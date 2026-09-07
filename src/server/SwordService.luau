-- Creates a welded spirit blade on spawn; toggles sheathed (back) / unsheathed (right hand).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.CombatTypes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local SwordService = {}

local BLADE_NAME = "SpiritBlade"

local function findTorso(character: Model): BasePart?
	local upper = character:FindFirstChild("UpperTorso")
	if upper and upper:IsA("BasePart") then
		return upper
	end
	local torso = character:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
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

local function getOrCreateWeld(blade: BasePart): Weld
	local existing = blade:FindFirstChild("BladeWeld")
	if existing and existing:IsA("Weld") then
		return existing
	end
	local weld = Instance.new("Weld")
	weld.Name = "BladeWeld"
	weld.Parent = blade
	return weld
end

local function sheathedOffset(): CFrame
	-- On back, angled like a katana
	return CFrame.new(0, 0.35, 0.85) * CFrame.Angles(0, 0, math.rad(25)) * CFrame.Angles(math.rad(90), 0, 0)
end

local function unsheathedOffset(hand: BasePart): CFrame
	if hand.Name == "RightHand" then
		return CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	end
	-- R6 Right Arm
	return CFrame.new(0, -1.1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function weldRelative(part0: BasePart, part1: BasePart, offset: CFrame)
	part1.CFrame = part0.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part1
end

local function createBlade(character: Model): BasePart
	local existing = character:FindFirstChild(BLADE_NAME)
	if existing and existing:IsA("BasePart") then
		return existing
	end

	local blade = Instance.new("Part")
	blade.Name = BLADE_NAME
	blade.Size = Vector3.new(0.28, 4.2, 0.12)
	blade.Material = Enum.Material.Neon
	blade.Color = Color3.fromRGB(160, 230, 255)
	blade.CanCollide = false
	blade.CanQuery = false
	blade.CanTouch = false
	blade.Massless = true
	blade.CastShadow = true
	blade.Anchored = false
	blade.Parent = character

	local tip = Instance.new("Part")
	tip.Name = "BladeEdge"
	tip.Size = Vector3.new(0.14, 3.6, 0.06)
	tip.Material = Enum.Material.Neon
	tip.Color = Color3.fromRGB(255, 255, 255)
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CanTouch = false
	tip.Massless = true
	tip.Anchored = false
	tip.Parent = character
	weldRelative(blade, tip, CFrame.new())

	local handle = Instance.new("Part")
	handle.Name = "Hilt"
	handle.Size = Vector3.new(0.35, 0.7, 0.35)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Color = Color3.fromRGB(40, 45, 60)
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.Anchored = false
	handle.Parent = character
	weldRelative(blade, handle, CFrame.new(0, -2.0, 0))

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.9, 0.12, 0.45)
	guard.Material = Enum.Material.Metal
	guard.Color = Color3.fromRGB(180, 220, 255)
	guard.CanCollide = false
	guard.CanQuery = false
	guard.CanTouch = false
	guard.Massless = true
	guard.Anchored = false
	guard.Parent = character
	weldRelative(blade, guard, CFrame.new(0, -1.55, 0))

	CollectionService:AddTag(blade, CombatTypes.Tags.SpiritBlade)
	getOrCreateWeld(blade)
	return blade
end

function SwordService.isSheathed(character: Model): boolean
	local attr = character:GetAttribute("Sheathed")
	if typeof(attr) == "boolean" then
		return attr
	end
	return true
end

function SwordService.applySheathState(character: Model, sheathed: boolean)
	local blade = character:FindFirstChild(BLADE_NAME)
	if not blade or not blade:IsA("BasePart") then
		blade = createBlade(character)
	end

	local weld = getOrCreateWeld(blade)
	character:SetAttribute("Sheathed", sheathed)

	if sheathed then
		local torso = findTorso(character)
		if not torso then
			return
		end
		weld.Part0 = torso
		weld.Part1 = blade
		weld.C0 = sheathedOffset()
		weld.C1 = CFrame.new()
	else
		local hand = findRightHand(character)
		if not hand then
			return
		end
		weld.Part0 = hand
		weld.Part1 = blade
		weld.C0 = unsheathedOffset(hand)
		weld.C1 = CFrame.new()
	end
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
	task.defer(function()
		if not character.Parent then
			return
		end
		character:WaitForChild("Humanoid", 5)
		local deadline = os.clock() + 3
		while character.Parent and os.clock() < deadline do
			if findTorso(character) and findRightHand(character) then
				break
			end
			task.wait(0.05)
		end
		if not character.Parent then
			return
		end
		createBlade(character)
		SwordService.applySheathState(character, true)
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
