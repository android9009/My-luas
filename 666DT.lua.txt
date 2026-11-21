-- decompiled by ебейший челик РОМАН МУЖИК НЕ ТРАКТОР НЕ ТОРМОЗИТ, and РОМАН БАРАН РУИНИТ ШКОЛЬНИКУ СКИНЫ В СТАНДОФФЕ, and ВАНЕК ХУЙ ЗНАЕТ КТО

local var_0_0 = require("neverlose/images")
local var_0_1 = require("neverlose/base64")
local var_0_2 = require("neverlose/csgo_weapons")

reference = {
	ragebot_menu = ui.find("Aimbot", "Ragebot", "Main"),
	double_tap_reference = {
		double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
		lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
		fakelag_limit = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Fake Lag Limit"),
		immediate_teleport = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Immediate Teleport"),
		quick_switch = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Quick-Switch")
	},
	leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"),
	fakelag_reference = {
		enabled = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
		limit = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit")
	},
	safe_points = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
	extended_backtrack = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Extended Backtrack"),
	head_scale = ui.find("Aimbot", "Ragebot", "Selection", "Multipoint", "Head Scale"),
	body_scale = ui.find("Aimbot", "Ragebot", "Selection", "Multipoint", "Body Scale"),
	delay_shot = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Min. Damage", "Delay Shot"),
	fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
	hitchance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
	onshot_aa = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots")
}
math = {
	abs = math.abs,
	ceil = math.ceil,
	cos = math.cos,
	deg = math.deg,
	floor = math.floor,
	huge = math.huge,
	max = math.max,
	min = math.min,
	pi = math.pi,
	modf = math.modf,
	rad = math.rad,
	pow = math.pow,
	random = math.random,
	sin = math.sin,
	sqrt = math.sqrt,
	acos = math.acos,
	atan = math.atan,
	atan2 = math.atan2,
	log = math.log,
	fmod = math.fmod,
	exp = math.exp,
	round = function(arg_1_0)
		return arg_1_0 >= 0 and math.floor(arg_1_0 + 0.5) or math.ceil(arg_1_0 - 0.5)
	end,
	clamp = function(arg_2_0, arg_2_1, arg_2_2)
		return arg_2_0 < arg_2_1 and arg_2_1 or arg_2_2 < arg_2_0 and arg_2_2 or arg_2_0
	end,
	lerp = function(arg_3_0, arg_3_1, arg_3_2)
		return arg_3_0 + (arg_3_1 - arg_3_0) * arg_3_2
	end,
	calculate_angles = function(arg_4_0, arg_4_1)
		local var_4_0 = arg_4_1 - arg_4_0
		local var_4_1 = -math.deg(math.atan2(var_4_0.z, math.sqrt(var_4_0.x^2 + var_4_0.y^2)))
		local var_4_2 = math.deg(math.atan2(var_4_0.y, var_4_0.x))

		return var_4_1, var_4_2
	end,
	normalize_yaw = function(arg_5_0)
		while arg_5_0 > 180 do
			arg_5_0 = arg_5_0 - 360
		end

		while arg_5_0 < -180 do
			arg_5_0 = arg_5_0 + 360
		end

		return arg_5_0
	end
}

local var_0_3 = reference.ragebot_menu:switch("DT 666👿", false)
local var_0_4 = var_0_3:create()
local var_0_5 = var_0_4:combo("Lag Options", {
	"Offensive",
	"Defensive"
})
local var_0_6 = var_0_4:combo("Defensive Options", {
	"On-Peek",
	"Force"
})
local var_0_7 = var_0_4:combo("On-Peek Mode", {
	"Default",
	"DT-666"
})
local var_0_8 = var_0_4:combo("Defensive Mode", {
	"Events",
	"Original"
})
local var_0_9 = var_0_4:slider("Defensive-Ticks", 1, 22, 16, 1, function(arg_6_0)
	return arg_6_0 == 16 and "NL" or arg_6_0 == 17 and "GS" or arg_6_0 .. "t"
end)

var_0_4:label("    ------------------------------------")

local var_0_10 = var_0_4:combo("Tick Options", {
	"Default",
	"Custom",
	"Self-Calculation"
})
local var_0_11 = var_0_4:slider("Process-Ticks", 1, 22, 16, 1, function(arg_7_0)
	return arg_7_0 == 16 and "NL" or arg_7_0 == 17 and "GS" or arg_7_0 .. "t"
end)

var_0_4:label("    ------------------------------------")

local var_0_12 = var_0_4:combo("Limit Options", {
	"Default",
	"Custom"
})
local var_0_13 = var_0_4:slider("Exploits-Limit", 1, 10, 1, 1, function(arg_8_0)
	return arg_8_0 == 1 and "Default" or arg_8_0
end)

var_0_4:label("    ------------------------------------")

local var_0_14 = var_0_4:combo("Teleport Options", {
	"Security",
	"Instant",
	"Experimental"
})
local var_0_15 = var_0_4:combo("Charge Mode", {
	"Default",
	"Force",
	"On-Peek"
})
local var_0_16 = var_0_4:slider("Max-Unlag", 0, 10, 2, 0.1, function(arg_9_0)
	return arg_9_0 == 0 and "Off" or arg_9_0 == 2 and "Default" or arg_9_0 / 10 .. "s"
end)

var_0_4:label("    ------------------------------------")

local var_0_17 = var_0_4:combo("Auto-Discharge", {
	"Disabled",
	"Automatic",
	"Modern"
})
local var_0_18 = var_0_4:combo("Anti-Prediction", {
	"Disabled",
	"Default",
	"Random",
	"Tick"
})
local var_0_19 = var_0_4:slider("Self-Tick", 1, 10, 1, 1, function(arg_10_0)
	return arg_10_0 == 3 and "Default" or arg_10_0 .. "t"
end)

var_0_4:label("    ------------------------------------")

local var_0_20 = var_0_4:combo("Avoid Unsafe-Tick", {
	"Disabled",
	"Safe-Points",
	"Ragebot-Settings"
})

var_0_4:label("    ------------------------------------")

local var_0_21 = var_0_4:switch("Watermark", false)
local var_0_22 = var_0_4:color_picker("Color", color(100, 255, 255, 246))
local var_0_23 = var_0_4:switch("Show Logs", false)

var_0_4:label("    ------------------------------------")

local var_0_24 = var_0_4:selectable("Unsafe Options", {
	"Clock Correction Detector",
	"Enhanced Shooting (Forced Firing)",
	"Fast Charging",
	"Speed+"
})
local var_0_25 = {
	frame_time = 0,
	is_charge_safe = false,
	charge_ticks = 0,
	charge_percentage = 0,
	can_dt = false,
	can_exploit = false,
	dl = 1,
	last_update = 0,
	global_alpha = 0.3,
	pulse_anim = 0,
	enabled = false,
	logs = {},
	dm = {
		0,
		0,
		0,
		0,
		0
	},
	animation_state = {
		recovery_timer = 0,
		last_shot_time = 0,
		last_weapon_change = 0,
		pulse_intensity = 0.5,
		charge_flow_anim = 0,
		shot_recoil_anim = 0,
		weapon_switch_anim = 0
	},
	cmove = {
		old_command_num = 0,
		old_sim_time = 0,
		old_tickbase = 0,
		max_history = 10,
		last_charge_log = 0,
		validate_cmd = 0,
		last_charge = 0,
		is_cmd_safe = true,
		can_shift_tickbase = 0,
		did_shift_before = false,
		charged_before = false,
		skip_next_differ = false,
		charge_history = {}
	},
	init = function(arg_11_0)
		arg_11_0.watermark_drag = {
			dragging = false,
			height = 37,
			width = 300,
			y = 200,
			x = 100,
			drag_offset_y = 0,
			drag_offset_x = 0
		}

		function arg_11_0.watermark_drag.drag(arg_12_0)
			if not (ui.get_alpha() > 0) then
				arg_12_0.dragging = false

				return arg_12_0.x, arg_12_0.y
			end

			local var_12_0 = ui.get_mouse_position()
			local var_12_1 = var_12_0.x
			local var_12_2 = var_12_0.y
			local var_12_3 = common.is_button_down(1)

			if var_12_1 >= arg_12_0.x and var_12_1 <= arg_12_0.x + arg_12_0.width and var_12_2 >= arg_12_0.y and var_12_2 <= arg_12_0.y + arg_12_0.height and var_12_3 and not arg_12_0.dragging then
				arg_12_0.dragging = true
				arg_12_0.drag_offset_x = var_12_1 - arg_12_0.x
				arg_12_0.drag_offset_y = var_12_2 - arg_12_0.y
			end

			if arg_12_0.dragging then
				if var_12_3 then
					local var_12_4 = render.screen_size()
					local var_12_5 = var_12_1 - arg_12_0.drag_offset_x
					local var_12_6 = var_12_2 - arg_12_0.drag_offset_y
					local var_12_7 = math.clamp(var_12_5, 0, var_12_4.x - arg_12_0.width)

					arg_12_0.y, arg_12_0.x = math.clamp(var_12_6, 0, var_12_4.y - arg_12_0.height), var_12_7
				else
					arg_12_0.dragging = false
				end
			end

			return arg_12_0.x, arg_12_0.y
		end

		for iter_11_0 = 1, 5 do
			arg_11_0.dm[iter_11_0] = 0
		end

		for iter_11_1 = 1, arg_11_0.cmove.max_history do
			arg_11_0.cmove.charge_history[iter_11_1] = 0
		end

		local var_11_0 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAdRJREFUWEe9li1LBGEUhc/J/ond6o8QxSBbDFosi64Gi6BGg6iwwShYLOIigkUQmwZxwSSYLEbtdutx7jIDwzgfd2Zn5i1b9r3Pee+5H0O0dCQtkXxK4tgGX9IygAcApyQP4szGBUhaBXAXQockD1sTIGkNwG0I/AHQIfnbigBJfQDXMdg+ybNWakDSJoDLGOyT5GxavdVeA5K2AVwkYH2SN40LkLQD4DwBeiU5l9VttWVA0gaADwBDAL0YsEfysVEBIfwKwDeABQB7AHYB3JNcyZs1U2dA0lEAOI5BTMQJgJkgE28k3xsTIOkFwHwKYJIJkvabeypnIAduwDFJs6LwVBKQkvYkqOt5vV0qLUCSpdxSn3VGJAeFTw//UEqApA6Ar4LgA5KjpgRkFV3Ec3sfXXBnwOH7N8mu9+WlBDh8t3jWduPaBTh9rwR3dUFBv5fq+bTs5NaAA17J97iQTAGOoqvse6GAJosuaUNqBiTZsLGhk3VK93tWoH8CJNlet++5xeBSfM1GMab2PdeC8PUTf4Oxu54ionLLubogUXy2VGynR8unVnjmHEiIMBueAWyV2XLeiZjXhrZ27XPLitGKzr1ivXDXJCwTrMp/3duwSnDPnT8WeqEh2dywlgAAAABJRU5ErkJggg=="

		arg_11_0.bullet_icon = render.load_image(var_0_1.decode(var_11_0), vector(32, 32))

		arg_11_0:add_log("666DT System Initialized")
	end,
	add_log = function(arg_13_0, arg_13_1)
		table.insert(arg_13_0.logs, {
			text = arg_13_1,
			time = globals.realtime,
			color = color(255, 255, 255, 255)
		})

		if #arg_13_0.logs > 8 then
			table.remove(arg_13_0.logs, 1)
		end
	end,
	update_logs = function(arg_14_0)
		local var_14_0 = globals.realtime

		for iter_14_0 = #arg_14_0.logs, 1, -1 do
			if var_14_0 - arg_14_0.logs[iter_14_0].time > 6 then
				table.remove(arg_14_0.logs, iter_14_0)
			end
		end
	end,
	smooth_lerp = function(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
		return arg_15_1 + (arg_15_2 - arg_15_1) * globals.frametime * arg_15_3
	end,
	update_animations = function(arg_16_0)
		local var_16_0 = globals.frametime
		local var_16_1 = globals.realtime

		arg_16_0.pulse_anim = (math.sin(var_16_1 * 3) + 1) * 0.5

		local var_16_2 = var_16_1 - arg_16_0.animation_state.last_weapon_change

		if var_16_2 < 0.5 then
			arg_16_0.animation_state.weapon_switch_anim = math.max(0, 1 - var_16_2 * 2)
		else
			arg_16_0.animation_state.weapon_switch_anim = math.max(0, arg_16_0.animation_state.weapon_switch_anim - var_16_0 * 8)
		end

		local var_16_3 = var_16_1 - arg_16_0.animation_state.last_shot_time

		if var_16_3 < 0.8 then
			arg_16_0.animation_state.shot_recoil_anim = math.sin(var_16_3 * math.pi * 2) * (1 - var_16_3 / 0.8)
		else
			arg_16_0.animation_state.shot_recoil_anim = math.max(0, arg_16_0.animation_state.shot_recoil_anim - var_16_0 * 6)
		end

		if arg_16_0.can_exploit then
			arg_16_0.animation_state.charge_flow_anim = (arg_16_0.animation_state.charge_flow_anim + var_16_0 * 2) % 1
		else
			arg_16_0.animation_state.charge_flow_anim = 0
		end

		if arg_16_0.can_exploit then
			arg_16_0.animation_state.pulse_intensity = math.lerp(arg_16_0.animation_state.pulse_intensity, 1, var_16_0 * 3)
		else
			arg_16_0.animation_state.pulse_intensity = math.lerp(arg_16_0.animation_state.pulse_intensity, 0.5, var_16_0 * 3)
		end
	end,
	update_weapon_info = function(arg_17_0)
		local var_17_0 = entity.get_local_player()

		if not var_17_0 or not var_17_0:is_alive() then
			arg_17_0.global_alpha = 0

			return
		end

		local var_17_1 = var_17_0:get_player_weapon()

		if not var_17_1 then
			arg_17_0.global_alpha = 0

			return
		end

		local var_17_2 = var_17_1:get_weapon_index()
		local var_17_3 = globals.realtime

		if arg_17_0.last_weapon_id ~= var_17_2 then
			arg_17_0.last_weapon_id = var_17_2
			arg_17_0.animation_state.last_weapon_change = var_17_3
			arg_17_0.animation_state.recovery_timer = var_17_3

			arg_17_0:add_log("Weapon switched")
		end

		local var_17_4 = 0
		local var_17_5, var_17_6 = pcall(function()
			return rage.exploit:get()
		end)

		if var_17_5 and type(var_17_6) == "number" then
			var_17_4 = var_17_6
			arg_17_0.charge_percentage = var_17_4
		end

		local var_17_7 = reference.double_tap_reference.double_tap:get() or var_0_3:get()
		local var_17_8 = reference.fake_duck:get()
		local var_17_9 = var_17_2 >= 500 and var_17_2 <= 525 or var_17_2 == 41 or var_17_2 == 42 or var_17_2 == 59 or var_17_2 >= 43 and var_17_2 <= 49

		arg_17_0.can_dt = var_17_7 and not var_17_8 and not var_17_9
		arg_17_0.can_exploit = arg_17_0.can_dt and var_17_4 >= 0.95

		if arg_17_0.can_dt then
			if var_17_2 == 7 or var_17_2 == 39 or var_17_2 == 16 then
				arg_17_0.dl = 3
			elseif var_17_2 == 1 or var_17_2 == 30 or var_17_2 == 36 or var_17_2 == 2 or var_17_2 == 4 or var_17_2 == 61 or var_17_2 == 11 or var_17_2 == 38 or var_17_2 == 32 then
				arg_17_0.dl = 2
			elseif var_17_2 == 34 or var_17_2 == 19 or var_17_2 == 25 or var_17_2 == 35 or var_17_2 == 29 or var_17_2 == 14 or var_17_2 == 28 or var_17_2 == 27 then
				arg_17_0.dl = 5
			elseif var_17_2 == 33 or var_17_2 == 24 or var_17_2 == 26 or var_17_2 == 17 or var_17_2 == 13 or var_17_2 == 10 or var_17_2 == 60 or var_17_2 == 8 then
				arg_17_0.dl = 4
			elseif var_17_2 == 9 or var_17_2 == 31 or var_17_2 == 40 or var_17_9 then
				arg_17_0.dl = 1
			else
				arg_17_0.dl = 1
			end
		else
			arg_17_0.dl = 1
		end

		local var_17_10 = 0.3

		if arg_17_0.can_dt and not var_17_9 then
			var_17_10 = arg_17_0.can_exploit and 1 or 0.5 + var_17_4 * 0.5
		end

		local var_17_11 = var_17_10 * (1 - arg_17_0.animation_state.weapon_switch_anim * 0.7)
		local var_17_12 = 8

		if arg_17_0.animation_state.weapon_switch_anim > 0 then
			var_17_12 = 15
		end

		arg_17_0.global_alpha = arg_17_0:smooth_lerp(arg_17_0.global_alpha, var_17_11, var_17_12)

		local var_17_13 = 5 * globals.frametime

		for iter_17_0 = 1, 5 do
			if iter_17_0 <= arg_17_0.dl then
				if arg_17_0.can_exploit then
					if iter_17_0 == 1 and arg_17_0.dm[1] < 1 then
						arg_17_0.dm[1] = math.min(arg_17_0.dm[1] + var_17_13 * 1.5, 1)
					elseif iter_17_0 > 1 and arg_17_0.dm[iter_17_0 - 1] >= 0.7 and arg_17_0.dm[iter_17_0] < 1 then
						arg_17_0.dm[iter_17_0] = math.min(arg_17_0.dm[iter_17_0] + var_17_13 * 1.2, 1)
					end
				else
					local var_17_14 = var_17_4 > 0.5 and iter_17_0 <= math.floor(var_17_4 * arg_17_0.dl) and 0.5 or 0.1

					arg_17_0.dm[iter_17_0] = math.lerp(arg_17_0.dm[iter_17_0], var_17_14, var_17_13 * 4)
				end
			else
				arg_17_0.dm[iter_17_0] = math.max(arg_17_0.dm[iter_17_0] - var_17_13 * 3, 0)
			end
		end

		arg_17_0:update_animations()
	end,
	update_charge_status = function(arg_19_0, arg_19_1)
		local var_19_0 = entity.get_local_player()

		if not var_19_0 or not var_19_0:is_alive() then
			return
		end

		local var_19_1 = var_19_0.m_nTickBase or 0
		local var_19_2 = globals.realtime
		local var_19_3 = false
		local var_19_4 = 0
		local var_19_5, var_19_6 = pcall(function()
			return rage.exploit:get()
		end)

		if var_19_5 and type(var_19_6) == "number" then
			var_19_4 = var_19_6
			var_19_3 = var_19_4 >= 0.95
		end

		if var_19_3 and not arg_19_0.cmove.charged_before then
			arg_19_0.cmove.charged_before = true
			arg_19_0.cmove.last_charge_log = var_19_2

			local var_19_7 = cvar.sv_maxusrcmdprocessticks:int()
			local var_19_8 = math.floor(var_19_4 * var_19_7)
			local var_19_9 = var_19_4 >= 0.8

			arg_19_0.charge_ticks = var_19_8
			arg_19_0.is_charge_safe = var_19_9

			local var_19_10 = var_19_9 and "safe" or "unsafe"
			local var_19_11 = math.floor(var_19_4 * 100)

			arg_19_0:add_log(string.format("charged: %dt (%s) %d%%", var_19_8, var_19_10, var_19_11))
		elseif not var_19_3 and arg_19_0.cmove.charged_before then
			arg_19_0.cmove.charged_before = false
			arg_19_0.cmove.last_charge = 0
			arg_19_0.charge_ticks = 0

			arg_19_0:add_log("discharged")
		elseif var_19_3 and arg_19_0.cmove.charged_before and var_19_2 - arg_19_0.cmove.last_charge_log > 2 then
			local var_19_12 = cvar.sv_maxusrcmdprocessticks:int()
			local var_19_13 = math.floor(var_19_4 * var_19_12)
			local var_19_14 = var_19_4 >= 0.8

			arg_19_0.charge_ticks = var_19_13
			arg_19_0.is_charge_safe = var_19_14

			local var_19_15 = var_19_14 and "safe" or "unsafe"
			local var_19_16 = math.floor(var_19_4 * 100)

			arg_19_0:add_log(string.format("charged: %dt (%s) %d%%", var_19_13, var_19_15, var_19_16))

			arg_19_0.cmove.last_charge_log = var_19_2
		end

		arg_19_0.cmove.old_tickbase = var_19_1
		arg_19_0.cmove.old_command_num = arg_19_1.command_number
	end,
	get_watermark_text = function(arg_21_0)
		local var_21_0 = entity.get_local_player()

		if not var_21_0 or not var_21_0:is_alive() then
			return "👿 666dt-system | disconnected"
		end

		local var_21_1 = var_21_0:get_name() or "Unknown"
		local var_21_2 = "👿 666dt-system | " .. string.sub(var_21_1, 1, 12)
		local var_21_3 = cvar.sv_maxusrcmdprocessticks:int()

		if arg_21_0.charge_percentage > 0 then
			local var_21_4 = math.floor(arg_21_0.charge_percentage * 100)

			var_21_2 = var_21_2 .. " | tick:" .. var_21_3 .. " (" .. var_21_4 .. "%)"
		end

		return var_21_2
	end,
	render_default_style = function(arg_22_0, arg_22_1, arg_22_2, arg_22_3, arg_22_4, arg_22_5, arg_22_6, arg_22_7, arg_22_8, arg_22_9)
		local var_22_0 = arg_22_7 or 255
		local var_22_1 = arg_22_8 or arg_22_0.global_alpha
		local var_22_2 = arg_22_1 - 2
		local var_22_3 = arg_22_2 - 1
		local var_22_4 = arg_22_3 + 4
		local var_22_5 = 23

		render.rect(vector(var_22_2, var_22_3), vector(var_22_2 + var_22_4, var_22_3 + var_22_5), color(17, 17, 17, 150))

		local var_22_6 = math.sin(globals.realtime * 4) * 0.1 + 0.9
		local var_22_7 = var_22_1 * arg_22_3 * var_22_6 + 3
		local var_22_8 = 200 + math.sin(arg_22_0.animation_state.charge_flow_anim * math.pi * 2) * 55

		render.gradient(vector(arg_22_1 - 2, arg_22_2 + 22), vector(arg_22_1 - 0.3, arg_22_2), color(arg_22_4, arg_22_5, arg_22_6, var_22_8), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, var_22_8), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))
		render.gradient(vector(arg_22_1 + arg_22_3 + 1, arg_22_2 + 22), vector(arg_22_1 + arg_22_3 + 2.7, arg_22_2), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))

		if var_22_7 > 0 then
			render.gradient(vector(arg_22_1 - 2, arg_22_2 + 21), vector(arg_22_1 - 2 + var_22_7 / 2 + 1, arg_22_2 + 22), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))
			render.gradient(vector(arg_22_1 + arg_22_3 + 2, arg_22_2 + 21), vector(arg_22_1 + arg_22_3 + 2 - var_22_7 / 2 - 1, arg_22_2 + 22), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))

			local var_22_9 = arg_22_0.animation_state.shot_recoil_anim * 2

			render.gradient(vector(arg_22_1 + arg_22_3 / 2 - 0.5, arg_22_2 + var_22_9), vector(arg_22_1 + arg_22_3 / 2 - var_22_7 / 2 - 0.5, arg_22_2 - 1 + var_22_9), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))
			render.gradient(vector(arg_22_1 + arg_22_3 / 2 - 0.5, arg_22_2 + var_22_9), vector(arg_22_1 + arg_22_3 / 2 + var_22_7 / 2 + 1, arg_22_2 - 1 + var_22_9), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0), color(arg_22_4, arg_22_5, arg_22_6, 255), color(arg_22_4, arg_22_5, arg_22_6, var_22_0))
		end

		local var_22_10 = arg_22_1 + 3 + math.sin(globals.realtime * 5) * 0.5
		local var_22_11 = arg_22_2 + 5 + arg_22_0.animation_state.shot_recoil_anim

		render.text(1, vector(var_22_10, var_22_11), color(255, 255, 255, 255), nil, arg_22_9)

		return arg_22_3
	end,
	render_watermark = function(arg_23_0)
		if not arg_23_0.enabled then
			return
		end

		local var_23_0, var_23_1 = arg_23_0.watermark_drag.drag(arg_23_0.watermark_drag)

		arg_23_0:update_weapon_info()

		local var_23_2 = render.screen_size()
		local var_23_3 = arg_23_0:get_watermark_text()
		local var_23_4 = render.measure_text(1, nil, var_23_3).x + 20
		local var_23_5 = var_0_22:get()
		local var_23_6 = var_23_5.r
		local var_23_7 = var_23_5.g
		local var_23_8 = var_23_5.b
		local var_23_9 = globals.realtime * (1 + arg_23_0.charge_percentage)
		local var_23_10 = math.floor(math.sin(var_23_9 * 4) * (127.5 * arg_23_0.animation_state.pulse_intensity) + 127.5)

		arg_23_0:render_default_style(var_23_0 + 3, var_23_1, var_23_4, var_23_6, var_23_7, var_23_8, var_23_10, arg_23_0.global_alpha, var_23_3)

		local var_23_11 = entity.get_local_player()

		if var_23_11 and var_23_11:is_alive() then
			local var_23_12 = var_23_11:get_player_weapon()

			if var_23_12 then
				local var_23_13 = var_23_12:get_weapon_index()
				local var_23_14 = ({
					"DEAGLE",
					"ELITE",
					"FIVESEVEN",
					"GLOCK",
					nil,
					nil,
					"AK47",
					"AUG",
					"AWP",
					"FAMAS",
					"G3SG1",
					nil,
					"GALIL",
					"M249",
					nil,
					"M4A4",
					"MAC10",
					nil,
					"P90",
					nil,
					nil,
					nil,
					nil,
					"UMP45",
					"XM1014",
					"BIZON",
					"MAG7",
					"NEGEV",
					"SAWEDOFF",
					"TEC9",
					"ZEUS",
					"P2000",
					"MP7",
					"MP9",
					"NOVA",
					"P250",
					nil,
					"SCAR20",
					"SG553",
					"SSG08"
				})[var_23_13]
				local var_23_15 = var_0_0.get_weapon_icon(var_23_14)

				if var_23_15 then
					local var_23_16 = 38
					local var_23_17 = var_23_0 + 8 + arg_23_0.animation_state.weapon_switch_anim * 10
					local var_23_18 = var_23_1 + 25 + math.sin(arg_23_0.animation_state.weapon_switch_anim * math.pi) * 5
					local var_23_19 = 1 - arg_23_0.animation_state.weapon_switch_anim * 0.3

					var_23_15:draw(var_23_17, var_23_18, nil, 14, 255, 255, 255, 255)

					local var_23_20 = 0
					local var_23_21 = 0

					for iter_23_0 = 1, arg_23_0.dl do
						if arg_23_0.dm[iter_23_0] then
							local var_23_22 = 13 * iter_23_0
							local var_23_23 = var_23_0 + var_23_16 + var_23_22

							if arg_23_0.dl == 1 then
								var_23_21 = var_23_13 >= 500 and var_23_13 <= 525 and arg_23_0.dm[iter_23_0] * 5 or arg_23_0.global_alpha * arg_23_0.dm[iter_23_0] * 20
							elseif arg_23_0.dl == 2 then
								var_23_21 = arg_23_0.global_alpha * arg_23_0.dm[iter_23_0] * 30
							elseif arg_23_0.dl == 3 then
								var_23_21 = arg_23_0.global_alpha * arg_23_0.dm[iter_23_0] * 40
							elseif arg_23_0.dl == 4 then
								var_23_21 = arg_23_0.global_alpha * arg_23_0.dm[iter_23_0] * 50
							elseif arg_23_0.dl == 5 then
								var_23_21 = arg_23_0.global_alpha * arg_23_0.dm[iter_23_0] * 70
							end

							if (not (var_23_13 >= 500) or not (var_23_13 <= 525)) and arg_23_0.bullet_icon then
								local var_23_24 = arg_23_0.dm[iter_23_0] * 255 * (0.7 + (math.sin(globals.realtime * 8 + iter_23_0) + 1) * 0.5 * 0.3)

								if arg_23_0.can_exploit then
									var_23_24 = var_23_24 * (0.8 + arg_23_0.pulse_anim * 0.4)
								end

								render.texture(arg_23_0.bullet_icon, vector(var_23_23, var_23_1 + 25), vector(19, 15), color(255, 255, 255, var_23_24), "f")
							end
						end
					end

					if var_0_23:get() then
						arg_23_0:render_logs(var_23_0 + 10, var_23_1, var_23_16, var_23_21)
					end
				end
			end
		end

		arg_23_0:update_logs()
	end,
	render_logs = function(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4)
		local var_24_0 = globals.realtime

		for iter_24_0 = 1, #arg_24_0.logs do
			if iter_24_0 > 8 then
				break
			end

			local var_24_1 = arg_24_0.logs[iter_24_0]
			local var_24_2 = var_24_0 - var_24_1.time
			local var_24_3 = 255

			if var_24_2 >= 5 then
				var_24_3 = math.abs(math.lerp(255, 0, (var_24_2 - 5) / 1))
			elseif var_24_2 < 0.3 then
				var_24_3 = math.lerp(0, 255, var_24_2 / 0.3)
			end

			local var_24_4 = arg_24_1 + arg_24_3 + arg_24_4 + 25
			local var_24_5 = arg_24_2 + 10 + iter_24_0 * 13
			local var_24_6 = color(255, 255, 255, var_24_3)

			if string.find(var_24_1.text, "charged:") then
				if string.find(var_24_1.text, "safe") then
					var_24_6 = color(100, 255, 100, var_24_3)
				else
					var_24_6 = color(255, 100, 100, var_24_3)
				end
			end

			if string.find(var_24_1.text, "discharged") then
				var_24_6 = color(255, 100, 100, var_24_3)
			end

			render.text(1, vector(var_24_4, var_24_5), var_24_6, nil, var_24_1.text)
		end
	end
}

var_0_25:init()
var_0_25:add_log("666DT System Loaded")

local var_0_26 = {
	tick = 0,
	result = false
}

local function var_0_27()
	if var_0_26.tick == globals.tickcount then
		return var_0_26.result
	end

	var_0_26.tick = globals.tickcount
	var_0_26.result = false

	local var_25_0 = entity.get_local_player()

	if not var_25_0 or not var_25_0:is_alive() then
		return false
	end

	local var_25_1 = 0
	local var_25_2, var_25_3 = pcall(function()
		return rage.exploit:get()
	end)

	if var_25_2 and type(var_25_3) == "number" then
		var_25_1 = var_25_3
	end

	if var_25_1 <= 0 then
		return false
	end

	local var_25_4 = cvar.sv_maxusrcmdprocessticks:int()
	local var_25_5 = math.floor(var_25_1 * var_25_4)

	if var_25_5 < 1 then
		var_25_5 = 1
	end

	local var_25_6 = var_25_0:simulate_movement()

	if not var_25_6 then
		return false
	end

	var_25_6:think(var_25_5)

	local var_25_7 = var_25_0:get_eye_position()
	local var_25_8 = var_25_6.origin + vector(0, 0, var_25_6.view_offset or 64)
	local var_25_9 = var_25_8
	local var_25_10 = utils.trace_line(var_25_7, var_25_8, var_25_0)

	if var_25_10 and var_25_10.end_pos then
		var_25_9 = var_25_10.end_pos
	end

	local var_25_11 = entity.get_players(true)

	if not var_25_11 or #var_25_11 == 0 then
		return false
	end

	local var_25_12 = var_25_0:get_origin()

	for iter_25_0 = 1, #var_25_11 do
		local var_25_13 = var_25_11[iter_25_0]

		if var_25_13 and var_25_13:is_alive() and not var_25_13:is_dormant() then
			local var_25_14 = var_25_13:get_origin()

			if not var_25_14 then
				empty
			elseif var_25_12:dist(var_25_14) < 800 then
				local var_25_15 = var_25_13:get_hitbox_position(0)

				if not var_25_15 then
					empty
				else
					local var_25_16, var_25_17 = utils.trace_bullet(var_25_0, var_25_9, var_25_15)

					if var_25_16 > 0 then
						var_0_26.result = true

						return true
					end
				end
			end
		end
	end

	return false
end

local var_0_28 = false

local function var_0_29(arg_27_0)
	if globals.tickcount % (arg_27_0 + 1) == 0 then
		if var_0_28 then
			var_0_28 = false
		else
			var_0_28 = true
		end
	end

	return var_0_28
end

local function var_0_30(arg_28_0)
	if var_0_5:get() == "Offensive" then
		reference.double_tap_reference.lag_options:override("Disabled")
	elseif var_0_6:get() == "On-Peek" then
		if var_0_7:get() == "Default" then
			reference.double_tap_reference.lag_options:override("On Peek")
		elseif var_0_8:get() == "Events" then
			reference.double_tap_reference.lag_options:override("Disabled")

			if var_0_27() then
				arg_28_0.force_defensive = arg_28_0.command_number % var_0_9:get() == 0
			else
				arg_28_0.force_defensive = false
			end
		elseif var_0_27() then
			if arg_28_0.command_number % var_0_9:get() == 0 then
				reference.double_tap_reference.lag_options:override("Always On")
			else
				reference.double_tap_reference.lag_options:override("Disabled")
			end
		else
			reference.double_tap_reference.lag_options:override("Disabled")
		end
	elseif var_0_7:get() == "Default" then
		reference.double_tap_reference.lag_options:override("Always On")
	elseif var_0_8:get() == "Events" then
		reference.double_tap_reference.lag_options:override("Disabled")

		arg_28_0.force_defensive = arg_28_0.command_number % var_0_9:get() == 0
	elseif arg_28_0.command_number % var_0_9:get() == 0 then
		reference.double_tap_reference.lag_options:override("Always On")
	else
		reference.double_tap_reference.lag_options:override("Disabled")
	end
end

local function var_0_31()
	local var_29_0 = entity.get_local_player()

	if var_29_0 == nil then
		return
	end

	local var_29_1 = var_29_0:get_player_weapon()

	if var_29_1 == nil then
		return
	end

	local var_29_2 = var_29_1:get_weapon_index()

	if var_29_2 == nil then
		return
	end

	if var_0_10:get() == "Default" then
		cvar.sv_maxusrcmdprocessticks:int(16)
	elseif var_0_10:get() == "Custom" then
		cvar.sv_maxusrcmdprocessticks:int(var_0_11:get())
	elseif var_0_10:get() == "Self-Calculation" then
		if entity.get_threat() == nil then
			cvar.sv_maxusrcmdprocessticks:int(16)

			return
		elseif var_29_2 == 77 or var_29_2 == 107 or var_29_2 == 99 or var_29_2 == 96 or var_29_2 == 156 or var_29_2 == 47 or var_29_2 == 113 then
			cvar.sv_maxusrcmdprocessticks:int(16)
			reference.fakelag_reference.limit:override(14)
		else
			local var_29_3 = var_29_0:get_origin()
			local var_29_4 = entity.get_threat():get_origin()
			local var_29_5 = utils.trace_bullet(var_29_0, var_29_3, var_29_4)

			if var_29_5 == 0 then
				bullet_damage = 48
			else
				bullet_damage = var_29_5
			end

			local var_29_6 = math.round(math.clamp(bullet_damage / 3, 12, 18))

			cvar.sv_maxusrcmdprocessticks:int(var_29_6)
			reference.fakelag_reference.limit:override(var_29_6 - 2)
		end
	end

	if var_0_12:get() == "Default" then
		reference.double_tap_reference.fakelag_limit:override(1)
	else
		reference.double_tap_reference.fakelag_limit:override(var_0_13:get())
	end
end

local function var_0_32()
	if var_0_14:get() == "Security" then
		reference.double_tap_reference.immediate_teleport:override(false)
	elseif var_0_14:get() == "Instant" then
		reference.double_tap_reference.immediate_teleport:override(true)
	elseif var_0_14:get() == "Experimental" then
		if var_0_27() then
			reference.double_tap_reference.immediate_teleport:override(globals.tickcount % 3 == 0 and true or false)
		else
			local var_30_0 = reference.double_tap_reference.immediate_teleport
			local var_30_1 = var_30_0
			local var_30_2 = var_30_0.override

			if globals.tickcount % 3 == 0 then
				empty
			end

			var_30_2(var_30_1, true)
		end
	end

	if var_0_15:get() == "Force" then
		rage.exploit:force_charge()
	elseif var_0_15:get() == "On-Peek" and var_0_27() then
		rage.exploit:force_charge()
	end

	cvar.sv_maxunlag:float(var_0_16:get() / 10)
end

local function var_0_33()
	local var_31_0 = cvar.cl_clock_correction

	if var_0_24:get(1) then
		var_31_0:int(0)

		local var_31_1 = globals.tickcount
		local var_31_2 = globals.tickinterval
		local var_31_3 = entity.get_local_player()

		if not var_31_3 then
			return
		end

		local var_31_4 = var_31_3.m_nTickBase or 0
		local var_31_5 = var_0_25.cmove.old_tickbase or 0

		if var_31_5 ~= 0 and var_31_4 < var_31_5 and var_31_5 - var_31_4 > 13 then
			var_0_25.cmove.skip_next_differ = true
			var_0_25.cmove.charged_before = false
			var_0_25.cmove.can_shift_tickbase = true

			var_0_25:add_log(string.format("tick correction: %d -> %d (delta: %d)", var_31_5, var_31_4, var_31_5 - var_31_4))
		end
	else
		var_31_0:int(1)
	end
end

local var_0_34 = 0
local var_0_35 = 0.2

local function var_0_36(arg_32_0)
	if not var_0_24:get(2) then
		return
	end

	local var_32_0 = entity.get_local_player()

	if not var_32_0 or not var_32_0:is_alive() then
		return
	end

	local var_32_1 = var_32_0:get_player_weapon()

	if not var_32_1 then
		return
	end

	local var_32_2 = var_32_1:get_weapon_index()
	local var_32_3 = var_32_2 == 11 or var_32_2 == 38
	local var_32_4 = ui.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Hit Chance")
	local var_32_5 = globals.realtime

	if not (bit.band(var_32_0.m_fFlags, 1) ~= 0) then
		var_0_34 = var_32_5

		return
	elseif var_32_5 - var_0_34 < var_0_35 then
		return
	end

	local var_32_6 = var_0_2(var_32_1)
	local var_32_7

	var_32_7 = var_32_0.m_bIsScoped == 1

	if var_32_3 then
		local var_32_8 = globals.realtime
		local var_32_9 = entity.get_threat(true)

		if var_32_9 and var_32_9:is_alive() then
			local var_32_10 = var_32_9.m_iHealth
			local var_32_11 = var_32_0:get_origin():dist(var_32_9:get_origin())
			local var_32_12 = var_32_0.m_vecVelocity
			local var_32_13 = math.sqrt(var_32_12.x * var_32_12.x + var_32_12.y * var_32_12.y)

			if var_32_11 < 1000 and var_32_10 > 50 then
				if var_32_13 <= utils.random_int(35, 40) then
					arg_32_0.in_attack = 1

					var_0_25:add_log("fortify shot: shoot at close range")
					var_32_4:override(100)
				end
			else
				var_32_4:override()
			end
		end
	end
end

local function var_0_37()
	if not var_0_24:get(3) then
		return
	end

	local var_33_0 = entity.get_local_player()

	if not var_33_0 or not var_33_0:is_alive() then
		return
	end

	local var_33_1 = 0
	local var_33_2, var_33_3 = pcall(function()
		return rage.exploit:get()
	end)

	if var_33_2 and type(var_33_3) == "number" then
		var_33_1 = var_33_3
	end

	local function var_33_4(arg_35_0, arg_35_1, arg_35_2)
		if arg_35_1 == nil then
			return false
		end

		local var_35_0 = arg_35_0.m_nTickBase
		local var_35_1 = globals.tickinterval * (var_35_0 - arg_35_2)

		if not var_0_3:get() then
			return false
		end

		if reference.fake_duck:get() then
			return false
		end

		if var_35_1 < arg_35_0.m_flNextAttack then
			return false
		end

		if var_35_1 < arg_35_1.m_flNextPrimaryAttack then
			return false
		end

		return true
	end

	local var_33_5 = var_33_0:get_player_weapon()

	if not var_33_5 then
		return
	end

	local var_33_6 = var_33_5:get_weapon_index()
	local var_33_7 = var_33_4(var_33_0, var_33_5, 20)
	local var_33_8 = var_33_6 >= 500 and var_33_6 <= 525
	local var_33_9 = var_33_6 >= 43 and var_33_6 <= 49

	if (var_0_3:get() or reference.double_tap_reference.double_tap:get()) and not var_33_8 and not var_33_9 then
		local var_33_10 = var_33_0.m_vecVelocity
		local var_33_11 = math.sqrt(var_33_10.x * var_33_10.x + var_33_10.y * var_33_10.y)

		if var_33_1 >= 0.05 and var_33_1 <= 0.15 then
			local var_33_12 = 0.05

			if pcall(function()
				rage.exploit:force_charge()
			end) then
				var_0_25:add_log("fast charge: charging at " .. var_33_12 * 100 .. "% per frame")
			end
		end
	end
end

local function var_0_38(arg_37_0)
	if not var_0_24:get(4) then
		return
	end

	local var_37_0 = entity.get_local_player()

	if not var_37_0 or not var_37_0:is_alive() then
		return
	end

	local var_37_1 = var_37_0.m_vecVelocity

	if math.sqrt(var_37_1.x * var_37_1.x + var_37_1.y * var_37_1.y) > 5 then
		local var_37_2 = 1.15
		local var_37_3 = arg_37_0.forwardmove
		local var_37_4 = arg_37_0.sidemove
		local var_37_5 = arg_37_0.upmove

		arg_37_0.forwardmove = var_37_3 * var_37_2
		arg_37_0.sidemove = var_37_4 * var_37_2
		arg_37_0.upmove = var_37_5 * var_37_2

		if bit.band(var_37_0.m_fFlags, 1) ~= 0 and var_37_3 > 0 then
			arg_37_0.in_jump = 1

			var_0_25:add_log("speed boost: auto jump applied")
		end
	end
end

local function var_0_39()
	local var_38_0 = entity.get_local_player()

	if var_38_0 == nil then
		return
	end

	local function var_38_1(arg_39_0, arg_39_1)
		return bit.band(arg_39_0.m_fFlags, bit.lshift(1, arg_39_1)) ~= 0
	end

	if var_0_17:get() == "Automatic" then
		if not var_38_0:is_dormant() then
			if not var_0_3:get() then
				return
			end

			local var_38_2 = false
			local var_38_3 = var_38_0:get_player_weapon()

			if var_38_3 == nil then
				return
			end

			local var_38_4 = var_38_3:get_classname() == "CKnife"

			local function var_38_5(arg_40_0)
				local var_40_0, var_40_1 = utils.trace_bullet(arg_40_0, arg_40_0:get_hitbox_position(3), var_38_0:get_hitbox_position(3))

				if var_40_0 ~= 0 and var_40_0 < 50 and (var_40_1.entity and var_40_1.entity == var_38_0 or false) then
					return true
				end

				return false
			end

			if not var_38_4 then
				for iter_38_0, iter_38_1 in pairs(entity.get_players(true)) do
					if iter_38_1 == var_38_0 then
						empty
					elseif var_38_5(iter_38_1) then
						var_38_2 = true
					end
				end
			end

			if var_38_2 and not var_38_1(var_38_0, 0) then
				reference.fake_duck:override(true)
			else
				reference.fake_duck:override()
			end
		end
	elseif var_0_17:get() == "Modern" and not var_38_1(var_38_0, 0) then
		reference.fake_duck:override(globals.tickcount % 14 == 0 and true or false)
	end
end

local function var_0_40()
	local var_41_0 = utils.random_int(0, 1)
	local var_41_1 = utils.random_int(1, 0)
	local var_41_2 = utils.random_int(var_41_0, var_41_1)

	if var_0_18:get() == "Disabled" then
		reference.leg_movement:override()
	elseif var_0_18:get() == "Default" then
		if var_0_27() then
			reference.leg_movement:override(globals.tickcount % 3 == 0 and "Walking" or "Sliding")
		end
	elseif var_0_18:get() == "Random" then
		if var_0_27() then
			if var_41_2 == 1 then
				reference.leg_movement:override("Sliding")
			else
				reference.leg_movement:override("Walking")
			end
		end
	elseif var_0_18:get() == "Tick" and var_0_27() then
		reference.leg_movement:override(var_0_29(var_0_19:get()) and "Walking" or "Sliding")
	end
end

local var_0_41 = {
	MAX_PLAYERS = 64,
	INT_MAX = 4.5e+15
}
local var_0_42 = {}

for iter_0_0 = 1, var_0_41.MAX_PLAYERS do
	var_0_42[iter_0_0] = {
		ticks = 0,
		origin = vector(0, 0, 0)
	}
end

local function var_0_43(arg_42_0)
	if var_0_20:get() == "Disabled" then
		reference.safe_points:override()
		reference.delay_shot:override()
		reference.extended_backtrack:override()
		reference.head_scale:override()
		reference.body_scale:override()
	elseif entity.get_threat() == nil then
		return
	else
		local var_42_0 = entity.get_threat():get_index()
		local var_42_1 = var_0_42[var_42_0]
		local var_42_2 = entity.get_threat():get_origin()

		if #(var_42_2 - var_42_1.origin) > 0 then
			var_42_1.ticks = arg_42_0.tickcount
		end

		var_42_1.origin = var_42_2

		if math.round(0.5 / globals.tickinterval + 0.5) > arg_42_0.tickcount - var_42_1.ticks then
			if var_42_0 == 2 then
				if var_0_20:get() == "Safe-Points" then
					reference.safe_points:override("Force")
					reference.delay_shot:override()
					reference.extended_backtrack:override()
					reference.head_scale:override()
					reference.body_scale:override()
				elseif var_0_20:get() == "Ragebot-Settings" then
					reference.safe_points:override()
					reference.delay_shot:override(true)
					reference.extended_backtrack:override(true)
					reference.head_scale:override(60)
					reference.body_scale:override(60)
				end
			elseif var_0_20:get() == "Safe-Points" then
				reference.safe_points:override()
			elseif var_0_20:get() == "Ragebot-Settings" then
				reference.delay_shot:override()
				reference.extended_backtrack:override()
				reference.head_scale:override()
				reference.body_scale:override()
			end
		end
	end
end

events.weapon_fire:set(function(arg_43_0)
	local var_43_0 = entity.get(arg_43_0.userid, true)
	local var_43_1 = entity.get_local_player()

	if var_43_0 and var_43_1 and var_43_0:get_index() == var_43_1:get_index() then
		var_0_25.animation_state.last_shot_time = globals.realtime

		var_0_25:add_log("Shot fired")
	end
end)
events.createmove:set(function(arg_44_0)
	if entity.get_local_player() == nil or not globals.is_in_game then
		return
	end

	reference.double_tap_reference.double_tap:override(var_0_3:get())
	var_0_30(arg_44_0)
	var_0_31()
	var_0_32()
	var_0_39()
	var_0_40()
	var_0_43(arg_44_0)
	var_0_33()
	var_0_36(arg_44_0)
	var_0_37()
	var_0_38(arg_44_0)
	var_0_25:update_charge_status(arg_44_0)
end)
events.render:set(function()
	reference.double_tap_reference.double_tap:visibility(false)
	var_0_6:visibility(var_0_5:get() == "Defensive")
	var_0_7:visibility(var_0_5:get() == "Defensive")
	var_0_8:visibility(var_0_5:get() == "Defensive" and var_0_7:get() == "DT-666")
	var_0_9:visibility(var_0_5:get() == "Defensive" and var_0_7:get() == "DT-666")
	var_0_11:visibility(var_0_10:get() == "Custom")
	var_0_13:visibility(var_0_12:get() == "Custom")
	var_0_19:visibility(var_0_18:get() == "Tick")
	var_0_22:visibility(var_0_21:get())
	var_0_23:visibility(var_0_21:get())

	var_0_25.enabled = var_0_21:get()

	var_0_25:render_watermark()
end)
events.shutdown:set(function()
	reference.double_tap_reference.double_tap:visibility(true)
	cvar.sv_maxusrcmdprocessticks:int(16)
	cvar.sv_maxunlag:float(0.2)
	reference.safe_points:override()
	reference.delay_shot:override()
	reference.extended_backtrack:override()
	reference.head_scale:override()
	reference.body_scale:override()
end)
