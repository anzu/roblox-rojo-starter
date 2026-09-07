-- Combat input: M1 = sword attack (auto-unsheath), E = sheath toggle.
-- Abilities 1–9 are handled by AbilityHotbar (keys + clicks).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InputController = {}

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function requestMelee()
	Remotes.get("RequestMelee"):FireServer()
end

local function requestToggleSheath()
	Remotes.get("RequestToggleSheath"):FireServer()
end

function InputController.start()
	-- Mobile sheath button (abilities use hotbar / CAS titles elsewhere)
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

		-- E sheath ignores gameProcessed (still skips text boxes)
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

	local _ = Players.LocalPlayer
end

return InputController
