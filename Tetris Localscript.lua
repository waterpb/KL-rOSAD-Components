-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py)
-- [DATA] constants, piece shapes, kick tables, scoring (PTS, PCX), fmt/clock | SHAPE, KJ, KI, K180, PTS, PCX, fmt() | deps: none | L29-77
-- [GAME] pure rules, no Roblox APIs | newGame(): press/release/update/ghost/reset/waiting/goal, lock, spinKind, modes, perfect clear | deps: DATA | L79-379
-- [SELFTEST] load-time logic asserts | selfTest() | deps: DATA, GAME | L381-423
-- [STATE] services, cfg, keys, best (records), lb (local top 10 per mode), save/load, game instance | cfg, keys, LIM, best, lb, save(), addScore(), refreshNames(), tet | deps: GAME | L425-536
-- [WINDOW] themes (colours + block look; Textured = blocks.png), window, playfield (gradient, starfield, flash), panels, layout | THEMES, TEX, loadBlocks(), applyTheme(), blockLook(), look(), layout(), setMini() | deps: STATE | L538-761
-- [BUBBLE] minimized draggable logo | bubble | deps: WINDOW | L763-772
-- [DRAG] mouse release, drag, resize | reason(), dragger(), grip | deps: WINDOW | L774-841
-- [OPTIONS] options panel shell + Scores tab | settings, list, lbP, showLb(), setOptions(open, scores) | deps: WINDOW, STATE | L843-914
-- [INPUT] CAS key sink, focus, toggle | onKey(), bindSink(), setFocus(), toggle() | deps: OPTIONS | L916-972
-- [OPTROWS] collapsible options sections, rows, dropdowns, On/Off toggles, key capture | section(), hint(), row(), opt(), drop(), numRows(), finishCapture() | deps: INPUT, STATE | L974-1117
-- [FOCUS] click focus model | pointOf(), inside() | deps: INPUT | L1119-1140
-- [RENDER] paint cells, stats, records + leaderboard insert, overlay, frame loop | render(), paint(), stat(), RenderStepped | deps: STATE, WINDOW | L1142-1248
-- [LIFE] cleanup and startup | cleanup(), layout(), restore() | deps: all | L1250-1266

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

-- [DATA]
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
local PCX = {[0]=0, 700, 900, 1300, 1200} -- extra points a perfect clear adds on top of the line score: totals 800/1200/1800/2000
local POINT = {[0]={0,-1},{1,0},{0,1},{-1,0}} -- T nose direction (dcol,drow) per rotation state

local function emptyRow() local r = {} for c = 1, W do r[c] = 0 end return r end
local function clock(t) return string.format("%d:%05.2f", math.floor(t / 60), t % 60) end
local function fmt(n) return (tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
-- [/DATA]

-- [GAME]
-- cfg (read live, so setting changes apply instantly): das/arr/lock/clear in ms, sdr rows/s (0 = instant), spin 1|2|3,
-- gmode 1 level curve|2 fixed|3 off|4 instant, grav ms/row (mode 2), start level, idle = pieces that fall before the game waits for input,
-- mode 1 Marathon|2 Sprint 40L|3 Ultra 2:00|4 Cheese 10 (read at reset), rand 1 7-bag|2 random|3 14-bag
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
	local function refill() -- 7-bag | pure random | 14-bag
		while #g.queue < 7 do
			if cfg.rand == 2 then
				g.queue[#g.queue + 1] = NAMES[rnd(7)]
			else
				local n, b = cfg.rand == 3 and 14 or 7, {}
				for i = 1, n do b[i] = (i - 1) % 7 + 1 end
				for i = n, 2, -1 do local j = rnd(i); b[i], b[j] = b[j], b[i] end
				for i = 1, n do g.queue[#g.queue + 1] = NAMES[b[i]] end
			end
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
		g.cur, g.pieces, g.cells = nil, g.pieces + 1, g.cells + 4
		local rows = {}
		for r = 1, H do
			local full, gb = true, false
			for c = 1, W do
				local v = g.board[r][c]
				if v == 0 then full = false break elseif v == 8 then gb = true end
			end
			if full then
				rows[#rows + 1] = r
				if gb then g.garb = g.garb - 1 end -- a garbage row (Cheese goal)
			end
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
		g.cells = g.cells - 10 * n
		local pc = n > 0 and g.cells == 0 -- perfect clear: the board is empty afterwards
		if pc then pts, atk = pts + (bonus and n == 4 and 2000 or PCX[n]), atk + 10 end -- B2B Tetris PC: 800*1.5 + 2000 = 3200
		g.score, g.attack = g.score + math.floor(pts * g.level), g.attack + atk
		if kind or n > 0 then
			g.msg = (bonus and "B2B " or "") .. (kind and ((mini and "MINI " or "") .. p.t .. "-SPIN") or "")
				.. (kind and n > 0 and " " or "") .. (CLEARN[n] or "") .. (g.combo > 0 and "  x" .. g.combo or "") .. (pc and "\nPERFECT CLEAR" or "")
			g.msgT = 2
		end
		g.lines = g.lines + n
		g.level, g.canHold = cfg.start + math.floor(g.lines / 10), true
		if g.mode == 2 and g.lines >= 40 or g.mode == 4 and g.garb <= 0 then -- Sprint / Cheese goal reached
			removeRows(rows)
			g.state, g.won = "over", true
			return
		end
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
		if not g.started then g.started, g.p0, g.attack = true, g.pieces, 0 end -- first input starts the clock (PPS/APM count from here)
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
		if g.started then
			g.time = g.time + dt
			if g.mode == 3 and g.time >= 120 then g.state, g.won = "over", true return end -- Ultra: time up
		end
		g.msgT = g.msgT - dt
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
		if not g.cur or g.waiting() then return end -- idle autoplay is over: no gravity until the first input
		if held.soft and cfg.sdr <= 0 and cfg.arr <= 0 then -- both instant: soft drop wins, fall first, then slide
			while drop1() do g.score = g.score + 1 end
			gAcc = 0
		end
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
		local m = cfg.gmode -- 1 level curve | 2 fixed ms/row | 3 off | 4 instant
		local spr = (m == 2 and cfg.grav / 1000) or (m == 3 and math.huge) or (m == 4 and 1e-4)
			or math.max((0.8 - (lv - 1) * 0.007) ^ (lv - 1), 1e-4)
		if held.soft and cfg.sdr <= 0 then
			while drop1() do g.score = g.score + 1 end
			gAcc = 0
		else
			local iv = held.soft and math.min(spr, 1 / cfg.sdr) or spr
			if iv == math.huge then gAcc = 0 end -- gravity off: never bank time for a later burst
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
	function g.pps() return g.time > 0 and (g.pieces - g.p0) / g.time or 0 end
	function g.waiting() return not g.started and g.state == "play" and g.pieces >= cfg.idle end
	function g.goal() -- label, value of the mode's objective (nil for Marathon)
		if g.mode == 2 then return "TO GO", math.max(0, 40 - g.lines)
		elseif g.mode == 3 then return "LEFT", clock(math.max(0, 120 - g.time))
		elseif g.mode == 4 then return "GARBAGE", g.garb end
	end
	function g.reset()
		g.board, g.queue, g.hold, g.cur, g.rows = {}, {}, nil, nil, nil
		for r = 1, H do g.board[r] = emptyRow() end
		g.score, g.lines, g.level, g.pieces, g.attack, g.time = 0, 0, cfg.start, 0, 0, 0
		g.started, g.p0, g.won, g.mode, g.cells, g.garb = false, 0, false, cfg.mode, 0, 0
		if g.mode == 4 then -- Cheese: 10 garbage rows with one hole each; clear them all
			for r = H - 9, H do
				local hole = rnd(W)
				for c = 1, W do g.board[r][c] = c == hole and 0 or 8 end
			end
			g.cells, g.garb = 90, 10
		end
		g.b2b, g.combo, g.msg, g.msgT, g.canHold, g.state = 0, -1, "", 0, true, "play"
		pend, hT, hDone, hFresh = {}, 0, 0, false
		refill()
		spawn()
	end
	g.reset()
	return g
end
-- [/GAME]

-- [SELFTEST]
-- SELF-CHECK: runs once at load (pure logic, no UI). A failure only warns; it never stops the game.
local function selfTest()
	local cfg0 = {das = 100, arr = 0, sdr = 0, lock = 500, clear = 0, spin = 2, gmode = 1, grav = 1000, start = 1, idle = 0, mode = 1, rand = 1}
	local g = newGame(cfg0, function() return 1 end)
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
	g.reset(); local y0 = g.cur.y -- idle 0: no gravity and no clock until the first input
	g.update(2)
	assert(g.cur.y == y0 and g.time == 0 and g.waiting(), "idle freeze")
	g.press("left"); g.update(0.1)
	assert(g.time > 0 and not g.waiting(), "input starts the clock")
	g.reset(); g.board[40][3] = 1; g.cur = {t = "I", r = 0, x = 4, y = 20, spun = false} -- falls first, so the slide is blocked
	g.press("soft"); g.press("left"); g.update(0.2)
	assert(g.cur.x == 4, "soft drop beats instant ARR")
	local function pcSetup() -- one row left with a 4-wide gap, an I fills it
		g.reset()
		for _, c in ipairs({1, 2, 3, 8, 9, 10}) do g.board[40][c] = 1 end
		g.cells, g.cur = 6, {t = "I", r = 0, x = 4, y = 39, spun = false}
	end
	pcSetup(); g.press("hard")
	assert(g.lines == 1 and g.msg:find("PERFECT"), "perfect clear")
	assert(g.score == 800, "perfect clear score") -- single PC at level 1: 100 + 700
	cfg0.mode = 2; pcSetup(); g.lines = 39; g.press("hard")
	assert(g.state == "over" and g.won, "sprint finish")
	cfg0.mode = 4; g.reset()
	assert(g.garb == 10 and g.cells == 90, "cheese setup")
	cfg0.mode = 1
end
-- [/SELFTEST]

-- [STATE]
-- UI + INPUT (Roblox) ------------------------------------------------------------------------------------------
local Players, UIS, CAS = game:GetService("Players"), game:GetService("UserInputService"), game:GetService("ContextActionService")
local RunService, GuiService = game:GetService("RunService"), game:GetService("GuiService")

if _G.TetrisCleanup then pcall(_G.TetrisCleanup) end -- re-running the script replaces the previous instance
local passed, why = pcall(selfTest)
if not passed then warn("[Tetris] self-check failed: " .. tostring(why)) end

local alive, conns = true, {}
local function on(signal, fn) conns[#conns + 1] = signal:Connect(fn) end

-- Settings (read live by the game). Keys are rebindable in the Options panel.
local cfg = {das = 167, arr = 33, sdr = 30, lock = 500, clear = 100, spin = 2, gmode = 1, grav = 1000, start = 1, idle = 4,
	mode = 1, rand = 1, ghost = 1, nexts = 5, theme = 1, snow = 1, flash = 1, shake = 1}
local keys = {left = Enum.KeyCode.Left, right = Enum.KeyCode.Right, soft = Enum.KeyCode.Down, hard = Enum.KeyCode.Space,
	cw = Enum.KeyCode.Up, ccw = Enum.KeyCode.Z, r180 = Enum.KeyCode.X, hold = Enum.KeyCode.C, restart = Enum.KeyCode.R, toggle = Enum.KeyCode.RightControl}
local LIM = {das = {0, 500}, arr = {0, 200}, sdr = {0, 500}, lock = {0, 3000}, clear = {0, 2000},
	grav = {1, 5000}, start = {1, 30}, idle = {0, 8}, mode = {1, 4}, rand = {1, 3}, ghost = {0, 1}, nexts = {0, 5},
	theme = {1, 4}, snow = {0, 1}, flash = {0, 1}, shake = {0, 1}}

-- Persistence: executor workspace file (writefile/readfile). A plain Roblox LocalScript has no file access, so there
-- settings stay in memory only. shortcut: whole file replaced on each change, fine for ~15 values.
local HttpService, SAVE = game:GetService("HttpService"), "TetrisSettings.json"
local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local best = {} -- records: m1 Marathon score, m2 Sprint time, m3 Ultra score, m4 Cheese time
local lb = {m1 = {}, m2 = {}, m3 = {}, m4 = {}} -- local top 10 per mode, best first: {v = score|time, s = score, l = lines, t = os.time(), u = userId, n = username}
local function save()
	if not canFile then return end
	local k = {}
	for a, c in pairs(keys) do k[a] = c.Name end
	local ok, e = pcall(function() writefile(SAVE, HttpService:JSONEncode({cfg = cfg, keys = k, best = best, lb = lb})) end)
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
			local gm = tonumber(d.cfg.gmode)
			if gm and gm >= 1 and gm <= 4 then cfg.gmode = math.floor(gm) end
			for m = 1, 4 do
				local b = type(d.best) == "table" and tonumber(d.best["m" .. m])
				if b and b > 0 then best["m" .. m] = b end
			end
		end
		for m = 1, 4 do -- leaderboard: keep only well-formed rows (the file is user-editable)
			local src, out = type(d.lb) == "table" and d.lb["m" .. m], {}
			for _, e in ipairs(type(src) == "table" and src or {}) do
				local v, l = type(e) == "table" and tonumber(e.v), type(e) == "table" and tonumber(e.l)
				if v and l and v > 0 and #out < 10 then
					out[#out + 1] = {v = v, l = l, s = tonumber(e.s) or 0, t = math.clamp(tonumber(e.t) or 0, 0, 4e9),
						u = math.floor(tonumber(e.u) or 0), n = type(e.n) == "string" and e.n:sub(1, 40) or "?"}
				end
			end
			lb["m" .. m] = out
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
local function addScore(m, v, timed) -- file one finished run into that mode's top 10 (timed modes: lower is better)
	local list, at = lb["m" .. m], nil
	for i, e in ipairs(list) do
		if timed and v < e.v or not timed and v > e.v then at = i break end
	end
	at = at or #list + 1
	if at > 10 then return end
	table.insert(list, at, {v = v, s = tet.score, l = tet.lines, t = os.time(), u = Players.LocalPlayer.UserId, n = Players.LocalPlayer.Name})
	list[11] = nil
	save()
end
local nameCache = {} -- userId -> current username (false = lookup failed; one try per session)
local function refreshNames(done) -- accounts can rename: replace stored names with the current ones, then call done() if any changed
	local lp = Players.LocalPlayer
	task.spawn(function()
		local changed = false
		for _, rows in pairs(lb) do
			for _, e in ipairs(rows) do
				if e.u > 0 then
					local nm = e.u == lp.UserId and lp.Name or nameCache[e.u]
					if nm == nil then
						local ok, r = pcall(Players.GetNameFromUserIdAsync, Players, e.u)
						nameCache[e.u] = ok and r or false
						nm = nameCache[e.u]
					end
					if nm and nm ~= e.n then e.n, changed = nm, true end
				end
			end
		end
		if changed then
			save()
			if done then done() end
		end
	end)
end
refreshNames()
-- [/STATE]

-- [WINDOW]
local TITLE, MINW, MINH = 34, 420, 480
local BG, TEXT, DIM, WHITE = Color3.fromRGB(16, 18, 28), Color3.fromRGB(235, 238, 250), Color3.fromRGB(143, 152, 179), Color3.new(1, 1, 1)
local COL = {Color3.fromRGB(0, 229, 255), Color3.fromRGB(255, 213, 0), Color3.fromRGB(176, 76, 240), Color3.fromRGB(80, 224, 100),
	Color3.fromRGB(245, 64, 64), Color3.fromRGB(72, 110, 255), Color3.fromRGB(255, 152, 48)} -- I O T S Z J L
COL[8] = Color3.fromRGB(110, 118, 140) -- garbage
local BLACK = Color3.new(0, 0, 0)
-- Themes: one setting for the whole look. c = 7 piece colours (I O T S Z J L) as r,g,b triples, bg = board gradient (top, bottom).
-- The rest shapes a block: fill = how far the body is darkened, r = corner radius, edge = outline mix (negative: outline in the
-- piece colour, 0: none), thick = outline width, gloss = top highlight band, tex = draw blocks.png tiles instead of the body.
-- cfg.theme is the index (keep LIM.theme in step); applyTheme() repaints the board on the next frame.
local THEMES = {
	{ n = "Textured", tex = true, fill = 0, r = 2, edge = 0.45, thick = 1, gloss = true, bg = {18, 22, 38, 5, 6, 12},
		c = {0, 229, 255, 255, 213, 0, 176, 76, 240, 80, 224, 100, 245, 64, 64, 72, 110, 255, 255, 152, 48} },
	{ n = "Glossy", fill = 0, r = 3, edge = 0.45, thick = 1, gloss = true, bg = {10, 16, 20, 3, 4, 6},
		c = {34, 196, 214, 224, 176, 32, 148, 48, 196, 56, 168, 88, 200, 40, 56, 44, 72, 196, 200, 108, 32} },
	{ n = "Flat", fill = 0, r = 0, edge = 0, thick = 0, gloss = false, bg = {38, 36, 52, 14, 13, 20},
		c = {132, 224, 246, 255, 232, 148, 202, 166, 255, 166, 232, 170, 255, 170, 170, 152, 186, 255, 255, 202, 152} },
	{ n = "Neon", fill = 0.55, r = 4, edge = -1, thick = 2, gloss = false, bg = {22, 4, 34, 6, 2, 14},
		c = {120, 240, 255, 255, 230, 120, 255, 80, 220, 80, 255, 200, 255, 80, 130, 110, 120, 255, 255, 140, 200} },
}
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
	if stroke then return mk("UIStroke", {Color = WHITE, Transparency = 0.82, Thickness = 1}, o) end
end

local layout, restore, minimize, toggle, setFocus, bindSink, setOptions, cleanup, applyTheme -- forward declarations
local fxX, fxY, skinDirty = 0, 0, true -- playfield home x/y (the clear shake moves it) and a repaint-every-block flag
local TEX -- blocks.png as a local asset id; nil means every style falls back to the drawn bevel
local function loadBlocks() -- fetch the sheet once, cache it, then repaint (needs an executor with getcustomasset)
	if not canFile or type(getcustomasset) ~= "function" then return end
	-- shortcut: the cached sheet never refreshes by itself; bump the _v number whenever blocks.png changes on GitHub
	local path, url = "TetrisBlocks_v2.png", "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/blocks.png"
	local ok, id = pcall(function()
		local okRead, cached = pcall(function() return readfile(path):sub(1, 4) == "\137PNG" end)
		if not okRead or not cached then -- no file yet, or an HTML error page was cached earlier: download again
			local body = game:HttpGet(url)
			assert(type(body) == "string" and body:sub(1, 4) == "\137PNG", "blocks.png download failed")
			writefile(path, body)
		end
		return getcustomasset(path)
	end)
	if ok and type(id) == "string" then TEX, skinDirty = id, true end
end

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
mk("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(26, 30, 48), Color3.fromRGB(8, 9, 15))}, win)
local accentLine = mk("Frame", {Name = "Accent", Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromOffset(0, TITLE),
	BackgroundColor3 = WHITE, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 12}, win)
local bar = mk("Frame", {Name = "TitleBar", Size = UDim2.new(1, 0, 0, TITLE), BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.55, BorderSizePixel = 0, Active = true, ZIndex = 10}, win)
mk("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(44, 50, 82), Color3.fromRGB(14, 16, 26))}, bar)
txt("TextLabel", {RichText = true, Text = '<font color="#f54040">T</font><font color="#ff9830">E</font><font color="#ffd500">T</font><font color="#50e064">R</font><font color="#00e5ff">I</font><font color="#b04cf0">S</font>', Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = LEFT,
	Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -200, 1, 0), ZIndex = 11}, bar)
local function barBtn(text, x, w, cb, hot) -- hot = hover colour
	local base = Color3.fromRGB(58, 66, 98)
	local b = txt("TextButton", {Text = text, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, BackgroundColor3 = base,
		BackgroundTransparency = 0.25, Position = UDim2.new(1, -x, 0.5, -12), Size = UDim2.fromOffset(w, 24), ZIndex = 11}, bar)
	round(b, 6, true)
	on(b.MouseEnter, function() b.BackgroundColor3, b.BackgroundTransparency = hot or Color3.fromRGB(92, 106, 158), 0.05 end)
	on(b.MouseLeave, function() b.BackgroundColor3, b.BackgroundTransparency = base, 0.25 end)
	on(b.Activated, cb)
	return b
end
local optBtn
optBtn = barBtn("Options", 152, 76, function() setOptions(not optBtn.Text:find("Back")) end)
barBtn("-", 68, 28, function() minimize() end)
barBtn("x", 34, 28, function() cleanup() end, Color3.fromRGB(200, 64, 72))

local field = mk("Frame", {Name = "Playfield", BackgroundColor3 = Color3.fromRGB(7, 9, 15), BackgroundTransparency = 0.1,
	BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2}, win)
local fieldStroke = round(field, 6, true)
local fieldBg = mk("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1}, field)
local fbg = mk("UIGradient", {Rotation = 90}, fieldBg) -- colours come from applyTheme
local stars = mk("Frame", {Name = "Stars", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true,
	Visible = cfg.snow == 1, ZIndex = 2}, field)
local starFx = {} -- drifting dots: the empty board is never a flat rectangle
for i = 1, 24 do
	local d = mk("Frame", {Size = UDim2.fromOffset(1 + math.random(0, 2), 1 + math.random(0, 2)), BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 2}, stars)
	round(d, 1)
	starFx[i] = {f = d, x = math.random(), y = math.random(), v = 0.01 + math.random() * 0.05, t = math.random() * 6.3}
end
local flash = mk("Frame", {Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
	BorderSizePixel = 0, ZIndex = 7}, field) -- line-clear white-out, faded by the render loop
local function blockLook(f) -- one block: body, outline and gloss; look() shapes and recolours it for the current style
	local cell = {f = f}
	cell.c = mk("UICorner", {CornerRadius = UDim.new(0, 3)}, f)
	cell.s = mk("UIStroke", {Color = WHITE, Transparency = 1, Thickness = 1}, f)
	cell.g = mk("Frame", {Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, f)
	mk("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(1, 1)})}, cell.g)
	cell.i = mk("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ImageRectSize = Vector2.new(64, 64), Visible = false}, f) -- one 64x64 tile of blocks.png
	return cell
end
local function look(cell, col, tr, n) -- shape, body, outline and gloss of one block (n = piece 1-7 for the texture tile)
	local st = THEMES[cfg.theme]
	cell.c.CornerRadius = UDim.new(0, st.r)
	cell.s.Thickness = st.thick
	cell.f.BackgroundColor3 = col and (st.fill > 0 and col:Lerp(BLACK, st.fill) or col) or WHITE
	cell.f.BackgroundTransparency = col and tr or 1
	if not col then cell.s.Transparency = 1
	elseif tr > 0.5 then cell.s.Color, cell.s.Transparency, cell.s.Thickness = col, 0.2, math.max(st.thick, 1) -- ghost outline
	elseif st.edge < 0 then cell.s.Color, cell.s.Transparency = col, 0.05 -- style draws the outline in the piece colour
	else cell.s.Color, cell.s.Transparency = col:Lerp(BLACK, st.edge), st.edge == 0 and 1 or 0.2 end
	cell.g.Visible = col ~= nil and tr < 0.5 and st.gloss
	cell.i.Visible = st.tex ~= nil and TEX ~= nil and n ~= nil and n <= 7 and col ~= nil and tr < 0.5
	if cell.i.Visible then -- the sheet is already shaded and coloured, so the drawn body steps aside
		cell.i.Image, cell.i.ImageRectOffset = TEX, Vector2.new(64 * (n - 1), 0)
		cell.f.BackgroundTransparency, cell.s.Transparency, cell.g.Visible = 1, 1, false
	end
end
local cells = {} -- 200 pooled cells; only repainted when their code changes
for r = 1, VIS do
	for c = 1, W do
		local f = mk("Frame", {Size = UDim2.new(0.1, -1, 0.05, -1), BorderSizePixel = 0, BackgroundTransparency = 1,
			ClipsDescendants = true, Position = UDim2.fromScale((c - 1) / W, (r - 1) / VIS), ZIndex = 3}, field)
		cells[(r - 1) * W + c] = blockLook(f)
	end
end
local msgLabel = txt("TextLabel", {Font = Enum.Font.GothamBold, Text = "", TextWrapped = true, Size = UDim2.fromScale(1, 0.12),
	Position = UDim2.fromScale(0, 0.3), ZIndex = 6}, field)
local overlay = txt("TextLabel", {Font = Enum.Font.GothamBold, Text = "", RichText = true, TextWrapped = true, Visible = false,
	BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), ZIndex = 8}, field)

local function panel()
	local f = mk("Frame", {BackgroundColor3 = Color3.fromRGB(8, 10, 18), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 2}, win)
	round(f, 8, true)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 6)}, f)
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
	for i = 1, 4 do
		m.cells[i] = blockLook(mk("Frame", {BorderSizePixel = 0, Visible = false, ClipsDescendants = true, ZIndex = 4}, f))
	end
	minis[#minis + 1] = m
	return m
end
local function setMini(m, t, dim)
	local key = t and (t .. (dim and "x" or "")) or ""
	if m.key == key then return end
	m.key = key
	for _, c in ipairs(m.cells) do c.f.Visible = false end
	if not t then return end
	local minc, maxc, minr = 9, 0, 9
	for _, v in ipairs(SHAPE[t][0]) do minc, maxc, minr = math.min(minc, v[1]), math.max(maxc, v[1]), math.min(minr, v[2]) end
	local off = (4 - (maxc - minc + 1)) / 2
	for i, v in ipairs(SHAPE[t][0]) do
		local c = m.cells[i]
		c.f.Position, c.f.Size = UDim2.fromScale((v[1] - minc + off) / 4, (v[2] - minr) / 2), UDim2.new(0.25, -1, 0.5, -1)
		c.f.Visible = true
		look(c, COL[TI[t]], dim and 0.6 or 0, TI[t])
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
	fxX, fxY = x0 + pw + gap, y0 -- the shake needs the home position to put the board back
	field.Position, field.Size = UDim2.fromOffset(fxX, fxY), UDim2.fromOffset(fw, fh)
	rightP.Position, rightP.Size = UDim2.fromOffset(x0 + pw + fw + 2 * gap, y0), UDim2.fromOffset(pw, fh)
	for _, m in ipairs(minis) do m.frame.Size = UDim2.fromOffset(pw - 8, (pw - 8) / 2) end
	stats.TextSize = math.clamp(math.floor(s * 0.55), 10, 20)
	msgLabel.TextSize = math.clamp(math.floor(s * 0.8), 12, 26)
	overlay.TextSize = math.clamp(math.floor(s * 0.9), 14, 28)
end
function applyTheme(n) -- colours, board gradient and block look of one theme; the render loop does the repaint
	n = THEMES[n] and n or 1 -- a saved theme that no longer exists falls back to the first
	cfg.theme, skinDirty = n, true
	local s, b = THEMES[n], THEMES[n].bg
	for i = 1, 7 do COL[i] = Color3.fromRGB(s.c[i * 3 - 2], s.c[i * 3 - 1], s.c[i * 3]) end
	fbg.Color = ColorSequence.new(Color3.fromRGB(b[1], b[2], b[3]), Color3.fromRGB(b[4], b[5], b[6]))
	fieldStroke.Color, fieldStroke.Transparency = COL[1], 0.55
	accentLine.BackgroundColor3, accentLine.BackgroundTransparency = COL[1], 0.35
end
applyTheme(cfg.theme)
task.spawn(loadBlocks) -- async: the texture repaint lands once the sheet is cached (or never, and the bevel stays)
-- [/WINDOW]

-- [BUBBLE]
-- Minimized bubble: draggable, upside-down-T tetromino logo, click restores ----------------------------------
local bubble = mk("Frame", {Name = "Bubble", Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(24, 120), Visible = false,
	Active = true, BackgroundColor3 = BG, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 1}, gui)
round(bubble, 28, true)
for _, p in ipairs({{1, 0}, {0, 1}, {1, 1}, {2, 1}}) do
	round(mk("Frame", {Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(10 + p[1] * 12, 16 + p[2] * 12),
		BackgroundColor3 = COL[3], BorderSizePixel = 0, ZIndex = 2}, bubble), 2)
end
-- [/BUBBLE]

-- [DRAG]
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
-- [/DRAG]

-- [OPTIONS]
-- Options panel shell (rows are added below, once the input code exists) ---------------------------------------
local focused, down, keyDown, map, capture = false, {}, {}, {}, nil
local settings = mk("Frame", {Position = UDim2.fromOffset(0, TITLE), Size = UDim2.new(1, 0, 1, -TITLE), Visible = false, Active = true,
	BackgroundColor3 = Color3.fromRGB(10, 12, 20), BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 20}, win)
local list = mk("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 21}, settings)
mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
mk("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 40)}, list)
local lbP = mk("Frame", {Size = UDim2.fromScale(1, 1), Visible = false, BackgroundTransparency = 1, ZIndex = 21}, settings) -- Scores tab
local lbMode, lbTabs, lbRows = 1, {}, {}
local RANKCOL = {Color3.fromRGB(255, 205, 64), Color3.fromRGB(205, 212, 228), Color3.fromRGB(218, 144, 84)} -- gold, silver, bronze
local CENTER, RIGHT = Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local LBC = {{0, 0.09, CENTER}, {0.09, 0.40, LEFT}, {0.49, 0.25, RIGHT}, {0.74, 0.11, RIGHT}, {0.85, 0.15, RIGHT}} -- column x, width, align
txt("TextLabel", {Text = "LEADERBOARD", Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = LEFT,
	Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 22), ZIndex = 22}, lbP)
txt("TextLabel", {Text = "Local top 10 per mode - names follow account renames", TextSize = 11, TextColor3 = DIM, TextXAlignment = LEFT,
	Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 14), ZIndex = 22}, lbP)
local tabRow = mk("Frame", {Position = UDim2.fromOffset(14, 52), Size = UDim2.new(1, -28, 0, 28), BackgroundTransparency = 1, ZIndex = 22}, lbP)
local function lbRow(y, h) -- one table row: 5 text cells at fixed column positions
	local f = mk("Frame", {Position = UDim2.new(0, 14, 0, y), Size = UDim2.new(1, -28, 0, h), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 22}, lbP)
	local c = {f = f}
	for i, d in ipairs(LBC) do
		c[i] = txt("TextLabel", {TextSize = 13, TextXAlignment = d[3], TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(d[1], i == 2 and 4 or 0, 0, 0), Size = UDim2.new(d[2], -6, 1, 0), ZIndex = 23}, f)
	end
	return c
end
local lbHead = lbRow(88, 18)
for i, t in ipairs({"#", "PLAYER", "SCORE", "LINES", "DATE"}) do lbHead[i].Text, lbHead[i].TextSize, lbHead[i].TextColor3 = t, 11, DIM end
for i = 1, 10 do
	local r = lbRow(108 + (i - 1) * 28, 26)
	round(r.f, 6)
	r[1].Font, r[3].Font, r[4].TextColor3, r[5].TextColor3 = Enum.Font.GothamBold, Enum.Font.GothamBold, DIM, DIM
	lbRows[i] = r
end
local lbEmpty = txt("TextLabel", {Text = "No runs yet - finish a game to get on the board.", TextColor3 = DIM, TextSize = 13,
	Position = UDim2.fromOffset(14, 116), Size = UDim2.new(1, -28, 0, 24), ZIndex = 22}, lbP)
local function showLb()
	local timed, me, data = lbMode == 2 or lbMode == 4, Players.LocalPlayer.UserId, lb["m" .. lbMode]
	lbHead[3].Text, lbEmpty.Visible = timed and "TIME" or "SCORE", #data == 0
	for i, r in ipairs(lbRows) do
		local e = data[i]
		r.f.Visible = e ~= nil
		if e then
			local mine, tc = e.u == me, RANKCOL[i] or TEXT
			r.f.BackgroundColor3 = mine and Color3.fromRGB(70, 90, 150) or Color3.fromRGB(34, 38, 58) -- your own runs stand out
			r.f.BackgroundTransparency = mine and 0.3 or (i % 2 == 0 and 0.75 or 0.6)
			r[1].Text, r[1].TextColor3, r[2].Text, r[2].TextColor3 = tostring(i), tc, e.n, tc
			r[3].Text, r[4].Text, r[5].Text = timed and clock(e.v) or fmt(e.v), tostring(e.l), os.date("%y-%m-%d", e.t)
		end
	end
	for m, b in ipairs(lbTabs) do
		local sel = m == lbMode
		b.BackgroundColor3, b.TextColor3 = sel and COL[1]:Lerp(BLACK, 0.45) or Color3.fromRGB(40, 46, 70), sel and WHITE or DIM
	end
end
for m, n in ipairs({"Marathon", "Sprint 40L", "Ultra 2:00", "Cheese 10"}) do
	local b = txt("TextButton", {Text = n, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, BackgroundTransparency = 0.2,
		Position = UDim2.new((m - 1) / 4, 0, 0, 0), Size = UDim2.new(0.25, -4, 1, 0), ZIndex = 23}, tabRow)
	round(b, 6)
	lbTabs[m] = b
	on(b.Activated, function() lbMode = m; showLb() end)
end
barBtn("Scores", 236, 68, function() setOptions(not lbP.Visible, true) end)
function setOptions(open, scores) -- scores = true shows the leaderboard instead of the option rows
	settings.Visible, list.Visible, lbP.Visible = open, not scores, open and scores == true
	optBtn.Text = open and "Back" or "Options"
	if open and scores then lbMode = tet.mode; showLb(); refreshNames(showLb) end
	if open then for a in pairs(down) do tet.release(a) end down = {} end -- no key may stay "held" while paused
end
-- [/OPTIONS]

-- [INPUT]
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
-- [/INPUT]

-- [OPTROWS]
-- Options rows -------------------------------------------------------------------------------------------------
local order, curSec = 0, nil
local function hint(text) -- one dim explanatory line, hidden together with its section
	order = order + 1
	local t = txt("TextLabel", {Text = text, TextSize = 11, TextColor3 = DIM, TextXAlignment = LEFT, TextWrapped = true,
		Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, ZIndex = 22}, list)
	if curSec then curSec.rows[#curSec.rows + 1] = t end
	return t
end
local function section(name) -- collapsible group header; clicking it hides every row that belongs to it
	order = order + 1
	local b = txt("TextButton", {Font = Enum.Font.GothamBold, TextSize = 12, BackgroundColor3 = Color3.fromRGB(30, 34, 52),
		BackgroundTransparency = 0.15, TextXAlignment = LEFT, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = order, ZIndex = 22}, list)
	round(b, 6)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 8)}, b)
	local sec = {btn = b, rows = {}, open = true}
	function sec.set(open)
		sec.open = open
		b.Text = (open and "-  " or "+  ") .. name
		for _, r in ipairs(sec.rows) do r.Visible = open end
	end
	on(b.Activated, function() sec.set(not sec.open) end)
	curSec = sec
	sec.set(true)
	return sec
end
local function row(name, class, text, extra)
	order = order + 1
	local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 22}, list)
	if curSec then curSec.rows[#curSec.rows + 1] = f end
	txt("TextLabel", {Text = name, TextXAlignment = LEFT, Size = UDim2.new(0.6, 0, 0, 30), ZIndex = 23}, f)
	local p = {Text = text, BackgroundColor3 = Color3.fromRGB(50, 56, 80), BackgroundTransparency = 0.2, Position = UDim2.new(0.62, 0, 0, 2),
		Size = UDim2.new(0.38, 0, 0, 26), ZIndex = 23}
	for k, v in pairs(extra or {}) do p[k] = v end
	local c = txt(class, p, f)
	round(c, 6)
	return c
end
local function opt(name, key) -- 0/1 setting shown as an On/Off button
	local b = row(name, "TextButton", cfg[key] == 1 and "On" or "Off")
	on(b.Activated, function() cfg[key] = 1 - cfg[key]; b.Text = cfg[key] == 1 and "On" or "Off"; save() end)
	return b
end
local openDrop -- close() of the one dropdown that is currently expanded
local function drop(name, key, items, lo, after) -- dropdown row, expands in place; stored value = lo + position - 1
	lo = lo or 1
	local b = row(name, "TextButton", items[cfg[key] - lo + 1])
	local f, opts = b.Parent, {}
	local function close()
		f.Size = UDim2.new(1, 0, 0, 30)
		for _, o in ipairs(opts) do o.Visible = false end
		if openDrop == close then openDrop = nil end
	end
	for i, label in ipairs(items) do
		local o = txt("TextButton", {Text = label, BackgroundColor3 = Color3.fromRGB(50, 56, 80), BackgroundTransparency = 0.2,
			Position = UDim2.new(0.62, 0, 0, 32 + (i - 1) * 26), Size = UDim2.new(0.38, 0, 0, 24), Visible = false, ZIndex = 23}, f)
		round(o, 6)
		opts[i] = o
		on(o.Activated, function()
			cfg[key], b.Text = lo + i - 1, label
			close()
			save()
			if after then after() end
		end)
	end
	on(b.Activated, function()
		if openDrop == close then close() return end
		if openDrop then openDrop() end
		openDrop = close
		f.Size = UDim2.new(1, 0, 0, 34 + #items * 26)
		for i, o in ipairs(opts) do
			o.BackgroundColor3 = lo + i - 1 == cfg[key] and Color3.fromRGB(88, 104, 160) or Color3.fromRGB(50, 56, 80)
			o.Visible = true
		end
	end)
	return b
end
section("Handling")
hint("Values are validated and applied instantly; the game pauses while Options is open.")
local function numRows(defs)
	for _, d in ipairs(defs) do
	local box = row(d[2], "TextBox", tostring(cfg[d[1]]), {ClearTextOnFocus = false})
	on(box.FocusLost, function()
		local n = tonumber(box.Text)
		if n then cfg[d[1]] = math.clamp(math.floor(n + 0.5), LIM[d[1]][1], LIM[d[1]][2]) end
		box.Text = tostring(cfg[d[1]]) -- invalid input snaps back to the last valid value
		save()
	end)
	end
end
numRows({{"das", "DAS (ms)"}, {"arr", "ARR (ms, 0 = instant)"}, {"sdr", "Soft drop (rows/s, 0 = instant)"},
	{"lock", "Lock delay (ms)"}, {"clear", "Line clear delay (ms)"}})
section("Spins")
hint("T-Spin: 3-corner rule (mini if one front corner, full if kick 5). Others: immobile rule.")
drop("Spin detection", "spin", {"T-Spin only", "All-Spin (full)", "All-Mini"})
section("Game")
hint("Changing the mode restarts the game; records are saved when file access exists.")
drop("Game mode", "mode", {"Marathon", "Sprint 40L", "Ultra 2:00", "Cheese 10"}, 1, function() tet.reset() end)
drop("Randomizer (next refill)", "rand", {"7-bag", "Random", "14-bag"})
drop("Next pieces shown", "nexts", {"0", "1", "2", "3", "4", "5"}, 0)
local recBtn = row("Records", "TextButton", "Reset all")
on(recBtn.Activated, function() for k in pairs(best) do best[k] = nil end; for k in pairs(lb) do lb[k] = {} end; save() end)
section("Visuals")
hint("One theme sets the colours and the block look. Textured draws blocks.png tiles; the others are drawn in Roblox.")
local themeNames = {}
for i, t in ipairs(THEMES) do themeNames[i] = t.n end
drop("Theme", "theme", themeNames, 1, function() applyTheme(cfg.theme) end)
opt("Ghost piece", "ghost")
opt("Snow / stars", "snow")
opt("Clear flash", "flash")
opt("Screen shake", "shake")
section("Gravity")
hint("Start level applies at the next lock or restart; idle pieces fall by themselves, then the game waits for a key.")
drop("Gravity mode", "gmode", {"Level curve", "Fixed speed", "Off (zen)", "Instant (20G)"})
numRows({{"grav", "Fixed speed (ms per row)"}, {"start", "Start level"}})
drop("Idle pieces before waiting", "idle", {"0", "1", "2", "3", "4", "5", "6", "7", "8"}, 0)
section("Controls")
hint("Click a key, then press the new one; Esc cancels; a used key swaps.")
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
-- [/OPTROWS]

-- [FOCUS]
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
-- [/FOCUS]

-- [RENDER]
-- Rendering: composes visible cells into codes (0 empty, 1-7 piece, 11-17 ghost, 20 clearing row) and repaints only changes.
local buf, shown, statT, lastOv, pauseT, overTxt, lastLines, fxT, fxN = {}, {}, 0, nil, 0, nil, 0, 0, 0
local snowOn = cfg.snow
for i = 1, VIS * W do shown[i] = -1 end
local function paint(cell, code)
	if code == 0 then look(cell)
	elseif code == 20 then look(cell, WHITE, 0.28)
	elseif code > 10 then look(cell, COL[code - 10], 0.86) -- ghost: outline only, so the stack reads through it
	else look(cell, COL[code], 0, code) end
end
local LBL = '<font color="#8f98b3">%s</font>'
local function stat(n, v) return string.format(LBL, n) .. "  " .. tostring(v) end
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
		local gy = cfg.ghost == 1 and tet.ghost() or p.y -- ghost off: skip the drop scan
		for _, v in ipairs(SHAPE[p.t][p.r]) do
			local r, i = gy + v[2] - base, (gy + v[2] - base - 1) * W + p.x + v[1]
			if r >= 1 and buf[i] == 0 then buf[i] = 10 + TI[p.t] end
		end
		for _, v in ipairs(SHAPE[p.t][p.r]) do
			local r = p.y + v[2] - base
			if r >= 1 then buf[(r - 1) * W + p.x + v[1]] = TI[p.t] end
		end
	end
	if skinDirty then -- skin changed: repaint every block and preview
		skinDirty = false
		for i = 1, VIS * W do shown[i] = -1 end
		for _, m in ipairs(minis) do m.key = false end
	end
	for i = 1, VIS * W do
		if buf[i] ~= shown[i] then shown[i] = buf[i]; paint(cells[i], buf[i]) end
	end
	if snowOn ~= cfg.snow then snowOn = cfg.snow; stars.Visible = snowOn == 1 end -- snow off: dots stop and hide
	if snowOn == 1 then
		for _, s in ipairs(starFx) do -- background drift + twinkle
			s.y = (s.y + s.v * dt) % 1
			s.t = s.t + dt * 1.7
			s.f.Position = UDim2.fromScale(s.x, s.y)
			s.f.BackgroundTransparency = 0.45 + 0.4 * math.abs(math.sin(s.t))
		end
	end
	if tet.lines ~= lastLines then -- a clear went through: white-out + shake, harder for more lines at once
		local n = tet.lines - lastLines
		lastLines = tet.lines
		if n > 0 then fxT, fxN = 0.3, math.min(n, 4) end
	end
	fxT = math.max(0, fxT - dt)
	flash.BackgroundTransparency = cfg.flash == 1 and (1 - (fxT / 0.3) * (0.12 + 0.1 * fxN)) or 1
	local amp = cfg.shake == 1 and math.floor(fxT / 0.3 * fxN * 2) or 0
	local jx, jy = amp > 0 and math.random(-amp, amp) or 0, amp > 0 and math.random(-amp, amp) or 0
	field.Position = UDim2.fromOffset(fxX + jx, fxY + jy)
	for i = 1, 5 do setMini(nextMinis[i], i <= cfg.nexts and tet.queue[i] or nil) end
	setMini(holdMini, tet.hold, not tet.canHold)
	if tet.msgT > 0 then msgLabel.Text, msgLabel.TextTransparency = tet.msg, math.clamp(1 - tet.msgT, 0, 1)
	elseif tet.waiting() then msgLabel.Text, msgLabel.TextTransparency = "PRESS A KEY", 0
	elseif msgLabel.Text ~= "" then msgLabel.Text = "" end
	statT = statT - dt
	if statT <= 0 then -- stats text refreshes at 10 Hz
		statT = 0.1
		local gl, gv = tet.goal()
		local timed, bv = tet.mode == 2 or tet.mode == 4, best["m" .. tet.mode]
		local r = {string.format(LBL, "SCORE") .. '\n<font size="18" color="#ffffff"><b>' .. fmt(tet.score) .. "</b></font>", stat("TIME", clock(tet.time)), stat("LINES", tet.lines),
			stat("LEVEL", tet.level)}
		if gl then r[#r + 1] = stat(gl, gv) end
		r[#r + 1] = stat("BEST", bv and (timed and clock(bv) or fmt(bv)) or "-")
		r[#r + 1] = stat("PIECES", tet.pieces - tet.p0)
		r[#r + 1] = stat("APM*", string.format("%.1f", tet.apm()))
		r[#r + 1] = stat("PPS", string.format("%.2f", tet.pps()))
		if tet.b2b > 1 then r[#r + 1] = stat("B2B", "x" .. tet.b2b - 1) end
		if tet.combo > 0 then r[#r + 1] = stat("COMBO", "x" .. tet.combo) end
		stats.Text = table.concat(r, "\n")
	end
	if tet.state ~= "over" then
		overTxt = nil
	elseif not overTxt then -- once per finished run: records + result text
		local timed, bk = tet.mode == 2 or tet.mode == 4, "m" .. tet.mode
		local v = timed and tet.won and tet.time or (not timed and tet.score) or nil
		local isBest = v and v > 0 and (not best[bk] or (timed and v < best[bk] or not timed and v > best[bk]))
		if isBest then best[bk] = v; save() end
		if v and v > 0 then addScore(tet.mode, v, timed) end
		local head = not tet.won and "GAME OVER" or tet.mode == 3 and "TIME UP\nSCORE " .. fmt(tet.score) or "FINISH\n" .. clock(tet.time)
		overTxt = head .. (isBest and "\nNEW BEST!" or "") .. '\n<font size="14">press ' .. keys.restart.Name .. " to restart</font>"
	end
	local ov = overTxt or (not focused and 'PAUSED\n<font size="14">click the window or press ' .. keys.toggle.Name .. "</font>") or ""
	if ov ~= lastOv then lastOv, overlay.Text, overlay.Visible = ov, ov, ov ~= "" end
end
-- The game only advances while the window is visible, focused and Options is closed (pause = no timers running, no stuck keys).
on(RunService.RenderStepped, function(dt)
	if not win.Visible then return end
	if focused and not settings.Visible then tet.update(math.min(dt, 0.1)); pauseT = 0
	else -- paused: nothing changes, so repaint at 10 Hz instead of every frame
		pauseT = pauseT - dt
		if pauseT > 0 then return end
		pauseT = 0.1
	end
	render(dt)
end)
-- [/RENDER]

-- [LIFE]
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
-- [/LIFE]
