-- Builds a simple starter world (hub island + 3 fishing islands) when the place
-- has no folder called "Map" in Workspace. That means the game is playable the
-- moment you press Play. To use your own scenery later, see docs/SETUP_GUIDE.md:
-- the game only cares about parts with these attributes:
--   FishingZone = "shallows"   invisible flat part on the water surface
--   ZoneGate    = "mangroves"  wall that blocks a locked zone
--   ZoneSpawn   = "frostbite"  where the teleporter drops players
--   Station     = "Sell" / "Rods" / "Leaderboard" / "EventBoard"
--   VipDoor     = true         door only VIP players can walk through

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Zones = require(Shared.Zones)
local Format = require(Shared.Format)

local MapBuilder = {}

local GROUND_Y = 3

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "Parent" then
			p[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function sign(parentPart, text, face, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parentPart
	return label
end

local function prompt(parentPart, action, object, distance)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object or ""
	p.MaxActivationDistance = distance or 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0
	p.Parent = parentPart
	return p
end

local function island(folder, name, center, size, topColor, topMaterial)
	part({
		Name = name .. "Beach",
		Size = Vector3.new(size.X + 16, 6, size.Z + 16),
		Position = Vector3.new(center.X, GROUND_Y - 4, center.Z),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(235, 215, 160),
		Parent = folder,
	})
	part({
		Name = name .. "Ground",
		Size = Vector3.new(size.X, 1, size.Z),
		Position = Vector3.new(center.X, GROUND_Y - 0.5, center.Z),
		Material = topMaterial or Enum.Material.Grass,
		Color = topColor,
		Parent = folder,
	})
end

local function tree(folder, position, leafColor, random)
	local height = random:NextNumber(10, 16)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Color3.fromRGB(110, 80, 50),
		Parent = folder,
	})
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * random:NextNumber(8, 12),
		Position = position + Vector3.new(0, height + 2, 0),
		Material = Enum.Material.Grass,
		Color = leafColor,
		CanCollide = false,
		Parent = folder,
	})
end

local function stall(folder, name, position, color, title)
	local model = Instance.new("Model")
	model.Name = name
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(14, 4, 4),
		Position = position + Vector3.new(0, 2, 0),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(160, 110, 70),
		Parent = model,
	})
	for _, x in ipairs({ -6.5, 6.5 }) do
		part({
			Name = "Post",
			Size = Vector3.new(1, 10, 1),
			Position = position + Vector3.new(x, 5, -3),
			Material = Enum.Material.Wood,
			Color = Color3.fromRGB(110, 80, 50),
			Parent = model,
		})
	end
	part({
		Name = "Roof",
		Size = Vector3.new(16, 1, 8),
		Position = position + Vector3.new(0, 10.5, -1.5),
		Material = Enum.Material.Fabric,
		Color = color,
		Parent = model,
	})
	local board = part({
		Name = "Sign",
		Size = Vector3.new(12, 3, 0.5),
		Position = position + Vector3.new(0, 12.5, 2),
		Color = Color3.fromRGB(60, 40, 30),
		Parent = model,
	})
	sign(board, title, Enum.NormalId.Front)
	sign(board, title, Enum.NormalId.Back)
	model.Parent = folder
	return counter
end

local function board(folder, name, cframe, size, station)
	local p = part({
		Name = name,
		Size = size,
		CFrame = cframe,
		Color = Color3.fromRGB(30, 40, 60),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	p:SetAttribute("Station", station)
	return p
end

function MapBuilder.Build()
	if Workspace:FindFirstChild("Map") then
		return -- the creator made their own map
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = map
	local fishing = Instance.new("Folder")
	fishing.Name = "FishingZones"
	fishing.Parent = map

	local random = Random.new(42)

	-- Ocean
	local terrain = Workspace.Terrain
	terrain:FillBlock(CFrame.new(350, -22, 0), Vector3.new(1300, 8, 700), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(350, -9, 0), Vector3.new(1300, 18, 700), Enum.Material.Water)
	terrain.WaterColor = Color3.fromRGB(40, 150, 200)
	terrain.WaterTransparency = 0.6
	terrain.WaterWaveSize = 0.15

	-- Hub island
	island(scenery, "Hub", Vector3.new(0, 0, 0), Vector3.new(140, 0, 140), Color3.fromRGB(110, 190, 90))
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "HubSpawn"
	spawnLocation.Anchored = true
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.Position = Vector3.new(0, GROUND_Y + 0.5, 30)
	spawnLocation.Material = Enum.Material.Wood
	spawnLocation.Color = Color3.fromRGB(190, 150, 100)
	spawnLocation.Duration = 0
	spawnLocation.Parent = map

	local hubSpawn = part({ Name = "HubTeleport", Size = Vector3.new(4, 1, 4), Position = Vector3.new(0, GROUND_Y + 0.5, 20), Transparency = 1, CanCollide = false, Parent = map })
	hubSpawn:SetAttribute("ZoneSpawn", "hub")

	local sellCounter = stall(scenery, "FishMarket", Vector3.new(-35, GROUND_Y, -25), Color3.fromRGB(60, 140, 220), "FISH MARKET")
	sellCounter:SetAttribute("Station", "Sell")
	prompt(sellCounter, "Sell all fish", "Fish Market")

	local rodCounter = stall(scenery, "RodShop", Vector3.new(35, GROUND_Y, -25), Color3.fromRGB(220, 120, 50), "ROD SHOP")
	rodCounter:SetAttribute("Station", "Rods")
	prompt(rodCounter, "Browse rods", "Rod Shop")

	board(map, "GlobalBoard", CFrame.new(0, GROUND_Y + 10, -60), Vector3.new(28, 18, 1), "Leaderboard")
	board(map, "EventBoard", CFrame.new(-55, GROUND_Y + 7, 25) * CFrame.Angles(0, math.rad(90), 0), Vector3.new(20, 12, 1), "EventBoard")

	-- VIP dock (cosmetic perk: a nice private spot by the hub)
	part({ Name = "VipDock", Size = Vector3.new(20, 1, 44), Position = Vector3.new(0, GROUND_Y - 0.5, 98), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(200, 160, 60), Parent = scenery })
	local vipDoor = part({ Name = "VipDoor", Size = Vector3.new(20, 12, 1), Position = Vector3.new(0, GROUND_Y + 6, 76.5), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, Transparency = 0.5, Parent = map })
	vipDoor:SetAttribute("VipDoor", true)
	sign(vipDoor, "VIP DOCK", Enum.NormalId.Front, Color3.fromRGB(255, 240, 180))
	sign(vipDoor, "VIP DOCK", Enum.NormalId.Back, Color3.fromRGB(255, 240, 180))
	local vipWater = part({ Name = "VipWater", Size = Vector3.new(80, 1, 70), Position = Vector3.new(0, 0.5, 112), Transparency = 1, CanCollide = false, CanTouch = false, Parent = fishing })
	vipWater:SetAttribute("FishingZone", "shallows")

	for _ = 1, 14 do
		local x = random:NextNumber(-64, 64)
		local z = random:NextNumber(-64, 64)
		if (math.abs(x) > 52 or math.abs(z) > 52) and math.abs(z - 0) > 8 and math.abs(x) > 12 then
			tree(scenery, Vector3.new(x, GROUND_Y, z), Color3.fromRGB(60, 160, 60), random)
		end
	end

	-- Fishing islands, one per zone, in a row going east
	local looks = {
		shallows = { ground = Color3.fromRGB(240, 220, 150), material = Enum.Material.Sand, leaves = Color3.fromRGB(90, 190, 70) },
		mangroves = { ground = Color3.fromRGB(70, 110, 60), material = Enum.Material.Grass, leaves = Color3.fromRGB(40, 90, 40) },
		frostbite = { ground = Color3.fromRGB(240, 250, 255), material = Enum.Material.Snow, leaves = Color3.fromRGB(220, 240, 255) },
	}
	local previousEdge = 78
	for index, zone in ipairs(Zones.List) do
		local centerX = 230 * index
		local look = looks[zone.id] or looks.shallows
		island(scenery, zone.name, Vector3.new(centerX, 0, 0), Vector3.new(90, 0, 90), look.ground, look.material)

		for _ = 1, 6 do
			local x = centerX + random:NextNumber(-38, 38)
			local z = random:NextNumber(-38, 38)
			if math.abs(z) > 12 then
				tree(scenery, Vector3.new(x, GROUND_Y, z), look.leaves, random)
			end
		end

		local zoneSign = part({ Name = "ZoneSign", Size = Vector3.new(24, 6, 1), Position = Vector3.new(centerX, GROUND_Y + 14, -40), Color = Color3.fromRGB(30, 40, 60), Parent = scenery })
		sign(zoneSign, zone.name, Enum.NormalId.Front, zone.color)
		sign(zoneSign, zone.name, Enum.NormalId.Back, zone.color)

		-- Bridge from the previous island
		local islandEdge = centerX - 53
		local bridgeLength = islandEdge - previousEdge
		part({
			Name = "Bridge",
			Size = Vector3.new(bridgeLength, 1, 10),
			Position = Vector3.new(previousEdge + bridgeLength / 2, GROUND_Y - 0.5, 0),
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromRGB(150, 110, 70),
			Parent = scenery,
		})
		previousEdge = centerX + 53

		if zone.price > 0 then
			local gate = part({
				Name = zone.name .. "Gate",
				Size = Vector3.new(2, 14, 12),
				Position = Vector3.new(islandEdge - bridgeLength + 6, GROUND_Y + 7, 0),
				Color = zone.color,
				Material = Enum.Material.ForceField,
				Parent = map,
			})
			gate:SetAttribute("ZoneGate", zone.id)
			local text = zone.name .. "\n" .. Format.Number(zone.price) .. " coins"
			sign(gate, text, Enum.NormalId.Left)
			sign(gate, text, Enum.NormalId.Right)
			prompt(gate, "Unlock", zone.name, 14)
		end

		local zoneSpawn = part({ Name = zone.name .. "Spawn", Size = Vector3.new(4, 1, 4), Position = Vector3.new(centerX, GROUND_Y + 0.5, 0), Transparency = 1, CanCollide = false, Parent = map })
		zoneSpawn:SetAttribute("ZoneSpawn", zone.id)

		-- The water around this island counts as this zone
		local water = part({
			Name = zone.name .. "Water",
			Size = Vector3.new(225, 1, 600),
			Position = Vector3.new(centerX, 0.5, 0),
			Transparency = 1,
			CanCollide = false,
			CanTouch = false,
			Parent = fishing,
		})
		water:SetAttribute("FishingZone", zone.id)
	end

	-- Mist over the mangroves
	local fog = Instance.new("Part")
	fog.Name = "MangroveMist"
	fog.Anchored = true
	fog.CanCollide = false
	fog.CanQuery = false
	fog.Transparency = 1
	fog.Size = Vector3.new(120, 1, 120)
	fog.Position = Vector3.new(460, GROUND_Y + 2, 0)
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(220, 235, 220))
	mist.Transparency = NumberSequence.new(0.85)
	mist.Size = NumberSequence.new(14)
	mist.Lifetime = NumberRange.new(8, 12)
	mist.Rate = 6
	mist.Speed = NumberRange.new(1, 2)
	mist.Parent = fog
	fog.Parent = scenery

	map.Parent = Workspace
end

return MapBuilder
