-- Server-authoritative melee / flash step / spirit wave / spirit guard.

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

local function flatLookFromRoot(root: BasePart): Vector3
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

-- Prefer SpiritBlade Blade world position; else root look box in front.
local function meleeHitboxCFrame(character: Model, root: BasePart): CFrame
	local flat = flatLookFromRoot(root)
	local katana = character:FindFirstChild("SpiritBlade")
	if katana and katana:IsA("Model") then
		local blade = katana:FindFirstChild("Blade")
		if blade and blade:IsA("BasePart") and blade.Transparency < 1 then
			local center = blade.Position + flat * (Config.MeleeHitboxSize.Z * 0.2)
			return CFrame.lookAt(center, center + flat)
		end
	end
	local origin = root.Position + Vector3.new(0, 0.5, 0)
	local center = origin + flat * (Config.MeleeHitboxSize.Z * 0.45 + 1)
	return CFrame.lookAt(center, center + flat)
end

local function inForwardCone(origin: Vector3, lookFlat: Vector3, targetPos: Vector3, range: number, coneDeg: number): boolean
	local offset = targetPos - origin
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local dist = flat.Magnitude
	if dist > range or dist < 0.01 then
		return false
	end
	local coneCos = math.cos(math.rad(coneDeg))
	return lookFlat:Dot(flat.Unit) >= coneCos
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

	-- Can't melee while guarding
	if SpiritPowerService.isGuarding(player) then
		return
	end

	local s = getState(player)
	local t = now()
	if t < s.meleeReadyAt then
		return
	end

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
	local comboIndex = s.index
	local cf = lookCFrame(root)
	local hitCF = meleeHitboxCFrame(character, root)

	-- Soft lunge — never freeze WalkSpeed / MoveDirection
	root.AssemblyLinearVelocity = Vector3.new(
		cf.LookVector.X * Config.MeleeLungeSpeed,
		root.AssemblyLinearVelocity.Y,
		cf.LookVector.Z * Config.MeleeLungeSpeed
	)

	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.Slash,
		position = hitCF.Position,
		cframe = hitCF,
		combo = comboIndex,
		userId = player.UserId,
	})

	local hitDelay = Config.MeleeHitDelay or 0.18
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

		local lookFlat = flatLookFromRoot(rootNow)
		local boxCF = meleeHitboxCFrame(character, rootNow)

		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = { character }

		local parts = workspace:GetPartBoundsInBox(boxCF, Config.MeleeHitboxSize, overlap)
		local radius = math.max(Config.MeleeHitboxSize.X, Config.MeleeHitboxSize.Z) * 0.5
		local sphereParts = workspace:GetPartBoundsInRadius(boxCF.Position, radius, overlap)

		-- Also query near the blade tip
		local bladeParts: { BasePart } = {}
		local katana = character:FindFirstChild("SpiritBlade")
		if katana then
			local blade = katana:FindFirstChild("Blade")
			if blade and blade:IsA("BasePart") and blade.Transparency < 1 then
				bladeParts = workspace:GetPartBoundsInRadius(blade.Position, 4.5, overlap)
			end
		end

		local hitModels: { [Model]: boolean } = {}
		local function consider(part: BasePart)
			local model = part:FindFirstAncestorOfClass("Model")
			if model and not hitModels[model] then
				local hum = model:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hitModels[model] = true
				end
			end
		end
		for _, part in parts do
			consider(part)
		end
		for _, part in sphereParts do
			consider(part)
		end
		for _, part in bladeParts do
			consider(part)
		end

		-- Magnet: Voidspawn within MeleeMagnetRange inside forward cone count as hits
		local magnetRange = Config.MeleeMagnetRange or 10
		local coneDeg = Config.MeleeConeAngleDeg or 70
		for _, model in CollectionService:GetTagged(CombatTypes.Tags.Voidspawn) do
			if model:IsA("Model") and not hitModels[model] then
				local hum = model:FindFirstChildOfClass("Humanoid")
				local targetRoot = model:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
					if inForwardCone(rootNow.Position, lookFlat, targetRoot.Position, magnetRange, coneDeg) then
						hitModels[model] = true
					end
				end
			end
		end

		local anyHit = false
		for model, _ in hitModels do
			local hum = model:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				local applied = DamageService.apply(player, hum, damage, "Melee", rootNow.Position)
				if applied then
					anyHit = true
					-- Zanjutsu finisher: hit 3 knockback + brief stun on Voidspawn
					if comboIndex >= Config.MeleeComboMax and CollectionService:HasTag(model, CombatTypes.Tags.Voidspawn) then
						local targetRoot = model:FindFirstChild("HumanoidRootPart")
						if targetRoot and targetRoot:IsA("BasePart") then
							local dir = targetRoot.Position - rootNow.Position
							DamageService.applyKnockback(model, dir, Config.MeleeFinisherKnockback or 28)
							DamageService.applyStun(model, Config.MeleeFinisherStunSeconds or 0.65)
						end
					end
				end
			end
		end

		if anyHit then
			local gain = Config.MeleeSpiritGainOnHit or 0
			if gain > 0 then
				SpiritPowerService.gain(player, gain)
			end
		end
	end)
end

local function dashDirection(humanoid: Humanoid, root: BasePart): Vector3
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

	if SpiritPowerService.isGuarding(player) then
		SpiritPowerService.setGuarding(player, false)
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
			DamageService.apply(player, hum, Config.SpiritWaveDamage, "SpiritWave", part.Position)
		end
	end)
end

function CombatService.handleGuard(player: Player, on: boolean)
	local character = player.Character
	if not character then
		SpiritPowerService.setGuarding(player, false)
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		SpiritPowerService.setGuarding(player, false)
		return
	end

	if on then
		local current = SpiritPowerService.get(player)
		if current < (Config.GuardMinSpirit or 1) then
			deny(player, "Not enough Spirit Power")
			SpiritPowerService.setGuarding(player, false)
			return
		end
		SpiritPowerService.setGuarding(player, true)
		Remotes.get("CombatFX"):FireClient(player, {
			kind = CombatTypes.Fx.Guard,
			active = true,
		})
	else
		SpiritPowerService.setGuarding(player, false)
	end
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
	Remotes.get("RequestGuard").OnServerEvent:Connect(function(player, on)
		CombatService.handleGuard(player, on == true)
	end)
end

return CombatService
