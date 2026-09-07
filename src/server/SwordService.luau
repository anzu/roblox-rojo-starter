-- Metal uchigatana + separate saya (scabbard) on back.
-- Bleach-inspired zanpakutō silhouette; player-facing name remains Spirit Blade.
-- Procedural Parts only — no neon / lightsaber look, no MeshId dependency.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwordService = {}

local KATANA_NAME = "SpiritBlade"
local SAYA_NAME = "SpiritSaya"
local ATTR_SHEATHED = "Sheathed"
local debugPrinted = false

-- Tunables from Config (fallback if older Config)
local SW = Config.Sword or {}

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
	shape: Enum.PartType?,
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
	if props.shape then
		p.Shape = props.shape
	end
	p.Parent = props.parent
	return p
end

local function makeWedge(props: {
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance,
	reflectance: number?,
}): WedgePart
	local p = Instance.new("WedgePart")
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

--------------------------------------------------------------------------
-- Saya (scabbard) — always on the back
--------------------------------------------------------------------------

local function buildSayaModel(): Model
	local model = Instance.new("Model")
	model.Name = SAYA_NAME

	-- Matching katana blade length (~4.6 studs) — dark lacquered wood look
	local body = makePart({
		name = "SayaBody",
		size = Vector3.new(0.34, 4.6, 0.30),
		color = Color3.fromRGB(22, 14, 10),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		reflectance = 0.08,
	})

	-- Koiguchi — mouth ring at the open end (+Y)
	local mouth = makePart({
		name = "Koiguchi",
		size = Vector3.new(0.42, 0.22, 0.38),
		color = Color3.fromRGB(40, 36, 34),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.28,
	})
	mouth.CFrame = body.CFrame * CFrame.new(0, 2.38, 0)
	weldConstraint(body, mouth)

	-- Soft inner lip so the mouth reads as a ring
	local mouthLip = makePart({
		name = "KoiguchiLip",
		size = Vector3.new(0.28, 0.12, 0.24),
		color = Color3.fromRGB(16, 10, 8),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		reflectance = 0.04,
	})
	mouthLip.CFrame = body.CFrame * CFrame.new(0, 2.22, 0)
	weldConstraint(body, mouthLip)

	-- Kojiri — end cap at the tip (-Y)
	local kojiri = makePart({
		name = "Kojiri",
		size = Vector3.new(0.36, 0.32, 0.32),
		color = Color3.fromRGB(32, 28, 26),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.22,
	})
	kojiri.CFrame = body.CFrame * CFrame.new(0, -2.42, 0)
	weldConstraint(body, kojiri)

	-- Sageo / mid band (fabric wrap accent)
	local band = makePart({
		name = "SayaBand",
		size = Vector3.new(0.38, 0.18, 0.34),
		color = Color3.fromRGB(48, 28, 18),
		material = Enum.Material.Fabric,
		parent = model,
	})
	band.CFrame = body.CFrame * CFrame.new(0, 0.55, 0)
	weldConstraint(body, band)

	-- Second accent ring near tip
	local band2 = makePart({
		name = "SayaBandLower",
		size = Vector3.new(0.36, 0.14, 0.32),
		color = Color3.fromRGB(36, 22, 14),
		material = Enum.Material.Fabric,
		parent = model,
	})
	band2.CFrame = body.CFrame * CFrame.new(0, -1.4, 0)
	weldConstraint(body, band2)

	model.PrimaryPart = body
	return model
end

--------------------------------------------------------------------------
-- Katana (drawn) — readable uchigatana from 10+ studs
-- Local +Y = tip direction; Handle is PrimaryPart at tsuka center
--------------------------------------------------------------------------

local function buildKatanaModel(): Model
	local model = Instance.new("Model")
	model.Name = KATANA_NAME

	-- Longer tsuka (~1.5 studs) for two-hand kenjutsu read
	local handle = makePart({
		name = "Handle",
		size = Vector3.new(0.28, 1.50, 0.28),
		color = Color3.fromRGB(28, 24, 22),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})

	-- Alternating ito wrap bands (Fabric / Plastic) for diamond-wrap look
	local itoColors = {
		Color3.fromRGB(38, 34, 32),
		Color3.fromRGB(52, 48, 46),
	}
	local itoMats = { Enum.Material.Fabric, Enum.Material.SmoothPlastic }
	local bandCount = 9
	local bandSpan = 1.28 -- along handle, leave room for kashira / fuchi
	local bandH = bandSpan / bandCount * 0.72
	local startY = -0.58
	for i = 1, bandCount do
		local t = (i - 1) / (bandCount - 1)
		local y = startY + t * bandSpan
		local idx = ((i - 1) % 2) + 1
		local wrap = makePart({
			name = "ItoBand" .. i,
			size = Vector3.new(0.34, bandH, 0.34),
			color = itoColors[idx],
			material = itoMats[idx],
			parent = model,
		})
		wrap.CFrame = handle.CFrame * CFrame.new(0, y, 0)
		weldConstraint(handle, wrap)
	end

	-- Kashira — metal pommel at butt of handle (-Y)
	local kashira = makePart({
		name = "Kashira",
		size = Vector3.new(0.20, 0.36, 0.36),
		color = Color3.fromRGB(72, 74, 80),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.32,
		shape = Enum.PartType.Cylinder,
	})
	-- Cylinder axis is local X; rotate so flat faces point along blade axis
	kashira.CFrame = handle.CFrame * CFrame.new(0, -0.82, 0) * CFrame.Angles(0, 0, math.rad(90))
	weldConstraint(handle, kashira)

	-- Fuchi — collar ring just below tsuba
	local fuchi = makePart({
		name = "Fuchi",
		size = Vector3.new(0.34, 0.12, 0.34),
		color = Color3.fromRGB(68, 70, 76),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.28,
	})
	fuchi.CFrame = handle.CFrame * CFrame.new(0, 0.72, 0)
	weldConstraint(handle, fuchi)

	-- Round tsuba (guard) — dark metal, wider than handle (reads from afar)
	local tsuba = makePart({
		name = "Tsuba",
		size = Vector3.new(0.10, 1.10, 1.10), -- Cylinder: height along X, then rotate
		color = Color3.fromRGB(48, 50, 56),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.35,
		shape = Enum.PartType.Cylinder,
	})
	tsuba.CFrame = handle.CFrame * CFrame.new(0, 0.82, 0) * CFrame.Angles(0, 0, math.rad(90))
	weldConstraint(handle, tsuba)

	-- Subtle hex accent plates on tsuba faces (reads as ornamental guard)
	local tsubaAccent = makePart({
		name = "TsubaAccent",
		size = Vector3.new(0.95, 0.04, 0.95),
		color = Color3.fromRGB(58, 60, 68),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.4,
	})
	tsubaAccent.CFrame = handle.CFrame * CFrame.new(0, 0.82, 0)
	weldConstraint(handle, tsubaAccent)

	-- Habaki — blade collar above tsuba (hidden when sheathed)
	local habaki = makePart({
		name = "Habaki",
		size = Vector3.new(0.26, 0.28, 0.18),
		color = Color3.fromRGB(160, 150, 110),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.45,
	})
	habaki.CFrame = handle.CFrame * CFrame.new(0, 1.02, 0)
	weldConstraint(handle, habaki)

	-- Main blade — longer & thinner (~4.6 × ~0.18 thick), steel Metal
	local bladeLen = 4.55
	local blade = makePart({
		name = "Blade",
		size = Vector3.new(0.20, bladeLen, 0.17),
		color = Color3.fromRGB(188, 194, 204),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.42,
	})
	-- Habaki top ~1.16; blade starts just above and extends to tip
	local bladeCenterY = 1.16 + bladeLen * 0.5
	blade.CFrame = handle.CFrame * CFrame.new(0, bladeCenterY, 0)
	weldConstraint(handle, blade)

	-- Darker spine (mune) strip — NOT Neon
	local spine = makePart({
		name = "BladeSpine",
		size = Vector3.new(0.05, bladeLen * 0.96, 0.14),
		color = Color3.fromRGB(110, 116, 128),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.25,
	})
	spine.CFrame = blade.CFrame * CFrame.new(-0.09, 0, 0)
	weldConstraint(blade, spine)

	-- Lighter edge (ha) strip — steel highlight, still Metal/Plastic not Neon
	local edge = makePart({
		name = "BladeEdge",
		size = Vector3.new(0.05, bladeLen * 0.94, 0.10),
		color = Color3.fromRGB(228, 232, 238),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		reflectance = 0.55,
	})
	edge.CFrame = blade.CFrame * CFrame.new(0.09, 0, 0)
	weldConstraint(blade, edge)

	-- Kissaki — angled tip wedge (reads as real katana tip)
	local kissaki = makeWedge({
		name = "Kissaki",
		size = Vector3.new(0.17, 0.48, 0.20),
		color = Color3.fromRGB(200, 206, 216),
		material = Enum.Material.Metal,
		parent = model,
		reflectance = 0.4,
	})
	-- Wedge: thick end toward blade, point toward tip. Orient so slope faces edge side.
	local tipY = bladeCenterY + bladeLen * 0.5 + 0.02
	kissaki.CFrame = handle.CFrame
		* CFrame.new(0, tipY, 0)
		* CFrame.Angles(0, math.rad(90), math.rad(90))
	weldConstraint(blade, kissaki)

	model.PrimaryPart = handle
	CollectionService:AddTag(model, CombatTypes.Tags.SpiritBlade)
	return model
end

--------------------------------------------------------------------------
-- Motors / C0
--------------------------------------------------------------------------

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

-- Shared back-mount orientation: diagonal across BACK.
-- Positive Z is character back on UpperTorso. Blade/saya long axis is local +Y.
-- 180° flip seats tip down-back; roll puts mouth near shoulder.
local function backMountAngles(): CFrame
	local pitch = SW.BackPitchDeg or 14
	local yaw = SW.BackYawDeg or 8
	local roll = SW.BackRollDeg or -38
	return CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll))
		* CFrame.Angles(math.rad(180), math.rad(0), 0)
end

local function sayaC0(): CFrame
	local o = SW.SayaOffset or Vector3.new(0.12, 0.22, 0.88)
	return CFrame.new(o.X, o.Y, o.Z) * backMountAngles()
end

-- Sheathed katana shares saya orientation; extra local-Y (pre-angle translation
-- in torso space is approximate — we also nudge along mount) so handle + tsuba
-- clear the koiguchi. Blade body is Transparency-hidden inside saya.
local function sheathedBladeC0(): CFrame
	local o = SW.SayaOffset or Vector3.new(0.12, 0.22, 0.88)
	local extra = SW.SheathedHandleExtra or Vector3.new(0.02, 0.72, 0.02)
	return CFrame.new(o.X + extra.X, o.Y + extra.Y, o.Z + extra.Z) * backMountAngles()
end

-- Drawn grip on RightHand / Right Arm — blade forward/up, natural kenjutsu hold.
local function unsheathedC0(hand: BasePart): CFrame
	if hand.Name == "RightHand" then
		local o = SW.DrawnR15Offset or Vector3.new(0, -0.12, 0.02)
		local grip = SW.DrawnR15GripAlong or -0.62 -- along handle toward tsuba from palm
		return CFrame.new(o.X, o.Y, o.Z)
			* CFrame.Angles(math.rad(-90), math.rad(90), 0)
			* CFrame.new(0, grip, 0)
	end
	-- R6 Right Arm
	local o = SW.DrawnR6Offset or Vector3.new(0, -1.05, -0.12)
	local grip = SW.DrawnR6GripAlong or -0.62
	return CFrame.new(o.X, o.Y, o.Z)
		* CFrame.Angles(math.rad(-90), math.rad(90), 0)
		* CFrame.new(0, grip, 0)
end

-- Blade-side parts hidden while sheathed (handle / ito / tsuba / kashira stay visible)
local BLADE_HIDE_NAMES = {
	Blade = true,
	BladeSpine = true,
	BladeEdge = true,
	Kissaki = true,
	Habaki = true,
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
		setBladeHidden(katana, true) -- handle / ito / tsuba / kashira stick out of saya mouth
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
