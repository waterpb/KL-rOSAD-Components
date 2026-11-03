-- PF XP: movement + camera in one panel.
--  Movement: speed / jump / gravity, constant speed, no fall damage
--  Camera  : FOV, zoom slowdown fix, recoil / sway / shake cancel (needs mousemoverel)
-- RightShift hides/shows. End = turn the two mouse features off. Home = calibrate the mouse.
-- Safe to re-run (cleans up its previous copy, including the old separate movement and camera panels).
for _, n in ipairs({"PF_CLEANUP", "PF_CAM_CLEANUP", "PF_XP_CLEANUP"}) do
    if getgenv()[n] then pcall(getgenv()[n]) end
end

local UIS, RS, TS, HS = game:GetService("UserInputService"), game:GetService("RunService"),
    game:GetService("TweenService"), game:GetService("HttpService")
local ORIG_GRAVITY = workspace.Gravity
local BASE_SPEED = 26 -- shortcut: PF idle WalkSpeed; constant speed uses this x slider. Change if PF's base differs.
local BASE_JUMP = 3.3 -- PF default jump height in studs
local SAFE_V = 25 -- shortcut: landing speed (studs/s) assumed harmless; lower it if you still take fall damage
local FALL_T = 0.1 -- seconds of fall the slow-down zone covers; zone height = fall speed * this (covers ping/error)

local S = {enabled = true, autoback = true, speed = 1, jump = 1, gravity = ORIG_GRAVITY, constant = false, nofall = true,
    nocd = false, autojump = false, ajms = 0, airjump = false, hl = false, airaccel = 10, hlfric = 8, hlaccel = 14, hlcap = 6, ladder = false, ladreach = 4, surf = false, surfang = 45,
    fov = 1, fix = 0, cancel = 0}
local conns, setters, defaults = {}, {}, {}
local hum, jump0, on = nil, nil, true
local surfing = false -- set by the Surf block; the speed boost, HL movement and fall cap stand down while true

-- ===== persistence (needs executor file functions; silently skipped if missing) =====
local FILE = "pf_xp.json"
-- fix/cancel are not saved: the mouse features always start at 0 until you raise them yourself
local PERSIST = {"enabled", "autoback", "speed", "jump", "gravity", "constant", "nofall", "nocd", "autojump", "ajms", "airjump", "hl", "airaccel", "hlfric", "hlaccel", "hlcap", "ladder", "ladreach", "surf", "surfang", "fov"}
local function save()
    if not writefile then return end
    local t = {}
    for _, k in ipairs(PERSIST) do t[k] = S[k] end
    pcall(writefile, FILE, HS:JSONEncode(t))
end

-- ===== camera state =====
local ref, gameFov, ours = nil, nil, nil -- ref = widest (unzoomed) FOV seen
local zoomNow = 1
local busy, fovConn, hookedCam = false, nil, nil
local lastInj, rem = Vector2.zero, Vector2.zero
local K = 1 -- fraction of injected pixels that Roblox registers (calibrate)
local calib, calibMsg = nil, "ready. press Calibrate once, then raise the mouse sliders"
local lastYaw, lastPitch
-- learning sums (radians per pixel at hipfire), one set per input lag:
-- 0 = this frame's mouse delta, 1 = last frame's (the camera sometimes reacts one frame late; we pick the better fit)
local L = {[0] = {xy = 0, xx = 0, yy = 0, vxy = 0, vxx = 0}, [1] = {xy = 0, xx = 0, yy = 0, vxy = 0, vxx = 0}}
local lagSel, dPrev = 0, Vector2.zero
local autoGain, pauseUntil, notice, noticeAt = 1, 0, "", 0 -- autoGain backs off by itself if the loop gets unstable
local lastShown = Vector2.zero
local DECAY, bad = 0.998, 0
local STEP = "PFXP"

local function near(a, b) return b ~= nil and math.abs(a - b) < 1e-3 end
local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end

-- Calibration: clicking the panel unlocks the mouse, so it can't measure right away. It waits a few
-- seconds, then until the mouse is locked in-game AND hasn't moved for ~20 frames, then sends a known
-- 30px move and checks how much of it Roblox registered.
local function startCalib()
    autoGain = 1
    calib = {phase = "wait", at = os.clock() + 3, start = os.clock(), quiet = 0, frame = 0, sum = 0}
end

-- ===== FOV (float32: tolerance compare + busy flag to avoid re-triggering ourselves) =====
local function applyFov(cam)
    local target = math.clamp(math.deg(2 * math.atan(math.tan(math.rad(gameFov) / 2) * S.fov)), 1, 120)
    ours = target
    busy = true
    cam.FieldOfView = target
    busy = false
end
local function hookCam(cam)
    if fovConn then fovConn:Disconnect() end
    hookedCam = cam
    fovConn = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if busy then return end
        local f = cam.FieldOfView
        if near(f, ours) then return end
        gameFov = f
        if S.enabled then applyFov(cam) end
    end)
end

-- ===== movement logic =====
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function bind(h) -- remember the game's jump so switching off can restore it
    hum, jump0 = h, {use = h.UseJumpPower, power = h.JumpPower}
    rayParams.FilterDescendantsInstances = {h.Parent, workspace.CurrentCamera}
end

conns[#conns + 1] = RS.Stepped:Connect(function()
    local s = workspace.CurrentCamera.CameraSubject
    if s and s:IsA("Humanoid") and s.Parent and s ~= hum then bind(s) end
    if not (hum and hum.Parent) then return end

    if not S.enabled then
        if on then -- just switched off: hand gravity and jump back to the game
            on = false
            workspace.Gravity = ORIG_GRAVITY
            hum.UseJumpPower, hum.JumpPower = jump0.use, jump0.power
        end
        return
    end
    on = true

    if workspace.Gravity ~= S.gravity then workspace.Gravity = S.gravity end

    if S.jump ~= 1 then -- JumpPower = sqrt(2*g*h), so height stays correct at any gravity
        hum.UseJumpPower = true
        hum.JumpPower = math.sqrt(2 * workspace.Gravity * BASE_JUMP * S.jump)
    end

    -- No fall damage: while falling fast, cap fall speed at (distance to ground / FALL_T), floored at SAFE_V.
    -- The cap only bites inside a zone of height (fall speed * FALL_T), so the zone grows with speed,
    -- and speed bleeds off smoothly toward SAFE_V as the ground gets close.
    local root = hum.RootPart
    local v = root and root.AssemblyLinearVelocity
    if S.nofall and not surfing and v and v.Y < -SAFE_V then
        local feet = hum.HipHeight + root.Size.Y / 2
        local hit = workspace:Raycast(root.Position, Vector3.new(0, v.Y * FALL_T - feet, 0), rayParams)
        if hit then
            local cap = math.max(SAFE_V, (hit.Distance - feet) / FALL_T)
            if cap < -v.Y then root.AssemblyLinearVelocity = Vector3.new(v.X, -cap, v.Z) end
        end
    end
end)

local PAUSE_T, RAMP_T = 1, 5
local SNAP_STUDS = 4 -- backward jump in one frame that counts as a rubber band; lower = more sensitive
local pauseEnd, rampEnd, backoffs = 0, 0, 0
local function thr() -- 0 while paused, 0..1 while ramping, 1 normally
    local t = os.clock()
    if t < pauseEnd then return 0 end
    if t < rampEnd then return (t - pauseEnd) / (rampEnd - pauseEnd) end
    return 1
end

local lastPos, avgV, stopFrames, lastTrig, detHum = nil, Vector3.zero, 0, 0, nil
conns[#conns + 1] = RS.Heartbeat:Connect(function(dt)
    if hum ~= detHum then detHum, lastPos, avgV, stopFrames = hum, nil, Vector3.zero, 0 end -- new character
    local root = hum and hum.Parent and hum.RootPart
    if not (S.autoback and S.enabled and root) or hum.Health <= 0 or hum.WalkSpeed <= 0 then lastPos = nil return end
    local pos = root.Position
    if not lastPos or dt <= 0 or dt > 0.1 then lastPos, avgV = pos, Vector3.zero return end
    local d = Vector3.new(pos.X - lastPos.X, 0, pos.Z - lastPos.Z)
    local pv = d / dt -- real movement, whatever caused it
    lastPos = pos
    local rv = root.AssemblyLinearVelocity
    local vh = Vector3.new(rv.X, 0, rv.Z) -- what the client physics thinks you're doing

    -- Only lag / rubber band trips this, never your own stopping or turning (those slow the physics velocity too,
    -- so position and velocity stay in agreement). Two signatures:
    --   snap : position jumped backward (against your recent motion) by more than SNAP_STUDS in one frame
    --   stall: physics says you're moving fast and you're trying to move, but position isn't progressing (3 frames)
    local now, avgSpeed = os.clock(), avgV.Magnitude
    local boosting = thr() > 0 and (S.hl or S.constant or S.speed > 1.05)
    local trig = false
    if boosting and avgSpeed > 12 and now - lastTrig > 2 then
        local dir = avgV.Unit
        local snap = -(d - avgV * dt):Dot(dir) > SNAP_STUDS
        local stalled = false
        if hum.MoveDirection.Magnitude > 0.5 and vh.Magnitude > 12 and pv.Magnitude < vh.Magnitude * 0.15
            and not workspace:Raycast(pos, dir * 3, rayParams) then -- a wall ahead explains a stall
            stopFrames = stopFrames + 1
            stalled = stopFrames >= 3
        else
            stopFrames = 0
        end
        trig = snap or stalled
    else
        stopFrames = 0
    end
    if trig then
        pauseEnd = now + PAUSE_T
        rampEnd = pauseEnd + RAMP_T
        lastTrig, stopFrames, avgV, backoffs = now, 0, Vector3.zero, backoffs + 1
    else
        avgV = avgV * 0.9 + pv * 0.1
    end
end)

-- Speed: WalkSpeed is never touched. PF seems to re-write WalkSpeed relative to its current
-- value, so scaling the property made every multiplier compound (1.1x felt like way more).
-- Instead each frame we add exactly (target - WalkSpeed) * dt of extra distance along the
-- move direction, so 1.1x is a true +10% and 1.0x adds nothing.
conns[#conns + 1] = RS.Heartbeat:Connect(function(dt)
    if S.hl or surfing or not (S.enabled and hum and hum.Parent) then return end
    local root, dir, ws = hum.RootPart, hum.MoveDirection, hum.WalkSpeed
    if not root or ws <= 0 or dir.Magnitude == 0 then return end
    local th = thr()
    if th <= 0 then return end -- backed off: no boost
    local m = 1 + (S.speed - 1) * th -- ramps from normal speed up to the slider
    if not S.constant and math.abs(m - 1) < 1e-4 then return end
    local target = S.constant and BASE_SPEED * m or ws * m
    root.CFrame = root.CFrame + dir * ((target - ws) * dt)
end)

-- Jump extras. We do our own jump, which skips the game's cooldown and ground check. The vertical speed is
-- SET to what a normal jump gives (not added), so it never stacks with the game's own jump.
--   No jump cooldown: tapping space jumps instantly (a tap just before landing is remembered for 0.1s).
--   Auto jump       : holding space jumps again every time you land.
--   Air jump        : every space press in the air gives another jump.
local lastJump, pressedAt = 0, -1
local wasGround, groundSince = false, 0 -- for the Auto jump delay: when did you last touch the ground
local function grounded(root)
    if hum.FloorMaterial ~= Enum.Material.Air then return true end
    -- PF's rig has long legs, so HipHeight says nothing: measure to the lowest part of the character instead
    local ok, cf, size = pcall(function() return hum.Parent:GetBoundingBox() end)
    local drop = (ok and (root.Position.Y - (cf.Position.Y - size.Y / 2)) or 3.5) + 0.4
    return workspace:Raycast(root.Position, Vector3.new(0, -drop, 0), rayParams) ~= nil
end
conns[#conns + 1] = UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.Space then pressedAt = os.clock() end
end)
conns[#conns + 1] = RS.Heartbeat:Connect(function()
    if not ((S.nocd or S.autojump or S.airjump) and S.enabled and hum and hum.Parent) then return end
    local root = hum.RootPart
    if not root or hum.Health <= 0 or hum.WalkSpeed <= 0 or UIS:GetFocusedTextBox() then return end
    local now = os.clock()
    if now - lastJump < 0.12 then return end
    local pressed = now - pressedAt < 0.1
    local go
    local onGround = grounded(root)
    if onGround and not wasGround then groundSince = now end
    wasGround = onGround
    if onGround then
        go = (S.nocd and pressed)
            or (S.autojump and UIS:IsKeyDown(Enum.KeyCode.Space) and now - groundSince >= S.ajms / 1000)
    else
        go = S.airjump and pressed
    end
    if go then
        lastJump, pressedAt, wasGround = now, -1, false
        local v = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(v.X, math.sqrt(2 * workspace.Gravity * BASE_JUMP * S.jump), v.Z)
    end
end)

-- Half-Life movement (GoldSrc / CS 1.3 style). We keep our own horizontal velocity: ground friction + ground
-- acceleration, and Quake air acceleration, which only lets you add speed sideways to your velocity, so turning
-- the mouse while holding A or D in the air builds speed (air strafing). The game's walking is cancelled by
-- moving the character by the gap between our velocity and what the game's physics already did this frame.
-- Max speed = BASE_SPEED * Speed slider. Crouch / sprint / stance speeds are ignored while this is on.
-- Anti-ice: ground state has a short grace window (bumps/slopes flicker FloorMaterial), friction and ground
-- accel are sliders (GoldSrc stock 4 / 10 feels floaty in Roblox), and hlVel resyncs when something blocks you.
local HL_UNITS = 250 -- GoldSrc run speed (units/s) that maps onto BASE_SPEED
local GROUND_GRACE = 0.08 -- seconds the ground state survives a flicker
local hlVel, hlHum, hlLast, groundedAt = Vector3.zero, nil, nil, 0
conns[#conns + 1] = RS.Heartbeat:Connect(function(dt)
    local th = thr()
    if not (S.hl and S.enabled and th > 0 and hum and hum.Parent) then hlHum, hlLast = nil, nil return end
    local root = hum.RootPart
    if not root or hum.Health <= 0 or hum.WalkSpeed <= 0 then hlHum, hlLast = nil, nil return end
    if surfing then hlHum, hlLast = nil, nil return end -- Surf owns the velocity; HL restarts from reality after
    local v = root.AssemblyLinearVelocity
    local vh = Vector3.new(v.X, 0, v.Z)
    if hlHum ~= hum then hlHum, hlVel, hlLast = hum, vh, nil end -- start from whatever the game was doing
    local rawDt = dt
    dt = math.min(dt, 0.05)

    local maxSpeed = BASE_SPEED * (1 + (S.speed - 1) * th)
    local scale = maxSpeed / HL_UNITS -- studs per GoldSrc unit
    local move = hum.MoveDirection
    move = Vector3.new(move.X, 0, move.Z)
    local wishdir = move.Magnitude > 0.01 and move.Unit or Vector3.zero
    local wishspeed = maxSpeed * math.min(move.Magnitude, 1)

    local now = os.clock()
    if v.Y < 2 and grounded(root) then groundedAt = now end
    -- grounded (with grace); jumping this frame = no friction (bhop)
    local onGround = v.Y < 2 and now - groundedAt < GROUND_GRACE and now - lastJump > 0.05

    -- holding space with Auto jump on: the Auto jump delay is just waiting out the server's ground tick, so no
    -- friction/ground accel during it (it would eat your speed before the jump). Air rules keep strafing alive.
    local holdJump = S.autojump and UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:GetFocusedTextBox()

    -- resync: if the game's physics blocked us (player, ledge, wall), our velocity must not keep gliding.
    -- Skipped while Auto jump is holding space: landing contact slows your real movement for a few frames and
    -- would be mistaken for a block, wiping your momentum during the delay.
    if hlLast and rawDt < 0.1 and onGround and not holdJump and hlVel.Magnitude > 4 then
        local r = root.Position - hlLast
        r = Vector3.new(r.X, 0, r.Z) / rawDt
        if r.Magnitude < hlVel.Magnitude * 0.5 then hlVel = r end
    end

    if onGround and not holdJump then
        local speed = hlVel.Magnitude -- friction, stopspeed 100
        if speed > 0.001 then
            local drop = math.max(speed, 100 * scale) * S.hlfric * dt
            hlVel = hlVel * (math.max(speed - drop, 0) / speed)
        end
        local add = wishspeed - hlVel:Dot(wishdir) -- ground accelerate
        if add > 0 then hlVel = hlVel + wishdir * math.min(S.hlaccel * dt * wishspeed, add) end
    else
        local capped = math.min(wishspeed, 30 * scale) -- the 30 unit air cap is what makes strafing work
        local add = capped - hlVel:Dot(wishdir)
        if add > 0 then hlVel = hlVel + wishdir * math.min(S.airaccel * dt * wishspeed, add) end
    end
    local cap = maxSpeed * S.hlcap -- velocity limit: max horizontal speed = Speed x limit slider
    if hlVel.Magnitude > cap then hlVel = hlVel.Unit * cap end

    local disp = (hlVel - vh) * dt
    local len = disp.Magnitude
    if len > 1e-4 then
        local hit = workspace:Raycast(root.Position, disp.Unit * (len + 1.2), rayParams) -- don't walk through walls
        if hit then
            disp = disp.Unit * math.max(math.min(len, hit.Distance - 1.2), 0)
            local n = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
            if n.Magnitude > 0.01 then
                n = n.Unit
                hlVel = hlVel - n * math.min(hlVel:Dot(n), 0) -- slide along the wall
            end
        end
        root.CFrame = root.CFrame + disp
    end
    hlLast = root.Position
end)

-- Ladder assist. Finds ladders (TrussParts, or parts / parent models with "ladder" in the name) and does two things:
--   bigger grab zone: holding toward a ladder within "Ladder reach" pulls you onto its surface
--   no sliding off  : while on a ladder (or pushing into it) you're held against it and can't drift off the sides;
--                     Space lets go. Half-Life momentum is zeroed while stuck so it can't carry you off.
local ladders = {}
do
    local ladderSet, scanned = {}, false
    local LAD_PULL, LAD_STICK, LAD_GAP = 30, 1.2, 0.3 -- pull speed (studs/s), stick distance, gap left to the surface
    local function addLadder(p)
        if ladderSet[p] or not p:IsA("BasePart") then return end
        local par = p.Parent
        if p:IsA("TrussPart") or p.Name:lower():find("ladder", 1, true)
            or (par and par ~= workspace and par.Name:lower():find("ladder", 1, true)) then
            ladderSet[p] = true
            ladders[#ladders + 1] = p
        end
    end
    local function scan()
        for n, d in ipairs(workspace:GetDescendants()) do
            addLadder(d)
            if n % 3000 == 0 then task.wait() end
        end
    end
    conns[#conns + 1] = workspace.DescendantAdded:Connect(function(d) if scanned then addLadder(d) end end)
    conns[#conns + 1] = RS.Heartbeat:Connect(function(dt)
        if not (S.ladder and S.enabled and hum and hum.Parent) then return end
        if not scanned then scanned = true; task.spawn(scan) end
        local root = hum.RootPart
        if not root or hum.Health <= 0 then return end
        local pos, reach = root.Position, S.ladreach
        local bestDist, bestDir = math.huge, nil
        for i = #ladders, 1, -1 do
            local p = ladders[i]
            if not p.Parent then
                ladders[i] = ladders[#ladders]; ladders[#ladders] = nil; ladderSet[p] = nil
            else
                local sz, cf = p.Size, p.CFrame
                if (cf.Position - pos).Magnitude <= sz.Magnitude / 2 + reach + 3 then
                    local up = cf:VectorToObjectSpace(Vector3.yAxis)
                    local ux, uy, uz = math.abs(up.X), math.abs(up.Y), math.abs(up.Z)
                    local vi = (ux >= uy and ux >= uz) and 1 or (uy >= uz and 2 or 3) -- local axis that points up
                    local lp = cf:PointToObjectSpace(pos)
                    local l, sa = {lp.X, lp.Y, lp.Z}, {sz.X, sz.Y, sz.Z}
                    if math.abs(l[vi]) <= sa[vi] / 2 + 0.5 then -- you're at a height the ladder covers
                        local dl = {0, 0, 0} -- horizontal offset from you to the nearest point of the ladder box
                        for k = 1, 3 do
                            if k ~= vi then dl[k] = math.clamp(l[k], -sa[k] / 2, sa[k] / 2) - l[k] end
                        end
                        local dw = cf:VectorToWorldSpace(Vector3.new(dl[1], dl[2], dl[3]))
                        dw = Vector3.new(dw.X, 0, dw.Z)
                        if dw.Magnitude < bestDist then bestDist, bestDir = dw.Magnitude, dw end
                    end
                end
            end
        end
        if not bestDir or bestDist > reach then return end

        local toward = bestDist > 1e-3 and bestDir.Unit or nil
        local want = hum.MoveDirection
        local pushing = toward ~= nil and want:Dot(toward) > 0.3
        local climbing = hum:GetState() == Enum.HumanoidStateType.Climbing
        local stuck = toward ~= nil and bestDist <= LAD_STICK and not UIS:IsKeyDown(Enum.KeyCode.Space)
            and (climbing or pushing)
        if not (toward and (pushing or stuck)) then return end

        local step = math.min(bestDist - LAD_GAP, LAD_PULL * dt)
        if step > 0 then root.CFrame = root.CFrame + toward * step end
        if stuck then
            local v = root.AssemblyLinearVelocity
            local c = v:Dot(-toward) -- speed away from the ladder
            if c > 0 then root.AssemblyLinearVelocity = v + toward * c end
            if S.hl then hlVel = Vector3.zero end
        end
    end)
end

-- Surf. On any surface steeper than "Surf angle" you can't stand: you slide down it frictionlessly (gravity along the
-- plane), and you steer with the keys using Quake air acceleration, so holding A or D into the ramp while turning
-- the mouse gains speed and counters the slide. Flatter surfaces behave normally. Space lets go (use it to jump off).
-- Also lowers the Humanoid's MaxSlopeAngle to the same angle so the game's walking controller doesn't grip the ramp.
local surfRestore = function() end
do
    local slopeHum, slope0, slopeSet = nil, nil, false
    local vPrev, wasSurf = Vector3.zero, false
    surfRestore = function()
        if slopeSet and slopeHum and slopeHum.Parent then pcall(function() slopeHum.MaxSlopeAngle = slope0 end) end
        slopeSet = false
    end
    local function clip(v, n) -- remove the part of v pointing into the surface
        local into = v:Dot(n)
        return into < 0 and v - n * into or v
    end
    conns[#conns + 1] = RS.Heartbeat:Connect(function(dt)
        surfing = false
        if not (hum and hum.Parent) then return end
        if hum ~= slopeHum then surfRestore(); slopeHum, slope0 = hum, hum.MaxSlopeAngle end
        local root = hum.RootPart
        if not (S.surf and S.enabled and root) or hum.Health <= 0 then surfRestore(); wasSurf = false return end
        local want = math.min(slope0, S.surfang)
        if hum.MaxSlopeAngle ~= want then hum.MaxSlopeAngle = want end
        slopeSet = true
        if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:GetFocusedTextBox() then wasSurf = false return end

        local v = root.AssemblyLinearVelocity
        local ok, cf, size = pcall(function() return hum.Parent:GetBoundingBox() end)
        local drop = (ok and (root.Position.Y - (cf.Position.Y - size.Y / 2)) or 3.5) + (wasSurf and 2 or 0.6)
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -drop, 0), rayParams)
        if not hit then wasSurf = false return end
        local n = hit.Normal
        local ang = math.deg(math.acos(math.clamp(n.Y, -1, 1)))
        if ang <= S.surfang or ang > 88 then wasSurf = false return end -- walkable, or a wall

        surfing = true
        dt = math.min(dt, 0.05)
        if not wasSurf then vPrev, wasSurf = v, true end
        local g = Vector3.new(0, -workspace.Gravity, 0)
        -- our own frictionless sim is the truth; if the real velocity strays far from it (hit a wall), follow reality
        if (v - clip(vPrev + g * dt, n)).Magnitude > 8 then vPrev = v end
        local nv = clip(vPrev + g * dt, n)

        local move = hum.MoveDirection
        local wish = Vector3.new(move.X, 0, move.Z)
        if wish.Magnitude > 0.01 then
            local wd = wish.Unit
            local maxSpeed = BASE_SPEED * S.speed
            local wishspeed = maxSpeed * math.min(wish.Magnitude, 1)
            local add = math.min(wishspeed, 30 * maxSpeed / HL_UNITS) - nv:Dot(wd) -- the air cap that makes strafing work
            if add > 0 then nv = clip(nv + wd * math.min(S.airaccel * dt * wishspeed, add), n) end
        end
        vPrev = nv
        root.AssemblyLinearVelocity = nv
    end)
end

-- ===== camera logic (per frame) =====
RS:BindToRenderStep(STEP, Enum.RenderPriority.Last.Value, function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if hookedCam ~= cam then hookCam(cam) end

    local f = cam.FieldOfView
    if not near(f, ours) then gameFov = f end
    if not gameFov then return end
    ref = math.max(ref or gameFov, gameFov)
    zoomNow = math.max(1, math.tan(math.rad(ref) / 2) / math.tan(math.rad(gameFov) / 2))

    if not S.enabled then -- off: give the game its own FOV back and stop touching the mouse
        if ours then
            ours = nil
            busy = true
            cam.FieldOfView = gameFov
            busy = false
        end
        lastYaw, lastInj, rem = nil, Vector2.zero, Vector2.zero
        return
    end
    applyFov(cam)

    -- how far did the camera turn this frame?
    local look = cam.CFrame.LookVector
    local yaw, pitch = math.atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
    local have = lastYaw ~= nil
    local dyaw, dpitch = 0, 0
    if have then
        dyaw, dpitch = wrap(yaw - lastYaw), pitch - lastPitch
        if math.abs(dyaw) > 0.6 or math.abs(dpitch) > 0.6 then have = false end -- teleport / respawn
    end
    lastYaw, lastPitch = yaw, pitch

    local d = UIS:GetMouseDelta()
    local dOld = dPrev
    dPrev = d
    local locked = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
    local prevInj = lastInj
    lastInj = Vector2.zero

    -- calibration (runs before the lock check, because clicking the panel unlocks the mouse)
    if calib then
        if not mousemoverel then
            calibMsg = "mousemoverel missing: can't calibrate (using K=1)"
            calib = nil
        elseif os.clock() - calib.start > 25 then
            calibMsg = "calibration timed out. click back into the game, keep the mouse still, try again"
            calib = nil
        elseif not (locked and have) then
            calib.quiet = 0
            if calib.phase ~= "wait" then calib.phase, calib.frame, calib.sum = "wait", 0, 0 end -- lost the lock
        elseif calib.phase == "wait" then
            if os.clock() < calib.at then calib.quiet = 0
            elseif d.Magnitude < 0.5 then calib.quiet = calib.quiet + 1
            else calib.quiet = 0 end
            if calib.quiet >= 20 then calib.phase = "inject" end
        elseif calib.phase == "inject" then
            mousemoverel(30, 0)
            calib.phase, calib.frame, calib.sum = "measure", 0, 0
        else -- measure: the injected move shows up in the next few frames' mouse delta
            calib.frame = calib.frame + 1
            calib.sum = calib.sum + d.X
            if calib.frame >= 5 then
                local k = calib.sum / 30
                if k > 0.05 and k < 5 then
                    K = k
                    calibMsg = string.format("calibrated (K=%.2f). raise the mouse sliders slowly", K)
                else
                    calibMsg = string.format("calibration failed: only %.1f of 30px registered (keeping K=%.2f)", calib.sum, K)
                end
                calib = nil
            end
        end
        if calib then return end
    end

    if not (locked and mousemoverel and have) then rem = Vector2.zero return end

    -- learn radians-per-pixel at hipfire (unzoomed, little injection), signed per axis, for both lags
    if zoomNow < 1.05 and prevInj.Magnitude < 1 then
        for lag = 0, 1 do
            local m, l = lag == 0 and d or dOld, L[lag]
            if math.abs(m.X) >= 2 then
                l.xy, l.xx, l.yy = l.xy * DECAY + m.X * dyaw, l.xx * DECAY + m.X * m.X, l.yy * DECAY + dyaw * dyaw
            end
            if math.abs(m.Y) >= 2 then l.vxy, l.vxx = l.vxy * DECAY + m.Y * dpitch, l.vxx * DECAY + m.Y * m.Y end
        end
        local function corr(l) return (l.xx > 400 and l.yy > 0) and (l.xy * l.xy) / (l.xx * l.yy) or 0 end
        local c0, c1 = corr(L[0]), corr(L[1])
        if lagSel == 0 and c1 > c0 * 1.2 then lagSel = 1 elseif lagSel == 1 and c0 > c1 * 1.2 then lagSel = 0 end
    end
    local Ls = L[lagSel]
    local rhoX = Ls.xx > 400 and Ls.xy / Ls.xx or nil
    local rhoY = Ls.vxx > 400 and Ls.vxy / Ls.vxx or nil
    local dm = lagSel == 0 and d or dOld -- the mouse delta that the camera actually reacted to

    local inj = Vector2.zero
    local real = d - prevInj * K -- what your hand did (without our own injected movement)

    if S.fix > 0 and zoomNow > 1.02 then
        inj = inj + real * ((zoomNow - 1) * S.fix / K)
    end

    if S.cancel > 0 and rhoX and rhoY and math.abs(rhoX) > 1e-5 and math.abs(rhoY) > 1e-5 then
        local ex, ey = rhoX / zoomNow, rhoY / zoomNow            -- radians per registered pixel right now
        local rYaw = dyaw - ex * dm.X                            -- turning the mouse doesn't explain
        local rPitch = dpitch - ey * dm.Y
        inj = inj + Vector2.new(-rYaw / (ex * K), -rPitch / (ey * K)) * (S.cancel * 0.8 * autoGain)
    end

    if os.clock() < pauseUntil then rem = Vector2.zero return end

    inj = Vector2.new(math.clamp(inj.X, -40, 40), math.clamp(inj.Y, -40, 40))
    local ix, iy = inj.X + rem.X, inj.Y + rem.Y
    local rx, ry = math.floor(ix + 0.5), math.floor(iy + 0.5)
    rem = Vector2.new(ix - rx, iy - ry)

    -- runaway guard: big injections several frames in a row mean the loop is diverging.
    -- Don't touch the sliders: pause briefly and halve the internal gain instead.
    if math.abs(rx) > 30 or math.abs(ry) > 30 then bad = bad + 1 else bad = math.max(0, bad - 1) end
    if bad >= 4 then
        bad, rem = 0, Vector2.zero
        autoGain = math.max(0.15, autoGain * 0.5)
        pauseUntil = os.clock() + 0.5
        notice, noticeAt = string.format("mouse loop was unstable: backed off to gain %.2f", autoGain), os.clock()
        return
    end
    lastShown = Vector2.new(rx, ry)
    if rx ~= 0 or ry ~= 0 then
        mousemoverel(rx, ry)
        lastInj = Vector2.new(rx, ry)
    end
end)

-- ===== UI (style: dark see-through panel, square corners, monospace, blue accent) =====
local BG, TEXT, MUTED = Color3.fromRGB(23, 22, 22), Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)
local BTN, ACCENT = Color3.fromRGB(62, 60, 55), Color3.fromRGB(91, 155, 213)
local OFF, KNOB_OFF, KNOB_ON = Color3.fromRGB(17, 17, 17), Color3.fromRGB(207, 207, 207), Color3.fromRGB(222, 235, 246)
local BLACK = Color3.new(0, 0, 0)
local FONT = Enum.Font.Code

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    i.Parent = parent
    return i
end
local function outline(i, color)
    new("UIStroke", {Color = color, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, i)
end
local function label(parent, str, props)
    local p = {BackgroundTransparency = 1, Text = str, TextColor3 = TEXT, Font = FONT, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left}
    for k, v in pairs(props or {}) do p[k] = v end
    return new("TextLabel", p, parent)
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end

local gui = new("ScreenGui", {Name = "PFXP", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling},
    (gethui and gethui()) or game:GetService("CoreGui"))
local W, H, HEAD = 300, 460, 36
local main = new("Frame", {Size = UDim2.fromOffset(W, H), Position = UDim2.new(0, 40, 0.5, -H / 2),
    BackgroundColor3 = BG, BackgroundTransparency = 0.2, BorderSizePixel = 0, ClipsDescendants = true}, gui)
new("UIStroke", {Color = BLACK, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, main)

-- header: title left, minimize + close right, thin white line under it
local header = new("Frame", {Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1}, main)
label(header, '<font color="rgb(91,155,213)">&gt;</font>KL // PF XP',
    {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -80, 1, 0), TextSize = 16, RichText = true})
new("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = TEXT, BorderSizePixel = 0}, header)
local function headBtn(x, str)
    local b = new("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 4), Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = BTN, Text = str, TextColor3 = TEXT, Font = FONT, TextSize = 14, BorderSizePixel = 0}, header)
    outline(b, TEXT)
    return b
end
local closeBtn, minBtn = headBtn(-4, "x"), headBtn(-32, "-")

-- body: scrolls, so every control stays full size
local body = new("ScrollingFrame", {Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 1, -HEAD),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = TEXT,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y}, main)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, body)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10)}, body)
local order = 0
local function row(h)
    order = order + 1
    return new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = order}, body)
end
local function caption(str) label(row(14), str, {Size = UDim2.fromScale(1, 1), TextSize = 11, TextColor3 = MUTED}) end

-- dragging (one active drag function: window or slider); saves once on release
local drag
conns[#conns + 1] = UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        drag(i.Position)
    end
end)
conns[#conns + 1] = UIS.InputEnded:Connect(function(i)
    if isPress(i) and drag then drag = nil; save() end
end)
header.InputBegan:Connect(function(i)
    if isPress(i) then
        local s0, p0 = i.Position, main.Position
        drag = function(p)
            local d = p - s0
            main.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
        end
    end
end)

local function addSlider(name, key, min, max, step, fmt)
    local r = row(44)
    label(r, name, {Size = UDim2.new(1, -64, 0, 18)})
    local box = new("Frame", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(58, 18),
        BackgroundColor3 = BLACK, BackgroundTransparency = 0.5, BorderSizePixel = 0}, r)
    local val = label(box, "", {Size = UDim2.new(1, -6, 1, 0), TextXAlignment = Enum.TextXAlignment.Right})
    local track = new("Frame", {Position = UDim2.fromOffset(6, 29), Size = UDim2.new(1, -12, 0, 4),
        BackgroundColor3 = BLACK, BorderSizePixel = 0}, r)
    local fill = new("Frame", {Size = UDim2.fromScale(0, 1), BackgroundColor3 = TEXT, BorderSizePixel = 0}, track)
    local knob = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = TEXT, BorderSizePixel = 0, ZIndex = 2}, track)
    outline(knob, Color3.fromRGB(127, 127, 127))
    local hit = new("TextButton", {Size = UDim2.new(1, 12, 0, 24), Position = UDim2.new(0, -6, 0.5, -12),
        BackgroundTransparency = 1, Text = "", ZIndex = 3}, track)

    local function set(v)
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        v = math.floor(v * 1000 + 0.5) / 1000 -- strip float noise (1.1500000001 etc.)
        S[key] = v
        local a = (v - min) / (max - min)
        fill.Size, knob.Position = UDim2.fromScale(a, 1), UDim2.fromScale(a, 0.5)
        val.Text = string.format(fmt, v)
        if key == "fix" or key == "cancel" then bad, rem = 0, Vector2.zero end
    end
    local function fromPos(p)
        set(min + math.clamp((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1) * (max - min))
    end
    hit.InputBegan:Connect(function(i)
        if isPress(i) then drag = fromPos; fromPos(i.Position) end
    end)
    setters[key], defaults[key] = set, S[key]
    set(S[key])
end

local function addSwitch(name, key)
    local r = row(22)
    label(r, name, {Size = UDim2.new(1, -44, 1, 0)})
    local sw = new("TextButton", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(36, 18),
        BackgroundColor3 = OFF, Text = "", AutoButtonColor = false, BorderSizePixel = 0}, r)
    local knob = new("Frame", {Size = UDim2.fromOffset(18, 18), BackgroundColor3 = KNOB_OFF, BorderSizePixel = 0}, sw)
    local function set(v)
        S[key] = v
        local t = TweenInfo.new(0.12)
        TS:Create(sw, t, {BackgroundColor3 = v and ACCENT or OFF}):Play()
        TS:Create(knob, t, {Position = UDim2.fromOffset(v and 18 or 0, 0), BackgroundColor3 = v and KNOB_ON or KNOB_OFF}):Play()
    end
    sw.MouseButton1Click:Connect(function() set(not S[key]); save() end)
    setters[key], defaults[key] = set, S[key]
    set(S[key])
end

addSwitch("Enabled", "enabled")
addSwitch("Auto back-off", "autoback")

caption("// movement")
addSlider("Speed", "speed", 0.5, 6, 0.05, "%.2fx")
addSlider("Jump", "jump", 0.5, 6, 0.05, "%.2fx")
addSlider("Gravity", "gravity", 10, 400, 1, "%.0f")
addSwitch("Constant speed", "constant")
addSwitch("No fall damage", "nofall")
addSwitch("No jump cooldown", "nocd")
addSwitch("Auto jump (hold space)", "autojump")
addSlider("Auto jump delay", "ajms", 0, 200, 10, "%.0fms")
addSwitch("Air jump", "airjump")
addSwitch("Half-Life movement", "hl")
addSlider("HL ground friction", "hlfric", 1, 20, 0.5, "%.1f")
addSlider("HL ground accel", "hlaccel", 1, 40, 0.5, "%.1f")
addSlider("HL air accel", "airaccel", 1, 100, 1, "%.0f")
addSlider("HL velocity limit", "hlcap", 1, 10, 0.1, "%.1fx")
addSwitch("Ladder assist", "ladder")
addSlider("Ladder reach", "ladreach", 1, 10, 0.5, "%.1f")
addSwitch("Surf", "surf")
addSlider("Surf angle", "surfang", 20, 85, 1, "%.0f deg")

caption("// camera")
addSlider("FOV", "fov", 0.6, 1.8, 0.02, "%.2fx")
addSlider("Zoom slowdown fix", "fix", 0, 1.5, 0.05, "%.2f")
addSlider("Recoil / sway cancel", "cancel", 0, 1, 0.05, "%.2f")

local br = row(26)
local function button(pos, str)
    local b = new("TextButton", {Position = pos, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = BTN, Text = str,
        TextColor3 = TEXT, Font = FONT, TextSize = 13, BorderSizePixel = 0}, br)
    outline(b, TEXT)
    return b
end
local calBtn = button(UDim2.fromScale(0, 0), "Calibrate")
local resetBtn = button(UDim2.new(0.5, 3, 0, 0), "Reset all")
calBtn.MouseButton1Click:Connect(startCalib)
resetBtn.MouseButton1Click:Connect(function()
    for k, set in pairs(setters) do
        if k ~= "enabled" then set(defaults[k]) end -- Reset leaves the master switch alone
    end
    autoGain = 1
    save()
end)

local status = label(row(44), "", {Size = UDim2.fromScale(1, 1), TextSize = 11, TextColor3 = MUTED, TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top})
label(row(14), "RightShift hide | End mouse panic | Home calibrate", {Size = UDim2.fromScale(1, 1), TextSize = 10, TextColor3 = MUTED})

-- close = full cleanup, minimize = collapse to the title bar
local mini = false
minBtn.MouseButton1Click:Connect(function()
    mini = not mini
    body.Visible = not mini
    main.Size = UDim2.fromOffset(W, mini and HEAD or H)
end)

conns[#conns + 1] = RS.Heartbeat:Connect(function()
    if calib then
        if not S.enabled then
            status.Text = "turn Enabled on to calibrate"
        elseif calib.phase == "wait" then
            status.Text = "calibrating: click back into the game (mouse locked) and keep the mouse still..."
        else
            status.Text = "measuring... keep the mouse still"
        end
    elseif L[lagSel].xx <= 400 or L[lagSel].vxx <= 400 then
        status.Text = string.format("learning your mouse... %d%% (move it around)",
            math.floor(100 * math.min(L[lagSel].xx, L[lagSel].vxx) / 400))
    else
        local msg = (os.clock() - noticeAt < 6) and notice or calibMsg
        status.Text = string.format("%s\nlag %d | gain %.2f | last push %d,%d px", msg, lagSel, autoGain, lastShown.X, lastShown.Y)
    end
    if S.surf and surfing then status.Text = status.Text .. "\nsurfing" end
    if S.ladder then status.Text = status.Text .. "\nladders found: " .. #ladders end
    local th = thr()
    if th < 1 then
        status.Text = status.Text .. (th == 0 and "\nback-off: boosts paused" or string.format("\nback-off: ramping %d%%", th * 100))
    end
end)
conns[#conns + 1] = UIS.InputBegan:Connect(function(i, gp)
    if i.KeyCode == Enum.KeyCode.End then setters.fix(0) setters.cancel(0) end
    if not gp and i.KeyCode == Enum.KeyCode.Home then startCalib() end
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
end)

-- load saved settings last, so Reset still goes to the true defaults
if readfile and isfile and isfile(FILE) then
    local ok, d = pcall(function() return HS:JSONDecode(readfile(FILE)) end)
    if ok and type(d) == "table" then
        for _, k in ipairs(PERSIST) do
            local v = d[k]
            if type(v) == type(S[k]) then setters[k](v) end -- sliders clamp to their range
        end
    end
end

getgenv().PF_XP_CLEANUP = function()
    pcall(function() RS:UnbindFromRenderStep(STEP) end)
    if fovConn then fovConn:Disconnect() end
    local cam = workspace.CurrentCamera
    if cam and gameFov then pcall(function() cam.FieldOfView = gameFov end) end
    for _, c in ipairs(conns) do c:Disconnect() end
    workspace.Gravity = ORIG_GRAVITY
    surfing = false
    surfRestore()
    if hum and jump0 then pcall(function() hum.UseJumpPower, hum.JumpPower = jump0.use, jump0.power end) end
    gui:Destroy()
    getgenv().PF_XP_CLEANUP = nil
end
closeBtn.MouseButton1Click:Connect(getgenv().PF_XP_CLEANUP)
