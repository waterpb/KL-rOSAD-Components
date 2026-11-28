-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py)
-- [BOOT] header, env, services, M table, conn | env, M, K, conn() | deps: none | L16-47
-- [THEME] rOSAD palette, paint registry, small helpers | col(), paint(), applyTheme(), fs(), thumb() | deps: BOOT | L48-107
-- [PURE] name classify, filter match, skin brightness | classifyNames(), filterMatch(), bodyLum() | deps: THEME | L108-185
-- [CACHE] avatar cache, lazy catalog names, per-player analyze | reclassify(), pump(), analyze(), watchPlayer() | deps: PURE | L186-378
-- [UI] window and widget builders | frame(), label(), button(), input(), scroller(), slider() | deps: THEME | L379-600
-- [HEADER] title bar, close/drag | deps: UI | L601-636
-- [FILTERS] filter chips and player list panel | paintChip() | deps: UI | L637-742
-- [RIGHT] 3D preview, details, actions, worn items panels | deps: UI | L743-860
-- [LIST] apply filters, render player rows | schedule(), tagLine(), renderList() | deps: CACHE, FILTERS | L861-939
-- [DETAILS] preview model, details, worn items | buildPreview(), showDetails(), renderItems() | deps: RIGHT, CACHE | L940-1103
-- [ACTIONS] view/listen/hide/ESP and rOSAD commands | refreshActions(), espToggle(), M.action(), selectPlayer(), M.refreshAll() | deps: DETAILS | L1104-1289
-- [LIFE] search box wiring, rOSAD hooks, open/close/toggle/Unload | M.open(), M.close(), M.toggle(), M.Unload() | deps: all | L1290-1399
-- [SELFTEST] assert self-check of pure logic | M.selftest() | deps: PURE | L1400-1428
-- [ENTRY] run selftest, open window | deps: all | L1429-1434
-- [BOOT]
-- ===== AVATAR DISCOVERY 1.0 ==================================================
-- Player discovery for KL rOSAD: filter players by worn items (Headless, Korblox,
-- 8-Bit Crown, Opal), female keywords and skin brightness, then preview the full
-- 3D avatar and act on the player with rOSAD's own commands.
--
-- Linked mode: getgenv().KLOSAD exists -> uses rOSAD's theme, scale, actions,
-- voice listen, hide, profile window and event bus. Registers ;avatars.
-- Standalone: getgenv().AvatarDiscovery.open() / the window opens on execute.
-- ============================================================================

local env = (getgenv and getgenv()) or _G
if env.AvatarDiscovery and env.AvatarDiscovery.Unload then pcall(env.AvatarDiscovery.Unload) end

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local lp = Players.LocalPlayer
local K = env.KLOSAD -- rOSAD 1.2+ handle (nil = standalone)

local M = { version = "1.0", visible = false, dead = false }
env.AvatarDiscovery = M

local cons = {}
local function conn(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

-- [/BOOT]
-- [THEME]
-- ===== theme (rOSAD's palette, inherited live through its "look" bus) ========
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local PAL = {
	Dark = { panel = rgb(8, 8, 10), inner = rgb(15, 15, 18), edge = rgb(72, 70, 80), row = rgb(32, 31, 37),
		ctrlOff = rgb(30, 30, 35), btnFill = rgb(40, 40, 46), text = rgb(255, 255, 255), text2 = rgb(238, 237, 242),
		sub = rgb(158, 156, 168), hint = rgb(122, 122, 134), danger = rgb(255, 99, 88) },
	Light = { panel = rgb(242, 242, 242), inner = rgb(231, 230, 230), edge = rgb(158, 155, 155), row = rgb(191, 191, 191),
		ctrlOff = rgb(250, 250, 250), btnFill = rgb(214, 213, 213), text = rgb(13, 13, 13), text2 = rgb(31, 31, 31),
		sub = rgb(84, 81, 81), hint = rgb(107, 103, 103), danger = rgb(206, 38, 30) },
}
local themeName = (K and K.cfg and K.cfg.theme == "Light") and "Light" or "Dark"
local ACCENT = (K and K.S and K.S.accent) or rgb(255, 255, 0)
local ACCENT_TEXT = rgb(16, 16, 18)
local ACCENT_LABEL = rgb(255, 255, 0)
local U
local function legibleOnAccent()
	local l = 0.2126 * ACCENT.R + 0.7152 * ACCENT.G + 0.0722 * ACCENT.B
	return l > 0.45 and rgb(16, 16, 18) or rgb(255, 255, 255)
end
local function accented()
	ACCENT_TEXT = legibleOnAccent()
	-- accent as a text colour: darken it on a light panel until it reads
	ACCENT_LABEL = themeName == "Dark" and ACCENT or ACCENT:Lerp(rgb(0, 0, 0), .45)
end
accented()

local function col(key)
	if key == "accent" then return ACCENT end
	if key == "accentText" then return ACCENT_LABEL end
	if key == "onAccent" then return ACCENT_TEXT end
	return (PAL[themeName] or PAL.Dark)[key] or PAL.Dark[key] or rgb(255, 255, 255)
end
local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + .5), math.floor(c.G * 255 + .5), math.floor(c.B * 255 + .5)) end

local themed = setmetatable({}, { __mode = "k" })
local function paint(o, prop, key)
	local t = themed[o]
	if not t then t = {}; themed[o] = t end
	t[prop] = key
	o[prop] = col(key)
end
local function applyTheme()
	for o, t in pairs(themed) do
		if o.Parent then for prop, key in pairs(t) do pcall(function() o[prop] = col(key) end) end end
	end
	if U and U.title then U.title.Text = "<font color=\"" .. hex(ACCENT_LABEL) .. "\">&gt;</font>AVATARS" end
end

local fs = function(pt) return math.floor(pt * 4 / 3 * 1.08 + .5) end
local FONT, FONT_B, FONT_CODE = Enum.Font.SourceSans, Enum.Font.SourceSansSemibold, Enum.Font.Code

local function clear(g)
	for _, c in ipairs(g:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
end
local function thumb(kind, id, size) return ("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(kind, id, size, size) end

-- [/THEME]
-- [PURE]
-- ===== pure helpers (also covered by M.selftest) ===========================
local FEMALE_WORDS = { "girl", "doll", "female", "woman", "lady", "princess", "barbie", "bride", "queen", "sister", "gal" }
local ITEM_KEYS = { "headless", "korblox", "crown", "opal", "limited" }
local KNOWN = {
	[15093053680] = "headless", [131592085] = "headless", [134082579] = "headless",
	[139607718] = "korblox", [139607570] = "korblox", [139607625] = "korblox", [139607673] = "korblox",
	[139607770] = "korblox", [139610147] = "korblox",
	[10159600649] = "crown",
}

-- names only: returns tags + the female keywords that matched
local function classifyNames(names, tags, words)
	tags, words = tags or {}, words or {}
	for _, nm in ipairs(names) do
		local n = tostring(nm):lower()
		if n:find("headless", 1, true) then tags.headless = true end
		if n:find("korblox", 1, true) then tags.korblox = true end
		if n:find("crown", 1, true) and (n:find("8-bit", 1, true) or n:find("8 bit", 1, true)) then tags.crown = true end
		if n:find("opal", 1, true) then tags.opal = true end
		for _, w in ipairs(FEMALE_WORDS) do
			if n:find("%f[%w]" .. w .. "%f[%W]") then
				tags.female = true
				words[w] = true
			end
		end
	end
	return tags, words
end

-- e = cached avatar entry, f = filter state
local function filterMatch(e, f)
	e = e or { tags = {} }
	local need, any, hit = 0, 0, 0
	for k, st in pairs(f.items) do
		local has = (e.tags and e.tags[k]) and true or false
		if st == 2 then -- needs: every 'needs' item must be worn
			if not has then return false end
			need = need + 1
		elseif st == 1 then -- can have: at least one of them must match
			any = any + 1
			if has then hit = hit + 1 end
		elseif st == 3 and has then -- excluded: must not be worn
			return false
		end
	end
	if need == 0 and any > 0 and hit == 0 then return false end
	if f.female and not (e.tags and e.tags.female) then return false end
	if f.keyword ~= "" then
		local found = false
		for _, nm in ipairs(e.namesList or {}) do
			if nm:lower():find(f.keyword:lower(), 1, true) then found = true; break end
		end
		if not found then return false end
	end
	if f.skin then -- minimum body brightness; anyone darker is ignored
		if not e.lum or e.lum < f.min then return false end
	end
	return true
end

-- body luminance 0..1 (HSV value of the body colours only)
local function bodyLum(desc)
	local sum, wsum = 0, 0
	local function add(c, w)
		if typeof(c) ~= "Color3" then return end
		local ok, _, _, v = pcall(function() return Color3.toHSV(c) end)
		if not ok then return end
		sum, wsum = sum + v * w, wsum + w
	end
	add(desc.HeadColor, 1)
	add(desc.TorsoColor, 3)
	add(desc.LeftArmColor, 1); add(desc.RightArmColor, 1)
	add(desc.LeftLegColor, 1); add(desc.RightLegColor, 1)
	return wsum > 0 and (sum / wsum) or nil
end

-- [/PURE]
-- [CACHE]
-- ===== avatar cache + lazy catalog names (no polling, cached per session) ===
local cache = {}      -- uid -> { desc, ids, idset, rig, lum, tags, words, namesList, status, sig, busy }
local product = {}    -- assetId -> name | false
local limitedOf = {}  -- assetId -> true | false (limited or limited unique)
local pending = {}    -- assetId -> true while looked up
local queue, workers = {}, 0
local selected

local showDetails, buildPreview, renderItems, renderList, refreshActions, schedule, selectPlayer
local F = { query = "", items = {}, female = false, keyword = "", skin = false, min = .5 }

local function reclassify(e)
	local tags, words, names, set = {}, {}, {}, {}
	for _, id in ipairs(e.ids or {}) do
		local known = KNOWN[id]
		if known then tags[known] = true end
		if limitedOf[id] then tags.limited = true end
		local nm = product[id]
		if nm then names[#names + 1] = nm end
		set[id] = true
	end
	classifyNames(names, tags, words)
	local list = {}
	for w in pairs(words) do list[#list + 1] = w end
	table.sort(list)
	e.tags, e.words, e.namesList, e.idset = tags, list, names, set
end

local batchOK, csrf = true, nil -- batch = one catalog request for up to 120 assets; falls back to GetProductInfo one by one if the executor / endpoint refuses
local function batchNames(ids)
	local rq = (syn and syn.request) or request or http_request or (http and http.request)
	if not rq then return nil end
	local HS = game:GetService("HttpService")
	local items = {}
	for _, id in ipairs(ids) do items[#items + 1] = { itemType = "Asset", id = id } end
	local body = HS:JSONEncode({ items = items })
	for _ = 1, 2 do -- the first try may only fetch the csrf token
		local ok, r = pcall(rq, { Url = "https://catalog.roblox.com/v1/catalog/items/details", Method = "POST",
			Headers = { ["Content-Type"] = "application/json", ["x-csrf-token"] = csrf or "" }, Body = body })
		if not (ok and type(r) == "table") then return nil end
		if r.StatusCode == 403 then
			for k, v in pairs(r.Headers or {}) do if tostring(k):lower() == "x-csrf-token" then csrf = v end end
			if not csrf then return nil end
		elseif r.StatusCode == 200 then
			local okJ, j = pcall(HS.JSONDecode, HS, r.Body)
			if not (okJ and type(j) == "table" and type(j.data) == "table") then return nil end
			local out = {}
			for _, d in ipairs(j.data) do
				if type(d) == "table" and tonumber(d.id) and type(d.name) == "string" then
					local lim = false
					for _, rs in ipairs(type(d.itemRestrictions) == "table" and d.itemRestrictions or {}) do
						if rs == "Limited" or rs == "LimitedUnique" then lim = true end
					end
					out[tonumber(d.id)] = { name = d.name, limited = lim }
				end
			end
			return out
		else
			return nil
		end
	end
	return nil
end

local function pump()
	if M.dead or #queue == 0 or workers >= (batchOK and 3 or 8) then return end
	workers = workers + 1
	local batch = {}
	for _ = 1, batchOK and 120 or 1 do
		local id = table.remove(queue, 1)
		if not id then break end
		batch[#batch + 1] = id
	end
	task.spawn(function()
		local got = batchOK and batchNames(batch) or nil
		if batchOK and not (got and next(got)) then -- no batch here: put them back and go one by one with more workers
			batchOK = false
			for i = #batch, 1, -1 do table.insert(queue, 1, batch[i]) end
			workers = workers - 1
			for _ = 1, 8 do pump() end
			return
		end
		for _, id in ipairs(batch) do
			local g = got and got[id]
			if g then
				product[id], limitedOf[id] = g.name, g.limited
			else
				local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
				product[id] = (ok and type(info) == "table" and type(info.Name) == "string") and info.Name or false
				limitedOf[id] = (ok and type(info) == "table" and (info.IsLimited == true or info.IsLimitedUnique == true)) and true or false
			end
			pending[id] = nil
		end
		workers = workers - 1
		for _, e in pairs(cache) do reclassify(e) end
		if M.dead then return end
		if selected then
			showDetails(selected)
			if #queue == 0 then renderItems(selected) end -- one rebuild once the names are in
		end
		schedule()
		pump()
	end)
end

local function queueName(id)
	id = tonumber(id)
	if not id or id <= 0 or product[id] ~= nil or pending[id] then return end
	pending[id] = true
	queue[#queue + 1] = id
	pump()
end

-- the player you are looking at jumps the queue: their names come first
local function prioritize(ids)
	for i = #(ids or {}), 1, -1 do
		local id = ids[i]
		local at = pending[id] and table.find(queue, id)
		if at then table.remove(queue, at); table.insert(queue, 1, id) end
	end
end

local BODY_FIELDS = { "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Face", "Shirt", "Pants", "GraphicTShirt" }

local function analyze(p, force)
	if M.dead or not p or not p.Parent then return end
	local e = cache[p.UserId]
	if e and e.busy then return end
	e = e or { uid = p.UserId, ids = {}, idset = {} }
	cache[p.UserId] = e
	if e.desc and not force then return end -- cached until CharacterAppearanceLoaded clears it
	e.busy = true
	task.spawn(function()
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		local ok, desc = pcall(function()
			if h then return h:GetAppliedDescription() end
			return Players:GetHumanoidDescriptionFromUserId(p.UserId)
		end)
		if not (ok and typeof(desc) == "Instance") then
			e.status = "Avatar unavailable"
			e.busy = false
			if selected == p then showDetails(p) end
			return
		end
		local ids, seen = {}, {}
		local okA, acc = pcall(function() return desc:GetAccessories(true) end)
		if okA and type(acc) == "table" then
			for _, a in ipairs(acc) do
				local id = tonumber((pcall(function() return a.AssetId end)) and a.AssetId)
				if id and id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
			end
		end
		for _, f in ipairs(BODY_FIELDS) do
			local id = tonumber((pcall(function() return desc[f] end)) and desc[f])
			if id and id > 0 and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
		end
		local sig = table.concat(ids, ",") .. "|" .. tostring(desc.HeadColor) .. tostring(desc.TorsoColor) ..
			tostring(desc.BodyTypeScale) .. tostring(desc.WidthScale) .. tostring(desc.ProportionScale)
		if not force and e.sig == sig and e.desc then
			e.busy = false
			return
		end
		e.sig, e.desc, e.status = sig, desc, nil
		e.rig = h and h.RigType or Enum.HumanoidRigType.R15
		e.ids = ids
		e.lum = bodyLum(desc)
		reclassify(e)
		for _, id in ipairs(ids) do queueName(id) end
		if selected == p then prioritize(ids) end
		e.busy = false
		if M.dead then return end
		if selected == p then
			buildPreview(p, e)
			showDetails(p)
			renderItems(p)
		end
		schedule()
	end)
end

local charCons = {}
local function watchPlayer(p)
	if charCons[p.UserId] then return end
	charCons[p.UserId] = p.CharacterAppearanceLoaded:Connect(function()
		cache[p.UserId] = nil -- even while closed: the next open reads the new body
		if not M.visible then return end
		analyze(p, true)
		if selected == p then selectPlayer(p) end
	end)
end

-- [/CACHE]
-- [UI]
-- ===== window + widgets ====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AvatarDiscovery"
gui.ResetOnSpawn = false
gui.DisplayOrder = 60
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okG, holder = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
if not okG then holder = lp:WaitForChild("PlayerGui") end
local okP = pcall(function() gui.Parent = holder end)
if not okP then gui.Parent = lp:WaitForChild("PlayerGui") end

local W, H, HD = 760, 560, 44
local win = Instance.new("Frame")
win.Name = "AvatarDiscoveryWindow"
win.AnchorPoint = Vector2.new(.5, .5)
win.Position = UDim2.fromScale(.5, .5)
win.Size = UDim2.fromOffset(W, H)
win.BorderSizePixel = 0
win.Active = true
win.BackgroundColor3 = col("panel")
win.BackgroundTransparency = 1 - ((K and K.cfg and K.cfg.opacity) or 0.88)
win.Parent = gui
local winCorner = Instance.new("UICorner", win); winCorner.CornerRadius = UDim.new(0, 12)
local winStroke = Instance.new("UIStroke", win)
winStroke.Thickness = 1.5; winStroke.Transparency = .1; winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
paint(winStroke, "Color", "accent")
local winScale = Instance.new("UIScale", win)
winScale.Scale = (K and K.cfg and K.cfg.scale) or 1

local function frame(parent, x, y, w, h, fill, tr, r, strokeKey, sth, stt)
	local f = Instance.new("Frame")
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = fill and tr or 1
	f.Parent = parent
	if fill then paint(f, "BackgroundColor3", fill) end
	if r then local c = Instance.new("UICorner", f); c.CornerRadius = UDim.new(0, r) end
	if strokeKey then
		local s = Instance.new("UIStroke", f)
		s.Thickness = sth or 1
		s.Transparency = stt or .7
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		paint(s, "Color", strokeKey)
	end
	return f
end

local function label(parent, str, pt, key, x, y, w, h, props)
	local o = Instance.new("TextLabel")
	o.BackgroundTransparency = 1
	o.BorderSizePixel = 0
	o.Text = str or ""
	o.TextSize = fs(pt)
	o.Font = FONT
	o.TextXAlignment = Enum.TextXAlignment.Left
	o.TextYAlignment = Enum.TextYAlignment.Top
	o.Position = UDim2.fromOffset(x, y)
	o.Size = UDim2.fromOffset(w, h)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	paint(o, "TextColor3", key or "text")
	return o
end

local VARIANT = {
	off = { fill = "ctrlOff", text = "text", tr = .25, edge = true },
	on = { fill = "accent", text = "onAccent", tr = .18, edge = true },
	primary = { fill = "accent", text = "onAccent", tr = 0, bold = true },
	danger = { fill = "btnFill", text = "danger", tr = .25, edge = true },
	ghost = { fill = "text", text = "text", tr = 1 },
}

local function setKind(b, kind)
	local v = VARIANT[kind or "off"]
	paint(b, "BackgroundColor3", v.fill)
	paint(b, "TextColor3", v.text)
	b.BackgroundTransparency = v.tr
	b:SetAttribute("adTr", v.tr)
	b.Font = v.bold and FONT_B or FONT
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		paint(s, "Color", v.edge and "edge" or v.fill)
		s.Enabled = v.edge == true
		s.Transparency = kind == "on" and .2 or .7
	end
	b:SetAttribute("adKind", kind or "off")
end

local function button(parent, str, x, y, w, h, kind, cb, pt)
	local b = Instance.new("TextButton")
	b.Text = str
	b.TextSize = fs(pt or 9)
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.TextTruncate = Enum.TextTruncate.AtEnd
	b.Position = UDim2.fromOffset(x, y)
	b.Size = UDim2.fromOffset(w, h)
	b.Parent = parent
	local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0, 8)
	local s = Instance.new("UIStroke", b)
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	setKind(b, kind)
	b.MouseEnter:Connect(function() if b.Active then b.BackgroundTransparency = math.max((b:GetAttribute("adTr") or b.BackgroundTransparency) - .12, 0) end end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency = b:GetAttribute("adTr") or b.BackgroundTransparency end)
	b:GetPropertyChangedSignal("Active"):Connect(function()
		b.TextTransparency = b.Active and 0 or .5
	end)
	b.MouseButton1Click:Connect(function() if b.Active and cb then cb(b) end end)
	return b
end

local function input(parent, ph, x, y, w, h, pt)
	local f = frame(parent, x, y, w, h, "ctrlOff", .25, 8, "edge", 1, .7)
	local t = Instance.new("TextBox")
	t.BackgroundTransparency = 1
	t.BorderSizePixel = 0
	t.Text = ""
	t.PlaceholderText = ph
	t.ClearTextOnFocus = false
	t.Font = FONT
	t.TextSize = fs(pt or 10)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Position = UDim2.fromOffset(10, 0)
	t.Size = UDim2.new(1, -20, 1, 0)
	t.Parent = f
	paint(t, "TextColor3", "text")
	paint(t, "PlaceholderColor3", "hint")
	return t
end

local function scroller(parent, x, y, w, h)
	local s = Instance.new("ScrollingFrame")
	s.Position = UDim2.fromOffset(x, y)
	s.Size = UDim2.fromOffset(w, h)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 3
	s.AutomaticCanvasSize = Enum.AutomaticSize.None
	s.CanvasSize = UDim2.new()
	s.ElasticBehavior = Enum.ElasticBehavior.Never
	paint(s, "ScrollBarImageColor3", "accent")
	s.Parent = parent
	return s
end

local function slider(parent, x, y, w, min, max, step, get, set, rainbow)
	local hit = Instance.new("TextButton")
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.Position = UDim2.fromOffset(x, y)
	hit.Size = UDim2.fromOffset(w, 20)
	hit.Parent = parent
	local track = Instance.new("Frame")
	track.AnchorPoint = Vector2.new(0, .5)
	track.Position = UDim2.new(0, 0, .5, 0)
	track.Size = UDim2.fromOffset(w, 4)
	track.BorderSizePixel = 0
	track.Parent = hit
	local c = Instance.new("UICorner", track); c.CornerRadius = UDim.new(1, 0)
	if rainbow then
		track.BackgroundColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient", track)
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, rgb(255, 60, 60)), ColorSequenceKeypoint.new(.17, rgb(255, 220, 40)),
			ColorSequenceKeypoint.new(.33, rgb(60, 220, 90)), ColorSequenceKeypoint.new(.5, rgb(40, 220, 220)),
			ColorSequenceKeypoint.new(.67, rgb(60, 110, 255)), ColorSequenceKeypoint.new(.83, rgb(210, 70, 255)),
			ColorSequenceKeypoint.new(1, rgb(255, 60, 60)),
		})
	else
		paint(track, "BackgroundColor3", "edge")
	end
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BorderSizePixel = 0
	fill.BackgroundTransparency = rainbow and 1 or .2
	fill.Parent = track
	paint(fill, "BackgroundColor3", "accent")
	local fc = Instance.new("UICorner", fill); fc.CornerRadius = UDim.new(1, 0)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(.5, .5)
	knob.Size = UDim2.fromOffset(14, 14)
	knob.BackgroundColor3 = rgb(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = hit
	local kc = Instance.new("UICorner", knob); kc.CornerRadius = UDim.new(1, 0)
	local ks = Instance.new("UIStroke", knob); ks.Thickness = 1; ks.Color = rgb(0, 0, 0); ks.Transparency = .6
	local function place(v)
		local f = (max == min) and 0 or math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(f, 0, 1, 0)
		knob.Position = UDim2.new(f, 0, .5, 0)
	end
	local function apply(px)
		local f = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = min + (max - min) * f
		if step then v = math.floor(v / step + .5) * step end
		v = math.clamp(v, min, max)
		set(v)
		place(v)
	end
	local drag = false
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			apply(i.Position.X)
		end
	end)
	conn(UserInputService.InputChanged, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then apply(i.Position.X) end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
	end)
	place(get())
	return place
end

-- [/UI]
-- [HEADER]
-- ===== header ===============================================================
U = {}
U.title = label(win, "", 14, "text", 22, 9, 190, 26, { Font = FONT_CODE, RichText = true, TextSize = 21 })
U.title.Text = "<font color=\"" .. hex(ACCENT_LABEL) .. "\">&gt;</font>AVATARS"
local hline = frame(win, 14, HD - 1, W - 28, 1, "accent", .8)
local hlGrad = Instance.new("UIGradient", hline)
hlGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, 1) })
U.sub = label(win, K and ("RoSaD linked  ·  v" .. tostring(K.version or "?")) or "standalone  ·  rOSAD not detected", 8, "hint", 170, 18, 320, 14, { Font = FONT_CODE, TextSize = 11 })
U.refresh = button(win, "↻", W - 84, 8, 32, 28, "ghost", function() M.refreshAll() end, 13)
U.close = button(win, "×", W - 46, 8, 34, 28, "ghost", function() M.close() end, 13)

-- drag by the header
do
	local drag, d0, p0 = false, nil, nil
	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.fromOffset(W - 100, HD - 6)
	header.Parent = win
	header.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag, d0, p0 = true, i.Position, win.Position
		end
	end)
	conn(UserInputService.InputChanged, function(i)
		if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - d0
			win.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
		end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
	end)
end

-- [/HEADER]
-- [FILTERS]
-- ===== left: filters + player list ==========================================
local LEFT_W = 312
local leftH = H - HD - 12
local left = frame(win, 12, HD, LEFT_W, leftH, "inner", .35, 10, "edge", 1, .75)

U.search = input(left, "Search player…", 10, 10, 220, 30, 10)
U.count = label(left, "", 8.5, "sub", 236, 10, 66, 30, { TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center })

local chipLabels = { headless = "Headless", korblox = "Korblox", crown = "8-Bit Crown", opal = "Opal", limited = "Any limited" }
local CHIP_AT = { headless = { 10, 50, 92 }, korblox = { 108, 50, 92 }, crown = { 206, 50, 96 },
	limited = { 10, 84, 96 }, opal = { 112, 84, 62 } }
local STATE_NAME = { "off", "can have", "needs", "excluded" }
local STATE_GLYPH = { "", " •", " ✓", " ×" }

local tip = frame(win, 0, 0, 262, 108, "panel", .04, 8, "accent", 1, .35)
tip.Visible, tip.ZIndex = false, 10
local tipTitle = label(tip, "", 9, "text", 9, 6, 244, 14)
local tipBody = label(tip, "Click a chip to cycle it:\n• can have — at least one • chip must match\n✓ needs — every ✓ chip must be worn\n× excluded — must not be worn\nno mark — ignored", 8, "sub", 9, 22, 244, 80, { TextWrapped = true })

-- 0 off · 1 can have (accent text + dot) · 2 needs (accent fill, thick border) · 3 excluded (faded + ×)
local function paintChip(b, state)
	b:SetAttribute("adState", state)
	paint(b, "BackgroundColor3", state == 2 and "accent" or "ctrlOff")
	b.BackgroundTransparency = state == 2 and .1 or (state == 1 and .05 or (state == 3 and .55 or .25))
	b:SetAttribute("adTr", b.BackgroundTransparency)
	paint(b, "TextColor3", state == 2 and "onAccent" or (state == 1 and "accentText" or (state == 3 and "hint" or "text")))
	b.Font = state == 2 and FONT_B or FONT
	local s = b:FindFirstChildOfClass("UIStroke")
	if s then
		s.Thickness = state == 2 and 2 or 1
		s.Transparency = state == 3 and .9 or ((state == 1 or state == 2) and .15 or .7)
		paint(s, "Color", (state == 1 or state == 2) and "accent" or "edge")
	end
	local dot = b:FindFirstChild("adDot")
	if dot then dot.Visible = state == 1 end
end

local chips = {}
for _, key in ipairs(ITEM_KEYS) do
	local at = CHIP_AT[key]
	local b = button(left, chipLabels[key], at[1], at[2], at[3], 26, "off", nil, 8)
	local dot = Instance.new("Frame")
	dot.Name = "adDot"
	dot.AnchorPoint = Vector2.new(1, 0)
	dot.Position = UDim2.new(1, -7, 0, 6)
	dot.Size = UDim2.fromOffset(7, 7)
	dot.BorderSizePixel = 0
	dot.Visible = false
	dot.Parent = b
	local dc = Instance.new("UICorner", dot); dc.CornerRadius = UDim.new(1, 0)
	paint(dot, "BackgroundColor3", "accent")
	local function show(st, quiet)
		F.items[key] = st
		paintChip(b, st)
		b.Text = chipLabels[key] .. STATE_GLYPH[st + 1]
		tipTitle.Text = chipLabels[key] .. "  ·  " .. STATE_NAME[st + 1]
		if not quiet then schedule() end
	end
	b.MouseButton1Click:Connect(function()
		show(((b:GetAttribute("adState") or 0) + 1) % 4)
	end)
	show(0, true)
	chips[key] = b
	b.MouseEnter:Connect(function()
		tipTitle.Text = chipLabels[key] .. "  ·  " .. STATE_NAME[(b:GetAttribute("adState") or 0) + 1]
		tip.Position = UDim2.fromOffset(12 + b.Position.X.Offset, HD + b.Position.Y.Offset + b.Size.Y.Offset + 4)
		tip.Visible = true
	end)
	b.MouseLeave:Connect(function() tip.Visible = false end)
end

U.female = button(left, "Female", 180, 84, 66, 26, "off", function()
	F.female = not F.female
	setKind(U.female, F.female and "on" or "off")
	schedule()
end, 9)
U.skin = button(left, "Skin", 252, 84, 50, 26, "off", function()
	F.skin = not F.skin
	setKind(U.skin, F.skin and "on" or "off")
	schedule()
end, 9)

U.keyword = input(left, "Keyword in worn items (girl, doll…)", 10, 118, 292, 28, 9)
U.keyword:GetPropertyChangedSignal("Text"):Connect(function()
	F.keyword = U.keyword.Text:match("^%s*(.-)%s*$")
	schedule()
end)

U.lumLbl = label(left, "Min skin brightness", 9, "text", 10, 154, 150, 16)
U.lumVal = label(left, ("%d%%"):format(math.floor(F.min * 100 + .5)), 8.5, "sub", 176, 154, 126, 16, { TextXAlignment = Enum.TextXAlignment.Right })
slider(left, 10, 174, 292, 0, 100, 1, function() return F.min * 100 end, function(v)
	F.min = v / 100
	U.lumVal.Text = math.floor(v + .5) .. "%"
	if F.skin then schedule() end
end)
U.hint = label(left, "Skips anyone darker than this.", 8, "hint", 10, 200, 292, 24, { TextWrapped = true })

U.list = scroller(left, 0, 230, LEFT_W, leftH - 238)
local listLayout = Instance.new("UIListLayout", U.list)
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
local listPad = Instance.new("UIPadding", U.list)
listPad.PaddingLeft = UDim.new(0, 10); listPad.PaddingRight = UDim.new(0, 10)

-- [/FILTERS]
-- [RIGHT]
-- ===== right: 3D preview, details, actions, worn items =====================
local RX = 336
local RW = W - RX - 12
local right = frame(win, RX, HD, RW, leftH, "inner", .35, 10, "edge", 1, .75)

local pvWrap = frame(right, 12, 12, 196, 300, "row", .7, 10, "edge", 1, .6)
local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.fromScale(1, 1)
vp.BackgroundTransparency = 1
vp.Ambient = rgb(180, 180, 190)
vp.LightColor = rgb(255, 255, 255)
vp.LightDirection = Vector3.new(-1, -1, -1)
vp.Parent = pvWrap
local world = Instance.new("WorldModel", vp)
local camera = Instance.new("Camera")
camera.FieldOfView = 40
camera.Parent = vp
vp.CurrentCamera = camera
-- 3D preview controls: left drag = orbit, middle drag = pan, scroll = zoom, right click = reset view
local P3 = { yaw = 0, pitch = 0, pan = Vector3.zero, dist = 6, d0 = 6, target = Vector3.zero }
U.pv3 = P3
function U.pvUpdate()
	local rot = CFrame.Angles(0, P3.yaw, 0) * CFrame.Angles(P3.pitch, 0, 0)
	local center = P3.target + P3.pan
	camera.CFrame = CFrame.lookAt(center + rot:VectorToWorldSpace(Vector3.new(0, 0, -P3.dist)), center)
end
function U.pvReset()
	P3.yaw, P3.pitch, P3.pan, P3.dist = 0, 0, Vector3.zero, P3.d0
	U.pvUpdate()
end
local pvHit = Instance.new("TextButton") -- invisible overlay: always receives clicks and the wheel, and sinks them so the game camera does not zoom behind the window
pvHit.Size = UDim2.fromScale(1, 1)
pvHit.BackgroundTransparency = 1
pvHit.Text = ""
pvHit.AutoButtonColor = false
pvHit.ZIndex = 20
pvHit.Parent = pvWrap
local RunService = game:GetService("RunService")
local pvDrag, pvLast -- "orbit" | "pan" while a button is held that started on the preview; pvLast = mouse position at the last frame
local function pvStart(mode) pvDrag, pvLast = mode, UserInputService:GetMouseLocation() end
pvHit.MouseButton1Down:Connect(function() pvStart("orbit") end)
pvHit.InputBegan:Connect(function(i)
	local t = i.UserInputType
	if t == Enum.UserInputType.MouseButton1 then pvStart("orbit")
	elseif t == Enum.UserInputType.MouseButton3 then pvStart("pan")
	elseif t == Enum.UserInputType.MouseButton2 then U.pvReset() end
end)
pvHit.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseWheel then
		P3.dist = math.clamp(P3.dist * (1 - i.Position.Z * .1), P3.d0 * .25, P3.d0 * 3)
		U.pvUpdate()
	end
end)
-- the drag is read from the mouse position every frame (not from InputChanged.Delta, which is 0 on some executors) and ends when the button is up
conn(RunService.RenderStepped, function()
	if not pvDrag then return end
	local btn = pvDrag == "pan" and Enum.UserInputType.MouseButton3 or Enum.UserInputType.MouseButton1
	if not UserInputService:IsMouseButtonPressed(btn) then pvDrag = nil return end
	local now = UserInputService:GetMouseLocation()
	local d = now - pvLast
	pvLast = now
	if d.X == 0 and d.Y == 0 then return end
	if pvDrag == "orbit" then
		P3.yaw = P3.yaw - d.X * .01
		P3.pitch = math.clamp(P3.pitch + d.Y * .01, -1.4, 1.4)
	else
		local k, cf = P3.dist * .0024, camera.CFrame
		P3.pan = P3.pan - cf.RightVector * d.X * k + cf.UpVector * d.Y * k
	end
	U.pvUpdate()
end)
U.pvImg = Instance.new("ImageLabel")
U.pvImg.Size = UDim2.fromScale(1, 1)
U.pvImg.BackgroundTransparency = 1
U.pvImg.ScaleType = Enum.ScaleType.Fit
U.pvImg.ImageTransparency = .35
U.pvImg.Visible = false
U.pvImg.Parent = pvWrap
U.pvNote = label(pvWrap, "", 8, "hint", 6, 276, 184, 20, { TextXAlignment = Enum.TextXAlignment.Center })

local dw = RW - 232
local dx = 220
U.dn = label(right, "No player selected", 14, "text", dx, 12, dw, 36, { Font = FONT_B, TextWrapped = true })
U.un = label(right, "", 9, "sub", dx, 50, dw, 14)
U.meta = label(right, "", 8, "hint", dx, 68, dw, 14)
U.id = label(right, "", 8.5, "sub", dx, 88, dw, 14)
U.team = label(right, "", 8.5, "sub", dx, 106, dw, 14)
U.dist = label(right, "", 8.5, "sub", dx, 124, dw, 14)
U.skinSw = frame(right, dx, 148, 12, 12, "row", 0, 3)
U.skinL = label(right, "", 8.5, "sub", dx + 18, 146, dw - 18, 14)
U.tags = label(right, "", 8.5, "accentText", dx, 166, dw, 130, { TextWrapped = true })

local actions = {}
local actionDefs = {
	{ key = "esp", label = "ESP" },
	{ key = "goto", label = "Go to" },
	{ key = "view", label = "View" },
	{ key = "listen", label = "Listen" },
	{ key = "hide", label = "Hide" },
	{ key = "profile", label = "Profile" },
}
for i, a in ipairs(actionDefs) do
	local col = (i - 1) % 3
	local row = math.floor((i - 1) / 3)
	actions[a.key] = button(right, a.label, 12 + col * 131, 324 + row * 32, 125, 26, "off", function()
		M.action(a.key)
	end, 9)
end

U.itemsHead = label(right, "WORN ITEMS", 8, "sub", 12, 386, 200, 14, { Font = FONT_B })
U.items = scroller(right, 0, 404, RW, 92)
local itemLayout = Instance.new("UIListLayout", U.items)
itemLayout.Padding = UDim.new(0, 2)
local itemPad = Instance.new("UIPadding", U.items)
itemPad.PaddingLeft = UDim.new(0, 12); itemPad.PaddingRight = UDim.new(0, 12)

-- [/RIGHT]
-- [LIST]
-- ===== filtering + list =====================================================
local queued = false
function schedule()
	if queued then return end
	queued = true
	task.delay(.2, function() -- coalesce bursts of catalog lookups into one redraw
		queued = false
		if M.visible then renderList() end
	end)
end

local function tagLine(e)
	if not e or not e.desc then return "reading avatar…" end
	local parts = {}
	for _, k in ipairs(ITEM_KEYS) do if e.tags[k] then parts[#parts + 1] = k == "crown" and "8-BIT" or k:upper() end end
	if e.tags.female then parts[#parts + 1] = "FEMALE" end
	if #parts == 0 then return "no tagged items" end
	return table.concat(parts, "  ·  ")
end

local function rowClicked(p)
	selectPlayer(p)
end

function renderList()
	if not M.visible then return end
	clear(U.list)
	local q = F.query:lower()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local nameOk = q == "" or p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)
		if nameOk and filterMatch(cache[p.UserId], F) then list[#list + 1] = p end
	end
	table.sort(list, function(a, b)
		local an, bn = a.DisplayName:lower(), b.DisplayName:lower()
		if an == bn then return a.Name:lower() < b.Name:lower() end
		return an < bn
	end)
	for i, p in ipairs(list) do
		local e = cache[p.UserId]
		local r = Instance.new("TextButton")
		r.Text = ""
		r.AutoButtonColor = false
		r.BorderSizePixel = 0
		r.Size = UDim2.new(1, 0, 0, 48)
		r.LayoutOrder = i
		r.BackgroundTransparency = .78
		r.Parent = U.list
		paint(r, "BackgroundColor3", "row")
		local rc = Instance.new("UICorner", r); rc.CornerRadius = UDim.new(0, 8)
		local rs = Instance.new("UIStroke", r)
		rs.Thickness = 1; rs.Transparency = .65; rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		paint(rs, "Color", p == selected and "accent" or "edge")
		if p == selected then rs.Transparency = .15 end
		local av = Instance.new("ImageLabel")
		av.Position = UDim2.fromOffset(6, 7)
		av.Size = UDim2.fromOffset(34, 34)
		av.BackgroundTransparency = .85
		av.Image = thumb("AvatarHeadShot", p.UserId, 150)
		av.Parent = r
		paint(av, "BackgroundColor3", "row")
		local ac = Instance.new("UICorner", av); ac.CornerRadius = UDim.new(1, 0)
		label(r, p.DisplayName .. (p == lp and "  (you)" or ""), 9.5, "text2", 48, 6, LEFT_W - 80, 15, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
		label(r, "@" .. p.Name, 8, "sub", 48, 22, LEFT_W - 80, 12, { TextTruncate = Enum.TextTruncate.AtEnd })
		label(r, tagLine(e), 7.5, (e and e.tags and (e.tags.headless or e.tags.korblox or e.tags.crown or e.tags.opal or e.tags.female)) and "accentText" or "hint", 48, 34, LEFT_W - 90, 11, { Font = FONT_B, TextTruncate = Enum.TextTruncate.AtEnd })
		r.MouseEnter:Connect(function() r.BackgroundTransparency = .68 end)
		r.MouseLeave:Connect(function() r.BackgroundTransparency = .78 end)
		r.MouseButton1Click:Connect(function() rowClicked(p) end)
	end
	if #list == 0 then
		label(U.list, "No players match.", 9.5, "sub", 10, 12, LEFT_W - 40, 20)
	end
	U.list.CanvasSize = UDim2.fromOffset(0, math.max(#list, 1) * 52 + 6)
	U.count.Text = ("%d / %d"):format(#list, #Players:GetPlayers())
	refreshActions()
end

-- [/LIST]
-- [DETAILS]
-- ===== details, preview and worn items =====================================
local function clearPreview()
	for _, c in ipairs(world:GetChildren()) do c:Destroy() end
end

local function cloneChar(p) -- the avatar as it is in the server right now: instant, no downloads
	local ch = p.Character
	if not (ch and ch:FindFirstChild("HumanoidRootPart")) then return nil end
	local was = ch.Archivable
	pcall(function() ch.Archivable = true end)
	local ok, m = pcall(function() return ch:Clone() end)
	pcall(function() ch.Archivable = was end)
	if not (ok and m) then return nil end
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BaseScript") or d:IsA("Sound") or d:IsA("BillboardGui") then d:Destroy()
		elseif d:IsA("BasePart") then d.Anchored = true end
	end
	return m
end

local function showModel(p, model)
	clearPreview()
	model:PivotTo(CFrame.new())
	model.Parent = world
	U.pvImg.Visible = false
	U.pvNote.Text = "drag: rotate · middle: pan · wheel: zoom · right click: reset"
	local okB, cf, size = pcall(function() return model:GetBoundingBox() end)
	if not okB or not size then return end
	local dist = math.max(size.Y * 1.35, size.X * 2.15, size.Z * 2.15, 6)
	local target = cf.Position + Vector3.new(0, size.Y * .02, 0)
	local same = U.pv3.uid == p.UserId -- the same player rebuilt: keep the view you set
	U.pv3.uid, U.pv3.target, U.pv3.d0 = p.UserId, target, dist
	if same then U.pvUpdate() else U.pvReset() end
end

function buildPreview(p, e)
	if not p then
		clearPreview()
		U.pvImg.Visible = false
		U.pvNote.Text = ""
		return
	end
	local tok = (U.pvTok or 0) + 1
	U.pvTok = tok
	local model = cloneChar(p)
	if model then return showModel(p, model) end
	-- not in range / not loaded: show the flat picture right away, build the 3D model from the description in the background
	clearPreview()
	U.pvImg.Image = thumb("Avatar", p.UserId, 420)
	U.pvImg.Visible = true
	if not (e and e.desc) then
		U.pvNote.Text = e and e.status or "loading avatar…"
		return
	end
	U.pvNote.Text = "loading 3D…"
	task.spawn(function()
		local ok, m = pcall(function()
			return Players:CreateHumanoidModelFromDescription(e.desc, e.rig or Enum.HumanoidRigType.R15)
		end)
		if M.dead or U.pvTok ~= tok then if ok and m then m:Destroy() end return end -- another player was picked meanwhile
		if ok and m then showModel(p, m) else U.pvNote.Text = "3D preview unavailable" end
	end)
end

local function playerDistance(p)
	local mine = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	local theirs = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if mine and theirs then return math.floor((mine.Position - theirs.Position).Magnitude + .5) .. " studs" end
	return "out of range"
end

function showDetails(p)
	if not p then
		U.dn.Text = "No player selected"
		U.un.Text = ""; U.meta.Text = ""; U.id.Text = ""; U.team.Text = ""; U.dist.Text = ""
		U.skinL.Text = ""; U.skinSw.BackgroundColor3 = col("row")
		U.tags.Text = ""
		buildPreview(nil)
		return
	end
	local e = cache[p.UserId]
	local tags = (e and e.tags) or {}
	local words = (e and e.words) or {}
	U.dn.Text = p.DisplayName .. (p == lp and "  (you)" or "")
	U.un.Text = "@" .. p.Name
	U.meta.Text = e and e.status or (e and e.desc) and ((e.rig == Enum.HumanoidRigType.R6 and "R6" or "R15") .. "  ·  " .. #e.ids .. " worn") or "reading avatar…"
	U.id.Text = "ID  " .. p.UserId
	U.team.Text = "Team  " .. (p.Team and p.Team.Name or "None")
	U.dist.Text = "Distance  " .. playerDistance(p)
	if e and e.lum then
		U.skinSw.BackgroundColor3 = Color3.new(e.lum, e.lum, e.lum)
		U.skinL.Text = ("Skin brightness %d%%"):format(math.floor(e.lum * 100 + .5))
	else
		U.skinSw.BackgroundColor3 = col("row")
		U.skinL.Text = "Skin brightness —"
	end
	local t = {}
	if e and e.desc then
		local got = {}
		for _, k in ipairs(ITEM_KEYS) do if tags[k] then got[#got + 1] = k == "crown" and "8-BIT CROWN" or k:upper() end end
		if tags.female then got[#got + 1] = "FEMALE" end
		if #got > 0 then t[#t + 1] = table.concat(got, "\n") end
		if #words > 0 then t[#t + 1] = "Keywords: " .. table.concat(words, ", ") end
		if #t == 0 then t[#t + 1] = "No tags detected." end
	else
		t[#t + 1] = e and (e.status or "Reading worn items…") or "Open the list to read avatars."
	end
	U.tags.Text = table.concat(t, "\n\n")
end

function renderItems(p)
	clear(U.items)
	if not p then U.itemsHead.Text = "WORN ITEMS"; return end
	local e = cache[p.UserId]
	local ids = e and e.ids or {}
	U.itemsHead.Text = "WORN ITEMS  ·  " .. (e and e.desc and tostring(#ids) or "…")
	if not e or not e.desc then
		label(U.items, e and e.status or "Reading avatar…", 8.5, "sub", 0, 6, RW - 30, 18)
		return
	end
	if #ids == 0 then
		label(U.items, "No worn items reported.", 8.5, "sub", 0, 6, RW - 30, 18)
		return
	end
	local rows = {}
	for _, id in ipairs(ids) do
		local nm = product[id] or nil
		rows[#rows + 1] = { id = id, nm = nm }
	end
	table.sort(rows, function(a, b)
		local an = (a.nm or ("Asset " .. a.id)):lower()
		local bn = (b.nm or ("Asset " .. b.id)):lower()
		return an < bn
	end)
	for i, r in ipairs(rows) do
		local row = Instance.new("TextButton")
		row.Text = ""
		row.AutoButtonColor = false
		row.BorderSizePixel = 0
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 24)
		row.LayoutOrder = i
		row.Parent = U.items
		local img = Instance.new("ImageLabel")
		img.Position = UDim2.fromOffset(0, 2)
		img.Size = UDim2.fromOffset(20, 20)
		img.BackgroundTransparency = 1
		img.Image = thumb("Asset", r.id, 110)
		img.Parent = row
		local tag = KNOWN[r.id]
		if not tag and r.nm then
			local t = classifyNames({ r.nm })
			for _, k in ipairs(ITEM_KEYS) do if t[k] then tag = k; break end end
		end
		label(row, r.nm or ("Asset " .. r.id), 8, tag and "accentText" or "text2", 26, 4, RW - 150, 16, { TextTruncate = Enum.TextTruncate.AtEnd })
		if tag then
			label(row, tag == "crown" and "8-BIT CROWN" or tag:upper(), 7.5, "sub", RW - 140, 4, 110, 16, { Font = FONT_B, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd })
		end
	end
	U.items.CanvasSize = UDim2.fromOffset(0, #rows * 26 + 4)
end

-- [/DETAILS]
-- [ACTIONS]
-- ===== actions ==============================================================
local esp = {}
local soloView, soloPrev

local function isViewing(p)
	if K then return K.ctx and K.ctx.state and K.ctx.state.viewing == p end
	return soloView == p
end
local function isListening(p)
	return K and K.ctx and K.ctx.state and K.ctx.state.listen[p.UserId] ~= nil
end
local function isHidden(p)
	return K and K.ctx and K.ctx.isHidden and K.ctx.isHidden(p.UserId)
end

local function toast(msg)
	if K and K.ctx and K.ctx.notify then pcall(K.ctx.notify, msg, 4) return end
	U.pvNote.Text = tostring(msg)
	U.pvNote.TextColor3 = col("danger")
	task.delay(4, function() if U.pvNote.Text == tostring(msg) then U.pvNote.Text = ""; U.pvNote.TextColor3 = col("hint") end end)
end

function refreshActions()
	local p = selected
	local uid = p and p.UserId
	for _, k in ipairs({ "esp", "goto", "view", "listen", "hide", "profile" }) do
		local b = actions[k]
		b.Active = p ~= nil and not (k == "listen" and not K) and not (k == "hide" and not K)
		b.TextTransparency = b.Active and 0 or .5
	end
	if not p then
		for _, b in pairs(actions) do setKind(b, "off") end
		return
	end
	setKind(actions.esp, esp[uid] and "on" or "off")
	setKind(actions.goto, "off")
	setKind(actions.view, isViewing(p) and "on" or "off")
	actions.view.Text = isViewing(p) and "Unview" or "View"
	setKind(actions.listen, isListening(p) and "on" or "off")
	actions.listen.Text = isListening(p) and "Unlisten" or "Listen"
	local hidden = isHidden(p)
	setKind(actions.hide, hidden and "on" or "off")
	actions.hide.Text = hidden and "Unhide" or "Hide"
	setKind(actions.profile, "off")
end

local function espPaint(rec)
	for _, o in ipairs(rec.objs) do pcall(function() o:Destroy() end) end
	rec.objs = {}
	local p = rec.player
	local c = p.Character
	local head = c and c:FindFirstChild("Head")
	if not (c and head) then return end
	local hl = Instance.new("Highlight")
	hl.Name = "_adEsp"
	hl.FillColor = ACCENT
	hl.FillTransparency = .7
	hl.OutlineColor = ACCENT
	hl.Parent = c
	local bb = Instance.new("BillboardGui")
	bb.Name = "_adEspTag"
	bb.Size = UDim2.fromOffset(120, 20)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.Adornee = head
	bb.Parent = c
	local tl = Instance.new("TextLabel", bb)
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = ACCENT
	tl.TextStrokeTransparency = 0
	tl.Text = p.Name
	rec.objs = { hl, bb }
end

local function espOff(uid)
	local rec = esp[uid]
	if not rec then return end
	if rec.conn then pcall(function() rec.conn:Disconnect() end) end
	for _, o in ipairs(rec.objs) do pcall(function() o:Destroy() end) end
	esp[uid] = nil
end

local function espToggle(p)
	if esp[p.UserId] then espOff(p.UserId); return end
	local rec = { player = p, objs = {} }
	esp[p.UserId] = rec
	espPaint(rec)
	rec.conn = p.CharacterAdded:Connect(function()
		task.wait(.5)
		if esp[p.UserId] == rec then espPaint(rec) end
	end)
end

function M.action(kind, p)
	p = p or selected
	if not p then return end
	local uid = p.UserId
	if kind == "esp" then
		if not (p.Character and p.Character:FindFirstChild("Head")) then toast(p.Name .. " is not loaded") return end
		espToggle(p)
	elseif kind == "goto" then
		if K then
			K.ctx.Run("goto " .. p.Name)
		else
			local mine = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
			local theirs = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if mine and theirs then
				mine.CFrame = theirs.CFrame * CFrame.new(0, 0, 3)
			else
				toast(p.Name .. " is not loaded")
			end
		end
	elseif kind == "view" then
		if K then
			if K.ctx.state.viewing == p then K.ctx.Run("unview") else K.ctx.Run("view " .. p.Name) end
		else
			local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			local cam = workspace.CurrentCamera
			if soloView == p then
				if soloPrev then cam.CameraSubject = soloPrev end
				soloView, soloPrev = nil, nil
			elseif not h then
				toast(p.Name .. " is not loaded")
			else
				if not soloView then soloPrev = cam.CameraSubject end
				soloView = p
				cam.CameraSubject = h
			end
		end
	elseif kind == "listen" then
		if not K then toast("Listen needs RoSaD (voice routing)") return end
		local st = K.ctx.state
		local on = st.listen[uid] == nil
		local wasMuted = on and st.muted[uid] ~= nil
		if wasMuted then K.ctx.setMuted(uid, false) end
		local ok, why = K.ctx.setListen(uid, on)
		if on and not ok then
			if wasMuted then K.ctx.setMuted(uid, true) end
			toast(why or "Could not listen to " .. p.Name)
		end
	elseif kind == "hide" then
		if not K then toast("Hide needs RoSaD") return end
		K.ctx.Run((isHidden(p) and "unhide " or "hide ") .. p.Name)
	elseif kind == "profile" then
		if K and K.ui and K.ui.openProfile then
			K.ui.openProfile(p)
		elseif GuiService and pcall(function() return GuiService:InspectPlayerFromUserId(uid) end) then
			-- Roblox's own inspect window
		else
			toast("No profile window available")
		end
	end
	task.delay(.15, function()
		if M.visible then refreshActions() end
		if selected == p then showDetails(p) end
	end)
end

function selectPlayer(p)
	selected = p
	prioritize((cache[p.UserId] or {}).ids)
	showDetails(p)
	local e = cache[p.UserId]
	if e and e.desc then
		buildPreview(p, e)
	else
		buildPreview(p, e)
		analyze(p)
	end
	renderItems(p)
	renderList()
end

function M.refreshAll()
	for _, p in ipairs(Players:GetPlayers()) do
		watchPlayer(p)
		analyze(p, true)
	end
	showDetails(selected)
	renderItems(selected)
	schedule()
end

-- [/ACTIONS]
-- [LIFE]
-- ===== lifecycle + rOSAD integration =======================================
U.search:GetPropertyChangedSignal("Text"):Connect(function()
	F.query = U.search.Text
	schedule()
end)

conn(Players.PlayerAdded, function(p)
	if not M.visible then return end
	watchPlayer(p)
	analyze(p)
	schedule()
end)
conn(Players.PlayerRemoving, function(p)
	espOff(p.UserId)
	if charCons[p.UserId] then pcall(function() charCons[p.UserId]:Disconnect() end); charCons[p.UserId] = nil end
	cache[p.UserId] = nil
	if soloView == p then
		local cam = workspace.CurrentCamera
		if soloPrev then cam.CameraSubject = soloPrev end
		soloView, soloPrev = nil, nil
	end
	if selected == p then
		selected = nil
		showDetails(nil)
		renderItems(nil)
	end
	schedule()
end)

local unsubLook, unsubUnload
if K then
	if K.ctx and K.ctx.bus then
		unsubLook = K.ctx.bus.on("look", function(s)
			if type(s) ~= "table" then return end
			themeName = s.theme == "Light" and "Light" or "Dark"
			if typeof(s.accent) == "Color3" then ACCENT = s.accent end
			accented()
			win.BackgroundColor3 = col("panel")
			win.BackgroundTransparency = 1 - (tonumber(s.opacity) or .88)
			winScale.Scale = tonumber(s.scale) or winScale.Scale
			winStroke.Color = ACCENT
			applyTheme()
			renderList()
		end)
		unsubUnload = K.ctx.bus.on("unload", function() M.Unload() end)
	end
	if K.ctx and K.ctx.register and not (K.ctx.Meta and K.ctx.Meta.avatars) then -- rOSAD 1.2+ owns ;avatars itself; this is for older builds
		pcall(K.ctx.register, function()
			return {
				names = { "avatars", "avatar" },
				args = "[refresh]",
				desc = "Avatar discovery: filter players by accessories, female keywords and skin brightness, preview their 3D avatar",
				tags = "avatar accessories headless korblox 8-bit crown opal female doll skin brightness luminance preview player list discover",
				run = function(a)
					if M.dead then return end
					if a == "refresh" then M.open(); M.refreshAll()
					elseif a == "close" then M.close()
					else M.toggle() end
				end,
			}
		end)
	end
end

function M.open()
	if M.dead then return end
	M.visible = true
	win.Visible = true
	for _, p in ipairs(Players:GetPlayers()) do
		watchPlayer(p)
		analyze(p)
	end
	renderList()
	if selected then
		showDetails(selected)
		local e = cache[selected.UserId]
		buildPreview(selected, e)
		renderItems(selected)
	end
end

function M.close()
	M.visible = false
	win.Visible = false
end

function M.toggle()
	if M.visible then M.close() else M.open() end
end

function M.Unload()
	if M.dead then return end
	M.dead, M.visible = true, false
	if soloView then
		local cam = workspace.CurrentCamera
		if soloPrev then cam.CameraSubject = soloPrev end
		soloView, soloPrev = nil, nil
	end
	for uid in pairs(esp) do espOff(uid) end
	for _, c in ipairs(cons) do pcall(function() c:Disconnect() end) end
	for uid, c in pairs(charCons) do pcall(function() c:Disconnect() end); charCons[uid] = nil end
	if unsubLook then pcall(unsubLook) end
	if unsubUnload then pcall(unsubUnload) end
	pcall(function() gui:Destroy() end)
	if env.AvatarDiscovery == M then env.AvatarDiscovery = nil end
end

-- ===== self-check of the pure logic ========================================
-- [/LIFE]
-- [SELFTEST]
function M.selftest()
	local tags, words = classifyNames({ "8-Bit Royal Crown", "Headless Head", "Cute Doll Hair", "Korblox Deathspeaker Right Leg" })
	assert(tags.crown and tags.headless and tags.korblox and tags.female)
	assert(words.doll)
	local e = { tags = { headless = true, female = true }, words = { "doll" }, namesList = { "Cute Doll Hair" }, lum = .4 }
	assert(filterMatch(e, { items = { headless = 2 } })) -- needs, has it
	assert(not filterMatch(e, { items = { korblox = 2 } })) -- needs, lacks it
	assert(filterMatch(e, { items = { headless = 1, korblox = 1 } })) -- can have: one dotted hit
	assert(not filterMatch(e, { items = { korblox = 1, opal = 1 } })) -- can have: no dotted hit
	assert(filterMatch(e, { items = { headless = 2, korblox = 1 } })) -- needs + can have
	e.tags.opal = true
	assert(not filterMatch(e, { items = { headless = 3 } })) -- excluded, has it
	assert(filterMatch(e, { items = { korblox = 3 } })) -- excluded, lacks it
	e.tags.opal = nil
	assert(filterMatch(e, { items = { headless = 2 } }))
	e.tags.korblox = true
	assert(filterMatch(e, { items = { headless = 2, korblox = 2 } })) -- needs both
	assert(not filterMatch(e, { items = { headless = 2, opal = 2 } })) -- opal missing
	assert(filterMatch(e, { items = { headless = 1, opal = 1 } })) -- at least one dotted hit
	assert(not filterMatch(e, { items = {}, female = false, keyword = "opal" }))
	assert(filterMatch(e, { items = {}, female = true, keyword = "doll" }))
	assert(filterMatch(e, { items = {}, skin = true, min = .3 }))
	assert(not filterMatch(e, { items = {}, skin = true, min = .5 }))
	e.lum = nil
	assert(not filterMatch(e, { items = {}, skin = true, min = .3 }))
	return true
end
-- [/SELFTEST]
-- [ENTRY]
local okTest, errTest = pcall(M.selftest)
if not okTest then warn("[AvatarDiscovery] self-test failed: " .. tostring(errTest)) end

M.open()
-- [/ENTRY]
