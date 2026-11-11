-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py)
-- [BOOT] version, env, wait for game, single-run guard, unload old runs | VERSION, DIR, env | deps: none | L24-46
-- [DATA] builtin slots, GitHub links, welcome/home/tip text | BUILTIN, GITHUB, WELCOME, TIPS | deps: BOOT | L48-169
-- [STATE] service cache, settings load/save, Module Cfg defaults | S, cfg, save(), MODDEF | deps: BOOT | L171-257
-- [THEME] colors, repaint registry, tween, text helpers | THEMES, col(), paint(), tw(), dur(), split(), score() | deps: STATE | L259-428
-- [CMD_CORE] ctx, player find, chat hook, mute/listen, keybind helpers, Run(), TOGGLES, register | ctx, ctx.Run, ctx.register, TOGGLES | deps: STATE, THEME | L430-1083
-- [CMD_BUILTIN] small built-in command files | CMD[] | deps: CMD_CORE | L1085-1917
-- [CMD_EXTRA] movement, defense, blink, names, servers (ctx.SRV), voice, hide, baseplate, tools, autoexec, autostart, notifier, cleanup | def(), SRV, TOOLS, openTool, setAutoExec | deps: CMD_CORE | L1919-5379
-- [UI_SHARED] gui root, widget builders, toast, welcome, HUD, search, mouse sync | fr(), txt(), btn(), input(), seg(), S.switch, S.notch, ST, ui.toast, ui.matches, ctx.AV | deps: THEME, CMD_CORE | L5381-6209
-- [UI_BAR] command bar, suggestions, history | ui.openBar, ui.closeBar, ui.search, ui.sugRender | deps: UI_SHARED | L6211-6773
-- [UI_PANEL] panel frame, layout table L, sidebar tabs, page motion, loading | L, pages, onShow, ui.selectTab, ui.setPanel, ui.busy, ui.lazy | deps: UI_SHARED | L6775-7145
-- [PG_HOME] Home page: profile, bio/tip, server hero, stats, actions | bannerShow(), stats loop, avatar total | deps: UI_PANEL | L7147-7436
-- [PG_PLAYERS] Players page (cards, sort, voice) and Servers page | render(), card(), slider(), ctx.SRV | deps: UI_PANEL | L7438-7990
-- [PROFILE] player profile window | ui.openProfile, ui.closeProfile, build() | deps: UI_PANEL, PG_PLAYERS | L7991-8397
-- [PG_LOOK] Look and feel page | seg controls, HSL picker | deps: UI_PANEL | L8399-8515
-- [PG_SCRIPTS] Load scripts page | item(), ghInfo() | deps: UI_PANEL, DATA | L8517-8598
-- [PG_CMDS] Commands page | render() | deps: UI_PANEL | L8600-8631
-- [PG_FLOW] flow layout helpers for simple pages | flow(), fhdr(), frow() | deps: UI_PANEL | L8633-8654
-- [PG_AUTOSTART] Autostart page | add(), QUICK, render() | deps: PG_FLOW | L8656-8779
-- [PG_KEYS] Keybinds page | keyTile(), card(), ui.refreshKeys | deps: PG_FLOW | L8781-9014
-- [PG_MODCFG] Module Cfg page | numRow(), strRow(), togRow(), optRow() | deps: PG_FLOW | L9016-9116
-- [PG_PREFS] Preferences page | refresh(), refreshSys(), ui.refreshNu | deps: PG_FLOW | L9118-9207
-- [ENTRY] apply settings, input wiring, unload, startup | ui.apply, ui.rescale, ui.unload, env.KLOSAD | deps: all | L9209-9398
-- [BOOT]
local VERSION = "1.2"
local DIR = "KLOSAD"
local env = (getgenv and getgenv()) or _G
-- the executor's autoexec folder and queue_on_teleport can both start a run after a rejoin / hop. The second run found no env.KLOSAD yet, so both stayed alive and exiting rOSAD only stopped one (lag). Only one run may boot.
if env.KLOSAD_BOOT and os.time() - env.KLOSAD_BOOT < 30 then warn("[KLOSAD] a run is still starting (or one crashed while starting): try again in 30 s"); return end
env.KLOSAD_BOOT = os.time()
-- an autoexec folder runs this before the game is ready: lp, the camera and CoreGui are still nil, so half the script errored out. Wait first.
if not game:IsLoaded() then game.Loaded:Wait(); task.wait(1) end
repeat task.wait() until game:GetService("Players").LocalPlayer and workspace.CurrentCamera
if env.KLOSAD and env.KLOSAD.Unload then pcall(env.KLOSAD.Unload) end
-- every finished run registers its unload here, so a run that lost env.KLOSAD (autoexec + teleport loader, re-exec) is still cleaned up
local olds = env.KLOSAD_ALL or {}
env.KLOSAD_ALL = {} -- emptied first: each unload removes itself from the list, which made ipairs skip every second run
for _, fn in ipairs(olds) do pcall(fn) end
pcall(function() game:GetService("ContextActionService"):UnbindAction("KLOSAD_Shift") end)
pcall(function() game:GetService("ContextActionService"):UnbindAction("KLOSAD_Block") end)
-- a run that errored before the end, or lost env.KLOSAD, leaves its gui, blur and render steps behind; they stack with this run and eat fps
for _, n in ipairs({ "KLSync", "KLSpiderCam", "KLOSAD_Mouse" }) do pcall(function() game:GetService("RunService"):UnbindFromRenderStep(n) end) end
for _, get in ipairs({ function() return game:GetService("CoreGui") end, function() return game:GetService("Players").LocalPlayer.PlayerGui end, function() return game:GetService("Lighting") end }) do
	pcall(function() for _, o in ipairs(get():GetChildren()) do if o.Name == "KLOSAD" or o.Name == "KLOSAD_Blur" then o:Destroy() end end end)
end
-- [/BOOT]

-- [DATA]
-- >>> BUILTIN: locked pre-installed scripts. Paste each script between its two marker lines.
-- An empty slot is simply not listed under Load scripts (and the matching command falls back to its GITHUB link below).
local BUILTIN = {
	{ name = "Lighting Utility", desc = "Real camera blur, focus presets", src = [==[
-- >>> PASTE LIGHTING UTILITY BELOW THIS LINE <<<

-- >>> PASTE LIGHTING UTILITY ABOVE THIS LINE <<<
]==] },
	{ name = "Cobalt", desc = "Remote spy", src = [==[
-- >>> PASTE COBALT BELOW THIS LINE <<<

-- >>> PASTE COBALT ABOVE THIS LINE <<<
]==] },
	{ name = "Dex", desc = "Explorer", src = [==[
-- >>> PASTE DEX BELOW THIS LINE <<<

-- >>> PASTE DEX ABOVE THIS LINE <<<
]==] },
	{ name = "Kelsec", desc = "In-game executor", src = [==[
-- >>> PASTE KELSEC BELOW THIS LINE <<<

-- >>> PASTE KELSEC ABOVE THIS LINE <<<
]==] },
	{ name = "WorkWell", desc = "Aim assist", src = [==[
-- >>> PASTE WORKWELL BELOW THIS LINE <<<

-- >>> PASTE WORKWELL ABOVE THIS LINE <<<
]==] },
	{ name = "KL HL XP", desc = "Half-life movement and physics", src = [==[
-- >>> PASTE KL HL XP BELOW THIS LINE <<<

-- >>> PASTE KL HL XP ABOVE THIS LINE <<<
]==] },
}

-- >>> GITHUB: loadstring links. Use a commit hash in the URL so a repo change can't run unreviewed code.
local GITHUB = {
	{ name = "HLXP", desc = "KL HL XP: half-life movement and physics", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/HLXP" },
	{ name = "Dex++", desc = "Explorer (Dex Plus Plus, stable 3.0)", url = "https://github.com/AZYsGithub/DexPlusPlus/releases/download/stable-3.0/out.lua" },
	{ name = "Kelsec", desc = "In-game executor", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Kelsec.lua" },
	{ name = "WorkWell", desc = "Aim assist", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Workwell%20Aimassist.lua" },
	{ name = "Cobalt", desc = "Remote spy", url = "https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau" },
	{ name = "RSpy", desc = "Remote spy (SimpleSpy V3)", url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua" },
	{ name = "ALogger", desc = "Audio logger: logs sounds as they play", url = "https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua" },
	{ name = "Freeze Instance Saver", desc = "Saves the instance with humanoids and players", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Freeze%20Instance%20Saver.lua" },
	{ name = "LiU", desc = "Lighting Utility", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/LiU%20v9.lua" },
	{ name = "Name Spoofer", desc = "Name spoofer / streamer mode", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Name%20Spoofer.lua" },
	{ name = "No Sit", desc = "Seats can't seat you (used by antisit)", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/No%20Sit.lua" },
	{ name = "Tetris", desc = "Tetris in a window", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Tetris%20Localscript.lua" },
	{ name = "WWA Phantom Forces (Workwell)", desc = "WorkWell aim assist for Phantom Forces", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/WWA%20Phantom%20Forces.lua" },
	{ name = "Tool Properties Editor", desc = "Edits properties for tools (inventory)", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Properties%20Editor.lua" },
	{ name = "KL PF XP", desc = "Half-Life / GoldSrc style movement in Phantom Forces", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/KL%20PF%20XP.lua" },
}

local WELCOME = {
	[==[Welcome back. rOSAD kept your settings. You're welcome.]==],
	[==[rOSAD loaded in under a second. Just thought you should know.]==],
	[==[Command bar's open. Don't just stare at it.]==],
	[==[Everything loaded. Break something, we'll wait.]==],
	[==[The panel's ready. Your move, hotshot.]==],
	[==[Back already? Respect. Type something.]==],
	[==[Command bar's open. It doesn't bite. Byfron does, but that's different.]==],
	[==[Loaded. Try not to type ;cmds ten times in a row.]==],
	[==[All modules loaded. Nothing has crashed yet. Give it a minute.]==],
	[==[Your settings made it back in one piece. Can't say the same for your last session.]==],
	[==[rOSAD is up. The command bar is open and your excuses are closed.]==],
	[==[Modules ready. Go on, pick a command. Any command.]==],
	[==[Everything's loaded and customizable (or at least some of it). Get to work.]==],
	[==[Welcome back, you menace. Command bar's yours.]==],
	[==[Loaded without a single error. Don't jinx it.]==],
	[==[The cursor's blinking. That's rOSAD's way of saying hurry up.]==],
	[==[Settings restored, loops cleared, ego intact. Let's go.]==],
	[==[You're in. The command bar is open, so use it.]==],
	[==[Ready when you are. Actually, ready before you are. Hurry up.]==],
	[==[Fresh session, clean slate. Go ahead and ruin it.]==],
	[==[Command bar's open. Typos are free, so take your shot.]==],
	[==[Back for another round? Good. The panel's warmed up.]==],
	[==[Everything's loaded. Whatever happens next is on you, chief.]==],
	[==[No errors on startup. That's already better than yesterday.]==],
	[==[rOSAD is awake. The command bar is open. Choose violence (the scripting kind).]==],
	[==[Welcome back. Your last command is still in the history. We saw it.]==],
}

local HOME_MSGS = {
	[==[Welcome to your favourite and trusted open-source admin panel, rOSAD.]==],
	[==[Welcome to rOSAD, for the humble scripters and exploiters.]==],
	[==[Welcome to rOSAD. You're not about to cheat on a game with this, are you? ...Right?]==],
	[==[Be gentle with Byfron. It bites, and that one's not on us.]==],
	[==[Welcome to rOSAD. Everything here is legal. Probably.]==],
	[==[Welcome back. Your admin privileges have been verified by absolutely no one.]==],
	[==[Loaded successfully. Whether it works is between you and the game.]==],
	[==[Welcome to rOSAD. 40% fewer errors than yesterday's build. We counted. Mostly.]==],
	[==[Welcome to rOSAD. Any resemblance to a functioning script is purely intentional.]==],
	[==[Thanks for choosing rOSAD. Your patience has been noted and will be needed.]==],
	[==[rOSAD is open source, so if it breaks, you're technically on the dev team.]==],
	[==[Welcome to rOSAD, where "it works on my machine" is a core design principle.]==],
	[==[Byfron says hi. We told it you were just browsing.]==],
	[==[Welcome. Not responsible for lag, bans, or sudden existential dread.]==],
	[==[Built, broken, and rebuilt more times than we'll admit.]==],
	[==[Structured with care, debugged with questionable patience.]==],
	[==[If something looks too clean, we're as surprised as you are.]==],
	[==[Every bug was found the hard way, usually twice.]==],
	[==[rOSAD loaded. It took a lot of "why is this nil" to get here.]==],
	[==[Somewhere in here is a pcall holding everything together. Nobody knows which one.]==],
	[==[Oh, you're back. Great. Let's go.]==],
	[==[The commands are all documented. Not that anyone checked.]==],
	[==[Customizable (or at least some), so every complaint is technically your fault.]==],
	[==[Customize everything. Break everything. Reset it and pretend it never happened.]==],
	[==[Welcome back, you menace. The command bar missed you.]==],
	[==[Misspelled a command? rOSAD saw it. rOSAD said nothing.]==],
}

local TIPS = {
	"Did you know that you can change your default prefix bind to a custom key? Go to the Keybinds tab.",
	"Type part of a command in the bar and press Tab to complete it.",
	"bind f fly 80 binds F to a command. Manage binds in the Keybinds tab.",
	"Drop your own command files in KLOSAD/commands, then type reload.",
	"Preferences > Reset all effects turns off fly, noclip, esp and more in one click.",
	"Drag the panel by its title bar.",
}
-- [/DATA]

-- [STATE]
-- S = service cache + shared state; ui = functions the UI part fills in
-- FIX: a failed GetService used to return the error text (truthy), so S.barOpen / S.capture etc. were always "set". Now returns nil.
local S = setmetatable({ cons = {}, sel = 1, cur = {}, launched = {}, alive = true }, { __index = function(t, k)
	local ok, v = pcall(game.GetService, game, k)
	if ok then t[k] = v; return v end
end })
-- >>> SELF_URL (optional): if you host this script on GitHub, put its raw link here. Auto execute uses it when there is no local copy.
local SELF_URL = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/refs/heads/main/!%20KL%20rOSAD%20Main.lua"

-- accept the github.com/.../blob/... page link too: the loader needs the raw file
SELF_URL = (SELF_URL:match("^%s*(.-)%s*$"):gsub("^https://github%.com/([^/]+)/([^/]+)/blob/", "https://raw.githubusercontent.com/%1/%2/"))

local ui = {}

local request = (syn and syn.request) or http_request or request
local HAS_FS = (readfile and writefile and listfiles and isfolder and makefolder) and true or false
local HAS_LOAD = pcall(function() return loadstring("return 1")() end)

-- ===== settings ============================================================
local DEFAULTS = {
	theme = "Dark", opacity = 0.8, glow = 75, banner = {}, accent = "#FFFF00", anim = 1, scale = 1,
	lines = 12, blur = 1, pos = "Center", barKey = "Semicolon", panelKey = "RightShift",
	toasts = true, bio = "", bios = {}, binds = {}, autoExec = false, avc = false, mod = {}, exp = {}, hist = {}, startBar = true, autostart = {},
	kbTabs = {}, kbActive = "default", expIcon = {}, carry = {}, sugCols = false, selfPath = "", aliases = {}, kbDefName = "Default", listenPad = 0, srvRegion = "", srvSort = "Ping", srvDesc = false, srvMax = 50, notifyUsers = {}, nuPoll = 60, plSort = "A-Z", plPoll = 1,
}
local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end
cfg.binds = {}
cfg.mod = {}
cfg.exp = {}
cfg.hist = {}
cfg.kbTabs = {}
cfg.expIcon = {}
cfg.banner = {}
cfg.carry = {}
cfg.aliases = {}
cfg.notifyUsers = {}
cfg.bios = {}
cfg.autostart = { onExec = true, items = {} }

local function save()
	if not writefile then return end
	pcall(function()
		if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
		writefile(DIR .. "/settings.json", S.HttpService:JSONEncode(cfg))
	end)
end

if readfile and isfile then
	pcall(function()
		if isfile(DIR .. "/settings.json") then
			for k, v in pairs(S.HttpService:JSONDecode(readfile(DIR .. "/settings.json"))) do
				if DEFAULTS[k] ~= nil and type(v) == type(DEFAULTS[k]) then cfg[k] = v end
			end
		end
	end)
end


-- Module Cfg defaults: every value-based command has a default and (where it makes sense) a multiplier
local MODDEF = {
	flyDef = 50, flyMult = 1, speedDef = 16, speedMult = 1, jpDef = 50, jpMult = 1, spinDef = 2, spinMult = 1,
	tpMode = "Multiplier", tpDef = 2, tpCap = 10, followRadius = 5, fpsCorner = "TR", ragdollBlock = true,
	streamMe = "Streamer", streamOthers = "Pasta Hater",
	bpDist = 1.5, bpHeight = 0.5, babyDist = 2.2, babyHeight = 0.5, babyRot = 35, babyLean = 0,
	afRadius = 15, afThreshold = 120, afRestore = 1.5, atpMin = 40, akMax = 80, aeThreshold = 500, aeDuration = 2,
	afkInterval = 60, spamCount = 3, avHeight = 50, defNotify = true,
	floatStep = 3, espCustom = false, espColor = "#FF3B3B", actOn = true, actCorner = "BL",
	predOn = false, predMult = 1, srvShow = false, srvHide = 0.5,
	chStyle = "Cross", chLen = 6, chGap = 4, chThick = 2, chOutline = 1, chOutlineAlpha = 1, chColor = "#00FF00", chCursor = false,
	headDist = 1.5, headHeight = 1.5, headSide = 0, headSweep = true, headSweepAmp = 0.5, headSweepSpeed = 10,
	backDist = 1.2, backHeight = 0.5, backSide = 0, backSweep = true, backSweepAmp = 0.5, backSweepSpeed = 20, srvPingMult = 2,
	ph1Mult = 1, spWall = 3,
}
for k, v in pairs(MODDEF) do
	if type(cfg.mod[k]) ~= type(v) then cfg.mod[k] = v end
end
-- one-time: move saved Back attach values to the standalone script's (sweep on); edits made afterwards stay
if not cfg.mod.backV2 then
	cfg.mod.backV2 = true
	cfg.mod.backDist, cfg.mod.backSweep, cfg.mod.backSweepSpeed = MODDEF.backDist, MODDEF.backSweep, MODDEF.backSweepSpeed
end

if type(cfg.autostart.items) ~= "table" then cfg.autostart.items = {} end
if type(cfg.autostart.onExec) ~= "boolean" then cfg.autostart.onExec = true end
-- [/STATE]

-- [THEME]
-- ===== theme + small helpers ===============================================
local rgb = Color3.fromRGB
-- Colors resolved from the reference deck (tx1=black, bg1=white, bg2=E7E6E6, with the lumMod values applied).
local THEMES = {
	Dark = { panel = rgb(8, 8, 10), panelEdge = rgb(52, 50, 58), inner = rgb(15, 15, 18), edge = rgb(72, 70, 80), bar = rgb(15, 15, 18),
		tabOn = rgb(110, 106, 120), tabOff = rgb(0, 0, 0), row = rgb(32, 31, 37), ctrlOn = rgb(110, 106, 120), ctrlOff = rgb(30, 30, 35),
		btnFill = rgb(40, 40, 46), glass = rgb(0, 0, 0), sheen = rgb(255, 255, 255), text = rgb(255, 255, 255), text2 = rgb(238, 237, 242), sub = rgb(158, 156, 168),
		dim = rgb(112, 110, 124), hint = rgb(122, 122, 134), line = rgb(72, 70, 80), danger = rgb(255, 99, 88), info = rgb(77, 163, 255) },
	Light = { panel = rgb(242, 242, 242), panelEdge = rgb(242, 242, 242), inner = rgb(231, 230, 230), edge = rgb(158, 155, 155), bar = rgb(231, 230, 230),
		tabOn = rgb(138, 134, 134), tabOff = rgb(255, 255, 255), row = rgb(191, 191, 191), ctrlOn = rgb(138, 134, 134), ctrlOff = rgb(250, 250, 250),
		btnFill = rgb(214, 213, 213), glass = rgb(255, 255, 255), sheen = rgb(0, 0, 0), text = rgb(13, 13, 13), text2 = rgb(31, 31, 31), sub = rgb(84, 81, 81),
		dim = rgb(107, 103, 103), hint = rgb(107, 103, 103), line = rgb(138, 134, 134), danger = rgb(206, 38, 30), info = rgb(0, 106, 220) },
}
if not THEMES[cfg.theme] then cfg.theme = "Dark" end
if cfg.pos ~= "Top" and cfg.pos ~= "Bottom" then cfg.pos = "Center" end

local function parseHex(h)
	if type(h) ~= "string" or not h:match("^#%x%x%x%x%x%x$") then return nil end
	return rgb(tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16))
end
local function hex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
S.accent = parseHex(cfg.accent) or rgb(255, 255, 0)

local function lum(c)
	local function f(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * f(c.R) + 0.7152 * f(c.G) + 0.0722 * f(c.B)
end
local function contrast(a, b)
	local la, lb = lum(a), lum(b)
	if la < lb then la, lb = lb, la end
	return (la + 0.05) / (lb + 0.05)
end
-- nudge a color toward white (dark bg) or black (light bg) until it reaches 4.5:1 contrast
local function legible(c, bg)
	local target = lum(bg) > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	for i = 0, 10 do
		local t = c:Lerp(target, i / 10)
		if contrast(t, bg) >= 4.5 then return t end
	end
	return target
end
S.accentText = legible(S.accent, THEMES[cfg.theme].panel)

local function col(key)
	if key == "accent" then return S.accent end
	if key == "accentText" then return S.accentText end
	if key == "onAccent" then return lum(S.accent) > 0.4 and rgb(16, 16, 18) or rgb(255, 255, 255) end -- label on a solid accent fill (primary buttons)
	return THEMES[cfg.theme][key]
end

-- every themed property is registered here so theme/accent changes repaint live. A plain table on purpose (weak Instance keys can drop rows that still exist): clear() and applyTheme() let go of destroyed rows
local themed = {}
local function paint(inst, prop, key)
	local t = themed[inst]
	if not t then t = {}; themed[inst] = t end
	t[prop] = key
	inst[prop] = col(key)
end
-- decoration (gradients, washes, sheens, glows) is dark mode only: light mode stays flat
S.fxSet = setmetatable({}, { __mode = "k" })
function S.deco(o)
	S.fxSet[o] = true
	o[o:IsA("UIGradient") and "Enabled" or "Visible"] = cfg.theme == "Dark"
	return o
end
function S.applyDeco()
	for o in pairs(S.fxSet) do pcall(function() o[o:IsA("UIGradient") and "Enabled" or "Visible"] = cfg.theme == "Dark" end) end
end
local function applyTheme()
	S.applyDeco()
	for inst, t in pairs(themed) do
		if not inst.Parent then
			themed[inst] = nil
		else
			for prop, key in pairs(t) do pcall(function() inst[prop] = col(key) end) end
		end
	end
end

local function esc(s) return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function hl(text, q)
	if q and q ~= "" then
		local i, j = text:lower():find(q:lower(), 1, true)
		if i then
			return esc(text:sub(1, i - 1)) .. '<font color="' .. hex(S.accentText) .. '">' .. esc(text:sub(i, j)) .. "</font>" .. esc(text:sub(j + 1))
		end
	end
	return esc(text)
end

local function mix(a, b)
	local o = {}
	for k, v in pairs(a) do o[k] = v end
	for k, v in pairs(b or {}) do o[k] = v end
	return o
end
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
-- animation speed setting: 0.5x / 1x / 2x / none (0)
-- every duration is doubled so effects are easier to notice; the 1.0x setting is what 0.5x used to be
-- motion tokens: every tween (and every wait that matches a tween) lands on one of four durations: press / hover / open / slow. Nothing animates at a one-off speed
local MOTION = { 0.06, 0.1, 0.16, 0.3 }
local function dur(t)
	if cfg.anim == 0 then return 0 end
	local want, best, bd = t or 0.15, MOTION[1], math.huge
	for _, v in ipairs(MOTION) do
		local d = math.abs(v - want)
		if d < bd then best, bd = v, d end
	end
	return best * 2 / cfg.anim
end
local function tw(inst, props, t, style)
	if cfg.anim == 0 then
		for k, v in pairs(props) do inst[k] = v end
		return
	end
	-- ONE curve for the whole UI: a quarter sine (Sine Out). Fast start, soft landing, never overshoots, and every fade / slide / hover / press uses it.
	-- Only Linear is honoured, for progress lines that show time running out (they have to be linear to be readable)
	S.TweenService:Create(inst, TweenInfo.new(dur(t), style == Enum.EasingStyle.Linear and style or Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
end

local function keyFromString(s)
	local sl = tostring(s):lower()
	for _, k in ipairs(Enum.KeyCode:GetEnumItems()) do
		if k.Name:lower() == sl or S.UserInputService:GetStringForKeyCode(k):lower() == sl then return k end
	end
end
local function keyStr(name)
	local pre, base = tostring(name):match("^(.*%+)([^%+]+)$") -- "Ctrl+G" -> "Ctrl+" .. keyStr("G")
	if pre then return pre .. keyStr(base) end
	local ok, s = pcall(function() return S.UserInputService:GetStringForKeyCode(Enum.KeyCode[name]) end)
	return (ok and s and s ~= "") and s or name
end

-- command line tokenizer: words, or "quoted text" as one argument
local function split(line)
	local out, buf, inq = {}, "", false
	for ch in line:gmatch(".") do
		if ch == '"' then
			inq = not inq
		elseif ch:find("%s") and not inq then
			if buf ~= "" then out[#out + 1] = buf; buf = "" end
		else
			buf = buf .. ch
		end
	end
	if buf ~= "" then out[#out + 1] = buf end
	return out
end

-- suggestion rank (lower = better): exact 0, prefix 1, name substring 3, description 5, search tags 6, no match nil
local function score(e, q)
	local best
	for _, n in ipairs(e.names) do
		if n == q then return 0 end
		if n:sub(1, #q) == q then best = math.min(best or 9, 1)
		elseif n:find(q, 1, true) then best = math.min(best or 9, 3) end
	end
	if best then return best end
	if e.desc ~= "" and e.desc:lower():find(q, 1, true) then return 5 end
	if e.tags and e.tags ~= "" and e.tags:lower():find(q, 1, true) then return 6 end
end
-- [/THEME]

-- [CMD_CORE]
-- ===== command core ========================================================
local ctx = {
	Players = S.Players, RunService = S.RunService, UIS = S.UserInputService, Lighting = S.Lighting,
	TeleportService = S.TeleportService, HttpService = S.HttpService, StarterGui = S.StarterGui,
	SocialService = S.SocialService, TextChatService = S.TextChatService,
	lp = S.Players.LocalPlayer, cam = workspace.CurrentCamera,
	Commands = {}, Aliases = {}, Meta = {},
	state = { conns = {}, muted = {}, esp = {}, saved = {}, active = {}, loopGen = 0, loopOf = {}, tools = {}, cc = {}, listen = {} },
	httpRequest = request,
}
local lp, state = ctx.lp, ctx.state

function ctx.notify(msg, secs)
	if ui.toast and cfg.toasts then ui.toast(tostring(msg), secs) end
end
function ctx.markMove() state.selfMove = os.clock() end -- tells anti teleport "this move was mine"
function ctx.val(k, arg) return (tonumber(arg) or cfg.mod[k .. "Def"]) * (cfg.mod[k .. "Mult"] or 1) end
function ctx.char() return lp.Character end
function ctx.hum() local c = lp.Character; return c and c:FindFirstChildOfClass("Humanoid") end
function ctx.root() local c = lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end

-- last seen position of every player, kept while they are in range (used by ctx.reach)
state.seen = state.seen or {} -- filled by the "seenTrack" connection below ctx.connect
-- back from where reach() parked you: back = true also returns you to where you were
function ctx.unpark(back)
	local pk, me = state.parked, ctx.root()
	state.parked = nil
	if not (pk and me) then return end
	if back then ctx.markMove(); me.CFrame = pk.cf end
	me.Anchored = pk.was
end
-- reach(p): the player's HumanoidRootPart, also when they are outside the streaming range (nil if impossible). Waits (yields).
-- 1) RequestStreamAroundAsync at their last seen position; 2) if the body still is not there, park your anchored character at the farthest
-- spot that streams the target in with a 100 stud margin (stream radius - 100, then half that, then on top of the spot). Needs a last seen position.
-- shortcut: the target is searched at where they were last seen; if they moved far since, it fails with a notice
function ctx.reach(p)
	local function rootOf() local c = p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local r = rootOf()
	if r or not workspace.StreamingEnabled then return r end
	local seen = state.seen[p.UserId]
	if not seen then ctx.notify(p.Name .. " is out of range and was never seen: no coordinates to load") return nil end
	local function wait4(t)
		local t0 = os.clock()
		repeat
			local x = rootOf()
			if x then return x end
			task.wait(0.1)
		until os.clock() - t0 > t
	end
	ctx.notify(("Loading the area around %s (last seen %d s ago)..."):format(p.Name, math.floor(os.clock() - seen.t)))
	if pcall(function() lp:RequestStreamAroundAsync(seen.pos, 4) end) then
		r = wait4(3)
		if r then return r end
	end
	local me = ctx.root()
	if not me then return nil end
	state.parked = state.parked or { cf = me.CFrame, was = me.Anchored }
	local okR, R = pcall(function() return workspace.StreamingTargetRadius end)
	R = okR and R or 1024
	local far = Vector3.new(me.Position.X - seen.pos.X, 0, me.Position.Z - seen.pos.Z)
	local dir = far.Magnitude > 1 and far.Unit or Vector3.xAxis
	for _, f in ipairs({ 1, 0.5, 0 }) do
		local at = seen.pos + dir * (math.min(math.max(R - 100, 0), far.Magnitude) * f) + Vector3.new(0, 20, 0)
		ctx.markMove(); me.Anchored = true; me.CFrame = CFrame.new(at)
		r = wait4(3)
		if r then return r end
		me = ctx.root() or me
	end
	ctx.unpark(true)
	ctx.notify("Could not load " .. p.Name .. ": they are not where they were last seen")
	return nil
end

function ctx.connect(key, signal, fn)
	if state.conns[key] then state.conns[key]:Disconnect() end
	state.conns[key] = signal:Connect(fn)
end
function ctx.disconnect(key)
	if state.conns[key] then state.conns[key]:Disconnect(); state.conns[key] = nil end
end
do -- last seen position of every player, once a second (for ctx.reach)
	local lastT = 0
	ctx.connect("seenDrop", game:GetService("Players").PlayerRemoving, function(pl) state.seen[pl.UserId] = nil end)
	ctx.connect("seenTrack", game:GetService("RunService").Heartbeat, function()
		local now = os.clock()
		if now - lastT < 1 then return end
		lastT = now
		for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
			local c = pl.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			if r then state.seen[pl.UserId] = { pos = r.Position, t = now } end
		end
	end)
end

-- me, all, others, random, exact name, or partial name / display name
function ctx.findPlayers(q)
	q = (q or "me"):lower()
	local all, out = S.Players:GetPlayers(), {}
	if q == "me" then return { lp } end
	if q == "all" then return all end
	if q == "others" then
		for _, p in ipairs(all) do if p ~= lp then out[#out + 1] = p end end
		return out
	end
	if q == "random" then return { all[math.random(#all)] } end
	for _, p in ipairs(all) do if p.Name:lower() == q then return { p } end end -- a username is unique, a display name is not
	for _, p in ipairs(all) do if p.DisplayName:lower() == q then return { p } end end
	for _, p in ipairs(all) do
		if p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q then out[#out + 1] = p end
	end
	return out
end
function ctx.findPlayer(q)
	local p = ctx.findPlayers(q)[1]
	if not p then ctx.notify("No player matches '" .. tostring(q) .. "'") end
	return p
end

-- shared by serverhop / smallserver
function ctx.hop(sort)
	if not ctx.httpRequest then return ctx.notify("No request function available") end
	local ok, data = pcall(function()
		local res = ctx.httpRequest({
			Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100"):format(game.PlaceId, sort),
			Method = "GET",
		})
		return S.HttpService:JSONDecode(res.Body).data
	end)
	if not ok or type(data) ~= "table" then return ctx.notify("Server list failed, try again in a moment") end
	for _, s in ipairs(data) do
		if s.id ~= game.JobId and s.playing < s.maxPlayers then
			return S.TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, lp)
		end
	end
	ctx.notify("No server found")
end

-- chat hook: one handler that chains the game's own, used by mute and anti spam
function ctx.hookChat()
	if S.chatHooked then return end
	S.chatHooked = true
	state.chat = { spam = false, spamN = 3, hist = {} }
	pcall(function()
		local TCS = S.TextChatService
		-- a script cannot read a callback property: only the executor's getcallbackvalue / getcallbackmember can hand us the game's own handler to chain
		local get = getcallbackvalue or getcallbackmember
		local okp, prev = false, nil
		if get then okp, prev = pcall(get, TCS, "OnIncomingMessage") end
		if type(prev) ~= "function" then okp, prev = false, nil end
		S.chatPrev = { ok = okp, fn = prev } -- unload puts prev back (nil = no handler, so ours never outlives the run)
		TCS.OnIncomingMessage = function(msg)
			local props = (okp and prev(msg)) or Instance.new("TextChatMessageProperties")
			local src = msg.TextSource
			if src then
				local uid = src.UserId
				if state.muted[uid] then props.Text = "" end
				if state.chat.spam and uid ~= lp.UserId then
					local h = state.chat.hist[uid] or {}
					state.chat.hist[uid] = h
					local now, same, key = os.clock(), 0, tostring(msg.Text):lower()
					for i = #h, 1, -1 do
						if now - h[i].t > 10 then table.remove(h, i) elseif h[i].k == key then same = same + 1 end
					end
					h[#h + 1] = { t = now, k = key }
					if same + 1 >= state.chat.spamN then props.Text = "" end
				end
			end
			return props
		end
	end)
end
-- voice: Roblox's own block call first; then every voice input of that player is muted and set to volume 0 in the game itself
local function voiceDevices(uid, on)
	local p = S.Players:GetPlayerByUserId(uid)
	if not p then return end
	state.voiceVol = state.voiceVol or {}
	for _, d in ipairs(p:GetDescendants()) do
		if d:IsA("AudioDeviceInput") then
			pcall(function()
				if on then
					if state.voiceVol[d] == nil then state.voiceVol[d] = d.Volume end
					d.Muted, d.Volume = true, 0
				else
					d.Muted, d.Volume = false, state.voiceVol[d] or 1
					state.voiceVol[d] = nil
				end
			end)
		end
	end
end
function ctx.setMuted(uid, on)
	state.muted[uid] = on or nil
	if on then ctx.hookChat(); ctx.setListen(uid, false) end
	pcall(function()
		local vc = game:GetService("VoiceChatInternal")
		local call = on and vc.SubscribeBlock or vc.SubscribeUnblock
		-- the method takes one id on some builds and a list on others
		if not pcall(call, vc, uid) then pcall(call, vc, { uid }) end
	end)
	voiceDevices(uid, on)
	if on and not S.voiceLoop then
		S.voiceLoop = true
		task.spawn(function() -- keeps them muted if their voice input is recreated
			while S.alive and next(state.muted) do
				task.wait(2)
				for id in pairs(state.muted) do voiceDevices(id, true) end
			end
			S.voiceLoop = false
		end)
	end
end
-- listen: wires a player's voice input straight into your own audio output (no emitter, so no distance and no panning),
-- like being in a call with them. The game's own proximity wires from that voice are switched off while listening, so nothing doubles.
-- shortcut: needs Audio API voice (Player.AudioDeviceInput) and only searches the player + character for the game's wires, when to upgrade: a game that wires elsewhere or still uses legacy voice.
local function quietWires(uid, rec)
	local p = S.Players:GetPlayerByUserId(uid)
	if not p then return ctx.setListen(uid, false) end
	for _, root in ipairs({ p, p.Character }) do
		for _, w in ipairs(root:GetDescendants()) do
			if w:IsA("Wire") and w.SourceInstance == rec.dev and w.TargetInstance ~= rec.out then
				if rec.wires[w] == nil then rec.wires[w] = w.Enabled end
				if w.Enabled then w.Enabled = false end -- the game switching it back on used to double the voice
			end
		end
	end
end
function ctx.setListen(uid, on)
	local old = state.listen[uid]
	if old then
		state.listen[uid] = nil
		pcall(function() old.out:Destroy() end)
		for w, was in pairs(old.wires) do pcall(function() w.Enabled = was end) end
	end
	if not on then return true end
	local p = S.Players:GetPlayerByUserId(uid)
	local dev = p and p:FindFirstChildWhichIsA("AudioDeviceInput", true)
	if not dev then return false, "Can't route this player's voice: the game doesn't use Audio API voice" end
	local ok = pcall(function()
		local out = Instance.new("AudioDeviceOutput")
		out.Name = "_klListen"
		out.Parent = S.SoundService
		-- voice -> pad (a fader set to the Preferences attenuation) -> your output
		local pad = Instance.new("AudioFader")
		pad.Name = "_klPad"
		pad.Volume = 10 ^ ((tonumber(cfg.listenPad) or 0) / 20)
		pad.Parent = out
		local w1, w2 = Instance.new("Wire"), Instance.new("Wire")
		w1.SourceInstance, w1.TargetInstance, w1.Parent = dev, pad, out
		w2.SourceInstance, w2.TargetInstance, w2.Parent = pad, out, out
		state.listen[uid] = { out = out, dev = dev, wires = {}, pad = pad }
		pcall(quietWires, uid, state.listen[uid]) -- the game's own voice off right now, not at the next sweep
	end)
	if not ok then return false, "Couldn't create the audio route in this executor" end
	if not S.listenLoop then
		S.listenLoop = true
		task.spawn(function() -- re-silences the game's own wires if they are recreated (respawn)
			while S.alive and next(state.listen) do
				for id, r in pairs(state.listen) do pcall(quietWires, id, r) end
				task.wait(0.5)
			end
			S.listenLoop = false
		end)
	end
	return true
end
-- voice activity: an AudioAnalyzer wired to the player's AudioDeviceInput (needs Audio API voice). Only exists while the Players tab is open.
function ctx.vcDrop(uid)
	local m = state.vcm and state.vcm[uid]
	if m then pcall(function() m.an:Destroy() end); state.vcm[uid] = nil end
end
function ctx.vcClear()
	for uid in pairs(state.vcm or {}) do ctx.vcDrop(uid) end
end
function ctx.vcMeter(uid)
	state.vcm, state.vcMiss = state.vcm or {}, state.vcMiss or {}
	local m = state.vcm[uid]
	if m and m.an.Parent and m.dev.Parent then return m end
	if m then ctx.vcDrop(uid) end
	if state.vcMiss[uid] and os.clock() - state.vcMiss[uid] < 3 then return nil end
	state.vcMiss[uid] = os.clock() -- no device yet: try again in 3 seconds, not every frame
	local p = S.Players:GetPlayerByUserId(uid)
	local dev = p and p:FindFirstChildWhichIsA("AudioDeviceInput", true)
	if not dev then return nil end
	pcall(function()
		local an = Instance.new("AudioAnalyzer")
		an.Name = "_klMeter"
		an.Parent = S.SoundService
		local w = Instance.new("Wire")
		w.SourceInstance, w.TargetInstance, w.Parent = dev, an, an
		state.vcm[uid] = { an = an, dev = dev }
	end)
	return state.vcm[uid]
end
-- per player volume: the player's voice input volume (0 = silent, 1 = normal, 2 = double). While muted it is stored and applied on unmute.
local function applyVol(uid, v)
	local p = S.Players:GetPlayerByUserId(uid)
	if not p then if state.vcVol then state.vcVol[uid] = nil end return end
	for _, d in ipairs(p:GetDescendants()) do
		if d:IsA("AudioDeviceInput") then
			if state.muted[uid] then
				if state.voiceVol and state.voiceVol[d] ~= nil then state.voiceVol[d] = v end
			else
				pcall(function() d.Volume = v end)
			end
		end
	end
end
function ctx.setVoiceVol(uid, v)
	state.vcVol = state.vcVol or {}
	state.vcVol[uid] = math.abs(v - 1) > 0.001 and v or nil
	applyVol(uid, v)
	if next(state.vcVol) and not S.volLoop then
		S.volLoop = true
		task.spawn(function() -- keeps the volume if the voice input is recreated
			while S.alive and next(state.vcVol) do
				task.wait(2)
				for id, vv in pairs(state.vcVol) do applyVol(id, vv) end
			end
			S.volLoop = false
		end)
	end
end
function ctx.applyListenPad() -- Preferences > Voice > listen pad, applied to everyone you are listening to right now
	local v = 10 ^ ((tonumber(cfg.listenPad) or 0) / 20)
	for _, rec in pairs(state.listen) do
		if rec.pad then pcall(function() rec.pad.Volume = v end) end
	end
end
function ctx.rememberLighting()
	local L = ctx.Lighting
	state.saved.light = state.saved.light or { Brightness = L.Brightness, ClockTime = L.ClockTime, FogEnd = L.FogEnd,
		GlobalShadows = L.GlobalShadows, Ambient = L.Ambient }
end

-- keybind tabs: cfg.binds is the Default tab, cfg.kbTabs the custom ones, cfg.kbActive = "none" | "default" | a tab id
function ctx.kbTab()
	for _, t in ipairs(cfg.kbTabs) do
		if t.id == cfg.kbActive then return t end
	end
end
function ctx.bindTable() -- binds of the selected tab (nil = No Keybinds)
	if cfg.kbActive == "none" then return nil end
	local t = ctx.kbTab()
	return t and t.binds or cfg.binds
end
function ctx.activeBinds() -- same, but an experience-specific tab stays silent in any other experience
	local t = ctx.kbTab()
	if t and t.es and t.exp ~= game.GameId then return nil end
	return ctx.bindTable()
end
-- a bind is one command line (string) or a list of them (table, cycles one per press); old saved strings still work
ctx.MODS = { LeftControl = "Ctrl", RightControl = "Ctrl", LeftShift = "Shift", RightShift = "Shift", LeftAlt = "Alt", RightAlt = "Alt" }
function ctx.normKey(s) -- "ctrl+g" -> "Ctrl+G"; a plain key -> its KeyCode name
	local parts = {}
	for p in tostring(s):gmatch("[^%+]+") do parts[#parts + 1] = p end
	local kc = keyFromString(parts[#parts] or s)
	if not kc then return nil end
	local seen, alias = {}, { ctrl = "Ctrl", control = "Ctrl", shift = "Shift", alt = "Alt" }
	for i = 1, #parts - 1 do
		local m = alias[parts[i]:lower()]
		if not m then return nil end
		seen[m] = true
	end
	local out = ""
	for _, m in ipairs({ "Ctrl", "Shift", "Alt" }) do if seen[m] then out = out .. m .. "+" end end
	return out .. kc.Name
end
function ctx.keyName(kc) -- key name with the modifiers currently held ("Ctrl+G"); a modifier on its own stays plain
	if ctx.MODS[kc.Name] then return kc.Name end
	local U, out = S.UserInputService, ""
	if U:IsKeyDown(Enum.KeyCode.LeftControl) or U:IsKeyDown(Enum.KeyCode.RightControl) then out = out .. "Ctrl+" end
	if U:IsKeyDown(Enum.KeyCode.LeftShift) or U:IsKeyDown(Enum.KeyCode.RightShift) then out = out .. "Shift+" end
	if U:IsKeyDown(Enum.KeyCode.LeftAlt) or U:IsKeyDown(Enum.KeyCode.RightAlt) then out = out .. "Alt+" end
	return out .. kc.Name
end
function ctx.bindList(key) -- commands of one key in the selected tab, as a fresh list
	local bt, out = ctx.bindTable(), {}
	local v = bt and bt[key]
	if type(v) == "table" then for _, c in ipairs(v) do out[#out + 1] = c end
	elseif v then out[1] = v end
	return out
end
function ctx.storeBinds(key, list)
	local bt = ctx.bindTable()
	if not bt then return ctx.notify("Keybinds are off. Pick Default or a tab in Keybinds first") end
	if #list == 0 then bt[key] = nil elseif #list == 1 then bt[key] = list[1] else bt[key] = list end
	if ctx.cycle then ctx.cycle[tostring(cfg.kbActive) .. "|" .. key] = nil end
	save()
	if ui.refreshKeys then ui.refreshKeys() end
end
function ctx.setBind(key, line) -- replaces everything on that key; nil / "" removes it
	local nk = ctx.normKey(key)
	if not nk then return ctx.notify("Unknown key: " .. tostring(key)) end
	ctx.storeBinds(nk, (line and line ~= "") and { line } or {})
end
function ctx.addBind(key, line) -- appends a command; two or more cycle on each press
	local nk = ctx.normKey(key)
	if not nk then return ctx.notify("Unknown key: " .. tostring(key)) end
	line = tostring(line):match("^%s*(.-)%s*$")
	if line == "" then return end
	local list = ctx.bindList(nk)
	list[#list + 1] = line
	ctx.storeBinds(nk, list)
end
function ctx.editBind(key, i, dir) -- dir 0 = remove command i, -1 / 1 = move it up / down
	local list = ctx.bindList(key)
	if not list[i] then return end
	if dir == 0 then table.remove(list, i)
	elseif list[i + dir] then list[i], list[i + dir] = list[i + dir], list[i] end
	ctx.storeBinds(key, list)
end
function ctx.fireBind(bt, kc) -- Ctrl+G wins over plain G; a list cycles one command per press
	local name = ctx.keyName(kc)
	local v = bt[name]
	if v == nil then name = kc.Name; v = bt[name] end
	if v == nil then return end
	if type(v) ~= "table" then return ctx.Run(v) end
	if #v == 0 then return end
	ctx.cycle = ctx.cycle or {}
	local id = tostring(cfg.kbActive) .. "|" .. name
	local n = (ctx.cycle[id] or 0) % #v + 1
	ctx.cycle[id] = n
	ctx.Run(v[n])
end
function ctx.setBarKey(s)
	local kc = keyFromString(s)
	if not kc then return ctx.notify("Unknown key: " .. tostring(s)) end
	cfg.barKey = kc.Name
	save()
	ui.apply()
end
function ctx.showCommands() ui.openBar("", true) end
function ctx.openTab(name) ui.setPanel(true); ui.selectTab(name) end

-- toggle commands and the command that turns each off (drives "Active effects" + Reset all)
local TOGGLES = {
	fly = "unfly", noclip = "clip", infjump = "uninfjump", follow = "unfollow", view = "unview", esp = "unesp",
	xray = "unxray", fullbright = "unfullbright", freeze = "thaw", invisible = "visible", noanim = "anim",
	float = "unfloat", cfly = "uncfly", jesus = "unjesus", tpwalk = "untpwalk", backpack = "unattach", baby = "unattach",
	headsit = "unattach", heada = "unattach", backa = "unattach", ragdoll = "unragdoll", spin = "unspin", antifling = "unantifling", antisit = "unantisit",
	antivoid = "unantivoid", antiteleport = "unantiteleport", antiknockback = "unantiknockback", antiattach = "unantiattach",
	antiearrape = "unantiearrape", antiblur = "unantiblur", antiafk = "unantiafk", antispam = "unantispam",
	antifreeze = "unantifreeze", blink = "unblink", ghost = "unghost", streamer = "unstreamer", name = "unname",
	lockmouse = "unlockmouse", ctrllock = "unctrllock", showfps = "unshowfps", hide = "unhide all", placeholder1 = "unplaceholder1", noplayercollision = "playercollision", hidecursor = "unhidecursor", look = "unlook", keepemotes = "unkeepemotes",
}
TOGGLES.spider, TOGGLES.serverpos = "unspider", "unserverpos"
TOGGLES.antigameplaypaused = "unantigameplaypaused"
-- commands that flip themselves on and off and keep state.active up to date on their own
local SELF = { float = true, blink = true, ghost = true, hide = true }

function ctx.resetAll()
	state.loopGen = state.loopGen + 1
	state.loopOf = {}
	state.noAct = true -- one notice for the whole reset instead of one per command
	for on in pairs(state.active) do
		state.active[on] = nil
		if TOGGLES[on] then pcall(ctx.Run, TOGGLES[on]) end
	end
	state.noAct = nil
	if ui.act then ui.act("stopall", "all effects off") end
end

function ctx.add(names, fn)
	if type(names) == "string" then names = { names } end
	ctx.Commands[names[1]] = fn
	for _, n in ipairs(names) do ctx.Aliases[n:lower()] = names[1] end -- Run looks names up lowercased
end

local NOACT = { panel = true, cmds = true, config = true, cfg = true, ui = true, exit = true, selftest = true, prefix = true, reload = true }
function ctx.Run(line)
	local args = split((line:gsub("^%s*;", "")))
	local name = table.remove(args, 1)
	if not name then return end
	-- loop^<command>: keeps re-running the command until ;break
	local loopName = name:match("^[Ll][Oo][Oo][Pp]%^(.+)$")
	local cmd = ctx.Aliases[(loopName or name):lower()]
	if not cmd then return ctx.notify("Unknown command: " .. (loopName or name)) end
	if loopName then
		local token, fn = {}, ctx.Commands[cmd]
		state.loopOf[cmd] = token
		state.active["loop^" .. cmd] = true
		task.spawn(function()
			while state.loopOf[cmd] == token and S.alive do
				if not (SELF[cmd] and state.active[cmd]) then pcall(fn, table.unpack(args)) end
				task.wait(0.15)
			end
			if state.loopOf[cmd] == nil then state.active["loop^" .. cmd] = nil end
		end)
		return
	end
	local ok, err = pcall(ctx.Commands[cmd], table.unpack(args))
	if not ok then return ctx.notify(cmd .. " error: " .. tostring(err)) end
	local who -- targeted command (<player> first): show the username, not what was typed ("fre" -> Fread)
	local meta = ctx.Meta[cmd]
	if meta and tostring(meta.args):find("^<player") and args[1] and not ({ me = 1, all = 1, others = 1, random = 1 })[args[1]:lower()] then
		local ps = ctx.findPlayers(args[1])
		if #ps == 1 then who = ps[1].Name end
	end
	if ui.act and not state.noAct and not NOACT[cmd] then -- activation notice: "fly 80", "esp on", "esp off"
		local offOf, cnt = nil, 0
		for on, off in pairs(TOGGLES) do if off == cmd then offOf, cnt = on, cnt + 1 end end
		local val = who and table.concat({ who, table.unpack(args, 2) }, " ") or table.concat(args, " ")
		if #val > 30 then val = val:sub(1, 28) .. ".." end
		if cnt > 0 then ui.act(cnt == 1 and offOf or (cmd:gsub("^un", "")), "off")
		elseif SELF[cmd] then ui.act(cmd, state.active[cmd] and "on" or "off")
		elseif TOGGLES[cmd] then ui.act(cmd, val ~= "" and val or "on")
		else ui.act(cmd, val) end
	end
	if SELF[cmd] then return end
	if TOGGLES[cmd] then
		state.active[cmd] = true
		state.who = state.who or {}
		state.who[cmd] = who
	else
		for on, off in pairs(TOGGLES) do
			if off == cmd then state.active[on] = nil; if state.who then state.who[on] = nil end end
		end
	end
end

-- command descriptions for the suggestion list. A command file can override with its own desc / args fields.
local META = {
	view = { "<player>", "Spectate a player" }, unview = { "", "Stop spectating" },
	["goto"] = { "<player>", "Teleport to a player" }, tpto = { "<x> <y> <z>", "Teleport to coordinates" },
	userinfo = { "<player>", "Show name, ID and account age" }, copyid = { "<player>", "Copy a player's user ID" },
	profile = { "<player>", "Copy a player's profile link" }, players = { "", "Open the Players tab" },
	follow = { "<player>", "Walk after a player" }, unfollow = { "", "Stop following" },
	friend = { "<player | username | id>", "Open the friend request prompt (not in the server: copies their profile link)" }, unfriend = { "<player>", "Open the unfriend prompt" },
	block = { "<player>", "Open the block prompt" }, unblock = { "<player>", "Open the unblock prompt" },
	mute = { "<player>", "Mute a player's voice and hide their chat" }, unmute = { "<player>", "Hear a player and see their chat again" },
	serverhop = { "", "Join another public server" }, smallserver = { "", "Join the emptiest public server" },
	rejoin = { "", "Rejoins you from the experience" }, jobid = { "", "Copy this server's job ID" },
	placeid = { "", "Copy the place ID" }, serverinfo = { "", "Show player count and uptime" },
	speed = { "[n]", "Set walk speed (default 16)" }, jumppower = { "[n]", "Set jump power (default 50)" },
	gravity = { "[n]", "Set gravity (default 196.2)" }, fov = { "[n]", "Set field of view (default 70)" },
	sit = { "", "Sit down" }, unsit = { "", "Stand up" },
	freeze = { "", "Anchor your character" }, thaw = { "", "Unanchor your character" },
	infjump = { "", "Jump again in mid-air" }, uninfjump = { "", "Turn infinite jump off" },
	noclip = { "", "Walk through walls" }, clip = { "", "Turn noclip off" },
	mousetp = { "", "Teleport to where your mouse points (bind it to a key)" },
	fly = { "[speed]", "Fly with WASD, E up and Q down" }, unfly = { "", "Stop flying" },
	reset = { "", "Respawn your character" }, invisible = { "", "Hide your avatar (only you see this)" },
	visible = { "", "Show your avatar again" }, noanim = { "", "Stop your animations" },
	anim = { "", "Turn your animations back on" }, tools = { "", "List the tools in your backpack" },
	esp = { "", "Highlight and tag other players" }, unesp = { "", "Remove player highlights" },
	fullbright = { "", "Light up the whole map" }, unfullbright = { "", "Restore the original lighting" },
	nofog = { "", "Remove fog" }, time = { "[hour]", "Set the time of day (default 14)" },
	xray = { "", "See through walls" }, unxray = { "", "Turn x-ray off" },
	maxzoom = { "[n]", "Set max camera zoom" }, minzoom = { "[n]", "Set min camera zoom" },
	fpscap = { "[n]", "Cap the frame rate (default 60)" }, console = { "", "Open the developer console" },
	cmds = { "", "Show every command" }, prefix = { "<key>", "Change the command bar key" },
	alias = { "<new> <command>", "Make a shortcut for a command" },
	loop = { "<n> <command>", "Run a command n times" }, unloop = { "", "Stop all running loops" },
	bind = { "<key> <command>", "Run a command when you press a key" }, unbind = { "<key>", "Remove a key bind" },
	stopall = { "", "Turn off every active effect" }, reload = { "", "Reload files from KLOSAD/commands" },
	panel = { "", "Open or close the panel" }, selftest = { "", "Run the built-in self check" },
}

-- extra words the search matches on, so "voice" finds mute, "teleport" finds goto, and so on
local TAGS = {
	view = "spectate watch camera", unview = "spectate watch camera", ["goto"] = "teleport tp player move", tpto = "teleport coordinates position",
	userinfo = "age id account info", copyid = "clipboard id", profile = "link url roblox", players = "list people", follow = "walk chase",
	unfollow = "walk chase", friend = "add request social", unfriend = "remove social", block = "report ignore social", unblock = "social",
	mute = "voice vc chat audio silence quiet speak talk", unmute = "voice vc chat audio hear speak talk",
	serverhop = "server change join new lobby", smallserver = "server empty low population", rejoin = "reconnect join again server",
	jobid = "server id", placeid = "game id", serverinfo = "server players uptime", speed = "walkspeed run fast", jumppower = "jump height",
	gravity = "fall float", fov = "camera zoom field view", sit = "seat", freeze = "anchor stop", thaw = "anchor", infjump = "infinite jump air",
	noclip = "wall collide ghost through", clip = "wall collide", mousetp = "teleport cursor click", fly = "flight air", unfly = "flight air",
	reset = "respawn die kill", invisible = "hide transparent", visible = "show transparent", noanim = "animation stop", anim = "animation",
	tools = "backpack items inventory", esp = "wallhack highlight name tag players", xray = "transparent walls see through",
	fullbright = "light bright dark", nofog = "fog view", time = "day night clock", maxzoom = "camera zoom", minzoom = "camera zoom",
	fpscap = "frame rate performance", console = "developer log output", cmds = "list commands help", prefix = "key bind bar",
	alias = "shortcut", loop = "repeat", bind = "key hotkey", stopall = "reset effects off", reload = "files commands",
}

-- sections for the scroll-all list of the command bar. Add a command's canonical name to a line to move it; anything not listed is "Other".
ctx.CAT_ORDER = { "Movement", "Defense", "Offense", "Players", "Voice", "Camera", "Visuals", "Character", "Privacy", "Server", "Tools", "rOSAD", "Other" }
local CATS = {
	Movement = "float unfloat cfly uncfly fly unfly jesus unjesus tpwalk untpwalk hheight follow unfollow sit unsit ragdoll unragdoll spin unspin look unlook speed jumppower goto tpto ptp mousetp freeze thaw infjump uninfjump noclip clip blink unblink ghost gravity clear",
	Defense = "antifling unantifling antisit unantisit antivoid unantivoid antiteleport unantiteleport antiknockback unantiknockback antiattach unantiattach antiearrape unantiearrape antiblur unantiblur antiafk unantiafk antispam unantispam antifreeze unantifreeze",
	Offense = "backpack baby headsit heada backa unattach",
	Players = "view unview userinfo copyid profile players friend unfriend block unblock hide unhide",
	Voice = "mute unmute listen unlisten nostereo stereo refreshaudio arjvc",
	Camera = "fov maxzoom minzoom freecam lockmouse unlockmouse enableshiftlock ctrllock unctrllock toggleshiftlock crosshair removecrosshair hidecursor unhidecursor",
	Visuals = "fullbright unfullbright esp unesp xray unxray nofog time showfps unshowfps baseplate removebaseplate",
	Character = "reset anim noanim invisible visible placeholder1 unplaceholder1 keepemotes unkeepemotes",
	Privacy = "streamer unstreamer name unname",
	Server = "serverhop smallserver serverinfo rejoin jobid placeid",
	Tools = "hlxp liu dex cobalt kelsec rspy alogger workwell tetris untetris workwellpf properties tooleditor klpfxp kill saveinstance freezesave tools console",
	rOSAD = "ui exit cmds config keeposad unkeeposad alias unalias bind unbind loop unloop breakloop prefix fpscap gamedefault text stopall reload panel selftest",
}
CATS.Movement = CATS.Movement .. " spider unspider"
CATS.Defense = CATS.Defense .. " antigameplaypaused unantigameplaypaused"
CATS.Visuals = CATS.Visuals .. " serverpos unserverpos"
CATS.Server = (CATS.Server or "") .. " region serverbrowser scanregions serverhop leave"
CATS.Players = CATS.Players .. " report"
ctx.catOf = {}
for cat, names in pairs(CATS) do
	for w in names:gmatch("%S+") do ctx.catOf[w] = cat end
end

function ctx.register(factory)
	local ok, mod = pcall(factory, ctx)
	if ok and type(mod) == "table" and type(mod.names) == "string" then mod.names = { mod.names } end
	if not ok or type(mod) ~= "table" or type(mod.names) ~= "table" or type(mod.names[1]) ~= "string" then -- names = {} used to stop the whole boot ("table index is nil")
		warn("[KLOSAD] bad command module: " .. tostring(mod))
		return
	end
	ctx.add(mod.names, mod.run)
	local m = META[mod.names[1]] or {}
	ctx.Meta[mod.names[1]] = { desc = mod.desc or m[2] or "", args = mod.args or m[1] or "", tags = mod.tags or TAGS[mod.names[1]] or "" }
	return mod
end

function ctx.loadFolder(path)
	if not (HAS_FS and HAS_LOAD and isfolder(path)) then return 0 end
	local n = 0
	for _, file in ipairs(listfiles(path)) do
		if isfolder(file) then
			n = n + ctx.loadFolder(file)
		elseif file:sub(-4) == ".lua" then
			local ok, factory = pcall(function() return loadstring(readfile(file))() end)
			if ok and type(factory) == "function" then
				ctx.register(factory)
				n = n + 1
			else
				warn("[KLOSAD] failed to load " .. file .. ": " .. tostring(factory))
			end
		end
	end
	return n
end

-- self check for the parser and the ranking (type: selftest)
function ctx.selftest()
	local t = split('say "hello world" x')
	assert(#t == 3 and t[2] == "hello world", "split")
	assert(parseHex("#ff0000") and not parseHex("red"), "hex")
	assert(score({ names = { "rejoin" }, desc = "" }, "re") == 1, "prefix rank")
	assert(score({ names = { "freecam" }, desc = "" }, "re") == 3, "substring rank")
	ctx.notify("selftest ok")
end

-- small commands that belong to the panel itself
local function mini(names, fn) ctx.register(function(c) return { names = names, run = fn } end) end
mini({ "stopall", "resetall" }, function() ctx.resetAll() end)
mini({ "reload" }, function() ctx.notify(("Reloaded %d command file(s)"):format(ctx.loadFolder(DIR .. "/commands"))) end)
mini({ "panel" }, function() ui.setPanel(not S.panelOpen) end)
mini({ "unbind" }, function(k) if k then ctx.setBind(k, nil) end end)
mini({ "unloop" }, function() ctx.Run("breakloop") end) -- loop^ loops watch state.loopOf, so bumping loopGen alone never stopped them
mini({ "selftest" }, function() ctx.selftest() end)
-- [/CMD_CORE]

-- [CMD_BUILTIN]
-- ===== built-in command files (generated from admin_cmds, bugs fixed) ======
local CMD = {}
CMD[#CMD + 1] = (function()
-- copyid.lua  |  aliases: copyid  |  args: q
return function(ctx)
	local findPlayer = ctx.findPlayer

	return {
		names = { "copyid" },
		run = function(q)
			local p = findPlayer(q)
			if p and setclipboard then setclipboard(tostring(p.UserId)) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- players.lua  |  aliases: players  |  args: none
return function(ctx)
	return {
		names = { "players" },
		run = function() ctx.openTab("Players") end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- profile.lua  |  aliases: profile  |  args: q
return function(ctx)
	local findPlayer = ctx.findPlayer

	return {
		names = { "profile" },
		run = function(q)
			local p = findPlayer(q)
			if p and setclipboard then setclipboard("https://www.roblox.com/users/" .. p.UserId .. "/profile") end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unfollow.lua  |  aliases: unfollow  |  args: none
return function(ctx)
	local disconnect = ctx.disconnect

	return {
		names = { "unfollow" },
		run = function()
			disconnect("follow")
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unview.lua  |  aliases: unview, unspectate  |  args: none
return function(ctx)
	local hum, state = ctx.hum, ctx.state

	return {
		names = { "unview", "unspectate" },
		run = function()
			ctx.unpark(true) -- back to where you were if the view had parked you
			if hum() then workspace.CurrentCamera.CameraSubject = hum() end
			state.viewing = nil
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- userinfo.lua  |  aliases: userinfo  |  args: q
return function(ctx)
	local findPlayer, notify = ctx.findPlayer, ctx.notify

	return {
		names = { "userinfo" },
		run = function(q)
			local p = findPlayer(q)
			if not p then return end
			notify(("%s (@%s) | ID %d | Age %d days"):format(p.DisplayName, p.Name, p.UserId, p.AccountAge))
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- view.lua  |  aliases: view, spectate  |  args: q
return function(ctx)
	local findPlayer, state, lp = ctx.findPlayer, ctx.state, ctx.lp

	return {
		names = { "view", "spectate" },
		run = function(q)
			local p = findPlayer(q)
			if not p or p == lp then return end
			-- your character never moves. While you watch: the area around the target's live position is requested from the server once a second
			-- (RequestStreamAroundAsync, the only streaming control a client has; ReplicationFocus is server side), the camera re-attaches when
			-- either of you respawns, and every name tag shows at any distance (restored when the last view ends). Ends on ;unview or when they leave
			state.viewing = p
			state.viewGen = (state.viewGen or 0) + 1
			state.viewRec = state.viewRec or {} -- shared by back-to-back views, so a switch never records our own far values as the originals
			local my, rec = state.viewGen, state.viewRec
			local function far(o, prop, v)
				rec[o] = rec[o] or {}
				if rec[o][prop] ~= nil then return end
				local ok, old = pcall(function() return o[prop] end)
				if ok and old ~= nil then rec[o][prop] = old; pcall(function() o[prop] = v end) end
			end
			local function body() local c = p.Character; return c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart") end
			if not body() then ctx.notify(p.Name .. " is not loaded yet: the camera moves to them once they stream in") end
			task.spawn(function()
				local asked = 0
				while state.viewGen == my and state.viewing == p do
					if not p.Parent then ctx.notify(p.Name .. " left the server: view ended"); ctx.Run("unview"); break end
					local h, r = body()
					local seen = state.seen[p.UserId]
					local pos = r and r.Position or (seen and seen.pos)
					if workspace.StreamingEnabled and pos and os.clock() - asked >= 1 then
						asked = os.clock()
						task.spawn(pcall, lp.RequestStreamAroundAsync, lp, pos, 2)
					end
					local cam = workspace.CurrentCamera
					if h and cam.CameraSubject ~= h then cam.CameraSubject = h end
					for _, pl in ipairs(ctx.Players:GetPlayers()) do
						local c = pl.Character
						local hm, head = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("Head")
						if hm then far(hm, "NameDisplayDistance", 1e5) end
						if head then for _, g in ipairs(head:GetChildren()) do if g:IsA("BillboardGui") then far(g, "MaxDistance", math.huge) end end end
					end
					task.wait(0.25)
				end
				if not state.viewing and state.viewRec == rec then
					for o, props in pairs(rec) do for k, v in pairs(props) do pcall(function() o[k] = v end) end end
					state.viewRec = nil
				end
			end)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- block.lua  |  aliases: block  |  args: q
return function(ctx)
	local findPlayer, StarterGui = ctx.findPlayer, ctx.StarterGui

	return {
		names = { "block" },
		run = function(q)
			local p = findPlayer(q)
			if p then StarterGui:SetCore("PromptBlockPlayer", p) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- friend.lua  |  aliases: friend  |  args: q
return function(ctx)
	local findPlayer, SocialService = ctx.findPlayer, ctx.SocialService

	return {
		names = { "friend" },
		run = function(q)
			local p = ctx.findPlayers(q)[1]
			if not p then -- not in this server: games can only prompt for players who are here, so hand over their profile instead
				local found, uid = pcall(function() return tonumber(q) or ctx.Players:GetUserIdFromNameAsync(q) end)
				if not (found and uid) then return ctx.notify("No player or Roblox user '" .. tostring(q) .. "'", 4) end
				if setclipboard then pcall(setclipboard, "https://www.roblox.com/users/" .. uid .. "/profile") end
				return ctx.notify("Not in this server: Roblox only lets a game send friend requests to players who are here. Their profile link is copied, open it and press Add Friend", 8)
			end
			local ok, err = pcall(function() SocialService:PromptFriendRequest(p) end)
			if not ok then
				ok, err = pcall(function() game:GetService("StarterGui"):SetCore("PromptSendFriendRequest", p) end)
			end
			if not ok then ctx.notify("Friend request failed: " .. tostring(err), 5) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- mute.lua  |  aliases: mute  |  args: q
return function(ctx)
	local findPlayers, lp = ctx.findPlayers, ctx.lp

	return {
		names = { "mute" },
		run = function(q)
			for _, p in ipairs(findPlayers(q)) do
				if p ~= lp then ctx.setMuted(p.UserId, true) end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unblock.lua  |  aliases: unblock  |  args: q
return function(ctx)
	local findPlayer, StarterGui = ctx.findPlayer, ctx.StarterGui

	return {
		names = { "unblock" },
		run = function(q)
			local p = findPlayer(q)
			if p then StarterGui:SetCore("PromptUnblockPlayer", p) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unfriend.lua  |  aliases: unfriend  |  args: q
return function(ctx)
	local findPlayer, SocialService = ctx.findPlayer, ctx.SocialService

	return {
		names = { "unfriend" },
		run = function(q)
			local p = findPlayer(q)
			if not p then return ctx.notify("Player not found") end
			local ok, err = pcall(function() SocialService:PromptUnfriend(p) end)
			if not ok then
				ok, err = pcall(function() game:GetService("StarterGui"):SetCore("PromptUnfriend", p) end)
			end
			if not ok then ctx.notify("Unfriend failed: " .. tostring(err), 5) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unmute.lua  |  aliases: unmute  |  args: q
return function(ctx)
	local findPlayers = ctx.findPlayers

	return {
		names = { "unmute" },
		run = function(q)
			for _, p in ipairs(findPlayers(q)) do ctx.setMuted(p.UserId, false) end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- jobid.lua  |  aliases: jobid  |  args: none
return function(ctx)
	local notify = ctx.notify

	return {
		names = { "jobid" },
		run = function()
			if setclipboard then setclipboard(game.JobId) end
			notify(game.JobId)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- placeid.lua  |  aliases: placeid  |  args: none
return function(ctx)
	local notify = ctx.notify

	return {
		names = { "placeid" },
		run = function()
			if setclipboard then setclipboard(tostring(game.PlaceId)) end
			notify(game.PlaceId)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- rejoin.lua  |  aliases: rejoin, rj  |  args: none
return function(ctx)
	local TeleportService, Players, lp = ctx.TeleportService, ctx.Players, ctx.lp

	return {
		names = { "rejoin", "rj" },
		run = function()
			if #Players:GetPlayers() == 1 then
				TeleportService:Teleport(game.PlaceId, lp)
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- serverhop.lua  |  aliases: serverhop, shop  |  args: none
return function(ctx)
	local hop = ctx.hop

	return {
		names = { "serverhop", "shop" }, args = "[US / EU / AS / city]", desc = "Hop to another server; with a region, to a scanned server there (run ;scanregions first)",
		run = function(q)
			if q and q ~= "" then return ctx.SRV.hop(q) end
			hop("Desc")
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- serverinfo.lua  |  aliases: serverinfo  |  args: none
return function(ctx)
	local Players, notify = ctx.Players, ctx.notify

	return {
		names = { "serverinfo" },
		run = function()
			notify(("%d players | up %ds"):format(#Players:GetPlayers(), math.floor(workspace.DistributedGameTime)))
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- smallserver.lua  |  aliases: smallserver, lowserver  |  args: none
return function(ctx)
	local hop = ctx.hop

	return {
		names = { "smallserver", "lowserver" },
		run = function()
			hop("Asc")
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- clip.lua  |  aliases: clip  |  args: none
return function(ctx)
	local disconnect = ctx.disconnect

	return {
		names = { "clip" },
		run = function()
			disconnect("noclip"); disconnect("noclip_safe")
			local nc = ctx.nc
			if nc then -- give every part the collision it had before noclip
				for part, was in pairs(nc.orig) do
					if part.Parent then part.CanCollide = was end
					nc.orig[part] = nil
				end
				nc.y = nil
				if nc.floor then nc.floor:Destroy(); nc.floor = nil end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- fov.lua  |  aliases: fov  |  args: n
return function(ctx)
	local cam = ctx.cam

	return {
		names = { "fov" },
		run = function(n)
			workspace.CurrentCamera.FieldOfView = tonumber(n) or 70 -- the live camera: a game can replace the one ctx.cam saw at load
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- gravity.lua  |  aliases: gravity  |  args: n
return function(ctx)
	return {
		names = { "gravity" },
		run = function(n)
			workspace.Gravity = tonumber(n) or 196.2
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- noclip.lua  |  aliases: noclip  |  args: none
-- FIX: noclip used to only turn collision off, so sinking under the floor / walking off the map was a free fall to the void.
-- Now an invisible solid floor (8x1x8) follows you at ground level (or the ;float level), so you walk through walls but never fall; clip restores collision and removes it.
return function(ctx)
	local connect, RunService, char = ctx.connect, ctx.RunService, ctx.char
	local nc = { orig = {} } -- orig = each part's CanCollide from before noclip, safe = last CFrame that had ground below
	ctx.nc = nc
	local rp = RaycastParams.new()
	rp.FilterType, rp.RespectCanCollide = Enum.RaycastFilterType.Exclude, true -- same rule the Humanoid's floor check uses

	return {
		names = { "noclip" },
		run = function()
			nc.y = nil
			connect("noclip", RunService.Stepped, function()
				local c = char()
				if not c then return end
				for _, v in ipairs(c:GetDescendants()) do
					if v:IsA("BasePart") then
						if nc.orig[v] == nil then nc.orig[v] = v.CanCollide end
						v.CanCollide = false
					end
				end
			end)
			local function floorStep(dt)
				local c = char()
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if not (hrp and hum) then return end
				local fl = nc.floor
				if not (fl and fl.Parent) then
					fl = Instance.new("Part")
					fl.Name, fl.Anchored, fl.CanCollide, fl.Transparency, fl.Size, fl.Locked = "_noclipFloor", true, true, 1, Vector3.new(8, 1, 8), true
					fl.Parent = workspace
					nc.floor = fl
				end
				local ex = { c, fl }
				for _, pl in ipairs(ctx.Players:GetPlayers()) do
					if pl ~= ctx.lp and pl.Character then ex[#ex + 1] = pl.Character end
				end
				rp.FilterDescendantsInstances = ex
				local feet = hrp.Position.Y - (hum.RigType == Enum.HumanoidRigType.R6 and 3 or (hum.HipHeight + hrp.Size.Y / 2))
				nc.y = nc.y or feet
				-- the level: ;float's level while floating, else the ground straight below you (up at once, down at 60 studs/s); nothing below = keep the last level
				local target = ctx.state.floatY
				if not target then
					local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rp)
					target = hit and hit.Position.Y
				end
				if target then nc.y = (target >= nc.y) and target or math.max(target, nc.y - 60 * dt) end
				nc.y = math.min(nc.y, feet + 1) -- never above your feet: it carries you, it never lifts you
				fl.CFrame = CFrame.new(hrp.Position.X, nc.y - 0.5, hrp.Position.Z)
			end
			floorStep(0.016) -- already solid under you in the first frame, no drop while it switches on
			connect("noclip_safe", RunService.Heartbeat, floorStep)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- uninfjump.lua  |  aliases: uninfjump  |  args: none
return function(ctx)
	local disconnect = ctx.disconnect

	return {
		names = { "uninfjump" },
		run = function()
			disconnect("infjump")
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unsit.lua  |  aliases: unsit  |  args: none
return function(ctx)
	local hum = ctx.hum

	return {
		names = { "unsit" },
		run = function()
			if hum() then hum().Sit = false end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- anim.lua  |  aliases: anim  |  args: none
return function(ctx)
	local char = ctx.char

	return {
		names = { "anim" },
		run = function()
			local a = char() and char():FindFirstChild("Animate")
			if a then a.Disabled = false end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- invisible.lua  |  aliases: invisible  |  args: none
return function(ctx)
	local char = ctx.char

	return {
		names = { "invisible" },
		run = function()
			if not char() then return end
			for _, v in ipairs(char():GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("Decal") then
					if v.Name ~= "HumanoidRootPart" then
						local iv = ctx.state.invis or {}
						ctx.state.invis = iv
						if iv[v] == nil then iv[v] = v.Transparency end -- remembered, so ;visible puts back parts that were see-through on purpose
						v.Transparency = 1
					end
				end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- noanim.lua  |  aliases: noanim  |  args: none
return function(ctx)
	local hum, char = ctx.hum, ctx.char

	return {
		names = { "noanim" },
		run = function()
			local h = hum()
			if not h then return end
			for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end
			local a = char():FindFirstChild("Animate")
			if a then a.Disabled = true end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- reset.lua  |  aliases: reset, respawn  |  args: none
return function(ctx)
	local hum = ctx.hum

	return {
		names = { "reset", "respawn" },
		run = function()
			if hum() then hum().Health = 0 end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- tools.lua  |  aliases: tools  |  args: none
return function(ctx)
	local lp, notify = ctx.lp, ctx.notify

	return {
		names = { "tools" },
		run = function()
			local names = {}
			local bp = lp:FindFirstChildOfClass("Backpack") -- missing for a moment while you respawn
			for _, t in ipairs(bp and bp:GetChildren() or {}) do names[#names + 1] = t.Name end
			notify(#names > 0 and table.concat(names, ", ") or "No tools in your backpack")
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- visible.lua  |  aliases: visible  |  args: none
return function(ctx)
	local char = ctx.char

	return {
		names = { "visible" },
		run = function()
			local iv = ctx.state.invis
			ctx.state.invis = nil
			if not char() then return end
			for _, v in ipairs(char():GetDescendants()) do
				if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then v.Transparency = iv and iv[v] or 0 end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- console.lua  |  aliases: console  |  args: none
return function(ctx)
	local StarterGui = ctx.StarterGui

	return {
		names = { "console" },
		run = function()
			StarterGui:SetCore("DevConsoleVisible", true)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- esp.lua  |  aliases: esp  |  args: none
return function(ctx)
	local Players, lp, state, connect = ctx.Players, ctx.lp, ctx.state, ctx.connect

	-- team colour unless Module Cfg has a custom colour on
	local function espCol(p)
		if cfg.mod.espCustom then return parseHex(cfg.mod.espColor) or Color3.fromRGB(255, 59, 59) end
		return p.Team and p.TeamColor.Color or Color3.new(1, 1, 1)
	end
	local function paintEsp(p)
		local o = state.esp[p]
		if not o then return end
		local c = espCol(p)
		if o[1].Parent then o[1].FillColor = c; o[1].OutlineColor = c end
		local tl = o[2]:FindFirstChildOfClass("TextLabel")
		if tl then tl.TextColor3 = c end
	end
	function ctx.espRefresh() for p in pairs(state.esp) do paintEsp(p) end end

	local function tag(p)
		if p == lp or not p.Character then return end
		for _, o in ipairs(state.esp[p] or {}) do o:Destroy() end
		local hl = Instance.new("Highlight")
		hl.FillTransparency = 0.7; hl.Name = "_esp"; hl.Parent = p.Character
		local bb = Instance.new("BillboardGui")
		bb.Name = "_espTag"; bb.Size = UDim2.fromOffset(120, 20)
		bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3, 0)
		local tl = Instance.new("TextLabel", bb)
		tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1
		tl.TextColor3 = Color3.new(1, 1, 1); tl.TextStrokeTransparency = 0
		tl.Text = p.Name -- username, not the display name
		bb.Adornee = p.Character:FindFirstChild("Head"); bb.Parent = p.Character
		state.esp[p] = { hl, bb }
		paintEsp(p)
	end

	local function watch(p)
		if p == lp then return end
		connect("espTeam_" .. p.UserId, p:GetPropertyChangedSignal("TeamColor"), function() paintEsp(p) end)
		connect("espChar_" .. p.UserId, p.CharacterAdded, function()
			task.wait(0.5)
			if ctx.state.conns["espChar_" .. p.UserId] and p.Parent then tag(p) end -- ;unesp during the wait: no new tag
		end)
	end

	return {
		names = { "esp" },
		run = function()
			for _, p in ipairs(Players:GetPlayers()) do tag(p); watch(p) end
			connect("espAdd", Players.PlayerAdded, watch)
			connect("espRem", Players.PlayerRemoving, function(p) -- a player who leaves takes their connections and tags along
				ctx.disconnect("espChar_" .. p.UserId); ctx.disconnect("espTeam_" .. p.UserId)
				for _, o in ipairs(ctx.state.esp[p] or {}) do pcall(function() o:Destroy() end) end
				ctx.state.esp[p] = nil
			end)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- fullbright.lua  |  aliases: fullbright  |  args: none
return function(ctx)
	local Lighting, state = ctx.Lighting, ctx.state

	return {
		names = { "fullbright", "fb" },
		run = function()
			state.saved.light = state.saved.light or {
				Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
				FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
			}
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.FogEnd = 1e9
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.new(1, 1, 1)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- maxzoom.lua  |  aliases: maxzoom  |  args: n
return function(ctx)
	local lp = ctx.lp

	return {
		names = { "maxzoom" },
		run = function(n)
			lp.CameraMaxZoomDistance = tonumber(n) or 128
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- minzoom.lua  |  aliases: minzoom  |  args: n
return function(ctx)
	local lp = ctx.lp

	return {
		names = { "minzoom" },
		run = function(n)
			lp.CameraMinZoomDistance = tonumber(n) or 0.5
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- nofog.lua  |  aliases: nofog  |  args: none
return function(ctx)
	local Lighting = ctx.Lighting

	return {
		names = { "nofog" },
		run = function()
			ctx.rememberLighting()
			Lighting.FogEnd = 1e9
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- time.lua  |  aliases: time  |  args: n
return function(ctx)
	local Lighting = ctx.Lighting

	return {
		names = { "time" },
		run = function(n)
			ctx.rememberLighting()
			Lighting.ClockTime = tonumber(n) or 14
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unesp.lua  |  aliases: unesp  |  args: none
return function(ctx)
	local disconnect, state = ctx.disconnect, ctx.state

	return {
		names = { "unesp" },
		run = function()
			disconnect("espAdd"); disconnect("espRem")
			for k in pairs(state.conns) do
				if k:find("^espChar_") or k:find("^espTeam_") then disconnect(k) end
			end
			for p, objs in pairs(state.esp) do
				for _, o in ipairs(objs) do o:Destroy() end
				state.esp[p] = nil
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unfullbright.lua  |  aliases: unfullbright  |  args: none
return function(ctx)
	local Lighting, state = ctx.Lighting, ctx.state

	return {
		names = { "unfullbright", "unfb" },
		run = function()
			for k, v in pairs(state.saved.light or {}) do Lighting[k] = v end
			state.saved.light = nil
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- unxray.lua  |  aliases: unxray  |  args: none
return function(ctx)
	return {
		names = { "unxray" },
		run = function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- xray.lua  |  aliases: xray  |  args: none
return function(ctx)
	local char = ctx.char

	return {
		names = { "xray" },
		run = function()
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and not (char() and v:IsDescendantOf(char())) and not v.Parent:FindFirstChildOfClass("Humanoid") then -- no character (respawning) = every part counts, not none
					v.LocalTransparencyModifier = 0.7
				end
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- alias.lua  |  aliases: alias  |  args: new, target
return function(ctx)
	local Aliases = ctx.Aliases

	return {
		names = { "alias" },
		run = function(new, target)
			local canon = target and Aliases[target:lower()]
			if new and canon then
				Aliases[new:lower()] = canon
				cfg.aliases[new:lower()] = canon -- saved: comes back on the next start
				save()
				ctx.notify("alias " .. new:lower() .. " = " .. canon)
			else
				ctx.notify("Usage: alias <new> <command>")
			end
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- bind.lua  |  aliases: bind  |  args: key, ...
return function(ctx)
	return {
		names = { "bind" },
		run = function(key, ...)
			if not key then return ctx.notify("Usage: bind <key> <command>") end
			ctx.setBind(key, table.concat({ ... }, " "))
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- loop.lua  |  aliases: loop  |  args: n, ...
return function(ctx)
	local Run, state = ctx.Run, ctx.state

	return {
		names = { "loop" },
		run = function(n, ...)
			local line, count, gen = table.concat({ ... }, " "), math.min(tonumber(n) or 1, 1000), state.loopGen
			task.spawn(function()
				for _ = 1, count do
					if state.loopGen ~= gen then break end
					Run(line)
					task.wait(0.1)
				end
			end)
		end,
	}
end
end)()
CMD[#CMD + 1] = (function()
-- prefix.lua  |  aliases: prefix  |  args: c
return function(ctx)
	return {
		names = { "prefix" },
		run = function(c)
			if c then ctx.setBarKey(c) else ctx.notify("Usage: prefix <key>") end
		end,
	}
end
end)()
for _, factory in ipairs(CMD) do ctx.register(factory) end
-- [/CMD_BUILTIN]

-- [CMD_EXTRA]
-- ===== commands from the notes ===============================================
-- (follow, fly, speed, jumppower, goto, tpto, mousetp, sit, freeze, thaw, infjump, fpscap, cmds are redefined here)
do
local mod = cfg.mod
local UIS, RS, Players = ctx.UIS, ctx.RunService, ctx.Players
local function def(names, args, desc, tags, run)
	ctx.register(function() return { names = names, args = args, desc = desc, tags = tags, run = run } end)
end
local function active(n, on) state.active[n] = on or nil end
local lastN = {}
local function dnotify(key, msg)
	if not mod.defNotify then return end
	local now = os.clock()
	if lastN[key] and now - lastN[key] < 3 then return end
	lastN[key] = now
	ctx.notify(msg)
end
local function typing() return UIS:GetFocusedTextBox() ~= nil end
local function down(k) return UIS:IsKeyDown(k) and not typing() end

-- What the game had when we first loaded, for ;gamedefault. Kept in getgenv so running this script again later
-- doesn't "capture" values that an earlier run already changed.
local H0 = ctx.hum()
env.KLOSAD_DEF = env.KLOSAD_DEF or {
	ws = H0 and H0.WalkSpeed or 16, jp = H0 and H0.JumpPower or 50, jh = H0 and H0.JumpHeight or 7.2, ujp = H0 and H0.UseJumpPower,
	hip = H0 and H0.HipHeight or 2, grav = workspace.Gravity, fov = workspace.CurrentCamera.FieldOfView,
	minz = lp.CameraMinZoomDistance, maxz = lp.CameraMaxZoomDistance,
	light = { Brightness = ctx.Lighting.Brightness, ClockTime = ctx.Lighting.ClockTime, FogEnd = ctx.Lighting.FogEnd,
		GlobalShadows = ctx.Lighting.GlobalShadows, Ambient = ctx.Lighting.Ambient },
}
state.defaults = env.KLOSAD_DEF

-- a fresh character has the server's values, before any command touched it
ctx.connect("defCap", lp.CharacterAdded, function(c)
	task.wait(1.5)
	local hh = ctx.hum()
	if state.blink or not hh or hh.Parent ~= c then return end
	local d = state.defaults
	d.ws, d.jp, d.jh, d.ujp, d.hip = hh.WalkSpeed, hh.JumpPower, hh.JumpHeight, hh.UseJumpPower, hh.HipHeight
end)

-- ---- shared helpers other files use (the UI part calls these) ----
function ctx.runSource(src, name)
	if not HAS_LOAD then return ctx.notify("loadstring isn't available in this executor") end
	local fn, err = loadstring(src)
	if not fn then return ctx.notify(name .. ": " .. tostring(err)) end
	task.spawn(function()
		local ok, e = pcall(fn)
		if not ok then ctx.notify(name .. " error: " .. tostring(e)) end
	end)
end
function ctx.fetch(url)
	if request then
		local ok, res = pcall(request, { Url = url, Method = "GET" })
		if ok and res and res.StatusCode == 200 then return res.Body end
		return nil, ok and ("HTTP " .. tostring(res and res.StatusCode)) or tostring(res)
	end
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok then return body end
	return nil, tostring(body)
end

-- ===== MODIFIERS =====
def({ "breakloop", "break" }, "[command]", "Stop loop^ loops (all, or just one command)", "stop loop repeat", function(q)
	state.loopGen = state.loopGen + 1
	if q and ctx.Aliases[q:lower()] then
		state.loopOf[ctx.Aliases[q:lower()]] = nil
		state.active["loop^" .. ctx.Aliases[q:lower()]] = nil
	else
		for k in pairs(state.loopOf) do state.active["loop^" .. k] = nil end
		state.loopOf = {}
	end
end)

-- ===== MOVEMENT =====
-- float: an invisible client-side platform under you. Drops of up to the stair height (Module Cfg) still let you fall
-- (stairs, small ledges); anything deeper is caught by the platform, which keeps your level. E / Q move it, running float
-- again re-centres it under you, unfloat removes it.
local function unfloat()
	ctx.disconnect("float")
	if state.floatPart then state.floatPart:Destroy(); state.floatPart = nil end
	state.floatY = nil
	active("float", nil)
end
local function feetY()
	local r, h = ctx.root(), ctx.hum()
	if not (r and h) then return nil end
	local off = h.RigType == Enum.HumanoidRigType.R6 and 3 or (h.HipHeight + r.Size.Y / 2)
	return r.Position.Y - off
end
def({ "float" }, "", "Float over drops deeper than the stair height (E up, Q down, run again to reset)", "hover levitate air step platform", function()
	local fy = feetY()
	if not fy then return end
	state.floatY, state.eLift = fy, nil
	if not state.floatPart then
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.Transparency, p.Size = "_float", true, false, 1, Vector3.new(8, 1, 8)
		p.Parent = workspace
		state.floatPart = p
	end
	ctx.connect("float", RS.Heartbeat, function(dt)
		local r, h, p = ctx.root(), ctx.hum(), state.floatPart
		if not (r and h and p and p.Parent) then return end
		local curF = feetY()
		if down(Enum.KeyCode.E) then -- E lifts you off the ground too: the platform starts right under your feet
			state.eLift = true
			if curF then state.floatY = math.max(state.floatY, curF) end
			state.floatY = state.floatY + 24 * dt
		end
		if down(Enum.KeyCode.Q) then state.floatY = state.floatY - 24 * dt end
		local params = RaycastParams.new()
		params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true -- solid things only; other players are not ground
		local ex = { ctx.char(), p }
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= lp and pl.Character then ex[#ex + 1] = pl.Character end
		end
		params.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), params)
		local groundY = hit and hit.Position.Y or -math.huge
		local cur = feetY()
		-- standing on real ground (a stair you dropped onto, a hill): that is the new level
		if state.eLift and state.floatY <= groundY + 0.1 then state.eLift = nil end -- back down on the ground: normal float again
		if hit and cur and h.FloorMaterial ~= Enum.Material.Air and math.abs(cur - groundY) < 1.5 and not state.eLift then state.floatY = groundY end
		p.CFrame = CFrame.new(r.Position.X, state.floatY - 0.5, r.Position.Z)
		p.CanCollide = state.eLift or (state.floatY - groundY) > mod.floatStep
	end)
	active("float", true)
end)
def({ "unfloat" }, "", "Remove the float platform", "hover levitate air step platform", unfloat)

def({ "cfly" }, "[speed]", "CFrame fly (WASD, E up, Q down)", "flight air cframe", function(spd)
	local r, h = ctx.root(), ctx.hum()
	if not (r and h) then return end
	local s = ctx.val("fly", spd)
	h.PlatformStand = true
	ctx.connect("cfly", RS.Heartbeat, function(dt)
		local rr, cam = ctx.root(), workspace.CurrentCamera
		if not rr then return end
		local d = Vector3.zero
		if down(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
		if down(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
		if down(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
		if down(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
		if down(Enum.KeyCode.E) then d = d + Vector3.yAxis end
		if down(Enum.KeyCode.Q) then d = d - Vector3.yAxis end
		rr.AssemblyLinearVelocity = Vector3.zero
		if d.Magnitude > 0 then rr.CFrame = rr.CFrame + d.Unit * s * dt end
	end)
end)
def({ "uncfly" }, "", "Stop CFrame flying", "flight air cframe", function()
	ctx.disconnect("cfly")
	if ctx.hum() then ctx.hum().PlatformStand = false end
end)

def({ "fly" }, "[speed]", "Fly with WASD, E up and Q down", "flight air", function(spd)
	local s = ctx.val("fly", spd)
	local r, h = ctx.root(), ctx.hum()
	if not (r and h) then return end
	for _, n in ipairs({ "_flyBV", "_flyBG" }) do
		local o = r:FindFirstChild(n)
		if o then o:Destroy() end
	end
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.one * 1e9; bv.Velocity = Vector3.zero; bv.Name = "_flyBV"
	local bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.one * 1e9; bg.P = 9e4; bg.Name = "_flyBG"
	bv.Parent, bg.Parent = r, r
	h.PlatformStand = true
	ctx.connect("fly", RS.RenderStepped, function()
		if not bv.Parent then return ctx.Run("unfly") end -- respawned: the movers died with the old body
		local cam = workspace.CurrentCamera
		local d = Vector3.zero
		if down(Enum.KeyCode.W) then d = d + cam.CFrame.LookVector end
		if down(Enum.KeyCode.S) then d = d - cam.CFrame.LookVector end
		if down(Enum.KeyCode.D) then d = d + cam.CFrame.RightVector end
		if down(Enum.KeyCode.A) then d = d - cam.CFrame.RightVector end
		if down(Enum.KeyCode.E) then d = d + Vector3.yAxis end
		if down(Enum.KeyCode.Q) then d = d - Vector3.yAxis end
		bv.Velocity = d.Magnitude > 0 and d.Unit * s or Vector3.zero
		bg.CFrame = cam.CFrame
	end)
end)
def({ "unfly" }, "", "Stop flying", "flight air", function()
	ctx.disconnect("fly")
	local r = ctx.root()
	if r then
		for _, n in ipairs({ "_flyBV", "_flyBG" }) do
			local o = r:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
	if ctx.hum() then ctx.hum().PlatformStand = false end
end)

def({ "jesus" }, "", "Walk on water", "water swim float", function()
	if state.jesusPart then pcall(function() state.jesusPart:Destroy() end) end -- one platform, whatever how often it runs (loop^jesus)
	local plat = Instance.new("Part")
	plat.Name, plat.Anchored, plat.CanCollide, plat.Transparency, plat.Size = "_jesus", true, false, 1, Vector3.new(12, 1, 12)
	plat.Parent = workspace
	state.jesusPart = plat
	local waterY
	ctx.connect("jesus", RS.Heartbeat, function()
		local r, h = ctx.root(), ctx.hum()
		if not (r and h) then return end
		if h:GetState() == Enum.HumanoidStateType.Swimming or h.FloorMaterial == Enum.Material.Water then
			waterY = r.Position.Y - 3.2
		end
		if waterY and r.Position.Y < waterY + 12 then
			plat.CFrame = CFrame.new(r.Position.X, waterY, r.Position.Z)
			plat.CanCollide = true
		else
			plat.CanCollide = false
			if waterY and r.Position.Y >= waterY + 12 then waterY = nil end
		end
	end)
end)
def({ "unjesus" }, "", "Stop walking on water", "water swim", function()
	ctx.disconnect("jesus")
	if state.jesusPart then state.jesusPart:Destroy(); state.jesusPart = nil end
end)

def({ "tpwalk", "cwalk" }, "[multiplier]", "Move faster through CFrame (mode and cap in Module Cfg)", "speed walkspeed fast", function(m)
	local mult = math.min(tonumber(m) or mod.tpDef, mod.tpCap)
	ctx.connect("tpwalk", RS.Heartbeat, function(dt)
		local r, h = ctx.root(), ctx.hum()
		if not (r and h) then return end
		local md = h.MoveDirection
		if md.Magnitude > 0 then
			local extra = (mod.tpMode == "Additive") and mult or h.WalkSpeed * (mult - 1)
			r.CFrame = r.CFrame + md * extra * dt
		end
	end)
end)
def({ "untpwalk", "uncwalk" }, "", "Stop CFrame walking", "speed walkspeed", function() ctx.disconnect("tpwalk") end)

def({ "hheight", "hipheight" }, "[number]", "Change your hip height", "height ground", function(n)
	if ctx.hum() then ctx.hum().HipHeight = tonumber(n) or state.defaults.hip end
end)

def({ "follow" }, "<player> [radius]", "Follow a player and stay within a radius (jumps over obstacles)", "walk chase", function(q, rad)
	local p = ctx.findPlayer(q)
	if not p then return end
	if tonumber(rad) then state.lastRadius = tonumber(rad) end
	local radius = state.lastRadius or mod.followRadius
	ctx.connect("follow", RS.Heartbeat, function()
		local r, h = ctx.root(), ctx.hum()
		local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if not (r and h and tr) then return end
		local delta = tr.Position - r.Position
		local flat = Vector3.new(delta.X, 0, delta.Z)
		if flat.Magnitude > radius then
			h:MoveTo(tr.Position - flat.Unit * math.max(radius - 1, 0))
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { ctx.char(), p.Character }
			if workspace:Raycast(r.Position - Vector3.new(0, 1.5, 0), flat.Unit * 3, params) then h.Jump = true end
		end
	end)
end)
def({ "unfollow" }, "", "Stop following", "walk chase", function() ctx.disconnect("follow") end)

-- backpack / baby / headsit share one attach loop; jump detaches
-- ===== SERVER SYNC: what the server sees of you =====
-- Prediction: while attached, the position that gets replicated is shifted by the target's velocity times your ping. The shift is made after
-- your frame is simulated and undone first thing in the next frame (RenderStepped, priority First), so your own screen and physics never see it.
-- Server position: a ghost drawn where the server should have you now = your replicated path, delayed by half your ping.
local SYNC = { real = nil, root = nil, hist = {}, parts = {}, gm = nil, bound = nil, ping = 0.1, pingT = 0 }
local function pingSec()
	local ok, v = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
	if ok and tonumber(v) and v > 0 then return v / 1000 end
	local ok2, w = pcall(function() return lp:GetNetworkPing() * 2 end)
	return ok2 and tonumber(w) or 0.1
end
local function histAt(t)
	local hs = SYNC.hist
	for i = #hs, 1, -1 do
		if hs[i][1] <= t then
			local nx = hs[i + 1]
			if nx then return hs[i][2]:Lerp(nx[2], math.clamp((t - hs[i][1]) / math.max(nx[1] - hs[i][1], 1e-4), 0, 1)) end
			return hs[i][2]
		end
	end
	return hs[1] and hs[1][2]
end
local function ghostClear()
	if SYNC.gm then pcall(function() SYNC.gm:Destroy() end) end
	SYNC.gm, SYNC.parts = nil, {}
end
local function ghostBuild()
	ghostClear()
	local c = ctx.char()
	if not c then return end
	local gm = Instance.new("Folder")
	gm.Name = "_KLServerPos"
	for _, p in ipairs(c:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			local g = Instance.new("Part")
			g.Name, g.Size, g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = p.Name, p.Size, true, false, false, false, false
			g.Material, g.Color, g.Transparency = Enum.Material.Neon, Color3.fromRGB(255, 140, 0), 0.6
			g.Parent = gm
			SYNC.parts[#SYNC.parts + 1] = { src = p, g = g }
		end
	end
	gm.Parent = workspace
	SYNC.gm = gm
end
local function syncStep()
	local r = ctx.root()
	if not r then return end
	local now = os.clock()
	local hs = SYNC.hist
	hs[#hs + 1] = { now, r.CFrame } -- this is what was replicated last frame (shifted if a shift was active)
	while #hs > 2 and now - hs[2][1] > 1.5 do table.remove(hs, 1) end
	if SYNC.real then
		if SYNC.root == r then r.CFrame = SYNC.real end
		SYNC.real = nil
	end
	if now - SYNC.pingT > 0.5 then SYNC.pingT, SYNC.ping = now, pingSec() end
	if SYNC.gm then
		local scf = histAt(now - SYNC.ping / 2 - 0.03)
		if not scf then return end
		local near = (scf.Position - r.Position).Magnitude < math.clamp(tonumber(mod.srvHide) or 0.5, 0, 5)
		for _, e in ipairs(SYNC.parts) do
			if near or not e.src.Parent then
				e.g.Transparency = 1
			else
				e.g.Transparency = 0.6
				e.g.CFrame = scf * r.CFrame:ToObjectSpace(e.src.CFrame)
			end
		end
	end
end
local function syncBind(need)
	if need and not SYNC.bound then
		SYNC.bound = true
		RS:BindToRenderStep("KLSync", Enum.RenderPriority.First.Value, syncStep)
	elseif not need and SYNC.bound then
		SYNC.bound = nil
		pcall(function() RS:UnbindFromRenderStep("KLSync") end)
		if SYNC.real and SYNC.root then pcall(function() SYNC.root.CFrame = SYNC.real end) end
		SYNC.real, SYNC.hist = nil, {}
	end
end
function SYNC.shift(r, cf, off)
	SYNC.real, SYNC.root = cf, r
	r.CFrame = cf + off
end
function ctx.srvApply(on)
	if on then
		ghostBuild()
		ctx.connect("srvChar", lp.CharacterAdded, function()
			task.wait(1.5)
			if mod.srvShow and S.alive then ghostBuild() end
		end)
	else
		ctx.disconnect("srvChar")
		ghostClear()
	end
	active("serverpos", on or nil)
	syncBind(on or mod.predOn)
end
function ctx.srvRefresh()
	local want = mod.srvShow == true
	if want ~= (SYNC.gm ~= nil) then ctx.srvApply(want) else syncBind(want or mod.predOn) end
end
function ctx.syncStop() ctx.srvApply(false); syncBind(false) end
def({ "serverpos", "showpos" }, "", "Show where the server has you (a ghost; hides when it is close to your position)", "server position lag ping ghost desync", function()
	mod.srvShow = true; save()
	ctx.srvApply(true)
end)
def({ "unserverpos", "unshowpos" }, "", "Hide the server position ghost", "server position lag ping ghost desync", function()
	if S.alive then mod.srvShow = false; save() end
	ctx.srvApply(false)
end)
if mod.predOn or mod.srvShow then task.defer(function() if mod.srvShow then ctx.srvApply(true) else syncBind(true) end end) end

local function detach()
	ctx.disconnect("attach"); ctx.disconnect("attachJump")
	state.attach = nil
	local h = ctx.hum()
	if h then
		h.Sit = false
		if state.attachPS then -- heada / backa: undo PlatformStand and stand back up
			h.PlatformStand = false
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
			local r = ctx.root()
			if r then r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
		end
	end
	state.attachPS = nil
end
local function attach(kind, q, off)
	local p = ctx.findPlayer(q)
	if not p or p == lp then return end
	detach()
	state.attach = kind
	local ps = kind == "heada" or kind == "backa" -- these two use PlatformStand instead of sitting
	state.attachPS = ps or nil
	local h = ctx.hum()
	if h then
		if ps then h.PlatformStand = true else h.Sit = true end
	end
	local lastP, lastT, tvel = nil, 0, Vector3.zero
	ctx.connect("attach", ps and RS.PreSimulation or RS.Heartbeat, function()
		if not p.Parent then return ctx.Run("unattach") end -- the target left: let go (it kept anti sit / anti knockback off and you in PlatformStand)
		local r, tc = ctx.root(), p.Character
		local tt = tc and (tc:FindFirstChild("UpperTorso") or tc:FindFirstChild("Torso") or tc:FindFirstChild("HumanoidRootPart"))
		if not (r and tt) then return end
		local cf
		if kind == "backpack" then
			cf = tt.CFrame * CFrame.new(0, mod.bpHeight, tonumber(off) or mod.bpDist) * CFrame.Angles(0, math.pi, 0)
		elseif kind == "baby" then
			cf = tt.CFrame * CFrame.new(0, mod.babyHeight, -(tonumber(off) or mod.babyDist)) * CFrame.Angles(0, math.rad(180 + mod.babyRot), 0) * CFrame.Angles(math.rad(tonumber(mod.babyLean) or 0), 0, 0)
		elseif ps then -- heada / backa: offsets + sweep come from Module Cfg (headXxx / backXxx), read every frame so edits apply live
			local pre = kind == "heada" and "head" or "back"
			local d = tonumber(off) or mod[pre .. "Dist"]
			if mod[pre .. "Sweep"] then d = math.max(0, d + math.sin(os.clock() * mod[pre .. "SweepSpeed"]) * mod[pre .. "SweepAmp"]) end
			local hh = ctx.hum()
			if hh then hh.PlatformStand = true end
			for _, part in ipairs(r.Parent:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
			if kind == "heada" then -- in front of the face, turned to look at it
				cf = (tc:FindFirstChild("Head") or tt).CFrame * CFrame.new(mod.headSide, mod.headHeight, -d) * CFrame.Angles(0, math.pi, 0)
			else -- behind the back, looking the same way as the target
				cf = tt.CFrame * CFrame.new(mod.backSide, mod.backHeight, d)
			end
			r.AssemblyAngularVelocity = Vector3.zero
		else
			local head = tc:FindFirstChild("Head") or tt
			cf = head.CFrame * CFrame.new(0, head.Size.Y / 2 + (tonumber(off) or 1.6), 0)
		end
		r.CFrame = cf
		r.AssemblyLinearVelocity = Vector3.zero
		ctx.markMove()
		if mod.predOn then -- the target's velocity (from its positions) times your ping: where it will be when the server sees you
			local now, pp = os.clock(), tt.Position
			if lastP and now > lastT then tvel = tvel:Lerp((pp - lastP) / (now - lastT), 0.35) end
			lastP, lastT = pp, now
			local off = tvel * (SYNC.ping * (tonumber(mod.predMult) or 1))
			if off.Magnitude > 30 then off = off.Unit * 30 end
			SYNC.shift(r, cf, off)
		end
	end)
	ctx.connect("attachJump", UIS.JumpRequest, detach)
end
def({ "backpack", "bp" }, "<player> [offset]", "Ride on a player's back (jump to detach)", "carry piggyback attach", function(q, o) attach("backpack", q, o) end)
def({ "baby" }, "<player> [offset]", "Sit in front of a player like a baby (jump to detach)", "carry attach", function(q, o) attach("baby", q, o) end)
def({ "headsit" }, "<player>", "Sit on a player's head (jump to detach)", "attach head", function(q) attach("headsit", q) end)
def({ "heada", "headattach" }, "<player> [distance]", "Attach in front of a player's head, facing them (jump to detach)", "attach head face", function(q, o) attach("heada", q, o) end)
def({ "backa", "backattach" }, "<player> [distance]", "Attach behind a player's back (jump to detach)", "attach back carry", function(q, o) attach("backa", q, o) end)
def({ "unattach" }, "", "Detach from a player", "backpack baby headsit heada backa", detach)
def({ "config", "cfg" }, "", "Open Module Cfg in the panel", "module settings options values defaults", function() ctx.openTab("Module Cfg") end)

-- stand up for real: Sit = false alone leaves the chair's weld on you, so you hang upright in the air ("float").
-- Remove any weld between you and something that is not you (in the seat, or in your root part for custom clickable chairs), then jump once.
function ctx.eject()
	local h, c, r = ctx.hum(), ctx.char(), ctx.root()
	if not (h and c) then return end
	state.ejectAt = os.clock()
	local function strip(holder)
		if not holder then return end
		for _, w in ipairs(holder:GetChildren()) do
			if w:IsA("JointInstance") or w:IsA("WeldConstraint") then
				local a, b = w.Part0, w.Part1
				if a and b and a:IsDescendantOf(c) ~= b:IsDescendantOf(c) then w:Destroy() end
			end
		end
	end
	strip(h.SeatPart); strip(r)
	h.Sit = false
	h:ChangeState(Enum.HumanoidStateType.Jumping)
end
def({ "sit" }, "", "Sit down", "seat", function()
	if state.active.antisit then return ctx.notify("Anti sit is on. Run unantisit first") end
	state.allowSit = os.clock()
	if ctx.hum() then ctx.hum().Sit = true end
end)
def({ "unsit" }, "", "Stand up", "seat", function()
	state.allowSit = os.clock()
	ctx.eject()
end)

-- ragdoll: the whole body goes stiff (PlatformStand + Physics state, every joint stays intact), so you drop like a plank and everyone sees it, not just you
def({ "ragdoll", "rag" }, "", "Go stiff and fall over until you press space or move (everyone sees it)", "fall limp stiff plank physics", function()
	local h, r = ctx.hum(), ctx.root()
	if not (h and r) then return end
	if state.ragdollStop then state.ragdollStop() end
	h.PlatformStand = true
	h:ChangeState(Enum.HumanoidStateType.Physics)
	local an = h:FindFirstChildOfClass("Animator")
	local frozen = {}
	local function freeze() -- hold the current pose so the limbs stay stiff
		if not an then return end
		for _, t in ipairs(an:GetPlayingAnimationTracks()) do
			if frozen[t] == nil then frozen[t] = t.Speed; pcall(function() t:AdjustSpeed(0) end) end
		end
	end
	freeze()
	r.AssemblyAngularVelocity = r.CFrame.RightVector * 2 -- tips you over even when you stand perfectly straight
	if mod.ragdollBlock then
		pcall(function() ctx.StarterGui:SetCore("ResetButtonCallback", false) end)
		state.resetBlocked = true
	end
	local function stop()
		ctx.disconnect("ragdoll"); ctx.disconnect("ragdollJump")
		for t, sp in pairs(frozen) do pcall(function() t:AdjustSpeed(sp) end) end
		local hh = ctx.hum()
		if hh then hh.PlatformStand = false; hh:ChangeState(Enum.HumanoidStateType.GettingUp) end
		if state.resetBlocked then
			pcall(function() ctx.StarterGui:SetCore("ResetButtonCallback", true) end)
			state.resetBlocked = nil
		end
		state.ragdollStop = nil
		active("ragdoll", nil)
	end
	state.ragdollStop = stop
	ctx.connect("ragdollJump", UIS.JumpRequest, stop)
	ctx.connect("ragdoll", RS.Heartbeat, function()
		local hh = ctx.hum()
		if not hh then return end
		if hh.MoveDirection.Magnitude > 0 then return stop() end
		if not hh.PlatformStand then hh.PlatformStand = true end
		if hh:GetState() ~= Enum.HumanoidStateType.Physics then hh:ChangeState(Enum.HumanoidStateType.Physics) end
		freeze()
	end)
end)
def({ "unragdoll", "unrag" }, "", "Get up from ragdoll", "fall limp stiff physics", function() if state.ragdollStop then state.ragdollStop() end end)

-- ===== SPIDER / WALLWALK: every surface is a floor =====
-- Your "up" becomes the surface normal (walls, ceilings, slopes, edges), gravity pulls you into it. The camera is never touched.
-- Three rays decide the surface: a wall in front of you, the floor under you, and the edge you are walking around.
do
	local SP
	local function toward(a, b, k)
		local v = a:Lerp(b, k)
		if v.Magnitude < 0.05 then v = a:Cross(Vector3.xAxis); if v.Magnitude < 0.05 then v = a:Cross(Vector3.zAxis) end end
		return v.Unit
	end
	local function stopSpider()
		local s = SP
		if not s then return end
		SP = nil
		ctx.disconnect("spiderBeat"); ctx.disconnect("spiderJump")
		pcall(function() RS:UnbindFromRenderStep("KLSpiderCam") end)
		for _, o in ipairs(s.objs) do pcall(function() o:Destroy() end) end
		for _, t in ipairs(s.tracks) do pcall(function() t:Stop(0.1) end) end
		if s.animate and s.animate.Parent then s.animate.Disabled = false end
		local h, r = ctx.hum(), ctx.root()
		if h then h.AutoRotate = s.autoRotate; h.PlatformStand = false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end
		if r then
			local f = Vector3.new(s.face.X, 0, s.face.Z)
			f = f.Magnitude > 0.05 and f.Unit or Vector3.new(0, 0, -1)
			local p = r.Position + Vector3.new(0, 3, 0)
			r.CFrame = CFrame.lookAt(p, p + f)
			r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero
		end
		active("spider", nil)
		if s.ownSit then -- the silent anti sit startSpider turned on goes with it
			local na = state.noAct
			state.noAct = true
			pcall(ctx.Run, "unantisit")
			state.noAct = na
		end
	end
	local function startSpider()
		local h, c, r = ctx.hum(), ctx.char(), ctx.root()
		if not (h and c and r) then return end
		stopSpider()
		local cam = workspace.CurrentCamera
		local s = { up = Vector3.yAxis, dwell = 0, fall = Vector3.zero, face = r.CFrame.LookVector, objs = {}, tracks = {},
			air = 0, jumpT = 0, gT = 0, fT = 0, grounded = false, autoRotate = h.AutoRotate }
		SP = s
		local stand = h.RigType == Enum.HumanoidRigType.R6 and 3 or (h.HipHeight + r.Size.Y / 2) -- root centre to feet
		-- the engine's gravity is cancelled by a force, ours acts along the surface normal
		local att = Instance.new("Attachment"); att.Name = "_SpiderAtt"; att.Parent = r
		local vf = Instance.new("VectorForce")
		vf.Name, vf.Attachment0, vf.RelativeTo, vf.ApplyAtCenterOfMass = "_SpiderVF", att, Enum.ActuatorRelativeTo.World, true
		vf.Parent = r
		s.objs = { att, vf }
		local rp = RaycastParams.new()
		rp.FilterType, rp.RespectCanCollide, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, true, { c }
		-- height (studs above the feet) of the top of the step in front of you; nil = a real wall (higher than Module Cfg step size)
		-- shortcut: one ray down just past the face, so a step whose tread is under 0.35 studs deep or a wall with a ledge right behind it can be misjudged
		local function lowWall(fh, wd, up, feet, st) -- the surface in front is lower than st studs above your feet (its top is found by a ray down just past the face)
			if not (st and st > 0) then return end
			local o = fh.Position + wd * 0.35
			o = o + up * (st + 0.05 - (o - feet):Dot(up))
			local d = workspace:Raycast(o, -up * (st + 0.65), rp)
			if d and d.Normal:Dot(up) > 0.7 then
				local h = (d.Position - feet):Dot(up)
				if h > 0.15 and h <= st + 0.05 then return h end
			end
		end
		-- animations: the game's own walk / idle / fall, played by hand because the humanoid is in the Physics state
		local an, animate = h:FindFirstChildOfClass("Animator"), c:FindFirstChild("Animate")
		local function load(folder, name)
			local f = animate and animate:FindFirstChild(folder)
			local a = f and f:FindFirstChild(name)
			if a and a:IsA("Animation") and an then
				local ok, t = pcall(function() return an:LoadAnimation(a) end)
				if ok and t then s.tracks[#s.tracks + 1] = t; return t end
			end
		end
		if animate and an then
			s.animate = animate
			animate.Disabled = true
			for _, t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0.1) end
		end
		local walkT, idleT, fallT = load("walk", "WalkAnim"), load("idle", "Animation1"), load("fall", "FallAnim")
		local function setTrack(t)
			if not t or s.cur == t then return end
			if s.cur then s.cur:Stop(0.15) end
			s.cur = t; t:Play(0.15)
		end
		local controls
		pcall(function() controls = require(lp.PlayerScripts:FindFirstChild("PlayerModule")):GetControls() end)
		local function moveInput()
			if controls then
				local ok, v = pcall(function() return controls:GetMoveVector() end)
				if ok and typeof(v) == "Vector3" then return v.X, -v.Z end
			end
			local x, z = 0, 0
			if down(Enum.KeyCode.W) then z = z + 1 end
			if down(Enum.KeyCode.S) then z = z - 1 end
			if down(Enum.KeyCode.D) then x = x + 1 end
			if down(Enum.KeyCode.A) then x = x - 1 end
			return x, z
		end
		h:ChangeState(Enum.HumanoidStateType.Physics)
		if not state.conns.antisit then -- no seat can sit you mid climb; silent (no activation notice)
			local na = state.noAct
			state.noAct = true
			pcall(ctx.Run, "nosit")
			s.ownSit = true
			state.noAct = na
		end
		ctx.connect("spiderBeat", RS.PreSimulation, function(dt)
			local hh, rr = ctx.hum(), ctx.root()
			if not (hh and rr and rr.Parent == c) then return stopSpider() end
			dt = math.min(dt, 0.1)
			if hh:GetState() ~= Enum.HumanoidStateType.Physics then hh:ChangeState(Enum.HumanoidStateType.Physics) end
			hh.AutoRotate = false
			s.fT = s.fT - dt
			if s.fT <= 0 then -- other players' characters are not surfaces: rays skip them (list refreshed every second)
				s.fT = 1
				local ex = { c }
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl ~= lp and pl.Character then ex[#ex + 1] = pl.Character end
				end
				rp.FilterDescendantsInstances = ex
			end
			vf.Force = Vector3.new(0, rr.AssemblyMass * workspace.Gravity, 0)
			local pos, up = rr.Position, s.up
			-- walk direction: camera relative, flattened onto the surface you stand on
			local ix, iz = moveInput()
			local cf = cam.CFrame
			-- screen-forward along the surface: where the camera looks plus where its top points (facing a wall, W climbs it); a blend, so no jump between the two
			local lv, uv = cf.LookVector, cf.UpVector
			local look = (lv - up * lv:Dot(up)) + (uv - up * uv:Dot(up)) * math.abs(lv:Dot(up))
			for _, ax in ipairs({ s.face, Vector3.xAxis, Vector3.zAxis }) do
				if look.Magnitude >= 0.05 then break end
				look = ax - up * ax:Dot(up)
			end
			look = look.Unit
			local right = look:Cross(up).Unit
			local wish = look * iz + right * ix
			if wish.Magnitude > 1 then wish = wish.Unit end
			local moving = wish.Magnitude > 0.1
			-- which surface is the floor now: wall in front > floor under you > the edge you are walking around
			local hit = workspace:Raycast(pos, -up * (stand + 1.5), rp)
			local want, ahead, wh, edge -- edge = the new surface is the side of the part you just walked off; ahead = the new surface is a wall in front of you, wh = the ray hit on it
			if s.jumpT > 0 then
				s.jumpT = s.jumpT - dt
				hit = nil
			else
				local wd = moving and wish.Unit
				if wd then
					local reach = math.max(4.5, stand + 1.2) -- further than the body is wide: the turn starts before you touch the wall
					for _, dy in ipairs({ 0, -stand * 0.5 }) do -- chest and knee height, so low walls count too
						local fh = workspace:Raycast(pos + up * dy, wd * reach, rp)
						if fh and s.dwell <= 0 and math.abs(fh.Normal:Dot(up)) < 0.9 then if not lowWall(fh, wd, up, pos - up * stand, mod.spWall) then want, ahead, wh = fh.Normal, true, fh; break end -- lower than Module Cfg wall height (stairs, curbs): not hooked
					end
					end
				end
				if not hit then hit = workspace:Raycast(pos - (wd or s.face) * 1.2, -up * (stand + 1.5), rp) end -- overhanging an edge by up to 1.2 studs still counts as standing on it
				if not want and hit then want = hit.Normal end
				if not want then
					local ed = wd or s.face -- also when standing still half off an edge
					local eh = workspace:Raycast(pos + ed * 2.4 - up * (stand + 0.15), -ed * 4.2, rp) -- under the feet, reaching back under you: finds the side of a thin roof / fence you just walked off
					if eh then
						want = eh.Normal
						edge, wh = s.gT < 0.4, eh -- just off the ground (0.4 s): pulled round the edge under the lip instead of falling while turning
					end
				end
			end
			s.dwell = s.dwell - dt
			s.gT = hit and 0 or s.gT + dt
			
			if want and (not s.want or want:Dot(s.want) < 0.95) then s.want, s.dwell = want, 0.12 end -- new surface: no other wall switch for 0.2 s (no flip-flop at corners and bumps)
			if want then
				s.air = 0
				s.up = toward(s.up, want, 1 - math.exp(-((ahead or edge) and 14 or 8) * dt)) -- smooth turn; a wall in front or an edge turns faster
			else
				s.air = s.air + dt
				if s.air > 0.6 then s.up = toward(s.up, Vector3.yAxis, 1 - math.exp(-3 * dt)) end
			end
			up = s.up
			local wm = wish.Magnitude
			wish = wish - up * wish:Dot(up) -- the walk direction follows the surface you are turning onto
			if wm > 0 and wish.Magnitude > 0.25 * wm then wish = wish.Unit * wm end -- ...at the same speed (the projection alone shrinks it while the surface turns)
			-- gravity along the normal: a spring holds you at standing height on a surface, in the air you fall along -up
			local vel
			if hit then
				s.fall = Vector3.zero
				vel = up * math.clamp((stand - hit.Distance) * 14, -30, 30)
			else
				if edge then -- no falling while turning round an edge: carried to the standing spot on the face under the lip
					s.fall = (wh.Position + want * stand - pos) * 12
					if s.fall.Magnitude > 40 then s.fall = s.fall.Unit * 40 end
				else s.fall = s.fall - up * workspace.Gravity * dt end
				vel = s.fall
			end
			s.grounded = hit ~= nil
			rr.AssemblyLinearVelocity = wish * hh.WalkSpeed + vel
			-- face the way you walk, feet on the surface
			local fwd = moving and wish.Unit or s.face
			fwd = fwd - up * fwd:Dot(up)
			if fwd.Magnitude < 0.05 then fwd = look end
			fwd = fwd.Unit
			s.face = fwd
			local target = CFrame.fromMatrix(Vector3.zero, fwd:Cross(up).Unit, up, -fwd)
			rr.CFrame = CFrame.new(pos) * rr.CFrame.Rotation:Lerp(target, 1 - math.exp(-12 * dt))
			rr.AssemblyAngularVelocity = Vector3.zero
			if not s.grounded and s.air > 0.25 and fallT then setTrack(fallT)
			elseif moving and s.grounded and walkT then setTrack(walkT); walkT:AdjustSpeed(hh.WalkSpeed / 14.5)
			else setTrack(idleT) end
		end)
		ctx.connect("spiderJump", UIS.JumpRequest, function()
			local hh = ctx.hum()
			if hh and (s.grounded or s.air < 0.15) then
				local jp = hh.UseJumpPower and hh.JumpPower or math.sqrt(2 * workspace.Gravity * hh.JumpHeight)
				s.fall, s.jumpT, s.grounded = s.up * jp, 0.25, false
			end
		end)
		
	end
	def({ "spider", "wallwalk" }, "", "Walk on walls, ceilings and slopes like Spider-Man (jump leaps off the surface)", "wall climb ceiling gravity surface walk", startSpider)
	def({ "unspider", "unwallwalk" }, "", "Stop walking on walls", "wall climb ceiling gravity surface walk", stopSpider)
end

def({ "spin" }, "<rotations per second>", "Spin your character (with fling prevention)", "rotate turn", function(n)
	local rps = ctx.val("spin", n)
	local h = ctx.hum()
	if h then h.AutoRotate = false end
	ctx.connect("spin", RS.Heartbeat, function(dt)
		local r = ctx.root()
		if not r then return end
		r.CFrame = r.CFrame * CFrame.Angles(0, rps * 2 * math.pi * dt, 0)
		r.AssemblyAngularVelocity = Vector3.zero
		local v = r.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > 120 then r.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0) end
	end)
end)
def({ "unspin" }, "", "Stop spinning", "rotate turn", function()
	ctx.disconnect("spin")
	if ctx.hum() then ctx.hum().AutoRotate = true end
end)

-- ;ptp / ;pulsetp <player> [seconds]: sit on the target for a moment, then go back to where you were
do
	local busy -- os.clock() of the running pulse; a stale value (error mid pulse) expires by itself
	def({ "ptp", "pulsetp" }, "<player> [seconds]", "Pulse teleport: go to a player for a moment (default 1 s), then back to where you were", "teleport pulse return", function(q, t)
		if busy and os.clock() - busy < 31 then return ctx.notify("Pulse teleport is already running") end
		local p, r = ctx.findPlayer(q), ctx.root()
		if not (p and r) then return end
		if not (p.Character and p.Character:FindFirstChild("HumanoidRootPart")) then return ctx.notify(p.Name .. " has no character") end
		local secs = math.clamp(tonumber(t) or 1, 0, 30)
		local back, t0 = r.CFrame, os.clock()
		busy = t0
		repeat
			local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not (tr and r.Parent) then break end
			ctx.markMove()
			r.CFrame = tr.CFrame
			RS.Heartbeat:Wait()
		until os.clock() - t0 >= secs or not S.alive
		busy = nil
		if r.Parent then ctx.markMove(); r.CFrame = back; r.AssemblyLinearVelocity = Vector3.zero end
	end)
end

-- ;look <player | near | far | inwall>: your character faces the target (turn only), the camera is not touched; same method as ;spin
do
	local function live(p) -- the target's root part + character, nil while dead / not spawned
		local c = p.Character
		local h, r = c and c:FindFirstChildOfClass("Humanoid"), c and c:FindFirstChild("HumanoidRootPart")
		if h and r and h.Health > 0 then return r, c end
	end
	local function seen(from, r, c) -- true when no wall is between you and the target
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { ctx.char(), c }
		return workspace:Raycast(from, r.Position - from, params) == nil
	end
	local function pick(mode, from) -- nearest / farthest player, or (inwall) the nearest one with a clear line to you
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local r, c = live(p)
			if p ~= lp and r then list[#list + 1] = { r = r, c = c, d = (r.Position - from).Magnitude } end
		end
		table.sort(list, function(a, b) if mode == "far" then return a.d > b.d end return a.d < b.d end)
		for _, e in ipairs(list) do
			if mode ~= "inwall" or seen(from, e.r, e.c) then return e.r end
		end
	end
	def({ "look", "lookat" }, "<player | near | far | inwall>", "Face a player without moving the camera (near / far = nearest / farthest, inwall = nearest one not behind a wall)", "aim face turn lock aimbot", function(q)
		local mode, target = tostring(q or ""):lower(), nil
		if mode ~= "near" and mode ~= "far" and mode ~= "inwall" then
			if not q then return ctx.notify("look <player | near | far | inwall>") end
			target = ctx.findPlayer(q)
			if not target then return end
		end
		local tr, nextPick
		ctx.connect("look", RS.Heartbeat, function()
			local r, h = ctx.root(), ctx.hum()
			if not (r and h) then return end
			if target then
				tr = live(target)
			elseif not (tr and tr.Parent) or os.clock() >= (nextPick or 0) then
				nextPick = os.clock() + 0.1
				tr = pick(mode, r.Position)
			end
			h.AutoRotate = tr == nil -- no target (inwall with nobody in view): walk and turn normally
			if not tr then return end
			local d = tr.Position - r.Position
			d = Vector3.new(d.X, 0, d.Z)
			if d.Magnitude < 0.05 then return end
			r.CFrame = CFrame.lookAt(r.Position, r.Position + d)
			r.AssemblyAngularVelocity = Vector3.zero
		end)
	end)
	def({ "unlook", "unlookat" }, "", "Stop looking at a player", "aim face turn lock aimbot", function()
		ctx.disconnect("look")
		local h = ctx.hum()
		if h then h.AutoRotate = true end
	end)
end

-- ;keepemotes / ;kemote: emotes and other animations are not cut off by moving, jumping, falling, sitting...
-- How: the newest non-default animation gets priority Action4 (beats the walk / jump / fall animations) and is played again the moment it stops early.
-- Also: Humanoid:PlayEmote only works while standing on the ground, so when the game's Animate script refuses, the emote is played here instead.
do
	local LOCO = { idle = 1, walk = 1, run = 1, jump = 1, fall = 1, climb = 1, sit = 1, swim = 1, swimidle = 1, toolnone = 1, toolslash = 1, toollunge = 1, mood = 1 }
	local cur, last, hooked, animator, gen, chk = nil, 0, nil, nil, 0, 0 -- kept track, its last seen TimePosition, { bf, orig } of the PlayEmote hook, the Animator we listen to, attach generation (a newer attach cancels an older one), last watcher check
	local mine = setmetatable({}, { __mode = "k" }) -- our hook functions -> the function each one wraps (a hook is never wrapped twice)
	local function emoteLike(t) -- the Animate script's own idle / walk / jump... are not emotes
		local a, an = t.Animation, lp.Character and lp.Character:FindFirstChild("Animate")
		return not (a and an and a:IsDescendantOf(an) and a.Parent and LOCO[a.Parent.Name:lower()])
	end
	local function take(t)
		if cur ~= t then cur, last = t, 0 end -- the same track coming back (our own replay fires AnimationPlayed too) keeps its position
		pcall(function() t.Priority = Enum.AnimationPriority.Action4 end)
	end
	local function unhook()
		local k = hooked
		hooked = nil
		if k and k.bf.Parent then pcall(function() k.bf.OnInvoke = k.orig end) end
	end
	local function playHere(animate, e) -- what Animate does for an emote, minus its "only while standing" check
		local a
		if typeof(e) == "Instance" and e:IsA("Animation") then a = e
		elseif type(e) == "string" then local f = animate:FindFirstChild(e); a = f and f:FindFirstChildOfClass("Animation") end
		local h = ctx.hum()
		local an = h and h:FindFirstChildOfClass("Animator")
		if not (a and an) then return false end
		local ok, t = pcall(function() return an:LoadAnimation(a) end)
		if not (ok and t) then return false end
		take(t); t:Play(0.1)
		return true, t
	end
	local function attach() -- runs for the current character, again after every respawn / when the game swaps the Animator
		gen = gen + 1
		local my = gen
		unhook()
		cur = nil
		local c = lp.Character
		local h = c and c:WaitForChild("Humanoid", 5)
		local an = h and h:WaitForChild("Animator", 5)
		if not an or lp.Character ~= c or my ~= gen then return end
		animator = an
		ctx.connect("kemotePlay", an.AnimationPlayed, function(t) if emoteLike(t) then take(t) end end)
		for _, t in ipairs(an:GetPlayingAnimationTracks()) do if emoteLike(t) then take(t) end end
		-- after a respawn the Animate script has only just been cloned in: its PlayEmote function and the callback on it appear a moment later, so wait for them instead of giving up
		local animate = c:WaitForChild("Animate", 10)
		local bf = animate and animate:WaitForChild("PlayEmote", 10)
		if not bf or my ~= gen then return end
		local orig
		for _ = 1, 40 do
			local got, f = pcall(getcallbackmember, bf, "OnInvoke")
			if not got then return end -- no getcallbackmember: emotes still survive moving, they just need you to stand still to start
			if f then orig = f; break end
			task.wait(0.15)
			if my ~= gen or not bf.Parent then return end
		end
		if not orig or my ~= gen then return end
		while mine[orig] do orig = mine[orig] end
		local function hk(e)
			local ok, a, b = pcall(orig, e)
			if ok and a then return a, b end
			return playHere(animate, e)
		end
		mine[hk] = orig
		hooked = { bf = bf, orig = orig }
		bf.OnInvoke = hk
	end
	def({ "keepemotes", "kemote" }, "", "Keep emotes / animations playing while you move, jump, fall or sit; default emotes also start mid air (;unkemote to stop)", "emote animation dance keep uninterrupted air anywher", function()
		ctx.connect("kemoteChar", lp.CharacterAdded, function() task.spawn(attach) end)
		ctx.connect("kemote", RS.Heartbeat, function()
			local h = ctx.hum()
			local now = os.clock()
			if now - chk >= 1 then -- the game swapped the Humanoid / Animator (morph, avatar change): our listener died with it
				chk = now
				local a2 = h and h:FindFirstChildOfClass("Animator")
				if a2 and a2 ~= animator then animator = a2; task.spawn(attach) end
			end
			local t = cur
			if not t then return end
			if not h or h.Health <= 0 then cur = nil; return end
			if t.IsPlaying then last = t.TimePosition; return end
			local len = t.Length -- 0 until the animation has loaded: that is not "ended"
			if len > 0 and not t.Looped and last >= len - 0.25 then cur = nil; return end -- a one-shot that ran to its end
			local pos = last -- read before Play: Play can fire AnimationPlayed
			pcall(function() t:Play(0.1); if pos > 0 then t.TimePosition = pos end end)
		end)
		task.spawn(attach)
	end)
	def({ "unkeepemotes", "unkemote" }, "", "Stop keeping animations (the one playing now is stopped)", "emote animation dance keep uninterrupted", function()
		for _, k in ipairs({ "kemote", "kemoteChar", "kemotePlay" }) do ctx.disconnect(k) end
		gen, animator = gen + 1, nil -- cancels an attach that is still waiting
		unhook()
		local t = cur
		cur = nil
		if t then pcall(function() t:Stop(0.1) end) end
	end)
end

-- plain movement commands, now with the module defaults / multipliers and anti-teleport awareness
def({ "speed", "walkspeed", "ws" }, "[n]", "Set walk speed (default and multiplier in Module Cfg)", "run fast", function(n)
	if ctx.hum() then ctx.hum().WalkSpeed = ctx.val("speed", n) end
end)
def({ "jumppower", "jp" }, "[n]", "Set jump power (default and multiplier in Module Cfg)", "jump height", function(n)
	local h = ctx.hum()
	if not h then return end
	h.UseJumpPower = true
	h.JumpPower = ctx.val("jp", n)
end)
def({ "goto", "tp" }, "<player>", "Teleport to a player", "teleport move", function(q)
	local p = ctx.findPlayer(q)
	local r = p and ctx.reach(p) -- also when they are outside the streaming range
	if r and ctx.root() then ctx.markMove(); ctx.root().CFrame = r.CFrame * CFrame.new(0, 0, 3); ctx.unpark(false) end
end)
def({ "tpto" }, "<x> <y> <z>", "Teleport to coordinates", "teleport position", function(x, y, z)
	if ctx.root() then ctx.markMove(); ctx.root().CFrame = CFrame.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0) end
end)
def({ "mousetp", "mtp" }, "", "Teleport to where your mouse points (bind it to a key)", "teleport cursor click", function()
	local r, c, cam = ctx.root(), ctx.char(), workspace.CurrentCamera
	if not (r and c and cam) then return end
	local m = UIS:GetMouseLocation()
	local ray = cam:ViewportPointToRay(m.X, m.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { c }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if not hit then return ctx.notify("Nothing under the mouse") end
	ctx.markMove()
	r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0)) * (r.CFrame - r.CFrame.Position)
end)
def({ "freeze" }, "", "Anchor your character", "stop lock", function()
	state.selfFrozen = true
	if ctx.root() then ctx.root().Anchored = true end
end)
def({ "thaw", "unfreeze" }, "", "Unanchor your character", "stop lock", function()
	state.selfFrozen = nil
	if ctx.root() then ctx.root().Anchored = false end
end)
-- infinite jump: pushes you up by exactly what a normal jump gives, so jump height and gravity are never touched
def({ "infjump" }, "", "Jump again in mid-air", "infinite air", function()
	ctx.connect("infjump", UIS.JumpRequest, function()
		local r, h = ctx.root(), ctx.hum()
		if not (r and h) then return end
		local v = h.UseJumpPower and h.JumpPower or math.sqrt(2 * workspace.Gravity * h.JumpHeight)
		local cur = r.AssemblyLinearVelocity
		r.AssemblyLinearVelocity = Vector3.new(cur.X, v, cur.Z)
	end)
end)
-- the executor's cap can get reset (focus change, teleport, graphics change), so it is checked once a second and re-applied
do
	local target, last = nil, 0
	-- every call takes a new generation number kept in env: a run that is still alive from before (an autostart run that errored, an old copy) sees it is outdated and drops its own lock instead of flipping the cap back to its old value (e.g. 1000)
	function ctx.lockFps(n)
		target = n
		local gen = (tonumber(env.KLOSAD_FPSGEN) or 0) + 1
		env.KLOSAD_FPSGEN = gen
		ctx.disconnect("fpsLock"); ctx.disconnect("fpsFocus")
		if not n then return end
		pcall(setfpscap, n)
		ctx.connect("fpsLock", RS.Heartbeat, function()
			if env.KLOSAD_FPSGEN ~= gen then ctx.disconnect("fpsLock"); ctx.disconnect("fpsFocus"); return end
			local t = os.clock()
			if t - last < 1 then return end
			last = t
			if getfpscap then
				local ok, cur = pcall(getfpscap)
				if ok and type(cur) == "number" and math.abs(cur - target) < 0.5 then return end
			end
			pcall(setfpscap, target)
		end)
		ctx.connect("fpsFocus", UIS.WindowFocused, function()
			if env.KLOSAD_FPSGEN == gen then pcall(setfpscap, target) end
		end)
	end
end
def({ "fpscap", "fps", "fpsmax" }, "[number|off]", "Cap the frame rate (default 60, stays locked; off removes it)", "frame rate performance", function(n)
	if not setfpscap then return ctx.notify("This executor has no setfpscap") end
	local w = n and tostring(n):lower()
	if w == "off" or w == "unlock" then
		ctx.lockFps(nil); pcall(setfpscap, 0)
		return ctx.notify("FPS cap removed")
	end
	ctx.lockFps(tonumber(n) or 60)
end)

-- ===== DEFENSE =====
local function setNoCollide(char, on)
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			if on then
				if state.cc[v] == nil then state.cc[v] = v.CanCollide end
				v.CanCollide = false
			elseif state.cc[v] ~= nil then
				v.CanCollide = state.cc[v]
				state.cc[v] = nil
			end
		end
	end
end

def({ "antifling", "af" }, "[radius] [threshold] [restore time]", "Turn off collision with fast-moving players until they calm down", "fling protect safe collision", function(rad, thr, rest)
	local radius, thresh, restore = tonumber(rad) or mod.afRadius, tonumber(thr) or mod.afThreshold, tonumber(rest) or mod.afRestore
	for p in pairs(state.afFlagged or {}) do if p.Character then setNoCollide(p.Character, false) end end -- a re-run (new radius) first gives back the old run's players
	local flagged = {}
	state.afFlagged = flagged
	ctx.connect("antifling", RS.Stepped, function()
		local r = ctx.root()
		if not r then return end
		local now = os.clock()
		for _, p in ipairs(Players:GetPlayers()) do
			local pc = p.Character
			local pr = pc and pc:FindFirstChild("HumanoidRootPart")
			if p ~= lp and pr then
				local fast = pr.AssemblyLinearVelocity.Magnitude > thresh or pr.AssemblyAngularVelocity.Magnitude > thresh / 3
				if fast and (pr.Position - r.Position).Magnitude <= radius then
					if not flagged[p] then dnotify("af", "Anti fling: " .. p.DisplayName .. " is moving fast") end
					flagged[p] = now
				end
				if flagged[p] then
					if now - flagged[p] > restore then
						flagged[p] = nil
						setNoCollide(pc, false)
					else
						setNoCollide(pc, true)
					end
				end
			end
		end
	end)
end)
def({ "unantifling", "unaf" }, "", "Turn anti fling off", "fling protect", function()
	ctx.disconnect("antifling")
	for p in pairs(state.afFlagged or {}) do
		if p.Character then setNoCollide(p.Character, false) end
	end
	state.afFlagged = {}
end)

def({ "antisit", "nosit" }, "", "Stop forced sitting: seats can't seat you (No Sit component)", "seat lock", function()
	if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup) end
	local url
	for _, g in ipairs(GITHUB) do
		if g.name == "No Sit" then url = g.url end
	end
	local body = url and ctx.fetch(url)
	if body then
		local fn = HAS_LOAD and loadstring(body) -- no loadstring: straight to the built-in fallback below
		if fn and pcall(fn) then state.noSitComponent = true end -- the guard below still runs, so welded chairs are handled too
	end
	-- fallback if the component can't be downloaded: stand back up whenever something sits you down
	if not state.noSitComponent then ctx.notify("No Sit component unavailable, using the built-in version") end
	ctx.connect("antisit", RS.Heartbeat, function()
		local h = ctx.hum()
		if not h then return end
		if (h.Sit or h.SeatPart) and not state.attach and not (state.allowSit and os.clock() - state.allowSit < 1.5)
			and os.clock() - (state.ejectAt or 0) > 0.4 then
			ctx.eject()
			dnotify("sit", "Anti sit: stood you back up")
		end
	end)
end)
def({ "unantisit", "unnosit" }, "", "Turn anti sit off", "seat lock", function()
	if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup) end
	state.noSitComponent = nil
	ctx.disconnect("antisit")
end)

def({ "antivoid" }, "[height]", "Catch you before the void and put you back on safe ground", "fall void teleport safe", function(hgt)
	local margin = tonumber(hgt) or mod.avHeight
	local safe
	ctx.connect("antivoid", RS.Heartbeat, function()
		local r, h = ctx.root(), ctx.hum()
		if not (r and h) then return end
		if h.FloorMaterial ~= Enum.Material.Air then safe = r.CFrame end
		local fpdh = workspace.FallenPartsDestroyHeight
		if fpdh < -1e5 then fpdh = -500 end
		if safe and r.Position.Y < fpdh + margin then
			ctx.markMove()
			r.CFrame = safe + Vector3.new(0, 3, 0)
			r.AssemblyLinearVelocity = Vector3.zero
			dnotify("void", "Anti void: put you back")
		end
	end)
end)
def({ "unantivoid" }, "", "Turn anti void off", "fall void safe", function() ctx.disconnect("antivoid") end)

def({ "antiteleport", "antitp" }, "[min distance]", "Revert sudden position changes you didn't cause", "teleport safe lock", function(m)
	local minD, last, lastRoot = tonumber(m) or mod.atpMin, nil, nil
	ctx.connect("antiteleport", RS.Heartbeat, function()
		local r = ctx.root()
		if not r then last = nil; return end
		if r ~= lastRoot then lastRoot, last = r, nil end
		local pos = r.Position
		if last and (pos - last).Magnitude > minD and not (state.selfMove and os.clock() - state.selfMove < 0.6) then
			r.CFrame = CFrame.new(last) * (r.CFrame - r.CFrame.Position)
			dnotify("tp", "Anti teleport: reverted a move")
		else
			last = pos
		end
	end)
end)
def({ "unantiteleport", "unantitp" }, "", "Turn anti teleport off", "teleport safe", function() ctx.disconnect("antiteleport") end)

def({ "antiknockback", "antipush" }, "[max speed]", "Clamp your velocity so pushes and explosions don't launch you", "push launch fling safe", function(m)
	local maxS = tonumber(m) or mod.akMax
	ctx.connect("antiknockback", RS.Heartbeat, function()
		local r = ctx.root()
		if not r or state.active.fly or state.active.cfly or state.attach then return end
		local v = r.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		local y = math.clamp(v.Y, -300, maxS)
		if flat.Magnitude > maxS or y ~= v.Y then
			r.AssemblyLinearVelocity = (flat.Magnitude > maxS and flat.Unit * maxS or flat) + Vector3.new(0, y, 0)
		end
	end)
end)
def({ "unantiknockback", "unantipush" }, "", "Turn anti knockback off", "push launch safe", function() ctx.disconnect("antiknockback") end)

def({ "antiattach" }, "", "Stop players welded or attached to you from moving you", "carry headsit weld safe collision", function()
	for p in pairs(state.aaFlagged or {}) do if p.Character then setNoCollide(p.Character, false) end end
	local flagged, acc = {}, 0
	state.aaFlagged = flagged
	local function joined(a, b)
		for _, v in ipairs(a:GetDescendants()) do
			if v:IsA("JointInstance") or v:IsA("WeldConstraint") then
				local p0, p1 = v.Part0, v.Part1
				if (p0 and p0:IsDescendantOf(b)) or (p1 and p1:IsDescendantOf(b)) then return true end
			end
		end
		return false
	end
	ctx.connect("antiattach", RS.Heartbeat, function(dt)
		acc = acc + dt
		if acc < 0.2 then return end
		acc = 0
		local c = ctx.char()
		if not c then return end
		for _, p in ipairs(Players:GetPlayers()) do
			local pc = p.Character
			if p ~= lp and pc then
				if joined(pc, c) or joined(c, pc) then
					if not flagged[p] then dnotify("aa", "Anti attach: " .. p.DisplayName) end
					flagged[p] = true
				elseif flagged[p] then
					flagged[p] = nil
					setNoCollide(pc, false)
				end
			end
		end
	end)
	ctx.connect("antiattachStep", RS.Stepped, function()
		for p in pairs(flagged) do
			if p.Character then setNoCollide(p.Character, true) end
		end
	end)
end)
def({ "unantiattach" }, "", "Turn anti attach off", "carry headsit weld safe", function()
	ctx.disconnect("antiattach"); ctx.disconnect("antiattachStep")
	for p in pairs(state.aaFlagged or {}) do
		if p.Character then setNoCollide(p.Character, false) end
	end
	state.aaFlagged = {}
end)

def({ "antiearrape", "antiloud" }, "[threshold] [duration]", "Lower sounds that spike past a loudness threshold (RMS)", "voice vc audio loud volume sound mute", function(thr, dur)
	local threshold, duration = tonumber(thr) or mod.aeThreshold, tonumber(dur) or mod.aeDuration
	local sounds, win, rescan = {}, {}, 0
	state.aeOrig = state.aeOrig or {}
	local orig = state.aeOrig
	ctx.connect("antiearrape", RS.Heartbeat, function(dt)
		rescan = rescan - dt
		if rescan <= 0 then
			rescan = 3
			sounds = {}
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Sound") then sounds[#sounds + 1] = v end
			end
			pcall(function()
				for _, v in ipairs(S.SoundService:GetDescendants()) do
					if v:IsA("Sound") then sounds[#sounds + 1] = v end
				end
			end)
		end
		for _, snd in ipairs(sounds) do
			if snd.Parent and snd.IsPlaying then
				local w = win[snd]
				if not w then w = { sum = 0, n = 0, t = 0 }; win[snd] = w end
				local l = snd.PlaybackLoudness
				w.sum, w.n, w.t = w.sum + l * l, w.n + 1, w.t + dt
				if w.t >= duration then
					local adj = (orig[snd] and snd.Volume > 0) and (orig[snd] / snd.Volume) or 1
					local rms = math.sqrt(w.sum / math.max(w.n, 1)) * adj
					if rms > threshold then
						if orig[snd] == nil then orig[snd] = snd.Volume end
						snd.Volume = orig[snd] * 0.15
						dnotify("ear", "Anti ear rape: lowered a loud sound")
					elseif orig[snd] ~= nil then
						snd.Volume = orig[snd]
						orig[snd] = nil
					end
					win[snd] = nil
				end
			end
		end
	end)
end)
def({ "unantiearrape", "unantiloud" }, "", "Turn anti ear rape off and restore volumes", "voice vc audio loud volume sound", function()
	ctx.disconnect("antiearrape")
	for snd, v in pairs(state.aeOrig or {}) do
		if snd.Parent then snd.Volume = v end
	end
	state.aeOrig = {}
end)

local FX = { blur = "BlurEffect", color = "ColorCorrectionEffect", bloom = "BloomEffect", dof = "DepthOfFieldEffect", sunrays = "SunRaysEffect" }
def({ "antiblur", "antieffects" }, "[blur|color|bloom|dof|sunrays|all]", "Strip blur and screen effects from your camera and lighting", "screen effects visual", function(which)
	which = (which or "all"):lower()
	state.abOff = state.abOff or {}
	local off = state.abOff
	local function kill(o)
		if o.Name == "KLOSAD_Blur" then return end
		for k, cls in pairs(FX) do
			if (which == "all" or which == k) and o:IsA(cls) then
				if off[o] == nil then off[o] = o.Enabled end
				pcall(function() o.Enabled = false end)
			end
		end
	end
	for _, o in ipairs(ctx.Lighting:GetDescendants()) do kill(o) end
	for _, o in ipairs(workspace.CurrentCamera:GetDescendants()) do kill(o) end
	ctx.connect("antiblurL", ctx.Lighting.DescendantAdded, kill)
	ctx.connect("antiblurC", workspace.CurrentCamera.DescendantAdded, kill)
	ctx.connect("antiblur", RS.Heartbeat, function()
		for o in pairs(off) do
			if o.Parent and o.Enabled then o.Enabled = false end
		end
	end)
end)
def({ "unantiblur", "unantieffects" }, "", "Turn anti blur off and bring the effects back", "screen effects visual", function()
	ctx.disconnect("antiblur"); ctx.disconnect("antiblurL"); ctx.disconnect("antiblurC")
	for o, was in pairs(state.abOff or {}) do
		if o.Parent then pcall(function() o.Enabled = was end) end
	end
	state.abOff = {}
end)

def({ "antiafk" }, "[interval]", "Stop the idle kick by simulating input", "idle kick afk", function(iv)
	local interval, acc = tonumber(iv) or mod.afkInterval, 0
	local function poke()
		pcall(function()
			local VU = game:GetService("VirtualUser")
			VU:CaptureController()
			VU:ClickButton2(Vector2.new())
		end)
	end
	ctx.connect("antiafk", lp.Idled, poke)
	ctx.connect("antiafkTick", RS.Heartbeat, function(dt)
		acc = acc + dt
		if acc >= interval then acc = 0; poke() end
	end)
end)
def({ "unantiafk" }, "", "Turn anti afk off", "idle kick afk", function() ctx.disconnect("antiafk"); ctx.disconnect("antiafkTick") end)

def({ "antispam", "antichatspam" }, "[messages per interval]", "Hide chat from players who repeat messages too fast", "chat spam flood mute", function(n)
	ctx.hookChat()
	state.chat.spam, state.chat.spamN = true, tonumber(n) or mod.spamCount
end)
def({ "unantispam", "unantichatspam" }, "", "Turn anti spam off", "chat spam flood", function()
	if state.chat then state.chat.spam = false; state.chat.hist = {} end
end)

def({ "antifreeze" }, "", "Un-anchor yourself if something locks you in place", "anchor stuck lock", function()
	ctx.connect("antifreeze", RS.Heartbeat, function()
		local r = ctx.root()
		if r and r.Anchored and not state.selfFrozen and not state.blink and not state.parked then -- ;goto parks you anchored while the target streams in
			r.Anchored = false
			dnotify("freeze", "Anti freeze: un-anchored you")
		end
	end)
end)
def({ "unantifreeze" }, "", "Turn anti freeze off", "anchor stuck lock", function() ctx.disconnect("antifreeze") end)

-- anti gameplay paused: with streaming on, Roblox pauses YOU when the area around you is not loaded: Player.GameplayPaused turns true (a property of the player, set by the client),
-- your character stops and "gameplay paused" shows. The old version read workspace.GameplayPaused, which does not exist, so it never did anything.
-- Four things: StreamingIntegrityMode is set to Disabled (original remembered for ;unantipause), the pause notice is hidden (GuiService:SetGameplayPausedNotificationEnabled),
-- and lp.GameplayPaused is forced back to false every frame and the moment it flips. Each write is tried as a normal property write first, then through sethiddenproperty.
-- shortcut: if the server itself freezes your character while paused (not just the client), this cannot undo that part
do
	local saved
	local function get(o, p)
		local ok, v = pcall(function() return o[p] end)
		if ok then return v end
		if gethiddenproperty then
			local ok2, v2 = pcall(gethiddenproperty, o, p)
			if ok2 then return v2 end
		end
	end
	local function set(o, p, v)
		if pcall(function() o[p] = v end) and get(o, p) == v then return true end
		if sethiddenproperty then return pcall(sethiddenproperty, o, p, v) end
		return false
	end
	local function unpause()
		if get(lp, "GameplayPaused") then
			pcall(function() if setthreadidentity then setthreadidentity(8) end end) -- the write needs a high identity on some executors
			set(lp, "GameplayPaused", false)
			dnotify("pause", "Anti gameplay paused: un-paused you")
		end
	end
	def({ "antigameplaypaused", "antipause" }, "", "Stop the game from pausing you (the \"gameplay paused\" state when streaming can't keep up)", "pause paused streaming freeze stuck lag loading gameplay", function()
		if saved == nil then saved = get(workspace, "StreamingIntegrityMode") or false end
		set(workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
		pcall(function() S.GuiService:SetGameplayPausedNotificationEnabled(false) end)
		-- every frame step, and the moment the property flips (the paused state can skip Heartbeat)
		ctx.connect("antipause", RS.Heartbeat, unpause)
		ctx.connect("antipauseR", RS.RenderStepped, unpause)
		ctx.connect("antipauseS", RS.Stepped, unpause)
		pcall(function() ctx.connect("antipauseC", lp:GetPropertyChangedSignal("GameplayPaused"), unpause) end)
		unpause()
		-- what this client reports, so a failure is visible instead of silent
		ctx.notify(("Anti pause on. Player.GameplayPaused: %s. StreamingIntegrityMode: %s (%s)"):format(tostring(get(lp, "GameplayPaused")), tostring(get(workspace, "StreamingIntegrityMode")),
			get(workspace, "StreamingIntegrityMode") == Enum.StreamingIntegrityMode.Disabled and "set to Disabled" or "could not be changed"), 8)
	end)
	def({ "unantigameplaypaused", "unantipause" }, "", "Turn anti gameplay paused off", "pause paused streaming gameplay", function()
		for _, k in ipairs({ "antipause", "antipauseR", "antipauseS", "antipauseC" }) do ctx.disconnect(k) end
		pcall(function() S.GuiService:SetGameplayPausedNotificationEnabled(true) end)
		if saved then set(workspace, "StreamingIntegrityMode", saved) end
		saved = nil
	end)
end

-- ===== POSITION SPOOFING =====
-- How blink works: your real body stays where you activated it and is anchored on YOUR client only, so the server
-- stops receiving position updates and everyone keeps seeing you standing there. You walk around in a local copy of
-- your character instead, and the frozen real body is drawn at 50% so you can see where the server thinks you are.
--   blink: switching off teleports the real body to where the copy ended up
--   ghost: switching off just drops the copy, so you are "back" at the original spot
local function blinkOff()
	local b = state.blink
	if not b then return end
	state.blink = nil
	ctx.disconnect("blinkDeath"); ctx.disconnect("blinkChar"); ctx.disconnect("blinkNC")
	local fr = b.fake and b.fake:FindFirstChild("HumanoidRootPart")
	local landed = fr and fr.CFrame
	pcall(function() lp.Character = b.real end) -- hand control back to the real body
	if b.real and b.real.Parent then
		local rr, rh = b.real:FindFirstChild("HumanoidRootPart"), b.real:FindFirstChildOfClass("Humanoid")
		if rr then
			rr.Anchored = state.selfFrozen and true or false
			if landed and not b.ghost then ctx.markMove(); rr.CFrame = landed end
		end
		if rh then workspace.CurrentCamera.CameraSubject = rh end
		for part, t in pairs(b.alpha) do
			if part.Parent then part.Transparency = t end
		end
	end
	if b.fake then b.fake:Destroy() end
	active("blink", nil); active("ghost", nil)
end
local function blinkOn(ghost)
	local real, rr, rh = ctx.char(), ctx.root(), ctx.hum()
	if not (real and rr and rh) then return ctx.notify("No character to blink with") end
	real.Archivable = true
	local okc, fake = pcall(function() return real:Clone() end)
	local fh = okc and fake and fake:FindFirstChildOfClass("Humanoid")
	if not (fh and fake:FindFirstChild("HumanoidRootPart")) then
		if okc and fake then fake:Destroy() end
		return ctx.notify("Couldn't copy your character")
	end
	-- the real body: frozen where it is (for the server) and drawn at 50% (for you)
	local alpha = {}
	for _, v in ipairs(real:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Decal") then
			alpha[v] = v.Transparency
			v.Transparency = math.max(v.Transparency, 0.5)
		end
	end
	rr.AssemblyLinearVelocity = Vector3.zero
	rr.Anchored = true
	-- the copy is the body you walk around in
	fake.Parent = workspace
	if not pcall(function() lp.Character = fake end) then
		rr.Anchored = false
		for part, t in pairs(alpha) do part.Transparency = t end
		fake:Destroy()
		return ctx.notify("This executor can't swap your character, so blink won't work")
	end
	workspace.CurrentCamera.CameraSubject = fh
	local anim = fake:FindFirstChild("Animate")
	if anim then anim.Disabled = true; anim.Disabled = false end
	state.blink = { real = real, fake = fake, ghost = ghost, alpha = alpha }
	active(ghost and "ghost" or "blink", true)
	-- the frozen body must not collide with the copy standing inside it
	ctx.connect("blinkNC", RS.Stepped, function()
		for part in pairs(alpha) do
			if part.Parent and part:IsA("BasePart") then part.CanCollide = false end
		end
	end)
	ctx.connect("blinkDeath", fh.Died, function()
		blinkOff()
		local h = ctx.hum()
		if h then h.Health = 0 end
	end)
	ctx.connect("blinkChar", lp.CharacterAdded, function(c)
		local b = state.blink
		if b and c ~= b.fake then -- the game gave you a new character: just drop the copy
			state.blink = nil
			ctx.disconnect("blinkDeath"); ctx.disconnect("blinkChar"); ctx.disconnect("blinkNC")
			if b.fake then b.fake:Destroy() end
			active("blink", nil); active("ghost", nil)
		end
	end)
end
def({ "blink" }, "", "Look frozen to everyone else while you keep moving (toggle)", "lag teleport spoof position", function()
	if state.blink then blinkOff() else blinkOn(false) end
end)
def({ "ghost", "ghostblink" }, "", "Like blink, but sends you back to where you started (toggle)", "lag teleport spoof position", function()
	if state.blink then blinkOff() else blinkOn(true) end
end)
def({ "unblink", "unghost" }, "", "Turn blink / ghost off (either name works for both)", "lag spoof position ghost", blinkOff)

-- ===== NAMES: driven by your Name Spoofer component (getgenv().NameSpoof) =====
-- The component keeps its "other players" names in a constant, so before running it the names from Module Cfg
-- (comma separated) are written into that constant, and it starts switched off.
local function spoofer() return env.NameSpoof end
local function loadSpoofer()
	if spoofer() and not state.spoofStale then return spoofer() end
	if spoofer() and spoofer().Destroy then pcall(spoofer().Destroy) end
	local url
	for _, g in ipairs(GITHUB) do
		if g.name == "Name Spoofer" then url = g.url end
	end
	local body, err = url and ctx.fetch(url)
	if not body then ctx.notify("Name Spoofer: download failed (" .. tostring(err) .. ")"); return nil end
	local list = {}
	for n in tostring(mod.streamOthers):gmatch("[^,]+") do
		n = n:match("^%s*(.-)%s*$")
		if n ~= "" then list[#list + 1] = string.format("%q", n) end
	end
	if #list == 0 then list[1] = '"Player"' end
	body = body:gsub("local OTHER_NAMES = %b{}", function() return "local OTHER_NAMES = {" .. table.concat(list, ", ") .. "}" end, 1)
	body = body:gsub("local ENABLED = %a+", function() return "local ENABLED = false" end, 1)
	body = body:gsub("local SPOOF_OTHERS = %a+", function() return "local SPOOF_OTHERS = false" end, 1)
	if not HAS_LOAD then ctx.notify("Name Spoofer needs loadstring (this executor has none)"); return nil end
	local fn, e = loadstring(body)
	if not fn then ctx.notify("Name Spoofer: " .. tostring(e)); return nil end
	local ok, e2 = pcall(fn)
	if not ok then ctx.notify("Name Spoofer error: " .. tostring(e2)); return nil end
	state.spoofStale = false
	return spoofer()
end
function ctx.reloadSpoofer() -- Module Cfg calls this when the streamer names change
	if spoofer() then state.spoofStale = true end
	if ctx.streamOthersOn and ctx.streamOthersOn() then ctx.streamOthers(false); ctx.streamOthers(true) end
end
-- Native "everyone else" half of streamer mode (the component only reliably renames you): other players get the names
-- from Module Cfg on their Player / Humanoid display names, and every text label in CoreGui / PlayerGui (leaderboard,
-- chat, nametags) that shows their real name or display name is rewritten. ;unstreamer puts it all back.
do
	local SO = { on = false, map = {}, real = {}, n = 0, txt = {}, cons = {}, hooked = {} }
	local function alias(p)
		if SO.map[p] then return SO.map[p] end
		local list = {}
		for n in tostring(mod.streamOthers):gmatch("[^,]+") do
			n = n:match("^%s*(.-)%s*$")
			if n ~= "" then list[#list + 1] = n end
		end
		if #list == 0 then list[1] = "Player" end
		local i = SO.n
		SO.n = i + 1
		local a = list[i % #list + 1]
		if i >= #list then a = a .. " " .. (math.floor(i / #list) + 1) end
		SO.map[p], SO.real[p] = a, { p.Name, p.DisplayName }
		return a
	end
	local function scrub(o)
		if o:FindFirstAncestor("KLOSAD") then return end
		local t = o.Text
		SO.set = SO.set or {}
		if t == "" or t == SO.set[o] then return end -- our own rewrite firing Text changed: a real name inside an alias used to rewrite forever
		local new = t
		for p, r in pairs(SO.real) do
			for _, nm in ipairs(r) do
				if #nm >= 3 and SO.map[p] and new:find(nm, 1, true) then
					new = new:gsub((nm:gsub("%p", "%%%0")), (SO.map[p]:gsub("%%", "%%%%")))
				end
			end
		end
		if new ~= t then
			SO.txt[o], SO.set[o] = t, new -- the latest original, so ;unstreamer restores current text
			o.Text = new
		else
			SO.txt[o], SO.set[o] = nil, nil
		end
	end
	local function hook(o)
		if not (o:IsA("TextLabel") or o:IsA("TextButton")) then return end
		scrub(o)
		if SO.hooked[o] then return end
		SO.hooked[o] = true
		SO.cons[#SO.cons + 1] = o:GetPropertyChangedSignal("Text"):Connect(function() scrub(o) end)
	end
	local function roots()
		local r = {}
		local ok, cg = pcall(function() return game:GetService("CoreGui") end)
		if ok and cg then r[#r + 1] = cg end
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		if pg then r[#r + 1] = pg end
		return r
	end
	local function scan()
		for _, root in ipairs(roots()) do
			local ok, list = pcall(function() return root:GetDescendants() end)
			if ok then
				for i, o in ipairs(list) do
					if SO.on then pcall(hook, o) end
					if i % 400 == 0 then task.wait() end
				end
			end
		end
	end
	local function apply(p)
		if p == lp then return end
		local a = alias(p)
		pcall(function() p.DisplayName = a end)
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if h then pcall(function() h.DisplayName = a end) end
	end
	function ctx.streamOthersOn() return SO.on end
	function ctx.streamOthers(on)
		ctx.disconnect("soAdd"); ctx.disconnect("soTick")
		for _, c in ipairs(SO.cons) do c:Disconnect() end
		if SO.on then -- put everything back
			for p, r in pairs(SO.real) do
				pcall(function() p.DisplayName = r[2] end)
				local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h then pcall(function() h.DisplayName = r[2] end) end
			end
			for o, t in pairs(SO.txt) do
				if o.Parent then pcall(function() o.Text = t end) end
			end
		end
		SO.on, SO.map, SO.real, SO.n, SO.cons = on and true or false, {}, {}, 0, {}
		SO.txt, SO.hooked = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
		if not on then return end
		for _, p in ipairs(Players:GetPlayers()) do apply(p) end
		ctx.connect("soAdd", Players.PlayerAdded, function(p)
			apply(p)
			task.delay(0.5, scan)
		end)
		local last = 0
		ctx.connect("soTick", RS.Heartbeat, function()
			local t = os.clock()
			if t - last < 2 then return end
			last = t
			for p, a in pairs(SO.map) do
				if not p.Parent then
					SO.map[p], SO.real[p] = nil, nil -- both: scrub indexed map[p] for a real name still listed and errored
				else
					if p.DisplayName ~= a then pcall(function() p.DisplayName = a end) end
					local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					if h and h.DisplayName ~= a then pcall(function() h.DisplayName = a end) end
				end
			end
		end)
		for _, root in ipairs(roots()) do
			SO.cons[#SO.cons + 1] = root.DescendantAdded:Connect(function(o) pcall(hook, o) end)
		end
		task.spawn(scan)
	end
end
def({ "streamer", "streamermode" }, "", "Hide your name and everyone else's (names set in Module Cfg)", "name hide spoof privacy", function()
	local c = loadSpoofer()
	if not c then return end
	c.Name, c.Enabled, c.Others = mod.streamMe, true, false
	ctx.streamOthers(true)
end)
def({ "unstreamer", "unstreamermode" }, "", "Turn streamer mode off", "name hide spoof privacy", function()
	ctx.streamOthers(false)
	local c = spoofer()
	if c then c.Enabled, c.Others = false, false end
end)
def({ "name", "spoof" }, "<name>", "Spoof your own name", "name hide spoof", function(...)
	local n = table.concat({ ... }, " ")
	if n == "" then return ctx.notify("Usage: name <name>") end
	local c = loadSpoofer()
	if not c then return end
	c.Name, c.Enabled, c.Others = n, true, false
end)
def({ "unname", "unspoof" }, "", "Stop spoofing your name", "name spoof", function()
	local c = spoofer()
	if c then c.Enabled, c.Others = false, false end
end)

-- ===== SERVER REGIONS: ;region and the Servers tab =====
-- A server's region is where its public IP is. join-game-instance (Roblox client User-Agent, logged in) returns that IP, a batch lookup turns it into a city,
-- TeleportToPlaceInstance joins. Servers are checked 4 at a time and cached for the session, the lookup is one request per 12 servers.
local SRV = { byId = {}, ip = {}, busy = false, stop = false }
ctx.SRV = SRV
do
	local csrf
	local G = (getgenv and getgenv()) or _G
	local function jdec(s) local ok, v = pcall(S.HttpService.JSONDecode, S.HttpService, s); return ok and v or nil end
	local function hdr(res, name)
		for k, v in pairs(res.Headers or {}) do if tostring(k):lower() == name then return v end end
	end
	local function cookie() -- only used when the executor's request does not already send your login
		for _, n in ipairs({ "getrbxcookie", "get_roblox_cookie", "getrobloxcookie", "getcookie" }) do
			if type(G[n]) == "function" then
				local ok, c = pcall(G[n])
				if ok and type(c) == "string" and #c > 20 then return c end
			end
		end
	end
	-- three ways to reach gamejoin with your login, the first one that works is remembered (SRV.mode):
	-- internal = the engine's own request (carries your session), api = HttpRbxApiService, request = the executor's request with a cookie
	local URL = "https://gamejoin.roblox.com/v1/join-game-instance"
	local function viaInternal(body)
		local res
		for _ = 1, 2 do
			res = nil
			local ok, rq = pcall(function()
				return S.HttpService:RequestInternal({ Url = URL, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["x-csrf-token"] = csrf }, Body = body })
			end)
			if not (ok and rq) then return nil end
			if not pcall(function() rq:Start(function(_, r) res = r or false end) end) then return nil end
			local t = os.clock()
			while res == nil and os.clock() - t < 10 do task.wait(0.05) end
			if type(res) ~= "table" then return nil end
			if res.StatusCode == 403 and hdr(res, "x-csrf-token") then csrf = hdr(res, "x-csrf-token") else break end
		end
		return { StatusCode = res.StatusCode, Body = res.Body }
	end
	local function viaApi(body)
		local ok, out = pcall(function()
			return game:GetService("HttpRbxApiService"):PostAsyncFullUrl(URL, body, Enum.ThrottlingPriority.Default, Enum.HttpContentType.ApplicationJson)
		end)
		if ok and type(out) == "string" then return { StatusCode = 200, Body = out } end
	end
	-- executors differ on whether they honour the Cookie header, the Cookies field or both, so try each and remember the one Roblox accepts (SRV.how)
	local HOW = { "both", "header", "table" }
	local function send(o, how, c)
		o.Headers = o.Headers or {}
		o.Headers["User-Agent"] = "Roblox/WinInet"
		if how ~= "table" then o.Headers.Cookie = ".ROBLOSECURITY=" .. c end
		if how ~= "header" then o.Cookies = { [".ROBLOSECURITY"] = c } end
		local ok, r = pcall(request, o)
		if ok and type(r) == "table" then return r end
	end
	local function viaRequest(body)
		SRV.cookie = SRV.cookie or cookie()
		if not SRV.cookie then return nil, "needs your cookie (start region-relay.py)" end
		local res
		for _, how in ipairs(SRV.how and { SRV.how } or HOW) do
			for _ = 1, 2 do
				res = send({ Url = URL, Method = "POST", Body = body, Headers = { ["Content-Type"] = "application/json", Referer = "https://www.roblox.com/", Origin = "https://www.roblox.com", ["x-csrf-token"] = csrf } }, how, SRV.cookie)
				if not res then return nil end
				if res.StatusCode == 403 and hdr(res, "x-csrf-token") then csrf = hdr(res, "x-csrf-token") else break end
			end
			if res.StatusCode ~= 401 then SRV.how = how; break end
		end
		return res
	end
	local function authCheck() -- bad cookie, or a cookie the executor never sent? status per way of attaching it, and what the executor really sends
		local c, out = tostring(SRV.cookie), {}
		for _, how in ipairs(HOW) do
			local r = send({ Url = "https://users.roblox.com/v1/users/authenticated", Method = "GET" }, how, c)
			local b = r and tostring(r.Body) or ""
			out[#out + 1] = how .. "=" .. (r and (tostring(r.StatusCode) .. "/" .. (b:match('"code":(%d+)') or "-") .. "." .. (b:match('"subcode":(%d+)') or "-")) or "fail")
		end
		local e = send({ Url = "https://httpbin.org/headers", Method = "GET" }, "header", "TEST")
		return "cookie check: " .. table.concat(out, " ") .. " | len " .. #c .. (c:find("_|WARNING", 1, true) and "" or " | no _|WARNING prefix")
			.. (e and (tostring(e.Body):find("ROBLOSECURITY=TEST", 1, true) and " | executor sends the Cookie header" or " | executor DROPS the Cookie header") or " | echo test failed")
	end
	local function viaRelay(body) -- region-relay.py on this PC does the gamejoin call with your cookie (proper cookie + csrf); nil when it is not running
		local ok, r = pcall(request, { Url = "http://127.0.0.1:47653/join", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
		SRV.relay = ok and type(r) == "table" and tonumber(r.StatusCode) ~= nil -- false = region-relay.py is not running (Home shows "Relay inactive")
		if SRV.relay then return { StatusCode = r.StatusCode, Body = r.Body } end
	end
	local MODES, ORDER = { relay = viaRelay, internal = viaInternal, api = viaApi, request = viaRequest }, { "relay", "internal", "api", "request" }
	local function resolve(placeId, jobId)
		local body = S.HttpService:JSONEncode({ placeId = placeId, isTeleport = false, gameId = jobId, gameJoinAttemptId = S.HttpService:GenerateGUID(false) })
		local notes = {}
		for _, m in ipairs(SRV.mode and { SRV.mode } or ORDER) do
			local res, why = MODES[m](body)
			if not res then
				notes[#notes + 1] = m .. ": " .. (why or "unavailable")
			else
				if res.StatusCode == 429 then return nil, "rate" end
				if res.StatusCode == 200 then
					local d = jdec(res.Body)
					local js = d and d.joinScript
					local ep = js and js.UdmuxEndpoints and js.UdmuxEndpoints[1]
					local ip = (ep and ep.Address) or (js and js.MachineAddress)
					if type(ip) == "string" and not ip:match("^10%.") then
						SRV.mode = m
						SRV.byId[jobId] = { ip = ip, t = os.time() }
						return SRV.byId[jobId]
					end
					-- a reply with a joinScript can carry a login ticket, so the raw body is only shown when there is none
					local raw = (d and d.joinScript) and "" or (" | status " .. tostring(d and d.status) .. " " .. (tostring(res.Body or ""):gsub("%s+", " ")):sub(1, 160))
					notes[#notes + 1] = m .. ": " .. ((d and d.message) or "reply has no server address") .. raw
				else
					local extra = ((tostring(res.Body or ""):gsub("%s+", " "))):sub(1, 90)
					if m == "request" and res.StatusCode == 401 then
						SRV.authNote = SRV.authNote or authCheck()
						extra = extra .. " | " .. SRV.authNote .. (csrf and "" or " | no csrf token received")
					end
					notes[#notes + 1] = m .. ": HTTP " .. tostring(res.StatusCode) .. " " .. extra
				end
			end
		end
		SRV.mode = nil
		return nil, table.concat(notes, " | ")
	end
	local function put(r, ip)
		if not r or not r.city or r.city == "" then return end
		local cc, region, country = r.countryCode or r.country_code or "", r.regionName or r.region or "", r.country or ""
		SRV.ip[ip] = { label = r.city .. ", " .. cc, cc = cc:upper(), cont = (r.continentCode or r.continent_code or ""):upper(),
			key = (r.city .. " " .. region .. " " .. country .. " " .. cc .. " " .. (r.continent or "")):lower() }
	end
	local function geo(ips) -- one batch request; per IP fallback over https
		local q = {}
		for _, ip in ipairs(ips) do q[#q + 1] = { query = ip, fields = "status,country,countryCode,regionName,city,query,continent,continentCode" } end
		local ok, res = pcall(request, { Url = "http://ip-api.com/batch", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = S.HttpService:JSONEncode(q) })
		local arr = ok and res and res.StatusCode == 200 and jdec(res.Body)
		if arr then
			for _, r in ipairs(arr) do if r.status == "success" then put(r, r.query) end end
			return true
		end
		for _, ip in ipairs(ips) do
			local body = ctx.fetch("https://ipwho.is/" .. ip)
			local r = body and jdec(body)
			if r and r.success then put(r, ip) end
		end
		return next(SRV.ip) ~= nil
	end

	-- persistent cache: server id -> { ip, scan time } and ip -> region, so a rejoin or re-exec does not rescan
	local FILE, TTL = DIR .. "/servers.json", 6 * 3600 -- shortcut: servers close on their own, so ids older than 6 h are dropped; raise TTL if you scan rarely
	function SRV.save()
		if not (HAS_FS and writefile) then return end
		local ids, ips, now = {}, {}, os.time()
		for id, e in pairs(SRV.byId) do
			if e.ip and e.t and now - e.t < TTL then ids[id] = e; ips[e.ip] = SRV.ip[e.ip] end
		end
		local ok, err = pcall(function()
			if not isfolder(DIR) then makefolder(DIR) end
			writefile(FILE, S.HttpService:JSONEncode({ ids = ids, ips = ips }))
		end)
		if not ok and not SRV.saveWarned then SRV.saveWarned = true; ctx.notify("Region cache not saved: " .. tostring(err), 8) end
	end
	pcall(function()
		if not (HAS_FS and isfile and isfile(FILE)) then return end
		local d, now = jdec(readfile(FILE)), os.time()
		if not d then return end
		for id, e in pairs(d.ids or {}) do
			if type(e) == "table" and type(e.ip) == "string" and type(e.t) == "number" and now - e.t < TTL then SRV.byId[id] = e; SRV.loaded = (SRV.loaded or 0) + 1 end
		end
		for ip, r in pairs(d.ips or {}) do if type(r) == "table" and r.label and r.key and r.cont then SRV.ip[ip] = r end end
	end)
	function SRV.running() return SRV.busy and os.clock() - (SRV.beat or 0) < 90 end -- a scan that died leaves busy set; 90 s without progress means it is dead and a new scan may start
	function SRV.region(id) local e = SRV.byId[id]; return e and SRV.ip[e.ip] end
	function SRV.match(id, q)
		local r = SRV.region(id)
		if not r then return false end
		if #q <= 2 then local c = q:upper() == "UK" and "GB" or q:upper(); return r.cc == c or r.cont == c end -- the UK's ISO code is GB -- "us", "eu", "as" are codes, not a piece of a name ("us" is inside "australia")
		return r.key:find(q, 1, true) ~= nil
	end
	function SRV.list(placeId) -- follows the page cursor (up to 10 pages); Roblox often sends fewer than 100 servers per page while more pages exist
		local out, cursor = {}, nil
		for _ = 1, 10 do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true%s"):format(placeId, cursor and ("&cursor=" .. cursor) or "")
			local body, err = ctx.fetch(url)
			local d = body and jdec(body)
			if not (d and d.data) then return out, err or "bad reply" end
			for _, s in ipairs(d.data) do out[#out + 1] = s end
			cursor = d.nextPageCursor
			if not cursor then break end
			task.wait(0.3) -- spaced out so the list call itself does not hit the rate limit
		end
		return out
	end
	-- checks the servers in chunks of 12 (4 at a time); onChunk(chunk) after each chunk, return true to stop; onChunk(nil) when finished
	function SRV.scan(placeId, servers, onChunk)
		if SRV.running() then return false end
		SRV.busy, SRV.stop, SRV.err, SRV.okN, SRV.failN, SRV.beat = true, false, nil, 0, 0, os.clock()
		-- the cap counts Roblox join requests (new servers only); servers already cached cost none, and the IP lookup is not Roblox
		local left, use = math.clamp(tonumber(cfg.srvMax) or 50, 1, 100), {}
		for _, s in ipairs(servers) do
			if (SRV.byId[s.id] and SRV.byId[s.id].ip) or left > 0 then
				if not (SRV.byId[s.id] and SRV.byId[s.id].ip) then left = left - 1 end
				use[#use + 1] = s
			end
		end
		servers = use
		task.spawn(function()
			local i = 1
			while i <= #servers and not SRV.stop and S.alive do
				local chunk = {}
				for j = i, math.min(i + 11, #servers) do chunk[#chunk + 1] = servers[j] end
				i = i + 12
				local nxt, running = 1, 0
				for _ = 1, 4 do
					running = running + 1
					task.spawn(function()
						while not SRV.stop do
							local s = chunk[nxt]
							if not s then break end
							nxt = nxt + 1
							if not (SRV.byId[s.id] and SRV.byId[s.id].ip) then
								local e, why
								for try = 1, 3 do
									local ok, a, b = pcall(resolve, placeId, s.id) -- an error here used to kill the worker, leave the scan hanging and block every later scan
									if ok then e, why = a, b else e, why = nil, tostring(a) end
									SRV.beat = os.clock()
									if why ~= "rate" or SRV.stop then break end
									task.wait(3 * try) -- rate limited: back off and retry this server instead of ending the whole scan
								end
								if e then
									SRV.okN = SRV.okN + 1
								else
									SRV.failN = SRV.failN + 1
									if why == "rate" or (SRV.okN == 0 and SRV.failN >= 4) then
										SRV.err = why == "rate" and "Roblox rate limit, try again in a minute" or why
										SRV.stop = true
									end
								end
								task.wait(0.2)
							end
						end
						running = running - 1
					end)
				end
				while running > 0 do task.wait(0.05) end
				local need, seen = {}, {}
				for _, s in ipairs(chunk) do
					local e = SRV.byId[s.id]
					if e and not SRV.ip[e.ip] and not seen[e.ip] then seen[e.ip] = true; need[#need + 1] = e.ip end
				end
				if #need > 0 and not geo(need) then SRV.err = SRV.err or "IP lookup failed (ip-api.com / ipwho.is)"; SRV.stop = true end
				SRV.save() -- every chunk, so a join / teleport / re-exec in the middle of a scan keeps what was found
				if onChunk and onChunk(chunk) then break end
			end
			SRV.busy = false
			if onChunk then onChunk(nil) end
		end)
		return true
	end
	-- joining keeps retrying while the server is full, with no "server is full" popup (Roblox's own error prompt is held back while it runs).
	-- SRV.joining = { id } while it runs; the Servers tab turns that server's Join button into Cancel (SRV.onJoin redraws it)
	function SRV.cancelJoin(quiet)
		local j = SRV.joining
		if not j then return end
		j.stop, SRV.joining = true, nil
		for _, c in ipairs(j.conns) do pcall(function() c:Disconnect() end) end
		pcall(function() if j.prompt and j.prompt.Parent then j.prompt.Enabled = j.was end end)
		if not quiet then ctx.notify("Join cancelled", 3) end
		if SRV.onJoin then SRV.onJoin() end
	end
	function SRV.join(placeId, id)
		SRV.save()
		SRV.cancelJoin(true) -- joining another server replaces the attempt that is running
		local TS, GS = S.TeleportService, S.GuiService
		local j = { id = id, stop = false, conns = {}, res = nil }
		SRV.joining = j
		pcall(function()
			j.prompt = S.CoreGui:FindFirstChild("RobloxPromptGui")
			if j.prompt then j.was = j.prompt.Enabled; j.prompt.Enabled = false end
		end)
		local function hush() pcall(function() GS:ClearError() end) end
		j.conns[1] = TS.TeleportInitFailed:Connect(function(_, res) j.res = res; hush() end)
		j.conns[2] = GS.ErrorMessageChanged:Connect(hush)
		ctx.notify("Joining server... it keeps retrying if it is full. Press Cancel to stop", 5)
		if SRV.onJoin then SRV.onJoin() end
		task.spawn(function()
			local errs, fatal = 0, nil
			while not j.stop and SRV.joining == j and S.alive do
				j.res = nil
				local ok, err = pcall(function() TS:TeleportToPlaceInstance(placeId, id, lp) end)
				local pause = 2
				if ok then
					errs = 0
					local t = os.clock()
					while not j.stop and j.res == nil and os.clock() - t < 12 do task.wait(0.1) end
					local r = j.res
					if r == Enum.TeleportResult.Flooded then pause = 5
					elseif r == Enum.TeleportResult.GameEnded or r == Enum.TeleportResult.GameNotFound then fatal = "That server no longer exists"
					elseif r == Enum.TeleportResult.Unauthorized then fatal = "You are not allowed to join that server"
					elseif r == nil then pause = 3 end -- no answer: the teleport is probably still going
				else
					errs = errs + 1
					if errs >= 8 then fatal = "Teleport failed: " .. tostring(err) end
				end
				if fatal then break end
				local t2 = os.clock()
				while not j.stop and os.clock() - t2 < pause do task.wait(0.1) end
			end
			if fatal and SRV.joining == j then
				SRV.cancelJoin(true)
				ctx.notify(fatal, 5)
			end
		end)
	end
	-- this server's own region (Home tab): the cache first, else one lookup of this JobId. Returns the label, or nil + why
	function SRV.here()
		local id = game.JobId
		if id == "" then return nil, "no job id" end
		local e = SRV.byId[id]
		if not (e and e.ip) then
			local r, why = resolve(game.PlaceId, id)
			if not r then return nil, why end
			e = r
		end
		if not SRV.ip[e.ip] and not geo({ e.ip }) then return nil, "IP lookup failed" end
		SRV.save()
		local rg = SRV.ip[e.ip]
		return rg and rg.label
	end
	-- first server that matches and has room
	function SRV.find(servers, q)
		for _, s in ipairs(servers) do
			if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 1) and SRV.match(s.id, q) then return s end
		end
	end
end
def({ "region", "joinregion" }, "<region>", "Join a server in a region: city, country or code (singapore, de, frankfurt, us). Checks servers 4 at a time and joins the first match with room", "server region location ping hop join", function(...)
	local q = table.concat({ ... }, " ") -- "new york" arrives as two arguments
	if q == "" then return ctx.notify("Usage: region <city / country / code>") end
	q = q:lower()
	local pid = game.PlaceId
	ctx.notify("Looking for a server in " .. q .. "...", 4)
	local list, err = SRV.list(pid, 2)
	if #list == 0 then return ctx.notify("Server list failed: " .. tostring(err), 5) end
	local hit = SRV.find(list, q)
	if hit then return SRV.join(pid, hit.id) end
	local found = false
	if not SRV.scan(pid, list, function(chunk)
		if not chunk then
			if not found then ctx.notify(SRV.err or ("No server with room in '" .. q .. "' among " .. #list .. " checked"), 6) end
			return
		end
		local s = SRV.find(chunk, q)
		if s then found = true; SRV.stop = true; SRV.join(pid, s.id); return true end
	end) then ctx.notify("A region scan is already running", 4) end
end)

-- ;serverhop <region> / ;scanregions / ;serverbrowser: work on the cache the scans fill, nothing here scans by itself
function SRV.hop(q)
	q = q:lower()
	local pid = game.PlaceId
	local list, err = SRV.list(pid, 1)
	if #list == 0 then return ctx.notify("Server list failed: " .. tostring(err), 5) end
	local best
	for _, s in ipairs(list) do
		if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 1) and SRV.match(s.id, q) and (not best or (s.ping or 9e9) < (best.ping or 9e9)) then best = s end
	end
	if not best then return ctx.notify("No scanned server in '" .. q .. "'. Run ;scanregions first", 5) end
	SRV.join(pid, best.id)
end
def({ "scanregions", "scanservers" }, "", "Scan the regions of this game's public servers (up to Preferences > Servers to scan); saved for ;serverhop and the Servers tab. Good for autostart", "server region scan ping", function()
	local pid = game.PlaceId
	local list, err = SRV.list(pid, 1)
	if #list == 0 then return ctx.notify("Server list failed: " .. tostring(err), 5) end
	if not SRV.scan(pid, list, function(chunk)
		if not chunk then ctx.notify(SRV.err or ("Region scan done: " .. SRV.okN .. " new servers checked"), 5) end
	end) then ctx.notify("A region scan is already running", 4) end
end)
def({ "serverbrowser", "server", "servers" }, "", "Open the server browser (Servers tab)", "server region list join", function() ctx.openTab("Servers") end)
def({ "leave", "leavegame" }, "", "Leave the game (closes the Roblox client)", "exit quit shutdown disconnect close", function() game:Shutdown() end)

-- ===== VOICE: listen / unlisten (same routing as the Players page button), nostereo / stereo =====
def({ "listen" }, "<player>", "Listen to a player's voice chat from anywhere (the game's own voice from them is muted for you)", "voice vc audio hear", function(q)
	if not q or q == "" then return ctx.notify("Usage: listen <player>") end
	local p = ctx.findPlayer(q)
	if not p then return end
	local ok, why = ctx.setListen(p.UserId, true)
	ctx.notify(ok and ("Listening to " .. p.Name) or why, ok and 3 or 5)
end)
def({ "unlisten" }, "[player]", "Stop listening to a player's voice chat (no name = stop all)", "voice vc audio hear", function(q)
	if not q or q == "" then
		local n = 0
		for uid in pairs(state.listen) do ctx.setListen(uid, false); n = n + 1 end
		return ctx.notify(n > 0 and "Stopped listening to everyone" or "You weren't listening to anyone")
	end
	local p = ctx.findPlayer(q)
	if not p then return end
	ctx.setListen(p.UserId, false)
	ctx.notify("Stopped listening to " .. p.Name)
end)

-- nostereo: every Wire AudioListener -> AudioDeviceOutput gets a Mono -> Stereo mixer pair in between, so the sound is
-- downmixed to one channel (centered) while the emitter distance volume stays. ;stereo points the wires back.
do
	local NS = { on = false, rec = {}, cons = {} }
	local function undo(w, r)
		NS.rec[w] = nil
		pcall(function() if w.Parent then w.TargetInstance = r.out end end)
		pcall(function() r.mono:Destroy() end)
		pcall(function() r.st:Destroy() end)
	end
	local function try(w)
		if not NS.on or NS.rec[w] or not w.Parent then return end
		local src, dst = w.SourceInstance, w.TargetInstance
		if not (src and dst and src:IsA("AudioListener") and dst:IsA("AudioDeviceOutput")) or dst.Name == "_klListen" then return end
		local ok = pcall(function()
			local mono = Instance.new("AudioChannelMixer")
			mono.Name, mono.Layout, mono.Parent = "_klNS", Enum.AudioChannelLayout.Mono, S.SoundService
			local st = Instance.new("AudioChannelMixer")
			st.Name, st.Layout, st.Parent = "_klNS", Enum.AudioChannelLayout.Stereo, S.SoundService
			local a, b = Instance.new("Wire"), Instance.new("Wire")
			a.SourceInstance, a.TargetInstance, a.Parent = mono, st, mono
			b.SourceInstance, b.TargetInstance, b.Parent = st, dst, st
			NS.rec[w] = { out = dst, mono = mono, st = st }
			w.TargetInstance = mono
		end)
		if not ok and NS.rec[w] then undo(w, NS.rec[w]) end
	end
	function ctx.noStereo(on)
		for _, c in ipairs(NS.cons) do c:Disconnect() end
		NS.cons = {}
		NS.on = on and true or false
		for w, r in pairs(NS.rec) do undo(w, r) end
		if not on then return true end
		local roots = { S.Players, S.SoundService, workspace }
		for _, root in ipairs(roots) do
			NS.cons[#NS.cons + 1] = root.DescendantAdded:Connect(function(o)
				if o:IsA("Wire") then task.delay(0.2, try, o) end
			end)
		end
		task.spawn(function()
			for _, root in ipairs(roots) do
				local ok, list = pcall(function() return root:GetDescendants() end)
				if ok then
					for i, o in ipairs(list) do
						if o:IsA("Wire") then try(o) end
						if i % 2000 == 0 then task.wait() end
					end
				end
			end
			if NS.on and next(NS.rec) == nil then
				ctx.notify("No proximity voice wires found yet: this game may not use the Audio API for voice. It will apply if they appear.", 6)
			end
		end)
		return true
	end
	def({ "nostereo", "mono" }, "", "Voice chat in mono: everyone centered, proximity volume kept", "voice vc audio stereo pan", function()
		ctx.noStereo(true)
		ctx.notify("Voice chat stereo off")
	end)
	def({ "stereo" }, "", "Back to normal voice chat stereo", "voice vc audio stereo pan", function()
		ctx.noStereo(false)
		ctx.notify("Voice chat stereo on")
	end)
end

-- ===== AUDIO: re-scan mic / speaker drivers =====
-- Asking the engine for its device list again makes it re-enumerate the OS drivers; selecting the default afterwards un-sticks "NoSound Driver".
-- shortcut: tries SoundService first, then VoiceChatInternal (names differ per build), when to upgrade: if neither exists on your client, add the AudioDeviceInput route
do
	local function nosound(n) return tostring(n):lower():find("nosound", 1, true) ~= nil end
	local function rescan(svc, get, set) -- returns chosen name, device count; nil if this service can't list devices
		local ok, names, guids, idx = pcall(function() return svc[get](svc) end)
		if not (ok and type(names) == "table" and #names > 0) then return nil end
		local pick = (tonumber(idx) and names[idx]) and idx or 1
		if nosound(names[pick]) then
			for j, n in ipairs(names) do
				if not nosound(n) then pick = j; break end
			end
		end
		pcall(function() svc[set](svc, names[pick], type(guids) == "table" and guids[pick] or "") end)
		return tostring(names[pick]), #names
	end
	def({ "refreshaudio", "refreshdevices" }, "", "Re-scan audio drivers and re-select the default mic and speaker (fixes \"NoSound Driver\")", "audio mic microphone speaker output input driver device voice vc nosound", function()
		local out, bad = {}, false
		for _, k in ipairs({ { "Mic", "GetInputDevices", "SetInputDevice", "GetMicDevices", "SetMicDevice" },
			{ "Speaker", "GetOutputDevices", "SetOutputDevice", "GetSpeakerDevices", "SetSpeakerDevice" } }) do
			local name, n = rescan(S.SoundService, k[2], k[3])
			if not name then name, n = rescan(S.VoiceChatInternal, k[4], k[5]) end
			if name then
				out[#out + 1] = ("%s: %s (%d found)"):format(k[1], name, n)
				if nosound(name) then bad = true end
			end
		end
		if #out == 0 then
			return ctx.notify("Couldn't read the device list from this client. Restart the Windows Audio service (or replug the device), then run this again", 7)
		end
		ctx.notify("Audio re-scanned. " .. table.concat(out, " | ") .. (bad and ". Roblox still only sees NoSound: the driver itself is broken in Windows, fix it there first" or ""), 7)
	end)
end

-- ===== HIDE: a player's avatar and every sound from them, client side only =====
-- Avatar: parts / decals / name tag / effects under their character are made invisible. Sounds: every Sound in their character
-- (footsteps, held guns) is moved into a silent SoundGroup, All of it is put back by ;unhide. Voice and chat are muted too (;mute), ;unhide undoes that.
-- shortcut: only sounds that live inside the character are caught (a sound a game plays from a part elsewhere is not), when to upgrade: tag sounds by nearest hidden character position
do
	local H = {} -- uid -> { rec = { instance -> { prop -> { original } } } }
	local grp
	local function group()
		if not (grp and grp.Parent) then
			grp = Instance.new("SoundGroup")
			grp.Name, grp.Volume, grp.Parent = "_klHide", 0, S.SoundService
		end
		return grp
	end
	local function setp(h, inst, prop, val)
		local ok, old = pcall(function() return inst[prop] end)
		if not ok then return end
		local r = h.rec[inst]
		if not r then r = {}; h.rec[inst] = r end
		if r[prop] == nil then r[prop] = { old } end -- boxed, so an original of nil still counts as stored
		pcall(function() inst[prop] = val end)
	end
	local function cover(h, o)
		if o:IsA("BasePart") then setp(h, o, "LocalTransparencyModifier", 1)
		elseif o:IsA("Decal") or o:IsA("Texture") then setp(h, o, "Transparency", 1)
		elseif o:IsA("BillboardGui") or o:IsA("SurfaceGui") or o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") or o:IsA("Highlight") then setp(h, o, "Enabled", false)
		elseif o:IsA("Humanoid") then setp(h, o, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
		elseif o:IsA("Sound") then setp(h, o, "SoundGroup", group())
		elseif o:IsA("AudioPlayer") then setp(h, o, "Volume", 0) end
	end
	local Q, qh, qt = {}, 1, 0
	ctx.connect("hideQ", RS.Heartbeat, function() -- parts / sounds added to a hidden character are covered 40 per frame, so a game spawning many cannot stall a frame
		for _ = 1, 40 do
			if qh > qt then
				if qt > 0 then Q, qh, qt = {}, 1, 0 end
				return
			end
			local e = Q[qh]
			Q[qh], qh = nil, qh + 1
			if H[e[3]] == e[1] and e[2].Parent then pcall(cover, e[1], e[2]) end
		end
	end)
	local function watch(p, h)
		local key = "hide_" .. p.UserId
		local function char(c)
			if not c then return end
			for _, o in ipairs(c:GetDescendants()) do cover(h, o) end
			ctx.connect(key .. "d", c.DescendantAdded, function(o) qt = qt + 1; Q[qt] = { h, o, p.UserId } end) -- tools, sounds and accessories added later (covered by hideQ)
		end
		char(p.Character)
		ctx.connect(key, p.CharacterAdded, function(c) task.defer(char, c) end)
	end
	function ctx.isHidden(uid) return H[uid] ~= nil end
	function ctx.hidePlayer(uid, on)
		local h = H[uid]
		if not on then
			if not h then return false end
			H[uid] = nil
			ctx.disconnect("hide_" .. uid); ctx.disconnect("hide_" .. uid .. "d")
			for inst, props in pairs(h.rec) do
				for prop, box in pairs(props) do pcall(function() inst[prop] = box[1] end) end
			end
			if h.muted and state.muted[uid] then ctx.setMuted(uid, false) end -- only if hide muted them
			if not next(H) and grp then pcall(function() grp:Destroy() end); grp = nil end
			state.active.hide = next(H) and true or nil
			return true
		end
		local p = S.Players:GetPlayerByUserId(uid)
		if h or not p or p == lp then return false end
		h = { rec = {} } -- a plain table: weak Instance keys can drop a part that still exists, and ;unhide would leave it invisible
		H[uid] = h
		if not state.muted[uid] then h.muted = true; ctx.setMuted(uid, true) end -- gone for good: voice and chat muted too
		watch(p, h)
		state.active.hide = true
		return true
	end
	ctx.connect("hideLeave", Players.PlayerRemoving, function(p) ctx.hidePlayer(p.UserId, false) end)
	def({ "hide" }, "<player>", "Make a player gone: avatar hidden, every sound from their character silenced, voice and chat muted (;unhide undoes it)", "hide invisible mute footsteps audio avatar gun", function(q)
		if not q then return ctx.notify("Usage: hide <player>") end
		local n = 0
		for _, p in ipairs(ctx.findPlayers(q)) do
			if ctx.hidePlayer(p.UserId, true) then n = n + 1 end
		end
		ctx.notify(n > 0 and ("Hid " .. n .. " player(s)") or "Nobody to hide")
	end)
	def({ "unhide" }, "<player|all>", "Show a hidden player again (no name = everyone)", "hide show visible unmute", function(q)
		local n = 0
		if not q or q:lower() == "all" then
			for uid in pairs(H) do
				if ctx.hidePlayer(uid, false) then n = n + 1 end
			end
		else
			for _, p in ipairs(ctx.findPlayers(q)) do
				if ctx.hidePlayer(p.UserId, false) then n = n + 1 end
			end
		end
		ctx.notify(n > 0 and ("Unhid " .. n .. " player(s)") or "Nobody was hidden")
	end)
end

-- ===== PLACEHOLDER1: a tool that plays an animation while equipped (ported from an Infinite Yield command) =====
-- Fixes vs the original: no global flag, no endless busy loop (it stops on unequip / death / ;unplaceholder1), speed is live from Module Cfg.
do
	local P = {}
	local function stopAnim()
		P.run = nil
		if P.track then pcall(function() P.track:Stop(0) end); P.track = nil end
	end
	local function startAnim()
		local h = ctx.hum()
		if not h then return end
		local token = {}
		P.run = token
		task.spawn(function()
			local r15 = h.RigType == Enum.HumanoidRigType.R15
			local a = Instance.new("Animation")
			a.AnimationId = r15 and "rbxassetid://698251653" or "rbxassetid://72042024"
			local ok, track = pcall(function() return (h:FindFirstChildOfClass("Animator") or h):LoadAnimation(a) end)
			if not ok or not track then return ctx.notify("Placeholder1: couldn't load the animation") end
			if P.run ~= token then return end
			P.track = track
			local lo, hi = 0.6, r15 and 0.7 or 0.65
			track.Priority = Enum.AnimationPriority.Action
			track:Play(0)
			track:AdjustSpeed(0) -- the time position is driven by hand below, so it can run backwards too
			local t, dir = lo, 1
			while P.run == token and S.alive do
				local dt = task.wait()
				t = t + dir * math.max(P.speed or tonumber(mod.ph1Mult) or 1, 0.05) * dt -- base speed 1; the Module Cfg value multiplies it, read live
				if t >= hi then t, dir = hi, -1 elseif t <= lo then t, dir = lo, 1 end
				track.TimePosition = t
			end
			pcall(function() track:Stop(0) end)
		end)
	end
	local function strip()
		stopAnim()
		for _, k in ipairs({ "ph1Eq", "ph1Un", "ph1Died" }) do ctx.disconnect(k) end
		for _, root in ipairs({ lp:FindFirstChildOfClass("Backpack"), ctx.char() }) do
			for _, t in ipairs(root and root:GetChildren() or {}) do
				if t:IsA("Tool") and t.Name == "Placeholder1" then t:Destroy() end
			end
		end
		P.tool = nil
	end
	def({ "placeholder1" }, "[animation speed]", "Get the Placeholder1 tool (equip it to play the animation); with a number it spawns with that speed, or changes the speed of the one you have", "tool animation hand gesture speed", function(sp)
		local n = tonumber(sp)
		if sp and not n then return ctx.notify("Placeholder1: the speed has to be a number") end
		local bp, h = lp:FindFirstChildOfClass("Backpack"), ctx.hum()
		if not (bp and h) then return end
		if P.tool and (P.tool.Parent == bp or P.tool.Parent == ctx.char()) then
			if n then P.speed = n; return ctx.notify("Placeholder1 speed: " .. n) end
			return ctx.notify("Placeholder1 is already in your inventory")
		end
		P.speed = n
		stopAnim() -- a tool left over from before a death can still have a parent (the old character): it is not yours any more, drop its animation first
		local t = Instance.new("Tool")
		t.Name, t.ToolTip, t.RequiresHandle, t.CanBeDropped = "Placeholder1", "Placeholder1", false, false
		t.Parent = bp
		P.tool = t
		ctx.connect("ph1Eq", t.Equipped, function() stopAnim(); startAnim() end)
		ctx.connect("ph1Un", t.Unequipped, stopAnim)
		ctx.connect("ph1Died", h.Died, stopAnim)
	end)
	def({ "unplaceholder1" }, "", "Remove the Placeholder1 tool from your inventory", "tool animation remove", strip)
end

-- ===== PLAYER COLLISION =====
do
	local was = setmetatable({}, { __mode = "k" }) -- parts that were solid before we made them walk-through
	local function restore()
		for part in pairs(was) do pcall(function() part.CanCollide = true end) end
		was = setmetatable({}, { __mode = "k" })
	end
	def({ "noplayercollision", "noplayercollide", "nopc", "nopcol", "nopcollide", "noplayercollusion" }, "", "Walk through other players (client side)", "collide collision collusion ghost pass through players", function()
		local function sweep() -- the humanoid / game switches collision back on every frame: set it again right before physics, whatever it reads now
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p ~= lp and p.Character
				for _, part in ipairs(c and c:GetChildren() or {}) do
					if part:IsA("BasePart") then
						if part.CanCollide then was[part] = true end
						part.CanCollide = false
					end
				end
			end
		end
		ctx.connect("noPlayerCol", RS.Stepped, sweep)
		ctx.connect("noPlayerCol2", RS.PreSimulation, sweep)
	end)
	def({ "playercollision", "playercollide", "pc", "pcol", "pcollide", "playercollusion" }, "", "Other players are solid again (undoes ;noplayercollision)", "collide collision collusion players", function()
		ctx.disconnect("noPlayerCol")
		ctx.disconnect("noPlayerCol2")
		restore()
	end)
end

-- ===== ALTS: ;sudo and the Accounts list, through region-relay.py (one relay for every instance on this PC) =====
do
	local HS, BASE = S.HttpService, "http://127.0.0.1:47653/alt"
	state.alts = {} -- userId -> info of the OTHER accounts connected to the relay
	local function post(path, t)
		local ok, r = pcall(request, { Url = BASE .. path, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HS:JSONEncode(t) })
		if ok and type(r) == "table" and r.StatusCode == 200 then
			local ok2, d = pcall(HS.JSONDecode, HS, r.Body)
			if ok2 and type(d) == "table" then return d end
		end
	end
	local sig = ""
	task.spawn(function()
		local fails = 0
		while S.alive do
			local d = post("/ping", { id = tostring(lp.UserId), userId = lp.UserId, name = lp.Name, displayName = lp.DisplayName, placeId = game.PlaceId, jobId = game.JobId })
			if d then
				fails = 0
				local alts, parts = {}, {}
				for _, a in ipairs(d.alts or {}) do alts[a.userId] = a; parts[#parts + 1] = a.userId .. ":" .. tostring(a.jobId) end
				table.sort(parts)
				local s = table.concat(parts, ",")
				if s ~= sig then sig, state.alts, state.altsRev = s, alts, (state.altsRev or 0) + 1 end
				for _, c in ipairs(d.cmds or {}) do
					if type(c) == "string" and not (c:lower():match("^%s*;?sudo") or c:lower():match("^%s*;?all%f[%A]")) then -- never sudo inside sudo: no loops between accounts
						ctx.notify("sudo: " .. c)
						task.spawn(ctx.Run, c)
					end
				end
			else
				fails = fails + 1 -- relay not running: back off to every 5 s
				if sig ~= "" then sig, state.alts, state.altsRev = "", {}, (state.altsRev or 0) + 1 end
			end
			task.wait(fails > 3 and 5 or 1.5)
		end
	end)
	-- sudo: the OTHER accounts run it (you do not); all: the other accounts and this one
	local function bcast(withSelf, ...)
		local a = { ... }
		local to = "others"
		if a[1] and a[1]:sub(1, 1) == "@" then to = table.remove(a, 1):sub(2):lower() end
		local text = table.concat(a, " ")
		if text == "" then return ctx.notify("Usage: " .. (withSelf and "all" or "sudo") .. " [@alt] <command>") end
		local low = text:lower()
		if low:match("^;?sudo") or low:match("^;?all%f[%A]") then return ctx.notify("Not inside sudo / all") end
		local d = post("/send", { from = tostring(lp.UserId), to = to, cmd = text })
		if withSelf then task.spawn(ctx.Run, text) end
		if not d then return ctx.notify("The relay does not answer (start region-relay.py)" .. (withSelf and ", ran it here only" or "")) end
		local n = d.sent or 0
		ctx.notify(n > 0 and ("Sent to %d account(s): %s"):format(n, text) or "No other account is connected to the relay")
	end
	def({ "sudo" }, "[@alt] <command>", "Run a command on your OTHER accounts (not this one; needs region-relay.py running)", "alt alts multi instance accounts everywhere execute run", function(...) bcast(false, ...) end)
	def({ "all" }, "[@alt] <command>", "Run a command on this account AND your other accounts (needs region-relay.py running)", "alt alts multi instance accounts everywhere execute run every", function(...) bcast(true, ...) end)
	-- while the @alt part is being typed, the bar suggests your connected accounts (Tab fills "sudo @name ")
	local function altChoices(i, partial)
		local out = {}
		if i == 1 and partial:sub(1, 1) == "@" then
			for _, a in pairs(state.alts or {}) do
				out[#out + 1] = { text = "@" .. a.name, desc = (a.displayName and a.displayName ~= "") and a.displayName or "" }
			end
		end
		return out
	end
	ctx.Meta.sudo.complete, ctx.Meta.all.complete = altChoices, altChoices
end

-- ===== MOUSE =====
local UISv = UIS
def({ "lockmouse" }, "", "Lock the mouse to the centre, like shift lock", "shiftlock cursor camera", function()
	ctx.connect("lockmouse", RS.RenderStepped, function()
		if not S.mouseFree then UISv.MouseBehavior = Enum.MouseBehavior.LockCenter end
	end)
end)
def({ "unlockmouse" }, "", "Unlock the mouse", "shiftlock cursor camera", function()
	ctx.disconnect("lockmouse")
	UISv.MouseBehavior = Enum.MouseBehavior.Default
end)
def({ "enableshiftlock", "enablesl" }, "", "Turn shift lock on as an option in the Roblox client", "mouse lock camera", function()
	pcall(function() lp.DevEnableMouseLock = true end)
	ctx.notify("Shift lock enabled")
end)
def({ "ctrllock", "controllock" }, "", "Make Left Ctrl the shift lock button instead of Shift", "mouse lock camera", function()
	pcall(function() lp.DevEnableMouseLock = false end)
	local locked = false
	ctx.connect("ctrllock", UIS.InputBegan, function(i)
		if i.KeyCode == Enum.KeyCode.LeftControl and not typing() then
			locked = not locked
			if locked then
				ctx.connect("ctrllockLoop", RS.RenderStepped, function()
					if not S.mouseFree then UISv.MouseBehavior = Enum.MouseBehavior.LockCenter end
				end)
			else
				ctx.disconnect("ctrllockLoop")
				UISv.MouseBehavior = Enum.MouseBehavior.Default
			end
		end
	end)
end)
def({ "unctrllock", "uncontrollock" }, "", "Put shift lock back on Shift", "mouse lock camera", function()
	ctx.disconnect("ctrllock"); ctx.disconnect("ctrllockLoop")
	pcall(function() lp.DevEnableMouseLock = true end)
	UISv.MouseBehavior = Enum.MouseBehavior.Default
end)

-- shift lock toggle through Roblox's own camera controller (what the Shift key does), for when the Shift keys are taken
def({ "toggleshiftlock", "shiftlock", "shl" }, "", "Toggle shift lock (for when the Shift key is taken)", "mouse lock camera shift", function()
	local ok, err = pcall(function()
		require(lp.PlayerScripts:WaitForChild("PlayerModule", 3)):GetCameras().activeMouseLockController:OnMouseLockToggled()
	end)
	if not ok then ctx.notify("Shift lock toggle failed (" .. tostring(err) .. "). Try ;enableshiftlock first", 5) end
end)

-- ===== CROSSHAIR: static CS style crosshair, look is set in Module Cfg (mode, length, gap, thickness, outline, colour) =====
-- "Replace Roblox cursor" on: the crosshair follows the mouse and the real cursor is hidden. Off: fixed at the screen center, and the real cursor is hidden only while the mouse is locked to the center (otherwise you see it).
do
	local CH = { gui = nil, root = nil, prevIcon = nil }
	local function rect(parent, x, y, w, h, color, alpha, z)
		new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = color,
			BackgroundTransparency = 1 - alpha, BorderSizePixel = 0, ZIndex = z }, parent)
	end
	local function build()
		local M = cfg.mod
		local len = math.max(0, math.floor(tonumber(M.chLen) or 0))
		local gap = math.floor(tonumber(M.chGap) or 0)
		local th = math.max(1, math.floor(tonumber(M.chThick) or 1))
		local ol = math.max(0, math.floor(tonumber(M.chOutline) or 0))
		local oa = math.clamp(tonumber(M.chOutlineAlpha) or 1, 0, 1)
		local col = parseHex(M.chColor) or rgb(0, 255, 0)
		local h1 = math.floor(th / 2)
		local od = th % 2 -- odd thickness: the line sits on one pixel, so the far side arms start 1px later to keep the gap symmetric
		local rects = {}
		if M.chStyle == "Dot" then
			rects[1] = { -h1, -h1, th, th }
		elseif len > 0 then
			rects[#rects + 1] = { -h1, gap + od, th, len } -- bottom
			rects[#rects + 1] = { -(gap + len), -h1, len, th } -- left
			rects[#rects + 1] = { gap + od, -h1, len, th } -- right
			if M.chStyle ~= "T" then rects[#rects + 1] = { -h1, -(gap + len), th, len } end -- top (a T has none)
		end
		CH.root:ClearAllChildren()
		if ol > 0 and oa > 0 then
			for _, r in ipairs(rects) do rect(CH.root, r[1] - ol, r[2] - ol, r[3] + ol * 2, r[4] + ol * 2, rgb(0, 0, 0), oa, 1) end
		end
		for _, r in ipairs(rects) do rect(CH.root, r[1], r[2], r[3], r[4], col, 1, 2) end
	end
	local GuiService = game:GetService("GuiService")
	-- the real cursor is hidden only while the mouse is locked to the center (LockCenter): shift lock, first person
	local function place()
		ctx.disconnect("chFollow")
		if cfg.mod.chCursor then
			if CH.prevIcon == nil then CH.prevIcon = UIS.MouseIconEnabled end
			ctx.connect("chFollow", RS.RenderStepped, function()
				local m = UIS:GetMouseLocation()
				CH.root.Position = UDim2.fromOffset(m.X, m.Y)
				UIS.MouseIconEnabled = false
			end)
		else
			CH.root.Position = UDim2.fromScale(0.5, 0.5)
			local gsz = CH.gui and CH.gui.AbsoluteSize
			if gsz then CH.root.Position = UDim2.fromOffset(math.floor(gsz.X / 2), math.floor(gsz.Y / 2)) end -- whole pixel, no half pixel blur on odd screen sizes
			ctx.connect("chFollow", RS.RenderStepped, function() -- the cursor would only sit next to the fixed crosshair
				local hide = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter and not S.mouseFree and not GuiService.MenuIsOpen
				if hide then
					if CH.prevIcon == nil then CH.prevIcon = UIS.MouseIconEnabled end
					UIS.MouseIconEnabled = false
				elseif CH.prevIcon ~= nil and not ctx.cursorOff then
					UIS.MouseIconEnabled = CH.prevIcon; CH.prevIcon = nil
				end
			end)
		end
	end
	function ctx.crosshair(on)
		if not on then
			ctx.disconnect("chFollow")
			if CH.gui then pcall(function() CH.gui:Destroy() end) end
			CH.gui, CH.root = nil, nil
			if CH.prevIcon ~= nil then UIS.MouseIconEnabled = CH.prevIcon; CH.prevIcon = nil end
			return
		end
		if not CH.gui then
			CH.gui = new("ScreenGui", { Name = "KLCrosshair", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 9999,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
			CH.root = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5) }, CH.gui)
			local ok = pcall(function() CH.gui.Parent = (gethui and gethui()) or S.CoreGui end)
			if not ok or not CH.gui.Parent then CH.gui.Parent = lp:WaitForChild("PlayerGui") end
		end
		build(); place()
	end
	-- Module Cfg calls this after any value changes, so the crosshair updates live
	function ctx.onMod(key)
		key = tostring(key)
		if CH.gui and key:match("^ch%u") then build(); place() end
		if key:match("^esp") and ctx.espRefresh then ctx.espRefresh() end
		if (key:match("^srv") or key:match("^pred")) and ctx.srvRefresh then ctx.srvRefresh() end
		if key == "actCorner" and ui.actLayout then ui.actLayout() end
	end
end
def({ "crosshair", "xhair" }, "", "Show a static CS style crosshair (mode, length, gap, thickness, outline, colour in Module Cfg)", "aim reticle cs dot", function()
	ctx.crosshair(true)
end)
def({ "removecrosshair", "nocrosshair", "uncrosshair" }, "", "Remove the crosshair", "aim reticle cs", function()
	ctx.crosshair(false)
	ctx.notify("Crosshair removed")
end)

-- ===== HIDE CURSOR: keeps the Roblox cursor hidden; ui.syncMouse shows it again while the panel or command bar is open =====
do
	local prev
	function ctx.hideCursor(on)
		ctx.disconnect("hideCursor")
		ctx.cursorOff = on and true or false
		if not on then
			if prev ~= nil then UIS.MouseIconEnabled = prev; prev = nil end
			return
		end
		if prev == nil then prev = UIS.MouseIconEnabled end
		ctx.connect("hideCursor", RS.RenderStepped, function()
			if not S.mouseFree then UIS.MouseIconEnabled = false end
		end)
	end
	def({ "hidecursor", "hidemouse" }, "", "Hide the Roblox cursor (it still shows while the panel or command bar is open)", "mouse pointer cursor hide invisible", function() ctx.hideCursor(true) end)
	def({ "unhidecursor", "unhidemouse" }, "", "Show the Roblox cursor again", "mouse pointer cursor show", function() ctx.hideCursor(false) end)
end

-- ===== PERFORMANCE / DISPLAY =====
def({ "showfps", "showperf", "showping" }, "", "Show FPS and ping in a corner (corner set in Module Cfg)", "performance frame rate latency overlay", function()
	if ui.showHud then ui.showHud(true) end
	active("showfps", true)
end)
def({ "unshowfps", "hidefps", "unshowping", "hideping", "unshowperf", "hideperf" }, "", "Hide the FPS / ping overlay", "performance overlay", function()
	if ui.showHud then ui.showHud(false) end
	active("showfps", nil)
end)

-- ===== REPORT: ;report <type> <player> <reason> [additional] =====
-- Sends a real Roblox report through Players:ReportAbuse (the same thing the in-game report menu uses). One player at a time, never me / all / others / random.
-- The command bar fills in the type, the player and the reason as you type (Tab accepts the highlighted one): see Meta.report.complete and ui.argSuggest.
do
	local TYPES = {
		chat = { swearing = "Swearing", bullying = "Bullying", scamming = "Scamming", dating = "Dating", personal = "Personal Question", links = "Offsite Links" },
		username = { inappropriate = "Inappropriate Username" },
		voice = { swearing = "Swearing", bullying = "Bullying", scamming = "Scamming", dating = "Dating", personal = "Personal Question", links = "Offsite Links" },
		exploit = { cheating = "Cheating/Exploiting" },
	}
	local TYPE_DESC = { chat = "Something they said in chat", voice = "Something they said in voice chat", username = "Their username", exploit = "Cheating / exploiting" }
	local function keys(t) local k = {} for n in pairs(t) do k[#k + 1] = n end table.sort(k) return table.concat(k, ", ") end
	def({ "report" }, "<type> <player> <reason> [additional]", "Report a player to Roblox (types: chat, voice, username, exploit). The bar fills in types, players and reasons", "report abuse moderation chat exploit cheating scam bully swear", function(tp, who, rs, ...)
		if not (tp and who) then return ctx.notify("Usage: report <type> <player> <reason> [additional]") end
		local T = TYPES[tp:lower()]
		if not T then return ctx.notify("Unknown report type '" .. tp .. "'. Types: " .. keys(TYPES), 5) end
		if ({ me = 1, all = 1, others = 1, random = 1 })[who:lower()] then return ctx.notify("Report one player by name") end
		local p = ctx.findPlayer(who)
		if not p then return end
		if p == lp then return ctx.notify("You can't report yourself") end
		local reason, extra = rs and T[rs:lower()], { ... }
		if not reason then
			local only, n = nil, 0
			for _, v in pairs(T) do only, n = v, n + 1 end
			if n == 1 and not rs then reason = only
			else return ctx.notify("Pick a reason for " .. tp:lower() .. ": " .. keys(T), 6) end
		end
		local note = table.concat(extra, " "):sub(1, 200)
		-- the report call has no voice category of its own: a voice report goes in with the normal reason and a tag in the comment
		if tp:lower() == "voice" then note = (("[Voice chat] " .. note):gsub("%s+$", "")):sub(1, 200) end
		local ok, err = pcall(function() ctx.Players:ReportAbuse(p, reason, note) end)
		if ok then return ctx.notify("Reported " .. p.Name .. " for " .. reason .. (note ~= "" and (": " .. note) or ""), 5) end
		-- ReportAbuse is a secured Roblox API: the engine / executor refuses it ("dangerous call"), so a script cannot send a report.
		-- Fallback: the text is copied and Roblox's own menu is opened, so you only pick Report > Person > the player.
		local text = ("%s | %s%s"):format(p.Name, reason, note ~= "" and (" | " .. note) or "")
		if setclipboard then pcall(setclipboard, text) end
		pcall(function() S.GuiService:SetMenuIsOpen(true) end)
		ctx.notify("Scripts can't send reports (" .. tostring(err):sub(1, 70) .. "). Roblox's menu is open: Report > Person > " .. p.Name .. " > " .. reason .. (setclipboard and ". Your note is copied." or ""), 10)
	end)
	ctx.Meta.report.complete = function(i, partial, prev) -- i = which argument is being typed, prev = the ones before it
		local out = {}
		if i == 1 then
			for k in pairs(TYPES) do out[#out + 1] = { text = k, desc = TYPE_DESC[k] } end
		elseif i == 2 then
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= lp then out[#out + 1] = { text = pl.Name, desc = pl.DisplayName ~= pl.Name and pl.DisplayName or "" } end
			end
		elseif i == 3 then
			for k, v in pairs(TYPES[(prev[1] or ""):lower()] or {}) do out[#out + 1] = { text = k, desc = v } end
		end
		table.sort(out, function(a, b) return a.text:lower() < b.text:lower() end)
		return out
	end
end

-- ===== CHAT =====
def({ "text", "chat", "t" }, "<message>", "Send a chat message", "say talk message", function(...)
	local msg = table.concat({ ... }, " ")
	if msg == "" then return ctx.notify("Usage: text <message>") end
	local ok = pcall(function() ctx.TextChatService.TextChannels.RBXGeneral:SendAsync(msg) end)
	if not ok then
		pcall(function() game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end)
	end
end)

-- ===== RESET =====
local function mode(list)
	local count, best, bc = {}, nil, 0
	for _, v in ipairs(list) do
		local k = math.floor(v * 100 + 0.5)
		count[k] = (count[k] or 0) + 1
		if count[k] > bc then best, bc = v, count[k] end
	end
	return best
end
-- A client can't ask the server for its own values after changing them, but other players' humanoids still carry what the
-- server gave them. The most common value among them is the best "server default" available.
local function serverHumanoid()
	local ws, jp, jh, ujp = {}, {}, {}, {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hh = p ~= lp and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hh then
			ws[#ws + 1] = hh.WalkSpeed
			if hh.UseJumpPower then jp[#jp + 1] = hh.JumpPower else jh[#jh + 1] = hh.JumpHeight end
			ujp[#ujp + 1] = hh.UseJumpPower and 1 or 0
		end
	end
	return mode(ws), mode(jp), mode(jh), mode(ujp)
end
def({ "gamedefault", "default", "reffect", "reseteffects" }, "", "Reset every command's changes back to the server's defaults", "reset restore undo", function()
	ctx.resetAll()
	local d, h = state.defaults, ctx.hum()
	local ws, jp, jh, ujp = serverHumanoid()
	if h then
		local useJP
		if ujp ~= nil then useJP = ujp == 1 else useJP = d.ujp ~= false end
		h.WalkSpeed = ws or d.ws
		h.UseJumpPower = useJP
		h.JumpPower, h.JumpHeight = jp or d.jp, jh or d.jh
		h.HipHeight, h.AutoRotate, h.PlatformStand = d.hip, true, false
		workspace.CurrentCamera.CameraSubject = h
	end
	workspace.Gravity = d.grav
	workspace.CurrentCamera.FieldOfView = d.fov
	pcall(function()
		lp.CameraMinZoomDistance = S.StarterPlayer.CameraMinZoomDistance
		lp.CameraMaxZoomDistance = S.StarterPlayer.CameraMaxZoomDistance
	end)
	for k, v in pairs(state.saved.light or d.light) do ctx.Lighting[k] = v end
	state.saved.light = nil
	ctx.lockFps(nil)
	if setfpscap then pcall(setfpscap, 60) end
	ctx.notify("Back to the game's defaults")
end)

-- ;clear / ;cls [effect...]: no argument = switch off every movement effect and put speed, jump and gravity back to the
-- server's values; with one or more effects (fly, noclip, ws, jp, gravity...) only those
do
	local MOVE = { "fly", "cfly", "noclip", "float", "jesus", "tpwalk", "infjump", "spin", "look", "freeze", "follow" }
	local function off(what) -- what = canonical command name; true if it knows how to clear it
		local h, d = ctx.hum(), state.defaults
		if what == "gravity" then workspace.Gravity = d.grav; return true end
		if what == "speed" or what == "jumppower" then -- value commands have no off switch: restore what the server gave
			local ws, jp, jh, ujp = serverHumanoid()
			if h and what == "speed" then h.WalkSpeed = ws or d.ws end
			if h and what == "jumppower" then
				if ujp ~= nil then h.UseJumpPower = ujp == 1 else h.UseJumpPower = d.ujp ~= false end
				h.JumpPower, h.JumpHeight = jp or d.jp, jh or d.jh
			end
			return true
		end
		if TOGGLES[what] then ctx.Run(TOGGLES[what]); state.active[what] = nil; return true end
	end
	def({ "clear", "cls" }, "[effect...]", "Clear movement effects (fly, noclip, float, walkspeed...), or only the ones you name", "reset stop off movement", function(...)
		local want = { ... }
		if #want == 0 then
			for _, n in ipairs(MOVE) do if state.active[n] then off(n) end end
			for _, n in ipairs({ "speed", "jumppower", "gravity" }) do off(n) end
			return ctx.notify("Cleared movement effects")
		end
		for _, q in ipairs(want) do
			local c = ctx.Aliases[q:lower()]
			if not (c and off(c)) then ctx.notify("Can't clear \"" .. q .. "\"") end
		end
	end)
end

-- ===== GAME SPECIFIC =====
-- place ids from the two game pages: MIC UP 18+ and MIC UP
local MICUP = { [15546218972] = true, [6884319169] = true }
-- endless SmoothPlastic floor: tiles of up to 2048 studs (the part size limit) on a fixed grid, kept as a 3 x 3 block around you AND around the camera focus
-- (spectating far away), re-placed only when one of them crosses into another grid cell, so at most 18 parts ever exist. The game's own baseplate
-- (648 x 16 x 648 at 8, -8, -482) is found by size + position, never by name, and is left alone: only its top height, color and textures are copied.
-- The tiles sit 0.05 studs under its top, so inside its footprint they are hidden by it (no z-fighting) and outside it they look the same
do
	local B = { cells = {} }
	local function gameBase()
		for _, o in ipairs(workspace:GetDescendants()) do
			if o:IsA("BasePart") and (o.Size - Vector3.new(648, 16, 648)).Magnitude < 0.5 and (o.Position - Vector3.new(8, -8, -482)).Magnitude < 0.5 then return o end
		end
	end
	function ctx.baseplate(on)
		ctx.disconnect("baseplate")
		for _, e in pairs(B.cells) do pcall(e.v.Destroy, e.v); pcall(e.c.Destroy, e.c) end
		B.cells, state.baseParts = {}, {}
		if not on then return true end
		-- The floor is only added OUTSIDE the game's own ground (the baseplate + the extra platforms). It never overlaps a part, so nothing can z-fight and nothing is cut around.
		local base, top = gameBase(), nil
		if base then
			top = base.Position.Y + base.Size.Y / 2
		else -- the game changed its baseplate: the part you stand on is the reference
			local r = ctx.root()
			if not r then return false, "No character" end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { ctx.char() }
			local hit = workspace:Raycast(r.Position, Vector3.new(0, -300, 0), params)
			if not (hit and hit.Instance:IsA("BasePart")) then return false, "Stand on the baseplate first, then run baseplate" end
			base, top = hit.Instance, hit.Position.Y
		end
		-- footprint of the ground = the baseplate plus every extra platform at the same height (parts named "platform", or inside a folder called extra_room)
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		local function add(p)
			if math.abs(p.Position.Y + p.Size.Y / 2 - top) > 0.5 then return end -- only parts whose top is at ground level
			local c, s = p.CFrame, p.Size
			local rv, uv, lv = c.RightVector, c.UpVector, c.LookVector
			local hx = (math.abs(rv.X) * s.X + math.abs(uv.X) * s.Y + math.abs(lv.X) * s.Z) / 2 -- half width along X, rotation included
			local hz = (math.abs(rv.Z) * s.X + math.abs(uv.Z) * s.Y + math.abs(lv.Z) * s.Z) / 2
			minX, maxX = math.min(minX, p.Position.X - hx), math.max(maxX, p.Position.X + hx)
			minZ, maxZ = math.min(minZ, p.Position.Z - hz), math.max(maxZ, p.Position.Z + hz)
		end
		add(base)
		for _, o in ipairs(workspace:GetDescendants()) do
			if o:IsA("BasePart") and o ~= base and (o.Name == "platform" or (o.Parent and o.Parent.Name == "extra_room")) then add(o) end
		end
		local x0, z0 = minX, minZ
		local W, D = math.min(maxX - minX, 2048), math.min(maxZ - minZ, 2048) -- one tile = exactly the size of that footprint (a part is 2048 studs at most), so the footprint itself is cell 0,0 and is skipped
		local tex = {}
		for _, t in ipairs(base:GetChildren()) do if t:IsA("Texture") then tex[#tex + 1] = t end end
		local color = rgb(25, 25, 25) -- very dark grey
		-- baseplateoffset: DROP = how far (studs) the floor sits under the ground level. 0 = level with it; the floor never overlaps the game's parts, so 0 is safe. THICK = the see-through skin (thin, so no side walls show where tiles meet)
		local THICK, DROP = 0.1, 0 -- baseplateoffset
		local function make()
			local v = Instance.new("Part")
			v.Name, v.Anchored, v.CanCollide, v.CanTouch, v.CanQuery, v.CastShadow, v.Locked = "_baseplateExt", true, false, false, false, false, true
			v.Material, v.Transparency, v.Color, v.Reflectance = Enum.Material.SmoothPlastic, 0.5, color, 0.1 -- 50% opacity, 10% reflectance
			v.TopSurface, v.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			v.Size = Vector3.new(W, THICK, D)
			for _, t in ipairs(tex) do
				local c = t:Clone()
				c.Parent = v
			end
			v.Parent = workspace
			local c = Instance.new("Part") -- invisible 16 stud slab: the part you actually stand on
			c.Name, c.Anchored, c.CanCollide, c.CanTouch, c.CastShadow, c.Locked, c.Transparency = "_baseplateExtCol", true, true, false, false, true, 1
			c.Size = Vector3.new(W, 16, D)
			c.Parent = workspace
			return { v = v, c = c }
		end
		local function sync()
			local want = {}
			local function around(pos) -- 5 x 5 cells around you and around the camera focus, never cell 0,0 (the game's own ground)
				if not pos then return end
				local cx, cz = math.floor((pos.X - x0) / W), math.floor((pos.Z - z0) / D)
				for dx = -2, 2 do
					for dz = -2, 2 do
						local ix, iz = cx + dx, cz + dz
						if ix ~= 0 or iz ~= 0 then want[ix .. "," .. iz] = Vector2.new(ix, iz) end
					end
				end
			end
			local me = ctx.root()
			around(me and me.Position)
			around(workspace.CurrentCamera and workspace.CurrentCamera.Focus.Position)
			local free = {}
			for k, e in pairs(B.cells) do
				if not want[k] or not e.v.Parent or not e.c.Parent then
					B.cells[k] = nil
					if e.v.Parent and e.c.Parent then free[#free + 1] = e else pcall(e.v.Destroy, e.v); pcall(e.c.Destroy, e.c) end
				end
			end
			for k, c in pairs(want) do
				if not B.cells[k] then
					local e = table.remove(free) or make() -- move a tile that is no longer needed before making a new one
					local px, pz = x0 + (c.X + 0.5) * W, z0 + (c.Y + 0.5) * D
					e.v.CFrame = CFrame.new(px, top - DROP - THICK / 2, pz)
					e.c.CFrame = CFrame.new(px, top - DROP - 8, pz)
					B.cells[k] = e
				end
			end
			for _, e in ipairs(free) do e.v:Destroy(); e.c:Destroy() end
			local list = {}
			for _, e in pairs(B.cells) do list[#list + 1] = e.v; list[#list + 1] = e.c end
			state.baseParts = list -- ;cleanup and unload read it
		end
		sync()
		local acc = 0
		ctx.connect("baseplate", S.RunService.Heartbeat, function(dt)
			acc = acc + dt
			if acc < 0.25 then return end
			acc = 0
			sync()
		end)
		return true
	end
end
def({ "baseplate" }, "", "Endless smooth plastic baseplate in MIC UP / MIC UP 18+: very dark grey, 50% opacity, 10% reflectance, with the game's own texture; the game's baseplate stays as it is. Follows you and the camera", "map floor ground mic up glass infinite endless", function()
	if not (MICUP[game.PlaceId] or tostring(game.Name):lower():find("mic up", 1, true)) then
		return ctx.notify("baseplate only works in MIC UP and MIC UP 18+ (this is place " .. game.PlaceId .. ")", 5)
	end
	local ok, why = ctx.baseplate(true)
	ctx.notify(ok and "Baseplate extended: endless smooth plastic floor (only you can see and stand on it)" or why, 5)
end)

def({ "removebaseplate", "nobaseplate" }, "", "Remove the baseplate that ;baseplate added (the game's own was never touched)", "map floor ground delete void", function()
	if #(state.baseParts or {}) == 0 then return ctx.notify("No extended baseplate to remove") end
	ctx.baseplate(false)
	ctx.notify("Removed the extended baseplate")
end)

-- ===== PLAYER PROFILE =====
-- target resolution for ;player: user id or exact username, then exact display name(s), then the start of either, then anywhere in either. Returns the best tier; more than one = ambiguous
function ctx.matchPlayers(q, all)
	all = all or S.Players:GetPlayers()
	local ql, id, tiers = tostring(q):lower(), tonumber(q), { {}, {}, {}, {} }
	for _, p in ipairs(all) do
		local n, d = p.Name:lower(), p.DisplayName:lower()
		local t = ((id and p.UserId == id) or n == ql) and 1 or d == ql and 2 or (n:sub(1, #ql) == ql or d:sub(1, #ql) == ql) and 3 or (n:find(ql, 1, true) or d:find(ql, 1, true)) and 4 or nil
		if t then table.insert(tiers[t], p) end
	end
	for _, t in ipairs(tiers) do if #t > 0 then return t end end
	return {}
end
do -- ;selftest also checks the matching
	local st0 = ctx.selftest
	function ctx.selftest()
		local A, B, C = { Name = "Fread", DisplayName = "Bob", UserId = 11 }, { Name = "bobby", DisplayName = "Rob", UserId = 22 }, { Name = "xbobx", DisplayName = "Bob", UserId = 33 }
		local all = { A, B, C }
		assert(ctx.matchPlayers("fread", all)[1] == A and #ctx.matchPlayers("fread", all) == 1, "player: exact username")
		assert(#ctx.matchPlayers("bob", all) == 2, "player: a shared display name is ambiguous")
		assert(ctx.matchPlayers("bobb", all)[1] == B, "player: start of a name")
		assert(ctx.matchPlayers("22", all)[1] == B, "player: user id")
		assert(#ctx.matchPlayers("zzz", all) == 0, "player: no match")
		st0()
	end
end
def({ "player" }, "<player>", "Open the Players tab, or straight into a player's profile (username, display name or user id; the start is enough)", "profile card avatar outfit friends info players", function(q)
	if not q or q == "" or q:lower() == "all" or q:lower() == "others" then
		if ui.closeProfile then ui.closeProfile(true) end
		return ctx.openTab("Players")
	end
	local list = q:lower() == "me" and { lp } or ctx.matchPlayers(q)
	if #list == 1 then return ui.openProfile(list[1]) end
	if ui.closeProfile then ui.closeProfile(true) end
	ctx.openTab("Players")
	if #list == 0 then return ctx.notify("No player in this server matches '" .. q .. "'", 4) end
	if ui.plSearch then ui.plSearch(q) end
	local names = {}
	for i = 1, math.min(#list, 4) do names[i] = list[i].Name end
	ctx.notify(("%d players match '%s': %s%s. Pick one in the list"):format(#list, q, table.concat(names, ", "), #list > 4 and ", ..." or ""), 5)
end)

-- ===== TOOLS =====
-- source: a filled BUILTIN slot first, then the matching GITHUB link
local TOOLS = {
	liu = { title = "LiU", names = { "liu", "lighting", "lightingutility" }, builtin = "Lighting Utility", github = "LiU" },
	dex = { title = "Dex++", names = { "dex", "explorer", "dexpp" }, builtin = "Dex", github = "Dex++" },
	cobalt = { title = "Cobalt", names = { "cobalt", "cspy", "cobaltspy" }, builtin = "Cobalt", github = "Cobalt" },
	kelsec = { title = "Kelsec", names = { "kelsec", "executor", "exec" }, builtin = "Kelsec", github = "Kelsec" },
	workwell = { title = "WorkWell", names = { "workwell" }, builtin = "WorkWell", github = "WorkWell" },
	hlxp = { title = "KL HL XP", names = { "hlxp" }, builtin = "KL HL XP", github = "HLXP",
		onKill = function() if env.__HLXP_SHUTDOWN then pcall(env.__HLXP_SHUTDOWN) end end },
	rspy = { title = "RSpy", names = { "rspy", "simplespy", "remotespy" }, github = "RSpy" },
	alogger = { title = "ALogger", names = { "alogger", "audiologger" }, github = "ALogger" },
	tetris = { title = "Tetris", names = { "tetris" }, github = "Tetris" },
	wwapf = { title = "WWA Phantom Forces", names = { "workwellpf", "wwapf" }, github = "WWA Phantom Forces (Workwell)" },
	tooleditor = { title = "Tool Properties Editor", names = { "tooleditor", "properties", "toolproperties" }, github = "Tool Properties Editor" },
	klpfxp = { title = "KL PF XP", names = { "klpfxp", "pfxp" }, github = "KL PF XP" },
}
local TOOL_BY = {}
for key, t in pairs(TOOLS) do
	for _, n in ipairs(t.names) do TOOL_BY[n] = key end
end
local function toolSource(t)
	for _, b in ipairs(BUILTIN) do
		if b.name == t.builtin and (b.src:gsub("%-%-[^\n]*", "")):match("%S") then return b.src end
	end
	if t.github then
		for _, g in ipairs(GITHUB) do
			if g.name == t.github then
				local body, err = ctx.fetch(g.url)
				if body then return body end
				return nil, "download failed (" .. tostring(err) .. ")"
			end
		end
	end
	return nil, "no source yet. Paste it into the '" .. tostring(t.builtin) .. "' slot in KL_rOSAD.lua, or add a GITHUB link for it"
end
local function guiRoots()
	local t = {}
	pcall(function() t[#t + 1] = S.CoreGui end)
	pcall(function() t[#t + 1] = lp.PlayerGui end)
	if gethui then pcall(function() t[#t + 1] = gethui() end) end
	return t
end
local function snapshot()
	local s = {}
	for _, root in ipairs(guiRoots()) do
		for _, c in ipairs(root:GetChildren()) do s[c] = true end
	end
	return s
end
local function openTool(key)
	local t, st = TOOLS[key], state.tools[key]
	if st then
		local any = false
		for _, g in ipairs(st.guis) do
			if g.Parent then
				any = true
				pcall(function() if g:IsA("ScreenGui") then g.Enabled = true end end)
			end
		end
		if any then return ctx.notify(t.title .. " reopened") end
	end
	local src, err = toolSource(t)
	if not src then return ctx.notify(t.title .. ": " .. err, 5) end
	local before = snapshot()
	st = { guis = {}, conns = {} }
	state.tools[key] = st
	-- every new ScreenGui that appears in the next 25 seconds belongs to this tool (tools build theirs late), so ;kill can remove it
	-- shortcut: a window the game opens in those 25 seconds is also caught, when to upgrade: run the tool with a wrapped Instance.new
	local function track(c)
		if c.Name ~= "KLOSAD" and not before[c] and c:IsA("ScreenGui") then st.guis[#st.guis + 1] = c end
	end
	for _, root in ipairs(guiRoots()) do
		st.conns[#st.conns + 1] = root.ChildAdded:Connect(track)
	end
	ctx.runSource(src, t.title)
	task.delay(25, function()
		for _, cn in ipairs(st.conns) do cn:Disconnect() end
		st.conns = {}
	end)
end
-- a tool that was started some other way (executor, another script) is found by its window name
local function killByName(key)
	local words, n = { key, TOOLS[key].title:lower() }, 0
	for _, root in ipairs(guiRoots()) do
		for _, g in ipairs(root:GetChildren()) do
			local nm = g.Name:lower()
			if nm ~= "klosad" then
				for _, w in ipairs(words) do
					if nm:sub(1, #w) == w then pcall(function() g:Destroy() end); n = n + 1; break end -- start of the name only: "dex" was inside the game's "Index"
				end
			end
		end
	end
	return n > 0
end
-- true only if something was actually closed, so ;kill never says "closed" when nothing happened
local function killTool(key)
	local st = state.tools[key]
	if not st then return false end
	for _, cn in ipairs(st.conns or {}) do cn:Disconnect() end
	if TOOLS[key].onKill then TOOLS[key].onKill() end -- tools with their own shutdown get to disconnect their connections
	local n = 0
	for _, g in ipairs(st.guis) do
		if g.Parent then pcall(function() g:Destroy() end); n = n + 1 end
	end
	state.tools[key] = nil
	S.launched["tool:" .. key] = nil
	return n > 0 or TOOLS[key].onKill ~= nil
end
ctx.openTool = openTool
-- Load scripts rows use this, so a tool started from the panel is the same tool ;kill knows about
ctx.toolKey = { ["Dex++"] = "dex", Dex = "dex", Cobalt = "cobalt", Kelsec = "kelsec", WorkWell = "workwell",
	["Lighting Utility"] = "liu", LiU = "liu", HLXP = "hlxp", ["KL HL XP"] = "hlxp", RSpy = "rspy", ALogger = "alogger",
	Tetris = "tetris", ["WWA Phantom Forces (Workwell)"] = "wwapf", ["Tool Properties Editor"] = "tooleditor", ["KL PF XP"] = "klpfxp" }
ctx.killTools = function()
	for key in pairs(TOOLS) do
		local a = killTool(key)
		local b = killByName(key)
	end
end
def({ "hlxp" }, "", "Load KL HL XP (half-life movement and physics)", "movement physics half life", function() openTool("hlxp") end)
def({ "liu", "lighting", "lightingutility" }, "", "Open LiU (Lighting Utility)", "lighting camera blur shaders", function() openTool("liu") end)
def({ "dex", "explorer", "dexpp" }, "", "Open Dex++ Explorer (loads once, then reopens)", "explorer instances tree", function() openTool("dex") end)
def({ "cobalt", "cspy", "cobaltspy" }, "", "Open Cobalt remote spy", "remote spy", function() openTool("cobalt") end)
def({ "kelsec", "executor", "exec" }, "", "Open Kelsec, the in-game executor (loads once, then reopens)", "execute script run", function() openTool("kelsec") end)
def({ "rspy", "simplespy", "remotespy" }, "", "Open RSpy (SimpleSpy V3 remote spy)", "remote spy", function() openTool("rspy") end)
def({ "alogger", "audiologger" }, "", "Open ALogger (logs sounds as they play)", "audio sound log", function() openTool("alogger") end)
def({ "workwell" }, "", "Open WorkWell aim assist", "aim assist", function() openTool("workwell") end)
def({ "tetris" }, "", "Load Tetris (;untetris closes it)", "game play", function() openTool("tetris") end)
def({ "untetris" }, "", "Unload Tetris", "game close stop", function()
	local a = killTool("tetris")
	local b = killByName("tetris")
	ctx.notify((a or b) and "Tetris closed" or "Tetris isn't loaded")
end)
def({ "workwellpf", "wwapf" }, "", "Load WorkWell for Phantom Forces (;kill wwapf closes it)", "aim assist phantom forces pf", function() openTool("wwapf") end)
def({ "properties", "tooleditor" }, "", "Load the Tool Properties Editor (;kill tooleditor closes it)", "tool properties edit inventory", function() openTool("tooleditor") end)
def({ "klpfxp", "pfxp" }, "", "Load KL PF XP, Half-Life / GoldSrc movement in Phantom Forces (;kill klpfxp closes it)", "movement phantom forces pf half life", function() openTool("klpfxp") end)
def({ "kill" }, "<tool>", "Close a loaded tool: dex, kelsec, cobalt, rspy, alogger, workwell, liu, hlxp, tetris, wwapf, tooleditor, klpfxp, all", "close unload stop tool", function(q)
	if not q then return ctx.notify("Usage: kill <dex|kelsec|cobalt|rspy|alogger|workwell|liu|hlxp|tetris|wwapf|tooleditor|klpfxp|all>") end
	q = q:lower()
	if q == "all" then ctx.killTools(); return ctx.notify("Closed every loaded tool") end
	local key = TOOL_BY[q]
	if not key then return ctx.notify("Unknown tool: " .. q) end
	-- both ways, no "or": the tracked windows AND anything whose name matches
	local a = killTool(key)
	local b = killByName(key)
	ctx.notify((a or b) and (TOOLS[key].title .. " closed") or (TOOLS[key].title .. " isn't loaded"))
end)

def({ "saveinstance", "save" }, "[dec]", "Save the game without humanoids and players (dec = decompile scripts)", "save map download place", function(a)
	if not saveinstance then return ctx.notify("This executor has no saveinstance") end
	local dec = a and (a:lower() == "dec" or a:lower() == "decompile") or false
	local ignore = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then ignore[#ignore + 1] = p.Character end
	end
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("Humanoid") and v.Parent then ignore[#ignore + 1] = v.Parent end
	end
	ctx.notify("Saving...")
	task.spawn(function()
		local ok, e = pcall(saveinstance, { Decompile = dec, SavePlayers = false, IgnoreList = ignore, ExcludeNames = {}, mode = "optimized" })
		if not ok then ok, e = pcall(saveinstance) end
		ctx.notify(ok and "Saved to your executor's workspace folder" or ("Save failed: " .. tostring(e)))
	end)
end)
def({ "freezesave", "fsave", "freezesaveinstance" }, "[dec]", "Save the game with humanoids and players (Freeze Instance Saver)", "save map download place", function(a)
	env.KLOSAD_DECOMPILE = a and (a:lower() == "dec" or a:lower() == "decompile") or false
	for _, g in ipairs(GITHUB) do
		if g.name == "Freeze Instance Saver" then
			local body, err = ctx.fetch(g.url)
			if body then return ctx.runSource(body, g.name) end
			return ctx.notify(g.name .. ": download failed (" .. tostring(err) .. ")")
		end
	end
end)
def({ "ui", "openui" }, "", "Open the panel", "panel window", function() ui.setPanel(true) end)
def({ "exit" }, "", "Exit rOSAD and every tool it started", "quit close unload", function()
	ctx.killTools()
	if env.NameSpoof and env.NameSpoof.Destroy then pcall(env.NameSpoof.Destroy) end
	if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup) end
	ui.unload()
end)
def({ "cmds", "cmd", "commands" }, "", "Open the Commands tab", "help list", function() ctx.openTab("Commands") end)

-- ===== AUTO FEATURES =====
-- Persistence: the script can't read its own source, so it finds the file you saved in the workspace (cfg.selfPath) and keeps a copy in KLOSAD/.
-- The loader (queued for teleports, dropped in autoexec) runs that file first (patched versions are picked up on the next start), then the copy, then SELF_URL.
local function loaderLine()
	local paths = {}
	if cfg.selfPath ~= "" then paths[#paths + 1] = ("%q"):format(cfg.selfPath) end
	paths[#paths + 1] = ("%q"):format(DIR .. "/KL_rOSAD.lua")
	-- link first (the GitHub file is the newest), then the saved copies; a failure is shown as a notification, not only in the console
	return ('local g = (getgenv and getgenv()) or _G if g.KLOSAD_LD and os.time() - g.KLOSAD_LD < 30 then return end g.KLOSAD_LD = os.time() if not game:IsLoaded() then game.Loaded:Wait() end task.wait(1) local ok, e = pcall(function() if "%s" ~= "" then local okh, src = pcall(game.HttpGet, game, "%s") local fn = okh and type(src) == "string" and loadstring(src) if fn then fn() return end end for _, p in ipairs({%s}) do if isfile and isfile(p) then loadstring(readfile(p))() return end end error("no copy of KL_rOSAD.lua found (and the link did not load)") end) if not ok then warn("[KLOSAD autoexec] " .. tostring(e)) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "KL rOSAD autoexec", Text = tostring(e):sub(1, 180), Duration = 12 }) end) end'):format(SELF_URL, SELF_URL, table.concat(paths, ", "))
end
local function isSelf(body)
	return type(body) == "string" and body:find("KL rOSAD v", 1, true) and body:find("open-source admin/dev panel", 1, true) and body:find("local BUILTIN", 1, true) and true or false
end
-- refresh (manual ;keeposad): re-read the saved script and renew the KLOSAD copy. Otherwise any copy that exists is enough.
local function ensureCopy(refresh)
	local path = DIR .. "/KL_rOSAD.lua"
	if not (isfile and writefile and readfile and listfiles and isfolder) then return false end
	if not refresh and (isfile(path) or (cfg.selfPath ~= "" and isfile(cfg.selfPath))) then return true end
	local src, checked = nil, 0
	local function try(f)
		local ok, body = pcall(readfile, f)
		if ok and isSelf(body) then src = { f = f, body = body } end
		return src ~= nil
	end
	local function scan(dir, depth)
		local ok, files = pcall(listfiles, dir)
		if not ok then return end
		for _, f in ipairs(files) do
			if src then return end
			if isfolder(f) then
				if depth < 2 then scan(f, depth + 1) end
			else
				local ext = f:lower():match("%.(%w+)$")
				local norm = f:gsub("\\", "/")
				-- skip our own KLOSAD copy: selfPath must point at the file the user keeps
				if (ext == "lua" or ext == "luau" or ext == "txt") and norm:sub(-#path) ~= path and checked < 300 then
					checked = checked + 1
					try(f)
				end
			end
		end
	end
	if not (cfg.selfPath ~= "" and isfile(cfg.selfPath) and try(cfg.selfPath)) then
		scan("", 0)
		if not src then scan(".", 0) end
	end
	if not src then return isfile(path) end
	cfg.selfPath = src.f
	save()
	pcall(function()
		if makefolder and not isfolder(DIR) then makefolder(DIR) end
		writefile(path, src.body)
	end)
	return true
end
local AUTOPATHS = { "../autoexec/KLOSAD_autoload.lua", "autoexec/KLOSAD_autoload.lua", "../../autoexec/KLOSAD_autoload.lua",
	"../autoexecute/KLOSAD_autoload.lua", "autoexecute/KLOSAD_autoload.lua", "../Autoexecute/KLOSAD_autoload.lua", "../Autoexec/KLOSAD_autoload.lua" }
function ctx.setAutoExec(on, quiet)
	cfg.autoExec = on and true or false
	save()
	ctx.disconnect("autoTp")
	if on then
		local have = ensureCopy(not quiet) or SELF_URL ~= ""
		local line = loaderLine()
		local queued = queue_on_teleport and pcall(queue_on_teleport, line) -- covers server hops, rejoins and teleports
		-- queue_on_teleport only lasts for the next teleport and some executors drop it: queue again the moment a teleport starts
		if queue_on_teleport then
			ctx.connect("autoTp", lp.OnTeleport, function() pcall(queue_on_teleport, loaderLine()) end)
		end
		local placed = {} -- covers opening Roblox fresh: the executor's own autoexec folder. Most executors only let scripts write inside the workspace, so this can stay empty
		if writefile then
			pcall(function()
				if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
				writefile(DIR .. "/KLOSAD_autoload.lua", line)
			end)
			for _, p in ipairs(AUTOPATHS) do
				if pcall(writefile, p, line) and isfile and isfile(p) then placed[#placed + 1] = p end
			end
		end
		if quiet and have then return end
		if not have then
			ctx.notify("Can't find a copy of this script to load next time. Save it once in your executor's workspace folder (.lua or .txt, any name), then run ;keeposad again", 10)
		elseif #placed > 0 then
			ctx.notify("Auto execute on. Loader written to " .. placed[1] .. ", it runs on join, hops and rejoins", 7)
		elseif queued then
			ctx.notify("Auto execute on for hops and teleports. This executor can't write to its autoexec folder: copy " .. DIR .. "/KLOSAD_autoload.lua into it once so rOSAD also starts when you open Roblox", 10)
		else
			ctx.notify("This executor can't write to its autoexec folder and has no queue_on_teleport: copy " .. DIR .. "/KLOSAD_autoload.lua into the autoexec folder once", 10)
		end
	elseif not quiet then
		ctx.notify("Auto execute off")
		pcall(function()
			if delfile and isfile then
				for _, p in ipairs(AUTOPATHS) do
					if isfile(p) then delfile(p) end
				end
			end
		end)
	end
end
def({ "keeposad" }, "", "Run rOSAD automatically when you join a game or hop servers", "auto execute autoexec startup persist", function() ctx.setAutoExec(true) end)
def({ "unkeeposad" }, "", "Stop running rOSAD automatically", "auto execute autoexec startup", function() ctx.setAutoExec(false) end)

local avcTimer
function ctx.setAvc(on, quiet)
	cfg.avc = on and true or false
	save()
	ctx.disconnect("avc")
	if not on then
		avcTimer = nil
		if not quiet then ctx.notify("Auto rejoin on VC ban off") end
		return
	end
	local function banned()
		if avcTimer then return end
		avcTimer = os.clock()
		local my = avcTimer
		ctx.notify("Voice chat ban detected. Rejoining in 5 minutes", 6)
		task.delay(300, function()
			if avcTimer == my and cfg.avc and S.alive then avcTimer = nil; ctx.Run("rejoin") end
		end)
	end
	local how
	-- 1) the engine event (blocked on some executors, so it is only tried)
	pcall(function()
		local vc = game:GetService("VoiceChatInternal")
		ctx.connect("avc", vc.PlayerModerated, function(uid)
			if uid == lp.UserId then banned() end
		end)
		how = "event"
	end)
	-- 2) also watch CoreGui for Roblox's own "voice chat suspended" message (chat messages are ignored); runs next to the event because the event can connect and still never fire. banned() is guarded by avcTimer, so a double hit is harmless
	do
		pcall(function()
			local cg = game:GetService("CoreGui")
			local function look(o)
				if not (o:IsA("TextLabel") or o:IsA("TextButton")) or not o.Parent then return end
				if o:FindFirstAncestor("KLOSAD") or o:FindFirstAncestor("ExperienceChat") or o:FindFirstAncestor("Chat") then return end
				local t = o.Text:lower()
				if t:find("voice chat", 1, true) and (t:find("suspend", 1, true) or t:find("banned", 1, true)) then banned() end
			end
			ctx.connect("avc", cg.DescendantAdded, function(o) task.delay(0.3, look, o) end)
			how = how and (how .. " + UI watch") or "UI watch"
		end)
	end
	if not quiet then ctx.notify(how and ("Auto rejoin on VC ban on (" .. how .. ")") or "Couldn't hook VC ban detection in this executor", 5) end
end
def({ "arjvc", "avc", "arvc", "autorejoinvc" }, "[on|off]", "Toggle: rejoin 5 minutes after a voice chat ban (on / off sets it)", "voice vc ban rejoin auto", function(a)
	local on = not cfg.avc
	if a == "on" then on = true elseif a == "off" then on = false end
	ctx.setAvc(on)
end)
-- ===== AUTOSTART: scripts that start when rOSAD runs, and again after every respawn if their "after reset" switch is on =====
local function autoSource(it)
	if it.kind == "builtin" then
		for _, b in ipairs(BUILTIN) do
			if b.name == it.ref then return b.src end
		end
	elseif it.kind == "github" then
		for _, g in ipairs(GITHUB) do
			if g.name == it.ref then return ctx.fetch(g.url) end
		end
	elseif it.kind == "local" then
		local ok, body = pcall(readfile, it.ref)
		if ok then return body end
	elseif it.kind == "url" then
		return ctx.fetch(it.ref)
	end
	return nil, "script not found"
end
-- commands that take you out of the game never run from autostart (exec or respawn), whatever they are called (aliases resolve to the real name)
local LEAVES = { rejoin = true, serverhop = true, smallserver = true, region = true, leave = true }
function ctx.leaves(line)
	local l = tostring(line):lower():gsub("^%s*;?", ""):gsub("^loop%^", "") -- loop^rejoin, "all rejoin" and "sudo @alt rejoin" leave too
	local w, rest = l:match("^(%S+)%s*(.*)$")
	if w == "all" or w == "sudo" then return ctx.leaves((rest:gsub("^@%S+%s*", ""))) end
	return w ~= nil and LEAVES[ctx.Aliases[w] or w] == true
end
function ctx.autoRun(it)
	if it.kind == "cmd" and ctx.leaves(it.ref) then return ctx.notify("Autostart skipped '" .. it.ref .. "': leave / rejoin / hop commands never run on startup", 5) end
	if it.kind == "cmd" then return task.spawn(ctx.Run, it.ref) end -- a command line, e.g. "antiearrape"
	local key = ctx.toolKey[it.name]
	if key then return ctx.openTool(key) end -- known tools go through the same loader as ;dex etc., so a second run just reopens
	task.spawn(function()
		local src, err = autoSource(it)
		if src then ctx.runSource(src, it.name) else ctx.notify("Autostart " .. it.name .. ": " .. tostring(err or "failed"), 5) end
	end)
end
function ctx.runAutostart(reason)
	if not S.alive then return end -- the delayed start (2 s after exec, 1 s after respawn) of a run that was unloaded meanwhile
	for _, it in ipairs(cfg.autostart.items) do
		if reason == "exec" or it.respawn then ctx.autoRun(it) end
	end
end
def({ "autostart" }, "", "Launch (relaunch) everything in Autostart now, like on execute", "startup launch run exec relaunch autorun", function() ctx.runAutostart("exec") end)
ctx.connect("autoRespawn", lp.CharacterAdded, function()
	task.wait(1)
	ctx.runAutostart("respawn")
end)
if cfg.autoExec then task.defer(function() ctx.setAutoExec(true, true) end) end
if cfg.avc then task.defer(function() ctx.setAvc(true, true) end) end

-- ;cleanup [game|scripts]: frees what a client script can free. Roblox gives scripts no way to force the engine's own garbage collection, so this is best effort.
do
	local function mb() local ok, v = pcall(function() return S.Stats:GetTotalMemoryUsageMb() end); return ok and v or 0 end
	function ctx.cleanup(q)
		q = tostring(q or ""):lower()
		local all = q == "" or q == "all"
		local doS, doG = all or q == "scripts" or q == "script", all or q == "game"
		if not (doS or doG) then return ctx.notify("Usage: ;cleanup [game|scripts] (nothing = both)") end
		local m0, k0, out = mb(), collectgarbage("count"), {}
		if doS then
			local n = 0
			for _, fn in ipairs(table.clone(env.KLOSAD_ALL or {})) do if fn ~= ui.unload then pcall(fn); n = n + 1 end end -- stray rOSAD runs
			for _, get in ipairs({ function() return S.CoreGui end, function() return lp.PlayerGui end, function() return S.Lighting end }) do
				pcall(function()
					for _, o in ipairs(get():GetChildren()) do
						if (o.Name == "KLOSAD" and o ~= ui.gui) or (o.Name == "KLOSAD_Blur" and o ~= ui.blur) then o:Destroy(); n = n + 1 end
					end
				end)
			end
			for i = #(state.baseParts or {}), 1, -1 do if not state.baseParts[i].Parent then table.remove(state.baseParts, i) end end
			out[#out + 1] = n .. " stray run/gui removed"
			pcall(collectgarbage, "collect")
		end
		if doG then
			if cleardrawcache and pcall(cleardrawcache) then out[#out + 1] = "drawing cache cleared" end
		end
		task.wait(0.5)
		out[#out + 1] = ("Lua %.1f > %.1f MB, client %.0f > %.0f MB"):format(k0 / 1024, collectgarbage("count") / 1024, m0, mb())
		ctx.notify("Cleanup: " .. table.concat(out, ", "), 6)
	end
	def({ "cleanup", "clean" }, "[game|scripts]", "Free memory: stray rOSAD runs, Lua garbage, drawing cache (nothing = both)", "memory leak optimize clear gc fps lag", ctx.cleanup)
end

-- user notifier: a card (ui.alertUser) when a listed username is in the server, now or when they join; Preferences shows each user's status,
-- polled every cfg.nuPoll seconds in ONE batched request. Exact username, any case.
do
	local info, seen, last, csrf = {}, {}, 0, ""
	ctx.nuInfo = info
	local GREEN, GREY = Color3.fromRGB(60, 200, 90), Color3.fromRGB(150, 150, 150)
	local KIND = { [0] = { "Offline", GREY }, [1] = { "Online", Color3.fromRGB(80, 160, 255) }, [2] = { "In game", GREEN }, [3] = { "In Studio", Color3.fromRGB(255, 160, 50) }, [4] = { "Invisible", GREY } }
	local function inServer(n) for _, p in ipairs(S.Players:GetPlayers()) do if p.Name:lower() == n then return p end end end
	local function redraw() if S.panelOpen and ui.tab == "Preferences" and ui.refreshNu then ui.refreshNu() end end
	local function entry(n) local e = info[n]; if not e then e = { user = n }; info[n] = e end; return e end
	local function hdr(res, name) for k, v in pairs(res.Headers or {}) do if tostring(k):lower() == name then return v end end end
	-- the engine's own request carries your login (presence needs it); the executor's request is the fallback
	local function post(url, tbl)
		local body, res = S.HttpService:JSONEncode(tbl), nil
		for _ = 1, 2 do
			res = nil
			local ok, rq = pcall(function() return S.HttpService:RequestInternal({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json", ["x-csrf-token"] = csrf }, Body = body }) end)
			if not (ok and rq and pcall(function() rq:Start(function(_, r) res = r or false end) end)) then res = nil; break end
			local t = os.clock()
			while res == nil and os.clock() - t < 10 do task.wait(0.05) end
			if type(res) ~= "table" then res = nil; break end
			local tok = res.StatusCode == 403 and hdr(res, "x-csrf-token")
			if not tok then break end
			csrf = tok
		end
		if not (res and res.StatusCode == 200) and request then
			local ok, r = pcall(request, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
			if ok and type(r) == "table" and (r.StatusCode == 200 or not res) then res = r end
		end
		if res and res.StatusCode == 200 then
			local ok, v = pcall(S.HttpService.JSONDecode, S.HttpService, res.Body)
			return ok and v or nil, "bad reply"
		end
		return nil, res and ("HTTP " .. tostring(res.StatusCode)) or "no response"
	end
	local function check(p)
		if p == lp or seen[p.UserId] or not table.find(cfg.notifyUsers, p.Name:lower()) then return end
		seen[p.UserId] = true
		local e = entry(p.Name:lower())
		e.id, e.user, e.display = p.UserId, p.Name, p.DisplayName
		if ui.alertUser then ui.alertUser(p.UserId, p.Name, p.DisplayName) end
		redraw()
	end
	function ctx.nuScan() for _, p in ipairs(S.Players:GetPlayers()) do check(p) end end
	local function remove(n, msg)
		n = tostring(n or ""):lower():gsub("^@", "")
		if n == "all" then cfg.notifyUsers = {}; table.clear(info) else
			local i = table.find(cfg.notifyUsers, n)
			if not i then return ctx.notify("Not on the notify list: " .. n) end
			table.remove(cfg.notifyUsers, i); info[n] = nil
		end
		save(); redraw()
		ctx.notify(msg or "Notify list updated")
	end
	function ctx.nuRemove(n) remove(n) end
	function ctx.nuAdd(q)
		local added = {}
		for n in tostring(q or ""):gmatch("[^%s,@]+") do
			n = n:lower()
			if not table.find(cfg.notifyUsers, n) then table.insert(cfg.notifyUsers, n); added[#added + 1] = n end
		end
		if #added == 0 then return ctx.notify("Usage: ;notifyuser <username> (or already on the list)") end
		save(); ctx.nuScan(); redraw()
		last = -math.huge -- poll their status now
		ctx.notify("Will alert when in the server: " .. table.concat(added, ", "))
	end
	-- activity text + dot color for a listed name. Roblox has no "idle": Online covers it, Offline adds how long ago they were last seen
	function ctx.nuStatus(n)
		local e = info[n]
		if inServer(n) then return "In this server", GREEN end
		if not e or e.kind == nil then return e and e.why or "checking…", GREY end
		local k = KIND[e.kind] or KIND[0]
		local t = k[1]
		if e.kind == 2 and e.loc and e.loc ~= "" then t = t .. ": " .. e.loc
		elseif e.kind == 0 and e.last then
			local ok, ts = pcall(function() return DateTime.fromIsoDate(e.last).UnixTimestamp end)
			if ok and ts then
				local m = math.max(0, math.floor((os.time() - ts) / 60))
				t = ("%s · last seen %s"):format(t, m < 60 and m .. "m" or m < 2880 and math.floor(m / 60) .. "h" or math.floor(m / 1440) .. "d")
			end
		end
		return t, k[2]
	end
	function ctx.nuPoll()
		local byId, ids, need, bad = {}, {}, {}, {}
		for _, n in ipairs(cfg.notifyUsers) do
			local e, p = entry(n), inServer(n)
			if p then e.id, e.user, e.display = p.UserId, p.Name, p.DisplayName end
			if not e.id then
				local ok, id = pcall(S.Players.GetUserIdFromNameAsync, S.Players, n)
				if ok then e.id = id elseif tostring(id):lower():find("valid") then bad[#bad + 1] = n else e.why = "lookup failed" end
			end
			if e.id then
				byId[e.id] = e; ids[#ids + 1] = e.id
				if not e.display then need[#need + 1] = e.id end
			end
		end
		for _, n in ipairs(bad) do remove(n, "No Roblox user called " .. n) end
		if #need > 0 then
			for _, u in ipairs((post("https://users.roblox.com/v1/users", { userIds = need, excludeBannedUsers = false }) or {}).data or {}) do
				local e = byId[u.id]
				if e then e.user, e.display = u.name, u.displayName end
			end
		end
		if #ids > 0 then
			local r, why = post("https://presence.roblox.com/v1/presence/users", { userIds = ids })
			for _, u in ipairs(r and r.userPresences or {}) do
				local e = byId[u.userId]
				if e then e.kind, e.loc, e.last, e.why = u.userPresenceType, u.lastLocation, u.lastOnline, nil end
			end
			if not r then for _, e in pairs(byId) do e.why = "status unavailable (" .. tostring(why) .. ")" end end
		end
		redraw()
	end
	ctx.connect("nuAdd", S.Players.PlayerAdded, check)
	ctx.connect("nuLeft", S.Players.PlayerRemoving, function(p) seen[p.UserId] = nil end)
	task.delay(3, ctx.nuScan) -- after the gui exists
	task.spawn(function()
		task.wait(4)
		while S.alive do
			if #cfg.notifyUsers > 0 then last = os.clock(); pcall(ctx.nuPoll) end
			repeat task.wait(2) until not S.alive or os.clock() - last >= math.max(15, cfg.nuPoll)
		end
	end)
	def({ "notifyuser", "nuser" }, "<username> [more]", "Alert card whenever this username is in the server (list + status in Preferences)", "notify alert watch user player join friend", function(...) ctx.nuAdd(table.concat({ ... }, " ")) end)
	def({ "unnotifyuser", "unuser" }, "<username|all>", "Remove a username from the notify list", "notify alert watch remove", ctx.nuRemove)
end
end

-- extra command files from KLOSAD/commands (same format, override built-ins with the same name)
ctx.loadFolder(DIR .. "/commands")
-- aliases made with ;alias are saved in the settings; restored here, after every command (including the command files) exists
for a, canon in pairs(cfg.aliases) do
	if ctx.Commands[canon] then ctx.Aliases[a] = canon end
end
ctx.register(function()
	return { names = { "unalias" }, args = "<alias>", desc = "Remove an alias made with alias", tags = "shortcut remove delete", run = function(a)
		a = a and a:lower()
		if a and cfg.aliases[a] then
			cfg.aliases[a] = nil; ctx.Aliases[a] = nil; save()
			ctx.notify("Removed alias " .. a)
		else
			ctx.notify("No saved alias called " .. tostring(a))
		end
	end }
end)
-- [/CMD_EXTRA]

-- [UI_SHARED]
-- ===== UI: shared pieces ===================================================
-- Everything below is laid out in the reference deck's own 1080p pixels (panel 685x443, bar 647x51).
-- ui.rescale() zooms it to the real screen, so at 1080p / 100% it matches the reference 1:1.
-- fs(): pt -> px at 1080p, nudged 8% up because Source Sans runs a little smaller than Bahnschrift at the same size.
local function fs(pt) return math.floor(pt * 4 / 3 * 1.08 + 0.5) end
local FONT, FONT_B, FONT_CODE = Enum.Font.SourceSans, Enum.Font.SourceSansSemibold, Enum.Font.Code
local BTN_ON, BTN_OFF = 0.2, 0.25 -- fill transparency of a selected / normal button

local gui = new("ScreenGui", { Name = "KLOSAD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
pcall(function() gui.Parent = S.CoreGui end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
ui.gui = gui
ui.blur = new("BlurEffect", { Name = "KLOSAD_Blur", Size = 0 }, S.Lighting)

-- UI Opacity is relative: every fill in the panel (tiles, cards, buttons, fields, washes) has a raw transparency designed at 80 %, and is scaled by opacity / 0.8 (20 % -> x0.25, 50 % -> x0.625, 100 % -> x1.25). Scaled elements carry the attribute "raw"; ui.apply rescales them live
S.opK = math.clamp(tonumber(cfg.opacity) or 0.8, 0.2, 1) / 0.8
function S.opx(tr) return math.clamp(1 - (1 - tr) * S.opK, 0, 1) end
local ord = 0
local function nx() ord = ord + 1; return ord end

-- ===== STYLE SHEET: the one place that says how the UI looks. Widgets read from here, nothing invents its own number =====
-- rCtrl: buttons, option chips, text fields, cards, toasts, tooltips. rPane: windows, big tiles, popups. Smaller shapes (bars, dots, knobs) are clamped to a pill by the corner radius itself
local ST = {
	rCtrl = 8, rPane = 12,
	ctrlEdge = 0.7, cardEdge = 0.55, -- hairline transparency: a control is defined by its fill, its hairline is only a hint (cards keep a clearer edge)
	btnPt = 9, -- every button label (glyph buttons like the close x pass their own size)
	hoverTint = 0.4, -- how far a hairline drifts toward the accent on hover
	press = 0.97, -- press scale
	fill = { hover = 0.15, press = 0.3 }, -- how much denser a fill gets on hover / press
	-- inner glow = BackgroundTransparency (lower = stronger): plain control / selected control / card
	glow = { idle = 1, hover = 0.82, press = 0.65, onIdle = 0.55, onHover = 0.4, onPress = 0.3, cardHover = 0.88 },
	slider = { halo = 0.8, haloHeld = 0.6, aura = 0.82, auraHeld = 0.6, swell = 1.06, lift = 1.12 },
}
-- frame at design-pixel position; fillKey nil = no fill
local function fr(parent, x, y, w, h, fillKey, tr, r, strokeKey, st, str)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0,
		BackgroundTransparency = fillKey and tr or 1 }, parent)
	if fillKey then paint(f, "BackgroundColor3", fillKey) end
	if S.opScope and fillKey and fillKey ~= "accent" and w >= 14 and h >= 14 then f:SetAttribute("raw", tr); f.BackgroundTransparency = S.opx(tr) end
	if r then
		if S.opScope then r = r <= ST.rCtrl and ST.rCtrl or ST.rPane end -- inside the panel only two corner sizes exist (the command bar above is its own pill)
		new("UICorner", { CornerRadius = UDim.new(0, r) }, f)
	end

	if strokeKey then
		paint(new("UIStroke", { Thickness = st or 1, Transparency = (S.opScope and strokeKey == "edge") and ST.cardEdge or (str or 0), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f), "Color", strokeKey)
	end
	return f
end
-- soft wash for depth: black fading out from the top (bottom = false) or white fading in toward the bottom; tr = its strongest transparency
local function wash(parent, x, y, w, h, bottom, tr, r)
	local f = fr(parent, x, y, w, h, nil)
	f.BackgroundColor3, f.BackgroundTransparency = bottom and Color3.new(1, 1, 1) or Color3.new(0, 0, 0), S.opx(0)
	f:SetAttribute("raw", 0)
	if r then new("UICorner", { CornerRadius = UDim.new(0, r) }, f) end
	S.deco(f)
	new("UIGradient", { Rotation = 90, Transparency = bottom and NumberSequence.new(1, tr) or NumberSequence.new(tr, 1) }, f)
	return f
end
-- text box of the reference: zero insets, top aligned
local function txt(parent, str, pt, key, x, y, w, h, props)
	local o = new("TextLabel", mix({ BackgroundTransparency = 1, BorderSizePixel = 0, Text = str, TextSize = fs(pt), Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, props), parent)
	paint(o, "TextColor3", key)
	return o
end
-- button variants. key: nil / "btnFill" = secondary (quiet fill), "ctrlOff" / "ctrlOn" = toggle chip (ctrlOn = selected: accent tint + accent label),
-- "primary" = the one main action of a row or page (solid accent, bold contrasting label), "danger" = removes something or throws you out (red label, red tint on hover),
-- "ghost" = glyph / icon button (no fill until hover). Any other theme key = a secondary button with that fill. Disabled = b.Active false (st() dims it).
-- A button that already exists (S.btnSt) tweens to the new look through its st(); a new one is set directly
local VARIANT = {
	primary = { fill = "accent", text = "onAccent", tr = 0, bold = true },
	danger = { fill = "btnFill", text = "danger", tint = "danger", edge = true },
	ghost = { fill = "text", text = "text", tr = 1 },
	ctrlOn = { fill = "accent", text = "accentText", tr = 0.78, edge = true, on = true },
}
S.btnV = setmetatable({}, { __mode = "k" }) -- button -> its variant
local function setFill(b, key, tr)
	local v = VARIANT[key or "btnFill"] or { fill = key or "btnFill", text = "text", edge = true }
	local raw = v.tr or tr or BTN_OFF
	local f, stroke = S.btnSt[b], b:FindFirstChildOfClass("UIStroke")
	local old = b.BackgroundColor3
	S.btnV[b] = v
	paint(b, "BackgroundColor3", v.fill)
	paint(b, "TextColor3", v.text)
	b.Font = v.bold and FONT_B or FONT
	b:SetAttribute("raw", raw) -- UI Opacity rescales it live (ui.apply)
	b:SetAttribute("base", S.opx(raw))
	b:SetAttribute("on", v.on == true)
	if stroke then
		paint(stroke, "Color", v.on and "accent" or "edge")
		stroke.Enabled = v.edge == true
	end
	if f then
		b.BackgroundColor3 = old -- the change tweens in st() instead of popping
		f()
	else
		b.BackgroundTransparency = S.opx(raw)
		if stroke then stroke.Transparency = v.on and 0.35 or ST.ctrlEdge end
	end
end
-- reference button: 1px edge, 8px corners, text 9pt, label centred. Hover and press are animated.
-- click ripple in the accent color, grows from where the mouse is
local function ripple(b)
	local sx = b.Size.X.Offset
	if cfg.anim == 0 or sx <= 0 then return end
	pcall(function()
		local p = (S.UserInputService:GetMouseLocation() - b.AbsolutePosition) / (b.AbsoluteSize.X / sx)
		local d = sx * 1.7
		local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = S.accent, BackgroundTransparency = 0.7, BorderSizePixel = 0 }, b)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
		tw(c, { Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1 }, 0.3)
		task.delay(dur(0.3) + 0.05, function() c:Destroy() end)
	end)
end
-- ONE hover rule for the whole UI. Enter turns it on, and it stays on until the mouse is really outside the object's rectangle (checked every frame while hovered).
-- Roblox fires MouseLeave when a glow / sheen / child appears over the object, which made hover flicker off and never stay lit. fn(true) / fn(false)
function S.hover(o, fn)
	local on = false
	local function inside()
		local m, p, s = S.UserInputService:GetMouseLocation(), o.AbsolutePosition, o.AbsoluteSize
		return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
	end
	o.MouseEnter:Connect(function()
		if on then return end
		on = true
		fn(true)
		task.spawn(function()
			repeat S.RunService.Heartbeat:Wait() until not (S.alive and o.Parent and inside())
			on = false
			if S.alive and o.Parent then fn(false) end
		end)
	end)
end
-- THE control look: every button, option chip and strip tab. Six states (idle / hover / focus / press / selected / disabled) all go through st(),
-- so they share one curve, one set of durations and the same parts: fill, hairline (variants with an edge), press scale. Every number comes from ST
S.btnSt = setmetatable({}, { __mode = "kv" }) -- button -> its st(), so setFill can retarget a live button. Weak values too: st() holds its button, and Luau has no ephemerons, so weak keys alone kept every destroyed button
local function btn(parent, str, x, y, w, h, key, tr, cb, pt)
	local b = new("TextButton", { Text = str, TextSize = fs((pt and pt >= 12) and pt or ST.btnPt), Font = FONT, AutoButtonColor = false, BorderSizePixel = 0,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, b)
	local stroke = new("UIStroke", { Thickness = 1, Transparency = ST.ctrlEdge, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	paint(stroke, "Color", "edge")
	setFill(b, key, tr)
	local sc = new("UIScale", {}, b)
	local hot, down, wasLive = false, false, true
	local function st() -- the single place that decides how the button looks
		local v, live = S.btnV[b] or { fill = "btnFill", text = "text", edge = true }, b.Active -- never nil, even if the variant entry was lost
		local h2, d2 = hot and live, down and live
		local base = col(v.fill)
		local c = d2 and base:Lerp(Color3.new(0, 0, 0), 0.18) or h2 and base:Lerp(col(v.tint or "text"), v.tint and 0.25 or 0.08) or base
		tw(b, { BackgroundColor3 = c, BackgroundTransparency = math.max((b:GetAttribute("base") or 0) - (d2 and ST.fill.press or h2 and ST.fill.hover or 0), 0) }, 0.1)
		if live ~= wasLive then wasLive = live; b.TextTransparency = live and 0 or 0.55 end
		stroke.Enabled = v.edge == true
		if v.edge then tw(stroke, { Color = v.on and S.accent or h2 and col("edge"):Lerp(S.accent, ST.hoverTint) or col("edge"), Transparency = (v.on or h2) and 0.35 or ST.ctrlEdge }, 0.1) end
		tw(sc, { Scale = d2 and ST.press or 1 }, 0.1)
	end
	S.btnSt[b] = st
	S.hover(b, function(v) hot = v; if not v then down = false end; st() end)
	b.SelectionGained:Connect(function() hot = true; st() end) -- keyboard / gamepad focus looks like hover
	b.SelectionLost:Connect(function() hot = false; down = false; st() end)
	b:GetPropertyChangedSignal("Active"):Connect(st) -- disabling dims the label at once
	b.MouseButton1Down:Connect(function() down = true; st() end)
	b.MouseButton1Up:Connect(function() down = false; st() end)
	b.MouseButton1Click:Connect(function() if b.Active then cb(b) end end)
	return b
end
-- reference text field: 1px edge, 8px corners, 10px left inset. The styled Frame holds a plain TextBox, because
-- UIPadding / UIStroke on the TextBox itself shifts the caret. Returns the TextBox; its Frame is o.Parent.
local function input(parent, ph, x, y, w, h, pt, fillKey, tr, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0, BackgroundTransparency = S.opx(tr or BTN_OFF) }, parent)
	f:SetAttribute("raw", tr or BTN_OFF)
	paint(f, "BackgroundColor3", fillKey or "ctrlOff")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, f)
	local stroke = new("UIStroke", { Thickness = 1, Transparency = ST.ctrlEdge, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	paint(stroke, "Color", "edge")
	-- focus glow: accent rising from the bottom edge, same recipe as buttons (created before the TextBox so the text stays on top)
	local glow = new("Frame", { Name = "Glow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Interactable = false }, f)
	paint(glow, "BackgroundColor3", "accent")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, glow)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 0) }) }, glow)
	local o = new("TextBox", mix({ BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = ph, ClearTextOnFocus = false, Font = FONT,
		TextSize = fs(pt or 11), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0) }, props), f)
	paint(o, "TextColor3", "text"); paint(o, "PlaceholderColor3", "hint")
	-- the edge turns accent only while the mouse is over the box or it has focus
	local focused, hv = false, { f = false, o = false }
	local function edge()
		local hot = hv.f or hv.o
		tw(stroke, { Color = focused and S.accent or hot and col("edge"):Lerp(S.accent, ST.hoverTint) or col("edge"), Thickness = focused and 2 or 1, Transparency = (focused or hot) and 0 or ST.ctrlEdge }, 0.1)
		tw(glow, { BackgroundTransparency = focused and ST.glow.onIdle or hot and ST.glow.hover or ST.glow.idle }, 0.1)
	end
	o.Focused:Connect(function() focused = true; edge() end)
	o.FocusLost:Connect(function() focused = false; edge() end)
	for k, g in pairs({ f = f, o = o }) do
		S.hover(g, function(v) hv[k] = v; edge() end) -- the shared hover rule: stays on until the mouse is really outside
		-- (leaving is handled by S.hover)
	end
	return o
end
local function scroller(parent, x, y, w, h)
	local sc = new("ScrollingFrame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = col("dim"), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ElasticBehavior = Enum.ElasticBehavior.Never }, parent)
	paint(sc, "ScrollBarImageColor3", "accent")
	return sc
end
local function clear(container)
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiObject") then
			themed[c] = nil -- rebuilt lists let go of their rows in the theme registry (it is not weak, see paint)
			for _, d in ipairs(c:GetDescendants()) do themed[d] = nil end
			c:Destroy()
		end
	end
end
local function empty(parent, str)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, LayoutOrder = nx() }, parent)
	txt(f, str, 10, "sub", 17, 14, 480, 34, { TextWrapped = true })
end
local function thumb(kind, id, size) return ("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(kind, id, size, size) end
local function conn(signal, fn) S.cons[#S.cons + 1] = signal:Connect(fn) end

-- ONE slider look for every slider (notched settings sliders and the per player volume slider): 4 px track, accent fill with a soft glow, white knob with a shadow and an accent halo.
-- hover: halo fades in and the knob swells a little. held: knob lifts, halo and glow get stronger. P.place(f) moves everything, f = 0..1 along the track. Looks from ST.slider
function S.sliderParts(parent, x, y, w, pad)
	local TW, K = w - pad * 2, ST.slider
	local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 23) }, parent)
	local function deco(class, props, par) props.Interactable, props.BorderSizePixel = false, 0; return new(class, props, par) end -- decoration never takes the mouse from the slider
	local track = deco("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, pad, 0.5, 0), Size = UDim2.fromOffset(TW, 4), BackgroundTransparency = 0.55 }, hit)
	paint(track, "BackgroundColor3", "edge")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local fill = deco("Frame", { Size = UDim2.fromOffset(0, 4) }, track)
	paint(fill, "BackgroundColor3", "accent")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local aura = deco("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = K.aura }, fill)
	paint(aura, "BackgroundColor3", "accent")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, aura)
	local halo = deco("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, ZIndex = 2 }, hit)
	paint(halo, "BackgroundColor3", "accent")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, halo)
	local shadow = deco("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.82, ZIndex = 3 }, hit)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, shadow)
	local knob = deco("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4 }, hit)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	new("UIStroke", { Thickness = 0.5, Color = Color3.new(0, 0, 0), Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, knob)
	local ks = new("UIScale", {}, knob)
	local P = { hit = hit, track = track, TW = TW }
	local hot, held = false, false
	local function look()
		tw(halo, { BackgroundTransparency = held and K.haloHeld or hot and K.halo or 1 }, 0.1)
		tw(aura, { BackgroundTransparency = held and K.auraHeld or K.aura }, 0.1)
		tw(ks, { Scale = held and K.lift or hot and K.swell or 1 }, 0.1)
	end
	function P.held(on) held = on; look() end
	S.hover(hit, function(v) hot = v; look() end)
	function P.place(f, t) -- f 0..1 along the track; t = tween time (nil = follow the finger directly)
		local p, sz = UDim2.new(0, pad + f * TW, 0.5, 0), UDim2.fromOffset(f * TW, 4)
		if t then
			tw(knob, { Position = p }, t); tw(shadow, { Position = p }, t); tw(halo, { Position = p }, t); tw(fill, { Size = sz }, t)
		else
			knob.Position, shadow.Position, halo.Position, fill.Size = p, p, p, sz
		end
	end
	return P
end
-- hover glow for list cards (same recipe as buttons / fields): the hairline drifts toward the accent and a faint accent glow rises from the bottom edge
function S.lit(f)
	local st, cr = f:FindFirstChildOfClass("UIStroke"), f:FindFirstChildOfClass("UICorner")
	local glow = new("Frame", { Name = "Glow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0, Interactable = false }, f) -- under the card's own content
	paint(glow, "BackgroundColor3", "accent")
	if cr then new("UICorner", { CornerRadius = cr.CornerRadius }, glow) end
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0) }) }, glow)
	local rest
	S.hover(f, function(v)
		if v then local k = st and themed[st] and themed[st].Color; rest = st and (k and col(k) or st.Color) end -- the painted colour, not one caught mid tween
		tw(glow, { BackgroundTransparency = v and ST.glow.cardHover or ST.glow.idle }, 0.16)
		if st and rest then tw(st, { Color = v and rest:Lerp(S.accent, ST.hoverTint) or rest }, 0.16) end
	end)
end
-- notched slider (iOS style): the knob follows the finger / mouse freely, the value snaps to the nearest notch and the knob settles into it on release. opts = { { label, value }, ... } in track order. Look = S.sliderParts
function S.notch(parent, y, x, w, opts, key, after, tbl)
	local n, LW = #opts, 40
	local tw0 = w - LW - 8 -- hit area; the label sits to the right of it
	local UIS = S.UserInputService
	local P = S.sliderParts(parent, x, y, tw0, 10)
	local hit, track = P.hit, P.track
	for i = 1, n do -- notch dots
		local d = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((i - 1) / (n - 1), 0, 0.5, 0), Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0, BackgroundTransparency = 0.6, ZIndex = 2 }, track)
		paint(d, "BackgroundColor3", "text")
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
	end
	local lbl = txt(parent, "", 10, "accentText", x + tw0 + 8, y, LW, 23, { Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })
	local cur
	local function find()
		local v, best, bd = tbl[key], 1, math.huge
		if type(v) ~= "number" then return 1 end
		for i, o in ipairs(opts) do
			local d = math.abs(o[2] - v)
			if d < bd then best, bd = i, d end
		end
		return best
	end
	local function near(f) return math.clamp(math.floor(f * (n - 1) + 0.5) + 1, 1, n) end
	cur = find()
	lbl.Text = opts[cur][1]
	P.place((cur - 1) / (n - 1))
	local moveC, endC
	local gx, gw = 0, 1 -- track position / width frozen when the drag starts (a live UI Scaling change would move the track under the cursor)
	local function commit()
		local v = opts[cur][2]
		if tbl[key] ~= v then
			tbl[key] = v; save()
			if after then after(v) else ui.apply() end
		end
	end
	local function drag(px)
		local f = math.clamp((px - gx) / gw, 0, 1)
		local c = near(f)
		if c ~= cur then
			cur = c; lbl.Text = opts[c][1]
			if key ~= "scale" then commit() end -- live while held; UI Scaling waits for release (it would resize the slider under your cursor)
		end
		P.place(f)
	end
	local function finish()
		if moveC then moveC:Disconnect(); moveC = nil end
		if endC then endC:Disconnect(); endC = nil end
		P.held(false)
		P.place((cur - 1) / (n - 1), 0.16) -- settles into the notch
		commit()
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if moveC then return end
		gx, gw = track.AbsolutePosition.X, math.max(track.AbsoluteSize.X, 1)
		P.held(true) -- the knob lifts while held
		drag(i.Position.X)
		moveC = UIS.InputChanged:Connect(function(m)
			if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then drag(m.Position.X) end
		end)
		endC = UIS.InputEnded:Connect(function(e)
			if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then finish() end
		end)
	end)
	return hit
end
-- On / Off switch (track + knob, accent track when on): a setting you flip never looks like a button you press. tbl[key] is true / false; after(v) runs on change (else ui.apply)
S.swLook = setmetatable({}, { __mode = "kv" }) -- switch -> its look(); the click handler holds look, so a live switch stays listed
function S.syncSwitches() for _, f in pairs(S.swLook) do pcall(f) end end -- a command can change a setting behind the panel (;arvc, ;keeposad)
function S.switch(parent, x, y, tbl, key, after)
	local hit = new("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(42, 23) }, parent)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, hit)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(19, 19), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Interactable = false }, hit)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
	new("UIStroke", { Thickness = 0.5, Color = Color3.new(0, 0, 0), Transparency = 0.8 }, knob)
	local ks = new("UIScale", {}, knob)
	local function look(t)
		local on = tbl[key] == true
		local k, pos, tr = on and "accent" or "edge", UDim2.new(0, on and 21 or 2, 0.5, 0), on and 0 or 0.35
		if t then
			local c = hit.BackgroundColor3
			paint(hit, "BackgroundColor3", k)
			hit.BackgroundColor3 = c
			tw(hit, { BackgroundColor3 = col(k), BackgroundTransparency = tr }, 0.16)
			tw(knob, { Position = pos }, 0.16)
		else
			paint(hit, "BackgroundColor3", k)
			hit.BackgroundTransparency, knob.Position = tr, pos
		end
	end
	look()
	S.swLook[hit] = look
	S.hover(hit, function(v) tw(ks, { Scale = v and 1.08 or 1 }, 0.1) end)
	hit.MouseButton1Click:Connect(function()
		tbl[key] = not (tbl[key] == true); save()
		look(true)
		if after then after(tbl[key]) else ui.apply() end
	end)
	return hit
end
-- segmented control: one reference button per option, selected = lighter fill. Three or more numeric options become a notched slider instead, On / Off a switch. tbl defaults to cfg; after() runs on change.
local function seg(parent, y, xs, w, opts, key, after, tbl)
	tbl = tbl or cfg
	if #opts == 2 and opts[1][2] == true and opts[2][2] == false then return S.switch(parent, xs[2] + w - 42, y, tbl, key, after) end -- right aligned where the two buttons were
	local allNum = #opts >= 3
	for _, o in ipairs(opts) do if type(o[2]) ~= "number" then allNum = false end end
	if allNum then return S.notch(parent, y, xs[1], xs[#xs] + w - xs[1], opts, key, after, tbl) end
	local bs = {}
	local function refresh()
		for _, o in ipairs(bs) do
			local on = tbl[key] == o.v
			setFill(o.b, on and "ctrlOn" or "ctrlOff", on and BTN_ON or BTN_OFF)
		end
	end
	for i, o in ipairs(opts) do
		bs[i] = { v = o[2], b = btn(parent, o[1], xs[i], y, w, 23, "ctrlOff", BTN_OFF, function()
			tbl[key] = o[2]; save(); refresh()
			if after then after(o[2]) else ui.apply() end
		end) }
	end
	refresh()
end

-- toast: slides up and fades in
do
	local t = new("TextLabel", { Name = "Toast", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70),
		AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.1, BorderSizePixel = 0,
		Font = FONT, TextSize = fs(11), TextWrapped = true, Visible = false, ZIndex = 50, ClipsDescendants = true }, gui)
	paint(t, "BackgroundColor3", "bar"); paint(t, "TextColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, t)
	paint(new("UIStroke", { Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, t), "Color", "accent")
	-- time-left line along the bottom edge (the padding is 14 / 8, so it reaches out to the edges)
	local prog = new("Frame", { Position = UDim2.new(0, -14, 1, 6), Size = UDim2.new(1, 28, 0, 2), BorderSizePixel = 0, BackgroundTransparency = 0.2 }, t)
	paint(prog, "BackgroundColor3", "accent")
	new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, t)
	new("UISizeConstraint", { MaxSize = Vector2.new(520, 300) }, t)
	ui.toastScale = new("UIScale", {}, t)
	local id, lastMsg, COPIED = 0, "", "Copied to clipboard"
	t.Active = true -- click the toast to copy its text
	t.InputBegan:Connect(function(i)
		if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and t.Visible and lastMsg ~= "" and t.Text ~= COPIED and setclipboard then
			pcall(setclipboard, lastMsg)
			ui.toast(COPIED, 1.5)
		end
	end)
	function ui.toast(msg, secs)
		id = id + 1
		local my = id
		t.Text = msg
		if msg ~= COPIED then lastMsg = msg end
		t.Visible = true
		t.Position = UDim2.new(0.5, 0, 1, -50)
		t.BackgroundTransparency, t.TextTransparency = 1, 1
		tw(t, { Position = UDim2.new(0.5, 0, 1, -70), BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.2)
		prog.BackgroundTransparency, prog.Size = 0.2, UDim2.new(1, 28, 0, 2)
		if cfg.anim ~= 0 then
			S.TweenService:Create(prog, TweenInfo.new(secs or 3, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2), BackgroundTransparency = 0.2 }):Play() -- also cancels the previous toast's fade-out of the line
		end
		task.delay(secs or 3, function()
			if id == my then
				tw(t, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.2)
				tw(prog, { BackgroundTransparency = 1 }, 0.2)
				task.delay(dur(0.2) + 0.05, function() if id == my then t.Visible = false end end)
			end
		end)
	end
end

-- activation notices: a small stack in a screen corner (Module Cfg: actOn, actCorner). One line per command with its value, fades in and out
do
	local CORNER = { TL = { 0, 0 }, TR = { 1, 0 }, BL = { 0, 1 }, BR = { 1, 1 } }
	local holder = new("Frame", { Name = "ActFeed", BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 40 }, gui)
	local lay = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	ui.actScale = new("UIScale", {}, holder)
	local items, n = {}, 0
	function ui.actLayout()
		local c = CORNER[cfg.mod.actCorner] or CORNER.BL
		holder.AnchorPoint = Vector2.new(c[1], c[2])
		holder.Position = UDim2.new(c[1], c[1] == 0 and 16 or -16, c[2], c[2] == 0 and 16 or -16)
		lay.HorizontalAlignment = c[1] == 0 and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
		lay.VerticalAlignment = c[2] == 0 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
	end
	function ui.act(label, value)
		if not cfg.mod.actOn then return end
		local txt = (value and value ~= "") and ("<b>%s</b>  %s"):format(esc(label), esc(value)) or ("<b>%s</b>"):format(esc(label))
		local e = items[label]
		if not (e and e.l.Parent) then
			n = n + 1
			local top = (CORNER[cfg.mod.actCorner] or CORNER.BL)[2] == 0
			local l = new("TextLabel", { AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, TextTransparency = 1,
				BorderSizePixel = 0, Font = FONT, TextSize = fs(10), RichText = true, Text = txt, LayoutOrder = top and -n or n, ZIndex = 40 }, holder)
			paint(l, "BackgroundColor3", "bar"); paint(l, "TextColor3", "text")
			new("UICorner", { CornerRadius = UDim.new(0, 8) }, l)
			new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, l)
			local st = new("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, l)
			paint(st, "Color", "accent")
			e = { l = l, st = st, id = 0 }
			items[label] = e
		end
		e.l.Text = txt
		e.id = e.id + 1
		local my = e.id
		tw(e.l, { BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.12)
		tw(e.st, { Transparency = 0.4 }, 0.12)
		task.delay(2.5, function()
			if e.id ~= my or not e.l.Parent then return end
			tw(e.l, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.15)
			tw(e.st, { Transparency = 1 }, 0.15)
			task.delay(dur(0.15) + 0.05, function()
				if e.id ~= my then return end
				pcall(function() e.l:Destroy() end)
				if items[label] == e then items[label] = nil end
			end)
		end)
	end
	ui.actLayout()
end

-- user notifier card (;notifyuser): themed like the toast, avatar + display name + username + status, accent ring pulse, 2 pings, stays 20 s, click closes. Shown even with Notifications off
do
	local holder = new("Frame", { Name = "UserAlert", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), BackgroundTransparency = 1,
		Size = UDim2.fromOffset(380, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 60 }, gui)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	local sc, n = new("UIScale", {}, holder), 0
	function ui.alertUser(uid, name, display)
		n = n + 1
		sc.Scale = cfg.scale
		local b = new("CanvasGroup", { LayoutOrder = n, Size = UDim2.fromOffset(380, 92), BackgroundTransparency = 0.05, BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 60 }, holder)
		paint(b, "BackgroundColor3", "bar")
		new("UICorner", { CornerRadius = UDim.new(0, ST.rPane) }, b)
		local st = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		paint(st, "Color", "accent")
		local av = new("ImageLabel", { Position = UDim2.fromOffset(14, 16), Size = UDim2.fromOffset(60, 60), BorderSizePixel = 0, BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", uid, 150), ZIndex = 61 }, b)
		paint(av, "BackgroundColor3", "row")
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
		paint(new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, av), "Color", "accent")
		txt(b, "USER IN SERVER", 8, "accentText", 90, 8, 270, 14, { Font = FONT_B, ZIndex = 61 })
		txt(b, display, 14, "text", 90, 22, 276, 22, { Font = FONT_B, ZIndex = 61, TextTruncate = Enum.TextTruncate.AtEnd })
		txt(b, "@" .. name, 9, "sub", 90, 45, 276, 14, { ZIndex = 61, TextTruncate = Enum.TextTruncate.AtEnd })
		local dot = new("Frame", { Position = UDim2.fromOffset(91, 68), Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, BackgroundColor3 = Color3.fromRGB(60, 200, 90), ZIndex = 61 }, b)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		txt(b, "In this server", 9, "text2", 105, 64, 260, 16, { ZIndex = 61 })
		local prog = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3), BorderSizePixel = 0, ZIndex = 62 }, b)
		paint(prog, "BackgroundColor3", "accent")
		local tws = {}
		if cfg.anim ~= 0 then
			tws[1] = S.TweenService:Create(prog, TweenInfo.new(20, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) })
			tws[2] = S.TweenService:Create(st, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.7 })
			for _, t in ipairs(tws) do t:Play() end
		end
		tw(b, { GroupTransparency = 0 }, 0.2)
		local closed = false
		local function close()
			if closed then return end
			closed = true
			for _, t in ipairs(tws) do pcall(function() t:Cancel() end) end
			tw(b, { GroupTransparency = 1 }, 0.2)
			task.delay(dur(0.2) + 0.05, function() pcall(function() b:Destroy() end) end)
		end
		new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 70 }, b).MouseButton1Click:Connect(close)
		task.delay(20, close)
		task.spawn(function()
			local s = new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 2 }, gui)
			for _ = 1, 2 do pcall(s.Play, s); task.wait(0.5) end
			s:Destroy()
		end)
	end
end

-- startup popup: page 1 is always the same, page 2 is a random line. Each page stays 5 seconds (click to skip ahead).
do
	local p = new("TextButton", { Name = "Welcome", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.08), AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Font = FONT, TextSize = fs(12),
		RichText = true, TextWrapped = true, Text = "", Visible = false, ZIndex = 60 }, gui)
	paint(p, "BackgroundColor3", "bar"); paint(p, "TextColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rPane) }, p)
	local stroke = new("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
	paint(stroke, "Color", "accent")
	new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, p)
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 300) }, p)
	ui.popScale = new("UIScale", {}, p)
	local seq, skipped = 0, false
	p.MouseButton1Click:Connect(function() skipped = true end)
	function ui.welcome()
		seq = seq + 1
		local my = seq
		local pages = {
			("rOSAD loaded. Panel: %s. Command bar: %s. Lost? Type ;cmds."):format(keyStr(cfg.panelKey), keyStr(cfg.barKey)),
			WELCOME[math.random(#WELCOME)],
		}
		local function show(i)
			p.Text = esc(pages[i]) .. '   <font color="' .. hex(col("dim")) .. '">' .. i .. "/2</font>"
		end
		local function hold(sec)
			local t = 0
			skipped = false
			while t < sec and my == seq and S.alive and not skipped do
				task.wait(0.1)
				t = t + 0.1
			end
			return my == seq and S.alive
		end
		task.spawn(function()
			show(1)
			p.Visible = true
			p.BackgroundTransparency, p.TextTransparency = 1, 1
			tw(p, { BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.25); tw(stroke, { Transparency = 0 }, 0.25)
			if not hold(5) then return end
			show(2)
			if not hold(5) then return end
			tw(p, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.25); tw(stroke, { Transparency = 1 }, 0.25)
			task.wait(dur(0.25) + 0.05)
			if my == seq then p.Visible = false end
		end)
	end
end

-- FPS / ping overlay for ;showfps
do
	local hud = new("TextLabel", { Name = "Hud", BackgroundTransparency = 0.35, BorderSizePixel = 0, Font = FONT, TextSize = fs(10), Text = "",
		AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Visible = false }, gui)
	paint(hud, "BackgroundColor3", "bar"); paint(hud, "TextColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, hud)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }, hud)
	ui.hudScale = new("UIScale", {}, hud)
	function ui.layoutHud()
		local c = cfg.mod.fpsCorner
		local right, bottom = c:sub(2, 2) == "R", c:sub(1, 1) == "B"
		hud.AnchorPoint = Vector2.new(right and 1 or 0, bottom and 1 or 0)
		hud.Position = UDim2.new(right and 1 or 0, right and -12 or 12, bottom and 1 or 0, bottom and -12 or 12)
	end
	function ui.showHud(on)
		hud.Visible = on
		if not on then return ctx.disconnect("hud") end
		ui.layoutHud()
		local acc, frames = 0, 0
		ctx.connect("hud", S.RunService.Heartbeat, function(dt)
			acc, frames = acc + dt, frames + 1
			if acc >= 0.5 then
				local ok, ping = pcall(function() return S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
				hud.Text = ("%d FPS  |  %s ms"):format(math.floor(frames / acc + 0.5), ok and tostring(math.floor(ping)) or "-")
				acc, frames = 0, 0
			end
		end)
	end
end

-- ===== search: shared by the command bar and the Commands tab ============
-- one entry per command: canonical name first, then its aliases
function ui.entries()
	local by, out = {}, {}
	for alias, canon in pairs(ctx.Aliases) do
		local e = by[canon]
		if not e then
			local m = ctx.Meta[canon] or {}
			e = { canon = canon, names = { canon }, desc = m.desc or "", args = m.args or "", tags = m.tags or "", cat = ctx.catOf[canon] or "Other" }
			by[canon] = e
			out[#out + 1] = e
		end
		if alias ~= canon then e.names[#e.names + 1] = alias end
	end
	for _, e in ipairs(out) do
		table.sort(e.names, function(a, b)
			if a == b then return false end
			if a == e.canon then return true end
			if b == e.canon then return false end
			return a < b
		end)
	end
	table.sort(out, function(a, b) return a.canon < b.canon end)
	return out
end
-- matches names, aliases, descriptions and tags. Several words: every word has to match somewhere.
function ui.matches(q)
	local all = ui.entries()
	q = (q or ""):lower():match("^%s*(.-)%s*$")
	if q == "" then return all end
	local words = {}
	for w in q:gmatch("%S+") do words[#words + 1] = w end
	local hits = {}
	for _, e in ipairs(all) do
		local worst
		for _, w in ipairs(words) do
			local s = score(e, w)
			if not s then worst = nil; break end
			worst = math.max(worst or 0, s)
		end
		if worst then hits[#hits + 1] = { e = e, s = worst } end
	end
	table.sort(hits, function(a, b)
		if a.s ~= b.s then return a.s < b.s end
		return a.e.canon < b.e.canon
	end)
	local out = {}
	for _, h in ipairs(hits) do out[#out + 1] = h.e end
	return out
end

-- ===== mouse: always free while the panel or bar is open, handed back to the game afterwards ==============
function ui.syncMouse()
	local UIS = S.UserInputService
	local need = S.panelOpen or S.barOpen or S.profOpen
	if need and not S.mouseFree then
		S.mouseFree = true
		S.mouseSaved = { UIS.MouseBehavior, UIS.MouseIconEnabled }
		pcall(function()
			S.RunService:BindToRenderStep("KLOSAD_Mouse", Enum.RenderPriority.Last.Value + 10, function()
				-- while the right mouse button is held the game is turning the camera: leave it alone
				if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
				UIS.MouseBehavior = Enum.MouseBehavior.Default
				UIS.MouseIconEnabled = true
			end)
		end)
	elseif not need and S.mouseFree then
		S.mouseFree = false
		pcall(function() S.RunService:UnbindFromRenderStep("KLOSAD_Mouse") end)
		if S.mouseSaved then
			UIS.MouseBehavior = S.mouseSaved[1]
			UIS.MouseIconEnabled = S.mouseSaved[2]
		end
	end
end
-- ===== avatar value: what a player wears, priced through MarketplaceService (same method as the profile's Outfit tab) =====
-- One asset cache for the whole session (the same hat is looked up once), shared by the profile and Home. At most 3 lookups run at a time and every real call is followed by a short wait, so a full server stays under the throttle.
-- Counts worn accessories, shirt, pants, t-shirt and face. Limited / off sale items have no price in game: counted separately, not added. The server total only uses characters that are loaded; a player who streams in later is added then.
do
	 local AV = { asset = {}, failT = {}, pend = {}, user = {}, busy = {}, skip = {}, rapC = {}, rapF = {}, workers = 0 }
	 ctx.AV = AV
	 function AV.comma(n) local s = tostring(math.floor((tonumber(n) or 0) + 0.5)); return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
	 local function priceOf(info) -- price, or 0 + the reason it is not counted
		 local cd = info.CollectiblesItemDetails
		 if info.IsLimited or info.IsLimitedUnique or (type(cd) == "table" and cd.IsLimited) then return 0, "limited" end
		 local price = tonumber(info.PriceInRobux)
		 if info.IsForSale and price and price > 0 then return price end
		 if info.IsForSale then return 0 end
		 return 0, "off"
	 end
	 function AV.info(id) -- yields; nil = could not be looked up (retried after 30 s)
		 local c = AV.asset[id]
		 if c then return c end
		 if AV.failT[id] and os.clock() - AV.failT[id] < 30 then return nil end
		 if AV.pend[id] then -- another worker is already asking for this asset
			 local t = os.clock()
			 while AV.pend[id] and os.clock() - t < 15 do task.wait(0.05) end
			 return AV.asset[id]
		 end
		 AV.pend[id] = true
		 local ok, res = pcall(function() return S.MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
		 AV.pend[id] = nil
		 if ok and type(res) == "table" then AV.asset[id] = res; task.wait(0.15); return res end
		 AV.failT[id] = os.clock()
	 end
	 -- what a limited is worth: a new UGC limited reports its lowest resale price in the product info, a classic limited has a recent average price (RAP) on the economy API. Cached; a failed lookup is retried after 60 s
	 function AV.limitedPrice(id, info) -- yields; nil = unknown
		 if AV.rapC[id] then return AV.rapC[id] end
		 if AV.rapF[id] and os.clock() - AV.rapF[id] < 60 then return nil end
		 local cd = type(info) == "table" and info.CollectiblesItemDetails
		 local v = type(cd) == "table" and tonumber(cd.CollectibleLowestResalePrice) or nil
		 if not (v and v > 0) then
			 local body = ctx.fetch("https://economy.roblox.com/v1/assets/" .. id .. "/resale-data")
			 local ok, d = pcall(function() return S.HttpService:JSONDecode(body) end)
			 v = ok and type(d) == "table" and tonumber(d.recentAveragePrice) or nil
			 task.wait(0.25)
		 end
		 if v and v > 0 then AV.rapC[id] = v; return v end
		 AV.rapF[id] = os.clock()
	 end
	 local function wornIds(p, web) -- web = also ask Roblox when the character is not loaded (profile only, the server scan skips those)
		 local ids, seen = {}, {}
		 local function add(id) id = tonumber(id); if id and id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end end
		 local ok, desc = pcall(function()
			 local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			 if h then return h:GetAppliedDescription() end
			 if web then return S.Players:GetHumanoidDescriptionFromUserId(p.UserId) end
		 end)
		 if ok and desc then
			 pcall(function() for _, a in ipairs(desc:GetAccessories(true)) do add(a.AssetId) end end)
			 for _, k in ipairs({ "Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }) do pcall(function() add(desc[k]) end) end
		 end
		 return ids
	 end
	 function AV.fresh(uid) local r = AV.user[uid]; return r ~= nil and os.clock() - r.t < (r.miss > 0 and 30 or 300) end -- a value with failed lookups is retried after 30 s, a complete one lasts 5 min
	 function AV.value(p, web) -- yields; { total, priced, n, other, miss } or nil when the outfit is not available
		 local uid = p.UserId
		 if AV.fresh(uid) then return AV.user[uid] end
		 if AV.busy[uid] then
			 local t = os.clock()
			 while AV.busy[uid] and os.clock() - t < 30 do task.wait(0.1) end
			 return AV.user[uid]
		 end
		 AV.busy[uid] = true
		 local rec
		 pcall(function()
			 local ids = wornIds(p, web)
			 if #ids == 0 then return end
			 local r = { total = 0, priced = 0, n = #ids, other = 0, miss = 0, lim = 0 }
			 for _, id in ipairs(ids) do
				 local info = AV.info(id)
				 if not info then
					 r.miss = r.miss + 1
				 else
					 local price, why = priceOf(info)
					 local rap = (why == "limited") and AV.limitedPrice(id, info) or nil
					 if rap then r.total = r.total + rap; r.priced = r.priced + 1; r.lim = r.lim + 1
					 elseif why then r.other = r.other + 1
					 else r.total = r.total + price; r.priced = r.priced + 1 end
				 end
			 end
			 r.t = os.clock()
			 AV.user[uid] = r
			 rec = r
		 end)
		 AV.busy[uid] = nil
		 return rec
	 end
	 function AV.srvTotal() -- value of everyone in the server who has been counted: total, counted, players
		 local total, done, of = 0, 0, 0
		 for _, p in ipairs(S.Players:GetPlayers()) do
			 of = of + 1
			 local r = AV.user[p.UserId]
			 if r then done = done + 1; total = total + r.total end
		 end
		 return total, done, of
	 end
	 function AV.srvStep() -- Home calls this once a second while it is open: 3 workers take the players that have no fresh value yet
		 if AV.workers > 0 then return end
		 local q, now = {}, os.clock()
		 for _, p in ipairs(S.Players:GetPlayers()) do
			 local uid = p.UserId
			 if p.Character and not AV.fresh(uid) and not (AV.skip[uid] and now - AV.skip[uid] < 20) then q[#q + 1] = p end
		 end
		 for _ = 1, math.min(3, #q) do
			 AV.workers = AV.workers + 1
			 task.spawn(function()
				 while S.alive do
					 local p = table.remove(q)
					 if not p then break end
					 local ok, r = pcall(AV.value, p)
					 if not (ok and r) then AV.skip[p.UserId] = os.clock() end -- no outfit yet: not asked again for 20 s
				 end
				 AV.workers = AV.workers - 1
			 end)
		 end
	 end
end
-- [/UI_SHARED]

-- [UI_BAR]
-- ===== UI: command bar (slides 2-3: 647x51 pill at 318, list 593 wide right under it) ==============
do
	-- full screen CanvasGroup: fades the bar, list and popup as one (the list hangs outside the bar, so the bar itself can't be the group)
local barFade = new("CanvasGroup", { Name = "BarFade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 10 }, gui)
local bar = new("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(647, 51), BackgroundTransparency = 1 }, barFade)
	ui.barScale = new("UIScale", {}, bar)
	local pill = fr(bar, 0, 0, 647, 51, "bar", 0, 25, "accent", 2, 0.35)
	-- the same soft drifting circle glows as behind the panel (UI_PANEL): stacked circles at tiny alpha in a CanvasGroup that clips to the corners, each drifting to a random spot over 14 to 28 s.
	-- shortcut: the panel keeps its own copy of this recipe (bigger circles, 4 glows); merge both into one builder if the look ever changes. k = strength against the panel's (the list is fainter)
	S.glowFields = {}
	local function glowField(parent, w, h, radius, k)
		local clip = new("CanvasGroup", { Name = "Glows", Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0, Interactable = false }, parent)
		new("UICorner", { CornerRadius = UDim.new(0, radius) }, clip)
		local holds, tws, live, gen, N = {}, {}, false, 0, 12
		for _, g in ipairs({ { true, 0.62, 0.3 }, { true, 0.5, 0.22 }, { false, 0.4, 0.12 } }) do -- accent?, diameter / width, alpha in the middle
			local d = w * g[2]
			local hold = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(math.random(0, w), math.random(0, h)), Size = UDim2.fromOffset(d, d),
				BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = math.random(0, 12) / 100 }, clip)
			hold:SetAttribute("peak", g[3])
			holds[#holds + 1] = hold
			if not g[1] then S.deco(hold) end -- the white glow is dark mode only
			for i = 1, N do
				local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(d * i / N, d * i / N), BorderSizePixel = 0, BackgroundTransparency = 1 }, hold)
				if g[1] then paint(c, "BackgroundColor3", "accent") else c.BackgroundColor3 = Color3.new(1, 1, 1) end
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
			end
		end
		local F = {}
		function F.set(K) -- K = Look and feel > Glow Opacity / 80, called by ui.setGlow
			K = K * k
			clip.Visible = K > 0
			for _, hd in ipairs(holds) do
				local a = 1 - (1 - hd:GetAttribute("peak") * K) ^ (1 / N)
				for _, c in ipairs(hd:GetChildren()) do c.BackgroundTransparency = 1 - a end
			end
		end
		local function go(hd, my)
			if not live or my ~= gen or not S.alive then return end
			local secs = math.random(140, 280) / 10
			local t = S.TweenService:Create(hd, TweenInfo.new(secs, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.fromOffset(math.random(0, math.floor(clip.Size.X.Offset)), math.random(0, math.floor(clip.Size.Y.Offset))) })
			local ta = S.TweenService:Create(hd, TweenInfo.new(secs * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { GroupTransparency = math.random(0, 12) / 100 })
			tws[hd] = { t, ta }
			t.Completed:Connect(function() go(hd, my) end)
			t:Play(); ta:Play()
		end
		function F.play() if live or cfg.anim == 0 then return end live, gen = true, gen + 1 for _, hd in ipairs(holds) do go(hd, gen) end end -- only while the bar is open
		function F.stop() live, gen = false, gen + 1 for _, p in pairs(tws) do for _, t in ipairs(p) do t:Cancel() end end tws = {} end
		F.clip = clip
		F.set(math.clamp((tonumber(cfg.glow) or 80) / 80, 0, 1.25))
		S.glowFields[#S.glowFields + 1] = F
		return F
	end
	glowField(pill, 647, 51, 25, 1) -- under the text: the labels below are created after this
	pill.Active = true -- a click on the bar never reaches the game
	-- cursor light: a small, faint white circle that follows the mouse over a surface (like Windows 10's reveal highlight). Dark mode only. ENTRY moves it every frame (S.spots)
	S.spots = {}
	function S.spot(parent, w, h, radius, z, area, live)
		local clip = new("CanvasGroup", { Name = "Spot", Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0, Interactable = false, ZIndex = z }, parent)
		new("UICorner", { CornerRadius = UDim.new(0, radius) }, clip)
		S.deco(clip)
		local D, N = 120, 10
		local hold = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(D, D), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Interactable = false }, clip)
		local a = 1 - (1 - 0.1) ^ (1 / N) -- 10 % white in the middle, fading to nothing
		for i = 1, N do
			local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(D * i / N, D * i / N), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 - a, Interactable = false }, hold)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
		end
		S.spots[#S.spots + 1] = { area = area, live = live, hold = hold }
		return clip
	end
	S.spot(pill, 647, 51, 25, 2, pill, function() return S.barOpen end)

	-- typed text and the completion are separate labels so no glyph is drawn twice
	local base = { BackgroundTransparency = 1, Position = UDim2.fromOffset(19, 0), Size = UDim2.fromOffset(610, 51),
		Font = FONT, TextSize = fs(16), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }
	local ghost = new("TextLabel", mix(base, { Text = "" }), bar)
	paint(ghost, "TextColor3", "dim")
	local box = new("TextBox", mix(base, { ClearTextOnFocus = false, Text = "", PlaceholderText = "" }), bar)
	paint(box, "TextColor3", "text"); paint(box, "PlaceholderColor3", "hint")
	ui.box = box

	local listF = new("Frame", { Name = "List", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 51), Size = UDim2.fromOffset(593, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, Active = true }, bar)
	paint(listF, "BackgroundColor3", "bar")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, listF)
	paint(new("UIStroke", { Thickness = 2, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, listF), "Color", "accent")
	new("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, listF)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, listF)
	-- the list's glows: a zero size first item of the layout (so it takes no room and is drawn under every row) holds the field, which is sized to the whole list; 60 % of the bar's strength
	do
		local holder = new("Frame", { Name = "GlowHolder", LayoutOrder = 0, Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Interactable = false }, listF)
		local clip = glowField(holder, 593, 8, ST.rCtrl, 0.6).clip
		local sclip = S.spot(holder, 593, 8, ST.rCtrl, 2, listF, function() return S.barOpen and listF.Visible end)
		clip.Position, sclip.Position = UDim2.fromOffset(-15, -8), UDim2.fromOffset(-15, -8)
		local function size() clip.Size = UDim2.fromOffset(listF.AbsoluteSize.X / ui.barScale.Scale, listF.AbsoluteSize.Y / ui.barScale.Scale); sclip.Size = clip.Size end
		listF:GetPropertyChangedSignal("AbsoluteSize"):Connect(size)
		size()
	end
	local rows = {}
	for i = 1, 20 do
		local r = new("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, BackgroundTransparency = 1,
			Font = FONT, TextSize = fs(14), RichText = true, TextWrapped = true, Text = "", Visible = false, LayoutOrder = i,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, listF)
		paint(r, "TextColor3", "text"); paint(r, "BackgroundColor3", "text")
		rows[i] = r
	end

	-- suggestions for an empty bar: 4 recent commands, a line, 4 commands from the full list.
	-- Scrolling over one of them hides the other and shows that one in full.
	local ROW = 24
	local function section(order)
		local sf = new("ScrollingFrame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, ScrollBarImageColor3 = col("dim"), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
			ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false }, listF)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, sf)
		return sf
	end
	local recentF, allF = section(101), section(103)
	local divF = new("Frame", { LayoutOrder = 102, Size = UDim2.new(1, 0, 0, 9), BackgroundTransparency = 1, Visible = false }, listF)
	local divLine = new("Frame", { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, BackgroundTransparency = 0.5 }, divF)
	paint(divLine, "BackgroundColor3", "dim")
	local hover -- which section the mouse is over
	for name, sf in pairs({ recent = recentF, all = allF }) do
		sf.MouseEnter:Connect(function() hover = name end)
		sf.MouseLeave:Connect(function() if hover == name then hover = nil end end)
	end

	-- full line popup for a highlighted suggestion that the row width cuts off
local tip = new("TextLabel", { Name = "Tip", Visible = false, ZIndex = 20, Size = UDim2.fromOffset(360, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 0.05, BorderSizePixel = 0, Font = FONT, TextSize = fs(13), RichText = true, TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, bar)
paint(tip, "BackgroundColor3", "bar"); paint(tip, "TextColor3", "text")
new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, tip)
paint(new("UIStroke", { Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, tip), "Color", "accent")
new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, tip)
local tipId = 0
local function hideTip() tipId = tipId + 1; tip.Visible = false end
local function showTip(it)
	hideTip()
	if not it or not it.lbl then return end
	local id = tipId
	local plain = it.rich:gsub("<[^>]+>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
	local ok, sz = pcall(function() return S.TextService:GetTextSize(plain, fs(14), FONT, Vector2.new(10000, ROW)) end)
	if not ok then return end
	task.spawn(function()
		S.RunService.RenderStepped:Wait(); S.RunService.RenderStepped:Wait() -- AbsoluteSize/Position are only valid after layout
		if id ~= tipId or not it.lbl.Parent then return end
		local s = ui.barScale.Scale
		if sz.X <= it.lbl.AbsoluteSize.X / s - 4 then return end -- fits, no popup
		local rel, bottom, w = (it.lbl.AbsolutePosition - bar.AbsolutePosition) / s, cfg.pos == "Bottom", listF.Size.X.Offset
		tip.AnchorPoint = Vector2.new(0, bottom and 1 or 0)
		tip.Position = UDim2.fromOffset(math.clamp(rel.X, 647 / 2 - w / 2, 647 / 2 + w / 2 - 360), bottom and rel.Y - 2 or rel.Y + ROW + 2)
		tip.Text = it.rich
		tip.Visible = true
	end)
end
conn(S.UserInputService.InputChanged, function(i)
	if i.UserInputType == Enum.UserInputType.MouseWheel then hideTip() end -- rows move under a scroll
end)

-- position as screen fractions: UIScale can't skew those. Center = the reference's y of 318/1080.
	function ui.layoutBar()
		local p = cfg.pos
		bar.Position = UDim2.fromScale(0.5, p == "Top" and 0.06 or p == "Bottom" and 0.86 or 318 / 1080)
		listF.AnchorPoint = Vector2.new(0.5, p == "Bottom" and 1 or 0)
		listF.Position = p == "Bottom" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0.5, 0, 0, 53) -- 53 = 51 + 2px nudge
	end

	-- "name / alias <args> - description": names white with the match in accent, the rest in the reference's dim grey
	local function rowText(e, q)
		local names = {}
		for _, n in ipairs(e.names) do names[#names + 1] = hl(n, q) end
		local dim = '<font color="' .. hex(col("dim")) .. '">'
		local s = table.concat(names, " / ")
		if e.args ~= "" then s = s .. " " .. dim .. esc(e.args) .. "</font>" end
		if e.desc ~= "" then s = s .. " " .. dim .. "- " .. esc(e.desc) .. "</font>" end
		return s
	end

	local function hideSug()
		recentF.Visible, allF.Visible, divF.Visible = false, false, false
		hideTip()
	end
	local function sugHighlight(still) -- still = hover: no scrolling, so rows don't slide under the mouse
		for i, it in ipairs(S.sugItems or {}) do
			local on = i == S.sugSel
			paint(it.lbl, "BackgroundColor3", on and "accent" or "text")
			it.lbl.BackgroundTransparency = on and 0.85 or 1
			if on and not still then -- keep the selected row inside its scroll window
				local sf, y = it.sf or it.lbl.Parent, it.rowY or (it.lbl.LayoutOrder - 1) * ROW
				local view = sf.Size.Y.Offset
				if y < sf.CanvasPosition.Y then sf.CanvasPosition = Vector2.new(0, y)
				elseif y + ROW > sf.CanvasPosition.Y + view then sf.CanvasPosition = Vector2.new(0, y + ROW - view) end
			end
		end
		showTip((S.sugItems or {})[S.sugSel])
	end
	-- cols > 1 spreads the rows over side by side columns (filled top to bottom, a new column starts at a section header when possible)
	local function addRows(sf, items, cols)
		for _, c in ipairs(sf:GetChildren()) do
			if c:IsA("GuiButton") or c:IsA("GuiLabel") or c.Name == "Cols" then c:Destroy() end
		end
		cols = cols or 1
		local hosts = {}
		if cols > 1 then
			local wrap = new("Frame", { Name = "Cols", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, sf)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
			for c = 1, cols do
				local f = new("Frame", { Size = UDim2.new(1 / cols, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = c }, wrap)
				new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, f)
				hosts[c] = f
			end
		else
			hosts[1] = sf
		end
		local per = math.ceil(#items / cols)
		local col, nrow = 1, 0
		for _, it in ipairs(items) do
			if col < cols and nrow >= per and (it.header or nrow >= per + 6) then col, nrow = col + 1, 0 end
			nrow = nrow + 1
			if it.header then
				local h = new("TextLabel", { Size = UDim2.new(1, -6, 0, ROW), LayoutOrder = nrow, BackgroundTransparency = 1, BorderSizePixel = 0,
					Font = FONT_B, TextSize = fs(12), RichText = true, Text = it.rich, TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom }, hosts[col])
				paint(h, "TextColor3", "accentText")
			else
				local b = new("TextButton", { Size = UDim2.new(1, -6, 0, ROW), LayoutOrder = nrow, BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
					Font = FONT, TextSize = fs(14), RichText = true, Text = it.rich, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, hosts[col])
				paint(b, "TextColor3", "text"); paint(b, "BackgroundColor3", "text")
				it.lbl, it.sf, it.rowY, it.col, it.row = b, sf, (nrow - 1) * ROW, col, nrow
				b.MouseButton1Click:Connect(function() ui.pickSug(it) end)
				b.MouseEnter:Connect(function()
					for i, o in ipairs(S.sugItems or {}) do
						if o == it then
							if S.sugSel ~= i then S.sugSel = i; sugHighlight(true) end
							break
						end
					end
				end)
			end
		end
	end
	function ui.sugRender()
		local mode = S.sugMode or "both"
		local recent, full = {}, {}
		for _, line in ipairs(cfg.hist) do recent[#recent + 1] = { text = line, rich = esc(line) } end
		for _, e in ipairs(ui.entries()) do full[#full + 1] = { text = e.canon, rich = rowText(e, "") } end
		local function cut(t, n)
			local o = {}
			for i = 1, math.min(#t, n) do o[i] = t[i] end
			return o
		end
		local cols, grouped = 1, nil
		if mode == "all" then
			-- sections (ctx.CAT_ORDER), each one alphabetical; a header row is not selectable
			local by = {}
			for _, e in ipairs(ui.entries()) do
				by[e.cat] = by[e.cat] or {}
				by[e.cat][#by[e.cat] + 1] = { text = e.canon, rich = rowText(e, "") }
			end
			grouped = {}
			for _, c in ipairs(ctx.CAT_ORDER) do
				if by[c] then
					grouped[#grouped + 1] = { header = true, rich = esc(c) .. ' <font color="' .. hex(col("dim")) .. '">' .. #by[c] .. "</font>" }
					for _, it in ipairs(by[c]) do grouped[#grouped + 1] = it end
				end
			end
			if cfg.sugCols then -- as many 400px columns as the screen holds, up to 3
				local vp = workspace.CurrentCamera.ViewportSize.X / ui.curScale()
				cols = math.clamp(math.floor((vp - 80) / 400), 1, 3)
			end
		end
		local rItems = mode == "all" and {} or (mode == "recent" and recent or cut(recent, 4))
		local aItems = mode == "recent" and {} or (mode == "all" and grouped or cut(full, 4))
		if mode ~= "all" and #rItems == 0 then
			rItems = { { text = "", empty = true, rich = '<font color="' .. hex(col("dim")) .. '">No recent commands yet</font>' } }
		end
		local function height(items, expanded, c)
			if not expanded then return math.min(#items, 4) * ROW end
			local fit = c > 1 and math.floor(workspace.CurrentCamera.ViewportSize.Y / ui.curScale() * 0.55 / ROW) or 0
			return math.min(math.ceil(#items / c), math.max(cfg.lines, 4, fit)) * ROW
		end
		listF.Size = UDim2.fromOffset(cols > 1 and cols * 400 + 30 or 593, 0)
		recentF.Size = UDim2.new(1, 0, 0, height(rItems, mode == "recent", 1))
		allF.Size = UDim2.new(1, 0, 0, height(aItems, mode == "all", cols))
		recentF.Visible, allF.Visible, divF.Visible = mode ~= "all", mode ~= "recent", mode == "both"
		addRows(recentF, rItems, 1); addRows(allF, aItems, cols)
		S.sugItems = {}
		for _, it in ipairs(rItems) do
			if not it.empty then S.sugItems[#S.sugItems + 1] = it end
		end
		for _, it in ipairs(aItems) do
			if not it.header then S.sugItems[#S.sugItems + 1] = it end
		end
		S.sugSel = math.min(S.sugSel or 1, math.max(#S.sugItems, 1))
		listF.Visible = true
		sugHighlight()
	end
	function ui.pickSug(it)
		if it.empty or not S.barOpen then return end -- rows stay clickable while the bar fades out
		box.Text = it.text
		box:CaptureFocus()
		box.CursorPosition = #box.Text + 1
	end
	conn(S.UserInputService.InputChanged, function(i)
		if i.UserInputType == Enum.UserInputType.MouseWheel and S.barOpen and S.sugOn and (S.sugMode or "both") == "both" and hover then
			S.sugMode, S.sugSel = hover, 1
			ui.sugRender()
		end
	end)
	function ui.pushHistory(line)
		line = (line:gsub("^%s*;", "")):match("^%s*(.-)%s*$")
		if line == "" then return end
		for i = #cfg.hist, 1, -1 do
			if cfg.hist[i] == line then table.remove(cfg.hist, i) end
		end
		table.insert(cfg.hist, 1, line)
		while #cfg.hist > 30 do table.remove(cfg.hist) end
		save()
	end

	function ui.render()
		if not S.sugOn then listF.Size = UDim2.fromOffset(593, 0) end -- the wide multi column list is only for browsing
		local n = math.min(#S.cur, cfg.lines)
		for i = 1, 20 do
			local r, e = rows[i], S.cur[i]
			if i <= n and e then
				r.Visible = true
				r.Text = rowText(e, S.q or "")
				paint(r, "BackgroundColor3", i == S.sel and "accent" or "text")
				r.BackgroundTransparency = (i == S.sel) and 0.85 or 1
			else
				r.Visible = false
			end
		end
		listF.Visible = n > 0 or S.sugOn == true
		if (S.ghost or "") ~= "" and S.ghostX then
			ghost.Text = S.ghost
			ghost.Position = UDim2.fromOffset(19 + S.ghostX, 0)
		else
			ghost.Text = ""
		end
	end

	-- argument suggestions for a command whose Meta has a complete(i, partial, prev) function (;report): fills S.cur with the matching choices for the argument being typed
	function ui.argSuggest(meta, q, rest)
		local toks = {}
		for w in rest:gmatch("%S+") do toks[#toks + 1] = w end
		local partial = ""
		if not rest:match("%s$") then partial = table.remove(toks) or "" end
		local lq, list = partial:lower(), {}
		local base = (S.pre or "") .. q .. " " .. table.concat(toks, " ") .. (#toks > 0 and " " or "")
		for _, it in ipairs(meta.complete(#toks + 1, lq, toks) or {}) do
			local t = it.text
			if lq == "" or t:lower():find(lq, 1, true) then
				list[#list + 1] = { names = { t }, args = "", desc = it.desc or "", canon = t, fill = base .. (t:find("%s") and ('"' .. t .. '"') or t) .. " ", pre = t:lower():sub(1, #lq) == lq }
			end
		end
		table.sort(list, function(x, z)
			if x.pre ~= z.pre then return x.pre end
			return x.names[1]:lower() < z.names[1]:lower()
		end)
		for i = 1, math.min(#list, 10) do S.cur[#S.cur + 1] = list[i] end
		if #S.cur > 1 then S.sel, S.q = 2, partial end
	end

	function ui.search()
		local line = box.Text:gsub("^%s*;", "")
		local q, rest = line:match("^%s*(%S*)(.*)$")
		q = (q or ""):lower()
		S.pre, S.tail = "", rest
		do -- ;sudo / ;all: suggest for the command typed after them ("sudo fly 5", "sudo @alt goto Bob"), the part before it is kept when you pick one
			local c0 = ctx.Aliases[q]
			if rest ~= "" and (c0 == "sudo" or c0 == "all") then
				local after = rest:gsub("^%s+", "")
				local alt = after:match("^@%S*")
				local ok = true
				if alt then
					local tail = after:sub(#alt + 1)
					if tail:match("^%s") then after = tail:gsub("^%s+", "") else ok = false end -- still typing the @name
				end
				if ok then -- also when nothing is typed after "sudo " / "sudo @alt " yet: the whole command list shows, as on an empty bar
					S.pre = line:sub(1, #line - #after)
					line = after
					q, rest = line:match("^%s*(%S*)(.*)$")
					q = (q or ""):lower()
					S.tail = rest
				end
			end
		end
		S.q, S.sel, S.cur, S.ghost, S.ghostX, S.sugOn = q, 1, {}, "", nil, false
		if rest ~= "" and ctx.Aliases[q] then
			-- typing arguments: show just that command's usage
			for _, e in ipairs(ui.entries()) do
				if e.canon == ctx.Aliases[q] then S.cur = { e } end
			end
			-- a command that takes a <player>: suggest the server's players while the first argument is typed (Tab fills it)
			local part = rest:match("^%s+(%S*)$")
			local cm = S.cur[1] and ctx.Meta[S.cur[1].canon]
			if cm and cm.complete then ui.argSuggest(cm, q, rest) end
			if S.cur[1] and part and not (cm and cm.complete) and tostring(S.cur[1].args):find("^<player") then
				local lq, list = part:lower(), {}
				for _, pl in ipairs(S.Players:GetPlayers()) do
					local nm, dn = pl.Name:lower(), pl.DisplayName:lower()
					if lq == "" or nm:find(lq, 1, true) or dn:find(lq, 1, true) then
						list[#list + 1] = { names = { pl.Name }, args = "", desc = pl.DisplayName ~= pl.Name and pl.DisplayName or "", canon = pl.Name, fill = (S.pre or "") .. q .. " " .. pl.Name .. " ", pre = nm:sub(1, #lq) == lq or dn:sub(1, #lq) == lq }
					end
				end
				table.sort(list, function(x, z)
					if x.pre ~= z.pre then return x.pre end
					return x.names[1]:lower() < z.names[1]:lower()
				end)
				for i = 1, math.min(#list, 8) do S.cur[#S.cur + 1] = list[i] end
				if #S.cur > 1 then S.sel, S.q = 2, part end
			end
		elseif rest ~= "" then
			-- more than one word that isn't a command: search by what commands do
			S.cur = ui.matches(line)
			S.q = ""
		elseif q == "" then
			if S.showAll or S.pre ~= "" then S.cur = ui.entries() else S.sugOn = true end
		else
			S.cur = ui.matches(q)
			for _, nm in ipairs(S.cur[1] and S.cur[1].names or {}) do
				if nm:sub(1, #q) == q and #nm > #q then
					-- measure what is typed, then place the grey remainder right after it
					local ok, sz = pcall(function() return S.TextService:GetTextSize(box.Text, fs(16), FONT, Vector2.new(10000, 51)) end)
					if ok then S.ghost, S.ghostX = nm:sub(#q + 1), sz.X end
					break
				end
			end
		end
		if S.sugOn then ui.sugRender() else hideSug() end
		ui.render()
	end

	function ui.move(d)
		if S.sugOn then
			local n = #(S.sugItems or {})
			if n == 0 then return end
			S.sugSel = (S.sugSel - 1 + d) % n + 1
			return sugHighlight()
		end
		if #S.cur == 0 then return end
		local n = math.min(#S.cur, cfg.lines)
		S.sel = (S.sel - 1 + d) % n + 1
		ui.render()
	end

	-- Left/Right: same row (or nearest) in the neighbouring column of the same section
function ui.moveH(d)
	local cur = (S.sugItems or {})[S.sugSel]
	if not (S.sugOn and cur and cur.col) then return end
	local best, gap
	for _, o in ipairs(S.sugItems) do
		if o.sf == cur.sf and o.col == cur.col + d and (not gap or math.abs(o.row - cur.row) < gap) then best, gap = o, math.abs(o.row - cur.row) end
	end
	for i, o in ipairs(S.sugItems) do
		if o == best then S.sugSel = i; sugHighlight() end
	end
end

-- key repeat: step once, then keep stepping while the key stays down
local holdId = 0
function ui.hold(kc, f)
	f()
	holdId = holdId + 1
	local id = holdId
	task.spawn(function()
		task.wait(0.3)
		while id == holdId and S.barOpen and S.UserInputService:IsKeyDown(kc) do f(); task.wait(0.04) end
	end)
end

-- Tab only completes the name; no trailing space
	function ui.complete()
		if S.sugOn then
			local it = (S.sugItems or {})[S.sugSel]
			if it then ui.pickSug(it) end
			return
		end
		local e = S.cur[S.sel]
		if not e then return end
		if e.fill then -- a suggested player: fill the whole line
			box.Text = e.fill
			box.CursorPosition = #box.Text + 1
			return
		end
		local q, name = S.q or "", e.canon
		for _, nm in ipairs(e.names) do
			if nm:sub(1, #q) == q then name = nm; break end
		end
		box.Text = (S.pre or "") .. name .. (S.tail or "") -- keeps the arguments already typed ("speed 50" + Tab stays "speed 50") and the "sudo @alt " in front
		box.CursorPosition = #box.Text + 1
	end

	function ui.openBar(prefill, showAll)
		if S.barOpen then return end
		S.barOpen, S.showAll = true, showAll
		S.sugMode, S.sugSel = "both", 1
		ui.layoutBar()
		box.Text = prefill or ""
		barFade.Visible = true
		barFade.Position = UDim2.fromOffset(0, cfg.pos == "Top" and -16 or 16)
		tw(barFade, { GroupTransparency = 0 }, 0.16)
		tw(barFade, { Position = UDim2.new() }, 0.3) -- slides in from the edge it hangs from
		local s = ui.curScale()
		ui.barScale.Scale = s
		tw(ui.blur, { Size = 18 * cfg.blur }, 0.2)
		if S.panelOpen and ui.shade then ui.shade.Visible = true end
		ui.syncMouse()
		for _, f in ipairs(S.glowFields) do f.play() end
		S.RunService.RenderStepped:Wait() -- lets the key press that opened the bar finish, so ";" isn't typed into the box
		box:CaptureFocus()
		box.Text = prefill or ""
		box.CursorPosition = #box.Text + 1
		ui.search()
	end

	function ui.closeBar()
		if not S.barOpen then return end
		S.barOpen, S.sugOn = false, false
		for _, f in ipairs(S.glowFields) do f.stop() end
		box:ReleaseFocus()
		tw(barFade, { GroupTransparency = 1 }, 0.1)
		task.delay(dur(0.1), function() -- hide (and clear the text) once faded, unless reopened meanwhile
			if not S.barOpen then barFade.Visible = false; box.Text = "" end
		end)
		if ui.shade then ui.shade.Visible = false end
		tw(ui.blur, { Size = 0 }, 0.2)
		ui.syncMouse()
	end

	-- clicking a suggestion takes focus from the box; that must not close the bar
	local function mouseInList()
		if not listF.Visible then return false end
		local m, p, s = S.UserInputService:GetMouseLocation(), listF.AbsolutePosition, listF.AbsoluteSize
		return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
	end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if box.Text:find("\t") then -- Tab types a tab character right after ui.complete ran: drop it
			box.Text = box.Text:gsub("\t", "")
			box.CursorPosition = #box.Text + 1
			return -- setting the text fires this again, which searches
		end
		if S.barOpen then ui.search() end
	end)
	box.FocusLost:Connect(function(enter)
		if not S.barOpen then return end
		if not enter and mouseInList() then
			task.defer(function() if S.barOpen then box:CaptureFocus() end end)
			return
		end
		local line = box.Text
		ui.closeBar()
		if enter and line:match("%S") then
			ui.pushHistory(line)
			ctx.Run(line)
		end
	end)
end
-- [/UI_BAR]

-- [UI_PANEL]
-- ===== UI: panel frame (slide 4: 685x443, sidebar 141x36 tabs, inner 532x379 at 141,52) ===========
local pages, tabs, onShow = {}, {}, {}
local onHide, lazy, pending = {}, {}, {} -- onHide[tab]: frees the rows of a tab you left; lazy[tab]: builds a page the first time it opens; pending[tab]: it is building right now
-- layout table (design pixels). The panel is ~10% bigger than the old 685x443 and every page takes its size from here
local L = { PW = 760, PH = 488, SIDE = 152, TOP = 58, MARG = 12 }
L.IX = L.SIDE + 2 -- inner area x
L.IW = L.PW - L.IX - L.MARG -- inner width (594)
L.IH = L.PH - L.TOP - L.MARG -- inner height (418)
L.DX = L.IW - 532 -- extra width the pages got
L.DY = L.IH - 379 -- extra height the pages got
S.opScope = true -- from here on fr() registers its fills for opacity scaling (the command bar above is not scaled)
do
	local panelFade = new("CanvasGroup", { Name = "PanelFade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false }, gui)
	local panel = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(L.PW, L.PH), BorderSizePixel = 0, Active = true }, panelFade) -- Active: a click on the panel never reaches the game
	paint(panel, "BackgroundColor3", "panel") -- transparency comes from the UI Opacity setting (reference: 80%)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
	-- border: an accent comet circles the window (the gradient on the stroke rotates; seamless because both ends match)
	local pst = new("UIStroke", { Thickness = 1.5, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)
	paint(pst, "Color", "accent")
	local pgr = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.88), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 0) }) }, pst)
	S.deco(pgr) -- light mode: a plain accent border
	ui.borderTween = S.TweenService:Create(pgr, TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 })
	if cfg.anim ~= 0 then ui.borderTween:Play() end
	-- soft glows drifting behind the content: big, faint, each picks a random spot and drifts there over 14 to 28 s (Sine in / out), and its strength wanders by a few percent. A glow is stacked circles at tiny alpha inside a CanvasGroup (UIGradient is linear only; the group lets GroupTransparency vary the whole glow). Dark mode only (S.deco)
	do
		-- a CanvasGroup clips to its UICorner (ClipsDescendants only clips to a rectangle, so the glows poked out of the rounded window corners)
		local clip = new("CanvasGroup", { Size = UDim2.fromOffset(L.PW, L.PH), BackgroundTransparency = 1, BorderSizePixel = 0 }, panel)
		new("UICorner", { CornerRadius = UDim.new(0, 12) }, clip)

		local holds, tws, live, gen = {}, {}, false, 0
		-- accent?, diameter, alpha in the middle
		for _, g in ipairs({ { true, 900, 0.3 }, { true, 760, 0.22 }, { true, 1000, 0.16 }, { false, 700, 0.12 } }) do
			local d = g[2]
			local hold = new("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(math.random(0, L.PW), math.random(0, L.PH)), Size = UDim2.fromOffset(d, d),
				BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = math.random(0, 12) / 100 }, clip)
			holds[#holds + 1] = hold
			if not g[1] then S.deco(hold) end -- the white glow is dark mode only; the accent glows show in both themes
			local n = 18
			hold:SetAttribute("peak", g[3])
			local a = 1 - (1 - g[3] * math.clamp((tonumber(cfg.glow) or 80) / 80, 0, 1.25)) ^ (1 / n)
			for i = 1, n do
				local c = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(d * i / n, d * i / n), BorderSizePixel = 0, BackgroundTransparency = 1 - a }, hold)
				if g[1] then paint(c, "BackgroundColor3", "accent") else c.BackgroundColor3 = Color3.new(1, 1, 1) end
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
			end
		end
		-- glow strength follows Look and feel > Glow Opacity (cfg.glow 30 / 60 / 80 / 100; 80 = the original look)
		function ui.setGlow()
			local K = math.clamp((tonumber(cfg.glow) or 80) / 80, 0, 1.25)
			for _, f in ipairs(S.glowFields) do f.set(K) end -- the command bar and its list
			clip.Visible = K > 0 -- glow 0 = nothing to draw: 72 frames and 4 big canvases less
			for _, h in ipairs(holds) do
				local a = 1 - (1 - h:GetAttribute("peak") * K) ^ (1 / 18)
				for _, c in ipairs(h:GetChildren()) do
					if c:IsA("Frame") then tw(c, { BackgroundTransparency = 1 - a }, 0.3) end
				end
			end
		end
		local function go(h, my)
			if not live or my ~= gen then return end
			local secs = math.random(140, 280) / 10
			local t = S.TweenService:Create(h, TweenInfo.new(secs, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.fromOffset(math.random(0, L.PW), math.random(0, L.PH)) })
			local ta = S.TweenService:Create(h, TweenInfo.new(secs * 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { GroupTransparency = math.random(0, 12) / 100 })
			tws[h] = { t, ta }
			t.Completed:Connect(function() go(h, my) end)
			t:Play(); ta:Play()
		end
		local function stop()
			live, gen = false, gen + 1
			for _, p in pairs(tws) do for _, t in ipairs(p) do t:Cancel() end end
			tws = {}
		end
		-- one handle: ui.apply / ui.unload call :Play() / :Pause() / :Cancel() on it
		ui.orbitTween = { Play = function() if live then return end live, gen = true, gen + 1 for _, h in ipairs(holds) do go(h, gen) end end, Pause = stop, Cancel = stop }
		if cfg.anim ~= 0 then ui.orbitTween:Play() end
	end

	ui.panel = panel
	ui.panelScale = new("UIScale", {}, panel)
	-- ZIndex 1 and created right after the drifting glows, before the sidebar / inner area / pages: it draws over the glows and under every tile, card and button
	S.spot(panel, L.PW, L.PH, 12, 1, panel, function() return S.panelOpen and not S.barOpen end)
	-- accent line along the top edge: a dim base plus a highlight that glides across (paused with Animation Speed: none)
	fr(panel, 14, 0, L.PW - 28, 2, "accent", 0.7)
	do
		local glow = fr(panel, 14, 0, L.PW - 28, 2, "accent", 0)
		local g = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, glow)
		ui.glowTween = S.TweenService:Create(g, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Offset = Vector2.new(1, 0) })
		if cfg.anim ~= 0 then ui.glowTween:Play() end
	end

	-- position is kept as a fraction of the screen so the zoom can never offset it
	function ui.placePanel(extraY, animate)
		local vp = workspace.CurrentCamera.ViewportSize
		local pos = UDim2.fromScale(ui.panelPos.X, ui.panelPos.Y + (extraY or 0) / vp.Y)
		if animate then tw(panel, { Position = pos }, 0.3) else panel.Position = pos end
	end
	function ui.centerPanel()
		ui.panelPos = Vector2.new(0.5, 0.5)
		ui.placePanel(0)
	end
	ui.centerPanel()

	ui.title = txt(panel, "", 14, "text", 22, 17, 150, 26, { Font = FONT_CODE, RichText = true, TextSize = 21 })
	S.deco(new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(165, 165, 178)) }, ui.title)) -- metallic title
	do -- hairline under the header that fades out at both ends
		local hd = fr(panel, 14, L.TOP - 1, L.PW - 28, 1, "accent", 0.8)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, hd)
		S.deco(hd)
	end
	txt(panel, "open-source admin/dev panel", 8, "hint", 172, 25, 220, 14, { Font = FONT_CODE, TextSize = 11 })

	btn(panel, "×", L.PW - 46, 14, 34, 28, "ghost", nil, function() ui.setPanel(false) end, 13)

	-- relay indicator: hidden until region-relay.py answers once; green ok, orange rate limited, red errors / connection lost. PID beside it
	do
		local rel = { sys = {}, pid = "-", col = { ok = Color3.fromRGB(70, 200, 90), warn = Color3.fromRGB(255, 165, 40), bad = Color3.fromRGB(230, 60, 60) } }
		ui.rel = rel
		local rdot = new("Frame", { Position = UDim2.fromOffset(L.PW - 66, 24), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0, Visible = false }, panel)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, rdot)
		local rpid = txt(panel, "", 8, "sub", L.PW - 148, 22, 76, 14, { TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Visible = false })
		local function poll()
			local ok, r = pcall(request, { Url = "http://127.0.0.1:47653/sys", Method = "GET" })
			local d
			if ok and type(r) == "table" and r.StatusCode == 200 then ok, d = pcall(S.HttpService.JSONDecode, S.HttpService, r.Body) end
			if type(d) == "table" then rel.sys, rel.s = d, d.err and "bad" or d.warn and "warn" or "ok"
			elseif rel.s then rel.s = "bad" end -- answered before, silent now
			local f = (getgenv and getgenv() or {}).getpid or (getgenv and getgenv() or {}).get_pid
			local pk, p = pcall(function() return f() end)
			local ps = rel.sys.pids
			-- shortcut: with several Roblox clients open the relay lists every PID, it cannot tell which one is this client; upgrade if an executor exposes its own PID
			rel.pid = pk and tonumber(p) and tostring(p) or (ps and #ps > 0 and table.concat(ps, "/")) or "-"
			rdot.Visible, rpid.Visible = rel.s ~= nil, rel.s ~= nil
			if rel.s then rdot.BackgroundColor3, rpid.Text = rel.col[rel.s], "PID " .. rel.pid end
		end
		task.spawn(function()
			local first = true
			while S.alive do
				if S.panelOpen or first then first = false; pcall(poll) end
				task.wait(3)
			end
		end)
	end

	-- drag by the title bar; moves in screen fractions
	local header = new("Frame", { Size = UDim2.fromOffset(L.PW - 50, L.TOP - 6), BackgroundTransparency = 1 }, panel)
	local drag, d0, p0
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag, d0, p0 = true, i.Position, ui.panelPos
		end
	end)
	conn(S.UserInputService.InputChanged, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local vp = workspace.CurrentCamera.ViewportSize
			local d = i.Position - d0
			ui.panelPos = Vector2.new(p0.X + d.X / vp.X, p0.Y + d.Y / vp.Y)
			ui.placePanel(0)
		end
	end)
	conn(S.UserInputService.InputEnded, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
			drag = false
			S.dragged = true
		end
	end)

	local inner = fr(panel, L.IX, L.TOP, L.IW, L.IH, "glass", 0.75, 10, "edge", 1, 0.7) -- a darkening veil (pure black in dark mode, grey in light), no tinted fill, so it darkens without turning the glow muddy -- a faint white veil instead of a dark fill: it brightens whatever glows behind it, a dark fill turned the yellow glow muddy olive
	inner.ClipsDescendants = true
	ui.inner = inner

	-- ===== loading + page motion =====
	-- ONE loading state for the whole panel: a pill in the corner of the page area and a sweeping accent line along its top edge. Shown only while something of the tab you are ON is working
	do
		local act, shown = {}, false
		local pill = new("CanvasGroup", { Name = "Busy", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(98, 24), BackgroundTransparency = 0.1,
			BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 30, Interactable = false }, inner)
		paint(pill, "BackgroundColor3", "bar")
		new("UICorner", { CornerRadius = UDim.new(0, ST.rCtrl) }, pill)
		paint(new("UIStroke", { Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pill), "Color", "accent")
		local lab = txt(pill, "Loading", 9, "text", 14, 0, 80, 24, { TextYAlignment = Enum.TextYAlignment.Center })
		local line = new("Frame", { Position = UDim2.fromOffset(-90, 0), Size = UDim2.fromOffset(90, 2), BorderSizePixel = 0, Visible = false, ZIndex = 30, Interactable = false }, inner)
		paint(line, "BackgroundColor3", "accent")
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, line)
		local sweep = S.TweenService:Create(line, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1), { Position = UDim2.fromOffset(L.IW, 0) })
		ui.busyTween = sweep
		local function want()
			local now = os.clock()
			for k, e in pairs(act) do
				if now - e.t > 20 then act[k] = nil -- a build that died never leaves the pill on
				elseif e.tab == nil or e.tab == ui.tab then return true end
			end
			return false
		end
		function ui.busySync()
			local w = want()
			if w == shown then return end
			shown, ui.busyOn = w, w
			if w then
				pill.Visible, line.Visible = true, true
				tw(pill, { GroupTransparency = 0 }, 0.16)
				if cfg.anim ~= 0 and S.panelOpen then sweep:Play() end
				task.spawn(function()
					local i = 0
					while shown and S.alive do
						i = i % 3 + 1
						lab.Text = "Loading" .. ("."):rep(i)
						task.wait(0.35)
					end
				end)
			else
				tw(pill, { GroupTransparency = 1 }, 0.16)
				task.delay(dur(0.16) + 0.05, function()
					if not shown then pill.Visible, line.Visible = false, false; sweep:Pause() end
				end)
			end
		end
		function ui.busy(key, on, tab) -- ui.busy("players", true, "Players") ... ui.busy("players", false)
			act[key] = on and { t = os.clock(), tab = tab } or nil
			ui.busySync()
		end
	end
	-- the ambient loops (drifting glows, border comet, loading sweep) only run while the panel is open and animations are on; the glow layer also stops at Glow Opacity 0
	function ui.ambient()
		local on = S.panelOpen and cfg.anim ~= 0
		for _, tn in ipairs({ "glowTween", "borderTween", "orbitTween", "busyTween" }) do
			local t = ui[tn]
			if t then
				pcall(function()
					local run = on and (tn ~= "orbitTween" or (tonumber(cfg.glow) or 0) > 0) and (tn ~= "busyTween" or ui.busyOn)
					if run then t:Play() else t:Pause() end
				end)
			end
		end
	end
	-- pages that are built the first time they open: ui.lazy(name, builder). The builder runs in its own thread and yields every few rows (ui.tick), so the panel never stalls
	function ui.lazy(name, fn) lazy[name] = fn end
	ui.building = {}
	function ui.tick()
		local th = coroutine.running()
		if not ui.building[th] then return end
		ui.nTick = (ui.nTick or 0) + 1
		if ui.nTick % 6 == 0 then task.wait() end
	end
	-- page motion: the whole page fades in (0.16 token) while it slides up 18 px (0.3 token), both on the one Sine Out curve
	function ui.pageIn(p)
		if cfg.anim == 0 then p.GroupTransparency, p.Position = 0, UDim2.new(); return end
		p.GroupTransparency, p.Position = 1, UDim2.fromOffset(0, 18)
		tw(p, { GroupTransparency = 0 }, 0.16)
		tw(p, { Position = UDim2.new() }, 0.3)
	end
	function ui.showPage(name, animate)
		local p, mk = pages[name], lazy[name]
		if pending[name] then return end
		if not mk then
			if animate then ui.pageIn(p) end
			if onShow[name] then onShow[name]() end
			return
		end
		lazy[name], pending[name] = nil, true
		p.GroupTransparency = 1
		ui.busy("page:" .. name, true, name)
		task.spawn(function()
			local th = coroutine.running()
			ui.building[th] = true
			task.wait() -- the tab highlight and the loading pill paint first
			local ok, err = pcall(mk)
			ui.building[th], pending[name] = nil, nil
			ui.busy("page:" .. name, false)
			if not ok then ctx.notify(name .. " page failed: " .. tostring(err), 6) end
			if ui.tab == name then
				ui.pageIn(p)
				if onShow[name] then onShow[name]() end
			else
				p.GroupTransparency = 0
			end
		end)
	end



	-- sidebar: the everyday tabs on top, then what you build with (TOOLS), then how the panel behaves (SETTINGS). 32 px tabs on a 36 px pitch, a small label over each group
	local TABS, GL, TH, ty = {}, {}, 32, L.TOP + 8
	for _, g in ipairs({ { nil, { "Home", "Players", "Servers" } }, { "TOOLS", { "Commands", "Keybinds", "Autostart", "Load scripts" } }, { "SETTINGS", { "Look and feel", "Preferences", "Module Cfg" } } }) do
		if g[1] then GL[#GL + 1] = { g[1], ty + 5 }; ty = ty + 22 end
		for _, n in ipairs(g[2]) do TABS[#TABS + 1] = { n, ty }; ty = ty + 36 end
	end
	ui.side = fr(panel, 0, L.TOP, L.SIDE, L.IH, "glass", 0.75, 10, "edge", 1, 0.7)
	for _, g in ipairs(GL) do txt(panel, g[1], 7, "hint", 6, g[2], L.SIDE - 26, 14, { Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right }) end -- right aligned like the tab labels


	 -- one dark column behind every tab
	for _, t in ipairs(TABS) do
		local name = t[1]
		-- every tab owns a glow (strongest on the text side, fading to the left) and an accent bar that fade in when it is selected
		local fx = { glow = fr(panel, 6, t[2], L.SIDE - 12, TH, nil) }
		paint(fx.glow, "BackgroundColor3", "accent")
		fx.glow.BackgroundTransparency = 1
		S.deco(fx.glow)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, fx.glow)
		new("UIGradient", { Transparency = NumberSequence.new(1, 0.75) }, fx.glow)
		ui.tabFx = ui.tabFx or {}
		ui.tabFx[name] = fx
		local b = new("TextButton", { Position = UDim2.fromOffset(6, t[2]), Size = UDim2.fromOffset(L.SIDE - 12, TH), AutoButtonColor = false, BorderSizePixel = 0,
			Text = name, Font = FONT, TextSize = fs(10.5), TextXAlignment = Enum.TextXAlignment.Right }, panel)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
		new("UIPadding", { PaddingRight = UDim.new(0, 14) }, b)
		paint(b, "TextColor3", "text")
		b.BackgroundTransparency = 1
		tabs[name] = b
		fx.bar = fr(panel, 12, t[2] + 8, 3, 16, "accent", 1, 2)
		ui.tabY = ui.tabY or {}
		ui.tabY[name] = t[2]
		S.hover(b, function(v) -- hover previews the selected look, with the same glow strength every control uses
			if ui.tab ~= name then
				tw(fx.glow, { BackgroundTransparency = v and ST.glow.hover or 1 }, 0.1)
				tw(fx.bar, { BackgroundTransparency = v and 0.7 or 1 }, 0.1)
			end
		end)
		b.MouseButton1Click:Connect(function() ui.selectTab(name) end)
		pages[name] = new("CanvasGroup", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, inner) -- a CanvasGroup so the whole page fades as one
	end

	-- the selected tab gets an accent tint, accent text and a bar that slides to it
	
	function ui.selectTab(name)
		local first, prev = ui.tab == nil, ui.tab
		ui.tab = name
		for n, p in pairs(pages) do p.Visible = (n == name) end
		if prev and prev ~= name and onHide[prev] then pcall(onHide[prev]) end -- culling: the tab you left frees its rows
		if ui.busySync then ui.busySync() end
		for n, b in pairs(tabs) do
			local on = n == name
			paint(b, "BackgroundColor3", on and "accent" or "tabOff")
			paint(b, "TextColor3", on and "accentText" or "text")
			tw(b, { BackgroundTransparency = on and 0.82 or 1 }, 0.12)
			tw(ui.tabFx[n].glow, { BackgroundTransparency = on and 0 or 1 }, 0.22)
			tw(ui.tabFx[n].bar, { BackgroundTransparency = on and 0 or 1 }, 0.22)
		end
		
		ui.showPage(name, first or prev ~= name)
	end

	-- dark layer over the panel while the command bar is open: the panel can't be clicked until the bar closes
	ui.shade = fr(panel, 0, 0, L.PW, L.PH, "tabOff", 0.45, 9)
	ui.shade.ZIndex, ui.shade.Active, ui.shade.Visible = 50, true, false

	function ui.setPanel(open)
		if open and S.panelOpen then return end -- already open: openTab / ;ui / a profile used to re-play the open slide and the old tab's onShow
		S.panelOpen = open
		ui.ambient()
		if open then
			local s = ui.curScale()
			ui.panelScale.Scale = s -- no scale pop: text re-rasterises at every scale step and snaps into size; the slide below + fade is smooth
			ui.placePanel(22, false)
			panelFade.Visible = true
			tw(panelFade, { GroupTransparency = 0 }, 0.16)
			ui.placePanel(0, true) -- slides up into place while it fades in

			ui.shade.Visible = S.barOpen and true or false
			if onShow[ui.tab] then onShow[ui.tab]() end
		else -- shrinks away first, then hides (unless it was opened again meanwhile)

			tw(panelFade, { GroupTransparency = 1 }, 0.12)
			ui.placePanel(12, true)
			task.delay(dur(0.12), function() if not S.panelOpen then panelFade.Visible = false end end)
		end
		ui.syncMouse()
	end
end
-- [/UI_PANEL]

-- [PG_HOME]
-- ===== page: Home (slide 4, positions = deck coords minus the inner origin 657,340) ===================
do
	local h = pages["Home"]
	-- some places call themselves "Ugc": keep the experience's real name per universe (so a teleport inside the experience
	-- keeps it), and only ask Roblox when nothing better is known
	local function goodName(n) return type(n) == "string" and n ~= "" and n ~= "Ugc" and n ~= "Game" and not n:match("^Place%d*$") end
	local gid = tostring(game.GameId)
	-- teleported here from an experience we already know, and this place only calls itself "Ugc": keep the previous name and icon
	local carry = cfg.carry
	if not goodName(game.Name) and not cfg.exp[gid] and carry and carry.name and os.time() - (carry.t or 0) < 300 then
		cfg.exp[gid], cfg.expIcon[gid] = carry.name, carry.gid
		save()
	end
	local expName = cfg.exp[gid] or (goodName(game.Name) and game.Name or nil)
	if goodName(game.Name) and not cfg.exp[gid] then cfg.exp[gid] = game.Name; save() end
	if expName then ctx.curExp = { gid = cfg.expIcon[gid] or game.GameId, name = expName } end
	ctx.connect("expTp", lp.OnTeleport, function() -- remembered for the next place, which may only call itself "Ugc"
		if ctx.curExp then cfg.carry = { gid = ctx.curExp.gid, name = ctx.curExp.name, t = os.time() }; save() end
	end)

	-- ===== hero: the experience's own screenshots (Roblox media API) cross-fade and drift slowly behind its icon, name and server =====
	local rise = {} -- { object, x, y }: slides up when Home opens
	local LW, GAP = math.floor(L.IW * 0.4), 12 -- left column (you) width and the gap
	local RX = 18 + LW + GAP -- right column (server) x
	local HW = L.IW - RX - 18 -- right column width
	local hero = new("CanvasGroup", { Position = UDim2.fromOffset(RX, 16), Size = UDim2.fromOffset(HW, 132), BorderSizePixel = 0, BackgroundTransparency = 0.1 }, h)
	paint(hero, "BackgroundColor3", "row")
	new("UICorner", { CornerRadius = UDim.new(0, ST.rPane) }, hero)
	paint(new("UIStroke", { Thickness = 1, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, hero), "Color", "accent")
	local heroName, heroSub, heroVal, layers, dotBox
	do
		local fb = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 0.55, ZIndex = 1 }, hero) -- shown until a screenshot loads (or when there is none)
		paint(fb, "BackgroundColor3", "accent")
		new("UIGradient", { Rotation = 35, Transparency = NumberSequence.new(0.35, 0.85) }, fb)
		layers = {}
		for i = 1, 2 do
			local im = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
				BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, ImageTransparency = 1, ZIndex = 2 }, hero)
			layers[i] = { im = im, sc = new("UIScale", {}, im) }
		end
		local scrim = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 4 }, hero)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.45, 0.85), NumberSequenceKeypoint.new(1, 0.1) }) }, scrim)
		local function white(str, pt, x, y, w, hh, font)
			return new("TextLabel", { BackgroundTransparency = 1, Text = str, TextSize = fs(pt), Font = font or FONT, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.88, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, hh), ZIndex = 6 }, hero)
		end
		local icon = new("ImageLabel", { Position = UDim2.fromOffset(14, 50), Size = UDim2.fromOffset(64, 64), BorderSizePixel = 0, ScaleType = Enum.ScaleType.Crop, BackgroundColor3 = Color3.new(0.1, 0.1, 0.12), ZIndex = 6,
			Image = thumb("GameIcon", cfg.expIcon[gid] or game.GameId, 150) }, hero)
		new("UICorner", { CornerRadius = UDim.new(0, 15) }, icon)
		new("UIStroke", { Thickness = 1.5, Color = Color3.new(1, 1, 1), Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, icon)
		heroName = white(expName or "...", 15, 90, 52, HW - 104, 26, FONT_B)
		heroSub = white("", 9, 90, 80, HW - 104, 18)
		heroSub.TextTransparency = 0.15
		 heroVal = white("", 9, 90, 98, HW - 104, 16)
		 heroVal.TextTransparency = 0.15
		-- server chip (top left): click copies the job id
		local jid = game.JobId ~= "" and game.JobId or "local"
		local chip = new("TextButton", { Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
			BorderSizePixel = 0, AutoButtonColor = false, Text = "●  " .. jid:sub(1, 8), TextSize = fs(8.5), Font = FONT_B, TextColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, hero)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, chip)
		chip.MouseEnter:Connect(function() tw(chip, { BackgroundTransparency = 0.3 }, 0.1) end)
		chip.MouseLeave:Connect(function() tw(chip, { BackgroundTransparency = 0.5 }, 0.12) end)
		chip.MouseButton1Click:Connect(function()
			if setclipboard and game.JobId ~= "" then pcall(setclipboard, game.JobId); ui.toast("Server ID copied", 1.5) end
		end)
		-- page dots (bottom right, built once the screenshots are known)
		dotBox = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromOffset(HW - 12, 120), Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55, BorderSizePixel = 0, Visible = false, ZIndex = 6 }, hero)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, dotBox)
		new("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, dotBox)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center }, dotBox)
	end

	-- screenshots: ids cached a day per experience; the second layer cross-fades in over the first, each one zooms slowly (Linear)
	local B = { ids = {}, cur = 0, front = 1, dots = {} }
	local function bannerShow(i)
		local to = B.front == 1 and 2 or 1
		local L, O = layers[to], layers[B.front]
		B.cur = i
		L.im.Image = ("rbxthumb://type=Asset&id=%d&w=768&h=432"):format(B.ids[i])
		local t0 = os.clock()
		while not L.im.IsLoaded and os.clock() - t0 < 5 and S.alive do task.wait(0.1) end
		if not S.alive then return end
		L.im.ZIndex, O.im.ZIndex = 3, 2
		L.sc.Scale = 1
		tw(L.im, { ImageTransparency = 0 }, 0.5)
		if cfg.anim ~= 0 then S.TweenService:Create(L.sc, TweenInfo.new(7 / cfg.anim, Enum.EasingStyle.Linear), { Scale = 1.12 }):Play() end -- tw() snaps every duration to a motion token (7 s became 0.6 s)
		task.delay(dur(0.5) + 0.05, function() if B.front == to then O.im.ImageTransparency = 1 end end) -- B.front is set right below, so ~= was always false and only the first change faded
		B.front = to
		for k, d in ipairs(B.dots) do tw(d, { Size = UDim2.fromOffset(k == i and 16 or 6, 6), BackgroundTransparency = k == i and 0 or 0.55 }, 0.2) end
	end
	task.spawn(function()
		local c = cfg.banner[gid]
		local ids = c and type(c.ids) == "table" and #c.ids > 0 and os.time() - (c.t or 0) < 86400 and c.ids or nil
		if not ids then
			local body = ctx.fetch("https://games.roblox.com/v2/games/" .. game.GameId .. "/media")
			local ok, data = pcall(function() return S.HttpService:JSONDecode(body).data end)
			ids = {}
			if ok and type(data) == "table" then
				for _, m in ipairs(data) do
					if m.assetType == "Image" and tonumber(m.imageId) then ids[#ids + 1] = tonumber(m.imageId) end
					if #ids >= 6 then break end
				end
			end
			if #ids > 0 then cfg.banner[gid] = { ids = ids, t = os.time() }; save() end
		end
		if #ids == 0 then -- no screenshots (or no network): the icon, large and soft, behind the accent
			layers[1].im.Image = thumb("GameIcon", cfg.expIcon[gid] or game.GameId, 420)
			tw(layers[1].im, { ImageTransparency = 0.55 }, 0.5)
			return
		end
		B.ids = ids
		if #ids > 1 then
			dotBox.Visible = true
			for k = 1, #ids do B.dots[k] = new("Frame", { Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0 }, dotBox); new("UICorner", { CornerRadius = UDim.new(1, 0) }, B.dots[k]) end
		end
		bannerShow(1)
		while S.alive and #ids > 1 do
			local t0 = os.clock()
			repeat task.wait(0.5) until not S.alive or (os.clock() - t0 > 8 and S.panelOpen and ui.tab == "Home")
			if S.alive then bannerShow(B.cur % #ids + 1) end
		end
	end)
	if not expName then
		task.spawn(function()
			-- the games API returns the experience's name (the place name is what says "Ugc")
			local body = ctx.fetch("https://games.roblox.com/v1/games?universeIds=" .. game.GameId)
			local ok, data = pcall(function() return S.HttpService:JSONDecode(body).data[1].name end)
			local n = ok and goodName(data) and data or nil
			if not n then
				local ok2, info = pcall(function() return S.MarketplaceService:GetProductInfo(game.PlaceId) end)
				n = ok2 and info and goodName(info.Name) and info.Name or nil
			end
			if n then cfg.exp[gid] = n; ctx.curExp = { gid = game.GameId, name = n }; save() end
			heroName.Text = n or game.Name
		end)
	end

	-- ===== stat tiles: Players (with a fill bar), Region, Latency (green / orange / red), Uptime =====
	local vals, bar, region = {}, nil, "..."
	local rg = ctx.SRV.region(game.JobId) -- cached by an earlier scan or lookup: shown at once
	if rg then region = rg.label end
	local TY, TG = 158, 8 -- first tile row y and the gap
	local TW = math.floor((HW - TG) / 2)
	for i, name in ipairs({ "Players", "Region", "Latency", "Uptime" }) do
		local x, y = RX + ((i - 1) % 2) * (TW + TG), TY + math.floor((i - 1) / 2) * (62 + TG)
		local t = fr(h, x, y, TW, 62, "row", 0.6, 12, "edge", 1, 0.6)
		rise[#rise + 1] = { t, x, y }
		txt(t, name:upper(), 7.5, "sub", 14, 10, TW - 28, 12, { Font = FONT_B })
		vals[name] = txt(t, "-", 13, "text", 14, 24, TW - 28, 22, { Font = FONT_B, TextYAlignment = Enum.TextYAlignment.Center, TextScaled = name == "Region" })
		if name == "Region" then new("UITextSizeConstraint", { MaxTextSize = fs(13) }, vals[name]) end -- a long city shrinks to fit instead of being cut
		if name == "Players" then
			local track = fr(t, 14, 51, TW - 28, 3, "edge", 0.5, 2)
			bar = fr(track, 0, 0, 0, 3, "accent", 0, 2)
		end
	end

	-- ===== profile card + bio / tip card =====
	local PWD = LW
	local function pchFor(msg) -- profile card height: the welcome message sits under the name block (y 92) and may wrap to any number of lines
		local ok, sz = pcall(function() return S.TextService:GetTextSize(msg, fs(9.5), FONT, Vector2.new(PWD - 32, 1000)) end)
		return ok and math.max(126, 92 + math.ceil(sz.Y) + 14) or 126
	end
	local msg0 = HOME_MSGS[math.random(#HOME_MSGS)]
	local PCH = pchFor(msg0)
	local pc = fr(h, 18, 16, PWD, PCH, "row", 0.6, 14, "edge", 1, 0.6)
	rise[#rise + 1] = { pc, 18, 16 }
	local av = new("ImageLabel", { Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(62, 62), BorderSizePixel = 0, BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", lp.UserId, 150) }, pc)
	paint(av, "BackgroundColor3", "row")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	paint(new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, av), "Color", "accent")
	txt(pc, "Good day,", 8.5, "sub", 92, 19, PWD - 104, 13)
	txt(pc, lp.DisplayName, 13, "text", 92, 33, PWD - 104, 20, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
	txt(pc, "@" .. lp.Name, 8.5, "sub", 92, 55, PWD - 104, 13, { TextTruncate = Enum.TextTruncate.AtEnd })
	local welcomeTxt = txt(pc, msg0, 9.5, "sub", 16, 92, PWD - 32, PCH - 100, { TextWrapped = true })

	local BX0, BWD, BY = 18, LW, 16 + PCH + 10
	local CH = L.IH - BY - 18
	local bc = fr(h, BX0, BY, BWD, CH, "row", 0.6, 14, "edge", 1, 0.6)
	local bcRise = { bc, BX0, BY }
	rise[#rise + 1] = bcRise
	if cfg.bio ~= "" then cfg.bios[tostring(lp.UserId)] = cfg.bios[tostring(lp.UserId)] or cfg.bio; cfg.bio = ""; save() end -- old single bio -> this account
	local bio = new("TextBox", { Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(BWD - 28, CH - 80), BorderSizePixel = 0, BackgroundTransparency = 0.8,
		Font = FONT, TextSize = fs(9.5), MultiLine = true, TextWrapped = true, ClearTextOnFocus = false, Text = cfg.bios[tostring(lp.UserId)] or "", PlaceholderText = "customizable bio",
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, bc)
	paint(bio, "BackgroundColor3", "tabOff"); paint(bio, "TextColor3", "text"); paint(bio, "PlaceholderColor3", "dim")
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, bio)
	local bst = new("UIStroke", { Thickness = 1, Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, bio)
	paint(bst, "Color", "tabOff")
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6) }, bio)
	bio.Focused:Connect(function() tw(bst, { Color = S.accent, Transparency = 0.2 }, 0.1) end)
	bio.FocusLost:Connect(function()
		tw(bst, { Color = col("tabOff"), Transparency = 0.8 }, 0.12)
		cfg.bios[tostring(lp.UserId)] = bio.Text ~= "" and bio.Text or nil; save()
	end)
	local tipBar = fr(bc, 14, CH - 56, 3, 36, "accent", 0, 2)
	local tipLbl = txt(bc, "TIP", 7.5, "accentText", 24, CH - 58, 100, 12, { Font = FONT_B })
	local tip = txt(bc, TIPS[1], 9, "dim", 24, CH - 43, BWD - 40, 30, { TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
	-- a new welcome message: the profile card resizes to it and the bio / tip card takes the rest
	local function fit(msg)
		PCH = pchFor(msg)
		BY = 16 + PCH + 10; CH = L.IH - BY - 18
		welcomeTxt.Text = msg
		pc.Size, welcomeTxt.Size = UDim2.fromOffset(PWD, PCH), UDim2.fromOffset(PWD - 32, PCH - 100)
		bcRise[3] = BY
		bc.Position, bc.Size = UDim2.fromOffset(BX0, BY), UDim2.fromOffset(BWD, CH)
		bio.Size = UDim2.fromOffset(BWD - 28, CH - 80)
		tipBar.Position, tipLbl.Position, tip.Position = UDim2.fromOffset(14, CH - 56), UDim2.fromOffset(24, CH - 58), UDim2.fromOffset(24, CH - 43)
	end

	-- ===== server actions (right column, anchored to the bottom); Rejoin / Server hop need a second click so a stray click can't throw you out =====
	local AW = math.floor((HW - 8) / 2)
	local function quick(label, x, y, w, cb)
		local b = btn(h, label, x, y, w, 28, nil, nil, cb)
		rise[#rise + 1] = { b, x, y }
		return b
	end
	local function confirmBtn(label, x, y, cmd)
		local armed, b = false, nil
		b = quick(label, x, y, AW, function()
			if armed then armed = false; b.Text = label; setFill(b); return ctx.Run(cmd) end
			armed, b.Text = true, "Click again"
			setFill(b, "danger") -- armed: the next click throws you out of this server
			task.delay(3, function() if armed and b.Parent then armed = false; b.Text = label; setFill(b) end end)
		end)
	end
	local AY = L.IH - 18 - 28 -- bottom row
	quick("Open server browser", RX, AY, HW, function() ctx.openTab("Servers") end)
	confirmBtn("Rejoin", RX, AY - 34, "rejoin")
	confirmBtn("Server hop", RX + AW + 8, AY - 34, "serverhop")
	quick("Copy Job ID", RX, AY - 68, AW, function() ctx.Run("jobid") end)
	quick("Copy Place ID", RX + AW + 8, AY - 68, AW, function() ctx.Run("placeid") end)

	-- opening: the hero fades in, the tiles and cards rise one after another
	onShow["Home"] = function()
		if cfg.anim == 0 then return end
		hero.GroupTransparency = 1
		tw(hero, { GroupTransparency = 0 }, 0.3)
		for i, r in ipairs(rise) do
			r[1].Position = UDim2.fromOffset(r[2], r[3] + 10)
			task.delay(i * 0.03, function() tw(r[1], { Position = UDim2.fromOffset(r[2], r[3]) }, 0.3) end)
		end
	end

	-- this server's region: cached, or looked up once (ctx.SRV.here); a failure retries every 30 s while Home is open
	local rTry, rBusy, rDone = 0, false, rg ~= nil
	local function regionStep()
		if rDone or rBusy or os.clock() - rTry < 30 then return end
		rBusy, rTry = true, os.clock()
		task.spawn(function()
			local ok, label = pcall(ctx.SRV.here)
			rBusy = false
			if ok and label then region, rDone = label, true
			else region = ctx.SRV.relay == false and "Relay inactive" or "unavailable" end
		end)
	end
	-- live stats + a new tip every 5 minutes
	task.spawn(function()
		local last = os.clock()
		while S.alive do
			if S.panelOpen and ui.tab == "Home" then
				regionStep()
				pcall(function()
					local n, max = #S.Players:GetPlayers(), S.Players.MaxPlayers
					vals["Players"].Text = n .. " / " .. max
					tw(bar, { Size = UDim2.new(math.clamp(n / math.max(max, 1), 0, 1), 0, 1, 0) }, 0.3)
					vals["Region"].Text = region
					local ok, ping = pcall(function() return S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
					vals["Latency"].Text = ok and (math.floor(ping) .. " ms") or "-"
					vals["Latency"].TextColor3 = not ok and col("text") or ping < 80 and Color3.fromRGB(52, 199, 89) or ping < 160 and Color3.fromRGB(255, 159, 10) or Color3.fromRGB(255, 69, 58)
					local t = math.floor(workspace.DistributedGameTime)
					vals["Uptime"].Text = ("%02d:%02d:%02d"):format(math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
					heroSub.Text = region .. "   ·   " .. n .. " players"
					 ctx.AV.srvStep()
					 local avT, avD, avN = ctx.AV.srvTotal()
					 heroVal.Text = ("Avatars  R$ %s  ·  %d/%d counted"):format(ctx.AV.comma(avT), avD, avN)
				end)
			end
			if os.clock() - last > 300 then
				last = os.clock()
				tip.Text = TIPS[math.random(#TIPS)]
				fit(HOME_MSGS[math.random(#HOME_MSGS)])
			end
			task.wait(1)
		end
	end)
end
-- [/PG_HOME]

-- [PG_PLAYERS]
-- ===== page: Players: search 299x32 at 9,10 + status text; cards 511 wide (80 tall, 64 for you) in a list with 6px gaps; group headers 20 tall =====
do
	local pg = pages["Players"]
	local sbox = input(pg, "Search for player…", 9, 10, 230, 32, 11)
	local stat = txt(pg, "", 9, "sub", L.IW - 176, 10, 167, 32, { TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })
	local plist = scroller(pg, 0, 56, L.IW, L.IH - 56)
	plist.AutomaticCanvasSize = Enum.AutomaticSize.None -- the height is known exactly, so the scroll position survives a rebuild
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, plist)
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }, plist)
	local friends = {} -- userId -> bool, filled in the background
	local rows = {} -- userId -> { ring, bars, lvl, fb, fr = card, grp = group } of the cards on screen
	local render
	local hdr, pollT = {}, 0 -- group -> LayoutOrder of its header (its cards follow at +1, +2...), seconds since the last re-sort

	-- sort A-Z / Z-A by display name, Nearest / Farthest by distance from you (unknown distance always last)
	local SORTS = { "A-Z", "Z-A", "Nearest", "Farthest" }
	local function sortList(list)
		local mode = cfg.plSort
		local byDist, d = mode == "Nearest" or mode == "Farthest", {}
		if byDist then
			local me = ctx.root()
			for _, p in ipairs(list) do
				local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				d[p] = (me and pr) and (me.Position - pr.Position).Magnitude or math.huge
				if mode == "Farthest" and d[p] ~= math.huge then d[p] = -d[p] end
			end
		end
		table.sort(list, function(a, b)
			local an, bn = a.DisplayName:lower(), b.DisplayName:lower()
			if byDist and d[a] ~= d[b] then return d[a] < d[b] end
			if mode == "Z-A" then return an > bn end
			return an < bn
		end)
	end
	-- Nearest / Farthest: move the cards that are already on screen instead of rebuilding them
	local function resort()
		local by = {}
		for uid, rw in pairs(rows) do
			local p = rw.grp and rw.fr and S.Players:GetPlayerByUserId(uid)
			if p then by[rw.grp] = by[rw.grp] or {}; table.insert(by[rw.grp], p) end
		end
		for key, list in pairs(by) do
			sortList(list)
			for i, p in ipairs(list) do rows[p.UserId].fr.LayoutOrder = (hdr[key] or 0) + i end
		end
	end
	local sortMenu
	local sortBtn = btn(pg, "Sort: " .. tostring(cfg.plSort), 246, 10, 104, 32, nil, nil, function() sortMenu.Visible = not sortMenu.Visible end)
	sortMenu = fr(pg, 246, 44, 104, #SORTS * 28 + 4, "ctrlOff", 0, 5, "edge", 1, 0.3)
	sortMenu.ZIndex, sortMenu.Visible = 20, false
	for i, v in ipairs(SORTS) do
		btn(sortMenu, v, 2, 2 + (i - 1) * 28, 100, 26, nil, nil, function()
			cfg.plSort, sortMenu.Visible = v, false
			sortBtn.Text = "Sort: " .. v
			save(); render()
		end)
	end

	-- a name you can double click: copies it, or (no clipboard) selects it so you can copy it by hand
	local clicks = {}
	local function copyable(parent, plain, rich, x, y, w, h, pt, key, props, single)
		local l = txt(parent, rich, pt, key, x, y, w, h, mix({ RichText = true, TextTruncate = Enum.TextTruncate.AtEnd }, props))
		local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = l.Position, Size = l.Size }, parent)
		local tb
		hit.MouseButton1Click:Connect(function()
			local now = os.clock()
			if clicks[hit] and now - clicks[hit] < 0.3 then
				clicks[hit] = nil
				if setclipboard then
					pcall(setclipboard, plain)
					ctx.notify("Copied " .. plain)
				else
					if not tb then
						tb = new("TextBox", { Text = plain, TextEditable = false, ClearTextOnFocus = false, BackgroundTransparency = 1, BorderSizePixel = 0,
							Font = FONT, TextSize = fs(pt), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
							Position = l.Position, Size = l.Size, Visible = false }, parent)
						paint(tb, "TextColor3", key)
						tb.FocusLost:Connect(function() tb.Visible = false; l.Visible = true end)
					end
					l.Visible, tb.Visible = false, true
					tb:CaptureFocus()
					tb.SelectionStart, tb.CursorPosition = 1, #plain + 1
				end
			else
				clicks[hit] = now
				if single then task.delay(0.3, function() if clicks[hit] == now then clicks[hit] = nil; single() end end) end -- one click = single(), a double click = copy
			end
		end)
		return l
	end
	local function greyOut(b, isFriend)
		if not (b and b.Parent) then return end
		b.Active = not isFriend
		b.Text = isFriend and "Friends" or "Add Friend"
		setFill(b) -- b.Active = false dims it (st())
	end

	-- friend status: fetched in the background, a card only moves when someone turns out to be (or stops being) a friend
	local fetching, sched = {}, false
	local function visible() return S.panelOpen and ui.tab == "Players" end
	local function later() -- one refresh for a burst of changes
		if sched then return end
		sched = true
		task.delay(0.15, function()
			sched = false
			if visible() then render() end
		end)
	end
	local function fetchFriends(force)
		for _, p in ipairs(S.Players:GetPlayers()) do
			local uid = p.UserId
			if p ~= lp and not fetching[uid] and (force or friends[uid] == nil) then
				fetching[uid] = true
				task.spawn(function()
					local ok, res = pcall(function() return lp:IsFriendsWith(uid) end)
					fetching[uid] = nil
					if not ok then return end -- throttled / failed: keep the last known answer (a friend used to drop out of Friends)
					local v = res == true
					local was = friends[uid] or false
					friends[uid] = v
					local row = rows[uid]
					if row and row.fb then greyOut(row.fb, v) end
					if was ~= v then later() end
				end)
			end
		end
	end
	local function blockedSet()
		local set = {}
		pcall(function()
			for _, id in ipairs(ctx.StarterGui:GetCore("GetBlockedUserIds")) do set[id] = true end
		end)
		return set
	end

	-- volume slider: 0 to 200 % in 5 % steps, snaps to 100 %, right click resets. One shared drag handler for every slider.
	local drag
	conn(S.UserInputService.InputChanged, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then drag(i.Position.X) end
	end)
	conn(S.UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = nil
			if S.dragEnd then pcall(S.dragEnd); S.dragEnd = nil end -- the volume slider's knob settles back when you let go
		end
	end)
	local function slider(parent, x, y, w, uid)
		local P = S.sliderParts(parent, x - 10, y - 3, w + 20, 10) -- the shared slider look; its track starts at x
		local pct = txt(parent, "", 9, "sub", x + w + 14, y, 38, 18, { TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center })
		local lastC = 0 -- double click = back to 100 %
		local function show(v)
			P.place(v / 2)
			pct.Text = math.floor(v * 100 + 0.5) .. "%"
		end
		local function set(px)
			local f = math.clamp((px - P.track.AbsolutePosition.X) / math.max(P.track.AbsoluteSize.X, 1), 0, 1)
			local v = math.floor(f * 40 + 0.5) / 20
			if math.abs(v - 1) < 0.04 then v = 1 end
			show(v)
			ctx.setVoiceVol(uid, v)
		end
		P.hit.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local now = os.clock()
				if now - lastC < 0.35 then lastC = 0; drag = nil; show(1); ctx.setVoiceVol(uid, 1); return end
				lastC = now
				drag = set
				S.dragEnd = function() P.held(false) end
				P.held(true)
				set(i.Position.X)
			end
		end)
		P.hit.MouseButton2Click:Connect(function() show(1); ctx.setVoiceVol(uid, 1) end)
		show(state.vcVol and state.vcVol[uid] or 1)
	end

	local CW, BW, BH, BG = L.IW - 21, 80, 26, 6 -- card width, button size and gap
	local BX = CW - 12 - (3 * BW + 2 * BG) -- left edge of the 3 x 2 button grid
	local TITLE = { accounts = "Accounts", listening = "Listening", friends = "Friends", players = "Players", hidden = "Blocked / Hidden" }
	local function header(key, count, order)
		local h = new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = order }, plist)
		fr(h, 2, 5, 3, 11, "accent", 0, 2)
		txt(h, (TITLE[key]):upper() .. "  ·  " .. count, 8, "sub", 12, 0, 400, 20, { Font = FONT_B, TextYAlignment = Enum.TextYAlignment.Center })
	end

	local function card(p, order, key, blocked, q)
		local uid, me = p.UserId, p == lp
		local h = me and 64 or 80
		local listening = state.listen[uid] ~= nil
		local r = fr(plist, 0, 0, CW, h, "row", 0.85, 8, "edge", 1, 0.55)
		r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, h), order
		if listening then paint(r:FindFirstChildOfClass("UIStroke"), "Color", "accent"); r:FindFirstChildOfClass("UIStroke").Transparency = 0.4 end
		S.lit(r)
		-- avatar; the ring around it is the voice activity indicator
		local a = new("ImageButton", { AutoButtonColor = false, Position = UDim2.fromOffset(12, (h - 52) / 2), Size = UDim2.fromOffset(52, 52), BorderSizePixel = 0, BackgroundTransparency = 0.9,
			Image = thumb("AvatarHeadShot", uid, 150), ImageTransparency = key == "hidden" and 0.5 or 0 }, r)
		paint(a, "BackgroundColor3", "row")
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
		local function open() ui.openProfile(p) end
		a.MouseButton1Click:Connect(open) -- the avatar (or one click on the name) opens the profile
		local ring = new("UIStroke", { Thickness = 1.5, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a)
		paint(ring, "Color", "accent")
		local ny = me and 14 or 12
		local tag = key == "hidden" and (blocked[uid] and "  ·  blocked" or "  ·  hidden") or (key == "accounts" and "  ·  alt" or "")
		copyable(r, p.DisplayName, hl(p.DisplayName, q) .. (me and " (you)" or ""), 76, ny, BX - 120, 16, 10, "text2", { Font = FONT_B }, open)
		copyable(r, p.Name, hl("@" .. p.Name, q) .. tag, 76, ny + 18, BX - 120, 13, 8, "sub", nil, open)
		-- level bars, bottom aligned next to the name
		local bars = {}
		for i = 1, 4 do
			local b = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(BX - 30 + (i - 1) * 5, ny + 15), Size = UDim2.fromOffset(3, 3),
				BorderSizePixel = 0, BackgroundTransparency = 0.7 }, r)
			paint(b, "BackgroundColor3", "accent")
			new("UICorner", { CornerRadius = UDim.new(0, 1) }, b)
			bars[i] = b
		end
		rows[uid] = { ring = ring, bars = bars, lvl = 0, fr = r, grp = key }
		if me then
			btn(r, "Respawn", BX + 2 * (BW + BG), (h - BH) / 2, BW, BH, "btnFill", BTN_OFF, function() ctx.Run("reset") end)
			return
		end
		local function cell(label, c, rw, on, cb)
			return btn(r, label, BX + c * (BW + BG), rw == 1 and 12 or 44, BW, BH, on and "ctrlOn" or nil, on and BTN_ON or nil, cb)
		end
		local viewing, muted, hidden = state.viewing == p, state.muted[uid] ~= nil, ctx.isHidden(uid)
		cell(viewing and "Unview" or "View", 0, 1, viewing, function()
			ctx.Run(viewing and "unview" or ("view " .. p.Name))
			render()
		end)
		cell("Go to", 1, 1, false, function() ctx.Run("goto " .. p.Name) end)
		local fb = cell("Add Friend", 2, 1, false, function() ctx.Run("friend " .. p.Name) end)
		rows[uid].fb = fb
		greyOut(fb, friends[uid])
		cell(muted and "Unmute" or "Mute", 0, 2, muted, function()
			ctx.setMuted(uid, not state.muted[uid])
			render()
		end)
		cell(listening and "Unlisten" or "Listen", 1, 2, listening, function()
			local on = not state.listen[uid]
			local wasMuted = on and state.muted[uid] ~= nil
			if wasMuted then ctx.setMuted(uid, false) end -- muted voice cannot be routed, so unmute first
			local ok, why = ctx.setListen(uid, on)
			if on and not ok then
				if wasMuted then ctx.setMuted(uid, true) end -- it failed: they stay muted, as the card still says
				return ctx.notify(why, 5)
			end
			render(on) -- listening pins the card to the top, so scroll up to it
		end)
		cell(hidden and "Unhide" or "Hide", 2, 2, hidden, function()
			ctx.Run((ctx.isHidden(uid) and "unhide " or "hide ") .. p.Name)
			render()
		end)
		slider(r, 76, 53, 160, uid)
	end

	-- an alt that is in another server: avatar, name, Join
	local function altRow(a, order)
		local r = fr(plist, 0, 0, CW, 56, "row", 0.85, 8, "edge", 1, 0.55)
		r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 56), order
		S.lit(r)
		local av = new("ImageLabel", { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(44, 44), BorderSizePixel = 0, BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", a.userId, 150) }, r)
		paint(av, "BackgroundColor3", "row")
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
		txt(r, (a.displayName and a.displayName ~= "") and a.displayName or a.name, 10, "text2", 68, 10, 220, 16, { Font = FONT_B })
		txt(r, "@" .. a.name .. "  ·  other server", 8, "sub", 68, 30, 240, 13)
		btn(r, "Join", BX + 2 * (BW + BG), 12, BW, BH, "primary", nil, function()
			pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(a.placeId, a.jobId, lp) end)
		end)
	end

	function render(toTop)
		S.plGen = (S.plGen or 0) + 1 -- a newer render cancels the cards an older one has not built yet
		local my, jobs = S.plGen, {}
		local keep = plist.CanvasPosition
		clear(plist)
		rows = {}
		local q = sbox.Text:lower()
		local blocked = blockedSet()
		local groups = { accounts = {}, listening = {}, friends = {}, players = {}, hidden = {} }
		local me
		for _, p in ipairs(S.Players:GetPlayers()) do
			if q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
				if p == lp then
					me = p
				else
					local uid = p.UserId
					local g = (state.alts and state.alts[uid]) and "accounts" or state.listen[uid] and "listening" or ((blocked[uid] or ctx.isHidden(uid)) and "hidden") or (friends[uid] and "friends") or "players"
					table.insert(groups[g], p)
				end
			end
		end
		for _, list in pairs(groups) do
			sortList(list)
		end
		local off = {} -- alts that are not in this server
		do
			local here = {}
			for _, p in ipairs(S.Players:GetPlayers()) do here[p.UserId] = true end
			for uid, a in pairs(state.alts or {}) do
				if not here[uid] and (q == "" or a.name:lower():find(q, 1, true) or (a.displayName or ""):lower():find(q, 1, true)) then off[#off + 1] = a end
			end
			table.sort(off, function(x, z) return x.name:lower() < z.name:lower() end)
		end
		local order, y, count = 0, 0, 0
		local function add(hh) y = y + (count > 0 and 6 or 0) + hh; count = count + 1 end
		if me then order = order + 1; add(64); local o = order; jobs[#jobs + 1] = function() card(me, o, nil, blocked, q) end end
		for _, key in ipairs({ "accounts", "listening", "friends", "players", "hidden" }) do
			local list = groups[key]
			local extra = key == "accounts" and off or {}
			if #list + #extra > 0 then
				order = order + 1; add(20); header(key, #list + #extra, order); hdr[key] = order
				for _, p in ipairs(list) do
					order = order + 1; add(80); local o = order; jobs[#jobs + 1] = function() card(p, o, key, blocked, q) end
				end
				for _, a in ipairs(extra) do
					order = order + 1; add(56); local o = order; jobs[#jobs + 1] = function() altRow(a, o) end
				end
			end
		end
		if count == 0 then
			empty(plist, "No players match.")
			y = 56
		end
		plist.CanvasSize = UDim2.fromOffset(0, y + 10)
		plist.CanvasPosition = toTop == true and Vector2.zero or keep
		ui.busy("players", false)
		if #jobs > 0 then -- the cards are built 3 per frame (a full server used to freeze the panel); a big list shows the loading pill meanwhile
			ui.busy("players", #jobs > 8, "Players")
			task.spawn(function()
				for i, job in ipairs(jobs) do
					if my ~= S.plGen or not S.alive then return end
					pcall(job)
					if i % 3 == 0 then task.wait() end
				end
				if my == S.plGen then ui.busy("players", false) end
			end)
		end
		local nl = 0
		for _ in pairs(state.listen) do nl = nl + 1 end
		stat.Text = ("%d players  ·  %d listening"):format(#S.Players:GetPlayers(), nl)
	end

	-- voice activity: the ring grows and the bars dance with the player's level (smoothed, fast attack, slow release)
	local EQ, wasVisible, altRev = { 0.75, 1, 0.9, 0.6 }, false, 0
	conn(ctx.RunService.Heartbeat, function(dt)
		if not visible() then
			if wasVisible then wasVisible = false; ctx.vcClear() end
			return
		end
		wasVisible = true
		if (state.altsRev or 0) ~= altRev then altRev = state.altsRev or 0; render() end -- the accounts list changed
		pollT = pollT + dt
		if (cfg.plSort == "Nearest" or cfg.plSort == "Farthest") and pollT >= (tonumber(cfg.plPoll) or 1) then
			pollT = 0
			resort()
		end
		local t = os.clock()
		for uid, rw in pairs(rows) do
			local m = ctx.vcMeter(uid)
			local target = 0
			if m then
				local ok, pk = pcall(function() return m.an.PeakLevel end)
				if ok and pk then target = math.clamp(math.sqrt(math.max(pk, 0)) * 1.8, 0, 1) end
			end
			if target < 0.08 then target = 0 end
			rw.lvl = target > rw.lvl and target or math.max(target, rw.lvl - dt * 2.2)
			rw.ring.Thickness = 1.5 + rw.lvl * 3.5
			rw.ring.Transparency = 0.55 - rw.lvl * 0.55
			for i, b in ipairs(rw.bars) do
				local f = math.clamp(rw.lvl * EQ[i] * (1 + 0.25 * math.sin(t * 14 + i * 1.7)), 0, 1)
				b.Size = UDim2.fromOffset(3, math.floor(3 + 11 * f))
				b.BackgroundTransparency = 0.7 - 0.7 * math.clamp(rw.lvl * 1.5, 0, 1)
			end
		end
	end)

	ui.plRender = function() if visible() then render() end end -- the profile refreshes the cards under it after an action
	ui.plSearch = function(q) sbox.Text = q or "" end -- ;player with several matches filters the list
	sbox:GetPropertyChangedSignal("Text"):Connect(function() render() end)
	onShow["Players"] = function() sortMenu.Visible = false; fetchFriends(true); render(true) end
	onHide["Players"] = function() S.plGen = (S.plGen or 0) + 1; ui.busy("players", false); clear(plist); rows = {}; ctx.vcClear() end
	conn(S.Players.PlayerAdded, function() if visible() then fetchFriends(); render() end end)
	conn(S.Players.PlayerRemoving, function(p)
		if state.viewing == p then ctx.Run("unview") end -- the camera comes back to you (it used to stay on the leaving player's body)
		task.defer(function() if visible() then render() end end)
	end)
end
-- ===== page: Servers: region filter + Scan regions + Join match, one 46px card per public server =====
do
	local pg = pages["Servers"]
	local SR = ctx.SRV
	local box = input(pg, "Region (city, country or code)…", 9, 10, 299, 32, 11)
	box.Text = cfg.srvRegion or ""
	
	local stat = txt(pg, "", 9, "sub", L.IW - 216, 46, 207, 26, { TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	local list = scroller(pg, 0, 80, L.IW, L.IH - 80)
	list.AutomaticCanvasSize = Enum.AutomaticSize.None
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }, list)
	local function ago(t) local m = math.floor((os.time() - t) / 60); return m < 1 and "just now" or m < 60 and (m .. " min ago") or (math.floor(m / 60) .. " h ago") end
	local servers, listErr, sched, scanBtn, menu = {}, nil, false, nil, nil
	local listBusy, known, ticking, rescanBtn, setStat, tick = false, 0, false, nil, nil, nil -- known = servers with a region; listBusy = the server list is being fetched
	local render
	local function visible() return S.panelOpen and ui.tab == "Servers" end
	local function later()
		if sched then return end
		sched = true
		task.delay(0.2, function() sched = false; if visible() then render() end end)
	end
	function render()
		clear(list)
		local q = box.Text:lower():match("^%s*(.-)%s*$")
		local rows = {}
		known = 0
		for _, s in ipairs(servers) do
			local r = SR.region(s.id)
			if r then known = known + 1 end
			if q == "" or (r and SR.match(s.id, q)) then rows[#rows + 1] = { s = s, r = r } end
		end
		local key, desc, now = cfg.srvSort, cfg.srvDesc, os.time()
		local function val(x) -- nil (unknown) always sorts last, whatever the direction
			if key == "Players" then return x.s.playing or 0 end
			if key == "Region" then return x.r and x.r.label end
			if key == "Age" then local e = SR.byId[x.s.id]; return e and e.t and now - e.t end
			return x.s.ping
		end
		table.sort(rows, function(a, b)
			local va, vb = val(a), val(b)
			if (va == nil) ~= (vb == nil) then return va ~= nil end
			if va ~= vb then if desc then return va > vb else return va < vb end end
			local pa, pb = a.s.ping or 9e9, b.s.ping or 9e9
			if pa ~= pb then return pa < pb end
			return a.s.id < b.s.id
		end)
		for i, row in ipairs(rows) do
			local s, r = row.s, row.r
			local c = fr(list, 0, 0, L.IW - 21, 50, "row", 0.85, 8, "edge", 1, 0.55)
			c.Size, c.LayoutOrder = UDim2.new(1, 0, 0, 50), i
			S.lit(c)
			local e = SR.byId[s.id]
			txt(c, r and (r.label .. (e and e.t and ("  ·  scanned " .. ago(e.t)) or "")) or "Not scanned yet", 10, r and "text2" or "sub", 14, 7, 330, 16, { Font = FONT_B })
			txt(c, ("%d/%d players  ·  %s  ·  %s"):format(s.playing or 0, s.maxPlayers or 0, s.ping and ("~" .. math.floor(s.ping * (cfg.mod.srvPingMult or 2) + 0.5) .. " ms") or "ping ?", s.fps and (math.floor(s.fps + 0.5) .. " fps") or "fps ?"),
				8, "sub", 14, 26, 330, 13)
			local cur = s.id == game.JobId
			local joining = SR.joining ~= nil and SR.joining.id == s.id
			local b = btn(c, cur and "Current" or (joining and "Cancel" or "Join"), L.IW - 21 - 12 - 82, 12, 82, 26, (not cur) and (joining and "danger" or "primary") or nil, nil, function()
				if SR.joining and SR.joining.id == s.id then SR.cancelJoin() else SR.join(game.PlaceId, s.id) end
			end)
			if cur then b.Active = false; b.TextTransparency = 0.55 end
		end
		if #rows == 0 then
			empty(list, listErr and ("Server list failed: " .. listErr) or (#servers == 0 and (listBusy and "Loading servers..." or "No public servers found.") or "No scanned server matches. Press Scan regions."))
		end
		list.CanvasSize = UDim2.fromOffset(0, math.max(#rows, 1) * 54 + 10)
		setStat()
		if SR.running() then tick() end -- a scan started by ;scanregions shows up too
	end
	-- status line: "refreshing list..." (Rescan) and/or "scanning regions N..." (Scan regions) in front of the counts while either one works
	function setStat()
		local busy = {}
		if listBusy then busy[#busy + 1] = "refreshing list" end
		if SR.running() then busy[#busy + 1] = "scanning regions " .. ((SR.okN or 0) + (SR.failN or 0)) end
		local head = #busy > 0 and (table.concat(busy, " + ") .. ("."):rep(math.floor(os.clock() * 2) % 3 + 1) .. "  ·  ") or ""
		local pl = 0
		for _, s in ipairs(servers) do pl = pl + (s.playing or 0) end
		stat.Text = head .. ("%d servers (%d players)  ·  %d regions"):format(#servers, pl, known) -- players listed: compare with the game's own count to see what is missing
		if rescanBtn then rescanBtn.TextTransparency = listBusy and 0.55 or 0 end
	end
	function tick() -- animates the dots until both are done
		if ticking then return end
		ticking = true
		task.spawn(function()
			ui.busy("servers", true, "Servers")
			while (listBusy or SR.running()) and S.alive do ui.busy("servers", true, "Servers"); setStat(); task.wait(0.4) end -- refreshed: the pill drops entries older than 20 s
			ui.busy("servers", false)
			ticking = false
			setStat()
		end)
	end
	-- the server list only: no join request, no IP lookup. Regions are Scan regions' job
	local function refresh(announce)
		if listBusy then return end
		listBusy = true; tick()
		task.spawn(function()
			local old = {}
			for _, s in ipairs(servers) do old[s.id] = true end
			local ok, l, err = pcall(SR.list, game.PlaceId, 1)
			if not ok then l, err = {}, tostring(l) end
			listBusy = false
			if #l > 0 then
				servers, listErr = l, nil
				if announce then
					local n = 0
					for _, s in ipairs(l) do if not old[s.id] then n = n + 1 end end
					ctx.notify(("Rescan: %d new server%s (%d total)"):format(n, n == 1 and "" or "s", #l), 4)
				end
			else
				listErr = err
				if announce then ctx.notify("Server list failed: " .. tostring(err), 5) end
			end
			if visible() then render() end
		end)
	end
	local function startScan()
		if #servers == 0 then return ctx.notify("No servers to scan yet") end
		scanBtn.Text = "Stop"
		local started = SR.scan(game.PlaceId, servers, function(chunk)
			if chunk then later() else
				scanBtn.Text = "Scan regions"
				if SR.err then ctx.notify(SR.err, 10) end
				later()
			end
		end)
		if started then tick() else scanBtn.Text = "Scan regions" end
	end
	scanBtn = btn(pg, "Scan regions", L.IW - 216, 13, 100, 26, nil, nil, function()
		if SR.running() then SR.stop = true; return end
		startScan()
	end)
	rescanBtn = btn(pg, "Rescan", 241, 46, 68, 26, nil, nil, function() refresh(true) end) -- new servers only: shown as "Not scanned yet" until Scan regions
	btn(pg, "Join match", L.IW - 110, 13, 100, 26, "primary", nil, function()
		local q = box.Text:lower():match("^%s*(.-)%s*$")
		if q == "" then return ctx.notify("Type a region first (city, country or code)") end
		ctx.Run("region " .. q)
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function() render() end)
	local SORTS = { "Ping", "Players", "Region", "Age" } -- Age = time since the region was scanned
	local sortBtn
	menu = fr(pg, 9, 74, 120, #SORTS * 28 + 4, "ctrlOff", 0, 5, "edge", 1, 0.3)
	menu.ZIndex, menu.Visible = 20, false
	for i, v in ipairs(SORTS) do
		btn(menu, v, 2, 2 + (i - 1) * 28, 116, 26, nil, nil, function()
			cfg.srvSort, menu.Visible = v, false
			sortBtn.Text = "Sort: " .. v .. "  v"
			save(); render()
		end)
	end
	sortBtn = btn(pg, "Sort: " .. tostring(cfg.srvSort) .. "  v", 9, 46, 120, 26, nil, nil, function() menu.Visible = not menu.Visible end)
	btn(pg, cfg.srvDesc and "Descending" or "Ascending", 135, 46, 100, 26, nil, nil, function(b)
		cfg.srvDesc = not cfg.srvDesc
		b.Text = cfg.srvDesc and "Descending" or "Ascending"
		save(); render()
	end)
	box.FocusLost:Connect(function() cfg.srvRegion = box.Text; save() end)
	SR.onJoin = later -- Join <-> Cancel redraws the rows
	onHide["Servers"] = function() clear(list) end
	onShow["Servers"] = function()
		menu.Visible = false
		if not SR.shown then SR.shown = true; ctx.notify("Region cache: " .. (SR.loaded or 0) .. " servers loaded from KLOSAD/servers.json", 4) end
		refresh(); render() -- refresh first (it only starts the fetch), so the empty list says Loading
	end
end
-- [/PG_PLAYERS]
-- [PROFILE]
-- ===== player profile: ONE window over the page area, reused (never two). Opens from a Players card (avatar, or one click on the name), a friend tile or ;player <name>.
-- Every open bumps P.gen: late answers (friends with you, friends list, outfit prices) for an older profile are dropped and its live refresh stops. Leaving Players closes it =====
do
	local W, H = L.IW, L.IH
	local LX, LW, RX, TOPY = 16, 180, 212, 44 -- left column (avatar + actions), the right column's x, top of the content
	local RW = W - RX - 16
	local P = { gen = 0, open = false, friend = {}, price = ctx.AV.asset } -- the same cache Home's server total fills
	ui.prof = P
	local joined = {} -- userId -> os.time() they joined (players already here when rOSAD started are unknown)
	conn(S.Players.PlayerAdded, function(p) joined[p.UserId] = os.time() end)
	local function prop(o, k) local ok, v = pcall(function() return o[k] end); return ok and v or nil end
	local function comma(n) local s = tostring(math.floor((tonumber(n) or 0) + 0.5)); return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
	local function date(f, t) local ok, s = pcall(os.date, f, t); return ok and type(s) == "string" and s or "?" end -- an executor with a cut down os.date never breaks the profile
	local function blockedIds()
		local ok, ids = pcall(function() return ctx.StarterGui:GetCore("GetBlockedUserIds") end)
		return ok and type(ids) == "table" and ids or {}
	end
	local function copy(text, what)
		if not setclipboard then return ctx.notify("This executor cannot copy: " .. text, 6) end
		pcall(setclipboard, text)
		ctx.notify("Copied " .. what)
	end
	local function chip(parent, text, key, order)
		local c = new("TextLabel", { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 20), BorderSizePixel = 0, BackgroundTransparency = 0.82,
			Text = text, Font = FONT_B, TextSize = fs(8), LayoutOrder = order }, parent)
		paint(c, "BackgroundColor3", key)
		paint(c, "TextColor3", key == "accent" and "accentText" or key == "sub" and "text2" or key)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
		new("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9) }, c)
	end

	-- the profile is its own window: `win` is a full screen fade group (like the panel's), `frame` is the window in the main panel's style, dragged by its header
	local WW, WH, HD = W + 24, H + 56, 44
	local win = new("CanvasGroup", { Name = "Profile", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 5 }, gui)
	local frame = new("Frame", { Name = "ProfileWindow", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(WW, WH), BorderSizePixel = 0, Active = true }, win)
	paint(frame, "BackgroundColor3", "panel")
	frame.BackgroundTransparency = 1 - cfg.opacity
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, frame)
	local pst = new("UIStroke", { Thickness = 1.5, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
	paint(pst, "Color", "accent")
	local pgr = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.88), NumberSequenceKeypoint.new(0.7, 0.88), NumberSequenceKeypoint.new(1, 0) }) }, pst)
	S.deco(pgr)
	P.comet = S.TweenService:Create(pgr, TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Rotation = 360 }) -- only runs while the window is open
	ui.profWin, ui.profScale = frame, new("UIScale", { Scale = cfg.scale }, frame)
	S.spot(frame, WW, WH, 12, 1, frame, function() return P.open and not S.barOpen end) -- cursor light, under everything else in the window
	fr(frame, 14, 0, WW - 28, 2, "accent", 0.7)
	local ttl = txt(frame, "", 14, "text", 22, 9, 200, 26, { Font = FONT_CODE, RichText = true, TextSize = 21 })
	S.deco(new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(165, 165, 178)) }, ttl))
	function P.retitle() ttl.Text = '<font color="' .. hex(S.accent) .. '">&gt;</font>PROFILE' end
	P.retitle()
	do -- hairline under the header, fading out at both ends
		local hd = fr(frame, 14, HD - 1, WW - 28, 1, "accent", 0.8)
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, hd)
		S.deco(hd)
	end
	btn(frame, "×", WW - 46, 8, 34, 28, "ghost", nil, function() ui.closeProfile() end, 13)
	-- position is kept as a fraction of the screen, like the panel's
	P.pos = Vector2.new(0.5, 0.5)
	function P.place(extraY, animate)
		local vp = workspace.CurrentCamera.ViewportSize
		local pos = UDim2.fromScale(P.pos.X, P.pos.Y + (extraY or 0) / vp.Y)
		if animate then tw(frame, { Position = pos }, 0.3) else frame.Position = pos end
	end
	do
		local header = new("Frame", { Size = UDim2.fromOffset(WW - 50, HD - 6), BackgroundTransparency = 1 }, frame)
		local drag, d0, p0
		header.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, d0, p0 = true, i.Position, P.pos end
		end)
		conn(S.UserInputService.InputChanged, function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local vp = workspace.CurrentCamera.ViewportSize
				local d = i.Position - d0
				P.pos = Vector2.new(p0.X + d.X / vp.X, p0.Y + d.Y / vp.Y)
				P.place(0)
			end
		end)
		conn(S.UserInputService.InputEnded, function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then drag = false end
		end)
	end
	-- content area: the same dark veil as the panel's inner area; everything build() makes goes in here
	P.inner = fr(frame, 12, HD, W, H, "glass", 0.75, 10, "edge", 1, 0.7)
	P.inner.ClipsDescendants = true
	-- dark layer over the window while the command bar is open (same as the panel)
	local shade = fr(frame, 0, 0, WW, WH, "tabOff", 0.45, 9)
	shade.ZIndex, shade.Active, shade.Visible = 50, true, false
	conn(S.RunService.Heartbeat, function()
		local v = P.open == true and S.barOpen == true
		if shade.Visible ~= v then shade.Visible = v end
	end)
	function P.show() -- a fresh open: slides up while it fades in
		P.retitle()
		if not P.placed then
			P.placed = true
			P.pos = Vector2.new(math.clamp(ui.panelPos.X + 0.04, 0.2, 0.8), math.clamp(ui.panelPos.Y + 0.03, 0.2, 0.8))
		end
		ui.profScale.Scale = ui.curScale()
		S.profOpen = true
		P.place(18, false)
		tw(win, { GroupTransparency = 0 }, 0.16)
		P.place(0, true)
		if cfg.anim ~= 0 then P.comet:Play() end
		ui.syncMouse()
	end
	function P.hideHook()
		S.profOpen = false
		pcall(function() P.comet:Pause() end)
		ui.syncMouse()
	end
	-- (the window's own fill is on `frame`)
	-- (see frame)
	-- (corners are on frame)
	local body = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, P.inner) -- its own group so switching profiles cross-fades it
	-- (the title is in the window header)
	-- (the close button is in the window header)

	local function build(p, my)
		clear(body)
		local uid, me = p.UserId, p == lp
		local function live() return my == P.gen and P.open and S.alive end
		local function here() return p.Parent ~= nil end
		local loaders = {}

		-- left: the full avatar (the actions go under it)
		local at = fr(body, LX, TOPY, LW, LW, "row", 0.85, ST.rPane)
		new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = thumb("Avatar", uid, 420), ScaleType = Enum.ScaleType.Fit }, at)

		-- right: headshot, names, state chips, section switcher, the section
		local hs = new("ImageLabel", { Position = UDim2.fromOffset(RX, TOPY), Size = UDim2.fromOffset(52, 52), BorderSizePixel = 0, BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", uid, 150) }, body)
		paint(hs, "BackgroundColor3", "row")
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, hs)
		paint(new("UIStroke", { Thickness = 1.5, Transparency = 0.4 }, hs), "Color", "accent")
		txt(body, p.DisplayName, 15, "text", RX + 66, TOPY + 2, RW - 66, 24, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
		txt(body, "@" .. p.Name, 10, "sub", RX + 66, TOPY + 28, RW - 66, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
		local chips = new("Frame", { Position = UDim2.fromOffset(RX, TOPY + 62), Size = UDim2.fromOffset(RW, 20), BackgroundTransparency = 1 }, body)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
		local PY = TOPY + 126
		local PH = H - PY - 14
		local panes, sw = {}, {}
		local function showPane(name)
			for n, f in pairs(panes) do f.Visible = n == name end
			for n, b in pairs(sw) do setFill(b, n == name and "ctrlOn" or "ctrlOff", BTN_OFF) end
			local f = loaders[name]
			if f then loaders[name] = nil; task.spawn(f) end -- a section loads the first time you open it
		end
		for i, n in ipairs({ "Overview", "Outfit", "Friends" }) do
			sw[n] = btn(body, n, RX + (i - 1) * 96, TOPY + 92, 90, 26, "ctrlOff", BTN_OFF, function() showPane(n) end)
			panes[n] = new("Frame", { Position = UDim2.fromOffset(RX, PY), Size = UDim2.fromOffset(RW, PH), BackgroundTransparency = 1, Visible = false }, body)
		end

		-- Overview: label / value rows
		local val, nrow = {}, 0
		local function kv(k, v)
			local y = nrow * 21
			nrow = nrow + 1
			txt(panes.Overview, k, 9.5, "sub", 0, y, 128, 21, { TextYAlignment = Enum.TextYAlignment.Center })
			val[k] = txt(panes.Overview, v, 9.5, "text", 128, y, RW - 128, 21, { TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
		end
		local age = tonumber(prop(p, "AccountAge")) or 0
		local fid = tonumber(prop(p, "FollowUserId")) or 0
		local fpl = fid ~= 0 and S.Players:GetPlayerByUserId(fid)
		local jt = joined[uid]
		kv("User ID", tostring(uid))
		kv("Account age", ("%s days  ·  on Roblox since %s"):format(comma(age), date("%b %Y", os.time() - age * 86400)))
		kv("Membership", prop(p, "MembershipType") == Enum.MembershipType.Premium and "Premium" or "Standard")
		kv("Verified badge", prop(p, "HasVerifiedBadge") and "Yes" or "No")
		 kv("Avatar value", "checking...")
		kv("Friends with you", me and "-" or "checking...")
		kv("Team", "None")
		kv("Distance", "-")
		kv("In this server", me and "you" or jt and ("since " .. date("%H:%M", jt)) or "since before rOSAD started")
		kv("Followed someone in", fid == 0 and "No" or fpl and ("@" .. fpl.Name) or ("user " .. fid))
		 task.spawn(function() -- worn items priced (shared cache with the Outfit tab and Home's server total)
			 local ok, r = pcall(ctx.AV.value, p, true)
			 if not live() then return end
			 if not (ok and r) then val["Avatar value"].Text = "unavailable (outfit not loaded)"; return end
			 val["Avatar value"].Text = ("R$ %s  ·  %d of %d priced%s%s"):format(ctx.AV.comma(r.total), r.priced, r.n, (r.lim > 0 and ("  ·  %d limited at RAP"):format(r.lim) or "") .. (r.other > 0 and ("  ·  %d off sale / no price"):format(r.other) or ""), r.miss > 0 and ("  ·  %d unknown"):format(r.miss) or "")
		 end)
		if not me then
			task.spawn(function()
				local ok, v = pcall(function() return lp:IsFriendsWith(uid) end)
				if ok then P.friend[uid] = v == true end
				if live() then val["Friends with you"].Text = ok and (v and "Yes" or "No") or "unknown (Roblox did not answer)" end
			end)
		end

		-- Outfit: what they wear, with catalog prices (MarketplaceService, cached per asset for the session)
		local osum = txt(panes.Outfit, "Loading the outfit...", 9.5, "sub", 0, 0, RW, 20, { TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
		local olist = scroller(panes.Outfit, 0, 24, RW, PH - 24)
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, olist)
		new("UIPadding", { PaddingRight = UDim.new(0, 8) }, olist)
		loaders.Outfit = function()
			local ids, seen = {}, {}
			local function addId(id) id = tonumber(id); if id and id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end end
			local ok, desc = pcall(function()
				local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h then return h:GetAppliedDescription() end -- what they wear in this server
				return S.Players:GetHumanoidDescriptionFromUserId(uid)
			end)
			if ok and desc then
				pcall(function() for _, a in ipairs(desc:GetAccessories(true)) do addId(a.AssetId) end end)
				for _, k in ipairs({ "Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg" }) do pcall(function() addId(desc[k]) end) end
			end
			if #ids == 0 and request then -- no description: the avatar API's "currently wearing" list (their saved avatar, may differ from this game)
				pcall(function()
					local r = request({ Url = ("https://avatar.roblox.com/v1/users/%d/currently-wearing"):format(uid), Method = "GET" })
					for _, id in ipairs(S.HttpService:JSONDecode(r.Body).assetIds or {}) do addId(id) end
				end)
			end
			if not live() then return end
			if #ids == 0 then osum.Text = "Outfit unavailable: Roblox returned no worn items"; return end
			local total, priced, other = 0, 0, 0
			local function sum()
				osum.Text = ("Est. value R$ %s  ·  %d of %d items priced%s"):format(comma(total), priced, #ids, other > 0 and ("  ·  %d off sale / limited"):format(other) or "")
			end
			for i, id in ipairs(ids) do
				local row = fr(olist, 0, 0, RW - 8, 40, "row", 0.85, ST.rCtrl)
				row.Size, row.LayoutOrder = UDim2.new(1, 0, 0, 40), i
				new("ImageLabel", { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Image = thumb("Asset", id, 150) }, row)
				local nm = txt(row, "Item " .. id, 9.5, "text", 46, 4, RW - 160, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
				local by = txt(row, "", 8, "sub", 46, 21, RW - 160, 14, { TextTruncate = Enum.TextTruncate.AtEnd })
				local pr = txt(row, "...", 9.5, "text2", RW - 110, 0, 94, 40, { Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })
				task.spawn(function()
					local info = P.price[id]
					if not info then
						local okI, res = pcall(function() return S.MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
						if okI and type(res) == "table" then info = res; P.price[id] = res end
					end
					if not live() then return end
					if not info then pr.Text = "unavailable"; other = other + 1; sum(); return end
					nm.Text = tostring(info.Name or ("Item " .. id))
					by.Text = (type(info.Creator) == "table" and info.Creator.Name) and ("by " .. tostring(info.Creator.Name)) or ""
					local cd = info.CollectiblesItemDetails
					local limited = info.IsLimited or info.IsLimitedUnique or (type(cd) == "table" and cd.IsLimited)
					local price = tonumber(info.PriceInRobux)
					if limited then
						local v = ctx.AV.limitedPrice(id, info) -- RAP / lowest resale price
						if v then pr.Text = "R$ " .. comma(v) .. " (RAP)"; total = total + v; priced = priced + 1
						else pr.Text = "Limited"; other = other + 1 end
					elseif info.IsForSale and price and price > 0 then pr.Text = "R$ " .. comma(price); total = total + price; priced = priced + 1
					elseif info.IsForSale then pr.Text = "Free"; priced = priced + 1
					else pr.Text = "Off sale"; other = other + 1 end
					sum()
				end)
			end
			sum()
		end

		-- Friends: the first page of their friends list (Players:GetFriendsAsync), the ones in this server first, then online
		local fsum = txt(panes.Friends, "Loading friends...", 9.5, "sub", 0, 0, RW, 20, { TextYAlignment = Enum.TextYAlignment.Center })
		local fl = scroller(panes.Friends, 0, 24, RW, PH - 24)
		new("UIGridLayout", { CellSize = UDim2.fromOffset(66, 80), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, fl)
		loaders.Friends = function()
			local ok, items, more = pcall(function()
				local pg = S.Players:GetFriendsAsync(uid)
				return pg:GetCurrentPage(), not pg.IsFinished
			end)
			if not live() then return end
			if not ok or type(items) ~= "table" then fsum.Text = "Friends list unavailable (Roblox refused or it is private)"; return end
			local function inS(f) return S.Players:GetPlayerByUserId(f.Id) ~= nil end
			table.sort(items, function(a, b)
				if inS(a) ~= inS(b) then return inS(a) end
				if (a.IsOnline == true) ~= (b.IsOnline == true) then return a.IsOnline == true end
				return tostring(a.Username):lower() < tostring(b.Username):lower()
			end)
			local nHere = 0
			for i, f in ipairs(items) do
				local hereF = inS(f)
				if hereF then nHere = nHere + 1 end
				local t = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, LayoutOrder = i }, fl)
				local av = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(46, 46), BorderSizePixel = 0,
					BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", f.Id, 150), Interactable = false }, t)
				paint(av, "BackgroundColor3", "row")
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
				paint(new("UIStroke", { Thickness = hereF and 2 or 1, Transparency = hereF and 0 or 0.7 }, av), "Color", hereF and "accent" or "edge")
				local dn = (f.DisplayName and f.DisplayName ~= "") and f.DisplayName or f.Username
				txt(t, tostring(dn), 8, hereF and "accentText" or "text2", 0, 54, 66, 13, { TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Interactable = false })
				txt(t, hereF and "here" or (f.IsOnline and "online" or ""), 7, "hint", 0, 67, 66, 11, { TextXAlignment = Enum.TextXAlignment.Center, Interactable = false })
				t.MouseButton1Click:Connect(function()
					local pl = S.Players:GetPlayerByUserId(f.Id)
					if pl then return ui.openProfile(pl) end
					copy("https://www.roblox.com/users/" .. f.Id .. "/profile", "@" .. tostring(f.Username) .. "'s profile link (not in this server)")
				end)
			end
			fsum.Text = ("%d%s friends  ·  %d in this server"):format(#items, more and "+" or "", nHere)
		end

		-- actions, two columns under the avatar. on() = selected look, en() = extra condition; any = also works for you / a player who left
		local function run(cmd) ctx.Run(cmd .. " " .. p.Name) end
		local A = {
			{ label = function() return state.viewing == p and "Unview" or "View" end, on = function() return state.viewing == p end,
				run = function() if state.viewing == p then ctx.Run("unview") else run("view") end end },
			{ label = function() return state.listen[uid] and "Unlisten" or "Listen" end, on = function() return state.listen[uid] ~= nil end,
				run = function()
					local on = not state.listen[uid]
					local wasMuted = on and state.muted[uid] ~= nil
					if wasMuted then ctx.setMuted(uid, false) end
					local ok, why = ctx.setListen(uid, on)
					if on and not ok then
						if wasMuted then ctx.setMuted(uid, true) end
						ctx.notify(why, 5)
					end
				end },
			{ label = function() return "Go to" end, run = function() run("goto") end },
			{ label = function() return P.friend[uid] and "Friends" or "Add friend" end, en = function() return not P.friend[uid] end, run = function() run("friend") end },
			{ label = function() return state.muted[uid] and "Unmute" or "Mute" end, on = function() return state.muted[uid] ~= nil end,
				run = function() ctx.setMuted(uid, not state.muted[uid]) end },
			{ label = function() return ctx.isHidden(uid) and "Unhide" or "Hide" end, on = function() return ctx.isHidden(uid) end,
				run = function() run(ctx.isHidden(uid) and "unhide" or "hide") end },
			{ label = function() return table.find(blockedIds(), uid) and "Unblock" or "Block" end, key = "danger",
				run = function() run(table.find(blockedIds(), uid) and "unblock" or "block") end },
			{ label = function() return "Inspect" end, any = true,
				run = function() if not pcall(function() S.GuiService:InspectPlayerFromUserId(uid) end) then ctx.notify("This experience has the avatar inspect menu turned off") end end },
			{ label = function() return "Copy ID" end, any = true, run = function() copy(tostring(uid), "the user ID") end },
			{ label = function() return "Copy link" end, any = true, run = function() copy("https://www.roblox.com/users/" .. uid .. "/profile", "the profile link") end },
		}
		for i, a in ipairs(A) do
			a.k = a.key
			a.b = btn(body, a.label(), LX + ((i - 1) % 2) * 93, TOPY + LW + 12 + math.floor((i - 1) / 2) * 32, 87, 26, a.key, nil, function()
				a.run()
				task.delay(0.1, function()
					if live() then P.refresh() end
					if ui.plRender then ui.plRender() end
				end)
			end)
		end

		-- live state: buttons, chips, distance, team (every 0.5 s while this profile is open)
		local sig
		function P.refresh()
			if not live() then return end
			local can = here() and not me
			for _, a in ipairs(A) do
				a.b.Text = a.label()
				local k = (a.on and a.on()) and "ctrlOn" or a.key
				if k ~= a.k then a.k = k; setFill(a.b, k) end
				local en = (a.any or can) and (not a.en or a.en())
				if a.b.Active ~= en then a.b.Active = en end
			end
			local list = {}
			local function add(t, k) list[#list + 1] = { t, k } end
			if me then add("You", "accent") end
			if state.alts and state.alts[uid] then add("Your alt", "accent") end
			if P.friend[uid] then add("Friend", "accent") end
			if prop(p, "HasVerifiedBadge") then add("Verified", "info") end
			if prop(p, "MembershipType") == Enum.MembershipType.Premium then add("Premium", "sub") end
			if state.viewing == p then add("Viewing", "accent") end
			if state.listen[uid] then add("Listening", "accent") end
			if state.muted[uid] then add("Muted", "danger") end
			if ctx.isHidden(uid) then add("Hidden", "danger") end
			if table.find(blockedIds(), uid) then add("Blocked", "danger") end
			if not here() then add("Left the server", "danger") end
			local s = ""
			for _, c in ipairs(list) do s = s .. c[1] .. "|" end
			if s ~= sig then
				sig = s
				clear(chips)
				for i, c in ipairs(list) do chip(chips, c[1], c[2], i) end
			end
			local mine, r = ctx.root(), p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			val.Distance.Text = me and "-" or not here() and "left the server" or (mine and r) and (comma((mine.Position - r.Position).Magnitude) .. " studs") or "not loaded (outside your streaming range)"
			val.Team.Text = p.Team and p.Team.Name or "None"
		end
		showPane("Overview")
		P.refresh()
		task.spawn(function()
			while live() do
				task.wait(0.5)
				P.refresh()
			end
		end)
	end

	function ui.openProfile(p)
		if typeof(p) ~= "Instance" or not p.Parent then return ctx.notify("That player is not in this server") end
		-- the profile is its own window: it no longer switches tab or opens the panel
		if P.open and P.p == p then return end -- already showing them
		local switching = P.open
		P.gen, P.p, P.open = P.gen + 1, p, true
		build(p, P.gen)
		win.Visible = true
		if switching then
			body.GroupTransparency = 1
			tw(body, { GroupTransparency = 0 }, 0.16)
		else
			body.GroupTransparency = 0
			P.show()
		end
	end
	function ui.closeProfile(instant)
		if not P.open then return end
		P.open, P.gen = false, P.gen + 1; P.hideHook()
		if instant or cfg.anim == 0 then win.Visible, win.GroupTransparency = false, 1; return end
		tw(win, { GroupTransparency = 1 }, 0.16)
		task.delay(dur(0.16) + 0.02, function() if not P.open then win.Visible = false end end) -- reopened meanwhile = stays
	end
	-- leaving Players closes the profile at once; clicking Players again while it is open goes back to the list
	local select0 = ui.selectTab
	function ui.selectTab(name)
		-- the profile window stays open while you change tab
		S.syncSwitches() -- switches show the real value when you come back to a page
		return select0(name)
	end
end
-- [/PROFILE]

-- [PG_LOOK]
-- ===== page: Look and feel (slide 7, every control at the deck's position) ============================
do
	local pg = scroller(pages["Look and feel"], 0, 0, L.IW, L.IH)
	pg.AutomaticCanvasSize, pg.CanvasSize = Enum.AutomaticSize.None, UDim2.fromOffset(0, 462) -- fixed height so the last row is never cut off
	local X0 = L.IW - 252 -- left edge of the control column, its right edge sits 20 px from the page edge
	local function label(str, x, y) txt(pg, str, 12, "text", x, y, X0 - x - 10, 19) end
	local function cols(n, step) local t = {} for i = 1, n do t[i] = X0 + (i - 1) * step end return t end
	txt(pg, "Main", 14, "text", 21, 14, 214, 23, { Font = FONT_B })
	label("Default theme", 33, 50)
	seg(pg, 48, { X0, X0 + 116 }, 108, { { "Dark Mode", "Dark" }, { "Light Mode", "Light" } }, "theme")
	label("UI Opacity", 33, 88)
	seg(pg, 86, cols(4, 60), 52, { { "20%", 0.2 }, { "50%", 0.5 }, { "80%", 0.8 }, { "100%", 1 } }, "opacity")
	label("Glow Opacity", 33, 126)
	seg(pg, 124, cols(4, 60), 52, { { "0%", 0 }, { "25%", 25 }, { "50%", 50 }, { "75%", 75 }, { "100%", 100 } }, "glow")
	label("Accent Color", 33, 164)
	local swatch = fr(pg, X0 + 37, 162, 30, 25, "accent", 0, 3, "edge", 1)
	local hexBox = input(pg, "#FFFF00", X0 + 74, 162, 104, 25, 9, "ctrlOff", BTN_OFF, { Text = cfg.accent, TextXAlignment = Enum.TextXAlignment.Center })
	local picker -- HSL picker, built on first click (see below)
	hexBox.FocusLost:Connect(function()
		local t = hexBox.Text:upper()
		if parseHex(t) then cfg.accent = t; save(); ui.apply() end
		hexBox.Text = cfg.accent
		if picker then picker.load() end
	end)
	-- HSL picker: click the swatch. Three sliders (hue 0-360, saturation, lightness 0-100) with live gradients; applies while you drag, saves on release
	local function toColor(h, sat, lig)
		local c = (1 - math.abs(2 * lig - 1)) * sat
		local x = c * (1 - math.abs((h / 60) % 2 - 1))
		local m, i = lig - c / 2, math.floor(h / 60) % 6
		local r, g, b = c, 0, x
		if i == 0 then r, g, b = c, x, 0 elseif i == 1 then r, g, b = x, c, 0 elseif i == 2 then r, g, b = 0, c, x elseif i == 3 then r, g, b = 0, x, c elseif i == 4 then r, g, b = x, 0, c end
		return Color3.new(r + m, g + m, b + m)
	end
	local function toHsl(c)
		local mx, mn = math.max(c.R, c.G, c.B), math.min(c.R, c.G, c.B)
		local l, d = (mx + mn) / 2, mx - mn
		if d < 1e-6 then return 0, 0, l end
		local sat = d / (1 - math.abs(2 * l - 1))
		local h = mx == c.R and ((c.G - c.B) / d) % 6 or mx == c.G and (c.B - c.R) / d + 2 or (c.R - c.G) / d + 4
		return h * 60, sat, l
	end
	swatch.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if picker then picker.frame.Visible = not picker.frame.Visible; if picker.frame.Visible then picker.load() end; return end
		local H, Sa, Li = 0, 1, 0.5
		local f = fr(pg, X0 - 22, 193, 242, 124, "panel", 0, 10, "edge", 1, 0.3)
		f.ZIndex, f.Active = 50, true -- Active: clicks inside the picker never reach the controls under it
		picker = { frame = f }
		local tracks, last = {}, 0
		local function push(final)
			cfg.accent = hex(toColor(H, Sa, Li))
			hexBox.Text = cfg.accent
			if final then save(); ui.apply() elseif os.clock() - last > 0.06 then last = os.clock(); ui.apply() end
		end
		local function paintTracks()
			local hs = {}
			for k = 0, 6 do hs[#hs + 1] = ColorSequenceKeypoint.new(k / 6, toColor(k * 60, 1, 0.5)) end
			tracks[1].grad.Color = ColorSequence.new(hs)
			tracks[2].grad.Color = ColorSequence.new(toColor(H, 0, Li), toColor(H, 1, Li))
			tracks[3].grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, toColor(H, Sa, 0)), ColorSequenceKeypoint.new(0.5, toColor(H, Sa, 0.5)), ColorSequenceKeypoint.new(1, toColor(H, Sa, 1)) })
			tracks[1].set(H / 360); tracks[2].set(Sa); tracks[3].set(Li)
		end
		for k, def in ipairs({ { "H", 360 }, { "S", 100 }, { "L", 100 } }) do
			local y = 14 + (k - 1) * 36
			txt(f, def[1], 10, "sub", 14, y - 1, 14, 18, { Font = FONT_B })
			local val = txt(f, "", 9, "dim", 190, y - 1, 40, 18, { TextXAlignment = Enum.TextXAlignment.Right })
			local track = new("Frame", { Position = UDim2.fromOffset(34, y + 2), Size = UDim2.fromOffset(150, 12), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, f)
			new("UICorner", { CornerRadius = UDim.new(0, 6) }, track)
			local grad = new("UIGradient", {}, track)
			local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(6, 18), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1) }, track)
			new("UICorner", { CornerRadius = UDim.new(0, 3) }, knob)
			new("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.4 }, knob)
			local T = { grad = grad }
			function T.set(v) knob.Position = UDim2.new(v, 0, 0.5, 0); val.Text = k == 1 and (math.floor(v * 360 + 0.5) .. "°") or (math.floor(v * 100 + 0.5) .. "%") end
			local drag = false
			local function move(x)
				local v = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
				if k == 1 then H = v * 360 elseif k == 2 then Sa = v else Li = v end
				paintTracks(); push(false)
			end
			track.InputBegan:Connect(function(i2)
				if i2.UserInputType == Enum.UserInputType.MouseButton1 or i2.UserInputType == Enum.UserInputType.Touch then drag = true; move(i2.Position.X) end
			end)
			conn(S.UserInputService.InputChanged, function(i2)
				if drag and (i2.UserInputType == Enum.UserInputType.MouseMovement or i2.UserInputType == Enum.UserInputType.Touch) then move(i2.Position.X) end
			end)
			conn(S.UserInputService.InputEnded, function(i2)
				if drag and (i2.UserInputType == Enum.UserInputType.MouseButton1 or i2.UserInputType == Enum.UserInputType.Touch) then drag = false; push(true) end
			end)
			tracks[k] = T
		end
		function picker.load() H, Sa, Li = toHsl(parseHex(cfg.accent) or S.accent); paintTracks() end
		picker.load()
		-- a click outside the picker (and not on the swatch) closes it
		conn(S.UserInputService.InputBegan, function(i2)
			if i2.UserInputType ~= Enum.UserInputType.MouseButton1 or not f.Visible then return end
			local m = S.UserInputService:GetMouseLocation()
			local function inside(o) local p, z = o.AbsolutePosition, o.AbsoluteSize; return m.X >= p.X and m.X <= p.X + z.X and m.Y >= p.Y and m.Y <= p.Y + z.Y end
			if not inside(f) and not inside(swatch) then f.Visible = false end
		end)
	end)
	onHide["Look and feel"] = function() if picker then picker.frame.Visible = false end end
	label("Animation Speed", 33, 202)
	seg(pg, 200, cols(4, 60), 52, { { "0.5x", 0.5 }, { "1.0x", 1 }, { "2.0x", 2 }, { "none", 0 } }, "anim")
	label("UI Scaling", 33, 240)
	seg(pg, 238, cols(4, 60), 52, { { "70%", 0.7 }, { "80%", 0.8 }, { "90%", 0.9 }, { "100%", 1 }, { "110%", 1.1 }, { "120%", 1.2 }, { "130%", 1.3 }, { "140%", 1.4 } }, "scale")
	fr(pg, 17, 272, L.IW - 34, 1, "edge", 0.6) -- divider between the two groups
	txt(pg, "Command Bar", 14, "text", 21, 288, 214, 23, { Font = FONT_B })
	label("Max suggestion lines", 33, 326)
	seg(pg, 324, cols(3, 80), 72, { { "6", 6 }, { "12", 12 }, { "20", 20 } }, "lines")
	label("Blur Size", 33, 364)
	seg(pg, 362, cols(4, 60), 52, { { "0x", 0 }, { "0.5x", 0.5 }, { "1.0x", 1 }, { "1.5x", 1.5 } }, "blur")
	label("Position", 33, 402)
	seg(pg, 400, cols(3, 80), 72, { { "Bottom", "Bottom" }, { "Center", "Center" }, { "Top", "Top" } }, "pos")
end
-- [/PG_LOOK]

-- [PG_SCRIPTS]
-- ===== page: Load scripts (slide 8: rows 76px flush, 11pt title, 8pt description, 94x23 button) ===========
do
	local pg = pages["Load scripts"]
	local sbox = input(pg, "Search scripts…", 9, 10, 299, 32, 11)
	local list = scroller(pg, 0, 56, L.IW, L.IH - 56)
	new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local function ghInfo(url)
		local ru, rr = url:match("github%.com/([^/]+)/([^/]+)/releases/latest/")
		if ru then return ru .. "/" .. rr .. " @ latest release (unpinned)" end
		local tu, tr, tag = url:match("github%.com/([^/]+)/([^/]+)/releases/download/([^/]+)/")
		if tu then return tu .. "/" .. tr .. " @ " .. tag .. " (release)" end
		local user, repo, ref = url:match("raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/")
		if not user then return url end
		local pinned = #ref >= 40 and ref:match("^%x+$") ~= nil
		return user .. "/" .. repo .. " @ " .. (pinned and ref:sub(1, 7) or (ref .. " (unpinned)"))
	end
	-- first click launches, afterwards the button says Relaunch so a double click can't open two copies by accident
	local function item(name, desc, locked, label, key, action)
		local r = fr(list, 0, 0, L.IW, 82, "row", 0.9)
		r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 82), nx()
		S.lit(r)
		txt(r, (locked and "🔒 " or "") .. name, 11, "text2", 17, 14, L.IW - 150, 18, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
		txt(r, desc, 8, "sub", 22, 38, L.IW - 150, 28, { TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
		return btn(r, S.launched[key] and "Relaunch" or label, L.IW - 114, 29, 96, 25, "btnFill", BTN_OFF, function(b)
			if b.Text == "Loading..." then return end -- a double click used to fetch and run it twice
			b.Text = "Loading..."
			task.spawn(function()
				local ok, e = pcall(action)
				if not ok then ctx.notify(name .. ": " .. tostring(e), 6) end -- it used to stay on "Loading..." for good
				S.launched[key] = ok or S.launched[key]
				b.Text = S.launched[key] and "Relaunch" or label
			end)
		end)
	end

	local function render()
		clear(list)
		local q = sbox.Text:lower()
		local function show(name) return q == "" or name:lower():find(q, 1, true) end
		-- only slots that actually hold a script are listed
		for _, s in ipairs(BUILTIN) do
			local filled = (s.src:gsub("%-%-[^\n]*", "")):match("%S")
			if filled and show(s.name) then
				item(s.name, s.desc, true, "Execute", "b:" .. s.name, function()
					local k = ctx.toolKey[s.name]
					if k then ctx.openTool(k) else ctx.runSource(s.src, s.name) end
				end)
			end
		end
		if HAS_FS and HAS_LOAD then
			pcall(makefolder, DIR); pcall(makefolder, DIR .. "/scripts")
			local ok, files = pcall(listfiles, DIR .. "/scripts")
			local found = {}
			for _, f in ipairs(ok and files or {}) do
				local n = f:match("([^/\\]+)$")
				if n and (n:sub(-4) == ".lua" or n:sub(-4) == ".txt") then found[#found + 1] = { name = n, path = f } end
			end
			table.sort(found, function(a, b) return a.name:lower() < b.name:lower() end)
			for _, f in ipairs(found) do
				if show(f.name) then item(f.name, "Local file: " .. DIR .. "/scripts", false, "Execute", "l:" .. f.path, function() ctx.runSource(readfile(f.path), f.name) end) end
			end
		else
			empty(list, "File access isn't available in this executor.")
		end
		for _, g in ipairs(GITHUB) do
			if show(g.name) then
				item(g.name, (g.desc and g.desc ~= "" and (g.desc .. "  |  ") or "") .. ghInfo(g.url), false, "Execute", "g:" .. g.url, function()
					local k = ctx.toolKey[g.name]
					if k then return ctx.openTool(k) end
					local body, err = ctx.fetch(g.url)
					if body then ctx.runSource(body, g.name) else ctx.notify(g.name .. ": download failed (" .. tostring(err) .. ")") end
				end)
			end
		end
	end
	sbox:GetPropertyChangedSignal("Text"):Connect(render)
	onShow["Load scripts"] = render
	onHide["Load scripts"] = function() clear(list) end
end
-- [/PG_SCRIPTS]

-- [PG_CMDS]
-- ===== page: Commands (every command with its function, arguments and modifier) ======================
do
	local pg = pages["Commands"]
	local sbox = input(pg, "Search commands, or what they do…", 9, 10, 299, 32, 11)
	local list = scroller(pg, 0, 56, L.IW, L.IH - 56)
	new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local NOLOOP = { panel = 1, cmds = 1, ui = 1, exit = 1, reload = 1, bind = 1, unbind = 1, alias = 1, prefix = 1, selftest = 1, kill = 1, ["break"] = 1, loop = 1, unloop = 1 }
	local function render()
		clear(list)
		local hits = ui.matches(sbox.Text)
		local n = 0
		for _, e in ipairs(hits) do
			n = n + 1
			local r = fr(list, 0, 0, L.IW, 72, "row", 0.9)
			r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 72), n
				S.lit(r)
			local names = {}
			for _, nm in ipairs(e.names) do names[#names + 1] = nm end
			local head = table.concat(names, " / ")
			txt(r, head, 11, "text2", 17, 9, L.IW - 190, 18, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
			if e.args ~= "" then txt(r, e.args, 9, "dim", 17, 9, L.IW - 44, 18, { TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center }) end
			txt(r, e.desc ~= "" and e.desc or "-", 8, "sub", 17, 31, L.IW - 44, 22, { TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
			txt(r, NOLOOP[e.canon] and "modifier: none" or ("modifier: loop^" .. e.canon), 8, "dim", 17, 55, L.IW - 44, 12)
		end
		if n == 0 then empty(list, "No command matches that.") end
	end
	sbox:GetPropertyChangedSignal("Text"):Connect(render)
	onShow["Commands"] = render
	onHide["Commands"] = function() clear(list) end -- gen was an undefined global: the error stopped clear(list) from ever running
end
-- [/PG_CMDS]

-- [PG_FLOW]
-- ===== pages without a slide (Keybinds, Module Cfg, Preferences): same tokens and sizes, flow layout ======
local function flow(name)
	local sc = scroller(pages[name], 0, 0, L.IW, L.IH)
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, sc)
	new("UIPadding", { PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24), PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16) }, sc)
	return sc
end
local function fhdr(sc, str)
	ui.tick()
	local h = txt(sc, str, 14, "text", 0, 0, 400, 23, { LayoutOrder = nx(), Font = FONT_B })
	fr(h, -10, 4, 3, 15, "accent", 0, 2) -- accent mark in the left margin
	return h
end
-- label on the left, a right-anchored group (width w) on the right
local function frow(sc, str, w)
	ui.tick()
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, sc)
	txt(r, str, 12, "text", 12, 2, math.max(60, L.IW - 72 - w), 19, { TextTruncate = Enum.TextTruncate.AtEnd }) -- never runs under the control
	return new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(w, 23), BackgroundTransparency = 1 }, r)
end
-- [/PG_FLOW]

-- [PG_AUTOSTART]
-- Autostart: scripts that start when rOSAD runs (master switch) and, per script, again after every respawn
do
	local pg = flow("Autostart")
	fhdr(pg, "Autostart")
	seg(frow(pg, "Start these when rOSAD runs", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "onExec", function() end, cfg.autostart)
	local list = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local KIND = { builtin = "Built-in", github = "GitHub", ["local"] = "Local file", url = "Link", cmd = "Command" }
	-- quick commands: { button text, command line }. "arvc on" and not "arvc", because a bare toggle would switch it OFF when it is already on.
	local QUICK = { { "Anti ear rape", "antiearrape" }, { "Auto rejoin on VC ban", "arvc on" }, { "Anti fling", "antifling" }, { "Anti sit", "antisit" },
		{ "Anti void", "antivoid" }, { "Anti AFK", "antiafk" }, { "Anti teleport", "antiteleport" }, { "Anti knockback", "antiknockback" },
		{ "Anti spam", "antispam" }, { "Anti freeze", "antifreeze" } }
	local render

	local function add(it)
		if it.kind == "cmd" and ctx.leaves(it.ref) then return ctx.notify("Leave / rejoin / hop commands can't be added to autostart") end
		cfg.autostart.items[#cfg.autostart.items + 1] = { name = it.name, kind = it.kind, ref = it.ref, respawn = false }
		save(); render()
	end
	local function has(kind, ref)
		for _, it in ipairs(cfg.autostart.items) do
			if it.kind == kind and it.ref == ref then return true end
		end
	end
	local function label(str) txt(list, str, 11, "sub", 0, 0, 400, 20, { LayoutOrder = nx() }) end
	local function card(h)
		local r = fr(list, 0, 0, 490, h, "row", 0.9, 4)
		r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, h), nx()
		return r
	end

	render = function()
		clear(list)
		local items = cfg.autostart.items
		label("Your autostart list (" .. #items .. ")")
		if #items == 0 then txt(list, "Nothing yet. Add a command or a script below.", 10, "dim", 0, 0, 400, 20, { LayoutOrder = nx() }) end
		for idx, it in ipairs(items) do
			local r = card(48)
			txt(r, it.name, 11, "text2", 12, 6, 270, 18, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
			txt(r, (KIND[it.kind] or it.kind) .. ((it.kind == "url" or it.kind == "cmd") and (": " .. it.ref) or ""), 8, "sub", 12, 27, 270, 14, { TextTruncate = Enum.TextTruncate.AtEnd })
			local rb = btn(r, it.respawn and "After reset: On" or "After reset: Off", L.IW - 238, 12, 100, 23, "ctrlOff", BTN_OFF, function(b)
				it.respawn = not it.respawn
				save()
				b.Text = it.respawn and "After reset: On" or "After reset: Off"
				setFill(b, it.respawn and "ctrlOn" or "ctrlOff", it.respawn and BTN_ON or BTN_OFF)
			end)
			if it.respawn then setFill(rb, "ctrlOn", BTN_ON) end
			btn(r, "Remove", L.IW - 132, 12, 76, 23, "danger", nil, function()
				table.remove(cfg.autostart.items, idx)
				save(); render()
			end)
		end

		label("Add a command")
		local chips = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, list)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
		for _, q in ipairs(QUICK) do
			if not has("cmd", q[2]) then
				btn(chips, q[1], 0, 0, #q[1] * 7 + 22, 23, "btnFill", BTN_OFF, function() add({ name = q[1], kind = "cmd", ref = q[2] }) end).LayoutOrder = nx()
			end
		end
		local crow = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, list)
		local cbox = input(crow, "any command, e.g. speed 30", 0, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
		cbox.Parent.Size = UDim2.new(1, -112, 0, 23)
		local cb = btn(crow, "Add command", 0, 0, 104, 23, "primary", nil, function()
			local line = ((cbox.Text:gsub("^%s*;", "")):match("^%s*(.-)%s*$"))
			local first = line:match("^(%S+)")
			local canon = first and ctx.Aliases[first:lower()]
			if not canon then return ctx.notify("Unknown command: " .. tostring(first or "")) end
			if canon == "arjvc" and line == first then line = line .. " on" end
			if has("cmd", line) then return ctx.notify("Already in the list") end
			add({ name = ";" .. line, kind = "cmd", ref = line })
		end)
		cb.AnchorPoint = Vector2.new(1, 0); cb.Position = UDim2.new(1, 0, 0, 0)

		label("Add a script")
		local shown = 0
		for _, b in ipairs(BUILTIN) do
			local filled = (b.src:gsub("%-%-[^\n]*", "")):match("%S")
			if filled and not has("builtin", b.name) then
				shown = shown + 1
				local r = card(34)
				txt(r, b.name, 10, "text2", 12, 8, 380, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
				btn(r, "Add", L.IW - 138, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = b.name, kind = "builtin", ref = b.name }) end)
			end
		end
		if HAS_FS and HAS_LOAD then
			local ok, files = pcall(listfiles, DIR .. "/scripts")
			for _, f in ipairs(ok and files or {}) do
				local n = f:match("([^/\\]+)$")
				if n and (n:sub(-4) == ".lua" or n:sub(-4) == ".txt") and not has("local", f) then
					shown = shown + 1
					local r = card(34)
					txt(r, n .. "  (local file)", 10, "text2", 12, 8, 380, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
					btn(r, "Add", L.IW - 138, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = n, kind = "local", ref = f }) end)
				end
			end
		end
		for _, g in ipairs(GITHUB) do
			if not has("github", g.name) then
				shown = shown + 1
				local r = card(34)
				txt(r, g.name .. "  (GitHub)", 10, "text2", 12, 8, 380, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
				btn(r, "Add", L.IW - 138, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = g.name, kind = "github", ref = g.name }) end)
			end
		end
		if shown == 0 then txt(list, "Everything available is already added.", 10, "dim", 0, 0, 400, 20, { LayoutOrder = nx() }) end

		label("Or add by link")
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, list)
		local link = input(row, "https://raw.githubusercontent.com/...", 0, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
		link.Parent.Size = UDim2.new(1, -90, 0, 23)
		local ab = btn(row, "Add link", 0, 0, 82, 23, "primary", nil, function()
			local u = link.Text:match("^%s*(.-)%s*$")
			if not u:match("^https?://") then return ctx.notify("That doesn't look like a link") end
			add({ name = u:match("([^/]+)$") or u, kind = "url", ref = u })
		end)
		ab.AnchorPoint = Vector2.new(1, 0); ab.Position = UDim2.new(1, 0, 0, 0)
	end
	onShow["Autostart"] = render
	onHide["Autostart"] = function() clear(list) end
end
-- [/PG_AUTOSTART]

-- [PG_KEYS]
do
	local pg = flow("Keybinds")
	-- two tiles side by side: caption + keycap (click the keycap, then press the new key)
	local function keyTile(row, x, cap, key)
		local t = fr(row, x, 0, math.floor((L.IW - 56) / 2), 54, "row", 0.9, 5, "edge", 1, 0.6)
		txt(t, cap, 9, "dim", 12, 8, 200, 12, { Font = FONT_B })
		txt(t, "click, then press a key", 9, "hint", 130, 28, 106, 14)
		return btn(t, "", 12, 24, 110, 23, "ctrlOff", BTN_OFF, function(b)
			if S.capBtn and S.capBtn ~= b and S.capBtn.Parent then setFill(S.capBtn, "ctrlOff", BTN_OFF) end -- arming one keycap disarms the other
			S.capBtn = b
			b.Text = "press a key..."
			setFill(b, "ctrlOn", BTN_ON) -- colored only while it waits for a key
			S.capture = function(kc)
				setFill(b, "ctrlOff", BTN_OFF)
				if kc ~= Enum.KeyCode.Escape then cfg[key] = kc.Name; save() end
				ui.apply()
			end
		end, 10)
	end
	fhdr(pg, "Hotkeys")
	local hot = new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local barBtn, panelBtn = keyTile(hot, 0, "COMMAND BAR", "barKey"), keyTile(hot, math.floor((L.IW - 56) / 2) + 8, "PANEL", "panelKey")
	-- experience (universe) ID -> game name, cached in cfg.exp. cb(name) or cb(nil, networkFailed)
	local function expName(id, cb)
		local k = string.format("%d", id)
		if id == game.GameId then return cb(cfg.exp[k] or game.Name) end
		if cfg.exp[k] then return cb(cfg.exp[k]) end
		task.spawn(function()
			local body = ctx.fetch("https://games.roblox.com/v1/games?universeIds=" .. k)
			local ok, n = pcall(function() return S.HttpService:JSONDecode(body).data[1].name end)
			if ok and type(n) == "string" and n ~= "" then
				cfg.exp[k] = n; save(); cb(n)
			else
				cb(nil, body == nil)
			end
		end)
	end
	fhdr(pg, "Keybind tabs")
	local area = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, area)
	local newKey

	-- card = one box per bind; line = a 23px row inside it; rbtn = a button pinned to the row's right edge
	local function card(parent)
		local c = fr(parent, 0, 0, 0, 0, "row", 0.9, 5, "edge", 1, 0.7)
		c.Size, c.AutomaticSize, c.LayoutOrder = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, nx()
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7) }, c)
		return c
	end
	local function line(parent)
		return new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, parent)
	end
	local function rbtn(parent, str, fromRight, w, cb)
		local b = btn(parent, str, 0, 0, w, 23, nil, nil, cb, 10)
		b.AnchorPoint, b.Position = Vector2.new(1, 0), UDim2.new(1, -fromRight, 0, 0)
		return b
	end
	local CENTER = Enum.TextYAlignment.Center
	-- "Tab name" box: Enter or click away renames (empty or unchanged reverts)
	local function renameRow(cur, set)
		local g = frow(area, "Tab name", 180)
		local nb = input(g, "tab name", 0, 0, 180, 23, 9, "ctrlOff", BTN_OFF, { Text = cur, TextXAlignment = Enum.TextXAlignment.Center })
		nb.FocusLost:Connect(function()
			if not nb.Parent then return end -- page was rebuilt
			local v = nb.Text:match("^%s*(.-)%s*$"):sub(1, 20)
			if v ~= "" and v ~= cur then set(v); save(); ui.refreshKeys() else nb.Text = cur end
		end)
	end

	function ui.refreshKeys()
		barBtn.Text, panelBtn.Text = "[ " .. keyStr(cfg.barKey) .. " ]", "[ " .. keyStr(cfg.panelKey) .. " ]"
		clear(area)
		newKey = nil
		local t = ctx.kbTab()
		if cfg.kbActive ~= "none" and cfg.kbActive ~= "default" and not t then cfg.kbActive = "default" end
		-- tab strip: No Keybinds | Default | custom tabs | +
		local strip = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, area)
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, strip)
		local function tabBtn(id, name)
			local on = cfg.kbActive == id
			local b = btn(strip, name, 0, 0, math.max(44, #name * 7 + 20), 23, on and "ctrlOn" or "ctrlOff", on and BTN_ON or BTN_OFF, function()
				cfg.kbActive = id; save(); ui.refreshKeys()
			end)
			b.LayoutOrder = nx()
		end
		tabBtn("none", "No Keybinds"); tabBtn("default", cfg.kbDefName)
		for _, x in ipairs(cfg.kbTabs) do tabBtn(x.id, x.name) end
		btn(strip, "+ New tab", 0, 0, 76, 23, nil, nil, function()
			local n = 1
			local function taken() for _, x in ipairs(cfg.kbTabs) do if x.name == "Tab " .. n then return true end end end
			while taken() do n = n + 1 end
			local nt = { id = S.HttpService:GenerateGUID(false), name = "Tab " .. n, binds = {}, es = false }
			cfg.kbTabs[#cfg.kbTabs + 1] = nt
			cfg.kbActive = nt.id; save(); ui.refreshKeys()
		end, 10).LayoutOrder = nx()

		if cfg.kbActive == "none" then
			txt(area, "Keybinds are off. Pick Default or a tab to use your binds.", 10, "sub", 0, 0, 440, 22, { LayoutOrder = nx() })
			return
		end
		if cfg.kbActive == "default" then
			renameRow(cfg.kbDefName, function(v) cfg.kbDefName = v end)
			txt(area, "Default tab: its binds work in every experience.", 9, "dim", 0, 0, 440, 14, { LayoutOrder = nx() })
		end
		if t then -- custom tab: rename, experience specific option + delete (No Keybinds and Default can't be deleted)
			renameRow(t.name, function(v) t.name = v end)
			seg(frow(area, "Experience specific", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "es", function() ui.refreshKeys() end, t)
			if t.es then
				local g = frow(area, "Experience ID", 250)
				local idb = input(g, "experience id", 0, 0, 140, 23, 9, "ctrlOff", BTN_OFF, { Text = t.exp and string.format("%d", t.exp) or "", TextXAlignment = Enum.TextXAlignment.Center })
				idb.FocusLost:Connect(function()
					if not idb.Parent then return end
					t.exp = tonumber(idb.Text); save(); ui.refreshKeys()
				end)
				btn(g, "Use current", 146, 0, 104, 23, "btnFill", BTN_OFF, function() t.exp = game.GameId; save(); ui.refreshKeys() end)
				local nm = txt(area, t.exp and "Looking up experience..." or "Type an experience ID to see which game it is.", 10, "sub", 0, 0, 440, 16, { LayoutOrder = nx(), TextTruncate = Enum.TextTruncate.AtEnd })
				if t.exp then
					expName(t.exp, function(n, netFail)
						if not nm.Parent then return end
						nm.Text = n and ("Experience: " .. n) or (netFail and "Couldn't look the experience up (no connection)" or "No experience found with that ID")
					end)
				end
				if t.exp ~= game.GameId then
					txt(area, (t.exp and "Inactive here: this tab only works in the experience above." or "Inactive here: no experience ID set."), 9, "dim", 0, 0, 440, 16, { LayoutOrder = nx() })
				end
			end
			btn(frow(area, "Delete this tab", 76), "Delete", 0, 0, 76, 23, "danger", nil, function()
				for i, x in ipairs(cfg.kbTabs) do
					if x == t then table.remove(cfg.kbTabs, i); break end
				end
				cfg.kbActive = "default"; save(); ui.refreshKeys()
			end)
		end

		local binds = ctx.bindTable()
		local names = {}
		for k in pairs(binds) do names[#names + 1] = k end
		table.sort(names)

		-- add a bind comes first so it never scrolls away: key box -> command -> Add (Ctrl/Shift/Alt + key works)
		local nb = card(area)
		local hd = line(nb)
		txt(hd, "Add a bind", 11, "text2", 0, 0, 80, 23, { Font = FONT_B, TextYAlignment = CENTER })
		txt(hd, "click the key box, press a key, type a command", 9, "dim", 86, 0, 360, 23, { TextYAlignment = CENTER })
		local a = line(nb)
		btn(a, "set key", 0, 0, 96, 23, "ctrlOff", BTN_OFF, function(b)
			b.Text = "press a key..."
			setFill(b, "ctrlOn", BTN_ON)
			local function cap(kc, name)
				if kc ~= Enum.KeyCode.Escape then
					if ctx.MODS[kc.Name] then S.capture = cap; return end -- modifier alone: keep waiting, so Ctrl+G works
					newKey = name
				end
				b.Text = newKey and keyStr(newKey) or "set key"
				setFill(b, newKey and "ctrlOn" or "ctrlOff", newKey and BTN_ON or BTN_OFF) -- a chosen key counts as selected
			end
			S.capture = cap
		end, 10)
		local cb = input(a, "command, e.g. fly 80", 102, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
		cb.Parent.Size = UDim2.new(1, -160, 1, 0)
		local function go()
			if newKey and cb.Text:match("%S") then ctx.addBind(newKey, cb.Text)
			else ctx.notify("Pick a key and type a command first") end
		end
		cb.FocusLost:Connect(function(enter) if enter then go() end end)
		rbtn(a, "+ Add", 0, 50, go)

		fhdr(area, "Your binds (" .. #names .. ")")
		if #names == 0 then txt(area, "Nothing here yet. Set a key above, type a command, hit Add.", 10, "sub", 0, 0, 440, 22, { LayoutOrder = nx() }) end
		for _, k in ipairs(names) do -- one card per key: keycap + remove, one code pill per command (cycle order), add box
			local list = ctx.bindList(k)
			local multi = #list > 1 -- a single command needs no number or arrows; Remove in the header covers it
			local c = card(area)
			local h = line(c)
			local w = math.max(34, #keyStr(k) * 8 + 16)
			btn(h, keyStr(k), 0, 0, w, 23, "ctrlOff", BTN_OFF, function(b)
				setFill(b, "ctrlOn", BTN_ON) -- click, then press the new key (Ctrl/Shift/Alt combos work)
				b.Text = "..."
				local function cap(kc, name)
					if kc ~= Enum.KeyCode.Escape then
						if ctx.MODS[kc.Name] then S.capture = cap; return end
						local nk = ctx.normKey(name)
						if nk and nk ~= k then
							local merged = ctx.bindList(nk) -- keep what the target key already does, ours go after it
							for _, c in ipairs(ctx.bindList(k)) do merged[#merged + 1] = c end
							ctx.storeBinds(k, {})
							return ctx.storeBinds(nk, merged)
						end
					end
					b.Text = keyStr(k)
					setFill(b, "ctrlOff", BTN_OFF)
				end
				S.capture = cap
			end, 11)
			txt(h, (multi and #list .. " commands, one per press · " or "") .. "click to edit", 9, "dim", w + 8, 0, 300, 23, { TextYAlignment = CENTER })
			rbtn(h, "Remove", 0, 62, function() ctx.setBind(k, nil) end)
			for i, cmd in ipairs(list) do
				local r = line(c)
				if multi then txt(r, tostring(i), 9, "dim", 0, 0, 14, 23, { TextYAlignment = CENTER }) end
				local x = multi and 20 or 0
				local eb = input(r, "command", x, 0, 0, 23, 11, "inner", 0.35, { Font = FONT_CODE, Text = cmd })
				eb.Parent.Size = UDim2.new(1, -(x + (multi and 80 or 0)), 1, 0)
				eb.FocusLost:Connect(function()
					if not eb.Parent then return end -- page was rebuilt
					local v = eb.Text:match("^%s*(.-)%s*$")
					if v == "" or v == cmd then eb.Text = cmd; return end
					local l = ctx.bindList(k)
					l[i] = v
					ctx.storeBinds(k, l)
				end)
				if multi then
					rbtn(r, "×", 0, 22, function() ctx.editBind(k, i, 0) end)
					if i < #list then rbtn(r, "↓", 26, 22, function() ctx.editBind(k, i, 1) end) end
					if i > 1 then rbtn(r, "↑", 52, 22, function() ctx.editBind(k, i, -1) end) end
				end
			end
			local a2 = line(c)
			local cb2 = input(a2, multi and "+ add another command" or "+ add a 2nd command (they cycle on each press)", 0, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
			cb2.Parent.Size = UDim2.new(1, -58, 1, 0)
			local function go2() if cb2.Text:match("%S") then ctx.addBind(k, cb2.Text) end end
			cb2.FocusLost:Connect(function(enter) if enter then go2() end end)
			rbtn(a2, "+ Add", 0, 50, go2)
		end
	end
	onShow["Keybinds"] = ui.refreshKeys
	onHide["Keybinds"] = function() -- leaving disarms key capture (the next letter typed in chat became the hotkey)
		clear(area); newKey = nil
		S.capture = nil -- the keycap text resets on the next visit (onShow = ui.refreshKeys)
		setFill(barBtn, "ctrlOff", BTN_OFF); setFill(panelBtn, "ctrlOff", BTN_OFF)
	end
end
-- [/PG_KEYS]

-- [PG_MODCFG]
-- Module Cfg: default values and multipliers for commands. Typing a number commits on Enter / click away.
ui.lazy("Module Cfg", function() -- built the first time the tab opens, a few rows per frame
	local pg = flow("Module Cfg")
	local M = cfg.mod
	local function numRow(label, key)
		local g = frow(pg, label, 96)
		local o = input(g, "", 0, 0, 96, 23, 9, "ctrlOff", BTN_OFF, { Text = tostring(M[key]), TextXAlignment = Enum.TextXAlignment.Center })
		o.FocusLost:Connect(function()
			local v = tonumber(o.Text)
			if v then M[key] = v; save(); if ctx.onMod then ctx.onMod(key) end end
			o.Text = tostring(M[key])
		end)
	end
	local function strRow(label, key)
		local g = frow(pg, label, 180)
		local o = input(g, "", 0, 0, 180, 23, 9, "ctrlOff", BTN_OFF, { Text = tostring(M[key]), TextXAlignment = Enum.TextXAlignment.Center })
		o.FocusLost:Connect(function()
			if o.Text:match("%S") and o.Text ~= M[key] then M[key] = o.Text; save(); ctx.reloadSpoofer() end
			o.Text = tostring(M[key])
		end)
	end
	local function togRow(label, key)
		seg(frow(pg, label, 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, key, function() if ctx.onMod then ctx.onMod(key) end end, M)
	end
	local function optRow(label, key, opts, w)
		local xs = {}
		for i = 1, #opts do xs[i] = (i - 1) * (w + 8) end
		seg(frow(pg, label, #opts * (w + 8) - 8), 0, xs, w, opts, key, function() if ctx.onMod then ctx.onMod(key) end end, M)
	end

	local function hexRow(label, key)
		local g = frow(pg, label, 96)
		local o = input(g, "", 0, 0, 96, 23, 9, "ctrlOff", BTN_OFF, { Text = tostring(M[key]), TextXAlignment = Enum.TextXAlignment.Center })
		o.FocusLost:Connect(function()
			local t = o.Text:match("^%s*(.-)%s*$")
			if not t:match("^#") then t = "#" .. t end
			if parseHex(t) then M[key] = t:upper(); save(); if ctx.onMod then ctx.onMod(key) end end
			o.Text = tostring(M[key])
		end)
	end

	fhdr(pg, "Speed and fly")
	numRow("Fly: default speed", "flyDef"); numRow("Fly: multiplier", "flyMult")
	numRow("Speed: default", "speedDef"); numRow("Speed: multiplier", "speedMult")
	numRow("Jump power: default", "jpDef"); numRow("Jump power: multiplier", "jpMult")
	numRow("Spin: default (rotations/s)", "spinDef"); numRow("Spin: multiplier", "spinMult")
	numRow("Float: stair height (studs)", "floatStep")
	fhdr(pg, "Spider (;spider)")
	
	numRow("Wall height (studs, hook only taller walls, 0 = any)", "spWall")
	fhdr(pg, "Tpwalk")
	optRow("Mode", "tpMode", { { "Multiplier", "Multiplier" }, { "Additive", "Additive" } }, 84)
	numRow("Default amount", "tpDef"); numRow("Maximum (cap)", "tpCap")
	fhdr(pg, "Follow, backpack, baby")
	numRow("Follow: default radius (studs)", "followRadius")
	numRow("Backpack: distance", "bpDist"); numRow("Backpack: height", "bpHeight")
	numRow("Baby: distance", "babyDist"); numRow("Baby: height", "babyHeight"); numRow("Baby: rotation (degrees)", "babyRot"); numRow("Baby: lean back (degrees)", "babyLean")
	fhdr(pg, "Head attach (;heada / ;headattach)")
	numRow("Distance (in front of the face)", "headDist"); numRow("Height above the head", "headHeight"); numRow("Side", "headSide")
	togRow("Sweep front / back", "headSweep"); numRow("Sweep amplitude (studs)", "headSweepAmp"); numRow("Sweep speed (radians/s)", "headSweepSpeed")
	fhdr(pg, "Back attach (;backa / ;backattach)")
	numRow("Distance (behind the back)", "backDist"); numRow("Height", "backHeight"); numRow("Side", "backSide")
	togRow("Sweep front / back", "backSweep"); numRow("Sweep amplitude (studs)", "backSweepAmp"); numRow("Sweep speed (radians/s)", "backSweepSpeed")
	fhdr(pg, "Offense prediction (backpack, baby, headsit, heada, backa)")
	togRow("Prediction (server sees you in sync)", "predOn")
	numRow("Prediction strength (1 = your ping)", "predMult")
	fhdr(pg, "Server position (;serverpos / ;unserverpos)")
	togRow("Show server position", "srvShow")
	numRow("Auto hide within (studs, 0 to 5)", "srvHide")
	fhdr(pg, "ESP (;esp)")
	togRow("Custom colour (off = team colour)", "espCustom")
	hexRow("Custom colour (hex)", "espColor")
	fhdr(pg, "Crosshair (;crosshair / ;removecrosshair)")
	optRow("Mode", "chStyle", { { "Cross", "Cross" }, { "T", "T" }, { "Dot", "Dot" } }, 84)
	numRow("Length", "chLen"); numRow("Gap", "chGap"); numRow("Thickness", "chThick")
	numRow("Outline thickness (0 = none)", "chOutline"); numRow("Outline opacity (0 to 1)", "chOutlineAlpha")
	hexRow("Colour (hex)", "chColor")
	togRow("Replace Roblox cursor (off = screen center)", "chCursor")
	fhdr(pg, "Notifications and display")
	togRow("Activation notices", "actOn")
	optRow("Notice corner", "actCorner", { { "TL", "TL" }, { "TR", "TR" }, { "BL", "BL" }, { "BR", "BR" } }, 47)
	optRow("Show FPS corner", "fpsCorner", { { "TL", "TL" }, { "TR", "TR" }, { "BL", "BL" }, { "BR", "BR" } }, 47)
	fhdr(pg, "Ragdoll (;ragdoll)")
	togRow("Ragdoll blocks game reset", "ragdollBlock")
	fhdr(pg, "Streamer mode")
	strRow("Your name", "streamMe"); strRow("Other players (comma separated)", "streamOthers")
	fhdr(pg, "Placeholder1 (;placeholder1)")
	numRow("Animation speed (1 = default)", "ph1Mult")
	fhdr(pg, "Server browser")
	numRow("Ping shown = list ping x this (the list underreports)", "srvPingMult")
	fhdr(pg, "Defense")
	togRow("Defense notifications", "defNotify")
	numRow("Anti fling: radius", "afRadius"); numRow("Anti fling: velocity threshold", "afThreshold"); numRow("Anti fling: restore time (s)", "afRestore")
	numRow("Anti teleport: min distance", "atpMin"); numRow("Anti knockback: max speed", "akMax")
	numRow("Anti void: height above destroy", "avHeight")
	numRow("Anti ear rape: threshold", "aeThreshold"); numRow("Anti ear rape: window (s)", "aeDuration")
	numRow("Anti afk: interval (s)", "afkInterval"); numRow("Anti spam: messages", "spamCount")
	onShow["Module Cfg"] = function() if ui.layoutHud and state.active.showfps then ui.layoutHud() end end
end)
-- [/PG_MODCFG]

-- [PG_PREFS]
ui.lazy("Preferences", function() -- built the first time the tab opens, a few rows per frame
	local pg = flow("Preferences")
	fhdr(pg, "General")
	seg(frow(pg, "Notifications", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "toasts")
	seg(frow(pg, "Open command bar on start", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "startBar")
	seg(frow(pg, "Auto execute", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "autoExec", function(v) ctx.setAutoExec(v) end)
	seg(frow(pg, "Auto rejoin on VC ban", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "avc", function(v) ctx.setAvc(v) end)
	seg(frow(pg, "Command list: up to 3 columns", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "sugCols")
	fhdr(pg, "Voice")
	if cfg.listenPad == -3 then cfg.listenPad = -6 end -- old option, nearest new one
	seg(frow(pg, "Listen pad (attenuation)", 168), 0, { 0, 59, 118 }, 50, { { "0 dB", 0 }, { "-6 dB", -6 }, { "-12 dB", -12 } }, "listenPad", function() ctx.applyListenPad() end)
	fhdr(pg, "Server browser")
	seg(frow(pg, "Max servers to scan", 227), 0, { 0, 59, 118, 177 }, 50, { { "25", 25 }, { "50", 50 }, { "75", 75 }, { "100", 100 } }, "srvMax")
	fhdr(pg, "Players tab")
	seg(frow(pg, "Sort refresh, 0 = no delay", 286), 0, { 0, 59, 118, 177, 236 }, 50, { { "0", 0 }, { "1", 1 }, { "2", 2 }, { "3", 3 }, { "5", 5 } }, "plPoll", function() end)
	fhdr(pg, "User notifier")
	seg(frow(pg, "Status refresh (seconds)", 227), 0, { 0, 59, 118, 177 }, 50, { { "30", 30 }, { "45", 45 }, { "60", 60 }, { "90", 90 } }, "nuPoll")
	local nr = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local nb = input(nr, "username to watch (also ;notifyuser)…", 0, 0, 330, 23, 11)
	local function addNu() ctx.nuAdd(nb.Text); nb.Text = "" end
	btn(nr, "Add", 336, 0, 60, 23, "primary", nil, addNu)
	nb.FocusLost:Connect(function(enter) if enter then addNu() end end)
	local nl = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, nl)
	function ui.refreshNu()
		for _, c in ipairs(nl:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		if #cfg.notifyUsers == 0 then
			txt(new("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 }, nl), "none", 11, "sub", 12, 0, 300, 20)
		end
		for i, n in ipairs(cfg.notifyUsers) do
			local e = ctx.nuInfo[n] or {}
			local r = fr(nl, 0, 0, 0, 56, "row", 0.85, 8, "edge", 1, 0.55)
			r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 56), i
			if e.id then
				local a = new("ImageLabel", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(40, 40), BorderSizePixel = 0, BackgroundTransparency = 0.9, Image = thumb("AvatarHeadShot", e.id, 150) }, r)
				paint(a, "BackgroundColor3", "row")
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
			end
			local status, color = ctx.nuStatus(n)
			txt(r, e.display or e.user or n, 11, "text2", 58, 5, 330, 16, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
			txt(r, "@" .. (e.user or n), 8, "sub", 58, 21, 330, 12, { TextTruncate = Enum.TextTruncate.AtEnd })
			local dot = new("Frame", { Position = UDim2.fromOffset(59, 40), Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, BackgroundColor3 = color }, r)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
			txt(r, status, 9, "text", 73, 36, 320, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
			btn(r, "Remove", L.IW - 134, 16, 70, 23, "danger", nil, function() ctx.nuRemove(n) end)
		end
	end
	ui.refreshNu()
	fhdr(pg, "System")
	local rr = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local rdot = new("Frame", { Position = UDim2.fromOffset(2, 3), Size = UDim2.fromOffset(10, 10), BorderSizePixel = 0 }, rr)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, rdot)
	local rtx = txt(rr, "", 11, "text", 18, 0, 400, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
	local sysT = {}
	for _, k in ipairs({ "cpu", "gpu", "ram", "mem", "ft", "ping" }) do sysT[k] = txt(pg, "", 11, "text", 0, 0, 400, 16, { LayoutOrder = nx(), TextTruncate = Enum.TextTruncate.AtEnd }) end
	local function refreshSys()
		local r = ui.rel
		local s = r.sys
		rdot.BackgroundColor3, rdot.Visible = r.col[r.s or "bad"], r.s ~= nil
		rtx.Text = "Relay: " .. (({ ok = "connected", warn = "connected, rate limited", bad = "errors / connection lost" })[r.s or ""] or "not connected") .. "   PID " .. r.pid
		sysT.cpu.Text = "CPU: " .. (s.cpu or "needs relay")
		sysT.gpu.Text = "GPU: " .. (s.gpu or "needs relay")
		sysT.ram.Text = "RAM: " .. (s.ram and (s.ram .. " GB, " .. s.load .. "% used") or "needs relay")
		local function v(f, u) local ok, x = pcall(f); return ok and tonumber(x) and (("%.1f"):format(x) .. u) or "-" end
		sysT.mem.Text = "Roblox memory: " .. v(function() return S.Stats:GetTotalMemoryUsageMb() end, " MB")
		sysT.ft.Text = "Frame time: CPU " .. v(function() return S.Stats.PerformanceStats.CPU:GetValue() end, " ms") .. ", GPU " .. v(function() return S.Stats.PerformanceStats.GPU:GetValue() end, " ms")
		sysT.ping.Text = "Ping: " .. v(function() return S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end, " ms")
	end
	task.spawn(function()
		while S.alive do
			if S.panelOpen and ui.tab == "Preferences" then pcall(refreshSys) end
			task.wait(2)
		end
	end)
	fhdr(pg, "Active effects")
	local active = txt(pg, "none", 11, "sub", 0, 0, 400, 20, { LayoutOrder = nx(), TextWrapped = true })
	local br = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local function refresh()
		local names = {}
		for k in pairs(state.active) do names[#names + 1] = (state.who and state.who[k]) and (k:sub(1, 1):upper() .. k:sub(2) .. ": " .. state.who[k]) or k end
		table.sort(names)
		active.Text = #names > 0 and table.concat(names, ", ") or "none"
	end
	btn(br, "Reset all effects", 0, 0, 120, 23, "danger", nil, function() ctx.resetAll(); refresh() end)
	btn(br, "Unload panel", 126, 0, 100, 23, "danger", nil, function() ui.unload() end)
	txt(pg, "KL rOSAD v" .. VERSION, 8, "dim", 0, 0, 300, 14, { LayoutOrder = nx() })
	onShow["Preferences"] = function() refresh(); ui.refreshNu(); pcall(refreshSys) end
end)
-- [/PG_PREFS]

-- [ENTRY]
-- ===== apply settings, wire input, start ===================================
-- 1080p is the design size only: the UI keeps the same pixel size at every resolution, the UI Scaling setting is the only zoom.
function ui.curScale() return cfg.scale end
function ui.rescale()
	local s = ui.curScale()
	ui.panelScale.Scale, ui.barScale.Scale, ui.toastScale.Scale, ui.hudScale.Scale, ui.popScale.Scale = s, s, s, s, s
	ui.actScale.Scale = s
	if ui.profScale then ui.profScale.Scale = s end
end

-- Roblox's shift lock listens on both Shift keys. When one of them is the panel / bar key, a higher priority action eats it
-- for shift lock only (our own InputBegan still sees it). Use ;shiftlock to toggle shift lock instead.
function ui.syncShift()
	local CAS = S.ContextActionService
	pcall(function() CAS:UnbindAction("KLOSAD_Shift") end)
	local keys = {}
	for _, n in ipairs({ cfg.panelKey, cfg.barKey }) do
		if n == "RightShift" or n == "LeftShift" then keys[#keys + 1] = Enum.KeyCode[n] end
	end
	if #keys > 0 then
		pcall(function()
			CAS:BindActionAtPriority("KLOSAD_Shift", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value, table.unpack(keys))
		end)
	end
end

function ui.apply()
	ui.syncShift()
	S.accent = parseHex(cfg.accent) or S.accent
	S.accentText = legible(S.accent, THEMES[cfg.theme].panel)
	applyTheme()
	ui.rescale()
	ui.panel.BackgroundTransparency = 1 - cfg.opacity
	-- everything in the panel follows UI Opacity relative to its 80 % design (tiles, cards, buttons, fields, washes)
	S.opK = math.clamp(tonumber(cfg.opacity) or 0.8, 0.2, 1) / 0.8
	local scope = ui.panel:GetDescendants()
	if ui.profWin then -- the profile window follows UI Opacity too
		ui.profWin.BackgroundTransparency = 1 - cfg.opacity
		for _, o in ipairs(ui.profWin:GetDescendants()) do scope[#scope + 1] = o end
	end
	if ui.prof and ui.prof.retitle then ui.prof.retitle() end
	for _, o in ipairs(scope) do
		local r = o:GetAttribute("raw")
		if r then
			local v = S.opx(r)
			o.BackgroundTransparency = v
			if o:GetAttribute("base") ~= nil then o:SetAttribute("base", v) end
		end
	end
	if ui.setGlow then ui.setGlow() end
	ui.ambient()
	ui.title.Text = '<font color="' .. hex(S.accent) .. '">&gt;</font>KL rOSAD'
	ui.box.PlaceholderText = "[ " .. keyStr(cfg.barKey) .. " ] enter or search a command…"
	ui.layoutBar()
	if ui.refreshKeys then ui.refreshKeys() end
	if S.barOpen then ui.search() end
	-- rich-text colors are baked in when a list is built, so rebuild the visible tab after a theme / accent change
	if S.panelOpen and onShow[ui.tab] then onShow[ui.tab]() end
end

conn(S.UserInputService.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local kc = input.KeyCode
	if S.capture then
		local f = S.capture
		S.capture = nil
		f(kc, ctx.keyName(kc))
		return
	end
	if S.barOpen then
		if kc == Enum.KeyCode.Escape then ui.closeBar()
		elseif kc == Enum.KeyCode.Tab then ui.complete()
		elseif kc == Enum.KeyCode.Space and (S.ghost or "") ~= "" then ui.complete() -- the space itself is typed right after, so "fl" + Space = "fly "
		elseif kc == Enum.KeyCode.Down then ui.hold(kc, function() ui.move(1) end)
		elseif kc == Enum.KeyCode.Up then ui.hold(kc, function() ui.move(-1) end)
		elseif kc == Enum.KeyCode.Right then ui.hold(kc, function() ui.moveH(1) end)
		elseif kc == Enum.KeyCode.Left then ui.hold(kc, function() ui.moveH(-1) end) end
		return
	end
	-- not "gameProcessed": Roblox's shift-lock grabs Shift first, which is why RightShift never opened the panel.
	-- A focused text box (chat, the panel's own inputs) is the only thing that should block hotkeys.
	if S.UserInputService:GetFocusedTextBox() then return end
	if kc.Name == cfg.barKey then
		ui.openBar()
	elseif kc.Name == cfg.panelKey then
		ui.setPanel(not S.panelOpen)
	else
		local bt = ctx.activeBinds()
		if bt then ctx.fireBind(bt, kc) end
	end
end)

conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
	ui.rescale()
	ui.layoutBar()
end)

-- while the mouse is over the panel / bar / list: move its cursor light and sink mouse + wheel input for the game's own ContextActionService handlers
-- (the Active surfaces already stop Roblox's camera and tools). shortcut: a game that reads clicks straight from UserInputService without checking gameProcessed still sees them; nothing client side can hide input from that
do
	local CAS, blocking = S.ContextActionService, false
	-- GetMouseLocation includes the topbar inset; this gui's AbsolutePosition does not, so the light sat one inset (36-58 px) too low. Change to 0 if it ever lands too high
	S.spotDY = 0
	pcall(function() S.spotDY = S.GuiService:GetGuiInset().Y end)
	conn(S.RunService.RenderStepped, function()
		local m = (S.panelOpen or S.barOpen or S.profOpen) and S.UserInputService:GetMouseLocation() or nil
		local over = false
		for _, sp in ipairs(S.spots) do
			local inside = false
			if m and sp.live() then
				local p, z = sp.area.AbsolutePosition, sp.area.AbsoluteSize
				if m.X >= p.X and m.X <= p.X + z.X and m.Y >= p.Y and m.Y <= p.Y + z.Y then
					inside = true
					local sc = z.X / math.max(sp.area.Size.X.Offset, 1) -- the scale it is really drawn at (UIScale, open animation), like the button ripple does
					sp.hold.Position = UDim2.fromOffset((m.X - p.X) / sc, (m.Y - S.spotDY - p.Y) / sc)
				end
			end
			if sp.hold.Visible ~= inside then sp.hold.Visible = inside end
			over = over or inside
		end
		if over ~= blocking then
			blocking = over
			if over then
				pcall(CAS.BindActionAtPriority, CAS, "KLOSAD_Block", function() return Enum.ContextActionResult.Sink end, false, Enum.ContextActionPriority.High.Value,
					Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.MouseWheel, Enum.UserInputType.Touch)
			else
				pcall(CAS.UnbindAction, CAS, "KLOSAD_Block")
			end
		end
	end)
end

function ui.unload()
	S.alive = false
	pcall(ctx.resetAll)
	pcall(function() -- ;nofog / ;time saved the original lighting too (resetAll only restores it for fullbright)
		for k, v in pairs(state.saved.light or {}) do ctx.Lighting[k] = v end
		state.saved.light = nil
	end)
	pcall(function() S.ContextActionService:UnbindAction("KLOSAD_Shift") end)
	pcall(function() S.ContextActionService:UnbindAction("KLOSAD_Block") end)
	for uid in pairs(state.listen) do pcall(ctx.setListen, uid, false) end
	for uid in pairs(state.vcVol or {}) do pcall(ctx.setVoiceVol, uid, 1) end
	pcall(ctx.vcClear)
	pcall(ctx.noStereo, false)
	pcall(ctx.crosshair, false)
	pcall(ctx.syncStop)
	pcall(ctx.SRV.cancelJoin, true) -- gives Roblox's prompt gui back if a join was still retrying
	pcall(function() ui.borderTween:Cancel() end)
	pcall(function() ui.glowTween:Cancel() end) -- endless tween: kept running after the gui was destroyed
	pcall(function() ui.orbitTween:Cancel() end)
	pcall(function() ui.busyTween:Cancel() end)
	for _, c in ipairs(S.cons) do pcall(function() c:Disconnect() end) end
	for k in pairs(state.conns) do ctx.disconnect(k) end
	for uid in pairs(state.muted) do pcall(ctx.setMuted, uid, false) end
	state.muted = {}
	if state.chat then state.chat.spam = false end
	pcall(function() -- hand the chat handler back to the game
		if S.chatPrev then S.TextChatService.OnIncomingMessage = S.chatPrev.fn end
	end)
	pcall(ctx.baseplate, false) -- the extra tiles are gone
	pcall(ui.closeProfile, true)
	S.panelOpen, S.barOpen = false, false
	ui.syncMouse()
	pcall(function() ui.blur:Destroy() end)
	pcall(function() gui:Destroy() end)
	if env.KLOSAD and env.KLOSAD.Unload == ui.unload then env.KLOSAD = nil end -- ;cleanup unloading an older run must not wipe this run's handle
	local i = env.KLOSAD_ALL and table.find(env.KLOSAD_ALL, ui.unload)
	if i then table.remove(env.KLOSAD_ALL, i) end
end

ui.apply()
do -- experience-specific keybind tabs: leave a tab that belongs to another experience, switch to the one made for this one
	local at = ctx.kbTab()
	if at and at.es and at.exp ~= game.GameId then cfg.kbActive = "default" end
	for _, x in ipairs(cfg.kbTabs) do
		if x.es and x.exp == game.GameId then cfg.kbActive = x.id; break end
	end
end
ui.selectTab("Home")
env.KLOSAD = { Unload = ui.unload, ctx = ctx, cfg = cfg, ui = ui, S = S, version = VERSION }
env.KLOSAD_BOOT = nil
env.KLOSAD_ALL = env.KLOSAD_ALL or {}
table.insert(env.KLOSAD_ALL, ui.unload)
if not (HAS_FS and HAS_LOAD) then ctx.notify("Limited mode: this executor has no file access or loadstring.", 5) end
ui.welcome()
if cfg.startBar then task.defer(function() ui.openBar() end) end
if cfg.autostart.onExec then task.delay(2, function() ctx.runAutostart("exec") end) end
-- [/ENTRY]
