-- @author uwksc
local ffi = require "ffi"

local new_class = function()
    local mt, mt_data, this_mt = { }, { }

    mt.__metatable = false
    mt_data.struct = function(self, name)
        assert(type(name) == 'string', 'invalid class name')
        assert(rawget(self, name) == nil, 'cannot overwrite subclass')

        return function(data)
            assert(type(data) == 'table', 'invalid class data')
            rawset(self, name, setmetatable(data, {
                __metatable = false,
                __index = function(self, key)
                    return
                        rawget(mt, key) or
                        rawget(this_mt, key)
                end
            }))

            return this_mt
        end
    end

    this_mt = setmetatable(mt_data, mt)

    return this_mt
end

ffi.cdef [[
    typedef long NTSTATUS;
    typedef unsigned long DWORD;
    typedef void* PVOID;
    typedef unsigned int UINT;
    typedef uintptr_t size_t;
]]

local proxy_addr = client.find_signature("client.dll", string.char(0x51, 0xC3)) or error("err1")

local get_mod_add_patern = client.find_signature("client.dll", string.char(0xC6, 0x06, 0x00, 0xFF, 0x15, 0xCC, 0xCC, 0xCC, 0xCC, 0x50)) or error("err2")
local get_mod_add_addr = ffi.cast("void***", ffi.cast("char*", get_mod_add_patern) + 5)[0][0] or error("err3")
local get_mod_add_proxy = ffi.cast("uintptr_t (__thiscall*)(void*, const char*)", proxy_addr) or error("err4")

local get_proc_add_patern = client.find_signature("client.dll", string.char(0x50, 0xFF, 0x15, 0xCC, 0xCC, 0xCC, 0xCC, 0x85, 0xC0, 0x0F, 0x84, 0xCC, 0xCC, 0xCC, 0xCC, 0x6A, 0x00)) or error("err5")
local get_proc_add_addr = ffi.cast("void***", ffi.cast("char*", get_proc_add_patern) + 3)[0][0] or error("err6")
local get_proc_add_proxy = ffi.cast("uintptr_t (__thiscall*)(void*, uintptr_t, const char*)", proxy_addr) or error("err7")

local kernel32_addr = get_mod_add_proxy(get_mod_add_addr, "kernel32.dll") or error("err8")
local VirtualProtect_addr = get_proc_add_proxy(get_proc_add_addr, kernel32_addr, "VirtualProtect") or error("err11")
local VirtualProtect_proxy = ffi.cast("bool (__thiscall*)(uintptr_t, void*, size_t, unsigned long, unsigned long*)", proxy_addr) or error("err12")

local function VirtualProtect(addr, size, protect, oldprotect)
    if oldprotect == nil then
        oldprotect = ffi.new("unsigned long[1]")
    end
    return VirtualProtect_proxy(VirtualProtect_addr, ffi.cast("void*", addr), size, protect, oldprotect)
end

local function set_mem_protect(addr, size, protect)
    local old = ffi.new("unsigned long[1]")
    return VirtualProtect(ffi.cast("uintptr_t", addr), size, protect, old)
end

local PAGE_EXECUTE_READWRITE = 0x40
local PAGE_EXECUTE_READ      = 0x20

local SKALA_JONSON_ADDR = ffi.cast("unsigned char*", 0x106D67A8)
local PATCH_SIZE    = 8

local SKALA_JONSON_enable = ui.new_checkbox("LUA", "B", "СТРЕЛЯТЬ КАК СКОЛА ДЖОНСОН")

local ctx = new_class()
:struct "SKALA_JONSON" {
    patched  = false,
    original = nil,

    apply = function(self)
        if self.patched then
            return
        end

        if not self.original then
            self.original = ffi.new("uint8_t[?]", PATCH_SIZE)
            ffi.copy(self.original, SKALA_JONSON_ADDR, PATCH_SIZE)
        end

        if not set_mem_protect(ffi.cast("uintptr_t", SKALA_JONSON_ADDR), PATCH_SIZE, PAGE_EXECUTE_READWRITE) then
            return
        end

        SKALA_JONSON_ADDR[0] = 0xB8
        SKALA_JONSON_ADDR[1] = 0x01
        SKALA_JONSON_ADDR[2] = 0x00
        SKALA_JONSON_ADDR[3] = 0x00
        SKALA_JONSON_ADDR[4] = 0x00
        SKALA_JONSON_ADDR[5] = 0xC2
        SKALA_JONSON_ADDR[6] = 0x08
        SKALA_JONSON_ADDR[7] = 0x00

        self.patched = true
    end,

    restore = function(self)
        if not self.patched or not self.original then
            return
        end

        ffi.copy(SKALA_JONSON_ADDR, self.original, PATCH_SIZE)
        set_mem_protect(ffi.cast("uintptr_t", SKALA_JONSON_ADDR), PATCH_SIZE, PAGE_EXECUTE_READ)

        self.patched = false
    end,

    init = function(self)
        ui.set_callback(SKALA_JONSON_enable, function()
            if ui.get(SKALA_JONSON_enable) then
                self:apply()
            else
                self:restore()
            end
        end)

        if ui.get(SKALA_JONSON_enable) then
            self:apply()
        end
    end,
}

ctx.SKALA_JONSON:init()

client.set_event_callback("shutdown", function()
    ctx.SKALA_JONSON:restore()
end)