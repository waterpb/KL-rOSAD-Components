--// NO SIT (LocalScript) - ignores seats on your client. Re-run after changing the toggle.
local BLOCK_SEATS = true   -- true = seats can't seat you, false = back to normal

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

-- clean up the previous run (restores seats + sit ability)
if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup) end

local touched, conns = {}, {}   -- seats we switched off, connections to disconnect

local function isSeat(o) return o:IsA("Seat") or o:IsA("VehicleSeat") end
local function disable(seat)
	if not seat.Disabled then seat.Disabled = true; touched[seat] = true end
end

local function stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	for seat in pairs(touched) do if seat.Parent then seat.Disabled = false end end
	touched = {}
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end
end
_G.__NoSitCleanup = stop

if not BLOCK_SEATS then print("[NoSit] off") return end

-- every seat in the game, now and when new ones appear
for _, o in ipairs(workspace:GetDescendants()) do if isSeat(o) then disable(o) end end
table.insert(conns, workspace.DescendantAdded:Connect(function(o) if isSeat(o) then disable(o) end end))

-- belt and braces: the Seated state is off, and if the server seats you anyway you hop straight off
table.insert(conns, RunService.Heartbeat:Connect(function()
	local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	if hum.SeatPart or hum.Sit then
		hum.Sit = false
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))
print("[NoSit] on - seats are ignored")
