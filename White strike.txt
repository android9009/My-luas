-- Dumped by gpt 6.7

local var_0_0, var_0_1 = pcall(require, "neverlose/gradient")

if not var_0_0 then
	print("gradient load failed: " .. tostring(var_0_1))

	var_0_1 = nil
end

local function var_0_2(arg_1_0, arg_1_1, arg_1_2)
	if not var_0_1 or not var_0_1.text_animate then
		return nil
	end

	local var_1_0, var_1_1 = pcall(function()
		return var_0_1.text_animate(arg_1_0, arg_1_1, arg_1_2)
	end)

	if not var_1_0 then
		print("gradient anim failed: " .. tostring(var_1_1))
	end

	return var_1_1
end

local var_0_3 = {
	time = 0,
	done = false,
	font_big = render.load_font("Verdana", 26, "bad"),
	font_small = render.load_font("Verdana", 18, "bad"),
	clamp = function(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
		return math.max(arg_3_2, math.min(arg_3_3, arg_3_1))
	end,
	a = function(arg_4_0, arg_4_1)
		return math.max(0, math.min(255, math.floor(arg_4_1 or 0)))
	end,
	ease = function(arg_5_0, arg_5_1)
		arg_5_1 = arg_5_0:clamp(arg_5_1, 0, 1)

		return arg_5_1 * arg_5_1 * arg_5_1 * (arg_5_1 * (arg_5_1 * 6 - 15) + 10)
	end,
	anim = function(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
		if arg_6_1 < arg_6_2 then
			return 0
		end

		if arg_6_3 <= arg_6_1 then
			return 1
		end

		return arg_6_0:ease((arg_6_1 - arg_6_2) / (arg_6_3 - arg_6_2))
	end,
	draw_flow_text = function(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
		local var_7_0 = color(0, 0, 0, 255)
		local var_7_1 = color(209, 182, 255, 255)
		local var_7_2 = 1
		local var_7_3 = 0.34
		local var_7_4 = 0.62
		local var_7_5 = arg_7_3
		local var_7_6 = render.measure_text(arg_7_1, nil, arg_7_2).x
		local var_7_7 = (arg_7_0.time or 0) * var_7_2 % 1

		for iter_7_0 = 1, #arg_7_2 do
			local var_7_8 = arg_7_2:sub(iter_7_0, iter_7_0)
			local var_7_9 = render.measure_text(arg_7_1, nil, var_7_8).x
			local var_7_10 = ((var_7_6 > 0 and (var_7_5 - arg_7_3 + var_7_9 * 0.5) / var_7_6 or 0) - var_7_7) % 1

			if var_7_10 > 0.5 then
				var_7_10 = 1 - var_7_10
			end

			local var_7_11 = math.max(0, 1 - var_7_10 / var_7_4)
			local var_7_12 = math.pow(var_7_11, var_7_3)
			local var_7_13 = var_7_0:lerp(var_7_1, var_7_12)

			render.text(arg_7_1, vector(var_7_5 + 1, arg_7_4 + 1), color(0, 0, 0, arg_7_0:a(100 * arg_7_5)), nil, var_7_8)
			render.text(arg_7_1, vector(var_7_5, arg_7_4), color(var_7_13.r, var_7_13.g, var_7_13.b, arg_7_0:a(255 * arg_7_5)), nil, var_7_8)

			var_7_5 = var_7_5 + var_7_9
		end
	end,
	draw_letters = function(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7, arg_8_8, arg_8_9)
		local var_8_0 = arg_8_3

		for iter_8_0 = 1, #arg_8_2 do
			local var_8_1 = arg_8_2:sub(iter_8_0, iter_8_0)
			local var_8_2 = render.measure_text(arg_8_1, nil, var_8_1).x
			local var_8_3 = arg_8_6 + (iter_8_0 - 1) * arg_8_7
			local var_8_4 = 0

			if var_8_3 <= arg_8_5 then
				var_8_4 = arg_8_0:anim(arg_8_5, var_8_3, var_8_3 + arg_8_8) * arg_8_9
			end

			if var_8_4 > 0.001 then
				local var_8_5 = (1 - var_8_4) * 8

				render.text(arg_8_1, vector(var_8_0 + 2, arg_8_4 + 2 + var_8_5), color(0, 0, 0, arg_8_0:a(150 * var_8_4)), nil, var_8_1)
				render.text(arg_8_1, vector(var_8_0, arg_8_4 + var_8_5), color(255, 255, 255, arg_8_0:a(255 * var_8_4)), nil, var_8_1)
			end

			var_8_0 = var_8_0 + var_8_2
		end
	end,
	draw = function(arg_9_0)
		if arg_9_0.done then
			return
		end

		local var_9_0 = globals.frametime or 0.016

		if var_9_0 <= 0 or var_9_0 > 0.1 then
			var_9_0 = 0.016
		end

		arg_9_0.time = (arg_9_0.time or 0) + var_9_0

		local var_9_1 = arg_9_0.time
		local var_9_2 = render.screen_size()

		if var_9_1 > 9.6 then
			arg_9_0.done = true

			return
		end

		local var_9_3 = arg_9_0:anim(var_9_1, 0, 2) * (1 - arg_9_0:anim(var_9_1, 7.6, 9.6))

		render.rect(vector(0, 0), var_9_2, color(0, 0, 0, arg_9_0:a(255 * var_9_3)), 0)

		local var_9_4 = 1 - arg_9_0:anim(var_9_1, 7.6, 9.6)
		local var_9_5 = "WELCOME TO WHITESTRIKE"
		local var_9_6 = render.measure_text(arg_9_0.font_big, nil, var_9_5)
		local var_9_7 = var_9_2.x / 2 - var_9_6.x / 2
		local var_9_8 = var_9_2.y / 2 - 38

		arg_9_0:draw_letters(arg_9_0.font_big, var_9_5, var_9_7, var_9_8, var_9_1, 2.15, 0.11, 0.42, var_9_4)

		local var_9_9 = "STABLE"
		local var_9_10 = render.measure_text(arg_9_0.font_small, nil, var_9_9)
		local var_9_11 = var_9_2.x / 2 - var_9_10.x / 2
		local var_9_12 = var_9_8 + var_9_6.y + 12
		local var_9_13 = arg_9_0:anim(var_9_1, 5.35, 6.25) * var_9_4

		if var_9_13 > 0.001 then
			arg_9_0:draw_flow_text(arg_9_0.font_small, var_9_9, var_9_11, var_9_12, var_9_13)
		end
	end
}
local var_0_4 = {
	aa_lib = require("neverlose/anti_aim"),
	base64 = require("neverlose/base64"),
	pui = require("neverlose/pui"),
	clipboard = require("neverlose/clipboard"),
	bomb = require("neverlose/bomb")
}
local var_0_5 = var_0_2(" whitestrike", -2.2, {
	ui.get_style("Link Active"),
	color(0, 0, 0, 255)
})

local function var_0_6()
	if not var_0_4 or not var_0_4.pui then
		return
	end

	if ui.get_alpha and ui.get_alpha() <= 0.1 then
		return
	end

	if var_0_5 then
		pcall(function()
			var_0_5:set_colors({
				ui.get_style("Link Active"),
				color(0, 0, 0, 255)
			})
			var_0_5:set_speed(-1)
			var_0_5:animate()
			var_0_4.pui.sidebar(var_0_5:get_animated_text(), ui.get_icon("rebel"))
		end)
	else
		pcall(function()
			var_0_4.pui.sidebar(" whitestrike")
		end)
	end
end

ffi.cdef(" \ntypedef struct { \n    char pad_0000[20];\n    int m_nOrder;\n    int m_nSequence; \n    float m_flPrevCycle; \n    float m_flWeight; \n    float m_flWeightDeltaRate; \n    float m_flPlaybackRate; \n    float m_flCycle; \n    void *m_pOwner; \n    char pad_0038[4];\n    } animstate_layer_t;\n")

local var_0_7 = {
	get_entity_address = utils.get_vfunc("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")
}
local var_0_8
local var_0_9 = {
	rage = {
		quickpeek = ui.find("Aimbot", "Ragebot", "Main", "Peek Assist")
	},
	min_damage = {
		global = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Min. Damage"),
		pistols = ui.find("Aimbot", "Ragebot", "Selection", "Pistols", "Min. Damage"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Min. Damage"),
		awpnaxyi = ui.find("Aimbot", "Ragebot", "Selection", "AWP", "Min. Damage"),
		scout = ui.find("Aimbot", "Ragebot", "Selection", "SSG-08", "Min. Damage"),
		deagle = ui.find("Aimbot", "Ragebot", "Selection", "Desert Eagle", "Min. Damage"),
		revik = ui.find("Aimbot", "Ragebot", "Selection", "R8 Revolver", "Min. Damage"),
		taser = ui.find("Aimbot", "Ragebot", "Selection", "Taser", "Min. Damage"),
		prsnipers = ui.find("Aimbot", "Ragebot", "Selection", "Snipers", "Min. Damage"),
		rifles = ui.find("Aimbot", "Ragebot", "Selection", "Rifles", "Min. Damage"),
		smgs = ui.find("Aimbot", "Ragebot", "Selection", "SMGs", "Min. Damage"),
		shotguns = ui.find("Aimbot", "Ragebot", "Selection", "Shotguns", "Min. Damage"),
		machiguns = ui.find("Aimbot", "Ragebot", "Selection", "Machineguns", "Min. Damage"),
		vityaAK47 = ui.find("Aimbot", "Ragebot", "Selection", "AK-47", "Min. Damage"),
		m4ma1 = ui.find("Aimbot", "Ragebot", "Selection", "M4A1/M4A4", "Min. Damage"),
		AUG = ui.find("Aimbot", "Ragebot", "Selection", "AUG/SG 553", "Min. Damage")
	},
	hitchance = {
		global = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Hit Chance"),
		pistols = ui.find("Aimbot", "Ragebot", "Selection", "Pistols", "Hit Chance"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Hit Chance"),
		awp = ui.find("Aimbot", "Ragebot", "Selection", "AWP", "Hit Chance"),
		scout = ui.find("Aimbot", "Ragebot", "Selection", "SSG-08", "Hit Chance"),
		deagle = ui.find("Aimbot", "Ragebot", "Selection", "Desert Eagle", "Hit Chance"),
		revolver = ui.find("Aimbot", "Ragebot", "Selection", "R8 Revolver", "Hit Chance"),
		rifles = ui.find("Aimbot", "Ragebot", "Selection", "Rifles", "Hit Chance"),
		smgs = ui.find("Aimbot", "Ragebot", "Selection", "SMGs", "Hit Chance"),
		shotguns = ui.find("Aimbot", "Ragebot", "Selection", "Shotguns", "Hit Chance"),
		machineguns = ui.find("Aimbot", "Ragebot", "Selection", "Machineguns", "Hit Chance")
	},
	multipoints = {
		global = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Multipoint"),
		pistols = ui.find("Aimbot", "Ragebot", "Selection", "Pistols", "Multipoint"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Multipoint"),
		awpblya = ui.find("Aimbot", "Ragebot", "Selection", "AWP", "Multipoint"),
		scout = ui.find("Aimbot", "Ragebot", "Selection", "SSG-08", "Multipoint"),
		deagle = ui.find("Aimbot", "Ragebot", "Selection", "Desert Eagle", "Multipoint"),
		revik = ui.find("Aimbot", "Ragebot", "Selection", "R8 Revolver", "Multipoint"),
		taser = ui.find("Aimbot", "Ragebot", "Selection", "Taser", "Multipoint"),
		prsnipers = ui.find("Aimbot", "Ragebot", "Selection", "Snipers", "Multipoint"),
		rifles = ui.find("Aimbot", "Ragebot", "Selection", "Rifles", "Multipoint"),
		smgs = ui.find("Aimbot", "Ragebot", "Selection", "SMGs", "Multipoint"),
		shotguns = ui.find("Aimbot", "Ragebot", "Selection", "Shotguns", "Multipoint"),
		machiguns = ui.find("Aimbot", "Ragebot", "Selection", "Machineguns", "Multipoint"),
		vityaAK47 = ui.find("Aimbot", "Ragebot", "Selection", "AK-47", "Multipoint"),
		m4ma1 = ui.find("Aimbot", "Ragebot", "Selection", "M4A1/M4A4", "Multipoint"),
		AUG = ui.find("Aimbot", "Ragebot", "Selection", "AUG/SG 553", "Multipoint")
	},
	hitboxes = {
		global = ui.find("Aimbot", "Ragebot", "Selection", "Global", "Hitboxes"),
		pistols = ui.find("Aimbot", "Ragebot", "Selection", "Pistols", "Hitboxes"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Selection", "AutoSnipers", "Hitboxes"),
		awpblya = ui.find("Aimbot", "Ragebot", "Selection", "AWP", "Hitboxes"),
		scout = ui.find("Aimbot", "Ragebot", "Selection", "SSG-08", "Hitboxes"),
		deagle = ui.find("Aimbot", "Ragebot", "Selection", "Desert Eagle", "Hitboxes"),
		revik = ui.find("Aimbot", "Ragebot", "Selection", "R8 Revolver", "Hitboxes"),
		taser = ui.find("Aimbot", "Ragebot", "Selection", "Taser", "Hitboxes"),
		prsnipers = ui.find("Aimbot", "Ragebot", "Selection", "Snipers", "Hitboxes"),
		rifles = ui.find("Aimbot", "Ragebot", "Selection", "Rifles", "Hitboxes"),
		smgs = ui.find("Aimbot", "Ragebot", "Selection", "SMGs", "Hitboxes"),
		shotguns = ui.find("Aimbot", "Ragebot", "Selection", "Shotguns", "Hitboxes"),
		machiguns = ui.find("Aimbot", "Ragebot", "Selection", "Machineguns", "Hitboxes"),
		vityaAK47 = ui.find("Aimbot", "Ragebot", "Selection", "AK-47", "Hitboxes"),
		m4ma1 = ui.find("Aimbot", "Ragebot", "Selection", "M4A1/M4A4", "Hitboxes"),
		AUG = ui.find("Aimbot", "Ragebot", "Selection", "AUG/SG 553", "Hitboxes")
	},
	body_aim = {
		global = ui.find("Aimbot", "Ragebot", "Safety", "Global", "Body Aim"),
		pistols = ui.find("Aimbot", "Ragebot", "Safety", "Pistols", "Body Aim"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Safety", "AutoSnipers", "Body Aim"),
		awpblya = ui.find("Aimbot", "Ragebot", "Safety", "AWP", "Body Aim"),
		scout = ui.find("Aimbot", "Ragebot", "Safety", "SSG-08", "Body Aim"),
		deagle = ui.find("Aimbot", "Ragebot", "Safety", "Desert Eagle", "Body Aim"),
		revik = ui.find("Aimbot", "Ragebot", "Safety", "R8 Revolver", "Body Aim"),
		taser = ui.find("Aimbot", "Ragebot", "Safety", "Taser", "Body Aim"),
		prsnipers = ui.find("Aimbot", "Ragebot", "Safety", "Snipers", "Body Aim"),
		rifles = ui.find("Aimbot", "Ragebot", "Safety", "Rifles", "Body Aim"),
		smgs = ui.find("Aimbot", "Ragebot", "Safety", "SMGs", "Body Aim"),
		shotguns = ui.find("Aimbot", "Ragebot", "Safety", "Shotguns", "Body Aim"),
		machiguns = ui.find("Aimbot", "Ragebot", "Safety", "Machineguns", "Body Aim"),
		vityaAK47 = ui.find("Aimbot", "Ragebot", "Safety", "AK-47", "Body Aim"),
		m4ma1 = ui.find("Aimbot", "Ragebot", "Safety", "M4A1/M4A4", "Body Aim"),
		AUG = ui.find("Aimbot", "Ragebot", "Safety", "AUG/SG 553", "Body Aim")
	},
	force_safe_point = {
		global = ui.find("Aimbot", "Ragebot", "Safety", "Global", "Safe Points"),
		pistols = ui.find("Aimbot", "Ragebot", "Safety", "Pistols", "Safe Points"),
		autosnipers = ui.find("Aimbot", "Ragebot", "Safety", "AutoSnipers", "Safe Points"),
		awpblya = ui.find("Aimbot", "Ragebot", "Safety", "AWP", "Safe Points"),
		scout = ui.find("Aimbot", "Ragebot", "Safety", "SSG-08", "Safe Points"),
		deagle = ui.find("Aimbot", "Ragebot", "Safety", "Desert Eagle", "Safe Points"),
		revik = ui.find("Aimbot", "Ragebot", "Safety", "R8 Revolver", "Safe Points"),
		taser = ui.find("Aimbot", "Ragebot", "Safety", "Taser", "Safe Points"),
		prsnipers = ui.find("Aimbot", "Ragebot", "Safety", "Snipers", "Safe Points"),
		rifles = ui.find("Aimbot", "Ragebot", "Safety", "Rifles", "Safe Points"),
		smgs = ui.find("Aimbot", "Ragebot", "Safety", "SMGs", "Safe Points"),
		shotguns = ui.find("Aimbot", "Ragebot", "Safety", "Shotguns", "Safe Points"),
		machiguns = ui.find("Aimbot", "Ragebot", "Safety", "Machineguns", "Safe Points"),
		vityaAK47 = ui.find("Aimbot", "Ragebot", "Safety", "AK-47", "Safe Points"),
		m4ma1 = ui.find("Aimbot", "Ragebot", "Safety", "M4A1/M4A4", "Safe Points"),
		AUG = ui.find("Aimbot", "Ragebot", "Safety", "AUG/SG 553", "Safe Points")
	},
	dormant = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),
	hideshots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
	unlock_hidden = ui.find("Miscellaneous", "Main", "Other", "Unlock Hidden Cvars"),
	windows = ui.find("Miscellaneous", "Main", "Other", "Windows"),
	scope_overlay = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay"),
	override_zoom = ui.find("Visuals", "World", "Main", "Override Zoom"),
	force_viewmodel = ui.find("Visuals", "World", "Main", "Override Zoom", "Force Viewmodel"),
	antiaim = {
		aa_enable = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
		aa_pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
		pitch_select = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),
		aa_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
		aa_yaw_base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
		aa_manual = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
		aa_manual2 = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
		aa_yaw_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
		aa_yaw_modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
		aa_backstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
		aa_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
		aa_modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),
		aa_hidden = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),
		aa_bodyyaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
		doubletapfin = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
		fakedick = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
		fakexyetensi = ui.find("Miscellaneous", "Main", "Other", "Fake Latency"),
		aa_slowwalk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
		leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement"),
		body_right = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
		body_left = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
		body_options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
		freestand = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
		freestand_disable_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
		freestand_body = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),
		dt = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
		dt_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
		dt_lag = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),
		hs_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options")
	},
	strafe = ui.find("Miscellaneous", "Main", "Movement", "Air Strafe"),
	strafe_smooth = ui.find("Miscellaneous", "Main", "Movement", "Air Strafe", "Smoothing")
}

local function var_0_10(arg_13_0)
	return "\a{Link Active}" .. ui.get_icon(arg_13_0) .. "\aDEFAULT"
end

local function var_0_11(arg_14_0)
	return ui.get_icon(arg_14_0)
end

local function var_0_12(arg_15_0)
	return "» " .. var_0_10(arg_15_0)
end

local var_0_13 = {
	z1 = {
		name = "Default",
		icon = "chess-rook"
	},
	z2 = {
		name = "Defensive",
		icon = "fort-awesome"
	},
	z3 = {
		name = "Terrorist",
		icon = "skull-crossbones"
	},
	z4 = {
		name = "Counter Terrorist",
		icon = "tower-observation"
	}
}
local var_0_14 = {
	z1 = {},
	z2 = {},
	z3 = {},
	z4 = {}
}

local function var_0_15(arg_16_0)
	var_0_14.z1 = {}
	var_0_14.z2 = {}

	local var_16_0 = {
		var_0_13.z1,
		var_0_13.z2
	}

	for iter_16_0, iter_16_1 in ipairs(var_16_0) do
		local var_16_1

		if arg_16_0 ~= nil and (arg_16_0 == iter_16_0 or arg_16_0 == iter_16_1.name) then
			var_16_1 = var_0_12(iter_16_1.icon) .. " " .. iter_16_1.name
		else
			var_16_1 = var_0_11(iter_16_1.icon) .. " " .. iter_16_1.name
		end

		var_0_14.z1[iter_16_0] = var_16_1
		var_0_14.z2[var_16_1] = iter_16_1.name
	end

	return var_0_14.z1
end

local function var_0_16(arg_17_0)
	var_0_14.z3 = {}
	var_0_14.z4 = {}

	local var_17_0 = {
		var_0_13.z3,
		var_0_13.z4
	}

	for iter_17_0, iter_17_1 in ipairs(var_17_0) do
		local var_17_1

		if arg_17_0 ~= nil and (arg_17_0 == iter_17_0 or arg_17_0 == iter_17_1.name) then
			var_17_1 = var_0_12(iter_17_1.icon) .. " " .. iter_17_1.name
		else
			var_17_1 = var_0_11(iter_17_1.icon) .. " " .. iter_17_1.name
		end

		var_0_14.z3[iter_17_0] = var_17_1
		var_0_14.z4[var_17_1] = iter_17_1.name
	end

	return var_0_14.z3
end

local var_0_17 = {
	cond = {
		"Shared",
		"Standing",
		"Moving",
		"Air",
		"Air Crouching",
		"Crouching",
		"Crouching Moving",
		"Slow Walking",
		"Freestanding",
		"Manual Yaw"
	},
	runtime = {
		ground = true,
		duck = 0,
		speed = 0,
		current = 1
	}
}
local var_0_18 = {
	Freestanding = "arrows-turn-to-dots",
	["Manual Yaw"] = "right-left",
	["Slow Walking"] = "shoe-prints",
	["Crouching Moving"] = "person-walking",
	Crouching = "person-praying",
	["Air Crouching"] = "plane-up",
	Air = "wind",
	Moving = "person-running",
	Standing = "person",
	Shared = "globe"
}
local var_0_19 = {}
local var_0_20 = {}

for iter_0_0, iter_0_1 in ipairs(var_0_17.cond) do
	local var_0_21 = var_0_10(var_0_18[iter_0_1] or "circle") .. " " .. iter_0_1

	var_0_19[iter_0_0] = var_0_21
	var_0_20[var_0_21] = iter_0_1
end

local var_0_22 = {
	main = {
		information = var_0_4.pui.create(ui.get_icon("house-night"), "##Information", 1),
		presets = var_0_4.pui.create(ui.get_icon("house-night"), "##Presets", 2)
	},
	antiaim = {
		builder_left = var_0_4.pui.create(ui.get_icon("shield"), "##builder", 1),
		yaw_base = var_0_4.pui.create(ui.get_icon("shield"), "##yawbase", 1),
		yaw = var_0_4.pui.create(ui.get_icon("shield"), "##yaw", 1),
		z = var_0_4.pui.create(ui.get_icon("shield"), "##z", 1),
		a = var_0_4.pui.create(ui.get_icon("shield"), "##a", 1),
		b = var_0_4.pui.create(ui.get_icon("shield"), "##ab", 1),
		v = var_0_4.pui.create(ui.get_icon("shield"), "##add", 1),
		d = var_0_4.pui.create(ui.get_icon("shield"), "##asd", 1),
		dd = var_0_4.pui.create(ui.get_icon("shield"), "##adsf", 1),
		ddd = var_0_4.pui.create(ui.get_icon("shield"), "##abcvb", 1),
		dddd = var_0_4.pui.create(ui.get_icon("shield"), "##avvvv", 1),
		ddddd = var_0_4.pui.create(ui.get_icon("shield"), "##aaaa", 1),
		dddddd = var_0_4.pui.create(ui.get_icon("shield"), "##aqqqq", 1),
		builder_right = var_0_4.pui.create(ui.get_icon("shield"), "##builder_left", 2),
		fdb = var_0_4.pui.create(ui.get_icon("shield"), "##ff", 2),
		builder_right2 = var_0_4.pui.create(ui.get_icon("shield"), "##builder_right", 2),
		builder_right3 = var_0_4.pui.create(ui.get_icon("shield"), "##bui", 2)
	},
	other = {
		selection = var_0_4.pui.create(ui.get_icon("cloud"), "##sel", 1),
		v1 = var_0_4.pui.create(ui.get_icon("cloud"), "##z1", 1),
		v2 = var_0_4.pui.create(ui.get_icon("cloud"), "##z2", 2),
		v3 = var_0_4.pui.create(ui.get_icon("cloud"), "##z3", 1),
		v4 = var_0_4.pui.create(ui.get_icon("cloud"), "##z4", 2),
		misc = var_0_4.pui.create(ui.get_icon("cloud"), "##m3", 2),
		misc2 = var_0_4.pui.create(ui.get_icon("cloud"), "##m22", 1),
		misc3 = var_0_4.pui.create(ui.get_icon("cloud"), "##m32", 2),
		misc4 = var_0_4.pui.create(ui.get_icon("cloud"), "##m42", 1)
	}
}

local function var_0_23(arg_18_0)
	if arg_18_0 and arg_18_0 ~= "" then
		panorama.SteamOverlayAPI.OpenExternalBrowserURL(arg_18_0)
	end
end

local var_0_24 = {
	main = {
		information = {
            welcome = var_0_22.main.information:label(var_0_10("user") .. " Welcome back, gpt 6.7"),
			update = var_0_22.main.information:label(var_0_10("clock") .. " Last update"),
			update_date = var_0_22.main.information:button(" 16.06.26 ", function()
				return
			end, true),
			build = var_0_22.main.information:label(var_0_10("code-branch") .. " Current build"),
			build_name = var_0_22.main.information:button(" Default ", function()
				return
			end, true),
			socials = var_0_22.main.information:label(var_0_10("link") .. " Social"),
			youtube = var_0_22.main.information:button("\aFF0000FF" .. ui.get_icon("youtube") .. "\aDEFAULT", function()
				var_0_23("https://www.youtube.com/")
			end, true),
			discord = var_0_22.main.information:button("\a5865F2FF" .. ui.get_icon("discord") .. "\aDEFAULT", function()
				var_0_23("https://discord.gg/AsYaXKWg4U")
			end, true),
			config = var_0_22.main.information:button("\a00BFFFFF" .. ui.get_icon("folder-open") .. "\aDEFAULT", function()
				var_0_23("https://neverlose.cc/market")
			end, true)
		},
		configs = {
			list = var_0_22.main.presets:list(var_0_10("folder-open") .. " Configs", {}),
			name = var_0_22.main.presets:input(var_0_10("file-pen") .. " Name"),
			create = var_0_22.main.presets:button(var_0_10("plus"), function()
				return
			end, true),
			save = var_0_22.main.presets:button(var_0_10("floppy-disk"), function()
				return
			end, true),
			load = var_0_22.main.presets:button(var_0_10("upload"), function()
				return
			end, true),
			remove = var_0_22.main.presets:button(var_0_10("trash"), function()
				return
			end, true),
			import = var_0_22.main.presets:button(var_0_10("file-import"), function()
				return
			end, true),
			export = var_0_22.main.presets:button(var_0_10("file-export"), function()
				return
			end, true)
		}
	},
	antiaim = {
		left = {
			builder = var_0_22.antiaim.builder_left:list(var_0_10("street-view") .. " Builder", var_0_15()),
			current = var_0_22.antiaim.builder_left:combo(var_0_10("leaf") .. " Current State", var_0_19),
			override = {},
			aa = {
				yawbase = var_0_22.antiaim.yaw_base:combo(var_0_10("spinner") .. " Yaw Base", {
					"Local View",
					"At Target"
				}),
				yawjitter = {
					lr = {
						yawbuilder = var_0_22.antiaim.yaw:label(var_0_10("mars") .. " Yaw", true, nil, function(arg_30_0)
							return {
								yaw_left = arg_30_0:slider(var_0_10("arrow-left") .. " Yaw Left", -180, 180, 0, "°"),
								yaw_right = arg_30_0:slider(var_0_10("arrow-right") .. " Yaw Right", -180, 180, 0, "°")
							}
						end),
						yaw_modifier = var_0_22.antiaim.yaw:label(var_0_10("sparkles") .. " Yaw Jitter", true, nil, function(arg_31_0)
							local var_31_0 = {
								modifier = arg_31_0:combo(var_0_10("shuffle") .. " Modifier", {
									"Disabled",
									"Center",
									"Offset",
									"Random",
									"Spin",
									"3-Way",
									"5-Way",
									"Custom Way",
									"LC"
								}),
								mode = arg_31_0:combo(var_0_10("sliders") .. " Mode", {
									"Default",
									"Custom"
								}),
								degree = arg_31_0:slider(var_0_10("arrows-left-right") .. " Degree", -180, 180, 0, 1, "°"),
								randomize = arg_31_0:slider(var_0_10("dice") .. " Randomize", 0, 100, 0, 1, "%"),
								lc_min = arg_31_0:slider(var_0_10("minus") .. " LC Min", -180, 180, 0, 1, "°"),
								lc_max = arg_31_0:slider(var_0_10("plus") .. " LC Max", -180, 180, 0, 1, "°"),
								spin_seed = arg_31_0:slider(var_0_10("rotate") .. " Spin Speed", 1, 30, 10),
								custom_count = arg_31_0:slider(var_0_10("list") .. " Ways", 1, 6, 3),
								custom = {}
							}

							for iter_31_0 = 1, 6 do
								var_31_0.custom[iter_31_0] = arg_31_0:slider(var_0_10("arrow-right") .. " Way " .. iter_31_0, -180, 180, 0, 1, "°")
							end

							var_31_0.custom_way = arg_31_0:slider(var_0_10("route") .. " Way Mode", 1, 5, 3, 1, function(arg_32_0)
								return arg_32_0 .. "-Way"
							end)

							return var_31_0
						end),
						yaw_delay = var_0_22.antiaim.yaw:label(var_0_10("clock") .. " Yaw Delay", true, nil, function(arg_33_0)
							local var_33_0 = {
								enable = arg_33_0:switch(var_0_10("toggle-on") .. " Switch Delay", false),
								activation = arg_33_0:combo(var_0_10("bolt") .. " Activation Type", {
									"Stable",
									"Aggressive"
								}),
								mode = arg_33_0:combo(var_0_10("bars-staggered") .. " Delay Mode", {
									"Default",
									"Custom",
									"Random"
								}),
								hold = arg_33_0:slider(var_0_10("hourglass-half") .. " Hold Tick", 1, 23, 1, 1, function(arg_34_0)
									return arg_34_0 .. "t"
								end),
								randomize = arg_33_0:slider(var_0_10("dice") .. " Randomize", 0, 100, 0, 1, function(arg_35_0)
									return arg_35_0 .. "%"
								end),
								from = arg_33_0:slider(var_0_10("arrow-down") .. " From", 1, 23, 1, 1, function(arg_36_0)
									return arg_36_0 .. "t"
								end),
								to = arg_33_0:slider(var_0_10("arrow-up") .. " To", 1, 23, 1, 1, function(arg_37_0)
									return arg_37_0 .. "t"
								end),
								count = arg_33_0:slider(var_0_10("list-ol") .. " Sliders", 1, 6, 1, 1),
								values = {}
							}

							for iter_33_0 = 1, 6 do
								var_33_0.values[iter_33_0] = arg_33_0:slider(var_0_10("timer") .. " Hold " .. iter_33_0, 1, 23, 1, 1, function(arg_38_0)
									return arg_38_0 .. "t"
								end)
							end

							return var_33_0
						end),
						desync = var_0_22.antiaim.yaw:label(var_0_10("shield-halved") .. " Desync", true, nil, function(arg_39_0)
							return {
								mode = arg_39_0:combo(var_0_10("wave-square") .. " Desync", {
									"Off",
									"Default",
									"Jitter",
									"Random",
									"Delay",
									"Whitestrike"
								}),
								delay = arg_39_0:slider(var_0_10("clock-rotate-left") .. " Delay", 1, 23, 12, 1, function(arg_40_0)
									return arg_40_0 .. "t"
								end),
								limit_mode = arg_39_0:combo(var_0_10("sliders") .. " Desync Mode", {
									"Default",
									"From / To",
									"Random"
								}),
								left = arg_39_0:slider(var_0_10("arrow-left") .. " Left", 0, 60, 32, 1, "°"),
								right = arg_39_0:slider(var_0_10("arrow-right") .. " Right", 0, 60, 32, 1, "°"),
								from = arg_39_0:slider(var_0_10("angles-left") .. " From", 0, 60, 32, 1, "°"),
								to = arg_39_0:slider(var_0_10("angles-right") .. " To", 0, 60, 60, 1, "°"),
								speed = arg_39_0:slider(var_0_10("gauge-high") .. " Speed", 0, 12, 5, 1, function(arg_41_0)
									return arg_41_0 .. "t"
								end)
							}
						end)
					}
				},
				extension = {
					break_lc = var_0_22.antiaim.z:label(var_0_10("triangle-exclamation") .. " Break LC", true, nil, function(arg_42_0)
						return {
							mode = arg_42_0:selectable(var_0_10("bolt") .. " Activation", "Weapon switch", "Weapon reload", "Always"),
							disable_qp = arg_42_0:switch(var_0_10("ban") .. " Dont override LC on Quickpeek", false)
						}
					end),
					options = var_0_22.antiaim.z:label(var_0_10("fire") .. " Options", true, nil, function(arg_43_0)
						return {
							selection = arg_43_0:selectable(var_0_10("list-check") .. " List", "Warmup AA", "Round end AA"),
							mode = arg_43_0:combo(var_0_10("rotate") .. " Mode", {
								"Full",
								"Half"
							}),
							speed = arg_43_0:slider(var_0_10("gauge-high") .. " Spin Speed", 1, 10, 4, 1, function(arg_44_0)
								return arg_44_0 .. "t"
							end)
						}
					end),
					tickbase = var_0_22.antiaim.z:label(var_0_10("globe") .. " Tickbase", true, nil, function(arg_45_0)
						return {
							mode = arg_45_0:combo(var_0_10("shield-check") .. " Mode", {
								"Default",
								"Custom"
							}),
							random = arg_45_0:switch(var_0_10("shuffle") .. " Random Choke", false),
							choke = arg_45_0:slider(var_0_10("gauge") .. " Choke", 1, 22, 16, 1, function(arg_46_0)
								return arg_46_0 == 16 and "Default" or tostring(arg_46_0)
							end),
							choke2 = arg_45_0:slider(var_0_10("gauge-high") .. " Choke 2nd", 1, 22, 16, 1, function(arg_47_0)
								return arg_47_0 == 16 and "Default" or tostring(arg_47_0)
							end),
							info = arg_45_0:label(var_0_10("circle-info") .. " Default choke value is 16.")
						}
					end)
				},
				defensive = {
					enable = var_0_22.antiaim.a:switch(var_0_10("shield-halved") .. " Enable Defensive", false),
					pitch = var_0_22.antiaim.b:combo(var_0_10("angles-up") .. " Defensive Pitch", {
						"Disabled",
						"Down",
						"Up",
						"Random",
						"Custom"
					}),
					pitch_first = var_0_22.antiaim.b:slider(var_0_10("arrow-down") .. " From", -89, 89, 0, 1, "°"),
					pitch_second = var_0_22.antiaim.b:slider(var_0_10("arrow-up") .. " To", -89, 89, 0, 1, "°"),
					pitch_custom = var_0_22.antiaim.b:slider(var_0_10("sliders") .. " Custom Pitch", -89, 89, 0, 1, "°"),
					modifier = var_0_22.antiaim.dd:combo(var_0_10("angle-90") .. " Defensive Modifier", {
						"Disabled",
						"Center",
						"Offset",
						"Random",
						"3-Way",
						"5-Way"
					}),
					modifier_mode = var_0_22.antiaim.dd:combo(var_0_10("rectangles-mixed") .. " Modifier Mode", {
						"Randomize",
						"Min - Max"
					}),
					modifier_offset = var_0_22.antiaim.dd:slider(var_0_10("slider") .. " Modifier Offset", -180, 180, 0, 1, "°"),
					modifier_randomize = var_0_22.antiaim.dd:slider(var_0_10("dice") .. " Randomize", 0, 100, 0, 1, "%"),
					modifier_min = var_0_22.antiaim.dd:slider(var_0_10("angle-right") .. " Min", -180, 180, 0, 1, "°"),
					modifier_max = var_0_22.antiaim.dd:slider(var_0_10("angle-left") .. " Max", -180, 180, 0, 1, "°"),
					yaw = var_0_22.antiaim.dddd:combo(var_0_10("arrows-left-right") .. " Defensive Yaw", {
						"Disabled",
						"Random",
						"Spin",
						"Custom"
					}),
					yaw_first = var_0_22.antiaim.dddd:slider(var_0_10("arrow-down-wide-short") .. " From", -180, 180, 0, 1, "°"),
					yaw_second = var_0_22.antiaim.dddd:slider(var_0_10("arrow-up-wide-short") .. " To", -180, 180, 0, 1, "°"),
					yaw_speed = var_0_22.antiaim.dddd:slider(var_0_10("rotate") .. " Spin Speed", 1, 30, 1, 1),
					yaw_custom = var_0_22.antiaim.dddd:slider(var_0_10("sliders") .. " Custom Yaw", -180, 180, 0, 1, "°")
				}
			}
		},
		right = {
			team = var_0_22.antiaim.builder_right:list(var_0_10("people-group") .. " Team Side", var_0_16()),
			send_t = var_0_22.antiaim.builder_right:button(var_0_10("arrow-left") .. " Send To T", function()
				return
			end, true),
			send_ct = var_0_22.antiaim.builder_right:button(var_0_10("arrow-right") .. " Send To CT", function()
				return
			end, true),
			reset = var_0_22.antiaim.builder_right:button("      \aFF0000FFReset      ", function()
				return
			end, true)
		},
		fr_d = {
			force_defensive = var_0_22.antiaim.fdb:label(var_0_10("helmet-safety") .. " Force Defensive", true, nil, function(arg_51_0)
				return {
					enable = arg_51_0:switch(var_0_10("power-off") .. " Enable", false),
					mode = arg_51_0:combo(var_0_10("bolt-lightning") .. " Mode", {
						"Always",
						"On Double Tap",
						"On Peek",
						"On Conditions"
					}),
					conditions = arg_51_0:selectable(var_0_10("layer-group") .. " Conditions", "Standing", "Moving", "Air", "Air Crouching", "Crouching", "Crouching Moving", "Slow Walking", "Freestanding", "Manual Yaw"),
					disablers = arg_51_0:selectable(var_0_10("shield-xmark") .. " Disablers", "Fake Duck", "Warmup AA", "Round End AA", "No Enemy")
				}
			end)
		},
		help = {
			manual_yaw = var_0_22.antiaim.builder_right2:combo(var_0_10("arrows-repeat") .. " Manual Yaw", {
				"Disabled",
				"Left",
				"Right",
				"Forward"
			}, function(arg_52_0)
				return {
					manual_over_fs = arg_52_0:switch(var_0_10("arrow-up") .. " Manual Over FS", false)
				}
			end),
			freestanding = var_0_22.antiaim.builder_right2:switch(var_0_10("arrows-turn-to-dots") .. " Freestanding", false, function(arg_53_0)
				return {
					conditions = arg_53_0:selectable(var_0_10("layer-group") .. "Ignore Cond", "Standing", "Moving", "Air", "Air Crouching", "Crouching", "Crouching Moving", "Slow Walking", "Manual Yaw"),
					disable_yaw_modifiers = arg_53_0:switch(var_0_10("ban") .. " Disable Yaw Modifiers", false),
					body_freestanding = arg_53_0:switch(var_0_10("person-rays") .. " Body Freestanding", false)
				}
			end)
		},
		adder = {
			edge_yaw = var_0_22.antiaim.builder_right3:switch(var_0_10("compass-drafting") .. " Edge Yaw", false, function(arg_54_0)
				return {
					ignore_manuals = arg_54_0:switch(var_0_10("hand") .. " Ignore Manuals", false)
				}
			end),
			avoid_backstab = var_0_22.antiaim.builder_right3:switch(var_0_10("knife-kitchen") .. " Avoid Backstab", false),
			safe_head = var_0_22.antiaim.builder_right3:switch(var_0_10("helmet-safety") .. " Safe Head", false, function(arg_55_0)
				return {
					triggers = arg_55_0:selectable(var_0_10("crosshairs") .. " Triggers", "Knife", "Taser", "Above Enemy"),
					height_difference = arg_55_0:slider(var_0_10("arrow-up-from-ground-water") .. " Height Difference", 30, 180, 80, 1)
				}
			end)
		}
	},
	other = {
		tab = var_0_22.other.selection:list(var_0_10("table-list") .. " Other Tab", {
			var_0_10("images") .. " Visual",
			var_0_10("screwdriver-wrench") .. " Misc"
		}),
		visual = {
			money_indicators = var_0_22.other.v2:switch("\a00FF00FF$500\aDEFAULT Indicators", false, function(arg_56_0)
				return {
					mode = arg_56_0:combo(var_0_10("layer-group") .. " Mode", {
						"Default",
						"Custom"
					}),
					select = arg_56_0:selectable(var_0_10("list") .. " Indicators", "Hit/Miss Rate", "Double Tap", "Hide Shots", "Fake Latency", "Min. Damage Override", "Body Aim", "Force Safe Point", "Freestanding", "Dormant Aimbot", "Bomb Information"),
					animated = arg_56_0:switch(var_0_10("sparkles") .. " Animated", true),
					custom_style = arg_56_0:combo(var_0_10("palette") .. " Custom Style", {
						"Dark",
						"White"
					}),
					accent = arg_56_0:color_picker(var_0_10("droplet") .. " Accent Color", color(160, 200, 255, 255)),
					y_offset = arg_56_0:slider(var_0_10("arrows-up-down") .. " Y Offset", -350, 350, 0, 1, function(arg_57_0)
						return arg_57_0 .. "px"
					end)
				}
			end),
			center_indicators = var_0_22.other.v1:switch(var_0_10("star") .. " Centered Indicators", false, function(arg_58_0)
				return {
					mode = arg_58_0:combo(var_0_10("wand-magic-sparkles") .. " Mode", {
						"Default",
						"Gradient Master"
					}),
					show_extra = arg_58_0:switch(var_0_10("list") .. " Show Extra Indicators", true),
					glow = arg_58_0:switch(var_0_10("sparkles") .. " Glow", false),
					glow_color = arg_58_0:color_picker(var_0_10("lightbulb") .. " Glow Color", color(160, 200, 255, 120)),
					y_offset = arg_58_0:slider(var_0_10("arrows-up-down") .. " Y Offset", -200, 200, 34, 1, function(arg_59_0)
						return arg_59_0 .. "px"
					end),
					main_font = arg_58_0:combo(var_0_10("font") .. " Main Font", {
						"Default",
						"Verdana",
						"Verdana Bold",
						"Calibri Bold",
						"Pixel",
						"Pixel Bold",
						"Pixel Outline",
						"Pixel Shadow"
					}),
					ind_font = arg_58_0:combo(var_0_10("font") .. " Indicators Font", {
						"Default",
						"Verdana",
						"Verdana Bold",
						"Calibri Bold",
						"Pixel",
						"Pixel Bold",
						"Pixel Outline",
						"Pixel Shadow"
					}),
					default_main = arg_58_0:color_picker(var_0_10("palette") .. " Main Color", color(255, 255, 255, 255)),
					default_second = arg_58_0:color_picker(var_0_10("droplet") .. " Flow Color", color(160, 200, 255, 255)),
					speed = arg_58_0:slider(var_0_10("gauge-high") .. " Flow Speed", 1, 30, 12, 1),
					master_count = arg_58_0:slider(var_0_10("layer-group") .. " Gradients", 1, 5, 3, 1),
					g1 = arg_58_0:color_picker(var_0_10("circle-1") .. " Gradient 1", color(255, 255, 255, 255)),
					g2 = arg_58_0:color_picker(var_0_10("circle-2") .. " Gradient 2", color(160, 200, 255, 255)),
					g3 = arg_58_0:color_picker(var_0_10("circle-3") .. " Gradient 3", color(255, 120, 200, 255)),
					g4 = arg_58_0:color_picker(var_0_10("circle-4") .. " Gradient 4", color(120, 255, 180, 255)),
					g5 = arg_58_0:color_picker(var_0_10("circle-5") .. " Gradient 5", color(255, 220, 120, 255))
				}
			end),
			windows = var_0_22.other.v1:switch(var_0_10("window") .. " Windows", false, function(arg_60_0)
				return {
					items = arg_60_0:selectable(var_0_10("list") .. " Items", "Keybinds", "Watermark", "Velocity Indicators", "Spectators"),
					bg_style = arg_60_0:combo(var_0_10("palette") .. " Background Style", {
						"Dark",
						"White"
					}),
					text_color = arg_60_0:color_picker(var_0_10("font") .. " Text Color", color(235, 235, 235, 235)),
					glow_color = arg_60_0:color_picker(var_0_10("lightbulb") .. " Glow Color", color(0, 220, 255, 255)),
					watermark_items = arg_60_0:selectable(var_0_10("bars") .. " Watermark Elements", "Nickname", "Ping", "Session Time"),
					nickname_source = arg_60_0:combo(var_0_10("user") .. " Nickname Source", {
						"Neverlose",
						"Steam"
					}),
					wm_speed = arg_60_0:slider(var_0_10("gauge-high") .. " Watermark Speed", 1, 30, 8, 1),
					distance = arg_60_0:slider(var_0_10("arrows-left-right") .. " Elements distance", 0, 40, 5, 1, function(arg_61_0)
						return arg_61_0 .. "px"
					end)
				}
			end),
			damage_indicator = var_0_22.other.v1:switch(var_0_10("bullseye-arrow") .. " Damage Indicator", false, function(arg_62_0)
				return {
					mode = arg_62_0:combo(var_0_10("layer-group") .. " Mode", {
						"Default",
						"Double"
					}),
					double_distance = arg_62_0:slider(var_0_10("arrows-left-right") .. " Double Distance", 20, 160, 54, 1, function(arg_63_0)
						return arg_63_0 .. "px"
					end),
					only_override = arg_62_0:switch(var_0_10("bolt") .. " Only Override", false),
					font = arg_62_0:combo(var_0_10("font") .. " Font", {
						"Default",
						"Pixel",
						"Bold"
					}),
					color = arg_62_0:color_picker(var_0_10("palette") .. " Color", color(255, 255, 255, 255)),
					override_color = arg_62_0:color_picker(var_0_10("droplet") .. " Override Color", color(0, 220, 255, 255))
				}
			end),
			scope_paint = var_0_22.other.v1:switch(var_0_10("crosshairs-simple") .. " Scope Overlay", false, function(arg_64_0)
				return {
					scope_type = arg_64_0:combo(var_0_10("diagram-project") .. " Style", {
						"Default",
						"T",
						"X"
					}),
					scope_mode = arg_64_0:combo(var_0_10("circle-half-stroke") .. " Mode", {
						"Default",
						"Inverted"
					}),
					scope_flags = arg_64_0:selectable(var_0_10("sliders-up") .. " Settings", "Spread Based", "Glow", "Animated Zoom"),
					scope_length = arg_64_0:slider(var_0_10("ruler-horizontal") .. " Size", 0, 300, 100),
					scope_offset = arg_64_0:slider(var_0_10("arrows-left-right-to-line") .. " Gap", 0, 300, 5),
					scope_main = arg_64_0:color_picker(var_0_10("palette") .. " Color", color(255, 255, 255, 255)),
					scope_second = arg_64_0:color_picker(var_0_10("droplet") .. " Second Color", color(255, 255, 255, 0))
				}
			end),
			aspect_ratio = var_0_22.other.v2:label(var_0_10("display") .. " Aspect Ratio", false, function(arg_65_0)
				local var_65_0 = {
					asp_value = arg_65_0:slider(var_0_10("ruler") .. " Value", 0, 300, 177, 1, function(arg_66_0)
						return arg_66_0 == 0 and "Default" or tostring(arg_66_0 / 100)
					end)
				}

				var_65_0.default = arg_65_0:button("      " .. ui.get_icon("rotate-left") .. " Default      ", function()
					var_65_0.asp_value:set(0)
				end, true)
				var_65_0.b32 = arg_65_0:button("      3:2      ", function()
					var_65_0.asp_value:set(150)
				end, true)
				var_65_0.b43 = arg_65_0:button("      4:3      ", function()
					var_65_0.asp_value:set(133)
				end, true)
				var_65_0.b54 = arg_65_0:button("      5:4      ", function()
					var_65_0.asp_value:set(125)
				end, true)
				var_65_0.b169 = arg_65_0:button("      16:9      ", function()
					var_65_0.asp_value:set(177)
				end, true)
				var_65_0.b1610 = arg_65_0:button("      16:10      ", function()
					var_65_0.asp_value:set(160)
				end, true)

				return var_65_0
			end),
			disable_sleeves = var_0_22.other.v2:switch(var_0_10("layer-group") .. " Disable Sleeves", false),
			lagcomp_box = var_0_22.other.v2:switch(var_0_10("box") .. " LagComp Box", false, function(arg_73_0)
				return {
					color = arg_73_0:color_picker(var_0_10("palette") .. " Color", color(64, 139, 237, 200)),
					defensive_color = arg_73_0:color_picker(var_0_10("triangle-exclamation") .. " Defensive Color", color(255, 40, 0, 200)),
					text = arg_73_0:switch(var_0_10("font") .. " Text", true)
				}
			end),
			hitmarker = var_0_22.other.v2:switch(var_0_10("sparkles") .. " Hitmarker", false, function(arg_74_0)
				return {
					marker_select = arg_74_0:selectable(var_0_10("layer-group") .. " Markers", "Center", "Kibit"),
					center_color = arg_74_0:color_picker(var_0_10("bolt") .. " Center Color", color(255, 255, 255, 255)),
					kibit_color = arg_74_0:color_picker(var_0_10("circle-o") .. " Kibit Color", color(88, 255, 209, 255))
				}
			end),
			crosshair_style = var_0_22.other.v2:switch(var_0_10("crosshairs-simple") .. " Crosshair Style", false, function(arg_75_0)
				return {
					style = arg_75_0:slider(var_0_10("sliders") .. " Style", 100, 102, 100, 1, function(arg_76_0)
						if arg_76_0 == 100 then
							return "Default"
						elseif arg_76_0 == 101 then
							return "Bit"
						elseif arg_76_0 == 102 then
							return "Good"
						end

						return tostring(arg_76_0)
					end)
				}
			end)
		},
		misc = {
			fakeduck_modifiers = var_0_22.other.misc2:label(var_0_10("duck") .. " Fakeduck Modifiers", false, function(arg_77_0)
				return {
					freezetime_fakeduck = arg_77_0:switch(var_0_10("snowflake") .. " Freezetime Fakeduck", false),
					unlock_fakeduck_speed = arg_77_0:switch(var_0_10("gauge-high") .. " Unlock Fakeduck Speed", false)
				}
			end),
			no_fall_damage = var_0_22.other.misc2:switch(var_0_10("person-falling") .. " No Fall Damage", false),
			fast_ladder = var_0_22.other.misc2:switch(var_0_10("water-ladder") .. " Fast Ladder", false),
			super_toss = var_0_22.other.misc2:switch(var_0_10("paper-plane") .. " Super Toss", false),
			edge_stop = var_0_22.other.misc2:switch(var_0_10("person-to-door") .. " Edge Stop", false),
			keep_model_transparency = var_0_22.other.misc:switch(var_0_10("ghost") .. " Keep Model Transparency", false),
			fake_latency = var_0_22.other.misc:switch(var_0_10("signal-stream") .. " Fake Latency", false, function(arg_78_0)
				return {
					amount = arg_78_0:slider(var_0_10("gauge-high") .. " Amount", 0, 200, 0, 1, function(arg_79_0)
						return arg_79_0 .. "ms"
					end)
				}
			end),
			client_anim = var_0_22.other.misc:switch(var_0_10("person-running") .. " Client Animations", false, function(arg_80_0)
				return {
					ground_legs = arg_80_0:combo(var_0_10("shoe-prints") .. " Ground Legs", {
						"Disabled",
						"Reversed",
						"Jitter",
						"Moonwalk"
					}),
					air_legs = arg_80_0:combo(var_0_10("wind") .. " Air Legs", {
						"Disabled",
						"Static",
						"Jitter",
						"Moonwalk"
					}),
					addons = arg_80_0:selectable(var_0_10("layer-group") .. " Addons", "Move Lean", "Earthquake", "Pitch Zero On Land"),
					move_lean_amount = arg_80_0:slider(var_0_10("person-walking-arrow-right") .. " Move Lean Amount", 0, 100, 0, 1, "%")
				}
			end),
			auto_clear = var_0_22.other.misc:switch(var_0_10("broom") .. " Auto Clear", false, function(arg_81_0)
				return {
					when = arg_81_0:selectable(var_0_10("clock") .. " When", "Match End", "Round Start")
				}
			end),
			print_events = var_0_22.other.misc:switch(var_0_10("receipt") .. " Aimbot Logs", false, function(arg_82_0)
				return {
					events = arg_82_0:selectable(var_0_10("list") .. " Events", "Shots", "Purchases", "Kill"),
					output = arg_82_0:selectable(var_0_10("display") .. " Output", "Console", "Screen", "Center"),
					style = arg_82_0:combo(var_0_10("palette") .. " Style", {
						"Dark",
						"White"
					}),
					text_color = arg_82_0:color_picker(var_0_10("font") .. " Text Color", color(255, 255, 255, 255)),
					glow_hit = arg_82_0:color_picker(var_0_10("circle-check") .. " Hit Color", color(160, 200, 255, 255)),
					glow_miss = arg_82_0:color_picker(var_0_10("circle-xmark") .. " Miss Color", color(255, 95, 95, 255))
				}
			end),
			viewmodel_changer = var_0_22.other.misc:label(var_0_10("hand-holding") .. " Viewmodel Changer", false, function(arg_83_0)
				local var_83_0 = {
					fov = arg_83_0:slider(var_0_10("eye") .. " FOV", -10000, 10000, 6800, 0.01),
					x = arg_83_0:slider(var_0_10("arrows-left-right") .. " X", -1000, 1000, 250, 0.01),
					y = arg_83_0:slider(var_0_10("arrows-up-down") .. " Y", -2000, 2000, 0, 0.01),
					z = arg_83_0:slider(var_0_10("up-down-left-right") .. " Z", -1000, 1000, -150, 0.01),
					options = arg_83_0:selectable(var_0_10("sliders-up") .. " Settings", "Left knife", "Viewmodel in scope")
				}

				var_83_0.reset = arg_83_0:button("      \aFF0000FF" .. ui.get_icon("rotate-left") .. " Reset      ", function()
					var_83_0.fov:set(6800)
					var_83_0.x:set(250)
					var_83_0.y:set(0)
					var_83_0.z:set(-150)
				end, true)

				return var_83_0
			end),
			clan_tag = var_0_22.other.misc3:switch(var_0_10("window-restore") .. " Clan Tag", false),
			trash_talk = var_0_22.other.misc3:switch(var_0_10("comments") .. " Trash Talk", false, function(arg_85_0)
				return {
					language = arg_85_0:combo(var_0_10("language") .. " Language", {
						"Russian",
						"English",
						"Combo"
					}),
					triggers = arg_85_0:selectable(var_0_10("bolt") .. " Triggers", "On Kill", "On Death"),
					delay = arg_85_0:slider(var_0_10("clock") .. " Delay", 1, 30, 8, 1, function(arg_86_0)
						return string.format("%.1fs", arg_86_0 / 10)
					end)
				}
			end)
		}
	}
}

pcall(function()
	var_0_24.main.configs.create:tooltip("Create a new local config")
end)
pcall(function()
	var_0_24.main.configs.save:tooltip("Save current settings to selected config")
end)
pcall(function()
	var_0_24.main.configs.load:tooltip("Load selected config")
end)
pcall(function()
	var_0_24.main.configs.remove:tooltip("Remove selected local config")
end)
pcall(function()
	var_0_24.main.configs.import:tooltip("Import config from clipboard")
end)
pcall(function()
	var_0_24.main.configs.export:tooltip("Export current config to clipboard")
end)
pcall(function()
	var_0_24.main.configs.list:tooltip("Select saved config")
end)
pcall(function()
	var_0_24.main.configs.name:tooltip("Config name")
end)
pcall(function()
	var_0_24.main.information.youtube:tooltip("YouTube channel")
end)
pcall(function()
	var_0_24.main.information.discord:tooltip("Join Whitestrike Discord")
end)
pcall(function()
	var_0_24.main.information.config:tooltip("Creator configs on Neverlose")
end)

local var_0_25 = {
	_upd0 = false,
	_hm_rt = {
		center = {},
		kibit = {}
	},
	_scp_rt = {
		zoom = 0
	},
	_cla_rt = {
		last_ground = true,
		land = 0,
		side = false
	},
	_vm_rt = {
		forced_knife = false
	},
	_ci_rt = {
		dmg_scope = 0,
		dmg_dy = 0,
		dmg_dx = 0,
		dmg_drag = false,
		dmg_gap = 54,
		dmg_alpha = 0,
		slow = 0,
		scope = 0,
		gi_alpha = 0,
		gs_y = 0,
		gs_alpha = 0,
		dt = 0,
		gi_rows = {}
	},
	_win_rt = {
		spec_h = 0,
		spec_dy = 0,
		spec_dx = 0,
		spec_drag = false,
		spec_y = 130,
		spec_x = 35,
		spec_alpha = 0,
		vel_mod = 1,
		vel_frac = 0,
		vel_speed = 0,
		vel_dy = 0,
		vel_dx = 0,
		vel_drag = false,
		vel_y = 75,
		vel_x = 35,
		vel_alpha = 0,
		wm_last_speed = 0,
		wm_st_total = 0,
		wm_next_info = 0,
		wm_info = "",
		wm_next_ping = 0,
		wm_ping = "0ms",
		wm_w = 0,
		wm_dy = 0,
		wm_dx = 0,
		wm_drag = false,
		wm_y = 35,
		wm_x = 35,
		wm_alpha = 0,
		kb_h = 0,
		kb_dy = 0,
		kb_dx = 0,
		kb_drag = false,
		kb_y = 285,
		kb_x = 45,
		kb_alpha = 0,
		kb_rows_anim = {},
		spec_rows_anim = {}
	},
	_pe_rt = {
		example_alpha = 0,
		dy = 0,
		drag = false,
		logs = {},
		center = {}
	}
}
local var_0_26 = {
	default = 1,
	verdana = render.load_font("Verdana", 13, "ad"),
	verdana_bold = render.load_font("Verdana", 13, "bad"),
	calibri_bold = render.load_font("Calibri Bold", 15, "ad"),
	pixel = render.load_font("Verdana", 13, "a"),
	pixel_bold = render.load_font("Verdana", 13, "ab"),
	pixel_outline = render.load_font("Verdana", 13, "abc"),
	pixel_shadow = render.load_font("Verdana", 13, "b")
}
local var_0_27

local function var_0_28()
	local var_98_0 = var_0_24.antiaim.left.builder:get()

	if var_98_0 == 1 then
		return "Default"
	elseif var_98_0 == 2 then
		return "Defensive"
	end

	return var_0_14.z2[var_98_0] or var_98_0
end

local function var_0_29()
	local var_99_0 = var_0_24.antiaim.right.team:get()

	if var_99_0 == 1 then
		return "Terrorist"
	elseif var_99_0 == 2 then
		return "Counter Terrorist"
	end

	return var_0_14.z4[var_99_0] or var_99_0
end

local function var_0_30(arg_100_0)
	return arg_100_0 == "Defensive" and 2 or 1
end

local function var_0_31(arg_101_0)
	return arg_101_0 == "Counter Terrorist" and 2 or 1
end

for iter_0_2, iter_0_3 in ipairs(var_0_17.cond) do
	if iter_0_2 ~= 1 then
		var_0_24.antiaim.left.override[iter_0_3] = var_0_22.antiaim.builder_left:switch(var_0_10("toggle-on") .. " Override " .. iter_0_3, false)
	end
end

local function var_0_32(arg_102_0, arg_102_1)
	if type(arg_102_0) ~= "table" then
		return arg_102_0 == arg_102_1
	end

	for iter_102_0, iter_102_1 in pairs(arg_102_0) do
		if iter_102_1 == arg_102_1 then
			return true
		end
	end

	return false
end

local function var_0_33(arg_103_0)
	return var_0_32(var_0_24.other.visual.scope_paint.scope_flags:get() or {}, arg_103_0)
end

local function var_0_34(arg_104_0, arg_104_1, arg_104_2)
	return arg_104_0 + (arg_104_1 - arg_104_0) * arg_104_2
end

local function var_0_35(arg_105_0)
	if arg_105_0 == "Verdana" then
		return var_0_26.verdana
	elseif arg_105_0 == "Verdana Bold" then
		return var_0_26.verdana_bold
	elseif arg_105_0 == "Calibri Bold" then
		return var_0_26.calibri_bold
	elseif arg_105_0 == "Pixel" then
		return var_0_26.pixel
	elseif arg_105_0 == "Pixel Bold" then
		return var_0_26.pixel_bold
	elseif arg_105_0 == "Pixel Outline" then
		return var_0_26.pixel_outline
	elseif arg_105_0 == "Pixel Shadow" then
		return var_0_26.pixel_shadow
	end

	return var_0_26.default
end

local function var_0_36(arg_106_0, arg_106_1, arg_106_2)
	return arg_106_0 + (arg_106_1 - arg_106_0) * arg_106_2
end

local function var_0_37(arg_107_0)
	local var_107_0 = math.max(1, math.min(5, arg_107_0.master_count:get() or 1))
	local var_107_1 = {
		(arg_107_0.g1:get())
	}

	if var_107_0 >= 2 then
		var_107_1[2] = arg_107_0.g2:get()
	end

	if var_107_0 >= 3 then
		var_107_1[3] = arg_107_0.g3:get()
	end

	if var_107_0 >= 4 then
		var_107_1[4] = arg_107_0.g4:get()
	end

	if var_107_0 >= 5 then
		var_107_1[5] = arg_107_0.g5:get()
	end

	return var_107_1, var_107_0
end

local function var_0_38(arg_108_0)
	if arg_108_0.mode:get() == "Gradient Master" or arg_108_0.mode:get() == 2 then
		return arg_108_0.g1:get()
	end

	return arg_108_0.default_second:get()
end

local function var_0_39(arg_109_0, arg_109_1)
	local var_109_0
	local var_109_1

	if arg_109_1.mode:get() == "Gradient Master" or arg_109_1.mode:get() == 2 then
		var_109_0, var_109_1 = var_0_37(arg_109_1)
	else
		var_109_0 = {
			arg_109_1.default_main:get(),
			arg_109_1.default_second:get()
		}
		var_109_1 = 2
	end

	if not var_0_27 then
		var_0_27 = var_0_2(arg_109_0, -8, {
			var_109_0[1],
			var_109_0[2] or var_109_0[1]
		})
	end

	local var_109_2 = arg_109_0
	local var_109_3 = math.max(1, math.min(30, tonumber(arg_109_1.speed:get()) or 12))
	local var_109_4 = math.max(0.015, 1.15 - var_109_3 / 30 * 1.12)

	if var_0_27 then
		pcall(function()
			var_0_27:set_text(arg_109_0)
			var_0_27:set_colors(var_109_0)
			var_0_27:set_speed(-var_109_4)
			var_0_27:animate()

			var_109_2 = var_0_27:get_animated_text()
		end)
	end

	return var_109_2, var_109_0, var_109_1
end

local function var_0_40(arg_111_0, arg_111_1, arg_111_2, arg_111_3, arg_111_4)
	local var_111_0 = render.measure_text(arg_111_0, nil, arg_111_2).x
	local var_111_1 = arg_111_1.x - (arg_111_4 and var_111_0 / 2 or 0)
	local var_111_2 = color(arg_111_3.r, arg_111_3.g, arg_111_3.b, math.min(arg_111_3.a, 60))
	local var_111_3 = color(arg_111_3.r, arg_111_3.g, arg_111_3.b, math.min(arg_111_3.a, 35))

	render.text(arg_111_0, vector(var_111_1 - 2, arg_111_1.y), var_111_3, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1 + 2, arg_111_1.y), var_111_3, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1, arg_111_1.y - 2), var_111_3, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1, arg_111_1.y + 2), var_111_3, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1 - 1, arg_111_1.y), var_111_2, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1 + 1, arg_111_1.y), var_111_2, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1, arg_111_1.y - 1), var_111_2, nil, arg_111_2)
	render.text(arg_111_0, vector(var_111_1, arg_111_1.y + 1), var_111_2, nil, arg_111_2)
end

local function var_0_41(arg_112_0)
	local var_112_0 = 0
	local var_112_1 = 0

	pcall(function()
		var_112_0 = arg_112_0.m_vecVelocity.x or 0
		var_112_1 = arg_112_0.m_vecVelocity.y or 0
	end)

	local var_112_2 = math.sqrt(var_112_0 * var_112_0 + var_112_1 * var_112_1)
	local var_112_3 = 250
	local var_112_4 = arg_112_0 and arg_112_0:get_player_weapon() or nil

	pcall(function()
		local var_114_0 = var_112_4 and var_112_4:get_weapon_info() or nil

		if var_114_0 then
			var_112_3 = var_114_0.max_speed or var_114_0.flMaxSpeed or var_112_3
		end
	end)

	if var_0_9.antiaim.aa_slowwalk and var_0_9.antiaim.aa_slowwalk:get() then
		var_112_3 = 100
	end

	return math.clamp(var_112_2 / math.max(var_112_3, 1), 0, 1), var_112_2, var_112_3
end

local function var_0_42()
	if rage and rage.exploit and rage.exploit.get then
		local var_115_0, var_115_1 = pcall(function()
			return rage.exploit:get()
		end)

		if var_115_0 then
			if type(var_115_1) == "number" then
				return math.clamp(var_115_1, 0, 1)
			elseif type(var_115_1) == "boolean" then
				return var_115_1 and 1 or 0
			end
		end
	end

	return var_0_9.antiaim.dt and var_0_9.antiaim.dt:get() and 1 or 0
end

local function var_0_43()
	local var_117_0 = var_0_24.other.visual.center_indicators

	if not var_117_0 or not var_117_0:get() then
		return
	end

	local var_117_1 = entity.get_local_player()

	if not var_117_1 or not var_117_1:is_alive() then
		return
	end

	local var_117_2 = render.screen_size()
	local var_117_3 = var_117_1.m_bIsScoped == true

	var_0_25._ci_rt.scope = var_0_36(var_0_25._ci_rt.scope or 0, var_117_3 and 1 or 0, math.min(1, globals.frametime * 14))

	local var_117_4 = 45 * (var_0_25._ci_rt.scope or 0)
	local var_117_5 = var_117_2.x / 2 + var_117_4
	local var_117_6 = var_117_2.y / 2 + (var_117_0.y_offset:get() or 34)
	local var_117_7 = var_0_35(var_117_0.main_font:get())
	local var_117_8 = var_0_35(var_117_0.ind_font:get())
	local var_117_9, var_117_10, var_117_11 = var_0_39("whitestrike", var_117_0)
	local var_117_12 = render.measure_text(var_117_7, nil, var_117_9)
	local var_117_13 = vector(var_117_5 - var_117_12.x / 2, var_117_6)

	if var_117_0.glow:get() then
		var_0_40(var_117_7, vector(var_117_5, var_117_6), var_117_9, var_117_0.glow_color:get(), true)
	end

	render.text(var_117_7, var_117_13, color(255, 255, 255, 255), nil, var_117_9)
	render.text(var_117_7, vector(var_117_13.x + 1, var_117_13.y), color(255, 255, 255, 210), nil, var_117_9)

	local var_117_14 = var_0_38(var_117_0)
	local var_117_15, var_117_16, var_117_17 = var_0_41(var_117_1)

	var_0_25._ci_rt.slow = var_0_36(var_0_25._ci_rt.slow or 0, var_117_15, math.min(1, globals.frametime * 18))

	local var_117_18 = 54
	local var_117_19 = var_117_6 + 14

	render.rect(vector(var_117_5 - var_117_18 / 2, var_117_19), vector(var_117_5 + var_117_18 / 2, var_117_19 + 2), color(0, 0, 0, 100), 1)
	render.rect(vector(var_117_5 - var_117_18 / 2, var_117_19), vector(var_117_5 - var_117_18 / 2 + var_117_18 * (var_0_25._ci_rt.slow or 0), var_117_19 + 2), color(var_117_14.r, var_117_14.g, var_117_14.b, 230), 1)

	if not var_117_0.show_extra:get() then
		return
	end

	local var_117_20 = 20
	local var_117_21 = (var_0_17.cond[var_0_17.runtime.current or 1] or "Shared"):upper()

	render.text(var_117_8, vector(var_117_5 - render.measure_text(var_117_8, nil, var_117_21).x / 2, var_117_6 + var_117_20), color(255, 255, 255, 220), nil, var_117_21)

	local var_117_22 = var_117_20 + 12
	local var_117_23 = var_0_9.antiaim.dt and var_0_9.antiaim.dt:get()
	local var_117_24 = math.clamp(var_0_42(), 0, 1)

	var_0_25._ci_rt.dt = var_0_36(var_0_25._ci_rt.dt or 0, var_117_24, 0.22)
	var_0_25._ci_rt.dt_alpha = var_0_36(var_0_25._ci_rt.dt_alpha or 0, var_117_23 and 1 or 0, 0.22)

	if (var_0_25._ci_rt.dt_alpha or 0) > 0.01 then
		local var_117_25 = "DT"
		local var_117_26 = render.measure_text(var_117_8, nil, var_117_25).x
		local var_117_27 = math.floor(255 * (var_0_25._ci_rt.dt_alpha or 0))

		render.text(var_117_8, vector(var_117_5 - var_117_26 / 2, var_117_6 + var_117_22), color(255, 255, 255, var_117_27), nil, var_117_25)
		render.circle_outline(vector(var_117_5 + var_117_26 / 2 + 10, var_117_6 + var_117_22 + 6), color(var_117_14.r, var_117_14.g, var_117_14.b, math.floor(75 * (var_0_25._ci_rt.dt_alpha or 0))), 5.5, 0, 1, 2)

		if (var_0_25._ci_rt.dt or 0) > 0.001 then
			render.circle_outline(vector(var_117_5 + var_117_26 / 2 + 10, var_117_6 + var_117_22 + 6), color(var_117_14.r, var_117_14.g, var_117_14.b, var_117_27), 5.5, -90, math.clamp(var_0_25._ci_rt.dt or 0, 0, 1), 2)
		end

		var_117_22 = var_117_22 + 12
	end

	if var_0_9.antiaim.fakedick and var_0_9.antiaim.fakedick:get() then
		local var_117_28 = "DUCK"

		render.text(var_117_8, vector(var_117_5 - render.measure_text(var_117_8, nil, var_117_28).x / 2, var_117_6 + var_117_22), color(255, 255, 255, 220), nil, var_117_28)

		var_117_22 = var_117_22 + 12
	end

	if var_0_9.rage.quickpeek and var_0_9.rage.quickpeek:get() then
		local var_117_29 = "PEEK"

		render.text(var_117_8, vector(var_117_5 - render.measure_text(var_117_8, nil, var_117_29).x / 2, var_117_6 + var_117_22), color(255, 255, 255, 220), nil, var_117_29)
	end
end

local function var_0_44(arg_118_0)
	return math.max(0, math.min(255, arg_118_0 or 0))
end

local function var_0_45(arg_119_0, arg_119_1, arg_119_2)
	local var_119_0 = var_0_34(arg_119_0.r, arg_119_1.r, arg_119_2)
	local var_119_1 = var_0_34(arg_119_0.g, arg_119_1.g, arg_119_2)
	local var_119_2 = var_0_34(arg_119_0.b, arg_119_1.b, arg_119_2)
	local var_119_3 = var_0_34(arg_119_0.a, arg_119_1.a, arg_119_2)

	return color(var_0_44(var_119_0), var_0_44(var_119_1), var_0_44(var_119_2), var_0_44(var_119_3))
end

local function var_0_46(arg_120_0, arg_120_1, arg_120_2, arg_120_3, arg_120_4)
	render.line(vector(arg_120_0, arg_120_1), vector(arg_120_2, arg_120_3), arg_120_4)
end

local function var_0_47(arg_121_0, arg_121_1, arg_121_2, arg_121_3, arg_121_4, arg_121_5, arg_121_6)
	arg_121_6 = arg_121_6 or 32

	local var_121_0 = arg_121_0
	local var_121_1 = arg_121_1

	for iter_121_0 = 1, arg_121_6 do
		local var_121_2 = (iter_121_0 - 1) / arg_121_6
		local var_121_3 = iter_121_0 / arg_121_6
		local var_121_4 = arg_121_0 + (arg_121_2 - arg_121_0) * var_121_3
		local var_121_5 = arg_121_1 + (arg_121_3 - arg_121_1) * var_121_3
		local var_121_6 = var_0_45(arg_121_4, arg_121_5, var_121_2)

		var_0_46(var_121_0, var_121_1, var_121_4, var_121_5, var_121_6)

		var_121_0, var_121_1 = var_121_4, var_121_5
	end
end

WS_DAMAGE = {
	fonts = {
		default = 1,
		pixel = render.load_font("Verdana", 11, "a"),
		bold = render.load_font("Verdana", 13, "bad")
	}
}

function WS_DAMAGE.font(arg_122_0, arg_122_1)
	if arg_122_1 == "Pixel" or arg_122_1 == 2 then
		return arg_122_0.fonts.pixel
	elseif arg_122_1 == "Bold" or arg_122_1 == 3 then
		return arg_122_0.fonts.bold
	end

	return arg_122_0.fonts.default
end

function WS_DAMAGE.bind(arg_123_0, arg_123_1)
	local var_123_0 = false
	local var_123_1
	local var_123_2, var_123_3 = pcall(function()
		return ui.get_binds()
	end)

	if var_123_2 and var_123_3 then
		for iter_123_0, iter_123_1 in pairs(var_123_3) do
			local var_123_4
			local var_123_5 = false
			local var_123_6

			pcall(function()
				var_123_4 = iter_123_1.name
			end)
			pcall(function()
				var_123_5 = iter_123_1.active
			end)
			pcall(function()
				var_123_6 = iter_123_1.value
			end)

			if var_123_4 == arg_123_1 and var_123_5 then
				var_123_0 = true
				var_123_1 = var_123_6

				break
			end
		end
	end

	return var_123_0, var_123_1
end

function WS_DAMAGE.weapon_group(arg_128_0)
	local var_128_0 = entity.get_local_player()

	if not var_128_0 or not var_128_0:is_alive() then
		return "global"
	end

	local var_128_1 = var_128_0:get_player_weapon()

	if not var_128_1 then
		return "global"
	end

	local var_128_2 = ""

	pcall(function()
		var_128_2 = var_128_1:get_classname() or ""
	end)

	var_128_2 = tostring(var_128_2)

	if var_128_2:find("SSG08") or var_128_2:find("ssg08") then
		return "scout"
	end

	if var_128_2:find("AWP") or var_128_2:find("awp") then
		return "awpnaxyi"
	end

	if var_128_2:find("Deagle") or var_128_2:find("DEagle") then
		return "deagle"
	end

	if var_128_2:find("Revolver") then
		return "revik"
	end

	if var_128_2:find("Taser") then
		return "taser"
	end

	if var_128_2:find("AK47") or var_128_2:find("M4A1") or var_128_2:find("M4A4") or var_128_2:find("Galil") or var_128_2:find("Famas") or var_128_2:find("AUG") or var_128_2:find("SG556") then
		return "rifles"
	end

	if var_128_2:find("G3SG1") or var_128_2:find("SCAR20") then
		return "autosnipers"
	end

	if var_128_2:find("Glock") or var_128_2:find("USP") or var_128_2:find("HKP2000") or var_128_2:find("P250") or var_128_2:find("Tec9") or var_128_2:find("Elite") or var_128_2:find("FiveSeven") or var_128_2:find("CZ75") then
		return "pistols"
	end

	if var_128_2:find("MP") or var_128_2:find("P90") or var_128_2:find("Bizon") or var_128_2:find("Mac10") or var_128_2:find("UMP") then
		return "smgs"
	end

	if var_128_2:find("Nova") or var_128_2:find("XM1014") or var_128_2:find("Sawedoff") or var_128_2:find("Mag7") then
		return "shotguns"
	end

	if var_128_2:find("M249") or var_128_2:find("Negev") then
		return "machiguns"
	end

	return "global"
end

function WS_DAMAGE.ref_value(arg_130_0, arg_130_1)
	if not arg_130_1 then
		return nil
	end

	local var_130_0, var_130_1 = pcall(function()
		return arg_130_1:get()
	end)

	if var_130_0 then
		return var_130_1
	end

	return nil
end

function WS_DAMAGE.current_value(arg_132_0)
	local var_132_0, var_132_1 = arg_132_0:bind("Min. Damage")

	if var_132_0 then
		local var_132_2 = tonumber(var_132_1)

		if var_132_2 then
			return var_132_2, true
		end

		if var_132_1 ~= nil then
			return tostring(var_132_1), true
		end
	end

	local var_132_3 = arg_132_0:weapon_group()
	local var_132_4 = var_0_9.min_damage and (var_0_9.min_damage[var_132_3] or var_0_9.min_damage.global) or nil
	local var_132_5 = arg_132_0:ref_value(var_132_4)

	if type(var_132_5) == "number" then
		return var_132_5, false
	end

	if type(var_132_5) == "string" then
		return var_132_5, false
	end

	return 0, false
end

function WS_DAMAGE.text(arg_133_0, arg_133_1)
	if type(arg_133_1) == "number" then
		return tostring(math.floor(arg_133_1 + 0.5))
	end

	return tostring(arg_133_1 or "0")
end

function WS_DAMAGE.mouse(arg_134_0)
	local var_134_0, var_134_1 = pcall(function()
		return ui.get_mouse_position()
	end)

	if var_134_0 and var_134_1 then
		return var_134_1
	end

	local var_134_2, var_134_3 = pcall(function()
		return render.mouse_position()
	end)

	if var_134_2 and var_134_3 then
		return var_134_3
	end

	return vector(0, 0)
end

function WS_DAMAGE.mdown(arg_137_0)
	local var_137_0, var_137_1 = pcall(function()
		return common.is_button_down(1)
	end)

	if var_137_0 then
		return var_137_1
	end

	local var_137_2, var_137_3 = pcall(function()
		return ui.is_mouse_down(0)
	end)

	if var_137_2 then
		return var_137_3
	end

	return false
end

function WS_DAMAGE.menu_open(arg_140_0)
	local var_140_0, var_140_1 = pcall(function()
		return ui.get_alpha()
	end)

	return var_140_0 and var_140_1 and var_140_1 > 0.01
end

function WS_DAMAGE.inbox(arg_142_0, arg_142_1, arg_142_2, arg_142_3, arg_142_4, arg_142_5)
	return arg_142_2 <= arg_142_1.x and arg_142_1.x <= arg_142_2 + arg_142_4 and arg_142_3 <= arg_142_1.y and arg_142_1.y <= arg_142_3 + arg_142_5
end

function WS_DAMAGE.corners(arg_143_0, arg_143_1, arg_143_2, arg_143_3, arg_143_4, arg_143_5, arg_143_6)
	local var_143_0 = 8
	local var_143_1 = math.floor(220 * arg_143_6)

	render.line(vector(arg_143_1, arg_143_2), vector(arg_143_1 + var_143_0, arg_143_2), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1, arg_143_2), vector(arg_143_1, arg_143_2 + var_143_0), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1 + arg_143_3, arg_143_2), vector(arg_143_1 + arg_143_3 - var_143_0, arg_143_2), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1 + arg_143_3, arg_143_2), vector(arg_143_1 + arg_143_3, arg_143_2 + var_143_0), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1, arg_143_2 + arg_143_4), vector(arg_143_1 + var_143_0, arg_143_2 + arg_143_4), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1, arg_143_2 + arg_143_4), vector(arg_143_1, arg_143_2 + arg_143_4 - var_143_0), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1 + arg_143_3, arg_143_2 + arg_143_4), vector(arg_143_1 + arg_143_3 - var_143_0, arg_143_2 + arg_143_4), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
	render.line(vector(arg_143_1 + arg_143_3, arg_143_2 + arg_143_4), vector(arg_143_1 + arg_143_3, arg_143_2 + arg_143_4 - var_143_0), color(arg_143_5.r, arg_143_5.g, arg_143_5.b, var_143_1))
end

function WS_DAMAGE.drag_box(arg_144_0, arg_144_1, arg_144_2, arg_144_3, arg_144_4, arg_144_5, arg_144_6)
	local var_144_0 = var_0_25._ci_rt
	local var_144_1 = render.screen_size()

	arg_144_3 = math.max(1, math.min(arg_144_3 or 1, var_144_1.x - 2))
	arg_144_4 = math.max(1, math.min(arg_144_4 or 1, var_144_1.y - 2))

	if arg_144_6 then
		arg_144_1 = var_144_1.x / 2 - arg_144_3 / 2
	else
		arg_144_1 = math.max(0, math.min(var_144_1.x - arg_144_3, tonumber(arg_144_1) or var_144_1.x / 2 - arg_144_3 / 2))
	end

	arg_144_2 = math.max(0, math.min(var_144_1.y - arg_144_4, tonumber(arg_144_2) or var_144_1.y / 2 + arg_144_4))
	var_144_0.dmg_x = arg_144_1
	var_144_0.dmg_y = arg_144_2

	local var_144_2 = arg_144_0:menu_open()
	local var_144_3 = arg_144_0:mouse()
	local var_144_4 = arg_144_0:mdown()
	local var_144_5 = var_144_2 and arg_144_0:inbox(var_144_3, arg_144_1, arg_144_2, arg_144_3, arg_144_4)

	if var_144_2 and var_144_4 and not var_144_0.dmg_drag and var_144_5 then
		var_144_0.dmg_drag = true
		var_144_0.dmg_dx = var_144_3.x - arg_144_1
		var_144_0.dmg_dy = var_144_3.y - arg_144_2
	end

	if not var_144_4 or not var_144_2 then
		var_144_0.dmg_drag = false
	end

	if var_144_0.dmg_drag then
		if arg_144_6 then
			var_144_0.dmg_x = var_144_1.x / 2 - arg_144_3 / 2
		else
			var_144_0.dmg_x = math.max(0, math.min(var_144_1.x - arg_144_3, var_144_3.x - (var_144_0.dmg_dx or 0)))
		end

		var_144_0.dmg_y = math.max(0, math.min(var_144_1.y - arg_144_4, var_144_3.y - (var_144_0.dmg_dy or 0)))

		render.rect(vector(0, 0), var_144_1, color(0, 0, 0, 95), 0)

		if arg_144_6 then
			local var_144_6 = var_144_0.dmg_x + arg_144_3 / 2

			render.line(vector(var_144_6, 0), vector(var_144_6, var_144_1.y), color(arg_144_5.r, arg_144_5.g, arg_144_5.b, 135))
			render.line(vector(var_144_6 - 1, 0), vector(var_144_6 - 1, var_144_1.y), color(arg_144_5.r, arg_144_5.g, arg_144_5.b, 45))
			render.line(vector(var_144_6 + 1, 0), vector(var_144_6 + 1, var_144_1.y), color(arg_144_5.r, arg_144_5.g, arg_144_5.b, 45))
		else
			local var_144_7 = var_144_0.dmg_x + arg_144_3 / 2
			local var_144_8 = var_144_0.dmg_y + arg_144_4 / 2

			render.line(vector(var_144_7, 0), vector(var_144_7, var_144_1.y), color(arg_144_5.r, arg_144_5.g, arg_144_5.b, 80))
			render.line(vector(0, var_144_8), vector(var_144_1.x, var_144_8), color(arg_144_5.r, arg_144_5.g, arg_144_5.b, 80))
		end

		arg_144_0:corners(var_144_0.dmg_x, var_144_0.dmg_y, arg_144_3, arg_144_4, arg_144_5, 1)
	elseif var_144_5 then
		arg_144_0:corners(arg_144_1, arg_144_2, arg_144_3, arg_144_4, arg_144_5, 0.65)
	end

	return var_144_0.dmg_x or arg_144_1, var_144_0.dmg_y or arg_144_2
end

function WS_DAMAGE.draw(arg_145_0)
	local var_145_0 = var_0_24.other.visual.damage_indicator

	if not var_145_0 or not var_145_0:get() then
		var_0_25._ci_rt.dmg_alpha = var_0_36(var_0_25._ci_rt.dmg_alpha or 0, 0, math.min(1, globals.frametime * 12))

		return
	end

	local var_145_1 = entity.get_local_player()
	local var_145_2 = var_145_1 and var_145_1:is_alive()
	local var_145_3, var_145_4 = arg_145_0:current_value()
	local var_145_5 = var_145_0.only_override and var_145_0.only_override:get()
	local var_145_6 = var_145_2 and var_145_3 ~= nil and (not var_145_5 or var_145_4)
	local var_145_7 = var_0_25._ci_rt

	var_145_7.dmg_alpha = var_0_36(var_145_7.dmg_alpha or 0, var_145_6 and 1 or 0, math.min(1, globals.frametime * 12))

	local var_145_8 = var_145_7.dmg_alpha or 0

	if var_145_8 <= 0.01 then
		return
	end

	local var_145_9 = render.screen_size()
	local var_145_10 = arg_145_0:font(var_145_0.font:get())
	local var_145_11 = var_145_0.mode and var_145_0.mode:get() or "Default"
	local var_145_12 = var_145_11 == "Double" or var_145_11 == 2
	local var_145_13 = var_145_4 and var_145_0.override_color:get() or var_145_0.color:get()
	local var_145_14 = var_145_0.color:get()
	local var_145_15 = arg_145_0:text(var_145_3)
	local var_145_16 = "0"
	local var_145_17 = render.measure_text(var_145_10, nil, var_145_15)
	local var_145_18 = render.measure_text(var_145_10, nil, var_145_16)
	local var_145_19 = var_145_0.double_distance and (tonumber(var_145_0.double_distance:get()) or 54) or 54
	local var_145_20 = math.max(20, math.min(220, var_145_19))
	local var_145_21
	local var_145_22
	local var_145_23

	if var_145_12 then
		var_145_21 = math.max(80, var_145_20 * 2 + math.max(var_145_17.x, var_145_18.x) + 28)
		var_145_23 = 22
	else
		var_145_21 = math.max(34, var_145_17.x + 14)
		var_145_23 = 18
	end

	if var_145_7.dmg_x == nil or var_145_7.dmg_y == nil then
		var_145_7.dmg_x = var_145_9.x / 2 - var_145_21 / 2
		var_145_7.dmg_y = var_145_9.y / 2 + 32
	end

	local var_145_24, var_145_25 = arg_145_0:drag_box(var_145_7.dmg_x, var_145_7.dmg_y, var_145_21, var_145_23, var_145_13, var_145_12)

	var_145_7.dmg_x = var_145_24
	var_145_7.dmg_y = var_145_25

	if var_145_12 then
		local var_145_26 = var_145_24 + var_145_21 / 2
		local var_145_27 = var_145_25 + var_145_23 / 2 - math.max(var_145_17.y, var_145_18.y) / 2
		local var_145_28 = var_145_26 - var_145_20 - var_145_18.x / 2
		local var_145_29 = var_145_26 + var_145_20 - var_145_17.x / 2

		render.text(var_145_10, vector(var_145_28 + 1, var_145_27 + 1), color(0, 0, 0, math.floor(160 * var_145_8)), nil, var_145_16)
		render.text(var_145_10, vector(var_145_28, var_145_27), color(var_145_14.r, var_145_14.g, var_145_14.b, math.floor((var_145_14.a or 255) * var_145_8)), nil, var_145_16)
		render.text(var_145_10, vector(var_145_29 + 1, var_145_27 + 1), color(0, 0, 0, math.floor(160 * var_145_8)), nil, var_145_15)
		render.text(var_145_10, vector(var_145_29, var_145_27), color(var_145_13.r, var_145_13.g, var_145_13.b, math.floor((var_145_13.a or 255) * var_145_8)), nil, var_145_15)
	else
		local var_145_30 = var_145_24 + var_145_21 / 2 - var_145_17.x / 2
		local var_145_31 = var_145_25 + var_145_23 / 2 - var_145_17.y / 2

		render.text(var_145_10, vector(var_145_30 + 1, var_145_31 + 1), color(0, 0, 0, math.floor(160 * var_145_8)), nil, var_145_15)
		render.text(var_145_10, vector(var_145_30, var_145_31), color(var_145_13.r, var_145_13.g, var_145_13.b, math.floor((var_145_13.a or 255) * var_145_8)), nil, var_145_15)
	end
end

WS_MONEY = {
	fonts = {
		main = render.load_font("Calibri Bold", 18, "ad"),
		small = render.load_font("Verdana", 13, "ad"),
		icon = render.load_font("Verdana", 15, "ad")
	}
}

function WS_MONEY.has(arg_146_0, arg_146_1, arg_146_2)
	local var_146_0 = arg_146_1.select and arg_146_1.select:get() or {}

	if type(var_146_0) ~= "table" then
		return var_146_0 == arg_146_2
	end

	for iter_146_0, iter_146_1 in pairs(var_146_0) do
		if iter_146_1 == arg_146_2 then
			return true
		end
	end

	return false
end

function WS_MONEY.anim(arg_147_0, arg_147_1, arg_147_2, arg_147_3)
	local var_147_0 = var_0_25._ci_rt

	var_147_0.gi_rows = var_147_0.gi_rows or {}

	local var_147_1 = var_147_0.gi_rows[arg_147_1] or 0

	var_147_0.gi_rows[arg_147_1] = var_0_36(var_147_1, arg_147_2, math.min(1, globals.frametime * ((arg_147_3 or 0.05) * 200)))

	return var_147_0.gi_rows[arg_147_1]
end

function WS_MONEY.bind_active(arg_148_0, arg_148_1)
	local var_148_0, var_148_1 = pcall(function()
		return ui.get_binds()
	end)

	if var_148_0 and var_148_1 then
		for iter_148_0, iter_148_1 in pairs(var_148_1) do
			local var_148_2
			local var_148_3 = false

			pcall(function()
				var_148_2 = iter_148_1.name
			end)
			pcall(function()
				var_148_3 = iter_148_1.active
			end)

			if tostring(var_148_2) == arg_148_1 and var_148_3 then
				return true
			end
		end
	end

	return false
end

function WS_MONEY.ref_get(arg_152_0, arg_152_1)
	if not arg_152_1 then
		return false
	end

	local var_152_0, var_152_1 = pcall(function()
		return arg_152_1:get()
	end)

	if var_152_0 then
		return var_152_1
	end

	return false
end

function WS_MONEY.fake_latency_active(arg_154_0)
	local var_154_0 = var_0_24.other.misc.fake_latency

	if not var_154_0 then
		return false
	end

	local var_154_1 = false
	local var_154_2 = 0

	pcall(function()
		var_154_1 = var_154_0:get()
	end)
	pcall(function()
		var_154_2 = var_154_0.amount and (tonumber(var_154_0.amount:get()) or 0) or 0
	end)

	return var_154_1 and var_154_2 > 0
end

function WS_MONEY.can_dormant(arg_157_0)
	local var_157_0 = {}
	local var_157_1 = {}

	pcall(function()
		var_157_0 = entity.get_players(true, false) or {}
		var_157_1 = entity.get_players(true, true) or {}
	end)

	return #var_157_0 ~= #var_157_1
end

function WS_MONEY.hit_text(arg_159_0)
	local var_159_0 = var_0_25._ci_rt

	var_159_0.gi_hits = var_159_0.gi_hits or 0
	var_159_0.gi_shots = var_159_0.gi_shots or 0

	local var_159_1 = var_159_0.gi_hits > 0 and var_159_0.gi_shots > 0 and var_159_0.gi_hits / var_159_0.gi_shots * 100 or 0

	return string.format("%d/%d (%.1f)", var_159_0.gi_hits, var_159_0.gi_shots, var_159_1)
end

function WS_MONEY.dt_charged(arg_160_0)
	local var_160_0 = 0

	pcall(function()
		var_160_0 = rage.exploit:get() or 0
	end)

	return var_160_0 == 1 or var_160_0 >= 1
end

function WS_MONEY.draw_text(arg_162_0, arg_162_1, arg_162_2, arg_162_3, arg_162_4, arg_162_5, arg_162_6, arg_162_7)
	local var_162_0 = math.floor((arg_162_3.a or 255) * arg_162_6)
	local var_162_1 = render.measure_text(arg_162_1, nil, arg_162_2)
	local var_162_2 = arg_162_7 and arg_162_4 - var_162_1.x / 2 or arg_162_4

	render.text(arg_162_1, vector(var_162_2 + 1, arg_162_5 + 1), color(0, 0, 0, math.floor(160 * arg_162_6)), nil, arg_162_2)
	render.text(arg_162_1, vector(var_162_2, arg_162_5), color(arg_162_3.r, arg_162_3.g, arg_162_3.b, var_162_0), nil, arg_162_2)
end

function WS_MONEY.rows(arg_163_0, arg_163_1)
	local var_163_0 = {}
	local var_163_1 = arg_163_0:dt_charged() and color(200, 200, 200, 255) or color(255, 0, 0, 255)
	local var_163_2 = arg_163_0:can_dormant() and color(200, 200, 200, 255) or color(255, 0, 0, 255)
	local var_163_3 = {
		"",
		ui.get_icon("bolt"),
		ui.get_icon("shield"),
		ui.get_icon("signal"),
		ui.get_icon("crosshairs"),
		ui.get_icon("person-rays"),
		ui.get_icon("shield-halved"),
		ui.get_icon("arrows-turn-to-dots"),
		ui.get_icon("eye-slash")
	}
	local var_163_4 = var_0_9.antiaim and var_0_9.antiaim.dt
	local var_163_5 = var_0_9.hideshots
	local var_163_6 = var_0_9.dormant
	local var_163_7 = false

	pcall(function()
		var_163_7 = var_0_9.body_aim and var_0_9.body_aim.global and var_0_9.body_aim.global:get() == "Force"
	end)

	local var_163_8 = false

	pcall(function()
		var_163_8 = var_0_9.force_safe_point and var_0_9.force_safe_point.global and var_0_9.force_safe_point.global:get() == "Force"
	end)

	var_163_0[#var_163_0 + 1] = {
		id = "hm",
		icon = var_163_3[1],
		text = arg_163_0:hit_text(),
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Hit/Miss Rate")
	}
	var_163_0[#var_163_0 + 1] = {
		text = "DT",
		id = "dt",
		icon = var_163_3[2],
		col = var_163_1,
		active = arg_163_0:has(arg_163_1, "Double Tap") and arg_163_0:ref_get(var_163_4)
	}
	var_163_0[#var_163_0 + 1] = {
		text = "OS-AA",
		id = "hs",
		icon = var_163_3[3],
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Hide Shots") and arg_163_0:ref_get(var_163_5) and not arg_163_0:ref_get(var_163_4)
	}
	var_163_0[#var_163_0 + 1] = {
		text = "PING",
		id = "ping",
		icon = var_163_3[4],
		col = color(150, 190, 50, 255),
		active = arg_163_0:has(arg_163_1, "Fake Latency") and arg_163_0:fake_latency_active()
	}
	var_163_0[#var_163_0 + 1] = {
		text = "MD",
		id = "md",
		icon = var_163_3[5],
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Min. Damage Override") and arg_163_0:bind_active("Min. Damage")
	}
	var_163_0[#var_163_0 + 1] = {
		text = "BODY",
		id = "body",
		icon = var_163_3[6],
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Body Aim") and var_163_7
	}
	var_163_0[#var_163_0 + 1] = {
		text = "SAFE",
		id = "safe",
		icon = var_163_3[7],
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Force Safe Point") and var_163_8
	}
	var_163_0[#var_163_0 + 1] = {
		text = "FS",
		id = "fs",
		icon = var_163_3[8],
		col = color(200, 200, 200, 255),
		active = arg_163_0:has(arg_163_1, "Freestanding") and var_0_9.antiaim and var_0_9.antiaim.freestand and arg_163_0:ref_get(var_0_9.antiaim.freestand)
	}
	var_163_0[#var_163_0 + 1] = {
		text = "DA",
		id = "da",
		icon = var_163_3[9],
		col = var_163_2,
		active = arg_163_0:has(arg_163_1, "Dormant Aimbot") and arg_163_0:ref_get(var_163_6)
	}

	return var_163_0
end

function WS_MONEY.draw_default(arg_166_0, arg_166_1, arg_166_2, arg_166_3)
	local var_166_0 = render.screen_size()
	local var_166_1 = 50
	local var_166_2 = var_166_0.y - 292 + (arg_166_1.y_offset:get() or 0)
	local var_166_3 = 0

	for iter_166_0, iter_166_1 in ipairs(arg_166_2) do
		local var_166_4 = arg_166_1.animated:get() and arg_166_0:anim("gi" .. iter_166_1.id, iter_166_1.active and 1 or 0, 0.05) or iter_166_1.active and 1 or 0

		var_166_3 = var_166_3 + 41 * var_166_4

		if var_166_4 > 0.01 then
			arg_166_0:draw_text(arg_166_0.fonts.main, iter_166_1.text, iter_166_1.col, var_166_1, var_166_2 - var_166_3, arg_166_3 * var_166_4, false)
		end
	end
end

function WS_MONEY.draw_custom(arg_167_0, arg_167_1, arg_167_2, arg_167_3)
	local var_167_0 = render.screen_size()
	local var_167_1 = 50
	local var_167_2 = var_167_0.y - 292 + (arg_167_1.y_offset:get() or 0)
	local var_167_3 = arg_167_1.custom_style:get()
	local var_167_4 = var_167_3 == "White" or var_167_3 == 2
	local var_167_5 = var_167_4 and color(245, 245, 245, 190) or color(10, 10, 10, 190)
	local var_167_6 = var_167_4 and color(210, 210, 210, 160) or color(0, 0, 0, 180)
	local var_167_7 = 0

	for iter_167_0, iter_167_1 in ipairs(arg_167_2) do
		local var_167_8 = arg_167_1.animated:get() and arg_167_0:anim("gi" .. iter_167_1.id, iter_167_1.active and 1 or 0, 0.05) or iter_167_1.active and 1 or 0

		var_167_7 = var_167_7 + 41 * var_167_8

		if var_167_8 > 0.01 then
			local var_167_9 = iter_167_1.icon .. "  " .. iter_167_1.text
			local var_167_10 = render.measure_text(arg_167_0.fonts.main, nil, var_167_9)
			local var_167_11 = var_167_1
			local var_167_12 = var_167_2 - var_167_7 - 5

			render.rect(vector(var_167_11 - 6, var_167_12 - 3), vector(var_167_11 + var_167_10.x + 12, var_167_12 + 25), color(var_167_6.r, var_167_6.g, var_167_6.b, math.floor(var_167_6.a * arg_167_3 * var_167_8)), 4)
			render.rect(vector(var_167_11 - 7, var_167_12 - 4), vector(var_167_11 + var_167_10.x + 11, var_167_12 + 24), color(var_167_5.r, var_167_5.g, var_167_5.b, math.floor(var_167_5.a * arg_167_3 * var_167_8)), 4)
			arg_167_0:draw_text(arg_167_0.fonts.main, var_167_9, iter_167_1.col, var_167_11, var_167_12, arg_167_3 * var_167_8, false)
		end
	end
end

function WS_MONEY.draw(arg_168_0)
	local var_168_0 = var_0_24.other.visual.money_indicators

	if not var_168_0 or not var_168_0:get() then
		return
	end

	local var_168_1 = entity.get_local_player()

	if not var_168_1 or not var_168_1:is_alive() then
		return
	end

	local var_168_2 = arg_168_0:rows(var_168_0)
	local var_168_3 = var_168_0.mode:get()

	if var_168_3 == "Custom" or var_168_3 == 2 then
		arg_168_0:draw_custom(var_168_0, var_168_2, 1)
	else
		arg_168_0:draw_default(var_168_0, var_168_2, 1)
	end
end

function WS_MONEY.reset_hitrate(arg_169_0)
	local var_169_0 = var_0_25._ci_rt

	var_169_0.gi_hits = 0
	var_169_0.gi_shots = 0
	var_169_0.gi_rows = {}
	var_169_0.gi_alpha = 0
end

local function var_0_48()
	if WS_MONEY and WS_MONEY.reset_hitrate then
		WS_MONEY:reset_hitrate()
	end
end

local function var_0_49(arg_171_0)
	local var_171_0 = var_0_24.other.visual.disable_sleeves

	if not var_171_0 or not var_171_0:get() then
		return
	end

	local var_171_1 = entity.get_local_player()

	if not var_171_1 or not var_171_1:is_alive() then
		return
	end

	local var_171_2 = ""

	pcall(function()
		var_171_2 = arg_171_0.name or ""
	end)

	if tostring(var_171_2):find("sleeve", 1, true) then
		return false
	end
end

local var_0_50 = {
	max_tickbase = 0,
	defensive_ticks = 0,
	sim_ticks = {},
	net_data = {},
	esp_data = {},
	backtrack_data = {},
	last_valid_positions = {}
}

local function var_0_51(arg_173_0)
	if to_ticks then
		local var_173_0, var_173_1 = pcall(function()
			return to_ticks(arg_173_0)
		end)

		if var_173_0 then
			return var_173_1
		end
	end

	return math.floor((arg_173_0 or 0) / (globals.tickinterval or 0.015) + 0.5)
end

local function var_0_52(arg_175_0, arg_175_1, arg_175_2)
	local var_175_0 = globals.tickinterval or 0.015
	local var_175_1 = 800
	local var_175_2 = 301

	pcall(function()
		var_175_1 = cvar.sv_gravity:float()
	end)
	pcall(function()
		var_175_2 = cvar.sv_jump_impulse:float()
	end)

	local var_175_3 = arg_175_0.m_vecVelocity or vector(0, 0, 0)
	local var_175_4 = arg_175_1
	local var_175_5 = arg_175_1
	local var_175_6 = var_175_3.z > 0 and -(var_175_1 * var_175_0) or var_175_2 * var_175_0

	for iter_175_0 = 1, arg_175_2 do
		var_175_5 = var_175_4
		var_175_4 = vector(var_175_4.x + var_175_3.x * var_175_0, var_175_4.y + var_175_3.y * var_175_0, var_175_4.z + (var_175_3.z + var_175_6) * var_175_0)

		local var_175_7

		pcall(function()
			var_175_7 = utils.trace_line(var_175_5, var_175_4)
		end)

		if var_175_7 and var_175_7.fraction <= 0.99 then
			return var_175_5
		end
	end

	return var_175_4
end

local function var_0_53()
	local var_179_0 = entity.get_local_player()

	if not var_179_0 then
		return
	end

	local var_179_1 = 0

	pcall(function()
		var_179_1 = var_179_0.m_nTickBase or 0
	end)

	if math.abs(var_179_1 - (var_0_50.max_tickbase or 0)) > 64 then
		var_0_50.max_tickbase = 0
	end

	if var_179_1 > (var_0_50.max_tickbase or 0) then
		var_0_50.max_tickbase = var_179_1
		var_0_50.defensive_ticks = 0
	elseif var_179_1 < (var_0_50.max_tickbase or 0) then
		var_0_50.defensive_ticks = math.min(14, math.max(0, (var_0_50.max_tickbase or 0) - var_179_1 - 1))
	end
end

local function var_0_54()
	if not entity.get_local_player() then
		return
	end

	local var_181_0 = {}

	pcall(function()
		var_181_0 = entity.get_players(true, true) or {}
	end)

	for iter_181_0, iter_181_1 in ipairs(var_181_0) do
		local var_181_1

		pcall(function()
			var_181_1 = iter_181_1:get_index()
		end)

		if var_181_1 then
			if iter_181_1:is_dormant() or not iter_181_1:is_alive() then
				var_0_50.sim_ticks[var_181_1] = nil
				var_0_50.net_data[var_181_1] = nil
				var_0_50.esp_data[var_181_1] = nil
				var_0_50.backtrack_data[var_181_1] = nil
				var_0_50.last_valid_positions[var_181_1] = nil
			else
				local var_181_2 = iter_181_1.m_vecOrigin or iter_181_1:get_origin()
				local var_181_3 = var_0_51(iter_181_1.m_flSimulationTime or 0)

				var_0_50.backtrack_data[var_181_1] = var_0_50.backtrack_data[var_181_1] or {}

				table.insert(var_0_50.backtrack_data[var_181_1], 1, {
					tick = var_181_3,
					origin = var_181_2
				})

				if #var_0_50.backtrack_data[var_181_1] > 14 then
					table.remove(var_0_50.backtrack_data[var_181_1])
				end

				if (var_0_50.defensive_ticks or 0) <= 0 then
					var_0_50.last_valid_positions[var_181_1] = var_181_2
				end

				local var_181_4 = var_0_50.sim_ticks[var_181_1]

				if var_181_4 then
					local var_181_5 = var_181_3 - var_181_4.tick

					if var_181_5 < 0 or var_181_5 > 0 and var_181_5 <= 64 then
						local var_181_6 = (var_181_2 - var_181_4.origin):length2dsqr()
						local var_181_7 = (var_0_50.defensive_ticks or 0) > 0 and var_181_5 < 0
						local var_181_8 = var_181_2

						if var_181_7 and var_0_50.last_valid_positions[var_181_1] then
							var_181_8 = var_0_50.last_valid_positions[var_181_1]
						elseif var_181_5 > 0 then
							var_181_8 = var_0_52(iter_181_1, var_181_2, var_181_5 - 1)
						end

						if var_181_7 then
							var_0_50.esp_data[var_181_1] = 1
						end

						var_0_50.net_data[var_181_1] = {
							tick = var_181_5 - 1,
							origin = var_181_2,
							predicted_origin = var_181_8,
							tickbase = var_181_7,
							lagcomp = var_181_6 > 4096
						}
					end
				end

				var_0_50.esp_data[var_181_1] = var_0_50.esp_data[var_181_1] or 0
				var_0_50.sim_ticks[var_181_1] = {
					tick = var_181_3,
					origin = var_181_2
				}
			end
		end
	end
end

local function var_0_55()
	local var_184_0 = var_0_24.other.visual.lagcomp_box

	if not var_184_0 or not var_184_0:get() then
		return
	end

	local var_184_1 = entity.get_local_player()

	if not var_184_1 or not var_184_1:is_alive() then
		return
	end

	local var_184_2 = var_184_0.color:get()
	local var_184_3 = var_184_0.defensive_color:get()

	for iter_184_0, iter_184_1 in pairs(var_0_50.net_data) do
		local var_184_4 = entity.get(iter_184_0)

		if var_184_4 and var_184_4:is_alive() and var_184_4:is_enemy() and (iter_184_1.lagcomp or iter_184_1.tickbase) then
			local var_184_5 = iter_184_1.predicted_origin or iter_184_1.origin or var_184_4:get_origin()
			local var_184_6 = var_184_4.m_vecMins or vector(-16, -16, 0)
			local var_184_7 = var_184_4.m_vecMaxs or vector(16, 16, 72)
			local var_184_8 = render.world_to_screen(var_184_5 + var_184_6)
			local var_184_9 = render.world_to_screen(var_184_5 + var_184_7)
			local var_184_10 = var_184_4:get_origin()
			local var_184_11 = render.world_to_screen(var_184_10)

			if var_184_8 and var_184_9 then
				local var_184_12 = math.min(var_184_8.x, var_184_9.x)
				local var_184_13 = math.min(var_184_8.y, var_184_9.y)
				local var_184_14 = math.max(var_184_8.x, var_184_9.x)
				local var_184_15 = math.max(var_184_8.y, var_184_9.y)
				local var_184_16 = iter_184_1.tickbase and var_184_3 or var_184_2

				render.rect_outline(vector(var_184_12, var_184_13), vector(var_184_14, var_184_15), color(var_184_16.r, var_184_16.g, var_184_16.b, var_184_16.a), 1, 0)

				if var_184_11 then
					render.line(vector((var_184_12 + var_184_14) / 2, var_184_15), var_184_11, color(var_184_16.r, var_184_16.g, var_184_16.b, math.min(var_184_16.a, 150)))
				end

				if var_184_0.text and var_184_0.text:get() then
					local var_184_17 = iter_184_1.tickbase and "DEFENSIVE" or "LAGCOMP BREAKER"
					local var_184_18 = render.measure_text(1, nil, var_184_17)

					render.text(1, vector((var_184_12 + var_184_14) / 2 - var_184_18.x / 2, var_184_13 - 14), color(var_184_16.r, var_184_16.g, var_184_16.b, var_184_16.a), nil, var_184_17)
				end
			end
		end
	end
end

local function var_0_56(arg_185_0, arg_185_1)
	if type(arg_185_0) ~= "table" then
		return arg_185_0 == arg_185_1
	end

	for iter_185_0, iter_185_1 in pairs(arg_185_0) do
		if iter_185_1 == arg_185_1 then
			return true
		end
	end

	return false
end

local function var_0_57()
	local var_186_0, var_186_1 = pcall(function()
		return ui.get_mouse_position()
	end)

	if var_186_0 and var_186_1 then
		return var_186_1
	end

	local var_186_2, var_186_3 = pcall(function()
		return render.mouse_position()
	end)
	local var_186_4 = var_186_3

	if var_186_2 and var_186_4 then
		return var_186_4
	end

	return vector(0, 0)
end

local function var_0_58()
	local var_189_0, var_189_1 = pcall(function()
		return common.is_button_down(1)
	end)

	if var_189_0 then
		return var_189_1
	end

	local var_189_2, var_189_3 = pcall(function()
		return ui.is_mouse_down(0)
	end)
	local var_189_4 = var_189_3

	if var_189_2 then
		return var_189_4
	end

	return false
end

local function var_0_59(arg_192_0, arg_192_1, arg_192_2, arg_192_3, arg_192_4)
	return arg_192_1 <= arg_192_0.x and arg_192_0.x <= arg_192_1 + arg_192_3 and arg_192_2 <= arg_192_0.y and arg_192_0.y <= arg_192_2 + arg_192_4
end

local function var_0_60(arg_193_0, arg_193_1, arg_193_2, arg_193_3, arg_193_4)
	local var_193_0 = var_0_57()
	local var_193_1 = var_0_58()
	local var_193_2 = var_0_25._win_rt

	if var_193_1 and not var_193_2[arg_193_0 .. "_drag"] and var_0_59(var_193_0, arg_193_1, arg_193_2, arg_193_3, arg_193_4) then
		var_193_2[arg_193_0 .. "_drag"] = true
		var_193_2[arg_193_0 .. "_dx"] = var_193_0.x - arg_193_1
		var_193_2[arg_193_0 .. "_dy"] = var_193_0.y - arg_193_2
	end

	if not var_193_1 then
		var_193_2[arg_193_0 .. "_drag"] = false
	end

	if var_193_2[arg_193_0 .. "_drag"] then
		var_193_2[arg_193_0 .. "_x"] = var_193_0.x - (var_193_2[arg_193_0 .. "_dx"] or 0)
		var_193_2[arg_193_0 .. "_y"] = var_193_0.y - (var_193_2[arg_193_0 .. "_dy"] or 0)
	end

	return var_193_2[arg_193_0 .. "_x"] or arg_193_1, var_193_2[arg_193_0 .. "_y"] or arg_193_2
end

local function var_0_61(arg_194_0)
	if not var_0_9.windows then
		return
	end

	pcall(function()
		var_0_9.windows:override(arg_194_0 and {} or nil)
	end)
	pcall(function()
		var_0_9.windows:override(arg_194_0 and "" or nil)
	end)
end

local function var_0_62(arg_197_0)
	return math.max(0, math.min(255, math.floor(arg_197_0 or 0)))
end

local function var_0_63(arg_198_0)
	if type(arg_198_0) ~= "string" then
		return nil
	end

	arg_198_0 = arg_198_0:gsub("^%s+", ""):gsub("%s+$", "")

	if arg_198_0 == "" then
		return nil
	end

	return arg_198_0
end

local function var_0_64(arg_199_0, arg_199_1)
	local var_199_0, var_199_1 = pcall(function()
		return arg_199_0[arg_199_1]
	end)

	if var_199_0 then
		return var_199_1
	end

	return nil
end

local function var_0_65(arg_201_0)
	arg_201_0 = tonumber(arg_201_0) or 0

	if arg_201_0 == 1 then
		return "hold"
	end

	if arg_201_0 == 2 then
		return "on"
	end

	return "on"
end

local function var_0_66(arg_202_0)
	local var_202_0 = var_0_64(arg_202_0, "active")

	if type(var_202_0) == "boolean" then
		return var_202_0
	end

	if type(var_202_0) == "number" then
		return var_202_0 ~= 0
	end

	if type(var_202_0) == "string" then
		local var_202_1 = var_202_0:lower()

		return var_202_1 == "true" or var_202_1 == "on" or var_202_1 == "hold" or var_202_1 == "toggle" or var_202_1 == "active"
	end

	return false
end

local function var_0_67(arg_203_0)
	local var_203_0 = var_0_64(arg_203_0, "name") or var_0_64(arg_203_0, "label") or var_0_64(arg_203_0, "title")

	if var_203_0 == "Double Tap" then
		return "Double Tap"
	end

	if var_203_0 == "Hide Shots" then
		return "Hide Shots"
	end

	if var_203_0 == "Min. Damage" then
		return "Min. Damage"
	end

	if var_203_0 == "Hit Chance" then
		return "Hit Chance"
	end

	if var_203_0 == "Body Aim" then
		return "Body Aim"
	end

	if var_203_0 == "Safe Points" then
		return "Safe Points"
	end

	if var_203_0 == "Multipoint" then
		return "Multipoint"
	end

	return var_0_63(var_203_0)
end

local function var_0_68(arg_204_0)
	local var_204_0 = {}

	if type(arg_204_0) ~= "table" then
		return nil
	end

	for iter_204_0, iter_204_1 in pairs(arg_204_0) do
		if type(iter_204_1) == "string" or type(iter_204_1) == "number" then
			var_204_0[#var_204_0 + 1] = tostring(iter_204_1)
		end
	end

	if #var_204_0 > 0 then
		return table.concat(var_204_0, ", ")
	end

	return nil
end

local function var_0_69(arg_205_0)
	local var_205_0 = var_0_65(var_0_64(arg_205_0, "mode"))
	local var_205_1 = var_0_64(arg_205_0, "value")

	if var_205_1 == nil then
		return var_205_0
	end

	if type(var_205_1) == "boolean" then
		return var_205_0
	end

	if type(var_205_1) == "number" then
		return tostring(var_205_1)
	end

	if type(var_205_1) == "string" then
		if var_205_1 == "" then
			return var_205_0
		end

		local var_205_2 = var_205_1:lower()

		if var_205_2 == "true" or var_205_2 == "false" then
			return var_205_0
		end

		return var_205_1
	end

	if type(var_205_1) == "table" then
		return var_0_68(var_205_1) or var_205_0
	end

	return var_205_0
end

local function var_0_70(arg_206_0, arg_206_1, arg_206_2, arg_206_3, arg_206_4)
	arg_206_2 = var_0_63(arg_206_2)

	if not arg_206_2 then
		return
	end

	arg_206_3 = arg_206_3 or "on"

	local var_206_0 = tostring(arg_206_2):lower() .. "|" .. tostring(arg_206_3):lower()

	if arg_206_1[var_206_0] then
		return
	end

	arg_206_1[var_206_0] = true
	arg_206_0[#arg_206_0 + 1] = {
		arg_206_2,
		tostring(arg_206_3),
		arg_206_4 == true
	}
end

local function var_0_71(arg_207_0, arg_207_1)
	local var_207_0, var_207_1 = pcall(function()
		return ui.get_binds()
	end)

	if not var_207_0 or not var_207_1 then
		return false
	end

	local var_207_2 = false

	for iter_207_0, iter_207_1 in pairs(var_207_1) do
		if var_0_64(iter_207_1, "active") ~= nil then
			var_207_2 = true

			local var_207_3 = var_0_67(iter_207_1)
			local var_207_4 = var_0_69(iter_207_1)
			local var_207_5 = var_0_66(iter_207_1)

			var_0_70(arg_207_0, arg_207_1, var_207_3, var_207_4, var_207_5)
		end
	end

	return var_207_2
end

local function var_0_72(arg_209_0)
	if not arg_209_0 then
		return false
	end

	local var_209_0, var_209_1 = pcall(function()
		return arg_209_0.get and arg_209_0:get()
	end)

	if var_209_0 and type(var_209_1) == "boolean" then
		return var_209_1
	end

	return false
end

local function var_0_73(arg_211_0, arg_211_1, arg_211_2, arg_211_3)
	if arg_211_3 and var_0_72(arg_211_3) then
		var_0_70(arg_211_0, arg_211_1, arg_211_2, "on", true)
	end
end

local function var_0_74()
	local var_212_0 = {}
	local var_212_1 = {}

	if not var_0_71(var_212_0, var_212_1) then
		var_0_73(var_212_0, var_212_1, "Double Tap", var_0_9.antiaim and var_0_9.antiaim.dt)
		var_0_73(var_212_0, var_212_1, "Hide Shots", var_0_9.hideshots)
		var_0_73(var_212_0, var_212_1, "Quick Peek", var_0_9.rage and var_0_9.rage.quickpeek)
		var_0_73(var_212_0, var_212_1, "Fake Duck", var_0_9.antiaim and var_0_9.antiaim.fakedick)
		var_0_73(var_212_0, var_212_1, "Slow Walk", var_0_9.antiaim and var_0_9.antiaim.aa_slowwalk)
		var_0_73(var_212_0, var_212_1, "Freestanding", var_0_9.antiaim and var_0_9.antiaim.freestand)
		var_0_73(var_212_0, var_212_1, "Dormant", var_0_9.dormant)
	end

	return var_212_0
end

local function var_0_75(arg_213_0, arg_213_1)
	return color(arg_213_0.r, arg_213_0.g, arg_213_0.b, math.floor(arg_213_1 or arg_213_0.a))
end

local function var_0_76(arg_214_0, arg_214_1, arg_214_2, arg_214_3, arg_214_4)
	render.rect(vector(arg_214_0, arg_214_1 - 1), vector(arg_214_0 + arg_214_2, arg_214_1), color(arg_214_3.r, arg_214_3.g, arg_214_3.b, math.floor(35 * arg_214_4)), 1)
	render.rect(vector(arg_214_0, arg_214_1 + 1), vector(arg_214_0 + arg_214_2, arg_214_1 + 2), color(arg_214_3.r, arg_214_3.g, arg_214_3.b, math.floor(35 * arg_214_4)), 1)
	render.rect(vector(arg_214_0, arg_214_1), vector(arg_214_0 + arg_214_2, arg_214_1 + 1), color(arg_214_3.r, arg_214_3.g, arg_214_3.b, math.floor(255 * arg_214_4)), 1)
	render.rect(vector(arg_214_0, arg_214_1), vector(arg_214_0 + arg_214_2, arg_214_1 + 1), color(255, 255, 255, math.floor(70 * arg_214_4)), 1)
end

local function var_0_77()
	local var_215_0 = var_0_24.other.visual.windows

	if not var_215_0 or not var_215_0:get() then
		var_0_61(false)

		return
	end

	local var_215_1 = var_215_0.items:get() or {}
	local var_215_2 = var_0_56(var_215_1, "Keybinds")

	var_0_61(var_215_2)

	local var_215_3 = var_0_74()
	local var_215_4 = var_0_25._win_rt

	var_215_4.kb_rows_anim = var_215_4.kb_rows_anim or {}

	local var_215_5 = false

	for iter_215_0, iter_215_1 in pairs(var_215_3) do
		if iter_215_1[3] then
			var_215_5 = true

			break
		end
	end

	local var_215_6 = ui.get_alpha and ui.get_alpha() > 0
	local var_215_7 = var_215_2 and (var_215_5 or var_215_6) and 1 or 0

	var_215_4.kb_alpha = var_0_36(var_215_4.kb_alpha or 0, var_215_7, math.min(1, globals.frametime * 11))

	local var_215_8 = var_215_4.kb_alpha or 0

	if var_215_8 <= 0.01 then
		return
	end

	local var_215_9 = 1
	local var_215_10 = 145
	local var_215_11 = 24
	local var_215_12 = 4
	local var_215_13 = 14
	local var_215_14 = 3
	local var_215_15 = 6
	local var_215_16 = 6
	local var_215_17 = 0
	local var_215_18 = 0

	for iter_215_2, iter_215_3 in pairs(var_215_3) do
		local var_215_19 = iter_215_3[1] .. "|" .. iter_215_3[2]
		local var_215_20 = iter_215_3[3] and 1 or 0

		var_215_4.kb_rows_anim[var_215_19] = var_0_36(var_215_4.kb_rows_anim[var_215_19] or 0, var_215_20, math.min(1, globals.frametime * 13))

		if (var_215_4.kb_rows_anim[var_215_19] or 0) > 0.01 then
			var_215_17 = var_215_17 + 1

			local var_215_21 = render.measure_text(var_215_9, nil, iter_215_3[1]).x
			local var_215_22 = render.measure_text(var_215_9, nil, iter_215_3[2]).x

			var_215_18 = math.max(var_215_18, var_215_21 + var_215_22 + 24)
		end
	end

	local var_215_23 = math.max(var_215_10, var_215_18)
	local var_215_24 = var_215_17 > 0 and var_215_15 + var_215_16 + var_215_17 * var_215_13 + math.max(0, var_215_17 - 1) * var_215_14 or 0

	var_215_4.kb_h = var_0_36(var_215_4.kb_h or 0, var_215_24, math.min(1, globals.frametime * 10))

	local var_215_25 = var_215_4.kb_h or 0
	local var_215_26 = var_215_11 + var_215_12 + var_215_25
	local var_215_27, var_215_28 = var_0_60("kb", var_215_4.kb_x or 45, var_215_4.kb_y or 285, var_215_23, var_215_26)

	var_215_4.kb_x = var_215_27
	var_215_4.kb_y = var_215_28

	local var_215_29 = var_215_0.bg_style:get()
	local var_215_30 = var_215_29 == "White" or var_215_29 == 2
	local var_215_31 = var_215_0.glow_color:get()
	local var_215_32 = var_215_0.text_color and var_215_0.text_color:get() or nil
	local var_215_33 = var_215_30 and color(245, 245, 245, 220) or color(8, 12, 17, 235)
	local var_215_34 = var_215_30 and color(225, 225, 225, 160) or color(4, 6, 9, 175)
	local var_215_35 = var_215_32 or var_215_30 and color(15, 15, 15, 245) or color(245, 245, 245, 245)
	local var_215_36 = var_215_32 or var_215_30 and color(25, 25, 25, 235) or color(235, 235, 235, 235)
	local var_215_37 = var_215_30 and color(170, 170, 170, 45) or color(0, 0, 0, 105)

	render.rect(vector(var_215_27 + 1, var_215_28 + 1), vector(var_215_27 + var_215_23 + 1, var_215_28 + var_215_11 + 1), color(var_215_37.r, var_215_37.g, var_215_37.b, var_0_62(var_215_37.a * var_215_8)), 3)
	render.rect(vector(var_215_27, var_215_28), vector(var_215_27 + var_215_23, var_215_28 + var_215_11), color(var_215_33.r, var_215_33.g, var_215_33.b, var_0_62(var_215_33.a * var_215_8)), 3)

	local var_215_38 = "keybinds"
	local var_215_39 = render.measure_text(var_215_9, nil, var_215_38)

	render.text(var_215_9, vector(var_215_27 + var_215_23 / 2 - var_215_39.x / 2, var_215_28 + var_215_11 / 2 - var_215_39.y / 2), color(var_215_35.r, var_215_35.g, var_215_35.b, var_0_62((var_215_35.a or 245) * var_215_8)), nil, var_215_38)
	var_0_76(var_215_27 + 1, var_215_28 + var_215_11, var_215_23 - 2, var_215_31, var_215_8)

	local var_215_40 = var_215_28 + var_215_11 + var_215_12

	if var_215_25 > 1 then
		render.rect(vector(var_215_27 + 1, var_215_40 + 1), vector(var_215_27 + var_215_23 + 1, var_215_40 + var_215_25 + 1), color(var_215_37.r, var_215_37.g, var_215_37.b, var_0_62(var_215_37.a * var_215_8)), 2)
		render.rect(vector(var_215_27, var_215_40), vector(var_215_27 + var_215_23, var_215_40 + var_215_25), color(var_215_34.r, var_215_34.g, var_215_34.b, var_0_62(var_215_34.a * var_215_8)), 2)
	end

	local var_215_41 = var_215_40 + var_215_15

	for iter_215_4, iter_215_5 in pairs(var_215_3) do
		local var_215_42 = iter_215_5[1] .. "|" .. iter_215_5[2]
		local var_215_43 = var_215_4.kb_rows_anim[var_215_42] or 0

		if var_215_43 > 0.01 then
			local var_215_44 = var_215_43 * var_215_8
			local var_215_45 = (1 - var_215_43) * 6
			local var_215_46 = iter_215_5[1]
			local var_215_47 = iter_215_5[2]

			if var_215_41 + var_215_13 <= var_215_40 + var_215_25 + 2 then
				render.text(var_215_9, vector(var_215_27 + 7 - var_215_45, var_215_41), color(var_215_36.r, var_215_36.g, var_215_36.b, var_0_62((var_215_36.a or 235) * var_215_44)), nil, var_215_46)

				local var_215_48 = render.measure_text(var_215_9, nil, var_215_47).x

				render.text(var_215_9, vector(var_215_27 + var_215_23 - var_215_48 - 8 + var_215_45, var_215_41), color(var_215_31.r, var_215_31.g, var_215_31.b, var_0_62(245 * var_215_44)), nil, var_215_47)
			end

			var_215_41 = var_215_41 + (var_215_13 + var_215_14) * var_215_43
		end
	end

	for iter_215_6, iter_215_7 in pairs(var_215_4.kb_rows_anim) do
		local var_215_49 = false

		for iter_215_8, iter_215_9 in pairs(var_215_3) do
			if iter_215_6 == iter_215_9[1] .. "|" .. iter_215_9[2] then
				var_215_49 = true

				break
			end
		end

		if not var_215_49 then
			var_215_4.kb_rows_anim[iter_215_6] = var_0_36(var_215_4.kb_rows_anim[iter_215_6] or 0, 0, math.min(1, globals.frametime * 13))

			if var_215_4.kb_rows_anim[iter_215_6] <= 0.01 then
				var_215_4.kb_rows_anim[iter_215_6] = nil
			end
		end
	end
end

WS_WATERMARK = {
	fonts = {
		title = render.load_font("Verdana", 14, "bad"),
		info = render.load_font("Verdana", 12, "ad")
	}
}

function WS_WATERMARK.lerp(arg_216_0, arg_216_1, arg_216_2, arg_216_3)
	return arg_216_1 + (arg_216_2 - arg_216_1) * arg_216_3
end

function WS_WATERMARK.now(arg_217_0)
	return globals.realtime or 0
end

function WS_WATERMARK.a(arg_218_0, arg_218_1)
	return math.max(0, math.min(255, math.floor(arg_218_1 or 0)))
end

function WS_WATERMARK.fmt_time(arg_219_0, arg_219_1)
	arg_219_1 = math.max(0, math.floor(arg_219_1 or 0))

	local var_219_0 = math.floor(arg_219_1 / 3600)
	local var_219_1 = math.floor(arg_219_1 % 3600 / 60)
	local var_219_2 = arg_219_1 % 60

	if var_219_0 > 0 then
		return string.format("%02d:%02d:%02d", var_219_0, var_219_1, var_219_2)
	end

	return string.format("%02d:%02d", var_219_1, var_219_2)
end

function WS_WATERMARK.ping(arg_220_0)
	local var_220_0 = var_0_25._win_rt
	local var_220_1 = arg_220_0:now()

	if var_220_0.wm_next_ping and var_220_1 < var_220_0.wm_next_ping and var_220_0.wm_ping then
		return var_220_0.wm_ping
	end

	local var_220_2 = 0
	local var_220_3, var_220_4 = pcall(function()
		return utils.net_channel()
	end)

	if var_220_3 and var_220_4 then
		pcall(function()
			var_220_2 = (var_220_4.avg_latency[1] or 0) * 1000
		end)
	end

	var_220_0.wm_ping = tostring(math.floor(math.max(0, var_220_2))) .. "ms"
	var_220_0.wm_next_ping = var_220_1 + 0.5

	return var_220_0.wm_ping
end

function WS_WATERMARK.steam_name(arg_223_0)
	local var_223_0 = var_0_25._win_rt
	local var_223_1 = arg_223_0:now()

	if var_223_0.wm_next_name and var_223_1 < var_223_0.wm_next_name and var_223_0.wm_steam_name then
		return var_223_0.wm_steam_name
	end

	local var_223_2 = entity.get_local_player()
	local var_223_3

	if var_223_2 then
		pcall(function()
			var_223_3 = var_223_2:get_name()
		end)
	end

	if not var_223_3 or var_223_3 == "" then
		var_223_3 = common.get_username()
	end

	var_223_0.wm_steam_name = var_223_3
	var_223_0.wm_next_name = var_223_1 + 2

	return var_223_3
end

function WS_WATERMARK.nickname(arg_225_0, arg_225_1)
	local var_225_0 = arg_225_1.nickname_source and arg_225_1.nickname_source:get() or "Neverlose"

	if var_225_0 == "Steam" or var_225_0 == 2 then
		return arg_225_0:steam_name()
	end

	return common.get_username()
end

function WS_WATERMARK.style_cols(arg_226_0, arg_226_1, arg_226_2)
	local var_226_0 = arg_226_1.bg_style:get()
	local var_226_1 = var_226_0 == "White" or var_226_0 == 2
	local var_226_2 = var_226_1 and color(245, 245, 245, math.floor(220 * arg_226_2)) or color(8, 12, 17, math.floor(235 * arg_226_2))
	local var_226_3 = var_226_1 and color(225, 225, 225, math.floor(160 * arg_226_2)) or color(4, 6, 9, math.floor(175 * arg_226_2))
	local var_226_4 = arg_226_1.text_color and arg_226_1.text_color:get() or var_226_1 and color(15, 15, 15, 245) or color(245, 245, 245, 245)
	local var_226_5 = arg_226_1.glow_color:get()

	return var_226_2, var_226_3, color(var_226_4.r, var_226_4.g, var_226_4.b, math.floor((var_226_4.a or 245) * arg_226_2)), var_226_5, var_226_1
end

function WS_WATERMARK.base_color(arg_227_0, arg_227_1)
	if arg_227_1 then
		return color(255, 255, 255, 255)
	end

	return color(0, 0, 0, 255)
end

function WS_WATERMARK.has_item(arg_228_0, arg_228_1, arg_228_2)
	local var_228_0 = arg_228_1.watermark_items and arg_228_1.watermark_items:get() or {}

	return var_0_56(var_228_0, arg_228_2)
end

function WS_WATERMARK.second_text(arg_229_0, arg_229_1)
	local var_229_0 = var_0_25._win_rt
	local var_229_1 = arg_229_0:now()

	if var_229_0.wm_next_info and var_229_1 < var_229_0.wm_next_info and var_229_0.wm_info then
		return var_229_0.wm_info
	end

	local var_229_2 = {}

	if arg_229_0:has_item(arg_229_1, "Nickname") then
		var_229_2[#var_229_2 + 1] = ui.get_icon("user") .. " " .. arg_229_0:nickname(arg_229_1)
	end

	if arg_229_0:has_item(arg_229_1, "Ping") then
		var_229_2[#var_229_2 + 1] = ui.get_icon("wifi") .. " " .. arg_229_0:ping()
	end

	if arg_229_0:has_item(arg_229_1, "Session Time") then
		var_229_2[#var_229_2 + 1] = ui.get_icon("clock") .. " " .. arg_229_0:fmt_time(var_229_1)
	end

	var_229_0.wm_info = table.concat(var_229_2, "   ")
	var_229_0.wm_next_info = var_229_1 + 0.25

	return var_229_0.wm_info
end

function WS_WATERMARK.flow_stable(arg_230_0, arg_230_1, arg_230_2, arg_230_3, arg_230_4, arg_230_5, arg_230_6)
	local var_230_0, var_230_1, var_230_2, var_230_3, var_230_4 = arg_230_0:style_cols(arg_230_4, 1)
	local var_230_5 = arg_230_0:base_color(var_230_4)
	local var_230_6 = arg_230_4.wm_speed and (tonumber(arg_230_4.wm_speed:get()) or 8) or 8
	local var_230_7 = 0.34
	local var_230_8 = 0.62
	local var_230_9 = arg_230_2
	local var_230_10 = render.measure_text(arg_230_1, nil, arg_230_5).x
	local var_230_11 = arg_230_0:now() * var_230_6 % 1

	for iter_230_0 = 1, #arg_230_5 do
		local var_230_12 = arg_230_5:sub(iter_230_0, iter_230_0)
		local var_230_13 = render.measure_text(arg_230_1, nil, var_230_12).x
		local var_230_14 = ((var_230_10 > 0 and (var_230_9 - arg_230_2 + var_230_13 * 0.5) / var_230_10 or 0) - var_230_11) % 1

		if var_230_14 > 0.5 then
			var_230_14 = 1 - var_230_14
		end

		local var_230_15 = math.max(0, 1 - var_230_14 / var_230_8)
		local var_230_16 = math.pow(var_230_15, var_230_7)
		local var_230_17 = var_230_5:lerp(var_230_3, var_230_16)

		render.text(arg_230_1, vector(var_230_9, arg_230_3), color(var_230_17.r, var_230_17.g, var_230_17.b, arg_230_0:a(255 * arg_230_6)), nil, var_230_12)

		var_230_9 = var_230_9 + var_230_13
	end
end

function WS_WATERMARK.box(arg_231_0, arg_231_1, arg_231_2, arg_231_3, arg_231_4, arg_231_5, arg_231_6, arg_231_7, arg_231_8)
	render.rect(vector(arg_231_1 + 1, arg_231_2 + 1), vector(arg_231_1 + arg_231_3 + 1, arg_231_2 + arg_231_4 + 1), color(arg_231_6.r, arg_231_6.g, arg_231_6.b, arg_231_0:a(arg_231_6.a * arg_231_7)), arg_231_8 or 3)
	render.rect(vector(arg_231_1, arg_231_2), vector(arg_231_1 + arg_231_3, arg_231_2 + arg_231_4), arg_231_5, arg_231_8 or 3)
end

function WS_WATERMARK.draw(arg_232_0)
	local var_232_0 = var_0_24.other.visual.windows

	if not var_232_0 or not var_232_0:get() then
		return
	end

	local var_232_1 = var_232_0.items:get() or {}
	local var_232_2 = var_0_56(var_232_1, "Watermark")
	local var_232_3 = var_0_25._win_rt

	var_232_3.wm_alpha = arg_232_0:lerp(var_232_3.wm_alpha or 0, var_232_2 and 1 or 0, math.min(1, globals.frametime * 11))

	local var_232_4 = var_232_3.wm_alpha or 0

	if var_232_4 <= 0.01 then
		return
	end

	local var_232_5 = arg_232_0.fonts.title
	local var_232_6 = arg_232_0.fonts.info
	local var_232_7, var_232_8, var_232_9, var_232_10, var_232_11 = arg_232_0:style_cols(var_232_0, var_232_4)
	local var_232_12 = var_232_11 and color(170, 170, 170, 45) or color(0, 0, 0, 105)
	local var_232_13 = "Whitestrike "
	local var_232_14 = "Stable"
	local var_232_15 = render.measure_text(var_232_5, nil, var_232_13)
	local var_232_16 = render.measure_text(var_232_5, nil, var_232_14)
	local var_232_17 = 25
	local var_232_18 = 9
	local var_232_19 = math.floor(var_232_15.x + var_232_16.x + var_232_18 * 2)
	local var_232_20 = arg_232_0:second_text(var_232_0)
	local var_232_21 = render.measure_text(var_232_6, nil, var_232_20)
	local var_232_22 = 25
	local var_232_23 = var_232_20 ~= "" and math.floor(var_232_21.x + var_232_18 * 2) or 0
	local var_232_24 = var_232_0.distance and var_232_0.distance:get() or 5
	local var_232_25 = var_232_19 + (var_232_23 > 0 and var_232_24 + var_232_23 or 0)
	local var_232_26 = math.max(var_232_17, var_232_22)
	local var_232_27 = render.screen_size()

	var_232_3.wm_x = math.max(0, math.min(var_232_27.x - var_232_25, tonumber(var_232_3.wm_x) or 35))
	var_232_3.wm_y = math.max(0, math.min(var_232_27.y - var_232_26, tonumber(var_232_3.wm_y) or 35))

	local var_232_28, var_232_29 = var_0_60("wm", var_232_3.wm_x, var_232_3.wm_y, var_232_25, var_232_26)

	var_232_3.wm_x = math.max(0, math.min(var_232_27.x - var_232_25, var_232_28))
	var_232_3.wm_y = math.max(0, math.min(var_232_27.y - var_232_26, var_232_29))
	var_232_3.wm_w = var_232_25

	local var_232_30 = var_232_3.wm_x
	local var_232_31 = var_232_3.wm_y

	arg_232_0:box(var_232_30, var_232_31, var_232_19, var_232_17, var_232_7, var_232_12, var_232_4, 3)

	local var_232_32 = var_232_31 + var_232_17 / 2 - var_232_15.y / 2

	render.text(var_232_5, vector(var_232_30 + var_232_18, var_232_32), var_232_9, nil, var_232_13)
	arg_232_0:flow_stable(var_232_5, var_232_30 + var_232_18 + var_232_15.x, var_232_32, var_232_0, var_232_14, var_232_4)
	var_0_76(var_232_30 + 1, var_232_31 + var_232_17, var_232_19 - 2, var_232_10, var_232_4)

	if var_232_23 > 0 then
		local var_232_33 = var_232_30 + var_232_19 + var_232_24

		arg_232_0:box(var_232_33, var_232_31, var_232_23, var_232_22, var_232_8, var_232_12, var_232_4, 3)
		render.text(var_232_6, vector(var_232_33 + var_232_18, var_232_31 + var_232_22 / 2 - var_232_21.y / 2), var_232_9, nil, var_232_20)
		var_0_76(var_232_33 + 1, var_232_31 + var_232_22, var_232_23 - 2, var_232_10, var_232_4)
	end
end

local var_0_78 = {
	small = 1,
	title = render.load_font("Verdana", 13, "bad"),
	value = render.load_font("Verdana", 12, "ad")
}

local function var_0_79()
	local var_233_0 = entity.get_local_player()

	if not var_233_0 or not var_233_0:is_alive() then
		return 0, 0, 250
	end

	local var_233_1 = 0
	local var_233_2 = 0

	pcall(function()
		var_233_1 = var_233_0.m_vecVelocity.x or 0
		var_233_2 = var_233_0.m_vecVelocity.y or 0
	end)

	local var_233_3 = math.sqrt(var_233_1 * var_233_1 + var_233_2 * var_233_2)
	local var_233_4 = 250
	local var_233_5 = var_233_0:get_player_weapon()

	pcall(function()
		local var_235_0 = var_233_5 and var_233_5:get_weapon_info() or nil

		if var_235_0 then
			var_233_4 = var_235_0.max_speed or var_235_0.flMaxSpeed or var_235_0.max_player_speed or var_233_4
		end
	end)

	if var_0_9.antiaim and var_0_9.antiaim.aa_slowwalk and var_0_9.antiaim.aa_slowwalk:get() then
		var_233_4 = 100
	end

	local var_233_6 = math.max(0, math.min(1, var_233_3 / math.max(var_233_4, 1)))
	local var_233_7 = math.floor(var_233_6 * 100 + 0.5)

	return var_233_3, var_233_7, var_233_4
end

local function var_0_80(arg_236_0, arg_236_1, arg_236_2, arg_236_3, arg_236_4, arg_236_5, arg_236_6)
	arg_236_4 = math.max(0, math.min(1, arg_236_4 or 0))

	render.rect(vector(arg_236_0, arg_236_1), vector(arg_236_0 + arg_236_2, arg_236_1 + arg_236_3), color(0, 0, 0, math.floor(95 * arg_236_6)), arg_236_3 / 2)
	render.rect(vector(arg_236_0, arg_236_1), vector(arg_236_0 + arg_236_2 * arg_236_4, arg_236_1 + arg_236_3), color(arg_236_5.r, arg_236_5.g, arg_236_5.b, math.floor(45 * arg_236_6)), arg_236_3 / 2)
	render.rect(vector(arg_236_0, arg_236_1 - 1), vector(arg_236_0 + arg_236_2 * arg_236_4, arg_236_1 + arg_236_3 + 1), color(arg_236_5.r, arg_236_5.g, arg_236_5.b, math.floor(35 * arg_236_6)), arg_236_3 / 2)
	render.rect(vector(arg_236_0, arg_236_1), vector(arg_236_0 + arg_236_2 * arg_236_4, arg_236_1 + arg_236_3), color(arg_236_5.r, arg_236_5.g, arg_236_5.b, math.floor(230 * arg_236_6)), arg_236_3 / 2)
	render.rect(vector(arg_236_0, arg_236_1), vector(arg_236_0 + arg_236_2 * arg_236_4, arg_236_1 + 1), color(255, 255, 255, math.floor(65 * arg_236_6)), 1)
end

local function var_0_81()
	local var_237_0 = var_0_24.other.visual.windows

	if not var_237_0 or not var_237_0:get() then
		return
	end

	local var_237_1 = var_237_0.items:get() or {}
	local var_237_2 = var_0_56(var_237_1, "Velocity Indicators")
	local var_237_3 = entity.get_local_player()
	local var_237_4 = var_237_3 and var_237_3:is_alive()
	local var_237_5, var_237_6, var_237_7 = var_0_79()
	local var_237_8 = false

	pcall(function()
		var_237_8 = ui.get_alpha() > 0.01
	end)

	local var_237_9 = var_237_2 and var_237_4 and (var_237_6 >= 88 or var_237_8)
	local var_237_10 = var_0_25._win_rt

	var_237_10.vel_alpha = var_0_36(var_237_10.vel_alpha or 0, var_237_9 and 1 or 0, math.min(1, globals.frametime * 11))

	local var_237_11 = var_237_10.vel_alpha or 0

	if var_237_11 <= 0.01 then
		return
	end

	var_237_10.vel_speed = var_0_36(var_237_10.vel_speed or 0, var_237_5, math.min(1, globals.frametime * 16))

	local var_237_12 = var_237_10.vel_speed or var_237_5
	local var_237_13 = math.max(0, math.min(1, var_237_12 / math.max(var_237_7, 1)))
	local var_237_14 = math.floor(var_237_13 * 100 + 0.5)
	local var_237_15 = var_237_0.bg_style:get()
	local var_237_16 = var_237_15 == "White" or var_237_15 == 2
	local var_237_17 = var_237_0.glow_color:get()
	local var_237_18 = var_237_0.text_color and var_237_0.text_color:get() or nil
	local var_237_19 = var_237_16 and color(245, 245, 245, 220) or color(8, 12, 17, 235)
	local var_237_20 = var_237_16 and color(225, 225, 225, 145) or color(4, 6, 9, 165)
	local var_237_21 = var_237_18 or var_237_16 and color(15, 15, 15, 245) or color(245, 245, 245, 245)
	local var_237_22 = var_237_16 and color(35, 35, 35, 210) or color(210, 210, 210, 210)
	local var_237_23 = var_237_16 and color(170, 170, 170, 45) or color(0, 0, 0, 105)
	local var_237_24 = 168
	local var_237_25 = 48
	local var_237_26, var_237_27 = var_0_60("vel", var_237_10.vel_x or 35, var_237_10.vel_y or 75, var_237_24, var_237_25)

	var_237_10.vel_x = var_237_26
	var_237_10.vel_y = var_237_27

	render.rect(vector(var_237_26 + 1, var_237_27 + 1), vector(var_237_26 + var_237_24 + 1, var_237_27 + var_237_25 + 1), color(var_237_23.r, var_237_23.g, var_237_23.b, var_0_62(var_237_23.a * var_237_11)), 4)
	render.rect(vector(var_237_26, var_237_27), vector(var_237_26 + var_237_24, var_237_27 + var_237_25), color(var_237_19.r, var_237_19.g, var_237_19.b, var_0_62(var_237_19.a * var_237_11)), 4)
	render.rect(vector(var_237_26 + 5, var_237_27 + 23), vector(var_237_26 + var_237_24 - 5, var_237_27 + var_237_25 - 5), color(var_237_20.r, var_237_20.g, var_237_20.b, var_0_62(var_237_20.a * var_237_11)), 3)

	local var_237_28 = "velocity"

	render.text(var_0_78.title, vector(var_237_26 + 8, var_237_27 + 6), color(var_237_21.r, var_237_21.g, var_237_21.b, var_0_62((var_237_21.a or 245) * var_237_11)), nil, var_237_28)

	local var_237_29 = tostring(var_237_14) .. "% "
	local var_237_30 = render.measure_text(var_0_78.title, nil, var_237_29)

	render.text(var_0_78.title, vector(var_237_26 + var_237_24 - var_237_30.x - 8, var_237_27 + 6), color(var_237_17.r, var_237_17.g, var_237_17.b, var_0_62(255 * var_237_11)), nil, var_237_29)

	local var_237_31 = var_237_26 + 8
	local var_237_32 = var_237_27 + 29
	local var_237_33 = var_237_24 - 16
	local var_237_34 = 5

	var_0_80(var_237_31, var_237_32, var_237_33, var_237_34, var_237_13, var_237_17, var_237_11)

	local var_237_35 = tostring(math.floor(var_237_12 + 0.5)) .. " / " .. tostring(math.floor(var_237_7 + 0.5)) .. " u/s"

	render.text(var_0_78.small, vector(var_237_26 + 8, var_237_27 + 37), color(var_237_22.r, var_237_22.g, var_237_22.b, var_0_62(var_237_22.a * var_237_11)), nil, var_237_35)

	local var_237_36 = var_237_14 >= 88 and "fast" or var_237_14 >= 35 and "move" or "slow"
	local var_237_37 = render.measure_text(var_0_78.small, nil, var_237_36)

	render.text(var_0_78.small, vector(var_237_26 + var_237_24 - var_237_37.x - 8, var_237_27 + 37), color(var_237_17.r, var_237_17.g, var_237_17.b, var_0_62(220 * var_237_11)), nil, var_237_36)
	var_0_76(var_237_26 + 1, var_237_27 + var_237_25, var_237_24 - 2, var_237_17, var_237_11)
end

local var_0_82 = {
	title = render.load_font("Verdana", 13, "bad"),
	name = render.load_font("Verdana", 12, "ad"),
	small = render.load_font("Verdana", 11, "a")
}

local function var_0_83()
	local var_239_0 = entity.get_local_player()

	if not var_239_0 then
		return {}
	end

	local var_239_1 = {}
	local var_239_2, var_239_3 = pcall(function()
		if var_239_0:is_alive() then
			return var_239_0:get_spectators()
		end

		local var_240_0 = var_239_0.m_hObserverTarget

		if var_240_0 ~= nil then
			return var_240_0:get_spectators()
		end

		return {}
	end)

	if var_239_2 and type(var_239_3) == "table" then
		for iter_239_0, iter_239_1 in pairs(var_239_3) do
			local var_239_4 = "unknown"
			local var_239_5

			pcall(function()
				var_239_4 = iter_239_1:get_name() or "unknown"
			end)
			pcall(function()
				var_239_5 = iter_239_1:get_steam_avatar()
			end)

			var_239_1[#var_239_1 + 1] = {
				name = var_239_4,
				avatar = var_239_5
			}
		end
	end

	return var_239_1
end

local function var_0_84(arg_243_0, arg_243_1, arg_243_2, arg_243_3)
	if arg_243_0 and pcall(function()
		render.texture(arg_243_0, vector(arg_243_1, arg_243_2), vector(16, 16), color(255, 255, 255, var_0_62(255 * arg_243_3)), "", 4)
	end) then
		return
	end

	render.rect(vector(arg_243_1, arg_243_2), vector(arg_243_1 + 16, arg_243_2 + 16), color(255, 255, 255, var_0_62(18 * arg_243_3)), 4)
	render.text(1, vector(arg_243_1 + 4, arg_243_2 + 2), color(255, 255, 255, var_0_62(180 * arg_243_3)), nil, "?")
end

local function var_0_85()
	local var_245_0 = var_0_24.other.visual.windows

	if not var_245_0 or not var_245_0:get() then
		return
	end

	local var_245_1 = var_245_0.items:get() or {}
	local var_245_2 = var_0_56(var_245_1, "Spectators")
	local var_245_3 = var_0_83()
	local var_245_4 = var_0_25._win_rt

	var_245_4.spec_rows_anim = var_245_4.spec_rows_anim or {}

	local var_245_5 = ui.get_alpha and ui.get_alpha() > 0
	local var_245_6 = var_245_2 and (#var_245_3 > 0 or var_245_5)

	var_245_4.spec_alpha = var_0_36(var_245_4.spec_alpha or 0, var_245_6 and 1 or 0, math.min(1, globals.frametime * 11))

	local var_245_7 = var_245_4.spec_alpha or 0

	if var_245_7 <= 0.01 then
		return
	end

	local var_245_8 = var_245_0.bg_style:get()
	local var_245_9 = var_245_8 == "White" or var_245_8 == 2
	local var_245_10 = var_245_0.glow_color:get()
	local var_245_11 = var_245_0.text_color and var_245_0.text_color:get() or nil
	local var_245_12 = var_245_9 and color(245, 245, 245, 220) or color(8, 12, 17, 235)
	local var_245_13 = var_245_9 and color(225, 225, 225, 155) or color(4, 6, 9, 175)
	local var_245_14 = var_245_11 or var_245_9 and color(15, 15, 15, 245) or color(245, 245, 245, 245)
	local var_245_15 = var_245_11 or var_245_9 and color(25, 25, 25, 235) or color(235, 235, 235, 235)
	local var_245_16 = var_245_9 and color(40, 40, 40, 190) or color(190, 190, 190, 190)
	local var_245_17 = var_245_9 and color(170, 170, 170, 45) or color(0, 0, 0, 105)
	local var_245_18 = 168
	local var_245_19 = 24
	local var_245_20 = 4
	local var_245_21 = 22
	local var_245_22 = 3
	local var_245_23 = 6
	local var_245_24 = 6
	local var_245_25 = 0

	for iter_245_0, iter_245_1 in pairs(var_245_3) do
		local var_245_26 = iter_245_1.name

		var_245_4.spec_rows_anim[var_245_26] = var_0_36(var_245_4.spec_rows_anim[var_245_26] or 0, 1, math.min(1, globals.frametime * 13))

		if (var_245_4.spec_rows_anim[var_245_26] or 0) > 0.01 then
			var_245_25 = var_245_25 + 1

			local var_245_27 = render.measure_text(var_0_82.name, nil, iter_245_1.name).x

			var_245_18 = math.max(var_245_18, var_245_27 + 54)
		end
	end

	for iter_245_2, iter_245_3 in pairs(var_245_4.spec_rows_anim) do
		local var_245_28 = false

		for iter_245_4, iter_245_5 in pairs(var_245_3) do
			if iter_245_5.name == iter_245_2 then
				var_245_28 = true

				break
			end
		end

		if not var_245_28 then
			var_245_4.spec_rows_anim[iter_245_2] = var_0_36(iter_245_3 or 0, 0, math.min(1, globals.frametime * 13))

			if var_245_4.spec_rows_anim[iter_245_2] <= 0.01 then
				var_245_4.spec_rows_anim[iter_245_2] = nil
			end

			var_245_25 = var_245_25 + 1
		end
	end

	local var_245_29 = var_245_25 > 0 and var_245_23 + var_245_24 + var_245_25 * var_245_21 + math.max(0, var_245_25 - 1) * var_245_22 or 0

	var_245_4.spec_h = var_0_36(var_245_4.spec_h or 0, var_245_29, math.min(1, globals.frametime * 10))

	local var_245_30 = var_245_4.spec_h or 0
	local var_245_31 = var_245_19 + var_245_20 + var_245_30
	local var_245_32, var_245_33 = var_0_60("spec", var_245_4.spec_x or 35, var_245_4.spec_y or 130, var_245_18, var_245_31)

	var_245_4.spec_x = var_245_32
	var_245_4.spec_y = var_245_33

	render.rect(vector(var_245_32 + 1, var_245_33 + 1), vector(var_245_32 + var_245_18 + 1, var_245_33 + var_245_19 + 1), color(var_245_17.r, var_245_17.g, var_245_17.b, var_0_62(var_245_17.a * var_245_7)), 3)
	render.rect(vector(var_245_32, var_245_33), vector(var_245_32 + var_245_18, var_245_33 + var_245_19), color(var_245_12.r, var_245_12.g, var_245_12.b, var_0_62(var_245_12.a * var_245_7)), 3)

	local var_245_34 = "spectators"
	local var_245_35 = render.measure_text(var_0_82.title, nil, var_245_34)

	render.text(var_0_82.title, vector(var_245_32 + 8, var_245_33 + var_245_19 / 2 - var_245_35.y / 2), color(var_245_14.r, var_245_14.g, var_245_14.b, var_0_62((var_245_14.a or 245) * var_245_7)), nil, var_245_34)

	local var_245_36 = tostring(#var_245_3)
	local var_245_37 = render.measure_text(var_0_82.title, nil, var_245_36)

	render.text(var_0_82.title, vector(var_245_32 + var_245_18 - var_245_37.x - 8, var_245_33 + var_245_19 / 2 - var_245_37.y / 2), color(var_245_10.r, var_245_10.g, var_245_10.b, var_0_62(255 * var_245_7)), nil, var_245_36)
	var_0_76(var_245_32 + 1, var_245_33 + var_245_19, var_245_18 - 2, var_245_10, var_245_7)

	local var_245_38 = var_245_33 + var_245_19 + var_245_20

	if var_245_30 > 1 then
		render.rect(vector(var_245_32 + 1, var_245_38 + 1), vector(var_245_32 + var_245_18 + 1, var_245_38 + var_245_30 + 1), color(var_245_17.r, var_245_17.g, var_245_17.b, var_0_62(var_245_17.a * var_245_7)), 2)
		render.rect(vector(var_245_32, var_245_38), vector(var_245_32 + var_245_18, var_245_38 + var_245_30), color(var_245_13.r, var_245_13.g, var_245_13.b, var_0_62(var_245_13.a * var_245_7)), 2)
	end

	local var_245_39 = var_245_38 + var_245_23

	for iter_245_6, iter_245_7 in pairs(var_245_3) do
		local var_245_40 = var_245_4.spec_rows_anim[iter_245_7.name] or 0

		if var_245_40 > 0.01 then
			local var_245_41 = var_245_40 * var_245_7
			local var_245_42 = (1 - var_245_40) * 7

			var_0_84(iter_245_7.avatar, var_245_32 + 7 - var_245_42, var_245_39 + 2, var_245_41)
			render.text(var_0_82.name, vector(var_245_32 + 29 - var_245_42, var_245_39 + 2), color(var_245_15.r, var_245_15.g, var_245_15.b, var_0_62((var_245_15.a or 235) * var_245_41)), nil, iter_245_7.name)
			render.text(var_0_82.small, vector(var_245_32 + 29 - var_245_42, var_245_39 + 13), color(var_245_16.r, var_245_16.g, var_245_16.b, var_0_62(var_245_16.a * var_245_41)), nil, "watching you")

			var_245_39 = var_245_39 + (var_245_21 + var_245_22) * var_245_40
		end
	end
end

local function var_0_86(arg_246_0, arg_246_1, arg_246_2, arg_246_3, arg_246_4, arg_246_5, arg_246_6)
	arg_246_6 = arg_246_6 or 32

	local var_246_0 = arg_246_2 - arg_246_0
	local var_246_1 = arg_246_3 - arg_246_1
	local var_246_2 = math.abs(var_246_0) >= math.abs(var_246_1)

	local function var_246_3(arg_247_0, arg_247_1)
		return color(arg_247_0.r, arg_247_0.g, arg_247_0.b, math.max(0, math.min(255, arg_247_0.a * arg_247_1)))
	end

	if var_246_2 then
		var_0_47(arg_246_0, arg_246_1 - 2, arg_246_2, arg_246_3 - 2, var_246_3(arg_246_4, 0.12), var_246_3(arg_246_5, 0.12), arg_246_6)
		var_0_47(arg_246_0, arg_246_1 + 2, arg_246_2, arg_246_3 + 2, var_246_3(arg_246_4, 0.12), var_246_3(arg_246_5, 0.12), arg_246_6)
		var_0_47(arg_246_0, arg_246_1 - 1, arg_246_2, arg_246_3 - 1, var_246_3(arg_246_4, 0.28), var_246_3(arg_246_5, 0.28), arg_246_6)
		var_0_47(arg_246_0, arg_246_1 + 1, arg_246_2, arg_246_3 + 1, var_246_3(arg_246_4, 0.28), var_246_3(arg_246_5, 0.28), arg_246_6)
	else
		var_0_47(arg_246_0 - 2, arg_246_1, arg_246_2 - 2, arg_246_3, var_246_3(arg_246_4, 0.12), var_246_3(arg_246_5, 0.12), arg_246_6)
		var_0_47(arg_246_0 + 2, arg_246_1, arg_246_2 + 2, arg_246_3, var_246_3(arg_246_4, 0.12), var_246_3(arg_246_5, 0.12), arg_246_6)
		var_0_47(arg_246_0 - 1, arg_246_1, arg_246_2 - 1, arg_246_3, var_246_3(arg_246_4, 0.28), var_246_3(arg_246_5, 0.28), arg_246_6)
		var_0_47(arg_246_0 + 1, arg_246_1, arg_246_2 + 1, arg_246_3, var_246_3(arg_246_4, 0.28), var_246_3(arg_246_5, 0.28), arg_246_6)
	end

	var_0_47(arg_246_0, arg_246_1, arg_246_2, arg_246_3, arg_246_4, arg_246_5, arg_246_6)
	var_0_47(arg_246_0, arg_246_1, arg_246_2, arg_246_3, var_246_3(arg_246_4, 0.85), var_246_3(arg_246_5, 0.85), arg_246_6)
end

local function var_0_87(arg_248_0)
	if not var_0_9.scope_overlay then
		return
	end

	var_0_25._scp_rt.overlay_active = var_0_25._scp_rt.overlay_active or false

	if arg_248_0 then
		if var_0_25._scp_rt.overlay_active then
			return
		end

		var_0_25._scp_rt.overlay_active = true

		if not pcall(function()
			var_0_9.scope_overlay:override("Remove All")
		end) then
			pcall(function()
				var_0_9.scope_overlay:override("Disabled")
			end)
		end
	else
		if not var_0_25._scp_rt.overlay_active then
			return
		end

		var_0_25._scp_rt.overlay_active = false

		pcall(function()
			var_0_9.scope_overlay:override()
		end)
	end
end

local function var_0_88()
	local var_252_0 = var_0_24.other.visual.scope_paint

	if not var_252_0 or not var_252_0:get() then
		var_0_87(false)

		var_0_25._scp_rt.zoom = 0

		return
	end

	var_0_87(true)

	local var_252_1 = entity.get_local_player()

	if not var_252_1 or not var_252_1:is_alive() then
		var_0_25._scp_rt.zoom = 0

		return
	end

	local var_252_2 = var_252_1:get_player_weapon()

	if not var_252_2 then
		var_0_25._scp_rt.zoom = 0

		return
	end

	local var_252_3 = var_252_1.m_bIsScoped == true
	local var_252_4 = var_0_33("Animated Zoom")
	local var_252_5 = var_252_3 and 1 or 0

	if var_252_4 then
		var_0_25._scp_rt.zoom = var_0_34(var_0_25._scp_rt.zoom or 0, var_252_5, math.min(1, globals.frametime * 18))
	else
		var_0_25._scp_rt.zoom = var_252_5
	end

	local var_252_6 = math.max(0, math.min(1, var_0_25._scp_rt.zoom or 0))

	if var_252_6 <= 0.01 then
		return
	end

	local var_252_7 = render.screen_size()
	local var_252_8 = var_252_7.x
	local var_252_9 = var_252_7.y
	local var_252_10 = var_252_8 / 2
	local var_252_11 = var_252_9 / 2
	local var_252_12 = var_252_0.scope_length:get() or 100
	local var_252_13 = var_252_0.scope_offset:get() or 5
	local var_252_14 = var_252_0.scope_type:get()
	local var_252_15 = var_252_0.scope_mode:get()
	local var_252_16 = var_252_15 == 2 or var_252_15 == "Inverted"
	local var_252_17 = var_252_0.scope_main:get()
	local var_252_18 = var_252_0.scope_second:get()
	local var_252_19 = 0

	if var_0_33("Spread Based") and var_252_2.get_inaccuracy then
		local var_252_20, var_252_21 = pcall(function()
			return var_252_2:get_inaccuracy()
		end)

		if var_252_20 and var_252_21 then
			var_252_19 = math.min(80, var_252_21 * 350)
		end
	end

	local var_252_22 = var_252_13 + var_252_19 + (1 - var_252_6) * 22
	local var_252_23 = var_252_12 * var_252_6

	if var_252_23 <= 1 then
		return
	end

	local var_252_24 = var_0_33("Glow")
	local var_252_25 = var_252_14 == 2 or var_252_14 == "T"
	local var_252_26 = var_252_14 == 3 or var_252_14 == "X"
	local var_252_27 = color(var_252_17.r, var_252_17.g, var_252_17.b, var_252_17.a * var_252_6)
	local var_252_28 = color(var_252_18.r, var_252_18.g, var_252_18.b, var_252_18.a * var_252_6)

	local function var_252_29()
		return var_252_16 and var_252_28 or var_252_27
	end

	local function var_252_30()
		return var_252_16 and var_252_27 or var_252_28
	end

	local function var_252_31(arg_256_0)
		local var_256_0 = 0.65 + math.abs(math.sin(globals.realtime * 4)) * 0.35

		return color(math.min(255, arg_256_0.r + 25 * var_256_0), math.min(255, arg_256_0.g + 25 * var_256_0), math.min(255, arg_256_0.b + 25 * var_256_0), math.min(255, math.max(arg_256_0.a, 210 * var_252_6)))
	end

	local function var_252_32(arg_257_0, arg_257_1, arg_257_2, arg_257_3, arg_257_4)
		local var_257_0 = arg_257_4 and var_252_30() or var_252_29()
		local var_257_1 = arg_257_4 and var_252_29() or var_252_30()

		if var_252_24 then
			var_0_86(arg_257_0, arg_257_1, arg_257_2, arg_257_3, var_252_31(var_257_0), var_252_31(var_257_1), 36)
		else
			var_0_47(arg_257_0, arg_257_1, arg_257_2, arg_257_3, var_257_0, var_257_1, 36)
		end
	end

	if var_252_26 then
		local var_252_33 = var_252_10 - var_252_22 - var_252_23
		local var_252_34 = var_252_11 - var_252_22 - var_252_23
		local var_252_35 = var_252_10 - var_252_22
		local var_252_36 = var_252_11 - var_252_22
		local var_252_37 = var_252_10 + var_252_22
		local var_252_38 = var_252_11 - var_252_22
		local var_252_39 = var_252_10 + var_252_22 + var_252_23
		local var_252_40 = var_252_11 - var_252_22 - var_252_23
		local var_252_41 = var_252_10 - var_252_22 - var_252_23
		local var_252_42 = var_252_11 + var_252_22 + var_252_23
		local var_252_43 = var_252_10 - var_252_22
		local var_252_44 = var_252_11 + var_252_22
		local var_252_45 = var_252_10 + var_252_22
		local var_252_46 = var_252_11 + var_252_22
		local var_252_47 = var_252_10 + var_252_22 + var_252_23
		local var_252_48 = var_252_11 + var_252_22 + var_252_23

		var_252_32(var_252_33, var_252_34, var_252_35, var_252_36, true)
		var_252_32(var_252_37, var_252_38, var_252_39, var_252_40, false)
		var_252_32(var_252_41, var_252_42, var_252_43, var_252_44, true)
		var_252_32(var_252_45, var_252_46, var_252_47, var_252_48, false)

		return
	end

	local var_252_49 = var_252_10 - var_252_22 - var_252_23
	local var_252_50 = var_252_11
	local var_252_51 = var_252_10 - var_252_22
	local var_252_52 = var_252_11
	local var_252_53 = var_252_10 + var_252_22
	local var_252_54 = var_252_11
	local var_252_55 = var_252_10 + var_252_22 + var_252_23
	local var_252_56 = var_252_11
	local var_252_57 = var_252_10
	local var_252_58 = var_252_11 - var_252_22 - var_252_23
	local var_252_59 = var_252_10
	local var_252_60 = var_252_11 - var_252_22
	local var_252_61 = var_252_10
	local var_252_62 = var_252_11 + var_252_22
	local var_252_63 = var_252_10
	local var_252_64 = var_252_11 + var_252_22 + var_252_23

	var_252_32(var_252_49, var_252_50, var_252_51, var_252_52, true)
	var_252_32(var_252_53, var_252_54, var_252_55, var_252_56, false)

	if not var_252_25 then
		var_252_32(var_252_57, var_252_58, var_252_59, var_252_60, true)
	end

	var_252_32(var_252_61, var_252_62, var_252_63, var_252_64, false)
end

local function var_0_89(arg_258_0)
	if not arg_258_0 then
		return
	end

	local var_258_0 = var_0_24.other.misc.no_fall_damage

	if not var_258_0 or not var_258_0:get() then
		return
	end

	local var_258_1 = entity.get_local_player()

	if not var_258_1 or not var_258_1:is_alive() then
		return
	end

	local var_258_2

	pcall(function()
		var_258_2 = var_258_1:get_origin()
	end)

	if not var_258_2 then
		return
	end

	local var_258_3 = 0

	pcall(function()
		var_258_3 = var_258_1.m_vecVelocity.z or 0
	end)

	if var_258_3 <= -500 then
		local var_258_4
		local var_258_5

		pcall(function()
			var_258_4 = utils.trace_line(vector(var_258_2.x, var_258_2.y, var_258_2.z), vector(var_258_2.x, var_258_2.y, var_258_2.z - 15))
		end)
		pcall(function()
			var_258_5 = utils.trace_line(vector(var_258_2.x, var_258_2.y, var_258_2.z), vector(var_258_2.x, var_258_2.y, var_258_2.z - 55))
		end)

		if var_258_4 and var_258_4.fraction ~= 1 then
			arg_258_0.in_duck = 0
		elseif var_258_5 and var_258_5.fraction ~= 1 then
			arg_258_0.in_duck = 1
		end
	end
end

local function var_0_90(arg_263_0)
	if not arg_263_0 then
		return
	end

	local var_263_0 = var_0_24.other.misc.fast_ladder

	if not var_263_0 or not var_263_0:get() then
		return
	end

	local var_263_1 = entity.get_local_player()

	if not var_263_1 or not var_263_1:is_alive() then
		return
	end

	local var_263_2 = 0

	pcall(function()
		var_263_2 = var_263_1.m_MoveType or var_263_1.m_MoveType
	end)

	if var_263_2 ~= 9 then
		return
	end

	if not arg_263_0.view_angles then
		return
	end

	arg_263_0.view_angles.y = math.floor(arg_263_0.view_angles.y + 0.5)

	local var_263_3 = arg_263_0.forwardmove or 0
	local var_263_4 = arg_263_0.sidemove or 0

	if var_263_3 > 0 then
		if arg_263_0.view_angles.x < 45 then
			arg_263_0.view_angles.x = 89
			arg_263_0.in_moveright = 1
			arg_263_0.in_moveleft = 0
			arg_263_0.in_forward = 0
			arg_263_0.in_back = 1

			if var_263_4 == 0 then
				arg_263_0.view_angles.y = arg_263_0.view_angles.y + 90
			end

			if var_263_4 < 0 then
				arg_263_0.view_angles.y = arg_263_0.view_angles.y + 150
			end

			if var_263_4 > 0 then
				arg_263_0.view_angles.y = arg_263_0.view_angles.y + 30
			end
		end
	elseif var_263_3 < 0 then
		arg_263_0.view_angles.x = 89
		arg_263_0.in_moveleft = 1
		arg_263_0.in_moveright = 0
		arg_263_0.in_forward = 1
		arg_263_0.in_back = 0

		if var_263_4 == 0 then
			arg_263_0.view_angles.y = arg_263_0.view_angles.y + 90
		end

		if var_263_4 > 0 then
			arg_263_0.view_angles.y = arg_263_0.view_angles.y + 150
		end

		if var_263_4 < 0 then
			arg_263_0.view_angles.y = arg_263_0.view_angles.y + 30
		end
	end
end

super_toss_refs = {
	restore = false
}

local function var_0_91(arg_265_0, arg_265_1, arg_265_2, arg_265_3)
	if not arg_265_0 then
		return nil
	end

	local var_265_0 = vector():angles(arg_265_0)
	local var_265_1 = (arg_265_3 or vector(0, 0, 0)) * 1.25
	local var_265_2 = math.clamp((arg_265_1 or 750) * 0.9, 15, 750) * (math.clamp(arg_265_2 or 1, 0, 1) * 0.7 + 0.3)
	local var_265_3 = var_265_1 - var_265_0 * var_265_0:dot(var_265_1)
	local var_265_4 = var_265_3:lengthsqr()

	if var_265_4 < var_265_2 * var_265_2 then
		return (var_265_0 * math.sqrt(var_265_2 * var_265_2 - var_265_4) - var_265_3):normalized():angles()
	end

	local var_265_5 = (var_265_0 * 0.001 - var_265_3):normalized()
	local var_265_6 = 1 - var_265_2 * var_265_2 / var_265_4

	return var_265_5:lerp(var_265_0, var_265_6):normalized():angles()
end

local function var_0_92(arg_266_0)
	if not arg_266_0 then
		return false, nil
	end

	local var_266_0

	pcall(function()
		var_266_0 = arg_266_0:get_weapon_info()
	end)

	if not var_266_0 then
		return false, nil
	end

	if (var_266_0.weapon_type or var_266_0.weapn_type or var_266_0.type) == 9 then
		return true, var_266_0
	end

	local var_266_1 = ""

	pcall(function()
		var_266_1 = arg_266_0:get_classname() or ""
	end)

	var_266_1 = tostring(var_266_1):lower()

	if var_266_1:find("grenade", 1, true) or var_266_1:find("flashbang", 1, true) or var_266_1:find("smoke", 1, true) or var_266_1:find("molotov", 1, true) or var_266_1:find("decoy", 1, true) or var_266_1:find("incgrenade", 1, true) or var_266_1:find("hegrenade", 1, true) then
		return true, var_266_0
	end

	return false, var_266_0
end

local function var_0_93()
	if super_toss_refs.restore then
		pcall(function()
			super_toss_movement.air_strafe:override()
		end)
		pcall(function()
			super_toss_movement.assist:override()
		end)

		super_toss_refs.restore = false
	end
end

local function var_0_94(arg_272_0)
	local var_272_0 = var_0_24.other.misc.super_toss

	if not var_272_0 or not var_272_0:get() then
		return
	end

	if not arg_272_0 then
		return
	end

	local var_272_1 = entity.get_local_player()

	if not var_272_1 or not var_272_1:is_alive() then
		return
	end

	local var_272_2 = var_272_1:get_player_weapon()

	if not var_272_2 then
		return
	end

	local var_272_3, var_272_4 = var_0_92(var_272_2)

	if not var_272_3 or not var_272_4 then
		return
	end

	local var_272_5 = 1

	pcall(function()
		var_272_5 = var_272_2.m_flThrowStrength or var_272_2.m_fThrowStrength or 1
	end)

	local var_272_6 = arg_272_0.velocity or vector(0, 0, 0)
	local var_272_7 = var_0_91(arg_272_0.angles, var_272_4.throw_velocity or 750, var_272_5, var_272_6)

	if var_272_7 then
		arg_272_0.angles = var_272_7
	end
end

local function var_0_95(arg_274_0)
	var_0_93()

	local var_274_0 = var_0_24.other.misc.super_toss

	if not var_274_0 or not var_274_0:get() then
		return
	end

	if not arg_274_0 or not arg_274_0.jitter_move then
		return
	end

	local var_274_1 = entity.get_local_player()

	if not var_274_1 or not var_274_1:is_alive() then
		return
	end

	local var_274_2 = var_274_1:get_player_weapon()

	if not var_274_2 then
		return
	end

	local var_274_3, var_274_4 = var_0_92(var_274_2)

	if not var_274_3 or not var_274_4 then
		return
	end

	local var_274_5 = 0

	pcall(function()
		var_274_5 = var_274_2.m_fThrowTime or var_274_2.m_flThrowTime or 0
	end)

	local var_274_6 = 0

	pcall(function()
		var_274_6 = rage.exploit:get() or 0
	end)

	local var_274_7 = 0.1 * var_274_6

	if not (var_274_5 > 0) or not (var_274_5 - var_274_7 <= globals.curtime) then
		return
	end

	pcall(function()
		super_toss_movement.air_strafe:override(false)
	end)
	pcall(function()
		super_toss_movement.assist:override(false)
	end)

	super_toss_refs.restore = true

	local var_274_8

	pcall(function()
		var_274_8 = var_274_1:simulate_movement()
	end)

	if var_274_8 then
		pcall(function()
			var_274_8:think(1)
		end)
	end

	local var_274_9 = var_274_8 and var_274_8.velocity or vector(0, 0, 0)
	local var_274_10 = 0

	pcall(function()
		var_274_10 = var_274_1.m_MoveType or 0
	end)

	if var_274_10 == 9 then
		arg_274_0.in_moveleft = 0
		arg_274_0.in_moveright = 0
		arg_274_0.in_forward = 0
		arg_274_0.in_back = 0
		arg_274_0.in_left = 0
		arg_274_0.in_right = 0
		var_274_9 = vector(0, 0, 0)
	end

	local var_274_11 = 1

	pcall(function()
		var_274_11 = var_274_2.m_flThrowStrength or var_274_2.m_fThrowStrength or 1
	end)

	local var_274_12 = var_0_91(arg_274_0.view_angles, var_274_4.throw_velocity or 750, var_274_11, var_274_9)

	if var_274_12 then
		arg_274_0.view_angles = var_274_12
	end
end

local function var_0_96(arg_283_0)
	if not arg_283_0 then
		return
	end

	local var_283_0 = var_0_24.other.misc.fakeduck_modifiers

	if not var_283_0 or not var_283_0.freezetime_fakeduck or not var_283_0.freezetime_fakeduck:get() then
		return
	end

	if not entity.get_local_player() then
		return
	end

	local var_283_1

	pcall(function()
		var_283_1 = entity.get_game_rules()
	end)

	local var_283_2 = false

	pcall(function()
		var_283_2 = var_283_1 and var_283_1.m_bFreezePeriod or false
	end)

	local var_283_3 = false

	pcall(function()
		var_283_3 = var_0_9.antiaim and var_0_9.antiaim.fakedick and var_0_9.antiaim.fakedick:get()
	end)

	if var_283_2 and var_283_3 then
		pcall(function()
			if var_0_9.antiaim.dt then
				var_0_9.antiaim.dt:override(false)
			end
		end)
		pcall(function()
			if var_0_9.hideshots then
				var_0_9.hideshots:override(false)
			end
		end)

		arg_283_0.send_packet = false

		if globals.choked_commands >= 7 then
			arg_283_0.in_duck = true
		else
			arg_283_0.in_duck = false
		end
	else
		pcall(function()
			if var_0_9.antiaim.dt then
				var_0_9.antiaim.dt:override()
			end
		end)
		pcall(function()
			if var_0_9.hideshots then
				var_0_9.hideshots:override()
			end
		end)
	end
end

local function var_0_97(arg_291_0)
	if not arg_291_0 then
		return
	end

	local var_291_0 = var_0_24.other.misc.fakeduck_modifiers

	if not var_291_0 or not var_291_0.unlock_fakeduck_speed or not var_291_0.unlock_fakeduck_speed:get() then
		return
	end

	if not var_0_9.antiaim or not var_0_9.antiaim.fakedick or var_0_9.antiaim.fakedick:get() == false then
		return
	end

	local var_291_1 = entity.get_local_player()

	if var_291_1 == nil then
		return
	end

	local var_291_2 = vector(arg_291_0.forwardmove or 0, arg_291_0.sidemove or 0)

	var_291_2:normalize()

	local var_291_3 = 0

	pcall(function()
		var_291_3 = var_291_1.m_vecVelocity.y or 0
	end)

	if math.abs(var_291_3) > 10 then
		local var_291_4 = 150

		arg_291_0.forwardmove = var_291_2.x * var_291_4
		arg_291_0.sidemove = var_291_2.y * var_291_4
	end
end

local function var_0_98()
	local var_293_0 = var_0_24.other.misc.fake_latency

	if not var_293_0 then
		return
	end

	local var_293_1 = false
	local var_293_2 = 0

	pcall(function()
		var_293_1 = var_293_0:get()
	end)
	pcall(function()
		var_293_2 = var_293_0.amount and (tonumber(var_293_0.amount:get()) or 0) or 0
	end)

	if var_293_1 and var_293_2 > 0 then
		pcall(function()
			cvar.sv_maxunlag:float(0.4, true)
		end)
		pcall(function()
			var_0_9.antiaim.fakexyetensi:override(var_293_2)
		end)
	else
		pcall(function()
			var_0_9.antiaim.fakexyetensi:override()
		end)
		pcall(function()
			cvar.sv_maxunlag:float(0.2, true)
		end)
	end
end

local function var_0_99(arg_300_0)
	if not arg_300_0 then
		return
	end

	local var_300_0 = var_0_24.other.misc.edge_stop

	if not var_300_0 or not var_300_0:get() then
		return
	end

	local var_300_1 = entity.get_local_player()

	if not var_300_1 or not var_300_1:is_alive() then
		return
	end

	local var_300_2

	pcall(function()
		var_300_2 = var_300_1:get_origin()
	end)

	if not var_300_2 then
		return
	end

	local var_300_3

	pcall(function()
		var_300_3 = var_300_1:simulate_movement()
	end)

	if not var_300_3 then
		return
	end

	pcall(function()
		var_300_3:think(4)
	end)

	local var_300_4 = 0

	pcall(function()
		var_300_4 = var_300_3.velocity.z or 0
	end)

	if var_300_4 < 0 then
		arg_300_0.block_movement = 2
	end
end

local function var_0_100(arg_305_0)
	local var_305_0 = var_0_24.other.misc.keep_model_transparency

	if not var_305_0 or not var_305_0:get() then
		return
	end

	return false
end

WS_PRINT_EVENTS = {
	font = render.load_font("Verdana", 12, "ad"),
	font_screen = render.load_font("Verdana", 12, "ad"),
	hitgroups = {
		[0] = "generic",
		"head",
		"chest",
		"stomach",
		"left arm",
		"right arm",
		"left leg",
		"right leg",
		"neck",
		"generic",
		"gear"
	}
}

function WS_PRINT_EVENTS.rt(arg_306_0)
	var_0_25._pe_rt = var_0_25._pe_rt or {
		last_time = 0,
		center_drag = false,
		screen_drag = false,
		screen_y = 12,
		screen_x = 12,
		dx = 0,
		example_alpha = 0,
		dy = 0,
		logs = {},
		center = {}
	}

	return var_0_25._pe_rt
end

function WS_PRINT_EVENTS.has(arg_307_0, arg_307_1, arg_307_2)
	if type(arg_307_1) ~= "table" then
		return arg_307_1 == arg_307_2
	end

	for iter_307_0, iter_307_1 in pairs(arg_307_1) do
		if iter_307_1 == arg_307_2 then
			return true
		end
	end

	return false
end

function WS_PRINT_EVENTS.enabled(arg_308_0)
	local var_308_0 = var_0_24.other.misc.print_events

	return var_308_0 and var_308_0.get and var_308_0:get()
end

function WS_PRINT_EVENTS.hex(arg_309_0, arg_309_1)
	local var_309_0, var_309_1 = pcall(function()
		return arg_309_1:to_hex()
	end)

	if var_309_0 and var_309_1 then
		return var_309_1
	end

	return "FFFFFFFF"
end

function WS_PRINT_EVENTS.tag(arg_311_0, arg_311_1, arg_311_2)
	return "\a" .. arg_311_0:hex(arg_311_2) .. tostring(arg_311_1) .. "\aFFFFFFFF"
end

function WS_PRINT_EVENTS.glow(arg_312_0, arg_312_1, arg_312_2)
	if arg_312_2 == "miss" then
		return arg_312_1.glow_miss and arg_312_1.glow_miss:get() or color(255, 95, 95, 255)
	end

	return arg_312_1.glow_hit and arg_312_1.glow_hit:get() or color(160, 200, 255, 255)
end

function WS_PRINT_EVENTS.text_col(arg_313_0, arg_313_1, arg_313_2)
	local var_313_0 = arg_313_1.text_color and arg_313_1.text_color:get() or color(255, 255, 255, 255)

	return color(var_313_0.r, var_313_0.g, var_313_0.b, math.floor((var_313_0.a or 255) * arg_313_2))
end

function WS_PRINT_EVENTS.hg(arg_314_0, arg_314_1, arg_314_2)
	if arg_314_2 and arg_314_2 ~= "" then
		return tostring(arg_314_2)
	end

	arg_314_1 = tonumber(arg_314_1) or 0

	return arg_314_0.hitgroups[arg_314_1] or "generic"
end

function WS_PRINT_EVENTS.ent_name_by_id(arg_315_0, arg_315_1)
	local var_315_0 = "Name"

	if arg_315_1 ~= nil then
		pcall(function()
			local var_316_0 = entity.get(arg_315_1)

			if var_316_0 then
				var_315_0 = var_316_0:get_name() or "Name"
			end
		end)
		pcall(function()
			local var_317_0 = entity.get(arg_315_1, true)

			if var_317_0 then
				var_315_0 = var_317_0:get_name() or var_315_0
			end
		end)
	end

	return var_315_0
end

function WS_PRINT_EVENTS.ent_hp_by_id(arg_318_0, arg_318_1)
	local var_318_0 = 0

	if arg_318_1 ~= nil then
		pcall(function()
			local var_319_0 = entity.get(arg_318_1)

			if var_319_0 then
				var_318_0 = var_319_0.m_iHealth or 0
			end
		end)
	end

	return var_318_0
end

function WS_PRINT_EVENTS.console(arg_320_0, arg_320_1, arg_320_2, arg_320_3, arg_320_4, arg_320_5, arg_320_6, arg_320_7, arg_320_8)
	local var_320_0 = var_0_24.other.misc.print_events
	local var_320_1 = arg_320_0:glow(var_320_0, arg_320_1)
	local var_320_2 = "\aFFFFFFFF"
	local var_320_3 = "\a" .. arg_320_0:hex(var_320_1) .. "whitestrike" .. var_320_2 .. " >> "

	if arg_320_1 == "hit" then
		return var_320_3 .. "Hit " .. arg_320_0:tag(arg_320_2, var_320_1) .. " " .. arg_320_0:tag(arg_320_3, var_320_1) .. " for (" .. arg_320_0:tag(arg_320_4, var_320_1) .. ") damage (hp: " .. arg_320_0:tag(arg_320_5, var_320_1) .. ") (bt: " .. arg_320_0:tag(arg_320_6, var_320_1) .. ") (spread: " .. arg_320_0:tag(string.format("%.2f°", tonumber(arg_320_7) or 0), var_320_1) .. ")"
	end

	if arg_320_1 == "miss" then
		return var_320_3 .. "Missed " .. arg_320_0:tag(arg_320_2, var_320_1) .. " " .. arg_320_0:tag(arg_320_3, var_320_1) .. " due to " .. arg_320_0:tag(arg_320_8, var_320_1) .. " (dmg: " .. arg_320_0:tag(arg_320_4, var_320_1) .. ") (bt: " .. arg_320_0:tag(arg_320_6, var_320_1) .. ") (spread: " .. arg_320_0:tag(string.format("%.2f°", tonumber(arg_320_7) or 0), var_320_1) .. ")"
	end

	if arg_320_1 == "purchase" then
		return var_320_3 .. arg_320_0:tag(arg_320_2, var_320_1) .. " bought " .. arg_320_0:tag(arg_320_3, var_320_1)
	end

	if arg_320_1 == "kill" then
		return var_320_3 .. "Killed " .. arg_320_0:tag(arg_320_2, var_320_1)
	end

	return var_320_3 .. tostring(arg_320_2 or "")
end

function WS_PRINT_EVENTS.plain(arg_321_0, arg_321_1, arg_321_2, arg_321_3, arg_321_4, arg_321_5, arg_321_6, arg_321_7, arg_321_8)
	if arg_321_1 == "hit" then
		return {
			{
				"whitestrike",
				true
			},
			{
				" >> Hit ",
				false
			},
			{
				arg_321_2,
				true
			},
			{
				" " .. arg_321_3 .. " for (",
				false
			},
			{
				tostring(arg_321_4),
				true
			},
			{
				") damage (hp: ",
				false
			},
			{
				tostring(arg_321_5),
				true
			},
			{
				") (bt: ",
				false
			},
			{
				tostring(arg_321_6),
				true
			},
			{
				") (spread: ",
				false
			},
			{
				string.format("%.2f°", tonumber(arg_321_7) or 0),
				true
			},
			{
				")",
				false
			}
		}
	end

	if arg_321_1 == "miss" then
		return {
			{
				"whitestrike",
				true
			},
			{
				" >> Missed ",
				false
			},
			{
				arg_321_2,
				true
			},
			{
				" " .. arg_321_3 .. " due to ",
				false
			},
			{
				arg_321_8,
				true
			},
			{
				" (dmg: ",
				false
			},
			{
				tostring(arg_321_4),
				true
			},
			{
				") (bt: ",
				false
			},
			{
				tostring(arg_321_6),
				true
			},
			{
				") (spread: ",
				false
			},
			{
				string.format("%.2f°", tonumber(arg_321_7) or 0),
				true
			},
			{
				")",
				false
			}
		}
	end

	if arg_321_1 == "purchase" then
		return {
			{
				"whitestrike",
				true
			},
			{
				" >> ",
				false
			},
			{
				arg_321_2,
				true
			},
			{
				" bought ",
				false
			},
			{
				arg_321_3,
				true
			}
		}
	end

	if arg_321_1 == "kill" then
		return {
			{
				"whitestrike",
				true
			},
			{
				" >> Killed ",
				false
			},
			{
				arg_321_2,
				true
			}
		}
	end

	return {
		{
			"whitestrike",
			true
		},
		{
			" >> " .. tostring(arg_321_2 or ""),
			false
		}
	}
end

function WS_PRINT_EVENTS.text_width(arg_322_0, arg_322_1, arg_322_2)
	local var_322_0 = 0

	for iter_322_0, iter_322_1 in ipairs(arg_322_1) do
		var_322_0 = var_322_0 + render.measure_text(arg_322_2, nil, tostring(iter_322_1[1])).x
	end

	return var_322_0
end

function WS_PRINT_EVENTS.base_cols(arg_323_0, arg_323_1, arg_323_2)
	local var_323_0 = arg_323_1.style and arg_323_1.style:get() or "Dark"
	local var_323_1 = var_323_0 == "White" or var_323_0 == 2
	local var_323_2 = var_323_1 and color(245, 245, 245, math.floor(220 * arg_323_2)) or color(8, 12, 17, math.floor(230 * arg_323_2))
	local var_323_3 = var_323_1 and color(200, 200, 200, math.floor(110 * arg_323_2)) or color(0, 0, 0, math.floor(170 * arg_323_2))
	local var_323_4 = arg_323_0:text_col(arg_323_1, arg_323_2)

	return var_323_2, var_323_3, var_323_4
end

function WS_PRINT_EVENTS.draw_parts(arg_324_0, arg_324_1, arg_324_2, arg_324_3, arg_324_4, arg_324_5, arg_324_6, arg_324_7, arg_324_8)
	local var_324_0 = arg_324_2

	for iter_324_0, iter_324_1 in ipairs(arg_324_4) do
		local var_324_1 = tostring(iter_324_1[1])
		local var_324_2 = iter_324_1[2] and arg_324_6 or arg_324_5

		if arg_324_8 then
			render.text(arg_324_1, vector(var_324_0 + 1, arg_324_3 + 1), color(0, 0, 0, math.floor(155 * arg_324_7)), nil, var_324_1)
		end

		render.text(arg_324_1, vector(var_324_0, arg_324_3), color(var_324_2.r, var_324_2.g, var_324_2.b, math.floor((var_324_2.a or 255) * arg_324_7)), nil, var_324_1)

		var_324_0 = var_324_0 + render.measure_text(arg_324_1, nil, var_324_1).x
	end
end

function WS_PRINT_EVENTS.draw_glow_box(arg_325_0, arg_325_1, arg_325_2, arg_325_3, arg_325_4, arg_325_5, arg_325_6)
	render.rect(vector(arg_325_1 - 3, arg_325_2 - 3), vector(arg_325_1 + arg_325_3 + 3, arg_325_2 + arg_325_4 + 3), color(arg_325_5.r, arg_325_5.g, arg_325_5.b, math.floor(18 * arg_325_6)), 7)
	render.rect(vector(arg_325_1 - 2, arg_325_2 - 2), vector(arg_325_1 + arg_325_3 + 2, arg_325_2 + arg_325_4 + 2), color(arg_325_5.r, arg_325_5.g, arg_325_5.b, math.floor(24 * arg_325_6)), 6)
	render.rect(vector(arg_325_1 - 1, arg_325_2 - 1), vector(arg_325_1 + arg_325_3 + 1, arg_325_2 + arg_325_4 + 1), color(arg_325_5.r, arg_325_5.g, arg_325_5.b, math.floor(34 * arg_325_6)), 5)
end

function WS_PRINT_EVENTS.draw_box(arg_326_0, arg_326_1, arg_326_2, arg_326_3, arg_326_4, arg_326_5, arg_326_6, arg_326_7, arg_326_8)
	arg_326_0:draw_glow_box(arg_326_1, arg_326_2, arg_326_3, arg_326_4, arg_326_7, arg_326_8)
	render.rect(vector(arg_326_1 + 1, arg_326_2 + 1), vector(arg_326_1 + arg_326_3 + 1, arg_326_2 + arg_326_4 + 1), color(0, 0, 0, math.floor(110 * arg_326_8)), 5)
	render.rect(vector(arg_326_1, arg_326_2), vector(arg_326_1 + arg_326_3, arg_326_2 + arg_326_4), arg_326_5, 5)
	render.rect_outline(vector(arg_326_1, arg_326_2), vector(arg_326_1 + arg_326_3, arg_326_2 + arg_326_4), arg_326_6, 1, 5)
end

function WS_PRINT_EVENTS.draw_center_line(arg_327_0, arg_327_1, arg_327_2, arg_327_3, arg_327_4, arg_327_5, arg_327_6, arg_327_7)
	local var_327_0, var_327_1, var_327_2 = arg_327_0:base_cols(arg_327_5, arg_327_4)
	local var_327_3 = arg_327_0.font
	local var_327_4 = 8
	local var_327_5 = arg_327_0:text_width(arg_327_1, var_327_3)
	local var_327_6 = 22
	local var_327_7 = var_327_5 + var_327_4 * 2

	if arg_327_6 then
		arg_327_2 = arg_327_2 - var_327_7 / 2
	end

	arg_327_0:draw_box(arg_327_2, arg_327_3, var_327_7, var_327_6, var_327_0, var_327_1, arg_327_7, arg_327_4)
	arg_327_0:draw_parts(var_327_3, arg_327_2 + var_327_4, arg_327_3 + 5, arg_327_1, var_327_2, arg_327_7, arg_327_4, true)

	return var_327_7, var_327_6
end

function WS_PRINT_EVENTS.draw_screen_line(arg_328_0, arg_328_1, arg_328_2, arg_328_3, arg_328_4, arg_328_5, arg_328_6)
	local var_328_0 = arg_328_0.font_screen
	local var_328_1 = arg_328_0:text_col(arg_328_5, arg_328_4)

	arg_328_0:draw_parts(var_328_0, arg_328_2, arg_328_3, arg_328_1, var_328_1, arg_328_6, arg_328_4, true)

	return arg_328_0:text_width(arg_328_1, var_328_0), 14
end

function WS_PRINT_EVENTS.mouse(arg_329_0)
	local var_329_0, var_329_1 = pcall(function()
		return ui.get_mouse_position()
	end)

	if var_329_0 and var_329_1 then
		return var_329_1
	end

	local var_329_2, var_329_3 = pcall(function()
		return render.mouse_position()
	end)

	if var_329_2 and var_329_3 then
		return var_329_3
	end

	return vector(0, 0)
end

function WS_PRINT_EVENTS.mdown(arg_332_0)
	local var_332_0, var_332_1 = pcall(function()
		return common.is_button_down(1)
	end)

	if var_332_0 then
		return var_332_1
	end

	local var_332_2, var_332_3 = pcall(function()
		return ui.is_mouse_down(0)
	end)

	if var_332_2 then
		return var_332_3
	end

	return false
end

function WS_PRINT_EVENTS.menu_open(arg_335_0)
	local var_335_0, var_335_1 = pcall(function()
		return ui.get_alpha()
	end)

	return var_335_0 and var_335_1 and var_335_1 > 0.01
end

function WS_PRINT_EVENTS.drag_area(arg_337_0, arg_337_1, arg_337_2, arg_337_3, arg_337_4, arg_337_5, arg_337_6, arg_337_7)
	local var_337_0 = arg_337_0:rt()
	local var_337_1 = render.screen_size()
	local var_337_2 = arg_337_0:mouse()
	local var_337_3 = arg_337_0:mdown()
	local var_337_4 = arg_337_0:menu_open()
	local var_337_5 = arg_337_1 .. "_drag"
	local var_337_6 = var_337_4 and arg_337_2 <= var_337_2.x and var_337_2.x <= arg_337_2 + arg_337_4 and arg_337_3 <= var_337_2.y and var_337_2.y <= arg_337_3 + arg_337_5

	if var_337_4 and var_337_3 and not var_337_0[var_337_5] and var_337_6 then
		var_337_0[var_337_5] = true
		var_337_0.dx = var_337_2.x - arg_337_2
		var_337_0.dy = var_337_2.y - arg_337_3
	end

	if not var_337_3 or not var_337_4 then
		var_337_0[var_337_5] = false
	end

	if var_337_0[var_337_5] then
		render.rect(vector(0, 0), var_337_1, color(0, 0, 0, 95), 0)

		if arg_337_7 == "screen" then
			var_337_0.screen_x = math.max(5, math.min(var_337_1.x - arg_337_4 - 5, var_337_2.x - (var_337_0.dx or 0)))
			var_337_0.screen_y = math.max(5, math.min(var_337_1.y - arg_337_5 - 5, var_337_2.y - (var_337_0.dy or 0)))

			render.line(vector(var_337_0.screen_x, 0), vector(var_337_0.screen_x, var_337_1.y), color(arg_337_6.r, arg_337_6.g, arg_337_6.b, 70))
			render.line(vector(0, var_337_0.screen_y), vector(var_337_1.x, var_337_0.screen_y), color(arg_337_6.r, arg_337_6.g, arg_337_6.b, 70))

			return var_337_0.screen_x, var_337_0.screen_y
		end

		if arg_337_7 == "center" then
			var_337_0.center_y = math.max(30, math.min(var_337_1.y - arg_337_5 - 30, var_337_2.y - (var_337_0.dy or 0)))

			render.line(vector(0, var_337_0.center_y + arg_337_5 / 2), vector(var_337_1.x, var_337_0.center_y + arg_337_5 / 2), color(arg_337_6.r, arg_337_6.g, arg_337_6.b, 95))

			return arg_337_2, var_337_0.center_y
		end
	end

	return arg_337_2, arg_337_3
end

function WS_PRINT_EVENTS.draw_examples(arg_338_0, arg_338_1)
	local var_338_0 = arg_338_0:rt()
	local var_338_1 = arg_338_1.output and arg_338_1.output:get() or {}
	local var_338_2 = arg_338_0:enabled() and arg_338_0:menu_open() and (arg_338_0:has(var_338_1, "Screen") or arg_338_0:has(var_338_1, "Center")) and 1 or 0

	var_338_0.example_alpha = var_0_36(var_338_0.example_alpha or 0, var_338_2, math.min(1, globals.frametime * 12))

	local var_338_3 = var_338_0.example_alpha or 0

	if var_338_3 <= 0.01 then
		return
	end

	local var_338_4 = render.screen_size()
	local var_338_5 = arg_338_0:plain("hit", "Name", "head", 0, 0, 0, 0, "")
	local var_338_6 = arg_338_0:plain("miss", "Name", "head", 0, 0, 0, 0, "spread")

	if arg_338_0:has(var_338_1, "Screen") then
		local var_338_7 = var_338_0.screen_x or 12
		local var_338_8 = var_338_0.screen_y or 12
		local var_338_9 = math.max(arg_338_0:text_width(var_338_5, arg_338_0.font_screen), arg_338_0:text_width(var_338_6, arg_338_0.font_screen))
		local var_338_10 = 34
		local var_338_11, var_338_12 = arg_338_0:drag_area("screen", var_338_7, var_338_8, var_338_9, var_338_10, arg_338_0:glow(arg_338_1, "hit"), "screen")

		arg_338_0:draw_screen_line(var_338_5, var_338_11, var_338_12, var_338_3, arg_338_1, arg_338_0:glow(arg_338_1, "hit"))
		arg_338_0:draw_screen_line(var_338_6, var_338_11, var_338_12 + 15, var_338_3, arg_338_1, arg_338_0:glow(arg_338_1, "miss"))
	end

	if arg_338_0:has(var_338_1, "Center") then
		if var_338_0.center_y == nil then
			var_338_0.center_y = var_338_4.y / 2 + 110
		end

		local var_338_13 = math.max(arg_338_0:text_width(var_338_5, arg_338_0.font), arg_338_0:text_width(var_338_6, arg_338_0.font)) + 16
		local var_338_14 = 52
		local var_338_15 = var_338_4.x / 2 - var_338_13 / 2
		local var_338_16 = var_338_0.center_y
		local var_338_17, var_338_18 = arg_338_0:drag_area("center", var_338_15, var_338_16, var_338_13, var_338_14, arg_338_0:glow(arg_338_1, "hit"), "center")

		arg_338_0:draw_center_line(var_338_5, var_338_17, var_338_18, var_338_3, arg_338_1, false, arg_338_0:glow(arg_338_1, "hit"))
		arg_338_0:draw_center_line(var_338_6, var_338_17, var_338_18 + 27, var_338_3, arg_338_1, false, arg_338_0:glow(arg_338_1, "miss"))
	end
end

function WS_PRINT_EVENTS.push(arg_339_0, arg_339_1, arg_339_2, arg_339_3, arg_339_4, arg_339_5, arg_339_6, arg_339_7, arg_339_8)
	local var_339_0 = var_0_24.other.misc.print_events

	if not var_339_0 or not var_339_0:get() then
		return
	end

	local var_339_1 = var_339_0.events and var_339_0.events:get() or {}

	if (arg_339_1 == "hit" or arg_339_1 == "miss") and not arg_339_0:has(var_339_1, "Shots") then
		return
	end

	if arg_339_1 == "purchase" and not arg_339_0:has(var_339_1, "Purchases") then
		return
	end

	if arg_339_1 == "kill" and not arg_339_0:has(var_339_1, "Kill") then
		return
	end

	local var_339_2 = var_339_0.output and var_339_0.output:get() or {}
	local var_339_3 = arg_339_0:glow(var_339_0, arg_339_1 == "miss" and "miss" or "hit")
	local var_339_4 = arg_339_0:plain(arg_339_1, arg_339_2, arg_339_3, arg_339_4, arg_339_5, arg_339_6, arg_339_7, arg_339_8)

	if arg_339_0:has(var_339_2, "Console") then
		local var_339_5 = arg_339_0:console(arg_339_1, arg_339_2, arg_339_3, arg_339_4, arg_339_5, arg_339_6, arg_339_7, arg_339_8)

		pcall(function()
			print_raw(var_339_5)
		end)
	end

	local var_339_6 = arg_339_0:rt()

	if arg_339_0:has(var_339_2, "Screen") then
		table.insert(var_339_6.logs, 1, {
			life = 5,
			alpha = 0,
			parts = var_339_4,
			glow = var_339_3,
			start = globals.realtime
		})

		if #var_339_6.logs > 8 then
			table.remove(var_339_6.logs)
		end
	end

	if arg_339_0:has(var_339_2, "Center") then
		table.insert(var_339_6.center, 1, {
			life = 4,
			alpha = 0,
			parts = var_339_4,
			glow = var_339_3,
			start = globals.realtime
		})

		if #var_339_6.center > 5 then
			table.remove(var_339_6.center)
		end
	end
end

function WS_PRINT_EVENTS.draw_screen(arg_341_0, arg_341_1)
	local var_341_0 = arg_341_0:rt()
	local var_341_1 = globals.realtime
	local var_341_2 = var_341_0.screen_x or 12
	local var_341_3 = var_341_0.screen_y or 12

	for iter_341_0 = #var_341_0.logs, 1, -1 do
		local var_341_4 = var_341_0.logs[iter_341_0]
		local var_341_5 = var_341_1 - var_341_4.start
		local var_341_6 = var_341_5 < var_341_4.life and 1 or 0

		var_341_4.alpha = var_0_36(var_341_4.alpha or 0, var_341_6, math.min(1, globals.frametime * 10))

		if var_341_5 > var_341_4.life + 0.8 and var_341_4.alpha < 0.02 then
			table.remove(var_341_0.logs, iter_341_0)
		end
	end

	local var_341_7 = var_341_3

	for iter_341_1 = #var_341_0.logs, 1, -1 do
		local var_341_8 = var_341_0.logs[iter_341_1]

		if var_341_8.alpha and var_341_8.alpha > 0.01 then
			local var_341_9 = (1 - var_341_8.alpha) * 12

			arg_341_0:draw_screen_line(var_341_8.parts, var_341_2 - var_341_9, var_341_7, var_341_8.alpha, arg_341_1, var_341_8.glow)

			var_341_7 = var_341_7 + 15 * var_341_8.alpha
		end
	end
end

function WS_PRINT_EVENTS.draw_center(arg_342_0, arg_342_1)
	local var_342_0 = arg_342_0:rt()
	local var_342_1 = render.screen_size()
	local var_342_2 = globals.realtime

	if var_342_0.center_y == nil then
		var_342_0.center_y = var_342_1.y / 2 + 110
	end

	for iter_342_0 = #var_342_0.center, 1, -1 do
		local var_342_3 = var_342_0.center[iter_342_0]
		local var_342_4 = var_342_2 - var_342_3.start
		local var_342_5 = var_342_4 < var_342_3.life and 1 or 0

		var_342_3.alpha = var_0_36(var_342_3.alpha or 0, var_342_5, math.min(1, globals.frametime * 10))

		if var_342_4 > var_342_3.life + 0.8 and var_342_3.alpha < 0.02 then
			table.remove(var_342_0.center, iter_342_0)
		end
	end

	local var_342_6 = var_342_0.center_y

	for iter_342_1 = #var_342_0.center, 1, -1 do
		local var_342_7 = var_342_0.center[iter_342_1]

		if var_342_7.alpha and var_342_7.alpha > 0.01 then
			local var_342_8, var_342_9 = arg_342_0:draw_center_line(var_342_7.parts, var_342_1.x / 2, var_342_6, var_342_7.alpha, arg_342_1, true, var_342_7.glow)

			var_342_6 = var_342_6 + var_342_9 + 5
		end
	end
end

function WS_PRINT_EVENTS.draw(arg_343_0)
	local var_343_0 = var_0_24.other.misc.print_events

	if not var_343_0 then
		return
	end

	if var_343_0:get() then
		local var_343_1 = var_343_0.output and var_343_0.output:get() or {}

		if arg_343_0:has(var_343_1, "Screen") then
			arg_343_0:draw_screen(var_343_0)
		end

		if arg_343_0:has(var_343_1, "Center") then
			arg_343_0:draw_center(var_343_0)
		end
	end

	arg_343_0:draw_examples(var_343_0)
end

function WS_PRINT_EVENTS.aim_ack(arg_344_0, arg_344_1)
	if not arg_344_1 then
		return
	end

	local var_344_0 = arg_344_0:rt()
	local var_344_1 = globals.realtime or 0
	local var_344_2 = arg_344_1.target or arg_344_1.player or arg_344_1.entity or 0
	local var_344_3 = tostring(arg_344_1.state or "hit")
	local var_344_4 = tonumber(arg_344_1.damage or arg_344_1.wanted_damage or arg_344_1.hitchance or arg_344_1.wanted_hitchance or 0) or 0
	local var_344_5 = tostring(var_344_2) .. "|" .. tostring(arg_344_1.hitgroup or arg_344_1.wanted_hitgroup or 0) .. "|" .. tostring(var_344_4) .. "|" .. var_344_3 .. "|" .. tostring(math.floor(var_344_1 * 20))

	if var_344_0.last_id == var_344_5 and var_344_1 - (var_344_0.last_time or 0) < 0.12 then
		return
	end

	var_344_0.last_id = var_344_5
	var_344_0.last_time = var_344_1

	local var_344_6 = type(var_344_2) == "number" and arg_344_0:ent_name_by_id(var_344_2) or "Name"
	local var_344_7 = type(var_344_2) == "number" and arg_344_0:ent_hp_by_id(var_344_2) or 0
	local var_344_8 = arg_344_0:hg(arg_344_1.hitgroup or arg_344_1.wanted_hitgroup or arg_344_1.hitgroup_id or arg_344_1.wanted_hitgroup_id, arg_344_1.hitgroup_str or arg_344_1.wanted_hitgroup_str)
	local var_344_9 = tonumber(arg_344_1.backtrack or arg_344_1.bt or 0) or 0
	local var_344_10 = tonumber(arg_344_1.spread or 0) or 0

	if arg_344_1.state == nil then
		arg_344_0:push("hit", var_344_6, var_344_8, tonumber(arg_344_1.damage or arg_344_1.wanted_damage or 0) or 0, var_344_7, var_344_9, var_344_10, "")
	else
		arg_344_0:push("miss", var_344_6, var_344_8, tonumber(arg_344_1.wanted_damage or arg_344_1.damage or arg_344_1.dmg or arg_344_1.wanted_dmg or 0) or 0, var_344_7, var_344_9, var_344_10, tostring(arg_344_1.state))
	end
end

function WS_PRINT_EVENTS.item_purchase(arg_345_0, arg_345_1)
	local var_345_0 = var_0_24.other.misc.print_events

	if not var_345_0 or not var_345_0:get() then
		return
	end

	local var_345_1 = var_345_0.events and var_345_0.events:get() or {}

	if not arg_345_0:has(var_345_1, "Purchases") then
		return
	end

	local var_345_2 = arg_345_1 and (arg_345_1.userid or arg_345_1.user_id) or nil
	local var_345_3

	pcall(function()
		var_345_3 = entity.get(var_345_2, true)
	end)

	if not var_345_3 then
		return
	end

	local var_345_4 = false

	pcall(function()
		var_345_4 = var_345_3:is_enemy()
	end)

	if not var_345_4 then
		return
	end

	local var_345_5 = "Name"

	pcall(function()
		var_345_5 = var_345_3:get_name() or "Name"
	end)
	arg_345_0:push("purchase", var_345_5, tostring(arg_345_1.weapon or arg_345_1.item or "weapon"), 0, 0, 0, 0, "")
end

function WS_PRINT_EVENTS.player_death(arg_349_0, arg_349_1)
	local var_349_0 = var_0_24.other.misc.print_events

	if not var_349_0 or not var_349_0:get() then
		return
	end

	local var_349_1 = var_349_0.events and var_349_0.events:get() or {}

	if not arg_349_0:has(var_349_1, "Kill") then
		return
	end

	local var_349_2 = entity.get_local_player()

	if not var_349_2 then
		return
	end

	local var_349_3
	local var_349_4

	pcall(function()
		var_349_3 = entity.get(arg_349_1.userid, true)
		var_349_4 = entity.get(arg_349_1.attacker, true)
	end)

	if var_349_4 == var_349_2 and var_349_3 ~= var_349_2 and var_349_3 ~= nil then
		local var_349_5 = "Name"

		pcall(function()
			var_349_5 = var_349_3:get_name() or "Name"
		end)
		arg_349_0:push("kill", var_349_5, "", 0, 0, 0, 0, "")
	end
end

WS_HITMARKER = {}

function WS_HITMARKER.rt(arg_352_0)
	var_0_25._hm_rt = var_0_25._hm_rt or {
		fadetime = 1,
		m_hit = false,
		wait_time = 0.25,
		fade_time = 0.25,
		shots = {}
	}

	return var_0_25._hm_rt
end

function WS_HITMARKER.has(arg_353_0, arg_353_1, arg_353_2)
	if type(arg_353_1) ~= "table" then
		return arg_353_1 == arg_353_2
	end

	for iter_353_0, iter_353_1 in pairs(arg_353_1) do
		if iter_353_1 == arg_353_2 then
			return true
		end
	end

	return false
end

function WS_HITMARKER.enabled(arg_354_0)
	local var_354_0 = var_0_24.other.visual.hitmarker

	return var_354_0 and var_354_0.get and var_354_0:get()
end

function WS_HITMARKER.selected(arg_355_0, arg_355_1)
	local var_355_0 = var_0_24.other.visual.hitmarker

	if not var_355_0 or not var_355_0.marker_select then
		return false
	end

	local var_355_1 = {}

	pcall(function()
		var_355_1 = var_355_0.marker_select:get() or {}
	end)

	return arg_355_0:has(var_355_1, arg_355_1)
end

function WS_HITMARKER.col(arg_357_0, arg_357_1, arg_357_2)
	local var_357_0 = var_0_24.other.visual.hitmarker

	if not var_357_0 then
		return color(255, 255, 255, math.floor(255 * arg_357_2))
	end

	local var_357_1

	if arg_357_1 == "kibit" then
		pcall(function()
			var_357_1 = var_357_0.kibit_color:get()
		end)
	else
		pcall(function()
			var_357_1 = var_357_0.center_color:get()
		end)
	end

	var_357_1 = var_357_1 or color(255, 255, 255, 255)

	return color(var_357_1.r, var_357_1.g, var_357_1.b, math.floor((var_357_1.a or 255) * arg_357_2))
end

function WS_HITMARKER.reset(arg_360_0)
	local var_360_0 = arg_360_0:rt()

	var_360_0.m_hit = false
	var_360_0.fadetime = 1
	var_360_0.fade_time = 0.25
	var_360_0.wait_time = 0.25
	var_360_0.shots = {}
end

function WS_HITMARKER.player_hurt(arg_361_0, arg_361_1)
	if not arg_361_0:enabled() or not arg_361_0:selected("Center") then
		return
	end

	local var_361_0 = entity.get_local_player()
	local var_361_1

	pcall(function()
		var_361_1 = entity.get(arg_361_1.attacker, true)
	end)

	if var_361_0 and var_361_1 == var_361_0 then
		local var_361_2 = arg_361_0:rt()

		var_361_2.m_hit = true
		var_361_2.fade_time = 0.25
		var_361_2.wait_time = 0.25
		var_361_2.fadetime = 1
	end
end

function WS_HITMARKER.player_spawned(arg_363_0, arg_363_1)
	local var_363_0 = entity.get_local_player()
	local var_363_1

	pcall(function()
		var_363_1 = entity.get(arg_363_1.userid, true)
	end)

	if var_363_0 and var_363_1 == var_363_0 then
		arg_363_0:reset()
	end
end

function WS_HITMARKER.aim_ack(arg_365_0, arg_365_1)
	if not arg_365_0:enabled() or not arg_365_0:selected("Kibit") then
		return
	end

	if not arg_365_1 or arg_365_1.state ~= nil then
		return
	end

	local var_365_0

	pcall(function()
		var_365_0 = arg_365_1.aim
	end)

	if not var_365_0 then
		pcall(function()
			var_365_0 = arg_365_1.position
		end)
	end

	if not var_365_0 then
		pcall(function()
			var_365_0 = arg_365_1.pos
		end)
	end

	if not var_365_0 then
		return
	end

	if var_365_0.x == nil or var_365_0.y == nil or var_365_0.z == nil then
		return
	end

	local var_365_1 = arg_365_0:rt()
	local var_365_2 = arg_365_1.id or globals.tickcount or #var_365_1.shots + 1

	var_365_1.shots[var_365_2] = {
		FadeTime = 1,
		WaitTime = 1,
		Position = var_365_0,
		Reason = arg_365_1.state
	}
end

function WS_HITMARKER.draw_center(arg_369_0)
	local var_369_0 = arg_369_0:rt()

	if not var_369_0.m_hit then
		return
	end

	if globals.is_in_game == false then
		return
	end

	local var_369_1 = render.screen_size()

	var_369_0.wait_time = (var_369_0.wait_time or 0.25) - globals.frametime

	if var_369_0.wait_time <= 0 then
		var_369_0.fadetime = (var_369_0.fadetime or 1) - 1 / (var_369_0.fade_time or 0.25) * globals.frametime
	end

	if var_369_0.fadetime <= 0 then
		var_369_0.m_hit = false
		var_369_0.fadetime = 0

		return
	end

	local var_369_2 = arg_369_0:col("center", var_369_0.fadetime)

	render.line(vector(var_369_1.x / 2 + 5, var_369_1.y / 2 + 5), vector(var_369_1.x / 2 + 10, var_369_1.y / 2 + 10), var_369_2)
	render.line(vector(var_369_1.x / 2 - 5, var_369_1.y / 2 + 5), vector(var_369_1.x / 2 - 10, var_369_1.y / 2 + 10), var_369_2)
	render.line(vector(var_369_1.x / 2 - 5, var_369_1.y / 2 - 5), vector(var_369_1.x / 2 - 10, var_369_1.y / 2 - 10), var_369_2)
	render.line(vector(var_369_1.x / 2 + 5, var_369_1.y / 2 - 5), vector(var_369_1.x / 2 + 10, var_369_1.y / 2 - 10), var_369_2)
end

function WS_HITMARKER.draw_kibit(arg_370_0)
	local var_370_0 = arg_370_0:rt()

	var_370_0.shots = var_370_0.shots or {}

	for iter_370_0, iter_370_1 in pairs(var_370_0.shots) do
		if (iter_370_1.FadeTime or 0) <= 0 then
			var_370_0.shots[iter_370_0] = nil
		else
			iter_370_1.WaitTime = (iter_370_1.WaitTime or 1) - globals.frametime

			if iter_370_1.WaitTime <= 0 then
				iter_370_1.FadeTime = (iter_370_1.FadeTime or 1) - 2 * globals.frametime
			end

			if iter_370_1.Position and iter_370_1.Position.x ~= nil and iter_370_1.Position.y ~= nil and iter_370_1.Position.z ~= nil and iter_370_1.Reason == nil then
				local var_370_1

				pcall(function()
					var_370_1 = render.world_to_screen(vector(iter_370_1.Position.x, iter_370_1.Position.y, iter_370_1.Position.z))
				end)

				if var_370_1 ~= nil then
					local var_370_2 = arg_370_0:col("kibit", iter_370_1.FadeTime or 1)

					render.rect(vector(var_370_1.x - 1, var_370_1.y - 5), vector(var_370_1.x + 1, var_370_1.y + 5), var_370_2, 0, true)
					render.rect(vector(var_370_1.x - 5, var_370_1.y - 1), vector(var_370_1.x + 5, var_370_1.y + 1), var_370_2, 0, true)
				end
			end
		end
	end
end

function WS_HITMARKER.draw(arg_372_0)
	if not arg_372_0:enabled() then
		return
	end

	if arg_372_0:selected("Center") then
		arg_372_0:draw_center()
	end

	if arg_372_0:selected("Kibit") then
		arg_372_0:draw_kibit()
	end
end

WS_CROSSHAIR_STYLE = {}

function WS_CROSSHAIR_STYLE.run(arg_373_0)
	local var_373_0 = var_0_24.other.visual.crosshair_style

	if not var_373_0 then
		return
	end

	if not var_373_0:get() then
		if arg_373_0.last ~= nil then
			arg_373_0.last = nil
		end

		return
	end

	local var_373_1 = 100

	pcall(function()
		var_373_1 = tonumber(var_373_0.style:get()) or 100
	end)

	local var_373_2 = 100
	local var_373_3 = var_373_1 == 101 and 4 or var_373_1 == 102 and 5 or 100

	if arg_373_0.last == var_373_3 then
		return
	end

	arg_373_0.last = var_373_3

	pcall(function()
		cvar.cl_crosshairstyle:int(var_373_3, true)
	end)
	pcall(function()
		utils.console_exec("cl_crosshairstyle " .. tostring(var_373_3))
	end)
end

function WS_CROSSHAIR_STYLE.shutdown(arg_377_0)
	pcall(function()
		cvar.cl_crosshairstyle:int(100, true)
	end)
	pcall(function()
		utils.console_exec("cl_crosshairstyle 100")
	end)

	arg_377_0.last = nil
end

WS_AUTO_CLEAR = {}

function WS_AUTO_CLEAR.has(arg_380_0, arg_380_1, arg_380_2)
	if type(arg_380_1) ~= "table" then
		return arg_380_1 == arg_380_2
	end

	for iter_380_0, iter_380_1 in pairs(arg_380_1) do
		if iter_380_1 == arg_380_2 then
			return true
		end
	end

	return false
end

function WS_AUTO_CLEAR.run(arg_381_0, arg_381_1)
	local var_381_0 = var_0_24.other.misc.auto_clear

	if not var_381_0 or not var_381_0:get() then
		return
	end

	local var_381_1 = var_381_0.when and var_381_0.when:get() or {}

	if arg_381_1 == "round_start" and not arg_381_0:has(var_381_1, "Round Start") then
		return
	end

	if arg_381_1 == "match_end" and not arg_381_0:has(var_381_1, "Match End") then
		return
	end

	pcall(function()
		utils.console_exec("clear")
	end)
	pcall(function()
		print_raw("")
	end)
end

WS_CLANTAG = {
	next_time = 0,
	frames = {
		"#",
		"#W",
		"#WH",
		"#WHI",
		"#WHIT",
		"#WHITE",
		"#WHITES",
		"#WHITEST",
		"#WHITESTR",
		"#WHITESTRI",
		"#WHITESTRIK",
		"#WHITESTRIKE",
		"#WHITESTRIKE",
		"#WHITESTRIKE",
		"#WHITESTRIKE",
		"#WHITESTRIK",
		"#WHITESTRI",
		"#WHITESTR",
		"#WHITEST",
		"#WHITES",
		"#WHITE",
		"#WHIT",
		"#WHI",
		"#WH",
		"#W",
		"#",
		""
	}
}

function WS_CLANTAG.enabled(arg_384_0)
	local var_384_0 = var_0_24.other.misc.clan_tag

	return var_384_0 and var_384_0.get and var_384_0:get()
end

function WS_CLANTAG.set(arg_385_0, arg_385_1)
	if arg_385_0.last == arg_385_1 then
		return
	end

	arg_385_0.last = arg_385_1

	pcall(function()
		common.set_clan_tag(arg_385_1)
	end)
	pcall(function()
		utils.set_clan_tag(arg_385_1)
	end)
	pcall(function()
		clan_tag(arg_385_1)
	end)
end

function WS_CLANTAG.run(arg_389_0)
	local var_389_0 = globals.realtime or 0

	if not arg_389_0:enabled() then
		if arg_389_0.last ~= nil and arg_389_0.last ~= "" then
			arg_389_0:set("")
		end

		arg_389_0.last_i = nil
		arg_389_0.next_time = 0

		return
	end

	if var_389_0 < (arg_389_0.next_time or 0) then
		return
	end

	arg_389_0.next_time = var_389_0 + 0.22
	arg_389_0.last_i = (arg_389_0.last_i or 0) + 1

	if arg_389_0.last_i > #arg_389_0.frames then
		arg_389_0.last_i = 1
	end

	arg_389_0:set(arg_389_0.frames[arg_389_0.last_i] or "#WHITESTRIKE")
end

function WS_CLANTAG.shutdown(arg_390_0)
	arg_390_0:set("")

	arg_390_0.last = nil
	arg_390_0.last_i = nil
	arg_390_0.next_time = 0
end

WS_TRASHTALK = {
	last_event = 0,
	next_time = 0,
	queue = {}
}

function WS_TRASHTALK.enabled(arg_391_0)
	local var_391_0 = var_0_24.other.misc.trash_talk

	return var_391_0 and var_391_0.get and var_391_0:get()
end

function WS_TRASHTALK.has(arg_392_0, arg_392_1, arg_392_2)
	if type(arg_392_1) ~= "table" then
		return arg_392_1 == arg_392_2
	end

	for iter_392_0, iter_392_1 in pairs(arg_392_1) do
		if iter_392_1 == arg_392_2 then
			return true
		end
	end

	return false
end

function WS_TRASHTALK.lang(arg_393_0)
	local var_393_0 = var_0_24.other.misc.trash_talk

	if not var_393_0 or not var_393_0.language then
		return "Russian"
	end

	local var_393_1 = var_393_0.language:get()

	if var_393_1 == 2 or var_393_1 == "English" then
		return "English"
	end

	if var_393_1 == 3 or var_393_1 == "Combo" then
		return "Combo"
	end

	return "Russian"
end

function WS_TRASHTALK.delay(arg_394_0)
	local var_394_0 = var_0_24.other.misc.trash_talk
	local var_394_1 = 8

	pcall(function()
		var_394_1 = tonumber(var_394_0.delay:get()) or 8
	end)

	return math.max(0.1, var_394_1 / 10)
end

function WS_TRASHTALK.can_trigger(arg_396_0, arg_396_1)
	local var_396_0 = var_0_24.other.misc.trash_talk

	if not var_396_0 or not var_396_0.triggers then
		return false
	end

	return arg_396_0:has(var_396_0.triggers:get() or {}, arg_396_1)
end

function WS_TRASHTALK.say(arg_397_0, arg_397_1)
	if not arg_397_1 or arg_397_1 == "" then
		return
	end

	pcall(function()
		utils.console_exec("say " .. arg_397_1)
	end)
end

function WS_TRASHTALK.pick(arg_399_0, arg_399_1)
	if not arg_399_1 or #arg_399_1 == 0 then
		return ""
	end

	return arg_399_1[math.random(1, #arg_399_1)]
end

function WS_TRASHTALK.make_cycle(arg_400_0, arg_400_1, arg_400_2)
	arg_400_2 = tostring(arg_400_2 or "you")

	local var_400_0 = {
		{
			"Я будто весь в алмазной броне",
			"Урон вообще не чувствую)"
		},
		{
			"Еще один мусор " .. arg_400_2 .. " не смог дать отпор:(",
			"Ливни уже дружище",
			"У тебя нет нормальных анти аимов)"
		},
		{
			"Ангелы сами держут мой прицел на твоей голове",
			"Закупись в магазине whitestrike"
		},
		{
			"Белый удар пришелся тебе дорого",
			"Трудно наверное сидеть в спеках...",
			"И мечтать об whitestrike)))"
		},
		{
			"Эта зима будет особенно теплой",
			"Ведь что может еще согреть кроме теплого чая и хвх?"
		},
		{
			"Почему же ты не можешь попасть?",
			"Почему ты опять падаешь?",
			"Почему у тебя нет Whitestrike?)"
		},
		{
			"ну что, " .. arg_400_2 .. ", понравилось?",
			"это был не раунд, это урок",
			"запомни тег #WHITESTRIKE"
		}
	}
	local var_400_1 = {
		{
			"sit down, " .. arg_400_2,
			"whitestrike just farmed you",
			"try turning your monitor on next time"
		},
		{
			"too easy, " .. arg_400_2,
			"you got deleted by whitestrike",
			"stop donating rounds"
		},
		{
			"cleaned you like dust",
			"whitestrike leaves no witnesses",
			"go warm up, " .. arg_400_2
		},
		{
			"nice try, " .. arg_400_2,
			"that was a lesson, not a duel",
			"remember #WHITESTRIKE"
		}
	}
	local var_400_2 = {
		{
			"Везет же новичкам",
			"Не бойсь играешь с фри кфг?"
		},
		{
			"Ватафаг нафиг",
			"Это что за резольвер такой?",
			"Как можно фиксить мои анти аимы?"
		},
		{
			"наслаждайся моментом",
			"это твой единственный хайлайт за карту",
			"дальше будет больно"
		}
	}
	local var_400_3 = {
		{
			"enjoy the gift",
			"one lucky kill does not make you good",
			"next one is mine"
		},
		{
			"you got me once, do not get excited",
			"whitestrike is already coming back",
			"prepare to drop"
		},
		{
			"enjoy your only highlight",
			"that luck will not happen twice",
			"next round you disappear"
		}
	}
	local var_400_4 = arg_400_0:lang()
	local var_400_5

	if arg_400_1 == "kill" then
		if var_400_4 == "English" then
			var_400_5 = var_400_1
		elseif var_400_4 == "Combo" then
			var_400_5 = math.random(1, 2) == 1 and var_400_0 or var_400_1
		else
			var_400_5 = var_400_0
		end
	elseif var_400_4 == "English" then
		var_400_5 = var_400_3
	elseif var_400_4 == "Combo" then
		var_400_5 = math.random(1, 2) == 1 and var_400_2 or var_400_3
	else
		var_400_5 = var_400_2
	end

	local var_400_6 = arg_400_0:pick(var_400_5)
	local var_400_7 = {}

	for iter_400_0 = 1, #var_400_6 do
		var_400_7[#var_400_7 + 1] = var_400_6[iter_400_0]
	end

	return var_400_7
end

function WS_TRASHTALK.push(arg_401_0, arg_401_1, arg_401_2)
	if not arg_401_0:enabled() then
		return
	end

	local var_401_0 = globals.realtime or 0

	if var_401_0 - (arg_401_0.last_event or 0) < 0.05 then
		return
	end

	arg_401_0.last_event = var_401_0

	local var_401_1 = arg_401_0:make_cycle(arg_401_1, arg_401_2)

	if var_401_1 and #var_401_1 > 0 then
		table.insert(arg_401_0.queue, {
			index = 1,
			phrases = var_401_1
		})
	end
end

function WS_TRASHTALK.run(arg_402_0)
	if not arg_402_0:enabled() then
		arg_402_0.queue = {}
		arg_402_0.active = nil

		return
	end

	local var_402_0 = globals.realtime or 0

	if not arg_402_0.active and #arg_402_0.queue > 0 then
		arg_402_0.active = table.remove(arg_402_0.queue, 1)
		arg_402_0.next_time = 0
	end

	if not arg_402_0.active then
		return
	end

	if var_402_0 < (arg_402_0.next_time or 0) then
		return
	end

	local var_402_1 = arg_402_0.active.phrases[arg_402_0.active.index]

	if var_402_1 then
		arg_402_0:say(var_402_1)

		arg_402_0.active.index = arg_402_0.active.index + 1
		arg_402_0.next_time = var_402_0 + arg_402_0:delay()
	else
		arg_402_0.active = nil
		arg_402_0.next_time = var_402_0 + 0.05
	end
end

function WS_TRASHTALK.player_death(arg_403_0, arg_403_1)
	if not arg_403_0:enabled() then
		return
	end

	local var_403_0 = entity.get_local_player()

	if not var_403_0 then
		return
	end

	local var_403_1
	local var_403_2

	pcall(function()
		var_403_1 = entity.get(arg_403_1.userid, true)
		var_403_2 = entity.get(arg_403_1.attacker, true)
	end)

	if not var_403_1 or not var_403_2 then
		return
	end

	if var_403_2 == var_403_0 and var_403_1 ~= var_403_0 then
		if arg_403_0:can_trigger("On Kill") then
			local var_403_3 = "enemy"

			pcall(function()
				var_403_3 = var_403_1:get_name() or "enemy"
			end)
			arg_403_0:push("kill", var_403_3)
		end

		return
	end

	if var_403_1 == var_403_0 and var_403_2 ~= var_403_0 and arg_403_0:can_trigger("On Death") then
		local var_403_4 = "enemy"

		pcall(function()
			var_403_4 = var_403_2:get_name() or "enemy"
		end)
		arg_403_0:push("death", var_403_4)
	end
end

function WS_TRASHTALK.reset(arg_407_0)
	arg_407_0.queue = {}
	arg_407_0.active = nil
	arg_407_0.next_time = 0
	arg_407_0.last_event = 0
end

local function var_0_101()
	local var_408_0 = var_0_24.other.visual.aspect_ratio

	if not var_408_0 or not var_408_0.asp_value then
		return
	end

	local var_408_1 = tonumber(var_408_0.asp_value:get()) or 0
	local var_408_2 = var_408_1 <= 0 and 0 or var_408_1 / 100

	pcall(function()
		if var_0_9.unlock_hidden then
			var_0_9.unlock_hidden:override(true)
		end
	end)
	pcall(function()
		if cvar and cvar.r_aspectratio then
			cvar.r_aspectratio:float(var_408_2, true)
		end
	end)
	pcall(function()
		if cvar and cvar.r_aspectratio then
			cvar.r_aspectratio:float(var_408_2)
		end
	end)
	pcall(function()
		if utils and utils.console_exec then
			utils.console_exec("r_aspectratio " .. string.format("%.2f", var_408_2))
		end
	end)
end

local function var_0_102(arg_413_0, arg_413_1, arg_413_2)
	return arg_413_0 == arg_413_2 or arg_413_0 == arg_413_1
end

local function var_0_103(arg_414_0, arg_414_1)
	if type(arg_414_0) ~= "table" then
		return arg_414_0 == arg_414_1
	end

	for iter_414_0, iter_414_1 in pairs(arg_414_0) do
		if iter_414_1 == arg_414_1 then
			return true
		end
	end

	return false
end

local function var_0_104(arg_415_0)
	if not arg_415_0 or not arg_415_0.m_vecVelocity then
		return false
	end

	return math.sqrt(arg_415_0.m_vecVelocity.x^2 + arg_415_0.m_vecVelocity.y^2) > 5
end

local function var_0_105(arg_416_0)
	if not arg_416_0 then
		return false
	end

	return bit.band(arg_416_0.m_fFlags or 0, 1) == 0
end

local function var_0_106()
	if var_0_8 == nil then
		return nil
	end

	local var_417_0, var_417_1 = pcall(function()
		return ffi.cast("animstate_layer_t**", ffi.cast("uintptr_t", var_0_8) + 10640)[0]
	end)

	if var_417_0 and var_417_1 ~= nil then
		return var_417_1
	end

	return nil
end

local function var_0_107(arg_419_0)
	local var_419_0 = var_0_106()

	if var_419_0 == nil then
		return nil
	end

	local var_419_1, var_419_2 = pcall(function()
		return var_419_0[arg_419_0]
	end)

	if var_419_1 then
		return var_419_2
	end

	return nil
end

local function var_0_108()
	local var_421_0 = var_0_24.other.misc.client_anim

	if not var_421_0 or not var_421_0:get() then
		return
	end

	local var_421_1 = entity.get_local_player()

	if var_421_1 == nil or not var_421_1:is_alive() then
		return
	end

	if not var_421_1.get_index or var_421_1:get_index() == nil then
		return
	end

	var_0_8 = var_0_7.get_entity_address(var_421_1:get_index())

	if var_0_8 == nil then
		return
	end

	local var_421_2

	if var_421_1.get_anim_state then
		local var_421_3, var_421_4 = pcall(function()
			return var_421_1:get_anim_state()
		end)

		if var_421_3 then
			var_421_2 = var_421_4
		end
	end

	local var_421_5 = var_0_104(var_421_1)
	local var_421_6 = var_0_105(var_421_1)
	local var_421_7 = var_421_0.ground_legs:get()
	local var_421_8 = var_421_0.air_legs:get()
	local var_421_9 = var_421_0.addons:get() or {}

	if var_0_102(var_421_7, "Reversed", 2) then
		var_421_1.m_flPoseParameter[0] = 1

		if var_0_9.antiaim.leg_movement then
			var_0_9.antiaim.leg_movement:override("Sliding")
		end
	elseif var_0_102(var_421_7, "Jitter", 3) then
		var_421_1.m_flPoseParameter[0] = utils.random_float(0.1, 1)

		if var_0_9.antiaim.leg_movement then
			var_0_9.antiaim.leg_movement:override("Sliding")
		end
	elseif var_0_102(var_421_7, "Moonwalk", 4) and var_421_5 and not var_421_6 then
		var_421_1.m_flPoseParameter[7] = 1

		if var_0_9.antiaim.leg_movement then
			var_0_9.antiaim.leg_movement:override("Walking")
		end
	elseif var_0_9.antiaim.leg_movement then
		var_0_9.antiaim.leg_movement:override()
	end

	if var_0_102(var_421_8, "Static", 2) then
		var_421_1.m_flPoseParameter[6] = 1
	elseif var_0_102(var_421_8, "Jitter", 3) then
		var_421_1.m_flPoseParameter[6] = globals.tickcount % 4 > 1 and utils.random_float(0.1, 1) or utils.random_float(0.1, 1)
	elseif var_0_102(var_421_8, "Moonwalk", 4) and var_421_6 and var_421_5 then
		local var_421_10 = var_0_107(6)

		if var_421_10 ~= nil then
			var_421_10.m_flWeight = 1
		end
	else
		var_421_1.m_flPoseParameter[6] = 0
	end

	if var_0_103(var_421_9, "Pitch Zero On Land") and var_421_2 ~= nil and var_421_2.landing then
		var_421_1.m_flPoseParameter[12] = 0.5
	elseif var_0_103(var_421_9, "Move Lean") and var_421_5 then
		local var_421_11 = var_0_107(12)

		if var_421_11 ~= nil then
			var_421_11.m_flWeight = (var_421_0.move_lean_amount:get() or 0) / 100
		end
	elseif var_0_103(var_421_9, "Earthquake") then
		local var_421_12 = var_0_107(12)

		if var_421_12 ~= nil then
			var_421_12.m_flWeight = utils.random_float(0.1, 1)
		end
	end
end

local var_0_109

local function var_0_110()
	return var_0_24.other.misc.viewmodel_changer
end

local function var_0_111(arg_424_0)
	local var_424_0 = var_0_110()

	return var_424_0 and var_0_32(var_424_0.options:get() or {}, arg_424_0)
end

local function var_0_112(arg_425_0, arg_425_1, arg_425_2)
	if not arg_425_0 then
		return
	end

	pcall(function()
		arg_425_0:float((tonumber(arg_425_1) or arg_425_2) / 100, true)
	end)
end

local function var_0_113(arg_427_0, arg_427_1)
	if not arg_427_0 then
		return
	end

	pcall(function()
		arg_427_0:int(arg_427_1)
	end)
end

local function var_0_114()
	if var_0_109 ~= nil then
		var_0_113(cvar.cl_righthand, var_0_109)

		var_0_109 = nil
	end
end

local function var_0_115()
	local var_430_0 = var_0_110()

	if not var_430_0 then
		return
	end

	var_430_0.fov:set(6800)
	var_430_0.x:set(250)
	var_430_0.y:set(0)
	var_430_0.z:set(-150)
	var_0_112(cvar.viewmodel_fov, 6800, 6800)
	var_0_112(cvar.viewmodel_offset_x, 250, 250)
	var_0_112(cvar.viewmodel_offset_y, 0, 0)
	var_0_112(cvar.viewmodel_offset_z, -150, -150)
end

local function var_0_116()
	local var_431_0 = var_0_110()

	if not var_431_0 then
		return
	end

	local var_431_1 = var_431_0:get()

	if var_431_1 then
		var_0_112(cvar.viewmodel_fov, var_431_0.fov:get(), 6800)
		var_0_112(cvar.viewmodel_offset_x, var_431_0.x:get(), 250)
		var_0_112(cvar.viewmodel_offset_y, var_431_0.y:get(), 0)
		var_0_112(cvar.viewmodel_offset_z, var_431_0.z:get(), -150)
	else
		var_0_112(cvar.viewmodel_fov, 6800, 6800)
		var_0_112(cvar.viewmodel_offset_x, 250, 250)
		var_0_112(cvar.viewmodel_offset_y, 0, 0)
		var_0_112(cvar.viewmodel_offset_z, -150, -150)
		var_0_114()
	end

	if var_0_9.force_viewmodel then
		pcall(function()
			var_0_9.force_viewmodel:override(var_431_1 and var_0_111("Viewmodel in scope") or false)
		end)
	end

	if not var_431_1 then
		return
	end

	local var_431_2 = entity.get_local_player()

	if not var_0_111("Left knife") or not var_431_2 or not var_431_2:is_alive() then
		var_0_114()

		return
	end

	local var_431_3 = var_431_2:get_player_weapon()
	local var_431_4 = var_431_3 and var_431_3.get_classname and var_431_3:get_classname() or ""

	if tostring(var_431_4):find("Knife", 1, true) ~= nil or tostring(var_431_4):find("Bayonet", 1, true) ~= nil then
		if var_0_109 == nil then
			local var_431_5, var_431_6 = pcall(function()
				return cvar.cl_righthand:int()
			end)

			var_0_109 = var_431_5 and var_431_6 or 1
		end

		var_0_113(cvar.cl_righthand, var_0_109 == 1 and 0 or 1)
	else
		var_0_114()
	end
end

local function var_0_117()
	local var_434_0 = entity.get_local_player()

	if not var_434_0 or not var_434_0:is_alive() then
		var_0_17.runtime.current = 1
		var_0_17.runtime.onground_ticks = 0

		return
	end

	local var_434_1 = 0
	local var_434_2 = 0

	pcall(function()
		var_434_1 = var_434_0.m_vecVelocity.x or 0
		var_434_2 = var_434_0.m_vecVelocity.y or 0
	end)

	var_0_17.runtime.speed = math.sqrt(var_434_1 * var_434_1 + var_434_2 * var_434_2)
	var_0_17.runtime.duck = var_434_0.m_flDuckAmount or 0

	local var_434_3 = var_434_0.m_fFlags or 0

	if bit.band(var_434_3, 1) == 1 then
		var_0_17.runtime.onground_ticks = (var_0_17.runtime.onground_ticks or 0) + 1
	else
		var_0_17.runtime.onground_ticks = 0
	end

	var_0_17.runtime.ground = (var_0_17.runtime.onground_ticks or 0) > 4

	local var_434_4 = false

	pcall(function()
		var_434_4 = var_0_24.antiaim.help.manual_yaw:get() ~= "Disabled"
	end)

	local var_434_5 = false

	pcall(function()
		var_434_5 = var_0_24.antiaim.help.freestanding:get()
	end)

	if var_434_4 then
		var_0_17.runtime.current = 10
	elseif var_434_5 then
		var_0_17.runtime.current = 9
	elseif not var_0_17.runtime.ground then
		if var_0_17.runtime.duck > 0.7 then
			var_0_17.runtime.current = 5
		else
			var_0_17.runtime.current = 4
		end
	elseif var_0_17.runtime.duck > 0.7 then
		if var_0_17.runtime.speed > 5 then
			var_0_17.runtime.current = 7
		else
			var_0_17.runtime.current = 6
		end
	elseif var_0_9.antiaim.aa_slowwalk and var_0_9.antiaim.aa_slowwalk:get() then
		var_0_17.runtime.current = 8
	elseif var_0_17.runtime.speed > 5 then
		var_0_17.runtime.current = 3
	else
		var_0_17.runtime.current = 2
	end
end

events.aim_ack(function(arg_438_0)
	local var_438_0 = var_0_25._ci_rt

	var_438_0.gi_hits = var_438_0.gi_hits or 0
	var_438_0.gi_shots = var_438_0.gi_shots or 0
	var_438_0.gi_shots = var_438_0.gi_shots + 1

	if arg_438_0 and arg_438_0.state == nil then
		var_438_0.gi_hits = var_438_0.gi_hits + 1

		if WS_HITMARKER and WS_HITMARKER.aim_ack then
			WS_HITMARKER:aim_ack(arg_438_0)
		end
	end

	if WS_PRINT_EVENTS and WS_PRINT_EVENTS.aim_ack then
		WS_PRINT_EVENTS:aim_ack(arg_438_0)
	end
end)

local function var_0_118()
	return {
		right = 0,
		degree = 0,
		modifier = "Disabled",
		custom_way = 1,
		mode = "Default",
		override = false,
		left = 0,
		custom_count = 1,
		spin_seed = 10,
		lc_max = 0,
		lc_min = 0,
		randomize = 0,
		yaw_base = {
			base = "Local View"
		},
		lr_state = {
			next_switch = 0,
			side = false
		},
		custom = {
			0,
			0,
			0,
			0,
			0,
			0
		},
		delay = {
			count = 1,
			activation = "Stable",
			mode = "Default",
			to = 1,
			enable = false,
			from = 1,
			hold = 1,
			randomize = 0,
			values = {
				1,
				1,
				1,
				1,
				1,
				1
			}
		},
		desync = {
			right = 0,
			left = 0,
			to = 0,
			from = 0,
			limit_mode = "Default",
			speed = 1,
			mode = "Off",
			delay = 0
		},
		extension = {
			break_lc_disable_qp = false,
			break_lc = {},
			tickbase = {
				mode = "Default",
				choke = 16,
				random = false,
				choke2 = 16
			}
		},
		defensive = {
			yaw_second = 0,
			modifier = "Disabled",
			yaw_first = 0,
			modifier_mode = "Randomize",
			modifier_offset = 0,
			pitch_custom = 0,
			pitch_second = 0,
			pitch_first = 0,
			modifier_min = 0,
			enable = false,
			modifier_randomize = 0,
			modifier_max = 0,
			pitch = "Disabled",
			yaw_custom = 0,
			yaw_speed = 1,
			yaw = "Disabled"
		}
	}
end

local var_0_119 = {}

for iter_0_4, iter_0_5 in ipairs(var_0_17.cond) do
	var_0_119[iter_0_5] = {
		z1 = {
			t = var_0_118(),
			ct = var_0_118()
		}
	}
end

local var_0_120 = {
	antiaim = {
		wrmp = {
			speed = 4,
			mode = "Full",
			selection = {}
		}
	},
	visual = {},
	misc = {},
	other = {}
}

local function var_0_121()
	local var_440_0 = var_0_24.antiaim.left.current:get()

	var_440_0 = var_0_20[var_440_0] or var_440_0

	for iter_440_0, iter_440_1 in ipairs(var_0_17.cond) do
		if var_440_0 == iter_440_1 then
			return iter_440_0
		end
	end

	return 1
end

local function var_0_122()
	local var_441_0 = var_0_29()

	if var_441_0 == 2 or var_441_0 == "Counter Terrorist" then
		return "ct"
	end

	return "t"
end

local function var_0_123()
	local var_442_0 = entity.get_local_player()

	if not var_442_0 then
		return var_0_122()
	end

	return var_442_0.m_iTeamNum == 3 and "ct" or "t"
end

local function var_0_124(arg_443_0, arg_443_1)
	if not var_0_119[arg_443_0] then
		return nil
	end

	arg_443_1 = arg_443_1 or var_0_122()
	var_0_119[arg_443_0].z1[arg_443_1] = var_0_119[arg_443_0].z1[arg_443_1] or var_0_118()

	return var_0_119[arg_443_0].z1[arg_443_1]
end

local function var_0_125(arg_444_0)
	if type(arg_444_0) ~= "table" then
		return arg_444_0
	end

	local var_444_0 = {}

	for iter_444_0, iter_444_1 in pairs(arg_444_0) do
		var_444_0[iter_444_0] = var_0_125(iter_444_1)
	end

	return var_444_0
end

local function var_0_126(arg_445_0, arg_445_1)
	local var_445_0 = var_0_17.cond[arg_445_0]

	if not var_445_0 then
		return
	end

	local var_445_1 = var_0_124(var_445_0, arg_445_1 or var_0_122())

	if not var_445_1 then
		return
	end

	local var_445_2 = var_0_24.antiaim.left.aa.yawbase
	local var_445_3 = var_0_24.antiaim.left.aa.yawjitter.lr.yawbuilder
	local var_445_4 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier
	local var_445_5 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay
	local var_445_6 = var_0_24.antiaim.left.aa.yawjitter.lr.desync
	local var_445_7 = var_0_24.antiaim.left.aa.extension.break_lc
	local var_445_8 = var_0_24.antiaim.left.aa.extension.tickbase
	local var_445_9 = var_0_24.antiaim.left.aa.defensive

	var_445_1.override = var_445_0 ~= "Shared" and var_0_24.antiaim.left.override[var_445_0] and var_0_24.antiaim.left.override[var_445_0]:get() or false
	var_445_1.yaw_base.base = var_445_2:get() or "Local View"
	var_445_1.left = var_445_3.yaw_left:get() or 0
	var_445_1.right = var_445_3.yaw_right:get() or 0
	var_445_1.modifier = var_445_4.modifier:get() or "Disabled"
	var_445_1.mode = var_445_4.mode:get() or "Default"
	var_445_1.degree = var_445_4.degree:get() or 0
	var_445_1.randomize = var_445_4.randomize:get() or 0
	var_445_1.lc_min = var_445_4.lc_min:get() or 0
	var_445_1.lc_max = var_445_4.lc_max:get() or 0
	var_445_1.spin_seed = var_445_4.spin_seed:get() or 10
	var_445_1.custom_count = var_445_4.custom_count:get() or 3
	var_445_1.custom_way = var_445_4.custom_way:get() or 3

	for iter_445_0 = 1, 6 do
		var_445_1.custom[iter_445_0] = var_445_4.custom[iter_445_0]:get() or 0
	end

	var_445_1.delay.enable = var_445_5.enable:get() or false
	var_445_1.delay.activation = var_445_5.activation:get() or "Stable"
	var_445_1.delay.mode = var_445_5.mode:get() or "Default"
	var_445_1.delay.hold = var_445_5.hold:get() or 1
	var_445_1.delay.randomize = var_445_5.randomize:get() or 0
	var_445_1.delay.from = var_445_5.from:get() or 1
	var_445_1.delay.to = var_445_5.to:get() or 1
	var_445_1.delay.count = var_445_5.count:get() or 1

	for iter_445_1 = 1, 6 do
		var_445_1.delay.values[iter_445_1] = var_445_5.values[iter_445_1]:get() or 1
	end

	var_445_1.desync.mode = var_445_6.mode:get() or "Off"
	var_445_1.desync.delay = var_445_6.delay:get() or 0
	var_445_1.desync.limit_mode = var_445_6.limit_mode:get() or "Default"
	var_445_1.desync.left = var_445_6.left:get() or 0
	var_445_1.desync.right = var_445_6.right:get() or 0
	var_445_1.desync.from = var_445_6.from:get() or 0
	var_445_1.desync.to = var_445_6.to:get() or 0
	var_445_1.desync.speed = var_445_6.speed:get() or 1
	var_445_1.extension = var_445_1.extension or {}
	var_445_1.extension.break_lc = var_445_7.mode:get() or {}
	var_445_1.extension.break_lc_disable_qp = var_445_7.disable_qp:get() or false
	var_445_1.extension.tickbase = var_445_1.extension.tickbase or {}
	var_445_1.extension.tickbase.mode = var_445_8.mode:get() or "Default"
	var_445_1.extension.tickbase.random = var_445_8.random:get() or false
	var_445_1.extension.tickbase.choke = var_445_8.choke:get() or 16
	var_445_1.extension.tickbase.choke2 = var_445_8.choke2:get() or 16
	var_445_1.defensive = var_445_1.defensive or {}
	var_445_1.defensive.enable = var_445_9.enable:get() or false
	var_445_1.defensive.pitch = var_445_9.pitch:get() or "Disabled"
	var_445_1.defensive.pitch_first = var_445_9.pitch_first:get() or 0
	var_445_1.defensive.pitch_second = var_445_9.pitch_second:get() or 0
	var_445_1.defensive.pitch_custom = var_445_9.pitch_custom:get() or 0
	var_445_1.defensive.yaw = var_445_9.yaw:get() or "Disabled"
	var_445_1.defensive.yaw_first = var_445_9.yaw_first:get() or 0
	var_445_1.defensive.yaw_second = var_445_9.yaw_second:get() or 0
	var_445_1.defensive.yaw_speed = var_445_9.yaw_speed:get() or 1
	var_445_1.defensive.yaw_custom = var_445_9.yaw_custom:get() or 0
	var_445_1.defensive.modifier = var_445_9.modifier:get() or "Disabled"
	var_445_1.defensive.modifier_mode = var_445_9.modifier_mode:get() or "Randomize"
	var_445_1.defensive.modifier_offset = var_445_9.modifier_offset:get() or 0
	var_445_1.defensive.modifier_randomize = var_445_9.modifier_randomize:get() or 0
	var_445_1.defensive.modifier_min = var_445_9.modifier_min:get() or 0
	var_445_1.defensive.modifier_max = var_445_9.modifier_max:get() or 0
end

local function var_0_127()
	local var_446_0 = var_0_24.antiaim.left.aa.extension.options

	var_0_120.antiaim.wrmp.selection = var_446_0.selection:get() or {}
	var_0_120.antiaim.wrmp.mode = var_446_0.mode:get() or "Full"
	var_0_120.antiaim.wrmp.speed = var_446_0.speed:get() or 4
end

local function var_0_128(arg_447_0, arg_447_1)
	local var_447_0 = var_0_17.cond[arg_447_0]

	if not var_447_0 then
		return
	end

	local var_447_1 = var_0_124(var_447_0, arg_447_1 or var_0_122())

	if not var_447_1 then
		return
	end

	local var_447_2 = var_0_24.antiaim.left.aa.yawbase
	local var_447_3 = var_0_24.antiaim.left.aa.yawjitter.lr.yawbuilder
	local var_447_4 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier
	local var_447_5 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay
	local var_447_6 = var_0_24.antiaim.left.aa.yawjitter.lr.desync
	local var_447_7 = var_0_24.antiaim.left.aa.extension.break_lc
	local var_447_8 = var_0_24.antiaim.left.aa.extension.tickbase
	local var_447_9 = var_0_24.antiaim.left.aa.defensive

	if var_447_0 ~= "Shared" and var_0_24.antiaim.left.override[var_447_0] then
		var_0_24.antiaim.left.override[var_447_0]:set(var_447_1.override or false)
	end

	var_447_2:set(var_447_1.yaw_base.base or "Local View")
	var_447_3.yaw_left:set(var_447_1.left or 0)
	var_447_3.yaw_right:set(var_447_1.right or 0)
	var_447_4.modifier:set(var_447_1.modifier or "Disabled")
	var_447_4.mode:set(var_447_1.mode or "Default")
	var_447_4.degree:set(var_447_1.degree or 0)
	var_447_4.randomize:set(var_447_1.randomize or 0)
	var_447_4.lc_min:set(var_447_1.lc_min or 0)
	var_447_4.lc_max:set(var_447_1.lc_max or 0)
	var_447_4.spin_seed:set(var_447_1.spin_seed or 10)
	var_447_4.custom_count:set(var_447_1.custom_count or 3)
	var_447_4.custom_way:set(var_447_1.custom_way or 3)

	for iter_447_0 = 1, 6 do
		var_447_4.custom[iter_447_0]:set(var_447_1.custom[iter_447_0] or 0)
	end

	var_447_1.delay = var_447_1.delay or {
		count = 1,
		activation = "Stable",
		mode = "Default",
		to = 1,
		enable = false,
		from = 1,
		hold = 1,
		randomize = 0,
		values = {
			1,
			1,
			1,
			1,
			1,
			1
		}
	}

	var_447_5.enable:set(var_447_1.delay.enable or false)
	var_447_5.activation:set(var_447_1.delay.activation or "Stable")
	var_447_5.mode:set(var_447_1.delay.mode or "Default")
	var_447_5.hold:set(var_447_1.delay.hold or 1)
	var_447_5.randomize:set(var_447_1.delay.randomize or 0)
	var_447_5.from:set(var_447_1.delay.from or 1)
	var_447_5.to:set(var_447_1.delay.to or 1)
	var_447_5.count:set(var_447_1.delay.count or 1)

	for iter_447_1 = 1, 6 do
		var_447_5.values[iter_447_1]:set(var_447_1.delay.values[iter_447_1] or 1)
	end

	var_447_1.desync = var_447_1.desync or {
		right = 0,
		left = 0,
		to = 0,
		from = 0,
		limit_mode = "Default",
		speed = 1,
		mode = "Off",
		delay = 0
	}

	var_447_6.mode:set(var_447_1.desync.mode or "Off")
	var_447_6.delay:set(var_447_1.desync.delay or 0)
	var_447_6.limit_mode:set(var_447_1.desync.limit_mode or "Default")
	var_447_6.left:set(var_447_1.desync.left or 0)
	var_447_6.right:set(var_447_1.desync.right or 0)
	var_447_6.from:set(var_447_1.desync.from or 0)
	var_447_6.to:set(var_447_1.desync.to or 0)
	var_447_6.speed:set(var_447_1.desync.speed or 1)

	var_447_1.extension = var_447_1.extension or {
		break_lc_disable_qp = false,
		break_lc = {}
	}

	var_447_7.mode:set(var_447_1.extension.break_lc or {})
	var_447_7.disable_qp:set(var_447_1.extension.break_lc_disable_qp or false)

	var_447_1.extension.tickbase = var_447_1.extension.tickbase or {
		mode = "Default",
		choke = 16,
		random = false,
		choke2 = 16
	}

	var_447_8.mode:set(var_447_1.extension.tickbase.mode or "Default")
	var_447_8.random:set(var_447_1.extension.tickbase.random or false)
	var_447_8.choke:set(var_447_1.extension.tickbase.choke or 16)
	var_447_8.choke2:set(var_447_1.extension.tickbase.choke2 or 16)

	var_447_1.defensive = var_447_1.defensive or {
		yaw_second = 0,
		modifier = "Disabled",
		yaw_first = 0,
		modifier_mode = "Randomize",
		modifier_offset = 0,
		pitch_custom = 0,
		pitch_second = 0,
		pitch_first = 0,
		modifier_min = 0,
		enable = false,
		modifier_randomize = 0,
		modifier_max = 0,
		pitch = "Disabled",
		yaw_custom = 0,
		yaw_speed = 1,
		yaw = "Disabled"
	}

	var_447_9.enable:set(var_447_1.defensive.enable or false)
	var_447_9.pitch:set(var_447_1.defensive.pitch or "Disabled")
	var_447_9.pitch_first:set(var_447_1.defensive.pitch_first or 0)
	var_447_9.pitch_second:set(var_447_1.defensive.pitch_second or 0)
	var_447_9.pitch_custom:set(var_447_1.defensive.pitch_custom or 0)
	var_447_9.yaw:set(var_447_1.defensive.yaw or "Disabled")
	var_447_9.yaw_first:set(var_447_1.defensive.yaw_first or 0)
	var_447_9.yaw_second:set(var_447_1.defensive.yaw_second or 0)
	var_447_9.yaw_speed:set(var_447_1.defensive.yaw_speed or 1)
	var_447_9.yaw_custom:set(var_447_1.defensive.yaw_custom or 0)
	var_447_9.modifier:set(var_447_1.defensive.modifier or "Disabled")
	var_447_9.modifier_mode:set(var_447_1.defensive.modifier_mode or "Randomize")
	var_447_9.modifier_offset:set(var_447_1.defensive.modifier_offset or 0)
	var_447_9.modifier_randomize:set(var_447_1.defensive.modifier_randomize or 0)
	var_447_9.modifier_min:set(var_447_1.defensive.modifier_min or 0)
	var_447_9.modifier_max:set(var_447_1.defensive.modifier_max or 0)
end

local function var_0_129()
	local var_448_0 = var_0_24.antiaim.left.aa.extension.options

	var_448_0.selection:set(var_0_120.antiaim.wrmp.selection or {})
	var_448_0.mode:set(var_0_120.antiaim.wrmp.mode or "Full")
	var_448_0.speed:set(var_0_120.antiaim.wrmp.speed or 4)
end

local function var_0_130()
	local var_449_0 = var_0_122()

	var_0_24.antiaim.right.send_t:visibility(var_449_0 == "ct")
	var_0_24.antiaim.right.send_ct:visibility(var_449_0 == "t")
end

var_0_130()

local var_0_131

local function var_0_132(arg_450_0)
	local var_450_0 = var_0_121()
	local var_450_1 = var_0_122()

	var_0_126(var_450_0, var_450_1)

	for iter_450_0, iter_450_1 in ipairs(var_0_17.cond) do
		var_0_119[iter_450_1] = var_0_119[iter_450_1] or {
			z1 = {
				t = var_0_118(),
				ct = var_0_118()
			}
		}
		var_0_119[iter_450_1].z1 = var_0_119[iter_450_1].z1 or {
			t = var_0_118(),
			ct = var_0_118()
		}
		var_0_119[iter_450_1].z1[var_450_1] = var_0_119[iter_450_1].z1[var_450_1] or var_0_118()
		var_0_119[iter_450_1].z1[arg_450_0] = var_0_125(var_0_119[iter_450_1].z1[var_450_1])
	end

	var_0_128(var_450_0, var_450_1)

	if var_0_131 then
		var_0_131()
	end
end

local function var_0_133()
	local var_451_0 = var_0_121()
	local var_451_1 = var_0_122()

	for iter_451_0, iter_451_1 in ipairs(var_0_17.cond) do
		var_0_119[iter_451_1] = var_0_119[iter_451_1] or {
			z1 = {
				t = var_0_118(),
				ct = var_0_118()
			}
		}
		var_0_119[iter_451_1].z1 = var_0_119[iter_451_1].z1 or {
			t = var_0_118(),
			ct = var_0_118()
		}
		var_0_119[iter_451_1].z1[var_451_1] = var_0_118()
	end

	var_0_128(var_451_0, var_451_1)

	if var_0_131 then
		var_0_131()
	end
end

var_0_24.antiaim.right.send_t:set_callback(function()
	var_0_132("t")
end)
var_0_24.antiaim.right.send_ct:set_callback(function()
	var_0_132("ct")
end)
var_0_24.antiaim.right.reset:set_callback(function()
	var_0_133()
end)

local function var_0_134()
	local var_455_0 = var_0_121()
	local var_455_1 = var_0_122()

	if var_455_0 ~= var_0_17.runtime.last_menu_state or var_455_1 ~= var_0_17.runtime.last_menu_team then
		var_0_126(var_0_17.runtime.last_menu_state or var_455_0, var_0_17.runtime.last_menu_team or var_455_1)
		var_0_128(var_455_0, var_455_1)

		var_0_17.runtime.last_menu_state = var_455_0
		var_0_17.runtime.last_menu_team = var_455_1
	end
end

var_0_17.runtime.side = 0
var_0_17.runtime.fixed_state = var_0_17.runtime.current
var_0_17.runtime.side = 0
var_0_17.runtime.switch_delay = 0
var_0_17.runtime.jitter_way = 1
var_0_17.runtime.jitter_timer = 0
var_0_17.runtime.spin_angle = 0
var_0_17.runtime.center_noise = 0
var_0_17.runtime.menu_state = 1
var_0_17.runtime.last_menu_state = 1
var_0_17.runtime.last_menu_team = "t"
var_0_17.runtime.way_spin = 1
var_0_17.runtime.lc_tick = 0
var_0_17.runtime.custom_way_step = 1
var_0_17.runtime.custom_way_tick = 0
var_0_17.runtime.delay_tick = 0
var_0_17.runtime.delay_slider = 1
var_0_17.runtime.desync_tick = 0
var_0_17.runtime.delay_hold = 0
var_0_17.runtime.round_ended = false
var_0_17.runtime.round_end_time = 0
var_0_17.runtime.tickbase_choke = 16
var_0_17.runtime.cached_yaw = 0
var_0_17.runtime.jitter_update = true
var_0_17.runtime.center_value = 0
var_0_17.runtime.random_value = 0
var_0_17.runtime.force_defensive = false
var_0_17.runtime.edge_angle = 0
var_0_17.runtime.is_edging = false
var_0_17.runtime.safe_head_trigger = false
var_0_17.runtime.defensive_spin = 0
var_0_17.runtime.defensive_tick = 0
var_0_17.runtime.defensive_last_cmd = -1
var_0_17.runtime.defensive_pitch_cache = 0
var_0_17.runtime.defensive_yaw_cache = 0
var_0_17.runtime.defensive_modifier_cache = 0
var_0_17.runtime.defensive_active_last = false
var_0_17.runtime.defensive_modifier_side = false
var_0_17.runtime.defensive_modifier_value = 0
var_0_17.runtime.defensive_modifier_tick = 0

local var_0_135 = {
	file = "whitestrike_configs.txt",
	last_save_time = 0,
	prefix = "{whitestrike:config}:",
	storage = {},
	menu_list = {},
	display_to_name = {},
	link_color = function(arg_456_0)
		local var_456_0, var_456_1 = pcall(function()
			return ui.get_style("Link Active")
		end)

		if var_456_0 and var_456_1 then
			return var_456_1
		end

		local var_456_2, var_456_3 = pcall(function()
			return ui.get_style()
		end)

		if var_456_2 and var_456_3 and var_456_3["Link Active"] then
			return var_456_3["Link Active"]
		end

		return color(160, 200, 255, 255)
	end,
	hex = function(arg_459_0, arg_459_1)
		local var_459_0, var_459_1 = pcall(function()
			return arg_459_1:to_hex()
		end)

		if var_459_0 and var_459_1 then
			return var_459_1
		end

		return "FFFFFFFF"
	end,
	log = function(arg_461_0, arg_461_1, arg_461_2)
		local var_461_0 = arg_461_0:link_color()
		local var_461_1 = arg_461_0:hex(var_461_0)

		pcall(function()
			print_raw("\a" .. var_461_1 .. "Whitestrike\aFFFFFFFF >> " .. tostring(arg_461_1))
		end)

		if arg_461_2 then
			pcall(function()
				cvar.play:call("ambient\\tones\\elev1")
			end)
		else
			pcall(function()
				cvar.play:call("buttons\\button10")
			end)
		end
	end,
	notify = function(arg_465_0, arg_465_1, arg_465_2)
		arg_465_0:log(arg_465_1, arg_465_2)
		pcall(function()
			common.add_notify("Whitestrike", tostring(arg_465_1))
		end)
	end,
	encode = function(arg_467_0, arg_467_1)
		return var_0_4.base64.encode(json.stringify(arg_467_1))
	end,
	decode = function(arg_468_0, arg_468_1)
		return json.parse(var_0_4.base64.decode(arg_468_1))
	end,
	read_file = function(arg_469_0)
		local var_469_0

		pcall(function()
			var_469_0 = files.read(arg_469_0.file)
		end)

		if not var_469_0 or var_469_0 == "" then
			return {}
		end

		local var_469_1, var_469_2 = pcall(function()
			return json.parse(var_469_0)
		end)

		if var_469_1 and type(var_469_2) == "table" then
			return var_469_2
		end

		return {}
	end,
	write_file = function(arg_472_0)
		pcall(function()
			files.write(arg_472_0.file, json.stringify(arg_472_0.storage or {}))
		end)
	end,
	valid_name = function(arg_474_0, arg_474_1)
		return type(arg_474_1) == "string" and arg_474_1:match("%w") ~= nil
	end,
	current_name = function(arg_475_0)
		local var_475_0

		pcall(function()
			var_475_0 = var_0_24.main.configs.name:get()
		end)

		if not var_475_0 or var_475_0 == "" then
			pcall(function()
				var_475_0 = var_0_24.main.configs.name()
			end)
		end

		return tostring(var_475_0 or "")
	end,
	clone = function(arg_478_0, arg_478_1)
		if type(arg_478_1) ~= "table" then
			return arg_478_1
		end

		local var_478_0 = {}

		for iter_478_0, iter_478_1 in pairs(arg_478_1) do
			var_478_0[iter_478_0] = arg_478_0:clone(iter_478_1)
		end

		return var_478_0
	end,
	safe_get = function(arg_479_0, arg_479_1, arg_479_2)
		if not arg_479_1 then
			return arg_479_2
		end

		local var_479_0, var_479_1 = pcall(function()
			return arg_479_1:get()
		end)

		if var_479_0 then
			if var_479_1 == nil then
				return arg_479_2
			end

			return var_479_1
		end

		local var_479_2, var_479_3 = pcall(function()
			return arg_479_1()
		end)

		if var_479_2 then
			if var_479_3 == nil then
				return arg_479_2
			end

			return var_479_3
		end

		return arg_479_2
	end,
	safe_set = function(arg_482_0, arg_482_1, arg_482_2)
		if not arg_482_1 then
			return false
		end

		if pcall(function()
			arg_482_1:set(arg_482_2)
		end) then
			return true
		end

		return pcall(function()
			arg_482_1(arg_482_2)
		end) == true
	end,
	save_pui = function(arg_485_0)
		return var_0_4.pui.setup({
			var_0_24.main,
			var_0_24.other.visual,
			var_0_24.other.misc,
			var_0_24.antiaim.fr_d,
			var_0_24.antiaim.help,
			var_0_24.antiaim.adder
		}, true):save()
	end,
	load_pui = function(arg_486_0, arg_486_1)
		var_0_4.pui.setup({
			var_0_24.main,
			var_0_24.other.visual,
			var_0_24.other.misc,
			var_0_24.antiaim.fr_d,
			var_0_24.antiaim.help,
			var_0_24.antiaim.adder
		}, true):load(arg_486_1)
	end,
	save_positions = function(arg_487_0)
		local var_487_0 = var_0_25._win_rt or {}
		local var_487_1 = var_0_25._ci_rt or {}
		local var_487_2 = var_0_25._pe_rt or {}

		return {
			windows = {
				keybinds = {
					x = var_487_0.kb_x or 45,
					y = var_487_0.kb_y or 285
				},
				watermark = {
					x = var_487_0.wm_x or 35,
					y = var_487_0.wm_y or 35
				},
				velocity = {
					x = var_487_0.vel_x or 35,
					y = var_487_0.vel_y or 75
				},
				spectators = {
					x = var_487_0.spec_x or 35,
					y = var_487_0.spec_y or 130
				}
			},
			damage_indicator = {
				x = var_487_1.dmg_x,
				y = var_487_1.dmg_y
			},
			aimbot_logs = {
				screen_x = var_487_2.screen_x or 12,
				screen_y = var_487_2.screen_y or 12,
				center_y = var_487_2.center_y
			}
		}
	end,
	load_positions = function(arg_488_0, arg_488_1)
		if type(arg_488_1) ~= "table" then
			return
		end

		var_0_25._win_rt = var_0_25._win_rt or {}
		var_0_25._ci_rt = var_0_25._ci_rt or {}
		var_0_25._pe_rt = var_0_25._pe_rt or {}

		local var_488_0 = arg_488_1.windows or {}

		if var_488_0.keybinds then
			var_0_25._win_rt.kb_x = tonumber(var_488_0.keybinds.x) or var_0_25._win_rt.kb_x or 45
			var_0_25._win_rt.kb_y = tonumber(var_488_0.keybinds.y) or var_0_25._win_rt.kb_y or 285
		end

		if var_488_0.watermark then
			var_0_25._win_rt.wm_x = tonumber(var_488_0.watermark.x) or var_0_25._win_rt.wm_x or 35
			var_0_25._win_rt.wm_y = tonumber(var_488_0.watermark.y) or var_0_25._win_rt.wm_y or 35
		end

		if var_488_0.velocity then
			var_0_25._win_rt.vel_x = tonumber(var_488_0.velocity.x) or var_0_25._win_rt.vel_x or 35
			var_0_25._win_rt.vel_y = tonumber(var_488_0.velocity.y) or var_0_25._win_rt.vel_y or 75
		end

		if var_488_0.spectators then
			var_0_25._win_rt.spec_x = tonumber(var_488_0.spectators.x) or var_0_25._win_rt.spec_x or 35
			var_0_25._win_rt.spec_y = tonumber(var_488_0.spectators.y) or var_0_25._win_rt.spec_y or 130
		end

		if arg_488_1.damage_indicator then
			var_0_25._ci_rt.dmg_x = tonumber(arg_488_1.damage_indicator.x) or var_0_25._ci_rt.dmg_x
			var_0_25._ci_rt.dmg_y = tonumber(arg_488_1.damage_indicator.y) or var_0_25._ci_rt.dmg_y
		end

		if arg_488_1.aimbot_logs then
			var_0_25._pe_rt.screen_x = tonumber(arg_488_1.aimbot_logs.screen_x) or var_0_25._pe_rt.screen_x or 12
			var_0_25._pe_rt.screen_y = tonumber(arg_488_1.aimbot_logs.screen_y) or var_0_25._pe_rt.screen_y or 12
			var_0_25._pe_rt.center_y = tonumber(arg_488_1.aimbot_logs.center_y) or var_0_25._pe_rt.center_y
		end
	end,
	save_antiaim = function(arg_489_0)
		var_0_126(var_0_121(), var_0_122())
		var_0_127()

		return {
			cfg = arg_489_0:clone(var_0_119),
			global_save = arg_489_0:clone(var_0_120),
			menu_state = var_0_121(),
			menu_team = var_0_122(),
			builder = var_0_28()
		}
	end,
	load_antiaim = function(arg_490_0, arg_490_1)
		if type(arg_490_1) ~= "table" then
			return
		end

		if type(arg_490_1.cfg) == "table" then
			var_0_119 = arg_490_1.cfg
		end

		if type(arg_490_1.global_save) == "table" then
			var_0_120 = arg_490_1.global_save
		end

		local var_490_0 = tonumber(arg_490_1.menu_state) or var_0_121()
		local var_490_1 = arg_490_1.menu_team == "ct" and "ct" or "t"

		pcall(function()
			var_0_24.antiaim.right.team:set(var_0_31(var_490_1 == "ct" and "Counter Terrorist" or "Terrorist"))
		end)
		pcall(function()
			var_0_24.antiaim.left.current:set(var_490_0)
		end)
		pcall(function()
			if arg_490_1.builder then
				var_0_24.antiaim.left.builder:set(var_0_30(arg_490_1.builder))
			end
		end)
		var_0_129()
		var_0_128(var_490_0, var_490_1)

		var_0_17.runtime.last_menu_state = var_490_0
		var_0_17.runtime.last_menu_team = var_490_1

		if var_0_131 then
			var_0_131()
		end

		var_0_130()
	end,
	pack = function(arg_494_0)
		return {
			build = "Whitestrike",
			version = 1,
			saved_at = common.get_date and common.get_date("%d/%m/%y - %H:%M:%S") or "",
			pui = arg_494_0:save_pui(),
			antiaim = arg_494_0:save_antiaim(),
			positions = arg_494_0:save_positions()
		}
	end,
	apply = function(arg_495_0, arg_495_1)
		if type(arg_495_1) ~= "table" then
			return false, "Invalid config data"
		end

		if arg_495_1.pui then
			arg_495_0:load_pui(arg_495_1.pui)
		end

		if arg_495_1.antiaim then
			arg_495_0:load_antiaim(arg_495_1.antiaim)
		end

		if arg_495_1.positions then
			arg_495_0:load_positions(arg_495_1.positions)
		end

		pcall(function()
			all_visibility()
		end)
		pcall(function()
			var_0_131()
		end)
		pcall(function()
			var_0_130()
		end)

		return true
	end,
	export_string = function(arg_499_0)
		local var_499_0, var_499_1 = pcall(function()
			return arg_499_0.prefix .. arg_499_0:encode(arg_499_0:pack())
		end)

		if var_499_0 and var_499_1 then
			return var_499_1
		end

		return nil
	end,
	import_string = function(arg_501_0, arg_501_1)
		if type(arg_501_1) ~= "string" or arg_501_1 == "" then
			return false, "Empty clipboard"
		end

		if not arg_501_1:find(arg_501_0.prefix, 1, true) then
			return false, "Invalid Whitestrike config"
		end

		local var_501_0 = arg_501_1:gsub(arg_501_0.prefix, "", 1)
		local var_501_1, var_501_2 = pcall(function()
			return arg_501_0:decode(var_501_0)
		end)

		if not var_501_1 or type(var_501_2) ~= "table" then
			return false, "Config parse error"
		end

		local var_501_3, var_501_4 = pcall(function()
			arg_501_0:apply(var_501_2)
		end)

		if not var_501_3 then
			return false, tostring(var_501_4)
		end

		return true
	end,
	refresh = function(arg_504_0)
		arg_504_0.menu_list = {}
		arg_504_0.display_to_name = {}

		for iter_504_0, iter_504_1 in pairs(arg_504_0.storage or {}) do
			local var_504_0 = iter_504_0

			if arg_504_0.active == iter_504_0 then
				var_504_0 = "\a" .. arg_504_0:hex(arg_504_0:link_color()) .. "» \aDEFAULT" .. iter_504_0 .. " \a" .. arg_504_0:hex(arg_504_0:link_color()) .. "~ Loaded"
			end

			table.insert(arg_504_0.menu_list, var_504_0)

			arg_504_0.display_to_name[var_504_0] = iter_504_0
		end

		table.sort(arg_504_0.menu_list, function(arg_505_0, arg_505_1)
			return tostring(arg_505_0) < tostring(arg_505_1)
		end)

		if #arg_504_0.menu_list == 0 then
			table.insert(arg_504_0.menu_list, "No saved configs")

			arg_504_0.display_to_name["No saved configs"] = nil
		end

		pcall(function()
			var_0_24.main.configs.list:update(arg_504_0.menu_list)
		end)
		arg_504_0:write_file()
	end,
	selected_name = function(arg_507_0)
		local var_507_0

		pcall(function()
			var_507_0 = var_0_24.main.configs.list:get()
		end)

		var_507_0 = tonumber(var_507_0) or 1

		local var_507_1 = arg_507_0.menu_list[var_507_0]
		local var_507_2 = var_507_1 and arg_507_0.display_to_name[var_507_1] or nil

		if var_507_2 then
			return var_507_2
		end

		local var_507_3 = arg_507_0:current_name()

		if arg_507_0:valid_name(var_507_3) then
			return var_507_3
		end

		return nil
	end,
	select_current = function(arg_509_0)
		local var_509_0 = arg_509_0:selected_name()

		if var_509_0 then
			arg_509_0:safe_set(var_0_24.main.configs.name, var_509_0)
		end
	end,
	create = function(arg_510_0)
		local var_510_0 = arg_510_0:current_name()

		if not arg_510_0:valid_name(var_510_0) then
			arg_510_0:notify("Invalid config name", false)

			return false
		end

		if arg_510_0.storage[var_510_0] then
			arg_510_0:notify("Config already exists", false)

			return false
		end

		local var_510_1 = arg_510_0:export_string()

		if not var_510_1 then
			arg_510_0:notify("Config create error", false)

			return false
		end

		arg_510_0.storage[var_510_0] = var_510_1
		arg_510_0.active = var_510_0

		arg_510_0:refresh()
		arg_510_0:notify("Config created", true)

		return true
	end,
	save = function(arg_511_0)
		local var_511_0 = arg_511_0:current_name()

		if not arg_511_0:valid_name(var_511_0) then
			arg_511_0:notify("Invalid config name", false)

			return false
		end

		local var_511_1 = arg_511_0:export_string()

		if not var_511_1 then
			arg_511_0:notify("Config save error", false)

			return false
		end

		arg_511_0.storage[var_511_0] = var_511_1
		arg_511_0.active = var_511_0

		arg_511_0:refresh()
		arg_511_0:notify("Config saved", true)

		return true
	end,
	load = function(arg_512_0)
		local var_512_0 = arg_512_0:current_name()

		if not arg_512_0.storage[var_512_0] then
			var_512_0 = arg_512_0:selected_name()
		end

		if not var_512_0 or not arg_512_0.storage[var_512_0] then
			arg_512_0:notify("Invalid config name", false)

			return false
		end

		local var_512_1, var_512_2 = arg_512_0:import_string(arg_512_0.storage[var_512_0])

		if not var_512_1 then
			arg_512_0:notify("Config load error: " .. tostring(var_512_2), false)

			return false
		end

		arg_512_0.active = var_512_0

		arg_512_0:refresh()
		arg_512_0:notify("Config loaded", true)

		return true
	end,
	delete = function(arg_513_0)
		local var_513_0 = arg_513_0:current_name()

		if not arg_513_0.storage[var_513_0] then
			var_513_0 = arg_513_0:selected_name()
		end

		if not var_513_0 or not arg_513_0.storage[var_513_0] then
			arg_513_0:notify("Invalid config name", false)

			return false
		end

		arg_513_0.storage[var_513_0] = nil

		if arg_513_0.active == var_513_0 then
			arg_513_0.active = nil
		end

		arg_513_0:refresh()
		arg_513_0:notify("Config removed", true)

		return true
	end,
	export_clipboard = function(arg_514_0)
		local var_514_0 = arg_514_0:export_string()

		if not var_514_0 then
			arg_514_0:notify("Config export error", false)

			return false
		end

		var_0_4.clipboard.set(var_514_0)
		arg_514_0:notify("Config exported", true)

		return true
	end,
	import_clipboard = function(arg_515_0)
		local var_515_0 = var_0_4.clipboard.get()

		if not var_515_0 or var_515_0 == "" then
			arg_515_0:notify("Clipboard is empty", false)

			return false
		end

		local var_515_1, var_515_2 = arg_515_0:import_string(var_515_0)

		if not var_515_1 then
			arg_515_0:notify("Config import error: " .. tostring(var_515_2), false)

			return false
		end

		arg_515_0.active = nil

		arg_515_0:refresh()
		arg_515_0:notify("Config imported", true)

		return true
	end
}

function var_0_135.initialize(arg_516_0)
	arg_516_0.storage = arg_516_0:read_file() or {}

	arg_516_0:refresh()
	pcall(function()
		var_0_24.main.configs.list:set_callback(function()
			var_0_135:select_current()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.create:set_callback(function()
			var_0_135:create()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.save:set_callback(function()
			var_0_135:save()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.load:set_callback(function()
			var_0_135:load()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.remove:set_callback(function()
			var_0_135:delete()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.export:set_callback(function()
			var_0_135:export_clipboard()
		end)
	end)
	pcall(function()
		var_0_24.main.configs.import:set_callback(function()
			var_0_135:import_clipboard()
		end)
	end)
end

var_0_135:initialize()

local function var_0_136(arg_531_0, arg_531_1)
	arg_531_0 = math.floor(arg_531_0 or 0)
	arg_531_1 = math.floor(arg_531_1 or 0)

	if arg_531_1 < arg_531_0 then
		arg_531_0, arg_531_1 = arg_531_1, arg_531_0
	end

	return utils.random_int(arg_531_0, arg_531_1)
end

local function var_0_137()
	var_0_9.antiaim.aa_modifier:override("Disabled")
	var_0_9.antiaim.aa_modifier_offset:override(0)
end

local function var_0_138(arg_533_0)
	local var_533_0 = math.max(tonumber(arg_533_0.hold) or 1, 1)
	local var_533_1 = math.max(0, math.min(100, tonumber(arg_533_0.randomize) or 0))

	if var_533_1 <= 0 then
		return var_533_0
	end

	local var_533_2 = math.max(1, math.floor(var_533_0 * (1 - var_533_1 / 100)))
	local var_533_3 = math.max(var_533_2, math.floor(var_533_0 * (1 + var_533_1 / 100)))

	return var_0_136(var_533_2, var_533_3)
end

local function var_0_139(arg_534_0)
	local var_534_0 = arg_534_0.delay or {}

	if globals.choked_commands ~= 0 then
		return false
	end

	if var_534_0.enable ~= true then
		var_0_17.runtime.delay_hold = 0
		var_0_17.runtime.side = 1 - var_0_17.runtime.side

		return true
	end

	if var_534_0.activation == "Aggressive" and globals.choked_commands ~= math.random(0, 1) then
		return false
	end

	var_0_17.runtime.delay_tick = var_0_17.runtime.delay_tick + 1

	if var_534_0.mode == "Random" then
		local var_534_1 = var_534_0.from or 1
		local var_534_2 = var_534_0.to or 1

		if var_534_2 < var_534_1 then
			var_534_1, var_534_2 = var_534_2, var_534_1
		end

		if var_0_17.runtime.delay_tick >= var_0_136(var_534_1, var_534_2) then
			var_0_17.runtime.delay_tick = 0
			var_0_17.runtime.side = 1 - var_0_17.runtime.side

			return true
		end
	elseif var_534_0.mode == "Custom" then
		local var_534_3 = math.max(1, math.min(6, var_534_0.count or 1))

		if var_534_3 < var_0_17.runtime.delay_slider then
			var_0_17.runtime.delay_slider = 1
		end

		local var_534_4 = var_534_0.values and var_534_0.values[var_0_17.runtime.delay_slider] or 1

		if math.max(tonumber(var_534_4) or 1, 1) <= var_0_17.runtime.delay_tick then
			var_0_17.runtime.delay_tick = 0
			var_0_17.runtime.side = 1 - var_0_17.runtime.side
			var_0_17.runtime.delay_slider = var_0_17.runtime.delay_slider + 1

			if var_534_3 < var_0_17.runtime.delay_slider then
				var_0_17.runtime.delay_slider = 1
			end

			return true
		end
	else
		if var_0_17.runtime.delay_hold <= 0 then
			var_0_17.runtime.delay_hold = var_0_138(var_534_0)
		end

		if math.max(var_0_17.runtime.delay_hold, 1) <= var_0_17.runtime.delay_tick then
			var_0_17.runtime.delay_tick = 0
			var_0_17.runtime.delay_hold = var_0_138(var_534_0)
			var_0_17.runtime.side = 1 - var_0_17.runtime.side

			return true
		end
	end

	return false
end

local function var_0_140(arg_535_0, arg_535_1)
	if type(arg_535_0) ~= "table" then
		return arg_535_0 == arg_535_1
	end

	for iter_535_0, iter_535_1 in pairs(arg_535_0) do
		if iter_535_1 == arg_535_1 then
			return true
		end
	end

	return false
end

local function var_0_141(arg_536_0)
	local var_536_0 = entity.get_local_player()
	local var_536_1 = var_536_0:get_eye_position()
	local var_536_2 = {}
	local var_536_3 = render.camera_angles()
	local var_536_4 = {}
	local var_536_5

	if not var_536_0 or not var_536_0:is_alive() then
		var_0_17.runtime.is_edging = false

		return
	end

	var_0_17.runtime.is_edging = false

	if arg_536_0 and arg_536_0.send_packet then
		var_536_1 = var_536_0:get_eye_position()
	end

	for iter_536_0 = 18, 360, 18 do
		iter_536_0 = math.normalize_yaw(iter_536_0)

		local var_536_6 = var_536_1 + vector():angles(0, iter_536_0) * 198
		local var_536_7 = utils.trace_line(var_536_1, var_536_6, var_536_0, 1174421507)

		table.insert(var_536_4, var_536_1:dist(var_536_7.end_pos))

		local var_536_8 = var_536_7.fraction
		local var_536_9 = var_536_7.entity

		if var_536_9 and var_536_9:get_classname() == "CWorld" and var_536_8 < 0.3 then
			var_536_2[#var_536_2 + 1] = {
				vecTraceEnd = var_536_6,
				flYaw = iter_536_0
			}
		end
	end

	table.sort(var_536_4)

	if not var_536_4[1] or var_536_4[1] > 30 then
		return
	end

	table.sort(var_536_2, function(arg_537_0, arg_537_1)
		return arg_537_0.flYaw < arg_537_1.flYaw
	end)

	if #var_536_2 > 0 then
		table.remove(var_536_2, #var_536_2)
	end

	if #var_536_2 >= 3 then
		var_536_5 = (var_536_1 - var_536_2[1].vecTraceEnd:lerp(var_536_2[#var_536_2].vecTraceEnd, 0.5)):angles()
	end

	if var_536_5 then
		local var_536_10 = var_536_3.y
		local var_536_11 = var_536_5.y
		local var_536_12 = math.normalize_yaw(var_536_11 - var_536_10)

		if math.abs(var_536_12) < 90 then
			var_536_12 = 0
			var_536_10 = math.normalize_yaw(var_536_11 + 180)
		end

		local var_536_13 = -var_536_10
		local var_536_14 = math.normalize_yaw(var_536_13 + var_536_11 + var_536_12 + 180)

		var_0_17.runtime.edge_angle = var_536_14
		var_0_17.runtime.is_edging = true
	end
end

local function var_0_142()
	local var_538_0 = var_0_24.antiaim.adder
	local var_538_1 = entity.get_local_player()

	if not var_538_1 or not var_538_1:is_alive() then
		var_0_17.runtime.safe_head_trigger = false

		return
	end

	if not var_538_0.safe_head:get() then
		var_0_17.runtime.safe_head_trigger = false

		return
	end

	local var_538_2 = var_538_1:get_player_weapon()

	if not var_538_2 then
		var_0_17.runtime.safe_head_trigger = false

		return
	end

	local var_538_3 = var_538_2:get_weapon_info()
	local var_538_4 = var_538_2:get_classname()

	if not var_538_3 or not var_538_4 then
		var_0_17.runtime.safe_head_trigger = false

		return
	end

	local var_538_5 = var_538_4 == "CWeaponTaser"
	local var_538_6 = var_538_4 == "CKnife"
	local var_538_7 = var_0_17.runtime.fixed_state or var_0_17.runtime.current
	local var_538_8 = var_538_1:get_origin()
	local var_538_9 = entity.get_threat and entity.get_threat() or nil
	local var_538_10 = var_538_9 ~= nil and var_538_9:get_origin() or var_538_8

	if var_0_140(var_538_0.safe_head.triggers:get() or {}, "Knife") and var_538_6 and var_538_7 == 5 then
		var_0_17.runtime.safe_head_trigger = true
	elseif var_0_140(var_538_0.safe_head.triggers:get() or {}, "Taser") and var_538_5 and var_538_7 == 5 then
		var_0_17.runtime.safe_head_trigger = true
	elseif var_0_140(var_538_0.safe_head.triggers:get() or {}, "Above Enemy") and var_538_8.z - var_538_10.z > var_538_0.safe_head.height_difference:get() and (var_538_7 == 5 or var_538_7 == 6 or var_538_7 == 7 or var_538_7 == 2) then
		var_0_17.runtime.safe_head_trigger = true
	else
		var_0_17.runtime.safe_head_trigger = false
	end
end

local function var_0_143()
	if not var_0_24.antiaim.adder.safe_head:get() then
		return
	end

	if not var_0_17.runtime.safe_head_trigger then
		return
	end

	var_0_9.antiaim.aa_yaw_offset:override(0)
	var_0_9.antiaim.aa_hidden:override(false)
	var_0_9.antiaim.aa_modifier:override("Disabled")
	var_0_9.antiaim.aa_modifier_offset:override(0)
	var_0_9.antiaim.aa_bodyyaw:override(true)
	var_0_9.antiaim.body_left:override(0)
	var_0_9.antiaim.body_right:override(0)
	var_0_9.antiaim.body_options:override("")

	if rage and rage.antiaim and rage.antiaim.inverter then
		rage.antiaim:inverter(false)
	end
end

local function var_0_144()
	local var_540_0 = var_0_24.antiaim.adder
	local var_540_1 = var_0_24.antiaim.help.manual_yaw:get()

	if not var_540_0.edge_yaw:get() then
		return
	end

	if not var_0_17.runtime.is_edging then
		return
	end

	if var_540_1 ~= "Disabled" and var_540_0.edge_yaw.ignore_manuals:get() then
		return
	end

	var_0_9.antiaim.aa_yaw_offset:override(var_0_17.runtime.edge_angle or 0)
	var_0_9.antiaim.aa_modifier:override("Disabled")
	var_0_9.antiaim.aa_modifier_offset:override(0)
	var_0_9.antiaim.aa_hidden:override(false)
end

local function var_0_145()
	var_0_9.antiaim.aa_backstab:override(var_0_24.antiaim.adder.avoid_backstab:get())
end

local function var_0_146()
	local var_542_0 = var_0_17.cond[var_0_17.runtime.fixed_state or var_0_17.runtime.current]
	local var_542_1 = var_0_24.antiaim.fr_d.force_defensive
	local var_542_2 = var_542_1.mode:get()
	local var_542_3 = var_542_1.conditions:get() or {}

	if var_542_2 == "Always" then
		return true
	end

	if var_542_2 == "On Double Tap" then
		return var_0_9.antiaim.dt:get()
	end

	if var_542_2 == "On Peek" then
		return var_0_9.rage.quickpeek and var_0_9.rage.quickpeek:get()
	end

	if var_542_2 == "On Conditions" then
		return var_0_140(var_542_3, var_542_0)
	end

	return false
end

WS_FORCE_DEFENSIVE = {
	hs_active = false,
	dt_active = false
}

function WS_FORCE_DEFENSIVE.has(arg_543_0, arg_543_1, arg_543_2)
	if type(arg_543_1) ~= "table" then
		return arg_543_1 == arg_543_2
	end

	for iter_543_0, iter_543_1 in pairs(arg_543_1) do
		if iter_543_1 == arg_543_2 then
			return true
		end
	end

	return false
end

function WS_FORCE_DEFENSIVE.mode(arg_544_0)
	local var_544_0 = var_0_24.antiaim.fr_d.force_defensive

	if not var_544_0 or not var_544_0.enable or not var_544_0.enable:get() then
		return nil
	end

	return var_544_0.mode and var_544_0.mode:get() or nil
end

function WS_FORCE_DEFENSIVE.state(arg_545_0)
	return var_0_17.cond[var_0_17.runtime.fixed_state or var_0_17.runtime.current] or "Shared"
end

function WS_FORCE_DEFENSIVE.run(arg_546_0)
	local var_546_0 = var_0_24.antiaim.fr_d.force_defensive

	if not var_546_0 or not var_546_0.enable or not var_546_0.enable:get() then
		arg_546_0:reset()

		return
	end

	local var_546_1 = var_546_0.mode:get()
	local var_546_2 = arg_546_0:state()
	local var_546_3 = var_546_0.conditions and var_546_0.conditions:get() or {}

	if var_546_1 == "Always" then
		if var_0_9.antiaim.hs_options then
			pcall(function()
				var_0_9.antiaim.hs_options:override("Break LC")
			end)
		end

		if var_0_9.antiaim.dt_lag then
			pcall(function()
				var_0_9.antiaim.dt_lag:override("Always On")
			end)
		end

		arg_546_0.hs_active = true
		arg_546_0.dt_active = true

		return
	end

	if var_546_1 == "On Double Tap" then
		if var_0_9.antiaim.hs_options then
			pcall(function()
				var_0_9.antiaim.hs_options:override()
			end)
		end

		if var_0_9.antiaim.dt_lag then
			pcall(function()
				var_0_9.antiaim.dt_lag:override("Always On")
			end)
		end

		arg_546_0.hs_active = false
		arg_546_0.dt_active = true

		return
	end

	if var_546_1 == "On Peek" then
		if var_0_9.antiaim.hs_options then
			pcall(function()
				var_0_9.antiaim.hs_options:override()
			end)
		end

		if var_0_9.antiaim.dt_lag then
			pcall(function()
				var_0_9.antiaim.dt_lag:override("On Peek")
			end)
		end

		arg_546_0.hs_active = false
		arg_546_0.dt_active = true

		return
	end

	if var_546_1 == "On Conditions" then
		if var_0_9.antiaim.hs_options then
			pcall(function()
				var_0_9.antiaim.hs_options:override()
			end)
		end

		if var_0_9.antiaim.dt_lag then
			if arg_546_0:has(var_546_3, var_546_2) then
				pcall(function()
					var_0_9.antiaim.dt_lag:override("Always On")
				end)
			else
				pcall(function()
					var_0_9.antiaim.dt_lag:override("On Peek")
				end)
			end
		end

		arg_546_0.hs_active = false
		arg_546_0.dt_active = true

		return
	end

	arg_546_0:reset()
end

function WS_FORCE_DEFENSIVE.reset(arg_556_0)
	if arg_556_0.hs_active and var_0_9.antiaim.hs_options then
		pcall(function()
			var_0_9.antiaim.hs_options:override()
		end)
	end

	if arg_556_0.dt_active and var_0_9.antiaim.dt_lag then
		pcall(function()
			var_0_9.antiaim.dt_lag:override()
		end)
	end

	arg_556_0.hs_active = false
	arg_556_0.dt_active = false
end

WS_FREESTANDING = {
	active = false
}

function WS_FREESTANDING.has(arg_559_0, arg_559_1, arg_559_2)
	if type(arg_559_1) ~= "table" then
		return arg_559_1 == arg_559_2
	end

	for iter_559_0, iter_559_1 in pairs(arg_559_1) do
		if iter_559_1 == arg_559_2 then
			return true
		end
	end

	return false
end

function WS_FREESTANDING.state(arg_560_0)
	local var_560_0 = entity.get_local_player()

	if not var_560_0 or not var_560_0:is_alive() then
		return "Shared"
	end

	local var_560_1 = 0
	local var_560_2 = 0

	pcall(function()
		var_560_1 = var_560_0.m_vecVelocity.x or 0
		var_560_2 = var_560_0.m_vecVelocity.y or 0
	end)

	local var_560_3 = math.sqrt(var_560_1 * var_560_1 + var_560_2 * var_560_2)
	local var_560_4 = 0

	pcall(function()
		var_560_4 = var_560_0.m_flDuckAmount or 0
	end)

	local var_560_5 = 0

	pcall(function()
		var_560_5 = var_560_0.m_fFlags or 0
	end)

	local var_560_6 = bit.band(var_560_5, 1) == 1
	local var_560_7 = false

	pcall(function()
		var_560_7 = var_0_9.antiaim.aa_slowwalk and var_0_9.antiaim.aa_slowwalk:get()
	end)

	local var_560_8 = false

	pcall(function()
		var_560_8 = var_0_24.antiaim.help.manual_yaw:get() ~= "Disabled"
	end)

	if var_560_8 then
		return "Manual Yaw"
	end

	if not var_560_6 then
		if var_560_4 > 0.7 then
			return "Air Crouching"
		end

		return "Air"
	end

	if var_560_4 > 0.7 then
		if var_560_3 > 5 then
			return "Crouching Moving"
		end

		return "Crouching"
	end

	if var_560_7 then
		return "Slow Walking"
	end

	if var_560_3 > 5 then
		return "Moving"
	end

	return "Standing"
end

function WS_FREESTANDING.enabled(arg_566_0)
	local var_566_0 = var_0_24.antiaim.help

	if not var_566_0 or not var_566_0.freestanding or not var_566_0.freestanding:get() then
		return false
	end

	local var_566_1 = var_566_0.freestanding.conditions and var_566_0.freestanding.conditions:get() or {}

	if #var_566_1 <= 0 then
		return true
	end

	return not arg_566_0:has(var_566_1, arg_566_0:state())
end

function WS_FREESTANDING.run(arg_567_0)
	local var_567_0 = var_0_24.antiaim.help

	if not var_567_0 or not var_567_0.freestanding then
		return false
	end

	local var_567_1 = arg_567_0:enabled()

	var_0_9.antiaim.freestand:override(var_567_1)
	var_0_9.antiaim.freestand_disable_yaw:override(var_567_1 and var_567_0.freestanding.disable_yaw_modifiers:get() or false)
	var_0_9.antiaim.freestand_body:override(var_567_1 and var_567_0.freestanding.body_freestanding:get() or false)

	arg_567_0.active = var_567_1

	return var_567_1
end

function WS_FREESTANDING.reset(arg_568_0)
	if var_0_9.antiaim.freestand then
		pcall(function()
			var_0_9.antiaim.freestand:override(false)
		end)
	end

	if var_0_9.antiaim.freestand_disable_yaw then
		pcall(function()
			var_0_9.antiaim.freestand_disable_yaw:override(false)
		end)
	end

	if var_0_9.antiaim.freestand_body then
		pcall(function()
			var_0_9.antiaim.freestand_body:override(false)
		end)
	end

	arg_568_0.active = false
end

local function var_0_147(arg_572_0)
	local var_572_0 = arg_572_0 and arg_572_0.extension or {}
	local var_572_1 = var_572_0.break_lc or {}
	local var_572_2 = entity.get_local_player()

	if not var_572_2 then
		return
	end

	local var_572_3 = var_572_2:get_player_weapon()

	if not var_572_3 then
		return
	end

	if var_0_9.antiaim.fakedick:get() then
		return
	end

	if not var_0_9.antiaim.dt:get() then
		return
	end

	if var_572_0.break_lc_disable_qp and var_0_9.rage.quickpeek and var_0_9.rage.quickpeek:get() then
		return
	end

	local var_572_4 = false

	if var_0_140(var_572_1, "Weapon switch") and var_572_2.m_flNextAttack > globals.curtime then
		var_572_4 = true
	end

	local var_572_5 = false

	if var_572_3.get_weapon_reload then
		local var_572_6, var_572_7 = pcall(function()
			return var_572_3:get_weapon_reload()
		end)

		var_572_5 = var_572_6 and var_572_7 ~= -1
	end

	if var_0_140(var_572_1, "Weapon reload") and var_572_5 then
		var_572_4 = true
	end

	if var_0_140(var_572_1, "Always") then
		var_572_4 = true
	end

	if var_572_4 then
		var_0_9.antiaim.dt_lag:override("Always On")
	end
end

local function var_0_148(arg_574_0)
	local var_574_0 = arg_574_0.desync or {}
	local var_574_1 = var_574_0.limit_mode or "Default"

	if var_574_1 == "From / To" then
		local var_574_2 = var_574_0.from or 0
		local var_574_3 = var_574_0.to or 0

		if var_574_3 < var_574_2 then
			var_574_2, var_574_3 = var_574_3, var_574_2
		end

		local var_574_4 = math.max(var_574_0.speed or 1, 1)

		return math.min(60, var_574_2 + globals.tickcount * var_574_4 % math.max(var_574_3 - var_574_2 + 1, 1))
	elseif var_574_1 == "Random" then
		return var_0_136(var_574_0.from or 0, var_574_0.to or 0)
	end

	return var_0_17.runtime.side == 0 and (var_574_0.left or 32) or var_574_0.right or 32
end

local function var_0_149(arg_575_0)
	local var_575_0 = arg_575_0.desync or {}
	local var_575_1 = var_575_0.mode or "Off"
	local var_575_2 = var_0_148(arg_575_0)

	var_0_9.antiaim.aa_bodyyaw:override(var_575_1 ~= "Off")

	if var_575_1 == "Off" then
		var_0_9.antiaim.aa_bodyyaw:override(false)
		var_0_9.antiaim.body_left:override(var_575_2)
		var_0_9.antiaim.body_right:override(var_575_2)

		return
	elseif var_575_1 == "Default" then
		var_0_9.antiaim.aa_bodyyaw:override(true)
		var_0_9.antiaim.body_left:override(var_575_0.left)
		var_0_9.antiaim.body_right:override(var_575_0.right)

		return
	elseif var_575_1 == "Jitter" then
		var_0_9.antiaim.aa_bodyyaw:override(true)
		var_0_9.antiaim.body_left:override(var_575_2)
		var_0_9.antiaim.body_right:override(var_575_2)

		if rage and rage.antiaim and rage.antiaim.inverter then
			rage.antiaim:inverter(var_0_17.runtime.side == 0)
		end
	elseif var_575_1 == "Random" then
		var_0_9.antiaim.aa_bodyyaw:override(true)
		var_0_9.antiaim.body_left:override(var_575_2)
		var_0_9.antiaim.body_right:override(var_575_2)

		if rage and rage.antiaim and rage.antiaim.inverter then
			rage.antiaim:inverter(globals.tickcount % math.random(3, 7) == 0)
		end
	elseif var_575_1 == "Delay" then
		var_0_9.antiaim.aa_bodyyaw:override(var_0_17.runtime.desync_tick % math.max(var_575_0.delay or 1, 1) ~= 1)
		var_0_9.antiaim.body_left:override(var_575_2)
		var_0_9.antiaim.body_right:override(var_575_2)

		if rage and rage.antiaim and rage.antiaim.inverter then
			rage.antiaim:inverter(var_0_17.runtime.side == 0)
		end
	elseif var_575_1 == "Whitestrike" then
		local var_575_3 = var_0_17.runtime.side == 0

		if globals.tickcount % math.random(6, 8) == 0 then
			var_575_3 = not var_575_3
		end

		var_0_9.antiaim.aa_bodyyaw:override(true)
		var_0_9.antiaim.body_left:override(var_575_2)
		var_0_9.antiaim.body_right:override(var_575_2)

		if rage and rage.antiaim and rage.antiaim.inverter then
			rage.antiaim:inverter(var_575_3)
		end
	end

	if globals.choked_commands == 0 then
		var_0_17.runtime.desync_tick = var_0_17.runtime.desync_tick + 1
	end
end

local function var_0_150(arg_576_0, arg_576_1)
	local var_576_0 = arg_576_0.modifier or "Disabled"
	local var_576_1 = arg_576_0.mode or "Default"
	local var_576_2 = arg_576_0.degree or 0
	local var_576_3 = arg_576_0.randomize or 0
	local var_576_4 = arg_576_0.spin_seed or 10
	local var_576_5 = tonumber(arg_576_1) or 0
	local var_576_6 = var_0_17.runtime.jitter_update == true

	if var_576_0 == "Disabled" then
		var_0_137()

		return var_576_5
	end

	if var_576_0 == "3-Way" then
		var_0_9.antiaim.aa_modifier:override("3-Way")
		var_0_9.antiaim.aa_modifier_offset:override(var_576_2)

		return var_576_5
	end

	if var_576_0 == "5-Way" then
		var_0_9.antiaim.aa_modifier:override("5-Way")
		var_0_9.antiaim.aa_modifier_offset:override(var_576_2)

		return var_576_5
	end

	if var_576_0 == "Custom Way" then
		var_0_137()

		local var_576_7 = math.max(1, math.min(5, arg_576_0.custom_way or 3))
		local var_576_8 = math.abs(var_576_2 or 0)

		if var_576_6 and globals.choked_commands == 0 then
			var_0_17.runtime.custom_way_tick = var_0_17.runtime.custom_way_tick + 1

			if var_0_17.runtime.custom_way_tick >= 1 then
				var_0_17.runtime.custom_way_tick = 0
				var_0_17.runtime.custom_way_step = var_0_17.runtime.custom_way_step + 1

				if var_576_7 < var_0_17.runtime.custom_way_step then
					var_0_17.runtime.custom_way_step = 1
				end
			end
		end

		local var_576_9 = 0

		if var_576_7 == 1 then
			var_576_9 = var_576_8
		else
			var_576_9 = -var_576_8 + (var_0_17.runtime.custom_way_step - 1) * (var_576_8 * 2 / (var_576_7 - 1))
		end

		var_576_5 = var_576_5 + var_576_9

		return var_576_5
	end

	if var_576_0 == "LC" then
		local var_576_10 = arg_576_0.lc_min or 0
		local var_576_11 = arg_576_0.lc_max or 0

		if var_576_11 < var_576_10 then
			var_576_10, var_576_11 = var_576_11, var_576_10
		end

		if var_576_6 and globals.choked_commands == 0 then
			if globals.tickcount % math.random(3, 4) == 0 then
				if math.random(0, 6) == 0 then
					var_0_9.antiaim.aa_modifier:override("5-Way")
				else
					var_0_9.antiaim.aa_modifier:override("Random")
				end
			else
				var_0_9.antiaim.aa_modifier:override("3-Way")
			end

			var_0_9.antiaim.aa_modifier_offset:override(var_0_136(var_576_10, var_576_11))
		end

		return var_576_5
	end

	if var_576_1 == "Custom" then
		var_0_137()

		local var_576_12 = math.max(1, math.min(6, arg_576_0.custom_count or 3))

		if var_576_12 < var_0_17.runtime.jitter_way then
			var_0_17.runtime.jitter_way = 1
		end

		local var_576_13 = arg_576_0.custom[var_0_17.runtime.jitter_way] or 0

		if var_576_6 and globals.choked_commands == 0 then
			var_0_17.runtime.jitter_timer = var_0_17.runtime.jitter_timer + 1

			if math.max(math.abs(var_576_13), 1) <= var_0_17.runtime.jitter_timer then
				var_0_17.runtime.jitter_timer = 0
				var_0_17.runtime.jitter_way = var_0_17.runtime.jitter_way + 1

				if var_576_12 < var_0_17.runtime.jitter_way then
					var_0_17.runtime.jitter_way = 1
				end
			end
		end

		local var_576_14 = arg_576_0.custom[var_0_17.runtime.jitter_way] or 0

		if var_576_0 == "Center" then
			var_576_5 = var_576_5 + (var_0_17.runtime.side == 1 and var_576_14 / 2 or -var_576_14 / 2)
		elseif var_576_0 == "Offset" then
			if var_0_17.runtime.side == 1 then
				var_576_5 = var_576_5 + var_576_14
			end
		elseif var_576_0 == "Random" then
			var_576_5 = var_576_5 + var_0_136(-math.abs(var_576_14), math.abs(var_576_14))
		elseif var_576_0 == "Spin" then
			var_0_17.runtime.spin_angle = (var_0_17.runtime.spin_angle + math.max(math.abs(var_576_14), 1)) % 360
			var_576_5 = var_576_5 + var_0_17.runtime.spin_angle
		end

		return var_576_5
	end

	if var_576_0 == "Center" then
		var_0_137()

		local var_576_15 = var_576_2

		if var_576_3 > 0 then
			if var_576_6 then
				var_0_17.runtime.center_value = var_0_136(var_576_2 - var_576_3, var_576_2 + var_576_3)
			end

			var_576_15 = var_0_17.runtime.center_value or var_576_2
		end

		var_576_5 = var_576_5 + (var_0_17.runtime.side == 1 and var_576_15 / 2 or -var_576_15 / 2)
	elseif var_576_0 == "Offset" then
		var_0_137()

		if var_0_17.runtime.side == 1 then
			var_576_5 = var_576_5 + var_576_2
		end
	elseif var_576_0 == "Random" then
		var_0_137()

		if var_576_6 then
			var_0_17.runtime.random_value = var_0_136(-math.abs(var_576_2), math.abs(var_576_2))
		end

		var_576_5 = var_576_5 + (var_0_17.runtime.random_value or 0)
	elseif var_576_0 == "Spin" then
		var_0_137()

		if var_576_6 then
			var_0_17.runtime.spin_angle = (var_0_17.runtime.spin_angle + var_576_4) % 360
		end

		var_576_5 = var_576_5 + var_0_17.runtime.spin_angle
	end

	return var_576_5
end

local function var_0_151(arg_577_0)
	local var_577_0 = math.max(1, math.min(22, tonumber(arg_577_0.choke) or 16))
	local var_577_1 = math.max(1, math.min(22, tonumber(arg_577_0.choke2) or 16))

	if arg_577_0.random == true then
		return var_0_136(var_577_0, var_577_1)
	end

	return var_577_0
end

local function var_0_152(arg_578_0)
	local var_578_0 = (arg_578_0.extension or {}).tickbase or {}

	if var_578_0.mode ~= "Custom" then
		var_0_9.antiaim.dt_lag:override()

		return
	end

	local var_578_1 = var_0_151(var_578_0)

	var_0_17.runtime.tickbase_choke = var_578_1

	if var_578_1 <= globals.choked_commands then
		var_0_9.antiaim.dt_lag:override("always on")
	else
		var_0_9.antiaim.dt_lag:override("disabled")
	end
end

local function var_0_153()
	local var_579_0 = entity.get_game_rules()

	if not var_579_0 then
		return false
	end

	local var_579_1 = var_579_0.m_bWarmupPeriod

	if var_579_1 == true then
		return true
	end

	if var_579_1 == false or var_579_1 == nil then
		return false
	end

	local var_579_2 = tonumber(var_579_1)

	if var_579_2 then
		return var_579_2 == 1
	end

	local var_579_3 = tostring(var_579_1):lower()

	return var_579_3:find("true", 1, true) ~= nil or var_579_3:find("1", 1, true) ~= nil
end

local function var_0_154()
	local var_580_0 = var_0_120.antiaim.wrmp or {}
	local var_580_1 = var_580_0.selection or {}
	local var_580_2 = var_580_0.mode or "Full"
	local var_580_3 = var_580_0.speed or 4
	local var_580_4 = var_0_153()
	local var_580_5 = var_0_17.runtime.round_ended == true and globals.curtime <= var_0_17.runtime.round_end_time and not var_580_4

	if (not var_0_140(var_580_1, "Warmup AA") or not var_580_4) and (not var_0_140(var_580_1, "Round end AA") or not var_580_5) then
		return false
	end

	local var_580_6 = 0

	if var_580_2 == "Half" then
		var_580_6 = math.sin(globals.tickcount * (var_580_3 / 10)) * 135
	else
		var_580_6 = globals.tickcount * 2^var_580_3 % 360
	end

	var_0_9.antiaim.aa_enable:override(true)
	var_0_9.antiaim.aa_pitch:override("Disabled")
	var_0_9.antiaim.aa_yaw:override("Backward")
	var_0_9.antiaim.aa_yaw_base:override("Local View")
	var_0_9.antiaim.aa_yaw_offset:override(var_580_6)
	var_0_9.antiaim.aa_modifier:override("Offset")
	var_0_9.antiaim.aa_modifier_offset:override(0)
	var_0_9.antiaim.aa_bodyyaw:override(false)
	var_0_9.antiaim.body_left:override(0)
	var_0_9.antiaim.body_right:override(0)
	var_0_9.antiaim.aa_hidden:override(false)

	return true
end

local function var_0_155(arg_581_0, arg_581_1)
	if (arg_581_1 and arg_581_1.defensive or {}).enable ~= true then
		var_0_17.runtime.force_defensive = false

		return false
	end

	local var_581_0 = var_0_24.antiaim.fr_d.force_defensive

	if not var_581_0.enable:get() then
		var_0_17.runtime.force_defensive = false

		return false
	end

	local var_581_1 = entity.get_local_player()

	if not var_581_1 or not var_581_1:is_alive() then
		var_0_17.runtime.force_defensive = false

		return false
	end

	local var_581_2 = var_581_0.disablers:get() or {}
	local var_581_3 = entity.get_threat and entity.get_threat(true) or nil
	local var_581_4 = var_0_153()
	local var_581_5 = var_0_17.runtime.round_ended == true and globals.curtime <= var_0_17.runtime.round_end_time and not var_581_4

	if var_0_140(var_581_2, "Fake Duck") and var_0_9.antiaim.fakedick:get() then
		var_0_17.runtime.force_defensive = false

		return false
	end

	if var_0_140(var_581_2, "Warmup AA") and var_581_4 then
		var_0_17.runtime.force_defensive = false

		return false
	end

	if var_0_140(var_581_2, "Round End AA") and var_581_5 then
		var_0_17.runtime.force_defensive = false

		return false
	end

	if var_0_140(var_581_2, "No Enemy") and not var_581_3 then
		var_0_17.runtime.force_defensive = false

		return false
	end

	local var_581_6 = var_0_146()

	var_0_17.runtime.force_defensive = var_581_6

	return var_581_6
end

local function var_0_156(arg_582_0)
	local var_582_0 = arg_582_0.modifier or "Disabled"
	local var_582_1 = arg_582_0.modifier_mode or "Randomize"
	local var_582_2 = arg_582_0.modifier_offset or 0
	local var_582_3 = math.max(0, math.min(100, arg_582_0.modifier_randomize or 0))
	local var_582_4 = arg_582_0.modifier_min or 0
	local var_582_5 = arg_582_0.modifier_max or 0

	if var_582_0 == "Disabled" then
		return 0
	end

	if globals.choked_commands == 0 then
		var_0_17.runtime.defensive_modifier_tick = var_0_17.runtime.defensive_modifier_tick + 1

		if var_0_17.runtime.defensive_modifier_tick >= 1 then
			var_0_17.runtime.defensive_modifier_tick = 0
			var_0_17.runtime.defensive_modifier_side = not var_0_17.runtime.defensive_modifier_side
		end
	end

	local var_582_6 = var_0_17.runtime.defensive_modifier_side
	local var_582_7 = var_582_2

	local function var_582_8(arg_583_0, arg_583_1)
		local var_583_0 = math.abs(arg_583_0) * (arg_583_1 / 100)
		local var_583_1 = arg_583_0 - var_583_0
		local var_583_2 = arg_583_0 + var_583_0

		return var_0_136(var_583_1, var_583_2)
	end

	if var_582_0 == "Center" then
		if var_582_1 == "Min - Max" then
			var_582_7 = var_0_136(var_582_4, var_582_5)
		else
			var_582_7 = var_582_8(var_582_2, var_582_3)
		end

		return var_582_6 and var_582_7 / 2 or -var_582_7 / 2
	end

	if var_582_0 == "Offset" then
		if var_582_1 == "Min - Max" then
			var_582_7 = var_0_136(var_582_4, var_582_5)
		else
			var_582_7 = var_582_8(var_582_2, var_582_3)
		end

		return var_582_6 and var_582_7 or 0
	end

	if var_582_0 == "Random" then
		if var_582_1 == "Min - Max" then
			return var_0_136(var_582_4, var_582_5)
		end

		return var_0_136(-math.abs(var_582_2), math.abs(var_582_2))
	end

	if var_582_0 == "3-Way" then
		local var_582_9 = var_582_1 == "Min - Max" and var_0_136(var_582_4, var_582_5) or var_582_8(var_582_2, var_582_3)

		return ({
			-var_582_9,
			0,
			var_582_9
		})[globals.tickcount % 3 + 1]
	end

	if var_582_0 == "5-Way" then
		local var_582_10 = var_582_1 == "Min - Max" and var_0_136(var_582_4, var_582_5) or var_582_8(var_582_2, var_582_3)

		return ({
			-var_582_10,
			-var_582_10 / 2,
			0,
			var_582_10 / 2,
			var_582_10
		})[globals.tickcount % 5 + 1]
	end

	return 0
end

local function var_0_157(arg_584_0, arg_584_1)
	local var_584_0 = arg_584_0.defensive or {}

	if var_584_0.enable ~= true then
		var_0_9.antiaim.aa_hidden:override(false)

		return false
	end

	if arg_584_1 ~= true then
		var_0_9.antiaim.aa_hidden:override(false)

		return false
	end

	var_0_9.antiaim.aa_hidden:override(true)

	local var_584_1 = 0
	local var_584_2 = 0

	if var_584_0.pitch == "Disabled" then
		var_584_1 = 0
	elseif var_584_0.pitch == "Down" then
		var_584_1 = 89
	elseif var_584_0.pitch == "Up" then
		var_584_1 = -89
	elseif var_584_0.pitch == "Random" then
		local var_584_3 = var_584_0.pitch_first or 0
		local var_584_4 = var_584_0.pitch_second or 0

		if var_584_4 < var_584_3 then
			var_584_3, var_584_4 = var_584_4, var_584_3
		end

		var_584_1 = utils.random_float(var_584_3, var_584_4)
	elseif var_584_0.pitch == "Custom" then
		var_584_1 = var_584_0.pitch_custom or 0
	end

	if var_584_0.yaw == "Disabled" then
		var_584_2 = 0
	elseif var_584_0.yaw == "Random" then
		local var_584_5 = var_584_0.yaw_first or 0
		local var_584_6 = var_584_0.yaw_second or 0

		if var_584_6 < var_584_5 then
			var_584_5, var_584_6 = var_584_6, var_584_5
		end

		var_584_2 = utils.random_float(var_584_5, var_584_6)
	elseif var_584_0.yaw == "Spin" then
		var_0_17.runtime.defensive_spin = (var_0_17.runtime.defensive_spin + math.max(var_584_0.yaw_speed or 1, 1)) % -360
		var_584_2 = var_0_17.runtime.defensive_spin - 180
	elseif var_584_0.yaw == "Custom" then
		var_584_2 = var_584_0.yaw_custom or 0
	end

	local var_584_7 = var_584_2 + var_0_156(var_584_0)

	if rage and rage.antiaim and rage.antiaim.override_hidden_pitch then
		rage.antiaim:override_hidden_pitch(var_584_1)
	end

	if rage and rage.antiaim and rage.antiaim.override_hidden_yaw_offset then
		rage.antiaim:override_hidden_yaw_offset(var_584_7)
	end

	return true
end

local function var_0_158()
	local var_585_0 = var_0_24.antiaim.help
	local var_585_1 = var_585_0.manual_yaw:get()
	local var_585_2 = var_585_0.freestanding:get()

	if var_585_1 ~= "Disabled" then
		var_0_9.antiaim.aa_yaw_base:override("Local View")

		if var_585_1 == "Left" then
			var_0_9.antiaim.aa_yaw_offset:override(-90)
		elseif var_585_1 == "Right" then
			var_0_9.antiaim.aa_yaw_offset:override(90)
		elseif var_585_1 == "Forward" then
			var_0_9.antiaim.aa_yaw_offset:override(180)
		end
	end

	function var_0_158()
		local var_586_0 = var_0_24.antiaim.help
		local var_586_1 = var_586_0.manual_yaw:get()

		if var_586_1 ~= "Disabled" then
			var_0_9.antiaim.aa_yaw_base:override("Local View")

			if var_586_1 == "Left" then
				var_0_9.antiaim.aa_yaw_offset:override(-90)
			elseif var_586_1 == "Right" then
				var_0_9.antiaim.aa_yaw_offset:override(90)
			elseif var_586_1 == "Forward" then
				var_0_9.antiaim.aa_yaw_offset:override(180)
			end
		end

		if var_586_1 ~= "Disabled" and var_586_0.manual_yaw.manual_over_fs:get() then
			var_0_9.antiaim.freestand:override(false)
			var_0_9.antiaim.freestand_disable_yaw:override(false)
			var_0_9.antiaim.freestand_body:override(false)
		else
			WS_FREESTANDING:run()
		end
	end
end

local function var_0_159(arg_587_0)
	if not entity.get_local_player() then
		return
	end

	var_0_17.runtime.fixed_state = var_0_17.runtime.current

	local var_587_0 = var_0_17.cond[var_0_17.runtime.fixed_state]

	if not var_587_0 then
		return
	end

	local var_587_1 = var_0_123()
	local var_587_2 = var_0_124(var_587_0, var_587_1)
	local var_587_3 = var_0_124("Shared", var_587_1)

	if not var_587_2 or not var_587_3 then
		return
	end

	local var_587_4 = var_587_2.override and var_587_0 or "Shared"
	local var_587_5 = var_0_124(var_587_4, var_587_1)

	if not var_587_5 then
		return
	end

	if var_0_154() then
		return
	end

	force_active = var_0_155(arg_587_0, var_587_5)
	defensive_active = var_0_157(var_587_5, force_active)

	var_0_141(arg_587_0)
	var_0_142()

	local var_587_6 = var_0_139(var_587_5)

	var_0_17.runtime.jitter_update = var_587_6

	local var_587_7 = var_0_17.runtime.side == 0 and (var_587_5.left or 0) or var_587_5.right or 0
	local var_587_8 = var_0_150(var_587_5, var_587_7)

	if var_587_6 or var_587_5.delay.enable ~= true then
		var_0_17.runtime.cached_yaw = var_587_8
	else
		var_587_8 = var_0_17.runtime.cached_yaw or var_587_8
	end

	var_0_9.antiaim.aa_enable:override(true)
	var_0_9.antiaim.aa_pitch:override("Down")
	var_0_9.antiaim.aa_yaw:override("Backward")
	var_0_9.antiaim.aa_yaw_base:override(var_587_5.yaw_base and var_587_5.yaw_base.base or "Local View")
	var_0_9.antiaim.aa_yaw_offset:override(var_587_8)

	if defensive_active then
		var_0_9.antiaim.aa_bodyyaw:override(true)
	else
		var_0_149(var_587_5)
	end

	var_0_152(var_587_5)
	var_0_147(var_587_5)
	WS_FORCE_DEFENSIVE:run()

	if not defensive_active then
		var_0_158()
		var_0_144()
		var_0_143()
	end

	var_0_145()
end

function var_0_131()
	local var_588_0 = var_0_28()
	local var_588_1 = var_588_0 == 2 or var_588_0 == "Defensive"

	var_0_24.antiaim.left.aa.yawbase:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.yawjitter.lr.yawbuilder:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.yawjitter.lr.desync:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.extension.break_lc:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.extension.options:set_visible(not var_588_1)
	var_0_24.antiaim.left.aa.extension.tickbase:set_visible(not var_588_1)

	local var_588_2 = var_0_24.antiaim.left.aa.defensive

	var_588_2.enable:set_visible(var_588_1)
	var_588_2.pitch:set_visible(var_588_1 and var_588_2.enable:get())
	var_588_2.yaw:set_visible(var_588_1 and var_588_2.enable:get())

	local var_588_3 = var_0_24.antiaim.left.aa.yawjitter.lr.yawbuilder
	local var_588_4 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier
	local var_588_5 = var_588_4.mode:get()
	local var_588_6 = var_588_4.modifier:get()
	local var_588_7 = var_588_4.custom_count:get()
	local var_588_8 = var_0_121()
	local var_588_9 = var_588_6 == "Custom Way"
	local var_588_10 = var_588_6 == "LC"
	local var_588_11 = var_588_6 == "Disabled"
	local var_588_12 = var_588_5 == "Default"
	local var_588_13 = var_588_5 == "Custom"
	local var_588_14 = var_588_6 == "Center" or var_588_6 == "Offset" or var_588_6 == "Random" or var_588_6 == "Spin" or var_588_6 == "3-Way" or var_588_6 == "5-Way"

	for iter_588_0, iter_588_1 in ipairs(var_0_17.cond) do
		if iter_588_0 ~= 1 and var_0_24.antiaim.left.override[iter_588_1] then
			var_0_24.antiaim.left.override[iter_588_1]:set_visible(iter_588_0 == var_588_8)
		end
	end

	var_588_4.mode:set_visible(not var_588_1 and var_588_14 and not var_588_11)
	var_588_4.degree:set_visible(not var_588_1 and (var_588_14 and var_588_12 and var_588_6 ~= "Spin" or var_588_9))
	var_588_4.randomize:set_visible(not var_588_1 and var_588_14 and var_588_12 and var_588_6 == "Center")
	var_588_4.lc_min:set_visible(not var_588_1 and var_588_10)
	var_588_4.lc_max:set_visible(not var_588_1 and var_588_10)
	var_588_4.spin_seed:set_visible(not var_588_1 and var_588_14 and var_588_12 and var_588_6 == "Spin")
	var_588_4.custom_count:set_visible(not var_588_1 and var_588_14 and var_588_13)
	var_588_4.custom_way:set_visible(not var_588_1 and var_588_9)

	for iter_588_2 = 1, 6 do
		var_588_4.custom[iter_588_2]:set_visible(not var_588_1 and var_588_14 and var_588_13 and iter_588_2 <= var_588_7)
	end

	local var_588_15 = var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay
	local var_588_16 = var_0_24.antiaim.left.aa.yawjitter.lr.desync
	local var_588_17 = var_588_15.enable:get()
	local var_588_18 = var_588_15.mode:get()

	var_588_15.activation:set_visible(not var_588_1 and var_588_17)
	var_588_15.mode:set_visible(not var_588_1 and var_588_17)
	var_588_15.randomize:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Default")
	var_588_15.hold:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Default")
	var_588_15.from:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Random")
	var_588_15.to:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Random")
	var_588_15.count:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Custom")

	for iter_588_3 = 1, 6 do
		var_588_15.values[iter_588_3]:set_visible(not var_588_1 and var_588_17 and var_588_18 == "Custom" and iter_588_3 <= var_588_15.count:get())
	end

	local var_588_19 = var_588_16.mode:get()
	local var_588_20 = var_588_16.limit_mode:get()

	var_588_16.delay:set_visible(not var_588_1 and var_588_19 == "Delay")
	var_588_16.limit_mode:set_visible(not var_588_1 and var_588_19 ~= "Off" and var_588_19 ~= "Default")
	var_588_16.left:set_visible(not var_588_1 and (var_588_19 == "Default" or var_588_19 ~= "Off" and var_588_20 == "Default"))
	var_588_16.right:set_visible(not var_588_1 and (var_588_19 == "Default" or var_588_19 ~= "Off" and var_588_20 == "Default"))
	var_588_16.from:set_visible(not var_588_1 and var_588_19 ~= "Off" and var_588_19 ~= "Default" and (var_588_20 == "From / To" or var_588_20 == "Random"))
	var_588_16.to:set_visible(not var_588_1 and var_588_19 ~= "Off" and var_588_19 ~= "Default" and (var_588_20 == "From / To" or var_588_20 == "Random"))
	var_588_16.speed:set_visible(not var_588_1 and var_588_19 ~= "Off" and var_588_19 ~= "Default" and var_588_20 == "From / To")

	local var_588_21 = var_0_24.antiaim.left.aa.extension.options
	local var_588_22 = var_588_21.selection:get()
	local var_588_23 = var_0_140(var_588_22, "Warmup AA") or var_0_140(var_588_22, "Round end AA")

	var_588_21.mode:set_visible(var_588_23)
	var_588_21.speed:set_visible(var_588_23)

	local var_588_24 = var_0_24.antiaim.left.aa.extension.tickbase
	local var_588_25 = var_588_24.mode:get() == "Custom"

	var_588_24.random:set_visible(var_588_25)
	var_588_24.choke:set_visible(var_588_25)
	var_588_24.choke2:set_visible(var_588_25 and var_588_24.random:get())
	var_588_24.info:set_visible(var_588_25)

	local var_588_26 = var_0_24.antiaim.help

	var_588_26.manual_yaw.manual_over_fs:set_visible(var_588_26.manual_yaw:get() ~= "Disabled")
	var_588_26.freestanding.disable_yaw_modifiers:set_visible(var_588_26.freestanding:get())
	var_588_26.freestanding.body_freestanding:set_visible(var_588_26.freestanding:get())
	var_588_26.freestanding.conditions:set_visible(var_588_26.freestanding:get())

	local var_588_27 = var_0_24.antiaim.fr_d.force_defensive
	local var_588_28 = var_588_27.enable:get()
	local var_588_29 = var_588_27.mode:get()

	var_588_27.mode:set_visible(var_588_28)
	var_588_27.conditions:set_visible(var_588_28 and var_588_29 == "On Conditions")
	var_588_27.disablers:set_visible(var_588_28)

	local var_588_30 = var_0_24.antiaim.adder

	var_588_30.edge_yaw.ignore_manuals:set_visible(var_588_30.edge_yaw:get())
	var_588_30.safe_head.triggers:set_visible(var_588_30.safe_head:get())
	var_588_30.safe_head.height_difference:set_visible(var_588_30.safe_head:get() and var_0_140(var_588_30.safe_head.triggers:get() or {}, "Above Enemy"))

	local var_588_31 = var_0_24.antiaim.left.aa.defensive
	local var_588_32 = var_588_31.enable:get()
	local var_588_33 = var_588_31.pitch:get()
	local var_588_34 = var_588_31.yaw:get()
	local var_588_35 = var_588_31.modifier:get()
	local var_588_36 = var_588_31.modifier_mode:get()

	var_588_31.enable:set_visible(var_588_1)
	var_588_31.pitch:set_visible(var_588_1 and var_588_32)
	var_588_31.pitch_first:set_visible(var_588_1 and var_588_32 and var_588_33 == "Random")
	var_588_31.pitch_second:set_visible(var_588_1 and var_588_32 and var_588_33 == "Random")
	var_588_31.pitch_custom:set_visible(var_588_1 and var_588_32 and var_588_33 == "Custom")
	var_588_31.yaw:set_visible(var_588_1 and var_588_32)
	var_588_31.yaw_first:set_visible(var_588_1 and var_588_32 and var_588_34 == "Random")
	var_588_31.yaw_second:set_visible(var_588_1 and var_588_32 and var_588_34 == "Random")
	var_588_31.yaw_speed:set_visible(var_588_1 and var_588_32 and var_588_34 == "Spin")
	var_588_31.yaw_custom:set_visible(var_588_1 and var_588_32 and var_588_34 == "Custom")
	var_588_31.modifier:set_visible(var_588_1 and var_588_32)
	var_588_31.modifier_mode:set_visible(var_588_1 and var_588_32 and (var_588_35 == "Center" or var_588_35 == "Offset" or var_588_35 == "Random"))
	var_588_31.modifier_offset:set_visible(var_588_1 and var_588_32 and var_588_35 ~= "Disabled" and var_588_36 == "Randomize")
	var_588_31.modifier_randomize:set_visible(var_588_1 and var_588_32 and (var_588_35 == "Center" or var_588_35 == "Offset") and var_588_36 == "Randomize")
	var_588_31.modifier_min:set_visible(var_588_1 and var_588_32 and (var_588_35 == "Center" or var_588_35 == "Offset" or var_588_35 == "Random") and var_588_36 == "Min - Max")
	var_588_31.modifier_max:set_visible(var_588_1 and var_588_32 and (var_588_35 == "Center" or var_588_35 == "Offset" or var_588_35 == "Random") and var_588_36 == "Min - Max")
end

var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier.mode:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier.modifier:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.yaw_modifier.custom_count:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay.enable:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay.mode:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.yaw_delay.count:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.desync.mode:set_callback(var_0_131)
var_0_24.antiaim.left.aa.yawjitter.lr.desync.limit_mode:set_callback(var_0_131)
var_0_24.antiaim.left.aa.extension.options.selection:set_callback(var_0_131)
var_0_24.antiaim.left.aa.extension.tickbase.mode:set_callback(var_0_131)
var_0_24.antiaim.left.aa.extension.tickbase.random:set_callback(var_0_131)
var_0_24.antiaim.help.manual_yaw:set_callback(var_0_131)
var_0_24.antiaim.help.freestanding:set_callback(var_0_131)
var_0_24.antiaim.help.freestanding.conditions:set_callback(var_0_131)
var_0_24.antiaim.fr_d.force_defensive.enable:set_callback(var_0_131)
var_0_24.antiaim.fr_d.force_defensive.mode:set_callback(var_0_131)
var_0_24.antiaim.adder.edge_yaw:set_callback(var_0_131)
var_0_24.antiaim.adder.safe_head:set_callback(var_0_131)
var_0_24.antiaim.adder.safe_head.triggers:set_callback(var_0_131)
var_0_24.antiaim.left.builder:set_callback(function()
	if var_0_25._upd0 then
		return
	end

	var_0_25._upd0 = true

	local var_589_0 = var_0_28()

	if var_0_24.antiaim.left.builder.update then
		var_0_24.antiaim.left.builder:update(var_0_15(var_589_0))
	end

	if var_0_24.antiaim.left.builder.set then
		var_0_24.antiaim.left.builder:set(var_0_30(var_589_0))
	end

	var_0_25._upd0 = false

	if var_0_131 then
		var_0_131()
	end
end)
var_0_24.antiaim.left.aa.defensive.enable:set_callback(var_0_131)
var_0_24.antiaim.left.aa.defensive.pitch:set_callback(var_0_131)
var_0_24.antiaim.left.aa.defensive.yaw:set_callback(var_0_131)
var_0_24.antiaim.left.aa.defensive.modifier:set_callback(var_0_131)
var_0_24.antiaim.left.aa.defensive.modifier_mode:set_callback(var_0_131)
var_0_24.antiaim.left.current:set_callback(function()
	var_0_134()

	if var_0_131 then
		var_0_131()
	end
end)
var_0_24.antiaim.right.team:set_callback(function()
	if var_0_25._upd0 then
		return
	end

	var_0_25._upd0 = true

	local var_591_0 = var_0_29()

	if var_0_24.antiaim.right.team.update then
		var_0_24.antiaim.right.team:update(var_0_16(var_591_0))
	end

	if var_0_24.antiaim.right.team.set then
		var_0_24.antiaim.right.team:set(var_0_31(var_591_0))
	end

	var_0_25._upd0 = false

	var_0_134()
	var_0_130()

	if var_0_131 then
		var_0_131()
	end
end)

local function var_0_160(arg_592_0, arg_592_1)
	local var_592_0 = true
	local var_592_1 = arg_592_0

	if type(arg_592_0) == "function" then
		local var_592_2, var_592_3 = pcall(arg_592_0)

		var_592_1 = var_592_3

		if not var_592_2 then
			return
		end
	end

	if var_592_1 == nil then
		return
	end

	pcall(function()
		var_592_1:visibility(arg_592_1)
	end)
	pcall(function()
		var_592_1:set_visible(arg_592_1)
	end)
	pcall(function()
		var_592_1:visible(arg_592_1)
	end)
end

local function var_0_161()
	local var_596_0 = var_0_24.other.tab:get()
	local var_596_1 = var_596_0 == 1 or tostring(var_596_0):find("Visual", 1, true) ~= nil
	local var_596_2 = var_596_0 == 2 or tostring(var_596_0):find("Misc", 1, true) ~= nil
	local var_596_3 = var_0_24.other.visual.scope_paint
	local var_596_4 = var_0_24.other.visual.aspect_ratio
	local var_596_5 = var_0_24.other.visual.center_indicators
	local var_596_6 = var_0_24.other.visual.windows
	local var_596_7 = var_0_24.other.misc.client_anim

	var_0_160(var_596_3, var_596_1)
	var_0_160(var_596_4, var_596_1)
	var_0_160(var_596_5, var_596_1)
	var_0_160(var_596_6, var_596_1)
	var_0_160(var_596_7, var_596_2)

	local var_596_8 = var_596_1 and var_596_3:get() or false

	var_0_160(function()
		return var_596_3.scope_type
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_mode
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_flags
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_length
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_offset
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_main
	end, var_596_8)
	var_0_160(function()
		return var_596_3.scope_second
	end, var_596_8)

	local var_596_9 = var_596_1

	var_0_160(function()
		return var_596_4.asp_value
	end, var_596_9)
	var_0_160(function()
		return var_596_4.default
	end, var_596_9)
	var_0_160(function()
		return var_596_4.b32
	end, var_596_9)
	var_0_160(function()
		return var_596_4.b43
	end, var_596_9)
	var_0_160(function()
		return var_596_4.b54
	end, var_596_9)
	var_0_160(function()
		return var_596_4.b169
	end, var_596_9)
	var_0_160(function()
		return var_596_4.b1610
	end, var_596_9)

	local var_596_10 = var_596_1 and var_596_5:get() or false
	local var_596_11 = var_596_5.mode:get()
	local var_596_12 = var_596_11 == "Gradient Master" or var_596_11 == 2
	local var_596_13 = var_596_11 == "Default" or var_596_11 == 1
	local var_596_14 = var_596_5.master_count:get() or 1

	var_0_160(function()
		return var_596_5.mode
	end, var_596_10)
	var_0_160(function()
		return var_596_5.show_extra
	end, var_596_10)
	var_0_160(function()
		return var_596_5.glow
	end, var_596_10)
	var_0_160(function()
		return var_596_5.glow_color
	end, var_596_10 and var_596_5.glow:get())
	var_0_160(function()
		return var_596_5.y_offset
	end, var_596_10)
	var_0_160(function()
		return var_596_5.main_font
	end, var_596_10)
	var_0_160(function()
		return var_596_5.ind_font
	end, var_596_10)
	var_0_160(function()
		return var_596_5.default_main
	end, var_596_10 and var_596_13)
	var_0_160(function()
		return var_596_5.default_second
	end, var_596_10 and var_596_13)
	var_0_160(function()
		return var_596_5.speed
	end, var_596_10)
	var_0_160(function()
		return var_596_5.master_count
	end, var_596_10 and var_596_12)
	var_0_160(function()
		return var_596_5.g1
	end, var_596_10 and var_596_12 and var_596_14 >= 1)
	var_0_160(function()
		return var_596_5.g2
	end, var_596_10 and var_596_12 and var_596_14 >= 2)
	var_0_160(function()
		return var_596_5.g3
	end, var_596_10 and var_596_12 and var_596_14 >= 3)
	var_0_160(function()
		return var_596_5.g4
	end, var_596_10 and var_596_12 and var_596_14 >= 4)
	var_0_160(function()
		return var_596_5.g5
	end, var_596_10 and var_596_12 and var_596_14 >= 5)

	local var_596_15 = var_596_1 and var_596_6:get() or false
	local var_596_16 = var_596_6.items and var_596_6.items:get() or {}
	local var_596_17 = var_596_15 and var_0_56(var_596_16, "Watermark")

	var_0_160(function()
		return var_596_6.items
	end, var_596_15)
	var_0_160(function()
		return var_596_6.bg_style
	end, var_596_15)
	var_0_160(function()
		return var_596_6.text_color
	end, var_596_15)
	var_0_160(function()
		return var_596_6.glow_color
	end, var_596_15)
	var_0_160(function()
		return var_596_6.watermark_items
	end, var_596_17)
	var_0_160(function()
		return var_596_6.nickname_source
	end, var_596_17 and var_0_56(var_596_6.watermark_items:get() or {}, "Nickname"))
	var_0_160(function()
		return var_596_6.wm_speed
	end, var_596_17)
	var_0_160(function()
		return var_596_6.distance
	end, var_596_17)

	local var_596_18 = var_596_2 and var_596_7:get() or false
	local var_596_19 = var_596_7.addons:get() or {}

	var_0_160(function()
		return var_596_7.ground_legs
	end, var_596_18)
	var_0_160(function()
		return var_596_7.air_legs
	end, var_596_18)
	var_0_160(function()
		return var_596_7.addons
	end, var_596_18)
	var_0_160(function()
		return var_596_7.move_lean_amount
	end, var_596_18 and var_0_32(var_596_19, "Move Lean"))
end

local function var_0_162()
	local var_639_0 = var_0_24.other.tab:get()
	local var_639_1 = var_639_0 == 1 or tostring(var_639_0):find("Visual", 1, true) ~= nil
	local var_639_2 = var_0_24.other.visual.damage_indicator

	if not var_639_2 then
		return
	end

	local var_639_3 = var_639_1 and var_639_2:get() or false
	local var_639_4 = var_639_2.mode and var_639_2.mode:get() or "Default"
	local var_639_5 = var_639_4 == "Double" or var_639_4 == 2

	var_0_160(var_639_2, var_639_1)
	var_0_160(function()
		return var_639_2.mode
	end, var_639_3)
	var_0_160(function()
		return var_639_2.double_distance
	end, var_639_3 and var_639_5)
	var_0_160(function()
		return var_639_2.only_override
	end, var_639_3)
	var_0_160(function()
		return var_639_2.font
	end, var_639_3)
	var_0_160(function()
		return var_639_2.color
	end, var_639_3)
	var_0_160(function()
		return var_639_2.override_color
	end, var_639_3)
end

local function var_0_163()
	local var_646_0 = var_0_24.other.tab:get()
	local var_646_1 = var_646_0 == 1 or tostring(var_646_0):find("Visual", 1, true) ~= nil
	local var_646_2 = var_0_24.other.visual.money_indicators

	if not var_646_2 then
		return
	end

	local var_646_3 = var_646_1 and var_646_2:get() or false
	local var_646_4 = var_646_2.mode and var_646_2.mode:get() or "Default"
	local var_646_5 = var_646_4 == "Custom" or var_646_4 == 2

	var_0_160(var_646_2, var_646_1)
	var_0_160(function()
		return var_646_2.mode
	end, var_646_3)
	var_0_160(function()
		return var_646_2.select
	end, var_646_3)
	var_0_160(function()
		return var_646_2.animated
	end, var_646_3)
	var_0_160(function()
		return var_646_2.custom_style
	end, var_646_3 and var_646_5)
	var_0_160(function()
		return var_646_2.accent
	end, var_646_3)
	var_0_160(function()
		return var_646_2.y_offset
	end, var_646_3)
end

local function var_0_164()
	local var_653_0 = var_0_24.other.tab:get()
	local var_653_1 = var_653_0 == 2 or tostring(var_653_0):find("Misc", 1, true) ~= nil
	local var_653_2 = var_0_24.other.misc.no_fall_damage
	local var_653_3 = var_0_24.other.misc.fast_ladder
	local var_653_4 = var_0_24.other.misc.edge_stop
	local var_653_5 = var_0_24.other.misc.keep_model_transparency
	local var_653_6 = var_0_24.other.misc.fake_latency
	local var_653_7 = var_0_24.other.misc.super_toss

	var_0_160(var_653_2, var_653_1)
	var_0_160(var_653_3, var_653_1)
	var_0_160(var_653_4, var_653_1)
	var_0_160(var_653_5, var_653_1)
	var_0_160(var_653_6, var_653_1)
	var_0_160(var_653_7, var_653_1)
	var_0_160(function()
		return var_653_6.amount
	end, var_653_1 and var_653_6 and var_653_6:get())
end

local function var_0_165()
	local var_655_0 = var_0_24.other.tab:get()
	local var_655_1 = var_655_0 == 2 or tostring(var_655_0):find("Misc", 1, true) ~= nil
	local var_655_2 = var_0_24.other.misc.fakeduck_modifiers

	if not var_655_2 then
		return
	end

	var_0_160(var_655_2, var_655_1)
	var_0_160(function()
		return var_655_2.freezetime_fakeduck
	end, var_655_1)
	var_0_160(function()
		return var_655_2.unlock_fakeduck_speed
	end, var_655_1)
end

local function var_0_166()
	local var_658_0 = var_0_24.other.tab:get()
	local var_658_1 = var_658_0 == 1 or tostring(var_658_0):find("Visual", 1, true) ~= nil
	local var_658_2 = var_0_24.other.visual.disable_sleeves
	local var_658_3 = var_0_24.other.visual.lagcomp_box

	var_0_160(var_658_2, var_658_1)
	var_0_160(var_658_3, var_658_1)

	if var_658_3 then
		local var_658_4 = var_658_1 and var_658_3:get() or false

		var_0_160(function()
			return var_658_3.color
		end, var_658_4)
		var_0_160(function()
			return var_658_3.defensive_color
		end, var_658_4)
		var_0_160(function()
			return var_658_3.text
		end, var_658_4)
	end
end

local function var_0_167()
	local var_662_0 = var_0_24.other.tab:get()
	local var_662_1 = var_662_0 == 2 or tostring(var_662_0):find("Misc", 1, true) ~= nil
	local var_662_2 = var_0_24.other.misc.print_events

	if not var_662_2 then
		return
	end

	local var_662_3 = var_662_1 and var_662_2:get()

	var_0_160(var_662_2, var_662_1)
	var_0_160(function()
		return var_662_2.events
	end, var_662_3)
	var_0_160(function()
		return var_662_2.output
	end, var_662_3)
	var_0_160(function()
		return var_662_2.style
	end, var_662_3)
	var_0_160(function()
		return var_662_2.text_color
	end, var_662_3)
	var_0_160(function()
		return var_662_2.glow_hit
	end, var_662_3)
	var_0_160(function()
		return var_662_2.glow_miss
	end, var_662_3)
end

local function var_0_168()
	local var_669_0 = var_0_24.other.tab:get()
	local var_669_1 = var_669_0 == 2 or tostring(var_669_0):find("Misc", 1, true) ~= nil
	local var_669_2 = var_0_24.other.misc.viewmodel_changer

	if not var_669_2 then
		return
	end

	var_0_160(var_669_2, var_669_1)
	var_0_160(function()
		return var_669_2.fov
	end, var_669_1)
	var_0_160(function()
		return var_669_2.x
	end, var_669_1)
	var_0_160(function()
		return var_669_2.y
	end, var_669_1)
	var_0_160(function()
		return var_669_2.z
	end, var_669_1)
	var_0_160(function()
		return var_669_2.options
	end, var_669_1)
	var_0_160(function()
		return var_669_2.reset
	end, var_669_1)
end

local function var_0_169()
	local var_676_0 = var_0_24.other.tab:get()
	local var_676_1 = var_676_0 == 1 or tostring(var_676_0):find("Visual", 1, true) ~= nil
	local var_676_2 = var_0_24.other.visual.hitmarker

	if not var_676_2 then
		return
	end

	local var_676_3 = var_676_1 and var_676_2:get()
	local var_676_4 = {}

	pcall(function()
		var_676_4 = var_676_2.marker_select:get() or {}
	end)
	var_0_160(var_676_2, var_676_1)
	var_0_160(function()
		return var_676_2.marker_select
	end, var_676_3)
	var_0_160(function()
		return var_676_2.center_color
	end, var_676_3 and WS_HITMARKER:has(var_676_4, "Center"))
	var_0_160(function()
		return var_676_2.kibit_color
	end, var_676_3 and WS_HITMARKER:has(var_676_4, "Kibit"))
end

local function var_0_170()
	local var_681_0 = var_0_24.other.tab:get()
	local var_681_1 = var_681_0 == 1 or tostring(var_681_0):find("Visual", 1, true) ~= nil
	local var_681_2 = var_0_24.other.visual.crosshair_style

	if not var_681_2 then
		return
	end

	local var_681_3 = var_681_1 and var_681_2:get()

	var_0_160(var_681_2, var_681_1)
	var_0_160(function()
		return var_681_2.style
	end, var_681_3)
end

local function var_0_171()
	local var_683_0 = var_0_24.other.tab:get()
	local var_683_1 = var_683_0 == 2 or tostring(var_683_0):find("Misc", 1, true) ~= nil
	local var_683_2 = var_0_24.other.misc.auto_clear

	if not var_683_2 then
		return
	end

	local var_683_3 = var_683_1 and var_683_2:get()

	var_0_160(var_683_2, var_683_1)
	var_0_160(function()
		return var_683_2.when
	end, var_683_3)
end

local function var_0_172()
	local var_685_0 = var_0_24.other.tab:get()
	local var_685_1 = var_685_0 == 2 or tostring(var_685_0):find("Misc", 1, true) ~= nil

	var_0_160(var_0_24.other.misc.clan_tag, var_685_1)
end

local function var_0_173()
	local var_686_0 = var_0_24.other.tab:get()
	local var_686_1 = var_686_0 == 2 or tostring(var_686_0):find("Misc", 1, true) ~= nil
	local var_686_2 = var_0_24.other.misc.trash_talk

	if not var_686_2 then
		return
	end

	local var_686_3 = var_686_1 and var_686_2:get()

	var_0_160(var_686_2, var_686_1)
	var_0_160(function()
		return var_686_2.language
	end, var_686_3)
	var_0_160(function()
		return var_686_2.triggers
	end, var_686_3)
	var_0_160(function()
		return var_686_2.delay
	end, var_686_3)
end

local function var_0_174()
	var_0_161()
	var_0_162()
	var_0_163()
	var_0_164()
	var_0_165()
	var_0_166()
	var_0_167()
	var_0_168()
	var_0_169()
	var_0_170()
	var_0_171()
	var_0_172()
	var_0_173()
end

pcall(function()
	var_0_24.other.tab:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.damage_indicator:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.damage_indicator.mode:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.money_indicators:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.money_indicators.mode:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.scope_paint:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.aspect_ratio:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.aspect_ratio.asp_value:set_callback(function()
		var_0_101()
		var_0_174()
	end)
end)
pcall(function()
	var_0_24.other.visual.center_indicators:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.center_indicators.mode:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.center_indicators.glow:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.center_indicators.master_count:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.windows:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.windows.items:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.windows.watermark_items:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.no_fall_damage:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.fast_ladder:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.super_toss:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.fakeduck_modifiers:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.edge_stop:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.keep_model_transparency:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.fake_latency:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.disable_sleeves:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.lagcomp_box:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.client_anim:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.client_anim.addons:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.print_events:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.print_events.events:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.print_events.output:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.print_events.style:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.hitmarker:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.hitmarker.marker_select:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.crosshair_style:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.visual.crosshair_style.style:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.auto_clear:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.clan_tag:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.trash_talk:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.viewmodel_changer:set_callback(var_0_174)
end)
pcall(function()
	var_0_24.other.misc.viewmodel_changer.reset:set_callback(function()
		var_0_115()
		var_0_174()
	end)
end)
pcall(function()
	var_0_9.antiaim.fakexyetensi:override()
end)
pcall(function()
	cvar.sv_maxunlag:float(0.2, true)
end)
var_0_174()
var_0_131()
var_0_130()
var_0_128(var_0_121())
events.round_end:set(function()
	var_0_17.runtime.round_ended = true
	var_0_17.runtime.round_end_time = globals.curtime + 8
end)
events.round_prestart:set(function()
	var_0_17.runtime.round_ended = false
	var_0_17.runtime.round_end_time = 0
end)
events.round_start:set(function()
	var_0_17.runtime.round_ended = false
	var_0_17.runtime.round_end_time = 0
end)
events.round_freeze_end:set(function()
	var_0_17.runtime.round_ended = false
	var_0_17.runtime.round_end_time = 0
end)
pcall(function()
	events.player_disconnect:set(function(arg_739_0)
		local var_739_0 = entity.get_local_player()

		if not var_739_0 then
			var_0_48()

			return
		end

		local var_739_1 = ""

		pcall(function()
			var_739_1 = var_739_0:get_name() or ""
		end)

		if arg_739_0 and arg_739_0.name and tostring(arg_739_0.name) == tostring(var_739_1) then
			var_0_48()
		end
	end)
end)
pcall(function()
	events.level_init:set(function()
		var_0_48()
	end)
end)
pcall(function()
	events.map_shutdown:set(function()
		var_0_48()
	end)
end)
pcall(function()
	events.cs_game_disconnected:set(function()
		var_0_48()
	end)
end)
pcall(function()
	events.item_purchase:set(function(arg_748_0)
		if WS_PRINT_EVENTS and WS_PRINT_EVENTS.item_purchase then
			WS_PRINT_EVENTS:item_purchase(arg_748_0)
		end
	end)
end)
pcall(function()
	events.player_death:set(function(arg_750_0)
		if WS_PRINT_EVENTS and WS_PRINT_EVENTS.player_death then
			WS_PRINT_EVENTS:player_death(arg_750_0)
		end

		if WS_PRINT_EVENTS and WS_PRINT_EVENTS.player_death then
			WS_PRINT_EVENTS:player_death(arg_750_0)
		end

		if WS_TRASHTALK and WS_TRASHTALK.player_death then
			WS_TRASHTALK:player_death(arg_750_0)
		end
	end)
end)
pcall(function()
	events.round_start:set(function()
		if WS_AUTO_CLEAR then
			WS_AUTO_CLEAR:run("round_start")
		end
	end)
end)
pcall(function()
	events.round_prestart:set(function()
		if WS_AUTO_CLEAR then
			WS_AUTO_CLEAR:run("round_start")
		end
	end)
end)
pcall(function()
	events.round_end:set(function()
		if WS_AUTO_CLEAR then
			WS_AUTO_CLEAR:run("match_end")
		end
	end)
end)
pcall(function()
	events.cs_win_panel_match:set(function()
		if WS_AUTO_CLEAR then
			WS_AUTO_CLEAR:run("match_end")
		end
	end)
end)
pcall(function()
	events.player_hurt:set(function(arg_760_0)
		if WS_HITMARKER and WS_HITMARKER.player_hurt then
			WS_HITMARKER:player_hurt(arg_760_0)
		end
	end)
end)
pcall(function()
	events.player_spawned:set(function(arg_762_0)
		if WS_HITMARKER and WS_HITMARKER.player_spawned then
			WS_HITMARKER:player_spawned(arg_762_0)
		end
	end)
end)
pcall(function()
	events.round_start:set(function()
		if WS_HITMARKER and WS_HITMARKER.reset then
			WS_HITMARKER:reset()
		end
	end)
end)
pcall(function()
	events.grenade_override_view:set(function(arg_766_0)
		var_0_94(arg_766_0)
	end)
end)
pcall(function()
	events.createmove_run:set(function(arg_768_0)
		var_0_97(arg_768_0)
	end)
end)
events.createmove:set(function(arg_769_0)
	var_0_117()
	var_0_134()
	var_0_126(var_0_121(), var_0_122())
	var_0_127()
	var_0_159(arg_769_0)
	var_0_89(arg_769_0)
	var_0_90(arg_769_0)
	var_0_99(arg_769_0)
	var_0_96(arg_769_0)
	var_0_95(arg_769_0)
	var_0_53()
end)
events.post_update_clientside_animation:set(function()
	var_0_108()
end)
events.render:set(function()
	var_0_3:draw()
	var_0_6()
	var_0_88()
	var_0_116()
	var_0_101()
	var_0_43()
	WS_MONEY:draw()
	var_0_77()
	WS_WATERMARK:draw()
	var_0_81()
	var_0_85()
	WS_DAMAGE:draw()
	WS_PRINT_EVENTS:draw()
	WS_HITMARKER:draw()
	WS_CROSSHAIR_STYLE:run()
	var_0_55()
	var_0_98()
	WS_CLANTAG:run()
	WS_TRASHTALK:run()
end)
events.shutdown:set(function()
	pcall(function()
		var_0_135:write_file()
	end)
	var_0_112(cvar.viewmodel_fov, 6800, 6800)
	var_0_112(cvar.viewmodel_offset_x, 250, 250)
	var_0_112(cvar.viewmodel_offset_y, 0, 0)
	var_0_112(cvar.viewmodel_offset_z, -150, -150)
	var_0_114()

	if var_0_9.force_viewmodel then
		pcall(function()
			var_0_9.force_viewmodel:override(false)
		end)
	end

	pcall(function()
		var_0_9.antiaim.fakexyetensi:override()
	end)
	pcall(function()
		cvar.sv_maxunlag:float(0.2, true)
	end)

	if WS_CLANTAG and WS_CLANTAG.shutdown then
		WS_CLANTAG:shutdown()
	end

	if WS_TRASHTALK and WS_TRASHTALK.reset then
		WS_TRASHTALK:reset()
	end

	if WS_FORCE_DEFENSIVE and WS_FORCE_DEFENSIVE.reset then
		WS_FORCE_DEFENSIVE:reset()
	end

	if WS_FREESTANDING and WS_FREESTANDING.reset then
		WS_FREESTANDING:reset()
	end
end)
events.draw_model:set(function(arg_777_0)
	return var_0_49(arg_777_0)
end)
events.localplayer_transparency:set(function(arg_778_0)
	return var_0_100(arg_778_0)
end)