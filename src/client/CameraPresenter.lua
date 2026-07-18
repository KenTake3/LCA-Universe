--!strict

export type Cue = "RebirthConfirmed" | "FactoryEra"

export type PreferenceConnection = {
	read Disconnect: (self: PreferenceConnection) -> (),
}

export type Dependencies = {
	read tweenService: TweenService,
	read getCurrentCamera: () -> Camera?,
	read getReducedMotion: () -> boolean,
	read subscribeReducedMotion: (listener: (reducedMotion: boolean) -> ()) -> PreferenceConnection,
}

local CameraPresenter = {}
local PULSE_IN_SECONDS = 0.12
local PULSE_OUT_SECONDS = 0.28
local MAX_FOV = 100

local dependencies: Dependencies? = nil
local generation = 0
local activeCamera: Camera? = nil
local originalFov: number? = nil
local activeTween: Tween? = nil
local preferenceConnection: PreferenceConnection? = nil

local function cancelTween()
	if activeTween ~= nil then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function restore()
	generation += 1
	cancelTween()
	local camera = activeCamera
	local fov = originalFov
	if camera ~= nil and fov ~= nil then
		camera.FieldOfView = fov
	end
	activeCamera = nil
	originalFov = nil
end

function CameraPresenter.init(candidate: Dependencies)
	if not candidate.tweenService:IsA("TweenService")
		or type(candidate.getCurrentCamera) ~= "function"
		or type(candidate.getReducedMotion) ~= "function"
		or type(candidate.subscribeReducedMotion) ~= "function"
	then
		error("CameraPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.tweenService == candidate.tweenService
			and dependencies.getCurrentCamera == candidate.getCurrentCamera
			and dependencies.getReducedMotion == candidate.getReducedMotion
			and dependencies.subscribeReducedMotion == candidate.subscribeReducedMotion
		then
			return
		end
		error("CameraPresenter is already initialized with different dependencies", 2)
	end
	dependencies = table.freeze({
		tweenService = candidate.tweenService,
		getCurrentCamera = candidate.getCurrentCamera,
		getReducedMotion = candidate.getReducedMotion,
		subscribeReducedMotion = candidate.subscribeReducedMotion,
	})
	preferenceConnection = candidate.subscribeReducedMotion(function(reducedMotion)
		if reducedMotion then
			restore()
		end
	end)
end

function CameraPresenter.play(cue: Cue): boolean
	local configured = dependencies
	if configured == nil or configured.getReducedMotion() then
		return false
	end
	local camera = configured.getCurrentCamera()
	if camera == nil then
		return false
	end

	restore()
	generation += 1
	local currentGeneration = generation
	activeCamera = camera
	originalFov = camera.FieldOfView
	local amplitude = if cue == "FactoryEra" then 5 else 3
	local pulseTween = configured.tweenService:Create(
		camera,
		TweenInfo.new(PULSE_IN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = math.min(camera.FieldOfView + amplitude, MAX_FOV) }
	)
	activeTween = pulseTween
	pulseTween:Play()

	task.delay(PULSE_IN_SECONDS, function()
		if currentGeneration ~= generation or activeCamera ~= camera or configured.getCurrentCamera() ~= camera then
			restore()
			return
		end
		cancelTween()
		local targetFov = originalFov
		if targetFov == nil then
			restore()
			return
		end
		local returnTween = configured.tweenService:Create(
			camera,
			TweenInfo.new(PULSE_OUT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FieldOfView = targetFov }
		)
		activeTween = returnTween
		returnTween:Play()
		task.delay(PULSE_OUT_SECONDS, function()
			if currentGeneration == generation then
				restore()
			end
		end)
	end)
	return true
end

function CameraPresenter.destroy()
	if preferenceConnection ~= nil then
		preferenceConnection:Disconnect()
		preferenceConnection = nil
	end
	restore()
	dependencies = nil
end

return table.freeze(CameraPresenter)
