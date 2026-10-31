-- A real-looking crown for the top of a head: a gold band with jewels, pointed
-- tips with pearls, and a red velvet cap with a little gold cross on top.
-- Crown.Build(head, gold) returns a Model whose parts are welded to the head.

local Crown = {}

local SEGMENTS = 8
local VELVET = Color3.fromRGB(165, 20, 45)
local PEARL = Color3.fromRGB(255, 250, 240)
local JEWELS = {
	Color3.fromRGB(230, 30, 60), -- ruby
	Color3.fromRGB(40, 110, 255), -- sapphire
	Color3.fromRGB(30, 200, 100), -- emerald
	Color3.fromRGB(40, 110, 255),
}

function Crown.Build(head, gold)
	gold = gold or Color3.fromRGB(255, 200, 40)
	local model = Instance.new("Model")
	model.Name = "Crown"

	local function add(name, className, size, offset, color, material, shape)
		local part = Instance.new(className)
		part.Name = name
		if shape then
			part.Shape = shape
		end
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.Metal
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.CFrame = head.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = part
		weld.C0 = offset
		weld.Parent = part
		part.Parent = model
		return part
	end

	local radius = math.clamp(head.Size.X * 0.38, 0.35, 0.6)
	local bandHeight = radius * 0.6
	local thick = 0.08
	local bandY = head.Size.Y / 2 + bandHeight / 2 - 0.08
	local width = 2 * (radius + thick / 2) * math.tan(math.pi / SEGMENTS)

	for index = 1, SEGMENTS do
		local angle = (index - 1) * 2 * math.pi / SEGMENTS
		local at = CFrame.new(0, bandY, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, radius)
		add("Band", "Part", Vector3.new(width, bandHeight, thick), at, gold)
		add("Rim", "Part", Vector3.new(width, 0.05, thick + 0.04), at * CFrame.new(0, -bandHeight / 2 + 0.025, 0), gold)
		add("Rim", "Part", Vector3.new(width, 0.05, thick + 0.04), at * CFrame.new(0, bandHeight / 2 - 0.025, 0), gold)
		add("Jewel", "Part", Vector3.new(0.13, 0.13, 0.13), at * CFrame.new(0, 0, thick / 2), JEWELS[(index - 1) % #JEWELS + 1], Enum.Material.Neon, Enum.PartType.Ball)

		-- A point on top of each segment: two wedges make a triangle.
		-- Tall points (with a pearl) and short points take turns.
		local tall = index % 2 == 1
		local height = radius * (tall and 0.85 or 0.5)
		local base = at * CFrame.new(0, bandHeight / 2 + height / 2, 0)
		add("Point", "WedgePart", Vector3.new(0.05, height, width / 2), base * CFrame.new(width / 4, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), gold)
		add("Point", "WedgePart", Vector3.new(0.05, height, width / 2), base * CFrame.new(-width / 4, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), gold)
		local tipSize = tall and 0.13 or 0.08
		add("Tip", "Part", Vector3.new(tipSize, tipSize, tipSize), at * CFrame.new(0, bandHeight / 2 + height, 0), tall and PEARL or gold, tall and Enum.Material.SmoothPlastic or Enum.Material.Metal, Enum.PartType.Ball)
	end

	-- Velvet cap inside the band, with a gold ball and cross on top
	local capSize = radius * 1.85
	add("Velvet", "Part", Vector3.new(capSize, capSize, capSize), CFrame.new(0, bandY - 0.04, 0), VELVET, Enum.Material.Fabric, Enum.PartType.Ball)
	local capTop = bandY - 0.04 + capSize / 2
	add("Orb", "Part", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0, capTop + 0.05, 0), gold, Enum.Material.Metal, Enum.PartType.Ball)
	add("Cross", "Part", Vector3.new(0.05, 0.24, 0.05), CFrame.new(0, capTop + 0.23, 0), gold)
	add("Cross", "Part", Vector3.new(0.16, 0.05, 0.05), CFrame.new(0, capTop + 0.27, 0), gold)

	return model
end

return Crown
