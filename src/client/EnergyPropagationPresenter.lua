--!strict

export type PreferenceConnection = {
	read Disconnect: (self: PreferenceConnection) -> (),
}

export type Dependencies = {
	read tweenService: TweenService,
	read corePart: BasePart?,
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

local dependencies: Dependencies? = nil
local light: PointLight? = nil
local activeTween: Tween? = nil
local generation = 0
local preferenceConnection: PreferenceConnection? = nil

local function liftColor(color: Color3): Color3
	return color:Lerp(Color3.new(1, 1, 1), COLOR_LIFT)
end

local function cancelTween()
	if activeTween ~= nil then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function restore()
	generation += 1
	cancelTween()
	if light ~= nil then
		light.Brightness = 0
	end
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
	cancelTween()
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
	restore()
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
				restore()
			end
		end)
	end)
	return true
end

function EnergyPropagationPresenter.init(candidate: Dependencies)
	if not candidate.tweenService:IsA("TweenService")
		or (candidate.corePart ~= nil and not candidate.corePart:IsA("BasePart"))
		or type(candidate.getReducedMotion) ~= "function"
		or type(candidate.subscribeReducedMotion) ~= "function"
	then
		error("EnergyPropagationPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.tweenService == candidate.tweenService
			and dependencies.corePart == candidate.corePart
			and dependencies.getReducedMotion == candidate.getReducedMotion
			and dependencies.subscribeReducedMotion == candidate.subscribeReducedMotion
		then
			return
		end
		error("EnergyPropagationPresenter is already initialized with different dependencies", 2)
	end

	dependencies = table.freeze({
		tweenService = candidate.tweenService,
		corePart = candidate.corePart,
		getReducedMotion = candidate.getReducedMotion,
		subscribeReducedMotion = candidate.subscribeReducedMotion,
	})
	if candidate.corePart ~= nil then
		local presentationLight = Instance.new("PointLight")
		presentationLight.Name = "WorldAwakeningPresentationLight"
		presentationLight.Brightness = 0
		presentationLight.Range = LIGHT_RANGE
		presentationLight.Shadows = false
		presentationLight.Parent = candidate.corePart
		light = presentationLight
	end
	preferenceConnection = candidate.subscribeReducedMotion(function()
		restore()
	end)
end

function EnergyPropagationPresenter.playContact(): boolean
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
	return pulse(payload.rarityColor, 3.2, MANUAL_IN_SECONDS, MANUAL_OUT_SECONDS)
end

function EnergyPropagationPresenter.playMajor(color: Color3): boolean
	local configured = dependencies
	local ownedLight = light
	if configured == nil or ownedLight == nil or typeof(color) ~= "Color3" then
		return false
	end
	if configured.getReducedMotion() then
		return pulse(color, 1, 0.08, 0.45)
	end

	restore()
	generation += 1
	local currentGeneration = generation
	ownedLight.Color = liftColor(color)
	tweenBrightness(currentGeneration, 2, MAJOR_GATHER_SECONDS, function()
		tweenBrightness(currentGeneration, 5, MAJOR_RELEASE_SECONDS, function()
			tweenBrightness(currentGeneration, 0, MAJOR_SETTLE_SECONDS, function()
				if currentGeneration == generation then
					restore()
				end
			end)
		end)
	end)
	return true
end

function EnergyPropagationPresenter.cancel()
	restore()
end

function EnergyPropagationPresenter.destroy()
	if preferenceConnection ~= nil then
		preferenceConnection:Disconnect()
		preferenceConnection = nil
	end
	restore()
	if light ~= nil then
		light:Destroy()
		light = nil
	end
	dependencies = nil
end

return table.freeze(EnergyPropagationPresenter)
