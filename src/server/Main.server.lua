--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local services = script.Parent:WaitForChild("Services")
local ServerDataService = require(services:WaitForChild("ServerDataService"))
local SessionRepository = require(services:WaitForChild("SessionRepository"))
local MemoryPersistenceAdapter = require(services:WaitForChild("MemoryPersistenceAdapter"))
local DataLifecycleService = require(services:WaitForChild("DataLifecycleService"))
local GameplayService = require(services:WaitForChild("GameplayService"))
local GameplayRemoteController = require(services:WaitForChild("GameplayRemoteController"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
assert(remotes ~= nil, "[LCA] ReplicatedStorage.Remotes is required")

local dataSync = remotes:FindFirstChild("DataSync")
local questSync = remotes:FindFirstChild("QuestSync")
local pressCore = remotes:FindFirstChild("PressCore")
local pressFeedback = remotes:FindFirstChild("PressFeedback")
local buyUpgrade = remotes:FindFirstChild("BuyUpgrade")
assert(dataSync ~= nil and dataSync:IsA("RemoteEvent"), "[LCA] Remotes.DataSync must be a RemoteEvent")
assert(questSync ~= nil and questSync:IsA("RemoteEvent"), "[LCA] Remotes.QuestSync must be a RemoteEvent")
assert(pressCore ~= nil and pressCore:IsA("RemoteEvent"), "[LCA] Remotes.PressCore must be a RemoteEvent")
assert(pressFeedback ~= nil and pressFeedback:IsA("RemoteEvent"), "[LCA] Remotes.PressFeedback must be a RemoteEvent")
assert(buyUpgrade ~= nil and buyUpgrade:IsA("RemoteEvent"), "[LCA] Remotes.BuyUpgrade must be a RemoteEvent")

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

GameplayService.init({
	sessions = SessionRepository,
	dataService = ServerDataService,
})

GameplayRemoteController.init({
	pressCore = pressCore,
	pressFeedback = pressFeedback,
	buyUpgrade = buyUpgrade,
	gameplayService = GameplayService,
})

DataLifecycleService.init({
	players = Players,
	dataService = ServerDataService,
})
