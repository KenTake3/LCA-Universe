--[[
	SecurityService Module (ServerStorage)
	Lucky Core Factory - Server-Side Validation

	Provides data-load checks, rate-limiting, and validation for all client requests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local SessionManager = require(ServerStorage.SessionManager)

local SecurityService = {}

-- ============================================================
-- Data Load Check
-- ============================================================

function SecurityService.isDataLoaded(player)
	if not player or not player.Parent then return false end
	local attrLoaded = player:GetAttribute("DataLoaded") == true
	local sessionLoaded = SessionManager.isLoaded(player)
	return attrLoaded and sessionLoaded
end

function SecurityService.isDataFailed(player)
	if not player or not player.Parent then return false end
	return player:GetAttribute("DataLoadFailed") == true or SessionManager.isFailed(player)
end

-- ============================================================
-- Number Validation (NaN-safe)
-- ============================================================

function SecurityService.validateNumber(value, min, max)
	local n = tonumber(value)
	if n == nil or n ~= n then return min or 0 end
	if min then n = math.max(n, min) end
	if max then n = math.min(n, max) end
	return n
end

function SecurityService.validateEnergy(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxEnergy)
end

function SecurityService.validateGems(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxGems)
end

function SecurityService.validateRebirths(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxRebirths)
end

function SecurityService.validateUpgradeLevel(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxUpgradeLevel)
end

function SecurityService.validateLuck(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxLuck)
end

function SecurityService.validateCoreAmplifier(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxCoreAmplifier)
end

function SecurityService.validateReward(value)
	return SecurityService.validateNumber(value, 0, Config.Security.MaxRewardPerPress)
end

-- ============================================================
-- Press Rate Limiting
-- ============================================================

local pressTimestamps = {}

function SecurityService.canPress(player)
	local now = os.clock()
	local key = player.UserId
	if not pressTimestamps[key] then
		pressTimestamps[key] = {}
	end

	local timestamps = pressTimestamps[key]
	for i = #timestamps, 1, -1 do
		if now - timestamps[i] > 1 then
			table.remove(timestamps, i)
		else
			break
		end
	end

	if #timestamps >= Config.MaxPressesPerSecond then
		return false
	end

	table.insert(timestamps, now)
	return true
end

function SecurityService.clearPlayer(player)
	pressTimestamps[player.UserId] = nil
end

-- ============================================================
-- Upgrade Validation
-- ============================================================

function SecurityService.canBuyUpgrade(upgradeId, currentLevel)
	for _, upgrade in ipairs(Config.Upgrades) do
		if upgrade.id == upgradeId then
			return currentLevel < upgrade.maxLevel
		end
	end
	return false
end

function SecurityService.validateUpgrade(data, upgradeId)
	if not data then return false, "No data" end

	local upgrade = nil
	for _, u in ipairs(Config.Upgrades) do
		if u.id == upgradeId then
			upgrade = u
			break
		end
	end
	if not upgrade then return false, "Invalid upgrade" end

	local currentLevel = data.UpgradeLevels[upgradeId] or 0
	if currentLevel >= upgrade.maxLevel then return false, "Max level" end
	if currentLevel >= Config.Security.MaxUpgradeLevel then return false, "Safety cap" end

	local cost = Config.getUpgradeCost(upgradeId, currentLevel)
	if data.Energy < cost then return false, "Not enough energy" end

	return true, cost
end

-- ============================================================
-- Rebirth Validation
-- ============================================================

function SecurityService.validateRebirth(data)
	if not data then return false, "No data" end

	if data.Rebirths >= Config.Security.MaxRebirths then return false, "Max rebirths" end

	local cost = Config.getRebirthCost(data.Rebirths)
	if data.Energy < cost then return false, "Not enough energy" end

	return true, cost
end

-- ============================================================
-- Daily Reward Validation
-- ============================================================

function SecurityService.validateDailyReward(data)
	if not data then return false, "No data" end
	local now = os.time()
	local cooldownSec = Config.DailyReward.CooldownHours * 3600
	local lastClaim = data.DailyReward.LastClaim or 0
	if now - lastClaim < cooldownSec then return false, "On cooldown" end
	return true
end

-- ============================================================
-- Playtime Reward Validation
-- ============================================================

function SecurityService.validatePlaytimeReward(data)
	if not data then return false, "No data" end
	local index = data.PlaytimeReward.Index or 1
	if index > #Config.PlaytimeReward.Intervals then return false, "All claimed" end
	local required = Config.PlaytimeReward.Intervals[index]
	local current = data.PlaytimeReward.TotalPlaytime or 0
	if current < required then return false, "Not enough playtime" end
	return true
end

-- ============================================================
-- Clamping
-- ============================================================

function SecurityService.clampEnergy(energy)
	return math.min(energy, Config.Security.MaxEnergy)
end

function SecurityService.clampGems(gems)
	return math.min(gems, Config.Security.MaxGems)
end

return SecurityService