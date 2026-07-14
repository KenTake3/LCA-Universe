--!strict

export type StageDefinition = {
	id: string,
	stage: number,
	name: string,
	description: string,
	coreColor: Color3,
	lifetimeEnergyRequired: number,
	rebirthsRequired: number,
	unlockMode: string,
}

local FactoryDefinitions = {}

local SUPPORTED_UNLOCK_MODES = {
	DEFAULT = true,
	ENERGY = true,
	ENERGY_OR_REBIRTHS = true,
}

local function stage(definition: StageDefinition): StageDefinition
	return table.freeze(definition)
end

local stages: { StageDefinition } = {
	stage({
		id = "core_online",
		stage = 1,
		name = "Core Online",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "The core is online and ready to generate energy.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(0, 170, 255),
		lifetimeEnergyRequired = 0,
		rebirthsRequired = 0,
		unlockMode = "DEFAULT",
	}),
	stage({
		id = "power_generator",
		stage = 2,
		name = "Power Generator",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "A dedicated generator expands the core's energy systems.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(80, 200, 120),
		lifetimeEnergyRequired = 500,
		rebirthsRequired = 0,
		unlockMode = "ENERGY",
	}),
	stage({
		id = "industrial_factory",
		stage = 3,
		name = "Industrial Factory",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "Industrial systems surround the core with a larger factory.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(255, 170, 0),
		lifetimeEnergyRequired = 5_000,
		rebirthsRequired = 0,
		unlockMode = "ENERGY",
	}),
	stage({
		id = "advanced_reactor",
		stage = 4,
		name = "Advanced Reactor",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "An advanced reactor channels the core's growing power.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(170, 85, 255),
		lifetimeEnergyRequired = 50_000,
		rebirthsRequired = 1,
		unlockMode = "ENERGY_OR_REBIRTHS",
	}),
	stage({
		id = "mega_factory",
		stage = 5,
		name = "Mega Factory",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "A mega factory extends the core into a vast production complex.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(255, 70, 100),
		lifetimeEnergyRequired = 500_000,
		rebirthsRequired = 3,
		unlockMode = "ENERGY_OR_REBIRTHS",
	}),
	stage({
		id = "quantum_factory",
		stage = 6,
		name = "Quantum Factory",
		-- RECOVERY_PROVISIONAL: the original stage description was not recovered.
		description = "Quantum systems bring the factory to its recovered final stage.",
		-- RECOVERY_PROVISIONAL: the original stage color was not recovered.
		coreColor = Color3.fromRGB(80, 255, 255),
		lifetimeEnergyRequired = 5_000_000,
		rebirthsRequired = 10,
		unlockMode = "ENERGY_OR_REBIRTHS",
	}),
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function normalizeNonNegativeInteger(value: any): number
	if type(value) ~= "number" and type(value) ~= "string" then
		return 0
	end

	local numericValue = tonumber(value)
	if not isFiniteNumber(numericValue) then
		return 0
	end

	return math.floor(math.max(0, numericValue :: number))
end

local function normalizeStage(value: any): number
	local normalized = normalizeNonNegativeInteger(value)
	return math.clamp(normalized, 1, #stages)
end

local function isNonNegativeInteger(value: any): boolean
	return isFiniteNumber(value) and value >= 0 and value == math.floor(value)
end

local function validateDefinitions()
	assert(#stages == 6, "FactoryDefinitions must contain exactly six stages")

	local seenIds: { [string]: boolean } = {}
	local previousEnergy = 0
	for index, definition in ipairs(stages) do
		assert(definition.stage == index, "FactoryDefinitions stages must be contiguous")
		assert(definition.id ~= "" and not seenIds[definition.id], "FactoryDefinitions IDs must be unique and non-empty")
		seenIds[definition.id] = true
		assert(definition.name ~= "", "FactoryDefinitions names must be non-empty")
		assert(type(definition.description) == "string", "FactoryDefinitions descriptions must be strings")
		assert(typeof(definition.coreColor) == "Color3", "FactoryDefinitions core colors must be Color3 values")
		assert(SUPPORTED_UNLOCK_MODES[definition.unlockMode] == true, "FactoryDefinitions unlock mode is unsupported")
		assert(isNonNegativeInteger(definition.lifetimeEnergyRequired), "FactoryDefinitions energy requirements must be non-negative integers")
		assert(isNonNegativeInteger(definition.rebirthsRequired), "FactoryDefinitions rebirth requirements must be non-negative integers")
		assert(definition.lifetimeEnergyRequired >= previousEnergy, "FactoryDefinitions energy requirements must not decrease")
		previousEnergy = definition.lifetimeEnergyRequired
	end
end

local function isEligible(definition: StageDefinition, lifetimeEnergy: number, rebirths: number): boolean
	if definition.unlockMode == "DEFAULT" then
		return true
	elseif definition.unlockMode == "ENERGY" then
		return lifetimeEnergy >= definition.lifetimeEnergyRequired
	end

	return lifetimeEnergy >= definition.lifetimeEnergyRequired or rebirths >= definition.rebirthsRequired
end

local function clampedRatio(value: number, requirement: number): number
	if requirement <= 0 then
		return 1
	end

	local ratio = value / requirement
	if not isFiniteNumber(ratio) then
		return 0
	end
	return math.clamp(ratio, 0, 1)
end

validateDefinitions()
FactoryDefinitions.Stages = table.freeze(stages)

function FactoryDefinitions.getStage(stageValue: any): StageDefinition
	return FactoryDefinitions.Stages[normalizeStage(stageValue)]
end

function FactoryDefinitions.getNextStage(stageValue: any): StageDefinition?
	local currentStage = normalizeStage(stageValue)
	if currentStage >= #FactoryDefinitions.Stages then
		return nil
	end
	return FactoryDefinitions.Stages[currentStage + 1]
end

function FactoryDefinitions.calculateStage(lifetimeEnergyValue: any, rebirthsValue: any): number
	local lifetimeEnergy = normalizeNonNegativeInteger(lifetimeEnergyValue)
	local rebirths = normalizeNonNegativeInteger(rebirthsValue)
	local eligibleStage = 1

	for index = 2, #FactoryDefinitions.Stages do
		if isEligible(FactoryDefinitions.Stages[index], lifetimeEnergy, rebirths) then
			eligibleStage = index
		end
	end

	return eligibleStage
end

function FactoryDefinitions.getProgress(stageValue: any, lifetimeEnergyValue: any, rebirthsValue: any): number
	local currentStage = normalizeStage(stageValue)
	if currentStage >= #FactoryDefinitions.Stages then
		return 1
	end

	local lifetimeEnergy = normalizeNonNegativeInteger(lifetimeEnergyValue)
	local rebirths = normalizeNonNegativeInteger(rebirthsValue)
	local nextStage = FactoryDefinitions.Stages[currentStage + 1]
	if isEligible(nextStage, lifetimeEnergy, rebirths) then
		return 1
	end

	local energyProgress = clampedRatio(lifetimeEnergy, nextStage.lifetimeEnergyRequired)
	if nextStage.unlockMode == "ENERGY" then
		return energyProgress
	end

	-- RECOVERY_PROVISIONAL: the original OR-condition progress formula was not
	-- recovered. Display the greater of energy and rebirth progress.
	local rebirthProgress = clampedRatio(rebirths, nextStage.rebirthsRequired)
	return math.clamp(math.max(energyProgress, rebirthProgress), 0, 1)
end

return table.freeze(FactoryDefinitions)
