-- Spirit Blade client bootstrap: UI, input, VFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- Wait for server remotes
Remotes.init()

local SpiritUI = require(script.SpiritUI)
local InputController = require(script.InputController)
local CombatVFX = require(script.CombatVFX)

SpiritUI.start()
InputController.start()
CombatVFX.start()

print(string.format("[%s] Client ready. E sheath · M1 slash · 1 flash · 2 wave", Config.GameName))
