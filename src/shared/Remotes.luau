-- Ensures CombatRemotes folder + RemoteEvents exist (server creates; client waits).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "CombatRemotes"

local REMOTE_NAMES = {
	"RequestMelee",
	"RequestFlashStep",
	"RequestSpiritWave",
	"CombatFX",
	"SpiritPowerChanged",
}

local Remotes = {}

local function getOrCreateFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end
	if RunService:IsServer() then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	local waited = ReplicatedStorage:WaitForChild(FOLDER_NAME, 15)
	assert(waited and waited:IsA("Folder"), "CombatRemotes folder missing")
	return waited
end

function Remotes.get(name: string): RemoteEvent
	local folder = getOrCreateFolder()
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if RunService:IsServer() then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	local waited = folder:WaitForChild(name, 15)
	assert(waited and waited:IsA("RemoteEvent"), "RemoteEvent missing: " .. name)
	return waited
end

function Remotes.init()
	for _, name in REMOTE_NAMES do
		Remotes.get(name)
	end
end

return Remotes
