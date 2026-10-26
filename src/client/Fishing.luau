-- Casting and the reel minigame on the player's screen.
-- Equip the rod, click (or tap) the water, wait for the bite, then tap when the
-- moving needle is inside the green zone.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Fish = require(Shared.Fish)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Notifications = require(script.Parent.Notifications)
local T = UI.Theme

local Fishing = {}

local ROD_NAME = "Fishing Rod"
local BITE_TIMEOUT = 25 -- give up waiting if the server never sends a bite
local MINIGAME_SECONDS = 10

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local screenGui
local statusLabel

local phase = "idle" -- idle, waiting, reeling
local waitToken = 0

local function setStatus(text)
	statusLabel.Text = text or ""
	statusLabel.Visible = text ~= nil
end

local function reset()
	phase = "idle"
	waitToken += 1
	setStatus(nil)
end

local function isWater(result)
	if not result then
		return false
	end
	if result.Instance == Workspace.Terrain then
		return result.Material == Enum.Material.Water
	end
	return result.Instance:GetAttribute("FishingZone") ~= nil
end

-- Where the bobber should land: where the player clicked if that is water,
-- otherwise a spot in front of them.
local function castTarget(root)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = false

	local ray = mouse.UnitRay
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
	if isWater(hit) then
		return hit.Position
	end

	local look = root.CFrame.LookVector
	local ahead = root.Position + Vector3.new(look.X, 0, look.Z).Unit * 25
	return Vector3.new(ahead.X, 0.5, ahead.Z)
end

local function cast()
	if phase == "reeling" then
		return
	end
	if phase == "waiting" then
		-- Clicking again reels the line back in
		Remotes.CancelCast:FireServer()
		reset()
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local ok, landed = pcall(function()
		return Remotes.Cast:InvokeServer(castTarget(root))
	end)
	if not ok or not landed then
		return
	end

	phase = "waiting"
	waitToken += 1
	local token = waitToken
	setStatus("Waiting for a bite...  (click again to reel in)")
	task.delay(BITE_TIMEOUT, function()
		if waitToken == token and phase == "waiting" then
			reset()
		end
	end)
end

local hookedTools = setmetatable({}, { __mode = "k" })
local function hookTool(tool)
	if not hookedTools[tool] then
		hookedTools[tool] = true
		tool.Activated:Connect(cast)
	end
end

local function watchCharacter(character)
	reset()
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == ROD_NAME then
			hookTool(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == ROD_NAME and phase ~= "idle" then
			Remotes.CancelCast:FireServer()
			reset()
		end
	end)
end

-- The reel minigame. Calls done(true) if the player lands every hit.
local function playMinigame(info, done)
	local hitsNeeded = info.hits or 1
	local speed = (info.speed or 1) * 0.65 -- bar widths per second
	local zoneWidth = math.clamp(0.22 + (info.control or 0) - (hitsNeeded - 1) * 0.03, 0.08, 0.5)
	local rarity = Fish.RarityById[info.rarity]

	local overlay = UI.new("TextButton", {
		Name = "ReelOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 20,
		Parent = screenGui,
	})
	local box = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
		Size = UDim2.fromOffset(440, 120),
		BackgroundColor3 = T.Background,
		ZIndex = 21,
		Parent = overlay,
	}, { UI.corner(14), UI.stroke(rarity and rarity.color or T.Accent, 3) })
	local title = UI.label("", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 30), ZIndex = 22, Parent = box })
	local bar = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 50),
		Size = UDim2.new(1, -40, 0, 34),
		BackgroundColor3 = T.Card,
		ZIndex = 22,
		Parent = box,
	}, { UI.corner(8) })
	local zone = UI.new("Frame", { Size = UDim2.new(zoneWidth, 0, 1, 0), BackgroundColor3 = T.Good, ZIndex = 23, Parent = bar }, { UI.corner(8) })
	local needle = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 6, 1, 10), Position = UDim2.new(0, 0, 0, -5), BackgroundColor3 = T.Text, ZIndex = 24, Parent = bar })
	UI.label("Tap / click / Space when the line is in the green!", { Position = UDim2.new(0, 0, 1, -28), Size = UDim2.new(1, 0, 0, 20), Font = T.BodyFont, TextColor3 = T.Muted, ZIndex = 22, Parent = box })

	local hits = 0
	local position, direction = 0, 1
	local zoneStart = 0
	local finished = false
	local connections = {}

	local function placeZone()
		zoneStart = math.random() * (1 - zoneWidth)
		zone.Position = UDim2.new(zoneStart, 0, 0, 0)
		title.Text = string.format("%s bite!  %d/%d", info.rarity or "", hits, hitsNeeded)
	end
	placeZone()

	local function finish(success)
		if finished then
			return
		end
		finished = true
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		overlay:Destroy()
		done(success)
	end

	local function press()
		if finished then
			return
		end
		if position >= zoneStart and position <= zoneStart + zoneWidth then
			hits += 1
			if hits >= hitsNeeded then
				finish(true)
				return
			end
			speed *= 1.15
			placeZone()
		else
			finish(false)
		end
	end

	table.insert(connections, overlay.Activated:Connect(press))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.ButtonR2 then
			press()
		end
	end))
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		position += direction * speed * dt
		if position >= 1 then
			position, direction = 1, -1
		elseif position <= 0 then
			position, direction = 0, 1
		end
		needle.Position = UDim2.new(position, 0, 0, -5)
	end))
	task.delay(MINIGAME_SECONDS, function()
		finish(false)
	end)
end

local function showCatch(result)
	local fish = Fish.ById[result.id]
	local rarity = Fish.RarityById[fish.rarity]
	local card = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.32),
		Size = UDim2.fromOffset(360, 130),
		BackgroundColor3 = T.Background,
		Parent = screenGui,
	}, { UI.corner(16), UI.stroke(rarity.color, 4), UI.padding(10), UI.list(4) })
	local top = result.isNew and "NEW FISH!" or "Caught!"
	UI.label(top, { Size = UDim2.new(1, 0, 0, 22), TextColor3 = result.isNew and T.Gold or T.Muted, Parent = card })
	UI.label((result.shiny and "Shiny " or "") .. fish.name, { Size = UDim2.new(1, 0, 0, 36), TextColor3 = rarity.color, Parent = card })
	UI.label(string.format("%s  -  %s  -  worth %s coins", fish.rarity, Format.Weight(result.weight), Format.Number(result.value)), {
		Size = UDim2.new(1, 0, 0, 22),
		Font = T.BodyFont,
		Parent = card,
	})
	task.delay(2.5, function()
		local tween = TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		card:Destroy()
	end)
end

function Fishing.Init(gui)
	screenGui = gui
	statusLabel = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -120),
		Size = UDim2.fromOffset(460, 30),
		Visible = false,
		TextStrokeTransparency = 0.4,
		Parent = gui,
	})

	if player.Character then
		watchCharacter(player.Character)
		local tool = player.Character:FindFirstChild(ROD_NAME)
		if tool then
			hookTool(tool)
		end
	end
	player.CharacterAdded:Connect(watchCharacter)

	Remotes.Bite.OnClientEvent:Connect(function(castId, info)
		if phase ~= "waiting" then
			return
		end
		phase = "reeling"
		setStatus(nil)
		playMinigame(info, function(success)
			Remotes.Reel:FireServer(castId, success)
			if phase == "reeling" then
				setStatus("Reeling...")
			end
		end)
	end)

	Remotes.CatchResult.OnClientEvent:Connect(function(_, result)
		reset()
		if result then
			showCatch(result)
		else
			Notifications.Show("The fish got away...", "warning")
		end
	end)
end

return Fishing
