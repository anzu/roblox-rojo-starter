-- Spirit Power bar ScreenGui (Health uses default Roblox bar).

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

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
	frame.Position = UDim2.new(0.5, 0, 1, -24)
	frame.Size = UDim2.fromOffset(280, 28)
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
	hints.Size = UDim2.fromOffset(320, 54)
	hints.BackgroundTransparency = 1
	hints.Font = Enum.Font.Gotham
	hints.TextSize = 14
	hints.TextXAlignment = Enum.TextXAlignment.Left
	hints.TextYAlignment = Enum.TextYAlignment.Top
	hints.TextColor3 = Color3.fromRGB(210, 220, 235)
	hints.TextStrokeTransparency = 0.55
	hints.Text = "M1 — Spirit Slash\nQ — Flash Step\nE — Spirit Wave"
	hints.Parent = gui

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

	-- Seed from attribute if already set
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
