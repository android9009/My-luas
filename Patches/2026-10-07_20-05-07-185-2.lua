-- @author uwksc
local ffi = require "ffi"
local vector = require "vector"

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

local ctx = new_class()
:struct "menu_fade" {
    tab_base      = ffi.cast("int*", 0x43479A04),
    rage_class    = ffi.cast("int*", ffi.cast("int*", 0x43479A00)[0]),
    min_w         = ffi.cast("int*", 0x434799C8),
    min_h         = ffi.cast("int*", 0x434799CC),
    pos_x         = ffi.cast("int*", 0x434799B8),
    pos_y         = ffi.cast("int*", 0x434799BC),
    h_ptr         = ffi.cast("int*", 0x434799C4),
    w_ptr         = ffi.cast("int*", 0x434799C0),
    act_ptr       = ffi.cast("char*", 0x434799E0),
    fade_mode     = ffi.cast("int*", 0x43479A38),
    fade_speed    = ffi.cast("float*", 0x4346F920),
    fade_val      = ffi.cast("float*", 0x43479A5C),
    tabs          = { [0] = {} },
    cached_min_w  = nil,
    cached_min_h  = nil,
    base_size     = nil,
    base_pos      = nil,
    prev_mode     = 0,
    spin_offset   = 0,
    wobble_phase  = 0,
    screen        = vector(client.screen_size()),

    build_tabs = function(self)
        self.tabs[0].active = ffi.cast("char*", self.rage_class[0] + 0x15)
        self.tabs[0].origin = vector(
            ffi.cast("int*", self.rage_class[0] + 0x20)[0],
            ffi.cast("int*", self.rage_class[0] + 0x24)[0]
        )
        self.tabs[0].extent = vector(
            ffi.cast("int*", self.rage_class[0] + 0x28)[0],
            ffi.cast("int*", self.rage_class[0] + 0x2C)[0]
        )

        for idx = 1, 8 do
            local tab_class = ffi.cast("int*", self.tab_base[0] - (0x20 - 0x4 * (idx - 1)))
            self.tabs[idx] = {}
            self.tabs[idx].active = ffi.cast("char*", tab_class[0] + 0x15)
            self.tabs[idx].origin = vector(
                ffi.cast("int*", tab_class[0] + 0x20)[0],
                ffi.cast("int*", tab_class[0] + 0x24)[0]
            )
            self.tabs[idx].extent = vector(
                ffi.cast("int*", tab_class[0] + 0x28)[0],
                ffi.cast("int*", tab_class[0] + 0x2C)[0]
            )
        end
    end,

    set_minsize = function(self, w, h)
        if self.cached_min_w == nil or self.cached_min_h == nil then
            self.cached_min_w = self.min_w[0]
            self.cached_min_h = self.min_h[0]
        end
        self.min_w[0] = w
        self.min_h[0] = h
    end,

    set_size = function(self, w, h)
        self.w_ptr[0] = w
        self.h_ptr[0] = h
    end,

    set_pos = function(self, x, y)
        self.pos_x[0] = x
        self.pos_y[0] = y
    end,

    toggle_icons = function(self, force)
        if self.act_ptr[0] == 0x00 then
            return
        end
        for idx = 0, #self.tabs do
            local tab = self.tabs[idx]
            if tab.origin.y + tab.extent.y > self.h_ptr[0] then
                tab.active[0] = 0x00
            else
                tab.active[0] = force
            end
        end
    end,

    on_paint_ui = function(self)
        local mode = self.fade_mode[0]

        if mode == 0 and self.act_ptr[0] > 0 and self.prev_mode == 0 then
            self.base_size = vector(self.w_ptr[0], self.h_ptr[0])
            self.base_pos  = vector(self.pos_x[0], self.pos_y[0])
            self.spin_offset = 0
            self.wobble_phase = 0
            self:set_minsize(self.cached_min_w, self.cached_min_h)
            self:toggle_icons(0x01)
            return
        elseif self.prev_mode ~= 0 then
            self:set_size(self.base_size:unpack())
            self:set_pos(self.base_pos:unpack())
        end

        self.prev_mode = mode

        local fade = self.fade_val[0]

        self:set_minsize(0, 0)

        local pivot_x = self.screen.x * 0.5
        local pivot_y = self.screen.y * 0.5

        local center_x = self.base_pos.x + self.base_size.x * 0.5
        local center_y = self.base_pos.y + self.base_size.y * 0.5

        local dx = center_x - pivot_x
        local dy = center_y - pivot_y

        local scale = 0.35 + 0.65 * fade
        local rotation = (1.0 - fade) * 0.35

        local rot_x = dx * math.cos(rotation) - dy * math.sin(rotation)
        local rot_y = dx * math.sin(rotation) + dy * math.cos(rotation)

        local new_size = vector(self.base_size.x * scale, self.base_size.y * scale)
        local new_center_x = pivot_x + rot_x * scale
        local new_center_y = pivot_y + rot_y * scale

        local new_x = new_center_x - new_size.x * 0.5
        local new_y = new_center_y - new_size.y * 0.5

        self.wobble_phase = self.wobble_phase + globals.frametime() * 8.0
        local wobble = math.sin(self.wobble_phase) * (1.0 - fade) * 12.0

        self:set_size(new_size.x, new_size.y)
        self:set_pos(new_x + wobble, new_y)

        self:toggle_icons(0x00)
    end,

    reset = function(self)
        self:set_minsize(self.cached_min_w, self.cached_min_h)
        self:set_size(self.base_size.x, self.base_size.y)
        self:set_pos(self.base_pos.x, self.base_pos.y)
        self.fade_val[0] = 1.0
        self.fade_speed[0] = 270
        self:toggle_icons(0x01)
    end,

    init = function(self)
        self:build_tabs()
        self:set_minsize(560, 660)
        self.base_size = vector(self.w_ptr[0], self.h_ptr[0])
        self.base_pos  = vector(self.pos_x[0], self.pos_y[0])

        self.speed_slider = ui.new_slider("Config", "Presets", "Anim Speed", 270, 1000, 150, true, "ms", 1, {[270] = "Default"})

        ui.set_callback(self.speed_slider, function()
            self.fade_speed[0] = ui.get(self.speed_slider)
        end)
    end,
}

ctx.menu_fade:init()

client.set_event_callback("paint_ui", function()
    ctx.menu_fade:on_paint_ui()
end)

client.set_event_callback("shutdown", function()
    ctx.menu_fade:reset()
end)