-- Server-authoritative melee / flash step / spirit wave.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DamageService = require(script.Parent.DamageService)
local SpiritPowerService = require(script.Parent.SpiritPowerService)
local SwordService = require(script.Parent.SwordService)

local CombatService = {}

type ComboState = {
	index: number,
	lastSwing: number,
	meleeReadyAt: number,
	flashReadyAt: number,
	waveReadyAt: number,
}

local state: { [Player]: ComboState } = {}

local function now(): number
	return os.clock()
end

local function getState(player: Player): ComboState
	local s = state[player]
	if not s then
		s = {
			index = 0,
			lastSwing = 0,
			meleeReadyAt = 0,
			flashReadyAt = 0,
			waveReadyAt = 0,
		}
		state[player] = s
	end
	return s
end

local function getRoot(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function setIFrames(character: Model, duration: number)
	character:SetAttribute(CombatTypes.Tags.IFrames, true)
	task.delay(duration, function()
		if character.Parent then
			character:SetAttribute(CombatTypes.Tags.IFrames, false)
		end
	end)
end

local function lookCFrame(root: BasePart): CFrame
	local look = root.CFrame.LookVector
	look = Vector3.new(look.X, 0, look.Z)
	if look.Magnitude < 0.05 then
		look = Vector3.new(0, 0, -1)
	else
		look = look.Unit
	end
	return CFrame.lookAt(root.Position, root.Position + look)
end

local function deny(player: Player, reason: string?)
	Remotes.get("CombatFX"):FireClient(player, {
		kind = CombatTypes.Fx.Deny,
		reason = reason or "Not enough Spirit Power",
	})
end

function CombatService.handleMelee(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = getRoot(character)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local s = getState(player)
	local t = now()
	if t < s.meleeReadyAt then
		return
	end

	-- Auto-unsheath on first M1 when sheathed
	SwordService.ensureUnsheathed(character)

	if not SpiritPowerService.trySpend(player, Config.MeleeSpiritCost) then
		deny(player, "Not enough Spirit Power")
		return
	end

	if t - s.lastSwing > Config.MeleeComboReset then
		s.index = 0
	end
	s.index = (s.index % Config.MeleeComboMax) + 1
	s.lastSwing = t
	s.meleeReadyAt = t + Config.MeleeCooldown

	local damage = Config.MeleeDamage[s.index] or Config.MeleeDamage[1]
	local cf = lookCFrame(root)
	local hitCenter = cf.Position + cf.LookVector * (Config.MeleeHitboxSize.Z * 0.5 + 1)

	-- Soft lunge so swing animation reads (not a teleport-slide)
	root.AssemblyLinearVelocity = Vector3.new(
		cf.LookVector.X * Config.MeleeLungeSpeed,
		root.AssemblyLinearVelocity.Y,
		cf.LookVector.Z * Config.MeleeLungeSpeed
	)

	-- FX first so clients start the arm/sword swing immediately
	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.Slash,
		position = hitCenter,
		cframe = cf + cf.LookVector * 3,
		combo = s.index,
		userId = player.UserId,
	})

	local hitDelay = Config.MeleeHitDelay or 0.12
	task.delay(hitDelay, function()
		if not character.Parent then
			return
		end
		local humNow = character:FindFirstChildOfClass("Humanoid")
		if not humNow or humNow.Health <= 0 then
			return
		end
		local rootNow = getRoot(character)
		if not rootNow then
			return
		end
		local cfNow = lookCFrame(rootNow)
		local center = cfNow.Position + cfNow.LookVector * (Config.MeleeHitboxSize.Z * 0.5 + 1)

		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = { character }

		local parts = workspace:GetPartBoundsInBox(
			CFrame.new(center) * (cfNow - cfNow.Position),
			Config.MeleeHitboxSize,
			overlap
		)

		local hitModels: { [Model]: boolean } = {}
		for _, part in parts do
			local model = part:FindFirstAncestorOfClass("Model")
			if model and not hitModels[model] then
				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hitModels[model] = true
					DamageService.apply(player, hum, damage, "Melee")
				end
			end
		end
	end)
end

local function dashDirection(humanoid: Humanoid, root: BasePart): Vector3
	-- Prefer MoveDirection for controllable dashes; fall back to look
	local move = humanoid.MoveDirection
	if move.Magnitude > 0.1 then
		local flat = Vector3.new(move.X, 0, move.Z)
		if flat.Magnitude > 0.05 then
			return flat.Unit
		end
	end
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.05 then
		return Vector3.new(0, 0, -1)
	end
	return flatLook.Unit
end

function CombatService.handleFlashStep(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = getRoot(character)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local s = getState(player)
	local t = now()
	if t < s.flashReadyAt then
		return
	end
	if not SpiritPowerService.trySpend(player, Config.FlashStepCost) then
		deny(player, "Not enough Spirit Power")
		return
	end
	s.flashReadyAt = t + Config.FlashStepCooldown

	local direction = dashDirection(humanoid, root)
	local cf = CFrame.lookAt(root.Position, root.Position + direction)
	local distance = Config.FlashStepDistance

	-- Raycast to avoid clipping into walls
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(root.Position, direction * distance, rayParams)
	if hit then
		distance = math.max(0, hit.Distance - 2)
	end

	setIFrames(character, Config.FlashStepIFrames)

	local startPos = root.Position
	local goal = startPos + direction * distance
	local goalCF = CFrame.new(goal) * (cf - cf.Position)

	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.FlashStep,
		position = startPos,
		goal = goal,
		userId = player.UserId,
	})

	-- Reliable teleport: PivotTo preferred, fallback CFrame
	if character.PrimaryPart then
		character:PivotTo(goalCF)
	else
		root.CFrame = goalCF
	end

	local dashSpeed = distance / math.max(Config.FlashStepDuration, 0.05)
	root.AssemblyLinearVelocity = direction * dashSpeed
	task.delay(Config.FlashStepDuration, function()
		if root.Parent then
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X * 0.2, v.Y, v.Z * 0.2)
		end
	end)
end

function CombatService.handleSpiritWave(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = getRoot(character)
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end

	local s = getState(player)
	local t = now()
	if t < s.waveReadyAt then
		return
	end
	if not SpiritPowerService.trySpend(player, Config.SpiritWaveCost) then
		deny(player, "Not enough Spirit Power")
		return
	end
	s.waveReadyAt = t + Config.SpiritWaveCooldown

	local cf = lookCFrame(root)
	local spawnPos = root.Position + cf.LookVector * 4 + Vector3.new(0, 1, 0)

	local part = Instance.new("Part")
	part.Name = "SpiritWave"
	part.Size = Config.SpiritWaveSize
	part.Shape = Enum.PartType.Block
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(120, 200, 255)
	part.CanCollide = false
	part.Anchored = false
	part.Massless = true
	part.CFrame = CFrame.lookAt(spawnPos, spawnPos + cf.LookVector)
	part.Parent = workspace

	CollectionService:AddTag(part, CombatTypes.Tags.SpiritProjectile)

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.MaxForce = math.huge
	lv.VectorVelocity = cf.LookVector * Config.SpiritWaveSpeed
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = part

	local angular = Instance.new("AngularVelocity")
	angular.Attachment0 = attachment
	angular.AngularVelocity = Vector3.new(0, 12, 0)
	angular.MaxTorque = math.huge
	angular.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	angular.Parent = part

	Debris:AddItem(part, Config.SpiritWaveLifetime)

	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.SpiritWave,
		position = spawnPos,
		look = cf.LookVector,
		userId = player.UserId,
	})

	local hitSet: { [Model]: boolean } = {}
	part.Touched:Connect(function(other)
		if not other:IsA("BasePart") then
			return
		end
		local model = other:FindFirstAncestorOfClass("Model")
		if not model or hitSet[model] or model == character then
			return
		end
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			hitSet[model] = true
			DamageService.apply(player, hum, Config.SpiritWaveDamage, "SpiritWave")
		end
	end)
end

function CombatService.start()
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)

	Remotes.get("RequestMelee").OnServerEvent:Connect(function(player)
		CombatService.handleMelee(player)
	end)
	Remotes.get("RequestFlashStep").OnServerEvent:Connect(function(player)
		CombatService.handleFlashStep(player)
	end)
	Remotes.get("RequestSpiritWave").OnServerEvent:Connect(function(player)
		CombatService.handleSpiritWave(player)
	end)
end

return CombatService
