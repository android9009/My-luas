local stable_build = true

local NadeHelper =
    { traj = true, cache = setmetatable({}, { __mode = "k" }), keys = setmetatable({}, { __mode = "k" }) }
NadeHelper.style = { theme = true, width = 1.6, opacity = 1, glow = 1, comet = true, best = true }
function NadeHelper.setup_style(item)
    local ok, saved = pcall(function()
        return db.nhx_trajectory_style
    end)
    saved = ok and type(saved) == "table" and saved or {}
    saved.fire_drop = nil
    local function label(icon, text)
        return "\a{Link Active}" .. (ui.get_icon(icon) or "") .. "\aDEFAULT  " .. text
    end
    local function number(name, fallback, lo, hi)
        local n = tonumber(saved[name]) or fallback
        return math.max(lo, math.min(hi, n))
    end
    local function save(name, value)
        saved[name] = value
        pcall(function()
            db.nhx_trajectory_style = saved
        end)
    end
    local group = item:create()
    local theme = group:switch(label("palette", "Use helper color"), saved.theme ~= false)
    local rgba = type(saved.color) == "table" and saved.color or { 88, 224, 128, 255 }
    local picker = group:color_picker(
        label("paintbrush", "Trajectory color"),
        color(tonumber(rgba[1]) or 88, tonumber(rgba[2]) or 224, tonumber(rgba[3]) or 128, tonumber(rgba[4]) or 255)
    )
    picker:set_callback(function(ref)
        local col = ref:get()
        NadeHelper.style.color = col
        save("color", { col.r, col.g, col.b, col.a })
    end, true)
    theme:set_callback(function(ref)
        NadeHelper.style.theme = ref:get()
        picker:visibility(not NadeHelper.style.theme)
        save("theme", NadeHelper.style.theme)
    end, true)
    local function slider(label, name, lo, hi, value, display_scale, divisor)
        group:slider(label, lo, hi, number(name, value, lo, hi), display_scale):set_callback(function(ref)
            local v = ref:get()
            NadeHelper.style[name] = v / divisor
            save(name, v)
        end, true)
    end
    slider(label("ruler-horizontal", "Line width"), "width", 5, 50, 16, 0.1, 10)
    slider(label("circle-half-stroke", "Opacity"), "opacity", 0, 100, 100, 1, 100)
    slider(label("sun", "Glow"), "glow", 0, 100, 100, 1, 100)
    group:switch(label("circle-dot", "Moving dot"), saved.comet ~= false):set_callback(function(ref)
        NadeHelper.style.comet = ref:get()
        save("comet", NadeHelper.style.comet)
    end, true)
    NadeHelper.best_icon = ui.get_icon("star") or ""
    NadeHelper.target_icon = ui.get_icon("crosshairs") or ""
    group
        :switch(label("bullseye", "Highlight best lineup"), saved.best ~= false)
        :tooltip(
            "Highlights the best of the 32 nearest HE / molotov lineups within 1500 units. HE: lethal hits first, then total damage. Molotov: enemies covered, with obstacle checks. Includes dormant enemies at their last known position. Green = best overall; other colors mark individual enemies, with numbered names beside the lineup. Recalculates gradually; green is an estimate, not a guaranteed hit."
        )
        :set_callback(function(ref)
            NadeHelper.style.best = ref:get()
            NadeHelper.best, NadeHelper.best_work, NadeHelper.best_targets = nil, nil, nil
            save("best", NadeHelper.style.best)
        end, true)
end
do
    local floor, min, max, abs, sqrt, sin, cos, rad =
        math.floor, math.min, math.max, math.abs, math.sqrt, math.sin, math.cos, math.rad

    NadeHelper.FILL = color(22, 22, 25, 255)
    NadeHelper.EDGE = color(255, 255, 255, 255)
    NadeHelper.SHADOW = color(0, 0, 0, 255)
    NadeHelper.AMBER = color(255, 196, 64, 255)
    NadeHelper.GREEN = color(88, 224, 128, 255)
    NadeHelper.IDLE = color(150, 150, 158, 255)

    local function c(col, a)
        return color(col.r, col.g, col.b, floor(max(0, min(255, a))))
    end
    NadeHelper.c = c

    function NadeHelper.panel(x1, y1, x2, y2, alpha, r)
        x1, y1, x2, y2 = floor(x1 + 0.5), floor(y1 + 0.5), floor(x2 + 0.5), floor(y2 + 0.5)
        r = floor(min(r or 6, (y2 - y1) * 0.5, (x2 - x1) * 0.5))
        if alpha <= 0.01 then
            return
        end
        pcall(render.shadow, vector(x1, y1 + 1), vector(x2, y2 + 1), c(NadeHelper.SHADOW, 150 * alpha), 22, 0, r)
        render.rect(vector(x1 - 1, y1 - 1), vector(x2 + 1, y2 + 1), c(NadeHelper.EDGE, 22 * alpha), r + 1)
        render.rect(vector(x1, y1), vector(x2, y2), c(NadeHelper.FILL, 238 * alpha), r)
    end

    local KIND = {
        weapon_smokegrenade = "smoke",
        weapon_flashbang = "flash",
        weapon_hegrenade = "he",
        weapon_molotov = "molly",
        weapon_incgrenade = "molly",
        weapon_decoy = "decoy",
    }
    NadeHelper.KIND = KIND
    local MASK = 34095115
    local MINS, MAXS = vector(-2, -2, -2), vector(2, 2, 2)

    NadeHelper.PASS = {
        CAK47 = true,
        CDEagle = true,
        CC4 = true,
        CKnife = true,
        CKnifeGG = true,
        CChicken = true,
        CPlantedC4 = true,
        CHostage = true,
        CBaseWeaponWorldModel = true,
        CEconEntity = true,
        CItem_Healthshot = true,
        CItemCash = true,
        CItemAssaultSuit = true,
        CItemDogtags = true,
        CDrone = true,
        CDronegun = true,
        CBreachCharge = true,
        CBumpMine = true,
        CSnowball = true,
        CTablet = true,
        CFists = true,
        CMelee = true,
        CInferno = true,
    }
    local function hits(ent)
        if ent == nil then
            return true
        end
        if ent:is_player() then
            return false
        end
        local n = ent.get_classname and ent:get_classname() or ""

        if NadeHelper.PASS[n] or n:find("^CWeapon") or n:find("Projectile$") or n:find("Grenade$") then
            return false
        end
        return true
    end

    local function cvf(name, def)
        local v = cvar[name]
        local ok, f = pcall(function()
            return v:float()
        end)
        return ok and type(f) == "number" and f or def
    end

    local function forward(p, y)
        p, y = rad(p), rad(y)
        return vector(cos(p) * cos(y), cos(p) * sin(y), -sin(p))
    end

    local PMASK = 33636363
    local function pmove(px, py, pz, vx, vy, vz, dt, mins, maxs)
        local hitn
        for _ = 1, 3 do
            if dt <= 0 then
                break
            end
            local tr = utils.trace_hull(
                vector(px, py, pz),
                vector(px + vx * dt, py + vy * dt, pz + vz * dt),
                mins,
                maxs,
                hits,
                PMASK
            )
            if tr == nil or tr.start_solid then
                return nil
            end
            if tr.fraction >= 1 then
                return px + vx * dt, py + vy * dt, pz + vz * dt, vx, vy, vz, hitn
            end
            local n = tr.plane.normal
            px, py, pz = tr.end_pos.x, tr.end_pos.y, tr.end_pos.z
            local d = vx * n.x + vy * n.y + vz * n.z
            vx, vy, vz = vx - n.x * d, vy - n.y * d, vz - n.z * d
            dt = dt * (1 - tr.fraction)
            hitn = n
        end
        return px, py, pz, vx, vy, vz, hitn
    end

    local function body(L, g, ti, yield_fn)
        local p = L.position
        local px, py, pz = p.x, p.y, p.z
        local vx, vy, vz = 0, 0, 0
        local run = type(g.run) == "number" and g.run or nil
        local jump = g.jump and true or false
        if not run and not jump then
            return px, py, pz, 0, 0, 0, false
        end

        local lead = floor(0.1 / ti + 0.5) + 2
        local total = (run or 0) + (g.delay or 0) + lead + (jump and 1 or 0)

        local wish = L.duck and 245 * 0.34 or g.run_speed and 245 * 0.52 or 245
        local akf = (not L.duck and g.run_speed) and 0.9 or 1
        local dir = rad(L.viewangles.y + (g.run_yaw or 0))
        local dx, dy = cos(dir), sin(dir)
        local accel, fric, stop = cvf("sv_accelerate", 5.5), cvf("sv_friction", 5.2), cvf("sv_stopspeed", 80)
        local aaccel = cvf("sv_airaccelerate", 12)
        local grav = cvf("sv_gravity", 800)

        local mins, maxs = vector(-16, -16, 0), vector(16, 16, L.duck and 54 or 72)
        local air = false
        local jump_at = (run or 0) + 1
        for t = 1, total do
            if yield_fn and t % 24 == 0 then
                yield_fn()
            end
            if jump and t == jump_at then
                vz, air = sqrt(2 * grav * 57) + 0.5 * grav * ti, true
            end
            if air then
                local ovz = vz
                vz = vz - grav * ti
                if run then
                    local cur = vx * dx + vy * dy
                    local add = min(30, wish) - cur
                    if add > 0 then
                        local a = min(add, aaccel * wish * ti)
                        vx, vy = vx + dx * a, vy + dy * a
                    end
                end
                local mz = (ovz + vz) * 0.5
                local nx, ny, nz, nvx, nvy, nvz, n = pmove(px, py, pz, vx, vy, mz, ti, mins, maxs)
                if nx == nil then
                    px, py, pz = px + vx * ti, py + vy * ti, pz + mz * ti
                else
                    px, py, pz, vx, vy = nx, ny, nz, nvx, nvy
                    if n and n.z > 0.7 and t ~= jump_at and mz <= 0 then
                        air, vz = false, 0
                    elseif n and n.z < -0.7 then
                        vz = min(vz, 0)
                    end
                end
            else
                local sp = sqrt(vx * vx + vy * vy)
                if sp > 0.1 then
                    local drop = max(sp, stop) * fric * ti
                    local k = max(0, sp - drop) / sp
                    vx, vy = vx * k, vy * k
                end
                if run then
                    local cur = vx * dx + vy * dy
                    local add = wish - cur
                    if add > 0 then
                        local a = min(add, accel * ti * wish * akf)
                        vx, vy = vx + dx * a, vy + dy * a
                    end
                end
                if vx ~= 0 or vy ~= 0 then
                    local nx, ny, nz, nvx, nvy = pmove(px, py, pz + 18, vx, vy, 0, ti, mins, maxs)
                    if nx == nil then
                        nx, ny, nz, nvx, nvy = pmove(px, py, pz, vx, vy, 0, ti, mins, maxs)
                    end
                    if nx == nil then
                        px, py = px + vx * ti, py + vy * ti
                    else
                        vx, vy = nvx, nvy
                        local dn =
                            utils.trace_hull(vector(nx, ny, nz), vector(nx, ny, pz - 18), mins, maxs, hits, PMASK)
                        if dn and not dn.start_solid and dn.fraction < 1 and dn.plane.normal.z > 0.7 then
                            px, py, pz = dn.end_pos.x, dn.end_pos.y, dn.end_pos.z
                        elseif dn and not dn.start_solid then
                            px, py, pz = dn.end_pos.x, dn.end_pos.y, dn.end_pos.z
                            air, vz = true, 0
                        else
                            px, py = nx, ny
                        end
                    end
                end
            end
        end
        return px, py, pz, vx, vy, vz, true
    end

    local function aim(L)
        local s = max(0, min(1, (L.grenade or {}).strength or 1))
        local pitch, yaw = L.viewangles.x, L.viewangles.y
        if pitch > 90 then
            pitch = pitch - 360
        elseif pitch < -90 then
            pitch = pitch + 360
        end
        pitch = pitch - (90 - abs(pitch)) * 10 / 90
        return forward(pitch, yaw), max(15, min(750, 750 * 0.9)) * (0.3 + 0.7 * s), s
    end

    local function spawn_point(x, y, z, eye, f, s)
        local src = vector(x, y, z + eye + s * 12 - 12)
        local tr0 = utils.trace_hull(src, src + f * 22, MINS, MAXS, hits, MASK)
        if tr0 and tr0.end_pos then
            src = vector(tr0.end_pos.x - f.x * 6, tr0.end_pos.y - f.y * 6, tr0.end_pos.z - f.z * 6)
        end
        return src
    end

    function NadeHelper.simulate(L, lr, yield_fn)
        local g = L.grenade or {}
        local kind = KIND[L.weapon]
        if kind == nil or L.movement ~= nil or L.viewangles == nil or L.position == nil then
            return false
        end
        local ti = globals.tickinterval
        local grav = cvf("sv_gravity", 800) * 0.4
        local px, py, pz, vx, vy, vz, approx
        if lr then
            px, py, pz, vx, vy, vz, approx = lr[1], lr[2], lr[3], lr[4], lr[5], lr[6], false
        else
            local bx, by, bz, pvx, pvy, pvz
            bx, by, bz, pvx, pvy, pvz, approx = body(L, g, ti, yield_fn)
            local f, vel, s = aim(L)
            local src = spawn_point(bx, by, bz, L.duck and 46.04 or 64.06, f, s)
            vx, vy, vz = f.x * vel + pvx * 1.25, f.y * vel + pvy * 1.25, f.z * vel + pvz * 1.25
            px, py, pz = src.x, src.y, src.z
        end

        local det = kind == "molly" and cvf("molotov_throw_detonate_time", 2) or 1.5
        local slope = kind == "molly" and cos(rad(cvf("weapon_molotov_maxdetonateslope", 30))) or 2
        local think = max(1, floor(0.2 / ti + 0.5))
        local path, times, bounces = { vector(px, py, pz) }, { 0 }, {}
        local landed, steps = false, 0
        for i = 1, 768 do
            if yield_fn and i % 24 == 0 then
                yield_fn()
            end
            steps = i
            local nvz = vz - grav * ti
            local nx, ny, nz = px + vx * ti, py + vy * ti, pz + (vz + nvz) * 0.5 * ti
            vz = nvz
            local tr = utils.trace_hull(vector(px, py, pz), vector(nx, ny, nz), MINS, MAXS, hits, MASK)
            if tr.fraction ~= 1 then
                local n, ep = tr.plane.normal, tr.end_pos

                path[#path + 1] = vector(ep.x, ep.y, ep.z)
                times[#times + 1] = (i - 1 + tr.fraction) * ti
                if kind == "molly" and n.z > slope then
                    px, py, pz, landed = ep.x, ep.y, ep.z, true
                    break
                end
                local lb = bounces[#bounces]
                if lb == nil or lb.pos:dist(ep) > 24 then
                    bounces[#bounces + 1] = { pos = vector(ep.x, ep.y, ep.z), n = vector(n.x, n.y, n.z) }
                end
                local d = (vx * n.x + vy * n.y + vz * n.z) * 2
                vx, vy, vz = vx - n.x * d, vy - n.y * d, vz - n.z * d
                if abs(vx) < 0.1 then
                    vx = 0
                end
                if abs(vy) < 0.1 then
                    vy = 0
                end
                if abs(vz) < 0.1 then
                    vz = 0
                end
                vx, vy, vz = vx * 0.45, vy * 0.45, vz * 0.45
                local sq = vx * vx + vy * vy + vz * vz
                if n.z > 0.7 and sq > 96000 then
                    local dn = (vx * n.x + vy * n.y + vz * n.z) / sqrt(sq)
                    if dn > 0.5 then
                        local k = 1 - dn + 0.5
                        vx, vy, vz = vx * k, vy * k, vz * k
                    end
                end
                if sq < 400 then
                    vx, vy, vz = 0, 0, 0
                end
                local rem = (1 - tr.fraction) * ti
                local t2 = utils.trace_hull(
                    vector(ep.x, ep.y, ep.z),
                    vector(ep.x + vx * rem, ep.y + vy * rem, ep.z + vz * rem),
                    MINS,
                    MAXS,
                    hits,
                    MASK
                )
                nx, ny, nz = t2.end_pos.x, t2.end_pos.y, t2.end_pos.z
            end
            local still = abs(nx - px) + abs(ny - py) + abs(nz - pz) < 0.05 and vx == 0 and vy == 0 and vz == 0
            px, py, pz = nx, ny, nz
            if not still or #path < 2 then
                path[#path + 1] = vector(px, py, pz)
                times[#times + 1] = i * ti
            end
            local t = i * ti
            if i % think == 0 and t >= det then
                if kind == "he" or kind == "flash" or kind == "molly" then
                    break
                end
                if still then
                    break
                end
            end
        end
        local endp = vector(px, py, pz)

        local fire_pos, fire_normal
        if kind == "molly" then
            local down = utils.trace_line(endp + vector(0, 0, landed and 2 or 0), endp - vector(0, 0, 256), hits, MASK)
            if down and not down.start_solid and down.fraction < 1 and down.plane.normal.z > 0.5 then
                fire_pos = vector(down.end_pos.x, down.end_pos.y, down.end_pos.z)
                fire_normal = down.plane.normal
            end
        end
        local len = 0
        for i = 2, #path do
            len = len + path[i]:dist(path[i - 1])
        end

        local pts, last = { path[1] }, path[1]
        for i = 2, #path do
            local q = path[i]
            local keep = i == #path or q:dist(last) >= 10
            if not keep then
                local a, b = q - path[i - 1], path[i + 1] - q
                local l1, l2 = a:length(), b:length()
                keep = l1 > 0.01 and l2 > 0.01 and (a.x * b.x + a.y * b.y + a.z * b.z) < 0.995 * l1 * l2
            end
            if keep then
                pts[#pts + 1] = q
                last = q
            end
        end
        return {
            path = path,
            times = times,
            pts = pts,
            bounces = bounces,
            pos = endp,
            fire_pos = fire_pos,
            fire_normal = fire_normal,
            time = landed and times[#times] or steps * ti,
            len = len,
            kind = kind,
            approx = approx,
            learned = lr ~= nil,
        }
    end

    local function key(L)
        local p, v, g = L.position, L.viewangles, L.grenade or {}

        return string.format(
            "v3 %s %.6f %.2f %.2f %.2f %.3f %.3f %s %s %s %s %s %s %s %s",
            tostring(globals.mapname),
            globals.tickinterval,
            p.x,
            p.y,
            p.z,
            v.x,
            v.y,
            tostring(L.weapon),
            tostring(L.duck),
            tostring(g.strength),
            tostring(g.jump),
            tostring(g.run),
            tostring(g.run_yaw),
            tostring(g.delay),
            tostring(g.run_speed)
        )
    end

    function NadeHelper.get(L)
        if L.position == nil or L.viewangles == nil then
            return false
        end
        local k = key(L)
        local r = NadeHelper.cache[L]
        if r ~= nil and NadeHelper.keys[L] ~= k then
            r = nil
        end
        if r == nil then
            NadeHelper.keys[L] = k
            local ok, res = pcall(NadeHelper.simulate, L, NadeHelper.learned_get(k))
            r = ok and res or false
            NadeHelper.cache[L] = r
        end
        return r
    end

    local function on(p)
        if not p then
            return false
        end
        local sc = NadeHelper.sc
        return abs(p.x) < sc.x * 3 and abs(p.y) < sc.y * 3
    end

    local function stroke(a, b, col, w, alpha, glow)
        local dx, dy = b.x - a.x, b.y - a.y
        local l = sqrt(dx * dx + dy * dy)
        if l < 0.05 then
            return
        end
        local nx, ny = -dy / l, dx / l
        local function rib(width, k)
            local x, y = nx * width * 0.5, ny * width * 0.5
            render.poly(
                c(col, col.a * alpha * k),
                vector(a.x + x, a.y + y),
                vector(b.x + x, b.y + y),
                vector(b.x - x, b.y - y),
                vector(a.x - x, a.y - y)
            )
        end
        if glow > 0 then
            rib(w + 5, 0.07 * glow)
            rib(w + 2.4, 0.18 * glow)
        end
        rib(w, 1)
    end

    function NadeHelper.draw(L, accent, alpha, focus, icon)
        local r = NadeHelper.get(L)
        if not r or #r.path < 2 or alpha <= 0.01 then
            return
        end
        NadeHelper.sc = render.screen_size()
        local path = r.path
        local style = NadeHelper.style
        local base = NadeHelper.best_color(L) or (style.theme and accent or style.color or accent)

        local col = c(base, style.theme and 255 or base.a)
        local a = alpha * (0.55 + 0.45 * focus) * style.opacity

        local pts = r.pts
        local prev = render.world_to_screen(pts[1])
        local travel = 0
        for i = 2, #pts do
            local q = pts[i]
            travel = travel + q:dist(pts[i - 1])
            local p = render.world_to_screen(q)
            if on(p) and on(prev) then
                local fade = min(1, travel / 90)
                stroke(prev, p, col, style.width, a * fade, style.glow * focus)
            end
            prev = p
        end

        local T = max(0.3, r.time)
        local ph = (globals.realtime % (T + 0.6)) / T
        if style.comet and ph <= 1 then
            local want = ph * T
            for i = 2, #path do
                local t0, t1 = r.times[i - 1], r.times[i]
                if t1 >= want then
                    local k = t1 > t0 and (want - t0) / (t1 - t0) or 0
                    local wp = render.world_to_screen(path[i - 1] + (path[i] - path[i - 1]) * k)
                    if on(wp) then
                        render.circle(wp, c(col, col.a * 0.24 * a), 5.5, 0, 1)
                        render.circle(wp, c(col, col.a * a), 2.6, 0, 1)
                    end
                    break
                end
            end
        end
        if r.fire_pos and r.pos:dist(r.fire_pos) > 4 then
            local p, q = render.world_to_screen(r.pos), render.world_to_screen(r.fire_pos)
            if on(p) and on(q) then
                stroke(p, q, col, style.width, a * 0.5, 0)
                render.circle(p, c(col, col.a * a), 3, 0, 1)
                render.circle(q, c(col, col.a * a), 3, 0, 1)
            end
        end

        local endp = r.fire_pos or r.pos
        local txt, heat = nil, 0
        if r.kind == "he" then
            local best, lethal = 0, false

            for _, e in ipairs(entity.get_players(true, true) or {}) do
                if e:is_alive() then
                    local dmg = NadeHelper.he_damage(endp, e)
                    if dmg > best then
                        best, lethal = dmg, dmg >= (e.m_iHealth or 100)
                    end
                end
            end
            if best >= 1 then
                txt = string.format("%d dmg", floor(best))
                heat = min(1, best / 100)
            end
        end

        if r.kind == "molly" and r.fire_pos then
            local zone = NadeHelper.fire_zone()
            local best, bh, bz

            for _, e in ipairs(entity.get_players(true, true) or {}) do
                if e:is_alive() then
                    local o = e:get_origin()
                    local h = sqrt((endp.x - o.x) ^ 2 + (endp.y - o.y) ^ 2)
                    if best == nil or h < bh then
                        best, bh, bz = e, h, abs(endp.z - o.z)
                    end
                end
            end
            if best ~= nil and bh <= zone and bz < 96 then
                txt = string.format("%.1f m", bh / 52.5)
                heat = min(1, bh / zone)
            end
        end
        local sp = txt and render.world_to_screen(vector(endp.x, endp.y, endp.z + 8))
        if on(sp) then
            local font = NadeHelper.font()
            local ts = render.measure_text(font, nil, txt)
            local x, y = floor(sp.x - ts.x * 0.5 + 0.5), floor(sp.y - ts.y - 4 + 0.5)
            local h = NadeHelper.HOT
            local tcol = color(
                floor(255 + (h.r - 255) * heat),
                floor(255 + (h.g - 255) * heat),
                floor(255 + (h.b - 255) * heat),
                floor(col.a * alpha * style.opacity)
            )
            render.text(font, vector(x + 1, y + 1), c(NadeHelper.SHADOW, 150 * alpha * style.opacity), nil, txt)
            render.text(font, vector(x, y), tcol, nil, txt)
        end
    end

    NadeHelper.HOT = color(255, 96, 84, 255)
    function NadeHelper.font()
        if NadeHelper.font_obj == nil then
            local ok, f = pcall(render.load_font, "C:/Windows/Fonts/seguisb.ttf", 14, "a")
            NadeHelper.font_obj = ok and f or 1
        end
        return NadeHelper.font_obj
    end

    function NadeHelper.fire_zone()
        local ok, r = pcall(function()
            return cvar.inferno_max_range:float()
        end)
        return (ok and type(r) == "number" and r > 0 and r or 150) + 16
    end

    function NadeHelper.he_damage(pos, e)
        local o = e:get_origin()
        local dist = sqrt((pos.x - o.x) ^ 2 + (pos.y - o.y) ^ 2 + (pos.z - o.z) ^ 2)
        local d = (dist - 25) / 140
        local dmg = 105 * math.exp(-d * d)
        local armor = e.m_ArmorValue or 0
        if armor > 0 then
            local new = dmg * 0.5
            if (dmg - new) * 0.5 > armor then
                new = dmg - armor / 0.5
            end
            dmg = new
        end
        if dmg < 1 then
            return 0
        end
        local tr = utils.trace_line(vector(pos.x, pos.y, pos.z + 6), vector(o.x, o.y, o.z + 40), hits, MASK)
        if tr and tr.fraction < 1 and tr.entity ~= e then
            return 0
        end
        return dmg
    end

    function NadeHelper.best_score(r, enemies)
        local score = { kills = 0, value = 0, count = 0, targets = {} }
        for _, e in ipairs(enemies) do
            if e:is_alive() then
                local target = { kills = 0, value = 0, count = 0 }
                score.targets[e:get_index()] = target
                if r.kind == "he" then
                    local hp = e.m_iHealth or 100
                    local dmg = NadeHelper.he_damage(r.pos, e)
                    if dmg >= 1 then
                        score.value = score.value + min(hp, dmg)
                        score.count = score.count + 1
                        if dmg >= hp then
                            score.kills = score.kills + 1
                        end
                        target.value, target.count, target.kills = min(hp, dmg), 1, dmg >= hp and 1 or 0
                    end
                elseif r.kind == "molly" and r.fire_pos then
                    local p, o, radius = r.fire_pos, e:get_origin(), NadeHelper.fire_zone()
                    local d = sqrt((p.x - o.x) ^ 2 + (p.y - o.y) ^ 2)
                    if d <= radius and abs(p.z - o.z) < 96 then
                        local tr = utils.trace_line(p + vector(0, 0, 8), o + vector(0, 0, 8), hits, MASK)
                        if tr and not tr.start_solid and tr.fraction == 1 then
                            score.count = score.count + 1
                            score.value = score.value + 1 - d / radius
                            target.value, target.count = 1 - d / radius, 1
                        end
                    end
                end
            end
        end
        return score
    end
    function NadeHelper.release_options()
        local s = NadeHelper.release_settings
        if not s then
            return nil
        end
        return {
            enabled = s.enabled:get(),
            disable_in_air = s.air_ref and s.air_ref:get() or (not s.air_ref and s.disable_in_air),
            he = s.he_ref and s.he_ref:get() or s.hegrenade or 0,
            flash = s.flash_ref and s.flash_ref:get() or s.flashbang or 0,
            molly = s.molly_ref and s.molly_ref:get() * 0.1 or s.molotov or 0,
        }
    end
    local RELEASE_KIND = { [43] = "Flash", [44] = "Frag", [46] = "Molly", [48] = "Molly" }
    function NadeHelper.release_prediction(e)
        local opts = NadeHelper.release_options()
        if not opts or not opts.enabled then
            NadeHelper.release_pending = nil
            return
        end
        local lp = entity.get_local_player()
        local weapon = lp and lp:get_player_weapon()
        if not weapon or not lp:is_alive() then
            return
        end
        local index = weapon:get_weapon_index()
        if RELEASE_KIND[index] ~= e.type then
            return
        end
        local valid = e.path and #e.path > 1
        local p = valid and e.path[#e.path]
        NadeHelper.release_pending = {
            tick = globals.tickcount,
            index = index,
            damage = tonumber(e.damage) or 0,
            fatal = e.fatal == true,
            kind = e.type,
            has_path = valid,
            pos = p and vector(p.x, p.y, p.z),
        }
    end
    function NadeHelper.release_run(cmd, helper_active)
        local opts = NadeHelper.release_options()
        local lp = entity.get_local_player()
        local w = lp and lp:get_player_weapon()
        if
            not opts
            or not opts.enabled
            or helper_active
            or not lp
            or not lp:is_alive()
            or not w
            or w.m_fThrowTime == nil
        then
            NadeHelper.release_pin, NadeHelper.release_pending = false, nil
            return false
        end
        local index = w:get_weapon_index()
        local armed = NadeHelper.release_pin and NadeHelper.release_weapon == index

        NadeHelper.release_pin, NadeHelper.release_weapon = w.m_bPinPulled == true, index
        if not RELEASE_KIND[index] then
            return false
        end
        if opts.disable_in_air and (bit.band(lp.m_fFlags, 1) == 0 or cmd.in_jump) then
            return false
        end
        if not armed then
            return false
        end
        if not (cmd.in_attack or cmd.in_attack2) then
            return false
        end
        local n = NadeHelper.release_pending
        if not n then
            return false
        end
        if n.index ~= index then
            return false
        end
        if n.tick ~= globals.tickcount then
            return false
        end
        if not n.has_path then
            return false
        end
        local go = false
        if n.kind == "Frag" and opts.he > 0 then
            go = n.fatal or (opts.he ~= 51 and n.damage >= opts.he)
        elseif n.kind == "Flash" then
            go = opts.flash > 0 and n.damage >= opts.flash
        elseif n.kind == "Molly" and opts.molly > 0 then
            local radius = opts.molly * 52.5
            for _, enemy in ipairs(entity.get_players(true) or {}) do
                if enemy:is_alive() and not enemy:is_dormant() and n.pos:dist(enemy:get_origin()) <= radius then
                    go = true
                    break
                end
            end
        end
        if not go then
            return false
        end

        cmd.in_attack, cmd.in_attack2 = false, false
        return true
    end

    function NadeHelper.better(a, b, kind)
        if b == nil then
            return a.count > 0
        end
        if kind == "he" and a.kills ~= b.kills then
            return a.kills > b.kills
        end
        if kind == "molly" and a.count ~= b.count then
            return a.count > b.count
        end
        return a.value > b.value + 0.01
    end
    function NadeHelper.is_best(L)
        local b = NadeHelper.best
        return NadeHelper.style.best and b ~= nil and b.L == L
    end

    function NadeHelper.stable_best(candidate, incumbent, current, kind)
        if not candidate then
            return nil
        end
        if
            incumbent
            and current
            and current.count > 0
            and candidate.L ~= incumbent.L
            and current.kills == candidate.kills
            and (kind ~= "molly" or current.count == candidate.count)
            and candidate.value - current.value < (kind == "he" and 3 or 0.1)
        then
            current.L, current.kind = incumbent.L, kind
            return current
        end
        return candidate
    end
    function NadeHelper.best_publish(work, kind)
        local old = NadeHelper.best
        NadeHelper.best = NadeHelper.stable_best(work.winner, old, old and work.scores[old.L], kind)
        local targets = {}
        for id, winner in pairs(work.target_winners) do
            local previous = NadeHelper.best_targets and NadeHelper.best_targets[id]
            local scored = previous and work.scores[previous.L]
            local chosen = NadeHelper.stable_best(winner, previous, scored and scored.targets[id], kind)
            chosen.name, chosen.slot = work.target_info[id].name, work.target_info[id].slot
            targets[id] = chosen
        end
        NadeHelper.best_targets = targets
    end
    local TARGET_COLORS = { color(96, 190, 255, 255), color(255, 190, 80, 255), color(205, 140, 255, 255) }
    function NadeHelper.best_color(L)
        if NadeHelper.is_best(L) then
            return color(88, 224, 128, 255)
        end
        if not NadeHelper.style.best then
            return nil
        end
        local slot
        for _, b in pairs(NadeHelper.best_targets or {}) do
            if b.L == L and (not slot or b.slot < slot) then
                slot = b.slot
            end
        end
        if slot then
            local c = TARGET_COLORS[(slot - 1) % #TARGET_COLORS + 1]
            return color(c.r, c.g, c.b, c.a)
        end
    end
    function NadeHelper.best_caption(L)
        if not NadeHelper.style.best then
            return ""
        end
        local names = {}
        for _, b in pairs(NadeHelper.best_targets or {}) do
            if b.L == L then
                names[#names + 1] = { slot = b.slot, text = b.slot .. ": " .. b.name }
            end
        end
        table.sort(names, function(a, b)
            return a.slot < b.slot
        end)
        local out = {}
        for i = 1, min(3, #names) do
            out[#out + 1] = names[i].text
        end
        if #names > 3 then
            out[#out + 1] = "+" .. (#names - 3)
        end
        return #out > 0 and ((NadeHelper.target_icon or "") .. " " .. table.concat(out, " / ")) or ""
    end
    function NadeHelper.best_group(group)
        for _, L in ipairs(group) do
            if NadeHelper.is_best(L) then
                return color(88, 224, 128, 255)
            end
        end
        for _, L in ipairs(group) do
            local c = NadeHelper.best_color(L)
            if c then
                return c
            end
        end
        return nil
    end
    function NadeHelper.best_group_label(group, x, y, alpha)
        if not NadeHelper.style.best then
            return
        end
        local members, names = {}, {}
        for _, L in ipairs(group) do
            members[L] = true
        end
        for _, b in pairs(NadeHelper.best_targets or {}) do
            if members[b.L] then
                names[#names + 1] = { slot = b.slot, text = b.slot .. ": " .. b.name }
            end
        end
        if #names == 0 then
            return
        end
        table.sort(names, function(a, b)
            return a.slot < b.slot
        end)
        local out = {}
        for i = 1, min(3, #names) do
            out[#out + 1] = names[i].text
        end
        if #names > 3 then
            out[#out + 1] = "+" .. (#names - 3)
        end
        local text = (NadeHelper.target_icon or "") .. " " .. table.concat(out, " / ")
        local size, col = render.measure_text(1, nil, text), NadeHelper.best_group(group)
        local p = vector(floor(x - size.x / 2), floor(y + 4))
        render.text(1, p + vector(1, 1), c(NadeHelper.SHADOW, 160 * alpha), nil, text)
        render.text(1, p, c(col, 255 * alpha), nil, text)
    end
    function NadeHelper.best_tick(groups, source, weapon, origin)
        local kind = KIND[weapon]
        if not NadeHelper.style.best or (kind ~= "he" and kind ~= "molly") or not groups or not source then
            NadeHelper.best, NadeHelper.best_work, NadeHelper.best_targets = nil, nil, nil
            return
        end
        local now, work = globals.realtime, NadeHelper.best_work
        if work and (work.source ~= source or work.weapon ~= weapon) then
            work = nil
            NadeHelper.best, NadeHelper.best_targets = nil, nil
        end
        if NadeHelper.best and NadeHelper.best.L.position:dist(origin) > 1500 then
            NadeHelper.best = nil
        end
        for id, b in pairs(NadeHelper.best_targets or {}) do
            if b.L.position:dist(origin) > 1500 then
                NadeHelper.best_targets[id] = nil
            end
        end
        if not work or (not work.queue and now >= work.next_at) then
            local enemies = {}
            for _, e in ipairs(entity.get_players(true, true) or {}) do
                if e:is_alive() then
                    enemies[#enemies + 1] = e
                end
            end
            table.sort(enemies, function(a, b)
                return a:get_index() < b:get_index()
            end)
            local queue, seen = {}, {}

            if #enemies > 0 then
                for _, group in ipairs(groups) do
                    for _, L in ipairs(group) do
                        if
                            not seen[L]
                            and L.weapon == weapon
                            and L.position
                            and L.viewangles
                            and not L.movement
                            and not L.editing
                        then
                            seen[L] = true
                            local d = origin:dist(L.position)
                            if d <= 1500 then
                                local i = #queue + 1
                                while i > 1 and queue[i - 1].distance > d do
                                    i = i - 1
                                end
                                if i <= 32 then
                                    table.insert(queue, i, { L = L, distance = d })
                                    if #queue > 32 then
                                        table.remove(queue)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            work = {
                source = source,
                weapon = weapon,
                queue = queue,
                index = 1,
                enemies = enemies,
                scores = {},
                target_winners = {},
                target_info = {},
            }
            for slot, e in ipairs(enemies) do
                work.target_info[e:get_index()] = { slot = slot, name = (e:get_name() or "Enemy"):gsub("[%c]", "") }
            end
            NadeHelper.best_work = work
            if #enemies == 0 then
                NadeHelper.best, NadeHelper.best_targets = nil, nil
            end
        end
        if not work.queue then
            return
        end

        for _ = 1, 2 do
            local item = work.queue[work.index]
            if not item then
                NadeHelper.best_publish(work, kind)
                work.queue, work.task, work.winner = nil, nil, nil
                work.next_at = now + 0.25
                return
            end
            local L = item.L
            local k, r = key(L), NadeHelper.cache[L]
            if NadeHelper.keys[L] ~= k then
                r = nil
            end
            if r == nil then
                if not work.task then
                    local learned = NadeHelper.learned_get(k)
                    work.task = coroutine.create(function()
                        return NadeHelper.simulate(L, learned, coroutine.yield)
                    end)
                    work.task_key = k
                end
                local ok, result = coroutine.resume(work.task)
                if not ok or coroutine.status(work.task) == "dead" then
                    work.task = nil
                    if work.task_key == key(L) then
                        NadeHelper.keys[L], NadeHelper.cache[L] = work.task_key, ok and result or false
                    end
                end
                return
            end
            work.task = nil
            if r then
                local score = NadeHelper.best_score(r, work.enemies)
                score.L, score.kind = L, kind
                work.scores[L] = score
                if NadeHelper.better(score, work.winner, kind) then
                    work.winner = score
                end
                for id, target in pairs(score.targets) do
                    target.L, target.kind = L, kind
                    if NadeHelper.better(target, work.target_winners[id], kind) then
                        work.target_winners[id] = target
                    end
                end
            end
            work.index = work.index + 1
        end
    end

    NadeHelper.key = key

    function NadeHelper.learned_get(k)
        if NadeHelper.learned == nil then
            local ok, t = pcall(function()
                return db.nhx_learned2
            end)
            NadeHelper.learned = ok and type(t) == "table" and t or {}
        end
        return NadeHelper.learned[k]
    end

    NadeHelper.ring, NadeHelper.ring_i = {}, 0
    function NadeHelper.record()
        local lp = entity.get_local_player()
        if lp == nil or not lp:is_alive() then
            return
        end
        local o, v, vo = lp:get_origin(), lp.m_vecVelocity, lp.m_vecViewOffset
        if o == nil or v == nil then
            return
        end
        NadeHelper.ring_i = NadeHelper.ring_i % 96 + 1
        NadeHelper.ring[NadeHelper.ring_i] = { o.x, o.y, o.z, v.x, v.y, v.z, vo and vo.z or 64.06 }
    end

    NadeHelper.seen = {}
    NadeHelper.CLS = { "CBaseCSGrenadeProjectile", "CSmokeGrenadeProjectile", "CMolotovProjectile", "CDecoyProjectile" }
    function NadeHelper.learn(L, iv, obs, e)
        local f, vel, s = aim(L)

        local rv = vector((iv.x - f.x * vel) / 1.25, (iv.y - f.y * vel) / 1.25, (iv.z - f.z * vel) / 1.25)

        local bd
        for _, r in pairs(NadeHelper.ring) do
            local d = (r[4] - rv.x) ^ 2 + (r[5] - rv.y) ^ 2 + (r[6] - rv.z) ^ 2
            if bd == nil or d < bd then
                bd = d
            end
        end
        if bd == nil then
            return
        end
        local best
        for j = 0, 95 do
            local r = NadeHelper.ring[(NadeHelper.ring_i - 1 - j) % 96 + 1]
            if r and (r[4] - rv.x) ^ 2 + (r[5] - rv.y) ^ 2 + (r[6] - rv.z) ^ 2 <= bd + 1 then
                best = r
                break
            end
        end
        local src = spawn_point(best[1], best[2], best[3], best[7], f, s)

        local shift = 0
        if obs ~= nil then
            local gg = cvf("sv_gravity", 800) * 0.4
            local h2 = iv.x * iv.x + iv.y * iv.y
            if h2 > 1 then
                local tt = ((obs.x - src.x) * iv.x + (obs.y - src.y) * iv.y) / h2
                if tt > 0 and tt < 1 then
                    local fixed = vector(obs.x - iv.x * tt, obs.y - iv.y * tt, obs.z - iv.z * tt + 0.5 * gg * tt * tt)
                    shift = fixed:dist(src)
                    if shift < 48 then
                        src = fixed
                    end
                end
            end
        end
        local k = key(L)
        NadeHelper.learned_get(k)
        local prev = NadeHelper.learned[k]
        NadeHelper.learned[k] = { src.x, src.y, src.z, iv.x, iv.y, iv.z }
        pcall(function()
            db.nhx_learned2 = NadeHelper.learned
        end)
        NadeHelper.cache[L] = nil
        if e ~= nil then
            NadeHelper.track = {
                idx = e:get_index(),
                cls = e:get_classname(),
                L = L,
                t0 = globals.realtime,
                last = obs or e:get_origin(),
                still = 0,
                k = k,
                prev = prev,
            }
        end
    end

    function NadeHelper.verify(T, r)
        local L, k = T.L, T.k
        local cur = k and NadeHelper.learned[k]
        if cur == nil or T.last == nil then
            return
        end
        local function save(entry)
            NadeHelper.learned[k] = entry
            pcall(function()
                db.nhx_learned2 = NadeHelper.learned
            end)
            NadeHelper.cache[L] = nil
        end
        if T.last:dist(r.pos) <= 32 then
            cur[7] = 1
            save(cur)
            return
        end
        local hx, hy = -cur[5], cur[4]
        local hl = sqrt(hx * hx + hy * hy)
        if hl > 0 then
            hx, hy = hx / hl, hy / hl
        end
        local best, berr
        for dz = -3, 3 do
            for dl = -2, 2, 2 do
                if dz ~= 0 or dl ~= 0 then
                    local cand = { cur[1] + hx * dl, cur[2] + hy * dl, cur[3] + dz, cur[4], cur[5], cur[6] }
                    local ok, rr = pcall(NadeHelper.simulate, L, cand)
                    if ok and rr then
                        local e2 = T.last:dist(rr.pos)
                        if berr == nil or e2 < berr then
                            best, berr = cand, e2
                        end
                    end
                end
            end
        end
        if berr ~= nil and berr <= 32 then
            best[7] = 1
            save(best)
        elseif T.prev ~= nil and T.prev[7] == 1 then
            save(T.prev)
        end
    end

    function NadeHelper.follow()
        local track = NadeHelper.track
        if track == nil then
            return
        end
        local grenade = entity.get(track.idx)
        local alive = grenade ~= nil and grenade:get_classname() == track.cls
        if alive then
            local origin = grenade:get_origin()
            if origin:dist(track.last) < 0.1 then
                track.still = track.still + globals.frametime
            else
                track.still = 0
            end
            track.last = vector(origin.x, origin.y, origin.z)
        end
        if alive and track.still < 0.6 and globals.realtime - track.t0 < 20 then
            return
        end
        NadeHelper.track = nil
        local prediction = NadeHelper.get(track.L)
        if prediction then
            pcall(NadeHelper.verify, track, prediction)
        end
    end

    function NadeHelper.scan()
        local lp = entity.get_local_player()
        if lp == nil then
            return
        end
        local L = NadeHelper.exec
        local fresh = L ~= nil and globals.realtime - (NadeHelper.exec_t or 0) < 3
        for _, cls in ipairs(NadeHelper.CLS) do
            for _, e in ipairs(entity.get_entities(cls) or {}) do
                local iv = e.m_vInitialVelocity
                if iv and (iv.x ~= 0 or iv.y ~= 0 or iv.z ~= 0) then
                    local k = e:get_index() .. string.format(":%.1f:%.1f:%.1f", iv.x, iv.y, iv.z)
                    if not NadeHelper.seen[k] then
                        NadeHelper.seen[k] = true
                        local th = e.m_hThrower
                        if fresh and th ~= nil and th:get_index() == lp:get_index() then
                            NadeHelper.exec = nil
                            local o = e:get_origin()
                            NadeHelper.learn(L, iv, (e.m_nBounces or 0) == 0 and vector(o.x, o.y, o.z) or nil, e)
                        end
                    end
                end
            end
        end
        NadeHelper.follow()
    end
    events.createmove:set(function()
        pcall(NadeHelper.record)
    end)
    events.render:set(function()
        pcall(NadeHelper.scan)
    end)

    events.level_init:set(function()
        NadeHelper.cache = setmetatable({}, { __mode = "k" })
        NadeHelper.keys = setmetatable({}, { __mode = "k" })
        NadeHelper.seen, NadeHelper.ring, NadeHelper.ring_i = {}, {}, 0
        NadeHelper.track, NadeHelper.exec, NadeHelper.kept = nil, nil, nil
        NadeHelper.best, NadeHelper.best_work, NadeHelper.best_targets = nil, nil, nil
        NadeHelper.release_pending, NadeHelper.release_pin, NadeHelper.release_weapon = nil, false, nil
    end)

    NadeHelper.PACKS = {
        "xannyx",
        "lunni",
        "teddy",
        "adolesense",
        "uitex",
        "brandon",
        "kitty",
        "fencai",
        "farlig",
        "kryiz",
        "rxd",
        "amor",
        "aok",
    }
    NadeHelper.PACK_DIR = "nl\\scripts\\grenade helper\\packs\\"
    NadeHelper.pack_cache = {}
    function NadeHelper.pack_data(name)
        local c = NadeHelper.pack_cache[name]
        if c == nil then
            local okr, raw = pcall(files.read, NadeHelper.PACK_DIR .. name .. ".json")
            local ok, d = false, nil
            if okr and type(raw) == "string" and #raw > 0 then
                ok, d = pcall(json.parse, raw)
            end
            c = ok and type(d) == "table" and d or false
            NadeHelper.pack_cache[name] = c
        end
        return c
    end

    function NadeHelper.packs_merge(db0)
        local locs, act = db0.locations, db0.active_locations
        if #locs < 3 and not db0.defaults_done then
            return
        end
        local pa, pr = db0.pack_active or {}, db0.pack_removed or {}
        db0.pack_active, db0.pack_removed, db0.nhx_merged = pa, pr, true
        for _, name in ipairs(NadeHelper.PACKS) do
            if not pr[name] then
                local d = NadeHelper.pack_data(name)
                if d then
                    locs[#locs + 1] = { name = name, locations = d, nhx_pack = true }
                    act[#locs] = pa[name] or false
                end
            end
        end
    end

    function NadeHelper.packs_strip(db0)
        if not db0.nhx_merged then
            return db0
        end
        local out = {}
        for k, v in pairs(db0) do
            out[k] = v
        end
        out.nhx_merged = nil
        local locs, act = db0.locations or {}, db0.active_locations or {}
        local nl, na, pa, pr, seen = {}, {}, {}, {}, {}
        for k, v in pairs(db0.pack_active or {}) do
            pa[k] = v
        end
        for k, v in pairs(db0.pack_removed or {}) do
            pr[k] = v
        end
        for i = 1, table.maxn(locs) do
            local L = locs[i]
            if L ~= nil then
                if L.nhx_pack then
                    seen[L.name] = true
                    pa[L.name] = act[i] or false
                else
                    nl[#nl + 1] = L
                    na[#nl] = act[i]
                end
            end
        end
        for _, name in ipairs(NadeHelper.PACKS) do
            if not seen[name] and not pr[name] and NadeHelper.pack_data(name) then
                pr[name] = true
            end
        end
        out.locations, out.active_locations, out.pack_active, out.pack_removed = nl, na, pa, pr
        return out
    end
end

local camera_angles, measure_text, rect_outline, rect, texture, text, sub, gsub, format, find, lower, char, abs, floor, _tostring, _next, _type, _pcall, _select, _unpack, execute_after, console_exec, remove, concat, sort, get_local_player, pack, unpack2, parse, stringify, get, _events, _globals, _vector, u71, clone, angles, length2d, to_screen, dist2d, u78, normalized, u81, _color, lerp, to_hex, find2, set, u91, get_override, u94, v95, u96, u97, clipboard, u100, u101, u102, u103, u104, u105, u106, u107, u113, copy_table, u115, u116, load_database, save_database, menu, get_held_weapon, map_changed, cloud_updated, current_map, current_map_pattern, weapon_locations, nearby_locations, t35, downloaded_sources, cloud_sources, locations_by_weapon, rebuild_locations, editing_sources, editor_state, selected_lineup, focused_location_group, selection_alpha, lineup_execution, handle_lineup_command, grenade_release, t57, t58, t59

do
    local push_clip_rect, pop_clip_rect, circle_outline, circle, upper, byte, sin, cos, atan2, min, max, normalize_yaw, _setmetatable, band, add_notify, post, s1, u213, u228, u232, u238

    do
        local camera_position = render.camera_position

        camera_angles = render.camera_angles
        measure_text = render.measure_text
        rect_outline = render.rect_outline
        rect = render.rect
        texture = render.texture
        push_clip_rect = render.push_clip_rect
        pop_clip_rect = render.pop_clip_rect
        circle_outline = render.circle_outline
        circle = render.circle
        text = render.text
        sub = string.sub
        gsub = string.gsub
        format = string.format
        find = string.find
        lower = string.lower
        upper = string.upper
        byte = string.byte
        char = string.char

        local gmatch, clamp, bor, trace_line

        do
            local get_map_data, get2

            do
                local pi, v126

                do
                    local get_timestamp

                    do
                        local bnot, bxor, rshift

                        do
                            local rep = string.rep

                            gmatch = string.gmatch
                            sin = math.sin
                            cos = math.cos

                            local pow = math.pow

                            atan2 = math.atan2
                            abs = math.abs
                            min = math.min
                            max = math.max
                            floor = math.floor
                            clamp = math.clamp
                            normalize_yaw = math.normalize_yaw
                            pi = math.pi
                            _tostring = tostring

                            do
                                local _ = tonumber
                            end

                            _next = next
                            _type = type
                            _pcall = pcall

                            local _error = error

                            _select = select
                            _unpack = unpack
                            _setmetatable = setmetatable
                            band = bit.band
                            bnot = bit.bnot
                            bxor = bit.bxor
                            rshift = bit.rshift

                            local lshift = bit.lshift

                            bor = bit.bor
                            get_map_data = common.get_map_data
                            add_notify = common.add_notify
                            get_timestamp = common.get_timestamp
                            execute_after = utils.execute_after
                            console_exec = utils.console_exec
                            trace_line = utils.trace_line
                            remove = table.remove
                            concat = table.concat
                            sort = table.sort
                            get2 = entity.get
                            get_local_player = entity.get_local_player
                            pack = msgpack.pack
                            unpack2 = msgpack.unpack
                            parse = json.parse
                            stringify = json.stringify
                            get = network.get
                            post = network.post

                            _events = events
                            _globals = globals
                            _vector = vector
                            u71 = _vector()
                            clone = u71.clone
                            angles = u71.angles
                            length2d = u71.length2d
                            to_screen = u71.to_screen

                            do
                                local dist = u71.dist

                                dist2d = u71.dist2d
                                u78 = dist
                            end

                            do
                                local normalize = u71.normalize

                                normalized = u71.normalized
                                u81 = normalize
                            end

                            _color = color

                            do
                                local v83 = _color()

                                lerp = v83.lerp
                                to_hex = v83.to_hex

                                local _ = v83.alpha_modulate
                            end

                            find2 = ui.find

                            local v88 = find2("Aimbot", "Ragebot", "Main", "Enabled")
                            local get3 = v88.get

                            set = v88.set
                            u91 = get3

                            local override = v88.override

                            get_override = v88.get_override
                            u94 = override
                            v95 = common.get_username()
                            u96 = render.screen_size()
                            u97 = u96 * 0.5
                            s1 = "0ucHJINGekQRUwZWVbPXyYlshz65DfLnpxTtKiFvor4ad9A7M3mSBCE21gjO8q+/="
                            clipboard = require("neverlose/clipboard")
                            u100 = (function()
                                local function v360(p1, p2, p3)
                                    return band(rshift(p1, p2), lshift(1, p3) - 1)
                                end
                                local function v361(p4)
                                    local t1 = {}
                                    local t2 = {}

                                    for i = 1, 65 do
                                        local v1221 = byte(sub(p4, i, i)) or 32

                                        if t2[v1221] ~= nil then
                                            _error("invalid alphabet: duplicate character " .. _tostring(v1221), 3)
                                        end

                                        t1[i - 1] = v1221
                                        t2[v1221] = i - 1
                                    end

                                    return t1, t2
                                end

                                local t3 = {}
                                local t4 = {}
                                local v364, v365 =
                                    v361("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")

                                t4.base64 = v365
                                t3.base64 = v364

                                local t5 = {
                                    __index = function(p5, p6)
                                        local v1224 = #p6

                                        if v1224 ~= 64 and v1224 ~= 65 then
                                            return
                                        end

                                        local v1225 = t3
                                        local v1226 = t4
                                        local v1227, v1228 = v361(p6)

                                        v1226[p6] = v1228
                                        v1225[p6] = v1227

                                        return p5[p6]
                                    end,
                                }

                                _setmetatable(t3, t5)
                                _setmetatable(t4, t5)

                                return {
                                    encode = function(p7, p8)
                                        local v1231 = t3[p8 or "base64"] or _error("invalid alphabet specified", 2)
                                        local t6 = {}
                                        local n1 = 1
                                        local v1234 = #p7
                                        local v1235 = v1234 % 3

                                        for i = 1, v1234 - v1235, 3 do
                                            local v1237, v1238, v1239 = byte(p7, i, i + 2)
                                            local v1240 = v1237 * 65536 + v1238 * 256 + v1239

                                            t6[n1] = char(
                                                v1231[v360(v1240, 18, 6)],
                                                v1231[v360(v1240, 12, 6)],
                                                v1231[v360(v1240, 6, 6)],
                                                v1231[v360(v1240, 0, 6)]
                                            )
                                            n1 = n1 + 1
                                        end

                                        if v1235 ~= 2 then
                                            if v1235 == 1 then
                                                local v1241 = byte(p7, v1234) * 65536

                                                t6[n1] = char(
                                                    v1231[v360(v1241, 18, 6)],
                                                    v1231[v360(v1241, 12, 6)],
                                                    v1231[64],
                                                    v1231[64]
                                                )
                                            end
                                        else
                                            local v1242, v1243 = byte(p7, v1234 - 1, v1234)
                                            local v1244 = v1242 * 65536 + v1243 * 256

                                            t6[n1] = char(
                                                v1231[v360(v1244, 18, 6)],
                                                v1231[v360(v1244, 12, 6)],
                                                v1231[v360(v1244, 6, 6)],
                                                v1231[64]
                                            )
                                        end

                                        return concat(t6)
                                    end,
                                    decode = function(p9, p10, _)
                                        local v1248 = t4[p10 or "base64"] or _error("invalid alphabet specified", 2)
                                        local s2 = "[^%w%+%/%=]"

                                        if v1248 then
                                            local v1250 = nil
                                            local v1251 = nil

                                            for v1252, v1253 in _next, v1248 do
                                                if v1253 ~= 62 then
                                                    if v1253 == 63 then
                                                        v1251 = v1252
                                                    end
                                                else
                                                    v1250 = v1252
                                                end
                                            end

                                            s2 = format("[^%%w%%%s%%%s%%=]", char(v1250), char(v1251))
                                        end

                                        local v1254 = gsub(p9, s2, "")
                                        local t7 = {}
                                        local n2 = 1
                                        local v1257 = #v1254
                                        local v1258 = sub(v1254, -2) == "==" and 2 or (sub(v1254, -1) == "=" and 1 or 0)

                                        for i = 1, v1258 > 0 and v1257 - 4 or v1257, 4 do
                                            local v1260, v1261, v1262, v1263 = byte(v1254, i, i + 3)
                                            local v1264 = v1248[v1260] * 262144
                                                + v1248[v1261] * 4096
                                                + v1248[v1262] * 64
                                                + v1248[v1263]

                                            t7[n2] = char(v360(v1264, 16, 8), v360(v1264, 8, 8), v360(v1264, 0, 8))
                                            n2 = n2 + 1
                                        end

                                        if v1258 ~= 1 then
                                            if v1258 == 2 then
                                                local v1265, v1266 = byte(v1254, v1257 - 3, v1257 - 2)
                                                local v1267 = v1248[v1265] * 262144 + v1248[v1266] * 4096

                                                t7[n2] = char(v360(v1267, 16, 8))
                                            end
                                        else
                                            local v1268, v1269, v1270 = byte(v1254, v1257 - 3, v1257 - 1)
                                            local v1271 = v1248[v1268] * 262144
                                                + v1248[v1269] * 4096
                                                + v1248[v1270] * 64

                                            t7[n2] = char(v360(v1271, 16, 8), v360(v1271, 8, 8))
                                        end

                                        return concat(t7)
                                    end,
                                }
                            end)()
                            u101 = (function()
                                local t8 = {
                                    [1] = 221,
                                    [2] = 221,
                                    [3] = 221,
                                }
                                local t9 = {
                                    [1] = 180,
                                    [2] = 230,
                                    [3] = 30,
                                }
                                local t10 = {
                                    [1] = 96,
                                    [2] = 160,
                                    [3] = 220,
                                }
                                local t11 = {
                                    [1] = 218,
                                    [2] = 230,
                                    [3] = 30,
                                }

                                local function v371(p12, p13, p14, p15, p16)
                                    local v1295 = p13 or t8
                                    local v1296 = p15 or t9
                                    local v1297 = p16 or t10

                                    if not p14 then
                                        p14 = t11
                                    end

                                    local v1298 = _tostring(p12)
                                    local t12 = {}
                                    local v1300 = nil
                                    local v1301 = nil
                                    local v1302 = v1295
                                    local t13 = {}

                                    for i = 1, #v1298 do
                                        local v1305 = sub(v1298, i, i)
                                        local v1306 = nil

                                        if v1301 or v1305 ~= "{" and v1305 ~= "[" then
                                            if v1301 or v1305 ~= "}" and v1305 ~= "]" then
                                                if v1301 or v1305 ~= "," and v1305 ~= ":" then
                                                    if v1305 ~= '"' or v1300 == "\\" then
                                                        if v1302 ~= p14 then
                                                            if
                                                                v1302 == v1295
                                                                and v1305 ~= " "
                                                                and v1305 ~= "\n"
                                                                and v1305 ~= "\t"
                                                            then
                                                                v1306 = v1301 and v1296 or v1297
                                                            end
                                                        else
                                                            v1306 = v1301 and v1296 or v1297
                                                        end
                                                    else
                                                        v1301 = not v1301 or nil
                                                        v1306 = p14
                                                    end

                                                    t13[#t13 + 1] = v1305
                                                else
                                                    v1306 = v1295
                                                    t13[#t13 + 1] = v1305
                                                end
                                            else
                                                v1306 = v1295

                                                if v1300 ~= "{" and v1300 ~= "[" then
                                                    t13[#t13 + 1] = v1305
                                                else
                                                    t13[#t13 + 1] = v1305
                                                end
                                            end
                                        else
                                            v1306 = v1295
                                            t13[#t13 + 1] = v1305
                                        end

                                        if v1306 ~= nil and v1306 ~= v1302 then
                                            local t14 = { remove(t13, #t13) }

                                            t12[#t12 + 1] = {
                                                v1302[1],
                                                v1302[2],
                                                v1302[3],
                                                concat(t13),
                                            }
                                            t13 = t14
                                            v1302 = v1306
                                        end

                                        v1300 = v1305
                                    end

                                    if #t13 > 0 then
                                        t12[#t12 + 1] = {
                                            v1302[1],
                                            v1302[2],
                                            v1302[3],
                                            concat(t13),
                                        }
                                    end

                                    return t12
                                end

                                return {
                                    format = function(p17, p18, p19, p20)
                                        local v1276 = _tostring(p17)
                                        local v1277 = _tostring(p18 or "\n")
                                        local v1278 = _tostring(p19 or "\t")
                                        local v1279 = _tostring(p20 or " ")
                                        local n3 = 1
                                        local n4 = 0
                                        local n5 = 0
                                        local v1283 = #v1276
                                        local t15 = {}
                                        local v1285 = nil
                                        local v1286 = nil
                                        local v1287 = sub(v1279, -1) == "\n"

                                        for i = 1, v1283 do
                                            local v1289 = sub(v1276, i, i)

                                            if v1286 or v1289 ~= "{" and v1289 ~= "[" then
                                                if v1286 or v1289 ~= "}" and v1289 ~= "]" then
                                                    if v1286 or v1289 ~= "," then
                                                        if v1286 or v1289 ~= ":" then
                                                            if v1289 == '"' and v1285 ~= "\\" then
                                                                v1286 = not v1286 or nil
                                                            end

                                                            if n4 ~= n5 then
                                                                t15[n3] = rep(v1278, n4)
                                                                n5 = n4
                                                                n3 = n3 + 1
                                                            end

                                                            t15[n3] = v1289
                                                        else
                                                            t15[n3] = v1289 .. v1279

                                                            if v1287 then
                                                                n3 = n3 + 1
                                                                t15[n3] = rep(v1278, n4)
                                                            end
                                                        end
                                                    else
                                                        t15[n3] = v1289 .. v1277
                                                        n5 = -1
                                                    end
                                                else
                                                    n4 = n4 - 1

                                                    if v1285 ~= "{" and v1285 ~= "[" then
                                                        t15[n3] = v1277 .. rep(v1278, n4) .. v1289
                                                    else
                                                        n3 = n3 - 1
                                                        t15[n3] = rep(v1278, n4) .. v1285 .. v1289
                                                    end
                                                end
                                            else
                                                t15[n3] = v1285 == ":" and v1289 .. v1277
                                                    or rep(v1278, n4) .. v1289 .. v1277
                                                n4 = n4 + 1
                                            end

                                            n3 = n3 + 1
                                            v1285 = v1289
                                        end

                                        return concat(t15)
                                    end,
                                    highlight = v371,
                                }
                            end)()

                            function u102(p26, p27, p28, p29)
                                local v376 = p26 / p29 * 2

                                if not (v376 < 1) then
                                    return -p28 * 0.5 * ((v376 - 1) * (v376 - 3) - 1) + p27
                                end

                                return p28 * 0.5 * pow(v376, 2) + p27
                            end
                            function u103(p30, p31, p32, p33)
                                local v381 = p30 / p33 - 1

                                return -p32 * (pow(v381, 4) - 1) + p31
                            end
                            function u104(p34, p35, p36, p37)
                                return -p36 * 0.5 * (cos(pi * p34 / p37) - 1) + p35
                            end
                            function u105(p38, p39, p40, p41)
                                local v390 = p38 / p41

                                return p40 * pow(v390, 3) + p39
                            end
                            function u106(p42, p43, p44, p45)
                                return p44 * sin(p42 / p45 * (pi * 0.5)) + p43
                            end
                            function u107(p46, p47, p48, p49)
                                if p46 ~= 0 then
                                    return p48 * pow(2, 10 * (p46 / p49 - 1)) + p47 - p48 * 0.001
                                end

                                return p47
                            end
                        end

                        local t17 = {}

                        for i = 1, 256 do
                            local v110 = i - 1

                            for _ = 1, 8 do
                                local v112 = -band(v110, 1)

                                v110 = bxor(rshift(v110, 1), band(3988292384, v112))
                            end

                            t17[i] = v110
                        end

                        function u113(p50)
                            local n6 = 4294967295

                            for i = 1, #p50 do
                                local v402 = byte(p50, i)

                                n6 = bxor(rshift(n6, 8), t17[band(bxor(n6, v402), 255) + 1])
                            end

                            return band(bnot(n6), 4294967295)
                        end
                    end

                    function copy_table(p51)
                        if _type(p51) == "table" then
                            local t18 = {}

                            for v405, v406 in _next, p51 do
                                t18[v405] = copy_table(v406)
                            end

                            return t18
                        end

                        return p51
                    end
                    function u115(p52, p53)
                        local t19 = {}

                        for v410, v411 in _next, p52 do
                            local v412, v413 = p53(v410, v411)

                            t19[v412] = v413
                        end

                        return t19
                    end
                    function u116(p54, p55, p56)
                        if p55 == nil then
                            p55 = {}
                            p56 = ""
                        end

                        for v417, v418 in _next, p54 do
                            local v419 = p56 .. v417

                            if _type(v418) ~= "table" or #v418 ~= 0 then
                                p55[v419] = v418
                            else
                                u116(v418, p55, v419 .. ".")
                            end
                        end

                        return p55
                    end

                    local decode = u100.decode
                    local encode = u100.encode
                    local read = files.read
                    local write = files.write

                    files.create_folder("nl\\scripts\\grenade helper")

                    local s3 = "nl\\scripts\\grenade helper\\database.msg"

                    function load_database()
                        local v420 = read(s3)
                        local _, v422 = _pcall(decode, v420, s1)
                        local v423, v424 = _pcall(unpack2, v422)

                        if not v423 or _type(v424) ~= "table" then
                            v424 = {}
                        end

                        v424.locations = v424.locations or {}
                        v424.active_locations = v424.active_locations
                            or {
                                [1] = true,
                                [2] = true,
                                [3] = true,
                            }
                        v424.cloud_active_locations = v424.cloud_active_locations or {}
                        v424.map_patterns = v424.map_patterns or {}

                        pcall(NadeHelper.packs_merge, v424)

                        return v424
                    end
                    function save_database(p57)
                        if _type(p57) == "table" then
                            local okp, stripped = pcall(NadeHelper.packs_strip, p57)

                            if okp then
                                p57 = stripped
                            end

                            local v426 = pack(p57)
                            local v427 = encode(v426, s1)

                            write(s3, v427)

                            if NadeHelper.active_ref ~= nil then
                                pcall(function()
                                    local fresh = load_database().active_locations
                                    local ref = NadeHelper.active_ref

                                    for k in pairs(ref) do
                                        ref[k] = nil
                                    end

                                    for k, v in pairs(fresh) do
                                        ref[k] = v
                                    end
                                end)
                            end

                            return
                        end
                    end

                    menu = {}

                    local OpenExternalBrowserURL = panorama.SteamOverlayAPI.OpenExternalBrowserURL

                    function v126(p58)
                        return function()
                            OpenExternalBrowserURL(p58)
                        end
                    end

                    local v127 = ui.create("\a{Link Active}\239\128\135", "\n main", 1)

                    v127:label("\a{Link Active}\239\128\135\aDEFAULT   " .. v95)
                    v127:label(
                        "\a{Link Active}\239\132\166\aDEFAULT   2.1 \a{Link Active} "
                            .. (stable_build and "Beta" or "Stable")
                    )

                    if not stable_build then
                        v127:button(
                            "\a{Link Active}\239\140\182\aDEFAULT  Beta Version",
                            v126("https://neverlose.cc/market/item?id=FL1YSP"),
                            true
                        )
                    end

                    local v128 = ui.create("\a{Link Active}\239\128\135", "\n discord", 1)

                    v128:button(
                        "\a{Link Active}\239\142\146\aDEFAULT Discord",
                        v126("https://discord.gg/uM2uSEJzQJ"),
                        true
                    )

                    local function v129(p59)
                        if p59 ~= nil and #p59 ~= 0 then
                            clipboard.set(p59)

                            return
                        end
                    end

                    v128:button("\a{Link Active}\239\131\129\aDEFAULT Get Verification Code", function()
                        local v430 = stable_build and "grenade-helper-beta" or "grenade-helper"
                        local v431 = _tostring(floor(abs(u113(v95) + get_timestamp())))
                        local v432 = v95 .. ":" .. v430 .. ":" .. v431
                        local v433 = u100.encode(v432, s1)

                        get("https://northon.dev/neverlose/discord/get_verification_code.php?data=" .. v433, nil, v129)
                    end, true)
                end

                local u130 = ui.create("\a{Link Active}\239\128\135", "best world editor ~ remaper", 1)

                u130:button(
                    "\239\149\189 Best World Edtior ~ Remaper",
                    v126("https://neverlose.cc/market/item?id=a67tQs")
                )

                local t21, t22, t23, u142, t25, t26, v148, t27

                do
                    local v131 = ui.create("\a{Link Active}\239\128\147", "\n settings", 1)

                    t21 = {
                        hotkey = v131:hotkey("\a{Link Active}\238\150\162\aDEFAULT  Hotkey"),
                    }

                    local v133 = v131:combo("\a{Link Active}\239\129\155\aDEFAULT   Aimbot", "Off", "Legit", "Rage")
                        :set_callback(function(p60)
                            t21.aimbot = u91(p60)
                        end, true)
                    local v134 = v133:create()
                    local v135 = v134
                        :slider("\a{Link Active}\239\131\154\aDEFAULT  Field Of View", 40, 180, 100, 1, "°")
                        :set_callback(function(p61)
                            t21.fov = u91(p61)
                        end, true)
                    local v136 = v134:slider("\a{Link Active}\239\131\154\aDEFAULT  Smooth", 1, 100, 50, 1, "%")
                        :set_callback(function(p62)
                            t21.smooth = u91(p62) * 0.1
                        end, true)

                    v133:set_callback(function(p63)
                        local v438 = u91(p63)

                        v135:visibility(v438 ~= "Off")
                        v136:visibility(v438 == "Legit")
                    end, true)
                    v131:selectable(
                        "\a{Link Active}\239\130\133\aDEFAULT  Options",
                        "\a{Link Active}\238\147\162\aDEFAULT   Automatic Throw",
                        "\a{Link Active}\239\143\173   Exploit:\aDEFAULT Force Defensive",
                        "\a{Link Active}\238\129\133   Exploit:\aDEFAULT Recovery Teleport"
                    ):set_callback(function(p64)
                        local v440 = t21
                        local v441 = t21
                        local v442 = t21
                        local v443 = u91(p64, 1)
                        local v444 = u91(p64, 2)

                        v442.recovery_teleport = u91(p64, 3)
                        v441.force_defensive = v444
                        v440.automatic_throw = v443
                    end, true)
                    menu.settings = t21

                    local v137 = ui.create("\a{Link Active}\239\128\147", "customization", 1)

                    t22 = {}
                    t22.options = v137:selectable(
                        "\n customization",
                        "\a{Link Active}\239\129\176\aDEFAULT  Show Behind Walls",
                        "\a{Link Active}\239\131\133\aDEFAULT   Hide Duplicates",
                        "\a{Link Active}\238\146\129\aDEFAULT  Hide Icon With Text"
                    ):set_callback(function(p65)
                        local v446 = t22
                        local v447 = t22
                        local v448 = t22
                        local v449 = u91(p65, 1)
                        local v450 = u91(p65, 2)

                        v448.hide_icon_with_text = u91(p65, 3)
                        v447.hide_duplicates = v450
                        v446.show_behind_walls = v449
                    end, true)

                    local v139 = ui.get_style("Link Active")

                    t22.options:color_picker(v139):set_callback(function(p66)
                        local v452 = u91(p66)
                        local v453 = max(40, v452.a) / 255
                        local v454 = t22

                        t22.alpha = v453
                        v454.color = v452
                    end, true)
                    menu.customization = t22

                    do
                        local ok, ic = pcall(ui.get_icon, "bezier-curve")

                        ic = ok and type(ic) == "string" and ic or ""
                        t22.trajectory = v137:switch("\a{Link Active}" .. ic .. "\aDEFAULT  Trajectory", true)
                            :tooltip(
                                "Draws the selected lineup's flight path. For airborne molotovs, the faint drop connects detonation to the expected fire on the ground.\nOpen the gear to customize the trajectory. Run / jump throws are estimates until learned from a real throw."
                            )
                            :set_callback(function(p)
                                NadeHelper.traj = u91(p)
                            end, true)
                        NadeHelper.setup_style(t22.trajectory)
                    end
                    t23 = {
                        enabled = ui.create("\a{Link Active}\239\128\147", "\n grenade release", 1)
                            :switch("\a{Link Active}\239\135\162\aDEFAULT   Grenade Release")
                            :tooltip(
                                "Releases the grenade is there's a possibility of dealing damage to an enemy\n\n\aAFAF62FF"
                                    .. ui.get_icon("triangle-exclamation")
                                    .. "  This feature is a work in progress and may not work as intended"
                            ),
                    }

                    local v141 = t23.enabled:create()

                    t23.enabled:set_callback(function(p67)
                        v141:visibility(u91(p67))
                    end, true)
                    t23.air_ref = v141:switch("\a{Link Active}\239\131\154\aDEFAULT  Disable in Air", true)
                        :set_callback(function(p68)
                            t23.disable_in_air = u91(p68)
                        end, true)
                    t23.he_ref = v141:slider(
                        "\a{Link Active}\239\131\154\aDEFAULT  High Explosive",
                        0,
                        51,
                        50,
                        1,
                        function(p69)
                            if p69 ~= 0 then
                                if p69 ~= 51 then
                                    return p69 .. " dmg"
                                end

                                return "Lethal"
                            end

                            return "Off"
                        end
                    ):set_callback(function(p70)
                        t23.hegrenade = u91(p70)
                    end, true)
                    t23.flash_ref = v141:slider(
                        "\a{Link Active}\239\131\154\aDEFAULT  Flashbang",
                        0,
                        90,
                        60,
                        1,
                        function(p71)
                            if p71 ~= 0 then
                                return p71 .. "%"
                            end

                            return "Off"
                        end
                    ):set_callback(function(p72)
                        t23.flashbang = u91(p72)
                    end, true)
                    t23.molly_ref = v141
                        :slider("\a{Link Active}\239\131\154\aDEFAULT  Molotov", 0, 30, 20, 1, function(p73)
                            if p73 ~= 0 then
                                return p73 * 0.1 .. "m"
                            end

                            return "Off"
                        end)
                        :set_callback(function(p74)
                            t23.molotov = u91(p74) * 0.1
                        end, true)
                    menu.grenade_release = t23
                    u142 = ui.create("\a{Link Active}\239\128\147", "best world editor ~ remaper", 1)
                    u142:button(
                        "\239\149\189 Best World Edtior ~ Remaper",
                        v126("https://neverlose.cc/market/item?id=a67tQs")
                    )
                    ui.create("\a{Link Active}\239\128\147", "best world editor ~ remaper ", 2)
                    get("https://northon.dev/neverlose/remaper/world_editor.jpg", nil, function(p75)
                        if p75 ~= nil and #p75 ~= 0 then
                            local v464 = render.load_image(p75)

                            u130:texture(v464, _vector(480, 270))
                            u142:texture(v464, _vector(280, 175))

                            return
                        end
                    end)

                    local v143 = ui.create("\a{Link Active}\239\128\147", "\n types", 2)
                    local t24 = {
                        [1] = "weapon_smokegrenade",
                        [2] = "weapon_flashbang",
                        [3] = "weapon_decoy",
                        [4] = "weapon_hegrenade",
                        [5] = "weapon_molotov",
                        [6] = "weapon_wallbang",
                        [7] = "weapon_knife",
                    }

                    t25 = {
                        selection = v143:listable(
                            "\n types",
                            "\a{Link Active}\239\157\160\aDEFAULT  Smoke",
                            "\a{Link Active}\239\129\176\aDEFAULT  Flashbang",
                            " \a{Link Active}\239\158\184\aDEFAULT   Decoy",
                            " \a{Link Active}\239\135\162\aDEFAULT  High Explosive",
                            " \a{Link Active}\239\129\173\aDEFAULT   Molotov",
                            "\a{Link Active}\239\155\171\aDEFAULT   Wallbang",
                            "\a{Link Active}\239\156\137\aDEFAULT  Movement"
                        ),
                    }
                    t25.selection:set_callback(function(p76)
                        for i = 1, #t24 do
                            t25[t24[i]] = u91(p76, i)
                        end
                    end, true)
                    menu.types = t25

                    local v146 = ui.create("\a{Link Active}\239\149\176", "\n locations", 1)

                    t26 = {
                        selection = v146:list("\n selection"),
                        enabled = v146:switch("Enabled"),
                        new_source_name = v146:input("\n name"):reset(),
                        create_label = v146:label("Create"),
                        create = v146:button("\a{Link Active}    \239\131\135    ", nil, true):tooltip("Create"),
                        label = v146:label("Edit & Delete"),
                        edit = v146:button("\a{Link Active}   \239\129\132   ", nil, true):tooltip("Edit"),
                        delete = v146:button("\a{Link Active}   \239\135\184   ", nil, true):tooltip("Delete"),
                        delete_confirm = v146:button("\a{Link Active}   \238\138\175   ", nil, true):tooltip("Confirm"),
                        delete_cancel = v146:button("\a{Link Active}   \238\138\174   ", nil, true):tooltip("Cancel"),
                    }

                    function t26.on_visibility()
                        local v467 = u91(t26.selection)
                        local v468 = v467 == #t26.selection:list()

                        t26.enabled:visibility(not v468)
                        t26.new_source_name:visibility(v468)
                        t26.create_label:visibility(v468)
                        t26.create:visibility(v468)
                        t26.delete_confirm:visibility(false)
                        t26.delete_cancel:visibility(false)
                        t26.label:visibility(not v468)
                        t26.edit:visibility(not v468)
                        t26.delete:visibility(not v468)
                    end

                    t26.selection:set_callback(t26.on_visibility, true)
                    t26.delete:set_callback(function()
                        t26.delete_confirm:visibility(true)
                        t26.delete_cancel:visibility(true)
                        t26.delete:visibility(false)
                    end)
                    t26.delete_confirm:set_callback(function()
                        t26.delete_confirm:visibility(false)
                        t26.delete_cancel:visibility(false)
                        t26.delete:visibility(true)
                    end)
                    t26.delete_cancel:set_callback(function()
                        t26.delete_confirm:visibility(false)
                        t26.delete_cancel:visibility(false)
                        t26.delete:visibility(true)
                    end)
                    t26.search = v146:input("\n search"):reset()
                    t26.locations_selection = v146:list("\n locations selection")
                    t26.all_maps = v146:switch("All Maps")
                    t26.clipboard = v146:label("Clipboard")
                    t26.import = v146:button("\a{Link Active}   \239\149\175    ", nil, true):tooltip("Import")
                    t26.export = v146:button("\a{Link Active}    \239\149\174   ", nil, true):tooltip("Export")
                    t26.delete_location_label = v146:label("Delete & Back")
                    t26.back_label = v146:label("Back")
                    t26.delete_location = v146:button("\a{Link Active}    \239\135\184    ", nil, true)
                        :tooltip("Delete")
                    t26.delete_location_confirm = v146:button("\a{Link Active}    \238\138\175    ", nil, true)
                        :tooltip("Confirm")
                    t26.delete_location_cancel = v146:button("\a{Link Active}    \238\138\174    ", nil, true)
                        :tooltip("Cancel")
                    t26.back = v146:button("\a{Link Active}   \239\139\170    ", nil, true):tooltip("Back")
                    t26.edit:set_callback(function()
                        t26.search:reset()
                        t26.edit:visibility(false)
                        t26.back:visibility(true)
                        t26.selection:visibility(false)
                        t26.enabled:visibility(false)
                        t26.delete_confirm:visibility(false)
                        t26.delete_cancel:visibility(false)
                        t26.label:visibility(false)
                        t26.delete:visibility(false)
                        t26.search:visibility(true)
                        t26.locations_selection:visibility(true)
                        t26.all_maps:visibility(true)
                        t26.clipboard:visibility(true)
                        t26.import:visibility(true)
                        t26.export:visibility(true)
                        t26.delete_location_confirm:visibility(false)
                        t26.delete_location_cancel:visibility(false)
                        t26.delete_location_label:visibility(true)
                        t26.back_label:visibility(false)
                        t26.delete_location:visibility(true)
                    end)
                    t26.locations_selection:set_callback(function(p77)
                        local v470 = u91(p77)
                        local v471 = not t26.edit:visibility()

                        t26.delete_location_confirm:visibility(false)
                        t26.delete_location_cancel:visibility(false)
                        t26.delete_location_label:visibility(v470 > 1 and v471)
                        t26.back_label:visibility(v470 == 1 and v471)
                        t26.delete_location:visibility(v470 > 1 and v471)
                    end, true)
                    t26.delete_location:set_callback(function()
                        t26.delete_location_confirm:visibility(true)
                        t26.delete_location_cancel:visibility(true)
                        t26.delete_location:visibility(false)
                    end)
                    t26.delete_location_confirm:set_callback(function()
                        t26.delete_location_confirm:visibility(false)
                        t26.delete_location_cancel:visibility(false)
                        t26.delete_location:visibility(true)
                    end)
                    t26.delete_location_cancel:set_callback(function()
                        t26.delete_location_confirm:visibility(false)
                        t26.delete_location_cancel:visibility(false)
                        t26.delete_location:visibility(true)
                    end)
                    t26.back:set_callback(function()
                        t26.search:reset()
                        t26.label:visibility(true)
                        t26.edit:visibility(true)
                        t26.back:visibility(false)
                        t26.selection:visibility(true)
                        t26.search:visibility(false)
                        t26.locations_selection:visibility(false)
                        t26.all_maps:visibility(false)
                        t26.clipboard:visibility(false)
                        t26.import:visibility(false)
                        t26.export:visibility(false)
                        t26.delete_location_confirm:visibility(false)
                        t26.delete_location_cancel:visibility(false)
                        execute_after(0, t26.back_label.visibility, t26.back_label, false)
                        t26.delete_location_label:visibility(false)
                        t26.delete_location:visibility(false)
                        t26.on_visibility()
                    end, true)
                    menu.locations = t26
                    v148 = ui.create("\a{Link Active}\239\149\176", "\n builder", 2)
                    menu.locations.edit:set_callback(function()
                        v148:visibility(true)
                    end)
                    menu.locations.back:set_callback(function()
                        v148:visibility(false)
                    end, true)
                    t27 = {
                        type = v148:combo("\n type", "Grenade", "Wallbang", "Movement"),
                        name = v148:input("Name"):reset(),
                        description = v148:input("Description"):reset(),
                        jump = v148:switch("Jump"),
                        run = v148:combo("Run", "Disabled", "Forward", "Left", "Right", "Back", "Custom"),
                    }

                    local v150 = t27.run:create()

                    t27.run_custom = v150:slider("Direction", -180, 180, 0)
                    t27.run_duration = v150:slider("Duration", 0, 256, 20)
                    t27.run_walk = v150:switch("Walk (Shift)")
                    t27.run:set_callback(function(p78)
                        local v473 = u91(p78)

                        v150:visibility(v473 ~= "Disabled")
                        t27.run_custom:visibility(v473 == "Custom")
                    end, true)
                    t27.recovery = v148:combo("Recovery", "Disabled", "Forward", "Left", "Right", "Back", "Custom")

                    local v151 = t27.recovery:create()

                    t27.recovery_custom = v151:slider("Direction", -180, 180, 0)
                    t27.recovery_bunnyhop = v151:switch("Bunny Hop")
                    t27.recovery:set_callback(function(p79)
                        local v475 = u91(p79)

                        v151:visibility(v475 ~= "Disabled")
                        t27.recovery_custom:visibility(v475 == "Custom")
                    end, true)
                end

                t27.strength = v148:combo("Strength", "Left", "Left / Right", "Right")
                t27.delay = v148:slider("Delay", 0, 64, 0, 1, function(p80)
                    if p80 ~= 0 then
                        return
                    end

                    return "Off"
                end)

                local v152 = ui.create("\a{Link Active}\239\149\176", "\n buttons", 2)

                menu.locations.edit:set_callback(function()
                    v152:visibility(true)
                end)
                menu.locations.back:set_callback(function()
                    v152:visibility(false)
                end, true)
                t27.record = v152:switch("Record")

                local v153 = v152:label("Set Location & Teleport")

                t27.teleport_label = v152:label("Teleport")
                t27.set_location_teleport_label = v153
                t27.set_location = v152:button("\a{Link Active}   \239\130\173   ", nil, true)
                    :tooltip("Set Position, Angles, Weapon")
                t27.teleport = v152:button("\a{Link Active}   \238\129\133   ", nil, true):tooltip("Teleport")
                t27.export_save = v152:label("Export & Save")
                t27.export = v152:button("\a{Link Active}   \239\149\174   ", nil, true):tooltip("Export")
                t27.save = v152:button("\a{Link Active}   \239\131\135   ", nil, true):tooltip("Save")
                t27.type:set_callback(function(p81)
                    local v478 = u91(p81)
                    local v479 = v478 == "Grenade"

                    local v480 = v478 == "Movement"

                    t27.jump:visibility(v479)
                    t27.run:visibility(v479)
                    t27.recovery:visibility(v479)
                    t27.strength:visibility(v479)
                    t27.delay:visibility(v479)
                    t27.record:visibility(v480)
                    t27.set_location_teleport_label:visibility(not v480)
                    t27.set_location:visibility(not v480)
                    t27.teleport_label:visibility(v480)
                end, true)

                local v154 = ui.create("\a{Link Active}\239\149\176", "\n hotkeys", 2)

                menu.locations.edit:set_callback(function()
                    v154:visibility(true)
                end)
                menu.locations.back:set_callback(function()
                    v154:visibility(false)
                end, true)
                t27.set_location_hotkey = v154:hotkey("Set Location"):tooltip("Set Position, Angles, Weapon")
                t27.teleport_hotkey = v154:hotkey("Teleport"):tooltip("Teleport")
                menu.builder = t27

                local v155 = ui.create("\a{Link Active}\239\149\176", "\n cloud sources", 2)
                local t28 = {}

                menu.locations.edit:set_callback(function()
                    v155:visibility(false)
                end)
                menu.locations.back:set_callback(function()
                    v155:visibility(true)
                end)

                local v157 = not stable_build

                if v157 then
                    v155:button(
                        "Cloud Sources Is Available in Beta Version",
                        v126("https://neverlose.cc/market/item?id=FL1YSP"),
                        false
                    )
                end

                t28.selection = v155:list("\n selection"):disabled(v157)

                if stable_build then
                    t28.enabled = v155:switch("Enabled")
                    t28.selection:set_callback(function(p82)
                        t28.enabled:visibility(not (u91(p82) <= 1))
                    end, true)
                    t28.update_selection = v155:list("\n update selection")
                    t28.upload_selection = v155:list("\n upload selection")
                    t28.update_delete_label = v155:label("Update & Delete")
                    t28.delete_label = v155:label("Delete")
                    t28.update = v155:button("\a{Link Active}   \239\131\174   ", nil, true):tooltip("Update")
                    t28.delete = v155:button("\a{Link Active}   \239\135\184   ", nil, true):tooltip("Delete")
                    t28.delete_confirm = v155:button("\a{Link Active}   \238\138\175   ", nil, true):tooltip("Confirm")
                    t28.delete_cancel = v155:button("\a{Link Active}   \238\138\174   ", nil, true):tooltip("Cancel")
                    t28.upload_label = v155:label("Upload")
                    t28.upload = v155:button("\a{Link Active}   \239\130\147   ", nil, true):tooltip("Upload")
                    t28.upload_text = v155:label(
                        "\a{Link Active}\239\129\177\aDEFAULT You don't have any locations that you can upload to the cloud"
                    )
                end

                t28.market_locations_label = v155:label("Market Locations"):visibility(false)
                t28.market_locations = t28.market_locations_label:create()

                if stable_build then
                    t28.delete:set_callback(function()
                        t28.delete:visibility(false)
                        t28.delete_confirm:visibility(true)
                        t28.delete_cancel:visibility(true)
                    end)
                    t28.delete_confirm:set_callback(function()
                        t28.delete:visibility(true)
                        t28.delete_confirm:visibility(false)
                        t28.delete_cancel:visibility(false)
                    end)
                    t28.delete_cancel:set_callback(function()
                        t28.delete:visibility(true)
                        t28.delete_confirm:visibility(false)
                        t28.delete_cancel:visibility(false)
                    end)
                end

                menu.cloud_sources = t28

                local v158 = ui.create("\a{Link Active}\239\149\176", "\n map patterns", 1)

                menu.locations.edit:set_callback(function()
                    v158:visibility(false)
                end)
                menu.locations.back:set_callback(function()
                    v158:visibility(true)
                end)

                local t29 = {
                    selection = v158:list("\n selection", "Edit Current Map Pattern"),
                    new_map_name = v158:input("\n new map name"):reset(),
                    save_label = v158:label("Save"),
                    current_map_pattern = v158:button("\n map pattern", nil, true):tooltip("Current Map Pattern"),
                    save = v158:button("\a{Link Active}    \239\131\135    ", nil, true):tooltip("Save"),
                    delete_label = v158:label("Delete"),
                    delete = v158:button("\a{Link Active}    \239\135\184    ", nil, true):tooltip("Delete"),
                }

                function t29.on_visibility()
                    local v482 = t29.selection:list()
                    local v483 = u91(t29.selection)

                    if v483 > #v482 then
                        local v484 = #v482

                        if v484 then
                            v483 = v484
                        end
                    end

                    local v485 = v483 == 1

                    t29.new_map_name:visibility(v485)
                    t29.save_label:visibility(v485)
                    t29.save:visibility(v485)
                    t29.current_map_pattern:visibility(v485)
                    t29.delete_label:visibility(not v485)
                    t29.delete:visibility(not v485)
                end

                t29.selection:set_callback(t29.on_visibility)
                menu.map_patterns = t29

                local get_alpha = ui.get_alpha
                local get_style = ui.get_style
                local sidebar = ui.sidebar
                local s4 = " Grenade Helper"
                local v164 = #s4 + 1

                _events.render(function()
                    if get_alpha() ~= 0 then
                        local t30 = {}
                        local v487 = get_style("Link Active")
                        local v488 = v487 * 0.3
                        local v489 = nil

                        for i = 1, v164 do
                            local v491 = (i - 1) / v164
                            local v492 = abs(sin(_globals.realtime % pi + v491 * 2))
                            local v493 = lerp(v488, v487, v492)

                            v493.a = 255

                            local v494 = "\a" .. to_hex(v493)

                            if i ~= 1 then
                                local v495 = sub(s4, i, i)

                                t30[#t30 + 1] = v494 .. v495
                            else
                                v489 = v494
                            end
                        end

                        local v496 = concat(t30)

                        sidebar(v496, v489 .. "\239\135\162")

                        return
                    end
                end)
            end

            local t31 = {
                [38] = "weapon_wallbang",
                [40] = "weapon_wallbang",
                [1] = "weapon_wallbang",
                [44] = "weapon_hegrenade",
                [48] = "weapon_molotov",
                [11] = "weapon_wallbang",
                [46] = "weapon_molotov",
                [64] = "weapon_wallbang",
                [9] = "weapon_wallbang",
                [45] = "weapon_smokegrenade",
                [43] = "weapon_flashbang",
                [47] = "weapon_decoy",
            }

            function get_held_weapon(p83)
                local v500 = p83:get_player_weapon()

                if v500 ~= nil then
                    local v501 = t31[v500:get_weapon_index()]

                    if v501 == nil then
                        return v500, v500:get_weapon_info().weapon_name
                    end

                    return v500, v501
                end
            end

            map_changed = _events["[Grenade Helper] Map Change"]
            cloud_updated = _events["[Grenade Helper] Cloud Updated"]
            current_map = nil
            current_map_pattern = nil

            local map_patterns = menu.map_patterns
            local map_patterns2 = load_database().map_patterns
            local default_map_patterns = {
                ["-692592072"] = "cs_italy",
                ["2041417734"] = "de_cbble",
                ["-768791216"] = "de_dust2",
                ["2056138930"] = "gd_rialto",
                ["-923663825"] = "dz_frostbite",
                ["-1218081885"] = "de_guard",
                ["-1348292803"] = "cs_apollo",
                ["-1411074561"] = "de_tulip",
                ["-1439577949"] = "de_canals",
                ["-1541779215"] = "de_sugarcane",
                ["-1621571143"] = "de_dust",
                ["-1639993233"] = "de_mirage",
                ["1964982021"] = "de_elysion",
                ["1900771637"] = "de_cache",
                ["1850283081"] = "de_anubis",
                ["1722587796"] = "de_dust2_old",
                ["1563115098"] = "de_nuke",
                ["1507960924"] = "cs_agency",
                ["1476824995"] = "de_vertigo",
                ["1463756432"] = "cs_assault",
                ["1445192006"] = "de_engage",
                ["1364328969"] = "cs_militia",
                ["1238495690"] = "ar_dizzy",
                ["-1752602089"] = "de_inferno",
                ["1014664118"] = "cs_office",
                ["-1768287648"] = "dz_blacksite",
                ["899765791"] = "de_safehouse",
                ["-1890957714"] = "ar_shoots",
                ["878725495"] = "de_bank",
                ["-2011174878"] = "de_train",
                ["792319475"] = "de_ancient",
                ["790893427"] = "dz_sirocco",
                ["549370830"] = "de_lake",
                ["405708653"] = "de_overpass",
                ["371013699"] = "de_stmarc",
                ["-182586077"] = "de_aztec",
                ["-222265935"] = "ar_baggage",
                ["-542128589"] = "ar_monastery",
            }
            local map_pattern_lookup = {}

            local function update_map_pattern()
                local v502 = get2(0)

                if v502 ~= nil and v502.m_WorldMins ~= nil and v502.m_WorldMaxs ~= nil then
                    local m_WorldMins = v502.m_WorldMins
                    local m_WorldMaxs = v502.m_WorldMaxs

                    current_map_pattern = format(
                        "bomb_%.2f_%.2f_%.2f %.2f_%.2f_%.2f",
                        m_WorldMins.x,
                        m_WorldMins.y,
                        m_WorldMins.z,
                        m_WorldMaxs.x,
                        m_WorldMaxs.y,
                        m_WorldMaxs.z
                    )
                    current_map_pattern = _tostring(u113(current_map_pattern))
                    map_patterns.current_map_pattern:name("\a{Link Active}" .. current_map_pattern)

                    return
                end

                current_map_pattern = nil
            end

            update_map_pattern()

            local function resolve_map(force)
                local prev = current_map
                local ok, md = pcall(get_map_data)
                if not ok then
                    md = nil
                end

                if _globals.is_in_game then
                    current_map = map_pattern_lookup[current_map_pattern]

                    if current_map == nil then
                        local raw = md and md.shortname
                        if not raw or raw == "" then
                            raw = md and md.name
                        end
                        local short = lower(raw or "")

                        short = short:match("([^/\\]+)$") or short
                        current_map = short ~= "" and short or nil

                        if current_map == "de_shortnuke" then
                            current_map = "de_nuke"
                        end

                        local known = current_map == nil

                        for _, name in _next, default_map_patterns do
                            if name == current_map then
                                known = true

                                break
                            end
                        end

                        if not known then
                            local best

                            for _, name in _next, default_map_patterns do
                                if find(current_map, name, 1, true) and (best == nil or #name > #best) then
                                    best = name
                                end
                            end

                            if best then
                                current_map = best
                            end
                        end
                    end

                    if not force and current_map == prev then
                        return
                    end

                    return map_changed:call()
                end

                current_map = nil

                if not force and prev == nil then
                    return
                end

                return map_changed:call()
            end
            local function refresh_map_patterns(force)
                map_pattern_lookup = {}

                for v505, v506 in _next, default_map_patterns do
                    map_pattern_lookup[v505] = v506
                end

                local t34 = {
                    [1] = "Edit Current Map Pattern",
                }

                for i = 1, #map_patterns2 do
                    local v509 = map_patterns2[i]
                    local map = v509.map
                    local pattern = v509.pattern

                    map_pattern_lookup[pattern] = map
                    t34[#t34 + 1] = format("\a{Link Active}%s:\aDEFAULT %s", map, pattern)
                end

                map_patterns.selection:update(t34)
                map_patterns.on_visibility()
                resolve_map(force)
            end

            refresh_map_patterns(true)

            local function v179(p84, p85)
                return p85.pattern, p84
            end

            map_patterns.save:set_callback(function()
                if current_map_pattern ~= nil then
                    if default_map_patterns[current_map_pattern] == nil then
                        local v514 = u91(map_patterns.new_map_name)
                        local v515 = gsub(v514, " ", "")

                        if _type(v515) == "string" and v515 ~= "" then
                            map_patterns2[u115(map_patterns2, v179)[current_map_pattern] or #map_patterns2 + 1] = {
                                map = v515,
                                pattern = current_map_pattern,
                            }

                            local v516 = load_database()

                            v516.map_patterns = map_patterns2
                            save_database(v516)
                            refresh_map_patterns()

                            return
                        end

                        return
                    end

                    return
                end
            end)
            map_patterns.delete:set_callback(function()
                local v517 = u91(map_patterns.selection) - 1

                if map_patterns2[v517] ~= nil then
                    remove(map_patterns2, v517)

                    local v518 = load_database()

                    v518.map_patterns = map_patterns2
                    save_database(v518)
                    refresh_map_patterns()

                    return
                end
            end)

            local map_monitor = { next_at = 0, retry_at = 0, connected = false }
            local function refresh_map()
                update_map_pattern()
                refresh_map_patterns(true)
            end

            local function map_poll()
                local now = _globals.realtime
                if now < map_monitor.next_at then
                    return
                end
                map_monitor.next_at = now + 0.5
                local previous = current_map
                update_map_pattern()
                resolve_map()
                if not _globals.is_in_game or (current_map == nil and current_map_pattern == nil) then
                    map_monitor.connected = false
                    map_monitor.map, map_monitor.pattern = nil, nil
                    map_monitor.retry_at = 0
                    return
                end
                if
                    not map_monitor.connected
                    or map_monitor.map ~= current_map
                    or map_monitor.pattern ~= current_map_pattern
                then
                    map_monitor.connected = true
                    map_monitor.map, map_monitor.pattern = current_map, current_map_pattern
                    map_monitor.retry_at = now + 4

                    if previous == current_map then
                        map_changed:call()
                    end
                elseif _next(locations_by_weapon) ~= nil then
                    map_monitor.retry_at = now + 8
                elseif current_map ~= nil and now >= map_monitor.retry_at then
                    map_monitor.retry_at = now + 8
                    map_changed:call()
                end
            end
            local function map_reset()
                map_monitor.next_at, map_monitor.retry_at, map_monitor.connected = 0, 0, false
                refresh_map()
            end
            _events.level_init:set(map_reset)
            _events.cs_game_disconnected:set(map_reset)
            _events.net_update_end:set(map_poll)
            _events.render:set(map_poll)

            weapon_locations = nil
            nearby_locations = nil
            t35 = {}
            downloaded_sources = {}
            cloud_sources = {}
            locations_by_weapon = {}

            local function collect_map_locations(p86)
                local list = p86[current_map]
                if type(list) ~= "table" then
                    return
                end
                for _, source in _next, list do
                    if type(source) == "table" and menu.types[source.weapon] then
                        local runtime = copy_table(source)
                        local bucket = locations_by_weapon[runtime.weapon]
                        if bucket == nil then
                            bucket = {}
                            locations_by_weapon[runtime.weapon] = bucket
                        end
                        bucket[#bucket + 1] = runtime
                    end
                end
            end

            function rebuild_locations(p87, p88)
                weapon_locations = nil
                locations_by_weapon = {}
                t35 = {}

                do
                    local types = menu.types
                    local order = {
                        "weapon_smokegrenade",
                        "weapon_flashbang",
                        "weapon_decoy",
                        "weapon_hegrenade",
                        "weapon_molotov",
                        "weapon_wallbang",
                        "weapon_knife",
                    }

                    for i = 1, #order do
                        local ok, on = pcall(function()
                            return types.selection:get(i)
                        end)

                        if ok then
                            types[order[i]] = on
                        end
                    end
                end

                if current_map ~= nil then
                    local v529 = p87 or load_database()
                    local active_locations = v529.active_locations
                    local locations = v529.locations
                    local v532 = p88 ~= nil and p88.source_index

                    for i = 1, #locations do
                        if not active_locations[i] then
                            if v532 == i then
                                local location = p88.location
                                local v535 = copy_table(location.editing)

                                v535.editing = true

                                local t39 = {
                                    [location.map_name] = {
                                        [1] = v535,
                                    },
                                }

                                collect_map_locations(t39)
                            end

                            locations[i] = nil
                        else
                            local locations2 = locations[i].locations

                            if v532 == i then
                                local location = p88.location
                                local map_name = location.map_name
                                local v540 = locations2[map_name]

                                if v540 == nil then
                                    v540 = {}
                                    locations2[map_name] = v540
                                end

                                local v541 = copy_table(location.editing)

                                v541.editing = true

                                local index = location.index

                                if index == 0 then
                                    index = #v540 + 1
                                end

                                v540[index] = v541
                            end

                            collect_map_locations(locations2)
                        end
                    end

                    for _, v544 in _next, cloud_sources do
                        collect_map_locations(v544)
                    end

                    for _, v546 in _next, downloaded_sources do
                        collect_map_locations(v546)
                    end

                    return
                end
            end

            rebuild_locations()

            local function v189()
                cloud_sources = {}
                downloaded_sources = {}
                rebuild_locations()
            end

            map_changed(v189)
            menu.types.selection:set_callback(v189)
            menu.customization.options:set_callback(v189)
        end

        editing_sources = false
        editor_state = nil
        selected_lineup = nil
        focused_location_group = nil
        selection_alpha = nil
        lineup_execution = {}

        local settings = menu.settings
        local customization = menu.customization
        local v198 = find2("Aimbot", "Ragebot", "Main", "Double Tap")
        local v199 = find2("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options")
        local v200 = find2("Aimbot", "Ragebot", "Main", "Double Tap", "Quick-Switch")

        find2("Aimbot", "Ragebot", "Main", "Hide Shots")

        local v201 = find2("Aimbot", "Ragebot", "Main", "Hide Shots", "Options")
        local v202 = find2("Aimbot", "Anti Aim", "Angles", "Extended Angles")
        local v203 = find2("Aimbot", "Anti Aim", "Misc", "Slow Walk")
        local v204 = find2("Aimbot", "Anti Aim", "Misc", "Fake Duck")
        local v205 = find2("Miscellaneous", "Main", "Movement", "Air Duck")
        local v206 = find2("Miscellaneous", "Main", "Movement", "Air Strafe")
        local v207 = find2("Miscellaneous", "Main", "Movement", "Air Strafe", "WASD Strafe")
        local v208 = find2("Miscellaneous", "Main", "Movement", "Air Strafe", "Smoothing")
        local v209 = find2("Miscellaneous", "Main", "Movement", "Quick Stop")
        local v210 = find2("Miscellaneous", "Main", "Movement", "Strafe Assist")
        local v211 = find2("Miscellaneous", "Main", "Movement", "Edge Jump")

        local function v212()
            u94(v200)
            u94(v199)
            u94(v201)
            u94(v202)
            u94(v203)
            u94(v204)
            u94(v205)
            u94(v206)
            u94(v209)
            u94(v207)
            u94(v208)
            u94(v210)
            u94(v211)
        end

        cvar.sensitivity:float()

        function u213(_) end

        local function v214(p90)
            p90.in_back = false
            p90.in_forward = false
            p90.in_moveright = false
            p90.in_moveleft = false
            p90.sidemove = 0
            p90.forwardmove = 0
            p90.in_jump = false
            p90.in_speed = false
            p90.in_duck = false
        end

        local n7 = 1
        local n8 = 2
        local n9 = 3
        local n10 = 4
        local n11 = 5
        local exploit = rage.exploit
        local get4 = exploit.get
        local force_teleport = exploit.force_teleport

        local function u223(p91, p92, p93, p94)
            local location = lineup_execution.location
            local data = lineup_execution.data

            if data == nil then
                data = {}
                lineup_execution.data = data
            end

            if not data.state then
                data.state = n7
            end

            if settings.aimbot ~= "Rage" then
                if data.state ~= n11 then
                    u213(false)

                    local viewangles = location.viewangles

                    camera_angles(viewangles)
                end
            else
                p91.view_angles = location.viewangles
            end

            local grenade = location.grenade
            local v557 = grenade ~= nil and grenade.strength or 1

            if data.state == n7 or data.state == n8 or data.state == n10 then
                if v557 ~= 0 then
                    if v557 ~= 0.5 then
                        p91.in_attack2 = false
                        p91.in_attack = true
                    else
                        p91.in_attack2 = true
                        p91.in_attack = true
                    end
                else
                    p91.in_attack2 = true
                    p91.in_attack = false
                end
            end

            local duck = location.duck

            if data.state ~= n11 then
                if p94 ~= location.weapon then
                    v212()
                    lineup_execution = {}
                end

                v214(p91)
                p91.in_duck = duck
            end

            local m_flDuckAmount = p92.m_flDuckAmount

            if (not duck or m_flDuckAmount == 1) and (duck or m_flDuckAmount == 0) then
                if data.state == n7 and v557 == p93.m_flThrowStrength and p93.m_bPinPulled then
                    data.state = n8
                    data.start_at = p91.command_number
                end

                u94(v200, false)

                if settings.force_defensive then
                    u94(v199, "Always on")
                    u94(v201, "Break LC")
                end

                if data.state == n11 then
                    if data.recovery_yaw == nil then
                        v212()
                        lineup_execution = {}
                    else
                        if not data.recovery_start_at then
                            data.recovery_start_at = p91.command_number
                        end

                        local v560 = p91.in_forward
                            or (p91.in_back or (p91.in_moveleft or (p91.in_moveright or p91.in_jump)))
                        local v561 = grenade ~= nil and grenade.recovery_jump
                        local v562 = min(32, data.run or 16) + 13 + (v561 and 10 or 0)

                        if not (p91.command_number - data.recovery_start_at < 1E-10) or v560 then
                            u94(v206, true)

                            if settings.recovery_teleport and data.teleported == nil and not v560 then
                                force_teleport(exploit)
                                data.teleported = true
                            end
                        end

                        if not v560 then
                            if not (data.recovery_start_at + v562 >= p91.command_number) then
                                v212()
                                lineup_execution = {}
                            else
                                v214(p91)
                                p91.move_yaw = p91.view_angles.y + data.recovery_yaw + data.run_yaw
                                p91.forwardmove = 450

                                if v561 then
                                    p91.in_jump = true
                                end
                            end
                        else
                            v212()
                            lineup_execution = {}
                        end
                    end
                end

                if data.state == n8 or data.state == n9 or data.state == n10 then
                    local v563 = p91.command_number - data.start_at
                    local v564 = grenade ~= nil and grenade.run

                    data.run_yaw = grenade ~= nil and grenade.run_yaw or 0
                    data.run = v564

                    if (not v564 or not (v563 < v564)) and data.state == n8 then
                        data.state = n9
                    end

                    if v564 then
                        if p92.m_MoveType ~= 9 then
                            p91.move_yaw = p91.view_angles.y + data.run_yaw
                            p91.forwardmove = 450
                            p91.in_forward = true
                        elseif data.run_yaw ~= -90 then
                            if data.run_yaw ~= 90 then
                                if data.run_yaw ~= 180 and data.run_yaw ~= -180 then
                                    p91.in_forward = true
                                else
                                    p91.in_back = true
                                end
                            else
                                p91.in_moveleft = true
                            end
                        else
                            p91.in_moveright = true
                        end

                        p91.in_speed = grenade ~= nil and grenade.run_speed and 1 or 0
                    end
                end

                if data.state == n9 then
                    if grenade ~= nil and grenade.jump then
                        p91.in_jump = true
                    end

                    data.state = n10
                    data.throw_at = p91.command_number
                end

                local v565 = grenade ~= nil and grenade.delay or 0
                local v566 = nil

                if data.state == n10 then
                    local v567 = get_override(v198)

                    if v567 == nil then
                        v567 = u91(v198)
                    end

                    if get4(exploit) == 1 and v567 then
                        v565 = v565 + 6
                    end

                    v566 = p91.command_number - data.throw_at

                    if v566 >= v565 - 3 then
                        u94(v200, false)
                        u94(v199, "Disabled")
                        u94(v201, "Favor Fake Lag")
                    end

                    if v565 <= v566 then
                        p91.in_attack2 = false
                        p91.in_attack = false
                        data.recovery_yaw = grenade and (grenade.recovery_yaw and grenade.recovery_yaw)
                            or grenade
                                and ((not not location.grenade.recovery_jump or location.grenade.jump) and 180)
                    end
                end

                if data.state == n10 then
                    if v565 < v566 then
                        data.thrown_at = p91.command_number
                    end

                    if p93.m_fThrowTime == 0 and data.thrown_at and data.thrown_at > data.throw_at then
                        data.state = n11
                    end
                end

                return
            end
        end

        local t41 = {
            in_back = "B",
            in_forward = "F",
            in_moveright = "R",
            in_moveleft = "L",
            in_attack2 = "Z",
            in_attack = "A",
            in_duck = "D",
            in_jump = "J",
            in_speed = "S",
            in_use = "U",
            B = "in_back",
            F = "in_forward",
            R = "in_moveright",
            L = "in_moveleft",
            Z = "in_attack2",
            A = "in_attack",
            D = "in_duck",
            J = "in_jump",
            S = "in_speed",
            U = "in_use",
        }

        local function v225(p95)
            local t42 = {}
            local t43 = {}

            for v571 in gmatch(p95, ".") do
                if v571 ~= lower(v571) then
                    t42[#t42 + 1] = t41[v571] or false
                else
                    t43[#t43 + 1] = t41[upper(v571)] or false
                end
            end

            return t42, t43
        end
        local function u226(p96)
            local location = lineup_execution.location
            local data = lineup_execution.data

            if not data then
                lineup_execution.data = {}
                data = lineup_execution.data
            end

            local frames = data.frames

            if frames == nil then
                data.frames = {}
                frames = data.frames

                local frames2 = location.movement.frames

                for i = 1, #frames2 do
                    local v578 = frames2[i]

                    if _type(v578) ~= "number" then
                        if _type(v578) == "table" then
                            frames[#frames + 1] = v578
                        end
                    elseif v578 > 0 then
                        for _ = 1, v578 do
                            frames[#frames + 1] = {}
                        end
                    end
                end

                local viewangles = location.viewangles
                local t44 = {
                    viewangles = {
                        pitch = viewangles.x,
                        yaw = viewangles.y,
                    },
                    buttons = {},
                }

                for v582, _ in _next, t41 do
                    t44.buttons[v582] = false
                end

                for i = 1, #frames do
                    local v585 = frames[i]
                    local v586, v587, v588, v589, v590 = _unpack(v585)

                    t44.viewangles.pitch = t44.viewangles.pitch + (v586 or 0)
                    t44.viewangles.yaw = t44.viewangles.yaw + (v587 or 0)

                    if _type(v588) == "string" then
                        local v591, v592 = v225(v588)

                        for j = 1, #v591 do
                            local v594 = v591[j]

                            t44.buttons[v594] = true
                        end

                        for j = 1, #v592 do
                            local v596 = v592[j]

                            t44.buttons[v596] = false
                        end
                    end

                    t44.forwardmove = _type(v589) == "number" and (v589 >= -450 and (v589 <= 450 and v589))
                        or (t44.buttons.in_forward and 450 or (t44.buttons.in_back and -450 or 0))
                    t44.sidemove = _type(v590) == "number" and (v590 >= -450 and (v590 <= 450 and v590))
                        or (t44.buttons.in_moveright and 450 or (t44.buttons.in_moveleft and -450 or 0))
                    frames[i] = {
                        pitch = t44.viewangles.pitch,
                        yaw = t44.viewangles.yaw,
                        move_yaw = t44.viewangles.yaw,
                        forwardmove = t44.forwardmove,
                        sidemove = t44.sidemove,
                    }

                    for v597, v598 in _next, t44.buttons do
                        data.frames[i][v597] = v598
                    end
                end
            end

            if not data.start_at then
                data.start_at = p96.command_number
            end

            local v599 = frames[p96.command_number - data.start_at + 1]

            if v599 then
                local v600 = _vector(v599.pitch, v599.yaw, 0)

                if menu.settings.aimbot ~= "Rage" then
                    u213(false)
                    camera_angles(v600)
                else
                    p96.view_angles = v600
                end

                local in_attack = v599.in_attack

                p96.in_attack2 = v599.in_attack2
                p96.in_attack = in_attack
                p96.move_yaw = v599.move_yaw
                p96.forwardmove = v599.forwardmove
                p96.sidemove = v599.sidemove
                p96.in_speed = v599.in_speed
                p96.in_duck = v599.in_duck
                p96.in_use = v599.in_use
                p96.in_jump = v599.in_jump

                return
            end

            v212()
            lineup_execution = {}
        end
        local function v227(p97)
            local location = lineup_execution.location
            local data = lineup_execution.data

            if not data then
                lineup_execution.data = {}
                data = lineup_execution.data
            end

            if not data.start_at then
                data.start_at = p97.command_number
            end

            local v605 = p97.command_number - data.start_at + 1
            local v606 = location.movement.steps[v605]

            if v606 then
                u94(v205, false)
                u94(v206)
                u94(v210, true)
                u94(v211, false)

                local strafer = location.strafer

                if strafer ~= nil then
                    u94(v209, strafer.quick_stop)
                    u94(v206, strafer.air_strafe)
                    u94(v207, strafer.wasd_strafer)
                    u94(v208, strafer.strafer_smoothing)
                end

                local viewangles = v606.viewangles
                local v609 = _vector(viewangles[1], viewangles[2], 0)

                if menu.settings.aimbot ~= "Rage" then
                    u213(false)
                    camera_angles(v609)
                else
                    p97.view_angles = v609
                end

                p97.move_yaw = v606.move_yaw

                local forwardmove = v606.forwardmove

                if forwardmove then
                    p97.forwardmove = forwardmove
                end

                local sidemove = v606.sidemove

                if sidemove then
                    p97.sidemove = sidemove
                end

                local v612 = v606.buttons or {}

                if p97.in_attack or p97.in_attack2 or v612.in_attack or v612.in_attack2 then
                    data.is_attack = true
                end

                if data.is_attack then
                    local v613 = v612.in_attack or false

                    p97.in_attack2 = v612.in_attack2 or false
                    p97.in_attack = v613
                end

                p97.in_forward = v612.in_forward or false
                p97.in_moveleft = v612.in_moveleft or false
                p97.in_moveright = v612.in_moveright or false
                p97.in_back = v612.in_back or false
                p97.in_speed = v612.in_speed or false
                p97.in_duck = v612.in_duck or false
                p97.in_use = v612.in_use or false
                p97.in_jump = v612.in_jump or false

                return
            end

            v212()
            lineup_execution = {}
        end

        function u228(p98, p99, p100, p101, p102)
            if p98 ~= nil then
                p99.jitter_move = false
                u94(v202, false)
                u94(v203, false)
                u94(v205, false)
                u94(v206, false)
                u94(v210, false)
                u94(v211, false)

                local movement = p98.movement

                if movement == nil then
                    u223(p99, p100, p101, p102)

                    return
                end

                if movement.frames == nil then
                    return v227(p99)
                end

                return u226(p99)
            end
        end

        local v229 = _vector(0, 0, 64)
        local v230 = _vector(0, 0, 6)

        local function v231(p103, p104)
            local v622 = customization.hide_duplicates and not editing_sources
            local t45 = {}

            for i = p104, 1, -1 do
                local v625 = p103[i]
                local name = v625.name

                if _type(name) == "table" then
                    v625.name = name[2] or name
                end

                local position = v625.position

                if _type(position) == "table" then
                    position = _vector(position[1], position[2], position[3])
                    v625.position = position
                    v625.render_position = clone(position)
                end

                local viewangles = v625.viewangles

                if _type(viewangles) == "table" then
                    local v629 = _vector(viewangles[1], viewangles[2])

                    v625.viewangles = v629
                    v625.viewangles_forward = position + v229 + angles(_vector(), v629) * 700
                end

                v625.in_fov_select = 0
                v625.on_screen = 0

                if v622 then
                    local v630 = _tostring(v625.position) .. _tostring(v625.viewangles)

                    if t45[v630] == nil then
                        t45[v630] = true
                    else
                        remove(p103, i)
                    end
                end
            end
        end

        function u232(p105, p106, p107)
            if t35[p107] == nil then
                v231(p105, p106)

                for i = 1, p106 do
                    local v635 = p105[i]

                    if v635 ~= nil then
                        local render_position = v635.render_position
                        local v637 = render_position
                        local t46 = {
                            [1] = v635,
                        }

                        for j = p106, i + 1, -1 do
                            local v640 = p105[j]

                            if v640 ~= nil then
                                local render_position2 = v640.render_position

                                if u78(render_position, render_position2) <= 20 then
                                    v637 = v637 + render_position2
                                    t46[#t46 + 1] = v640
                                    remove(p105, j)
                                end
                            end
                        end

                        local v642 = v637 / #t46
                        local t47 = {
                            viewangles_alpha = 0,
                            distance_width = 0,
                            visible_alpha = 0,
                            weapon = v635.weapon,
                            position = v642,
                            world_position = v642 + v230,
                        }
                        local t48 = {}
                        local v645 = false
                        local v646 = false
                        local v647 = #t46

                        for j = 1, v647 do
                            local v649 = t46[j]
                            local name = v649.name

                            if not v649.editing then
                                t48[#t48 + 1] = name
                            else
                                t48[#t48 + 1] = "<editing>" .. name
                                v646 = true

                                if v647 == 1 then
                                    v645 = true
                                end
                            end

                            t47[j] = v649
                        end

                        local v651 = concat(t48, "\aDEFAULT\n")
                        local v652 = gsub(v651, "<editing>", "")
                        local v653 = measure_text(1, nil, v652)

                        t47.text = v651

                        local x = v653.x

                        t47.height = v653.y
                        t47.width = x
                        t47.is_have_editing = v646
                        t47.is_one_editing = v645
                        p105[i] = t47
                    end
                end

                t35[p107] = true

                return
            end
        end

        local t49 = {}
        local u234 = nil
        local n12 = nil

        local function v236(p108, p109)
            return not (p108.distance <= p109.distance)
        end
        local function v237(p110, p111, p112)
            sort(p110, v236)

            local v660 = p110[p111]

            selection_alpha = 1
            focused_location_group = v660

            if focused_location_group ~= nil then
                local v661 = u78(p112, focused_location_group.position)

                if not (v661 > 30) then
                    selection_alpha = 0.4 + u102(v661, 0, 0.6, 30)

                    return
                end

                focused_location_group = nil

                return
            end
        end

        function u238(p113, p114, p115, p116)
            if p115 ~= u234 then
                u234 = p115
                weapon_locations = nil
            end

            if weapon_locations == nil then
                local v666 = locations_by_weapon[p115] or false

                nearby_locations = {}
                weapon_locations = v666

                if weapon_locations then
                    for i = 1, #weapon_locations do
                        local v668 = weapon_locations[i]

                        v668.visible_alpha = 0
                        v668.distance_width = 0
                        v668.viewangles_alpha = 0
                    end
                end

                n12 = 0
            end

            if weapon_locations then
                local v669 = #weapon_locations

                if v669 ~= 0 then
                    u232(weapon_locations, v669, p115)

                    local v670 = #weapon_locations
                    local realtime = _globals.realtime

                    if not (realtime > n12 + 0.07) then
                        local v672 = #t49

                        if v672 ~= 0 then
                            for i = 1, v672 do
                                local v674 = t49[i]

                                if v674.distance > 30 then
                                    v674.distance = u78(p114, v674.position)

                                    for j = 1, #v674 do
                                        local v676 = v674[j]

                                        v676.in_fov_select = 0
                                        v676.on_screen = 0
                                    end
                                end
                            end

                            v237(t49, v672, p114)

                            return
                        end

                        return
                    end

                    n12 = realtime
                    t49 = {}
                    nearby_locations = {}

                    for i = 1, v670 do
                        local v678 = weapon_locations[i]
                        local v679 = u78(p114, v678.position)

                        v678.distance = v679

                        if not (v679 <= 1500) then
                            v678.distance_width = 0
                            v678.in_range = false
                        else
                            nearby_locations[#nearby_locations + 1] = v678

                            if v679 <= 50 then
                                t49[#t49 + 1] = v678
                            end

                            v678.distance_alpha = u103(1 - v679 / 1500, 0, 1, 1)
                            v678.is_visible = not (
                                trace_line(p116, v678.world_position, p113, 33570827).fraction <= 0.97
                            )
                            v678.in_range = not (v679 > 650)
                        end
                    end

                    return v237(nearby_locations, #nearby_locations, p114)
                end

                return
            end
        end
        function handle_lineup_command(p117)
            local v681 = get_local_player()

            if v681 ~= nil and v681:is_alive() then
                local v682, v683 = get_held_weapon(v681)

                if v682 ~= nil then
                    local v684 = v681:get_origin()
                    local v685 = camera_position()

                    u238(v681, v684, v683, v685)

                    local v686 = settings.aimbot == "Legit"
                    local location = lineup_execution.location

                    if u91(settings.hotkey) then
                        if selected_lineup ~= nil then
                            v212()
                        end

                        if selected_lineup == nil or location ~= nil then
                            if v686 then
                                u213(true)
                            end
                        else
                            local position = selected_lineup.position
                            local v689 = u78(v684, position)
                            local v690 = dist2d(v684, position)

                            if v690 < 0.5 and v689 > 0.08 and v689 < 5 then
                                v689 = v690
                            end

                            local v691 = length2d(v681.m_vecAbsVelocity)
                            local v692 = band(v681.m_fFlags, 1) == 1
                            local v693 = v681.m_MoveType == 9
                            local v694 = p117.in_forward
                                or (
                                    p117.in_back
                                    or (
                                        p117.in_moveleft
                                        or (p117.in_moveright or (p117.in_jump or not v693 and not v692))
                                    )
                                )
                            local on_position = selected_lineup.on_position

                            if not on_position and not v694 then
                                u94(v202, false)
                                u94(v203, false)
                                p117.jitter_move = false
                                p117.sidemove = 0
                                p117.in_moveright = false
                                p117.in_moveleft = false

                                if not v693 then
                                    local v696 = position + normalized(position - v684) * 10 - v684

                                    p117.move_yaw = angles(v696).y
                                    p117.in_speed = false

                                    if not (v689 > 14) then
                                        local m_flDuckAmount = v681.m_flDuckAmount
                                        local v698 = clamp(1.1 + m_flDuckAmount * 10, v689 * 9, 450)

                                        if not (v691 >= min(250, v698) + 15) then
                                            p117.forwardmove = max(6, v691 >= min(250, v698) and v698 * 0.9 or v698)
                                            p117.in_forward = true

                                            if v689 < 1 then
                                                u94(v209, false)
                                            end
                                        else
                                            p117.forwardmove = 0
                                            p117.in_forward = false
                                        end
                                    else
                                        p117.forwardmove = 450
                                    end
                                else
                                    local v699 = position.z - v684.z
                                    local v700 = position.y - v684.y
                                    local v701 = not (v699 <= 0.5) or not (v699 >= -0.5)
                                    local v702 = not (v700 <= 0.5) or not (v700 >= -0.5)

                                    if v701 then
                                        p117.buttons = v699 > 0 and bor(p117.buttons, 8) or bor(p117.buttons, 16)
                                    end

                                    if v702 then
                                        p117.buttons = v700 > 0 and bor(p117.buttons, 512) or bor(p117.buttons, 1024)
                                    end

                                    if v701 or v702 then
                                        p117.in_speed = true
                                        p117.in_duck = true
                                    end
                                end
                            end

                            if selected_lineup.weapon ~= "weapon_wallbang" then
                                if p117.in_attack or p117.in_attack2 then
                                    local v703 = selected_lineup.grenade and selected_lineup.grenade.strength

                                    if v703 ~= 0 then
                                        if v703 ~= 0.5 then
                                            p117.in_attack2 = false
                                            p117.in_attack = true
                                        else
                                            p117.in_attack2 = true
                                            p117.in_attack = true
                                        end
                                    else
                                        p117.in_attack2 = true
                                        p117.in_attack = false
                                    end
                                end

                                local v704 = settings.automatic_throw and not (_globals.curtime <= v681.m_flNextAttack)
                                    or (
                                        selected_lineup.movement and p117.in_attack
                                        or (p117.in_attack2 or v682.m_bPinPulled)
                                    )

                                if on_position and v704 and v691 < 2 then
                                    if v686 then
                                        local v705 = camera_angles()
                                        local v706 = v705 - selected_lineup.viewangles

                                        v706.y = normalize_yaw(v706.y)

                                        local x = v706.x
                                        local y = v706.y
                                        local v709 = abs(u81(v706))
                                        local fov = settings.fov
                                        local smooth = settings.smooth

                                        if v709 <= fov then
                                            local v712 = min(1, v709 / 3) * 0.5
                                            local v713 = (v712 + abs(v709 * (1 - v712))) * _globals.frametime * smooth

                                            u213(false)
                                            camera_angles(
                                                _vector(v705.x - x / v709 * v713, v705.y - y / v709 * v713, 0)
                                            )
                                        end
                                    end

                                    if selected_lineup.is_on_fov then
                                        lineup_execution.location = selected_lineup
                                    end
                                end

                                if (p117.in_attack or p117.in_attack2) and selected_lineup.movement ~= nil then
                                    p117.in_attack2 = false
                                    p117.in_attack = false
                                end
                            end
                        end

                        u228(location, p117, v681, v682, v683)

                        return
                    end

                    if v686 or selected_lineup ~= nil or location ~= nil then
                        v212()
                        u213(true)
                    end

                    lineup_execution = {}

                    return
                end

                return
            end

            u213(true)
            v212()
            lineup_execution = {}
            weapon_locations = nil
        end
    end

    local n13 = -1
    local createmove = _events.createmove

    local function v242()
        execute_after(1, v242)

        local v714 = #createmove

        if v714 ~= n13 then
            n13 = v714
            createmove(handle_lineup_command, false)
            createmove(handle_lineup_command, true)

            return
        end
    end

    v242()

    local settings = menu.settings
    local customization = menu.customization
    local v245 = _color(16, 16, 16, 255)
    local v246 = _color(255, 245, 5)
    local v247 = _color(20, 236, 0)
    local v248 = _color(140, 255)
    local v249 = _color(255, 16, 16)
    local u250 =
        utils.get_vfunc("engine.dll", "VEngineClient014", 37, "struct { float m[4][4]; } & (__thiscall*)(void*)")

    local function v251(p118, p119, p120, p121, p122, p123, p124, p125)
        local v723 = p118 * p121 - p119 * p120
        local v724 = p122 * p125 - p123 * p124
        local v725 = (p118 - p120) * (p123 - p125) - (p119 - p121) * (p122 - p124)

        return (v723 * (p122 - p124) - (p118 - p120) * v724) / v725,
            (v723 * (p123 - p125) - (p119 - p121) * v724) / v725
    end

    local x = u97.x
    local y = u97.y
    local x2 = u96.x
    local y2 = u96.y

    local function u256(p126, p127, p128)
        local x3 = p127.x
        local y3 = p127.y
        local z = p127.z
        local m = p126.m
        local v733 = m[0]
        local v734 = m[1]
        local v735 = m[3]
        local v736 = v733[0] * x3 + v733[1] * y3 + v733[2] * z + v733[3]
        local v737 = v734[0] * x3 + v734[1] * y3 + v734[2] * z + v734[3]
        local v738 = v735[0] * x3 + v735[1] * y3 + v735[2] * z + v735[3]
        local v739 = not (v738 < 0.001)
        local v740 = (v739 and 1 or -1) / v738
        local v741 = v736 * v740
        local v742 = v737 * v740
        local v743 = x + (0.5 * v741 * x2 + 0.5)
        local v744 = y - (0.5 * v742 * y2 + 0.5)

        if v739 and (v743 >= p128 and v743 <= x2 - p128 and v744 >= p128 and not (v744 > y2 - p128)) then
            return _vector(v743, v744), true
        end

        if not v739 then
            local v745 = atan2(v744 - y, v743 - x)
            local v746 = max(x2, y2)

            v743 = x + v746 * cos(v745)
            v744 = y + v746 * sin(v745)
        end

        local t50 = {
            [1] = p128,
            [2] = p128,
            [3] = x2 - p128,
            [4] = p128,
            [5] = x2 - p128,
            [6] = p128,
            [7] = x2 - p128,
            [8] = y2 - p128,
            [9] = p128,
            [10] = p128,
            [11] = p128,
            [12] = y2 - p128,
            [13] = p128,
            [14] = y2 - p128,
            [15] = x2 - p128,
            [16] = y2 - p128,
        }

        for i = 1, 16, 4 do
            local v749 = t50[i]
            local v750 = t50[i + 1]
            local v751 = t50[i + 2]
            local v752 = t50[i + 3]
            local v753, v754 = v251(v749, v750, v751, v752, x, y, v743, v744)

            if
                i == 1 and v744 < p128 and p128 <= v753 and not (v753 > x2 - p128)
                or i == 5 and v743 > x2 - p128 and p128 <= v754 and not (v754 > y2 - p128)
                or i == 9 and v743 < p128 and p128 <= v754 and not (v754 > y2 - p128)
                or i == 13 and v744 > y2 - p128 and p128 <= v753 and v753 <= x2 - p128
            then
                return _vector(v753, v754), false
            end
        end

        return _vector(v743, v744), false
    end

    local v257 = render.load_font("calibri", 11, "abd")
    local t51 = {
        weapon_smokegrenade = render.load_image_from_file(
            "materials\\panorama\\images\\icons\\equipment\\smokegrenade.svg"
        ),
        weapon_flashbang = render.load_image_from_file("materials\\panorama\\images\\icons\\equipment\\flashbang.svg"),
        weapon_decoy = render.load_image_from_file("materials\\panorama\\images\\icons\\equipment\\decoy.svg"),
        weapon_hegrenade = render.load_image_from_file("materials\\panorama\\images\\icons\\equipment\\hegrenade.svg"),
        weapon_molotov = render.load_image_from_file("materials\\panorama\\images\\icons\\equipment\\molotov.svg"),
        weapon_wallbang = render.load_image_from_file("materials\\panorama\\images\\icons\\ui\\bullet.svg"),
        weapon_knife = render.load_image(
            "<?xml version='1.0' encoding='UTF-8' standalone='no'?>\n<svg xmlns:svg='http://www.w3.org/2000/svg' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 158 200' height='200mm' width='158mm'>\n<g style='mix-blend-mode:normal'>\n<path d='m 27.692726,195.58287 c -2.00307,-2.00307 -2.362731,-5.63696 -1.252001,-12.64982 .51631,-3.25985 .938744,-6.15692 .938744,-6.43794 0,-.28102 -1.054647,-.68912 -2.343659,-.9069 -1.289012,-.21778 -2.343659,-.46749 -2.343659,-.55491 0,-.0874 .894568,-2.10761 1.987932,-4.48934 4.178194,-9.10153 7.386702,-22.1671 7.386702,-3.07983 v -3.57114 l -3.439063,-.65356 c -7.509422,-1.42712 -14.810239,-6.3854 -17.132592,-11.63547 -.617114,-1.39509 -1.6652612,-5.2594 -2.3292172,-8.58736 -.894299,-4.48252 -1.742757,-6.93351 -3.273486,-9.45625 -2.296839,-3.78538 -2.316583,-5.11371 -.151099,-1.165583 .632785,-1.47622 2.428356,-7.85932 3.990157,-14.18467 2.3650332,-9.578444 3.4874882,-12.902312 6.7157522,-19.887083 5.153317,-11.149867 5.357987,-11.987895 3.936721,-16.118875 -1.318135,-3.831228 -1.056436,-5.345174 1.69769,-9.821193 .98924,-1.607722 2.121218,-4.129295 2.515508,-5.6035 C 25.28429,28.210324 25.23258,27.949807 23.35135,24.502898 21.710552,21.496527 21.306782,19.993816 2.889474,15.340532 2.614927,12.279129 2.380889,8.4556505 2.369393,6.8439185 l -.02091,-2.930428 9.333915,.83216 9.333914,.832161 .415652,4.4356115 c .228605,2.439587 .232248,9.481725 .0081,15.649196 l -.407561,11.213581 3.401641,.387936 c 1.8709,.213363 4.456285,.528941 5.745297,.701283 l 2.343658,.31335 .01922,-4.58462 c .01523,-3.630049 .300834,-5.120017 1.371678,-7.156027 3.087768,-5.870826 9.893488,-1.61208 17.039741,-11.87087 2.720173,-.479148 4.160963,-.409507 7.136663,.344951 8.66897,2.197927 13.98192,9.621168 13.98192,19.535491 0,3.495649 -.1404,3.901096 -1.99211,5.752805 -1.24394,1.243942 -2.56423,1.992111 -3.51549,1.992111 -1.49731,0 -1.52337,.07107 -1.52337,4.153986 v 4.15399 l 8.9352,-.237138 c 5.2858,-.140285 11.170779,-.674802 14.408789,-1.308719 l 5.4736,-1.071577 -.38275,-2.552314 c -.37145,-2.476984 -.33603,-2.552315 1.19984,-2.552315 .87041,0 1.91062,-.448636 2.31157,-.996969 .68332,-.93449 1.27483,-.910186 9.43922,.387872 4.86768,.773912 12.32893,1.486871 16.91304,1.616118 4.51154,.127203 8.93123,.513358 9.82152,.858128 2.24255,.86843 2.71036,3.071333 1.03169,4.858196 -2.36272,2.515004 -4.22494,2.914196 -9.65444,2.069567 -6.49602,-1.010535 -9.48434,-.608226 -12.89073,1.735433 -1.51944,1.045409 -3.78166,2.037422 -5.02716,2.204478 -2.12756,.285364 -2.24441,.404325 -1.93193,1.966706 .54423,2.721143 -.2472,4.489222 -3.68173,8.225132 -3.77119,4.102112 -4.63155,5.89093 -5.49449,11.423793 -.94965,6.08886 -1.57396,7.52473 -5.32281,12.24226 -5.48499,6.90229 -11.865029,11.373083 -16.271159,11.401983 -2.96514,.0195 -5.44164,-1.427403 -1.64598,-6.219683 -6.09285,-5.61044 -11.509723,-9.58715 -13.059111,-9.58715 -.74413,0 -2.728788,1.56375 -5.069514,3.99435 -2.115662,2.19689 -4.279795,4.24027 -4.809188,4.54084 -.873942,.49619 -.888303,.97152 -.156034,5.16456 .443574,2.539953 1.213393,5.239093 1.710714,5.998093 1.234397,1.88393 4.464204,3.43033 1.249847,4.90755 11.894956,3.03704 24.227356,12.17082 28.700056,21.25618 3.277059,6.65665 3.756559,14.90456 1.06537,18.32585 -2.00495,2.54888 -4.71703,3.29933 -13.73034,3.79931 -12.02449,.66702 -11.43259,.30042 -25.191149,15.60203 -3.539415,3.93635 -4.947788,5.02545 -9.098134,7.03552 -6.030466,2.92066 -8.127669,5.18229 -9.759102,1.52427 -1.407053,4.60727 -3.889283,7.93618 -7.163048,9.60633 -3.066476,1.56439 -5.550268,1.48363 -7.270304,-.2364 z M 99.119321,71.201503 c 3.729129,-4.724307 6.662059,-8.707839 6.517599,-8.852305 -.14446,-.144451 -2.7777,1.571678 -5.851649,3.813635 -4.38891,3.20102 -6.56642,4.363275 -1.1411,5.412849 -2.50365,.73511 -4.68393,1.459682 -4.84506,1.610152 -.31664,.295703 6.47662,6.567603 7.13899,6.591103 .22054,.008 3.4521,-3.85113 7.18122,-8.575434 z' style='fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:.585916;stroke-opacity:1' />\n</g>\n</svg>\n",
            _vector(26, 26)
        ),
    }
    local t52 = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    }
    local t53 = {
        [t51.weapon_smokegrenade] = {
            [1] = 0.2,
            [2] = -0.1,
            [3] = 0.35,
            [4] = 0,
        },
        [t51.weapon_hegrenade] = {
            [1] = 0.1,
            [2] = -0.12,
            [3] = 0.2,
            [4] = 0,
        },
        [t51.weapon_molotov] = {
            [1] = 0,
            [2] = -0.04,
            [3] = 0,
            [4] = 0,
        },
        [t51.weapon_knife] = {
            [1] = 0,
            [2] = 0,
            [3] = -0.2,
            [4] = 0,
        },
    }
    local u261 = _setmetatable({}, {
        __index = function(p129, p130)
            local v757 = t53[p130] or t52

            p129[p130] = _setmetatable({}, {
                __index = function(p131, p132)
                    local v1325 = p130.width * p132 / p130.height
                    local v1326 = v757[1] * v1325
                    local v1327 = v757[2] * p132
                    local t54 = {
                        v1325 + v757[3] * v1325,
                        p132 + v757[4] * p132,
                        v1326,
                        v1327,
                        _vector(v1325, p132),
                    }

                    if _tostring(t54[1]) ~= "nan" then
                        p131[p132] = t54
                    end

                    return t54
                end,
            })

            return p129[p130]
        end,
    })

    local function v262(p133, p134)
        return not (p133.fov <= p134.fov)
    end

    local nhx_main = function()
        selected_lineup = nil

        local v760 = get_local_player()
        if v760 ~= nil and v760:is_alive() then
            local _, weapon = get_held_weapon(v760)
            NadeHelper.best_tick(nearby_locations, weapon_locations, weapon, v760:get_origin())
        else
            NadeHelper.best, NadeHelper.best_work, NadeHelper.best_targets = nil, nil, nil
        end

        if v760 ~= nil and v760:is_alive() then
            if weapon_locations then
                local v761 = #nearby_locations

                if v761 ~= 0 then
                    local color2 = customization.color
                    local alpha = customization.alpha
                    local show_behind_walls = customization.show_behind_walls
                    local hide_icon_with_text = customization.hide_icon_with_text
                    local aimbot = settings.aimbot
                    local fov = settings.fov

                    if aimbot ~= "Rage" then
                        fov = 0.3
                    end

                    local frametime = _globals.frametime
                    local location = lineup_execution.location

                    for i = 1, v761 do
                        local v771 = nearby_locations[i]
                        local v772 = v771 == focused_location_group

                        if not v772 then
                            v771.viewangles_alpha = 0
                        end

                        local v773 = v771.in_range and (not (selection_alpha <= 0.5) or v772)
                        local distance_width = v771.distance_width

                        if not v773 or not (distance_width < 1) then
                            if not v773 and distance_width > 0 then
                                distance_width = max(0, distance_width - frametime * 6)
                            end
                        else
                            distance_width = min(1, distance_width + frametime * 6)
                        end

                        v771.distance_width = distance_width

                        local v775 = u102(distance_width, 0, 1, 1)
                        local visible_alpha = v771.visible_alpha
                        local is_visible = v771.is_visible
                        local v778 = show_behind_walls and v775 > 0 and 0.45 or 0
                        local v779 = show_behind_walls and (v775 > 0 and not is_visible) and 0.33 or 1

                        if (not is_visible or visible_alpha >= 1) and not (visible_alpha < v778) then
                            if not is_visible and v778 < visible_alpha then
                                visible_alpha = max(v778, visible_alpha - frametime * 7.5 * v779)
                            end
                        else
                            visible_alpha = min(1, visible_alpha + frametime * 5.5 * v779)
                        end

                        local v780 = location == v771 and 1 or v771.distance_alpha

                        v771.visible_alpha = visible_alpha

                        local v781 = u104(visible_alpha, 0, 1, 1) * (v772 and 1 or selection_alpha) * v780

                        if v781 > 0 then
                            local v782 = to_screen(v771.world_position)

                            if v782 ~= nil then
                                local x4 = floor(v782.x + 0.5)
                                local y4 = floor(v782.y + 0.5)
                                local v785 = alpha * v781
                                local v786 = 255 * v785
                                local v787 = NadeHelper.best_group(v771) or color2

                                v787.a = v786

                                local is_have_editing = v771.is_have_editing

                                if is_have_editing then
                                    v249.a = v786

                                    if v771.is_one_editing then
                                        v787 = v249
                                    end
                                end

                                local width = v771.width
                                local height = v771.height

                                if v775 < 1 then
                                    width = width * v775
                                    height = height * v775
                                end

                                local v791 = t51[v771.weapon]
                                local v792 = nil
                                local v793 = nil
                                local v794 = nil

                                if hide_icon_with_text and v775 > 0 then
                                    v791 = nil
                                end

                                local v795 = height
                                local v796

                                if v791 == nil then
                                    v796 = width - 3 * v775
                                else
                                    local v797 = v771.distance - 60
                                    local v798 = min(20, floor(max(13, height + 2, v797 < 0 and -v797 or 0)))
                                    local v799 = u261[v791][v798]

                                    v794 = v799[5]
                                    v793 = v799[1]

                                    local v800 = v799[2]

                                    v796 = width + v775 * 8 + v793
                                    height = max(v800, height)

                                    local v801 = x4 - v796 * 0.5 + v799[3]
                                    local v802 = y4 - height + v799[4]

                                    if v800 < v795 then
                                        v802 = v802 + (v795 - v800) * 0.5
                                    end

                                    v792 = _vector(floor(v801), floor(v802))
                                end

                                local v803 = x4 - v796 * 0.5
                                local v804 = y4 - height
                                local v805 = v803 + v796
                                local v806 = v804 + height

                                NadeHelper.panel(
                                    v803 - 6,
                                    v804 - 4,
                                    v805 + 8,
                                    v806 + 4,
                                    v785,
                                    min(9, (v806 - v804 + 8) * 0.5)
                                )

                                if v775 > 0 then
                                    if v793 ~= nil then
                                        local v807 = v803 + v793
                                        local v808 = v804 + 2

                                        rect(
                                            _vector(v807 + 3, v808),
                                            _vector(v807 + 4, v808 + height - 3),
                                            NadeHelper.c(NadeHelper.EDGE, 40 * v785),
                                            0,
                                            true
                                        )
                                        v803 = v803 + v793 + 8
                                    end

                                    if v795 < height then
                                        v804 = v804 + (height - v795) * 0.5
                                    end

                                    local text2 = v771.text

                                    if is_have_editing then
                                        text2 = gsub(text2, "<editing>", "\a" .. to_hex(v249))
                                    end

                                    push_clip_rect(_vector(v803, v804), _vector(v805, v806), false)
                                    text(1, _vector(v803, v804 - 1), v787, nil, text2)
                                    pop_clip_rect()
                                    NadeHelper.best_group_label(v771, x4, y4, v785)
                                end

                                if v791 ~= nil then
                                    texture(v791, v792, v794, v787, "f", 0)
                                end
                            end
                        end
                    end

                    if focused_location_group ~= nil then
                        local viewangles_alpha = focused_location_group.viewangles_alpha

                        if location ~= focused_location_group then
                            if viewangles_alpha < 1 then
                                viewangles_alpha = min(1, viewangles_alpha + frametime * 6)
                            end
                        else
                            viewangles_alpha = 1
                        end

                        focused_location_group.viewangles_alpha = viewangles_alpha

                        local v811 = u105(viewangles_alpha, 0, 1, 1)

                        if v811 ~= 0 then
                            local v812 = v760:get_origin()
                            local v813 = camera_angles()
                            local m_flDuckAmount = v760.m_flDuckAmount
                            local v815 = v760.m_MoveType == 9
                            local v816 = #focused_location_group

                            for i = 1, v816 do
                                local v818 = focused_location_group[i]
                                local v819 = v813 - v818.viewangles

                                v819.y = normalize_yaw(v819.y)

                                local v820 = abs(u81(v819))

                                v818.is_on_fov = not (v820 > fov)
                                v818.fov = v820

                                local position = v818.position
                                local v822 = u78(v812, position)
                                local v823 = dist2d(v812, position)

                                if v823 < 1.5 then
                                    v822 = v823
                                end

                                v818.distance_2d = v823
                                v818.distance = v822
                                v818.on_position = v822 < (v815 and 0.45 or 0.1)
                                    and (m_flDuckAmount == v818.duck and 1 or 0)
                            end

                            sort(focused_location_group, v262)
                            selected_lineup = focused_location_group[v816]

                            local v824 = u250()

                            for i = 1, v816 do
                                local v826 = focused_location_group[i]
                                local v827 = v826 == selected_lineup
                                local is_on_fov = v826.is_on_fov
                                local v829 = v827 and is_on_fov
                                local v830 = v826.on_position or v826 == location
                                local v831, v832 = u256(v824, v826.viewangles_forward, 40)
                                local on_screen = v826.on_screen

                                if not v832 or not (on_screen < 1) then
                                    if not v832 and on_screen > 0 then
                                        on_screen = max(0, on_screen - frametime * 5.5)
                                    end
                                else
                                    on_screen = min(1, on_screen + frametime * 4.5)
                                end

                                v826.on_screen = on_screen

                                local v834 = alpha * ((0.5 + on_screen * 0.5) * v811)
                                local v835 = NadeHelper.best_color(v826) or color2

                                if v826.editing then
                                    v835 = v249
                                end

                                local v836 = 255 * v834

                                v835.a = v836

                                local v837 = "»" .. v826.name
                                if NadeHelper.is_best(v826) then
                                    v837 = (NadeHelper.best_icon or "") .. " " .. v826.name
                                end
                                local target_caption = NadeHelper.best_caption(v826)
                                if target_caption ~= "" then
                                    v837 = v837 .. "  [" .. target_caption .. "]"
                                end
                                local description = v826.description
                                local v839 = measure_text(v257, nil, v837)
                                local v840 = u71

                                if description ~= nil then
                                    description = gsub(upper(description), " ", "  ")
                                    v840 = measure_text(2, nil, description)
                                end

                                local v841 = floor(v840.y * 0.5)
                                local v842 = max(v839.x, v840.x)
                                local v843 = v839.y + v840.y
                                local v844 = floor(v839.y * 0.5 - 1) * 2.25
                                local n14 = 0

                                if on_screen > 0 then
                                    n14 = floor((v844 + 7) * on_screen) + v841
                                    v842 = v842 + n14
                                end

                                local v846 = floor(min(v831.x - v844 * 0.5 - v841 * 0.5, u96.x - 40 - v842) + 0.5)
                                local v847 = floor(v831.y - v843 * 0.5 + 0.5)
                                local v848 = v846 + v842
                                local v849 = v847 + v843
                                local v850 = u106(v834, 0, 1, 1)

                                NadeHelper.panel(v846 - 6, v847 - 4, v848 + 7, v849 + 4, v850, 8)

                                if on_screen > 0.5 then
                                    local v851 = v844 * 0.5
                                    local in_fov_select = v826.in_fov_select

                                    if not v829 or not (in_fov_select < 1) then
                                        if not v829 and in_fov_select > 0 then
                                            in_fov_select = max(0, in_fov_select - frametime * 4.5)
                                        end
                                    else
                                        in_fov_select = min(1, in_fov_select + frametime * 2.5 * (is_on_fov and 2 or 1))
                                    end

                                    v826.in_fov_select = in_fov_select

                                    local v853 = _vector(v846 + v851 + v841 * 0.5, v847 + v843 * 0.5)

                                    if location ~= v826 then
                                        local v854 = v836 * u107(on_screen, 0, 1, 1)
                                        local v855 = NadeHelper.best_color(v826)
                                            or (v830 and NadeHelper.GREEN or NadeHelper.AMBER)
                                        local v856 = lerp(NadeHelper.IDLE, v855, in_fov_select)

                                        v856.a = v854

                                        circle_outline(v853, v856, v851, 0, 1, 1.5)
                                    else
                                        circle_outline(v853, v835 * 1.2, v851, 0, 1, 1.5)
                                    end
                                end

                                local v857 = v846 + n14

                                if n14 > 1 then
                                    v835.a = v835.a * on_screen
                                    rect(_vector(v857 - 5, v847 + 1), _vector(v857 - 3, v847 + v843), v835, 1)
                                end

                                text(v257, _vector(v857, v847), v835, nil, v837)

                                if description ~= nil then
                                    text(2, _vector(v857, v847 + v839.y), v835 * 1.2, nil, description)
                                end
                            end

                            if
                                NadeHelper.traj
                                and selected_lineup ~= nil
                                and selected_lineup.weapon ~= "weapon_wallbang"
                            then
                                local fsel = selected_lineup.in_fov_select or 0
                                local focus = (
                                    selected_lineup.is_on_fov
                                    or selected_lineup.on_position == 1
                                    or selected_lineup == location
                                )
                                        and 1
                                    or 0

                                NadeHelper.draw(
                                    selected_lineup,
                                    color2,
                                    alpha * v811 * fsel,
                                    focus,
                                    t51[selected_lineup.weapon]
                                )
                            end

                            if location ~= nil then
                                NadeHelper.exec, NadeHelper.exec_t = location, globals.realtime
                            end

                            return
                        end

                        return
                    end

                    return
                end

                return
            end

            return
        end
    end

    _events.render(function()
        local live = weapon_locations and nearby_locations ~= nil and #nearby_locations ~= 0

        if live then
            NadeHelper.kept = { weapon_locations, nearby_locations, focused_location_group, selection_alpha }
            NadeHelper.fade = 1
            nhx_main()

            return
        end

        local k = NadeHelper.kept

        if k == nil or (NadeHelper.fade or 0) <= 0 then
            nhx_main()

            return
        end

        NadeHelper.fade = NadeHelper.fade - globals.frametime / 0.25

        if NadeHelper.fade <= 0 then
            NadeHelper.kept = nil
            nhx_main()

            return
        end

        local s181, s182, s193, s194, a0 =
            weapon_locations, nearby_locations, focused_location_group, selection_alpha, customization.alpha
        local f = NadeHelper.fade

        weapon_locations, nearby_locations, focused_location_group, selection_alpha = k[1], k[2], k[3], k[4]
        customization.alpha = (a0 or 1) * f * f * (3 - 2 * f)

        local ok = pcall(nhx_main)

        weapon_locations, nearby_locations, focused_location_group, selection_alpha = s181, s182, s193, s194
        customization.alpha = a0
        selected_lineup = nil

        if not ok then
            NadeHelper.kept = nil
        end
    end)
    grenade_release = menu.grenade_release

    NadeHelper.release_settings = grenade_release
    local v272 = find2("Visuals", "World", "Other", "Grenade Prediction")
    local release_was = nil

    _events.grenade_prediction:set(function(e)
        NadeHelper.release_prediction(e)
    end)
    _events.createmove:set(function(cmd)
        NadeHelper.release_run(cmd, lineup_execution.location ~= nil or editor_state ~= nil)
    end)
    _events.render:set(function()
        local enabled = grenade_release.enabled:get()
        if enabled ~= release_was then
            release_was = enabled
            NadeHelper.release_pending, NadeHelper.release_pin, NadeHelper.release_weapon = nil, false, nil
            if v272 then
                v272:override(enabled and true or nil)
            end
        end
        if enabled and v272 and v272:get_override() ~= true then
            v272:override(true)
        end
    end)
    _events.shutdown:set(function()
        if v272 then
            v272:override()
        end
    end)

    t57 = {}
    t58 = {}
    t59 = {}

    local s6 = "https://northon.dev/grenade-helper-api"
    local s7 = "%s::%s"
    local s8 = "\a{Active Text}%s\aDEFAULT ~ %s"

    if not stable_build then
        get(s6, nil, function(p140)
            if p140 ~= nil and #p140 ~= 0 then
                local v916, v917 = _pcall(parse, p140)

                if v916 and _type(v917) == "table" then
                    local t60 = {
                        [1] = "\a{Link Active}\239\153\158\aDEFAULT  New",
                    }

                    for i = 1, #v917 do
                        local v920 = v917[i]
                        local v921 = v920[2]
                        local v922 = v920[3]
                        local v923 = format(s8, v921, v922)

                        t60[#t60 + 1] = "\a{Link Active}\239\133\134\aDEFAULT   " .. v923
                    end

                    menu.cloud_sources.selection:update(t60)

                    return
                end

                return
            end
        end)
    else
        local u282, u283, u284, u286, v287

        do
            local t61

            do
                do
                    local cloud_active_locations = load_database().cloud_active_locations

                    t61 = {}

                    function u282()
                        local n16 = 0
                        local n17 = 0

                        for i = 1, #t61 do
                            local v881 = t61[i]
                            local v882 = v881[2]
                            local v883 = v881[3]
                            local v884 = format(s7, v882, v883)
                            local v885 = cloud_active_locations[v884]

                            if v885 then
                                if v885 and cloud_sources[v884] == nil then
                                    n16 = n16 + 1

                                    local v886 = v881[1]
                                    local v887 = format("/%s-%s", v886, v882)

                                    get(s6 .. v887, nil, function(p141)
                                        if v885 then
                                            n17 = n17 + 1

                                            if p141 ~= nil and #p141 ~= 0 then
                                                local v1330, v1331 = _pcall(u100.decode, p141, s1)

                                                if v1330 and _type(v1331) == "string" then
                                                    cloud_sources[v884] = unpack2(v1331)

                                                    if n16 == n17 then
                                                        rebuild_locations()
                                                    end

                                                    return
                                                end

                                                return
                                            end

                                            return
                                        end

                                        cloud_sources[v884] = nil
                                    end)
                                end
                            else
                                local v888 = cloud_sources[v884] ~= nil

                                cloud_sources[v884] = nil

                                if v888 then
                                    rebuild_locations()
                                end
                            end
                        end
                    end

                    map_changed(u282)
                    menu.types.selection:set_callback(u282)
                    menu.customization.options:set_callback(u282)

                    function u283()
                        t59 = {}

                        local t62 = {
                            [1] = "\a{Link Active}\239\153\158\aDEFAULT  New",
                        }

                        for i = 1, #t61 do
                            local v891 = t61[i]
                            local v892 = v891[2]
                            local v893 = v891[3]
                            local v894 = format(s7, v892, v893)
                            local v895 = format(s8, v892, v893)
                            local v896 = #t62 + 1

                            t62[v896] = (
                                cloud_active_locations[v894] and "\a{Link Active}\239\131\190\aDEFAULT   "
                                or "\a{Link Active}\239\133\134\aDEFAULT   "
                            ) .. v895
                            t59[v896] = v891
                        end

                        menu.cloud_sources.selection:update(t62)
                        u282()
                    end
                    function u284(p142)
                        local v898 = u91(p142)
                        local v899 = v898 == 1
                        local v900 = #t58

                        menu.cloud_sources.upload_selection:visibility(v899 and not (v900 <= 0))
                        menu.cloud_sources.upload_label:visibility(v899 and not (v900 <= 0))
                        menu.cloud_sources.upload:visibility(v899 and not (v900 <= 0))
                        menu.cloud_sources.upload_text:visibility(v899 and v900 == 0)
                        menu.cloud_sources.update_selection:visibility(false)
                        menu.cloud_sources.update_delete_label:visibility(false)
                        menu.cloud_sources.delete_label:visibility(false)
                        menu.cloud_sources.update:visibility(false)
                        menu.cloud_sources.delete:visibility(false)
                        menu.cloud_sources.delete_confirm:visibility(false)
                        menu.cloud_sources.delete_cancel:visibility(false)

                        local v901 = t59[v898]

                        if v901 ~= nil then
                            local v902 = #t57
                            local v903 = v95 == t59[v898][2]

                            menu.cloud_sources.update_selection:visibility(v903 and not (v902 <= 0))
                            menu.cloud_sources.update_delete_label:visibility(v903 and not (v902 <= 0))
                            menu.cloud_sources.delete_label:visibility(v903 and v902 == 0)
                            menu.cloud_sources.update:visibility(v903 and not (v902 <= 0))
                            menu.cloud_sources.delete:visibility(v903)
                            menu.cloud_sources.delete_confirm:visibility(false)
                            menu.cloud_sources.delete_cancel:visibility(false)

                            local v904 = format(s7, v901[2], v901[3])
                            local v905 = u91(menu.cloud_sources.enabled)
                            local v906 = cloud_active_locations[v904] or false

                            if v905 ~= v906 then
                                set(menu.cloud_sources.enabled, v906)

                                return
                            end

                            return
                        end
                    end

                    menu.cloud_sources.selection:set_callback(u284, true)

                    function on_enabled(p143)
                        local v908 = t59[u91(menu.cloud_sources.selection)]

                        if v908 ~= nil then
                            local v909 = format(s7, v908[2], v908[3])
                            local v910 = u91(p143)

                            if v910 ~= (cloud_active_locations[v909] or false) then
                                cloud_active_locations[v909] = v910

                                local v911 = load_database()

                                v911.cloud_active_locations = cloud_active_locations
                                save_database(v911)
                                u283()

                                return
                            end

                            return
                        end
                    end
                end

                menu.cloud_sources.enabled:set_callback(on_enabled, true)

                local function v285(p144)
                    if p144 ~= nil and #p144 ~= 0 then
                        local v913, v914 = _pcall(parse, p144)

                        if v913 and _type(v914) == "table" then
                            t61 = v914
                            u283()
                            cloud_updated:call()
                            u284(menu.cloud_sources.selection)

                            return
                        end

                        return
                    end
                end

                function u286()
                    get(s6, nil, v285)
                end
            end

            u286()

            function v287(p145)
                local v925 = p145 .. "HELPER_CLOUD:SECRET"
                local n18 = 0

                gsub(v925, ".", function(p146)
                    n18 = n18 + byte(p146)
                end)

                local v927 = n18 * 5345

                return _tostring(v927)
            end

            local function v288(p147)
                if p147 == "success" then
                    add_notify("Grenade Helper", "Locations Successfully Updated")
                    u286()

                    return
                end
            end

            menu.cloud_sources.update:set_callback(function()
                local v929 = u91(menu.cloud_sources.selection)
                local v930 = t57[u91(menu.cloud_sources.update_selection)]
                local v931 = t59[v929]

                if v931 ~= nil then
                    local v932 = v931[1]
                    local v933 = v931[2]
                    local v934 = v931[3]

                    cloud_sources[format(s7, v933, v934)] = nil

                    local v935 = load_database().locations[v930]
                    local _ = v935.name
                    local locations = v935.locations
                    local v938 = pack(locations)
                    local v939 = u100.encode(v938, s1)
                    local t63 = {
                        id = v932,
                        author = v95,
                        locations = v939,
                    }
                    local v941 = stringify(t63)
                    local t64 = {
                        json = v941,
                        signature = v287(v941),
                    }

                    post(s6 .. "/update", t64, nil, v288)

                    return
                end
            end)
        end

        local function v289(p148)
            if p148 == "success" then
                add_notify("Grenade Helper", "Locations Successfully Deleted")
                u286()

                return
            end
        end

        menu.cloud_sources.delete_confirm:set_callback(function()
            local v944 = t59[u91(menu.cloud_sources.selection)]

            if v944 ~= nil then
                local v945 = v944[1]
                local v946 = v944[2]
                local v947 = v944[3]

                cloud_sources[format(s7, v946, v947)] = nil

                local t65 = {
                    id = v945,
                    author = v95,
                }
                local v949 = stringify(t65)
                local t66 = {
                    json = v949,
                    signature = v287(v949),
                }

                post(s6 .. "/delete", t66, nil, v289)

                return
            end
        end)

        local function v290(p149)
            if p149 == "success" then
                add_notify("Grenade Helper", "Locations Successfully Uploaded")
                u286()

                return
            end
        end

        menu.cloud_sources.upload:set_callback(function()
            local v952 = t58[u91(menu.cloud_sources.upload_selection)]
            local v953 = load_database().locations[v952]
            local name = v953.name
            local locations = v953.locations
            local v956 = pack(locations)
            local v957 = u100.encode(v956, s1)
            local t67 = {
                author = v95,
                name = name,
                locations = v957,
            }
            local v959 = stringify(t67)
            local t68 = {
                json = v959,
                signature = v287(v959),
            }

            post(s6 .. "/upload", t68, nil, v290)
        end)
    end
end

local t69 = {
    [1] = {
        [1] = 0.1,
        [2] = "kizaru",
        [3] = "nl\\scripts\\grenade helper\\helper.txt",
        [4] = "KeBA1OZtLzFUJ9SRuXYnV2Tc4dNkfmDjpyCvha37GrIQWq85lgxw6obsHEM0Pi+/=",
    },
    [2] = {
        [1] = 0.2,
        [2] = "brandon",
        [3] = "nl\\scripts\\grenade helper\\brandon.txt",
        [4] = "WD836KSxLOJ0ZTdflXVb4nchmzpiB59ArjMkytuvHwPURYs712IEQaqoFeGgNC+/=",
    },
    [3] = {
        [1] = 0.3,
        [2] = "fencai",
        [3] = "nl\\scripts\\grenade helper\\fencai.txt",
        [4] = "IOJMABGWSFCTmR08ei4cVatr6hgsYZqvpzwkfuQxb592oLXHUPlDKNj7E1n3yd+/=",
    },
    [4] = {
        [1] = 0.4,
        [2] = "japan_malva",
        [3] = "nl\\scripts\\grenade helper\\japan_malva.txt",
        [4] = "JPFAO6aWYSVRTCBMDXyhZ2ewqbNnjitgrUm0d4pxLz1vu9fc3kl75oGsK8HQEI+/=",
    },
    [5] = {
        [1] = 0.5,
        [2] = "spacex",
        [3] = "nl\\scripts\\grenade helper\\spacex.txt",
        [4] = "dtaS4Khx3R6MjfuwHl7YATbEFXvmPCLJ2y5pW98rGVUZz0QOeDsokqIB1iNgcn+/=",
    },
    [6] = {
        [1] = 0.6,
        [2] = "mercy",
        [3] = "nl\\scripts\\grenade helper\\mercy.txt",
        [4] = "CeASsDQFGKLWmvT8RUIkaiOVozjBfg05wpnh64MxEyc2Yl9tr31ZuP7dbNXJqH+/=",
    },
}
local s9 = "https://northon.dev/neverlose/grenade_helper/%s.txt"

for i = 1, #t69 do
    local v294 = t69[i]
    local v295 = v294[1]
    local v296 = v294[2]
    local v297 = v294[3]
    local v298 = v294[4]

    execute_after(v295, function()
        local v961 = abs(u113(v95))
        local v962 = v95 .. ":" .. v961
        local v963 = _tostring(abs(u113(v962)))
        local v964 = pack(v963)
        local v965 = u100.encode(v964, v298)

        if u100.encode(v965) == files.read(v297) then
            local v966 = v296

            if v966 == "japan_malva" then
                v966 = "japan & malva"
            end

            menu.cloud_sources.market_locations_label:visibility(true)

            local v967 = menu.cloud_sources.market_locations:switch(v966)

            local function v968()
                if u91(v967) then
                    get(format(s9, v296), nil, function(p150)
                        if p150 ~= nil and #p150 ~= 0 then
                            local v1338, v1339 = _pcall(u100.decode, p150)

                            if v1338 then
                                local v1340, v1341 = _pcall(u100.decode, v1339, v298)

                                if v1340 then
                                    local v1342, v1343 = _pcall(unpack2, v1341)

                                    if v1342 then
                                        downloaded_sources[v296] = v1343
                                        rebuild_locations()

                                        return
                                    end

                                    return
                                end

                                return
                            end

                            return
                        end
                    end)

                    return
                end

                local v1333 = downloaded_sources[v296] ~= nil

                downloaded_sources[v296] = nil

                if v1333 then
                    rebuild_locations()
                end
            end

            v967:set_callback(v968, true)
            map_changed(v968)
            menu.types.selection:set_callback(v968)
            menu.customization.options:set_callback(v968)

            return
        end
    end)
end

local t70 = {
    weapon_smokegrenade = "Smoke",
    weapon_knife = "Movement",
    weapon_wallbang = "Wallbang",
    weapon_molotov = "Molotov",
    weapon_hegrenade = "HE",
    weapon_decoy = "Decoy",
    weapon_flashbang = "Flashbang",
}
local selection = menu.cloud_sources.selection
local update_selection = menu.cloud_sources.update_selection
local upload_selection = menu.cloud_sources.upload_selection
local selection2 = menu.locations.selection
local active_locations = load_database().active_locations

NadeHelper.active_ref = active_locations

local function v305(_, p152)
    if v95 ~= p152[2] then
        return 0, false
    end

    return p152[3], true
end
local function u306(_)
    local locations = load_database().locations
    local t71 = {}

    for i = 1, #locations do
        local v975 = locations[i]

        t71[#t71 + 1] = (
            active_locations[i] and "\a{Link Active}\239\131\190\aDEFAULT   "
            or "\a{Link Active}\239\133\134\aDEFAULT   "
        ) .. v975.name
    end

    t71[#t71 + 1] = "\a{Link Active}\239\153\158\aDEFAULT  New"
    selection2:update(t71)

    if stable_build then
        local t72 = {}
        local t73 = {}

        t57 = {}
        t58 = {}

        for i = 1, #locations do
            local v979 = locations[i]

            if not v979.nhx_pack and not (type(v979.name) == "string" and v979.name:find("^Default: ")) then
                if not u115(t59, v305)[v979.name] then
                    t72[#t72 + 1] = v979.name
                    t58[#t58 + 1] = i
                end

                t73[#t73 + 1] = v979.name
                t57[#t57 + 1] = i
            end
        end

        update_selection:update(t73)
        upload_selection:update(t72)
        set(selection, u91(selection))
    end

    menu.locations.on_visibility()
end

u306()
cloud_updated(u306)
execute_after(0.01, selection2.set_callback, selection2, function(p154)
    local v981 = u91(p154)
    local v982 = u91(menu.locations.enabled)
    local v983 = active_locations[v981] or false

    if v982 ~= v983 then
        set(menu.locations.enabled, v983)

        return
    end
end, true)
menu.locations.enabled:set_callback(function(p155)
    local v985 = u91(selection2)
    local v986 = u91(p155)

    if v986 ~= (active_locations[v985] or false) then
        active_locations[v985] = v986

        local v987 = load_database()

        v987.active_locations = active_locations
        save_database(v987)
        u306(v987)
        rebuild_locations(v987)

        return
    end
end);
(function()
    local t74 = {
        [1] = {
            [1] = "grenades",
            [2] = "Default: Grenade",
        },
        [2] = {
            [1] = "movements",
            [2] = "Default: Movement",
        },
        [3] = {
            [1] = "wallbangs",
            [2] = "Default: Wallbang",
        },
    }
    local n19 = 0
    local u990 = load_database()
    local locations = u990.locations

    if #locations >= 3 and not u990.defaults_done then
        u990.defaults_done = true
        save_database(u990)
    end

    if not (#locations >= 3) and not u990.defaults_done then
        for i = 1, #t74 do
            local v993 = t74[i]
            local v994 = v993[1]
            local v995 = v993[2]
            local v996 = format("https://northon.dev/neverlose/grenade_helper/%s.json", v994)

            get(v996, nil, function(p156)
                if p156 ~= nil and #p156 ~= 0 then
                    local v1335, v1336 = _pcall(parse, p156)

                    if v1335 and _type(v1336) == "table" then
                        locations[i] = {
                            name = v995,
                            locations = v1336,
                        }
                        n19 = n19 + 1

                        if n19 == #t74 then
                            u990.defaults_done = true
                            save_database(u990)
                            u306(u990)
                            u990 = nil
                            locations = nil

                            return
                        end

                        return
                    end

                    u990 = nil
                    locations = nil

                    return
                end

                u990 = nil
                locations = nil
            end)
        end

        return
    end
end)()

local new_source_name = menu.locations.new_source_name

local function v308(_, p158)
    return p158.name, true
end

menu.locations.create:set_callback(function()
    local v999 = u91(new_source_name)

    if gsub(v999, " ", "") == "" then
        v999 = "Unnamed"
    end

    local v1000 = load_database()
    local locations = v1000.locations
    local v1002 = v999
    local n20 = 2
    local v1004 = u115(locations, v308)

    while v1004[v1002] do
        v1002 = format("%s (%d)", v999, n20)
        n20 = n20 + 1
    end

    locations[#locations + 1] = {
        name = v1002,
        locations = {},
    }
    save_database(v1000)
    u306(v1000)
    new_source_name:reset()
end)

local selection3 = menu.locations.selection

menu.locations.delete_confirm:set_callback(function()
    local v1005 = u91(selection3)
    local v1006 = load_database()
    local locations = v1006.locations

    remove(locations, v1005)

    local act = v1006.active_locations

    for j = v1005, table.maxn(act) do
        act[j] = act[j + 1]
    end

    save_database(v1006)
    u306(v1006)
    rebuild_locations(v1006)
end)

local search = menu.locations.search
local all_maps = menu.locations.all_maps
local locations_selection = menu.locations.locations_selection

local function v313(p159, p160, p161, p162, p163, p164)
    if p159 ~= nil then
        local v1014 = p162 and "[\a{Link Active}%s\aDEFAULT] \a{Link Active}%s:\aDEFAULT %s"
            or "\a{Link Active}%s:\aDEFAULT %s"

        for i = 1, #p159 do
            local v1016 = p159[i]
            local name = v1016.name

            if _type(name) == "table" then
                local v1018 = name[2]

                if v1018 then
                    name = v1018
                end
            end

            if find(lower(name), p161, 1, true) ~= nil then
                local v1019 = #p163 + 1

                p163[v1019] = p162 and format(v1014, p160, t70[v1016.weapon], name)
                    or format(v1014, t70[v1016.weapon], name)
                p164[v1019] = {
                    map_name = p160,
                    index = i,
                    location = v1016,
                }
            end
        end

        return
    end
end
local function u314()
    if editor_state ~= nil then
        local locations = editor_state.source.locations
        local t75 = {
            [1] = "\a{Link Active}\238\146\163\aDEFAULT  New",
        }
        local t76 = {}
        local v1023 = lower(u91(search))
        local v1024 = current_map == nil or u91(all_maps)

        if not v1024 then
            v313(locations[current_map], current_map, v1023, v1024, t75, t76)
        else
            for v1025, v1026 in _next, locations do
                v313(v1026, v1025, v1023, v1024, t75, t76)
            end
        end

        editor_state.selection = t76
        locations_selection:update(t75)

        return
    end
end

menu.locations.search:set_callback(u314)
menu.locations.all_maps:set_callback(u314)

local t84 = nil
local t77 = {
    viewangles = "4",
    weapon = "2",
    position = "3",
    name = "1",
}

local function u317(p165, p166)
    return not ((t77[p166[1]] or p166[1]) <= (t77[p165[1]] or p165[1]))
end

local t78 = {
    edit = render.load_image_from_file("materials\\panorama\\images\\icons\\ui\\edit.svg"),
    warning = render.load_image_from_file("materials\\panorama\\images\\icons\\ui\\warning.svg"),
}

_events.render(function()
    if t84 ~= nil then
        local n21 = 0
        local n22 = 0
        local t79 = {}

        for i = 1, #t84 do
            local v1033 = t84[i]
            local v1034 = _type(v1033[1]) == "string"
            local v1035 = measure_text(1, nil, _select(v1034 and 6 or 5, _unpack(v1033)))
            local x = v1035.x
            local y = v1035.y

            if v1034 then
                x = x + 13
            end

            if n21 < x then
                n21 = x
            end

            t79[i] = n22
            n22 = n22 + y

            if i == 1 then
                n22 = n22 + 2
            end
        end

        local v1038 = u97.x - floor(n21 * 0.5)
        local n23 = 140

        NadeHelper.panel(v1038 - 8, n23 - 5, v1038 + n21 + 8, n23 + n22 + 5, 1, 8)
        rect(_vector(v1038 + 13, n23), _vector(v1038 + 13, n23) + _vector(1, 12), _color())

        for i = 1, #t84 do
            local v1041 = t84[i]

            if _type(v1041[1]) ~= "string" then
                local v1042, v1043, v1044, v1045, v1046 = _unpack(t84[i])

                text(1, _vector(v1038 - 2, n23 + t79[i]), _color(v1042, v1043, v1044, v1045), nil, v1046)
            else
                local v1047, v1048, v1049, v1050, v1051, v1052 = _unpack(v1041)

                texture(t78[v1047], _vector(v1038 - 2, n23 + t79[i]), _vector(12, 12), _color(v1048, v1049, v1050, 255))
                text(1, _vector(v1038 + 13, n23 + t79[i]), _color(v1048, v1049, v1050, v1051), nil, v1052)
            end
        end

        return
    end
end)

local selection4 = menu.locations.selection
local locations_selection2 = menu.locations.locations_selection

local function u321(p167)
    local v1054 = u91(selection4)
    local v1055 = p167 or load_database()
    local locations = v1055.locations
    local active_locations2 = v1055.active_locations

    editing_sources = true
    editor_state = {
        source = locations[v1054],
        source_index = v1054,
        enabled = active_locations2[v1054],
    }
    set(locations_selection2, 1)
    u314()
end

menu.locations.edit:set_callback(function()
    u321()
end)

local t80 = {
    [0] = "Forward",
    Back = 180,
    [-90] = "Right",
    Right = -90,
    Left = 90,
    Forward = 0,
    [180] = "Back",
    [90] = "Left",
}
local t81 = {
    [0] = "Right",
    [1] = "Left",
    [0.5] = "Left / Right",
    ["Left / Right"] = 0.5,
    Right = 0,
    Left = 1,
}
local builder = menu.builder

local function u325()
    local v1058 = get_local_player()

    if v1058 ~= nil and v1058:is_alive() then
        local v1059 = v1058:get_origin()
        local v1060 = camera_angles()
        local m_flDuckAmount = v1058.m_flDuckAmount
        local v1062, v1063 = get_held_weapon(v1058)

        if v1062 ~= nil then
            local location = editor_state.location

            if location.map_name == current_map then
                local v1065 = u91(builder.type)

                if v1063 ~= "weapon_wallbang" or v1065 == "Wallbang" then
                    if v1065 == "Wallbang" then
                        v1063 = "weapon_wallbang"
                    end
                else
                    set(builder.type, "Wallbang")
                end

                local editing = location.editing

                editing.position = {
                    [1] = v1059.x,
                    [2] = v1059.y,
                    [3] = v1059.z,
                }
                editing.viewangles = {
                    [1] = v1060.x,
                    [2] = v1060.y,
                }
                editing.weapon = v1063
                editing.duck = m_flDuckAmount == 1 or nil
                editing.strafer = nil
                rebuild_locations(nil, editor_state)

                return
            end

            return
        end

        return
    end
end

builder.set_location:set_callback(u325)

local sv_cheats = cvar.sv_cheats
local int = sv_cheats.int

local function u328()
    local location = editor_state.location

    if location.map_name == current_map then
        local editing = location.editing
        local position = editing.position
        local viewangles = editing.viewangles
        local weapon = editing.weapon

        if position ~= nil and viewangles ~= nil and weapon ~= nil then
            if weapon == "weapon_molotov" then
                weapon = "weapon_molotov; use weapon_incgrenade"
            end

            local v1072 = int(sv_cheats)

            int(sv_cheats, 1)
            console_exec(
                format(
                    "noclip off; setpos_exact %s %s %s; setang %s %s; use %s",
                    position[1],
                    position[2],
                    position[3],
                    viewangles[1],
                    viewangles[2],
                    weapon
                )
            )
            execute_after(0.01, int, sv_cheats, v1072)

            return
        end

        return
    end
end

menu.builder.teleport:set_callback(u328)

local u329 = nil
local builder2 = menu.builder

local function u331()
    if editor_state ~= nil then
        local location = editor_state.location
        local index = location.index
        local editing = location.editing
        local original = location.original
        local v1077 = u91(builder2.name)
        local v1078 = u91(builder2.description)

        if gsub(v1077, " ", "") == "" then
            v1077 = "Unnamed"
        end

        editing.description = gsub(v1078, " ", "") ~= "" and gsub(gsub(v1078, "^%s+", ""), "%s+$", "") or nil
        editing.name = v1077

        local v1079, v1080 = u91(builder2.type)

        if v1079 ~= "Grenade" then
            if v1079 == "Wallbang" then
                editing.weapon = "weapon_wallbang"
                editing.movement = nil
            end
        else
            if u91(builder2.jump) then
                if not v1080 then
                    v1080 = {}
                end

                v1080.jump = true
            end

            local v1081 = u91(builder2.run)

            if v1081 ~= "Disabled" then
                if not v1080 then
                    v1080 = {}
                end

                v1080.run = u91(builder2.run_duration)

                local v1082 = v1081 == "Custom" and u91(builder2.run_custom) or t80[v1081]

                v1080.run_yaw = v1082 ~= 0 and v1082 or nil
                v1080.run_speed = u91(builder2.run_walk) or nil
            end

            local v1083 = u91(builder2.recovery)

            if v1083 ~= "Disabled" then
                if not v1080 then
                    v1080 = {}
                end

                v1080.recovery_yaw = v1083 == "Custom" and u91(builder2.recovery_custom) or t80[v1083]
                v1080.recovery_jump = u91(builder2.recovery_bunnyhop) or nil
            end

            local v1084 = u91(builder2.strength)

            if v1084 ~= "Left" then
                if not v1080 then
                    v1080 = {}
                end

                v1080.strength = t81[v1084]
            end

            local v1085 = u91(builder2.delay)

            if v1085 > 0 then
                if not v1080 then
                    v1080 = {}
                end

                v1080.delay = v1085
            end

            editing.movement = nil
        end

        editing.grenade = v1080

        local v1086 = editing.position ~= nil and (editing.viewangles ~= nil and editing.weapon ~= nil)

        if not v1086 then
            if index == 0 and not v1086 then
                rebuild_locations()
            end
        else
            rebuild_locations(nil, editor_state)
        end

        local v1087 = false
        local v1088 = u116(editing)
        local v1089 = u116(original)
        local t82 = {}

        for v1091, v1092 in _next, v1088 do
            local v1093 = v1091
            local v1094 = _type(v1092) ~= "table" and _tostring(v1092) or stringify(v1092)
            local v1095 = v1089[v1093]

            if v1093 == "name" and _type(v1095) == "table" then
                local v1096 = v1095[2]

                if v1096 then
                    v1095 = v1096
                end
            end

            local v1097 = v1094 ~= (_type(v1095) ~= "table" and _tostring(v1095) or stringify(v1095))

            if v1097 then
                v1087 = true
            end

            if v1093 ~= "movement.steps" then
                if v1093 == "movement.frames" then
                    v1094 = v1092 ~= nil and #v1092
                    v1093 = "movement"
                end
            else
                v1094 = v1092 ~= nil and #v1092
                v1093 = "movement"
            end

            local t83 = {}
            local v1099 = u101.highlight(v1094, v1097 and {
                [1] = 244,
                [2] = 147,
                [3] = 134,
            } or {
                [1] = 221,
                [2] = 221,
                [3] = 221,
            }, v1097 and {
                [1] = 223,
                [2] = 57,
                [3] = 35,
            } or {
                [1] = 218,
                [2] = 230,
                [3] = 30,
            }, v1097 and {
                [1] = 209,
                [2] = 42,
                [3] = 62,
            } or {
                [1] = 180,
                [2] = 230,
                [3] = 30,
            }, v1097 and {
                [1] = 209,
                [2] = 42,
                [3] = 62,
            } or {
                [1] = 96,
                [2] = 160,
                [3] = 220,
            })

            for i = 1, #v1099 do
                local v1101 = v1099[i]
                local v1102 = v1101[1]
                local v1103 = v1101[2]
                local v1104 = v1101[3]
                local v1105 = v1101[4]

                t83[#t83 + 1] = format("\a%02X%02X%02XFF%s", v1102, v1103, v1104, v1105)
            end

            local v1106 = concat(t83)

            t82[#t82 + 1] = {
                [1] = v1093,
                [2] = v1106,
                [3] = v1097,
            }
        end

        sort(t82, u317)
        t84 = {
            [1] = {
                [1] = "edit",
                [2] = 255,
                [3] = 255,
                [4] = 255,
                [5] = 220,
                [6] = " Editing Location:",
            },
        }

        for _, v1108 in _next, t82 do
            t84[#t84 + 1] = {
                [1] = 255,
                [2] = 255,
                [3] = 255,
                [4] = 220,
                [5] = v1108[1] .. ": " .. v1108[2],
            }
        end

        local weapon = editing.weapon
        local v1110 = weapon == nil or menu.types[weapon]
        local enabled = editor_state.enabled

        if v1087 or not v1110 or not enabled then
            t84[#t84 + 1] = {
                [1] = 255,
                [2] = 255,
                [3] = 255,
                [4] = 255,
                [5] = " ",
            }
        end

        if v1087 then
            t84[#t84 + 1] = {
                [1] = "warning",
                [2] = 234,
                [3] = 64,
                [4] = 18,
                [5] = 220,
                [6] = "You have unsaved changes! Make sure to click Save.",
            }
        end

        if not v1110 then
            t84[#t84 + 1] = {
                "warning",
                234,
                64,
                18,
                220,
                format('Location not shown because type "%s" is not enabled.', t70[weapon]),
            }
        end

        if not enabled then
            t84[#t84 + 1] = {
                "warning",
                234,
                64,
                18,
                220,
                format('Location not shown because source "%s" is not enabled.', editor_state.source.name),
            }
        end

        u329 = #t84 + 1

        return
    end
end

local t85 = {
    teleport = true,
    record = true,
    export = true,
    save = true,
}

local function u333(p168)
    for v1113, v1114 in _next, builder2 do
        if t85[v1113] == nil then
            if not p168 then
                v1114:unset_callback(u331)
            else
                v1114:set_callback(u331)
            end
        end
    end
end

u333(true)
menu.types.selection:set_callback(u331)

local t86 = {}
local v335 = find2("Miscellaneous", "Main", "Movement", "Air Duck")
local v336 = find2("Miscellaneous", "Main", "Movement", "Air Strafe")
local v337 = find2("Miscellaneous", "Main", "Movement", "Quick Stop")
local v338 = find2("Miscellaneous", "Main", "Movement", "Air Strafe", "WASD Strafe")
local v339 = find2("Miscellaneous", "Main", "Movement", "Air Strafe", "Smoothing")
local v340 = find2("Miscellaneous", "Main", "Movement", "Strafe Assist")
local v341 = find2("Miscellaneous", "Main", "Movement", "Edge Jump")
local builder3 = menu.builder
local set_location_hotkey = builder3.set_location_hotkey
local teleport_hotkey = builder3.teleport_hotkey
local get5 = set_location_hotkey.get
local u346 = nil
local u347 = nil

_events.createmove(function(p169)
    if editor_state ~= nil then
        local v1116 = get5(set_location_hotkey)

        if not v1116 or u347 ~= nil then
            if not v1116 then
                u347 = nil
            end
        else
            u347 = true
            u325()
        end

        local v1117 = get5(teleport_hotkey)

        if not v1117 or u346 ~= nil then
            if not v1117 then
                u346 = nil
            end
        else
            u346 = true
            u328()
        end

        if get5(builder3.type) == "Movement" then
            local v1118 = get_local_player()

            if v1118 ~= nil and v1118:is_alive() then
                local editing = editor_state.location.editing
                local start_at = t86.start_at
                local movement = t86.movement

                if get5(builder3.record) then
                    local _, v1123 = get_held_weapon(v1118)
                    local v1124 = v1118:get_origin()
                    local v1125 = camera_angles()
                    local v1126 = v1118.m_vecAbsVelocity:length2d()

                    if start_at == nil and v1126 < 2 then
                        local t87 = {
                            [1] = v1124.x,
                            [2] = v1124.y,
                            [3] = v1124.z,
                        }

                        editing.viewangles = {
                            [1] = v1125.x,
                            [2] = v1125.y,
                        }
                        editing.position = t87
                        editing.weapon = v1123

                        if editing.strafer == nil then
                            editing.strafer = {}
                            editing.strafer.quick_stop = get5(v337)
                            editing.strafer.air_strafe = get5(v336)
                            editing.strafer.wasd_strafer = get5(v338)
                            editing.strafer.strafer_smoothing = get5(v339)
                        end

                        start_at = p169.command_number
                        movement = {
                            steps = {},
                        }

                        local v1128 = t86

                        t86.movement = movement
                        v1128.start_at = start_at
                    end

                    local v1129 = start_at == nil and 0 or p169.command_number - t86.start_at

                    t84[u329] = {
                        234,
                        64,
                        18,
                        220,
                        format("Recorded for %.2fs", _globals.tickinterval * v1129),
                    }

                    if v1129 ~= 0 then
                        u94(v335, false)
                        u94(v336)
                        u94(v340, true)
                        u94(v341, false)

                        local t88 = nil

                        if p169.in_forward then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_forward = true
                        end

                        if p169.in_moveleft then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_moveleft = true
                        end

                        if p169.in_moveright then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_moveright = true
                        end

                        if p169.in_back then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_back = true
                        end

                        if p169.in_duck then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_duck = true
                        end

                        if p169.in_attack then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_attack = true
                        end

                        if p169.in_attack2 then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_attack2 = true
                        end

                        if p169.in_jump then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_jump = true
                        end

                        if p169.in_use then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_use = true
                        end

                        if p169.in_speed then
                            if not t88 then
                                t88 = {}
                            end

                            t88.in_speed = true
                        end

                        local move_yaw = p169.move_yaw
                        local forwardmove = p169.forwardmove
                        local sidemove = p169.sidemove

                        movement.steps[#movement.steps + 1] = {
                            move_yaw = move_yaw,
                            forwardmove = forwardmove ~= 0 and forwardmove or nil,
                            sidemove = sidemove ~= 0 and sidemove or nil,
                            buttons = t88,
                            viewangles = {
                                [1] = v1125.x,
                                [2] = v1125.y,
                            },
                        }

                        return
                    end

                    return
                end

                if movement ~= nil then
                    editing.movement = movement
                    u331()
                end

                t86 = {}

                return
            end

            t86 = {}

            return
        end

        t86 = {}

        return
    end

    t86 = {}
end)

local builder4 = menu.builder
local locations_selection3 = menu.locations.locations_selection

local function u350()
    if editor_state ~= nil then
        u333(false)

        local v1134 = u91(locations_selection3)
        local v1135 = editor_state.selection[v1134]

        if v1135 ~= nil then
            local map_name = v1135.map_name
            local index = v1135.index
            local v1138 = editor_state.source.locations[map_name][index]

            if v1138.movement == nil then
                if v1138.weapon ~= "weapon_wallbang" then
                    set(builder4.type, "Grenade")
                else
                    set(builder4.type, "Wallbang")
                end
            else
                set(builder4.type, "Movement")
            end

            local name = v1138.name
            local v1140 = v1138.description or ""

            if _type(name) == "table" then
                local v1141 = name[2]

                if v1141 then
                    name = v1141
                end
            end

            set(builder4.name, name)
            set(builder4.description, v1140)

            local v1142 = v1138.grenade or {}
            local v1143 = v1142.jump or false

            set(builder4.jump, v1143)

            local run = v1142.run
            local run_yaw = v1142.run_yaw
            local v1146 = v1142.run_speed or false
            local v1147 = run == nil and "Disabled" or (run_yaw == nil and "Forward" or (t80[run_yaw] or "Custom"))

            set(builder4.run, v1147)
            set(builder4.run_custom, run_yaw or 0)
            set(builder4.run_duration, run or 0)
            set(builder4.run_walk, v1146)

            local recovery_yaw = v1142.recovery_yaw
            local v1149 = v1142.recovery_jump or false
            local v1150 = recovery_yaw == nil and "Disabled" or (t80[recovery_yaw] or "Custom")

            set(builder4.recovery, v1150)
            set(builder4.recovery_custom, recovery_yaw or 0)
            set(builder4.recovery_bunnyhop, v1149)

            local v1151 = t81[v1142.strength or 1]

            set(builder4.strength, v1151)

            local v1152 = v1142.delay or 0

            set(builder4.delay, v1152)
            editor_state.location = {
                index = index,
                map_name = current_map,
                editing = copy_table(v1138),
                original = v1138,
            }
            u331()
            u333(true)

            return
        end

        builder4.type:reset()
        builder4.name:reset()
        builder4.description:reset()
        builder4.jump:reset()
        builder4.run:reset()
        builder4.run_custom:reset()
        builder4.run_duration:reset()
        builder4.run_walk:reset()
        builder4.recovery:reset()
        builder4.recovery_custom:reset()
        builder4.recovery_bunnyhop:reset()
        builder4.strength:reset()
        builder4.delay:reset()
        editor_state.location = {
            index = 0,
            map_name = current_map,
            editing = {},
            original = {},
        }
        u331()

        return u333(true)
    end
end

locations_selection3:set_callback(u350)
menu.builder.export:set_callback(function()
    local editing = editor_state.location.editing
    local v1154 = stringify(editing)
    local v1155 = u101.format(v1154, "\n", "  ")

    clipboard.set(v1155)
end)
menu.builder.save:set_callback(function()
    local location = editor_state.location
    local editing = location.editing

    if editing.position ~= nil and editing.viewangles ~= nil and editing.weapon ~= nil then
        local source_index = editor_state.source_index
        local v1159 = load_database()
        local locations = v1159.locations[source_index].locations
        local index = location.index
        local map_name = location.map_name

        if index ~= 0 then
            locations[map_name][index] = editing
        else
            local v1163 = locations[map_name]

            if v1163 == nil then
                v1163 = {}
                locations[map_name] = v1163
            end

            v1163[#v1163 + 1] = editing
        end

        save_database(v1159)
        u321(v1159)
        u350()

        return
    end
end)

local function v351(p170)
    if _type(p170) == "table" then
        local name = p170.name

        if _type(name) == "string" and not (#name <= 0) or _type(name) == "table" and #name == 2 then
            local description = p170.description

            if description == nil or _type(description) == "string" and #description ~= 0 then
                local weapon = p170.weapon

                if _type(weapon) == "string" and #weapon ~= 0 then
                    local position = p170.position

                    if _type(position) ~= "table" or #position ~= 3 then
                        return false, "invalid position"
                    end

                    if
                        _type(position[1]) == "number"
                        and _type(position[2]) == "number"
                        and _type(position[3]) == "number"
                    then
                        local viewangles = p170.viewangles

                        if _type(viewangles) ~= "table" and #viewangles ~= 2 then
                            return false, "invalid viewangles"
                        end

                        if _type(viewangles[1]) == "number" and _type(viewangles[2]) == "number" then
                            local duck = p170.duck

                            if duck == nil or _type(duck) == "boolean" then
                                return true
                            end

                            return false, "invalid duck"
                        end

                        return false, "invalid type in viewangles"
                    end

                    return false, "invalid type in position"
                end

                return false, "invalid weapon"
            end

            return false, "invalid description, expected nil or non-empty string"
        end

        return false, "invalid name, expected string or table of length 2"
    end

    return false, "wrong type, expected table"
end

local t89 = {}

for i = 128, 255 do
    t89[#t89 + 1] = char(i)
end

local u354 = format("[%s]", (concat(t89)))

local function u355(p171)
    return gsub(p171, u354, "")
end
local function v356(p172, p173, p174, p175)
    if _type(p174) == "string" and find(p174, " ") == nil then
        if p173 ~= nil then
            local v1176 = p172[p174]

            if v1176 == nil then
                v1176 = {}
                p172[p174] = v1176
            end

            for i = 1, #p173 do
                local v1178 = p173[i]
                local position = v1178.position
                local viewangles = v1178.viewangles
                local v1181 = p174
                    .. v1178.weapon
                    .. position[1]
                    .. position[2]
                    .. position[3]
                    .. viewangles[1]
                    .. viewangles[2]

                if p175[v1181] ~= nil then
                else
                    local v1182, v1183 = v351(v1178)

                    if not v1182 then
                    else
                        v1176[#v1176 + 1] = v1178
                    end

                    p175[v1181] = i
                end
            end

            return
        end

        return
    end

    return
end

menu.locations.import:set_callback(function()
    local v1184 = clipboard.get()

    if v1184 ~= nil then
        local v1185 = u355(v1184)
        local v1186, v1187 = _pcall(parse, v1185)

        if v1186 and _type(v1187) == "table" then
            local v1188 = sub(v1185, 1, 1) == "["

            if not v1188 and (v1187.name ~= nil or v1187.grenade ~= nil or v1187.weapon ~= nil) then
                v1187 = {
                    [1] = v1187,
                }
                v1188 = true
            end

            local locations = editor_state.source.locations
            local t90 = {}

            for v1191, v1192 in _next, locations do
                for i = 1, #v1192 do
                    local v1194 = v1192[i]
                    local position = v1194.position
                    local viewangles = v1194.viewangles

                    t90[v1191 .. v1194.weapon .. position[1] .. position[2] .. position[3] .. viewangles[1] .. viewangles[2]] =
                        i
                end
            end

            if not v1188 then
                for v1197, v1198 in _next, v1187 do
                    v356(locations, v1198, v1197, t90)
                end
            else
                v356(locations, v1187, current_map, t90)
            end

            local source_index = editor_state.source_index
            local enabled = editor_state.enabled
            local v1201 = load_database()

            v1201.locations[source_index].locations = locations
            save_database(v1201)
            u314()

            if enabled then
                rebuild_locations()
            end

            return
        end

        return
    end

    return
end)

local all_maps2 = menu.locations.all_maps

menu.locations.export:set_callback(function()
    local locations = editor_state.source.locations

    if not u91(all_maps2) or current_map == nil then
        locations = locations[current_map]
    end

    if locations ~= nil and _next(locations) ~= nil then
        local v1203 = stringify(locations)
        local v1204 = u101.format(v1203, "\n", "  ")

        clipboard.set(v1204)

        return
    end
end)

local locations_selection4 = menu.locations.locations_selection

menu.locations.delete_location_confirm:set_callback(function()
    local v1205 = u91(locations_selection4)
    local v1206 = editor_state.selection[v1205]
    local locations = editor_state.source.locations
    local map_name = v1206.map_name
    local index = v1206.index
    local v1210 = locations[map_name]

    remove(v1210, index)

    if #v1210 == 0 then
        locations[map_name] = nil
    end

    local source_index = editor_state.source_index
    local enabled = editor_state.enabled
    local v1213 = load_database()

    v1213.locations[source_index].locations = locations
    save_database(v1213)
    u314()

    if enabled then
        rebuild_locations()
    end

    set(locations_selection4, v1205 - 1)
end)

local locations_selection5 = menu.locations.locations_selection

menu.locations.back:set_callback(function()
    editing_sources = false
    editor_state = nil
    t84 = nil
    locations_selection5:update({})
    rebuild_locations()
end)
