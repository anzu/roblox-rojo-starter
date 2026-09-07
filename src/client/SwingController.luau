-- Visible M1 swing via Motor6D.Transform (Animator overwrites C0 every frame).
-- Drive RightShoulder + SpiritBlade BladeMotor inside RunService.Stepped.

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local SwingController = {}

local SWING_TOTAL = 0.30
local WINDUP_END = 0.08
local STRIKE_END = 0.18

type ActiveSwing = {
	conn: RBXScriptConnection,
	token: number,
}

local active: { [Model]: ActiveSwing } = {}

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

local function shoulderPoses(combo: number, isR15: boolean): (CFrame, CFrame)
	local windup: CFrame
	local strike: CFrame
	if combo % 3 == 1 then
		-- Horizontal slash
		if isR15 then
			windup = CFrame.Angles(math.rad(-20), math.rad(70), math.rad(55))
			strike = CFrame.Angles(math.rad(25), math.rad(-85), math.rad(-40))
		else
			windup = CFrame.Angles(math.rad(50), 0, math.rad(85))
			strike = CFrame.Angles(math.rad(-25), 0, math.rad(-95))
		end
	elseif combo % 3 == 2 then
		-- Diagonal
		if isR15 then
			windup = CFrame.Angles(math.rad(-55), math.rad(40), math.rad(30))
			strike = CFrame.Angles(math.rad(45), math.rad(-50), math.rad(-60))
		else
			windup = CFrame.Angles(math.rad(80), 0, math.rad(50))
			strike = CFrame.Angles(math.rad(-55), 0, math.rad(-60))
		end
	else
		-- Overhead finisher
		if isR15 then
			windup = CFrame.Angles(math.rad(-120), math.rad(15), math.rad(15))
			strike = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(-25))
		else
			windup = CFrame.Angles(math.rad(120), 0, math.rad(15))
			strike = CFrame.Angles(math.rad(-70), 0, math.rad(-20))
		end
	end
	return windup, strike
end

-- Milder wrist snap so the blade reads the same arc without tearing the grip.
local function bladePoses(combo: number): (CFrame, CFrame)
	if combo % 3 == 1 then
		return CFrame.Angles(0, math.rad(25), math.rad(35)), CFrame.Angles(0, math.rad(-30), math.rad(-40))
	elseif combo % 3 == 2 then
		return CFrame.Angles(math.rad(-20), math.rad(15), math.rad(20)), CFrame.Angles(math.rad(25), math.rad(-20), math.rad(-30))
	end
	return CFrame.Angles(math.rad(-35), 0, math.rad(10)), CFrame.Angles(math.rad(40), 0, math.rad(-15))
end

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function samplePose(windup: CFrame, strike: CFrame, elapsed: number): CFrame
	if elapsed <= WINDUP_END then
		local a = smoothstep(elapsed / WINDUP_END)
		return CFrame.new():Lerp(windup, a)
	elseif elapsed <= STRIKE_END then
		local a = smoothstep((elapsed - WINDUP_END) / (STRIKE_END - WINDUP_END))
		return windup:Lerp(strike, a)
	else
		local a = smoothstep((elapsed - STRIKE_END) / (SWING_TOTAL - STRIKE_END))
		return strike:Lerp(CFrame.new(), a)
	end
end

local function attachBladeTrail(blade: BasePart)
	local a0 = Instance.new("Attachment")
	a0.Name = "SwingTrailA0"
	a0.Position = Vector3.new(0, 1.2, 0)
	a0.Parent = blade

	local a1 = Instance.new("Attachment")
	a1.Name = "SwingTrailA1"
	a1.Position = Vector3.new(0, -0.4, 0)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.12
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.LightEmission = 0.15
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(200, 210, 220))
	trail.Parent = blade

	Debris:AddItem(a0, SWING_TOTAL + 0.15)
	Debris:AddItem(a1, SWING_TOTAL + 0.15)
	Debris:AddItem(trail, SWING_TOTAL + 0.15)
end

function SwingController.isPlaying(character: Model): boolean
	return active[character] ~= nil
end

function SwingController.play(character: Model, combo: number?)
	if not character or not character.Parent then
		return
	end
	local index = combo or 1

	local prev = active[character]
	if prev then
		prev.conn:Disconnect()
		active[character] = nil
	end

	local shoulder = findRightShoulder(character)
	local bladeMotor = findBladeMotor(character)
	if not shoulder and not bladeMotor then
		return
	end

	local isR15 = if shoulder then shoulder.Name == "RightShoulder" else true
	local sWind, sStrike = shoulderPoses(index, isR15)
	local bWind, bStrike = bladePoses(index)

	local bladePart = findBladePart(character)
	if bladePart then
		attachBladeTrail(bladePart)
	end

	local start = os.clock()
	local token = start
	local conn: RBXScriptConnection

	conn = RunService.Stepped:Connect(function()
		if not character.Parent then
			conn:Disconnect()
			if active[character] and active[character].token == token then
				active[character] = nil
			end
			return
		end

		local elapsed = os.clock() - start
		if elapsed >= SWING_TOTAL then
			-- Stop overriding; Animator reclaims shoulder. Clear blade (not animated).
			if bladeMotor and bladeMotor.Parent then
				bladeMotor.Transform = CFrame.new()
			end
			conn:Disconnect()
			if active[character] and active[character].token == token then
				active[character] = nil
			end
			return
		end

		local shoulderPose = samplePose(sWind, sStrike, elapsed)
		local bladePose = samplePose(bWind, bStrike, elapsed)

		if shoulder and shoulder.Parent then
			shoulder.Transform = shoulderPose
		end
		if bladeMotor and bladeMotor.Parent then
			-- Only twist the drawn blade (Part0 is hand when unsheathed)
			local part0 = bladeMotor.Part0
			if part0 and (part0.Name == "RightHand" or part0.Name == "Right Arm") then
				bladeMotor.Transform = bladePose
			end
		end
	end)

	active[character] = {
		conn = conn,
		token = token,
	}
end

return SwingController
