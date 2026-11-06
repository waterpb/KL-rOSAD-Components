-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py). Markers use "--" (Lua), not "//".
-- [BOOT] scale, services, single-instance guard, bind/px/new/tween | S, bind(), px(), new(), tween() | deps: none | L27-74
-- [THEME] colors, fonts, panel/inner/outline tokens | WHITE, ACCENT, PANEL, INNER, OUTLINE, F_* | deps: BOOT | L76-96
-- [SETTINGS] settings file load/save | settings, save(), box, fullText | deps: BOOT | L100-123
-- [GUIROOT] ScreenGui root, screenSize, zTop, overFrame | gui, screenSize(), front(), overFrame() | deps: SETTINGS | L125-146
-- [PANELS] panel frame, pop/fade, drag | newPanel(), setTL(), popOpen(), fadeClose(), makeDrag() | deps: GUIROOT | L148-249
-- [WIDGETS] box2, label, icon, inner, window buttons, scrollbar | box2(), label(), inner(), xButton(), minButton(), scrollbar() | deps: PANELS | L251-381
-- [HIGHLIGHT] Lua syntax highlighter | highlight() | deps: none | L383-447
-- [LOGSTATE] log queue, unread dot | emit(), updateDot(), stamp() | deps: WIDGETS | L449-480
-- [KEEP] keep executor after teleport, auto re-join, server hop | queueSelf(), findServer() | deps: LOGSTATE, SETTINGS | L482-547
-- [EXEC_PANEL] executor panel, title morph, header, window buttons | ex, titleMorph(), minBtn, closeBtn | deps: PANELS, WIDGETS | L549-597
-- [WINMODEL] script model: head lines + window + tail lines, unit tested | newDoc(), lineStart(), cut() | deps: none | L599-709
-- [EDITOR] windowed + culled code editor, whole-script selection (Ctrl+A, drag, shift+click, Ctrl+Home/End) | box, doc, sf, setWindow(), renderSlice(), onEdited(), syncNative() | deps: EXEC_PANEL, HIGHLIGHT, WINMODEL | L711-1142
-- [EXEC_BTNS] bottom row buttons settings / logs / run | gearBtn, logsBtn, runBtn, dot | deps: EXEC_PANEL | L1144-1151
-- [LOGS] logs panel, log list, LogService hook | logsP, pushLine() | deps: WIDGETS, LOGSTATE | L1153-1225
-- [SETTINGS_UI] settings panel with its toggles | setP | deps: WIDGETS, SETTINGS | L1227-1267
-- [PLACE] open / place panels | place(), toggleLogs(), toggleSettings() | deps: LOGS, SETTINGS_UI | L1269-1293
-- [RUN] run the script | run() | deps: EDITOR | L1295-1313
-- [WINDOW] minimize / restore / close, header drag | minimize(), restore(), closeExecutor(), api | deps: all | L1315-1385
-- [ENTRY] startup | popOpen(ex) | deps: all | L1387-1391

--// >kelsec v1.0.0 : LocalScript executor
--// All sizes are the deck's 1080p pixels (1 slide inch = 144 px).
--// Save this file as "kelsec.lua" in your executor's workspace folder if you want
--// "Keep executor between sessions" to work (it re-loads that file after a teleport).

-- [BOOT]
local S = 1 -- UI scale. 1 = exact deck size on a 1080p screen



local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local genv = (getgenv and getgenv()) or _G

-- only one executor at a time: re-running closes the old one cleanly
if genv.__kelsec then pcall(genv.__kelsec.close, true) end

---------------------------------------------------------------- basics
local conns, alive = {}, true
local function bind(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function px(n) return math.floor(n * S + 0.5) end
local function V2(x, y) return Vector2.new(x, y) end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

-- ONE easing for every animation: very fast at the start, long slow settle (logarithmic).
-- Exponential is the hardest. Softer options: Quint, Quart, Cubic, Quad, Sine (softest).
local EASE, EASE_DIR = Enum.EasingStyle.Exponential, Enum.EasingDirection.Out
local function tween(o, dur, props, style, dir, delay)
	local t = TweenService:Create(o, TweenInfo.new(dur, style or EASE, dir or EASE_DIR, 0, false, delay or 0), props)
	t:Play()
	return t
end
-- [/BOOT]

-- [THEME]
-- KL rOSAD dark theme, same values: panel 80% opaque, recessed areas 50%, 1px edges, yellow accent
local WHITE = Color3.new(1, 1, 1)
local ACCENT = Color3.fromRGB(255, 255, 0)
local CYAN = Color3.fromRGB(0x4F, 0xE3, 0xF0) -- logs: what the executor itself says
local GREEN = Color3.fromRGB(0x15, 0xD9, 0x7C) -- logs: game output
local LOG_TXT = Color3.fromRGB(0xD6, 0xD6, 0xDB)
local LOG_WARN = Color3.fromRGB(0xFF, 0xC9, 0x6B)
local LOG_ERR = Color3.fromRGB(0xFF, 0x6B, 0x6B)

local F_CODE, F_MONO, F_UI = Enum.Font.Code, Enum.Font.RobotoMono, Enum.Font.SourceSans

local PANEL, PANEL_T = Color3.fromRGB(13, 13, 13), 0.2 -- window fill
local INNER, INNER_T = Color3.fromRGB(24, 23, 23), 0.5 -- recessed editor / log / settings areas
local OUTLINE = Color3.fromRGB(70, 67, 67) -- window outline
local EDGE = Color3.fromRGB(88, 84, 84) -- button outline
local BTN_FILL, CTRL_ON, CTRL_OFF = Color3.fromRGB(66, 63, 63), Color3.fromRGB(118, 113, 113), Color3.fromRGB(52, 50, 50)
local BTN_ON, BTN_OFF = 0.2, 0.4 -- fill transparency of a selected / normal button
local SCROLL = Color3.fromRGB(118, 113, 113)
local SEL = Color3.fromRGB(0x26, 0x4F, 0x78) -- editor selection
-- [/THEME]



-- [SETTINGS]
---------------------------------------------------------------- settings / files
local SETTINGS_FILE, SELF_FILE = "kelsec_settings.json", "kelsec.lua"
local SAMPLE = 'print("Hello, World!")'
local OLD_SAMPLE = 'local Players = game:GetService("Players")\nlocal TeleportService = game:GetService("TeleportService")\n\nlocal player = Players.LocalPlayer\nlocal placeId = game.PlaceId\nlocal jobId = game.JobId'
local settings = { keep = true, sendLogs = false, autoRejoin = false, serverHop = false }

if isfile and readfile then
	pcall(function()
		if isfile(SETTINGS_FILE) then
			for k, v in pairs(HttpService:JSONDecode(readfile(SETTINGS_FILE))) do settings[k] = v end
		end
	end)
end

if settings.code == OLD_SAMPLE then settings.code = nil end -- old starter -> new starter

local box, doc, fullText -- editor TextBox; doc = the script model: lines above / below the TextBox window (assigned below)
local function save()
	if not writefile then return end
	if fullText then settings.code = fullText() end
	pcall(writefile, SETTINGS_FILE, HttpService:JSONEncode(settings))
end
-- [/SETTINGS]

-- [GUIROOT]
---------------------------------------------------------------- gui root
local gui = new("ScreenGui", {
	Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, nil)
gui.Parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")

local function screenSize()
	local s = gui.AbsoluteSize
	if s.X < 10 then s = workspace.CurrentCamera.ViewportSize end
	return s
end

local zTop = 1
local function front(p) zTop += 1 p.root.ZIndex = zTop end

local function overFrame(f)
	local m, p, s = UIS:GetMouseLocation(), f.AbsolutePosition, f.AbsoluteSize
	return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end
-- [/GUIROOT]

-- [PANELS]
---------------------------------------------------------------- panels
-- Root (top-left anchored, integer px)
--   Glass   : flat fill, rounded
--   Border  : 1px stroke, rounded
--   Clip    : clips Content while the executor shrinks
--     Content (CanvasGroup) : everything inside the panel, fades as one
local function newPanel(name, w, h, radius)
	local p = { W = px(w), H = px(h), isOpen = false, token = 0, strokeT = 0, tl = V2(0, 0), groups = {} }
	p.root = new("Frame", { Name = name, Size = UDim2.fromOffset(p.W, p.H), BackgroundTransparency = 1, Visible = false }, gui)
	p.glass = new("Frame", { Name = "Glass", Size = UDim2.fromScale(1, 1), BackgroundColor3 = PANEL, BackgroundTransparency = 1, BorderSizePixel = 0 }, p.root)
	new("UICorner", { CornerRadius = UDim.new(0, px(radius)) }, p.glass)
	local border = new("Frame", { Name = "Border", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100 }, p.root)
	new("UICorner", { CornerRadius = UDim.new(0, px(radius)) }, border)
	p.stroke = new("UIStroke", { Color = OUTLINE, Thickness = 1, Transparency = 1 }, border)
	p.clip = new("Frame", { Name = "Clip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2 }, p.root)
	p.content = new("CanvasGroup", { Name = "Content", Size = UDim2.fromOffset(p.W, p.H), BackgroundTransparency = 1, GroupTransparency = 1 }, p.clip)
	p.groups[1] = p.content
	p.scale = new("UIScale", {}, p.root)
	return p
end

local function applyPos(p)
	local v = p.tl
	if p.popping then -- scale from the center while popping
		p.root.AnchorPoint = V2(0.5, 0.5)
		p.root.Position = UDim2.fromOffset(v.X + p.root.Size.X.Offset / 2, v.Y + p.root.Size.Y.Offset / 2)
	else
		p.root.AnchorPoint = V2(0, 0)
		p.root.Position = UDim2.fromOffset(v.X, v.Y)
	end
end

local function setTL(p, v)
	local sz = screenSize()
	local w = p.root.Size.X.Offset
	p.tl = V2(math.clamp(math.floor(v.X + 0.5), -(w - 80), sz.X - 80), math.clamp(math.floor(v.Y + 0.5), 0, sz.Y - 36))
	applyPos(p)
end

local function setShown(p, on, dur)
	for _, g in ipairs(p.groups) do tween(g, dur, { GroupTransparency = on and 0 or 1 }) end
	tween(p.stroke, dur, { Transparency = on and p.strokeT or 1 })
	return tween(p.glass, dur, { BackgroundTransparency = on and PANEL_T or 1 })
end

-- opening: pops from small + fades from transparent. closing: fades out.
local function popOpen(p)
	p.token += 1
	local tk = p.token
	p.isOpen = true
	p.popping = true
	p.root.Visible = true
	p.scale.Scale = 0.55
	applyPos(p)
	front(p)
	tween(p.scale, 0.3, { Scale = 1 })
	setShown(p, true, 0.2)
	task.delay(0.34, function()
		if alive and p.token == tk then p.popping = false applyPos(p) end
	end)
end

local function fadeClose(p, cb)
	p.token += 1
	local tk = p.token
	p.isOpen = false
	local t = setShown(p, false, 0.18)
	t.Completed:Connect(function()
		if p.token == tk then
			p.root.Visible = false
			if cb then cb() end
		end
	end)
end

local function makeDrag(handle, get, set, onClick, gate)
	local active, moved, m0, p0 = false, false, nil, nil
	bind(handle.InputBegan, function(i)
		local t = i.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		if gate and not gate() then return end
		active, moved = true, false
		m0, p0 = V2(i.Position.X, i.Position.Y), get()
	end)
	bind(UIS.InputChanged, function(i)
		if not active then return end
		local t = i.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
		local d = V2(i.Position.X, i.Position.Y) - m0
		if not moved and d.Magnitude > 4 then moved = true end
		if moved then set(p0 + d) end
	end)
	bind(UIS.InputEnded, function(i)
		local t = i.UserInputType
		if active and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then
			active = false
			if not moved and onClick then onClick() end
		end
	end)
end
-- [/PANELS]

-- [WIDGETS]
---------------------------------------------------------------- small widgets
local function box2(parent, x, y, w, h, props)
	props = props or {}
	props.Position = UDim2.fromOffset(px(x), px(y))
	props.Size = UDim2.fromOffset(px(w), px(h))
	props.BorderSizePixel = 0
	return new("Frame", props, parent)
end

local function label(parent, text, x, y, w, h, font, size, color, align)
	return new("TextLabel", {
		Text = text, Position = UDim2.fromOffset(px(x), px(y)), Size = UDim2.fromOffset(px(w), px(h)),
		BackgroundTransparency = 1, Font = font, TextSize = px(size), TextColor3 = color or WHITE,
		TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 5,
	}, parent)
end

local function fs(pt) return math.floor(pt * 4 / 3 * 1.08 + 0.5) end -- rOSAD point sizes -> design px

-- recessed rounded area used for the editor, log list and settings list
local function inner(parent, x, y, w, h)
	local f = box2(parent, x, y, w, h, { BackgroundColor3 = INNER, BackgroundTransparency = INNER_T, ClipsDescendants = true })
	new("UICorner", { CornerRadius = UDim.new(0, px(8)) }, f)
	return f
end

-- rOSAD button: 3px corners, 1px edge, fades lighter on hover and press. fill nil = the normal button look
local function btn(parent, str, x, y, w, h, fill, tr, cb, pt)
	local b = new("TextButton", {
		Text = str, Font = F_UI, TextSize = px(fs(pt or 9)), TextColor3 = WHITE, AutoButtonColor = false, BorderSizePixel = 0,
		BackgroundColor3 = fill or BTN_FILL, BackgroundTransparency = tr or BTN_OFF,
		Position = UDim2.fromOffset(px(x), px(y)), Size = UDim2.fromOffset(px(w), px(h)), ZIndex = 10,
	}, parent)
	b:SetAttribute("base", b.BackgroundTransparency)
	new("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	new("UIStroke", { Color = EDGE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local function shade(d, t) tween(b, t, { BackgroundTransparency = math.max(b:GetAttribute("base") - d, 0) }) end
	b.MouseEnter:Connect(function() shade(0.15, 0.1) end)
	b.MouseLeave:Connect(function() shade(0, 0.12) end)
	b.MouseButton1Down:Connect(function() shade(0.3, 0.05) end)
	b.MouseButton1Click:Connect(function()
		shade(0.15, 0.1)
		if cb then cb(b) end
	end)
	return b
end

-- selected / normal look of a button (the On / Off pairs)
local function fill(b, on)
	b.BackgroundColor3 = on and CTRL_ON or CTRL_OFF
	b.BackgroundTransparency = on and BTN_ON or BTN_OFF
	b:SetAttribute("base", b.BackgroundTransparency)
end

-- window buttons: 28 x 26 boxes centred on cx, cy
local function xButton(parent, cx, cy) return btn(parent, "×", cx - 14, cy - 13, 28, 26, CTRL_OFF, BTN_OFF, nil, 13) end
local function minButton(parent, cx, cy) return btn(parent, "–", cx - 14, cy - 13, 28, 26, CTRL_OFF, BTN_OFF, nil, 13) end

-- custom scrollbar: hidden when not needed, 80% opacity, 50% on hover
local function scrollbar(sf, vertical, host)
	local T, inset = px(10), px(2)
	local track = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(px(2), px(2)), Size = UDim2.new(1, -px(4), 1, -px(4)), ZIndex = 20 }, host)
	local thumb = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = SCROLL, BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Visible = false, ZIndex = 21,
	}, track)
	new("UICorner", { CornerRadius = UDim.new(0, math.floor(T / 2)) }, thumb)
	local dragging, hovering, startMouse, startPos = false, false, 0, 0

	local function dims()
		local c = vertical and sf.AbsoluteCanvasSize.Y or sf.AbsoluteCanvasSize.X
		local v = vertical and sf.AbsoluteWindowSize.Y or sf.AbsoluteWindowSize.X
		local p = vertical and sf.CanvasPosition.Y or sf.CanvasPosition.X
		return c, v, p
	end
	local function refresh()
		local c, v, p = dims()
		if v <= 0 or c <= v + 1 then thumb.Visible = false return end
		thumb.Visible = true
		local frac = math.max(v / c, 0.08)
		local t = math.clamp(p / (c - v), 0, 1) * (1 - frac)
		if vertical then
			thumb.Size = UDim2.new(0, T, frac, 0)
			thumb.Position = UDim2.new(1, -T, t, 0)
		else
			thumb.Size = UDim2.new(frac, 0, 0, T)
			thumb.Position = UDim2.new(t, 0, 1, -T)
		end
	end
	local function shade() tween(thumb, 0.12, { BackgroundTransparency = (hovering or dragging) and 0.5 or 0.2 }) end

	bind(sf:GetPropertyChangedSignal("CanvasPosition"), refresh)
	bind(sf:GetPropertyChangedSignal("AbsoluteCanvasSize"), refresh)
	bind(sf:GetPropertyChangedSignal("AbsoluteWindowSize"), refresh)
	bind(thumb.MouseEnter, function() hovering = true shade() end)
	bind(thumb.MouseLeave, function() hovering = false shade() end)
	bind(thumb.InputBegan, function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = true
			startMouse = vertical and i.Position.Y or i.Position.X
			local _, _, p = dims()
			startPos = p
			shade()
		end
	end)
	bind(UIS.InputChanged, function(i)
		if not dragging then return end
		local t = i.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end
		local c, v = dims()
		local frac = math.max(v / c, 0.08)
		local trackLen = vertical and track.AbsoluteSize.Y or track.AbsoluteSize.X
		local scrollable = trackLen * (1 - frac)
		if scrollable <= 0 then return end
		local d = (vertical and i.Position.Y or i.Position.X) - startMouse
		local np = math.clamp(startPos + d / scrollable * (c - v), 0, c - v)
		sf.CanvasPosition = vertical and V2(sf.CanvasPosition.X, np) or V2(np, sf.CanvasPosition.Y)
	end)
	bind(UIS.InputEnded, function(i)
		local t = i.UserInputType
		if dragging and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then
			dragging = false
			shade()
		end
	end)
	task.defer(refresh)
	return refresh
end
-- [/WIDGETS]

-- [HIGHLIGHT]
---------------------------------------------------------------- lua highlighter
local highlight
do -- the highlighter's tables stay out of the main chunk (Luau allows 200 locals per function)
local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end
local KW = set({ "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue" })
local BI = set({ "game", "workspace", "script", "self", "shared", "_G", "_VERSION", "task", "table", "string", "math", "os", "debug", "coroutine", "utf8", "bit32", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "TweenInfo", "Random", "Ray", "Region3", "BrickColor", "Rect", "NumberSequence", "ColorSequence" })
local H = { kw = "#5AA6E0", bi = "#4EC9B0", fn = "#DCDCAA", str = "#CE9178", num = "#B5CEA8", com = "#6A9955" }
local ESC = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&apos;" }

function highlight(src)
	local out, n, i = {}, #src, 1
	local function put(col, s)
		if s and s ~= "" then
			s = s:gsub("[&<>\"']", ESC)
			out[#out + 1] = col and ('<font color="' .. col .. '">' .. s .. "</font>") or s
		end
	end
	while i <= n do
		local c = src:sub(i, i)
		if c == "-" and src:sub(i + 1, i + 1) == "-" then
			local eq = src:match("^%-%-%[(=*)%[", i)
			local e
			if eq then
				local _, ce = src:find("]" .. eq .. "]", i, true)
				e = ce or n
			else
				e = (src:find("\n", i, true) or n + 1) - 1
			end
			put(H.com, src:sub(i, e)) i = e + 1
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n do
				local d = src:sub(j, j)
				if d == "\\" then j += 2
				elseif d == c then break
				elseif d == "\n" then j -= 1 break
				else j += 1 end
			end
			local e = math.min(j, n)
			put(H.str, src:sub(i, e)) i = e + 1
		elseif c == "[" and src:match("^%[=*%[", i) then
			local eq = src:match("^%[(=*)%[", i)
			local _, ce = src:find("]" .. eq .. "]", i, true)
			local e = ce or n
			put(H.str, src:sub(i, e)) i = e + 1
		elseif c:match("%d") then
			local w = src:match("^0[xX]%x+", i) or src:match("^%d[%d%.eE]*", i)
			put(H.num, w) i += #w
		elseif c:match("[%a_]") then
			local w = src:match("^[%a_][%w_]*", i)
			local col
			if KW[w] then col = H.kw
			elseif src:match("^%s*%(", i + #w) then col = H.fn
			elseif BI[w] then col = H.bi end
			put(col, w) i += #w
		else
			local w = src:match("^[^%w_\"'%-%[]+", i) or c
			put(nil, w) i += #w
		end
	end
	return table.concat(out)
end
end -- do
-- [/HIGHLIGHT]

-- [LOGSTATE]
---------------------------------------------------------------- logs state (ui built later)
local logsP, setP, ex -- panels
local logSF, logCount, logOrder = nil, 0, 0
local queue, pendingStick = {}, 0
local unreadE, unreadO = 0, 0
local dot
local t0 = os.clock()
local rcon = rconsoleprint

local function stamp()
	local s = math.floor(os.clock() - t0)
	return string.format("%02d:%02d:%02d", s // 3600, s // 60 % 60, s % 60)
end

local function updateDot()
	if not dot then return end
	dot.Visible = (unreadE + unreadO) > 0
	dot.BackgroundColor3 = unreadE > 0 and CYAN or GREEN
end

-- byExec = produced by the executor itself (cyan dot); otherwise game output (green dot)
local function emit(msg, color, byExec, silent)
	local line = stamp() .. " " .. tostring(msg)
	queue[#queue + 1] = { line, color or (byExec and CYAN or LOG_TXT) }
	if settings.sendLogs and rcon then pcall(rcon, line .. "\n") end
	if not silent and not (logsP and logsP.isOpen) then
		if byExec then unreadE += 1 else unreadO += 1 end
		updateDot()
	end
end
-- [/LOGSTATE]

-- [KEEP]
---------------------------------------------------------------- keep executor / rejoin
local STUB = [[
local ok, s = pcall(function()
	if isfile and isfile("kelsec_settings.json") then
		return game:GetService("HttpService"):JSONDecode(readfile("kelsec_settings.json"))
	end
end)
if ok and s and s.keep == false then return end
if isfile and isfile("kelsec.lua") then loadstring(readfile("kelsec.lua"))() end
]]
local queued = false
local function queueSelf(verbose)
	if queued then return end
	local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
	if not q then
		if verbose then emit("queue_on_teleport is unavailable here", LOG_WARN, true) end
		return
	end
	if not (isfile and isfile(SELF_FILE)) then
		if verbose then emit('save this script as "' .. SELF_FILE .. '" in your workspace folder to keep it between sessions', LOG_WARN, true) end
		return
	end
	queued = true
	pcall(q, STUB)
end

local function findServer()
	local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"):format(game.PlaceId)
	local req = request or http_request or (syn and syn.request) or (http and http.request)
	local ok, body = pcall(function()
		if req then return req({ Url = url, Method = "GET" }).Body end
		return game:HttpGet(url)
	end)
	if not ok or not body then return end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, body)
	if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then return end
	local pool = {}
	for _, s in ipairs(data.data) do
		if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then pool[#pool + 1] = s.id end
	end
	if #pool > 0 then return pool[math.random(#pool)] end
end

local reconnecting = false
bind(GuiService.ErrorMessageChanged, function()
	local msg = GuiService:GetErrorMessage()
	if msg == "" or reconnecting then return end
	emit("Disconnected: " .. msg, LOG_ERR, true)
	if not settings.autoRejoin then return end
	reconnecting = true
	task.delay(20, function() reconnecting = false end)
	save()
	task.spawn(function()
		task.wait(1)
		emit(settings.serverHop and "Server-hopping..." or "Re-joining...", nil, true)
		if settings.keep then queueSelf(false) end
		if settings.serverHop then
			local id = findServer()
			if id then pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, id, player) return end
			emit("No free server found, re-joining instead", LOG_WARN, true)
		end
		pcall(TeleportService.Teleport, TeleportService, game.PlaceId, player)
	end)
end)
-- [/KEEP]

-- [EXEC_PANEL]
---------------------------------------------------------------- EXECUTOR PANEL  (648 x 312)
-- grid: 12px outer margin, 40px header, 28px square window buttons, 36px square bottom buttons
ex = newPanel("Executor", 648, 312, 9)
ex.state, ex.busy = "open", false
ex.tl = V2(px(311), px(244))
applyPos(ex)
local EW, EH = ex.W, ex.H
local BW, BH = px(52), px(52) -- minimized bubble, same top-left corner as the panel
local content = ex.content

-- title ">kelsec" built from single chars so it can morph into ">kl"
local titleGroup = new("CanvasGroup", { Name = "TitleGroup", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 5 }, ex.root)
ex.groups[2] = titleGroup
local fsE = px(19) -- same size minimized and not
local function measure(t, size) return TextService:GetTextSize(t, size, F_CODE, V2(10000, 10000)) end
local mE = measure(">", fsE)
local cwE, lhE = math.ceil(mE.X), math.ceil(mE.Y)
local EXP_HOLDER = UDim2.fromOffset(px(14), px(20) - math.floor(lhE / 2))
local MIN_HOLDER = UDim2.fromOffset(math.floor((BW - 3 * cwE) / 2), math.floor((BH - lhE) / 2))
local holder = new("Frame", { Name = "Title", BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1), Position = EXP_HOLDER }, titleGroup)
local chars = {}
for i, ch in ipairs({ ">", "k", "e", "l", "s", "e", "c" }) do
	chars[i] = new("TextLabel", {
		Text = ch, Font = F_CODE, TextSize = fsE, TextColor3 = i == 1 and ACCENT or WHITE, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
		Size = UDim2.fromOffset(cwE, lhE), Position = UDim2.fromOffset((i - 1) * cwE, 0),
	}, holder)
end
-- minimize: ">" and "k" stay, "e" / "sec" fade out, "l" slides left next to the "k"
local function titleMorph(toMin)
	if toMin then
		tween(holder, 0.22, { Position = MIN_HOLDER })
		tween(chars[4], 0.22, { Position = UDim2.fromOffset(2 * cwE, 0) })
		for _, i in ipairs({ 3, 5, 6, 7 }) do tween(chars[i], 0.12, { TextTransparency = 1 }) end
	else
		tween(holder, 0.3, { Position = EXP_HOLDER })
		tween(chars[4], 0.3, { Position = UDim2.fromOffset(3 * cwE, 0) })
		for _, i in ipairs({ 3, 5, 6, 7 }) do tween(chars[i], 0.18, { TextTransparency = 0 }, nil, nil, 0.14) end
	end
end

label(content, "v1.0.0", 14 + 7 * cwE / S + 5, 17, 60, 15, F_CODE, 11, Color3.fromRGB(128, 128, 128))
local header = box2(content, 0, 0, 560, 40, { BackgroundTransparency = 1 })

-- window controls
local minBtn = minButton(content, 590, 20)
local closeBtn = xButton(content, 622, 20)
-- [/EXEC_PANEL]

-- [WINMODEL]
-- pure script model of the windowed editor (no Roblox objects, so test_winmodel.lua can run it on its own).
-- The whole script = head lines + the window (what the TextBox holds) + tail lines. Moving the window only moves the lines
-- it passes over, so scrolling through a huge script never re-copies the script.
local function lineStart(s, a) -- byte where line a starts; stops at the last line if the script has fewer
	local pos, ln = 1, 1
	while ln < a do
		local p = s:find("\n", pos, true)
		if not p then break end
		pos, ln = p + 1, ln + 1
	end
	return pos, ln
end

-- the n lines of s that start at line a: returns head, window, tail (head .. window .. tail == s) and the lines in head
local function cut(s, a, n)
	local from, la = lineStart(s, a)
	local stop, q = nil, from
	for _ = 1, math.max(n, 1) do
		stop = s:find("\n", q, true)
		if not stop then break end
		q = stop + 1
	end
	return s:sub(1, from - 1), s:sub(from, (stop or #s + 1) - 1), stop and s:sub(stop) or "", la - 1
end

local function split(s)
	local t, n = {}, 0
	for line in (s .. "\n"):gmatch("(.-)\n") do
		n = n + 1
		t[n] = line
	end
	return t
end

local Doc = {}
Doc.__index = Doc
-- H = head lines, T = tail lines in reverse (T[#T] is the first tail line), hLen / tLen = their bytes with one "\n" each
local function newDoc() return setmetatable({ H = {}, T = {}, hLen = 0, tLen = 0 }, Doc) end

-- moves the window to the n lines that start at line a (clamped) and returns the new window text. win = the current window text
function Doc:reframe(win, a, n)
	local H, T, W = self.H, self.T, split(win)
	local hN, wN, tN = #H, #W, #T
	local total = hN + wN + tN
	a = math.max(1, math.min(a, total))
	local b = math.min(a + math.max(n, 1) - 1, total)
	local function line(i) -- line i of the script as it is now
		if i <= hN then return H[i] end
		if i <= hN + wN then return W[i - hN] end
		return T[tN - (i - hN - wN) + 1]
	end
	local nw, grow, push = {}, {}, {}
	for i = a, b do nw[#nw + 1] = line(i) end
	for i = hN + 1, a - 1 do grow[#grow + 1] = line(i) end -- head grows: window lines (or tail lines) it passed over
	for i = hN + wN, b + 1, -1 do push[#push + 1] = line(i) end -- tail grows: lines the window left behind
	for i = hN, a, -1 do
		self.hLen = self.hLen - #H[i] - 1
		H[i] = nil
	end
	for _, l in ipairs(grow) do
		H[#H + 1] = l
		self.hLen = self.hLen + #l + 1
	end
	for _ = 1, b - hN - wN do -- tail shrinks: the window moved down over its first lines
		local l = T[#T]
		T[#T] = nil
		self.tLen = self.tLen - #l - 1
	end
	for _, l in ipairs(push) do
		T[#T + 1] = l
		self.tLen = self.tLen + #l + 1
	end
	return table.concat(nw, "\n")
end

-- whole script as a string
function Doc:full(win)
	local parts = {}
	if #self.H > 0 then parts[1] = table.concat(self.H, "\n") .. "\n" end
	parts[#parts + 1] = win
	for i = #self.T, 1, -1 do parts[#parts + 1] = "\n" .. self.T[i] end
	return table.concat(parts)
end

-- replaces the script by text and returns the window of n lines from line a
function Doc:load(text, a, n)
	self.H, self.T, self.hLen, self.tLen = {}, {}, 0, 0
	return self:reframe(text, a, n)
end

-- line number that holds byte position abs of the whole script (#script + 1 = the end of the last line)
function Doc:lineAt(win, abs)
	if abs <= self.hLen then
		local p = 0
		for i = 1, #self.H do
			p = p + #self.H[i] + 1
			if abs <= p then return i end
		end
	end
	local rel = abs - self.hLen
	local wl = select(2, win:gsub("\n", "")) + 1
	if rel <= #win + 1 then return #self.H + select(2, win:sub(1, rel - 1):gsub("\n", "")) + 1 end
	local p, line = self.hLen + #win, #self.H + wl
	for i = #self.T, 1, -1 do
		p, line = p + #self.T[i] + 1, line + 1
		if abs <= p + 1 then return line end
	end
	return line
end
-- [/WINMODEL]

-- [EDITOR]
do local function buildEditor() -- its own function = its own 200-local budget, so the editor's ~70 locals don't count against the main chunk
local ebox = inner(content, 12, 40, 624, 228)
local GUT = px(31)
local VW, VH = px(624) - GUT - 1, px(228) -- visible text area
local gclip = new("Frame", { Size = UDim2.new(0, GUT, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true }, ebox)
local fsC = px(13)
local TX, TY = px(10), px(6) -- text origin inside the window frame
local gutter = new("TextLabel", {
	Position = UDim2.fromOffset(0, TY), Size = UDim2.new(0, px(25), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Font = F_MONO, TextSize = fsC, TextColor3 = Color3.fromRGB(0x78, 0x78, 0x80),
	TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top, Text = "1",
}, gclip)
new("Frame", { Position = UDim2.fromOffset(GUT, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, ebox)

-- HOW IT WORKS. The script lives in `doc` (head lines + window + tail lines). The TextBox only holds the window (~180 lines), so
-- a huge script never becomes one giant text object. The ScrollingFrame is as tall as the whole script, `win` sits at the window's
-- line, and only the lines in view are coloured / numbered / selected (culling). The selection and caret are kept as byte
-- positions in the WHOLE script (aA / cA), so a selection can span any number of windows; the TextBox's own selection only mirrors
-- the part inside the window. Edits that reach outside the window rebuild the script from those positions.
local sf = new("ScrollingFrame", {
	Position = UDim2.fromOffset(GUT + 1, 0), Size = UDim2.new(1, -(GUT + 1), 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.XY, ElasticBehavior = Enum.ElasticBehavior.Never,
}, ebox)
local win = new("Frame", { Name = "Window", Size = UDim2.new(), BackgroundTransparency = 1 }, sf)

-- exact font metrics (measured over long strings so rounding can't drift on long lines / many lines)
local ADV = TextService:GetTextSize(("A"):rep(200), fsC, F_MONO, V2(100000, 100000)).X / 200
local PITCH = TextService:GetTextSize(("A\n"):rep(100) .. "A", fsC, F_MONO, V2(100000, 100000)).Y / 101
local lineH = math.floor(PITCH + 0.5)
local function textW(s) return (utf8.len(s) or #s) * ADV end
local function rnd(n) return math.floor(n + 0.5) end
local function count(s) return select(2, s:gsub("\n", "")) end

-- lines kept above / below the view, window size that forces a re-cut (a paste), margin before the view reaches the window edge,
-- lines drawn around the view
local WIN_BUF, WIN_MAX, WIN_MARGIN, SLICE_BUF = 80, 400, 30, 8
local ROWS = math.ceil(VH / PITCH) + 1 -- lines in view
-- the saved script may hold tabs / CRLF from an older version or a paste: normalise it like typing does
local startText = (type(settings.code) == "string" and settings.code or SAMPLE):gsub("\r\n?", "\n"):gsub("\t", "    ")
doc = newDoc()
local win0 = doc:load(startText, 1, ROWS + 2 * WIN_BUF)
local hN, tN, wN, winY = #doc.H, #doc.T, count(win0) + 1, 0 -- lines above / below / inside the window, window top in the canvas
-- shortcut: the canvas width only ever grows (longest line seen so far), when to upgrade: keep a per-line length index
local maxCols = 0
for line in (startText .. "\n"):gmatch("(.-)\n") do
	if #line > maxCols then maxCols = #line end
end

box = new("TextBox", {
	Position = UDim2.fromOffset(TX, TY), Size = UDim2.fromOffset(VW - TX, VH - TY), AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1, ClearTextOnFocus = false, MultiLine = true, TextWrapped = false, Font = F_MONO, TextSize = fsC,
	TextColor3 = WHITE, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Text = win0,
}, win)
fullText = function() return doc:full(box.Text) end
local hl = new("TextLabel", {
	Position = box.Position, Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, RichText = true,
	Font = F_MONO, TextSize = fsC, TextColor3 = Color3.fromRGB(0xD4, 0xD4, 0xD4), TextWrapped = false,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3,
}, win)
local caret = new("Frame", { Name = "Caret", Size = UDim2.fromOffset(2, lineH), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 4 }, win)

local barHost = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, ebox)
scrollbar(sf, true, barHost)
scrollbar(sf, false, barHost)

---------------- state
local aA, cA = 1, 1 -- selection anchor / caret: byte positions in the whole script
local mirC, mirS = -1, -1 -- TextBox cursor / selection as we last wrote or read them (tells us when the user changed them)
local lastText = win0 -- window text we last saw
local internal, hlPending = false, false -- internal: we are assigning box.Text ourselves
local pressed, dragging, pressAt, dragT = false, false, V2(0, 0), 0
local hold, dirty, follow = 0, false, false -- hold: frames we keep re-writing the selection after a command; dirty: redraw; follow: scroll to caret
local undoSnap, redoSnap -- { whole script, anchor, caret } from before the last edit that reached outside the window
-- shortcut: undo of such an edit works until you type again (the TextBox undo can't see text outside its window), when to upgrade: own undo stack
local c0, c1 = 0, -1 -- window lines currently drawn
local lastMove, caretOn = os.clock(), false
local setWindow, updateCaret, onEdited, syncNative

local function toWin(a) return math.clamp(a - doc.hLen, 1, #box.Text + 1) end
-- writes the whole-script selection into the TextBox (the part that falls inside the window)
local function mirror()
	local lc, ls = toWin(cA), toWin(aA)
	if aA == cA or lc == ls then ls = -1 end
	box.CursorPosition = lc
	box.SelectionStart = ls
	mirC, mirS = box.CursorPosition, box.SelectionStart
end

---------------- drawing (culled: only the lines in view)
local function visRange() -- first / last window line in view
	local top = math.floor((sf.CanvasPosition.Y - winY - TY) / PITCH) + 1
	return math.max(top, 1), math.min(top + ROWS, wN)
end

local function placeGutter()
	gutter.Position = UDim2.fromOffset(0, winY + TY + rnd((c0 - 1) * PITCH) - sf.CanvasPosition.Y)
end

local function renderSlice(force)
	local vt, vb = visRange()
	if not force and vt >= c0 and vb <= c1 and (c0 == 1 or vt - c0 >= 3) and (c1 == wN or c1 - vb >= 3) then return end
	local txt = box.Text
	c0, c1 = math.max(vt - SLICE_BUF, 1), math.min(vb + SLICE_BUF, wN)
	c0 = math.min(c0, c1)
	-- shortcut: a long [[ ]] string / comment is only coloured right when it starts inside the window, when to upgrade: carry the lexer state into the window
	if txt:find("[[", 1, true) or txt:find("[=", 1, true) then c0, c1 = 1, wN end
	local _, part = cut(txt, c0, c1 - c0 + 1)
	hl.Text = highlight(part)
	hl.Position = UDim2.fromOffset(TX, TY + rnd((c0 - 1) * PITCH))
	local t = table.create(c1 - c0 + 1)
	for k = c0, c1 do t[k - c0 + 1] = hN + k end
	gutter.Text = table.concat(t, "\n")
	placeGutter()
end

-- window frame, canvas size (whole script tall, longest line wide)
-- shortcut: the canvas can't be taller than about 1M lines (engine float limit), when to upgrade: scale scrolling for bigger scripts
local function layout()
	winY = rnd(hN * PITCH)
	win.Position = UDim2.fromOffset(0, winY)
	for line in (box.Text .. "\n"):gmatch("(.-)\n") do
		if #line > maxCols then maxCols = #line end
	end
	sf.CanvasSize = UDim2.fromOffset(math.max(VW, TX + rnd(maxCols * ADV) + px(24)), 2 * TY + rnd((hN + wN + tN) * PITCH))
	placeGutter()
end

local function rehighlight()
	hlPending = false
	if not alive then return end
	onEdited()
	syncNative()
	local txt = box.Text
	wN = count(txt) + 1
	if wN > WIN_MAX then -- a paste made the window huge: cut it again around the caret
		return setWindow(doc:lineAt(txt, cA) - WIN_BUF, 2 * WIN_BUF + 1)
	end
	layout()
	renderSlice(true)
end

-- re-cuts the window to n lines from line a. The selection stays on the same text (it is kept in whole-script positions); the
-- TextBox only loses focus when neither the caret nor the selection touches the new window.
setWindow = function(a, n)
	onEdited()
	syncNative()
	local text = doc:reframe(box.Text, a, n)
	lastText, internal = text, true
	box.Text = text
	internal = false
	hN, tN = #doc.H, #doc.T
	mirror()
	if box:IsFocused() and not dragging then
		local wS, wE = doc.hLen + 1, doc.hLen + #text + 1
		local lo, hi = math.min(aA, cA), math.max(aA, cA)
		if (cA < wS or cA > wE) and not (lo < hi and lo <= wE and hi > wS) then box:ReleaseFocus() end
	end
	rehighlight()
end

-- scrolling: keep the view well inside the window, otherwise re-cut it around the view
local function onScroll()
	local top = math.floor((sf.CanvasPosition.Y - TY) / PITCH) + 1
	if (hN > 0 and top - WIN_MARGIN < hN + 1) or (tN > 0 and top + ROWS + WIN_MARGIN > hN + wN) then
		setWindow(top - WIN_BUF, ROWS + 2 * WIN_BUF)
	else
		renderSlice(false)
		placeGutter()
	end
end
bind(sf:GetPropertyChangedSignal("CanvasPosition"), onScroll)

-- selection highlight (drawn by us, behind the text), only for the lines in view
local selPool = {}
local function updateSelection()
	local used = 0
	local lo, hi = math.min(aA, cA), math.max(aA, cA)
	if (box:IsFocused() or dragging) and lo < hi then
		local txt = box.Text
		local s, e = lo - doc.hLen, hi - doc.hLen -- positions in the window (may lie outside it)
		local top, bot = visRange()
		local idx, lineNo = lineStart(txt, top)
		for line in (txt:sub(idx) .. "\n"):gmatch("(.-)\n") do
			if lineNo > bot then break end
			local le = idx + #line -- position of this line's newline
			if e > idx and s <= le then
				local x1 = textW(line:sub(1, math.max(s, idx) - idx))
				local x2 = textW(line:sub(1, math.min(e, le) - idx))
				if e > le then x2 += px(6) end -- newline is selected too
				if x2 > x1 then
					used += 1
					local f = selPool[used]
					if not f then
						f = new("Frame", { BackgroundColor3 = SEL, BorderSizePixel = 0, ZIndex = 1 }, win)
						selPool[used] = f
					end
					f.Position = UDim2.fromOffset(TX + rnd(x1), TY + rnd((lineNo - 1) * PITCH))
					f.Size = UDim2.fromOffset(rnd(x2) - rnd(x1), lineH)
					f.Visible = true
				end
			end
			idx = le + 1
			lineNo += 1
		end
	end
	for k = used + 1, #selPool do selPool[k].Visible = false end
end

-- caret: drawn by us (the real one is hidden with the text); scroll = also move the view to it
updateCaret = function(scroll)
	updateSelection()
	local cp = cA - doc.hLen
	if not box:IsFocused() or cp < 1 or cp > #box.Text + 1 then caretOn = false return end
	caretOn = true
	local before = box.Text:sub(1, cp - 1)
	local colText = before:sub(before:match(".*\n()") or 1)
	local cx, cy = TX + rnd(textW(colText)), TY + rnd(count(before) * PITCH)
	caret.Position = UDim2.fromOffset(cx, cy)
	lastMove = os.clock()
	if not scroll then return end
	local gy, pos = winY + cy, sf.CanvasPosition -- gy = caret line in the canvas
	if gy < pos.Y then pos = V2(pos.X, gy)
	elseif gy + lineH > pos.Y + VH then pos = V2(pos.X, gy + lineH - VH) end
	if cx < pos.X then pos = V2(math.max(0, cx - px(20)), pos.Y)
	elseif cx + px(20) > pos.X + VW then pos = V2(cx + px(20) - VW, pos.Y) end
	if pos ~= sf.CanvasPosition then sf.CanvasPosition = pos end
end

---------------- reading the TextBox (typing, clicking, arrow keys) into the whole-script selection
syncNative = function()
	if dragging or hold > 0 or not box:IsFocused() then return false end
	local cp, ss = box.CursorPosition, box.SelectionStart
	if cp < 1 or (cp == mirC and ss == mirS) then return false end
	cA = doc.hLen + cp
	if ss == -1 then aA = cA elseif ss ~= mirS then aA = doc.hLen + ss end -- an untouched anchor stays where it was (it may be outside the window)
	mirC, mirS = cp, ss
	dirty, follow = true, true
	return true
end

-- replaces the script by text (window cut around caret) and puts the caret there
local function reload(text, caret)
	local line = count(text:sub(1, caret - 1)) + 1
	local text0 = doc:load(text, line - WIN_BUF, ROWS + 2 * WIN_BUF)
	lastText, internal = text0, true
	box.Text = text0
	internal = false
	hN, tN = #doc.H, #doc.T
	aA, cA, hold = caret, caret, 2
	mirror()
	rehighlight()
	updateCaret(true)
end

-- the user changed the window text (typed, pasted, cut, deleted)
onEdited = function()
	local t = box.Text
	if t == lastText then return end
	local old = lastText
	if t:find("\t", 1, true) then -- tabs -> 4 spaces so the monospace caret math stays exact
		local cp = box.CursorPosition
		local tabs = cp > 1 and select(2, t:sub(1, cp - 1):gsub("\t", "")) or 0
		t = t:gsub("\t", "    ")
		internal = true
		box.Text = t
		internal = false
		if cp > 0 then box.CursorPosition = cp + tabs * 3 end
	end
	lastText = t
	local lo, hi = math.min(aA, cA), math.max(aA, cA)
	local wS = doc.hLen + 1
	if lo < hi and (lo < wS or hi > wS + #old) then
		-- the selection reached outside the window (Ctrl+A, long drag...): the TextBox replaced only the part inside it,
		-- so rebuild the whole script: everything before the selection + what was typed + everything after it
		local full0 = doc:full(old)
		local os_ = math.max(lo - wS + 1, 1) -- selected part of the old window
		local oe = math.min(hi - wS + 1, #old + 1)
		local typed = t:sub(os_, #t - (#old - oe + 1))
		undoSnap, redoSnap = { full0, aA, cA }, nil
		return reload(full0:sub(1, lo - 1) .. typed .. full0:sub(hi), lo + #typed)
	end
	undoSnap, redoSnap = nil, nil
	dirty = true
end

bind(box:GetPropertyChangedSignal("Text"), function()
	if not internal and not hlPending then hlPending = true task.defer(rehighlight) end
end)
bind(box.FocusLost, function()
	caretOn, caret.Visible, pressed, dragging = false, false, false, false
	updateSelection()
	save()
end)

---------------- mouse: drag-select with edge scrolling, shift + click
local function mouseAbs(m) -- byte position in the whole script under the mouse (the view is always inside the window)
	local ap, as, pos = sf.AbsolutePosition, sf.AbsoluteSize, sf.CanvasPosition
	local y = math.clamp(m.Y - ap.Y, 0, as.Y - 1) + pos.Y - winY - TY
	local x = math.clamp(m.X - ap.X, 0, as.X - 1) + pos.X - TX
	local txt = box.Text
	local ls = lineStart(txt, math.clamp(math.floor(y / PITCH), 0, wN - 1) + 1)
	local line = txt:sub(ls, (txt:find("\n", ls, true) or #txt + 1) - 1)
	return doc.hLen + ls + (utf8.offset(line, math.max(math.floor(x / ADV + 0.5), 0) + 1) or #line + 1) - 1
end

local function dragStep(dt)
	local m, ap, as = UIS:GetMouseLocation(), sf.AbsolutePosition, sf.AbsoluteSize
	local ox = m.X < ap.X and m.X - ap.X or (m.X > ap.X + as.X and m.X - ap.X - as.X or 0)
	local oy = m.Y < ap.Y and m.Y - ap.Y or (m.Y > ap.Y + as.Y and m.Y - ap.Y - as.Y or 0)
	if ox ~= 0 or oy ~= 0 then -- mouse outside the editor: scroll, faster the farther out and the longer it stays
		dragT += dt
		local k = (1 + math.min(dragT * 3, 30)) * dt
		local mx, pos = sf.AbsoluteCanvasSize - sf.AbsoluteWindowSize, sf.CanvasPosition
		sf.CanvasPosition = V2(
			math.clamp(pos.X + math.clamp(ox * 8, -1500, 1500) * k, 0, math.max(mx.X, 0)),
			math.clamp(pos.Y + math.clamp(oy * 12, -2400, 2400) * k, 0, math.max(mx.Y, 0)))
		onScroll()
	else
		dragT = 0
	end
	cA = mouseAbs(m)
	dirty = true
	mirror()
end

bind(UIS.InputBegan, function(i)
	local t = i.UserInputType
	if t == Enum.UserInputType.MouseButton1 then
		if overFrame(sf) then
			local m, ap, as = UIS:GetMouseLocation(), sf.AbsolutePosition, sf.AbsoluteSize
			if m.X < ap.X + as.X - px(14) and m.Y < ap.Y + as.Y - px(14) then -- not on a scrollbar
				pressed, pressAt = true, m
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
	syncNative()
	dragging, dragT = true, 0 -- shift + click: extend the selection from its anchor, however far away (even if scrolling released the focus)
	if not box:IsFocused() then box:CaptureFocus() end
end
			end
		end
	elseif t == Enum.UserInputType.Keyboard and box:IsFocused() then
		local K = Enum.KeyCode
		local ctrl = UIS:IsKeyDown(K.LeftControl) or UIS:IsKeyDown(K.RightControl) or UIS:IsKeyDown(K.LeftMeta) or UIS:IsKeyDown(K.RightMeta)
		if not ctrl then return end
		local shift = UIS:IsKeyDown(K.LeftShift) or UIS:IsKeyDown(K.RightShift)
		local k = i.KeyCode
		syncNative()
		if k == K.A then -- the whole script, not just the window
			aA, cA, hold, dirty = 1, doc.hLen + #box.Text + doc.tLen + 1, 3, true
			mirror()
		elseif k == K.C or k == K.X then -- copy / cut what is selected, also the part outside the window
			local lo, hi, wS = math.min(aA, cA), math.max(aA, cA), doc.hLen + 1
			if lo < hi and (lo < wS or hi > wS + #box.Text) then
				local s = doc:full(box.Text):sub(lo, hi - 1)
				local clip = setclipboard or toclipboard
				if clip then
					task.delay(0.05, function() pcall(clip, s) end) -- after the TextBox put its own (window only) copy there
				else
					emit("setclipboard is unavailable: copy only gets the part inside the window", LOG_WARN, true, true)
				end
			end
		elseif (k == K.Z and not shift and undoSnap) or ((k == K.Y or (k == K.Z and shift)) and redoSnap) then
			local undo = k == K.Z and not shift
			local s, cur = undo and undoSnap or redoSnap, { doc:full(box.Text), aA, cA }
			task.delay(0.05, function() -- after the TextBox's own undo, which can't see outside the window
				if not alive then return end
				reload(s[1], s[3])
				aA = s[2]
				mirror()
				if undo then redoSnap = cur else undoSnap = cur end
				dirty = true
			end)
		elseif k == K.Home or k == K.End then -- start / end of the whole script
			local total = doc.hLen + #box.Text + doc.tLen + 1
			cA = k == K.Home and 1 or total
			if not shift then aA = cA end
			setWindow(doc:lineAt(box.Text, cA) - WIN_BUF, ROWS + 2 * WIN_BUF)
			hold = 2
			mirror()
			updateCaret(true)
		end
	end
end)
bind(UIS.InputEnded, function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		pressed = false
		if dragging then
			dragging, hold, dirty = false, 2, true
			mirror()
		end
	end
end)

-- every frame: pick up what the TextBox did, run a drag, redraw caret + selection when they moved, blink the caret
bind(RunService.Heartbeat, function(dt)
	if ex.state ~= "open" then caretOn, caret.Visible = false, false return end
	onEdited()
	if pressed and not dragging and box:IsFocused() and (UIS:GetMouseLocation() - pressAt).Magnitude > 4 then
		syncNative() -- the click has put the anchor where it was pressed
		dragging, dragT = true, 0
	end
	if dragging then
		dragStep(dt)
	elseif hold > 0 then
		hold -= 1
		mirror()
		dirty = true
	else
		syncNative()
	end
	if dirty then
		dirty = false
		updateCaret(follow)
		follow = false
	end
	caret.Visible = caretOn and (os.clock() - lastMove) % 1.06 < 0.53
end)

-- shift + wheel scrolls sideways
bind(UIS.InputChanged, function(i)
	if i.UserInputType == Enum.UserInputType.MouseWheel and UIS:IsKeyDown(Enum.KeyCode.LeftShift) and overFrame(sf) then
		sf.CanvasPosition = V2(math.max(0, sf.CanvasPosition.X - i.Position.Z * 60), sf.CanvasPosition.Y)
	end
end)

rehighlight()
end
buildEditor()
end -- do
-- [/EDITOR]

-- [EXEC_BTNS]
-- bottom row (y 268..312): settings, logs, run
local gearBtn = btn(content, "Settings", 12, 278, 72, 26)
local logsBtn = btn(content, "Logs", 90, 278, 56, 26)
dot = new("Frame", { Position = UDim2.fromOffset(px(49), px(-3)), Size = UDim2.fromOffset(px(10), px(10)), BackgroundColor3 = GREEN, BorderSizePixel = 0, Visible = false, ZIndex = 12 }, logsBtn)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
local runBtn = btn(content, "Run", 564, 278, 72, 26, CTRL_ON, BTN_ON)
-- [/EXEC_BTNS]

-- [LOGS]
---------------------------------------------------------------- LOGS PANEL  (471 x 557)
logsP = newPanel("Logs", 471, 557, 9)
do
	local c = logsP.content
	local lh = box2(c, 0, 0, 365, 40, { BackgroundTransparency = 1 })
	label(c, "logs", 14, 11, 100, 18, F_CODE, 16)
	local clear = btn(c, "clear", 371, 9, 52, 22)
	local lclose = xButton(c, 445, 20)

	local area = inner(c, 12, 40, 447, 505)
	logSF = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	}, area)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, logSF)
	new("UIPadding", { PaddingLeft = UDim.new(0, px(10)), PaddingRight = UDim.new(0, px(18)), PaddingTop = UDim.new(0, px(6)), PaddingBottom = UDim.new(0, px(6)) }, logSF)
	scrollbar(logSF, true, new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, area))

	local function wipe()
		for _, ch in ipairs(logSF:GetChildren()) do if ch:IsA("TextLabel") then ch:Destroy() end end
		logCount = 0
	end
	bind(clear.MouseButton1Click, wipe)
	bind(lclose.MouseButton1Click, function() fadeClose(logsP) end)
	makeDrag(lh, function() return logsP.tl end, function(v) setTL(logsP, v) end)
end

local function pushLine(line, color)
	logOrder += 1
	new("TextLabel", {
		LayoutOrder = logOrder, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Font = F_MONO, TextSize = px(11), TextColor3 = color, Text = line,
	}, logSF)
	logCount += 1
	if logCount > 400 then
		for _, ch in ipairs(logSF:GetChildren()) do
			if ch:IsA("TextLabel") then ch:Destroy() logCount -= 1 break end
		end
	end
end

bind(RunService.Heartbeat, function()
	-- log queue
	if #queue > 0 then
		if #queue > 300 then queue = table.move(queue, #queue - 299, #queue, 1, {}) end
		local atBottom = logSF.CanvasPosition.Y >= logSF.AbsoluteCanvasSize.Y - logSF.AbsoluteWindowSize.Y - 6
		for _ = 1, math.min(30, #queue) do
			local e = table.remove(queue, 1)
			pushLine(e[1], e[2])
		end
		if atBottom then pendingStick = 2 end
	end
	if pendingStick > 0 then
		pendingStick -= 1
		logSF.CanvasPosition = V2(0, 1e7)
	end
	
end)

local MSG_COLOR = {
	[Enum.MessageType.MessageOutput] = LOG_TXT,
	[Enum.MessageType.MessageInfo] = Color3.fromRGB(0x7F, 0xC8, 0xFF),
	[Enum.MessageType.MessageWarning] = LOG_WARN,
	[Enum.MessageType.MessageError] = LOG_ERR,
}
bind(LogService.MessageOut, function(msg, kind)
	emit(msg, MSG_COLOR[kind] or LOG_TXT, false)
end)

emit("Welcome, " .. player.Name .. ". Logs will be displayed here.", LOG_TXT, true, true)
-- [/LOGS]

-- [SETTINGS_UI]
---------------------------------------------------------------- SETTINGS PANEL  (297 x 188)
setP = newPanel("Settings", 353, 188, 9)
do
	local c = setP.content
	local sh = box2(c, 0, 0, 311, 40, { BackgroundTransparency = 1 })
	label(c, "settings", 14, 11, 160, 18, F_CODE, 16)
	local sclose = xButton(c, 327, 20)
	local panelInner = inner(c, 12, 40, 329, 136)

	local rows = {
		{ "keep", "Keep executor between sessions" },
		{ "sendLogs", "Send logs to executor" },
		{ "autoRejoin", "Auto re-join after disconnect" },
		{ "serverHop", "Server-hop instead of re-join" },
	}
	for idx, rw in ipairs(rows) do
		local key, y = rw[1], 6 + (idx - 1) * 32
		label(panelInner, rw[2], 14, y, 215, 28, F_UI, fs(12))
		local onB, offB = btn(panelInner, "On", 229, y + 3, 40, 22), btn(panelInner, "Off", 275, y + 3, 40, 22)
		local function show()
			fill(onB, settings[key])
			fill(offB, not settings[key])
		end
		local function choose(v)
			settings[key] = v
			show()
			if key == "keep" and v then queueSelf(true) end
			if key == "sendLogs" and v and not rcon then
				emit("rconsoleprint is unavailable: logs can't be sent to the executor console", LOG_WARN, true)
			end
			save()
		end
		show()
		bind(onB.MouseButton1Click, function() choose(true) end)
		bind(offB.MouseButton1Click, function() choose(false) end)
	end
	bind(sclose.MouseButton1Click, function() fadeClose(setP) end)
	makeDrag(sh, function() return setP.tl end, function(v) setTL(setP, v) end)
end
-- [/SETTINGS_UI]

-- [PLACE]
---------------------------------------------------------------- opening / placing panels
local function place(p, dx, dy)
	if p.placed then return end
	p.placed = true
	setTL(p, ex.tl + V2(px(dx), px(dy)))
end

local function toggleLogs()
	if logsP.isOpen then fadeClose(logsP) return end
	place(logsP, 759, 11)
	unreadE, unreadO = 0, 0
	updateDot()
	popOpen(logsP)
end

local function toggleSettings()
	if setP.isOpen then fadeClose(setP) return end
	place(setP, 148, 392)
	popOpen(setP)
end

bind(gearBtn.MouseButton1Click, toggleSettings)
bind(logsBtn.MouseButton1Click, toggleLogs)
-- [/PLACE]

-- [RUN]
---------------------------------------------------------------- run
local function run()
	save()
	if not loadstring then emit("loadstring is unavailable in this environment", LOG_ERR, true) return end
	local fn, err = loadstring(fullText(), "=kelsec")
	if not fn then emit("Syntax error: " .. tostring(err), LOG_ERR, true) return end
	local start = os.clock()
	task.spawn(function()
		local ok, e = xpcall(fn, function(m) return debug.traceback(tostring(m), 2) end)
		if ok then
			emit(("Executed (%.1f ms)"):format((os.clock() - start) * 1000), nil, true)
		else
			emit(e, LOG_ERR, true)
		end
	end)
end
bind(runBtn.MouseButton1Click, run)
-- [/RUN]

-- [WINDOW]
---------------------------------------------------------------- minimize / restore / close
-- the panel shrinks into / grows out of its own top-left corner, so that corner never moves
local function minimize()
	if ex.busy or ex.state ~= "open" then return end
	ex.busy, ex.state = true, "min"
	for _, p in ipairs({ logsP, setP }) do
		p.reopen = p.isOpen
		if p.isOpen then fadeClose(p) end
	end
	titleMorph(true)
	tween(content, 0.14, { GroupTransparency = 1 })
	tween(ex.root, 0.34, { Size = UDim2.fromOffset(BW, BH) }, nil, nil, 0.05)
	task.delay(0.42, function()
		if not alive then return end
		content.Visible = false
		ex.busy = false
	end)
end

local function restore()
	if ex.busy or ex.state ~= "min" then return end
	ex.busy, ex.state = true, "open"
	front(ex)
	content.Visible = true
	titleMorph(false)
	tween(content, 0.2, { GroupTransparency = 0 }, nil, nil, 0.16)
	tween(ex.root, 0.38, { Size = UDim2.fromOffset(EW, EH) })
	task.delay(0.4, function()
		if not alive then return end
		ex.busy = false
		for _, p in ipairs({ logsP, setP }) do
			if p.reopen then p.reopen = false popOpen(p) end
		end
	end)
end

local api = {}
local function destroy()
	if not alive then return end
	save()
	alive = false
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	table.clear(queue)
	gui:Destroy()
	if genv.__kelsec == api then genv.__kelsec = nil end
end

local function closeExecutor()
	if ex.busy then return end
	ex.busy = true
	for _, p in ipairs({ logsP, setP }) do if p.isOpen then fadeClose(p) end end
	local t = setShown(ex, false, 0.2)
	t.Completed:Connect(destroy)
	task.delay(1, destroy) -- safety net
end

api.close = function(instant)
	if instant then destroy() else closeExecutor() end
end
genv.__kelsec = api

bind(minBtn.MouseButton1Click, minimize)
bind(closeBtn.MouseButton1Click, closeExecutor)

-- one shared top-left (ex.tl): drag the header while open, drag/click the bubble while minimized
makeDrag(header, function() return ex.tl end, function(v) if not ex.busy then setTL(ex, v) end end)
makeDrag(ex.root, function() return ex.tl end, function(v) if not ex.busy then setTL(ex, v) end end, restore,
	function() return ex.state == "min" and not ex.busy end)
-- [/WINDOW]

-- [ENTRY]
---------------------------------------------------------------- start
if settings.keep then queueSelf(false) end
popOpen(ex)
-- [/ENTRY]
