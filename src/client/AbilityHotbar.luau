-- Spirit ability hotbar: 9 slots. 1 = Flash Step, 2 = Spirit Wave, 3 = Spirit Guard, 4–9 locked.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InputController = require(script.Parent.InputController)

local AbilityHotbar = {}

local SLOT_DEFS = {
	[1] = { id = "FlashStep", label = "Flash\nStep", color = Color3.fromRGB(120, 190, 255) },
	[2] = { id = "SpiritWave", label = "Spirit\nWave", color = Color3.fromRGB(100, 160, 255) },
	[3] = { id = "SpiritGuard", label = "Spirit\nGuard", color = Color3.fromRGB(160, 200, 140), hold = true },
}

local KEYCODES = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

local guardHotbarHeld = false
local slots: { TextButton } = {}

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function setGuardVisual(on: boolean)
	local slot = slots[3]
	if not slot then
		return
	end
	if on then
		slot.BackgroundColor3 = Color3.fromRGB(60, 100, 70)
	else
		slot.BackgroundColor3 = Color3.fromRGB(28, 42, 70)
	end
end

local function activateSlot(index: number, pressed: boolean)
	local def = SLOT_DEFS[index]
	if not def then
		return
	end
	if def.id == "FlashStep" then
		if pressed then
			InputController.tryCancelSwingForFlashStep()
			InputController.playLocalFlashPose()
			Remotes.get("RequestFlashStep"):FireServer()
		end
	elseif def.id == "SpiritWave" then
		if pressed then
			InputController.playLocalCast()
			Remotes.get("RequestSpiritWave"):FireServer()
		end
	elseif def.id == "SpiritGuard" then
		-- Hold semantics for key/hotbar 3 (same as F)
		guardHotbarHeld = pressed
		InputController.setGuardFromHotbar(pressed)
		setGuardVisual(pressed)
	end
end

function AbilityHotbar.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "AbilityHotbar"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5
	gui.Parent = playerGui

	local bar = Instance.new("Frame")
	bar.Name = "Hotbar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -64)
	bar.Size = UDim2.fromOffset(9 * 54 + 8 * 6 + 16, 70)
	bar.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel = 0
	bar.Parent = gui

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = bar

	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.fromRGB(80, 130, 200)
	barStroke.Thickness = 1.2
	barStroke.Transparency = 0.4
	barStroke.Parent = bar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.Parent = bar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = bar

	for i = 1, 9 do
		local def = SLOT_DEFS[i]
		local slot = Instance.new("TextButton")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.fromOffset(54, 54)
		slot.AutoButtonColor = def ~= nil
		slot.Text = ""
		slot.BorderSizePixel = 0
		slot.Parent = bar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = slot

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.5
		stroke.Parent = slot

		local keyBadge = Instance.new("TextLabel")
		keyBadge.Name = "Key"
		keyBadge.BackgroundTransparency = 1
		keyBadge.Position = UDim2.fromOffset(4, 2)
		keyBadge.Size = UDim2.fromOffset(16, 14)
		keyBadge.Font = Enum.Font.GothamBold
		keyBadge.TextSize = 12
		keyBadge.TextXAlignment = Enum.TextXAlignment.Left
		keyBadge.Text = tostring(i)
		keyBadge.Parent = slot

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "AbilityName"
		nameLabel.BackgroundTransparency = 1
		nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		nameLabel.Position = UDim2.fromScale(0.5, 0.58)
		nameLabel.Size = UDim2.new(1, -6, 0, 32)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 11
		nameLabel.TextWrapped = true
		nameLabel.Parent = slot

		if def then
			slot.BackgroundColor3 = Color3.fromRGB(28, 42, 70)
			stroke.Color = def.color
			keyBadge.TextColor3 = def.color
			nameLabel.TextColor3 = Color3.fromRGB(230, 240, 255)
			nameLabel.Text = def.label
			if def.hold then
				slot.MouseButton1Down:Connect(function()
					activateSlot(i, true)
				end)
				slot.MouseButton1Up:Connect(function()
					activateSlot(i, false)
				end)
				slot.MouseLeave:Connect(function()
					if guardHotbarHeld then
						activateSlot(i, false)
					end
				end)
			else
				slot.MouseButton1Click:Connect(function()
					activateSlot(i, true)
				end)
			end
		else
			slot.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
			slot.BackgroundTransparency = 0.15
			stroke.Color = Color3.fromRGB(60, 65, 80)
			stroke.Transparency = 0.35
			keyBadge.TextColor3 = Color3.fromRGB(110, 115, 130)
			nameLabel.TextColor3 = Color3.fromRGB(90, 95, 110)
			nameLabel.Text = "—"
			slot.Active = false
			slot.AutoButtonColor = false
		end

		slots[i] = slot
	end

	UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if isTyping() then
			return
		end
		for i, key in KEYCODES do
			if input.KeyCode == key then
				local def = SLOT_DEFS[i]
				activateSlot(i, true)
				local slot = slots[i]
				if slot and def and not def.hold then
					local old = slot.BackgroundColor3
					slot.BackgroundColor3 = Color3.fromRGB(50, 80, 130)
					task.delay(0.08, function()
						if slot.Parent then
							slot.BackgroundColor3 = old
						end
					end)
				end
				return
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		for i, key in KEYCODES do
			if input.KeyCode == key then
				local def = SLOT_DEFS[i]
				if def and def.hold then
					activateSlot(i, false)
				end
				return
			end
		end
	end)
end

return AbilityHotbar
