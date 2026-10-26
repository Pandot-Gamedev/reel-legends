-- All the messages between server and players. The server creates them;
-- players wait for them to appear.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"DataUpdate", -- server -> player: the player's full save data
	"Notify", -- server -> player: a toast message
	"OpenPanel", -- server -> player: open a menu (e.g. the rod shop)
	"CancelCast", -- player -> server: stop fishing
	"Bite", -- server -> player: a fish bit, start the reel minigame
	"Reel", -- player -> server: reel minigame result
	"CatchResult", -- server -> player: what was caught (or that it escaped)
}

local FUNCTIONS = {
	"Action", -- player -> server: buy rod, unlock zone, rebirth, teleport, equip...
	"Cast", -- player -> server: cast at a position, returns true if the bobber landed
}

local Remotes = {}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(EVENTS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	for _, name in ipairs(FUNCTIONS) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

for _, name in ipairs(EVENTS) do
	Remotes[name] = folder:WaitForChild(name)
end
for _, name in ipairs(FUNCTIONS) do
	Remotes[name] = folder:WaitForChild(name)
end

return Remotes
