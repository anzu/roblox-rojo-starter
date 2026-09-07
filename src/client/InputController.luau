-- Combat input: M1 = sword attack (auto-unsheath), E = sheath toggle, F = Spirit Guard hold.
-- Local swing starts immediately; server remains authoritative for damage.
-- Flash Step (via hotbar) can cancel late-swing recovery for combat feel.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local ArmAnimator = require(script.Parent.ArmAnimator)

local InputController = {}

local localCombo = 0
local lastLocalSwing = 0
local guarding = false

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function setGuard(on: boolean)
	if guarding == on then
		return
	end
	guarding = on
	local character = Players.LocalPlayer.Character
	if character then
		ArmAnimator.setGuarding(character, on)
	end
	Remotes.get("RequestGuard"):FireServer(on)
end

local function requestMelee()
	if guarding then
		return -- can't swing while holding guard
	end
	local t = os.clock()
	if t - lastLocalSwing > Config.MeleeComboReset then
		localCombo = 0
	end

	-- Immediate local arm-driven swing (server still owns damage/cooldown)
	if t - lastLocalSwing >= Config.MeleeCooldown * 0.5 then
		localCombo = (localCombo % Config.MeleeComboMax) + 1
		lastLocalSwing = t
		local character = Players.LocalPlayer.Character
		if character then
			ArmAnimator.playSwing(character, localCombo)
		end
	end

	Remotes.get("RequestMelee"):FireServer()
end

local function requestToggleSheath()
	Remotes.get("RequestToggleSheath"):FireServer()
end

-- Called by AbilityHotbar before firing Flash Step — cancel late recovery for snappy combat
function InputController.tryCancelSwingForFlashStep()
	local character = Players.LocalPlayer.Character
	if character and ArmAnimator.isInLateRecovery(character) then
		ArmAnimator.cancel(character)
	end
end

function InputController.playLocalFlashPose()
	local character = Players.LocalPlayer.Character
	if character and not guarding then
		ArmAnimator.playFlashPose(character)
	end
end

function InputController.playLocalCast()
	local character = Players.LocalPlayer.Character
	if character and not guarding then
		ArmAnimator.playCast(character)
	end
end

function InputController.isGuarding(): boolean
	return guarding
end

function InputController.setGuardFromHotbar(on: boolean)
	setGuard(on)
end

function InputController.start()
	ContextActionService:BindAction("ToggleSheath", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			requestToggleSheath()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Unknown)

	ContextActionService:SetTitle("ToggleSheath", "E Sheath")
	ContextActionService:SetPosition("ToggleSheath", UDim2.new(1, -160, 1, -120))

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if isTyping() then
			return
		end

		if input.KeyCode == Enum.KeyCode.E then
			requestToggleSheath()
			return
		end

		-- Hold F = Spirit Guard (works even if gameProcessed for reliability)
		if input.KeyCode == Enum.KeyCode.F then
			setGuard(true)
			return
		end

		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			requestMelee()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.F then
			setGuard(false)
		end
	end)

	UserInputService.TouchTap:Connect(function(_positions, gameProcessed)
		if gameProcessed or isTyping() then
			return
		end
		requestMelee()
	end)

	Players.LocalPlayer.CharacterRemoving:Connect(function(character)
		ArmAnimator.cancel(character)
		if guarding then
			setGuard(false)
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function()
		if guarding then
			setGuard(false)
		end
	end)
end

return InputController
