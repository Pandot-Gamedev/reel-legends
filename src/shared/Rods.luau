-- Rods are bought with in-game coins only (never Robux).
-- luck: multiplies the chance of Rare and better fish
-- speed: multiplies the wait for a bite (lower is faster)
-- control: reel faster with less line tension during the fight
-- color/material: the rod's blank (the long pole), wrap: the thread bands and
-- reel knob, reel: the reel's body. These are looks only.

local Rods = {}

Rods.List = {
	{ id = "twig", name = "Twig Rod", price = 0, luck = 1.0, speed = 1.0, control = 0.0, color = Color3.fromRGB(140, 100, 60), material = Enum.Material.Wood, wrap = Color3.fromRGB(90, 60, 35), reel = Color3.fromRGB(120, 120, 125) },
	{ id = "bamboo", name = "Bamboo Rod", price = 400, luck = 1.1, speed = 0.95, control = 0.02, color = Color3.fromRGB(190, 180, 90), material = Enum.Material.Wood, wrap = Color3.fromRGB(60, 120, 50), reel = Color3.fromRGB(150, 150, 155) },
	{ id = "fiberglass", name = "Fiberglass Rod", price = 2000, luck = 1.2, speed = 0.9, control = 0.04, color = Color3.fromRGB(230, 230, 230), material = Enum.Material.SmoothPlastic, wrap = Color3.fromRGB(210, 50, 50), reel = Color3.fromRGB(70, 70, 80) },
	{ id = "carbon", name = "Carbon Rod", price = 8000, luck = 1.35, speed = 0.85, control = 0.06, color = Color3.fromRGB(40, 40, 45), material = Enum.Material.SmoothPlastic, wrap = Color3.fromRGB(210, 210, 220), reel = Color3.fromRGB(30, 30, 35) },
	{ id = "mangrove", name = "Mangrove Rod", price = 30000, luck = 1.5, speed = 0.8, control = 0.08, color = Color3.fromRGB(70, 120, 60), material = Enum.Material.SmoothPlastic, wrap = Color3.fromRGB(240, 190, 60), reel = Color3.fromRGB(45, 70, 40) },
	{ id = "glacier", name = "Glacier Rod", price = 120000, luck = 1.75, speed = 0.72, control = 0.1, color = Color3.fromRGB(150, 220, 255), material = Enum.Material.Ice, wrap = Color3.fromRGB(245, 250, 255), reel = Color3.fromRGB(70, 120, 170) },
	{ id = "aurora", name = "Aurora Rod", price = 450000, luck = 2.0, speed = 0.65, control = 0.12, color = Color3.fromRGB(120, 255, 200), material = Enum.Material.SmoothPlastic, wrap = Color3.fromRGB(190, 110, 255), reel = Color3.fromRGB(40, 60, 90) },
	{ id = "leviathan", name = "Leviathan Rod", price = 1500000, luck = 2.5, speed = 0.55, control = 0.15, color = Color3.fromRGB(60, 40, 140), material = Enum.Material.SmoothPlastic, wrap = Color3.fromRGB(255, 200, 40), reel = Color3.fromRGB(25, 15, 50), glow = true, requiresRebirths = 1 },
}

Rods.ById = {}
for index, rod in ipairs(Rods.List) do
	rod.order = index
	Rods.ById[rod.id] = rod
end

Rods.Default = "twig"

return Rods
