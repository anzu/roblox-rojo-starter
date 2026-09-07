-- Toggle LeftShift mouse-lock for combat aiming. Desktop only; leave mobile alone.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ShiftLock = {}

local locked = false
local renderConn: RBXScriptConnection? = nil

local function isDesktop(): boolean
	-- Don't fight touch-primary / mobile layouts
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return false
	end
	return UserInputService.KeyboardEnabled or UserInputService.MouseEnabled
end

local function getHumanoidAndRoot(): (Humanoid?, BasePart?)
	local character = Players.LocalPlayer.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and not root:IsA("BasePart") then
		root = nil
	end
	return humanoid, root :: BasePart?
end

local function applyMouseBehavior(on: boolean)
	if on then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function setHumanoidRotate(humanoid: Humanoid?, auto: boolean)
	if humanoid then
		humanoid.AutoRotate = auto
	end
end

local function stopRender()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

local function startRender()
	stopRender()
	renderConn = RunService.RenderStepped:Connect(function()
		if not locked then
			return
		end
		local humanoid, root = getHumanoidAndRoot()
		if not humanoid or humanoid.Health <= 0 or not root then
			return
		end

		-- Keep lock behavior sticky if something else resets it
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		humanoid.AutoRotate = false

		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.05 then
			return
		end
		flat = flat.Unit
		local pos = root.Position
		root.CFrame = CFrame.lookAt(pos, pos + flat)
	end)
end

function ShiftLock.isLocked(): boolean
	return locked
end

function ShiftLock.setLocked(on: boolean)
	if not isDesktop() then
		return
	end
	locked = on
	local humanoid = getHumanoidAndRoot()
	if locked then
		applyMouseBehavior(true)
		setHumanoidRotate(humanoid, false)
		startRender()
	else
		stopRender()
		applyMouseBehavior(false)
		setHumanoidRotate(humanoid, true)
	end
end

function ShiftLock.toggle()
	ShiftLock.setLocked(not locked)
end

function ShiftLock.start()
	if not isDesktop() then
		return
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			ShiftLock.toggle()
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function()
		-- Re-apply after respawn if still toggled on
		if locked then
			task.defer(function()
				local humanoid = getHumanoidAndRoot()
				applyMouseBehavior(true)
				setHumanoidRotate(humanoid, false)
				startRender()
			end)
		end
	end)
end

return ShiftLock
