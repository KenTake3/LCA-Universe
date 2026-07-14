--!strict

local Config = require(game.ReplicatedStorage.LCA_Shared.Config)
local UpgradeDefinitions = require(game.ReplicatedStorage.LCA_Shared.UpgradeDefinitions)

export type ResultCode =
	"OK"
	| "INVALID_PLAYER"
	| "NOT_FOUND"
	| "NOT_LOADED"
	| "BUSY"
	| "INVALID_DATA"
	| "INVALID_REWARD"
	| "DIRTY_FAILED"

export type PressResult = {
	reward: number,
	syncSucceeded: boolean,
}

export type SessionRepository = {
	getSession: (player: Player) -> any,
}

export type DataService = {
	markDirty: (player: Player) -> (boolean, string),
	syncToClient: (player: Player) -> boolean,
}

export type Dependencies = {
	sessions: SessionRepository,
	dataService: DataService,
}

local GameplayService = {}
local dependencies: Dependencies? = nil
local MAX_SAFE_INTEGER = 9_007_199_254_740_991
local UPGRADE_IDS = { "ClickPower", "AutoPower", "CoreAmplifier", "Luck" }

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function isFiniteInteger(value: any): boolean
	return isFiniteNumber(value) and value == math.floor(value)
end

local function isPlayer(value: any): boolean
	return typeof(value) == "Instance"
		and value:IsA("Player")
		and isFiniteInteger((value :: Player).UserId)
end

local function validateDependencies(candidate: any): Dependencies
	if type(candidate) ~= "table" then
		error("GameplayService.init requires a dependency table", 3)
	end

	local expectedKeys = { sessions = true, dataService = true }
	for key in pairs(candidate) do
		if not expectedKeys[key] then
			error("GameplayService.init received an unexpected dependency", 3)
		end
	end

	local sessions = candidate.sessions
	local dataService = candidate.dataService
	if type(sessions) ~= "table"
		or type(sessions.getSession) ~= "function"
		or type(dataService) ~= "table"
		or type(dataService.markDirty) ~= "function"
		or type(dataService.syncToClient) ~= "function"
	then
		error("GameplayService.init received malformed dependencies", 3)
	end

	return table.freeze({
		sessions = sessions,
		dataService = dataService,
	}) :: Dependencies
end

local function configuredCap(value: any): number?
	if not isFiniteInteger(value) or value < 1 or value > MAX_SAFE_INTEGER then
		return nil
	end
	return value
end

local function configuredNonNegativeCap(value: any): number?
	if not isFiniteInteger(value) or value < 0 or value > MAX_SAFE_INTEGER then
		return nil
	end
	return value
end

local function saturatingAdd(currentValue: number, amount: number, maximum: number): number
	if currentValue >= maximum then
		return maximum
	end
	local remaining = maximum - currentValue
	if amount >= remaining then
		return maximum
	end
	return currentValue + amount
end

local function upgradeLimit(upgradeId: string): number?
	local securityLimit = configuredNonNegativeCap(Config.Security.MaxUpgradeLevel)
	if securityLimit == nil then
		return nil
	end
	for _, upgrade in ipairs(Config.Upgrades) do
		if type(upgrade) == "table" and upgrade.id == upgradeId then
			local definitionLimit = configuredNonNegativeCap(upgrade.maxLevel)
			if definitionLimit == nil then
				return nil
			end
			return math.min(securityLimit, definitionLimit)
		end
	end
	return nil
end

local function validSessionMetadata(session: any): boolean
	return type(session) == "table"
		and isFiniteInteger(session.revision)
		and session.revision >= 0
		and session.revision <= MAX_SAFE_INTEGER
		and isFiniteInteger(session.savedRevision)
		and session.savedRevision >= 0
		and session.savedRevision <= session.revision
		and type(session.dirty) == "boolean"
		and session.dirty == (session.revision > session.savedRevision)
		and type(session.saveInFlight) == "boolean"
		and type(session.finalizeRequested) == "boolean"
end

function GameplayService.init(candidate: Dependencies)
	local validated = validateDependencies(candidate)
	if dependencies ~= nil then
		if dependencies.sessions == validated.sessions and dependencies.dataService == validated.dataService then
			return
		end
		error("GameplayService is already initialized with different dependencies", 2)
	end
	dependencies = validated
end

function GameplayService.press(player: Player): (boolean, ResultCode, PressResult?)
	if not isPlayer(player) then
		return false, "INVALID_PLAYER", nil
	end
	local configured = dependencies
	if configured == nil then
		return false, "NOT_FOUND", nil
	end

	local session = configured.sessions.getSession(player)
	if session == nil then
		return false, "NOT_FOUND", nil
	end
	if not validSessionMetadata(session) or session.player ~= player or session.userId ~= player.UserId then
		return false, "INVALID_DATA", nil
	end
	if session.state == "Saving" or session.saveInFlight or session.finalizeRequested then
		return false, "BUSY", nil
	end
	if session.state ~= "Loaded" then
		return false, "NOT_LOADED", nil
	end

	local data = session.data
	if type(data) ~= "table"
		or type(data.UpgradeLevels) ~= "table"
		or not isFiniteInteger(data.Rebirths)
		or data.Rebirths < 0
		or not isFiniteInteger(data.Energy)
		or data.Energy < 0
		or not isFiniteInteger(data.LifetimeEnergy)
		or data.LifetimeEnergy < 0
		or not isFiniteInteger(data.TotalPresses)
		or data.TotalPresses < 0
	then
		return false, "INVALID_DATA", nil
	end

	local maxEnergy = configuredCap(Config.Security.MaxEnergy)
	local maxReward = configuredCap(Config.Security.MaxRewardPerPress)
	local maxRebirths = configuredNonNegativeCap(Config.Security.MaxRebirths)
	if maxEnergy == nil or maxReward == nil
		or maxRebirths == nil
		or data.Rebirths > maxRebirths
		or data.Energy > maxEnergy
		or data.LifetimeEnergy > maxEnergy
		or data.TotalPresses > MAX_SAFE_INTEGER
	then
		return false, "INVALID_DATA", nil
	end
	for _, upgradeId in ipairs(UPGRADE_IDS) do
		local level = data.UpgradeLevels[upgradeId]
		local limit = upgradeLimit(upgradeId)
		if limit == nil or not isFiniteInteger(level) or level < 0 or level > limit then
			return false, "INVALID_DATA", nil
		end
	end

	local stats = UpgradeDefinitions.calculateStats(data.UpgradeLevels, data.Rebirths)
	local clickPower = stats.ClickPower
	if not isFiniteNumber(clickPower) or clickPower < 0 then
		return false, "INVALID_REWARD", nil
	end

	local minimumReward = math.max(1, math.floor(clickPower))
	local reward = math.min(minimumReward, maxReward)
	if not isFiniteInteger(reward) or reward < 1 then
		return false, "INVALID_REWARD", nil
	end

	local oldEnergy = data.Energy
	local oldLifetimeEnergy = data.LifetimeEnergy
	local oldTotalPresses = data.TotalPresses
	data.Energy = saturatingAdd(oldEnergy, reward, maxEnergy)
	data.LifetimeEnergy = saturatingAdd(oldLifetimeEnergy, reward, maxEnergy)
	data.TotalPresses = saturatingAdd(oldTotalPresses, 1, MAX_SAFE_INTEGER)

	local dirtySucceeded = configured.dataService.markDirty(player)
	if not dirtySucceeded then
		data.Energy = oldEnergy
		data.LifetimeEnergy = oldLifetimeEnergy
		data.TotalPresses = oldTotalPresses
		return false, "DIRTY_FAILED", nil
	end

	local syncSucceeded = configured.dataService.syncToClient(player)
	return true, "OK", table.freeze({
		reward = reward,
		syncSucceeded = syncSucceeded,
	})
end

return table.freeze(GameplayService)
