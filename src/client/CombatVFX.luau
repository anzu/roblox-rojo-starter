-- Lightweight client VFX: slash parts, flash-step trail, hit sparks, deny flash.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CombatVFX = {}

local function fadePart(part: BasePart, lifetime: number)
	local tween = TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = part.Size * 1.35,
	})
	tween:Play()
	Debris:AddItem(part, lifetime + 0.05)
end

local function slashFX(payload: any)
	local cf: CFrame = payload.cframe or CFrame.new(payload.position or Vector3.zero)
	local combo = payload.combo or 1

	local slash = Instance.new("Part")
	slash.Name = "SlashFX"
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CanTouch = false
	slash.Material = Enum.Material.Neon
	slash.Color = if combo >= 3 then Color3.fromRGB(180, 230, 255) else Color3.fromRGB(140, 200, 255)
	slash.Size = Vector3.new(0.35, 4 + combo, 6)
	slash.CFrame = cf * CFrame.Angles(0, 0, math.rad(-35 + combo * 20))
	slash.Transparency = 0.15
	slash.Parent = workspace
	fadePart(slash, 0.22)
end

local function flashStepFX(payload: any)
	local startPos: Vector3 = payload.position or Vector3.zero
	local goal: Vector3 = payload.goal or startPos

	local trail = Instance.new("Part")
	trail.Name = "FlashStepTrail"
	trail.Anchored = true
	trail.CanCollide = false
	trail.CanQuery = false
	trail.CanTouch = false
	trail.Material = Enum.Material.Neon
	trail.Color = Color3.fromRGB(200, 220, 255)
	local mid = (startPos + goal) * 0.5
	local dist = (goal - startPos).Magnitude
	trail.Size = Vector3.new(1.2, 1.2, math.max(dist, 1))
	trail.CFrame = CFrame.lookAt(mid, goal)
	trail.Transparency = 0.35
	trail.Parent = workspace
	fadePart(trail, 0.28)

	local ghost = Instance.new("Part")
	ghost.Name = "FlashGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.Size = Vector3.new(2, 5, 1)
	ghost.Material = Enum.Material.ForceField
	ghost.Color = Color3.fromRGB(160, 200, 255)
	ghost.CFrame = CFrame.new(startPos)
	ghost.Transparency = 0.4
	ghost.Parent = workspace
	fadePart(ghost, 0.35)
end

local function spiritWaveHint(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local ring = Instance.new("Part")
	ring.Name = "WaveCast"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(100, 190, 255)
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.2
	ring.Parent = workspace
	fadePart(ring, 0.3)
end

local function hitFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local spark = Instance.new("Part")
	spark.Name = "HitSpark"
	spark.Shape = Enum.PartType.Ball
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.CanTouch = false
	spark.Material = Enum.Material.Neon
	spark.Color = Color3.fromRGB(255, 240, 180)
	spark.Size = Vector3.new(1.2, 1.2, 1.2)
	spark.CFrame = CFrame.new(pos)
	spark.Transparency = 0.1
	spark.Parent = workspace
	fadePart(spark, 0.18)
end

local function deathFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local puff = Instance.new("Part")
	puff.Name = "DeathPuff"
	puff.Shape = Enum.PartType.Ball
	puff.Anchored = true
	puff.CanCollide = false
	puff.CanQuery = false
	puff.CanTouch = false
	puff.Material = Enum.Material.Neon
	puff.Color = Color3.fromRGB(120, 60, 180)
	puff.Size = Vector3.new(2, 2, 2)
	puff.CFrame = CFrame.new(pos)
	puff.Transparency = 0.25
	puff.Parent = workspace
	local tween = TweenService:Create(puff, TweenInfo.new(0.45), {
		Size = Vector3.new(6, 6, 6),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(puff, 0.5)
end

local function denyFX(_payload: any)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local pulse = Instance.new("Part")
	pulse.Name = "DenyFX"
	pulse.Shape = Enum.PartType.Ball
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanQuery = false
	pulse.CanTouch = false
	pulse.Material = Enum.Material.Neon
	pulse.Color = Color3.fromRGB(255, 90, 90)
	pulse.Size = Vector3.new(1.5, 1.5, 1.5)
	pulse.CFrame = CFrame.new(root.Position)
	pulse.Transparency = 0.2
	pulse.Parent = workspace
	fadePart(pulse, 0.25)
end

function CombatVFX.start()
	Remotes.get("CombatFX").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		local kind = payload.kind
		if kind == CombatTypes.Fx.Slash then
			slashFX(payload)
		elseif kind == CombatTypes.Fx.FlashStep then
			flashStepFX(payload)
		elseif kind == CombatTypes.Fx.SpiritWave then
			spiritWaveHint(payload)
		elseif kind == CombatTypes.Fx.Hit then
			hitFX(payload)
		elseif kind == CombatTypes.Fx.Death then
			deathFX(payload)
		elseif kind == CombatTypes.Fx.Deny then
			denyFX(payload)
		end
		-- Sheath FX is visual via welded blade; no extra VFX needed
	end)
end

return CombatVFX
