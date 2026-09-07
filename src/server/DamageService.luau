-- Central damage application (players + Voidspawn). Server only.
-- Respects IFrames, Spirit Guard (frontal melee chip), and stun tags.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DamageService = {}

local function hasIFrames(character: Model): boolean
	return character:GetAttribute(CombatTypes.Tags.IFrames) == true
end

local function isGuarding(character: Model): boolean
	return character:GetAttribute(CombatTypes.Tags.Guarding) == true
end

local function isFrontal(defenderRoot: BasePart, attackOrigin: Vector3?): boolean
	if not attackOrigin then
		return true -- assume frontal if unknown
	end
	local toAttacker = attackOrigin - defenderRoot.Position
	local flat = Vector3.new(toAttacker.X, 0, toAttacker.Z)
	if flat.Magnitude < 0.05 then
		return true
	end
	local look = defenderRoot.CFrame.LookVector
	local lookFlat = Vector3.new(look.X, 0, look.Z)
	if lookFlat.Magnitude < 0.05 then
		return true
	end
	return lookFlat.Unit:Dot(flat.Unit) > 0.15
end

local function getHumanoid(target: Instance): Humanoid?
	if target:IsA("Humanoid") then
		return target
	end
	local model = target:FindFirstAncestorOfClass("Model") or (target:IsA("Model") and target)
	if model then
		return model:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

export type DamageOpts = {
	source: string?,
	attackOrigin: Vector3?,
	skipGuard: boolean?,
}

function DamageService.apply(attacker: Player?, humanoid: Humanoid, amount: number, source: string?, attackOrigin: Vector3?)
	local character = humanoid.Parent
	if not character or not character:IsA("Model") then
		return false
	end
	if humanoid.Health <= 0 then
		return false
	end
	if hasIFrames(character) then
		return false
	end

	-- Stunned Voidspawn still take damage; stunned players do too
	if not Config.FriendlyFire and attacker then
		local victimPlayer = Players:GetPlayerFromCharacter(character)
		if victimPlayer and victimPlayer ~= attacker then
			return false
		end
	end

	local finalAmount = amount
	local blocked = false

	-- Spirit Guard: reduce frontal melee from Voidspawn (and other melee)
	if isGuarding(character) and not (source == "SpiritWave") then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and isFrontal(root, attackOrigin) then
			local isMeleeLike = source == "VoidspawnMelee" or source == "Melee" or source == nil
			if isMeleeLike then
				finalAmount = amount * (Config.GuardDamageMult or 0.25)
				blocked = true
				local victimPlayer = Players:GetPlayerFromCharacter(character)
				if victimPlayer then
					local SpiritPowerService = require(script.Parent.SpiritPowerService)
					local cost = Config.GuardSpiritCostOnBlock or 0
					if cost > 0 then
						SpiritPowerService.trySpend(victimPlayer, cost)
					end
				end
			end
		end
	end

	humanoid:TakeDamage(finalAmount)

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Remotes.get("CombatFX"):FireAllClients({
			kind = if blocked then CombatTypes.Fx.Guard else CombatTypes.Fx.Hit,
			position = root.Position,
			attackerUserId = if attacker then attacker.UserId else nil,
			source = source,
			blocked = blocked,
		})
	end

	if humanoid.Health <= 0 and attacker then
		character:SetAttribute("LastKillerUserId", attacker.UserId)
		character:SetAttribute("LastKillerName", attacker.Name)
		task.delay(Config.KillerTagSeconds, function()
			if character.Parent then
				character:SetAttribute("LastKillerUserId", nil)
				character:SetAttribute("LastKillerName", nil)
			end
		end)
	end

	return true
end

function DamageService.applyStun(character: Model, duration: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return
	end
	character:SetAttribute(CombatTypes.Tags.Stunned, true)
	local prevSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	-- Do not set JumpPower here in a way that fights Voidspawn zero-jump; just freeze move
	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.Stun,
		position = root.Position,
	})
	task.delay(duration, function()
		if character.Parent then
			character:SetAttribute(CombatTypes.Tags.Stunned, false)
			if humanoid.Parent and humanoid.Health > 0 then
				humanoid.WalkSpeed = prevSpeed
			end
		end
	end)
end

function DamageService.applyKnockback(character: Model, direction: Vector3, speed: number)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	flat = flat.Unit
	root.AssemblyLinearVelocity = Vector3.new(
		flat.X * speed,
		math.max(root.AssemblyLinearVelocity.Y, 8),
		flat.Z * speed
	)
end

function DamageService.applyToPart(attacker: Player?, part: BasePart, amount: number, source: string?)
	local humanoid = getHumanoid(part)
	if humanoid then
		if attacker and humanoid.Parent == attacker.Character then
			return false
		end
		return DamageService.apply(attacker, humanoid, amount, source, part.Position)
	end
	return false
end

return DamageService
