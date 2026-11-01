local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local FREEZE_SELF = true   -- true = you freeze too (clean snapshot)
local AUTO_RESUME = true   -- unfreeze after the save finishes
local FILE_NAME   = "Blink_" .. game.PlaceId .. "_" .. os.time()

local OPTS = {
	FileName = FILE_NAME,
	Decompile = true,
	DecompileTimeout = 30,
	NoScripts = false,
	SaveBytecode = false,
	RemovePlayerCharacters = false,
}

local env = getgenv()
if env.__BlinkResume then      -- already frozen -> re-execute resumes
	env.__BlinkResume()
	return
end

local S = { parts = {}, hums = {}, tracks = {}, sounds = {}, emit = {} }
local conns = {}

local function freezeInst(d)
	local ch = LP.Character
	if not FREEZE_SELF and ch and d:IsDescendantOf(ch) then return end
	if d:IsA("BasePart") and not d:IsA("Terrain") then
		if S.parts[d] then return end
		S.parts[d] = { d.Anchored, d.AssemblyLinearVelocity, d.AssemblyAngularVelocity }
		d.AssemblyLinearVelocity = Vector3.zero
		d.AssemblyAngularVelocity = Vector3.zero
		d.Anchored = true
	elseif d:IsA("Humanoid") then
		if S.hums[d] then return end
		S.hums[d] = { d.WalkSpeed, d.JumpPower, d.JumpHeight, d.AutoRotate }
		d.WalkSpeed, d.JumpPower, d.JumpHeight, d.AutoRotate = 0, 0, 0, false
	elseif d:IsA("Animator") then
		for _, t in ipairs(d:GetPlayingAnimationTracks()) do
			if S.tracks[t] == nil then S.tracks[t] = t.Speed; t:AdjustSpeed(0) end
		end
		table.insert(conns, d.AnimationPlayed:Connect(function(t)
			if S.tracks[t] == nil then S.tracks[t] = t.Speed; t:AdjustSpeed(0) end
		end))
	elseif d:IsA("Sound") then
		if d.IsPlaying and not S.sounds[d] then S.sounds[d] = true; d:Pause() end
	elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
		if S.emit[d] == nil then S.emit[d] = d.Enabled; d.Enabled = false end
	end
end

local function resume()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	for d, v in pairs(S.parts)  do pcall(function() d.Anchored = v[1]; d.AssemblyLinearVelocity = v[2]; d.AssemblyAngularVelocity = v[3] end) end
	for d, v in pairs(S.hums)   do pcall(function() d.WalkSpeed, d.JumpPower, d.JumpHeight, d.AutoRotate = v[1], v[2], v[3], v[4] end) end
	for t, v in pairs(S.tracks) do pcall(function() t:AdjustSpeed(v) end) end
	for d in pairs(S.sounds)    do pcall(function() d:Resume() end) end
	for d, v in pairs(S.emit)   do pcall(function() d.Enabled = v end) end
	env.__BlinkResume = nil
end
env.__BlinkResume = resume

-- freeze
for _, d in ipairs(workspace:GetDescendants()) do pcall(freezeInst, d) end
table.insert(conns, workspace.DescendantAdded:Connect(function(d)
	task.defer(pcall, freezeInst, d)
end))

-- let the frozen state settle, then save
task.wait(0.2)

local attempts = {
	{ "bare",      function() return saveinstance() end },
	{ "min opts",  function() return saveinstance({ FileName = FILE_NAME }) end },
	{ "full opts", function() return saveinstance(OPTS) end },
}

local saved = false
for _, a in ipairs(attempts) do
	local ok, err = pcall(a[2])
	warn(("[Blink] %s: %s"):format(a[1], ok and "ok" or tostring(err)))
	if ok then saved = true break end
end
warn(saved and "[Blink] saved" or "[Blink] all save attempts failed")

if AUTO_RESUME then resume() end
