--- by estk / amnesia.plus / doscord.gg/antihit

---@diagnostic disable: undefined-global

username = _USER_NAME or "admin"
build = "Beta"
update_date = "30.09.2026"


---я там дохуя коментариев написал, мне скучно просто было и я по приколу накалякал

---@references
ref = {
    enabled = ui.reference("AA", "Anti-Aimbot angles", "Enabled"),
    pitch     = { ui.reference("AA", "Anti-Aimbot angles", "Pitch") },
    yaw_base  = ui.reference("AA", "Anti-Aimbot angles", "Yaw base"),
    yaw       = { ui.reference("AA", "Anti-Aimbot angles", "Yaw") },
    yaw_jitter = { ui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") },
    body_yaw  = { ui.reference("AA", "Anti-Aimbot angles", "Body yaw") },
    freestanding_body_yaw = ui.reference("AA", "Anti-Aimbot angles", "Freestanding body yaw"),
    edge_yaw  = ui.reference("AA", "Anti-Aimbot angles", "Edge yaw"),
    freestand = { ui.reference("AA", "Anti-Aimbot angles", "Freestanding") },
    roll      = ui.reference("AA", "Anti-Aimbot angles", "Roll"),
    slow_walk = { ui.reference("AA", "Other", "Slow motion") },
    dt        = { ui.reference("RAGE", "Aimbot", "Double Tap") },
    hs        = { ui.reference("AA", "Other", "On shot anti-aim") },
    fd        = ui.reference("RAGE", "Other", "Duck peek assist"),
    min_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),
    min_damage_override = { ui.reference("RAGE", "Aimbot", "Minimum damage override") },
    rage_cb   = { ui.reference("RAGE", "Aimbot", "Enabled") },
    menu_color = ui.reference("MISC", "Settings", "Menu color"),
    clantag = ui.reference("MISC", "Miscellaneous", "Clan tag spammer"),
    falelag_enabled = { ui.reference("AA", "Fake lag", "Enabled") },
    fakelag_limit = ui.reference("AA", "Fake lag", "Limit"),
    variability   = ui.reference("AA", "Fake lag", "Variance"),
    fakelag_amount = ui.reference("AA", "Fake lag", "Amount"),
    aimbot        = ui.reference("RAGE", "Aimbot", "Enabled"),
    scope_overlay = ui.reference("VISUALS", "Effects", "Remove scope overlay"),
    body = ui.reference("RAGE", "Aimbot", "Force Body aim"),
    dt_fakelag = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
    autostop = {ui.reference("RAGE", "Aimbot", "Quick stop")},
    zoom = ui.reference("MISC", "Miscellaneous", "Override zoom FOV"),
    fov = ui.reference("MISC", "Miscellaneous", "Override FOV"),
    sv_unlag = { ui.reference("Misc", "Settings", "sv_maxunlag2") }
}

do
    local ok, qp_a, qp_b = pcall(ui.reference, "RAGE", "Other", "Quick peek assist")
    ref.quick_peek = ok and { qp_a, qp_b } or {}
end

do
    local ok, max_proc = pcall(ui.reference, "MISC", "Settings", "sv_maxusrcmdprocessticks2")
    ref.max_process_ticks = ok and max_proc or nil
end

---@end

---@libs

vector = require 'vector'
ffi = require 'ffi'
weapons = require 'gamesense/csgo_weapons'
clipboard = require 'gamesense/clipboard'
json = require 'json'
base64 = require 'gamesense/base64'
c_entity = require 'gamesense/entity'

---@end

---@sdk
local sdk = {
    get_lp = function()
        return entity.get_local_player()
    end,
    
    is_alive = function(idx)
        return entity.is_alive(idx)
    end,

    get_velocity = function(idx)
        return math.max(0, math.floor(vector(entity.get_prop(idx, "m_vecAbsVelocity")):length2d()) - 1)
    end,

    isScoped = function(idx)
        return entity.get_prop(idx, "m_bIsScoped") == 1
    end
}

local player = {
    shifting = 0,
    _shifting_enough = nil,
    choked = 0,
}

player.get_dt = function()
    return player._shifting_enough
end

player.run_command = function(cmd)
    local lp = sdk.get_lp()

    if lp then
        local m_nTickBase = entity.get_prop(lp, 'm_nTickBase')
        local client_latency = client.latency()
        local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client_latency) * 0.88 * (client_latency * 10))

        if math.abs(shift - (-1)) < math.abs(shift - (-15)) then
            shift = -1
        else
            shift = -15
        end

        local wanted = -14 + (ui.get(ref.dt_fakelag) - 1) + 3

        player.shifting = shift
        player._shifting_enough = shift <= wanted
    end
end

---@end

---@helpful functions

local debug_params = {}

local function render_debug_text(pos)
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return end

    local screen_width, screen_height = client.screen_size()
    local x
    local y
    if pos == "Right Upper" then
        x = screen_width - 200
        y = 13
    elseif pos == "Right Center" then
        x = screen_width - 10
        y = (screen_height / 2)
    end
    local active_line_index = 0
    
    for _, line in ipairs(debug_params) do
        if line.active then
            local display_text = line.text
            if line.value then
                display_text = display_text .. " - > " .. tostring(line.value)
            end
            
            renderer.text(
                x,
                y + (active_line_index * 15),
                255, 255, 255, 255,
                "r",
                0,  
                display_text
            )
            active_line_index = active_line_index + 1
        end
    end
end

function change_debug(parameter, value, active_or_value)
    if parameter == "add" then
        for i, line in ipairs(debug_params) do
            if line.text == value then
                if active_or_value ~= nil then
                    if type(active_or_value) == "boolean" then
                        debug_params[i].active = active_or_value
                    else
                        debug_params[i].value = active_or_value
                    end
                end
                return
            end
        end
        table.insert(debug_params, {
            text = value,
            active = true,
            value = type(active_or_value) ~= "boolean" and active_or_value or nil
        })
    elseif parameter == "remove" then
        table.remove(debug_params, #debug_params)
    elseif parameter == "clear" then
        debug_params = {}
    elseif parameter == "set_active" then
        for i, line in ipairs(debug_params) do
            if line.text == value then
                debug_params[i].active = active_or_value
                break
            end
        end
    elseif parameter == "set_value" then
        for i, line in ipairs(debug_params) do
            if line.text == value then
                debug_params[i].value = active_or_value
                break
            end
        end
    end
end

function height_advantaged(idx)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then
        return false
    end

    if not entity.is_enemy(idx) or not entity.is_alive(idx) then
        return false
    end

    local local_origin = { entity.get_origin(local_player) }
    local enemy_origin = { entity.get_origin(idx) }

    if not local_origin[3] or not enemy_origin[3] then
        return false
    end

    local height_diff = local_origin[3] - enemy_origin[3]
    local threshold = 125

    return height_diff >= threshold
end

aspect_ratio_table = {}

clamp = function(value, min, max)
    return math.max(min, math.min(max, value))
end

function ease_in_out_quad(t)
    return t < 0.5 and (2 * t * t) or (-1 + (4 - 2 * t) * t)
end

function gradient_text(color1, color2, text, speed)
    local time = globals.realtime() * speed
    local gradient_str = ""
    local text_length = #text

    local position = - 0.5 * (1 - math.cos(time))

    for i = 1, text_length do
        local index = i
        local char = text:sub(i, i)
        
        local t = (math.sin(time + (index / text_length) * math.pi) + 1) / 2
        local r = math.floor(color1[1] * t + color2[1] * (1 - t))
        local g = math.floor(color1[2] * t + color2[2] * (1 - t))
        local b = math.floor(color1[3] * t + color2[3] * (1 - t))
        
        gradient_str = gradient_str .. string.format("\a%02X%02X%02XFF%s", r, g, b, char)
    end
    
    return gradient_str
end

function gradient_text_lower(color1, color2, text, speed)
    local time = globals.realtime() * speed
    local gradient_str = ""
    local text_length = #text

    for i = 1, text_length do
        local char = text:sub(i, i)
        
        local t = (math.sin(time + (i / text_length) * math.pi) + 1) / 2

        local weight1 = t * 1.3
        local weight2 = (1 - t) * 0.3
        local total_weight = weight1 + weight2

        weight1 = weight1 / total_weight
        weight2 = weight2 / total_weight

        local r = math.floor(color1[1] * weight1 + color2[1] * weight2)
        local g = math.floor(color1[2] * weight1 + color2[2] * weight2)
        local b = math.floor(color1[3] * weight1 + color2[3] * weight2)
        
        gradient_str = gradient_str .. string.format("\a%02X%02X%02XFF%s", r, g, b, char)
    end
    
    return gradient_str
end

local function copy(tbl)
    local out = {}
    for i = 1, #tbl do
        out[i] = tbl[i]
    end
    return out
end

local a = function (...) return ... end

local lerp = function(a, b, t)
    t = clamp(t, 0, 1)
    return a + (b - a) * t
end

local interp = function(a, b, speed)
    local t = 1 - math.exp(-speed * globals.absoluteframetime())
    return lerp(a, b, t)
end

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

local accent = {
    r = 113,
    g = 104,
    b = 230
}

local print = function(...)
    local prefix = "Panchan"
    if log_prefix_textbox ~= nil then
        local custom_prefix = ui.get(log_prefix_textbox)
        if custom_prefix ~= nil and custom_prefix ~= "" then
            prefix = custom_prefix
        end
    end

    local lr, lg, lb = 198, 203, 209
    if log_console_color ~= nil then
        local cr, cg, cb = ui.get(log_console_color)
        lr, lg, lb = cr or lr, cg or lg, cb or lb
    end

    local pr, pg, pb = accent.r, accent.g, accent.b
    if log_prefix_color ~= nil then
        local cr, cg, cb = ui.get(log_prefix_color)
        pr, pg, pb = cr or pr, cg or pg, cb or pb
    end

    client.color_log(pr, pg, pb, "[" .. prefix .. "] \0")
    client.color_log(lr, lg, lb, ...)
end

local logs = {}
local screen_w, screen_h = client.screen_size()

local function add_log(text, duration, r, g, b)
    table.insert(logs, {
        text = text,
        duration = duration,
        start = globals.curtime(),
        color = {r, g, b},
        y = screen_h + 100,
        state = "appearing",
        fade_delay = 1,
        scale = 1,
        alpha = 0
    })
end

function draw_rounded_rect(x, y, w, h, r, g, b, a)
    local radius = math.min(x/2, y/2, 6)
    renderer.rectangle(x + radius, y, w - radius*2, h, r, g, b, a)
    renderer.rectangle(x, y + radius, radius, h - radius*2, r, g, b, a)
    renderer.rectangle(x + w - radius, y + radius, radius, h - radius*2, r, g, b, a)
    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
    renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25)
end

function render_logs()
    local now = globals.curtime()
    local frametime = globals.frametime()
    local font = "cb"
    local spacing = 14
    local side_padding = 12
    local base_y = screen_h - 120
    local log_h_extra = 14
    
    for i = #logs, 1, -1 do
        local log = logs[i]
        local elapsed = now - log.start
        if log.state == "disappearing" and log.y > screen_h + 50 then
            table.remove(logs, i)
        elseif elapsed >= log.duration * log.fade_delay and log.state ~= "disappearing" then
            log.state = "disappearing"
        end
    end

    for i, log in ipairs(logs) do
        local elapsed = now - log.start
        local t = math.min(elapsed / log.duration, 1)
        local text_w, text_h = renderer.measure_text(font, log.text)
        local width = math.floor(text_w + side_padding * 2 + 10)
        local height = math.floor(text_h + log_h_extra)
        local x = math.floor((screen_w - width) / 2)
        local target_y = math.floor(base_y - (height + spacing) * (#logs - i))
        
        if log.state == "appearing" then
            log.scale = 1
            log.y = lerp(log.y or screen_h + 100, target_y, frametime * 8)
            log.alpha = lerp(log.alpha or 0, 255, frametime * 8)
            if math.abs(log.y - target_y) < 1 then
                log.state = "visible"
                log.scale = 1
                log.alpha = 255
            end
        elseif log.state == "visible" then
            log.y = lerp(log.y, target_y, frametime * 8)
            log.scale = 1
            log.alpha = 255
        elseif log.state == "disappearing" then
            log.y = lerp(log.y, screen_h + 100, frametime * 8)
            log.alpha = lerp(log.alpha, 0, frametime * 8)
        end
        
        local scaled_width = math.floor(width * (log.scale or 1))
        local scaled_height = math.floor(height * (log.scale or 1))
        local scaled_x = math.floor(x + (width - scaled_width) / 2)
        local scaled_y = math.floor((log.y or target_y) + (height - scaled_height) / 2)
        
        local alpha = log.alpha or 255
        local bg_alpha = math.min(125, alpha)
        local r, g, b = log.color[1], log.color[2], log.color[3]
        
        draw_rounded_rect(
            scaled_x, 
            scaled_y, 
            scaled_width, 
            scaled_height, 
            20, 20, 20, bg_alpha
        )
        
        local text_alpha = alpha
        local text_x = scaled_x + scaled_width / 2
        local text_y = (scaled_y + (scaled_height - text_h) / 2) + 4
        renderer.text(text_x, text_y, 255, 255, 255, text_alpha, font, 0, log.text)
    end
end

function panchan_clear_map_ui_state()
    for i = #logs, 1, -1 do
        logs[i] = nil
    end

    if welcome_intro ~= nil then
        welcome_intro.start = globals.realtime() - (welcome_intro.duration or 0) - 1
    end

    if anti_brute ~= nil then
        if anti_brute_reset ~= nil then
            anti_brute_reset(true)
        else
            anti_brute.active_until = 0
            anti_brute.current_offset = 0
        end
    end

    if defensive_rework_reset ~= nil then
        defensive_rework_reset()
    end

    if flick_exploit_reset_runtime ~= nil then
        flick_exploit_reset_runtime()
    end

    if fake_duck_freezetime_restore ~= nil then
        fake_duck_freezetime_restore()
    end

    if airlag_panchan_restore ~= nil then
        airlag_panchan_restore()
    end

    if panchan_crimwalk_restore ~= nil then
        panchan_crimwalk_restore()
    end

    if panchan_scolious_restore ~= nil then
        panchan_scolious_restore()
    end

    if panchan_exploit_reset_runtime ~= nil then
        panchan_exploit_reset_runtime()
    end

    if quickpeek_reset_runtime ~= nil then
        quickpeek_reset_runtime()
    end

    if dormant_stats ~= nil then
        dormant_stats.pending = false
        dormant_stats.pending_target = nil
        dormant_stats.pending_time = nil
        dormant_stats.pending_prediction_hypothesis = nil
        dormant_stats.pending_prediction_scale = nil
        dormant_stats.lock_target = nil
        dormant_stats.lock_until = 0
        dormant_stats.last_target_time = 0
        dormant_stats.last_confidence = 0
        dormant_stats.shot_ledger = {}
    end

    if shared_esp_clear_runtime ~= nil then
        shared_esp_clear_runtime()
    elseif shared_esp_neverlose_packets ~= nil then
        for idx in pairs(shared_esp_neverlose_packets) do
            shared_esp_neverlose_packets[idx] = nil
        end
    end

    if tracer_clear_state ~= nil then
        tracer_clear_state()
    end
end

function distance3d(x1, y1, z1, x2, y2, z2)
	return math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1))
end

to_hex = function(r, g, b, a)
    return string.format("%02x%02x%02x%02x", r, g, b, a)
end

to_hex_a = function(r, g, b)
    return string.format("%02x%02x%02xff", r, g, b)
end

local function get_desync_angle()
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return 0 end

    local desync_angle = entity.get_prop(lp, "m_flPoseParameter", 11) * 120 - 60
    return math.floor(desync_angle)
end

---@end

---@lua menu
local cur_tab = 1
local back_button = ui.new_button("AA", "Anti-Aimbot angles", "\aFF7070FFBack", function()
    cur_tab = 1
end)

local aa_button = ui.new_button("AA", "Anti-Aimbot angles", "\aB4F000FFAnti - Aim", function()
    cur_tab = 2
end)

local visuals_button = ui.new_button("AA", "Anti-Aimbot angles", "\a7AD7FFFFVisuals", function()
    cur_tab = 3
end)

local misc_button = ui.new_button("AA", "Anti-Aimbot angles", "\aFFD166FFMisc", function()
    cur_tab = 4
end)

local cfg_button = ui.new_button("AA", "Anti-Aimbot angles", "\aC792EAFFConfig", function()
    cur_tab = 5
end)

--@visuals

center_indicators = ui.new_checkbox("AA", "Anti-Aimbot angles", "Crosshair Indicators")
color = ui.new_color_picker("AA", "Anti-Aimbot angles", "Crosshair Indicators", 176, 192, 255, 255)
center_indicators_type = ui.new_combobox("AA", "Anti-Aimbot angles", "Crosshair Indicators Style", "Modern", "Legacy")
--local center_indicators_alpha = ui.new_multiselect("AA", "Anti-Aimbot angles", "Reduce Alpha", "Scoped", "On Nades")

manual_ind = ui.new_checkbox("AA", "Anti-Aimbot angles", "Manual Indicator")
manual_ind_color = ui.new_color_picker("AA", "Anti-Aimbot angles", "Manual Indicator", 255, 255, 255, 255)

_custom_scope = ui.new_checkbox("AA", "Anti-Aimbot angles", "Custom Scope")
custom_scope_color = ui.new_color_picker("AA", "Anti-Aimbot angles", "Custom Scope", 255, 255, 255, 255)
custom_scope_style = ui.new_combobox("AA", "Anti-Aimbot angles", "Custom Scope Style", "Default", "Inverted", "X-Style", "X-Style Inverted")
custom_scope_size = ui.new_slider("AA", "Anti-Aimbot angles", "Custom Scope Size", 0, 320, 25)
custom_scope_gap = ui.new_slider("AA", "Anti-Aimbot angles", "Custom Scope Gap", 0, 50, 6)
custom_scope_disable_animation = ui.new_checkbox("AA", "Anti-Aimbot angles", "Disable Scope Animation")

revolver_helper = ui.new_checkbox("AA", "Anti-Aimbot angles", "Revolver Helper")

damage_indicator = ui.new_checkbox("AA", "Anti-Aimbot angles", "Damage Indicator")
damage_indicator_font = ui.new_combobox("AA", "Anti-Aimbot angles", "Damage Indicator Font", "Verdana", "Pixel")

enable_aspect_ratio = ui.new_checkbox("AA", "Anti-Aimbot Angles", "Aspect Ratio")
aspect_ratio_reference = ui.new_slider("AA", "Anti-Aimbot angles", "Aspect Ratio", 1, 199, 100, true, "%", 0.01, aspect_ratio_table)

debug_text = ui.new_checkbox("AA", "Anti-Aimbot angles", "Debug Text")
debug_text_position = ui.new_combobox("AA", "Anti-Aimbot angles", "Debug Text Position", "Right Upper", "Right Center")

velocity_modifier = ui.new_checkbox("AA", "Anti-Aimbot angles", "Velocity Modifier")

animated_zoom = ui.new_checkbox("AA", "Anti-Aimbot angles", "Animated zoom FOV")
zoom_val = ui.new_slider("AA", "Anti-Aimbot angles", "Animated zoom FOV", 0, 35, 0, true, "°")
visual_tracer = ui.new_checkbox("AA", "Anti-Aimbot angles", "Bullet Tracers")
visual_tracer_type = ui.new_combobox("AA", "Anti-Aimbot angles", "Tracer Type", "Beam", "Line")
visual_tracer_impact_mode = ui.new_combobox("AA", "Anti-Aimbot angles", "Tracer Impact Mode", "First impact", "Last impact", "All impacts")
visual_tracer_color = ui.new_color_picker("AA", "Anti-Aimbot angles", "Tracer Color", 255, 255, 255, 255)

--@end

---@misc
local recharge_fix = ui.new_checkbox("AA", "Anti-Aimbot angles", "Recharge Fix")
local fix_exploits = ui.new_checkbox("AA", "Anti-Aimbot angles", "Exploits Fix")
jitter_correction = ui.new_checkbox("AA", "Anti-Aimbot angles", "Jitter Correction")
jitter_correction_esp_flag = ui.new_checkbox("AA", "Anti-Aimbot angles", "Jitter Correction ESP Flag")
fake_flick = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fake Flick Fix")
adaptive_ping_spike = ui.new_checkbox("AA", "Anti-Aimbot angles", "Adaptive \aB4F000FFPing Spike")
fake_flick_conditions = ui.new_multiselect("AA", "Anti-Aimbot angles", "Conditions", "Standing", "Moving", "Slowwalk", "Crouching", "Air", "Crouch-Air", "Fake Duck")
defensive_correct = ui.new_checkbox("AA", "Anti-Aimbot angles", "Defensive ~ Correct")
resolver_lagcomp = ui.new_checkbox("AA", "Anti-Aimbot angles", "Resolver ~ lagcomp")
early_quickpeek_autostop = ui.new_checkbox("AA", "Anti-Aimbot angles", "Early Autostop on Quick Peek")
quickpeek_weapon = ui.new_combobox("AA", "Anti-Aimbot angles", "Quick Peek Weapon", "AWP", "SSG 08", "SCAR", "Pistols", "Deagle", "Any")
quickpeek_dt_options = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
quickpeek_dt_options_awp = quickpeek_dt_options
quickpeek_dt_options_scout = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
quickpeek_dt_options_scar = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
quickpeek_dt_options_pistols = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
quickpeek_dt_options_deagle = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
quickpeek_dt_options_any = ui.new_multiselect("AA", "Anti-Aimbot angles", "Quick Peek Double Tap Options", "Early", "Slow Motion", "Move between shots")
experimental_predict = ui.new_combobox("AA", "Anti-Aimbot angles", "\aFF5555FFExperimental\aFFFFFFFF Predict", "Off", "High Ping >= 55", "Low Ping <= 40")
pcall(ui.set, fake_flick_conditions, "Standing", "Moving", "Slowwalk", "Crouching", "Air", "Crouch-Air", "Fake Duck")
pcall(ui.set, quickpeek_dt_options, "Early", "Slow Motion", "Move between shots")
pcall(ui.set, quickpeek_dt_options_scout, "Early", "Move between shots")
pcall(ui.set, quickpeek_dt_options_scar, "Early", "Slow Motion", "Move between shots")
pcall(ui.set, quickpeek_dt_options_pistols, "Early")
pcall(ui.set, quickpeek_dt_options_deagle, "Early", "Slow Motion")
pcall(ui.set, quickpeek_dt_options_any, "Early", "Slow Motion", "Move between shots")
delay_fix = ui.new_checkbox("AA", "Anti-Aimbot angles", "Remove Delay On DT Uncharge")
delay_fix_weapons = ui.new_multiselect("AA", "Anti-Aimbot angles", "DT Uncharge Weapons", "SCAR", "AWP", "Scout", "Pistols", "Deagle")
pcall(ui.set, delay_fix_weapons, "SCAR", "AWP", "Scout", "Pistols", "Deagle")
_trashtalk = ui.new_checkbox("AA", "Anti-Aimbot angles", "Killsay")
trashtalk_mode = ui.new_combobox("AA", "Anti-Aimbot angles", "Killsay Mode", "Panchan (sponsored)", "?")
trashtalk_on_death = ui.new_checkbox("AA", "Anti-Aimbot angles", "Trash Talk On Death")
double_zoom = ui.new_checkbox("AA", "Anti-Aimbot angles", "Double Zoom")
double_zoom_key = ui.new_hotkey("AA", "Anti-Aimbot angles", "Double Zoom Key")
double_zoom_amount = ui.new_slider("AA", "Anti-Aimbot angles", "Double Zoom Amount", 0, 80, 30, true, "")
hirate_indicator = ui.new_checkbox("AA", "Anti-Aimbot angles", "Hirate Indicator")
hirate_reset = ui.new_button("AA", "Anti-Aimbot angles", "\aFFD166FFReset Hirate", function()
    hirate_shots = 0
    hirate_hits = 0
    hirate_headshots = 0
end)
dormant_aimbot = ui.new_checkbox("AA", "Anti-Aimbot angles", "Dormant Aimbot")
dormant_aimbot_key = ui.new_hotkey("AA", "Anti-Aimbot angles", "Dormant Aimbot Key")
dormant_aimbot_selection = ui.new_combobox("AA", "Anti-Aimbot angles", "Dormant Target Selection", "Best Hit Chance", "Best Damage", "Closest to Crosshair", "Lowest Health")
dormant_aimbot_hitboxes = ui.new_multiselect("AA", "Anti-Aimbot angles", "Dormant Hitboxes", "Head", "Chest", "Stomach", "Legs")
dormant_aimbot_accuracy = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Accuracy", 50, 100, 74, true, "%")
dormant_aimbot_mindmg = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Minimum Damage", 0, 126, 10, true, nil, 1)
dormant_aimbot_indicator = ui.new_checkbox("AA", "Anti-Aimbot angles", "Dormant Indicator")
dormant_aimbot_multipoint = ui.new_checkbox("AA", "Anti-Aimbot angles", "Dormant Multipoint")
dormant_aimbot_autostop = ui.new_checkbox("AA", "Anti-Aimbot angles", "Dormant Auto Stop")
dormant_aimbot_max_fov = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Max FOV", 1, 180, 45, true, "В°")
dormant_aimbot_max_distance = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Max Distance", 250, 5000, 2800, true, "u")
dormant_aimbot_cooldown = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Shot Delay", 0, 1000, 150, true, "ms")
dormant_aimbot_timeout = ui.new_slider("AA", "Anti-Aimbot angles", "Dormant Timeout", 5, 40, 22, true, "s", 0.1)
ui.set(dormant_aimbot_max_fov, 62)
ui.set(dormant_aimbot_max_distance, 3200)
ui.set(dormant_aimbot_cooldown, 110)
ui.set(dormant_aimbot_timeout, 24)
ui.set(dormant_aimbot_accuracy, 74)
ui.set(dormant_aimbot_multipoint, true)
ui.set(dormant_aimbot_autostop, true)
local console_filter = ui.new_checkbox("AA", "Anti-Aimbot angles", "Console Filter")
local _clantag = ui.new_checkbox("AA", "Anti-Aimbot angles", "Clantag")
local teammate_aimbot = ui.new_checkbox("AA", "Anti-Aimbot angles", "Force Team Aimbot")
duck_on_fd = ui.new_checkbox("AA", "Anti-Aimbot angles", "Duck on FD")
fake_duck_unspeed = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fake Duck Unspeed")
fake_duck_unspeed_scale = ui.new_slider("AA", "Anti-Aimbot angles", "Fake Duck Unspeed Scale", 15, 150, 150, true, "u")
fake_duck_freezetime = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fake Duck Freezetime")
local fps_optimize = ui.new_multiselect("AA", "Anti-Aimbot angles", "Fps Optimizations", "3d sky", "fog", "shadows", "blood", "decals", "bloom", "other", "disable weapon rendering third person")
local animfix = ui.new_multiselect("AA", "Anti-aimbot angles", "Anim Breakers", "Jitter legs on ground", "Body lean", "0 pitch on landing", "Static in Air", "Kangaroo")
local extendedbacktrack = ui.new_combobox("AA", "Anti-Aimbot angles", "Extended Backtrack", "Off", "Normal", "High")
cheat_revealer = ui.new_combobox("AA", "Anti-Aimbot angles", "Cheat Revealer", "Off", "ESP Flag", "Player List", "Both")
cheat_revealer_list = ui.new_listbox("AA", "Anti-Aimbot angles", "Player List", "No detected cheats")
shared_esp_neverlose = ui.new_checkbox("AA", "Anti-Aimbot angles", "Shared ESP with Neverlose (Allies only)")

--@aa
local states = {"Global", "Fake Lag", "Stand", "Running", "Air", "Air-Duck", "Slow-walk", "Duck", "Duck-Running", "Safe-Head"}
local aa_settings = {}
local tab_type = ui.new_slider("AA", "Anti-Aimbot angles", "Tab", 1, 3, 1, true, "", 1, {
    [1] = "Builder",
    [2] = "Defensive",
    [3] = "Tweaks"
})
local state_selector = ui.new_combobox("AA", "Anti-Aimbot angles", "State selector", states)

local zalupa = to_hex(ui.get(ref.menu_color))
local panchan_fake_lag_defaults = {
    ["Fake Lag"] = 16,
    ["Stand"] = 14,
    ["Running"] = 10,
    ["Air"] = 14,
    ["Air-Duck"] = 14,
    ["Slow-walk"] = 12,
    ["Duck"] = 12,
    ["Duck-Running"] = 10,
    ["Safe-Head"] = 1
}

panchan_delayed_virtual = {
    database_key = "panchan_delayed_virtual_profiles_v1",
    version = 3,
    fields = {
        "panchan_delayed_preset",
        "panchan_delayed_crouch_preset",
        "panchan_delayed_preset_side",
        "panchan_delayed_preset_t",
        "panchan_delayed_preset_ct",
        "panchan_delayed_crouch_preset_t",
        "panchan_delayed_crouch_preset_ct",
        "panchan_delayed_delay_mode",
        "panchan_delayed_yaw_left",
        "panchan_delayed_yaw_right",
        "panchan_delayed_body_left",
        "panchan_delayed_body_right",
        "panchan_delayed_body_pattern",
        "panchan_delayed_body_pulse",
        "panchan_delayed_body_phase",
        "panchan_delayed_body_delay",
        "panchan_delayed_delay_fixed",
        "panchan_delayed_delay_from",
        "panchan_delayed_delay_to",
        "panchan_delayed_sequence_count",
        "panchan_delayed_delay_1",
        "panchan_delayed_delay_2",
        "panchan_delayed_delay_3",
        "panchan_delayed_delay_4",
        "panchan_delayed_delay_5",
        "panchan_delayed_delay_6",
        "panchan_delayed_delay_7",
        "panchan_delayed_delay_8"
    },
    values = {},
    ui = {},
    editor_state = "Global",
    editor_side = "T Side",
    loading = false,
    save_token = 0
}

panchan_delayed_settings_state = {}

function panchan_delayed_virtual_defaults()
    return {
        panchan_delayed_preset = "Panchan",
        panchan_delayed_crouch_preset = "Off",
        panchan_delayed_preset_side = "T Side",
        panchan_delayed_preset_t = "Panchan",
        panchan_delayed_preset_ct = "Panchan",
        panchan_delayed_crouch_preset_t = "Off",
        panchan_delayed_crouch_preset_ct = "Off",
        panchan_delayed_delay_mode = "Fixed",
        panchan_delayed_yaw_left = -30,
        panchan_delayed_yaw_right = 36,
        panchan_delayed_body_left = -58,
        panchan_delayed_body_right = 58,
        panchan_delayed_body_pattern = "Hold",
        panchan_delayed_body_pulse = 6,
        panchan_delayed_body_phase = "Synced",
        panchan_delayed_body_delay = 4,
        panchan_delayed_delay_fixed = 4,
        panchan_delayed_delay_from = 3,
        panchan_delayed_delay_to = 8,
        panchan_delayed_sequence_count = 4,
        panchan_delayed_delay_1 = 2,
        panchan_delayed_delay_2 = 4,
        panchan_delayed_delay_3 = 6,
        panchan_delayed_delay_4 = 8,
        panchan_delayed_delay_5 = 10,
        panchan_delayed_delay_6 = 12,
        panchan_delayed_delay_7 = 14,
        panchan_delayed_delay_8 = 16
    }
end

function panchan_delayed_virtual_normalize_side(side)
    return side == "CT Side" and "CT Side" or "T Side"
end

function panchan_delayed_virtual_slot_key(side, crouch)
    local suffix = panchan_delayed_virtual_normalize_side(side) == "CT Side" and "ct" or "t"
    return (crouch and "panchan_delayed_crouch_preset_" or "panchan_delayed_preset_") .. suffix
end

function panchan_delayed_virtual_side_preset(state, side, crouch)
    local key = panchan_delayed_virtual_slot_key(side, crouch)
    local fallback = crouch and state.panchan_delayed_crouch_preset or state.panchan_delayed_preset
    return state[key] or fallback or (crouch and "Off" or "Panchan")
end

function panchan_delayed_virtual_sync_editor(state)
    local side = panchan_delayed_virtual_normalize_side(state.panchan_delayed_preset_side)
    state.panchan_delayed_preset_side = side
    state.panchan_delayed_preset = panchan_delayed_virtual_side_preset(state, side, false)
    state.panchan_delayed_crouch_preset = panchan_delayed_virtual_side_preset(state, side, true)
    return state
end

function panchan_delayed_virtual_restrict_slowwalk(state_name, state)
    if state_name == "Slow-walk" or type(state) ~= "table" then
        return state
    end

    if state.panchan_delayed_preset == "Panchan Slowwalk" then
        state.panchan_delayed_preset = "Panchan"
    end
    if state.panchan_delayed_preset_t == "Panchan Slowwalk" then
        state.panchan_delayed_preset_t = "Panchan"
    end
    if state.panchan_delayed_preset_ct == "Panchan Slowwalk" then
        state.panchan_delayed_preset_ct = "Panchan"
    end

    return panchan_delayed_virtual_sync_editor(state)
end

function panchan_delayed_virtual_migrate_state(target, source)
    if type(source) == "table" then
        for _, field in ipairs(panchan_delayed_virtual.fields) do
            if source[field] ~= nil then
                target[field] = source[field]
            end
        end

        if source.panchan_delayed_preset_t == nil and source.panchan_delayed_preset ~= nil then
            target.panchan_delayed_preset_t = source.panchan_delayed_preset
        end
        if source.panchan_delayed_preset_ct == nil and source.panchan_delayed_preset ~= nil then
            target.panchan_delayed_preset_ct = source.panchan_delayed_preset
        end
        if source.panchan_delayed_crouch_preset_t == nil and source.panchan_delayed_crouch_preset ~= nil then
            target.panchan_delayed_crouch_preset_t = source.panchan_delayed_crouch_preset
        end
        if source.panchan_delayed_crouch_preset_ct == nil and source.panchan_delayed_crouch_preset ~= nil then
            target.panchan_delayed_crouch_preset_ct = source.panchan_delayed_crouch_preset
        end
    end

    return panchan_delayed_virtual_sync_editor(target)
end

function panchan_delayed_virtual_state(state_name)
    local state = panchan_delayed_virtual.values[state_name]

    if type(state) ~= "table" then
        state = panchan_delayed_virtual_defaults()
        panchan_delayed_virtual.values[state_name] = state
    end

    return panchan_delayed_virtual_restrict_slowwalk(state_name, state)
end

function panchan_delayed_virtual_restore()
    local saved = nil

    if database ~= nil and database.read ~= nil then
        local ok, value = pcall(database.read, panchan_delayed_virtual.database_key)
        if ok and type(value) == "table" then
            saved = type(value.values) == "table" and value.values or value
        end
    end

    for _, state_name in ipairs(states) do
        local target = panchan_delayed_virtual_defaults()
        local source = saved and saved[state_name] or nil
        panchan_delayed_virtual.values[state_name] = panchan_delayed_virtual_migrate_state(target, source)
    end
end

function panchan_delayed_virtual_save_now()
    if database == nil or database.write == nil then
        return
    end

    pcall(database.write, panchan_delayed_virtual.database_key, {
        version = panchan_delayed_virtual.version,
        values = panchan_delayed_virtual.values
    })
end

function panchan_delayed_virtual_queue_save()
    panchan_delayed_virtual.save_token = panchan_delayed_virtual.save_token + 1
    local token = panchan_delayed_virtual.save_token

    if client ~= nil and client.delay_call ~= nil then
        pcall(client.delay_call, 0.35, function()
            if token == panchan_delayed_virtual.save_token then
                panchan_delayed_virtual_save_now()
            end
        end)
    else
        panchan_delayed_virtual_save_now()
    end
end

function panchan_delayed_virtual_capture(state_name, side_override)
    if panchan_delayed_virtual.loading or state_name == nil then
        return
    end

    local target = panchan_delayed_virtual_state(state_name)
    local side = panchan_delayed_virtual_normalize_side(side_override or panchan_delayed_virtual.editor_side)

    for _, field in ipairs(panchan_delayed_virtual.fields) do
        local widget = panchan_delayed_virtual.ui[field]

        if widget ~= nil and field ~= "panchan_delayed_preset_side" then
            local ok, value = pcall(ui.get, widget)
            if ok then
                target[field] = value
            end
        end
    end

    target.panchan_delayed_preset_side = side
    target[panchan_delayed_virtual_slot_key(side, false)] = target.panchan_delayed_preset
    target[panchan_delayed_virtual_slot_key(side, true)] = target.panchan_delayed_crouch_preset
end

function panchan_delayed_virtual_update_preset_options(state_name)
    local widget = panchan_delayed_virtual.ui.panchan_delayed_preset
    if widget == nil then
        return
    end

    local options = {
        "Panchan", "Exaint", "Aggressive", "Universal", "Panchan 2026",
        "Panchan Pressure", "Meta", "Meta2", "brandog", "Chester Panchan"
    }
    if state_name == "Slow-walk" then
        options[#options + 1] = "Panchan Slowwalk"
    end
    options[#options + 1] = "Custom"
    pcall(ui.update, widget, options)
end

function panchan_delayed_virtual_load_editor(state_name)
    local source = panchan_delayed_virtual_sync_editor(panchan_delayed_virtual_state(state_name))
    panchan_delayed_virtual.editor_state = state_name
    panchan_delayed_virtual.editor_side = source.panchan_delayed_preset_side
    panchan_delayed_virtual.loading = true
    panchan_delayed_virtual_update_preset_options(state_name)

    for _, field in ipairs(panchan_delayed_virtual.fields) do
        local widget = panchan_delayed_virtual.ui[field]
        if widget ~= nil and source[field] ~= nil then
            pcall(ui.set, widget, source[field])
        end
    end

    panchan_delayed_virtual.loading = false
    panchan_delayed_virtual_capture(state_name)
end

function panchan_delayed_virtual_switch()
    local next_state = ui.get(state_selector)
    local previous_state = panchan_delayed_virtual.editor_state

    if previous_state ~= nil and previous_state ~= next_state then
        panchan_delayed_virtual_capture(previous_state)
    end

    panchan_delayed_virtual_load_editor(next_state)
end

function panchan_delayed_virtual_changed()
    if panchan_delayed_virtual.loading then
        return
    end

    panchan_delayed_virtual_capture(panchan_delayed_virtual.editor_state)
    panchan_delayed_virtual_queue_save()
end

function panchan_delayed_virtual_side_changed()
    if panchan_delayed_virtual.loading then
        return
    end

    local state_name = panchan_delayed_virtual.editor_state
    local previous_side = panchan_delayed_virtual.editor_side
    panchan_delayed_virtual_capture(state_name, previous_side)

    local target = panchan_delayed_virtual_state(state_name)
    local side = panchan_delayed_virtual_normalize_side(ui.get(panchan_delayed_virtual.ui.panchan_delayed_preset_side))
    target.panchan_delayed_preset_side = side
    target.panchan_delayed_preset = panchan_delayed_virtual_side_preset(target, side, false)
    target.panchan_delayed_crouch_preset = panchan_delayed_virtual_side_preset(target, side, true)
    panchan_delayed_virtual.editor_side = side

    panchan_delayed_virtual.loading = true
    pcall(ui.set, panchan_delayed_virtual.ui.panchan_delayed_preset, target.panchan_delayed_preset)
    pcall(ui.set, panchan_delayed_virtual.ui.panchan_delayed_crouch_preset, target.panchan_delayed_crouch_preset)
    panchan_delayed_virtual.loading = false

    panchan_delayed_virtual_capture(state_name, side)
    panchan_delayed_virtual_queue_save()
end

function panchan_delayed_virtual_collect_into(config_aa)
    panchan_delayed_virtual_capture(panchan_delayed_virtual.editor_state)

    for _, state_name in ipairs(states) do
        local target = config_aa[state_name]
        local source = panchan_delayed_virtual_state(state_name)

        if type(target) ~= "table" then
            target = {}
            config_aa[state_name] = target
        end

        for _, field in ipairs(panchan_delayed_virtual.fields) do
            target[field] = source[field]
        end
    end
end

function panchan_delayed_virtual_apply_from(config_aa)
    if type(config_aa) ~= "table" then
        return
    end

    for _, state_name in ipairs(states) do
        local source = config_aa[state_name]
        local target = panchan_delayed_virtual_state(state_name)

        if type(source) == "table" then
            panchan_delayed_virtual_migrate_state(target, source)
        end
    end

    panchan_delayed_virtual_load_editor(ui.get(state_selector))
    panchan_delayed_virtual_save_now()
end

function panchan_delayed_create_ui(settings, prefix)
    settings.panchan_delayed_preset = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed preset", "Panchan", "Exaint", "Aggressive", "Universal", "Panchan 2026", "Panchan Pressure", "Meta", "Meta2", "brandog", "Chester Panchan", "Custom")
    settings.panchan_delayed_crouch_preset = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Crouch Flow preset", "Off", "Exaint", "Aggressive", "Universal", "Meta", "Meta2", "brandog", "Chester Panchan", "Mapsat", "Mautlast", "Adaptive")
    settings.panchan_delayed_preset_side = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Preset side", "T Side", "CT Side")
    settings.panchan_delayed_delay_mode = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed timing", "Fixed", "Random Range", "Sequence")
    settings.panchan_delayed_yaw_left = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed yaw left", -180, 180, -30, true, "deg")
    settings.panchan_delayed_yaw_right = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed yaw right", -180, 180, 36, true, "deg")
    settings.panchan_delayed_body_left = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed body left", -60, 60, -58, true, "deg")
    settings.panchan_delayed_body_right = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed body right", -60, 60, 58, true, "deg")
    settings.panchan_delayed_body_pattern = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed body pattern", "Hold", "Pulse", "Random Hold")
    settings.panchan_delayed_body_pulse = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed body timing", 2, 22, 6, true, "t")
    settings.panchan_delayed_body_phase = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed body phase", "Synced", "One phase late", "Independent")
    settings.panchan_delayed_body_delay = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed independent timing", 1, 22, 4, true, "t")
    settings.panchan_delayed_delay_fixed = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed fixed timing", 1, 22, 4, true, "t")
    settings.panchan_delayed_delay_from = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed timing from", 1, 22, 3, true, "t")
    settings.panchan_delayed_delay_to = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed timing to", 1, 22, 8, true, "t")
    settings.panchan_delayed_sequence_count = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed sequence phases", 2, 8, 4, true, "", 1)

    for delayed_index = 1, 8 do
        settings["panchan_delayed_delay_" .. delayed_index] = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "Panchan Delayed delay " .. delayed_index, 1, 22, delayed_index * 2, true, "t")
    end
end

function panchan_delayed_virtual_initialize()
    local prefix = string.format('\a%s', zalupa) .. "Delayed \aC0C0C0FF"
    panchan_delayed_create_ui(panchan_delayed_virtual.ui, prefix)
    panchan_delayed_virtual_restore()

    for _, field in ipairs(panchan_delayed_virtual.fields) do
        local widget = panchan_delayed_virtual.ui[field]
        if widget ~= nil and field ~= "panchan_delayed_preset_side" then
            ui.set_callback(widget, panchan_delayed_virtual_changed)
        end
    end

    ui.set_callback(panchan_delayed_virtual.ui.panchan_delayed_preset_side, panchan_delayed_virtual_side_changed)
    ui.set_callback(state_selector, panchan_delayed_virtual_switch)
    panchan_delayed_virtual_load_editor(ui.get(state_selector))
    client.set_event_callback("shutdown", panchan_delayed_virtual_save_now)
end

for _, state_name in ipairs(states) do
    local prefix = string.format('\a%s', zalupa) .. state_name .. " \aC0C0C0FF"

    if state_name ~= "Global" then
        aa_settings[state_name] = {
            allow = ui.new_checkbox("AA", "Anti-Aimbot angles", "Allow " .. prefix),
            yaw_select     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw type", "Static", "L/R"),
            static_yaw     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw value", -180, 180, 0, true, "°"),
            l_yaw          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw left", -180, 180, 0, true, "°"),
            r_yaw          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw right", -180, 180, 0, true, "°"),
            rnd_yaw        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw randomization", 0, 100, 0, true, "%"),
            yaw_jitter     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter", "Off", "Offset", "Center", "Random", "Skitter", "Spin"),
            yaw_jitter_value = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter value", -180, 180, 0, true, "°"),
            yaw_jitter_rnd = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter randomization", 0, 100, 0, true, "%"),
            yaw_jitter_spin_range = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range", 1, 360, 360, true, "deg"),
            yaw_jitter_spin_range_randomize = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range randomize"),
            yaw_jitter_spin_range_from = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range from", 1, 360, 90, true, "deg"),
            yaw_jitter_spin_range_to = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range to", 1, 360, 360, true, "deg"),
            yaw_jitter_spin_speed = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin speed", 1, 128, 32, true, "t"),
            body_yaw     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw", "Off", "Static", "Jitter", "Custom Jitter", "Chaos Jitter", "PanchanModeV2", "Panchan Delayed"),
            panchan_v2_body_yaw_offset = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "PanchanModeV2 body yaw offset", -60, 60, 0, true, "°"),
            body_yaw_value     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "body yaw value", -60, 60, 0, true, "°"),
            delay          = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "delay type", "Off", "Tickbased", "Settable Random", "Chance", "Panchan Adaptive"),
            delay_randomize = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "delay randomize"),
            delay_t        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks", 1, 14, 1, true, "t"),
            delay_t_from   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks from", 1, 14, 1, true, "t"),
            delay_t_to     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks to", 1, 14, 3, true, "t"),
            delay_c        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "switch chance", 1, 100, 1, true, "%"),
            delay_rnd_select = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay stances", 2, 12, 2, true,  "", 1, {[2] = "2 Stances", [3] = "3 Stances", [4] = "4 Stances", [5] = "5 Stances", [6] = "6 Stances", [7] = "7 Stances", [8] = "8 Stances", [9] = "9 Stances", [10] = "10 Stances", [11] = "11 Stances", [12] = "12 Stances" }),
            delay_rnd_1    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "first delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_2    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_3    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "third delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_4    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "fourth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_5    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "fifth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_6    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "sixth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_7    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "seventh delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_8    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "eighth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_9    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "ninth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_10   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "tenth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_11   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "11 delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_12   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "12 delay ticks", 1, 14, 1, true, "t"),
            break_lc       = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "break lc"),
            defensive_aa   = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "defensive anti-aim"),

            defensive_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive pitch", "Off", "Down", "Up", "Random", "POTATO", "Semi-Up", "Semi-Down", "Static", "Jitter", "Sway", "Static Random", "Spin", "Micro Jitter"),
            defensive_pitch_static = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "pitch value", -89, 89, 0, true, "°"),
            defensive_pitch_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second pitch value", -89, 89, 0, true, "°"),

            defensive_yaw = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive yaw", "Off", "Opposite", "Opposite Jitter", "Side-Based", "Sideways", "Random", "3-Way", "5-Way", "Static", "Jitter", "Spin", "Negative Spin", "Distortion", "Sway", "Panchan", "Snap Jitter", "Adaptive Snap"),
            defensive_yaw_snap_mode = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "snap jitter mode", "Offset Snap Jitter", "Center Snap Jitter", "Skitter Snap Jitter", "Random Snap Jitter"),
            defensive_yaw_static = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw offset", -180, 180, 0, true, "°"),
            defensive_yaw_spin = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "spin speed", 1, 100, 1, true, "°s"),
            defensive_yaw_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second yaw offset", -180, 180, 0, true, "°"),
            defensive_yaw_delay = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw delay", 1, 14, 1, true, "t"),
        }
    else
        aa_settings[state_name] = {
            yaw_select     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw type", "Static", "L/R"),
            static_yaw     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw value", -180, 180, 0, true, "°"),
            l_yaw          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw left", -180, 180, 0, true, "°"),
            r_yaw          = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw right", -180, 180, 0, true, "°"),
            rnd_yaw        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw randomization", 0, 100, 0, true, "%"),
            yaw_jitter     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter", "Off", "Offset", "Center", "Random", "Skitter", "Spin"),
            yaw_jitter_value = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter value", -180, 180, 0, true, "°"),
            yaw_jitter_rnd = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter randomization", 0, 100, 0, true, "%"),
            yaw_jitter_spin_range = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range", 1, 360, 360, true, "deg"),
            yaw_jitter_spin_range_randomize = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range randomize"),
            yaw_jitter_spin_range_from = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range from", 1, 360, 90, true, "deg"),
            yaw_jitter_spin_range_to = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin range to", 1, 360, 360, true, "deg"),
            yaw_jitter_spin_speed = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw jitter spin speed", 1, 128, 32, true, "t"),
            body_yaw     = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "body yaw", "Off", "Static", "Jitter", "Custom Jitter", "Chaos Jitter", "PanchanModeV2", "Panchan Delayed"),
            panchan_v2_body_yaw_offset = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "PanchanModeV2 body yaw offset", -60, 60, 0, true, "°"),
            body_yaw_value     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "body yaw value", -60, 60, 0, true, "°"),
            delay          = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "delay type", "Off", "Tickbased", "Settable Random", "Chance", "Panchan Adaptive"),
            delay_randomize = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "delay randomize"),
            delay_t        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks", 1, 14, 1, true, "t"),
            delay_t_from   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks from", 1, 14, 1, true, "t"),
            delay_t_to     = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay ticks to", 1, 14, 3, true, "t"),
            delay_c        = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "switch chance", 1, 100, 1, true, "%"),
            delay_rnd_select = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "delay stances", 2, 12, 2, true,  "", 1, {[2] = "2 Stances", [3] = "3 Stances", [4] = "4 Stances", [5] = "5 Stances", [6] = "6 Stances", [7] = "7 Stances", [8] = "8 Stances", [9] = "9 Stances", [10] = "10 Stances", [11] = "11 Stances", [12] = "12 Stances" }),
            delay_rnd_1    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "first delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_2    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_3    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "third delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_4    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "fourth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_5    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "fifth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_6    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "sixth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_7    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "seventh delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_8    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "eighth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_9    = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "ninth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_10   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "tenth delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_11   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "11 delay ticks", 1, 14, 1, true, "t"),
            delay_rnd_12   = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "12 delay ticks", 1, 14, 1, true, "t"),
            break_lc       = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "break lc"),
            defensive_aa   = ui.new_checkbox("AA", "Anti-Aimbot angles", prefix .. "defensive anti-aim"),

            defensive_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive pitch", "Off", "Down", "Up", "Random", "POTATO", "Semi-Up", "Semi-Down", "Static", "Jitter", "Sway", "Static Random", "Spin", "Micro Jitter"),
            defensive_pitch_static = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "pitch value", -89, 89, 0, true, "°"),
            defensive_pitch_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second pitch value", -89, 89, 0, true, "°"),

            defensive_yaw = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "defensive yaw", "Off", "Opposite", "Opposite Jitter", "Side-Based", "Sideways", "Random", "3-Way", "5-Way", "Static", "Jitter", "Spin", "Negative Spin", "Distortion", "Sway", "Panchan", "Snap Jitter", "Adaptive Snap"),
            defensive_yaw_snap_mode = ui.new_combobox("AA", "Anti-Aimbot angles", prefix .. "snap jitter mode", "Offset Snap Jitter", "Center Snap Jitter", "Skitter Snap Jitter", "Random Snap Jitter"),
            defensive_yaw_static = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "yaw offset", -180, 180, 0, true, "°"),
            defensive_yaw_spin = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "spin speed", 1, 100, 1, true, "°s"),
            defensive_yaw_2 = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "second yaw offset", -180, 180, 0, true, "°"),
            defensive_yaw_delay = ui.new_slider("AA", "Anti-Aimbot angles", prefix .. "defensive yaw delay", 1, 14, 1, true, "t"),
        }
    end

    panchan_delayed_settings_state[aa_settings[state_name]] = state_name

    if aa_settings[state_name] and aa_settings[state_name].delay_rnd_select then
        local shake_state_name = state_name
        aa_settings[state_name].delay_shake = ui.new_button("AA", "Anti-Aimbot angles", prefix .. "\aFFD166FFshake delay", function()
            local state = aa_settings[shake_state_name]

            for i = 1, 12 do
                local slider = state["delay_rnd_" .. i]

                if slider then
                    ui.set(slider, math.random(1, 14))
                end
            end

            add_log("delay shake randomized " .. shake_state_name, 3, 150, 255, 150)
        end)
    end
end

panchan_delayed_virtual_initialize()

function is_body_yaw_delay_mode(mode)
    return mode == "Jitter" or mode == "Custom Jitter" or mode == "Chaos Jitter" or mode == "PanchanModeV2"
end

local menu_visibility_cache = {}
local aa_visibility_last_signature
local menu_visibility_last_signature
local function set_menu_visible(ref, visible)
    if ref == nil then
        return
    end

    visible = visible == true
    if menu_visibility_cache[ref] == visible then
        return
    end

    menu_visibility_cache[ref] = visible
    ui.set_visible(ref, visible)
end

local function append_menu_state(parts, ref)
    if ref == nil then
        parts[#parts + 1] = "<nil>"
        return
    end

    local values = { pcall(ui.get, ref) }
    if not values[1] then
        parts[#parts + 1] = "<error>"
        return
    end

    parts[#parts + 1] = "["
    for i = 2, #values do
        local value = values[i]
        if type(value) == "table" then
            for j = 1, #value do
                parts[#parts + 1] = tostring(value[j])
                parts[#parts + 1] = ","
            end
        else
            parts[#parts + 1] = tostring(value)
        end
        parts[#parts + 1] = ";"
    end
    parts[#parts + 1] = "]"
end

function panchan_delayed_virtual_visibility(is_visible, state_name)
    local refs = panchan_delayed_virtual.ui
    local crouch_state = state_name == "Duck" or state_name == "Duck-Running"
    local crouch_preset = ui.get(refs.panchan_delayed_crouch_preset)
    local crouch_override = is_visible and crouch_state and crouch_preset ~= "Off"
    local preset = ui.get(refs.panchan_delayed_preset)
    local custom = is_visible and not crouch_override and preset == "Custom"
    local timing = ui.get(refs.panchan_delayed_delay_mode)
    local pattern = ui.get(refs.panchan_delayed_body_pattern)
    local body_phase = ui.get(refs.panchan_delayed_body_phase)
    local sequence_count = ui.get(refs.panchan_delayed_sequence_count)

    set_menu_visible(refs.panchan_delayed_preset, is_visible and not crouch_override)
    set_menu_visible(refs.panchan_delayed_crouch_preset, is_visible and crouch_state)
    set_menu_visible(refs.panchan_delayed_preset_side, is_visible)
    set_menu_visible(refs.panchan_delayed_delay_mode, custom)
    set_menu_visible(refs.panchan_delayed_yaw_left, custom)
    set_menu_visible(refs.panchan_delayed_yaw_right, custom)
    set_menu_visible(refs.panchan_delayed_body_left, custom)
    set_menu_visible(refs.panchan_delayed_body_right, custom)
    set_menu_visible(refs.panchan_delayed_body_pattern, custom)
    set_menu_visible(refs.panchan_delayed_body_pulse, custom and pattern ~= "Hold")
    set_menu_visible(refs.panchan_delayed_body_phase, custom)
    set_menu_visible(refs.panchan_delayed_body_delay, custom and body_phase == "Independent")
    set_menu_visible(refs.panchan_delayed_delay_fixed, custom and timing == "Fixed")
    set_menu_visible(refs.panchan_delayed_delay_from, custom and timing == "Random Range")
    set_menu_visible(refs.panchan_delayed_delay_to, custom and timing == "Random Range")
    set_menu_visible(refs.panchan_delayed_sequence_count, custom and timing == "Sequence")

    for delayed_index = 1, 8 do
        set_menu_visible(
            refs["panchan_delayed_delay_" .. delayed_index],
            custom and timing == "Sequence" and delayed_index <= sequence_count
        )
    end
end

local function aa_visibility()
    local selected_state = ui.get(state_selector)
    local signature_parts = { tostring(cur_tab) }

    if cur_tab == 2 then
        signature_parts[#signature_parts + 1] = tostring(ui.get(tab_type))
        signature_parts[#signature_parts + 1] = tostring(selected_state)

        local selected = aa_settings[selected_state]
        local visibility_fields = {
            "allow", "fake_lag", "yaw_select", "yaw_jitter",
            "yaw_jitter_spin_range_randomize", "body_yaw", "delay",
            "delay_randomize", "delay_rnd_select", "defensive_aa",
            "defensive_pitch", "defensive_yaw"
        }
        if selected then
            for i = 1, #visibility_fields do
                append_menu_state(signature_parts, selected[visibility_fields[i]])
            end

            if selected.body_yaw and ui.get(selected.body_yaw) == "Panchan Delayed" then
                local delayed_ui = panchan_delayed_virtual.ui
                local delayed_fields = {
                    "panchan_delayed_preset", "panchan_delayed_crouch_preset",
                    "panchan_delayed_delay_mode", "panchan_delayed_body_pattern",
                    "panchan_delayed_body_phase", "panchan_delayed_sequence_count"
                }
                for i = 1, #delayed_fields do
                    append_menu_state(signature_parts, delayed_ui[delayed_fields[i]])
                end
            end
        end
    end

    local signature = table.concat(signature_parts, "\30")
    if signature == aa_visibility_last_signature then
        return
    end

    for _, state_name in ipairs(states) do
        local state = aa_settings[state_name]
        local is_current = (state_name == selected_state and cur_tab == 2 and ui.get(tab_type) == 1)
        local is_defensive_tab = (state_name == selected_state and cur_tab == 2 and ui.get(tab_type) == 2)
        local is_allowed = (state_name == "Global" or (state.allow and ui.get(state.allow)))
        local is_delayed_body = state.body_yaw and ui.get(state.body_yaw) == "Panchan Delayed"

        if state.allow then
            set_menu_visible(state.allow, is_current or is_defensive_tab)
        end

        if state.fake_lag then
            set_menu_visible(state.fake_lag, is_current and is_allowed)
        end

        if state.fake_lag_disable_on_exploit then
            set_menu_visible(state.fake_lag_disable_on_exploit, is_current and is_allowed and ui.get(state.fake_lag))
        end

        if state.fake_lag_ticks then
            set_menu_visible(state.fake_lag_ticks, is_current and is_allowed and ui.get(state.fake_lag))
        end

        if state.fake_lag_variance then
            set_menu_visible(state.fake_lag_variance, is_current and is_allowed and ui.get(state.fake_lag))
        end
        
        if state.yaw_select then
            set_menu_visible(state.yaw_select, is_current and is_allowed and not is_delayed_body)

            if state.static_yaw then
                set_menu_visible(state.static_yaw, is_current and is_allowed and not is_delayed_body and ui.get(state.yaw_select) == "Static")
            end

            local yaw_type = ui.get(state.yaw_select)
            local is_lr_randomizer = is_current and is_allowed and not is_delayed_body and yaw_type == "L/R"
            local is_lr_yaw = is_lr_randomizer

        if state.l_yaw then
            set_menu_visible(state.l_yaw, is_lr_yaw)
        end

        if state.r_yaw then
            set_menu_visible(state.r_yaw, is_lr_yaw)
        end

        if state.rnd_yaw then
            set_menu_visible(state.rnd_yaw, is_lr_randomizer)
        end

        if state.yaw_jitter then
            set_menu_visible(state.yaw_jitter, is_current and is_allowed and not is_delayed_body)
        end

        if state.yaw_jitter_value then
            set_menu_visible(state.yaw_jitter_value, is_current and is_allowed and not is_delayed_body and ui.get(state.yaw_jitter) ~= "Off" and ui.get(state.yaw_jitter) ~= "Spin")
        end

        if state.yaw_jitter_rnd then
            set_menu_visible(state.yaw_jitter_rnd, is_current and is_allowed and not is_delayed_body and ui.get(state.yaw_jitter) ~= "Off" and ui.get(state.yaw_jitter) ~= "Spin")
        end

        local spin_visible = is_current and is_allowed and not is_delayed_body and ui.get(state.yaw_jitter) == "Spin"
        local spin_range_random = state.yaw_jitter_spin_range_randomize and ui.get(state.yaw_jitter_spin_range_randomize)

        if state.yaw_jitter_spin_range then
            set_menu_visible(state.yaw_jitter_spin_range, spin_visible and not spin_range_random)
        end

        if state.yaw_jitter_spin_range_randomize then
            set_menu_visible(state.yaw_jitter_spin_range_randomize, spin_visible)
        end

        if state.yaw_jitter_spin_range_from then
            set_menu_visible(state.yaw_jitter_spin_range_from, spin_visible and spin_range_random)
        end

        if state.yaw_jitter_spin_range_to then
            set_menu_visible(state.yaw_jitter_spin_range_to, spin_visible and spin_range_random)
        end

        if state.yaw_jitter_spin_speed then
            set_menu_visible(state.yaw_jitter_spin_speed, spin_visible)
        end

        if state.body_yaw then
            set_menu_visible(state.body_yaw, is_current and is_allowed)
        end
        
        if state.body_yaw_value then
            local body_mode = ui.get(state.body_yaw)
            set_menu_visible(state.body_yaw_value, is_current and is_allowed and body_mode ~= "Off" and body_mode ~= "PanchanModeV2" and body_mode ~= "Panchan Delayed")
        end

        local is_panchan_mode_v2 = is_current and is_allowed and ui.get(state.body_yaw) == "PanchanModeV2"
        local is_panchan_delayed = is_current and is_allowed and is_delayed_body

        if state.panchan_v2_body_yaw_offset then
            set_menu_visible(state.panchan_v2_body_yaw_offset, is_panchan_mode_v2)
        end

        if state_name == selected_state then
            panchan_delayed_virtual_visibility(is_panchan_delayed, state_name)
        end

        if state.delay then
            set_menu_visible(state.delay, is_current and is_allowed and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_t then
            local delay_is_tickbased = ui.get(state.delay) == "Tickbased"
            local delay_is_adaptive = ui.get(state.delay) == "Panchan Adaptive"
            local delay_random_enabled = state.delay_randomize and ui.get(state.delay_randomize)
            set_menu_visible(state.delay_t, is_current and is_allowed and ((delay_is_tickbased and not delay_random_enabled) or delay_is_adaptive) and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_randomize then
            set_menu_visible(state.delay_randomize, is_current and is_allowed and ui.get(state.delay) == "Tickbased" and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_t_from then
            set_menu_visible(state.delay_t_from, is_current and is_allowed and ui.get(state.delay) == "Tickbased" and state.delay_randomize and ui.get(state.delay_randomize) and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_t_to then
            set_menu_visible(state.delay_t_to, is_current and is_allowed and ui.get(state.delay) == "Tickbased" and state.delay_randomize and ui.get(state.delay_randomize) and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_c then
            set_menu_visible(state.delay_c, is_current and is_allowed and (ui.get(state.delay) == "Chance" or ui.get(state.delay) == "Panchan Adaptive") and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        if state.delay_rnd_select then
            set_menu_visible(state.delay_rnd_select, is_current and is_allowed and ui.get(state.delay) == "Settable Random" and is_body_yaw_delay_mode(ui.get(state.body_yaw)))
        end

        local is_settable_delay = is_current and is_allowed and ui.get(state.delay) == "Settable Random" and is_body_yaw_delay_mode(ui.get(state.body_yaw))

        for i = 1, 12 do
            local slider = state["delay_rnd_" .. i]

            if slider then
                set_menu_visible(slider, is_settable_delay and ui.get(state.delay_rnd_select) >= i)
            end
        end

        if state.delay_shake then
            set_menu_visible(state.delay_shake, is_settable_delay)
        end

        if state.break_lc then
            set_menu_visible(state.break_lc, is_current and is_allowed)
        end

        if state.defensive_aa then
            set_menu_visible(state.defensive_aa, is_defensive_tab and is_allowed)
        end

        if state.defensive_pitch then
            set_menu_visible(state.defensive_pitch, is_defensive_tab and is_allowed and ui.get(state.defensive_aa))
        end

        if state.defensive_pitch_static then
            local pitch_mode = ui.get(state.defensive_pitch)
            local pitch_custom = pitch_mode == "Static" or pitch_mode == "Jitter" or pitch_mode == "Sway" or pitch_mode == "Static Random" or pitch_mode == "Spin"
            set_menu_visible(state.defensive_pitch_static, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and pitch_custom)
        end

        if state.defensive_pitch_2 then
            local pitch_mode = ui.get(state.defensive_pitch)
            local pitch_pair = pitch_mode == "Jitter" or pitch_mode == "Static Random" or pitch_mode == "Spin" or pitch_mode == "Sway"
            set_menu_visible(state.defensive_pitch_2, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and pitch_pair)
        end



        if state.defensive_yaw then
            set_menu_visible(state.defensive_yaw, is_defensive_tab and is_allowed and ui.get(state.defensive_aa))
        end

        if state.defensive_yaw_snap_mode then
            set_menu_visible(state.defensive_yaw_snap_mode, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and ui.get(state.defensive_yaw) == "Snap Jitter")
        end

        if state.defensive_yaw_static then
            local yaw_mode = ui.get(state.defensive_yaw)
            local yaw_custom = yaw_mode == "Static" or yaw_mode == "Jitter" or yaw_mode == "Snap Jitter" or yaw_mode == "Sway"
            set_menu_visible(state.defensive_yaw_static, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and yaw_custom)
        end

        if state.defensive_yaw_2 then
            local yaw_mode = ui.get(state.defensive_yaw)
            local yaw_pair = yaw_mode == "Jitter" or yaw_mode == "Snap Jitter" or yaw_mode == "Sway"
            set_menu_visible(state.defensive_yaw_2, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and yaw_pair)
        end

        if state.defensive_yaw_delay then
            set_menu_visible(state.defensive_yaw_delay, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_yaw) == "Jitter" or ui.get(state.defensive_yaw) == "Snap Jitter"))
        end

        
            if state.defensive_yaw_spin then
                set_menu_visible(state.defensive_yaw_spin, is_defensive_tab and is_allowed and ui.get(state.defensive_aa) and (ui.get(state.defensive_yaw) == "Spin" or ui.get(state.defensive_yaw) == "Negative Spin"))
            end
        end
    end

    aa_visibility_last_signature = signature
end

aa_visibility()


--@end

---@tweaks

local backstab = ui.new_checkbox("AA", "Anti-Aimbot angles", "Avoid Backstab")
local legit_aa = ui.new_checkbox("AA", "Anti-Aimbot angles", "Legit AA and Bombsite e-fix")
local legit_aa_type = ui.new_combobox("AA", "Anti-Aimbot angles", "Legit AA Type", "Opposite", "2-Way")
local fast_ladder = ui.new_multiselect("AA", "Anti-Aimbot angles", "Fast Ladder Movement", "Ascending", "Descending")
local ladder_yaw180 = ui.new_checkbox("AA", "Anti-Aimbot angles", "Ladder yaw 180")
local warmup_aa = ui.new_checkbox("AA", "Anti-Aimbot angles", "Warmup AA")
local warmup_aa_activation = ui.new_combobox("AA", "Anti-Aimbot angles", "Warmup AA Activation", "Warmup", "No Enemies", "Force")
local warmup_aa_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", "Warmup AA Pitch", "Disabled", "Down")
local warmup_aa_yaw = ui.new_combobox("AA", "Anti-Aimbot angles", "Warmup AA Yaw", "Spin", "Distortion", "L/R", "Spin 2")
local warmup_aa_range = ui.new_slider("AA", "Anti-Aimbot angles", "Warmup AA Range", 1, 360, 360, true, "°")
local warmup_aa_speed = ui.new_slider("AA", "Anti-Aimbot angles", "Warmup AA Speed", 1, 128, 32, true, "t")
local warmup_aa_left = ui.new_slider("AA", "Anti-Aimbot angles", "Warmup AA Left", -180, 180, 0, true, "°")
local warmup_aa_right = ui.new_slider("AA", "Anti-Aimbot angles", "Warmup AA Right", -180, 180, 0, true, "°")
local anti_bruteforce = ui.new_checkbox("AA", "Anti-Aimbot angles", "Anti-Bruteforce")
panchan_fake_lag = ui.new_checkbox("AA", "Fake Lag", "Panchan Fake Lag")
panchan_fake_lag_disable_on_exploit = ui.new_checkbox("AA", "Fake Lag", "Disable Fake Lag On Exploit")
panchan_fake_lag_ticks = ui.new_slider("AA", "Fake Lag", "Panchan Fake Lag Ticks", 1, 24, 16, true, "t")
panchan_fake_lag_variance = ui.new_slider("AA", "Fake Lag", "Panchan Fake Lag Variance", 0, 100, 0, true, "%")
ragebot_improved_label = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "RAGE BOT IMPROVED\aC0C0C0FF - patch / bt / movement / hitscan")
ragebot_improved = ui.new_multiselect("AA", "Fake Lag", "RAGE BOT IMPROVED", "Delay Shot Fix", "BT Fix", "Jump Scout Fix", "Hitscan Fix")
ragebot_hitscan_sample_count = ui.new_slider("AA", "Fake Lag", "Scan density", 128, 512, 512)
ragebot_hitscan_percent_cap = ui.new_slider("AA", "Fake Lag", "Accuracy ceiling", 1, 100, 76, true, "%")
ragebot_hitscan_hitbox_cap = ui.new_slider("AA", "Fake Lag", "Hitbox budget", 1, 19, 18)
ragebot_hitscan_hitbox_mask = ui.new_slider("AA", "Fake Lag", "Scan mask", 1, 255, 255)
local safehead = ui.new_multiselect("AA", "Anti-Aimbot angles", "Safe Head Options", "Knife", "Zeus", "Height Advantage")
local freestand = ui.new_hotkey("AA", "Anti-Aimbot angles", "Freestanding")
local manual_l = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Left")
local manual_r = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Right")
local manual_f = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Forward")
local manual_res = ui.new_hotkey("AA", "Anti-Aimbot angles", "Manual Reset")
local edge_yaw = ui.new_hotkey("AA", "Anti-Aimbot angles", "Edge Yaw")
flick_exploit = ui.new_checkbox("AA", "Anti-Aimbot angles", "Fake Flick")
flick_exploit_states = ui.new_multiselect("AA", "Anti-Aimbot angles", "Conditions", "Stand", "Running", "Air", "Air-Duck", "Slow-walk", "Duck", "Duck-Running", "Safe-Head")
flick_exploit_delay = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Exploit Delay", 1, 16, 4, true, "t")
flick_exploit_offset = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Exploit Offset", -180, 180, 90, true, "deg")
flick_exploit_body = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Exploit Body", 0, 60, 60, true, "deg")
flick_exploit_pitch = ui.new_combobox("AA", "Anti-Aimbot angles", "Flick Exploit Pitch", "Off", "Static", "Sway", "Switch", "Random", "Static Random")
flick_exploit_pitch_value = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Pitch Value", -89, 89, 0, true, "deg")
flick_exploit_pitch_second = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Pitch Second", -89, 89, 0, true, "deg")
flick_exploit_pitch_speed = ui.new_slider("AA", "Anti-Aimbot angles", "Flick Pitch Speed", -75, 75, 20, true, "", 0.1)
roll_antiaim = ui.new_checkbox("AA", "Anti-Aimbot angles", "Roll Anti-Aim")
roll_antiaim_key = ui.new_hotkey("AA", "Anti-Aimbot angles", "Roll Anti-Aim Key")
roll_antiaim_value = ui.new_slider("AA", "Anti-Aimbot angles", "Roll Anti-Aim Value", -50, 50, 0, true, "deg")
panchan_exploit = ui.new_checkbox("AA", "Anti-Aimbot angles", "\aFF0000FFWARNING!\aC0C0C0FF PANCHAN EXPLOIT")
panchan_exploit_mode = ui.new_combobox("AA", "Anti-Aimbot angles", "PANCHAN EXPLOIT Mode", "Panchan V2 Meta (OFF DOUBLE TAP AND HS)", "Panchan Adaptive Core (OFF DOUBLE TAP AND HS)", "Panchan Massive Fake (OFF DOUBLE TAP AND HS)")
panchan_exploit_key = ui.new_hotkey("AA", "Anti-Aimbot angles", "PANCHAN EXPLOIT Bind")
airlag_panchan_exploit = ui.new_checkbox("AA", "Anti-Aimbot angles", "PANCHAN AIRLAG")
airlag_panchan_key = ui.new_hotkey("AA", "Anti-Aimbot angles", "PANCHAN AIRLAG Bind")
--local force_lag = ui.new_hotkey("AA", "Anti-Aimbot angles", "Force Lag In Air")
pcall(ui.set, flick_exploit_states, "Stand", "Running", "Air", "Air-Duck", "Slow-walk", "Duck", "Duck-Running", "Safe-Head")
---@end

---@main menu

lua_name_label = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Panchan\aC0C0C0FF • ".. build)
lua_user_label = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Username\aC0C0C0FF - ".. username)
lua_update_label = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Last Update\aC0C0C0FF - ".. update_date)
lua_session = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Current Session\aC0C0C0FF - 0 min 0 sec")
session_stats = session_stats or {
    enemy_misses = 0,
    your_misses = 0,
    last_enemy_miss = {}
}
session_stats.enemy_misses = session_stats.enemy_misses or 0
session_stats.your_misses = session_stats.your_misses or 0
session_stats.last_enemy_miss = session_stats.last_enemy_miss or {}
lua_enemy_misses = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Enemy Misses\aC0C0C0FF - 0")
lua_your_misses = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Your Misses\aC0C0C0FF - 0")
custom_logs_note = ui.new_label("AA", "Fake Lag", "\a" .. zalupa .. "Custom Logs\aC0C0C0FF - prefix + command print")
hit_logs = ui.new_checkbox("AA", "Fake Lag", "Enable Custom Logs")
hit_logs_type = ui.new_multiselect("AA", "Fake Lag", "Custom Logs Output", "Console", "Under Crosshair")
hit_logs_color = ui.new_color_picker("AA", "Fake Lag", "Custom Logs Color", 255, 255, 255, 255)
log_prefix_textbox = ui.new_textbox("AA", "Fake Lag", "Log Prefix")
log_prefix_color = ui.new_color_picker("AA", "Fake Lag", "Console Prefix Color", 113, 104, 230, 255)
log_console_color = ui.new_color_picker("AA", "Fake Lag", "Console Log Color", 198, 203, 209, 255)
print_command_button = ui.new_button("AA", "Fake Lag", "\aB4F000FFPrint Command", function()
    print("custom logs ready")
end)
misc_watermark = ui.new_checkbox("AA", "Fake Lag", "Watermark")
misc_watermark_text = ui.new_textbox("AA", "Fake Lag", "Watermark Text")
misc_watermark_beta_text = ui.new_textbox("AA", "Fake Lag", "Watermark Beta Text")
misc_watermark_type = ui.new_combobox("AA", "Fake Lag", "Watermark Type", "Default", "Custom", "Luasense")
misc_watermark_font = ui.new_slider("AA", "Fake Lag", "Watermark Font", 1, 4, 1, true, "", 1, {
    [1] = "Default",
    [2] = "Pixel",
    [3] = "Console",
    [4] = "Bold"
})
misc_watermark_remove_space = ui.new_combobox("AA", "Fake Lag", "Watermark Remove Space", "No", "Yes")
misc_watermark_color = ui.new_color_picker("AA", "Fake Lag", "Watermark Color", 120, 150, 255, 255)
misc_watermark_gradient = ui.new_checkbox("AA", "Fake Lag", "Watermark Gradient")
misc_watermark_second_color = ui.new_color_picker("AA", "Fake Lag", "Watermark Second Color", 255, 255, 255, 255)
misc_watermark_beta_color = ui.new_color_picker("AA", "Fake Lag", "Watermark Beta Color", 255, 90, 90, 255)
misc_watermark_position = ui.new_combobox("AA", "Fake Lag", "Watermark Position", "Right", "Left", "Center", "Custom")
misc_watermark_rainbow = ui.new_checkbox("AA", "Fake Lag", "Watermark Rainbow")
misc_watermark_blink_speed = ui.new_slider("AA", "Fake Lag", "Watermark Blink Speed", 1, 100, 35, true, "%")
misc_watermark_rainbow_speed = ui.new_slider("AA", "Fake Lag", "Watermark Rainbow Speed", 1, 100, 42, true, "%")
misc_watermark_encode_amount = ui.new_slider("AA", "Fake Lag", "Encode Amount", 0, 100, 0, true, "%")
misc_watermark_encode_speed = ui.new_slider("AA", "Fake Lag", "Encode Speed", 1, 100, 35, true, "%")
ui.set(log_prefix_textbox, "Panchan")
ui.set(misc_watermark_text, "panchan.beta")
ui.set(misc_watermark_beta_text, "BETA")

---@end

local function menu_visibility_main()
    set_menu_visible(back_button, cur_tab ~= 1)
    set_menu_visible(aa_button, cur_tab == 1)
    set_menu_visible(visuals_button, cur_tab == 1)
    set_menu_visible(misc_button, cur_tab == 1)
    set_menu_visible(cfg_button, cur_tab == 1)
    set_menu_visible(lua_name_label, cur_tab == 1)
    set_menu_visible(lua_user_label, cur_tab == 1)
    set_menu_visible(lua_update_label, cur_tab == 1)
    set_menu_visible(lua_session, cur_tab == 1)
    set_menu_visible(lua_enemy_misses, cur_tab == 1)
    set_menu_visible(lua_your_misses, cur_tab == 1)
end

local function menu_visibility_aa()
    set_menu_visible(state_selector, cur_tab == 2 and (ui.get(tab_type) == 1 or ui.get(tab_type) == 2))
    set_menu_visible(tab_type, cur_tab == 2)

    set_menu_visible(backstab, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(legit_aa, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(legit_aa_type, cur_tab == 2 and ui.get(legit_aa) and ui.get(tab_type) == 3)
    set_menu_visible(fast_ladder, false)
    set_menu_visible(ladder_yaw180, false)
    set_menu_visible(warmup_aa, cur_tab == 2 and ui.get(tab_type) == 3)
    local warmup_visible = cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(warmup_aa)
    local warmup_yaw_mode = warmup_visible and ui.get(warmup_aa_yaw) or "Spin"
    set_menu_visible(warmup_aa_activation, warmup_visible)
    set_menu_visible(warmup_aa_pitch, warmup_visible)
    set_menu_visible(warmup_aa_yaw, warmup_visible)
    set_menu_visible(warmup_aa_range, warmup_visible and (warmup_yaw_mode == "Spin" or warmup_yaw_mode == "Distortion"))
    set_menu_visible(warmup_aa_speed, warmup_visible and (warmup_yaw_mode == "Spin" or warmup_yaw_mode == "Distortion"))
    set_menu_visible(warmup_aa_left, warmup_visible and warmup_yaw_mode == "L/R")
    set_menu_visible(warmup_aa_right, warmup_visible and warmup_yaw_mode == "L/R")
    set_menu_visible(anti_bruteforce, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(jitter_correction, false)
    set_menu_visible(fake_flick, false)
    set_menu_visible(adaptive_ping_spike, false)
    set_menu_visible(fake_flick_conditions, false)
    set_menu_visible(early_quickpeek_autostop, false)
    set_menu_visible(quickpeek_weapon, false)
    set_menu_visible(quickpeek_dt_options, false)
    set_menu_visible(quickpeek_dt_options_scout, false)
    set_menu_visible(quickpeek_dt_options_scar, false)
    set_menu_visible(quickpeek_dt_options_pistols, false)
    set_menu_visible(quickpeek_dt_options_deagle, false)
    set_menu_visible(quickpeek_dt_options_any, false)
    set_menu_visible(experimental_predict, false)
    set_menu_visible(cheat_revealer, false)
    set_menu_visible(cheat_revealer_list, false)
    set_menu_visible(safehead, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(freestand, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(manual_l, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(manual_r, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(manual_res, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(manual_f, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(edge_yaw, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(flick_exploit, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(flick_exploit_states, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit))
    set_menu_visible(flick_exploit_delay, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit))
    set_menu_visible(flick_exploit_offset, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit))
    set_menu_visible(flick_exploit_body, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit))
    set_menu_visible(flick_exploit_pitch, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit))
    set_menu_visible(flick_exploit_pitch_value, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit) and ui.get(flick_exploit_pitch) ~= "Off")
    set_menu_visible(flick_exploit_pitch_second, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit) and ui.get(flick_exploit_pitch) ~= "Off" and ui.get(flick_exploit_pitch) ~= "Static")
    set_menu_visible(flick_exploit_pitch_speed, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(flick_exploit) and ui.get(flick_exploit_pitch) == "Sway")
    set_menu_visible(roll_antiaim, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(roll_antiaim_key, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(roll_antiaim))
    set_menu_visible(roll_antiaim_value, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(roll_antiaim))
    set_menu_visible(panchan_exploit, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(panchan_exploit_mode, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(panchan_exploit))
    set_menu_visible(panchan_exploit_key, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(panchan_exploit))
    set_menu_visible(airlag_panchan_exploit, cur_tab == 2 and ui.get(tab_type) == 3)
    set_menu_visible(airlag_panchan_key, cur_tab == 2 and ui.get(tab_type) == 3 and ui.get(airlag_panchan_exploit))
end

local function menu_visibility_visuals()
    set_menu_visible(center_indicators, cur_tab == 3)
    set_menu_visible(color, cur_tab == 3 and ui.get(center_indicators))
    set_menu_visible(center_indicators_type, cur_tab == 3 and ui.get(center_indicators))
    set_menu_visible(hit_logs, false)
    set_menu_visible(hit_logs_color, false)
    set_menu_visible(hit_logs_type, false)
    set_menu_visible(_custom_scope, cur_tab == 3)
    set_menu_visible(custom_scope_color, cur_tab == 3 and ui.get(_custom_scope))
    set_menu_visible(custom_scope_size, cur_tab == 3 and ui.get(_custom_scope))
    set_menu_visible(custom_scope_gap, cur_tab == 3 and ui.get(_custom_scope))
    set_menu_visible(custom_scope_style, cur_tab == 3 and ui.get(_custom_scope))
    set_menu_visible(custom_scope_disable_animation, cur_tab == 3 and ui.get(_custom_scope))
    set_menu_visible(manual_ind, cur_tab == 3)
    set_menu_visible(manual_ind_color, cur_tab == 3 and ui.get(manual_ind))
    set_menu_visible(revolver_helper, cur_tab == 3)
    set_menu_visible(damage_indicator, cur_tab == 3)
    set_menu_visible(damage_indicator_font, cur_tab == 3 and ui.get(damage_indicator))
    set_menu_visible(enable_aspect_ratio, cur_tab == 3)
    set_menu_visible(aspect_ratio_reference, cur_tab == 3 and ui.get(enable_aspect_ratio))
    set_menu_visible(debug_text, cur_tab == 3)
    set_menu_visible(debug_text_position, cur_tab == 3 and ui.get(debug_text))
    set_menu_visible(velocity_modifier, cur_tab == 3)
    set_menu_visible(animated_zoom, cur_tab == 3)
    set_menu_visible(zoom_val, cur_tab == 3 and ui.get(animated_zoom))
    set_menu_visible(visual_tracer, cur_tab == 3)
    set_menu_visible(visual_tracer_type, cur_tab == 3 and ui.get(visual_tracer))
    set_menu_visible(visual_tracer_impact_mode, cur_tab == 3 and ui.get(visual_tracer))
    set_menu_visible(visual_tracer_color, cur_tab == 3 and ui.get(visual_tracer))
end

local function menu_visibility_misc()
    set_menu_visible(custom_logs_note, cur_tab == 4)
    set_menu_visible(hit_logs, cur_tab == 4)
    set_menu_visible(hit_logs_type, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(hit_logs_color, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(log_prefix_textbox, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(log_prefix_color, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(log_console_color, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(print_command_button, cur_tab == 4 and ui.get(hit_logs))
    set_menu_visible(misc_watermark, cur_tab == 4)
    set_menu_visible(misc_watermark_type, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_text, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_beta_text, cur_tab == 4 and ui.get(misc_watermark) and ui.get(misc_watermark_type) == "Luasense")
    set_menu_visible(misc_watermark_font, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_remove_space, cur_tab == 4 and ui.get(misc_watermark) and ui.get(misc_watermark_type) == "Luasense")
    set_menu_visible(misc_watermark_color, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_gradient, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_second_color, cur_tab == 4 and ui.get(misc_watermark) and ui.get(misc_watermark_gradient))
    set_menu_visible(misc_watermark_beta_color, cur_tab == 4 and ui.get(misc_watermark) and ui.get(misc_watermark_type) == "Luasense")
    set_menu_visible(misc_watermark_position, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_rainbow, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_blink_speed, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_rainbow_speed, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_encode_amount, cur_tab == 4 and ui.get(misc_watermark))
    set_menu_visible(misc_watermark_encode_speed, cur_tab == 4 and ui.get(misc_watermark) and ui.get(misc_watermark_encode_amount) > 0)
    set_menu_visible(ragebot_improved_label, cur_tab == 4)
    set_menu_visible(ragebot_improved, cur_tab == 4)
    set_menu_visible(ragebot_hitscan_sample_count, cur_tab == 4 and ragebot_improved_enabled("Hitscan Fix"))
    set_menu_visible(ragebot_hitscan_percent_cap, cur_tab == 4 and ragebot_improved_enabled("Hitscan Fix"))
    set_menu_visible(ragebot_hitscan_hitbox_cap, cur_tab == 4 and ragebot_improved_enabled("Hitscan Fix"))
    set_menu_visible(ragebot_hitscan_hitbox_mask, cur_tab == 4 and ragebot_improved_enabled("Hitscan Fix"))
    set_menu_visible(recharge_fix, cur_tab == 4)
    set_menu_visible(fix_exploits, cur_tab == 4)
    set_menu_visible(jitter_correction, cur_tab == 4)
    set_menu_visible(jitter_correction_esp_flag, cur_tab == 4 and ui.get(jitter_correction))
    set_menu_visible(fake_flick, cur_tab == 4 and ui.get(jitter_correction))
    set_menu_visible(adaptive_ping_spike, cur_tab == 4 and ui.get(jitter_correction))
    set_menu_visible(fake_flick_conditions, cur_tab == 4 and ui.get(jitter_correction) and ui.get(fake_flick))
    set_menu_visible(defensive_correct, cur_tab == 4)
    set_menu_visible(resolver_lagcomp, cur_tab == 4)
    set_menu_visible(early_quickpeek_autostop, cur_tab == 4)
    set_menu_visible(quickpeek_weapon, cur_tab == 4 and ui.get(early_quickpeek_autostop))
    local quickpeek_visible = cur_tab == 4 and ui.get(early_quickpeek_autostop)
    local quickpeek_profile = quickpeek_visible and ui.get(quickpeek_weapon) or ""
    set_menu_visible(quickpeek_dt_options, quickpeek_visible and quickpeek_profile == "AWP")
    set_menu_visible(quickpeek_dt_options_scout, quickpeek_visible and quickpeek_profile == "SSG 08")
    set_menu_visible(quickpeek_dt_options_scar, quickpeek_visible and quickpeek_profile == "SCAR")
    set_menu_visible(quickpeek_dt_options_pistols, quickpeek_visible and quickpeek_profile == "Pistols")
    set_menu_visible(quickpeek_dt_options_deagle, quickpeek_visible and quickpeek_profile == "Deagle")
    set_menu_visible(quickpeek_dt_options_any, quickpeek_visible and quickpeek_profile == "Any")
    set_menu_visible(experimental_predict, cur_tab == 4)
    set_menu_visible(cheat_revealer, cur_tab == 4)
    set_menu_visible(cheat_revealer_list, cur_tab == 4 and (ui.get(cheat_revealer) == "Player List" or ui.get(cheat_revealer) == "Both"))
    set_menu_visible(shared_esp_neverlose, cur_tab == 4)
    set_menu_visible(console_filter, cur_tab == 4)
    set_menu_visible(teammate_aimbot, cur_tab == 4)
    set_menu_visible(duck_on_fd, cur_tab == 4)
    set_menu_visible(fake_duck_unspeed, cur_tab == 4)
    set_menu_visible(fake_duck_unspeed_scale, cur_tab == 4 and ui.get(fake_duck_unspeed))
    set_menu_visible(fake_duck_freezetime, cur_tab == 4)
    set_menu_visible(_clantag, cur_tab == 4)
    set_menu_visible(delay_fix, cur_tab == 4)
    set_menu_visible(delay_fix_weapons, cur_tab == 4 and ui.get(delay_fix))
    set_menu_visible(_trashtalk, cur_tab == 4)
    set_menu_visible(trashtalk_mode, cur_tab == 4 and ui.get(_trashtalk))
    set_menu_visible(trashtalk_on_death, cur_tab == 4)
    set_menu_visible(double_zoom, cur_tab == 4)
    set_menu_visible(double_zoom_key, cur_tab == 4 and ui.get(double_zoom))
    set_menu_visible(double_zoom_amount, cur_tab == 4 and ui.get(double_zoom))
    set_menu_visible(hirate_indicator, cur_tab == 4)
    set_menu_visible(hirate_reset, cur_tab == 4 and ui.get(hirate_indicator))
    set_menu_visible(dormant_aimbot, cur_tab == 4)
    set_menu_visible(dormant_aimbot_key, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_selection, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_hitboxes, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_accuracy, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_mindmg, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_indicator, cur_tab == 4 and ui.get(dormant_aimbot))
    set_menu_visible(dormant_aimbot_multipoint, false)
    set_menu_visible(dormant_aimbot_autostop, false)
    set_menu_visible(dormant_aimbot_max_fov, false)
    set_menu_visible(dormant_aimbot_max_distance, false)
    set_menu_visible(dormant_aimbot_cooldown, false)
    set_menu_visible(dormant_aimbot_timeout, false)
    set_menu_visible(fps_optimize, cur_tab == 4)
    set_menu_visible(animfix, cur_tab == 4)
    set_menu_visible(fast_ladder, cur_tab == 4)
    set_menu_visible(ladder_yaw180, cur_tab == 4)
    set_menu_visible(extendedbacktrack, cur_tab == 4)
end

function menu_visibility()
    local signature_parts = { tostring(cur_tab) }
    local watch = {
        tab_type, legit_aa, warmup_aa, warmup_aa_yaw, flick_exploit,
        flick_exploit_pitch, roll_antiaim, panchan_exploit, airlag_panchan_exploit,
        center_indicators, _custom_scope, manual_ind, damage_indicator,
        enable_aspect_ratio, debug_text, animated_zoom, visual_tracer,
        hit_logs, misc_watermark, misc_watermark_type, misc_watermark_gradient,
        misc_watermark_encode_amount, ragebot_improved, jitter_correction,
        fake_flick, early_quickpeek_autostop, quickpeek_weapon, cheat_revealer,
        fake_duck_unspeed, delay_fix, _trashtalk, double_zoom,
        hirate_indicator, dormant_aimbot
    }
    for i = 1, #watch do
        append_menu_state(signature_parts, watch[i])
    end

    local signature = table.concat(signature_parts, "\30")
    if signature == menu_visibility_last_signature then
        return
    end

    menu_visibility_main()
    menu_visibility_aa()
    menu_visibility_visuals()
    menu_visibility_misc()
    menu_visibility_last_signature = signature
end


menu_visibility()

---@end

---@viewmodel
;(function()
    local VM = {
        tab = "AA",
        group = "Anti-Aimbot angles",
        db_key = "panchan_view_model_state",
        refs = {},
        original = {},
        raw_float_cvars = {
            viewmodel_fov = true,
            viewmodel_offset_x = true,
            viewmodel_offset_y = true,
            viewmodel_offset_z = true
        },
        was_enabled = false,
        was_bob_enabled = false,
        loading = false,
        config_loading = false,
        force_apply_until = 0,
        save_token = 0
    }

    function VM.clamp(value, min, max)
        value = tonumber(value) or min

        if value < min then
            return min
        end

        if value > max then
            return max
        end

        return value
    end

    function VM.round(value)
        value = tonumber(value) or 0

        if value >= 0 then
            return math.floor(value + 0.5)
        end

        return math.ceil(value - 0.5)
    end

    function VM.read_cvar(name, fallback)
        if cvar and cvar[name] then
            local ok_float, value_float = pcall(function()
                return cvar[name]:get_float()
            end)

            if ok_float and value_float ~= nil then
                return tonumber(value_float) or fallback
            end

            local ok_int, value_int = pcall(function()
                return cvar[name]:get_int()
            end)

            if ok_int and value_int ~= nil then
                return tonumber(value_int) or fallback
            end

            local ok_string, value_string = pcall(function()
                return cvar[name]:get_string()
            end)

            if ok_string and value_string ~= nil then
                return tonumber(value_string) or fallback
            end
        end

        if client and client.get_cvar then
            local ok, value = pcall(client.get_cvar, name)

            if ok and value ~= nil then
                return tonumber(value) or fallback
            end
        end

        return fallback
    end

    function VM.write_cvar(name, value)
        value = tostring(value)

        if cvar and cvar[name] then
            local number_value = tonumber(value)

            if number_value ~= nil then
                if VM.raw_float_cvars[name] then
                    local ok_raw_float = pcall(function()
                        cvar[name]:set_raw_float(number_value)
                    end)

                    if ok_raw_float then
                        return
                    end
                end

                local ok_float = pcall(function()
                    cvar[name]:set_float(number_value)
                end)

                if ok_float then
                    return
                end

                local ok_int = pcall(function()
                    cvar[name]:set_int(VM.round(number_value))
                end)

                if ok_int then
                    return
                end
            end

            local ok_string = pcall(function()
                cvar[name]:set_string(value)
            end)

            if ok_string then
                return
            end
        end

        if client and client.set_cvar then
            pcall(client.set_cvar, name, value)
        end
    end

    function VM.to_slider(value, scale, min, max)
        return VM.clamp(VM.round((tonumber(value) or 0) / scale), min, max)
    end

    function VM.from_slider(ref, scale)
        return (tonumber(ui.get(ref)) or 0) * scale
    end

    function VM.safe_set(ref, value, fallback)
        local number_value = tonumber(value)
        if number_value == nil then
            number_value = fallback or 0
        end

        pcall(ui.set, ref, number_value)
    end

    function VM.safe_get(ref, fallback)
        local value = tonumber(ui.get(ref))
        if value == nil then
            return fallback or 0
        end

        return value
    end

    function VM.log(text, r, g, b)
        if client and client.color_log then
            client.color_log(r or 155, g or 180, b or 255, "[viewmodel] " .. tostring(text))
        end
    end

    function VM.collect()
        return {
            enable = ui.get(VM.refs.enable) == true,
            fov = VM.safe_get(VM.refs.fov, 68),
            x = VM.safe_get(VM.refs.x, 0),
            y = VM.safe_get(VM.refs.y, 0),
            z = VM.safe_get(VM.refs.z, 0),
            right_hand = ui.get(VM.refs.right_hand) == true,
            custom_bob = ui.get(VM.refs.custom_bob) == true,
            bob_lower = VM.safe_get(VM.refs.bob_lower, 21),
            bob_lat = VM.safe_get(VM.refs.bob_lat, 40),
            bob_vert = VM.safe_get(VM.refs.bob_vert, 25)
        }
    end

    function VM.has_config_state(cfg)
        return type(cfg) == "table" and cfg.view_model_enable ~= nil
    end

    function VM.state_from_config(cfg)
        if not VM.has_config_state(cfg) then
            return nil
        end

        return {
            enable = cfg.view_model_enable == true,
            fov = cfg.view_model_fov,
            x = cfg.view_model_x,
            y = cfg.view_model_y,
            z = cfg.view_model_z,
            right_hand = cfg.view_model_right_hand ~= false,
            custom_bob = cfg.view_model_custom_bob == true,
            bob_lower = cfg.view_model_bob_lower,
            bob_lat = cfg.view_model_bob_lat,
            bob_vert = cfg.view_model_bob_vert
        }
    end

    function VM.save()
        if VM.loading or VM.config_loading or database == nil or database.write == nil then
            return
        end

        pcall(database.write, VM.db_key, VM.collect())
    end

    function VM.queue_save()
        if VM.loading or VM.config_loading then
            return
        end

        VM.save_token = VM.save_token + 1
        local token = VM.save_token

        if client and client.delay_call then
            pcall(client.delay_call, 0.45, function()
                if token == VM.save_token and not VM.loading and not VM.config_loading then
                    VM.save()
                end
            end)
        else
            VM.save()
        end
    end

    function VM.read_saved()
        if database == nil or database.read == nil then
            return nil
        end

        local ok, saved = pcall(database.read, VM.db_key)
        if not ok or type(saved) ~= "table" then
            return nil
        end

        return saved
    end

    function VM.apply_state(saved)
        if type(saved) ~= "table" then
            return
        end

        VM.loading = true
        pcall(ui.set, VM.refs.enable, saved.enable == true)
        VM.safe_set(VM.refs.fov, saved.fov, 68)
        VM.safe_set(VM.refs.x, saved.x, 0)
        VM.safe_set(VM.refs.y, saved.y, 0)
        VM.safe_set(VM.refs.z, saved.z, 0)
        pcall(ui.set, VM.refs.right_hand, saved.right_hand ~= false)
        pcall(ui.set, VM.refs.custom_bob, saved.custom_bob == true)
        VM.safe_set(VM.refs.bob_lower, saved.bob_lower, 21)
        VM.safe_set(VM.refs.bob_lat, saved.bob_lat, 40)
        VM.safe_set(VM.refs.bob_vert, saved.bob_vert, 25)
        VM.loading = false
    end

    function VM.load_saved()
        VM.apply_state(VM.read_saved())
    end

    function VM.apply_config_state(cfg)
        local state = VM.state_from_config(cfg)

        if state == nil then
            return false
        end

        VM.begin_config_apply()
        VM.apply_state(state)
        VM.finish_config_apply(false)
        VM.force_apply_until = (globals and globals.realtime and globals.realtime() or 0) + 2.25

        if client and client.delay_call then
            pcall(client.delay_call, 0.05, function() VM.finish_config_apply(false) end)
            pcall(client.delay_call, 0.20, function() VM.finish_config_apply(false) end)
            pcall(client.delay_call, 0.50, function() VM.finish_config_apply(false) end)
        end

        return true
    end

    VM.original.viewmodel_presetpos = VM.read_cvar("viewmodel_presetpos", 1)
    VM.original.viewmodel_fov = VM.read_cvar("viewmodel_fov", 68)
    VM.original.viewmodel_offset_x = VM.read_cvar("viewmodel_offset_x", 0)
    VM.original.viewmodel_offset_y = VM.read_cvar("viewmodel_offset_y", 0)
    VM.original.viewmodel_offset_z = VM.read_cvar("viewmodel_offset_z", 0)
    VM.original.cl_righthand = VM.read_cvar("cl_righthand", 1)
    VM.original.cl_bob_lower_amt = VM.read_cvar("cl_bob_lower_amt", 21)
    VM.original.cl_bobamt_lat = VM.read_cvar("cl_bobamt_lat", 0.4)
    VM.original.cl_bobamt_vert = VM.read_cvar("cl_bobamt_vert", 0.25)

    VM.refs.enable = ui.new_checkbox(VM.tab, VM.group, "View Model")

    VM.refs.fov = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model FOV",
        1,
        179,
        VM.clamp(VM.round(VM.original.viewmodel_fov), 1, 179),
        true,
        "°"
    )

    VM.refs.x = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model X",
        -1500,
        1500,
        VM.to_slider(VM.original.viewmodel_offset_x, 0.01, -1500, 1500),
        true,
        "",
        0.01
    )

    VM.refs.y = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model Y",
        -1500,
        1500,
        VM.to_slider(VM.original.viewmodel_offset_y, 0.01, -1500, 1500),
        true,
        "",
        0.01
    )

    VM.refs.z = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model Z",
        -1500,
        1500,
        VM.to_slider(VM.original.viewmodel_offset_z, 0.01, -1500, 1500),
        true,
        "",
        0.01
    )

    VM.refs.right_hand = ui.new_checkbox(VM.tab, VM.group, "View Model Right Hand")
    ui.set(VM.refs.right_hand, VM.original.cl_righthand ~= 0)

    VM.refs.custom_bob = ui.new_checkbox(VM.tab, VM.group, "View Model Bob")

    VM.refs.bob_lower = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model Bob Lower",
        5,
        30,
        VM.clamp(VM.round(VM.original.cl_bob_lower_amt), 5, 30),
        true
    )

    VM.refs.bob_lat = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model Bob Lat",
        10,
        200,
        VM.to_slider(VM.original.cl_bobamt_lat, 0.01, 10, 200),
        true,
        "",
        0.01
    )

    VM.refs.bob_vert = ui.new_slider(
        VM.tab,
        VM.group,
        "View Model Bob Vert",
        10,
        200,
        VM.to_slider(VM.original.cl_bobamt_vert, 0.01, 10, 200),
        true,
        "",
        0.01
    )

    function VM.restore_bob()
        VM.write_cvar("cl_bob_lower_amt", VM.original.cl_bob_lower_amt)
        VM.write_cvar("cl_bobamt_lat", VM.original.cl_bobamt_lat)
        VM.write_cvar("cl_bobamt_vert", VM.original.cl_bobamt_vert)

        VM.was_bob_enabled = false
    end

    function VM.restore_original()
        VM.write_cvar("viewmodel_presetpos", VM.original.viewmodel_presetpos)
        VM.write_cvar("viewmodel_fov", VM.original.viewmodel_fov)
        VM.write_cvar("viewmodel_offset_x", VM.original.viewmodel_offset_x)
        VM.write_cvar("viewmodel_offset_y", VM.original.viewmodel_offset_y)
        VM.write_cvar("viewmodel_offset_z", VM.original.viewmodel_offset_z)
        VM.write_cvar("cl_righthand", VM.original.cl_righthand)

        VM.restore_bob()

        VM.was_enabled = false
    end

    function VM.reset_ui()
        VM.safe_set(VM.refs.fov, VM.clamp(VM.round(VM.original.viewmodel_fov), 1, 179), 68)
        VM.safe_set(VM.refs.x, VM.to_slider(VM.original.viewmodel_offset_x, 0.01, -1500, 1500), 0)
        VM.safe_set(VM.refs.y, VM.to_slider(VM.original.viewmodel_offset_y, 0.01, -1500, 1500), 0)
        VM.safe_set(VM.refs.z, VM.to_slider(VM.original.viewmodel_offset_z, 0.01, -1500, 1500), 0)
        ui.set(VM.refs.right_hand, VM.original.cl_righthand ~= 0)
        ui.set(VM.refs.custom_bob, false)
        VM.safe_set(VM.refs.bob_lower, VM.clamp(VM.round(VM.original.cl_bob_lower_amt), 5, 30), 21)
        VM.safe_set(VM.refs.bob_lat, VM.to_slider(VM.original.cl_bobamt_lat, 0.01, 10, 200), 40)
        VM.safe_set(VM.refs.bob_vert, VM.to_slider(VM.original.cl_bobamt_vert, 0.01, 10, 200), 25)
    end

    function VM.apply()
        if not ui.get(VM.refs.enable) then
            if VM.config_loading then
                return
            end

            if VM.was_enabled then
                VM.restore_original()
            end

            return
        end

        VM.was_enabled = true

        VM.write_cvar("viewmodel_presetpos", 0)
        VM.write_cvar("viewmodel_fov", VM.clamp(VM.safe_get(VM.refs.fov, 68), 1, 179))
        VM.write_cvar("viewmodel_offset_x", VM.from_slider(VM.refs.x, 0.01))
        VM.write_cvar("viewmodel_offset_y", VM.from_slider(VM.refs.y, 0.01))
        VM.write_cvar("viewmodel_offset_z", VM.from_slider(VM.refs.z, 0.01))
        VM.write_cvar("cl_righthand", ui.get(VM.refs.right_hand) and 1 or 0)

        if ui.get(VM.refs.custom_bob) then
            VM.was_bob_enabled = true

            VM.write_cvar("cl_bob_lower_amt", VM.clamp(VM.safe_get(VM.refs.bob_lower, 21), 5, 30))
            VM.write_cvar("cl_bobamt_lat", VM.from_slider(VM.refs.bob_lat, 0.01))
            VM.write_cvar("cl_bobamt_vert", VM.from_slider(VM.refs.bob_vert, 0.01))
        elseif VM.was_bob_enabled then
            VM.restore_bob()
        end
    end

    function VM.apply_now()
        VM.visibility()
        VM.apply()
    end

    function VM.apply_saved_fallback()
        local saved = VM.read_saved()

        if type(saved) == "table" and saved.enable == true and not ui.get(VM.refs.enable) then
            VM.apply_state(saved)
        end
    end

    function VM.finish_config_apply(use_saved_fallback)
        VM.config_loading = false

        if use_saved_fallback then
            VM.apply_saved_fallback()
        end

        VM.apply_now()
    end

    function VM.begin_config_apply()
        VM.config_loading = true
        VM.force_apply_until = (globals and globals.realtime and globals.realtime() or 0) + 2.25
    end

    function VM.delayed_apply(use_saved_fallback)
        VM.begin_config_apply()

        if client and client.delay_call then
            pcall(client.delay_call, 0.05, function() VM.finish_config_apply(false) end)
            pcall(client.delay_call, 0.15, function() VM.finish_config_apply(false) end)
            pcall(client.delay_call, 0.35, function() VM.finish_config_apply(false) end)
            pcall(client.delay_call, 0.75, function() VM.finish_config_apply(use_saved_fallback == true) end)
            pcall(client.delay_call, 1.25, function() VM.finish_config_apply(use_saved_fallback == true) end)
            pcall(client.delay_call, 2.00, function() VM.finish_config_apply(use_saved_fallback == true) end)
        else
            VM.finish_config_apply(use_saved_fallback == true)
        end
    end

    function VM.is_visual_tab()
        return cur_tab == nil or cur_tab == 3
    end

    function VM.visibility()
        local tab_visible = VM.is_visual_tab()
        local enabled = tab_visible and ui.get(VM.refs.enable)
        local bob_enabled = enabled and ui.get(VM.refs.custom_bob)

        ui.set_visible(VM.refs.enable, tab_visible)

        ui.set_visible(VM.refs.fov, enabled)
        ui.set_visible(VM.refs.x, enabled)
        ui.set_visible(VM.refs.y, enabled)
        ui.set_visible(VM.refs.z, enabled)
        ui.set_visible(VM.refs.right_hand, enabled)
        ui.set_visible(VM.refs.custom_bob, enabled)

        ui.set_visible(VM.refs.bob_lower, bob_enabled)
        ui.set_visible(VM.refs.bob_lat, bob_enabled)
        ui.set_visible(VM.refs.bob_vert, bob_enabled)

        if VM.refs.reset then
            ui.set_visible(VM.refs.reset, tab_visible)
        end
    end

    VM.refs.reset = ui.new_button(VM.tab, VM.group, "\aFFD166FFReset View Model", function()
        ui.set(VM.refs.enable, false)
        VM.reset_ui()
        VM.restore_original()
        VM.visibility()
        VM.log("reset", 255, 180, 120)
    end)

    function VM.on_change()
        VM.visibility()

        if VM.loading or VM.config_loading then
            return
        end

        VM.apply()
        VM.queue_save()
    end

    ui.set_callback(VM.refs.enable, VM.on_change)
    ui.set_callback(VM.refs.fov, VM.on_change)
    ui.set_callback(VM.refs.x, VM.on_change)
    ui.set_callback(VM.refs.y, VM.on_change)
    ui.set_callback(VM.refs.z, VM.on_change)
    ui.set_callback(VM.refs.right_hand, VM.on_change)
    ui.set_callback(VM.refs.custom_bob, VM.on_change)
    ui.set_callback(VM.refs.bob_lower, VM.on_change)
    ui.set_callback(VM.refs.bob_lat, VM.on_change)
    ui.set_callback(VM.refs.bob_vert, VM.on_change)

    client.set_event_callback("pre_render", function()
        if VM.force_apply_until > 0 and globals.realtime() <= VM.force_apply_until then
            VM.apply_now()
        elseif ui.get(VM.refs.enable) or VM.was_enabled then
            VM.apply_now()
        else
            VM.visibility()
        end
    end)

    pcall(client.set_event_callback, "post_config_load", function()
        VM.delayed_apply(true)
    end)

    client.set_event_callback("shutdown", function()
        VM.restore_original()
    end)

    VM.load_saved()
    VM.delayed_apply(false)
    view_model_config_refs = VM.refs
    view_model_begin_config_apply = VM.begin_config_apply
    view_model_has_config_state = VM.has_config_state
    view_model_on_config_applied = function(cfg)
        if not VM.apply_config_state(cfg) then
            VM.delayed_apply(true)
        end
    end
end)()
---@end

---@accent color logs
local function set_accent()
    if not ui.get(hit_logs) then
        accent.r = 113
        accent.g = 104
        accent.b = 230
        return
    end

    accent.r, accent.g, accent.b = unpack({ui.get(hit_logs_color)})
end
---@end

---@manual

local yaw_direction = 0
local last_press_t_dir = 0

local yawDirectionMapping = {
    { keyFunc = function() return ui.get(manual_l) end, value = -90 },
    { keyFunc = function() return ui.get(manual_r) end, value = 90 },
    { keyFunc = function() return ui.get(manual_f) end, value = -180 },
    { keyFunc = function() return ui.get(manual_res) end, value = 0 },
}

local function manual_yaw(cmd)
    if ui.is_menu_open() then
        return
    end

    local curtime = globals.curtime()
    
    for _, mapping in ipairs(yawDirectionMapping) do
        if mapping.keyFunc() and (last_press_t_dir + 0.13 < curtime) then
            yaw_direction = (yaw_direction == mapping.value) and 0 or mapping.value
            last_press_t_dir = curtime
            break
        end
    end

    if last_press_t_dir > curtime then
        last_press_t_dir = curtime
    end

    if yaw_direction ~= 0 then
        ui.set(ref.yaw_base, "Local view")
        ui.set(ref.yaw[1], "180")
        ui.set(ref.yaw[2], clamp(yaw_direction, -180, 180))
    end
end

welcome_intro = welcome_intro or {
    start = globals.realtime(),
    duration = 4.2
}

function render_welcome_intro()
    local now = globals.realtime()
    local elapsed = now - welcome_intro.start

    if elapsed > welcome_intro.duration then
        return
    end

    local sw, sh = client.screen_size()
    local fade_in = clamp(elapsed / 0.45, 0, 1)
    local fade_out = clamp((welcome_intro.duration - elapsed) / 1.15, 0, 1)
    local alpha = math.floor(255 * math.min(fade_in, fade_out))

    if alpha <= 0 then
        return
    end

    local title = "Welcome, " .. tostring(username or "player")
    local subtitle = elapsed < 2.1 and "Panchan beta loaded" or "Have a good game"
    local offset = math.floor((1 - math.min(fade_in, 1)) * 18)

    renderer.rectangle(0, 0, sw, sh, 16, 16, 16, math.floor(alpha * 0.82))
    renderer.text(sw / 2, sh / 2 - 16 + offset, 184, 184, 184, alpha, "cb", 0, title)
    renderer.text(sw / 2, sh / 2 + 8 + offset, 184, 184, 184, math.floor(alpha * 0.9), "c", 0, subtitle)
end

---@end

---@aa functions
is_on_ground = false

function get_player_state(cmd)
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then
        return "Unknown"
    end

    local flags = entity.get_prop(lp, 'm_fFlags')
    local velocity = sdk.get_velocity(lp)
    local in_grounded = bit.band(flags, 1) == 1
    local jump = bit.band(flags, 1) == 0 or cmd.in_jump == 1
    local ducked = entity.get_prop(lp, 'm_flDuckAmount') > 0.7
    local duck = ducked
    local is_slowwalk = ui.get(ref.slow_walk[1]) and ui.get(ref.slow_walk[2])
    is_on_ground = in_grounded
    local weapon_class = safe_get_classname(entity.get_prop(lp, "m_hActiveWeapon")) or ""
    local selected_weapons = ui.get(safehead)

    local is_allowed_weapon = 
        (weapon_class == "CKnife" and contains(selected_weapons, "Knife")) or
        (weapon_class == "CWeaponTaser" and contains(selected_weapons, "Zeus"))


    if jump and duck and is_allowed_weapon then
        return "Safe-Head"
    elseif contains(selected_weapons, "Height Advantage") and height_advantaged(client.current_threat()) then
        return "Safe-Head"
    elseif jump and duck then
        return "Air-Duck"
    elseif jump then
        return "Air"
    elseif duck and velocity > 10 then
        return "Duck-Running"
    elseif duck and velocity < 10 then
        return "Duck"
    elseif in_grounded and is_slowwalk and velocity > 10 then
        return "Slow-walk"
    elseif in_grounded and velocity > 5 then
        return "Running"
    elseif in_grounded and velocity < 5 then
        return "Stand"
    else
        return "Unknown"
    end
end

local current_state = nil

local function change_state(cmd)
    current_state = get_player_state(cmd)
end
---@end

---@centered indicators


local value = 0.0
local target = 1.0
local speed = 0.04

function smooth_exploit()
    target = player.get_dt() and 1.0 or 0.0
    value = value + (target - value) * speed
    if math.abs(value - target) < 0.01 then value = target end
    return value
end

renderer_rec = function(x, y, w, h, radius, r, g, b, a)
    radius = math.min(x/2, y/2, radius)
    
    renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
    renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
    renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
    
    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
    renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
    
    renderer.rectangle(x, y, w, 1, 0, 0, 0, 255)
    renderer.rectangle(x, y + h - 1, w, 1, 0, 0, 0, 255)
    renderer.rectangle(x, y, 1, h, 0, 0, 0, 255)
    renderer.rectangle(x + w - 1, y, 1, h, 0, 0, 0, 255)
end

local scoped_offset, scoped_offset_ind, scoped_offset_body, scoped_offset_scp, scoped_offset_dt, scoped_offset_hs = 0, 0, 0, 0, 0, 0
last_switch_time = 0

function centered_indicators_legacy()
    if not ui.get(center_indicators) then return end

    if ui.get(center_indicators_type) ~= "Legacy" then
        return
    end

    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return end

    local x, y = client.screen_size()
    local pos_x, pos_y = x / 2, y / 2
    local velocity = sdk.get_velocity(lp)
    local speed_factor = math.min(velocity / 450, 1)
    local vel_x = lerp(1, 64, speed_factor)
    local current_side = get_desync_angle() < 0 and "left" or "right"

    local state_text =
    (current_state and string.upper(current_state)) or
    "UNKNOWN"

    local scoped = sdk.isScoped(lp)
    if state_text == "AIR-DUCK" then
        scoped_offset = interp(scoped_offset, scoped and 22 or 0, 15)
    elseif state_text == "RUNNING" then
        scoped_offset = interp(scoped_offset, scoped and 21 or 0, 15)
    elseif state_text == "DUCK-RUNNING" then
        scoped_offset = interp(scoped_offset, scoped and 32 or 0, 15)
    elseif state_text == "AIR" then
        scoped_offset = interp(scoped_offset, scoped and 11 or 0, 15)
    elseif state_text == "DUCK" then
        scoped_offset = interp(scoped_offset, scoped and 15 or 0, 15)
    elseif state_text == "STAND" then
        scoped_offset = interp(scoped_offset, scoped and 17 or 0, 15)
    elseif state_text == "MANUAL LEFT" then
        scoped_offset = interp(scoped_offset, scoped and 28 or 0, 15)
    elseif state_text == "MANUAL RIGHT" then
        scoped_offset = interp(scoped_offset, scoped and 31 or 0, 15)
    else
        scoped_offset = interp(scoped_offset, scoped and 26 or 0, 15)
    end
    scoped_offset_scp = interp(scoped_offset_scp, scoped and 24 or 0, 15)
    scoped_offset_ind = interp(scoped_offset_ind, scoped and 10 or 0, 15)
    scoped_offset_hs = interp(scoped_offset_hs, scoped and 11 or 0, 15)
    scoped_offset_body = interp(scoped_offset_body, scoped and 14 or 0, 15)
    scoped_offset_dt = interp(scoped_offset_dt, scoped and 10 or 0, 15)

    local desync = get_desync_angle()
    local now = globals.curtime()

    local new_side = desync < 0 and "left" or "right"
    if new_side ~= current_side and now - last_switch_time >= 0.058 then
        current_side = new_side
        last_switch_time = now
    end

    local i_color = to_hex_a(ui.get(color))
    local left_color = current_side == "left" and "\a" .. i_color or "\aFFFFFFFF"
    local right_color = current_side == "right" and "\a" .. i_color or "\aFFFFFFFF"    
    local text = left_color .. "pan" .. right_color .. "chan"
    renderer.text(pos_x + scoped_offset_scp, pos_y + 27, 255, 255, 255, 255, "cb", nil, text)
    renderer.text(pos_x + scoped_offset, pos_y + 40, 255, 255, 255, 255, "c-", nil, state_text)

    local space = 9.33

    if ui.get(ref.dt[2]) and ui.get(ref.dt[1]) then
        renderer.text(pos_x - 1 + scoped_offset_dt, pos_y + 44 + space, 255, 255, 255, 255, "c-", nil, "DT")
        renderer.circle_outline(pos_x + 11 + scoped_offset_dt, pos_y + 44.95 + space, 255, 255, 255, 255, 3, 90, smooth_exploit(), 1)
        space = space + 10

        
    elseif ui.get(ref.hs[1]) and ui.get(ref.hs[2]) then
        renderer.text(pos_x - 1 + scoped_offset_hs, pos_y + 44 + space, 255, 255, 255, 255, "c-", nil, "HS")
        space = space + 10
    end

    if ui.get(ref.min_damage_override[1]) and ui.get(ref.min_damage_override[2]) then
        renderer.text(pos_x + scoped_offset_ind, pos_y + 44 + space, 255, 255, 255, 255, "c-", nil, "MD")
        space = space + 10
    end

    if ui.get(ref.body) then
        renderer.text(pos_x + scoped_offset_body, pos_y + 44 + space, 255, 255, 255, 255, "c-", nil, "BODY")
        space = space + 10
    end
end

local scoped_offset, scoped_offset_ind, scoped_offset_body, scoped_offset_scp, scoped_offset_dt, scoped_offset_hs, dt_offset = 0, 0, 0, 0, 0, 0, 0
local alpha_dt, alpha_hs, alpha_dmg, alpha_baim = 0, 0, 0, 0
local indicator_positions = {dt = 0, hs = 0, dmg = 0, baim = 0}

local function centered_indicators_modern()
    if not ui.get(center_indicators) then return end
    if ui.get(center_indicators_type) ~= "Modern" then return end

    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return end

    local x, y = client.screen_size()
    local pos_x, pos_y = x / 2, y / 2
    local velocity = sdk.get_velocity(lp)
    local speed_factor = math.min(velocity / 450, 1)
    local vel_x = lerp(1, 64, speed_factor)
    local current_side = get_desync_angle() < 0 and "left" or "right"

    local state_text = (current_state and string.upper(current_state)) or "UNKNOWN"
    local scoped = sdk.isScoped(lp)

    if state_text == "AIR-DUCK" then
        scoped_offset = interp(scoped_offset, scoped and 22 or 0, 15)
    elseif state_text == "RUNNING" then
        scoped_offset = interp(scoped_offset, scoped and 21 or 0, 15)
    elseif state_text == "DUCK-RUNNING" then
        scoped_offset = interp(scoped_offset, scoped and 32 or 0, 15)
    elseif state_text == "AIR" then
        scoped_offset = interp(scoped_offset, scoped and 11 or 0, 15)
    elseif state_text == "DUCK" then
        scoped_offset = interp(scoped_offset, scoped and 15 or 0, 15)
    elseif state_text == "STAND" then
        scoped_offset = interp(scoped_offset, scoped and 17 or 0, 15)
    elseif state_text == "MANUAL LEFT" then
        scoped_offset = interp(scoped_offset, scoped and 28 or 0, 15)
    elseif state_text == "MANUAL RIGHT" then
        scoped_offset = interp(scoped_offset, scoped and 31 or 0, 15)
    else
        scoped_offset = interp(scoped_offset, scoped and 26 or 0, 15)
    end

    scoped_offset_scp = interp(scoped_offset_scp, scoped and 33 or 0, 15)
    scoped_offset_ind = interp(scoped_offset_ind, scoped and 14 or 0, 15)
    scoped_offset_hs = interp(scoped_offset_hs, scoped and 10 or 0, 15)
    scoped_offset_body = interp(scoped_offset_body, scoped and 15 or 0, 15)
    scoped_offset_dt = interp(scoped_offset_dt, scoped and 11 or 0, 15)

    local color_s = {ui.get(color)}
    local r, g, b, a = unpack(color_s)
    local i_color = to_hex_a(ui.get(color))

    local text = gradient_text_lower({r,g,b}, {r/12,g/12,b/12}, "panchan.tech", 2.33)
    renderer.text(pos_x + scoped_offset_scp, pos_y + 27, 255, 255, 255, 255, "cb", nil, text)
    renderer.text(pos_x + scoped_offset, pos_y + 40, 255, 255, 255, 255, "c-", nil, "\a"..i_color..state_text)

    local base_space = 9.33
    local target_alpha = 255
    local fade_speed = 10
    local move_speed = 8
    
    dt_offset = interp(dt_offset, (smooth_exploit() > 0.5) and -2 or 2, 15)
    if scoped then dt_offset = 0 end

    local current_position = 42 + base_space
    local active_indicators = {}

    if ui.get(ref.dt[2]) and ui.get(ref.dt[1]) then
        active_indicators.dt = current_position
        current_position = current_position + 11
    end
    
    if ui.get(ref.hs[1]) and ui.get(ref.hs[2]) and not ui.get(ref.dt[2]) then
        active_indicators.hs = current_position
        current_position = current_position + 11
    end
    
    if ui.get(ref.min_damage_override[1]) and ui.get(ref.min_damage_override[2]) then
        active_indicators.dmg = current_position
        current_position = current_position + 11
    end
    
    if ui.get(ref.body) then
        active_indicators.baim = current_position
    end

    for indicator, target_pos in pairs(active_indicators) do
        indicator_positions[indicator] = interp(indicator_positions[indicator] or 35, target_pos, move_speed)
    end

    for indicator, _ in pairs(indicator_positions) do
        if not active_indicators[indicator] then
            indicator_positions[indicator] = interp(indicator_positions[indicator], 35, move_speed)
        end
    end

    alpha_dt = interp(alpha_dt, ui.get(ref.dt[2]) and ui.get(ref.dt[1]) and target_alpha or 0, fade_speed)
    alpha_hs = interp(alpha_hs, ui.get(ref.hs[1]) and ui.get(ref.hs[2]) and not ui.get(ref.dt[2]) and target_alpha or 0, fade_speed)
    alpha_dmg = interp(alpha_dmg, ui.get(ref.min_damage_override[1]) and ui.get(ref.min_damage_override[2]) and target_alpha or 0, fade_speed)
    alpha_baim = interp(alpha_baim, ui.get(ref.body) and target_alpha or 0, fade_speed)

    if alpha_dt > 0 and ui.get(ref.dt[2]) then
        local dt_color = smooth_exploit() > 0.5 and "\a"..i_color or "\aec5353FF"
        renderer.text(pos_x + dt_offset - 1 + scoped_offset_dt, pos_y + indicator_positions.dt, 255, 255, 255, alpha_dt, "c-", nil, dt_color.."DT")
        renderer.circle_outline(pos_x + dt_offset + 11 + scoped_offset_dt, pos_y + indicator_positions.dt + 0.95, r, g, b, alpha_dt, 3, 90, smooth_exploit(), 1)
    end

    if alpha_hs > 0 then
        renderer.text(pos_x + scoped_offset_hs, pos_y + indicator_positions.hs, r, g, b, alpha_hs, "c-", nil, "HS")
    end

    if alpha_dmg > 0 then
        renderer.text(pos_x + scoped_offset_ind, pos_y + indicator_positions.dmg, r, g, b, alpha_dmg, "c-", nil, "DMG")
    end

    if alpha_baim > 0 then
        renderer.text(pos_x + scoped_offset_body, pos_y + indicator_positions.baim, r, g, b, alpha_baim, "c-", nil, "BAIM")
    end
end

---@end

---@anti-aims

--local function do_desync(cmd, target_desync, mode, jitter_delay, real_yaw)
--
--    -- from supremacy :3
--    if entity.get_prop(lp, "m_MoveType") == 8 then return end
--
--    if not target_desync or not mode then
--        cmd.allow_send_packet = true
--        return
--    end
--
--    local choked = globals.chokedcommands()
--
--    if choked > 0 then
--        cmd.allow_send_packet = true
--        return
--    end
--
--    if mode == 1 then
--        cmd.allow_send_packet = false
--        ui.set(ref.yaw[2], delayjitter(-target_desync + real_yaw, target_desync - real_yaw, jitter_delay, math.random(0, 1) == 1))
--
--    elseif mode == 2 then
--        cmd.allow_send_packet = false
--        ui.set(ref.yaw[2], clamp(target_desync + real_yaw, -180, 180))
--
--    elseif mode == 3 then
--        cmd.allow_send_packet = false
--        local left = -target_desync + real_yaw
--        local right = target_desync - real_yaw
--        ui.set(ref.yaw[2], delayjitter(left, right, jitter_delay, math.random(0, 1) == 1))
--    end
--end


---@defensive check

last_commandnumber = 0

static = {
    tickbase_max = 0, 
    diff = 0,         
    defensive = false,
}

function update_defensive(cmd)
	local lp = entity.get_local_player()
	local valid_entity = lp and entity.is_alive(lp)

	if not valid_entity then return end

    local can_exploit = (((ui.get(ref.dt[2]) or ui.get(ref.hs[2])) and not ui.get(ref.fd)) and player.get_dt())

    if not can_exploit then static.defensive = false end

	local tickbase = entity.get_prop(lp, "m_nTickBase") or 0

	if last_commandnumber == cmd.command_number then
		static.diff = tickbase - static.tickbase_max
		static.defensive = static.diff < -3

		if math.abs(static.diff) > 64 then
			static.tickbase_max = 0
		end

		static.tickbase_max = math.max(tickbase, static.tickbase_max or 0)
	end

	return static.defensive
end

function on_finish_command(cmd)
    local lp = entity.get_local_player()
	local valid_entity = lp and entity.is_alive(lp)

	if valid_entity then
        last_commandnumber = cmd.command_number
    end
end

---@end

---@custom sway
local sway_state = {
    current_value = 0,
    increasing = true
}

function custom_sway(from, to)
    if sway_state.increasing then
        sway_state.current_value = sway_state.current_value + 3.33
        if sway_state.current_value >= to then
            sway_state.current_value = to
            sway_state.increasing = false
        end
    else
        sway_state.current_value = sway_state.current_value - 3.33
        if sway_state.current_value <= from then
            sway_state.current_value = from
            sway_state.increasing = true
        end
    end

    return sway_state.current_value
end
---@end

---@sway yaw
local sway_state_2 = {
    current_value = 0,
    increasing = true
}

function custom_sway_2(from, to)
    if sway_state_2.increasing then
        sway_state_2.current_value = sway_state_2.current_value + 3.33
        if sway_state_2.current_value >= to then
            sway_state_2.current_value = to
            sway_state_2.increasing = false
        end
    else
        sway_state_2.current_value = sway_state_2.current_value - 3.33
        if sway_state_2.current_value <= from then
            sway_state_2.current_value = from
            sway_state_2.increasing = true
        end
    end

    return sway_state_2.current_value
end
---@end

local function normalize_yaw(yaw)
    yaw = (yaw + 180) % 360
    if yaw < 0 then
        yaw = yaw + 360
    end
    return yaw - 180
end

local function random_between(a, b)
    a = math.floor(tonumber(a) or 0)
    b = math.floor(tonumber(b) or 0)

    if a > b then
        a, b = b, a
    end

    return math.random(a, b)
end

spin_range_random_cache = spin_range_random_cache or {}

function get_yaw_spin_range(settings, key)
    local base_range = settings.yaw_jitter_spin_range and ui.get(settings.yaw_jitter_spin_range) or 360

    if not settings.yaw_jitter_spin_range_randomize or not ui.get(settings.yaw_jitter_spin_range_randomize) then
        return base_range
    end

    local from = settings.yaw_jitter_spin_range_from and ui.get(settings.yaw_jitter_spin_range_from) or 1
    local to = settings.yaw_jitter_spin_range_to and ui.get(settings.yaw_jitter_spin_range_to) or base_range
    local cache_key = key or "Global"
    local cache = spin_range_random_cache[cache_key] or { value = base_range, next_tick = 0 }
    local tick = globals.tickcount()

    if tick >= cache.next_tick then
        cache.value = random_between(from, to)
        cache.next_tick = tick + 4
        spin_range_random_cache[cache_key] = cache
    end

    return cache.value
end

function get_defensive_snap_yaw(settings, switch_state, cmd)
    local mode = settings.defensive_yaw_snap_mode and ui.get(settings.defensive_yaw_snap_mode) or "Offset Snap Jitter"
    local first = ui.get(settings.defensive_yaw_static)
    local second = ui.get(settings.defensive_yaw_2)
    local yaw = switch_state and first or second

    if mode == "Center Snap Jitter" then
        local center = first
        local range = math.abs(second)
        yaw = switch_state and (center + range) or (center - range)
    elseif mode == "Skitter Snap Jitter" then
        local min_yaw = math.min(first, second)
        local max_yaw = math.max(first, second)
        local range = math.max(1, max_yaw - min_yaw)
        local phase = cmd and cmd.command_number % 4 or globals.tickcount() % 4

        if phase == 0 then
            yaw = min_yaw
        elseif phase == 1 then
            yaw = min_yaw + math.floor(range * 0.35)
        elseif phase == 2 then
            yaw = max_yaw
        else
            yaw = max_yaw - math.floor(range * 0.35)
        end

        yaw = yaw + random_between(-4, 4)
    elseif mode == "Random Snap Jitter" then
        yaw = random_between(first, second)
    end

    return clamp(normalize_yaw(yaw), -180, 180)
end

safe_get_classname = function(entindex)
    if entindex == nil or entindex <= 0 then
        return nil
    end

    local ok, classname = pcall(entity.get_classname, entindex)
    return ok and classname or nil
end

local function spin_between(a, b, speed)
    local range = b - a
    local time = globals.curtime() * speed
    local t = (time % 1)
    return a + range * t
end

---@end

function delayjitter(val1, val2, yawrandom, switch_state)
    if not sdk.is_alive(sdk.get_lp()) or not sdk.get_lp() then
        return
    end

        local random_left  = random_between(0, math.abs(val1) * yawrandom / 100)
        local random_right = random_between(0, math.abs(val2) * yawrandom / 100)
        local yaw = switch_state and (val1 + random_left) or (val2 - random_right)
        return clamp(yaw, -180, 180)
end

anti_brute = anti_brute or {
    active_until = 0,
    started_at = 0,
    last_print = -10,
    current_offset = 0,
    delay_shift = 0,
    phase_advance = 0,
    yaw_flip = false,
    body_flip = false,
    generation = 0,
    stage = 0,
    target = nil,
    condition = "Unknown",
    enemies = {}
}
anti_brute.enemies = anti_brute.enemies or {}
anti_brute.generation = anti_brute.generation or 0
anti_brute.started_at = anti_brute.started_at or 0
anti_brute.condition = anti_brute.condition or "Unknown"

anti_brute_patterns = anti_brute_patterns or {
    {offset = 7,  duration = 0.58, delay = -1, phase = 1, yaw_flip = true,  body_flip = true},
    {offset = 11, duration = 0.72, delay = 1,  phase = 2, yaw_flip = false, body_flip = true},
    {offset = 14, duration = 0.86, delay = -2, phase = 3, yaw_flip = true,  body_flip = true},
    {offset = 9,  duration = 0.64, delay = 2,  phase = 2, yaw_flip = true,  body_flip = false},
    {offset = 13, duration = 0.78, delay = -1, phase = 3, yaw_flip = false, body_flip = true},
    {offset = 6,  duration = 0.54, delay = 1,  phase = 1, yaw_flip = true,  body_flip = true}
}

aa_adaptive = {
    danger_until = 0,
    last_time = 0,
    side = 1,
    level = 0,
    enemy = 0
}

adaptive_desync_cache = {
    next_tick = 0,
    angle = 0,
    noise = 0
}

function adaptive_aa_power()
    return 0
end

function register_adaptive_threat(enemy, severity)
    return
end

function anti_brute_reset(clear_memory)
    anti_brute.active_until = 0
    anti_brute.started_at = 0
    anti_brute.current_offset = 0
    anti_brute.delay_shift = 0
    anti_brute.phase_advance = 0
    anti_brute.yaw_flip = false
    anti_brute.body_flip = false
    anti_brute.stage = 0
    anti_brute.target = nil
    anti_brute.distance = nil
    if clear_memory then
        anti_brute.enemies = {}
    end
end

function anti_brute_is_suspended(cmd)
    if cmd ~= nil and (cmd.in_attack == 1 or cmd.in_attack == true or cmd.in_attack2 == 1 or cmd.in_attack2 == true or cmd.in_use == 1 or cmd.in_use == true) then
        return true
    end
    return ref ~= nil and ref.fd ~= nil and ui.get(ref.fd)
end

function anti_brute_active(cmd)
    if not ui.get(anti_bruteforce) then
        if anti_brute.current_offset ~= 0 then
            anti_brute_reset(false)
        end
        return false
    end

    if globals.realtime() > (anti_brute.active_until or 0) then
        if anti_brute.current_offset ~= 0 then
            anti_brute_reset(false)
        end
        return false
    end

    return not anti_brute_is_suspended(cmd)
end

function anti_brute_duck_offset_cap()
    if anti_brute.condition == "Duck" then
        return 3
    elseif anti_brute.condition == "Duck-Running" then
        return 4
    end
    return nil
end

function anti_brute_duck_blend()
    local cap = anti_brute_duck_offset_cap()
    if cap == nil then
        return 1
    end

    local now = globals.realtime()
    local elapsed = math.max(now - (anti_brute.started_at or now), 0)
    local remaining = math.max((anti_brute.active_until or now) - now, 0)
    local attack = anti_brute.condition == "Duck" and 0.12 or 0.09
    local release = anti_brute.condition == "Duck" and 0.22 or 0.18
    return math.min(clamp(elapsed / attack, 0, 1), clamp(remaining / release, 0, 1))
end

function anti_brute_effective_offset(cmd)
    if not anti_brute_active(cmd) then
        return 0
    end

    local value = anti_brute.current_offset or 0
    local cap = anti_brute_duck_offset_cap()
    if cap ~= nil then
        value = clamp(value, -cap, cap) * anti_brute_duck_blend()
    end

    return value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
end

function anti_brute_closest_distance(ax, ay, az, bx, by, bz, px, py, pz)
    local abx, aby, abz = bx - ax, by - ay, bz - az
    local apx, apy, apz = px - ax, py - ay, pz - az
    local length_sqr = abx * abx + aby * aby + abz * abz
    local t = 0

    if length_sqr > 0.0001 then
        t = clamp((apx * abx + apy * aby + apz * abz) / length_sqr, 0, 1)
    end

    local cx, cy, cz = ax + abx * t, ay + aby * t, az + abz * t
    local dx, dy, dz = px - cx, py - cy, pz - cz
    return math.sqrt(dx * dx + dy * dy + dz * dz), t
end

function anti_brute_effective_state(state, cmd)
    if anti_brute_active(cmd) and anti_brute.yaw_flip and anti_brute_duck_offset_cap() == nil then
        return not state
    end
    return state
end

function anti_brute_adjust_delay(value, cmd)
    value = tonumber(value) or 1
    if anti_brute_active(cmd) then
        local shift = anti_brute.delay_shift or 0
        if anti_brute_duck_offset_cap() ~= nil then
            shift = clamp(shift, -1, 1)
        end
        value = value + shift
    end
    return clamp(math.floor(value), 1, 22)
end

function anti_brute_adjust_body(value, cmd)
    value = tonumber(value) or 0
    if not anti_brute_active(cmd) or not anti_brute.body_flip or math.abs(value) <= 0.5 then
        return value
    end

    local duck_cap = anti_brute_duck_offset_cap()
    if duck_cap ~= nil then
        local nudge = (anti_brute.condition == "Duck" and 2 or 3) * anti_brute_duck_blend()
        local magnitude = math.floor(clamp(math.abs(value) - nudge, 1, 60) + 0.5)
        return value > 0 and magnitude or -magnitude
    end

    local magnitude = clamp(math.abs(value) + ((anti_brute.severity or 0) >= 80 and 1 or 0), 1, 60)
    return value > 0 and -magnitude or magnitude
end

function anti_brute_sync_delayed_runtime(runtime, cmd)
    if runtime == nil or not anti_brute_active(cmd) or runtime.anti_brute_generation == anti_brute.generation then
        return
    end

    runtime.anti_brute_generation = anti_brute.generation
    local advance = math.max(anti_brute.phase_advance or 1, 1)
    if anti_brute_duck_offset_cap() ~= nil then
        local shift = clamp(anti_brute.delay_shift or 0, -1, 1)
        runtime.phase_target = clamp((runtime.phase_target or 2) + shift, 1, 22)
        runtime.modifier_step = (runtime.modifier_step or 0) + 1
        runtime.bobro_step = (runtime.bobro_step or 1) % 6 + 1
        return
    end

    if advance % 2 == 1 then
        runtime.previous_phase = runtime.phase
        runtime.phase = not runtime.phase
    end
    if advance >= 2 then
        runtime.body_phase = not runtime.body_phase
    end

    runtime.phase_ticks = math.max(runtime.phase_ticks or 0, math.max((runtime.phase_target or 2) - 1, 0))
    runtime.body_ticks = math.max(runtime.body_ticks or 0, math.max((runtime.body_target or 2) - 1, 0))
    runtime.phase_target = clamp((runtime.phase_target or 2) + (anti_brute.delay_shift or 0), 1, 22)
    runtime.body_target = clamp((runtime.body_target or 2) - (anti_brute.delay_shift or 0), 1, 22)
    runtime.modifier_step = (runtime.modifier_step or 0) + advance
    runtime.bobro_step = ((runtime.bobro_step or 1) + advance - 1) % 6 + 1
end

function anti_brute_sync_panchan_v2(runtime, cmd)
    if runtime == nil or not anti_brute_active(cmd) or runtime.anti_brute_generation == anti_brute.generation then
        return
    end

    runtime.anti_brute_generation = anti_brute.generation
    if anti_brute_duck_offset_cap() ~= nil then
        runtime.phase_limit = clamp((runtime.phase_limit or 3) + clamp(anti_brute.delay_shift or 0, -1, 1), 1, 6)
        runtime.yaw_noise = clamp((runtime.yaw_noise or 0) + anti_brute_effective_offset(cmd) * 0.25, -4, 4)
        return
    end

    runtime.phase_ticks = math.max(runtime.phase_ticks or 0, math.max((runtime.phase_limit or 3) - 1, 0))
    runtime.phase_limit = clamp((runtime.phase_limit or 3) + (anti_brute.delay_shift or 0), 1, 6)
    runtime.packet_flip = not (runtime.packet_flip or false)
    runtime.yaw_noise = clamp((runtime.yaw_noise or 0) + (anti_brute.current_offset or 0) * 0.35, -8, 8)
end

function anti_brute_sync_defensive_runtime(runtime, cmd)
    if runtime == nil or not anti_brute_active(cmd) or runtime.anti_brute_generation == anti_brute.generation then
        return
    end

    runtime.anti_brute_generation = anti_brute.generation
    if anti_brute_duck_offset_cap() ~= nil then
        runtime.snap_step = ((runtime.snap_step or 0) + 1) % 5
        return
    end

    runtime.next_phase_tick = 0
    runtime.snap_step = ((runtime.snap_step or 0) + math.max(anti_brute.phase_advance or 1, 1)) % 5
    runtime.reference_step_3 = ((runtime.reference_step_3 or 0) + 1) % 3
    runtime.reference_step_5 = ((runtime.reference_step_5 or 0) + 2) % 5
    runtime.reference_flip = not (runtime.reference_flip or false)
end

function anti_brute_apply_final(cmd, body_yaw_mode)
    if not anti_brute_active(cmd) then
        return
    end

    local yaw = ref ~= nil and ref.yaw ~= nil and ref.yaw[2] ~= nil and ui.get(ref.yaw[2]) or nil
    if type(yaw) == "number" then
        ui.set(ref.yaw[2], clamp(normalize_yaw(yaw + anti_brute_effective_offset(cmd)), -180, 180))
    end
end

function anti_brute_trigger(ent, distance, shot_side)
    local now = globals.realtime()
    local enemy = anti_brute.enemies[ent] or {stage = 0, last_trigger = -10, last_tick = -1, last_side = 0}
    local tick = globals.tickcount()

    if enemy.last_tick == tick or now - (enemy.last_trigger or -10) < 0.08 then
        return false
    end

    if now - (enemy.last_trigger or -10) > 7 then
        enemy.stage = 1
    else
        enemy.stage = (enemy.stage or 0) % #anti_brute_patterns + 1
    end

    local pattern = anti_brute_patterns[enemy.stage]
    local severity = distance <= 14 and 100 or distance <= 26 and 82 or 62
    local side = shot_side == 0 and ((enemy.stage % 2 == 0) and -1 or 1) or -shot_side
    if enemy.last_side == side then
        side = -side
    end

    local scale = 0.72 + severity * 0.0028
    local offset = math.floor(pattern.offset * scale + 0.5) * side
    anti_brute.generation = (anti_brute.generation or 0) + 1
    anti_brute.started_at = now
    anti_brute.active_until = now + pattern.duration + (severity >= 95 and 0.08 or 0)
    anti_brute.current_offset = offset
    anti_brute.delay_shift = pattern.delay
    anti_brute.phase_advance = pattern.phase
    anti_brute.yaw_flip = pattern.yaw_flip
    anti_brute.body_flip = pattern.body_flip
    anti_brute.stage = enemy.stage
    anti_brute.target = ent
    anti_brute.distance = distance
    anti_brute.severity = severity

    enemy.last_trigger = now
    enemy.last_tick = tick
    enemy.last_side = side
    enemy.last_distance = distance
    anti_brute.enemies[ent] = enemy

    if now - (anti_brute.last_print or -10) > 0.65 then
        local applied_offset = offset
        local applied_delay = pattern.delay
        local duck_cap = anti_brute_duck_offset_cap()
        if duck_cap ~= nil then
            applied_offset = clamp(offset, -duck_cap, duck_cap)
            applied_delay = clamp(pattern.delay, -1, 1)
        end

        local message
        if duck_cap ~= nil then
            message = string.format(
                "anti-bruteforce | stage %d | %s | %.1fu | offset %+d -> %+d | delay %+d -> %+d",
                enemy.stage,
                anti_brute.condition,
                distance,
                offset,
                applied_offset,
                pattern.delay,
                applied_delay
            )
        else
            message = string.format(
                "anti-bruteforce | stage %d | %.1fu | offset %+d | delay %+d",
                enemy.stage,
                distance,
                applied_offset,
                applied_delay
            )
        end
        add_log(message, 3, 255, 255, 255)
        print(message)
        anti_brute.last_print = now
    end

    return true
end

client.set_event_callback("bullet_impact", function(e)
    if not ui.get(anti_bruteforce) then
        anti_brute_reset(false)
        return
    end

    local lp = entity.get_local_player()
    local ent = client.userid_to_entindex(e.userid)
    if lp == nil or ent == nil or ent <= 0 or ent == lp or not entity.is_enemy(ent) or not entity.is_alive(lp) then
        return
    end

    local sx, sy, sz = entity.get_origin(ent)
    local hx, hy, hz = entity.hitbox_position(lp, 0)
    if sx == nil or hx == nil or e.x == nil or e.y == nil or e.z == nil then
        return
    end

    local view_z = entity.get_prop(ent, "m_vecViewOffset[2]") or 64
    sz = (sz or 0) + view_z
    local distance, projection = anti_brute_closest_distance(sx, sy, sz, e.x, e.y, e.z, hx, hy, hz)
    if projection <= 0.02 or distance > 42 then
        return
    end

    local ray_x, ray_y = e.x - sx, e.y - sy
    local head_x, head_y = hx - sx, hy - sy
    local cross = ray_x * head_y - ray_y * head_x
    local shot_side = cross > 0.001 and 1 or cross < -0.001 and -1 or 0

    if anti_brute_trigger(ent, distance, shot_side) then
        local now = globals.realtime()
        local last_miss = session_stats.last_enemy_miss[ent] or 0
        if now - last_miss > 0.12 then
            session_stats.enemy_misses = (session_stats.enemy_misses or 0) + 1
            session_stats.last_enemy_miss[ent] = now
        end
        register_adaptive_threat(ent, anti_brute.severity or 62)
    end
end)

local last_switch_timer = 0
local current_state = false
local defensive_switch_time = 0
local defensive_state = false
local delay_timer = 0

defensive_rework_runtime = defensive_rework_runtime or {
    active = false,
    next_phase_tick = 0,
    delay_offset = 0,
    yaw_noise = 0,
    pitch_noise = 0,
    body_side = 1,
    body_value = 58,
    last_body_value = 0,
    last_yaw = 0,
    activation_tick = 0,
    snap_step = 0,
    reference_step_3 = 0,
    reference_step_5 = 0,
    reference_flip = false,
    reference_last_command = nil,
    threat_close = false,
    speed = 0
}

function defensive_rework_reset()
    defensive_rework_runtime.active = false
    defensive_rework_runtime.next_phase_tick = 0
    defensive_rework_runtime.delay_offset = 0
    defensive_rework_runtime.yaw_noise = 0
    defensive_rework_runtime.pitch_noise = 0
    defensive_rework_runtime.body_side = 1
    defensive_rework_runtime.body_value = 58
    defensive_rework_runtime.last_body_value = 0
    defensive_rework_runtime.last_yaw = 0
    defensive_rework_runtime.activation_tick = 0
    defensive_rework_runtime.snap_step = 0
    defensive_rework_runtime.reference_step_3 = 0
    defensive_rework_runtime.reference_step_5 = 0
    defensive_rework_runtime.reference_flip = false
    defensive_rework_runtime.reference_last_command = nil
    defensive_rework_runtime.threat_close = false
    defensive_rework_runtime.speed = 0
    defensive_rework_runtime.anti_brute_generation = -1
end

function defensive_rework_update(cmd, condition)
    local rt = defensive_rework_runtime
    local tick = globals.tickcount()
    local choked = cmd.chokedcommands or globals.chokedcommands() or 0
    local threat = client.current_threat()
    local lp = entity.get_local_player()
    local vx, vy = 0, 0

    if lp ~= nil then
        vx, vy = entity.get_prop(lp, "m_vecVelocity")
    end

    local speed = math.sqrt((vx or 0) * (vx or 0) + (vy or 0) * (vy or 0))
    local threat_close = false

    if threat ~= nil and threat > 0 and lp ~= nil then
        local lx, ly, lz = entity.get_origin(lp)
        local tx, ty, tz = entity.get_origin(threat)
        if lx ~= nil and tx ~= nil then
            threat_close = distance3d(lx, ly, lz or 0, tx, ty, tz or 0) <= 820
        end
    end

    if not rt.active then
        rt.activation_tick = tick
        rt.next_phase_tick = 0
        rt.body_side = math.random(0, 1) == 1 and 1 or -1
    end

    rt.active = true
    rt.threat_close = threat_close
    rt.speed = speed
    anti_brute_sync_defensive_runtime(rt, cmd)

    if choked == 0 and tick >= rt.next_phase_tick then
        local phase_min = threat_close and 2 or (threat ~= nil and 3 or 4)
        local phase_max = threat_close and 5 or (threat ~= nil and 7 or 10)
        local speed_noise = speed > 115 and 3 or (speed > 15 and 2 or 0)

        if math.random(1, 100) <= (threat_close and 72 or 54) then
            rt.body_side = -rt.body_side
        end

        rt.delay_offset = random_between(-1, threat_close and 2 or 1)
        rt.yaw_noise = random_between(-7 - speed_noise, 7 + speed_noise)
        rt.pitch_noise = random_between(-1, 1)
        rt.body_value = random_between(threat_close and 56 or 54, 60) * rt.body_side
        rt.snap_step = ((rt.snap_step or 0) + random_between(1, threat_close and 2 or 1)) % 5

        if math.abs(rt.body_value - (rt.last_body_value or 0)) <= 3 then
            rt.body_value = -rt.body_value
        end

        rt.last_body_value = rt.body_value
        rt.next_phase_tick = tick + random_between(phase_min, phase_max)
    end

    if choked == 0 and rt.reference_last_command ~= (cmd.command_number or tick) then
        rt.reference_last_command = cmd.command_number or tick
        rt.reference_flip = not rt.reference_flip
        rt.reference_step_3 = ((rt.reference_step_3 or 0) + 1) % 3
        rt.reference_step_5 = ((rt.reference_step_5 or 0) + 1) % 5
    end

    return rt
end

function defensive_rework_delay(base_delay, yaw_mode)
    if yaw_mode ~= "Jitter" and yaw_mode ~= "Snap Jitter" and yaw_mode ~= "Adaptive Snap" then
        return base_delay
    end

    return clamp((base_delay or 1) + (defensive_rework_runtime.delay_offset or 0), 1, 14)
end

function defensive_micro_jitter_pitch(cmd)
    local rt = defensive_rework_runtime
    local step = ((rt.snap_step or 0) + ((cmd.command_number or globals.tickcount()) % 3)) % 3
    local values = {-89, -86, -88}
    local value = values[step + 1] or -89

    if rt.threat_close then
        value = value - 1
    end

    return clamp(value + (rt.pitch_noise or 0), -89, 89)
end

function defensive_rework_pitch(value, pitch_mode)
    value = tonumber(value)

    if pitch_mode == "Off" or pitch_mode == "Spin" then
        return value
    end

    if value == nil then
        value = -89
    end

    return clamp(value + (defensive_rework_runtime.pitch_noise or 0), -89, 89)
end

function defensive_rework_yaw(value, yaw_mode, cmd)
    value = tonumber(value)

    if yaw_mode == "Off" then
        return value
    end

    if value == nil then
        value = 0
    end

    local rt = defensive_rework_runtime
    local noise = rt.yaw_noise or 0
    local yaw = value

    if yaw_mode == "Jitter" or yaw_mode == "Snap Jitter" or yaw_mode == "Adaptive Snap" then
        yaw = yaw + noise
    elseif yaw_mode == "Static" or yaw_mode == "3-Way" or yaw_mode == "Sway" then
        yaw = yaw + math.floor(noise * 0.5)
    end

    local last_delta = math.abs(normalize_yaw(yaw - (rt.last_yaw or 0)))
    if (yaw_mode == "Snap Jitter" or yaw_mode == "Jitter" or yaw_mode == "Adaptive Snap") and last_delta < 9 and (cmd.chokedcommands or 0) == 0 then
        yaw = yaw + (rt.body_side or 1) * random_between(10, 17)
    end

    yaw = clamp(normalize_yaw(yaw), -180, 180)
    rt.last_yaw = yaw

    return yaw
end

function defensive_adaptive_snap_yaw(cmd)
    local rt = defensive_rework_runtime
    local side = rt.body_side or 1
    local step = rt.snap_step or 0
    local pattern = {
        -74 * side,
        68 * side,
        -58 * side,
        53 * side,
        42 * side
    }
    local yaw = pattern[step + 1] or 0
    local noise = rt.yaw_noise or 0

    if rt.threat_close then
        yaw = yaw + (yaw > 0 and random_between(2, 8) or -random_between(2, 8))
    else
        yaw = yaw + math.floor(noise * 0.75)
    end

    if rt.speed and rt.speed > 115 then
        yaw = yaw + side * random_between(3, 8)
    end

    return defensive_rework_yaw(yaw, "Adaptive Snap", cmd)
end

function defensive_reference_yaw(mode)
    local rt = defensive_rework_runtime
    local flip = rt.reference_flip == true
    local side = rt.body_side == -1 and -1 or 1
    local yaw = 0

    if mode == "Opposite" then
        yaw = random_between(150, 210)
    elseif mode == "Opposite Jitter" then
        yaw = flip and random_between(135, 180) or random_between(180, 225)
    elseif mode == "Side-Based" then
        yaw = side == 1 and random_between(75, 105) or random_between(-105, -75)
    elseif mode == "Sideways" then
        yaw = flip and random_between(-120, -60) or random_between(60, 120)
    elseif mode == "Random" then
        yaw = random_between(-180, 180)
    elseif mode == "3-Way" then
        local pattern = {-90, 180, 90}
        yaw = pattern[(rt.reference_step_3 or 0) + 1]
    elseif mode == "5-Way" then
        local pattern = {-90, -45, 180, 45, 90}
        yaw = pattern[(rt.reference_step_5 or 0) + 1]
    end

    return clamp(normalize_yaw(yaw), -180, 180)
end

function defensive_reference_pitch(mode)
    if mode == "Down" then
        return random_between(74, 89)
    elseif mode == "Up" then
        return random_between(-89, -74)
    elseif mode == "POTATO" then
        local phase = math.abs(globals.realtime() % 0.3 - 0.15) / 0.15
        return clamp(-89 + phase * 178, -89, 89)
    elseif mode == "Semi-Up" then
        return random_between(-60, -45)
    elseif mode == "Semi-Down" then
        return random_between(45, 60)
    end

    return random_between(-89, 60)
end

function defensive_rework_body(body_yaw_mode, yaw_value, switch_state, cmd)
    local rt = defensive_rework_runtime
    local base = math.abs(yaw_value or 0)

    if base < 35 then
        base = math.abs(rt.body_value or 58)
    end

    base = clamp(base, 35, 60)

    local value
    if body_yaw_mode == "Jitter" then
        value = (switch_state and -base or base) + math.floor((rt.yaw_noise or 0) * 0.25)
    elseif body_yaw_mode == "Static" then
        value = base * (rt.body_side or 1)
    else
        value = rt.body_value or (58 * (rt.body_side or 1))
    end

    value = anti_brute_adjust_body(value, cmd)
    ui.set(ref.body_yaw[1], "Static")
    ui.set(ref.body_yaw[2], clamp(value, -60, 60))
end

function update_state(cmd, curtime, delay_mode, delay_ticks, delay_rnd_select, delay_ticks_values, chance_percent, last_time, state)
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then
        return true, curtime
    end

    local interval_per_tick = globals.tickinterval()
    if last_time == 0 or last_time == nil or curtime < last_time then
        return state, curtime
    end

    local choked = cmd.chokedcommands == 0
    local passed = curtime - last_time

    if not choked then
        return state, last_time
    end

    if delay_mode == "Off" and passed >= interval_per_tick then
        return not state, curtime

    elseif delay_mode == "Tickbased" and passed >= delay_ticks * interval_per_tick then
        return not state, curtime

    elseif delay_mode == "Chance" and passed >= interval_per_tick then
        if math.random(1, 100) <= chance_percent then
            return not state, curtime
        end

    elseif delay_mode == "Settable Random" then
        local rnd = math.random(1, math.max(1, delay_rnd_select))
        local selected_delay = delay_ticks_values[rnd] or delay_ticks_values[1] or delay_ticks

        if passed >= selected_delay * interval_per_tick then
            return not state, curtime
        end
    elseif delay_mode == "Panchan Adaptive" then
        local threat = client.current_threat()
        local adaptive_delay = clamp(delay_ticks + random_between(-1, threat ~= nil and 1 or 3), 1, 14)
        local adaptive_chance = clamp(chance_percent + (threat ~= nil and 28 or 12) + (player.get_dt() and 12 or 0), 1, 100)

        if passed >= adaptive_delay * interval_per_tick and random_between(1, 100) <= adaptive_chance then
            return not state, curtime
        end
    end

    return state, last_time
end

last_switch = 0
side = 1
threeway_value = 0

function thrreway(cmd, a, b, c)
    if cmd.chokedcommands ~= 0 then
        return threeway_value
    end

    if last_switch > globals.curtime() then
        last_switch = 0
    end

    if globals.curtime() - last_switch >= 0.001 then
        side = side % 3 + 1
        last_switch = globals.curtime()
    end

    if side == 1 then
        threeway_value = a
    elseif side == 2 then
        threeway_value = b
    elseif side == 3 then
        threeway_value = c
    end

    return threeway_value
end

spin_val = 0
dir_val = 1

function update_dist(step)
    spin_val = spin_val + step * dir_val
    if spin_val >= 180 or spin_val <= -180 then
        spin_val = math.max(-180, math.min(180, spin_val))
        dir_val = -dir_val
    end
    return spin_val
end

spin2_val = 0

function normalize_spin(val)
    val = val % 360
    if val > 180 then
        val = val - 360
    end
    return val
end

function update_spin(step)
    spin2_val = normalize_spin(spin2_val + step)
    return spin2_val
end

last_upd_t = 0
cur_value_rnd = 0

function static_random(first, second)
    first = math.floor(tonumber(first) or -89)
    second = math.floor(tonumber(second) or first)
    if first > second then
        first, second = second, first
    end

    local cur_time = globals.curtime()
    if last_upd_t > cur_time then
        last_upd_t = 0
        cur_value_rnd = clamp(cur_value_rnd ~= 0 and cur_value_rnd or first, first, second)
        return cur_value_rnd
    end
    if cur_time - last_upd_t >= 0.25 then
        cur_value_rnd = math.random(first, second)
        last_upd_t = cur_time
    end
    if cur_value_rnd == nil or cur_value_rnd < first or cur_value_rnd > second then
        cur_value_rnd = first
    end
    return cur_value_rnd
end

flick_exploit_runtime = {
    packet = 0,
    last_switch = 0,
    side = false,
    pitch_inverted = false,
    generated_pitch = 0,
    freestand_side = -1,
    active_until = 0,
    cooldown_until = 0,
    window_ticks = 0,
    window_started = 0,
    last_threat = nil,
    yaw_noise = 0,
    body_noise = 0,
    shot_safe_until = 0,
    force_side = nil
}

function flick_exploit_reset_runtime()
    flick_exploit_runtime.packet = 0
    flick_exploit_runtime.last_switch = 0
    flick_exploit_runtime.side = false
    flick_exploit_runtime.active_until = 0
    flick_exploit_runtime.cooldown_until = 0
    flick_exploit_runtime.window_ticks = 0
    flick_exploit_runtime.window_started = 0
    flick_exploit_runtime.yaw_noise = 0
    flick_exploit_runtime.body_noise = 0
    flick_exploit_runtime.shot_safe_until = 0
    flick_exploit_runtime.force_side = nil
end

function flick_exploit_update_freestand()
    local me = entity.get_local_player()
    local threat = client.current_threat()

    if not me or not threat then
        return
    end

    local ex, ey, ez = client.eye_position()
    local tx, ty, tz = entity.hitbox_position(threat, 3)

    if not ex or not tx then
        return
    end

    local yaw = math.atan2
        and math.deg(math.atan2(ty - ey, tx - ex))
        or math.deg(math.atan((ty - ey) / ((tx - ex) == 0 and 0.0001 or (tx - ex))))
    local left = math.rad(yaw + 90)
    local right = math.rad(yaw - 90)
    local lx, ly = ex + math.cos(left) * 31, ey + math.sin(left) * 31
    local rx, ry = ex + math.cos(right) * 31, ey + math.sin(right) * 31
    local ent_left, damage_left = client.trace_bullet(me, lx, ly, ez, tx, ty, tz, false)
    local ent_right, damage_right = client.trace_bullet(me, rx, ry, ez, tx, ty, tz, false)

    if ent_left ~= threat then
        damage_left = 0
    end

    if ent_right ~= threat then
        damage_right = 0
    end

    if (damage_left > 0 or damage_right > 0) and damage_left ~= damage_right then
        flick_exploit_runtime.freestand_side = damage_left > damage_right and -1 or 1
    end
end

function flick_exploit_should_update(condition)
    if not ui.get(flick_exploit) then
        return false
    end

    if not player.get_dt() then
        return false
    end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        return false
    end

    local weapon = entity.get_player_weapon(me)
    if weapon ~= nil then
        local ok, weapon_info = pcall(weapons, weapon)
        if ok and weapon_info ~= nil and weapon_info.is_revolver then
            return false
        end
    end

    local selected_states = ui.get(flick_exploit_states)
    if type(selected_states) ~= "table" or #selected_states == 0 then
        return false
    end

    return contains(selected_states, condition)
end

function flick_exploit_threat_info()
    local me = entity.get_local_player()
    local threat = client.current_threat()

    if not me or not threat or not entity.is_alive(threat) or entity.is_dormant(threat) then
        return nil, false, 99999
    end

    local lx, ly, lz = entity.get_origin(me)
    local tx, ty, tz = entity.get_origin(threat)

    if lx == nil or tx == nil then
        return threat, false, 99999
    end

    local distance = distance3d(lx, ly, lz or 0, tx, ty, tz or 0)
    return threat, distance <= 900, distance
end

function flick_exploit_can_fire(cmd)
    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        return false
    end

    local weapon = entity.get_player_weapon(me)
    if weapon == nil then
        return false
    end

    local next_attack = entity.get_prop(me, "m_flNextAttack") or 0
    local next_primary = entity.get_prop(weapon, "m_flNextPrimaryAttack") or 0

    if cmd.in_reload == 1 or cmd.in_use == 1 then
        return false
    end

    return next_attack <= globals.curtime() and next_primary <= globals.curtime() + globals.tickinterval() * 2
end

function flick_exploit_update_window(cmd, condition)
    local rt = flick_exploit_runtime
    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local tick = globals.tickcount()
    local threat, close_threat, distance = flick_exploit_threat_info()
    local can_fire = flick_exploit_can_fire(cmd)

    if can_fire then
        rt.shot_safe_until = tick + 3
    end

    if choked ~= 0 then
        return rt.active_until >= tick, threat, close_threat, can_fire
    end

    local active = rt.active_until >= tick
    if not active and tick >= (rt.cooldown_until or 0) then
        local delay = math.max(1, ui.get(flick_exploit_delay))
        local threat_bonus = close_threat and 2 or (threat ~= nil and 1 or 0)
        local should_start = (rt.packet - (rt.last_switch or 0)) >= math.max(2, delay - threat_bonus)

        if should_start then
            rt.side = not rt.side
            rt.last_switch = rt.packet
            rt.window_started = tick
            rt.window_ticks = random_between(close_threat and 2 or 1, close_threat and 4 or 3)
            rt.active_until = tick + rt.window_ticks
            rt.cooldown_until = rt.active_until + random_between(can_fire and 5 or 7, close_threat and 13 or 17)
            rt.yaw_noise = random_between(-9, 9)
            rt.body_noise = random_between(-3, 2)
            rt.last_threat = threat

            if threat ~= nil then
                rt.force_side = rt.freestand_side == -1 and -1 or 1
            else
                rt.force_side = nil
            end

            active = true
        end
    end

    return active, threat, close_threat, can_fire
end

function flick_exploit_update_pitch(choked)
    local pitch_mode = ui.get(flick_exploit_pitch)

    if pitch_mode == "Off" then
        return nil
    end

    local first_pitch = ui.get(flick_exploit_pitch_value)
    local second_pitch = ui.get(flick_exploit_pitch_second)

    if pitch_mode == "Static" then
        return first_pitch
    end

    if pitch_mode == "Sway" then
        local speed = ui.get(flick_exploit_pitch_speed)
        local time = globals.curtime() * speed * 0.1
        local phase = time % 1
        return lerp(first_pitch, second_pitch, phase)
    end

    if pitch_mode == "Switch" then
        return flick_exploit_runtime.pitch_inverted and second_pitch or first_pitch
    end

    if pitch_mode == "Random" then
        return random_between(first_pitch, second_pitch)
    end

    if pitch_mode == "Static Random" then
        if static.defensive and choked == 0 then
            flick_exploit_runtime.generated_pitch = random_between(first_pitch, second_pitch)
        end

        return flick_exploit_runtime.generated_pitch
    end

    return nil
end

function flick_exploit_active_body_mode(condition)
    local settings = aa_settings and aa_settings[condition] or nil

    if not settings or (condition ~= "Global" and settings.allow ~= nil and not ui.get(settings.allow)) then
        settings = aa_settings and aa_settings["Global"] or nil
    end

    if settings ~= nil and settings.body_yaw ~= nil then
        return ui.get(settings.body_yaw)
    end

    return "Off"
end

function flick_exploit_apply(cmd, condition)
    if not flick_exploit_should_update(condition) then
        flick_exploit_reset_runtime()
        return
    end

    flick_exploit_update_freestand()

    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    if choked == 0 then
        flick_exploit_runtime.packet = flick_exploit_runtime.packet + 1
        flick_exploit_runtime.pitch_inverted = not flick_exploit_runtime.pitch_inverted
    end

    local flick_active, threat, close_threat, can_fire = flick_exploit_update_window(cmd, condition)
    local defensive_active = static.defensive or player.get_dt()
    if not flick_active and not defensive_active then
        return
    end

    local side = flick_exploit_runtime.side and 1 or -1
    local freestand_side = flick_exploit_runtime.freestand_side == -1 and -1 or 1
    local forced_side = flick_exploit_runtime.force_side or freestand_side
    local shot_safe = globals.tickcount() <= (flick_exploit_runtime.shot_safe_until or 0)
    local window_age = globals.tickcount() - (flick_exploit_runtime.window_started or 0)
    local entry_scale = window_age <= 1 and 1 or 0.72
    local yaw_scale = flick_active and entry_scale or 0.28
    local body_scale = flick_active and 1 or 0.55

    if shot_safe then
        yaw_scale = math.min(yaw_scale, 0.45)
        body_scale = math.min(body_scale, 0.72)
    end

    if close_threat then
        yaw_scale = math.min(1, yaw_scale + 0.12)
    end

    local base_offset = ui.get(flick_exploit_offset)
    local base_body = ui.get(flick_exploit_body)
    local yaw_noise = flick_exploit_runtime.yaw_noise or 0
    local body_noise = flick_exploit_runtime.body_noise or 0
    local active_body_mode = flick_exploit_active_body_mode(condition)
    local yaw_offset = defensive_active and (base_offset * yaw_scale * side * forced_side + yaw_noise) or 0
    local body_value = defensive_active and ((base_body + body_noise) * body_scale * side) or side

    if active_body_mode ~= "Off" and math.abs(body_value) < 35 then
        body_value = (body_value < 0 and -1 or 1) * random_between(56, 60)
    end

    if flick_active and cmd.command_number % (close_threat and 5 or 7) == 0 then
        cmd.force_defensive = true
    end

    pcall(ui.set, ref.yaw_base, "At Targets")
    pcall(ui.set, ref.yaw[1], "180")
    pcall(ui.set, ref.yaw[2], clamp(yaw_offset, -180, 180))
    pcall(ui.set, ref.yaw_jitter[1], "Off")
    pcall(ui.set, ref.yaw_jitter[2], 0)
    pcall(ui.set, ref.body_yaw[1], "Static")
    pcall(ui.set, ref.body_yaw[2], clamp(body_value, -60, 60))
    pcall(ui.set, ref.freestanding_body_yaw, false)
    pcall(ui.set, ref.edge_yaw, false)
    pcall(ui.set, ref.roll, 0)

    local pitch_value = flick_exploit_update_pitch(choked)
    if pitch_value ~= nil then
        pcall(ui.set, ref.pitch[1], "Custom")
        pcall(ui.set, ref.pitch[2], clamp(pitch_value, -89, 89))
    end
end

panchan_exploit_runtime = panchan_exploit_runtime or {
    active_until = 0,
    cooldown_until = 0,
    side = 1,
    yaw_noise = 0,
    body_noise = 0,
    pitch_noise = 0,
    body_side = 1,
    last_threat = nil,
    last_condition = nil,
    freestand_side = 1,
    freestand_damage_delta = 0,
    side_lock_until = 0,
    pattern_id = 1,
    phase_offset = 0,
    packet_flip = false,
    lag_goal = 0,
    release_tick = 0,
    release_jitter = 0,
    body_target = 58,
    danger_score = 0,
    real_desync = 0,
    side_history = 0,
    started_tick = 0,
    released = false,
    threat_close = false,
    threat_distance = nil,
    speed = 0,
    last_yaw = nil,
    chimera_flick_active = false,
    chimera_flick_side = 1,
    chimera_flick_phase = 0,
    crimwalk_flip = false,
    crimwalk_saved = nil,
    crimwalk_active = false,
    scolious_saved = nil,
    scolious_active = false,
    adaptive_active = false,
    adaptive_side = 1,
    adaptive_next_switch = 0,
    adaptive_yaw_noise = 0,
    adaptive_body = 45,
    adaptive_was_air = false,
    adaptive_land_until = 0,
    adaptive_threat = nil,
    adaptive_release_until = 0,
    adaptive_last_choked = 0,
    adaptive_stuck_ticks = 0,
    adaptive_zero_stuck_ticks = 0,
    adaptive_last_speed = 0,
    adaptive_micro_phase = 0,
    massive_active = false,
    massive_side = 1,
    massive_last_choked = 0
}

function panchan_exploit_reset_runtime()
    panchan_exploit_runtime.active_until = 0
    panchan_exploit_runtime.cooldown_until = 0
    panchan_exploit_runtime.side = 1
    panchan_exploit_runtime.yaw_noise = 0
    panchan_exploit_runtime.body_noise = 0
    panchan_exploit_runtime.pitch_noise = 0
    panchan_exploit_runtime.body_side = 1
    panchan_exploit_runtime.last_threat = nil
    panchan_exploit_runtime.last_condition = nil
    panchan_exploit_runtime.freestand_side = 1
    panchan_exploit_runtime.freestand_damage_delta = 0
    panchan_exploit_runtime.side_lock_until = 0
    panchan_exploit_runtime.pattern_id = 1
    panchan_exploit_runtime.phase_offset = 0
    panchan_exploit_runtime.packet_flip = false
    panchan_exploit_runtime.lag_goal = 0
    panchan_exploit_runtime.release_tick = 0
    panchan_exploit_runtime.release_jitter = 0
    panchan_exploit_runtime.body_target = 58
    panchan_exploit_runtime.danger_score = 0
    panchan_exploit_runtime.real_desync = 0
    panchan_exploit_runtime.side_history = 0
    panchan_exploit_runtime.started_tick = 0
    panchan_exploit_runtime.released = false
    panchan_exploit_runtime.threat_close = false
    panchan_exploit_runtime.threat_distance = nil
    panchan_exploit_runtime.speed = 0
    panchan_exploit_runtime.last_yaw = nil
    panchan_exploit_runtime.chimera_flick_active = false
    panchan_exploit_runtime.chimera_flick_side = 1
    panchan_exploit_runtime.chimera_flick_phase = 0
    panchan_exploit_runtime.crimwalk_flip = false
    panchan_exploit_runtime.crimwalk_active = false
    panchan_exploit_runtime.scolious_active = false
    panchan_exploit_runtime.adaptive_active = false
    panchan_exploit_runtime.adaptive_side = 1
    panchan_exploit_runtime.adaptive_next_switch = 0
    panchan_exploit_runtime.adaptive_yaw_noise = 0
    panchan_exploit_runtime.adaptive_body = 45
    panchan_exploit_runtime.adaptive_was_air = false
    panchan_exploit_runtime.adaptive_land_until = 0
    panchan_exploit_runtime.adaptive_threat = nil
    panchan_exploit_runtime.adaptive_release_until = 0
    panchan_exploit_runtime.adaptive_last_choked = 0
    panchan_exploit_runtime.adaptive_stuck_ticks = 0
    panchan_exploit_runtime.adaptive_zero_stuck_ticks = 0
    panchan_exploit_runtime.adaptive_last_speed = 0
    panchan_exploit_runtime.adaptive_micro_phase = 0
    panchan_exploit_runtime.massive_active = false
    panchan_exploit_runtime.massive_side = 1
    panchan_exploit_runtime.massive_last_choked = 0
end

function panchan_crimwalk_save()
    local rt = panchan_exploit_runtime
    if rt.crimwalk_saved ~= nil then
        return
    end

    local saved = {}
    local hotkey_modes = {
        [0] = "Always on",
        [1] = "On hotkey",
        [2] = "Toggle",
        [3] = "Off hotkey"
    }
    local function save(name, ref_item)
        if ref_item == nil then
            return
        end

        local ok, a, b, c = pcall(ui.get, ref_item)
        if ok then
            local ok_type, item_type = pcall(ui.type, ref_item)
            if ok_type and item_type == "hotkey" then
                saved[name] = {ref = ref_item, values = {hotkey_modes[b] or "On hotkey", c or 0}}
            else
                saved[name] = {ref = ref_item, values = {a, b, c}}
            end
        end
    end

    save("dt", ref.dt and ref.dt[1])
    save("hs", ref.hs and ref.hs[1])
    save("fakelag_enabled", ref.falelag_enabled and ref.falelag_enabled[1])
    save("fakelag_limit", ref.fakelag_limit)
    save("body_yaw_mode", ref.body_yaw and ref.body_yaw[1])
    save("body_yaw_value", ref.body_yaw and ref.body_yaw[2])
    save("freestanding_body_yaw", ref.freestanding_body_yaw)
    save("yaw_jitter_mode", ref.yaw_jitter and ref.yaw_jitter[1])
    save("yaw_jitter_value", ref.yaw_jitter and ref.yaw_jitter[2])

    rt.crimwalk_saved = saved
end

function panchan_crimwalk_reset_fd()
end

function panchan_crimwalk_restore()
    local rt = panchan_exploit_runtime
    local saved = rt.crimwalk_saved

    if saved == nil and not rt.crimwalk_active then
        return
    end

    if saved ~= nil then
        for _, item in pairs(saved) do
            if item.ref ~= nil and item.values ~= nil then
                pcall(ui.set, item.ref, unpack(item.values))
            end
        end
    end

    if cvar and cvar.sv_maxusrcmdprocessticks then
        pcall(function()
            cvar.sv_maxusrcmdprocessticks:set_int(16)
        end)
    end

    rt.crimwalk_saved = nil
    rt.crimwalk_active = false
end

function panchan_exploit_should_update()
    if airlag_panchan_active ~= nil and airlag_panchan_active() then
        return false
    end

    if ref.fd ~= nil and ui.get(ref.fd) then
        return false
    end

    if not ui.get(panchan_exploit) then
        return false
    end

    if not ui.get(panchan_exploit_key) then
        return false
    end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then
        return false
    end

    if panchan_exploit_is_v2_meta_mode ~= nil and panchan_exploit_is_v2_meta_mode() then
        return true
    end

    return true
end

function panchan_exploit_is_v2_meta_mode()
    if panchan_exploit_mode == nil then
        return false
    end

    local mode = ui.get(panchan_exploit_mode)
    return mode == "Panchan V2 Meta" or mode == "Panchan V2 Meta (OFF DOUBLE TAP AND HS)"
end

function panchan_exploit_is_adaptive_mode()
    if panchan_exploit_mode == nil then
        return false
    end

    return ui.get(panchan_exploit_mode) == "Panchan Adaptive Core (OFF DOUBLE TAP AND HS)"
end

function panchan_exploit_is_massive_mode()
    if panchan_exploit_mode == nil then
        return false
    end

    return ui.get(panchan_exploit_mode) == "Panchan Massive Fake (OFF DOUBLE TAP AND HS)"
end

function panchan_main_exploit_active()
    return panchan_exploit ~= nil
        and panchan_exploit_key ~= nil
        and ui.get(panchan_exploit)
        and ui.get(panchan_exploit_key)
        and (ref.fd == nil or not ui.get(ref.fd))
end

function panchan_packet_exploit_active()
    if airlag_panchan_active ~= nil and airlag_panchan_active() then
        return true
    end

    return panchan_main_exploit_active()
end

function panchan_exploit_v2_meta_active()
    return panchan_exploit_mode ~= nil
        and panchan_main_exploit_active()
        and panchan_exploit_is_v2_meta_mode()
end

function panchan_crimwalk_apply(cmd)
    local rt = panchan_exploit_runtime
    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local tick = globals.tickcount()

    panchan_crimwalk_save()
    rt.crimwalk_active = true

    if tick % 12 == 0 then
        rt.crimwalk_flip = not rt.crimwalk_flip
    end

    pcall(ui.set, ref.falelag_enabled[1], false)
    pcall(ui.set, ref.hs[1], false)
    pcall(ui.set, ref.dt[1], false)

    local body_limit = random_between(0, 45)
    local body_sign = rt.crimwalk_flip and 1 or -1
    pcall(ui.set, ref.body_yaw[1], "Static")
    pcall(ui.set, ref.body_yaw[2], body_limit * body_sign)
    pcall(ui.set, ref.freestanding_body_yaw, false)
    pcall(ui.set, ref.yaw_jitter[1], "Off")

    local me = entity.get_local_player()
    if me ~= nil and entity.set_prop ~= nil then
        pcall(entity.set_prop, me, "m_flLowerBodyYawTarget", random_between(-180, 180))
    end

    if choked < 14 then
        cmd.allow_send_packet = false
    end

    if choked < 12 then
        if cvar and cvar.sv_maxusrcmdprocessticks then
            pcall(function()
                cvar.sv_maxusrcmdprocessticks:set_int(0)
            end)
        end
    else
        if cvar and cvar.sv_maxusrcmdprocessticks then
            pcall(function()
                cvar.sv_maxusrcmdprocessticks:set_int(19)
            end)
        end
    end

    if choked < 11 then
        if cvar and cvar.sv_maxusrcmdprocessticks then
            pcall(function()
                cvar.sv_maxusrcmdprocessticks:set_int(0)
            end)
        end
    else
        if cvar and cvar.sv_maxusrcmdprocessticks then
            pcall(function()
                cvar.sv_maxusrcmdprocessticks:set_int(19)
            end)
        end
    end
end

airlag_panchan_runtime = airlag_panchan_runtime or {
    active = false,
    patch = {
        name = "Panchan Airlag",
        address = 0x433AC17C,
        size = 6,
        capture_original = true,
        patched = {0x90, 0x90, 0x90, 0x90, 0x90, 0x90}
    }
}

function airlag_panchan_restore()
    if panchan_aesthetic_patch_restore ~= nil then
        panchan_aesthetic_patch_restore(airlag_panchan_runtime.patch)
    end
    airlag_panchan_runtime.active = false
end

function airlag_panchan_active()
    return airlag_panchan_exploit ~= nil
        and airlag_panchan_key ~= nil
        and ui.get(airlag_panchan_exploit)
        and ui.get(airlag_panchan_key)
end

function airlag_panchan_apply(cmd)
    if not airlag_panchan_active() then
        airlag_panchan_restore()
        return
    end

    cmd.discharge_pending = globals.tickcount() % 16 == 0

    if panchan_aesthetic_patch_apply ~= nil
        and panchan_aesthetic_patch_apply(airlag_panchan_runtime.patch) then
        airlag_panchan_runtime.active = true
    else
        airlag_panchan_runtime.active = false
    end
end

function panchan_scolious_save()
    local rt = panchan_exploit_runtime
    if rt.scolious_saved ~= nil then
        return
    end

    local saved = {}

    local function save(name, ref_item)
        if ref_item == nil then
            return
        end

        local ok, a, b, c = pcall(ui.get, ref_item)
        if ok then
            saved[name] = {ref = ref_item, values = {a, b, c}}
        end
    end

    save("enabled", ref.enabled)
    save("pitch_mode", ref.pitch and ref.pitch[1])
    save("pitch_value", ref.pitch and ref.pitch[2])
    save("yaw_base", ref.yaw_base)
    save("yaw_mode", ref.yaw and ref.yaw[1])
    save("yaw_offset", ref.yaw and ref.yaw[2])
    save("fakelag_enabled", ref.falelag_enabled and ref.falelag_enabled[1])
    save("fakelag_limit", ref.fakelag_limit)
    save("fakelag_amount", ref.fakelag_amount)
    save("variability", ref.variability)
    save("max_process_ticks", ref.max_process_ticks)
    save("hs", ref.hs and ref.hs[1])
    save("dt", ref.dt and ref.dt[1])
    save("body_yaw_mode", ref.body_yaw and ref.body_yaw[1])
    save("body_yaw_value", ref.body_yaw and ref.body_yaw[2])
    save("yaw_jitter_mode", ref.yaw_jitter and ref.yaw_jitter[1])
    save("yaw_jitter_value", ref.yaw_jitter and ref.yaw_jitter[2])
    save("freestanding_body_yaw", ref.freestanding_body_yaw)
    save("edge_yaw", ref.edge_yaw)

    rt.scolious_saved = saved
end

function panchan_exploit_packet(cmd, value)
    if cmd == nil then
        return
    end

    pcall(function()
        cmd.allow_send_packet = value
    end)
    pcall(function()
        cmd.send_packet = value
    end)
end

function panchan_scolious_restore(cmd)
    local rt = panchan_exploit_runtime
    local saved = rt.scolious_saved

    if saved == nil and not rt.scolious_active then
        return
    end

    local fake_duck_active = ref.fd ~= nil and ui.get(ref.fd)
    if cmd ~= nil and not fake_duck_active then
        panchan_exploit_packet(cmd, true)
        cmd.in_duck = 0
    end

    if saved ~= nil then
        for _, item in pairs(saved) do
            if item.ref ~= nil and item.values ~= nil then
                pcall(ui.set, item.ref, unpack(item.values))
            end
        end
    end

    if cvar and cvar.sv_maxusrcmdprocessticks then
        local process_ticks = 16
        if saved ~= nil and saved.max_process_ticks ~= nil and saved.max_process_ticks.values ~= nil then
            process_ticks = tonumber(saved.max_process_ticks.values[1]) or process_ticks
        end
        pcall(function()
            cvar.sv_maxusrcmdprocessticks:set_int(process_ticks)
        end)
    end

    rt.scolious_saved = nil
    rt.scolious_active = false
    rt.adaptive_active = false
    rt.massive_active = false
end

function panchan_adaptive_weapon_profile(me)
    local weapon = me and entity.get_player_weapon(me)
    if weapon == nil then
        return false, false
    end

    local ok, data = pcall(weapons, weapon)
    if not ok or data == nil then
        return false, false
    end

    local name = string.lower(tostring(data.name or data.console_name or data.weapon_name or ""))
    local scoped_weapon = name:find("awp", 1, true) ~= nil
        or name:find("ssg08", 1, true) ~= nil
        or name:find("scout", 1, true) ~= nil
        or name:find("scar20", 1, true) ~= nil
        or name:find("g3sg1", 1, true) ~= nil
    local scoped = entity.get_prop(me, "m_bIsScoped") == 1

    return scoped_weapon, scoped
end

function panchan_adaptive_apply(cmd, condition)
    local rt = panchan_exploit_runtime
    local me = entity.get_local_player()
    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local tick = globals.tickcount()

    panchan_scolious_save()
    rt.scolious_active = true
    rt.adaptive_active = true

    local vx, vy = 0, 0
    local flags = 0
    if me ~= nil then
        vx, vy = entity.get_prop(me, "m_vecVelocity")
        flags = entity.get_prop(me, "m_fFlags") or 0
    end

    local speed = math.sqrt((vx or 0) * (vx or 0) + (vy or 0) * (vy or 0))
    local in_air = bit.band(flags, 1) == 0 or cmd.in_jump == 1 or cmd.in_jump == true
    local scoped_weapon, scoped = panchan_adaptive_weapon_profile(me)
    local threat = client.current_threat()
    local close = false

    if threat ~= nil and threat > 0 and me ~= nil then
        local lx, ly, lz = entity.get_origin(me)
        local tx, ty, tz = entity.get_origin(threat)
        if lx ~= nil and tx ~= nil then
            close = distance3d(lx, ly, lz or 0, tx, ty, tz or 0) <= 780
        end
    end

    if rt.adaptive_was_air == true and not in_air then
        rt.adaptive_land_until = tick + 3
    end
    rt.adaptive_was_air = in_air

    local landing_guard = tick <= (rt.adaptive_land_until or 0)
    if threat ~= (rt.adaptive_threat or nil) and choked <= 1 then
        rt.adaptive_threat = threat
        rt.adaptive_next_switch = tick + random_between(close and 5 or 8, close and 9 or 14)
    end

    if tick >= (rt.adaptive_next_switch or 0) and choked <= 1 then
        rt.adaptive_side = -(rt.adaptive_side or 1)
        rt.adaptive_next_switch = tick + random_between(close and 6 or 10, close and 10 or 16)
        rt.adaptive_yaw_noise = random_between(close and -16 or -8, close and 16 or 8)
        rt.adaptive_body = random_between(close and 42 or 28, close and 56 or 44)
    end

    local side = rt.adaptive_side == -1 and -1 or 1
    local choke_limit = close and 15 or 14
    if in_air then
        choke_limit = math.min(choke_limit, 13)
    end
    if landing_guard then
        choke_limit = math.min(choke_limit, 10)
    end
    if scoped_weapon and scoped then
        choke_limit = math.min(choke_limit, speed > 20 and 11 or 12)
    elseif speed > 185 then
        choke_limit = math.min(choke_limit, 13)
    end
    choke_limit = clamp(choke_limit, 10, 14)

    local soft_release = landing_guard or (scoped_weapon and scoped and speed > 20 and choked >= (choke_limit - 1))
    local attack = cmd.in_attack == 1 or cmd.in_attack == true
    local force_release = choked >= choke_limit
        or soft_release
        or attack
        or cmd.in_use == 1
        or cmd.in_use == true
        or cmd.in_reload == 1
        or cmd.in_reload == true
    local holding = not force_release
    panchan_exploit_packet(cmd, not holding)

    if cvar and cvar.sv_maxusrcmdprocessticks then
        pcall(function()
            cvar.sv_maxusrcmdprocessticks:set_int(holding and 0 or (scoped_weapon and scoped and 16 or 19))
        end)
    end

    local duck_end = clamp(choke_limit - (in_air and 3 or 1), 8, 14)
    cmd.in_duck = (holding and choked > 1 and choked < duck_end) and 1 or 0
    cmd.force_defensive = holding and not landing_guard and ((tick + choked) % (close and 4 or 5) ~= 0)

    local yaw_offset = side * (close and 24 or 12) + (rt.adaptive_yaw_noise or 0)
    local body_value = side * (rt.adaptive_body or 45)
    if scoped_weapon and scoped then
        yaw_offset = side * (speed > 20 and 8 or 14) + math.floor((rt.adaptive_yaw_noise or 0) * 0.35)
        body_value = side * (speed > 20 and 28 or 38)
    elseif in_air then
        yaw_offset = yaw_offset + side * 5
        body_value = side * 54
    elseif landing_guard then
        yaw_offset = side * 8
        body_value = side * 24
    end
    if force_release then
        yaw_offset = normalize_yaw(-side * (close and 58 or 42) + math.floor((rt.adaptive_yaw_noise or 0) * 0.35))
        body_value = -side * (close and 56 or 44)
    end

    pcall(ui.set, ref.enabled, true)
    pcall(ui.set, ref.yaw_base, "At Targets")
    pcall(ui.set, ref.yaw[1], "180")
    pcall(ui.set, ref.yaw[2], clamp(normalize_yaw(yaw_offset), -180, 180))
    pcall(ui.set, ref.falelag_enabled[1], false)
    pcall(ui.set, ref.hs[1], false)
    pcall(ui.set, ref.dt[1], false)
    pcall(ui.set, ref.yaw_jitter[1], "Off")
    pcall(ui.set, ref.yaw_jitter[2], 0)
    pcall(ui.set, ref.body_yaw[1], "Static")
    pcall(ui.set, ref.body_yaw[2], clamp(body_value, -60, 60))
    pcall(ui.set, ref.freestanding_body_yaw, false)
    pcall(ui.set, ref.edge_yaw, false)
end

function panchan_massive_fake_apply(cmd, condition)
    local rt = panchan_exploit_runtime
    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local max_proc = 17
    local fake_lag_limit = max_proc - 1

    panchan_scolious_save()
    rt.scolious_active = true
    rt.massive_active = true

    if ref.max_process_ticks ~= nil then
        pcall(ui.set, ref.max_process_ticks, max_proc)
    end

    if cvar and cvar.sv_maxusrcmdprocessticks then
        pcall(function()
            cvar.sv_maxusrcmdprocessticks:set_int(max_proc)
        end)
    end

    pcall(ui.set, ref.enabled, true)
    pcall(ui.set, ref.pitch[1], "Default")
    pcall(ui.set, ref.pitch[2], 0)
    pcall(ui.set, ref.falelag_enabled[1], true)
    pcall(ui.set, ref.fakelag_amount, "Maximum")
    pcall(ui.set, ref.fakelag_limit, fake_lag_limit)
    pcall(ui.set, ref.variability, 0)
    pcall(ui.set, ref.hs[1], false)
    pcall(ui.set, ref.dt[1], false)
    pcall(ui.set, ref.yaw_base, "At Targets")
    pcall(ui.set, ref.yaw[1], "180")
    pcall(ui.set, ref.yaw_jitter[1], "Off")
    pcall(ui.set, ref.yaw_jitter[2], 0)
    pcall(ui.set, ref.freestanding_body_yaw, false)
    pcall(ui.set, ref.edge_yaw, false)

    local massive_tick = choked == fake_lag_limit
    if massive_tick and rt.massive_last_choked ~= fake_lag_limit then
        rt.massive_side = -(rt.massive_side or 1)
    end

    pcall(ui.set, ref.body_yaw[1], "Static")
    if massive_tick then
        local massive_yaw = (rt.massive_side or 1) > 0 and 90 or -40
        pcall(ui.set, ref.yaw[2], massive_yaw)
        pcall(ui.set, ref.body_yaw[2], 180)
    else
        pcall(ui.set, ref.yaw[2], 0)
        pcall(ui.set, ref.body_yaw[2], 0)
    end

    rt.massive_last_choked = choked
    cmd.force_defensive = false
    return true
end

function panchan_exploit_apply(cmd, condition)
    -- Airlag runs later in setup_command; release its overrides before the next owner saves them.
    if airlag_panchan_active ~= nil
        and not airlag_panchan_active()
        and airlag_panchan_runtime ~= nil
        and airlag_panchan_runtime.active then
        airlag_panchan_restore()
    end

    if not panchan_exploit_should_update() then
        panchan_scolious_restore(cmd)
        panchan_crimwalk_restore()
        panchan_exploit_reset_runtime()
        return
    end

    if panchan_exploit_is_v2_meta_mode ~= nil and panchan_exploit_is_v2_meta_mode() then
        panchan_scolious_restore(cmd)
        panchan_crimwalk_apply(cmd)
        return
    end

    panchan_crimwalk_restore()
    local massive_mode = panchan_exploit_is_massive_mode ~= nil and panchan_exploit_is_massive_mode()
    if panchan_exploit_runtime.massive_active and not massive_mode then
        panchan_scolious_restore(cmd)
    end

    if massive_mode then
        panchan_massive_fake_apply(cmd, condition)
        return
    end

    if panchan_exploit_is_adaptive_mode ~= nil and panchan_exploit_is_adaptive_mode() then
        panchan_adaptive_apply(cmd, condition)
        return
    end

    panchan_scolious_restore(cmd)
end

roll_antiaim_runtime = roll_antiaim_runtime or {
    max_positive = nil,
    max_negative = nil
}

function roll_antiaim_set(value)
    value = math.floor(clamp(tonumber(value) or 0, -50, 50))

    if value == 0 then
        return pcall(ui.set, ref.roll, 0)
    end

    local sign = value < 0 and -1 or 1
    local wanted = math.abs(value)
    local cached_limit = sign > 0 and roll_antiaim_runtime.max_positive or roll_antiaim_runtime.max_negative

    if cached_limit ~= nil then
        return pcall(ui.set, ref.roll, sign * math.min(wanted, cached_limit))
    end

    for candidate = wanted, 0, -1 do
        local ok = pcall(ui.set, ref.roll, sign * candidate)

        if ok then
            if sign > 0 then
                roll_antiaim_runtime.max_positive = candidate
            else
                roll_antiaim_runtime.max_negative = candidate
            end

            return true
        end
    end

    return false
end

function roll_antiaim_apply()
    if ui.get(roll_antiaim) and ui.get(roll_antiaim_key) then
        roll_antiaim_set(ui.get(roll_antiaim_value))
    end
end

--[[is_peeking = false

function is_peeking_state()
    local me = entity.get_local_player()
    if not me or me == 0 then
        is_peeking = false
        return false
    end

    local enemies = entity.get_players(true)
    if not enemies or #enemies == 0 then
        is_peeking = false
        return false
    end

    local hx, hy, hz = entity.hitbox_position(me, 3)
    if not hx or not hy or not hz then
        is_peeking = false
        return false
    end

    local stomach_origin = vector(hx, hy, hz)
    local predict_amt = 0.55
    local velocity = vector(entity.get_prop(me, 'm_vecVelocity'))
    local stomach_future = vector(
        stomach_origin.x + velocity.x * predict_amt,
        stomach_origin.y + velocity.y * predict_amt,
        stomach_origin.z + velocity.z * predict_amt
    )

    is_peeking = false

    for i = 1, #enemies do
        local enemy = enemies[i]
        if entity.get_player_weapon(enemy) then
            local ehx, ehy, ehz = entity.hitbox_position(enemy, 3)
            if ehx and ehy and ehz then
                local enemy_body = vector(ehx, ehy, ehz)

                local _, damage = client.trace_bullet(
                    enemy,
                    enemy_body.x, enemy_body.y, enemy_body.z,
                    stomach_origin.x, stomach_origin.y, stomach_origin.z,
                    false
                )

                if damage and damage > 0 then
                    is_peeking = true
                    break
                end
            end
        end
    end

    return is_peeking
end


function get_fs_side()
    local player = entity.get_local_player()
    if not player or entity.get_prop(player, "m_lifeState") ~= 0 then
        return "none"
    end

    local eye = vector(client.eye_position())
    local ang = vector(client.camera_angles())

    local trace_data = {
        left = 0,
        right = 0
    }

    for i = ang.y - 120, ang.y + 120, 30 do
        if i ~= ang.y then
            local rad = math.rad(i)
            local px = eye.x + 256 * math.cos(rad)
            local py = eye.y + 256 * math.sin(rad)
            local pz = eye.z

            local fraction = client.trace_line(player, eye.x, eye.y, eye.z, px, py, pz)
            local side = i < ang.y and "left" or "right"
            trace_data[side] = trace_data[side] + fraction
        end
    end

    if trace_data.left < trace_data.right then
        return "left"
    elseif trace_data.right < trace_data.left then
        return "right"
    else
        return "none"
    end
end]]

yaw_rl = 0
yaw_rl_def = 0
local spin_yaw = 0
change_debug("add", "antiaim:at_targets()", "L1")
change_debug("add", "antiaim:custom_desync()", "L373")
change_debug("add", "entity:shifting()", "-1")
change_debug("add", "entity:exploit.get()", "0")
change_debug("add", "entity:defensive_diff.get()", "0")
change_debug("add", "antiaim:resolver_trap()", "0")

function apply_custom_desync(cmd, yaw_base, yaw_value, switch_state)
    local trap_power = adaptive_aa_power()
    local desync_angle = switch_state and -yaw_value or yaw_value

    if trap_power > 0 then
        local base = clamp(math.max(18, math.abs(yaw_value)) + math.floor(trap_power * 0.1), 18, 60)
        local noise = math.floor(trap_power * 0.05)
        desync_angle = clamp(base * aa_adaptive.side + random_between(-noise, noise), -60, 60)
    end

    desync_angle = anti_brute_adjust_body(desync_angle, cmd)

    ui.set(ref.body_yaw[1], "Static")
    ui.set(ref.body_yaw[2], 0)

    if player.get_dt() then
        if cmd.chokedcommands == 0 then
            cmd.allow_send_packet = false
            local yaw_noise = trap_power > 0 and random_between(-4, 4) or 0
            ui.set(ref.yaw[2], clamp(-(desync_angle + yaw_base) + yaw_noise, -180, 180))
        end
    else
        ui.set(ref.body_yaw[2], clamp(desync_angle, -60, 60))

        if trap_power > 0 then
            ui.set(ref.yaw[2], clamp(yaw_base + random_between(-3, 3), -180, 180))
        end
    end
end

function apply_chaos_desync(cmd, yaw_base, yaw_value, switch_state, defensive)
    local tick = globals.tickcount()
    local trap_power = adaptive_aa_power()

    if anti_brute_active(cmd) and adaptive_desync_cache.anti_brute_generation ~= anti_brute.generation then
        adaptive_desync_cache.anti_brute_generation = anti_brute.generation
        adaptive_desync_cache.next_tick = 0
    end

    if tick >= adaptive_desync_cache.next_tick then
        local base = clamp(math.max(42, math.abs(yaw_value)), 42, 60)
        local low = clamp(base - (trap_power > 0 and 8 or 12), 35, 60)
        local high = 60
        local side = switch_state and -1 or 1

        if trap_power > 0 then
            side = aa_adaptive.side
        end

        local flip_chance = defensive and 40 or 35
        flip_chance = clamp(flip_chance + math.floor(trap_power * 0.18), 0, 62)

        if random_between(1, 100) <= flip_chance then
            side = -side
        end

        local noise_range = (defensive and 8 or 6) + math.floor(trap_power * 0.05)
        adaptive_desync_cache.angle = random_between(low, high) * side
        adaptive_desync_cache.noise = random_between(-noise_range, noise_range)
        adaptive_desync_cache.next_tick = tick + random_between(trap_power > 0 and 3 or 4, trap_power > 0 and 7 or 9)
    end

    local active_angle = anti_brute_adjust_body(adaptive_desync_cache.angle, cmd)

    ui.set(ref.body_yaw[1], "Static")
    ui.set(ref.body_yaw[2], 0)

    if player.get_dt() then
        if cmd.chokedcommands == 0 then
            cmd.allow_send_packet = false
            ui.set(ref.yaw[2], clamp(-(active_angle + yaw_base) + adaptive_desync_cache.noise, -180, 180))
        elseif trap_power > 0 then
            ui.set(ref.yaw[2], clamp(yaw_base - math.floor(adaptive_desync_cache.noise * 0.5), -180, 180))
        end
    else
        ui.set(ref.body_yaw[2], clamp(active_angle, -60, 60))
        ui.set(ref.yaw[2], clamp(yaw_base + adaptive_desync_cache.noise, -180, 180))
    end
end

panchan_delayed_presets = panchan_delayed_presets or {
    Panchan = {
        ["Stand"] = { yaw_left = -30, yaw_right = 36, body_left = -58, body_right = 58, delay_mode = "Sequence", delays = {4, 7, 3}, body_pattern = "Hold", body_phase = "One phase late", body_delay = 4 },
        ["Running"] = { yaw_left = -35, yaw_right = 41, body_left = -54, body_right = 60, delay_mode = "Random Range", delay_min = 3, delay_max = 6, body_pattern = "Random Hold", body_pulse = 6, body_phase = "Synced", body_delay = 4 },
        ["Slow-walk"] = { yaw_left = -39, yaw_right = 45, body_left = -58, body_right = 60, delay_mode = "Sequence", delays = {6, 10, 4}, body_pattern = "Pulse", body_pulse = 6, body_phase = "One phase late", body_delay = 6 },
        ["Duck"] = { yaw_left = -28, yaw_right = 38, body_left = -36, body_right = 60, delay_mode = "Sequence", delays = {5, 8, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 },
        ["Duck-Running"] = { yaw_left = -32, yaw_right = 42, body_left = -30, body_right = 60, delay_mode = "Random Range", delay_min = 3, delay_max = 7, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Independent", body_delay = 3 },
        ["Air"] = { yaw_left = -24, yaw_right = 32, body_left = -56, body_right = 60, delay_mode = "Fixed", delay_fixed = 4, body_pattern = "Hold", body_phase = "Synced", body_delay = 4 },
        ["Air-Duck"] = { yaw_left = -22, yaw_right = 40, body_left = -60, body_right = 60, delay_mode = "Random Range", delay_min = 7, delay_max = 9, body_pattern = "Hold", body_phase = "Synced", body_delay = 1 },
        ["Fake Lag"] = { yaw_left = -34, yaw_right = 40, body_left = -58, body_right = 58, delay_mode = "Sequence", delays = {5, 8}, body_pattern = "Random Hold", body_pulse = 6, body_phase = "Synced", body_delay = 4 },
        ["Safe-Head"] = { yaw_left = -18, yaw_right = 22, body_left = -60, body_right = 60, delay_mode = "Fixed", delay_fixed = 6, body_pattern = "Hold", body_phase = "One phase late", body_delay = 6 }
    },
    Aggressive = {
        ["Stand"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -19, yaw_left_min = -19, yaw_left_max = -23, yaw_right = 36, yaw_right_min = 36, yaw_right_max = 45, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 3, delay_max = 8, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Running"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -24, yaw_left_min = -24, yaw_left_max = -27, yaw_right = 36, yaw_right_min = 36, yaw_right_max = 39, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 4, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Slow-walk"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -26, yaw_left_min = -26, yaw_left_max = -32, yaw_right = 40, yaw_right_min = 40, yaw_right_max = 47, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 3, delay_max = 6, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Duck"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -25, yaw_left_min = -25, yaw_left_max = -30, yaw_right = 40, yaw_right_min = 40, yaw_right_max = 46, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "3-Way", modifier_offset = 15 },
        ["Duck-Running"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -25, yaw_left_min = -25, yaw_left_max = -27, yaw_right = 37, yaw_right_min = 37, yaw_right_max = 40, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 4, delay_max = 14, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Air"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -24, yaw_left_min = -24, yaw_left_max = -26, yaw_right = 26, yaw_right_min = 26, yaw_right_max = 30, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 3, delay_max = 6, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Air-Duck"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -17, yaw_left_min = -17, yaw_left_max = -20, yaw_right = 37, yaw_right_min = 37, yaw_right_max = 42, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 2, delay_max = 7, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" }
    },
    Universal = {
        ["Stand"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -23, yaw_right = 38, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Running"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -26, yaw_right = 33, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Slow-walk"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -23, yaw_right = 43, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 4, delay_max = 5, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Duck"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -29, yaw_right = 49, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Duck-Running"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -19, yaw_right = 42, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Air"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -14, yaw_right = 39, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Random Range", delay_min = 1, delay_max = 3, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" },
        ["Air-Duck"] = { source_runtime = "XO-Yaw", original_lr = true, yaw_left = -17, yaw_right = 38, body_left = -58, body_right = 58, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", modifier_mode = "Disabled" }
    },
    ["Panchan 2026"] = {
        ["Stand"] = { yaw_left = -31, yaw_right = 37, body_left = -56, body_right = 60, delay_mode = "Sequence", delays = {3, 5, 8}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true },
        ["Running"] = { yaw_left = -37, yaw_right = 43, body_left = -52, body_right = 60, delay_mode = "Sequence", delays = {2, 4, 7}, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Adaptive", body_delay = 3, adaptive = true },
        ["Slow-walk"] = { yaw_left = -41, yaw_right = 47, body_left = -58, body_right = 60, delay_mode = "Sequence", delays = {5, 9, 4}, body_pattern = "Pulse", body_pulse = 6, body_phase = "Adaptive", body_delay = 5, adaptive = true },
        ["Duck"] = { yaw_left = -29, yaw_right = 39, body_left = -32, body_right = 60, delay_mode = "Sequence", delays = {4, 7, 11}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true },
        ["Duck-Running"] = { yaw_left = -34, yaw_right = 44, body_left = -28, body_right = 60, delay_mode = "Sequence", delays = {3, 6, 9}, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Adaptive", body_delay = 3, adaptive = true },
        ["Air"] = { yaw_left = -24, yaw_right = 31, body_left = -50, body_right = 60, delay_mode = "Sequence", delays = {2, 5}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true },
        ["Air-Duck"] = { yaw_left = -18, yaw_right = 51, body_left = -26, body_right = 60, delay_mode = "Sequence", delays = {3, 6, 10}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true },
        ["Fake Lag"] = { yaw_left = -36, yaw_right = 42, body_left = -54, body_right = 60, delay_mode = "Sequence", delays = {3, 7, 5}, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Adaptive", body_delay = 3, adaptive = true },
        ["Safe-Head"] = { yaw_left = -20, yaw_right = 24, body_left = -60, body_right = 60, delay_mode = "Sequence", delays = {5, 8}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 5, adaptive = true }
    },
    ["Panchan Pressure"] = {
        ["Stand"] = { yaw_left = -24, yaw_right = 34, body_left = -58, body_right = 60, delay_mode = "Sequence", delays = {3, 5, 8}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true, modifier_mode = "Center", modifier_offset = 5 },
        ["Running"] = { yaw_left = -28, yaw_right = 38, body_left = -56, body_right = 60, delay_mode = "Sequence", delays = {2, 4, 7}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true, modifier_mode = "3-Way", modifier_offset = 5 },
        ["Slow-walk"] = { yaw_left = -31, yaw_right = 42, body_left = -58, body_right = 60, delay_mode = "Sequence", delays = {4, 7, 3, 9}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 5, adaptive = true, modifier_mode = "Center", modifier_offset = 6 },
        ["Duck"] = { yaw_left = -22, yaw_right = 35, body_left = -46, body_right = 60, delay_mode = "Sequence", delays = {3, 6, 9}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true, modifier_mode = "Offset", modifier_offset = 4 },
        ["Duck-Running"] = { yaw_left = -25, yaw_right = 39, body_left = -40, body_right = 60, delay_mode = "Sequence", delays = {2, 5, 8}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true, modifier_mode = "3-Way", modifier_offset = 4 },
        ["Air"] = { yaw_left = -18, yaw_right = 27, body_left = -54, body_right = 58, delay_mode = "Sequence", delays = {2, 4, 6}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true, modifier_mode = "Center", modifier_offset = 3 },
        ["Air-Duck"] = { yaw_left = -16, yaw_right = 36, body_left = -38, body_right = 60, delay_mode = "Sequence", delays = {3, 5, 9}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true, modifier_mode = "Offset", modifier_offset = 4 },
        ["Fake Lag"] = { yaw_left = -27, yaw_right = 38, body_left = -56, body_right = 60, delay_mode = "Sequence", delays = {3, 7, 4}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true, modifier_mode = "3-Way", modifier_offset = 5 },
        ["Safe-Head"] = { yaw_left = -12, yaw_right = 18, body_left = -60, body_right = 60, delay_mode = "Sequence", delays = {5, 8}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 5, adaptive = true, modifier_mode = "Disabled" }
    },
    Meta = {
        ["Stand"] = { original_lr = true, yaw_left = 0, yaw_right = 0, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Running"] = { original_lr = true, yaw_left = -24, yaw_right = 39, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Slow-walk"] = { original_lr = true, yaw_left = -23, yaw_right = 47, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Duck"] = { original_lr = true, yaw_left = -31, yaw_right = 37, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Duck-Running"] = { original_lr = true, yaw_left = -25, yaw_right = 41, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Air"] = { original_lr = true, yaw_left = 0, yaw_right = 0, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" },
        ["Air-Duck"] = { original_lr = true, yaw_left = -19, yaw_right = 37, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled" }
    },
    -- Chimera's Chester inverter branches supply L/R; Panchan Delayed owns the timing.
    ["Chester Panchan"] = {
        ["Stand"] = { original_lr = true, yaw_left = -42, yaw_right = 25, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {5, 8, 4}, body_pattern = "Hold", body_phase = "One phase late", body_delay = 5, adaptive = true, modifier_mode = "Disabled" },
        ["Running"] = { original_lr = true, yaw_left = -32, yaw_right = 37, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 6, 4}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true, modifier_mode = "Disabled" },
        ["Slow-walk"] = { original_lr = true, yaw_left = -26, yaw_right = 44, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {5, 9, 4, 12}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 6, adaptive = true, modifier_mode = "Disabled" },
        ["Duck"] = { original_lr = true, yaw_left = -32, yaw_right = 50, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {4, 7, 10}, body_pattern = "Hold", body_phase = "Independent", body_delay = 5, adaptive = true, modifier_mode = "Disabled" },
        ["Duck-Running"] = { original_lr = true, yaw_left = -27, yaw_right = 33, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 5, 8}, body_pattern = "Hold", body_phase = "Independent", body_delay = 4, adaptive = true, modifier_mode = "Disabled" },
        ["Air"] = { original_lr = true, yaw_left = -28, yaw_right = 46, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {2, 4, 7}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true, modifier_mode = "Disabled" },
        ["Air-Duck"] = { original_lr = true, yaw_left = -24, yaw_right = 42, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 6, 9}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 4, adaptive = true, modifier_mode = "Disabled" },
        ["Fake Lag"] = { original_lr = true, yaw_left = -32, yaw_right = 37, body_left = -60, body_right = 60, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {4, 7, 5}, body_pattern = "Hold", body_phase = "One phase late", body_delay = 4, adaptive = true, modifier_mode = "Disabled" },
        ["Safe-Head"] = { original_lr = true, yaw_left = 0, yaw_right = 0, body_left = 0, body_right = 0, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 0, body_right_limit = 0, delay_mode = "Fixed", delay_fixed = 6, body_pattern = "Hold", body_phase = "Synced", body_delay = 6, modifier_mode = "Disabled" }
    },
    ["Panchan Slowwalk"] = {
        ["Slow-walk"] = { yaw_left = -29, yaw_right = 43, body_left = -58, body_right = 60, delay_mode = "Random Set", delays = {3, 5, 8, 12, 17}, body_pattern = "Hold", body_phase = "Independent", body_delay = 7, adaptive = true, modifier_mode = "Center", modifier_offset = 4 }
    }
}

panchan_delayed_exaint = panchan_delayed_exaint or {
    ["Stand"] = {
        [2] = { yaw_left = -27, yaw_right = 33, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 1 },
        [3] = { yaw_left = -27, yaw_right = 33, body_left = -38, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 1 }
    },
    ["Running"] = {
        [2] = { yaw_left = -32, yaw_right = 38, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 },
        [3] = { yaw_left = -32, yaw_right = 38, body_left = -28, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 }
    },
    ["Slow-walk"] = {
        [2] = { yaw_left = -38, yaw_right = 44, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 15, body_pattern = "Pulse", body_pulse = 6, body_phase = "Independent", body_delay = 9 },
        [3] = { yaw_left = -38, yaw_right = 44, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 15, body_pattern = "Pulse", body_pulse = 6, body_phase = "Independent", body_delay = 9 }
    },
    ["Duck"] = {
        [2] = { yaw_left = -26, yaw_right = 36, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {9, 10, 17, 14, 20, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 },
        [3] = { yaw_left = -30, yaw_right = 43, body_left = -28, body_right = 58, delay_mode = "Random Set", delays = {5, 10, 8, 14, 10, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 }
    },
    ["Duck-Running"] = {
        [2] = { yaw_left = -22, yaw_right = 35, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 6, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 },
        [3] = { yaw_left = -11, yaw_right = 35, body_left = -28, body_right = 58, delay_mode = "Fixed", delay_fixed = 6, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 }
    },
    ["Air"] = {
        [2] = { yaw_left = -25, yaw_right = 27, body_left = -58, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 8 },
        [3] = { yaw_left = 0, yaw_right = 0, body_left = -28, body_right = 58, delay_mode = "Fixed", delay_fixed = 2, body_pattern = "Hold", body_phase = "Independent", body_delay = 14 }
    },
    ["Air-Duck"] = {
        [2] = { yaw_left = -22, yaw_right = 49, body_left = -28, body_right = 58, delay_mode = "Random Set", delays = {6, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 14 },
        [3] = { yaw_left = -16, yaw_right = 40, body_left = -28, body_right = 58, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Independent", body_delay = 1 }
    },
    ["Safe-Head"] = {
        [2] = { yaw_left = 0, yaw_right = 0, body_left = -60, body_right = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 2 },
        [3] = { yaw_left = 0, yaw_right = 0, body_left = -60, body_right = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 2 }
    }
}

panchan_delayed_meta2 = panchan_delayed_meta2 or {
    -- Decoded KnowKarmaIsBack / G$Z0LINA preset, adapted to the Skeet state model.
    ["Stand"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 46, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = 50 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 46, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "5-Way", modifier_offset = 50 }
    },
    ["Running"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -26, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -7, modifier_randomize = true, modifier_random_min = -44, modifier_random_max = 53 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -26, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -7, modifier_randomize = true, modifier_random_min = -44, modifier_random_max = 53 }
    },
    ["Slow-walk"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 38, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 7, 2, 11, 6, 8}, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {-12, 17, -39, -51, 40} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 38, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 7, 2, 11, 6, 8}, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {-12, 17, -39, -51, 40} }
    },
    ["Duck"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -29, yaw_right = 44, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 9, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 3, modifier_values = {0, 0, -11} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -29, yaw_right = 44, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 9, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 3, modifier_values = {0, 0, -11} }
    },
    ["Duck-Running"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -30, yaw_right = 43, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {5, 7, 2}, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 10, body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {-8, 0, 0, 0, 10} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 43, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {6, 7, 2}, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 10, body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {0, 0, 0, 0, 10} }
    },
    ["Air"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = 0, yaw_right = 0, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -13 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = 0, yaw_right = 0, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -13 }
    },
    ["Air-Duck"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 40, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Random Range", delay_min = 6, delay_max = 8, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 11, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_offset = -10, modifier_randomize = true, modifier_random_min = -11, modifier_random_max = 0 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 40, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Random Range", delay_min = 6, delay_max = 8, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 11, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_offset = -10, modifier_randomize = true, modifier_random_min = -11, modifier_random_max = 0 }
    }
}

panchan_delayed_brandog = panchan_delayed_brandog or {
    -- Decoded trillnex / G$Z0LINA preset, adapted to the Skeet state model.
    ["Stand"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 46, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "5-Way", modifier_offset = 50 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 46, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "5-Way", modifier_offset = 50 }
    },
    ["Running"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -26, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 8, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_offset = 0 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_static = true, yaw_offset = 0, yaw_left = -26, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 1, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = 0 }
    },
    ["Slow-walk"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 38, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 7, 2, 11, 6, 8}, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {-12, 17, -39, -51, 40} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 38, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Sequence", delays = {3, 7, 2, 11, 6, 8}, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Bobro", modifier_sequence = true, modifier_count = 5, modifier_values = {-12, 17, -39, -51, 40} }
    },
    ["Duck"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 40, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 9, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 3, modifier_values = {0, 0, -15} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -27, yaw_right = 40, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 9, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 3, modifier_values = {0, 0, -15} }
    },
    ["Duck-Running"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 44, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Sequence", delays = {2, 2}, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 12, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 6, modifier_values = {0, 0, 0, 0, 0, -16} },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 44, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Sequence", delays = {2, 2}, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 12, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_sequence = true, modifier_count = 6, modifier_values = {0, 0, 0, 0, 0, -16} }
    },
    ["Air"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 7, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -13 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 41, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 60, body_right_limit = 60, delay_mode = "Fixed", delay_fixed = 7, delay_divisor = 1.95, body_pattern = "Hold", body_phase = "Synced", body_delay = 1, modifier_mode = "Disabled", modifier_offset = -13 }
    },
    ["Air-Duck"] = {
        [2] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 49, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Random Range", delay_min = 7, delay_max = 8, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 11, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_offset = -10, modifier_randomize = true, modifier_random_min = -11, modifier_random_max = 0 },
        [3] = { source_runtime = "Gazolina", original_lr = true, yaw_left = -22, yaw_right = 49, body_follow_yaw = true, body_limit_mode = "From/To", body_left_limit = 60, body_right_limit = 48, delay_mode = "Random Range", delay_min = 7, delay_max = 8, delay_divisor = 1.95, body_pattern = "Gazolina Ticks", body_pulse = 11, body_phase = "Synced", body_delay = 1, modifier_mode = "Spin", modifier_offset = -10, modifier_randomize = true, modifier_random_min = -11, modifier_random_max = 0 }
    }
}

panchan_delayed_crouch_presets = panchan_delayed_crouch_presets or {
    Exaint = {
        ["Duck"] = panchan_delayed_exaint["Duck"],
        ["Duck-Running"] = panchan_delayed_exaint["Duck-Running"]
    },
    Aggressive = {
        ["Duck"] = {
            [2] = panchan_delayed_presets.Aggressive["Duck"],
            [3] = panchan_delayed_presets.Aggressive["Duck"]
        },
        ["Duck-Running"] = {
            [2] = panchan_delayed_presets.Aggressive["Duck-Running"],
            [3] = panchan_delayed_presets.Aggressive["Duck-Running"]
        }
    },
    Universal = {
        ["Duck"] = {
            [2] = panchan_delayed_presets.Universal["Duck"],
            [3] = panchan_delayed_presets.Universal["Duck"]
        },
        ["Duck-Running"] = {
            [2] = panchan_delayed_presets.Universal["Duck-Running"],
            [3] = panchan_delayed_presets.Universal["Duck-Running"]
        }
    },
    Meta = {
        ["Duck"] = {
            [2] = panchan_delayed_presets.Meta["Duck"],
            [3] = panchan_delayed_presets.Meta["Duck"]
        },
        ["Duck-Running"] = {
            [2] = panchan_delayed_presets.Meta["Duck-Running"],
            [3] = panchan_delayed_presets.Meta["Duck-Running"]
        }
    },
    Meta2 = {
        ["Duck"] = panchan_delayed_meta2["Duck"],
        ["Duck-Running"] = panchan_delayed_meta2["Duck-Running"]
    },
    brandog = {
        ["Duck"] = panchan_delayed_brandog["Duck"],
        ["Duck-Running"] = panchan_delayed_brandog["Duck-Running"]
    },
    ["Chester Panchan"] = {
        ["Duck"] = {
            [2] = panchan_delayed_presets["Chester Panchan"]["Duck"],
            [3] = panchan_delayed_presets["Chester Panchan"]["Duck"]
        },
        ["Duck-Running"] = {
            [2] = panchan_delayed_presets["Chester Panchan"]["Duck-Running"],
            [3] = panchan_delayed_presets["Chester Panchan"]["Duck-Running"]
        }
    },
    Mapsat = {
        ["Duck"] = {
            [2] = { yaw_left = -21, yaw_right = 40, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {3, 7, 2, 13, 5, 8, 5}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 },
            [3] = { yaw_left = -21, yaw_right = 40, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {3, 7, 2, 13, 5, 8, 5}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 }
        },
        ["Duck-Running"] = {
            [2] = { yaw_left = -21, yaw_right = 37, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {5, 1, 9, 4}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 },
            [3] = { yaw_left = -21, yaw_right = 37, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {5, 1, 9, 4}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 }
        }
    },
    Mautlast = {
        ["Duck"] = {
            [2] = { yaw_left = -30, yaw_right = 43, body_left = -28, body_right = 58, delay_mode = "Random Set", delays = {5, 10, 8, 14, 10, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 },
            [3] = { yaw_left = -30, yaw_right = 43, body_left = -28, body_right = 58, delay_mode = "Random Set", delays = {5, 10, 8, 14, 10, 12}, body_pattern = "Hold", body_phase = "Independent", body_delay = 3 }
        },
        ["Duck-Running"] = {
            [2] = { yaw_left = -22, yaw_right = 42, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {5, 5, 1, 1, 15}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 },
            [3] = { yaw_left = -22, yaw_right = 42, body_left = -58, body_right = 58, delay_mode = "Random Set", delays = {4, 8}, body_pattern = "Hold", body_phase = "Independent", body_delay = 2 }
        }
    },
    Adaptive = {
        ["Duck"] = {
            [2] = { yaw_left = -24, yaw_right = 42, body_left = -34, body_right = 60, delay_mode = "Sequence", delays = {3, 7, 2, 11, 5}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true },
            [3] = { yaw_left = -28, yaw_right = 46, body_left = -30, body_right = 60, delay_mode = "Sequence", delays = {3, 6, 2, 10, 5}, body_pattern = "Hold", body_phase = "Adaptive", body_delay = 3, adaptive = true }
        },
        ["Duck-Running"] = {
            [2] = { yaw_left = -19, yaw_right = 39, body_left = -56, body_right = 60, delay_mode = "Sequence", delays = {2, 5, 9, 3}, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Adaptive", body_delay = 2, adaptive = true },
            [3] = { yaw_left = -16, yaw_right = 43, body_left = -28, body_right = 60, delay_mode = "Sequence", delays = {2, 6, 8, 3}, body_pattern = "Random Hold", body_pulse = 5, body_phase = "Adaptive", body_delay = 2, adaptive = true }
        }
    }
}

panchan_delayed_exaint_behavior = panchan_delayed_exaint_behavior or {
    ["Stand"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 58, body_tick_right = 58, modifier_mode = "Offset", modifier_offset = -1 },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 38, body_tick_right = 58, modifier_mode = "Offset", modifier_offset = -1 }
    },
    ["Running"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 58, body_right_limit = 58, body_tick_left = 58, body_tick_right = 58, modifier_mode = "3-Way", modifier_offset = 10 },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 58, body_right_limit = 58, body_tick_left = 28, body_tick_right = 58, modifier_mode = "Disabled", modifier_offset = 1 }
    },
    ["Slow-walk"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 58, body_right_limit = 58, body_tick_left = 58, body_tick_right = 58, body_pattern = "Ticks", body_pulse = 6, modifier_mode = "3-Way", modifier_offset = 1, modifier_randomize = true, modifier_count = 2, modifier_values = {2, 27} },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 58, body_right_limit = 58, body_tick_left = 58, body_tick_right = 58, body_pattern = "Ticks", body_pulse = 6, modifier_mode = "3-Way", modifier_offset = 1, modifier_randomize = true, modifier_count = 2, modifier_values = {2, 27} }
    },
    ["Duck"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 58, body_tick_right = 58, modifier_mode = "5-Way", modifier_offset = 10 },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 28, body_tick_right = 58, modifier_mode = "5-Way", modifier_offset = 10 }
    },
    ["Duck-Running"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 58, body_tick_right = 58, modifier_mode = "Spin", modifier_offset = 5 },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 28, body_tick_right = 58, modifier_mode = "Spin", modifier_offset = 5 }
    },
    ["Air"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 58, body_tick_right = 58, modifier_mode = "3-Way", modifier_offset = 10 },
        [3] = { source_runtime = "Nyanza", original_lr = true, yaw_static = true, yaw_offset = 0, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 28, body_tick_right = 58, modifier_mode = "Disabled", modifier_offset = -1 }
    },
    ["Air-Duck"] = {
        [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 28, body_tick_right = 58, modifier_mode = "5-Way", modifier_offset = -6 },
        [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 60, body_right_limit = 60, body_tick_left = 28, body_tick_right = 58, modifier_mode = "Disabled", modifier_offset = 0 }
    }
}

panchan_delayed_crouch_behavior = panchan_delayed_crouch_behavior or {
    Exaint = {
        ["Duck"] = panchan_delayed_exaint_behavior["Duck"],
        ["Duck-Running"] = panchan_delayed_exaint_behavior["Duck-Running"]
    },
    Mapsat = {
        ["Duck"] = {
            [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "Spin", modifier_randomize = true, modifier_count = 8, modifier_values = {0, 0, 0, 0, 0, 0, 0, -19} },
            [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "Spin", modifier_randomize = true, modifier_count = 8, modifier_values = {0, 0, 0, 0, 0, 0, 0, -19} }
        },
        ["Duck-Running"] = {
            [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "Spin", modifier_randomize = true, modifier_count = 6, modifier_values = {0, 0, 0, 0, 0, -19} },
            [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "Spin", modifier_randomize = true, modifier_count = 6, modifier_values = {0, 0, 0, 0, 0, -19} }
        }
    },
    Mautlast = {
        ["Duck"] = {
            [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 28, body_tick_right = 58, modifier_mode = "5-Way", modifier_offset = 10 },
            [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Ticks", body_left_limit = 59, body_right_limit = 59, body_tick_left = 28, body_tick_right = 58, modifier_mode = "5-Way", modifier_offset = 10 }
        },
        ["Duck-Running"] = {
            [2] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "3-Way", modifier_randomize = true, modifier_count = 3, modifier_values = {16, 5, 5} },
            [3] = { source_runtime = "Nyanza", original_lr = true, body_follow_yaw = true, body_limit_mode = "Static", body_left_limit = 58, body_right_limit = 58, modifier_mode = "3-Way", modifier_randomize = true, modifier_count = 3, modifier_values = {16, 5, 5} }
        }
    }
}

panchan_delayed_preset_behavior = panchan_delayed_preset_behavior or {
    Panchan = {
        ["Air-Duck"] = {
            source_runtime = "Gaza",
            original_lr = true,
            delay_divisor = 1.95,
            body_follow_yaw = true,
            body_limit_mode = "Static",
            body_left_limit = 60,
            body_right_limit = 60,
            modifier_mode = "Bobro",
            modifier_randomize = true,
            modifier_random_min = -11,
            modifier_random_max = 20
        }
    }
}

panchan_delayed_runtime = panchan_delayed_runtime or {}

function panchan_delayed_state_key(condition, source)
    if source[condition] ~= nil then
        return condition
    end

    if condition == "Global" then
        return "Stand"
    elseif condition == "Fake Lag" then
        return source["Fake Lag"] ~= nil and "Fake Lag" or "Running"
    elseif condition == "Safe-Head" then
        return source["Safe-Head"] ~= nil and "Safe-Head" or "Stand"
    end

    return source["Stand"] ~= nil and "Stand" or condition
end

function panchan_delayed_team()
    local lp = sdk.get_lp()
    local team = lp and entity.get_prop(lp, "m_iTeamNum") or 2
    return team == 3 and 3 or 2
end

function panchan_delayed_team_preset(delayed_settings, team, crouch)
    local side = team == 3 and "CT Side" or "T Side"
    return panchan_delayed_virtual_side_preset(delayed_settings, side, crouch)
end

function panchan_delayed_custom_profile(settings)
    local delays = {}

    for delayed_index = 1, 8 do
        delays[delayed_index] = settings["panchan_delayed_delay_" .. delayed_index]
    end

    return {
        yaw_left = settings.panchan_delayed_yaw_left,
        yaw_right = settings.panchan_delayed_yaw_right,
        body_left = settings.panchan_delayed_body_left,
        body_right = settings.panchan_delayed_body_right,
        delay_mode = settings.panchan_delayed_delay_mode,
        delay_fixed = settings.panchan_delayed_delay_fixed,
        delay_min = settings.panchan_delayed_delay_from,
        delay_max = settings.panchan_delayed_delay_to,
        delays = delays,
        delay_count = settings.panchan_delayed_sequence_count,
        body_pattern = settings.panchan_delayed_body_pattern,
        body_pulse = settings.panchan_delayed_body_pulse,
        body_phase = settings.panchan_delayed_body_phase,
        body_delay = settings.panchan_delayed_body_delay
    }
end

function panchan_delayed_merge_behavior(profile, behavior)
    if profile == nil or behavior == nil then
        return profile
    end

    local merged = {}
    for key, value in pairs(profile) do
        merged[key] = value
    end
    for key, value in pairs(behavior) do
        merged[key] = value
    end
    return merged
end

function panchan_delayed_profile(settings, condition)
    local state_name = panchan_delayed_settings_state[settings] or condition or "Global"
    local delayed_settings = panchan_delayed_virtual_state(state_name)
    local team = panchan_delayed_team()
    local preset = panchan_delayed_team_preset(delayed_settings, team, false)
    local crouch_preset = panchan_delayed_team_preset(delayed_settings, team, true)

    if preset == "Panchan Slowwalk" and condition ~= "Slow-walk" then
        preset = "Panchan"
    end

    if (condition == "Duck" or condition == "Duck-Running") and crouch_preset ~= "Off" then
        local source = panchan_delayed_crouch_presets[crouch_preset]
        local state_profile = source and source[condition]

        if state_profile ~= nil then
            local profile = state_profile[team] or state_profile[2]
            local behavior_source = panchan_delayed_crouch_behavior[crouch_preset]
            local behavior_state = behavior_source and behavior_source[condition]
            local behavior = behavior_state and (behavior_state[team] or behavior_state[2])
            return panchan_delayed_merge_behavior(profile, behavior), "CrouchFlow:" .. crouch_preset .. ":" .. condition .. ":" .. team .. ":" .. tostring(settings)
        end
    end

    if preset == "Custom" then
        local profile = panchan_delayed_custom_profile(delayed_settings)
        local signature = table.concat({"Custom", tostring(condition), tostring(team), tostring(settings), profile.delay_mode, profile.body_pattern, profile.body_phase}, ":")
        return profile, signature
    end

    if preset == "Exaint" then
        local state_key = panchan_delayed_state_key(condition, panchan_delayed_exaint)
        local state_profile = panchan_delayed_exaint[state_key] or panchan_delayed_exaint["Stand"]
        local profile = state_profile[team] or state_profile[2]
        local behavior_state = panchan_delayed_exaint_behavior[state_key]
        local behavior = behavior_state and (behavior_state[team] or behavior_state[2])
        return panchan_delayed_merge_behavior(profile, behavior), "Exaint:" .. state_key .. ":" .. team .. ":" .. tostring(settings)
    end

    if preset == "Meta2" then
        local state_key = panchan_delayed_state_key(condition, panchan_delayed_meta2)
        local state_profile = panchan_delayed_meta2[state_key] or panchan_delayed_meta2["Stand"]
        local profile = state_profile[team] or state_profile[2]
        return profile, "Meta2:" .. state_key .. ":" .. team .. ":" .. tostring(settings)
    end

    if preset == "brandog" then
        local state_key = panchan_delayed_state_key(condition, panchan_delayed_brandog)
        local state_profile = panchan_delayed_brandog[state_key] or panchan_delayed_brandog["Stand"]
        local profile = state_profile[team] or state_profile[2]
        return profile, "brandog:" .. state_key .. ":" .. team .. ":" .. tostring(settings)
    end

    local source = panchan_delayed_presets[preset] or panchan_delayed_presets.Panchan
    local state_key = panchan_delayed_state_key(condition, source)
    local profile = source[state_key] or source["Stand"]
    local behavior_source = panchan_delayed_preset_behavior[preset]
    local behavior = behavior_source and behavior_source[state_key]
    return panchan_delayed_merge_behavior(profile, behavior), preset .. ":" .. state_key .. ":" .. team .. ":" .. tostring(settings)
end

function panchan_delayed_reset_runtime(runtime, signature)
    runtime.signature = signature
    runtime.phase = false
    runtime.previous_phase = false
    runtime.body_phase = false
    runtime.body_enabled = true
    runtime.phase_ticks = 0
    runtime.phase_target = nil
    runtime.body_ticks = 0
    runtime.body_target = nil
    runtime.pattern_ticks = 0
    runtime.pattern_target = nil
    runtime.sequence_index = 0
    runtime.phase_cycle = 0
    runtime.modifier_step = 0
    runtime.modifier_value = 0
    runtime.modifier_sequence_index = 1
    runtime.modifier_sequence_ticks = 0
    runtime.modifier_spin = 0
    runtime.yaw_left = nil
    runtime.yaw_right = nil
    runtime.xo_packet_phase = false
    runtime.xo_delay_phase = false
    runtime.bobro_step = 1
    runtime.gazolina_body_initialized = false
    runtime.gazolina_body_ticks = 0
    runtime.last_command = -1
    runtime.last_tick = nil
    runtime.anti_brute_generation = -1
end

function panchan_delayed_get_runtime(condition, signature)
    local key = condition or "Global"
    local runtime = panchan_delayed_runtime[key]

    if runtime == nil then
        runtime = {}
        panchan_delayed_runtime[key] = runtime
    end

    if runtime.signature ~= signature then
        panchan_delayed_reset_runtime(runtime, signature)
    end

    return runtime
end

function panchan_delayed_pick_delay(profile, runtime)
    local mode = profile.delay_mode or "Fixed"
    local value = profile.delay_fixed or 4
    local delay_count = profile.delay_count or (profile.delays and #profile.delays or 0)

    if mode == "Random Range" then
        local from = clamp(profile.delay_min or 2, 1, 22)
        local to = clamp(profile.delay_max or from, 1, 22)

        if from > to then
            from, to = to, from
        end

        value = random_between(from, to)
    elseif (mode == "Sequence" or mode == "Random Set") and delay_count > 0 then
        if mode == "Random Set" then
            value = profile.delays[random_between(1, delay_count)] or value
        else
            runtime.sequence_index = ((runtime.sequence_index or 0) % delay_count) + 1
            value = profile.delays[runtime.sequence_index] or value
        end
    end

    if profile.adaptive then
        local lp = sdk.get_lp()
        local speed = lp and sdk.get_velocity(lp) or 0

        if client.current_threat() ~= nil then
            value = value - 1
        elseif speed < 5 then
            value = value + 1
        end

        if player.get_dt() then
            value = value - 1
        end
    end

    if profile.delay_divisor and profile.delay_divisor > 0 then
        value = math.ceil(value / profile.delay_divisor)
    end

    return clamp(math.floor(value or 1), 1, 22)
end

function panchan_delayed_pick_body_delay(profile)
    local value = profile.body_delay or 4

    if profile.adaptive then
        if client.current_threat() ~= nil then
            value = value - 1
        elseif not player.get_dt() then
            value = value + 1
        end
    end

    return clamp(math.floor(value or 1), 1, 22)
end

function panchan_delayed_frozen(cmd)
    if ui.get(ref.fd) then
        return true
    end

    return cmd.in_attack == true or cmd.in_attack == 1 or cmd.in_attack2 == true or cmd.in_attack2 == 1 or cmd.in_use == true or cmd.in_use == 1
end

function panchan_delayed_sample_modifier(runtime, profile, advance_sequence)
    runtime.modifier_step = (runtime.modifier_step or 0) + 1
    runtime.modifier_value = profile.modifier_offset or 0

    if profile.modifier_sequence then
        local values = profile.modifier_values
        local count = math.min(profile.modifier_count or (values and #values or 0), values and #values or 0)

        if values and count > 0 then
            local index = clamp(runtime.modifier_sequence_index or 1, 1, count)
            local hold = math.max(values[index] or 0, 1)
            if advance_sequence ~= false then
                runtime.modifier_sequence_ticks = (runtime.modifier_sequence_ticks or 0) + 1

                if runtime.modifier_sequence_ticks >= hold then
                    runtime.modifier_sequence_ticks = 0
                    index = (index % count) + 1
                end
            end

            runtime.modifier_sequence_index = index
            runtime.modifier_value = values[index] or 0
        end
    elseif profile.modifier_randomize then
        local values = profile.modifier_values
        local count = math.min(profile.modifier_count or (values and #values or 0), values and #values or 0)

        if values and count > 0 then
            runtime.modifier_value = values[random_between(1, count)] or 0
        else
            runtime.modifier_value = random_between(profile.modifier_random_min or 0, profile.modifier_random_max or 0)
        end
    elseif profile.modifier_mode == "Random" then
        local range = math.abs(profile.modifier_offset or 0)
        runtime.modifier_value = random_between(-range, range)
    end
end

function panchan_delayed_sample_yaw(runtime, profile)
    runtime.yaw_left = profile.yaw_left
    runtime.yaw_right = profile.yaw_right

    if profile.yaw_left_min ~= nil and profile.yaw_left_max ~= nil then
        runtime.yaw_left = random_between(profile.yaw_left_min, profile.yaw_left_max)
    end
    if profile.yaw_right_min ~= nil and profile.yaw_right_max ~= nil then
        runtime.yaw_right = random_between(profile.yaw_right_min, profile.yaw_right_max)
    end
end

function panchan_delayed_update_runtime(runtime, profile, cmd)
    local command_number = cmd.command_number or globals.tickcount()

    if runtime.last_command == command_number then
        return
    end

    runtime.last_command = command_number

    local tick = globals.tickcount()
    if runtime.last_tick ~= nil and (tick < runtime.last_tick or tick - runtime.last_tick > 128) then
        local signature = runtime.signature
        panchan_delayed_reset_runtime(runtime, signature)
        runtime.last_command = command_number
    end
    runtime.last_tick = tick
    anti_brute_sync_delayed_runtime(runtime, cmd)

    if panchan_delayed_frozen(cmd) then
        return
    end

    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local source_runtime = profile.source_runtime
    local source_command_runtime = source_runtime == "Nyanza" or source_runtime == "Gaza" or source_runtime == "XO-Yaw" or source_runtime == "Gazolina"

    if profile.body_pattern == "Gazolina Ticks" then
        local body_ticks = clamp(profile.body_pulse or 6, 4, 16)

        if not runtime.gazolina_body_initialized then
            runtime.body_enabled = false
            runtime.gazolina_body_ticks = 0
            runtime.gazolina_body_initialized = true
        end

        if tick % body_ticks == 0 then
            runtime.body_enabled = not runtime.body_enabled
            runtime.gazolina_body_ticks = 0
        end

        if not runtime.body_enabled then
            runtime.gazolina_body_ticks = (runtime.gazolina_body_ticks or 0) + 1
            if runtime.gazolina_body_ticks >= random_between(2, 6) then
                runtime.body_enabled = true
                runtime.gazolina_body_ticks = 0
            end
        end
    elseif profile.body_pattern == "Ticks" then
        local body_ticks = clamp(profile.body_pulse or 6, 2, 22)
        runtime.body_enabled = not (tick % body_ticks <= 1)
    end

    if source_command_runtime then
        panchan_delayed_sample_modifier(runtime, profile, source_runtime ~= "Gazolina" or choked == 0)

        if source_runtime == "Nyanza" and profile.delay_mode == "Random Set" then
            runtime.phase_target = anti_brute_adjust_delay(panchan_delayed_pick_delay(profile, runtime), cmd)
        elseif source_runtime == "XO-Yaw" then
            panchan_delayed_sample_yaw(runtime, profile)
            runtime.phase_target = player.get_dt() and panchan_delayed_pick_delay(profile, runtime) or 1
        end
    end

    if choked ~= 0 then
        return
    end

    if not source_command_runtime then
        panchan_delayed_sample_modifier(runtime, profile)
    end

    if source_runtime == "XO-Yaw" then
        local old_phase = runtime.phase

        if player.get_dt() then
            runtime.phase_ticks = (runtime.phase_ticks or 0) + 1
            if runtime.phase_ticks >= (runtime.phase_target or 1) then
                runtime.xo_delay_phase = not (runtime.xo_delay_phase or false)
                runtime.phase_ticks = 0
                runtime.phase_cycle = (runtime.phase_cycle or 0) + 1
            end
            runtime.phase = runtime.xo_delay_phase or false
        else
            runtime.xo_packet_phase = not (runtime.xo_packet_phase or false)
            runtime.phase = runtime.xo_packet_phase
            runtime.phase_ticks = 0
            runtime.phase_cycle = (runtime.phase_cycle or 0) + 1
        end

        runtime.previous_phase = old_phase
        runtime.body_phase = runtime.phase
        runtime.body_enabled = true
        return
    end

    if profile.modifier_mode == "Bobro" then
        runtime.bobro_step = (runtime.bobro_step or 1) + 1
        if runtime.bobro_step >= 7 then
            runtime.bobro_step = 1
        end
    end

    if source_runtime == "Gaza" and profile.delay_mode == "Random Range" then
        runtime.phase_target = anti_brute_adjust_delay(panchan_delayed_pick_delay(profile, runtime), cmd)
    end

    if runtime.phase_target == nil then
        runtime.phase_target = panchan_delayed_pick_delay(profile, runtime)
    end
    if runtime.body_target == nil then
        runtime.body_target = panchan_delayed_pick_body_delay(profile)
    end
    if runtime.pattern_target == nil then
        runtime.pattern_target = clamp(profile.body_pulse or 6, 2, 22)
    end

    runtime.phase_ticks = (runtime.phase_ticks or 0) + 1
    runtime.body_ticks = (runtime.body_ticks or 0) + 1
    runtime.pattern_ticks = (runtime.pattern_ticks or 0) + 1

    if runtime.phase_ticks >= runtime.phase_target then
        local old_phase = runtime.phase
        runtime.previous_phase = old_phase
        runtime.phase = not old_phase
        runtime.phase_ticks = 0
        runtime.phase_cycle = (runtime.phase_cycle or 0) + 1
        runtime.phase_target = panchan_delayed_pick_delay(profile, runtime)

        if profile.body_phase == "Synced" then
            runtime.body_phase = runtime.phase
        elseif profile.body_phase == "One phase late" then
            runtime.body_phase = old_phase
        elseif profile.body_phase == "Adaptive" then
            runtime.body_phase = runtime.phase_cycle % 3 == 0 and old_phase or runtime.phase
        end
    end

    if profile.body_phase == "Independent" and runtime.body_ticks >= runtime.body_target then
        runtime.body_phase = not runtime.body_phase
        runtime.body_ticks = 0
        runtime.body_target = panchan_delayed_pick_body_delay(profile)
    end

    if profile.body_pattern == "Ticks" or profile.body_pattern == "Gazolina Ticks" then
        -- Source-specific tick patterns already update body_enabled before packet gating.
    elseif profile.body_pattern == "Pulse" then
        if runtime.pattern_ticks >= runtime.pattern_target then
            runtime.pattern_ticks = 0
            runtime.body_enabled = false
        else
            runtime.body_enabled = true
        end
    elseif profile.body_pattern == "Random Hold" then
        if runtime.pattern_ticks >= runtime.pattern_target then
            runtime.pattern_ticks = 0
            runtime.body_enabled = not runtime.body_enabled
            runtime.pattern_target = random_between(2, clamp(profile.body_pulse or 6, 2, 22))
        end
    else
        runtime.body_enabled = true
    end
end

function panchan_delayed_modifier_value(profile, runtime)
    local mode = profile.modifier_mode or "Disabled"
    local value = runtime.modifier_value or profile.modifier_offset or 0
    local step = math.max(runtime.modifier_step or 1, 1)

    if mode == "Bobro" then
        local bobro_values = {-value, -value / 2, -value / 3, value / 3, value / 2, value}
        value = bobro_values[runtime.bobro_step or 1] or value
        mode = "3-Way"
    end

    if mode == "Disabled" then
        value = 0
    elseif mode == "Offset" then
        value = runtime.phase and value or 0
    elseif mode == "Center" then
        value = runtime.phase and value or -value
    elseif mode == "3-Way" then
        local values = {-value, 0, value}
        value = values[((step - 1) % 3) + 1]
    elseif mode == "5-Way" then
        local values = {-value, -value / 2, 0, value / 2, value}
        value = values[((step - 1) % 5) + 1]
    elseif mode == "Spin" then
        local range = math.abs(value)
        if range > 0 then
            value = -range + ((step - 1) % (range * 2 + 1))
        else
            value = 0
        end
    end

    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function panchan_delayed_body_value(profile, runtime)
    if not profile.body_follow_yaw then
        return runtime.body_phase and profile.body_right or profile.body_left
    end

    local magnitude = 0
    if profile.body_limit_mode == "Ticks" then
        magnitude = runtime.body_phase and profile.body_tick_left or profile.body_tick_right
    elseif profile.body_limit_mode == "Random" then
        magnitude = random_between(profile.body_limit_min or 0, profile.body_limit_max or 60)
    else
        magnitude = runtime.phase and profile.body_left_limit or profile.body_right_limit
    end

    magnitude = math.abs(magnitude or 0)
    return runtime.phase and -magnitude or magnitude
end

function apply_panchan_delayed_body_yaw(cmd, settings, condition, preserve_yaw)
    local profile, signature = panchan_delayed_profile(settings, condition)
    local runtime = panchan_delayed_get_runtime(condition, signature)
    panchan_delayed_update_runtime(runtime, profile, cmd)

    local yaw_left = runtime.yaw_left or profile.yaw_left
    local yaw_right = runtime.yaw_right or profile.yaw_right
    local yaw = runtime.phase and yaw_right or yaw_left
    if profile.original_lr then
        yaw = runtime.phase and yaw_left or yaw_right
    end
    if profile.yaw_static then
        yaw = profile.yaw_offset or 0
    end

    local body = panchan_delayed_body_value(profile, runtime)
    local modifier = panchan_delayed_modifier_value(profile, runtime)
    yaw = clamp((yaw or 0) + modifier, -180, 180)
    body = clamp(anti_brute_adjust_body(body or 0, cmd), -60, 60)

    if not preserve_yaw then
        ui.set(ref.yaw[2], yaw)
        ui.set(ref.yaw_jitter[1], "Off")
        ui.set(ref.yaw_jitter[2], 0)
    end

    ui.set(ref.freestanding_body_yaw, false)

    if runtime.body_enabled or panchan_delayed_frozen(cmd) then
        ui.set(ref.body_yaw[1], "Static")
        ui.set(ref.body_yaw[2], body)
    else
        ui.set(ref.body_yaw[1], "Off")
    end

    return yaw
end

panchan_mode_v2_runtime = panchan_mode_v2_runtime or {
    side = 1,
    phase_ticks = 0,
    phase_limit = 3,
    last_command = -1,
    body_limit = 58,
    yaw_noise = 0,
    packet_flip = false
}

function panchan_mode_v2_reset_runtime()
    local rt = panchan_mode_v2_runtime
    rt.side = 1
    rt.phase_ticks = 0
    rt.phase_limit = 3
    rt.last_command = -1
    rt.body_limit = 58
    rt.yaw_noise = 0
    rt.packet_flip = false
    rt.anti_brute_generation = -1
end

function panchan_mode_v2_is_air()
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then
        return false
    end

    local flags = entity.get_prop(lp, "m_fFlags") or 0
    return bit ~= nil and bit.band ~= nil and bit.band(flags, 1) == 0 or flags % 2 == 0
end

function panchan_mode_v2_auto_limit(settings)
    local wanted_offset = settings and settings.panchan_v2_body_yaw_offset and ui.get(settings.panchan_v2_body_yaw_offset) or 0
    local sign = wanted_offset < 0 and -1 or 1
    local limit = math.abs(wanted_offset)

    if limit > 0 then
        return clamp(limit, 1, 60), sign
    end

    local lp = sdk.get_lp()
    local speed = lp and sdk.get_velocity(lp) or 0
    local threat = client.current_threat()

    if ui.get(ref.fd) then
        limit = 54
    elseif panchan_mode_v2_is_air() then
        limit = 56
    elseif speed > 150 then
        limit = 60
    elseif speed > 5 then
        limit = 58
    else
        limit = 57
    end

    if threat ~= nil then
        limit = limit + 1
    end

    return clamp(limit, 1, 60), sign
end

function panchan_mode_v2_next_phase_limit(side)
    local limit = side > 0 and 3 or 4

    if player.get_dt() then
        limit = limit - 1
    end

    local lp = sdk.get_lp()
    local speed = lp and sdk.get_velocity(lp) or 0

    if speed > 150 then
        limit = limit + (side > 0 and 0 or 1)
    end

    return clamp(limit, 1, 6)
end

function panchan_mode_v2_update_phase(cmd, settings)
    local rt = panchan_mode_v2_runtime
    local command_number = cmd.command_number or globals.tickcount()

    if rt.last_command == command_number then
        return
    end

    rt.last_command = command_number

    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    if choked ~= 0 then
        return
    end

    rt.phase_ticks = (rt.phase_ticks or 0) + 1

    if rt.phase_ticks < (rt.phase_limit or 3) then
        return
    end

    rt.phase_ticks = 0
    rt.side = -(rt.side or 1)
    rt.phase_limit = panchan_mode_v2_next_phase_limit(rt.side)
    rt.packet_flip = not (rt.packet_flip or false)

    local limit = panchan_mode_v2_auto_limit(settings)
    local spread = player.get_dt() and 2 or 1
    rt.body_limit = clamp(limit + random_between(-spread, spread), 1, 60)
    rt.yaw_noise = random_between(-4, 4)
end

function apply_panchan_mode_v2_body_yaw(cmd, settings, current_state, yaw_base)
    local rt = panchan_mode_v2_runtime

    anti_brute_sync_panchan_v2(rt, cmd)
    panchan_mode_v2_update_phase(cmd, settings)

    local limit, base_side = panchan_mode_v2_auto_limit(settings)
    local active_limit = rt.body_limit or limit
    local body_value = clamp(anti_brute_adjust_body(active_limit * base_side * (rt.side or 1), cmd), -60, 60)
    yaw_base = yaw_base or 0

    ui.set(ref.body_yaw[1], "Static")
    ui.set(ref.freestanding_body_yaw, false)

    local choked = get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)
    local yaw_correction = clamp(normalize_yaw(-(body_value + yaw_base) + (rt.yaw_noise or 0)), -180, 180)

    if player.get_dt() then
        ui.set(ref.body_yaw[2], 0)

        if choked == 0 then
            if rt.packet_flip ~= false then
                cmd.allow_send_packet = false
            end

            ui.set(ref.yaw[2], yaw_correction)
        end
    else
        ui.set(ref.body_yaw[2], body_value)
    end
end

panchan_fakelag_runtime = {
    choked = 0,
    target_ticks = nil,
    condition = nil,
    variance = 0,
    saved = nil,
    active = false,
    owner = nil
}

duck_on_fd_state = {
    saved = nil,
    active = false
}

duck_on_fd_hotkey_mode = {
    [0] = "Always on",
    [1] = "On hotkey",
    [2] = "Toggle",
    [3] = "Off hotkey"
}

duck_on_fd_save_value = function(item)
    local values = { ui.get(item) }
    local ok, item_type = pcall(ui.type, item)

    if ok and item_type == "hotkey" then
        return { duck_on_fd_hotkey_mode[values[2]] or "On hotkey", values[3] or 0 }
    end

    return values
end

duck_on_fd_unset = function()
    if duck_on_fd_state.saved == nil then
        return
    end

    pcall(ui.set, ref.fd, unpack(duck_on_fd_state.saved))
    duck_on_fd_state.saved = nil
    duck_on_fd_state.active = false
end

duck_on_fd_set = function()
    duck_on_fd_state.active = true
end

duck_on_fd_apply = function(cmd)
    duck_on_fd_unset()

    if not ui.get(duck_on_fd) then
        return
    end

    if ref.fd == nil or not ui.get(ref.fd) then
        return
    end

    cmd.in_duck = 1
end

fake_duck_freezetime_state = {
    cnt = 0,
    ready = false,
    saved_dt = nil,
    saved_hs = nil
}

fake_duck_get_freeze_period = function()
    local rules
    local ok = pcall(function()
        rules = entity.get_game_rules and entity.get_game_rules()
    end)

    if ok and rules ~= nil then
        local ok_prop, freeze = pcall(entity.get_prop, rules, "m_bFreezePeriod")
        if ok_prop then
            return freeze == 1 or freeze == true
        end
    end

    local proxies
    ok = pcall(function()
        proxies = entity.get_all and entity.get_all("CCSGameRulesProxy")
    end)

    if ok and proxies and proxies[1] then
        local ok_prop, freeze = pcall(entity.get_prop, proxies[1], "m_bFreezePeriod")
        if ok_prop then
            return freeze == 1 or freeze == true
        end
    end

    return false
end

fake_duck_freezetime_disable_exploits = function()
    if fake_duck_freezetime_state.saved_dt == nil and ref.dt and ref.dt[1] then
        local ok, value = pcall(ui.get, ref.dt[1])
        if ok then
            fake_duck_freezetime_state.saved_dt = value
            pcall(ui.set, ref.dt[1], false)
        end
    end

    if fake_duck_freezetime_state.saved_hs == nil and ref.hs and ref.hs[1] then
        local ok, value = pcall(ui.get, ref.hs[1])
        if ok then
            fake_duck_freezetime_state.saved_hs = value
            pcall(ui.set, ref.hs[1], false)
        end
    end
end

fake_duck_freezetime_restore = function()
    if fake_duck_freezetime_state.saved_dt ~= nil and ref.dt and ref.dt[1] then
        pcall(ui.set, ref.dt[1], fake_duck_freezetime_state.saved_dt)
    end

    if fake_duck_freezetime_state.saved_hs ~= nil and ref.hs and ref.hs[1] then
        pcall(ui.set, ref.hs[1], fake_duck_freezetime_state.saved_hs)
    end

    fake_duck_freezetime_state.saved_dt = nil
    fake_duck_freezetime_state.saved_hs = nil
    fake_duck_freezetime_state.ready = false
    fake_duck_freezetime_state.cnt = 0
end

fake_duck_freezetime_apply = function(cmd)
    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        fake_duck_freezetime_restore()
        return false
    end

    if not ui.get(fake_duck_freezetime) or not ui.get(ref.fd) or not fake_duck_get_freeze_period() then
        fake_duck_freezetime_restore()
        return false
    end

    local me = entity.get_local_player()
    if me == nil or not entity.is_alive(me) then
        fake_duck_freezetime_restore()
        return false
    end

    fake_duck_freezetime_disable_exploits()

    local tick = fake_duck_freezetime_state.cnt % 14
    cmd.allow_send_packet = false

    if tick == 0 then
        fake_duck_freezetime_state.ready = true
    elseif tick == 6 then
        cmd.allow_send_packet = true
    elseif tick == 7 then
        fake_duck_freezetime_state.ready = false
    end

    cmd.in_duck = fake_duck_freezetime_state.ready and 1 or 0
    fake_duck_freezetime_state.cnt = fake_duck_freezetime_state.cnt + 1
    return true
end

fake_duck_unspeed_apply = function(cmd)
    if not ui.get(fake_duck_unspeed) or not ui.get(ref.fd) then
        return
    end

    local me = entity.get_local_player()
    if me == nil or not entity.is_alive(me) then
        return
    end

    local vx, vy = entity.get_prop(me, "m_vecVelocity")
    if math.abs(vx or 0) <= 10 and math.abs(vy or 0) <= 10 then
        return
    end

    local forward = cmd.forwardmove or 0
    local side = cmd.sidemove or 0
    local length = math.sqrt(forward * forward + side * side)

    if length <= 0 then
        return
    end

    local scale = ui.get(fake_duck_unspeed_scale)
    cmd.forwardmove = (forward / length) * scale
    cmd.sidemove = (side / length) * scale
end

function set_builtin_fake_lag(ticks, process_ticks_override)
    local target_ticks = clamp(ticks, 1, 24)
    local max_process_ticks = tonumber(process_ticks_override) or (target_ticks + 1)
    max_process_ticks = clamp(math.floor(max_process_ticks), 2, 25)

    -- Aesthetic keeps the old 14 choke edge on a 16 command window.
    if max_process_ticks == 15 then
        max_process_ticks = 16
    end

    pcall(ui.set, ref.falelag_enabled[1], true)
    pcall(ui.set, ref.fakelag_amount, "Maximum")
    pcall(ui.set, ref.variability, 0)
    pcall(ui.set, ref.fakelag_limit, clamp(target_ticks, 1, 14))

    if ref.max_process_ticks ~= nil then
        pcall(ui.set, ref.max_process_ticks, max_process_ticks)
    end

    if cvar and cvar.sv_maxusrcmdprocessticks then
        pcall(function()
            cvar.sv_maxusrcmdprocessticks:set_int(max_process_ticks)
        end)
    end
end

function get_cmd_choke(cmd)
    return cmd.chokedcommands or globals.chokedcommands() or 0
end

function panchan_fake_lag_roll_ticks(ticks, variance)
    ticks = clamp(tonumber(ticks) or 1, 1, 24)
    variance = clamp(tonumber(variance) or 0, 0, 100)

    if variance <= 0 then
        return ticks
    end

    local spread = math.max(1, math.floor((ticks * variance / 100) + 0.5))
    local minimum = clamp(ticks - spread, 1, 24)
    local maximum = clamp(ticks + spread, 1, 24)

    return random_between(minimum, maximum)
end

function panchan_fake_lag_exploit_locked()
    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        return true
    end

    local dt_enabled = ref.dt and ref.dt[1] and ref.dt[2] and ui.get(ref.dt[1]) and ui.get(ref.dt[2])
    local hs_enabled = ref.hs and ref.hs[1] and ref.hs[2] and ui.get(ref.hs[1]) and ui.get(ref.hs[2])
    local exploit_key_active = (dt_enabled or hs_enabled) and not ui.get(ref.fd)

    return panchan_fake_lag_disable_on_exploit ~= nil
        and ui.get(panchan_fake_lag_disable_on_exploit)
        and exploit_key_active
end

function panchan_fake_lag_get_settings()
    local ticks = panchan_fake_lag_ticks and ui.get(panchan_fake_lag_ticks) or 1
    local variance = panchan_fake_lag_variance and ui.get(panchan_fake_lag_variance) or 0

    return clamp(ticks, 1, 24), clamp(variance, 0, 100), "Panchan Fake Lag"
end

function panchan_fake_lag_reset_runtime()
    panchan_fakelag_runtime.choked = 0
    panchan_fakelag_runtime.target_ticks = nil
    panchan_fakelag_runtime.condition = nil
    panchan_fakelag_runtime.variance = 0
end

function panchan_fake_lag_save()
    if panchan_fakelag_runtime.saved ~= nil then
        return
    end

    local saved = {items = {}, process_ticks = 16}
    local function save(ref_item)
        if ref_item == nil then
            return
        end

        local ok, value = pcall(ui.get, ref_item)
        if ok then
            saved.items[#saved.items + 1] = {ref = ref_item, value = value}
        end
    end

    save(ref.falelag_enabled and ref.falelag_enabled[1])
    save(ref.fakelag_amount)
    save(ref.fakelag_limit)
    save(ref.variability)
    save(ref.max_process_ticks)

    if cvar and cvar.sv_maxusrcmdprocessticks then
        local ok, value = pcall(function()
            return cvar.sv_maxusrcmdprocessticks:get_int()
        end)
        if ok and value ~= nil then
            saved.process_ticks = value
        end
    end

    panchan_fakelag_runtime.saved = saved
end

function panchan_fake_lag_restore()
    local saved = panchan_fakelag_runtime.saved
    if saved ~= nil then
        for i = 1, #saved.items do
            local item = saved.items[i]
            pcall(ui.set, item.ref, item.value)
        end

        if cvar and cvar.sv_maxusrcmdprocessticks then
            pcall(function()
                cvar.sv_maxusrcmdprocessticks:set_int(saved.process_ticks or 16)
            end)
        end
    end

    panchan_fake_lag_reset_runtime()
    panchan_fakelag_runtime.saved = nil
    panchan_fakelag_runtime.active = false
    panchan_fakelag_runtime.owner = nil
end

function panchan_fake_lag_apply_fake_duck()
    if panchan_fakelag_runtime.owner ~= "fake_duck" then
        panchan_fake_lag_reset_runtime()
    end

    panchan_fake_lag_save()
    panchan_fakelag_runtime.active = true
    panchan_fakelag_runtime.owner = "fake_duck"
    set_builtin_fake_lag(18, 18)
end

function panchan_fake_lag_force_off(cmd)
    panchan_fake_lag_restore()
end

function apply_panchan_fake_lag(cmd)
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        panchan_fake_lag_restore()
        return
    end

    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        panchan_fake_lag_restore()
        return
    end

    local enabled = panchan_fake_lag and ui.get(panchan_fake_lag)
    local fake_duck_active = ref.fd ~= nil and ui.get(ref.fd)

    if fake_duck_active then
        panchan_fake_lag_apply_fake_duck()
        return
    end

    if not enabled or panchan_fake_lag_exploit_locked() then
        panchan_fake_lag_force_off(cmd)
        return
    end

    if panchan_fakelag_runtime.owner ~= "panchan" then
        panchan_fake_lag_reset_runtime()
    end
    panchan_fake_lag_save()
    panchan_fakelag_runtime.active = true
    panchan_fakelag_runtime.owner = "panchan"

    local choked = get_cmd_choke(cmd)
    local ticks, variance, active_condition = panchan_fake_lag_get_settings()

    if panchan_fakelag_runtime.target_ticks == nil or panchan_fakelag_runtime.choked == 0 or panchan_fakelag_runtime.condition ~= active_condition or panchan_fakelag_runtime.variance ~= variance then
        panchan_fakelag_runtime.target_ticks = panchan_fake_lag_roll_ticks(ticks, variance)
        panchan_fakelag_runtime.condition = active_condition
        panchan_fakelag_runtime.variance = variance
    end

    local target_ticks = clamp(panchan_fakelag_runtime.target_ticks or ticks, 1, 24)
    set_builtin_fake_lag(target_ticks)

    if panchan_fakelag_runtime.choked < target_ticks and choked < target_ticks then
        cmd.allow_send_packet = false
        panchan_fakelag_runtime.choked = panchan_fakelag_runtime.choked + 1
    else
        panchan_fakelag_runtime.choked = 0
        panchan_fakelag_runtime.target_ticks = nil
    end
end

local function on_setup_command(cmd)
    if ref.fd == nil or not ui.get(ref.fd) then
        cmd.allow_send_packet = true
    end
    ui.set(ref.enabled, true)
    ui.set(ref.yaw_base, "At Targets")
    ui.set(ref.pitch[1], "Minimal")
    ui.set(ref.yaw[1], "180")
    ui.set(ref.yaw_jitter[1], "Off")
    ui.set(ref.freestanding_body_yaw, false)
    ui.set(ref.roll, 0)

    local condition = get_player_state(cmd)
    anti_brute.condition = condition
    local fake_lag_state = aa_settings["Fake Lag"]
    local fake_lag_exploit_locked = panchan_fake_lag_exploit_locked()

    if panchan_fake_lag and ui.get(panchan_fake_lag) and not fake_lag_exploit_locked and fake_lag_state and fake_lag_state.allow and ui.get(fake_lag_state.allow) then
        condition = "Fake Lag"
    end

    local settings = aa_settings[condition]

    if not settings or (condition ~= "Global" and not ui.get(settings.allow)) then
        settings = aa_settings["Global"]
    end

    if not sdk.is_alive(sdk.get_lp()) or not sdk.get_lp() then
        defensive_switch_time = 0
        return
    end

    local packet_exploit_active = panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active()
    if packet_exploit_active then
        fake_duck_freezetime_restore()
        duck_on_fd_unset()
    else
        if not fake_duck_freezetime_apply(cmd) then
            duck_on_fd_apply(cmd)
        end
        fake_duck_unspeed_apply(cmd)
    end

    local current_tick = globals.curtime()
    local delay_mode = ui.get(settings.delay)
    local delay_ticks = ui.get(settings.delay_t)

    if delay_mode == "Tickbased" and settings.delay_randomize and ui.get(settings.delay_randomize) then
        delay_ticks = random_between(ui.get(settings.delay_t_from), ui.get(settings.delay_t_to))
    end

    delay_ticks = anti_brute_adjust_delay(delay_ticks, cmd)

    local chance_percent = ui.get(settings.delay_c)
    local delay_rnd_select = ui.get(settings.delay_rnd_select)
    local delay_ticks_values = {}

    for i = 1, 12 do
        local slider = settings["delay_rnd_" .. i]
        delay_ticks_values[i] = slider and anti_brute_adjust_delay(ui.get(slider), cmd) or delay_ticks
    end

    current_state, last_switch_timer = update_state(cmd, current_tick, delay_mode, delay_ticks, delay_rnd_select, delay_ticks_values, chance_percent, last_switch_timer, current_state)

    local yaw_type = ui.get(settings.yaw_select)
    local yaw_switch_state = anti_brute_effective_state(current_state, cmd)

    if yaw_type == "Static" then
        local yaw = ui.get(settings.static_yaw)
        yaw_rl = ui.get(settings.static_yaw)
        ui.set(ref.yaw[2], clamp(yaw, -180, 180))
    elseif yaw_type == "L/R" then
        local left = ui.get(settings.l_yaw)
        local right = ui.get(settings.r_yaw)
        local random = settings.rnd_yaw and ui.get(settings.rnd_yaw) or 0
        local yaw = delayjitter(left, right, random, yaw_switch_state)
        ui.set(ref.yaw[2], clamp(yaw or 0, -180, 180))
        yaw_rl = yaw or 0
    end

    local yaw_jitter_mode = ui.get(settings.yaw_jitter)
    if yaw_jitter_mode == "Spin" then
        local spin_range = get_yaw_spin_range(settings, condition)
        local spin_speed = settings.yaw_jitter_spin_speed and ui.get(settings.yaw_jitter_spin_speed) or 32
        local frame_count = globals.framecount and globals.framecount() or globals.tickcount()
        local spin_offset = (frame_count * (spin_speed * 0.1)) % math.max(1, spin_range)

        yaw_rl = normalize_yaw(yaw_rl + spin_offset)
        ui.set(ref.yaw[2], clamp(yaw_rl, -180, 180))
        ui.set(ref.yaw_jitter[1], "Off")
        ui.set(ref.yaw_jitter[2], 0)
    else
        ui.set(ref.yaw_jitter[1], yaw_jitter_mode)
        if yaw_jitter_mode == "Off" then
            ui.set(ref.yaw_jitter[2], 0)
        else
            local yaw_jitters = ui.get(settings.yaw_jitter_value) + random_between(0, math.abs(ui.get(settings.yaw_jitter_value)) * ui.get(settings.yaw_jitter_rnd) / 100)
            ui.set(ref.yaw_jitter[2], clamp(yaw_jitters, -180, 180))
        end
    end

    local body_yaw_mode = ui.get(settings.body_yaw)
    local yaw_value = ui.get(settings.body_yaw_value)

    if body_yaw_mode ~= "Off" then
        ui.set(ref.body_yaw[1], "Static")
    else
        ui.set(ref.body_yaw[1], "Off")
    end

    change_debug("set_active", "antiaim:custom_desync()", false)
    if body_yaw_mode == "Static" then
        ui.set(ref.body_yaw[2], anti_brute_adjust_body(yaw_value, cmd))
    elseif body_yaw_mode == "Jitter" then
        local desync_angle = current_state and -yaw_value or yaw_value
        ui.set(ref.body_yaw[2], anti_brute_adjust_body(desync_angle, cmd))
    elseif body_yaw_mode == "Custom Jitter" then
        change_debug("set_active", "antiaim:custom_desync()", true)
        apply_custom_desync(cmd, yaw_rl, yaw_value, current_state)
    elseif body_yaw_mode == "Chaos Jitter" then
        change_debug("set_active", "antiaim:custom_desync()", true)
        apply_chaos_desync(cmd, yaw_rl, yaw_value, current_state, false)
    elseif body_yaw_mode == "PanchanModeV2" then
        apply_panchan_mode_v2_body_yaw(cmd, settings, current_state, yaw_rl)
    elseif body_yaw_mode == "Panchan Delayed" then
        yaw_rl = apply_panchan_delayed_body_yaw(cmd, settings, condition, false) or yaw_rl
    end

    change_debug("set_value", "antiaim:at_targets()", client.current_threat() ~= nil and "L"..client.current_threat() or "ERR")
    change_debug("set_value", "entity:shifting()", string.format("%d", player.shifting))
    change_debug("set_value", "entity:exploit.get()", player.get_dt() == true and "1" or "0")
    local trap_power = adaptive_aa_power()
    change_debug("set_active", "antiaim:resolver_trap()", trap_power > 0)
    change_debug("set_value", "antiaim:resolver_trap()", tostring(trap_power))
    if static.diff < 0 then
        change_debug("set_value", "entity:defensive_diff.get()", string.format("%d", static.diff))
        change_debug("set_active", "entity:defensive_diff.get()", true)
    else
        change_debug("set_active", "entity:defensive_diff.get()", false)
    end

    ---WARNING: НЕ ФОРСИТЬ ЛЦ НА ФОЛС ЕСЛИ НЕ БРИК ЛЦ ИНАЧЕ НАХУЙ ДЕФЕНСИВ ПИК УМРЁТ

    if (ui.get(settings.break_lc) and player.get_dt()) then
        cmd.force_defensive = true
    end
    
    local is_lcshka_slomana = static.defensive

    if is_lcshka_slomana and ui.get(settings.defensive_aa) then
        defensive_rework_update(cmd, condition)
        local defensive_yaw_mode = ui.get(settings.defensive_yaw)
        local defensive_pitch_mode = ui.get(settings.defensive_pitch)
        if defensive_yaw_mode == "Adaptive Snap" then
            delay_ticks_def = anti_brute_adjust_delay(defensive_rework_delay(3, defensive_yaw_mode), cmd)
        elseif defensive_yaw_mode == "Jitter" or defensive_yaw_mode == "Snap Jitter" then
            delay_ticks_def = anti_brute_adjust_delay(defensive_rework_delay(ui.get(settings.defensive_yaw_delay), defensive_yaw_mode), cmd)
        else
            delay_ticks_def = delay_ticks
        end
        delay_mode_def = (defensive_yaw_mode == "Jitter" or defensive_yaw_mode == "Snap Jitter" or defensive_yaw_mode == "Adaptive Snap") and "Tickbased" or delay_mode
        defensive_state, defensive_switch_time = update_state(cmd, current_tick, delay_mode_def, delay_ticks_def, delay_rnd_select, delay_ticks_values, chance_percent, defensive_switch_time, defensive_state)
        local defensive_yaw_state = anti_brute_effective_state(defensive_state, cmd)

        ui.set(ref.yaw_jitter[1], "Off")

        if defensive_pitch_mode == "Down" or defensive_pitch_mode == "Up" or defensive_pitch_mode == "POTATO" or defensive_pitch_mode == "Semi-Up" or defensive_pitch_mode == "Semi-Down" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_reference_pitch(defensive_pitch_mode))
        elseif defensive_pitch_mode == "Static" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_rework_pitch(ui.get(settings.defensive_pitch_static), defensive_pitch_mode))
        elseif defensive_pitch_mode == "Jitter" then
            local a, b = ui.get(settings.defensive_pitch_static), ui.get(settings.defensive_pitch_2)
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_rework_pitch(defensive_state and a or b, defensive_pitch_mode))
        elseif defensive_pitch_mode == "Random" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_reference_pitch(defensive_pitch_mode))
        elseif defensive_pitch_mode == "Sway" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_rework_pitch(custom_sway(ui.get(settings.defensive_pitch_static), ui.get(settings.defensive_pitch_2)), defensive_pitch_mode))
        elseif defensive_pitch_mode == "Static Random" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_rework_pitch(static_random(ui.get(settings.defensive_pitch_static), ui.get(settings.defensive_pitch_2)), defensive_pitch_mode))
        elseif defensive_pitch_mode == "Spin" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], spin_between(ui.get(settings.defensive_pitch_static), ui.get(settings.defensive_pitch_2), 2.55))
        elseif defensive_pitch_mode == "Micro Jitter" then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], defensive_micro_jitter_pitch(cmd))
        end

        if defensive_yaw_mode == "Opposite" or defensive_yaw_mode == "Opposite Jitter" or defensive_yaw_mode == "Side-Based" or defensive_yaw_mode == "Sideways" or defensive_yaw_mode == "Random" or defensive_yaw_mode == "3-Way" or defensive_yaw_mode == "5-Way" then
            yaw_rl_def = defensive_reference_yaw(defensive_yaw_mode)
            ui.set(ref.yaw[2], yaw_rl_def)
        elseif defensive_yaw_mode == "Static" then
            yaw_rl_def = defensive_rework_yaw(ui.get(settings.defensive_yaw_static), defensive_yaw_mode, cmd)
            ui.set(ref.yaw[2], yaw_rl_def)
        elseif defensive_yaw_mode == "Jitter" then
            local a, b = ui.get(settings.defensive_yaw_static), ui.get(settings.defensive_yaw_2)
            yaw_rl_def = defensive_rework_yaw(defensive_yaw_state and a or b, defensive_yaw_mode, cmd)
            ui.set(ref.yaw[2], yaw_rl_def)
        elseif defensive_yaw_mode == "Spin" then
            local yaw_spin = -normalize_yaw(globals.curtime() * (ui.get(settings.defensive_yaw_spin) * 10))
            yaw_rl_def = yaw_spin
            ui.set(ref.yaw[2], clamp(yaw_spin, -180, 180))
        elseif defensive_yaw_mode == "Negative Spin" then
            local yaw_spin = normalize_yaw(globals.curtime() * (ui.get(settings.defensive_yaw_spin) * 10))
            yaw_rl_def = yaw_spin
            ui.set(ref.yaw[2], clamp(yaw_spin, -180, 180))
        elseif defensive_yaw_mode == "Sway" then
            local yaw_sway = custom_sway_2(ui.get(settings.defensive_yaw_static), ui.get(settings.defensive_yaw_2))
            yaw_rl_def = defensive_rework_yaw(yaw_sway, defensive_yaw_mode, cmd)
            ui.set(ref.yaw[2], yaw_rl_def)
        elseif defensive_yaw_mode == "Distortion" then
            local yaw_dist = update_dist(14)
            yaw_rl_def = yaw_dist
            ui.set(ref.yaw[2], clamp(yaw_dist, -180, 180))
        elseif defensive_yaw_mode == "Panchan" then
            local yaw_panchan = update_spin(15)
            yaw_rl_def = yaw_panchan
            ui.set(ref.yaw[2], clamp(yaw_panchan, -180, 180))
        elseif defensive_yaw_mode == "Snap Jitter" then
            yaw_rl_def = defensive_rework_yaw(get_defensive_snap_yaw(settings, defensive_yaw_state, cmd), defensive_yaw_mode, cmd)
            ui.set(ref.yaw[2], yaw_rl_def)
        elseif defensive_yaw_mode == "Adaptive Snap" then
            yaw_rl_def = defensive_adaptive_snap_yaw(cmd)
            ui.set(ref.yaw[2], yaw_rl_def)
        end

        if defensive_yaw_mode ~= "Snap Jitter" then
            if body_yaw_mode == "Custom Jitter" then
                apply_custom_desync(cmd, yaw_rl_def, yaw_value, defensive_state)
            elseif body_yaw_mode == "Chaos Jitter" then
                apply_chaos_desync(cmd, yaw_rl_def, yaw_value, defensive_state, true)
            elseif body_yaw_mode == "PanchanModeV2" then
                apply_panchan_mode_v2_body_yaw(cmd, settings, defensive_state, yaw_rl_def)
            elseif body_yaw_mode == "Panchan Delayed" then
                apply_panchan_delayed_body_yaw(cmd, settings, condition, true)
            else
                defensive_rework_body(body_yaw_mode, yaw_value, defensive_state, cmd)
            end
        else
            if body_yaw_mode == "Static" then
                defensive_rework_body(body_yaw_mode, yaw_value, defensive_state, cmd)
            elseif body_yaw_mode == "Jitter" then
                defensive_rework_body(body_yaw_mode, yaw_value, defensive_state, cmd)
            elseif body_yaw_mode == "Custom Jitter" then
                apply_custom_desync(cmd, yaw_rl_def, yaw_value, defensive_state)
            elseif body_yaw_mode == "Chaos Jitter" then
                apply_chaos_desync(cmd, yaw_rl_def, yaw_value, defensive_state, true)
            elseif body_yaw_mode == "PanchanModeV2" then
                apply_panchan_mode_v2_body_yaw(cmd, settings, defensive_state, yaw_rl_def)
            elseif body_yaw_mode == "Panchan Delayed" then
                apply_panchan_delayed_body_yaw(cmd, settings, condition, true)
            else
                defensive_rework_body(body_yaw_mode, yaw_value, defensive_state, cmd)
            end
        end

    elseif defensive_rework_runtime.active then
        defensive_rework_runtime.active = false
        defensive_rework_runtime.next_phase_tick = 0
    end

    if aa_stealer_apply ~= nil then
        aa_stealer_apply(cmd, condition, settings)
    end
    anti_brute_apply_final(cmd, body_yaw_mode)
    flick_exploit_apply(cmd, condition)

    roll_antiaim_apply()

    if ui.get(edge_yaw) then
        ui.set(ref.edge_yaw, true)
    else
        ui.set(ref.edge_yaw, false)
    end
end

---@end

--[[local function freestnd(cmd)
    is_peeking_state()
    local is_in_peek = is_peeking
    local side = get_fs_side()

    if ui.get(freestand) then
        if is_in_peek then
            cmd.force_defensive = true

            if is_defensive and yaw_direction == 0 then
                ui.set(ref.freestand[1], false)

                if side == "left" then
                    ui.set(ref.yaw[2], -90)
                elseif side == "right" then
                    ui.set(ref.yaw[2], 90)
                else
                    ui.set(ref.yaw[2], 0)
                end

                ui.set(ref.pitch[1], "Custom")
                ui.set(ref.pitch[2], 0)
            elseif not is_defensive and yaw_direction == 0 then
                ui.set(ref.freestand[1], false)

                if side == "left" then
                    ui.set(ref.yaw[2], 90)
                elseif side == "right" then
                    ui.set(ref.yaw[2], -90)
                else
                    ui.set(ref.yaw[2], 0)
                end

                ui.set(ref.pitch[1], "Custom")
                ui.set(ref.pitch[2], 89)
            end
        else
            ui.set(ref.freestand[1], true)
            ui.set(ref.freestand[2], "Always On")
        end
    else
        ui.set(ref.freestand[1], false)
        ui.set(ref.freestand[2], "On Hotkey")
    end
end]]

local function freestnd()
    if yaw_direction ~= 0 then
        return
    end

    if ui.get(freestand) then
        ui.set(ref.freestand[1], true)   
        ui.set(ref.freestand[2], "Always On")
    else
        ui.set(ref.freestand[1], false)
        ui.set(ref.freestand[2], "On Hotkey")
    end
end

local function anti_stab()
    if not ui.get(backstab) then return end
    
    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return end
    
    local lp_origin = vector(entity.get_origin(lp))
    local enemies = entity.get_players(true)
    
    for i = 1, #enemies do
        local enemy = enemies[i]
        local enemy_weapon = entity.get_player_weapon(enemy)
        
            if enemy_weapon and safe_get_classname(enemy_weapon) == "CKnife" then
            if vector(entity.get_origin(enemy)):dist2d(lp_origin) < 250 then
                ui.set(ref.yaw[1], "180")
                ui.set(ref.yaw[2], 180)
                return
            end
        end
    end
end

local timer = globals.tickcount()
local recharge_delay = 1

local function handle_recharge()
    if not ui.get(recharge_fix) then
        return
    end

    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        timer = globals.tickcount()
        pcall(ui.set, ref.aimbot, true)
        return
    end

    local lp = sdk.get_lp()
    if not sdk.is_alive(lp) then return end
    
    local lp_weapon = entity.get_player_weapon(lp)
    if not lp_weapon then return end
    
    recharge_delay = weapons(lp_weapon).is_revolver and 18 or 2
 
    if ( ui.get(ref.dt[2]) or ui.get(ref.hs[2]) ) then
        if globals.tickcount() >= timer + recharge_delay then
            ui.set(ref.aimbot, true)
        else
            ui.set(ref.aimbot, false)
        end
    else
        timer = globals.tickcount()
        ui.set(ref.aimbot, true)
    end
end

---@config


local function setup_default_config(base64_cfg)
    if type(base64_cfg) ~= "string" or base64_cfg == "" then
        return false
    end

    local ok, decrypted_data = pcall(base64.decode, base64_cfg)
    if not ok then 
        return false
    end

    local ok2, cfg = pcall(json.parse, decrypted_data)
    if not ok2 or type(cfg) ~= "table" then 
        return false
    end
    
    cfg.config_name = "Default"
    
    return cfg
end

local function initialize_configs()
    if database.read("panchan_configs") == nil then
        database.write("panchan_configs", {})
    end
    if database.read("panchan_config_names") == nil then
        database.write("panchan_config_names", {})
    end
    
    local configs = database.read("panchan_configs")
    local names = database.read("panchan_config_names")
end

local function get_config_names()
    initialize_configs()
    local names = database.read("panchan_config_names")
    local options = {}
    
    for i = 1, #names do
        options[i] = names[i]
    end
    
    if #options == 0 then
        options[1] = "Please create a config"
    end
    
    return options
end

local config_names = get_config_names()
local config_listbox = ui.new_listbox("AA", "Anti-Aimbot angles", "Configs", config_names)
config_sections = ui.new_multiselect("AA", "Anti-Aimbot angles", "Config Sections", "Anti-Aim", "Visual", "Misc")
pcall(ui.set, config_sections, "Anti-Aim", "Visual", "Misc")
local config_name_textbox = ui.new_textbox("AA", "Anti-Aimbot angles", "Config name")
local collect_config
local apply_config

function panchan_config_today()
    if type(os) == "table" and type(os.date) == "function" then
        local ok, value = pcall(os.date, "%d.%m.%Y")
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end

    return tostring(update_date or "13.07.2026")
end

function panchan_config_metadata(cfg, create_if_missing)
    if type(cfg) ~= "table" then
        return nil
    end

    local meta = cfg._panchan_meta
    if type(meta) ~= "table" and create_if_missing then
        local today = panchan_config_today()
        meta = {
            version = 1,
            created_on = today,
            updated_on = today
        }
        cfg._panchan_meta = meta
    end

    if type(meta) ~= "table" then
        return nil
    end

    return meta
end

function panchan_config_new_metadata(cfg)
    if type(cfg) ~= "table" then
        return nil
    end

    local today = panchan_config_today()
    cfg._panchan_meta = {
        version = 1,
        created_on = today,
        updated_on = today
    }

    return cfg._panchan_meta
end

function panchan_config_saved_metadata(cfg, previous_cfg)
    if type(cfg) ~= "table" then
        return nil
    end

    local today = panchan_config_today()
    local previous_meta = panchan_config_metadata(previous_cfg, false)
    local created_on = today

    if previous_meta ~= nil and type(previous_meta.created_on) == "string" and previous_meta.created_on ~= "" then
        created_on = previous_meta.created_on
    end

    cfg._panchan_meta = {
        version = 1,
        created_on = created_on,
        updated_on = today
    }

    return cfg._panchan_meta
end

function panchan_config_console(action, name, cfg)
    local safe_action = tostring(action or "event")
    local safe_name = tostring(name or "unnamed"):gsub("[\r\n]", " "):gsub('"', "'")
    local line = 'cfg ' .. safe_action .. ' "' .. safe_name .. '"'
    local meta = panchan_config_metadata(cfg, false)

    if meta == nil or type(meta.created_on) ~= "string" or meta.created_on == "" then
        print(line .. " | legacy config")
        return
    end

    line = line .. " | created on " .. meta.created_on

    local updated_on = meta.updated_on
    if type(updated_on) ~= "string" or updated_on == "" then
        updated_on = meta.created_on
    end

    if safe_action == "save" or ((safe_action == "load" or safe_action == "export") and updated_on ~= meta.created_on) then
        line = line .. " | updated on " .. updated_on
    end

    print(line)
end

local function export()
    initialize_configs()
    local names = database.read("panchan_config_names")
    
    if #names == 0 then
        add_log("No configs to export", 3, 255, 100, 100)
        return
    end
    
    local selected_index = ui.get(config_listbox) + 1
    if selected_index > #names then
        add_log("Invalid config selected", 3, 255, 100, 100)
        return
    end
    
    local selected_name = names[selected_index]
    
    local cfg = collect_config()
    cfg.config_name = selected_name
    
    local encrypted = base64.encode(json.stringify(cfg))
    clipboard.set(encrypted)
    add_log("Exported config '" .. selected_name .. "'", 3, 100, 255, 100)
end

local function import(cfgdata)
    local ok, decrypted_data = pcall(base64.decode, cfgdata or clipboard.get())
    if not ok then 
        add_log("Failed to decode config data", 3, 255, 100, 100)
        return 
    end

    local ok2, cfg = pcall(json.parse, decrypted_data)
    if not ok2 or type(cfg) ~= "table" then 
        add_log("Failed to parse config data", 3, 255, 100, 100)
        return 
    end

    if not cfg.config_name then
        add_log("Invalid config format - no name found", 3, 255, 100, 100) 
        return
    end
    
    initialize_configs()
    local configs = database.read("panchan_configs")
    local names = database.read("panchan_config_names")
    
    local config_name = cfg.config_name
    
    local original_name = config_name
    local counter = 1
    while true do
        local exists = false
        for i = 1, #names do
            if names[i] == config_name then
                exists = true
                break
            end
        end
        
        if not exists then
            break
        end
        
        config_name = original_name .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    cfg.config_name = config_name

    table.insert(names, config_name)
    configs[config_name] = cfg
    
    database.write("panchan_configs", configs)
    database.write("panchan_config_names", names)
    database.flush()
    
    apply_config(cfg)

    ui.update(config_listbox, names)

    for i = 1, #names do
        if names[i] == config_name then
            ui.set(config_listbox, i - 1)
            break
        end
    end
    
    add_log("Imported config as '" .. config_name .. "'", 3, 100, 255, 100)
end

local config_value_refs = {
    {"center_indicators", center_indicators},
    {"center_indicators_type", center_indicators_type},
    {"hit_logs", hit_logs},
    {"hit_logs_type", hit_logs_type},
    {"recharge_fix", recharge_fix},
    {"fix_exploits", fix_exploits},
    {"jitter_correction", jitter_correction},
    {"jitter_correction_esp_flag", jitter_correction_esp_flag},
    {"fake_flick", fake_flick},
    {"adaptive_ping_spike", adaptive_ping_spike},
    {"fake_flick_conditions", fake_flick_conditions},
    {"defensive_correct", defensive_correct},
    {"resolver_lagcomp", resolver_lagcomp},
    {"panchan_fake_lag", panchan_fake_lag},
    {"panchan_fake_lag_disable_on_exploit", panchan_fake_lag_disable_on_exploit},
    {"panchan_fake_lag_ticks", panchan_fake_lag_ticks},
    {"panchan_fake_lag_variance", panchan_fake_lag_variance},
    {"early_quickpeek_autostop", early_quickpeek_autostop},
    {"quickpeek_weapon", quickpeek_weapon},
    {"quickpeek_dt_options", quickpeek_dt_options},
    {"quickpeek_dt_options_scout", quickpeek_dt_options_scout},
    {"quickpeek_dt_options_scar", quickpeek_dt_options_scar},
    {"quickpeek_dt_options_pistols", quickpeek_dt_options_pistols},
    {"quickpeek_dt_options_deagle", quickpeek_dt_options_deagle},
    {"quickpeek_dt_options_any", quickpeek_dt_options_any},
    {"experimental_predict", experimental_predict},
    {"cheat_revealer", cheat_revealer},
    {"delay_fix", delay_fix},
    {"delay_fix_weapons", delay_fix_weapons},
    {"_trashtalk", _trashtalk},
    {"trashtalk_mode", trashtalk_mode},
    {"trashtalk_on_death", trashtalk_on_death},
    {"console_filter", console_filter},
    {"duck_on_fd", duck_on_fd},
    {"fake_duck_unspeed", fake_duck_unspeed},
    {"fake_duck_unspeed_scale", fake_duck_unspeed_scale},
    {"fake_duck_freezetime", fake_duck_freezetime},
    {"state", state_selector},
    {"backstab", backstab},
    {"legit_aa", legit_aa},
    {"legit_aa_type", legit_aa_type},
    {"warmup_aa", warmup_aa},
    {"warmup_aa_activation", warmup_aa_activation},
    {"warmup_aa_pitch", warmup_aa_pitch},
    {"warmup_aa_yaw", warmup_aa_yaw},
    {"warmup_aa_range", warmup_aa_range},
    {"warmup_aa_speed", warmup_aa_speed},
    {"warmup_aa_left", warmup_aa_left},
    {"warmup_aa_right", warmup_aa_right},
    {"anti_bruteforce", anti_bruteforce},
    {"safehead", safehead},
    {"animfix", animfix},
    {"freestand", freestand},
    {"manual_l", manual_l},
    {"manual_r", manual_r},
    {"manual_f", manual_f},
    {"edge_yaw", edge_yaw},
    {"_custom_scope", _custom_scope},
    {"custom_scope_size", custom_scope_size},
    {"custom_scope_gap", custom_scope_gap},
    {"custom_scope_style", custom_scope_style},
    {"custom_scope_disable_animation", custom_scope_disable_animation},
    {"teammate_aimbot", teammate_aimbot},
    {"_clantag", _clantag},
    {"manual_ind", manual_ind},
    {"revolver_helper", revolver_helper},
    {"damage_indicator", damage_indicator},
    {"damage_indicator_font", damage_indicator_font},
    {"aspect_ratio_reference", aspect_ratio_reference},
    {"fast_ladder", fast_ladder},
    {"ladder_yaw180", ladder_yaw180},
    {"flick_exploit", flick_exploit},
    {"flick_exploit_states", flick_exploit_states},
    {"flick_exploit_delay", flick_exploit_delay},
    {"flick_exploit_offset", flick_exploit_offset},
    {"flick_exploit_body", flick_exploit_body},
    {"flick_exploit_pitch", flick_exploit_pitch},
    {"flick_exploit_pitch_value", flick_exploit_pitch_value},
    {"flick_exploit_pitch_second", flick_exploit_pitch_second},
    {"flick_exploit_pitch_speed", flick_exploit_pitch_speed},
    {"panchan_exploit", panchan_exploit},
    {"panchan_exploit_mode", panchan_exploit_mode},
    {"panchan_exploit_key", panchan_exploit_key},
    {"airlag_panchan_exploit", airlag_panchan_exploit},
    {"airlag_panchan_key", airlag_panchan_key},
    {"roll_antiaim", roll_antiaim},
    {"roll_antiaim_key", roll_antiaim_key},
    {"roll_antiaim_value", roll_antiaim_value},
    {"enable_aspect_ratio", enable_aspect_ratio},
    {"debug_text", debug_text},
    {"debug_text_position", debug_text_position},
    {"velocity_modifier", velocity_modifier},
    {"animated_zoom", animated_zoom},
    {"zoom_val", zoom_val},
    {"double_zoom", double_zoom},
    {"double_zoom_key", double_zoom_key},
    {"double_zoom_amount", double_zoom_amount},
    {"hirate_indicator", hirate_indicator},
    {"dormant_aimbot", dormant_aimbot},
    {"dormant_aimbot_key", dormant_aimbot_key},
    {"dormant_aimbot_selection", dormant_aimbot_selection},
    {"dormant_aimbot_hitboxes", dormant_aimbot_hitboxes},
    {"dormant_aimbot_mindmg", dormant_aimbot_mindmg},
    {"dormant_aimbot_accuracy", dormant_aimbot_accuracy},
    {"dormant_aimbot_indicator", dormant_aimbot_indicator},
    {"dormant_aimbot_multipoint", dormant_aimbot_multipoint},
    {"dormant_aimbot_autostop", dormant_aimbot_autostop},
    {"dormant_aimbot_max_fov", dormant_aimbot_max_fov},
    {"dormant_aimbot_max_distance", dormant_aimbot_max_distance},
    {"dormant_aimbot_cooldown", dormant_aimbot_cooldown},
    {"dormant_aimbot_timeout", dormant_aimbot_timeout},
    {"shared_esp_neverlose", shared_esp_neverlose},
    {"view_model_enable", view_model_config_refs.enable},
    {"view_model_fov", view_model_config_refs.fov},
    {"view_model_x", view_model_config_refs.x},
    {"view_model_y", view_model_config_refs.y},
    {"view_model_z", view_model_config_refs.z},
    {"view_model_right_hand", view_model_config_refs.right_hand},
    {"view_model_custom_bob", view_model_config_refs.custom_bob},
    {"view_model_bob_lower", view_model_config_refs.bob_lower},
    {"view_model_bob_lat", view_model_config_refs.bob_lat},
    {"view_model_bob_vert", view_model_config_refs.bob_vert},
    {"log_prefix", log_prefix_textbox},
    {"misc_watermark", misc_watermark},
    {"misc_watermark_text", misc_watermark_text},
    {"misc_watermark_beta_text", misc_watermark_beta_text},
    {"misc_watermark_type", misc_watermark_type},
    {"misc_watermark_font", misc_watermark_font},
    {"misc_watermark_remove_space", misc_watermark_remove_space},
    {"misc_watermark_gradient", misc_watermark_gradient},
    {"misc_watermark_position", misc_watermark_position},
    {"misc_watermark_rainbow", misc_watermark_rainbow},
    {"misc_watermark_blink_speed", misc_watermark_blink_speed},
    {"misc_watermark_rainbow_speed", misc_watermark_rainbow_speed},
    {"misc_watermark_encode_amount", misc_watermark_encode_amount},
    {"misc_watermark_encode_speed", misc_watermark_encode_speed},
    {"ragebot_improved", ragebot_improved},
    {"ragebot_hitscan_sample_count", ragebot_hitscan_sample_count},
    {"ragebot_hitscan_percent_cap", ragebot_hitscan_percent_cap},
    {"ragebot_hitscan_hitbox_cap", ragebot_hitscan_hitbox_cap},
    {"ragebot_hitscan_hitbox_mask", ragebot_hitscan_hitbox_mask},
    {"visual_tracer", visual_tracer},
    {"visual_tracer_type", visual_tracer_type},
    {"visual_tracer_impact_mode", visual_tracer_impact_mode},
    {"extendedbacktrack", extendedbacktrack},
    {"fps_optimize", fps_optimize}
}

local config_color_refs = {
    {"color", color},
    {"hit_logs_color", hit_logs_color},
    {"log_prefix_color", log_prefix_color},
    {"log_console_color", log_console_color},
    {"custom_scope_color", custom_scope_color},
    {"manual_ind_color", manual_ind_color},
    {"misc_watermark_color", misc_watermark_color},
    {"misc_watermark_second_color", misc_watermark_second_color},
    {"misc_watermark_beta_color", misc_watermark_beta_color},
    {"visual_tracer_color", visual_tracer_color}
}

config_key_categories = {
    center_indicators = "Visual",
    center_indicators_type = "Visual",
    hit_logs = "Misc",
    hit_logs_type = "Misc",
    _custom_scope = "Visual",
    custom_scope_size = "Visual",
    custom_scope_gap = "Visual",
    custom_scope_style = "Visual",
    custom_scope_disable_animation = "Visual",
    manual_ind = "Visual",
    revolver_helper = "Visual",
    damage_indicator = "Visual",
    damage_indicator_font = "Visual",
    aspect_ratio_reference = "Visual",
    enable_aspect_ratio = "Visual",
    debug_text = "Visual",
    debug_text_position = "Visual",
    velocity_modifier = "Visual",
    animated_zoom = "Visual",
    zoom_val = "Visual",
    misc_watermark = "Visual",
    misc_watermark_text = "Visual",
    misc_watermark_beta_text = "Visual",
    misc_watermark_type = "Visual",
    misc_watermark_font = "Visual",
    misc_watermark_remove_space = "Visual",
    misc_watermark_gradient = "Visual",
    misc_watermark_position = "Visual",
    misc_watermark_rainbow = "Visual",
    misc_watermark_blink_speed = "Visual",
    misc_watermark_rainbow_speed = "Visual",
    misc_watermark_encode_amount = "Visual",
    misc_watermark_encode_speed = "Visual",
    visual_tracer = "Visual",
    visual_tracer_type = "Visual",
    visual_tracer_impact_mode = "Visual",
    color = "Visual",
    hit_logs_color = "Misc",
    log_prefix_color = "Misc",
    log_console_color = "Misc",
    jitter_correction = "Misc",
    jitter_correction_esp_flag = "Misc",
    fake_flick = "Misc",
    adaptive_ping_spike = "Misc",
    fake_flick_conditions = "Misc",
    defensive_correct = "Misc",
    ragebot_improved = "Misc",
    ragebot_hitscan_sample_count = "Misc",
    ragebot_hitscan_percent_cap = "Misc",
    ragebot_hitscan_hitbox_cap = "Misc",
    ragebot_hitscan_hitbox_mask = "Misc",
    panchan_fake_lag = "Anti-Aim",
    panchan_fake_lag_disable_on_exploit = "Anti-Aim",
    panchan_fake_lag_ticks = "Anti-Aim",
    panchan_fake_lag_variance = "Anti-Aim",
    resolver_lagcomp = "Misc",
    early_quickpeek_autostop = "Misc",
    quickpeek_weapon = "Misc",
    quickpeek_dt_options = "Misc",
    quickpeek_dt_options_scout = "Misc",
    quickpeek_dt_options_scar = "Misc",
    quickpeek_dt_options_pistols = "Misc",
    quickpeek_dt_options_deagle = "Misc",
    quickpeek_dt_options_any = "Misc",
    experimental_predict = "Misc",
    cheat_revealer = "Misc",
    shared_esp_neverlose = "Misc",
    delay_fix_weapons = "Misc",
    view_model_enable = "Visual",
    view_model_fov = "Visual",
    view_model_x = "Visual",
    view_model_y = "Visual",
    view_model_z = "Visual",
    view_model_right_hand = "Visual",
    view_model_custom_bob = "Visual",
    view_model_bob_lower = "Visual",
    view_model_bob_lat = "Visual",
    view_model_bob_vert = "Visual",
    custom_scope_color = "Visual",
    manual_ind_color = "Visual",
    misc_watermark_color = "Visual",
    misc_watermark_second_color = "Visual",
    misc_watermark_beta_color = "Visual",
    visual_tracer_color = "Visual",

    state = "Anti-Aim",
    backstab = "Anti-Aim",
    legit_aa = "Anti-Aim",
    legit_aa_type = "Anti-Aim",
    warmup_aa = "Anti-Aim",
    warmup_aa_activation = "Anti-Aim",
    warmup_aa_pitch = "Anti-Aim",
    warmup_aa_yaw = "Anti-Aim",
    warmup_aa_range = "Anti-Aim",
    warmup_aa_speed = "Anti-Aim",
    warmup_aa_left = "Anti-Aim",
    warmup_aa_right = "Anti-Aim",
    anti_bruteforce = "Anti-Aim",
    safehead = "Anti-Aim",
    freestand = "Anti-Aim",
    manual_l = "Anti-Aim",
    manual_r = "Anti-Aim",
    manual_f = "Anti-Aim",
    edge_yaw = "Anti-Aim",
    flick_exploit = "Anti-Aim",
    flick_exploit_states = "Anti-Aim",
    flick_exploit_delay = "Anti-Aim",
    flick_exploit_offset = "Anti-Aim",
    flick_exploit_body = "Anti-Aim",
    flick_exploit_pitch = "Anti-Aim",
    flick_exploit_pitch_value = "Anti-Aim",
    flick_exploit_pitch_second = "Anti-Aim",
    flick_exploit_pitch_speed = "Anti-Aim",
    panchan_exploit = "Anti-Aim",
    panchan_exploit_mode = "Anti-Aim",
    panchan_exploit_key = "Anti-Aim",
    airlag_panchan_exploit = "Anti-Aim",
    airlag_panchan_key = "Anti-Aim",
    roll_antiaim = "Anti-Aim",
    roll_antiaim_key = "Anti-Aim",
    roll_antiaim_value = "Anti-Aim"
}

function config_section_enabled(section)
    local selected = ui.get(config_sections)

    if type(selected) ~= "table" or #selected == 0 then
        return true
    end

    return contains(selected, section)
end

function config_should_apply_key(key)
    return config_section_enabled(config_key_categories[key] or "Misc")
end

collect_config = function()
    local cfg = {}

    for i = 1, #config_value_refs do
        local item = config_value_refs[i]
        local ok, value = pcall(ui.get, item[2])

        if ok then
            cfg[item[1]] = value
        end
    end

    for i = 1, #config_color_refs do
        local item = config_color_refs[i]
        local ok, r, g, b, a = pcall(ui.get, item[2])

        if ok then
            cfg[item[1]] = { r, g, b, a }
        end
    end

    cfg.aa = {}
    for state, elems in pairs(aa_settings) do
        cfg.aa[state] = {}
        for key, widget in pairs(elems) do
            local ok, value = pcall(ui.get, widget)

            if ok then
                cfg.aa[state][key] = value
            end
        end
    end

    panchan_delayed_virtual_collect_into(cfg.aa)

    return cfg
end

apply_config = function(cfg)
    local has_view_model_state = false

    if view_model_has_config_state ~= nil then
        local ok, result = pcall(view_model_has_config_state, cfg)
        has_view_model_state = ok and result == true
    end

    if has_view_model_state and view_model_begin_config_apply ~= nil then
        pcall(view_model_begin_config_apply)
    end

    for i = 1, #config_value_refs do
        local item = config_value_refs[i]
        local value = cfg[item[1]]

        if value ~= nil and config_should_apply_key(item[1]) then
            pcall(ui.set, item[2], value)
        end
    end

    for i = 1, #config_color_refs do
        local item = config_color_refs[i]
        local value = cfg[item[1]]

        if value ~= nil and config_should_apply_key(item[1]) then
            pcall(function()
                if type(value) == "table" then
                    ui.set(item[2], unpack(value))
                else
                    ui.set(item[2], value)
                end
            end)
        end
    end

    if cfg.aa ~= nil and config_section_enabled("Anti-Aim") then
        for state, elems in pairs(aa_settings) do
            if cfg.aa[state] ~= nil then
                for key, widget in pairs(elems) do
                    local value = cfg.aa[state][key]

                    if value ~= nil then
                        if key == "yaw_select" and value == "L/R Delay" then
                            value = "L/R"
                        end
                        pcall(ui.set, widget, value)
                    end
                end
            end
        end

        panchan_delayed_virtual_apply_from(cfg.aa)
    end

    if view_model_on_config_applied ~= nil then
        pcall(view_model_on_config_applied, cfg)
    end

end

local create_button = ui.new_button("AA", "Anti-Aimbot angles", "\aB4F000FFCreate Config", function()
    local name = ui.get(config_name_textbox)
    if name == nil or name == "" then
        add_log("Please enter a config name", 3, 255, 100, 100)
        return
    end

    if string.len(name) > 32 then
        add_log("Config name too long", 3, 255, 100, 100)
        return
    end
    
    initialize_configs()
    local configs = database.read("panchan_configs")
    local names = database.read("panchan_config_names")
    
    for i = 1, #names do
        if names[i] == name then
            add_log("Config name already exists", 3, 255, 100, 100)
            return
        end
    end
    
    local cfg = collect_config()
    cfg.config_name = name
    panchan_config_new_metadata(cfg)
    
    table.insert(names, name)
    configs[name] = cfg
    
    database.write("panchan_configs", configs)
    database.write("panchan_config_names", names)
    database.flush()
    
    ui.update(config_listbox, names)
    add_log("Config '" .. name .. "' created", 3, 100, 255, 100)
    panchan_config_console("create", name, cfg)
end)

local save_button = ui.new_button("AA", "Anti-Aimbot angles", "\a7AD7FFFFSave Config", function()
    initialize_configs()
    local names = database.read("panchan_config_names")
    local configs = database.read("panchan_configs")
    
    if #names == 0 then
        add_log("No configs to save to", 3, 255, 100, 100)
        return
    end
    
    local selected_index = ui.get(config_listbox) + 1
    if selected_index > #names then
        add_log("Invalid config selected", 3, 255, 100, 100)
        return
    end
    
    local selected_name = names[selected_index]

    if selected_name == "Default" then
        add_log("Cannot save to Default config", 3, 255, 100, 100)
        return
    end

    local previous_cfg = configs[selected_name]
    local cfg = collect_config()
    cfg.config_name = selected_name
    panchan_config_saved_metadata(cfg, previous_cfg)
    
    configs[selected_name] = cfg
    database.write("panchan_configs", configs)
    database.flush()
    
    add_log("Config '" .. selected_name .. "' saved", 3, 100, 255, 100)
    panchan_config_console("save", selected_name, cfg)

end)

local load_button = ui.new_button("AA", "Anti-Aimbot angles", "\a7AD7FFFFLoad Config", function()
    initialize_configs()
    local names = database.read("panchan_config_names")
    local configs = database.read("panchan_configs")
    
    if #names == 0 then
        add_log("No configs to load", 3, 255, 100, 100)
        return
    end
    
    local selected_index = ui.get(config_listbox) + 1
    if selected_index > #names then
        add_log("Invalid config selected", 3, 255, 100, 100)
        return
    end
    
    local selected_name = names[selected_index]
    local cfg = configs[selected_name]
    
    if not cfg then
        add_log("Config data not found", 3, 255, 100, 100)
        return
    end
    
    apply_config(cfg)
    
    add_log("Config '" .. selected_name .. "' loaded", 3, 100, 255, 100)
    panchan_config_console("load", selected_name, cfg)
end)

local delete_button = ui.new_button("AA", "Anti-Aimbot angles", "\aFF7070FFDelete Config", function()
    initialize_configs()
    local names = database.read("panchan_config_names")
    local configs = database.read("panchan_configs")
    
    if #names == 0 then
        add_log("No configs to delete", 3, 255, 100, 100)
        return
    end
    
    local selected_index = ui.get(config_listbox) + 1
    if selected_index > #names then
        add_log("Invalid config selected", 3, 255, 100, 100)
        return
    end
    
    local selected_name = names[selected_index]
    
    if selected_name == "Default" then
        add_log("Cannot delete Default config", 3, 255, 100, 100)
        return
    end
    
    local deleted_cfg = configs[selected_name]

    table.remove(names, selected_index)
    configs[selected_name] = nil
    
    database.write("panchan_configs", configs)
    database.write("panchan_config_names", names)
    database.flush()
    
    ui.update(config_listbox, names)
    add_log("Config '" .. selected_name .. "' deleted", 3, 255, 150, 150)
    panchan_config_console("delete", selected_name, deleted_cfg)
end)

local import_button = ui.new_button("AA", "Anti-Aimbot angles", "\aC792EAFFImport Config", function()
    import()
end)

local export_button = ui.new_button("AA", "Anti-Aimbot angles", "\aFFD166FFExport Config", function()
    initialize_configs()
    local names = database.read("panchan_config_names")
    local configs = database.read("panchan_configs")
    
    if #names == 0 then
        add_log("No configs to export", 3, 255, 100, 100)
        return
    end
    
    local selected_index = ui.get(config_listbox) + 1
    if selected_index > #names then
        add_log("Invalid config selected", 3, 255, 100, 100)
        return
    end
    
    local selected_name = names[selected_index]
    
    if selected_name == "Default" then
        add_log("Cannot export Default config", 3, 255, 100, 100)
        return
    end

    local cfg = configs[selected_name]
    if not cfg then
        add_log("Config data not found", 3, 255, 100, 100)
        return
    end
    
    cfg.config_name = selected_name
    
    local encrypted = base64.encode(json.stringify(cfg))
    clipboard.set(encrypted)
    add_log("Exported config '" .. selected_name .. "'", 3, 100, 255, 100)
    panchan_config_console("export", selected_name, cfg)
end)

local function cfg_visibility()
    set_menu_visible(config_listbox, cur_tab == 5)
    set_menu_visible(config_sections, cur_tab == 5)
    set_menu_visible(config_name_textbox, cur_tab == 5)
    set_menu_visible(create_button, cur_tab == 5)
    set_menu_visible(delete_button, cur_tab == 5)
    set_menu_visible(save_button, cur_tab == 5)
    set_menu_visible(load_button, cur_tab == 5)
    set_menu_visible(export_button, cur_tab == 5)
    set_menu_visible(import_button, cur_tab == 5)
end

initialize_configs()

---@end



---@skeet_elements_hider_start
local function on_load()
    if not ui.is_menu_open() then
        return
    end

    local skeet_refs = {
        ref.enabled, ref.pitch[1], ref.pitch[2], ref.yaw_base, ref.yaw[1], ref.yaw[2],
        ref.yaw_jitter[1], ref.yaw_jitter[2], ref.body_yaw[1], ref.body_yaw[2],
        ref.freestanding_body_yaw, ref.edge_yaw, ref.freestand[1], ref.freestand[2],
        ref.roll
    }
    for _, ref_item in ipairs(skeet_refs) do
        if ref_item ~= nil then
            local ok = pcall(ui.set_visible, ref_item, false)
            if ok then
                menu_visibility_cache[ref_item] = false
            end
        end
    end
end

local function on_unload()
    local skeet_refs = {
        ref.enabled, ref.pitch[1], ref.pitch[2], ref.yaw_base, ref.yaw[1], ref.yaw[2],
        ref.yaw_jitter[1], ref.yaw_jitter[2], ref.body_yaw[1], ref.body_yaw[2],
        ref.freestanding_body_yaw, ref.edge_yaw, ref.freestand[1], ref.freestand[2],
        ref.roll, ref.fakelag_limit, ref.variability, ref.falelag_enabled[1], ref.falelag_enabled[2], ref.fakelag_amount
    }
    for _, ref_item in ipairs(skeet_refs) do
        set_menu_visible(ref_item, true)
    end
end

local function hide_fakelag()
    local fl_refs = {ref.fakelag_limit, ref.variability, ref.falelag_enabled[1], ref.falelag_enabled[2], ref.fakelag_amount}
    for _, ref_item in ipairs(fl_refs) do
        set_menu_visible(ref_item, cur_tab == 2)
    end

    local panchan_visible = cur_tab == 2
    local panchan_enabled = panchan_visible and ui.get(panchan_fake_lag)

    set_menu_visible(panchan_fake_lag, panchan_visible)
    set_menu_visible(panchan_fake_lag_disable_on_exploit, panchan_enabled)
    set_menu_visible(panchan_fake_lag_ticks, panchan_enabled)
    set_menu_visible(panchan_fake_lag_variance, panchan_enabled)
end

panchan_aesthetic_core = panchan_aesthetic_core or {
    init_attempted = false,
    winapi = nil,
    old_protection = ffi.new("unsigned long[1]"),
    errors = {}
}

function panchan_aesthetic_log_once(key, message)
    if panchan_aesthetic_core.errors[key] then
        return
    end

    panchan_aesthetic_core.errors[key] = true
    client.error_log("[Panchan] " .. tostring(message))
end

function panchan_aesthetic_copy_bytes(values)
    local result = {}
    for i = 1, #values do
        result[i] = values[i]
    end
    return result
end

function panchan_aesthetic_bytes_equal(first, second)
    if first == nil or second == nil or #first ~= #second then
        return false
    end

    for i = 1, #first do
        if first[i] ~= second[i] then
            return false
        end
    end

    return true
end

function panchan_aesthetic_read_import_target(call_site)
    return ffi.cast("uint32_t**", ffi.cast("uint32_t", call_site) + 2)[0][0]
end

function panchan_aesthetic_memory_initialize()
    local core = panchan_aesthetic_core
    if core.winapi ~= nil then
        return true
    end
    if core.init_attempted then
        return false
    end

    core.init_attempted = true
    local ok, resolved = pcall(function()
        local jmp_ecx = client.find_signature("engine.dll", "\xFF\xE1")
        local get_proc_call = client.find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\xA3\xCC\xCC\xCC\xCC\xEB\x05")
        local get_module_call = client.find_signature("engine.dll", "\xFF\x15\xCC\xCC\xCC\xCC\x85\xC0\x74\x0B")

        if jmp_ecx == nil or get_proc_call == nil or get_module_call == nil then
            return nil
        end

        local get_proc_address = panchan_aesthetic_read_import_target(get_proc_call)
        local get_module_handle = panchan_aesthetic_read_import_target(get_module_call)
        local call_get_proc_address = ffi.cast("uint32_t(__fastcall*)(unsigned int, unsigned int, uint32_t, const char*)", jmp_ecx)
        local call_get_module_handle = ffi.cast("uint32_t(__fastcall*)(unsigned int, unsigned int, const char*)", jmp_ecx)
        local call_virtual_protect = ffi.cast("int(__fastcall*)(unsigned int, unsigned int, void*, unsigned long, unsigned long, unsigned long*)", jmp_ecx)
        local kernel32 = call_get_module_handle(get_module_handle, 0, "kernel32.dll")

        if kernel32 == 0 then
            return nil
        end

        local virtual_protect = call_get_proc_address(get_proc_address, 0, kernel32, "VirtualProtect")
        if virtual_protect == 0 then
            return nil
        end

        return {
            protect = function(address, size, protection, old_protection)
                return call_virtual_protect(virtual_protect, 0, address, size, protection, old_protection)
            end
        }
    end)

    if not ok or resolved == nil then
        panchan_aesthetic_log_once("memory_init", "Aesthetic patch core unavailable")
        return false
    end

    core.winapi = resolved
    return true
end

function panchan_aesthetic_read_bytes(address, length)
    if not panchan_aesthetic_memory_initialize() then
        return nil
    end

    local result = {}
    local ok = pcall(function()
        local pointer = ffi.cast("uint8_t*", address)
        for i = 1, length do
            result[i] = pointer[i - 1]
        end
    end)

    return ok and result or nil
end

function panchan_aesthetic_write_bytes(address, values)
    if not panchan_aesthetic_memory_initialize() then
        return false
    end

    local core = panchan_aesthetic_core
    local pointer = ffi.cast("void*", address)
    local size = #values

    if core.winapi.protect(pointer, size, 0x40, core.old_protection) == 0 then
        return false
    end

    local ok = pcall(function()
        local bytes = ffi.cast("uint8_t*", address)
        for i = 1, size do
            bytes[i - 1] = values[i]
        end
    end)

    core.winapi.protect(pointer, size, core.old_protection[0], core.old_protection)
    return ok
end

function panchan_aesthetic_patch_apply(patch, value)
    if patch == nil or patch.disabled then
        return false
    end

    local wanted = patch.build ~= nil and patch.build(value) or patch.patched
    if wanted == nil then
        return false
    end

    local current = panchan_aesthetic_read_bytes(patch.address, #wanted)
    if current == nil then
        panchan_aesthetic_log_once(patch.name .. "_read", patch.name .. " memory read failed")
        return false
    end

    if patch.owned then
        if not panchan_aesthetic_bytes_equal(current, patch.applied) then
            patch.owned = false
            patch.applied = nil
            patch.restore_bytes = nil
            panchan_aesthetic_log_once(patch.name .. "_ownership", patch.name .. " patch ownership lost")
            return false
        end

        if panchan_aesthetic_bytes_equal(current, wanted) then
            return true
        end
    else
        local valid = patch.capture_original == true
            or panchan_aesthetic_bytes_equal(current, patch.original)

        if not valid and patch.validator ~= nil then
            valid = patch.validator(current)
        end

        if not valid then
            patch.disabled = true
            panchan_aesthetic_log_once(patch.name .. "_bytes", patch.name .. " byte check failed")
            return false
        end

        patch.restore_bytes = panchan_aesthetic_copy_bytes(current)
        if patch.capture_original and patch.original == nil then
            patch.original = panchan_aesthetic_copy_bytes(current)
        end
    end

    if not panchan_aesthetic_write_bytes(patch.address, wanted) then
        panchan_aesthetic_log_once(patch.name .. "_write", patch.name .. " memory write failed")
        return false
    end

    local verify = panchan_aesthetic_read_bytes(patch.address, #wanted)
    if not panchan_aesthetic_bytes_equal(verify, wanted) then
        panchan_aesthetic_log_once(patch.name .. "_verify", patch.name .. " patch verification failed")
        return false
    end

    patch.owned = true
    patch.applied = panchan_aesthetic_copy_bytes(wanted)
    return true
end

function panchan_aesthetic_patch_restore(patch)
    if patch == nil or not patch.owned then
        return true
    end

    local current = panchan_aesthetic_read_bytes(patch.address, #(patch.applied or {}))
    if current == nil then
        return false
    end

    if not panchan_aesthetic_bytes_equal(current, patch.applied) then
        patch.owned = false
        patch.applied = nil
        patch.restore_bytes = nil
        panchan_aesthetic_log_once(patch.name .. "_restore_ownership", patch.name .. " restore skipped after ownership loss")
        return false
    end

    if patch.restore_bytes ~= nil
        and not panchan_aesthetic_write_bytes(patch.address, patch.restore_bytes) then
        panchan_aesthetic_log_once(patch.name .. "_restore", patch.name .. " restore failed")
        return false
    end

    patch.owned = false
    patch.applied = nil
    patch.restore_bytes = nil
    return true
end

function panchan_aesthetic_group_apply(group, value)
    if group == nil then
        return false
    end

    for i = 1, #group do
        if not panchan_aesthetic_patch_apply(group[i], value) then
            for restore_index = 1, i - 1 do
                panchan_aesthetic_patch_restore(group[restore_index])
            end
            return false
        end
    end

    return true
end

function panchan_aesthetic_group_restore(group)
    if group == nil then
        return
    end

    for i = #group, 1, -1 do
        panchan_aesthetic_patch_restore(group[i])
    end
end

function panchan_aesthetic_to_u8(value)
    return math.floor(tonumber(value) or 0) % 0x100
end

function panchan_aesthetic_to_le32(value)
    value = math.floor(tonumber(value) or 0)
    if value < 0 then
        value = value + 0x100000000
    end

    return {
        value % 0x100,
        math.floor(value / 0x100) % 0x100,
        math.floor(value / 0x10000) % 0x100,
        math.floor(value / 0x1000000) % 0x100
    }
end

function panchan_aesthetic_join_bytes(first, second)
    local result = panchan_aesthetic_copy_bytes(first)
    for i = 1, #second do
        result[#result + 1] = second[i]
    end
    return result
end

function panchan_aesthetic_nops(count)
    local result = {}
    for i = 1, count do
        result[i] = 0x90
    end
    return result
end

function panchan_aesthetic_cmp_imm32(name, address, register, original)
    return {
        name = name,
        address = address,
        original = panchan_aesthetic_join_bytes({0x81, register}, panchan_aesthetic_to_le32(original)),
        validator = function(current)
            return current ~= nil and current[1] == 0x81 and current[2] == register
        end,
        build = function(value)
            return panchan_aesthetic_join_bytes({0x81, register}, panchan_aesthetic_to_le32(value))
        end
    }
end

function panchan_aesthetic_push_imm8(name, address, original)
    return {
        name = name,
        address = address,
        original = {0x6A, original},
        validator = function(current)
            return current ~= nil and current[1] == 0x6A
        end,
        build = function(value)
            return {0x6A, panchan_aesthetic_to_u8(value)}
        end
    }
end

function panchan_aesthetic_mov_esi_imm32(name, address, original)
    return {
        name = name,
        address = address,
        original = panchan_aesthetic_join_bytes({0xBE}, panchan_aesthetic_to_le32(original)),
        validator = function(current)
            return current ~= nil and current[1] == 0xBE
        end,
        build = function(value)
            return panchan_aesthetic_join_bytes({0xBE}, panchan_aesthetic_to_le32(value))
        end
    }
end

function panchan_aesthetic_disp32(name, address, prefix, original)
    return {
        name = name,
        address = address,
        original = panchan_aesthetic_join_bytes(prefix, panchan_aesthetic_to_le32(original)),
        validator = function(current)
            if current == nil then
                return false
            end
            for i = 1, #prefix do
                if current[i] ~= prefix[i] then
                    return false
                end
            end
            return true
        end,
        build = function(value)
            return panchan_aesthetic_join_bytes(prefix, panchan_aesthetic_to_le32(value))
        end
    }
end

function panchan_aesthetic_fixed_patch(name, address, original, patched)
    return {
        name = name,
        address = address,
        original = original,
        patched = patched
    }
end

ragebot_improved_runtime = {
    initialized = false,
    groups = {},
    hitscan = {
        airborne = nil,
        post_landing_ticks = 0,
        last_sample_count = nil
    },
    bt_distance_squared = nil,
    fixed_seed_table = nil,
    fixed_seed_address = nil
}

function ragebot_improved_enabled(option)
    if ragebot_improved == nil then
        return false
    end

    local selected = ui.get(ragebot_improved)
    if selected == nil or selected == "Off" then
        return false
    end

    if type(selected) == "table" then
        for i = 1, #selected do
            if selected[i] == option
                or selected[i] == "Full Improved"
                or selected[i] == "Full improved" then
                return true
            end
        end
        return false
    end

    return selected == option
        or selected == "Full Improved"
        or selected == "Full improved"
end

function ragebot_improved_any_enabled()
    if ragebot_improved == nil then
        return false
    end

    local selected = ui.get(ragebot_improved)
    if type(selected) == "table" then
        return #selected > 0
    end

    return selected ~= nil and selected ~= "Off"
end

function ragebot_improved_initialize()
    local rt = ragebot_improved_runtime
    if rt.initialized then
        return true
    end
    if not panchan_aesthetic_memory_initialize() then
        return false
    end

    rt.groups.delay = {
        panchan_aesthetic_fixed_patch(
            "Delay Shot strict branch",
            0x433ED5BD,
            {0x75, 0x07},
            {0xEB, 0x07}
        ),
        panchan_aesthetic_fixed_patch(
            "Delay Shot revalidate",
            0x433ED757,
            {0x0F, 0x2F, 0x15, 0x58, 0x27, 0x47, 0x43},
            {0x0F, 0x2F, 0x15, 0x6C, 0xEE, 0x46, 0x43}
        ),
        panchan_aesthetic_fixed_patch(
            "Delay Shot rescan",
            0x4335BAA5,
            {0x74, 0x64},
            {0x90, 0x90}
        )
    }

    rt.bt_distance_squared = ffi.new("float[1]", 512 * 512)
    local bt_distance_address = tonumber(ffi.cast("uintptr_t", ffi.cast("void*", rt.bt_distance_squared)))
    local bt_distance_patch = panchan_aesthetic_disp32(
        "BT distance",
        0x433AED50,
        {0x0F, 0x2F, 0x15},
        0x43472B60
    )

    rt.groups.bt = {
        bt_distance_patch,
        {
            name = "BT gap",
            address = 0x433AF012,
            original = {0x83, 0xF9, 0x08},
            patched = {0x83, 0xF9, 20},
            validator = function(current)
                return current ~= nil and current[1] == 0x83 and current[2] == 0xF9
            end
        }
    }
    bt_distance_patch.patched = panchan_aesthetic_join_bytes(
        {0x0F, 0x2F, 0x15},
        panchan_aesthetic_to_le32(bt_distance_address)
    )
    bt_distance_patch.build = nil

    rt.groups.jump = {
        panchan_aesthetic_fixed_patch(
            "Jump Scout",
            0x43372D89,
            {
                0xF7, 0x40, 0x04, 0x00, 0x00, 0x02, 0x00,
                0x0F, 0x84, 0x94, 0x04, 0x00, 0x00
            },
            panchan_aesthetic_nops(13)
        )
    }

    rt.fixed_seed_table = ffi.new("unsigned char[512]")
    for seed_index = 0, 511 do
        rt.fixed_seed_table[seed_index] = seed_index % 256
    end

    rt.fixed_seed_address = tonumber(ffi.cast(
        "uintptr_t",
        ffi.cast("void*", rt.fixed_seed_table)
    ))

    if rt.fixed_seed_address ~= nil
        and rt.fixed_seed_address >= 0
        and rt.fixed_seed_address <= 0xFFFFFFFF then
        rt.groups.hitscan = {
            sample = {
                panchan_aesthetic_cmp_imm32("Hitscan samples A", 0x4333278D, 0xFF, 0x80),
                panchan_aesthetic_cmp_imm32("Hitscan samples B", 0x4333285D, 0xF9, 0x80)
            },
            seed = {
                panchan_aesthetic_disp32("Hitscan seed A", 0x433326CF, {0x0F, 0xB6, 0x88}, 0x4346FC50),
                panchan_aesthetic_disp32("Hitscan seed B", 0x4333273E, {0x0F, 0xB6, 0x87}, 0x4346FC50),
                panchan_aesthetic_disp32("Hitscan seed C", 0x433327B3, {0x0F, 0xB6, 0x91}, 0x4346FC50),
                panchan_aesthetic_disp32("Hitscan seed D", 0x4333281F, {0x0F, 0xB6, 0x80}, 0x4346FC50)
            },
            percent = {
                panchan_aesthetic_push_imm8("Hitscan percent cap", 0x43332890, 0x64)
            },
            hitbox = {
                panchan_aesthetic_push_imm8("Hitscan hitbox cap A", 0x433337EA, 0x13),
                panchan_aesthetic_push_imm8("Hitscan hitbox cap B", 0x43333C88, 0x13)
            },
            mask = {
                panchan_aesthetic_mov_esi_imm32("Hitscan mask", 0x43333349, 0xCA)
            },
            distance = {
                panchan_aesthetic_fixed_patch("Hitscan distance A", 0x43333078, {0x76, 0x27}, {0xEB, 0x27}),
                panchan_aesthetic_fixed_patch("Hitscan distance B", 0x433330A8, {0x76, 0x0D}, {0xEB, 0x0D})
            }
        }
    else
        panchan_aesthetic_log_once("hitscan_seed", "Hitscan fixed seed address is unavailable")
    end

    rt.initialized = true
    return true
end

function ragebot_improved_hitscan_restore()
    local groups = ragebot_improved_runtime.groups.hitscan
    if groups == nil then
        return
    end

    panchan_aesthetic_group_restore(groups.distance)
    panchan_aesthetic_group_restore(groups.mask)
    panchan_aesthetic_group_restore(groups.hitbox)
    panchan_aesthetic_group_restore(groups.percent)
    panchan_aesthetic_group_restore(groups.sample)
    panchan_aesthetic_group_restore(groups.seed)
end

function ragebot_improved_hitscan_samples()
    local state = ragebot_improved_runtime.hitscan
    if ref.fd ~= nil and ui.get(ref.fd) then
        return 128
    end
    if state.airborne == true or (state.post_landing_ticks or 0) > 0 then
        return 256
    end
    return ui.get(ragebot_hitscan_sample_count) or 512
end

function ragebot_improved_hitscan_update()
    local groups = ragebot_improved_runtime.groups.hitscan
    if groups == nil then
        return
    end

    if not ragebot_improved_enabled("Hitscan Fix") then
        ragebot_improved_hitscan_restore()
        return
    end

    local samples = ragebot_improved_hitscan_samples()
    panchan_aesthetic_group_apply(groups.seed, ragebot_improved_runtime.fixed_seed_address)
    panchan_aesthetic_group_apply(groups.sample, samples)
    panchan_aesthetic_group_apply(groups.percent, ui.get(ragebot_hitscan_percent_cap) or 76)
    panchan_aesthetic_group_apply(groups.hitbox, ui.get(ragebot_hitscan_hitbox_cap) or 18)
    panchan_aesthetic_group_apply(groups.mask, ui.get(ragebot_hitscan_hitbox_mask) or 255)
    panchan_aesthetic_group_apply(groups.distance, true)
    ragebot_improved_runtime.hitscan.last_sample_count = samples
end

function ragebot_improved_jump_update()
    local should_patch = false
    if ragebot_improved_enabled("Jump Scout Fix") then
        local lp = entity.get_local_player()
        should_patch = lp ~= nil
            and lp ~= 0
            and entity.is_alive(lp)
            and entity.get_prop(lp, "m_bIsScoped") == 1
    end

    if should_patch then
        panchan_aesthetic_group_apply(ragebot_improved_runtime.groups.jump, true)
    else
        panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.jump)
    end
end

function ragebot_improved_apply()
    if not ragebot_improved_any_enabled() then
        ragebot_improved_restore()
        return
    end
    if not ragebot_improved_initialize() then
        return
    end

    if ragebot_improved_enabled("Delay Shot Fix") then
        panchan_aesthetic_group_apply(ragebot_improved_runtime.groups.delay, true)
    else
        panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.delay)
    end

    if ragebot_improved_enabled("BT Fix") then
        ragebot_improved_runtime.bt_distance_squared[0] = 512 * 512
        panchan_aesthetic_group_apply(ragebot_improved_runtime.groups.bt, true)
    else
        panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.bt)
    end

    ragebot_improved_jump_update()
    ragebot_improved_hitscan_update()
end

function ragebot_improved_setup_command(cmd)
    local lp = entity.get_local_player()
    local state = ragebot_improved_runtime.hitscan
    local airborne = false

    if lp ~= nil and entity.is_alive(lp) then
        local flags = entity.get_prop(lp, "m_fFlags") or 0
        airborne = bit.band(flags, 1) == 0
    end

    if airborne or state.airborne == true then
        state.post_landing_ticks = 4
    end
    state.airborne = airborne

    ragebot_improved_apply()

    if not airborne and state.post_landing_ticks > 0 then
        state.post_landing_ticks = state.post_landing_ticks - 1
    end
end

function ragebot_improved_restore()
    if not ragebot_improved_runtime.initialized then
        return
    end

    panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.delay)
    panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.bt)
    panchan_aesthetic_group_restore(ragebot_improved_runtime.groups.jump)
    ragebot_improved_hitscan_restore()
end

function ragebot_improved_reset_feedback()
    ragebot_improved_runtime.hitscan.airborne = nil
    ragebot_improved_runtime.hitscan.post_landing_ticks = 0
    ragebot_improved_runtime.hitscan.last_sample_count = nil
end
---@skeet_elements_hider_end

---@hitlogs
local taps = 0
local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}
local fireData = {}
hirate_shots = 0
hirate_hits = 0
hirate_headshots = 0

-- Three independent resolver helpers share one player-list writer so they do not
-- undo each other's overrides when more than one checkbox is enabled.
resolver_runtime = {
    jitter = {},
    defensive = {},
    lagcomp = {},
    shots = {},
    owned = {},
    learn = {}
}

resolver_fields = {
    "Correction active",
    "Force body yaw",
    "Force body yaw value",
    "Force pitch",
    "Force pitch value",
    "High priority"
}

function resolver_clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function resolver_snap_body_yaw(value)
    value = math.abs(value or 0)
    if value >= 57.25 then
        local snapped = math.floor(value + 0.5)
        if snapped < 58 then snapped = 58 end
        if snapped > 60 then snapped = 60 end
        return snapped
    end

    return resolver_clamp(math.floor(value + 0.5), 18, 60)
end

function resolver_resolve_body_amount(state, fallback_side, fallback_amplitude)
    if state == nil then
        return 0
    end

    local amount = state.amount or state.spike_hold_amount or state.learned_amount
    if amount ~= nil and math.abs(amount) >= 8 then
        local side = amount >= 0 and 1 or -1
        return side * resolver_snap_body_yaw(amount)
    end

    local side = state.resolved_side or fallback_side or 1
    side = side == -1 and -1 or 1
    local amplitude = resolver_snap_body_yaw(state.amplitude or fallback_amplitude or 60)
    return side * amplitude
end

function resolver_pick_body_side(state, delta, pose_signed, lby_delta)
    local vote = 0
    local now = globals.realtime()

    if delta ~= nil and math.abs(delta) >= 2 then
        vote = vote + (delta > 0 and -2.4 or 2.4)
    end
    if pose_signed ~= nil and math.abs(pose_signed) >= 12 then
        vote = vote + (pose_signed > 0 and -1.55 or 1.55)
    end
    if lby_delta ~= nil and math.abs(lby_delta) >= 10 then
        vote = vote + (lby_delta > 0 and -1.25 or 1.25)
    end
    if state.amount ~= nil and math.abs(state.amount) >= 8 then
        vote = vote + (state.amount > 0 and 0.55 or -0.55)
    end
    if state.hit_side ~= nil and (state.hit_side_until or 0) > now then
        vote = vote + state.hit_side * 1.35
    end

    state.side_score = resolver_clamp((state.side_score or 0) * 0.72 + vote, -12, 12)
    local proposed = state.side_score >= 0 and 1 or -1
    local recent_switch = (state.side_switched_at or 0) + 0.75 > now
    local miss_pressure = resolver_clamp((state.misses or 0) * 0.5, 0, 2)
    local confidence_lock = resolver_clamp((state.confidence or 0) * 0.08, 0, 1.1)
    if state.resolved_side == nil then
        state.resolved_side = proposed
        state.side_candidate = nil
        state.side_candidate_count = 0
    elseif proposed == state.resolved_side then
        state.side_candidate = nil
        state.side_candidate_count = 0
    elseif math.abs(state.side_score) >= 1.2 then
        if state.side_candidate == proposed then
            state.side_candidate_count = (state.side_candidate_count or 0) + 1
        else
            state.side_candidate = proposed
            state.side_candidate_count = 1
        end

        local confirmations = math.abs(state.side_score) >= 5.5 and 1 or ((state.confidence or 0) >= 7 and 3 or 2)
        if recent_switch then
            confirmations = confirmations + 1
        end
        confirmations = math.max(1, math.floor(confirmations + confidence_lock - miss_pressure + 0.5))
        if state.side_candidate_count >= confirmations then
            state.resolved_side = proposed
            state.side_candidate = nil
            state.side_candidate_count = 0
            state.side_switched_at = now
        end
    end

    return state.resolved_side or (delta ~= nil and (delta > 0 and -1 or 1) or 1)
end

function resolver_jitter_history_stats(history)
    local count = history and #history or 0
    if count <= 0 then
        return {
            count = 0,
            average = 0,
            variance = 0,
            flips = 0,
            alternating_ratio = 0,
            max_delta = 0,
            min_delta = 0,
            median = 0,
            trimmed_average = 0,
            return_ratio = 0,
            sign_balance = 0
        }
    end

    local average, flips, returns, positives, negatives, max_delta, min_delta = 0, 0, 0, 0, 0, 0, 180
    local magnitudes = {}
    for i = 1, count do
        local value = math.abs(history[i])
        magnitudes[i] = value
        average = average + value
        max_delta = math.max(max_delta, value)
        min_delta = math.min(min_delta, value)
        if history[i] > 0 then positives = positives + 1 else negatives = negatives + 1 end
        if i > 1 and history[i] * history[i - 1] < 0 then
            flips = flips + 1
        end
        if i > 2 and history[i] * history[i - 1] < 0 then
            local previous_magnitude = math.abs(history[i - 2])
            if previous_magnitude > 0 and math.abs(value - previous_magnitude) <= math.max(10, previous_magnitude * 0.32) then
                returns = returns + 1
            end
        end
    end

    average = average / count
    table.sort(magnitudes)
    local middle = math.floor((count + 1) * 0.5)
    local median = count % 2 == 0 and (magnitudes[middle] + magnitudes[middle + 1]) * 0.5 or magnitudes[middle]
    local trimmed_total, trimmed_count = 0, 0
    local trim = count >= 6 and 1 or 0
    for i = 1 + trim, count - trim do
        trimmed_total = trimmed_total + magnitudes[i]
        trimmed_count = trimmed_count + 1
    end
    local trimmed_average = trimmed_count > 0 and trimmed_total / trimmed_count or average

    local variance = 0
    for i = 1, count do
        variance = variance + math.abs(math.abs(history[i]) - median)
    end
    variance = variance / count

    return {
        count = count,
        average = average,
        variance = variance,
        flips = flips,
        alternating_ratio = count > 1 and flips / (count - 1) or 0,
        max_delta = max_delta,
        min_delta = min_delta,
        median = median,
        trimmed_average = trimmed_average,
        return_ratio = count > 2 and returns / (count - 2) or 0,
        sign_balance = math.min(positives, negatives) / math.max(positives, negatives, 1)
    }
end

function resolver_jitter_amplitude(body_pose, stats, delta_abs, speed_2d, fake_flick_detected)
    local pose_weight = speed_2d <= 90 and 0.66 or 0.48
    local delta_weight = fake_flick_detected and 0.42 or 0.34
    local history_weight = stats.count >= 4 and 0.28 or 0.18
    local history_amplitude = stats.trimmed_average or stats.median or stats.average
    local raw = (body_pose * pose_weight) + (delta_abs * delta_weight) + (history_amplitude * history_weight)

    if body_pose >= 57.25 then
        raw = math.max(raw, body_pose)
    end
    if fake_flick_detected then
        raw = math.max(raw, delta_abs * 0.5, body_pose)
    end
    if stats.alternating_ratio >= 0.72 and stats.variance <= math.max(16, stats.average * 0.36) then
        raw = math.max(raw, stats.average * 0.72)
    end

    return resolver_snap_body_yaw(raw)
end

function resolver_jitter_pattern_valid(stats, delta_abs, body_pose, speed_2d)
    local count = stats and stats.count or 0
    if count < 2 then
        return false, false, false, 0
    end

    local average = stats.average or 0
    local variance = stats.variance or 0
    local alternating_ratio = stats.alternating_ratio or 0
    local spread = math.max(0, (stats.max_delta or 0) - (stats.min_delta or 0))
    local enough_history = count >= (delta_abs >= 28 and 3 or 4)
    local tight_range = spread <= math.max(18, average * 0.42)
    local stable_range = variance <= math.max(14, average * 0.4)
    local strong_pose = body_pose >= 46 and speed_2d <= 110
    local return_ratio = stats.return_ratio or 0
    local sign_balance = stats.sign_balance or 0
    local strong_pattern = alternating_ratio >= 0.72 and return_ratio >= 0.45 and sign_balance >= 0.5 and count >= 4 and tight_range
    local micro_consistent = average >= 6 and average <= 28 and alternating_ratio >= 0.58 and sign_balance >= 0.35 and count >= 4 and stable_range
    local low_noise = variance <= math.max(8, average * 0.28)
    local valid_pattern = (strong_pattern or (enough_history and alternating_ratio >= 0.42) or strong_pose or micro_consistent) and stable_range
    local quality = 0
    quality = quality + resolver_clamp(alternating_ratio * 4, 0, 4)
    quality = quality + resolver_clamp(return_ratio * 3, 0, 3)
    quality = quality + resolver_clamp(sign_balance * 2, 0, 2)
    quality = quality + resolver_clamp((1 - (variance / math.max(average, 1))) * 1.5, 0, 1.5)
    if tight_range then quality = quality + 1 end
    if low_noise then quality = quality + 0.75 end
    if micro_consistent then quality = quality + 1.25 end
    if strong_pose then quality = quality + 1 end
    quality = resolver_clamp(quality, 0, 10)

    return valid_pattern, strong_pattern, tight_range, quality
end

function resolver_pattern_stability(stats, delta_abs, body_pose, speed_2d)
    if stats == nil or (stats.count or 0) < 2 then
        return 0
    end

    local average = math.max(stats.average or 0, 1)
    local variance = stats.variance or 0
    local spread = math.max(0, (stats.max_delta or 0) - (stats.min_delta or 0))
    local stability = 0

    stability = stability + resolver_clamp((stats.alternating_ratio or 0) * 3.2, 0, 3.2)
    stability = stability + resolver_clamp((stats.return_ratio or 0) * 2.3, 0, 2.3)
    stability = stability + resolver_clamp((stats.sign_balance or 0) * 1.7, 0, 1.7)
    stability = stability + resolver_clamp((1 - variance / average) * 1.8, 0, 1.8)
    stability = stability + resolver_clamp((1 - spread / math.max(average * 1.15, 18)) * 1.4, 0, 1.4)

    if body_pose >= 42 and speed_2d <= 115 then
        stability = stability + 1.1
    elseif body_pose >= 18 and delta_abs >= 14 then
        stability = stability + 0.55
    end

    return resolver_clamp(stability, 0, 10)
end

function resolver_jitter_signal_type(stats, body_pose, delta_abs, fake_flick_detected)
    if fake_flick_detected then
        return "FAKE FLICK"
    end
    if body_pose >= 57.25 then
        return "BODY 60"
    end
    if stats.alternating_ratio >= 0.72 and stats.max_delta >= 74 then
        return "SKITTER"
    end
    if stats.alternating_ratio >= 0.55 and stats.average <= 58 and body_pose <= 32 then
        return "CENTRE"
    end
    if delta_abs >= 24 or body_pose >= 38 then
        return "OFFSET"
    end
    return "MICRO"
end

function resolver_commit_body_yaw_lock(state, side, amplitude, hold_time, jitter_type)
    local now = globals.realtime()
    amplitude = resolver_snap_body_yaw(amplitude or state.amplitude or 60)
    side = side == -1 and -1 or 1
    local same_side = state.last_commit_side ~= nil and state.last_commit_side == side
    local amplitude_close = state.last_committed_amplitude ~= nil and math.abs(state.last_committed_amplitude - amplitude) <= 10
    local stickiness = same_side and amplitude_close and 0.35 or 0

    state.body_lock_score = resolver_clamp((state.body_lock_score or 0) * 0.74 + side + (side * stickiness), -4.5, 4.5)
    if math.abs(state.body_lock_score) >= 0.65 then
        side = state.body_lock_score >= 0 and 1 or -1
        state.resolved_side = side
    end

    if same_side and amplitude_close then
        hold_time = hold_time + resolver_clamp((state.confidence or 0) * 0.018, 0.12, 0.25)
    end

    state.amplitude = amplitude
    state.detected_until = now + hold_time
    state.active_until = math.max(state.active_until or 0, state.detected_until)
    state.jitter_type = jitter_type or "OFFSET"
    state.jitter_type_until = now + 1.25
    state.last_commit_side = side
    state.last_committed_amplitude = amplitude

    if (state.feedback_step or 0) == 0 or math.abs(state.amount or 0) < 8 then
        state.amount = side * amplitude
        state.spike_hold_amount = state.amount
    end
end

function resolver_decay_jitter_state(state, now)
    local last_decay = state.last_confidence_decay or now
    local elapsed = math.max(0, now - last_decay)
    state.last_confidence_decay = now

    if elapsed > 0 and (state.detected_until or 0) <= now and (state.feedback_until or 0) <= now and (state.spike_until or 0) <= now then
        state.confidence = math.max((state.confidence or 0) - elapsed * 1.15, 0)
    end

    if (state.last_observation_at or 0) + 2.25 < now then
        state.side_score = (state.side_score or 0) * 0.92
        state.body_lock_score = (state.body_lock_score or 0) * 0.92
        state.side_candidate = nil
        state.side_candidate_count = 0
    end

    if resolver_matrix_decay ~= nil then
        resolver_matrix_decay(state, now)
    end
end

function resolver_body_yaw_meta(state, body_pose, body_pose_signed, lby_delta, speed_2d)
    local now = globals.realtime()
    local high_body = body_pose >= 54 and speed_2d <= 135
    local near_meta = body_pose >= 57.25 and body_pose <= 60.5

    if not high_body then
        return false
    end

    local side = resolver_pick_body_side(state, nil, body_pose_signed, lby_delta)
    local amplitude = near_meta and resolver_snap_body_yaw(body_pose) or resolver_snap_body_yaw(math.max(body_pose, 58))
    local confidence_boost = near_meta and 3 or 2

    state.confidence = math.min((state.confidence or 0) + confidence_boost, 10)
    resolver_commit_body_yaw_lock(state, side, amplitude, near_meta and 1.05 or 0.75, near_meta and "BODY 60" or "OFFSET")
    state.meta_body_until = now + 1.2
    return true
end

function resolver_learn_key(idx)
    if entity.get_steam64 ~= nil then
        local ok, steam64 = pcall(entity.get_steam64, idx)
        if ok and steam64 ~= nil and tostring(steam64) ~= "0" then
            return "steam:" .. tostring(steam64)
        end
    end

    return "name:" .. string.lower(entity.get_player_name(idx) or tostring(idx))
end

function resolver_learn_bucket(amount)
    amount = amount or 0
    if math.abs(amount) < 8 then
        return 0
    end

    local side = amount >= 0 and 1 or -1
    return side * resolver_snap_body_yaw(amount)
end

function resolver_learn_feedback(idx, amount, hit)
    if idx == nil or amount == nil then
        return
    end

    local key = resolver_learn_key(idx)
    local learn = resolver_runtime.learn[key] or { values = {}, best = nil }
    local bucket = resolver_learn_bucket(amount)
    local entry = learn.values[bucket] or { score = 0, hits = 0, misses = 0 }

    if hit then
        entry.hits = entry.hits + 1
        entry.score = entry.score + 2.25
    else
        entry.misses = entry.misses + 1
        entry.score = entry.score - 1.35
    end

    entry.score = resolver_clamp(entry.score, -5, 10)
    learn.values[bucket] = entry

    local best_bucket, best_score = nil, -999
    for learned_bucket, learned_entry in pairs(learn.values) do
        if learned_entry.score > best_score then
            best_bucket, best_score = learned_bucket, learned_entry.score
        end
    end

    if best_bucket ~= nil and best_score >= 2.5 then
        learn.best = best_bucket
        learn.best_score = best_score
    else
        learn.best = nil
        learn.best_score = nil
    end

    resolver_runtime.learn[key] = learn
end

-- The matrix keeps resolver feedback local to the current enemy instead of
-- blindly walking the same fixed angle list after every miss.
function resolver_matrix_normalize_amount(value)
    value = tonumber(value)
    if value == nil or math.abs(value) < 8 then
        return 0
    end

    local side = value >= 0 and 1 or -1
    return side * resolver_snap_body_yaw(math.abs(value))
end

function resolver_matrix_key(value)
    return tostring(resolver_matrix_normalize_amount(value))
end

function resolver_matrix_get(state)
    state.matrix = state.matrix or {
        cells = {},
        stage = 0,
        last_decay = globals.realtime(),
        last_feedback = 0,
        last_success_amount = nil,
        last_reason = "scan"
    }
    return state.matrix
end

function resolver_matrix_cell(matrix, amount)
    amount = resolver_matrix_normalize_amount(amount)
    local key = resolver_matrix_key(amount)
    local cell = matrix.cells[key]

    if cell == nil then
        cell = {
            amount = amount,
            score = 0,
            hits = 0,
            misses = 0,
            last_used = 0,
            last_result = 0
        }
        matrix.cells[key] = cell
    end

    return cell, key
end

function resolver_matrix_decay(state, now)
    local matrix = state and state.matrix
    if matrix == nil then
        return
    end

    local elapsed = math.max(0, now - (matrix.last_decay or now))
    matrix.last_decay = now
    if elapsed <= 0 then
        return
    end

    for key, cell in pairs(matrix.cells) do
        cell.score = cell.score * math.max(0, 1 - elapsed * 0.035)
        if (cell.last_used or 0) + 24 < now and math.abs(cell.score or 0) < 0.12 then
            matrix.cells[key] = nil
        end
    end
end

function resolver_matrix_feedback(state, amount, hit, weight)
    if state == nil or amount == nil then
        return
    end

    local matrix = resolver_matrix_get(state)
    local cell, key = resolver_matrix_cell(matrix, amount)
    local now = globals.realtime()
    weight = resolver_clamp(tonumber(weight) or 1, 0.25, 1.5)

    if hit then
        cell.hits = (cell.hits or 0) + 1
        cell.score = resolver_clamp((cell.score or 0) + 2.8 * weight, -7, 12)
        cell.last_result = 1
        matrix.last_success_amount = cell.amount
    else
        cell.misses = (cell.misses or 0) + 1
        cell.score = resolver_clamp((cell.score or 0) - 1.45 * weight, -7, 12)
        cell.last_result = -1
    end

    cell.last_used = now
    matrix.last_feedback = now
    matrix.last_key = key
end

function resolver_matrix_candidates(state, shot)
    local amplitude = resolver_snap_body_yaw((shot and shot.amplitude) or state.amplitude or 60)
    local side = (shot and shot.side) or state.resolved_side or 1
    side = side == -1 and -1 or 1
    local shot_amount = (shot and shot.amount) or state.amount or (side * amplitude)
    local current_amount = resolver_matrix_normalize_amount(shot_amount)
    local alternate_amplitude = resolver_snap_body_yaw(math.max(24, amplitude - 4))
    local micro_amplitude = resolver_snap_body_yaw(math.max(18, math.min(34, amplitude * 0.58)))
    local values = {}
    local seen = {}

    local function push(value)
        value = resolver_matrix_normalize_amount(value)
        local key = resolver_matrix_key(value)
        if not seen[key] then
            seen[key] = true
            values[#values + 1] = value
        end
    end

    -- The opposite of the fired amount is always tried first, then the
    -- amplitude alternatives observed by the current jitter pattern.
    push(-current_amount)
    push(-side * amplitude)
    push(side * amplitude)

    if state.learned_amount ~= nil then
        push(state.learned_amount)
        push(-state.learned_amount)
    end

    push(side * alternate_amplitude)
    push(-side * alternate_amplitude)
    push(side * micro_amplitude)
    push(-side * micro_amplitude)
    push(0)

    return values, current_amount
end

function resolver_matrix_select(state, shot, filter)
    local matrix = resolver_matrix_get(state)
    local values, failed_amount = resolver_matrix_candidates(state, shot)
    local failed_key = resolver_matrix_key(failed_amount)
    local now = globals.realtime()
    local selected, selected_score = nil, -99999

    for i = 1, #values do
        local candidate = values[i]
        local cell, key = resolver_matrix_cell(matrix, candidate)
        local score = (cell.score or 0) * 2.15 + (#values - i) * 0.16

        if key == failed_key then
            score = score - 5.5
        end
        if (cell.last_used or 0) + 0.85 > now then
            score = score - 2.35
        end
        if matrix.last_success_amount ~= nil and candidate == matrix.last_success_amount then
            score = score + 0.7
        end
        if state.hit_side ~= nil and (state.hit_side_until or 0) > now and candidate ~= 0 then
            score = score + ((candidate >= 0 and 1 or -1) == state.hit_side and 0.4 or -0.25)
        end
        if candidate == 0 and (state.confidence or 0) >= 4 then
            score = score - 0.45
        end

        if selected == nil or score > selected_score then
            selected = candidate
            selected_score = score
        end
    end

    selected = selected or (-failed_amount)
    local selected_cell = resolver_matrix_cell(matrix, selected)
    selected_cell.last_used = now
    matrix.stage = (matrix.stage or 0) + 1
    matrix.last_selected_amount = selected
    matrix.last_reason = filter and filter.category or "resolver"

    return selected
end

function resolver_matrix_best(state)
    local matrix = state and state.matrix
    local now = globals.realtime()
    if matrix == nil or (matrix.last_feedback or 0) + 10 < now then
        return nil
    end

    local amount, score = nil, 2.75
    for _, cell in pairs(matrix.cells) do
        if (cell.score or 0) > score and (cell.hits or 0) > (cell.misses or 0) then
            amount = cell.amount
            score = cell.score
        end
    end

    return amount
end

function resolver_apply_learned(idx, state)
    local matrix_amount = resolver_matrix_best(state)
    if matrix_amount ~= nil then
        local now = globals.realtime()
        if (state.feedback_until or 0) <= now and ((state.detected_until or 0) <= now or (state.confidence or 0) < 4) then
            state.amount = matrix_amount
            state.amplitude = math.abs(matrix_amount)
            state.resolved_side = matrix_amount >= 0 and 1 or -1
            state.learned_amount = matrix_amount
            state.learned_until = now + 0.8
            state.learned = true
            state.confidence = math.max(state.confidence or 0, 3.5)
            state.detected_until = math.max(state.detected_until or 0, now + 0.35)
            state.active_until = math.max(state.active_until or 0, now + 0.35)
            return
        end
    end

    local now = globals.realtime()
    if (state.feedback_until or 0) > now or ((state.detected_until or 0) > now and (state.confidence or 0) >= 4) then
        return
    end

    local learn = resolver_runtime.learn[resolver_learn_key(idx)]
    if learn ~= nil and learn.best ~= nil and (learn.best_score or 0) >= 2.5 then
        state.amount = learn.best
        state.amplitude = math.abs(learn.best)
        state.resolved_side = learn.best >= 0 and 1 or -1
        state.learned_amount = learn.best
        state.learned_until = now + 1.25
        state.learned = true
        state.confidence = math.max(state.confidence or 0, resolver_clamp((learn.best_score or 0) * 0.65, 2, 6.5))
        state.detected_until = math.max(state.detected_until or 0, now + 0.45)
        state.active_until = math.max(state.active_until or 0, now + 0.45)
        return
    end
end

function miss_filter_classify(e, target)
    local reason = string.lower(tostring(e and e.reason or "unknown"))
    local stored = e and e.id and fireData[e.id] or nil
    local info = {
        reason = reason == "?" and "unknown" or reason,
        category = "resolver",
        resolver_feedback = true,
        learn_feedback = true,
        cycle_feedback = true,
        matrix_feedback = true,
        matrix_weight = 1,
        lagcomp_feedback = false,
        dormant_feedback = false
    }

    if target == nil or target < 1 then
        info.category = "unknown"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
        return info
    end

    local target_alive = entity.is_alive(target)
    local target_dormant = entity.is_dormant(target)
    local teleported = (e and e.teleported) or (stored and stored.teleported)
    local extrapolated = (e and e.extrapolated) or (stored and stored.extrapolated)
    local interpolated = (e and e.interpolated) or (stored and stored.interpolated)

    if not target_alive or reason:find("death", 1, true) then
        info.category = "death"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
    elseif reason:find("spread", 1, true) then
        info.category = "spread"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
    elseif reason:find("occlusion", 1, true) or reason:find("wall", 1, true) then
        info.category = "occlusion"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
    elseif target_dormant or reason:find("dormant", 1, true) then
        info.category = "dormant"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
        info.dormant_feedback = true
    elseif teleported or extrapolated or reason:find("lagcomp", 1, true) or reason:find("prediction error", 1, true) then
        info.category = "lagcomp"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
        info.lagcomp_feedback = true
    elseif reason:find("prediction", 1, true) or interpolated then
        info.category = "prediction"
        info.resolver_feedback = false
        info.learn_feedback = false
        info.cycle_feedback = false
        info.matrix_feedback = false
    elseif reason:find("resolver", 1, true) or reason == "unknown" or reason == "" then
        info.category = "resolver"
    else
        info.category = "resolver"
    end

    local hit_chance = tonumber((e and e.hit_chance) or (stored and stored.hit_chance))
    if info.matrix_feedback and hit_chance ~= nil then
        if hit_chance < 55 then
            info.category = "low hc"
            info.resolver_feedback = false
            info.learn_feedback = false
            info.cycle_feedback = false
            info.matrix_feedback = false
        elseif hit_chance < 70 then
            info.matrix_weight = 0.6
        elseif (e and e.high_priority) or (stored and stored.high_priority) then
            info.matrix_weight = 0.8
        end
    end

    return info
end

function miss_filter_format_reason(e, filter)
    local raw = tostring(e and e.reason or "unknown")
    raw = raw == "?" and "unknown" or string.lower(raw)

    local category = filter and filter.category or "unknown"
    category = category == "" and "unknown" or tostring(category)

    if category == "low hc" then
        return "unknown"
    end

    if raw == "" or raw == "unknown" then
        return category
    end

    if raw == category then
        return category
    end

    if category == "resolver" and raw:find("resolver", 1, true) then
        return "resolver"
    end

    if category == "death" or category == "spread" or category == "dormant" or category == "lagcomp" or category == "prediction" or category == "occlusion" then
        return category
    end

    return raw
end

function resolver_plist_get(idx, field)
    if plist == nil or plist.get == nil then
        return false, nil
    end

    return pcall(plist.get, idx, field)
end

function resolver_plist_set(idx, field, value)
    if plist == nil or plist.set == nil then
        return false
    end

    return pcall(plist.set, idx, field, value)
end

function resolver_capture_player(idx)
    if resolver_runtime.owned[idx] ~= nil then
        return
    end

    local snapshot = {}
    for i = 1, #resolver_fields do
        local field = resolver_fields[i]
        local ok, value = resolver_plist_get(idx, field)
        snapshot[field] = {valid = ok, value = value}
    end
    resolver_runtime.owned[idx] = snapshot
end

function resolver_restore_player(idx)
    local snapshot = resolver_runtime.owned[idx]
    if snapshot == nil then
        return
    end

    for i = 1, #resolver_fields do
        local field = resolver_fields[i]
        local saved = snapshot[field]
        if saved ~= nil and saved.valid then
            resolver_plist_set(idx, field, saved.value)
        end
    end
    resolver_runtime.owned[idx] = nil
end

function adaptive_ping_spike_enabled()
    return adaptive_ping_spike ~= nil and ui.get(jitter_correction) and ui.get(adaptive_ping_spike)
end

function adaptive_ping_spike_latency_ms()
    local latency = client.latency ~= nil and client.latency() or 0
    return math.floor((latency or 0) * 1000 + 0.5)
end

function adaptive_ping_spike_update_state(state, simtime, tickinterval)
    if not adaptive_ping_spike_enabled() then
        state.spike_until = 0
        state.spike_hold_amount = nil
        state.spike_reason = nil
        state.spike_strength = nil
        return false
    end

    local now = globals.realtime()
    local ping_ms = adaptive_ping_spike_latency_ms()
    local baseline = state.ping_baseline or ping_ms
    local ping_delta = math.abs(ping_ms - (state.last_ping_ms or ping_ms))
    local ping_spike = (ping_ms - baseline >= 18) or ping_delta >= 22
    local sim_spike = false

    if state.simtime ~= nil and simtime ~= nil and tickinterval ~= nil and tickinterval > 0 then
        local sim_delta = simtime - state.simtime
        local sim_ticks = math.floor((sim_delta / tickinterval) + 0.5)
        sim_spike = sim_delta < -(tickinterval * 0.5) or sim_ticks > 3
    end

    if ping_spike or sim_spike then
        local duration = sim_spike and 1.05 or 0.7
        local hold_amount = resolver_resolve_body_amount(state, nil, 60)
        state.spike_until = math.max(state.spike_until or 0, now + duration)
        state.spike_hold_amount = hold_amount
        state.amount = hold_amount
        state.amplitude = resolver_snap_body_yaw(math.abs(hold_amount))
        state.feedback_step = 0
        state.feedback_until = 0
        state.active_until = math.max(state.active_until or 0, state.spike_until)
        state.spike_reason = sim_spike and "simtime" or "ping"
        state.spike_strength = sim_spike and 5 or 4
        state.spike_ping_ms = ping_ms
    end

    state.ping_baseline = baseline * 0.88 + ping_ms * 0.12
    state.last_ping_ms = ping_ms
    return (state.spike_until or 0) > now
end

function adaptive_ping_spike_mark_state(state, duration, reason, strength)
    if not adaptive_ping_spike_enabled() or state == nil then
        return false
    end

    local now = globals.realtime()
    local hold_amount = resolver_resolve_body_amount(state, nil, 60)
    state.spike_until = math.max(state.spike_until or 0, now + duration)
    state.spike_hold_amount = hold_amount
    state.amount = hold_amount
    state.amplitude = resolver_snap_body_yaw(math.abs(hold_amount))
    state.feedback_step = 0
    state.feedback_until = 0
    state.active_until = math.max(state.active_until or 0, state.spike_until)
    state.detected_until = math.max(state.detected_until or 0, now + math.min(duration, 0.45))
    state.confidence = math.max(state.confidence or 0, strength or 4)
    state.spike_reason = reason
    state.spike_strength = strength or 4
    state.spike_ping_ms = adaptive_ping_spike_latency_ms()
    return true
end

function adaptive_ping_spike_hold_state(state)
    if not adaptive_ping_spike_enabled() or (state.spike_until or 0) <= globals.realtime() then
        return false
    end

    if state.spike_hold_amount == nil then
        state.spike_hold_amount = resolver_resolve_body_amount(state, nil, 60)
    end

    if state.spike_hold_amount ~= nil and (state.feedback_step or 0) == 0 then
        state.amount = state.spike_hold_amount
        state.amplitude = resolver_snap_body_yaw(math.abs(state.amount))
        state.confidence = math.max(state.confidence or 0, state.spike_strength or 4)
        state.detected_until = math.max(state.detected_until or 0, globals.realtime() + 0.35)
        state.active_until = math.max(state.active_until or 0, state.spike_until or 0, globals.realtime() + 0.35)
    end

    return true
end

function resolver_abstain_gate(state, candidate, now, spike_active)
    now = now or globals.realtime()
    candidate = resolver_matrix_normalize_amount(candidate)
    state.gate_mode = "PASS"
    state.gate_amount = nil

    if math.abs(candidate) < 8 then
        state.gate_score = 0
        return false, 0, "PASS"
    end

    if spike_active then
        state.gate_mode = "APPLY"
        state.gate_reason = "spike"
        state.gate_amount = candidate
        state.gate_score = 12
        return true, candidate, "APPLY"
    end

    if (state.gate_native_until or 0) > now then
        state.gate_reason = "native hit"
        state.gate_score = 0
        return false, 0, "PASS"
    end

    if (state.gate_abstain_until or 0) > now then
        state.gate_reason = "contradiction cooldown"
        state.gate_score = 0
        return false, 0, "PASS"
    elseif (state.gate_contradictions or 0) >= 3 then
        state.gate_contradictions = 2
    end

    local confidence = resolver_clamp(state.confidence or 0, 0, 12)
    local stability = resolver_clamp(state.pattern_stability or 0, 0, 10)
    local quality = resolver_clamp(state.last_pattern_quality or 0, 0, 10)
    local alternating = resolver_clamp(state.last_alternating_ratio or 0, 0, 1)
    local contradictions = resolver_clamp(state.gate_contradictions or 0, 0, 4)
    local misses = resolver_clamp(state.misses or 0, 0, 6)
    local recent_observation = (state.last_observation_at or 0) + 0.5 > now
    local meta_active = (state.meta_body_until or 0) > now
    local flick_active = (state.flick_until or 0) > now
    local learned_active = (state.learned_until or 0) > now and state.learned_amount ~= nil
    local trusted_active = (state.gate_trusted_until or 0) > now and math.abs(state.gate_hold_amount or 0) >= 8
    local probe_active = (state.gate_probe_until or 0) > now and (state.feedback_until or 0) > now

    if trusted_active then
        candidate = resolver_matrix_normalize_amount(state.gate_hold_amount)
    end

    local matrix = state.matrix
    local matrix_cell = matrix and matrix.cells and matrix.cells[resolver_matrix_key(candidate)] or nil
    local matrix_confirmed = matrix_cell ~= nil
        and (matrix_cell.score or 0) >= 2.5
        and (matrix_cell.hits or 0) > (matrix_cell.misses or 0)
        and (matrix_cell.last_used or 0) + 10 > now

    local evidence = confidence * 0.48 + stability * 0.24 + quality * 0.16 + alternating * 0.75
    if recent_observation then evidence = evidence + 0.55 end
    if meta_active then evidence = evidence + 1.65 end
    if flick_active then evidence = evidence + 1.1 end
    if learned_active then evidence = evidence + 0.65 end
    if matrix_confirmed then evidence = evidence + 1.2 end
    if trusted_active then evidence = evidence + 1.8 end
    if math.abs(candidate) >= 57.25 then evidence = evidence + 0.45 end

    local average = math.max(state.last_stats_average or 0, 1)
    if (state.last_stats_variance or 0) > math.max(18, average * 0.52) then
        evidence = evidence - 0.75
    end
    if not recent_observation and not meta_active and not flick_active and not trusted_active then
        evidence = evidence - 0.65
    end
    evidence = evidence - contradictions * 0.85 - math.max(misses - 1, 0) * 0.35
    evidence = resolver_clamp(evidence, 0, 12)
    state.gate_score = evidence

    if probe_active then
        state.gate_mode = "APPLY"
        state.gate_reason = "matrix probe"
        state.gate_amount = candidate
        return true, candidate, "APPLY"
    end

    local strong_flick = flick_active and ((state.flick_returned and confidence >= 1.5) or confidence >= 2.5)
    local strong_signal = trusted_active
        or (meta_active and confidence >= 3)
        or strong_flick
        or evidence >= 4.25
        or (matrix_confirmed and evidence >= 3.35)

    if strong_signal then
        state.gate_mode = "APPLY"
        state.gate_reason = trusted_active and "confirmed hit" or matrix_confirmed and "matrix" or meta_active and "body meta" or strong_flick and "fake flick" or "confidence"
        state.gate_amount = candidate
        state.gate_last_apply = now

        local trust_signal = trusted_active
            or matrix_confirmed
            or meta_active
            or strong_flick
            or (contradictions <= 0 and evidence >= 4.25)
            or (contradictions == 1 and evidence >= 5.5)
        if trust_signal then
            state.gate_hold_amount = candidate
            state.gate_hold_until = now + resolver_clamp(0.38 + confidence * 0.025, 0.42, 0.72)
        end
        return true, candidate, "APPLY"
    end

    local held = resolver_matrix_normalize_amount(state.gate_hold_amount)
    local can_hold = math.abs(held) >= 8
        and (state.gate_hold_until or 0) > now
        and contradictions < 2
        and evidence >= 2.15

    if can_hold then
        state.gate_mode = "HOLD"
        state.gate_reason = "uncertain"
        state.gate_amount = held
        return true, held, "HOLD"
    end

    state.gate_reason = contradictions >= 2 and "contradiction" or "low confidence"
    return false, 0, "PASS"
end

function resolver_apply_player(idx)
    local now = globals.realtime()
    local jitter = resolver_runtime.jitter[idx]
    local defensive = resolver_runtime.defensive[idx]
    local lagcomp = resolver_runtime.lagcomp[idx]
    local jitter_active = ui.get(jitter_correction) and jitter ~= nil and (jitter.active_until or 0) > now
    local spike_active = adaptive_ping_spike_enabled() and jitter ~= nil and (jitter.spike_until or 0) > now
    local body_yaw_active = jitter_active or spike_active
    local defensive_active = ui.get(defensive_correct) and defensive ~= nil and (defensive.active_until or 0) > now and defensive.pitch ~= nil
    local lagcomp_active = ui.get(resolver_lagcomp) and lagcomp ~= nil and (lagcomp.broken_until or 0) > now

    local body_yaw_value = 0
    local gate_mode = "PASS"
    if body_yaw_active and jitter ~= nil then
        body_yaw_value = resolver_resolve_body_amount(jitter, nil, 60)
        jitter.amount = body_yaw_value
        if math.abs(body_yaw_value) < 8 then
            body_yaw_active = false
        end
        if body_yaw_active then
            body_yaw_active, body_yaw_value, gate_mode = resolver_abstain_gate(jitter, body_yaw_value, now, spike_active)
        end
    end

    if jitter ~= nil and not body_yaw_active then
        jitter.gate_mode = "PASS"
        jitter.gate_amount = nil
        jitter.gate_reason = jitter.gate_reason or "inactive"
    end

    if not body_yaw_active and not defensive_active and not lagcomp_active then
        resolver_restore_player(idx)
        return
    end

    resolver_capture_player(idx)
    resolver_plist_set(idx, "Correction active", true)
    resolver_plist_set(idx, "Force body yaw", body_yaw_active)
    resolver_plist_set(idx, "Force body yaw value", body_yaw_active and body_yaw_value or 0)
    resolver_plist_set(idx, "Force pitch", defensive_active)
    resolver_plist_set(idx, "Force pitch value", defensive_active and defensive.pitch or 0)
    resolver_plist_set(idx, "High priority", lagcomp_active or spike_active or (body_yaw_active and gate_mode == "APPLY" and ((jitter.misses or 0) >= 2 or (jitter.confidence or 0) >= 5 or (jitter.amplitude or 0) >= 58 or (jitter.pattern_stability or 0) >= 7.5)))
end

function resolver_restore_all()
    local players = {}
    for idx in pairs(resolver_runtime.owned) do
        players[#players + 1] = idx
    end
    for i = 1, #players do
        resolver_restore_player(players[i])
    end
end

function resolver_reset_all()
    resolver_restore_all()
    resolver_runtime.jitter = {}
    resolver_runtime.defensive = {}
    resolver_runtime.lagcomp = {}
    resolver_runtime.shots = {}
end

function resolver_update_enemy(idx)
    if not entity.is_alive(idx) or entity.is_dormant(idx) then
        resolver_restore_player(idx)
        resolver_runtime.jitter[idx] = nil
        resolver_runtime.defensive[idx] = nil
        resolver_runtime.lagcomp[idx] = nil
        return
    end

    local now = globals.realtime()
    local tickinterval = globals.tickinterval()
    local simtime = entity.get_prop(idx, "m_flSimulationTime")
    local origin_x, origin_y, origin_z = entity.get_prop(idx, "m_vecOrigin")

    if ui.get(jitter_correction) and simtime ~= nil then
        local state = resolver_runtime.jitter[idx] or {confidence = 0, misses = 0, feedback_step = 0}
        resolver_decay_jitter_state(state, now)
        local spike_active = adaptive_ping_spike_update_state(state, simtime, tickinterval)
        local eye_yaw = entity.get_prop(idx, "m_angEyeAngles[1]")
        local body_pose_raw = entity.get_prop(idx, "m_flPoseParameter", 11)
        local body_pose_signed = body_pose_raw ~= nil and (body_pose_raw * 120 - 60) or 0
        local body_pose = math.abs(body_pose_signed)
        local lower_body_yaw = entity.get_prop(idx, "m_flLowerBodyYawTarget")
        local lby_delta = lower_body_yaw ~= nil and eye_yaw ~= nil and normalize_yaw(eye_yaw - lower_body_yaw) or nil
        local vel_x = entity.get_prop(idx, "m_vecVelocity[0]") or 0
        local vel_y = entity.get_prop(idx, "m_vecVelocity[1]") or 0
        local speed_2d = math.sqrt(vel_x * vel_x + vel_y * vel_y)
        local body_meta_active = false

        if (state.feedback_until or 0) <= now then
            state.feedback_step = 0
        end
        if (state.learned_until or 0) <= now then
            state.learned_amount = nil
        end

        if eye_yaw ~= nil and state.simtime ~= simtime then
            body_meta_active = resolver_body_yaw_meta(state, body_pose, body_pose_signed, lby_delta, speed_2d)
            if state.last_yaw ~= nil then
                local delta = normalize_yaw(eye_yaw - state.last_yaw)
                local delta_abs = math.abs(delta)

                if delta_abs >= 6 and delta_abs <= 165 then
                    local fake_flick_detected = fake_flick_detect_signal ~= nil and fake_flick_detect_signal(idx, state, delta, delta_abs, body_pose, lby_delta, speed_2d)
                    state.delta_history = state.delta_history or {}
                    if not fake_flick_detected then
                        state.delta_history[#state.delta_history + 1] = delta
                    end
                    if #state.delta_history > 8 then
                        table.remove(state.delta_history, 1)
                    end

                    local stats = resolver_jitter_history_stats(state.delta_history)
                    local last_delta = state.last_delta
                    local alternating = (last_delta ~= nil and delta * last_delta < 0) or stats.alternating_ratio >= 0.55
                    local valid_pattern, strong_pattern, tight_range, pattern_quality = resolver_jitter_pattern_valid(stats, delta_abs, body_pose, speed_2d)
                    local pattern_stability = resolver_pattern_stability(stats, delta_abs, body_pose, speed_2d)
                    local pose_confirmed = body_pose >= 12
                    local resolved_side = resolver_pick_body_side(state, delta, body_pose_signed, lby_delta)
                    local snapped_body = resolver_jitter_amplitude(body_pose, stats, delta_abs, speed_2d, fake_flick_detected)
                    local static_body = body_pose >= 48 and speed_2d <= 90
                    local micro_jitter = stats.count >= 4 and stats.alternating_ratio >= 0.58 and stats.average >= 6 and stats.average <= 28 and body_pose >= 14 and stats.variance <= math.max(9, stats.average * 0.34)
                    local type_hint = resolver_jitter_signal_type(stats, body_pose, delta_abs, fake_flick_detected)

                    state.last_stats_average = stats.average
                    state.last_stats_variance = stats.variance
                    state.last_alternating_ratio = stats.alternating_ratio
                    state.last_stats_spread = math.max(0, (stats.max_delta or 0) - (stats.min_delta or 0))
                    state.last_pattern_quality = pattern_quality
                    state.last_pattern_stability = pattern_stability
                    state.pattern_stability = resolver_clamp((state.pattern_stability or 0) * 0.65 + pattern_stability * 0.35, 0, 10)
                    state.last_observation_at = now

                    if fake_flick_detected then
                        state.confidence = math.min((state.confidence or 0) + (state.flick_returned and 3 or 1.25), 12)
                        state.flick_until = now + 0.65
                        resolver_commit_body_yaw_lock(state, resolved_side, snapped_body, 0.65, "FAKE FLICK")
                    elseif alternating and valid_pattern then
                        local stability_bonus = resolver_clamp((state.pattern_stability or 0) * 0.08, 0, 0.8)
                        local confidence_gain = strong_pattern and 3.5 or resolver_clamp(pattern_quality * 0.32 + stability_bonus, pose_confirmed and 1.5 or 1, 3.15)
                        state.confidence = math.min((state.confidence or 0) + confidence_gain, 12)
                        resolver_commit_body_yaw_lock(state, resolved_side, snapped_body, strong_pattern and 1.2 or 0.9, type_hint)
                    elseif static_body then
                        state.confidence = math.min((state.confidence or 0) + 2, 12)
                        resolver_commit_body_yaw_lock(state, resolved_side, math.max(body_pose, snapped_body), 0.85, type_hint)
                    elseif micro_jitter and tight_range then
                        state.confidence = math.min((state.confidence or 0) + 1.25, 12)
                        resolver_commit_body_yaw_lock(state, resolved_side, math.max(body_pose, 24), 0.55, "MICRO")
                    else
                        if not spike_active and not body_meta_active then
                            state.pattern_stability = math.max((state.pattern_stability or 0) - 0.45, 0)
                            state.confidence = math.max((state.confidence or 0) - 0.55, 0)
                        end
                    end

                    state.last_delta = delta
                else
                    if body_pose >= 48 and speed_2d <= 75 then
                        local resolved_side = resolver_pick_body_side(state, nil, body_pose_signed, lby_delta)
                        state.confidence = math.min((state.confidence or 0) + 1, 12)
                        resolver_commit_body_yaw_lock(state, resolved_side, body_pose, 0.65, "OFFSET")
                    else
                        if not spike_active and not body_meta_active then
                            state.confidence = math.max((state.confidence or 0) - 0.55, 0)
                        end
                    end
                end
            end

            state.last_yaw = eye_yaw
            state.simtime = simtime
        end

        if (state.confidence or 0) >= 2 and (state.detected_until or 0) > now then
            state.active_until = math.max(state.active_until or 0, state.detected_until)
        end
        if (state.flick_until or 0) > now then
            state.active_until = math.max(state.active_until or 0, state.flick_until)
        end
        if spike_active then
            adaptive_ping_spike_hold_state(state)
        end
        if not spike_active then
            resolver_apply_learned(idx, state)
        end

        resolver_runtime.jitter[idx] = state
    end

    if ui.get(defensive_correct) and simtime ~= nil then
        local eye_pitch = entity.get_prop(idx, "m_angEyeAngles[0]")
        local pose = entity.get_prop(idx, "m_flPoseParameter", 1)
        pose = pose ~= nil and pose * 120 - 60 or 0

        local state = resolver_runtime.defensive[idx] or {}
        if state.simtime ~= nil then
            local sim_delta = simtime - state.simtime
            local sim_ticks = math.floor(sim_delta / tickinterval + 0.5)
            local pose_delta = math.abs(pose - (state.pose or pose))
            local regressed = sim_delta < -tickinterval * 0.5
            local shifted = sim_ticks > 3
            local pose_break = sim_ticks <= 1 and pose_delta > 35

            if regressed or shifted or pose_break then
                local pitch_delta = ((state.pose or pose) - pose) * 0.5
                state.pitch = resolver_clamp((eye_pitch or state.eye_pitch or 0) + pitch_delta, -89, 89)
                state.active_until = now + 0.4
            end
        end

        state.simtime = simtime
        state.pose = pose
        state.eye_pitch = eye_pitch
        resolver_runtime.defensive[idx] = state
    end

    if ui.get(resolver_lagcomp) and simtime ~= nil and origin_x ~= nil then
        local state = resolver_runtime.lagcomp[idx] or {}
        if state.simtime ~= nil and state.x ~= nil then
            local dx = origin_x - state.x
            local dy = origin_y - state.y
            local dz = origin_z - state.z
            local distance_sqr = dx * dx + dy * dy + dz * dz
            local regressed = simtime < state.simtime - tickinterval * 0.5

            if regressed or distance_sqr > 4096 then
                state.broken_until = now + 0.45
            end
        end

        state.simtime = simtime
        state.x, state.y, state.z = origin_x, origin_y, origin_z
        resolver_runtime.lagcomp[idx] = state
    end

    resolver_apply_player(idx)
end

function resolver_update_all()
    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then
        resolver_restore_all()
        return
    end

    local enemies = entity.get_players(true)
    local active = {}
    for i = 1, #enemies do
        local idx = enemies[i]
        active[idx] = true
        resolver_update_enemy(idx)
    end

    local stale = {}
    for idx in pairs(resolver_runtime.owned) do
        if not active[idx] then
            stale[#stale + 1] = idx
        end
    end
    for i = 1, #stale do
        resolver_restore_player(stale[i])
    end
end

-- Per-enemy anti-aim scanner. It learns only network-visible behavior and
-- applies a frozen profile at runtime without rewriting the user's config.
;(function()
    local state_order = {
        {key = "Stand", label = "Standing"},
        {key = "Running", label = "Running"},
        {key = "Air", label = "Air"},
        {key = "Air-Duck", label = "Air-Duck"},
        {key = "Duck", label = "Duck"},
        {key = "Slow-walk", label = "Slow-Walk"},
        {key = "Duck-Running", label = "Duck-Running"}
    }
    local target_samples = 24
    local max_samples = 64
    local player_list = ui.reference("PLAYERS", "Players", "Player list")
    local title_label = ui.new_label("PLAYERS", "Adjustments", "PANCHAN AA STEALER")
    ui.new_label("PLAYERS", "Adjustments", "\a9ACD32FFscan anti-aim: always active")
    local progress_labels = {}
    for i = 1, #state_order do
        local item = state_order[i]
        progress_labels[item.key] = ui.new_label("PLAYERS", "Adjustments", item.label .. ": 0%")
    end
    local status_label = ui.new_label("PLAYERS", "Adjustments", "scanning all enemies...")

    aa_stealer_runtime = {}
    local runtime = aa_stealer_runtime
    runtime.profiles = {}
    runtime.active = nil
    runtime.phase = {}
    runtime.next_ui_update = 0

    local function new_state_data()
        return {
            samples = 0,
            yaws = {},
            pitches = {},
            bodies = {},
            deltas = {},
            switch_intervals = {},
            first_time = nil,
            last_time = nil,
            serial = 0,
            timeline_ticks = 0,
            last_relative_yaw = nil,
            last_change_tick = nil,
            model = nil
        }
    end

    local function new_profile(idx, identity)
        local states = {}
        for i = 1, #state_order do
            states[state_order[i].key] = new_state_data()
        end

        return {
            idx = idx,
            identity = identity,
            name = entity.get_player_name(idx) or "enemy",
            states = states,
            observation = {
                last_simtime = nil,
                candidate_state = nil,
                state_dwell = 0
            },
            version = 0
        }
    end

    local function player_identity(idx)
        if idx == nil or idx < 1 or idx > 64 then
            return nil
        end

        if entity.get_steam64 ~= nil then
            local ok, steam = pcall(entity.get_steam64, idx)
            if ok and steam ~= nil and tostring(steam) ~= "" and tostring(steam) ~= "0" then
                return tostring(steam)
            end
        end

        local name = entity.get_player_name(idx)
        if name == nil then
            return nil
        end
        return tostring(idx) .. ":" .. tostring(name)
    end

    local function get_profile(idx, create)
        local identity = player_identity(idx)
        if identity == nil then
            return nil
        end

        local profile = runtime.profiles[idx]
        if profile ~= nil and profile.identity ~= identity then
            runtime.profiles[idx] = nil
            profile = nil
        end

        if profile == nil and create then
            profile = new_profile(idx, identity)
            runtime.profiles[idx] = profile
        end

        if profile ~= nil then
            profile.name = entity.get_player_name(idx) or profile.name or "enemy"
        end
        return profile
    end

    local function selected_enemy()
        local ok, idx = pcall(ui.get, player_list)
        if not ok or type(idx) ~= "number" or idx < 1 or idx > 64 then
            return nil
        end

        local enemy_ok, is_enemy = pcall(entity.is_enemy, idx)
        if not enemy_ok or not is_enemy then
            return nil
        end
        return idx
    end

    local function state_progress(data)
        if data == nil then
            return 0
        end
        return clamp(math.floor((math.min(data.samples or 0, target_samples) / target_samples) * 100 + 0.5), 0, 100)
    end

    local function profile_completion(profile)
        local complete = 0
        for i = 1, #state_order do
            if state_progress(profile.states[state_order[i].key]) >= 100 then
                complete = complete + 1
            end
        end
        return complete
    end

    local function profile_available(profile)
        local available = 0
        for i = 1, #state_order do
            local data = profile.states[state_order[i].key]
            if data ~= nil and data.model ~= nil and (data.samples or 0) > 0 then
                available = available + 1
            end
        end
        return available
    end

    local function notify(message, r, g, b)
        local text = "AA Stealer | " .. tostring(message)
        if add_log ~= nil then
            add_log(text, 3, r or 255, g or 255, b or 255)
        end
        client.log("[Panchan] " .. text)
    end

    local function clear_runtime(full)
        runtime.phase = {}
        runtime.next_ui_update = 0

        if full then
            runtime.profiles = {}
            runtime.active = nil
        else
            for _, profile in pairs(runtime.profiles) do
                profile.observation = {
                    last_simtime = nil,
                    candidate_state = nil,
                    state_dwell = 0
                }
                for i = 1, #state_order do
                    local data = profile.states[state_order[i].key]
                    data.last_relative_yaw = nil
                    data.last_change_tick = nil
                end
            end
        end
    end

    aa_stealer_reset_runtime = clear_runtime

    local function push_sample(list, value)
        if value == nil then
            return
        end
        list[#list + 1] = value
        if #list > max_samples then
            table.remove(list, 1)
        end
    end

    local function median(values)
        if values == nil or #values == 0 then
            return 0
        end

        local sorted = {}
        for i = 1, #values do
            sorted[i] = values[i]
        end
        table.sort(sorted)

        local middle = math.floor((#sorted + 1) * 0.5)
        if #sorted % 2 == 0 then
            return (sorted[middle] + sorted[middle + 1]) * 0.5
        end
        return sorted[middle]
    end

    local function atan2(y, x)
        if math.atan2 ~= nil then
            return math.atan2(y, x)
        end
        if x > 0 then
            return math.atan(y / x)
        elseif x < 0 and y >= 0 then
            return math.atan(y / x) + math.pi
        elseif x < 0 then
            return math.atan(y / x) - math.pi
        elseif y > 0 then
            return math.pi * 0.5
        elseif y < 0 then
            return -math.pi * 0.5
        end
        return 0
    end

    local function circular_mean(values)
        if values == nil or #values == 0 then
            return 0
        end

        local sine, cosine = 0, 0
        for i = 1, #values do
            local radians = math.rad(values[i])
            sine = sine + math.sin(radians)
            cosine = cosine + math.cos(radians)
        end
        return normalize_yaw(math.deg(atan2(sine, cosine)))
    end

    local function build_state_model(data, idx)
        if data == nil or #data.yaws == 0 then
            return nil
        end

        local center = circular_mean(data.yaws)
        local left_deviations, right_deviations = {}, {}
        local left_bodies, right_bodies, all_bodies = {}, {}, {}
        local signs = {}
        local deadzone = 3

        for i = 1, #data.yaws do
            local deviation = normalize_yaw(data.yaws[i] - center)
            local body = data.bodies[i]
            if body ~= nil then
                all_bodies[#all_bodies + 1] = body
            end

            if deviation < -deadzone then
                left_deviations[#left_deviations + 1] = deviation
                signs[#signs + 1] = -1
                if body ~= nil then left_bodies[#left_bodies + 1] = body end
            elseif deviation > deadzone then
                right_deviations[#right_deviations + 1] = deviation
                signs[#signs + 1] = 1
                if body ~= nil then right_bodies[#right_bodies + 1] = body end
            end
        end

        local yaw_left = center
        local yaw_right = center
        if #left_deviations > 0 then
            yaw_left = normalize_yaw(center + median(left_deviations))
        end
        if #right_deviations > 0 then
            yaw_right = normalize_yaw(center + median(right_deviations))
        end

        local amplitude = math.abs(normalize_yaw(yaw_right - yaw_left))
        local flips = 0
        for i = 2, #signs do
            if signs[i] ~= signs[i - 1] then
                flips = flips + 1
            end
        end
        local alternating = #signs > 1 and flips / (#signs - 1) or 0

        local mode = "STATIC"
        if amplitude >= 8 and #left_deviations > 0 and #right_deviations > 0 then
            if amplitude >= 72 and alternating >= 0.62 then
                mode = "SKITTER"
            elseif alternating >= 0.52 then
                mode = "CENTER"
            elseif alternating >= 0.22 then
                mode = "OFFSET"
            else
                mode = "RANDOM"
            end
        end

        local resolver_state = resolver_runtime ~= nil and resolver_runtime.jitter[idx] or nil
        if mode ~= "STATIC" and resolver_state ~= nil and (resolver_state.confidence or 0) >= 4 then
            if resolver_state.jitter_type == "SKITTER" then
                mode = "SKITTER"
            elseif resolver_state.jitter_type == "CENTRE" then
                mode = "CENTER"
            end
        end

        local delay = clamp(math.floor(median(data.switch_intervals) + 0.5), 1, 22)
        local pitch = clamp(median(data.pitches), -89, 89)
        local body_fallback = clamp(median(all_bodies), -60, 60)
        local body_left = #left_bodies > 0 and clamp(median(left_bodies), -60, 60) or body_fallback
        local body_right = #right_bodies > 0 and clamp(median(right_bodies), -60, 60) or body_fallback

        if resolver_state ~= nil and (resolver_state.confidence or 0) >= 4
            and math.max(math.abs(body_left), math.abs(body_right)) < 8
        then
            local amount = clamp(resolver_state.amplitude or math.abs(resolver_state.amount or 0), 18, 60)
            local side = resolver_state.resolved_side == -1 and -1 or 1
            body_left = -side * amount
            body_right = side * amount
        end

        local progress = state_progress(data)
        local duration = math.max(0, (data.last_time or 0) - (data.first_time or data.last_time or 0))
        local history_stats = resolver_jitter_history_stats ~= nil and resolver_jitter_history_stats(data.deltas) or nil
        local stability = history_stats ~= nil and clamp(1 - (history_stats.variance or 0) / math.max(history_stats.average or 1, 1), 0, 1) or 0.5
        local confidence = clamp(math.floor(progress * 0.78 + math.min(duration / 0.7, 1) * 12 + stability * 10 + 0.5), 0, 100)

        return {
            center = center,
            yaw_left = yaw_left,
            yaw_right = yaw_right,
            amplitude = amplitude,
            mode = mode,
            delay = delay,
            pitch = pitch,
            body_left = body_left,
            body_right = body_right,
            confidence = confidence,
            progress = progress,
            samples = data.samples
        }
    end

    local function enemy_state(idx)
        local flags = entity.get_prop(idx, "m_fFlags")
        if flags == nil then
            return nil
        end

        local vx = entity.get_prop(idx, "m_vecVelocity[0]") or 0
        local vy = entity.get_prop(idx, "m_vecVelocity[1]") or 0
        local speed = math.sqrt(vx * vx + vy * vy)
        local duck = clamp(entity.get_prop(idx, "m_flDuckAmount") or 0, 0, 1)
        local on_ground = bit.band(flags, 1) == 1

        if not on_ground then
            return duck > 0.55 and "Air-Duck" or "Air", speed
        end
        if duck > 0.65 then
            return speed > 8 and "Duck-Running" or "Duck", speed
        end
        if speed <= 5 then
            return "Stand", speed
        end

        local max_speed = 250
        local weapon = entity.get_player_weapon(idx)
        if weapon ~= nil and weapons ~= nil then
            local ok, info = pcall(weapons, weapon)
            if ok and type(info) == "table" then
                local scoped = entity.get_prop(idx, "m_bIsScoped") == 1
                max_speed = scoped and (info.max_speed_alt or info.max_speed or max_speed) or (info.max_speed or max_speed)
            end
        end

        local speed_ratio = speed / math.max(max_speed, 1)
        if speed <= 112 and speed_ratio <= 0.54 then
            return "Slow-walk", speed
        end
        return "Running", speed
    end

    local function collect_enemy(profile, idx, local_player)
        if profile == nil or not entity.is_alive(idx)
            or entity.is_dormant(idx)
        then
            return
        end

        local simtime = entity.get_prop(idx, "m_flSimulationTime")
        local observation = profile.observation
        if simtime == nil or observation.last_simtime == simtime then
            return
        end

        local previous_simtime = observation.last_simtime
        local simulation_ticks = 1
        observation.last_simtime = simtime
        if previous_simtime ~= nil then
            local sim_delta = simtime - previous_simtime
            if sim_delta <= 0 or sim_delta > 0.35 then
                observation.candidate_state = nil
                observation.state_dwell = 0
                return
            end
            simulation_ticks = clamp(math.floor(sim_delta / globals.tickinterval() + 0.5), 1, 22)
        end

        local weapon = entity.get_player_weapon(idx)
        if weapon ~= nil then
            local last_shot = entity.get_prop(weapon, "m_fLastShotTime")
            if last_shot ~= nil then
                local shot_age = simtime - last_shot
                if shot_age >= -globals.tickinterval() and shot_age <= 0.22 then
                    observation.candidate_state = nil
                    observation.state_dwell = 0
                    return
                end
            end
        end

        local state = enemy_state(idx)
        if state == nil then
            return
        end

        if observation.candidate_state ~= state then
            observation.candidate_state = state
            observation.state_dwell = 1
            local entering = profile.states[state]
            if entering ~= nil then
                entering.last_relative_yaw = nil
                entering.last_change_tick = nil
            end
            return
        end

        observation.state_dwell = (observation.state_dwell or 0) + 1
        if observation.state_dwell < 2 then
            return
        end

        local eye_yaw = entity.get_prop(idx, "m_angEyeAngles[1]")
        local eye_pitch = entity.get_prop(idx, "m_angEyeAngles[0]")
        local enemy_x, enemy_y = entity.get_prop(idx, "m_vecOrigin")
        local local_x, local_y = entity.get_prop(local_player, "m_vecOrigin")
        if eye_yaw == nil or eye_pitch == nil or enemy_x == nil or local_x == nil then
            return
        end

        local yaw_to_local = math.deg(atan2(local_y - enemy_y, local_x - enemy_x))
        local backward_yaw = normalize_yaw(yaw_to_local + 180)
        local relative_yaw = normalize_yaw(eye_yaw - backward_yaw)
        local body_pose_raw = entity.get_prop(idx, "m_flPoseParameter", 11)
        local body_pose = body_pose_raw ~= nil and clamp(body_pose_raw * 120 - 60, -60, 60) or 0
        local data = profile.states[state]
        if data == nil then
            return
        end

        local now = globals.realtime()
        data.samples = math.min((data.samples or 0) + 1, max_samples)
        data.serial = (data.serial or 0) + 1
        data.timeline_ticks = (data.timeline_ticks or 0) + simulation_ticks
        data.first_time = data.first_time or now
        data.last_time = now
        push_sample(data.yaws, relative_yaw)
        push_sample(data.pitches, clamp(eye_pitch, -89, 89))
        push_sample(data.bodies, body_pose)

        if data.last_relative_yaw ~= nil then
            local delta = normalize_yaw(relative_yaw - data.last_relative_yaw)
            local delta_abs = math.abs(delta)
            if delta_abs <= 175 then
                push_sample(data.deltas, delta)
            end

            if delta_abs >= 8 then
                if data.last_change_tick ~= nil then
                    local interval = data.timeline_ticks - data.last_change_tick
                    if interval >= 1 and interval <= 32 then
                        push_sample(data.switch_intervals, interval)
                    end
                end
                data.last_change_tick = data.timeline_ticks
            end
        end

        data.last_relative_yaw = relative_yaw
        data.model = build_state_model(data, idx)
        profile.version = (profile.version or 0) + 1
    end

    aa_stealer_update_all = function()
        local local_player = entity.get_local_player()
        if local_player == nil or not entity.is_alive(local_player) then
            return
        end

        local enemies = entity.get_players(true)
        for i = 1, #enemies do
            local idx = enemies[i]
            local profile = get_profile(idx, true)
            if profile ~= nil then
                collect_enemy(profile, idx, local_player)
            end
        end
    end

    local function copy_model(model)
        return {
            center = model.center,
            yaw_left = model.yaw_left,
            yaw_right = model.yaw_right,
            amplitude = model.amplitude,
            mode = model.mode,
            delay = model.delay,
            pitch = model.pitch,
            body_left = model.body_left,
            body_right = model.body_right,
            confidence = model.confidence,
            progress = model.progress,
            samples = model.samples
        }
    end

    local function steal_selected()
        local idx = selected_enemy()
        if idx == nil then
            notify("select an enemy in Player List", 255, 190, 120)
            return
        end

        local profile = get_profile(idx, true)
        if profile == nil then
            return
        end

        if runtime.active ~= nil and runtime.active.identity == profile.identity then
            notify("disabled profile from " .. tostring(runtime.active.name), 190, 190, 190)
            runtime.active = nil
            runtime.phase = {}
            runtime.next_ui_update = 0
            return
        end

        local frozen = {}
        local available = 0
        for i = 1, #state_order do
            local key = state_order[i].key
            local data = profile.states[key]
            if data ~= nil and data.model ~= nil and (data.samples or 0) > 0 then
                frozen[key] = copy_model(data.model)
                available = available + 1
            end
        end

        if available == 0 then
            notify("waiting for the first valid record from " .. tostring(profile.name), 255, 190, 120)
            return
        end

        runtime.active = {
            identity = profile.identity,
            source_idx = idx,
            name = profile.name,
            states = frozen,
            stolen_at = globals.realtime(),
            version = profile.version
        }
        runtime.phase = {}
        runtime.next_ui_update = 0
        notify("stole " .. tostring(available) .. "/" .. tostring(#state_order) .. " available states from " .. tostring(profile.name), 154, 205, 50)
    end

    local steal_button = ui.new_button("PLAYERS", "Adjustments", "steal anti-aim", steal_selected)

    local function progress_color(progress)
        if progress >= 100 then
            return "\a9ACD32FF"
        elseif progress > 0 then
            return "\aE5C07BFF"
        end
        return "\aA0A0A0FF"
    end

    local function refresh_ui(force)
        if not force and not ui.is_menu_open() then
            return
        end
        local now = globals.realtime()
        if not force and now < (runtime.next_ui_update or 0) then
            return
        end
        runtime.next_ui_update = now + 0.05

        local idx = selected_enemy()
        local profile = idx ~= nil and get_profile(idx, true) or nil

        for i = 1, #state_order do
            local item = state_order[i]
            local progress = profile ~= nil and state_progress(profile.states[item.key]) or 0
            ui.set(progress_labels[item.key], progress_color(progress) .. item.label .. ": " .. tostring(progress) .. "%")
        end

        if runtime.active ~= nil then
            ui.set(status_label, "\a9ACD32FFactive: " .. tostring(runtime.active.name) .. " | press Steal again to disable")
        elseif profile == nil then
            ui.set(status_label, "\aA0A0A0FFselect an enemy...")
        else
            local complete = profile_completion(profile)
            local available = profile_available(profile)
            if complete == #state_order then
                ui.set(status_label, "\a9ACD32FFdone! | ready to Steal")
            elseif available > 0 then
                ui.set(status_label, "\aE5C07BFFscanning... " .. tostring(complete) .. "/" .. tostring(#state_order) .. " complete | Steal ready")
            else
                ui.set(status_label, "\aE5C07BFFscanning... waiting for records")
            end
        end
    end

    aa_stealer_apply = function(cmd, condition, settings)
        local active = runtime.active
        local model = active ~= nil and active.states[condition] or nil
        if model == nil or condition == "Safe-Head" or condition == "Fake Lag" then
            return false
        end
        if ref.fd ~= nil and ui.get(ref.fd) then
            return false
        end
        if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
            return false
        end
        if static ~= nil and static.defensive
            and settings ~= nil and settings.defensive_aa ~= nil and ui.get(settings.defensive_aa)
        then
            return false
        end

        local tick = globals.tickcount()
        local phase = runtime.phase[condition]
        if phase == nil then
            phase = {
                side = false,
                step = 0,
                next_switch_tick = tick,
                random_yaw = model.center
            }
            runtime.phase = {[condition] = phase}
        end

        local delay = clamp(math.floor((model.delay or 1) + 0.5), 1, 22)
        if anti_brute_adjust_delay ~= nil then
            delay = anti_brute_adjust_delay(delay, cmd)
        end
        if tick >= (phase.next_switch_tick or tick) then
            phase.side = not phase.side
            phase.step = (phase.step or 0) + 1
            phase.next_switch_tick = tick + delay

            if model.mode == "RANDOM" then
                local base = phase.side and model.yaw_right or model.yaw_left
                local noise = math.min(math.max(model.amplitude or 0, 8) * 0.12, 12)
                phase.random_yaw = normalize_yaw(base + random_between(-noise, noise))
            end
        end

        local yaw
        if model.mode == "STATIC" then
            yaw = model.center
        elseif model.mode == "SKITTER" and phase.step % 4 == 0 then
            yaw = model.center
        elseif model.mode == "RANDOM" then
            yaw = phase.random_yaw
        else
            yaw = phase.side and model.yaw_right or model.yaw_left
        end

        yaw = clamp(normalize_yaw(yaw or 0), -180, 180)
        yaw_rl = yaw
        ui.set(ref.enabled, true)
        ui.set(ref.yaw_base, "At Targets")
        ui.set(ref.yaw[1], "180")
        ui.set(ref.yaw[2], yaw)
        ui.set(ref.yaw_jitter[1], "Off")
        ui.set(ref.yaw_jitter[2], 0)
        ui.set(ref.freestanding_body_yaw, false)
        ui.set(ref.roll, 0)

        if ref.pitch[2] ~= nil then
            ui.set(ref.pitch[1], "Custom")
            ui.set(ref.pitch[2], clamp(model.pitch or 0, -89, 89))
        end

        local body = phase.side and model.body_right or model.body_left
        body = clamp(body or 0, -60, 60)
        if anti_brute_adjust_body ~= nil then
            body = anti_brute_adjust_body(body, cmd)
        end
        if math.abs(body) >= 6 then
            ui.set(ref.body_yaw[1], "Static")
            ui.set(ref.body_yaw[2], body)
        else
            ui.set(ref.body_yaw[1], "Off")
            ui.set(ref.body_yaw[2], 0)
        end
        return true
    end

    client.set_event_callback("paint_ui", function()
        refresh_ui(false)
    end)
    client.set_event_callback("round_start", function()
        clear_runtime(false)
    end)
    client.set_event_callback("level_init", function()
        clear_runtime(true)
    end)
    pcall(client.set_event_callback, "cs_game_disconnected", function()
        clear_runtime(true)
    end)
    pcall(client.set_event_callback, "game_newmap", function()
        clear_runtime(true)
    end)
    client.set_event_callback("shutdown", function()
        clear_runtime(true)
    end)

    refresh_ui(true)
end)()

function jitter_on_fire(e)
    if e == nil or e.id == nil or e.target == nil then
        return
    end

    local state = resolver_runtime.jitter[e.target]
    local gate_applied = state ~= nil and state.gate_mode ~= nil and state.gate_mode ~= "PASS" and math.abs(state.gate_amount or 0) >= 8
    resolver_runtime.shots[e.id] = {
        target = e.target,
        amount = gate_applied and state.gate_amount or nil,
        side = state and state.resolved_side or nil,
        amplitude = state and state.amplitude or nil,
        jitter_type = state and state.jitter_type or nil,
        gate_applied = gate_applied,
        gate_mode = state and state.gate_mode or "PASS",
        gate_score = state and state.gate_score or 0,
        matrix_key = gate_applied and resolver_matrix_key(state.gate_amount) or nil,
        matrix_stage = state and state.matrix and state.matrix.stage or 0,
        matrix_confidence = state and state.confidence or 0,
        fired_at = globals.realtime()
    }
    if ui.get(resolver_lagcomp) and e.teleported then
        local state = resolver_runtime.lagcomp[e.target] or {}
        state.broken_until = globals.realtime() + 0.6
        resolver_runtime.lagcomp[e.target] = state
        resolver_apply_player(e.target)
    end
end

function jitter_on_hit(e)
    local shot = e and e.id and resolver_runtime.shots[e.id] or nil
    local target = e and (e.target or (shot and shot.target))
    if target == nil then
        return
    end

    if e.id ~= nil then
        resolver_runtime.shots[e.id] = nil
    end
    if not ui.get(jitter_correction) then
        return
    end

    local state = resolver_runtime.jitter[target]
    if state ~= nil then
        local gate_applied = shot ~= nil and shot.gate_applied or (shot == nil and state.gate_mode ~= nil and state.gate_mode ~= "PASS")
        local hit_amount = shot and shot.amount or state.gate_amount
        local now = globals.realtime()

        if gate_applied and hit_amount ~= nil and math.abs(hit_amount) >= 8 then
            hit_amount = resolver_matrix_normalize_amount(hit_amount)
            resolver_matrix_feedback(state, hit_amount, true, 1)
            resolver_learn_feedback(target, hit_amount, true)
            state.learned_amount = hit_amount
            state.learned_until = now + 8
            state.hit_side = hit_amount >= 0 and 1 or -1
            state.hit_side_until = now + 10
            state.amount = hit_amount
            state.resolved_side = state.hit_side
            state.misses = math.max((state.misses or 0) - 2, 0)
            state.feedback_step = 0
            state.feedback_until = 0
            state.feedback_attempts = {}
            state.confidence = math.min((state.confidence or 0) + 2, 12)
            state.pattern_stability = math.min((state.pattern_stability or 0) + 1.5, 10)
            state.side_score = resolver_clamp((state.side_score or 0) + ((state.hit_side or 0) * 2.25), -12, 12)
            state.active_until = math.max(state.detected_until or 0, state.spike_until or 0, now + 0.75)
            state.gate_mode = "APPLY"
            state.gate_reason = "confirmed hit"
            state.gate_amount = hit_amount
            state.gate_hold_amount = hit_amount
            state.gate_hold_until = now + 0.8
            state.gate_trusted_until = now + 2.25
            state.gate_probe_until = 0
            state.gate_native_until = 0
            state.gate_abstain_until = 0
            state.gate_contradictions = 0
        else
            -- The native resolver landed this shot while our override was released.
            state.gate_mode = "PASS"
            state.gate_reason = "native hit"
            state.gate_amount = nil
            state.gate_hold_until = 0
            state.gate_probe_until = 0
            state.gate_native_until = now + 0.75
        end
        resolver_apply_player(target)
    end
end

function jitter_on_miss(e)
    local shot = e and e.id and resolver_runtime.shots[e.id] or nil
    local target = e and (e.target or (shot and shot.target))
    if target == nil then
        return
    end

    if e.id ~= nil then
        resolver_runtime.shots[e.id] = nil
    end
    if not ui.get(jitter_correction) then
        return
    end

    local filter = miss_filter_classify(e, target)
    local state = resolver_runtime.jitter[target] or {misses = 0, confidence = 0, feedback_step = 0}

    if filter.lagcomp_feedback and ui.get(resolver_lagcomp) then
        local lagcomp = resolver_runtime.lagcomp[target] or {}
        lagcomp.broken_until = globals.realtime() + 0.45
        resolver_runtime.lagcomp[target] = lagcomp
        resolver_apply_player(target)
    end

    if adaptive_ping_spike_enabled() and (filter.lagcomp_feedback or filter.category == "prediction") then
        local spike_duration = filter.lagcomp_feedback and 1.1 or 0.85
        adaptive_ping_spike_mark_state(state, spike_duration, filter.category, filter.lagcomp_feedback and 5 or 4)
        resolver_runtime.jitter[target] = state
        resolver_apply_player(target)
        return
    end

    if not filter.resolver_feedback then
        return
    end

    local gate_applied = shot ~= nil and shot.gate_applied or (shot == nil and state.gate_mode ~= nil and state.gate_mode ~= "PASS")
    local feedback_amount = shot and shot.amount or state.gate_amount
    local now = globals.realtime()

    if not gate_applied or feedback_amount == nil or math.abs(feedback_amount) < 8 then
        -- A native-resolver miss is not evidence against any Panchan Matrix cell.
        state.gate_native_until = 0
        state.gate_abstain_until = 0
        state.gate_hold_until = 0
        state.gate_probe_until = 0
        state.gate_mode = "PASS"
        state.gate_reason = "native miss"
        state.gate_amount = nil
        resolver_runtime.jitter[target] = state
        resolver_apply_player(target)
        return
    end

    feedback_amount = resolver_matrix_normalize_amount(feedback_amount)
    state.gate_contradictions = math.min((state.gate_contradictions or 0) + 1, 4)
    state.gate_trusted_until = 0
    state.gate_hold_until = 0

    if filter.matrix_feedback then
        resolver_matrix_feedback(state, feedback_amount, false, filter.matrix_weight)
    end
    if filter.learn_feedback then
        resolver_learn_feedback(target, feedback_amount, false)
    end
    state.misses = math.min((state.misses or 0) + 1, 6)
    if state.misses >= 2 then
        state.side_score = -(state.side_score or 0) * 0.55
        state.body_lock_score = -(state.body_lock_score or 0) * 0.45
        state.pattern_stability = math.max((state.pattern_stability or 0) - 2, 0)
        state.hit_side_until = math.min(state.hit_side_until or 0, globals.realtime() + 0.15)
    else
        state.pattern_stability = math.max((state.pattern_stability or 0) - 0.75, 0)
    end
    if state.hit_side ~= nil then
        local missed_side = feedback_amount >= 0 and 1 or -1
        if missed_side == state.hit_side then
            state.hit_side_until = math.min(state.hit_side_until or 0, now + (state.misses >= 2 and 0 or 1))
        end
    end
    if not filter.cycle_feedback then
        resolver_runtime.jitter[target] = state
        resolver_apply_player(target)
        return
    end

    if (state.gate_contradictions or 0) >= 3 then
        state.feedback_until = 0
        state.active_until = math.min(state.active_until or now, now + 0.2)
        state.gate_probe_until = 0
        state.gate_abstain_until = now + 1.45
        state.gate_mode = "PASS"
        state.gate_reason = "contradiction cooldown"
        state.gate_amount = nil
        resolver_runtime.jitter[target] = state
        resolver_apply_player(target)
        return
    end

    local selected = resolver_matrix_select(state, shot, filter)
    state.feedback_step = state.matrix and state.matrix.stage or 0
    state.feedback_attempts = {}
    state.amount = selected
    if math.abs(state.amount or 0) >= 8 then
        state.resolved_side = state.amount >= 0 and 1 or -1
    end
    state.feedback_until = now + 5.5
    state.active_until = math.abs(state.amount or 0) >= 8 and state.feedback_until or now + 0.2
    state.confidence = math.max((state.confidence or 0) - 0.35, 2)
    state.gate_probe_until = now + resolver_clamp(1.38 - state.misses * 0.18, 0.68, 1.2)
    state.gate_mode = "APPLY"
    state.gate_reason = "matrix probe"
    state.gate_amount = selected
    resolver_runtime.jitter[target] = state
    resolver_apply_player(target)
end

ui.set_callback(jitter_correction, function()
    if not ui.get(jitter_correction) then
        resolver_runtime.jitter = {}
    end
    resolver_update_all()
    if fake_flick_sync ~= nil then
        fake_flick_sync()
    end
end)

ui.set_callback(adaptive_ping_spike, function()
    if not ui.get(adaptive_ping_spike) then
        for _, state in pairs(resolver_runtime.jitter) do
            state.spike_until = 0
            state.spike_hold_amount = nil
            state.spike_reason = nil
            state.spike_strength = nil
            state.spike_ping_ms = nil
        end
    end
    resolver_update_all()
end)

ui.set_callback(defensive_correct, function()
    if not ui.get(defensive_correct) then
        resolver_runtime.defensive = {}
    end
    resolver_update_all()
end)

ui.set_callback(resolver_lagcomp, function()
    if not ui.get(resolver_lagcomp) then
        resolver_runtime.lagcomp = {}
    end
    resolver_update_all()
end)

function fake_flick_sync()
    return
end

function fake_flick_condition_enabled(idx)
    if not ui.get(fake_flick) then
        return false
    end

    local selected = ui.get(fake_flick_conditions)
    if #selected == 0 then
        return true
    end

    local flags = entity.get_prop(idx, "m_fFlags") or 0
    local duck = entity.get_prop(idx, "m_flDuckAmount") or 0
    local vx = entity.get_prop(idx, "m_vecVelocity[0]") or 0
    local vy = entity.get_prop(idx, "m_vecVelocity[1]") or 0
    local speed = math.sqrt(vx * vx + vy * vy)
    local condition

    if flags % 2 == 0 then
        condition = duck > 0.55 and "Crouch-Air" or "Air"
    elseif duck > 0.55 then
        condition = speed > 8 and "Fake Duck" or "Crouching"
    elseif speed < 4 then
        condition = "Standing"
    elseif speed < 95 then
        condition = "Slowwalk"
    else
        condition = "Moving"
    end

    for i = 1, #selected do
        if selected[i] == condition then
            return true
        end
    end
    return false
end

function fake_flick_detect_signal(idx, state, delta, delta_abs, body_pose, lby_delta, speed_2d)
    if not fake_flick_condition_enabled(idx) then
        return false
    end

    local now = globals.realtime()
    local pose_confirm = (body_pose or 0) >= 18
    local lby_confirm = lby_delta ~= nil and math.abs(lby_delta) >= 28
    local moving_confirm = (speed_2d or 0) <= 160
    local big_spike = delta_abs >= 92
    local medium_spike = delta_abs >= 68 and (pose_confirm or lby_confirm)
    local returned = false

    if (state.flick_spike_until or 0) > now and state.flick_spike_delta ~= nil then
        local magnitude_match = math.abs(delta_abs - math.abs(state.flick_spike_delta)) <= math.max(24, math.abs(state.flick_spike_delta) * 0.42)
        returned = delta * state.flick_spike_delta < 0 and delta_abs >= 34 and magnitude_match
    end

    if big_spike or medium_spike then
        state.flick_spike_until = now + 0.32
        state.flick_spike_delta = delta
    end
    state.flick_returned = returned

    local instant_flick = delta_abs >= 125 and (pose_confirm or lby_confirm)
    return moving_confirm and (instant_flick or returned)
end

ui.set_callback(fake_flick, fake_flick_sync)
ui.set_callback(fake_flick_conditions, fake_flick_sync)
fake_flick_sync()

quickpeek_runtime = {
    hold_until = 0,
    attack_until = 0,
    last_stop_tick = 0
}

function quickpeek_reset_runtime()
    quickpeek_runtime.hold_until = 0
    quickpeek_runtime.attack_until = 0
    quickpeek_runtime.last_stop_tick = 0
end

quickpeek_option_refs = {
    ["AWP"] = quickpeek_dt_options_awp,
    ["SSG 08"] = quickpeek_dt_options_scout,
    ["SCAR"] = quickpeek_dt_options_scar,
    ["Pistols"] = quickpeek_dt_options_pistols,
    ["Deagle"] = quickpeek_dt_options_deagle,
    ["Any"] = quickpeek_dt_options_any
}

quickpeek_profile_tuning = {
    ["AWP"] = { early = 0.22, release = 0.10, stop_speed = 7, hold_bonus = 0 },
    ["SSG 08"] = { early = 0.17, release = 0.08, stop_speed = 10, hold_bonus = 0 },
    ["SCAR"] = { early = 0.20, release = 0.09, stop_speed = 8, hold_bonus = 0 },
    ["Pistols"] = { early = 0.11, release = 0.05, stop_speed = 13, hold_bonus = 0 },
    ["Deagle"] = { early = 0.15, release = 0.07, stop_speed = 9, hold_bonus = 0 },
    ["Any"] = { early = 0.14, release = 0.07, stop_speed = 10, hold_bonus = 0 }
}

function quickpeek_weapon_group(data)
    if data == nil then
        return nil
    end

    local name = string.lower(tostring(data.name or data.console_name or data.weapon_name or ""))
    if data.type == "knife" or data.type == "grenade" then
        return nil
    elseif name:find("awp", 1, true) ~= nil then
        return "AWP"
    elseif name:find("ssg08", 1, true) ~= nil or name:find("scout", 1, true) ~= nil then
        return "SSG 08"
    elseif name:find("scar20", 1, true) ~= nil or name:find("g3sg1", 1, true) ~= nil then
        return "SCAR"
    elseif name:find("deagle", 1, true) ~= nil or name:find("revolver", 1, true) ~= nil then
        return "Deagle"
    elseif data.type == "pistol" then
        return "Pistols"
    end

    return "Any"
end

function quickpeek_active_options(data)
    local group = quickpeek_weapon_group(data)
    local ref = quickpeek_option_refs[group or "Any"] or quickpeek_dt_options_any
    return ui.get(ref)
end

function quickpeek_get_tuning(data)
    local group = quickpeek_weapon_group(data) or "Any"
    return quickpeek_profile_tuning[group] or quickpeek_profile_tuning["Any"]
end

function quickpeek_has_any_options(data)
    local options = quickpeek_active_options(data)
    return options ~= nil and #options > 0
end

function quickpeek_has_option(name, data)
    local options = quickpeek_active_options(data)
    for i = 1, #options do
        if options[i] == name then
            return true
        end
    end
    return false
end

function quickpeek_weapon_allowed(data)
    return quickpeek_weapon_group(data) ~= nil
end

function quickpeek_assist_active()
    if ref.quick_peek ~= nil and ref.quick_peek[1] ~= nil then
        local ok_enabled, enabled = pcall(ui.get, ref.quick_peek[1])
        local ok_hotkey, hotkey = false, false
        if ref.quick_peek[2] ~= nil then
            ok_hotkey, hotkey = pcall(ui.get, ref.quick_peek[2])
        end

        if ok_enabled and ok_hotkey then
            return enabled == true and hotkey == true
        elseif ok_hotkey then
            return hotkey == true
        elseif ok_enabled then
            return enabled == true
        end
    end

    local ok, fd_active = pcall(ui.get, ref.fd)
    return ok and fd_active == true
end

function quickpeek_autostop_run(cmd)
    if not ui.get(early_quickpeek_autostop) then
        quickpeek_reset_runtime()
        return
    end

    local assist_active = quickpeek_assist_active()
    if not assist_active then
        quickpeek_reset_runtime()
        return
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) or cmd.in_use == 1 then
        quickpeek_reset_runtime()
        return
    end

    local flags = entity.get_prop(lp, "m_fFlags") or 0
    local move_type = entity.get_prop(lp, "m_MoveType") or 0
    if flags % 2 == 0 or move_type == 8 or move_type == 9 then
        quickpeek_reset_runtime()
        return
    end

    local weapon = entity.get_player_weapon(lp)
    local data = weapon and weapons(weapon)
    if not quickpeek_weapon_allowed(data) then
        quickpeek_reset_runtime()
        return
    end
    if not quickpeek_has_any_options(data) then
        quickpeek_reset_runtime()
        return
    end

    local next_primary = entity.get_prop(weapon, "m_flNextPrimaryAttack") or 0
    local tuning = quickpeek_get_tuning(data)
    local move_between_shots = quickpeek_has_option("Move between shots", data)
    local early_window = quickpeek_has_option("Early", data) and tuning.early or 0.08
    local now = globals.realtime()
    local curtime = globals.curtime()
    local tick = globals.tickcount()
    local user_forward = cmd.forwardmove or 0
    local user_side = cmd.sidemove or 0
    local user_moving = math.abs(user_forward) > 2 or math.abs(user_side) > 2
    local attacking = cmd.in_attack == 1
    if attacking then
        quickpeek_runtime.attack_until = now + 0.08
    end

    local in_attack_window = now < (quickpeek_runtime.attack_until or 0)
    local in_hold_window = now < (quickpeek_runtime.hold_until or 0)
    local in_ready_window = next_primary <= curtime + early_window

    if not in_attack_window and not in_hold_window then
        if user_moving then
            quickpeek_runtime.hold_until = 0
        end
        return
    end

    if not in_hold_window and not in_ready_window then
        return
    end

    local threat = client.current_threat()
    local has_damage_window = false
    if threat ~= nil and entity.is_alive(threat) and not entity.is_dormant(threat) then
        local ex, ey, ez = client.eye_position()
        local tx, ty, tz = entity.hitbox_position(threat, 3)
        if tx ~= nil then
            local _, damage = client.trace_bullet(lp, ex, ey, ez, tx, ty, tz, false)
            has_damage_window = (damage or 0) > 0
        end
    end

    if not in_hold_window and not has_damage_window then
        return
    end

    if user_moving and in_hold_window and not attacking and (move_between_shots or now > (quickpeek_runtime.attack_until or 0)) then
        quickpeek_runtime.hold_until = 0
        return
    end

    if move_between_shots and not in_ready_window and not in_hold_window then
        return
    end

    local vx = entity.get_prop(lp, "m_vecVelocity[0]") or 0
    local vy = entity.get_prop(lp, "m_vecVelocity[1]") or 0
    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > tuning.stop_speed then
        local _, view_yaw = client.camera_angles()
        local velocity_yaw = math.atan2 and math.deg(math.atan2(vy, vx)) or math.deg(math.atan(vy / (vx == 0 and 0.0001 or vx)))
        local relative = math.rad(normalize_yaw(velocity_yaw - view_yaw))
        cmd.forwardmove = -math.cos(relative) * 450
        cmd.sidemove = -math.sin(relative) * 450
    else
        if attacking or in_hold_window or tick ~= (quickpeek_runtime.last_stop_tick or -1) then
            cmd.forwardmove = 0
            cmd.sidemove = 0
        end
    end

    quickpeek_runtime.last_stop_tick = tick

    if quickpeek_has_option("Slow Motion", data) then
        cmd.in_speed = 1
    end
end

function quickpeek_autostop_on_fire()
    local lp = entity.get_local_player()
    local weapon = lp and entity.get_player_weapon(lp)
    local data = weapon and weapons(weapon)
    if ui.get(early_quickpeek_autostop) and quickpeek_assist_active() and quickpeek_weapon_allowed(data) and quickpeek_has_any_options(data) and not quickpeek_has_option("Move between shots", data) then
        local tuning = quickpeek_get_tuning(data)
        quickpeek_runtime.hold_until = globals.realtime() + math.min(0.11, tuning.release + (tuning.hold_bonus or 0))
    end
end

experimental_predict_runtime = experimental_predict_runtime or {
    owned = false,
    active = false,
    profile = nil,
    original = {},
    last_ping = 0,
    last_record_ticks = 0,
    last_future_ticks = 0
}

function experimental_predict_capture()
    local runtime = experimental_predict_runtime
    if runtime.owned then
        return true
    end
    if cvar == nil or cvar.cl_interp == nil or cvar.cl_interpolate == nil or cvar.cl_interp_ratio == nil then
        return false
    end

    local ok, interp, interpolate, ratio = pcall(function()
        return cvar.cl_interp:get_float(), cvar.cl_interpolate:get_int(), cvar.cl_interp_ratio:get_int()
    end)
    if not ok then
        return false
    end

    runtime.original = {
        cl_interp = interp,
        cl_interpolate = interpolate,
        cl_interp_ratio = ratio
    }
    runtime.owned = true
    return true
end

function experimental_predict_restore()
    local runtime = experimental_predict_runtime
    if runtime.owned and cvar ~= nil then
        local original = runtime.original or {}
        pcall(function()
            if original.cl_interp ~= nil and cvar.cl_interp ~= nil then
                cvar.cl_interp:set_float(original.cl_interp)
            end
            if original.cl_interpolate ~= nil and cvar.cl_interpolate ~= nil then
                cvar.cl_interpolate:set_int(original.cl_interpolate)
            end
            if original.cl_interp_ratio ~= nil and cvar.cl_interp_ratio ~= nil then
                cvar.cl_interp_ratio:set_int(original.cl_interp_ratio)
            end
        end)
    end

    runtime.owned = false
    runtime.active = false
    runtime.profile = nil
    runtime.original = {}
end

function experimental_predict_profile()
    local mode = ui.get(experimental_predict)
    local ping = math.max(0, (client.latency() or 0) * 1000)
    experimental_predict_runtime.last_ping = ping

    if mode == "Low Ping <= 40" and ping <= 40 then
        return "low"
    end
    if mode == "High Ping >= 55" and ping >= 55 then
        return "high"
    end
    return nil
end

function experimental_predict_apply(profile)
    local runtime = experimental_predict_runtime
    if runtime.profile ~= nil and runtime.profile ~= profile then
        experimental_predict_restore()
    end
    if not experimental_predict_capture() then
        return false
    end

    local ok = pcall(function()
        cvar.cl_interp:set_float(0)
        cvar.cl_interpolate:set_int(profile == "low" and 0 or 1)
        cvar.cl_interp_ratio:set_int(profile == "low" and 1 or 2)
    end)
    if not ok then
        experimental_predict_restore()
        return false
    end

    runtime.active = true
    runtime.profile = profile
    return true
end

function experimental_predict_update()
    local profile = experimental_predict_profile()
    if profile == nil then
        experimental_predict_restore()
        return false
    end
    return experimental_predict_apply(profile)
end

function experimental_predict_on_aim_fire(e)
    if not experimental_predict_runtime.active or e == nil or e.tick == nil then
        return
    end

    local record_ticks = globals.tickcount() - e.tick
    experimental_predict_runtime.last_record_ticks = record_ticks
    if record_ticks < 0 then
        experimental_predict_runtime.last_future_ticks = record_ticks
    end
end

ui.set_callback(experimental_predict, function()
    experimental_predict_restore()
end)
client.set_event_callback("setup_command", experimental_predict_update)
client.set_event_callback("level_init", experimental_predict_restore)
pcall(client.set_event_callback, "cs_game_disconnected", experimental_predict_restore)
pcall(client.set_event_callback, "game_newmap", experimental_predict_restore)
client.set_event_callback("shutdown", experimental_predict_restore)

cheat_revealer_runtime = {
    next_update = 0,
    memory_key = "panchan_cheat_revealer_memory_v2",
    memory = {},
    samples = {},
    observations = {},
    confidence = {}
}

function cheat_revealer_load_memory()
    local ok, saved = pcall(database.read, cheat_revealer_runtime.memory_key)
    if ok and type(saved) == "table" then
        cheat_revealer_runtime.memory = saved
    end
end

function cheat_revealer_identity(idx)
    if entity.get_steam64 ~= nil then
        local ok, steam64 = pcall(entity.get_steam64, idx)
        steam64 = ok and steam64 ~= nil and tostring(steam64) or nil
        if steam64 ~= nil and steam64 ~= "" and steam64 ~= "0" then
            return "steam:" .. steam64
        end
    end

    return "name:" .. string.lower(entity.get_player_name(idx) or tostring(idx))
end

function cheat_revealer_get_remembered(idx)
    local remembered = cheat_revealer_runtime.memory[cheat_revealer_identity(idx)]
    if type(remembered) == "table" then
        return remembered.cheat
    end
    if remembered == "NL" or remembered == "GS" then
        return remembered
    end
    return nil
end

function cheat_revealer_get_memory_info(idx)
    local remembered = cheat_revealer_runtime.memory[cheat_revealer_identity(idx)]
    if type(remembered) == "table" then
        return remembered
    end
    if remembered == "NL" or remembered == "GS" then
        return { cheat = remembered, confidence = 72, legacy = true }
    end
    return nil
end

function cheat_revealer_remember(idx, cheat, confidence, evidence)
    if cheat ~= "NL" and cheat ~= "GS" then
        return nil
    end

    confidence = clamp(math.floor((confidence or 75) + 0.5), 0, 100)
    if confidence < 72 then
        return nil
    end

    local key = cheat_revealer_identity(idx)
    local remembered = cheat_revealer_runtime.memory[key]
    if type(remembered) == "table" and remembered.cheat == cheat then
        if confidence <= (remembered.confidence or 0) then
            return cheat
        end
    elseif type(remembered) == "table" and remembered.cheat ~= cheat then
        local old_confidence = remembered.confidence or 72
        if confidence < old_confidence + 18 then
            return remembered.cheat
        end
    elseif (remembered == "NL" or remembered == "GS") and remembered ~= cheat and confidence < 88 then
        return remembered
    elseif remembered == cheat then
        return cheat
    end

    cheat_revealer_runtime.memory[key] = {
        cheat = cheat,
        name = entity.get_player_name(idx) or "unknown",
        confidence = confidence,
        evidence = evidence or "behavior",
        updated_at = globals.realtime()
    }
    pcall(database.write, cheat_revealer_runtime.memory_key, cheat_revealer_runtime.memory)
    pcall(database.flush)
    return cheat
end

-- The reveal source uses repeated unique samples instead of trusting one packet.
-- This behavioral fallback follows the same 4 confirmations / 5 seconds rule.
function cheat_revealer_probe(idx, allow_repeat)
    if not entity.is_alive(idx) or entity.is_dormant(idx) then
        return nil, nil
    end

    local now = globals.realtime()
    local simtime = entity.get_prop(idx, "m_flSimulationTime")
    local eye_yaw = entity.get_prop(idx, "m_angEyeAngles[1]")
    local eye_pitch = entity.get_prop(idx, "m_angEyeAngles[0]")
    local body_pose = entity.get_prop(idx, "m_flPoseParameter", 11)
    local origin_x, origin_y, origin_z = entity.get_prop(idx, "m_vecOrigin")
    local observation = cheat_revealer_runtime.observations[idx] or {delta_history = {}}

    if simtime == nil or eye_yaw == nil or (observation.simtime == simtime and not allow_repeat) then
        return nil, nil
    end

    local nl_score, gs_score = 0, 0
    local delta, delta_abs, pose_delta = 0, 0, 0
    local sim_ticks = 1
    body_pose = body_pose ~= nil and math.abs(body_pose * 120 - 60) or 0

    if observation.simtime ~= nil and observation.eye_yaw ~= nil then
        local sim_delta = simtime - observation.simtime
        sim_ticks = math.floor(sim_delta / globals.tickinterval() + 0.5)
        delta = normalize_yaw(eye_yaw - observation.eye_yaw)
        delta_abs = math.abs(delta)
        pose_delta = math.abs(body_pose - (observation.body_pose or body_pose))

        if delta_abs >= 12 and delta_abs <= 165 then
            observation.delta_history[#observation.delta_history + 1] = delta
            if #observation.delta_history > 6 then
                table.remove(observation.delta_history, 1)
            end

            local average, flips = 0, 0
            for i = 1, #observation.delta_history do
                average = average + math.abs(observation.delta_history[i])
                if i > 1 and observation.delta_history[i] * observation.delta_history[i - 1] < 0 then
                    flips = flips + 1
                end
            end
            average = average / math.max(#observation.delta_history, 1)

            local variance = 0
            for i = 1, #observation.delta_history do
                variance = variance + math.abs(math.abs(observation.delta_history[i]) - average)
            end
            variance = variance / math.max(#observation.delta_history, 1)

            local alternating = #observation.delta_history >= 3 and flips / (#observation.delta_history - 1) >= 0.6
            if alternating and variance <= math.max(18, average * 0.45) then
                if average >= 72 or delta_abs >= 92 then
                    nl_score = nl_score + 3
                else
                    gs_score = gs_score + 1
                end
            end
        end

        if delta_abs >= 88 and body_pose >= 8 then
            nl_score = nl_score + 4
        end
        if delta_abs >= 28 and delta_abs <= 68 and body_pose >= 20 and body_pose <= 58 and sim_ticks <= 2 and pose_delta <= 18 then
            gs_score = gs_score + 2
        end
        if sim_delta < -globals.tickinterval() * 0.5 or sim_ticks > 3 then
            nl_score = nl_score + 2
        end
        if sim_ticks >= 1 and sim_ticks <= 2 and pose_delta <= 20 and delta_abs <= 80 then
            gs_score = gs_score + 1
        end
        if pose_delta > 35 and sim_ticks <= 1 then
            nl_score = nl_score + 3
        end
        if observation.eye_pitch ~= nil and math.abs(eye_pitch - observation.eye_pitch) > 55 and sim_ticks > 1 then
            nl_score = nl_score + 2
        end

        if observation.origin_x ~= nil and origin_x ~= nil then
            local dx, dy, dz = origin_x - observation.origin_x, origin_y - observation.origin_y, origin_z - observation.origin_z
            if dx * dx + dy * dy + dz * dz > 4096 and nl_score < 3 then
                gs_score = gs_score + 1
            end
        end
    end

    local jitter = resolver_runtime.jitter[idx]
    local defensive = resolver_runtime.defensive[idx]
    local lagcomp = resolver_runtime.lagcomp[idx]
    if jitter ~= nil then
        if (jitter.flick_until or 0) > now then
            nl_score = nl_score + 4
        end
        if jitter.jitter_type == "OFFSET" and math.abs(jitter.last_delta or 0) >= 92 then
            nl_score = nl_score + 2
        end
        if (jitter.confidence or 0) >= 4 then
            nl_score = nl_score + 1
        end
        if jitter.jitter_type == "SKITTER" and math.abs(jitter.last_delta or 0) >= 72 then
            nl_score = nl_score + 2
        end
        if jitter.jitter_type == "CENTRE" and (jitter.confidence or 0) >= 4 and math.abs(jitter.last_delta or 0) <= 74 then
            gs_score = gs_score + 1
        end
        if jitter.jitter_type == "OFFSET" and math.abs(jitter.last_delta or 0) >= 35 and math.abs(jitter.last_delta or 0) <= 72 then
            gs_score = gs_score + 1
        end
    end
    if defensive ~= nil and (defensive.active_until or 0) > now then
        nl_score = nl_score + 3
    end
    if lagcomp ~= nil and (lagcomp.broken_until or 0) > now then
        gs_score = gs_score + 1
    end

    local strong_nl_signal = nl_score >= 5 or delta_abs >= 96 or (defensive ~= nil and (defensive.active_until or 0) > now) or (jitter ~= nil and (jitter.flick_until or 0) > now)
    if strong_nl_signal then
        gs_score = math.max(0, gs_score - 3)
        nl_score = nl_score + 1
    end

    observation.simtime = simtime
    observation.eye_yaw = eye_yaw
    observation.eye_pitch = eye_pitch
    observation.body_pose = body_pose
    observation.origin_x, observation.origin_y, observation.origin_z = origin_x, origin_y, origin_z
    cheat_revealer_runtime.observations[idx] = observation

    local signature = string.format("%.6f:%d:%d:%d", simtime, math.floor(delta_abs + 0.5), nl_score, gs_score)
    local diff = math.abs(nl_score - gs_score)
    if nl_score >= 5 and nl_score >= gs_score + 2 then
        local confidence = clamp(58 + nl_score * 7 + diff * 4, 0, 100)
        return "NL", signature, confidence, "nl-behavior"
    end
    if gs_score >= 6 and gs_score >= nl_score + 3 and not strong_nl_signal then
        local confidence = clamp(56 + gs_score * 7 + diff * 4, 0, 100)
        return "GS", signature, confidence, "gs-behavior"
    end
    return nil, signature
end

function cheat_revealer_classify(idx)
    local remembered_info = cheat_revealer_get_memory_info(idx)
    if remembered_info ~= nil then
        local corrected, corrected_signature, corrected_confidence, corrected_evidence = cheat_revealer_probe(idx, true)
        if corrected ~= nil and corrected_signature ~= nil then
            local remembered_confidence = remembered_info.confidence or 72
            if corrected == remembered_info.cheat then
                local stored = cheat_revealer_remember(idx, corrected, math.max(corrected_confidence or 0, remembered_confidence), corrected_evidence)
                return stored or remembered_info.cheat, math.max(corrected_confidence or 0, remembered_confidence)
            elseif (corrected_confidence or 0) >= remembered_confidence + 18 then
                local stored = cheat_revealer_remember(idx, corrected, corrected_confidence, corrected_evidence)
                return stored or corrected, corrected_confidence
            end
        end

        if (remembered_info.confidence or 0) >= 82 then
            return remembered_info.cheat, remembered_info.confidence
        end
    end

    local cheat, signature, confidence, evidence = cheat_revealer_probe(idx)
    if cheat == nil or signature == nil then
        return nil
    end

    local key = cheat_revealer_identity(idx)
    local sample_state = cheat_revealer_runtime.samples[key] or {items = {}, last_signature = nil}
    if sample_state.last_signature == signature then
        return nil
    end

    local now = globals.realtime()
    sample_state.last_signature = signature
    sample_state.items[#sample_state.items + 1] = {time = now, cheat = cheat, confidence = confidence or 0}
    for i = #sample_state.items, 1, -1 do
        if now - sample_state.items[i].time > 5 then
            table.remove(sample_state.items, i)
        end
    end

    local confirmations, opposite, confidence_sum = 0, 0, 0
    for i = 1, #sample_state.items do
        if sample_state.items[i].cheat == cheat then
            confirmations = confirmations + 1
            confidence_sum = confidence_sum + (sample_state.items[i].confidence or 0)
        else
            opposite = opposite + 1
        end
    end
    cheat_revealer_runtime.samples[key] = sample_state

    local avg_confidence = confirmations > 0 and confidence_sum / confirmations or 0
    if confirmations >= 4 and opposite <= 1 and avg_confidence >= 74 then
        local remembered = cheat_revealer_remember(idx, cheat, avg_confidence, evidence)
        if remembered ~= nil then
            return remembered, avg_confidence
        end
    end
    return nil
end

cheat_revealer_load_memory()

function cheat_revealer_update_list()
    local mode = ui.get(cheat_revealer)
    if mode ~= "Player List" and mode ~= "Both" then
        return
    end
    if globals.realtime() < cheat_revealer_runtime.next_update then
        return
    end

    cheat_revealer_runtime.next_update = globals.realtime() + 0.35
    local entries = {}
    local players = entity.get_players(true)
    for i = 1, #players do
        local idx = players[i]
        local cheat, confidence = cheat_revealer_classify(idx)
        if cheat ~= nil then
            entries[#entries + 1] = string.format("%s [%s %d%%]", entity.get_player_name(idx) or "unknown", cheat, confidence or 82)
        end
    end

    if #entries == 0 then
        entries[1] = "No detected cheats"
    else
        table.sort(entries)
    end
    ui.update(cheat_revealer_list, entries)
end

function cheat_revealer_flag_position(idx, x1, y1, x2, y2, text)
    local screen_width = client.screen_size()
    local row = 5
    if entity.get_prop(idx, "m_bIsScoped") == 1 then
        row = row + 1
    end
    if entity.get_prop(idx, "m_bIsDefusing") == 1 then
        row = row + 1
    end
    if (entity.get_prop(idx, "m_flFlashDuration") or 0) > 0 then
        row = row + 1
    end

    local y = math.min(y1 + row * 9, y2 - 10)
    local text_width = renderer.measure_text("d-", text) or 0
    if x2 + text_width + 8 < screen_width then
        return x2 + 5, y, "d-"
    end
    return x1 - 5, y, "rd-"
end

function jitter_correction_flag_text(idx)
    if jitter_correction_esp_flag == nil or not ui.get(jitter_correction_esp_flag) or not ui.get(jitter_correction) then
        return nil
    end

    local state = resolver_runtime and resolver_runtime.jitter and resolver_runtime.jitter[idx]
    if state == nil then
        return nil
    end

    if state.gate_mode == "PASS" then
        return nil
    end

    local now = globals.realtime()
    if (state.active_until or 0) <= now and (state.detected_until or 0) <= now and (state.confidence or 0) < 2 then
        return nil
    end

    local amount = state.gate_amount or state.amount
    if amount == nil or math.abs(amount) < 8 then
        amount = resolver_resolve_body_amount(state, state.resolved_side or 1, state.amplitude or 60)
    end
    if amount == nil or math.abs(amount) < 8 then
        return nil
    end

    local side = amount >= 0 and "R" or "L"
    return string.format("JITTER %d° %s", math.floor(math.abs(amount) + 0.5), side)
end

function jitter_correction_flag_position(idx, x1, y1, x2, y2, text)
    local screen_width = client.screen_size()
    local row = 6
    if entity.get_prop(idx, "m_bIsScoped") == 1 then
        row = row + 1
    end
    if entity.get_prop(idx, "m_bIsDefusing") == 1 then
        row = row + 1
    end
    if (entity.get_prop(idx, "m_flFlashDuration") or 0) > 0 then
        row = row + 1
    end

    local y = math.min(y1 + row * 9, y2 - 10)
    local text_width = renderer.measure_text("d-", text) or 0
    if x2 + text_width + 8 < screen_width then
        return x2 + 5, y, "d-"
    end
    return x1 - 5, y, "rd-"
end

function render_jitter_correction_esp_flag()
    if jitter_correction_esp_flag == nil or not ui.get(jitter_correction_esp_flag) or not ui.get(jitter_correction) then
        return
    end

    local players = entity.get_players(true)
    for i = 1, #players do
        local idx = players[i]
        if entity.is_alive(idx) and not entity.is_dormant(idx) then
            local text = jitter_correction_flag_text(idx)
            if text ~= nil then
                local x1, y1, x2, y2, alpha = entity.get_bounding_box(idx)
                if x1 ~= nil and alpha ~= nil and alpha > 0 then
                    local flag_x, flag_y, flag_align = jitter_correction_flag_position(idx, x1, y1, x2, y2, text)
                    renderer.text(flag_x, flag_y, 255, 255, 255, math.floor(255 * alpha), flag_align, 0, text)
                end
            end
        end
    end
end

function render_cheat_revealer()
    local mode = ui.get(cheat_revealer)
    local show_cheat_esp = mode == "ESP Flag" or mode == "Both"
    local players = entity.get_players(true)

    for i = 1, #players do
        local idx = players[i]
        if entity.is_alive(idx) and not entity.is_dormant(idx) then
            local x1, y1, x2, y2, alpha = entity.get_bounding_box(idx)
            if x1 ~= nil and alpha ~= nil and alpha > 0 then
                if show_cheat_esp then
                    local cheat = cheat_revealer_classify(idx)
                    if cheat ~= nil then
                        local flag_x, flag_y, flag_align = cheat_revealer_flag_position(idx, x1, y1, x2, y2, cheat)
                        renderer.text(flag_x, flag_y, 255, 255, 255, math.floor(255 * alpha), flag_align, 0, cheat)
                    end
                end
            end
        end
    end

    cheat_revealer_update_list()
end

;(function()
    local voice_message_ptr_t = ffi.typeof([[
        struct {
            char pad_0000[8];
            int32_t client;
            int32_t audible_mask;
            uint32_t xuid_low;
            uint32_t xuid_high;
            void* voice_data;
            int32_t proximity;
            int32_t format;
            int32_t sequence_bytes;
            uint32_t section_number;
            uint32_t uncompressed_sample_offset;
            int32_t cached_size;
            uint32_t flags;
            uint8_t no_stack_overflow[0xFF];
        }*
    ]])
    local packed_words = ffi.new("uint32_t[5]")
    local decoded_bytes = ffi.new("uint8_t[20]")
    shared_esp_neverlose_packets = shared_esp_neverlose_packets or {}
    shared_esp_neverlose_reports = shared_esp_neverlose_reports or {}
    shared_esp_neverlose_trust = shared_esp_neverlose_trust or {senders = {}, sequences = {}}
    local packets = shared_esp_neverlose_packets
    local reports = shared_esp_neverlose_reports
    local trust = shared_esp_neverlose_trust
    trust.senders = trust.senders or {}
    trust.sequences = trust.sequences or {}
    local magic = 0xAE6B
    local seed_salt = 0x7F21
    local packet_lifetime = 1.5
    local aim_lifetime = 0.38

    local function read_bits(state, count)
        local value = 0
        local shift = 0

        while count > 0 and state.pos < state.size do
            local available = 8 - state.bit_pos
            local take = math.min(count, available)
            local mask = bit.lshift(1, take) - 1
            local part = bit.band(bit.rshift(state.data[state.pos], state.bit_pos), mask)

            value = bit.bor(value, bit.lshift(part, shift))
            state.bit_pos = state.bit_pos + take
            count = count - take
            shift = shift + take

            if state.bit_pos == 8 then
                state.bit_pos = 0
                state.pos = state.pos + 1
            end
        end

        return value
    end

    local function read_coord(state)
        local has_integer = read_bits(state, 1)
        local has_fraction = read_bits(state, 1)
        if has_integer == 0 and has_fraction == 0 then
            return 0
        end

        local negative = read_bits(state, 1)
        local integer = has_integer == 1 and (read_bits(state, 14) + 1) or 0
        local fraction = has_fraction == 1 and read_bits(state, 5) or 0
        local value = integer + fraction * 0.03125
        return negative == 1 and -value or value
    end

    local function sender_steam64(idx)
        if entity.get_steam64 == nil then
            return nil
        end

        local ok, steam64 = pcall(entity.get_steam64, idx)
        if not ok or steam64 == nil then
            return nil
        end

        steam64 = tostring(steam64)
        if steam64 == "" or steam64 == "0" then
            return nil
        end
        return steam64
    end

    local function sender_is_teammate(sender)
        local me = entity.get_local_player()
        if me == nil or sender == nil or sender == me or sender < 1 or sender > 64 then
            return false
        end

        local my_team = entity.get_prop(me, "m_iTeamNum")
        local sender_team = entity.get_prop(sender, "m_iTeamNum")
        return my_team ~= nil and my_team > 1 and sender_team == my_team
    end

    local function tick_delta(current, previous)
        local delta = bit.band((current or 0) - (previous or 0), 0x7FF)
        if delta > 1024 then
            delta = delta - 2048
        end
        return delta
    end

    local function clear_table(tbl)
        for key in pairs(tbl or {}) do
            tbl[key] = nil
        end
    end

    local shared_sound_types_ready = pcall(ffi.typeof, "panchan_shared_sound_params_t")
    if not shared_sound_types_ready then
        shared_sound_types_ready = pcall(ffi.cdef, [[
            typedef struct {
                float x;
                float y;
                float z;
            } panchan_shared_sound_vec3_t;

            typedef struct panchan_shared_sound_params_t {
                int userdata;
                int soundsource;
                int entchannel;
                uintptr_t pSfx;
                panchan_shared_sound_vec3_t origin;
                panchan_shared_sound_vec3_t direction;
                float fvol;
                int soundlevel;
                int flags;
                int pitch;
                float delay;
                int speakerentity;
                int initialStreamPosition;
                int skipInitialSamples;
                int m_nQueuedGUID;
                unsigned int m_nSoundScriptHash;
                uintptr_t m_pSoundEntryName;
                uintptr_t m_pOperatorsKV;
                float opStackElapsedTime;
                float opStackElapsedStopTime;
                unsigned char staticsound : 1;
                unsigned char bUpdatePositions : 1;
                unsigned char fromserver : 1;
                unsigned char bToolSound : 1;
                unsigned char m_bIsScriptHandle : 1;
                unsigned char m_bDelayedStart : 1;
                unsigned char m_bInEyeSound : 1;
                unsigned char m_bHRTFFollowEntity : 1;
                unsigned char m_bHRTFBilinear : 1;
                unsigned char m_bHRTFLock : 1;
            } panchan_shared_sound_params_t;
        ]])
    end

    local shared_sound_bridge = {
        initialized = false,
        available = shared_sound_types_ready,
        start_sound = nil,
        find_name = nil,
        sound_handle = nil,
        entry_name = nil,
        failures = 0,
        last_emit = {}
    }

    local function shared_sound_reset(full)
        clear_table(shared_sound_bridge.last_emit)
        shared_sound_bridge.failures = 0

        if full then
            shared_sound_bridge.initialized = false
            shared_sound_bridge.available = shared_sound_types_ready
            shared_sound_bridge.start_sound = nil
            shared_sound_bridge.find_name = nil
            shared_sound_bridge.sound_handle = nil
            shared_sound_bridge.entry_name = nil
        end
    end

    local function shared_sound_initialize()
        if shared_sound_bridge.initialized then
            return shared_sound_bridge.available
        end

        shared_sound_bridge.initialized = true
        if not shared_sound_bridge.available or type(client.find_signature) ~= "function" then
            shared_sound_bridge.available = false
            return false
        end

        local start_ok, start_address = pcall(
            client.find_signature,
            "engine.dll",
            "\x55\x8B\xEC\x81\xEC\x24\x01\x00\x00\x53\x56"
        )
        local find_ok, find_address = pcall(
            client.find_signature,
            "engine.dll",
            "\x55\x8B\xEC\x81\xEC\x1C\x01\x00\x00\x53\x56\x8B"
        )

        if not start_ok or not find_ok or start_address == nil or find_address == nil then
            shared_sound_bridge.available = false
            return false
        end

        local start_cast_ok, start_sound = pcall(
            ffi.cast,
            "int(__fastcall*)(panchan_shared_sound_params_t*, void*)",
            start_address
        )
        local find_cast_ok, find_name = pcall(
            ffi.cast,
            "uintptr_t(__fastcall*)(const char*, int*)",
            find_address
        )

        if not start_cast_ok or not find_cast_ok or start_sound == nil or find_name == nil then
            shared_sound_bridge.available = false
            return false
        end

        local entry_ok, entry_name = pcall(ffi.new, "char[260]", "Land_Concrete.StepLeft")
        local handle_ok, sound_handle = pcall(find_name, "player/land.wav", nil)
        if not entry_ok or not handle_ok or sound_handle == nil or tonumber(sound_handle) == 0 then
            shared_sound_bridge.available = false
            return false
        end

        shared_sound_bridge.start_sound = start_sound
        shared_sound_bridge.find_name = find_name
        shared_sound_bridge.sound_handle = sound_handle
        shared_sound_bridge.entry_name = entry_name
        return true
    end

    local function shared_sound_emit(target, x, y, z, packet)
        if not ui.get(shared_esp_neverlose)
            or target == nil
            or not entity.is_alive(target)
            or not entity.is_enemy(target)
            or not entity.is_dormant(target)
        then
            return false
        end

        local confidence = packet and (packet.aim_confidence or packet.confidence) or 0
        if confidence < 0.4 then
            return false
        end

        local now = globals.realtime()
        local previous = shared_sound_bridge.last_emit[target]
        if previous ~= nil then
            local elapsed = now - (previous.time or 0)
            if elapsed < 0.035 then
                return false
            end

            local dx = x - (previous.x or x)
            local dy = y - (previous.y or y)
            local dz = z - (previous.z or z)
            if dx * dx + dy * dy + dz * dz < 1 and elapsed < 0.09 then
                return false
            end
        end

        if not shared_sound_initialize() then
            return false
        end

        local params = ffi.new("panchan_shared_sound_params_t")
        params.userdata = 0
        params.soundsource = target
        params.entchannel = 4
        params.pSfx = shared_sound_bridge.sound_handle
        params.origin.x = x
        params.origin.y = y
        params.origin.z = z
        params.direction.x = 0
        params.direction.y = 0
        params.direction.z = 0
        params.fvol = 0.01
        params.soundlevel = 60
        params.flags = 1024
        params.pitch = 100
        params.delay = 0
        params.speakerentity = -1
        params.initialStreamPosition = 0
        params.skipInitialSamples = 0
        params.m_nQueuedGUID = -1
        params.m_nSoundScriptHash = 892530346
        params.m_pSoundEntryName = ffi.cast("uintptr_t", shared_sound_bridge.entry_name)
        params.m_pOperatorsKV = 0
        params.opStackElapsedTime = 0
        params.opStackElapsedStopTime = 0
        params.staticsound = 1
        params.bUpdatePositions = 1
        params.fromserver = 1
        params.bToolSound = 0
        params.m_bIsScriptHandle = 1
        params.m_bDelayedStart = 0
        params.m_bInEyeSound = 0
        params.m_bHRTFFollowEntity = 0
        params.m_bHRTFBilinear = 0
        params.m_bHRTFLock = 0

        local emitted = pcall(shared_sound_bridge.start_sound, params, nil)
        if not emitted then
            shared_sound_bridge.failures = shared_sound_bridge.failures + 1
            if shared_sound_bridge.failures >= 2 then
                shared_sound_bridge.available = false
                shared_sound_bridge.start_sound = nil
                shared_sound_bridge.find_name = nil
            end
            return false
        end

        shared_sound_bridge.failures = 0
        shared_sound_bridge.last_emit[target] = {
            time = now,
            x = x,
            y = y,
            z = z
        }
        packet.engine_applied_at = now
        return true
    end

    function shared_esp_clear_runtime()
        clear_table(packets)
        clear_table(reports)
        clear_table(trust.senders)
        clear_table(trust.sequences)
        shared_sound_reset(false)
    end

    function shared_esp_feedback(target, sender, hit)
        if sender == nil then
            return
        end

        local sender_state = trust.senders[sender] or {score = 0.62, hits = 0, misses = 0}
        if hit then
            sender_state.hits = (sender_state.hits or 0) + 1
            sender_state.score = clamp((sender_state.score or 0.62) + 0.035, 0.25, 0.92)
        else
            sender_state.misses = (sender_state.misses or 0) + 1
            sender_state.score = clamp((sender_state.score or 0.62) - 0.06, 0.25, 0.92)
        end
        trust.senders[sender] = sender_state

        local target_reports = reports[target]
        if target_reports ~= nil and target_reports[sender] ~= nil then
            target_reports[sender].trust = sender_state.score
        end
    end

    local function rebuild_target_packet(target, now)
        local target_reports = reports[target]
        if target_reports == nil then
            packets[target] = nil
            return
        end

        local freshest
        for sender, report in pairs(target_reports) do
            if now - (report.received_at or 0) > packet_lifetime then
                target_reports[sender] = nil
            elseif freshest == nil or (report.received_at or 0) > (freshest.received_at or 0) then
                freshest = report
            end
        end

        if freshest == nil then
            reports[target] = nil
            packets[target] = nil
            return
        end

        local consensus = 0
        local consensus_trust = 0
        for _, report in pairs(target_reports) do
            local dx = report.x - freshest.x
            local dy = report.y - freshest.y
            local dz = report.z - freshest.z
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            local time_delta = math.abs((report.received_at or 0) - (freshest.received_at or 0))
            if distance <= 80 and time_delta <= 0.45 then
                consensus = consensus + 1
                consensus_trust = consensus_trust + (report.trust or 0.5)
            end
        end

        local average_trust = consensus > 0 and consensus_trust / consensus or (freshest.trust or 0.5)
        local confidence = clamp((freshest.trust or 0.5) * 0.72 + average_trust * 0.28 + math.min(consensus - 1, 2) * 0.12, 0.1, 0.96)
        local effective_age = math.max(0, now - (freshest.received_at or now)) + math.max(0, freshest.tick_age or 0)
        local aim_ttl = clamp(0.18 + confidence * 0.28 + math.min(consensus - 1, 2) * 0.05, 0.22, 0.52)
        local aim_valid = freshest.tick_valid == true and effective_age <= 0.5 and confidence >= 0.38
        local aim_until = aim_valid
            and ((freshest.received_at or now) + aim_ttl - math.max(0, freshest.tick_age or 0))
            or (now - 1)
        local old = packets[target]

        packets[target] = {
            x = freshest.x,
            y = freshest.y,
            z = freshest.z,
            health = freshest.health,
            sender = freshest.sender,
            tick = freshest.tick,
            tick_age = freshest.tick_age,
            received_at = freshest.received_at,
            effective_age = effective_age,
            confidence = confidence,
            consensus = consensus,
            aim_valid = aim_valid,
            aim_until = aim_until,
            priority_until = aim_until,
            visual_until = (freshest.received_at or now) + packet_lifetime,
            source = "NL",
            render_x = old and old.render_x or freshest.x,
            render_y = old and old.render_y or freshest.y,
            render_z = old and old.render_z or freshest.z
        }
    end

    local function decode_voice_message(message)
        if not ui.get(shared_esp_neverlose) or message == nil then
            return
        end

        local voice = ffi.cast(voice_message_ptr_t, message)[0]
        local sender = tonumber(voice.client) + 1
        if not sender_is_teammate(sender) then
            return
        end

        local steam64 = sender_steam64(sender)
        if steam64 == nil then
            return
        end

        packed_words[0] = voice.xuid_low
        packed_words[1] = voice.xuid_high
        packed_words[2] = voice.sequence_bytes
        packed_words[3] = voice.section_number
        packed_words[4] = voice.uncompressed_sample_offset
        ffi.copy(decoded_bytes, ffi.cast("uint8_t*", packed_words), 20)

        local key = string.format("nle_%s_%d", steam64, seed_salt)
        for i = 0, 19 do
            decoded_bytes[i] = bit.bxor(decoded_bytes[i], string.byte(key, i % #key + 1))
        end

        local reader = {data = decoded_bytes, size = 20, pos = 0, bit_pos = 0}
        if read_bits(reader, 16) ~= bit.bxor(magic, seed_salt) then
            return
        end

        local target = bit.bxor(read_bits(reader, 7), bit.band(seed_salt, 0x7F))
        local health = bit.bxor(read_bits(reader, 11), bit.band(seed_salt, 0x7FF))
        local shared_tick = bit.bxor(read_bits(reader, 11), bit.band(seed_salt, 0x7FF))
        local z = read_coord(reader)
        local y = read_coord(reader)
        local x = read_coord(reader)
        local checksum = read_bits(reader, 16)
        local expected_checksum = bit.band(bit.bxor(bit.bxor(target, health), seed_salt), 0xFFFF)

        if checksum ~= expected_checksum or target < 1 or target > 64 then
            return
        end
        if health < 0 or health > 120 or x == 0 or y == 0 or z == 0 then
            return
        end
        if math.abs(x) > 16384 or math.abs(y) > 16384 or math.abs(z) > 16384 then
            return
        end
        if not entity.is_enemy(target) then
            return
        end

        local now = globals.realtime()
        local local_tick = bit.band(globals.tickcount(), 0x7FF)
        local tick_age_ticks = tick_delta(local_tick, shared_tick)
        local tick_is_plausible = tick_age_ticks >= -8 and tick_age_ticks <= 128
        local tick_age = tick_is_plausible and math.max(0, tick_age_ticks) * globals.tickinterval() or 0
        local sequence_key = tostring(sender) .. ":" .. tostring(target)
        local previous = trust.sequences[sequence_key]
        local forward_ticks = previous ~= nil and tick_delta(shared_tick, previous.tick) or 1

        if previous ~= nil and forward_ticks <= 0 and now - (previous.received_at or 0) < packet_lifetime then
            return
        end

        local jump_penalty = 0
        if previous ~= nil and previous.x ~= nil then
            local dx = x - previous.x
            local dy = y - previous.y
            local dz = z - previous.z
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            local elapsed = math.max(now - (previous.received_at or now), math.max(forward_ticks, 1) * globals.tickinterval(), globals.tickinterval())
            local measured_speed = distance / elapsed

            if distance > 1200 then
                return
            end
            jump_penalty = clamp((measured_speed - 650) / 4200, 0, 0.35)
        end

        local sender_state = trust.senders[sender] or {score = 0.62, hits = 0, misses = 0}
        trust.senders[sender] = sender_state
        local packet_trust = clamp((sender_state.score or 0.62) - tick_age * 0.45 - jump_penalty - (tick_is_plausible and 0 or 0.12), 0.1, 0.95)
        local report = {
            x = x,
            y = y,
            z = z,
            health = health,
            sender = sender,
            tick = shared_tick,
            tick_age = tick_age,
            tick_valid = tick_is_plausible and tick_age_ticks >= -8 and tick_age_ticks <= 32,
            received_at = now,
            trust = packet_trust
        }

        reports[target] = reports[target] or {}
        reports[target][sender] = report
        trust.sequences[sequence_key] = report
        rebuild_target_packet(target, now)

        local active_packet = packets[target]
        if active_packet ~= nil
            and active_packet.aim_valid
            and packet_trust >= 0.4
            and now <= (active_packet.aim_until or 0)
        then
            shared_sound_emit(target, active_packet.x, active_packet.y, active_packet.z, active_packet)
        end
    end

    local function draw_box(x, y, w, h, r, g, b, a)
        renderer.rectangle(x, y, w, 1, r, g, b, a)
        renderer.rectangle(x, y + h - 1, w, 1, r, g, b, a)
        renderer.rectangle(x, y, 1, h, r, g, b, a)
        renderer.rectangle(x + w - 1, y, 1, h, r, g, b, a)
    end

    local function render_shared_esp()
        if not ui.get(shared_esp_neverlose) then
            return
        end

        local now = globals.realtime()
        for idx, packet in pairs(packets) do
            if now > (packet.visual_until or ((packet.received_at or 0) + packet_lifetime)) or not entity.is_alive(idx) then
                packets[idx] = nil
                reports[idx] = nil
            elseif entity.is_dormant(idx) then
                packet.render_x = (packet.render_x or packet.x) * 0.7 + packet.x * 0.3
                packet.render_y = (packet.render_y or packet.y) * 0.7 + packet.y * 0.3
                packet.render_z = (packet.render_z or packet.z) * 0.7 + packet.z * 0.3

                local duck = clamp(entity.get_prop(idx, "m_flDuckAmount") or 0, 0, 1)
                local player_height = 72 - duck * 18
                local top_x, top_y = renderer.world_to_screen(packet.render_x, packet.render_y, packet.render_z + player_height)
                local bottom_x, bottom_y = renderer.world_to_screen(packet.render_x, packet.render_y, packet.render_z)
                if top_x ~= nil and bottom_x ~= nil then
                    local height = math.abs(bottom_y - top_y)
                    local width = math.max(4, height * 0.5)
                    local box_x = top_x - width * 0.5
                    local box_y = math.min(top_y, bottom_y)
                    local health = math.max(0, math.min(100, packet.health))
                    local hp_height = height * health / 100
                    local packet_age = math.max(0, now - (packet.received_at or now)) + math.max(0, packet.tick_age or 0)
                    local fade = 1 - clamp(packet_age / packet_lifetime, 0, 1)
                    local alpha = math.floor(220 * fade * (0.55 + (packet.confidence or 0.5) * 0.45))
                    local status = string.format("NL %dms x%d %d%%", math.floor(packet_age * 1000 + 0.5), packet.consensus or 1, math.floor((packet.confidence or 0) * 100 + 0.5))

                    draw_box(box_x - 1, box_y - 1, width + 2, height + 2, 0, 0, 0, math.min(180, alpha))
                    draw_box(box_x, box_y, width, height, 255, 255, 255, alpha)
                    renderer.rectangle(box_x - 5, box_y - 1, 3, height + 2, 0, 0, 0, math.min(180, alpha))
                    renderer.rectangle(box_x - 4, box_y + height - hp_height, 1, hp_height, 255, 255, 255, alpha)
                    renderer.text(top_x, box_y - 10, 255, 255, 255, alpha, "cd-", 0, entity.get_player_name(idx) or "enemy")
                    renderer.text(top_x, box_y + height + 3, 200, 200, 200, math.min(210, alpha), "cd-", 0, status)
                end
            else
                packets[idx] = nil
                reports[idx] = nil
            end
        end
    end

    pcall(client.set_event_callback, 127, function(message)
        local ok = pcall(decode_voice_message, message)
        if not ok then
            return
        end
    end)
    client.set_event_callback("paint", function() render_shared_esp() end)
    client.set_event_callback("round_start", shared_esp_clear_runtime)
    client.set_event_callback("shutdown", function()
        shared_esp_clear_runtime()
        shared_sound_reset(true)
    end)
    ui.set_callback(shared_esp_neverlose, function()
        if not ui.get(shared_esp_neverlose) then
            shared_esp_clear_runtime()
        end
    end)
end)()

function shared_esp_get_packet(idx)
    local packet = shared_esp_neverlose_packets and shared_esp_neverlose_packets[idx]
    if packet == nil then
        return nil
    end

    local now = globals.realtime()
    if now > (packet.visual_until or 0) then
        shared_esp_neverlose_packets[idx] = nil
        return nil
    end

    if now > (packet.aim_until or packet.priority_until or 0) then
        return nil
    end

    local effective_age = math.max(0, now - (packet.received_at or now)) + math.max(0, packet.tick_age or 0)
    local age_decay = 1 - clamp(effective_age / 0.65, 0, 1) * 0.7
    local confidence = clamp((packet.confidence or 0.5) * age_decay, 0, 1)
    if confidence < 0.38 then
        return nil
    end

    packet.effective_age = effective_age
    packet.aim_confidence = confidence
    return packet
end

local function get_shot_id(id)
    return ((id or 0) % 15) + 1
end

local function get_hurt_verb(weapon)
    weapon = tostring(weapon or "")

    if weapon == "hegrenade" then
        return "Naded"
    elseif weapon == "inferno" or weapon == "molotov" or weapon == "incgrenade" then
        return "Burned"
    elseif weapon == "taser" then
        return "Zeused"
    elseif weapon:find("knife", 1, true) then
        return "Knifed"
    end

    return nil
end

function aim_fire(e)
    jitter_on_fire(e)
    experimental_predict_on_aim_fire(e)
    if dormant_shot_ledger_attach_event ~= nil then
        dormant_shot_ledger_attach_event(e)
    end
    quickpeek_autostop_on_fire()
    hirate_shots = hirate_shots + 1

    local flags = {}
    if e.teleported then table.insert(flags, "LC") end
    if e.interpolated then table.insert(flags, "I") end
    if e.extrapolated then table.insert(flags, "EX") end
    if e.high_priority then table.insert(flags, "HP") end
    if experimental_predict_runtime.active and e.tick ~= nil and globals.tickcount() - e.tick < 0 then
        table.insert(flags, "PR")
    end

    fireData[e.id] = {
        tick = e.tick,
        predicted_damage = e.damage,
        predicted_hitgroup = e.hitgroup,
        hit_chance = e.hit_chance,
        backtrack_ticks = globals.tickcount() - e.tick,
        shot_id = get_shot_id(e.id),
        flags = #flags > 0 and table.concat(flags) or nil,
        teleported = e.teleported == true,
        interpolated = e.interpolated == true,
        extrapolated = e.extrapolated == true,
        high_priority = e.high_priority == true,
        target = e.target,
        timestamp = client.timestamp()
    }
end

function aim_hit(e)
    jitter_on_hit(e)
    hirate_hits = hirate_hits + 1
    if e.hitgroup == 1 then
        hirate_headshots = hirate_headshots + 1
    end

    if e.hitgroup == 1 and entity.get_prop(e.target, "m_iHealth") <= 0 then
        taps = taps + 1
    end

    if not ui.get(hit_logs) then
        fireData[e.id] = nil
        return
    end
    local stored = fireData[e.id]
    local predicted_hitgroup = stored and stored.predicted_hitgroup or e.hitgroup
    local group = predicted_hitgroup ~= e.hitgroup and string.format("%s (%s)", hitgroup_names[e.hitgroup + 1] or "?", hitgroup_names[predicted_hitgroup + 1] or "?") or hitgroup_names[e.hitgroup + 1] or "?"
    local backtrack_ticks = stored and stored.backtrack_ticks or 0
    local predicted_damage = stored and stored.predicted_damage or e.damage
    local damage_info = predicted_damage ~= e.damage and string.format("%d (%d)", e.damage, predicted_damage) or tostring(e.damage)
    local hit_chance = tostring(stored and stored.hit_chance or "?")
    local delay = stored and math.ceil(client.timestamp() - stored.timestamp, 0) or 0
    local shot_id = stored and stored.shot_id or get_shot_id(e.id)
    local flags = stored and stored.flags or "none"
    local hp_left = entity.get_prop(e.target, "m_iHealth") or 0
    local mismatch = {}

    if stored then
        if predicted_damage ~= e.damage then
            table.insert(mismatch, "dmg: " .. tostring(predicted_damage))
        end

        if predicted_hitgroup ~= e.hitgroup then
            table.insert(mismatch, "hitgroup: " .. tostring(hitgroup_names[predicted_hitgroup + 1] or "?"))
        end
    end

    local mismatch_text = #mismatch > 0 and string.format(", mismatch: [%s]", table.concat(mismatch, " | ")) or ""
    local message = string.format("Registered #%02d shot in %s's %s for %s dmg (hp: %d, hc: %s%%, bt: %dt, delay: %s ms, flags: %s%s)",
        shot_id,
        entity.get_player_name(e.target),
        group,
        damage_info,
        hp_left,
        hit_chance,
        backtrack_ticks,
        delay,
        flags,
        mismatch_text
    )

    if contains(ui.get(hit_logs_type), "Under Crosshair") then
        add_log(message, 3, ui.get(hit_logs_color))
    end

    if contains(ui.get(hit_logs_type), "Console") then
        print(message)
    end

    fireData[e.id] = nil
end

function render_hirate_indicator()
    if not ui.get(hirate_indicator) then
        return
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return
    end

    local shots = hirate_shots or 0
    local hits = hirate_hits or 0
    local headshots = hirate_headshots or 0

    local hitrate = shots > 0 and (hits / shots) * 100 or 0
    local hsrate = hits > 0 and (headshots / hits) * 100 or 0

    local text = string.format("%d/%d (%.2f%% / %.2f%%)", hits, shots, hitrate, hsrate)
    renderer.indicator(255, 255, 255, 255, text)
end

dormant_stats = dormant_stats or {
    shots = 0,
    hits = 0,
    last_name = "-",
    last_hitbox = "-",
    last_damage = 0,
    last_fov = 0,
    last_accuracy = 0,
    last_confidence = 0,
    last_target_time = 0,
    last_shot_time = 0,
    hp_cache = {}
}
dormant_stats.hp_cache = dormant_stats.hp_cache or {}
dormant_stats.lock_target = dormant_stats.lock_target or nil
dormant_stats.lock_until = dormant_stats.lock_until or 0
dormant_stats.shot_ledger = dormant_stats.shot_ledger or {}
dormant_stats.next_shot_id = dormant_stats.next_shot_id or 0
dormant_prefer_body_aim = true
dormant_seed_count = 24

dormant_hitbox_offsets = dormant_hitbox_offsets or {
    Head = {
        { x = 0, y = 0, z = 58, duck = 10 },
        { x = 3, y = 0, z = 56, duck = 10 },
        { x = -3, y = 0, z = 56, duck = 10 }
    },
    Chest = {
        { x = 0, y = 0, z = 50, duck = 4 },
        { x = 4, y = 0, z = 48, duck = 4 },
        { x = -4, y = 0, z = 48, duck = 4 }
    },
    Stomach = {
        { x = 0, y = 0, z = 40, duck = 0 },
        { x = 4, y = 0, z = 38, duck = 0 },
        { x = -4, y = 0, z = 38, duck = 0 }
    },
    Legs = {
        { x = 0, y = 0, z = 20, duck = 0 },
        { x = 3, y = 0, z = 16, duck = 0 },
        { x = -3, y = 0, z = 16, duck = 0 },
        { x = 6, y = 0, z = 24, duck = 0 },
        { x = -6, y = 0, z = 24, duck = 0 },
        { x = 8, y = 0, z = 10, duck = 0 },
        { x = -8, y = 0, z = 10, duck = 0 }
    }
}

dormant_hitbox_anchor_groups = dormant_hitbox_anchor_groups or {
    Head = { { 0 } },
    Chest = { { 5, 6, 4 } },
    Stomach = { { 3, 2 } },
    Legs = { { 7 }, { 8 }, { 9 }, { 10 }, { 11 }, { 12 } }
}

dormant_hitbox_anchor_radius = dormant_hitbox_anchor_radius or {
    Head = 3,
    Chest = 4,
    Stomach = 4,
    Legs = 0
}

dormant_net_data = dormant_net_data or {}
dormant_prediction = dormant_prediction or {
    reset_time = 2.8,
    max_lead_time = 0.22,
    min_speed = 15,
    max_speed = 450,
    velocity_smoothing = 0.55,
    acceleration_weight = 0.5,
    hypothesis_scales = {0.72, 1.0, 1.18}
}
dormant_prediction.reset_time = math.max(dormant_prediction.reset_time or 2.8, 2.8)
dormant_prediction.max_lead_time = dormant_prediction.max_lead_time or 0.22
dormant_prediction.min_speed = 15
dormant_prediction.max_speed = dormant_prediction.max_speed or 450
dormant_prediction.velocity_smoothing = dormant_prediction.velocity_smoothing or 0.55
dormant_prediction.acceleration_weight = dormant_prediction.acceleration_weight or 0.5
dormant_prediction.hypothesis_scales = dormant_prediction.hypothesis_scales or {0.72, 1.0, 1.18}

function dormant_lagcomp_enabled()
    if cvar == nil or cvar.cl_lagcompensation == nil then
        return true
    end

    local ok, value = pcall(function()
        return cvar.cl_lagcompensation:get_int()
    end)
    return not ok or value ~= 0
end

function dormant_alpha_255(alpha)
    alpha = tonumber(alpha)
    if alpha == nil then
        return 255
    end
    if alpha >= 0 and alpha <= 1 then
        alpha = alpha * 255
    end
    return clamp(alpha, 0, 255)
end

function dormant_hotkey_active()
    if dormant_aimbot_key == nil then
        return true
    end

    local active, _, key = ui.get(dormant_aimbot_key)
    return active == true or key == nil or key == 0
end

dormant_trace_offsets = dormant_trace_offsets or {
    Head = { 0, 3, -3, 5, -5 },
    Chest = { 0, 4, -4, 7, -7 },
    Stomach = { 0, 4, -4, 7, -7 },
    Legs = { 0, 3, -3, 6, -6 }
}

function dormant_table_contains(tbl, val)
    for i = 1, #tbl do
        if tbl[i] == val then
            return true
        end
    end
    return false
end

function dormant_capture_hitbox_anchors(idx, origin, data, is_dormant)
    if is_dormant or entity.hitbox_position == nil or origin == nil or data == nil then
        return
    end

    local now = globals.realtime()
    if data.hitbox_anchor_time ~= nil and now - data.hitbox_anchor_time < 0.12 then
        return
    end

    local anchors = {}
    for name, groups in pairs(dormant_hitbox_anchor_groups) do
        local entries = {}

        for group_index = 1, #groups do
            local ids = groups[group_index]

            for id_index = 1, #ids do
                local ok, hx, hy, hz = pcall(entity.hitbox_position, idx, ids[id_index])
                if ok and hx ~= nil and hy ~= nil and hz ~= nil then
                    local offset_x = hx - origin.x
                    local offset_y = hy - origin.y
                    local offset_z = hz - origin.z
                    local planar = math.sqrt(offset_x * offset_x + offset_y * offset_y)

                    if planar <= 48 and offset_z >= -12 and offset_z <= 96 then
                        entries[#entries + 1] = {
                            x = offset_x,
                            y = offset_y,
                            z = offset_z,
                            id = ids[id_index]
                        }
                        break
                    end
                end
            end
        end

        if #entries > 0 then
            anchors[name] = entries
        end
    end

    if next(anchors) ~= nil then
        data.hitbox_anchors = anchors
        data.hitbox_anchor_time = now
    end
end

function dormant_get_mindmg(target_health)
    local mindmg = ui.get(dormant_aimbot_mindmg)

    if mindmg == 0 then
        local override = ref.min_damage_override and ref.min_damage_override[1] and ui.get(ref.min_damage_override[1])
        if override and ref.min_damage_override[2] then
            mindmg = ui.get(ref.min_damage_override[2]) or 0
        else
            mindmg = ui.get(ref.min_damage)
        end
    end

    if mindmg > 100 then
        mindmg = target_health + mindmg - 100
    end

    return clamp(mindmg, 1, target_health + 26)
end

function dormant_get_record_age(alpha)
    local quality = clamp(dormant_alpha_255(alpha) / 255, 0, 0.8)
    return 4 - ((quality / 0.8) * 4)
end

function dormant_record_quality(cached, esp_alpha, record_age, distance, max_distance)
    local alpha_quality = clamp(dormant_alpha_255(esp_alpha or (cached and cached.alpha)) / 255, 0, 1)
    local freshness = 1 - clamp((record_age or 0) / math.max(dormant_prediction.reset_time, 0.1), 0, 1)
    local distance_quality = distance ~= nil and max_distance ~= nil and (1 - clamp(distance / math.max(max_distance, 1), 0, 1)) or 0.65
    local trace_quality = cached and clamp(cached.primary_trace_fraction or 1, 0, 1) or 1
    local uncertainty_penalty = cached ~= nil and clamp((cached.uncertainty or 0) / 100, 0, 1) * 0.22 or 0
    local dormant_penalty = cached ~= nil and clamp((cached.dormant_time or 0) / math.max(dormant_prediction.reset_time, 0.1), 0, 1) * 0.16 or 0

    local quality = alpha_quality * 0.24 + freshness * 0.32 + distance_quality * 0.12 + trace_quality * 0.2 - uncertainty_penalty - dormant_penalty
    return clamp(quality, 0, 1)
end

function dormant_get_health(idx, esp_health)
    if esp_health and esp_health > 0 then
        dormant_stats.hp_cache[idx] = esp_health
        return esp_health
    end

    local prop_health = entity.get_prop(idx, "m_iHealth")
    if prop_health and prop_health > 0 then
        dormant_stats.hp_cache[idx] = prop_health
        return prop_health
    end

    return dormant_stats.hp_cache[idx] or 100
end

function dormant_selection_score(mode, damage, health, fov, distance, hitbox, center, accuracy)
    local lethal_bonus = damage >= health and 120 or 0
    local hitbox_bonus = hitbox == "Head" and 14 or hitbox == "Chest" and 18 or hitbox == "Stomach" and 16 or 0
    local center_bonus = center and 8 or 0
    local body_bonus = dormant_prefer_body_aim and hitbox ~= "Head" and 10 or 0

    if dormant_prefer_body_aim and lethal_bonus > 0 then
        body_bonus = body_bonus + 12
    end

    if mode == "Best Damage" then
        return damage * 5 + accuracy * 0.9 + lethal_bonus + hitbox_bonus + center_bonus + body_bonus - fov * 0.45
    elseif mode == "Closest to Crosshair" then
        return -fov * 8 + accuracy * 1.3 + damage * 0.65 + lethal_bonus + center_bonus + body_bonus
    elseif mode == "Lowest Health" then
        return (140 - math.min(health, 140)) * 3 + damage * 1.4 + accuracy + lethal_bonus + body_bonus - fov * 0.5
    end

    return accuracy * 3.6 + damage * 1.4 + lethal_bonus + hitbox_bonus + center_bonus + body_bonus - fov * 0.8 - distance * 0.004
end

function dormant_refine_accuracy(lp, eye, point, min_damage, hitbox, base_accuracy, seed_limit)
    local total = seed_limit or dormant_seed_count
    local hits = 0
    local dx = point.vec.x - eye.x
    local dy = point.vec.y - eye.y
    local length = math.sqrt(dx * dx + dy * dy)
    local right_x = length > 0 and (-dy / length) or 1
    local right_y = length > 0 and (dx / length) or 0
    local hitbox_radius = hitbox == "Head" and 1.75 or hitbox == "Chest" and 2.35 or hitbox == "Stomach" and 2.15 or 2.7

    for i = 1, total do
        local seed_angle = i * 2.399963229728653
        local seed_radius = math.sqrt(i / total) * hitbox_radius
        local sample_x = point.vec.x + right_x * math.cos(seed_angle) * seed_radius
        local sample_y = point.vec.y + right_y * math.cos(seed_angle) * seed_radius
        local sample_z = point.vec.z + math.sin(seed_angle) * seed_radius
        local _, sample_damage = client.trace_bullet(lp, eye.x, eye.y, eye.z, sample_x, sample_y, sample_z, true)

        if (sample_damage or 0) >= min_damage then
            hits = hits + 1
        end
    end

    local trace_accuracy = total > 0 and (hits / total) * 100 or base_accuracy
    return clamp(math.floor((base_accuracy * 0.65) + (trace_accuracy * 0.35) + 0.5), 0, 100)
end

function dormant_get_velocity(idx, fallback_origin)
    local data = dormant_net_data[idx] or {}
    local now = globals.realtime()
    local raw_x = entity.get_prop(idx, "m_vecVelocity[0]") or 0
    local raw_y = entity.get_prop(idx, "m_vecVelocity[1]") or 0
    local raw_z = entity.get_prop(idx, "m_vecVelocity[2]") or 0
    local sample_x, sample_y, sample_z

    if fallback_origin then
        if data.sample_origin and data.sample_time then
            local move_x = fallback_origin.x - data.sample_origin.x
            local move_y = fallback_origin.y - data.sample_origin.y
            local move_z = fallback_origin.z - data.sample_origin.z
            local moved_sqr = move_x * move_x + move_y * move_y + move_z * move_z
            local dt = now - data.sample_time

            if moved_sqr > 0.0625 then
                if dt >= globals.tickinterval() * 0.5 and dt <= 0.5 then
                    sample_x, sample_y, sample_z = move_x / dt, move_y / dt, move_z / dt
                    data.last_origin_move_time = now
                end
                data.sample_origin = fallback_origin
                data.sample_time = now
            end
        else
            data.sample_origin = fallback_origin
            data.sample_time = now
        end
    end

    local vx, vy, vz = raw_x, raw_y, raw_z
    if sample_x ~= nil then
        local sample_speed = math.sqrt(sample_x * sample_x + sample_y * sample_y)
        if sample_speed <= dormant_prediction.max_speed and math.abs(sample_z) <= 700 then
            local raw_speed = math.sqrt(raw_x * raw_x + raw_y * raw_y)
            local sample_weight = raw_speed > 2 and 0.65 or 1
            vx = sample_x * sample_weight + raw_x * (1 - sample_weight)
            vy = sample_y * sample_weight + raw_y * (1 - sample_weight)
            vz = sample_z * sample_weight + raw_z * (1 - sample_weight)
        end
    end

    local previous_velocity = data.velocity
    if previous_velocity then
        local smoothing = dormant_prediction.velocity_smoothing
        vx = previous_velocity.x * smoothing + vx * (1 - smoothing)
        vy = previous_velocity.y * smoothing + vy * (1 - smoothing)
        vz = previous_velocity.z * smoothing + vz * (1 - smoothing)
    end

    local speed = math.sqrt(vx * vx + vy * vy)
    if speed > dormant_prediction.max_speed then
        local scale = dormant_prediction.max_speed / speed
        vx, vy = vx * scale, vy * scale
        speed = dormant_prediction.max_speed
    end

    if speed >= 6 then
        data.last_motion_direction = vector(vx / speed, vy / speed, 0)
        data.last_motion_direction_time = now
    end

    local previous_speed = data.last_speed
    if previous_speed ~= nil then
        local speed_delta = speed - previous_speed
        if speed_delta < -35 and speed < previous_speed * 0.78 then
            data.release_until = now + 0.28
            data.release_factor = clamp(0.35 + (speed / math.max(previous_speed, 1)) * 0.35, 0.32, 0.75)
        elseif speed_delta > 35 then
            data.press_until = now + 0.18
        end
    end

    local velocity_dt = now - (data.velocity_sample_time or now)
    if previous_velocity ~= nil and velocity_dt >= globals.tickinterval() * 0.5 then
        local raw_ax = clamp((vx - previous_velocity.x) / math.max(velocity_dt, 0.001), -1800, 1800)
        local raw_ay = clamp((vy - previous_velocity.y) / math.max(velocity_dt, 0.001), -1800, 1800)
        local raw_az = clamp((vz - previous_velocity.z) / math.max(velocity_dt, 0.001), -2200, 2200)
        local old_acceleration = data.acceleration or vector(0, 0, 0)
        data.acceleration = vector(
            old_acceleration.x * 0.68 + raw_ax * 0.32,
            old_acceleration.y * 0.68 + raw_ay * 0.32,
            old_acceleration.z * 0.68 + raw_az * 0.32
        )
        data.velocity_sample_time = now
    elseif data.velocity_sample_time == nil then
        data.velocity_sample_time = now
        data.acceleration = vector(0, 0, 0)
    end

    local flags = entity.get_prop(idx, "m_fFlags") or 0
    local on_ground = bit.band(flags, 1) == 1
    local acceleration = data.acceleration or vector(0, 0, 0)
    local directional_acceleration = speed > 1 and ((vx * acceleration.x + vy * acceleration.y) / speed) or 0
    if not on_ground then
        data.motion_state = "air"
    elseif speed < dormant_prediction.min_speed then
        data.motion_state = "stopped"
    elseif directional_acceleration < -120 then
        data.motion_state = "decelerating"
    elseif directional_acceleration > 120 then
        data.motion_state = "accelerating"
    else
        data.motion_state = "steady"
    end

    data.last_speed = speed
    data.velocity = vector(vx, vy, vz)

    dormant_net_data[idx] = data
    return vector(vx, vy, vz)
end

function dormant_trace_prediction(idx, origin, predicted, velocity)
    local dx = predicted.x - origin.x
    local dy = predicted.y - origin.y
    local length = math.sqrt(dx * dx + dy * dy)
    local right_x = length > 0 and -dy / length or 0
    local right_y = length > 0 and dx / length or 0
    local probes = {
        {0, 0, 4},
        {0, 0, 36},
        {right_x * 12, right_y * 12, 18},
        {-right_x * 12, -right_y * 12, 18}
    }
    local fraction = 1

    for i = 1, #probes do
        local probe = probes[i]
        local trace = client.trace_line(
            idx,
            origin.x + probe[1], origin.y + probe[2], origin.z + probe[3],
            predicted.x + probe[1], predicted.y + probe[2], predicted.z + probe[3]
        )
        if trace ~= nil then
            fraction = math.min(fraction, trace)
        end
    end

    if fraction < 1 then
        fraction = clamp(fraction - 0.035, 0, 1)
        return vector(
            origin.x + dx * fraction,
            origin.y + dy * fraction,
            origin.z + (predicted.z - origin.z) * fraction
        ), fraction
    end

    return predicted, fraction
end

function dormant_predict_origin(idx, origin, record_age)
    local velocity = dormant_get_velocity(idx, origin)
    local speed = math.sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
    local freshness = 1 - clamp((record_age or 0) / dormant_prediction.reset_time, 0, 1)
    local latency = client.latency() or 0
    local lagcomp_enabled = dormant_lagcomp_enabled()
    local latency_component = latency * (lagcomp_enabled and 0.28 or 1)
    local age_component = math.min(record_age or 0, lagcomp_enabled and 0.075 or 0.12)
    local predict_time = clamp(latency_component + age_component, 0, dormant_prediction.max_lead_time)
    predict_time = predict_time * (0.35 + freshness * 0.65)
    local data = dormant_net_data[idx] or {}

    if speed < dormant_prediction.min_speed then
        predict_time = 0
    elseif predict_time > 0 then
        local now = globals.realtime()
        if data.release_until ~= nil and data.release_until > now then
            predict_time = predict_time * (data.release_factor or 0.45)
        elseif data.press_until ~= nil and data.press_until > now then
            predict_time = math.min(dormant_prediction.max_lead_time, predict_time * 1.12)
        end

        if data.motion_state == "air" then
            predict_time = predict_time * 0.88
        elseif data.motion_state == "decelerating" then
            predict_time = predict_time * 0.68
        elseif data.motion_state == "accelerating" then
            predict_time = math.min(dormant_prediction.max_lead_time, predict_time * 1.08)
        end
    end

    local acceleration = data.acceleration or vector(0, 0, 0)
    local acceleration_weight = dormant_prediction.acceleration_weight or 0.5
    local acceleration_magnitude = math.sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y)
    local preferred = clamp(data.preferred_hypothesis or 2, 1, 3)
    local scales = predict_time > 0 and (dormant_prediction.hypothesis_scales or {0.72, 1.0, 1.18}) or {1}
    local hypotheses = {}

    for i = 1, #scales do
        local scale = scales[i]
        local hypothesis_index = predict_time > 0 and i or 2
        local hypothesis_time = predict_time * scale
        local accel_x = clamp(0.5 * acceleration.x * hypothesis_time * hypothesis_time * acceleration_weight, -24, 24)
        local accel_y = clamp(0.5 * acceleration.y * hypothesis_time * hypothesis_time * acceleration_weight, -24, 24)
        local accel_z = clamp(0.5 * acceleration.z * hypothesis_time * hypothesis_time * acceleration_weight, -18, 18)
        local predicted = vector(
            origin.x + velocity.x * hypothesis_time + accel_x,
            origin.y + velocity.y * hypothesis_time + accel_y,
            origin.z + velocity.z * hypothesis_time + accel_z
        )
        local traced, trace_fraction = dormant_trace_prediction(idx, origin, predicted, velocity)
        hypotheses[#hypotheses + 1] = {
            vec = traced,
            index = hypothesis_index,
            scale = scale,
            time = hypothesis_time,
            trace_fraction = trace_fraction
        }
    end

    local prediction_now = globals.realtime()
    local direction_age = data.last_motion_direction_time ~= nil and (prediction_now - data.last_motion_direction_time) or 999
    local origin_move_age = data.last_origin_move_time ~= nil and (prediction_now - data.last_origin_move_time) or 999
    if speed < dormant_prediction.min_speed
        and freshness >= 0.35
        and (record_age or 0) <= 1.35
        and data.last_motion_direction ~= nil
        and direction_age <= 0.85
        and origin_move_age <= 0.55 then
        local drift_distance = clamp(4 + freshness * 5, 4, 9)
        local drift = data.last_motion_direction
        local drift_origin = vector(
            origin.x + drift.x * drift_distance,
            origin.y + drift.y * drift_distance,
            origin.z
        )
        local traced, trace_fraction = dormant_trace_prediction(idx, origin, drift_origin, velocity)
        hypotheses[#hypotheses + 1] = {
            vec = traced,
            index = 3,
            scale = 1.08,
            time = drift_distance / math.max(dormant_prediction.min_speed, 1),
            trace_fraction = trace_fraction,
            slow_fallback = true
        }
    end

    local primary = hypotheses[1]
    local primary_score = -999
    for i = 1, #hypotheses do
        local hypothesis = hypotheses[i]
        local scale = hypothesis.scale or 1
        local hypothesis_score = 0

        hypothesis_score = hypothesis_score + ((hypothesis.index == preferred) and 6 or 0)
        hypothesis_score = hypothesis_score + ((data.hypothesis_scores and data.hypothesis_scores[hypothesis.index]) or 0) * 2.35
        hypothesis_score = hypothesis_score + (hypothesis.trace_fraction or 1) * 12
        hypothesis_score = hypothesis_score - math.abs(scale - 1) * 4.5
        hypothesis_score = hypothesis_score - (hypothesis.time or 0) * 8

        if hypothesis.slow_fallback then
            hypothesis_score = hypothesis_score - 6
        end

        if data.motion_state == "decelerating" then
            hypothesis_score = hypothesis_score + (scale < 1 and 4.5 or -3)
        elseif data.motion_state == "accelerating" then
            hypothesis_score = hypothesis_score + (scale > 1 and 3.5 or 0)
        elseif data.motion_state == "air" then
            hypothesis_score = hypothesis_score + (scale <= 1 and 2.5 or -2.5)
        elseif data.motion_state == "stopped" then
            hypothesis_score = hypothesis_score + (math.abs(scale - 1) <= 0.05 and 3 or -3)
        end

        hypothesis.score = hypothesis_score
        if hypothesis_score > primary_score then
            primary_score = hypothesis_score
            primary = hypothesis
        end
    end
    data.uncertainty = clamp((acceleration_magnitude / 1800) * 38 + (1 - freshness) * 36 + (primary and (1 - primary.trace_fraction) * 25 or 0), 0, 100)
    data.lagcomp_enabled = lagcomp_enabled
    data.predict_time = predict_time
    data.hypotheses = hypotheses
    data.primary_trace_fraction = primary and primary.trace_fraction or 1
    data.primary_hypothesis_score = primary_score
    dormant_net_data[idx] = data

    return primary and primary.vec or origin, speed, velocity, hypotheses
end

function dormant_fusion_track(data, candidate, speed)
    data.fusion_tracks = data.fusion_tracks or {}
    local key = tostring(candidate.source or "local") .. ":" .. tostring(candidate.index or 2)
    local track = data.fusion_tracks[key] or {stable = 0}
    local now = globals.realtime()
    local point = candidate.vec

    if track.vec ~= nil and point ~= nil then
        local dt = now - (track.time or now)
        if dt > 0 and dt <= 0.4 then
            local dx = point.x - track.vec.x
            local dy = point.y - track.vec.y
            local dz = point.z - track.vec.z
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            local allowed = 10 + math.max(speed or 0, 0) * dt * 1.55
            if distance <= allowed then
                track.stable = math.min((track.stable or 0) + 1, 4)
            else
                track.stable = math.max((track.stable or 0) - 2, 0)
            end
        else
            track.stable = math.max((track.stable or 0) - 1, 0)
        end
    end

    track.vec = point
    track.time = now
    data.fusion_tracks[key] = track
    candidate.stability = clamp((track.stable or 0) / 3, 0, 1)
    return candidate.stability
end

function dormant_fusion_hypotheses(idx, data, local_hypotheses, shared_packet, speed, velocity, local_record_age)
    local candidates = {}
    local local_primary

    for i = 1, #(local_hypotheses or {}) do
        local hypothesis = local_hypotheses[i]
        hypothesis.source = "local"
        hypothesis.record_age = local_record_age
        hypothesis.source_confidence = clamp(0.5 + (hypothesis.trace_fraction or 1) * 0.28, 0, 0.82)
        hypothesis.consensus = 1
        dormant_fusion_track(data, hypothesis, speed)
        candidates[#candidates + 1] = hypothesis

        if local_primary == nil or (hypothesis.score or -999) > (local_primary.score or -999) then
            local_primary = hypothesis
        end
    end

    if shared_packet == nil or local_primary == nil then
        data.shared_delta = nil
        return candidates
    end

    local shared_confidence = clamp(shared_packet.aim_confidence or shared_packet.confidence or 0, 0, 1)
    local shared_age = math.max(0, shared_packet.effective_age or 0)
    local shared_origin = vector(shared_packet.x, shared_packet.y, shared_packet.z)
    local dx = shared_origin.x - local_primary.vec.x
    local dy = shared_origin.y - local_primary.vec.y
    local dz = shared_origin.z - local_primary.vec.z
    local local_delta = math.sqrt(dx * dx + dy * dy + dz * dz)
    data.shared_delta = local_delta

    for i = 1, #candidates do
        if local_delta <= 72 then
            candidates[i].cross_confirmed = true
            candidates[i].source_confidence = clamp((candidates[i].source_confidence or 0.5) + shared_confidence * 0.1, 0, 0.9)
        end
    end

    if shared_confidence < 0.38 or local_delta > 640 then
        return candidates
    end

    local lead_time = clamp(shared_age + (client.latency() or 0) * 0.12, 0, 0.18)
    if local_delta > 160 then
        lead_time = lead_time * 0.25
    end

    local shared_predicted = vector(
        shared_origin.x + (velocity.x or 0) * lead_time,
        shared_origin.y + (velocity.y or 0) * lead_time,
        shared_origin.z + (velocity.z or 0) * lead_time
    )
    local traced, trace_fraction = dormant_trace_prediction(idx, shared_origin, shared_predicted, velocity)
    local source = "shared"
    local final_point = traced
    local agreement = clamp(1 - local_delta / 160, 0, 1)

    if local_delta <= 96 then
        local blend = clamp(0.34 + shared_confidence * 0.42, 0.42, 0.78)
        final_point = vector(
            local_primary.vec.x * (1 - blend) + traced.x * blend,
            local_primary.vec.y * (1 - blend) + traced.y * blend,
            local_primary.vec.z * (1 - blend) + traced.z * blend
        )
        source = "fusion"
        shared_confidence = clamp(shared_confidence + agreement * 0.12, 0, 0.96)
    else
        shared_confidence = shared_confidence * clamp(1 - (local_delta - 96) / 640, 0.35, 1)
    end

    local shared_hypothesis = {
        vec = final_point,
        index = 2,
        scale = 1,
        time = lead_time,
        trace_fraction = trace_fraction,
        source = source,
        source_confidence = shared_confidence,
        record_age = shared_age,
        sender = shared_packet.sender,
        consensus = shared_packet.consensus or 1,
        agreement = agreement,
        score = (trace_fraction or 1) * 12 + shared_confidence * 10 + agreement * 5
    }
    dormant_fusion_track(data, shared_hypothesis, speed)
    candidates[#candidates + 1] = shared_hypothesis
    return candidates
end

function dormant_hypothesis_quality(cached, hypothesis, base_quality)
    local source = hypothesis and hypothesis.source or "local"
    local stability = hypothesis and hypothesis.stability or 0
    local quality = base_quality or 0.5

    if source == "shared" or source == "fusion" then
        local age = hypothesis.record_age or 0
        local freshness = 1 - clamp(age / 0.65, 0, 1)
        local source_confidence = hypothesis.source_confidence or 0
        local trace_quality = hypothesis.trace_fraction or 1
        quality = source_confidence * 0.5 + freshness * 0.2 + trace_quality * 0.15 + stability * 0.15
        if source == "fusion" then
            quality = quality + 0.06
        end
        if (hypothesis.consensus or 1) >= 2 then
            quality = quality + 0.08
        end
        if cached ~= nil and (cached.shared_delta or 0) > 160 then
            quality = quality - clamp(((cached.shared_delta or 160) - 160) / 640, 0, 0.25)
        end
    else
        quality = quality + stability * 0.05 + (hypothesis and hypothesis.cross_confirmed and 0.06 or 0)
    end

    return clamp(quality, 0, 1)
end

function dormant_update_cache()
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        dormant_net_data = {}
        return
    end

    local timeout = ui.get(dormant_aimbot_timeout) * 0.1
    local now = globals.realtime()

    for i = 1, globals.maxplayers() do
        if i ~= lp and entity.is_enemy(i) and entity.is_alive(i) then
            local ox, oy, oz = entity.get_origin(i)

            if ox then
                local origin = vector(ox, oy, oz)
                local data = dormant_net_data[i] or { dormant_start = 0, dormant_time = 0 }
                local is_dormant = entity.is_dormant(i)
                local shared_packet = shared_esp_get_packet ~= nil and shared_esp_get_packet(i) or nil

                if shared_packet ~= nil then
                    data.shared_esp_until = shared_packet.aim_until or shared_packet.priority_until
                    data.shared_visual_until = shared_packet.visual_until
                    data.shared_health = shared_packet.health
                    data.shared_sender = shared_packet.sender
                    data.shared_confidence = shared_packet.aim_confidence or shared_packet.confidence
                    data.shared_consensus = shared_packet.consensus or 1
                    data.shared_origin = vector(shared_packet.x, shared_packet.y, shared_packet.z)
                    data.shared_age = shared_packet.effective_age or 0
                elseif (data.shared_esp_until or 0) <= now then
                    data.shared_esp_until = 0
                    data.shared_health = nil
                    data.shared_sender = nil
                    data.shared_confidence = nil
                    data.shared_consensus = nil
                    data.shared_origin = nil
                    data.shared_age = nil
                end

                if is_dormant then
                    if data.dormant_start == 0 then
                        data.dormant_start = now
                    end
                    data.dormant_time = now - data.dormant_start
                else
                    data.dormant_start = 0
                    data.dormant_time = 0
                end


                dormant_capture_hitbox_anchors(i, origin, data, is_dormant)

                local esp = entity.get_esp_data(i) or {}
                local alpha = dormant_alpha_255(esp.alpha)
                local alpha_age = dormant_get_record_age(alpha)
                local simtime = entity.get_prop(i, "m_flSimulationTime")
                if simtime ~= nil and simtime ~= data.last_simtime then
                    data.last_simtime = simtime
                    data.last_simtime_update = now
                end
                local simtime_age = data.last_simtime_update and (now - data.last_simtime_update) or alpha_age
                local record_age = clamp(math.max(alpha_age * 0.55, simtime_age), 0, 4)
                dormant_net_data[i] = data
                local predicted, speed, velocity, hypotheses = dormant_predict_origin(i, origin, record_age)

                if data.dormant_time > timeout or record_age > timeout then
                    predicted = origin
                    hypotheses = {
                        {vec = origin, index = 2, scale = 1, time = 0, trace_fraction = 1}
                    }
                end

                hypotheses = dormant_fusion_hypotheses(i, data, hypotheses, shared_packet, speed, velocity, record_age)

                data.origin = origin
                data.predicted_origin = predicted
                data.predicted_origins = hypotheses
                data.speed = speed
                data.velocity = velocity
                data.alpha = alpha
                data.record_age = record_age
                data.record_quality = dormant_record_quality(data, data.alpha, record_age)
                data.update_time = now
                dormant_net_data[i] = data
            end
        else
            dormant_net_data[i] = nil
        end
    end
end

function dormant_get_points(origin, duck_amount, hitboxes, cached)
    local points = {}
    local selected = #hitboxes > 0 and hitboxes or { "Head", "Chest", "Stomach", "Legs" }
    local use_multipoint = dormant_aimbot_multipoint == nil or ui.get(dormant_aimbot_multipoint)
    local eye = vector(client.eye_position())
    local dx = origin[1] - eye.x
    local dy = origin[2] - eye.y
    local length = math.sqrt(dx * dx + dy * dy)
    local forward_x = length > 0 and (dx / length) or 1
    local forward_y = length > 0 and (dy / length) or 0
    local right_x = -forward_y
    local right_y = forward_x
    local anchor_age = cached ~= nil and cached.hitbox_anchor_time ~= nil and (globals.realtime() - cached.hitbox_anchor_time) or 999
    local anchors_fresh = cached ~= nil
        and cached.hitbox_anchors ~= nil
        and anchor_age <= dormant_prediction.reset_time + 0.6

    for i = 1, #selected do
        local name = selected[i]
        local data = dormant_hitbox_offsets[name]
        local anchors = anchors_fresh and cached.hitbox_anchors[name] or nil

        if anchors ~= nil and #anchors > 0 then
            local radius = use_multipoint and (dormant_hitbox_anchor_radius[name] or 0) or 0

            for j = 1, #anchors do
                local anchor = anchors[j]
                local center = vector(origin[1] + anchor.x, origin[2] + anchor.y, origin[3] + anchor.z)
                points[#points + 1] = {
                    hitbox = name,
                    vec = center,
                    center = true,
                    anchored = true
                }

                if radius > 0 then
                    points[#points + 1] = {
                        hitbox = name,
                        vec = vector(center.x + right_x * radius, center.y + right_y * radius, center.z),
                        center = false,
                        anchored = true
                    }
                    points[#points + 1] = {
                        hitbox = name,
                        vec = vector(center.x - right_x * radius, center.y - right_y * radius, center.z),
                        center = false,
                        anchored = true
                    }
                end
            end
        elseif data then
            local limit = use_multipoint and #data or 1
            for j = 1, limit do
                local point = data[j]
                local z = point.z - (duck_amount * point.duck)
                local side_offset = point.x or 0
                local forward_offset = point.y or 0
                points[#points + 1] = {
                    hitbox = name,
                    vec = vector(
                        origin[1] + right_x * side_offset + forward_x * forward_offset,
                        origin[2] + right_y * side_offset + forward_y * forward_offset,
                        origin[3] + z
                    ),
                    center = j == 1
                }
            end
        end
    end

    return points
end

function dormant_can_fire(cmd, weapon)
    local lp = entity.get_local_player()
    if not lp or not weapon then
        return false
    end

    local next_attack = entity.get_prop(lp, "m_flNextAttack") or 0
    local next_primary = entity.get_prop(weapon, "m_flNextPrimaryAttack") or 0

    if next_attack > globals.curtime() or next_primary > globals.curtime() then
        return false
    end

    if cmd.in_reload == 1 then
        return false
    end

    if cmd.in_use == 1 then
        return false
    end

    local clip = entity.get_prop(weapon, "m_iClip1")
    if clip ~= nil and clip <= 0 then
        return false
    end

    if entity.get_prop(weapon, "m_bInReload") == 1 then
        return false
    end

    local cooldown = ui.get(dormant_aimbot_cooldown) / 1000
    if cooldown > 0 and globals.realtime() - (dormant_stats.last_shot_time or 0) < cooldown then
        return false
    end

    if dormant_stats.pending and globals.realtime() - (dormant_stats.pending_time or 0) < 0.18 then
        return false
    end

    return true
end

function dormant_score_target(damage, health, fov, distance, hitbox, center)
    local lethal_bonus = damage >= health and 65 or 0
    local hitbox_bonus = hitbox == "Head" and 16 or hitbox == "Chest" and 10 or hitbox == "Stomach" and 6 or 0
    local center_bonus = center and 4 or 0
    local damage_score = math.min(damage, health + 20) * 2.2
    local fov_penalty = fov * 1.05
    local distance_penalty = distance * 0.006

    return damage_score + lethal_bonus + hitbox_bonus + center_bonus - fov_penalty - distance_penalty
end

function dormant_estimate_accuracy(damage, health, fov, max_fov, distance, max_distance, hitbox, center, esp_alpha, record_quality)
    local fov_quality = 1 - clamp(fov / math.max(max_fov, 1), 0, 1)
    local distance_quality = 1 - clamp(distance / math.max(max_distance, 1), 0, 1)
    local damage_quality = clamp(damage / math.max(health, 1), 0, 1)
    local alpha_quality = clamp(dormant_alpha_255(esp_alpha) / 255, 0.35, 1)
    local record_quality = record_quality ~= nil and clamp(record_quality, 0, 1) or alpha_quality
    local hitbox_bonus = hitbox == "Head" and 8 or hitbox == "Chest" and 5 or hitbox == "Stomach" and 3 or 0
    local center_bonus = center and 6 or 0
    local lethal_bonus = damage >= health and 18 or 0
    local accuracy = (fov_quality * 42) + (distance_quality * 20) + (damage_quality * 18) + (alpha_quality * 7) + (record_quality * 15) + hitbox_bonus + center_bonus + lethal_bonus
    accuracy = accuracy - ((1 - record_quality) * 9)

    return clamp(math.floor(accuracy + 0.5), 0, 100)
end

function dormant_confidence_score(idx, cached, accuracy, damage, health, record_age, distance, max_distance, hitbox, center, lethal, record_quality, hypothesis)
    local confidence = accuracy * 0.58
    local freshness = 1 - clamp((record_age or 0) / math.max(dormant_prediction.reset_time, 0.1), 0, 1)
    local record_quality = record_quality ~= nil and clamp(record_quality, 0, 1) or freshness
    local source = hypothesis and hypothesis.source or "local"
    confidence = confidence + freshness * 18
    confidence = confidence + record_quality * 14 - ((1 - record_quality) * 10)

    if cached ~= nil then
        if cached.speed ~= nil and cached.speed < dormant_prediction.min_speed then
            confidence = confidence + 6
        end
        if cached.velocity ~= nil and math.abs(cached.velocity.z or 0) < 80 then
            confidence = confidence + 3
        end
        confidence = confidence - (cached.uncertainty or 0) * 0.32
        confidence = confidence + clamp((cached.primary_hypothesis_score or 0) * 0.65, -6, 8)
        if cached.motion_state == "decelerating" or cached.motion_state == "air" then
            confidence = confidence - 4
        elseif cached.motion_state == "steady" then
            confidence = confidence + 3
        end
    end

    if source == "shared" or source == "fusion" then
        local source_confidence = hypothesis.source_confidence or 0
        confidence = confidence + source_confidence * 14
        confidence = confidence + (hypothesis.stability or 0) * 7
        confidence = confidence + math.min((hypothesis.consensus or 1) - 1, 2) * 5
        if source == "fusion" then
            confidence = confidence + 5
        end
        if (hypothesis.agreement or 0) < 0.25 then
            confidence = confidence - 8
        end
    elseif hypothesis ~= nil and hypothesis.cross_confirmed then
        confidence = confidence + 5
    end

    if hypothesis ~= nil and hypothesis.slow_fallback then
        confidence = confidence - 5
    end

    confidence = confidence + (1 - clamp(distance / math.max(max_distance, 1), 0, 1)) * 8
    confidence = confidence + clamp(damage / math.max(health, 1), 0, 1.25) * 7
    confidence = confidence + (center and 4 or 0)
    confidence = confidence + (hitbox ~= "Head" and 3 or 0)
    confidence = confidence + (lethal and 10 or 0)

    if record_age ~= nil and record_age > 1.4 then
        confidence = confidence - 10
    end

    return clamp(math.floor(confidence + 0.5), 0, 100)
end

function dormant_find_target(cmd)
    if not ui.get(dormant_aimbot) or not dormant_hotkey_active() then
        dormant_stats.last_block = "key"
        return nil
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return nil
    end

    local weapon = entity.get_player_weapon(lp)
    if not weapon then
        return nil
    end

    local weapon_data = weapons(weapon)
    if not weapon_data or weapon_data.type == "knife" or weapon_data.type == "grenade" then
        return nil
    end

    local eye = vector(client.eye_position())
    local cam_pitch, cam_yaw = client.camera_angles()
    local selection_mode = ui.get(dormant_aimbot_selection)
    local selected_hitboxes = ui.get(dormant_aimbot_hitboxes)
    local accuracy_req = ui.get(dormant_aimbot_accuracy)
    local max_fov = ui.get(dormant_aimbot_max_fov)
    local max_distance = ui.get(dormant_aimbot_max_distance)
    local timeout = ui.get(dormant_aimbot_timeout) * 0.1
    local weapon_accuracy_bias = weapon_data.type == "sniperrifle" and 2 or weapon_data.type == "pistol" and 4 or weapon_data.type == "rifle" and 1 or 2
    local weapon_confidence_bias = weapon_data.type == "sniperrifle" and 3 or weapon_data.type == "pistol" and 4 or 2
    local best_target
    local best_score = -999999

    dormant_update_cache()

    for i = 1, globals.maxplayers() do
        if i ~= lp and entity.is_enemy(i) and entity.is_dormant(i) and entity.is_alive(i) then
            local ox, oy, oz = entity.get_origin(i)
            if ox then
                local cached = dormant_net_data[i]
                local fallback_origin = vector(ox, oy, oz)
                local origin_candidates = cached and cached.predicted_origins or {
                    {vec = fallback_origin, index = 2, scale = 1, time = 0, trace_fraction = 1}
                }

                for hypothesis_number = 1, #origin_candidates do
                local hypothesis = origin_candidates[hypothesis_number]
                local origin_vec = hypothesis.vec or fallback_origin
                local origin = { origin_vec.x, origin_vec.y, origin_vec.z }
                local distance = eye:dist(origin_vec)
                local source = hypothesis.source or "local"
                local shared_source = source == "shared" or source == "fusion"

                if distance <= max_distance and (not cached or (cached.dormant_time or 0) <= timeout) then
                    local esp = entity.get_esp_data(i) or {}
                    local esp_alpha = dormant_alpha_255(esp.alpha)
                    local base_record_age = cached and cached.record_age or dormant_get_record_age(esp.alpha)
                    local record_age = hypothesis.record_age ~= nil and hypothesis.record_age or base_record_age
                    if (shared_source or esp.alpha == nil or esp_alpha >= 8) and record_age <= timeout then
                        local base_quality = dormant_record_quality(cached, esp_alpha, base_record_age, distance, max_distance)
                        local record_quality = dormant_hypothesis_quality(cached, hypothesis, base_quality)
                        local health = dormant_get_health(i, (cached and cached.shared_health) or esp.health)
                        local min_damage = dormant_get_mindmg(health)
                        local duck = entity.get_prop(i, "m_flDuckAmount") or 0
                        local points = dormant_get_points(origin, duck, selected_hitboxes, cached)

                        for j = 1, #points do
                            local point = points[j]
                            local pitch, yaw = eye:to(point.vec):angles()
                            local yaw_delta = math.abs(normalize_yaw(yaw - cam_yaw))
                            local pitch_delta = math.abs(pitch - cam_pitch)
                            local fov = math.sqrt((yaw_delta * yaw_delta) + (pitch_delta * pitch_delta))

                            if fov <= max_fov then
                                local _, damage = client.trace_bullet(lp, eye.x, eye.y, eye.z, point.vec.x, point.vec.y, point.vec.z, true)
                                damage = damage or 0

                                if damage >= min_damage then
                                    local lethal = damage >= health
                                    local accuracy = dormant_estimate_accuracy(damage, health, fov, max_fov, distance, max_distance, point.hitbox, point.center, esp_alpha, record_quality)
                                    local preferred_hypothesis = cached and (cached.preferred_hypothesis or 2) or 2
                                    local seed_limit = #origin_candidates > 1 and (hypothesis.index == preferred_hypothesis and 14 or 8) or dormant_seed_count
                                    if shared_source then
                                        seed_limit = (hypothesis.consensus or 1) >= 2 and 14 or 10
                                    elseif hypothesis.cross_confirmed then
                                        seed_limit = math.max(seed_limit, 12)
                                    end
                                    accuracy = dormant_refine_accuracy(lp, eye, point, min_damage, point.hitbox, accuracy, seed_limit)
                                    local confidence = dormant_confidence_score(i, cached, accuracy, damage, health, record_age, distance, max_distance, point.hitbox, point.center, lethal, record_quality, hypothesis)
                                    local accuracy_gate = accuracy_req + weapon_accuracy_bias
                                    local confidence_gate = (lethal and 58 or 70) + weapon_confidence_bias

                                    if lethal then
                                        accuracy_gate = accuracy_gate - 22
                                    end

                                    if shared_source then
                                        local source_confidence = hypothesis.source_confidence or 0
                                        if source_confidence >= 0.75 then
                                            accuracy_gate = accuracy_gate - 6
                                            confidence_gate = confidence_gate - 7
                                        elseif source_confidence < 0.52 then
                                            accuracy_gate = accuracy_gate + 7
                                            confidence_gate = confidence_gate + 8
                                        end
                                        if (hypothesis.consensus or 1) >= 2 then
                                            accuracy_gate = accuracy_gate - 3
                                            confidence_gate = confidence_gate - 4
                                        end
                                        if (hypothesis.stability or 0) < 0.34 then
                                            accuracy_gate = accuracy_gate + 5
                                            confidence_gate = confidence_gate + 6
                                        end
                                    elseif hypothesis.cross_confirmed then
                                        accuracy_gate = accuracy_gate - 2
                                        confidence_gate = confidence_gate - 3
                                    end

                                    if esp.alpha ~= nil and esp_alpha >= 140 then
                                        accuracy_gate = accuracy_gate - 6
                                    end

                                    if cached and cached.speed and cached.speed < dormant_prediction.min_speed then
                                        accuracy_gate = accuracy_gate - 4
                                    end

                                    if record_age < 0.8 then
                                        accuracy_gate = accuracy_gate - 4
                                    end
                                    if record_quality >= 0.78 then
                                        accuracy_gate = accuracy_gate - 5
                                        confidence_gate = confidence_gate - 6
                                    elseif record_quality < 0.45 then
                                        accuracy_gate = accuracy_gate + 8
                                        confidence_gate = confidence_gate + 9
                                    end

                                    accuracy_gate = clamp(accuracy_gate, 48, 96)
                                    confidence_gate = clamp(confidence_gate, 42, 82)
                                    local source_ready = true

                                    if shared_source then
                                        local source_confidence = hypothesis.source_confidence or 0
                                        source_ready = source_confidence >= 0.38
                                            and ((hypothesis.consensus or 1) >= 2 or (hypothesis.stability or 0) >= 0.18 or source_confidence >= 0.68)
                                    end

                                    local standard_ready = accuracy >= accuracy_gate and confidence >= confidence_gate
                                    local local_lane = not shared_source
                                        and point.center
                                        and record_age <= math.min(timeout, 1.8)
                                        and record_quality >= 0.12
                                        and (hypothesis.trace_fraction or 1) >= 0.72
                                        and accuracy >= math.max(50, accuracy_req - 16)
                                        and confidence >= 40
                                    local shared_lane = shared_source
                                        and point.center
                                        and (hypothesis.source_confidence or 0) >= 0.48
                                        and accuracy >= math.max(50, accuracy_req - 14)
                                        and confidence >= 44
                                    local lethal_lane = lethal
                                        and accuracy >= math.max(48, accuracy_req - 22)
                                        and confidence >= 42

                                    if source_ready and (standard_ready or local_lane or shared_lane or lethal_lane) then
                                        local score = dormant_selection_score(selection_mode, damage, health, fov, distance, point.hitbox, point.center, accuracy)
                                        score = score + confidence * 1.15
                                        if cached and cached.speed and cached.speed < dormant_prediction.min_speed then
                                            score = score + 8
                                        end
                                        if shared_source then
                                            score = score + (hypothesis.source_confidence or 0) * 20
                                            score = score + math.min((hypothesis.consensus or 1) - 1, 2) * 7
                                            score = score + (hypothesis.stability or 0) * 8
                                            score = score + (source == "fusion" and 6 or 0)
                                            score = score - (1 - (hypothesis.agreement or 0)) * 8
                                        elseif hypothesis.cross_confirmed then
                                            score = score + 6
                                        end
                                        if cached and source == "local" and hypothesis.index == (cached.preferred_hypothesis or 2) then
                                            score = score + 9
                                        end
                                        score = score + record_quality * 26 - ((1 - record_quality) * 18)
                                        score = score - ((cached and cached.uncertainty or 0) * 0.24)
                                        score = score - math.abs((hypothesis.scale or 1) - 1) * 5
                                        score = score - (1 - (hypothesis.trace_fraction or 1)) * 12
                                        score = score - (record_age * 18)
                                        score = score + (point.center and 4 or 0)

                                        if point.hitbox ~= "Head" then
                                            score = score + 6
                                        end

                                        if dormant_stats.lock_target == i and (dormant_stats.lock_until or 0) > globals.realtime() then
                                            score = score + 14
                                        end

                                        if score > best_score then
                                            best_score = score
                                            best_target = {
                                                idx = i,
                                                hitbox = point.hitbox,
                                                vec = point.vec,
                                                damage = damage,
                                                health = health,
                                                pitch = pitch,
                                                yaw = yaw,
                                                fov = fov,
                                                distance = distance,
                                                accuracy = accuracy,
                                                confidence = confidence,
                                                lethal = lethal,
                                                prediction_hypothesis = hypothesis.index or 2,
                                                prediction_scale = hypothesis.scale or 1,
                                                prediction_time = hypothesis.time or 0,
                                                prediction_source = source,
                                                shared_sender = hypothesis.sender,
                                                source_confidence = hypothesis.source_confidence or 0,
                                                source_consensus = hypothesis.consensus or 1,
                                                source_stability = hypothesis.stability or 0,
                                                record_age = record_age,
                                                record_quality = record_quality,
                                                needs_stop = shared_source or (point.hitbox ~= "Head") or accuracy < 92 or confidence < 86 or distance > 900 or record_quality < 0.68
                                            }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                end
            end
        end
    end

    if best_target then
        dormant_stats.lock_target = best_target.idx
        dormant_stats.lock_until = globals.realtime() + 0.25
        dormant_stats.last_block = "ready"
    elseif (dormant_stats.lock_until or 0) <= globals.realtime() then
        dormant_stats.lock_target = nil
        dormant_stats.last_block = "scan"
    end

    return best_target
end

function dormant_auto_stop(cmd)
    if dormant_aimbot_autostop ~= nil and not ui.get(dormant_aimbot_autostop) then
        return true
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        return false
    end

    local flags = entity.get_prop(lp, "m_fFlags") or 0
    if flags % 2 == 0 then
        return false
    end

    local vx = entity.get_prop(lp, "m_vecVelocity[0]") or 0
    local vy = entity.get_prop(lp, "m_vecVelocity[1]") or 0
    local speed = math.sqrt(vx * vx + vy * vy)

    if speed > 18 then
        local _, view_yaw = client.camera_angles()
        local velocity_yaw = math.atan2 and math.deg(math.atan2(vy, vx)) or math.deg(math.atan(vy / (vx == 0 and 0.0001 or vx)))
        local relative = math.rad(normalize_yaw(velocity_yaw - view_yaw))
        cmd.forwardmove = -math.cos(relative) * 450
        cmd.sidemove = -math.sin(relative) * 450
        cmd.in_speed = 1
        return false
    end


    return true
end

function dormant_shot_ledger_sync()
    local ledger = dormant_stats.shot_ledger or {}
    local pending
    for i = #ledger, 1, -1 do
        if not ledger[i].resolved then
            pending = ledger[i]
            break
        end
    end

    dormant_stats.pending = pending ~= nil
    dormant_stats.pending_target = pending and pending.target or nil
    dormant_stats.pending_time = pending and pending.created_at or nil
    dormant_stats.pending_prediction_hypothesis = pending and pending.hypothesis or nil
    dormant_stats.pending_prediction_scale = pending and pending.scale or nil
end

function dormant_shot_ledger_prune()
    local ledger = dormant_stats.shot_ledger or {}
    local now = globals.realtime()
    local write = 1

    for read = 1, #ledger do
        local shot = ledger[read]
        if not shot.resolved and now - (shot.created_at or now) <= 1.25 then
            ledger[write] = shot
            write = write + 1
        end
    end
    for i = #ledger, write, -1 do
        ledger[i] = nil
    end

    dormant_stats.shot_ledger = ledger
    dormant_shot_ledger_sync()
end

function dormant_shot_ledger_drop_target(idx)
    local ledger = dormant_stats.shot_ledger or {}
    for i = #ledger, 1, -1 do
        if ledger[i].target == idx then
            table.remove(ledger, i)
        end
    end
    dormant_shot_ledger_sync()
end

function dormant_shot_ledger_add(target)
    dormant_shot_ledger_prune()
    dormant_stats.next_shot_id = (dormant_stats.next_shot_id or 0) + 1

    local shot = {
        id = dormant_stats.next_shot_id,
        target = target.idx,
        created_at = globals.realtime(),
        hypothesis = target.prediction_hypothesis or 2,
        scale = target.prediction_scale or 1,
        source = target.prediction_source or "local",
        sender = target.shared_sender,
        hitbox = target.hitbox,
        record_age = target.record_age,
        record_quality = target.record_quality,
        source_confidence = target.source_confidence,
        source_consensus = target.source_consensus,
        source_stability = target.source_stability,
        x = target.vec and target.vec.x or nil,
        y = target.vec and target.vec.y or nil,
        z = target.vec and target.vec.z or nil
    }

    local ledger = dormant_stats.shot_ledger
    ledger[#ledger + 1] = shot
    while #ledger > 8 do
        table.remove(ledger, 1)
    end
    dormant_shot_ledger_sync()
    return shot
end

function dormant_shot_ledger_attach_event(e)
    if e == nil or e.target == nil then
        return
    end

    local ledger = dormant_stats.shot_ledger or {}
    local now = globals.realtime()
    for i = #ledger, 1, -1 do
        local shot = ledger[i]
        if not shot.resolved and shot.target == e.target and now - (shot.created_at or now) <= 0.3 then
            shot.event_id = e.id
            shot.event_tick = e.tick
            return
        end
    end
end

function dormant_shot_ledger_resolve(idx, hit, event_id)
    dormant_shot_ledger_prune()
    local ledger = dormant_stats.shot_ledger or {}
    local shot_index

    if event_id ~= nil then
        for i = 1, #ledger do
            if not ledger[i].resolved and ledger[i].event_id == event_id and (idx == nil or ledger[i].target == idx) then
                shot_index = i
                break
            end
        end
    end

    for i = 1, #ledger do
        if shot_index == nil and not ledger[i].resolved and ledger[i].target == idx then
            shot_index = i
            break
        end
    end

    local shot
    if shot_index ~= nil then
        shot = table.remove(ledger, shot_index)
        shot.resolved = true
        shot.result = hit and "hit" or "miss"
        shot.resolved_at = globals.realtime()
    elseif dormant_stats.pending and dormant_stats.pending_target == idx then
        shot = {
            target = idx,
            hypothesis = dormant_stats.pending_prediction_hypothesis or 2,
            scale = dormant_stats.pending_prediction_scale or 1,
            source = "local",
            created_at = dormant_stats.pending_time or globals.realtime()
        }
    end

    if shot ~= nil then
        dormant_prediction_feedback(idx, hit, shot)
    end
    dormant_shot_ledger_sync()
    return shot
end

function dormant_prediction_feedback(idx, hit, shot)
    if idx == nil then
        return
    end

    local data = dormant_net_data[idx] or {}
    local now = globals.realtime()
    local source = shot and shot.source or "local"
    local sender = shot and shot.sender or nil
    local feedback_weight = source == "local" and 1 or 0.35
    local hypothesis = clamp((shot and shot.hypothesis) or dormant_stats.pending_prediction_hypothesis or data.preferred_hypothesis or 2, 1, 3)
    data.hypothesis_scores = data.hypothesis_scores or {0, 0, 0}
    data.feedback_time = now

    if hit then
        data.hypothesis_scores[hypothesis] = clamp((data.hypothesis_scores[hypothesis] or 0) + 2.75 * feedback_weight, -5, 12)
        if hypothesis > 1 then
            data.hypothesis_scores[hypothesis - 1] = clamp((data.hypothesis_scores[hypothesis - 1] or 0) + 0.35 * feedback_weight, -5, 12)
        end
        if hypothesis < 3 then
            data.hypothesis_scores[hypothesis + 1] = clamp((data.hypothesis_scores[hypothesis + 1] or 0) + 0.35 * feedback_weight, -5, 12)
        end
        if source == "local" then
            data.preferred_hypothesis = hypothesis
            data.feedback_miss_streak = 0
        else
            data.shared_feedback_hits = (data.shared_feedback_hits or 0) + 1
            data.shared_feedback_miss_streak = 0
        end
        data.feedback_hits = (data.feedback_hits or 0) + 1
        data.record_quality = clamp((data.record_quality or 0.5) + 0.12 * feedback_weight, 0, 1)
    else
        data.hypothesis_scores[hypothesis] = clamp((data.hypothesis_scores[hypothesis] or 0) - 1.75 * feedback_weight, -6, 12)
        data.feedback_misses = (data.feedback_misses or 0) + 1
        data.record_quality = clamp((data.record_quality or 0.5) - 0.1 * feedback_weight, 0, 1)

        if source == "local" then
            data.feedback_miss_streak = (data.feedback_miss_streak or 0) + 1
            local best_index, best_score = nil, -999
            for i = 1, 3 do
                local score = data.hypothesis_scores[i] or 0
                if data.feedback_miss_streak >= 2 and i == hypothesis then
                    score = score - 2
                end
                if i ~= hypothesis and score > best_score then
                    best_index, best_score = i, score
                end
            end
            data.preferred_hypothesis = best_index or (hypothesis % 3) + 1
        else
            data.shared_feedback_misses = (data.shared_feedback_misses or 0) + 1
            data.shared_feedback_miss_streak = (data.shared_feedback_miss_streak or 0) + 1
        end
    end

    if (source == "shared" or source == "fusion") and shared_esp_feedback ~= nil then
        shared_esp_feedback(idx, sender, hit)
    end

    dormant_net_data[idx] = data
end

function dormant_aimbot_setup(cmd)
    if ref.fd ~= nil and ui.get(ref.fd) then
        dormant_stats.last_block = "fake_duck"
        return false
    end

    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        dormant_stats.last_block = "exploit"
        return false
    end

    local target = dormant_find_target(cmd)
    if not target then
        return false
    end

    local lp = entity.get_local_player()
    local weapon = entity.get_player_weapon(lp)
    local weapon_data = weapon and weapons(weapon)

    if not weapon_data then
        dormant_stats.last_block = "weapon"
        return false
    end

    dormant_stats.last_name = entity.get_player_name(target.idx) or "-"
    dormant_stats.last_hitbox = target.hitbox or "-"
    dormant_stats.last_damage = target.damage or 0
    dormant_stats.last_fov = target.fov or 0
    dormant_stats.last_accuracy = target.accuracy or 0
    dormant_stats.last_confidence = target.confidence or 0
    dormant_stats.last_source = target.prediction_source or "local"
    dormant_stats.last_target_time = globals.realtime()

    if weapon_data.type == "sniperrifle" and entity.get_prop(lp, "m_bIsScoped") ~= 1 then
        cmd.in_attack2 = 1
        cmd.allow_send_packet = true
        dormant_stats.last_block = "scope"
        return true
    end

    local local_vx = entity.get_prop(lp, "m_vecVelocity[0]") or 0
    local local_vy = entity.get_prop(lp, "m_vecVelocity[1]") or 0
    local local_speed = math.sqrt(local_vx * local_vx + local_vy * local_vy)

    if (target.needs_stop or local_speed >= 5) and not dormant_auto_stop(cmd) then
        dormant_stats.last_block = "stop"
        return false
    end

    if not dormant_can_fire(cmd, weapon) then
        dormant_stats.last_block = "cooldown"
        return false
    end

    cmd.pitch = target.pitch
    cmd.yaw = target.yaw
    cmd.in_attack = 1
    cmd.allow_send_packet = true

    if panchan_fakelag_runtime ~= nil then
        panchan_fakelag_runtime.choked = 0
        panchan_fakelag_runtime.target_ticks = nil
    end

    dormant_stats.shots = (dormant_stats.shots or 0) + 1
    dormant_stats.last_shot_time = globals.realtime()
    dormant_stats.last_block = "shot"
    dormant_shot_ledger_add(target)
    return true
end

function render_dormant_indicator()
    if not ui.get(dormant_aimbot) or not dormant_hotkey_active() or not ui.get(dormant_aimbot_indicator) then
        return
    end

    local lp = entity.get_local_player()
    if lp and entity.is_alive(lp) then
        local active = globals.realtime() - (dormant_stats.last_target_time or 0) < 0.25
        if active then
            renderer.indicator(120, 255, 120, 255, "DA")
        else
            renderer.indicator(255, 255, 255, 180, "DA")
        end
    end
end

function aim_miss(e)
    jitter_on_miss(e)
    session_stats.your_misses = (session_stats.your_misses or 0) + 1
    local miss_filter = miss_filter_classify(e, e and e.target)

    if miss_filter.dormant_feedback and e ~= nil and e.target ~= nil then
        dormant_shot_ledger_resolve(e.target, false, e.id)
    end

    if not ui.get(hit_logs) then
        fireData[e.id] = nil
        return
    end
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local stored = fireData[e.id]
    local backtrack_ticks = stored and stored.backtrack_ticks or 0
    local hit_chance = tostring(stored and stored.hit_chance or "?")
    local predicted_damage = stored and stored.predicted_damage or "?"
    local flags = stored and stored.flags or "none"
    local shot_id = stored and stored.shot_id or get_shot_id(e.id)
    local reason = miss_filter_format_reason(e, miss_filter)

    local message = string.format("Missed #%02d shot at %s's %s due to %s (pred: %s dmg, hc: %s%%, bt: %dt, flags: %s)",
        shot_id,
        entity.get_player_name(e.target),
        group,
        reason,
        predicted_damage,
        hit_chance,
        backtrack_ticks,
        flags
    )

    if contains(ui.get(hit_logs_type), "Under Crosshair") then
        add_log(message, 3, ui.get(hit_logs_color))
    end

    if contains(ui.get(hit_logs_type), "Console") then
        print(message)
    end

    fireData[e.id] = nil
end

function hurt_log(e, victim)
    if not ui.get(hit_logs) then
        return
    end

    local verb = get_hurt_verb(e.weapon)
    if verb == nil then
        return
    end

    local target_name = victim and entity.get_player_name(victim) or "unknown"
    local group = hitgroup_names[(e.hitgroup or 0) + 1] or "?"
    local damage = e.dmg_health or 0
    local health = e.health or 0
    local message = string.format("%s %s for %d dmg (%d remaining, hitgroup: %s)",
        verb,
        target_name,
        damage,
        health,
        group
    )

    if contains(ui.get(hit_logs_type), "Under Crosshair") then
        add_log(message, 3, ui.get(hit_logs_color))
    end

    if contains(ui.get(hit_logs_type), "Console") then
        print(message)
    end
end
---@end

---@console filter
function console_filter_func()
    if ui.get(console_filter) then
        cvar.con_filter_enable:set_int(1)
        cvar.con_filter_text:set_string("IrWL5106TZZKNFPz4P4Gl3pSN?J370f5hi373ZjPg%VOVh6lN")
    else
        cvar.con_filter_enable:set_int(0)
        cvar.con_filter_text:set_string("")
    end
end

ui.set_callback(console_filter, console_filter_func)
console_filter_func()
---@end

---@watermark

watermark_drag = {
    active = false,
    offset_x = 0,
    offset_y = 0,
    x = nil,
    y = nil
}

function hsv_to_rgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6

    local r, g, b
    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

watermark_font_flags = {
    [1] = "",
    [2] = "-",
    [3] = "",
    [4] = "b"
}

function watermark_spaced_text(text)
    local out = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        if char ~= " " then
            out[#out + 1] = char
        end
    end
    return table.concat(out, " ")
end

function watermark_gradient_text(text, color_a, color_b)
    local pieces = {}
    local len = math.max(1, #text)

    for i = 1, len do
        local char = text:sub(i, i)
        local t = len == 1 and 0 or (i - 1) / (len - 1)
        local rr = math.floor(color_a[1] + (color_b[1] - color_a[1]) * t)
        local gg = math.floor(color_a[2] + (color_b[2] - color_a[2]) * t)
        local bb = math.floor(color_a[3] + (color_b[3] - color_a[3]) * t)
        pieces[#pieces + 1] = string.format("\a%02X%02X%02XFF%s", rr, gg, bb, char)
    end

    return table.concat(pieces)
end

watermark_lerp_color = function(color_a, color_b, t)
    t = clamp(t, 0, 1)
    return
        math.floor(color_a[1] + (color_b[1] - color_a[1]) * t + 0.5),
        math.floor(color_a[2] + (color_b[2] - color_a[2]) * t + 0.5),
        math.floor(color_a[3] + (color_b[3] - color_a[3]) * t + 0.5)
end

watermark_bright_color = function(color)
    return {
        math.floor(color[1] + (255 - color[1]) * 0.55 + 0.5),
        math.floor(color[2] + (255 - color[2]) * 0.55 + 0.5),
        math.floor(color[3] + (255 - color[3]) * 0.55 + 0.5)
    }
end

watermark_animated_text = function(text, color_a, color_b, speed, spread)
    local pieces = {}
    local len = math.max(1, #text)
    local phase = globals.realtime() * math.max(speed, 0.1)

    for i = 1, len do
        local char = text:sub(i, i)
        local wave = (math.sin(phase + (i / len) * (spread or 4.2)) + 1) * 0.5
        local rr, gg, bb = watermark_lerp_color(color_a, color_b, wave)
        pieces[#pieces + 1] = string.format("\a%02X%02X%02XFF%s", rr, gg, bb, char)
    end

    return table.concat(pieces)
end

watermark_build_colored = function(text, color_a, color_b, animated, speed)
    if animated then
        return watermark_animated_text(text, color_a, color_b, speed, 5.4)
    end

    return watermark_gradient_text(text, color_a, color_b)
end

watermark_encode_charset = "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*<>?/\\|{}[]+=-_~"

function watermark_encode_random_char(seed)
    local len = #watermark_encode_charset
    local wave = math.abs(math.sin(seed * 12.9898 + 78.233)) * 43758.5453
    local idx = math.floor(wave % len) + 1
    return watermark_encode_charset:sub(idx, idx)
end

function watermark_encode_text(text, amount, speed_amount, time)
    amount = tonumber(amount) or 0
    if amount <= 0 or text == nil or text == "" then
        return text
    end

    local len = #text
    if len <= 0 then
        return text
    end

    speed_amount = clamp(tonumber(speed_amount) or 35, 1, 100)

    local speed = 0.06 + (speed_amount / 62)
    local phase = (time * speed) % 2
    local wave = phase <= 1 and phase or (2 - phase)
    local max_span = math.max(1, math.floor(len * (amount / 100) + 0.5))
    local scramble_count = math.floor(max_span * wave + 0.5)
    local random_tick = math.floor(time * clamp(3 + speed_amount / 3.7, 3, 30))

    if scramble_count <= 0 then
        return text
    end

    local start_index = math.max(1, len - scramble_count + 1)
    local out = {}
    for i = 1, len do
        local char = text:sub(i, i)
        if i >= start_index and char ~= " " then
            out[#out + 1] = watermark_encode_random_char(random_tick + i + amount * 0.01)
        else
            out[#out + 1] = char
        end
    end

    return table.concat(out)
end

function watermark()
    if not ui.get(misc_watermark) then
        return
    end

    local pos_type = ui.get(misc_watermark_position)
    local screen_width, screen_height = client.screen_size()
    local latency = math.floor(client.latency() * 1000)
    local color = { ui.get(misc_watermark_color) }
    local r, g, b, a = unpack(color)
    local second_color = { ui.get(misc_watermark_second_color) }
    local sr, sg, sb = second_color[1], second_color[2], second_color[3]
    local beta_color = { ui.get(misc_watermark_beta_color) }
    local br, bg, bb = beta_color[1], beta_color[2], beta_color[3]
    local blink_speed = ui.get(misc_watermark_blink_speed) / 10
    local rainbow_speed = ui.get(misc_watermark_rainbow_speed) / 10
    local encode_amount = ui.get(misc_watermark_encode_amount) or 0
    local encode_speed = ui.get(misc_watermark_encode_speed) or 35
    local realtime = globals.realtime()

    if ui.get(misc_watermark_rainbow) then
        local hue = (realtime * rainbow_speed) % 1
        r, g, b = hsv_to_rgb(hue, 0.85, 1)
    end

    local watermark_name = ui.get(misc_watermark_text)
    if watermark_name == nil or watermark_name == "" then
        watermark_name = "panchan.beta"
    end

    local watermark_beta_name = ui.get(misc_watermark_beta_text)
    if watermark_beta_name == nil or watermark_beta_name == "" then
        watermark_beta_name = "BETA"
    end

    local watermark_type_value = ui.get(misc_watermark_type)
    local raw_text
    if watermark_type_value == "Custom" then
        raw_text = watermark_name
    elseif watermark_type_value == "Luasense" then
        local name_part = watermark_name:upper():gsub("[%.%s_-]*BETA$", "")
        local beta_part = watermark_beta_name:upper()

        if name_part == "" then
            name_part = "PANCHAN"
        end

        if ui.get(misc_watermark_remove_space) == "No" then
            name_part = watermark_spaced_text(name_part)
            beta_part = watermark_spaced_text(beta_part)
        end

        raw_text = name_part .. " " .. beta_part
    else
        raw_text = string.format("%s / %s / %d ms", watermark_name, username, latency)
    end

    raw_text = watermark_encode_text(raw_text, encode_amount, encode_speed, realtime)

    local text
    if ui.get(misc_watermark_rainbow) then
        local pieces = {}
        local len = math.max(1, #raw_text)
        local pulse = 0.86 + (math.sin(realtime * blink_speed) * 0.14)
        for i = 1, len do
            local char = raw_text:sub(i, i)
            local hue = (realtime * rainbow_speed + (i / len) * 0.28) % 1
            local rr, gg, bb = hsv_to_rgb(hue, 0.92, pulse)
            pieces[#pieces + 1] = string.format("\a%02X%02X%02XFF%s", rr, gg, bb, char)
        end
        text = table.concat(pieces)
    elseif watermark_type_value == "Luasense" then
        local name_part = watermark_name:upper():gsub("[%.%s_-]*BETA$", "")
        local beta_part = watermark_beta_name:upper()

        if name_part == "" then
            name_part = "PANCHAN"
        end

        if ui.get(misc_watermark_remove_space) == "No" then
            name_part = watermark_spaced_text(name_part)
            beta_part = watermark_spaced_text(beta_part)
        end

        if encode_amount > 0 then
            local combined = watermark_encode_text(name_part .. " " .. beta_part, encode_amount, encode_speed, realtime)
            name_part = combined:sub(1, #name_part)
            beta_part = combined:sub(#name_part + 2)
        end

        local name_color = { r, g, b }
        local name_second = ui.get(misc_watermark_gradient) and { sr, sg, sb } or watermark_bright_color(name_color)
        local beta_main = { br, bg, bb }
        local beta_second = watermark_bright_color(beta_main)
        local name_text = watermark_build_colored(name_part, name_color, name_second, true, blink_speed)
        local beta_text = watermark_build_colored(beta_part, beta_main, beta_second, true, blink_speed * 1.15)

        text = name_text .. " " .. beta_text
    elseif ui.get(misc_watermark_gradient) then
        text = watermark_build_colored(raw_text, { r, g, b }, { sr, sg, sb }, true, blink_speed)
    else
        text = watermark_build_colored(raw_text, { r, g, b }, watermark_bright_color({ r, g, b }), true, blink_speed)
    end

    local margin, padding = 5, 5
    local flags = watermark_font_flags[ui.get(misc_watermark_font)] or "b"
    if watermark_type_value == "Luasense" and ui.get(misc_watermark_font) == 1 then
        flags = "-"
    end
    local text_width, text_height = renderer.measure_text(flags, text)
    local box_width = text_width + 18
    local box_height = text_height + 12

    local x, y
    if pos_type == "Right" then
        x = screen_width - box_width - margin
        y = margin
    elseif pos_type == "Left" then
        x = margin
        y = margin
    elseif pos_type == "Center" then
        x = (screen_width - box_width) / 2
        y = screen_height - box_height - margin
    elseif pos_type == "Custom" then
        local saved = database.read("panchan_watermark_pos")
        if watermark_drag.x == nil then
            watermark_drag.x = saved and saved.x or (screen_width - box_width - margin)
            watermark_drag.y = saved and saved.y or margin
        end

        x = clamp(watermark_drag.x, margin, screen_width - box_width - margin)
        y = clamp(watermark_drag.y, margin, screen_height - box_height - margin)
        watermark_drag.x, watermark_drag.y = x, y

        if ui.is_menu_open() then
            local mx, my = ui.mouse_position()
            local mouse_down = client.key_state(0x01)
            local hovered = mx >= x and mx <= x + box_width and my >= y and my <= y + box_height

            if mouse_down and hovered and not watermark_drag.active then
                watermark_drag.active = true
                watermark_drag.offset_x = mx - x
                watermark_drag.offset_y = my - y
            elseif not mouse_down and watermark_drag.active then
                watermark_drag.active = false
                database.write("panchan_watermark_pos", { x = watermark_drag.x, y = watermark_drag.y })
            end

            if watermark_drag.active then
                watermark_drag.x = clamp(mx - watermark_drag.offset_x, margin, screen_width - box_width - margin)
                watermark_drag.y = clamp(my - watermark_drag.offset_y, margin, screen_height - box_height - margin)
                x, y = watermark_drag.x, watermark_drag.y
            end
        end
    else
        x = screen_width - box_width - margin
        y = margin
    end

    renderer.text(x, y, 255, 255, 255, 255, flags, 0, text)
end

---@end

---@scope overlay

function draw_gradient_line(x1, y1, x2, y2, color_start, color_end, thickness)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local step = 1  -- шаг в пикселях
    local steps = math.max(1, math.floor(length / step))

    for i = 0, steps - 1 do
        local t = i / steps
        local r = color_start[1] + (color_end[1] - color_start[1]) * t
        local g = color_start[2] + (color_end[2] - color_start[2]) * t
        local b = color_start[3] + (color_end[3] - color_start[3]) * t
        local a = color_start[4] + (color_end[4] - color_start[4]) * t

        local x = x1 + dx * t
        local y = y1 + dy * t
        local next_t = (i + 1) / steps
        local next_x = x1 + dx * next_t
        local next_y = y1 + dy * next_t

        renderer.line(math.floor(x + 0.5), math.floor(y + 0.5), math.floor(next_x + 0.5), math.floor(next_y + 0.5), r, g, b, a)
    end
end

animation = animation or 0

function custom_scope()
lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then return end
    if not ui.get(_custom_scope) then return end

    ui.set(ref.scope_overlay, false)

    local lp_ent = entity.get_local_player()
    if not lp_ent then return end

    local width, height = client.screen_size()
    local max_length = ui.get(custom_scope_size) * height / 1080
    local gap = ui.get(custom_scope_gap) * height / 1080

    local scoped = entity.get_prop(lp_ent, 'm_bIsScoped') == 1 and entity.get_prop(lp_ent, 'm_bResumeZoom') == 0
    if ui.get(custom_scope_disable_animation) then
        animation = scoped and 1 or 0
    else
        animation = lerp(animation, scoped and 1 or 0, 10 * globals.frametime())
    end
    if animation < 0.01 then return end

    local style = ui.get(custom_scope_style)
    local length = max_length * animation
    local clr = { ui.get(custom_scope_color) }
    local clr_empty = { clr[1], clr[2], clr[3], 0 }
    local clr_full = { clr[1], clr[2], clr[3], clr[4] * animation }

    if style == "Default" then

        renderer.gradient(width/2, height/2 - gap - length, 1, length,
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4],
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4], false)
        renderer.gradient(width/2, height/2 + gap, 1, length,
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4],
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4], false)
        renderer.gradient(width/2 - gap - length, height/2, length, 1,
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4],
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4], true)
        renderer.gradient(width/2 + gap, height/2, length, 1,
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4],
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4], true)
    elseif style == "Inverted" then

        renderer.gradient(width/2, height/2 - gap - length, 1, length,
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4],
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4], false)

        renderer.gradient(width/2, height/2 + gap, 1, length,
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4],
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4], false)

        renderer.gradient(width/2 - gap - length, height/2, length, 1,
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4],
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4], true)

        renderer.gradient(width/2 + gap, height/2, length, 1,
                          clr_empty[1],clr_empty[2],clr_empty[3],clr_empty[4],
                          clr_full[1],clr_full[2],clr_full[3],clr_full[4], true)
    
    elseif style == "X-Style" then
        local cx, cy = (width / 2) + 0, (height / 2)
        local offset = gap + length
    
        draw_gradient_line(cx - offset, cy - offset, cx - gap, cy - gap, clr_empty, clr_full, 1)
        draw_gradient_line(cx + offset, cy + offset, cx + gap, cy + gap, clr_empty, clr_full, 1)
        draw_gradient_line(cx + offset, cy - offset, cx + gap, cy - gap, clr_empty, clr_full, 1)
        draw_gradient_line(cx - offset, cy + offset, cx - gap, cy + gap, clr_empty, clr_full, 1)

    elseif style == "X-Style Inverted" then
        local cx, cy = (width / 2) + 0, (height / 2)
        local offset = gap + length
    
        draw_gradient_line(cx - offset, cy - offset, cx - gap, cy - gap, clr_full, clr_empty, 1)
        draw_gradient_line(cx + offset, cy + offset, cx + gap, cy + gap, clr_full, clr_empty, 1)
        draw_gradient_line(cx + offset, cy - offset, cx + gap, cy - gap, clr_full, clr_empty, 1)
        draw_gradient_line(cx - offset, cy + offset, cx - gap, cy + gap, clr_full, clr_empty, 1)

    end

    ui.set_visible(ref.scope_overlay, true)
end


---@end

---@manual ind

manual_alpha_left = 255
manual_alpha_right = 255
manual_offset = 0

function render_manual()
    if not ui.get(manual_ind) then
        manual_alpha_left = interp(manual_alpha_left, 170, 10)
        manual_alpha_right = interp(manual_alpha_right, 170, 10)
        return
    end

    local lp = sdk.get_lp()
    if not lp or not sdk.is_alive(lp) then
        manual_alpha_left = interp(manual_alpha_left, 170, 10)
        manual_alpha_right = interp(manual_alpha_right, 170, 10)
        return
    end

    local screen_x, screen_y = client.screen_size()
    local scoped = sdk.isScoped(lp)
    manual_offset = interp(manual_offset, scoped and 22 or 0, 15)

    local r, g, b = unpack({ui.get(manual_ind_color)})
    local alpha_left_target = (yaw_direction == -90) and 255 or 100
    local alpha_right_target = (yaw_direction == 90) and 255 or 100

    manual_alpha_left = interp(manual_alpha_left, alpha_left_target, 10)
    manual_alpha_right = interp(manual_alpha_right, alpha_right_target, 10)

    if manual_alpha_left > 1 then
        renderer.text((screen_x / 2) - 40, (screen_y / 2) - 2 - manual_offset, r, g, b, math.floor(manual_alpha_left), "cb+", 0, "<")
    end

    if manual_alpha_right > 1 then
        renderer.text((screen_x / 2) + 40, (screen_y / 2) - 2 - manual_offset, r, g, b, math.floor(manual_alpha_right), "cb+", 0, ">")
    end
end

---@end

---@force team aimbot

function team_aim()
    cvar.mp_teammates_are_enemies:set_int(ui.get(teammate_aimbot) and 1 or 0)
end

team_aim()

ui.set_callback(teammate_aimbot, function()
    team_aim()
end)
---@end

---@clan tag
clan_tags = {"", "p", "pa", "pan", "panc", "panch", "pancha", "panchan", "pancha", "panch", "panc", "pan", "pa", "p", ""}
last_step = last_step or -1
frame_interval = frame_interval or 25

function clantag()
    local enabled = ui.get(_clantag)
    if not enabled then
        if last_step ~= -1 then
            client.set_clan_tag("")
            last_step = -1
        end
        return
    end

    local server_tick = globals.tickcount()
    local current_step = math.floor(server_tick / frame_interval)

    if current_step == last_step then return end

    last_step = current_step
    local index = (current_step % #clan_tags) + 1
    client.set_clan_tag(clan_tags[index])
end
---@end

---@exploit fix
local original_fakelag_limit = nil

local function restore_exploit_fakelag_limit()
    if original_fakelag_limit ~= nil then
        pcall(ui.set, ref.fakelag_limit, original_fakelag_limit)
        original_fakelag_limit = nil
    end
end

function exploit_fix()
    local packet_exploit_owns_fake_lag = panchan_packet_exploit_active ~= nil
        and panchan_packet_exploit_active()
    local custom_fake_lag_owns_controls = panchan_fakelag_runtime ~= nil
        and panchan_fakelag_runtime.active

    if packet_exploit_owns_fake_lag or custom_fake_lag_owns_controls then
        restore_exploit_fakelag_limit()
        return
    end

    local fix_enabled = ui.get(fix_exploits)
    local exploit_key_active = (ui.get(ref.dt[2]) or ui.get(ref.hs[2])) and not ui.get(ref.fd)
    local can_exploit = fix_enabled and exploit_key_active and player.get_dt()

    if can_exploit and fix_enabled then
        if original_fakelag_limit == nil then
            local ok, current_limit = pcall(ui.get, ref.fakelag_limit)
            if ok then
                original_fakelag_limit = current_limit
            end
        end

        if original_fakelag_limit ~= nil then
            pcall(ui.set, ref.fakelag_limit, 1)
        end
        return
    end

    restore_exploit_fakelag_limit()
end

function bring_original_fakelag_on_unlaod()
    restore_exploit_fakelag_limit()
end
---@end

---@session time
previous_time = previous_time or client.unix_time()
session_time = session_time or 0
session_minute = session_minute or 0
local session_label_cache, enemy_misses_label_cache, your_misses_label_cache

function get_session_time()
    local current_unix_time = client.unix_time()
    local elapsed_time = current_unix_time - previous_time

    if elapsed_time > 0 then
        session_time = session_time + elapsed_time
        previous_time = current_unix_time

        while session_time >= 60 do
            session_minute = session_minute + 1
            session_time = session_time - 60
        end
    end
    local session_label = "\a" .. zalupa .. "Current Session\aC0C0C0FF - "
        .. session_minute .. " min " .. math.floor(session_time) .. " sec"
    if session_label ~= session_label_cache then
        ui.set(lua_session, session_label)
        session_label_cache = session_label
    end

    local enemy_misses_label = "\a" .. zalupa .. "Enemy Misses\aC0C0C0FF - "
        .. tostring(session_stats.enemy_misses or 0)
    if enemy_misses_label ~= enemy_misses_label_cache then
        ui.set(lua_enemy_misses, enemy_misses_label)
        enemy_misses_label_cache = enemy_misses_label
    end

    local your_misses_label = "\a" .. zalupa .. "Your Misses\aC0C0C0FF - "
        .. tostring(session_stats.your_misses or 0)
    if your_misses_label ~= your_misses_label_cache then
        ui.set(lua_your_misses, your_misses_label)
        your_misses_label_cache = your_misses_label
    end
end
---@end

---@revolver helper
function is_revolver(weapon)
	local weapon_id = entity.get_prop(weapon, "m_iItemDefinitionIndex")
	return weapon_id == 64
end

function check_revolver_distance3d(player, victim)
	if player == nil or victim == nil then return 0 end

	local weapon = entity.get_prop(player, "m_hActiveWeapon")
	if weapon == nil or not is_revolver(weapon) then return 0 end

	local player_x, player_y, player_z = entity.get_origin(player)
	local victim_x, victim_y, victim_z = entity.get_origin(victim)

	if player_x == nil or victim_x == nil then
		return 0
	end

	local units = distance3d(player_x, player_y, player_z, victim_x, victim_y, victim_z)
	local no_kevlar = entity.get_prop(victim, "m_ArmorValue") == 0
	local height_difference = player_z - victim_z

	if height_difference > 100 and units < 300 then
		return "DMG+"
	elseif units > 585 then
		return "DMG-"
	elseif units < 585 and units > 511 then
		return "DMG"
	elseif units <= 511 and no_kevlar then
		return "DMG+"
	else
		return "DMG"
	end
end

function draw_status(player, status)
	local x1, y1, x2, y2, alpha_multiplier = entity.get_bounding_box(player)

	if x1 == nil or alpha_multiplier == 0 then
		return
	end
	
	local x_center = (x1 + x2) / 2
	local y_position = y1 - 20

	local color = {255, 0, 0}
	if status == "DMG" then
		color = {255, 255, 0}
	elseif status == "DMG+" then
		color = {50, 205, 50}
	end

	renderer.text(x_center, y_position, color[1], color[2], color[3], 255, "cb", 0, status)
end

function rev_helper()
    if not ui.get(revolver_helper) then return end
   
    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then return end
   
    local weapon = entity.get_prop(lp, "m_hActiveWeapon")
    if weapon == nil or not is_revolver(weapon) then
        return
    end
    local players = entity.get_players(true)
    if #players == 0 then
        return
    end
   
    for i = 1, #players do
        local entindex = players[i]
        if entindex ~= lp then
            local status = check_revolver_distance3d(lp, entindex)
            if status ~= 0 then
                draw_status(entindex, status)
            end
        end
    end

end
---@end

---@damage indicator
displayed_min_damage = displayed_min_damage or 0
function render_damage_indicator()
    if not ui.get(damage_indicator) then
        return
    end

    local player = entity.get_local_player()
    if not player or not entity.is_alive(player) then
        return
    end

    local x = 0
    local y = 0

    local screen_x, screen_y = client.screen_size()
    if font == "Verdana" then
        x = screen_x / 2 + 5
        y = screen_y / 2 - 16
    else
        x = screen_x / 2 + 8
        y = screen_y / 2 - 16
    end

    local min_damage = ui.get(ref.min_damage)
    if ui.get(ref.min_damage_override[2]) then
        min_damage = ui.get(ref.min_damage_override[3])
    end

    displayed_min_damage = lerp(displayed_min_damage, min_damage, 0.12)

    local font = ui.get(damage_indicator_font)

    if font == "Verdana" then
        renderer.text(x, y, 255, 255, 255, 255, "l", nil, string.format("%.0f", displayed_min_damage))
    elseif font == "Pixel" then
        renderer.text(x - 5, y + 2, 255, 255, 255, 255, "l-", nil, string.format("%.0f", displayed_min_damage))
    end
end
---@end

---@legit aa
classnames = {
"CWorld",
"CCSPlayer",
"CFuncBrush"
}

function entity_has_c4(ent)
	local bomb = entity.get_all("CC4")[1]
	return bomb ~= nil and entity.get_prop(bomb, "m_hOwnerEntity") == ent
end

function aa_on_use(cmd)
    if ui.is_menu_open() then
        return
    end

	if ui.get(legit_aa) then

        if cmd.in_use == 1 then
            if ui.get(legit_aa_type) == "Opposite" then
                ui.set(ref.pitch[1], "Off")
                ui.set(ref.yaw_base, "Local view")
                ui.set(ref.yaw[1], "180")
                ui.set(ref.yaw[2], 180)
                ui.set(ref.yaw_jitter[1], "Offset")
                ui.set(ref.yaw_jitter[2], 0)
                ui.set(ref.body_yaw[1], "Opposite")
                ui.set(ref.freestanding_body_yaw, true)
            elseif ui.get(legit_aa_type) == "2-Way" then
                ui.set(ref.pitch[1], "Off")
                ui.set(ref.yaw_base, "Local view")
                ui.set(ref.yaw[1], "180")
                ui.set(ref.yaw[2], 180)
                ui.set(ref.yaw_jitter[1], "Center")
                ui.set(ref.yaw_jitter[2], 65)
                ui.set(ref.body_yaw[1], "Jitter")
                ui.set(ref.body_yaw[2], -1)
                ui.set(ref.freestanding_body_yaw, false)
            end
        end

		local plocal = entity.get_local_player()
		
		local distance = 100
		local bomb = entity.get_all("CPlantedC4")[1]
		local bomb_x, bomb_y, bomb_z = entity.get_prop(bomb, "m_vecOrigin")

		if bomb_x ~= nil then
			local player_x, player_y, player_z = entity.get_prop(plocal, "m_vecOrigin")
			distance = distance3d(bomb_x, bomb_y, bomb_z, player_x, player_y, player_z)
		end
		
		local team_num = entity.get_prop(plocal, "m_iTeamNum")
		local defusing = team_num == 3 and distance < 62

		local on_bombsite = entity.get_prop(plocal, "m_bInBombZone")

		local has_bomb = entity_has_c4(plocal)
        local cat = 3
		local trynna_plant = on_bombsite ~= 0 and team_num == 2 and has_bomb and cat ~= 3
		
		local px, py, pz = client.eye_position()
		local pitch, yaw = client.camera_angles()
	
		local sin_pitch = math.sin(math.rad(pitch))
		local cos_pitch = math.cos(math.rad(pitch))
		local sin_yaw = math.sin(math.rad(yaw))
		local cos_yaw = math.cos(math.rad(yaw))

		local dir_vec = { cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch }

		local fraction, entindex = client.trace_line(plocal, px, py, pz, px + (dir_vec[1] * 8192), py + (dir_vec[2] * 8192), pz + (dir_vec[3] * 8192))

		local using = true

        if entindex ~= nil and entindex > 0 then
            local classname = safe_get_classname(entindex)

            for i = 1, #classnames do
                if classname == classnames[i] then
                    using = false
                    break
                end
            end
        end

		if not using and not trynna_plant and not defusing then
			cmd.in_use = 0
		end
	end
end
---@end

---@warmup
warmup_aa_runtime = warmup_aa_runtime or {
    saved = nil,
    active = false,
    distortion = 0,
    side = false,
    last_command = -1
}

function warmup_aa_save()
    if warmup_aa_runtime.saved ~= nil then
        return
    end

    local saved = {}
    local function save(name, item)
        if item == nil then
            return
        end

        local ok, a, b, c = pcall(ui.get, item)
        if ok then
            saved[name] = {ref = item, values = {a, b, c}}
        end
    end

    save("enabled", ref.enabled)
    save("pitch_mode", ref.pitch and ref.pitch[1])
    save("pitch_value", ref.pitch and ref.pitch[2])
    save("yaw_base", ref.yaw_base)
    save("yaw_mode", ref.yaw and ref.yaw[1])
    save("yaw_offset", ref.yaw and ref.yaw[2])
    save("yaw_jitter_mode", ref.yaw_jitter and ref.yaw_jitter[1])
    save("yaw_jitter_value", ref.yaw_jitter and ref.yaw_jitter[2])
    save("body_yaw_mode", ref.body_yaw and ref.body_yaw[1])
    save("body_yaw_value", ref.body_yaw and ref.body_yaw[2])
    save("freestanding_body_yaw", ref.freestanding_body_yaw)
    save("freestand_enabled", ref.freestand and ref.freestand[1])
    save("edge_yaw", ref.edge_yaw)
    save("roll", ref.roll)
    warmup_aa_runtime.saved = saved
end

function warmup_aa_restore()
    if warmup_aa_runtime.saved ~= nil then
        for _, item in pairs(warmup_aa_runtime.saved) do
            if item.ref ~= nil and item.values ~= nil then
                pcall(ui.set, item.ref, unpack(item.values))
            end
        end
    end

    warmup_aa_runtime.saved = nil
    warmup_aa_runtime.active = false
    warmup_aa_runtime.distortion = 0
    warmup_aa_runtime.side = false
    warmup_aa_runtime.last_command = -1
end

function warmup_aa_is_warmup()
    local rules = entity.get_all("CCSGameRulesProxy")
    local proxy = rules and rules[1]
    return proxy ~= nil and entity.get_prop(proxy, "m_bWarmupPeriod") == 1
end

function warmup_aa_no_enemies()
    local ok, enemies = pcall(entity.get_players, true)
    if not ok or type(enemies) ~= "table" then
        return false
    end

    for i = 1, #enemies do
        if entity.is_alive(enemies[i]) then
            return false
        end
    end

    return true
end

function warmup_aa_should_run()
    if not ui.get(warmup_aa) then
        return false
    end

    local player = entity.get_local_player()
    if player == nil or not entity.is_alive(player) then
        return false
    end

    if (panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active()) or (ref.fd ~= nil and ui.get(ref.fd)) then
        return false
    end

    local activation = ui.get(warmup_aa_activation)
    local is_warmup = warmup_aa_is_warmup()
    local no_enemies = warmup_aa_no_enemies()

    if activation == "Warmup" then
        return is_warmup
    elseif activation == "No Enemies" then
        return no_enemies
    end

    return is_warmup or no_enemies
end

function warmup(cmd)
    if not warmup_aa_should_run() then
        warmup_aa_restore()
        return false
    end

    warmup_aa_save()

    local yaw_mode = ui.get(warmup_aa_yaw)
    local range = ui.get(warmup_aa_range)
    local speed = math.max(ui.get(warmup_aa_speed), 1)
    local tick = globals.tickcount()
    local yaw_offset = 0

    if yaw_mode == "Spin" then
        local frame = globals.framecount and globals.framecount() or tick
        yaw_offset = normalize_yaw((frame * (speed * 0.1)) % range)
    elseif yaw_mode == "Distortion" then
        if not warmup_aa_runtime.active or tick % speed == 0 then
            warmup_aa_runtime.distortion = random_between(-range, range)
        end
        yaw_offset = normalize_yaw(warmup_aa_runtime.distortion or 0)
    elseif yaw_mode == "L/R" then
        local command_number = cmd and cmd.command_number or tick
        local choked = cmd and (get_cmd_choke and get_cmd_choke(cmd) or (cmd.chokedcommands or 0)) or 0
        if command_number ~= warmup_aa_runtime.last_command and choked == 0 then
            warmup_aa_runtime.side = not warmup_aa_runtime.side
        end
        warmup_aa_runtime.last_command = command_number
        yaw_offset = warmup_aa_runtime.side and ui.get(warmup_aa_left) or ui.get(warmup_aa_right)
    else
        yaw_offset = normalize_yaw(-180 + tick % 9 * 40 + random_between(-30, 30))
    end

    pcall(ui.set, ref.enabled, true)
    pcall(ui.set, ref.pitch[1], ui.get(warmup_aa_pitch) == "Down" and "Down" or "Off")
    pcall(ui.set, ref.pitch[2], 0)
    pcall(ui.set, ref.yaw_base, "At Targets")
    pcall(ui.set, ref.yaw[1], "180")
    pcall(ui.set, ref.yaw[2], clamp(yaw_offset, -180, 180))
    pcall(ui.set, ref.yaw_jitter[1], "Off")
    pcall(ui.set, ref.yaw_jitter[2], 0)
    pcall(ui.set, ref.freestanding_body_yaw, false)
    pcall(ui.set, ref.freestand[1], false)
    pcall(ui.set, ref.edge_yaw, false)
    pcall(ui.set, ref.roll, 0)

    if yaw_mode == "L/R" then
        pcall(ui.set, ref.body_yaw[1], "Jitter")
        pcall(ui.set, ref.body_yaw[2], 60)
    else
        pcall(ui.set, ref.body_yaw[1], "Off")
        pcall(ui.set, ref.body_yaw[2], 0)
    end

    warmup_aa_runtime.active = true
    return true
end
---@end

---@aspect_ratio
function set_aspect_ratio(aspect_ratio_multiplier)
	local screen_width, screen_height = client.screen_size()
	local aspectratio_value = (screen_width*aspect_ratio_multiplier)/screen_height

	if aspect_ratio_multiplier == 1 then
		aspectratio_value = 0
	end
	client.set_cvar("r_aspectratio", tonumber(aspectratio_value))
end

function gcd(m, n)
	-- greatest common divisor
	while m ~= 0 do
		m, n = math.fmod(n, m), m;
	end

	return n
end

screen_width, screen_height = client.screen_size()
for i=1, 200 do
	local i2=i*0.01
	i2 = 2 - i2
	local divisor = gcd(screen_width*i2, screen_height)
	if screen_width*i2/divisor < 100 or i2 == 1 then
		aspect_ratio_table[i] = screen_width*i2/divisor .. ":" .. screen_height/divisor
	end
end

function on_aspect_ratio_changed()
	local aspect_ratio = ui.get(aspect_ratio_reference)*0.01
	aspect_ratio = 2 - aspect_ratio
	set_aspect_ratio(aspect_ratio)

    if not ui.get(enable_aspect_ratio) then
        set_aspect_ratio(0)
    end
end

ui.set_callback(enable_aspect_ratio, on_aspect_ratio_changed)
ui.set_callback(aspect_ratio_reference, on_aspect_ratio_changed)


---@end

---@fast_ladder
client.set_event_callback("setup_command", function(cmd)
    local local_player = entity.get_local_player()
    if not local_player then return end

    local pitch, yaw = client.camera_angles()
    if entity.get_prop(local_player, "m_MoveType") == 9 then
        cmd.yaw = math.floor(cmd.yaw + 0.5)
        cmd.roll = 0

        if ui.get(ladder_yaw180) then
            if cmd.forwardmove == 0 and cmd.sidemove ~= 0 then
                cmd.pitch = 89
                cmd.yaw = cmd.yaw + 180

                if cmd.sidemove < 0 then
                    cmd.in_moveleft = 0
                    cmd.in_moveright = 1
                elseif cmd.sidemove > 0 then
                    cmd.in_moveleft = 1
                    cmd.in_moveright = 0
                end
            end
        end

        local ladder_modes = ui.get(fast_ladder)

        if contains(ladder_modes, "Ascending") then
            if cmd.forwardmove > 0 then
                if pitch < 45 then
                    cmd.pitch = 89
                    cmd.in_moveright = 1
                    cmd.in_moveleft = 0
                    cmd.in_forward = 0
                    cmd.in_back = 1
                    if cmd.sidemove == 0 then
                        cmd.yaw = cmd.yaw + 90
                    elseif cmd.sidemove < 0 then
                        cmd.yaw = cmd.yaw + 150
                    else
                        cmd.yaw = cmd.yaw + 30
                    end
                end 
            end
        end

        if contains(ladder_modes, "Descending") then
            if cmd.forwardmove < 0 then
                cmd.pitch = 89
                cmd.in_moveleft = 1
                cmd.in_moveright = 0
                cmd.in_forward = 1
                cmd.in_back = 0
                if cmd.sidemove == 0 then
                    cmd.yaw = cmd.yaw + 90
                elseif cmd.sidemove > 0 then
                    cmd.yaw = cmd.yaw + 150
                else
                    cmd.yaw = cmd.yaw + 30
                end
            end
        end
    end
end)
---@end

---@extended_backtrack
function extended_backtrack_setup()
    if ref.sv_unlag == nil or ref.sv_unlag[1] == nil then
        return
    end

    local mode = ui.get(extendedbacktrack)

    if mode == "Normal" then
        ui.set(ref.sv_unlag[1], 265)
    elseif mode == "High" then
        ui.set(ref.sv_unlag[1], 375)
    else
        ui.set(ref.sv_unlag[1], 200)
    end
end

client.set_event_callback("paint", function()
    extended_backtrack_setup()
end)
---@end

---@bullet_tracer
;(function()
pcall(ffi.cdef, [[
typedef struct {
    float x;
    float y;
    float z;
} bullet_tracer_vec3_t;

typedef struct {
    int m_nType;
    void* m_pStartEnt;
    int m_nStartAttachment;
    void* m_pEndEnt;
    int m_nEndAttachment;
    bullet_tracer_vec3_t m_vecStart;
    bullet_tracer_vec3_t m_vecEnd;
    int m_nModelIndex;
    const char* m_pszModelName;
    int m_nHaloIndex;
    const char* m_pszHaloName;
    float m_flHaloScale;
    float m_flLife;
    float m_flWidth;
    float m_flEndWidth;
    float m_flFadeLength;
    float m_flAmplitude;
    float m_flBrightness;
    float m_flSpeed;
    int m_nStartFrame;
    float m_flFrameRate;
    float m_flRed;
    float m_flGreen;
    float m_flBlue;
    bool m_bRenderable;
    int m_nSegments;
    int m_nFlags;
    bullet_tracer_vec3_t m_vecCenter;
    float m_flStartRadius;
    float m_flEndRadius;
} bullet_tracer_beam_info_t;
]])

tracer_cast = ffi.cast
tracer_typeof = ffi.typeof
tracer_char_ptr = tracer_typeof("char*")
tracer_vec3_t = tracer_typeof("bullet_tracer_vec3_t")

tracer_beam_enabled = visual_tracer
tracer_beam_type = visual_tracer_type
tracer_beam_impact_mode = visual_tracer_impact_mode
tracer_beam_color = visual_tracer_color

TRACER_MODEL = "sprites/physbeam.vmt"
TRACER_LIFE = 4.0
TRACER_WIDTH = 2.0
TRACER_FLAGS = 0x100
TRACER_SHOT_TIMEOUT = 1.0
TRACER_LAST_IMPACT_DELAY = 0.03

tracer_beam_info_t = tracer_typeof("bullet_tracer_beam_info_t")
tracer_create_beam_points_t = tracer_typeof("void*(__thiscall*)(void*, $*)", tracer_beam_info_t)
tracer_add_line_overlay_alpha_t = tracer_typeof(
    "void(__thiscall*)(void*, const $&, const $&, int, int, int, int, bool, float)",
    tracer_vec3_t,
    tracer_vec3_t
)

function tracer_signature(module_name, pattern, offset)
    local address = client.find_signature(module_name, pattern)
    if address == nil then
        error(("signature not found: %s"):format(module_name), 2)
    end
    return tracer_cast("uintptr_t", address) + (offset or 0)
end

function tracer_interface(module_name, interface_name)
    local raw = client.create_interface(module_name, interface_name)
    if raw == nil then
        error(("interface not found: %s::%s"):format(module_name, interface_name), 2)
    end
    return tracer_cast("void***", raw)
end

tracer_model_info = tracer_interface("engine.dll", "VModelInfoClient004")
tracer_string_table_container = tracer_interface("engine.dll", "VEngineClientStringTable001")
tracer_debug_overlay = tracer_interface("engine.dll", "VDebugOverlay004")
tracer_view_render_beams_raw = tracer_cast(
    "void**",
    tracer_cast(tracer_char_ptr, tracer_signature("client.dll", "\xB9\xCC\xCC\xCC\xCC\xA1\xCC\xCC\xCC\xCC\xFF\x10\xA1\xCC\xCC\xCC\xCC\xB9")) + 1
)[0]

tracer_view_render_beams = tracer_cast("void***", tracer_view_render_beams_raw)
tracer_find_or_load_model = tracer_cast("void*(__thiscall*)(void*, const char*)", tracer_model_info[0][39])
tracer_get_model_index = tracer_cast("int(__thiscall*)(void*, const char*)", tracer_model_info[0][2])
tracer_find_table = tracer_cast("void*(__thiscall*)(void*, const char*)", tracer_string_table_container[0][3])
tracer_render_beam = tracer_cast("void(__thiscall*)(void*, void*)", tracer_view_render_beams[0][6])
tracer_create_beam_points = tracer_cast(tracer_create_beam_points_t, tracer_view_render_beams[0][12])
tracer_add_line_overlay_alpha = tracer_cast(tracer_add_line_overlay_alpha_t, tracer_debug_overlay[0][20])

tracer_beam_info = ffi.new("bullet_tracer_beam_info_t")
tracer_cached_models = tracer_cached_models or {}
tracer_pending_shots = tracer_pending_shots or {}
tracer_latest_shot = nil
tracer_draw_impl = nil

function tracer_update_latest_shot()
    tracer_latest_shot = tracer_pending_shots[#tracer_pending_shots]
end

function tracer_remove_first_shot()
    if tracer_pending_shots[1] == nil then
        return
    end

    table.remove(tracer_pending_shots, 1)
    tracer_update_latest_shot()
end

function tracer_prune_shots()
    local now = globals.curtime()
    while tracer_pending_shots[1] ~= nil and tracer_pending_shots[1].expires_at < now do
        tracer_remove_first_shot()
    end

    if tracer_latest_shot ~= nil and tracer_latest_shot.expires_at < now then
        tracer_latest_shot = nil
    end
end

function tracer_flush_last_impact_shots(force)
    local now = globals.curtime()

    while true do
        local shot = tracer_pending_shots[1]
        if shot == nil then
            break
        end

        if shot.last_impact_x ~= nil then
            local ready = force or shot.expires_at < now or shot.last_impact_at + TRACER_LAST_IMPACT_DELAY <= now
            if not ready then
                break
            end

            tracer_draw_impl(
                shot.x,
                shot.y,
                shot.z,
                shot.last_impact_x,
                shot.last_impact_y,
                shot.last_impact_z,
                tracer_beam_color
            )
            tracer_remove_first_shot()
        elseif shot.expires_at < now then
            tracer_remove_first_shot()
        else
            break
        end
    end
end

function tracer_clear_state()
    tracer_pending_shots = {}
    tracer_latest_shot = nil
    tracer_cached_models = {}
end

function tracer_precache_model(model_name)
    if tracer_cached_models[model_name] then
        return
    end

    local model_precache = tracer_cast("void***", tracer_find_table(tracer_string_table_container, "modelprecache"))
    if model_precache == ffi.NULL then
        return
    end

    local add_string = tracer_cast("int(__thiscall*)(void*, bool, const char*, int, const void*)", model_precache[0][8])
    tracer_find_or_load_model(tracer_model_info, model_name)
    add_string(model_precache, false, model_name, -1, ffi.NULL)
    tracer_cached_models[model_name] = true
end

function tracer_draw_beam(start_x, start_y, start_z, end_x, end_y, end_z, r, g, b, a)
    tracer_precache_model(TRACER_MODEL)

    tracer_beam_info.m_nType = 0
    tracer_beam_info.m_pStartEnt = ffi.NULL
    tracer_beam_info.m_nStartAttachment = 0
    tracer_beam_info.m_pEndEnt = ffi.NULL
    tracer_beam_info.m_nEndAttachment = 0
    tracer_beam_info.m_vecStart.x = start_x
    tracer_beam_info.m_vecStart.y = start_y
    tracer_beam_info.m_vecStart.z = start_z
    tracer_beam_info.m_vecEnd.x = end_x
    tracer_beam_info.m_vecEnd.y = end_y
    tracer_beam_info.m_vecEnd.z = end_z
    tracer_beam_info.m_nModelIndex = tracer_get_model_index(tracer_model_info, TRACER_MODEL)
    tracer_beam_info.m_pszModelName = TRACER_MODEL
    tracer_beam_info.m_nHaloIndex = -1
    tracer_beam_info.m_pszHaloName = ffi.NULL
    tracer_beam_info.m_flHaloScale = 0
    tracer_beam_info.m_flLife = TRACER_LIFE
    tracer_beam_info.m_flWidth = TRACER_WIDTH
    tracer_beam_info.m_flEndWidth = TRACER_WIDTH
    tracer_beam_info.m_flFadeLength = 0
    tracer_beam_info.m_flAmplitude = 0
    tracer_beam_info.m_flBrightness = a
    tracer_beam_info.m_flSpeed = 0
    tracer_beam_info.m_nStartFrame = 0
    tracer_beam_info.m_flFrameRate = 0
    tracer_beam_info.m_flRed = r
    tracer_beam_info.m_flGreen = g
    tracer_beam_info.m_flBlue = b
    tracer_beam_info.m_bRenderable = true
    tracer_beam_info.m_nSegments = 2
    tracer_beam_info.m_nFlags = TRACER_FLAGS
    tracer_beam_info.m_vecCenter.x = 0
    tracer_beam_info.m_vecCenter.y = 0
    tracer_beam_info.m_vecCenter.z = 0
    tracer_beam_info.m_flStartRadius = 0
    tracer_beam_info.m_flEndRadius = 0

    local beam = tracer_create_beam_points(tracer_view_render_beams, tracer_beam_info)
    if beam ~= ffi.NULL then
        tracer_render_beam(tracer_view_render_beams_raw, beam)
        return true
    end

    return false
end

function tracer_draw_line(start_x, start_y, start_z, end_x, end_y, end_z, r, g, b, a)
    local start_vec = tracer_vec3_t(start_x, start_y, start_z)
    local end_vec = tracer_vec3_t(end_x, end_y, end_z)
    tracer_add_line_overlay_alpha(tracer_debug_overlay, start_vec, end_vec, r, g, b, a, true, TRACER_LIFE)
end

tracer_draw_impl = function(start_x, start_y, start_z, end_x, end_y, end_z, color_ref)
    local r, g, b, a = ui.get(color_ref)
    if a <= 0 then
        return
    end

    if ui.get(tracer_beam_type) == "Line" then
        tracer_draw_line(start_x, start_y, start_z, end_x, end_y, end_z, r, g, b, a)
        return
    end

    local ok, rendered = pcall(tracer_draw_beam, start_x, start_y, start_z, end_x, end_y, end_z, r, g, b, a)
    if not ok or not rendered then
        tracer_draw_line(start_x, start_y, start_z, end_x, end_y, end_z, r, g, b, a)
    end
end

client.set_event_callback("weapon_fire", function(e)
    if not ui.get(tracer_beam_enabled) then
        return
    end

    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then
        return
    end

    local x, y, z = client.eye_position()
    if x == nil then
        return
    end

    if ui.get(tracer_beam_impact_mode) == "Last impact" then
        tracer_flush_last_impact_shots(false)
    else
        tracer_prune_shots()
    end

    tracer_pending_shots[#tracer_pending_shots + 1] = {
        x = x,
        y = y,
        z = z,
        expires_at = globals.curtime() + TRACER_SHOT_TIMEOUT
    }
    tracer_update_latest_shot()
end)

client.set_event_callback("bullet_impact", function(e)
    if not ui.get(tracer_beam_enabled) then
        return
    end

    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then
        return
    end

    local mode = ui.get(tracer_beam_impact_mode)
    local shot

    if mode == "First impact" then
        tracer_prune_shots()
        if tracer_pending_shots[1] == nil then
            return
        end
        shot = tracer_pending_shots[1]
        tracer_remove_first_shot()
    elseif mode == "Last impact" then
        tracer_flush_last_impact_shots(false)
        shot = tracer_pending_shots[1]
        if shot ~= nil then
            shot.last_impact_x = e.x
            shot.last_impact_y = e.y
            shot.last_impact_z = e.z
            shot.last_impact_at = globals.curtime()
            return
        end
        shot = tracer_latest_shot
    else
        shot = tracer_latest_shot
        if shot == nil then
            local x, y, z = client.eye_position()
            if x == nil then
                return
            end
            shot = { x = x, y = y, z = z }
        end
    end

    if shot ~= nil then
        tracer_draw_impl(shot.x, shot.y, shot.z, e.x, e.y, e.z, tracer_beam_color)
    end
end)

client.set_event_callback("paint", function()
    if not ui.get(tracer_beam_enabled) then
        return
    end

    if ui.get(tracer_beam_impact_mode) == "Last impact" then
        tracer_flush_last_impact_shots(false)
    else
        tracer_prune_shots()
    end
end)

ui.set_callback(tracer_beam_enabled, function()
    if not ui.get(tracer_beam_enabled) then
        tracer_clear_state()
    end
end)

ui.set_callback(tracer_beam_impact_mode, tracer_clear_state)
client.set_event_callback("round_prestart", tracer_clear_state)
client.set_event_callback("shutdown", tracer_clear_state)
end)()
---@end

---@fix delay
dt = ref.dt[2]
autostop = ref.autostop[3]

last_dt = ui.get(dt)
removed = false
saved = {}
delay_fix_restore_tick = 0
delay_fix_window_ticks = 4

function delay_fix_weapon_allowed()
    local lp = entity.get_local_player()
    local weapon = lp and entity.get_player_weapon(lp)
    local data = weapon and weapons(weapon)
    if data == nil then
        return false
    end

    local selected = ui.get(delay_fix_weapons)
    if #selected == 0 then
        return true
    end

    local name = string.lower(tostring(data.name or data.console_name or data.weapon_name or ""))
    for i = 1, #selected do
        local value = selected[i]
        if value == "SCAR" and (name:find("scar20", 1, true) or name:find("g3sg1", 1, true)) then
            return true
        elseif value == "AWP" and name:find("awp", 1, true) then
            return true
        elseif value == "Scout" and (name:find("ssg08", 1, true) or name:find("scout", 1, true)) then
            return true
        elseif value == "Deagle" and name:find("deagle", 1, true) then
            return true
        elseif value == "Pistols" and data.type == "pistol" and not name:find("deagle", 1, true) then
            return true
        end
    end

    return false
end

function delay_fix_restore()
    if removed then
        pcall(ui.set, autostop, saved)
        removed = false
        saved = {}
        delay_fix_restore_tick = 0
    end
end

function fix_delay()
    if panchan_packet_exploit_active ~= nil and panchan_packet_exploit_active() then
        delay_fix_restore()
        last_dt = false
        return
    end

    local cur_dt = ui.get(dt)
    local allowed = delay_fix_weapon_allowed()
    local tick = globals.tickcount()

    if not ui.get(delay_fix) or not allowed or cur_dt then
        delay_fix_restore()
        last_dt = cur_dt
        return
    end

    if removed and delay_fix_restore_tick > 0 and tick >= delay_fix_restore_tick then
        delay_fix_restore()
        last_dt = cur_dt
        return
    end

    local cur_autostop = ui.get(autostop)
    if type(cur_autostop) ~= "table" then
        last_dt = cur_dt
        return
    end

    local early_index
    for i, v in ipairs(cur_autostop) do
        if v == "Early" then
            early_index = i
            break
        end
    end

    if last_dt and not cur_dt and early_index then
        saved = copy(cur_autostop)
        table.remove(cur_autostop, early_index)
        ui.set(autostop, cur_autostop)
        removed = true
        delay_fix_restore_tick = tick + delay_fix_window_ticks
    elseif removed and early_index then
        table.remove(cur_autostop, early_index)
        ui.set(autostop, cur_autostop)
    end

    last_dt = cur_dt
end

---@end


---@kill say

phrases = {
        ".gg/RKdScvQcGF",
    "леее куда ты хуесос ебаный",
    "забавный факт, ты хуеглот",
    "пизда пацантеч забустил",
    "не получилось чет у тебя",
    "я твоего кота ебал",
    "бомж ебаный, куда ты?",
    ".gg/RKdScvQcGF",
    "иди ноулава посмотри, тебе полезно будет",
    "выйди с сервера, заебался тя пиздить",
    "ты носом муваешься или почему так хуёво?",
    "до связи =D",
    "спонсор твоих миссов - .gg/RKdScvQcGF",
    "у тебя флюид хитбоксы?",
    "сосал? Ток честно пж",
    "..gg/RKdScvQcGF",
    "снеговичок ам-ам-ам",
    "азази азаза",
    "чупеп ебаный",
    "спонсор твоих миссов - .gg/RKdScvQcGF",
    "fuck yall niggas",
    "восстановление в ряды мёртвых",
    "купи себе рамоны с вб и задушись шнурками",
    "пацан да твоей матери и тёлки в рот дал",
    "получи отцовских пиздюлей бешбармак ебаный",
    "я думал такие после рождения умирают нахуй",
    "спонсор твоей смерти - .gg/RKdScvQcGF",
    "за рецептом отправляйтесь в бахмут",
    "умри ради дога",
    "покааааааа",
    "верёвка стоит не так дорого..",
    "заебенил твою бошку нах",
    "спонсор моих киллов - .gg/RKdScvQcGF",
    "пацан пацан твоей телке и мамке на ротан дал",
    "пацан твоей матери защеку то дал",
    "так разбераем мануал по трештолку,чо в хуй,чо с хуя , у меня рот твой",
    "ЫЫЫЫЫЫЫЫЫЫЫЫЫЫ ИСПОЛЬЗУЯ АИРЛАГ ВС Sex1k.d0xbIn",
    "1,2,3,4,5,6,7,8",
    "ПОБЕЖАЛ НА ВЫХИН0",
    "𝘁𝘆 𝗰𝗵𝘁𝗼 𝗱𝘂𝗺𝗮𝗲𝘀𝗵 𝗰𝗵𝘁𝗼 𝗲𝘁𝗼? 𝗔𝗡𝗚𝗘𝗟𝗪𝗜𝗡𝗚𝗦 𝗡𝗢 𝗜𝗧 𝗩𝗔𝗡𝗗𝗔𝗟 𝗧𝗘𝗖𝗛",
    "𝖲𝖣𝖤𝖫𝖠𝖸 𝖴𝖹𝖧𝖤 𝖲𝖤𝖫𝖧𝖠𝖱𝖬 𝖲𝖧𝖫𝖸𝖴𝖧𝖠!!!!!!!!!!!",
    "ᚱᛋᛙᚻᚣ ᚺᛊᚱᛊ ᛜᚻᚳᛉ ᛋ :)",
    "ҽɓყ------->Եѵօყ ɓƖყąɗí",
    "𝓼𝓹𝓸𝓷𝓼𝓸𝓻 𝓾𝓻 𝓴𝓮𝔂𝓫𝓸𝓪𝓻𝓭 ------>𝓢𝓦𝓤𝓠𝔂𝔂𝓩𝓢𝓝6",
    "ᴄᴇᴧɸᴀхᴩʍ дᴧя ᴛᴇбя ϶ᴛо ʙыход",
    "ⲣⲁⳅⲟⳝⲗⲁɥⲉⲏυⲉ! ⲏⲁ ⲕⲟⲧⲁ ⲃⲁⲏⲇⲁⲗ",
    "ΤΡΑΧΗΥΥΥΥΥΥΥΥΥΥΥΤ!",
    "подобдеевкой выебал твою мать",
}

trashtalk_queue = trashtalk_queue or {}

function trashtalk_exec(text)
    client.exec('say "' .. tostring(text) .. '"')
end

function trashtalk_queue_message(text, delay)
    trashtalk_queue[#trashtalk_queue + 1] = {
        text = text,
        at = globals.realtime() + (delay or 0)
    }
end

death_phrases = {
    "СКАЧАТЬ ТРЕШТОЛК ОНЛАЙН!",
    "БЛЯТЬЬЬЬ ДА КАК ТЫ ЗАЕБАЛ КАК ТЕБЕ ВЕЗЕТ",
    "ТЫ ЖЕ НЕ КТО",
    "ДА СМЕШНО",
    "КОРЕКТИОН КОРЕКТИОН СПРИД ПРЕД ЕРОР ДА Я МАТЬ ЕБАЛ ЭТОГО СЕРВЕРА",
    "НЕНАВИЖУ ТЕБЯ",
    "МУСОР ЖДИ ПОД ХАТОЙ МУСОРОВ",
    "$WAT WAIT D0X",
    ")",
    "?",
    "))))",
    "??",
    "опять тебе повезло",
    "блядина тупорылыая как тебе везет",
    "2бомжа купите мать",
    "да ты заебал тебе просто повезло",
    "p2h",
    "pray for luck",
    "how u kill me"
}

client.set_event_callback("paint", function()
    if #trashtalk_queue == 0 then
        return
    end

    local now = globals.realtime()
    for i = 1, #trashtalk_queue do
        local item = trashtalk_queue[i]
        if item ~= nil and now >= item.at then
            trashtalk_exec(item.text)
            table.remove(trashtalk_queue, i)
            return
        end
    end
end)

function death_trashtalk(e)
    if not ui.get(trashtalk_on_death) then
        return
    end

    local victim_userid, attacker_userid = e.userid, e.attacker
    if victim_userid == nil or attacker_userid == nil then
        return
    end

    local victim_entindex = client.userid_to_entindex(victim_userid)
    local attacker_entindex = client.userid_to_entindex(attacker_userid)
    local me = entity.get_local_player()

    if victim_entindex == me and attacker_entindex ~= me and attacker_entindex ~= nil and entity.is_enemy(attacker_entindex) then
        local phrase = death_phrases[math.random(1, #death_phrases)]
        trashtalk_queue_message(phrase, 0.65)
    end
end

function trashtalk(e)
    if not ui.get(_trashtalk) then
        return
    end
    local victim_userid, attacker_userid = e.userid, e.attacker
    if victim_userid == nil or attacker_userid == nil then
        return
    end

    local victim_entindex   = client.userid_to_entindex(victim_userid)
    local attacker_entindex = client.userid_to_entindex(attacker_userid)
    if attacker_entindex == entity.get_local_player() and entity.is_enemy(victim_entindex) then
        local mode = ui.get(trashtalk_mode)
        if mode == "?" then
            trashtalk_queue_message("1", 0)
            trashtalk_queue_message("?", 0.9)
            return
        end

        local phrase = phrases[math.random(1, #phrases)]
        local say = 'say ' .. phrase
        client.exec(say)
    end
end

---@end

---@velocity

alpha = alpha or 0
last_visible = last_visible or false

function render_velocity()
    if not ui.get(velocity_modifier) then
        return
    end

    local lp = entity.get_local_player()

    if not lp or not entity.is_alive(lp) then
        alpha = 0
        last_visible = false
        return
    end

    local vel_mod = entity.get_prop(lp, "m_flVelocityModifier")
    local visible = vel_mod and vel_mod < 1

    if visible then
        alpha = math.min(alpha + globals.frametime() * 5 * 255, 255)
    else
        alpha = math.max(alpha - globals.frametime() * 5 * 255, 0)
    end

    if alpha <= 0 then
        return
    end

    local screen_x, screen_y = client.screen_size()
    local pos_x, pos_y = screen_x / 2, screen_y / 2

    local vel_mod_proc = math.floor((vel_mod or 1) * 100)

    renderer.text(pos_x, pos_y - 300, 180, 180, 180, math.floor(alpha), "c", nil, "velocity rejected: " .. vel_mod_proc .. " %")
end

---@end


---@double zoom

double_zoom_original = nil
double_zoom_active = false

function restore_double_zoom()
    if double_zoom_active then
        ui.set_enabled(ref.zoom, true)

        if double_zoom_original ~= nil then
            ui.set(ref.zoom, double_zoom_original)
        end

        double_zoom_original = nil
        double_zoom_active = false
    end
end

function double_zoom_apply()
    if ui.get(animated_zoom) then
        restore_double_zoom()
        return
    end

    if not ui.get(double_zoom) or not ui.get(double_zoom_key) then
        restore_double_zoom()
        return
    end

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then
        restore_double_zoom()
        return
    end

    local weapon = entity.get_player_weapon(lp)
    if not weapon then
        restore_double_zoom()
        return
    end

    local zoom_level = entity.get_prop(weapon, "m_zoomLevel") or 0
    if zoom_level < 2 then
        restore_double_zoom()
        return
    end

    if double_zoom_original == nil then
        double_zoom_original = ui.get(ref.zoom)
    end

    local zoom_fov = clamp(90 - ui.get(double_zoom_amount), 1, 90)

    ui.set_enabled(ref.zoom, false)
    ui.set(ref.zoom, zoom_fov)

    double_zoom_active = true
end

---@end

---@animated zoom

original_fov = nil
original_zoom = nil
animated_zoom_was_active = false

anim_state = {
    duration = 0.25,
    timer = 1.0,
    animating = false,
    start_fov = nil,
    target_fov = nil,
    last_fov = nil,
}

function animate_zoom()
    if not ui.get(animated_zoom) then
        if animated_zoom_was_active then
            ui.set_enabled(ref.fov, true)
            ui.set_enabled(ref.zoom, true)

            if original_fov ~= nil then
                ui.set(ref.fov, original_fov)
            end

            if original_zoom ~= nil then
                ui.set(ref.zoom, original_zoom)
            end

            original_fov = nil
            original_zoom = nil
            animated_zoom_was_active = false

            anim_state.animating = false
            anim_state.start_fov = nil
            anim_state.target_fov = nil
            anim_state.last_fov = nil
            anim_state.timer = 1.0
        end

        return
    end

    local lp = entity.get_local_player()
    if not lp then
        return
    end

    if not animated_zoom_was_active then
        original_fov = ui.get(ref.fov)
        original_zoom = ui.get(ref.zoom)

        anim_state.start_fov = original_fov
        anim_state.target_fov = original_fov
        anim_state.last_fov = original_fov
        anim_state.timer = 1.0
        anim_state.animating = false

        animated_zoom_was_active = true
    end

    ui.set_enabled(ref.fov, false)
    ui.set_enabled(ref.zoom, false)

    local scoped = sdk.isScoped(lp)
    local desired_target = scoped and (original_fov - ui.get(zoom_val)) or original_fov

    if desired_target ~= anim_state.target_fov then
        anim_state.start_fov = ui.get(ref.fov)
        anim_state.target_fov = desired_target
        anim_state.timer = 0
        anim_state.animating = true
    end

    ui.set(ref.zoom, 0)

    if anim_state.animating then
        anim_state.timer = math.min(
            anim_state.timer + globals.frametime(),
            anim_state.duration
        )

        local t = anim_state.timer / anim_state.duration
        local eased_t = ease_in_out_quad(t)

        local new_fov = math.floor(
            lerp(anim_state.start_fov, anim_state.target_fov, eased_t) + 0.5
        )

        if new_fov ~= anim_state.last_fov then
            ui.set(ref.fov, new_fov)
            anim_state.last_fov = new_fov
        end

        if anim_state.timer >= anim_state.duration then
            anim_state.animating = false
            ui.set(ref.fov, anim_state.target_fov)
            anim_state.last_fov = anim_state.target_fov
        end
    elseif ui.get(ref.fov) ~= anim_state.target_fov then
        ui.set(ref.fov, anim_state.target_fov)
        anim_state.last_fov = anim_state.target_fov
    end
end

---@end


---@fps optimize
groups = {
    ["3d sky"] = { cvar.r_3dsky },
    ["fog"] = { cvar.fog_enable, cvar.fog_enable_water_fog },
    ["shadows"] = {
        cvar.r_shadows, cvar.cl_csm_static_prop_shadows, cvar.cl_csm_shadows,
        cvar.cl_csm_world_shadows, cvar.cl_foot_contact_shadows,
        cvar.cl_csm_viewmodel_shadows, cvar.cl_csm_rope_shadows,
        cvar.cl_csm_sprite_shadows, cvar.cl_csm_translucent_shadows,
        cvar.cl_csm_entity_shadows, cvar.cl_csm_world_shadows_in_viewmodelcascade
    },
    ["blood"] = { cvar.violence_hblood },
    ["decals"] = { cvar.r_drawdecals, cvar.r_drawropes, cvar.r_drawsprites },
    ["bloom"] = { cvar.mat_disable_bloom },
    ["other"] = {
        cvar.r_dynamic, cvar.r_eyegloss, cvar.r_eyes,
        cvar.r_drawtracers_firstperson, cvar.r_dynamiclighting
    }
}

backup, active = {}, {}
weapon_render_backup = weapon_render_backup or {}
local fps_last_update_tick

function set(c, v)
    if c == nil then return end
    if not backup[c] then backup[c] = c:get_int() end
    c:set_int(v)
end

function update_cvar()
    local selected = {}
    for _, name in ipairs(ui.get(fps_optimize)) do selected[name] = true end

    for name, cvars in pairs(groups) do
        local enable, was_enabled = selected[name], active[name]
        if enable and not was_enabled then
            for _, c in ipairs(cvars) do set(c, 0) end
        elseif not enable and was_enabled then
            for _, c in ipairs(cvars) do if backup[c] then c:set_int(backup[c]) end end
        end
    end

    active = selected
end

function fps_option_enabled(name)
    local selected = ui.get(fps_optimize)

    for i = 1, #selected do
        if selected[i] == name then
            return true
        end
    end

    return false
end

function fps_disable_weapon_thirdperson_enabled()
    return fps_option_enabled("disable weapon rendering third person") or fps_option_enabled("disable weapon third person")
end

function fps_entity_from_handle(handle)
    if handle == nil then
        return nil
    end

    local value = tonumber(handle)
    if value == nil or value <= 0 then
        return nil
    end

    if bit ~= nil and bit.band ~= nil then
        value = bit.band(value, 0xFFF)
    end

    return value > 0 and value or nil
end

function fps_get_prop(ent, prop)
    local ok, value = pcall(entity.get_prop, ent, prop)
    return ok and value or nil
end

function fps_get_prop_index(ent, prop, index)
    local ok, value = pcall(entity.get_prop, ent, prop, index)
    return ok and value or nil
end

function fps_entity_classname(ent)
    if ent == nil or ent <= 0 then
        return nil
    end

    local ok, classname = pcall(entity.get_classname, ent)
    return ok and classname or nil
end

function fps_is_weapon_entity(ent)
    local classname = fps_entity_classname(ent)

    if classname == nil then
        return false
    end

    classname = string.lower(tostring(classname))
    return string.find(classname, "weaponworldmodel", 1, true) ~= nil or string.find(classname, "weapon_", 1, true) ~= nil
end

function fps_effects_add_nodraw(value)
    value = tonumber(value) or 0

    if bit ~= nil and bit.band ~= nil and bit.bor ~= nil then
        if bit.band(value, 32) ~= 0 then
            return value
        end

        return bit.bor(value, 32)
    end

    return value + 32
end

function fps_entity_is_valid(ent)
    return fps_entity_classname(ent) ~= nil
end

function fps_is_weapon_worldmodel(ent)
    local classname = fps_entity_classname(ent)

    if classname == nil then
        return false
    end

    classname = string.lower(tostring(classname))
    return string.find(classname, "weaponworldmodel", 1, true) ~= nil
end

function fps_get_vector_prop(ent, prop)
    local ok, x, y, z = pcall(entity.get_prop, ent, prop)

    if ok and x ~= nil and y ~= nil and z ~= nil then
        return tonumber(x), tonumber(y), tonumber(z)
    end

    return nil
end

function fps_distance_sqr(a, b)
    local ax, ay, az = fps_get_vector_prop(a, "m_vecOrigin")
    local bx, by, bz = fps_get_vector_prop(b, "m_vecOrigin")

    if ax == nil or bx == nil then
        return nil
    end

    local dx, dy, dz = ax - bx, ay - by, az - bz
    return dx * dx + dy * dy + dz * dz
end

function fps_handle_points_to(handle, target)
    local ent = fps_entity_from_handle(handle)
    return ent ~= nil and target ~= nil and ent == target
end

function fps_worldmodel_matches_local(ent, lp, weapon)
    if not fps_is_weapon_worldmodel(ent) then
        return false
    end

    local owner_props = {
        "m_hOwnerEntity",
        "m_hOwner",
        "m_hMoveParent",
        "m_hParent",
        "moveparent"
    }

    local checked_owner = false

    for i = 1, #owner_props do
        local value = fps_get_prop(ent, owner_props[i])
        local owner_ent = fps_entity_from_handle(value)

        if owner_ent ~= nil then
            checked_owner = true

            if owner_ent == lp or owner_ent == weapon then
                return true
            end
        end
    end

    local weapon_handle = fps_get_prop(ent, "m_hWeapon")
    local weapon_ent = fps_entity_from_handle(weapon_handle)

    if weapon_ent ~= nil then
        checked_owner = true

        if weapon_ent == weapon then
            return true
        end
    end

    if checked_owner then
        return false
    end

    local weapon_world_index = fps_get_prop(weapon, "m_iWorldModelIndex")
    local model_index = fps_get_prop(ent, "m_nModelIndex")

    if weapon_world_index ~= nil and model_index ~= nil and tonumber(weapon_world_index) == tonumber(model_index) then
        local distance = fps_distance_sqr(ent, lp)

        return distance ~= nil and distance < 22500
    end

    return false
end

function fps_add_worldmodels_from_class(result, out, used)
    if type(result) ~= "table" then
        return
    end

    for i = 1, #result do
        local ent = tonumber(result[i])

        if ent ~= nil and ent > 0 and not used[ent] then
            used[ent] = true
            out[#out + 1] = ent
        end
    end
end

function fps_collect_weapon_worldmodels()
    local out, used = {}, {}

    if entity.get_all == nil then
        return out
    end

    local ok_base, base = pcall(entity.get_all, "CBaseWeaponWorldModel")
    if ok_base then
        fps_add_worldmodels_from_class(base, out, used)
    end

    local ok_weapon, weapon_models = pcall(entity.get_all, "CWeaponWorldModel")
    if ok_weapon then
        fps_add_worldmodels_from_class(weapon_models, out, used)
    end

    if #out == 0 then
        local ok_all, all = pcall(entity.get_all)

        if ok_all and type(all) == "table" then
            for i = 1, #all do
                local ent = tonumber(all[i])

                if ent ~= nil and ent > 0 and not used[ent] and fps_is_weapon_worldmodel(ent) then
                    used[ent] = true
                    out[#out + 1] = ent
                end
            end
        end
    end

    return out
end

function fps_find_local_weapon_worldmodels(lp, weapon)
    local entities = fps_collect_weapon_worldmodels()
    local result = {}

    for i = 1, #entities do
        local ent = entities[i]

        if fps_worldmodel_matches_local(ent, lp, weapon) then
            result[#result + 1] = ent
        end
    end

    return result
end

function fps_backup_model_entity(ent)
    if ent == nil or ent <= 0 then
        return nil
    end

    if weapon_render_backup[ent] ~= nil then
        return weapon_render_backup[ent]
    end

    local props = {}
    local ok_render, render_r, render_g, render_b, render_a = pcall(entity.get_prop, ent, "m_clrRender")
    local ok_effects, effects = pcall(entity.get_prop, ent, "m_fEffects")

    if ok_render then
        props.render_r = render_r
        props.render_g = render_g
        props.render_b = render_b
        props.render_a = render_a
    end
    if ok_effects then props.effects = effects end

    weapon_render_backup[ent] = props
    return props
end

function fps_restore_weapon_render_entity(ent, props)
    if ent == nil or props == nil then
        return
    end

    if props.render_r ~= nil then
        pcall(entity.set_prop, ent, "m_clrRender", props.render_r or 255, props.render_g or 255, props.render_b or 255, props.render_a or 255)
    end

    if props.effects ~= nil then
        pcall(entity.set_prop, ent, "m_fEffects", props.effects)
    end
end

function fps_restore_weapon_rendering()
    for ent, props in pairs(weapon_render_backup) do
        if type(props) == "table" then
            fps_restore_weapon_render_entity(ent, props)
        end
    end

    weapon_render_backup = {}
end

function fps_weapon_rendering_update(force)
    local hide_third = fps_disable_weapon_thirdperson_enabled()
    local tick = globals.tickcount()
    if not force and tick == fps_last_update_tick then
        return
    end
    fps_last_update_tick = tick

    if not hide_third then
        if next(weapon_render_backup) ~= nil then
            fps_restore_weapon_rendering()
        end
        return
    end

    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then
        if next(weapon_render_backup) ~= nil then
            fps_restore_weapon_rendering()
        end
        return
    end

    local weapon = entity.get_player_weapon(lp)
    if weapon == nil or weapon <= 0 then
        if next(weapon_render_backup) ~= nil then
            fps_restore_weapon_rendering()
        end
        return
    end

    local worldmodels = fps_find_local_weapon_worldmodels(lp, weapon)
    local active_worldmodels = {}

    for i = 1, #worldmodels do
        local worldmodel = worldmodels[i]
        active_worldmodels[worldmodel] = true

        local props = fps_backup_model_entity(worldmodel)
        if props ~= nil then
            pcall(entity.set_prop, worldmodel, "m_clrRender", props.render_r or 255, props.render_g or 255, props.render_b or 255, 0)

            if props.effects ~= nil then
                pcall(entity.set_prop, worldmodel, "m_fEffects", fps_effects_add_nodraw(props.effects))
            end
        end
    end

    for stored_ent, props in pairs(weapon_render_backup) do
        if not active_worldmodels[stored_ent] or not fps_entity_is_valid(stored_ent) then
            if type(props) == "table" then
                fps_restore_weapon_render_entity(stored_ent, props)
            end

            weapon_render_backup[stored_ent] = nil
        end
    end
end

function reset_cvar()
    fps_restore_weapon_rendering()
    for c, v in pairs(backup) do
        if c ~= nil then
            c:set_int(v)
        end
    end
    backup, active = {}, {}
end

ui.set_callback(fps_optimize, function()
    update_cvar()
    fps_weapon_rendering_update(true)
end)

---@end

---@anim breakers

local function animfix_setup()
    local animfix_values = ui.get(animfix)
    local self = entity.get_local_player()
    if not self or not entity.is_alive(self) then
        return
    end

    local self_index = c_entity.new(self)
    local self_anim_state = self_index:get_anim_state()


    if not self_anim_state then
        return
    end

    if contains(animfix_values, "Body lean") then
        local self_anim_overlay = self_index:get_anim_overlay(12)
        if not self_anim_overlay then
            return
        end
        local x_velocity = entity.get_prop(self, "m_vecVelocity[0]")
        if math.abs(x_velocity) >= 3 then
            self_anim_overlay.weight = 1
        end
    end

    if contains(animfix_values, "Jitter legs on ground") and is_on_ground then

        ui.set(ui.reference("AA", "other", "leg movement"), command_number % 3 == 0 and "Off" or "Always slide")
        entity.set_prop(self, "m_flPoseParameter", 1, globals.tickcount() % 4 > 1 and 5 / 10 or 1)

    end

    if contains(animfix_values, "Static in Air") and not is_on_ground then

        entity.set_prop(self, "m_flPoseParameter", 1 , 6)

    end

    if contains(animfix_values, "Kangaroo") then

        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 3)
        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 7)
        entity.set_prop(self, "m_flPoseParameter", math.random(0, 10)/10, 6)

    end

    if contains(animfix_values, "0 pitch on landing") then
        if not self_anim_state.hit_in_ground_animation or not is_on_ground then
            return
        end

        entity.set_prop(self, "m_flPoseParameter", 0.5, 12)
    end
end

---@end

---@lag in air ( azazi function btw )

---local function lag_air(cmd)
---    local need_to_lag = (ui.get(force_lag) and (current_state == "Air-Duck" or current_state == "Air") and player.get_dt()
---
---    if need_to_lag then
---        потом напишу лень пиздец
---    end

---@end

---@callbacks

ui.set_enabled(ref.clantag, false)
ui.set(ref.clantag, false)

client.set_event_callback("shutdown", function()
    resolver_reset_all()
    if warmup_aa_restore ~= nil then
        warmup_aa_restore()
    end
    if fake_duck_freezetime_restore ~= nil then
        fake_duck_freezetime_restore()
    end
    if panchan_fake_lag_restore ~= nil then
        panchan_fake_lag_restore()
    end
    if airlag_panchan_restore ~= nil then
        airlag_panchan_restore()
    end
    if panchan_crimwalk_restore ~= nil then
        panchan_crimwalk_restore()
    end
    if panchan_scolious_restore ~= nil then
        panchan_scolious_restore()
    end
    if ragebot_improved_restore ~= nil then
        ragebot_improved_restore()
    end
    delay_fix_restore()
    duck_on_fd_unset()
    on_unload()
    reset_cvar()
    database.flush()
    bring_original_fakelag_on_unlaod()
    ui.set_enabled(ref.clantag, true)
   ui.set_enabled(ref.fov, true)
ui.set_enabled(ref.zoom, true)
set_aspect_ratio(0)

if animated_zoom_was_active then
    if original_zoom ~= nil then
        ui.set(ref.zoom, original_zoom)
    end

    if original_fov ~= nil then
        ui.set(ref.fov, original_fov)
    end
end

restore_double_zoom()

cvar.con_filter_enable:set_int(0)
cvar.con_filter_text:set_string("")
cvar.mp_teammates_are_enemies:set_int(0)
end)

client.set_event_callback("aim_miss", function(e) 
    aim_miss(e)
end)

client.set_event_callback("aim_hit", function(e) 
    aim_hit(e)
end)

client.set_event_callback("aim_fire", function(e)
    aim_fire(e)
end)

client.set_event_callback('player_death', function(e)
    trashtalk(e)
    death_trashtalk(e)

    local idx = client.userid_to_entindex(e.userid)
    if idx == entity.get_local_player() then
        if warmup_aa_restore ~= nil then
            warmup_aa_restore()
        end
        if fake_duck_freezetime_restore ~= nil then
            fake_duck_freezetime_restore()
        end
        if airlag_panchan_restore ~= nil then
            airlag_panchan_restore()
        end
        if panchan_crimwalk_restore ~= nil then
            panchan_crimwalk_restore()
        end
    end

    if idx ~= nil and idx > 0 then
        resolver_restore_player(idx)
        resolver_runtime.jitter[idx] = nil
        resolver_runtime.defensive[idx] = nil
        resolver_runtime.lagcomp[idx] = nil
    end
end)

client.set_event_callback('player_hurt', function(e)
    local lp = entity.get_local_player()
    if not lp then
        return
    end

    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)

    if victim ~= nil and victim > 0 and victim ~= lp and entity.is_enemy(victim) then
        if e.health ~= nil and e.health > 0 then
            dormant_stats.hp_cache[victim] = e.health
        else
            dormant_stats.hp_cache[victim] = nil
        end
    end

    if victim == lp and attacker ~= nil and attacker > 0 and attacker ~= lp and entity.is_enemy(attacker) then
        register_adaptive_threat(attacker, 95)
    end

    if attacker ~= lp then
        return
    end

    hurt_log(e, victim)

    if victim ~= nil and dormant_shot_ledger_resolve(victim, true) ~= nil then
        dormant_stats.hits = (dormant_stats.hits or 0) + 1
    end
end)

client.set_event_callback("player_spawn", function(e)
    local idx = client.userid_to_entindex(e.userid)

    if idx ~= nil and idx > 0 then
        resolver_restore_player(idx)
        resolver_runtime.jitter[idx] = nil
        resolver_runtime.defensive[idx] = nil
        resolver_runtime.lagcomp[idx] = nil
        if dormant_stats.lock_target == idx then
            dormant_stats.lock_target = nil
            dormant_stats.lock_until = 0
        end
        dormant_shot_ledger_drop_target(idx)
        dormant_stats.hp_cache[idx] = nil
        dormant_net_data[idx] = nil
    end
end)

client.set_event_callback("pre_render", function()
    on_load()
    animfix_setup()
    menu_visibility()
    aa_visibility()
    cfg_visibility()
    hide_fakelag()
    fps_weapon_rendering_update()
    get_session_time()
    set_accent()
end)

command_number = 0
client.set_event_callback("setup_command", function(cmd)
    change_state(cmd)
    ragebot_improved_setup_command(cmd)
    ---fake_lag(cmd)
    on_setup_command(cmd)
    freestnd(cmd)
    manual_yaw(cmd)
    anti_stab()
    handle_recharge()
    aa_on_use(cmd)
    quickpeek_autostop_run(cmd)
    dormant_aimbot_setup(cmd)
    warmup(cmd)
    fix_delay()
    apply_panchan_fake_lag(cmd)
    panchan_exploit_apply(cmd, current_state or get_player_state(cmd))
    airlag_panchan_apply(cmd)
    if ref.fd ~= nil and ui.get(ref.fd) then
        panchan_fake_lag_apply_fake_duck()
    end
    command_number = cmd.command_number
end)

client.set_event_callback("round_start", function()
    panchan_clear_map_ui_state()
    ragebot_improved_restore()
    ragebot_improved_reset_feedback()
    if fake_duck_freezetime_restore ~= nil then
        fake_duck_freezetime_restore()
    end
    if airlag_panchan_restore ~= nil then
        airlag_panchan_restore()
    end
    if panchan_crimwalk_restore ~= nil then
        panchan_crimwalk_restore()
    end
    fps_restore_weapon_rendering()
    resolver_reset_all()
    quickpeek_reset_runtime()
    dormant_stats.pending = false
    dormant_stats.pending_target = nil
    dormant_stats.pending_time = nil
    dormant_stats.pending_prediction_hypothesis = nil
    dormant_stats.pending_prediction_scale = nil
    dormant_stats.lock_target = nil
    dormant_stats.lock_until = 0
    dormant_stats.shot_ledger = {}
    dormant_stats.hp_cache = {}
    dormant_net_data = {}
    aa_adaptive.danger_until = 0
    aa_adaptive.level = 0
    adaptive_desync_cache.next_tick = 0
    panchan_fakelag_runtime.choked = 0
    panchan_fakelag_runtime.target_ticks = nil
    panchan_fakelag_runtime.condition = nil
    panchan_fakelag_runtime.variance = 0
    if panchan_mode_v2_reset_runtime ~= nil then
        panchan_mode_v2_reset_runtime()
    end
    anti_brute_reset(true)
end)

client.set_event_callback("paint", function()
    centered_indicators_legacy()
    centered_indicators_modern()
    watermark()
    custom_scope()
    render_manual()
    rev_helper()
    render_damage_indicator()
    render_hirate_indicator()
    render_dormant_indicator()
    render_cheat_revealer()
    render_jitter_correction_esp_flag()
    dormant_shot_ledger_prune()
    render_velocity()
    double_zoom_apply()
    animate_zoom()

    if ui.get(debug_text) then
        render_debug_text(ui.get(debug_text_position))
    end

    local lp = entity.get_local_player()
    if not entity.is_alive(lp) then
        yaw_direction = 0
        return
    end

    --- суда так как в ипаном сетапе пиздец КАПУТ нахуй
    if globals.realtime() > (anti_brute.active_until or 0) or not ui.get(anti_bruteforce) then
        anti_brute_reset(false)
    end
end)

client.set_event_callback('net_update_end', function()
    clantag()
    resolver_update_all()
    if aa_stealer_update_all ~= nil then
        aa_stealer_update_all()
    end

    local lp = sdk.get_lp()

    if not lp or not sdk.is_alive(lp) then
        player.choked = 0
    end
end)

client.set_event_callback('level_init', function()
    panchan_clear_map_ui_state()
    ragebot_improved_restore()
    ragebot_improved_reset_feedback()
    fps_restore_weapon_rendering()
    timer = globals.tickcount()
    defensive_switch_time = 0
    if panchan_mode_v2_reset_runtime ~= nil then
        panchan_mode_v2_reset_runtime()
    end
end)

pcall(client.set_event_callback, "cs_game_disconnected", function()
    panchan_clear_map_ui_state()
    ragebot_improved_restore()
    ragebot_improved_reset_feedback()
end)

pcall(client.set_event_callback, "game_newmap", function()
    panchan_clear_map_ui_state()
    ragebot_improved_restore()
    ragebot_improved_reset_feedback()
end)

client.set_event_callback("paint_ui", function()
    render_welcome_intro()
    render_logs()
    ui.set(ui.reference('VISUALS', 'Effects', 'Remove scope overlay'), true)
end)

client.set_event_callback("run_command", function(cmd)
    player.run_command(cmd)
end)

client.set_event_callback('predict_command', function(cmd)
    exploit_fix()
    update_defensive(cmd)
end)

client.set_event_callback('finish_command', function(cmd)
    on_finish_command(cmd)
end)

---@end
