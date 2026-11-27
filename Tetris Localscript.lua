-- NAV INDEX (tags are truth; line ranges auto-synced by apply_patch.py)
-- [DATA] constants, piece shapes, kick tables, scoring (PTS, PCX), fmt/clock, practice drills | SHAPE, KJ, KI, K180, PTS, PCX, fmt(), DRILLS, PCDRILLS, PCL, PRACN, drillPool() | deps: none | L31-263
-- [GAME] pure rules, no Roblox APIs | newGame(): press/release/update/ghost/reset/waiting/goal/progress, lock, spinKind, kicked, minKeys/finesse, loadPuzzle (spin / finesse / perfect-clear practice), fnote, modes, perfect clear | deps: DATA | L265-771
-- [SELFTEST] load-time logic asserts | selfTest() | deps: DATA, GAME | L773-856
-- [STATE] services, cfg, keys, best (records), lb (local top 10 per mode), save/load, game instance | cfg, keys, LIM, best, lb, save(), addScore(), refreshNames(), tet | deps: GAME | L859-974
-- [WINDOW] themes (colours + block look; Textured = blocks.png), window, playfield (gradient, starfield, flash), panels, layout | THEMES, TEX, loadBlocks(), applyTheme(), blockLook(), look(), layout(), setMini() | deps: STATE | L976-1247
-- [BUBBLE] minimized draggable logo | bubble | deps: WINDOW | L1249-1258
-- [DRAG] mouse release, drag, resize | reason(), dragger(), grip | deps: WINDOW | L1260-1327
-- [OPTIONS] options panel shell + Scores tab | settings, list, lbP, showLb(), setOptions(open, scores) | deps: WINDOW, STATE | L1329-1400
-- [INPUT] CAS key sink, focus, toggle | onKey(), bindSink(), setFocus(), toggle() | deps: OPTIONS | L1402-1458
-- [OPTROWS] collapsible options sections, rows, dropdowns, On/Off toggles, key capture | section(), hint(), row(), opt(), drop(), seg(), chips(), sub(), refreshGates(), numRows(), finishCapture() | deps: INPUT, STATE | L1460-1714
-- [FOCUS] click focus model | pointOf(), inside() | deps: INPUT | L1716-1737
-- [RENDER] paint cells, stats, records + leaderboard insert, overlay, frame loop | render(), paint(), stat(), RenderStepped | deps: STATE, WINDOW | L1739-1883
-- [LIFE] cleanup and startup | cleanup(), layout(), restore() | deps: all | L1885-1901

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

local W, H, VIS, SHAPE, TI, clock, fmt, PRACN, drillPool, newGame, selfTest -- the only names the UI layer needs from the logic layer below
do -- logic layer: its other helpers stay private (a script may hold at most 200 locals at once)
-- [DATA]
W, H, VIS = 10, 40, 20
local MAXRESET = 15 -- 10x40 board (bottom 20 rows visible); lock-delay reset cap per piece
local NAMES = {"I", "O", "T", "S", "Z", "J", "L"}
TI = {I = 1, O = 2, T = 3, S = 4, Z = 5, J = 6, L = 7}
local BASE = { -- spawn orientation as {col,row} inside the piece's bounding box
    I = {{0,1},{1,1},{2,1},{3,1}}, O = {{0,0},{1,0},{0,1},{1,1}}, T = {{1,0},{0,1},{1,1},{2,1}},
    S = {{1,0},{2,0},{0,1},{1,1}}, Z = {{0,0},{1,0},{1,1},{2,1}}, J = {{0,0},{0,1},{1,1},{2,1}}, L = {{2,0},{0,1},{1,1},{2,1}},
}
SHAPE = {} -- SHAPE[type][rotation 0..3]; each step is one 90-degree clockwise turn: (col,row) -> (n-1-row, col)
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
local MIR = {S = "Z", Z = "S", J = "L", L = "J"} -- mirror image of a piece
PRACN = {"Spin", "Finesse", "Perfect Clear"} -- practice types (cfg.prac)

-- Spin drills: p = piece, k = wanted spin ("T" full T-spin, "TM" mini, "S" all-spin), n = lines, rows = the stack (top to bottom, X = block).
-- Generated by a solver that ports these exact rules (SRS+ kicks, 3-corner / immobile): every drill is solvable with CW/CCW only,
-- no plain (non-spin) placement clears n lines, and the mirror image (S->Z, L->J) is solvable too (mirrored in loadPuzzle).
local DRILLS = {
    {p = "T", k = "T", n = 1, rows = {".....XX...", ".....X....", "XXXXXX.XXX", "X..X....XX", "X..XX..X.X"}},
    {p = "T", k = "T", n = 1, rows = {"......XXX.", "........XX", "XXXXXX...X", ".XX.X....X", "XXXXXX.XXX"}},
    {p = "T", k = "T", n = 1, rows = {"....X.....", "....XX....", "XXXXX...XX", "XX...X.XXX"}},
    {p = "T", k = "T", n = 1, rows = {"..XX......", "...XXXXXXX", "X.X..X.X.."}},
    {p = "T", k = "T", n = 1, rows = {"...X......", "..XX......", "...XXXXXXX", "X.X..XXX..", "XXXXXX.XXX", "XXXXXXXX.X"}},
    {p = "T", k = "T", n = 2, rows = {".X........", ".X...XX...", "XXX...XXXX", "XXXX.XXXXX"}},
    {p = "T", k = "T", n = 2, rows = {"XXX.......", "XX...XXXXX", "XXX.XXXXXX", "XXXX.XXXXX"}},
    {p = "T", k = "T", n = 2, rows = {".XX.......", "XX...XXXXX", "XXX.XXXXXX", "X.XXXXXXXX"}},
    {p = "T", k = "T", n = 2, rows = {".....XX...", "....XX....", "XX...XXXXX", "XXX.XXXXXX"}},
    {p = "T", k = "T", n = 2, rows = {".....X..XX", "XXXXXX...X", "XXXXXXX.XX"}},
    {p = "T", k = "T", n = 2, rows = {"..X.......", "..XX......", "...XXXXXXX", "X.XXXXXXXX", "X.XXXXXXXX"}},
    {p = "T", k = "T", n = 2, rows = {"........XX", "XXXXXX...X", "XXXXXXX.XX"}},
    {p = "T", k = "T", n = 3, rows = {".XX.......", ".X........", "XX.XXXXXXX", "XX..XXXXXX", "XX.XXXXXXX", "XXX.XXXXXX"}},
    {p = "T", k = "T", n = 3, rows = {"XX........", "X.........", "X.XXXXXXXX", "X..XXXXXXX", "X.XXXXXXXX"}},
    {p = "T", k = "T", n = 3, rows = {"...XX.....", "...X......", "XXXX.XXXXX", "XXXX..XXXX", "XXXX.XXXXX"}},
    {p = "T", k = "T", n = 3, rows = {"..XXX.....", "....X.....", "XX.XXXXXXX", "X..XXXXXXX", "XX.XXXXXXX"}},
    {p = "T", k = "T", n = 3, rows = {"..XX......", "...X......", "XX.XXXXXXX", "X..XXXXXXX", "XX.XXXXXXX"}},
    {p = "T", k = "T", n = 3, rows = {".....XXX..", ".......X..", "XXXXX.XXXX", "XXXX..XXXX", "XXXXX.XXXX", "XXXXX.XXXX"}},
    {p = "T", k = "TM", n = 1, rows = {"........X.", "X..X..XXXX", "XXXX...XXX", "X.XXXXXXXX"}},
    {p = "T", k = "TM", n = 1, rows = {"......XX..", "XXXXXXX...", "XX.XXXXX.X", "XXXXXXXX.X"}},
    {p = "T", k = "TM", n = 1, rows = {"...XXX..X.", "XXXXX...XX"}},
    {p = "T", k = "TM", n = 1, rows = {"X..XX..XXX", "XXXXX...XX", "XXXXXXXXX.", "XXXXXXX.XX"}},
    {p = "T", k = "TM", n = 1, rows = {"X.XXX..XXX", "XXXXX...XX"}},
    {p = "T", k = "TM", n = 1, rows = {".X.XX..X.X", "XXXX...XXX", "XXXXXXXX.X"}},
    {p = "S", k = "S", n = 1, rows = {"XX...X..X.", "X..XXXXXXX"}},
    {p = "S", k = "S", n = 1, rows = {"XXXXXXXX..", "XX..XXX..X"}},
    {p = "S", k = "S", n = 1, rows = {"...XX...X.", "XXXX..XXXX"}},
    {p = "S", k = "S", n = 1, rows = {"X.....XX..", "XXXXXXX..X"}},
    {p = "S", k = "S", n = 1, rows = {"XXXXXXXX..", ".XXX..X..X"}},
    {p = "S", k = "S", n = 2, rows = {"XXXXXXXX..", "XXXXXXX..X"}},
    {p = "S", k = "S", n = 2, rows = {"XXXX..XXXX", "XXX..XXXXX"}},
    {p = "S", k = "S", n = 2, rows = {"XXX..XXXXX", "XX..XXXXXX"}},
    {p = "S", k = "S", n = 2, rows = {".......X..", "XXXXXXXX..", "XXXXXXX..X"}},
    {p = "S", k = "S", n = 2, rows = {".......XX.", "XXXXX..XXX", "XXXX..XXXX"}},
    {p = "S", k = "S", n = 2, rows = {"XX..XXXXXX", "X..XXXXXXX"}},
    {p = "S", k = "S", n = 3, rows = {"......X...", "......X..X", "XXXXXXX.XX", "XXXXXXX..X", "XXXXXXXX.X"}},
    {p = "S", k = "S", n = 3, rows = {"...X......", "X.XXXXXXXX", "X..XXXXXXX", "XX.XXXXXXX"}},
    {p = "S", k = "S", n = 3, rows = {".......X..", "XXXXX.XXXX", "XXXXX..XXX", "XXXXXX.XXX"}},
    {p = "S", k = "S", n = 3, rows = {".....X....", ".....X..X.", "XXXXXX.XXX", "XXXXXX..XX", "XXXXXXX.XX"}},
    {p = "S", k = "S", n = 3, rows = {".........X", "XXXXXXX.XX", "XXXXXXX..X", "XXXXXXXX.X"}},
    {p = "L", k = "S", n = 1, rows = {".XX..XXX.X", "XX...XXXXX"}},
    {p = "L", k = "S", n = 1, rows = {".X.XXX..XX", "XXXXX...XX"}},
    {p = "L", k = "S", n = 1, rows = {".XXX.XXX..", "XXXXXXX..."}},
    {p = "L", k = "S", n = 1, rows = {"X....XXX..", "XXXXXXX..."}},
    {p = "L", k = "S", n = 1, rows = {"XXX.......", "X...XXXXXX", "X..X.....X"}},
    {p = "L", k = "S", n = 2, rows = {"XXXXXX.XXX", "XXXX...XXX"}},
    {p = "L", k = "S", n = 2, rows = {"XXXXXXXXX.", "XXXXXXX..."}},
    {p = "L", k = "S", n = 2, rows = {".....X....", ".....X....", "XXXX.XXXXX", "XX...XXXXX"}},
    {p = "L", k = "S", n = 2, rows = {"....X.....", "....X.....", "XXXXXXXX.X", "XXXXXX...X"}},
    {p = "L", k = "S", n = 2, rows = {".X........", "XXX.XXXXXX", "X...XXXXXX"}},
    {p = "L", k = "S", n = 2, rows = {"XXXXXXXX.X", "XXXXXX...X"}},
    {p = "L", k = "S", n = 3, rows = {"......XX..", "......X...", "XXXXXXX.XX", "XXXXXXX.XX", "XXXXXXX..X"}},
    {p = "L", k = "S", n = 3, rows = {"......XX..", "......X...", "XXXXXXX.XX", "XXXXXXX.XX", "XXXXXXX..X", "XXXXXX.XXX"}},
    {p = "L", k = "S", n = 3, rows = {"..XX......", "..X....X..", "XXXX.XXXXX", "XXXX.XXXXX", "XXXX..XXXX", "XXXXXX.XXX"}},
    {p = "L", k = "S", n = 3, rows = {"......XXX.", "......X...", "XXXXXXX.XX", "XXXXXXX.XX", "XXXXXXX..X"}},
    {p = "I", k = "S", n = 1, rows = {"....XX....", "XXXXX....X"}},
    {p = "I", k = "S", n = 1, rows = {"..X....XXX", "XXXX....XX", ".XXXXXXXXX", "XXXXXX.XXX"}},
    {p = "I", k = "S", n = 1, rows = {".....XXX..", "XXXXXX....", ".XXXXXXXXX"}},
    {p = "I", k = "S", n = 1, rows = {"...X..XXX.", "XXXX....XX"}},
}

-- Perfect-clear drills: q = the pieces you get, in order (no hold); rows = the stack. Empty the whole board.
-- Verified like DRILLS: reachable with CW/CCW only, every piece lands inside the gaps, the mirror image works too.
local PCDRILLS = {
    {q = "I", rows = {"XXXX.XXXXX", "XXXX.XXXXX", "XXXX.XXXXX", "XXXX.XXXXX"}},
    {q = "L", rows = {"XXXX.XXXXX", "XX...XXXXX"}},
    {q = "S", rows = {"XX..XXXXXX", "X..XXXXXXX"}},
    {q = "Z", rows = {"XX..XXXXXX", "XXX..XXXXX"}},
    {q = "J", rows = {"XXXXXXXX..", "XXXXXXXX.X", "XXXXXXXX.X"}},
    {q = "O", rows = {"XXXXXX..XX", "XXXXXX..XX"}},
    {q = "SO", rows = {"XX..XX..XX", "X..XXX..XX"}},
    {q = "TO", rows = {"XXXX..XXXX", "XXXX..XXXX", "XXXX...XXX", "XXXXX.XXXX"}},
    {q = "OJ", rows = {"..XXXXX.XX", "..XXXXX..."}},
    {q = "OS", rows = {"XX..XXXX..", "X..XXXXX.."}},
    {q = "OZ", rows = {"..XXX..XXX", "..XXXX..XX"}},
    {q = "OO", rows = {"XXX..XXX..", "XXX..XXX.."}},
    {q = "ZO", rows = {"XXXX..XX..", "XXXXX..X.."}},
    {q = "II", rows = {"X..XXXXXXX", "X..XXXXXXX", "X..XXXXXXX", "X..XXXXXXX"}},
    {q = "JJ", rows = {".XXX.XXXXX", "...X...XXX"}},
    {q = "LS", rows = {"XX.XXXX..X", "...XXX..XX"}},
    {q = "SL", rows = {"XXX..XX.XX", "XX..X...XX"}},
    {q = "OL", rows = {"XX.XXX..XX", "...XXX..XX"}},
    {q = "ZZ", rows = {"..XXX..XXX", "X..XXX..XX"}},
    {q = "LL", rows = {"XXXXXXXX..", "XXXXXX....", "XXXXXX.XX."}},
    {q = "JO", rows = {"XX...XXXXX", "XX.....XXX"}},
    {q = "LO", rows = {"..XXXXXX.X", "..XXXX...X"}},
}
-- Levels 2 and 3: generated by playing backwards from an empty board with this script's own kick and movement rules (CW/CCW only),
-- so every map is solvable (mirror too) and most need tucks. Level 2 = 3 pieces, up to 4 rows. Level 3 = 4-5 pieces, up to 5 rows.
local PCL = {PCDRILLS, {
        {q = "ISI", rows = {"....XXXX..", "X....XX..X"}},
        {q = "LOO", rows = {"..XX..XX.X", "..XX.....X"}},
        {q = "ZZI", rows = {"X..X......", "XX..X..XXX"}},
        {q = "OIO", rows = {"X........X", "X....XXXXX"}},
        {q = "JZZ", rows = {"....X.XXXX", "X.....XXXX", "XXXX..XXXX"}},
        {q = "LZO", rows = {"X...X..XXX", "X...XXXXXX", "X..XXX..XX"}},
        {q = "IJO", rows = {"XX..XXXX..", "XXXXXXXX.X", "XX.......X"}},
        {q = "JZS", rows = {"..XXX...XX", ".XXX..XXXX", ".XXX...XXX"}},
        {q = "JSI", rows = {"...X....XX", "...XXXXXXX", "..XXXXXXXX"}},
        {q = "ISL", rows = {"XXX....XXX", "XX.XXXXX..", "...XXXX..X"}},
        {q = "JLT", rows = {"...XXX..XX", "X.XX....XX", "XXXXXX..XX"}},
        {q = "IJS", rows = {"XX.X....XX", "XX...XX..X", "XXXXXX..XX"}},
        {q = "JJZ", rows = {"..X.....XX", "XXX.XXX.XX", "X...XXXXXX"}},
        {q = "LZI", rows = {"XX...XX..X", "XX.XXXXXXX", "XX....XX.."}},
        {q = "LSI", rows = {"XXXXXX.X..", "XXXX.....X", "XXXXX....X"}},
        {q = "OZO", rows = {"XXX..X....", "XXXXXXXX..", "XXXX....XX"}},
        {q = "LOJ", rows = {"X.....X.XX", "X.XXXXXXXX", "XXXX..X..."}},
        {q = "JZS", rows = {"XXXX.XXXXX", "..XX...X..", "X..XXXX..X"}},
        {q = "TTO", rows = {"X...XXXXXX", "...XXXX...", "..XXXXXX.X"}},
        {q = "TOL", rows = {"X....XXXXX", "X....XXXXX", "X....XXXXX"}},
        {q = "TOI", rows = {"...XXXXXXX", "X.XXXXXX..", "XXXX......"}},
        {q = "JTI", rows = {"XXX......X", "XXXX.XXX.X", "XXXX....XX"}},
        {q = "JOI", rows = {"..XX......", "..XXXXXX.X", "XXXXXXXX.X"}},
        {q = "JSZ", rows = {"XX..XXX.XX", "XX...XX...", "XX..XXXXXX", "XXX.XXXXXX"}},
        {q = "LJI", rows = {"XXXXXXXX..", "XX.XXXXXX.", "XX...XXXX.", "XXXX....XX"}},
        {q = "ZLI", rows = {"XX....X..X", "XXXXXXX..X", "XXXXXXX.XX", "XXXXX...XX"}},
        {q = "SIJ", rows = {"X.XX.....X", "X.X..XXXXX", "X.XXXXXX.X", "X.XXXXXXXX"}},
        {q = "IIS", rows = {".XXXXX.XXX", ".XX..X.XXX", ".XXXXX.XXX", ".X..XX.XXX"}},
        {q = "ZJO", rows = {"XX...XXXXX", "XXX..XX..X", "XX..XXXXXX", "XX.XXXX..X"}},
        {q = "ZTO", rows = {"XXXXX...XX", "XXXXX....X", "XXXXXXX..X", "XXXXXXX..."}},
        {q = "ILZ", rows = {"XXX...XXX.", "XXX.XXXXX.", "XXXXXX..X.", "XXXXXXX..."}},
        {q = "ZTI", rows = {"XXX....XXX", "XXXXX...XX", "XXXXXX..XX", "XXXXXX...X"}},
        {q = "STI", rows = {"...X....XX", "XXXXXX.XXX", "XXXXXX..XX", "X.XXXXX.XX"}},
        {q = "SZO", rows = {"X..X..XXXX", "..XXXXXXXX", "XX..X..XXX", "XX..XXXXXX"}},
        {q = "TIS", rows = {".XXXX..XXX", ".XXX...XXX", ".XXXX.XXXX", ".XXX..XXXX"}},
        {q = "JZZ", rows = {"X..XX..XXX", "X.XX..XXXX", "X.XXX..XXX", "XXXXXX..XX"}},
        {q = "OZJ", rows = {"X..XXXX...", "X..XXXXXXX", "X..XXXXXXX", "XX..XXXXX."}},
        {q = "LOT", rows = {"XXX.XXXXXX", "X...XXX..X", "...XXXX..X", "X.XXXXXXXX"}},
        {q = "ZIL", rows = {"X...X....X", "XXXXXX..XX", "XXXXXXX..X", "X.XXXXXXXX"}},
        {q = "IJT", rows = {"XXX.XXXX..", "XXX....X.X", "XXX.X.XX.X", "XXX.XXXXXX"}},
        {q = "TLL", rows = {"...XXXXXXX", "X....XXXXX", "XX....XXXX", "XXX.XXXXXX"}},
        {q = "IJL", rows = {"XXXXXXX.XX", "X..X....XX", "X.XX.XX.XX", "X.XXXXX.XX"}},
        {q = "IOL", rows = {".XXXXXXXXX", ".X..X...XX", ".X..X.XXXX", ".XXXXXXXXX"}},
        {q = "LIO", rows = {"X.XXXXX...", "X.XXXXX...", "X.XXXXX..X", "X.XXXXXXXX"}},
    }, {
        {q = "JOSL", rows = {"XX.......X", "XXXXXXX...", "XX.X..X..."}},
        {q = "JIOL", rows = {"X......XX.", "XXXX.XXXXX", "X..X......"}},
        {q = "OTOI", rows = {"..XXX.....", "XXXXX..X..", "..XXX..XX."}},
        {q = "ZLLI", rows = {"......XXX.", "X.....X...", "XXX.XXXXXX"}},
        {q = "ZIOS", rows = {"..X....XXX", "X......XXX", "XX..X..XXX"}},
        {q = "JSLI", rows = {"X...XX...X", "X.XXX..X.X", "XXX......X"}},
        {q = "ZJSO", rows = {"XXX....X..", "XX...XXX.X", "XXX..XXXXX", "XXX.X..X.X"}},
        {q = "IOOL", rows = {"XX......XX", "XX...X..XX", "XXXX.X..XX", "XXXX..XXXX"}},
        {q = "LJIT", rows = {"XXXXXXXX.X", "...X.X...X", "X.XX...XXX", "X....XXXXX"}},
        {q = "LTOO", rows = {"X..X..X...", "XXXXX.XX..", "XXXXX.XXXX", "X..XXXX..."}},
        {q = "IITO", rows = {"XX...XX.X.", "X....XX.X.", "XXXXXXX.X.", "XX.XXXX.X."}},
        {q = "OOOL", rows = {"X.....XX..", "X..XXXXXXX", "X..XXXXXXX", "X.XX..XX.."}},
        {q = "SIZI", rows = {"X..X....XX", "XX.....XXX", "XXXXXX..XX", "XX..XXX.XX"}},
        {q = "SOOI", rows = {"XXXXXXXX..", "XXXXXXX..X", "X..XXXXX..", "X..X......"}},
        {q = "JOOO", rows = {"X..X..X..X", "X..X..X..X", "...XXXXXXX", "XX.XXXXXXX"}},
        {q = "OZSI", rows = {"XX..XXX..X", "XXX..XX..X", "XXX....X..", "XXXXXXX..X"}},
        {q = "JOOZ", rows = {"....XX..XX", "..X..X..XX", "XXXXXX.XXX", "XXXXXX...X"}},
        {q = "IJII", rows = {"X..X.....X", "XXXX.XXXXX", "XXXX.XXXXX", "X.XX.XXXXX", "X.XXXX...."}},
        {q = "IJJT", rows = {"XXXXXXXX.X", "...XXXXX.X", "XX.XX.XX.X", "XX.......X", "XXX.XXXXXX"}},
        {q = "SJJL", rows = {"XX....XXXX", "X..X.XXXXX", "XXXX....XX", "XXXXXX.XXX", "XXX....XXX"}},
        {q = "LIJS", rows = {"XX..XX.X..", "XXXX...XXX", "X..X.X.X.X", "XXXXXX.X.X", "XXXXXX.XXX"}},
        {q = "IIJLO", rows = {"X..XX....X", "XXXX.....X", "...XX.XX.X", "...XXXXX.X"}},
        {q = "OOIZO", rows = {"XX.X....XX", "XX.....XXX", "XX.....XXX", "XX.X..X..X"}},
        {q = "IIIZI", rows = {".XX......X", ".XX....XXX", ".....XXX..", ".XXXXXXXXX"}},
        {q = "OTOZJ", rows = {"..X..XX..X", "..X..X...X", "XXXX......", "XXXXXX.XXX"}},
        {q = "ITLIO", rows = {"....XXX...", "X.....XX.X", "X.....XXXX", "XX..XXXXXX"}},
        {q = "OLLLL", rows = {".XX.....XX", "........XX", "..XXX..XXX", "XXXXX..XXX"}},
        {q = "JOZOI", rows = {"..X...XX..", "XXXXX.XXXX", "XXXXXXXX..", "X..XXXX..X", "X....XX..X"}},
        {q = "IJITI", rows = {"X...X.X...", "XXXXX....X", "XX.XX.XXX.", "XXXXX.XXXX", "XXXXX....."}},
        {q = "LIOOI", rows = {".XXXX....X", ".XXXX...XX", "XXXXX.XXXX", ".XXXXXXXXX", ".........X"}},
    }}
function drillPool(c, all) -- every (drill, mirrored) spin puzzle that matches the piece / line toggles in c (all = ignore the toggles)
    local pool = {}
    for _, d in ipairs(DRILLS) do
        for _, mir in ipairs({false, true}) do
            local pc = mir and MIR[d.p] or d.p
            local lines = d.k == "TM" and c.mini == 1 or d.k ~= "TM" and c["ln" .. d.n] == 1
            if all or (c["sp" .. pc] == 1 and lines) then pool[#pool + 1] = {d, mir} end
        end
    end
    return pool
end
local function emptyRow() local r = {} for c = 1, W do r[c] = 0 end return r end
function clock(t) return string.format("%d:%05.2f", math.floor(t / 60), t % 60) end
function fmt(n) return (tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end
-- [/DATA]

-- [GAME]
-- cfg (read live, so setting changes apply instantly): das/arr/lock/clear in ms, sdr rows/s (0 = instant), spin 1|2|3,
-- gmode 1 level curve|2 fixed|3 off|4 instant, grav ms/row (mode 2), start level, idle = pieces that fall before the game waits for input,
-- mode 1 Marathon|2 Sprint 40L|3 Ultra 2:00|4 Cheese 10|6 Zen (the only mode with adjustable gravity) (read at reset), rand 1 7-bag|2 random|3 14-bag
function newGame(cfg, rnd)
    local g, held, pend, act = {}, {}, {}, {}
    local hdir, hT, hDone, hFresh, gAcc, lockT, resets, lowest = nil, 0, 0, false, 0, 0, 0, 0
    local spawn, lock
    local function key(label) -- one counted key press (finesse) and what it was
        g.keys = g.keys + 1
        g.used[#g.used + 1] = label
    end

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
local function kicked(t, r, x, y, d) -- first kick that fits: new rotation, x, y and kick number (nil if none)
        if t == "O" then return end
        local nr = (r + d) % 4
        for i, k in ipairs((d == 2 and K180 or t == "I" and KI or KJ)[r .. ">" .. nr]) do
            if fits(t, nr, x + k[1], y - k[2]) then return nr, x + k[1], y - k[2], i end
        end
    end
    local function rotate(d)
        local p = g.cur
        local nr, nx, ny, i = kicked(p.t, p.r, p.x, p.y, d)
        if not nr then return end
        p.r, p.x, p.y, p.spun, p.kick = nr, nx, ny, true, d == 2 and 0 or i -- 180 kicks never count as the T-spin 5th-kick rule
        touch()
    end
    -- Finesse: breadth-first search over key presses (tap, DAS slide, rotate, soft drop; hard drop is free) from the spawn spot
    local function fall(t, r, x, y) while fits(t, r, x, y + 1) do y = y + 1 end return y end
    local function cellsOf(t, r, x, y) -- sorted cells of a placement, each encoded row * 100 + col
        local c = {}
        for i, v in ipairs(SHAPE[t][r]) do c[i] = (y + v[2]) * 100 + x + v[1] end
        table.sort(c)
        return c
    end
    local function goalOf(t, cells) -- every (rotation, x) whose piece covers exactly these cells -> the y it sits at
        local goal, key, top = {}, table.concat(cells, ","), math.floor(cells[1] / 100)
        for r = 0, 3 do
            local mn = 9
            for _, v in ipairs(SHAPE[t][r]) do mn = math.min(mn, v[2]) end
            for x = -3, W do
                if table.concat(cellsOf(t, r, x, top - mn), ",") == key then goal[r * 32 + x + 8] = top - mn end
            end
        end
        return goal
    end
    local LAB = {"Left", "Right", "DAS Left", "DAS Right", "CW", "CCW", "180", "Soft Drop"}
    local function minKeys(t, sx, sy, goal) -- fewest presses to reach any goal placement, and the presses themselves
        local function id(x, y, r) return (r * 64 + y) * 32 + x + 8 end
        local dist, from, q, qi = {[id(sx, sy, 0)] = 0}, {}, {{sx, sy, 0}}, 1
        while qi <= #q do
            local x, y, r = q[qi][1], q[qi][2], q[qi][3]
            qi = qi + 1
            local me = id(x, y, r)
            local gy = goal[r * 32 + x + 8]
            if gy and y <= gy and fall(t, r, x, y) == gy then
                local path, n = {}, dist[me]
                while from[me] do table.insert(path, 1, LAB[from[me][2]]); me = from[me][1] end
                return n, path
            end
            local function go(nx, ny, nr, e)
                local n = id(nx, ny, nr)
                if not dist[n] then dist[n], from[n] = dist[me] + 1, {me, e}; q[#q + 1] = {nx, ny, nr} end
            end
            for dx = -1, 1, 2 do
                if fits(t, r, x + dx, y) then go(x + dx, y, r, dx < 0 and 1 or 2) end
                local nx = x
                while fits(t, r, nx + dx, y) do nx = nx + dx end
                if nx ~= x then go(nx, y, r, dx < 0 and 3 or 4) end
            end
            for i, d in ipairs({1, -1, 2}) do
                local nr, nx, ny = kicked(t, r, x, y, d)
                if nr then go(nx, ny, nr, 4 + i) end
            end
            local ny = fall(t, r, x, y)
            if ny ~= y then go(x, ny, r, 8) end
        end
    end
    local function finesse(p, cells) -- (faults, fewest keys, key path) for a placement; cells = judge that target instead
        local opt, path = minKeys(p.t, g.sx, g.sy, goalOf(p.t, cells or cellsOf(p.t, p.r, p.x, p.y)))
        return opt and math.max(0, g.keys - opt) or 0, opt, path
    end
    local function fnote(fa, opt, path, always) -- "last piece" note: verdict, keys used vs best, and how it could have been placed better (suggestions on, or always in the finesse trainer)
        local route = ""
        if path and opt and (always or cfg.fbest == 1) then
            route = '\n<font color="#9aa3c0">You: ' .. (#g.used > 0 and table.concat(g.used, " + ") or "hard drop only")
                .. '</font>\n<font color="#96d2ff">Better: ' .. (#path > 0 and table.concat(path, " + ") or "hard drop only") .. "</font>"
        end
        if not fa then return '<font color="#ff8282"><b>MISS</b></font>' .. route end -- fa = nil: wrong spot
        if not opt then return "" end
        if fa == 0 then return string.format('<font color="#6fe38a"><b>PERFECT</b></font>\n%d keys', g.keys) end
        return string.format('<font color="#ff8282"><b>FINESSE +%d</b></font>\nUsed %d, best %d', fa, g.keys, opt) .. route
    end
    local function loadPuzzle(same) -- practice: set up the next puzzle (or the same one again after a miss)
        for r = 1, H do g.board[r] = emptyRow() end
        g.hold, g.canHold, g.tgt, g.cells = nil, false, nil, 0 -- one piece per puzzle: no hold
        if cfg.prac == 2 then -- finesse trainer: empty board, a piece and a target spot to reach
            if not (same and g.keep) then
                g.queue = {}
                refill()
                local t = g.queue[1]
                for _ = 1, 8 do -- skip pieces that are switched off in the options
                    if cfg["fn" .. t] == 1 then break end
                    table.remove(g.queue, 1)
                    refill()
                    t = g.queue[1]
                end
                local opts, seen = {}, {}
                for r = 0, 3 do
                    local mx = 0
                    for _, v in ipairs(SHAPE[t][r]) do mx = math.max(mx, v[2]) end
                    for x = -3, W do
                        if fits(t, r, x, H - mx) then
                            local cells = cellsOf(t, r, x, H - mx)
                            local key = table.concat(cells, ",")
                            if not seen[key] then seen[key] = true; opts[#opts + 1] = {t = t, cells = cells, key = key} end
                        end
                    end
                end
                g.keep = opts[rnd(#opts)]
            end
            g.tgt, g.dr = g.keep, nil
            g.queue = {g.tgt.t}
        else
            if not (same and g.dr) then
                if cfg.prac == 3 then
                    local pl = PCL[cfg.plv] or PCDRILLS
                    g.dr, g.mir = pl[rnd(#pl)], rnd(2) == 2
                else
                    local pool = drillPool(cfg)
                    if #pool == 0 then pool = drillPool(cfg, true) end -- nothing matches the toggles: use every drill
                    local e = pool[rnd(#pool)]
                    g.dr, g.mir = e[1], e[2]
                end
            end
            local d = g.dr
            for i, row in ipairs(d.rows) do
                local s, r = g.mir and row:reverse() or row, H - #d.rows + i
                for c = 1, W do if s:sub(c, c) == "X" then g.board[r][c], g.cells = 8, g.cells + 1 end end
            end
            if d.q then -- perfect clear: several pieces, in order
                g.queue, g.pcLeft = {}, #d.q
                for i = 1, #d.q do
                    local t = d.q:sub(i, i)
                    g.queue[i] = g.mir and MIR[t] or t
                end
            else
                g.queue = {g.mir and MIR[d.p] or d.p}
            end
        end
        refill()
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
        local sm = g.mode == 5 and 2 or cfg.spin -- practice always detects every spin
        if sm == 1 or free(-1, 0) or free(1, 0) or free(0, -1) then return nil end
        return sm == 2 and "S" or "SM"
    end
    local function removeRows(rows)
        for i = #rows, 1, -1 do table.remove(g.board, rows[i]) end
        for _ = 1, #rows do table.insert(g.board, 1, emptyRow()) end
    end

    spawn = function(t)
        if g.prpend and not t then g.prpend = false; loadPuzzle(g.prsame) end
        t = t or table.remove(g.queue, 1)
        refill()
        local p = {t = t, r = 0, x = t == "O" and 5 or 4, y = 19, spun = false}
        g.cur = p
        gAcc, lockT, resets = 0, 0, 0
        g.since = 0
        if not fits(t, 0, p.x, p.y) then g.cur, g.state = nil, "over" return end -- block out
        if free(0, 1) then p.y = p.y + 1 end
        lowest = p.y
        g.sx, g.sy, g.keys, g.used, g.hidx = p.x, p.y, 0, {}, nil -- finesse: spawn spot, presses used so far and what they were
        if hFresh and hdir then -- direction pressed during the line-clear delay: apply once at spawn
            if move(hdir == "left" and -1 or 1) then
                touch()
                key(hdir == "left" and "Left" or "Right")
                g.hidx = #g.used
            end
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
        local tg = g.mode == 5 and g.tgt
        local fa, fopt, fpath = 0
        if cfg.fin == 1 or tg then fa, fopt, fpath = finesse(p, tg and tg.cells) end
        local fkey = table.concat(cellsOf(p.t, p.r, p.x, p.y), ",")
        for _, v in ipairs(SHAPE[p.t][p.r]) do
            local r = p.y + v[2]
            if r > H - VIS then out = false end
            g.board[r][p.x + v[1]] = TI[p.t]
        end
        g.cur, g.pieces, g.cells = nil, g.pieces + 1, g.cells + 4
        g.cut = (cfg.dcd or 0) / 1000 -- DAS cut delay: no auto-shift for a moment after a lock
        if cfg.dcl == 1 then hT, hDone = 0, 0 end -- cancel DAS on lock
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
        if cfg.fin == 1 and not tg and not (cfg.fskip == 1 and kind) then -- finesse counter (spin placements can be skipped in the options)
            g.fp = g.fp + 1
            if fa > 0 then g.ff, g.fbad = g.ff + fa, g.fbad + 1 end
            g.fmsg = fnote(fa, fopt, fpath)
        end
        if g.mode == 5 then -- practice: judge the attempt; the next spawn loads the next puzzle (or the same one again)
            local ok, done = false, true
            if tg then
                ok = fkey == tg.key and fa == 0
                g.fmsg = fnote(fkey == tg.key and fa or nil, fopt, fpath, true)
                if not ok then g.msg = fkey == tg.key and ("FINESSE +" .. fa) or "MISS" end
            elseif g.dr.q then -- perfect clear: empty the board with the queued pieces
                ok, g.pcLeft = pc, g.pcLeft - 1
                done = ok or g.pcLeft <= 0
            else
                local d = g.dr
                ok = p.t == (g.mir and MIR[d.p] or d.p) and kind == d.k and n == d.n
            end
            if done then
                if not ok and not tg then g.msg = "RETRY" end
                if ok then g.msg = tg and "PERFECT" or ("SOLVED\n" .. g.msg) end
                g.msgT, g.try = 2, g.try + 1
                if ok then g.ok, g.streak = g.ok + 1, g.streak + 1 else g.streak = 0 end
                g.prpend, g.prsame = true, not ok and cfg.retry == 1
            end
        end
        g.lines = g.lines + n
        g.level, g.canHold = (g.mode == 6 and cfg.start or 1) + math.floor(g.lines / 10), true
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

    act.cw = function() key("CW"); rotate(1) end
    act.ccw = function() key("CCW"); rotate(-1) end
    act.r180 = function() key("180"); rotate(2) end
    act.hold = function()
        if not g.canHold then return end
        local old = g.hold
        g.canHold, g.hold = false, g.cur.t
        if cfg.dch == 1 then hT, hDone = 0, 0 end -- cancel DAS on hold
        spawn(old)
    end
    act.hard = function()
        if g.since < (cfg.hdl or 0) / 1000 then return end -- hard drop lockout after a spawn
        local n = 0
        while drop1() do n = n + 1 end
        g.score = g.score + 2 * n
        lock()
    end

    function g.press(a) -- executed immediately (no per-frame polling), so fast taps are never skipped
        if g.state == "over" then return end
        if not g.started then g.started, g.p0, g.attack = true, g.pieces, 0 end -- first input starts the clock (PPS/APM count from here)
        if a == "left" or a == "right" then
            local keep = cfg.dsw == 2 and hdir and hdir ~= a and hT or 0 -- "Keep DAS charge": the new direction inherits the charge
            held[a], hdir, hT, hDone = true, a, keep, 0
            if not g.cur then hFresh = true
            else
                key(a == "left" and "Left" or "Right")
                g.hidx = #g.used
                if move(a == "left" and -1 or 1) then touch() end
            end
        elseif a == "soft" then
            if not held.soft and g.cur then key("Soft Drop") end
            held.soft = true
        elseif g.cur then act[a]()
        elseif a ~= "hard" and cfg.irs ~= 0 and #pend < 4 then pend[#pend + 1] = a end
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
        g.since, g.cut = g.since + dt, math.max(0, g.cut - dt)
        local das, arr = cfg.das / 1000, cfg.arr / 1000
        if g.state == "clear" then
            if hdir and cfg.dcl ~= 1 and g.cut <= 0 then hT = math.min(hT + dt, das) end -- DAS keeps charging through the delay
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
        if hdir and g.cut <= 0 then -- 1) horizontal DAS / ARR (bounded: at most 10 successful steps, never blocks the steps below)
            hT = hT + dt
            if hT >= das then
                local dx, moved = hdir == "left" and -1 or 1, false
                if arr <= 0 then
                    local sd = held.soft and cfg.sdr <= 0 -- instant soft drop wins: fall into every gap before sliding on
                    while true do
                        if sd then while drop1() do g.score = g.score + 1 end end
                        if not move(dx) then break end
                        moved = true
                    end
                else
                    local due = math.floor((hT - das) / arr) + 1
                    while hDone < due do
                        hDone = hDone + 1
                        if move(dx) then moved = true else hDone = due end
                    end
                end
                if moved then
                    touch()
                    local u = g.hidx and g.used[g.hidx]
                    if u == "Left" or u == "Right" then g.used[g.hidx] = "DAS " .. u end -- the tap grew into a slide
                end
            end
        end
        local lv = math.min(g.level, 30) -- 2) gravity / soft drop (same frame as 1, so pieces never hover)
        local m = g.mode == 5 and 3 or (g.mode == 6 and cfg.gmode or 1) -- only Zen can change gravity; every other mode stays on the standard level curve -- 1 level curve | 2 fixed ms/row | 3 off | 4 instant
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
            if lockT >= cfg.lock / 1000 and g.mode ~= 5 then lock() end
        end
    end

    function g.ghost()
        local p, y = g.cur, g.cur.y
        while fits(p.t, p.r, p.x, y + 1) do y = y + 1 end
        return y
    end
    function g.apm() return g.time > 0 and g.attack * 60 / g.time or 0 end
    function g.pps() return g.time > 0 and (g.pieces - g.p0) / g.time or 0 end
    function g.waiting() return not g.started and g.state == "play" and (g.mode == 5 or g.pieces >= cfg.idle) end
    function g.goal() -- label, value of the mode's objective (nil for Marathon)
        if g.mode == 2 then return "TO GO", math.max(0, 40 - g.lines)
        elseif g.mode == 3 then return "LEFT", clock(math.max(0, 120 - g.time))
        elseif g.mode == 4 then return "GARBAGE", g.garb end
    end
    function g.progress() -- 0..1 toward the mode's finish (Marathon: toward the next level)
        if g.mode == 5 then return math.min(1, g.streak / 10)
        elseif g.mode == 2 then return g.lines / 40
        elseif g.mode == 3 then return g.time / 120
        elseif g.mode == 4 then return 1 - g.garb / 10 end
        return (g.lines % 10) / 10
    end
    function g.skip() -- restart key: practice swaps in a fresh puzzle and keeps the session stats; every other mode restarts
        if g.mode == 5 and g.state == "play" then g.prpend, g.prsame, g.cur = true, false, nil; spawn()
        else g.reset() end
    end
    function g.reset()
        g.board, g.queue, g.hold, g.cur, g.rows = {}, {}, nil, nil, nil
        for r = 1, H do g.board[r] = emptyRow() end
        g.score, g.lines, g.level, g.pieces, g.attack, g.time = 0, 0, cfg.mode == 6 and cfg.start or 1, 0, 0, 0
        g.started, g.p0, g.won, g.mode, g.cells, g.garb = false, 0, false, cfg.mode, 0, 0
        if g.mode == 4 then -- Cheese: 10 garbage rows with one hole each; clear them all
            for r = H - 9, H do
                local hole = rnd(W)
                for c = 1, W do g.board[r][c] = c == hole and 0 or 8 end
            end
            g.cells, g.garb = 90, 10
        end
        g.b2b, g.combo, g.msg, g.msgT, g.canHold, g.state = 0, -1, "", 0, true, "play"
        g.fp, g.ff, g.fbad, g.fmsg, g.keys, g.sx, g.sy = 0, 0, 0, "", 0, 4, 19 -- finesse counters
        g.used, g.hidx = {}, nil
        g.ok, g.try, g.streak, g.dr, g.mir, g.tgt, g.keep = 0, 0, 0, nil, false, nil, nil -- practice session
        g.prpend, g.prsame = g.mode == 5, false
        pend, hT, hDone, hFresh = {}, 0, 0, false
        g.cut, g.since = 0, 0
        refill()
        spawn()
    end
    g.reset()
    return g
end
-- [/GAME]

-- [SELFTEST]
-- SELF-CHECK: runs once at load (pure logic, no UI). A failure only warns; it never stops the game.
function selfTest()
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
    g.reset(); g.board[40][3] = 1; g.cur = {t = "I", r = 0, x = 5, y = 20, spun = false} -- the press-tap moves it to x = 4 -- falls first, so the slide is blocked
    g.press("soft"); g.press("left"); g.update(0.2)
    assert(g.cur.x == 4, "soft drop beats instant ARR")
    g.reset(); for r = 39, 40 do for _, c in ipairs({1, 2, 3, 4, 7, 8, 9, 10}) do g.board[r][c] = 1 end end -- 2-wide gap between two ledges
    g.cur = {t = "O", r = 0, x = 3, y = 37, spun = false}
    g.press("soft"); g.press("right"); g.update(0.2)
    assert(g.cur.x == 5 and g.cur.y == 39, "instant soft drop falls into the gap instead of sliding past it")
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
    g.release("soft"); g.release("left"); g.release("right") -- earlier checks left keys held
    cfg0.fin, cfg0.mode = 1, 1; g.reset() -- finesse: one DAS slide is optimal, four taps are not
    g.press("left"); g.update(0.2); g.release("left"); g.press("hard")
    assert(g.fp == 1 and g.ff == 0, "finesse: DAS slide is optimal")
    for _ = 1, 4 do g.press("left"); g.release("left") end
    g.press("hard")
    assert(g.ff == 3, "finesse: extra taps are faults")
    cfg0.fin = nil
    for _, d in ipairs(DRILLS) do -- drill data sanity
        assert(SHAPE[d.p] and #d.rows >= 2, "drill piece")
        for _, row in ipairs(d.rows) do assert(#row == W and not row:find("[^X.]"), "drill row") end
    end
    cfg0.gmode, cfg0.start = 4, 15 -- gravity is locked outside Zen: instant gravity and start level must be ignored
    g.reset(); y0 = g.cur.y
    g.press("left"); g.update(0.1); g.release("left")
    assert(g.level == 1 and g.cur.y <= y0 + 1, "gravity locked outside Zen")
    cfg0.mode = 6; g.reset(); y0 = g.cur.y
    g.press("left"); g.update(0.1); g.release("left")
    assert(g.level == 15 and g.cur.y > y0 + 5, "Zen takes the gravity setting")
    cfg0.mode, cfg0.gmode, cfg0.start = 1, 1, 1
    cfg0.dch = 1; g.reset(); g.press("left"); g.update(0.2); g.press("hold"); local hx = g.cur.x; g.update(0.05)
    assert(g.cur.x == hx, "cancel DAS on hold")
    cfg0.dch = nil; g.release("left")
    cfg0.hdl = 300; g.reset(); g.press("hard")
    assert(g.pieces == 0, "hard drop lockout")
    cfg0.hdl = nil
    cfg0.mode, cfg0.prac = 5, 1; g.reset()
    assert(g.dr and g.cur and g.cur.t == (g.mir and MIR[g.dr.p] or g.dr.p), "practice puzzle")
    cfg0.prac = 2; g.reset()
    assert(g.tgt and g.cur and g.cur.t == g.tgt.t, "finesse target")
    cfg0.prac = 3; g.reset()
    assert(g.dr and g.dr.q and g.cur, "perfect clear puzzle")
    for _, lvl in ipairs(PCL) do for _, d in ipairs(lvl) do -- every level: valid rows and pieces, and a cell count a perfect clear can reach
        local n = 4 * #d.q
        for _, row in ipairs(d.rows) do assert(#row == W and not row:find("[^X.]"), "pc drill row"); n = n + select(2, row:gsub("X", "")) end
        assert(n % 10 == 0 and not d.q:find("[^IOTSZJL]"), "pc drill cells")
    end end
    cfg0.mode = 1
end
-- [/SELFTEST]
end -- logic layer

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
    mode = 1, rand = 1, ghost = 1, nexts = 5, theme = 1, snow = 1, flash = 1, shake = 1, fin = 1, prac = 1, ln1 = 1, ln2 = 1, ln3 = 1, mini = 1, retry = 1, fbest = 1, fskip = 0, dcl = 0, dcd = 0, dch = 0, dsw = 1, irs = 1, hdl = 0, plv = 1}
local keys = {left = Enum.KeyCode.Left, right = Enum.KeyCode.Right, soft = Enum.KeyCode.Down, hard = Enum.KeyCode.Space,
    cw = Enum.KeyCode.Up, ccw = Enum.KeyCode.Z, r180 = Enum.KeyCode.X, hold = Enum.KeyCode.C, restart = Enum.KeyCode.R, toggle = Enum.KeyCode.RightControl}
local LIM = {das = {0, 500}, arr = {0, 200}, sdr = {0, 500}, lock = {0, 3000}, clear = {0, 2000},
    grav = {1, 5000}, start = {1, 30}, idle = {0, 8}, mode = {1, 6}, rand = {1, 3}, ghost = {0, 1}, nexts = {0, 5},
    theme = {1, 6}, snow = {0, 1}, flash = {0, 1}, shake = {0, 1}, fin = {0, 1}, prac = {1, 3}, ln1 = {0, 1}, ln2 = {0, 1}, ln3 = {0, 1}, mini = {0, 1}, retry = {0, 1}, fbest = {0, 1}, fskip = {0, 1}, dcl = {0, 1}, dcd = {0, 500}, dch = {0, 1}, dsw = {1, 2}, irs = {0, 1}, hdl = {0, 500}, plv = {1, 3}}
for _, t in ipairs({"T", "S", "Z", "L", "J", "I", "O"}) do -- piece toggles: sp* = spin drills (T only by default), fn* = finesse trainer (all)
    if t ~= "O" then cfg["sp" .. t], LIM["sp" .. t] = t == "T" and 1 or 0, {0, 1} end
    cfg["fn" .. t], LIM["fn" .. t] = 1, {0, 1}
end

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
-- piece colour, 0: none), thick = outline width, gloss = top highlight band, file = PNG sheet in the repo drawn instead of the body (7 square tiles in a row, I O T S Z J L; tile = tile size px, ord = tile column per piece if the order differs); the drawn look is the fallback.
-- cfg.theme is the index (keep LIM.theme in step); applyTheme() repaints the board on the next frame.
local THEMES = {
    { n = "Default", file = "blocks.png", fill = 0, r = 2, edge = 0.45, thick = 1, gloss = true, bg = {18, 22, 38, 5, 6, 12},
        c = {0, 229, 255, 255, 213, 0, 176, 76, 240, 80, 224, 100, 245, 64, 64, 72, 110, 255, 255, 152, 48} },
    { n = "Glossy", fill = 0, r = 3, edge = 0.45, thick = 1, gloss = true, bg = {10, 16, 20, 3, 4, 6},
        c = {34, 196, 214, 224, 176, 32, 148, 48, 196, 56, 168, 88, 200, 40, 56, 44, 72, 196, 200, 108, 32} },
    { n = "Flat", fill = 0, r = 0, edge = 0, thick = 0, gloss = false, bg = {38, 36, 52, 14, 13, 20},
        c = {132, 224, 246, 255, 232, 148, 202, 166, 255, 166, 232, 170, 255, 170, 170, 152, 186, 255, 255, 202, 152} },
    { n = "Neon", fill = 0.55, r = 4, edge = -1, thick = 2, gloss = false, bg = {22, 4, 34, 6, 2, 14},
        c = {120, 240, 255, 255, 230, 120, 255, 80, 220, 80, 255, 200, 255, 80, 130, 110, 120, 255, 255, 140, 200} },
    -- flat blocks with a lighter top edge and a darker bottom edge (bevel), the four.lol look
    { n = "four.lol", gap = 0, fill = 0, r = 0, edge = 0, thick = 0, gloss = false, bevel = true, bg = {10, 10, 12, 0, 0, 0},
        -- colours I O T S Z J L, garbage (g), and the lighter strip colour per piece + garbage (top); all colours sampled from the four.lol reference pixels
        c = {66, 175, 225, 246, 208, 60, 151, 57, 162, 81, 184, 77, 235, 79, 101, 17, 101, 181, 243, 137, 39}, g = {134, 134, 134},
        top = {108, 234, 255, 255, 255, 127, 217, 88, 233, 132, 248, 128, 255, 127, 121, 51, 155, 255, 255, 186, 89, 221, 221, 221} },
    -- glass bevel blocks from gems.png (replaces the old Puyo skin): row 1 = solid I O T S Z J L, row 2 = glowing ghost tiles (gh); gap 0 so blocks touch
    { n = "Gem", file = "puyo2.png", gh = true, gap = 0, fill = 0, r = 2, edge = 0.45, thick = 1, gloss = true, bg = {10, 10, 12, 0, 0, 0},
        c = {6, 171, 233, 233, 185, 6, 177, 6, 233, 95, 233, 6, 233, 6, 8, 6, 110, 233, 233, 106, 6} }, -- body colours sampled from the reference blocks
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
local TOPC = {} -- theme's lighter top-strip colours per piece (bevel styles)
local TEX = {} -- sheet file name -> local asset id; a sheet that is missing makes its style fall back to the drawn look
local function loadBlocks(file) -- fetch one sheet once, cache it, then repaint (needs an executor with getcustomasset)
    if not canFile or type(getcustomasset) ~= "function" or TEX[file .. "?"] then return end
    TEX[file .. "?"] = true -- one attempt per sheet per run: no duplicate downloads, a missing sheet is not retried on every theme switch
    -- shortcut: the cached sheet never refreshes by itself; bump the _v number in the path below whenever a sheet changes on GitHub
    local path, url = (file == "blocks.png" and "TetrisBlocks_v2.png" or "Tetris_v2_" .. file), "https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/" .. file
    local ok, id = pcall(function()
        local okRead, cached = pcall(function() return readfile(path):sub(1, 4) == "\137PNG" end)
        if not okRead or not cached then -- no file yet, or an HTML error page was cached earlier: download again
            local body = game:HttpGet(url)
            assert(type(body) == "string" and body:sub(1, 4) == "\137PNG", "blocks.png download failed")
            writefile(path, body)
        end
        return getcustomasset(path)
    end)
    if ok and type(id) == "string" then
        TEX[file] = id
        if THEMES[cfg.theme].file == file then skinDirty = true end -- only the sheet in use repaints the board
    end
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
local barTrack = mk("Frame", {BackgroundColor3 = Color3.fromRGB(8, 10, 18), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 2}, win) -- progress bar beside the board
round(barTrack, 2)
local barFill = mk("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3}, barTrack)
round(barFill, 2)
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
    cell.t = mk("Frame", {Position = UDim2.fromScale(0, -3 / 16), Size = UDim2.fromScale(1, 3 / 16), BorderSizePixel = 0, Visible = false}, f) -- bevel style: a lighter strip above a block whose top is exposed
    
    cell.h = mk("Frame", {Position = UDim2.fromScale(0.16, 0.13), Size = UDim2.fromScale(0.34, 0.2), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false}, f) -- shine spot
    mk("UICorner", {CornerRadius = UDim.new(0.5, 0)}, cell.h)
    return cell
end
local function look(cell, col, tr, n, top) -- shape, body, outline and gloss of one block (n = piece 1-7 for the texture tile)
    local st = THEMES[cfg.theme]
    cell.c.CornerRadius = st.rs and UDim.new(st.rs, 0) or UDim.new(0, st.r) -- rs = radius as a fraction of the block
    cell.s.Thickness = st.thick
    if cell.sw then cell.f.Size = UDim2.new(cell.sw, -(st.gap or 1), cell.sh, -(st.gap or 1)) end -- gap 0: blocks touch
    cell.t.Position = cell.inner and UDim2.new() or UDim2.fromScale(0, -3 / 16) -- bevel strip: above the block on the board, inside it in previews
    cell.f.BackgroundColor3 = col and (st.fill > 0 and col:Lerp(BLACK, st.fill) or col) or WHITE
    cell.f.BackgroundTransparency = col and tr or 1
    if not col then cell.s.Transparency = 1
    elseif tr > 0.5 then cell.s.Color, cell.s.Transparency, cell.s.Thickness = col, 0.2, math.max(st.thick, 1) -- ghost outline
    elseif st.edge < 0 then cell.s.Color, cell.s.Transparency = col, 0.05 -- style draws the outline in the piece colour
    else cell.s.Color, cell.s.Transparency = col:Lerp(BLACK, st.edge), st.edge == 0 and 1 or 0.2 end
    cell.g.Visible = col ~= nil and tr < 0.5 and st.gloss
    local solid = col ~= nil and tr < 0.5
    cell.t.Visible, cell.h.Visible = solid and st.bevel == true and top == true, solid and st.shine == true
    cell.f.ClipsDescendants = st.bevel ~= true -- the strip pokes out above the block
    if solid then cell.t.BackgroundColor3 = n and TOPC[n] or col:Lerp(WHITE, 0.35) end
    local sheet = st.file and TEX[st.file] -- nil until the sheet is downloaded: the drawn look shows meanwhile
    local gh = st.gh == true and col ~= nil and tr > 0.85 -- col nil = empty cell, which comes with no tr: comparing nil with a number threw every frame -- sheet row 2 holds the ghost tiles (hold-preview dimming is 0.6, finesse target has no n)
    cell.i.Visible = sheet ~= nil and n ~= nil and n <= 7 and col ~= nil and (tr < 0.5 or gh)
    if cell.i.Visible then -- the sheet is already shaded and coloured, so the drawn body steps aside
        local tile = st.tile or 64
        cell.i.Image, cell.i.ImageRectSize, cell.i.ImageRectOffset = sheet, Vector2.new(tile, tile), Vector2.new(tile * ((st.ord and st.ord[n] or n) - 1), gh and tile or 0)
        cell.f.BackgroundTransparency, cell.s.Transparency, cell.g.Visible, cell.t.Visible, cell.h.Visible = 1, 1, false, false, false
    end
end
local cells = {} -- 200 pooled cells; only repainted when their code changes
for r = 1, VIS do
    for c = 1, W do
        local f = mk("Frame", {Size = UDim2.new(0.1, -1, 0.05, -1), BorderSizePixel = 0, BackgroundTransparency = 1,
            ClipsDescendants = true, Position = UDim2.fromScale((c - 1) / W, (r - 1) / VIS), ZIndex = 3}, field)
        local k = blockLook(f)
        k.sw, k.sh = 0.1, 0.05 -- base size as a fraction of the board; look() subtracts the style's gap
        cells[(r - 1) * W + c] = k
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
        local k = blockLook(mk("Frame", {BorderSizePixel = 0, Visible = false, ClipsDescendants = true, ZIndex = 4}, f))
        k.sw, k.sh, k.inner = 0.25, 0.5, true -- preview block: its strip stays inside it, so it never pokes into the next preview
        m.cells[i] = k
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
        c.f.Position = UDim2.fromScale((v[1] - minc + off) / 4, (v[2] - minr) / 2) -- size comes from look()
        c.f.Visible = true
        local top = true -- bevel strip only where no other cell of the piece sits above
        for _, w in ipairs(SHAPE[t][0]) do if w[1] == v[1] and w[2] == v[2] - 1 then top = false end end
        look(c, COL[TI[t]], dim and 0.6 or 0, TI[t], top)
    end
end
title(leftP, "HOLD", 1)
local holdMini = mini(leftP, 2)
local stats = txt("TextLabel", {Text = "", RichText = true, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top,
    Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, ZIndex = 3}, leftP)
txt("TextLabel", {Text = "*APM uses a local attack estimate (no opponents here).", TextSize = 10, TextColor3 = DIM, TextWrapped = true,
    TextXAlignment = LEFT, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, ZIndex = 3}, leftP)
local finTitle = txt("TextLabel", {Text = "LAST PIECE", TextSize = 12, TextColor3 = DIM, TextXAlignment = LEFT, Size = UDim2.new(1, -8, 0, 16), LayoutOrder = 5, ZIndex = 3}, leftP)
local finBox = txt("TextLabel", {Text = "", RichText = true, TextWrapped = true, TextSize = 12, TextXAlignment = LEFT, TextYAlignment = Enum.TextYAlignment.Top,
    Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 6, ZIndex = 3}, leftP) -- finesse verdict + a better route
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
    barTrack.Position, barTrack.Size = UDim2.fromOffset(fxX - 7, fxY), UDim2.fromOffset(5, fh)
    rightP.Position, rightP.Size = UDim2.fromOffset(x0 + pw + fw + 2 * gap, y0), UDim2.fromOffset(pw, fh)
    local q = math.floor((pw - 8) / 4) -- whole-pixel preview blocks, so touching blocks leave no hairline
    for _, m in ipairs(minis) do m.frame.Size = UDim2.fromOffset(q * 4, q * 2) end
    stats.TextSize = math.clamp(math.floor(s * 0.55), 10, 20)
    msgLabel.TextSize = math.clamp(math.floor(s * 0.8), 12, 26)
    finBox.TextSize = math.clamp(math.floor(s * 0.45), 9, 15)
    overlay.TextSize = math.clamp(math.floor(s * 0.9), 14, 28)
end
function applyTheme(n) -- colours, board gradient and block look of one theme; the render loop does the repaint
    n = THEMES[n] and n or 1 -- a saved theme that no longer exists falls back to the first
    cfg.theme, skinDirty = n, true
    if THEMES[n].file then task.spawn(loadBlocks, THEMES[n].file) end -- sheets load on demand: only the selected theme's, no startup downloads for skins nobody uses
    local s, b = THEMES[n], THEMES[n].bg
    for i = 1, 7 do COL[i] = Color3.fromRGB(s.c[i * 3 - 2], s.c[i * 3 - 1], s.c[i * 3]) end
    COL[8] = s.g and Color3.fromRGB(s.g[1], s.g[2], s.g[3]) or Color3.fromRGB(110, 118, 140) -- garbage / Cheese rows
    TOPC = {}
    for i = 1, 8 do if s.top then TOPC[i] = Color3.fromRGB(s.top[i * 3 - 2], s.top[i * 3 - 1], s.top[i * 3]) end end
    fbg.Color = ColorSequence.new(Color3.fromRGB(b[1], b[2], b[3]), Color3.fromRGB(b[4], b[5], b[6]))
    fieldStroke.Color, fieldStroke.Transparency = COL[1], 0.55
    accentLine.BackgroundColor3, accentLine.BackgroundTransparency = COL[1], 0.35
end
applyTheme(cfg.theme)

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
for m, n in ipairs({"Marathon", "40 Lines", "Blitz", "Cheese"}) do
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
    if open and scores then lbMode = tet.mode <= 4 and tet.mode or lbMode; showLb(); refreshNames(showLb) end
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
        if a == "restart" then if begin then tet.skip() end
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
local finishCapture -- the only helper the rest of the script needs from the rows builder below
do -- options rows builder: its helpers stay private (a script may hold at most 200 locals at once)
local order, curSec = 0, nil
local gates, secs = {}, {} -- gates[row] = function telling when a row shows; secs = every section
local function hint(text, gate) -- one dim explanatory line, hidden together with its section
    order = order + 1
    local t = txt("TextLabel", {Text = text, TextSize = 11, TextColor3 = DIM, TextXAlignment = LEFT, TextWrapped = true,
        Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, ZIndex = 22}, list)
    gates[t] = gate
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
        for _, r in ipairs(sec.rows) do r.Visible = open and (not gates[r] or gates[r]()) end
    end
    on(b.Activated, function() sec.set(not sec.open) end)
    secs[#secs + 1] = sec
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
local function opt(name, key, gate) -- 0/1 setting shown as an On/Off button (gate = when the row shows)
    local b = row(name, "TextButton", cfg[key] == 1 and "On" or "Off")
    gates[b.Parent] = gate
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
local function refreshGates() for _, s in ipairs(secs) do s.set(s.open) end end -- re-evaluate which gated rows show
local function seg(name, key, items, lo, after, gate) -- segmented selector: one button per choice, all visible at once
    lo = lo or 1
    order = order + 1
    local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 22}, list)
    if curSec then curSec.rows[#curSec.rows + 1] = f end
    gates[f] = gate
    txt("TextLabel", {Text = name, TextSize = 12, TextColor3 = DIM, TextXAlignment = LEFT, Size = UDim2.new(1, 0, 0, 18), ZIndex = 23}, f)
    local btns = {}
    local function paint()
        for i, b in ipairs(btns) do
            local sel = cfg[key] == lo + i - 1
            b.BackgroundColor3, b.TextColor3 = sel and Color3.fromRGB(70, 100, 190) or Color3.fromRGB(40, 46, 70), sel and WHITE or DIM
        end
    end
    for i, label in ipairs(items) do
        local b = txt("TextButton", {Text = label, Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, BackgroundTransparency = 0.1,
            Position = UDim2.new((i - 1) / #items, 0, 0, 20), Size = UDim2.new(1 / #items, -4, 0, 28), ZIndex = 23}, f)
        round(b, 6)
        btns[i] = b
        on(b.Activated, function()
            cfg[key] = lo + i - 1
            paint()
            save()
            if after then after() end
        end)
    end
    paint()
    return f
end
local function chips(name, defs, after, gate) -- independent on/off chips, defs = {{cfgKey, label}, ...}
    order = order + 1
    local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 22}, list)
    if curSec then curSec.rows[#curSec.rows + 1] = f end
    gates[f] = gate
    txt("TextLabel", {Text = name, TextSize = 12, TextColor3 = DIM, TextXAlignment = LEFT, Size = UDim2.new(1, 0, 0, 18), ZIndex = 23}, f)
    local btns = {}
    local function paint()
        for i, d in ipairs(defs) do
            local sel = cfg[d[1]] == 1
            btns[i].BackgroundColor3, btns[i].TextColor3 = sel and Color3.fromRGB(70, 100, 190) or Color3.fromRGB(40, 46, 70), sel and WHITE or DIM
        end
    end
    for i, d in ipairs(defs) do
        btns[i] = txt("TextButton", {Text = d[2], Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false, BackgroundTransparency = 0.1,
            Position = UDim2.new((i - 1) / #defs, 0, 0, 20), Size = UDim2.new(1 / #defs, -4, 0, 28), ZIndex = 23}, f)
        round(btns[i], 6)
        on(btns[i].Activated, function()
            cfg[d[1]] = 1 - cfg[d[1]]
            paint()
            save()
            if after then after() end
        end)
    end
    paint()
    return f
end
local function sub(o) -- indent a row under the control that owns it, with a thin accent bar
    mk("UIPadding", {PaddingLeft = UDim.new(0, 14)}, o)
    mk("Frame", {Size = UDim2.new(0, 3, 1, -6), Position = UDim2.fromOffset(-12, 3), BackgroundColor3 = Color3.fromRGB(70, 100, 190), BorderSizePixel = 0, ZIndex = 23}, o)
end
local function inPractice() return cfg.mode == 5 end
local function inSpin() return cfg.mode == 5 and cfg.prac == 1 end
local function inFinesse() return cfg.mode == 5 and cfg.prac == 2 end
local function inZen() return cfg.mode == 6 end
local function inPC() return cfg.mode == 5 and cfg.prac == 3 end
local function restartPractice() if cfg.mode == 5 then tet.reset() end end
section("Game")
seg("Game mode", "mode", {"Marathon", "40 Lines", "Blitz", "Cheese", "Practice", "Zen"}, 1, function() tet.reset(); refreshGates() end)
-- Practice options open right under the mode selector, and only while Practice is picked
local cnt
local function recount()
    local n = #drillPool(cfg)
    cnt.Text = n > 0 and (n .. " puzzles match") or "Nothing matches - every spin drill is used until you turn a piece on"
end
sub(seg("Practice type", "prac", {"Spin", "Finesse", "Perfect Clear"}, 1, function() restartPractice(); refreshGates() end, inPractice))
sub(seg("Perfect Clear level", "plv", {"1 Easy", "2 Medium", "3 Hard"}, 1, restartPractice, inPC))
sub(chips("Spin pieces (Z and J are mirrors of S and L)", {{"spT", "T"}, {"spS", "S"}, {"spZ", "Z"}, {"spL", "L"}, {"spJ", "J"}, {"spI", "I"}},
    function() recount(); restartPractice() end, inSpin))
sub(chips("Lines", {{"ln1", "1 line"}, {"ln2", "2 lines"}, {"ln3", "3 lines"}, {"mini", "T-Mini"}}, function() recount(); restartPractice() end, inSpin))
cnt = hint("", inSpin)
sub(cnt)
sub(chips("Finesse pieces", {{"fnT", "T"}, {"fnS", "S"}, {"fnZ", "Z"}, {"fnL", "L"}, {"fnJ", "J"}, {"fnI", "I"}, {"fnO", "O"}}, restartPractice, inFinesse))
sub(opt("Retry the same puzzle after a miss", "retry", inPractice).Parent)
sub(hint("Hard drop locks the piece, R skips the puzzle. Spin: clear the lines with the right spin. Finesse: reach the outlined spot with the fewest keys. Perfect Clear: empty the board.", inPractice))
seg("Randomizer (next refill)", "rand", {"7-bag", "Random", "14-bag"})
seg("Next pieces shown", "nexts", {"0", "1", "2", "3", "4", "5"}, 0)
local recBtn = row("Records", "TextButton", "Reset all")
on(recBtn.Activated, function() for k in pairs(best) do best[k] = nil end; for k in pairs(lb) do lb[k] = {} end; save() end)
order = order + 1
local play = txt("TextButton", {Text = "Play", Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(70, 100, 190),
    BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = order, ZIndex = 22}, list)
round(play, 8)
curSec.rows[#curSec.rows + 1] = play
on(play.Activated, function() setOptions(false) end)
section("Finesse")
hint("Every piece is judged against the fewest possible key presses (tap, DAS slide, rotate, soft drop; hard drop is free). Suggestions show, after a faulty placement, what you pressed and a better way to place it.")
opt("Finesse counter", "fin")
opt("Finesse suggestions", "fbest")
opt("Skip finesse on spins", "fskip")
section("Handling")
hint("Values are validated and applied instantly; the game pauses while Options is open.")
local function numRows(defs, gate)
    for _, d in ipairs(defs) do
    local box = row(d[2], "TextBox", tostring(cfg[d[1]]), {ClearTextOnFocus = false})
    gates[box.Parent] = gate
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
numRows({{"dcd", "DAS cut delay (ms)"}, {"hdl", "Hard drop lockout (ms)"}})
opt("Cancel DAS on lock", "dcl")
opt("Cancel DAS on hold", "dch")
opt("Initial rotate / hold (IRS)", "irs")
seg("Direction switch", "dsw", {"Restart DAS", "Keep DAS charge"})
hint("Cancel DAS on lock / hold restarts the DAS charge when a piece locks or you hold. DAS cut delay pauses auto-shift for that long after a lock. Hard drop lockout ignores hard drop for that long after a piece appears. IRS buffers rotate and hold pressed before the next piece appears. Keep DAS charge: pressing the other direction carries the charge over instead of restarting it.")
section("Spins")
hint("T-Spin: 3-corner rule (mini if one front corner, full if kick 5). Others: immobile rule.")
seg("Spin detection (Practice always detects every spin)", "spin", {"T-Spin only", "All-Spin", "All-Mini"})

section("Visuals")
hint("One theme sets the colours and the block look. Default, four.lol and Gem use the PNG sheets blocks.png, fourlol.png and puyo2.png from the GitHub repo (a drawn look shows until a sheet downloads, or if it is missing); Glossy, Flat and Neon are drawn in Roblox.")
local themeNames = {}
for i, t in ipairs(THEMES) do themeNames[i] = t.n end
seg("Theme", "theme", themeNames, 1, function() applyTheme(cfg.theme) end)
opt("Ghost piece", "ghost")
opt("Snow / stars", "snow")
opt("Clear flash", "flash")
opt("Screen shake", "shake")
section("Gravity")
hint("Gravity follows the standard level curve (start level 1) in every mode except Zen. Speed mode, fixed speed and start level only show and apply in Zen. Idle pieces fall by themselves, then the game waits for a key.")
seg("Gravity mode (Zen only)", "gmode", {"Level curve", "Fixed speed", "Off", "Instant (20G)"}, 1, nil, inZen)
numRows({{"grav", "Fixed speed (ms per row)"}, {"start", "Start level"}}, inZen)
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
function finishCapture(code)
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
for i = 3, #secs do secs[i].set(false) end -- Game and Finesse stay open, the other sections start collapsed
refreshGates()
recount()
end -- options rows builder
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
    local top = code > 30 -- bevel style: nothing solid above this block (see render)
    if top then code = code - 30 end
    if code == 0 then look(cell)
    elseif code == 20 then look(cell, WHITE, 0.28)
    elseif code == 21 then look(cell, WHITE, 0.8) -- finesse target
    elseif code > 10 then look(cell, COL[code - 10], 0.86, code - 10) -- ghost: outline only, so the stack reads through it
    else look(cell, COL[code], 0, code, top) end
end
local LBL = '<font color="#8f98b3">%s</font>'
local MODEN = {"MARATHON", "40 LINES", "BLITZ", "CHEESE", "PRACTICE", "ZEN"}
local MODEC = {Color3.fromRGB(176, 76, 240), Color3.fromRGB(0, 229, 255), Color3.fromRGB(255, 213, 0), Color3.fromRGB(255, 152, 48), Color3.fromRGB(80, 224, 100), Color3.fromRGB(90, 200, 255)}
local barV = 0 -- displayed progress, eased toward tet.progress()
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
    if tet.tgt then -- finesse trainer: outline of the spot to reach
        for _, v in ipairs(tet.tgt.cells) do
            local i = (math.floor(v / 100) - base - 1) * W + v % 100
            if buf[i] == 0 then buf[i] = 21 end
        end
    end
    if THEMES[cfg.theme].bevel then -- a block with nothing solid above it gets the lighter top strip: mark it +30 so it repaints when its neighbour changes
        for i = 1, VIS * W do
            local v = buf[i]
            if v >= 1 and v <= 8 then
                local a = i > W and buf[i - W] or 0
                if not (a >= 1 and a <= 8 or a >= 31 and a <= 38) then buf[i] = v + 30 end
            end
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
    barV = barV + (tet.progress() - barV) * math.min(1, dt * 10) -- eased, so a clear reads as motion
    barFill.Size, barFill.BackgroundColor3 = UDim2.fromScale(1, math.clamp(barV, 0, 1)), MODEC[tet.mode]
    if tet.msgT > 0 then msgLabel.Text, msgLabel.TextTransparency = tet.msg, math.clamp(1 - tet.msgT, 0, 1)
    elseif tet.waiting() then msgLabel.Text, msgLabel.TextTransparency = "PRESS A KEY", 0
    elseif msgLabel.Text ~= "" then msgLabel.Text = "" end
    local fn = cfg.fin == 1 and tet.fmsg or "" -- finesse verdict for the last piece, in the left card
    if finBox.Text ~= fn then finBox.Text = fn end
    finTitle.Visible = fn ~= ""
    statT = statT - dt
    if statT <= 0 then -- stats text refreshes at 10 Hz
        statT = 0.1
        local timed, bv, m = tet.mode == 2 or tet.mode == 4, best["m" .. tet.mode], tet.mode
        local bl, bg = "SCORE", fmt(tet.score) -- headline = the mode's objective, TETR.IO style
        if m == 2 then bl, bg = "LINES", tet.lines .. " / 40"
        elseif m == 3 then bl, bg = "TIME LEFT", clock(math.max(0, 120 - tet.time))
        elseif m == 4 then bl, bg = "GARBAGE LEFT", tostring(tet.garb)
        elseif m == 5 then bl, bg = cfg.prac == 2 and "PERFECT" or "SOLVED", tet.ok .. " / " .. tet.try end
        local r = {'<font color="#' .. MODEC[m]:ToHex() .. '"><b>' .. MODEN[m] .. "</b></font>",
            string.format(LBL, bl) .. '\n<font size="18" color="#ffffff"><b>' .. bg .. "</b></font>", stat("TIME", clock(tet.time))}
        if m ~= 1 and m ~= 6 then r[#r + 1] = stat("SCORE", fmt(tet.score)) end
        if m ~= 2 then r[#r + 1] = stat("LINES", tet.lines) end
        r[#r + 1] = stat("LEVEL", tet.level)
        r[#r + 1] = stat("BEST", bv and (timed and clock(bv) or fmt(bv)) or "-")
        r[#r + 1] = stat("PIECES", tet.pieces - tet.p0)
        r[#r + 1] = stat("APM*", string.format("%.1f", tet.apm()))
        r[#r + 1] = stat("PPS", string.format("%.2f", tet.pps()))
        if tet.b2b > 1 then r[#r + 1] = stat("B2B", "x" .. tet.b2b - 1) end
        if tet.combo > 0 then r[#r + 1] = stat("COMBO", "x" .. tet.combo) end
        if cfg.fin == 1 and m ~= 5 and tet.fp > 0 then
            r[#r + 1] = stat("FINESSE", string.format("%d  (%d%%)", tet.ff, math.floor((tet.fp - tet.fbad) / tet.fp * 100 + 0.5)))
        end
        if m == 5 then r = {r[1], r[2], stat("STREAK", tet.streak), stat("ACC", tet.try > 0 and math.floor(tet.ok / tet.try * 100 + 0.5) .. "%" or "-"),
            stat("DRILL", PRACN[cfg.prac] .. (cfg.prac == 3 and " L" .. cfg.plv or ""))} end
        stats.Text = table.concat(r, "\n")
    end
    if tet.state ~= "over" then
        overTxt = nil
    elseif not overTxt then -- once per finished run: records + result text
        local timed, bk = tet.mode == 2 or tet.mode == 4, "m" .. tet.mode
        local v = timed and tet.won and tet.time or (not timed and tet.score) or nil
        if tet.mode > 4 then v = nil end -- Practice and Zen keep no records
        local isBest = v and v > 0 and (not best[bk] or (timed and v < best[bk] or not timed and v > best[bk]))
        if isBest then best[bk] = v; save() end
        if v and v > 0 and tet.mode <= 4 then addScore(tet.mode, v, timed) end
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
