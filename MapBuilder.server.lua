-- Sky Coin Rush | MapBuilder
-- Procedurally builds the floating-island map. Runs once on server start.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mapModel = Instance.new("Model")
mapModel.Name = "SkyCoinRushMap"

-- ============ SPAWN LOBBY ============
local function makePart(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent or mapModel
	return p
end

local lobby = makePart({
	Name = "Lobby",
	Size = Vector3.new(40, 2, 40),
	Position = Vector3.new(0, 50, 0),
	Color = Color3.fromRGB(120, 200, 255),
	Material = Enum.Material.SmoothPlastic,
})

makePart({
	Name = "LobbyRim",
	Size = Vector3.new(44, 1, 44),
	Position = Vector3.new(0, 49, 0),
	Color = Color3.fromRGB(255, 220, 100),
	Material = Enum.Material.Neon,
	Transparency = 0.4,
})

local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Size = Vector3.new(12, 1, 12)
spawnLoc.Position = Vector3.new(0, 51.5, 0)
spawnLoc.Anchored = true
spawnLoc.Neutral = true
spawnLoc.Color = Color3.fromRGB(200, 230, 255)
spawnLoc.Material = Enum.Material.SmoothPlastic
spawnLoc.TopSurface = Enum.SurfaceType.Smooth
spawnLoc.Parent = mapModel

-- ============ ISLANDS ============
local seed = 1337
local function rand()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local ISLAND_COUNT = 14
local islands = {}

local palette = {
	Color3.fromRGB(106, 170, 80),
	Color3.fromRGB(140, 200, 120),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(200, 120, 255),
}

for i = 1, ISLAND_COUNT do
	local angle = (i / ISLAND_COUNT) * math.pi * 2
	local radius = 55 + rand() * 35
	local height = 55 + rand() * 30 + (i % 3) * 6
	local pos = Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
	local size = Vector3.new(14 + rand() * 10, 3, 14 + rand() * 10)
	local col = palette[(i % #palette) + 1]

	local island = makePart({
		Name = "Island" .. i,
		Size = size,
		Position = pos,
		Color = col,
		Material = Enum.Material.Grass,
	})

	makePart({
		Name = "IslandCrystal" .. i,
		Size = Vector3.new(size.X * 0.35, size.Y * 2.2, size.Z * 0.35),
		Position = pos - Vector3.new(0, size.Y * 1.2, 0),
		Color = Color3.fromRGB(170, 120, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.25,
	})

	local trunk = makePart({
		Name = "Trunk" .. i,
		Size = Vector3.new(1.2, 5, 1.2),
		Position = pos + Vector3.new(size.X * 0.25, size.Y / 2 + 2.5, -size.Z * 0.2),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
	})
	local leaves = Instance.new("Part")
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(6, 6, 6)
	leaves.Position = trunk.Position + Vector3.new(0, 4, 0)
	leaves.Color = Color3.fromRGB(60, 150, 60)
	leaves.Material = Enum.Material.Grass
	leaves.Anchored = true
	leaves.Parent = mapModel

	islands[i] = { position = pos, size = size, index = i }
end

-- ============ BRIDGES ============
local plankFolder = Instance.new("Folder")
plankFolder.Name = "Planks"
plankFolder.Parent = mapModel

for i = 1, ISLAND_COUNT do
	local a = islands[i]
	local b = islands[(i % ISLAND_COUNT) + 1]
	local mid = (a.position + b.position) / 2
	local dist = (b.position - a.position).Magnitude
	makePart({
		Name = "Plank" .. i,
		Size = Vector3.new(4, 0.6, math.max(dist - 12, 4)),
		CFrame = CFrame.lookAt(mid, b.position),
		Color = Color3.fromRGB(180, 130, 90),
		Material = Enum.Material.WoodPlanks,
	}, plankFolder)

	if i % 3 == 0 then
		local pad = makePart({
			Name = "JumpPad" .. i,
			Size = Vector3.new(5, 0.5, 5),
			Position = a.position + Vector3.new(0, a.size.Y / 2 + 0.3, 0),
			Color = Color3.fromRGB(255, 80, 120),
			Material = Enum.Material.Neon,
		})
		pad:SetAttribute("JumpPad", true)
	end
end

-- ============ FALL ZONE ============
local killZone = makePart({
	Name = "KillZone",
	Size = Vector3.new(600, 5, 600),
	Position = Vector3.new(0, -40, 0),
	Color = Color3.fromRGB(30, 60, 120),
	Material = Enum.Material.SmoothPlastic,
	Transparency = 0.35,
})
killZone:SetAttribute("KillZone", true)

local cloudFolder = Instance.new("Folder")
cloudFolder.Name = "Clouds"
cloudFolder.Parent = mapModel
for i = 1, 20 do
	local c = Instance.new("Part")
	c.Shape = Enum.PartType.Ball
	c.Size = Vector3.new(20 + rand() * 30, 8, 20 + rand() * 30)
	c.Position = Vector3.new((rand() - 0.5) * 400, 20 + rand() * 60, (rand() - 0.5) * 400)
	c.Color = Color3.fromRGB(255, 255, 255)
	c.Material = Enum.Material.SmoothPlastic
	c.Transparency = 0.2
	c.Anchored = true
	c.CanCollide = false
	c.Parent = cloudFolder
end

-- ============ COIN TEMPLATE ============
local coinTemplate = Instance.new("Part")
coinTemplate.Name = "CoinTemplate"
coinTemplate.Shape = Enum.PartType.Cylinder
coinTemplate.Size = Vector3.new(0.4, 3.2, 3.2)
coinTemplate.Color = Color3.fromRGB(255, 200, 40)
coinTemplate.Material = Enum.Material.Neon
coinTemplate.CanCollide = false
coinTemplate.Anchored = true
coinTemplate.Parent = ReplicatedStorage

local marker = Instance.new("BoolValue")
marker.Name = "IsCoin"
marker.Parent = coinTemplate

-- ============ REMOTES ============
local remotes = Instance.new("Folder")
remotes.Name = "SkyCoinRemotes"
remotes.Parent = ReplicatedStorage

local collectRemote = Instance.new("RemoteEvent")
collectRemote.Name = "CoinCollected"
collectRemote.Parent = remotes

local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "GameState"
stateRemote.Parent = remotes

local buyRemote = Instance.new("RemoteEvent")
buyRemote.Name = "BuyUpgrade"
buyRemote.Parent = remotes

mapModel.Parent = workspace
print("[SkyCoinRush] Map built: " .. ISLAND_COUNT .. " islands ready.")
