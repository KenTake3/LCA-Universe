--!strict

export type ReconcileResult = {
	read stage: number,
	read changed: boolean,
	read celebrate: boolean,
}

type PartState = {
	instance: BasePart,
	transparency: number,
	canCollide: boolean,
	canTouch: boolean,
	canQuery: boolean,
}

type Effect = Light | ParticleEmitter | Trail | Beam

type EffectState = {
	instance: Effect,
	enabled: boolean,
}

type StageLayer = {
	stage: number,
	parts: { PartState },
	effects: { EffectState },
}

local FactoryVisualController = {}
local initialized = false
local layers: { StageLayer } = {}
local previousStage: number? = nil
local previousRebirths: number? = nil

local function finiteInteger(value: unknown): number?
	if type(value) ~= "number"
		or value ~= value
		or value == math.huge
		or value == -math.huge
		or value ~= math.floor(value)
	then
		return nil
	end
	return value
end

local function cacheLayers()
	initialized = true
	local root = workspace:FindFirstChild("FactoryEvolution")
	if root == nil then
		return
	end

	local discovered: { { stage: number, folder: Folder } } = {}
	for _, child in root:GetChildren() do
		if child:IsA("Folder") then
			local stageText = string.match(child.Name, "^Stage(%d+)$")
			local stageNumber = if stageText ~= nil then tonumber(stageText) else nil
			if stageNumber ~= nil and stageNumber >= 1 and stageNumber == math.floor(stageNumber) then
				table.insert(discovered, {
					stage = stageNumber,
					folder = child,
				})
			end
		end
	end

	table.sort(discovered, function(left, right)
		return left.stage < right.stage
	end)

	for _, discoveredLayer in discovered do
		local partStates: { PartState } = {}
		local effectStates: { EffectState } = {}
		for _, descendant in discoveredLayer.folder:GetDescendants() do
			if descendant:IsA("BasePart") then
				table.insert(partStates, {
					instance = descendant,
					transparency = descendant.Transparency,
					canCollide = descendant.CanCollide,
					canTouch = descendant.CanTouch,
					canQuery = descendant.CanQuery,
				})
			elseif descendant:IsA("Light")
				or descendant:IsA("ParticleEmitter")
				or descendant:IsA("Trail")
				or descendant:IsA("Beam")
			then
				table.insert(effectStates, {
					instance = descendant,
					enabled = descendant.Enabled,
				})
			end
		end

		table.insert(layers, {
			stage = discoveredLayer.stage,
			parts = partStates,
			effects = effectStates,
		})
	end
end

local function renderStage(stage: number)
	for _, layer in layers do
		local visible = layer.stage <= stage
		for _, state in layer.parts do
			local part = state.instance
			part.Transparency = if visible then state.transparency else 1
			part.CanCollide = visible and state.canCollide
			part.CanTouch = visible and state.canTouch
			part.CanQuery = visible and state.canQuery
		end
		for _, state in layer.effects do
			state.instance.Enabled = visible and state.enabled
		end
	end
end

function FactoryVisualController.reconcile(factoryStageValue: unknown, rebirthsValue: unknown): ReconcileResult?
	local factoryStage = finiteInteger(factoryStageValue)
	local rebirths = finiteInteger(rebirthsValue)
	if factoryStage == nil or factoryStage < 1 or rebirths == nil or rebirths < 0 then
		return nil
	end

	if not initialized then
		cacheLayers()
	end

	local lastStage = previousStage
	local lastRebirths = previousRebirths
	local changed = lastStage == nil or factoryStage ~= lastStage
	local celebrate = lastStage ~= nil
		and lastRebirths ~= nil
		and factoryStage > lastStage
		and rebirths > lastRebirths

	if changed then
		local renderSucceeded = pcall(renderStage, factoryStage)
		if not renderSucceeded then
			return nil
		end
	end
	previousStage = factoryStage
	previousRebirths = rebirths

	return table.freeze({
		stage = factoryStage,
		changed = changed,
		celebrate = celebrate,
	})
end

return table.freeze(FactoryVisualController)
