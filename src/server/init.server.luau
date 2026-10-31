-- Hook a Mythic Fish! server. Starts every service in order.

local MapBuilder = require(script.MapBuilder)
local DataService = require(script.DataService)
local ShopService = require(script.ShopService)
local TutorialService = require(script.TutorialService)
local NpcService = require(script.NpcService)
local EconomyService = require(script.EconomyService)
local CosmeticService = require(script.CosmeticService)
local FishingService = require(script.FishingService)
local WorldService = require(script.WorldService)
local CommunityService = require(script.CommunityService)

MapBuilder.Build()

-- Services that react to players loading must start before DataService
ShopService.Start()
TutorialService.Start()
EconomyService.Start()
CosmeticService.Start()
FishingService.Start()
WorldService.Start()
NpcService.Start()
CommunityService.Start({
	gameId = "fish",
	rewards = { "community_rod", "community_title" },
	equip = { rodSkin = "community_rod", title = "community_title" },
	rewardText = "Crew Rod Skin and Pandot Crew title",
})
DataService.Start()

print("[Hook a Mythic Fish!] Server ready")
