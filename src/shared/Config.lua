--!strict

-- Recovered compatibility contract for the salvaged Lucky Core Factory scripts.
-- Values grouped below are safe recovery defaults, not original balance data.

local Config = {}

-- RECOVERY_PROVISIONAL: original version, caps, progression, and reward values
-- were not present in the recovered source. Keep them centralized here.
local PROVISIONAL = {
	DataVersion = 4,
	DebugMode = false,
	MaxPressesPerSecond = 12,

	Security = {
		MaxEnergy = 1e15,
		MaxGems = 1e9,
		MaxRebirths = 100,
		MaxUpgradeLevel = 100,
		MaxLuck = 1e6,
		MaxCoreAmplifier = 1e6,
		MaxRewardPerPress = 1e12,
	},

	Upgrades = {
		ClickPower = { baseCost = 10, growth = 1.15, maxLevel = 100 },
		AutoPower = { baseCost = 50, growth = 1.16, maxLevel = 100 },
		CoreAmplifier = { baseCost = 250, growth = 1.17, maxLevel = 100 },
		Luck = { baseCost = 500, growth = 1.18, maxLevel = 100 },
	},

	Rebirth = {
		baseCost = 10_000,
		costGrowth = 1.75,
		multiplierPerRebirth = 0.5,
	},

	DailyReward = {
		CooldownHours = 24,
		Gems = { 5, 10, 15, 20, 30, 40, 75 },
	},

	PlaytimeReward = {
		Intervals = { 5 * 60, 15 * 60, 30 * 60, 60 * 60 },
		Gems = { 5, 10, 20, 40 },
	},
}

Config.DataVersion = PROVISIONAL.DataVersion
Config.DEBUG_MODE = PROVISIONAL.DebugMode
Config.MaxPressesPerSecond = PROVISIONAL.MaxPressesPerSecond

Config.Security = {
	MaxEnergy = PROVISIONAL.Security.MaxEnergy,
	MaxGems = PROVISIONAL.Security.MaxGems,
	MaxRebirths = PROVISIONAL.Security.MaxRebirths,
	MaxUpgradeLevel = PROVISIONAL.Security.MaxUpgradeLevel,
	MaxLuck = PROVISIONAL.Security.MaxLuck,
	MaxCoreAmplifier = PROVISIONAL.Security.MaxCoreAmplifier,
	MaxRewardPerPress = PROVISIONAL.Security.MaxRewardPerPress,
}

-- RECOVERY_PROVISIONAL: upgrade display text and colors were not recovered.
-- IDs are fixed by saved data; numeric tuning remains centralized above.
Config.Upgrades = {
	{
		id = "ClickPower",
		displayName = "Click Power",
		description = "Increase energy earned per press.",
		iconColor = Color3.fromRGB(0, 170, 255),
		maxLevel = PROVISIONAL.Upgrades.ClickPower.maxLevel,
		baseCost = PROVISIONAL.Upgrades.ClickPower.baseCost,
		costGrowth = PROVISIONAL.Upgrades.ClickPower.growth,
	},
	{
		id = "AutoPower",
		displayName = "Auto Power",
		description = "Increase automatic energy production.",
		iconColor = Color3.fromRGB(80, 200, 120),
		maxLevel = PROVISIONAL.Upgrades.AutoPower.maxLevel,
		baseCost = PROVISIONAL.Upgrades.AutoPower.baseCost,
		costGrowth = PROVISIONAL.Upgrades.AutoPower.growth,
	},
	{
		id = "CoreAmplifier",
		displayName = "Core Amplifier",
		description = "Amplify factory energy output.",
		iconColor = Color3.fromRGB(255, 150, 0),
		maxLevel = PROVISIONAL.Upgrades.CoreAmplifier.maxLevel,
		baseCost = PROVISIONAL.Upgrades.CoreAmplifier.baseCost,
		costGrowth = PROVISIONAL.Upgrades.CoreAmplifier.growth,
	},
	{
		id = "Luck",
		displayName = "Luck",
		description = "Improve the chance of valuable cores.",
		iconColor = Color3.fromRGB(255, 100, 200),
		maxLevel = PROVISIONAL.Upgrades.Luck.maxLevel,
		baseCost = PROVISIONAL.Upgrades.Luck.baseCost,
		costGrowth = PROVISIONAL.Upgrades.Luck.growth,
	},
}

-- No game-pass products survived recovery. An empty table prevents the client
-- from creating a purchase button and avoids inventing names, perks, or IDs.
Config.GamePasses = {}

Config.DailyReward = {
	CooldownHours = PROVISIONAL.DailyReward.CooldownHours,
	Gems = table.clone(PROVISIONAL.DailyReward.Gems),
}

Config.PlaytimeReward = {
	Intervals = table.clone(PROVISIONAL.PlaytimeReward.Intervals),
	Gems = table.clone(PROVISIONAL.PlaytimeReward.Gems),
}

-- RECOVERY_PROVISIONAL: rarity names and multipliers are confirmed; colors
-- were not recovered and are conservative display defaults.
Config.LuckRarities = {
	{ name = "COMMON", color = Color3.fromRGB(200, 200, 200), multiplier = 1 },
	{ name = "UNCOMMON", color = Color3.fromRGB(80, 200, 120), multiplier = 2 },
	{ name = "RARE", color = Color3.fromRGB(0, 170, 255), multiplier = 5 },
	{ name = "EPIC", color = Color3.fromRGB(170, 85, 255), multiplier = 15 },
	{ name = "LEGENDARY", color = Color3.fromRGB(255, 170, 0), multiplier = 50 },
	{ name = "MYTHIC", color = Color3.fromRGB(255, 70, 100), multiplier = 250 },
	{ name = "COSMIC", color = Color3.fromRGB(80, 255, 255), multiplier = 2_000 },
	{ name = "JACKPOT", color = Color3.fromRGB(255, 215, 0), multiplier = 77_777 },
}

local upgradesById = {}
for _, upgrade in ipairs(Config.Upgrades) do
	upgradesById[upgrade.id] = upgrade
end

local function finiteNonNegative(value, fallback, maximum)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end

	local safeValue = math.max(0, value)
	if maximum ~= nil then
		safeValue = math.min(safeValue, maximum)
	end
	return safeValue
end

local function finitePower(base, exponent, maximum)
	local result = base ^ exponent
	if result ~= result or result == math.huge or result == -math.huge then
		return maximum
	end
	return math.min(math.max(0, result), maximum)
end

function Config.getUpgradeCost(upgradeId, currentLevel)
	if type(upgradeId) ~= "string" then
		return 0
	end

	local upgrade = upgradesById[upgradeId]
	if not upgrade then
		return 0
	end

	local level = math.floor(finiteNonNegative(currentLevel, 0, upgrade.maxLevel))
	local growth = finitePower(upgrade.costGrowth, level, Config.Security.MaxEnergy)
	local cost = upgrade.baseCost * growth
	return math.floor(finiteNonNegative(cost, 0, Config.Security.MaxEnergy))
end

function Config.getRebirthCost(currentRebirths)
	local rebirths = math.floor(finiteNonNegative(currentRebirths, 0, Config.Security.MaxRebirths))
	local growth = finitePower(PROVISIONAL.Rebirth.costGrowth, rebirths, Config.Security.MaxEnergy)
	local cost = PROVISIONAL.Rebirth.baseCost * growth
	return math.floor(finiteNonNegative(cost, 0, Config.Security.MaxEnergy))
end

function Config.getRebirthMultiplier(rebirthCount)
	local rebirths = math.floor(finiteNonNegative(rebirthCount, 0, Config.Security.MaxRebirths))
	local multiplier = 1 + rebirths * PROVISIONAL.Rebirth.multiplierPerRebirth
	return finiteNonNegative(multiplier, 1, Config.Security.MaxCoreAmplifier)
end

return Config
