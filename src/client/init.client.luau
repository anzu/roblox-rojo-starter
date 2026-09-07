-- Spirit Blade client bootstrap: UI, hotbar, input, VFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

Remotes.init()

local SpiritUI = require(script.SpiritUI)
local AbilityHotbar = require(script.AbilityHotbar)
local InputController = require(script.InputController)
local CombatVFX = require(script.CombatVFX)

SpiritUI.start()
AbilityHotbar.start()
InputController.start()
CombatVFX.start()

print(string.format("[%s] Client ready. E sheath · M1 sword · hotbar 1/2 abilities", Config.GameName))
