-- While any menu window is open the player can't walk, jump or use
-- shopkeeper prompts. Fishing ignores clicks too (see Fishing.luau).

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local UI = require(script.Parent.UI)

local MenuLock = {}

local player = Players.LocalPlayer

function MenuLock.Init()
	local controls = nil
	task.spawn(function()
		local ok, result = pcall(function()
			local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 20)
			return module and require(module):GetControls()
		end)
		if ok then
			controls = result
		end
	end)

	UI.WindowChanged:Connect(function()
		local open = UI.IsWindowOpen()
		ProximityPromptService.Enabled = not open
		if controls then
			if open then
				controls:Disable()
			else
				controls:Enable()
			end
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if open and humanoid then
			humanoid:Move(Vector3.zero) -- stop on the spot
			humanoid.Jump = false
		end
	end)
end

return MenuLock
