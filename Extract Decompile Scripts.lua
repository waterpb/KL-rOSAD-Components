-- Decompiles every script the executor can see and writes decompiled_scripts.zip to the executor workspace folder.
-- Needs executor globals: getscripts, decompile, writefile.

local OUT = "decompiled_scripts.zip"

print("DecompileToZip: started")
for _, g in ipairs({ "getscripts", "decompile", "writefile" }) do
	if not getgenv()[g] then
		return warn("Your executor is missing: " .. g)
	end
end

local function le(n, bytes)
	local t = {}
	for i = 1, bytes do
		t[i] = string.char(bit32.band(bit32.rshift(n, 8 * (i - 1)), 255))
	end
	return table.concat(t)
end

local crcT = {}
for i = 0, 255 do
	local c = i
	for _ = 1, 8 do
		c = bit32.band(c, 1) == 1 and bit32.bxor(0xEDB88320, bit32.rshift(c, 1)) or bit32.rshift(c, 1)
	end
	crcT[i] = c
end

local function crc32(s)
	local c = 0xFFFFFFFF
	for i = 1, #s do
		c = bit32.bxor(crcT[bit32.band(bit32.bxor(c, s:byte(i)), 255)], bit32.rshift(c, 8))
	end
	return bit32.bxor(c, 0xFFFFFFFF)
end

local files, seen = {}, {}
local scripts = getscripts()
local failed = 0
print(("Found %d scripts, decompiling..."):format(#scripts))

for i, s in ipairs(scripts) do
	local ok, src = pcall(decompile, s)
	if not (ok and type(src) == "string") then
		failed += 1
		warn(("Failed: %s (%s)"):format(s:GetFullName(), tostring(src)))
	else
		local name = (s:GetFullName():gsub("[^%w%._ %-]", "_")):gsub("%.", "/")
		seen[name] = (seen[name] or 0) + 1
		if seen[name] > 1 then name ..= "_" .. seen[name] end
		table.insert(files, { name = name .. ".lua", data = src })
	end
	if i % 5 == 0 then
		print(("Progress: %d/%d (%d failed)"):format(i, #scripts, failed))
		task.wait() -- keep the client from freezing
	end
end

-- shortcut: "stored" zip (no compression) with no zip64, so max 65535 files / 4 GB; upgrade if you hit that
local body, central, offset = {}, {}, 0
for _, f in ipairs(files) do
	local crc, size, nlen = crc32(f.data), #f.data, #f.name
	local local_hdr = "PK\3\4" .. le(20, 2) .. le(0x0800, 2) .. le(0, 2) .. le(0, 2) .. le(0x21, 2)
		.. le(crc, 4) .. le(size, 4) .. le(size, 4) .. le(nlen, 2) .. le(0, 2) .. f.name
	table.insert(body, local_hdr .. f.data)
	table.insert(central, "PK\1\2" .. le(20, 2) .. le(20, 2) .. le(0x0800, 2) .. le(0, 2) .. le(0, 2) .. le(0x21, 2)
		.. le(crc, 4) .. le(size, 4) .. le(size, 4) .. le(nlen, 2) .. le(0, 2) .. le(0, 2)
		.. le(0, 2) .. le(0, 2) .. le(0, 4) .. le(offset, 4) .. f.name)
	offset += #local_hdr + size
end

local cd = table.concat(central)
local zip = table.concat(body) .. cd
	.. "PK\5\6" .. le(0, 2) .. le(0, 2) .. le(#files, 2) .. le(#files, 2) .. le(#cd, 4) .. le(offset, 4) .. le(0, 2)

local ok, err = pcall(writefile, OUT, zip)
if not ok then
	-- many executors only allow certain extensions (.txt, .json, .lua); rename to .zip by hand afterwards
	warn("writefile rejected " .. OUT .. " (" .. tostring(err) .. "), retrying as .txt")
	OUT = "decompiled_scripts.txt"
	ok, err = pcall(writefile, OUT, zip)
	if not ok then
		return warn("writefile failed: " .. tostring(err))
	end
	print("Saved as .txt: rename it to decompiled_scripts.zip to open it")
end
print(("Done: %d saved, %d failed, %s is %d bytes, exists on disk: %s"):format(
	#files, failed, OUT, #zip, tostring(isfile and isfile(OUT))))
