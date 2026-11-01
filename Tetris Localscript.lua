--[[
	TETRIS for Roblox - one self-contained client LocalScript (no modules, no assets, no server code).
	Layer 1 (LOGIC): pure rules, no Roblox APIs. Layer 2 (UI/INPUT): window, rendering, settings, focus.

	Spin rules (spinKind): a spin needs the LAST successful action to be a rotation (any move/drop clears it).
	  T piece : 3-corner rule. Corners = the 4 diagonal cells around the T centre; walls/floor/stack count as filled.
	            3+ filled and both "front" corners (the side the nose points to) filled -> full T-Spin.
	            3+ filled but only one front corner -> Mini, unless the 5th kick test (the 1x2 kick) was used -> full.
	  Others  : "immobile" rule (as TETR.IO). Piece cannot move left, right or up -> spin. All-Spin = full, All-Mini = mini.
	  O piece never spins. Spin mode (T-only / All-Spin / All-Mini) is a setting.
	Rotation: SRS+ (Guideline SRS kicks; I-piece kicks mirrored left/right as in TETR.IO). 180 rotation uses a separate kick table (K180).
]]

-- LOGIC BEGIN -----------------------------------------------------------------
local W, H, VIS, MAXRESET = 10, 40, 20, 15 -- 10x40 board (bottom 20 rows visible); lock-delay reset cap per piece
local NAMES = {"I", "O", "T", "S", "Z", "J", "L"}
local TI = {I = 1, O = 2, T = 3, S = 4, Z = 5, J = 6, L = 7}
local BASE = { -- spawn orientation as {col,row} inside the piece's bounding box
	I = {{0,1},{1,1},{2,1},{3,1}}, O = {{0,0},{1,0},{0,1},{1,1}}, T = {{1,0},{0,1},{1,1},{2,1}},
	S = {{1,0},{2,0},{0,1},{1,1}}, Z = {{0,0},{1,0},{1,1},{2,1}}, J = {{0,0},{0,1},{1,1},{2,1}}, L = {{2,0},{0,1},{1,1},{2,1}},
}
local SHAPE = {} -- SHAPE[type][rotation 0..3]; each step is one 90-degree clockwise turn: (col,row) -> (n-1-row, col)
for t, cells in pairs(BASE) do
	local n, cur = (t == "I" and 4) or (t == "O" and 2) or 3, cells
	SHAPE[t] = {}
	for r = 0, 3 do
		SHAPE[t][r] = cur
		local nx = {}
		for i, v in ipairs(cur) do nx[i] = {n - 1 - v[2], v[1]} end
		cur = nx
	end
end

-- Kick tables, {dx, dy} with y UP (the board's rows grow downward, so row = y - dy). Test 1 is always plain rotation.
local function mirror(list) local o = {} for i, k in ipairs(list) do o[i] = {-k[1], k[2]} end return o end
local function symmetric(t, links) for _, l in ipairs(links) do t[l[2]] = mirror(t[l[1]]) end return t end
local KJ = symmetric({ -- J L S T Z (Guideline SRS); the left-side tables are mirrors of the right-side ones
	["0>1"] = {{0,0},{-1,0},{-1,1},{0,-2},{-1,-2}}, ["1>0"] = {{0,0},{1,0},{1,-1},{0,2},{1,2}},
	["1>2"] = {{0,0},{1,0},{1,-1},{0,2},{1,2}},     ["2>1"] = {{0,0},{-1,0},{-1,1},{0,-2},{-1,-2}},
}, {{"0>1","0>3"},{"1>0","3>0"},{"1>2","3>2"},{"2>1","2>3"}})
local KI = symmetric({ -- I (SRS+): official SRS left-side tables, right side mirrored (TETR.IO's symmetric I kicks)
	["0>3"] = {{0,0},{-1,0},{2,0},{-1,2},{2,-1}}, ["3>0"] = {{0,0},{1,0},{-2,0},{1,-2},{-2,1}},
	["3>2"] = {{0,0},{-2,0},{1,0},{-2,-1},{1,2}}, ["2>3"] = {{0,0},{2,0},{-1,0},{2,1},{-1,-2}},
}, {{"0>3","0>1"},{"3>0","1>0"},{"3>2","1>2"},{"2>3","2>1"}})

-- 180 kicks (all pieces; TETR.IO-style 180 set, not verified against its exact table). shortcut: one table for I too, add an I table if it feels off.
local K180 = {
	["0>2"] = {{0,0},{0,1},{1,1},{-1,1},{1,0},{-1,0}}, ["2>0"] = {{0,0},{0,-1},{-1,-1},{1,-1},{-1,0},{1,0}},
	["1>3"] = {{0,0},{1,0},{1,2},{1,1},{0,2},{0,1}},   ["3>1"] = {{0,0},{-1,0},{-1,2},{-1,1},{0,2},{0,1}},
}

-- Scoring (TETR.IO solo table); attack is a LOCAL ESTIMATE (no opponent exists), see README note in the summary.
local PTS, SPTS, MPTS = {[0]=0,100,300,500,800}, {[0]=400,800,1200,1600,2600}, {[0]=100,200,400,800,1600}
local ATK, SATK, MATK = {[0]=0,0,1,2,4}, {[0]=0,2,4,6,10}, {[0]=0,0,1,2,4}
local CLEARN = {"SINGLE", "DOUBLE", "TRIPLE", "QUAD"}
local POINT = {[0]={0,-1},{1,0},{0,1},{-1,0}} -- T nose direction (dcol,drow) per rotation state

local function emptyRow() local r = {} for c = 1, W do r[c] = 0 end return r end

-- cfg (read live, so setting changes apply instantly): das/arr/lock/clear in ms, sdr rows/s (0 = instant), spin 1|2|3
local function newGame(cfg, rnd)
	local g, held, pend, act = {}, {}, {}, {}
	local hdir, hT, hDone, hFresh, gAcc, lockT, resets, lowest = nil, 0, 0, false, 0, 0, 0, 0
	local spawn, lock

	local function fits(t, r, x, y)
		for _, v in ipairs(SHAPE[t][r]) do
			local c, row = x + v[1], y + v[2]
			if c < 1 or c > W or row < 1 or row > H or g.board[row][c] ~= 0 then return false end
		end
		return true
	end
	local function free(dx, dy)
		local p = g.cur
		return fits(p.t, p.r, p.x + dx, p.y + dy)
	end
	local function refill() -- 7-bag
		while #g.queue < 7 do
			local b = {1, 2, 3, 4, 5, 6, 7}
			for i = 7, 2, -1 do local j = rnd(i); b[i], b[j] = b[j], b[i] end
			for i = 1, 7 do g.queue[#g.queue + 1] = NAMES[b[i]] end
		end
	end
	local function touch() -- after a successful move/rotation: lock-delay reset rules
		local p = g.cur
		if p.y > lowest then lowest, resets = p.y, 0 end -- new lowest row: reset allowance renews
		if not free(0, 1) and resets < MAXRESET then lockT, resets = 0, resets + 1 end
	end
	local function move(dx)
		if not free(dx, 0) then return false end
		g.cur.x, g.cur.spun = g.cur.x + dx, false
		return true
	end
	local function drop1()
		if not free(0, 1) then return false end
		g.cur.y, g.cur.spun = g.cur.y + 1, false
		return true
	end
	local function rotate(d)
		local p = g.cur
		if p.t == "O" then return end
		local nr = (p.r + d) % 4
		for i, k in ipairs((d == 2 and K180 or p.t == "I" and KI or KJ)[p.r .. ">" .. nr]) do
			if fits(p.t, nr, p.x + k[1], p.y - k[2]) then
				p.r, p.x, p.y, p.spun, p.kick = nr, p.x + k[1], p.y - k[2], true, d == 2 and 0 or i -- 180 kicks never count as the T-spin 5th-kick rule
				touch()
				return
			end
		end
	end
	local function spinKind(p) -- nil | "T" | "TM" | "S" | "SM"; called BEFORE the piece is written to the board
		if not p.spun or p.t == "O" then return nil end
		if p.t == "T" then
			local f, b, pv = 0, 0, POINT[p.r]
			for ox = -1, 1, 2 do
				for oy = -1, 1, 2 do
					local c, r = p.x + 1 + ox, p.y + 1 + oy
					if c < 1 or c > W or r < 1 or r > H or g.board[r][c] ~= 0 then
						if ox * pv[1] + oy * pv[2] > 0 then f = f + 1 else b = b + 1 end
					end
				end
			end
			if f + b < 3 then return nil end
			return (f == 2 or p.kick == 5) and "T" or "TM"
		end
		if cfg.spin == 1 or free(-1, 0) or free(1, 0) or free(0, -1) then return nil end
		return cfg.spin == 2 and "S" or "SM"
	end
	local function removeRows(rows)
		for i = #rows, 1, -1 do table.remove(g.board, rows[i]) end
		for _ = 1, #rows do table.insert(g.board, 1, emptyRow()) end
	end

	spawn = function(t)
		t = t or table.remove(g.queue, 1)
		refill()
		local p = {t = t, r = 0, x = t == "O" and 5 or 4, y = 19, spun = false}
		g.cur = p
		gAcc, lockT, resets = 0, 0, 0
		if not fits(t, 0, p.x, p.y) then g.cur, g.state = nil, "over" return end -- block out
		if free(0, 1) then p.y = p.y + 1 end
		lowest = p.y
		if hFresh and hdir then -- direction pressed during the line-clear delay: apply once at spawn
			if move(hdir == "left" and -1 or 1) then touch() end
		end
		hFresh = false
		local b = pend
		pend = {}
		for _, a in ipairs(b) do if g.cur then act[a]() end end -- buffered rotate/hold (IRS / IHS)
	end

	lock = function()
		local p = g.cur
		if not p then return end -- guards against duplicate locks
		local kind, out = spinKind(p), true
		for _, v in ipairs(SHAPE[p.t][p.r]) do
			local r = p.y + v[2]
			if r > H - VIS then out = false end
			g.board[r][p.x + v[1]] = TI[p.t]
		end
		g.cur, g.pieces = nil, g.pieces + 1
		local rows = {}
		for r = 1, H do
			local full = true
			for c = 1, W do if g.board[r][c] == 0 then full = false break end end
			if full then rows[#rows + 1] = r end
		end
		local n, mini = #rows, kind == "TM" or kind == "SM"
		local pts = (kind and (mini and MPTS or SPTS) or PTS)[n]
		local atk = (kind and (mini and MATK or SATK) or ATK)[n]
		local bonus = false
		if n > 0 then
			g.combo = g.combo + 1
			local hard = kind ~= nil or n >= 4 -- "difficult" clear for back-to-back
			bonus = hard and g.b2b > 0
			if bonus then pts, atk = pts * 1.5, atk + 1 end
			g.b2b = hard and g.b2b + 1 or 0
			if g.combo > 0 then -- TETR.IO multiplier combo: base*(1+0.25*combo), ln(1+1.25*combo) when base is 0
				pts = pts + 50 * g.combo
				if atk > 0 then atk = math.floor(atk * (1 + 0.25 * g.combo))
				elseif g.combo >= 2 then atk = math.floor(math.log(1 + 1.25 * g.combo)) end
			end
		else
			g.combo = -1
		end
		g.score, g.attack = g.score + math.floor(pts * g.level), g.attack + atk
		if kind or n > 0 then
			g.msg = (bonus and "B2B " or "") .. (kind and ((mini and "MINI " or "") .. p.t .. "-SPIN") or "")
				.. (kind and n > 0 and " " or "") .. (CLEARN[n] or "") .. (g.combo > 0 and "  x" .. g.combo or "")
			g.msgT = 2
		end
		g.lines = g.lines + n
		g.level, g.canHold = math.floor(g.lines / 10) + 1, true
		if out and n == 0 then g.state = "over" return end -- lock out
		if n > 0 and cfg.clear > 0 then
			g.state, g.rows, g.clearT = "clear", rows, cfg.clear / 1000
		else
			removeRows(rows)
			spawn()
		end
	end

	act.cw = function() rotate(1) end
	act.ccw = function() rotate(-1) end
	act.r180 = function() rotate(2) end
	act.hold = function()
		if not g.canHold then return end
		local old = g.hold
		g.canHold, g.hold = false, g.cur.t
		spawn(old)
	end
	act.hard = function()
		local n = 0
		while drop1() do n = n + 1 end
		g.score = g.score + 2 * n
		lock()
	end

	function g.press(a) -- executed immediately (no per-frame polling), so fast taps are never skipped
		if g.state == "over" then return end
		if a == "left" or a == "right" then
			held[a], hdir, hT, hDone = true, a, 0, 0
			if not g.cur then hFresh = true
			elseif move(a == "left" and -1 or 1) then touch() end
		elseif a == "soft" then held.soft = true
		elseif g.cur then act[a]()
		elseif a ~= "hard" and #pend < 4 then pend[#pend + 1] = a end
	end
	function g.release(a)
		held[a] = nil
		if a == hdir then -- the other direction (if still held) takes over with its DAS already charged
			local o = a == "left" and "right" or "left"
			if held[o] then hdir, hT, hDone = o, cfg.das / 1000, 0 else hdir = nil end
		end
	end

	function g.update(dt)
		if g.state == "over" then return end
		g.time, g.msgT = g.time + dt, g.msgT - dt
		local das, arr = cfg.das / 1000, cfg.arr / 1000
		if g.state == "clear" then
			if hdir then hT = math.min(hT + dt, das) end -- DAS keeps charging through the delay
			hDone = 0
			g.clearT = g.clearT - dt
			if g.clearT <= 0 then
				removeRows(g.rows)
				g.rows, g.state = nil, "play"
				spawn()
			end
			return
		end
		if not g.cur then return end
		if hdir then -- 1) horizontal DAS / ARR (bounded: at most 10 successful steps, never blocks the steps below)
			hT = hT + dt
			if hT >= das then
				local dx, moved = hdir == "left" and -1 or 1, false
				if arr <= 0 then
					while move(dx) do moved = true end
				else
					local due = math.floor((hT - das) / arr) + 1
					while hDone < due do
						hDone = hDone + 1
						if move(dx) then moved = true else hDone = due end
					end
				end
				if moved then touch() end
			end
		end
		local lv = math.min(g.level, 30) -- 2) gravity / soft drop (same frame as 1, so pieces never hover)
		local spr = math.max((0.8 - (lv - 1) * 0.007) ^ (lv - 1), 1e-4)
		if held.soft and cfg.sdr <= 0 then
			while drop1() do g.score = g.score + 1 end
			gAcc = 0
		else
			local iv = held.soft and math.min(spr, 1 / cfg.sdr) or spr
			gAcc = gAcc + dt
			while gAcc >= iv do
				if not drop1() then gAcc = 0 break end
				gAcc = gAcc - iv
				if held.soft then g.score = g.score + 1 end
			end
		end
		local p = g.cur -- 3) lock delay
		if p.y > lowest then lowest, resets = p.y, 0 end
		if free(0, 1) then
			if resets < MAXRESET then lockT = 0 end -- once resets are spent the timer keeps its progress
		else
			lockT = lockT + dt
			if lockT >= cfg.lock / 1000 then lock() end
		end
	end

	function g.ghost()
		local p, y = g.cur, g.cur.y
		while fits(p.t, p.r, p.x, y + 1) do y = y + 1 end
		return y
	end
	function g.apm() return g.time > 0 and g.attack * 60 / g.time or 0 end
	function g.pps() return g.time > 0 and g.pieces / g.time or 0 end
	function g.reset()
		g.board, g.queue, g.hold, g.cur, g.rows = {}, {}, nil, nil, nil
		for r = 1, H do g.board[r] = emptyRow() end
		g.score, g.lines, g.level, g.pieces, g.attack, g.time = 0, 0, 1, 0, 0, 0
		g.b2b, g.combo, g.msg, g.msgT, g.canHold, g.state = 0, -1, "", 0, true, "play"
		pend, hT, hDone, hFresh = {}, 0, 0, false
		refill()
		spawn()
	end
	g.reset()
	return g
end
-- LOGIC END -------------------------------------------------------------------

-- SELF-CHECK: runs once at load (pure logic, no UI). A failure only warns; it never stops the game. --------------
local function selfTest()
	local g = newGame({das = 100, arr = 0, sdr = 0, lock = 500, clear = 0, spin = 2}, function() return 1 end)
	assert(KI["0>1"][2][1] == 1 and KJ["0>3"][2][1] == 1, "kick tables")
	for r = 39, 40 do for c = 1, W do g.board[r][c] = 1 end end -- T-spin double: T rotates into a slot, 3 corners, 2 lines
	for _, c in ipairs({4, 5, 6}) do g.board[39][c] = 0 end
	g.board[40][5], g.board[38][4] = 0, 1
	g.cur = {t = "T", r = 3, x = 4, y = 38, spun = false}
	g.press("ccw"); g.press("hard")
	assert(g.lines == 2 and g.msg == "T-SPIN DOUBLE", "T-spin double")
	g.reset(); g.board[21][5] = 1 -- 180: plain turn blocked below, must take kick 2 (up one row)
	g.cur = {t = "T", r = 0, x = 4, y = 19, spun = false}
	g.press("r180")
	assert(g.cur.r == 2 and g.cur.y == 18 and g.cur.spun, "180 rotation + kick")
	g.reset(); g.press("right"); g.update(0.2) -- ARR 0: a single update must reach the wall
	local mx = 0
	for _, v in ipairs(SHAPE[g.cur.t][g.cur.r]) do mx = math.max(mx, g.cur.x + v[1]) end
	assert(mx == W, "instant ARR")
end

-- UI + INPUT (Roblox) ------------------------------------------------------------------------------------------
local Players, UIS, CAS = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("ContextActionService")
local RunService, GuiService = game:GetService("RunService"), game:GetService("GuiService")

if _G.TetrisCleanup then pcall(_G.TetrisCleanup) end -- re-running the script replaces the previous instance
local passed, why = pcall(selfTest)
if not passed then warn("[Tetris] self-check failed: " .. tostring(why)) end

local alive, conns = true, {}
local function on(signal, fn) conns[#conns + 1] = signal:Connect(fn) end

-- Settings (read live by the game). Keys are rebindable in the Options panel.
local cfg = {das = 167, arr = 33, sdr = 30, lock = 500, clear = 100, spin = 2}
local keys = {left = Enum.KeyCode.Left, right = Enum.KeyCode.Right, soft = Enum.KeyCode.Down, hard = Enum.KeyCode.Space,
	cw = Enum.KeyCode.Up, ccw = Enum.KeyCode.Z, r180 = Enum.KeyCode.X, hold = Enum.KeyCode.C, restart = Enum.KeyCode.R, toggle = Enum.KeyCode.RightControl}
local LIM = {das = {0, 500}, arr = {0, 200}, sdr = {0, 500}, lock = {0, 3000}, clear = {0, 2000}}

-- Persistence: executor workspace file (writefile/readfile). A plain Roblox LocalScript has no file access, so there
-- settings stay in memory only. shortcut: whole file replaced on each change, fine for ~15 values.
local HttpService, SAVE = game:GetService("HttpService"), "TetrisSettings.json"
local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local function save()
	if not canFile then return end
	local k = {}
	for a, c in pairs(keys) do k[a] = c.Name end
	local ok, e = pcall(function() writefile(SAVE, HttpService:JSONEncode({cfg = cfg, keys = k})) end)
	if not ok then warn("[Tetris] could not save settings: " .. tostring(e)) end
end
if canFile then -- load + validate (the file is user-editable): bad values keep defaults
	local ok, d = pcall(function() return isfile(SAVE) and HttpService:JSONDecode(readfile(SAVE)) end)
	if ok and type(d) == "table" then
		if type(d.cfg) == "table" then
			for n, l in pairs(LIM) do
				local v = tonumber(d.cfg[n])
				if v then cfg[n] = math.clamp(math.floor(v + 0.5), l[1], l[2]) end
			end
			local sp = tonumber(d.cfg.spin)
			if sp and sp >= 1 and sp <= 3 then cfg.spin = math.floor(sp) end
		end
		if type(d.keys) == "table" then
			local new, seen, good = {}, {}, true
			for a, def in pairs(keys) do
				local c = type(d.keys[a]) == "string" and Enum.KeyCode:FromName(d.keys[a]) or def
				if seen[c] or c == Enum.KeyCode.Unknown or c == Enum.KeyCode.Escape then good = false break end
				seen[c], new[a] = true, c
			end
			if good then keys = new end -- any duplicate/invalid key: keep the default layout
		end
	end
end
local rng = Random.new()
local tet = newGame(cfg, function(n) return rng:NextInteger(1, n) end)

local TITLE, MINW, MINH = 34, 420, 480
local BG, TEXT, DIM, WHITE = Color3.fromRGB(16, 18, 28), Color3.fromRGB(235, 238, 250), Color3.fromRGB(143, 152, 179), Color3.new(1, 1, 1)
local COL = {Color3.fromRGB(0, 229, 255), Color3.fromRGB(255, 213, 0), Color3.fromRGB(176, 76, 240), Color3.fromRGB(80, 224, 100),
	Color3.fromRGB(245, 64, 64), Color3.fromRGB(72, 110, 255), Color3.fromRGB(255, 152, 48)} -- I O T S Z J L
local LEFT = Enum.TextXAlignment.Left

local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function txt(class, props, parent) -- text-capable instance with house defaults
	local p = {Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = TEXT, BackgroundTransparency = 1, BorderSizePixel = 0}
	for k, v in pairs(props) do p[k] = v end
	return mk(class, p, parent)
end
local function round(o, r, stroke)
	mk("UICorner", {CornerRadius = UDim.new(0, r)}, o)
	if stroke then mk("UIStroke", {Color = WHITE, Transparency = 0.82, Thickness = 1}, o) end
end

local layout, restore, minimize, toggle, setFocus, bindSink, setOptions, cleanup -- forward declarations

local gui = mk("ScreenGui", {Name = "TetrisGui", ResetOnSpawn = false, DisplayOrder = 1000000000, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, Players.LocalPlayer:WaitForChild("PlayerGui"))
local function view()
	local v = gui.AbsoluteSize
	return v.X > 0 and v or workspace.CurrentCamera.ViewportSize
end
local vp = workspace.CurrentCamera.ViewportSize
local w0, h0 = math.min(560, vp.X - 24), math.min(640, vp.Y - 24)

-- Window: transparent shell, more opaque playfield ----------------------------------------------------------
local win = mk("Frame", {Name = "Window", Size = UDim2.fromOffset(w0, h0), Visible = false, Active = true, ClipsDescendants = true,
	Position = UDim2.fromOffset(math.floor((vp.X - w0) / 2), math.floor((vp.Y - h0) / 2)),
	BackgroundColor3 = BG, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 1}, gui)
round(win, 12, true)
local bar = mk("Frame", {Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE), BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.55, BorderSizePixel = 0, Active = true, ZIndex = 10}, win)
txt("TextLabel", {Text = "TETRIS", Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = LEFT,
	Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -200, 1, 0), ZIndex = 11}, bar)
local function barBtn(text, x, w, cb)
	local b = txt("TextButton", {Text = text, BackgroundColor3 = Color3.fromRGB(70, 78, 110), BackgroundTransparency = 0.35,
		Position = UDim2.new(1, -x, 0.5, -12), Size = UDim2.fromOffset(w, 24), ZIndex = 11}, bar)
	round(b, 6)
	on(b.Activated, cb)
	return b
end
local optBtn
optBtn = barBtn("Options", 152, 76, function() setOptions(not optBtn.Text:find("Back")) end)
barBtn("-", 68, 28, function() minimize() end)
barBtn("x", 34, 28, function() cleanup() end)

local field = mk("Frame", {Name = "Playfield", BackgroundColor3 = Color3.fromRGB(7, 9, 15), BackgroundTransparency = 0.1,
	BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2}, win)
round(field, 6, true)
local cells = {} -- 200 pooled cells; only repainted when their code changes
for r = 1, VIS do
	for c = 1, W do
		cells[(r - 1) * W + c] = mk("Frame", {Size = UDim2.new(0.1, -1, 0.05, -1), BorderSizePixel = 0,
			Position = UDim2.fromScale((c - 1) / W, (r - 1) / VIS), BackgroundTransparency = 1}, field)
	end
end
local msgLabel = txt("TextLabel", {Font = Enum.Font.GothamBold, Text = "", TextWrapped = true, Size = UDim2.fromScale(1, 0.12),
	Position = UDim2.fromScale(0, 0.3), ZIndex = 6}, field)
local overlay = txt("TextLabel", {Font = Enum.Font.GothamBold, Text = "", RichText = true, TextWrapped = true, Visible = false,
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), ZIndex = 8}, field)

local function panel()
	local f = mk("Frame", {BackgroundTransparency = 1, ZIndex = 2}, win)
	mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	return f
end
local leftP, rightP, minis = panel(), panel(), {}
local function title(parent, text, order)
	txt("TextLabel", {Text = text, TextSize = 12, TextColor3 = DIM, TextXAlignment = LEFT, Size = UDim2.new(1, -8, 0, 16), LayoutOrder = order, ZIndex = 3}, parent)
end
local function mini(parent, order) -- small piece preview: 4 pooled blocks
	local f = mk("Frame", {BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 3}, parent)
	local m = {frame = f, key = false, cells = {}}
	for i = 1, 4 do m.cells[i] = mk("Frame", {BorderSizePixel = 0, Visible = false, ZIndex = 4}, f) end
	minis[#minis + 1] = m
	return m
end
local function setMini(m, t, dim)
	local key = t and (t .. (dim and "x" or "")) or ""
	if m.key == key then return end
	m.key = key
	for _, c in ipairs(m.cells) do c.Visible = false end
	if not t then return end
	local minc, maxc, minr = 9, 0, 9
	for _, v in ipairs(SHAPE[t][0]) do minc, maxc, minr = math.min(minc, v[1]), math.max(maxc, v[1]), math.min(minr, v[2]) end
	local off = (4 - (maxc - minc + 1)) / 2
	for i, v in ipairs(SHAPE[t][0]) do
		local c = m.cells[i]
		c.Position, c.Size = UDim2.fromScale((v[1] - minc + off) / 4, (v[2] - minr) / 2), UDim2.new(0.25, -1, 0.5, -1)
		c.BackgroundColor3, c.BackgroundTransparency, c.Visible = COL[TI[t]], dim and 0.65 or 0, true
	end
end
title(leftP, "HOLD", 1)
local holdMini = mini(leftP, 2)
local stats = txt("TextLabel", {Text = "", RichText = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top,
	Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, ZIndex = 3}, leftP)
txt("TextLabel", {Text = "*APM uses a local attack estimate (no opponents here).", TextSize = 10, TextColor3 = DIM, TextWrapped = true,
	TextXAlignment = LEFT, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, ZIndex = 3}, leftP)
title(rightP, "NEXT", 1)
local nextMinis = {}
for i = 1, 5 do nextMinis[i] = mini(rightP, i + 1) end

function layout() -- sizes scale with the window; cells use scale positions so only 3 containers are touched
	local w, h = win.Size.X.Offset, win.Size.Y.Offset - TITLE
	local s = math.max(8, math.floor(math.min((h - 24) / VIS, (w - 40) / 20)))
	local pw, fw, fh, gap = s * 5, s * W, s * VIS, 8
	local x0, y0 = math.floor((w - (fw + 2 * pw + 2 * gap)) / 2), TITLE + math.floor((h - fh) / 2)
	leftP.Position, leftP.Size = UDim2.fromOffset(x0, y0), UDim2.fromOffset(pw, fh)
	field.Position, field.Size = UDim2.fromOffset(x0 + pw + gap, y0), UDim2.fromOffset(fw, fh)
	rightP.Position, rightP.Size = UDim2.fromOffset(x0 + pw + fw + 2 * gap, y0), UDim2.fromOffset(pw, fh)
	for _, m in ipairs(minis) do m.frame.Size = UDim2.fromOffset(pw - 8, (pw - 8) / 2) end
	stats.TextSize = math.clamp(math.floor(s * 0.55), 10, 20)
	msgLabel.TextSize = math.clamp(math.floor(s * 0.8), 12, 26)
	overlay.TextSize = math.clamp(math.floor(s * 0.9), 14, 28)
end

-- Minimized bubble: draggable, upside-down-T tetromino logo, click restores ----------------------------------
local bubble = mk("Frame", {Name = "Bubble", Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(24, 120), Visible = false,
	Active = true, BackgroundColor3 = BG, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 1}, gui)
round(bubble, 28, true)
for _, p in ipairs({{1, 0}, {0, 1}, {1, 1}, {2, 1}}) do
	round(mk("Frame", {Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(10 + p[1] * 12, 16 + p[2] * 12),
		BackgroundColor3 = COL[3], BorderSizePixel = 0, ZIndex = 2}, bubble), 2)
end

-- Mouse release: while the window is focused or being dragged we force MouseBehavior.Default (first-person / shift-lock
-- would otherwise re-lock the cursor every frame) and restore the previous behavior when the last reason ends.
local holds, savedMB, savedIcon = {}, nil, nil
local function reason(key, active)
	holds[key] = active or nil
	local need = next(holds) ~= nil
	if need and not savedMB then
		savedMB, savedIcon = UIS.MouseBehavior, UIS.MouseIconEnabled
		RunService:BindToRenderStep("TetrisMouse", Enum.RenderPriority.Last.Value, function()
			if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then UIS.MouseBehavior = Enum.MouseBehavior.Default end
			if not UIS.MouseIconEnabled then UIS.MouseIconEnabled = true end
		end)
	elseif not need and savedMB then
		RunService:UnbindFromRenderStep("TetrisMouse")
		UIS.MouseBehavior, UIS.MouseIconEnabled = savedMB, savedIcon
		savedMB = nil
	end
end

-- Dragging/resizing is driven by global UserInputService events, so it keeps working outside the window.
local drag
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function startDrag(move, done) drag = {move = move, done = done}; reason("drag", true) end
on(UIS.InputChanged, function(i)
	if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then drag.move(i.Position) end
end)
on(UIS.InputEnded, function(i)
	if drag and isPress(i) then
		local d = drag
		drag = nil
		reason("drag", false)
		if d.done then d.done() end
	end
end)
local function clampPos(p, size) -- keep at least 80px (or the whole bubble) on screen
	local v, m = view(), math.min(80, size.X)
	return UDim2.fromOffset(math.clamp(p.X.Offset, m - size.X, v.X - m), math.clamp(p.Y.Offset, 0, v.Y - 40))
end
local function dragger(handle, target, onTap)
	on(handle.InputBegan, function(i)
		if not isPress(i) then return end
		local p0, s0, moved = i.Position, target.Position, 0
		startDrag(function(pos)
			local d = pos - p0
			moved = math.max(moved, d.Magnitude)
			target.Position = clampPos(UDim2.fromOffset(s0.X.Offset + d.X, s0.Y.Offset + d.Y), target.AbsoluteSize)
		end, function() if onTap and moved < 5 then onTap() end end)
	end)
end
dragger(bar, win)
dragger(bubble, bubble, function() restore() end)
local grip = mk("Frame", {Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -20, 1, -20), Active = true, BackgroundColor3 = WHITE,
	BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 30}, win)
round(grip, 6)
on(grip.InputBegan, function(i)
	if not isPress(i) then return end
	local p0, s0 = i.Position, Vector2.new(win.Size.X.Offset, win.Size.Y.Offset)
	startDrag(function(pos)
		local d, v = pos - p0, view()
		win.Size = UDim2.fromOffset(math.clamp(s0.X + d.X, MINW, math.max(MINW, v.X)), math.clamp(s0.Y + d.Y, MINH, math.max(MINH, v.Y)))
		layout()
	end)
end)
on(gui:GetPropertyChangedSignal("AbsoluteSize"), function() -- viewport changed: keep both reachable
	win.Position, bubble.Position = clampPos(win.Position, win.AbsoluteSize), clampPos(bubble.Position, bubble.AbsoluteSize)
end)

-- Options panel shell (rows are added below, once the input code exists) ---------------------------------------
local focused, down, keyDown, map, capture = false, {}, {}, {}, nil
local settings = mk("Frame", {Position = UDim2.fromOffset(0, TITLE), Size = UDim2.new(1, 0, 1, -TITLE), Visible = false, Active = true,
	BackgroundColor3 = Color3.fromRGB(10, 12, 20), BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 20}, win)
local list = mk("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 21}, settings)
mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
mk("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 40)}, list)
function setOptions(open)
	settings.Visible = open
	optBtn.Text = open and "Back" or "Options"
	if open then for a in pairs(down) do tet.release(a) end down = {} end -- no key may stay "held" while paused
end

-- Keyboard: while focused, a high-priority ContextActionService binding SINKS the Tetris keys and the default movement
-- keys/actions, so they drive the game and never the Roblox character. Unfocus/minimize/close unbinds it again.
local SINK, Sink, Pass = "TetrisSink", Enum.ContextActionResult.Sink, Enum.ContextActionResult.Pass
local BLOCK = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down,
	Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump}
local function onKey(_, state, input)
	if UIS:GetFocusedTextBox() then return Pass end -- typing into an option box
	local code, begin = input.KeyCode, state == Enum.UserInputState.Begin
	if begin then
		if keyDown[code] then return Sink end -- one action bound to several inputs can fire twice
		keyDown[code] = true
	else
		keyDown[code] = nil
	end
	local a = map[code]
	if a == "toggle" then
		if begin then toggle() end
	elseif a and not capture and not settings.Visible then
		if a == "restart" then if begin then tet.reset() end
		elseif begin then down[a] = true; tet.press(a)
		else down[a] = nil; tet.release(a) end
	end
	return Sink
end
function bindSink()
	local seen, binds = {}, {}
	for _, k in ipairs(BLOCK) do seen[k] = true; binds[#binds + 1] = k end
	for _, k in pairs(keys) do if not seen[k] then seen[k] = true; binds[#binds + 1] = k end end
	CAS:BindActionAtPriority(SINK, onKey, false, Enum.ContextActionPriority.High.Value + 500, table.unpack(binds))
end
local function rebuildMap()
	map = {}
	for a, k in pairs(keys) do map[k] = a end
	if focused then bindSink() end
end
function setFocus(active)
	if focused == active then return end
	focused = active
	if active then
		bindSink()
	else
		CAS:UnbindAction(SINK)
		for a in pairs(down) do tet.release(a) end -- nothing may stay held after focus ends
		down, keyDown = {}, {}
		if capture then capture.btn.Text = keys[capture.a].Name; capture = nil end
	end
	reason("focus", active)
end
function restore() win.Visible, bubble.Visible = true, false; setFocus(true) end
function minimize() win.Visible, bubble.Visible = false, true; setFocus(false) end
function toggle()
	if not win.Visible then restore() elseif not focused then setFocus(true) else minimize() end
end
rebuildMap()

-- Options rows -------------------------------------------------------------------------------------------------
local order = 0
local function header(text)
	order = order + 1
	txt("TextLabel", {Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = DIM, TextXAlignment = LEFT, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 22), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, ZIndex = 22}, list)
end
local function row(name, class, text, extra)
	order = order + 1
	local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 22}, list)
	txt("TextLabel", {Text = name, TextXAlignment = LEFT, Size = UDim2.new(0.6, 0, 1, 0), ZIndex = 23}, f)
	local p = {Text = text, BackgroundColor3 = Color3.fromRGB(50, 56, 80), BackgroundTransparency = 0.2, Position = UDim2.new(0.62, 0, 0, 2),
		Size = UDim2.new(0.38, 0, 1, -4), ZIndex = 23}
	for k, v in pairs(extra or {}) do p[k] = v end
	local c = txt(class, p, f)
	round(c, 6)
	return c
end
header("HANDLING  (values are validated and applied instantly; the game pauses while Options is open)")
for _, d in ipairs({{"das", "DAS (ms)"}, {"arr", "ARR (ms, 0 = instant)"}, {"sdr", "Soft drop (rows/s, 0 = instant)"},
	{"lock", "Lock delay (ms)"}, {"clear", "Line clear delay (ms)"}}) do
	local box = row(d[2], "TextBox", tostring(cfg[d[1]]), {ClearTextOnFocus = false})
	on(box.FocusLost, function()
		local n = tonumber(box.Text)
		if n then cfg[d[1]] = math.clamp(math.floor(n + 0.5), LIM[d[1]][1], LIM[d[1]][2]) end
		box.Text = tostring(cfg[d[1]]) -- invalid input snaps back to the last valid value
		save()
	end)
end
header("SPINS  T-Spin: 3-corner rule (mini if one front corner, full if kick 5). Others: immobile rule.")
local SPIN = {"T-Spin only", "All-Spin (full)", "All-Mini"}
local spinBtn = row("Spin detection", "TextButton", SPIN[cfg.spin])
on(spinBtn.Activated, function() cfg.spin = cfg.spin % 3 + 1; spinBtn.Text = SPIN[cfg.spin]; save() end)
header("CONTROLS  (click a key, then press the new one; Esc cancels; a used key swaps)")
local keyBtns = {}
for _, a in ipairs({{"left", "Move left"}, {"right", "Move right"}, {"soft", "Soft drop"}, {"hard", "Hard drop"}, {"cw", "Rotate clockwise"},
	{"ccw", "Rotate counter-clockwise"}, {"r180", "Rotate 180"}, {"hold", "Hold"}, {"restart", "Restart"}, {"toggle", "Show / minimize window"}}) do
	local b = row(a[2], "TextButton", keys[a[1]].Name)
	keyBtns[a[1]] = b
	on(b.Activated, function()
		if capture then capture.btn.Text = keys[capture.a].Name end
		capture = {a = a[1], btn = b}
		b.Text = "press a key..."
	end)
end
local function finishCapture(code)
	local c = capture
	capture = nil
	if code ~= Enum.KeyCode.Escape and code ~= Enum.KeyCode.Unknown then
		for a, k in pairs(keys) do
			if k == code and a ~= c.a then keys[a] = keys[c.a]; keyBtns[a].Text = keys[a].Name end -- swap, never duplicate
		end
		keys[c.a] = code
		rebuildMap()
		save()
	end
	c.btn.Text = keys[c.a].Name
end

-- Focus model: clicking the window focuses it; clicking anywhere else (or losing Roblox window focus) unfocuses it.
local function pointOf(i)
	if i.UserInputType == Enum.UserInputType.Touch then return Vector2.new(i.Position.X, i.Position.Y) + GuiService:GetGuiInset() end
	return UIS:GetMouseLocation()
end
local function inside(o, v)
	local p, s = o.AbsolutePosition, o.AbsoluteSize
	return v.X >= p.X and v.X <= p.X + s.X and v.Y >= p.Y and v.Y <= p.Y + s.Y
end
on(UIS.InputBegan, function(i, gp)
	if i.UserInputType == Enum.UserInputType.Keyboard then
		if capture then finishCapture(i.KeyCode)
		elseif not gp and not focused and i.KeyCode == keys.toggle then toggle() end -- while focused, onKey handles the toggle
	elseif isPress(i) then
		local v = pointOf(i)
		if win.Visible and inside(win, v) then setFocus(true)
		elseif not (bubble.Visible and inside(bubble, v)) then setFocus(false) end
	end
end)
on(UIS.WindowFocusReleased, function() setFocus(false) end)

-- Rendering: composes visible cells into codes (0 empty, 1-7 piece, 11-17 ghost, 20 clearing row) and repaints only changes.
local function fmt(n) return (tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
local buf, shown, statT, lastOv = {}, {}, 0, nil
for i = 1, VIS * W do shown[i] = -1 end
local function paint(f, code)
	if code == 0 then f.BackgroundColor3, f.BackgroundTransparency = WHITE, 0.95
	elseif code == 20 then f.BackgroundColor3, f.BackgroundTransparency = WHITE, 0.1
	elseif code > 10 then f.BackgroundColor3, f.BackgroundTransparency = COL[code - 10], 0.72
	else f.BackgroundColor3, f.BackgroundTransparency = COL[code], 0 end
end
local LBL = '<font color="#8f98b3">%s</font>'
local function render(dt)
	local base, p = H - VIS, tet.cur
	for r = 1, VIS do
		local row = tet.board[base + r]
		for c = 1, W do buf[(r - 1) * W + c] = row[c] end
	end
	if tet.rows then
		for _, rr in ipairs(tet.rows) do if rr > base then for c = 1, W do buf[(rr - base - 1) * W + c] = 20 end end end
	end
	if p then
		local gy = tet.ghost()
		for _, v in ipairs(SHAPE[p.t][p.r]) do
			local r, i = gy + v[2] - base, (gy + v[2] - base - 1) * W + p.x + v[1]
			if r >= 1 and buf[i] == 0 then buf[i] = 10 + TI[p.t] end
		end
		for _, v in ipairs(SHAPE[p.t][p.r]) do
			local r = p.y + v[2] - base
			if r >= 1 then buf[(r - 1) * W + p.x + v[1]] = TI[p.t] end
		end
	end
	for i = 1, VIS * W do
		if buf[i] ~= shown[i] then shown[i] = buf[i]; paint(cells[i], buf[i]) end
	end
	for i = 1, 5 do setMini(nextMinis[i], tet.queue[i]) end
	setMini(holdMini, tet.hold, not tet.canHold)
	if tet.msgT > 0 then msgLabel.Text, msgLabel.TextTransparency = tet.msg, math.clamp(1 - tet.msgT, 0, 1)
	elseif msgLabel.Text ~= "" then msgLabel.Text = "" end
	statT = statT - dt
	if statT <= 0 then -- stats text refreshes at 10 Hz
		statT = 0.1
		stats.Text = string.format(LBL .. "\n%s\n" .. LBL .. "  %d\n" .. LBL .. "  %d\n" .. LBL .. "  %.1f\n" .. LBL .. "  %.2f",
			"SCORE", fmt(tet.score), "LINES", tet.lines, "LEVEL", tet.level, "APM*", tet.apm(), "PPS", tet.pps())
	end
	local ov = (tet.state == "over" and 'GAME OVER\n<font size="14">press ' .. keys.restart.Name .. " to restart</font>")
		or (not focused and 'PAUSED\n<font size="14">click the window or press ' .. keys.toggle.Name .. "</font>") or ""
	if ov ~= lastOv then lastOv, overlay.Text, overlay.Visible = ov, ov, ov ~= "" end
end
-- The game only advances while the window is visible, focused and Options is closed (pause = no timers running, no stuck keys).
on(RunService.RenderStepped, function(dt)
	if not win.Visible then return end
	if focused and not settings.Visible then tet.update(math.min(dt, 0.1)) end
	render(dt)
end)

-- Lifecycle ----------------------------------------------------------------------------------------------------
function cleanup() -- Close: stops everything this script created; the Roblox client and character are untouched
	if not alive then return end
	alive = false
	for _, c in ipairs(conns) do c:Disconnect() end
	CAS:UnbindAction(SINK)
	holds = {}
	reason("cleanup", false) -- unbinds the mouse override and restores the previous MouseBehavior / icon
	if _G.TetrisCleanup == cleanup then _G.TetrisCleanup = nil end
	gui:Destroy()
end
_G.TetrisCleanup = cleanup
on(gui.AncestryChanged, function(_, parent) if not parent then cleanup() end end) -- destroyed by someone else
layout()
restore()
