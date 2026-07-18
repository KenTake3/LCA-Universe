--!strict

export type UpgradeId = "ClickPower" | "AutoPower" | "CoreAmplifier" | "Luck"

export type EnergyChangedEvent = {
	read name: "EnergyChanged",
	read previousEnergy: number,
	read energy: number,
	read delta: number,
}

export type FactoryStageChangedEvent = {
	read name: "FactoryStageChanged",
	read previousFactoryStage: number,
	read factoryStage: number,
}

export type RebirthCompletedEvent = {
	read name: "RebirthCompleted",
	read previousRebirths: number,
	read rebirths: number,
	read previousFactoryStage: number,
	read factoryStage: number,
}

export type UpgradeLevelChange = {
	read upgradeId: UpgradeId,
	read previousLevel: number,
	read level: number,
}

export type UpgradeLevelsChangedEvent = {
	read name: "UpgradeLevelsChanged",
	read changes: { read [number]: UpgradeLevelChange },
}

export type PresentationEvent = EnergyChangedEvent
	| FactoryStageChangedEvent
	| RebirthCompletedEvent
	| UpgradeLevelsChangedEvent

export type Listener = (event: PresentationEvent) -> ()

export type Connection = {
	read Disconnect: (self: Connection) -> (),
}

type UpgradeLevels = {
	ClickPower: number,
	AutoPower: number,
	CoreAmplifier: number,
	Luck: number,
}

type AuthoritativeState = {
	Energy: number,
	FactoryStage: number,
	Rebirths: number,
	UpgradeLevels: UpgradeLevels,
}

local PresentationCoordinator = {}
local initialized = false
local previousState: AuthoritativeState? = nil
local listeners: { [Listener]: boolean } = {}
local UPGRADE_IDS: { UpgradeId } = { "ClickPower", "AutoPower", "CoreAmplifier", "Luck" }

local function finiteNonNegativeInteger(value: unknown): number?
	if type(value) ~= "number"
		or value ~= value
		or value == math.huge
		or value == -math.huge
		or value < 0
		or value ~= math.floor(value)
	then
		return nil
	end
	return value
end

local function snapshot(packet: unknown): AuthoritativeState?
	if type(packet) ~= "table" then
		return nil
	end

	local energy = finiteNonNegativeInteger(packet.Energy)
	local factoryStage = finiteNonNegativeInteger(packet.FactoryStage)
	local rebirths = finiteNonNegativeInteger(packet.Rebirths)
	local rawUpgradeLevels = packet.UpgradeLevels
	if energy == nil
		or factoryStage == nil
		or factoryStage < 1
		or rebirths == nil
		or type(rawUpgradeLevels) ~= "table"
	then
		return nil
	end

	local clickPower = finiteNonNegativeInteger(rawUpgradeLevels.ClickPower)
	local autoPower = finiteNonNegativeInteger(rawUpgradeLevels.AutoPower)
	local coreAmplifier = finiteNonNegativeInteger(rawUpgradeLevels.CoreAmplifier)
	local luck = finiteNonNegativeInteger(rawUpgradeLevels.Luck)
	if clickPower == nil or autoPower == nil or coreAmplifier == nil or luck == nil then
		return nil
	end

	return {
		Energy = energy,
		FactoryStage = factoryStage,
		Rebirths = rebirths,
		UpgradeLevels = {
			ClickPower = clickPower,
			AutoPower = autoPower,
			CoreAmplifier = coreAmplifier,
			Luck = luck,
		},
	}
end

local function dispatch(event: PresentationEvent)
	for listener in listeners do
		pcall(listener, event)
	end
end

function PresentationCoordinator.init()
	initialized = true
end

function PresentationCoordinator.subscribe(listener: Listener): Connection
	if type(listener) ~= "function" then
		error("PresentationCoordinator.subscribe requires a listener", 2)
	end
	listeners[listener] = true

	local connected = true
	local connection: Connection
	connection = {
		Disconnect = function(_self: Connection)
			if not connected then
				return
			end
			connected = false
			listeners[listener] = nil
		end,
	}
	return table.freeze(connection)
end

function PresentationCoordinator.processDataSync(packet: unknown): boolean
	if not initialized then
		return false
	end

	local currentState = snapshot(packet)
	if currentState == nil then
		return false
	end

	local previous = previousState
	previousState = currentState
	if previous == nil then
		return true
	end

	if currentState.Energy ~= previous.Energy then
		dispatch(table.freeze({
			name = "EnergyChanged",
			previousEnergy = previous.Energy,
			energy = currentState.Energy,
			delta = currentState.Energy - previous.Energy,
		}))
	end

	local changes: { UpgradeLevelChange } = {}
	for _, upgradeId in UPGRADE_IDS do
		local previousLevel = previous.UpgradeLevels[upgradeId]
		local level = currentState.UpgradeLevels[upgradeId]
		if level ~= previousLevel then
			table.insert(changes, table.freeze({
				upgradeId = upgradeId,
				previousLevel = previousLevel,
				level = level,
			}))
		end
	end
	if #changes > 0 then
		dispatch(table.freeze({
			name = "UpgradeLevelsChanged",
			changes = table.freeze(changes),
		}))
	end

	if currentState.Rebirths > previous.Rebirths then
		dispatch(table.freeze({
			name = "RebirthCompleted",
			previousRebirths = previous.Rebirths,
			rebirths = currentState.Rebirths,
			previousFactoryStage = previous.FactoryStage,
			factoryStage = currentState.FactoryStage,
		}))
	end

	if currentState.FactoryStage ~= previous.FactoryStage then
		dispatch(table.freeze({
			name = "FactoryStageChanged",
			previousFactoryStage = previous.FactoryStage,
			factoryStage = currentState.FactoryStage,
		}))
	end

	return true
end

return table.freeze(PresentationCoordinator)
