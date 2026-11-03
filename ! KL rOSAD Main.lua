-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py). Markers use "--" (Lua), not "//".
-- [BOOT] version, DIR, env, wait for game/LocalPlayer/camera (autoexec), unload previous run | VERSION, DIR, env | deps: none | L82-90
-- [DATA] BUILTIN slots, GITHUB links, WELCOME/HOME_MSGS/TIPS text | BUILTIN, GITHUB, WELCOME, HOME_MSGS, TIPS | deps: BOOT | L92-213
-- [STATE] service cache S, settings load/save, cfg, MODDEF | S, cfg, DEFAULTS, save(), MODDEF, request, HAS_FS | deps: BOOT | L215-292
-- [THEME] colors, repaint registry, small helpers, tween | THEMES, col(), paint(), applyTheme(), esc(), hl(), new(), dur(), tw() (every duration x2), split(), score() | deps: STATE | L294-439
-- [CMD_CORE] ctx object, player find, hop, chat hook, mute, listen, bind tabs (bindList/addBind/editBind/fireBind, Ctrl+key combos, cycling), Run(), TOGGLES, META/TAGS, register, loadFolder | ctx, ctx.Run, ctx.add, ctx.register, ctx.setMuted, ctx.setListen, ctx.kbTab/bindTable/activeBinds, TOGGLES | deps: STATE, THEME | L441-925
-- [CMD_BUILTIN] small built-in command files (copyid, view, mute, noclip, esp, bind, loop...) | CMD[] | deps: CMD_CORE | L927-1672
-- [CMD_EXTRA] movement/defense/blink/names/mouse/tools/save/autoexec/autostart commands | def(), heada/backa (attach kinds, Module Cfg headXxx/backXxx keys), config/cfg (opens Module Cfg), removebaseplate/nobaseplate, crosshair (ctx.crosshair, Module Cfg chXxx keys), tetris/wwapf/tooleditor/klpfxp tool commands, listen/unlisten, nostereo/stereo (ctx.noStereo), refreshaudio/refreshdevices, float, fly, ragdoll, antifling, antisit/nosit (ctx.eject), clear/cls, blink/unghost, shiftlock, native streamer-others (ctx.streamOthers), ctx.lockFps, setAvc (event + CoreGui text fallback), TOOLS, openTool, setAutoExec, runAutostart | deps: CMD_CORE | L1674-3503
-- [UI_SHARED] gui root, widget builders, toast, welcome popup, HUD, entries/matches search, mouse sync | fr(), txt(), ripple(), btn() (accent hover/selected, press scale), input(), scroller(), seg(), ui.toast (progress line), ui.welcome, ui.showHud, ui.matches, ui.syncMouse | deps: THEME, CMD_CORE | L3505-3851
-- [UI_BAR] command bar, suggestions (scroll list grouped in sections, optional 3 columns), history | ui.openBar, ui.closeBar, ui.search, ui.sugRender, ui.complete, ui.moveH, ui.hold, tip popup, barFade (opacity fade) | deps: UI_SHARED | L3853-4272
-- [UI_PANEL] panel frame, drag, tabs, selectTab, setPanel | pages, tabs, onShow, ui.selectTab, ui.setPanel, panelFade (opacity fade) | deps: UI_SHARED | L4274-4406
-- [PG_HOME] Home page (stats+icon centered, experience name carry) | stats loop, bio, ctx.curExp | deps: UI_PANEL | L4408-4503
-- [PG_PLAYERS] Players page (3x2 buttons, Listen) | render(), copyable() | deps: UI_PANEL | L4505-4621
-- [PG_LOOK] Look and feel page | seg controls | deps: UI_PANEL | L4623-4653
-- [PG_SCRIPTS] Load scripts page | item(), ghInfo() | deps: UI_PANEL, DATA | L4655-4732
-- [PG_CMDS] Commands page | render() | deps: UI_PANEL | L4734-4763
-- [PG_FLOW] flow/fhdr/frow layout helpers for pages w/o slides | flow(), fhdr(), frow() | deps: UI_PANEL | L4765-4784
-- [PG_AUTOSTART] Autostart page (scripts + commands) | add(), QUICK, render() | deps: PG_FLOW | L4786-4907
-- [PG_KEYS] Keybinds page with tabs (none/default/custom, experience specific) | keyTile(), tabBtn(), card(), line(), rbtn(), New bind card on top, bind cards (key chip, 1 command per line, up/down/remove, ADD), expName() id->game name lookup, ui.refreshKeys | deps: PG_FLOW | L4909-5115
-- [PG_MODCFG] Module Cfg page | numRow(), strRow(), togRow(), optRow() | deps: PG_FLOW | L5117-5200
-- [PG_PREFS] Preferences page | refresh() | deps: PG_FLOW | L5202-5225
-- [ENTRY] apply settings, input wiring, unload, startup | ui.apply, ui.rescale, ui.unload, ui.syncShift, env.KLOSAD | deps: all | L5227-5343

--[[
	KL rOSAD v1.1  |  open-source admin/dev panel  |  client-side only

	CHANGELOG (newest first; every change adds a line here and updates the NAV INDEX, then navfix)
	v1.1  New ;refreshaudio / ;refreshdevices: re-scans the mic and speaker drivers and re-selects the default one, for when the audio settings only show "NoSound Driver"
	v1.1  Autoexec fix: the script now waits for the game, LocalPlayer and the camera before starting, so dropping KL_rOSAD.lua itself into the executor's autoexec folder works (it used to run too early and error out). Buttons: subtler sheen gradient, a bit darker fill
	v1.1  ;removebaseplate only removes the tiles ;baseplate added; the game's own baseplate can no longer be removed
	v1.1  ;removebaseplate: if ;baseplate added tiles it removes only those (the game's own baseplate stays); with no tiles it removes the game's baseplate
	v1.1  ;baseplate now always uses the standard Roblox baseplate look (grey plastic, studs on top) instead of copying the floor under you; ;removebaseplate also removes the tiles ;baseplate added
	v1.1  Crosshair (fixed at center mode): while fullscreen and the mouse is not locked to the center, the Roblox cursor is hidden; it comes back when the panel or command bar or the Roblox menu is open, in windowed mode, or when the crosshair is removed
	v1.1  New ;removebaseplate / ;nobaseplate: removes every part named Baseplate (client side only, rejoin to get it back)
	v1.1  Command bar: Space completes the suggested command name (same as Tab) and then types its space, so you can go straight to the arguments. Tab no longer leaves a stray tab/space in the text
	v1.1  ;backa now uses the standalone back attach script's values by default: distance 1.2, sweep on, amplitude 0.5, speed 20 (saved Back attach values are migrated once)
	v1.1  Keybinds: existing binds are editable. Click a command to retype it (Enter or click away saves, empty or unchanged reverts); click the keycap and press a new key to move the bind (joins the commands of that key if it already has some)
	v1.1  Keybinds page redesign: Hotkeys tiles (keycaps), "+ New tab", Add a bind form, bind cards with code pills. Open/close fade is now 2x faster (dur() doubles every duration, so the values are halved)
	v1.1  Panel tab indicator slides with Quart easing (no overshoot bounce)
	v1.1  Fix ;backa / ;heada: move in PreSimulation (no one frame lag) and turn off CanCollide on the whole character each frame (no more getting shoved by the target)
	v1.1  Command bar and panel fade in/out (CanvasGroup wrappers barFade/panelFade tween GroupTransparency together with the existing scale pop)
	v1.1  Suggestion bar: list 2px lower, hover highlights a row, Left/Right jump between columns, held arrows repeat, a cut-off row shows its full line in a small popup. Buttons (btnFill) a bit darker
	v1.1  New ;heada / ;headattach <player> and ;backa / ;backattach <player>: PlatformStand attach in front of the head / behind the back (jump or ;unattach detaches). Offsets and the front/back sweep live in Module Cfg (Head attach, Back attach)
	v1.1  New ;config / ;cfg: opens Module Cfg. ;arvc is an alias of ;arjvc and takes on / off
	v1.1  Autostart: commands can be added too (quick buttons like Anti ear rape and Auto rejoin on VC ban, or any command line); they run on exec and, with "After reset", after every respawn
	v1.1  UI: accent hints (panel edge, glow line, selected tab and buttons, input focus, scrollbars, bar, toast), click ripple, press scale, slide in pages, closing animation. Every animation is 2x longer (1.0x now lasts what 0.5x used to). Rows with a long label no longer run into their control
	v1.1  Keybinds: experience specific tabs show the game's name under the typed ID (cached in cfg.exp, looked up through the games API)
	v1.1  Fix: ;friend / ;unfriend now report errors and fall back to the SetCore prompts when SocialService refuses
	v1.1  Fix: ;streamermode now renames other players too (native: Player / Humanoid display names + every name in CoreGui and PlayerGui text); ;unstreamer restores them
	v1.1  Fix: ;fps keeps re-applying the cap (Heartbeat check every second + on window focus), ;fps off removes it, ;gamedefault stops the lock
	v1.1  Fix: UI keeps the same pixel size at any resolution (1080p stays the reference, no more height / 1080 zoom); only the UI Scaling setting changes it
	v1.1  Fix: auto rejoin on VC ban falls back to watching CoreGui for the suspension message when VoiceChatInternal can't be hooked (Potassium)
	v1.1  New ;listen <player> / ;unlisten [player] (same routing as the Players page Listen button; unlisten with no name stops all)
	v1.1  New ;nostereo / ;stereo: downmixes the voice chat listener to mono (everyone centered, proximity volume kept) and restores it
	v1.1  New ;crosshair / ;removecrosshair (nocrosshair): static CS style crosshair, Module Cfg has mode (Cross / T / Dot), length, gap, thickness, outline, outline opacity, colour and "Replace Roblox cursor" (off = fixed at screen center)
	v1.1  New tools in Load scripts + commands: Tetris (;tetris / ;untetris), WWA Phantom Forces (;workwellpf / ;wwapf), Tool Properties Editor (;properties / ;tooleditor), KL PF XP (;klpfxp / ;pfxp); all closable with ;kill <name>
	v1.1  Command bar: scrolling the full command list now groups commands in sections (Movement, Defense, Offense, Players, Voice, Camera, Visuals, Character, Privacy, Server, Tools, rOSAD, Other). Sections live in the CATS table in CMD_CORE
	v1.1  Preferences: "Command list: up to 3 columns" - the full list spreads over 1 to 3 columns depending on the screen width
	v1.1  Fix: antisit / ;unsit left you floating on clickable (welded) chairs. New ctx.eject removes the chair weld and jumps once; antisit now keeps its guard running even when the No Sit component loads
	v1.1  New ;clear / ;cls [effect]: clears movement effects (fly, noclip, float, speed, jump, gravity...) or only the named ones. ;nosit is now an alias of ;antisit
	v1.1  Keybinds layout: New bind card on top, key chip + command count in each card header, single-command binds drop numbers and arrows
	v1.1  ;noclip: ground safety (pulls you back to the last ground if you fall into the void / under the map), ;clip restores collision
	v1.1  Keybinds UI cleanup: one card per key, one command per line (numbered cycle order, up/down/remove), Enter adds, new bind box at the bottom
	v1.1  Keybinds: tabs (No Keybinds / Default / custom, + to add), custom tabs can be experience specific (typed id or Use current)
	v1.1  Home: experience name and icon carry over a teleport when the new place only says "Ugc"; stats + icon centered left of the divider
	v1.1  Sidebar tabs no longer overlap (35px tall); Players buttons 15% narrower (81px) in a 3-column grid; new Listen button
	v1.1  Panel / bar key set to a Shift key no longer toggles Roblox shift lock; new ;toggleshiftlock / shiftlock / shl; new ;unghost
	v1.1  Auto execute: no longer silent when it has no copy to load, loader logs its error, more autoexec folders tried

	WHERE TO PUT THINGS (search this file for ">>>"):
	  >>> BUILTIN   locked pre-installed scripts (Lighting Utility, Cobalt, Dex): paste the script between the markers
	  >>> GITHUB    your loadstring links: pin them to a commit hash, not "main"

	FOLDERS (in your executor's workspace, created for you):
	  KLOSAD/scripts    any .lua / .txt dropped here shows up under Load scripts > Local
	  KLOSAD/commands   extra command files (same format as the built-in ones), then type: reload
	  KLOSAD/settings.json   saved settings, binds and bio

	Command file format:  return function(ctx) return { names = {"x","alias"}, args = "[n]", desc = "...", run = function(n) end } end
]]

-- [BOOT]
local VERSION = "1.1"
local DIR = "KLOSAD"
local env = (getgenv and getgenv()) or _G
-- an autoexec folder runs this before the game is ready: lp, the camera and CoreGui are still nil, so half the script errored out. Wait first.
if not game:IsLoaded() then game.Loaded:Wait(); task.wait(1) end
repeat task.wait() until game:GetService("Players").LocalPlayer and workspace.CurrentCamera
if env.KLOSAD and env.KLOSAD.Unload then pcall(env.KLOSAD.Unload) end
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
local SELF_URL = ""

local ui = {}

local request = (syn and syn.request) or http_request or request
local HAS_FS = (readfile and writefile and listfiles and isfolder and makefolder) and true or false
local HAS_LOAD = pcall(function() return loadstring("return 1")() end)

-- ===== settings ============================================================
local DEFAULTS = {
	theme = "Dark", opacity = 0.8, accent = "#FFFF00", anim = 1, scale = 1,
	lines = 12, blur = 1, pos = "Center", barKey = "Semicolon", panelKey = "RightShift",
	toasts = true, bio = "", binds = {}, autoExec = false, avc = false, mod = {}, exp = {}, hist = {}, startBar = true, autostart = {},
	kbTabs = {}, kbActive = "default", expIcon = {}, carry = {}, sugCols = false,
}
local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end
cfg.binds = {}
cfg.mod = {}
cfg.exp = {}
cfg.hist = {}
cfg.kbTabs = {}
cfg.expIcon = {}
cfg.carry = {}
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
	bpDist = 1.5, bpHeight = 0.5, babyDist = 2.2, babyHeight = 0.5, babyRot = 35,
	afRadius = 15, afThreshold = 120, afRestore = 1.5, atpMin = 40, akMax = 80, aeThreshold = 500, aeDuration = 2,
	afkInterval = 60, spamCount = 3, avHeight = 50, defNotify = true,
	floatStep = 3, ragHead = true, ragTorso = true, ragLeftArm = true, ragRightArm = true, ragLeftLeg = true, ragRightLeg = true,
	chStyle = "Cross", chLen = 6, chGap = 4, chThick = 2, chOutline = 1, chOutlineAlpha = 1, chColor = "#00FF00", chCursor = false,
	headDist = 1.5, headHeight = 1.5, headSide = 0, headSweep = true, headSweepAmp = 0.5, headSweepSpeed = 10,
	backDist = 1.2, backHeight = 0.5, backSide = 0, backSweep = true, backSweepAmp = 0.5, backSweepSpeed = 20,
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
	Dark = { panel = rgb(13, 13, 13), panelEdge = rgb(70, 67, 67), inner = rgb(24, 23, 23), edge = rgb(88, 84, 84), bar = rgb(24, 23, 23),
		tabOn = rgb(118, 113, 113), tabOff = rgb(0, 0, 0), row = rgb(59, 56, 56), ctrlOn = rgb(118, 113, 113), ctrlOff = rgb(52, 50, 50),
		btnFill = rgb(40, 38, 38), text = rgb(255, 255, 255), text2 = rgb(231, 230, 230), sub = rgb(175, 171, 171),
		dim = rgb(118, 113, 113), hint = rgb(128, 128, 128), line = rgb(118, 113, 113) },
	Light = { panel = rgb(242, 242, 242), panelEdge = rgb(242, 242, 242), inner = rgb(231, 230, 230), edge = rgb(158, 155, 155), bar = rgb(231, 230, 230),
		tabOn = rgb(138, 134, 134), tabOff = rgb(255, 255, 255), row = rgb(191, 191, 191), ctrlOn = rgb(138, 134, 134), ctrlOff = rgb(250, 250, 250),
		btnFill = rgb(214, 213, 213), text = rgb(13, 13, 13), text2 = rgb(31, 31, 31), sub = rgb(84, 81, 81),
		dim = rgb(107, 103, 103), hint = rgb(107, 103, 103), line = rgb(138, 134, 134) },
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
	return THEMES[cfg.theme][key]
end

-- every themed property is registered here so theme/accent changes repaint live (weak keys: destroyed rows vanish)
local themed = {}
local function paint(inst, prop, key)
	local t = themed[inst]
	if not t then t = {}; themed[inst] = t end
	t[prop] = key
	inst[prop] = col(key)
end
local function applyTheme()
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
local function dur(t) return cfg.anim == 0 and 0 or (t or 0.15) * 2 / cfg.anim end
local function tw(inst, props, t, style)
	if cfg.anim == 0 then
		for k, v in pairs(props) do inst[k] = v end
		return
	end
	S.TweenService:Create(inst, TweenInfo.new(dur(t), style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
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

function ctx.connect(key, signal, fn)
	if state.conns[key] then state.conns[key]:Disconnect() end
	state.conns[key] = signal:Connect(fn)
end
function ctx.disconnect(key)
	if state.conns[key] then state.conns[key]:Disconnect(); state.conns[key] = nil end
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
	for _, p in ipairs(all) do
		if p.Name:lower() == q or p.DisplayName:lower() == q then return { p } end
	end
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
		local okp, prev = pcall(function() return TCS.OnIncomingMessage end)
		S.chatPrev = { ok = okp, fn = prev }
		TCS.OnIncomingMessage = function(msg)
			local props = (okp and type(prev) == "function" and prev(msg)) or Instance.new("TextChatMessageProperties")
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
			if w:IsA("Wire") and w.SourceInstance == rec.dev and w.TargetInstance ~= rec.out and rec.wires[w] == nil then
				rec.wires[w] = w.Enabled
				w.Enabled = false
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
		local w = Instance.new("Wire")
		w.SourceInstance, w.TargetInstance, w.Parent = dev, out, out
		state.listen[uid] = { out = out, dev = dev, wires = {} }
	end)
	if not ok then return false, "Couldn't create the audio route in this executor" end
	if not S.listenLoop then
		S.listenLoop = true
		task.spawn(function() -- re-silences the game's own wires if they are recreated (respawn)
			while S.alive and next(state.listen) do
				for id, r in pairs(state.listen) do pcall(quietWires, id, r) end
				task.wait(2)
			end
			S.listenLoop = false
		end)
	end
	return true
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
	lockmouse = "unlockmouse", ctrllock = "unctrllock", showfps = "unshowfps",
}
-- commands that flip themselves on and off and keep state.active up to date on their own
local SELF = { float = true, blink = true, ghost = true }

function ctx.resetAll()
	state.loopGen = state.loopGen + 1
	state.loopOf = {}
	for on in pairs(state.active) do
		state.active[on] = nil
		if TOGGLES[on] then pcall(ctx.Run, TOGGLES[on]) end
	end
end

function ctx.add(names, fn)
	if type(names) == "string" then names = { names } end
	ctx.Commands[names[1]] = fn
	for _, n in ipairs(names) do ctx.Aliases[n] = names[1] end
end

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
	if SELF[cmd] then return end
	if TOGGLES[cmd] then
		state.active[cmd] = true
	else
		for on, off in pairs(TOGGLES) do
			if off == cmd then state.active[on] = nil end
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
	friend = { "<player>", "Open the friend request prompt" }, unfriend = { "<player>", "Open the unfriend prompt" },
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
	Movement = "float unfloat cfly uncfly fly unfly jesus unjesus tpwalk untpwalk hheight follow unfollow sit unsit ragdoll unragdoll spin unspin speed jumppower goto tpto mousetp freeze thaw infjump uninfjump noclip clip blink unblink ghost gravity clear",
	Defense = "antifling unantifling antisit unantisit antivoid unantivoid antiteleport unantiteleport antiknockback unantiknockback antiattach unantiattach antiearrape unantiearrape antiblur unantiblur antiafk unantiafk antispam unantispam antifreeze unantifreeze",
	Offense = "backpack baby headsit heada backa unattach",
	Players = "view unview userinfo copyid profile players friend unfriend block unblock",
	Voice = "mute unmute listen unlisten nostereo stereo refreshaudio arjvc",
	Camera = "fov maxzoom minzoom freecam lockmouse unlockmouse enableshiftlock ctrllock unctrllock toggleshiftlock crosshair removecrosshair",
	Visuals = "fullbright unfullbright esp unesp xray unxray nofog time showfps unshowfps baseplate removebaseplate",
	Character = "reset anim noanim invisible visible",
	Privacy = "streamer unstreamer name unname",
	Server = "serverhop smallserver serverinfo rejoin jobid placeid",
	Tools = "hlxp liu dex cobalt kelsec rspy alogger workwell tetris untetris workwellpf properties tooleditor klpfxp kill saveinstance freezesave tools console",
	rOSAD = "ui exit cmds config keeposad unkeeposad alias bind unbind loop unloop breakloop prefix fpscap gamedefault text stopall reload panel selftest",
}
ctx.catOf = {}
for cat, names in pairs(CATS) do
	for w in names:gmatch("%S+") do ctx.catOf[w] = cat end
end

function ctx.register(factory)
	local ok, mod = pcall(factory, ctx)
	if not ok or type(mod) ~= "table" or not mod.names then
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
mini({ "unloop" }, function() state.loopGen = state.loopGen + 1 end)
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
	local findPlayer, state = ctx.findPlayer, ctx.state

	return {
		names = { "view", "spectate" },
		run = function(q)
			local p = findPlayer(q)
			local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if h then
				workspace.CurrentCamera.CameraSubject = h
				state.viewing = p
			end
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
			local p = findPlayer(q)
			if not p then return ctx.notify("Player not found") end
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
		names = { "serverhop", "shop" },
		run = function()
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
				nc.safe = nil
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
			cam.FieldOfView = tonumber(n) or 70
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
-- Now it remembers the last spot with ground under you and pulls you back if you fall into nothing; clip restores collision.
return function(ctx)
	local connect, RunService, char = ctx.connect, ctx.RunService, ctx.char
	local nc = { orig = {} } -- orig = each part's CanCollide from before noclip, safe = last CFrame that had ground below
	ctx.nc = nc
	local rp = RaycastParams.new()
	rp.FilterType, rp.RespectCanCollide = Enum.RaycastFilterType.Exclude, true -- same rule the Humanoid's floor check uses

	return {
		names = { "noclip" },
		run = function()
			nc.safe = nil
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
			connect("noclip_safe", RunService.Heartbeat, function()
				local c = char()
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if not (hrp and hum) then return end
				rp.FilterDescendantsInstances = { c }
				local pos, vy = hrp.Position, hrp.AssemblyLinearVelocity.Y
				if not nc.safe then nc.safe = hrp.CFrame end
				local reach = hum.HipHeight + hrp.Size.Y / 2 + 3
				if workspace:Raycast(pos, Vector3.new(0, -reach, 0), rp) and math.abs(vy) < 30 then
					nc.safe = hrp.CFrame -- ground right under you and not mid-fall: remember this spot
				end
				local fh = workspace.FallenPartsDestroyHeight
				local void = fh > -1e6 and pos.Y < fh + 100 -- about to be killed by the map's kill height
				local sunk = pos.Y < nc.safe.Position.Y - 25 and vy < -20
					and not workspace:Raycast(pos, Vector3.new(0, -3000, 0), rp) -- falling with nothing below at all
				if void or sunk then
					ctx.markMove()
					hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
					hrp.CFrame = nc.safe + Vector3.new(0, 3, 0)
					if os.clock() - (nc.warned or 0) > 3 then
						nc.warned = os.clock()
						ctx.notify("Noclip: nothing under you, moved you back to the last ground")
					end
				end
			end)
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
					if v.Name ~= "HumanoidRootPart" then v.Transparency = 1 end
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
			for _, t in ipairs(lp.Backpack:GetChildren()) do names[#names + 1] = t.Name end
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
			if not char() then return end
			for _, v in ipairs(char():GetDescendants()) do
				if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
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
		tl.Text = p.DisplayName
		bb.Adornee = p.Character:FindFirstChild("Head"); bb.Parent = p.Character
		state.esp[p] = { hl, bb }
	end

	local function watch(p)
		if p == lp then return end
		connect("espChar_" .. p.UserId, p.CharacterAdded, function()
			task.wait(0.5)
			tag(p)
		end)
	end

	return {
		names = { "esp" },
		run = function()
			for _, p in ipairs(Players:GetPlayers()) do tag(p); watch(p) end
			connect("espAdd", Players.PlayerAdded, watch)
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
			disconnect("espAdd")
			for k in pairs(state.conns) do
				if k:find("^espChar_") then disconnect(k) end
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
				if v:IsA("BasePart") and not v:IsDescendantOf(char() or workspace) and not v.Parent:FindFirstChildOfClass("Humanoid") then
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
			if new and canon then Aliases[new:lower()] = canon else ctx.notify("Usage: alias <new> <command>") end
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
	state.floatY = fy
	if not state.floatPart then
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.Transparency, p.Size = "_float", true, false, 1, Vector3.new(8, 1, 8)
		p.Parent = workspace
		state.floatPart = p
	end
	ctx.connect("float", RS.Heartbeat, function(dt)
		local r, h, p = ctx.root(), ctx.hum(), state.floatPart
		if not (r and h and p and p.Parent) then return end
		if down(Enum.KeyCode.E) then state.floatY = state.floatY + 24 * dt end
		if down(Enum.KeyCode.Q) then state.floatY = state.floatY - 24 * dt end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { ctx.char(), p }
		local hit = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), params)
		local groundY = hit and hit.Position.Y or -math.huge
		local cur = feetY()
		-- standing on real ground (a stair you dropped onto, a hill): that is the new level
		if hit and cur and h.FloorMaterial ~= Enum.Material.Air and math.abs(cur - groundY) < 1.5 then state.floatY = groundY end
		p.CFrame = CFrame.new(r.Position.X, state.floatY - 0.5, r.Position.Z)
		p.CanCollide = (state.floatY - groundY) > mod.floatStep
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
	ctx.connect("attach", ps and RS.PreSimulation or RS.Heartbeat, function()
		local r, tc = ctx.root(), p.Character
		local tt = tc and (tc:FindFirstChild("UpperTorso") or tc:FindFirstChild("Torso") or tc:FindFirstChild("HumanoidRootPart"))
		if not (r and tt) then return end
		local cf
		if kind == "backpack" then
			cf = tt.CFrame * CFrame.new(0, mod.bpHeight, tonumber(off) or mod.bpDist) * CFrame.Angles(0, math.pi, 0)
		elseif kind == "baby" then
			cf = tt.CFrame * CFrame.new(0, mod.babyHeight, -(tonumber(off) or mod.babyDist)) * CFrame.Angles(0, math.rad(180 + mod.babyRot), 0)
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

-- true ragdoll: every joint of an enabled limb (Module Cfg) is swapped for a ball socket, so the limb really goes limp
local RAG = {
	head = { Neck = 1 }, torso = { Waist = 1 },
	leftArm = { LeftShoulder = 1, LeftElbow = 1, LeftWrist = 1, ["Left Shoulder"] = 1 },
	rightArm = { RightShoulder = 1, RightElbow = 1, RightWrist = 1, ["Right Shoulder"] = 1 },
	leftLeg = { LeftHip = 1, LeftKnee = 1, LeftAnkle = 1, ["Left Hip"] = 1 },
	rightLeg = { RightHip = 1, RightKnee = 1, RightAnkle = 1, ["Right Hip"] = 1 },
}
local RAGKEY = { head = "ragHead", torso = "ragTorso", leftArm = "ragLeftArm", rightArm = "ragRightArm", leftLeg = "ragLeftLeg", rightLeg = "ragRightLeg" }
local function ragGroup(jointName)
	for g, set in pairs(RAG) do
		if set[jointName] then return g end
	end
end
def({ "ragdoll", "rag" }, "", "Ragdoll until you press space or move (limbs picked in Module Cfg)", "fall limp physics", function()
	local h, c = ctx.hum(), ctx.char()
	if not (h and c) then return end
	if state.ragdollStop then state.ragdollStop() end
	h:ChangeState(Enum.HumanoidStateType.Physics)
	local undo, neck = {}, h.RequiresNeck
	h.RequiresNeck = false -- a loose neck must not kill you
	for _, m in ipairs(c:GetDescendants()) do
		local g = m:IsA("Motor6D") and ragGroup(m.Name)
		if g and mod[RAGKEY[g]] and m.Part0 and m.Part1 then
			local a0, a1, bs = Instance.new("Attachment"), Instance.new("Attachment"), Instance.new("BallSocketConstraint")
			a0.Name, a0.CFrame, a0.Parent = "_RagA0", m.C0, m.Part0
			a1.Name, a1.CFrame, a1.Parent = "_RagA1", m.C1, m.Part1
			bs.Name, bs.Attachment0, bs.Attachment1 = "_RagBS", a0, a1
			bs.LimitsEnabled, bs.UpperAngle = true, (g == "head") and 45 or 80
			bs.TwistLimitsEnabled, bs.TwistLowerAngle, bs.TwistUpperAngle = true, -45, 45
			bs.Parent = m.Part0
			local was = m.Part1.CanCollide
			m.Part1.CanCollide = true
			if pcall(function() m.Enabled = false end) then
				undo[#undo + 1] = { m = m, a0 = a0, a1 = a1, bs = bs, part = m.Part1, was = was }
			else
				a0:Destroy(); a1:Destroy(); bs:Destroy()
				m.Part1.CanCollide = was
			end
		end
	end
	if mod.ragdollBlock then
		pcall(function() ctx.StarterGui:SetCore("ResetButtonCallback", false) end)
		state.resetBlocked = true
	end
	local function stop()
		ctx.disconnect("ragdoll"); ctx.disconnect("ragdollJump")
		for _, u in ipairs(undo) do
			pcall(function() u.m.Enabled = true end)
			pcall(function() u.bs:Destroy(); u.a0:Destroy(); u.a1:Destroy(); u.part.CanCollide = u.was end)
		end
		local hh = ctx.hum()
		if hh then hh.RequiresNeck = neck; hh:ChangeState(Enum.HumanoidStateType.GettingUp) end
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
		if hh:GetState() ~= Enum.HumanoidStateType.Physics then hh:ChangeState(Enum.HumanoidStateType.Physics) end
	end)
end)
def({ "unragdoll", "unrag" }, "", "Get up from ragdoll", "fall limp physics", function() if state.ragdollStop then state.ragdollStop() end end)

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
	local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if r and ctx.root() then ctx.markMove(); ctx.root().CFrame = r.CFrame * CFrame.new(0, 0, 3) end
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
	function ctx.lockFps(n)
		target = n
		ctx.disconnect("fpsLock"); ctx.disconnect("fpsFocus")
		if not n then return end
		pcall(setfpscap, n)
		ctx.connect("fpsLock", RS.Heartbeat, function()
			local t = os.clock()
			if t - last < 1 then return end
			last = t
			if getfpscap then
				local ok, cur = pcall(getfpscap)
				if ok and type(cur) == "number" and math.abs(cur - target) < 0.5 then return end
			end
			pcall(setfpscap, target)
		end)
		ctx.connect("fpsFocus", UIS.WindowFocused, function() pcall(setfpscap, target) end)
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
		local fn = loadstring(body)
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
		if r and r.Anchored and not state.selfFrozen and not state.blink then
			r.Anchored = false
			dnotify("freeze", "Anti freeze: un-anchored you")
		end
	end)
end)
def({ "unantifreeze" }, "", "Turn anti freeze off", "anchor stuck lock", function() ctx.disconnect("antifreeze") end)

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
		if t == "" then return end
		local new = t
		for p, r in pairs(SO.real) do
			for _, nm in ipairs(r) do
				if #nm >= 3 and new:find(nm, 1, true) then
					new = new:gsub((nm:gsub("%p", "%%%0")), (SO.map[p]:gsub("%%", "%%%%")))
				end
			end
		end
		if new ~= t then
			if SO.txt[o] == nil then SO.txt[o] = t end
			o.Text = new
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
					SO.map[p] = nil
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
-- "Replace Roblox cursor" on: the crosshair follows the mouse and the real cursor is hidden. Off: fixed at the screen center, and the real cursor is hidden while fullscreen and not locked to the center.
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
		local rects = {}
		if M.chStyle == "Dot" then
			rects[1] = { -h1, -h1, th, th }
		elseif len > 0 then
			rects[#rects + 1] = { -h1, gap, th, len } -- bottom
			rects[#rects + 1] = { -(gap + len), -h1, len, th } -- left
			rects[#rects + 1] = { gap, -h1, len, th } -- right
			if M.chStyle ~= "T" then rects[#rects + 1] = { -h1, -(gap + len), th, len } end -- top (a T has none)
		end
		CH.root:ClearAllChildren()
		if ol > 0 and oa > 0 then
			for _, r in ipairs(rects) do rect(CH.root, r[1] - ol, r[2] - ol, r[3] + ol * 2, r[4] + ol * 2, rgb(0, 0, 0), oa, 1) end
		end
		for _, r in ipairs(rects) do rect(CH.root, r[1], r[2], r[3], r[4], col, 1, 2) end
	end
	local GuiService = game:GetService("GuiService")
	local function inFull() -- false if the engine refuses the call
		local ok, v = pcall(function() return UserSettings():GetService("UserGameSettings"):InFullScreen() end)
		return ok and v == true
	end
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
			ctx.connect("chFollow", RS.RenderStepped, function() -- the cursor would only sit next to the fixed crosshair
				local hide = inFull() and UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter and not S.mouseFree and not GuiService.MenuIsOpen
				if hide then
					if CH.prevIcon == nil then CH.prevIcon = UIS.MouseIconEnabled end
					UIS.MouseIconEnabled = false
				elseif CH.prevIcon ~= nil then
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
		if CH.gui and tostring(key):match("^ch%u") then build(); place() end
	end
end
def({ "crosshair", "xhair" }, "", "Show a static CS style crosshair (mode, length, gap, thickness, outline, colour in Module Cfg)", "aim reticle cs dot", function()
	ctx.crosshair(true)
end)
def({ "removecrosshair", "nocrosshair", "uncrosshair" }, "", "Remove the crosshair", "aim reticle cs", function()
	ctx.crosshair(false)
	ctx.notify("Crosshair removed")
end)

-- ===== PERFORMANCE / DISPLAY =====
def({ "showfps", "showperf", "showping" }, "", "Show FPS and ping in a corner (corner set in Module Cfg)", "performance frame rate latency overlay", function()
	if ui.showHud then ui.showHud(true) end
	active("showfps", true)
end)
def({ "unshowfps", "hidefps", "unshowping", "hideping", "unshowperf", "hideperf" }, "", "Hide the FPS / ping overlay", "performance overlay", function()
	if ui.showHud then ui.showHud(false) end
	active("showfps", nil)
end)

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
	local MOVE = { "fly", "cfly", "noclip", "float", "jesus", "tpwalk", "infjump", "spin", "freeze", "follow" }
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
def({ "baseplate" }, "", "Extend the baseplate in MIC UP / MIC UP 18+ (stand on it first)", "map floor ground mic up", function()
	if not (MICUP[game.PlaceId] or tostring(game.Name):lower():find("mic up", 1, true)) then
		return ctx.notify("baseplate only works in MIC UP and MIC UP 18+ (this is place " .. game.PlaceId .. ")", 5)
	end
	local r = ctx.root()
	if not r then return end
	for _, p in ipairs(state.baseParts or {}) do p:Destroy() end
	state.baseParts = {}
	-- no guessing the name of the game's baseplate: only the height of whatever you are standing on is used
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ctx.char() }
	local hit = workspace:Raycast(r.Position, Vector3.new(0, -300, 0), params)
	if not hit then return ctx.notify("Stand on the baseplate first, then run baseplate", 5) end
	-- standard Roblox baseplate look, whatever the floor is made of.
	-- a part can't be wider than 2048 studs, so it is a 3x3 tile around you; the top sits 0.05 under the real floor (no z-fighting)
	local top = hit.Position.Y - 0.05
	for dx = -1, 1 do
		for dz = -1, 1 do
			local p = Instance.new("Part")
			p.Name, p.Anchored, p.Material, p.Color = "_baseplateExt", true, Enum.Material.Plastic, rgb(99, 95, 98)
			p.Size = Vector3.new(2048, 4, 2048)
			p.Position = Vector3.new(r.Position.X + dx * 2048, top - 2, r.Position.Z + dz * 2048)
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
			p.Parent = workspace
			state.baseParts[#state.baseParts + 1] = p
		end
	end
	ctx.notify("Baseplate extended (only you can see and stand on it)")
end)

def({ "removebaseplate", "nobaseplate" }, "", "Remove the baseplate that ;baseplate added (never the game's own)", "map floor ground delete void", function()
	local ext = state.baseParts or {}
	if #ext == 0 then return ctx.notify("No extended baseplate to remove") end
	for _, p in ipairs(ext) do pcall(p.Destroy, p) end -- only our own tiles, never anything the game made
	state.baseParts = {}
	ctx.notify("Removed the extended baseplate")
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
					if nm:find(w, 1, true) then pcall(function() g:Destroy() end); n = n + 1; break end
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
-- The loader that gets queued / dropped in the autoexec folder. It runs KLOSAD/KL_rOSAD.lua, or SELF_URL if there is no local copy.
local function loaderLine()
	return ('if not game:IsLoaded() then game.Loaded:Wait() end task.wait(1) local ok, e = pcall(function() local p = "%s/KL_rOSAD.lua" if isfile and isfile(p) then loadstring(readfile(p))() elseif "%s" ~= "" then loadstring(game:HttpGet("%s"))() else error("no copy of KL_rOSAD.lua in " .. p) end end) if not ok then warn("[KLOSAD autoexec] " .. tostring(e)) end'):format(DIR, SELF_URL, SELF_URL)
end
-- The loader needs this script on disk. If KLOSAD/KL_rOSAD.lua is missing, look for a copy anywhere in the workspace and put it there.
local function ensureCopy()
	local path = DIR .. "/KL_rOSAD.lua"
	if not (isfile and writefile and readfile and listfiles and isfolder) then return false end
	if isfile(path) then return true end
	local checked = 0
	local function scan(dir, depth)
		local ok, files = pcall(listfiles, dir)
		if not ok then return false end
		for _, f in ipairs(files) do
			if isfolder(f) then
				if depth < 2 and scan(f, depth + 1) then return true end
			elseif f:sub(-4) == ".lua" and checked < 300 then
				checked = checked + 1
				local rok, body = pcall(readfile, f)
				if rok and type(body) == "string" and body:find("KL rOSAD v", 1, true) and body:find("open-source admin/dev panel", 1, true) and body:find("local BUILTIN", 1, true) then
					pcall(function()
						if makefolder and not isfolder(DIR) then makefolder(DIR) end
						writefile(path, body)
					end)
					return isfile(path)
				end
			end
		end
		return false
	end
	return scan("", 0) or scan(".", 0)
end
local AUTOPATHS = { "../autoexec/KLOSAD_autoload.lua", "autoexec/KLOSAD_autoload.lua", "../../autoexec/KLOSAD_autoload.lua",
	"../autoexecute/KLOSAD_autoload.lua", "autoexecute/KLOSAD_autoload.lua", "../Autoexecute/KLOSAD_autoload.lua", "../Autoexec/KLOSAD_autoload.lua" }
function ctx.setAutoExec(on, quiet)
	cfg.autoExec = on and true or false
	save()
	ctx.disconnect("autoTp")
	if on then
		local have = ensureCopy() or SELF_URL ~= ""
		local line = loaderLine()
		local queued = queue_on_teleport and pcall(queue_on_teleport, line) -- covers server hops, rejoins and teleports
		-- queue_on_teleport only lasts for the next teleport and some executors drop it: queue again the moment a teleport starts
		if queue_on_teleport then
			ctx.connect("autoTp", lp.OnTeleport, function() pcall(queue_on_teleport, loaderLine()) end)
		end
		local placed = false -- covers joining from the website: the executor's own autoexec folder
		if writefile then
			pcall(function()
				if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
				writefile(DIR .. "/KLOSAD_autoload.lua", line)
			end)
			for _, p in ipairs(AUTOPATHS) do
				if pcall(writefile, p, line) then placed = true end
			end
		end
		if quiet and have then return end
		if not have then
			ctx.notify("Auto execute can't find a copy of this script. Save it as " .. DIR .. "/KL_rOSAD.lua, or set SELF_URL", 8)
		elseif queued and placed then
			ctx.notify("Auto execute on: it runs after hops, rejoins and joins")
		elseif queued then
			ctx.notify("Auto execute on for hops and teleports. To also run on join, copy " .. DIR .. "/KLOSAD_autoload.lua into your executor's autoexec folder", 9)
		else
			ctx.notify("This executor has no queue_on_teleport. Copy " .. DIR .. "/KLOSAD_autoload.lua into its autoexec folder", 8)
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
			if avcTimer == my and cfg.avc then avcTimer = nil; ctx.Run("rejoin") end
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
	-- 2) fallback: watch CoreGui for Roblox's own "voice chat suspended" message (chat messages are ignored)
	if not how then
		pcall(function()
			local cg = game:GetService("CoreGui")
			local function look(o)
				if not (o:IsA("TextLabel") or o:IsA("TextButton")) or not o.Parent then return end
				if o:FindFirstAncestor("KLOSAD") or o:FindFirstAncestor("ExperienceChat") or o:FindFirstAncestor("Chat") then return end
				local t = o.Text:lower()
				if t:find("voice chat", 1, true) and (t:find("suspend", 1, true) or t:find("banned", 1, true)) then banned() end
			end
			ctx.connect("avc", cg.DescendantAdded, function(o) task.delay(0.3, look, o) end)
			how = "UI watch"
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
function ctx.autoRun(it)
	if it.kind == "cmd" then return task.spawn(ctx.Run, it.ref) end -- a command line, e.g. "antiearrape"
	local key = ctx.toolKey[it.name]
	if key then return ctx.openTool(key) end -- known tools go through the same loader as ;dex etc., so a second run just reopens
	task.spawn(function()
		local src, err = autoSource(it)
		if src then ctx.runSource(src, it.name) else ctx.notify("Autostart " .. it.name .. ": " .. tostring(err or "failed"), 5) end
	end)
end
function ctx.runAutostart(reason)
	for _, it in ipairs(cfg.autostart.items) do
		if reason == "exec" or it.respawn then ctx.autoRun(it) end
	end
end
ctx.connect("autoRespawn", lp.CharacterAdded, function()
	task.wait(1)
	ctx.runAutostart("respawn")
end)
if cfg.autoExec then task.defer(function() ctx.setAutoExec(true, true) end) end
if cfg.avc then task.defer(function() ctx.setAvc(true, true) end) end
end

-- extra command files from KLOSAD/commands (same format, override built-ins with the same name)
ctx.loadFolder(DIR .. "/commands")
-- [/CMD_EXTRA]

-- [UI_SHARED]
-- ===== UI: shared pieces ===================================================
-- Everything below is laid out in the reference deck's own 1080p pixels (panel 685x443, bar 647x51).
-- ui.rescale() zooms it to the real screen, so at 1080p / 100% it matches the reference 1:1.
-- fs(): pt -> px at 1080p, nudged 8% up because Source Sans runs a little smaller than Bahnschrift at the same size.
local function fs(pt) return math.floor(pt * 4 / 3 * 1.08 + 0.5) end
local FONT, FONT_B, FONT_CODE = Enum.Font.SourceSans, Enum.Font.SourceSansSemibold, Enum.Font.Code
local BTN_ON, BTN_OFF = 0.2, 0.4 -- fill transparency of a selected / normal button

local gui = new("ScreenGui", { Name = "KLOSAD", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
pcall(function() gui.Parent = S.CoreGui end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
ui.gui = gui
ui.blur = new("BlurEffect", { Name = "KLOSAD_Blur", Size = 0 }, S.Lighting)

local ord = 0
local function nx() ord = ord + 1; return ord end

-- frame at design-pixel position; fillKey nil = no fill
local function fr(parent, x, y, w, h, fillKey, tr, r, strokeKey, st, str)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0,
		BackgroundTransparency = fillKey and tr or 1 }, parent)
	if fillKey then paint(f, "BackgroundColor3", fillKey) end
	if r then new("UICorner", { CornerRadius = UDim.new(0, r) }, f) end
	if strokeKey then
		paint(new("UIStroke", { Thickness = st or 1, Transparency = str or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f), "Color", strokeKey)
	end
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
local function setFill(b, key, tr)
	local on = key == "ctrlOn" -- selected = accent tinted fill + accent edge
	if on then tr = 0.78 end
	paint(b, "BackgroundColor3", on and "accent" or key)
	b:SetAttribute("base", tr)
	b:SetAttribute("on", on)
	b.BackgroundTransparency = tr
	local st = b:FindFirstChildOfClass("UIStroke")
	if st then paint(st, "Color", on and "accent" or "edge") end
end
-- reference button: 1px edge, ~3px corners, text 9pt, label centred. Hover and press are animated.
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
-- button: 1px edge (accent on hover / when selected), 5px corners, top sheen, press shrinks it, click ripples
local function btn(parent, str, x, y, w, h, key, tr, cb, pt)
	local b = new("TextButton", { Text = str, TextSize = fs(pt or 9), Font = FONT, AutoButtonColor = false, BorderSizePixel = 0, ClipsDescendants = true,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
	paint(b, "TextColor3", "text")
	setFill(b, key or "btnFill", key and tr or BTN_OFF)
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
	local stroke = new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	paint(stroke, "Color", b:GetAttribute("on") and "accent" or "edge")
	local sheen = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, b)
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, sheen)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.94, 1) }, sheen)
	local sc = new("UIScale", {}, b)
	local function edge(hot) tw(stroke, { Color = col((hot or b:GetAttribute("on")) and "accent" or "edge") }, 0.1) end
	b.MouseEnter:Connect(function()
		if b.Active then
			tw(b, { BackgroundTransparency = math.max(b:GetAttribute("base") - 0.15, 0) }, 0.1)
			edge(true)
		end
	end)
	b.MouseLeave:Connect(function()
		tw(b, { BackgroundTransparency = b:GetAttribute("base") }, 0.12)
		tw(sc, { Scale = 1 }, 0.1)
		edge(false)
	end)
	b.MouseButton1Down:Connect(function()
		if b.Active then
			tw(b, { BackgroundTransparency = math.max(b:GetAttribute("base") - 0.3, 0) }, 0.05)
			tw(sc, { Scale = 0.95 }, 0.06)
		end
	end)
	b.MouseButton1Up:Connect(function() tw(sc, { Scale = 1 }, 0.1, Enum.EasingStyle.Back) end)
	b.MouseButton1Click:Connect(function()
		if b.Active then
			ripple(b)
			tw(b, { BackgroundTransparency = math.max(b:GetAttribute("base") - 0.15, 0) }, 0.1)
			cb(b)
		end
	end)
	return b
end
-- reference text field: 1px edge, 5px corners, 10px left inset. The styled Frame holds a plain TextBox, because
-- UIPadding / UIStroke on the TextBox itself shifts the caret. Returns the TextBox; its Frame is o.Parent.
local function input(parent, ph, x, y, w, h, pt, fillKey, tr, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0, BackgroundTransparency = tr or BTN_OFF }, parent)
	paint(f, "BackgroundColor3", fillKey or "ctrlOff")
	new("UICorner", { CornerRadius = UDim.new(0, 5) }, f)
	local stroke = new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	paint(stroke, "Color", "edge")
	local o = new("TextBox", mix({ BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", PlaceholderText = ph, ClearTextOnFocus = false, Font = FONT,
		TextSize = fs(pt or 11), TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0) }, props), f)
	paint(o, "TextColor3", "text"); paint(o, "PlaceholderColor3", "hint")
	o.Focused:Connect(function() paint(stroke, "Color", "accent") end)
	o.FocusLost:Connect(function() paint(stroke, "Color", "edge") end)
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
		if c:IsA("GuiObject") then c:Destroy() end
	end
end
local function empty(parent, str)
	local f = new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, LayoutOrder = nx() }, parent)
	txt(f, str, 10, "sub", 17, 14, 480, 34, { TextWrapped = true })
end
local function thumb(kind, id, size) return ("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(kind, id, size, size) end
local function conn(signal, fn) S.cons[#S.cons + 1] = signal:Connect(fn) end

-- segmented control: one reference button per option, selected = lighter fill. tbl defaults to cfg; after() runs on change.
local function seg(parent, y, xs, w, opts, key, after, tbl)
	tbl = tbl or cfg
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
	local id = 0
	function ui.toast(msg, secs)
		id = id + 1
		local my = id
		t.Text = msg
		t.Visible = true
		t.Position = UDim2.new(0.5, 0, 1, -50)
		t.BackgroundTransparency, t.TextTransparency = 1, 1
		tw(t, { Position = UDim2.new(0.5, 0, 1, -70), BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.2, Enum.EasingStyle.Back)
		prog.BackgroundTransparency, prog.Size = 0.2, UDim2.new(1, 28, 0, 2)
		if cfg.anim ~= 0 then
			S.TweenService:Create(prog, TweenInfo.new(secs or 3, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
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

-- startup popup: page 1 is always the same, page 2 is a random line. Each page stays 5 seconds (click to skip ahead).
do
	local p = new("TextButton", { Name = "Welcome", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.08), AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Font = FONT, TextSize = fs(12),
		RichText = true, TextWrapped = true, Text = "", Visible = false, ZIndex = 60 }, gui)
	paint(p, "BackgroundColor3", "bar"); paint(p, "TextColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, p)
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
	new("UICorner", { CornerRadius = UDim.new(0, 6) }, hud)
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
	local need = S.panelOpen or S.barOpen
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
-- [/UI_SHARED]

-- [UI_BAR]
-- ===== UI: command bar (slides 2-3: 647x51 pill at 318, list 593 wide right under it) ==============
do
	-- full screen CanvasGroup: fades the bar, list and popup as one (the list hangs outside the bar, so the bar itself can't be the group)
local barFade = new("CanvasGroup", { Name = "BarFade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false, ZIndex = 10 }, gui)
local bar = new("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(647, 51), BackgroundTransparency = 1 }, barFade)
	ui.barScale = new("UIScale", {}, bar)
	fr(bar, 0, 0, 647, 51, "bar", 0, 25, "accent", 2, 0.35)

	-- typed text and the completion are separate labels so no glyph is drawn twice
	local base = { BackgroundTransparency = 1, Position = UDim2.fromOffset(19, 0), Size = UDim2.fromOffset(610, 51),
		Font = FONT, TextSize = fs(16), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }
	local ghost = new("TextLabel", mix(base, { Text = "" }), bar)
	paint(ghost, "TextColor3", "dim")
	local box = new("TextBox", mix(base, { ClearTextOnFocus = false, Text = "", PlaceholderText = "" }), bar)
	paint(box, "TextColor3", "text"); paint(box, "PlaceholderColor3", "hint")
	ui.box = box

	local listF = new("Frame", { Name = "List", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 51), Size = UDim2.fromOffset(593, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false }, bar)
	paint(listF, "BackgroundColor3", "bar")
	new("UICorner", { CornerRadius = UDim.new(0, 4) }, listF)
	paint(new("UIStroke", { Thickness = 2, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, listF), "Color", "accent")
	new("UIPadding", { PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }, listF)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, listF)
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
new("UICorner", { CornerRadius = UDim.new(0, 4) }, tip)
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

	function ui.search()
		local line = box.Text:gsub("^%s*;", "")
		local q, rest = line:match("^%s*(%S*)(.*)$")
		q = (q or ""):lower()
		S.q, S.sel, S.cur, S.ghost, S.ghostX, S.sugOn = q, 1, {}, "", nil, false
		if rest ~= "" and ctx.Aliases[q] then
			-- typing arguments: show just that command's usage
			for _, e in ipairs(ui.entries()) do
				if e.canon == ctx.Aliases[q] then S.cur = { e } end
			end
		elseif rest ~= "" then
			-- more than one word that isn't a command: search by what commands do
			S.cur = ui.matches(line)
			S.q = ""
		elseif q == "" then
			if S.showAll then S.cur = ui.entries() else S.sugOn = true end
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
		local q, name = S.q or "", e.canon
		for _, nm in ipairs(e.names) do
			if nm:sub(1, #q) == q then name = nm; break end
		end
		box.Text = name
		box.CursorPosition = #box.Text + 1
	end

	function ui.openBar(prefill, showAll)
		if S.barOpen then return end
		S.barOpen, S.showAll = true, showAll
		S.sugMode, S.sugSel = "both", 1
		ui.layoutBar()
		box.Text = prefill or ""
		barFade.Visible = true
		tw(barFade, { GroupTransparency = 0 }, 0.07)
		local s = ui.curScale()
		ui.barScale.Scale = s * 0.96
		tw(ui.barScale, { Scale = s }, 0.16, Enum.EasingStyle.Back)
		tw(ui.blur, { Size = 18 * cfg.blur }, 0.2)
		if S.panelOpen and ui.shade then ui.shade.Visible = true end
		ui.syncMouse()
		S.RunService.RenderStepped:Wait() -- lets the key press that opened the bar finish, so ";" isn't typed into the box
		box:CaptureFocus()
		box.Text = prefill or ""
		box.CursorPosition = #box.Text + 1
		ui.search()
	end

	function ui.closeBar()
		if not S.barOpen then return end
		S.barOpen, S.sugOn = false, false
		box:ReleaseFocus()
		tw(barFade, { GroupTransparency = 1 }, 0.06)
		task.delay(dur(0.06), function() -- hide (and clear the text) once faded, unless reopened meanwhile
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
do
	local panelFade = new("CanvasGroup", { Name = "PanelFade", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false }, gui)
	local panel = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(685, 443), BorderSizePixel = 0 }, panelFade)
	paint(panel, "BackgroundColor3", "panel") -- transparency comes from the UI Opacity setting (reference: 80%)
	new("UICorner", { CornerRadius = UDim.new(0, 9) }, panel)
	paint(new("UIStroke", { Thickness = 1, Transparency = 0.55, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel), "Color", "accent")
	ui.panel = panel
	ui.panelScale = new("UIScale", {}, panel)
	-- accent line along the top edge: a dim base plus a highlight that glides across (paused with Animation Speed: none)
	fr(panel, 14, 0, 657, 2, "accent", 0.7)
	do
		local glow = fr(panel, 14, 0, 657, 2, "accent", 0)
		local g = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, glow)
		ui.glowTween = S.TweenService:Create(g, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Offset = Vector2.new(1, 0) })
		if cfg.anim ~= 0 then ui.glowTween:Play() end
	end

	-- position is kept as a fraction of the screen so the zoom can never offset it
	function ui.placePanel(extraY, animate)
		local vp = workspace.CurrentCamera.ViewportSize
		local pos = UDim2.fromScale(ui.panelPos.X, ui.panelPos.Y + (extraY or 0) / vp.Y)
		if animate then tw(panel, { Position = pos }, 0.18) else panel.Position = pos end
	end
	function ui.centerPanel()
		ui.panelPos = Vector2.new(0.5, 0.5)
		ui.placePanel(0)
	end
	ui.centerPanel()

	ui.title = txt(panel, "", 14, "text", 21, 16, 130, 23, { Font = FONT_CODE, RichText = true, TextSize = 19 })
	txt(panel, "open-source admin/dev panel", 8, "hint", 158, 21, 200, 13, { Font = FONT_CODE, TextSize = 11 })

	btn(panel, "×", 641, 13, 32, 26, "ctrlOff", BTN_OFF, function() ui.setPanel(false) end, 13)

	-- drag by the title bar; moves in screen fractions
	local header = new("Frame", { Size = UDim2.fromOffset(640, 50), BackgroundTransparency = 1 }, panel)
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

	local inner = fr(panel, 141, 52, 532, 379, "inner", 0.5, 8)
	inner.ClipsDescendants = true
	ui.inner = inner

	-- tab y positions copied from the deck (8 tabs now); text right-aligned with the deck's 9.6px inset
	local TABS = { { "Home", 66 }, { "Players", 102 }, { "Look and feel", 137 }, { "Load scripts", 173 }, { "Autostart", 208 },
		{ "Keybinds", 244 }, { "Module Cfg", 279 }, { "Commands", 315 }, { "Preferences", 350 } }
	for _, t in ipairs(TABS) do
		local name = t[1]
		local b = new("TextButton", { Position = UDim2.fromOffset(0, t[2]), Size = UDim2.fromOffset(141, 35), AutoButtonColor = false, BorderSizePixel = 0,
			Text = name, Font = FONT, TextSize = fs(10), TextXAlignment = Enum.TextXAlignment.Right }, panel)
		new("UIPadding", { PaddingRight = UDim.new(0, 10) }, b)
		paint(b, "TextColor3", "text")
		b.BackgroundTransparency = 0.9
		tabs[name] = b
		ui.tabY = ui.tabY or {}
		ui.tabY[name] = t[2]
		b.MouseEnter:Connect(function() if ui.tab ~= name then tw(b, { BackgroundTransparency = 0.8 }, 0.1) end end)
		b.MouseLeave:Connect(function() if ui.tab ~= name then tw(b, { BackgroundTransparency = 0.9 }, 0.12) end end)
		b.MouseButton1Click:Connect(function() ui.selectTab(name) end)
		pages[name] = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, inner)
	end

	-- the selected tab gets an accent tint, accent text and a bar that slides to it
	ui.tabBar = fr(panel, 4, 73, 3, 21, "accent", 0, 2)
	function ui.selectTab(name)
		local first = ui.tab == nil
		ui.tab = name
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabs) do
			local on = n == name
			paint(b, "BackgroundColor3", on and "accent" or "tabOff")
			paint(b, "TextColor3", on and "accentText" or "text")
			tw(b, { BackgroundTransparency = on and 0.82 or 0.9 }, 0.12)
		end
		local goal = UDim2.fromOffset(4, ui.tabY[name] + 7)
		if first then
			ui.tabBar.Position = goal
		else
			tw(ui.tabBar, { Position = goal }, 0.18, Enum.EasingStyle.Quart)
			if cfg.anim ~= 0 then -- page slides up into place
				pages[name].Position = UDim2.fromOffset(0, 14)
				tw(pages[name], { Position = UDim2.new() }, 0.15)
			end
		end
		if onShow[name] then onShow[name]() end
	end

	-- dark layer over the panel while the command bar is open: the panel can't be clicked until the bar closes
	ui.shade = fr(panel, 0, 0, 685, 443, "tabOff", 0.45, 9)
	ui.shade.ZIndex, ui.shade.Active, ui.shade.Visible = 50, true, false

	function ui.setPanel(open)
		S.panelOpen = open
		if open then
			local s = ui.curScale()
			ui.panelScale.Scale = s * 0.94
			tw(ui.panelScale, { Scale = s }, 0.18, Enum.EasingStyle.Back)
			ui.placePanel(24, false)
			panelFade.Visible = true
			tw(panelFade, { GroupTransparency = 0 }, 0.07)
			ui.placePanel(0, true)
			ui.shade.Visible = S.barOpen and true or false
			if onShow[ui.tab] then onShow[ui.tab]() end
		else -- shrinks away first, then hides (unless it was opened again meanwhile)
			tw(ui.panelScale, { Scale = ui.curScale() * 0.96 }, 0.12)
			tw(panelFade, { GroupTransparency = 1 }, 0.06)
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
	txt(h, "Good day, " .. lp.DisplayName, 14, "text", 17, 15, 229, 23, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
	local welcomeTxt = txt(h, HOME_MSGS[math.random(#HOME_MSGS)], 10.5, "text", 17, 49, 342, 34, { TextWrapped = true })
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
	local gameName = txt(h, "Experience: " .. (expName or "..."), 11, "text", 26, 86, 315, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
	if expName then ctx.curExp = { gid = cfg.expIcon[gid] or game.GameId, name = expName } end
	ctx.connect("expTp", lp.OnTeleport, function() -- remembered for the next place, which may only call itself "Ugc"
		if ctx.curExp then cfg.carry = { gid = ctx.curExp.gid, name = ctx.curExp.name, t = os.time() }; save() end
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
			gameName.Text = "Experience: " .. (n or game.Name)
		end)
	end

	-- stats: four rows that together span exactly the icon's height (105..215), each text centred in its row
	local vals, region = {}, "-"
	for i, name in ipairs({ "Players", "Locale", "Latency", "Uptime" }) do
		vals[name] = txt(h, name .. ": -", 11, "text", 64, 105 + math.floor((i - 1) * 27.5), 125, 27, { TextYAlignment = Enum.TextYAlignment.Center })
	end
	-- game icon: square (the deck's is 196x110; this one is 110x110)
	local icon = new("ImageLabel", { Position = UDim2.fromOffset(199, 105), Size = UDim2.fromOffset(110, 110), BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop, Image = thumb("GameIcon", cfg.expIcon[gid] or game.GameId, 150) }, h)
	paint(icon, "BackgroundColor3", "row")
	icon.BackgroundTransparency = 0.9
	new("UICorner", { CornerRadius = UDim.new(0, 10) }, icon)
	paint(new("UIStroke", { Thickness = 1, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, icon), "Color", "accent")
	local tip = txt(h, "Tips: " .. TIPS[1], 9, "dim", 17, 230, 340, 58, { TextWrapped = true })

	fr(h, 373, 14, 1, 349, "accent", 0.7)
	local av = new("ImageLabel", { Position = UDim2.fromOffset(398, 22), Size = UDim2.fromOffset(110, 110), BorderSizePixel = 0, BackgroundTransparency = 0.9,
		Image = thumb("AvatarHeadShot", lp.UserId, 150) }, h)
	paint(av, "BackgroundColor3", "row")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	paint(new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, av), "Color", "accent")
	txt(h, lp.DisplayName, 12, "text2", 398, 139, 110, 17, { Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })
	txt(h, "@" .. lp.Name, 8, "sub", 398, 159, 110, 12, { TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd })

	-- bio: black at 20% with a 20% edge, 3px corners, 4.8px side insets
	local bio = new("TextBox", { Position = UDim2.fromOffset(384, 176), Size = UDim2.fromOffset(140, 187), BorderSizePixel = 0, BackgroundTransparency = 0.8,
		Font = FONT, TextSize = fs(9), MultiLine = true, TextWrapped = true, ClearTextOnFocus = false, Text = cfg.bio, PlaceholderText = "customizable bio",
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, h)
	paint(bio, "BackgroundColor3", "tabOff"); paint(bio, "TextColor3", "text"); paint(bio, "PlaceholderColor3", "dim")
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, bio)
	paint(new("UIStroke", { Thickness = 1, Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, bio), "Color", "tabOff")
	new("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5), PaddingTop = UDim.new(0, 4) }, bio)
	bio.FocusLost:Connect(function() cfg.bio = bio.Text; save() end)

	pcall(function() region = S.LocalizationService.RobloxLocaleId end)
	-- live stats + a new tip every 5 minutes
	task.spawn(function()
		local last = os.clock()
		while S.alive do
			if S.panelOpen and ui.tab == "Home" then
				pcall(function()
					vals["Players"].Text = "Players: " .. #S.Players:GetPlayers() .. " / " .. S.Players.MaxPlayers
					vals["Locale"].Text = "Locale: " .. region
					local ok, ping = pcall(function() return S.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
					vals["Latency"].Text = "Latency: " .. (ok and (math.floor(ping) .. " ms") or "-")
					local t = math.floor(workspace.DistributedGameTime)
					vals["Uptime"].Text = ("Uptime: %02d:%02d:%02d"):format(math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
				end)
			end
			if os.clock() - last > 300 then
				last = os.clock()
				tip.Text = "Tips: " .. TIPS[math.random(#TIPS)]
				welcomeTxt.Text = HOME_MSGS[math.random(#HOME_MSGS)]
			end
			task.wait(1)
		end
	end)
end
-- [/PG_HOME]

-- [PG_PLAYERS]
-- ===== page: Players (slide 5: search 299x32 at 9,10; rows 77px flush; 95x23 buttons in a 2x2 grid) =====
do
	local pg = pages["Players"]
	local sbox = input(pg, "Search for player…", 9, 10, 299, 32, 11)
	local plist = scroller(pg, 0, 53, 532, 326)
	new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, plist)
	local friends = {} -- userId -> bool, filled in the background

	-- a name you can double click: copies it, or (no clipboard) selects it so you can copy it by hand
	local clicks = {}
	local function copyable(parent, plain, rich, x, y, w, h, pt, key, props)
		local l = txt(parent, rich, pt, key, x, y, w, h, mix({ RichText = true, TextTruncate = Enum.TextTruncate.AtEnd }, props))
		local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = l.Position, Size = l.Size }, parent)
		local tb
		hit.MouseButton1Click:Connect(function()
			local now = os.clock()
			if clicks[hit] and now - clicks[hit] < 0.4 then
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
			end
		end)
		return l
	end
	local function greyOut(b, isFriend)
		if not (b and b.Parent) then return end
		b.Active = not isFriend
		b.TextTransparency = isFriend and 0.55 or 0
		setFill(b, isFriend and "tabOff" or "btnFill", isFriend and 0.5 or BTN_OFF)
	end

	local function render()
		clear(plist)
		local q = sbox.Text:lower()
		local ps = S.Players:GetPlayers()
		table.sort(ps, function(a, b)
			if a == b then return false end
			if a == lp then return true end
			if b == lp then return false end
			return a.DisplayName:lower() < b.DisplayName:lower()
		end)
		local n = 0
		for _, p in ipairs(ps) do
			if q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true) then
				n = n + 1
				local r = fr(plist, 0, 0, 532, 77, "row", 0.9)
				r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 77), n
				local a = new("ImageLabel", { Position = UDim2.fromOffset(9, 7), Size = UDim2.fromOffset(61, 61), BorderSizePixel = 0, BackgroundTransparency = 0.9,
					Image = thumb("AvatarHeadShot", p.UserId, 150) }, r)
				paint(a, "BackgroundColor3", "row")
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
				paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a), "Color", "accent")
				copyable(r, p.DisplayName, hl(p.DisplayName, q) .. (p == lp and " (you)" or ""), 80, 21, 175, 16, 10, "text2", { Font = FONT_B })
				copyable(r, p.Name, hl("@" .. p.Name, q), 80, 39, 175, 13, 8, "sub")
				if p == lp then
					btn(r, "Respawn", 439, 27, 81, 23, "btnFill", BTN_OFF, function() ctx.Run("reset") end)
				else
					btn(r, state.viewing == p and "Unview" or "View", 265, 12, 81, 23, nil, nil, function()
						ctx.Run(state.viewing == p and "unview" or ("view " .. p.Name))
						render()
					end)
					local fb = btn(r, "Add Friend", 439, 12, 81, 23, nil, nil, function() ctx.Run("friend " .. p.Name) end)
					if friends[p.UserId] == nil then
						task.spawn(function()
							local ok, res = pcall(function() return lp:IsFriendsWith(p.UserId) end)
							friends[p.UserId] = ok and res or false
							greyOut(fb, friends[p.UserId])
						end)
					else
						greyOut(fb, friends[p.UserId])
					end
					btn(r, "Go to", 352, 12, 81, 23, nil, nil, function() ctx.Run("goto " .. p.Name) end)
					btn(r, state.listen[p.UserId] and "Unlisten" or "Listen", 352, 41, 81, 23, nil, nil, function()
						local on = not state.listen[p.UserId]
						if on and state.muted[p.UserId] then ctx.setMuted(p.UserId, false) end
						local ok, why = ctx.setListen(p.UserId, on)
						if on and not ok then return ctx.notify(why, 5) end
						render()
					end)
					btn(r, state.muted[p.UserId] and "Unmute" or "Mute", 265, 41, 81, 23, nil, nil, function(b)
						local on = not state.muted[p.UserId]
						ctx.setMuted(p.UserId, on)
						b.Text = on and "Unmute" or "Mute"
						render()
					end)
				end
			end
		end
		if n == 0 then
			empty(plist, "No players match.")
		end
	end
	sbox:GetPropertyChangedSignal("Text"):Connect(render)
	onShow["Players"] = render
	conn(S.Players.PlayerAdded, function() if S.panelOpen and ui.tab == "Players" then render() end end)
	conn(S.Players.PlayerRemoving, function(p)
		if state.viewing == p then state.viewing = nil end
		task.defer(function() if S.panelOpen and ui.tab == "Players" then render() end end)
	end)
end
-- [/PG_PLAYERS]

-- [PG_LOOK]
-- ===== page: Look and feel (slide 7, every control at the deck's position) ============================
do
	local pg = scroller(pages["Look and feel"], 0, 0, 532, 379)
	local function label(str, x, y) txt(pg, str, 12, "text", x, y, 214, 19) end
	txt(pg, "Main", 14, "text", 21, 12, 214, 23, { Font = FONT_B })
	label("Default theme", 33, 46)
	seg(pg, 44, { 285, 396 }, 104, { { "Dark Mode", "Dark" }, { "Light Mode", "Light" } }, "theme")
	label("UI Opacity", 33, 81)
	seg(pg, 79, { 285, 340, 396, 451 }, 47, { { "20%", 0.2 }, { "50%", 0.5 }, { "80%", 0.8 }, { "100%", 1 } }, "opacity")
	label("Accent Color", 33, 118)
	fr(pg, 322, 116, 30, 23, "accent", 0, 3, "edge", 1)
	local hexBox = input(pg, "#FFFF00", 359, 116, 104, 23, 9, "ctrlOff", BTN_OFF, { Text = cfg.accent, TextXAlignment = Enum.TextXAlignment.Center })
	hexBox.FocusLost:Connect(function()
		local t = hexBox.Text:upper()
		if parseHex(t) then cfg.accent = t; save(); ui.apply() end
		hexBox.Text = cfg.accent
	end)
	label("Animation Speed", 33, 155)
	seg(pg, 153, { 285, 340, 396, 451 }, 47, { { "0.5x", 0.5 }, { "1.0x", 1 }, { "2.0x", 2 }, { "none", 0 } }, "anim")
	label("UI Scaling", 33, 192)
	seg(pg, 190, { 285, 340, 396, 451 }, 47, { { "80%", 0.8 }, { "100%", 1 }, { "120%", 1.2 }, { "140%", 1.4 } }, "scale")
	txt(pg, "Command Bar", 14, "text", 17, 228, 214, 23, { Font = FONT_B })
	label("Max suggestion lines", 28, 262)
	seg(pg, 260, { 281, 354, 428 }, 69, { { "6", 6 }, { "12", 12 }, { "20", 20 } }, "lines")
	label("Blur Size", 28, 297)
	seg(pg, 295, { 281, 336, 391, 447 }, 47, { { "0x", 0 }, { "0.5x", 0.5 }, { "1.0x", 1 }, { "1.5x", 1.5 } }, "blur")
	label("Position", 28, 331)
	seg(pg, 329, { 281, 354, 428 }, 68, { { "Bottom", "Bottom" }, { "Center", "Center" }, { "Top", "Top" } }, "pos")
end
-- [/PG_LOOK]

-- [PG_SCRIPTS]
-- ===== page: Load scripts (slide 8: rows 76px flush, 11pt title, 8pt description, 94x23 button) ===========
do
	local pg = pages["Load scripts"]
	local sbox = input(pg, "Search scripts…", 9, 10, 299, 32, 11)
	local list = scroller(pg, 0, 53, 532, 326)
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
		local r = fr(list, 0, 0, 532, 76, "row", 0.9)
		r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 76), nx()
		txt(r, (locked and "🔒 " or "") .. name, 11, "text2", 17, 12, 380, 18, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
		txt(r, desc, 8, "sub", 22, 35, 380, 26, { TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
		return btn(r, S.launched[key] and "Relaunch" or label, 418, 26, 94, 23, "btnFill", BTN_OFF, function(b)
			b.Text = "Loading..."
			task.spawn(function()
				action()
				S.launched[key] = true
				b.Text = "Relaunch"
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
end
-- [/PG_SCRIPTS]

-- [PG_CMDS]
-- ===== page: Commands (every command with its function, arguments and modifier) ======================
do
	local pg = pages["Commands"]
	local sbox = input(pg, "Search commands, or what they do…", 9, 10, 299, 32, 11)
	local list = scroller(pg, 0, 53, 532, 326)
	new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local NOLOOP = { panel = 1, cmds = 1, ui = 1, exit = 1, reload = 1, bind = 1, unbind = 1, alias = 1, prefix = 1, selftest = 1, kill = 1, ["break"] = 1, loop = 1, unloop = 1 }
	local function render()
		clear(list)
		local hits = ui.matches(sbox.Text)
		local n = 0
		for _, e in ipairs(hits) do
			n = n + 1
			local r = fr(list, 0, 0, 532, 66, "row", 0.9)
			r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 66), n
			local names = {}
			for _, nm in ipairs(e.names) do names[#names + 1] = nm end
			local head = table.concat(names, " / ")
			txt(r, head, 11, "text2", 17, 8, 360, 18, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
			if e.args ~= "" then txt(r, e.args, 9, "dim", 17, 8, 488, 18, { TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center }) end
			txt(r, e.desc ~= "" and e.desc or "-", 8, "sub", 17, 28, 488, 22, { TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd })
			txt(r, NOLOOP[e.canon] and "modifier: none" or ("modifier: loop^" .. e.canon), 8, "dim", 17, 50, 488, 12)
		end
		if n == 0 then empty(list, "No command matches that.") end
	end
	sbox:GetPropertyChangedSignal("Text"):Connect(render)
	onShow["Commands"] = render
end
-- [/PG_CMDS]

-- [PG_FLOW]
-- ===== pages without a slide (Keybinds, Module Cfg, Preferences): same tokens and sizes, flow layout ======
local function flow(name)
	local sc = scroller(pages[name], 0, 0, 532, 379)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sc)
	new("UIPadding", { PaddingLeft = UDim.new(0, 21), PaddingRight = UDim.new(0, 21), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, sc)
	return sc
end
local function fhdr(sc, str)
	local h = txt(sc, str, 14, "text", 0, 0, 400, 23, { LayoutOrder = nx(), Font = FONT_B })
	fr(h, -10, 4, 3, 15, "accent", 0, 2) -- accent mark in the left margin
	return h
end
-- label on the left, a right-anchored group (width w) on the right
local function frow(sc, str, w)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, sc)
	txt(r, str, 12, "text", 12, 2, math.max(60, 466 - w), 19, { TextTruncate = Enum.TextTruncate.AtEnd }) -- never runs under the control
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
			local rb = btn(r, it.respawn and "After reset: On" or "After reset: Off", 300, 12, 100, 23, "ctrlOff", BTN_OFF, function(b)
				it.respawn = not it.respawn
				save()
				b.Text = it.respawn and "After reset: On" or "After reset: Off"
				setFill(b, it.respawn and "ctrlOn" or "ctrlOff", it.respawn and BTN_ON or BTN_OFF)
			end)
			if it.respawn then setFill(rb, "ctrlOn", BTN_ON) end
			btn(r, "Remove", 406, 12, 76, 23, "btnFill", BTN_OFF, function()
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
		local cb = btn(crow, "Add command", 0, 0, 104, 23, "btnFill", BTN_OFF, function()
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
				btn(r, "Add", 400, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = b.name, kind = "builtin", ref = b.name }) end)
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
					btn(r, "Add", 400, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = n, kind = "local", ref = f }) end)
				end
			end
		end
		for _, g in ipairs(GITHUB) do
			if not has("github", g.name) then
				shown = shown + 1
				local r = card(34)
				txt(r, g.name .. "  (GitHub)", 10, "text2", 12, 8, 380, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
				btn(r, "Add", 400, 5, 82, 23, "btnFill", BTN_OFF, function() add({ name = g.name, kind = "github", ref = g.name }) end)
			end
		end
		if shown == 0 then txt(list, "Everything available is already added.", 10, "dim", 0, 0, 400, 20, { LayoutOrder = nx() }) end

		label("Or add by link")
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, list)
		local link = input(row, "https://raw.githubusercontent.com/...", 0, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
		link.Parent.Size = UDim2.new(1, -90, 0, 23)
		local ab = btn(row, "Add link", 0, 0, 82, 23, "btnFill", BTN_OFF, function()
			local u = link.Text:match("^%s*(.-)%s*$")
			if not u:match("^https?://") then return ctx.notify("That doesn't look like a link") end
			add({ name = u:match("([^/]+)$") or u, kind = "url", ref = u })
		end)
		ab.AnchorPoint = Vector2.new(1, 0); ab.Position = UDim2.new(1, 0, 0, 0)
	end
	onShow["Autostart"] = render
end
-- [/PG_AUTOSTART]

-- [PG_KEYS]
do
	local pg = flow("Keybinds")
	-- two tiles side by side: caption + keycap (click the keycap, then press the new key)
	local function keyTile(row, x, cap, key)
		local t = fr(row, x, 0, 241, 54, "row", 0.9, 5, "edge", 1, 0.6)
		txt(t, cap, 9, "dim", 12, 8, 200, 12, { Font = FONT_B })
		txt(t, "click, then press a key", 9, "hint", 130, 28, 106, 14)
		return btn(t, "", 12, 24, 110, 23, "ctrlOn", BTN_ON, function(b)
			b.Text = "press a key..."
			S.capture = function(kc)
				if kc ~= Enum.KeyCode.Escape then cfg[key] = kc.Name; save() end
				ui.apply()
			end
		end, 10)
	end
	fhdr(pg, "Hotkeys")
	local hot = new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local barBtn, panelBtn = keyTile(hot, 0, "COMMAND BAR", "barKey"), keyTile(hot, 249, "PANEL", "panelKey")
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
		tabBtn("none", "No Keybinds"); tabBtn("default", "Default")
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
		if cfg.kbActive == "default" then txt(area, "Default tab: its binds work in every experience.", 9, "dim", 0, 0, 440, 14, { LayoutOrder = nx() }) end
		if t then -- custom tab: experience specific option + delete (No Keybinds and Default can't be deleted)
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
			btn(frow(area, "Delete this tab", 76), "Delete", 0, 0, 76, 23, "btnFill", BTN_OFF, function()
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
		btn(a, "set key", 0, 0, 96, 23, "ctrlOn", BTN_ON, function(b)
			b.Text = "press a key..."
			local function cap(kc, name)
				if kc ~= Enum.KeyCode.Escape then
					if ctx.MODS[kc.Name] then S.capture = cap; return end -- modifier alone: keep waiting, so Ctrl+G works
					newKey = name
				end
				b.Text = newKey and keyStr(newKey) or "set key"
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
			btn(h, keyStr(k), 0, 0, w, 23, "ctrlOn", BTN_ON, function(b) -- click, then press the new key (Ctrl/Shift/Alt combos work)
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
end
-- [/PG_KEYS]

-- [PG_MODCFG]
-- Module Cfg: default values and multipliers for commands. Typing a number commits on Enter / click away.
do
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

	fhdr(pg, "Speed and fly")
	numRow("Fly: default speed", "flyDef"); numRow("Fly: multiplier", "flyMult")
	numRow("Speed: default", "speedDef"); numRow("Speed: multiplier", "speedMult")
	numRow("Jump power: default", "jpDef"); numRow("Jump power: multiplier", "jpMult")
	numRow("Spin: default (rotations/s)", "spinDef"); numRow("Spin: multiplier", "spinMult")
	numRow("Float: stair height (studs)", "floatStep")
	fhdr(pg, "Tpwalk")
	optRow("Mode", "tpMode", { { "Multiplier", "Multiplier" }, { "Additive", "Additive" } }, 84)
	numRow("Default amount", "tpDef"); numRow("Maximum (cap)", "tpCap")
	fhdr(pg, "Follow, backpack, baby")
	numRow("Follow: default radius (studs)", "followRadius")
	numRow("Backpack: distance", "bpDist"); numRow("Backpack: height", "bpHeight")
	numRow("Baby: distance", "babyDist"); numRow("Baby: height", "babyHeight"); numRow("Baby: rotation (degrees)", "babyRot")
	fhdr(pg, "Head attach (;heada / ;headattach)")
	numRow("Distance (in front of the face)", "headDist"); numRow("Height above the head", "headHeight"); numRow("Side", "headSide")
	togRow("Sweep front / back", "headSweep"); numRow("Sweep amplitude (studs)", "headSweepAmp"); numRow("Sweep speed (radians/s)", "headSweepSpeed")
	fhdr(pg, "Back attach (;backa / ;backattach)")
	numRow("Distance (behind the back)", "backDist"); numRow("Height", "backHeight"); numRow("Side", "backSide")
	togRow("Sweep front / back", "backSweep"); numRow("Sweep amplitude (studs)", "backSweepAmp"); numRow("Sweep speed (radians/s)", "backSweepSpeed")
	fhdr(pg, "Ragdoll limbs (a limb switched off stays stiff)")
	togRow("Head", "ragHead"); togRow("Torso", "ragTorso")
	togRow("Left arm", "ragLeftArm"); togRow("Right arm", "ragRightArm")
	togRow("Left leg", "ragLeftLeg"); togRow("Right leg", "ragRightLeg")
	fhdr(pg, "Display and misc")
	optRow("Show FPS corner", "fpsCorner", { { "TL", "TL" }, { "TR", "TR" }, { "BL", "BL" }, { "BR", "BR" } }, 47)
	togRow("Ragdoll blocks game reset", "ragdollBlock")
	fhdr(pg, "Streamer mode")
	strRow("Your name", "streamMe"); strRow("Other players (comma separated)", "streamOthers")
	fhdr(pg, "Crosshair (;crosshair / ;removecrosshair)")
	optRow("Mode", "chStyle", { { "Cross", "Cross" }, { "T", "T" }, { "Dot", "Dot" } }, 84)
	numRow("Length", "chLen"); numRow("Gap", "chGap"); numRow("Thickness", "chThick")
	numRow("Outline thickness (0 = none)", "chOutline"); numRow("Outline opacity (0 to 1)", "chOutlineAlpha")
	do
		local g = frow(pg, "Colour (hex)", 96)
		local o = input(g, "", 0, 0, 96, 23, 9, "ctrlOff", BTN_OFF, { Text = tostring(M.chColor), TextXAlignment = Enum.TextXAlignment.Center })
		o.FocusLost:Connect(function()
			local t = o.Text:match("^%s*(.-)%s*$")
			if not t:match("^#") then t = "#" .. t end
			if parseHex(t) then M.chColor = t:upper(); save(); if ctx.onMod then ctx.onMod("chColor") end end
			o.Text = tostring(M.chColor)
		end)
	end
	togRow("Replace Roblox cursor (off = screen center)", "chCursor")
	fhdr(pg, "Defense")
	togRow("Defense notifications", "defNotify")
	numRow("Anti fling: radius", "afRadius"); numRow("Anti fling: velocity threshold", "afThreshold"); numRow("Anti fling: restore time (s)", "afRestore")
	numRow("Anti teleport: min distance", "atpMin"); numRow("Anti knockback: max speed", "akMax")
	numRow("Anti void: height above destroy", "avHeight")
	numRow("Anti ear rape: threshold", "aeThreshold"); numRow("Anti ear rape: window (s)", "aeDuration")
	numRow("Anti afk: interval (s)", "afkInterval"); numRow("Anti spam: messages", "spamCount")
	onShow["Module Cfg"] = function() if ui.layoutHud and state.active.showfps then ui.layoutHud() end end
end
-- [/PG_MODCFG]

-- [PG_PREFS]
do
	local pg = flow("Preferences")
	fhdr(pg, "General")
	seg(frow(pg, "Notifications", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "toasts")
	seg(frow(pg, "Open command bar on start", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "startBar")
	seg(frow(pg, "Auto execute", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "autoExec", function(v) ctx.setAutoExec(v) end)
	seg(frow(pg, "Auto rejoin on VC ban", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "avc", function(v) ctx.setAvc(v) end)
	seg(frow(pg, "Command list: up to 3 columns", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "sugCols")
	fhdr(pg, "Active effects")
	local active = txt(pg, "none", 11, "sub", 0, 0, 400, 20, { LayoutOrder = nx(), TextWrapped = true })
	local br = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local function refresh()
		local names = {}
		for k in pairs(state.active) do names[#names + 1] = k end
		table.sort(names)
		active.Text = #names > 0 and table.concat(names, ", ") or "none"
	end
	btn(br, "Reset all effects", 0, 0, 120, 23, "btnFill", BTN_OFF, function() ctx.resetAll(); refresh() end)
	btn(br, "Unload panel", 126, 0, 100, 23, "btnFill", BTN_OFF, function() ui.unload() end)
	txt(pg, "KL rOSAD v" .. VERSION, 8, "dim", 0, 0, 300, 14, { LayoutOrder = nx() })
	onShow["Preferences"] = refresh
end
-- [/PG_PREFS]

-- [ENTRY]
-- ===== apply settings, wire input, start ===================================
-- 1080p is the design size only: the UI keeps the same pixel size at every resolution, the UI Scaling setting is the only zoom.
function ui.curScale() return cfg.scale end
function ui.rescale()
	local s = ui.curScale()
	ui.panelScale.Scale, ui.barScale.Scale, ui.toastScale.Scale, ui.hudScale.Scale, ui.popScale.Scale = s, s, s, s, s
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
	if ui.glowTween then pcall(function() if cfg.anim == 0 then ui.glowTween:Pause() else ui.glowTween:Play() end end) end
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

function ui.unload()
	S.alive = false
	pcall(ctx.resetAll)
	pcall(function() S.ContextActionService:UnbindAction("KLOSAD_Shift") end)
	for uid in pairs(state.listen) do pcall(ctx.setListen, uid, false) end
	pcall(ctx.noStereo, false)
	pcall(ctx.crosshair, false)
	for _, c in ipairs(S.cons) do pcall(function() c:Disconnect() end) end
	for k in pairs(state.conns) do ctx.disconnect(k) end
	for uid in pairs(state.muted) do pcall(ctx.setMuted, uid, false) end
	state.muted = {}
	if state.chat then state.chat.spam = false end
	pcall(function() -- hand the chat handler back to the game
		if S.chatPrev then S.TextChatService.OnIncomingMessage = S.chatPrev.fn end
	end)
	for _, p in ipairs(state.baseParts or {}) do pcall(function() p:Destroy() end) end
	S.panelOpen, S.barOpen = false, false
	ui.syncMouse()
	pcall(function() ui.blur:Destroy() end)
	pcall(function() gui:Destroy() end)
	env.KLOSAD = nil
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
if not (HAS_FS and HAS_LOAD) then ctx.notify("Limited mode: this executor has no file access or loadstring.", 5) end
ui.welcome()
if cfg.startBar then task.defer(function() ui.openBar() end) end
if cfg.autostart.onExec then task.delay(2, function() ctx.runAutostart("exec") end) end
-- [/ENTRY]
