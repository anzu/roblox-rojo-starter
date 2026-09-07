-- Spawns Voidspawn NPCs near world spawn; simple MoveTo AI + melee; respawn after death.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DamageService = require(script.Parent.DamageService)

local VoidspawnService = {}

local active: { Model } = {}

local function getSpawnOrigin(): Vector3
	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation and spawnLocation:IsA("BasePart") then
		return spawnLocation.Position
	end
	return Vector3.new(0, 5, 0)
end

local function randomOffset(radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local dist = radius * (0.45 + math.random() * 0.55)
	return Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function createVoidspawnModel(position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Voidspawn"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = false
	root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	root.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(35, 35, 45)
	torso.Material = Enum.Material.SmoothPlastic
	torso.CFrame = root.CFrame
	torso.CanCollide = true
	torso.Parent = model
	weld(root, torso)

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.4, 1.4, 1.4)
	head.Color = Color3.fromRGB(20, 20, 28)
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0)
	head.CanCollide = false
	head.Parent = model
	weld(root, head)

	-- Mask plate (void vibe)
	local mask = Instance.new("Part")
	mask.Name = "Mask"
	mask.Size = Vector3.new(1.1, 0.9, 0.2)
	mask.Color = Color3.fromRGB(230, 230, 235)
	mask.Material = Enum.Material.SmoothPlastic
	mask.CFrame = head.CFrame * CFrame.new(0, 0, -0.65)
	mask.CanCollide = false
	mask.Parent = model
	weld(head, mask)

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Color = Color3.fromRGB(45, 30, 55)
	leftArm.CFrame = root.CFrame * CFrame.new(-1.5, 0, 0)
	leftArm.CanCollide = false
	leftArm.Parent = model
	weld(root, leftArm)

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Color = Color3.fromRGB(45, 30, 55)
	rightArm.CFrame = root.CFrame * CFrame.new(1.5, 0, 0)
	rightArm.CanCollide = false
	rightArm.Parent = model
	weld(root, rightArm)

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = Color3.fromRGB(25, 25, 35)
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.5, -2, 0)
	leftLeg.CanCollide = false
	leftLeg.Parent = model
	weld(root, leftLeg)

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = Color3.fromRGB(25, 25, 35)
	rightLeg.CFrame = root.CFrame * CFrame.new(0.5, -2, 0)
	rightLeg.CanCollide = false
	rightLeg.Parent = model
	weld(root, rightLeg)

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.VoidspawnHealth
	humanoid.Health = Config.VoidspawnHealth
	humanoid.WalkSpeed = Config.VoidspawnWalkSpeed
	humanoid.HipHeight = 2
	humanoid.AutoRotate = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "VoidspawnLabel"
	billboard.Size = UDim2.fromOffset(120, 28)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Voidspawn"
	label.TextColor3 = Color3.fromRGB(200, 160, 255)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	model.PrimaryPart = root
	CollectionService:AddTag(model, CombatTypes.Tags.Voidspawn)
	model.Parent = workspace

	return model
end

local function nearestPlayerRoot(fromPos: Vector3): (Player?, BasePart?)
	local bestPlayer: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDist = math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local hum = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and root and root:IsA("BasePart") then
				local d = (root.Position - fromPos).Magnitude
				if d < bestDist then
					bestDist = d
					bestPlayer = player
					bestRoot = root
				end
			end
		end
	end
	return bestPlayer, bestRoot
end

local function runAI(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end

	local lastAttack = 0

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local _, targetRoot = nearestPlayerRoot(root.Position)
			if targetRoot then
				local dist = (targetRoot.Position - root.Position).Magnitude
				humanoid:MoveTo(targetRoot.Position)

				if dist <= Config.VoidspawnMeleeRange then
					local t = os.clock()
					if t - lastAttack >= Config.VoidspawnAttackCooldown then
						lastAttack = t
						local targetModel = targetRoot.Parent
						if targetModel and targetModel:IsA("Model") then
							local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
							if targetHum then
								-- Brief claw flash
								Remotes.get("CombatFX"):FireAllClients({
									kind = CombatTypes.Fx.Slash,
									position = root.Position + root.CFrame.LookVector * 2,
									cframe = root.CFrame,
									combo = 1,
									userId = nil,
								})
								DamageService.apply(nil, targetHum, Config.VoidspawnDamage, "VoidspawnMelee")
							end
						end
					end
				end
			end
			task.wait(Config.VoidspawnThinkInterval)
		end
	end)

	humanoid.Died:Once(function()
		Remotes.get("CombatFX"):FireAllClients({
			kind = CombatTypes.Fx.Death,
			position = root.Position,
		})
		-- Remove from active list
		for i = #active, 1, -1 do
			if active[i] == model then
				table.remove(active, i)
			end
		end
		Debris:AddItem(model, 2)
		task.delay(Config.VoidspawnRespawnDelay, function()
			VoidspawnService.spawnOne()
		end)
	end)
end

function VoidspawnService.spawnOne()
	local origin = getSpawnOrigin()
	local pos = origin + randomOffset(Config.VoidspawnSpawnRadius)
	-- Keep above ground roughly
	pos = Vector3.new(pos.X, origin.Y + 3, pos.Z)
	local model = createVoidspawnModel(pos)
	table.insert(active, model)
	runAI(model)
	return model
end

function VoidspawnService.start()
	task.defer(function()
		-- Wait a moment for baseplate/spawn to exist
		task.wait(1)
		for _ = 1, Config.VoidspawnCount do
			VoidspawnService.spawnOne()
			task.wait(0.15)
		end
	end)
end

return VoidspawnService
