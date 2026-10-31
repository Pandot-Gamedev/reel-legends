-- Builds how a fishing rod looks: cork grips, a reel with line on its spool and
-- a crank, a tapered pole with thread bands, line guides and a metal tip.
-- The tool's Handle is an invisible stick the length of the rod; every visible
-- piece is welded to it, so the grip and the line's Tip never move.
--
-- Handle space: +Y runs from the butt (-length / 2) to the tip (+length / 2).
-- SIDE is the side the reel and guides hang on (under the rod in the hand).

local RodModel = {}

local SIDE = Vector3.new(0, 0, -1)
local ACROSS = Vector3.new(1, 0, 0) -- the crank sticks out this way
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder to run along Y

local CORK = Color3.fromRGB(196, 150, 98)
local METAL = Color3.fromRGB(190, 192, 200)
local DARK_METAL = Color3.fromRGB(45, 45, 50)
local LINE = Color3.fromRGB(245, 245, 245)

local function piece(handle, name, shape, size, offset, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.CFrame = handle.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = handle.Parent
	return part
end

-- A cylinder along the rod from y0 to y1, centered `out` studs to the side
local function tube(handle, name, y0, y1, diameter, color, material, out)
	local center = (out or Vector3.zero) + Vector3.new(0, (y0 + y1) / 2, 0)
	return piece(handle, name, Enum.PartType.Cylinder, Vector3.new(y1 - y0, diameter, diameter), CFrame.new(center) * UPRIGHT, color, material)
end

function RodModel.Build(handle, rod, length)
	local bottom = -length / 2
	local top = length / 2
	local material = rod.material or Enum.Material.SmoothPlastic
	local wrap = rod.wrap or Color3.fromRGB(40, 40, 40)
	local reelColor = rod.reel or DARK_METAL

	-- Handle end: butt cap, rear cork grip, reel seat, fore grip
	tube(handle, "ButtCap", bottom, bottom + 0.18, 0.32, DARK_METAL, Enum.Material.Metal)
	tube(handle, "RearGrip", bottom + 0.18, bottom + 1.35, 0.27, CORK, Enum.Material.Wood)
	tube(handle, "ReelSeat", bottom + 1.35, bottom + 1.8, 0.21, reelColor, Enum.Material.Metal)
	tube(handle, "SeatRing", bottom + 1.33, bottom + 1.41, 0.25, METAL, Enum.Material.Metal)
	tube(handle, "SeatRing", bottom + 1.74, bottom + 1.82, 0.25, METAL, Enum.Material.Metal)
	tube(handle, "ForeGrip", bottom + 1.8, bottom + 2.3, 0.23, CORK, Enum.Material.Wood)

	-- The pole, thinner toward the tip, with thread bands at each joint.
	-- Parts marked RodBlank take the rod skin's color.
	local sections = {
		{ bottom + 2.3, bottom + 4.4, 0.15 },
		{ bottom + 4.4, bottom + 6.0, 0.11 },
		{ bottom + 6.0, top - 0.04, 0.075 },
	}
	for index, section in ipairs(sections) do
		local blank = tube(handle, "Blank", section[1], section[2], section[3], rod.color, material)
		blank:SetAttribute("RodBlank", true)
		if rod.glow then
			local light = Instance.new("PointLight")
			light.Color = wrap
			light.Range = 4
			light.Brightness = 0.6
			light.Parent = blank
		end
		local band = tube(handle, "Wrap", section[1] - 0.02, section[1] + (index == 1 and 0.2 or 0.12), section[3] + 0.045, wrap, rod.glow and Enum.Material.Neon or Enum.Material.SmoothPlastic)
		band:SetAttribute("RodWrap", true)
	end
	piece(handle, "TipTop", Enum.PartType.Ball, Vector3.new(0.1, 0.1, 0.1), CFrame.new(0, top - 0.03, 0), METAL, Enum.Material.Metal)

	-- Line guides: a little foot on the pole holding a ring the line runs through
	local guides = { { bottom + 3.4, 0.24, 0.15 }, { bottom + 4.9, 0.17, 0.12 }, { bottom + 5.9, 0.13, 0.1 }, { top - 0.75, 0.1, 0.08 } }
	for _, guide in ipairs(guides) do
		local y, ring, out = guide[1], guide[2], guide[3]
		piece(handle, "GuideFoot", Enum.PartType.Block, Vector3.new(0.035, 0.1, out), CFrame.new(SIDE * (out / 2) + Vector3.new(0, y, 0)), DARK_METAL, Enum.Material.Metal)
		tube(handle, "GuideRing", y - 0.015, y + 0.015, ring, METAL, Enum.Material.Metal, SIDE * (out + ring / 2))
	end

	-- Spinning reel hanging under the reel seat
	local seatY = bottom + 1.57
	local reelOut = 0.5
	piece(handle, "ReelStem", Enum.PartType.Block, Vector3.new(0.07, 0.3, reelOut - 0.1), CFrame.new(SIDE * (reelOut / 2) + Vector3.new(0, seatY, 0)), reelColor, Enum.Material.Metal)
	local reelCenter = SIDE * reelOut + Vector3.new(0, seatY, 0)
	piece(handle, "ReelBody", Enum.PartType.Cylinder, Vector3.new(0.24, 0.36, 0.36), CFrame.new(reelCenter - Vector3.new(0, 0.08, 0)), reelColor, Enum.Material.Metal)
	tube(handle, "SpoolBack", seatY + 0.1, seatY + 0.16, 0.34, METAL, Enum.Material.Metal, SIDE * reelOut)
	tube(handle, "SpoolLine", seatY + 0.16, seatY + 0.34, 0.29, LINE, Enum.Material.SmoothPlastic, SIDE * reelOut)
	tube(handle, "SpoolFront", seatY + 0.34, seatY + 0.42, 0.33, METAL, Enum.Material.Metal, SIDE * reelOut)
	local arm = reelCenter - Vector3.new(0, 0.08, 0) + ACROSS * 0.3
	piece(handle, "CrankArm", Enum.PartType.Block, Vector3.new(0.4, 0.06, 0.06), CFrame.new(arm), METAL, Enum.Material.Metal)
	piece(handle, "CrankKnob", Enum.PartType.Cylinder, Vector3.new(0.18, 0.13, 0.13), CFrame.new(arm + ACROSS * 0.2 + SIDE * 0.09) * CFrame.Angles(0, math.rad(90), 0), wrap)

	-- Line from the spool up to the tip
	local from = Instance.new("Attachment")
	from.Name = "SpoolPoint"
	from.Position = SIDE * reelOut + Vector3.new(0, seatY + 0.38, 0)
	from.Parent = handle
	local to = Instance.new("Attachment")
	to.Name = "TipPoint"
	to.Position = Vector3.new(0, top, 0)
	to.Parent = handle
	local beam = Instance.new("Beam")
	beam.Name = "RodLine"
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Width0 = 0.025
	beam.Width1 = 0.02
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(LINE)
	beam.LightInfluence = 1
	beam.Segments = 1
	beam.Parent = handle
end

-- Recolors the pole for a rod skin
function RodModel.Skin(tool, color, material)
	for _, part in ipairs(tool:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("RodBlank") then
			part.Color = color
			part.Material = material
		end
	end
end

return RodModel
