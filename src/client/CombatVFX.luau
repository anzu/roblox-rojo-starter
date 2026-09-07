-- Lightweight client VFX: slash parts, arm swing, flash-step trail, hit sparks, deny flash.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CombatVFX = {}

local swinging: { [Model]: boolean } = {}

local function fadePart(part: BasePart, lifetime: number)
	local tween = TweenService:Create(part, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = part.Size * 1.35,
	})
	tween:Play()
	Debris:AddItem(part, lifetime + 0.05)
end

local function findRightShoulder(character: Model): Motor6D?
	-- R15
	local upper = character:FindFirstChild("UpperTorso")
	if upper then
		local rs = upper:FindFirstChild("RightShoulder")
		if rs and rs:IsA("Motor6D") then
			return rs
		end
	end
	-- R6
	local torso = character:FindFirstChild("Torso")
	if torso then
		local rs = torso:FindFirstChild("Right Shoulder")
		if rs and rs:IsA("Motor6D") then
			return rs
		end
	end
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and (d.Name == "RightShoulder" or d.Name == "Right Shoulder") then
			return d
		end
	end
	return nil
end

local function characterFromUserId(userId: number?): Model?
	if typeof(userId) ~= "number" then
		return nil
	end
	for _, player in Players:GetPlayers() do
		if player.UserId == userId then
			return player.Character
		end
	end
	return nil
end

-- Temporary RightShoulder C0 arc, then restore. Combo picks overhead vs horizontal.
local function playArmSwing(character: Model, combo: number)
	if swinging[character] then
		return
	end
	local shoulder = findRightShoulder(character)
	if not shoulder then
		return
	end

	swinging[character] = true
	local original = shoulder.C0
	local isR15 = shoulder.Name == "RightShoulder"

	-- Pose offsets relative to rest C0 (radians)
	local windup: CFrame
	local strike: CFrame
	if combo % 3 == 1 then
		-- Horizontal slash
		if isR15 then
			windup = CFrame.Angles(math.rad(-25), math.rad(55), math.rad(40))
			strike = CFrame.Angles(math.rad(15), math.rad(-70), math.rad(-25))
		else
			windup = CFrame.Angles(math.rad(40), 0, math.rad(70))
			strike = CFrame.Angles(math.rad(-20), 0, math.rad(-80))
		end
	elseif combo % 3 == 2 then
		-- Diagonal
		if isR15 then
			windup = CFrame.Angles(math.rad(-50), math.rad(30), math.rad(20))
			strike = CFrame.Angles(math.rad(35), math.rad(-40), math.rad(-50))
		else
			windup = CFrame.Angles(math.rad(70), 0, math.rad(40))
			strike = CFrame.Angles(math.rad(-50), 0, math.rad(-50))
		end
	else
		-- Overhead finisher
		if isR15 then
			windup = CFrame.Angles(math.rad(-110), math.rad(10), math.rad(10))
			strike = CFrame.Angles(math.rad(50), math.rad(-15), math.rad(-20))
		else
			windup = CFrame.Angles(math.rad(110), 0, math.rad(10))
			strike = CFrame.Angles(math.rad(-60), 0, math.rad(-15))
		end
	end

	local windInfo = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local strikeInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local recoverInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local t1 = TweenService:Create(shoulder, windInfo, { C0 = original * windup })
	t1:Play()
	t1.Completed:Wait()
	if not shoulder.Parent or not character.Parent then
		swinging[character] = nil
		return
	end

	local t2 = TweenService:Create(shoulder, strikeInfo, { C0 = original * strike })
	t2:Play()
	t2.Completed:Wait()
	if not shoulder.Parent or not character.Parent then
		swinging[character] = nil
		return
	end

	local t3 = TweenService:Create(shoulder, recoverInfo, { C0 = original })
	t3:Play()
	t3.Completed:Wait()
	if shoulder.Parent then
		shoulder.C0 = original
	end
	swinging[character] = nil
end

local function slashFX(payload: any)
	local cf: CFrame = payload.cframe or CFrame.new(payload.position or Vector3.zero)
	local combo = payload.combo or 1

	-- Arm / sword swing for the attacking player (and local echo)
	local character = characterFromUserId(payload.userId)
	if not character and payload.userId == nil then
		-- NPC slash: no arm motor
	elseif character then
		task.spawn(playArmSwing, character, combo)
	elseif payload.userId == Players.LocalPlayer.UserId then
		local localChar = Players.LocalPlayer.Character
		if localChar then
			task.spawn(playArmSwing, localChar, combo)
		end
	end

	local slash = Instance.new("Part")
	slash.Name = "SlashFX"
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CanTouch = false
	slash.Material = Enum.Material.SmoothPlastic
	slash.Color = if combo >= 3 then Color3.fromRGB(210, 215, 225) else Color3.fromRGB(180, 185, 195)
	slash.Size = Vector3.new(0.25, 3.5 + combo * 0.4, 5)
	slash.CFrame = cf * CFrame.Angles(0, 0, math.rad(-35 + combo * 20))
	slash.Transparency = 0.35
	slash.Reflectance = 0.2
	slash.Parent = workspace
	fadePart(slash, 0.2)
end

local function flashStepFX(payload: any)
	local startPos: Vector3 = payload.position or Vector3.zero
	local goal: Vector3 = payload.goal or startPos

	local trail = Instance.new("Part")
	trail.Name = "FlashStepTrail"
	trail.Anchored = true
	trail.CanCollide = false
	trail.CanQuery = false
	trail.CanTouch = false
	trail.Material = Enum.Material.ForceField
	trail.Color = Color3.fromRGB(180, 200, 230)
	local mid = (startPos + goal) * 0.5
	local dist = (goal - startPos).Magnitude
	trail.Size = Vector3.new(1.0, 1.0, math.max(dist, 1))
	trail.CFrame = CFrame.lookAt(mid, goal)
	trail.Transparency = 0.45
	trail.Parent = workspace
	fadePart(trail, 0.28)

	local ghost = Instance.new("Part")
	ghost.Name = "FlashGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.Size = Vector3.new(2, 5, 1)
	ghost.Material = Enum.Material.ForceField
	ghost.Color = Color3.fromRGB(160, 190, 230)
	ghost.CFrame = CFrame.new(startPos)
	ghost.Transparency = 0.5
	ghost.Parent = workspace
	fadePart(ghost, 0.35)
end

local function spiritWaveHint(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local ring = Instance.new("Part")
	ring.Name = "WaveCast"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.ForceField
	ring.Color = Color3.fromRGB(120, 170, 220)
	ring.Size = Vector3.new(0.4, 4, 4)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.35
	ring.Parent = workspace
	fadePart(ring, 0.3)
end

local function hitFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local spark = Instance.new("Part")
	spark.Name = "HitSpark"
	spark.Shape = Enum.PartType.Ball
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.CanTouch = false
	spark.Material = Enum.Material.SmoothPlastic
	spark.Color = Color3.fromRGB(255, 230, 160)
	spark.Size = Vector3.new(1.0, 1.0, 1.0)
	spark.CFrame = CFrame.new(pos)
	spark.Transparency = 0.2
	spark.Parent = workspace
	fadePart(spark, 0.18)
end

local function deathFX(payload: any)
	local pos: Vector3 = payload.position or Vector3.zero
	local puff = Instance.new("Part")
	puff.Name = "DeathPuff"
	puff.Shape = Enum.PartType.Ball
	puff.Anchored = true
	puff.CanCollide = false
	puff.CanQuery = false
	puff.CanTouch = false
	puff.Material = Enum.Material.ForceField
	puff.Color = Color3.fromRGB(120, 60, 180)
	puff.Size = Vector3.new(2, 2, 2)
	puff.CFrame = CFrame.new(pos)
	puff.Transparency = 0.3
	puff.Parent = workspace
	local tween = TweenService:Create(puff, TweenInfo.new(0.45), {
		Size = Vector3.new(6, 6, 6),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(puff, 0.5)
end

local function denyFX(_payload: any)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local pulse = Instance.new("Part")
	pulse.Name = "DenyFX"
	pulse.Shape = Enum.PartType.Ball
	pulse.Anchored = true
	pulse.CanCollide = false
	pulse.CanQuery = false
	pulse.CanTouch = false
	pulse.Material = Enum.Material.SmoothPlastic
	pulse.Color = Color3.fromRGB(255, 90, 90)
	pulse.Size = Vector3.new(1.5, 1.5, 1.5)
	pulse.CFrame = CFrame.new(root.Position)
	pulse.Transparency = 0.25
	pulse.Parent = workspace
	fadePart(pulse, 0.25)
end

function CombatVFX.start()
	Remotes.get("CombatFX").OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end
		local kind = payload.kind
		if kind == CombatTypes.Fx.Slash then
			slashFX(payload)
		elseif kind == CombatTypes.Fx.FlashStep then
			flashStepFX(payload)
		elseif kind == CombatTypes.Fx.SpiritWave then
			spiritWaveHint(payload)
		elseif kind == CombatTypes.Fx.Hit then
			hitFX(payload)
		elseif kind == CombatTypes.Fx.Death then
			deathFX(payload)
		elseif kind == CombatTypes.Fx.Deny then
			denyFX(payload)
		end
		-- Sheath FX is visual via Motor6D blade + saya; no extra VFX needed
	end)
end

return CombatVFX
