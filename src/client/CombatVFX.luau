-- Lightweight client VFX: Transform swing (via SwingController), flash-step, hits, guard.
-- Floating SlashFX part removed — blade trail is enough.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwingController = require(script.Parent.SwingController)

local CombatVFX = {}

local function fadePart(part: BasePart, lifetime: number)
	local tween = TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = part.Size * 1.35,
	})
	tween:Play()
	Debris:AddItem(part, lifetime + 0.05)
end

local function characterFromUserId(userId: number?): Model?
	if typeof(userId) ~= "number" then
		return nil
	end
	for _, player in Players:GetPlayers() do
		if player.UserId == userId then
			return player.Character
		end
	end
	return nil
end

local function slashFX(payload: any)
	local combo = payload.combo or 1
	local localPlayer = Players.LocalPlayer
	local character = characterFromUserId(payload.userId)
	if not character and payload.userId == localPlayer.UserId then
		character = localPlayer.Character
	end

	if character then
		if character == localPlayer.Character then
			if not SwingController.isPlaying(character) then
				SwingController.play(character, combo)
			end
		else
			SwingController.play(character, combo)
		end
	end
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
	trail.Material = Enum.Material.ForceField
	trail.Color = Color3.fromRGB(180, 200, 230)
	local mid = (startPos + goal) * 0.5
	local dist = (goal - startPos).Magnitude
	trail.Size = Vector3.new(1.0, 1.0, math.max(dist, 1))
	trail.CFrame = CFrame.lookAt(mid, goal)
	trail.Transparency = 0.45
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
	ghost.Color = Color3.fromRGB(160, 190, 230)
	ghost.CFrame = CFrame.new(startPos)
	ghost.Transparency = 0.5
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
	ring.Material = Enum.Material.ForceField
	ring.Color = Color3.fromRGB(120, 170, 220)
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.35
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
	spark.Material = Enum.Material.SmoothPlastic
	spark.Color = Color3.fromRGB(255, 230, 160)
	spark.Size = Vector3.new(1.0, 1.0, 1.0)
	spark.CFrame = CFrame.new(pos)
	spark.Transparency = 0.2
	spark.Parent = workspace
	fadePart(spark, 0.18)
end

local function guardFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	if payload.active and not payload.position then
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			pos = root.Position
		end
	end
	local shield = Instance.new("Part")
	shield.Name = "GuardFX"
	shield.Shape = Enum.PartType.Ball
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanQuery = false
	shield.CanTouch = false
	shield.Material = Enum.Material.ForceField
	shield.Color = Color3.fromRGB(140, 220, 160)
	shield.Size = Vector3.new(2.2, 2.2, 2.2)
	shield.CFrame = CFrame.new(pos)
	shield.Transparency = 0.35
	shield.Parent = workspace
	fadePart(shield, 0.22)
end

local function stunFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local ring = Instance.new("Part")
	ring.Name = "StunFX"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.ForceField
	ring.Color = Color3.fromRGB(255, 220, 100)
	ring.Size = Vector3.new(0.3, 3.5, 3.5)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.3
	ring.Parent = workspace
	fadePart(ring, 0.4)
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
	puff.Material = Enum.Material.ForceField
	puff.Color = Color3.fromRGB(120, 60, 180)
	puff.Size = Vector3.new(2, 2, 2)
	puff.CFrame = CFrame.new(pos)
	puff.Transparency = 0.3
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
	pulse.Material = Enum.Material.SmoothPlastic
	pulse.Color = Color3.fromRGB(255, 90, 90)
	pulse.Size = Vector3.new(1.5, 1.5, 1.5)
	pulse.CFrame = CFrame.new(root.Position)
	pulse.Transparency = 0.25
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
		elseif kind == CombatTypes.Fx.Guard then
			guardFX(payload)
		elseif kind == CombatTypes.Fx.Stun then
			stunFX(payload)
		elseif kind == CombatTypes.Fx.Death then
			deathFX(payload)
		elseif kind == CombatTypes.Fx.Deny then
			denyFX(payload)
		end
	end)
end

return CombatVFX
