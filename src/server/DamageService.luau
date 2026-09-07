-- Central damage application (players + Voidspawn). Server only.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local DamageService = {}

local function hasIFrames(character: Model): boolean
	return character:GetAttribute(CombatTypes.Tags.IFrames) == true
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

function DamageService.apply(attacker: Player?, humanoid: Humanoid, amount: number, source: string?)
	local character = humanoid.Parent
	if not character or not character:IsA("Model") then
		return
	end
	if humanoid.Health <= 0 then
		return
	end
	if hasIFrames(character) then
		return
	end

	-- Optional friendly-fire gate (on for v1 sandbox)
	if not Config.FriendlyFire and attacker then
		local victimPlayer = Players:GetPlayerFromCharacter(character)
		if victimPlayer and victimPlayer ~= attacker then
			-- still allow; FriendlyFire true means we damage. When false, skip other players.
			return
		end
	end

	humanoid:TakeDamage(amount)

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		Remotes.get("CombatFX"):FireAllClients({
			kind = CombatTypes.Fx.Hit,
			position = root.Position,
			attackerUserId = if attacker then attacker.UserId else nil,
			source = source,
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
end

function DamageService.applyToPart(attacker: Player?, part: BasePart, amount: number, source: string?)
	local humanoid = getHumanoid(part)
	if humanoid then
		-- Don't damage self
		if attacker and humanoid.Parent == attacker.Character then
			return
		end
		DamageService.apply(attacker, humanoid, amount, source)
	end
end

return DamageService
