local ffi = require("ffi")
local bit = require("bit")

local WINDOW_TICKS   = 14     -- default window: 14 * 15.625 ms = 218 ms
local WINDOW_DEFAULT = 8      -- immediate as shipped; find_immediate keys on it
local UNLAG_HEADROOM = 0.05   -- seconds of slack on top of window + latency
local UNLAG_CEILING  = 1.0    -- never write more than this into sv_maxunlag
local UNLAG_RECHECK  = 16     -- net updates between sv_maxunlag re-checks
local RETRY_TICKS    = 64     -- net updates between base-resolve attempts
local MAX_ATTEMPTS   = 8      -- then stop and report instead of spamming

local IDA_BASE = 0x41000000

local SYM = {
    lagrecord_check_lagcomp_window = { va = 0x41400bf0, size = 484  },
    player_records_cleanup         = { va = 0x414441c0, size = 919  },
    should_extrapolate             = { va = 0x413f6db0, size = 33   },
    backtrack_valid_while_fakeduck = { va = 0x414961e0, size = 555  },
    -- verification-only
    player_records_update          = { va = 0x4144b12e, size = 5750 },
    lagrecord_is_expired           = { va = 0x413f6d50, size = 65   },
    select_lagrecord               = { va = 0x4148f180, size = 1700 },
    validate_backtrack_window      = { va = 0x4148ff1d, size = 613  },
    backtrack_valid_check          = { va = 0x414ab5d0, size = 297  },
    backtrack_scan                 = { va = 0x41495850, size = 1071 },
    ragebot_backtrack_apply        = { va = 0x414c0920, size = 236  },
    adjust_extrap_ticks            = { va = 0x413341e0, size = 250  },
}

-- ============================================================
--  Win32 (x86)
-- ============================================================

ffi.cdef[[
    typedef struct {
        unsigned int BaseAddress, AllocationBase, AllocationProtect, RegionSize;
        unsigned int State, Protect, Type;
    } PAW_MBI;
    int          __stdcall VirtualProtect(void* addr, unsigned int size, unsigned int newProt, unsigned int* oldProt);
    unsigned int __stdcall VirtualQuery(const void* addr, PAW_MBI* buf, unsigned int len);
    void*        __stdcall GetModuleHandleA(const char* name);
]]

local C            = ffi.C
local MEM_COMMIT   = 0x1000
local MEM_PRIVATE  = 0x20000  -- manual-mapped module is a private commit; DLLs are MEM_IMAGE
local PAGE_EXECANY = 0xF0     -- EXECUTE | _READ | _READWRITE | _WRITECOPY
local PAGE_GUARD   = 0x100
local PAGE_RWX     = 0x40

-- ============================================================
--  Module base -- resolved at runtime, verified against every symbol
-- ============================================================

local module_base = nil

local function region_info(addr)
    local mbi = ffi.new("PAW_MBI")
    if C.VirtualQuery(ffi.cast("void*", addr), mbi, ffi.sizeof("PAW_MBI")) == 0 then return nil end
    return mbi
end

local function is_exec(addr)
    local mbi = region_info(addr)
    if not mbi then return false end
    return mbi.State == MEM_COMMIT
       and bit.band(tonumber(mbi.Protect), PAGE_EXECANY) ~= 0
       and bit.band(tonumber(mbi.Protect), PAGE_GUARD) == 0
end

local function verify_base(base)
    local ok, total = 0, 0
    for _, s in pairs(SYM) do
        total = total + 1
        if is_exec(base + (s.va - IDA_BASE)) then ok = ok + 1 end
    end
    return total > 0 and ok == total, ok, total
end

local function resolve_base(force)
    if module_base and not force then return module_base end
    module_base = nil

    local mbi  = ffi.new("PAW_MBI")
    local addr = 0x00010000
    local span = {}                                 -- AllocationBase -> exec bytes
    while addr < 0x7FFF0000 do
        if C.VirtualQuery(ffi.cast("void*", addr), mbi, ffi.sizeof("PAW_MBI")) == 0 then break end
        local size = tonumber(mbi.RegionSize)
        if size == 0 then break end
        local prot, kind, alloc = tonumber(mbi.Protect), tonumber(mbi.Type), tonumber(mbi.AllocationBase)
        if mbi.State == MEM_COMMIT and kind == MEM_PRIVATE and alloc ~= 0
           and bit.band(prot, PAGE_EXECANY) ~= 0 and bit.band(prot, PAGE_GUARD) == 0 then
            span[alloc] = (span[alloc] or 0) + size
        end
        addr = tonumber(mbi.BaseAddress) + size
    end

    local candidates = {}
    for alloc, size in pairs(span) do candidates[#candidates + 1] = { base = alloc, size = size } end
    table.sort(candidates, function(a, b) return a.size > b.size end)

    for _, candidate in ipairs(candidates) do
        local ok, hit, total = verify_base(candidate.base)
        if ok then
            module_base = candidate.base
            print(("[paw-bt] module base 0x%08X (private exec %.2f MB, %d/%d sites verified)")
                  :format(candidate.base, candidate.size / 1048576, hit, total))
            return module_base
        end
    end

    for _, name in ipairs({ "csgo.dll", "client.dll" }) do
        local handle = C.GetModuleHandleA(name)
        if handle ~= nil then
            local base = tonumber(ffi.cast("uintptr_t", handle))
            if verify_base(base) then
                module_base = base
                print(("[paw-bt] base via GetModuleHandle('%s') 0x%08X"):format(name, base))
                return module_base
            end
        end
    end

    return nil
end

local function entry_of(name)
    local base = resolve_base()
    local sym  = SYM[name]
    if not base or not sym then return nil end
    return base + (sym.va - IDA_BASE), sym.size
end

-- ============================================================
--  Memory helpers -- every write is journaled
-- ============================================================

local function raw_write(addr, bytes)
    local old = ffi.new("unsigned int[1]")
    if C.VirtualProtect(ffi.cast("void*", addr), #bytes, PAGE_RWX, old) == 0 then return false end
    local p = ffi.cast("uint8_t*", addr)
    for i = 1, #bytes do p[i - 1] = bytes[i] end
    local restored = ffi.new("unsigned int[1]")
    C.VirtualProtect(ffi.cast("void*", addr), #bytes, old[0], restored)
    return true
end

local function snapshot(addr, count)
    local p, saved = ffi.cast("uint8_t*", addr), {}
    for i = 1, count do saved[i] = p[i - 1] end
    return saved
end

local function hexdump(addr, count)
    local p, out = ffi.cast("uint8_t*", addr), {}
    for i = 0, count - 1 do out[#out + 1] = string.format("%02X", p[i]) end
    return table.concat(out, " ")
end

-- ============================================================
--  Payloads derived from the live bytes -- no guessed opcodes
-- ============================================================

-- The function's own terminal ret carries its stack cleanup (C3 or C2 imm16),
-- so an early return built from it never unbalances the caller's stack.
local function detect_ret(entry, size)
    local p = ffi.cast("uint8_t*", entry)
    local i = size - 1
    while i > 0 and (p[i] == 0xCC or p[i] == 0x90) do i = i - 1 end
    if i >= 2 and p[i - 2] == 0xC2 then return { 0xC2, p[i - 1], p[i] } end
    if p[i] == 0xC3 then return { 0xC3 } end
    return nil
end

local function make_neutralize(entry, size)
    return detect_ret(entry, size)
end

-- mov eax, imm32 ; <the function's own ret>
local function make_force_return(entry, size, value)
    local ret = detect_ret(entry, size)
    if not ret then return nil end
    local payload = {
        0xB8,
        bit.band(value, 0xFF),
        bit.band(bit.rshift(value, 8),  0xFF),
        bit.band(bit.rshift(value, 16), 0xFF),
        bit.band(bit.rshift(value, 24), 0xFF),
    }
    for _, byte in ipairs(ret) do payload[#payload + 1] = byte end
    return payload
end

-- Only length-safe operand forms are considered, and the match has to be
-- unique -- two candidates mean the wrong compare could be rewritten, so the
-- patch refuses and dumps the prologue instead.
local function find_immediate(entry, size, default)
    local p, found, i = ffi.cast("uint8_t*", entry), {}, 0
    while i < size - 1 do
        local op = p[i]
        if op == 0x6A and p[i + 1] == default then                      -- push imm8
            found[#found + 1] = { off = i + 1, len = 1 }
        elseif op == 0x83 and i + 2 < size then                         -- grp1 r/m32, imm8
            if bit.rshift(p[i + 1], 6) == 3 and p[i + 2] == default then
                found[#found + 1] = { off = i + 2, len = 1 }
            end
        elseif op >= 0xB8 and op <= 0xBF and i + 4 < size then          -- mov r32, imm32
            local value = p[i + 1] + p[i + 2] * 256 + p[i + 3] * 65536 + p[i + 4] * 16777216
            if value == default then found[#found + 1] = { off = i + 1, len = 4 } end
        end
        i = i + 1
    end
    return found
end

local function encode_imm(value, len)
    if len == 1 then return { bit.band(value, 0xFF) } end
    return {
        bit.band(value, 0xFF),
        bit.band(bit.rshift(value, 8),  0xFF),
        bit.band(bit.rshift(value, 16), 0xFF),
        bit.band(bit.rshift(value, 24), 0xFF),
    }
end

-- ============================================================
--  Patch object -- kinds: immediate | neutralize | force_return
-- ============================================================

local registry = {}

local Patch = {}
Patch.__index = Patch

function Patch.new(def)
    local self = setmetatable(def, Patch)
    self.armed = false
    registry[#registry + 1] = self
    return self
end

function Patch:log(fmt, ...)
    print(("[paw-bt] %-32s %s"):format(self.note, fmt:format(...)))
end

function Patch:arm()
    if self.armed then return true end

    local entry, size = entry_of(self.sym)
    if not entry then return false end

    if not is_exec(entry) then
        self:log("target not executable @0x%08X, refusing", entry)
        return false
    end

    if self.kind == "immediate" then
        local found = find_immediate(entry, size, self.default)
        if #found ~= 1 then
            self:log("immediate ambiguous (%d matches for %d): %s", #found, self.default, hexdump(entry, 24))
            return false
        end
        local slot   = found[1]
        self.applied = entry + slot.off
        self.imm_len = slot.len
        self.saved   = snapshot(self.applied, slot.len)
        if not raw_write(self.applied, encode_imm(self.value, slot.len)) then
            self.applied, self.saved, self.imm_len = nil, nil, nil
            self:log("VirtualProtect failed")
            return false
        end
        self.armed = true
        self:log("window %d -> %d @+0x%X", self.default, self.value, slot.off)
        return true
    end

    local payload
    if self.kind == "neutralize" then
        payload = make_neutralize(entry, size)
    else
        payload = make_force_return(entry, size, self.value)
    end
    if not payload then
        self:log("no epilogue ret found (tail-call?): %s", hexdump(entry, 24))
        return false
    end

    self.applied = entry
    self.saved   = snapshot(entry, #payload)
    if not raw_write(entry, payload) then
        self.applied, self.saved = nil, nil
        self:log("VirtualProtect failed")
        return false
    end
    self.armed = true
    self:log("armed @0x%08X (%d bytes)", entry, #payload)
    return true
end

-- Slider moves while armed: the operand slot is already located and saved, so
-- this is one in-place store, no re-scan and no second snapshot.
function Patch:set(value)
    self.value = value
    if not (self.armed and self.kind == "immediate" and self.applied) then return false end
    if not raw_write(self.applied, encode_imm(value, self.imm_len)) then return false end
    self:log("set = %d", value)
    return true
end

function Patch:disarm()
    if self.armed and self.saved and self.applied then
        raw_write(self.applied, self.saved)
        self:log("reverted")
    end
    self.armed, self.saved, self.applied, self.imm_len = false, nil, nil, nil
end

-- ============================================================
--  The four sites
-- ============================================================

local P_window = Patch.new{
    note    = "Backtrack window",
    sym     = "lagrecord_check_lagcomp_window",
    kind    = "immediate",
    default = WINDOW_DEFAULT,
    value   = WINDOW_TICKS,
}

-- The window immediate is the whole point and it only widens what the ragebot
-- already does. The three below change behaviour instead of range, and any of
-- them can fight Fake Latency, so they are off unless asked for.
local EXTRA = {
    Patch.new{
        note = "Keep valid records",
        sym  = "player_records_cleanup",
        kind = "neutralize",
    },
    Patch.new{
        note  = "No extrapolation",
        sym   = "should_extrapolate",
        kind  = "force_return",
        value = 0,
    },
    Patch.new{
        note  = "Records valid on fakeduck",
        sym   = "backtrack_valid_while_fakeduck",
        kind  = "force_return",
        value = 1,
    },
}

-- ============================================================
--  Menu
-- ============================================================

local group    = ui.create("Rage", "PAW Backtrack")
local enabled  = group:switch("Backtrack Patch", false)
local window   = group:slider("Window", 1, 16, WINDOW_TICKS, 1, " ticks")
local invasive = group:switch("Aggressive", false)

window:tooltip("How far the native backtrack may reach back. 8 is stock, 14 is ~218 ms. " ..
               "sv_maxunlag is raised to cover this plus your real outgoing latency, " ..
               "so Fake Latency keeps working on top of it.")
invasive:tooltip("Adds the three behaviour patches: no record cleanup, no extrapolation, " ..
                 "records valid on fakeduck. Leave off if Fake Latency misbehaves.")

-- ============================================================
--  Wiring -- memory is only touched on a control transition, and a partial
--  arm is rolled back so the ragebot is never left half-patched.
-- ============================================================

local armed_state   = false   -- true when the window write (at least) is live
local armed_extra   = false
local saved_unlag   = nil     -- sv_maxunlag exactly as it was before we armed
local applied_unlag = nil     -- the last value WE wrote, for compare-and-restore
local attempts      = 0
local countdown     = 0

local function active_patches()
    local list = { P_window }
    if invasive:get() then
        for _, patch in ipairs(EXTRA) do list[#list + 1] = patch end
    end
    return list
end

local function revert_writes()
    for i = #EXTRA, 1, -1 do EXTRA[i]:disarm() end
    P_window:disarm()
    armed_extra = false
end

-- A widened window is only legal if the server will rewind that far, and Fake
-- Latency spends part of that same budget: the command arrives out_latency late
-- and THEN gets rewound by the window. So the requirement is the sum, not the
-- window alone -- covering only the window is why the spike and the patch
-- cancelled each other out. Never lowered, only raised, and the current value
-- is re-read every time so a value another script raised is never clobbered.
local function needed_unlag()
    local span    = window:get() * globals.tickinterval
    local channel = utils.net_channel()
    local out     = channel ~= nil and (tonumber(channel.latency[0]) or 0) or 0
    return math.min(span + out + UNLAG_HEADROOM, UNLAG_CEILING)
end

local function apply_unlag()
    if not armed_state then return end
    local need    = needed_unlag()
    local current = cvar.sv_maxunlag:float()
    if need > current + 0.001 then
        cvar.sv_maxunlag:float(need, true)
        applied_unlag = need
    end
end

local function try_arm()
    if resolve_base() == nil then return false end

    P_window.value = window:get()

    local list = active_patches()
    for _, patch in ipairs(list) do
        if not patch:arm() then
            revert_writes()
            return false
        end
    end

    saved_unlag = cvar.sv_maxunlag:float()
    armed_state = true
    armed_extra = invasive:get()
    apply_unlag()
    print(("[paw-bt] on: window %d ticks (%.0f ms), %d patches, sv_maxunlag %.2f -> %.2f")
          :format(window:get(), window:get() * globals.tickinterval * 1000, #list,
                  saved_unlag, cvar.sv_maxunlag:float()))
    return true
end

-- Hand sv_maxunlag back only if it is still the value we wrote. If Fake Latency
-- or another script raised it after us, it is theirs now and we leave it alone.
local function teardown()
    revert_writes()
    if armed_state and saved_unlag then
        local current = cvar.sv_maxunlag:float()
        if applied_unlag == nil or math.abs(current - applied_unlag) < 0.002 then
            cvar.sv_maxunlag:float(saved_unlag, true)
        end
    end
    armed_state, saved_unlag, applied_unlag = false, nil, nil
end

window:set_callback(function(slider)
    P_window:set(slider:get())
    apply_unlag()
end)

invasive:set_callback(function(switch)
    if not armed_state or switch:get() == armed_extra then return end
    if switch:get() then
        for _, patch in ipairs(EXTRA) do patch:arm() end
    else
        for i = #EXTRA, 1, -1 do EXTRA[i]:disarm() end
    end
    armed_extra = switch:get()
end)

enabled:set_callback(function(switch)
    attempts, countdown = 0, 0
    if switch:get() then
        if not armed_state then try_arm() end
    else
        teardown()
    end
end, true)

-- The base only exists once the module is mapped, so an arm at load or in the
-- menu can legitimately fail. Retry on a tick count (curtime resets between
-- maps, a tick count does not), then stop and say so instead of spamming.
-- Once armed the same tick counter drives the sv_maxunlag re-check, because
-- Fake Latency moves the outgoing leg while you play.
events.net_update_end:set(function()
    if not enabled:get() then return end

    if armed_state then
        countdown = countdown - 1
        if countdown > 0 then return end
        countdown = UNLAG_RECHECK
        apply_unlag()
        return
    end

    if attempts >= MAX_ATTEMPTS then return end

    countdown = countdown - 1
    if countdown > 0 then return end
    countdown = RETRY_TICKS

    attempts = attempts + 1
    if not try_arm() and attempts >= MAX_ATTEMPTS then
        print("[paw-bt] could not arm after " .. MAX_ATTEMPTS ..
              " tries, ragebot build changed, nothing was written")
    end
end)

events.shutdown(function() teardown() end, true)