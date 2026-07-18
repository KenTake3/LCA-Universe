--!strict

local PresentationCoordinator = require(script.Parent.PresentationCoordinator)

export type Dependencies = {
	read getAwakeningName: (stage: number) -> string,
	read getAwakeningColor: (stage: number) -> Color3,
	read playPropagation: (color: Color3) -> (),
	read cancelPropagation: () -> (),
	read showMajor: (text: string, color: Color3) -> (),
	read playAudio: () -> (),
	read playCamera: () -> (),
	read getReducedMotion: () -> boolean,
}

local WorldAwakeningPresenter = {}
local AUDIO_SECONDS = 0.25
local CAMERA_SECONDS = 0.9
local NOTIFICATION_SECONDS = 0.95
local REDUCED_NOTIFICATION_SECONDS = 0.08

local dependencies: Dependencies? = nil
local connection: PresentationCoordinator.Connection? = nil
local generation = 0

local function cancel()
	generation += 1
	local configured = dependencies
	if configured ~= nil then
		configured.cancelPropagation()
	end
end

local function onEvent(event: PresentationCoordinator.PresentationEvent)
	if event.name ~= "FactoryStageChanged" then
		return
	end
	if event.factoryStage <= event.previousFactoryStage then
		cancel()
		return
	end

	cancel()
	generation += 1
	local currentGeneration = generation
	local configured = dependencies
	if configured == nil then
		return
	end
	local stage = event.factoryStage
	local name = configured.getAwakeningName(stage)
	local color = configured.getAwakeningColor(stage)
	configured.playPropagation(color)

	local reducedMotion = configured.getReducedMotion()
	local audioDelay = if reducedMotion then 0 else AUDIO_SECONDS
	local cameraDelay = if reducedMotion then 0 else CAMERA_SECONDS
	local notificationDelay = if reducedMotion then REDUCED_NOTIFICATION_SECONDS else NOTIFICATION_SECONDS

	task.delay(audioDelay, function()
		if currentGeneration == generation and dependencies ~= nil then
			configured.playAudio()
		end
	end)
	task.delay(cameraDelay, function()
		if currentGeneration == generation and dependencies ~= nil and not configured.getReducedMotion() then
			configured.playCamera()
		end
	end)
	task.delay(notificationDelay, function()
		if currentGeneration == generation and dependencies ~= nil then
			configured.showMajor("WORLD AWAKENED! Awakening " .. stage .. ": " .. name, color)
		end
	end)
end

function WorldAwakeningPresenter.init(candidate: Dependencies)
	if type(candidate.getAwakeningName) ~= "function"
		or type(candidate.getAwakeningColor) ~= "function"
		or type(candidate.playPropagation) ~= "function"
		or type(candidate.cancelPropagation) ~= "function"
		or type(candidate.showMajor) ~= "function"
		or type(candidate.playAudio) ~= "function"
		or type(candidate.playCamera) ~= "function"
		or type(candidate.getReducedMotion) ~= "function"
	then
		error("WorldAwakeningPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.getAwakeningName == candidate.getAwakeningName
			and dependencies.getAwakeningColor == candidate.getAwakeningColor
			and dependencies.playPropagation == candidate.playPropagation
			and dependencies.cancelPropagation == candidate.cancelPropagation
			and dependencies.showMajor == candidate.showMajor
			and dependencies.playAudio == candidate.playAudio
			and dependencies.playCamera == candidate.playCamera
			and dependencies.getReducedMotion == candidate.getReducedMotion
		then
			return
		end
		error("WorldAwakeningPresenter is already initialized with different dependencies", 2)
	end

	dependencies = table.freeze(candidate)
	connection = PresentationCoordinator.subscribe(onEvent)
end

function WorldAwakeningPresenter.destroy()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	cancel()
	dependencies = nil
end

return table.freeze(WorldAwakeningPresenter)
