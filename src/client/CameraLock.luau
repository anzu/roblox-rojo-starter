-- Toggle LeftControl mouse-lock for combat aiming (+ optional soft assist toward Voidspawn).
-- Only AutoRotate=false while lock active; on unlock restore AutoRotate and clear movers.
-- Desktop only; leave mobile alone.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)

local CameraLock = {}

local locked = false
local renderConn: RBXScriptConnection? = nil

local function isDesktop(): boolean
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

local function clearCustomBodyMovers(root: BasePart?)
	if not root then
		return
	end
	for _, child in root:GetChildren() do
		if child:IsA("BodyGyro") or child:IsA("BodyAngularVelocity") then
			if child.Name == "CameraLockGyro" or child:GetAttribute("SpiritBladeCameraLock") then
				child:Destroy()
			end
		end
	end
end

local function applyMouseBehavior(on: boolean)
	if on then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function stopRender()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

local function softAssistLook(root: BasePart, camLookFlat: Vector3): Vector3
	if not Config.CameraLockSoftAssist then
		return camLookFlat
	end
	local range = Config.CameraLockSoftRange or 40
	local coneCos = math.cos(math.rad(Config.CameraLockSoftConeDeg or 55))
	local bestPos: Vector3? = nil
	local bestDist = range + 1

	for _, model in CollectionService:GetTagged(CombatTypes.Tags.Voidspawn) do
		if model:IsA("Model") and model.Parent then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local targetRoot = model:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
				local offset = targetRoot.Position - root.Position
				local flat = Vector3.new(offset.X, 0, offset.Z)
				local dist = flat.Magnitude
				if dist > 0.5 and dist <= range then
					local dir = flat.Unit
					if dir:Dot(camLookFlat) >= coneCos and dist < bestDist then
						bestDist = dist
						bestPos = targetRoot.Position
					end
				end
			end
		end
	end

	if not bestPos then
		return camLookFlat
	end
	local toTarget = Vector3.new(bestPos.X - root.Position.X, 0, bestPos.Z - root.Position.Z)
	if toTarget.Magnitude < 0.05 then
		return camLookFlat
	end
	local strength = Config.CameraLockSoftYawStrength or 0.12
	return camLookFlat:Lerp(toTarget.Unit, strength).Unit
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

		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		-- Only while lock active
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
		flat = softAssistLook(root, flat)
		local pos = root.Position
		root.CFrame = CFrame.lookAt(pos, pos + flat)
	end)
end

function CameraLock.isLocked(): boolean
	return locked
end

function CameraLock.setLocked(on: boolean)
	if not isDesktop() then
		return
	end
	locked = on
	local humanoid, root = getHumanoidAndRoot()
	if locked then
		applyMouseBehavior(true)
		if humanoid then
			humanoid.AutoRotate = false
		end
		startRender()
	else
		stopRender()
		applyMouseBehavior(false)
		if humanoid then
			humanoid.AutoRotate = true
		end
		clearCustomBodyMovers(root)
	end
end

function CameraLock.toggle()
	CameraLock.setLocked(not locked)
end

function CameraLock.start()
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
		if input.KeyCode == Enum.KeyCode.LeftControl then
			CameraLock.toggle()
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function()
		task.defer(function()
			local humanoid, root = getHumanoidAndRoot()
			if locked then
				applyMouseBehavior(true)
				if humanoid then
					humanoid.AutoRotate = false
				end
				startRender()
			else
				-- Ensure AutoRotate is healthy after respawn
				if humanoid then
					humanoid.AutoRotate = true
				end
				clearCustomBodyMovers(root)
				applyMouseBehavior(false)
			end
		end)
	end)

	Players.LocalPlayer.CharacterRemoving:Connect(function()
		stopRender()
		-- Don't leave AutoRotate false on a dying character; next spawn resets
	end)
end

return CameraLock
