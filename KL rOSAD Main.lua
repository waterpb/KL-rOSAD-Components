--[[
	KL rOSAD v1.0  |  open-source admin/dev panel  |  client-side only

	WHERE TO PUT THINGS (search this file for ">>>"):
	  >>> BUILTIN   locked pre-installed scripts (Lighting Utility, Cobalt, Dex): paste the script between the markers
	  >>> GITHUB    your loadstring links: pin them to a commit hash, not "main"

	FOLDERS (in your executor's workspace, created for you):
	  KLOSAD/scripts    any .lua / .txt dropped here shows up under Load scripts > Local
	  KLOSAD/commands   extra command files (same format as the built-in ones), then type: reload
	  KLOSAD/settings.json   saved settings, binds and bio

	Command file format:  return function(ctx) return { names = {"x","alias"}, args = "[n]", desc = "...", run = function(n) end } end
]]

local VERSION = "1.0"
local DIR = "KLOSAD"
local env = (getgenv and getgenv()) or _G
if env.KLOSAD and env.KLOSAD.Unload then pcall(env.KLOSAD.Unload) end

-- >>> BUILTIN: locked pre-installed scripts. Paste each script between its two marker lines.
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
	{ name = "Cobalt", desc = "Remote spy", url = "https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau" },
	{ name = "RSpy", desc = "Remote spy (SimpleSpy V3)", url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua" },
	{ name = "ALogger", desc = "Audio logger: logs sounds as they play", url = "https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua" },
	{ name = "Freeze Instance Saver", desc = "Saves the instance with humanoids and players", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Freeze%20Instance%20Saver.lua" },
	{ name = "LiU", desc = "Lighting Utility", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/LiU%20v9.lua" },
	{ name = "Name Spoofer", desc = "Name spoofer / streamer mode", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Name%20Spoofer.lua" },
	{ name = "No Sit", desc = "Seats can't seat you (used by antisit)", url = "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/No%20Sit.lua" },
}

local TIPS = {
	"Did you know that you can change your default prefix bind to a custom key? Go to the Keybinds tab.",
	"Type part of a command in the bar and press Tab to complete it.",
	"bind f fly 80 binds F to a command. Manage binds in the Keybinds tab.",
	"Drop your own command files in KLOSAD/commands, then type reload.",
	"Preferences > Reset all effects turns off fly, noclip, esp and more in one click.",
	"Drag the panel by its title bar.",
}

-- S = service cache + shared state; ui = functions the UI part fills in
-- FIX: a failed GetService used to return the error text (truthy), so S.barOpen / S.capture etc. were always "set". Now returns nil.
local S = setmetatable({ cons = {}, sel = 1, cur = {}, launched = {}, alive = true }, { __index = function(t, k)
	local ok, v = pcall(game.GetService, game, k)
	if ok then t[k] = v; return v end
end })
local ui = {}

local request = (syn and syn.request) or http_request or request
local HAS_FS = (readfile and writefile and listfiles and isfolder and makefolder) and true or false
local HAS_LOAD = pcall(function() return loadstring("return 1")() end)

-- ===== settings ============================================================
local DEFAULTS = {
	theme = "Dark", opacity = 0.8, accent = "#FFFF00", anim = 1, scale = 1,
	lines = 12, blur = 1, pos = "Center", barKey = "Semicolon", panelKey = "RightShift",
	toasts = true, bio = "", binds = {}, autoExec = false, avc = false, mod = {},
}
local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end
cfg.binds = {}
cfg.mod = {}

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
}
for k, v in pairs(MODDEF) do
	if type(cfg.mod[k]) ~= type(v) then cfg.mod[k] = v end
end

-- ===== theme + small helpers ===============================================
local rgb = Color3.fromRGB
-- Colors resolved from the reference deck (tx1=black, bg1=white, bg2=E7E6E6, with the lumMod values applied).
local THEMES = {
	Dark = { panel = rgb(13, 13, 13), panelEdge = rgb(70, 67, 67), inner = rgb(24, 23, 23), edge = rgb(88, 84, 84), bar = rgb(24, 23, 23),
		tabOn = rgb(118, 113, 113), tabOff = rgb(0, 0, 0), row = rgb(59, 56, 56), ctrlOn = rgb(118, 113, 113), ctrlOff = rgb(52, 50, 50),
		btnFill = rgb(66, 63, 63), text = rgb(255, 255, 255), text2 = rgb(231, 230, 230), sub = rgb(175, 171, 171),
		dim = rgb(118, 113, 113), hint = rgb(128, 128, 128), line = rgb(118, 113, 113) },
	Light = { panel = rgb(242, 242, 242), panelEdge = rgb(242, 242, 242), inner = rgb(231, 230, 230), edge = rgb(158, 155, 155), bar = rgb(231, 230, 230),
		tabOn = rgb(138, 134, 134), tabOff = rgb(255, 255, 255), row = rgb(191, 191, 191), ctrlOn = rgb(138, 134, 134), ctrlOff = rgb(250, 250, 250),
		btnFill = rgb(255, 255, 255), text = rgb(13, 13, 13), text2 = rgb(31, 31, 31), sub = rgb(84, 81, 81),
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
local function tw(inst, props, t)
	if cfg.anim == 0 then
		for k, v in pairs(props) do inst[k] = v end
		return
	end
	S.TweenService:Create(inst, TweenInfo.new((t or 0.15) / cfg.anim, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function keyFromString(s)
	local sl = tostring(s):lower()
	for _, k in ipairs(Enum.KeyCode:GetEnumItems()) do
		if k.Name:lower() == sl or S.UserInputService:GetStringForKeyCode(k):lower() == sl then return k end
	end
end
local function keyStr(name)
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

-- ===== command core ========================================================
local ctx = {
	Players = S.Players, RunService = S.RunService, UIS = S.UserInputService, Lighting = S.Lighting,
	TeleportService = S.TeleportService, HttpService = S.HttpService, StarterGui = S.StarterGui,
	SocialService = S.SocialService, TextChatService = S.TextChatService,
	lp = S.Players.LocalPlayer, cam = workspace.CurrentCamera,
	Commands = {}, Aliases = {}, Meta = {},
	state = { conns = {}, muted = {}, esp = {}, saved = {}, active = {}, loopGen = 0, loopOf = {}, tools = {}, cc = {} },
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
function ctx.setMuted(uid, on)
	state.muted[uid] = on or nil
	if on then ctx.hookChat() end
end

function ctx.setBind(key, line)
	local kc = keyFromString(key)
	if not kc then return ctx.notify("Unknown key: " .. tostring(key)) end
	cfg.binds[kc.Name] = (line and line ~= "") and line or nil
	save()
	if ui.refreshKeys then ui.refreshKeys() end
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
	headsit = "unattach", ragdoll = "unragdoll", spin = "unspin", antifling = "unantifling", antisit = "unantisit",
	antivoid = "unantivoid", antiteleport = "unantiteleport", antiknockback = "unantiknockback", antiattach = "unantiattach",
	antiearrape = "unantiearrape", antiblur = "unantiblur", antiafk = "unantiafk", antispam = "unantispam",
	antifreeze = "unantifreeze", blink = "unblink", ghost = "unblink", streamer = "unstreamer", name = "unname",
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
	mute = { "<player>", "Hide a player's chat messages" }, unmute = { "<player>", "Show a player's chat messages again" },
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
			if p then SocialService:PromptFriendRequest(p) end
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
			if p then SocialService:PromptUnfriend(p) end
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
			disconnect("noclip")
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
return function(ctx)
	local connect, RunService, char = ctx.connect, ctx.RunService, ctx.char

	return {
		names = { "noclip" },
		run = function()
			connect("noclip", RunService.Stepped, function()
				if char() then
					for _, v in ipairs(char():GetDescendants()) do
						if v:IsA("BasePart") then v.CanCollide = false end
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
		names = { "fullbright" },
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
		names = { "unfullbright" },
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

-- what the game had when we loaded, for ;gamedefault
local H0 = ctx.hum()
state.defaults = {
	ws = H0 and H0.WalkSpeed or 16, jp = H0 and H0.JumpPower or 50, jh = H0 and H0.JumpHeight or 7.2, ujp = H0 and H0.UseJumpPower,
	hip = H0 and H0.HipHeight or 2, grav = workspace.Gravity, fov = workspace.CurrentCamera.FieldOfView,
	minz = lp.CameraMinZoomDistance, maxz = lp.CameraMaxZoomDistance,
	light = { Brightness = ctx.Lighting.Brightness, ClockTime = ctx.Lighting.ClockTime, FogEnd = ctx.Lighting.FogEnd,
		GlobalShadows = ctx.Lighting.GlobalShadows, Ambient = ctx.Lighting.Ambient },
}

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
local function unfloat()
	ctx.disconnect("float")
	if state.floatPart then state.floatPart:Destroy(); state.floatPart = nil end
	active("float", nil)
end
def({ "float" }, "", "Float above the ground (toggle)", "hover levitate air", function()
	if state.active.float then return unfloat() end
	local r, h = ctx.root(), ctx.hum()
	if not r then return end
	local y = r.Position.Y - (h and h.HipHeight or 2) - r.Size.Y / 2 + 4
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.CanCollide, p.Transparency, p.Size = "_float", true, true, 1, Vector3.new(10, 1, 10)
	p.Parent = workspace
	state.floatPart = p
	r.CFrame = r.CFrame + Vector3.new(0, 4, 0)
	ctx.markMove()
	ctx.connect("float", RS.Heartbeat, function()
		local rr = ctx.root()
		if rr then p.CFrame = CFrame.new(rr.Position.X, y - 0.5, rr.Position.Z) end
	end)
	active("float", true)
end)
def({ "unfloat" }, "", "Stop floating", "hover levitate air", unfloat)

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
	if h then h.Sit = false end
end
local function attach(kind, q, off)
	local p = ctx.findPlayer(q)
	if not p or p == lp then return end
	detach()
	state.attach = kind
	local h = ctx.hum()
	if h then h.Sit = true end
	ctx.connect("attach", RS.Heartbeat, function()
		local r, tc = ctx.root(), p.Character
		local tt = tc and (tc:FindFirstChild("UpperTorso") or tc:FindFirstChild("Torso") or tc:FindFirstChild("HumanoidRootPart"))
		if not (r and tt) then return end
		local cf
		if kind == "backpack" then
			cf = tt.CFrame * CFrame.new(0, mod.bpHeight, tonumber(off) or mod.bpDist) * CFrame.Angles(0, math.pi, 0)
		elseif kind == "baby" then
			cf = tt.CFrame * CFrame.new(0, mod.babyHeight, -(tonumber(off) or mod.babyDist)) * CFrame.Angles(0, math.rad(180 + mod.babyRot), 0)
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
def({ "unattach" }, "", "Detach from a player", "backpack baby headsit", detach)

def({ "sit" }, "", "Sit down", "seat", function()
	if state.active.antisit then return ctx.notify("Anti sit is on. Run unantisit first") end
	state.allowSit = os.clock()
	if ctx.hum() then ctx.hum().Sit = true end
end)
def({ "unsit" }, "", "Stand up", "seat", function()
	state.allowSit = os.clock()
	if ctx.hum() then ctx.hum().Sit = false end
end)

def({ "ragdoll" }, "", "Ragdoll until you press space or move", "fall limp physics", function()
	local h = ctx.hum()
	if not h then return end
	h:ChangeState(Enum.HumanoidStateType.Physics)
	if mod.ragdollBlock then
		pcall(function() ctx.StarterGui:SetCore("ResetButtonCallback", false) end)
		state.resetBlocked = true
	end
	local function stop()
		ctx.disconnect("ragdoll"); ctx.disconnect("ragdollJump")
		local hh = ctx.hum()
		if hh then hh:ChangeState(Enum.HumanoidStateType.GettingUp) end
		if state.resetBlocked then
			pcall(function() ctx.StarterGui:SetCore("ResetButtonCallback", true) end)
			state.resetBlocked = nil
		end
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
def({ "unragdoll" }, "", "Get up from ragdoll", "fall limp physics", function() if state.ragdollStop then state.ragdollStop() end end)

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
def({ "fpscap", "fps", "fpsmax" }, "[number]", "Cap the frame rate (default 60)", "frame rate performance", function(n)
	if setfpscap then setfpscap(tonumber(n) or 60) else ctx.notify("This executor has no setfpscap") end
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

def({ "antisit" }, "", "Stop forced sitting: seats can't seat you (No Sit component)", "seat lock", function()
	if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup) end
	local url
	for _, g in ipairs(GITHUB) do
		if g.name == "No Sit" then url = g.url end
	end
	local body = url and ctx.fetch(url)
	if body then
		local fn = loadstring(body)
		if fn and pcall(fn) then state.noSitComponent = true; return end
	end
	-- fallback if the component can't be downloaded: stand back up whenever something sits you down
	ctx.notify("No Sit component unavailable, using the built-in version")
	ctx.connect("antisit", RS.Heartbeat, function()
		local h = ctx.hum()
		if not h then return end
		if (h.Sit or h.SeatPart) and not state.attach and not (state.allowSit and os.clock() - state.allowSit < 1.5) then
			h.Sit = false
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
			dnotify("sit", "Anti sit: stood you back up")
		end
	end)
end)
def({ "unantisit" }, "", "Turn anti sit off", "seat lock", function()
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
		if r and r.Anchored and not state.selfFrozen then
			r.Anchored = false
			dnotify("freeze", "Anti freeze: un-anchored you")
		end
	end)
end)
def({ "unantifreeze" }, "", "Turn anti freeze off", "anchor stuck lock", function() ctx.disconnect("antifreeze") end)

-- ===== POSITION SPOOFING (holds back your outgoing replication; needs an executor that exposes NetworkClient) =====
local function netLimit(v)
	return (pcall(function() game:GetService("NetworkClient"):SetOutgoingKBPSLimit(v) end))
end
local function blinkOff()
	local b = state.blink
	if not b then return end
	state.blink = nil
	if b.ghost and b.cf and ctx.root() then ctx.markMove(); ctx.root().CFrame = b.cf end
	netLimit(math.huge)
	active("blink", nil); active("ghost", nil)
end
local function blinkOn(ghost)
	if not netLimit(1) then return ctx.notify("This executor can't limit outgoing replication, so blink won't work") end
	local r = ctx.root()
	state.blink = { ghost = ghost, cf = r and r.CFrame }
	active(ghost and "ghost" or "blink", true)
end
def({ "blink" }, "", "Freeze your position for the server while you keep moving (toggle)", "lag teleport spoof position", function()
	if state.blink then blinkOff() else blinkOn(false) end
end)
def({ "ghost", "ghostblink" }, "", "Like blink, but sends you back to where you started (toggle)", "lag teleport spoof position", function()
	if state.blink then blinkOff() else blinkOn(true) end
end)
def({ "unblink" }, "", "Turn blink / ghost off", "lag spoof position", blinkOff)

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
end
def({ "streamer", "streamermode" }, "", "Hide your name and everyone else's (names set in Module Cfg)", "name hide spoof privacy", function()
	local c = loadSpoofer()
	if not c then return end
	c.Name, c.Enabled, c.Others = mod.streamMe, true, true
end)
def({ "unstreamer", "unstreamermode" }, "", "Turn streamer mode off", "name hide spoof privacy", function()
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
def({ "gamedefault", "default", "reffect", "reseteffects" }, "", "Reset every command's changes back to the game's own values", "reset restore undo", function()
	ctx.resetAll()
	local d, h = state.defaults, ctx.hum()
	if h then
		h.WalkSpeed, h.HipHeight = d.ws, d.hip
		h.UseJumpPower = d.ujp ~= false
		h.JumpPower, h.JumpHeight, h.AutoRotate = d.jp, d.jh, true
	end
	workspace.Gravity = d.grav
	workspace.CurrentCamera.FieldOfView = d.fov
	lp.CameraMinZoomDistance, lp.CameraMaxZoomDistance = d.minz, d.maxz
	for k, v in pairs(d.light) do ctx.Lighting[k] = v end
	if setfpscap then pcall(setfpscap, 60) end
	ctx.notify("Back to the game's defaults")
end)

-- ===== GAME SPECIFIC =====
def({ "baseplate" }, "", "Extend the baseplate (MIC UP / MIC UP 18+ only)", "map floor ground mic up", function()
	if not tostring(game.Name):lower():find("mic up", 1, true) then
		return ctx.notify("baseplate only works in MIC UP and MIC UP 18+")
	end
	local bp = workspace:FindFirstChild("Baseplate")
	if not (bp and bp:IsA("BasePart")) then return ctx.notify("Couldn't find the baseplate in this server") end
	if state.basePart then state.basePart:Destroy() end
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.Material, p.Color = "_baseplateExt", true, bp.Material, bp.Color
	p.Size = Vector3.new(4096, bp.Size.Y, 4096)
	p.Position = bp.Position
	p.Parent = workspace
	state.basePart = p
	ctx.notify("Baseplate extended (only you can see and stand on it)")
end)

-- ===== TOOLS =====
-- source: a filled BUILTIN slot first, then the matching GITHUB link
local TOOLS = {
	liu = { title = "LiU", names = { "liu", "lighting", "lightingutility" }, builtin = "Lighting Utility", github = "LiU" },
	dex = { title = "Dex++", names = { "dex", "explorer", "dexpp" }, builtin = "Dex", github = "Dex++" },
	cobalt = { title = "Cobalt", names = { "cobalt", "cspy", "cobaltspy" }, builtin = "Cobalt", github = "Cobalt" },
	kelsec = { title = "Kelsec", names = { "kelsec", "executor", "exec" }, builtin = "Kelsec" },
	workwell = { title = "WorkWell", names = { "workwell" }, builtin = "WorkWell" },
	hlxp = { title = "KL HL XP", names = { "hlxp" }, builtin = "KL HL XP", github = "HLXP",
		onKill = function() if env.__HLXP_SHUTDOWN then pcall(env.__HLXP_SHUTDOWN) end end },
	rspy = { title = "RSpy", names = { "rspy", "simplespy", "remotespy" }, github = "RSpy" },
	alogger = { title = "ALogger", names = { "alogger", "audiologger" }, github = "ALogger" },
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
	return nil, "no source yet. Paste it into the '" .. tostring(t.builtin) .. "' slot in KL_rOSAD.lua"
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
	if not src then return ctx.notify(t.title .. ": " .. err) end
	local before = snapshot()
	st = { guis = {} }
	state.tools[key] = st
	ctx.runSource(src, t.title)
	task.delay(1.5, function()
		for _, root in ipairs(guiRoots()) do
			for _, c in ipairs(root:GetChildren()) do
				if not before[c] and c.Name ~= "KLOSAD" then st.guis[#st.guis + 1] = c end
			end
		end
	end)
end
local function killTool(key)
	local st = state.tools[key]
	if not st then return false end
	if TOOLS[key].onKill then TOOLS[key].onKill() end -- tools with their own shutdown get to disconnect their connections
	for _, g in ipairs(st.guis) do pcall(function() g:Destroy() end) end
	state.tools[key] = nil
	return true
end
ctx.killTools = function()
	for key in pairs(TOOLS) do killTool(key) end
end
def({ "hlxp" }, "", "Load KL HL XP (half-life movement and physics)", "movement physics half life", function() openTool("hlxp") end)
def({ "liu", "lighting", "lightingutility" }, "", "Open LiU (Lighting Utility)", "lighting camera blur shaders", function() openTool("liu") end)
def({ "dex", "explorer", "dexpp" }, "", "Open Dex++ Explorer (loads once, then reopens)", "explorer instances tree", function() openTool("dex") end)
def({ "cobalt", "cspy", "cobaltspy" }, "", "Open Cobalt remote spy", "remote spy", function() openTool("cobalt") end)
def({ "kelsec", "executor", "exec" }, "", "Open Kelsec, the in-game executor (loads once, then reopens)", "execute script run", function() openTool("kelsec") end)
def({ "rspy", "simplespy", "remotespy" }, "", "Open RSpy (SimpleSpy V3 remote spy)", "remote spy", function() openTool("rspy") end)
def({ "alogger", "audiologger" }, "", "Open ALogger (logs sounds as they play)", "audio sound log", function() openTool("alogger") end)
def({ "workwell" }, "", "Open WorkWell aim assist", "aim assist", function() openTool("workwell") end)
def({ "kill" }, "<tool>", "Close a loaded tool: dex, kelsec, cobalt, rspy, alogger, workwell, liu, hlxp, all", "close unload stop tool", function(q)
	if not q then return ctx.notify("Usage: kill <dex|kelsec|cobalt|rspy|alogger|workwell|liu|hlxp|all>") end
	q = q:lower()
	if q == "all" then ctx.killTools(); return ctx.notify("Closed every loaded tool") end
	local key = TOOL_BY[q]
	if not key then return ctx.notify("Unknown tool: " .. q) end
	ctx.notify(killTool(key) and (TOOLS[key].title .. " closed") or (TOOLS[key].title .. " isn't loaded"))
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
local function loaderLine() return 'loadstring(readfile("' .. DIR .. '/KL_rOSAD.lua"))()' end
function ctx.setAutoExec(on, quiet)
	cfg.autoExec = on and true or false
	save()
	if on then
		if queue_on_teleport then pcall(queue_on_teleport, loaderLine()) end
		local wrote = false
		if writefile then
			pcall(function()
				if makefolder and isfolder and not isfolder(DIR) then makefolder(DIR) end
				writefile(DIR .. "/KLOSAD_autoload.lua", loaderLine())
				wrote = true
			end)
			if pcall(writefile, "../autoexec/KLOSAD_autoload.lua", loaderLine()) then wrote = "autoexec" end
		end
		local there = isfile and isfile(DIR .. "/KL_rOSAD.lua")
		if not quiet then
			if wrote == "autoexec" and there then ctx.notify("Auto execute on")
			elseif not there then ctx.notify("Auto execute needs this script saved as " .. DIR .. "/KL_rOSAD.lua", 6)
			else ctx.notify("Auto execute: it re-runs after teleports. To run on join, copy " .. DIR .. "/KLOSAD_autoload.lua into your executor's autoexec folder", 7) end
		end
	elseif not quiet then
		ctx.notify("Auto execute off")
		pcall(function() if delfile and isfile and isfile("../autoexec/KLOSAD_autoload.lua") then delfile("../autoexec/KLOSAD_autoload.lua") end end)
	end
end
def({ "keeposad" }, "", "Run rOSAD automatically when you join a game", "auto execute autoexec startup", function() ctx.setAutoExec(true) end)
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
	local ok = pcall(function()
		local vc = game:GetService("VoiceChatInternal")
		ctx.connect("avc", vc.PlayerModerated, function(uid)
			if uid ~= lp.UserId or avcTimer then return end
			avcTimer = os.clock()
			local my = avcTimer
			ctx.notify("Voice chat ban detected. Rejoining in 5 minutes", 6)
			task.delay(300, function()
				if avcTimer == my and cfg.avc then ctx.Run("rejoin") end
			end)
		end)
	end)
	if not quiet then ctx.notify(ok and "Auto rejoin on VC ban on" or "Couldn't hook VC ban detection in this executor", 5) end
end
def({ "arjvc", "avc", "autorejoinvc" }, "", "Toggle: rejoin 5 minutes after a voice chat ban", "voice vc ban rejoin auto", function()
	ctx.setAvc(not cfg.avc)
end)
if cfg.autoExec then task.defer(function() ctx.setAutoExec(true, true) end) end
if cfg.avc then task.defer(function() ctx.setAvc(true, true) end) end
end

-- extra command files from KLOSAD/commands (same format, override built-ins with the same name)
ctx.loadFolder(DIR .. "/commands")

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
	paint(b, "BackgroundColor3", key)
	b:SetAttribute("base", tr)
	b.BackgroundTransparency = tr
end
-- reference button: 1px edge, ~3px corners, text 9pt, left inset 9.6. Hover and press are animated.
local function btn(parent, str, x, y, w, h, key, tr, cb, pt)
	local b = new("TextButton", { Text = str, TextSize = fs(pt or 9), Font = FONT, AutoButtonColor = false, BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
	paint(b, "TextColor3", "text")
	setFill(b, key or "btnFill", key and tr or BTN_OFF)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b)
	paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b), "Color", "edge")
	b.MouseEnter:Connect(function() if b.Active then tw(b, { BackgroundTransparency = math.max(b:GetAttribute("base") - 0.15, 0) }, 0.1) end end)
	b.MouseLeave:Connect(function() tw(b, { BackgroundTransparency = b:GetAttribute("base") }, 0.12) end)
	b.MouseButton1Down:Connect(function() if b.Active then tw(b, { BackgroundTransparency = math.max(b:GetAttribute("base") - 0.3, 0) }, 0.05) end end)
	b.MouseButton1Click:Connect(function()
		if b.Active then
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
	o.Focused:Connect(function() paint(stroke, "Color", "dim") end)
	o.FocusLost:Connect(function() paint(stroke, "Color", "edge") end)
	return o
end
local function scroller(parent, x, y, w, h)
	return new("ScrollingFrame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = col("dim"), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ElasticBehavior = Enum.ElasticBehavior.Never }, parent)
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
		Font = FONT, TextSize = fs(11), TextWrapped = true, Visible = false, ZIndex = 50 }, gui)
	paint(t, "BackgroundColor3", "bar"); paint(t, "TextColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, t)
	paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, t), "Color", "panelEdge")
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
		tw(t, { Position = UDim2.new(0.5, 0, 1, -70), BackgroundTransparency = 0.1, TextTransparency = 0 }, 0.2)
		task.delay(secs or 3, function()
			if id == my then
				tw(t, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.2)
				task.delay(0.25, function() if id == my then t.Visible = false end end)
			end
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
			e = { canon = canon, names = { canon }, desc = m.desc or "", args = m.args or "", tags = m.tags or "" }
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

-- ===== UI: command bar (slides 2-3: 647x51 pill at 318, list 593 wide right under it) ==============
do
	local bar = new("Frame", { Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(647, 51), BackgroundTransparency = 1, Visible = false, ZIndex = 10 }, gui)
	ui.barScale = new("UIScale", {}, bar)
	fr(bar, 0, 0, 647, 51, "bar", 0, 25, "panelEdge", 2)

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
	paint(new("UIStroke", { Thickness = 2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, listF), "Color", "panelEdge")
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

	-- position as screen fractions: UIScale can't skew those. Center = the reference's y of 318/1080.
	function ui.layoutBar()
		local p = cfg.pos
		bar.Position = UDim2.fromScale(0.5, p == "Top" and 0.06 or p == "Bottom" and 0.86 or 318 / 1080)
		listF.AnchorPoint = Vector2.new(0.5, p == "Bottom" and 1 or 0)
		listF.Position = p == "Bottom" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0.5, 0, 0, 51)
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

	function ui.render()
		local n = math.min(#S.cur, cfg.lines)
		for i = 1, 20 do
			local r, e = rows[i], S.cur[i]
			if i <= n and e then
				r.Visible = true
				r.Text = rowText(e, S.q or "")
				r.BackgroundTransparency = (i == S.sel) and 0.92 or 1
			else
				r.Visible = false
			end
		end
		listF.Visible = n > 0
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
		S.q, S.sel, S.cur, S.ghost, S.ghostX = q, 1, {}, "", nil
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
			if S.showAll then S.cur = ui.entries() end
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
		ui.render()
	end

	function ui.move(d)
		if #S.cur == 0 then return end
		local n = math.min(#S.cur, cfg.lines)
		S.sel = (S.sel - 1 + d) % n + 1
		ui.render()
	end

	-- Tab only completes the name; no trailing space
	function ui.complete()
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
		ui.layoutBar()
		box.Text = prefill or ""
		bar.Visible = true
		local s = ui.curScale()
		ui.barScale.Scale = s * 0.96
		tw(ui.barScale, { Scale = s }, 0.14)
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
		S.barOpen = false
		box:ReleaseFocus()
		box.Text = ""
		bar.Visible = false
		if ui.shade then ui.shade.Visible = false end
		tw(ui.blur, { Size = 0 }, 0.2)
		ui.syncMouse()
	end

	box:GetPropertyChangedSignal("Text"):Connect(function() if S.barOpen then ui.search() end end)
	box.FocusLost:Connect(function(enter)
		if not S.barOpen then return end
		local line = box.Text
		ui.closeBar()
		if enter and line:match("%S") then ctx.Run(line) end
	end)
end

-- ===== UI: panel frame (slide 4: 685x443, sidebar 141x36 tabs, inner 532x379 at 141,52) ===========
local pages, tabs, onShow = {}, {}, {}
do
	local panel = new("Frame", { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(685, 443), BorderSizePixel = 0, Visible = false }, gui)
	paint(panel, "BackgroundColor3", "panel") -- transparency comes from the UI Opacity setting (reference: 80%)
	new("UICorner", { CornerRadius = UDim.new(0, 9) }, panel)
	paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel), "Color", "panelEdge")
	ui.panel = panel
	ui.panelScale = new("UIScale", {}, panel)

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

	local close = btn(panel, "×", 641, 13, 32, 26, "ctrlOff", BTN_OFF, function() ui.setPanel(false) end, 13)
	close:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 0)

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
	local TABS = { { "Home", 66 }, { "Players", 102 }, { "Look and feel", 137 }, { "Load scripts", 173 }, { "Keybinds", 208 },
		{ "Module Cfg", 244 }, { "Commands", 279 }, { "Preferences", 315 } }
	for _, t in ipairs(TABS) do
		local name = t[1]
		local b = new("TextButton", { Position = UDim2.fromOffset(0, t[2]), Size = UDim2.fromOffset(141, 36), AutoButtonColor = false, BorderSizePixel = 0,
			Text = name, Font = FONT, TextSize = fs(10), TextXAlignment = Enum.TextXAlignment.Right }, panel)
		new("UIPadding", { PaddingRight = UDim.new(0, 10) }, b)
		paint(b, "TextColor3", "text")
		b.BackgroundTransparency = 0.9
		tabs[name] = b
		b.MouseEnter:Connect(function() if ui.tab ~= name then tw(b, { BackgroundTransparency = 0.8 }, 0.1) end end)
		b.MouseLeave:Connect(function() if ui.tab ~= name then tw(b, { BackgroundTransparency = 0.9 }, 0.12) end end)
		b.MouseButton1Click:Connect(function() ui.selectTab(name) end)
		pages[name] = new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, inner)
	end

	function ui.selectTab(name)
		ui.tab = name
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabs) do
			paint(b, "BackgroundColor3", n == name and "tabOn" or "tabOff")
			tw(b, { BackgroundTransparency = n == name and 0.55 or 0.9 }, 0.12)
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
			ui.panelScale.Scale = s * 0.96
			tw(ui.panelScale, { Scale = s }, 0.18)
			ui.placePanel(14, false)
			panel.Visible = true
			ui.placePanel(0, true)
			ui.shade.Visible = S.barOpen and true or false
			if onShow[ui.tab] then onShow[ui.tab]() end
		else
			panel.Visible = false
		end
		ui.syncMouse()
	end
end

-- ===== page: Home (slide 4, positions = deck coords minus the inner origin 657,340) ===================
do
	local h = pages["Home"]
	txt(h, "Good day, " .. lp.DisplayName, 14, "text", 17, 15, 229, 23, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
	txt(h, "Welcome to your favourite, and trusted admin panel.", 10.5, "text", 17, 49, 342, 17)
	txt(h, "Experience: " .. game.Name, 11, "text", 26, 77, 315, 18, { TextTruncate = Enum.TextTruncate.AtEnd })

	-- stats: four rows that together span exactly the icon's height (105..215), each text centred in its row
	local vals, region = {}, "-"
	for i, name in ipairs({ "Players", "Locale", "Latency", "Uptime" }) do
		vals[name] = txt(h, name .. ": -", 11, "text", 18, 105 + math.floor((i - 1) * 27.5), 135, 27, { TextYAlignment = Enum.TextYAlignment.Center })
	end
	-- game icon: square (the deck's is 196x110; this one is 110x110)
	local icon = new("ImageLabel", { Position = UDim2.fromOffset(159, 105), Size = UDim2.fromOffset(110, 110), BorderSizePixel = 0,
		ScaleType = Enum.ScaleType.Crop, Image = thumb("GameIcon", game.GameId, 150) }, h)
	paint(icon, "BackgroundColor3", "row")
	icon.BackgroundTransparency = 0.9
	local tip = txt(h, "Tips: " .. TIPS[1], 9, "dim", 17, 230, 340, 58, { TextWrapped = true })

	fr(h, 373, 14, 1, 349, "dim", 0.5)
	local av = new("ImageLabel", { Position = UDim2.fromOffset(398, 22), Size = UDim2.fromOffset(110, 110), BorderSizePixel = 0, BackgroundTransparency = 0.9,
		Image = thumb("AvatarHeadShot", lp.UserId, 150) }, h)
	paint(av, "BackgroundColor3", "row")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
	paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, av), "Color", "dim")
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
			end
			task.wait(1)
		end
	end)
end

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
				paint(new("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a), "Color", "dim")
				copyable(r, p.DisplayName, hl(p.DisplayName, q) .. (p == lp and " (you)" or ""), 80, 21, 230, 16, 10, "text2", { Font = FONT_B })
				copyable(r, p.Name, hl("@" .. p.Name, q), 80, 39, 230, 13, 8, "sub")
				if p == lp then
					btn(r, "Respawn", 423, 27, 95, 23, "btnFill", BTN_OFF, function() ctx.Run("reset") end)
				else
					btn(r, state.viewing == p and "Unview" or "View", 319, 12, 95, 23, nil, nil, function()
						ctx.Run(state.viewing == p and "unview" or ("view " .. p.Name))
						render()
					end)
					local fb = btn(r, "Add Friend", 425, 12, 95, 23, nil, nil, function() ctx.Run("friend " .. p.Name) end)
					if friends[p.UserId] == nil then
						task.spawn(function()
							local ok, res = pcall(function() return lp:IsFriendsWith(p.UserId) end)
							friends[p.UserId] = ok and res or false
							greyOut(fb, friends[p.UserId])
						end)
					else
						greyOut(fb, friends[p.UserId])
					end
					btn(r, "Go to", 319, 41, 95, 23, nil, nil, function() ctx.Run("goto " .. p.Name) end)
					btn(r, state.muted[p.UserId] and "Unmute" or "Mute", 425, 41, 95, 23, nil, nil, function(b)
						local on = not state.muted[p.UserId]
						ctx.setMuted(p.UserId, on)
						b.Text = on and "Unmute" or "Mute"
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
		for _, s in ipairs(BUILTIN) do
			if show(s.name) then
				local filled = (s.src:gsub("%-%-[^\n]*", "")):match("%S")
				local b = item(s.name, filled and s.desc or "empty slot: paste the script into KL_rOSAD.lua", true, "Execute", "b:" .. s.name,
					function() if filled then ctx.runSource(s.src, s.name) end end)
				if not filled then b.Active = false; b.TextTransparency = 0.5 end
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
			if #found == 0 and q == "" then empty(list, "Drop .lua files into " .. DIR .. "/scripts and reopen this tab.") end
		else
			empty(list, "File access isn't available in this executor.")
		end
		for _, g in ipairs(GITHUB) do
			if show(g.name) then
				item(g.name, (g.desc and g.desc ~= "" and (g.desc .. "  |  ") or "") .. ghInfo(g.url), false, "Execute", "g:" .. g.url, function()
					local body, err = ctx.fetch(g.url)
					if body then ctx.runSource(body, g.name) else ctx.notify(g.name .. ": download failed (" .. tostring(err) .. ")") end
				end)
			end
		end
	end
	sbox:GetPropertyChangedSignal("Text"):Connect(render)
	onShow["Load scripts"] = render
end

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

-- ===== pages without a slide (Keybinds, Module Cfg, Preferences): same tokens and sizes, flow layout ======
local function flow(name)
	local sc = scroller(pages[name], 0, 0, 532, 379)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sc)
	new("UIPadding", { PaddingLeft = UDim.new(0, 21), PaddingRight = UDim.new(0, 21), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, sc)
	return sc
end
local function fhdr(sc, str) return txt(sc, str, 14, "text", 0, 0, 400, 23, { LayoutOrder = nx(), Font = FONT_B }) end
-- label on the left, a right-anchored group (width w) on the right
local function frow(sc, str, w)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, sc)
	txt(r, str, 12, "text", 12, 2, 250, 19)
	return new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(w, 23), BackgroundTransparency = 1 }, r)
end

do
	local pg = flow("Keybinds")
	local function keyRow(text, key)
		local g = frow(pg, text, 96)
		return btn(g, "", 0, 0, 96, 23, "ctrlOff", BTN_OFF, function(b)
			b.Text = "press a key..."
			S.capture = function(kc)
				if kc ~= Enum.KeyCode.Escape then cfg[key] = kc.Name; save() end
				ui.apply()
			end
		end)
	end
	fhdr(pg, "Keys")
	local barBtn, panelBtn = keyRow("Command bar key", "barKey"), keyRow("Panel key", "panelKey")
	fhdr(pg, "Bound keys")
	local blist = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, blist)

	local addRow = new("Frame", { Size = UDim2.new(1, 0, 0, 23), BackgroundTransparency = 1, LayoutOrder = nx() }, pg)
	local newKey
	local kb = btn(addRow, "key", 0, 0, 60, 23, "ctrlOff", BTN_OFF, function(b)
		b.Text = "press a key..."
		S.capture = function(kc)
			if kc ~= Enum.KeyCode.Escape then newKey = kc.Name end
			b.Text = newKey and keyStr(newKey) or "key"
		end
	end)
	local cb = input(addRow, "command, e.g. fly 80", 66, 0, 0, 23, 9, "ctrlOff", BTN_OFF)
	cb.Parent.Size = UDim2.new(1, -140, 0, 23)
	local ab = btn(addRow, "Add", 0, 0, 68, 23, "btnFill", BTN_OFF, function()
		if newKey and cb.Text:match("%S") then
			ctx.setBind(newKey, cb.Text)
			newKey, cb.Text, kb.Text = nil, "", "key"
		else
			ctx.notify("Pick a key and type a command first")
		end
	end)
	ab.AnchorPoint = Vector2.new(1, 0); ab.Position = UDim2.new(1, 0, 0, 0)

	function ui.refreshKeys()
		barBtn.Text, panelBtn.Text = "[ " .. keyStr(cfg.barKey) .. " ]", "[ " .. keyStr(cfg.panelKey) .. " ]"
		clear(blist)
		local names = {}
		for k in pairs(cfg.binds) do names[#names + 1] = k end
		table.sort(names)
		if #names == 0 then txt(blist, "No binds yet.", 10, "sub", 0, 0, 300, 22, { LayoutOrder = 1 }) end
		for i, k in ipairs(names) do
			local r = fr(blist, 0, 0, 100, 32, "row", 0.9, 4)
			r.Size, r.LayoutOrder = UDim2.new(1, 0, 0, 32), i
			txt(r, "[ " .. keyStr(k) .. " ]", 12, "accentText", 12, 7, 80, 18, { Font = FONT_B })
			txt(r, cfg.binds[k], 12, "text2", 96, 7, 300, 18, { TextTruncate = Enum.TextTruncate.AtEnd })
			local x = btn(r, "×", 0, 0, 22, 22, nil, nil, function() ctx.setBind(k, nil) end, 11)
			x.AnchorPoint = Vector2.new(1, 0.5); x.Position = UDim2.new(1, -5, 0.5, 0)
		end
	end
	onShow["Keybinds"] = ui.refreshKeys
end

-- Module Cfg: default values and multipliers for commands. Typing a number commits on Enter / click away.
do
	local pg = flow("Module Cfg")
	local M = cfg.mod
	local function numRow(label, key)
		local g = frow(pg, label, 96)
		local o = input(g, "", 0, 0, 96, 23, 9, "ctrlOff", BTN_OFF, { Text = tostring(M[key]), TextXAlignment = Enum.TextXAlignment.Center })
		o.FocusLost:Connect(function()
			local v = tonumber(o.Text)
			if v then M[key] = v; save() end
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
		seg(frow(pg, label, 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, key, function() end, M)
	end
	local function optRow(label, key, opts, w)
		local xs = {}
		for i = 1, #opts do xs[i] = (i - 1) * (w + 8) end
		seg(frow(pg, label, #opts * (w + 8) - 8), 0, xs, w, opts, key, function() end, M)
	end

	fhdr(pg, "Speed and fly")
	numRow("Fly: default speed", "flyDef"); numRow("Fly: multiplier", "flyMult")
	numRow("Speed: default", "speedDef"); numRow("Speed: multiplier", "speedMult")
	numRow("Jump power: default", "jpDef"); numRow("Jump power: multiplier", "jpMult")
	numRow("Spin: default (rotations/s)", "spinDef"); numRow("Spin: multiplier", "spinMult")
	fhdr(pg, "Tpwalk")
	optRow("Mode", "tpMode", { { "Multiplier", "Multiplier" }, { "Additive", "Additive" } }, 84)
	numRow("Default amount", "tpDef"); numRow("Maximum (cap)", "tpCap")
	fhdr(pg, "Follow, backpack, baby")
	numRow("Follow: default radius (studs)", "followRadius")
	numRow("Backpack: distance", "bpDist"); numRow("Backpack: height", "bpHeight")
	numRow("Baby: distance", "babyDist"); numRow("Baby: height", "babyHeight"); numRow("Baby: rotation (degrees)", "babyRot")
	fhdr(pg, "Display and misc")
	optRow("Show FPS corner", "fpsCorner", { { "TL", "TL" }, { "TR", "TR" }, { "BL", "BL" }, { "BR", "BR" } }, 47)
	togRow("Ragdoll blocks game reset", "ragdollBlock")
	fhdr(pg, "Streamer mode")
	strRow("Your name", "streamMe"); strRow("Other players (comma separated)", "streamOthers")
	fhdr(pg, "Defense")
	togRow("Defense notifications", "defNotify")
	numRow("Anti fling: radius", "afRadius"); numRow("Anti fling: velocity threshold", "afThreshold"); numRow("Anti fling: restore time (s)", "afRestore")
	numRow("Anti teleport: min distance", "atpMin"); numRow("Anti knockback: max speed", "akMax")
	numRow("Anti void: height above destroy", "avHeight")
	numRow("Anti ear rape: threshold", "aeThreshold"); numRow("Anti ear rape: window (s)", "aeDuration")
	numRow("Anti afk: interval (s)", "afkInterval"); numRow("Anti spam: messages", "spamCount")
	onShow["Module Cfg"] = function() if ui.layoutHud and state.active.showfps then ui.layoutHud() end end
end

do
	local pg = flow("Preferences")
	fhdr(pg, "General")
	seg(frow(pg, "Notifications", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "toasts")
	seg(frow(pg, "Auto execute", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "autoExec", function(v) ctx.setAutoExec(v) end)
	seg(frow(pg, "Auto rejoin on VC ban", 102), 0, { 0, 55 }, 47, { { "On", true }, { "Off", false } }, "avc", function(v) ctx.setAvc(v) end)
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

-- ===== apply settings, wire input, start ===================================
-- 1080p is the design size: scale = screen height / 1080, then the UI Scaling setting on top.
function ui.curScale() return cfg.scale * workspace.CurrentCamera.ViewportSize.Y / 1080 end
function ui.rescale()
	local s = ui.curScale()
	ui.panelScale.Scale, ui.barScale.Scale, ui.toastScale.Scale, ui.hudScale.Scale = s, s, s, s
end

function ui.apply()
	S.accent = parseHex(cfg.accent) or S.accent
	S.accentText = legible(S.accent, THEMES[cfg.theme].panel)
	applyTheme()
	ui.rescale()
	ui.panel.BackgroundTransparency = 1 - cfg.opacity
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
		f(kc)
		return
	end
	if S.barOpen then
		if kc == Enum.KeyCode.Escape then ui.closeBar()
		elseif kc == Enum.KeyCode.Tab then ui.complete()
		elseif kc == Enum.KeyCode.Down then ui.move(1)
		elseif kc == Enum.KeyCode.Up then ui.move(-1) end
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
		local line = cfg.binds[kc.Name]
		if line then ctx.Run(line) end
	end
end)

conn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
	ui.rescale()
	ui.layoutBar()
end)

function ui.unload()
	S.alive = false
	pcall(ctx.resetAll)
	for _, c in ipairs(S.cons) do pcall(function() c:Disconnect() end) end
	for k in pairs(state.conns) do ctx.disconnect(k) end
	state.muted = {}
	if state.chat then state.chat.spam = false end
	pcall(function() -- hand the chat handler back to the game
		if S.chatPrev then S.TextChatService.OnIncomingMessage = S.chatPrev.fn end
	end)
	S.panelOpen, S.barOpen = false, false
	ui.syncMouse()
	pcall(function() ui.blur:Destroy() end)
	pcall(function() gui:Destroy() end)
	env.KLOSAD = nil
end

ui.apply()
ui.selectTab("Home")
env.KLOSAD = { Unload = ui.unload, ctx = ctx, cfg = cfg, ui = ui, version = VERSION }
if not (HAS_FS and HAS_LOAD) then ctx.notify("Limited mode: this executor has no file access or loadstring.", 5) end
ctx.notify("KL rOSAD loaded. Press " .. keyStr(cfg.barKey) .. " for commands, " .. keyStr(cfg.panelKey) .. " for the panel.", 5)
