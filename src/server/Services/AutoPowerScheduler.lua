--!strict

export type GameplayService = {
	applyAutoPowerTick: (player: Player) -> (boolean, string, any?),
}

export type Dependencies = {
	players: Players,
	runService: RunService,
	gameplayService: GameplayService,
}

local AutoPowerScheduler = {}

-- RECOVERY_PROVISIONAL: WP-10 approves one authoritative production tick per
-- second; the original scheduler implementation was not recovered.
local INTERVAL_SECONDS = 1
-- RECOVERY_PROVISIONAL: discard whole intervals beyond five per Heartbeat to
-- bound recovery after an extreme server frame stall.
local MAX_TICKS_PER_HEARTBEAT = 5

local dependencies: Dependencies? = nil
-- Retain the single connection for a future lifecycle-owned stop() contract.
local heartbeatConnection: RBXScriptConnection? = nil
local accumulator = 0

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function validateDependencies(candidate: any): Dependencies
	if type(candidate) ~= "table" then
		error("AutoPowerScheduler.init requires a dependency table", 3)
	end
	local expectedKeys = { players = true, runService = true, gameplayService = true }
	for key in pairs(candidate) do
		if not expectedKeys[key] then
			error("AutoPowerScheduler.init received an unexpected dependency", 3)
		end
	end

	local players = candidate.players
	local runService = candidate.runService
	local gameplayService = candidate.gameplayService
	if typeof(players) ~= "Instance"
		or not players:IsA("Players")
		or typeof(runService) ~= "Instance"
		or not runService:IsA("RunService")
		or type(gameplayService) ~= "table"
		or type(gameplayService.applyAutoPowerTick) ~= "function"
	then
		error("AutoPowerScheduler.init received malformed dependencies", 3)
	end

	return table.freeze({
		players = players,
		runService = runService,
		gameplayService = gameplayService,
	}) :: Dependencies
end

local function tickAllPlayers()
	local configured = dependencies :: Dependencies
	for _, player in configured.players:GetPlayers() do
		local callSucceeded = pcall(function()
			configured.gameplayService.applyAutoPowerTick(player)
		end)
		if not callSucceeded then
			warn("[AutoPowerScheduler] applyAutoPowerTick raised")
		end
	end
end

local function onHeartbeat(deltaTime: number)
	if not isFiniteNumber(deltaTime) or deltaTime <= 0 then
		return
	end
	accumulator += deltaTime

	local completedTicks = 0
	while accumulator >= INTERVAL_SECONDS and completedTicks < MAX_TICKS_PER_HEARTBEAT do
		accumulator -= INTERVAL_SECONDS
		completedTicks += 1
		tickAllPlayers()
	end
	if accumulator >= INTERVAL_SECONDS then
		accumulator %= INTERVAL_SECONDS
	end
end

function AutoPowerScheduler.init(candidate: Dependencies)
	local validated = validateDependencies(candidate)
	if dependencies ~= nil then
		if dependencies.players == validated.players
			and dependencies.runService == validated.runService
			and dependencies.gameplayService == validated.gameplayService
		then
			return
		end
		error("AutoPowerScheduler is already initialized with different dependencies", 2)
	end

	dependencies = validated
	heartbeatConnection = validated.runService.Heartbeat:Connect(onHeartbeat)
end

return table.freeze(AutoPowerScheduler)
