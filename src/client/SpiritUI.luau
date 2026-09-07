-- Spirit Power bar + control hints (abilities live on AbilityHotbar).

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)

local SpiritUI = {}

function SpiritUI.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "SpiritBladeUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "SpiritPowerFrame"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -12)
	frame.Size = UDim2.fromOffset(280, 24)
	frame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 170, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = frame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 180, 255)
	fill.BorderSizePixel = 0
	fill.Parent = frame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 248, 255)
	label.TextStrokeTransparency = 0.5
	label.Text = string.format("Spirit Power  %d / %d", Config.SpiritPowerMax, Config.SpiritPowerMax)
	label.ZIndex = 2
	label.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "GameTitle"
	title.AnchorPoint = Vector2.new(0, 0)
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.fromOffset(220, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(180, 220, 255)
	title.TextStrokeTransparency = 0.4
	title.Text = Config.GameName
	title.Parent = gui

	local hints = Instance.new("TextLabel")
	hints.Name = "Controls"
	hints.AnchorPoint = Vector2.new(0, 0)
	hints.Position = UDim2.fromOffset(16, 40)
	hints.Size = UDim2.fromOffset(420, 120)
	hints.BackgroundTransparency = 1
	hints.Font = Enum.Font.Gotham
	hints.TextSize = 14
	hints.TextXAlignment = Enum.TextXAlignment.Left
	hints.TextYAlignment = Enum.TextYAlignment.Top
	hints.TextColor3 = Color3.fromRGB(210, 220, 235)
	hints.TextStrokeTransparency = 0.55
	hints.Text =
		"E — Draw / sheath katana (saya on back)\n"
		.. "M1 — Sword Attack (3-hit Zanjutsu combo)\n"
		.. "Shift — Sprint · Ctrl — Camera lock\n"
		.. "F / Hotbar 3 — Spirit Guard (hold)\n"
		.. "Hotbar 1 — Flash Step · 2 — Spirit Wave"
	hints.Parent = gui

	local denyLabel = Instance.new("TextLabel")
	denyLabel.Name = "DenyNotice"
	denyLabel.AnchorPoint = Vector2.new(0.5, 1)
	denyLabel.Position = UDim2.new(0.5, 0, 1, -148)
	denyLabel.Size = UDim2.fromOffset(320, 22)
	denyLabel.BackgroundTransparency = 1
	denyLabel.Font = Enum.Font.GothamBold
	denyLabel.TextSize = 16
	denyLabel.TextColor3 = Color3.fromRGB(255, 140, 140)
	denyLabel.TextStrokeTransparency = 0.4
	denyLabel.Text = ""
	denyLabel.Parent = gui

	local denyToken = 0
	local function showDeny(reason: string)
		denyToken += 1
		local token = denyToken
		denyLabel.Text = reason
		task.delay(1.4, function()
			if denyToken == token then
				denyLabel.Text = ""
			end
		end)
	end

	local function setPower(current: number, maxPower: number)
		local ratio = 0
		if maxPower > 0 then
			ratio = math.clamp(current / maxPower, 0, 1)
		end
		fill.Size = UDim2.fromScale(ratio, 1)
		label.Text = string.format("Spirit Power  %d / %d", math.floor(current + 0.5), math.floor(maxPower + 0.5))
	end

	Remotes.get("SpiritPowerChanged").OnClientEvent:Connect(function(current, maxPower)
		setPower(tonumber(current) or 0, tonumber(maxPower) or Config.SpiritPowerMax)
	end)

	Remotes.get("CombatFX").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" and payload.kind == CombatTypes.Fx.Deny then
			showDeny(tostring(payload.reason or "Denied"))
		end
	end)

	local attr = player:GetAttribute("SpiritPower")
	if typeof(attr) == "number" then
		setPower(attr, Config.SpiritPowerMax)
	end
	player:GetAttributeChangedSignal("SpiritPower"):Connect(function()
		local v = player:GetAttribute("SpiritPower")
		if typeof(v) == "number" then
			setPower(v, Config.SpiritPowerMax)
		end
	end)
end

return SpiritUI
