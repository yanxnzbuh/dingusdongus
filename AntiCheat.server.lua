-- Sky Coin Rush | AntiCheat
-- Server-side movement validation: teleport detection, sustained speed hacks,
-- and reversion of client-tampered WalkSpeed/JumpPower.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BASE_SPEED = 16
local BASE_JUMP = 50
local MAX_SPEED_LEVEL = 5
local SPEED_PER_LEVEL = 4
local JUMP_PER_LEVEL = 10

local TELEPORT_DIST = 60      -- studs per heartbeat jump = instant teleport
local MAX_RUN_SPEED = BASE_SPEED + MAX_SPEED_LEVEL * SPEED_PER_LEVEL + 12 -- headroom
local VIOLATION_KICK = 25

local lastPos = {}          -- [player] = Vector3
local violationCount = {}   -- [player] = number
local grounds = {}          -- [player] = boolean (was grounded last frame)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart")
		local humanoid = char:WaitForChild("Humanoid")
		lastPos[plr] = root.Position
		violationCount[plr] = 0
		grounds[plr] = true

		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not root.Parent then
				conn:Disconnect()
				return
			end

			local allowedSpeed = humanoid:GetAttribute("AllowedSpeed") or BASE_SPEED
			local allowedJump = humanoid:GetAttribute("AllowedJump") or BASE_JUMP

			-- Revert client tampering of stats the server owns
			if math.abs(humanoid.WalkSpeed - allowedSpeed) > 0.5 then
				humanoid.WalkSpeed = allowedSpeed
			end
			if math.abs(humanoid.JumpPower - allowedJump) > 0.5 then
				humanoid.JumpPower = allowedJump
			end

			local prev = lastPos[plr]
			local pos = root.Position
			local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
			local delta = prev and (pos - prev).Magnitude or 0

			-- Teleport hack: huge position delta regardless of physics
			if delta > TELEPORT_DIST then
				violationCount[plr] += 1
				if prev then
					root.CFrame = CFrame.new(prev + Vector3.new(0, 5, 0))
				end
			-- Speed hack: sustained horizontal speed above the hardest legit build
			elseif grounded and delta / dt > MAX_RUN_SPEED then
				violationCount[plr] += 1
				root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			end

			if violationCount[plr] > VIOLATION_KICK then
				plr:Kick("Suspicious movement detected.")
			end

			lastPos[plr] = pos
			grounds[plr] = grounded
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	lastPos[plr] = nil
	violationCount[plr] = nil
	grounds[plr] = nil
end)

print("[SkyCoinRush] AntiCheat active.")
