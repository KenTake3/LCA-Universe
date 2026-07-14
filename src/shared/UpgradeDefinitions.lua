--!strict

local Config = require(script.Parent.Config)

local UpgradeDefinitions = {}

local SUPPORTED_IDS = {
	ClickPower = true,
	AutoPower = true,
	CoreAmplifier = true,
	Luck = true,
}

local function finiteLimit(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.max(0, value)
end

local configuredUpgrades = {}
local configMaxLevels = {}
for _, upgrade in ipairs(Config.Upgrades) do
	if type(upgrade) == "table" and type(upgrade.id) == "string" and SUPPORTED_IDS[upgrade.id] then
		configuredUpgrades[upgrade.id] = true
		configMaxLevels[upgrade.id] = finiteLimit(upgrade.maxLevel, 0)
	end
end

local function normalizeInteger(value: any, maximum: number): (number, boolean)
	if type(value) ~= "number" and type(value) ~= "string" then
		return 0, false
	end

	local numberValue = tonumber(value)
	if numberValue == nil or numberValue ~= numberValue then
		return 0, false
	end
	if numberValue == math.huge or numberValue == -math.huge then
		return 0, false
	end

	local safeMaximum = finiteLimit(maximum, 0)
	return math.floor(math.min(math.max(0, numberValue), safeMaximum)), true
end

local function levelLimit(upgradeId: string): (number, boolean)
	if not configuredUpgrades[upgradeId] then
		return 0, false
	end

	local securityLimit = finiteLimit(Config.Security.MaxUpgradeLevel, 0)
	local upgradeLimit = finiteLimit(configMaxLevels[upgradeId], 0)
	return math.min(securityLimit, upgradeLimit), true
end

local function normalizedLevel(upgradeLevels: any, upgradeId: string): number
	if type(upgradeLevels) ~= "table" then
		return 0
	end

	local maximum, isConfigured = levelLimit(upgradeId)
	if not isConfigured then
		return 0
	end

	local level = normalizeInteger(upgradeLevels[upgradeId], maximum)
	return level
end

local function capStat(value: number, maximum: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.min(math.max(0, value), finiteLimit(maximum, 0))
end

function UpgradeDefinitions.calculateStats(upgradeLevels: any, rebirths: any)
	local clickPowerLevel = normalizedLevel(upgradeLevels, "ClickPower")
	local autoPowerLevel = normalizedLevel(upgradeLevels, "AutoPower")
	local coreAmplifierLevel = normalizedLevel(upgradeLevels, "CoreAmplifier")
	local luckLevel = normalizedLevel(upgradeLevels, "Luck")
	local normalizedRebirths = normalizeInteger(rebirths, Config.Security.MaxRebirths)
	local rebirthMultiplier = Config.getRebirthMultiplier(normalizedRebirths)

	-- RECOVERY_PROVISIONAL: additive stat formulas are specified by WP-03 and
	-- replace original formulas that were not present in the recovered source.
	local clickPower = (1 + clickPowerLevel) * rebirthMultiplier
	local autoPower = autoPowerLevel * rebirthMultiplier
	local coreAmplifier = 1 + coreAmplifierLevel * 0.05
	local luck = luckLevel

	return {
		ClickPower = capStat(clickPower, Config.Security.MaxEnergy),
		AutoPower = capStat(autoPower, Config.Security.MaxEnergy),
		CoreAmplifier = capStat(coreAmplifier, Config.Security.MaxCoreAmplifier),
		Luck = capStat(luck, Config.Security.MaxLuck),
	}
end

function UpgradeDefinitions.canLevelUp(upgradeId: any, currentLevel: any): boolean
	if type(upgradeId) ~= "string" or not SUPPORTED_IDS[upgradeId] then
		return false
	end

	local maximum, isConfigured = levelLimit(upgradeId)
	if not isConfigured then
		return false
	end

	local level, isValid = normalizeInteger(currentLevel, maximum)
	if not isValid then
		return false
	end

	return level < maximum
end

return UpgradeDefinitions
