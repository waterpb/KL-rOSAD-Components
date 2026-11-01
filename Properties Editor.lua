--!nonstrict
--[[
	Tool Properties Editor - single LocalScript (put in StarterPlayerScripts).
	Edits Tools that are equipped or in the local Backpack. Client-side only.
	Sections: utils / persistence / theme+components / window+animations / model / tracking.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SCHEMA, FOLDER, KEY, GUI_NAME = 1, "ToolPropertiesEditor", "__ToolPropsEditor", "ToolPropsEditorGui"

local player = Players.LocalPlayer
if not player then return end
local env = (getgenv and getgenv()) or _G

-- Single-instance guard: close any previous run first.
do
	local prev = env[KEY]
	if type(prev) == "table" and prev.cleanup then pcall(prev.cleanup) end
	env[KEY] = nil
end
local playerGui = player:WaitForChild("PlayerGui")
do
	local old = playerGui:FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end

----------------------------------------------------------------------
-- Utilities
----------------------------------------------------------------------
local function Bin()
	local list = {}
	return {
		add = function(_, c) list[#list + 1] = c; return c end,
		clean = function()
			for i = #list, 1, -1 do
				local c = list[i]; list[i] = nil
				pcall(c.Disconnect, c)
			end
		end,
	}
end
local function on(bin, sig, fn) return bin:add(sig:Connect(fn)) end

local threads = {} -- every pending/looping task, so cleanup can cancel them all
local function later(sec, fn)
	local th
	th = task.delay(sec, function() threads[th] = nil; fn() end)
	threads[th] = true
	return th
end
local function cancel(th)
	if th then threads[th] = nil; pcall(task.cancel, th) end
end

local function fmtNum(n) return string.format("%.9g", n) end
local function fmt(t, v)
	if t == "string" then return v
	elseif t == "number" then return fmtNum(v)
	elseif t == "Vector3" then return ("%s, %s, %s"):format(fmtNum(v.X), fmtNum(v.Y), fmtNum(v.Z))
	elseif t == "Vector2" then return ("%s, %s"):format(fmtNum(v.X), fmtNum(v.Y))
	elseif t == "Color3" then return "#" .. v:ToHex()
	elseif typeof(v) == "Instance" then return v:GetFullName()
	elseif typeof(v) == "EnumItem" then return v.Name end
	return tostring(v)
end
local function nums(text, n)
	local out = {}
	for tok in text:gmatch("[^,%s]+") do
		local x = tonumber(tok)
		if not x or x ~= x or math.abs(x) == math.huge then return nil end
		out[#out + 1] = x
	end
	if #out == n then return out end
	return nil
end
local function parse(t, text)
	if t == "string" then return text
	elseif t == "number" then
		local n = tonumber(text)
		if n and n == n and math.abs(n) < math.huge then return n end
	elseif t == "Vector3" then
		local a = nums(text, 3); if a then return Vector3.new(a[1], a[2], a[3]) end
	elseif t == "Vector2" then
		local a = nums(text, 2); if a then return Vector2.new(a[1], a[2]) end
	elseif t == "Color3" then
		local hex = text:match("^%s*#?(%x%x%x%x%x%x)%s*$")
		if hex then
			local ok, c = pcall(Color3.fromHex, hex)
			if ok then return c end
		end
		local a = nums(text, 3)
		if a then return Color3.fromRGB(math.clamp(a[1], 0, 255), math.clamp(a[2], 0, 255), math.clamp(a[3], 0, 255)) end
	end
	return nil
end
local function same(a, b)
	local ta = typeof(a)
	if ta ~= typeof(b) then return false end
	if ta == "number" then return math.abs(a - b) <= 1e-5 * math.max(1, math.abs(a), math.abs(b))
	elseif ta == "Vector3" or ta == "Vector2" then return (a - b).Magnitude <= 1e-4 * math.max(1, a.Magnitude)
	elseif ta == "Color3" then return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) <= 1e-4 end
	return a == b
end
local function enc(v)
	local t = typeof(v)
	if t == "string" or t == "number" or t == "boolean" then return v
	elseif t == "Vector3" then return {v.X, v.Y, v.Z}
	elseif t == "Vector2" then return {v.X, v.Y}
	elseif t == "Color3" then return {v.R, v.G, v.B}
	elseif t == "EnumItem" then return v.Name end
	return nil
end
local function isNums(e, n)
	if type(e) ~= "table" or #e ~= n then return false end
	for i = 1, n do if type(e[i]) ~= "number" then return false end end
	return true
end
local function dec(t, e, enumType)
	if t == "string" or t == "number" or t == "boolean" then return type(e) == t and e or nil
	elseif t == "Vector3" and isNums(e, 3) then return Vector3.new(e[1], e[2], e[3])
	elseif t == "Vector2" and isNums(e, 2) then return Vector2.new(e[1], e[2])
	elseif t == "Color3" and isNums(e, 3) then return Color3.new(e[1], e[2], e[3])
	elseif t == "EnumItem" and enumType and type(e) == "string" then
		local ok, item = pcall(function() return enumType[e] end)
		if ok and typeof(item) == "EnumItem" then return item end
	end
	return nil
end

----------------------------------------------------------------------
-- Persistence (safe writes, corruption/outdated handling, memory fallback)
----------------------------------------------------------------------
local fs = {ok = false, note = "Memory only (no filesystem API)"}
do
	local fns = {writefile, readfile, isfile, isfolder, makefolder}
	local all = true
	for i = 1, 5 do if type(fns[i]) ~= "function" then all = false end end
	if all and pcall(function()
		if not isfolder(FOLDER) then makefolder(FOLDER) end
		writefile(FOLDER .. "/.probe", "ok")
	end) then
		fs.ok = true
		fs.note = "Saving to workspace/" .. FOLDER
	end
end

local function flush(s)
	s.dirty = false
	if not fs.ok then return false end
	local okJ, json = pcall(HttpService.JSONEncode, HttpService, {v = SCHEMA, d = s.data})
	if not okJ then return false end
	local tmp = s.path .. ".tmp"
	-- No atomic rename API: write temp, verify read-back, keep previous as .bak, then replace.
	local good = pcall(writefile, tmp, json) and pcall(function() assert(readfile(tmp) == json) end)
	if not good then return false end
	pcall(function() if isfile(s.path) then writefile(s.path .. ".bak", readfile(s.path)) end end)
	return (pcall(writefile, s.path, json))
end
local function markDirty(s)
	s.dirty = true
	if not s.thread then
		s.thread = later(1.5, function() s.thread = nil; if s.dirty then flush(s) end end)
	end
end
local function newStore(file)
	local s = {path = FOLDER .. "/" .. file, dirty = false, data = nil, note = nil}
	local function tryLoad(path)
		if not fs.ok then return nil, "none" end
		local ok, raw = pcall(function() return isfile(path) and readfile(path) or nil end)
		if not ok or not raw then return nil, "missing" end
		local okD, obj = pcall(HttpService.JSONDecode, HttpService, raw)
		if not okD or type(obj) ~= "table" or type(obj.d) ~= "table" then return nil, "corrupt", raw end
		if obj.v ~= SCHEMA then return nil, "outdated", raw end
		return obj.d
	end
	local d, why, raw = tryLoad(s.path)
	if not d and (why == "corrupt" or why == "outdated") then
		pcall(writefile, s.path .. ".old", raw)
		d = tryLoad(s.path .. ".bak")
		s.note = ("%s was %s; %s"):format(file, why, d and "restored from backup" or "reset to defaults")
	end
	s.data = d or {}
	return s
end

local settingsStore, suggStore, toolsStore = newStore("settings.json"), newStore("suggestions.json"), newStore("tools.json")
local settings, suggData = settingsStore.data, suggStore.data
if type(settings.autoUpdate) ~= "boolean" then settings.autoUpdate = true end
if type(settings.rememberTools) ~= "boolean" then settings.rememberTools = false end
if type(settings.revertOnClose) ~= "boolean" then settings.revertOnClose = false end
if type(settings.collapsed) ~= "table" then settings.collapsed = {} end
if type(settings.pos) ~= "table" or type(settings.pos.x) ~= "number" or type(settings.pos.y) ~= "number" then settings.pos = nil end
for k, list in pairs(suggData) do
	local clean = {}
	if type(list) == "table" then
		for _, s in ipairs(list) do if type(s) == "string" and #clean < 8 then clean[#clean + 1] = s end end
	end
	suggData[k] = #clean > 0 and clean or nil
end

----------------------------------------------------------------------
-- State, forward declarations, cleanup
----------------------------------------------------------------------
local alive = true
local state = "expanded" -- expanded | minimized | animating | closed
local mainBin, containerBin, dragBin, lockBin = Bin(), Bin(), Bin(), Bin()
local entries = {}                                   -- [Tool] = entry
local activeLocks = {}                               -- [row] = lock (enforced every frame)
local selected, uidN, filterText, filterVer = nil, 0, "", 0
local baseName = setmetatable({}, {__mode = "k"})    -- first name seen per Tool instance
local weakRec = setmetatable({}, {__mode = "k"})     -- per-instance saved-settings record
local polledRows, pollTh, searchTh, hideTh, lockConnected = {}, nil, nil, nil, false
local gui

local revertAll, hidePopup, showPopup, setStatus, refreshRow, onChanged, commit, applyFilter
local refreshLabels, selectEntry, removeEntry, removeRow, bindHandle

local function cleanup()
	if state == "closed" then return end
	state, alive = "closed", false
	for th in pairs(threads) do pcall(task.cancel, th) end
	table.clear(threads)
	lockBin:clean(); table.clear(activeLocks)                          -- stop the lock loop, release every lock
	for _, e in pairs(entries) do e.locks = {} end
	if settings.revertOnClose and revertAll then pcall(revertAll) end   -- optional: undo temporary edits
	for _, s in ipairs({settingsStore, suggStore, toolsStore}) do if s.dirty then pcall(flush, s) end end
	mainBin:clean(); containerBin:clean(); dragBin:clean()
	for _, e in pairs(entries) do
		e.bin:clean()
		for _, r in pairs(e.rowByKey) do r.ui:clean(); r.sig:clean() end
	end
	if gui then pcall(function() gui:Destroy() end) end                 -- window + bubble live inside it
	table.clear(entries); table.clear(polledRows); table.clear(baseName); table.clear(weakRec)
	selected, gui, pollTh, searchTh, hideTh = nil, nil, nil, nil, nil
	if type(env[KEY]) == "table" and env[KEY].cleanup == cleanup then env[KEY] = nil end
end
env[KEY] = {cleanup = cleanup}

----------------------------------------------------------------------
-- Theme + components
----------------------------------------------------------------------
local T = {
	accent = Color3.fromRGB(94, 140, 255), text = Color3.fromRGB(235, 238, 245), sub = Color3.fromRGB(150, 156, 172),
	white = Color3.new(1, 1, 1), bg = Color3.fromRGB(16, 18, 26), gradTop = Color3.fromRGB(34, 38, 54),
	gradBot = Color3.fromRGB(14, 16, 24), danger = Color3.fromRGB(235, 80, 80),
	font = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold,
	winW = 520, headerH = 38, bubble = 52, margin = 8, pad = 12, radius = 8, ctl = 4,
}
local QUAD, QUINT, OUT = Enum.EasingStyle.Quad, Enum.EasingStyle.Quint, Enum.EasingDirection.Out

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function merge(base, extra)
	if extra then for k, v in pairs(extra) do base[k] = v end end
	return base
end
local function tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur, style or QUAD, dir or OUT), props)
	t:Play()
	return t
end
local function corner(inst, r) return new("UICorner", {CornerRadius = r or UDim.new(0, T.ctl)}, inst) end
local function label(parent, text, props)
	return new("TextLabel", merge({BackgroundTransparency = 1, Font = T.font, TextSize = 13, TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextTruncate = Enum.TextTruncate.AtEnd}, props), parent)
end
local function button(parent, text, props)
	return new("TextButton", merge({BackgroundColor3 = T.white, BackgroundTransparency = 0.92, BorderSizePixel = 0, Font = T.font,
		TextSize = 13, TextColor3 = T.text, Text = text, AutoButtonColor = false}, props), parent)
end
local function hoverFade(bin, btn, base, over) -- subtle background hover
	on(bin, btn.MouseEnter, function() tween(btn, 0.12, {BackgroundTransparency = over}) end)
	on(bin, btn.MouseLeave, function() tween(btn, 0.12, {BackgroundTransparency = base}) end)
end
local function scroller(parent, props)
	return new("ScrollingFrame", merge({BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.white, ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y}, props), parent)
end
local function createHeaderButton(parent, text, x, hoverColor)
	local b = button(parent, text, {Position = UDim2.new(1, x, 0, 5), Size = UDim2.fromOffset(28, 28), Font = T.bold, TextSize = 16})
	corner(b, UDim.new(0.5, 0))
	on(mainBin, b.MouseEnter, function() tween(b, 0.12, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.5}) end)
	on(mainBin, b.MouseLeave, function() tween(b, 0.12, {BackgroundColor3 = T.white, BackgroundTransparency = 0.92}) end)
	return b
end
local function createToggle(parent, text, x, y, w, key, onChange)
	local b = button(parent, "", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 22)})
	corner(b)
	hoverFade(mainBin, b, 0.92, 0.85)
	label(b, text, {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -36, 1, 0), TextSize = 11})
	local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(22, 12), BorderSizePixel = 0}, b)
	corner(track, UDim.new(0.5, 0))
	local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.white, BorderSizePixel = 0}, track)
	corner(knob, UDim.new(0.5, 0))
	local function paint(animate)
		local isOn = settings[key]
		local d = animate and 0.12 or 0
		tween(track, d, {BackgroundColor3 = isOn and T.accent or T.white, BackgroundTransparency = isOn and 0 or 0.8})
		tween(knob, d, {Position = UDim2.new(0, isOn and 12 or 2, 0.5, 0)})
	end
	on(mainBin, b.Activated, function()
		settings[key] = not settings[key]
		paint(true); markDirty(settingsStore)
		if onChange then onChange() end
	end)
	paint(false)
end
local function createAction(parent, text, x, w, fn)
	local b = new("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 0), Size = UDim2.fromOffset(w, 20),
		BackgroundTransparency = 1, Font = T.bold, TextSize = 11, TextColor3 = T.accent, Text = text, AutoButtonColor = false}, parent)
	on(mainBin, b.MouseEnter, function() tween(b, 0.12, {TextColor3 = T.white}) end)
	on(mainBin, b.MouseLeave, function() tween(b, 0.12, {TextColor3 = T.accent}) end)
	on(mainBin, b.Activated, fn)
	return b
end

----------------------------------------------------------------------
-- Window (ScreenGui, header, content CanvasGroup, bubble)
----------------------------------------------------------------------
gui = new("ScreenGui", {Name = GUI_NAME, ResetOnSpawn = false, DisplayOrder = 2147483647, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
-- Keep the GUI parented to PlayerGui (max DisplayOrder) even if something re-parents it.
on(mainBin, gui.AncestryChanged, function()
	if alive and gui and gui.Parent ~= playerGui then gui.Parent = playerGui end
end)

local function viewport()
	local s = gui.AbsoluteSize
	if s.X < 100 and workspace.CurrentCamera then return workspace.CurrentCamera.ViewportSize end
	return s
end
local function expandedSize()
	local vp = viewport()
	return Vector2.new(math.min(T.winW, vp.X - 2 * T.margin), math.clamp(440, 280, vp.Y - 2 * T.margin))
end
local function clampPos(x, y, w, h)
	local vp = viewport()
	return math.clamp(x, T.margin, math.max(T.margin, vp.X - w - T.margin)),
		math.clamp(y, T.margin, math.max(T.margin, vp.Y - h - T.margin))
end

local size0 = expandedSize()
local px, py = (viewport().X - size0.X) / 2, (viewport().Y - size0.Y) / 2
if settings.pos then px, py = settings.pos.x, settings.pos.y end
px, py = clampPos(px, py, size0.X, size0.Y)

local win = new("Frame", {Name = "MainWindow", Size = UDim2.fromOffset(size0.X, size0.Y), Position = UDim2.fromOffset(px, py),
	BackgroundColor3 = T.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1}, gui)
local winCorner = new("UICorner", {CornerRadius = UDim.new(0, T.radius)}, win)
new("UIStroke", {Color = T.white, Transparency = 0.72, Thickness = 1}, win)
new("UIGradient", {Color = ColorSequence.new(T.gradTop, T.gradBot), Rotation = 90}, win)

local content = new("CanvasGroup", {Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, win)
local header = new("Frame", {Size = UDim2.new(1, 0, 0, T.headerH), BackgroundTransparency = 1}, content)
label(header, "Tool Properties Editor", {Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -90, 1, 0), Font = T.bold, TextSize = 15})
new("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.white, BackgroundTransparency = 0.92, BorderSizePixel = 0}, header)
local minBtn = createHeaderButton(header, "–", -(T.pad + 28 + 6 + 28), T.accent)
local closeBtn = createHeaderButton(header, "×", -(T.pad + 28), T.danger)
local body = new("Frame", {Position = UDim2.fromOffset(0, T.headerH), Size = UDim2.new(1, 0, 1, -T.headerH), BackgroundTransparency = 1}, content)

-- Minimized bubble: ring + dot in a CanvasGroup (fades), plus a hitbox button
local bubbleGroup = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 20}, win)
-- Minimized icon: a gear built from Frames (no assets): a ring with a hole, plus 8 teeth around it
local gear = new("Frame", {Name = "Gear", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1}, bubbleGroup)
local gearBody = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1}, gear)
corner(gearBody, UDim.new(0.5, 0))
new("UIStroke", {Color = T.accent, Thickness = 5}, gearBody) -- the stroke is the gear body; the middle stays see-through
for i = 0, 7 do
	local a = i * 45
	local r = math.rad(a)
	local tooth = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 9), BackgroundColor3 = T.accent,
		BorderSizePixel = 0, Position = UDim2.new(0.5, math.sin(r) * 14, 0.5, -math.cos(r) * 14), Rotation = a}, gear)
	corner(tooth, UDim.new(0, 1))
end
local hitbox = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = false, Visible = false, ZIndex = 30}, win)

-- Left column: Tools list. Right column: search, options, properties, footer.
local sidebar = scroller(body, {Position = UDim2.fromOffset(T.pad, 8), Size = UDim2.new(0, 124, 1, -48)})
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, sidebar)
local fsLbl = label(body, fs.note, {Position = UDim2.new(0, T.pad, 1, -36), Size = UDim2.fromOffset(124, 30), TextSize = 10,
	TextColor3 = T.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.None})
local right = new("Frame", {Position = UDim2.fromOffset(146, 0), Size = UDim2.new(1, -146 - T.pad, 1, 0), BackgroundTransparency = 1}, body)
local searchBox = new("TextBox", {Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.gradBot, BackgroundTransparency = 0.2,
	BorderSizePixel = 0, ClearTextOnFocus = false, Font = T.font, TextSize = 13, TextColor3 = T.text, PlaceholderText = "Search properties / attributes",
	PlaceholderColor3 = T.sub, Text = "", TextXAlignment = Enum.TextXAlignment.Left}, right)
corner(searchBox)
new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, searchBox)
local bar = new("Frame", {Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1}, right)
local propHolder = new("Frame", {Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66 - 28), BackgroundTransparency = 1, ClipsDescendants = true}, right)
local emptyLbl = label(propHolder, "No Tools equipped or in your Backpack.", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.sub})
local footer = new("Frame", {Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1}, right)
local statusLbl = label(footer, "", {Size = UDim2.new(1, -140, 1, 0), TextSize = 11, TextColor3 = T.sub})

function setStatus(text, kind)
	statusLbl.Text = text
	statusLbl.TextColor3 = kind == "err" and T.danger or kind == "warn" and T.text or T.sub
end

-- Shared popup (enum dropdown + remembered-value suggestions)
local pop = {items = {}, owner = nil}
pop.frame = scroller(content, {Visible = false, ZIndex = 100, BackgroundTransparency = 0.02, BackgroundColor3 = T.gradTop})
corner(pop.frame)
new("UIStroke", {Color = T.white, Transparency = 0.8, Thickness = 1}, pop.frame)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, pop.frame)
local function popItem(i)
	local it = pop.items[i]
	if it then return it end
	local fr = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 101, LayoutOrder = i}, pop.frame)
	local b = button(fr, "", {Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 1, ZIndex = 102, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12})
	new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, b)
	local x = button(fr, "×", {Position = UDim2.new(1, -22, 0, 0), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 102,
		TextColor3 = T.danger, Font = T.bold, TextSize = 15})
	it = {frame = fr, btn = b, x = x}
	hoverFade(mainBin, b, 1, 0.88)
	on(mainBin, b.Activated, function() if it.pick then it.pick() end end)
	on(mainBin, x.Activated, function() if it.remove then it.remove() end end)
	pop.items[i] = it
	return it
end
function hidePopup() pop.frame.Visible = false; pop.owner = nil end
function showPopup(anchor, list, owner)
	if #list == 0 then hidePopup() return end
	for i, d in ipairs(list) do
		local it = popItem(i)
		it.btn.Text, it.pick, it.remove = d.text, d.pick, d.remove
		it.btn.Size = d.remove and UDim2.new(1, -22, 1, 0) or UDim2.new(1, 0, 1, 0)
		it.x.Visible, it.frame.Visible = d.remove ~= nil, true
	end
	for i = #list + 1, #pop.items do
		local it = pop.items[i]
		it.frame.Visible, it.pick, it.remove = false, nil, nil
	end
	local wp, ap, as = win.AbsolutePosition, anchor.AbsolutePosition, anchor.AbsoluteSize
	local h = math.min(#list, 8) * 22
	local y = ap.Y - wp.Y + as.Y + 2
	if y + h > win.AbsoluteSize.Y then y = ap.Y - wp.Y - h - 2 end
	pop.frame.Position = UDim2.fromOffset(ap.X - wp.X, y)
	pop.frame.Size = UDim2.fromOffset(math.max(as.X, 170), h)
	pop.owner = owner
	pop.frame.Visible = true
end
local function scheduleHide(sec)
	cancel(hideTh)
	hideTh = later(sec, function() hideTh = nil; hidePopup() end)
end

----------------------------------------------------------------------
-- Dragging + minimize / restore animations
----------------------------------------------------------------------
local function savePos()
	settings.pos = {x = win.Position.X.Offset, y = win.Position.Y.Offset}
	markDirty(settingsStore)
end
local function makeDraggable(handle, onClick)
	on(mainBin, handle.InputBegan, function(input)
		local ut = input.UserInputType
		if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
		if state ~= "expanded" and state ~= "minimized" then return end
		dragBin:clean()
		local start, origin, moved = input.Position, win.Position, false
		dragBin:add(UIS.InputChanged:Connect(function(i)
			if i ~= input and i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local d = i.Position - start
			if not moved and Vector2.new(d.X, d.Y).Magnitude < 4 then return end -- click vs drag threshold
			moved = true
			local sz = win.AbsoluteSize
			local x, y = clampPos(origin.X.Offset + d.X, origin.Y.Offset + d.Y, sz.X, sz.Y)
			win.Position = UDim2.fromOffset(x, y)
		end))
		dragBin:add(input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then return end
			dragBin:clean()
			if moved then savePos() elseif onClick then onClick() end
		end))
	end)
end

local function minimizeWindow()
	if state ~= "expanded" then return end
	state = "animating"
	hidePopup()
	task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		tween(content, 0.16, {GroupTransparency = 1})
		task.wait(0.08)
		tween(win, 0.36, {Size = UDim2.fromOffset(T.bubble, T.bubble), BackgroundTransparency = 0.10}, QUINT)
		tween(winCorner, 0.36, {CornerRadius = UDim.new(0.5, 0)}, QUINT)
		task.wait(0.18) -- 0.42s after the click
		content.Visible = false
		hitbox.Visible, hitbox.Active = true, true
		state = "minimized"
		tween(bubbleGroup, 0.20, {GroupTransparency = 0})
		savePos()
		threads[me] = nil
	end)
end
local function restoreWindow()
	if state ~= "minimized" then return end
	state = "animating"
	hitbox.Active = false
	task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		tween(bubbleGroup, 0.12, {GroupTransparency = 1})
		local sz = expandedSize()
		local x, y = clampPos(win.Position.X.Offset, win.Position.Y.Offset, sz.X, sz.Y)
		content.Visible = true
		tween(win, 0.36, {Size = UDim2.fromOffset(sz.X, sz.Y), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 0.08}, QUINT)
		tween(winCorner, 0.36, {CornerRadius = UDim.new(0, T.radius)}, QUINT)
		task.wait(0.14)
		tween(content, 0.22, {GroupTransparency = 0})
		task.wait(0.24) -- 0.38s total
		hitbox.Visible = false
		state = "expanded"
		savePos()
		threads[me] = nil
	end)
end
makeDraggable(header, nil)
makeDraggable(hitbox, restoreWindow)
on(mainBin, minBtn.Activated, minimizeWindow)
on(mainBin, closeBtn.Activated, cleanup)
if typeof(script) == "Instance" then pcall(function() on(mainBin, script.Destroying, cleanup) end) end

----------------------------------------------------------------------
-- Model: read/write, remembered values, saved Tool records
----------------------------------------------------------------------
local SUPPORTED = {string = true, number = true, boolean = true, Vector3 = true, Vector2 = true, Color3 = true, EnumItem = true}
local SUGGESTABLE = {string = true, number = true, Vector3 = true, Vector2 = true, Color3 = true}
local SHORT = {boolean = "bool"}

local SECTIONS = {
	{"Data", {
		{n = "Name", t = "string"}, {n = "ClassName", t = "string", ro = true}, {n = "Parent", t = "Instance", ro = true},
		{n = "Archivable", t = "boolean"},
	}},
	{"Behavior", {
		{n = "Enabled", t = "boolean"}, {n = "CanBeDropped", t = "boolean"}, {n = "RequiresHandle", t = "boolean"},
		{n = "ManualActivationOnly", t = "boolean"}, {n = "ToolTip", t = "string"}, {n = "TextureId", t = "string"},
	}},
	{"Grip", {
		{n = "Grip", t = "CFrame"}, {n = "GripPos", t = "Vector3"}, {n = "GripForward", t = "Vector3"},
		{n = "GripRight", t = "Vector3"}, {n = "GripUp", t = "Vector3"},
	}},
	{"Handle", {
		{n = "Size", t = "Vector3"}, {n = "Color", t = "Color3"}, {n = "Material", t = "EnumItem", e = Enum.Material},
		{n = "Transparency", t = "number"}, {n = "Anchored", t = "boolean"}, {n = "CanCollide", t = "boolean"},
		{n = "Massless", t = "boolean"}, {n = "AssemblyMass", t = "number", ro = true},
	}, true},
}

local function readRow(row)
	local inst = row.inst
	if not inst then return nil, false end
	if row.kind == "attr" then return inst:GetAttribute(row.name), true end
	local ok, v = pcall(function() return inst[row.name] end)
	return v, ok
end
local function writeRaw(row, v)
	local inst = row.inst
	if not inst then return false, "unavailable" end
	if row.kind == "attr" then return pcall(inst.SetAttribute, inst, row.name, v) end
	return pcall(function() inst[row.name] = v end)
end

local function pushSuggestion(row, text)
	if text == "" or #text > 120 then return end
	local k = row.type .. "|" .. row.title
	local list = suggData[k]
	if not list then list = {}; suggData[k] = list end
	local i = table.find(list, text)
	if i then
		if i == 1 then return end
		table.remove(list, i)
	end
	table.insert(list, 1, text)
	if #list > 8 then table.remove(list) end
	markDirty(suggStore)
end

-- Saved per-Tool records, keyed by the Tool's original name. Used only when that name is unique among
-- tracked Tools, or when this exact instance already owns a record this session.
local function recordFor(entry, create)
	local tool = entry.tool
	local rec = weakRec[tool]
	if rec then return rec end
	local name, n = baseName[tool], 0
	for _, e in pairs(entries) do if baseName[e.tool] == name then n += 1 end end
	if n > 1 then
		if create then rec = {f = {}}; weakRec[tool] = rec end
		return rec, true
	end
	rec = toolsStore.data[name]
	if type(rec) ~= "table" or type(rec.f) ~= "table" then
		if not create then return nil end
		rec = {f = {}}
		toolsStore.data[name] = rec
	end
	weakRec[tool] = rec
	return rec
end
local function rememberField(row, v)
	if not settings.rememberTools then return end
	local e = enc(v)
	if e == nil then return end
	local rec = recordFor(row.entry, true)
	if not rec then return end
	rec.f[row.key] = {t = row.type, v = e, lock = row.entry.locks[row.key] ~= nil or nil}
	markDirty(toolsStore)
end
local function noteOrig(row)
	local o = row.entry.orig
	if o[row.key] then return end
	local v, ok = readRow(row)
	o[row.key] = {has = ok and v ~= nil, v = v}
end

----------------------------------------------------------------------
-- Rows: slot (lock / RO / N/A), locks, editors, refresh, commit
----------------------------------------------------------------------
local function paintSlot(row)
	local s = row.slot
	if row.ro then
		s.Text, s.TextColor3, s.BackgroundTransparency = "RO", T.sub, 1
	elseif row.unsup then
		s.Text, s.TextColor3, s.BackgroundTransparency = "N/A", T.sub, 1
	else
		local lk = row.entry.locks[row.key] ~= nil
		s.Text, s.TextColor3 = lk and "LOCKED" or "Lock", lk and T.white or T.sub
		tween(s, 0.12, {BackgroundColor3 = lk and T.accent or T.white, BackgroundTransparency = lk and 0.1 or 0.9})
	end
end
local function setRO(row)
	row.ro = true
	row.entry.locks[row.key] = nil
	activeLocks[row] = nil
	for _, b in ipairs(row.boxes or {}) do b.TextEditable = false end
	paintSlot(row)
end
local function failRow(row, err)
	local msg = tostring(err)
	if #msg > 100 then msg = msg:sub(1, 100) .. "..." end
	row.stroke.Transparency = 0
	cancel(row.flashTh)
	row.flashTh = later(1.2, function()
		row.flashTh = nil
		if row.stroke.Parent then tween(row.stroke, 0.2, {Transparency = 1}) end
	end)
	local l = msg:lower()
	if l:find("cannot be assigned", 1, true) or l:find("read only", 1, true) or l:find("readonly", 1, true) or l:find("lacking capability", 1, true) then
		setRO(row)
		msg ..= " (marked read-only)"
	end
	setStatus(("Edit failed on %s: %s"):format(row.name, msg), "err")
end

function refreshRow(row, force)
	local v, ok = readRow(row)
	if not ok or v == nil then return end
	if not force and row.cur ~= nil and same(v, row.cur) then return end -- only touch UI when changed
	if row.setDisplay then row.setDisplay(v) end
end

-- LOCK LOOP: while any lock exists, one shared enforcer runs every frame (PreRender + Heartbeat) and
-- immediately on each change signal. It reads the live value and writes the locked value back whenever
-- it differs. It disconnects itself as soon as the last lock is released.
local function enforceRow(row, lock)
	if row.reasserting or not row.inst then return end
	local v, ok = readRow(row)
	if not ok then return end
	if v ~= nil and v == lock.value then lock.fails = 0 return end -- exact match; lock.value is a read-back so no float drift
	row.reasserting = true
	local w, err = writeRaw(row, lock.value)
	row.reasserting = false
	if w then
		lock.fails = 0
		lock.hits += 1
		local now = os.clock()
		if now - lock.shown > 0.25 then
			lock.shown = now
			setStatus(("Holding %s = %s  (reverted x%d)"):format(row.title, fmt(row.type, lock.value), lock.hits))
		end
	else
		lock.fails += 1 -- a write that keeps erroring means the property can't be held; stop after 5 straight failures
		if lock.fails >= 5 then row.entry.locks[row.key] = nil; activeLocks[row] = nil; paintSlot(row); setStatus(("Lock dropped on %s: %s"):format(row.name, tostring(err)), "err") end
	end
end
local function enforceAll()
	for row, lock in pairs(activeLocks) do pcall(enforceRow, row, lock) end
end
local function syncLockLoop()
	if next(activeLocks) then
		if not lockConnected then
			lockConnected = true
			lockBin:add(RunService.RenderStepped:Connect(enforceAll))
			lockBin:add(RunService.Stepped:Connect(enforceAll))
			lockBin:add(RunService.Heartbeat:Connect(enforceAll))
		end
	elseif lockConnected then
		lockConnected = false
		lockBin:clean()
	end
end
local function releaseLock(row)
	local entry = row.entry
	entry.locks[row.key] = nil
	activeLocks[row] = nil
	syncLockLoop()
	paintSlot(row)
	local rec = settings.rememberTools and recordFor(entry, false)
	if rec and rec.f[row.key] then rec.f[row.key].lock = nil; markDirty(toolsStore) end
end
local function setLock(row, on)
	if row.ro or row.unsup then return end
	if on then
		local live, ok = readRow(row)
		if not ok or live == nil then return end
		noteOrig(row)
		local lock = {value = live, fails = 0, hits = 0, shown = 0}
		row.entry.locks[row.key] = lock
		activeLocks[row] = lock
		syncLockLoop()
		paintSlot(row)
		rememberField(row, live)
		setStatus(("Locked %s = %s"):format(row.title, fmt(row.type, live)))
	else
		releaseLock(row)
	end
end

function commit(row, v, fromUser)
	local entry = row.entry
	if row.ro or row.unsup then return false end
	noteOrig(row)
	local lock = entry.locks[row.key]
	if lock then lock.value = v end -- the new value becomes the locked one
	local ok, err = writeRaw(row, v)
	local live = readRow(row)
	if not ok then
		if lock and live ~= nil then lock.value = live end
		failRow(row, err)
		refreshRow(row, true)
		return false
	end
	if live ~= nil then
		if lock then lock.value = live end -- hold the value Roblox actually accepted (clamping etc.)
		refreshRow(row, true)
	end
	if fromUser then
		if SUGGESTABLE[row.type] then pushSuggestion(row, fmt(row.type, v)) end
		rememberField(row, live ~= nil and live or v)
	end
	return true
end

function onChanged(row)
	local entry = row.entry
	if entry.dead then return end
	local lock = entry.locks[row.key]
	if lock then enforceRow(row, lock) end -- instant revert; the frame loop is the backstop
	local v, ok = readRow(row)
	if not ok then return end
	if row.kind == "prop" and row.name == "Name" and not row.target then refreshLabels() end
	if v == nil or lock then return end
	if not settings.autoUpdate or entry ~= selected then entry.stale = true return end
	refreshRow(row)
end

local function ensurePoll() -- lightweight 1s fallback, only for properties without a usable change signal
	if pollTh then return end
	pollTh = task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		while alive and next(polledRows) do
			task.wait(1)
			for row in pairs(polledRows) do if not row.entry.dead then onChanged(row) end end
		end
		threads[me], pollTh = nil, nil
	end)
end
local function connectRow(row)
	local inst = row.inst
	if not inst or row.kind ~= "prop" then return end
	local ok, sig = pcall(inst.GetPropertyChangedSignal, inst, row.name)
	if ok then
		row.sig:add(sig:Connect(function() onChanged(row) end))
	else
		polledRows[row] = true
		ensurePoll()
	end
end

-- Remembered-value suggestions
local function showSuggestions(row, anchor, filterStr)
	local k = row.type .. "|" .. row.title
	local list = suggData[k]
	if not list then hidePopup() return end
	local f = filterStr and filterStr ~= "" and filterStr:lower() or nil
	local out = {}
	for _, s in ipairs(list) do
		if not f or s:lower():find(f, 1, true) then
			out[#out + 1] = {
				text = s,
				pick = function()
					cancel(row.commitTh); row.commitTh = nil
					hidePopup()
					if row.applyText then row.applyText(s) end
				end,
				remove = function()
					local i = table.find(list, s)
					if i then table.remove(list, i) end
					if #list == 0 then suggData[k] = nil end
					markDirty(suggStore)
					showSuggestions(row, anchor, filterStr)
					scheduleHide(3)
				end,
			}
		end
	end
	showPopup(anchor, out, row)
end

local function buildEditor(row, holder)
	local t = row.type
	holder.ClipsDescendants = true
	if row.ro or row.unsup then
		local l = label(holder, "", {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -10, 1, 0), TextColor3 = T.sub, TextSize = 12})
		row.setDisplay = function(v)
			row.cur = v
			local s = fmt(t, v)
			if l.Text ~= s then l.Text = s end
		end
	elseif t == "boolean" then
		local b = button(holder, "", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextSize = 12, Font = T.bold})
		on(row.ui, b.Activated, function() if not row.ro and row.cur ~= nil then commit(row, not row.cur, true) end end)
		row.setDisplay = function(v)
			row.cur = v
			b.Text = tostring(v)
			tween(b, 0.1, {TextColor3 = v and T.accent or T.sub})
		end
	elseif t == "EnumItem" then
		local b = button(holder, "", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12})
		new("UIPadding", {PaddingLeft = UDim.new(0, 6)}, b)
		on(row.ui, b.Activated, function()
			if row.ro then return end
			if pop.owner == row then hidePopup() return end
			local list = {}
			for _, item in ipairs(row.enum:GetEnumItems()) do
				list[#list + 1] = {text = item.Name, pick = function() hidePopup(); commit(row, item, true) end}
			end
			showPopup(holder, list, row)
		end)
		row.setDisplay = function(v)
			row.cur = v
			if b.Text ~= v.Name then b.Text = v.Name end
		end
	else
		local n = (t == "Vector3" and 3) or (t == "Vector2" and 2) or 1
		local boxes, sw, x0 = {}, nil, 0
		row.boxes = boxes
		if t == "Color3" then
			sw = new("Frame", {Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(14, 10), BorderSizePixel = 0}, holder)
			corner(sw, UDim.new(0, 3))
			x0 = 22
		end
		local function textNow()
			local parts = {}
			for i, b in ipairs(boxes) do parts[i] = b.Text end
			return table.concat(parts, ", ")
		end
		local function anyFocused()
			for _, b in ipairs(boxes) do if b:IsFocused() then return true end end
			return false
		end
		row.setDisplay = function(v)
			row.cur = v
			if sw then sw.BackgroundColor3 = v end
			if anyFocused() then return end -- never overwrite what the user is typing
			if n == 1 then
				local s = fmt(t, v)
				if boxes[1].Text ~= s then boxes[1].Text = s end
			else
				local c = t == "Vector3" and {v.X, v.Y, v.Z} or {v.X, v.Y}
				for i, b in ipairs(boxes) do
					local s = fmtNum(c[i])
					if b.Text ~= s then b.Text = s end
				end
			end
		end
		local function redraw() if row.cur ~= nil then row.setDisplay(row.cur) end end
		local function submit()
			local v = parse(t, textNow())
			if v == nil then failRow(row, "invalid " .. t .. " value"); redraw() return end
			if row.cur ~= nil and same(v, row.cur) then redraw() return end
			commit(row, v, true)
		end
		row.applyText = function(s)
			for _, b in ipairs(boxes) do if b:IsFocused() then b:ReleaseFocus() end end
			local v = parse(t, s)
			if v ~= nil and not (row.cur ~= nil and same(v, row.cur)) then commit(row, v, true) else redraw() end
		end
		local function onBlur(enter)
			scheduleHide(0.2)
			if row.ro then redraw() return end
			local function go()
				row.commitTh = nil
				if not anyFocused() then submit() end
			end
			cancel(row.commitTh)
			if enter then row.commitTh = nil; go() else row.commitTh = later(0.12, go) end -- lets a suggestion click win
		end
		for i = 1, n do
			local b = new("TextBox", {BackgroundTransparency = 1, ClearTextOnFocus = false, Font = T.font, TextSize = 12, TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Left, Text = "",
				Position = n == 1 and UDim2.fromOffset(x0 + 6, 0) or UDim2.new((i - 1) / n, 5, 0, 0),
				Size = n == 1 and UDim2.new(1, -(x0 + 10), 1, 0) or UDim2.new(1 / n, -7, 1, 0)}, holder)
			boxes[i] = b
			on(row.ui, b.Focused, function()
				cancel(hideTh)
				if SUGGESTABLE[t] then showSuggestions(row, holder) end
			end)
			on(row.ui, b.FocusLost, onBlur)
			if n == 1 then
				on(row.ui, b:GetPropertyChangedSignal("Text"), function()
					if b:IsFocused() then showSuggestions(row, holder, b.Text) end
				end)
			end
		end
	end
end

local function addRow(entry, sec, d)
	local row = {
		entry = entry, sec = sec, name = d.n, title = d.title or d.n, kind = d.kind or "prop", type = d.t, enum = d.e, ro = d.ro or false,
		target = sec.handle and "Handle" or nil, unsup = not SUPPORTED[d.t], ui = Bin(), sig = Bin(), available = true,
	}
	row.key = d.key or ((row.kind == "attr" and "a:" or "p:") .. (row.target and "Handle." or "") .. row.name)
	row.inst = d.inst or (row.target and entry.handle or entry.tool)
	if row.target and not row.inst then row.available = false end
	if row.inst then
		local _, ok = readRow(row)
		if not ok then return nil end -- unreadable here: not shown
	end
	local typeText = d.e and tostring(d.e) or SHORT[d.t] or d.t
	row.lname, row.ltype = row.title:lower(), typeText:lower()
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.white, BackgroundTransparency = 0.95, BorderSizePixel = 0,
		Visible = false, LayoutOrder = sec.order * 10000 + #sec.rows + 1}, entry.content)
	corner(f)
	row.frame = f
	label(f, row.title, {Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 100, 1, 0)})
	local holder = new("Frame", {Position = UDim2.fromOffset(112, 3), Size = UDim2.new(1, -206, 0, 18), BackgroundColor3 = T.gradBot,
		BackgroundTransparency = 0.25, BorderSizePixel = 0}, f)
	corner(holder)
	row.stroke = new("UIStroke", {Color = T.danger, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, holder)
	row.typeLbl = label(f, typeText, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 0), Size = UDim2.new(0, 44, 1, 0),
		TextSize = 10, TextColor3 = T.sub})
	row.slot = button(f, "", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(40, 18),
		TextSize = 10, Font = T.bold})
	corner(row.slot)
	on(row.ui, row.slot.Activated, function()
		if row.ro or row.unsup then return end
		setLock(row, entry.locks[row.key] == nil)
	end)
	on(row.ui, row.slot.MouseEnter, function()
		if not row.ro and not row.unsup and not entry.locks[row.key] then tween(row.slot, 0.12, {BackgroundTransparency = 0.8}) end
	end)
	on(row.ui, row.slot.MouseLeave, function() paintSlot(row) end)
	buildEditor(row, holder)
	paintSlot(row)
	sec.rows[#sec.rows + 1] = row
	entry.rowByKey[row.key] = row
	if row.target then entry.handleRows[#entry.handleRows + 1] = row end
	connectRow(row)
	if row.inst then refreshRow(row, true) end
	return row
end

----------------------------------------------------------------------
-- Sections, filtering, entries
----------------------------------------------------------------------
local function createSection(entry, name, handle)
	local order = #entry.secList + 1
	local sec = {name = name, order = order, rows = {}, handle = handle, expanded = not settings.collapsed[name]}
	sec.header = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		LayoutOrder = order * 10000, Visible = false}, entry.content)
	local lbl = label(sec.header, "", {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -6, 1, 0), Font = T.bold, TextSize = 12,
		TextColor3 = T.sub, RichText = true})
	local function paint()
		lbl.Text = ('<font color="#5E8CFF">%s</font>  %s'):format(sec.expanded and "-" or "+", name)
	end
	paint()
	on(entry.bin, sec.header.Activated, function()
		sec.expanded = not sec.expanded
		settings.collapsed[name] = (not sec.expanded) or nil
		paint(); markDirty(settingsStore); hidePopup()
		applyFilter(entry)
	end)
	entry.secList[order] = sec
	return sec
end

function applyFilter(entry)
	entry.fv = filterVer
	local q = filterText
	for _, sec in ipairs(entry.secList) do
		local any = false
		for _, row in ipairs(sec.rows) do
			local match = row.available and (q == "" or row.lname:find(q, 1, true) ~= nil or row.ltype:find(q, 1, true) ~= nil)
			any = any or match
			local show = match and (q ~= "" or sec.expanded) or false
			if row.frame.Visible ~= show then row.frame.Visible = show end
		end
		if sec.header.Visible ~= any then sec.header.Visible = any end
	end
end
local function touchFilter(entry)
	if entry == selected then applyFilter(entry) else entry.fv = nil end
end
local function refreshAll(entry)
	entry.stale = false
	for _, sec in ipairs(entry.secList) do
		for _, row in ipairs(sec.rows) do if row.available then refreshRow(row) end end
	end
end

local function addAttrRow(entry, name)
	local v = entry.tool:GetAttribute(name)
	if v == nil or not entry.secAttr then return nil end
	return addRow(entry, entry.secAttr, {n = name, t = typeof(v), kind = "attr"})
end
local VALUE_TYPES = {BoolValue = "boolean", IntValue = "number", NumberValue = "number", StringValue = "string",
	Color3Value = "Color3", Vector3Value = "Vector3", CFrameValue = "CFrame", ObjectValue = "Instance"}
local function addValueRow(entry, child) -- ValueObjects (IntValue, NumberValue, ...) directly inside the Tool
	local t = VALUE_TYPES[child.ClassName]
	if not t or not entry.secVal or entry.valRows[child] then return nil end
	local key, n = "v:" .. child.Name, 1
	while entry.rowByKey[key] do n += 1; key = ("v:%s #%d"):format(child.Name, n) end
	local row = addRow(entry, entry.secVal, {n = "Value", t = t, title = child.Name, inst = child, key = key, ro = t == "Instance"})
	if row then entry.valRows[child] = row end
	return row
end
function removeRow(entry, row)
	row.ui:clean(); row.sig:clean()
	polledRows[row] = nil
	entry.locks[row.key] = nil
	if activeLocks[row] then activeLocks[row] = nil; syncLockLoop() end
	entry.rowByKey[row.key] = nil
	local i = table.find(row.sec.rows, row)
	if i then table.remove(row.sec.rows, i) end
	if pop.owner == row then hidePopup() end
	cancel(row.commitTh); cancel(row.flashTh)
	row.frame:Destroy()
end
local function onAttr(entry, name)
	if entry.dead or not entry.built then return end
	local key, v = "a:" .. name, entry.tool:GetAttribute(name)
	local row = entry.rowByKey[key]
	local locked = entry.locks[key] ~= nil
	if row then
		if locked or (v ~= nil and typeof(v) == row.type) then onChanged(row) return end
		removeRow(entry, row) -- removed, or its type changed: rebuild below if still present
	end
	if v ~= nil then
		addAttrRow(entry, name)
		local sec = entry.secAttr
		table.sort(sec.rows, function(a, b) return a.name < b.name end)
		for i, r in ipairs(sec.rows) do r.frame.LayoutOrder = sec.order * 10000 + i end
	end
	touchFilter(entry)
end

local function findHandle(tool)
	local h = tool:FindFirstChild("Handle")
	if h and h:IsA("BasePart") then return h end
	return nil
end
function bindHandle(entry)
	if entry.dead then return end
	local h = findHandle(entry.tool)
	if h == entry.handle then return end
	entry.handle = h
	for _, row in ipairs(entry.handleRows) do
		row.sig:clean()
		polledRows[row] = nil
		row.inst, row.available, row.cur = h, h ~= nil, nil
		if h then
			connectRow(row)
			refreshRow(row, true)
		end
	end
	touchFilter(entry)
end

local function applyRecord(entry)
	if not settings.rememberTools then return end
	local rec, ambiguous = recordFor(entry, false)
	if not rec then
		if ambiguous then setStatus(("Duplicate Tool name '%s': saved settings not applied"):format(baseName[entry.tool]), "warn") end
		return
	end
	local count = 0
	for key, s in pairs(rec.f) do
		if type(s) == "table" then
			local row = entry.rowByKey[key]
			if row then
				if not row.ro and not row.unsup and s.t == row.type then
					local v = dec(row.type, s.v, row.enum)
					if v ~= nil then
						local live = readRow(row)
						if live == nil or not same(v, live) then commit(row, v, false) end
						count += 1
						if s.lock then setLock(row, true) end
					end
				end
			elseif key:sub(1, 2) == "a:" then -- attribute missing on this Tool: restore it
				local v = dec(s.t, s.v)
				if v ~= nil and pcall(entry.tool.SetAttribute, entry.tool, key:sub(3), v) then count += 1 end
			end
		end
	end
	if count > 0 then setStatus(("Applied %d saved value(s) to %s"):format(count, entry.tool.Name)) end
end

local function buildEntry(entry)
	local me = coroutine.running()
	threads[me] = true
	local n = 0
	local function step() -- yield every few rows so big Tools never hitch a frame
		n += 1
		if n % 12 == 0 then task.wait() end
		return not entry.dead
	end
	for _, s in ipairs(SECTIONS) do
		if s[3] then entry.handle = findHandle(entry.tool) end
		local sec = createSection(entry, s[1], s[3])
		for _, d in ipairs(s[2]) do
			addRow(entry, sec, d)
			if not step() then threads[me] = nil return end
		end
	end
	entry.secAttr = createSection(entry, "Attributes")
	local names = {}
	for name in pairs(entry.tool:GetAttributes()) do names[#names + 1] = name end
	table.sort(names)
	for _, name in ipairs(names) do
		addAttrRow(entry, name)
		if not step() then threads[me] = nil return end
	end
	for name in pairs(entry.tool:GetAttributes()) do -- attributes added while we yielded
		if not entry.rowByKey["a:" .. name] then addAttrRow(entry, name) end
	end
	entry.secVal = createSection(entry, "Values")
	for _, c in ipairs(entry.tool:GetChildren()) do
		addValueRow(entry, c)
		if not step() then threads[me] = nil return end
	end
	entry.built = true
	applyRecord(entry)
	entry.stale = false
	touchFilter(entry)
	threads[me] = nil
end

local function isOurs(p)
	return p ~= nil and (p == player.Character or p == player:FindFirstChildOfClass("Backpack"))
end
local function paintBtn(e)
	local isSel = e == selected
	tween(e.btn, 0.12, {BackgroundColor3 = isSel and T.accent or T.white, BackgroundTransparency = isSel and 0.55 or 0.95})
end
local function addTool(tool)
	uidN += 1
	baseName[tool] = baseName[tool] or tool.Name
	local entry = {tool = tool, uid = uidN, bin = Bin(), rowByKey = {}, handleRows = {}, secList = {}, valRows = {}, locks = {}, orig = {},
		built = false, dead = false, stale = false, equipped = tool.Parent == player.Character}
	entries[tool] = entry
	entry.btn = button(sidebar, "", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0.95})
	corner(entry.btn)
	entry.lbl = label(entry.btn, "", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -16, 1, 0)})
	entry.bar = new("Frame", {Position = UDim2.fromOffset(4, 6), Size = UDim2.fromOffset(3, 14), BackgroundColor3 = T.accent, BorderSizePixel = 0}, entry.btn)
	corner(entry.bar, UDim.new(0.5, 0))
	on(entry.bin, entry.btn.MouseEnter, function() if selected ~= entry then tween(entry.btn, 0.12, {BackgroundTransparency = 0.88}) end end)
	on(entry.bin, entry.btn.MouseLeave, function() paintBtn(entry) end)
	entry.content = scroller(propHolder, {Size = UDim2.fromScale(1, 1), Visible = false})
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, entry.content)
	new("UIPadding", {PaddingRight = UDim.new(0, 6)}, entry.content)
	on(entry.bin, entry.btn.Activated, function() selectEntry(entry) end)
	on(entry.bin, tool.AncestryChanged, function()
		if entry.dead then return end
		if isOurs(tool.Parent) then
			entry.equipped = tool.Parent == player.Character
			refreshLabels()
		else
			removeEntry(tool) -- dropped, removed or destroyed
		end
	end)
	on(entry.bin, tool.AttributeChanged, function(name) onAttr(entry, name) end)
	on(entry.bin, tool.ChildAdded, function(c)
		if c.Name == "Handle" then bindHandle(entry)
		elseif entry.built and VALUE_TYPES[c.ClassName] then addValueRow(entry, c); touchFilter(entry) end
	end)
	on(entry.bin, tool.ChildRemoved, function(c)
		if c.Name == "Handle" then bindHandle(entry) end
		local row = entry.valRows[c]
		if row then entry.valRows[c] = nil; removeRow(entry, row); touchFilter(entry) end
	end)
	entry.thread = task.spawn(buildEntry, entry)
	if not selected then selectEntry(entry) else refreshLabels(); paintBtn(entry) end
	emptyLbl.Visible = false
end

function removeEntry(tool)
	local e = entries[tool]
	if not e then return end
	entries[tool] = nil
	e.dead = true
	cancel(e.thread)
	e.bin:clean()
	for _, r in pairs(e.rowByKey) do
		r.ui:clean(); r.sig:clean()
		polledRows[r] = nil
		activeLocks[r] = nil
		cancel(r.commitTh); cancel(r.flashTh)
		if pop.owner == r then hidePopup() end
	end
	syncLockLoop()
	local name = e.lbl.Text
	e.btn:Destroy(); e.content:Destroy()
	e.locks, e.orig, e.rowByKey, e.handleRows, e.secList = {}, {}, {}, {}, {}
	if selected == e then
		selected = nil
		local best
		for _, o in pairs(entries) do
			if not best or (o.equipped and not best.equipped) or (o.equipped == best.equipped and o.uid < best.uid) then best = o end
		end
		selectEntry(best)
	else
		refreshLabels()
	end
	emptyLbl.Visible = next(entries) == nil
	setStatus("Removed: " .. name)
end

function refreshLabels()
	local list = {}
	for _, e in pairs(entries) do list[#list + 1] = e end
	table.sort(list, function(a, b) return a.uid < b.uid end)
	local total, seen = {}, {}
	for _, e in ipairs(list) do local n = e.tool.Name; total[n] = (total[n] or 0) + 1 end
	for _, e in ipairs(list) do
		local n = e.tool.Name
		seen[n] = (seen[n] or 0) + 1
		local txt = total[n] > 1 and ("%s #%d"):format(n, seen[n]) or n -- duplicates are numbered, never merged
		if e.lbl.Text ~= txt then e.lbl.Text = txt end
		e.lbl.Font = e.equipped and T.bold or T.font
		e.bar.Visible = e.equipped
		e.btn.LayoutOrder = e.equipped and e.uid or 100000 + e.uid -- equipped Tool(s) on top
	end
end

function selectEntry(entry)
	hidePopup()
	selected = entry
	for _, e in pairs(entries) do
		local isSel = e == entry
		if e.content.Visible ~= isSel then e.content.Visible = isSel end
		paintBtn(e)
	end
	if entry and entry.built then
		if entry.stale and settings.autoUpdate then refreshAll(entry) end
		if entry.fv ~= filterVer then applyFilter(entry) end
	end
	refreshLabels()
end

-- Optional "revert on close": restore the first-seen value of everything we edited
function revertAll()
	for _, e in pairs(entries) do
		for key, o in pairs(e.orig) do
			if key:sub(1, 2) == "a:" then
				pcall(e.tool.SetAttribute, e.tool, key:sub(3), o.has and o.v or nil)
			else
				local row = e.rowByKey[key]
				if row and o.has then writeRaw(row, o.v) end
			end
		end
	end
end

----------------------------------------------------------------------
-- Toolbar + footer
----------------------------------------------------------------------
createToggle(bar, "Auto Update", 0, 0, 106, "autoUpdate", function()
	if settings.autoUpdate and selected and selected.built then refreshAll(selected) end
end)
createToggle(bar, "Remember Tool", 112, 0, 120, "rememberTools")
createToggle(bar, "Revert on Close", 238, 0, 124, "revertOnClose")
createAction(footer, "Forget saved", 0, 76, function()
	if not selected then return end
	local tool = selected.tool
	local rec = recordFor(selected, false)
	if rec then
		table.clear(rec.f)
		if toolsStore.data[baseName[tool]] == rec then toolsStore.data[baseName[tool]] = nil end
		weakRec[tool] = nil
		markDirty(toolsStore)
	end
	setStatus("Forgot saved settings for " .. tool.Name)
end)
createAction(footer, "Refresh", -80, 52, function() if selected and selected.built then refreshAll(selected) end end)
on(mainBin, searchBox:GetPropertyChangedSignal("Text"), function()
	cancel(searchTh)
	searchTh = later(0.12, function()
		searchTh = nil
		filterText = searchBox.Text:lower():match("^%s*(.-)%s*$")
		filterVer += 1
		hidePopup()
		if selected and selected.built then applyFilter(selected) end
	end)
end)

----------------------------------------------------------------------
-- Tool tracking: equipped (Character) + Backpack only
----------------------------------------------------------------------
local function considerTool(tool)
	if tool:IsA("Tool") and not entries[tool] then addTool(tool) end
end
local function bindContainers()
	containerBin:clean()
	local function bind(c)
		if not c then return end
		for _, ch in ipairs(c:GetChildren()) do considerTool(ch) end
		containerBin:add(c.ChildAdded:Connect(considerTool))
	end
	bind(player.Character)
	bind(player:FindFirstChildOfClass("Backpack"))
	local gone = {}
	for tool in pairs(entries) do if not isOurs(tool.Parent) then gone[#gone + 1] = tool end end
	for _, tool in ipairs(gone) do removeEntry(tool) end
	for _, e in pairs(entries) do e.equipped = e.tool.Parent == player.Character end
	refreshLabels()
end
on(mainBin, player.CharacterAdded, bindContainers)
on(mainBin, player.ChildAdded, function(c) if c:IsA("Backpack") then bindContainers() end end)
bindContainers()

local notes = {}
for _, s in ipairs({settingsStore, suggStore, toolsStore}) do if s.note then notes[#notes + 1] = s.note end end
if #notes > 0 then setStatus(table.concat(notes, "; "), "warn") end--!nonstrict
--[[
	Tool Properties Editor - single LocalScript (put in StarterPlayerScripts).
	Edits Tools that are equipped or in the local Backpack. Client-side only.
	Sections: utils / persistence / theme+components / window+animations / model / tracking.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SCHEMA, FOLDER, KEY, GUI_NAME = 1, "ToolPropertiesEditor", "__ToolPropsEditor", "ToolPropsEditorGui"

local player = Players.LocalPlayer
if not player then return end
local env = (getgenv and getgenv()) or _G

-- Single-instance guard: close any previous run first.
do
	local prev = env[KEY]
	if type(prev) == "table" and prev.cleanup then pcall(prev.cleanup) end
	env[KEY] = nil
end
local playerGui = player:WaitForChild("PlayerGui")
do
	local old = playerGui:FindFirstChild(GUI_NAME)
	if old then old:Destroy() end
end

----------------------------------------------------------------------
-- Utilities
----------------------------------------------------------------------
local function Bin()
	local list = {}
	return {
		add = function(_, c) list[#list + 1] = c; return c end,
		clean = function()
			for i = #list, 1, -1 do
				local c = list[i]; list[i] = nil
				pcall(c.Disconnect, c)
			end
		end,
	}
end
local function on(bin, sig, fn) return bin:add(sig:Connect(fn)) end

local threads = {} -- every pending/looping task, so cleanup can cancel them all
local function later(sec, fn)
	local th
	th = task.delay(sec, function() threads[th] = nil; fn() end)
	threads[th] = true
	return th
end
local function cancel(th)
	if th then threads[th] = nil; pcall(task.cancel, th) end
end

local function fmtNum(n) return string.format("%.9g", n) end
local function fmt(t, v)
	if t == "string" then return v
	elseif t == "number" then return fmtNum(v)
	elseif t == "Vector3" then return ("%s, %s, %s"):format(fmtNum(v.X), fmtNum(v.Y), fmtNum(v.Z))
	elseif t == "Vector2" then return ("%s, %s"):format(fmtNum(v.X), fmtNum(v.Y))
	elseif t == "Color3" then return "#" .. v:ToHex()
	elseif typeof(v) == "Instance" then return v:GetFullName()
	elseif typeof(v) == "EnumItem" then return v.Name end
	return tostring(v)
end
local function nums(text, n)
	local out = {}
	for tok in text:gmatch("[^,%s]+") do
		local x = tonumber(tok)
		if not x or x ~= x or math.abs(x) == math.huge then return nil end
		out[#out + 1] = x
	end
	if #out == n then return out end
	return nil
end
local function parse(t, text)
	if t == "string" then return text
	elseif t == "number" then
		local n = tonumber(text)
		if n and n == n and math.abs(n) < math.huge then return n end
	elseif t == "Vector3" then
		local a = nums(text, 3); if a then return Vector3.new(a[1], a[2], a[3]) end
	elseif t == "Vector2" then
		local a = nums(text, 2); if a then return Vector2.new(a[1], a[2]) end
	elseif t == "Color3" then
		local hex = text:match("^%s*#?(%x%x%x%x%x%x)%s*$")
		if hex then
			local ok, c = pcall(Color3.fromHex, hex)
			if ok then return c end
		end
		local a = nums(text, 3)
		if a then return Color3.fromRGB(math.clamp(a[1], 0, 255), math.clamp(a[2], 0, 255), math.clamp(a[3], 0, 255)) end
	end
	return nil
end
local function same(a, b)
	local ta = typeof(a)
	if ta ~= typeof(b) then return false end
	if ta == "number" then return math.abs(a - b) <= 1e-5 * math.max(1, math.abs(a), math.abs(b))
	elseif ta == "Vector3" or ta == "Vector2" then return (a - b).Magnitude <= 1e-4 * math.max(1, a.Magnitude)
	elseif ta == "Color3" then return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) <= 1e-4 end
	return a == b
end
local function enc(v)
	local t = typeof(v)
	if t == "string" or t == "number" or t == "boolean" then return v
	elseif t == "Vector3" then return {v.X, v.Y, v.Z}
	elseif t == "Vector2" then return {v.X, v.Y}
	elseif t == "Color3" then return {v.R, v.G, v.B}
	elseif t == "EnumItem" then return v.Name end
	return nil
end
local function isNums(e, n)
	if type(e) ~= "table" or #e ~= n then return false end
	for i = 1, n do if type(e[i]) ~= "number" then return false end end
	return true
end
local function dec(t, e, enumType)
	if t == "string" or t == "number" or t == "boolean" then return type(e) == t and e or nil
	elseif t == "Vector3" and isNums(e, 3) then return Vector3.new(e[1], e[2], e[3])
	elseif t == "Vector2" and isNums(e, 2) then return Vector2.new(e[1], e[2])
	elseif t == "Color3" and isNums(e, 3) then return Color3.new(e[1], e[2], e[3])
	elseif t == "EnumItem" and enumType and type(e) == "string" then
		local ok, item = pcall(function() return enumType[e] end)
		if ok and typeof(item) == "EnumItem" then return item end
	end
	return nil
end

----------------------------------------------------------------------
-- Persistence (safe writes, corruption/outdated handling, memory fallback)
----------------------------------------------------------------------
local fs = {ok = false, note = "Memory only (no filesystem API)"}
do
	local fns = {writefile, readfile, isfile, isfolder, makefolder}
	local all = true
	for i = 1, 5 do if type(fns[i]) ~= "function" then all = false end end
	if all and pcall(function()
		if not isfolder(FOLDER) then makefolder(FOLDER) end
		writefile(FOLDER .. "/.probe", "ok")
	end) then
		fs.ok = true
		fs.note = "Saving to workspace/" .. FOLDER
	end
end

local function flush(s)
	s.dirty = false
	if not fs.ok then return false end
	local okJ, json = pcall(HttpService.JSONEncode, HttpService, {v = SCHEMA, d = s.data})
	if not okJ then return false end
	local tmp = s.path .. ".tmp"
	-- No atomic rename API: write temp, verify read-back, keep previous as .bak, then replace.
	local good = pcall(writefile, tmp, json) and pcall(function() assert(readfile(tmp) == json) end)
	if not good then return false end
	pcall(function() if isfile(s.path) then writefile(s.path .. ".bak", readfile(s.path)) end end)
	return (pcall(writefile, s.path, json))
end
local function markDirty(s)
	s.dirty = true
	if not s.thread then
		s.thread = later(1.5, function() s.thread = nil; if s.dirty then flush(s) end end)
	end
end
local function newStore(file)
	local s = {path = FOLDER .. "/" .. file, dirty = false, data = nil, note = nil}
	local function tryLoad(path)
		if not fs.ok then return nil, "none" end
		local ok, raw = pcall(function() return isfile(path) and readfile(path) or nil end)
		if not ok or not raw then return nil, "missing" end
		local okD, obj = pcall(HttpService.JSONDecode, HttpService, raw)
		if not okD or type(obj) ~= "table" or type(obj.d) ~= "table" then return nil, "corrupt", raw end
		if obj.v ~= SCHEMA then return nil, "outdated", raw end
		return obj.d
	end
	local d, why, raw = tryLoad(s.path)
	if not d and (why == "corrupt" or why == "outdated") then
		pcall(writefile, s.path .. ".old", raw)
		d = tryLoad(s.path .. ".bak")
		s.note = ("%s was %s; %s"):format(file, why, d and "restored from backup" or "reset to defaults")
	end
	s.data = d or {}
	return s
end

local settingsStore, suggStore, toolsStore = newStore("settings.json"), newStore("suggestions.json"), newStore("tools.json")
local settings, suggData = settingsStore.data, suggStore.data
if type(settings.autoUpdate) ~= "boolean" then settings.autoUpdate = true end
if type(settings.rememberTools) ~= "boolean" then settings.rememberTools = false end
if type(settings.revertOnClose) ~= "boolean" then settings.revertOnClose = false end
if type(settings.collapsed) ~= "table" then settings.collapsed = {} end
if type(settings.pos) ~= "table" or type(settings.pos.x) ~= "number" or type(settings.pos.y) ~= "number" then settings.pos = nil end
for k, list in pairs(suggData) do
	local clean = {}
	if type(list) == "table" then
		for _, s in ipairs(list) do if type(s) == "string" and #clean < 8 then clean[#clean + 1] = s end end
	end
	suggData[k] = #clean > 0 and clean or nil
end

----------------------------------------------------------------------
-- State, forward declarations, cleanup
----------------------------------------------------------------------
local alive = true
local state = "expanded" -- expanded | minimized | animating | closed
local mainBin, containerBin, dragBin, lockBin = Bin(), Bin(), Bin(), Bin()
local entries = {}                                   -- [Tool] = entry
local activeLocks = {}                               -- [row] = lock (enforced every frame)
local selected, uidN, filterText, filterVer = nil, 0, "", 0
local baseName = setmetatable({}, {__mode = "k"})    -- first name seen per Tool instance
local weakRec = setmetatable({}, {__mode = "k"})     -- per-instance saved-settings record
local polledRows, pollTh, searchTh, hideTh, lockConnected = {}, nil, nil, nil, false
local gui

local revertAll, hidePopup, showPopup, setStatus, refreshRow, onChanged, commit, applyFilter
local refreshLabels, selectEntry, removeEntry, removeRow, bindHandle

local function cleanup()
	if state == "closed" then return end
	state, alive = "closed", false
	for th in pairs(threads) do pcall(task.cancel, th) end
	table.clear(threads)
	lockBin:clean(); table.clear(activeLocks)                          -- stop the lock loop, release every lock
	for _, e in pairs(entries) do e.locks = {} end
	if settings.revertOnClose and revertAll then pcall(revertAll) end   -- optional: undo temporary edits
	for _, s in ipairs({settingsStore, suggStore, toolsStore}) do if s.dirty then pcall(flush, s) end end
	mainBin:clean(); containerBin:clean(); dragBin:clean()
	for _, e in pairs(entries) do
		e.bin:clean()
		for _, r in pairs(e.rowByKey) do r.ui:clean(); r.sig:clean() end
	end
	if gui then pcall(function() gui:Destroy() end) end                 -- window + bubble live inside it
	table.clear(entries); table.clear(polledRows); table.clear(baseName); table.clear(weakRec)
	selected, gui, pollTh, searchTh, hideTh = nil, nil, nil, nil, nil
	if type(env[KEY]) == "table" and env[KEY].cleanup == cleanup then env[KEY] = nil end
end
env[KEY] = {cleanup = cleanup}

----------------------------------------------------------------------
-- Theme + components
----------------------------------------------------------------------
local T = {
	accent = Color3.fromRGB(94, 140, 255), text = Color3.fromRGB(235, 238, 245), sub = Color3.fromRGB(150, 156, 172),
	white = Color3.new(1, 1, 1), bg = Color3.fromRGB(16, 18, 26), gradTop = Color3.fromRGB(34, 38, 54),
	gradBot = Color3.fromRGB(14, 16, 24), danger = Color3.fromRGB(235, 80, 80),
	font = Enum.Font.GothamMedium, bold = Enum.Font.GothamBold,
	winW = 520, headerH = 38, bubble = 52, margin = 8, pad = 12, radius = 8, ctl = 4,
}
local QUAD, QUINT, OUT = Enum.EasingStyle.Quad, Enum.EasingStyle.Quint, Enum.EasingDirection.Out

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function merge(base, extra)
	if extra then for k, v in pairs(extra) do base[k] = v end end
	return base
end
local function tween(inst, dur, props, style, dir)
	local t = TweenService:Create(inst, TweenInfo.new(dur, style or QUAD, dir or OUT), props)
	t:Play()
	return t
end
local function corner(inst, r) return new("UICorner", {CornerRadius = r or UDim.new(0, T.ctl)}, inst) end
local function label(parent, text, props)
	return new("TextLabel", merge({BackgroundTransparency = 1, Font = T.font, TextSize = 13, TextColor3 = T.text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextTruncate = Enum.TextTruncate.AtEnd}, props), parent)
end
local function button(parent, text, props)
	return new("TextButton", merge({BackgroundColor3 = T.white, BackgroundTransparency = 0.92, BorderSizePixel = 0, Font = T.font,
		TextSize = 13, TextColor3 = T.text, Text = text, AutoButtonColor = false}, props), parent)
end
local function hoverFade(bin, btn, base, over) -- subtle background hover
	on(bin, btn.MouseEnter, function() tween(btn, 0.12, {BackgroundTransparency = over}) end)
	on(bin, btn.MouseLeave, function() tween(btn, 0.12, {BackgroundTransparency = base}) end)
end
local function scroller(parent, props)
	return new("ScrollingFrame", merge({BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.white, ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y}, props), parent)
end
local function createHeaderButton(parent, text, x, hoverColor)
	local b = button(parent, text, {Position = UDim2.new(1, x, 0, 5), Size = UDim2.fromOffset(28, 28), Font = T.bold, TextSize = 16})
	corner(b, UDim.new(0.5, 0))
	on(mainBin, b.MouseEnter, function() tween(b, 0.12, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.5}) end)
	on(mainBin, b.MouseLeave, function() tween(b, 0.12, {BackgroundColor3 = T.white, BackgroundTransparency = 0.92}) end)
	return b
end
local function createToggle(parent, text, x, y, w, key, onChange)
	local b = button(parent, "", {Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 22)})
	corner(b)
	hoverFade(mainBin, b, 0.92, 0.85)
	label(b, text, {Position = UDim2.fromOffset(7, 0), Size = UDim2.new(1, -36, 1, 0), TextSize = 11})
	local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(22, 12), BorderSizePixel = 0}, b)
	corner(track, UDim.new(0.5, 0))
	local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = T.white, BorderSizePixel = 0}, track)
	corner(knob, UDim.new(0.5, 0))
	local function paint(animate)
		local isOn = settings[key]
		local d = animate and 0.12 or 0
		tween(track, d, {BackgroundColor3 = isOn and T.accent or T.white, BackgroundTransparency = isOn and 0 or 0.8})
		tween(knob, d, {Position = UDim2.new(0, isOn and 12 or 2, 0.5, 0)})
	end
	on(mainBin, b.Activated, function()
		settings[key] = not settings[key]
		paint(true); markDirty(settingsStore)
		if onChange then onChange() end
	end)
	paint(false)
end
local function createAction(parent, text, x, w, fn)
	local b = new("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, x, 0, 0), Size = UDim2.fromOffset(w, 20),
		BackgroundTransparency = 1, Font = T.bold, TextSize = 11, TextColor3 = T.accent, Text = text, AutoButtonColor = false}, parent)
	on(mainBin, b.MouseEnter, function() tween(b, 0.12, {TextColor3 = T.white}) end)
	on(mainBin, b.MouseLeave, function() tween(b, 0.12, {TextColor3 = T.accent}) end)
	on(mainBin, b.Activated, fn)
	return b
end

----------------------------------------------------------------------
-- Window (ScreenGui, header, content CanvasGroup, bubble)
----------------------------------------------------------------------
gui = new("ScreenGui", {Name = GUI_NAME, ResetOnSpawn = false, DisplayOrder = 2147483647, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
-- Keep the GUI parented to PlayerGui (max DisplayOrder) even if something re-parents it.
on(mainBin, gui.AncestryChanged, function()
	if alive and gui and gui.Parent ~= playerGui then gui.Parent = playerGui end
end)

local function viewport()
	local s = gui.AbsoluteSize
	if s.X < 100 and workspace.CurrentCamera then return workspace.CurrentCamera.ViewportSize end
	return s
end
local function expandedSize()
	local vp = viewport()
	return Vector2.new(math.min(T.winW, vp.X - 2 * T.margin), math.clamp(440, 280, vp.Y - 2 * T.margin))
end
local function clampPos(x, y, w, h)
	local vp = viewport()
	return math.clamp(x, T.margin, math.max(T.margin, vp.X - w - T.margin)),
		math.clamp(y, T.margin, math.max(T.margin, vp.Y - h - T.margin))
end

local size0 = expandedSize()
local px, py = (viewport().X - size0.X) / 2, (viewport().Y - size0.Y) / 2
if settings.pos then px, py = settings.pos.x, settings.pos.y end
px, py = clampPos(px, py, size0.X, size0.Y)

local win = new("Frame", {Name = "MainWindow", Size = UDim2.fromOffset(size0.X, size0.Y), Position = UDim2.fromOffset(px, py),
	BackgroundColor3 = T.bg, BackgroundTransparency = 0.08, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 1}, gui)
local winCorner = new("UICorner", {CornerRadius = UDim.new(0, T.radius)}, win)
new("UIStroke", {Color = T.white, Transparency = 0.72, Thickness = 1}, win)
new("UIGradient", {Color = ColorSequence.new(T.gradTop, T.gradBot), Rotation = 90}, win)

local content = new("CanvasGroup", {Name = "Content", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2}, win)
local header = new("Frame", {Size = UDim2.new(1, 0, 0, T.headerH), BackgroundTransparency = 1}, content)
label(header, "Tool Properties Editor", {Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -90, 1, 0), Font = T.bold, TextSize = 15})
new("Frame", {Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.white, BackgroundTransparency = 0.92, BorderSizePixel = 0}, header)
local minBtn = createHeaderButton(header, "–", -(T.pad + 28 + 6 + 28), T.accent)
local closeBtn = createHeaderButton(header, "×", -(T.pad + 28), T.danger)
local body = new("Frame", {Position = UDim2.fromOffset(0, T.headerH), Size = UDim2.new(1, 0, 1, -T.headerH), BackgroundTransparency = 1}, content)

-- Minimized bubble: ring + dot in a CanvasGroup (fades), plus a hitbox button
local bubbleGroup = new("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 20}, win)
local ring = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1}, bubbleGroup)
corner(ring, UDim.new(0.5, 0))
new("UIStroke", {Color = T.accent, Thickness = 2}, ring)
local dot = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = T.white, BorderSizePixel = 0}, bubbleGroup)
corner(dot, UDim.new(0.5, 0))
local hitbox = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = false, Visible = false, ZIndex = 30}, win)

-- Left column: Tools list. Right column: search, options, properties, footer.
local sidebar = scroller(body, {Position = UDim2.fromOffset(T.pad, 8), Size = UDim2.new(0, 124, 1, -48)})
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, sidebar)
local fsLbl = label(body, fs.note, {Position = UDim2.new(0, T.pad, 1, -36), Size = UDim2.fromOffset(124, 30), TextSize = 10,
	TextColor3 = T.sub, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.None})
local right = new("Frame", {Position = UDim2.fromOffset(146, 0), Size = UDim2.new(1, -146 - T.pad, 1, 0), BackgroundTransparency = 1}, body)
local searchBox = new("TextBox", {Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.gradBot, BackgroundTransparency = 0.2,
	BorderSizePixel = 0, ClearTextOnFocus = false, Font = T.font, TextSize = 13, TextColor3 = T.text, PlaceholderText = "Search properties / attributes",
	PlaceholderColor3 = T.sub, Text = "", TextXAlignment = Enum.TextXAlignment.Left}, right)
corner(searchBox)
new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, searchBox)
local bar = new("Frame", {Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1}, right)
local propHolder = new("Frame", {Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66 - 28), BackgroundTransparency = 1, ClipsDescendants = true}, right)
local emptyLbl = label(propHolder, "No Tools equipped or in your Backpack.", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = T.sub})
local footer = new("Frame", {Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1}, right)
local statusLbl = label(footer, "", {Size = UDim2.new(1, -140, 1, 0), TextSize = 11, TextColor3 = T.sub})

function setStatus(text, kind)
	statusLbl.Text = text
	statusLbl.TextColor3 = kind == "err" and T.danger or kind == "warn" and T.text or T.sub
end

-- Shared popup (enum dropdown + remembered-value suggestions)
local pop = {items = {}, owner = nil}
pop.frame = scroller(content, {Visible = false, ZIndex = 100, BackgroundTransparency = 0.02, BackgroundColor3 = T.gradTop})
corner(pop.frame)
new("UIStroke", {Color = T.white, Transparency = 0.8, Thickness = 1}, pop.frame)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}, pop.frame)
local function popItem(i)
	local it = pop.items[i]
	if it then return it end
	local fr = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, ZIndex = 101, LayoutOrder = i}, pop.frame)
	local b = button(fr, "", {Size = UDim2.new(1, -22, 1, 0), BackgroundTransparency = 1, ZIndex = 102, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12})
	new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, b)
	local x = button(fr, "×", {Position = UDim2.new(1, -22, 0, 0), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, ZIndex = 102,
		TextColor3 = T.danger, Font = T.bold, TextSize = 15})
	it = {frame = fr, btn = b, x = x}
	hoverFade(mainBin, b, 1, 0.88)
	on(mainBin, b.Activated, function() if it.pick then it.pick() end end)
	on(mainBin, x.Activated, function() if it.remove then it.remove() end end)
	pop.items[i] = it
	return it
end
function hidePopup() pop.frame.Visible = false; pop.owner = nil end
function showPopup(anchor, list, owner)
	if #list == 0 then hidePopup() return end
	for i, d in ipairs(list) do
		local it = popItem(i)
		it.btn.Text, it.pick, it.remove = d.text, d.pick, d.remove
		it.btn.Size = d.remove and UDim2.new(1, -22, 1, 0) or UDim2.new(1, 0, 1, 0)
		it.x.Visible, it.frame.Visible = d.remove ~= nil, true
	end
	for i = #list + 1, #pop.items do
		local it = pop.items[i]
		it.frame.Visible, it.pick, it.remove = false, nil, nil
	end
	local wp, ap, as = win.AbsolutePosition, anchor.AbsolutePosition, anchor.AbsoluteSize
	local h = math.min(#list, 8) * 22
	local y = ap.Y - wp.Y + as.Y + 2
	if y + h > win.AbsoluteSize.Y then y = ap.Y - wp.Y - h - 2 end
	pop.frame.Position = UDim2.fromOffset(ap.X - wp.X, y)
	pop.frame.Size = UDim2.fromOffset(math.max(as.X, 170), h)
	pop.owner = owner
	pop.frame.Visible = true
end
local function scheduleHide(sec)
	cancel(hideTh)
	hideTh = later(sec, function() hideTh = nil; hidePopup() end)
end

----------------------------------------------------------------------
-- Dragging + minimize / restore animations
----------------------------------------------------------------------
local function savePos()
	settings.pos = {x = win.Position.X.Offset, y = win.Position.Y.Offset}
	markDirty(settingsStore)
end
local function makeDraggable(handle, onClick)
	on(mainBin, handle.InputBegan, function(input)
		local ut = input.UserInputType
		if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.Touch then return end
		if state ~= "expanded" and state ~= "minimized" then return end
		dragBin:clean()
		local start, origin, moved = input.Position, win.Position, false
		dragBin:add(UIS.InputChanged:Connect(function(i)
			if i ~= input and i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local d = i.Position - start
			if not moved and Vector2.new(d.X, d.Y).Magnitude < 4 then return end -- click vs drag threshold
			moved = true
			local sz = win.AbsoluteSize
			local x, y = clampPos(origin.X.Offset + d.X, origin.Y.Offset + d.Y, sz.X, sz.Y)
			win.Position = UDim2.fromOffset(x, y)
		end))
		dragBin:add(input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then return end
			dragBin:clean()
			if moved then savePos() elseif onClick then onClick() end
		end))
	end)
end

local function minimizeWindow()
	if state ~= "expanded" then return end
	state = "animating"
	hidePopup()
	task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		tween(content, 0.16, {GroupTransparency = 1})
		task.wait(0.08)
		tween(win, 0.36, {Size = UDim2.fromOffset(T.bubble, T.bubble), BackgroundTransparency = 0.10}, QUINT)
		tween(winCorner, 0.36, {CornerRadius = UDim.new(0.5, 0)}, QUINT)
		task.wait(0.18) -- 0.42s after the click
		content.Visible = false
		hitbox.Visible, hitbox.Active = true, true
		state = "minimized"
		tween(bubbleGroup, 0.20, {GroupTransparency = 0})
		savePos()
		threads[me] = nil
	end)
end
local function restoreWindow()
	if state ~= "minimized" then return end
	state = "animating"
	hitbox.Active = false
	task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		tween(bubbleGroup, 0.12, {GroupTransparency = 1})
		local sz = expandedSize()
		local x, y = clampPos(win.Position.X.Offset, win.Position.Y.Offset, sz.X, sz.Y)
		content.Visible = true
		tween(win, 0.36, {Size = UDim2.fromOffset(sz.X, sz.Y), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 0.08}, QUINT)
		tween(winCorner, 0.36, {CornerRadius = UDim.new(0, T.radius)}, QUINT)
		task.wait(0.14)
		tween(content, 0.22, {GroupTransparency = 0})
		task.wait(0.24) -- 0.38s total
		hitbox.Visible = false
		state = "expanded"
		savePos()
		threads[me] = nil
	end)
end
makeDraggable(header, nil)
makeDraggable(hitbox, restoreWindow)
on(mainBin, minBtn.Activated, minimizeWindow)
on(mainBin, closeBtn.Activated, cleanup)
if typeof(script) == "Instance" then pcall(function() on(mainBin, script.Destroying, cleanup) end) end

----------------------------------------------------------------------
-- Model: read/write, remembered values, saved Tool records
----------------------------------------------------------------------
local SUPPORTED = {string = true, number = true, boolean = true, Vector3 = true, Vector2 = true, Color3 = true, EnumItem = true}
local SUGGESTABLE = {string = true, number = true, Vector3 = true, Vector2 = true, Color3 = true}
local SHORT = {boolean = "bool"}

local SECTIONS = {
	{"Data", {
		{n = "Name", t = "string"}, {n = "ClassName", t = "string", ro = true}, {n = "Parent", t = "Instance", ro = true},
		{n = "Archivable", t = "boolean"},
	}},
	{"Behavior", {
		{n = "Enabled", t = "boolean"}, {n = "CanBeDropped", t = "boolean"}, {n = "RequiresHandle", t = "boolean"},
		{n = "ManualActivationOnly", t = "boolean"}, {n = "ToolTip", t = "string"}, {n = "TextureId", t = "string"},
	}},
	{"Grip", {
		{n = "Grip", t = "CFrame"}, {n = "GripPos", t = "Vector3"}, {n = "GripForward", t = "Vector3"},
		{n = "GripRight", t = "Vector3"}, {n = "GripUp", t = "Vector3"},
	}},
	{"Handle", {
		{n = "Size", t = "Vector3"}, {n = "Color", t = "Color3"}, {n = "Material", t = "EnumItem", e = Enum.Material},
		{n = "Transparency", t = "number"}, {n = "Anchored", t = "boolean"}, {n = "CanCollide", t = "boolean"},
		{n = "Massless", t = "boolean"}, {n = "AssemblyMass", t = "number", ro = true},
	}, true},
}

local function readRow(row)
	local inst = row.inst
	if not inst then return nil, false end
	if row.kind == "attr" then return inst:GetAttribute(row.name), true end
	local ok, v = pcall(function() return inst[row.name] end)
	return v, ok
end
local function writeRaw(row, v)
	local inst = row.inst
	if not inst then return false, "unavailable" end
	if row.kind == "attr" then return pcall(inst.SetAttribute, inst, row.name, v) end
	return pcall(function() inst[row.name] = v end)
end

local function pushSuggestion(row, text)
	if text == "" or #text > 120 then return end
	local k = row.type .. "|" .. row.title
	local list = suggData[k]
	if not list then list = {}; suggData[k] = list end
	local i = table.find(list, text)
	if i then
		if i == 1 then return end
		table.remove(list, i)
	end
	table.insert(list, 1, text)
	if #list > 8 then table.remove(list) end
	markDirty(suggStore)
end

-- Saved per-Tool records, keyed by the Tool's original name. Used only when that name is unique among
-- tracked Tools, or when this exact instance already owns a record this session.
local function recordFor(entry, create)
	local tool = entry.tool
	local rec = weakRec[tool]
	if rec then return rec end
	local name, n = baseName[tool], 0
	for _, e in pairs(entries) do if baseName[e.tool] == name then n += 1 end end
	if n > 1 then
		if create then rec = {f = {}}; weakRec[tool] = rec end
		return rec, true
	end
	rec = toolsStore.data[name]
	if type(rec) ~= "table" or type(rec.f) ~= "table" then
		if not create then return nil end
		rec = {f = {}}
		toolsStore.data[name] = rec
	end
	weakRec[tool] = rec
	return rec
end
local function rememberField(row, v)
	if not settings.rememberTools then return end
	local e = enc(v)
	if e == nil then return end
	local rec = recordFor(row.entry, true)
	if not rec then return end
	rec.f[row.key] = {t = row.type, v = e, lock = row.entry.locks[row.key] ~= nil or nil}
	markDirty(toolsStore)
end
local function noteOrig(row)
	local o = row.entry.orig
	if o[row.key] then return end
	local v, ok = readRow(row)
	o[row.key] = {has = ok and v ~= nil, v = v}
end

----------------------------------------------------------------------
-- Rows: slot (lock / RO / N/A), locks, editors, refresh, commit
----------------------------------------------------------------------
local function paintSlot(row)
	local s = row.slot
	if row.ro then
		s.Text, s.TextColor3, s.BackgroundTransparency = "RO", T.sub, 1
	elseif row.unsup then
		s.Text, s.TextColor3, s.BackgroundTransparency = "N/A", T.sub, 1
	else
		local lk = row.entry.locks[row.key] ~= nil
		s.Text, s.TextColor3 = lk and "LOCKED" or "Lock", lk and T.white or T.sub
		tween(s, 0.12, {BackgroundColor3 = lk and T.accent or T.white, BackgroundTransparency = lk and 0.1 or 0.9})
	end
end
local function setRO(row)
	row.ro = true
	row.entry.locks[row.key] = nil
	activeLocks[row] = nil
	for _, b in ipairs(row.boxes or {}) do b.TextEditable = false end
	paintSlot(row)
end
local function failRow(row, err)
	local msg = tostring(err)
	if #msg > 100 then msg = msg:sub(1, 100) .. "..." end
	row.stroke.Transparency = 0
	cancel(row.flashTh)
	row.flashTh = later(1.2, function()
		row.flashTh = nil
		if row.stroke.Parent then tween(row.stroke, 0.2, {Transparency = 1}) end
	end)
	local l = msg:lower()
	if l:find("cannot be assigned", 1, true) or l:find("read only", 1, true) or l:find("readonly", 1, true) or l:find("lacking capability", 1, true) then
		setRO(row)
		msg ..= " (marked read-only)"
	end
	setStatus(("Edit failed on %s: %s"):format(row.name, msg), "err")
end

function refreshRow(row, force)
	local v, ok = readRow(row)
	if not ok or v == nil then return end
	if not force and row.cur ~= nil and same(v, row.cur) then return end -- only touch UI when changed
	if row.setDisplay then row.setDisplay(v) end
end

-- LOCK LOOP: while any lock exists, one shared enforcer runs every frame (PreRender + Heartbeat) and
-- immediately on each change signal. It reads the live value and writes the locked value back whenever
-- it differs. It disconnects itself as soon as the last lock is released.
local function enforceRow(row, lock)
	if row.reasserting or not row.inst then return end
	local v, ok = readRow(row)
	if not ok then return end
	if v ~= nil and v == lock.value then lock.fails = 0 return end -- exact match; lock.value is a read-back so no float drift
	row.reasserting = true
	local w, err = writeRaw(row, lock.value)
	row.reasserting = false
	if w then
		lock.fails = 0
		lock.hits += 1
		local now = os.clock()
		if now - lock.shown > 0.25 then
			lock.shown = now
			setStatus(("Holding %s = %s  (reverted x%d)"):format(row.title, fmt(row.type, lock.value), lock.hits))
		end
	else
		lock.fails += 1 -- a write that keeps erroring means the property can't be held; stop after 5 straight failures
		if lock.fails >= 5 then row.entry.locks[row.key] = nil; activeLocks[row] = nil; paintSlot(row); setStatus(("Lock dropped on %s: %s"):format(row.name, tostring(err)), "err") end
	end
end
local function enforceAll()
	for row, lock in pairs(activeLocks) do pcall(enforceRow, row, lock) end
end
local function syncLockLoop()
	if next(activeLocks) then
		if not lockConnected then
			lockConnected = true
			lockBin:add(RunService.RenderStepped:Connect(enforceAll))
			lockBin:add(RunService.Stepped:Connect(enforceAll))
			lockBin:add(RunService.Heartbeat:Connect(enforceAll))
		end
	elseif lockConnected then
		lockConnected = false
		lockBin:clean()
	end
end
local function releaseLock(row)
	local entry = row.entry
	entry.locks[row.key] = nil
	activeLocks[row] = nil
	syncLockLoop()
	paintSlot(row)
	local rec = settings.rememberTools and recordFor(entry, false)
	if rec and rec.f[row.key] then rec.f[row.key].lock = nil; markDirty(toolsStore) end
end
local function setLock(row, on)
	if row.ro or row.unsup then return end
	if on then
		local live, ok = readRow(row)
		if not ok or live == nil then return end
		noteOrig(row)
		local lock = {value = live, fails = 0, hits = 0, shown = 0}
		row.entry.locks[row.key] = lock
		activeLocks[row] = lock
		syncLockLoop()
		paintSlot(row)
		rememberField(row, live)
		setStatus(("Locked %s = %s"):format(row.title, fmt(row.type, live)))
	else
		releaseLock(row)
	end
end

function commit(row, v, fromUser)
	local entry = row.entry
	if row.ro or row.unsup then return false end
	noteOrig(row)
	local lock = entry.locks[row.key]
	if lock then lock.value = v end -- the new value becomes the locked one
	local ok, err = writeRaw(row, v)
	local live = readRow(row)
	if not ok then
		if lock and live ~= nil then lock.value = live end
		failRow(row, err)
		refreshRow(row, true)
		return false
	end
	if live ~= nil then
		if lock then lock.value = live end -- hold the value Roblox actually accepted (clamping etc.)
		refreshRow(row, true)
	end
	if fromUser then
		if SUGGESTABLE[row.type] then pushSuggestion(row, fmt(row.type, v)) end
		rememberField(row, live ~= nil and live or v)
	end
	return true
end

function onChanged(row)
	local entry = row.entry
	if entry.dead then return end
	local lock = entry.locks[row.key]
	if lock then enforceRow(row, lock) end -- instant revert; the frame loop is the backstop
	local v, ok = readRow(row)
	if not ok then return end
	if row.kind == "prop" and row.name == "Name" and not row.target then refreshLabels() end
	if v == nil or lock then return end
	if not settings.autoUpdate or entry ~= selected then entry.stale = true return end
	refreshRow(row)
end

local function ensurePoll() -- lightweight 1s fallback, only for properties without a usable change signal
	if pollTh then return end
	pollTh = task.spawn(function()
		local me = coroutine.running()
		threads[me] = true
		while alive and next(polledRows) do
			task.wait(1)
			for row in pairs(polledRows) do if not row.entry.dead then onChanged(row) end end
		end
		threads[me], pollTh = nil, nil
	end)
end
local function connectRow(row)
	local inst = row.inst
	if not inst or row.kind ~= "prop" then return end
	local ok, sig = pcall(inst.GetPropertyChangedSignal, inst, row.name)
	if ok then
		row.sig:add(sig:Connect(function() onChanged(row) end))
	else
		polledRows[row] = true
		ensurePoll()
	end
end

-- Remembered-value suggestions
local function showSuggestions(row, anchor, filterStr)
	local k = row.type .. "|" .. row.title
	local list = suggData[k]
	if not list then hidePopup() return end
	local f = filterStr and filterStr ~= "" and filterStr:lower() or nil
	local out = {}
	for _, s in ipairs(list) do
		if not f or s:lower():find(f, 1, true) then
			out[#out + 1] = {
				text = s,
				pick = function()
					cancel(row.commitTh); row.commitTh = nil
					hidePopup()
					if row.applyText then row.applyText(s) end
				end,
				remove = function()
					local i = table.find(list, s)
					if i then table.remove(list, i) end
					if #list == 0 then suggData[k] = nil end
					markDirty(suggStore)
					showSuggestions(row, anchor, filterStr)
					scheduleHide(3)
				end,
			}
		end
	end
	showPopup(anchor, out, row)
end

local function buildEditor(row, holder)
	local t = row.type
	holder.ClipsDescendants = true
	if row.ro or row.unsup then
		local l = label(holder, "", {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -10, 1, 0), TextColor3 = T.sub, TextSize = 12})
		row.setDisplay = function(v)
			row.cur = v
			local s = fmt(t, v)
			if l.Text ~= s then l.Text = s end
		end
	elseif t == "boolean" then
		local b = button(holder, "", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextSize = 12, Font = T.bold})
		on(row.ui, b.Activated, function() if not row.ro and row.cur ~= nil then commit(row, not row.cur, true) end end)
		row.setDisplay = function(v)
			row.cur = v
			b.Text = tostring(v)
			tween(b, 0.1, {TextColor3 = v and T.accent or T.sub})
		end
	elseif t == "EnumItem" then
		local b = button(holder, "", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12})
		new("UIPadding", {PaddingLeft = UDim.new(0, 6)}, b)
		on(row.ui, b.Activated, function()
			if row.ro then return end
			if pop.owner == row then hidePopup() return end
			local list = {}
			for _, item in ipairs(row.enum:GetEnumItems()) do
				list[#list + 1] = {text = item.Name, pick = function() hidePopup(); commit(row, item, true) end}
			end
			showPopup(holder, list, row)
		end)
		row.setDisplay = function(v)
			row.cur = v
			if b.Text ~= v.Name then b.Text = v.Name end
		end
	else
		local n = (t == "Vector3" and 3) or (t == "Vector2" and 2) or 1
		local boxes, sw, x0 = {}, nil, 0
		row.boxes = boxes
		if t == "Color3" then
			sw = new("Frame", {Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(14, 10), BorderSizePixel = 0}, holder)
			corner(sw, UDim.new(0, 3))
			x0 = 22
		end
		local function textNow()
			local parts = {}
			for i, b in ipairs(boxes) do parts[i] = b.Text end
			return table.concat(parts, ", ")
		end
		local function anyFocused()
			for _, b in ipairs(boxes) do if b:IsFocused() then return true end end
			return false
		end
		row.setDisplay = function(v)
			row.cur = v
			if sw then sw.BackgroundColor3 = v end
			if anyFocused() then return end -- never overwrite what the user is typing
			if n == 1 then
				local s = fmt(t, v)
				if boxes[1].Text ~= s then boxes[1].Text = s end
			else
				local c = t == "Vector3" and {v.X, v.Y, v.Z} or {v.X, v.Y}
				for i, b in ipairs(boxes) do
					local s = fmtNum(c[i])
					if b.Text ~= s then b.Text = s end
				end
			end
		end
		local function redraw() if row.cur ~= nil then row.setDisplay(row.cur) end end
		local function submit()
			local v = parse(t, textNow())
			if v == nil then failRow(row, "invalid " .. t .. " value"); redraw() return end
			if row.cur ~= nil and same(v, row.cur) then redraw() return end
			commit(row, v, true)
		end
		row.applyText = function(s)
			for _, b in ipairs(boxes) do if b:IsFocused() then b:ReleaseFocus() end end
			local v = parse(t, s)
			if v ~= nil and not (row.cur ~= nil and same(v, row.cur)) then commit(row, v, true) else redraw() end
		end
		local function onBlur(enter)
			scheduleHide(0.2)
			if row.ro then redraw() return end
			local function go()
				row.commitTh = nil
				if not anyFocused() then submit() end
			end
			cancel(row.commitTh)
			if enter then row.commitTh = nil; go() else row.commitTh = later(0.12, go) end -- lets a suggestion click win
		end
		for i = 1, n do
			local b = new("TextBox", {BackgroundTransparency = 1, ClearTextOnFocus = false, Font = T.font, TextSize = 12, TextColor3 = T.text,
				TextXAlignment = Enum.TextXAlignment.Left, Text = "",
				Position = n == 1 and UDim2.fromOffset(x0 + 6, 0) or UDim2.new((i - 1) / n, 5, 0, 0),
				Size = n == 1 and UDim2.new(1, -(x0 + 10), 1, 0) or UDim2.new(1 / n, -7, 1, 0)}, holder)
			boxes[i] = b
			on(row.ui, b.Focused, function()
				cancel(hideTh)
				if SUGGESTABLE[t] then showSuggestions(row, holder) end
			end)
			on(row.ui, b.FocusLost, onBlur)
			if n == 1 then
				on(row.ui, b:GetPropertyChangedSignal("Text"), function()
					if b:IsFocused() then showSuggestions(row, holder, b.Text) end
				end)
			end
		end
	end
end

local function addRow(entry, sec, d)
	local row = {
		entry = entry, sec = sec, name = d.n, title = d.title or d.n, kind = d.kind or "prop", type = d.t, enum = d.e, ro = d.ro or false,
		target = sec.handle and "Handle" or nil, unsup = not SUPPORTED[d.t], ui = Bin(), sig = Bin(), available = true,
	}
	row.key = d.key or ((row.kind == "attr" and "a:" or "p:") .. (row.target and "Handle." or "") .. row.name)
	row.inst = d.inst or (row.target and entry.handle or entry.tool)
	if row.target and not row.inst then row.available = false end
	if row.inst then
		local _, ok = readRow(row)
		if not ok then return nil end -- unreadable here: not shown
	end
	local typeText = d.e and tostring(d.e) or SHORT[d.t] or d.t
	row.lname, row.ltype = row.title:lower(), typeText:lower()
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = T.white, BackgroundTransparency = 0.95, BorderSizePixel = 0,
		Visible = false, LayoutOrder = sec.order * 10000 + #sec.rows + 1}, entry.content)
	corner(f)
	row.frame = f
	label(f, row.title, {Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 100, 1, 0)})
	local holder = new("Frame", {Position = UDim2.fromOffset(112, 3), Size = UDim2.new(1, -206, 0, 18), BackgroundColor3 = T.gradBot,
		BackgroundTransparency = 0.25, BorderSizePixel = 0}, f)
	corner(holder)
	row.stroke = new("UIStroke", {Color = T.danger, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, holder)
	row.typeLbl = label(f, typeText, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -46, 0, 0), Size = UDim2.new(0, 44, 1, 0),
		TextSize = 10, TextColor3 = T.sub})
	row.slot = button(f, "", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(40, 18),
		TextSize = 10, Font = T.bold})
	corner(row.slot)
	on(row.ui, row.slot.Activated, function()
		if row.ro or row.unsup then return end
		setLock(row, entry.locks[row.key] == nil)
	end)
	on(row.ui, row.slot.MouseEnter, function()
		if not row.ro and not row.unsup and not entry.locks[row.key] then tween(row.slot, 0.12, {BackgroundTransparency = 0.8}) end
	end)
	on(row.ui, row.slot.MouseLeave, function() paintSlot(row) end)
	buildEditor(row, holder)
	paintSlot(row)
	sec.rows[#sec.rows + 1] = row
	entry.rowByKey[row.key] = row
	if row.target then entry.handleRows[#entry.handleRows + 1] = row end
	connectRow(row)
	if row.inst then refreshRow(row, true) end
	return row
end

----------------------------------------------------------------------
-- Sections, filtering, entries
----------------------------------------------------------------------
local function createSection(entry, name, handle)
	local order = #entry.secList + 1
	local sec = {name = name, order = order, rows = {}, handle = handle, expanded = not settings.collapsed[name]}
	sec.header = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		LayoutOrder = order * 10000, Visible = false}, entry.content)
	local lbl = label(sec.header, "", {Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -6, 1, 0), Font = T.bold, TextSize = 12,
		TextColor3 = T.sub, RichText = true})
	local function paint()
		lbl.Text = ('<font color="#5E8CFF">%s</font>  %s'):format(sec.expanded and "-" or "+", name)
	end
	paint()
	on(entry.bin, sec.header.Activated, function()
		sec.expanded = not sec.expanded
		settings.collapsed[name] = (not sec.expanded) or nil
		paint(); markDirty(settingsStore); hidePopup()
		applyFilter(entry)
	end)
	entry.secList[order] = sec
	return sec
end

function applyFilter(entry)
	entry.fv = filterVer
	local q = filterText
	for _, sec in ipairs(entry.secList) do
		local any = false
		for _, row in ipairs(sec.rows) do
			local match = row.available and (q == "" or row.lname:find(q, 1, true) ~= nil or row.ltype:find(q, 1, true) ~= nil)
			any = any or match
			local show = match and (q ~= "" or sec.expanded) or false
			if row.frame.Visible ~= show then row.frame.Visible = show end
		end
		if sec.header.Visible ~= any then sec.header.Visible = any end
	end
end
local function touchFilter(entry)
	if entry == selected then applyFilter(entry) else entry.fv = nil end
end
local function refreshAll(entry)
	entry.stale = false
	for _, sec in ipairs(entry.secList) do
		for _, row in ipairs(sec.rows) do if row.available then refreshRow(row) end end
	end
end

local function addAttrRow(entry, name)
	local v = entry.tool:GetAttribute(name)
	if v == nil or not entry.secAttr then return nil end
	return addRow(entry, entry.secAttr, {n = name, t = typeof(v), kind = "attr"})
end
local VALUE_TYPES = {BoolValue = "boolean", IntValue = "number", NumberValue = "number", StringValue = "string",
	Color3Value = "Color3", Vector3Value = "Vector3", CFrameValue = "CFrame", ObjectValue = "Instance"}
local function addValueRow(entry, child) -- ValueObjects (IntValue, NumberValue, ...) directly inside the Tool
	local t = VALUE_TYPES[child.ClassName]
	if not t or not entry.secVal or entry.valRows[child] then return nil end
	local key, n = "v:" .. child.Name, 1
	while entry.rowByKey[key] do n += 1; key = ("v:%s #%d"):format(child.Name, n) end
	local row = addRow(entry, entry.secVal, {n = "Value", t = t, title = child.Name, inst = child, key = key, ro = t == "Instance"})
	if row then entry.valRows[child] = row end
	return row
end
function removeRow(entry, row)
	row.ui:clean(); row.sig:clean()
	polledRows[row] = nil
	entry.locks[row.key] = nil
	if activeLocks[row] then activeLocks[row] = nil; syncLockLoop() end
	entry.rowByKey[row.key] = nil
	local i = table.find(row.sec.rows, row)
	if i then table.remove(row.sec.rows, i) end
	if pop.owner == row then hidePopup() end
	cancel(row.commitTh); cancel(row.flashTh)
	row.frame:Destroy()
end
local function onAttr(entry, name)
	if entry.dead or not entry.built then return end
	local key, v = "a:" .. name, entry.tool:GetAttribute(name)
	local row = entry.rowByKey[key]
	local locked = entry.locks[key] ~= nil
	if row then
		if locked or (v ~= nil and typeof(v) == row.type) then onChanged(row) return end
		removeRow(entry, row) -- removed, or its type changed: rebuild below if still present
	end
	if v ~= nil then
		addAttrRow(entry, name)
		local sec = entry.secAttr
		table.sort(sec.rows, function(a, b) return a.name < b.name end)
		for i, r in ipairs(sec.rows) do r.frame.LayoutOrder = sec.order * 10000 + i end
	end
	touchFilter(entry)
end

local function findHandle(tool)
	local h = tool:FindFirstChild("Handle")
	if h and h:IsA("BasePart") then return h end
	return nil
end
function bindHandle(entry)
	if entry.dead then return end
	local h = findHandle(entry.tool)
	if h == entry.handle then return end
	entry.handle = h
	for _, row in ipairs(entry.handleRows) do
		row.sig:clean()
		polledRows[row] = nil
		row.inst, row.available, row.cur = h, h ~= nil, nil
		if h then
			connectRow(row)
			refreshRow(row, true)
		end
	end
	touchFilter(entry)
end

local function applyRecord(entry)
	if not settings.rememberTools then return end
	local rec, ambiguous = recordFor(entry, false)
	if not rec then
		if ambiguous then setStatus(("Duplicate Tool name '%s': saved settings not applied"):format(baseName[entry.tool]), "warn") end
		return
	end
	local count = 0
	for key, s in pairs(rec.f) do
		if type(s) == "table" then
			local row = entry.rowByKey[key]
			if row then
				if not row.ro and not row.unsup and s.t == row.type then
					local v = dec(row.type, s.v, row.enum)
					if v ~= nil then
						local live = readRow(row)
						if live == nil or not same(v, live) then commit(row, v, false) end
						count += 1
						if s.lock then setLock(row, true) end
					end
				end
			elseif key:sub(1, 2) == "a:" then -- attribute missing on this Tool: restore it
				local v = dec(s.t, s.v)
				if v ~= nil and pcall(entry.tool.SetAttribute, entry.tool, key:sub(3), v) then count += 1 end
			end
		end
	end
	if count > 0 then setStatus(("Applied %d saved value(s) to %s"):format(count, entry.tool.Name)) end
end

local function buildEntry(entry)
	local me = coroutine.running()
	threads[me] = true
	local n = 0
	local function step() -- yield every few rows so big Tools never hitch a frame
		n += 1
		if n % 12 == 0 then task.wait() end
		return not entry.dead
	end
	for _, s in ipairs(SECTIONS) do
		if s[3] then entry.handle = findHandle(entry.tool) end
		local sec = createSection(entry, s[1], s[3])
		for _, d in ipairs(s[2]) do
			addRow(entry, sec, d)
			if not step() then threads[me] = nil return end
		end
	end
	entry.secAttr = createSection(entry, "Attributes")
	local names = {}
	for name in pairs(entry.tool:GetAttributes()) do names[#names + 1] = name end
	table.sort(names)
	for _, name in ipairs(names) do
		addAttrRow(entry, name)
		if not step() then threads[me] = nil return end
	end
	for name in pairs(entry.tool:GetAttributes()) do -- attributes added while we yielded
		if not entry.rowByKey["a:" .. name] then addAttrRow(entry, name) end
	end
	entry.secVal = createSection(entry, "Values")
	for _, c in ipairs(entry.tool:GetChildren()) do
		addValueRow(entry, c)
		if not step() then threads[me] = nil return end
	end
	entry.built = true
	applyRecord(entry)
	entry.stale = false
	touchFilter(entry)
	threads[me] = nil
end

local function isOurs(p)
	return p ~= nil and (p == player.Character or p == player:FindFirstChildOfClass("Backpack"))
end
local function paintBtn(e)
	local isSel = e == selected
	tween(e.btn, 0.12, {BackgroundColor3 = isSel and T.accent or T.white, BackgroundTransparency = isSel and 0.55 or 0.95})
end
local function addTool(tool)
	uidN += 1
	baseName[tool] = baseName[tool] or tool.Name
	local entry = {tool = tool, uid = uidN, bin = Bin(), rowByKey = {}, handleRows = {}, secList = {}, valRows = {}, locks = {}, orig = {},
		built = false, dead = false, stale = false, equipped = tool.Parent == player.Character}
	entries[tool] = entry
	entry.btn = button(sidebar, "", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0.95})
	corner(entry.btn)
	entry.lbl = label(entry.btn, "", {Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -16, 1, 0)})
	entry.bar = new("Frame", {Position = UDim2.fromOffset(4, 6), Size = UDim2.fromOffset(3, 14), BackgroundColor3 = T.accent, BorderSizePixel = 0}, entry.btn)
	corner(entry.bar, UDim.new(0.5, 0))
	on(entry.bin, entry.btn.MouseEnter, function() if selected ~= entry then tween(entry.btn, 0.12, {BackgroundTransparency = 0.88}) end end)
	on(entry.bin, entry.btn.MouseLeave, function() paintBtn(entry) end)
	entry.content = scroller(propHolder, {Size = UDim2.fromScale(1, 1), Visible = false})
	new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, entry.content)
	new("UIPadding", {PaddingRight = UDim.new(0, 6)}, entry.content)
	on(entry.bin, entry.btn.Activated, function() selectEntry(entry) end)
	on(entry.bin, tool.AncestryChanged, function()
		if entry.dead then return end
		if isOurs(tool.Parent) then
			entry.equipped = tool.Parent == player.Character
			refreshLabels()
		else
			removeEntry(tool) -- dropped, removed or destroyed
		end
	end)
	on(entry.bin, tool.AttributeChanged, function(name) onAttr(entry, name) end)
	on(entry.bin, tool.ChildAdded, function(c)
		if c.Name == "Handle" then bindHandle(entry)
		elseif entry.built and VALUE_TYPES[c.ClassName] then addValueRow(entry, c); touchFilter(entry) end
	end)
	on(entry.bin, tool.ChildRemoved, function(c)
		if c.Name == "Handle" then bindHandle(entry) end
		local row = entry.valRows[c]
		if row then entry.valRows[c] = nil; removeRow(entry, row); touchFilter(entry) end
	end)
	entry.thread = task.spawn(buildEntry, entry)
	if not selected then selectEntry(entry) else refreshLabels(); paintBtn(entry) end
	emptyLbl.Visible = false
end

function removeEntry(tool)
	local e = entries[tool]
	if not e then return end
	entries[tool] = nil
	e.dead = true
	cancel(e.thread)
	e.bin:clean()
	for _, r in pairs(e.rowByKey) do
		r.ui:clean(); r.sig:clean()
		polledRows[r] = nil
		activeLocks[r] = nil
		cancel(r.commitTh); cancel(r.flashTh)
		if pop.owner == r then hidePopup() end
	end
	syncLockLoop()
	local name = e.lbl.Text
	e.btn:Destroy(); e.content:Destroy()
	e.locks, e.orig, e.rowByKey, e.handleRows, e.secList = {}, {}, {}, {}, {}
	if selected == e then
		selected = nil
		local best
		for _, o in pairs(entries) do
			if not best or (o.equipped and not best.equipped) or (o.equipped == best.equipped and o.uid < best.uid) then best = o end
		end
		selectEntry(best)
	else
		refreshLabels()
	end
	emptyLbl.Visible = next(entries) == nil
	setStatus("Removed: " .. name)
end

function refreshLabels()
	local list = {}
	for _, e in pairs(entries) do list[#list + 1] = e end
	table.sort(list, function(a, b) return a.uid < b.uid end)
	local total, seen = {}, {}
	for _, e in ipairs(list) do local n = e.tool.Name; total[n] = (total[n] or 0) + 1 end
	for _, e in ipairs(list) do
		local n = e.tool.Name
		seen[n] = (seen[n] or 0) + 1
		local txt = total[n] > 1 and ("%s #%d"):format(n, seen[n]) or n -- duplicates are numbered, never merged
		if e.lbl.Text ~= txt then e.lbl.Text = txt end
		e.lbl.Font = e.equipped and T.bold or T.font
		e.bar.Visible = e.equipped
		e.btn.LayoutOrder = e.equipped and e.uid or 100000 + e.uid -- equipped Tool(s) on top
	end
end

function selectEntry(entry)
	hidePopup()
	selected = entry
	for _, e in pairs(entries) do
		local isSel = e == entry
		if e.content.Visible ~= isSel then e.content.Visible = isSel end
		paintBtn(e)
	end
	if entry and entry.built then
		if entry.stale and settings.autoUpdate then refreshAll(entry) end
		if entry.fv ~= filterVer then applyFilter(entry) end
	end
	refreshLabels()
end

-- Optional "revert on close": restore the first-seen value of everything we edited
function revertAll()
	for _, e in pairs(entries) do
		for key, o in pairs(e.orig) do
			if key:sub(1, 2) == "a:" then
				pcall(e.tool.SetAttribute, e.tool, key:sub(3), o.has and o.v or nil)
			else
				local row = e.rowByKey[key]
				if row and o.has then writeRaw(row, o.v) end
			end
		end
	end
end

----------------------------------------------------------------------
-- Toolbar + footer
----------------------------------------------------------------------
createToggle(bar, "Auto Update", 0, 0, 106, "autoUpdate", function()
	if settings.autoUpdate and selected and selected.built then refreshAll(selected) end
end)
createToggle(bar, "Remember Tool", 112, 0, 120, "rememberTools")
createToggle(bar, "Revert on Close", 238, 0, 124, "revertOnClose")
createAction(footer, "Forget saved", 0, 76, function()
	if not selected then return end
	local tool = selected.tool
	local rec = recordFor(selected, false)
	if rec then
		table.clear(rec.f)
		if toolsStore.data[baseName[tool]] == rec then toolsStore.data[baseName[tool]] = nil end
		weakRec[tool] = nil
		markDirty(toolsStore)
	end
	setStatus("Forgot saved settings for " .. tool.Name)
end)
createAction(footer, "Refresh", -80, 52, function() if selected and selected.built then refreshAll(selected) end end)
on(mainBin, searchBox:GetPropertyChangedSignal("Text"), function()
	cancel(searchTh)
	searchTh = later(0.12, function()
		searchTh = nil
		filterText = searchBox.Text:lower():match("^%s*(.-)%s*$")
		filterVer += 1
		hidePopup()
		if selected and selected.built then applyFilter(selected) end
	end)
end)

----------------------------------------------------------------------
-- Tool tracking: equipped (Character) + Backpack only
----------------------------------------------------------------------
local function considerTool(tool)
	if tool:IsA("Tool") and not entries[tool] then addTool(tool) end
end
local function bindContainers()
	containerBin:clean()
	local function bind(c)
		if not c then return end
		for _, ch in ipairs(c:GetChildren()) do considerTool(ch) end
		containerBin:add(c.ChildAdded:Connect(considerTool))
	end
	bind(player.Character)
	bind(player:FindFirstChildOfClass("Backpack"))
	local gone = {}
	for tool in pairs(entries) do if not isOurs(tool.Parent) then gone[#gone + 1] = tool end end
	for _, tool in ipairs(gone) do removeEntry(tool) end
	for _, e in pairs(entries) do e.equipped = e.tool.Parent == player.Character end
	refreshLabels()
end
on(mainBin, player.CharacterAdded, bindContainers)
on(mainBin, player.ChildAdded, function(c) if c:IsA("Backpack") then bindContainers() end end)
bindContainers()

local notes = {}
for _, s in ipairs({settingsStore, suggStore, toolsStore}) do if s.note then notes[#notes + 1] = s.note end end
if #notes > 0 then setStatus(table.concat(notes, "; "), "warn") end
