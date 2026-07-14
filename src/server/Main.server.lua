--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent:WaitForChild("Services")
local ServerDataService = require(services:WaitForChild("ServerDataService"))
local SessionRepository = require(services:WaitForChild("SessionRepository"))
local MemoryPersistenceAdapter = require(services:WaitForChild("MemoryPersistenceAdapter"))
local DataLifecycleService = require(services:WaitForChild("DataLifecycleService"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
assert(remotes ~= nil, "[LCA] ReplicatedStorage.Remotes is required")

local dataSync = remotes:FindFirstChild("DataSync")
local questSync = remotes:FindFirstChild("QuestSync")
assert(dataSync ~= nil and dataSync:IsA("RemoteEvent"), "[LCA] Remotes.DataSync must be a RemoteEvent")
assert(questSync ~= nil and questSync:IsA("RemoteEvent"), "[LCA] Remotes.QuestSync must be a RemoteEvent")

local function sendDataSync(player: Player, packet: any)
	dataSync:FireClient(player, packet)
end

local function sendQuestSync(player: Player, packet: any)
	questSync:FireClient(player, packet)
end

ServerDataService.init({
	sessions = SessionRepository,
	persistence = MemoryPersistenceAdapter,
	sendDataSync = sendDataSync,
	sendQuestSync = sendQuestSync,
})

DataLifecycleService.init({
	players = Players,
	dataService = ServerDataService,
})
