-- Coins: selling fish, buying rods, unlocking zones, rebirths, daily rewards,
-- plus the menu buttons players press (all go through the "Action" remote).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Shop = require(Shared.Shop)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)

local EconomyService = {}

local function notify(player, text, kind)
	Remotes.Notify:FireClient(player, text, kind)
end

function EconomyService.SellAll(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Still loading"
	end
	if #data.bag == 0 then
		return false, "Your bag is empty. Go catch some fish!"
	end
	local count = #data.bag
	local earned = DataService.Update(player, function(saved)
		local total = 0
		for _, fish in ipairs(saved.bag) do
			total += fish.value
		end
		total = math.floor(total * Config.SellMultiplier(saved.rebirths))
		saved.coins += total
		saved.totalEarned += total
		saved.bag = {}
		return total
	end)
	notify(player, string.format("Sold %d fish for %s coins", count, Format.Number(earned)), "coins")
	return true
end

function EconomyService.BuyRod(player, rodId)
	local rod = Rods.ById[rodId]
	local data = DataService.Get(player)
	if not rod or not data then
		return false, "Unknown rod"
	end
	if data.rodsOwned[rod.id] then
		return EconomyService.EquipRod(player, rodId)
	end
	if rod.requiresRebirths and data.rebirths < rod.requiresRebirths then
		return false, string.format("Needs %d rebirth(s)", rod.requiresRebirths)
	end
	if data.coins < rod.price then
		return false, "Not enough coins"
	end
	DataService.Update(player, function(saved)
		saved.coins -= rod.price
		saved.rodsOwned[rod.id] = true
		saved.equippedRod = rod.id
	end)
	notify(player, "You bought the " .. rod.name .. "!", "success")
	return true
end

function EconomyService.EquipRod(player, rodId)
	local data = DataService.Get(player)
	if not data or not data.rodsOwned[rodId] then
		return false, "You don't own that rod"
	end
	DataService.Update(player, function(saved)
		saved.equippedRod = rodId
	end)
	return true
end

function EconomyService.UnlockZone(player, zoneId)
	local zone = Zones.ById[zoneId]
	local data = DataService.Get(player)
	if not zone or not data then
		return false, "Unknown zone"
	end
	if data.zones[zone.id] then
		return true
	end
	if data.coins < zone.price then
		return false, string.format("You need %s coins to unlock %s", Format.Number(zone.price), zone.name)
	end
	DataService.Update(player, function(saved)
		saved.coins -= zone.price
		saved.zones[zone.id] = true
	end)
	notify(player, zone.name .. " unlocked!", "success")
	return true
end

function EconomyService.Teleport(player, zoneId)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return false, "Not ready"
	end
	if zoneId ~= "hub" then
		if not ShopService.HasPass(player, "Teleporter") then
			return false, "The Zone Teleporter pass lets you teleport to zones"
		end
		if not data.zones[zoneId] then
			return false, "Unlock that zone first"
		end
	end
	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("ZoneSpawn") == zoneId then
			character:PivotTo(item.CFrame + Vector3.new(0, 4, 0))
			return true
		end
	end
	return false, "No teleport spot for that zone"
end

function EconomyService.Rebirth(player)
	local data = DataService.Get(player)
	if not data then
		return false, "Not ready"
	end
	local cost = Config.RebirthCost(data.rebirths)
	local requiredZone = Zones.ById[Config.RebirthRequiresZone]
	if requiredZone and not data.zones[requiredZone.id] then
		return false, "Unlock " .. requiredZone.name .. " first"
	end
	if data.coins < cost then
		return false, string.format("You need %s coins to rebirth", Format.Number(cost))
	end
	DataService.Update(player, function(saved)
		-- Keep: fish book, cosmetics, titles, total stats. Reset: coins, rods, zones, bag.
		saved.rebirths += 1
		saved.coins = 0
		saved.bag = {}
		saved.rodsOwned = { [Rods.Default] = true }
		saved.equippedRod = Rods.Default
		saved.zones = { [Zones.Default] = true }
	end)
	EconomyService.Teleport(player, "hub")
	notify(player, string.format("Reborn! You now earn +%d%% coins from fish.", math.floor((Config.SellMultiplier(data.rebirths) - 1) * 100 + 0.5)), "success")
	return true
end

function EconomyService.EquipCosmetic(player, cosmeticId)
	local item = Shop.CosmeticById[cosmeticId]
	local data = DataService.Get(player)
	if not item or not data or not data.cosmetics.owned[cosmeticId] then
		return false, "You don't own that"
	end
	DataService.Update(player, function(saved)
		if saved.cosmetics.equipped[item.kind] == cosmeticId then
			saved.cosmetics.equipped[item.kind] = nil -- pressing again takes it off
		else
			saved.cosmetics.equipped[item.kind] = cosmeticId
		end
	end)
	return true
end

local function giveDailyReward(player, data)
	local today = math.floor(os.time() / 86400)
	if data.lastDailyDay == today then
		return
	end
	if data.lastDailyDay == today - 1 then
		data.dailyStreak += 1
	else
		data.dailyStreak = 1
	end
	data.lastDailyDay = today
	local day = math.min(data.dailyStreak, Config.DailyStreakCap)
	local reward = math.floor(Config.DailyRewardBase * day * Config.SellMultiplier(data.rebirths))
	data.coins += reward
	data.totalEarned += reward
	task.spawn(function()
		if DataService.WaitFor(player) then
			notify(player, string.format("Daily reward (day %d streak): +%s coins! Come back tomorrow for more.", data.dailyStreak, Format.Number(reward)), "coins")
		end
	end)
end

local actions = {
	BuyRod = EconomyService.BuyRod,
	EquipRod = EconomyService.EquipRod,
	UnlockZone = EconomyService.UnlockZone,
	Teleport = EconomyService.Teleport,
	Rebirth = EconomyService.Rebirth,
	EquipCosmetic = EconomyService.EquipCosmetic,
}

function EconomyService.Start()
	DataService.OnLoaded(function(player, data)
		giveDailyReward(player, data)
	end)

	Remotes.Action.OnServerInvoke = function(player, actionName, argument)
		local action = actions[actionName]
		if type(actionName) ~= "string" or not action then
			return false, "Unknown action"
		end
		if argument ~= nil and type(argument) ~= "string" then
			return false, "Bad request"
		end
		local ok, success, message = pcall(action, player, argument)
		if not ok then
			warn("[EconomyService] " .. actionName .. " failed: " .. tostring(success))
			return false, "Something went wrong"
		end
		return success, message
	end
end

return EconomyService
