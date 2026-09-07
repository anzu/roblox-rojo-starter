-- Obvious katana-style spirit blade: Model + Motor6D weld to back (sheathed) or right hand.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwordService = {}

local MODEL_NAME = "SpiritBlade"
local ATTR_SHEATHED = "Sheathed"

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
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.Color = props.color
	p.Material = props.material
	p.Transparency = 0 -- MUST be visible
	p.Reflectance = 0.15
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

-- Build a chunky, unmistakable katana (handle + guard + blade + neon edge).
local function buildKatanaModel(): Model
	local model = Instance.new("Model")
	model.Name = MODEL_NAME

	-- Root / grip reference (slightly larger handle so it's obvious)
	local handle = makePart({
		name = "Handle",
		size = Vector3.new(0.45, 1.35, 0.45),
		color = Color3.fromRGB(28, 32, 48),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})

	local wrap = makePart({
		name = "HandleWrap",
		size = Vector3.new(0.5, 0.55, 0.5),
		color = Color3.fromRGB(70, 90, 130),
		material = Enum.Material.Fabric,
		parent = model,
	})
	wrap.CFrame = handle.CFrame * CFrame.new(0, 0.15, 0)
	weldConstraint(handle, wrap)

	local pommel = makePart({
		name = "Pommel",
		size = Vector3.new(0.55, 0.35, 0.55),
		color = Color3.fromRGB(180, 210, 255),
		material = Enum.Material.Metal,
		parent = model,
	})
	pommel.CFrame = handle.CFrame * CFrame.new(0, -0.75, 0)
	weldConstraint(handle, pommel)

	local guard = makePart({
		name = "Guard",
		size = Vector3.new(1.35, 0.22, 0.7),
		color = Color3.fromRGB(200, 230, 255),
		material = Enum.Material.Metal,
		parent = model,
	})
	guard.CFrame = handle.CFrame * CFrame.new(0, 0.78, 0)
	weldConstraint(handle, guard)

	-- Main blade body (large, bright)
	local blade = makePart({
		name = "Blade",
		size = Vector3.new(0.38, 4.6, 0.16),
		color = Color3.fromRGB(140, 210, 255),
		material = Enum.Material.Neon,
		parent = model,
	})
	blade.CFrame = handle.CFrame * CFrame.new(0, 3.15, 0)
	weldConstraint(handle, blade)

	-- White neon cutting edge (extra obvious)
	local edge = makePart({
		name = "NeonEdge",
		size = Vector3.new(0.12, 4.4, 0.08),
		color = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		parent = model,
	})
	edge.CFrame = blade.CFrame * CFrame.new(0.18, 0, 0)
	weldConstraint(blade, edge)

	-- Tip accent
	local tip = makePart({
		name = "Tip",
		size = Vector3.new(0.32, 0.55, 0.14),
		color = Color3.fromRGB(220, 245, 255),
		material = Enum.Material.Neon,
		parent = model,
	})
	tip.CFrame = blade.CFrame * CFrame.new(0, 2.4, 0)
	weldConstraint(blade, tip)

	-- Glow so it reads at distance
	local light = Instance.new("PointLight")
	light.Name = "BladeGlow"
	light.Color = Color3.fromRGB(160, 220, 255)
	light.Brightness = 2.2
	light.Range = 10
	light.Parent = blade

	model.PrimaryPart = handle
	CollectionService:AddTag(model, CombatTypes.Tags.SpiritBlade)
	return model
end

local function getMotor(model: Model): Motor6D
	local existing = model:FindFirstChild("BladeMotor")
	if existing and existing:IsA("Motor6D") then
		return existing
	end
	local motor = Instance.new("Motor6D")
	motor.Name = "BladeMotor"
	motor.Parent = model
	return motor
end

-- Sheathed: across the back, clearly sticking out behind torso
local function sheathedC0(): CFrame
	return CFrame.new(0, 0.55, 0.95)
		* CFrame.Angles(0, math.rad(90), 0)
		* CFrame.Angles(math.rad(-15), 0, math.rad(40))
		* CFrame.new(0, -0.4, 0)
end

-- Unsheathed: blade extending forward/up from right hand — visible in front of character
local function unsheathedC0(hand: BasePart): CFrame
	if hand.Name == "RightHand" then
		-- R15: grip in palm, blade out along fingers / forward
		return CFrame.new(0, -0.1, 0)
			* CFrame.Angles(math.rad(90), 0, 0)
			* CFrame.Angles(0, math.rad(90), 0)
			* CFrame.new(0, -0.9, 0)
	end
	-- R6 Right Arm: from lower arm outward
	return CFrame.new(0, -1.0, 0)
		* CFrame.Angles(math.rad(90), 0, 0)
		* CFrame.Angles(0, math.rad(90), 0)
		* CFrame.new(0, -0.9, 0)
end

local function assertVisible(model: Model)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			inst.Transparency = 0
			inst.LocalTransparencyModifier = 0
		end
	end
end

function SwordService.isSheathed(character: Model): boolean
	local attr = character:GetAttribute(ATTR_SHEATHED)
	if typeof(attr) == "boolean" then
		return attr
	end
	return true
end

function SwordService.applySheathState(character: Model, sheathed: boolean)
	local model = character:FindFirstChild(MODEL_NAME)
	if not model or not model:IsA("Model") then
		model = buildKatanaModel()
		model.Parent = character
	end
	assertVisible(model)

	local handle = model.PrimaryPart or model:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		warn("[SwordService] SpiritBlade missing Handle")
		return
	end

	local motor = getMotor(model)
	motor.Part1 = handle
	character:SetAttribute(ATTR_SHEATHED, sheathed)

	if sheathed then
		local torso = findTorso(character)
		if not torso then
			warn("[SwordService] No torso for sheath weld")
			return
		end
		motor.Part0 = torso
		motor.C0 = sheathedC0()
		motor.C1 = CFrame.new()
	else
		local hand = findRightHand(character)
		if not hand then
			warn("[SwordService] No right hand for unsheath weld")
			return
		end
		motor.Part0 = hand
		motor.C0 = unsheathedC0(hand)
		motor.C1 = CFrame.new()
	end

	-- Nudge assembly so clients see the attachment immediately
	handle.AssemblyLinearVelocity = Vector3.zero
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

		-- Destroy any stale blade
		local old = character:FindFirstChild(MODEL_NAME)
		if old then
			old:Destroy()
		end

		local model = buildKatanaModel()
		model.Parent = character
		assertVisible(model)
		SwordService.applySheathState(character, true)

		-- Sanity log for Studio Output
		local parts = 0
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 0.05 then
				parts += 1
			end
		end
		print(string.format("[SwordService] Equipped SpiritBlade on %s (%d visible parts, sheathed)", character.Name, parts))
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
