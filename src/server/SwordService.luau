-- Metal katana + separate saya (scabbard) on back. No neon / lightsaber look.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwordService = {}

local KATANA_NAME = "SpiritBlade"
local SAYA_NAME = "SpiritSaya"
local ATTR_SHEATHED = "Sheathed"
local debugPrinted = false

local function findTorso(character: Model): BasePart?
	local upper = character:FindFirstChild("UpperTorso")
	if upper and upper:IsA("BasePart") then
		return upper
	end
	local torso = character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function findRightHand(character: Model): BasePart?
	local hand = character:FindFirstChild("RightHand")
	if hand and hand:IsA("BasePart") then
		return hand
	end
	local arm = character:FindFirstChild("Right Arm")
	if arm and arm:IsA("BasePart") then
		return arm
	end
	return nil
end

local function makePart(props: {
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	reflectance: number?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.Color = props.color
	p.Material = props.material
	p.Transparency = 0
	p.Reflectance = props.reflectance or 0
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = props.parent
	return p
end

local function weldConstraint(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- Dark brown/black scabbard — always on the back.
local function buildSayaModel(): Model
	local model = Instance.new("Model")
	model.Name = SAYA_NAME

	local body = makePart({
		name = "SayaBody",
		size = Vector3.new(0.32, 4.0, 0.28),
		color = Color3.fromRGB(28, 18, 12),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		reflectance = 0.05,
	})

	local mouth = makePart({
		name = "SayaMouth",
		size = Vector3.new(0.38, 0.28, 0.34),
		color = Color3.fromRGB(18, 12, 8),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.2,
	})
	mouth.CFrame = body.CFrame * CFrame.new(0, 2.05, 0)
	weldConstraint(body, mouth)

	local tip = makePart({
		name = "SayaTip",
		size = Vector3.new(0.3, 0.35, 0.26),
		color = Color3.fromRGB(22, 14, 10),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	tip.CFrame = body.CFrame * CFrame.new(0, -2.1, 0)
	weldConstraint(body, tip)

	local band = makePart({
		name = "SayaBand",
		size = Vector3.new(0.36, 0.2, 0.32),
		color = Color3.fromRGB(50, 30, 18),
		material = Enum.Material.Fabric,
		parent = model,
	})
	band.CFrame = body.CFrame * CFrame.new(0, 0.6, 0)
	weldConstraint(body, band)

	model.PrimaryPart = body
	return model
end

-- Normal metal katana: steel blade, dark ito wrap, simple tsuba. NO neon / PointLight.
local function buildKatanaModel(): Model
	local model = Instance.new("Model")
	model.Name = KATANA_NAME

	local handle = makePart({
		name = "Handle",
		size = Vector3.new(0.32, 1.15, 0.32),
		color = Color3.fromRGB(32, 28, 26),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})

	local wrap = makePart({
		name = "ItoWrap",
		size = Vector3.new(0.36, 0.95, 0.36),
		color = Color3.fromRGB(45, 40, 38),
		material = Enum.Material.Fabric,
		parent = model,
	})
	wrap.CFrame = handle.CFrame * CFrame.new(0, 0.05, 0)
	weldConstraint(handle, wrap)

	local pommel = makePart({
		name = "Pommel",
		size = Vector3.new(0.38, 0.22, 0.38),
		color = Color3.fromRGB(90, 90, 95),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.25,
	})
	pommel.CFrame = handle.CFrame * CFrame.new(0, -0.62, 0)
	weldConstraint(handle, pommel)

	-- Simple round-ish tsuba
	local guard = makePart({
		name = "Tsuba",
		size = Vector3.new(0.95, 0.12, 0.95),
		color = Color3.fromRGB(70, 72, 78),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.3,
	})
	guard.CFrame = handle.CFrame * CFrame.new(0, 0.62, 0)
	weldConstraint(handle, guard)

	local blade = makePart({
		name = "Blade",
		size = Vector3.new(0.22, 3.9, 0.08),
		color = Color3.fromRGB(190, 195, 205),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.45,
	})
	blade.CFrame = handle.CFrame * CFrame.new(0, 2.7, 0)
	weldConstraint(handle, blade)

	local edge = makePart({
		name = "BladeEdge",
		size = Vector3.new(0.06, 3.7, 0.05),
		color = Color3.fromRGB(220, 225, 230),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		reflectance = 0.55,
	})
	edge.CFrame = blade.CFrame * CFrame.new(0.1, 0, 0)
	weldConstraint(blade, edge)

	local tip = makePart({
		name = "BladeTip",
		size = Vector3.new(0.18, 0.4, 0.07),
		color = Color3.fromRGB(200, 205, 215),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.4,
	})
	tip.CFrame = blade.CFrame * CFrame.new(0, 2.05, 0)
	weldConstraint(blade, tip)

	model.PrimaryPart = handle
	CollectionService:AddTag(model, CombatTypes.Tags.SpiritBlade)
	return model
end

local function getMotor(model: Model, name: string): Motor6D
	local existing = model:FindFirstChild(name)
	if existing and existing:IsA("Motor6D") then
		return existing
	end
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Parent = model
	return motor
end

-- Saya on UpperTorso/Torso: diagonal across BACK, mouth near right shoulder, tip toward left hip.
-- Positive Z is character back. Blade/saya long axis is local +Y.
local function sayaC0(): CFrame
	return CFrame.new(0.05, 0.15, 0.78)
		* CFrame.Angles(math.rad(12), math.rad(0), math.rad(-32))
		* CFrame.Angles(math.rad(180), math.rad(0), 0)
end

-- Sheathed katana: same back mount as saya; handle sticks out the mouth (near shoulder).
local function sheathedBladeC0(): CFrame
	-- Slightly raised so handle/tsuba clear the saya mouth; blade body sits inside saya.
	return CFrame.new(0.05, 0.55, 0.78)
		* CFrame.Angles(math.rad(12), math.rad(0), math.rad(-32))
		* CFrame.Angles(math.rad(180), math.rad(0), 0)
end

-- Drawn grip on RightHand / Right Arm — blade forward-up, not through the arm.
local function unsheathedC0(hand: BasePart): CFrame
	if hand.Name == "RightHand" then
		-- R15: palm grip, blade extends along fingers / forward
		return CFrame.new(0, -0.15, 0)
			* CFrame.Angles(math.rad(-90), math.rad(90), 0)
			* CFrame.new(0, -0.55, 0)
	end
	-- R6 Right Arm
	return CFrame.new(0, -1.05, -0.15)
		* CFrame.Angles(math.rad(-90), math.rad(90), 0)
		* CFrame.new(0, -0.55, 0)
end

local BLADE_HIDE_NAMES = {
	Blade = true,
	BladeEdge = true,
	BladeTip = true,
}

local function setBladeHidden(model: Model, hidden: boolean)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			if BLADE_HIDE_NAMES[inst.Name] then
				inst.Transparency = if hidden then 1 else 0
			else
				inst.Transparency = 0
			end
			inst.LocalTransparencyModifier = 0
		end
	end
end

local function ensureSaya(character: Model, torso: BasePart): Model
	local existing = character:FindFirstChild(SAYA_NAME)
	if existing and existing:IsA("Model") then
		local motor = getMotor(existing, "SayaMotor")
		local body = existing.PrimaryPart or existing:FindFirstChild("SayaBody")
		if body and body:IsA("BasePart") then
			motor.Part0 = torso
			motor.Part1 = body
			motor.C0 = sayaC0()
			motor.C1 = CFrame.new()
		end
		return existing
	end

	local saya = buildSayaModel()
	saya.Parent = character
	local body = saya.PrimaryPart :: BasePart
	local motor = getMotor(saya, "SayaMotor")
	motor.Part0 = torso
	motor.Part1 = body
	motor.C0 = sayaC0()
	motor.C1 = CFrame.new()
	return saya
end

local function printDebugOnce(character: Model, katana: Model, saya: Model, torso: BasePart, sheathed: boolean)
	if debugPrinted then
		return
	end
	debugPrinted = true
	local bladeMotor = katana:FindFirstChild("BladeMotor")
	local sayaMotor = saya:FindFirstChild("SayaMotor")
	local hand = findRightHand(character)
	print(string.format(
		"[SwordService] Motor6D debug | torso=%s hand=%s sheathed=%s\n  Saya C0=%s\n  Blade C0=%s\n  Blade Part0=%s",
		torso.Name,
		if hand then hand.Name else "nil",
		tostring(sheathed),
		tostring(if sayaMotor and sayaMotor:IsA("Motor6D") then sayaMotor.C0 else nil),
		tostring(if bladeMotor and bladeMotor:IsA("Motor6D") then bladeMotor.C0 else nil),
		tostring(if bladeMotor and bladeMotor:IsA("Motor6D") then bladeMotor.Part0 else nil)
	))
end

function SwordService.isSheathed(character: Model): boolean
	local attr = character:GetAttribute(ATTR_SHEATHED)
	if typeof(attr) == "boolean" then
		return attr
	end
	return true
end

function SwordService.applySheathState(character: Model, sheathed: boolean)
	local torso = findTorso(character)
	if not torso then
		warn("[SwordService] No torso for sheath weld")
		return
	end

	local saya = ensureSaya(character, torso)

	local katana = character:FindFirstChild(KATANA_NAME)
	if not katana or not katana:IsA("Model") then
		katana = buildKatanaModel()
		katana.Parent = character
	end

	local handle = katana.PrimaryPart or katana:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("[SwordService] SpiritBlade missing Handle")
		return
	end

	local motor = getMotor(katana, "BladeMotor")
	motor.Part1 = handle
	character:SetAttribute(ATTR_SHEATHED, sheathed)

	if sheathed then
		motor.Part0 = torso
		motor.C0 = sheathedBladeC0()
		motor.C1 = CFrame.new()
		setBladeHidden(katana, true) -- only handle/tsuba/pommel visible sticking from saya
	else
		local hand = findRightHand(character)
		if not hand then
			warn("[SwordService] No right hand for unsheath weld")
			return
		end
		motor.Part0 = hand
		motor.C0 = unsheathedC0(hand)
		motor.C1 = CFrame.new()
		setBladeHidden(katana, false)
	end

	-- Saya always stays on the back (empty when drawn)
	ensureSaya(character, torso)

	handle.AssemblyLinearVelocity = Vector3.zero
	printDebugOnce(character, katana, saya, torso, sheathed)
end

function SwordService.setSheathed(character: Model, sheathed: boolean)
	SwordService.applySheathState(character, sheathed)
	local player = Players:GetPlayerFromCharacter(character)
	Remotes.get("CombatFX"):FireAllClients({
		kind = CombatTypes.Fx.Sheath,
		sheathed = sheathed,
		userId = if player then player.UserId else nil,
	})
end

function SwordService.toggle(character: Model): boolean
	local nextState = not SwordService.isSheathed(character)
	SwordService.setSheathed(character, nextState)
	return nextState
end

function SwordService.ensureUnsheathed(character: Model)
	if SwordService.isSheathed(character) then
		SwordService.setSheathed(character, false)
	end
end

local function onCharacter(character: Model)
	task.spawn(function()
		if not character.Parent then
			return
		end
		character:WaitForChild("Humanoid", 8)

		local deadline = os.clock() + 5
		while character.Parent and os.clock() < deadline do
			if findTorso(character) and findRightHand(character) then
				break
			end
			task.wait(0.05)
		end
		if not character.Parent then
			return
		end

		local oldBlade = character:FindFirstChild(KATANA_NAME)
		if oldBlade then
			oldBlade:Destroy()
		end
		local oldSaya = character:FindFirstChild(SAYA_NAME)
		if oldSaya then
			oldSaya:Destroy()
		end

		local katana = buildKatanaModel()
		katana.Parent = character
		SwordService.applySheathState(character, true)

		local visible = 0
		for _, d in katana:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.05 then
				visible += 1
			end
		end
		local saya = character:FindFirstChild(SAYA_NAME)
		local sayaParts = 0
		if saya then
			for _, d in saya:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.05 then
					sayaParts += 1
				end
			end
		end
		print(string.format(
			"[SwordService] Equipped metal katana + saya on %s (%d handle parts visible, %d saya parts, sheathed)",
			character.Name,
			visible,
			sayaParts
		))
	end)
end

function SwordService.handleToggle(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	SwordService.toggle(character)
end

function SwordService.start()
	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			onCharacter(player.Character)
		end
	end

	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end

	Remotes.get("RequestToggleSheath").OnServerEvent:Connect(function(player)
		SwordService.handleToggle(player)
	end)
end

return SwordService
