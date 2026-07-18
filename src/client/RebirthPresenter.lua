--!strict

local PresentationCoordinator = require(script.Parent.PresentationCoordinator)

export type Dependencies = {
	read rebirthsLabel: TextLabel,
	read multiplierLabel: TextLabel,
	read tweenService: TweenService,
	read showRoutine: (text: string, color: Color3) -> (),
	read showMajor: (text: string, color: Color3) -> (),
	read getFactoryName: (stage: number) -> string,
	read getFactoryColor: (stage: number) -> Color3,
	read playAudio: (majorFactoryEra: boolean) -> (),
	read playCamera: (majorFactoryEra: boolean) -> (),
	read getReducedMotion: () -> boolean,
}

local RebirthPresenter = {}
local EMPHASIS_SECONDS = 0.14
local RESTORE_SECONDS = 0.36
local REBIRTH_COLOR = Color3.fromRGB(140, 80, 220)
local FACTORY_COLOR = Color3.fromRGB(255, 200, 50)

local dependencies: Dependencies? = nil
local connection: PresentationCoordinator.Connection? = nil
local generation = 0
local activeTweens: { Tween } = {}
local originalRebirthColor: Color3? = nil
local originalMultiplierColor: Color3? = nil

local function cancelTweens()
	for _, tween in activeTweens do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

local function restore()
	generation += 1
	cancelTweens()
	local configured = dependencies
	local rebirthColor = originalRebirthColor
	local multiplierColor = originalMultiplierColor
	if configured ~= nil then
		if rebirthColor ~= nil then
			configured.rebirthsLabel.TextColor3 = rebirthColor
		end
		if multiplierColor ~= nil then
			configured.multiplierLabel.TextColor3 = multiplierColor
		end
	end
	originalRebirthColor = nil
	originalMultiplierColor = nil
end

local function emphasize(major: boolean)
	local configured = dependencies
	if configured == nil then
		return
	end
	restore()
	generation += 1
	local currentGeneration = generation
	originalRebirthColor = configured.rebirthsLabel.TextColor3
	originalMultiplierColor = configured.multiplierLabel.TextColor3
	local targetColor = if major then FACTORY_COLOR else REBIRTH_COLOR
	local emphasisDuration = if configured.getReducedMotion() then 0.08 else EMPHASIS_SECONDS

	local rebirthTween = configured.tweenService:Create(
		configured.rebirthsLabel,
		TweenInfo.new(emphasisDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextColor3 = targetColor }
	)
	local multiplierTween = configured.tweenService:Create(
		configured.multiplierLabel,
		TweenInfo.new(emphasisDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextColor3 = targetColor }
	)
	table.insert(activeTweens, rebirthTween)
	table.insert(activeTweens, multiplierTween)
	rebirthTween:Play()
	multiplierTween:Play()

	task.delay(emphasisDuration, function()
		if currentGeneration ~= generation or dependencies == nil then
			return
		end
		cancelTweens()
		local rebirthColor = originalRebirthColor
		local multiplierColor = originalMultiplierColor
		if rebirthColor == nil or multiplierColor == nil then
			restore()
			return
		end
		local rebirthRestore = configured.tweenService:Create(
			configured.rebirthsLabel,
			TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextColor3 = rebirthColor }
		)
		local multiplierRestore = configured.tweenService:Create(
			configured.multiplierLabel,
			TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextColor3 = multiplierColor }
		)
		table.insert(activeTweens, rebirthRestore)
		table.insert(activeTweens, multiplierRestore)
		rebirthRestore:Play()
		multiplierRestore:Play()
		task.delay(RESTORE_SECONDS, function()
			if currentGeneration == generation then
				restore()
			end
		end)
	end)
end

local function onEvent(event: PresentationCoordinator.PresentationEvent)
	if event.name ~= "RebirthCompleted" then
		return
	end
	local major = event.factoryStage > event.previousFactoryStage
	if major then
		-- WorldAwakeningPresenter exclusively owns stage-advance presentation.
		return
	end
	emphasize(major)
	local configured = dependencies
	if configured == nil then
		return
	end
	configured.showRoutine("REBIRTH COMPLETE! Cycle " .. event.rebirths, REBIRTH_COLOR)
	configured.playAudio(false)
	configured.playCamera(false)
end

function RebirthPresenter.init(candidate: Dependencies)
	if not candidate.rebirthsLabel:IsA("TextLabel")
		or not candidate.multiplierLabel:IsA("TextLabel")
		or not candidate.tweenService:IsA("TweenService")
		or type(candidate.showRoutine) ~= "function"
		or type(candidate.showMajor) ~= "function"
		or type(candidate.getFactoryName) ~= "function"
		or type(candidate.getFactoryColor) ~= "function"
		or type(candidate.playAudio) ~= "function"
		or type(candidate.playCamera) ~= "function"
		or type(candidate.getReducedMotion) ~= "function"
	then
		error("RebirthPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.rebirthsLabel == candidate.rebirthsLabel
			and dependencies.multiplierLabel == candidate.multiplierLabel
			and dependencies.tweenService == candidate.tweenService
			and dependencies.showRoutine == candidate.showRoutine
			and dependencies.showMajor == candidate.showMajor
			and dependencies.getFactoryName == candidate.getFactoryName
			and dependencies.getFactoryColor == candidate.getFactoryColor
			and dependencies.playAudio == candidate.playAudio
			and dependencies.playCamera == candidate.playCamera
			and dependencies.getReducedMotion == candidate.getReducedMotion
		then
			return
		end
		error("RebirthPresenter is already initialized with different dependencies", 2)
	end
	dependencies = table.freeze({
		rebirthsLabel = candidate.rebirthsLabel,
		multiplierLabel = candidate.multiplierLabel,
		tweenService = candidate.tweenService,
		showRoutine = candidate.showRoutine,
		showMajor = candidate.showMajor,
		getFactoryName = candidate.getFactoryName,
		getFactoryColor = candidate.getFactoryColor,
		playAudio = candidate.playAudio,
		playCamera = candidate.playCamera,
		getReducedMotion = candidate.getReducedMotion,
	})
	connection = PresentationCoordinator.subscribe(onEvent)
end

function RebirthPresenter.destroy()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	restore()
	dependencies = nil
end

return table.freeze(RebirthPresenter)
