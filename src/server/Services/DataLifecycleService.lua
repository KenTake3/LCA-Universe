--!strict

export type DataService = {
	loadPlayer: (player: Player) -> (boolean, string),
	finalizePlayer: (player: Player, reason: "PlayerRemoving" | "Shutdown") -> (boolean, string),
}

export type Dependencies = {
	players: Players,
	dataService: DataService,
}

local DataLifecycleService = {}

local initialized = false
local configuredPlayers: Players? = nil
local configuredDataService: DataService? = nil
local closing = false
local managedPlayers: { [Player]: boolean } = {}
local finalizationStarted: { [Player]: boolean } = {}

local function validateDependencies(candidate: any): Dependencies
	if type(candidate) ~= "table" then
		error("DataLifecycleService.init requires a dependency table", 3)
	end

	local expectedKeys = {
		players = true,
		dataService = true,
	}
	for key in pairs(candidate) do
		if not expectedKeys[key] then
			error("DataLifecycleService.init received an unexpected dependency", 3)
		end
	end

	local players = candidate.players
	local dataService = candidate.dataService
	if typeof(players) ~= "Instance"
		or not players:IsA("Players")
		or type(dataService) ~= "table"
		or type(dataService.loadPlayer) ~= "function"
		or type(dataService.finalizePlayer) ~= "function"
	then
		error("DataLifecycleService.init received malformed dependencies", 3)
	end

	return table.freeze({
		players = players,
		dataService = dataService,
	}) :: Dependencies
end

local function loadPlayer(player: Player)
	if closing or managedPlayers[player] then
		return
	end
	managedPlayers[player] = true

	local dataService = configuredDataService :: DataService
	local callOk, loaded, result = pcall(dataService.loadPlayer, player)
	if not callOk then
		warn("[DataLifecycleService] loadPlayer raised for", player.UserId)
	elseif not loaded then
		warn("[DataLifecycleService] loadPlayer failed for", player.UserId, result)
	end
end

local function finalizePlayer(player: Player, reason: "PlayerRemoving" | "Shutdown")
	if finalizationStarted[player] then
		return
	end
	finalizationStarted[player] = true

	local dataService = configuredDataService :: DataService
	local callOk, finalized, result = pcall(dataService.finalizePlayer, player, reason)
	if not callOk then
		warn("[DataLifecycleService] finalizePlayer raised for", player.UserId, reason)
	elseif not finalized then
		warn("[DataLifecycleService] finalizePlayer failed for", player.UserId, reason, result)
	else
		managedPlayers[player] = nil
	end
end

function DataLifecycleService.init(candidate: Dependencies)
	local dependencies = validateDependencies(candidate)
	if initialized then
		if configuredPlayers == dependencies.players and configuredDataService == dependencies.dataService then
			return
		end
		error("DataLifecycleService is already initialized with different dependencies", 2)
	end

	initialized = true
	configuredPlayers = dependencies.players
	configuredDataService = dependencies.dataService

	dependencies.players.PlayerAdded:Connect(loadPlayer)
	dependencies.players.PlayerRemoving:Connect(function(player: Player)
		finalizePlayer(player, "PlayerRemoving")
	end)

	game:BindToClose(function()
		closing = true
		for player in pairs(managedPlayers) do
			finalizePlayer(player, "Shutdown")
		end
	end)

	for _, player in dependencies.players:GetPlayers() do
		loadPlayer(player)
	end
end

return table.freeze(DataLifecycleService)
