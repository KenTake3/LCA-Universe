--!strict

export type PreferenceConnection = {
	read Disconnect: (self: PreferenceConnection) -> (),
}

export type Dependencies = {
	read tweenService: TweenService,
	read corePart: BasePart?,
	read worldTarget: BasePart?,
	read getReducedMotion: () -> boolean,
	read subscribeReducedMotion: (listener: (reducedMotion: boolean) -> ()) -> PreferenceConnection,
}

local EnergyPropagationPresenter = {}
local CONTACT_IN_SECONDS = 0.06
local CONTACT_OUT_SECONDS = 0.12
local MANUAL_IN_SECONDS = 0.08
local MANUAL_OUT_SECONDS = 0.32
local MAJOR_GATHER_SECONDS = 0.25
local MAJOR_RELEASE_SECONDS = 0.35
local MAJOR_SETTLE_SECONDS = 0.7
local LIGHT_RANGE = 18
local COLOR_LIFT = 0.22
local BEAM_REVEAL_DELAY = 0.06
local BEAM_REVEAL_SECONDS = 0.12
local TARGET_PEAK_DELAY = 0.18
local TARGET_IN_SECONDS = 0.08
local TARGET_HOLD_SECONDS = 0.06
local TARGET_OUT_SECONDS = 0.28
local BEAM_FADE_DELAY = 0.3
local BEAM_FADE_SECONDS = 0.22
local WORLD_CLEANUP_SECONDS = 0.7

local dependencies: Dependencies? = nil
local light: PointLight? = nil
local activeTween: Tween? = nil
local generation = 0
local majorActive = false
local preferenceConnection: PreferenceConnection? = nil

local worldGeneration = 0
local worldAvailable = false
local worldTarget: BasePart? = nil
local approvedStage: Instance? = nil
local approvedFactoryRoot: Instance? = nil
local coreAttachment: Attachment? = nil
local targetAttachment: Attachment? = nil
local transferBeam: Beam? = nil
local targetLight: PointLight? = nil
local beamTween: Tween? = nil
local targetTween: Tween? = nil

local function liftColor(color: Color3): Color3
	return color:Lerp(Color3.new(1, 1, 1), COLOR_LIFT)
end

local function cancelTween(tween: Tween?)
	if tween ~= nil then
		tween:Cancel()
	end
end

local function cancelCoreTween()
	cancelTween(activeTween)
	activeTween = nil
end

local function restoreCore()
	generation += 1
	cancelCoreTween()
	if light ~= nil then
		light.Brightness = 0
	end
end

local function neutralizeWorld()
	worldGeneration += 1
	cancelTween(beamTween)
	cancelTween(targetTween)
	beamTween = nil
	targetTween = nil
	if transferBeam ~= nil then
		transferBeam.Enabled = false
		transferBeam.Transparency = NumberSequence.new(1)
		transferBeam.Width0 = 0
		transferBeam.Width1 = 0
	end
	if targetLight ~= nil then
		targetLight.Brightness = 0
	end
end

local function destroyWorldInstances()
	neutralizeWorld()
	if transferBeam ~= nil then
		transferBeam:Destroy()
	end
	if targetLight ~= nil then
		targetLight:Destroy()
	end
	if targetAttachment ~= nil then
		targetAttachment:Destroy()
	end
	if coreAttachment ~= nil then
		coreAttachment:Destroy()
	end
	transferBeam = nil
	targetLight = nil
	targetAttachment = nil
	coreAttachment = nil
	worldTarget = nil
	approvedStage = nil
	approvedFactoryRoot = nil
	worldAvailable = false
end

local function worldTargetIsValid(): boolean
	local configured = dependencies
	local target = worldTarget
	local stage = approvedStage
	local factoryRoot = approvedFactoryRoot
	return worldAvailable
		and configured ~= nil
		and configured.corePart ~= nil
		and configured.corePart.Parent ~= nil
		and target ~= nil
		and stage ~= nil
		and factoryRoot ~= nil
		and target.Parent == stage
		and stage.Parent == factoryRoot
		and factoryRoot.Parent == workspace
		and coreAttachment ~= nil
		and coreAttachment.Parent == configured.corePart
		and targetAttachment ~= nil
		and targetAttachment.Parent == target
		and transferBeam ~= nil
		and targetLight ~= nil
end

local function validateWorldTarget(): boolean
	if worldTargetIsValid() then
		return true
	end
	if worldAvailable then
		destroyWorldInstances()
	end
	return false
end

local function tweenBrightness(
	currentGeneration: number,
	brightness: number,
	duration: number,
	onComplete: (() -> ())?
)
	local configured = dependencies
	local ownedLight = light
	if configured == nil or ownedLight == nil or currentGeneration ~= generation then
		return
	end
	cancelCoreTween()
	local tween = configured.tweenService:Create(
		ownedLight,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = brightness }
	)
	activeTween = tween
	tween:Play()
	task.delay(duration, function()
		if currentGeneration ~= generation or dependencies == nil or light ~= ownedLight then
			return
		end
		activeTween = nil
		if onComplete ~= nil then
			onComplete()
		end
	end)
end

local function pulse(color: Color3, peak: number, inSeconds: number, outSeconds: number)
	local configured = dependencies
	local ownedLight = light
	if configured == nil or ownedLight == nil then
		return false
	end
	restoreCore()
	generation += 1
	local currentGeneration = generation
	ownedLight.Color = liftColor(color)
	local reducedMotion = configured.getReducedMotion()
	local adjustedPeak = if reducedMotion then math.min(peak, 1) else peak
	local adjustedIn = if reducedMotion then math.min(inSeconds, 0.05) else inSeconds
	local adjustedOut = if reducedMotion then math.min(outSeconds, 0.12) else outSeconds
	tweenBrightness(currentGeneration, adjustedPeak, adjustedIn, function()
		tweenBrightness(currentGeneration, 0, adjustedOut, function()
			if currentGeneration == generation then
				restoreCore()
			end
		end)
	end)
	return true
end

local function tweenTargetBrightness(currentWorldGeneration: number, brightness: number, duration: number)
	local configured = dependencies
	local ownedTargetLight = targetLight
	if configured == nil or ownedTargetLight == nil or currentWorldGeneration ~= worldGeneration then
		return
	end
	cancelTween(targetTween)
	local tween = configured.tweenService:Create(
		ownedTargetLight,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = brightness }
	)
	targetTween = tween
	tween:Play()
end

local function presentWorldResponse(color: Color3): boolean
	local configured = dependencies
	if configured == nil or not validateWorldTarget() then
		return false
	end

	neutralizeWorld()
	worldGeneration += 1
	local currentWorldGeneration = worldGeneration
	local ownedBeam = transferBeam :: Beam
	local ownedTargetLight = targetLight :: PointLight
	local displayColor = liftColor(color)
	ownedBeam.Color = ColorSequence.new(displayColor)
	ownedTargetLight.Color = displayColor

	if configured.getReducedMotion() then
		tweenTargetBrightness(currentWorldGeneration, 0.65, 0.05)
		task.delay(0.05, function()
			if currentWorldGeneration == worldGeneration then
				tweenTargetBrightness(currentWorldGeneration, 0, 0.12)
			end
		end)
		task.delay(0.2, function()
			if currentWorldGeneration == worldGeneration then
				neutralizeWorld()
			end
		end)
		return true
	end

	task.delay(BEAM_REVEAL_DELAY, function()
		if currentWorldGeneration ~= worldGeneration or not validateWorldTarget() then
			return
		end
		ownedBeam.Enabled = true
		ownedBeam.Transparency = NumberSequence.new(0.28)
		ownedBeam.Width0 = 0
		ownedBeam.Width1 = 0
		local tween = configured.tweenService:Create(
			ownedBeam,
			TweenInfo.new(BEAM_REVEAL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Width0 = 0.12, Width1 = 0.06 }
		)
		beamTween = tween
		tween:Play()
	end)

	task.delay(TARGET_PEAK_DELAY, function()
		if currentWorldGeneration ~= worldGeneration or not validateWorldTarget() then
			return
		end
		tweenTargetBrightness(currentWorldGeneration, 1.5, TARGET_IN_SECONDS)
		task.delay(TARGET_IN_SECONDS + TARGET_HOLD_SECONDS, function()
			if currentWorldGeneration == worldGeneration then
				tweenTargetBrightness(currentWorldGeneration, 0, TARGET_OUT_SECONDS)
			end
		end)
	end)

	task.delay(BEAM_FADE_DELAY, function()
		if currentWorldGeneration ~= worldGeneration or not validateWorldTarget() then
			return
		end
		cancelTween(beamTween)
		local tween = configured.tweenService:Create(
			ownedBeam,
			TweenInfo.new(BEAM_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Width0 = 0, Width1 = 0 }
		)
		beamTween = tween
		tween:Play()
	end)

	task.delay(WORLD_CLEANUP_SECONDS, function()
		if currentWorldGeneration == worldGeneration then
			neutralizeWorld()
		end
	end)
	return true
end

function EnergyPropagationPresenter.init(candidate: Dependencies)
	if not candidate.tweenService:IsA("TweenService")
		or (candidate.corePart ~= nil and not candidate.corePart:IsA("BasePart"))
		or (candidate.worldTarget ~= nil and not candidate.worldTarget:IsA("BasePart"))
		or type(candidate.getReducedMotion) ~= "function"
		or type(candidate.subscribeReducedMotion) ~= "function"
	then
		error("EnergyPropagationPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.tweenService == candidate.tweenService
			and dependencies.corePart == candidate.corePart
			and dependencies.worldTarget == candidate.worldTarget
			and dependencies.getReducedMotion == candidate.getReducedMotion
			and dependencies.subscribeReducedMotion == candidate.subscribeReducedMotion
		then
			return
		end
		error("EnergyPropagationPresenter is already initialized with different dependencies", 2)
	end

	dependencies = table.freeze(candidate)
	if candidate.corePart ~= nil then
		local presentationLight = Instance.new("PointLight")
		presentationLight.Name = "WorldAwakeningPresentationLight"
		presentationLight.Brightness = 0
		presentationLight.Range = LIGHT_RANGE
		presentationLight.Shadows = false
		presentationLight.Parent = candidate.corePart
		light = presentationLight
	end

	if candidate.corePart ~= nil and candidate.worldTarget ~= nil then
		worldTarget = candidate.worldTarget
		approvedStage = candidate.worldTarget.Parent
		approvedFactoryRoot = if approvedStage ~= nil then approvedStage.Parent else nil

		local sourceAttachment = Instance.new("Attachment")
		sourceAttachment.Name = "WP15CoreTransferAttachment"
		sourceAttachment.Parent = candidate.corePart
		coreAttachment = sourceAttachment

		local destinationAttachment = Instance.new("Attachment")
		destinationAttachment.Name = "WP15BaseRingResponseAttachment"
		destinationAttachment.Parent = candidate.worldTarget
		targetAttachment = destinationAttachment

		local beam = Instance.new("Beam")
		beam.Name = "WP15CoreToBaseRingBeam"
		beam.Attachment0 = sourceAttachment
		beam.Attachment1 = destinationAttachment
		beam.Enabled = false
		beam.FaceCamera = true
		beam.LightEmission = 0.7
		beam.LightInfluence = 0
		beam.Transparency = NumberSequence.new(1)
		beam.Width0 = 0
		beam.Width1 = 0
		beam.Parent = sourceAttachment
		transferBeam = beam

		local responseLight = Instance.new("PointLight")
		responseLight.Name = "WP15BaseRingResponseLight"
		responseLight.Brightness = 0
		responseLight.Range = 10
		responseLight.Shadows = false
		responseLight.Parent = candidate.worldTarget
		targetLight = responseLight
		worldAvailable = true
		worldAvailable = worldTargetIsValid()
		if not worldAvailable then
			destroyWorldInstances()
		end
	end

	preferenceConnection = candidate.subscribeReducedMotion(function()
		restoreCore()
		majorActive = false
		neutralizeWorld()
	end)
end

function EnergyPropagationPresenter.playContact(): boolean
	if majorActive then
		return false
	end
	return pulse(Color3.fromRGB(165, 230, 255), 1, CONTACT_IN_SECONDS, CONTACT_OUT_SECONDS)
end

function EnergyPropagationPresenter.presentManual(payload: unknown): boolean
	if type(payload) ~= "table" or typeof(payload.rarityColor) ~= "Color3" then
		return false
	end
	local reward = payload.reward
	if type(reward) ~= "number"
		or reward ~= reward
		or reward == math.huge
		or reward == -math.huge
		or reward <= 0
	then
		return false
	end
	if majorActive then
		return true
	end
	local corePresented = pulse(payload.rarityColor, 3.2, MANUAL_IN_SECONDS, MANUAL_OUT_SECONDS)
	local worldPresented = presentWorldResponse(payload.rarityColor)
	return corePresented or worldPresented
end

function EnergyPropagationPresenter.playMajor(color: Color3): boolean
	local configured = dependencies
	local ownedLight = light
	if configured == nil or ownedLight == nil or typeof(color) ~= "Color3" then
		return false
	end
	neutralizeWorld()
	majorActive = true
	if configured.getReducedMotion() then
		local result = pulse(color, 1, 0.08, 0.45)
		majorActive = true
		local currentGeneration = generation
		task.delay(0.55, function()
			if currentGeneration == generation then
				majorActive = false
			end
		end)
		return result
	end

	restoreCore()
	majorActive = true
	generation += 1
	local currentGeneration = generation
	ownedLight.Color = liftColor(color)
	tweenBrightness(currentGeneration, 2, MAJOR_GATHER_SECONDS, function()
		tweenBrightness(currentGeneration, 5, MAJOR_RELEASE_SECONDS, function()
			tweenBrightness(currentGeneration, 0, MAJOR_SETTLE_SECONDS, function()
				if currentGeneration == generation then
					majorActive = false
					restoreCore()
				end
			end)
		end)
	end)
	return true
end

function EnergyPropagationPresenter.cancel()
	majorActive = false
	restoreCore()
	neutralizeWorld()
end

function EnergyPropagationPresenter.destroy()
	if preferenceConnection ~= nil then
		preferenceConnection:Disconnect()
		preferenceConnection = nil
	end
	EnergyPropagationPresenter.cancel()
	destroyWorldInstances()
	if light ~= nil then
		light:Destroy()
		light = nil
	end
	dependencies = nil
end

return table.freeze(EnergyPropagationPresenter)
