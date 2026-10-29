-- Sky Coin Rush | ClientFX (LocalScript)
-- HUD: round timer, coin counter animation, upgrade shop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("SkyCoinRemotes")
local stateRemote = remotes:WaitForChild("GameState")
local buyRemote = remotes:WaitForChild("BuyUpgrade")
local collectRemote = remotes:WaitForChild("CoinCollected")

local UPGRADES = {
	Speed = { baseCost = 50, max = 5, step = 8 },
	Jump = { baseCost = 60, max = 5, step = 10 },
	Trail = { baseCost = 100, max = 3, step = 75 },
}

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "SkyCoinHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 220, 0, 50)
timerLabel.Position = UDim2.new(0.5, -110, 0, 10)
timerLabel.BackgroundTransparency = 0.3
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
timerLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 28
timerLabel.Text = "Starting..."
timerLabel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = timerLabel

local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0, 160, 0, 44)
shopBtn.Position = UDim2.new(1, -175, 1, -60)
shopBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
shopBtn.TextColor3 = Color3.fromRGB(40, 30, 10)
shopBtn.Font = Enum.Font.GothamBold
shopBtn.TextSize = 20
shopBtn.Text = "UPGRADES"
shopBtn.Parent = gui
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, 10); c2.Parent = shopBtn

local shopPanel = Instance.new("Frame")
shopPanel.Size = UDim2.new(0, 300, 0, 260)
shopPanel.Position = UDim2.new(1, -320, 1, -330)
shopPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
shopPanel.BackgroundTransparency = 0.05
shopPanel.Visible = false
shopPanel.Parent = gui
local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0, 14); c3.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 36)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "UPGRADE SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 80)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 22
shopTitle.Parent = shopPanel

local yOffset = 40
for name, cfg in pairs(UPGRADES) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 50)
	btn.Position = UDim2.new(0, 10, 0, yOffset)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 110)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 16
	btn.Name = "Buy_" .. name
	btn.Parent = shopPanel
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = btn

	btn.MouseButton1Click:Connect(function()
		buyRemote:FireServer(name)
	end)
	yOffset += 60
end

local function updateShop()
	local coins = player:FindFirstChild("leaderstats")
	coins = coins and coins:FindFirstChild("Coins")
	local c = coins and coins.Value or 0
	for name, cfg in pairs(UPGRADES) do
		local btn = shopPanel:FindFirstChild("Buy_" .. name)
		if btn then
			btn.Text = string.format("%s (Lv ?) - %d coins", name, cfg.baseCost)
			btn.AutoButtonColor = c >= cfg.baseCost
		end
	end
end

shopBtn.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	updateShop()
end)

task.spawn(function()
	local ls = player:WaitForChild("leaderstats")
	local coins = ls:WaitForChild("Coins")
	coins.Changed:Connect(function()
		if shopPanel.Visible then updateShop() end
		local pop = Instance.new("TextLabel")
		pop.Size = UDim2.new(0, 100, 0, 30)
		pop.Position = UDim2.new(0.5, -50, 0, 60)
		pop.BackgroundTransparency = 1
		pop.Text = "+1 coin"
		pop.TextColor3 = Color3.fromRGB(255, 210, 60)
		pop.Font = Enum.Font.GothamBold
		pop.TextSize = 22
		pop.Parent = gui
		local tween = TweenService:Create(pop, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = pop.Position - UDim2.new(0, 0, 0, 40),
			TextTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function() pop:Destroy() end)
	end)
end)

-- ============ ROUND STATE ============
stateRemote.OnClientEvent:Connect(function(state)
	if state.phase == "intermission" then
		timerLabel.Text = "Next round in " .. tostring(state.time or 8) .. "s..."
		timerLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	elseif state.phase == "round" and state.timeLeft then
		timerLabel.Text = tostring(state.timeLeft)
		timerLabel.TextColor3 = state.timeLeft <= 10 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 80)
	elseif state.phase == "results" then
		if state.winner then
			timerLabel.Text = state.winner .. " wins! +" .. tostring(state.score or 0)
		else
			timerLabel.Text = "Round over!"
		end
	end
end)

-- ============ COIN COLLECTION (client ping, server validates) ============
local function hookCharacter(char)
	local root = char:WaitForChild("HumanoidRootPart")
	root.Touched:Connect(function(hit)
		if hit.Name == "CoinTemplate" and hit.Parent and hit.Parent.Name == "Coins" then
			collectRemote:FireServer(hit)
		end
	end)
end

if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)
