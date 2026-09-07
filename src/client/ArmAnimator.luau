-- Arm-driven combat animation via Motor6D.Transform (post-Animator, Stepped).
-- Sword is PASSIVE: BladeMotor / hand weld Transform stays identity — blade follows the hand.
-- Never animate BladeMotor. Always reset overridden Motors to identity on cancel/end.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local ArmAnimator = {}

local SWING_TOTAL = Config.SwingTotal or 0.50
local WINDUP_END = Config.SwingWindupEnd or 0.12
local STRIKE_END = Config.SwingStrikeEnd or 0.32
local CAST_TOTAL = 0.35
local FLASH_TOTAL = 0.15

type Mode = "swing" | "cast" | "flash" | "guard"

type ArmMotors = {
	shoulder: Motor6D?,
	elbow: Motor6D?,
	wrist: Motor6D?,
	leftShoulder: Motor6D?,
	isR15: boolean,
}

type ActiveAnim = {
	conn: RBXScriptConnection,
	token: number,
	start: number,
	mode: Mode,
	motors: ArmMotors,
	combo: number?,
}

local active: { [Model]: ActiveAnim } = {}
local characterHooked = false

--------------------------------------------------------------------------
-- Motor discovery
--------------------------------------------------------------------------

local function findMotorByNames(character: Model, names: { string }): Motor6D?
	for _, name in names do
		local found = character:FindFirstChild(name, true)
		if found and found:IsA("Motor6D") then
			return found
		end
	end
	return nil
end

local function resolveMotors(character: Model): ArmMotors
	local shoulder = findMotorByNames(character, { "RightShoulder", "Right Shoulder" })
	local elbow = findMotorByNames(character, { "RightElbow" })
	local wrist = findMotorByNames(character, { "RightWrist" })
	local leftShoulder = findMotorByNames(character, { "LeftShoulder", "Left Shoulder" })
	local isR15 = if shoulder then shoulder.Name == "RightShoulder" else (elbow ~= nil)
	return {
		shoulder = shoulder,
		elbow = elbow,
		wrist = wrist,
		leftShoulder = leftShoulder,
		isR15 = isR15,
	}
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

--------------------------------------------------------------------------
-- Easing
--------------------------------------------------------------------------

local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function smootherstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerpCF(a: CFrame, b: CFrame, t: number): CFrame
	return a:Lerp(b, math.clamp(t, 0, 1))
end

--------------------------------------------------------------------------
-- Pose libraries — LARGE obvious arcs (tens of degrees per joint)
--------------------------------------------------------------------------

type Triple = { shoulder: CFrame, elbow: CFrame, wrist: CFrame, leftShoulder: CFrame? }

-- Swing windup / strike by combo (1 horiz, 2 diag, 3 overhead)
local function swingPoses(combo: number, isR15: boolean): (Triple, Triple)
	local windup: Triple
	local strike: Triple
	local idx = ((combo - 1) % 3) + 1

	if isR15 then
		if idx == 1 then
			-- Horizontal slash — big sideways arc
			windup = {
				shoulder = CFrame.Angles(math.rad(-35), math.rad(95), math.rad(85)),
				elbow = CFrame.Angles(math.rad(-70), math.rad(10), math.rad(15)),
				wrist = CFrame.Angles(math.rad(-20), math.rad(25), math.rad(40)),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(25), math.rad(-105), math.rad(-70)),
				elbow = CFrame.Angles(math.rad(-25), math.rad(-15), math.rad(-35)),
				wrist = CFrame.Angles(math.rad(15), math.rad(-30), math.rad(-45)),
			}
		elseif idx == 2 then
			-- Diagonal
			windup = {
				shoulder = CFrame.Angles(math.rad(-85), math.rad(55), math.rad(50)),
				elbow = CFrame.Angles(math.rad(-80), math.rad(5), math.rad(20)),
				wrist = CFrame.Angles(math.rad(-30), math.rad(15), math.rad(25)),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(50), math.rad(-70), math.rad(-80)),
				elbow = CFrame.Angles(math.rad(-20), math.rad(-10), math.rad(-40)),
				wrist = CFrame.Angles(math.rad(25), math.rad(-20), math.rad(-35)),
			}
		else
			-- Overhead finisher
			windup = {
				shoulder = CFrame.Angles(math.rad(-150), math.rad(25), math.rad(25)),
				elbow = CFrame.Angles(math.rad(-40), 0, math.rad(10)),
				wrist = CFrame.Angles(math.rad(-15), 0, math.rad(20)),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(70), math.rad(-30), math.rad(-35)),
				elbow = CFrame.Angles(math.rad(-55), 0, math.rad(-15)),
				wrist = CFrame.Angles(math.rad(30), 0, math.rad(-25)),
			}
		end
	else
		-- R6: shoulder only (approximate full arc)
		if idx == 1 then
			windup = {
				shoulder = CFrame.Angles(math.rad(60), 0, math.rad(110)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(-35), 0, math.rad(-120)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
		elseif idx == 2 then
			windup = {
				shoulder = CFrame.Angles(math.rad(100), 0, math.rad(70)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(-70), 0, math.rad(-85)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
		else
			windup = {
				shoulder = CFrame.Angles(math.rad(140), 0, math.rad(25)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
			strike = {
				shoulder = CFrame.Angles(math.rad(-85), 0, math.rad(-30)),
				elbow = CFrame.new(),
				wrist = CFrame.new(),
			}
		end
	end

	return windup, strike
end

-- Spirit Wave cast — right arm thrust forward / slightly up
local function castPose(isR15: boolean): Triple
	if isR15 then
		return {
			shoulder = CFrame.Angles(math.rad(-75), math.rad(-25), math.rad(-15)),
			elbow = CFrame.Angles(math.rad(-10), 0, 0),
			wrist = CFrame.Angles(math.rad(-20), 0, 0),
			leftShoulder = CFrame.Angles(math.rad(-40), math.rad(20), math.rad(25)),
		}
	end
	return {
		shoulder = CFrame.Angles(math.rad(-90), 0, math.rad(-20)),
		elbow = CFrame.new(),
		wrist = CFrame.new(),
		leftShoulder = CFrame.Angles(math.rad(-45), 0, math.rad(30)),
	}
end

-- Flash Step — brief arm tuck / readiness (shoulder in); legs untouched
local function flashPose(isR15: boolean): Triple
	if isR15 then
		return {
			shoulder = CFrame.Angles(math.rad(-25), math.rad(45), math.rad(55)),
			elbow = CFrame.Angles(math.rad(-95), math.rad(15), 0),
			wrist = CFrame.Angles(0, 0, math.rad(20)),
			leftShoulder = CFrame.Angles(math.rad(-20), math.rad(-40), math.rad(-50)),
		}
	end
	return {
		shoulder = CFrame.Angles(math.rad(25), 0, math.rad(70)),
		elbow = CFrame.new(),
		wrist = CFrame.new(),
		leftShoulder = CFrame.Angles(math.rad(20), 0, math.rad(-65)),
	}
end

-- Spirit Guard — arm raised across body (held while blocking)
local function guardPose(isR15: boolean): Triple
	if isR15 then
		return {
			shoulder = CFrame.Angles(math.rad(-70), math.rad(55), math.rad(75)),
			elbow = CFrame.Angles(math.rad(-90), math.rad(-20), math.rad(10)),
			wrist = CFrame.Angles(math.rad(-15), math.rad(30), math.rad(25)),
			leftShoulder = CFrame.Angles(math.rad(-35), math.rad(-30), math.rad(-40)),
		}
	end
	return {
		shoulder = CFrame.Angles(math.rad(80), 0, math.rad(90)),
		elbow = CFrame.new(),
		wrist = CFrame.new(),
		leftShoulder = CFrame.Angles(math.rad(40), 0, math.rad(-50)),
	}
end

--------------------------------------------------------------------------
-- Apply / reset
--------------------------------------------------------------------------

local function applyTriple(motors: ArmMotors, pose: Triple)
	if motors.shoulder and motors.shoulder.Parent then
		motors.shoulder.Transform = pose.shoulder
	end
	if motors.elbow and motors.elbow.Parent then
		motors.elbow.Transform = pose.elbow
	end
	if motors.wrist and motors.wrist.Parent then
		motors.wrist.Transform = pose.wrist
	end
	if pose.leftShoulder and motors.leftShoulder and motors.leftShoulder.Parent then
		motors.leftShoulder.Transform = pose.leftShoulder
	end
end

local function resetMotors(motors: ArmMotors)
	if motors.shoulder and motors.shoulder.Parent then
		motors.shoulder.Transform = CFrame.new()
	end
	if motors.elbow and motors.elbow.Parent then
		motors.elbow.Transform = CFrame.new()
	end
	if motors.wrist and motors.wrist.Parent then
		motors.wrist.Transform = CFrame.new()
	end
	if motors.leftShoulder and motors.leftShoulder.Parent then
		motors.leftShoulder.Transform = CFrame.new()
	end
	-- BladeMotor intentionally untouched — stays at identity grip from SwordService
end

local function clearAnim(character: Model, reset: boolean)
	local entry = active[character]
	if not entry then
		return
	end
	entry.conn:Disconnect()
	if reset then
		resetMotors(entry.motors)
	end
	active[character] = nil
end

local function sampleSwingTriple(windup: Triple, strike: Triple, elapsed: number): Triple
	if elapsed <= WINDUP_END then
		local a = smootherstep(elapsed / WINDUP_END)
		return {
			shoulder = lerpCF(CFrame.new(), windup.shoulder, a),
			elbow = lerpCF(CFrame.new(), windup.elbow, a),
			wrist = lerpCF(CFrame.new(), windup.wrist, a),
		}
	elseif elapsed <= STRIKE_END then
		local a = smootherstep((elapsed - WINDUP_END) / math.max(STRIKE_END - WINDUP_END, 0.001))
		return {
			shoulder = lerpCF(windup.shoulder, strike.shoulder, a),
			elbow = lerpCF(windup.elbow, strike.elbow, a),
			wrist = lerpCF(windup.wrist, strike.wrist, a),
		}
	else
		local a = smoothstep((elapsed - STRIKE_END) / math.max(SWING_TOTAL - STRIKE_END, 0.001))
		return {
			shoulder = lerpCF(strike.shoulder, CFrame.new(), a),
			elbow = lerpCF(strike.elbow, CFrame.new(), a),
			wrist = lerpCF(strike.wrist, CFrame.new(), a),
		}
	end
end

-- Timed pose: ease in → hold peak briefly → ease out to identity
local function sampleTimedPose(peak: Triple, elapsed: number, total: number, peakAt: number): Triple
	local easeIn = peakAt
	local easeOutStart = total * 0.55
	if elapsed <= easeIn then
		local a = smootherstep(elapsed / math.max(easeIn, 0.001))
		return {
			shoulder = lerpCF(CFrame.new(), peak.shoulder, a),
			elbow = lerpCF(CFrame.new(), peak.elbow, a),
			wrist = lerpCF(CFrame.new(), peak.wrist, a),
			leftShoulder = lerpCF(CFrame.new(), peak.leftShoulder or CFrame.new(), a),
		}
	elseif elapsed <= easeOutStart then
		return peak
	else
		local a = smoothstep((elapsed - easeOutStart) / math.max(total - easeOutStart, 0.001))
		return {
			shoulder = lerpCF(peak.shoulder, CFrame.new(), a),
			elbow = lerpCF(peak.elbow, CFrame.new(), a),
			wrist = lerpCF(peak.wrist, CFrame.new(), a),
			leftShoulder = lerpCF(peak.leftShoulder or CFrame.new(), CFrame.new(), a),
		}
	end
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
	trail.Lifetime = 0.16
	trail.MinLength = 0.04
	trail.FaceCamera = true
	trail.LightEmission = 0.15
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.04),
	})
	trail.Color = ColorSequence.new(Color3.fromRGB(200, 210, 220))
	trail.Parent = blade

	Debris:AddItem(a0, SWING_TOTAL + 0.2)
	Debris:AddItem(a1, SWING_TOTAL + 0.2)
	Debris:AddItem(trail, SWING_TOTAL + 0.2)
end

--------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------

function ArmAnimator.isPlaying(character: Model): boolean
	local entry = active[character]
	return entry ~= nil and entry.mode ~= "guard"
end

function ArmAnimator.isGuarding(character: Model): boolean
	local entry = active[character]
	return entry ~= nil and entry.mode == "guard"
end

function ArmAnimator.getElapsed(character: Model): number?
	local entry = active[character]
	if not entry or entry.mode ~= "swing" then
		return nil
	end
	return os.clock() - entry.start
end

function ArmAnimator.isInLateRecovery(character: Model): boolean
	local elapsed = ArmAnimator.getElapsed(character)
	if not elapsed then
		return false
	end
	local cancelAfter = Config.FlashStepCancelSwingAfter or STRIKE_END
	return elapsed >= cancelAfter
end

function ArmAnimator.cancel(character: Model)
	clearAnim(character, true)
end

local function beginStepped(
	character: Model,
	mode: Mode,
	motors: ArmMotors,
	duration: number?,
	onSample: (elapsed: number) -> Triple,
	combo: number?
)
	-- Guard holds indefinitely; don't tear down if already guarding unless replacing
	clearAnim(character, true)

	if not motors.shoulder and not motors.elbow then
		return
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
			clearAnim(character, true)
			return
		end

		local elapsed = os.clock() - start

		if mode == "guard" then
			applyTriple(motors, onSample(elapsed))
			return
		end

		local total = duration or SWING_TOTAL
		if elapsed >= total then
			resetMotors(motors)
			conn:Disconnect()
			if active[character] and active[character].token == token then
				active[character] = nil
			end
			return
		end

		applyTriple(motors, onSample(elapsed))
	end)

	active[character] = {
		conn = conn,
		token = token,
		start = start,
		mode = mode,
		motors = motors,
		combo = combo,
	}
end

function ArmAnimator.playSwing(character: Model, combo: number?)
	if not character or not character.Parent then
		return
	end
	-- Don't swing over an active guard pose
	local existing = active[character]
	if existing and existing.mode == "guard" then
		return
	end

	local index = combo or 1
	local motors = resolveMotors(character)
	local windup, strike = swingPoses(index, motors.isR15)

	local bladePart = findBladePart(character)
	if bladePart then
		attachBladeTrail(bladePart)
	end

	beginStepped(character, "swing", motors, SWING_TOTAL, function(elapsed)
		return sampleSwingTriple(windup, strike, elapsed)
	end, index)
end

-- Alias used by older call sites
function ArmAnimator.play(character: Model, combo: number?)
	ArmAnimator.playSwing(character, combo)
end

function ArmAnimator.playCast(character: Model)
	if not character or not character.Parent then
		return
	end
	local existing = active[character]
	if existing and existing.mode == "guard" then
		return
	end

	local motors = resolveMotors(character)
	local peak = castPose(motors.isR15)
	beginStepped(character, "cast", motors, CAST_TOTAL, function(elapsed)
		return sampleTimedPose(peak, elapsed, CAST_TOTAL, 0.12)
	end, nil)
end

function ArmAnimator.playFlashPose(character: Model)
	if not character or not character.Parent then
		return
	end
	local existing = active[character]
	if existing and existing.mode == "guard" then
		return
	end

	local motors = resolveMotors(character)
	local peak = flashPose(motors.isR15)
	beginStepped(character, "flash", motors, FLASH_TOTAL, function(elapsed)
		return sampleTimedPose(peak, elapsed, FLASH_TOTAL, 0.05)
	end, nil)
end

function ArmAnimator.setGuarding(character: Model, on: boolean)
	if not character or not character.Parent then
		return
	end
	if on then
		local motors = resolveMotors(character)
		local pose = guardPose(motors.isR15)
		beginStepped(character, "guard", motors, nil, function(_elapsed)
			return pose
		end, nil)
	else
		local entry = active[character]
		if entry and entry.mode == "guard" then
			clearAnim(character, true)
		end
	end
end

--------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------

local function hookLocalCharacter()
	if characterHooked then
		return
	end
	characterHooked = true
	local player = Players.LocalPlayer

	player.CharacterRemoving:Connect(function(character)
		clearAnim(character, true)
	end)

	player.CharacterAdded:Connect(function(character)
		for model in active do
			if not model.Parent then
				clearAnim(model, false)
			end
		end
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				clearAnim(character, true)
			end
		end)
	end)

	if player.Character then
		player.Character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				clearAnim(player.Character :: Model, true)
			end
		end)
	end
end

function ArmAnimator.start()
	hookLocalCharacter()
end

return ArmAnimator
