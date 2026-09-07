-- Spirit Blade server bootstrap: remotes, spirit power, sword, combat, Voidspawn PvE.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SpiritPowerService = require(script.SpiritPowerService)
local SwordService = require(script.SwordService)
local CombatService = require(script.CombatService)
local VoidspawnService = require(script.VoidspawnService)

Remotes.init()
SpiritPowerService.start()
SwordService.start()
CombatService.start()
VoidspawnService.start()

print(string.format("[%s] Server combat systems online.", Config.GameName))
