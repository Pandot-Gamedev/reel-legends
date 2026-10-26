-- The menus: Fish Book, Rods, Shop, Teleport and Rebirth.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Fish = require(Shared.Fish)
local Rods = require(Shared.Rods)
local Zones = require(Shared.Zones)
local Shop = require(Shared.Shop)
local Events = require(Shared.Events)
local Format = require(Shared.Format)

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Notifications = require(script.Parent.Notifications)
local T = UI.Theme

local player = Players.LocalPlayer
local Panels = {}

local function act(actionName, argument)
	local ok, message = State.Action(actionName, argument)
	if not ok and message then
		Notifications.Show(message, "warning")
	end
	return ok
end

-- Robux prices come from Roblox, so they always match the Creator Dashboard
local priceCache = {}
local function robuxPrice(id, infoType, onReady)
	local key = tostring(infoType) .. id
	if priceCache[key] then
		onReady(priceCache[key])
		return
	end
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			priceCache[key] = info.PriceInRobux
			onReady(info.PriceInRobux)
		end
	end)
end

local function row(parent, height, order)
	return UI.new("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = T.Card,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { UI.corner(10) })
end

local function heading(parent, text, order)
	UI.label(text, { Size = UDim2.new(1, -8, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = T.Gold, LayoutOrder = order, Parent = parent })
end

------------------------------------------------------------------ Fish Book
local bookTab = Zones.List[1].id

local function renderBook(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(10).Parent = body

	local tabs = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 40), BackgroundTransparency = 1, LayoutOrder = 1, Parent = body }, { UI.list(8, Enum.FillDirection.Horizontal) })
	local tabList = {}
	for _, zone in ipairs(Zones.List) do
		table.insert(tabList, { id = zone.id, name = zone.name, fish = Fish.ByZone[zone.id] or {} })
	end
	table.insert(tabList, { id = "event", name = "Legends", fish = Fish.EventFish })

	local found, total = 0, #Fish.List
	for id in pairs(data.book) do
		if Fish.ById[id] then
			found += 1
		end
	end

	local current
	for index, tab in ipairs(tabList) do
		if tab.id == bookTab then
			current = tab
		end
		UI.button(tab.name, tab.id == bookTab and T.Accent or T.Card, function()
			bookTab = tab.id
			Panels.Book.refresh()
		end, { Size = UDim2.fromOffset(136, 36), LayoutOrder = index, Parent = tabs })
	end
	current = current or tabList[1]

	local zoneFound = 0
	for _, fish in ipairs(current.fish) do
		if data.book[fish.id] then
			zoneFound += 1
		end
	end
	UI.label(string.format("%s: %d/%d found   (whole book: %d/%d)", current.name, zoneFound, #current.fish, found, total), {
		Size = UDim2.new(1, -8, 0, 24),
		Font = T.BodyFont,
		TextColor3 = T.Muted,
		LayoutOrder = 2,
		Parent = body,
	})

	local grid = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = body }, {
		UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(134, 112), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	for index, fish in ipairs(current.fish) do
		local entry = data.book[fish.id]
		local rarity = Fish.RarityById[fish.rarity]
		local card = UI.new("Frame", { BackgroundColor3 = T.Card, LayoutOrder = index, Parent = grid }, { UI.corner(10), UI.stroke(rarity.color, 2), UI.padding(6), UI.list(2) })
		UI.label(entry and fish.name or "???", { Size = UDim2.new(1, 0, 0, 34), TextWrapped = true, Parent = card })
		UI.label(fish.rarity, { Size = UDim2.new(1, 0, 0, 18), TextColor3 = rarity.color, Parent = card })
		local detail = "Not caught yet"
		if entry then
			detail = string.format("x%d  best %s", entry.count, Format.Weight(entry.best))
			if entry.shiny > 0 then
				detail ..= string.format("\n%d shiny", entry.shiny)
			end
		end
		UI.label(detail, { Size = UDim2.new(1, 0, 0, 34), Font = T.BodyFont, TextColor3 = T.Muted, TextWrapped = true, Parent = card })
	end

	if current.id == "event" then
		local eventFish, left = Events.GetEventFish()
		local zone = Zones.ById[eventFish.zone]
		UI.label(string.format("This week: %s in %s (ends in %s)", eventFish.name, zone and zone.name or "", Format.Duration(left)), {
			Size = UDim2.new(1, -8, 0, 24),
			Font = T.BodyFont,
			TextColor3 = T.Gold,
			LayoutOrder = 4,
			Parent = body,
		})
	end
end

------------------------------------------------------------------ Rods
local function renderRods(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	for index, rod in ipairs(Rods.List) do
		local card = row(body, 64, index)
		UI.label(rod.name, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rod.color:Lerp(Color3.new(1, 1, 1), 0.4), Parent = card })
		local stats = string.format("Luck x%.2f   Bites %d%% faster   Reel zone +%d%%", rod.luck, math.floor((1 - rod.speed) * 100 + 0.5), math.floor(rod.control * 100 + 0.5))
		UI.label(stats, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(0.68, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })

		local text, color, onClick
		if data.equippedRod == rod.id then
			text, color = "Equipped", T.Card
		elseif data.rodsOwned[rod.id] then
			text, color = "Equip", T.Accent
			onClick = function()
				act("EquipRod", rod.id)
			end
		elseif rod.requiresRebirths and data.rebirths < rod.requiresRebirths then
			text, color = string.format("%d rebirth", rod.requiresRebirths), T.Card
		else
			text = Format.Number(rod.price) .. " coins"
			color = data.coins >= rod.price and T.Good or T.Bad
			onClick = function()
				act("BuyRod", rod.id)
			end
		end
		UI.button(text, color, onClick, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 40), Parent = card })
	end
end

------------------------------------------------------------------ Shop
local function renderShop(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	heading(body, "Game passes (yours forever)", nextOrder())
	for _, pass in ipairs(Shop.Passes) do
		local card = row(body, 64, nextOrder())
		UI.label(pass.name, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.6, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		UI.label(pass.description, { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(0.68, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Font = T.BodyFont, TextColor3 = T.Muted, Parent = card })
		local button = UI.button("...", T.Good, nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 40), Parent = card })
		if State.HasPass(pass.id) then
			button.Text = "Owned"
			button.BackgroundColor3 = T.Card
		elseif pass.gamePassId == 0 then
			button.Text = "Coming soon"
			button.BackgroundColor3 = T.Card
		else
			robuxPrice(pass.gamePassId, Enum.InfoType.GamePass, function(price)
				button.Text = "R$ " .. price
			end)
			button.Activated:Connect(function()
				MarketplaceService:PromptGamePassPurchase(player, pass.gamePassId)
			end)
		end
	end

	local function cosmeticRow(item)
		local card = row(body, 52, nextOrder())
		local label = UI.label(item.name, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.65, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = label })
		local owned = data.cosmetics.owned[item.id]
		local equipped = data.cosmetics.equipped[item.kind] == item.id
		local button = UI.button("...", T.Good, nil, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 36), Parent = card })
		if owned then
			button.Text = equipped and "Unequip" or "Equip"
			button.BackgroundColor3 = equipped and T.Card or T.Accent
			button.Activated:Connect(function()
				act("EquipCosmetic", item.id)
			end)
		elseif item.earned then
			button.Text = "Not earned"
			button.BackgroundColor3 = T.Card
		elseif item.productId == 0 then
			button.Text = "Coming soon"
			button.BackgroundColor3 = T.Card
		else
			robuxPrice(item.productId, Enum.InfoType.Product, function(price)
				button.Text = "R$ " .. price
			end)
			button.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, item.productId)
			end)
		end
	end

	heading(body, "Rod skins (looks only)", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "rodSkin" then
			cosmeticRow(item)
		end
	end
	heading(body, "Trails (looks only)", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "trail" then
			cosmeticRow(item)
		end
	end
	heading(body, "Titles", nextOrder())
	for _, item in ipairs(Shop.Cosmetics) do
		if item.kind == "title" then
			cosmeticRow(item)
		end
	end
	heading(body, "Earned titles (free, unlocked by playing)", nextOrder())
	for _, item in ipairs(Shop.EarnedTitles) do
		cosmeticRow(item)
	end
end

------------------------------------------------------------------ Teleport
local function renderTeleport(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(8).Parent = body
	local hasPass = State.HasPass("Teleporter")
	if not hasPass then
		UI.label("Walk across the bridges to reach zones, or get the Zone Teleporter pass in the Shop.", {
			Size = UDim2.new(1, -8, 0, 40),
			TextWrapped = true,
			Font = T.BodyFont,
			TextColor3 = T.Muted,
			LayoutOrder = 0,
			Parent = body,
		})
	end

	local hubRow = row(body, 56, 1)
	UI.label("Harbor (hub)", { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = hubRow })
	UI.button("Go", T.Accent, function()
		if act("Teleport", "hub") then
			Panels.Teleport.close()
		end
	end, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(130, 38), Parent = hubRow })

	for index, zone in ipairs(Zones.List) do
		local card = row(body, 56, index + 1)
		UI.label(zone.name, { Position = UDim2.fromOffset(12, 14), Size = UDim2.new(0.6, 0, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = zone.color, Parent = card })
		local props = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 38), Parent = card }
		if not data.zones[zone.id] then
			UI.button("Unlock " .. Format.Number(zone.price), data.coins >= zone.price and T.Good or T.Bad, function()
				act("UnlockZone", zone.id)
			end, props)
		elseif hasPass then
			UI.button("Go", T.Accent, function()
				if act("Teleport", zone.id) then
					Panels.Teleport.close()
				end
			end, props)
		else
			UI.button("Unlocked", T.Card, nil, props)
		end
	end
end

------------------------------------------------------------------ Rebirth
local function renderRebirth(body)
	local data = State.data
	if not data then
		return
	end
	UI.list(10).Parent = body
	local cost = Config.RebirthCost(data.rebirths)
	local nowBonus = math.floor((Config.SellMultiplier(data.rebirths) - 1) * 100 + 0.5)
	local nextBonus = math.floor((Config.SellMultiplier(data.rebirths + 1) - 1) * 100 + 0.5)
	local requiredZone = Zones.ById[Config.RebirthRequiresZone]

	local lines = {
		string.format("Rebirths: %d   (now +%d%% coins from fish)", data.rebirths, nowBonus),
		string.format("Next rebirth: +%d%% coins from fish, forever", nextBonus),
		string.format("Cost: %s coins", Format.Number(cost)),
		"You keep: your Fish Book, titles, skins, trails and passes.",
		"You reset: coins, rods, unlocked zones and your bag.",
	}
	if requiredZone then
		table.insert(lines, "Requires: " .. requiredZone.name .. " unlocked.")
	end
	for index, text in ipairs(lines) do
		UI.label(text, { Size = UDim2.new(1, -8, 0, 26), TextWrapped = true, Font = index <= 3 and T.Font or T.BodyFont, TextColor3 = index <= 3 and T.Text or T.Muted, LayoutOrder = index, Parent = body })
	end
	local ready = data.coins >= cost and (not requiredZone or data.zones[requiredZone.id])
	UI.button("Rebirth", ready and T.Good or T.Card, function()
		if act("Rebirth") then
			Panels.Rebirth.close()
		end
	end, { Size = UDim2.fromOffset(200, 50), LayoutOrder = 99, Parent = body })
end

function Panels.Init(screenGui)
	Panels.Book = UI.window(screenGui, "Fish Book", renderBook)
	Panels.Rods = UI.window(screenGui, "Rods", renderRods)
	Panels.Shop = UI.window(screenGui, "Shop", renderShop)
	Panels.Teleport = UI.window(screenGui, "Travel", renderTeleport)
	Panels.Rebirth = UI.window(screenGui, "Rebirth", renderRebirth)

	State.Changed:Connect(function()
		for _, name in ipairs({ "Book", "Rods", "Shop", "Teleport", "Rebirth" }) do
			Panels[name].refresh()
		end
	end)
end

return Panels
