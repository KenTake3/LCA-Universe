--[[
	SessionManager Module (ServerStorage)
	Lucky Core Factory - In-Memory Session Data

	Flat session architecture: sessions[userId] = { data = {...}, state, player, dirty }
	All server scripts use SessionManager.getData(player) to access the data table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local SessionManager = {}

local DataState = {
	Loading = "Loading",
	Loaded = "Loaded",
	LoadFailed = "LoadFailed",
}

local sessions = {}

-- ============================================================
-- Default Data
-- ============================================================

local function getDefaultData()
	return {
		-- Core stats
		Energy = 0,
		LifetimeEnergy = 0,
		Rebirths = 0,
		Gems = 0,

		-- Upgrade levels
		UpgradeLevels = { ClickPower = 0, AutoPower = 0, CoreAmplifier = 0, Luck = 0 },

		-- Reward tracking
		DailyReward = { LastClaim = 0, Streak = 0 },
		PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 },
		PurchasedPerks = {},

		-- Luck history
		History = {},
		BestRarity = 0,
		BestRarityName = "None",

		-- Factory evolution
		FactoryStage = 1,
		HighestFactoryStage = 1,

		-- Quest / Achievement / Collection / DailyLogin (v4)
		DailyQuests = { Date = "", Quests = {}, SessionStart = 0 },
		Achievements = { Unlocked = {}, Claimed = {} },
		Collection = { Cores = {}, Auras = {}, Titles = {}, Factories = {} },
		DailyLogin = { LastClaim = 0, CumulativeDays = 0, CurrentDay = 1 },

		-- Lifetime stat tracking (for achievements)
		TotalPresses = 0,
		TotalRarePulls = 0,
		TotalLegendaryPulls = 0,
		TotalMythicPulls = 0,
		TotalCosmicPulls = 0,
		TotalJackpotPulls = 0,
		RarityCount = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },

		-- Meta
		FirstJoin = os.time(),
		DataVersion = Config.DataVersion,
	}
end

-- ============================================================
-- Migration
-- ============================================================

local function migrateData(data)
	if not data then return getDefaultData() end

	local defaults = getDefaultData()

	-- Merge missing top-level fields
	for key, value in pairs(defaults) do
		if data[key] == nil then
			if typeof(value) == "table" then
				data[key] = table.clone(value)
			else
				data[key] = value
			end
		end
	end

	-- Ensure nested table structure
	if not data.UpgradeLevels then
		data.UpgradeLevels = { ClickPower = 0, AutoPower = 0, CoreAmplifier = 0, Luck = 0 }
	else
		for k in pairs(defaults.UpgradeLevels) do
			if data.UpgradeLevels[k] == nil then data.UpgradeLevels[k] = 0 end
		end
		-- Remove old v1 fields
		data.UpgradeLevels.CriticalChance = nil
		data.UpgradeLevels.CriticalMultiplier = nil
	end

	if not data.DailyReward then data.DailyReward = { LastClaim = 0, Streak = 0 } end
	if not data.PlaytimeReward then data.PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 } end
	if not data.PurchasedPerks then data.PurchasedPerks = {} end
	if not data.History then data.History = {} end

	if not data.DailyQuests then data.DailyQuests = { Date = "", Quests = {}, SessionStart = 0 } end
	if not data.DailyQuests.Quests then data.DailyQuests.Quests = {} end

	if not data.Achievements then data.Achievements = { Unlocked = {}, Claimed = {} } end
	if not data.Achievements.Unlocked then data.Achievements.Unlocked = {} end
	if not data.Achievements.Claimed then data.Achievements.Claimed = {} end

	if not data.Collection then data.Collection = { Cores = {}, Auras = {}, Titles = {}, Factories = {} } end
	if not data.Collection.Cores then data.Collection.Cores = {} end
	if not data.Collection.Auras then data.Collection.Auras = {} end
	if not data.Collection.Titles then data.Collection.Titles = {} end
	if not data.Collection.Factories then data.Collection.Factories = {} end

	if not data.DailyLogin then data.DailyLogin = { LastClaim = 0, CumulativeDays = 0, CurrentDay = 1 } end

	if not data.RarityCount then
		data.RarityCount = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 }
	end

	data.DataVersion = Config.DataVersion
	return data
end

-- ============================================================
-- Session Lifecycle
-- ============================================================

function SessionManager.createSession(player)
	local userId = player.UserId
	sessions[userId] = {
		data = getDefaultData(),
		state = DataState.Loading,
		player = player,
		dirty = false,
	}
	return sessions[userId]
end

function SessionManager.getSession(player)
	return sessions[player.UserId]
end

function SessionManager.getData(player)
	local session = sessions[player.UserId]
	return session and session.data or nil
end

function SessionManager.removeSession(player)
	sessions[player.UserId] = nil
end

function SessionManager.getAllSessions()
	return sessions
end

-- ============================================================
-- Data State
-- ============================================================

function SessionManager.setState(player, state)
	local session = sessions[player.UserId]
	if session then
		session.state = state
		if state == DataState.Loaded then
			player:SetAttribute("DataLoaded", true)
		elseif state == DataState.LoadFailed then
			player:SetAttribute("DataLoaded", false)
			player:SetAttribute("DataLoadFailed", true)
		end
	end
end

function SessionManager.getState(player)
	local session = sessions[player.UserId]
	return session and session.state or DataState.Loading
end

function SessionManager.isLoaded(player)
	local session = sessions[player.UserId]
	return session ~= nil and session.state == DataState.Loaded
end

function SessionManager.isFailed(player)
	local session = sessions[player.UserId]
	return session ~= nil and session.state == DataState.LoadFailed
end

function SessionManager.markDirty(player)
	local session = sessions[player.UserId]
	if session then session.dirty = true end
end

function SessionManager.isDirty(player)
	local session = sessions[player.UserId]
	return session ~= nil and session.dirty
end

function SessionManager.clearDirty(player)
	local session = sessions[player.UserId]
	if session then session.dirty = false end
end

-- ============================================================
-- Data Loading / Exporting
-- ============================================================

function SessionManager.loadData(player, savedData)
	local session = sessions[player.UserId]
	if not session then return end
	session.data = migrateData(savedData)
end

function SessionManager.exportData(player)
	local session = sessions[player.UserId]
	if not session then return nil end
	return session.data
end

function SessionManager.migrateData(data)
	return migrateData(data)
end

function SessionManager.getDefaultData()
	return getDefaultData()
end

function SessionManager.DataState()
	return DataState
end

-- ============================================================
-- Sync Packet Builders
-- ============================================================

function SessionManager.buildSyncPacket(player)
	local data = SessionManager.getData(player)
	if not data then return nil end

	local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
	local stats = UpgradeDefinitions.calculateStats(data.UpgradeLevels, data.Rebirths)

	return {
		Energy = data.Energy,
		LifetimeEnergy = data.LifetimeEnergy,
		ClickPower = stats.ClickPower,
		AutoPower = stats.AutoPower,
		CoreAmplifier = stats.CoreAmplifier,
		Luck = stats.Luck,
		Rebirths = data.Rebirths,
		Gems = data.Gems,
		UpgradeLevels = data.UpgradeLevels,
		DailyReward = data.DailyReward,
		PlaytimeReward = data.PlaytimeReward,
		PurchasedPerks = data.PurchasedPerks,
		History = data.History,
		BestRarity = data.BestRarity,
		BestRarityName = data.BestRarityName,
		FactoryStage = data.FactoryStage,
		HighestFactoryStage = data.HighestFactoryStage,
	}
end

function SessionManager.buildQuestSyncPacket(player)
	local data = SessionManager.getData(player)
	if not data then return nil end

	return {
		DailyQuests = data.DailyQuests,
		Achievements = data.Achievements,
		Collection = data.Collection,
		DailyLogin = data.DailyLogin,
		-- Stats for achievement progress display
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
			RarityCount = data.RarityCount,
		},
	}
end

return SessionManager