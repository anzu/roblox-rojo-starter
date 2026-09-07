-- LeftShift hold = sprint. Boosts WalkSpeed; optional FOV bump. Never freezes movement.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local SprintController = {}

local sprinting = false
local shiftHeld = false
local heartbeatConn: RBXScriptConnection? = nil
local baseFov: number? = nil

local function getHumanoid(): Humanoid?
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function applySpeed(humanoid: Humanoid, sprint: boolean)
	-- Don't override if dead
	if humanoid.Health <= 0 then
		return
	end
	-- Never set WalkSpeed to 0 here
	if sprint then
		humanoid.WalkSpeed = Config.SprintWalkSpeed or 28
	else
		humanoid.WalkSpeed = Config.WalkSpeedDefault or 16
	end
end

local function applyFov(sprint: boolean)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local boost = Config.SprintFovBoost or 0
	if boost <= 0 then
		return
	end
	if sprint then
		if baseFov == nil then
			baseFov = cam.FieldOfView
		end
		cam.FieldOfView = (baseFov or 70) + boost
	else
		if baseFov ~= nil then
			cam.FieldOfView = baseFov
			baseFov = nil
		end
	end
end

local function setSprinting(on: boolean)
	if sprinting == on then
		return
	end
	sprinting = on
	local humanoid = getHumanoid()
	if humanoid then
		applySpeed(humanoid, on)
	end
	applyFov(on)
end

function SprintController.isSprinting(): boolean
	return sprinting
end

function SprintController.start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			shiftHeld = true
			setSprinting(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			shiftHeld = false
			setSprinting(false)
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		task.defer(function()
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid and humanoid:IsA("Humanoid") then
				-- Restore default; resume sprint if still holding
				if shiftHeld then
					applySpeed(humanoid, true)
					applyFov(true)
					sprinting = true
				else
					applySpeed(humanoid, false)
					applyFov(false)
					sprinting = false
				end
			end
		end)
	end)

	-- Keep WalkSpeed correct if something else resets it mid-sprint
	if heartbeatConn then
		heartbeatConn:Disconnect()
	end
	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not sprinting then
			return
		end
		local humanoid = getHumanoid()
		if humanoid and humanoid.Health > 0 then
			local target = Config.SprintWalkSpeed or 28
			if math.abs(humanoid.WalkSpeed - target) > 0.5 then
				humanoid.WalkSpeed = target
			end
		end
	end)
end

return SprintController
