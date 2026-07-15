--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local services = script.Parent:WaitForChild("Services")
local ServerDataService = require(services:WaitForChild("ServerDataService"))
local SessionRepository = require(services:WaitForChild("SessionRepository"))
local MemoryPersistenceAdapter = require(services:WaitForChild("MemoryPersistenceAdapter"))
local DataLifecycleService = require(services:WaitForChild("DataLifecycleService"))
local GameplayService = require(services:WaitForChild("GameplayService"))
local GameplayRemoteController = require(services:WaitForChild("GameplayRemoteController"))
local AutoPowerScheduler = require(services:WaitForChild("AutoPowerScheduler"))

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
assert(remotes ~= nil, "[LCA] ReplicatedStorage.Remotes is required")

local dataSync = remotes:FindFirstChild("DataSync")
local questSync = remotes:FindFirstChild("QuestSync")
local pressCore = remotes:FindFirstChild("PressCore")
local pressFeedback = remotes:FindFirstChild("PressFeedback")
local buyUpgrade = remotes:FindFirstChild("BuyUpgrade")
local requestRebirth = remotes:FindFirstChild("RequestRebirth")
assert(dataSync ~= nil and dataSync:IsA("RemoteEvent"), "[LCA] Remotes.DataSync must be a RemoteEvent")
assert(questSync ~= nil and questSync:IsA("RemoteEvent"), "[LCA] Remotes.QuestSync must be a RemoteEvent")
assert(pressCore ~= nil and pressCore:IsA("RemoteEvent"), "[LCA] Remotes.PressCore must be a RemoteEvent")
assert(pressFeedback ~= nil and pressFeedback:IsA("RemoteEvent"), "[LCA] Remotes.PressFeedback must be a RemoteEvent")
assert(buyUpgrade ~= nil and buyUpgrade:IsA("RemoteEvent"), "[LCA] Remotes.BuyUpgrade must be a RemoteEvent")
assert(requestRebirth ~= nil and requestRebirth:IsA("RemoteEvent"), "[LCA] Remotes.RequestRebirth must be a RemoteEvent")

local function sendDataSync(player: Player, packet: any)
	dataSync:FireClient(player, packet)
end

local function sendQuestSync(player: Player, packet: any)
	questSync:FireClient(player, packet)
end

local serverDataSessions: ServerDataService.SessionRepository = {
	createSession = SessionRepository.createSession,
	getSession = SessionRepository.getSession,
	removeSession = SessionRepository.removeSession,
	getDefaultData = SessionRepository.getDefaultData,
	migrateData = SessionRepository.migrateData,
	buildSyncPacket = SessionRepository.buildSyncPacket,
	buildQuestSyncPacket = SessionRepository.buildQuestSyncPacket,
}
local persistenceAdapter: ServerDataService.PersistenceAdapter = {
	read = MemoryPersistenceAdapter.read,
	write = MemoryPersistenceAdapter.write,
}
local gameplaySessions: GameplayService.SessionRepository = {
	getSession = SessionRepository.getSession,
}
local gameplayDataService: GameplayService.DataService = {
	markDirty = ServerDataService.markDirty,
	syncToClient = ServerDataService.syncToClient,
}
local remoteGameplayService: GameplayRemoteController.GameplayService = {
	press = GameplayService.press,
	buyUpgrade = GameplayService.buyUpgrade,
	rebirth = GameplayService.rebirth,
}
local autoPowerGameplayService: AutoPowerScheduler.GameplayService = {
	applyAutoPowerTick = GameplayService.applyAutoPowerTick,
}
local lifecycleDataService: DataLifecycleService.DataService = {
	loadPlayer = ServerDataService.loadPlayer,
	finalizePlayer = ServerDataService.finalizePlayer,
}

ServerDataService.init({
	sessions = serverDataSessions,
	persistence = persistenceAdapter,
	sendDataSync = sendDataSync,
	sendQuestSync = sendQuestSync,
})

GameplayService.init({
	sessions = gameplaySessions,
	dataService = gameplayDataService,
})

GameplayRemoteController.init({
	pressCore = pressCore,
	pressFeedback = pressFeedback,
	buyUpgrade = buyUpgrade,
	requestRebirth = requestRebirth,
	gameplayService = remoteGameplayService,
})

AutoPowerScheduler.init({
	players = Players,
	runService = RunService,
	gameplayService = autoPowerGameplayService,
})

DataLifecycleService.init({
	players = Players,
	dataService = lifecycleDataService,
})
