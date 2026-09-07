-- Visible M1 swing via Motor6D.Transform (Animator overwrites C0 every frame).
-- Drive RightShoulder + RightElbow + SpiritBlade BladeMotor inside RunService.Stepped.
-- Always clear Stepped + reset Transform to identity on end/cancel. Never touches AutoRotate.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local SwingController = {}

local SWING_TOTAL = Config.SwingTotal or 0.40
local WINDUP_END = Config.SwingWindupEnd or 0.10
local STRIKE_END = Config.SwingStrikeEnd or 0.26

type ActiveSwing = {
	conn: RBXScriptConnection,
	token: number,
	start: number,
	shoulder: Motor6D?,
	elbow: Motor6D?,
	bladeMotor: Motor6D?,
}

local active: { [Model]: ActiveSwing } = {}
local characterHooked = false

local function findRightShoulder(character: Model): Motor6D?
	local upper = character:FindFirstChild("UpperTorso")
	if upper then
		local rs = upper:FindFirstChild("RightShoulder")
		if rs and rs:IsA("Motor6D") then
			return rs
		end
	end
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

local function findRightElbow(character: Model): Motor6D?
	local lower = character:FindFirstChild("RightLowerArm")
	if lower then
		local elbow = lower:FindFirstChild("RightElbow")
		if elbow and elbow:IsA("Motor6D") then
			return elbow
		end
	end
	for _, d in character:GetDescendants() do
		if d:IsA("Motor6D") and d.Name == "RightElbow" then
			return d
		end
	end
	return nil
end

local function findBladeMotor(character: Model): Motor6D?
	local katana = character:FindFirstChild("SpiritBlade")
	if not katana then
		return nil
	end
	local motor = katana:FindFirstChild("BladeMotor")
	if motor and motor:IsA("Motor6D") then
		return motor
	end
	return nil
end

local function findBladePart(character: Model): BasePart?
	local katana = character:FindFirstChild("SpiritBlade")
	if not katana then
		return nil
	end
	local blade = katana:FindFirstChild("Blade")
	if blade and blade:IsA("BasePart") and blade.Transparency < 1 then
		return blade
	end
	local handle = katana:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end
	return nil
end

-- Bigger arcs for a readable fluid slash
local function shoulderPoses(combo: number, isR15: boolean): (CFrame, CFrame)
	local windup: CFrame
	local strike: CFrame
	if combo % 3 == 1 then
		-- Horizontal slash — wide arc
		if isR15 then
			windup = CFrame.Angles(math.rad(-25), math.rad(95), math.rad(70))
			strike = CFrame.Angles(math.rad(30), math.rad(-100), math.rad(-55))
		else
			windup = CFrame.Angles(math.rad(55), 0, math.rad(100))
			strike = CFrame.Angles(math.rad(-30), 0, math.rad(-110))
		end
	elseif combo % 3 == 2 then
		-- Diagonal
		if isR15 then
			windup = CFrame.Angles(math.rad(-70), math.rad(50), math.rad(40))
			strike = CFrame.Angles(math.rad(55), math.rad(-65), math.rad(-75))
		else
			windup = CFrame.Angles(math.rad(95), 0, math.rad(60))
			strike = CFrame.Angles(math.rad(-65), 0, math.rad(-75))
		end
	else
		-- Overhead finisher
		if isR15 then
			windup = CFrame.Angles(math.rad(-140), math.rad(20), math.rad(20))
			strike = CFrame.Angles(math.rad(75), math.rad(-25), math.rad(-30))
		else
			windup = CFrame.Angles(math.rad(135), 0, math.rad(20))
			strike = CFrame.Angles(math.rad(-80), 0, math.rad(-25))
		end
	end
	return windup, strike
end

local function elbowPoses(combo: number): (CFrame, CFrame)
	-- Mild elbow bend so the slash reads as an arm swing, not a stiff stick
	if combo % 3 == 1 then
		return CFrame.Angles(math.rad(-15), 0, 0), CFrame.Angles(math.rad(-35), 0, math.rad(-10))
	elseif combo % 3 == 2 then
		return CFrame.Angles(math.rad(-25), 0, math.rad(5)), CFrame.Angles(math.rad(-45), 0, math.rad(-15))
	end
	return CFrame.Angles(math.rad(-10), 0, 0), CFrame.Angles(math.rad(-50), 0, 0)
end

local function bladePoses(combo: number): (CFrame, CFrame)
	if combo % 3 == 1 then
		return CFrame.Angles(0, math.rad(30), math.rad(40)), CFrame.Angles(0, math.rad(-35), math.rad(-45))
	elseif combo % 3 == 2 then
		return CFrame.Angles(math.rad(-25), math.rad(20), math.rad(25)), CFrame.Angles(math.rad(30), math.rad(-25), math.rad(-35))
	end
	return CFrame.Angles(math.rad(-40), 0, math.rad(12)), CFrame.Angles(math.rad(45), 0, math.rad(-18))
end

-- Cubic smoothstep for fluid easing (sampled alpha on Stepped)
local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function smootherstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function samplePose(windup: CFrame, strike: CFrame, elapsed: number): CFrame
	if elapsed <= WINDUP_END then
		local a = smootherstep(elapsed / WINDUP_END)
		return CFrame.new():Lerp(windup, a)
	elseif elapsed <= STRIKE_END then
		local a = smootherstep((elapsed - WINDUP_END) / (STRIKE_END - WINDUP_END))
		return windup:Lerp(strike, a)
	else
		-- Ease out gently — no snap recover
		local a = smoothstep((elapsed - STRIKE_END) / math.max(SWING_TOTAL - STRIKE_END, 0.001))
		return strike:Lerp(CFrame.new(), a)
	end
end

local function resetMotors(shoulder: Motor6D?, elbow: Motor6D?, bladeMotor: Motor6D?)
	if shoulder and shoulder.Parent then
		shoulder.Transform = CFrame.new()
	end
	if elbow and elbow.Parent then
		elbow.Transform = CFrame.new()
	end
	if bladeMotor and bladeMotor.Parent then
		bladeMotor.Transform = CFrame.new()
	end
end

local function clearSwing(character: Model, reset: boolean)
	local entry = active[character]
	if not entry then
		return
	end
	entry.conn:Disconnect()
	if reset then
		resetMotors(entry.shoulder, entry.elbow, entry.bladeMotor)
	end
	active[character] = nil
end

local function attachBladeTrail(blade: BasePart)
	local a0 = Instance.new("Attachment")
	a0.Name = "SwingTrailA0"
	a0.Position = Vector3.new(0, 1.4, 0)
	a0.Parent = blade

	local a1 = Instance.new("Attachment")
	a1.Name = "SwingTrailA1"
	a1.Position = Vector3.new(0, -0.5, 0)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.18
	trail.MinLength = 0.04
	trail.FaceCamera = true
	trail.LightEmission = 0.2
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(200, 210, 220))
	trail.Parent = blade

	Debris:AddItem(a0, SWING_TOTAL + 0.2)
	Debris:AddItem(a1, SWING_TOTAL + 0.2)
	Debris:AddItem(trail, SWING_TOTAL + 0.2)
end

function SwingController.isPlaying(character: Model): boolean
	return active[character] ~= nil
end

function SwingController.getElapsed(character: Model): number?
	local entry = active[character]
	if not entry then
		return nil
	end
	return os.clock() - entry.start
end

function SwingController.isInLateRecovery(character: Model): boolean
	local elapsed = SwingController.getElapsed(character)
	if not elapsed then
		return false
	end
	local cancelAfter = Config.FlashStepCancelSwingAfter or STRIKE_END
	return elapsed >= cancelAfter
end

-- Hard cancel: disconnect Stepped, identity Transform. Safe to call anytime.
function SwingController.cancel(character: Model)
	clearSwing(character, true)
end

function SwingController.play(character: Model, combo: number?)
	if not character or not character.Parent then
		return
	end
	local index = combo or 1

	-- Always tear down previous swing cleanly first
	clearSwing(character, true)

	local shoulder = findRightShoulder(character)
	local elbow = findRightElbow(character)
	local bladeMotor = findBladeMotor(character)
	if not shoulder and not bladeMotor then
		return
	end

	local isR15 = if shoulder then shoulder.Name == "RightShoulder" else true
	local sWind, sStrike = shoulderPoses(index, isR15)
	local eWind, eStrike = elbowPoses(index)
	local bWind, bStrike = bladePoses(index)

	local bladePart = findBladePart(character)
	if bladePart then
		attachBladeTrail(bladePart)
	end

	local start = os.clock()
	local token = start
	local conn: RBXScriptConnection

	conn = RunService.Stepped:Connect(function()
		local entry = active[character]
		if not entry or entry.token ~= token then
			conn:Disconnect()
			return
		end

		if not character.Parent then
			clearSwing(character, true)
			return
		end

		local elapsed = os.clock() - start
		if elapsed >= SWING_TOTAL then
			-- Ease already reached identity; clear Transform so Animate reclaims cleanly
			resetMotors(shoulder, elbow, bladeMotor)
			conn:Disconnect()
			if active[character] and active[character].token == token then
				active[character] = nil
			end
			return
		end

		local shoulderPose = samplePose(sWind, sStrike, elapsed)
		local elbowPose = samplePose(eWind, eStrike, elapsed)
		local bladePose = samplePose(bWind, bStrike, elapsed)

		if shoulder and shoulder.Parent then
			shoulder.Transform = shoulderPose
		end
		if elbow and elbow.Parent then
			elbow.Transform = elbowPose
		end
		if bladeMotor and bladeMotor.Parent then
			local part0 = bladeMotor.Part0
			if part0 and (part0.Name == "RightHand" or part0.Name == "Right Arm") then
				bladeMotor.Transform = bladePose
			end
		end
	end)

	active[character] = {
		conn = conn,
		token = token,
		start = start,
		shoulder = shoulder,
		elbow = elbow,
		bladeMotor = bladeMotor,
	}
end

local function hookLocalCharacter()
	if characterHooked then
		return
	end
	characterHooked = true
	local player = Players.LocalPlayer

	local function onRemoving(character: Model)
		clearSwing(character, true)
	end

	player.CharacterRemoving:Connect(onRemoving)
	if player.Character then
		-- Ensure we don't leave Transform stuck across respawns
		player.Character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				clearSwing(player.Character :: Model, true)
			end
		end)
	end
	player.CharacterAdded:Connect(function(character)
		-- Clear any stale entry keyed by old model
		for model in active do
			if not model.Parent then
				clearSwing(model, false)
			end
		end
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				clearSwing(character, true)
			end
		end)
	end)
end

function SwingController.start()
	hookLocalCharacter()
end

return SwingController
