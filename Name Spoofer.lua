-- Name Spoofer + Others (client-side only)
local ENABLED      = true          -- spoof your own name
local CUSTOM_NAME  = "Player"
local SPOOF_OTHERS = true          -- rename other players
local OTHER_NAMES  = {"Pasta Hater"}

local env = getgenv()
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer

-- live toggles: getgenv().NameSpoof.Enabled / .Others / .Name
local cfg = env.NameSpoof
if cfg and cfg.Destroy then cfg.Destroy() end
cfg = {}
env.NameSpoof = cfg
cfg.Enabled, cfg.Name, cfg.Others = ENABLED, CUSTOM_NAME, SPOOF_OTHERS

local conns, originals, alive, busy = {}, setmetatable({}, {__mode = "k"}), true, false
local realSelf = {name = lp.Name, display = lp.DisplayName}
local others = {}      -- [player] = {name, display, fake}
local list = {}        -- flat replacement list {pattern, fake}

-- even distribution: always pick from the least-used names, random tie-break
local counts = {}
for _, n in ipairs(OTHER_NAMES) do counts[n] = 0 end
local function pickName()
	if #OTHER_NAMES == 0 then return nil end
	local min = math.huge
	for _, n in ipairs(OTHER_NAMES) do min = math.min(min, counts[n]) end
	local pool = {}
	for _, n in ipairs(OTHER_NAMES) do
		if counts[n] == min then pool[#pool + 1] = n end
	end
	local n = pool[math.random(#pool)]
	counts[n] = counts[n] + 1
	return n .. " #" .. counts[n]
end

local function esc(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

local function rebuild()
	table.clear(list)
	local function add(real, fake)
		if real and real ~= "" then
			list[#list + 1] = {real = real, pat = "%f[%w_]" .. esc(real) .. "%f[^%w_]", fake = fake}
		end
	end
	if cfg.Enabled then
		add(realSelf.name, cfg.Name); add(realSelf.display, cfg.Name)
	end
	if cfg.Others then
		for _, e in pairs(others) do add(e.name, e.fake); add(e.display, e.fake) end
	end
	table.sort(list, function(a, b) return #a.real > #b.real end)
end

local function spoofText(text)
	local out, hit = text, false
	for _, it in ipairs(list) do
		local r, c = out:gsub(it.pat, function() return it.fake end)
		if c > 0 then out, hit = r, true end
	end
	return out, hit
end

local function isText(i) return i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox") end

local function apply(inst)
	local new, hit = spoofText(inst.Text)
	if hit then
		originals[inst] = inst.Text
		busy = true; inst.Text = new; busy = false
	end
end

local function watch(inst)
	if not isText(inst) then return end
	if #list > 0 then apply(inst) end
	table.insert(conns, inst:GetPropertyChangedSignal("Text"):Connect(function()
		if not busy and #list > 0 then apply(inst) end
	end))
end

local function setHumanoids()
	local function set(plr, fake, real)
		local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if h then h.DisplayName = fake or real end
	end
	set(lp, cfg.Enabled and cfg.Name, realSelf.display)
	for plr, e in pairs(others) do set(plr, cfg.Others and e.fake, e.display) end
end

local roots = {CoreGui, lp:WaitForChild("PlayerGui")}
local function refresh()
	rebuild()
	busy = true
	for _, root in ipairs(roots) do
		for _, d in ipairs(root:GetDescendants()) do
			if isText(d) then
				if originals[d] then d.Text = originals[d] end
				apply(d)
			end
		end
	end
	busy = false
	setHumanoids()
end

-- player tracking
local function track(plr)
	if plr == lp or others[plr] then return end
	local fake = pickName()
	if not fake then return end
	others[plr] = {name = plr.Name, display = plr.DisplayName, fake = fake}
	table.insert(conns, plr.CharacterAdded:Connect(function(c)
		c:WaitForChild("Humanoid", 5)
		if cfg.Others and others[plr] then setHumanoids() end
	end))
end
for _, p in ipairs(Players:GetPlayers()) do track(p) end
table.insert(conns, Players.PlayerAdded:Connect(function(p) track(p); refresh() end))
table.insert(conns, Players.PlayerRemoving:Connect(function(p) others[p] = nil; rebuild() end))
table.insert(conns, lp.CharacterAdded:Connect(function(c)
	c:WaitForChild("Humanoid", 5); setHumanoids()
end))

for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do watch(d) end
	table.insert(conns, root.DescendantAdded:Connect(watch))
end

-- lookup used by the __index hook (game scripts reading .Name / .DisplayName)
cfg.lookup = function(inst)
	if inst == lp then
		if cfg.Enabled then return cfg.Name end
	elseif cfg.Others then
		local e = others[inst]
		if e then return e.fake end
	end
end

if hookmetamethod and newcclosure and checkcaller and not env.__NameSpoofHooked then
	env.__NameSpoofHooked = true
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if (key == "Name" or key == "DisplayName") and not checkcaller() then
			local c = env.NameSpoof
			local f = c and c.lookup and c.lookup(self)
			if f then return f end
		end
		return oldIndex(self, key)
	end))
end

refresh()
task.spawn(function()
	local lE, lN, lO = cfg.Enabled, cfg.Name, cfg.Others
	while alive do
		if cfg.Enabled ~= lE or cfg.Name ~= lN or cfg.Others ~= lO then
			lE, lN, lO = cfg.Enabled, cfg.Name, cfg.Others
			refresh()
		end
		task.wait(0.2)
	end
end)

cfg.Destroy = function()
	alive = false
	cfg.Enabled, cfg.Others = false, false
	refresh()
	for _, c in ipairs(conns) do c:Disconnect() end
end
