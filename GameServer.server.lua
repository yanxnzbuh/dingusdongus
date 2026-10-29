-- Sky Coin Rush | GameServer
-- Authoritative round loop, coin spawning, currency, upgrades, leaderstats.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("SkyCoinRemotes")
local collectRemote = remotes:WaitForChild("CoinCollected")
local stateRemote = remotes:WaitForChild("GameState")
local buyRemote = remotes:WaitForChild("BuyUpgrade")

local coinTemplate = ReplicatedStorage:WaitForChild("CoinTemplate")

local CONFIG = {
	ROUND_TIME = 60,
	INTERMISSION = 8,
	COINS_PER_ROUND = 40,
	COIN_VALUE = 1,
	WIN_BONUS = 25,
	UPGRADES = {
		Speed = { label = "Speed", baseCost = 50, max = 5, step = 8, start = 16, perLevel = 4 },
		Jump = { label = "Jump", baseCost = 60, max = 5, step = 10, start = 50, perLevel = 10 },
		Trail = { label = "Trail", baseCost = 100, max = 3, step = 75 },
	},
}

-- ============ DATA ============
local playerData = {} -- [player] = { coins, wins, upgrades, roundScore }

local function loadData(plr)
	local d = playerData[plr]
	if d then return d end
	d = { coins = 0, wins = 0, roundScore = 0, upgrades = { Speed = 0, Jump = 0, Trail = 0 } }
	playerData[plr] = d
	return d
end

local function makeLeaderstats(plr)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = plr

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = ls

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = ls
end

local function applyStats(plr)
	local d = playerData[plr]
	if not d then return end
	local char = plr.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local speedCfg = CONFIG.UPGRADES.Speed
	local jumpCfg = CONFIG.UPGRADES.Jump
	humanoid.WalkSpeed = speedCfg.start + d.upgrades.Speed * speedCfg.perLevel
	humanoid.JumpPower = jumpCfg.start + d.upgrades.Jump * jumpCfg.perLevel
	humanoid:SetAttribute("AllowedSpeed", humanoid.WalkSpeed)
	humanoid:SetAttribute("AllowedJump", humanoid.JumpPower)
end

Players.PlayerAdded:Connect(function(plr)
	loadData(plr)
	makeLeaderstats(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		applyStats(plr)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	playerData[plr] = nil
end)

-- ============ COINS ============
local activeCoins = {} -- [coinPart] = { position, collected = {[userId]=true} }
local coinFolder

local function clearCoins()
	if coinFolder then coinFolder:Destroy() coinFolder = nil end
	table.clear(activeCoins)
end

local function spawnCoins(count)
	clearCoins()
	coinFolder = Instance.new("Folder")
	coinFolder.Name = "Coins"
	coinFolder.Parent = workspace

	local islandList = {}
	for _, p in ipairs(workspace.SkyCoinRushMap:GetChildren()) do
		if p.Name:match("^Island%d+$") then
			table.insert(islandList, p)
		end
	end
	if #islandList == 0 then return end

	for i = 1, count do
		local isl = islandList[(i % #islandList) + 1]
		local coin = coinTemplate:Clone()
		local offset = Vector3.new(
			(math.random() - 0.5) * isl.Size.X * 0.7,
			2.5,
			(math.random() - 0.5) * isl.Size.Z * 0.7
		)
		coin.Position = isl.Position + offset
		coin.Parent = coinFolder
		activeCoins[coin] = { position = coin.Position, collected = {} }

		local att = Instance.new("Attachment")
		att.Parent = coin
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxassetid://241629073"
		particles.Rate = 6
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Speed = NumberRange.new(0.5)
		particles.Size = NumberSequence.new(0.25)
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80))
		particles.Parent = att
	end
end

local function coinTouched(coin, plr)
	local data = activeCoins[coin]
	local d = playerData[plr]
	if not data or not d then return end
	if data.collected[plr.UserId] then return end

	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (root.Position - coin.Position).Magnitude > 12 then return end

	data.collected[plr.UserId] = true
	d.coins += CONFIG.COIN_VALUE
	d.roundScore += CONFIG.COIN_VALUE
	plr.leaderstats.Coins.Value = d.coins
	activeCoins[coin] = nil
	coin:Destroy()
end

local function hookCoinTouch()
	coinFolder.ChildAdded:Connect(function(coin)
		coin.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then
				coinTouched(coin, plr)
			end
		end)
	end)
end

collectRemote.OnServerEvent:Connect(function(plr, coin)
	if typeof(coin) ~= "Instance" then return end
	if coin.Parent == coinFolder then
		coinTouched(coin, plr)
	end
end)

-- ============ UPGRADES ============
buyRemote.OnServerEvent:Connect(function(plr, upgradeName)
	local cfg = CONFIG.UPGRADES[upgradeName]
	local d = playerData[plr]
	if not cfg or not d then return end

	local level = d.upgrades[upgradeName]
	if level >= cfg.max then return end

	local cost = cfg.baseCost + level * cfg.step
	if d.coins < cost then return end

	d.coins -= cost
	d.upgrades[upgradeName] = level + 1
	plr.leaderstats.Coins.Value = d.coins

	if upgradeName == "Trail" then
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 1, 0); a0.Parent = root
			local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -1, 0); a1.Parent = root
			local trail = Instance.new("Trail")
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.5
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60))
			trail.Parent = root
		end
	else
		applyStats(plr)
	end
end)

-- ============ ROUND LOOP ============
local function teleportToIsland(plr)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	for _, p in ipairs(workspace.SkyCoinRushMap:GetChildren()) do
		if p.Name:match("^Island%d+$") then
			root.CFrame = CFrame.new(p.Position + Vector3.new(0, p.Size.Y / 2 + 3, 0))
			return
		end
	end
end

task.spawn(function()
	while true do
		stateRemote:FireAllClients({ phase = "intermission", time = CONFIG.INTERMISSION })
		task.wait(CONFIG.INTERMISSION)

		for plr, d in pairs(playerData) do
			d.roundScore = 0
			teleportToIsland(plr)
		end
		spawnCoins(CONFIG.COINS_PER_ROUND)
		hookCoinTouch()

		stateRemote:FireAllClients({ phase = "round", time = CONFIG.ROUND_TIME })
		for t = CONFIG.ROUND_TIME, 1, -1 do
			stateRemote:FireAllClients({ phase = "round", timeLeft = t })
			task.wait(1)
		end

		-- Results & winner bonus
		local best, bestScore = nil, -1
		for plr, d in pairs(playerData) do
			if plr.Parent and d.roundScore > bestScore then
				best, bestScore = plr, d.roundScore
			end
		end

		clearCoins()
		stateRemote:FireAllClients({ phase = "results", winner = best and best.Name or nil, score = bestScore })

		if best and bestScore > 0 then
			local d = playerData[best]
			d.coins += CONFIG.WIN_BONUS
			d.wins += 1
			best.leaderstats.Coins.Value = d.coins
			best.leaderstats.Wins.Value = d.wins
		end
		task.wait(4)
	end
end)

print("[SkyCoinRush] GameServer running.")
