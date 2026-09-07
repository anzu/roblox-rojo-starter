-- Tool-less combat input:
-- M1 = melee (auto-unsheath), E = sheath toggle, 1 = Flash Step, 2 = Spirit Wave.
-- Keys 3–9 reserved (no-op).

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

local function requestToggleSheath()
	Remotes.get("RequestToggleSheath"):FireServer()
end

function InputController.start()
	-- Mobile touch buttons
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

	ContextActionService:BindAction("ToggleSheath", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			requestToggleSheath()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.Unknown)

	ContextActionService:SetTitle("FlashStep", "1 Flash Step")
	ContextActionService:SetTitle("SpiritWave", "2 Spirit Wave")
	ContextActionService:SetTitle("ToggleSheath", "E Sheath")
	ContextActionService:SetPosition("FlashStep", UDim2.new(1, -160, 1, -280))
	ContextActionService:SetPosition("SpiritWave", UDim2.new(1, -160, 1, -200))
	ContextActionService:SetPosition("ToggleSheath", UDim2.new(1, -160, 1, -120))

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if isTyping() then
			return
		end

		local key = input.KeyCode
		-- Ability keys ignore gameProcessed (Q/E conflicted before); still skip text boxes.
		if key == Enum.KeyCode.E then
			requestToggleSheath()
			return
		elseif key == Enum.KeyCode.One then
			requestFlashStep()
			return
		elseif key == Enum.KeyCode.Two then
			requestSpiritWave()
			return
		elseif key == Enum.KeyCode.Three
			or key == Enum.KeyCode.Four
			or key == Enum.KeyCode.Five
			or key == Enum.KeyCode.Six
			or key == Enum.KeyCode.Seven
			or key == Enum.KeyCode.Eight
			or key == Enum.KeyCode.Nine
		then
			-- Reserved ability slots — intentional no-op
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
