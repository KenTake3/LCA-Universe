--!strict

export type PreferenceConnection = {
	read Disconnect: (self: PreferenceConnection) -> (),
}

export type Dependencies = {
	read tweenService: TweenService,
	read corePart: BasePart?,
	read worldTarget: BasePart?,
	read stage2Route: { BasePart }?,
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
local STAGE2 = 2
local ROUTE_START_SECONDS = 0.25
local ROUTE_ARRIVAL_SECONDS = table.freeze({ 0.28, 0.48, 0.68, 0.88 })
local ROUTE_NEXT_SECONDS = table.freeze({ 0.3, 0.5, 0.7 })
local ROUTE_LIGHT_PEAK = 1.15
local DESTINATION_LIGHT_PEAK = 2.4
local DESTINATION_HOLD_SECONDS = 0.42
local MAJOR_WORLD_CLEANUP_SECONDS = 2.1

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

local routeAvailable = false
local routeStage: Instance? = nil
local routeFactoryRoot: Instance? = nil
local routeTargets: { BasePart } = {}
local routeAttachments: { Attachment } = {}
local routeLight: PointLight? = nil

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
	if routeLight ~= nil then
		routeLight.Brightness = 0
	end
end

local function destroyRouteInstances()
	neutralizeWorld()
	if routeLight ~= nil then
		routeLight:Destroy()
	end
	for _, attachment in routeAttachments do
		attachment:Destroy()
	end
	routeLight = nil
	routeAttachments = {}
	routeTargets = {}
	routeStage = nil
	routeFactoryRoot = nil
	routeAvailable = false
end

local function destroyManualWorldInstances()
	neutralizeWorld()
	if targetLight ~= nil then
		targetLight:Destroy()
	end
	if targetAttachment ~= nil then
		targetAttachment:Destroy()
	end
	targetLight = nil
	targetAttachment = nil
	worldTarget = nil
	approvedStage = nil
	approvedFactoryRoot = nil
	worldAvailable = false
end

local function destroySharedWorldInstances()
	neutralizeWorld()
	if transferBeam ~= nil then
		transferBeam:Destroy()
	end
	if coreAttachment ~= nil then
		coreAttachment:Destroy()
	end
	transferBeam = nil
	coreAttachment = nil
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
		destroyManualWorldInstances()
	end
	return false
end

local function routeIsValid(): boolean
	local configured = dependencies
	local stage = routeStage
	local factoryRoot = routeFactoryRoot
	if not routeAvailable
		or configured == nil
		or configured.corePart == nil
		or configured.corePart.Parent == nil
		or stage == nil
		or factoryRoot == nil
		or stage.Parent ~= factoryRoot
		or factoryRoot.Parent ~= workspace
		or coreAttachment == nil
		or coreAttachment.Parent ~= configured.corePart
		or transferBeam == nil
		or routeLight == nil
		or #routeTargets ~= 4
		or #routeAttachments ~= 4
	then
		return false
	end
	for index = 1, 4 do
		if routeTargets[index].Parent ~= stage or routeAttachments[index].Parent ~= routeTargets[index] then
			return false
		end
	end
	return true
end

local function validateRoute(): boolean
	if routeIsValid() then
		return true
	end
	if routeAvailable then
		destroyRouteInstances()
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
	ownedBeam.Attachment0 = coreAttachment
	ownedBeam.Attachment1 = targetAttachment
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

local function tweenRouteBrightness(currentWorldGeneration: number, brightness: number, duration: number)
	local configured = dependencies
	local ownedRouteLight = routeLight
	if configured == nil or ownedRouteLight == nil or currentWorldGeneration ~= worldGeneration then
		return
	end
	cancelTween(targetTween)
	local tween = configured.tweenService:Create(
		ownedRouteLight,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = brightness }
	)
	targetTween = tween
	tween:Play()
end

local function beginRouteSegment(currentWorldGeneration: number, index: number, displayColor: Color3)
	if currentWorldGeneration ~= worldGeneration or not validateRoute() then
		return
	end
	local ownedBeam = transferBeam :: Beam
	local source = if index == 1 then coreAttachment else routeAttachments[index - 1]
	local destination = routeAttachments[index]
	if source == nil or destination == nil then
		return
	end
	cancelTween(beamTween)
	ownedBeam.Attachment0 = source
	ownedBeam.Attachment1 = destination
	ownedBeam.Color = ColorSequence.new(displayColor)
	ownedBeam.Enabled = true
	ownedBeam.Transparency = NumberSequence.new(0.38)
	ownedBeam.Width0 = 0
	ownedBeam.Width1 = 0
	local segmentStart = if index == 1 then ROUTE_START_SECONDS else ROUTE_NEXT_SECONDS[index - 1]
	local duration = math.max(ROUTE_ARRIVAL_SECONDS[index] - segmentStart, 0.03)
	local tween = (dependencies :: Dependencies).tweenService:Create(
		ownedBeam,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Width0 = 0.14, Width1 = 0.07 }
	)
	beamTween = tween
	tween:Play()
end

local function arriveAtRouteTarget(currentWorldGeneration: number, index: number, displayColor: Color3)
	if currentWorldGeneration ~= worldGeneration or not validateRoute() then
		return
	end
	local ownedRouteLight = routeLight :: PointLight
	ownedRouteLight.Parent = routeTargets[index]
	ownedRouteLight.Color = displayColor
	ownedRouteLight.Brightness = 0
	if index == 4 then
		tweenRouteBrightness(currentWorldGeneration, DESTINATION_LIGHT_PEAK, 0.12)
		task.delay(DESTINATION_HOLD_SECONDS, function()
			if currentWorldGeneration == worldGeneration then
				tweenRouteBrightness(currentWorldGeneration, 0, 0.38)
			end
		end)
	else
		tweenRouteBrightness(currentWorldGeneration, ROUTE_LIGHT_PEAK, 0.06)
		task.delay(0.1, function()
			if currentWorldGeneration == worldGeneration then
				tweenRouteBrightness(currentWorldGeneration, 0, 0.08)
			end
		end)
	end
end

local function presentStage2Route(color: Color3): boolean
	local configured = dependencies
	if configured == nil or not validateRoute() then
		return false
	end
	neutralizeWorld()
	worldGeneration += 1
	local currentWorldGeneration = worldGeneration
	local displayColor = liftColor(color)

	if configured.getReducedMotion() then
		local ownedRouteLight = routeLight :: PointLight
		ownedRouteLight.Parent = routeTargets[4]
		ownedRouteLight.Color = displayColor
		tweenRouteBrightness(currentWorldGeneration, 0.8, 0.08)
		task.delay(0.18, function()
			if currentWorldGeneration == worldGeneration then
				tweenRouteBrightness(currentWorldGeneration, 0, 0.18)
			end
		end)
		task.delay(0.45, function()
			if currentWorldGeneration == worldGeneration then
				neutralizeWorld()
			end
		end)
		return true
	end

	task.delay(ROUTE_START_SECONDS, function()
		beginRouteSegment(currentWorldGeneration, 1, displayColor)
	end)
	for index, arrivalSeconds in ROUTE_ARRIVAL_SECONDS do
		task.delay(arrivalSeconds, function()
			arriveAtRouteTarget(currentWorldGeneration, index, displayColor)
		end)
		if index < 4 then
			task.delay(ROUTE_NEXT_SECONDS[index], function()
				beginRouteSegment(currentWorldGeneration, index + 1, displayColor)
			end)
		end
	end
	task.delay(1.3, function()
		if currentWorldGeneration == worldGeneration and transferBeam ~= nil then
			cancelTween(beamTween)
			local tween = configured.tweenService:Create(
				transferBeam,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Width0 = 0, Width1 = 0 }
			)
			beamTween = tween
			tween:Play()
		end
	end)
	task.delay(MAJOR_WORLD_CLEANUP_SECONDS, function()
		if currentWorldGeneration == worldGeneration then
			neutralizeWorld()
		end
	end)
	return true
end

function EnergyPropagationPresenter.init(candidate: Dependencies)
	local malformedRoute = candidate.stage2Route ~= nil and #candidate.stage2Route ~= 4
	if candidate.stage2Route ~= nil and not malformedRoute then
		for _, target in candidate.stage2Route do
			if not target:IsA("BasePart") then
				malformedRoute = true
				break
			end
		end
	end
	if not candidate.tweenService:IsA("TweenService")
		or (candidate.corePart ~= nil and not candidate.corePart:IsA("BasePart"))
		or (candidate.worldTarget ~= nil and not candidate.worldTarget:IsA("BasePart"))
		or malformedRoute
		or type(candidate.getReducedMotion) ~= "function"
		or type(candidate.subscribeReducedMotion) ~= "function"
	then
		error("EnergyPropagationPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.tweenService == candidate.tweenService
			and dependencies.corePart == candidate.corePart
			and dependencies.worldTarget == candidate.worldTarget
			and dependencies.stage2Route == candidate.stage2Route
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

	if candidate.corePart ~= nil and (candidate.worldTarget ~= nil or candidate.stage2Route ~= nil) then
		local sourceAttachment = Instance.new("Attachment")
		sourceAttachment.Name = "WP15CoreTransferAttachment"
		sourceAttachment.Parent = candidate.corePart
		coreAttachment = sourceAttachment

		local beam = Instance.new("Beam")
		beam.Name = "WP15CoreToBaseRingBeam"
		beam.Attachment0 = sourceAttachment
		beam.Enabled = false
		beam.FaceCamera = true
		beam.LightEmission = 0.7
		beam.LightInfluence = 0
		beam.Transparency = NumberSequence.new(1)
		beam.Width0 = 0
		beam.Width1 = 0
		beam.Parent = sourceAttachment
		transferBeam = beam
	end

	if candidate.corePart ~= nil and candidate.worldTarget ~= nil and coreAttachment ~= nil and transferBeam ~= nil then
		worldTarget = candidate.worldTarget
		approvedStage = candidate.worldTarget.Parent
		approvedFactoryRoot = if approvedStage ~= nil then approvedStage.Parent else nil

		local destinationAttachment = Instance.new("Attachment")
		destinationAttachment.Name = "WP15BaseRingResponseAttachment"
		destinationAttachment.Parent = candidate.worldTarget
		targetAttachment = destinationAttachment
		transferBeam.Attachment1 = destinationAttachment

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
			destroyManualWorldInstances()
		end
	end

	if candidate.corePart ~= nil and candidate.stage2Route ~= nil and coreAttachment ~= nil and transferBeam ~= nil then
		routeStage = candidate.stage2Route[1].Parent
		routeFactoryRoot = if routeStage ~= nil then routeStage.Parent else nil
		for index, target in candidate.stage2Route do
			routeTargets[index] = target
			local attachment = Instance.new("Attachment")
			attachment.Name = "WP15BStage2Connector" .. (index - 1) .. "Attachment"
			attachment.Parent = target
			routeAttachments[index] = attachment
		end
		local responseLight = Instance.new("PointLight")
		responseLight.Name = "WP15BStage2RouteLight"
		responseLight.Brightness = 0
		responseLight.Range = 12
		responseLight.Shadows = false
		responseLight.Parent = candidate.stage2Route[1]
		routeLight = responseLight
		routeAvailable = true
		if not routeIsValid() then
			destroyRouteInstances()
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

function EnergyPropagationPresenter.playMajor(color: Color3, destinationStage: number): boolean
	local configured = dependencies
	local ownedLight = light
	if configured == nil
		or ownedLight == nil
		or typeof(color) ~= "Color3"
		or type(destinationStage) ~= "number"
		or destinationStage ~= math.floor(destinationStage)
	then
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
		if destinationStage == STAGE2 then
			presentStage2Route(color)
		end
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
	if destinationStage == STAGE2 then
		presentStage2Route(color)
	end
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
	destroyRouteInstances()
	destroyManualWorldInstances()
	destroySharedWorldInstances()
	if light ~= nil then
		light:Destroy()
		light = nil
	end
	dependencies = nil
end

return table.freeze(EnergyPropagationPresenter)
