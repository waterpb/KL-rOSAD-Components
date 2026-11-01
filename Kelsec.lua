--// >kelsec v1.0.0 : LocalScript executor
--// All sizes are the deck's 1080p pixels (1 slide inch = 144 px).
--// Save this file as "kelsec.lua" in your executor's workspace folder if you want
--// "Keep executor between sessions" to work (it re-loads that file after a teleport).

local S = 1 -- UI scale. 1 = exact deck size on a 1080p screen

-- optional: your own uploaded images ("rbxassetid://123"). empty = use the deck's icons
local ICON_GEAR, ICON_LOGS = "", ""

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

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local ACCENT = Color3.fromRGB(0x5B, 0x9B, 0xD5)
local CYAN = Color3.fromRGB(0x4F, 0xE3, 0xF0)
local GREEN = Color3.fromRGB(0x15, 0xD9, 0x7C)
local SCROLL = Color3.fromRGB(0x73, 0x73, 0x73)
local LOG_TXT = Color3.fromRGB(0xD6, 0xD6, 0xDB)
local LOG_WARN = Color3.fromRGB(0xFF, 0xC9, 0x6B)
local LOG_ERR = Color3.fromRGB(0xFF, 0x6B, 0x6B)

local F_CODE, F_MONO, F_UI = Enum.Font.Code, Enum.Font.RobotoMono, Enum.Font.SourceSans
local F_GLYPH = Enum.Font.GothamMedium

-- flat dark-grey theme (about 10% lightness)
local PANEL, PANEL_T = Color3.fromRGB(26, 26, 26), 0.12
local INNER, INNER_T = Color3.fromRGB(14, 14, 14), 0.2
local SEL = Color3.fromRGB(0x26, 0x4F, 0x78)
local OUTLINE = Color3.fromRGB(58, 58, 58)    -- <<< window outline colour (panels + minimized bubble)
local INNER_EDGE = Color3.fromRGB(42, 42, 42) -- outline of the recessed editor / log / settings areas
local CTRL_EDGE = Color3.fromRGB(88, 88, 88)  -- outline of the checkboxes and the clear button

---------------------------------------------------------------- icon assets (from the deck)
local GEAR_B64 = "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"
local LOGS_B64 = "iVBORw0KGgoAAAANSUhEUgAAADgAAAAqCAYAAADmmJiOAAAAwklEQVR42u3aQQrCQAyF4T9jreBG8Fae2HN4EfeljHEhrcFu3fh82RSy+0iaDNNGZiavWJ4qEQDDZ0ItKvAMTCKuA3AHiNKiu4h4KOgyswEdoJX8XqgzV0tDPOSBdciM79fx52NcV8MyZCJCak0srqEkbkLLPjYV9JARGDIXYBbag9e/GzJHsbPopkV7RHSR6nUf1Qw00EADDTTQQAMNNNBAAw000EADDTTwG8BZyLVa6r3oKTPlLn7lvy7VCkr+CPQE2f5DKwfEIDwAAAAASUVORK5CYII="
local X_B64 = "iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAYAAAByDd+UAAABgklEQVR42q2WzUoDMRRG70wrVl0UQdoKghsR9KX0Ldz4SoIvIIoLUemydSMUV9WFgrioxYLHhTc1ExonPw2Um9LMPc1M5vCJWAMotRaSOUwPby8LVqk5MLf3ItgR0Ae6+r2RADO91oFr4LTyJ4BSP8fAF79jAPRioQ7skr9xAqwApQG2gKH+ONE6jIF6YJ9a34AtoLAXbuvO7IVBUA9sqnUMHFSepXVBz9ppELQG9gwc+g5OIxYaAWv6bk0wNBuWAC2yYYHQgZ645lJgNVDTuA9cLA1WA51ZL7SZv2TDFkA7wB3wraCZzh+B/VBYGcakEJF3EfkQEdf+ExF5NWtzd2cf/at/bulDintjDPJkaXCa4t5YN+4Bm7EaTIHNj36qe1NF3ExxbzIsR/jZ1o+Alm66aqW6McC9nTlUI0YbuM9xY417R8DOPGIAG8C59UKPU9zoQAdWvxtVY1nJkMCZBp5kETvQEXALrLlR0TzHVWA3S1FVaBdo+zJN4U3Kmenbnv8A07M/uG75KaMAAAAASUVORK5CYII="
local CHEV_B64 = "iVBORw0KGgoAAAANSUhEUgAAADgAAAA4CAYAAACohjseAAAC80lEQVR42t2bP2gUQRSHZzcHERIJpAjCWQRMYwpNFYRUCsJZXZVKrNIpCOm0kAOLiI1VsLrG2FkFEbRJbNIEBUWIRRoJRGOKgMR/0dvzs3AGhuEUd3eW+yUD4SYwHPNmfrz3zXvvDHAd+Maf0SH/6AI/gNvGDqBmlAZwDnhrN5wBv3Ia6dY/AerOSCBRMG7Afg4DbW/TWU4j3fqPQNN+ZwKkMkba+RywX1Cy/qHcc1KVkKw9bXebk8B6Qcl27R/AGnDaHaKKZN2pD9pbKCpZd/ufgCu91NJPI1NvPgvsRpBsGxhSk6y7zXFgpYcE/9fDOkPfANOSkrXzVgTJHgDzcpJ1sgUawJa36bwOyI1HwJgUGHiSHQOWPQnmlay7zXfAhfAQlWLmvLfZTkHJArSkMM8nFGAG2CgRM936FWBcDfOcZEeApQgOaBeY7RWulDDvSyTMG1TFvLPAi4KS9WPmOjCpjHmLESS7D8ypxcyBAPP2Ikh2CRhRxbwJYDUC5m0AM17MlJJsCtz5SwzMI9mOKuYldn4J2C6BeW79sjLm1YHHETBvC2gop0ZulMA83wEteFRVU5Gsj3mbJSTrbn8VmFDFvFHgYYSYuaeOeVeB7xEkuwgcU8W8KeB1kEwuEjNfAWfUsutOskPAXeBnTg8bSvYzcCtVstEYY5Ik+WqM+eD+LzCcgxk2xpxUw7o68KyERN3tbQMX1SinCewUdDIh5Zzou5Px6xYBp2aHmlN7vDTWKnhppP0yzo97l4/UWzEIA/ePzGv/H4H88OdrKkIxjYxbBTCtkTON/BzSynpHfNDq1S0qSEloVJ4C3GqUTCpp1Q6DtOBChLTggSpuxUrsTqvFtlip+TZwXEmSsYorGj00Ectjel1QFRY4a0qSjFWi3pHoRKyoyeCpRC9pBW0iXeCmRMmrgkafTeC8Cm7FaNXKAtwaVXAkviRbJXAr83DrmoQkvU2cAp4XxC0/SfsSmOp7bAuMawLvS/6soAs8kGp4teM33tJJGvFR/EgAAAAASUVORK5CYII="

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64decode(s)
	local map = {}
	for i = 1, 64 do map[B64:byte(i)] = i - 1 end
	local out, buf, bits = {}, 0, 0
	for i = 1, #s do
		local v = map[s:byte(i)]
		if v then
			buf = buf * 64 + v
			bits += 6
			if bits >= 8 then
				bits -= 8
				local p = 2 ^ bits
				out[#out + 1] = string.char(math.floor(buf / p) % 256)
				buf = buf % p
			end
		end
	end
	return table.concat(out)
end

local function customAsset(id, fileName, b64)
	if id ~= "" then return id end
	if not (writefile and getcustomasset) then return nil end
	local ok, res = pcall(function()
		if not (isfile and isfile(fileName)) then writefile(fileName, b64decode(b64)) end
		return getcustomasset(fileName)
	end)
	if ok and res and res ~= "" then return res end
end

local A_GEAR = customAsset(ICON_GEAR, "kelsec_gear_v2.png", GEAR_B64)
local A_LOGS = customAsset(ICON_LOGS, "kelsec_logs_v2.png", LOGS_B64)
local A_X = customAsset("", "kelsec_x_v1.png", X_B64)
local A_CHEV = customAsset("", "kelsec_chev_v1.png", CHEV_B64)

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

local box -- editor TextBox (assigned below)
local function save()
	if not writefile then return end
	if box then settings.code = box.Text end
	pcall(writefile, SETTINGS_FILE, HttpService:JSONEncode(settings))
end

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

local function icon(parent, asset, x, y, w, h)
	return new("ImageLabel", { BackgroundTransparency = 1, Image = asset, Position = UDim2.fromOffset(px(x), px(y)), Size = UDim2.fromOffset(px(w), px(h)), ZIndex = 11 }, parent)
end

-- recessed rounded area used for the editor, log list and settings list
local function inner(parent, x, y, w, h)
	local f = box2(parent, x, y, w, h, { BackgroundColor3 = INNER, BackgroundTransparency = INNER_T, ClipsDescendants = true })
	new("UICorner", { CornerRadius = UDim.new(0, px(4)) }, f)
	new("UIStroke", { Color = INNER_EDGE, Thickness = 1 }, f)
	return f
end

-- window buttons: 28px square clickbox, 14px glyph
local function windowButton(parent, cx, cy)
	return new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(px(cx - 14), px(cy - 14)), Size = UDim2.fromOffset(px(28), px(28)), ZIndex = 10,
	}, parent)
end

local function xButton(parent, cx, cy)
	local b = windowButton(parent, cx, cy)
	if A_X then
		icon(b, A_X, 7, 7, 14, 14)
	else
		b.Text, b.Font, b.TextSize, b.TextColor3 = "×", F_GLYPH, px(24), WHITE
	end
	return b
end

local function minButton(parent, cx, cy)
	local b = windowButton(parent, cx, cy)
	box2(b, 7, 13, 14, 2, { BackgroundColor3 = WHITE })
	return b
end

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

---------------------------------------------------------------- lua highlighter
local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end
local KW = set({ "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue" })
local BI = set({ "game", "workspace", "script", "self", "shared", "_G", "_VERSION", "task", "table", "string", "math", "os", "debug", "coroutine", "utf8", "bit32", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "TweenInfo", "Random", "Ray", "Region3", "BrickColor", "Rect", "NumberSequence", "ColorSequence" })
local H = { kw = "#5AA6E0", bi = "#4EC9B0", fn = "#DCDCAA", str = "#CE9178", num = "#B5CEA8", com = "#6A9955" }
local ESC = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&apos;" }

local function highlight(src)
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

---------------------------------------------------------------- EXECUTOR PANEL  (648 x 312)
-- grid: 12px outer margin, 40px header, 28px square window buttons, 36px square bottom buttons
ex = newPanel("Executor", 648, 312, 10)
ex.state, ex.busy = "open", false
ex.tl = V2(px(311), px(244))
applyPos(ex)
local EW, EH = ex.W, ex.H
local BW, BH = px(52), px(52) -- minimized bubble, same top-left corner as the panel
local content = ex.content

-- title ">kelsec" built from single chars so it can morph into ">kl"
local titleGroup = new("CanvasGroup", { Name = "TitleGroup", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 5 }, ex.root)
ex.groups[2] = titleGroup
local fsE = px(24) -- same size minimized and not
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

label(content, "v1.0.0", 14 + 7 * cwE / S + 5, 17, 60, 15, F_MONO, 12, Color3.fromRGB(0xB4, 0xB4, 0xB9))
local header = box2(content, 0, 0, 560, 40, { BackgroundTransparency = 1 })

-- window controls
local minBtn = minButton(content, 590, 20)
local closeBtn = xButton(content, 622, 20)

-- editor
local ebox = inner(content, 12, 40, 624, 228)
local GUT = px(31)
local gclip = new("Frame", { Size = UDim2.new(0, GUT, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true }, ebox)
local fsC = px(13)
local TX, TY = px(10), px(6) -- text origin inside the scroll area
local gutter = new("TextLabel", {
	Position = UDim2.fromOffset(0, TY), Size = UDim2.new(0, px(25), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Font = F_MONO, TextSize = fsC, TextColor3 = Color3.fromRGB(0x78, 0x78, 0x80),
	TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top, Text = "1",
}, gclip)
new("Frame", { Position = UDim2.fromOffset(GUT, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0 }, ebox)

local sf = new("ScrollingFrame", {
	Position = UDim2.fromOffset(GUT + 1, 0), Size = UDim2.new(1, -(GUT + 1), 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY,
	ScrollingDirection = Enum.ScrollingDirection.XY, ElasticBehavior = Enum.ElasticBehavior.Never,
}, ebox)
box = new("TextBox", {
	Position = UDim2.fromOffset(TX, TY), Size = UDim2.new(1, -TX, 1, -TY), AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1, ClearTextOnFocus = false, MultiLine = true, TextWrapped = false, Font = F_MONO, TextSize = fsC,
	TextColor3 = WHITE, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	Text = type(settings.code) == "string" and settings.code or SAMPLE,
}, sf)
local hl = new("TextLabel", {
	Position = box.Position, Size = UDim2.new(), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, RichText = true,
	Font = F_MONO, TextSize = fsC, TextColor3 = Color3.fromRGB(0xD4, 0xD4, 0xD4), TextWrapped = false,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3,
}, sf)
-- exact font metrics (measured over long strings so rounding can't drift on long lines / many lines)
local ADV = TextService:GetTextSize(("A"):rep(200), fsC, F_MONO, V2(100000, 100000)).X / 200
local PITCH = TextService:GetTextSize(("A\n"):rep(100) .. "A", fsC, F_MONO, V2(100000, 100000)).Y / 101
local lineH = math.floor(PITCH + 0.5)
local caret = new("Frame", { Name = "Caret", Size = UDim2.fromOffset(2, lineH), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 4 }, sf)

local barHost = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, ebox)
scrollbar(sf, true, barHost)
scrollbar(sf, false, barHost)

local lastN, hlPending = 0, false
local function rehighlight()
	hlPending = false
	if not alive then return end
	local txt = box.Text
	hl.Text = highlight(txt)
	local n = select(2, txt:gsub("\n", "")) + 1
	if n ~= lastN then
		lastN = n
		local t = table.create(n)
		for k = 1, n do t[k] = k end
		gutter.Text = table.concat(t, "\n")
	end
end

local function textW(s) return (utf8.len(s) or #s) * ADV end
local function rnd(n) return math.floor(n + 0.5) end

-- selection highlight (drawn by us, behind the text)
local selPool = {}
local function updateSelection()
	local used = 0
	local a, b = box.SelectionStart, box.CursorPosition
	if box:IsFocused() and a ~= -1 and b ~= -1 and a ~= b then
		local s, e = math.min(a, b), math.max(a, b) -- selects chars s .. e-1
		local idx, lineNo = 1, 0
		for line in (box.Text .. "\n"):gmatch("(.-)\n") do
			local le = idx + #line -- position of this line's newline
			if e > idx and s <= le then
				local x1 = textW(line:sub(1, math.max(s, idx) - idx))
				local x2 = textW(line:sub(1, math.min(e, le) - idx))
				if e > le then x2 += px(6) end -- newline is selected too
				if x2 > x1 then
					used += 1
					local f = selPool[used]
					if not f then
						f = new("Frame", { BackgroundColor3 = SEL, BorderSizePixel = 0, ZIndex = 1 }, sf)
						selPool[used] = f
					end
					f.Position = UDim2.fromOffset(TX + rnd(x1), TY + rnd(lineNo * PITCH))
					f.Size = UDim2.fromOffset(rnd(x2) - rnd(x1), lineH)
					f.Visible = true
				end
			end
			idx = le + 1
			lineNo += 1
			if idx > e then break end
		end
	end
	for k = used + 1, #selPool do selPool[k].Visible = false end
end

-- caret: drawn by us (the real one is hidden with the text), also scrolls the view to follow typing
local lastMove = os.clock()
local cCP, cSS, cN -- last seen cursor / selection / length (polled every frame)
local function updateCaret()
	updateSelection()
	if not box:IsFocused() then caret.Visible = false return end
	local cp = box.CursorPosition
	if cp < 1 then return end
	local before = box.Text:sub(1, cp - 1)
	local lines = select(2, before:gsub("\n", ""))
	local colText = before:sub(before:match(".*\n()") or 1)
	local cx, cy = TX + rnd(textW(colText)), TY + rnd(lines * PITCH)
	caret.Position = UDim2.fromOffset(cx, cy)
	lastMove = os.clock()
	local view, pos = sf.AbsoluteWindowSize, sf.CanvasPosition
	if cy < pos.Y then pos = V2(pos.X, cy)
	elseif cy + lineH > pos.Y + view.Y then pos = V2(pos.X, cy + lineH - view.Y) end
	if cx < pos.X then pos = V2(math.max(0, cx - px(20)), pos.Y)
	elseif cx + px(20) > pos.X + view.X then pos = V2(cx + px(20) - view.X, pos.Y) end
	if pos ~= sf.CanvasPosition then sf.CanvasPosition = pos end
end

local fixing = false
bind(box:GetPropertyChangedSignal("Text"), function()
	-- tabs -> 4 spaces so the monospace caret math stays exact
	if not fixing and box.Text:find("\t", 1, true) then
		fixing = true
		local txt, cp = box.Text, box.CursorPosition
		local tabs = cp > 0 and select(2, txt:sub(1, cp - 1):gsub("\t", "")) or 0
		box.Text = txt:gsub("\t", "    ")
		if cp > 0 then box.CursorPosition = cp + tabs * 3 end
		fixing = false
	end
	if not hlPending then hlPending = true task.defer(rehighlight) end
end)
bind(box.FocusLost, function() caret.Visible = false cCP = nil updateSelection() save() end)
rehighlight()

bind(sf:GetPropertyChangedSignal("CanvasPosition"), function()
	gutter.Position = UDim2.fromOffset(0, TY - sf.CanvasPosition.Y)
end)

-- shift + wheel scrolls sideways
bind(UIS.InputChanged, function(i)
	if i.UserInputType == Enum.UserInputType.MouseWheel and UIS:IsKeyDown(Enum.KeyCode.LeftShift) and overFrame(sf) then
		sf.CanvasPosition = V2(math.max(0, sf.CanvasPosition.X - i.Position.Z * 60), sf.CanvasPosition.Y)
	end
end)

-- bottom row (y 268..312): settings, logs, run. 36px square buttons, 28px icons
local function bottomButton(x)
	return new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(px(x), px(272)), Size = UDim2.fromOffset(px(36), px(36)), ZIndex = 10 }, content)
end

local gearBtn = bottomButton(12)
if A_GEAR then icon(gearBtn, A_GEAR, 4, 4, 28, 28)
else new("TextLabel", { BackgroundTransparency = 1, Text = "⚙", Font = Enum.Font.SourceSansBold, TextSize = px(28), TextColor3 = WHITE, Size = UDim2.fromScale(1, 1) }, gearBtn) end

local logsBtn = bottomButton(52)
local logsIcon = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(px(4), px(8)), Size = UDim2.fromOffset(px(28), px(21)) }, logsBtn)
if A_LOGS then icon(logsIcon, A_LOGS, 0, 0, 28, 21)
else
	new("UIStroke", { Color = WHITE, Thickness = 2 }, logsIcon)
	box2(logsIcon, 0, 5, 28, 2, { BackgroundColor3 = WHITE })
end
dot = new("Frame", { Position = UDim2.fromOffset(px(25), px(3)), Size = UDim2.fromOffset(px(10), px(10)), BackgroundColor3 = GREEN, BorderSizePixel = 0, Visible = false, ZIndex = 12 }, logsBtn)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

local runBtn = bottomButton(600)
if A_CHEV then icon(runBtn, A_CHEV, 4, 4, 28, 28)
else new("TextLabel", { BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBlack, TextSize = px(32), TextColor3 = WHITE, Size = UDim2.fromScale(1, 1) }, runBtn) end

---------------------------------------------------------------- LOGS PANEL  (471 x 557)
logsP = newPanel("Logs", 471, 557, 10)
do
	local c = logsP.content
	local lh = box2(c, 0, 0, 365, 40, { BackgroundTransparency = 1 })
	label(c, "logs", 14, 11, 100, 18, F_CODE, 16)
	local clear = new("TextButton", {
		Text = "clear", Font = F_CODE, TextSize = px(12), TextColor3 = WHITE, AutoButtonColor = false,
		Position = UDim2.fromOffset(px(371), px(9)), Size = UDim2.fromOffset(px(52), px(22)),
		BackgroundColor3 = INNER, BackgroundTransparency = INNER_T, BorderSizePixel = 0, ZIndex = 10,
	}, c)
	new("UICorner", { CornerRadius = UDim.new(0, px(4)) }, clear)
	new("UIStroke", { Color = CTRL_EDGE, Thickness = 1 }, clear)
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
	-- caret: follows cursor / selection / text, solid while you move or type, then blinks
	if box:IsFocused() and ex.state == "open" then
		local cp, ss, n = box.CursorPosition, box.SelectionStart, #box.Text
		if cp ~= cCP or ss ~= cSS or n ~= cN then
			cCP, cSS, cN = cp, ss, n
			updateCaret()
		end
		caret.Visible = (os.clock() - lastMove) % 1.06 < 0.53
	else
		caret.Visible = false
		cCP = nil
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

---------------------------------------------------------------- SETTINGS PANEL  (297 x 188)
setP = newPanel("Settings", 297, 188, 10)
do
	local c = setP.content
	local sh = box2(c, 0, 0, 255, 40, { BackgroundTransparency = 1 })
	label(c, "settings", 0, 11, 297, 18, F_CODE, 16, WHITE, Enum.TextXAlignment.Center)
	local sclose = xButton(c, 271, 20)
	local panelInner = inner(c, 12, 40, 273, 136)

	local rows = {
		{ "keep", "Keep executor between sessions" },
		{ "sendLogs", "Send logs to executor" },
		{ "autoRejoin", "Auto re-join after disconnect" },
		{ "serverHop", "Server-hop instead of re-join" },
	}
	for idx, rw in ipairs(rows) do
		local key = rw[1]
		local row = new("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, px(6 + (idx - 1) * 32)), Size = UDim2.fromOffset(px(273), px(28)),
		}, panelInner)
		new("TextLabel", {
			Text = rw[2], Font = F_UI, TextSize = px(14), TextColor3 = WHITE, BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(px(14), 0), Size = UDim2.new(0, px(210), 1, 0),
		}, row)
		local cb = new("Frame", { Position = UDim2.fromOffset(px(243), px(6)), Size = UDim2.fromOffset(px(16), px(16)), BorderSizePixel = 0 }, row)
		new("UICorner", { CornerRadius = UDim.new(0, px(3)) }, cb)
		new("UIStroke", { Color = CTRL_EDGE, Thickness = 1 }, cb)
		local function paint()
			local on = settings[key]
			cb.BackgroundColor3 = on and WHITE or BLACK
			cb.BackgroundTransparency = on and 0.15 or 0.8
		end
		paint()
		bind(row.MouseButton1Click, function()
			settings[key] = not settings[key]
			paint()
			if key == "keep" and settings.keep then queueSelf(true) end
			if key == "sendLogs" and settings.sendLogs and not rcon then
				emit("rconsoleprint is unavailable: logs can't be sent to the executor console", LOG_WARN, true)
			end
			save()
		end)
	end
	bind(sclose.MouseButton1Click, function() fadeClose(setP) end)
	makeDrag(sh, function() return setP.tl end, function(v) setTL(setP, v) end)
end

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
	place(setP, 171, 392)
	popOpen(setP)
end

bind(gearBtn.MouseButton1Click, toggleSettings)
bind(logsBtn.MouseButton1Click, toggleLogs)

---------------------------------------------------------------- run
local function run()
	save()
	if not loadstring then emit("loadstring is unavailable in this environment", LOG_ERR, true) return end
	local fn, err = loadstring(box.Text, "=kelsec")
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

---------------------------------------------------------------- minimize / restore / close
-- the panel shrinks into / grows out of its own top-left corner, so that corner never moves
local function minimize()
	if ex.busy or ex.state ~= "open" then return end
	ex.busy, ex.state = true, "min"
	caret.Visible = false
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

---------------------------------------------------------------- start
if settings.keep then queueSelf(false) end
popOpen(ex)
