-- Spirit Blade client bootstrap: UI, hotbar, input, VFX, sprint, camera lock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

Remotes.init()

local SpiritUI = require(script.SpiritUI)
local InputController = require(script.InputController)
local AbilityHotbar = require(script.AbilityHotbar)
local CombatVFX = require(script.CombatVFX)
local CameraLock = require(script.CameraLock)
local SprintController = require(script.SprintController)
local ArmAnimator = require(script.ArmAnimator)

ArmAnimator.start()
SpiritUI.start()
InputController.start()
AbilityHotbar.start()
CombatVFX.start()
CameraLock.start()
SprintController.start()

print(string.format(
	"[%s] Client ready. E sheath · M1 sword · Shift sprint · Ctrl lock · F guard · hotbar 1/2/3",
	Config.GameName
))
