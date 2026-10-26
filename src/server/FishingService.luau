-- Casting, bites and catches. The server decides which fish bites, so players
-- can't pick their own fish. The reel minigame runs on the player's screen.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Events = require(Shared.Events)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local EconomyService = require(script.Parent.EconomyService)
local CosmeticService = require(script.Parent.CosmeticService)

local FishingService = {}

local ROD_NAME = "Fishing Rod"
local SECONDS_PER_HIT = 0.3 -- fastest a human can finish each reel hit

local random = Random.new()
local casts = {} -- [player] = current cast
local lastCast = {} -- [player] = os.clock()
local nextCastId = 0

local function fishingZoneParts()
	local result = {}
	for _, item in ipairs(Workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("FishingZone") then
			table.insert(result, item)
		end
	end
	return result
end

local zoneParts = {}

local function zoneAt(position)
	for _, zonePart in ipairs(zoneParts) do
		local relative = zonePart.CFrame:PointToObjectSpace(position)
		local half = zonePart.Size / 2
		if math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and math.abs(relative.Y) <= half.Y + 3 then
			return zonePart:GetAttribute("FishingZone")
		end
	end
	return nil
end

-- True if there is land (an island, a bridge...) at this spot instead of water
local function isOverLand(position, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = table.clone(zoneParts)
	table.insert(ignore, character)
	params.FilterDescendantsInstances = ignore
	params.IgnoreWater = true
	local hit = Workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	return hit ~= nil and hit.Instance ~= Workspace.Terrain and hit.Position.Y > position.Y + 0.5
end

local function rodTip(player)
	local character = player.Character
	local tool = character and character:FindFirstChild(ROD_NAME)
	local handle = tool and tool:FindFirstChild("Handle")
	return handle and handle:FindFirstChild("Tip")
end

local function clearCast(player)
	local cast = casts[player]
	casts[player] = nil
	if cast and cast.bobber then
		cast.bobber:Destroy()
	end
end

local function makeBobber(player, position)
	local bobber = Instance.new("Part")
	bobber.Name = player.Name .. "Bobber"
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.8, 0.8, 0.8)
	bobber.Color = Color3.fromRGB(255, 60, 60)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.Position = position
	local attachment = Instance.new("Attachment")
	attachment.Parent = bobber

	-- The fishing line is a Beam: it only draws a line, so it can't pull the player
	local tip = rodTip(player)
	if tip then
		local line = Instance.new("Beam")
		line.Attachment0 = tip
		line.Attachment1 = attachment
		line.Width0 = 0.06
		line.Width1 = 0.06
		line.FaceCamera = true
		line.CurveSize0 = -2
		line.Segments = 12
		line.Color = ColorSequence.new(Color3.new(1, 1, 1))
		line.Transparency = NumberSequence.new(0.2)
		line.Parent = bobber
	end
	CosmeticService.DecorateBobber(player, bobber)
	bobber.Parent = Workspace
	return bobber
end

-- Pick which fish bites, using rod luck, weather and the weekly event
local function rollFish(data, zoneId)
	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]
	local weather = Events.GetWeather()
	local eventFish = Events.GetEventFish()

	local byRarity = {}
	for _, fish in ipairs(Fish.ByZone[zoneId] or {}) do
		byRarity[fish.rarity] = byRarity[fish.rarity] or {}
		table.insert(byRarity[fish.rarity], fish)
	end

	local choices = {}
	local total = 0
	for _, rarity in ipairs(Fish.Rarities) do
		if byRarity[rarity.id] then
			local weight = rarity.weight
			if rarity.order >= 3 then
				weight *= rod.luck * (weather.luckMultiplier or 1)
			end
			if rarity.order >= 5 then
				weight *= weather.legendaryMultiplier or 1
			end
			total += weight
			table.insert(choices, { rarity = rarity, weight = weight })
		end
	end

	local pick = random:NextNumber(0, total)
	local chosen = choices[1].rarity
	for _, choice in ipairs(choices) do
		pick -= choice.weight
		if pick <= 0 then
			chosen = choice.rarity
			break
		end
	end

	local fish
	if chosen.id == "Legendary" and eventFish.zone == zoneId and random:NextNumber() < 0.5 then
		fish = eventFish
	else
		local pool = byRarity[chosen.id]
		fish = pool[random:NextInteger(1, #pool)]
	end

	-- Heavier fish are rarer and worth more
	local roll = random:NextNumber() ^ 1.6
	local weight = fish.weight[1] + (fish.weight[2] - fish.weight[1]) * roll
	local shiny = random:NextNumber() < Config.ShinyChance * (weather.shinyMultiplier or 1)
	local value = fish.value * (0.75 + 0.5 * roll)
	if shiny then
		value *= Config.ShinyValueMultiplier
	end

	return {
		id = fish.id,
		weight = math.floor(weight * 10 + 0.5) / 10,
		value = math.max(1, math.floor(value)),
		shiny = shiny,
	}
end

local function announce(player, fish, caught)
	local rarity = Fish.RarityById[fish.rarity]
	if rarity.order < 5 then
		return
	end
	local text = string.format("%s caught a %s%s %s!", player.DisplayName, caught.shiny and "Shiny " or "", fish.rarity, fish.name)
	for _, other in ipairs(Players:GetPlayers()) do
		Remotes.Notify:FireClient(other, text, "rare")
	end
end

local function onCast(player, target)
	if typeof(target) ~= "Vector3" then
		return
	end
	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not root or not humanoid or humanoid.Health <= 0 or not character:FindFirstChild(ROD_NAME) then
		return
	end
	if lastCast[player] and os.clock() - lastCast[player] < Config.CastCooldown then
		return
	end

	if #data.bag >= runtime.bagSize then
		if ShopService.HasPass(player, "AutoSell") then
			EconomyService.SellAll(player)
		else
			Remotes.Notify:FireClient(player, "Your bag is full! Sell your fish at the Fish Market.", "warning")
			return
		end
	end

	local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
	if flat.Magnitude > Config.MaxCastDistance then
		Remotes.Notify:FireClient(player, "That's too far. Get closer to the water.", "warning")
		return
	end

	local zoneId = zoneAt(target)
	if not zoneId or isOverLand(target, character) then
		Remotes.Notify:FireClient(player, "Cast into the water to fish.", "warning")
		return
	end
	if not data.zones[zoneId] then
		local zone = Zones.ById[zoneId]
		Remotes.Notify:FireClient(player, "Unlock " .. (zone and zone.name or zoneId) .. " to fish here.", "warning")
		return
	end

	clearCast(player)
	lastCast[player] = os.clock()
	nextCastId += 1
	local castId = nextCastId
	local surface = Vector3.new(target.X, 0.3, target.Z)
	local cast = { id = castId, zone = zoneId, phase = "waiting", bobber = makeBobber(player, surface) }
	casts[player] = cast

	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]
	local weather = Events.GetWeather()
	local wait = random:NextNumber(Config.BiteWaitMin, Config.BiteWaitMax) * rod.speed * (weather.biteMultiplier or 1)

	task.delay(wait, function()
		if casts[player] ~= cast or not player.Parent then
			return
		end
		local latest = DataService.Get(player)
		if not latest then
			return
		end
		cast.catch = rollFish(latest, zoneId)
		cast.phase = "bite"
		cast.biteAt = os.clock()
		if cast.bobber then
			cast.bobber.Position -= Vector3.new(0, 0.4, 0)
			cast.bobber.Color = Color3.fromRGB(255, 220, 0)
		end
		local rarity = Fish.RarityById[Fish.ById[cast.catch.id].rarity]
		Remotes.Bite:FireClient(player, castId, {
			rarity = rarity.id,
			hits = rarity.hits,
			speed = rarity.speed,
			control = rod.control,
		})

		task.delay(Config.ReelWindow, function()
			if casts[player] == cast then
				clearCast(player)
				Remotes.CatchResult:FireClient(player, castId, nil)
			end
		end)
	end)
	return true
end

local function onReel(player, castId, success)
	local cast = casts[player]
	if not cast or cast.id ~= castId or cast.phase ~= "bite" then
		return
	end
	clearCast(player)

	local fish = Fish.ById[cast.catch.id]
	local rarity = Fish.RarityById[fish.rarity]
	local tooFast = os.clock() - cast.biteAt < rarity.hits * SECONDS_PER_HIT
	if success ~= true or tooFast then
		Remotes.CatchResult:FireClient(player, castId, nil)
		return
	end

	local caught = cast.catch
	local isNew = DataService.Update(player, function(data)
		table.insert(data.bag, caught)
		data.totalCaught += 1
		local entry = data.book[caught.id]
		local firstTime = entry == nil
		if firstTime then
			entry = { count = 0, best = 0, shiny = 0 }
			data.book[caught.id] = entry
		end
		entry.count += 1
		entry.best = math.max(entry.best, caught.weight)
		if caught.shiny then
			entry.shiny += 1
		end
		return firstTime
	end)

	Remotes.CatchResult:FireClient(player, castId, {
		id = caught.id,
		weight = caught.weight,
		value = caught.value,
		shiny = caught.shiny,
		isNew = isNew,
	})
	announce(player, fish, caught)

	local data = DataService.Get(player)
	local runtime = DataService.GetRuntime(player)
	if data and runtime and #data.bag >= runtime.bagSize and ShopService.HasPass(player, "AutoSell") then
		EconomyService.SellAll(player)
	end
end

-- Builds the rod tool from the player's equipped rod and rod skin
local function buildRod(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local rod = Rods.ById[data.equippedRod] or Rods.ById[Rods.Default]

	local tool = Instance.new("Tool")
	tool.Name = ROD_NAME
	tool.ToolTip = rod.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true

	local length = 7
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.25, length, 0.25)
	handle.CanCollide = false
	handle.Massless = true
	handle.Color = rod.color
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool

	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, length / 2, 0)
	tip.Parent = handle

	-- Hold the rod near its bottom end, tilted forward.
	-- If the rod ever points the wrong way, change ROD_TILT (e.g. to -50).
	local ROD_TILT = 50
	tool.Grip = CFrame.new(0, -length / 2 + 0.6, 0) * CFrame.Angles(math.rad(ROD_TILT), 0, 0)

	CosmeticService.StyleRod(player, handle)
	return tool
end

local function giveRod(player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then
		return
	end
	local character = player.Character
	local wasEquipped = character and character:FindFirstChild(ROD_NAME) ~= nil
	for _, container in ipairs({ backpack, character }) do
		local old = container and container:FindFirstChild(ROD_NAME)
		if old then
			old:Destroy()
		end
	end
	local tool = buildRod(player)
	if not tool then
		return
	end
	if wasEquipped and character then
		tool.Parent = character
	else
		tool.Parent = backpack
	end
end

function FishingService.GiveRod(player)
	clearCast(player)
	giveRod(player)
end

function FishingService.Start()
	zoneParts = fishingZoneParts()
	Workspace.DescendantAdded:Connect(function(item)
		if item:IsA("BasePart") and item:GetAttribute("FishingZone") then
			table.insert(zoneParts, item)
		end
	end)

	Remotes.Cast.OnServerInvoke = function(player, target)
		return onCast(player, target) == true
	end
	Remotes.Reel.OnServerEvent:Connect(onReel)
	Remotes.CancelCast.OnServerEvent:Connect(function(player)
		clearCast(player)
	end)

	DataService.OnLoaded(function(player)
		player.CharacterAdded:Connect(function()
			clearCast(player)
			task.defer(giveRod, player)
		end)
		task.spawn(function()
			if DataService.WaitFor(player) and player.Character then
				giveRod(player)
			end
		end)
	end)

	-- Rebuild the rod when the player equips a new rod or rod skin
	local rodLooks = {}
	DataService.OnChanged(function(player, data)
		local look = data.equippedRod .. "|" .. tostring(data.cosmetics.equipped.rodSkin)
		if rodLooks[player] ~= nil and rodLooks[player] ~= look then
			FishingService.GiveRod(player)
		end
		rodLooks[player] = look
	end)

	Players.PlayerRemoving:Connect(function(player)
		clearCast(player)
		lastCast[player] = nil
		rodLooks[player] = nil
	end)
end

return FishingService
