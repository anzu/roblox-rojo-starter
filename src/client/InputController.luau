-- Tool-less combat input: Mouse1 / touch tap = melee, Q = Flash Step, E = Spirit Wave.

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

local function requestFlashStep()
	Remotes.get("RequestFlashStep"):FireServer()
end

local function requestSpiritWave()
	Remotes.get("RequestSpiritWave"):FireServer()
end

function InputController.start()
	-- Mobile touch buttons for Flash Step / Spirit Wave
	ContextActionService:BindAction("FlashStep", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			requestFlashStep()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Unknown)

	ContextActionService:BindAction("SpiritWave", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			requestSpiritWave()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Unknown)

	ContextActionService:SetTitle("FlashStep", "Flash Step")
	ContextActionService:SetTitle("SpiritWave", "Spirit Wave")
	ContextActionService:SetPosition("FlashStep", UDim2.new(1, -160, 1, -200))
	ContextActionService:SetPosition("SpiritWave", UDim2.new(1, -160, 1, -120))

	-- Keyboard + mouse (single path — no double-fire with ContextAction)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or isTyping() then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			requestMelee()
		elseif input.KeyCode == Enum.KeyCode.Q then
			requestFlashStep()
		elseif input.KeyCode == Enum.KeyCode.E then
			requestSpiritWave()
		end
	end)

	-- Touch tap = melee when not eating UI
	UserInputService.TouchTap:Connect(function(_positions, gameProcessed)
		if gameProcessed or isTyping() then
			return
		end
		requestMelee()
	end)

	local _ = Players.LocalPlayer
end

return InputController
