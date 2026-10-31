-- Roblox Client Lighting Utility Tool (V9)
-- V9: fog sliders work again (neutral Atmosphere no longer kept in Lighting), read-spoof layer
--     (needs hookmetamethod/newcclosure/checkcaller; skipped silently if missing), generic effect
--     names, Override Lock is event-driven (+10 Hz safety poll) instead of per-frame, re-run cleanup.
-- Place inside StarterPlayer -> StarterPlayerScripts (or StarterGui) as a LocalScript
--
-- CHANGELOG FROM V8.5 (Real Camera Blur autofocus restructure):
--   * Removed the "In Front of Character" autofocus target and all its settings.
--   * Autofocus is now split into "3rd Person AF" and "1st Person AF" (one shared
--     builder). Each has its own target: Auto Focus Box/Circle (default) or Center
--     of Screen, and its own box/circle setup.
--   * NEW per camera mode: "Focus Any Person Touching the Area" (3rd: closest person,
--     1st: person nearest the area centre) -- ignores the Focus On slider.
--   * 3rd person only: Ignore Self; Focus on Self After Inactivity (+ new Transition
--     Time fader that replaces the normal autofocus speed for that one move); and
--     Pitch-Based Focus Area (area moves proportionally with camera pitch).
--   * Global options, in order: Momentary Focus Override, Cursor Auto Focus (ON/OFF +
--     optional hotkey; replaces the old "Cursor" target), Player Autofocus (range now
--     10..200 studs), Lens Options, Autofocus Speed, Transition Curve Options, Reset,
--     Save/Load Autofocus Presets.
--   * Saved settings and focus presets from v8.5 are migrated automatically (the old
--     single setup becomes both the 3rd and 1st person setup; "Cursor" target ->
--     Cursor Auto Focus ON).
--   * Autofocus ignores anything closer than 1.5 studs to the camera (character touching /
--     inside the camera, viewmodels, props against the lens) and focuses on what is behind it.
--   * Internals: camera mode is read once per frame; inactivity tracking does no work
--     while it is Off; the two area/momentary overlays share one GUI + one RenderStepped
--     loop; control visibility is declarative (one refresh function).
--
-- CHANGELOG FROM V8.4 (stability / performance pass):
--   * Override Lock loop now writes a property ONLY when it actually differs
--     (it used to rewrite ~45 Lighting/effect properties every rendered frame,
--     including Technology / GlobalShadows / Atmosphere / Environment scales,
--     which can make the engine re-do expensive lighting work).
--   * "Remember Last Lighting": autosave every 10 s (was 3 s) and ONLY when the
--     state really changed (it rewrote the file every 3 s on an HDD).
--   * Real Camera Blur settings save is now a trailing 1 s debounce (it used to
--     write the whole settings file ~1x/second WHILE you dragged a slider).
--   * Live-sync no longer rewrites ~60 sliders' text/position 5x/second when
--     nothing changed, and skips the UI refresh entirely while the window is hidden.
--   * Re-running the script no longer stacks loops / GUIs / file writers from
--     the previous run (single-instance guard + connection registry).
--   * Raycasts reuse RaycastParams objects; per-frame CFrame reads are cached.
--   * Overlays do no per-frame work while hidden.
--   * NEW (opt-in, off by default): Performance Monitor in the Utilities section --
--     shows script CPU per frame, rays/s, file writes, and for every frame hitch
--     whether the script or Roblox/system was responsible.
--
-- CHANGELOG FROM V8.3:
--   * Added (Real Camera Blur): "After inactivity, focus on self" (0 = Off,
--     1-10 s; counts character movement, or character + camera pan/zoom --
--     never just cursor movement; only when zoomed out / not first person).
--   * Added: Ignore Self for normal autofocus target detection.
--   * Added: Momentary Focus Override -- hold a customizable key/mouse button
--     to force focus to a screen-centre circle (adjustable size); choose when
--     it is active (mouse locked / 3rd person, first person only, or both).
--   * Focus priority: 1) momentary override, 2) focus on self after
--     inactivity, 3) normal autofocus. The existing Real Camera Blur toggle
--     is still the master ON/OFF.
--
-- CHANGELOG FROM V8.2:
--   * Added: Focus Box / Circle autofocus target (Real Camera Blur). Define a
--     screen-space box or circle (X/Y -100..100, Length/Width or Radius 0..50),
--     and "Focus On" 20..80 picks the nearer / middle / farther surfaces seen
--     inside it. The region is shown live while you drag or hover its sliders.
--   * Added: separate Focus Presets (save / load / overwrite / rename / delete),
--     stored in _focus_presets.json -- NOT mixed with lighting presets.
--
-- CHANGELOG FROM V8 (this build):
--   * Added: "Real Camera Blur" section -- an automatic controller layered on
--     Roblox's EXISTING DepthOfFieldEffect (no custom blur). Autofocus target
--     (cursor / screen center / cone in front of character), player-focus
--     override, thin-lens focus-range + foreground/background blur model,
--     time/distance-mixed focus transitions (Linear or Logarithmic) and
--     stability filtering. While ON it overrides DoF; OFF restores the normal
--     DoF exactly. Its settings persist in _settings.json, never in presets;
--     the calculated runtime DoF values are never saved anywhere.
--   * Added: Automatic Exposure Compensation (AE) and Automatic White Balance
--     (AWB) sliders in View Offsets. They are extra layers added on top of
--     base + manual offset (the manual Exposure / White Balance / Tint offsets
--     are untouched). Scene metering is APPROXIMATED from camera raycasts +
--     Lighting info, since a LocalScript cannot read rendered pixels.
--   * Internal: DoF reads/writes in captureState/applyState/neutralize go
--     through CamSys.getDoF/setDoF so presets, Override and Reset always see
--     the NORMAL DoF config. createSlider gained optional fmt + .Container.
--
-- CHANGELOG FROM V7:
--   * Added: dedicated White Balance (warm/cool) and Tint (green/magenta)
--     sliders in Ambient & Color -- these write into the SAME existing
--     CC_TintColor state field as before, so old presets/JSON exports are
--     unaffected and load exactly as they did before this change
--
-- CHANGELOG FROM V6:
--   * Added: Import/Export -- export current lighting or ALL custom presets
--     as text (JSON, or a compact multi-config format), and import either
--     back in. No official clipboard-write API exists for live games, so
--     export pre-selects the text for you to Ctrl+C, and import is a
--     paste-and-click box (see the note in that section)
--   * Added: DisplayOrder maxed out so the window renders above other
--     PlayerGui-level UI (can't render above Roblox's own CoreGui though --
--     nothing scriptable can)
--   * Added: minimize button -- collapses to a small draggable icon
--   * Added: "Reset to Server Defaults" with a confirm popup, restoring the
--     exact Lighting values the server/developer had before this script
--     touched anything (snapshotted at the very top of the script)
--
-- CHANGELOG FROM V5:
--   * Added: real cross-session preset persistence via DataStoreService,
--     through the new companion server script (see above)
--
-- CHANGELOG FROM V5:
--   * Added: real cross-session preset persistence via DataStoreService,
--     through the new companion server script:
--       1. Put LightingUtilityPresetsServer.lua into ServerScriptService.
--       2. Game Settings > Security > "Enable Studio Access to API
--          Services" must be ON to test in Studio (live published games
--          have this on by default).
--       3. This script talks to that server script over a RemoteEvent /
--          RemoteFunction. Without it installed, Custom Presets still
--          work but fall back to session-only.
--   * Roblox sandboxes the live client completely -- there's no "AppData"
--     or disk access available to a LocalScript, hence the server-script
--     requirement above; that's how Roblox's security model works, not a
--     gap in this script.
--
-- CHANGELOG FROM V4:
--   * Fixed: DepthOfFieldEffect/Atmosphere/BloomEffect are now forced to a
--     true neutral state on load (Roblox's factory defaults for these are
--     NOT off, which was causing an unexpected blur/haze on script start)
--   * Added: Custom Presets section (bottom) -- name, save, load, and
--     delete your own lighting looks.
--
-- CHANGELOG FROM V3:
--   * Fixed: dragging the window no longer fights with slider/button clicks
--     (only the title bar is draggable now, not the whole frame)
--   * Fixed: scroll canvas now auto-sizes instead of a hardcoded 1400px guess
--   * Added: collapsible sections so the much longer control list stays usable
--   * Added: Ambient / OutdoorAmbient / ColorShift Top&Bottom / ExposureCompensation
--   * Added: Technology switcher (Voxel / ShadowMap / Compatibility / Future)
--             + EnvironmentDiffuseScale / EnvironmentSpecularScale
--             (this is the closest thing Roblox has to "ambient occlusion" --
--              see the NOTE further down, there is no direct AO property)
--   * Added: Atmosphere object controls (Density, Offset, Color, Decay, Glare, Haze)
--   * Added: Bloom / Blur / DepthOfField post-effects
--   * Added: Skybox changer -- manual 6-face asset ID entry AND a preset list
--   * Added: Auto Fog Color -- samples the skybox and averages its color at
--            50% / 75% / 100% coverage. READ THE NOTE ABOVE THAT SECTION,
--            this only works under specific asset-ownership conditions.

local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- ============================================================
-- Single-instance guard. Re-running this script used to leave the previous
-- run's loops, GUIs and file writers alive underneath the new one, so
-- everything stacked up (duplicate autosaves, duplicate lock loops, ...).
-- Every service-level connection is now registered (CamSys.track) so the next
-- run can disconnect them; GUIs are swept by name (this also catches GUIs
-- left by builds that predate this guard).
-- ============================================================
do
	local env = (type(getgenv) == "function" and getgenv()) or _G
	if type(env.__LiUtCleanup) == "function" then
		pcall(env.__LiUtCleanup)
	end
	local guiNames = {"LightingUtility", "LightingUtilityFocusArea", "LightingUtilityMomentaryCircle"}
	local parents = {
		function() return type(gethui) == "function" and gethui() or nil end,
		function() return game:GetService("CoreGui") end,
		function() return Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end,
	}
	local function sweep()
	for _, getParent in ipairs(parents) do
		local okP, parent = pcall(getParent)
		if okP and parent then
			for _, n in ipairs(guiNames) do
				-- bounded: if the runtime refuses to destroy one, never spin forever
				for _ = 1, 8 do
					local g = parent:FindFirstChild(n)
					if not g then break end
					pcall(function() g:Destroy() end)
				end
			end
		end
	end
	end
	env.__LiUtSweep = sweep
	sweep()
	local conns = {}
	env.__LiUtConns = conns
	env.__LiUtCleanup = function()
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(conns)
		if type(env.__LiUtRelease) == "function" then pcall(env.__LiUtRelease) end
		env.__LiUtRelease = nil
		env.__LiUtCleanup = nil
	end
end

-- Snapshot the developer/server's real Lighting setup BEFORE this script
-- touches anything. This is what "Reset to Server Defaults" restores --
-- it has to be captured right here, at the very top, or it would just be
-- capturing our own script's changes instead of the original values.
local serverDefaultLighting = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	GlobalShadows = Lighting.GlobalShadows,
	FogStart = Lighting.FogStart,
	FogEnd = Lighting.FogEnd,
	FogColor = Lighting.FogColor,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Ambient = Lighting.Ambient,
	ColorShift_Top = Lighting.ColorShift_Top,
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ExposureCompensation = Lighting.ExposureCompensation,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	Technology = Lighting.Technology,
}

-- ============================================================
-- Configuration & State
-- ============================================================
local lockLighting = false
local lockedSettings = {}

-- >>> Fill these in with your own skybox asset IDs (numbers only, no quotes
-- needed but strings work too e.g. "123456789"). These are used by the
-- "Preset" buttons in the Skybox section. Leave any face blank ("") to
-- leave that face unchanged when the preset is applied.
local SKYBOX_PRESETS = {
	{
		Name = "Preset Slot 1 (edit me)",
		Bk = "", Dn = "", Ft = "", Lf = "", Rt = "", Up = "",
	},
	{
		Name = "Preset Slot 2 (edit me)",
		Bk = "", Dn = "", Ft = "", Lf = "", Rt = "", Up = "",
	},
	{
		Name = "Preset Slot 3 (edit me)",
		Bk = "", Dn = "", Ft = "", Lf = "", Rt = "", Up = "",
	},
}

-- ============================================================
-- Ensure Effects / Objects Exist in Lighting
-- ============================================================
-- getOrCreateEffect(className, name) -> effect, wasCreated
--
-- IMPORTANT FIX: this used to look ONLY for a child named exactly `name`
-- (e.g. "ClientAtmosphere"), and create a brand new instance if that exact
-- name wasn't found -- even if the game's OWN Atmosphere/Bloom/etc already
-- existed under its default name. Several of these effect types behave as
-- singletons in Roblox (only one instance of the class meaningfully takes
-- effect), so quietly parenting a second, neutral one next to the
-- developer's real one could override/replace it the instant this script
-- ran -- this is what was causing lighting to visibly change on load even
-- when nothing had been touched yet.
--
-- Fix: first look for ANY existing instance of this class already under
-- Lighting (the developer's own, or ours from an earlier run) and adopt
-- it as-is -- its current property values become the baseline, untouched.
-- Only create a brand new instance (and only THEN neutralize it) when
-- nothing of that class exists yet at all.
local function getOrCreateEffect(className, name)
	local existing = Lighting:FindFirstChildOfClass(className)
	if existing then
		return existing, false -- adopted -- do NOT neutralize this
	end
	local effect = Instance.new(className)
	effect.Name = className -- default class name, not a "Client..." tell
	-- A parented Atmosphere (even at Density 0) switches OFF Lighting.FogStart/FogEnd/FogColor.
	-- Ours stays unparented until it has something to show (see the sync block below).
	if className ~= "Atmosphere" then effect.Parent = Lighting end
	return effect, true -- freshly created -- Roblox's factory defaults for
	                     -- these are NOT neutral, so this DOES need it
end

local colorCorrection, colorCorrectionWasCreated = getOrCreateEffect("ColorCorrectionEffect", "ClientColorCorrection")
local sunRays, sunRaysWasCreated = getOrCreateEffect("SunRaysEffect", "ClientSunRays")
local atmosphere, atmosphereWasCreated = getOrCreateEffect("Atmosphere", "ClientAtmosphere")
local bloom, bloomWasCreated = getOrCreateEffect("BloomEffect", "ClientBloom")
local blur, blurWasCreated = getOrCreateEffect("BlurEffect", "ClientBlur")
local depthOfField, depthOfFieldWasCreated = getOrCreateEffect("DepthOfFieldEffect", "ClientDepthOfField")

-- Snapshot the REAL starting values of any adopted (pre-existing) effect
-- right now, before anything touches them. neutralizeCustomEffects() uses
-- this as the true baseline for adopted effects (instead of zero), and
-- "Reset to Server Defaults" restores to this snapshot rather than
-- whatever happens to be live at the moment Reset is clicked.
local adoptedEffectDefaults = {
	CC = (not colorCorrectionWasCreated) and {
		Brightness = colorCorrection.Brightness,
		Contrast = colorCorrection.Contrast,
		Saturation = colorCorrection.Saturation,
		TintColor = colorCorrection.TintColor,
	} or nil,
	SunRays = (not sunRaysWasCreated) and {
		Intensity = sunRays.Intensity,
		Spread = sunRays.Spread,
		Enabled = sunRays.Enabled,
	} or nil,
	Atmosphere = (not atmosphereWasCreated) and {
		Density = atmosphere.Density,
		Offset = atmosphere.Offset,
		Glare = atmosphere.Glare,
		Haze = atmosphere.Haze,
		Color = atmosphere.Color,
		Decay = atmosphere.Decay,
	} or nil,
	Bloom = (not bloomWasCreated) and {
		Intensity = bloom.Intensity,
		Threshold = bloom.Threshold,
		Size = bloom.Size,
	} or nil,
	Blur = (not blurWasCreated) and {
		Size = blur.Size,
	} or nil,
	DepthOfField = (not depthOfFieldWasCreated) and {
		FarIntensity = depthOfField.FarIntensity,
		NearIntensity = depthOfField.NearIntensity,
		InFocusRadius = depthOfField.InFocusRadius,
		FocusDistance = depthOfField.FocusDistance,
	} or nil,
}

-- ============================================================
-- Camera System shared state (Real Camera Blur + Auto Exposure / White
-- Balance). Deliberately ONE table: this script sits right at Luau's
-- 200-locals-per-function limit, so new top-level locals would stop it from
-- compiling.
--   CamSys.dofActive      true while Real Camera Blur owns the DepthOfFieldEffect
--   CamSys.dofBase        the NORMAL (game / config / preset) DoF values while it does
--   CamSys.autoExposureEV / autoWB / autoTint
--                         automatic correction layers, added on top of base + offset
-- ============================================================
local CamSys = {
	dofActive = false,
	dofBase = {},
	autoExposureEV = 0,
	autoWB = 0,
	autoTint = 0,
	tintMulR = 1, tintMulG = 1, tintMulB = 1, -- post-process TintColor RGB multipliers
	lockDirty = true, lockAccum = 0,          -- Override Lock: re-apply only when something changed
}

-- Connection registry + optional timing (see the single-instance guard above)
CamSys.conns = ((type(getgenv) == "function" and getgenv()) or _G).__LiUtConns or {}
CamSys.perf = {on = false, rays = 0, writes = 0, frameMs = 0, mods = {}, hitches = 0, lastHitch = nil}
CamSys.nextName = nil

-- Wrap a callback so its CPU time is recorded while the Performance Monitor is on.
-- (When the monitor is off this is just one table read per call.)
function CamSys.timed(name, fn)
	return function(...)
		local pf = CamSys.perf
		if not pf.on then return fn(...) end
		local t0 = os.clock()
		local r1, r2 = fn(...)
		local ms = (os.clock() - t0) * 1000
		pf.frameMs = pf.frameMs + ms
		local e = pf.mods[name]
		if not e then e = {total = 0, worst = 0, calls = 0}; pf.mods[name] = e end
		e.total = e.total + ms
		e.calls = e.calls + 1
		if ms > e.worst then e.worst = ms end
		return r1, r2
	end
end

-- Connect to a service signal AND register it so a re-run can disconnect it.
-- Set CamSys.nextName right before the call to also time that callback.
function CamSys.track(signal, fn)
	local name = CamSys.nextName
	CamSys.nextName = nil
	local c = signal:Connect(name and CamSys.timed(name, fn) or fn)
	table.insert(CamSys.conns, c)
	return c
end

-- Write a property ONLY if it differs. Roblox stores most of these as float32, so
-- numbers are compared with a tiny relative tolerance (an exact compare would
-- never match after the float32 round trip and we'd rewrite every frame anyway).
function CamSys.set(inst, prop, v)
	local cur = inst[prop]
	if type(v) == "number" and type(cur) == "number" then
		if math.abs(cur - v) <= 1e-6 * math.max(1, math.abs(v)) then return end
	elseif cur == v then
		return
	end
	inst[prop] = v
end

-- Every normal-config read/write of DoF goes through these two, so captured
-- presets / Override / Reset never see (or overwrite with) runtime values.
function CamSys.setDoF(prop, value)
	if CamSys.dofActive then CamSys.dofBase[prop] = value else CamSys.set(depthOfField, prop, value) end
end
function CamSys.getDoF(prop)
	if CamSys.dofActive then return CamSys.dofBase[prop] end
	return depthOfField[prop]
end

-- ============================================================
-- Light & Neon recolor layer (client-side, optional, OFF by default).
--   game/server updates  ->  this layer  ->  what your client renders
-- For every Light (Point/Spot/Surface) and Neon-material BasePart in Workspace
-- we remember the GAME's own Color (and Brightness for lights) and keep
-- showing  game value x RGB multiplier.  When the game changes a value, the
-- change is detected (it won't match what we last wrote), stored as the new
-- game value, and the processed value is re-applied. Math is always
-- game value x multiplier, never previous output x multiplier.
-- Over-1 handling (Color3 channels cap at 1), see CamSys.light.overflow:
--   compensate  normalize the color to max channel 1, move the excess into
--               Brightness (lights); Neon parts are just normalized
--   normalize   normalize only (keeps hue, loses the extra intensity)
--   clip        clamp each channel to 1 (hue can shift)
-- Performance: event-driven (no polling). Up to activeCap objects that are
-- currently animating get recolored immediately; any further animating
-- objects are queued and drained at overflowPerSec objects/second. The
-- initial scan and multiplier changes are time-sliced (2 ms per frame).
-- NOTE: everything lives in CamSys.light (zero new top-level locals).
-- ============================================================
CamSys.light = {
	enabled = false,
	mulR = 1, mulG = 1, mulB = 1,
	brightOffset = 0, -- stops (EV): Light.Brightness x 2^offset; Neon: colour gain, capped at 1
	overflow = "compensate",
	activeCap = 50,
	overflowPerSec = 50,
	tracked = {}, count = 0,
	active = {}, activeCount = 0,
	queue = {}, qHead = 1, qTail = 0, queued = {},
	tokens = 0, expireAcc = 0,
	scanList = nil, scanIdx = 1,
	refreshList = nil, refreshIdx = 1,
}

function CamSys.light.compute(rec)
	local L = CamSys.light
	local g = rec.game
	local r, gr, b = g.R * L.mulR, g.G * L.mulG, g.B * L.mulB
	local bright = rec.gameB
	local gain = 2 ^ L.brightOffset
	-- Neon has no Brightness: the offset becomes a colour gain (Color3 caps at 1, so it can
	-- lift dark neon and dim any neon, but it can't push an already-full neon past 1).
	if not rec.isLight and gain ~= 1 then r, gr, b = r * gain, gr * gain, b * gain end
	local m = math.max(r, gr, b)
	if m > 1 then
		if L.overflow == "clip" then
			r, gr, b = math.min(r, 1), math.min(gr, 1), math.min(b, 1)
		else
			r, gr, b = r / m, gr / m, b / m
			if rec.isLight and bright and L.overflow == "compensate" then
				bright = bright * m
			end
		end
	end
	-- lights: offset applied last, on top of the overflow compensation
	if rec.isLight and bright then bright = bright * gain end
	return Color3.new(r, gr, b), bright
end

-- Did the GAME change this object since our last write? Our own write comes back as
-- a (deferred or immediate) change event too, so compare against what we wrote.
-- BasePart.Color is stored with 8-bit precision: reading a color back can differ
-- by up to ~0.002 from what was written, so the tolerance MUST exceed that (0.0025)
-- or the layer mistakes its own write for a game update and compounds the tint.
function CamSys.light.adopt(inst, rec)
	local changed = false
	local lc = rec.lastC
	if lc then
		local cur = inst.Color
		if math.abs(cur.R - lc.R) > 0.0025 or math.abs(cur.G - lc.G) > 0.0025 or math.abs(cur.B - lc.B) > 0.0025 then
			rec.game = cur
			changed = true
		end
	end
	if rec.isLight and rec.lastB then
		local br = inst.Brightness
		if math.abs(br - rec.lastB) > 1e-3 * math.max(1, math.abs(br)) then
			rec.gameB = br
			changed = true
		end
	end
	return changed
end

function CamSys.light.write(inst, rec)
	local L = CamSys.light
	L.adopt(inst, rec) -- never overwrite a game change we haven't seen yet
	local c, b = L.compute(rec)
	-- a part that stopped being Neon is shown with the game's own color
	if not rec.isLight and inst.Material ~= Enum.Material.Neon then c = rec.game end
	rec.lastC = c -- provisional (an immediate change event may fire mid-write)
	if rec.isLight and b then rec.lastB = b end
	local cur = inst.Color
	if math.abs(cur.R - c.R) > 0.0015 or math.abs(cur.G - c.G) > 0.0015 or math.abs(cur.B - c.B) > 0.0015 then
		inst.Color = c
	end
	rec.lastC = inst.Color -- read back: this is what the engine actually stored
	if rec.isLight and b then
		if math.abs(inst.Brightness - b) > 1e-4 * math.max(1, math.abs(b)) then inst.Brightness = b end
		rec.lastB = inst.Brightness
	end
end

function CamSys.light.onChange(inst, rec)
	local L = CamSys.light
	if not L.enabled then return end
	if not L.adopt(inst, rec) then return end -- that was our own write coming back
	local now = os.clock()
	if L.active[inst] then
		L.active[inst] = now
		L.write(inst, rec)
	elseif L.activeCount < L.activeCap then
		L.active[inst] = now
		L.activeCount = L.activeCount + 1
		L.write(inst, rec)
	elseif not L.queued[inst] then
		L.queued[inst] = true
		L.qTail = L.qTail + 1
		L.queue[L.qTail] = inst
	end
end

function CamSys.light.trackInst(inst)
	local L = CamSys.light
	if L.tracked[inst] then return end
	local isLight = inst:IsA("Light")
	if not isLight then
		if not (inst:IsA("BasePart") and inst.Material == Enum.Material.Neon) then return end
	end
	local rec = {isLight = isLight, game = inst.Color, gameB = isLight and inst.Brightness or nil, conns = {}}
	L.tracked[inst] = rec
	L.count = L.count + 1
	rec.conns[1] = inst:GetPropertyChangedSignal("Color"):Connect(function() L.onChange(inst, rec) end)
	if isLight then
		rec.conns[2] = inst:GetPropertyChangedSignal("Brightness"):Connect(function() L.onChange(inst, rec) end)
	end
	rec.conns[#rec.conns + 1] = inst.Destroying:Connect(function() L.untrack(inst, false) end)
	L.write(inst, rec)
end

function CamSys.light.untrack(inst, restore)
	local L = CamSys.light
	local rec = L.tracked[inst]
	if not rec then return end
	for _, c in ipairs(rec.conns) do pcall(function() c:Disconnect() end) end
	L.tracked[inst] = nil
	L.count = L.count - 1
	if L.active[inst] then
		L.active[inst] = nil
		L.activeCount = L.activeCount - 1
	end
	if restore then
		pcall(L.adopt, inst, rec) -- a game change we haven't seen yet must not be overwritten
		pcall(function()
			inst.Color = rec.game
			if rec.isLight and rec.gameB then inst.Brightness = rec.gameB end
		end)
	end
end

-- Hand every tracked object back to the game's own values and stop tracking.
function CamSys.light.shutdown()
	local L = CamSys.light
	L.enabled = false
	for inst in pairs(L.tracked) do L.untrack(inst, true) end
	L.queue, L.qHead, L.qTail, L.queued = {}, 1, 0, {}
	L.scanList, L.refreshList = nil, nil
	L.activeCount = 0
	table.clear(L.active)
end

function CamSys.light.setEnabled(v)
	local L = CamSys.light
	v = v and true or false
	if v == L.enabled then return end
	if not v then
		L.shutdown()
		return
	end
	L.enabled = true
	L.tokens = L.overflowPerSec
	local ok, list = pcall(function() return workspace:GetDescendants() end)
	if ok then L.scanList, L.scanIdx = list, 1 end
end

-- Re-process every tracked object (multiplier / overflow-mode change), time-sliced.
function CamSys.light.refreshAll()
	local L = CamSys.light
	if not L.enabled then return end
	local list = {}
	for inst in pairs(L.tracked) do list[#list + 1] = inst end
	L.refreshList, L.refreshIdx = list, 1
end

function CamSys.light.step(dt)
	local L = CamSys.light
	if not L.enabled then return end
	local t0 = os.clock()
	-- 1. initial scan, 2 ms per frame
	if L.scanList then
		local list, i, n = L.scanList, L.scanIdx, #L.scanList
		while i <= n do
			pcall(L.trackInst, list[i])
			i = i + 1
			if os.clock() - t0 > 0.002 then break end
		end
		L.scanIdx = i
		if i > n then L.scanList = nil end
	end
	-- 2. multiplier refresh, 2 ms per frame
	if L.refreshList then
		local list, i, n = L.refreshList, L.refreshIdx, #L.refreshList
		local t1 = os.clock()
		while i <= n do
			local inst = list[i]
			local rec = L.tracked[inst]
			if rec then pcall(L.write, inst, rec) end
			i = i + 1
			if os.clock() - t1 > 0.002 then break end
		end
		L.refreshIdx = i
		if i > n then L.refreshList = nil end
	end
	-- 3. overflow queue: at most overflowPerSec objects per second
	L.tokens = math.min(L.tokens + dt * L.overflowPerSec, L.overflowPerSec)
	while L.qHead <= L.qTail and L.tokens >= 1 do
		local inst = L.queue[L.qHead]
		L.queue[L.qHead] = nil
		L.qHead = L.qHead + 1
		L.queued[inst] = nil
		local rec = L.tracked[inst]
		if rec then
			pcall(L.write, inst, rec)
			L.tokens = L.tokens - 1
		end
	end
	if L.qHead > L.qTail then L.qHead, L.qTail = 1, 0 end
	-- 4. free full-rate slots of objects that stopped animating (1 s idle)
	L.expireAcc = L.expireAcc + dt
	if L.expireAcc >= 0.25 then
		L.expireAcc = 0
		local now = os.clock()
		for inst, t in pairs(L.active) do
			if now - t > 1 then
				L.active[inst] = nil
				L.activeCount = L.activeCount - 1
			end
		end
	end
end

CamSys.nextName = "lightRecolor"
CamSys.track(RunService.Heartbeat, function(dt) CamSys.light.step(dt) end)
CamSys.track(workspace.DescendantAdded, function(d)
	if CamSys.light.enabled then CamSys.light.trackInst(d) end
end)

-- ============================================================
-- Base + Offset system for Exposure / Saturation / Contrast / White
-- Balance / Tint. The "base" values are what actually get saved into
-- presets/config (captureState/applyState only ever touch these).
-- "Offset" is a separate personal viewing adjustment layer, wired up in
-- its own section further down -- lets different games' baseline visuals
-- be compensated for without that compensation ever being written into a
-- preset. Final applied value = base + offset. Declared here (before
-- neutralizeCustomEffects) so that function can reset these trackers too.
-- ============================================================
local WB_STRENGTH = 0.18
local TINT_STRENGTH = 0.18

local baseExposure, offsetExposure = Lighting.ExposureCompensation, 0
local baseSaturation, offsetSaturation = 0, 0
local baseContrast, offsetContrast = 0, 0
local currentWB, offsetWB = 0, 0 -- -1..1 each
local currentTint, offsetTint = 0, 0 -- -1..1 each
-- Independent per-channel TintColor multipliers live in CamSys.CamSys.tintMulR/G/B
-- (preset settings, 1 = neutral; kept off the top-level locals, see CamSys).
-- Applied AFTER computeTintColor from the stable base every time, never to a
-- previous output, so they can't compound.

local function computeTintColor(wb, tint)
	local tintR = 1 + wb * WB_STRENGTH + tint * (TINT_STRENGTH * 0.5)
	local tintG = 1 - tint * TINT_STRENGTH
	local tintB = 1 - wb * WB_STRENGTH + tint * (TINT_STRENGTH * 0.5)
	return Color3.new(
		math.clamp(tintR, 0, 2),
		math.clamp(tintG, 0, 2),
		math.clamp(tintB, 0, 2)
	)
end

-- Inverse of computeTintColor -- recovers the wb/tint floats that would
-- have produced a given TintColor. Used both when loading a saved state
-- (to restore currentWB/currentTint) and to sync the slider positions.
local function invertTintColor(tintColor)
	local tint = (1 - tintColor.G) / TINT_STRENGTH
	local wb = (tintColor.R - 1 - tint * (TINT_STRENGTH * 0.5)) / WB_STRENGTH
	return wb, tint
end

-- Final TintColor = clamp(WB/Tint color * RGB multipliers). Always rebuilt from
-- currentWB/currentTint/offsets/auto + the multipliers, never from the live property.
function CamSys.expectedTintColor()
	local c = computeTintColor(currentWB + offsetWB + CamSys.autoWB, currentTint + offsetTint + CamSys.autoTint)
	return Color3.new(
		math.clamp(c.R * CamSys.tintMulR, 0, 2),
		math.clamp(c.G * CamSys.tintMulG, 0, 2),
		math.clamp(c.B * CamSys.tintMulB, 0, 2)
	)
end

local function recomputeExposure()
	CamSys.set(Lighting, "ExposureCompensation", baseExposure + offsetExposure + CamSys.autoExposureEV)
end

local function recomputeSaturation()
	CamSys.set(colorCorrection, "Saturation", baseSaturation + offsetSaturation)
end

local function recomputeContrast()
	CamSys.set(colorCorrection, "Contrast", baseContrast + offsetContrast)
end

local function recomputeTint()
	CamSys.set(colorCorrection, "TintColor", CamSys.expectedTintColor())
end

-- IMPORTANT: Roblox's factory defaults for these effects are NOT neutral.
-- A freshly created DepthOfFieldEffect, Atmosphere, or BloomEffect already
-- applies a visible amount of blur/haze/glow the instant it's parented into
-- Lighting -- even with Enabled = true and no slider ever touched. Without
-- this, running the script would immediately blur/haze the screen on its
-- own. Force everything to a true "off" baseline so nothing changes until
-- you actually move a slider. Also reused by "Reset to Server Defaults"
-- below, since these Client-prefixed effects didn't exist before this
-- script created them -- neutral/off IS their correct reset state.
local function neutralizeCustomEffects()
	if colorCorrectionWasCreated then
		colorCorrection.Brightness = 0
		baseSaturation, offsetSaturation = 0, 0
		baseContrast, offsetContrast = 0, 0
		currentWB, offsetWB = 0, 0
		currentTint, offsetTint = 0, 0
	else
		-- Adopted the game's own ColorCorrectionEffect -- restore the real
		-- snapshotted baseline instead of wiping it to zero.
		local d = adoptedEffectDefaults.CC
		colorCorrection.Brightness = d.Brightness
		baseSaturation, offsetSaturation = d.Saturation, 0
		baseContrast, offsetContrast = d.Contrast, 0
		local wb, tint = invertTintColor(d.TintColor)
		currentWB, offsetWB = wb, 0
		currentTint, offsetTint = tint, 0
	end
	CamSys.tintMulR, CamSys.tintMulG, CamSys.tintMulB = 1, 1, 1
	CamSys.light.mulR, CamSys.light.mulG, CamSys.light.mulB = 1, 1, 1
	CamSys.light.brightOffset = 0
	CamSys.light.refreshAll()
	recomputeSaturation()
	recomputeContrast()
	recomputeTint()

	if sunRaysWasCreated then
		sunRays.Intensity = 0
		sunRays.Spread = 0
		sunRays.Enabled = true
	else
		local d = adoptedEffectDefaults.SunRays
		sunRays.Intensity = d.Intensity
		sunRays.Spread = d.Spread
		if d.Enabled ~= nil then sunRays.Enabled = d.Enabled end
	end

	if atmosphereWasCreated then
		atmosphere.Density = 0
		atmosphere.Offset = 0
		atmosphere.Glare = 0
		atmosphere.Haze = 0
		atmosphere.Color = Color3.new(1, 1, 1)
		atmosphere.Decay = Color3.new(1, 1, 1)
	else
		local d = adoptedEffectDefaults.Atmosphere
		atmosphere.Density = d.Density
		atmosphere.Offset = d.Offset
		atmosphere.Glare = d.Glare
		atmosphere.Haze = d.Haze
		atmosphere.Color = d.Color
		atmosphere.Decay = d.Decay
	end

	if bloomWasCreated then
		bloom.Intensity = 0
		bloom.Threshold = 2
		bloom.Size = 24
	else
		local d = adoptedEffectDefaults.Bloom
		bloom.Intensity = d.Intensity
		bloom.Threshold = d.Threshold
		bloom.Size = d.Size
	end

	if blurWasCreated then
		blur.Size = 0
	else
		blur.Size = adoptedEffectDefaults.Blur.Size
	end

	if depthOfFieldWasCreated then
		CamSys.setDoF("FarIntensity", 0)
		CamSys.setDoF("NearIntensity", 0)
		CamSys.setDoF("InFocusRadius", 50)
		CamSys.setDoF("FocusDistance", 100)
	else
		local d = adoptedEffectDefaults.DepthOfField
		CamSys.setDoF("FarIntensity", d.FarIntensity)
		CamSys.setDoF("NearIntensity", d.NearIntensity)
		CamSys.setDoF("InFocusRadius", d.InFocusRadius)
		CamSys.setDoF("FocusDistance", d.FocusDistance)
	end
end

neutralizeCustomEffects()

-- ============================================================
-- Fog fix + read-spoof layer + change tracking
--  * Atmosphere: only parented while Density/Haze/Glare are non-zero, so the legacy
--    Fog Start / Fog End / Fog Color sliders work again. (If the PLACE ships its own
--    Atmosphere the engine ignores legacy fog -- use Density/Offset there.)
--  * Spoof layer: game scripts reading a property this tool overrides get the value
--    the game last set / the original one; this script's own reads/writes are untouched.
--  * Lighting/effect .Changed marks the Override Lock dirty instead of polling every frame.
-- ============================================================
do
	if atmosphereWasCreated then
		local function syncAtmo()
			local want = (atmosphere.Density > 0 or atmosphere.Haze > 0 or atmosphere.Glare > 0) and Lighting or nil
			if atmosphere.Parent ~= want then atmosphere.Parent = want end
		end
		for _, prop in ipairs({"Density", "Haze", "Glare"}) do
			table.insert(CamSys.conns, atmosphere:GetPropertyChangedSignal(prop):Connect(syncAtmo))
		end
		syncAtmo()
	end

	local env = (type(getgenv) == "function" and getgenv()) or _G
	local S
	if type(hookmetamethod) == "function" and type(newcclosure) == "function" and type(checkcaller) == "function" then
		S = env.__LiUtSpoof
		if not S then
			local T = {ours = {}, gv = {}} -- hooks keep T forever; S may be dropped below
			S = T
			env.__LiUtSpoof = T -- hooks are installed once per session; a re-run only swaps the tables
			local cc = checkcaller
			local oldIndex, oldNew
			local okH = pcall(function()
				oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, k)
					local g = T.gv[self]
					if g then
						local v = g[k]
						if v ~= nil and not cc() then return v end
					end
					return oldIndex(self, k)
				end))
				oldNew = hookmetamethod(game, "__newindex", newcclosure(function(self, k, v)
					local o = T.ours[self]
					if o and k ~= "Parent" and k ~= "Name" then
						if cc() then
							local g = T.gv[self]
							if g[k] == nil then
								local ok, cur = pcall(oldIndex, self, k) -- real value before our first override
								if ok then g[k] = cur end
							end
							o[k] = v
						elseif o[k] ~= nil then
							o[k] = nil -- the game wrote it itself: its value is now the real one
							T.gv[self][k] = nil
						end
					end
					return oldNew(self, k, v)
				end))
			end)
			if not okH then S = nil; env.__LiUtSpoof = nil end
		end
		if S then S.ours, S.gv = {}, {} end
	end

	for _, inst in ipairs({Lighting, colorCorrection, sunRays, atmosphere, bloom, blur, depthOfField}) do
		if S then S.ours[inst] = {}; S.gv[inst] = {} end
	end
	for _, inst in ipairs({Lighting, colorCorrection, sunRays, atmosphere, bloom, blur}) do
		CamSys.track(inst.Changed, function(p)
			-- ExposureCompensation is rewritten by Auto Exposure every frame; the poll below covers it
			if p ~= "ExposureCompensation" then CamSys.lockDirty = true end
			if S then
				-- server/replicated change to something we override: drop our record, real value is the game's
				local o = S.ours[inst]
				local ov = o and o[p]
				if ov ~= nil then
					local cur = inst[p]
					local same
					if type(cur) == "number" and type(ov) == "number" then
						same = math.abs(cur - ov) <= 1e-4 * math.max(1, math.abs(ov))
					else
						same = (cur == ov)
					end
					if not same then o[p] = nil; S.gv[inst][p] = nil end
				end
			end
		end)
	end
end

-- Snapshot the place's own Sky (if any) so closing the tool can put it back exactly.
do
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		local snap = {inst = sky}
		for _, prop in ipairs({"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp",
			"SunAngularSize", "MoonAngularSize", "StarCount", "CelestialBodiesShown", "SunTextureId", "MoonTextureId"}) do
			local ok, v = pcall(function() return sky[prop] end)
			if ok then snap[prop] = v end
		end
		CamSys.skySnap = snap
	end
end

local function getSky()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
		CamSys.skyCreated = sky
	end
	return sky
end

-- ============================================================
-- State capture / apply -- shared by the Lock Loop AND the
-- Custom Presets system further down (save/load/delete).
-- ============================================================
local function captureState()
	return {
		ClockTime = Lighting.ClockTime,
		Brightness = Lighting.Brightness,
		GlobalShadows = Lighting.GlobalShadows,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
		FogColor = Lighting.FogColor,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Ambient = Lighting.Ambient,
		ColorShift_Top = Lighting.ColorShift_Top,
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		-- NOTE: these 4 intentionally read the BASE trackers, not the live
		-- Lighting/colorCorrection properties -- the live properties also
		-- include the personal Offset layer (see further down), which must
		-- never be captured into a saved preset/config.
		ExposureCompensation = baseExposure,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		Technology = Lighting.Technology,

		CC_Brightness = colorCorrection.Brightness,
		CC_Contrast = baseContrast,
		CC_Saturation = baseSaturation,
		CC_TintColor = computeTintColor(currentWB, currentTint),
		CC_TintMulR = CamSys.tintMulR,
		CC_TintMulG = CamSys.tintMulG,
		CC_TintMulB = CamSys.tintMulB,
		LT_MulR = CamSys.light.mulR,
		LT_MulG = CamSys.light.mulG,
		LT_MulB = CamSys.light.mulB,
		LT_BrightOffset = CamSys.light.brightOffset,
		LT_Enabled = CamSys.light.enabled,
		LT_Overflow = CamSys.light.overflow,
		LT_ActiveCap = CamSys.light.activeCap,
		LT_OverflowPerSec = CamSys.light.overflowPerSec,

		SunRaysEnabled = sunRays.Enabled,
		SunRaysIntensity = sunRays.Intensity,
		SunRaysSpread = sunRays.Spread,

		Atmo_Density = atmosphere.Density,
		Atmo_Offset = atmosphere.Offset,
		Atmo_Color = atmosphere.Color,
		Atmo_Decay = atmosphere.Decay,
		Atmo_Glare = atmosphere.Glare,
		Atmo_Haze = atmosphere.Haze,

		Bloom_Intensity = bloom.Intensity,
		Bloom_Threshold = bloom.Threshold,
		Bloom_Size = bloom.Size,

		Blur_Size = blur.Size,

		-- NORMAL DoF config (never the automatic Real Camera Blur runtime values)
		DoF_FarIntensity = CamSys.getDoF("FarIntensity"),
		DoF_InFocusRadius = CamSys.getDoF("InFocusRadius"),
		DoF_NearIntensity = CamSys.getDoF("NearIntensity"),
		DoF_FocusDistance = CamSys.getDoF("FocusDistance"),

		-- Sky celestial sizes (read from an existing Sky only, so we never
		-- create a default Sky in a game that doesn't have one)
		Sun_Size = (Lighting:FindFirstChildOfClass("Sky") or {SunAngularSize = 21}).SunAngularSize,
		Moon_Size = (Lighting:FindFirstChildOfClass("Sky") or {MoonAngularSize = 11}).MoonAngularSize,
	}
end

local function applyState(s)
	-- Runs EVERY rendered frame while Override Lock is on, so it only writes what
	-- actually differs (see CamSys.set) instead of re-assigning ~45 properties.
	local set = CamSys.set
	set(Lighting, "ClockTime", s.ClockTime)
	set(Lighting, "Brightness", s.Brightness)
	set(Lighting, "GlobalShadows", s.GlobalShadows)
	set(Lighting, "FogStart", s.FogStart)
	set(Lighting, "FogEnd", s.FogEnd)
	set(Lighting, "FogColor", s.FogColor)
	set(Lighting, "OutdoorAmbient", s.OutdoorAmbient)
	set(Lighting, "Ambient", s.Ambient)
	set(Lighting, "ColorShift_Top", s.ColorShift_Top)
	set(Lighting, "ColorShift_Bottom", s.ColorShift_Bottom)
	baseExposure = s.ExposureCompensation
	recomputeExposure()
	set(Lighting, "EnvironmentDiffuseScale", s.EnvironmentDiffuseScale)
	set(Lighting, "EnvironmentSpecularScale", s.EnvironmentSpecularScale)
	if s.Technology then set(Lighting, "Technology", s.Technology) end

	set(colorCorrection, "Brightness", s.CC_Brightness)
	baseContrast = s.CC_Contrast
	recomputeContrast()
	baseSaturation = s.CC_Saturation
	recomputeSaturation()
	currentWB, currentTint = invertTintColor(s.CC_TintColor)
	-- old presets have no multiplier keys -> neutral 1
	CamSys.tintMulR = math.clamp(tonumber(s.CC_TintMulR) or 1, 0, 2)
	CamSys.tintMulG = math.clamp(tonumber(s.CC_TintMulG) or 1, 0, 2)
	CamSys.tintMulB = math.clamp(tonumber(s.CC_TintMulB) or 1, 0, 2)
	recomputeTint()
	-- Light & Neon multipliers (old presets without them -> neutral 1)
	-- (applyState also runs every frame under Override Lock, so only refresh on a real change)
	do
		local L = CamSys.light
		local nr = math.clamp(tonumber(s.LT_MulR) or 1, 0, 2)
		local ng = math.clamp(tonumber(s.LT_MulG) or 1, 0, 2)
		local nb = math.clamp(tonumber(s.LT_MulB) or 1, 0, 2)
		local changed = false
		if nr ~= L.mulR or ng ~= L.mulG or nb ~= L.mulB then
			L.mulR, L.mulG, L.mulB = nr, ng, nb
			changed = true
		end
		local bo = math.clamp(tonumber(s.LT_BrightOffset) or 0, -3, 4)
		if bo ~= L.brightOffset then
			L.brightOffset = bo
			changed = true
		end
		-- the settings below are only applied when the preset contains them
		-- (presets saved before they existed leave the current values alone)
		local ov = s.LT_Overflow
		if (ov == "compensate" or ov == "normalize" or ov == "clip") and ov ~= L.overflow then
			L.overflow = ov
			changed = true
		end
		if tonumber(s.LT_ActiveCap) then L.activeCap = math.clamp(math.floor(tonumber(s.LT_ActiveCap) + 0.5), 10, 50) end
		if tonumber(s.LT_OverflowPerSec) then L.overflowPerSec = math.clamp(math.floor(tonumber(s.LT_OverflowPerSec) + 0.5), 10, 200) end
		if type(s.LT_Enabled) == "boolean" then L.setEnabled(s.LT_Enabled) end
		if changed then L.refreshAll() end
		if L.syncUI then L.syncUI() end
	end

	set(sunRays, "Enabled", s.SunRaysEnabled)
	set(sunRays, "Intensity", s.SunRaysIntensity)
	set(sunRays, "Spread", s.SunRaysSpread)

	set(atmosphere, "Density", s.Atmo_Density)
	set(atmosphere, "Offset", s.Atmo_Offset)
	set(atmosphere, "Color", s.Atmo_Color)
	set(atmosphere, "Decay", s.Atmo_Decay)
	set(atmosphere, "Glare", s.Atmo_Glare)
	set(atmosphere, "Haze", s.Atmo_Haze)

	set(bloom, "Intensity", s.Bloom_Intensity)
	set(bloom, "Threshold", s.Bloom_Threshold)
	set(bloom, "Size", s.Bloom_Size)

	set(blur, "Size", s.Blur_Size)

	CamSys.setDoF("FarIntensity", s.DoF_FarIntensity)
	CamSys.setDoF("InFocusRadius", s.DoF_InFocusRadius)
	CamSys.setDoF("NearIntensity", s.DoF_NearIntensity)
	CamSys.setDoF("FocusDistance", s.DoF_FocusDistance)

	local existingSky = Lighting:FindFirstChildOfClass("Sky")
	if existingSky then
		if s.Sun_Size ~= nil then set(existingSky, "SunAngularSize", s.Sun_Size) end
		if s.Moon_Size ~= nil then set(existingSky, "MoonAngularSize", s.Moon_Size) end
	end
end

local function updateLockedSettings()
	lockedSettings = captureState()
end

-- ============================================================
-- Serialize / Deserialize -- DataStores (and RemoteEvents, for
-- best practice) can't carry Color3 or Enum values directly, only
-- plain numbers/strings/booleans/tables. These convert a captured
-- state table to/from a plain-value form safe to send to the server.
-- ============================================================
local COLOR3_STATE_KEYS = {
	FogColor = true, OutdoorAmbient = true, Ambient = true,
	ColorShift_Top = true, ColorShift_Bottom = true,
	CC_TintColor = true, Atmo_Color = true, Atmo_Decay = true,
}

local function serializeState(s)
	local out = {}
	for k, v in pairs(s) do
		if COLOR3_STATE_KEYS[k] then
			out[k] = {r = v.R, g = v.G, b = v.B}
		elseif k == "Technology" then
			out[k] = v.Name
		else
			out[k] = v
		end
	end
	return out
end

local function deserializeState(data)
	local out = {}
	for k, v in pairs(data) do
		if COLOR3_STATE_KEYS[k] and type(v) == "table" then
			out[k] = Color3.new(v.r or 0, v.g or 0, v.b or 0)
		elseif k == "Technology" and type(v) == "string" then
			out[k] = Enum.Technology[v]
		else
			out[k] = v
		end
	end
	-- presets saved before the RGB multipliers existed: fill neutral values so
	-- Load/Import also repaints the new sliders back to 1.00
	if out.CC_TintMulR == nil then out.CC_TintMulR = 1 end
	if out.CC_TintMulG == nil then out.CC_TintMulG = 1 end
	if out.CC_TintMulB == nil then out.CC_TintMulB = 1 end
	if out.LT_MulR == nil then out.LT_MulR = 1 end
	if out.LT_MulG == nil then out.LT_MulG = 1 end
	if out.LT_MulB == nil then out.LT_MulB = 1 end
	if out.LT_BrightOffset == nil then out.LT_BrightOffset = 0 end
	return out
end

-- Restores exactly what the developer/server had set before this script
-- touched anything (captured into serverDefaultLighting at the very top),
-- plus resets this script's own effects back to neutral/off (see
-- neutralizeCustomEffects -- those effects have no "server default" of
-- their own since this script created them). Actual UI wiring (confirm
-- popup, button) is further down once the buttons exist.
local function resetToServerDefaults()
	Lighting.ClockTime = serverDefaultLighting.ClockTime
	Lighting.Brightness = serverDefaultLighting.Brightness
	Lighting.GlobalShadows = serverDefaultLighting.GlobalShadows
	Lighting.FogStart = serverDefaultLighting.FogStart
	Lighting.FogEnd = serverDefaultLighting.FogEnd
	Lighting.FogColor = serverDefaultLighting.FogColor
	Lighting.OutdoorAmbient = serverDefaultLighting.OutdoorAmbient
	Lighting.Ambient = serverDefaultLighting.Ambient
	Lighting.ColorShift_Top = serverDefaultLighting.ColorShift_Top
	Lighting.ColorShift_Bottom = serverDefaultLighting.ColorShift_Bottom
	baseExposure, offsetExposure = serverDefaultLighting.ExposureCompensation, 0
	recomputeExposure()
	Lighting.EnvironmentDiffuseScale = serverDefaultLighting.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = serverDefaultLighting.EnvironmentSpecularScale
	pcall(function() Lighting.Technology = serverDefaultLighting.Technology end)

	neutralizeCustomEffects()

	lockLighting = false
end

-- ============================================================
-- Optional Runtime Filesystem Support -- detected here, BEFORE the UI is
-- built, so that "Remember Last Lighting on Startup" (further down) can
-- restore your last-used state before any slider reads its starting
-- value, instead of building the UI at neutral and then snapping over.
-- ============================================================
local hasFilesystem = (type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function" and type(isfile) == "function" and type(delfile) == "function")
local LOCAL_FOLDER_NAME = "LightingUtilityPresets"
local SETTINGS_FILE = LOCAL_FOLDER_NAME .. "/_settings.json"
local LAST_STATE_FILE = LOCAL_FOLDER_NAME .. "/_last_state.json"
local ORDER_FILE = LOCAL_FOLDER_NAME .. "/_order.json"

if hasFilesystem and not isfolder(LOCAL_FOLDER_NAME) then
	makefolder(LOCAL_FOLDER_NAME)
end

local function loadJSONFile(path)
	if not (hasFilesystem and isfile(path)) then return nil end
	local ok, content = pcall(readfile, path)
	if not ok then return nil end
	local decodeOk, parsed = pcall(function() return HttpService:JSONDecode(content) end)
	if decodeOk and type(parsed) == "table" then return parsed end
	return nil
end

local function saveJSONFile(path, data)
	if not hasFilesystem then return end
	CamSys.perf.writes = CamSys.perf.writes + 1
	pcall(writefile, path, HttpService:JSONEncode(data))
end

local savedSettings = loadJSONFile(SETTINGS_FILE) or {}
local rememberLastState = savedSettings.rememberLastState == true

if rememberLastState then
	local lastState = loadJSONFile(LAST_STATE_FILE)
	if lastState then
		local ok, err = pcall(function()
			applyState(deserializeState(lastState))
		end)
		if not ok then
			warn("[LightingUtility] Failed to restore your last saved lighting, starting neutral instead: " .. tostring(err))
		end
	end
end

local function saveLastStateNow()
	if not rememberLastState or not hasFilesystem then return end
	local okE, json = pcall(function() return HttpService:JSONEncode(serializeState(captureState())) end)
	-- identical to what is already on disk? then skip the write entirely
	if not okE or json == CamSys.lastStateJSON then return end
	CamSys.lastStateJSON = json
	CamSys.perf.writes = CamSys.perf.writes + 1
	pcall(writefile, LAST_STATE_FILE, json)
end

-- ============================================================
-- Persistent Loop (Overrides Server Scripts)
-- ============================================================
CamSys.nextName = "lockLoop"
CamSys.track(RunService.RenderStepped, function(dt)
	if not lockLighting then return end
	local C = CamSys
	C.lockAccum = C.lockAccum + dt
	-- re-apply when a .Changed fired, else at most 10x/second as a safety net
	-- (was: ~45 property reads + recompute calls on EVERY frame)
	if not C.lockDirty and C.lockAccum < 0.1 then return end
	C.lockDirty, C.lockAccum = false, 0
	applyState(lockedSettings)
end)

-- Periodic autosave of "last used" lighting, only while the toggle is on.
-- Throttled (not on every slider tick) so dragging a fader doesn't hammer
-- the filesystem.
do
local AUTOSAVE_INTERVAL = 10 -- was 3 s; the write is also skipped when nothing changed
local autosaveAccum = 0
CamSys.nextName = "autosave"
CamSys.track(RunService.Heartbeat, function(dt)
	if not rememberLastState then return end
	autosaveAccum += dt
	if autosaveAccum < AUTOSAVE_INTERVAL then return end
	autosaveAccum = 0
	saveLastStateNow()
end)
end


-- ============================================================
-- Real Camera Blur + Automatic Exposure / White Balance ENGINE
--
-- Pure logic, no UI (the UI is built further down and only talks to
-- CamSys.rcb / CamSys.autoCam). Wrapped in do...end so none of its helpers
-- count against the 200-locals limit.
--
-- REAL CAMERA BLUR
--   Controls Roblox's existing DepthOfFieldEffect (the same `depthOfField`
--   the rest of this script already adopted/created). No custom blur.
--   While ON it owns FocusDistance / InFocusRadius / NearIntensity /
--   FarIntensity / Enabled. The NORMAL values live in CamSys.dofBase and are
--   what captureState()/presets/Override/the DoF sliders see, so runtime
--   values never leak into presets. Turning it OFF restores dofBase.
--
--     Autofocus target (3rd / 1st person: focus box-circle or screen centre; optional cursor)
--       -> optional player-priority override
--       -> median filter + dead-band (stability)
--       -> time/distance-mixed transition with Linear or Logarithmic curve
--       -> thin-lens model (focus range, foreground + background blur)
--       -> user lens controls (multipliers / offsets)
--       -> DepthOfFieldEffect
--
-- AUTO EXPOSURE / AUTO WHITE BALANCE
--   Roblox does not let a LocalScript read back rendered pixels, so the scene
--   is APPROXIMATED: a grid of camera rays is cast across the screen and each
--   hit is lit using Lighting (sun direction, Brightness, Ambient /
--   OutdoorAmbient, shadow + sky-exposure rays) for Auto Exposure. Auto White
--   Balance does NOT use the lighting: it is the plain average colour of what
--   the grid hits on screen (gray-world). The result feeds extra
--   layers (CamSys.autoExposureEV / autoWB / autoTint) added on top of the
--   existing base + offset values.
-- ============================================================
do
local lp = Players.LocalPlayer

-- ---------- shared helpers ----------
local INVISIBLE_PASS = 0.95 -- effective transparency at/above this is treated as "not there"

local function effectiveTransparency(part)
	return 1 - (1 - part.Transparency) * (1 - part.LocalTransparencyModifier)
end

-- Raycast that skips parts that are effectively transparent (>= passThrough).
-- Parts closer than minDist studs to the ray origin (optional) are skipped the same way.
-- Returns the first RaycastResult that counts as visible geometry, or nil.
local function castVisible(origin, direction, baseFilter, passThrough, ignoreWater, keepLast, minDist)
	local filter, copied = baseFilter, false
	-- two shared RaycastParams objects (water / no water) instead of a fresh one per ray
	-- (autofocus + auto-exposure fire hundreds of rays per second)
	local pool = CamSys.rayParams
	if not pool then
		pool = {}
		for i = 1, 2 do
			local p = RaycastParams.new()
			p.FilterType = Enum.RaycastFilterType.Exclude
			p.IgnoreWater = (i == 2)
			pool[i] = p
		end
		CamSys.rayParams = pool
	end
	local params = pool[ignoreWater and 2 or 1]
	local pf = CamSys.perf
	local last
	params.FilterDescendantsInstances = filter
	for _ = 1, 12 do
		pf.rays = pf.rays + 1
		local result = workspace:Raycast(origin, direction, params)
		if not result then return nil end
		last = result
		local inst = result.Instance
		if inst and inst:IsA("BasePart") and not inst:IsA("Terrain")
			and (effectiveTransparency(inst) >= passThrough or (minDist and result.Distance < minDist)) then
			if not copied then
				filter = table.clone(filter)
				copied = true
			end
			table.insert(filter, inst)
			params.FilterDescendantsInstances = filter
		else
			return result
		end
	end
	-- 12 see-through parts in a row (maps full of invisible hitboxes): autofocus passes keepLast so
	-- it still gets a distance, instead of reading "nothing" and holding stale focus
	-- (a leftover hit that is itself inside minDist is never returned: that is exactly what is ignored)
	return (keepLast and last and not (minDist and last.Distance < minDist)) and last or nil
end

local function smoothstep(e0, e1, x)
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function expAlpha(dt, tau)
	if tau <= 0 then return 1 end
	return 1 - math.exp(-dt / tau)
end

local function tanh(x)
	local e = math.exp(2 * math.clamp(x, -20, 20))
	return (e - 1) / (e + 1)
end

local function lumGamma(c) return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B end
local function lumLinear(c) return 0.2126 * c.R ^ 2.2 + 0.7152 * c.G ^ 2.2 + 0.0722 * c.B ^ 2.2 end

local function cameraDepth(cam, pos)
	local cf = cam.CFrame -- one CFrame read instead of two (each read allocates)
	return (pos - cf.Position):Dot(cf.LookVector)
end

-- ============================================================
-- REAL CAMERA BLUR
-- ============================================================
local RCB_DEFAULTS = {
	enabled = false,
	-- Player Autofocus (override)
	lockPlayer = false,           -- Auto Lock to Closest Player
	playerRange = 40,             -- 10..200 studs
	autoAdjustRange = true,       -- Auto Adjust Focus Range (player lock)
	dirPriority = false,          -- prefer the player nearest where you look
	dirAngle = 12,                -- 1..30 degrees
	disableWhenZoomedOut = true,
	zoomThreshold = 6,            -- studs; camera farther than this = "zoomed out"
	-- Lens
	aperture = 2.0,               -- simulated f-stop
	fgMult = 1, fgOffset = 0,
	bgMult = 1, bgOffset = 0,
	rangeMult = 1,
	-- Autofocus speed / transition curve
	focusTime = 0.45,             -- seconds (time-based factor)
	focusSpeed = 3,               -- distance doublings / second (distance-based factor)
	timeDistMix = 50,             -- 0 = all time, 100 = all distance
	curve = "Logarithmic",        -- "Linear" | "Logarithmic"
	-- Momentary override / Cursor Auto Focus (global: apply in both 3rd and 1st person)
	momentaryEnabled = false,
	momentaryKey = "MouseButton2", -- "MouseButton1/2/3" or an Enum.KeyCode name
	momentaryRadius = 5,          -- 0..50 (% of the shorter screen side), circle at screen centre
	momentaryScope = "Both",      -- "Locked" (mouse locked / 3rd person) | "First" | "Both"
	cursorEnabled = false,        -- Cursor Auto Focus: focus where the cursor points
	cursorKey = "",               -- optional hotkey that toggles it ("" = none)
}
-- Autofocus target settings, one table per camera mode: fp = 1st person, tp = 3rd person.
-- Both share the same keys; tp adds the 3rd-person-only options.
RCB_DEFAULTS.fp = {
	target = "Area",              -- "Area" (Auto Focus Box/Circle) | "Center" (Center of Screen)
	areaShape = "Box",            -- "Box" | "Circle"
	areaX = 0, areaY = 0,         -- -100..100 (0 = screen centre, +X right, +Y up, +-100 = screen edge)
	areaLength = 20, areaWidth = 20, -- 0..50 (% of screen width / height)
	areaRadius = 10,              -- 0..50 (% of the shorter screen side)
	areaFocusOn = 50,             -- 20..80 (20 = nearer part, 50 = middle, 80 = farther part)
	areaShowAlways = false,       -- keep the on-screen overlay visible
	anyPerson = false,            -- ignore Focus On: focus a person touching the area
}
RCB_DEFAULTS.tp = table.clone(RCB_DEFAULTS.fp)
for k, v in pairs({
	ignoreSelf = false,           -- autofocus ignores my own character
	idleSelfSeconds = 0,          -- 0 = Off, 1..10 s without activity -> focus on self
	idleMode = "Move",            -- "Move" (character movement) | "MoveCam" (+ camera pan/zoom)
	idleTransition = 1.5,         -- seconds the focus takes to move to self (replaces the normal speed)
	pitchOn = false,              -- move the area with camera pitch
	pitchMaxAngle = 30,           -- 0..45 deg of downward pitch at which the area is fully moved
	pitchDownY = -20,             -- Y of the area's highest point when fully looking down
	pitchCenterY = 0,             -- Y offset of the area when looking straight ahead
}) do RCB_DEFAULTS.tp[k] = v end

local RCB_LIMITS = {
	playerRange = {10, 200},
	dirAngle = {1, 30}, zoomThreshold = {1, 30}, aperture = {1.2, 16},
	fgMult = {0, 3}, fgOffset = {-0.5, 0.5}, bgMult = {0, 3}, bgOffset = {-0.5, 0.5},
	rangeMult = {0.25, 4}, focusTime = {0.05, 2}, focusSpeed = {0.5, 8}, timeDistMix = {0, 100},
	areaX = {-100, 100}, areaY = {-100, 100}, areaLength = {0, 50}, areaWidth = {0, 50},
	areaRadius = {0, 50}, areaFocusOn = {20, 80},
	idleSelfSeconds = {0, 10}, idleTransition = {0.1, 5},
	pitchMaxAngle = {0, 45}, pitchDownY = {-100, 100}, pitchCenterY = {-100, 100},
	momentaryRadius = {0, 50},
}

local rcbConfig = table.clone(RCB_DEFAULTS)
rcbConfig.tp, rcbConfig.fp = table.clone(RCB_DEFAULTS.tp), table.clone(RCB_DEFAULTS.fp)

-- Configuration lives in the persistent settings file next to
-- rememberLastState (NOT in lighting presets, NOT in captureState()).
do
	local saved = savedSettings.realCameraBlur
	if type(saved) == "table" then
		if saved.tp == nil and saved.fp == nil then
			-- Migrate the pre-v8.6 flat layout: its single autofocus setup becomes both the 3rd and 1st
			-- person setup, "Cursor" becomes the global Cursor Auto Focus toggle, and "In Front of
			-- Character" (removed) falls back to the default Focus Box/Circle.
			local old = saved
			saved = table.clone(old)
			local target = (old.target == "Center") and "Center" or "Area"
			saved.cursorEnabled = (old.target == "Cursor")
			saved.tp, saved.fp = {target = target}, {target = target}
			for _, k in ipairs({"areaShape", "areaX", "areaY", "areaLength", "areaWidth", "areaRadius", "areaFocusOn", "areaShowAlways"}) do
				saved.tp[k], saved.fp[k] = old[k], old[k]
			end
			saved.tp.ignoreSelf, saved.tp.idleSelfSeconds, saved.tp.idleMode = old.ignoreSelf, old.idleSelfSeconds, old.idleMode
		end
		-- copy saved values over the defaults where the type matches (numbers clamped); recurses into tp / fp
		local function load(dst, def, src)
			for k, d in pairs(def) do
				local v = src[k]
				if type(d) == "table" then
					if type(v) == "table" then load(dst[k], d, v) end
				elseif type(v) == type(d) and v == v then
					if type(v) == "number" and RCB_LIMITS[k] then
						v = math.clamp(v, RCB_LIMITS[k][1], RCB_LIMITS[k][2])
					end
					dst[k] = v
				end
			end
		end
		load(rcbConfig, RCB_DEFAULTS, saved)

		for _, sub in ipairs({rcbConfig.tp, rcbConfig.fp}) do
			if sub.target ~= "Area" and sub.target ~= "Center" then sub.target = "Area" end
			if sub.areaShape ~= "Box" and sub.areaShape ~= "Circle" then sub.areaShape = "Box" end
		end
		if rcbConfig.curve ~= "Linear" and rcbConfig.curve ~= "Logarithmic" then
			rcbConfig.curve = RCB_DEFAULTS.curve
		end
		local tp = rcbConfig.tp
		tp.idleSelfSeconds = math.floor(tp.idleSelfSeconds + 0.5)
		if tp.idleMode ~= "Move" and tp.idleMode ~= "MoveCam" then
			tp.idleMode = RCB_DEFAULTS.tp.idleMode
		end
		local sc = rcbConfig.momentaryScope
		if sc ~= "Locked" and sc ~= "First" and sc ~= "Both" then
			rcbConfig.momentaryScope = RCB_DEFAULTS.momentaryScope
		end
		for _, k in ipairs({"momentaryKey", "cursorKey"}) do -- "" is only valid for cursorKey (its default)
			local v = rcbConfig[k]
			if v ~= "MouseButton1" and v ~= "MouseButton2" and v ~= "MouseButton3" then
				local okKey, kc = pcall(function() return Enum.KeyCode[v] end)
				if not okKey or kc == nil then rcbConfig[k] = RCB_DEFAULTS[k] end
			end
		end
	end
	savedSettings.realCameraBlur = rcbConfig -- same table: any later settings write includes it
end

local rcb = {config = rcbConfig, defaults = RCB_DEFAULTS, limits = RCB_LIMITS}
CamSys.rcb = rcb
-- Autofocus never focuses on anything closer than this (studs) to the camera: a character
-- touching / inside the camera, a viewmodel, a prop against the lens. Rays pass through such
-- hits and continue to whatever is behind them.
rcb.MIN_DIST = 1.5

local RCB_SAMPLE_INTERVAL = 1 / 15

local rs = {} -- runtime state (never saved)
local function resetRuntime()
	rs.sampleAccum = RCB_SAMPLE_INTERVAL -- sample on the very first frame
	rs.history = {}
	rs.targetKey = nil
	rs.targetDist = nil
	rs.currentFocus = nil
	rs.animating = false
	rs.from, rs.to, rs.elapsed, rs.duration = 0, 0, 0, 1
	rs.lockedPlayer = nil
	rs.lastValidTime = nil
	rs.label = "Searching..."
	rs.source = nil                      -- "override" | "self" | "normal"
	rs.lastActivity = os.clock()         -- inactivity timer starts when Real Camera Blur turns on
	rs.prevRootPos, rs.prevLook, rs.prevZoom, rs.prevFov = nil, nil, nil, nil
	rs.outRadius, rs.outNear, rs.outFar = nil, nil, nil
	rs.fp, rs.prevFp, rs.sub = false, nil, rcbConfig.tp -- camera mode (1st / 3rd person) + its settings table
	rs.pendingDur = nil                  -- one-shot transition time (focus on self after inactivity)
end
resetRuntime()

-- ---------- DepthOfFieldEffect ownership ----------
local function ensureDoF()
	if depthOfField and depthOfField.Parent == Lighting then return end
	local found = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
	if not found then
		found = Instance.new("DepthOfFieldEffect")
		found.Name = "ClientDepthOfField"
		found.FarIntensity, found.NearIntensity = 0, 0
		found.InFocusRadius, found.FocusDistance = 50, 100
		found.Parent = Lighting
	end
	depthOfField = found
end

function rcb.SetEnabled(on)
	on = on and true or false
	rcbConfig.enabled = on
	if on == CamSys.dofActive then return end
	ensureDoF()
	if on then
		-- capture the NORMAL state before taking control
		local b = CamSys.dofBase
		b.Enabled = depthOfField.Enabled
		b.FarIntensity = depthOfField.FarIntensity
		b.NearIntensity = depthOfField.NearIntensity
		b.InFocusRadius = depthOfField.InFocusRadius
		b.FocusDistance = depthOfField.FocusDistance
		resetRuntime()
		CamSys.dofActive = true
	else
		CamSys.dofActive = false
		local b = CamSys.dofBase
		if b.Enabled ~= nil then depthOfField.Enabled = b.Enabled end
		depthOfField.FarIntensity = b.FarIntensity
		depthOfField.NearIntensity = b.NearIntensity
		depthOfField.InFocusRadius = b.InFocusRadius
		depthOfField.FocusDistance = b.FocusDistance
		resetRuntime()
	end
end

-- ---------- target sampling ----------
-- ---------- Focus Box / Circle ----------
-- A screen-space region (box or circle) that autofocus measures. Kept as
-- rcb.* functions so the on-screen overlay in the UI uses the EXACT same
-- geometry and sample points as the focus calculation.
--   X/Y  : -100..100, 0 = screen centre, +-100 = screen edge (+Y is up)
--   Box  : Length = % of screen WIDTH, Width = % of screen HEIGHT (0..50),
--          so equal values keep the screen's own aspect ratio
--   Circle: Radius = % of the SHORTER screen side (0..50) -> always round
-- `c` is the settings table of one camera mode (rcbConfig.tp / .fp). With Pitch-Based
-- Focus Area on (3rd person) the region's vertical position follows the camera pitch:
-- level = Y + Center Offset, fully looking down (Max Angle) = its highest point sits at
-- "Area Top When Looking Down"; in between it is interpolated proportionally.
function rcb.areaGeometry(vp, c, cam)
	local cx = vp.X / 2 + (c.areaX / 100) * (vp.X / 2)
	local cy = vp.Y / 2 - (c.areaY / 100) * (vp.Y / 2)
	local g
	if c.areaShape == "Circle" then
		g = {shape = "Circle", cx = cx, cy = cy, r = (c.areaRadius / 100) * math.min(vp.X, vp.Y)}
	else
		g = {shape = "Box", cx = cx, cy = cy, w = (c.areaLength / 100) * vp.X, h = (c.areaWidth / 100) * vp.Y}
	end
	if c.pitchOn and cam then
		local down = math.deg(-math.asin(math.clamp(cam.CFrame.LookVector.Y, -1, 1))) -- + = looking down
		local t = math.clamp(down / math.max(c.pitchMaxAngle, 0.01), 0, 1)
		local half = g.r or (g.h / 2)
		local levelY = cy - (c.pitchCenterY / 100) * (vp.Y / 2)
		local downY = vp.Y / 2 - (c.pitchDownY / 100) * (vp.Y / 2) + half -- centre that puts the top edge at pitchDownY
		g.cy = levelY + (downY - levelY) * t
		g.pitchDeg, g.pitchT = down, t
	end
	return g
end

-- Deterministic grid of points inside the region (on-screen only).
-- 0 size = 1 point, a zero-thickness box = a line of points.
function rcb.areaSamplePoints(g, vp)
	local pts = {}
	local function add(x, y)
		-- 1px tolerance so a region that exactly touches the screen edge keeps its edge row
		if x >= -1 and x <= vp.X and y >= -1 and y <= vp.Y then
			pts[#pts + 1] = Vector2.new(math.clamp(x, 0, vp.X - 1), math.clamp(y, 0, vp.Y - 1))
		end
	end
	if g.shape == "Circle" then
		if g.r < 1 then
			add(g.cx, g.cy)
		else
			local n = (g.r * 2 < 80) and 3 or ((g.r * 2 < 160) and 5 or 7) -- odd -> includes the centre
			for i = 0, n - 1 do
				for j = 0, n - 1 do
					local u, v = i / (n - 1) * 2 - 1, j / (n - 1) * 2 - 1
					if u * u + v * v <= 1.0001 then
						add(g.cx + u * g.r, g.cy + v * g.r)
					end
				end
			end
		end
	else
		local function count(len)
			if len < 1 then return 1 end
			return math.clamp(math.ceil(len / 40) + 1, 2, 7)
		end
		local nx, ny = count(g.w), count(g.h)
		for i = 0, nx - 1 do
			local u = (nx == 1) and 0 or (i / (nx - 1) - 0.5)
			for j = 0, ny - 1 do
				local v = (ny == 1) and 0 or (j / (ny - 1) - 0.5)
				add(g.cx + u * g.w, g.cy + v * g.h)
			end
		end
	end
	if #pts == 0 then -- region is entirely off-screen: fall back to its nearest on-screen point
		pts[1] = Vector2.new(math.clamp(g.cx, 0, vp.X - 1), math.clamp(g.cy, 0, vp.Y - 1))
	end
	return pts
end

-- Exclusion list for autofocus rays.
--  * Anything closer than rcb.MIN_DIST to the camera is skipped by castVisible (see there).
--  * The camera itself is always excluded: first-person viewmodels / camera-attached parts live
--    under it, a few inches from the lens.
--  * My own character is excluded in FIRST person (its arms, torso and held tool are inches from
--    the lens; if a ray hits them focus locks at ~1-3 studs, the in-focus zone collapses and the
--    whole scene stays blurry) and, in third person, when Ignore Self is on.
function rcb.rayFilter(cam, sub, fp)
	local c = lp.Character
	if c and (fp or sub.ignoreSelf) then return {c, cam} end
	return {cam}
end

-- Cast through every sample point of a screen region, collect the camera depth
-- of each visible surface, then pick the "Focus On" percentile of that
-- distribution (20% = nearer part, 50% = middle/median, 80% = farther part).
-- Nearest-rank (no interpolation) so focus always lands on a real surface,
-- never on the empty gap between a near object and a far wall. Sky is ignored.
function rcb.sampleRegion(cam, g, focusOnPct, key, label)
	local vp = cam.ViewportSize
	local pts = rcb.areaSamplePoints(g, vp)
	local filter = rcb.rayFilter(cam, rs.sub, rs.fp)
	local depths = {}
	for _, p in ipairs(pts) do
		local ray = cam:ViewportPointToRay(p.X, p.Y)
		local res = castVisible(ray.Origin, ray.Direction * 2000, filter, INVISIBLE_PASS, false, true, rcb.MIN_DIST)
		if res then depths[#depths + 1] = cameraDepth(cam, res.Position) end
	end
	local n = #depths
	if n == 0 then return nil end
	table.sort(depths)
	local idx = math.clamp(math.floor((n - 1) * (focusOnPct / 100) + 0.5) + 1, 1, n)
	return key, depths[idx], string.format("%s @ %.0f%% (%d/%d hits)", label, focusOnPct, n, #pts)
end

-- Does the character's on-screen bounding box touch the region? (projected 8-corner AABB vs
-- box / circle; a zero-size region is a point)
function rcb.touchesRegion(cam, pc, g)
	local cf, size = pc:GetBoundingBox()
	local h = size / 2
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				local p = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)))
				if p.Z > 0 then
					x0, y0, x1, y1 = math.min(x0, p.X), math.min(y0, p.Y), math.max(x1, p.X), math.max(y1, p.Y)
				end
			end
		end
	end
	if x0 == math.huge then return false end -- entirely behind the camera
	if g.shape == "Circle" then
		local dx, dy = math.clamp(g.cx, x0, x1) - g.cx, math.clamp(g.cy, y0, y1) - g.cy
		return dx * dx + dy * dy <= g.r * g.r
	end
	return x0 <= g.cx + g.w / 2 and x1 >= g.cx - g.w / 2 and y0 <= g.cy + g.h / 2 and y1 >= g.cy - g.h / 2
end

-- "Focus any person touching the area": people = other players, plus me in 3rd person unless
-- Ignore Self is on. 3rd person picks the one closest to the camera, 1st person the one whose
-- screen position is closest to the centre of the region. The current target gets a 20% bonus
-- so two people at similar scores don't flip-flop. Returns {plr, depth} or nil.
function rcb.samplePersonInArea(cam, char, sub, g, fp)
	local camPos = cam.CFrame.Position
	local others = char and {char, cam} or {cam}
	local best, bestScore
	for _, plr in ipairs(Players:GetPlayers()) do
		local pc = plr.Character
		local isMe = plr == lp
		if pc and not (isMe and (fp or sub.ignoreSelf)) then
			local hum = pc:FindFirstChildOfClass("Humanoid")
			if (not hum or hum.Health > 0) and rcb.touchesRegion(cam, pc, g) then
				local pos = rcb.visiblePersonPos(cam, pc, isMe and {cam} or others)
				if pos and (pos - camPos).Magnitude >= rcb.MIN_DIST then
					local score
					if fp then
						local v = cam:WorldToViewportPoint(pos)
						score = (Vector2.new(v.X, v.Y) - Vector2.new(g.cx, g.cy)).Magnitude
					else
						score = (pos - camPos).Magnitude
					end
					if plr == rs.lockedPlayer then score = score * 0.8 end
					if not bestScore or score < bestScore then
						best, bestScore = {plr = plr, depth = cameraDepth(cam, pos)}, score
					end
				end
			end
		end
	end
	return best
end

-- Auto Focus Box/Circle measurement for the active camera mode (`sub`).
function rcb.sampleArea(cam, char, sub, fp)
	local g = rcb.areaGeometry(cam.ViewportSize, sub, cam)
	local label = "Focus " .. sub.areaShape
	if sub.anyPerson then
		local c = rcb.samplePersonInArea(cam, char, sub, g, fp)
		if c then
			rs.lockedPlayer = c.plr -- keeps the subject inside the in-focus zone, like Player Autofocus
			return "P:" .. c.plr.UserId, c.depth, "Person: " .. c.plr.DisplayName
		end
		return rcb.sampleRegion(cam, g, 50, "AREA", label) -- nobody touching: middle depth of the area
	end
	return rcb.sampleRegion(cam, g, sub.areaFocusOn, "AREA", label)
end

-- Momentary override: a circle at the exact screen centre, size from the
-- "Center Focus Circle Size" setting (0 = a single point). Uses the middle
-- (median) depth of what is inside it.
function rcb.momentaryGeometry(vp)
	return {shape = "Circle", cx = vp.X / 2, cy = vp.Y / 2, r = (rcbConfig.momentaryRadius / 100) * math.min(vp.X, vp.Y)}
end
function rcb.sampleMomentary(cam)
	return rcb.sampleRegion(cam, rcb.momentaryGeometry(cam.ViewportSize), 50, "OVERRIDE", "Momentary Override")
end

-- "Focus on self" target: my character's root, if it is on screen.
function rcb.sampleSelf(cam, char)
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	if not root then return nil end
	local _, onScreen = cam:WorldToViewportPoint(root.Position)
	if not onScreen then return nil end
	local depth = cameraDepth(cam, root.Position)
	if depth < rcb.MIN_DIST then return nil end -- camera touching / inside me: fall back to normal autofocus
	return "SELF", depth, "Self (inactive)"
end

-- A person's world position if the camera can see their head / root (on screen, nothing solid
-- in between; glass-like parts are see-through), else nil. Shared by Player Autofocus and
-- the Focus Box/Circle person mode.
function rcb.visiblePersonPos(cam, pc, filter)
	local camPos = cam.CFrame.Position
	for _, name in ipairs({"Head", "HumanoidRootPart"}) do
		local p = pc:FindFirstChild(name)
		if p then
			local _, onScreen = cam:WorldToViewportPoint(p.Position)
			if onScreen then
				local d = p.Position - camPos
				local res = d.Magnitude > 0.05 and castVisible(camPos, d * 1.02 + d.Unit * 0.25, filter, 0.6, true)
				if (not res) or res.Instance:IsDescendantOf(pc) then return p.Position end
			end
		end
	end
	return nil
end

-- ---------- focus source: override > self (inactivity) > normal ----------
function rcb.isFirstPerson(cam, char)
	local head = char and char:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return (cam.CFrame.Position - cam.Focus.Position).Magnitude < 1.5
	end
	if (cam.CFrame.Position - head.Position).Magnitude < 1.5 then return true end
	return head.LocalTransparencyModifier >= 0.95 -- Roblox hides your own head in first person
end

-- Same check for callers outside the per-frame loop (e.g. the overlay's "always show" rule).
function rcb.isFirstPersonNow()
	local cam = workspace.CurrentCamera
	return cam ~= nil and rcb.isFirstPerson(cam, lp.Character)
end

-- Runs every frame. "Activity" = my character actually moving, plus (optionally)
-- the CAMERA actually panning / zooming. Mouse-cursor movement is deliberately
-- not looked at: only real camera rotation, zoom distance and FOV changes count.
-- Does nothing while Focus on Self After Inactivity is Off.
function rcb.updateActivity(cam, dt)
	local now = os.clock()
	local tp = rcbConfig.tp
	if tp.idleSelfSeconds < 0.5 then
		-- feature is Off: no tracking; the timer starts fresh (no fake movement spike) when it is switched on
		rs.lastActivity = now
		rs.prevRootPos, rs.prevLook, rs.prevZoom, rs.prevFov = nil, nil, nil, nil
		return
	end
	local char = lp.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	local active = false

	if root then
		local p = root.Position
		if rs.prevRootPos and dt > 0 and (p - rs.prevRootPos).Magnitude / dt > 0.5 then active = true end
		rs.prevRootPos = p
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0.05 then active = true end -- trying to move counts too
	else
		rs.prevRootPos = nil
	end

	local cf = cam.CFrame
	local look = cf.LookVector
	local zoom = (cf.Position - cam.Focus.Position).Magnitude
	local fov = cam.FieldOfView
	if tp.idleMode == "MoveCam" and dt > 0 then
		if rs.prevLook and math.deg(math.acos(math.clamp(look:Dot(rs.prevLook), -1, 1))) / dt > 1 then active = true end -- > 1 deg/s pan
		if rs.prevZoom and math.abs(zoom - rs.prevZoom) / dt > 0.3 then active = true end                               -- zoom in/out
		if rs.prevFov and math.abs(fov - rs.prevFov) / dt > 1 then active = true end                                    -- FOV zoom
	end
	-- always keep these current so switching the mode never causes a fake "movement" spike
	rs.prevLook, rs.prevZoom, rs.prevFov = look, zoom, fov

	if active then rs.lastActivity = now end
end

-- Is the momentary key / mouse button held right now? (polled, so a missed
-- release event can never leave it stuck on)
function rcb.momentaryHeld()
	local key = rcbConfig.momentaryKey
	if key == "MouseButton1" or key == "MouseButton2" or key == "MouseButton3" then
		return UserInputService:IsMouseButtonPressed(Enum.UserInputType[key])
	end
	if UserInputService:GetFocusedTextBox() then return false end -- typing in a box
	local ok, kc = pcall(function() return Enum.KeyCode[key] end)
	return ok and kc ~= nil and UserInputService:IsKeyDown(kc)
end

-- When is the override allowed? Locked = mouse locked while NOT in first person.
function rcb.momentaryScopeOk(fp)
	local locked = UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
	local scope = rcbConfig.momentaryScope
	if scope == "First" then return fp end
	if scope == "Locked" then return (not fp) and locked end
	return fp or locked
end

-- Priority: 1) momentary override while the key is held, 2) focus on self
-- after inactivity (3rd person only), 3) normal autofocus. `fp` = first person.
function rcb.focusSource(char, fp)
	local c = rcbConfig
	if c.momentaryEnabled and not rcb.capturingKey and rcb.momentaryHeld() and rcb.momentaryScopeOk(fp) then
		return "override"
	end
	local secs = c.tp.idleSelfSeconds
	if secs >= 1 and char and not fp and (os.clock() - rs.lastActivity) >= secs then
		return "self"
	end
	return "normal"
end

-- Is the player-focus override allowed right now?
local function playerOverrideAllowed(cam, char)
	if not (rcbConfig.lockPlayer or rcbConfig.dirPriority) then return false end
	if not rcbConfig.disableWhenZoomedOut then return true end
	local head = char and char:FindFirstChild("Head")
	local anchor = (head and head:IsA("BasePart")) and head.Position or cam.Focus.Position
	return (cam.CFrame.Position - anchor).Magnitude <= rcbConfig.zoomThreshold
end

-- Visible players -> pick one (range, optional look-direction cone, stickiness).
local function samplePlayerTarget(cam, char)
	local cfg, sub = rcbConfig, rs.sub
	local camPos = cam.CFrame.Position
	local dirVec = cam.CFrame.LookVector
	if cfg.cursorEnabled then
		local m = UserInputService:GetMouseLocation()
		dirVec = cam:ViewportPointToRay(m.X, m.Y).Direction
	elseif sub.target == "Area" then
		local vp = cam.ViewportSize
		local g = rcb.areaGeometry(vp, sub, cam)
		dirVec = cam:ViewportPointToRay(math.clamp(g.cx, 0, vp.X - 1), math.clamp(g.cy, 0, vp.Y - 1)).Direction
	end
	local filter = char and {char, cam} or {cam}

	local pool = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local pc = plr ~= lp and plr.Character
		if pc then
			local hum = pc:FindFirstChildOfClass("Humanoid")
			local aim = pc:FindFirstChild("Head") or pc:FindFirstChild("HumanoidRootPart")
			if aim and aim:IsA("BasePart") and (not hum or hum.Health > 0) then
				local dist = (aim.Position - camPos).Magnitude
				if dist <= cfg.playerRange and dist >= rcb.MIN_DIST then
					local seenPos = rcb.visiblePersonPos(cam, pc, filter)
					if seenPos then
						local toP = (seenPos - camPos).Unit
						local ang = math.deg(math.acos(math.clamp(dirVec.Unit:Dot(toP), -1, 1)))
						table.insert(pool, {plr = plr, pos = seenPos, dist = dist, angle = ang})
					end
				end
			end
		end
	end
	if #pool == 0 then return nil end

	local candidates = pool
	if cfg.dirPriority then
		local inCone = {}
		for _, c in ipairs(pool) do
			if c.angle <= cfg.dirAngle then table.insert(inCone, c) end
		end
		if #inCone > 0 then
			candidates = inCone
		elseif not cfg.lockPlayer then
			return nil
		end
	end

	-- score: lower is better. Distance first; players nearer the look direction get a bonus.
	local function score(c)
		local s = c.dist
		if cfg.dirPriority and c.angle <= cfg.dirAngle then
			s = s * (1 + 0.35 * c.angle / math.max(cfg.dirAngle, 1))
		end
		if c.plr == rs.lockedPlayer then s = s * 0.8 end -- stickiness: challenger must be ~20% better
		return s
	end
	local best, bestScore
	for _, c in ipairs(candidates) do
		local sc = score(c)
		if not bestScore or sc < bestScore then best, bestScore = c, sc end
	end
	return {plr = best.plr, key = "P:" .. best.plr.UserId, depth = cameraDepth(cam, best.pos)}
end

-- One measurement -> (key, depth, label) or nil.
local function rcbMeasure(cam, src)
	local char, sub = lp.Character, rs.sub

	-- 1) momentary override: forced screen-centre focus; if nothing is hit
	--    (e.g. aiming at the sky) hold the current focus rather than snapping back
	if src == "override" then
		rs.lockedPlayer = nil
		return rcb.sampleMomentary(cam)
	end
	-- 2) inactivity: focus on my own character (falls through if it is off-screen)
	if src == "self" then
		local k, d, l = rcb.sampleSelf(cam, char)
		if k then
			rs.lockedPlayer = nil
			return k, d, l
		end
	end

	-- 3) normal autofocus: player override > Cursor Auto Focus > this camera mode's target
	if playerOverrideAllowed(cam, char) then
		local c = samplePlayerTarget(cam, char)
		if c then
			rs.lockedPlayer = c.plr
			return c.key, c.depth, "Player: " .. c.plr.DisplayName
		end
	end
	rs.lockedPlayer = nil

	local cursor = rcbConfig.cursorEnabled
	if not cursor and sub.target == "Area" then
		return rcb.sampleArea(cam, char, sub, rs.fp) -- may set rs.lockedPlayer (person mode)
	end
	local x, y
	if cursor then
		local m = UserInputService:GetMouseLocation()
		x, y = m.X, m.Y
	else
		local vp = cam.ViewportSize
		x, y = vp.X / 2, vp.Y / 2
	end
	local ray = cam:ViewportPointToRay(x, y)
	local res = castVisible(ray.Origin, ray.Direction * 2000, rcb.rayFilter(cam, sub, rs.fp), INVISIBLE_PASS, false, true, rcb.MIN_DIST)
	if not res then return nil end
	return res.Instance, cameraDepth(cam, res.Position), cursor and "Cursor" or "Screen Center"
end

-- ---------- focus transitions ----------
-- `forced` (seconds) replaces the normal time/distance-mixed duration; used for the one
-- transition to self after inactivity.
local function startTransition(to, forced)
	local from = rs.currentFocus
	if not from or from <= 0 then
		rs.currentFocus = to
		rs.animating = false
		return
	end
	local dur
	if forced then
		dur = math.clamp(forced, 0.05, 5)
	else
		local timeDur = rcbConfig.focusTime
		local octaves = math.abs(math.log(to / from) / math.log(2))
		local distDur = octaves / math.max(rcbConfig.focusSpeed, 0.05)
		local mix = rcbConfig.timeDistMix / 100
		dur = math.clamp(timeDur * (1 - mix) + distDur * mix, 0.05, 5)
	end
	rs.from, rs.to, rs.elapsed, rs.duration, rs.animating = from, to, 0, dur, true
end

local function curveValue(from, to, t)
	if rcbConfig.curve == "Linear" then
		return from + (to - from) * t
	end
	-- Logarithmic: interpolate in log-distance (constant RATIO per unit time, so a
	-- 5 -> 400 stud pull doesn't blast through the near range) with a soft ease.
	local e = t * t * (3 - 2 * t)
	return from * (to / from) ^ e
end

-- Stability: median of recent depths + dead-band. The focus target only changes
-- when the filtered distance moves meaningfully; tiny raycast jitter is ignored.
local function processSample(key, depth)
	depth = math.max(depth, 0.8)
	-- one-shot transition time for the move to self; consumed by the first sample after the switch,
	-- and only applied if that sample really is the self target (not a fall-back measurement)
	local forced = (key == "SELF") and rs.pendingDur or nil
	rs.pendingDur = nil
	if rs.lastValidTime and os.clock() - rs.lastValidTime > 1 then
		table.clear(rs.history) -- stale readings from before a gap shouldn't vote
	end
	local h = rs.history
	table.insert(h, depth)
	if #h > 5 then table.remove(h, 1) end
	local sorted = table.clone(h)
	table.sort(sorted)
	local med = sorted[math.ceil(#sorted / 2)]
	rs.lastValidTime = os.clock()

	if rs.targetDist == nil then
		-- first valid target (e.g. just enabled): snap, don't rack focus from nowhere
		rs.targetDist, rs.targetKey = med, key
		rs.currentFocus = med
		rs.animating = false
		return
	end
	local dead = math.max(0.35, rs.targetDist * 0.03)
	if math.abs(med - rs.targetDist) > dead then
		rs.targetDist = med
		startTransition(med, forced)
	end
	rs.targetKey = key
end

-- ---------- simulated lens ----------
-- A thin-lens model with a virtual sensor. 1 stud ~ 0.28 m. The focal length
-- comes from the camera FOV (70 deg vertical == a "normal" 50 mm lens), the
-- f-stop from the Aperture control. Everything is a continuous function of the
-- focus distance -- there are no distance bands.
local STUD_MM = 280
local SENSOR_H = 70          -- mm (virtual)
local COC = SENSOR_H / 800   -- accepted circle of confusion
local NEAR_REF_MM = 6000     -- reference foreground distance (~21 studs)
local K_FAR, K_NEAR = 0.003, 0.006

local function computeLens(focusStuds, fovDeg, aperture)
	local f = math.clamp(SENSOR_H * 0.5 / math.tan(math.rad(math.clamp(fovDeg, 5, 120)) * 0.5), 14, 400)
	local N = math.clamp(aperture, 0.95, 32)
	local s = math.max(focusStuds * STUD_MM, f * 2)
	local sf = s - f
	local H = f * f / (N * COC) + f -- hyperfocal distance

	-- depth of field: sharp from nearLim to farLim
	local nearLim = H * s / (H + sf)
	local farLim = (sf >= H) and math.huge or (H * s / (H - sf))
	-- Roblox's in-focus zone is SYMMETRIC about FocusDistance: [focus - r, focus + r]. Foreground
	-- blur only exists in front of focus - r, so if r >= focus the whole foreground is "in focus"
	-- and NearIntensity does nothing. The old code averaged the near and far half-depths, which
	-- for a far focus (far limit = infinity) gave r ~ 2000 studs and erased the foreground blur.
	-- Anchor the zone to the real near limit instead (a little slack toward the far side).
	local nearHalf = math.max((s - nearLim) / STUD_MM, 0.1)
	local farHalf = (farLim == math.huge) and 2000 or math.min((farLim - s) / STUD_MM, 2000)
	local avgHalf = (nearHalf + farHalf) / 2
	local radius = math.max(math.min(avgHalf, nearHalf * 1.3), 0.1)

	-- blur strengths from blur-disc size (mm on sensor, relative to sensor height)
	local fsq = f * f / N
	local cBg = fsq / sf                                              -- disc for a point at infinity
	local cFg = fsq * math.max(s - NEAR_REF_MM, 0) / (NEAR_REF_MM * sf) -- disc for a close foreground object
	local bg = 1 - math.exp(-(cBg / SENSOR_H) / K_FAR)
	local fg = 1 - math.exp(-(cFg / SENSOR_H) / K_NEAR)
	return radius, fg, bg
end

-- ---------- per-frame update ----------
-- Camera mode (read once per frame: 1st person uses cfg.fp, 3rd person cfg.tp) and the focus
-- source: override > self-after-inactivity > normal. Returns the source.
function rcb.selectSource(cam, dt, cfg)
	local char = lp.Character
	rs.fp = rcb.isFirstPerson(cam, char)
	rs.sub = rs.fp and cfg.fp or cfg.tp
	rcb.updateActivity(cam, dt)
	local src = rcb.focusSource(char, rs.fp)
	if src ~= rs.source or rs.fp ~= rs.prevFp then
		if src ~= rs.source then
			-- moving to self after inactivity takes its own transition time instead of the normal speed
			rs.pendingDur = (src == "self") and cfg.tp.idleTransition or nil
		end
		rs.source, rs.prevFp = src, rs.fp
		table.clear(rs.history)               -- old readings must not vote for the new source / mode
		rs.sampleAccum = RCB_SAMPLE_INTERVAL  -- measure immediately, don't wait for the next tick
	end
	return src
end

-- Errors are shown in the status line and warned once per distinct message (they used to be
-- warned once EVER, so a later, different failure was invisible while focus silently froze).
function rcb.reportError(err)
	err = tostring(err)
	rs.label = "Error (see console): " .. err:sub(1, 70)
	if rs.lastErr ~= err then
		rs.lastErr = err
		warn("[LightingUtility] Real Camera Blur autofocus error: " .. err)
	end
end

local function rcbFrame(dt)
	if not CamSys.dofActive then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	ensureDoF()
	local cfg = rcbConfig

	-- camera mode + who decides the focus (protected: a failure here must never stop the lens update)
	local okS, src = pcall(rcb.selectSource, cam, dt, cfg)
	if not okS then
		rcb.reportError(src)
		src = "normal"
	end

	rs.sampleAccum += dt
	if rs.sampleAccum >= RCB_SAMPLE_INTERVAL then
		rs.sampleAccum = 0
		local ok, key, depth, label = pcall(rcbMeasure, cam, src)
		if ok and key and depth then
			rs.label = label
			processSample(key, depth)
		elseif ok then
			rs.label = "No target (holding focus)"
		else
			rcb.reportError(key)
		end
	end

	if rs.currentFocus == nil then
		rs.currentFocus = math.clamp(CamSys.dofBase.FocusDistance or 50, 1, 2000)
	end
	if rs.animating then
		rs.elapsed += dt
		local t = math.clamp(rs.elapsed / math.max(rs.duration, 0.01), 0, 1)
		rs.currentFocus = curveValue(rs.from, rs.to, t)
		if t >= 1 then
			rs.currentFocus = rs.to
			rs.animating = false
		end
	end

	local fd = math.clamp(rs.currentFocus, 1, 2000)
	local radius, fg, bg = computeLens(fd, cam.FieldOfView, cfg.aperture)

	-- keep the subject itself comfortably inside the in-focus zone
	local subjectFloor = 1.5 + 0.02 * fd
	if rs.lockedPlayer then
		subjectFloor = math.max(subjectFloor, 2.5)
		if cfg.autoAdjustRange then
			-- close player -> tight range, far player -> progressively wider (smooth, no bands)
			local t = smoothstep(4, 100, fd)
			radius = radius * (0.5 + 1.4 * t)
		end
	end
	radius = math.max(radius, subjectFloor)

	-- user lens controls on top of the automatic calculation
	radius = math.max(radius * cfg.rangeMult, 0.25)
	-- never let the zone's near edge reach the camera, or foreground blur silently vanishes
	-- (player auto-range, subject floor and the range multiplier can all push radius up)
	radius = math.min(radius, math.max(fd * 0.92, 0.25))
	fg = math.clamp(fg * cfg.fgMult + cfg.fgOffset, 0, 1)
	bg = math.clamp(bg * cfg.bgMult + cfg.bgOffset, 0, 1)

	-- light output smoothing (also hides FOV changes / tiny lens jitter)
	if rs.outRadius == nil then
		rs.outRadius, rs.outNear, rs.outFar = radius, fg, bg
	else
		local a = expAlpha(dt, 0.12)
		rs.outRadius = math.exp(math.log(rs.outRadius) + (math.log(radius) - math.log(rs.outRadius)) * a)
		rs.outNear += (fg - rs.outNear) * a
		rs.outFar += (bg - rs.outFar) * a
	end

	local set = CamSys.set
	set(depthOfField, "Enabled", true)
	set(depthOfField, "FocusDistance", fd)
	set(depthOfField, "InFocusRadius", rs.outRadius)
	set(depthOfField, "NearIntensity", rs.outNear)
	set(depthOfField, "FarIntensity", rs.outFar)
end

function rcb.GetStatus()
	if not CamSys.dofActive then return "OFF -- normal DepthOfField settings are in control." end
	return string.format("ON | %s | %s | focus %.1f studs | zone +/-%.1f | FG %.2f / BG %.2f",
		rs.fp and "1st person" or "3rd person", rs.label or "?", rs.currentFocus or 0, rs.outRadius or 0, rs.outNear or 0, rs.outFar or 0)
end

-- debounced persistence of the Real Camera Blur configuration
local saveDirty, saveTimer = false, 0
-- trailing debounce: every change restarts the timer, so the file is written ONCE,
-- 1 s after the last change (it used to be rewritten ~1x/second during a drag)
function rcb.MarkDirty() saveDirty = true; saveTimer = 0 end
CamSys.nextName = "settingsSave"
CamSys.track(RunService.Heartbeat, function(dt)
	if not saveDirty then return end
	saveTimer += dt
	if saveTimer < 1.0 then return end
	saveTimer, saveDirty = 0, false
	saveJSONFile(SETTINGS_FILE, savedSettings)
end)

-- ============================================================
-- AUTOMATIC EXPOSURE + AUTOMATIC WHITE BALANCE
-- ============================================================
local autoCam = {aeStrength = 0, awbStrength = 0, speed = 1, status = "AE / AWB off"}
CamSys.autoCam = autoCam

local ac = {
	accum = 1, active = false,
	meterLn = nil, aeTarget = 0, aeSmoothed = 0,
	wbMeas = nil, tintMeas = nil, wbTarget = 0, tintTarget = 0, wbSmoothed = 0, tintSmoothed = 0,
}
local AC_COLS, AC_ROWS, AC_INTERVAL = 7, 5, 0.25
local AE_TARGET = 0.4 -- metering target in this estimator's units; calibrated so a typical sunlit Roblox daytime scene sits near 0 EV
local AE_MAX_EV = 3.5

local function normalizeMean(v)
	local m = (v.X + v.Y + v.Z) / 3
	if m < 0.02 then return Vector3.one end
	return v / m
end

local function acSample(cam)
	local vp = cam.ViewportSize
	local char = lp.Character
	local filter = char and {char} or {}
	local sunDir = Lighting:GetSunDirection()
	local sunUp = smoothstep(-0.05, 0.25, sunDir.Y)
	local brightScale = math.clamp(Lighting.Brightness / 3, 0, 2)
	local ambIn, ambOut = Lighting.Ambient, Lighting.OutdoorAmbient

	local sumW, sumLn = 0, 0
	local awbSum, awbN = Vector3.zero, 0 -- plain (unweighted) sum of on-screen surface colours

	for ix = 1, AC_COLS do
		for iy = 1, AC_ROWS do
			local nx, ny = (ix - 0.5) / AC_COLS, (iy - 0.5) / AC_ROWS
			local rx, ry = (nx - 0.5) * 2, (ny - 0.5) * 2
			local w = 0.3 + 0.7 * (1 - math.min((rx * rx + ry * ry) / 2, 1)) -- centre-weighted metering
			local ray = cam:ViewportPointToRay(nx * vp.X, ny * vp.Y)
			local res = castVisible(ray.Origin, ray.Direction * 1500, filter, 0.85, false)
			local L
			if res then
				local inst = res.Instance
				local col, emissive = Color3.new(0.5, 0.5, 0.5), false
				if inst and inst:IsA("Terrain") then
					local ok, c = pcall(function() return workspace.Terrain:GetMaterialColor(res.Material) end)
					if ok and c then col = c end
				elseif inst and inst:IsA("BasePart") then
					col = inst.Color
					emissive = inst.Material == Enum.Material.Neon
				end
				local o = res.Position + res.Normal * 0.15
				local skyOpen = castVisible(o, Vector3.new(0, 400, 0), filter, 0.6, true) == nil
				local sunHit = false
				if sunUp > 0.02 then
					sunHit = castVisible(o, sunDir * 1000, filter, 0.6, true) == nil
				end
				local amb = lumGamma(ambIn:Lerp(ambOut, skyOpen and 1 or 0))
				local ndl = math.max(res.Normal:Dot(sunDir), 0)
				local irr = 0.12 + 1.1 * amb
				if sunHit then irr += 0.9 * brightScale * sunUp * (0.15 + 0.85 * ndl) end
				L = lumLinear(col) * irr * (emissive and 4 or 1)

				awbSum += Vector3.new(col.R, col.G, col.B)
				awbN += 1
			else
				L = (0.02 + 0.9 * sunUp) * (0.6 + 0.4 * brightScale) -- sky
			end
			sumLn += w * math.log(math.max(L, 0.003))
			sumW += w
		end
	end
	if sumW <= 0 then return end

	-- ----- Auto Exposure: log-average luminance -> EV toward mid-grey -----
	local avgLn = sumLn / sumW
	ac.meterLn = ac.meterLn and (ac.meterLn + (avgLn - ac.meterLn) * 0.35) or avgLn
	local rawEV = (math.log(AE_TARGET) - ac.meterLn) / math.log(2)
	local ev = AE_MAX_EV * tanh(rawEV / AE_MAX_EV) -- soft limit
	if math.abs(ev - ac.aeTarget) > 0.12 then ac.aeTarget = ev end -- hysteresis

	-- ----- Auto White Balance: gray-world on the SCREEN AVERAGE -----
	-- The colour of everything visible (equal weight per sample point, no centre weighting, no
	-- lighting / sun / ambient model) is averaged and pushed toward neutral. Only what the grid
	-- hits counts; sky samples have no readable colour and are skipped. If almost nothing
	-- solid is on screen the previous correction is kept.
	if awbN < 3 then return end
	local avg = awbSum / awbN
	local gains = normalizeMean(Vector3.new(1 / math.max(avg.X, 0.05), 1 / math.max(avg.Y, 0.05), 1 / math.max(avg.Z, 0.05)))
	-- map the correcting gains onto the EXISTING white balance / tint model:
	-- R = 1 + wb*S + tint*S/2,  G = 1 - tint*S,  B = 1 - wb*S + tint*S/2
	local wb = math.clamp((gains.X - gains.Z) / (2 * WB_STRENGTH), -1, 1)
	local tint = math.clamp((1 - gains.Y) / TINT_STRENGTH, -1, 1)
	if ac.wbMeas == nil then
		ac.wbMeas, ac.tintMeas = wb, tint
	else
		ac.wbMeas += (wb - ac.wbMeas) * 0.35
		ac.tintMeas += (tint - ac.tintMeas) * 0.35
	end
	if math.abs(ac.wbMeas - ac.wbTarget) > 0.04 or math.abs(ac.tintMeas - ac.tintTarget) > 0.04 then
		ac.wbTarget, ac.tintTarget = ac.wbMeas, ac.tintMeas
	end
end

local acErrorShown = false
local function acFrame(dt)
	local aeOn = autoCam.aeStrength > 0.01
	local awbOn = autoCam.awbStrength > 0.01
	if not aeOn and not awbOn then
		if ac.active then
			ac.active = false
			ac.meterLn, ac.wbMeas, ac.tintMeas = nil, nil, nil
			ac.aeTarget, ac.aeSmoothed = 0, 0
			ac.wbTarget, ac.tintTarget, ac.wbSmoothed, ac.tintSmoothed = 0, 0, 0, 0
			CamSys.autoExposureEV, CamSys.autoWB, CamSys.autoTint = 0, 0, 0
			recomputeExposure()
			recomputeTint()
			autoCam.status = "AE / AWB off"
		end
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	ac.active = true

	ac.accum += dt
	if ac.accum >= AC_INTERVAL then
		ac.accum = 0
		local ok, err = pcall(acSample, cam)
		if not ok and not acErrorShown then
			acErrorShown = true
			warn("[LightingUtility] Auto exposure / white balance sampling error: " .. tostring(err))
		end
	end

	local spd = math.max(autoCam.speed, 0.05)
	local newEV, newWB, newTint = 0, 0, 0
	if aeOn then
		-- brighter scene (target < current) -> reduce exposure a bit faster than we raise it
		local tau = ((ac.aeTarget < ac.aeSmoothed) and 0.8 or 1.8) / spd
		ac.aeSmoothed += (ac.aeTarget - ac.aeSmoothed) * expAlpha(dt, tau)
		newEV = ac.aeSmoothed * autoCam.aeStrength / 100
	else
		ac.aeSmoothed, ac.aeTarget, ac.meterLn = 0, 0, nil
	end
	if awbOn then
		local a = expAlpha(dt, 2.5 / spd)
		ac.wbSmoothed += (ac.wbTarget - ac.wbSmoothed) * a
		ac.tintSmoothed += (ac.tintTarget - ac.tintSmoothed) * a
		newWB = ac.wbSmoothed * autoCam.awbStrength / 100
		newTint = ac.tintSmoothed * autoCam.awbStrength / 100
	else
		ac.wbSmoothed, ac.tintSmoothed, ac.wbTarget, ac.tintTarget = 0, 0, 0, 0
		ac.wbMeas, ac.tintMeas = nil, nil
	end

	if math.abs(newEV - CamSys.autoExposureEV) > 1e-4 then
		CamSys.autoExposureEV = newEV
		recomputeExposure()
	end
	if math.abs(newWB - CamSys.autoWB) > 1e-4 or math.abs(newTint - CamSys.autoTint) > 1e-4 then
		CamSys.autoWB, CamSys.autoTint = newWB, newTint
		recomputeTint()
	end
	autoCam.status = string.format("AE %+.2f EV | AWB warmth %+.0f, tint %+.0f",
		CamSys.autoExposureEV, CamSys.autoWB * 100, CamSys.autoTint * 100)
end

-- ---------- bind ----------
pcall(function() RunService:UnbindFromRenderStep("LiUt_AutoExposureWB") end)
pcall(function() RunService:UnbindFromRenderStep("LiUt_RealCameraBlur") end)
-- AE/AWB run just after the camera updates; Real Camera Blur runs LAST so it wins
-- any same-frame write to the DepthOfFieldEffect.
RunService:BindToRenderStep("LiUt_AutoExposureWB", Enum.RenderPriority.Camera.Value + 1, CamSys.timed("autoExposureWB", acFrame))
RunService:BindToRenderStep("LiUt_RealCameraBlur", Enum.RenderPriority.Last.Value, CamSys.timed("realCameraBlur", rcbFrame))

-- Used by the single-instance guard: if this script is run again, the NEW run
-- calls this on the OLD one (it hands the DepthOfFieldEffect back and unbinds).
do
	local env = (type(getgenv) == "function" and getgenv()) or _G
	env.__LiUtRelease = function()
		pcall(function() CamSys.light.shutdown() end)
		pcall(function() if CamSys.dofActive and CamSys.rcb then CamSys.rcb.SetEnabled(false) end end)
		pcall(function() RunService:UnbindFromRenderStep("LiUt_AutoExposureWB") end)
		pcall(function() RunService:UnbindFromRenderStep("LiUt_RealCameraBlur") end)
		pcall(function()
			if colorCorrectionWasCreated then colorCorrection:Destroy() end
			if sunRaysWasCreated then sunRays:Destroy() end
			if atmosphereWasCreated then atmosphere:Destroy() end
			if bloomWasCreated then bloom:Destroy() end
			if blurWasCreated then blur:Destroy() end
			if depthOfFieldWasCreated then depthOfField:Destroy() end
		end)
	end
end
end

-- ============================================================
-- UI Shell
-- ============================================================
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LightingUtility"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Dex Explorer style UI Parenting
local uiParent
if type(gethui) == "function" then
	uiParent = gethui() -- Best option when the runtime provides a private UI parent
else
	local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if success and coreGui then
		uiParent = coreGui -- Runtime-provided CoreGui parent
	else
		uiParent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") -- Fallback for standard Studio testing
	end
end

screenGui.Parent = uiParent

-- ============================================================
-- Theme -- a modern dark/"glass" palette. Roblox UI has no true
-- backdrop-blur (BlurEffect only blurs the whole 3D viewport, not
-- specifically what's behind one UI panel), so the glass look here comes
-- from layered translucency + a soft gradient sheen + a gradient edge
-- stroke instead -- the closest approximation that doesn't blur the game
-- world while the panel's open.
-- ============================================================
local THEME_ACCENT = Color3.fromRGB(64, 170, 255)
local THEME_PANEL = Color3.fromRGB(18, 19, 24)
local THEME_PANEL_TRANSPARENCY = 0.08
local THEME_HEADER = Color3.fromRGB(30, 31, 38)

local frame = Instance.new("CanvasGroup")
frame.Size = UDim2.new(0, 380, 0, 560)
frame.Position = UDim2.new(0.05, 0, 0.1, 0)
frame.BackgroundColor3 = THEME_PANEL
frame.BackgroundTransparency = THEME_PANEL_TRANSPARENCY
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameScale = Instance.new("UIScale")
frameScale.Scale = 1
frameScale.Parent = frame

do
do
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame
end

-- Soft top-to-bottom sheen (lighter at the top) -- the classic
-- "glassmorphism" highlight cue, layered on top of the translucent fill.
-- NOTE: a UIGradient parented directly to a CanvasGroup tints EVERY child
-- (text, buttons, everything) -- that's what made the UI unreadable. The
-- sheen lives on its own background frame behind the content instead.
local sheen = Instance.new("Frame")
sheen.Name = "Sheen"
sheen.Size = UDim2.new(1, 0, 1, 0)
sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sheen.BorderSizePixel = 0
sheen.ZIndex = 0
sheen.Active = false
sheen.Parent = frame
local sheenCorner = Instance.new("UICorner")
sheenCorner.CornerRadius = UDim.new(0, 12)
sheenCorner.Parent = sheen
local sheenGradient = Instance.new("UIGradient")
sheenGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.9),
	NumberSequenceKeypoint.new(0.3, 0.98),
	NumberSequenceKeypoint.new(1, 1),
})
sheenGradient.Rotation = 90
sheenGradient.Parent = sheen

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(255, 255, 255)
frameStroke.Transparency = 0.72
frameStroke.Thickness = 1
frameStroke.Parent = frame

local frameStrokeGradient = Instance.new("UIGradient")
frameStrokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, THEME_ACCENT),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})
frameStrokeGradient.Rotation = 90
frameStrokeGradient.Parent = frameStroke
end


-- Title bar (drag handle lives here ONLY, fixes the drag-vs-click bug)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = THEME_HEADER
titleBar.BackgroundTransparency = 0.05
titleBar.BorderSizePixel = 0
titleBar.Active = true
titleBar.Parent = frame

do
local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 12)
titleBarCorner.Parent = titleBar
end

-- mask the bottom corners of the title bar so it reads as a flat header
do
local titleBarMask = Instance.new("Frame")
titleBarMask.Size = UDim2.new(1, 0, 0, 12)
titleBarMask.Position = UDim2.new(0, 0, 1, -12)
titleBarMask.BackgroundColor3 = titleBar.BackgroundColor3
titleBarMask.BackgroundTransparency = titleBar.BackgroundTransparency
titleBarMask.BorderSizePixel = 0
titleBarMask.ZIndex = 1
titleBarMask.Parent = titleBar
end

do
local titleBarDivider = Instance.new("Frame")
titleBarDivider.Size = UDim2.new(1, 0, 0, 1)
titleBarDivider.Position = UDim2.new(0, 0, 1, -1)
titleBarDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleBarDivider.BackgroundTransparency = 0.9
titleBarDivider.BorderSizePixel = 0
titleBarDivider.ZIndex = 2
titleBarDivider.Parent = titleBar
end


local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -114, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Lighting Utility"
title.TextColor3 = Color3.fromRGB(240, 240, 245)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -114, 1, 0)
title.Position = UDim2.new(0, 130, 0, 0)
title.BackgroundTransparency = 1
title.Text = "| by claude & kalel"
title.TextColor3 = Color3.fromRGB(180, 220, 245)
title.TextSize = 14
-- Changed from GothamBold to regular Gotham
title.Font = Enum.Font.Gotham 
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2
title.Parent = titleBar

-- Minimized state: a small draggable pill that replaces the full window
local minimizedIcon = Instance.new("TextButton")
minimizedIcon.Name = "MinimizedIcon"
minimizedIcon.Size = UDim2.new(0, 46, 0, 46)
minimizedIcon.Position = UDim2.new(0.05, 0, 0.1, 0)
minimizedIcon.BackgroundColor3 = Color3.fromRGB(24, 24, 26)
minimizedIcon.Text = "LU"
minimizedIcon.TextColor3 = Color3.fromRGB(240, 240, 245)
minimizedIcon.Font = Enum.Font.GothamBold
minimizedIcon.TextSize = 14
minimizedIcon.AutoButtonColor = false
minimizedIcon.Active = true
minimizedIcon.Visible = false
minimizedIcon.ZIndex = 5
minimizedIcon.Parent = screenGui

do
local minimizedIconCorner = Instance.new("UICorner")
minimizedIconCorner.CornerRadius = UDim.new(1, 0)
minimizedIconCorner.Parent = minimizedIcon
end

local minimizedIconStroke = Instance.new("UIStroke")
minimizedIconStroke.Color = Color3.fromRGB(60, 60, 65)
minimizedIconStroke.Thickness = 1
minimizedIconStroke.Parent = minimizedIcon

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -72, 0.5, -14)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 2
minimizeBtn.Parent = titleBar

do
local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeBtn
end

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 2
closeBtn.Parent = titleBar

do
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
end

local minimizedIconScale = Instance.new("UIScale")
minimizedIconScale.Scale = 1
minimizedIconScale.Parent = minimizedIcon

local POPUP_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local POPDOWN_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- Smoothly shrinks+fades `target` (a CanvasGroup, using GroupTransparency)
-- using `scaleObj`, then hides it and calls onComplete.
local function animateHide(target, scaleObj, onComplete)
	local tw1 = TweenService:Create(scaleObj, POPDOWN_TWEEN_INFO, {Scale = 0.05})
	local tw2 = TweenService:Create(target, POPDOWN_TWEEN_INFO, {GroupTransparency = 1})
	tw1:Play()
	tw2:Play()
	tw2.Completed:Connect(function()
		target.Visible = false
		target.GroupTransparency = 0
		scaleObj.Scale = 1
		if onComplete then onComplete() end
	end)
end

-- Shows `target` and pops it in from nothing with a slight overshoot.
local function animateShow(target, scaleObj)
	target.GroupTransparency = 1
	scaleObj.Scale = 0.05
	target.Visible = true
	TweenService:Create(scaleObj, POPUP_TWEEN_INFO, {Scale = 1}):Play()
	TweenService:Create(target, POPUP_TWEEN_INFO, {GroupTransparency = 0}):Play()
end

-- minimizedIcon is a plain TextButton (needs real click events, which a
-- CanvasGroup can't fire), so it fades via its own few properties instead
-- of GroupTransparency.
local function iconHide(onComplete)
	TweenService:Create(minimizedIconScale, POPDOWN_TWEEN_INFO, {Scale = 0.05}):Play()
	TweenService:Create(minimizedIcon, POPDOWN_TWEEN_INFO, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
	local tw = TweenService:Create(minimizedIconStroke, POPDOWN_TWEEN_INFO, {Transparency = 1})
	tw:Play()
	tw.Completed:Connect(function()
		minimizedIcon.Visible = false
		minimizedIconScale.Scale = 1
		minimizedIcon.BackgroundTransparency = 0
		minimizedIcon.TextTransparency = 0
		minimizedIconStroke.Transparency = 0
		if onComplete then onComplete() end
	end)
end

local function iconShow()
	minimizedIconScale.Scale = 0.05
	minimizedIcon.BackgroundTransparency = 1
	minimizedIcon.TextTransparency = 1
	minimizedIconStroke.Transparency = 1
	minimizedIcon.Visible = true
	TweenService:Create(minimizedIconScale, POPUP_TWEEN_INFO, {Scale = 1}):Play()
	TweenService:Create(minimizedIcon, POPUP_TWEEN_INFO, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
	TweenService:Create(minimizedIconStroke, POPUP_TWEEN_INFO, {Transparency = 0}):Play()
end

-- X = full uninstall: put every value back, release the camera/effects, disconnect everything,
-- destroy all GUIs and our effect instances. Saved presets on disk are left alone.
function CamSys.uninstall()
	if CamSys.uninstalling then return end
	CamSys.uninstalling = true
	local env = (type(getgenv) == "function" and getgenv()) or _G
	pcall(function() frame.Visible = false end)
	pcall(saveLastStateNow) -- only writes when "Remember Last Lighting" is on
	CamSys.autoExposureEV, CamSys.autoWB, CamSys.autoTint = 0, 0, 0
	pcall(resetToServerDefaults) -- Lighting values + effects back to the place's own, Override off
	pcall(function()
		if CamSys.skyCreated and CamSys.skyCreated.Parent then
			CamSys.skyCreated:Destroy()
		elseif CamSys.skySnap and CamSys.skySnap.inst.Parent then
			for prop, v in pairs(CamSys.skySnap) do
				if prop ~= "inst" then pcall(function() CamSys.skySnap.inst[prop] = v end) end
			end
		end
	end)
	-- disconnects every tracked connection, hands lights/neon + camera blur back, unbinds
	-- the render steps, destroys the effect instances this script created
	pcall(function() if type(env.__LiUtCleanup) == "function" then env.__LiUtCleanup() end end)
	-- read-spoof hooks can't be safely unhooked (something may sit on top of them): empty tables = pure pass-through
	pcall(function() local S = env.__LiUtSpoof; if S then S.ours, S.gv = {}, {} end end)
	pcall(function() screenGui:Destroy() end)
	pcall(function() if type(env.__LiUtSweep) == "function" then env.__LiUtSweep() end end)
	env.__LiUtConns, env.__LiUtSweep = nil, nil
end

closeBtn.MouseButton1Click:Connect(function()
	CamSys.uninstall()
end)

local minimizedIconWasDragged -- forward-declared; assigned once makeDraggable exists below

minimizeBtn.MouseButton1Click:Connect(function()
	minimizedIcon.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset)
	animateHide(frame, frameScale, iconShow)
end)

minimizedIcon.MouseButton1Click:Connect(function()
	if minimizedIconWasDragged() then return end
	frame.Position = UDim2.new(minimizedIcon.Position.X.Scale, minimizedIcon.Position.X.Offset, minimizedIcon.Position.Y.Scale, minimizedIcon.Position.Y.Offset)
	iconHide(function()
		animateShow(frame, frameScale)
	end)
end)

-- Reusable drag handler: dragging `handle` moves `target`. Used for the
-- title bar (moves the full window) and the minimized icon (moves itself).
local function makeDraggable(handle, target)
	local dragging = false
	local dragStart, startPos
	local moved = false

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	CamSys.track(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 2 then moved = true end
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	return function() return moved end
end

makeDraggable(titleBar, frame)
minimizedIconWasDragged = makeDraggable(minimizedIcon, minimizedIcon)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -50)
scroll.Position = UDim2.new(0, 10, 0, 44)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 95)
scroll.Parent = frame

do
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
end

-- ============================================================
-- Confirm Modal Helper -- a simple reusable "are you sure?" popup.
-- Sits directly in screenGui (not in the scroll/frame) so it overlays
-- the whole window regardless of scroll position.
-- ============================================================
local modalOverlay = Instance.new("Frame")
modalOverlay.Size = UDim2.new(1, 0, 1, 0)
modalOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
modalOverlay.BackgroundTransparency = 0.45
modalOverlay.Visible = false
modalOverlay.ZIndex = 10
modalOverlay.Parent = screenGui

local modalBox = Instance.new("Frame")
modalBox.Size = UDim2.new(0, 300, 0, 150)
modalBox.AnchorPoint = Vector2.new(0.5, 0.5)
modalBox.Position = UDim2.new(0.5, 0, 0.5, 0)
modalBox.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
modalBox.ZIndex = 11
modalBox.Parent = modalOverlay

do
local modalBoxCorner = Instance.new("UICorner")
modalBoxCorner.CornerRadius = UDim.new(0, 10)
modalBoxCorner.Parent = modalBox
end

do
local modalBoxStroke = Instance.new("UIStroke")
modalBoxStroke.Color = Color3.fromRGB(70, 70, 76)
modalBoxStroke.Thickness = 1
modalBoxStroke.Parent = modalBox
end

local modalText = Instance.new("TextLabel")
modalText.Size = UDim2.new(1, -24, 1, -64)
modalText.Position = UDim2.new(0, 12, 0, 14)
modalText.BackgroundTransparency = 1
modalText.TextWrapped = true
modalText.TextColor3 = Color3.fromRGB(225, 225, 230)
modalText.Font = Enum.Font.Gotham
modalText.TextSize = 13
modalText.ZIndex = 11
modalText.Parent = modalBox

local modalCancelBtn = Instance.new("TextButton")
modalCancelBtn.Size = UDim2.new(0.46, 0, 0, 34)
modalCancelBtn.Position = UDim2.new(0.02, 0, 1, -44)
modalCancelBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
modalCancelBtn.Text = "Cancel"
modalCancelBtn.TextColor3 = Color3.new(1, 1, 1)
modalCancelBtn.Font = Enum.Font.Gotham
modalCancelBtn.TextSize = 13
modalCancelBtn.ZIndex = 11
modalCancelBtn.Parent = modalBox

do
local modalCancelCorner = Instance.new("UICorner")
modalCancelCorner.CornerRadius = UDim.new(0, 6)
modalCancelCorner.Parent = modalCancelBtn
end

local modalConfirmBtn = Instance.new("TextButton")
modalConfirmBtn.Size = UDim2.new(0.46, 0, 0, 34)
modalConfirmBtn.Position = UDim2.new(0.52, 0, 1, -44)
modalConfirmBtn.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
modalConfirmBtn.Text = "Confirm"
modalConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
modalConfirmBtn.Font = Enum.Font.GothamBold
modalConfirmBtn.TextSize = 13
modalConfirmBtn.ZIndex = 11
modalConfirmBtn.Parent = modalBox

do
local modalConfirmCorner = Instance.new("UICorner")
modalConfirmCorner.CornerRadius = UDim.new(0, 6)
modalConfirmCorner.Parent = modalConfirmBtn
end

-- showConfirm(message, onConfirm): opens the popup; onConfirm is only
-- called if the user actually clicks Confirm.
local function showConfirm(message, onConfirm)
	modalText.Text = message
	modalOverlay.Visible = true

	local confirmConn, cancelConn
	local function cleanup()
		modalOverlay.Visible = false
		confirmConn:Disconnect()
		cancelConn:Disconnect()
	end

	confirmConn = modalConfirmBtn.MouseButton1Click:Connect(function()
		cleanup()
		onConfirm()
	end)
	cancelConn = modalCancelBtn.MouseButton1Click:Connect(function()
		cleanup()
	end)
end

-- ============================================================
-- Global Active Sliders Tracker for High Precision Dragging
-- ============================================================
local activeSliders = {}

CamSys.track(UserInputService.InputChanged, function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		for _, slider in ipairs(activeSliders) do
			slider:Update(input)
		end
	end
end)

CamSys.track(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		table.clear(activeSliders)
	end
end)

-- ============================================================
-- Collapsible Section Helper
-- ============================================================
local sectionOrder = 0
local function createSection(titleText, startOpen)
	sectionOrder += 1

	local header = Instance.new("TextButton")
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	header.BackgroundTransparency = 0.85
	header.Text = ""
	header.AutoButtonColor = false
	header.LayoutOrder = sectionOrder * 1000
	header.Parent = scroll

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = Color3.fromRGB(255, 255, 255)
	headerStroke.Transparency = 0.9
	headerStroke.Thickness = 1
	headerStroke.Parent = header

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(0, 8, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = startOpen and "v" or ">"
	arrow.TextColor3 = THEME_ACCENT
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 14
	arrow.Parent = header

	local headerLbl = Instance.new("TextLabel")
	headerLbl.Size = UDim2.new(1, -36, 1, 0)
	headerLbl.Position = UDim2.new(0, 30, 0, 0)
	headerLbl.BackgroundTransparency = 1
	headerLbl.Text = titleText
	headerLbl.TextColor3 = Color3.fromRGB(230, 230, 235)
	headerLbl.Font = Enum.Font.GothamBold
	headerLbl.TextSize = 14
	headerLbl.TextXAlignment = Enum.TextXAlignment.Left
	headerLbl.Parent = header

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Visible = startOpen or false
	body.LayoutOrder = sectionOrder * 1000 + 1
	body.Parent = scroll

	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.Padding = UDim.new(0, 8)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body

	local bodyPad = Instance.new("UIPadding")
	bodyPad.PaddingLeft = UDim.new(0, 4)
	bodyPad.PaddingRight = UDim.new(0, 4)
	bodyPad.Parent = body

	header.MouseButton1Click:Connect(function()
		body.Visible = not body.Visible
		arrow.Text = body.Visible and "v" or ">"
	end)

	return body
end

-- ============================================================
-- Slider Registry (state-key -> slider object), used by the
-- Custom Presets system to visually sync sliders after a Load
-- ============================================================
local sliderRegistry = {}
local colorSliderRegistry = {}

-- White Balance / Tint sliders (built in the Ambient & Color section
-- below) forward-declared here so syncTintSlidersFromColor can use them.
-- WB_STRENGTH/TINT_STRENGTH/computeTintColor are declared earlier, up
-- with the rest of the base+offset system, right after captureState needs
-- them for real.
local wbSlider, tintSlider

-- Given a CC_TintColor, work backwards to the Warm/Cool and Green/Magenta
-- BASE slider positions that would have produced it (offsets are not part
-- of what's saved, so this only ever needs to invert the base). Exact for
-- any tint this script itself produced; a hand-authored TintColor from
-- outside this tool would just show an approximate position instead.
local function syncTintSlidersFromColor(tintColor)
	if not (wbSlider and tintSlider) then return end
	local wbFloat, tintFloat = invertTintColor(tintColor)
	wbSlider:SetValue(math.clamp(wbFloat * 100, -100, 100), true)
	tintSlider:SetValue(math.clamp(tintFloat * 100, -100, 100), true)
end

local function refreshSlidersFromState(s)
	for key, slider in pairs(sliderRegistry) do
		if s[key] ~= nil then slider:SetValue(s[key], true) end
	end
	for key, group in pairs(colorSliderRegistry) do
		local c = s[key]
		if c then
			group.sR:SetValue(c.R, true)
			group.sG:SetValue(c.G, true)
			group.sB:SetValue(c.B, true)
		end
	end
	if s.CC_TintColor then
		syncTintSlidersFromColor(s.CC_TintColor)
	end
end

-- ============================================================
-- Control Creators
-- ============================================================
local function createButton(parent, text, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.8
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 240, 245)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.AutoButtonColor = true
	btn.Parent = parent

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 7)
	btnCorner.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(255, 255, 255)
	btnStroke.Transparency = 0.75
	btnStroke.Thickness = 1
	btnStroke.Parent = btn

	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function createSlider(parent, labelText, min, max, default, onChange, stateKey, fmt)
	fmt = fmt or "%.2f"
	-- fmt may be a format string OR a function(value) -> text (e.g. to show "Off")
	local function fmtV(v)
		if type(fmt) == "function" then return fmt(v) end
		return string.format(fmt, v)
	end
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 50)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText .. ": " .. fmtV(default)
	lbl.TextColor3 = Color3.fromRGB(210, 210, 215)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = container

	local sliderHitbox = Instance.new("TextButton")
	sliderHitbox.Size = UDim2.new(1, 0, 0, 24)
	sliderHitbox.Position = UDim2.new(0, 0, 0, 22)
	sliderHitbox.BackgroundTransparency = 1
	sliderHitbox.Text = ""
	sliderHitbox.AutoButtonColor = false
	sliderHitbox.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, 0, 0, 6)
	sliderBg.Position = UDim2.new(0, 0, 0.5, -3)
	sliderBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sliderBg.BackgroundTransparency = 0.75
	sliderBg.BorderSizePixel = 0
	sliderBg.Parent = sliderHitbox

	local sliderCorner = Instance.new("UICorner")
	sliderCorner.CornerRadius = UDim.new(1, 0)
	sliderCorner.Parent = sliderBg

	local initialAlpha = (max > min) and math.clamp((default - min) / (max - min), 0, 1) or 0

	local fillBar = Instance.new("Frame")
	fillBar.Size = UDim2.new(initialAlpha, 0, 1, 0)
	fillBar.BackgroundColor3 = THEME_ACCENT
	fillBar.BorderSizePixel = 0
	fillBar.Parent = sliderBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fillBar

	local handle = Instance.new("Frame")
	handle.Size = UDim2.new(0, 14, 0, 14)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.Position = UDim2.new(initialAlpha, 0, 0.5, 0)
	handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	handle.ZIndex = 2
	handle.Parent = sliderBg

	local handleCorner = Instance.new("UICorner")
	handleCorner.CornerRadius = UDim.new(1, 0)
	handleCorner.Parent = handle

	local sliderObj = {}
	sliderObj.Container = container
	local lastVal = default

	function sliderObj:SetValue(val, skipCallback)
		-- a programmatic refresh (live sync / preset load) with an unchanged value must not
		-- touch the GUI at all: 3 property writes + a string.format per slider, 5x/second,
		-- inside a CanvasGroup, adds up
		if skipCallback and lastVal ~= nil and math.abs(val - lastVal) <= 1e-6 * math.max(1, math.abs(val)) then
			return
		end
		lastVal = val
		-- Auto-expand range instead of clamping: a preset (or the game's
		-- own original developer-set values) can legitimately be outside
		-- whatever min/max this slider happened to be built with. If we
		-- clamped here, the fader would visually sit at its old min/max
		-- while the actual applied Lighting value is the real, unclamped
		-- number -- exactly the "image is right, fader is wrong" bug.
		if val < min then min = val end
		if val > max then max = val end

		local alpha = (max > min) and (val - min) / (max - min) or 0
		fillBar.Size = UDim2.new(alpha, 0, 1, 0)
		handle.Position = UDim2.new(alpha, 0, 0.5, 0)
		lbl.Text = labelText .. ": " .. fmtV(val)
		if not skipCallback then
			onChange(val)
			if lockLighting then updateLockedSettings() end
		end
	end

	function sliderObj:Update(input)
		local xOffset = input.Position.X - sliderBg.AbsolutePosition.X
		local alpha = math.clamp(xOffset / sliderBg.AbsoluteSize.X, 0, 1)
		local val = min + (max - min) * alpha
		sliderObj:SetValue(val)
	end

	sliderHitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			table.insert(activeSliders, sliderObj)
			sliderObj:Update(input)
		end
	end)

	if stateKey then sliderRegistry[stateKey] = sliderObj end

	return sliderObj
end

-- Convenience wrapper: 3 sliders (R/G/B, 0-1) bound to a Color3 property
local function createColor3Sliders(parent, labelPrefix, getColor, setColor, stateKey)
	local c = getColor()

	-- Always read the OTHER two channels from the real property at the moment of the change.
	-- (A cached copy goes stale whenever a preset load / live sync / auto-fog moves the sliders
	-- with the callback skipped, and the next nudge of one channel would snap the others back.)
	local function channelSetter(which)
		return function(v)
			local cur = getColor()
			local r, g, b = cur.R, cur.G, cur.B
			if which == "R" then r = v elseif which == "G" then g = v else b = v end
			setColor(Color3.new(r, g, b))
		end
	end

	local sR = createSlider(parent, labelPrefix .. " R", 0, 1, c.R, channelSetter("R"))
	local sG = createSlider(parent, labelPrefix .. " G", 0, 1, c.G, channelSetter("G"))
	local sB = createSlider(parent, labelPrefix .. " B", 0, 1, c.B, channelSetter("B"))

	if stateKey then colorSliderRegistry[stateKey] = {sR = sR, sG = sG, sB = sB} end

	return sR, sG, sB
end

local function createTextBox(parent, placeholder, defaultText)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.BackgroundTransparency = 0.82
	box.TextColor3 = Color3.fromRGB(235, 235, 240)
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(120, 120, 125)
	box.Text = defaultText or ""
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = box

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(255, 255, 255)
	boxStroke.Transparency = 0.88
	boxStroke.Thickness = 1
	boxStroke.Parent = box

	return box
end

-- Modern pill-shaped toggle switch (label + animated on/off track+knob).
-- Returns an object with :Get() and :Set(bool, skipCallback).
local function createToggleSwitch(parent, labelText, default, onChange)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 32)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -52, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = Color3.fromRGB(220, 220, 225)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = container

	local track = Instance.new("TextButton")
	track.Size = UDim2.new(0, 44, 0, 24)
	track.Position = UDim2.new(1, -44, 0.5, -12)
	track.AutoButtonColor = false
	track.Text = ""
	track.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
	track.Parent = container

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local obj = {}
	obj.Container = container
	local value = default and true or false

	local function render(animate)
		local onPos = UDim2.new(0, 23, 0.5, -9)
		local offPos = UDim2.new(0, 3, 0.5, -9)
		local onColor = Color3.fromRGB(0, 162, 255)
		local offColor = Color3.fromRGB(60, 60, 66)

		if animate then
			TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = value and onPos or offPos,
			}):Play()
			TweenService:Create(track, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = value and onColor or offColor,
			}):Play()
		else
			knob.Position = value and onPos or offPos
			track.BackgroundColor3 = value and onColor or offColor
		end
	end

	function obj:Get()
		return value
	end

	function obj:Set(v, skipCallback)
		value = v and true or false
		render(true)
		if not skipCallback and onChange then onChange(value) end
	end

	track.MouseButton1Click:Connect(function()
		obj:Set(not value)
	end)

	render(false)
	return obj
end

-- ============================================================
-- Sections
-- ============================================================
local coreSection = createSection("Core", true)
local settingsSection = createSection("Settings")
local offsetsSection = createSection("View Offsets (not saved to presets)", true)
local basicSection = createSection("Basic (Time / Brightness / Fog)")
local ambientSection = createSection("Ambient & Color")
local techSection = createSection("Technology & Quality (incl. AO note)")
local atmoSection = createSection("Atmosphere")
local postFxSection = createSection("Post Effects")
CamSys.rcbSection = createSection("Real Camera Blur")
local skyboxSection = createSection("Skybox")
local presetSection = createSection("Quick Presets")
local customPresetSection = createSection("Custom Presets")
local importExportSection = createSection("Import / Export")
local utilitySection = createSection("Utilities (Reset / Diagnostics)")

-- ---- Core ----
local lockBtn = createButton(coreSection, "Override Lock Loop: OFF", function() end)
lockBtn.MouseButton1Click:Connect(function()
	lockLighting = not lockLighting
	if lockLighting then
		lockBtn.Text = "Override Lock Loop: ON"
		lockBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
		updateLockedSettings()
	else
		lockBtn.Text = "Override Lock Loop: OFF"
		lockBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
	end
end)

local shadowsBtn = createButton(coreSection, "Toggle Shadows: " .. (Lighting.GlobalShadows and "ON" or "OFF"), function() end)
shadowsBtn.MouseButton1Click:Connect(function()
	Lighting.GlobalShadows = not Lighting.GlobalShadows
	shadowsBtn.Text = "Toggle Shadows: " .. (Lighting.GlobalShadows and "ON" or "OFF")
	if lockLighting then updateLockedSettings() end
end)

-- ---- Settings ----
do
local settingsNote = Instance.new("TextLabel")
settingsNote.Size = UDim2.new(1, 0, 0, 34)
settingsNote.BackgroundTransparency = 1
settingsNote.Text = hasFilesystem
	and "When ON, your current lighting is saved every few seconds and restored automatically next time this loads."
	or "Needs runtime-provided file functions (writefile/readfile) -- unavailable here, so this can't persist right now."
settingsNote.TextColor3 = Color3.fromRGB(160, 160, 165)
settingsNote.TextWrapped = true
settingsNote.TextSize = 11
settingsNote.Font = Enum.Font.Gotham
settingsNote.TextXAlignment = Enum.TextXAlignment.Left
settingsNote.TextYAlignment = Enum.TextYAlignment.Top
settingsNote.Parent = settingsSection

local rememberToggle = createToggleSwitch(settingsSection, "Remember Last Lighting on Startup", rememberLastState, function(v)
	rememberLastState = v
	savedSettings.rememberLastState = v
	saveJSONFile(SETTINGS_FILE, savedSettings)
	if v then
		saveLastStateNow() -- save immediately so it's not empty until the next autosave tick
	end
end)

if not hasFilesystem then
	rememberToggle:Set(false, true)
end
end


local sunRaysBtn = createButton(coreSection, "Toggle Sun Rays: " .. (sunRays.Enabled and "ON" or "OFF"), function() end)
sunRaysBtn.MouseButton1Click:Connect(function()
	sunRays.Enabled = not sunRays.Enabled
	sunRaysBtn.Text = "Toggle Sun Rays: " .. (sunRays.Enabled and "ON" or "OFF")
	if lockLighting then updateLockedSettings() end
end)

-- ---- View Offsets ----
-- Deliberately NOT registered in sliderRegistry -- these must never be
-- touched by refreshSlidersFromState() (Load Preset / Reset), since
-- switching presets should not reset your personal viewing offsets, and
-- captureState() never reads these at all, so they can never end up
-- saved into a preset/config either.
local offsetsNote = Instance.new("TextLabel")
offsetsNote.Size = UDim2.new(1, 0, 0, 46)
offsetsNote.BackgroundTransparency = 1
offsetsNote.Text = "Personal viewing adjustments only -- layered on top of whatever preset/config is loaded, never saved into one. Useful for compensating between games with different baseline visuals."
offsetsNote.TextColor3 = Color3.fromRGB(160, 160, 165)
offsetsNote.TextWrapped = true
offsetsNote.TextSize = 11
offsetsNote.Font = Enum.Font.Gotham
offsetsNote.TextXAlignment = Enum.TextXAlignment.Left
offsetsNote.TextYAlignment = Enum.TextYAlignment.Top
offsetsNote.Parent = offsetsSection

local offsetExposureSlider = createSlider(offsetsSection, "Exposure Offset", -5, 5, 0, function(v)
	offsetExposure = v
	recomputeExposure()
end)

-- Automatic Exposure Compensation: an EXTRA layer on top of base + Exposure
-- Offset (which stays exactly as it was). 0% = off, 100% = full auto.
CamSys.aeSlider = createSlider(offsetsSection, "Automatic Exposure (AE)", 0, 100, 0, function(v)
	CamSys.autoCam.aeStrength = v
end, nil, "%.0f%%")

local offsetSaturationSlider = createSlider(offsetsSection, "Saturation Offset", -2, 2, 0, function(v)
	offsetSaturation = v
	recomputeSaturation()
end)

local offsetContrastSlider = createSlider(offsetsSection, "Contrast Offset", -2, 2, 0, function(v)
	offsetContrast = v
	recomputeContrast()
end)

local offsetWBSlider = createSlider(offsetsSection, "White Balance Offset", -100, 100, 0, function(v)
	offsetWB = v / 100
	recomputeTint()
end)

local offsetTintSlider = createSlider(offsetsSection, "Tint Offset", -100, 100, 0, function(v)
	offsetTint = v / 100
	recomputeTint()
end)

-- Automatic White Balance (temperature + tint): extra layer on top of the
-- existing White Balance / Tint system and their offsets.
CamSys.awbSlider = createSlider(offsetsSection, "Automatic White Balance (AWB)", 0, 100, 0, function(v)
	CamSys.autoCam.awbStrength = v
end, nil, "%.0f%%")

CamSys.autoSpeedSlider = createSlider(offsetsSection, "Auto Adaptation Speed", 0.25, 4, 1, function(v)
	CamSys.autoCam.speed = v
end, nil, "%.2fx")

do
local autoNote = Instance.new("TextLabel")
autoNote.Size = UDim2.new(1, 0, 0, 72)
autoNote.BackgroundTransparency = 1
autoNote.Text = "AE / AWB add on top of the manual offsets. Roblox can't read back screen pixels, so both are approximated from a grid of camera rays: AE from the lit scene (sun, shadows, ambient), AWB from the plain average colour of what is on screen (sky is skipped) -- smooth and stable, but not exact."
autoNote.TextColor3 = Color3.fromRGB(160, 160, 165)
autoNote.TextWrapped = true
autoNote.TextSize = 11
autoNote.Font = Enum.Font.Gotham
autoNote.TextXAlignment = Enum.TextXAlignment.Left
autoNote.TextYAlignment = Enum.TextYAlignment.Top
autoNote.Parent = offsetsSection
end

local function resetOffsetsToZero()
	CamSys.autoCam.aeStrength, CamSys.autoCam.awbStrength = 0, 0
	CamSys.aeSlider:SetValue(0, true)
	CamSys.awbSlider:SetValue(0, true)
	offsetExposure, offsetSaturation, offsetContrast, offsetWB, offsetTint = 0, 0, 0, 0, 0
	recomputeExposure()
	recomputeSaturation()
	recomputeContrast()
	recomputeTint()
	offsetExposureSlider:SetValue(0, true)
	offsetSaturationSlider:SetValue(0, true)
	offsetContrastSlider:SetValue(0, true)
	offsetWBSlider:SetValue(0, true)
	offsetTintSlider:SetValue(0, true)
end

createButton(offsetsSection, "Reset Offsets to Zero", resetOffsetsToZero)

-- ---- Basic ----
local sClock = createSlider(basicSection, "Time of Day", 0, 24, Lighting.ClockTime, function(v) Lighting.ClockTime = v end, "ClockTime")
local sBright = createSlider(basicSection, "Brightness", 0, 10, Lighting.Brightness, function(v) Lighting.Brightness = v end, "Brightness")
local sFogStart = createSlider(basicSection, "Fog Start", 0, 5000, Lighting.FogStart, function(v) Lighting.FogStart = v end, "FogStart")
local sFogEnd = createSlider(basicSection, "Fog End", 50, 10000, Lighting.FogEnd, function(v) Lighting.FogEnd = v end, "FogEnd")

local sFogR, sFogG, sFogB = createColor3Sliders(basicSection, "Fog Color", function() return Lighting.FogColor end, function(c) Lighting.FogColor = c end, "FogColor")

-- ---- Auto Fog Color ----
-- NOTE ON HOW THIS WORKS:
-- Sampling real pixel colors off the skybox requires Roblox's EditableImage
-- API (AssetService:CreateEditableImageAsync). Roblox restricts which image
-- assets that API is allowed to load -- it only works on images owned by:
--   * you / your group, if you own this experience, OR
--   * the currently logged-in Studio user, for an unpublished/unsaved place.
-- Marketplace / stock skybox textures you don't own will throw a permission
-- error when loaded this way -- that's a Roblox-side restriction, not a bug
-- in this script. When that happens this falls back to approximating the
-- color from Lighting.OutdoorAmbient instead, and prints a warning so you
-- know which path was used.
-- Also: for a PUBLISHED game, EditableImage additionally requires you to be
-- age/ID verified and to enable "Allow Mesh & Image APIs" under
-- Game Settings > Security in Studio.

local function sampleFaceAverage(imageId, coverage)
	if imageId == nil or imageId == "" then return nil end
	local ok, result = pcall(function()
		local content = Content.fromUri("rbxassetid://" .. tostring(imageId))
		local editableImage = AssetService:CreateEditableImageAsync(content)
		local size = editableImage.Size

		local sampleW = math.max(1, math.floor(size.X * coverage))
		local sampleH = math.max(1, math.floor(size.Y * coverage))
		local offsetX = math.floor((size.X - sampleW) / 2)
		local offsetY = math.floor((size.Y - sampleH) / 2)

		-- Step through the sampled region instead of reading every pixel --
		-- full-resolution reads on a 1024x1024 face would be extremely slow.
		local step = math.max(1, math.floor(math.min(sampleW, sampleH) / 24))

		local totalR, totalG, totalB, count = 0, 0, 0, 0
		for y = 0, sampleH - 1, step do
			for x = 0, sampleW - 1, step do
				local pixel = editableImage:ReadPixels(Vector2.new(offsetX + x, offsetY + y), Vector2.new(1, 1))
				-- pixel = {r, g, b, a}, each 0-1
				totalR += pixel[1]
				totalG += pixel[2]
				totalB += pixel[3]
				count += 1
			end
		end

		editableImage:Destroy()

		if count == 0 then return nil end
		return Color3.new(totalR / count, totalG / count, totalB / count)
	end)

	if ok then
		return result
	else
		warn("[LightingUtility] Could not read skybox face " .. tostring(imageId) .. " (likely not owned by you): " .. tostring(result))
		return nil, result
	end
end

local function autoFogColor(coverage)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	local color

	if sky then
		local faces = {sky.SkyboxFt, sky.SkyboxBk, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp, sky.SkyboxDn}
		local totalR, totalG, totalB, count = 0, 0, 0, 0
		local anySuccess = false

		for _, faceId in ipairs(faces) do
			local faceColor = sampleFaceAverage(faceId, coverage)
			if faceColor then
				anySuccess = true
				totalR += faceColor.R
				totalG += faceColor.G
				totalB += faceColor.B
				count += 1
			end
		end

		if anySuccess and count > 0 then
			color = Color3.new(totalR / count, totalG / count, totalB / count)
		end
	end

	if not color then
		-- Fallback: approximate using OutdoorAmbient, since we couldn't
		-- read the actual skybox pixels (permissions, no Sky object, etc).
		warn("[LightingUtility] Falling back to OutdoorAmbient-based fog color approximation.")
		color = Lighting.OutdoorAmbient
	end

	Lighting.FogColor = color
	sFogR:SetValue(color.R, true)
	sFogG:SetValue(color.G, true)
	sFogB:SetValue(color.B, true)
	if lockLighting then updateLockedSettings() end
end

createButton(basicSection, "Auto Fog Color (50% coverage)", function() autoFogColor(0.5) end)
createButton(basicSection, "Auto Fog Color (75% coverage)", function() autoFogColor(0.75) end)
createButton(basicSection, "Auto Fog Color (100% coverage)", function() autoFogColor(1.0) end)

-- ---- Ambient & Color ----
createColor3Sliders(ambientSection, "Ambient", function() return Lighting.Ambient end, function(c) Lighting.Ambient = c end, "Ambient")
createColor3Sliders(ambientSection, "OutdoorAmbient", function() return Lighting.OutdoorAmbient end, function(c) Lighting.OutdoorAmbient = c end, "OutdoorAmbient")
createColor3Sliders(ambientSection, "ColorShift Top (Sun Color)", function() return Lighting.ColorShift_Top end, function(c) Lighting.ColorShift_Top = c end, "ColorShift_Top")
createColor3Sliders(ambientSection, "ColorShift Bottom", function() return Lighting.ColorShift_Bottom end, function(c) Lighting.ColorShift_Bottom = c end, "ColorShift_Bottom")
createSlider(ambientSection, "Exposure Compensation", -5, 5, baseExposure, function(v)
	baseExposure = v
	recomputeExposure()
end, "ExposureCompensation")

local sSat = createSlider(ambientSection, "Color Saturation", -1, 3, baseSaturation, function(v)
	baseSaturation = v
	recomputeSaturation()
end, "CC_Saturation")
local sCon = createSlider(ambientSection, "Color Contrast", -1, 3, baseContrast, function(v)
	baseContrast = v
	recomputeContrast()
end, "CC_Contrast")
local sCcBri = createSlider(ambientSection, "Color Brightness", -1, 1, colorCorrection.Brightness, function(v) colorCorrection.Brightness = v end, "CC_Brightness")

-- White Balance / Tint: a proper photo/video-style color-grade tint,
-- separate from Ambient above (which changes real in-world light color,
-- not a post-process white balance). Both write into the same
-- ColorCorrectionEffect.TintColor property together.
local wbTintNote = Instance.new("TextLabel")
wbTintNote.Size = UDim2.new(1, 0, 0, 30)
wbTintNote.BackgroundTransparency = 1
wbTintNote.Text = "White Balance / Tint (post-process color grade, not in-world light):"
wbTintNote.TextColor3 = Color3.fromRGB(160, 160, 165)
wbTintNote.TextWrapped = true
wbTintNote.TextSize = 11
wbTintNote.Font = Enum.Font.Gotham
wbTintNote.TextXAlignment = Enum.TextXAlignment.Left
wbTintNote.Parent = ambientSection

wbSlider = createSlider(ambientSection, "White Balance (Cool <-> Warm)", -100, 100, 0, function(v)
	currentWB = v / 100
	recomputeTint()
end)

tintSlider = createSlider(ambientSection, "Tint (Green <-> Magenta)", -100, 100, 0, function(v)
	currentTint = v / 100
	recomputeTint()
end)

-- Independent RGB multipliers on top of WB/Tint (saved in presets; 1.00 = neutral).
-- Post-process TintColor only: per-channel scale of the final image, not a shader.
createSlider(ambientSection, "Tint Multiplier Red", 0, 2, CamSys.tintMulR, function(v)
	CamSys.tintMulR = v
	recomputeTint()
end, "CC_TintMulR")
createSlider(ambientSection, "Tint Multiplier Green", 0, 2, CamSys.tintMulG, function(v)
	CamSys.tintMulG = v
	recomputeTint()
end, "CC_TintMulG")
createSlider(ambientSection, "Tint Multiplier Blue", 0, 2, CamSys.tintMulB, function(v)
	CamSys.tintMulB = v
	recomputeTint()
end, "CC_TintMulB")

-- Light & Neon recolor (client-side): Lights + Neon parts only, sun/moon untouched.
CamSys.light.buildUI = function()
	CamSys.light.toggleObj = createToggleSwitch(ambientSection, "Light & Neon Recolor (client-side)", CamSys.light.enabled, function(v)
		CamSys.light.setEnabled(v)
		if lockLighting then updateLockedSettings() end
	end)
	createSlider(ambientSection, "Light Multiplier Red", 0, 2, CamSys.light.mulR, function(v)
		CamSys.light.mulR = v
		CamSys.light.refreshAll()
	end, "LT_MulR")
	createSlider(ambientSection, "Light Multiplier Green", 0, 2, CamSys.light.mulG, function(v)
		CamSys.light.mulG = v
		CamSys.light.refreshAll()
	end, "LT_MulG")
	createSlider(ambientSection, "Light Multiplier Blue", 0, 2, CamSys.light.mulB, function(v)
		CamSys.light.mulB = v
		CamSys.light.refreshAll()
	end, "LT_MulB")
	createSlider(ambientSection, "Light Brightness Offset", -3, 4, CamSys.light.brightOffset, function(v)
		CamSys.light.brightOffset = v
		CamSys.light.refreshAll()
	end, "LT_BrightOffset", function(v) return string.format("%+.2f EV (x%.2f)", v, 2 ^ v) end)
	local order = {"compensate", "normalize", "clip"}
	local names = {compensate = "Compensate (brightness)", normalize = "Normalize (keep hue)", clip = "Clip"}
	local btn = createButton(ambientSection, "Overflow above 1: " .. names[CamSys.light.overflow], function() end)
	btn.MouseButton1Click:Connect(function()
		local L = CamSys.light
		local i = table.find(order, L.overflow) or 1
		L.overflow = order[i % #order + 1]
		btn.Text = "Overflow above 1: " .. names[L.overflow]
		L.refreshAll()
		if lockLighting then updateLockedSettings() end
	end)
	CamSys.light.syncUI = function()
		local L = CamSys.light
		if L.toggleObj and L.toggleObj:Get() ~= L.enabled then L.toggleObj:Set(L.enabled, true) end
		local t = "Overflow above 1: " .. names[L.overflow]
		if btn.Text ~= t then btn.Text = t end
	end
	createSlider(ambientSection, "Full-rate animating objects", 10, 50, CamSys.light.activeCap, function(v)
		CamSys.light.activeCap = math.floor(v + 0.5)
	end, "LT_ActiveCap", "%.0f")
	createSlider(ambientSection, "Overflow objects per second", 10, 200, CamSys.light.overflowPerSec, function(v)
		CamSys.light.overflowPerSec = math.floor(v + 0.5)
	end, "LT_OverflowPerSec", "%.0f")
end
CamSys.light.buildUI()

-- ---- Technology & Quality ----
local techLabel = Instance.new("TextLabel")
techLabel.Size = UDim2.new(1, 0, 0, 60)
techLabel.BackgroundTransparency = 1
techLabel.Text = "Roblox has no direct 'ambient occlusion' property. Future " ..
	"technology is the closest thing -- it enables SSAO-style shadowing " ..
	"plus better reflections automatically."
techLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
techLabel.TextWrapped = true
techLabel.TextSize = 12
techLabel.Font = Enum.Font.Gotham
techLabel.TextXAlignment = Enum.TextXAlignment.Left
techLabel.TextYAlignment = Enum.TextYAlignment.Top
techLabel.Parent = techSection

local techOptions = {Enum.Technology.Voxel, Enum.Technology.ShadowMap, Enum.Technology.Compatibility, Enum.Technology.Future}
local techIndex = 1
for i, t in ipairs(techOptions) do
	if Lighting.Technology == t then techIndex = i end
end

local techBtn = createButton(techSection, "Technology: " .. Lighting.Technology.Name, function() end)
techBtn.MouseButton1Click:Connect(function()
	techIndex = (techIndex % #techOptions) + 1
	Lighting.Technology = techOptions[techIndex]
	techBtn.Text = "Technology: " .. Lighting.Technology.Name
	if lockLighting then updateLockedSettings() end
end)

createSlider(techSection, "Environment Diffuse Scale", 0, 1, Lighting.EnvironmentDiffuseScale, function(v) Lighting.EnvironmentDiffuseScale = v end, "EnvironmentDiffuseScale")
createSlider(techSection, "Environment Specular Scale", 0, 1, Lighting.EnvironmentSpecularScale, function(v) Lighting.EnvironmentSpecularScale = v end, "EnvironmentSpecularScale")

-- Keeps the toggle buttons' text/color honest after a custom preset is
-- loaded (since applyState() changes GlobalShadows / sunRays.Enabled /
-- Technology directly, bypassing the buttons that normally toggle them).
local function syncTogglesUI()
	local sTxt = "Toggle Shadows: " .. (Lighting.GlobalShadows and "ON" or "OFF")
	if shadowsBtn.Text ~= sTxt then shadowsBtn.Text = sTxt end
	local rTxt = "Toggle Sun Rays: " .. (sunRays.Enabled and "ON" or "OFF")
	if sunRaysBtn.Text ~= rTxt then sunRaysBtn.Text = rTxt end
	for i, t in ipairs(techOptions) do
		if Lighting.Technology == t then techIndex = i end
	end
	local tTxt = "Technology: " .. Lighting.Technology.Name
	if techBtn.Text ~= tTxt then techBtn.Text = tTxt end
	if CamSys.light.syncUI then CamSys.light.syncUI() end
end

-- ---- Atmosphere ----
createSlider(atmoSection, "Density", 0, 1, atmosphere.Density, function(v) atmosphere.Density = v end, "Atmo_Density")
createSlider(atmoSection, "Offset", 0, 1, atmosphere.Offset, function(v) atmosphere.Offset = v end, "Atmo_Offset")
createSlider(atmoSection, "Glare", 0, 1, atmosphere.Glare, function(v) atmosphere.Glare = v end, "Atmo_Glare")
createSlider(atmoSection, "Haze", 0, 10, atmosphere.Haze, function(v) atmosphere.Haze = v end, "Atmo_Haze")
createColor3Sliders(atmoSection, "Atmo Color", function() return atmosphere.Color end, function(c) atmosphere.Color = c end, "Atmo_Color")
createColor3Sliders(atmoSection, "Atmo Decay", function() return atmosphere.Decay end, function(c) atmosphere.Decay = c end, "Atmo_Decay")

-- ---- Post Effects ----
createSlider(postFxSection, "Sun Rays Intensity", 0, 1, sunRays.Intensity, function(v) sunRays.Intensity = v end, "SunRaysIntensity")
createSlider(postFxSection, "Sun Rays Spread", 0, 1, sunRays.Spread, function(v) sunRays.Spread = v end, "SunRaysSpread")
createSlider(postFxSection, "Bloom Intensity", 0, 5, bloom.Intensity, function(v) bloom.Intensity = v end, "Bloom_Intensity")
createSlider(postFxSection, "Bloom Threshold", 0, 5, bloom.Threshold, function(v) bloom.Threshold = v end, "Bloom_Threshold")
createSlider(postFxSection, "Bloom Size", 0, 56, bloom.Size, function(v) bloom.Size = v end, "Bloom_Size")
do
	local skyNow = Lighting:FindFirstChildOfClass("Sky")
	createSlider(skyboxSection, "Sun Size", 0, 21, skyNow and skyNow.SunAngularSize or 21, function(v) getSky().SunAngularSize = v end, "Sun_Size")
	createSlider(skyboxSection, "Moon Size", 0, 11, skyNow and skyNow.MoonAngularSize or 11, function(v) getSky().MoonAngularSize = v end, "Moon_Size")
end

createSlider(postFxSection, "Blur Size", 0, 56, blur.Size, function(v) blur.Size = v end, "Blur_Size")
createSlider(postFxSection, "Depth of Field: Far Intensity", 0, 1, depthOfField.FarIntensity, function(v) CamSys.setDoF("FarIntensity", v) end, "DoF_FarIntensity")
createSlider(postFxSection, "Depth of Field: Near Intensity", 0, 1, depthOfField.NearIntensity, function(v) CamSys.setDoF("NearIntensity", v) end, "DoF_NearIntensity")
createSlider(postFxSection, "Depth of Field: In-Focus Radius", 0, 200, depthOfField.InFocusRadius, function(v) CamSys.setDoF("InFocusRadius", v) end, "DoF_InFocusRadius")
createSlider(postFxSection, "Depth of Field: Focus Distance", 0, 400, depthOfField.FocusDistance, function(v) CamSys.setDoF("FocusDistance", v) end, "DoF_FocusDistance")

-- ---- Real Camera Blur ----
-- Settings here are saved in the persistent settings file (see the engine
-- above), NOT in lighting presets. The Depth of Field sliders in Post
-- Effects keep editing the NORMAL DoF config; while Real Camera Blur is ON
-- that config is simply held in reserve and restored when it is turned OFF.
--
-- Layout: 3rd Person AF, 1st Person AF (one shared builder), then the global options in
-- this order: Momentary Override, Cursor Auto Focus, Player Autofocus, Lens, Autofocus
-- Speed, Transition Curve, Reset, Autofocus Presets. Controls are bound straight to the
-- settings tables (cfg / cfg.tp / cfg.fp), so every change is live; visibility is
-- declarative (showIf) and refreshed in one place.
do
local rcb = CamSys.rcb
local cfg = rcb.config
local sec = CamSys.rcbSection
local ui = {}   -- ui[control] = {t = settings table, k = key} | {render = fn}
rcb.conds = {}  -- {gui object, visible()} pairs, evaluated by refreshVisibility
local refreshVisibility  -- forward declaration

local function addNote(text, height)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, height or 30)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(160, 160, 165)
	lbl.TextWrapped = true
	lbl.TextSize = 11
	lbl.Font = Enum.Font.Gotham
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.Parent = sec
	return lbl
end

local function addHeader(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = THEME_ACCENT
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = sec
	return lbl
end

-- Show / hide a control from a predicate (re-evaluated by refreshVisibility).
local function showIf(obj, fn)
	rcb.conds[#rcb.conds + 1] = {typeof(obj) == "Instance" and obj or obj.Container, fn}
	return obj
end

-- Slider bound to t[key]; `snap` rounds to whole numbers.
local function addSlider(t, key, label, min, max, fmt, snap)
	local s = createSlider(sec, label, min, max, t[key], function(v)
		if snap then v = math.floor(v + 0.5) end
		t[key] = v
		rcb.MarkDirty()
	end, nil, fmt)
	ui[s] = {t = t, k = key}
	return s
end

-- Toggle bound to t[key]; `after` runs on every change (e.g. to flash the overlay).
local function addToggle(t, key, label, after)
	local o = createToggleSwitch(sec, label, t[key], function(v)
		t[key] = v
		rcb.MarkDirty()
		refreshVisibility()
		if after then after() end
	end)
	ui[o] = {t = t, k = key}
	return o
end

-- Button that cycles t[key] through opts ({id, name} pairs).
local function addCycle(t, key, prefix, opts, after)
	local btn
	local function render()
		for _, o in ipairs(opts) do
			if o.id == t[key] then btn.Text = prefix .. o.name end
		end
	end
	btn = createButton(sec, "", function()
		for i, o in ipairs(opts) do
			if o.id == t[key] then
				t[key] = opts[i % #opts + 1].id
				break
			end
		end
		render()
		rcb.MarkDirty()
		refreshVisibility()
		if after then after() end
	end)
	render()
	ui[btn] = {render = render}
	return btn
end

-- Click-to-bind key button for cfg[key] (keyboard key or mouse button). One shared capture
-- at a time; allowNone lets Backspace clear the bind ("" = none).
local function addKeyBind(key, prefix, allowNone)
	local NAMES = {MouseButton1 = "Left Mouse Button", MouseButton2 = "Right Mouse Button", MouseButton3 = "Middle Mouse Button"}
	local btn
	local function render()
		if rcb.capture and rcb.capture.btn == btn then
			btn.Text = "Press a key or mouse button...  (Esc = cancel" .. (allowNone and ", Backspace = none)" or ")")
		else
			local k = cfg[key]
			btn.Text = prefix .. ((k == "" and "None") or NAMES[k] or k) .. "  (click to change)"
		end
	end
	btn = createButton(sec, "", function()
		local prev = rcb.capture
		rcb.capture = {btn = btn, key = key, render = render, allowNone = allowNone}
		rcb.capturingKey = true
		if prev then prev.render() end
		render()
	end)
	render()
	ui[btn] = {render = render}
	return btn
end

-- ONE input handler: finishes a pending key capture, otherwise runs the Cursor Auto Focus hotkey.
CamSys.track(UserInputService.InputBegan, function(input, processed)
	local ut = input.UserInputType
	local name
	if ut == Enum.UserInputType.Keyboard then
		if input.KeyCode ~= Enum.KeyCode.Unknown then name = input.KeyCode.Name end
	elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
		name = ut.Name
	end
	if not name then return end
	local cap = rcb.capture
	if cap then
		rcb.capture, rcb.capturingKey = nil, false
		if name == "Backspace" and cap.allowNone then
			cfg[cap.key] = ""
			rcb.MarkDirty()
		elseif name ~= "Escape" then
			cfg[cap.key] = name
			rcb.MarkDirty()
		end
		cap.render()
	elseif cfg.cursorKey ~= "" and name == cfg.cursorKey and not processed and not UserInputService:GetFocusedTextBox() then
		rcb.cursorToggle:Set(not cfg.cursorEnabled) -- hotkey flips the Cursor Auto Focus toggle (and the setting)
	end
end)

-- Re-read every control from its settings table (after Reset / loading a preset).
local function syncUI()
	rcb.capture, rcb.capturingKey = nil, false
	for obj, b in pairs(ui) do
		if b.render then
			b.render()
		elseif obj.SetValue then
			obj:SetValue(b.t[b.k], true)
		else
			obj:Set(b.t[b.k], true)
		end
	end
	refreshVisibility()
end

-- ---- On-screen overlay: focus areas + momentary circle ----
-- ONE ScreenGui and ONE RenderStepped loop serve every view. A view is shown while one of
-- its sliders is dragged or hovered (plus a short linger), or when it is pinned (Always Show).
-- It draws the exact geometry / sample points the focus calculation uses, so what you see is
-- what is measured -- including the pitch-based movement, live as the camera tilts.
-- View = {eligible = fn, pinned = fn?, geometry = fn(cam), text = fn(g), points = bool?}
rcb.overlay = (function()
	local O, views, fpCache = {}, {}, nil
	local gui = Instance.new("ScreenGui")
	gui.Name = "LightingUtilityFocusArea"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true   -- GUI pixels == camera viewport pixels
	gui.DisplayOrder = -1       -- below the tool window
	gui.Parent = uiParent

	local function bar(w, h)
		local b = Instance.new("Frame")
		b.Size = UDim2.fromOffset(w, h)
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		b.BorderSizePixel = 0
		b.Active = false
		b.Visible = false
		b.Parent = gui
		return b
	end

	function O.add(v)
		views[#views + 1] = v
		v.watched, v.hover, v.pool, v.lastActive, v.shown = {}, {}, {}, -10, false
		local shape = Instance.new("Frame")
		shape.AnchorPoint = Vector2.new(0.5, 0.5)
		shape.BackgroundColor3 = THEME_ACCENT
		shape.BackgroundTransparency = 0.88
		shape.BorderSizePixel = 0
		shape.Active = false
		shape.Visible = false
		shape.Parent = gui
		v.shape = shape
		v.corner = Instance.new("UICorner")
		v.corner.Parent = shape
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 2
		stroke.Transparency = 0.1
		stroke.Parent = shape
		v.barH, v.barV = bar(16, 2), bar(2, 16)
		local info = Instance.new("TextLabel")
		info.Size = UDim2.fromOffset(520, 22)
		info.AnchorPoint = Vector2.new(0.5, 0)
		info.Position = UDim2.new(0.5, 0, 0, 56 + 26 * (#views - 1)) -- views stack so labels never overlap
		info.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
		info.BackgroundTransparency = 0.25
		info.TextColor3 = Color3.new(1, 1, 1)
		info.Font = Enum.Font.GothamBold
		info.TextSize = 12
		info.Active = false
		info.Visible = false
		info.Parent = gui
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(0, 6)
		ic.Parent = info
		v.info = info
		return v
	end

	-- show this view while the slider is dragged / hovered
	function O.watch(v, s)
		v.watched[s] = true
		s.Container.MouseEnter:Connect(function() v.hover[s] = true end)
		s.Container.MouseLeave:Connect(function() v.hover[s] = nil end)
	end
	function O.flash(v) v.lastActive = os.clock() end
	function O.flashAll()
		local now = os.clock()
		for _, v in ipairs(views) do v.lastActive = now end
	end
	-- first-person state, evaluated at most once per frame and only when a view is pinned
	function O.isFP()
		if fpCache == nil then fpCache = rcb.isFirstPersonNow() end
		return fpCache
	end

	local function setShown(v, on)
		v.shown = on
		v.shape.Visible, v.barH.Visible, v.barV.Visible, v.info.Visible = on, on, on, on
		if not on then
			for _, d in ipairs(v.pool) do d.Visible = false end
		end
	end

	local function getDot(v, i)
		local d = v.pool[i]
		if not d then
			d = Instance.new("Frame")
			d.Size = UDim2.fromOffset(4, 4)
			d.AnchorPoint = Vector2.new(0.5, 0.5)
			d.BackgroundColor3 = Color3.fromRGB(255, 220, 90)
			d.BorderSizePixel = 0
			d.Active = false
			d.Parent = gui
			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1, 0)
			dc.Parent = d
			v.pool[i] = d
		end
		return d
	end

	CamSys.nextName = "focusOverlay"
	CamSys.track(RunService.RenderStepped, function()
		local cam = workspace.CurrentCamera
		local open = cam ~= nil and screenGui.Enabled
		local uiOpen = open and sec.Visible and frame.Visible
		local now = os.clock()
		fpCache = nil
		for _, v in ipairs(views) do
			local eligible = open and v.eligible()
			local active = false
			if eligible and uiOpen then
				for _, s in ipairs(activeSliders) do
					if v.watched[s] then active = true break end
				end
				active = active or next(v.hover) ~= nil
			end
			if active then v.lastActive = now end
			if not (eligible and (active or now - v.lastActive < 0.6 or (v.pinned and v.pinned()))) then
				if v.shown then setShown(v, false) end -- only on the transition, not every frame
			else
				local g = v.geometry(cam)
				if g.shape == "Circle" then
					local d = math.max(g.r * 2, 2)
					v.shape.Size = UDim2.fromOffset(d, d)
					v.corner.CornerRadius = UDim.new(0.5, 0)
				else
					v.shape.Size = UDim2.fromOffset(math.max(g.w, 2), math.max(g.h, 2))
					v.corner.CornerRadius = UDim.new(0, 0)
				end
				local pos = UDim2.fromOffset(g.cx, g.cy)
				v.shape.Position, v.barH.Position, v.barV.Position = pos, pos, pos
				v.info.Text = v.text(g)
				if not v.shown then setShown(v, true) end
				if v.points then
					local pts = rcb.areaSamplePoints(g, cam.ViewportSize)
					for i, p in ipairs(pts) do
						local d = getDot(v, i)
						d.Position = UDim2.fromOffset(p.X, p.Y)
						d.Visible = true
					end
					for i = #pts + 1, #v.pool do v.pool[i].Visible = false end
				end
			end
		end
	end)

	return O
end)()

-- ---- master switch + status ----
addNote("Turns Roblox's own DepthOfFieldEffect into a camera-style autofocus system. While ON it overrides the Depth of Field settings; turning it OFF restores them exactly. Calculated values are never saved into presets.", 70)

rcb.enableToggle = createToggleSwitch(sec, "Real Camera Blur", cfg.enabled, function(v)
	rcb.SetEnabled(v)
	rcb.MarkDirty()
end)

local statusLbl = addNote(rcb.GetStatus(), 44)

-- ---- 3rd Person AF / 1st Person AF ----
-- One builder for both; `third` adds the 3rd-person-only options (Ignore Self, Focus on Self
-- After Inactivity, Pitch-Based Focus Area). `sub` is cfg.tp / cfg.fp.
local function buildAF(sub, third)
	local tag = third and "3rd" or "1st"
	local function gate(obj, extra) -- only while "Auto Focus Box/Circle" is the target
		return showIf(obj, function() return sub.target == "Area" and (extra == nil or extra()) end)
	end
	local view = rcb.overlay.add({
		eligible = function() return sub.target == "Area" end,
		pinned = function() return sub.areaShowAlways and rcb.overlay.isFP() ~= third end, -- only in its own camera mode
		geometry = function(cam) return rcb.areaGeometry(cam.ViewportSize, sub, cam) end,
		points = true,
		text = function(g)
			local s
			if g.shape == "Circle" then
				s = string.format("%s Circle | X %.0f  Y %.0f | R %.1f", tag, sub.areaX, sub.areaY, sub.areaRadius)
			else
				s = string.format("%s Box | X %.0f  Y %.0f | L %.1f  W %.1f", tag, sub.areaX, sub.areaY, sub.areaLength, sub.areaWidth)
			end
			s = s .. (sub.anyPerson and " | Any person" or string.format(" | Focus On %.0f%%", sub.areaFocusOn))
			if g.pitchT then s = s .. string.format(" | Pitch %.0f deg -> %.0f%%", g.pitchDeg, g.pitchT * 100) end
			return s
		end,
	})
	local function flash() rcb.overlay.flash(view) end
	local function areaSlider(key, label, min, max, fmt, extra)
		local s = gate(addSlider(sub, key, label, min, max, fmt), extra)
		rcb.overlay.watch(view, s)
		return s
	end
	local function isBox() return sub.areaShape == "Box" end
	local function isCircle() return sub.areaShape == "Circle" end

	addHeader(third and "3rd Person AF" or "1st Person AF")
	addCycle(sub, "target", "Autofocus Target: ", {
		{id = "Area", name = "Auto Focus Box/Circle"},
		{id = "Center", name = "Center of Screen"},
	}, flash)

	-- Focus Box / Circle options
	gate(addNote("Autofocus on whatever is visible inside a screen region. X/Y: 0 = centre, +-100 = screen edge (+Y is up). Size 50 = 50% of the screen (circle: of the shorter side). Focus On: 20 = nearer part, 50 = middle, 80 = farther part. The region is shown on screen while you drag or hover its sliders.", 92))
	gate(addCycle(sub, "areaShape", "Shape: ", {{id = "Box", name = "Box"}, {id = "Circle", name = "Circle"}}, flash))
	areaSlider("areaX", "Position X (-100 left .. +100 right)", -100, 100, "%.0f")
	areaSlider("areaY", "Position Y (-100 down .. +100 up)", -100, 100, "%.0f")
	areaSlider("areaLength", "Box Length (% of screen width)", 0, 50, "%.1f", isBox)
	areaSlider("areaWidth", "Box Width (% of screen height)", 0, 50, "%.1f", isBox)
	areaSlider("areaRadius", "Circle Radius (% of screen)", 0, 50, "%.1f", isCircle)
	areaSlider("areaFocusOn", "Focus On (20 near .. 80 far)", 20, 80, "%.0f%%", function() return not sub.anyPerson end)
	gate(addToggle(sub, "anyPerson", third and "Focus Any Person Touching the Area" or "Focus Person Nearest Area Center"))
	gate(addNote(third
		and "Ignores Focus On: focuses the closest person (other players, and you unless Ignore Self is on) whose body touches the box/circle. Nobody touching = middle depth of the area."
		or "Ignores Focus On: focuses the person touching the box/circle whose position is closest to its centre. Nobody touching = middle depth of the area.", 56), function() return sub.anyPerson end)
	gate(addToggle(sub, "areaShowAlways", "Always Show Focus Area On Screen"))

	if not third then return end

	-- 3rd person only: Ignore Self + Focus on Self After Inactivity
	addToggle(sub, "ignoreSelf", "Ignore Self (autofocus skips my character)")
	addHeader("Focus on Self After Inactivity")
	addSlider(sub, "idleSelfSeconds", "After Inactivity, Focus on Self", 0, 10, function(v)
		if v < 0.5 then return "Off" end
		return string.format("%.0f s", v)
	end, true)
	addSlider(sub, "idleTransition", "Transition Time to Self (seconds)", 0.1, 5, "%.1f s")
	addCycle(sub, "idleMode", "Inactivity Counts: ", {
		{id = "Move", name = "Character Movement Only"},
		{id = "MoveCam", name = "Character + Camera Movement"},
	})
	addNote("0 = Off. After this long with no activity, focus moves to your character over the transition time (instead of the normal autofocus speed) until you move again. Camera movement means real panning / zooming -- moving the mouse cursor alone does not count.", 82)

	-- 3rd person only: Pitch-Based Focus Area (part of the focus box/circle settings)
	gate(addHeader("Pitch-Based Focus Area"))
	gate(addToggle(sub, "pitchOn", "Move Area With Camera Pitch", flash))
	local function pitchOn() return sub.pitchOn end
	areaSlider("pitchMaxAngle", "Max Pitch Angle (0 level .. 45 full down)", 0, 45, "%.0f deg", pitchOn)
	areaSlider("pitchDownY", "Area Top When Looking Down (Y)", -100, 100, "%.0f", pitchOn)
	areaSlider("pitchCenterY", "Center Offset When Looking Straight (Y)", -100, 100, "%.0f", pitchOn)
	gate(addNote("Looking straight ahead the area sits at Position Y + Center Offset. Looking down by the Max Angle, its highest point sits at the Y above; in between it moves proportionally. The area stays on screen while you drag these -- tilt the camera to watch it move.", 82), pitchOn)
end
buildAF(cfg.tp, true)
buildAF(cfg.fp, false)

-- ---- Global: Momentary Focus Override ----
addHeader("Momentary Focus Override")
addToggle(cfg, "momentaryEnabled", "Momentary Focus Override")
do
	local function on() return cfg.momentaryEnabled end
	showIf(addKeyBind("momentaryKey", "Hold Key: ", false), on)
	local radius = showIf(addSlider(cfg, "momentaryRadius", "Center Focus Circle Size", 0, 50, "%.1f"), on)
	showIf(addCycle(cfg, "momentaryScope", "Override Active In: ", {
		{id = "Locked", name = "Mouse Locked (3rd Person)"},
		{id = "First", name = "First Person Only"},
		{id = "Both", name = "Both"},
	}), on)
	showIf(addNote("While the key is held, focus is forced to a circle at the exact centre of the screen (size 0 = a single point); release to return to normal focus. Mouse Locked = mouse locked while NOT in first person; First Person Only = first person; Both = either. Beats focus-on-self and normal autofocus.", 84), on)
	rcb.overlay.watch(rcb.overlay.add({
		eligible = on,
		geometry = function(cam) return rcb.momentaryGeometry(cam.ViewportSize) end,
		text = function() return string.format("Momentary focus circle | R %.1f", cfg.momentaryRadius) end,
	}), radius)
end

-- ---- Global: Cursor Auto Focus ----
addHeader("Cursor Auto Focus")
rcb.cursorToggle = addToggle(cfg, "cursorEnabled", "Cursor Auto Focus")
addKeyBind("cursorKey", "Toggle Hotkey: ", true)
addNote("Focus follows whatever the cursor points at, replacing the 3rd / 1st person focus target. The optional hotkey flips this ON/OFF. Player Autofocus, Focus on Self and the Momentary Override still take priority.", 70)

-- ---- Global: Player Autofocus (override) ----
addHeader("Player Autofocus (override)")
addToggle(cfg, "lockPlayer", "Auto Lock to Closest Player")
addToggle(cfg, "dirPriority", "Prefer Player Nearest Where I Look")
do
	local function anyPlayer() return cfg.lockPlayer or cfg.dirPriority end
	showIf(addSlider(cfg, "playerRange", "Player Range (studs)", 10, 200, "%.0f"), anyPlayer)
	showIf(addSlider(cfg, "dirAngle", "Look Direction Angle (deg)", 1, 30, "%.0f"), function() return cfg.dirPriority end)
	showIf(addToggle(cfg, "autoAdjustRange", "Auto Adjust Focus Range"), anyPlayer)
	showIf(addToggle(cfg, "disableWhenZoomedOut", "Disable Player Autofocus When Zoomed Out"), anyPlayer)
	showIf(addSlider(cfg, "zoomThreshold", "Zoomed-Out Distance (studs)", 1, 30, "%.1f"), function() return anyPlayer() and cfg.disableWhenZoomedOut end)
end

-- ---- Global: Lens Options ----
addHeader("Lens Options")
addSlider(cfg, "aperture", "Aperture (f-stop)", 1.2, 16, "f/%.1f")
addSlider(cfg, "fgMult", "Foreground Blur Multiplier", 0, 3, "%.2f")
addSlider(cfg, "fgOffset", "Foreground Blur Offset", -0.5, 0.5, "%.2f")
addSlider(cfg, "bgMult", "Background Blur Multiplier", 0, 3, "%.2f")
addSlider(cfg, "bgOffset", "Background Blur Offset", -0.5, 0.5, "%.2f")
addSlider(cfg, "rangeMult", "Focus Range Multiplier", 0.25, 4, "%.2f")

-- ---- Global: Autofocus Speed ----
addHeader("Autofocus Speed")
addSlider(cfg, "focusTime", "Focus Time (seconds)", 0.05, 2, "%.2f")
addSlider(cfg, "focusSpeed", "Focus Speed (doublings/sec)", 0.5, 8, "%.1f")
addSlider(cfg, "timeDistMix", "Time vs Distance (0=time 100=dist)", 0, 100, "%.0f%%")

-- ---- Global: Transition Curve Options ----
addHeader("Transition Curve Options")
addCycle(cfg, "curve", "Transition Curve: ", {{id = "Linear", name = "Linear"}, {id = "Logarithmic", name = "Logarithmic"}})

-- ---- Global: Reset ----
createButton(sec, "Reset Real Camera Blur Settings", function()
	for k, v in pairs(rcb.defaults) do
		if type(v) == "table" then
			for sk, sv in pairs(v) do cfg[k][sk] = sv end -- keep the tp / fp tables themselves (controls hold them)
		elseif k ~= "enabled" then
			cfg[k] = v
		end
	end
	syncUI()
	rcb.MarkDirty()
end)

-- ---- Global: Save / Load Autofocus Presets ----
rcb.presetUI = (function()
	-- ================= Focus Presets (separate from lighting presets) =================
	local FOCUS_PRESET_FILE = LOCAL_FOLDER_NAME .. "/_focus_presets.json" -- "_" prefix: the lighting-preset loader skips it
	local focusPresets = {}

	local presetFrame = Instance.new("Frame")
	presetFrame.Size = UDim2.new(1, 0, 0, 0)
	presetFrame.AutomaticSize = Enum.AutomaticSize.Y
	presetFrame.BackgroundTransparency = 1
	presetFrame.Parent = sec
	do
		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 6)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = presetFrame
	end

	local pHeader = Instance.new("TextLabel")
	pHeader.Size = UDim2.new(1, 0, 0, 20)
	pHeader.BackgroundTransparency = 1
	pHeader.Text = "Autofocus Presets"
	pHeader.TextColor3 = THEME_ACCENT
	pHeader.TextSize = 12
	pHeader.Font = Enum.Font.GothamBold
	pHeader.TextXAlignment = Enum.TextXAlignment.Left
	pHeader.LayoutOrder = 1
	pHeader.Parent = presetFrame

	local pNote = Instance.new("TextLabel")
	pNote.Size = UDim2.new(1, 0, 0, 44)
	pNote.BackgroundTransparency = 1
	pNote.TextWrapped = true
	pNote.TextSize = 11
	pNote.Font = Enum.Font.Gotham
	pNote.TextXAlignment = Enum.TextXAlignment.Left
	pNote.TextYAlignment = Enum.TextYAlignment.Top
	pNote.LayoutOrder = 2
	pNote.Parent = presetFrame
	if hasFilesystem then
		pNote.Text = "Saves the 3rd and 1st person focus setups (target, shape, position, sizes, Focus On, person mode, pitch) -- separate from lighting presets. Stored in " .. FOCUS_PRESET_FILE .. "."
		pNote.TextColor3 = Color3.fromRGB(120, 200, 255)
	else
		pNote.Text = "No runtime file access detected -- autofocus presets last for this session only."
		pNote.TextColor3 = Color3.fromRGB(220, 160, 90)
	end

	local nameBox = createTextBox(presetFrame, "Autofocus preset name...")
	nameBox.LayoutOrder = 3

	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1, 0, 0, 0)
	listFrame.AutomaticSize = Enum.AutomaticSize.Y
	listFrame.BackgroundTransparency = 1
	listFrame.LayoutOrder = 5
	listFrame.Parent = presetFrame
	do
		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 6)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = listFrame
	end

	-- preset key -> settings key (the short keys keep pre-v8.6 focus presets readable)
	local MAP = {
		target = "target", shape = "areaShape", x = "areaX", y = "areaY", length = "areaLength", width = "areaWidth",
		radius = "areaRadius", focusOn = "areaFocusOn", anyPerson = "anyPerson",
		pitchOn = "pitchOn", pitchMaxAngle = "pitchMaxAngle", pitchDownY = "pitchDownY", pitchCenterY = "pitchCenterY",
	}
	-- Presets only carry what they contain: a key that is missing or invalid stays nil, and
	-- applyFocusPreset leaves that setting alone (so loading an older / partial preset never
	-- resets unrelated settings such as the pitch options to defaults).
	local function num(v, lo, hi)
		if type(v) ~= "number" or v ~= v then return nil end
		return math.clamp(v, lo, hi)
	end
	local function bool(v)
		if type(v) == "boolean" then return v end
		return nil
	end
	local function sanitizeMode(d, third)
		if type(d) ~= "table" then return {} end
		local r = {
			target = (d.target == "Center" or d.target == "Area") and d.target or nil,
			shape = (d.shape == "Circle" or d.shape == "Box") and d.shape or nil,
			x = num(d.x, -100, 100), y = num(d.y, -100, 100),
			length = num(d.length, 0, 50), width = num(d.width, 0, 50),
			radius = num(d.radius, 0, 50), focusOn = num(d.focusOn, 20, 80),
			anyPerson = bool(d.anyPerson),
		}
		if third then
			r.pitchOn = bool(d.pitchOn)
			r.pitchMaxAngle = num(d.pitchMaxAngle, 0, 45)
			r.pitchDownY = num(d.pitchDownY, -100, 100)
			r.pitchCenterY = num(d.pitchCenterY, -100, 100)
		end
		return r
	end
	-- {tp = ..., fp = ...}. A pre-v8.6 preset (one flat area) is upgraded: it becomes both the
	-- 3rd and the 1st person setup, and (like before) loading it selects Auto Focus Box/Circle.
	local function sanitize(d)
		if type(d) ~= "table" then return nil end
		if d.tp == nil and d.fp == nil then
			local tp, fp = sanitizeMode(d, true), sanitizeMode(d, false)
			tp.target, fp.target = "Area", "Area"
			return {tp = tp, fp = fp}
		end
		return {tp = sanitizeMode(d.tp, true), fp = sanitizeMode(d.fp, false)}
	end
	local function captureArea()
		local out = {}
		for _, mode in ipairs({"tp", "fp"}) do
			local r = {}
			for pk, ck in pairs(MAP) do
				if cfg[mode][ck] ~= nil then r[pk] = cfg[mode][ck] end -- fp has no pitch keys
			end
			out[mode] = r
		end
		return out
	end
	local function persistFocusPresets()
		if not hasFilesystem then return end
		local out = {}
		for _, p in ipairs(focusPresets) do
			table.insert(out, {name = p.name, data = p.data})
		end
		saveJSONFile(FOCUS_PRESET_FILE, {presets = out})
	end
	local function applyFocusPreset(d)
		for _, mode in ipairs({"tp", "fp"}) do
			for pk, ck in pairs(MAP) do
				if d[mode][pk] ~= nil then cfg[mode][ck] = d[mode][pk] end
			end
		end
		syncUI()
		rcb.overlay.flashAll() -- flash the overlays so you see what was loaded
		rcb.MarkDirty()
	end

	local function rowBtn(parent, text, color, fromRight)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 32, 0, 24)
		b.Position = UDim2.new(1, -34 * fromRight + 2, 0.5, -12)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.Gotham
		b.TextSize = 10
		b.Parent = parent
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = b
		return b
	end

	local function renumber()
		for i, p in ipairs(focusPresets) do
			if p.row then p.row.LayoutOrder = i end
		end
	end

	local function createFocusRow(preset)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
		row.BackgroundTransparency = 0.1
		row.BorderSizePixel = 0
		row.Parent = listFrame
		preset.row = row
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0, 6)
		rc.Parent = row

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -146, 1, 0)
		nameLbl.Position = UDim2.new(0, 8, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = preset.name
		nameLbl.TextColor3 = Color3.fromRGB(220, 220, 225)
		nameLbl.Font = Enum.Font.Gotham
		nameLbl.TextSize = 12
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Parent = row

		local renBox = Instance.new("TextBox")
		renBox.Size = UDim2.new(1, -146, 0, 24)
		renBox.Position = UDim2.new(0, 8, 0.5, -12)
		renBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
		renBox.TextColor3 = Color3.fromRGB(230, 230, 235)
		renBox.Font = Enum.Font.Gotham
		renBox.TextSize = 12
		renBox.ClearTextOnFocus = false
		renBox.TextXAlignment = Enum.TextXAlignment.Left
		renBox.Visible = false
		renBox.Parent = row
		local rbc = Instance.new("UICorner")
		rbc.CornerRadius = UDim.new(0, 5)
		rbc.Parent = renBox

		local renBtn = rowBtn(row, "Ren", Color3.fromRGB(60, 60, 66), 4)
		local savBtn = rowBtn(row, "Sav", Color3.fromRGB(0, 110, 160), 3)
		local loadBtn = rowBtn(row, "Load", Color3.fromRGB(0, 140, 90), 2)
		local delBtn = rowBtn(row, "Del", Color3.fromRGB(150, 45, 45), 1)

		loadBtn.MouseButton1Click:Connect(function()
			applyFocusPreset(preset.data)
		end)
		savBtn.MouseButton1Click:Connect(function()
			showConfirm('Overwrite "' .. preset.name .. '" with your current autofocus setup?', function()
				preset.data = captureArea()
				persistFocusPresets()
			end)
		end)
		renBtn.MouseButton1Click:Connect(function()
			nameLbl.Visible = false
			renBox.Text = preset.name
			renBox.Visible = true
			renBox:CaptureFocus()
		end)
		renBox.FocusLost:Connect(function()
			renBox.Visible = false
			nameLbl.Visible = true
			local newName = renBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
			if newName == "" or newName == preset.name then return end
			for _, p in ipairs(focusPresets) do
				if p ~= preset and p.name == newName then return end -- name already taken
			end
			preset.name = newName
			nameLbl.Text = newName
			persistFocusPresets()
		end)
		delBtn.MouseButton1Click:Connect(function()
			showConfirm('Delete the autofocus preset "' .. preset.name .. '"? This can\'t be undone.', function()
				for i, p in ipairs(focusPresets) do
					if p == preset then table.remove(focusPresets, i) break end
				end
				row:Destroy()
				renumber()
				persistFocusPresets()
			end)
		end)
		renumber()
	end

	local saveNewBtn = createButton(presetFrame, "Save Current Autofocus Setup as New Preset", function()
		local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then
			local n = #focusPresets + 1
			local function taken(s)
				for _, p in ipairs(focusPresets) do if p.name == s then return true end end
				return false
			end
			while taken("Autofocus Preset " .. n) do n += 1 end
			name = "Autofocus Preset " .. n
		end
		local existing
		for _, p in ipairs(focusPresets) do
			if p.name == name then existing = p break end
		end
		local function doSave()
			if existing then
				existing.data = captureArea()
			else
				local p = {name = name, data = captureArea()}
				table.insert(focusPresets, p)
				createFocusRow(p)
			end
			persistFocusPresets()
			nameBox.Text = ""
		end
		if existing then
			showConfirm('An autofocus preset named "' .. name .. '" already exists. Overwrite it?', doSave)
		else
			doSave()
		end
	end)
	saveNewBtn.LayoutOrder = 4

	local okLoad, errLoad = pcall(function()
		local loaded = loadJSONFile(FOCUS_PRESET_FILE)
		if loaded and type(loaded.presets) == "table" then
			for _, e in ipairs(loaded.presets) do
				if type(e) == "table" and type(e.name) == "string" and e.name ~= "" then
					local d = sanitize(e.data)
					if d then
						local p = {name = e.name, data = d}
						table.insert(focusPresets, p)
						createFocusRow(p)
					end
				end
			end
		end
	end)
	if not okLoad then warn("[LightingUtility] Could not load autofocus presets: " .. tostring(errLoad)) end

	return {}
end)()

function refreshVisibility()
	for _, c in ipairs(rcb.conds) do c[1].Visible = c[2]() end
end
refreshVisibility()

-- live status text (cheap; only touches the label a few times a second)
local statusAccum = 0
CamSys.nextName = "statusText"
CamSys.track(RunService.Heartbeat, function(dt)
	statusAccum += dt
	if statusAccum < 0.25 then return end
	statusAccum = 0
	if sec.Visible and frame.Visible then
		local txt = rcb.GetStatus()
		if statusLbl.Text ~= txt then statusLbl.Text = txt end
	end
end)

-- restore "enabled" from the saved settings (baseline is captured NOW, after
-- any remembered last-lighting has already been applied)
if cfg.enabled then
	local okOn, errOn = pcall(rcb.SetEnabled, true)
	if not okOn then warn("[LightingUtility] Could not enable Real Camera Blur: " .. tostring(errOn)) end
end
rcb.enableToggle:Set(CamSys.dofActive, true) -- the switch always shows the real state
end

-- ---- Skybox ----
local skyboxNote = Instance.new("TextLabel")
skyboxNote.Size = UDim2.new(1, 0, 0, 44)
skyboxNote.BackgroundTransparency = 1
skyboxNote.Text = "Enter numeric asset IDs only (no rbxassetid:// prefix). Leave a field blank to leave that face unchanged."
skyboxNote.TextColor3 = Color3.fromRGB(160, 160, 165)
skyboxNote.TextWrapped = true
skyboxNote.TextSize = 12
skyboxNote.Font = Enum.Font.Gotham
skyboxNote.TextXAlignment = Enum.TextXAlignment.Left
skyboxNote.TextYAlignment = Enum.TextYAlignment.Top
skyboxNote.Parent = skyboxSection

local boxFt = createTextBox(skyboxSection, "Front face asset ID")
local boxBk = createTextBox(skyboxSection, "Back face asset ID")
local boxLf = createTextBox(skyboxSection, "Left face asset ID")
local boxRt = createTextBox(skyboxSection, "Right face asset ID")
local boxUp = createTextBox(skyboxSection, "Up face asset ID")
local boxDn = createTextBox(skyboxSection, "Down face asset ID")

local function applySkyboxFaces(ft, bk, lf, rt, up, dn)
	local sky = getSky()
	if ft and ft ~= "" then sky.SkyboxFt = "rbxassetid://" .. ft end
	if bk and bk ~= "" then sky.SkyboxBk = "rbxassetid://" .. bk end
	if lf and lf ~= "" then sky.SkyboxLf = "rbxassetid://" .. lf end
	if rt and rt ~= "" then sky.SkyboxRt = "rbxassetid://" .. rt end
	if up and up ~= "" then sky.SkyboxUp = "rbxassetid://" .. up end
	if dn and dn ~= "" then sky.SkyboxDn = "rbxassetid://" .. dn end
end

createButton(skyboxSection, "Apply Custom Skybox (fields above)", function()
	applySkyboxFaces(boxFt.Text, boxBk.Text, boxLf.Text, boxRt.Text, boxUp.Text, boxDn.Text)
end)

do
local presetDivider = Instance.new("Frame")
presetDivider.Size = UDim2.new(1, 0, 0, 1)
presetDivider.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
presetDivider.BorderSizePixel = 0
presetDivider.Parent = skyboxSection
end

local skyboxPresetLabel = Instance.new("TextLabel")
skyboxPresetLabel.Size = UDim2.new(1, 0, 0, 20)
skyboxPresetLabel.BackgroundTransparency = 1
skyboxPresetLabel.Text = "Presets (edit SKYBOX_PRESETS at the top of the script to fill these in):"
skyboxPresetLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
skyboxPresetLabel.TextWrapped = true
skyboxPresetLabel.TextSize = 12
skyboxPresetLabel.Font = Enum.Font.Gotham
skyboxPresetLabel.TextXAlignment = Enum.TextXAlignment.Left
skyboxPresetLabel.Parent = skyboxSection

for _, preset in ipairs(SKYBOX_PRESETS) do
	createButton(skyboxSection, "Apply: " .. preset.Name, function()
		applySkyboxFaces(preset.Ft, preset.Bk, preset.Lf, preset.Rt, preset.Up, preset.Dn)
	end)
end

-- ---- Presets ----
local function applyPreset(clock, bright, sat, con, ccBri, fogStart, fogEnd, fogCol)
	sClock:SetValue(clock)
	sBright:SetValue(bright)
	sSat:SetValue(sat)
	sCon:SetValue(con)
	sCcBri:SetValue(ccBri)
	sFogStart:SetValue(fogStart)
	sFogEnd:SetValue(fogEnd)
	sFogR:SetValue(fogCol.R)
	sFogG:SetValue(fogCol.G)
	sFogB:SetValue(fogCol.B)
end

createButton(presetSection, "Preset: Default Day", function()
	applyPreset(14, 2, 0, 0, 0, 0, 10000, Color3.fromRGB(192, 192, 192))
end)

createButton(presetSection, "Preset: Film Noir", function()
	applyPreset(0, 1.5, -1, 0.6, -0.1, 0, 1500, Color3.fromRGB(30, 30, 30))
end)

createButton(presetSection, "Preset: Vibrant Cyberpunk", function()
	applyPreset(18, 3, 1.2, 0.4, 0.1, 100, 3000, Color3.fromRGB(180, 50, 255))
end)

createButton(presetSection, "Preset: Night Vision", function()
	applyPreset(0, 4, 1.5, 0.5, 0.2, 0, 2000, Color3.fromRGB(20, 255, 50))
end)

-- ---- Custom Presets ----
local remotesFolder = ReplicatedStorage:FindFirstChild("LightingUtilityRemotes")
	or ReplicatedStorage:WaitForChild("LightingUtilityRemotes", 8)

local getPresetsRemote, savePresetRemote, deletePresetRemote, reorderPresetsRemote
local cloudSavingEnabled = false

if remotesFolder then
	getPresetsRemote = remotesFolder:WaitForChild("GetPresets", 5)
	savePresetRemote = remotesFolder:WaitForChild("SavePreset", 5)
	deletePresetRemote = remotesFolder:WaitForChild("DeletePreset", 5)
	reorderPresetsRemote = remotesFolder:FindFirstChild("ReorderPresets")
	cloudSavingEnabled = (getPresetsRemote ~= nil) and (savePresetRemote ~= nil) and (deletePresetRemote ~= nil)
end

local customPresetsNote = Instance.new("TextLabel")
customPresetsNote.Size = UDim2.new(1, 0, 0, 44)
customPresetsNote.BackgroundTransparency = 1
customPresetsNote.TextWrapped = true
customPresetsNote.TextSize = 12
customPresetsNote.Font = Enum.Font.Gotham
customPresetsNote.TextXAlignment = Enum.TextXAlignment.Left
customPresetsNote.TextYAlignment = Enum.TextYAlignment.Top

if hasFilesystem then
	customPresetsNote.Text = "Local saving is ON -- presets are saved directly to the runtime's workspace folder (" .. LOCAL_FOLDER_NAME .. ")."
	customPresetsNote.TextColor3 = Color3.fromRGB(120, 200, 255)
elseif cloudSavingEnabled then
	customPresetsNote.Text = "Cloud saving is ON -- presets persist across sessions for your account. Doesn't include the skybox."
	customPresetsNote.TextColor3 = Color3.fromRGB(120, 200, 150)
else
	customPresetsNote.Text = "Cloud saving is OFF (companion server script not found) -- presets are session-only right now."
	customPresetsNote.TextColor3 = Color3.fromRGB(220, 160, 90)
end
customPresetsNote.Parent = customPresetSection

local presetNameBox = createTextBox(customPresetSection, "Preset name...")

local customPresets = {} 

local presetListContainer = Instance.new("Frame")
presetListContainer.Size = UDim2.new(1, 0, 0, 0)
presetListContainer.AutomaticSize = Enum.AutomaticSize.Y
presetListContainer.BackgroundTransparency = 1
presetListContainer.LayoutOrder = 10
presetListContainer.Parent = customPresetSection

do
local presetListLayout = Instance.new("UIListLayout")
presetListLayout.Padding = UDim.new(0, 6)
presetListLayout.SortOrder = Enum.SortOrder.LayoutOrder
presetListLayout.Parent = presetListContainer
end

local function renumberPresetRows()
	for i, p in ipairs(customPresets) do
		if p.row then p.row.LayoutOrder = i end
	end
end

-- Persists the current customPresets order so it survives leaving/rejoining.
-- Cloud mode pushes it to the companion server script; local runtime mode
-- writes it straight to disk next to the preset files themselves.
local function persistPresetOrder()
	if cloudSavingEnabled and reorderPresetsRemote then
		local names = {}
		for _, p in ipairs(customPresets) do
			table.insert(names, p.name)
		end
		reorderPresetsRemote:FireServer(names)
	end

	if hasFilesystem then
		local names = {}
		for _, p in ipairs(customPresets) do
			table.insert(names, p.name)
		end
		saveJSONFile(ORDER_FILE, names)
	end
end

local function movePreset(preset, direction) 
	local idx
	for i, p in ipairs(customPresets) do
		if p == preset then idx = i; break end
	end
	if not idx then return end

	local targetIdx = idx + direction
	if targetIdx < 1 or targetIdx > #customPresets then return end

	customPresets[idx], customPresets[targetIdx] = customPresets[targetIdx], customPresets[idx]
	renumberPresetRows()
	persistPresetOrder()
end

-- Writes preset.data to disk/cloud under preset.name -- shared by
-- "Save Current as New Preset", the per-row Overwrite button, and Rename
-- (which deletes the old file/name and re-saves under the new one).
local function persistPresetToStorage(preset)
	if hasFilesystem then
		local safeName = preset.name:gsub("[\\/:*?\"<>|]", "_")
		local filePath = LOCAL_FOLDER_NAME .. "/" .. safeName .. ".json"
		saveJSONFile(filePath, serializeState(preset.data))
	elseif cloudSavingEnabled then
		savePresetRemote:FireServer(preset.name, serializeState(preset.data))
	end
end

local function deletePresetFromStorage(name)
	if hasFilesystem then
		local safeName = name:gsub("[\\/:*?\"<>|]", "_")
		local filePath = LOCAL_FOLDER_NAME .. "/" .. safeName .. ".json"
		if isfile(filePath) then
			pcall(delfile, filePath)
		end
	elseif cloudSavingEnabled then
		deletePresetRemote:FireServer(name)
	end
end

local function createPresetRow(preset)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
	row.BackgroundTransparency = 0.1
	row.BorderSizePixel = 0
	row.Parent = presetListContainer
	preset.row = row

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = Color3.fromRGB(255, 255, 255)
	rowStroke.Transparency = 0.93
	rowStroke.Thickness = 1
	rowStroke.Parent = row

	local reorderCol = Instance.new("Frame")
	reorderCol.Size = UDim2.new(0, 18, 1, -6)
	reorderCol.Position = UDim2.new(0, 2, 0, 3)
	reorderCol.BackgroundTransparency = 1
	reorderCol.Parent = row

	local upBtn = Instance.new("TextButton")
	upBtn.Size = UDim2.new(1, 0, 0, 13)
	upBtn.Position = UDim2.new(0, 0, 0, 0)
	upBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	upBtn.Text = "^"
	upBtn.TextColor3 = Color3.new(1, 1, 1)
	upBtn.Font = Enum.Font.GothamBold
	upBtn.TextSize = 10
	upBtn.Parent = reorderCol
	local upCorner = Instance.new("UICorner")
	upCorner.CornerRadius = UDim.new(0, 4)
	upCorner.Parent = upBtn

	local downBtn = Instance.new("TextButton")
	downBtn.Size = UDim2.new(1, 0, 0, 13)
	downBtn.Position = UDim2.new(0, 0, 1, -13)
	downBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
	downBtn.Text = "v"
	downBtn.TextColor3 = Color3.new(1, 1, 1)
	downBtn.Font = Enum.Font.GothamBold
	downBtn.TextSize = 10
	downBtn.Parent = reorderCol
	local downCorner = Instance.new("UICorner")
	downCorner.CornerRadius = UDim.new(0, 4)
	downCorner.Parent = downBtn

	upBtn.MouseButton1Click:Connect(function() movePreset(preset, -1) end)
	downBtn.MouseButton1Click:Connect(function() movePreset(preset, 1) end)

	-- Name label + inline rename textbox (same slot, only one visible at once)
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -164, 1, 0)
	nameLbl.Position = UDim2.new(0, 26, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = preset.name
	nameLbl.TextColor3 = Color3.fromRGB(220, 220, 225)
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 12
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = row

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, -164, 0, 24)
	nameBox.Position = UDim2.new(0, 26, 0.5, -12)
	nameBox.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	nameBox.TextColor3 = Color3.fromRGB(230, 230, 235)
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 12
	nameBox.ClearTextOnFocus = false
	nameBox.TextXAlignment = Enum.TextXAlignment.Left
	nameBox.Visible = false
	nameBox.Parent = row
	local nameBoxCorner = Instance.new("UICorner")
	nameBoxCorner.CornerRadius = UDim.new(0, 5)
	nameBoxCorner.Parent = nameBox
	local nameBoxPad = Instance.new("UIPadding")
	nameBoxPad.PaddingLeft = UDim.new(0, 6)
	nameBoxPad.Parent = nameBox

	local renameBtn = Instance.new("TextButton")
	renameBtn.Size = UDim2.new(0, 30, 0, 26)
	renameBtn.Position = UDim2.new(1, -132, 0.5, -13)
	renameBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
	renameBtn.Text = "Ren"
	renameBtn.TextColor3 = Color3.new(1, 1, 1)
	renameBtn.Font = Enum.Font.Gotham
	renameBtn.TextSize = 10
	renameBtn.Parent = row
	local renameCorner = Instance.new("UICorner")
	renameCorner.CornerRadius = UDim.new(0, 5)
	renameCorner.Parent = renameBtn

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0, 30, 0, 26)
	saveBtn.Position = UDim2.new(1, -98, 0.5, -13)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 160)
	saveBtn.Text = "Sav"
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.Gotham
	saveBtn.TextSize = 10
	saveBtn.Parent = row
	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 5)
	saveCorner.Parent = saveBtn

	local loadBtn = Instance.new("TextButton")
	loadBtn.Size = UDim2.new(0, 30, 0, 26)
	loadBtn.Position = UDim2.new(1, -64, 0.5, -13)
	loadBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 90)
	loadBtn.Text = "Load"
	loadBtn.TextColor3 = Color3.new(1, 1, 1)
	loadBtn.Font = Enum.Font.Gotham
	loadBtn.TextSize = 10
	loadBtn.Parent = row
	local loadCorner = Instance.new("UICorner")
	loadCorner.CornerRadius = UDim.new(0, 5)
	loadCorner.Parent = loadBtn

	local delBtn = Instance.new("TextButton")
	delBtn.Size = UDim2.new(0, 30, 0, 26)
	delBtn.Position = UDim2.new(1, -30, 0.5, -13)
	delBtn.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
	delBtn.Text = "Del"
	delBtn.TextColor3 = Color3.new(1, 1, 1)
	delBtn.Font = Enum.Font.Gotham
	delBtn.TextSize = 10
	delBtn.Parent = row
	local delCorner = Instance.new("UICorner")
	delCorner.CornerRadius = UDim.new(0, 5)
	delCorner.Parent = delBtn

	loadBtn.MouseButton1Click:Connect(function()
		applyState(preset.data)
		refreshSlidersFromState(preset.data)
		syncTogglesUI()
		if lockLighting then updateLockedSettings() end
		saveLastStateNow()
	end)

	-- Overwrite: re-save the CURRENTLY LIVE lighting into this existing
	-- preset slot, without needing to retype its name.
	saveBtn.MouseButton1Click:Connect(function()
		showConfirm(
			'Overwrite "' .. preset.name .. '" with your current lighting?',
			function()
				preset.data = captureState()
				persistPresetToStorage(preset)
			end
		)
	end)

	-- Rename: swap the label for an editable textbox in place.
	local function startRename()
		nameLbl.Visible = false
		nameBox.Text = preset.name
		nameBox.Visible = true
		nameBox:CaptureFocus()
	end

	local function finishRename()
		nameBox.Visible = false
		nameLbl.Visible = true

		local newName = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if newName == "" or newName == preset.name then return end

		-- Don't allow renaming onto another preset's name
		for _, p in ipairs(customPresets) do
			if p ~= preset and p.name == newName then
				return
			end
		end

		local oldName = preset.name
		deletePresetFromStorage(oldName)
		preset.name = newName
		nameLbl.Text = newName
		persistPresetToStorage(preset)
		persistPresetOrder()
	end

	renameBtn.MouseButton1Click:Connect(startRename)
	nameBox.FocusLost:Connect(finishRename)

	delBtn.MouseButton1Click:Connect(function()
		showConfirm(
			'Delete the preset "' .. preset.name .. '"? This can\'t be undone.',
			function()
				for idx, p in ipairs(customPresets) do
					if p == preset then
						table.remove(customPresets, idx)
						break
					end
				end

				deletePresetFromStorage(preset.name)
				row:Destroy()
				renumberPresetRows()
				persistPresetOrder()
			end
		)
	end)

	renumberPresetRows()
	return row
end

local function addOrUpdatePreset(name, state)
	local existing
	for _, p in ipairs(customPresets) do
		if p.name == name then existing = p; break end
	end

	if existing then
		existing.data = state
	else
		existing = {name = name, data = state}
		table.insert(customPresets, existing)
		createPresetRow(existing)
		persistPresetOrder()
	end

	persistPresetToStorage(existing)

	return existing
end

createButton(customPresetSection, "Save Current as New Preset", function()
	local name = presetNameBox.Text
	if name == "" then
		name = "Preset " .. (#customPresets + 1)
	end
	local exists = false
	for _, p in ipairs(customPresets) do
		if p.name == name then exists = true; break end
	end

	local function doSave()
		addOrUpdatePreset(name, captureState())
		presetNameBox.Text = ""
	end

	if exists then
		showConfirm('A preset named "' .. name .. '" already exists. Overwrite it?', doSave)
	else
		doSave()
	end
end)

-- Fetch Existing Presets (Local or Cloud)
if hasFilesystem then
	task.spawn(function()
		local ok, files = pcall(listfiles, LOCAL_FOLDER_NAME)
		if ok then
			local loaded = {}
			local readCount = 0
			for _, filePath in ipairs(files) do
				local fileName = filePath:match("([^/\\]+)%.json$")
				-- Skip our own internal files (_settings, _last_state, _order)
				-- -- these aren't presets.
				if fileName and not fileName:match("^_") then
					local readOk, content = pcall(readfile, filePath)
					if readOk then
						local decodeOk, parsed = pcall(function() return HttpService:JSONDecode(content) end)
						if decodeOk and type(parsed) == "table" then
							table.insert(loaded, {name = fileName, data = deserializeState(parsed)})
						end
					end
					readCount = readCount + 1
					if readCount % 3 == 0 then task.wait() end -- spread HDD reads across frames
				end
			end

			-- Restore the last-saved sort order (missing/new names fall
			-- through to the end, in the order they were found on disk).
			local savedOrder = loadJSONFile(ORDER_FILE)
			if savedOrder then
				local rank = {}
				for i, n in ipairs(savedOrder) do rank[n] = i end
				table.sort(loaded, function(a, b)
					local ra, rb = rank[a.name], rank[b.name]
					if ra and rb then return ra < rb end
					if ra then return true end
					if rb then return false end
					return false
				end)
			end

			for _, entry in ipairs(loaded) do
				table.insert(customPresets, entry)
				createPresetRow(entry)
			end
		end
	end)
elseif cloudSavingEnabled then
	task.spawn(function()
		local ok, remotePresets = pcall(function()
			return getPresetsRemote:InvokeServer()
		end)
		if ok and type(remotePresets) == "table" then
			for _, p in ipairs(remotePresets) do
				if type(p) == "table" and type(p.name) == "string" and type(p.data) == "table" then
					local entry = {name = p.name, data = deserializeState(p.data)}
					table.insert(customPresets, entry)
					createPresetRow(entry)
				end
			end
		end
	end)
end
-- ---- Import / Export ----
-- NOTE ON "CLIPBOARD": Roblox has no official API for a live game to write
-- to the OS clipboard -- that's not a gap here, it just doesn't exist for
-- security reasons (the only thing named like that, setclipboard(), is an
-- runtime-specific function, not something available in a normal
-- published game, so this script doesn't use it). Instead: exported text
-- gets dropped into a box with everything pre-selected, so you just press
-- Ctrl+C yourself. Same idea for "importing a file" -- there's no file
-- picker available either, so open the file yourself, copy its contents,
-- and paste (Ctrl+V) into the Import box below; that's as close as a live
-- LocalScript can get to reading a file.

do
local exportLabel = Instance.new("TextLabel")
exportLabel.Size = UDim2.new(1, 0, 0, 16)
exportLabel.BackgroundTransparency = 1
exportLabel.Text = "Export (click a button below, then Ctrl+C -- it's pre-selected)"
exportLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
exportLabel.TextWrapped = true
exportLabel.TextSize = 11
exportLabel.Font = Enum.Font.Gotham
exportLabel.TextXAlignment = Enum.TextXAlignment.Left
exportLabel.Parent = importExportSection

local exportBox = Instance.new("TextBox")
exportBox.Size = UDim2.new(1, 0, 0, 90)
exportBox.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
exportBox.TextColor3 = Color3.fromRGB(200, 220, 200)
exportBox.PlaceholderText = "Export output appears here..."
exportBox.Text = ""
exportBox.Font = Enum.Font.Code
exportBox.TextSize = 12
exportBox.MultiLine = true
exportBox.ClearTextOnFocus = false
exportBox.TextWrapped = true
exportBox.TextXAlignment = Enum.TextXAlignment.Left
exportBox.TextYAlignment = Enum.TextYAlignment.Top
exportBox.Parent = importExportSection

do
local exportBoxCorner = Instance.new("UICorner")
exportBoxCorner.CornerRadius = UDim.new(0, 6)
exportBoxCorner.Parent = exportBox
end

local function putInExportBoxAndSelectAll(text)
	exportBox.Text = text
	exportBox:CaptureFocus()
	exportBox.SelectionStart = 1
	exportBox.CursorPosition = #text + 1
end

createButton(importExportSection, "Export ALL Presets as Text (compact, multi-config)", function()
	if #customPresets == 0 then
		putInExportBoxAndSelectAll("-- (no custom presets saved yet)")
		return
	end
	local lines = {}
	for _, p in ipairs(customPresets) do
		-- one preset per line/bar: LUTPRESET::<name>::<minified json>
		-- the name travels inside the string itself, as requested
		local safeName = p.name:gsub("::", ";;")
		local json = HttpService:JSONEncode(serializeState(p.data))
		table.insert(lines, "LUTPRESET::" .. safeName .. "::" .. json)
	end
	putInExportBoxAndSelectAll(table.concat(lines, "\n"))
end)

createButton(importExportSection, "Export Current Lighting as JSON", function()
	local json = HttpService:JSONEncode(serializeState(captureState()))
	putInExportBoxAndSelectAll(json)
end)

local importLabel = Instance.new("TextLabel")
importLabel.Size = UDim2.new(1, 0, 0, 16)
importLabel.BackgroundTransparency = 1
importLabel.Text = "Import (paste below -- accepts the compact multi-config text OR a single raw JSON export)"
importLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
importLabel.TextWrapped = true
importLabel.TextSize = 11
importLabel.Font = Enum.Font.Gotham
importLabel.TextXAlignment = Enum.TextXAlignment.Left
importLabel.Parent = importExportSection

local importBox = Instance.new("TextBox")
importBox.Size = UDim2.new(1, 0, 0, 90)
importBox.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
importBox.TextColor3 = Color3.fromRGB(220, 220, 225)
importBox.PlaceholderText = "Paste config text or JSON here..."
importBox.Text = ""
importBox.Font = Enum.Font.Code
importBox.TextSize = 12
importBox.MultiLine = true
importBox.ClearTextOnFocus = false
importBox.TextWrapped = true
importBox.TextXAlignment = Enum.TextXAlignment.Left
importBox.TextYAlignment = Enum.TextYAlignment.Top
importBox.Parent = importExportSection

do
local importBoxCorner = Instance.new("UICorner")
importBoxCorner.CornerRadius = UDim.new(0, 6)
importBoxCorner.Parent = importBox
end

local importStatusLabel = Instance.new("TextLabel")
importStatusLabel.Size = UDim2.new(1, 0, 0, 16)
importStatusLabel.BackgroundTransparency = 1
importStatusLabel.Text = ""
importStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
importStatusLabel.TextWrapped = true
importStatusLabel.TextSize = 11
importStatusLabel.Font = Enum.Font.Gotham
importStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
importStatusLabel.Parent = importExportSection

createButton(importExportSection, "Import From Text Above", function()
	local text = importBox.Text
	if text == nil or text:match("^%s*$") then
		importStatusLabel.TextColor3 = Color3.fromRGB(220, 140, 140)
		importStatusLabel.Text = "Nothing to import -- paste something first."
		return
	end

	-- Multi-config compact format: one "LUTPRESET::name::json" per line
	local importedCount = 0
	local sawMultiFormat = false

	for line in text:gmatch("[^\r\n]+") do
		local name, json = line:match("^LUTPRESET::(.-)::(.+)$")
		if name and json then
			sawMultiFormat = true
			name = name:gsub(";;", "::")
			local ok, decoded = pcall(function()
				return HttpService:JSONDecode(json)
			end)
			if ok and type(decoded) == "table" then
				addOrUpdatePreset(name, deserializeState(decoded))
				importedCount += 1
			end
		end
	end

	if sawMultiFormat then
		importStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
		importStatusLabel.Text = "Imported " .. importedCount .. " preset(s)."
		importBox.Text = ""
		return
	end

	-- Fall back: treat the whole box as one raw JSON state export
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(text)
	end)

	if ok and type(decoded) == "table" then
		local name = presetNameBox.Text
		if name == "" then name = "Imported Preset" end
		addOrUpdatePreset(name, deserializeState(decoded))
		importStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 160)
		importStatusLabel.Text = 'Imported 1 preset as "' .. name .. '".'
		importBox.Text = ""
		presetNameBox.Text = ""
	else
		importStatusLabel.TextColor3 = Color3.fromRGB(220, 140, 140)
		importStatusLabel.Text = "Import failed -- that doesn't look like valid exported text or JSON."
	end
end)
end

-- ---- Utilities: Reset to Server Defaults ----
createButton(utilitySection, "Reset to Server Defaults", function()
	showConfirm(
		"Reset ALL lighting, atmosphere, and post-effects back to what the server had before this script touched anything? This also zeroes out your View Offsets. This can't be undone (though your Custom Presets are safe).",
		function()
			-- Real Camera Blur is a runtime layer over DoF: release it first so the
			-- reset below restores the real (normal) DoF values
			local rcb = CamSys.rcb
			local rcbWasOn = rcb and rcb.config.enabled
			if rcb then rcb.SetEnabled(false) end -- in-memory only: nothing is written to the settings file
			resetToServerDefaults()
			refreshSlidersFromState(captureState())
			resetOffsetsToZero()
			syncTogglesUI()
			lockBtn.Text = "Override Lock Loop: OFF"
			lockBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 48)
			if rcb then
				if rcbWasOn then rcb.SetEnabled(true) end -- baseline = the freshly reset DoF values
				if rcb.enableToggle then rcb.enableToggle:Set(rcb.config.enabled, true) end
			end
		end
	)
end)

-- ---- Performance Monitor (opt-in diagnostics) ----
-- Off by default. While off there is no connection at all (only the one table read
-- inside each CamSys.timed wrapper). While on it reports the CPU time of THIS
-- script's per-frame work and, for every frame hitch (> 120 ms), whether the
-- script could have caused it -- so you can tell script stutter from Roblox/system/disk.
-- (Assigned to a field on purpose: a bare statement starting with "(" would be parsed as a
-- call on the PREVIOUS statement's result.)
CamSys.perfUI = (function()
	local pf = CamSys.perf
	local btn, lbl, conn
	local acc, frames, totalMs, peakMs, prevMs, lastRays = 0, 0, 0, 0, 0, 0

	local function onHeartbeat(dt)
		local ms = pf.frameMs
		pf.frameMs = 0
		frames += 1
		totalMs += ms
		if ms > peakMs then peakMs = ms end
		if dt > 0.12 then -- a visible hitch
			pf.hitches += 1
			local mine = ms + prevMs -- callbacks can land on either side of this connection within a frame
			pf.lastHitch = string.format("%.2f s frame; script used %.1f ms of it -> %s", dt, mine,
				(mine > dt * 1000 * 0.4) and "THE SCRIPT" or "NOT the script (Roblox / system / disk)")
		end
		prevMs = ms
		acc += dt
		if acc >= 1 then
			local worstName, worstMs = "-", 0
			for name, e in pairs(pf.mods) do
				if e.worst > worstMs then worstName, worstMs = name, e.worst end
			end
			lbl.Text = string.format(
				"script CPU: avg %.2f ms/frame, peak %.1f ms\nrays/s: %d | file writes (total): %d\nworst single callback: %s %.1f ms\nhitches >120 ms: %d\nlast hitch: %s",
				totalMs / math.max(frames, 1), peakMs, math.floor((pf.rays - lastRays) / acc), pf.writes, worstName, worstMs,
				pf.hitches, pf.lastHitch or "none")
			acc, frames, totalMs, peakMs = 0, 0, 0, 0
			lastRays = pf.rays
		end
	end

	local function setEnabled(on)
		pf.on = on
		btn.Text = "Performance Monitor (diagnostics): " .. (on and "ON" or "OFF")
		lbl.Visible = on
		lbl.Text = on and "measuring..." or ""
		pf.mods, pf.frameMs, pf.hitches, pf.lastHitch = {}, 0, 0, nil
		if on then
			acc, frames, totalMs, peakMs, prevMs = 0, 0, 0, 0, 0
			lastRays = pf.rays
			conn = CamSys.track(RunService.Heartbeat, onHeartbeat)
		elseif conn then
			conn:Disconnect()
			for i, c in ipairs(CamSys.conns) do
				if c == conn then table.remove(CamSys.conns, i) break end
			end
			conn = nil
		end
	end

	btn = createButton(utilitySection, "Performance Monitor (diagnostics): OFF", function()
		setEnabled(not pf.on)
	end)
	lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 96)
	lbl.BackgroundTransparency = 1
	lbl.TextWrapped = true
	lbl.TextSize = 11
	lbl.Font = Enum.Font.Code
	lbl.TextColor3 = Color3.fromRGB(150, 220, 170)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.Text = ""
	lbl.Visible = false
	lbl.Parent = utilitySection
end)()

-- ============================================================
-- Live-Sync Loop -- fixes stale faders when Override is OFF.
--
-- The bug this solves: if the game has its own dynamic lighting (a
-- day/night cycle, a storm system, whatever) running server-side, it
-- changes Lighting properties out from under this tool. With Override
-- OFF, this tool was never reading those changes back -- so a fader could
-- sit at some old position while the actual live value had moved on.
-- Touching that fader would then suddenly snap the real lighting to the
-- stale number instead of adjusting from where it actually was.
--
-- Fix: while Override is OFF (and you're not actively dragging something),
-- periodically re-read the true live state and resync every fader to it.
-- While Override IS ON, the existing lock loop above already reasserts
-- lockedSettings every rendered frame -- THAT's what actually overrides
-- the dynamic system; this loop deliberately does nothing in that case.
-- ============================================================
do
local LIVE_SYNC_INTERVAL = 0.2 -- seconds; frequent enough to feel live, cheap enough not to matter
local liveSyncAccumulator = 0

CamSys.nextName = "liveSync"
CamSys.track(RunService.Heartbeat, function(dt)
	if lockLighting then return end -- Override handles this case instead
	if #activeSliders > 0 then return end -- don't fight the user's own drag

	liveSyncAccumulator += dt
	if liveSyncAccumulator < LIVE_SYNC_INTERVAL then return end
	liveSyncAccumulator = 0

	-- Exposure/Saturation/Contrast/Tint are base+offset (see further up) --
	-- re-derive base by subtracting our own offset contribution, so an
	-- external change to the live property shows up as a base change
	-- without silently absorbing our own offset into it.
	-- (the automatic AE / AWB layers are subtracted too, so they never get
	-- absorbed into the base; at Roblox's +/-5 EV clamp the live value no longer
	-- reflects base + offsets, so exposure isn't re-derived there)
	if math.abs(Lighting.ExposureCompensation) < 4.99 then
		baseExposure = Lighting.ExposureCompensation - offsetExposure - CamSys.autoExposureEV
	end
	baseSaturation = colorCorrection.Saturation - offsetSaturation
	baseContrast = colorCorrection.Contrast - offsetContrast
	-- Only re-derive WB/Tint when the live TintColor is NOT what this script last wrote
	-- (i.e. something external changed it). Otherwise clamping at the multiplier extremes
	-- would make the base drift every sync. Multipliers are divided out before inverting.
	local liveTC, expTC = colorCorrection.TintColor, CamSys.expectedTintColor()
	local tintExternal = math.abs(liveTC.R - expTC.R) > 0.002 or math.abs(liveTC.G - expTC.G) > 0.002 or math.abs(liveTC.B - expTC.B) > 0.002
	if tintExternal and CamSys.tintMulR > 0.01 and CamSys.tintMulG > 0.01 and CamSys.tintMulB > 0.01 then
		local liveWB, liveTint = invertTintColor(Color3.new(
			math.clamp(liveTC.R / CamSys.tintMulR, 0, 2),
			math.clamp(liveTC.G / CamSys.tintMulG, 0, 2),
			math.clamp(liveTC.B / CamSys.tintMulB, 0, 2)
		))
		currentWB = liveWB - offsetWB - CamSys.autoWB
		currentTint = liveTint - offsetTint - CamSys.autoTint
	end

	-- the base values above are always re-derived (autosave / Override read them), but the
	-- sliders are only repainted while the window is actually on screen
	if frame.Visible then
		refreshSlidersFromState(captureState())
		syncTogglesUI()
	end
end)
end

-- ============================================================
-- Keybind to Toggle Menu Visibility (Press "L")
-- ============================================================
CamSys.track(UserInputService.InputBegan, function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.L then
		if minimizedIcon.Visible then
			iconHide(function()
				animateShow(frame, frameScale)
			end)
		elseif frame.Visible then
			animateHide(frame, frameScale)
		else
			animateShow(frame, frameScale)
		end
	end
end)
