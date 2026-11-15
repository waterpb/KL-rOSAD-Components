--!nocheck
-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py)
-- [BOOT] re-run guard, services, executor shims, connection bookkeeping | env, conn(), softService | deps: none | L28-65
-- [PORTS] rOSAD link: listen()/send(), env.KLOSAD.ctx.bus | listen, send, K_ctx | deps: BOOT | L67-79
-- [LOOK] rOSAD palette, accent, opacity, animation speed, repaint | THEMES, col(), paint(), opx(), tw(), applyLook() | deps: PORTS | L81-167
-- [KIT] rOSAD widgets: fr, txt, button, toast | fr(), txt(), mkBtn(), toast() | deps: LOOK | L169-258
-- [GUI_ROOT] gui container + old UI cleanup | guiRoot, attach() | deps: BOOT | L260-320
-- [PANEL] window, title bar, drag, content, placement | panel, execBtn, micBtn, chips, place() | deps: KIT, GUI_ROOT | L322-430
-- [STATE] mode/executed/muted + status text, push() | mode, executed, muted, setExec(), push() | deps: PANEL | L432-483
-- [MIC_HUD] V1 mic hud | ensureMicHud(), syncHud() | deps: STATE | L485-525
-- [BYPASS_ONE] V1 bypass | waitMicUnmuted(), runBypassV1() | deps: STATE | L527-583
-- [BYPASS_TWO] V2 bypass | runBypassV2() | deps: STATE | L585-743
-- [WIRING] buttons, ports commands, show/hide, kill, ENTRY | doCmd(), setOpen(), Kill() | deps: all | L745-877
--=====================================================================
--  VC Bypasser (KL rOSAD component)
--  Same bypass core as before (Bypass V1 / Bypass V2 + mic mute handling).
--  What is new: the panel looks like rOSAD and follows its Look and feel,
--  and it talks to rOSAD through ports (ctx.bus):
--     receives  "look"      theme / accent / opacity / glow / scale / animation changes
--               "unload"    rOSAD is closing
--               "vcb:cmd"   open close toggle mute unmute togglemute v1 v2 run state kill
--     sends     "vcb:state" { open, version, mode, executed, muted, busy }
--  Without rOSAD it still works on its own (RightShift toggles the panel,
--  a "VC Bypass" line at the bottom reopens it). Closing only minimizes the panel; re-running the
--  script just reopens it and never rebuilds or disturbs a running bypass.
--=====================================================================

-- [BOOT]
local VERSION = "1.0"
local env = (getgenv and getgenv()) or _G
-- re-running while a copy is alive only brings its panel back. Nothing is rebuilt, so the bypass that is already running (mode, mic controller, mute state) is left alone
local prev = env.KLOSAD_VCB
if prev and prev.isAlive and prev.isAlive() then
	pcall(prev.open)
	return
end
if prev and prev.Kill then pcall(prev.Kill) end -- a dead copy (its gui is gone): clean up and start fresh

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
if not Players.LocalPlayer then Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- optional executor globals: safe fallbacks when absent
local clonerefFn = (type(cloneref) == "function") and cloneref or function(i) return i end
local getconnectionsFn = (type(getconnections) == "function") and getconnections or nil
local gethuiFn = (type(gethui) == "function") and gethui or nil
local function softService(name)
	local ok, s = pcall(function() return game:GetService(name) end)
	if ok then return s end
	return nil
end
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local alive = true
local conns, guis = {}, {} -- everything Kill() has to let go of
local function conn(signal, fn)
	local c = signal:Connect(fn)
	conns[#conns + 1] = c
	return c
end
-- [/BOOT]

-- [PORTS]
-- rOSAD hands itself over as env.KLOSAD ({ ctx, cfg, ui, S }); ctx.bus is its port system. Without rOSAD (or with an older one) every port is a no-op
local KL = env.KLOSAD
local K_ctx = KL and KL.ctx
local bus = K_ctx and K_ctx.bus
local unlisten = {}
local function listen(name, fn, replay)
	if bus then unlisten[#unlisten + 1] = bus.on(name, fn, replay) end
end
local function send(name, ...)
	if bus then pcall(bus.fire, name, ...) end
end
-- [/PORTS]

-- [LOOK]
local rgb = Color3.fromRGB
-- the Dark / Light palettes of rOSAD (only the keys this panel uses)
local THEMES = {
	Dark = { panel = rgb(8, 8, 10), panelEdge = rgb(52, 50, 58), edge = rgb(72, 70, 80), ctrlOff = rgb(30, 30, 35), btnFill = rgb(40, 40, 46),
		glass = rgb(0, 0, 0), text = rgb(255, 255, 255), sub = rgb(158, 156, 168), danger = rgb(255, 99, 88) },
	Light = { panel = rgb(242, 242, 242), panelEdge = rgb(242, 242, 242), edge = rgb(158, 155, 155), ctrlOff = rgb(250, 250, 250), btnFill = rgb(214, 213, 213),
		glass = rgb(255, 255, 255), text = rgb(13, 13, 13), sub = rgb(84, 81, 81), danger = rgb(206, 38, 30) },
}
local Look = { theme = "Dark", accent = rgb(255, 255, 0), accentText = rgb(255, 255, 170), opacity = 0.8, glow = 75, scale = 1, anim = 1 }
local opK = 1

local function lum(c)
	local function f(v) return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * f(c.R) + 0.7152 * f(c.G) + 0.0722 * f(c.B)
end
local function contrast(a, b)
	local la, lb = lum(a), lum(b)
	if la < lb then la, lb = lb, la end
	return (la + 0.05) / (lb + 0.05)
end
local function legible(c, bg) -- nudge toward white (dark bg) / black (light bg) until it reaches 4.5:1
	local target = lum(bg) > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	for i = 0, 10 do
		local t = c:Lerp(target, i / 10)
		if contrast(t, bg) >= 4.5 then return t end
	end
	return target
end
local function hex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function col(key)
	if key == "accent" then return Look.accent end
	if key == "accentText" then return Look.accentText end
	if key == "onAccent" then return lum(Look.accent) > 0.4 and rgb(16, 16, 18) or rgb(255, 255, 255) end
	return THEMES[Look.theme][key]
end
local function opx(tr) return math.clamp(1 - (1 - tr) * opK, 0, 1) end -- UI Opacity is relative to rOSAD's 80 % design

local themed = {} -- inst -> { prop = colour key }: repainted on every "look"
local function paint(inst, prop, key)
	local t = themed[inst]
	if not t then t = {}; themed[inst] = t end
	t[prop] = key
	inst[prop] = col(key)
end
local relook = {} -- extra repaint callbacks (buttons, title, glow bar...)

local function dur(t)
	if Look.anim == 0 then return 0 end
	return t / math.max(tonumber(Look.anim) or 1, 0.25)
end
local function tw(o, goals, t)
	local d = dur(t or 0.15)
	if d <= 0 then
		for k, v in pairs(goals) do pcall(function() o[k] = v end) end
		return nil
	end
	local a = TweenService:Create(o, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	a:Play()
	return a
end

local scaleObj, glowBar, glowTween -- set by PANEL
local function applyLook(l)
	if type(l) == "table" then
		if THEMES[l.theme] then Look.theme = l.theme end
		if typeof(l.accent) == "Color3" then Look.accent = l.accent end
		for _, k in ipairs({ "opacity", "glow", "scale", "anim" }) do
			if tonumber(l[k]) then Look[k] = tonumber(l[k]) end
		end
	end
	Look.accentText = (typeof(l) == "table" and typeof(l.accentText) == "Color3") and l.accentText or legible(Look.accent, THEMES[Look.theme].panel)
	opK = math.clamp(Look.opacity, 0.2, 1) / 0.8
	for inst, t in pairs(themed) do
		if not inst.Parent then
			themed[inst] = nil
		else
			for prop, key in pairs(t) do pcall(function() inst[prop] = col(key) end) end
			local r = inst:GetAttribute("raw")
			if r then inst.BackgroundTransparency = opx(r) end
		end
	end
	for _, f in pairs(relook) do pcall(f) end
end
-- [/LOOK]

-- [KIT]
local function fs(pt) return math.floor(pt * 4 / 3 * 1.08 + 0.5) end
local FONT, FONT_B = Enum.Font.SourceSans, Enum.Font.SourceSansSemibold
-- rCtrl: buttons / chips, rPane: windows and big tiles (same two corner sizes rOSAD uses)
local ST = { rCtrl = 8, rPane = 12, ctrlEdge = 0.7, cardEdge = 0.55, hoverTint = 0.4, press = 0.97,
	glow = { idle = 1, hover = 0.82, press = 0.65, onIdle = 0.55, onHover = 0.4, onPress = 0.3 } }

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
-- frame at design-pixel position; fillKey nil = no fill
local function fr(parent, x, y, w, h, fillKey, tr, r, strokeKey, st, str)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0,
		BackgroundTransparency = fillKey and tr or 1 }, parent)
	if fillKey then
		paint(f, "BackgroundColor3", fillKey)
		if fillKey ~= "accent" then f:SetAttribute("raw", tr); f.BackgroundTransparency = opx(tr) end
	end
	if r then new("UICorner", { CornerRadius = UDim.new(0, r) }, f) end
	if strokeKey then
		paint(new("UIStroke", { Thickness = st or 1, Transparency = str or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f), "Color", strokeKey)
	end
	return f
end
local function txt(parent, str, pt, key, x, y, w, h, props)
	local o = new("TextLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Text = str, TextSize = fs(pt), Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
	for k, v in pairs(props or {}) do o[k] = v end
	paint(o, "TextColor3", key)
	return o
end

-- button variants, same names as rOSAD: secondary / primary (solid accent) / ctrlOff + ctrlOn (toggle chip) / danger / ghost
local VARIANT = {
	secondary = { fill = "btnFill", text = "text", tr = 0.25, edge = true },
	primary = { fill = "accent", text = "onAccent", tr = 0, bold = true },
	ctrlOff = { fill = "ctrlOff", text = "sub", tr = 0.35, edge = true },
	ctrlOn = { fill = "accent", text = "accentText", tr = 0.78, edge = true, on = true },
	danger = { fill = "btnFill", text = "danger", tr = 0.25, edge = true },
	ghost = { fill = "text", text = "text", tr = 1 },
}
local function mkBtn(parent, x, y, w, h, text, variant, cb, radius)
	radius = radius or ST.rCtrl
	local self = { variant = variant, enabled = true }
	local hot, down = false, false
	local b = new("TextButton", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", BackgroundTransparency = 1 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, b)
	local stroke = new("UIStroke", { Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
	local sc = new("UIScale", {}, b)
	-- accent glow rising from the bottom edge (created before the label so the text stays on top)
	local glow = new("Frame", { Name = "Glow", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Interactable = false }, b)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, glow)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 0) }) }, glow)
	local lbl = new("TextLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Text = text,
		TextSize = fs(9), Font = FONT, Interactable = false }, b)
	self.b, self.lbl = b, lbl
	local function look()
		local v = VARIANT[self.variant] or VARIANT.secondary
		local fillTr = v.fill == "accent" and v.tr or opx(v.tr)
		if fillTr >= 1 then fillTr = hot and 0.9 or 1 else fillTr = math.clamp(fillTr - (down and 0.3 or hot and 0.15 or 0), 0, 1) end
		local edge = col("edge"):Lerp(Look.accent, hot and ST.hoverTint or 0)
		lbl.Font = v.bold and FONT_B or FONT
		lbl.TextColor3 = col(v.text)
		lbl.TextTransparency = self.enabled and 0 or 0.55
		tw(b, { BackgroundColor3 = col(v.fill), BackgroundTransparency = fillTr }, 0.12)
		tw(stroke, { Color = edge, Transparency = v.edge and ST.ctrlEdge or 1 }, 0.12)
		glow.BackgroundColor3 = Look.accent
		local g = ST.glow
		local gt = (v.fill == "accent") and 1 or (v.on and (down and g.onPress or hot and g.onHover or g.onIdle) or (down and g.press or hot and g.hover or g.idle))
		tw(glow, { BackgroundTransparency = gt }, 0.12)
		tw(sc, { Scale = down and ST.press or 1 }, 0.08)
	end
	relook[b] = look
	look()
	b.MouseEnter:Connect(function() hot = true; look() end)
	b.MouseLeave:Connect(function() hot, down = false, false; look() end)
	b.MouseButton1Down:Connect(function() if self.enabled then down = true; look() end end)
	b.MouseButton1Up:Connect(function() down = false; look() end)
	b.MouseButton1Click:Connect(function() if self.enabled and cb then cb() end end)
	function self.set(v) self.variant = v; look() end
	function self.text(s) lbl.Text = s end
	function self.enable(on) self.enabled = on and true or false; look() end
	return self
end
-- [/KIT]

-- [GUI_ROOT]
local function resolveGuiRoot()
	if gethuiFn then
		local ok, r = pcall(gethuiFn)
		if ok and typeof(r) == "Instance" then return r end
	end
	local coreGui = softService("CoreGui")
	if coreGui then
		local probe = Instance.new("Folder")
		local parented = pcall(function() probe.Parent = coreGui end)
		probe:Destroy()
		if parented then return coreGui end
	end
	return PlayerGui
end
local guiRoot = resolveGuiRoot()
local function attach(inst, preferred)
	local ok = pcall(function() inst.Parent = preferred or guiRoot end)
	if not ok then pcall(function() inst.Parent = PlayerGui end) end
	guis[#guis + 1] = inst
	return inst
end
-- never CustomVoiceController below: that is the mic button of a running V2 bypass
-- leftovers of the old standalone script (a re-run of this one cleans up its own copy through Kill)
for _, container in ipairs({ guiRoot, PlayerGui }) do
	pcall(function()
		for _, name in ipairs({ "VCBypass", "VCBypass_Toasts", "VCBypass_Mic", "VCB_Toasts", "VCB_MicToggleGUI" }) do
			local stale = container:FindFirstChild(name)
			if stale then stale:Destroy() end
		end
	end)
end

-- toasts: rOSAD's own toast when rOSAD is there (same look, same Toasts setting), a small copy of it otherwise
local toastGui, toastStack, toastN = nil, nil, 0
local function ensureToastGui()
	if toastGui then return end
	toastGui = new("ScreenGui", { Name = "VCBypass_Toasts", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 240, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	attach(toastGui)
	toastStack = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(300, 0), BackgroundTransparency = 1 }, toastGui)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Bottom }, toastStack)
end
local function toast(msg, secs)
	msg, secs = tostring(msg or ""), tonumber(secs) or 3
	if K_ctx and K_ctx.notify then return pcall(K_ctx.notify, msg, secs) end
	ensureToastGui()
	toastN = toastN + 1
	local card = fr(toastStack, 0, 0, 300, 34, "panel", 0.1, ST.rCtrl, "edge", 1, ST.cardEdge)
	card.LayoutOrder = toastN
	card.BackgroundTransparency = 1
	local label = txt(card, msg, 9.5, "text", 12, 0, 276, 34, { TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, TextTransparency = 1 })
	tw(card, { BackgroundTransparency = opx(0.1) }, 0.25)
	tw(label, { TextTransparency = 0 }, 0.25)
	task.delay(secs, function()
		if not card.Parent then return end
		tw(card, { BackgroundTransparency = 1 }, 0.25)
		tw(label, { TextTransparency = 1 }, 0.25)
		task.delay(0.3, function() card:Destroy() end)
	end)
end
-- [/GUI_ROOT]

-- [PANEL]
local W, H = 300, 190
local ICONS = { mic = "rbxasset://textures/ui/VoiceChat/MicLight/Talking0.png", micoff = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png" }
local NOTES = { "Not supported on Xeno or Solara", "Second VCB" }

local panelGui = new("ScreenGui", { Name = "VCBypass", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 180, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
attach(panelGui)

local panel = new("Frame", { Name = "VCBypassPanel", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(W, H),
	BorderSizePixel = 0, Active = true, ZIndex = 150 }, panelGui)
paint(panel, "BackgroundColor3", "panel")
new("UICorner", { CornerRadius = UDim.new(0, 14) }, panel)
paint(new("UIStroke", { Thickness = 1, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel), "Color", "panelEdge")
scaleObj = new("UIScale", {}, panel)
relook.panel = function()
	panel.BackgroundTransparency = 1 - Look.opacity
	for _, d in ipairs(panel:GetChildren()) do
		if d:GetAttribute("deco") then d.Visible = Look.theme == "Dark" end
	end
end

-- soft depth like rOSAD's panel: black fading out from the top, white fading in toward the bottom (dark mode only)
local function wash(bottom, tr)
	local f = new("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = bottom and Color3.new(1, 1, 1) or Color3.new(0, 0, 0), Interactable = false, ZIndex = 150 }, panel)
	f:SetAttribute("deco", true)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, f)
	new("UIGradient", { Rotation = 90, Transparency = bottom and NumberSequence.new(1, tr) or NumberSequence.new(tr, 1) }, f)
	return f
end
wash(false, 0.7)
wash(true, 0.93)

-- the accent comet along the top edge (rOSAD's panel has the same one); stops with animations off or Glow Opacity 0
glowBar = fr(panel, 14, 0, W - 28, 2, "accent", 0)
glowBar.ZIndex = 152
local gg = new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(-1, 0) }, glowBar)
glowTween = TweenService:Create(gg, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), { Offset = Vector2.new(1, 0) })
local function syncGlowBar()
	local on = Look.glow > 0 and Look.theme == "Dark"
	glowBar.Visible = on
	if on and Look.anim ~= 0 and panel.Visible then glowTween:Play() else glowTween:Pause() end
end
relook.glowBar = syncGlowBar

-- title bar: ">" in the accent, like ">KL rOSAD"
local titleBar = new("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 151 }, panel)
local title = txt(titleBar, "", 11, "text", 16, 0, 180, 36, { RichText = true, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 152 })
title.Font = FONT_B
relook.title = function() title.Text = '<font color="' .. hex(Look.accent) .. '">&gt;</font>VC Bypasser' end
local closeBtn = mkBtn(titleBar, W - 34, 7, 22, 22, "", "ghost", nil, 11)
for _, rot in ipairs({ 45, -45 }) do -- a crisp X without font glyphs
	local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 2), BorderSizePixel = 0, Rotation = rot, Interactable = false }, closeBtn.b)
	paint(bar, "BackgroundColor3", "text")
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
end

-- drag by the title bar
do
	local dragging, dragStart, startPos, moveC, upC
	conn(titleBar.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging, dragStart, startPos = true, input.Position, panel.Position
		panel:SetAttribute("moved", true)
		if moveC then moveC:Disconnect() end
		if upC then upC:Disconnect() end
		moveC = UIS.InputChanged:Connect(function(ch)
			if not dragging then return end
			if ch.UserInputType ~= Enum.UserInputType.MouseMovement and ch.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = ch.Position - dragStart
			panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end)
		upC = UIS.InputEnded:Connect(function(e)
			if e.UserInputType ~= Enum.UserInputType.MouseButton1 and e.UserInputType ~= Enum.UserInputType.Touch then return end
			dragging = false
			if moveC then moveC:Disconnect(); moveC = nil end
			if upC then upC:Disconnect(); upC = nil end
		end)
	end)
end

-- content sits on rOSAD's darkening veil
local inner = fr(panel, 10, 40, W - 20, H - 50, "glass", 0.75, ST.rPane, "edge", 1, ST.cardEdge)
inner.ZIndex = 151
local IW = W - 20
local chipW = (IW - 24 - 8) / 2
local chip1 = mkBtn(inner, 12, 12, chipW, 28, "Bypass V1", "ctrlOn", function() end)
local chip2 = mkBtn(inner, 12 + chipW + 8, 12, chipW, 28, "Bypass V2", "ctrlOff", function() end)
local execBtn = mkBtn(inner, 12, 50, IW - 24 - 42, 34, "Execute Bypass", "primary", function() end)
local micBtn = mkBtn(inner, IW - 12 - 34, 50, 34, 34, "", "secondary", function() end, 17)
local micIcon = new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1, Image = ICONS.mic, ScaleType = Enum.ScaleType.Fit, Interactable = false }, micBtn.b)
paint(micIcon, "ImageColor3", "text")
local note = txt(inner, NOTES[1], 9, "sub", 14, 94, IW - 28, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
local statusDot = fr(inner, 14, 116, 6, 6, "accent", 0, 3)
local status = txt(inner, "Idle", 9, "sub", 26, 111, IW - 40, 16, { TextTruncate = Enum.TextTruncate.AtEnd })

local function place()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local fit = math.clamp(math.min((vp.X - 24) / W, (vp.Y - 90) / H), 0.45, 1)
	scaleObj.Scale = fit * math.clamp(Look.scale, 0.5, 2)
	if not panel:GetAttribute("moved") then
		local topInset = 36
		pcall(function() topInset = math.max(GuiService:GetGuiInset().Y, 36) end)
		panel.Position = UDim2.new(0.5, 0, 0, topInset + (isMobile and 8 or 12))
	end
end
relook.place = place
-- [/PANEL]

-- [STATE]
local version, mode, executed, muted, busy = 1, nil, false, false, false
local v2SetMuted -- set by V2

local function push()
	send("vcb:state", { open = panel.Visible, version = version, mode = mode, executed = executed, muted = muted, busy = busy })
end
local function setStatus(text, accent)
	status.Text = text
	paint(status, "TextColor3", accent and "accentText" or "sub")
	paint(statusDot, "BackgroundColor3", accent and "accent" or "edge")
end
-- the execute button: idle / bypassing / bypassed
local function setExec(state)
	if state == "busy" then
		busy = true
		execBtn.text("BYPASSING...")
		execBtn.set("ctrlOff"); execBtn.enable(false)
		setStatus("Working: follow the prompts", true)
	elseif state == "done" then
		busy = false
		execBtn.text("BYPASSED")
		execBtn.set("ctrlOn"); execBtn.enable(true)
		setStatus("Bypass " .. string.upper(mode or "?") .. " active", true)
	else
		busy = false
		execBtn.text("Execute Bypass")
		execBtn.set("primary"); execBtn.enable(true)
		setStatus("Idle", false)
	end
	push()
end
local function applyMicVisual(isMuted)
	micIcon.Image = isMuted and ICONS.micoff or ICONS.mic
	paint(micIcon, "ImageColor3", isMuted and "danger" or "text")
	micBtn.set(isMuted and "danger" or "secondary")
end
local function selectVersion(index)
	version = index
	chip1.set(index == 1 and "ctrlOn" or "ctrlOff")
	chip2.set(index == 2 and "ctrlOn" or "ctrlOff")
	note.Text = NOTES[index]
	push()
end
local function alreadyOn(requested)
	if mode == requested then
		toast(executed and "Already bypassed" or "Already running", 3)
	else
		toast("Bypass " .. string.upper(mode or "?") .. " is already on. Rejoin to use the other one", 4)
	end
end
-- [/STATE]

-- [MIC_HUD]
local function ensureMicHud()
	if guiRoot:FindFirstChild("VCBypass_Mic") or PlayerGui:FindFirstChild("VCBypass_Mic") then return end
	local order = 49
	pcall(function()
		local top = softService("CoreGui"):FindFirstChild("TopBarApp")
		if top and top:IsA("ScreenGui") then order = top.DisplayOrder end
	end)
	local g = new("ScreenGui", { Name = "VCBypass_Mic", ResetOnSpawn = false, DisplayOrder = order + 1 })
	attach(g)
	local frame = fr(g, 165, -45, 40, 40, "panel", 0.25, 20, "edge", 1, 0.5)
	frame.Name = "StatusFrame"
	frame.Active = true
	local hudIcon = new("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20),
		Image = ICONS.mic, ScaleType = Enum.ScaleType.Fit }, frame)
	paint(hudIcon, "ImageColor3", "text")
	local hit = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", ZIndex = 2 }, frame)
	hit.MouseButton1Click:Connect(function()
		muted = not muted
		hudIcon.Image = muted and ICONS.micoff or ICONS.mic
		paint(hudIcon, "ImageColor3", muted and "danger" or "text")
		applyMicVisual(muted)
		pcall(function() clonerefFn(softService("VoiceChatInternal")):PublishPause(muted) end)
		push()
	end)
end
local function syncHud()
	local g = guiRoot:FindFirstChild("VCBypass_Mic") or PlayerGui:FindFirstChild("VCBypass_Mic")
	local frame = g and g:FindFirstChild("StatusFrame")
	local icon = frame and frame:FindFirstChildOfClass("ImageLabel")
	if icon then
		icon.Image = muted and ICONS.micoff or ICONS.mic
		paint(icon, "ImageColor3", muted and "danger" or "text")
	end
end
local function publishMute()
	local vi = clonerefFn(softService("VoiceChatInternal"))
	if not vi then return false end
	return (pcall(function() vi:PublishPause(muted) end))
end
-- [/MIC_HUD]

-- [BYPASS_ONE]
local MUTED_ICON = "rbxasset://textures/ui/VoiceChat/MicLight/Muted.png"

local function waitMicUnmuted(timeout)
	timeout = timeout or 45
	local coreGui = softService("CoreGui")
	if not coreGui then return false end
	local micButton
	local ok = pcall(function()
		local top = coreGui:WaitForChild("TopBarApp", 5)
		top = top and top:WaitForChild("TopBarApp", 5)
		local left = top and top:WaitForChild("UnibarLeftFrame", 5)
		local menu = left and left:WaitForChild("UnibarMenu", 5)
		local l2 = menu and menu:WaitForChild("2", 5)
		local l3 = l2 and l2:WaitForChild("3", 5)
		micButton = l3 and l3:FindFirstChild("toggle_mic_mute", true)
	end)
	if not ok or not micButton then return false end
	local function iconImage()
		local f = micButton:FindFirstChild("IntegrationIconFrame", true)
		local holder = f and f:FindFirstChild("IntegrationIcon", true)
		local label = holder and holder:FindFirstChild("1")
		return label and label.Image or nil
	end
	local elapsed = 0
	repeat
		task.wait(1)
		elapsed = elapsed + 1
		local image = iconImage()
		if image and image ~= MUTED_ICON then return true end
	until elapsed >= timeout
	return false
end

local function runBypassV1()
	local voiceService = clonerefFn(softService("VoiceChatService"))
	local voiceInternal = clonerefFn(softService("VoiceChatInternal"))
	if not (voiceService and voiceInternal) then
		toast("Voice chat services are unavailable in this game", 5)
		return false
	end
	toast("Unmute your mic to continue bypass...")
	pcall(waitMicUnmuted, 45)
	pcall(function() voiceService:leaveVoice() end)
	task.wait(3)
	if getconnectionsFn then
		pcall(function()
			local cs = getconnectionsFn(voiceInternal.StateChanged)
			for i = 7, #cs do pcall(function() cs[i]:Disable() end) end
		end)
	end
	task.wait(3)
	pcall(function() voiceService:joinVoice() end)
	pcall(function() voiceInternal:PublishPause(muted) end)
	return true
end
-- [/BYPASS_ONE]

-- [BYPASS_TWO]
local function runBypassV2()
	if mode then return alreadyOn("v2") end
	mode = "v2"
	selectVersion(2)
	setExec("busy")
	task.spawn(function()
		local ok, err = pcall(function()
			local HIT_OFFSET_X, HIT_OFFSET_Y, HIT_SIZE = 14, 13, 35
			local voiceService = clonerefFn(softService("VoiceChatService"))
			local voiceInternal = clonerefFn(softService("VoiceChatInternal"))
			local coreGui = clonerefFn(softService("CoreGui")) or guiRoot
			local existingGui = LocalPlayer:WaitForChild("PlayerGui")
			if not (voiceService and voiceInternal) then error("VoiceChat services are not accessible from this script") end

			local TALKING_ICON = "rbxasset://textures/ui/VoiceChat/MicLight/Talking0.png"
			local micToggle, iconFrame, iconHolder, redDot
			local function findMicNodes()
				for _, node in ipairs(coreGui:GetDescendants()) do
					if node.Name == "toggle_mic_mute" then
						micToggle = node
					elseif node.Name == "RedVoiceDot" and node:IsA("GuiObject") then
						redDot = node
					end
				end
				if micToggle then
					iconFrame = micToggle:FindFirstChild("IntegrationIconFrame", true)
					if iconFrame then iconHolder = iconFrame:FindFirstChild("IntegrationIcon", true) end
				end
			end
			findMicNodes()
			if not micToggle then
				task.spawn(function() pcall(function() voiceService:joinVoice() end) end)
				task.wait(1.5)
				findMicNodes()
			end
			toast("Unmute to continue.", 5)

			local function iconImage()
				if iconHolder and iconHolder:FindFirstChild("1") then return iconHolder["1"].Image end
				return nil
			end
			local unmuted, waited = false, 0
			while not unmuted do
				local image = iconImage()
				if image and image ~= MUTED_ICON and image ~= "" then
					TALKING_ICON = image
					unmuted = true
				end
				if not unmuted then
					if waited >= 60 then error("timed out waiting for your mic to unmute") end
					task.wait(0.5)
					waited = waited + 0.5
				end
			end
			task.wait(1)

			task.spawn(function() pcall(function() voiceService:leaveVoice() end) end)
			task.wait(2)
			if getconnectionsFn then
				task.spawn(function()
					pcall(function()
						local cs = getconnectionsFn(voiceInternal.StateChanged)
						for i, c in ipairs(cs) do
							if i >= 7 and c then pcall(function() c:Disable() end) end
						end
					end)
				end)
			end
			task.wait(2)
			task.spawn(function() pcall(function() voiceService:joinVoice() end) end)
			task.wait(1)
			findMicNodes()

			if micToggle then
				task.spawn(function()
					for _, d in ipairs(micToggle:GetDescendants()) do
						if d:IsA("ImageLabel") or d:IsA("ImageButton") then
							d.ImageTransparency = 1
						elseif d:IsA("TextLabel") or d:IsA("TextButton") then
							d.TextTransparency = 1
						end
					end
				end)
			end

			local root
			if gethuiFn then
				local okHui, r = pcall(gethuiFn)
				if okHui then root = r end
			end
			root = root or coreGui or existingGui
			local old = root:FindFirstChild("CustomVoiceController")
			if old then old:Destroy() end

			-- the controller outlives the panel on purpose: it is your mic button now, closing / killing the panel must not take it away
			local controller = new("ScreenGui", { Name = "CustomVoiceController", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
			pcall(function() controller.Parent = root end)
			if not controller.Parent then controller.Parent = existingGui end

			local hitArea = new("TextButton", { Name = "MicHitArea", Size = UDim2.fromOffset(HIT_SIZE, HIT_SIZE), Position = UDim2.new(0, 150 + HIT_OFFSET_X, 0, 4 + HIT_OFFSET_Y),
				BackgroundTransparency = 1, Text = "", Active = true, ZIndex = 10000 }, controller)
			local customIcon = new("ImageLabel", { Name = "MicIcon", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = MUTED_ICON, ScaleType = Enum.ScaleType.Fit, ZIndex = 10001 }, hitArea)

			local paused = false
			pcall(function() paused = voiceInternal:IsPublishPaused() end)
			local function applyPaused(value)
				customIcon.Image = value and MUTED_ICON or TALKING_ICON
				if redDot and redDot.Parent then redDot.Visible = not value end
				task.spawn(function() pcall(function() voiceInternal:PublishPause(value) end) end)
			end
			hitArea.MouseButton1Click:Connect(function()
				paused = not paused
				applyPaused(paused)
				muted = paused
				applyMicVisual(paused)
				push()
			end)
			v2SetMuted = function(value)
				paused = value
				applyPaused(value)
			end
			applyPaused(true)
			paused = true

			local function micAnchor()
				if not iconHolder or not iconHolder.Parent then findMicNodes() end
				if iconHolder and iconHolder.AbsolutePosition.X > 50 then
					return iconHolder.AbsolutePosition, iconHolder.AbsoluteSize
				elseif micToggle and micToggle.AbsolutePosition.X > 50 then
					return micToggle.AbsolutePosition, micToggle.AbsoluteSize
				end
				return nil, nil
			end
			local anchor = micAnchor()
			if anchor and anchor.X > 0 and anchor.Y >= 0 then
				hitArea.Position = UDim2.new(0, anchor.X + HIT_OFFSET_X, 0, anchor.Y + HIT_OFFSET_Y)
				hitArea.Size = UDim2.fromOffset(HIT_SIZE, HIT_SIZE)
			end
			if redDot and redDot:IsA("GuiObject") then redDot.Visible = not paused end
			voiceInternal.StateChanged:Connect(function()
				pcall(function() paused = voiceInternal:IsPublishPaused() end)
				if redDot and redDot.Parent then redDot.Visible = not paused end
			end)
		end)

		if ok then
			executed, muted = true, true
			applyMicVisual(true)
			setExec("done")
			toast("Bypass active. Use the mic button to mute and unmute.", 5)
		else
			mode = nil
			setExec("idle")
			toast("Bypass failed: " .. tostring(err), 5)
		end
	end)
end
-- [/BYPASS_TWO]

-- [WIRING]
local function runBypass()
	if version == 2 then return runBypassV2() end
	if mode then return alreadyOn("v1") end
	mode = "v1"
	setExec("busy")
	task.spawn(function()
		local ok, result = pcall(runBypassV1)
		if ok and result == true then
			executed = true
			setExec("done")
			toast("Bypass executed")
			pcall(ensureMicHud)
			pcall(syncHud)
		else
			mode = nil
			setExec("idle")
			if ok then toast("Bypass failed: voice chat unavailable", 5) else toast("Bypass failed: " .. tostring(result), 5) end
		end
	end)
end
local function setMuted(value)
	if not executed then return toast("Execute bypass first") end
	if value == nil then value = not muted end
	muted = value
	applyMicVisual(muted)
	if mode == "v2" then
		if v2SetMuted then pcall(v2SetMuted, muted) end
	else
		pcall(syncHud)
		pcall(publishMute)
	end
	push()
end
local function pickVersion(index)
	if version == index then return end
	if mode then return toast("A bypass is already on. Rejoin to switch versions", 3) end
	selectVersion(index)
end
chip1.b.MouseButton1Click:Connect(function() pickVersion(1) end)
chip2.b.MouseButton1Click:Connect(function() pickVersion(2) end)
-- the buttons were built before the functions above existed: give them their click handlers now
execBtn.b.MouseButton1Click:Connect(function() if execBtn.enabled then runBypass() end end)
micBtn.b.MouseButton1Click:Connect(function() setMuted(nil) end)

local setOpen
local pill -- standalone only: the minimized panel is a clickable line in this script's own toast stack. With rOSAD it is a line in rOSAD's notification feed instead (it reads "vcb:state")
local function showPill(on)
	if bus then return end
	if on and not pill then
		ensureToastGui()
		pill = mkBtn(toastStack, 0, 0, 300, 30, "VC Bypass  ·  click to open", "secondary", function() setOpen(true) end)
		pill.b.LayoutOrder = 0
	end
	if pill then pill.b.Visible = on end
end
function setOpen(open)
	panel.Visible = open
	showPill(not open)
	if open then
		task.defer(place)
		syncGlowBar()
	else
		glowTween:Pause()
	end
	push()
end
closeBtn.b.MouseButton1Click:Connect(function() setOpen(false) end)

local function Kill()
	if not alive then return end
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	for _, u in ipairs(unlisten) do pcall(u) end
	pcall(function() glowTween:Cancel() end)
	for _, g in ipairs(guis) do pcall(function() g:Destroy() end) end
	if env.KLOSAD_VCB and env.KLOSAD_VCB.Kill == Kill then env.KLOSAD_VCB = nil end
	send("vcb:state", { closed = true })
end

local function doCmd(cmd)
	cmd = tostring(cmd or ""):lower()
	if cmd == "open" then setOpen(true)
	elseif cmd == "close" then setOpen(false)
	elseif cmd == "toggle" then setOpen(not panel.Visible)
	elseif cmd == "mute" then setMuted(true)
	elseif cmd == "unmute" then setMuted(false)
	elseif cmd == "togglemute" then setMuted(nil)
	elseif cmd == "v1" then pickVersion(1)
	elseif cmd == "v2" then pickVersion(2)
	elseif cmd == "run" then runBypass()
	elseif cmd == "state" then push()
	elseif cmd == "kill" then Kill() end
end

-- receiving ports
listen("look", applyLook, true) -- replay = the current look right away
listen("vcb:cmd", doCmd)
listen("unload", Kill)
-- older rOSAD without ports: read its settings now and then instead
if KL and not bus and KL.cfg then
	task.spawn(function()
		local sig
		while alive do
			local c, s = KL.cfg, KL.S
			local now = tostring(c.theme) .. tostring(c.accent) .. tostring(c.opacity) .. tostring(c.glow) .. tostring(c.scale) .. tostring(c.anim)
			if now ~= sig then
				sig = now
				applyLook({ theme = c.theme, accent = s and s.accent, opacity = c.opacity, glow = c.glow, scale = c.scale, anim = c.anim })
			end
			task.wait(1)
		end
	end)
end

conn(UIS.InputBegan, function(input, processed)
	if processed or bus then return end -- with rOSAD the keybinds are its own
	if input.KeyCode == Enum.KeyCode.RightShift then setOpen(not panel.Visible) end
end)
pcall(function()
	local cam = workspace.CurrentCamera
	if cam then conn(cam:GetPropertyChangedSignal("ViewportSize"), function() if panel.Visible then place() end end) end
end)

env.KLOSAD_VCB = { Kill = Kill, version = VERSION, open = function() setOpen(true) end, cmd = doCmd, isAlive = function() return alive and panelGui.Parent ~= nil end }
applyLook(nil) -- paints everything once (the "look" replay above overrides it when rOSAD is there)
relook.title()
setExec("idle")
selectVersion(1)
applyMicVisual(false)
setOpen(true)
toast("Unmute your mic, talk into it for 5 seconds, then press Execute Bypass", 5)
-- [/WIRING]
