-- Spawns Voidspawn NPCs near world spawn; aggro-radius AI + melee; respawn after death.
-- Stays on ground (no jump/climb onto player). Standoff melee ring. Ignores players during grace.

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
local playerGraceUntil: { [Player]: number } = {}
local globalGraceUntil = 0

local function now(): number
	return os.clock()
end

local function grantPlayerGrace(player: Player)
	local grace = Config.VoidspawnPlayerGraceSeconds or 6
	playerGraceUntil[player] = now() + grace
end

local function isPlayerInGrace(player: Player): boolean
	if now() < globalGraceUntil then
		return true
	end
	local untilTime = playerGraceUntil[player]
	return typeof(untilTime) == "number" and now() < untilTime
end

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
	humanoid.WalkSpeed = Config.VoidspawnIdleWalkSpeed
	humanoid.HipHeight = 2
	humanoid.AutoRotate = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
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

local function nearestPlayerRoot(fromPos: Vector3): (Player?, BasePart?, number)
	local bestPlayer: Player? = nil
	local bestRoot: BasePart? = nil
	local bestDist = math.huge
	for _, player in Players:GetPlayers() do
		if not isPlayerInGrace(player) then
			local character = player.Character
			if character then
				local hum = character:FindFirstChildOfClass("Humanoid")
				local root = character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and root and root:IsA("BasePart") then
					local offset = root.Position - fromPos
					local d = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if d < bestDist then
						bestDist = d
						bestPlayer = player
						bestRoot = root
					end
				end
			end
		end
	end
	return bestPlayer, bestRoot, bestDist
end

-- Flatten to NPC Y; offset away from player by standoff along NPC→player vector.
local function standoffGoal(npcRoot: BasePart, playerRoot: BasePart): Vector3
	local standoff = Config.VoidspawnStandoff or 5.5
	local npcPos = npcRoot.Position
	local playerPos = playerRoot.Position
	local flat = Vector3.new(playerPos.X - npcPos.X, 0, playerPos.Z - npcPos.Z)
	local dist = flat.Magnitude
	local dir: Vector3
	if dist < 0.05 then
		dir = Vector3.new(0, 0, -1)
	else
		dir = flat.Unit
	end
	-- Goal = player position flattened to NPC Y, then back away by standoff
	local groundPlayer = Vector3.new(playerPos.X, npcPos.Y, playerPos.Z)
	return groundPlayer - dir * standoff
end

local function backupGoal(npcRoot: BasePart, playerRoot: BasePart): Vector3
	local npcPos = npcRoot.Position
	local playerPos = playerRoot.Position
	local flat = Vector3.new(npcPos.X - playerPos.X, 0, npcPos.Z - playerPos.Z)
	if flat.Magnitude < 0.05 then
		-- Strafe sideways if overlapping
		local look = npcRoot.CFrame.RightVector
		flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.05 then
			flat = Vector3.new(1, 0, 0)
		end
	end
	flat = flat.Unit
	local standoff = Config.VoidspawnStandoff or 5.5
	return Vector3.new(playerPos.X, npcPos.Y, playerPos.Z) + flat * standoff
end

local function horizontalDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function isFacing(npcRoot: BasePart, targetPos: Vector3): boolean
	local flat = Vector3.new(targetPos.X - npcRoot.Position.X, 0, targetPos.Z - npcRoot.Position.Z)
	if flat.Magnitude < 0.05 then
		return true
	end
	local look = npcRoot.CFrame.LookVector
	local lookFlat = Vector3.new(look.X, 0, look.Z)
	if lookFlat.Magnitude < 0.05 then
		return false
	end
	return lookFlat.Unit:Dot(flat.Unit) >= (Config.VoidspawnFacingDot or 0.35)
end

local function runAI(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end

	-- Enforce no-jump every think (stun restore shouldn't re-enable jump)
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0

	local lastAttack = 0
	local aggroRoot: BasePart? = nil
	local idleAnchor = root.Position
	local nextPatrolAt = 0

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0

			-- Skip movement orders while stunned
			local stunned = model:GetAttribute(CombatTypes.Tags.Stunned) == true

			local _, nearestRoot, nearestDist = nearestPlayerRoot(root.Position)

			if aggroRoot then
				if not aggroRoot.Parent then
					aggroRoot = nil
				else
					local targetModel = aggroRoot.Parent
					local aggroHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")
					local aggroPlayer = if targetModel and targetModel:IsA("Model")
						then Players:GetPlayerFromCharacter(targetModel)
						else nil
					if not aggroHum or aggroHum.Health <= 0 then
						aggroRoot = nil
					elseif aggroPlayer and isPlayerInGrace(aggroPlayer) then
						aggroRoot = nil
					else
						local d = horizontalDist(aggroRoot.Position, root.Position)
						if d > Config.VoidspawnDeaggroRadius then
							aggroRoot = nil
						end
					end
				end
			end

			if not aggroRoot and nearestRoot and nearestDist <= Config.VoidspawnAggroRadius then
				aggroRoot = nearestRoot
			end

			if not stunned then
				if aggroRoot then
					humanoid.WalkSpeed = Config.VoidspawnWalkSpeed
					local dist = horizontalDist(aggroRoot.Position, root.Position)
					local tooClose = Config.VoidspawnTooClose or 3
					local meleeRange = Config.VoidspawnMeleeRange or 5.5

					if dist < tooClose then
						-- Back up / strafe — don't walk into torso/head
						humanoid:MoveTo(backupGoal(root, aggroRoot))
					elseif dist > meleeRange then
						-- Approach standoff ring (never enter player AABB center)
						humanoid:MoveTo(standoffGoal(root, aggroRoot))
					else
						-- In melee ring: face player, hold position
						local face = Vector3.new(aggroRoot.Position.X, root.Position.Y, aggroRoot.Position.Z)
						root.CFrame = CFrame.lookAt(root.Position, face)
						humanoid:MoveTo(root.Position)
					end

					-- Attack only in horizontal melee range while facing
					if dist <= meleeRange and dist >= (tooClose * 0.5) and isFacing(root, aggroRoot.Position) then
						local t = now()
						if t - lastAttack >= Config.VoidspawnAttackCooldown then
							lastAttack = t
							local targetModel = aggroRoot.Parent
							if targetModel and targetModel:IsA("Model") then
								local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
								if targetHum then
									Remotes.get("CombatFX"):FireAllClients({
										kind = CombatTypes.Fx.Slash,
										position = root.Position + root.CFrame.LookVector * 2,
										cframe = root.CFrame,
										combo = 1,
										userId = nil,
									})
									DamageService.apply(nil, targetHum, Config.VoidspawnDamage, "VoidspawnMelee", root.Position)
								end
							end
						end
					end
				else
					humanoid.WalkSpeed = Config.VoidspawnIdleWalkSpeed
					local t = now()
					if t >= nextPatrolAt then
						nextPatrolAt = t + (3 + math.random() * 4)
						local offset = randomOffset(6)
						humanoid:MoveTo(Vector3.new(idleAnchor.X + offset.X, root.Position.Y, idleAnchor.Z + offset.Z))
					end
				end
			end -- not stunned

			task.wait(Config.VoidspawnThinkInterval)
		end
	end)

	humanoid.Died:Once(function()
		Remotes.get("CombatFX"):FireAllClients({
			kind = CombatTypes.Fx.Death,
			position = root.Position,
		})
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
	pos = Vector3.new(pos.X, origin.Y + 3, pos.Z)
	local model = createVoidspawnModel(pos)
	table.insert(active, model)
	runAI(model)
	return model
end

function VoidspawnService.start()
	local spawnDelay = Config.VoidspawnSpawnDelay or 4
	local grace = Config.VoidspawnPlayerGraceSeconds or 6
	globalGraceUntil = now() + math.max(spawnDelay, grace)

	local function hookPlayer(player: Player)
		grantPlayerGrace(player)
		player.CharacterAdded:Connect(function()
			grantPlayerGrace(player)
		end)
	end

	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		playerGraceUntil[player] = nil
	end)

	task.defer(function()
		task.wait(spawnDelay)
		for _ = 1, Config.VoidspawnCount do
			VoidspawnService.spawnOne()
			task.wait(0.15)
		end
	end)
end

return VoidspawnService
