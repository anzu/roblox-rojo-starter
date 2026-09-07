-- Server-authoritative Spirit Power meter (regen + spend + gain on hit).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)

local SpiritPowerService = {}

local power: { [Player]: number } = {}
local guarding: { [Player]: boolean } = {}

local function clamp(n: number, lo: number, hi: number): number
	return math.clamp(n, lo, hi)
end

local function push(player: Player)
	local value = power[player] or Config.SpiritPowerMax
	Remotes.get("SpiritPowerChanged"):FireClient(player, value, Config.SpiritPowerMax)
	player:SetAttribute("SpiritPower", value)
end

function SpiritPowerService.get(player: Player): number
	return power[player] or Config.SpiritPowerMax
end

function SpiritPowerService.set(player: Player, value: number)
	power[player] = clamp(value, 0, Config.SpiritPowerMax)
	push(player)
end

function SpiritPowerService.trySpend(player: Player, cost: number): boolean
	if cost <= 0 then
		return true
	end
	local current = SpiritPowerService.get(player)
	if current < cost then
		return false
	end
	SpiritPowerService.set(player, current - cost)
	return true
end

function SpiritPowerService.gain(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	SpiritPowerService.set(player, SpiritPowerService.get(player) + amount)
end

function SpiritPowerService.setGuarding(player: Player, on: boolean)
	guarding[player] = on == true
	local character = player.Character
	if character then
		character:SetAttribute(CombatTypes.Tags.Guarding, on == true)
	end
end

function SpiritPowerService.isGuarding(player: Player): boolean
	return guarding[player] == true
end

function SpiritPowerService.start()
	Players.PlayerAdded:Connect(function(player)
		power[player] = Config.SpiritPowerMax
		guarding[player] = false
		push(player)
		player.CharacterAdded:Connect(function(character)
			character:SetAttribute(CombatTypes.Tags.Guarding, false)
			guarding[player] = false
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		power[player] = nil
		guarding[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		power[player] = Config.SpiritPowerMax
		guarding[player] = false
		push(player)
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		-- Guard Spirit drain every frame while holding
		local drainRate = Config.GuardSpiritDrainPerSecond or 0
		if drainRate > 0 then
			for player, isGuard in guarding do
				if isGuard and player.Parent then
					local current = SpiritPowerService.get(player)
					if current <= (Config.GuardMinSpirit or 1) then
						SpiritPowerService.setGuarding(player, false)
					else
						SpiritPowerService.set(player, current - drainRate * dt)
					end
				end
			end
		end

		acc += dt
		if acc < 0.2 then
			return
		end
		local step = acc
		acc = 0
		local regen = Config.SpiritPowerRegenPerSecond * step
		for player, value in power do
			if player.Parent and value < Config.SpiritPowerMax and not guarding[player] then
				SpiritPowerService.set(player, value + regen)
			end
		end
	end)
end

return SpiritPowerService
