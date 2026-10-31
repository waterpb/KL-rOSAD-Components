-- LocalScript -> StarterPlayer > StarterPlayerScripts
-- Aim assist with instant left-click pre-aim snap, target persistence, bot/pseudo-player detection, translucent settings panel, and persistent settings.
-- v1.11: universal keybinds, Anti-Recoil tab (always-active / post-click fade), viewmodel pose lock, preset list.
-- + bindable hold-to-aim key, wall-independent tracers, trigger bot, and DEV RAGE MODE (spin bot / silent aim / autofire / autojump / third person).
-- + 6 o'clock exclusion wedge (BottomWedge): targets within BottomWedge.deg degrees of straight down are ignored.

--==================================================================--
--  CUSTOM BODY PART ASSET IDS  (edit these)
--  Any MeshPart / SpecialMesh whose MeshId (or TextureID) matches an
--  ID below is treated as that character's HEAD or TORSO.
--  Accepts numbers, "123456", "rbxassetid://123456" or asset URLs.
--  Leave both lists empty to use the normal Head / UpperTorso / Torso.
--==================================================================--
local CUSTOM_HEAD_IDS = {
	6179256256, 16150814, -- 16150814 reaper
	-- "rbxassetid://1234567890",
}
local CUSTOM_TORSO_IDS = {
    132077786, 4049240078 -- 132077 786 reaper
	-- 1234567890,
}

-- true  = ONLY a custom head counts as a head. Characters without one are skipped completely
--         (the regular Head / Top part is not used as a fallback).
-- false = custom head preferred, regular head used when no custom one is found.
-- Ignored while no custom head is configured (empty ID list and no head names in the CUSTOM PARTS panel).
local IGNORE_REGULAR_HEADS = true

-- TARGET SCOPE: auto-detects everything under workspace.Players; you pick which ones to detect / lock onto
-- from the panel (MAIN > TARGET SCOPE). Functions are defined further down, once `settings` exists.
local Scope = {}
--==================================================================--

-- Lowercase name fragments used to find the gun's muzzle (Attachment or Part inside the equipped Tool)
-- for muzzle-based anti-recoil. Add your own gun's muzzle name here if it isn't detected.
local MUZZLE_NAMES = { "muzzle", "barrel", "firepoint", "shootpoint", "bulletspawn", "bulletorigin" }

local HAS_CUSTOM, partRole, getBodyParts, onCustomPart, forgetBody = false, nil, nil, nil, nil

do
	local HEAD_SET, TORSO_SET = {}, {}
	local function key(v)
		return v ~= nil and tostring(v):match("%d+") or nil
	end
	for _, id in ipairs(CUSTOM_HEAD_IDS) do local k = key(id) if k then HEAD_SET[k] = true end end
	for _, id in ipairs(CUSTOM_TORSO_IDS) do local k = key(id) if k then TORSO_SET[k] = true end end
	HAS_CUSTOM = next(HEAD_SET) ~= nil or next(TORSO_SET) ~= nil
	Scope.headIds = next(HEAD_SET) ~= nil

	local function roleOf(assetStr)
		local k = key(assetStr)
		if not k then return nil end
		if HEAD_SET[k] then return "head" end
		if TORSO_SET[k] then return "torso" end
		return nil
	end

	-- returns role ("head" / "torso") and the BasePart carrying the matching asset
	-- only matches parts inside the folder from getCustomFolder()
	partRole = function(inst, raw) -- raw = true skips the scope restriction
		local c = inst.ClassName
		local part, role
		if c == "MeshPart" then
			part = inst
			role = roleOf(inst.MeshId) or roleOf(inst.TextureID)
		elseif c == "SpecialMesh" then
			part = inst.Parent
			role = roleOf(inst.MeshId) or roleOf(inst.TextureId)
		else
			return nil
		end
		if not (role and part and part:IsA("BasePart")) then return nil end

		-- scope restriction (inside workspace.Players, and inside a ticked entry if any are ticked)
		if not raw and not Scope.allowsPart(part) then return nil end

		return role, part
	end

	local bodyCache = setmetatable({}, { __mode = "k" })

	forgetBody = function(char) bodyCache[char] = nil end

	-- cached lookup of a character's custom head / torso parts (O(1) on the hot path)
	getBodyParts = function(char)
		if not HAS_CUSTOM then return nil, nil end
		local now = os.clock()
		local c = bodyCache[char]
		if c and now < c.expire and (not c.head or c.head.Parent) and (not c.torso or c.torso.Parent) then
			return c.head, c.torso
		end
		local head, torso
		for _, d in ipairs(char:GetDescendants()) do
			local role, part = partRole(d)
			if role == "head" and not head then head = part
			elseif role == "torso" and not torso then torso = part end
			if head and torso then break end
		end
		bodyCache[char] = { head = head, torso = torso, expire = now + ((head or torso) and 5 or 1.5) }
		return head, torso
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then
	warn("[AimAssist] No LocalPlayer. Press Play / Start Server first, then run it again.")
	return
end

local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
while not camera do
	task.wait()
	camera = workspace.CurrentCamera
end

local DEFAULTS = {
	Enabled = true,
	RequireTool = true,
	ShowCircle = true,
	WallCheck = false,
	TeamCheck = true,
	RightClick = true,
	LeftClick = true,
	LeftStability = 0.65,
	Tracers = false,
	FOV = 150,
	Strength = 0.5,
	Boost = 0.8,
	BoostRange = 80,
	SyncMouse = true,
	AntiRecoil = true,
	RecoilStrength = 0.8,
	RecoilHorizontal = true,

	-- binds (KeyCode name, "MouseButton3", or "None")
	CustomHeadNames = "",    -- comma-separated part names/paths used as the head, e.g. Top, Hitbox.Top
	CustomTorsoNames = "",   -- same for the torso, e.g. Center
	CustomTargetFolder = "Characters", -- workspace path whose Models are all registered as targets, e.g. Characters
	MinDistance = 3, -- studs; ignore anything closer than this to your character (stops self/clone targeting)
	LeftDelay = 0,   -- seconds between aim engaging on a target and the scripted left-click fire (0-0.3; 0 = off, native click only)
	RightDelay = 0,  -- same for right click. Hold key (Q) still uses this as a hold-before-aim delay, as before
	RageDelay = 0,   -- seconds after a rage target is acquired before it fires
	TriggerAssetDepth = 2,  -- studs the trigger may look through attached assets (helmets, armor) to reach the body
	TriggerTeamBlock = true, -- hold fire when a teammate (or their asset) is in the way
	TriggerNeedsAim = false, -- trigger bot only fires while the aimbot is locked on
	MuzzleRecoil = false,   -- detect the gun's muzzle and compensate its kick (replaces camera-delta anti-recoil)
	MuzzleComp = 1,         -- 0-1 compensation rate for muzzle anti-recoil
	TriggerWallDepth = 0.3, -- studs of occluder the trigger bot may see through
	TriggerAssetDist = 1,   -- studs: parts this close to a target count as that target (helmets, external assets)
	TracerDist = 2,   -- index into TRACER_DISTS (600 / 1200 / 2400)
	KeepDelay = 150,  -- ms to keep a target through brief wall/visibility failures
	LockCursor = false, -- aim at the real cursor instead of screen center
	AimBlend = 0,       -- aim point between head (0) and torso (1)
	PreferVisible = false,     -- candidates that are not behind a wall always beat ones that are
	PreferClosestBehind = false, -- full priority order: not behind a wall, then behind walls nearest to YOU first, then farther ones
	WallIgnoreDepth = 0,       -- studs: a wall this thin (in total along the line of sight) does not count as a wall (0 = off)
	MuzzleOn = false,      -- ballistic prediction: solve the shot from muzzle velocity + gravity + target velocity
	MuzzleVelocity = 2000, -- studs/s (500-6500)
	ProjGravity = 0,       -- studs/s^2 used for the bullet; 0 = the game's workspace.Gravity (never the player-movement gravity)
	PredMarker = true,     -- debug marker where the shot is expected to land
	PredH = 55, PredS = 100, PredL = 60, -- marker colour (HSL)
	BottomDeg = 10,     -- 6 o'clock exclusion: half-angle in degrees (0 = off)
	ReleaseHoldMs = 0,  -- ms the camera keeps chasing the aim point after you release (0 = let go instantly)
	HardLockDeg = 2,    -- inside this many degrees of the aim point the lock is absolute (0 = off)
	OffsetRange = 0,    -- mouse offset while left click is held: degrees pushed down (0 = off)
	OffsetTime = 1,     -- seconds to reach the full offset
	OffsetCurve = 1,    -- 1 = linear, 2 = logarithmic (fast start, slow finish)

	-- camera filter counter (heavy ADS camera smoothing)
	FilterPass = 100,   -- % of the game's own (filtered) camera movement let through while locked (100 = all, 0 = none)
	LockSpeed = 1,      -- multiplier on lock speed (visible lerp and mouse correction)
	AimLead = 0,        -- seconds of target velocity added to the aim point (counters camera lag on moving targets)

	-- visual debug
	TracerThick = 1,    -- px
	TracerStyle = 1,    -- 1 = anti-aliased GUI line, 2 = sharp pixel line (Drawing API)
	TracerEnd = 1,      -- 1 = tracers end at the head, 2 = at the body (root)
	TracerH = 199, TracerS = 100, TracerL = 74,   -- normal tracer colour (HSL)
	BlockedH = 37, BlockedS = 100, BlockedL = 65, -- target behind a wall
	FocusH = 7, FocusS = 100, FocusL = 64,        -- focused / locked target
	HealthBar = false,
	HealthBarSize = 100, -- percent of the default 36 x 4 px bar
	HealthBarDist = false, -- bar size follows distance (closer = bigger)
	Chams = false,
	ChamMode = 2,       -- behind-wall layer: 1 = world copy near the camera (viewmodel layer), 2 = screen overlay (ViewportFrame, stable like the tracers)
	ChamRate = 3,       -- chams update rate: 1 = 30 fps, 2 = 60 fps, 3 = every rendered frame
	ChamWall = true,    -- the behind-wall (white) chams on / off (off = nothing is cloned or drawn for them)
	ChamWallDist = 500, -- studs: behind-wall copies are only made for targets closer than this
	Box = false,        -- character box marker (cheap 2D frame around the character)
	BoxThick = 1,       -- px
	BoxPad = 0,         -- percent: grows the box (for parts whose mesh is bigger than their Size)
	BoxH = 135, BoxS = 100, BoxL = 55,                -- box colour: normal (HSL)
	BoxBlockedH = 40, BoxBlockedS = 100, BoxBlockedL = 60, -- box colour: target behind a wall
	BoxFocusH = 0, BoxFocusS = 100, BoxFocusL = 60,   -- box colour: focused target
	ChamWallH = 0, ChamWallS = 0, ChamWallL = 100, ChamWallFill = 50, ChamWallOutline = 100, -- behind walls (white)
	ChamVisH = 0, ChamVisS = 100, ChamVisL = 50, ChamVisFill = 40, ChamVisOutline = 100,    -- in view (red)
	ScopeSel = "",      -- newline-separated names of workspace.Players children to detect / lock onto ("" = all)
	ScopeAuto = false,  -- auto-select every workspace.Players entry that is NOT mine (the enemy side), re-checked live
	ScopeMethod = 1,    -- how "mine" is found: 1 = my character / my name, 2 = the head nearest the camera
	ScopeNearStuds = 3, -- method 2: a head must be within this many studs of the camera to count as mine
	CamDiag = false,    -- print camera diagnostics (who rewrites the camera after us) to the executor log
	ToggleKey = "G",        -- aim assist on/off
	PanelKey = "RightShift", -- show / hide the panel
	ClickGameUI = false,    -- allow auto-clicks while the cursor is over clickable game UI
	ForcePerspective = true, -- rage mode keeps re-applying its camera settings against game scripts
	AlwaysAim = false,      -- always-active mode: lock on whenever a target is in range, no click needed
	AlwaysKey = "None",     -- bind to toggle AlwaysAim
	Notify = true,          -- toast notifications when a bound feature is toggled
	NotifyLeft = false,     -- legacy (pre-NotifyPos); only read once to migrate old configs
	NotifyPos = 2,          -- toast position: 1 = bottom-left, 2 = bottom-right, 3 = center (just below screen center)
	HoldKey = "Q",
	RageKey = "V",
	RecoilKey = "None",       -- toggle anti-recoil
	TriggerKey = "None",      -- toggle trigger bot
	ModelLockKey = "None",    -- toggle viewmodel lock
	ModelCaptureKey = "None", -- capture the weapon pose (held = lock while held)

	-- anti-recoil
	RecoilAlways = false,   -- recoil control runs without holding left click
	RecoilPostMs = 150,     -- ms of recoil control kept after left click is released (0-500)
	RecoilFade = 1,         -- post-click fade-out: 1 = linear, 2 = logarithmic (fast drop, long tail)

	-- viewmodel / gun model lock
	ModelLock = false,        -- hold the weapon at its captured pose
	ModelPerTool = false,     -- remember + restore the locked pose per tool
	ModelLockOnClick = false, -- capture the pose on left click and hold it while the button is down

	-- trigger bot
	TriggerBot = false,
	TriggerWalls = false,
	TriggerRadius = 8,
	TriggerDelay = 0.03,
	FireRate = 0.1,

	-- dev rage mode
	RageSpin = true,
	SpinSpeed = 1440,
	RageAutoJump = true,
	RageThirdPerson = true,
	RageZoom = 14,
	RageMouseLook = true,
	RageAutoFire = true,
	RageWalls = true,
	RageLead = 0,
}

local settings = {}
for k, v in pairs(DEFAULTS) do settings[k] = v end

-- TARGET SCOPE logic. Only entries that currently exist AND are ticked count; nothing ticked (or a stale saved
-- selection from an older session whose names no longer exist) = no restriction, everything under Players is allowed.
do
	local cache, cacheAt = nil, 0

	function Scope.container()
		return workspace:FindFirstChild("Players")
	end

	function Scope.invalidate() cache = nil end

	-- METHOD 2: the head closest to the camera (within ScopeNearStuds) is MY head; its entry is my team.
	-- "Head" = a custom asset head, a part named Head, or the last name of anything typed in the head-names box.
	Scope.mine = nil
	function Scope.scanNearest()
		local box, cam = Scope.container(), workspace.CurrentCamera
		if not (box and cam) then return nil end
		local camPos = cam.CFrame.Position
		local extra = {}
		for chunk in string.gmatch(settings.CustomHeadNames or "", "[^,]+") do
			local last = chunk:match("([^%.%s]+)%s*$")
			if last then extra[last:lower()] = true end
		end
		local best, bestD = nil, settings.ScopeNearStuds
		for _, c in ipairs(box:GetChildren()) do
			for _, d in ipairs(c:GetDescendants()) do
				local part
				local cn = d.ClassName
				if cn == "MeshPart" or cn == "SpecialMesh" then
					local role, p = partRole(d, true)
					if role == "head" then part = p end
				end
				if not part and d:IsA("BasePart") then
					local n = d.Name:lower()
					if n == "head" or extra[n] then part = d end
				end
				if part then
					local dist = (part.Position - camPos).Magnitude
					if dist < bestD then best, bestD = c, dist end
				end
			end
		end
		return best, bestD
	end

	-- is this entry mine? (method 2 uses the detected entry; with nothing detected yet it falls back to method 1)
	function Scope.isMine(c)
		if settings.ScopeMethod == 2 and Scope.mine and Scope.mine.Parent then return c == Scope.mine end
		return Scope.hasMe(c)
	end

	-- does this workspace.Players entry contain my own character (directly, as a descendant, or named after me)?
	function Scope.hasMe(c)
		local ch = player.Character
		if ch and (ch == c or ch:IsDescendantOf(c)) then return true end
		if c.Name == player.Name then return true end
		return c:FindFirstChild(player.Name, true) ~= nil
	end

	function Scope.active()
		local now = os.clock()
		if cache and now - cacheAt < 0.25 then return cache end
		cacheAt = now
		local list = {}
		local box = Scope.container()
		if box and settings.ScopeAuto then
			-- auto: every entry that does not contain me
			for _, c in ipairs(box:GetChildren()) do
				if not Scope.isMine(c) then list[#list + 1] = c end
			end
		elseif box and settings.ScopeSel ~= "" then
			local want = {}
			for n in string.gmatch(settings.ScopeSel, "[^\n]+") do want[n] = true end
			for _, c in ipairs(box:GetChildren()) do
				if want[c.Name] then list[#list + 1] = c end
			end
		end
		cache = list
		return list
	end

	local function inside(inst, list)
		for i = 1, #list do
			local c = list[i]
			if inst == c or inst:IsDescendantOf(c) then return true end
		end
		return false
	end

	-- custom head/torso parts: must live under workspace.Players (and under a ticked entry if any are ticked)
	function Scope.allowsPart(part)
		local box = Scope.container()
		if not box then return true end
		if not part:IsDescendantOf(box) then return false end
		local list = Scope.active()
		return #list == 0 or inside(part, list)
	end

	-- any character: only restricted when it lives under workspace.Players
	function Scope.allowsChar(char)
		local box = Scope.container()
		if not box or not char:IsDescendantOf(box) then return true end
		local list = Scope.active()
		return #list == 0 or inside(char, list)
	end
end

-- Shared keybind system (the UI half is defined with the other controls). One setting key per bindable action.
local Binds = {
	keys = { "ToggleKey", "AlwaysKey", "RageKey", "RecoilKey", "TriggerKey", "ModelLockKey", "ModelCaptureKey", "HoldKey", "PanelKey" },
	-- keybound feature toggles: setting flipped through its UI setter, then a toast
	toggles = {
		{ bind = "ToggleKey", setting = "Enabled", id = "aim", name = "Aimbot" },
		{ bind = "AlwaysKey", setting = "AlwaysAim", id = "always", name = "Always Active" },
		{ bind = "RageKey", setting = "RageActive", id = "rage", name = "Rage Mode" },
		{ bind = "RecoilKey", setting = "AntiRecoil", id = "recoil", name = "Anti-Recoil" },
		{ bind = "TriggerKey", setting = "TriggerBot", id = "trigger", name = "Trigger Bot" },
		{ bind = "ModelLockKey", setting = "ModelLock", id = "modellock", name = "Model Lock" },
	},
}

function Binds.valid(v)
	if v == "None" or v == "MouseButton3" then return true end
	if type(v) ~= "string" then return false end
	local ok, kc = pcall(function() return Enum.KeyCode[v] end)
	return ok and kc ~= nil and kc ~= Enum.KeyCode.Unknown
end

-- invalid values fall back to the default; a key may only be bound once (later duplicates are cleared)
function Binds.dedupe()
	local seen, changed = {}, false
	for _, k in ipairs(Binds.keys) do
		local v = settings[k]
		if not Binds.valid(v) then v = DEFAULTS[k] settings[k] = v changed = true end
		if v ~= "None" then
			if seen[v] then settings[k] = "None" changed = true else seen[v] = true end
		end
	end
	return changed
end

----------------------------------------------------------------------
-- PERSISTENT CONFIG & CLEANUP
----------------------------------------------------------------------
local STORAGE_FOLDER = "AimAssistDebug"
local CONFIG_FILE = STORAGE_FOLDER .. "/config.json"
local CONFIG_VERSION = 1
local SAVE_DELAY = 1

local env = (type(getgenv) == "function" and getgenv()) or _G
if type(env.__AimAssistCleanup) == "function" then
	pcall(env.__AimAssistCleanup)
end

local hasFS = type(writefile) == "function" and type(readfile) == "function"
	and type(isfile) == "function" and type(isfolder) == "function"
	and type(makefolder) == "function"
local hasMouseMove = type(mousemoverel) == "function"
local pluginRef = (typeof(plugin) == "Instance") and plugin or nil

local function readConfig()
	local raw
	if hasFS then
		local okExists, exists = pcall(isfile, CONFIG_FILE)
		if okExists and exists then
			local ok, content = pcall(readfile, CONFIG_FILE)
			if ok then raw = content end
		end
	elseif pluginRef then
		local ok, content = pcall(function() return pluginRef:GetSetting(STORAGE_FOLDER) end)
		if ok then raw = content end
	end

	if type(raw) ~= "string" and type(env.__AimAssistSavedConfig) == "string" then
		raw = env.__AimAssistSavedConfig
	end

	if type(raw) ~= "string" then return nil end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(data) == "table" then return data end
	return nil
end

local function writeConfig(encoded)
	env.__AimAssistSavedConfig = encoded
	if hasFS then
		pcall(function()
			if not isfolder(STORAGE_FOLDER) then makefolder(STORAGE_FOLDER) end
		end)
		return (pcall(writefile, CONFIG_FILE, encoded))
	elseif pluginRef then
		return (pcall(function() pluginRef:SetSetting(STORAGE_FOLDER, encoded) end))
	end
	return true
end

local presets = {} -- named settings snapshots, stored in the same persistent config
local modelLock = {} -- viewmodel pose lock API (filled in by the VIEWMODEL LOCK block; the UI calls it)
local modelPoses = {} -- tool name -> 12 CFrame components (pose relative to the camera), per-tool viewmodel lock memory
local savedWindowPos
do
	local saved = readConfig()
	if saved and saved.version == CONFIG_VERSION then
		if type(saved.settings) == "table" then
			for k, default in pairs(DEFAULTS) do
				if type(saved.settings[k]) == type(default) then
					settings[k] = saved.settings[k]
				end
			end
			-- old configs only had NotifyLeft (bottom-left vs bottom-right)
			if type(saved.settings.NotifyPos) ~= "number" and saved.settings.NotifyLeft == true then
				settings.NotifyPos = 1
			end
			-- old configs had an "aim at torso" checkbox
			if type(saved.settings.AimBlend) ~= "number" and saved.settings.AimTorso == true then
				settings.AimBlend = 1
			end
		end
		if type(saved.presets) == "table" then
			for name, p in pairs(saved.presets) do
				if type(name) == "string" and type(p) == "table" then presets[name] = p end
			end
		end
		if type(saved.modelPoses) == "table" then
			for name, c in pairs(saved.modelPoses) do
				if type(name) == "string" and type(c) == "table" and #c == 12 then
					local good = true
					for i = 1, 12 do if type(c[i]) ~= "number" then good = false end end
					if good then modelPoses[name] = c end
				end
			end
		end
		local w = saved.window
		if type(w) == "table" and type(w.x) == "number" and type(w.y) == "number" then
			savedWindowPos = Vector2.new(w.x, w.y)
		end
	end
end

Binds.dedupe() -- validates binds loaded from an older/edited config

-- THEME
local ACCENT = Color3.fromRGB(94, 140, 255)
local GOOD = Color3.fromRGB(72, 214, 120) -- enabled toast status
local BAD = Color3.fromRGB(240, 84, 84)   -- disabled toast status
local TEXT = Color3.fromRGB(235, 238, 245)
local SUBTEXT = Color3.fromRGB(150, 156, 172)
local WHITE = Color3.new(1, 1, 1)
local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local WIDTH, HEADER_H, BUBBLE = 520, 38, 52

-- DEBUG TRACERS
local TRACER_DISTS = { 600, 1200, 2400 } -- selectable max tracer distance (studs)
local TRACER_SLOW = 0.12 -- seconds between validity/occlusion refreshes per tracer
local TRACER_MIN_OPACITY = 0.30
local TRACER_COLOR = Color3.fromRGB(120, 200, 255)
local TRACER_BLOCKED_COLOR = Color3.fromRGB(255, 190, 80) -- target behind a wall
local FOCUS_COLOR = Color3.fromRGB(255, 90, 70)
local BAR_W, BAR_H = 36, 4
local hideTracers

-- VISUAL DEBUG shared state: HSL helper, chams colours, Drawing availability. Functions are filled in further down.
local VD = {
	cols = { wall = Color3.new(1, 1, 1), vis = Color3.fromRGB(255, 0, 0), pred = Color3.fromRGB(255, 230, 80), box = Color3.new(1, 1, 1),
		boxBlocked = Color3.new(1, 1, 1), boxFocus = Color3.new(1, 1, 1) },
	hasDrawing = (type(Drawing) == "table" or type(Drawing) == "userdata") and type(Drawing.new) == "function",
}
function VD.hsl(h, s, l) -- h 0-360, s 0-100, l 0-100
	s, l = s / 100, l / 100
	local c = (1 - math.abs(2 * l - 1)) * s
	local hp = (h % 360) / 60
	local x = c * (1 - math.abs(hp % 2 - 1))
	local r, g, b
	if hp < 1 then r, g, b = c, x, 0
	elseif hp < 2 then r, g, b = x, c, 0
	elseif hp < 3 then r, g, b = 0, c, x
	elseif hp < 4 then r, g, b = 0, x, c
	elseif hp < 5 then r, g, b = x, 0, c
	else r, g, b = c, 0, x end
	local m = l - c / 2
	return Color3.new(r + m, g + m, b + m)
end

-- TOP LEVEL UI IMPLEMENTATION
local targetGuiParent = playerGui
pcall(function()
	local coreGui = game:GetService("CoreGui")
	-- a normal LocalScript can fetch CoreGui but cannot parent into it; probe with a throwaway instance
	local probe = Instance.new("Folder")
	probe.Parent = coreGui
	probe:Destroy()
	targetGuiParent = coreGui
end)

local old = targetGuiParent:FindFirstChild("AimAssistGui")
if old then old:Destroy() end

if targetGuiParent ~= playerGui then
	local oldP = playerGui:FindFirstChild("AimAssistGui")
	if oldP then oldP:Destroy() end
end

local alive = true
local heldRight, heldLeft = false, false
local heldBind = false -- momentary hold-to-aim key
local heldModelKey = false -- viewmodel pose-capture key is down
local bindAt = 0 -- when the hold-to-aim key was pressed (hold key keeps its hold-before-aim delay)
local listeningFor = nil -- setting key currently waiting for a keybind press
local rageOn, setRage = false, nil
local notify -- toggle notifications (defined after the HUD)
local fireClickExt -- scripted click, assigned next to fireClick; used by the click pre-delay
local pendLeft, pendRight = nil, nil -- pending delayed fire per button: nil or { target, at, done }
local rageStep, triggerStep
local Gate = {} -- true pre-fire click gate (filled in by the FIRE HELPERS block)
local releaseMouse
local wasAiming = false
local lockedTarget = nil
local connections = {}

local function track(conn)
	table.insert(connections, conn)
	return conn
end

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function tween(obj, time, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

----------------------------------------------------------------------
-- GUI ROOT + FOV CIRCLE
----------------------------------------------------------------------
local gui = new("ScreenGui", {
	Name = "AimAssistGui",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 2147483647,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, targetGuiParent)

local circle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(settings.FOV * 2, settings.FOV * 2),
	BackgroundTransparency = 1,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, circle)
new("UIStroke", { Thickness = 1.5, Color = WHITE, Transparency = 0.35 }, circle)

local tracerLayer = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	ZIndex = 0,
}, gui)

local hud = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(340, 24),
	BackgroundColor3 = Color3.fromRGB(10, 10, 14),
	BackgroundTransparency = 0.35,
	Text = "",
	Font = FONT_BOLD,
	TextSize = 13,
	TextColor3 = FOCUS_COLOR,
	Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, hud)

----------------------------------------------------------------------
-- TOGGLE NOTIFICATIONS
-- One entry per feature (repeat toggles update it in place), max 4 on screen, one shared Heartbeat step
-- (idle cost: a single table check). Bar and expiry come from timestamps, so there are no per-toast timers to go stale.
----------------------------------------------------------------------
do
	local NOTE_TIME, NOTE_FADE, NOTE_MAX = 3, 0.2, 4
	local NOTE_H = 26
	local box = new("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, gui)
	local boxLayout = new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 4),
	}, box)
	local notes, count, order = {}, 0, 0
	local placedAt = nil

	-- 1 = bottom-left, 2 = bottom-right, 3 = center (30 px below the middle of the screen; stack grows downward)
	local function place()
		local pos = settings.NotifyPos
		if pos ~= 1 and pos ~= 3 then pos = 2 end
		if pos == placedAt then return end
		placedAt = pos
		if pos == 3 then
			box.AnchorPoint = Vector2.new(0.5, 0)
			box.Position = UDim2.new(0.5, 0, 0.5, 30)
			boxLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			boxLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		else
			local left = pos == 1
			box.AnchorPoint = Vector2.new(left and 0 or 1, 1)
			box.Position = UDim2.new(left and 0 or 1, left and 14 or -14, 1, -14)
			boxLayout.HorizontalAlignment = left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
			boxLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		end
	end

	local function hex(c)
		return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local GOOD_HEX, BAD_HEX = hex(GOOD), hex(BAD)

	-- slot keeps a fixed layout cell so the pop-in scale never shifts neighbouring toasts
	local function build()
		local slot = new("Frame", {
			Size = UDim2.new(1, 0, 0, NOTE_H),
			BackgroundTransparency = 1,
		}, box)
		local g = new("CanvasGroup", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(16, 18, 26),
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			GroupTransparency = 1,
		}, slot)
		local scale = new("UIScale", { Scale = 0.92 }, g)
		new("UICorner", { CornerRadius = UDim.new(0, 4) }, g)
		new("UIStroke", { Color = WHITE, Transparency = 0.8, Thickness = 1 }, g)
		local label = new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -16, 1, -3),
			Font = FONT,
			TextSize = 12,
			TextColor3 = TEXT,
			RichText = true,
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, g)
		local bar = new("Frame", { -- always the theme blue, independent of the status colour
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = ACCENT,
			BorderSizePixel = 0,
		}, g)
		return { slot = slot, g = g, scale = scale, label = label, bar = bar }
	end

	local function stop(n)
		if n.fade then n.fade:Cancel() n.fade = nil end
		if n.pop then n.pop:Cancel() n.pop = nil end
		if n.drain then n.drain:Cancel() n.drain = nil end
	end

	notify = function(id, name, on, bindKey)
		if not settings.Notify then return end
		place()

		local n = notes[id]
		if not n then
			if count >= NOTE_MAX then -- drop the oldest instead of stacking without limit
				local oldId, oldOrder = nil, math.huge
				for k, v in pairs(notes) do
					if v.order < oldOrder then oldId, oldOrder = k, v.order end
				end
				if oldId then
					stop(notes[oldId])
					notes[oldId].slot:Destroy()
					notes[oldId] = nil
					count -= 1
				end
			end
			n = build()
			notes[id] = n
			count += 1
		end

		order += 1
		n.order = order
		n.slot.LayoutOrder = order -- newest sits lowest

		local bind = ""
		if type(bindKey) == "string" and bindKey ~= "" and bindKey ~= "None" then
			bind = " (" .. (bindKey == "MouseButton3" and "MMB" or bindKey) .. ")"
		end
		n.label.Text = string.format('<font color="%s"><b>%s</b></font> — %s%s', on and GOOD_HEX or BAD_HEX, on and "Enabled" or "Disabled", name, bind)

		-- (re)start: cancel anything still running so a repeat toggle never overlaps old animations,
		-- then fade/pop in and drain the bar with a single linear tween (no per-frame bar updates)
		stop(n)
		n.start, n.dying = os.clock(), false
		n.scale.Scale = 0.92
		n.bar.Size = UDim2.new(1, 0, 0, 2)
		n.fade = tween(n.g, 0.15, { GroupTransparency = 0 })
		n.pop = tween(n.scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
		n.drain = tween(n.bar, NOTE_TIME, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
	end

	-- one shared step: only handles expiry (idle cost: a single table check)
	track(RunService.Heartbeat:Connect(function()
		if next(notes) == nil then return end
		local now = os.clock()
		for id, n in pairs(notes) do
			if n.dying then
				if now >= n.dieAt then
					stop(n)
					n.slot:Destroy()
					notes[id] = nil
					count -= 1
				end
			elseif now - n.start >= NOTE_TIME then
				n.dying, n.dieAt = true, now + NOTE_FADE
				if n.fade then n.fade:Cancel() end
				n.fade = tween(n.g, NOTE_FADE, { GroupTransparency = 1 })
			end
		end
	end))
end

local function refreshCircle()
	circle.Visible = settings.Enabled and settings.ShowCircle
end

----------------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------------
local startPos = savedWindowPos or Vector2.new(40, 90)
do
	local vpNow = camera.ViewportSize
	if vpNow.X > 200 then
		startPos = Vector2.new(
			math.clamp(startPos.X, 0, math.max(0, vpNow.X - 80)),
			math.clamp(startPos.Y, 0, math.max(0, vpNow.Y - 80))
		)
	end
end

local window = new("Frame", {
	Name = "Window",
	Position = UDim2.fromOffset(startPos.X, startPos.Y),
	Size = UDim2.fromOffset(WIDTH, 420),
	BackgroundColor3 = Color3.fromRGB(16, 18, 26),
	BackgroundTransparency = 0.08,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
local windowCorner = new("UICorner", { CornerRadius = UDim.new(0, 8) }, window)
new("UIStroke", { Color = WHITE, Transparency = 0.72, Thickness = 1 }, window)
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(34, 38, 54), Color3.fromRGB(14, 16, 24)),
}, window)

local content = new("CanvasGroup", {
	BackgroundTransparency = 1,
	GroupTransparency = 0,
	Size = UDim2.fromScale(1, 1),
}, window)

local header = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, HEADER_H),
}, content)

local dragArea = new("Frame", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
}, header)

new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 0),
	Size = UDim2.new(1, -100, 1, 0),
	Text = "Workwell Aimbot",
	Font = FONT_BOLD,
	TextSize = 15,
	TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.92,
	BorderSizePixel = 0,
}, header)

local function headerButton(text, xOffset, hoverColor)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.92,
		Text = text,
		Font = FONT_BOLD,
		TextSize = 16,
		TextColor3 = TEXT,
		AutoButtonColor = false,
	}, header)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
	track(b.MouseEnter:Connect(function()
		tween(b, 0.12, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.5 })
	end))
	track(b.MouseLeave:Connect(function()
		tween(b, 0.12, { BackgroundColor3 = WHITE, BackgroundTransparency = 0.92 })
	end))
	return b
end

local minBtn = headerButton("–", -46, ACCENT)
local closeBtn = headerButton("×", -12, Color3.fromRGB(235, 80, 80))

-- left nav column is 118 wide (top tabs + their categories)
local body = new("ScrollingFrame", {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(118 + 14, HEADER_H),
	Size = UDim2.new(1, -(118 + 14), 1, -HEADER_H),
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = WHITE,
	ScrollBarImageTransparency = 0.6,
}, content)

new("UIPadding", {
	PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 12),
	PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12),
}, body)

-- left navigation: the top tabs (MAIN / ANTI-RECOIL / PRESETS) stacked vertically, the active one lists its categories
local nav = new("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, HEADER_H + 6),
	Size = UDim2.new(0, 118, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
}, content)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, nav)

local layout = new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, body)

local order = 0
local function nextOrder()
	order += 1
	return order
end

-- every page has two columns (or one); every section is a collapsible dropdown, "advanced" ones nest inside their section
local custom = { names = { head = {}, torso = {} } } -- CUSTOM PARTS logic (apply/find), filled in after the target registry exists
local colL, colR -- content area / sidebar of the page being built (makePage returns them)
local cur, sectionBox -- `cur` is where the next control is parented

local function dropdown(text, parent, open, nested)
	local h = nested and 20 or 24
	local wrap = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
	local head = new("TextButton", {
		Size = UDim2.new(1, 0, 0, h),
		BackgroundColor3 = nested and WHITE or ACCENT,
		BackgroundTransparency = nested and 0.94 or 0.8,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = 0,
	}, wrap)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, head)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Text = text,
		Font = FONT_BOLD,
		TextSize = nested and 10 or 11,
		TextColor3 = nested and SUBTEXT or TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, head)
	local arrow = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.fromOffset(12, h),
		Text = open and "-" or "+",
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = SUBTEXT,
	}, head)
	local box = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Visible = open,
	}, wrap)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	if nested then new("UIPadding", { PaddingLeft = UDim.new(0, 5) }, box) end
	track(head.MouseButton1Click:Connect(function()
		box.Visible = not box.Visible
		arrow.Text = box.Visible and "-" or "+"
	end))
	return box
end

-- sections are sidebar categories: each owns a panel in the page's content area, the sidebar button shows it
local pageRecs = {} -- last entry = page being built: { name, tab, subs, cats, content }
local selectCat -- assigned once showTab exists
local function section(text)
	local rec = pageRecs[#pageRecs]
	local idx = #rec.cats + 1
	local panel = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
	}, rec.content)
	new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = ACCENT,
		BackgroundTransparency = 1,
		Text = text,
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = nextOrder(),
	}, rec.subs)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 4) }, b)
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -8, 0.5, 0),
		Size = UDim2.fromOffset(3, 14),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
		Visible = false,
	}, b)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	track(b.MouseEnter:Connect(function()
		if rec.active ~= idx then tween(b, 0.1, { BackgroundTransparency = 0.88 }) end
	end))
	track(b.MouseLeave:Connect(function()
		if rec.active ~= idx then tween(b, 0.1, { BackgroundTransparency = 1 }) end
	end))
	track(b.MouseButton1Click:Connect(function() selectCat(rec, idx, true) end))
	rec.cats[idx] = { btn = b, panel = panel, bar = bar }
	sectionBox = panel
	cur = panel
	if idx == 1 then selectCat(rec, 1) end
end
local function advanced(text, open)
	cur = dropdown(text, sectionBox, open == true, true)
end

----------------------------------------------------------------------
-- SAVE & CONTROLS
----------------------------------------------------------------------
local ready = false
local dirty = false
local saveToken = 0
local lastSaved

local function flushSave()
	if not (ready and dirty) then return end
	dirty = false
	local snap = { version = CONFIG_VERSION, settings = {}, presets = presets, modelPoses = modelPoses, window = {
		x = window.Position.X.Offset,
		y = window.Position.Y.Offset,
	} }
	for k in pairs(DEFAULTS) do snap.settings[k] = settings[k] end

	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, snap)
	if ok and encoded ~= lastSaved then
		if writeConfig(encoded) then
			lastSaved = encoded
		end
	end
end

local function requestSave()
	if not ready then return end
	dirty = true
	saveToken += 1
	local mine = saveToken
	task.delay(SAVE_DELAY, function()
		if alive and mine == saveToken then flushSave() end
	end)
end

local setters = {}

local function checkbox(text, key, onChange, bindKey)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.9,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	}, cur)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, bindKey and -92 or -30, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Font = FONT,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(15, 15),
		BackgroundColor3 = ACCENT,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, row)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, box)
	local boxStroke = new("UIStroke", { Color = WHITE, Transparency = 0.6, Thickness = 1.5 }, box)
	local dot = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, dot)

	local function render(animate)
		local on = settings[key]
		local t = animate and 0.15 or 0
		tween(box, t, { BackgroundTransparency = on and 0 or 1 })
		tween(boxStroke, t, { Transparency = on and 1 or 0.6 })
		tween(dot, t, { Size = on and UDim2.fromOffset(7, 7) or UDim2.fromOffset(0, 0) })
	end

	local function set(value, animate)
		settings[key] = value
		render(animate)
		if onChange then onChange(value) end
		requestSave()
	end

	track(row.MouseButton1Click:Connect(function() set(not settings[key], true) end))
	track(row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundTransparency = 0.84 }) end))
	track(row.MouseLeave:Connect(function() tween(row, 0.12, { BackgroundTransparency = 0.9 }) end))

	if bindKey then Binds.chip(row, bindKey, 56).Position = UDim2.new(1, -28, 0.5, 0) end

	render(false)
	setters[key] = set
end

local function slider(text, key, min, max, step, fmt, onChange)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.9,
		LayoutOrder = nextOrder(),
	}, cur)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 4),
		Size = UDim2.new(0.62, 0, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = text,
		Font = FONT,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local valueLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 4),
		Size = UDim2.new(0.4, 0, 0, 16),
		Text = "",
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)

	local bar = new("Frame", {
		Position = UDim2.new(0, 8, 0, 27),
		Size = UDim2.new(1, -16, 0, 4),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
	}, row)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = ACCENT,
		BorderSizePixel = 0,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, bar)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local hit = new("TextButton", {
		Position = UDim2.new(0, 4, 0, 19),
		Size = UDim2.new(1, -8, 0, 19),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
	}, row)

	local function setValue(v)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		settings[key] = v
		local a = (v - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		valueLabel.Text = fmt(v)
		if onChange then onChange(v) end
		requestSave()
	end

	local dragging = false
	local function fromInput(input)
		local a = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(min + (max - min) * a)
	end

	track(hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			fromInput(input)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromInput(input)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	setValue(settings[key])
	setters[key] = setValue
end

local bindRenders = {}
local function refreshBinds()
	for _, r in pairs(bindRenders) do r() end
end

function Binds.label(v)
	if v == "MouseButton3" then return "MMB" end
	if type(v) ~= "string" or v == "None" then return "None" end
	return (v:gsub("^Right", "R"):gsub("^Left", "L"))
end

-- click a chip to enter binding mode (or click again to leave it); releases any focused TextBox so keys reach us
function Binds.listen(key)
	local f = UserInputService:GetFocusedTextBox()
	if f then f:ReleaseFocus() end
	listeningFor = (listeningFor ~= key) and key or nil
	refreshBinds()
end

-- bind `name` to `key`; the same key can only drive one action, so any other action using it is cleared
function Binds.assign(key, name)
	if name ~= "None" then
		for _, other in ipairs(Binds.keys) do
			if other ~= key and settings[other] == name then
				local s = setters[other]
				if s then s("None") else settings[other] = "None" end
			end
		end
	end
	local s = setters[key]
	if s then s(name) else settings[key] = name end
end

-- the one keybind box used everywhere (beside toggles and in the BINDS section)
function Binds.chip(parent, key, w)
	local chip = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(w, 16),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.88,
		AutoButtonColor = false,
		Text = "",
		Font = FONT_BOLD,
		TextSize = 10,
		TextColor3 = ACCENT,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, chip)

	local function render()
		local v = settings[key]
		if listeningFor == key then
			chip.Text, chip.TextColor3 = "press key...", TEXT
		else
			chip.Text, chip.TextColor3 = Binds.label(v), (v == "None") and SUBTEXT or ACCENT
		end
	end
	track(chip.MouseButton1Click:Connect(function() Binds.listen(key) end))

	bindRenders[key] = render
	setters[key] = function(value)
		settings[key] = value
		render()
		requestSave()
	end
	render()
	return chip
end

local function keybind(text, key)
	local row = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.9,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = nextOrder(),
	}, cur)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Text = text,
		Font = FONT,
		TextSize = 12,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	Binds.chip(row, key, 78).Position = UDim2.new(1, -8, 0.5, 0)

	track(row.MouseButton1Click:Connect(function() Binds.listen(key) end))
	track(row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundTransparency = 0.84 }) end))
	track(row.MouseLeave:Connect(function() tween(row, 0.12, { BackgroundTransparency = 0.9 }) end))
end

do -- UI build: its helpers/locals are released afterwards (keeps the main chunk under the 200-local limit)
local function getViewportWidth()
	for _ = 1, 30 do
		if camera.ViewportSize.X > 200 then break end
		task.wait(0.05)
	end
	return camera.ViewportSize.X
end
local maxFov = math.max(400, math.floor(getViewportWidth() / 2 / 5) * 5)
local function pct(v) return math.floor(v * 100 + 0.5) .. "%" end
local function fmtSec(v) return string.format("%.2fs", v) end
local function studs(v) return v .. " studs" end
local function px(v) return v .. " px" end
local function ms(v) return v .. " ms" end
local NOTIFY_POS_NAMES = { "Bottom-left", "Bottom-right", "Center" }

-- tabs: each page is built once; switching only toggles Visible
local pages = {}
local function showTab(name)
	for k, p in pairs(pages) do p.Visible = (k == name) end
	for _, r in ipairs(pageRecs) do
		local on = (r.name == name)
		r.tab.BackgroundColor3 = on and ACCENT or WHITE
		r.tab.BackgroundTransparency = on and 0.55 or 0.92
		r.tab.TextColor3 = on and TEXT or SUBTEXT
		r.subs.Visible = (on or r.name == "main") and #r.cats > 1 -- MAIN stays open
	end
	if listeningFor then listeningFor = nil refreshBinds() end -- a hidden chip must not keep capturing
end
selectCat = function(rec, i, show)
	if show and not rec.content.Visible then showTab(rec.name) end
	rec.active = i
	for k, c in ipairs(rec.cats) do
		local on = (k == i)
		c.panel.Visible = on
		c.bar.Visible = on
		c.btn.BackgroundTransparency = on and 0.8 or 1
		c.btn.TextColor3 = on and TEXT or SUBTEXT
	end
	if listeningFor then listeningFor = nil refreshBinds() end -- a hidden chip must not keep capturing
end
-- every page = one nav group (tab button + category buttons) + a content area holding one panel per category
local function makePage(name, label)
	local page = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
		Visible = false,
	}, body)
	local group = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
	}, nav)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, group)
	local tab = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.92,
		Text = label,
		Font = FONT_BOLD,
		TextSize = 12,
		TextColor3 = SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = 0,
	}, group)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, tab)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, tab)
	local subs = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Visible = false,
	}, group)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, subs)
	new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, subs)
	track(tab.MouseButton1Click:Connect(function() showTab(name) end))
	pages[name] = page
	pageRecs[#pageRecs + 1] = { name = name, tab = tab, subs = subs, cats = {}, content = page, active = 1 }
	return page, nav
end

local function btn(text, parent, w, fn)
	local b = new("TextButton", {
		Size = w,
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.86,
		Text = text,
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = TEXT,
		AutoButtonColor = false,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	track(b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundTransparency = 0.78 }) end))
	track(b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundTransparency = 0.86 }) end))
	track(b.MouseButton1Click:Connect(fn))
	return b
end
local function row(items)
	local r = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = nextOrder() }, cur)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, r)
	local n = #items
	for i, it in ipairs(items) do
		local b = btn(it[1], r, UDim2.new(1 / n, -3 * (n - 1) / n, 1, 0), it[2])
		b.LayoutOrder = i
	end
end

------------------------------ MAIN TAB ---------------------------------
colL, colR = makePage("main", "MAIN")
section("GENERAL")
checkbox("Aim assist", "Enabled", refreshCircle, "ToggleKey")
checkbox("Require tool equipped", "RequireTool")
checkbox("Show FOV circle", "ShowCircle", refreshCircle)
checkbox("Wall check", "WallCheck")
checkbox("Prefer targets not behind a wall", "PreferVisible")
checkbox("Team check", "TeamCheck")
checkbox("Right click aims", "RightClick")
checkbox("Left click aims", "LeftClick")
checkbox("Always active (auto lock)", "AlwaysAim", nil, "AlwaysKey")
slider("Aim point (head to torso)", "AimBlend", 0, 1, 0.05, function(v)
	if v <= 0 then return "Head" elseif v >= 1 then return "Torso" end
	return pct(v) .. " torso"
end)
checkbox("Ballistic prediction (muzzle velocity)", "MuzzleOn")
slider("Muzzle velocity", "MuzzleVelocity", 500, 6500, 50, function(v) return v .. " studs/s" end)
slider("Gravity override (0 = game gravity)", "ProjGravity", 0, 400, 1, function(v)
	return v <= 0 and string.format("Game (%.0f)", workspace.Gravity) or (v .. " studs/s2")
end)
slider("Prediction time (extra)", "AimLead", 0, 1, 0.01, fmtSec)
checkbox("Lock on cursor (3rd person)", "LockCursor")
checkbox(hasMouseMove and "Sync real mouse" or "Sync real mouse (n/a)", "SyncMouse")
advanced("ADVANCED - WALL DETECTION")
slider("Ignore wall depth", "WallIgnoreDepth", 0, 3, 0.1, function(v)
	return v <= 0 and "Off" or string.format("%.1f studs", v)
end)
checkbox("Priority: clear, then walls near to far", "PreferClosestBehind")
advanced("ADVANCED - AIM TIMING")
slider("Left pre-fire delay", "LeftDelay", 0, 0.3, 0.05, fmtSec)
slider("Right pre-fire delay", "RightDelay", 0, 0.3, 0.05, fmtSec)
slider("Keep target delay", "KeepDelay", 0, 500, 10, ms)
slider("Min target distance", "MinDistance", 0, 10, 0.5, studs)
slider("Release hold (camera settle)", "ReleaseHoldMs", 0, 400, 10, ms)
advanced("ADVANCED - NOTIFICATIONS")
checkbox("Toggle notifications", "Notify")
slider("Notification position", "NotifyPos", 1, 3, 1, function(v) return NOTIFY_POS_NAMES[v] or "Bottom-right" end)

section("TUNING")
slider("FOV radius", "FOV", 30, maxFov, 5, px, function(v)
	circle.Size = UDim2.fromOffset(v * 2, v * 2)
end)
slider("Lock strength (far)", "Strength", 0.05, 1, 0.05, pct)
slider("Close-range boost", "Boost", 0, 1, 0.05, pct)
slider("Boost range", "BoostRange", 20, 250, 5, px)
slider("Left-only stability", "LeftStability", 0.5, 0.8, 0.05, pct)
slider("Hard-lock zone", "HardLockDeg", 0, 10, 0.5, function(v)
	return v <= 0 and "Off" or string.format("%.1f deg", v)
end)
slider("6 o'clock exclusion", "BottomDeg", 0, 45, 1, function(v)
	return v <= 0 and "Off" or (v .. " deg each side")
end)
advanced("ADVANCED - CAMERA FILTER (ADS lag)")
slider("Game camera filter let through", "FilterPass", 0, 100, 5, function(v) return v .. "%" end)
slider("Lock speed multiplier", "LockSpeed", 1, 5, 0.1, function(v) return string.format("%.1fx", v) end)
checkbox("Camera diagnostics (log)", "CamDiag", function(on)
	if on and VD.sens then VD.sens.diagSources() end
end)

section("VISUAL DEBUG")
do
	-- HSL colour group: a live preview swatch plus Hue / Saturation / Lightness sliders. `apply(color)` is called
	-- on every change (and once at build) to push the colour to wherever it is used.
	local function colorGroup(title, prefix, apply)
		local r = new("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			LayoutOrder = nextOrder(),
		}, cur)
		new("UICorner", { CornerRadius = UDim.new(0, 4) }, r)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 0),
			Size = UDim2.new(1, -70, 1, 0),
			Text = title,
			Font = FONT_BOLD,
			TextSize = 11,
			TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, r)
		local swatch = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(48, 14),
			BorderSizePixel = 0,
		}, r)
		new("UICorner", { CornerRadius = UDim.new(0, 3) }, swatch)
		new("UIStroke", { Color = WHITE, Transparency = 0.6, Thickness = 1 }, swatch)
		local function refresh()
			local c = VD.hsl(settings[prefix .. "H"], settings[prefix .. "S"], settings[prefix .. "L"])
			swatch.BackgroundColor3 = c
			apply(c)
		end
		slider("Hue", prefix .. "H", 0, 360, 1, function(v) return v .. " deg" end, refresh)
		slider("Saturation", prefix .. "S", 0, 100, 1, function(v) return v .. "%" end, refresh)
		slider("Lightness", prefix .. "L", 0, 100, 1, function(v) return v .. "%" end, refresh)
		refresh()
	end
	local function percent(v) return v .. "%" end

	checkbox("Debug tracers", "Tracers", function(on)
		if not on and hideTracers then hideTracers() end
	end)
	slider("Max distance", "TracerDist", 1, 3, 1, function(v) return studs(TRACER_DISTS[v] or 1200) end)
	slider("Tracer thickness", "TracerThick", 1, 3, 1, function(v) return v .. " px" end)
	slider(VD.hasDrawing and "Tracer visual" or "Tracer visual (sharp n/a)", "TracerStyle", 1, 2, 1, function(v)
		return v == 2 and "Sharp (pixel)" or "Anti-aliased"
	end)
	slider("Tracer end", "TracerEnd", 1, 2, 1, function(v) return v == 2 and "Body" or "Head" end)

	advanced("TRACER COLORS")
	colorGroup("Normal tracer", "Tracer", function(c) TRACER_COLOR = c end)
	colorGroup("Behind a wall", "Blocked", function(c) TRACER_BLOCKED_COLOR = c end)
	colorGroup("Focused / locked target", "Focus", function(c)
		FOCUS_COLOR = c
		hud.TextColor3 = c
	end)

	advanced("PREDICTION MARKER")
	checkbox("Show predicted landing", "PredMarker")
	colorGroup("Marker color", "Pred", function(c) VD.cols.pred = c end)

	advanced("BOXES")
	checkbox("Character boxes", "Box", function(on)
		if not on then
			for _, t in pairs(tracers) do if t.boxVis then t.box.Visible = false t.boxVis = false end end
		end
	end)
	slider("Box thickness", "BoxThick", 1, 3, 1, function(v) return v .. " px" end)
	slider("Box padding", "BoxPad", 0, 50, 1, function(v) return v .. "%" end)
	colorGroup("Box: normal", "Box", function(c) VD.cols.box = c end)
	colorGroup("Box: behind a wall", "BoxBlocked", function(c) VD.cols.boxBlocked = c end)
	colorGroup("Box: focused target", "BoxFocus", function(c) VD.cols.boxFocus = c end)

	advanced("HEALTH BARS")
	checkbox("Health bars", "HealthBar")
	slider("Health bar size", "HealthBarSize", 50, 300, 10, percent)
	checkbox("Size follows distance", "HealthBarDist")

	advanced("CHAMS")
	checkbox("Chams", "Chams", function(on)
		if not on and VD.clearChams then VD.clearChams() end
	end)
	checkbox("Behind-wall (white) chams", "ChamWall", function(on)
		if not on and VD.clearWhite then VD.clearWhite() end
	end)
	slider("White chams max distance", "ChamWallDist", 50, 2000, 50, function(v) return v .. " studs" end)
	slider("Behind-wall layer", "ChamMode", 1, 2, 1, function(v)
		return v == 2 and "Screen overlay" or "World copy"
	end)
	slider("Chams update rate", "ChamRate", 1, 3, 1, function(v)
		return v == 1 and "30 fps" or (v == 2 and "60 fps" or "Every frame")
	end)
	colorGroup("Behind walls (ForceField copy)", "ChamWall", function(c) VD.cols.wall = c end)
	slider("Behind walls: fill opacity", "ChamWallFill", 0, 100, 5, percent)
	slider("Behind walls: outline opacity", "ChamWallOutline", 0, 100, 5, percent)
	colorGroup("In view (over the character)", "ChamVis", function(c) VD.cols.vis = c end)
	slider("In view: fill opacity", "ChamVisFill", 0, 100, 5, percent)
	slider("In view: outline opacity", "ChamVisOutline", 0, 100, 5, percent)
end

section("TARGET SCOPE")
do
	local rebuild
	local uiRows = {}

	local function selectedSet()
		local t = {}
		if settings.ScopeAuto then -- effective selection while auto is on
			for _, c in ipairs(Scope.active()) do t[c.Name] = true end
			return t
		end
		for n in string.gmatch(settings.ScopeSel, "[^\n]+") do t[n] = true end
		return t
	end
	local function store(set)
		local names = {}
		for n in pairs(set) do names[#names + 1] = n end
		table.sort(names)
		settings.ScopeSel = table.concat(names, "\n")
		Scope.invalidate()
		requestSave()
	end

	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = "Auto-detects everything under workspace.Players (refreshes every 2s). Tick the ones to detect / lock onto. None ticked = all.",
		Font = FONT,
		TextSize = 10,
		TextColor3 = SUBTEXT,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, cur)
	local status = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "",
		Font = FONT_BOLD,
		TextSize = 10,
		TextColor3 = ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
	}, cur)
	checkbox("Auto: every folder without me", "ScopeAuto", function()
		Scope.invalidate()
		if rebuild then rebuild() end
	end)
	slider("Auto method", "ScopeMethod", 1, 2, 1, function(v)
		return v == 2 and "Nearest head to camera" or "Character / name"
	end, function()
		Scope.invalidate()
		if rebuild then rebuild() end
	end)
	slider("Nearest-head radius", "ScopeNearStuds", 1, 15, 0.5, studs)
	row({
		{ "Detect my team now (nearest head)", function()
			local mine, d = Scope.scanNearest()
			if not mine then
				rebuild()
				status.Text = string.format("No head within %.1f studs of the camera", settings.ScopeNearStuds)
				return
			end
			Scope.mine = mine
			local box, set = Scope.container(), {}
			for _, c in ipairs(box:GetChildren()) do
				if c ~= mine then set[c.Name] = true end
			end
			if settings.ScopeAuto and setters.ScopeAuto then setters.ScopeAuto(false) end -- one-shot: manual selection
			store(set)
			rebuild()
			status.Text = string.format("Mine: %s (head %.1f studs away); the rest ticked", mine.Name, d)
		end },
	})
	row({
		{ "Refresh", function() rebuild() end },
		{ "Select all", function()
			local box, set = Scope.container(), {}
			if box then for _, c in ipairs(box:GetChildren()) do set[c.Name] = true end end
			if settings.ScopeAuto and setters.ScopeAuto then setters.ScopeAuto(false) end -- manual takes over
			store(set)
			rebuild()
		end },
		{ "Clear", function()
			if settings.ScopeAuto and setters.ScopeAuto then setters.ScopeAuto(false) end
			store({})
			rebuild()
		end },
	})
	local listBox = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder(),
	}, cur)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, listBox)

	rebuild = function()
		for _, r in ipairs(uiRows) do r:Destroy() end
		table.clear(uiRows)
		local box = Scope.container()
		if not box then
			status.Text = "workspace.Players not found"
			return
		end
		local kids = box:GetChildren()
		table.sort(kids, function(a, b) return a.Name < b.Name end)
		local sel = selectedSet()
		local ticked = 0
		for i, c in ipairs(kids) do
			local name = c.Name
			if sel[name] then ticked += 1 end
			local r = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = WHITE,
				BackgroundTransparency = 0.9,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
			}, listBox)
			new("UICorner", { CornerRadius = UDim.new(0, 4) }, r)
			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Text = string.format("%s  (%s, %d)", name, c.ClassName, #c:GetChildren()),
				Font = FONT,
				TextSize = 11,
				TextColor3 = TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, r)
			local on = sel[name] == true
			local boxUI = new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(15, 15),
				BackgroundColor3 = ACCENT,
				BackgroundTransparency = on and 0 or 1,
				BorderSizePixel = 0,
			}, r)
			new("UICorner", { CornerRadius = UDim.new(0, 3) }, boxUI)
			new("UIStroke", { Color = WHITE, Transparency = on and 1 or 0.6, Thickness = 1.5 }, boxUI)
			-- not tracked: the row is destroyed (with its connection) on every rebuild
			r.MouseButton1Click:Connect(function()
				local s = selectedSet() -- in auto mode this is the auto selection: clicking edits a copy and switches auto off
				if settings.ScopeAuto and setters.ScopeAuto then setters.ScopeAuto(false) end
				if s[name] then s[name] = nil else s[name] = true end
				store(s)
				rebuild()
			end)
			uiRows[#uiRows + 1] = r
		end
		status.Text = string.format("%d found, %d ticked%s%s", #kids, ticked, ticked == 0 and " (all allowed)" or "", settings.ScopeAuto and " [auto]" or "")
	end

	setters.ScopeSel = function(v)
		settings.ScopeSel = type(v) == "string" and v or ""
		Scope.invalidate()
		rebuild()
		requestSave()
	end

	-- auto-detect: re-scan every 2s, rebuild only when the set of entries (or their child counts) changed
	task.spawn(function()
		local last
		while alive do
			-- realtime method 2: follows team swaps (nothing found = keep the last result, e.g. while respawning)
			if settings.ScopeAuto and settings.ScopeMethod == 2 then
				local m = Scope.scanNearest()
				if m and m ~= Scope.mine then
					Scope.mine = m
					Scope.invalidate()
				end
			end
			local box = Scope.container()
			local sig = "none"
			if box then
				local p = {}
				for _, c in ipairs(box:GetChildren()) do p[#p + 1] = c.Name .. ":" .. #c:GetChildren() .. (settings.ScopeAuto and (Scope.isMine(c) and "m" or "o") or "") end
				table.sort(p)
				sig = table.concat(p, "|")
			end
			if sig ~= last then
				last = sig
				rebuild()
			end
			task.wait((settings.ScopeAuto and settings.ScopeMethod == 2) and 1 or 2)
		end
	end)
end

------------------------------ RIGHT COLUMN -----------------------------
section("BINDS")
new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 26),
	Text = "Click a chip, press a key. Esc cancels, Backspace clears.",
	Font = FONT,
	TextSize = 10,
	TextColor3 = SUBTEXT,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, cur)
keybind("Hold to aim (momentary)", "HoldKey")
keybind("Show / hide panel", "PanelKey")

section("TRIGGER BOT")
checkbox("Trigger bot", "TriggerBot", nil, "TriggerKey")
checkbox("Through walls", "TriggerWalls")
checkbox("Only while aimbot is locked", "TriggerNeedsAim")
checkbox("Hold fire: teammate in front", "TriggerTeamBlock")
advanced("ADVANCED - TRIGGER")
checkbox("Auto-click over game UI", "ClickGameUI")
slider("Pre-delay", "TriggerDelay", 0, 0.3, 0.01, fmtSec)
slider("Fire interval", "FireRate", 0.03, 0.5, 0.01, fmtSec)
slider("Max wall depth", "TriggerWallDepth", 0, 1, 0.1, studs)
slider("Asset distance from player", "TriggerAssetDist", 0, 2, 0.25, studs)
slider("Asset depth (see through)", "TriggerAssetDepth", 0, 4, 0.25, studs)
slider("Proximity radius (walls)", "TriggerRadius", 2, 60, 1, px)

section("DEV RAGE MODE")
checkbox("RAGE MODE", "RageActive", function(on)
	if setRage then setRage(on) end
end, "RageKey")
checkbox("Spin bot", "RageSpin")
checkbox("Auto jump", "RageAutoJump")
checkbox("Third person", "RageThirdPerson", function()
	if setRage and rageOn then setRage(true, true) end
end)
checkbox("Auto fire (no click)", "RageAutoFire")
checkbox("Aim through walls", "RageWalls")
checkbox("Mouse look (locks cursor)", "RageMouseLook")
advanced("ADVANCED - RAGE")
slider("Pre-delay before fire", "RageDelay", 0, 0.3, 0.05, fmtSec)
slider("Spin speed", "SpinSpeed", 200, 3600, 50, function(v) return v .. " deg/s" end)
checkbox("Zoom lock loop (override game)", "ForcePerspective")
slider("Camera distance", "RageZoom", 6, 40, 1, studs, function()
	if setRage and rageOn then setRage(true, true) end
end)
slider("Target lead", "RageLead", 0, 0.3, 0.01, fmtSec)

do
-- single-line text setting (applies when the box loses focus)
	local function textRow(text, key, placeholder)
		local row = new("Frame", {
			Size = UDim2.new(1, 0, 0, 42),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			LayoutOrder = nextOrder(),
		}, cur)
		new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 3),
			Size = UDim2.new(1, -16, 0, 14),
			Text = text,
			Font = FONT,
			TextSize = 11,
			TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local box = new("TextBox", {
			Position = UDim2.fromOffset(6, 19),
			Size = UDim2.new(1, -12, 0, 19),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Text = settings[key] or "",
			PlaceholderText = placeholder,
			PlaceholderColor3 = SUBTEXT,
			TextColor3 = TEXT,
			Font = FONT,
			TextSize = 11,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		new("UICorner", { CornerRadius = UDim.new(0, 3) }, box)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, box)
		local function set(value)
			value = type(value) == "string" and value or ""
			settings[key] = value
			box.Text = value
			custom.apply()
			requestSave()
		end
		track(box.FocusLost:Connect(function() set(box.Text) end))
		setters[key] = set
	end
	

section("CUSTOM PARTS")
new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 40),
	Text = "Names are children of the character. Separate with commas; use A.B for a nested part. Press Enter / click away to apply.",
	Font = FONT,
	TextSize = 10,
	TextColor3 = SUBTEXT,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
}, cur)
textRow("Head part names", "CustomHeadNames", "Top")
textRow("Torso part names", "CustomTorsoNames", "Center")
textRow("Target models folder (workspace path)", "CustomTargetFolder", "Characters")
end

cur = colR
local resetBtn = new("TextButton", {
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.9,
	Text = "Reset settings",
	Font = FONT,
	TextSize = 11,
	TextColor3 = SUBTEXT,
	AutoButtonColor = false,
	LayoutOrder = 1000000,
}, colR)
new("UICorner", { CornerRadius = UDim.new(0, 4) }, resetBtn)
track(resetBtn.MouseEnter:Connect(function() tween(resetBtn, 0.12, { BackgroundTransparency = 0.84 }) end))
track(resetBtn.MouseLeave:Connect(function() tween(resetBtn, 0.12, { BackgroundTransparency = 0.9 }) end))
track(resetBtn.MouseButton1Click:Connect(function()
	for key, default in pairs(DEFAULTS) do
		local setter = setters[key]
		if setter then setter(default, true) end
	end
end))


------------------------------ ANTI-RECOIL TAB --------------------------
section("ANTI-RECOIL") -- continues the MAIN page
checkbox("Anti-recoil", "AntiRecoil", nil, "RecoilKey")
checkbox("Always active (no click needed)", "RecoilAlways")
checkbox("Counter sideways kick", "RecoilHorizontal")
slider("Recoil control", "RecoilStrength", 0.1, 1, 0.05, pct)
slider("Post-click duration", "RecoilPostMs", 0, 500, 10, ms)
slider("Fade-out curve", "RecoilFade", 1, 2, 1, function(v) return v == 2 and "Logarithmic" or "Linear" end)
section("MOUSE OFFSET")
slider(hasMouseMove and "Offset range (down, held)" or "Offset range (n/a)", "OffsetRange", 0, 20, 0.1, function(v)
	return string.format("%.1f deg", v)
end)
slider("Time to full offset", "OffsetTime", 0, 5, 0.1, function(v) return string.format("%.1fs", v) end)
slider("Offset curve", "OffsetCurve", 1, 2, 1, function(v) return v == 2 and "Logarithmic" or "Linear" end)
section("MUZZLE")
checkbox("Muzzle-based (detects gun)", "MuzzleRecoil")
slider("Muzzle compensation", "MuzzleComp", 0, 1, 0.05, pct)
section("VIEWMODEL LOCK")
checkbox("Lock at current position", "ModelLock", nil, "ModelLockKey")
checkbox("Remember position per tool", "ModelPerTool")
checkbox("Lock on click (left click)", "ModelLockOnClick")
keybind("Capture / lock key (hold)", "ModelCaptureKey")
btn("Clear saved tool poses", cur, UDim2.new(1, 0, 0, 22), function()
	table.clear(modelPoses)
	modelLock.reset()
	requestSave()
end).LayoutOrder = nextOrder()

------------------------------ PRESETS TAB ------------------------------
-- saved in the persistent config AND exportable / importable as .json
colL = makePage("presets", "PRESETS")
section("PRESETS")
do
	local selName
	local rows = {} -- preset name -> its list row; rows are created/destroyed only when a preset is added/removed
	local function presetNames()
		local t = {}
		for n in pairs(presets) do t[#t + 1] = n end
		table.sort(t, function(a, b)
			local la, lb = a:lower(), b:lower()
			if la ~= lb then return la < lb end
			return a < b
		end)
		return t
	end
	local function cleanName(s)
		s = tostring(s or ""):gsub("[^%w _%-]", "")
		s = s:gsub("^%s+", ""):gsub("%s+$", "")
		return s:sub(1, 32)
	end
	-- "Foo" and "foo" are the same preset: reuse the stored spelling instead of creating a look-alike duplicate
	local function canonical(n)
		if presets[n] then return n end
		local l = n:lower()
		for k in pairs(presets) do
			if k:lower() == l then return k end
		end
		return n
	end
	local function snapshot()
		local t = {}
		for k in pairs(DEFAULTS) do t[k] = settings[k] end
		return t
	end
	local function filtered(tbl)
		local t = {}
		for k, def in pairs(DEFAULTS) do
			if type(tbl[k]) == type(def) then t[k] = tbl[k] end
		end
		return t
	end
	local function applyPreset(tbl)
		for k, v in pairs(filtered(tbl)) do
			local s = setters[k]
			if s then s(v, true) else settings[k] = v end
		end
		Binds.dedupe() -- a preset must never leave two actions on one key
		refreshBinds()
		requestSave()
	end
	local function saveNow()
		dirty = true
		flushSave()
	end

	local function input(props)
		props.BackgroundColor3 = WHITE
		props.BackgroundTransparency = 0.9
		props.PlaceholderColor3 = SUBTEXT
		props.TextColor3 = TEXT
		props.Font = FONT
		props.ClearTextOnFocus = false
		props.TextXAlignment = Enum.TextXAlignment.Left
		props.LayoutOrder = nextOrder()
		local box = new("TextBox", props, cur)
		new("UICorner", { CornerRadius = UDim.new(0, 3) }, box)
		new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, box)
		return box
	end

	local nameBox = input({ Size = UDim2.new(1, 0, 0, 22), PlaceholderText = "preset name (click a preset below to select it)", Text = "", TextSize = 12 })
	local jsonBox, status -- created below the buttons so the layout reads name > list > buttons > json > status
	local function say(msg) if status then status.Text = msg end end

	-- scrollable list: every preset visible at once, click to select
	local list = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = WHITE,
		ScrollBarImageTransparency = 0.5,
		LayoutOrder = nextOrder(),
	}, cur)
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, list)
	new("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, list)
	new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local emptyLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Text = "No presets yet - type a name and press Save",
		Font = FONT,
		TextSize = 11,
		TextColor3 = SUBTEXT,
	}, list)

	local function styleRow(n)
		local r = rows[n]
		if not r then return end
		local on = (n == selName)
		r.BackgroundColor3 = on and ACCENT or WHITE
		r.BackgroundTransparency = on and 0.55 or 0.92
	end
	local function choose(n)
		local prev = selName
		selName = n
		if prev then styleRow(prev) end
		if n then styleRow(n) end
	end
	local function makeRow(n)
		local r = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			Text = n,
			Font = FONT,
			TextSize = 12,
			TextColor3 = TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		}, list)
		new("UICorner", { CornerRadius = UDim.new(0, 3) }, r)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, r)
		-- not tracked on purpose: the row is destroyed with its connection when the preset goes away
		r.MouseButton1Click:Connect(function()
			choose(n)
			nameBox.Text = n
		end)
		return r
	end
	-- reconcile rows with the preset table: add new, remove stale, reorder; existing rows are reused
	local function refreshList()
		local names = presetNames()
		local seen = {}
		for i, n in ipairs(names) do
			seen[n] = true
			local r = rows[n]
			if not r then
				r = makeRow(n)
				rows[n] = r
				styleRow(n)
			end
			if r.LayoutOrder ~= i then r.LayoutOrder = i end
		end
		for n, r in pairs(rows) do
			if not seen[n] then r:Destroy() rows[n] = nil end
		end
		emptyLabel.Visible = (#names == 0)
	end
	local function targetName()
		local n = cleanName(nameBox.Text)
		if n == "" then n = selName end
		return n
	end

	row({
		{ "Save", function()
			local n = targetName()
			if not n or n == "" then say("Type a preset name first") return end
			n = canonical(n)
			presets[n] = snapshot()
			refreshList()
			choose(n)
			nameBox.Text = n
			saveNow()
			say("Saved '" .. n .. "'")
		end },
		{ "Load", function()
			if selName and presets[selName] then
				applyPreset(presets[selName])
				say("Loaded '" .. selName .. "'")
			else
				say("Select a preset first")
			end
		end },
		{ "Delete", function()
			if not (selName and presets[selName]) then say("Select a preset first") return end
			local gone = selName
			local idx = table.find(presetNames(), gone) or 1
			presets[gone] = nil
			refreshList()
			local names = presetNames()
			choose(names[math.min(idx, #names)]) -- neighbour; nil when the list is now empty
			nameBox.Text = ""
			saveNow()
			say("Deleted '" .. gone .. "'")
		end },
	})
	row({
		{ "Export .json", function()
			local n = targetName() or "current"
			if n == "" then n = "current" end
			n = canonical(n)
			local data = presets[n] or snapshot()
			local ok, encoded = pcall(HttpService.JSONEncode, HttpService, { name = n, version = 1, settings = data })
			if not ok then say("Export failed") return end
			jsonBox.Text = encoded
			if hasFS then
				local path = STORAGE_FOLDER .. "/presets/" .. n .. ".json"
				pcall(function()
					if not isfolder(STORAGE_FOLDER) then makefolder(STORAGE_FOLDER) end
					if not isfolder(STORAGE_FOLDER .. "/presets") then makefolder(STORAGE_FOLDER .. "/presets") end
				end)
				say(pcall(writefile, path, encoded) and ("Exported to " .. path) or "File write failed - copy the JSON below")
			else
				say("No file access - copy the JSON below")
			end
		end },
		{ "Import .json", function()
			local raw = jsonBox.Text
			local n = targetName()
			if raw == "" and hasFS and n and n ~= "" then
				local path = STORAGE_FOLDER .. "/presets/" .. n .. ".json"
				local okFile, exists = pcall(isfile, path)
				if okFile and exists then
					local okRead, content = pcall(readfile, path)
					if okRead then raw = content end
				end
			end
			if raw == "" then say("Paste JSON below, or type the name of an exported file") return end
			local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
			if not ok or type(data) ~= "table" then say("Invalid JSON") return end
			local st = type(data.settings) == "table" and data.settings or data
			local name = cleanName(data.name)
			if name == "" then name = (n and n ~= "") and n or "imported" end
			name = canonical(name)
			presets[name] = filtered(st)
			refreshList()
			choose(name)
			nameBox.Text = name
			applyPreset(presets[name])
			saveNow()
			say("Imported and applied '" .. name .. "'")
		end },
	})

	jsonBox = input({
		Size = UDim2.new(1, 0, 0, 54),
		PlaceholderText = "JSON: Export fills this, paste here and press Import",
		Text = "",
		TextSize = 10,
		Font = Enum.Font.Code,
		MultiLine = true,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	status = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "",
		Font = FONT,
		TextSize = 10,
		TextColor3 = SUBTEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = nextOrder(),
	}, cur)

	refreshList()
	choose(presetNames()[1])
end

showTab("main")
end -- UI build

new("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Hold an enabled click (or your hold key) to lock on",
	Font = FONT,
	TextSize = 11,
	TextColor3 = SUBTEXT,
	LayoutOrder = nextOrder(),
}, body)

refreshCircle()
ready = true

----------------------------------------------------------------------
-- DRAGGING & UI MINIMIZE
----------------------------------------------------------------------
local function makeDraggable(handle, target, onClick, onDragEnd)
	local dragging, moved = false, false
	local startMouse, startPos

	track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			startMouse = input.Position
			startPos = target.Position
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startMouse
			if delta.Magnitude > 4 then moved = true end
			if moved then
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if not moved and onClick then onClick() end
			if moved and onDragEnd then onDragEnd() end
		end
	end))
end

makeDraggable(dragArea, window, nil, requestSave)

local minimized, animating = false, false
local expandedHeight = 420

local bubbleGroup = new("CanvasGroup", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	GroupTransparency = 1,
}, window)
local ring = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(22, 22),
	BackgroundTransparency = 1,
}, bubbleGroup)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
new("UIStroke", { Color = ACCENT, Thickness = 2 }, ring)
local centerDot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = WHITE,
	BorderSizePixel = 0,
}, bubbleGroup)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, centerDot)

local bubbleHit = new("TextButton", {
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Text = "",
	Visible = false,
	ZIndex = 10,
}, window)

for _, lay in ipairs({ layout, nav:FindFirstChildOfClass("UIListLayout") }) do -- window fits the taller of nav / body
	track(lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local maxHeight = math.max(320, camera.ViewportSize.Y - 140)
		local inner = math.max(layout.AbsoluteContentSize.Y, nav:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
		expandedHeight = math.min(HEADER_H + inner + 18, maxHeight)
		if not minimized and not animating then
			window.Size = UDim2.fromOffset(WIDTH, expandedHeight)
		end
	end))
end

local function minimize()
	if minimized or animating then return end
	animating = true
	if listeningFor then listeningFor = nil refreshBinds() end

	tween(content, 0.16, { GroupTransparency = 1 })
	task.delay(0.08, function()
		if not alive then return end
		tween(window, 0.36, { Size = UDim2.fromOffset(BUBBLE, BUBBLE), BackgroundTransparency = 0.1 }, Enum.EasingStyle.Quint)
		tween(windowCorner, 0.36, { CornerRadius = UDim.new(0.5, 0) }, Enum.EasingStyle.Quint)
	end)
	task.delay(0.42, function()
		if not alive then return end
		content.Visible = false
		bubbleHit.Visible = true
		tween(bubbleGroup, 0.2, { GroupTransparency = 0 })
		minimized, animating = true, false
	end)
end

local function restore()
	if not minimized or animating then return end
	animating = true
	bubbleHit.Visible = false

	local vp = gui.AbsoluteSize
	local pos = window.AbsolutePosition
	local x = math.clamp(pos.X, 8, math.max(8, vp.X - WIDTH - 8))
	local y = math.clamp(pos.Y, 8, math.max(8, vp.Y - expandedHeight - 8))

	tween(bubbleGroup, 0.12, { GroupTransparency = 1 })
	content.Visible = true
	tween(window, 0.36, {
		Size = UDim2.fromOffset(WIDTH, expandedHeight),
		Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 0.08,
	}, Enum.EasingStyle.Quint)
	tween(windowCorner, 0.36, { CornerRadius = UDim.new(0, 8) }, Enum.EasingStyle.Quint)
	task.delay(0.14, function()
		if alive then tween(content, 0.22, { GroupTransparency = 0 }) end
	end)
	task.delay(0.38, function()
		minimized, animating = false, false
	end)
end

makeDraggable(bubbleHit, window, restore, requestSave)
track(minBtn.MouseButton1Click:Connect(minimize))

----------------------------------------------------------------------
-- CAMERA PERSISTENCE / NO-REVERT FIX
----------------------------------------------------------------------
local function syncCameraOrientation()
	if not camera then return end
	local currentCF = camera.CFrame

	local synced = false
	pcall(function()
		local PlayerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
		if PlayerModule then
			local cameraModule = require(PlayerModule:WaitForChild("CameraModule", 0.1))
			if cameraModule then
				local activeCam = cameraModule:GetActiveCameraController()
				if activeCam and type(activeCam.ResetCameraLookVector) == "function" then
					activeCam:ResetCameraLookVector()
					synced = true
				end
			end
		end
	end)

	if not synced then
		pcall(function()
			local oldType = camera.CameraType
			if oldType == Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Scriptable
				camera.CFrame = currentCF
				task.defer(function()
					if camera then
						camera.CFrame = currentCF
						camera.CameraType = Enum.CameraType.Custom
					end
				end)
			end
		end)
	end
end

----------------------------------------------------------------------
-- TARGET SCANNING & DYNAMIC ENTITY DETECTION (Players + Bots/Pseudo Players)
----------------------------------------------------------------------
local potentialTargets = {}
local tracers = {} -- per-target tracer state + cached UI (declared here so removal can clean it up)

local function dropTarget(key)
	potentialTargets[key] = nil
	local t = tracers[key]
	if t then
		tracers[key] = nil
		if t.line then t.line:Destroy() end
		if t.barBg then t.barBg:Destroy() end
		if t.dline then pcall(function() t.dline:Remove() end) end
		if t.box then t.box:Destroy() end
		if VD.dropChams then VD.dropChams(t) end
	end
	if lockedTarget == key then lockedTarget = nil end
	if forgetBody then forgetBody(key) end
end

-- Real players are tracked by their Player key only (isEntityValid reads p.Character live),
-- so models are registered only for bots / non-player rigs. No duplicates, no CharacterAdded hooks.
local function registerModel(model, noHumanoidOk)
	if not model or potentialTargets[model] or not model:IsA("Model") then return end
	if Players:GetPlayerFromCharacter(model) or model.Name == player.Name then return end
	local ch = player.Character
	if ch and (model == ch or model:IsDescendantOf(ch)) then return end
	if noHumanoidOk or model:FindFirstChildOfClass("Humanoid") then
		potentialTargets[model] = true
	end
end

-- a part matching one of the custom asset IDs appeared: register its character (Humanoid-less rigs too)
onCustomPart = function(inst)
	local role, part = partRole(inst)
	if not role then return end
	local first = part:FindFirstAncestorOfClass("Model")
	local m = first
	while m and not m:FindFirstChildOfClass("Humanoid") do
		m = m:FindFirstAncestorOfClass("Model")
	end
	registerModel(m or first, true)
end

-- user-entered part names / folder (CUSTOM PARTS category)
do
	local folderConn
	local function parseNames(str)
		local out = {}
		for chunk in string.gmatch(str or "", "[^,]+") do
			local n = chunk:match("^%s*(.-)%s*$")
			if n ~= "" then out[#out + 1] = string.split(n, ".") end
		end
		return out
	end
	local function resolvePath(root, segs)
		local node = root
		for _, seg in ipairs(segs) do
			node = node and node:FindFirstChild(seg)
		end
		return node
	end
	custom.find = function(char, list)
		for _, segs in ipairs(list) do
			local p = resolvePath(char, segs)
			if p and p:IsA("BasePart") then return p end
		end
	end
	custom.apply = function()
		custom.names.head = parseNames(settings.CustomHeadNames)
		custom.names.torso = parseNames(settings.CustomTorsoNames)
		if folderConn then folderConn:Disconnect() folderConn = nil end
		local path = parseNames(settings.CustomTargetFolder)[1]
		if not path then return end
		local folder = resolvePath(workspace, path)
		if not folder then
			if settings.CustomTargetFolder ~= DEFAULTS.CustomTargetFolder then -- the default is only a guess, don't nag
				warn("[AimAssist] Custom parts: workspace path '" .. settings.CustomTargetFolder .. "' not found")
			end
			return
		end
		for _, m in ipairs(folder:GetChildren()) do registerModel(m, true) end
		folderConn = track(folder.ChildAdded:Connect(function(m) registerModel(m, true) end))
	end
	custom.apply()
end

local function registerPlayer(p)
	if p ~= player then potentialTargets[p] = true end
end

for _, p in ipairs(Players:GetPlayers()) do
	registerPlayer(p)
end

-- initial map scan in chunks so a big workspace never freezes the UI
task.spawn(function()
	local list = workspace:GetDescendants()
	for i = 1, #list do
		local d = list[i]
		local cn = d.ClassName
		if cn == "Humanoid" then
			registerModel(d.Parent)
		elseif HAS_CUSTOM and (cn == "MeshPart" or cn == "SpecialMesh") then
			onCustomPart(d)
		end
		if i % 3000 == 0 then
			task.wait()
			if not alive then return end
		end
	end
end)

track(Players.PlayerAdded:Connect(registerPlayer))

-- hot path (fires for every instance, incl. coins/particles): one string compare, nothing else.
-- A model gaining a Humanoid always fires this for the Humanoid itself.
track(workspace.DescendantAdded:Connect(function(desc)
	local cn = desc.ClassName
	if cn == "Humanoid" then
		registerModel(desc.Parent)
	elseif HAS_CUSTOM and (cn == "MeshPart" or cn == "SpecialMesh") then
		onCustomPart(desc)
	end
end))

track(workspace.DescendantRemoving:Connect(function(desc)
	if potentialTargets[desc] then dropTarget(desc) end
end))

track(Players.PlayerRemoving:Connect(dropTarget))

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true -- coins / non-collidable decoration no longer count as walls

-- visible(head, origin, char, toPos, ignoreDepth) -> (isVisible, distanceToFirstBlocker)
-- ignoreDepth (studs, optional): walls whose combined thickness along the line of sight is at most this still count
-- as "visible". Thickness of each blocker is measured with a ray from the target back toward the origin that can
-- only hit that blocker (its far face); the near face is where the forward ray hit it.
local visible
do
	local back = RaycastParams.new()
	back.FilterType = Enum.RaycastFilterType.Include
	back.RespectCanCollide = true

	visible = function(head, origin, char, toPos, ignoreDepth)
		local filter = { player.Character, char or head.Parent }
		rayParams.FilterDescendantsInstances = filter
		origin = origin or camera.CFrame.Position
		local target = toPos or head.Position
		local dir = target - origin
		local hit = workspace:Raycast(origin, dir, rayParams)
		if not hit then return true end
		local firstD = hit.Distance
		if not ignoreDepth or ignoreDepth <= 0 then return false, firstD end

		local total = 0
		for _ = 1, 4 do
			local inst = hit.Instance
			back.FilterDescendantsInstances = { inst }
			local far = workspace:Raycast(target, origin - target, back)
			if not far then return false, firstD end -- cannot measure it: treat as a real wall
			total += math.max(0, (far.Position - hit.Position).Magnitude)
			if total > ignoreDepth then return false, firstD end
			filter[#filter + 1] = inst
			rayParams.FilterDescendantsInstances = filter
			hit = workspace:Raycast(origin, dir, rayParams)
			if not hit then return true end
		end
		return false, firstD
	end
end

-- opts (all optional): wall = true/false forces / skips the wall check (nil = use the WallCheck setting),
--                      screen = false skips the on-screen requirement, origin = ray origin for the wall check
local function isEntityValid(targetObj, opts)
	opts = opts or {}
	if not targetObj then return false end

	local char, pTeam, isRealPlayer
	if targetObj:IsA("Player") then
		if targetObj == player or not targetObj.Parent then return false end
		pTeam = targetObj.Team
		char = targetObj.Character
		isRealPlayer = true
	elseif targetObj:IsA("Model") then
		if not targetObj.Parent then return false end
		char = targetObj
		if player.Character and (char == player.Character or char:IsDescendantOf(player.Character)) then
			return false
		end
		local pFromChar = Players:GetPlayerFromCharacter(char)
		if not pFromChar then -- custom character folders (workspace.Characters.<playername>) are named after their player
			local byName = Players:FindFirstChild(char.Name)
			if byName and byName:IsA("Player") then pFromChar = byName end
		end
		if pFromChar then
			if pFromChar == player then return false end
			pTeam = pFromChar.Team
			isRealPlayer = true
		end
	else
		return false
	end

	if not char or not char.Parent then return false end
	if not Scope.allowsChar(char) then return false end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local cHead, cTorso = getBodyParts(char)
	local altHead, altTorso = char:FindFirstChild("Top"), char:FindFirstChild("Center") -- non-humanoid rigs
	local uHead = #custom.names.head > 0 and custom.find(char, custom.names.head) or nil
	local uTorso = #custom.names.torso > 0 and custom.find(char, custom.names.torso) or nil
	local stdHead = uHead or char:FindFirstChild("Head") or altHead
	local stdTorso = uTorso or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or altTorso
	-- IGNORE_REGULAR_HEADS: only a custom head (asset ID match or a name typed in the CUSTOM PARTS panel) counts
	local onlyCustom = IGNORE_REGULAR_HEADS and (Scope.headIds or #custom.names.head > 0)
	local headPart
	if onlyCustom then headPart = cHead or uHead else headPart = cHead or stdHead end
	if onlyCustom and not headPart then return false end
	local torsoPart = cTorso or stdTorso or char:FindFirstChild("HumanoidRootPart")

	-- aim point: slider between head (0) and torso (1); falls back to whichever part exists
	local head, aimPos -- head = part handed back to callers, aimPos = the point actually aimed at
	if headPart and torsoPart and headPart ~= torsoPart then
		aimPos = headPart.Position:Lerp(torsoPart.Position, settings.AimBlend)
		head = (settings.AimBlend >= 0.5) and torsoPart or headPart
	else
		head = headPart or torsoPart
		aimPos = head and head.Position
	end
	if not head then return false end
	if hum then
		if hum.Health <= 0 then return false end
	elseif not (cHead or cTorso or altHead or altTorso or uHead or uTorso) then
		return false -- Humanoid-less rigs only count when a custom / Top / Center part was found
	end

	if settings.TeamCheck and opts.team ~= false then
		if isRealPlayer and pTeam ~= nil and player.Team ~= nil and pTeam == player.Team then
			return false
		end
		local charTeam = char:FindFirstChild("Team") or char:GetAttribute("Team")
		if charTeam and player.Team and tostring(charTeam) == tostring(player.Team.Name) then
			return false
		end
	end

	-- minimum distance: skip anything too close to your own character
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if myRoot and settings.MinDistance > 0 and (aimPos - myRoot.Position).Magnitude < settings.MinDistance then
		return false
	end

	if opts.screen ~= false then
		local _, onScreen = camera:WorldToViewportPoint(aimPos)
		if not onScreen then return false end
	end

	local needWall = opts.wall
	if needWall == nil then needWall = settings.WallCheck end
	if needWall and not visible(head, opts.origin, char, aimPos, settings.WallIgnoreDepth) then return false end

	return true, head, char, aimPos, headPart
end

-- reference point for targeting: screen center (default) or the real cursor
local function lockCenter()
	if settings.LockCursor then return UserInputService:GetMouseLocation() end
	return camera.ViewportSize / 2
end

-- camera goal that puts `pos` under the reference point (cursor mode) or at screen center
local function aimGoal(cf, pos)
	local origin = cf.Position
	if not settings.LockCursor then return CFrame.lookAt(origin, pos) end
	local m = UserInputService:GetMouseLocation()
	local dC = camera:ViewportPointToRay(m.X, m.Y).Direction
	local dH = (pos - origin).Unit
	local axis = dC:Cross(dH)
	local mag = axis.Magnitude
	if mag < 1e-4 then return cf end
	local rot = CFrame.fromAxisAngle(axis / mag, math.atan2(mag, dC:Dot(dH)))
	return CFrame.lookAt(origin, origin + rot * cf.LookVector)
end

-- 6 o'clock exclusion: ignore targets within `deg` degrees of straight down from the aim center
local BottomWedge = { deadPx = 6 }
function BottomWedge.contains(screenPos, center)
	local deg = settings.BottomDeg
	if deg <= 0 then return false end
	local off = screenPos - center
	if off.Y <= 0 then return false end -- at or above center
	-- right on the crosshair the angle is meaningless (sub-pixel jitter): never exclude or drop a lock there
	if off.Magnitude <= BottomWedge.deadPx then return false end
	return math.deg(math.atan2(math.abs(off.X), off.Y)) <= deg
end

local function getTarget()
	local center = lockCenter()
	local bestHead, bestDist, bestTarget, bestPos = nil, settings.FOV, nil, nil
	-- ranking is only paid for (one raycast per candidate in the FOV) when one of the two priority toggles is on
	local rank = settings.PreferVisible or settings.PreferClosestBehind
	local bestVis, bestWd
	local camPos = camera.CFrame.Position

	for targetObj in pairs(potentialTargets) do
		if not targetObj or (type(targetObj) == "userdata" and not targetObj.Parent) then
			dropTarget(targetObj)
		else
			local isValid, head, char, aimPos = isEntityValid(targetObj)
			if isValid and head then
				local pos = camera:WorldToViewportPoint(aimPos)
				local sp = Vector2.new(pos.X, pos.Y)
				local dist = (sp - center).Magnitude
				if not rank then
					if dist < bestDist and not BottomWedge.contains(sp, center) then
						bestHead, bestDist, bestTarget, bestPos = head, dist, targetObj, aimPos
					end
				elseif dist <= settings.FOV and not BottomWedge.contains(sp, center) then
					local vis = visible(head, camPos, char, aimPos, settings.WallIgnoreDepth) -- thin walls count as visible
					local wd = (aimPos - camPos).Magnitude
					local better
					if not bestHead then
						better = true
					elseif (settings.PreferVisible or settings.PreferClosestBehind) and vis ~= bestVis then
						better = vis -- not behind a wall beats behind a wall (the closest-first priority implies this)
					elseif settings.PreferClosestBehind and not vis and not bestVis then
						better = wd < bestWd -- behind walls: nearest to me first, then farther ones
					else
						better = dist < bestDist -- otherwise closest to the crosshair, as before
					end
					if better then
						bestHead, bestDist, bestTarget, bestPos, bestVis, bestWd = head, dist, targetObj, aimPos, vis, wd
					end
				end
			end
		end
	end

	return bestHead, bestDist, bestTarget, bestPos
end

----------------------------------------------------------------------
-- DEBUG TRACERS
----------------------------------------------------------------------
local tracersShown = false
local OPTS = {
	tracer = { wall = false, screen = false },
	trig = { wall = false, screen = false, team = false }, -- includes teammates
	soft = { wall = false }, -- normal validation but ignoring wall/visibility only
	lock = { screen = false }, -- a target you are already locked on to stays valid even if the head leaves the screen
	lockSoft = { wall = false, screen = false },
}

local function buildTracerUI(t)
	t.line = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = TRACER_COLOR,
		BorderSizePixel = 0,
		Visible = false,
	}, tracerLayer)
	t.barBg = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Size = UDim2.fromOffset(BAR_W, BAR_H),
		BackgroundColor3 = Color3.fromRGB(10, 10, 10),
		BorderSizePixel = 0,
		Visible = false,
	}, tracerLayer)
	t.barFill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
	}, t.barBg)
end

local function hideT(t)
	if t.lineVis then t.line.Visible = false; t.lineVis = false end
	if t.barVis then t.barBg.Visible = false; t.barVis = false end
	if t.dVis then t.dline.Visible = false; t.dVis = false end
	if t.boxVis then t.box.Visible = false; t.boxVis = false end
end

hideTracers = function()
	for _, t in pairs(tracers) do
		if t.line then hideT(t) end
	end
	tracersShown = false
end

-- CHAMS. Two layers per target, one active at a time:
--  * IN VIEW (not behind a wall): red Highlight laid over the character in the world (occluded by walls).
--  * BEHIND A WALL: a ForceField-material copy of the character that lives in the SAME SPACE AS THE GUN VIEWMODEL.
--    The copy is shrunk toward the camera (position and size scaled by the same factor about the camera, so it
--    projects to exactly the same place on screen) and parented under the camera, a few studs in front of you.
--    Nothing in the world can be in front of it, exactly like the viewmodel; the gun (nearer) is drawn over it.
--    Real Material = ForceField, recolourable, opacity adjustable, optional outline via a Highlight on the copy.
VD.D0 = 3 -- studs from the camera of the nearest copy; farther targets sit up to 2 studs deeper (keeps their order)

-- CODE TOGGLE (debug / optimisation) -------------------------------------------------------------------------
-- true  = the red in-view chams are ALWAYS enabled. The Highlight is depth-occluded, so it is hidden behind walls
--         by itself and never has to switch on visibility changes (no delay, no flicker).
-- false = the red Highlight is only enabled while the target is visible (fewer active highlights; the 31-highlight
--         cap is reached later). Switching is checked every frame.
VD.RED_ALWAYS = true

-- A/B TOGGLES for the white-layer drift (flip one at a time while testing) -------------------------------------
-- FAST_VIS: true = visibility is re-checked EVERY FRAME (white switches on in the same frame the wall hides the red,
--           with a 2-frame hysteresis when going back to visible so it cannot flicker). false = ~8 times a second.
-- OCCLUDER_DEPTH: true = each copy is placed just in front of the wall that hides it (70% of the way) instead of
--           a fixed 3-5 studs from the camera. The copy is a shrunken stand-in, so any camera position error is
--           multiplied by (target distance / copy distance); a deeper copy shrinks that error.
VD.FAST_VIS = true
VD.OCCLUDER_DEPTH = true

-- PERFORMANCE (white chams) ---------------------------------------------------------------------------------
-- DUAL_PASS_OVERLAY: overlay mode only. true = place the copies + redraw the tracers a second time per frame in the
--   RenderStepped hook (what world-copy mode needs). false = once per frame (half the work); the overlay and the
--   tracers still share one camera sample, so they stay in sync.
-- VIS_INTERVAL: seconds between visibility raycasts per target (FAST_VIS). 1/30 = 30 checks a second instead of one per frame.
-- SKIP_ACCESSORIES / MIN_PART: leave hats / hair and parts smaller than MIN_PART studs out of the copy (fewer parts).
VD.DUAL_PASS_OVERLAY = false
VD.VIS_INTERVAL = 1 / 30
VD.SKIP_ACCESSORIES = true
VD.MIN_PART = 0.35
-- -----------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------

function VD.mk(char, depth)
	local h = Instance.new("Highlight")
	h.DepthMode = depth
	h.Adornee = char
	h.Enabled = false
	h.Parent = gui
	return h
end

local function meshScale(m, k) -- FileMesh geometry ignores Part.Size, so its Scale / Offset must be shrunk too
	if m:IsA("SpecialMesh") and m.MeshType == Enum.MeshType.FileMesh then
		m.Scale = m.Scale * k
		m.Offset = m.Offset * k
	end
end

function VD.clonePart(src)
	local ok, c = pcall(function() return src:Clone() end)
	if not ok or not c then -- Archivable = false etc.: fall back to a plain block of the same size
		c = Instance.new("Part")
		c.Size = src.Size
	end
	local meshes = {}
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("DataModelMesh") then
			pcall(function() ch.TextureId = "" end)
			meshes[#meshes + 1] = { inst = ch, scale = ch.Scale, offset = ch.Offset }
		else
			ch:Destroy() -- joints, scripts, attachments, SurfaceAppearance...
		end
	end
	c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch = true, false, false, false
	c.CastShadow, c.Massless = false, true
	c.Material = Enum.Material.ForceField
	pcall(function() c.TextureID = "" end)
	return { src = src, dst = c, size = src.Size, meshes = meshes }
end

-- resize every copy for scale factor k (done only when k changed noticeably: positions are updated every frame)
function VD.rescale(t, k)
	t.cK = k
	for _, e in ipairs(t.cParts) do
		e.dst.Size = e.size * k
		for _, m in ipairs(e.meshes) do
			m.inst.Scale, m.inst.Offset = m.scale, m.offset
			meshScale(m.inst, k)
		end
	end
end

function VD.build(t, char)
	if t.cModel then t.cModel:Destroy() end
	if t.cHl then t.cHl:Destroy() t.cHl = nil end
	local model = Instance.new("Model")
	model.Name = "AimAssistChams"
	local list, n = {}, 0
	for _, d in ipairs(char:GetDescendants()) do
		n += 1
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.95
			and math.max(d.Size.X, d.Size.Y, d.Size.Z) >= VD.MIN_PART
			and not (VD.SKIP_ACCESSORIES and d:FindFirstAncestorOfClass("Accessory")) then
			local e = VD.clonePart(d)
			e.dst.Parent = model
			list[#list + 1] = e
		end
	end
	t.cModel, t.cParts, t.cMapChar, t.cN, t.cK = model, list, char, n, nil
	local hl = Instance.new("Highlight") -- outline of the copy (the copy itself is never occluded)
	hl.Adornee = model
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.FillTransparency = 1
	hl.Enabled = false
	hl.Parent = gui
	t.cHl = hl
end

-- SCREEN OVERLAY (ChamMode 2): the white copies are drawn by a full-screen ViewportFrame whose camera is set from the
-- same camera sample the tracers use. Like the tracer lines it lives in screen space, so a game that nudges the camera
-- after our update cannot slide it; copies are real-size and keep their real depth order among themselves. It sits
-- behind the tracer lines and the panel, and above the world (so also above the gun).
function VD.vp()
	if VD.vpf and VD.vpf.Parent then return VD.vpf end
	local vpf = Instance.new("ViewportFrame")
	vpf.Name = "ChamsOverlay"
	vpf.BackgroundTransparency = 1
	vpf.Size = UDim2.fromScale(1, 1)
	vpf.ZIndex = -1
	vpf.Ambient = Color3.new(1, 1, 1)
	vpf.LightColor = Color3.new(1, 1, 1)
	vpf.Parent = gui
	local c = Instance.new("Camera")
	c.Parent = vpf
	vpf.CurrentCamera = c
	VD.vpf, VD.vpCam = vpf, c
	return vpf
end

function VD.hideWhite(t)
	if t.cHl then t.cHl.Enabled = false end
	if t.cModel then t.cModel.Parent = nil end
	t.cActive = false
end

function VD.dropWhite(t)
	if t.cHl then t.cHl:Destroy() t.cHl = nil end
	if t.cModel then t.cModel:Destroy() t.cModel = nil end
	t.cParts, t.cActive, t.cK, t.cSig = nil, false, nil, nil
end

function VD.hideChams(t)
	if t.hlVis then t.hlVis.Enabled = false end
	VD.hideWhite(t)
end

function VD.dropChams(t)
	if t.hlVis then t.hlVis:Destroy() t.hlVis = nil end
	VD.dropWhite(t)
	t.cChar, t.cHead, t.cRoot = nil, nil, nil
end

function VD.clearChams()
	for _, t in pairs(tracers) do VD.hideChams(t) end
end

-- white chams switched off: destroy every copy and stop the overlay from rendering
function VD.clearWhite()
	for _, t in pairs(tracers) do VD.dropWhite(t) end
	if VD.vpf then VD.vpf.Visible = false end
end

-- apply colour / opacity to the copy, but only when something actually changed (it used to rewrite every part 8x/s)
function VD.styleWhite(t)
	local cw, tr, ot = VD.cols.wall, 1 - settings.ChamWallFill / 100, 1 - settings.ChamWallOutline / 100
	local sig = cw.R .. "|" .. cw.G .. "|" .. cw.B .. "|" .. tr .. "|" .. ot
	if t.cSig == sig then return end
	t.cSig = sig
	for _, e in ipairs(t.cParts) do
		e.dst.Color = cw
		e.dst.Transparency = tr
	end
	t.cHl.OutlineColor = cw
	t.cHl.OutlineTransparency = ot
end

-- the copy is built only when a target is FIRST behind a wall (not for every target up front), and re-checked for
-- changed parts twice a second
function VD.ensureWhite(t, now)
	local char = t.cChar
	if not char then return false end
	if not t.cModel then
		VD.build(t, char)
		t.cCheck, t.cSig = now + 0.5, nil
	elseif now >= (t.cCheck or 0) then
		t.cCheck = now + 0.5
		if #char:GetDescendants() ~= t.cN then
			VD.build(t, char)
			t.cSig = nil
		end
	end
	VD.styleWhite(t)
	return true
end

-- slow path (called from refreshTracer, ~8 Hz per target): the red layer, and noticing a new character
function VD.chams(t, char, dist, head, root)
	if not settings.Chams then VD.hideChams(t) return end
	if t.cChar ~= char and t.cModel then VD.dropWhite(t) end -- respawned: the old copy is stale
	t.cChar, t.cHead, t.cRoot = char, head, root

	-- red layer: Highlight over the character, occluded by walls
	if not (t.hlVis and t.hlVis.Adornee == char and t.hlVis.Parent) then
		if t.hlVis then t.hlVis:Destroy() end
		t.hlVis = VD.mk(char, Enum.HighlightDepthMode.Occluded)
	end
	local hv, cv = t.hlVis, VD.cols.vis
	hv.Enabled = VD.RED_ALWAYS or t.blocked ~= true
	hv.FillColor, hv.OutlineColor = cv, cv
	hv.FillTransparency = 1 - settings.ChamVisFill / 100
	hv.OutlineTransparency = 1 - settings.ChamVisOutline / 100
end

-- EVERY FRAME, after the camera is final: visibility (optional, at VIS_INTERVAL), then place the copy
function VD.step(cam, light) -- light = placement only (second call per frame)
	if not settings.Chams then return end
	local overlay = settings.ChamMode == 2
	if light and overlay and not VD.DUAL_PASS_OVERLAY then return end

	-- update-rate cap (ChamRate 1 = 30 fps, 2 = 60 fps, 3 = every rendered frame)
	local now = os.clock()
	local rate = settings.ChamRate
	if rate < 3 then
		if now - (VD.lastStep or 0) < (rate == 1 and 1 / 30 or 1 / 60) - 0.002 then return end
		VD.lastStep = now
	end

	local camPos = cam.CFrame.Position
	local white = settings.ChamWall
	local maxD = settings.ChamWallDist
	local anyActive = false
	if overlay and white then -- the overlay camera is the camera sample the tracers use
		VD.vp()
		VD.vpCam.CFrame = cam.CFrame
		VD.vpCam.FieldOfView = cam.FieldOfView
	end

	for _, t in pairs(tracers) do
		local char, head, hv = t.cChar, t.cHead, t.hlVis
		if t.valid and char and head and head.Parent and hv then
			if VD.FAST_VIS and not light then
				if not t.visAt then t.visAt = now + math.random() * VD.VIS_INTERVAL end -- staggered across targets
				if now >= t.visAt then
					t.visAt = now + VD.VIS_INTERVAL
					local vis, hitD = visible(head, camPos, char)
					local want = not vis
					if want == (t.blocked == true) then
						t.bN = 0
					else
						t.bN = (t.bN or 0) + 1
						-- turning white ON is immediate; going back to visible needs 2 clear checks (no edge flicker)
						if want or t.bN >= 2 then t.blocked, t.bN = want, 0 end
					end
					t.hitD = hitD
					hv.Enabled = VD.RED_ALWAYS or not t.blocked
				end
			end

			local shown = false
			if white and t.blocked then
				local r = t.cRoot
				local pos = (r and r.Parent) and r.Position or head.Position
				local dist = (pos - camPos).Magnitude
				if dist <= maxD and VD.ensureWhite(t, now) then
					local k
					if overlay then
						k = 1 -- real size, real place: the overlay camera does the projecting
					else
						local D
						if VD.OCCLUDER_DEPTH and t.hitD then
							D = math.clamp(t.hitD * 0.7, VD.D0, math.max(dist, VD.D0)) -- just in front of the blocking wall
						else
							D = VD.D0 + 2 * dist / (dist + 100)
						end
						k = dist > D and D / dist or 1 -- never enlarge a target already closer than the copy distance
					end
					if not t.cK or math.abs(k - t.cK) / t.cK > 0.08 then VD.rescale(t, k) end
					k = t.cK
					local parent = overlay and VD.vpf or cam
					local model = t.cModel
					if model.Parent ~= parent then model.Parent = parent end
					if t.cHl then
						local want = not overlay -- highlights are not drawn inside a ViewportFrame
						if t.cHl.Enabled ~= want then t.cHl.Enabled = want end
					end
					t.cActive, shown, anyActive = true, true, true
					local list = t.cParts
					for i = 1, #list do
						local e = list[i]
						local src = e.src
						if src.Parent then
							local cf = src.CFrame
							local want = (k == 1) and cf or (cf.Rotation + (camPos + (cf.Position - camPos) * k))
							if want ~= e.last then -- only touch the engine when the pose actually changed
								e.dst.CFrame = want
								e.last = want
							end
						end
					end
				end
			end
			if not shown and t.cActive then VD.hideWhite(t) end
		end
	end
	if overlay and VD.vpf then VD.vpf.Visible = anyActive and white end -- no render pass while nothing is shown
end

-- slow path (~8 Hz per target, staggered): validity, occlusion, distance, opacity, health
local function refreshTracer(key, t, camPos, maxDist, logMax)
	local ok, head, char, _, hp = isEntityValid(key, OPTS.tracer)
	if not ok then t.valid = false return end
	t.hpart = hp or head -- the real head (tracer end); falls back to the aim part
	local _, cTorso = getBodyParts(char)
	local root = char:FindFirstChild("HumanoidRootPart") or cTorso or char.PrimaryPart or head
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root then t.valid = false return end

	local d = (root.Position - camPos).Magnitude
	if d > maxDist then t.valid = false return end -- far targets never pay for a raycast

	t.valid, t.root, t.hum = true, root, hum
	local vis, hitD = visible(head, nil, char)
	t.blocked, t.hitD = not vis, hitD
	t.opacity = 1 - (math.log(1 + d) / logMax) * (1 - TRACER_MIN_OPACITY)
	t.ratio = (hum and hum.MaxHealth > 0) and math.clamp(hum.Health / hum.MaxHealth, 0, 1) or 1
	if settings.Box then
		-- the parts the box wraps: every visible part anywhere inside the character (the same set the chams copy,
		-- nested rigs included), minus held tools and specks. Refreshed twice a second; capped at the 40 biggest.
		local nowb = os.clock()
		if t.bpChar ~= char or not t.bpAt or nowb - t.bpAt > 0.5 then
			t.bpChar, t.bpAt = char, nowb
			local list = {}
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.95 then
					local sz = d.Size
					if math.max(sz.X, sz.Y, sz.Z) >= 0.2 and not d:FindFirstAncestorOfClass("Tool") then
						list[#list + 1] = d
					end
				end
			end
			if #list > 40 then
				table.sort(list, function(a, b)
					local sa, sb = a.Size, b.Size
					return sa.X * sa.Y * sa.Z > sb.X * sb.Y * sb.Z
				end)
				for i = #list, 41, -1 do list[i] = nil end
			end
			if #list == 0 then list[1] = head end
			t.bparts = list
		end
	end
	VD.chams(t, char, d, head, root)
end

local function updateTracers(focusTarget, focusDist, redraw)
	-- redraw = true: only re-project lines / bars with the camera as it is now (no refresh, nothing created)
	if redraw then focusTarget, focusDist = VD.lastFocus, VD.lastFocusD else VD.lastFocus, VD.lastFocusD = focusTarget, focusDist end
	local now = os.clock()
	local vp = camera.ViewportSize
	local cx, cy = vp.X / 2, vp.Y / 2
	local maxLen = vp.Magnitude / 2
	local camPos = camera.CFrame.Position
	local maxDist = TRACER_DISTS[settings.TracerDist] or 1200
	local logMax = math.log(1 + maxDist)
	local halfTan = math.tan(math.rad(camera.FieldOfView) * 0.5)
	local camR, camU = camera.CFrame.RightVector, camera.CFrame.UpVector -- screen-right / screen-up in world space

	for key in pairs(potentialTargets) do
		local t = tracers[key]
		if not t then
			if redraw then continue end
			t = { nextSlow = now + math.random() * TRACER_SLOW }
			tracers[key] = t
		end

		if not redraw and now >= t.nextSlow then
			t.nextSlow = now + TRACER_SLOW
			refreshTracer(key, t, camPos, maxDist, logMax)
			if not t.valid then VD.hideChams(t) end
		end

		local root = t.valid and t.root
		if not (root and root.Parent) then
			if t.line then hideT(t) end
			continue
		end
		if not t.line then buildTracerUI(t) end

		local color, thickness, opacity = t.blocked and TRACER_BLOCKED_COLOR or TRACER_COLOR, settings.TracerThick, t.opacity
		if key == focusTarget and focusDist then
			local closeness = 1 - math.clamp(focusDist / settings.FOV, 0, 1)
			opacity = 0.35 + 0.65 * closeness
			color = FOCUS_COLOR
			-- thickness stays exactly what the slider says (the colour and opacity mark the focus target)
		end

		local spr = camera:WorldToViewportPoint(root.Position) -- body projection (the health bar hangs off this)
		local ep = (settings.TracerEnd == 1 and t.hpart and t.hpart.Parent) and t.hpart or root
		local sp = (ep == root) and spr or camera:WorldToViewportPoint(ep.Position) -- tracer end: the head by default
		local dx, dy = sp.X - cx, sp.Y - cy
		if sp.Z < 0 then dx, dy = -dx, -dy end
		local full = math.sqrt(dx * dx + dy * dy)

		-- line: only touch the engine when something visibly changed
		local sharp = settings.TracerStyle == 2 and VD.hasDrawing
		if settings.Tracers and full > 2 then
			local len = math.min(full, maxLen)
			local ux, uy = dx / full, dy / full
			if sharp then
				-- pixel-exact line through the Drawing API (a rotated GUI frame is always anti-aliased, so it looks soft)
				if t.lineVis then t.line.Visible = false; t.lineVis = false end
				local d = t.dline
				if not d then
					d = Drawing.new("Line")
					t.dline = d
				end
				d.From = Vector2.new(cx, cy)
				d.To = Vector2.new(cx + ux * len, cy + uy * len)
				d.Color = color
				d.Thickness = math.max(1, math.floor(thickness + 0.5))
				d.Transparency = opacity
				if not t.dVis then d.Visible = true; t.dVis = true end
			else
				if t.dVis then t.dline.Visible = false; t.dVis = false end
				local mx, my = cx + ux * len * 0.5, cy + uy * len * 0.5
				local rot = math.deg(math.atan2(uy, ux))
				local line = t.line
				if not t.lineVis then line.Visible = true; t.lineVis = true end
				if not t.lx or math.abs(mx - t.lx) > 0.4 or math.abs(my - t.ly) > 0.4 then
					t.lx, t.ly = mx, my
					line.Position = UDim2.fromOffset(mx, my)
				end
				if not t.len or math.abs(len - t.len) > 0.4 or thickness ~= t.thick then
					t.len, t.thick = len, thickness
					line.Size = UDim2.fromOffset(len, thickness)
				end
				if not t.rot or math.abs(rot - t.rot) > 0.05 then
					t.rot = rot
					line.Rotation = rot
				end
				if color ~= t.color then t.color = color; line.BackgroundColor3 = color end
				if not t.op or math.abs(opacity - t.op) > 0.01 then
					t.op = opacity
					line.BackgroundTransparency = 1 - opacity
				end
			end
		else
			if t.lineVis then t.line.Visible = false; t.lineVis = false end
			if t.dVis then t.dline.Visible = false; t.dVis = false end
		end

		-- character box: the screen rectangle that wraps the character's body parts as they are RIGHT NOW (pose,
		-- perspective and camera angle included), so it traces the character instead of guessing a size. Each part
		-- contributes its centre plus its half extent along screen-right / screen-up (from its own orientation and size).
		if settings.Box and t.bparts then
			local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
			local focal = vp.Y / (2 * halfTan)
			local list = t.bparts
			for i = 1, #list do
				local part = list[i]
				if part.Parent then
					local pp = camera:WorldToViewportPoint(part.Position)
					if pp.Z > 0.1 then
						local cf, sz = part.CFrame, part.Size
						local rv, uv, lv = cf.RightVector, cf.UpVector, cf.LookVector
						local k = 0.5 * focal / pp.Z
						local hx = (math.abs(rv:Dot(camR)) * sz.X + math.abs(uv:Dot(camR)) * sz.Y + math.abs(lv:Dot(camR)) * sz.Z) * k
						local hy = (math.abs(rv:Dot(camU)) * sz.X + math.abs(uv:Dot(camU)) * sz.Y + math.abs(lv:Dot(camU)) * sz.Z) * k
						if pp.X - hx < minX then minX = pp.X - hx end
						if pp.X + hx > maxX then maxX = pp.X + hx end
						if pp.Y - hy < minY then minY = pp.Y - hy end
						if pp.Y + hy > maxY then maxY = pp.Y + hy end
					end
				end
			end
			if maxX > minX and maxY > minY then
				if not t.box then
					t.box = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, tracerLayer)
					t.boxStroke = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, t.box)
				end
				local pad = 1 + settings.BoxPad / 100
				local w, h = (maxX - minX) * pad + 2, (maxY - minY) * pad + 2
				local mx, my = (minX + maxX) * 0.5, (minY + maxY) * 0.5
				local bx = t.box
				if not t.boxVis then bx.Visible = true; t.boxVis = true end
				if not t.bxx or math.abs(mx - t.bxx) > 0.4 or math.abs(my - t.bxy) > 0.4 then
					t.bxx, t.bxy = mx, my
					bx.Position = UDim2.fromOffset(mx, my)
				end
				if not t.bxw or math.abs(w - t.bxw) > 0.4 or math.abs(h - t.bxh) > 0.4 then
					t.bxw, t.bxh = w, h
					bx.Size = UDim2.fromOffset(w, h)
				end
				local st = t.boxStroke
				local bcol = (key == focusTarget and focusDist) and VD.cols.boxFocus or (t.blocked and VD.cols.boxBlocked or VD.cols.box)
				if st.Color ~= bcol then st.Color = bcol end
				if st.Thickness ~= settings.BoxThick then st.Thickness = settings.BoxThick end
				local btr = 1 - opacity
				if math.abs(st.Transparency - btr) > 0.01 then st.Transparency = btr end
			elseif t.boxVis then
				t.box.Visible = false
				t.boxVis = false
			end
		elseif t.boxVis then
			t.box.Visible = false
			t.boxVis = false
		end

		local sp = spr -- the bar hangs above the body, not the head
		-- health bar: one projection, bar offset derived from depth (no second WorldToViewportPoint)
		if settings.HealthBar and sp.Z > 0 and sp.X > 0 and sp.X < vp.X and sp.Y > 0 and sp.Y < vp.Y then
			local by = sp.Y - 3.1 * vp.Y / (2 * halfTan * sp.Z)
			local bar = t.barBg
			local sc = settings.HealthBarSize / 100
			if settings.HealthBarDist then sc = sc * math.clamp(60 / sp.Z, 0.25, 3) end -- 60 studs = slider size
			local bw, bh = math.max(4, math.floor(BAR_W * sc + 0.5)), math.max(2, math.floor(BAR_H * sc + 0.5))
			if bw ~= t.bw or bh ~= t.bh then t.bw, t.bh = bw, bh; bar.Size = UDim2.fromOffset(bw, bh) end
			if not t.barVis then bar.Visible = true; t.barVis = true end
			if not t.bx or math.abs(sp.X - t.bx) > 0.4 or math.abs(by - t.by) > 0.4 then
				t.bx, t.by = sp.X, by
				bar.Position = UDim2.fromOffset(sp.X, by)
			end
			if t.ratio ~= t.lratio then
				t.lratio = t.ratio
				t.barFill.Size = UDim2.fromScale(t.ratio, 1)
				t.barFill.BackgroundColor3 = Color3.fromHSV(t.ratio * 0.33, 0.85, 1)
			end
			if not t.bop or math.abs(opacity - t.bop) > 0.01 then
				t.bop = opacity
				bar.BackgroundTransparency = 1 - opacity * 0.8
				t.barFill.BackgroundTransparency = 1 - opacity
			end
		elseif t.barVis then
			t.barBg.Visible = false
			t.barVis = false
		end
	end
end

-- Re-project the tracers and health bars with the camera as it is NOW. Called from the same late hooks that place the
-- chams copies, so line ends, bars and copies all come from the same camera sample instead of the line / bar being
-- left at an earlier one.
function VD.redraw()
	if not (settings.Tracers or settings.HealthBar or settings.Box) then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	camera = cam
	updateTracers(nil, nil, true)
end

-- PREDICTION MARKER (debug): a ring + dot where the shot is expected to land, with flight time, distance and launch
-- elevation. Projected from the camera as it is at the late hooks, like the tracers.
function VD.marker(cam)
	local m = VD.pm
	local land = VD.land
	if not (settings.PredMarker and land) then
		if m and m.ring.Visible then m.ring.Visible, m.dot.Visible, m.label.Visible = false, false, false end
		return
	end
	if not m then
		local ring = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Visible = false }, gui)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		local stroke = new("UIStroke", { Thickness = 2 }, ring)
		local dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0, ZIndex = 5, Visible = false }, gui)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		local label = new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(240, 14), BackgroundTransparency = 1, Font = FONT, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.5, ZIndex = 5, Visible = false,
		}, gui)
		m = { ring = ring, stroke = stroke, dot = dot, label = label }
		VD.pm = m
	end
	local p = cam:WorldToViewportPoint(land.pt)
	if p.Z <= 0 then
		m.ring.Visible, m.dot.Visible, m.label.Visible = false, false, false
		return
	end
	local c = VD.cols.pred
	m.ring.Position = UDim2.fromOffset(p.X, p.Y)
	m.dot.Position = UDim2.fromOffset(p.X, p.Y)
	m.label.Position = UDim2.fromOffset(p.X + 16, p.Y)
	m.stroke.Color, m.dot.BackgroundColor3, m.label.TextColor3 = c, c, c
	m.label.Text = string.format("T %.2fs | %d studs | %+.1f deg%s", land.t, math.floor(land.d + 0.5), land.elev, land.out and " | OUT OF RANGE" or "")
	m.ring.Visible, m.dot.Visible, m.label.Visible = true, true, true
end

----------------------------------------------------------------------
-- MAIN RENDER LOOP & INPUT
----------------------------------------------------------------------
local function hasToolEquipped()
	local char = player.Character
	return char ~= nil and char:FindFirstChildOfClass("Tool") ~= nil
end

----------------------------------------------------------------------
-- ANTI-RECOIL
-- Works on the camera itself, so it doesn't matter how the weapon model
-- implements recoil. While you're firing and NOT moving the mouse, any
-- upward pitch (or sideways yaw) change is treated as recoil kick and a
-- portion of it is cancelled. Real mouse movement is never touched.
----------------------------------------------------------------------
local recoilPitch, recoilYaw = nil, nil -- baseline from the previous frame

local function camAngles(cf)
	local look = cf.LookVector
	return math.asin(math.clamp(look.Y, -1, 1)), math.atan2(-look.X, -look.Z)
end

local function wrapAngle(a)
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- Recoil-control strength this frame, 0..1 (shared by both methods): full while left click is held or in
-- Always-active mode, then faded out over RecoilPostMs after release (linear, or logarithmic = fast drop, long tail).
local lastFire = -math.huge
local function recoilGate()
	if not settings.AntiRecoil or (settings.RequireTool and not hasToolEquipped()) then return 0 end
	local now = os.clock()
	if heldLeft or settings.RecoilAlways then
		lastFire = now
		return 1
	end
	local dur = settings.RecoilPostMs / 1000
	if dur <= 0 then return 0 end
	local t = (now - lastFire) / dur
	if t >= 1 then return 0 end
	if settings.RecoilFade == 2 then
		return 1 - math.log(1 + 9 * t) / math.log(10)
	end
	return 1 - t
end

local function applyAntiRecoil(driven, gate)
	-- Aim assist is steering this frame, or recoil control is idle (not firing / faded out): just drop the baseline
	if gate <= 0 or driven then
		recoilPitch, recoilYaw = nil, nil
		return
	end

	local pitch, yaw = camAngles(camera.CFrame)

	if recoilPitch then
		local mouse = UserInputService:GetMouseDelta()
		local s = settings.RecoilStrength * gate
		local newPitch, newYaw = pitch, yaw

		if math.abs(mouse.Y) < 0.5 then
			local dp = pitch - recoilPitch
			if dp > 0 then -- only cancel upward kick, not the recovery back down
				newPitch = pitch - dp * s
			end
		end

		if settings.RecoilHorizontal and math.abs(mouse.X) < 0.5 then
			newYaw = yaw - wrapAngle(yaw - recoilYaw) * s
		end

		if newPitch ~= pitch or newYaw ~= yaw then
			newPitch = math.clamp(newPitch, -1.45, 1.45)
			camera.CFrame = CFrame.new(camera.CFrame.Position)
				* CFrame.Angles(0, newYaw, 0)
				* CFrame.Angles(newPitch, 0, 0)
			pitch, yaw = newPitch, newYaw
		end
	end

	recoilPitch, recoilYaw = pitch, yaw
end

----------------------------------------------------------------------
-- MUZZLE ANTI-RECOIL
-- Finds the muzzle of the equipped tool (Attachment / Part whose name matches MUZZLE_NAMES, else the Handle),
-- takes the barrel direction as grip -> muzzle, and measures how far that direction sits from where it
-- sits at rest relative to the camera. Intentional mouse movement moves both together, so only the gun's
-- own kick shows up. The camera is rotated against that kick by MuzzleComp (0-100%); because the offset
-- is applied as an integrator it never drifts, and it unwinds by itself as the kick recovers.
-- Returns true when it handled the frame (so the camera-delta method is skipped).
----------------------------------------------------------------------
local applyMuzzleRecoil
do
	local cache = setmetatable({}, { __mode = "k" })
	local baseP, baseY = nil, nil -- gun pose relative to the camera at rest
	local appP, appY = 0, 0 -- compensation currently applied to the camera (rad)

	local function findMuzzle(tool)
		local now = os.clock()
		local c = cache[tool]
		if c and c.obj.Parent and (c.found or now - c.at < 2) then return c end
		local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
		if not handle then return nil end
		local found
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("Attachment") or d:IsA("BasePart") then
				local n = d.Name:lower()
				for _, hint in ipairs(MUZZLE_NAMES) do
					if n:find(hint, 1, true) then found = d break end
				end
				if found then break end
			end
		end
		c = { obj = found or handle, grip = handle, found = found ~= nil, at = now }
		cache[tool] = c
		return c
	end

	local function muzzleDir(c)
		local obj, grip = c.obj, c.grip
		local isAtt = obj:IsA("Attachment")
		if obj ~= grip then
			local d = (isAtt and obj.WorldPosition or obj.Position) - grip.Position
			if d.Magnitude > 0.3 then return d.Unit end
		end
		return (isAtt and obj.WorldCFrame or obj.CFrame).LookVector
	end

	applyMuzzleRecoil = function(driven, gate, dt)
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		local c = tool and settings.AntiRecoil and settings.MuzzleRecoil and findMuzzle(tool)
		if not c then
			baseP, appP, appY = nil, 0, 0
			return false
		end

		local d = camera.CFrame:VectorToObjectSpace(muzzleDir(c))
		local p, y = math.asin(math.clamp(d.Y, -1, 1)), math.atan2(-d.X, -d.Z)
		local firing = gate > 0 and not driven
		local tail = math.abs(appP) > 0.002 or math.abs(appY) > 0.002

		if not (firing or tail) then
			-- idle: follow the rest pose so a gun held at an angle is not mistaken for recoil
			if baseP then
				baseP = baseP + (p - baseP) * 0.25
				baseY = baseY + wrapAngle(y - baseY) * 0.25
			else
				baseP, baseY = p, y
			end
			return true
		end
		if not baseP then baseP, baseY = p, y return true end
		if driven then appP, appY = 0, 0 return true end -- aimbot is steering: stop compensating

		if settings.RecoilAlways and not heldLeft then
			-- always-active: let the rest pose drift slowly so walk/idle sway is not mistaken for recoil (fast kicks still are)
			local a = 1 - math.exp(-dt / 0.35)
			baseP = baseP + (p - baseP) * a
			baseY = baseY + wrapAngle(y - baseY) * a
		end

		local k = settings.MuzzleComp * gate
		local tp = math.clamp(-(p - baseP) * k, -0.35, 0.35)
		local ty = math.clamp(-wrapAngle(y - baseY) * k, -0.35, 0.35)
		local dP, dY = tp - appP, ty - appY
		appP, appY = tp, ty
		if dP ~= 0 or dY ~= 0 then
			local pitch, yaw = camAngles(camera.CFrame)
			pitch = math.clamp(pitch + dP, -1.45, 1.45)
			camera.CFrame = CFrame.new(camera.CFrame.Position)
				* CFrame.Angles(0, yaw + dY, 0)
				* CFrame.Angles(pitch, 0, 0)
		end
		return true
	end
end

----------------------------------------------------------------------
-- VIEWMODEL / GUN MODEL LOCK
-- Holds the equipped weapon at a captured pose (stored relative to the camera). Instead of anchoring parts or
-- writing the part's CFrame, it rewrites the offset (C0) of the joint that carries the weapon (the character's
-- RightGrip, or the matching Motor6D inside a camera-parented viewmodel rig). Animations keep driving the joints;
-- the offset just cancels their effect on the weapon. The original C0 is restored when the lock is released
-- (disabled, tool switched / unequipped, respawn, script closed). Tuned for first-person viewmodels.
----------------------------------------------------------------------
do
	local VIEWMODEL_HINTS = { "viewmodel", "fpsarms", "firstperson", "arms", "hands", "weapon", "gun" } -- name fragments of rigs parented to the camera
	local tgt, tool, pose = nil, false, nil -- carrying joint, equipped tool (false = unknown while idle), pose (CFrame relative to the camera)
	local since, nextFind = 0, 0
	local lastLeft, lastKey = false, false
	local warned, diagTool, drift = {}, nil, 0 -- printed diagnostics (reset per tool), tool they belong to, frames the weapon failed to follow

	local function warnOnce(msg)
		if warned[msg] then return end
		warned[msg] = true
		warn("[AimAssist] Model lock: " .. msg)
	end
	-- a destroyed rig keeps its descendants' Parent set, so "Parent ~= nil" is not enough to know it is still alive
	local function inWorld(i) return i:IsDescendantOf(workspace) end
	local function transformOf(j)
		return j:IsA("Motor6D") and j.Transform or CFrame.identity
	end
	-- the joint that positions `part` (Part1 is the moved side, its offset is C0 on the Part0 side)
	local function jointFor(root, part)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("JointInstance") and d.Part1 == part and d.Part0 then return d end
		end
	end
	local function findPart(root, names)
		for _, n in ipairs(names) do
			local p = root:FindFirstChild(n, true)
			if p and p:IsA("BasePart") then return p end
		end
	end
	local function hinted(m, toolLower)
		local n = m.Name:lower()
		if toolLower ~= "" and n:find(toolLower, 1, true) then return true end
		for _, h in ipairs(VIEWMODEL_HINTS) do
			if n:find(h, 1, true) then return true end
		end
		return false
	end
	-- returns a target { joint, handle, orig } or nil + the reason it failed
	local function findTarget(t, char, cam)
		local handle = t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart")
		if not handle then return nil, "tool '" .. t.Name .. "' has no BasePart/Handle to lock" end
		local names = { handle.Name, t.Name, "Handle" }
		local first, rest, seen, orphan = {}, {}, {}, nil
		for _, m in ipairs(cam:GetChildren()) do -- a viewmodel rig is the gun you actually see, so it wins
			if m:IsA("Model") then
				seen[#seen + 1] = m.Name
				table.insert(hinted(m, t.Name:lower()) and first or rest, m)
			end
		end
		for _, list in ipairs({ first, rest }) do
			for _, m in ipairs(list) do
				local part = findPart(m, names)
				if part then
					local j = jointFor(m, part)
					if j then return { joint = j, handle = part, orig = j.C0, where = "viewmodel '" .. m.Name .. "'" } end
					orphan = orphan or (m.Name .. "." .. part.Name)
				end
			end
		end
		local j = jointFor(char, handle)
		if j then
			return {
				joint = j, handle = handle, orig = j.C0, where = "character tool '" .. t.Name .. "'",
				note = #seen > 0 and ("camera models [" .. table.concat(seen, ", ") .. "] had no weapon joint matching '" .. handle.Name
					.. "'; locking the character's tool, which is usually hidden in first person") or nil,
			}
		end
		if orphan then
			return nil, "found '" .. orphan .. "' but no Motor6D/Weld has it as Part1 (rig may use a WeldConstraint, or the gun is the rig root)"
		end
		return nil, "no joint carries '" .. handle.Name .. "' in the character or camera models [" .. table.concat(seen, ", ") .. "]"
	end
	-- where the weapon would be without our offset, relative to the camera
	local function natural(g, cam)
		local cf = g.handle.CFrame
		if g.applied then
			local j = g.joint
			cf = j.Part0.CFrame * g.orig * transformOf(j) * j.C1:Inverse()
		end
		return cam.CFrame:ToObjectSpace(cf)
	end
	local function release()
		local g = tgt
		tgt, drift = nil, 0
		if g and g.applied and inWorld(g.joint) then g.joint.C0 = g.orig end
	end

	modelLock.release = function()
		release()
		pose, tool = nil, false
	end
	modelLock.reset = function() pose = nil end

	modelLock.step = function(cam)
		local leftEdge = heldLeft and not lastLeft
		local keyEdge = heldModelKey and not lastKey
		lastLeft, lastKey = heldLeft, heldModelKey

		if not (settings.ModelLock or (settings.ModelLockOnClick and heldLeft) or heldModelKey) then
			-- idle: nothing to do (no per-frame lookups); put the joint back if we were holding it
			if tgt or pose then release() pose = nil end
			tool = false -- unknown while idle, so the next activation captures right away
			return
		end

		local char = player.Character
		local t = char and char:FindFirstChildOfClass("Tool")
		if t ~= tool then -- equipped, switched, unequipped or respawned: start clean
			local fresh = tool ~= false
			release()
			pose, tool, nextFind = nil, t, 0
			since = fresh and os.clock() or -1e9
			if t ~= diagTool then diagTool = t table.clear(warned) end
		end
		if not t then
			warnOnce("no Tool is equipped in your Character; the lock needs an equipped Tool")
			return
		end

		if tgt and not (inWorld(tgt.joint) and tgt.joint.Part0 and tgt.joint.Part1 and inWorld(tgt.handle)) then
			tgt, drift, nextFind = nil, 0, 0 -- rig rebuilt/destroyed: nothing to restore, re-resolve (pose is kept)
		end
		if not tgt then
			local now = os.clock()
			if now < nextFind then return end
			local g, why = findTarget(t, char, cam)
			if not g then
				warnOnce(why)
				nextFind = now + 0.5 -- retry twice a second, not every frame
				return
			end
			tgt = g
			if g.note then warnOnce(g.note) end
			local key = "using " .. g.where .. ", joint " .. g.joint:GetFullName()
			if not warned[key] then warned[key] = true print("[AimAssist] Model lock: " .. key) end
		end

		local recap = keyEdge or (leftEdge and settings.ModelLockOnClick)
		if recap or not pose then
			local saved = (not recap) and settings.ModelLock and settings.ModelPerTool and modelPoses[t.Name]
			if saved then
				pose = CFrame.new(table.unpack(saved)) -- this weapon's remembered pose
			elseif recap or not settings.ModelLock or os.clock() - since >= 0.3 then -- let the equip animation settle first
				pose = natural(tgt, cam)
				if settings.ModelLock and settings.ModelPerTool then
					modelPoses[t.Name] = { pose:GetComponents() }
					requestSave()
				end
			else
				return
			end
		end

		local j = tgt.joint
		if tgt.applied then
			-- verify the weapon actually followed last frame's offset; if not, something else is driving it
			if (cam.CFrame:ToObjectSpace(tgt.handle.CFrame).Position - pose.Position).Magnitude > 1.5 then
				drift += 1
				if drift == 45 then
					warnOnce("the weapon part is not following the joint offset (" .. tgt.where .. "): it is probably driven by direct CFrame writes, a WeldConstraint or a late render callback")
				end
			else
				drift = 0
			end
		end
		tgt.applied = true
		j.C0 = j.Part0.CFrame:Inverse() * (cam.CFrame * pose) * j.C1 * transformOf(j):Inverse()
	end
end

----------------------------------------------------------------------
-- REAL MOUSE SYNC
-- Some gun kits keep their own look angles (built from mouse deltas) and
-- rewrite camera.CFrame from them every frame, so a CFrame we force is
-- visible but the game's real aim never moves, and it snaps back on release.
-- Fix: compare the camera the game produced this frame with what we forced
-- last frame, and feed the difference back in as real mouse movement so the
-- game's own state follows. Needs mousemoverel; does nothing without it.
----------------------------------------------------------------------
local MOUSE_RAD_X = 0.002 * math.pi -- default Roblox rad per pixel (yaw)
local MOUSE_RAD_Y = 0.0015 * math.pi -- default Roblox rad per pixel (pitch)
local SYNC_GAIN = 0.6 -- <1 so it converges instead of overshooting
local SYNC_MAX_PX = 150 -- cap per frame
local SYNC_DEADZONE = 0.015 -- rad; ignore tiny gaps while aiming
local SETTLE_DEADZONE = 0.003 -- rad; how close before we let go after release
local function settleFrames() return math.floor(settings.ReleaseHoldMs / 1000 * 60 + 0.5) end -- frames to keep chasing after release (0 = let go instantly)

local holdCF = nil -- last orientation we forced
local settleLeft = 0

local userGameSettings
pcall(function() userGameSettings = UserSettings():GetService("UserGameSettings") end)

-- Learned mouse sensitivity. ADS / scoped sensitivity changes how far the game's camera turns per mouse pixel
-- (and the FOV change that comes with it), so a fixed pixel conversion under-corrects (the lock can be dragged
-- off the target by hand) or overshoots. This measures radians-per-pixel from the game's own camera response to
-- the real mouse delta, only on frames where that response is trustworthy, and feeds it to mouse sync and the offset.
local Sens = { pre = nil, post = nil, kx = nil, ky = nil, applied = 0, seg = nil,
	flyP = 0, flyY = 0, lastPx = 0, lastPy = 0 } -- fly* = mouse movement we injected that the game's camera has not shown yet
VD.sens = Sens -- reachable from code that is written before Sens is declared (the UI callbacks)

function Sens.angDist(a, b)
	return math.acos(math.clamp(a.LookVector:Dot(b.LookVector), -1, 1))
end

function Sens.base()
	local s = math.max((userGameSettings and userGameSettings.MouseSensitivity) or 1, 0.05)
	return MOUSE_RAD_X * s, MOUSE_RAD_Y * s
end

function Sens.get()
	local bx, by = Sens.base()
	return Sens.kx or bx, Sens.ky or by
end

-- BALLISTIC PREDICTION. Replaces the old "degrees per 1000 studs" drop and the plain lead.
--   * target velocity: smoothed derivative of the target's own position (works for CFrame-moved bots too)
--   * MuzzleOn off: aim point = target + velocity * AimLead (the "prediction time")
--   * MuzzleOn on : solve the shot. Bullet speed = MuzzleVelocity, gravity = ProjGravity or the game's workspace.Gravity
--     (the engine's physics setting, so a different gravity used by player-movement scripts never matters).
--     Flight time t is found by iteration: the target is predicted at t + AimLead, the launch angle that reaches that
--     point is solved (low-angle solution of the ballistic equation), t is updated from it, repeat until it settles.
--     Out of range (no solution) falls back to a 45 degree launch and is flagged.
--   * returns the point to AIM at; VD.land holds the expected landing point + stats for the debug marker.
Sens.hist = setmetatable({}, { __mode = "k" })
VD.land = nil
function Sens.predict(key, pos, now, camPos)
	local h = Sens.hist[key]
	if not h then
		h = { p = pos, t = now, v = Vector3.zero }
		Sens.hist[key] = h
	else
		local dt = now - h.t
		if dt > 0.0005 then
			local v = (pos - h.p) / dt
			if v.Magnitude > 120 then v = v.Unit * 120 end -- teleports / respawns are not real motion
			h.v = h.v:Lerp(v, 0.35)
			h.p, h.t = pos, now
		end
	end
	local vel, extra = h.v, settings.AimLead
	VD.land = nil

	if not settings.MuzzleOn then
		if extra <= 0 then return pos end
		local pt = pos + vel * extra
		VD.land = { pt = pt, t = extra, d = (pt - camPos).Magnitude, elev = 0, out = false }
		return pt
	end

	local mv = math.max(settings.MuzzleVelocity, 1)
	local g = settings.ProjGravity > 0 and settings.ProjGravity or workspace.Gravity
	local S = camPos
	local t = (pos - S).Magnitude / mv
	local pt, dirv, out = pos, Vector3.yAxis, false
	for _ = 1, 8 do
		pt = pos + vel * (t + extra)
		local d = pt - S
		local x = math.sqrt(d.X * d.X + d.Z * d.Z)
		local nt
		if g < 1e-3 or x < 1e-3 then
			nt = d.Magnitude / mv
			dirv = d.Magnitude > 1e-3 and d.Unit or Vector3.yAxis
			out = false
		else
			local disc = mv ^ 4 - g * (g * x * x + 2 * d.Y * mv * mv)
			local tanT
			if disc < 0 then
				tanT, out = 1, true -- no solution: best effort at 45 degrees
			else
				tanT, out = (mv * mv - math.sqrt(disc)) / (g * x), false
			end
			local cosT = 1 / math.sqrt(1 + tanT * tanT)
			dirv = Vector3.new(d.X / x * cosT, tanT * cosT, d.Z / x * cosT)
			nt = x / (mv * cosT)
		end
		if math.abs(nt - t) < 1e-3 then t = nt break end
		t = nt
	end
	local dist = (pt - S).Magnitude
	VD.land = { pt = pt, t = t, d = dist, elev = math.deg(math.asin(math.clamp(dirv.Y, -1, 1))), out = out }
	return S + dirv * dist
end

-- Camera diagnostics (opt-in, prints to the executor log): does the game change the camera AFTER our step in the
-- same frame? Compared at Heartbeat: camera now vs the camera we left at the end of our step.
Sens.dg = { n = 0, late = 0, cuts = 0, posSum = 0, posMax = 0, angSum = 0, angMax = 0, t = os.clock(), tool = nil }
function Sens.diagStep()
	if not settings.CamDiag then return end
	local cam, post = workspace.CurrentCamera, Sens.post
	if not (cam and post) then return end
	local g = Sens.dg

	-- one window per equipped weapon: the numbers depend on the weapon's own camera code
	local ch = player.Character
	local tl = ch and ch:FindFirstChildOfClass("Tool")
	local tn = tl and tl.Name or "none"
	if g.tool ~= tn then
		g.tool = tn
		g.n, g.late, g.cuts, g.posSum, g.posMax, g.angSum, g.angMax, g.t = 0, 0, 0, 0, 0, 0, 0, os.clock()
	end

	g.n += 1
	local pd = (cam.CFrame.Position - post.Position).Magnitude
	local ad = math.deg(Sens.angDist(cam.CFrame, post))
	if pd > 20 or ad > 60 then
		g.cuts += 1 -- respawn / camera cut / subject change: not filtering, kept out of the averages
	elseif pd > 1e-4 or ad > 1e-3 then
		g.late += 1
		g.posSum += pd
		g.angSum += ad
		g.posMax = math.max(g.posMax, pd)
		g.angMax = math.max(g.angMax, ad)
	end
	local now = os.clock()
	if now - g.t >= 3 then
		print(string.format("[AimAssist] camera diag (3s) tool=%s: %d frames | changed after our step: %d (%.0f%%) | pos avg %.3f max %.3f studs | angle avg %.3f max %.3f deg | camera cuts (ignored): %d",
			g.tool, g.n, g.late, g.n > 0 and g.late / g.n * 100 or 0,
			g.late > 0 and g.posSum / g.late or 0, g.posMax,
			g.late > 0 and g.angSum / g.late or 0, g.angMax, g.cuts))
		g.n, g.late, g.cuts, g.posSum, g.posMax, g.angSum, g.angMax, g.t = 0, 0, 0, 0, 0, 0, 0, now
	end
end
-- lists the scripts connected to RenderStepped (needs getconnections): usually the game's camera filter is one of them
function Sens.diagSources()
	pcall(function()
		if type(getconnections) ~= "function" then print("[AimAssist] camera diag: getconnections not available") return end
		local list = getconnections(RunService.RenderStepped)
		print("[AimAssist] camera diag: RenderStepped connections:", #list)
		for i, c in ipairs(list) do
			if i > 15 then break end
			local src = "?"
			local f = c.Function
			if f and type(debug.info) == "function" then
				local ok, v = pcall(debug.info, f, "s")
				if ok then src = tostring(v) end
			end
			print(string.format("  #%d  %s", i, src))
		end
	end)
end

-- once per frame, with the camera exactly as the game left it (before anything of ours touches it)
function Sens.observe(cf)
	local pre, post = Sens.pre, Sens.post
	Sens.pre = cf
	local locked = UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
	local md = locked and UserInputService:GetMouseDelta() or Vector2.zero
	local lpx, lpy = Sens.lastPx, Sens.lastPy -- what we injected last frame lands in THIS frame's delta
	Sens.lastPx, Sens.lastPy = 0, 0
	if not pre then return end

	local kx, ky = Sens.get()
	local p0, y0 = camAngles(pre)
	local p1, y1 = camAngles(cf)
	local rp, ry = p1 - p0, wrapAngle(y1 - y0)

	-- In-flight bookkeeping for heavy camera filters: a filtered camera shows an injected correction over several
	-- frames. `fly` is what we injected that the camera has not shown yet; the sync subtracts it from the remaining
	-- error, so a slow camera is not re-corrected every frame (that is what made the lock overshoot / take its time).
	-- Movement caused by the user's own mouse is removed first, so it is not mistaken for our correction.
	local ip = rp + (md.Y - lpy) * ky
	local iy = ry + (md.X - lpx) * kx
	if Sens.flyP > 0 then Sens.flyP = math.max(0, Sens.flyP - math.max(ip, 0))
	elseif Sens.flyP < 0 then Sens.flyP = math.min(0, Sens.flyP - math.min(ip, 0)) end
	if Sens.flyY > 0 then Sens.flyY = math.max(0, Sens.flyY - math.max(iy, 0))
	elseif Sens.flyY < 0 then Sens.flyY = math.min(0, Sens.flyY - math.min(iy, 0)) end
	Sens.flyP, Sens.flyY = Sens.flyP * 0.93, Sens.flyY * 0.93 -- slow decay: a lost correction is retried

	-- learning the sensitivity: only when the response is trustworthy
	if heldLeft or not locked then return end
	-- the game follows OUR camera (reads camera.CFrame back) instead of its own angles: ratio would be meaningless
	if post and Sens.angDist(cf, post) < Sens.angDist(cf, pre) then return end

	local bx, by = Sens.base()
	if math.abs(md.Y) >= 3 and rp * md.Y < 0 then -- mouse up = look up
		local k = math.abs(rp) / math.abs(md.Y)
		if k > by * 0.15 and k < by * 6 then Sens.ky = Sens.ky and (Sens.ky + (k - Sens.ky) * 0.3) or k end
	end
	if math.abs(md.X) >= 3 and ry * md.X < 0 then -- mouse right = turn right (yaw down)
		local k = math.abs(ry) / math.abs(md.X)
		if k > bx * 0.15 and k < bx * 6 then Sens.kx = Sens.kx and (Sens.kx + (k - Sens.kx) * 0.3) or k end
	end
end

-- MOUSE OFFSET (hold): while left click is held the real mouse is pushed DOWN by OffsetRange degrees (reached over
-- OffsetTime seconds, linear or logarithmic) and stays there; on release it is given back the same way, so the
-- view ends up where it started. Uses mousemoverel, so the game's own aim state follows. Sits out while the
-- aimbot steers (no catch-up jump afterwards).
function Sens.offset(driven, dt)
	local range = math.rad(settings.OffsetRange)
	local canMove = hasMouseMove and not rageOn and UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
	if not canMove or (range <= 0 and Sens.applied == 0) then
		Sens.seg, Sens.applied = nil, 0
		return
	end
	local want = range > 0 and heldLeft and (not settings.RequireTool or hasToolEquipped())
	local goal = want and range or 0
	local now = os.clock()

	local seg = Sens.seg
	if not seg or seg.to ~= goal then
		-- click went down: hold to the offset; click came up: return. Duration scales with the distance left.
		local span = range > 0 and math.min(math.abs(goal - Sens.applied) / range, 1) or 0
		seg = { from = Sens.applied, to = goal, t0 = now, dur = settings.OffsetTime * span }
		Sens.seg = seg
	end

	local f = seg.dur <= 0 and 1 or math.clamp((now - seg.t0) / seg.dur, 0, 1)
	if settings.OffsetCurve == 2 then f = math.log(1 + 9 * f) / math.log(10) end
	local target = seg.from + (seg.to - seg.from) * f

	-- Aimbot is steering: do nothing and freeze the ramp. `applied` stays exactly what was really injected, so the
	-- release gives back only that (it used to be marked as applied without moving, then "returned" on release).
	if driven then
		seg.t0 += dt
		return
	end

	local _, ky = Sens.get()
	local px = (target - Sens.applied) / ky
	local whole = px >= 0 and math.floor(px) or math.ceil(px) -- whole pixels only; the remainder stays in the error
	if whole ~= 0 then
		Sens.applied += whole * ky
		pcall(mousemoverel, 0, whole) -- positive y = look down
	end
end

-- Feeds the gap between the game's camera and `targetCF` back in as real mouse movement, so the game's own aim
-- state follows what we force. `firm` (the lock is absolute this frame) uses full gain and a bigger per-frame
-- cap; the in-flight amount from Sens.observe is subtracted so heavy camera filters converge instead of chasing.
local function syncMouseToward(targetCF, currentCF, deadzone, firm)
	if not (hasMouseMove and settings.SyncMouse) then return 0 end
	-- Only when the game is actually mouse-looking (mouse locked); otherwise
	-- this would just drag the visible cursor around.
	if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then return 0 end

	local tp, ty = camAngles(targetCF)
	local cp, cy = camAngles(currentCF)
	local dPitch, dYaw = tp - cp, wrapAngle(ty - cy)
	local gap = math.max(math.abs(dPitch), math.abs(dYaw))
	if gap < deadzone then return gap end

	local kx, ky = Sens.get() -- rad per pixel, learned from real mouse movement (follows ADS sensitivity)
	local gain = (firm and 1 or SYNC_GAIN) * math.min(settings.LockSpeed, 3)
	local cap = firm and 500 or SYNC_MAX_PX
	-- mouse right = turn right (yaw down), mouse up = look up (pitch up, dy negative)
	local px = math.clamp(math.round(-(dYaw - Sens.flyY) / kx * gain), -cap, cap)
	local py = math.clamp(math.round(-(dPitch - Sens.flyP) / ky * gain), -cap, cap)
	if px ~= 0 or py ~= 0 then
		pcall(mousemoverel, px, py)
		Sens.flyP += -py * ky
		Sens.flyY += -px * kx
		Sens.lastPx, Sens.lastPy = px, py
	end
	return gap
end

----------------------------------------------------------------------
-- FIRE HELPERS, TRIGGER BOT, DEV RAGE MODE
----------------------------------------------------------------------
;(function() -- own function = own register space (Luau allows 200 locals per function)
	local fireCooldown = 0
	local triggerHold = 0
	local rageTarget = nil
	local rageYaw = 0
	local savedCam = nil
	local spinOn = false
	local savedMouse, mouseForced = nil, false
	local nextVisFix = 0
	local GuiService = game:GetService("GuiService")

	-- single exit path for every mouse-locking feature: restores the normal state, never a stale lock
	releaseMouse = function()
		if not mouseForced then return end
		mouseForced = false
		local mb = savedMouse
		savedMouse = nil
		if mb ~= Enum.MouseBehavior.LockCenter then mb = Enum.MouseBehavior.Default end
		pcall(function() UserInputService.MouseBehavior = mb end)
	end

	-- true when an auto-click would land on our own panel, or on clickable game UI (unless allowed)
	local function clickBlocked()
		local m = UserInputService:GetMouseLocation()
		local p, s = window.AbsolutePosition, window.AbsoluteSize
		if m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y then
			return true
		end
		if settings.ClickGameUI then return false end
		local inset = GuiService:GetGuiInset()
		for _, o in ipairs(playerGui:GetGuiObjectsAtPosition(m.X - inset.X, m.Y - inset.Y)) do
			if not o:IsDescendantOf(gui) and (o:IsA("GuiButton") or o.Active) then
				return true
			end
		end
		return false
	end

	-- executor click if present, otherwise Tool:Activate() (fine for your own game's tools)
	local function fireClick()
		if clickBlocked() then return end
		if type(mouse1click) == "function" then
			if Gate.markSim then Gate.markSim(1, 0.3) end
			pcall(mouse1click)
			return
		end
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if tool then
			pcall(function() tool:Activate() end)
		end
	end

	fireClickExt = fireClick

	----------------------------------------------------------------
	-- TRUE PRE-FIRE DELAY (Left / Right pre-fire delay)
	-- click > [delay] > simulated click. The real press is swallowed by a high-priority ContextActionService
	-- sink so the game never sees it, aim engages immediately, and once the delay has passed a simulated press
	-- goes out through mouse1press / mouse2press. A click is only gated when a target is in range, the cursor is
	-- not over UI, and the delay is above 0; otherwise it passes through untouched. Without mouse1press/mouse2press
	-- (or if the sink could not be bound) the old behaviour stays: native click, extra scripted click after the delay.
	----------------------------------------------------------------
	do -- own scope: keeps the gate's locals out of the register budget of everything below (Luau 200-local limit)
	local CAS = game:GetService("ContextActionService")
	local rec = {} -- [1] = left, [2] = right: { t0, due, cap, target, released, relAt, fired }
	local sim = {} -- [btn] = { down, up, exp }: simulated events still in flight (they must pass through the sink)
	Gate.bound = false

	local function fns(btn)
		if btn == 1 then return mouse1press, mouse1release end
		return mouse2press, mouse2release
	end
	local function delayOf(btn) return btn == 1 and settings.LeftDelay or settings.RightDelay end
	local function aimOf(btn) return btn == 1 and settings.LeftClick or settings.RightClick end

	function Gate.available(btn)
		if not Gate.bound then return false end
		local p, r = fns(btn)
		return type(p) == "function" and type(r) == "function"
	end
	function Gate.holding(btn)
		local r = rec[btn]
		return r ~= nil and not r.released
	end
	function Gate.markSim(btn, life)
		sim[btn] = { down = 1, up = 1, exp = os.clock() + (life or 0.3) }
	end
	function Gate.cancel()
		rec[1], rec[2], sim[1], sim[2] = nil, nil, nil, nil
	end

	local function shouldGate(btn)
		if rageOn or not settings.Enabled or not aimOf(btn) or delayOf(btn) <= 0 then return false end
		if settings.RequireTool and not hasToolEquipped() then return false end
		if clickBlocked() then return false end
		return (getTarget()) ~= nil
	end

	local function fire(btn, r, now)
		local press, release = fns(btn)
		r.fired = true
		local s = { down = 1, up = 1, exp = now + 0.5 }
		sim[btn] = s
		if r.released then
			-- the real click was a tap that ended inside the delay: replay it, held as long as the original
			local hold = math.clamp((r.relAt or now) - r.t0, 0.03, 0.4)
			s.exp = now + hold + 0.5
			pcall(press)
			task.delay(hold, function()
				if alive then pcall(release) end
			end)
		else
			-- the OS still has the real button down: hand the game a clean release + press pair
			pcall(release)
			pcall(press)
		end
	end

	local PASS, SINK = Enum.ContextActionResult.Pass, Enum.ContextActionResult.Sink
	local function onInput(_, state, input)
		local btn = input.UserInputType == Enum.UserInputType.MouseButton1 and 1 or 2

		-- our own simulated events always pass
		local s = sim[btn]
		if s and os.clock() < s.exp then
			if state == Enum.UserInputState.Begin and s.down > 0 then s.down -= 1 return PASS end
			if state == Enum.UserInputState.End and s.up > 0 then s.up -= 1 return PASS end
		end

		local r = rec[btn]
		if state == Enum.UserInputState.Begin then
			if r or not shouldGate(btn) then return PASS end
			local now, d = os.clock(), delayOf(btn)
			rec[btn] = { t0 = now, due = now + d, cap = now + d + 0.3 }
			-- the sink makes UIS report this press as "processed", so the held state is set here
			if btn == 1 then heldLeft = true else heldRight = true end
			return SINK
		elseif state == Enum.UserInputState.End then
			if not r then return PASS end
			if btn == 1 then heldLeft = false else heldRight = false end
			r.released, r.relAt = true, os.clock()
			if r.fired then
				rec[btn] = nil
				return PASS -- the game already has our simulated press: let the real release end it
			end
			return SINK -- tap shorter than the delay: replayed by Gate.step
		end
		return PASS
	end

	-- called every frame; `live` = the current locked target (or nil)
	function Gate.step(now, live)
		for btn = 1, 2 do
			local r = rec[btn]
			if r then
				if r.fired then
					if r.released then rec[btn] = nil end
				else
					if live and r.target ~= live then
						-- first lock just records the target; a switch restarts the delay (bounded by `cap`)
						if r.target then r.due = math.min(now + delayOf(btn), r.cap) end
						r.target = live
					end
					if now >= r.due then fire(btn, r, now) end
				end
			end
		end
	end

	function Gate.unbind()
		pcall(function() CAS:UnbindAction("AimAssistClickGate") end)
		Gate.bound = false
		Gate.cancel()
	end

	pcall(function() CAS:UnbindAction("AimAssistClickGate") end)
	Gate.bound = (pcall(function()
		CAS:BindActionAtPriority("AimAssistClickGate", onInput, false, 9000,
			Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2)
	end))
	print(string.format("[AimAssist] mousemoverel=%s mouse1press=%s mouse1release=%s mouse2press=%s mouse2release=%s mouse1click=%s | click gate bound=%s",
		type(mousemoverel), type(mouse1press), type(mouse1release), type(mouse2press), type(mouse2release),
		type(mouse1click), tostring(Gate.bound)))
	end -- gate scope

	local function ownHumanoid()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if hum and root and hum.Health > 0 then
			return hum, root
		end
	end

	do -- trigger-only helpers
	local trigParams = RaycastParams.new()
	trigParams.FilterType = Enum.RaycastFilterType.Exclude
	trigParams.RespectCanCollide = true -- coins / non-collidable decoration don't block the trigger
	local trigSkip = {}

	-- teammate test (same rules as isEntityValid's team check)
	local function friendlyChar(char)
		local myTeam = player.Team
		if not myTeam then return false end
		local p = Players:GetPlayerFromCharacter(char)
		if p then return p ~= player and p.Team == myTeam end
		local t = char:FindFirstChild("Team") or char:GetAttribute("Team")
		return t ~= nil and tostring(t) == tostring(myTeam.Name)
	end

	-- cached target list (10 Hz): key, aim part, root, assembly root, teammate flag
	local trigKeys, trigHeads, trigRoots, trigAsm, trigFriend, trigAt = {}, {}, {}, {}, {}, 0
	local function refreshTrigList(now)
		if now - trigAt < 0.1 then return end
		trigAt = now
		table.clear(trigKeys)
		table.clear(trigHeads)
		table.clear(trigRoots)
		table.clear(trigAsm)
		table.clear(trigFriend)
		for obj in pairs(potentialTargets) do
			local ok, head, char = isEntityValid(obj, OPTS.trig)
			if ok and head then
				local n = #trigKeys + 1
				local root = char:FindFirstChild("HumanoidRootPart") or head
				trigKeys[n], trigHeads[n], trigRoots[n] = obj, head, root
				trigAsm[n] = root.AssemblyRootPart
				trigFriend[n] = friendlyChar(char)
			end
		end
	end

	-- index of the target that `inst` (hit at `pos`) belongs to: welded to it, or within `dist` studs of its head / root
	local function targetNear(pos, dist, inst)
		local ar = inst.AssemblyRootPart
		for i = 1, #trigKeys do
			local h, r = trigHeads[i], trigRoots[i]
			if h.Parent and ((ar ~= nil and trigAsm[i] == ar)
				or (h.Position - pos).Magnitude <= dist or (r.Position - pos).Magnitude <= dist) then
				return i
			end
		end
		return nil
	end

	local function ownerValid(key)
		if key and isEntityValid(key, OPTS.tracer) then return key end
		return nil
	end

	-- is the crosshair on a valid target?
	-- returns the target key under the crosshair (or nil), and true as 2nd value when fire must be held (teammate in front)
	local function crosshairOnTarget()
		local center = lockCenter()

		if settings.TriggerWalls then
			-- proximity mode: any valid target near the crosshair, walls ignored
			refreshTrigList(os.clock())
			for i = 1, #trigKeys do
				local h = trigHeads[i]
				if h.Parent and not (settings.TeamCheck and trigFriend[i]) then
					local p = camera:WorldToViewportPoint(h.Position)
					local sp = Vector2.new(p.X, p.Y)
					if p.Z > 0 and (sp - center).Magnitude <= settings.TriggerRadius and not BottomWedge.contains(sp, center) then
						return trigKeys[i]
					end
				end
			end
			return nil
		end

		-- ray mode: fires when the crosshair is on a target.
		--  * assets (helmets, armor, anything welded to a player or within `asset distance` of it) count as that player:
		--    the ray looks through them up to `asset depth` studs to reach the body, and if it can't, the asset itself counts
		--  * other occluders are walls: only seen through up to `wall depth` studs
		--  * a teammate (or a teammate's asset) in front holds fire when "teammate in front" is on
		local ray = camera:ViewportPointToRay(center.X, center.Y)
		local wallDepth, assetDist, assetDepth = settings.TriggerWallDepth, settings.TriggerAssetDist, settings.TriggerAssetDepth
		if assetDist > 0 then refreshTrigList(os.clock()) end
		table.clear(trigSkip)
		trigSkip[1] = player.Character
		local wallStart, assetStart, ownerKey
		for _ = 1, 5 do
			trigParams.FilterDescendantsInstances = trigSkip
			local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, trigParams)
			if not hit then return ownerValid(ownerKey) end

			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			local key = model and (Players:GetPlayerFromCharacter(model) or model)
			if key and potentialTargets[key] then
				if settings.TriggerTeamBlock and friendlyChar(model) then return nil, true end
				if not isEntityValid(key, OPTS.tracer) then return nil end
				if (wallStart and hit.Distance - wallStart > wallDepth)
					or (assetStart and hit.Distance - assetStart > assetDepth) then
					return ownerValid(ownerKey)
				end
				return key
			end

			local idx = assetDist > 0 and targetNear(hit.Position, assetDist, hit.Instance) or nil
			if idx then
				if settings.TriggerTeamBlock and trigFriend[idx] then return nil, true end
				ownerKey = ownerKey or trigKeys[idx]
				assetStart = assetStart or hit.Distance
				if hit.Distance - assetStart > assetDepth then return ownerValid(ownerKey) end
			else
				if wallDepth <= 0 then return ownerValid(ownerKey) end
				wallStart = wallStart or hit.Distance
				if hit.Distance - wallStart > wallDepth then return ownerValid(ownerKey) end
			end
			trigSkip[#trigSkip + 1] = hit.Instance
		end
		return ownerValid(ownerKey)
	end

	local trigKey, trigSeen = nil, 0

	triggerStep = function(dt, aimActive)
		fireCooldown = math.max(0, fireCooldown - dt)
		if not settings.TriggerBot or heldLeft or (settings.TriggerNeedsAim and not aimActive) then
			triggerHold = 0
			return
		end
		if settings.RequireTool and not hasToolEquipped() then
			triggerHold = 0
			return
		end
		if not ownHumanoid() then
			triggerHold = 0
			return
		end

		-- keep delay: a briefly blocked/flickering hit keeps the same target alive while it is still near the aim point
		local now = os.clock()
		local key, hold = crosshairOnTarget()
		if hold then trigKey = nil end -- a teammate in front cancels the keep-delay grace too
		if key then
			trigKey, trigSeen = key, now
		elseif trigKey then
			local ok, head = false, nil
			if settings.KeepDelay > 0 and now - trigSeen <= settings.KeepDelay / 1000 then
				ok, head = isEntityValid(trigKey, OPTS.soft)
			end
			if ok and head then
				local p = camera:WorldToViewportPoint(head.Position)
				if (Vector2.new(p.X, p.Y) - lockCenter()).Magnitude <= 30 then key = trigKey end
			end
			if not key then trigKey = nil end
		end

		if key then
			triggerHold += dt
			if triggerHold >= settings.TriggerDelay and fireCooldown <= 0 then
				fireCooldown = settings.FireRate
				fireClick()
			end
		else
			triggerHold = 0
		end
	end

	end -- trigger-only helpers

	----------------------------------------------------------------
	-- third person
	----------------------------------------------------------------
	local function enterThirdPerson()
		pcall(function()
			if not savedCam then
				savedCam = {
					mode = player.CameraMode,
					min = player.CameraMinZoomDistance,
					max = player.CameraMaxZoomDistance,
				}
			end
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMaxZoomDistance = math.max(settings.RageZoom, savedCam.max)
			player.CameraMinZoomDistance = settings.RageZoom
		end)
	end

	local function leaveThirdPerson()
		if not savedCam then return end
		local s = savedCam
		savedCam = nil
		pcall(function()
			player.CameraMinZoomDistance = s.min
			player.CameraMaxZoomDistance = s.max
			player.CameraMode = s.mode
		end)
	end

	-- Min/max zoom + camera mode loop. Runs just BEFORE the camera module every frame, so a game script that
	-- re-forces first person / zoom limits (even every Heartbeat) is overridden before the frame renders.
	-- The original mode/min/max were saved in enterThirdPerson and are restored by leaveThirdPerson on rage off.
	pcall(function() RunService:UnbindFromRenderStep("AimAssistCamLock") end)
	RunService:BindToRenderStep("AimAssistCamLock", Enum.RenderPriority.Camera.Value - 1, function()
		if not (rageOn and savedCam and settings.RageThirdPerson and settings.ForcePerspective) then return end
		local z = settings.RageZoom
		if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
		if player.CameraMaxZoomDistance < z then player.CameraMaxZoomDistance = math.max(z, savedCam.max) end
		if player.CameraMinZoomDistance ~= z then player.CameraMinZoomDistance = z end
	end)

	-- setRage(on)           -> turn rage on/off
	-- setRage(true, true)   -> re-apply camera options while already on
	setRage = function(on, reapply)
		if on then
			if not rageOn then
				rageOn = true
				lockedTarget, holdCF, settleLeft, wasAiming = nil, nil, 0, false
				rageTarget = nil
				local _, root = ownHumanoid()
				if root then
					rageYaw = select(2, root.CFrame:ToOrientation())
				end
			elseif not reapply then
				return
			end
			if settings.RageThirdPerson then
				enterThirdPerson()
			else
				leaveThirdPerson()
			end
		else
			if not rageOn then return end
			rageOn = false
			rageTarget = nil
			leaveThirdPerson()
			hud.Visible = false
			releaseMouse()
			local hum = ownHumanoid()
			if hum and spinOn then hum.AutoRotate = true end
			spinOn = false
		end
	end

	----------------------------------------------------------------
	-- rage target selection: nearest to your character, whole map
	----------------------------------------------------------------
	local ropts = { screen = false }
	local rageSeen = 0
	local rageAcq, rageAcqAt = nil, 0 -- current target + when it was acquired (pre-delay)

	local function getRageTarget(root)
		ropts.wall = not settings.RageWalls -- RageWalls on = skip wall check
		ropts.origin = root.Position
		local opts = ropts

		if rageTarget then
			local now = os.clock()
			local ok, head = isEntityValid(rageTarget, opts)
			if ok and head then rageSeen = now return head, rageTarget end
			-- occlusion-only failure: keep the target for KeepDelay
			if opts.wall and settings.KeepDelay > 0 and now - rageSeen <= settings.KeepDelay / 1000 then
				local ok2, head2 = isEntityValid(rageTarget, OPTS.tracer)
				if ok2 and head2 then return head2, rageTarget end
			end
			rageTarget = nil
		end

		local bestHead, bestObj, bestDist = nil, nil, math.huge
		for obj in pairs(potentialTargets) do
			local ok, head = isEntityValid(obj, opts)
			if ok and head then
				local d = (head.Position - root.Position).Magnitude
				if d < bestDist then
					bestHead, bestObj, bestDist = head, obj, d
				end
			end
		end
		rageTarget = bestObj
		rageSeen = os.clock()
		return bestHead, bestObj
	end

	rageStep = function(dt)
		fireCooldown = math.max(0, fireCooldown - dt)

		local hum, root = ownHumanoid()
		if not hum then
			hud.Visible = true
			hud.Text = "RAGE  |  waiting for character"
			releaseMouse() -- free the cursor while dead so respawn / UI stay clickable
			return nil
		end

		-- free camera: lock the cursor so the mouse orbits the view without holding right click
		if settings.RageMouseLook then
			if not mouseForced then
				mouseForced = true
				savedMouse = UserInputService.MouseBehavior
				if savedMouse == Enum.MouseBehavior.LockCurrentPosition then savedMouse = Enum.MouseBehavior.Default end
			end
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
			end
		else
			releaseMouse()
		end

		-- zoom/mode enforcement lives in the AimAssistCamLock step; here only the body-visibility fix
		if settings.RageThirdPerson and settings.ForcePerspective and savedCam then
			-- unhide the body if the game fades it for first person (checked 4x/sec)
			nextVisFix -= dt
			if nextVisFix <= 0 then
				nextVisFix = 0.25
				for _, d in ipairs(hum.Parent:GetChildren()) do
					if d:IsA("BasePart") and d.LocalTransparencyModifier ~= 0 then
						d.LocalTransparencyModifier = 0
					end
				end
			end
		end

		-- auto jump
		if settings.RageAutoJump and hum.FloorMaterial ~= Enum.Material.Air then
			hum.Jump = true
		end

		-- spin bot: the model spins, the camera does not
		if settings.RageSpin then
			hum.AutoRotate = false
			spinOn = true
			rageYaw = (rageYaw + math.rad(settings.SpinSpeed) * dt) % (2 * math.pi)
			root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, rageYaw, 0)
		elseif spinOn then
			hum.AutoRotate = true
			spinOn = false
		end

		-- target + silent aim
		local head, target = getRageTarget(root)
		local usable = (not settings.RequireTool) or hasToolEquipped()
		local nowR = os.clock()
		if target ~= rageAcq then rageAcq, rageAcqAt = target, nowR end
		local wantFire = head and usable
			and (settings.RageAutoFire or heldLeft or heldRight)
			and (nowR - rageAcqAt) >= settings.RageDelay

		if head and wantFire and fireCooldown <= 0 then
			fireCooldown = settings.FireRate
			local aimPos = head.Position + head.AssemblyLinearVelocity * settings.RageLead

			-- Silent aim: aim for one frame only, on the frame the shot goes out. The camera module
			-- overwrites the camera on the next frame, so your view stays free.
			local rp = root.Position
			root.CFrame = CFrame.lookAt(rp, Vector3.new(aimPos.X, rp.Y, aimPos.Z))
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, aimPos)
			fireClick()
		end

		-- HUD
		hud.Visible = true
		if head and target then
			local name = (typeof(target) == "Instance" and target.Name) or "target"
			local studs = math.floor((head.Position - root.Position).Magnitude + 0.5)
			hud.Text = string.format("RAGE  |  %s  |  %d studs%s", name, studs, usable and "" or "  |  equip a tool")
		else
			hud.Text = "RAGE  |  no target"
		end

		return target
	end
end)() -- fire helpers / trigger bot / rage mode

do -- render loop + its private state
local lostAt, focusT, focusHead, focusObj = nil, 0, nil, nil
local circleX, circleY, circleCursor = nil, nil, false
pcall(function() RunService:UnbindFromRenderStep("AimAssist") end)

-- Click pre-delay state machine, one record per button (created on press, dropped on release).
-- Returns (record or nil, shouldFire). The record is dropped when the button is released, the feature/delay is off,
-- aiming stopped, or the target was lost. A target change restarts the delay so aim can settle on the new one.
-- `done` makes it one fire per press, so there can never be overlapping or duplicate fire jobs.
local function stepPend(p, held, enabled, delay, now, target)
	if not p then return nil, false end
	if not (held and enabled and delay > 0 and target) then return nil, false end
	if p.done then return p, false end
	if p.target ~= target then
		p.target, p.at = target, now + delay
		return p, false
	end
	if now >= p.at then
		p.done = true
		return p, true
	end
	return p, false
end

local function renderStep(dt)
	camera = workspace.CurrentCamera
	if not camera then return end

	Sens.observe(camera.CFrame) -- learn the real mouse sensitivity from the game's untouched camera
	VD.land = nil -- the prediction marker only shows while a prediction was made this frame

	modelLock.step(camera) -- viewmodel pose lock (cheap early-out when unused)

	-- safety net: rage is off but the cursor is still ours -> release it
	if not rageOn then releaseMouse() end

	-- clear stuck mouse states if a release event was swallowed (camera drag, locked cursor, focus loss)
	if heldRight and not Gate.holding(2) and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then heldRight = false end
	if heldLeft and not Gate.holding(1) and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then heldLeft = false end

	-- FOV circle follows the cursor in cursor-lock mode
	if circle.Visible then
		if settings.LockCursor then
			local m = UserInputService:GetMouseLocation()
			if m.X ~= circleX or m.Y ~= circleY then
				circleX, circleY, circleCursor = m.X, m.Y, true
				circle.Position = UDim2.fromOffset(m.X, m.Y)
			end
		elseif circleCursor then
			circleX, circleY, circleCursor = nil, nil, false
			circle.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	-- DEV RAGE MODE owns the frame: camera stays free, aim is silent
	if rageOn then
		pendLeft, pendRight = nil, nil -- rage mode has its own fire path
		Gate.cancel()
		local focus = rageStep(dt)
		if settings.Tracers or settings.HealthBar or settings.Chams or settings.Box then
			tracersShown = true
			updateTracers(focus, 0)
		elseif tracersShown then
			hideTracers()
		end
		return
	end

	local nowT = os.clock()
	-- aim engages immediately on click; Left/RightDelay now only delays the scripted fire (see stepPend below)
	local rightOn = settings.RightClick and heldRight
	local leftOn = settings.LeftClick and heldLeft
	local holdOn = heldBind and (nowT - bindAt) >= settings.RightDelay
	local aiming = settings.Enabled and (rightOn or leftOn or holdOn or settings.AlwaysAim)
		and (not settings.RequireTool or hasToolEquipped())

	local head, dist, focusTarget, apos

	if aiming then
		wasAiming = true

		if lockedTarget then
			-- a locked target no longer needs to be on screen: swinging the mouse (high ADS sensitivity) used to
			-- push the head off screen, which dropped the lock and re-picked a target; now the aim pulls back to it
			local isValid, headPart, _, ap = isEntityValid(lockedTarget, OPTS.lock)
			if isValid then
				head, apos, lostAt = headPart, ap, nil
			else
				-- soft failure (only wall/visibility) -> keep the target for KeepDelay; hard failure -> drop now
				local soft, softHead, _, softPos = isEntityValid(lockedTarget, OPTS.lockSoft)
				local now = os.clock()
				if soft and softHead then
					lostAt = lostAt or now
					-- KeepDelay 0 = true zero: dropped on the very frame the check fails
					if settings.KeepDelay > 0 and now - lostAt <= settings.KeepDelay / 1000 then
						head, apos = softHead, softPos
					else
						lockedTarget, lostAt = nil, nil
					end
				else
					lockedTarget, lostAt = nil, nil
				end
			end
		else
			lostAt = nil
		end

		-- 6 o'clock exclusion: drop an already-locked target that has drifted into the wedge
		if lockedTarget and apos then
			local p, onScr = camera:WorldToViewportPoint(apos)
			if onScr and BottomWedge.contains(Vector2.new(p.X, p.Y), lockCenter()) then
				lockedTarget, head, apos, lostAt = nil, nil, nil, nil
			end
		end

		if not lockedTarget then
			head, dist, lockedTarget, apos = getTarget()
		end

		if lockedTarget and apos then apos = Sens.predict(lockedTarget, apos, nowT, camera.CFrame.Position) end -- ballistic prediction

		focusTarget = lockedTarget

		if focusTarget and apos then
			local pos = camera:WorldToViewportPoint(apos)
			dist = (Vector2.new(pos.X, pos.Y) - lockCenter()).Magnitude
		end
	else
		if wasAiming then
			wasAiming = false
			task.spawn(syncCameraOrientation)
		end

		lockedTarget, lostAt = nil, nil
		Sens.flyP, Sens.flyY = 0, 0

		-- tracer focus highlight: full target scan at 10 Hz, cheap re-projection in between
		if settings.Enabled and settings.Tracers then
			focusT -= dt
			if focusT <= 0 then
				focusT = 0.1
				local fh, _, fo = getTarget()
				focusHead, focusObj = fh, fo
			end
			if focusObj and focusHead and focusHead.Parent then
				local p = camera:WorldToViewportPoint(focusHead.Position)
				local sp = Vector2.new(p.X, p.Y)
				dist = (sp - lockCenter()).Magnitude
				if dist <= settings.FOV and not BottomWedge.contains(sp, lockCenter()) then
					head, focusTarget = focusHead, focusObj
				else
					focusObj = nil
				end
			end
		end
	end

	if pendLeft or pendRight then
		local live = aiming and head ~= nil and lockedTarget or nil
		local lReady, rReady
		pendLeft, lReady = stepPend(pendLeft, heldLeft, settings.LeftClick, settings.LeftDelay, nowT, live)
		pendRight, rReady = stepPend(pendRight, heldRight, settings.RightClick, settings.RightDelay, nowT, live)
		if (lReady or rReady) and fireClickExt then fireClickExt() end -- one click even if both are due this frame
	end

	Gate.step(nowT, aiming and head ~= nil and lockedTarget or nil) -- true pre-fire (replaces the block above when available)

	local lockedNow = aiming and head ~= nil
	local gate = recoilGate()
	if applyMuzzleRecoil(lockedNow, gate, dt) then
		recoilPitch, recoilYaw = nil, nil -- the camera-delta method sits out while the muzzle method is active
	else
		applyAntiRecoil(lockedNow, gate)
	end
	Sens.offset(lockedNow, dt) -- mouse offset while left click is held

	if aiming and head and apos then
		local mouseSync = hasMouseMove and settings.SyncMouse

		-- Camera filter: `pre` is what the game's (filtered / smoothed) camera produced this frame. Below 100% "filter
		-- let through" the lock builds on OUR last camera instead, so only that fraction of the game's own camera
		-- movement (and its lag) reaches the view while locked. 0% = the game's camera is ignored completely.
		local pre = camera.CFrame
		local base = pre
		local pass = settings.FilterPass / 100
		if holdCF and pass < 1 then
			base = CFrame.new(pre.Position) * holdCF.Rotation:Lerp(pre.Rotation, pass)
		end

		-- Error is measured as an ANGLE, not pixels. A zoomed (ADS) camera stretches the same angular error over
		-- more pixels, which used to shrink the boost and let mouse movement drag the lock off the target.
		local look
		if settings.LockCursor then
			local m = UserInputService:GetMouseLocation()
			look = camera:ViewportPointToRay(m.X, m.Y).Direction
		else
			look = base.LookVector
		end
		local toAim = apos - base.Position
		local errAng = toAim.Magnitude > 1e-3 and math.acos(math.clamp(look:Dot(toAim.Unit), -1, 1)) or 0
		-- BoostRange is expressed in pixels at the default 70 degree FOV
		local refFocal = (camera.ViewportSize.Y / 2) / math.tan(math.rad(35))
		local refAng = math.atan2(settings.BoostRange, refFocal)
		local ramp = math.clamp(1 - errAng / refAng, 0, 1)
		ramp = ramp * ramp * (3 - 2 * ramp)
		local strength = settings.Strength + (1 - settings.Strength) * settings.Boost * ramp

		if leftOn and not rightOn and not holdOn and not settings.AlwaysAim then
			strength = strength * settings.LeftStability
		end

		local goal = aimGoal(base, apos)
		local alpha = 1 - (1 - strength) ^ (dt * 60 * settings.LockSpeed) -- LockSpeed = lock speed multiplier
		-- hard-lock zone: close enough to the aim point and the lock is absolute, so hand jitter cannot pull it off
		if settings.HardLockDeg > 0 and errAng <= math.rad(settings.HardLockDeg) then alpha = 1 end
		-- camera.CFrame right now is the game's own (filtered) state. Pull THAT toward what we force this frame,
		-- with full gain when the lock is absolute (alpha 1: max strength, boost range or hard-lock zone).
		local forced = base:Lerp(goal, alpha)
		local firm = alpha >= 0.999
		if mouseSync then
			syncMouseToward(forced, pre, firm and 0.002 or SYNC_DEADZONE, firm)
		end
		camera.CFrame = forced

		holdCF = forced
		if mouseSync then settleLeft = settleFrames() end
	elseif holdCF and not aiming then
		-- Released: keep the view where the aim assist left it until the game's own camera catches up
		local gap = 0
		if hasMouseMove and settings.SyncMouse and settleLeft > 0 then
			gap = syncMouseToward(holdCF, camera.CFrame, SETTLE_DEADZONE)
		end
		if gap > SETTLE_DEADZONE and settleLeft > 0 then
			local pos = camera.CFrame.Position
			camera.CFrame = CFrame.lookAt(pos, pos + holdCF.LookVector)
			settleLeft -= 1
		else
			holdCF = nil
			settleLeft = 0
		end
	end

	if settings.Tracers or settings.HealthBar or settings.Chams or settings.Box then
		tracersShown = true
		updateTracers(focusTarget, dist)
	elseif tracersShown then
		hideTracers()
	end

	triggerStep(dt, aiming and head ~= nil)
end

RunService:BindToRenderStep("AimAssist", Enum.RenderPriority.Last.Value + 1000, function(dt) -- after any game camera step at Last
	renderStep(dt)
	local cam = workspace.CurrentCamera
	Sens.post = cam and cam.CFrame or nil -- the camera as we left it (lets Sens.observe tell who drives the camera)
	if cam then
		VD.step(cam) -- behind-wall chams copies follow their targets
		VD.redraw() -- tracers / bars re-projected from the same camera
		VD.marker(cam)
	end
end)
end -- render loop

-- Second chams placement on the RenderStepped event. Whichever of the two (this or the bound step) runs last in the
-- frame reads the freshest camera, so a game that nudges the camera after our bound step no longer leaves the
-- copies behind. Also feeds the camera diagnostics.
track(RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		if settings.Chams then VD.step(cam, true) end
		-- single-pass overlay: lines, bars and the overlay all stay on the bound step's camera sample
		if not (settings.Chams and settings.ChamMode == 2 and not VD.DUAL_PASS_OVERLAY) then VD.redraw() end
		VD.marker(cam)
	end
end))
track(RunService.Heartbeat:Connect(function() Sens.diagStep() end))

local function bindMatches(input, name)
	if type(name) ~= "string" or name == "" or name == "None" then return false end
	return input.KeyCode.Name == name or input.UserInputType.Name == name
end

track(UserInputService.WindowFocusReleased:Connect(function()
	heldBind, heldRight, heldLeft, heldModelKey = false, false, false, false
	pendLeft, pendRight = nil, nil
	Gate.cancel()
	if listeningFor then listeningFor = nil refreshBinds() end -- never leave binding mode armed in the background
end))

track(UserInputService.InputBegan:Connect(function(input, processed)
	-- binding mode (one shared path for every keybind box): Esc cancels and keeps the old bind, Backspace clears it
	if listeningFor then
		local name
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Escape then
				listeningFor = nil
				refreshBinds()
				return
			elseif kc == Enum.KeyCode.Backspace then
				name = "None"
			elseif kc ~= Enum.KeyCode.Unknown then
				name = kc.Name
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			name = "MouseButton3"
		end
		if name then
			local k = listeningFor
			listeningFor = nil
			Binds.assign(k, name) -- steals the key from any other action that had it
			refreshBinds()
		end
		return -- nothing else reacts to input while a bind is being captured
	end

	if not processed then
		if bindMatches(input, settings.HoldKey) then
			if not heldBind then bindAt = os.clock() end
			heldBind = true
		end
		if bindMatches(input, settings.ModelCaptureKey) then heldModelKey = true end
		local tg = Binds.toggles
		for i = 1, #tg do
			local t = tg[i]
			local set = setters[t.setting]
			if set and bindMatches(input, settings[t.bind]) then
				set(not settings[t.setting], true)
				notify(t.id, t.name, settings[t.setting] == true, settings[t.bind])
			end
		end
		if bindMatches(input, settings.PanelKey) and not animating then
			if minimized then restore() else minimize() end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		heldRight = true
		pendRight = (not rageOn and settings.RightClick and settings.RightDelay > 0 and not Gate.available(2)) and {} or nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not processed then
			heldLeft = true
			pendLeft = (not rageOn and settings.LeftClick and settings.LeftDelay > 0 and not Gate.available(1)) and {} or nil
			-- PRE-CLICK INSTANT AIM SNAP (skipped when a left-click pre-delay is set)
			if not rageOn and settings.LeftDelay <= 0 and settings.Enabled and settings.LeftClick and (not settings.RequireTool or hasToolEquipped()) then
				camera = workspace.CurrentCamera
				if camera then
					local head, _, target, apos = getTarget()
					if head and apos then
						lockedTarget = target
						camera.CFrame = aimGoal(camera.CFrame, Sens.predict(target, apos, os.clock(), camera.CFrame.Position))
						if hasMouseMove and settings.SyncMouse then
							holdCF = camera.CFrame
							settleLeft = settleFrames()
						end
					end
				end
			end
		end
	end
end))

track(UserInputService.InputEnded:Connect(function(input)
	if bindMatches(input, settings.HoldKey) then heldBind = false end
	if bindMatches(input, settings.ModelCaptureKey) then heldModelKey = false end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if Gate.holding(2) then return end -- simulated release inside the gate: the real one is handled by the sink
		heldRight = false
		pendRight = nil
		if wasAiming then
			wasAiming = false
			task.spawn(syncCameraOrientation)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if Gate.holding(1) then return end -- simulated release inside the gate: the real one is handled by the sink
		heldLeft = false
		pendLeft = nil
		if wasAiming then
			wasAiming = false
			task.spawn(syncCameraOrientation)
		end
	end
end))

----------------------------------------------------------------------
-- CLOSE & CLEANUP
----------------------------------------------------------------------
local function close()
	if not alive then return end
	if setRage then pcall(setRage, false) end
	if releaseMouse then releaseMouse() end
	flushSave()
	alive = false
	heldBind, heldModelKey = false, false
	heldRight, heldLeft = false, false
	modelLock.release() -- puts the weapon joint back exactly as the game had it
	Gate.unbind() -- removes the click sink so the game gets its normal mouse input back
	pendLeft, pendRight, fireClickExt = nil, nil, nil
	lockedTarget = nil
	settings.Enabled = false
	pcall(function() RunService:UnbindFromRenderStep("AimAssist") end)
	pcall(function() RunService:UnbindFromRenderStep("AimAssistCamLock") end)
	for _, t in pairs(tracers) do
		if t.dline then pcall(function() t.dline:Remove() end) end
		VD.dropChams(t)
	end
	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
	gui:Destroy()
	if env.__AimAssistCleanup == close then env.__AimAssistCleanup = nil end
end

track(closeBtn.MouseButton1Click:Connect(close))
track(gui.Destroying:Connect(close))
env.__AimAssistCleanup = close
