--!strict

export type Cue = "PressContact" | "PressConfirmed" | "UpgradeConfirmed" | "RebirthConfirmed" | "FactoryEra"

export type Dependencies = {
	read soundParent: Instance,
}

local AudioPresenter = {}

-- No reviewed SoundIds currently exist in the repository. Keep this allowlist
-- empty until an asset-review work package supplies approved IDs.
local SOUND_IDS: { [Cue]: string } = {
	PressContact = "",
	PressConfirmed = "",
	UpgradeConfirmed = "",
	RebirthConfirmed = "",
	FactoryEra = "",
}
local VOLUMES: { [Cue]: number } = {
	PressContact = 0.25,
	PressConfirmed = 0.3,
	UpgradeConfirmed = 0.4,
	RebirthConfirmed = 0.5,
	FactoryEra = 0.55,
}
local ROUTINE_CUES: { [Cue]: boolean } = {
	PressContact = true,
	PressConfirmed = true,
	UpgradeConfirmed = true,
	RebirthConfirmed = false,
	FactoryEra = false,
}

local dependencies: Dependencies? = nil
local routineSound: Sound? = nil
local majorSound: Sound? = nil
local MAX_CUE_LIFETIME_SECONDS = 10

local function stopAndDestroy(sound: Sound?)
	if sound ~= nil then
		sound:Stop()
		sound:Destroy()
	end
end

function AudioPresenter.init(candidate: Dependencies)
	if typeof(candidate.soundParent) ~= "Instance" then
		error("AudioPresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.soundParent == candidate.soundParent then
			return
		end
		error("AudioPresenter is already initialized with different dependencies", 2)
	end
	dependencies = table.freeze({ soundParent = candidate.soundParent })
end

function AudioPresenter.play(cue: Cue): boolean
	local configured = dependencies
	local soundId = SOUND_IDS[cue]
	local volume = VOLUMES[cue]
	if configured == nil or soundId == nil or soundId == "" or volume == nil then
		return false
	end

	local isRoutine = ROUTINE_CUES[cue]
	if not isRoutine then
		stopAndDestroy(routineSound)
		routineSound = nil
		stopAndDestroy(majorSound)
		majorSound = nil
	else
		stopAndDestroy(routineSound)
		routineSound = nil
	end

	local sound = Instance.new("Sound")
	sound.Name = "PresentationCue"
	sound.SoundId = soundId
	sound.Volume = math.clamp(volume, 0, 1)
	sound.Looped = false
	sound.Parent = configured.soundParent
	if isRoutine then
		routineSound = sound
	else
		majorSound = sound
	end
	sound:Play()
	task.delay(MAX_CUE_LIFETIME_SECONDS, function()
		if routineSound == sound then
			routineSound = nil
			stopAndDestroy(sound)
		elseif majorSound == sound then
			majorSound = nil
			stopAndDestroy(sound)
		end
	end)
	return true
end

function AudioPresenter.destroy()
	stopAndDestroy(routineSound)
	stopAndDestroy(majorSound)
	routineSound = nil
	majorSound = nil
	dependencies = nil
end

return table.freeze(AudioPresenter)
