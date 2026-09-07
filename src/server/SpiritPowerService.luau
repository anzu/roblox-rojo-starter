-- Server-authoritative Spirit Power meter (regen + spend).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SpiritPowerService = {}

local power: { [Player]: number } = {}

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

function SpiritPowerService.start()
	Players.PlayerAdded:Connect(function(player)
		power[player] = Config.SpiritPowerMax
		push(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		power[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		power[player] = Config.SpiritPowerMax
		push(player)
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		local step = acc
		acc = 0
		local regen = Config.SpiritPowerRegenPerSecond * step
		for player, value in power do
			if player.Parent and value < Config.SpiritPowerMax then
				SpiritPowerService.set(player, value + regen)
			end
		end
	end)
end

return SpiritPowerService
