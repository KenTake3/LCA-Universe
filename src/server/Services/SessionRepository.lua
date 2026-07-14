--!strict

local Config = require(game.ReplicatedStorage.LCA_Shared.Config)
local UpgradeDefinitions = require(game.ReplicatedStorage.LCA_Shared.UpgradeDefinitions)

export type ResultCode =
	"OK"
	| "INVALID_PLAYER"
	| "NOT_FOUND"
	| "NOT_INITIALIZED"
	| "ALREADY_ACTIVE"
	| "NOT_LOADED"
	| "LOAD_FAILED"
	| "SAVE_FAILED"
	| "INVALID_DATA"
	| "SAVE_IN_PROGRESS"
	| "FINALIZING"
	| "RELEASED"

export type SessionState = "Loading" | "Loaded" | "LoadFailed" | "Saving" | "Released"

export type GameplayData = { [any]: any }
export type MainSyncPacket = { [any]: any }
export type QuestSyncPacket = { [any]: any }

export type Session = {
	userId: number,
	player: Player,
	data: { [any]: any },
	state: SessionState,
	revision: number,
	savedRevision: number,
	dirty: boolean,
	saveInFlight: boolean,
	finalizeRequested: boolean,
	lastResult: ResultCode?,
}

local SessionRepository = {}
local sessions: { [number]: Session } = {}

-- RECOVERY_PROVISIONAL: no original serialization-depth bound survived.
local MAX_CLONE_DEPTH = 32
local MAX_SAFE_INTEGER = 9_007_199_254_740_991
local FACTORY_STAGE_COUNT = 6

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

local function cloneValue(value: any, depth: number, active: { [any]: boolean }): (any?, string?)
	if depth > MAX_CLONE_DEPTH then
		return nil, "MAX_DEPTH_EXCEEDED"
	end

	local valueType = type(value)
	if value == nil or valueType == "boolean" or valueType == "string" then
		return value, nil
	elseif valueType == "number" then
		if not isFiniteNumber(value) then
			return nil, "NON_FINITE_NUMBER"
		end
		return value, nil
	elseif valueType ~= "table" then
		return nil, "UNSUPPORTED_VALUE"
	end

	if active[value] then
		return nil, "CYCLIC_TABLE"
	end
	active[value] = true

	local result = {}
	for key, nestedValue in pairs(value) do
		if type(key) ~= "string" and not isFiniteInteger(key) then
			active[value] = nil
			return nil, "UNSUPPORTED_TABLE_KEY"
		end

		local clonedValue, cloneError = cloneValue(nestedValue, depth + 1, active)
		if cloneError ~= nil then
			active[value] = nil
			return nil, cloneError
		end
		result[key] = clonedValue
	end

	active[value] = nil
	return result, nil
end

local function deepClone(value: any): (any?, string?)
	return cloneValue(value, 0, {})
end

local function currentDataVersion(): number
	local version = Config.DataVersion
	if not isFiniteInteger(version) or version < 0 or version > MAX_SAFE_INTEGER then
		error("SessionRepository requires a finite non-negative integer Config.DataVersion", 3)
	end
	return version
end

local function freshDefaultData(): GameplayData
	return {
		Energy = 0,
		LifetimeEnergy = 0,
		Rebirths = 0,
		Gems = 0,
		UpgradeLevels = { ClickPower = 0, AutoPower = 0, CoreAmplifier = 0, Luck = 0 },
		DailyReward = { LastClaim = 0, Streak = 0 },
		PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 },
		PurchasedPerks = {},
		History = {},
		BestRarity = 0,
		BestRarityName = "None",
		FactoryStage = 1,
		HighestFactoryStage = 1,
		DailyQuests = { Date = "", Quests = {}, SessionStart = 0 },
		Achievements = { Unlocked = {}, Claimed = {} },
		Collection = { Cores = {}, Auras = {}, Titles = {}, Factories = {} },
		DailyLogin = { LastClaim = 0, CumulativeDays = 0, CurrentDay = 1 },
		TotalPresses = 0,
		TotalRarePulls = 0,
		TotalLegendaryPulls = 0,
		TotalMythicPulls = 0,
		TotalCosmicPulls = 0,
		TotalJackpotPulls = 0,
		RarityCount = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },
		FirstJoin = os.time(),
		DataVersion = currentDataVersion(),
	}
end

local function normalizeIntegerField(
	container: { [any]: any },
	key: any,
	defaultValue: number,
	minimum: number,
	maximum: number
): boolean
	local value = container[key]
	local normalized = defaultValue
	if isFiniteNumber(value) then
		normalized = math.clamp(math.floor(value), minimum, maximum)
	end
	if value ~= normalized then
		container[key] = normalized
		return true
	end
	return false
end

local function normalizeStringField(container: { [any]: any }, key: any, defaultValue: string): boolean
	if type(container[key]) == "string" then
		return false
	end
	container[key] = defaultValue
	return true
end

local function ensureTable(container: { [any]: any }, key: any): ({ [any]: any }, boolean)
	local value = container[key]
	if type(value) == "table" then
		return value, false
	end
	local replacement = {}
	container[key] = replacement
	return replacement, true
end

local function upgradeLimit(upgradeId: string): number
	local globalLimit = Config.Security.MaxUpgradeLevel
	if not isFiniteNumber(globalLimit) then
		return 0
	end
	local limit = math.max(0, math.floor(globalLimit))
	for _, upgrade in ipairs(Config.Upgrades) do
		if type(upgrade) == "table" and upgrade.id == upgradeId and isFiniteNumber(upgrade.maxLevel) then
			return math.min(limit, math.max(0, math.floor(upgrade.maxLevel)))
		end
	end
	return 0
end

local function approvedCap(value: any, fallback: number): number
	if not isFiniteNumber(value) or value < 0 then
		return fallback
	end
	return math.min(math.floor(value), MAX_SAFE_INTEGER)
end

local function normalizeKnownFields(data: GameplayData): boolean
	local changed = false
	local maxEnergy = approvedCap(Config.Security.MaxEnergy, MAX_SAFE_INTEGER)
	local maxGems = approvedCap(Config.Security.MaxGems, MAX_SAFE_INTEGER)
	local maxRebirths = approvedCap(Config.Security.MaxRebirths, MAX_SAFE_INTEGER)

	changed = normalizeIntegerField(data, "Energy", 0, 0, maxEnergy) or changed
	changed = normalizeIntegerField(data, "LifetimeEnergy", 0, 0, maxEnergy) or changed
	changed = normalizeIntegerField(data, "Rebirths", 0, 0, maxRebirths) or changed
	changed = normalizeIntegerField(data, "Gems", 0, 0, maxGems) or changed

	local upgradeLevels, repairedUpgrades = ensureTable(data, "UpgradeLevels")
	changed = repairedUpgrades or changed
	for _, upgradeId in ipairs({ "ClickPower", "AutoPower", "CoreAmplifier", "Luck" }) do
		changed = normalizeIntegerField(upgradeLevels, upgradeId, 0, 0, upgradeLimit(upgradeId)) or changed
	end

	local dailyReward, repairedDailyReward = ensureTable(data, "DailyReward")
	changed = repairedDailyReward or changed
	changed = normalizeIntegerField(dailyReward, "LastClaim", 0, 0, MAX_SAFE_INTEGER) or changed
	changed = normalizeIntegerField(dailyReward, "Streak", 0, 0, MAX_SAFE_INTEGER) or changed

	local playtimeReward, repairedPlaytime = ensureTable(data, "PlaytimeReward")
	changed = repairedPlaytime or changed
	changed = normalizeIntegerField(playtimeReward, "LastClaim", 0, 0, MAX_SAFE_INTEGER) or changed
	changed = normalizeIntegerField(playtimeReward, "TotalPlaytime", 0, 0, MAX_SAFE_INTEGER) or changed
	changed = normalizeIntegerField(playtimeReward, "Index", 1, 1, MAX_SAFE_INTEGER) or changed

	local _, repairedPerks = ensureTable(data, "PurchasedPerks")
	local _, repairedHistory = ensureTable(data, "History")
	changed = repairedPerks or repairedHistory or changed
	changed = normalizeIntegerField(data, "BestRarity", 0, 0, #Config.LuckRarities) or changed
	changed = normalizeStringField(data, "BestRarityName", "None") or changed
	changed = normalizeIntegerField(data, "FactoryStage", 1, 1, FACTORY_STAGE_COUNT) or changed
	changed = normalizeIntegerField(data, "HighestFactoryStage", 1, 1, FACTORY_STAGE_COUNT) or changed
	if data.HighestFactoryStage < data.FactoryStage then
		data.HighestFactoryStage = data.FactoryStage
		changed = true
	end

	local dailyQuests, repairedDailyQuests = ensureTable(data, "DailyQuests")
	changed = repairedDailyQuests or changed
	changed = normalizeStringField(dailyQuests, "Date", "") or changed
	local _, repairedQuests = ensureTable(dailyQuests, "Quests")
	changed = repairedQuests or changed
	changed = normalizeIntegerField(dailyQuests, "SessionStart", 0, 0, MAX_SAFE_INTEGER) or changed

	local achievements, repairedAchievements = ensureTable(data, "Achievements")
	changed = repairedAchievements or changed
	local _, repairedUnlocked = ensureTable(achievements, "Unlocked")
	local _, repairedClaimed = ensureTable(achievements, "Claimed")
	changed = repairedUnlocked or repairedClaimed or changed

	local collection, repairedCollection = ensureTable(data, "Collection")
	changed = repairedCollection or changed
	for _, key in ipairs({ "Cores", "Auras", "Titles", "Factories" }) do
		local _, repaired = ensureTable(collection, key)
		changed = repaired or changed
	end

	local dailyLogin, repairedDailyLogin = ensureTable(data, "DailyLogin")
	changed = repairedDailyLogin or changed
	changed = normalizeIntegerField(dailyLogin, "LastClaim", 0, 0, MAX_SAFE_INTEGER) or changed
	changed = normalizeIntegerField(dailyLogin, "CumulativeDays", 0, 0, MAX_SAFE_INTEGER) or changed
	changed = normalizeIntegerField(dailyLogin, "CurrentDay", 1, 1, MAX_SAFE_INTEGER) or changed

	for _, key in ipairs({
		"TotalPresses",
		"TotalRarePulls",
		"TotalLegendaryPulls",
		"TotalMythicPulls",
		"TotalCosmicPulls",
		"TotalJackpotPulls",
	}) do
		changed = normalizeIntegerField(data, key, 0, 0, MAX_SAFE_INTEGER) or changed
	end

	local rarityCount, repairedRarityCount = ensureTable(data, "RarityCount")
	changed = repairedRarityCount or changed
	for index = 1, 8 do
		changed = normalizeIntegerField(rarityCount, index, 0, 0, MAX_SAFE_INTEGER) or changed
	end

	return changed
end

function SessionRepository.createSession(player: Player): Session?
	if not isPlayer(player) then
		return nil
	end
	local userId = player.UserId
	if sessions[userId] ~= nil then
		return nil
	end

	local session: Session = {
		userId = userId,
		player = player,
		data = {},
		state = "Loading",
		revision = 0,
		savedRevision = 0,
		dirty = false,
		saveInFlight = false,
		finalizeRequested = false,
		lastResult = nil,
	}
	sessions[userId] = session
	return session
end

function SessionRepository.getSession(player: Player): Session?
	if not isPlayer(player) then
		return nil
	end
	local session = sessions[player.UserId]
	if session == nil or session.player ~= player or session.userId ~= player.UserId then
		return nil
	end
	return session
end

function SessionRepository.removeSession(player: Player): boolean
	if not isPlayer(player) then
		return false
	end
	local session = sessions[player.UserId]
	if session == nil or session.player ~= player or session.userId ~= player.UserId then
		return false
	end
	sessions[player.UserId] = nil
	return true
end

function SessionRepository.getDefaultData(): GameplayData
	return freshDefaultData()
end

function SessionRepository.migrateData(data: { [any]: any }): (GameplayData?, boolean, string?)
	if type(data) ~= "table" then
		return nil, false, "INVALID_ROOT"
	end

	local cloned, cloneError = deepClone(data)
	if cloneError ~= nil or type(cloned) ~= "table" then
		return nil, false, cloneError or "INVALID_ROOT"
	end
	local migrated = cloned :: GameplayData

	if not isFiniteInteger(migrated.FirstJoin)
		or migrated.FirstJoin < 0
		or migrated.FirstJoin > MAX_SAFE_INTEGER
	then
		return nil, false, migrated.FirstJoin == nil and "MISSING_FIRST_JOIN" or "INVALID_FIRST_JOIN"
	end

	local targetVersion = currentDataVersion()
	local sourceVersion = migrated.DataVersion
	local versionWasMissing = sourceVersion == nil
	if sourceVersion == nil then
		sourceVersion = 0
	elseif not isFiniteInteger(sourceVersion) or sourceVersion < 0 or sourceVersion > MAX_SAFE_INTEGER then
		return nil, false, "INVALID_DATA_VERSION"
	end
	if sourceVersion > targetVersion then
		return nil, false, "FUTURE_DATA_VERSION"
	end

	local changed = normalizeKnownFields(migrated)
	if versionWasMissing or sourceVersion ~= targetVersion then
		migrated.DataVersion = targetVersion
		changed = true
	end

	return migrated, changed, nil
end

local function packetSession(player: Player): Session?
	local session = SessionRepository.getSession(player)
	if session == nil or (session.state ~= "Loaded" and session.state ~= "Saving") then
		return nil
	end
	if session.dirty ~= (session.revision > session.savedRevision) then
		return nil
	end
	return session
end

local function clonedPacket(packet: { [any]: any }): { [any]: any }?
	local cloned, cloneError = deepClone(packet)
	if cloneError ~= nil or type(cloned) ~= "table" then
		return nil
	end
	return cloned
end

function SessionRepository.buildSyncPacket(player: Player): MainSyncPacket?
	local session = packetSession(player)
	if session == nil then
		return nil
	end
	local data = session.data
	if type(data) ~= "table" then
		return nil
	end

	local stats = UpgradeDefinitions.calculateStats(data.UpgradeLevels, data.Rebirths)

	local packetOk, packet = pcall(function()
		return {
			Energy = data.Energy,
			LifetimeEnergy = data.LifetimeEnergy,
			ClickPower = stats.ClickPower,
			AutoPower = stats.AutoPower,
			CoreAmplifier = stats.CoreAmplifier,
			Luck = stats.Luck,
			Rebirths = data.Rebirths,
			Gems = data.Gems,
			UpgradeLevels = {
				ClickPower = data.UpgradeLevels.ClickPower,
				AutoPower = data.UpgradeLevels.AutoPower,
				CoreAmplifier = data.UpgradeLevels.CoreAmplifier,
				Luck = data.UpgradeLevels.Luck,
			},
			DailyReward = { LastClaim = data.DailyReward.LastClaim, Streak = data.DailyReward.Streak },
			PlaytimeReward = {
				LastClaim = data.PlaytimeReward.LastClaim,
				TotalPlaytime = data.PlaytimeReward.TotalPlaytime,
				Index = data.PlaytimeReward.Index,
			},
			PurchasedPerks = data.PurchasedPerks,
			History = data.History,
			BestRarity = data.BestRarity,
			BestRarityName = data.BestRarityName,
			FactoryStage = data.FactoryStage,
			HighestFactoryStage = data.HighestFactoryStage,
		}
	end)
	if not packetOk or type(packet) ~= "table" then
		return nil
	end
	return clonedPacket(packet)
end

function SessionRepository.buildQuestSyncPacket(player: Player): QuestSyncPacket?
	local session = packetSession(player)
	if session == nil then
		return nil
	end
	local data = session.data
	if type(data) ~= "table" then
		return nil
	end

	local packetOk, packet = pcall(function()
		return {
			DailyQuests = {
				Date = data.DailyQuests.Date,
				Quests = data.DailyQuests.Quests,
				SessionStart = data.DailyQuests.SessionStart,
			},
			Achievements = {
				Unlocked = data.Achievements.Unlocked,
				Claimed = data.Achievements.Claimed,
			},
			Collection = {
				Cores = data.Collection.Cores,
				Auras = data.Collection.Auras,
				Titles = data.Collection.Titles,
				Factories = data.Collection.Factories,
			},
			DailyLogin = {
				LastClaim = data.DailyLogin.LastClaim,
				CumulativeDays = data.DailyLogin.CumulativeDays,
				CurrentDay = data.DailyLogin.CurrentDay,
			},
			Stats = {
				TotalPresses = data.TotalPresses,
				LifetimeEnergy = data.LifetimeEnergy,
				Rebirths = data.Rebirths,
				HighestFactoryStage = data.HighestFactoryStage,
				TotalRarePulls = data.TotalRarePulls,
				TotalLegendaryPulls = data.TotalLegendaryPulls,
				TotalMythicPulls = data.TotalMythicPulls,
				TotalCosmicPulls = data.TotalCosmicPulls,
				TotalJackpotPulls = data.TotalJackpotPulls,
				RarityCount = {
					[1] = data.RarityCount[1],
					[2] = data.RarityCount[2],
					[3] = data.RarityCount[3],
					[4] = data.RarityCount[4],
					[5] = data.RarityCount[5],
					[6] = data.RarityCount[6],
					[7] = data.RarityCount[7],
					[8] = data.RarityCount[8],
				},
			},
		}
	end)
	if not packetOk or type(packet) ~= "table" then
		return nil
	end
	return clonedPacket(packet)
end

return table.freeze(SessionRepository)
