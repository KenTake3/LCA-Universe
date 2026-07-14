--!strict

local Config = require(game.ReplicatedStorage.LCA_Shared.Config)

export type GameplayService = {
	press: (player: Player) -> (boolean, string, { reward: number, syncSucceeded: boolean }?),
	buyUpgrade: (player: Player, upgradeId: string) -> (boolean, string, any?),
}

export type Dependencies = {
	pressCore: RemoteEvent,
	pressFeedback: RemoteEvent,
	buyUpgrade: RemoteEvent,
	gameplayService: GameplayService,
}

local GameplayRemoteController = {}
local dependencies: Dependencies? = nil
local pressTimestamps: { [Player]: { number } } = setmetatable({}, { __mode = "k" }) :: any
local upgradeTimestamps: { [Player]: { number } } = setmetatable({}, { __mode = "k" }) :: any
local SUPPORTED_UPGRADES = {
	ClickPower = true,
	AutoPower = true,
	CoreAmplifier = true,
	Luck = true,
}

local function isFiniteInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

local function pressLimit(): number
	local limit = Config.MaxPressesPerSecond
	if not isFiniteInteger(limit) or limit < 1 then
		error("GameplayRemoteController requires a positive integer Config.MaxPressesPerSecond", 3)
	end
	return limit
end

local function commonRarity(): any
	local rarity = Config.LuckRarities[1]
	if type(rarity) ~= "table"
		or rarity.name ~= "COMMON"
		or typeof(rarity.color) ~= "Color3"
	then
		error("GameplayRemoteController requires Config.LuckRarities[1] COMMON presentation data", 3)
	end
	return rarity
end

local function validateDependencies(candidate: any): Dependencies
	if type(candidate) ~= "table" then
		error("GameplayRemoteController.init requires a dependency table", 3)
	end

	local expectedKeys = { pressCore = true, pressFeedback = true, buyUpgrade = true, gameplayService = true }
	for key in pairs(candidate) do
		if not expectedKeys[key] then
			error("GameplayRemoteController.init received an unexpected dependency", 3)
		end
	end

	local pressCore = candidate.pressCore
	local pressFeedback = candidate.pressFeedback
	local buyUpgrade = candidate.buyUpgrade
	local gameplayService = candidate.gameplayService
	if typeof(pressCore) ~= "Instance"
		or not pressCore:IsA("RemoteEvent")
		or typeof(pressFeedback) ~= "Instance"
		or not pressFeedback:IsA("RemoteEvent")
		or typeof(buyUpgrade) ~= "Instance"
		or not buyUpgrade:IsA("RemoteEvent")
		or type(gameplayService) ~= "table"
		or type(gameplayService.press) ~= "function"
		or type(gameplayService.buyUpgrade) ~= "function"
	then
		error("GameplayRemoteController.init received malformed dependencies", 3)
	end

	pressLimit()
	commonRarity()
	return table.freeze({
		pressCore = pressCore,
		pressFeedback = pressFeedback,
		buyUpgrade = buyUpgrade,
		gameplayService = gameplayService,
	}) :: Dependencies
end

local function acceptUpgrade(player: Player): boolean
	local now = os.clock()
	local timestamps = upgradeTimestamps[player]
	if timestamps == nil then
		timestamps = {}
		upgradeTimestamps[player] = timestamps
	end

	for index = #timestamps, 1, -1 do
		if now - timestamps[index] > 1 then
			table.remove(timestamps, index)
		end
	end
	if #timestamps >= pressLimit() then
		return false
	end
	table.insert(timestamps, now)
	return true
end

local function acceptPress(player: Player): boolean
	local now = os.clock()
	local timestamps = pressTimestamps[player]
	if timestamps == nil then
		timestamps = {}
		pressTimestamps[player] = timestamps
	end

	for index = #timestamps, 1, -1 do
		if now - timestamps[index] > 1 then
			table.remove(timestamps, index)
		end
	end
	if #timestamps >= pressLimit() then
		return false
	end
	table.insert(timestamps, now)
	return true
end

local function onBuyUpgrade(player: Player, ...: any)
	if select("#", ...) ~= 1 then
		return
	end
	local upgradeId = ...
	if type(upgradeId) ~= "string" or not SUPPORTED_UPGRADES[upgradeId] or not acceptUpgrade(player) then
		return
	end

	local configured = dependencies :: Dependencies
	pcall(configured.gameplayService.buyUpgrade, player, upgradeId)
end

local function onPress(player: Player, ...: any)
	if select("#", ...) ~= 0 or not acceptPress(player) then
		return
	end

	local configured = dependencies :: Dependencies
	local callOk, succeeded, _, result = pcall(configured.gameplayService.press, player)
	if not callOk or not succeeded or type(result) ~= "table" or not isFiniteInteger(result.reward) then
		return
	end

	local rarity = commonRarity()
	configured.pressFeedback:FireClient(player, {
		reward = result.reward,
		rarityName = "COMMON",
		rarityColor = rarity.color,
		rarityIndex = 1,
	})
end

function GameplayRemoteController.init(candidate: Dependencies)
	local validated = validateDependencies(candidate)
	if dependencies ~= nil then
		if dependencies.pressCore == validated.pressCore
			and dependencies.pressFeedback == validated.pressFeedback
			and dependencies.buyUpgrade == validated.buyUpgrade
			and dependencies.gameplayService == validated.gameplayService
		then
			return
		end
		error("GameplayRemoteController is already initialized with different dependencies", 2)
	end

	dependencies = validated
	validated.pressCore.OnServerEvent:Connect(onPress)
	validated.buyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
end

return table.freeze(GameplayRemoteController)
