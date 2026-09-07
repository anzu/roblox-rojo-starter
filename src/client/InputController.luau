-- Combat input: M1 = sword attack (auto-unsheath), E = sheath toggle.
-- Local swing starts immediately; server remains authoritative for damage.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwingController = require(script.Parent.SwingController)

local InputController = {}

local localCombo = 0
local lastLocalSwing = 0

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function requestMelee()
	local t = os.clock()
	if t - lastLocalSwing > Config.MeleeComboReset then
		localCombo = 0
	end

	-- Immediate local swing for responsiveness (server still owns damage/cooldown)
	if t - lastLocalSwing >= Config.MeleeCooldown * 0.5 then
		localCombo = (localCombo % Config.MeleeComboMax) + 1
		lastLocalSwing = t
		local character = Players.LocalPlayer.Character
		if character then
			SwingController.play(character, localCombo)
		end
	end

	Remotes.get("RequestMelee"):FireServer()
end

local function requestToggleSheath()
	Remotes.get("RequestToggleSheath"):FireServer()
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

		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			requestMelee()
		end
	end)

	UserInputService.TouchTap:Connect(function(_positions, gameProcessed)
		if gameProcessed or isTyping() then
			return
		end
		requestMelee()
	end)
end

return InputController
