-- General game settings. Change numbers here to rebalance the game.

local Config = {}

Config.GameName = "Reel Legends"

-- Saving
Config.DataStoreName = "PlayerData_v1"
Config.LeaderboardStoreName = "TotalCaught_v1"
Config.AutosaveSeconds = 120

-- Fish bag
Config.BagSize = 20
Config.BigBagSize = 60 -- with the Big Bag pass

-- Fishing
Config.MaxCastDistance = 80 -- studs from the player to the bobber
Config.BiteWaitMin = 3.5 -- seconds, before rod speed bonus
Config.BiteWaitMax = 8
Config.ReelWindow = 15 -- seconds the player has to finish reeling after a bite
Config.CastCooldown = 1
Config.ShinyChance = 1 / 100
Config.ShinyValueMultiplier = 3

-- Rebirth: cost = RebirthBaseCost * RebirthCostGrowth ^ rebirths
Config.RebirthBaseCost = 1000000
Config.RebirthCostGrowth = 3
Config.RebirthSellBonus = 0.25 -- +25% coins from selling per rebirth
Config.RebirthRequiresZone = "frostbite"

-- Daily login reward: DailyRewardBase * streak day (streak capped at 7)
Config.DailyRewardBase = 100
Config.DailyStreakCap = 7

-- Set to true to try every game pass for free while testing in Roblox Studio.
-- Has no effect in the live game.
Config.TestPassesInStudio = false

-- How long each weather lasts, in seconds
Config.WeatherSeconds = 15 * 60

function Config.RebirthCost(rebirths)
	return math.floor(Config.RebirthBaseCost * Config.RebirthCostGrowth ^ rebirths)
end

function Config.SellMultiplier(rebirths)
	return 1 + Config.RebirthSellBonus * rebirths
end

return Config
