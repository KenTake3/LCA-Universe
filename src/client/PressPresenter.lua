--!strict

export type Dependencies = {
	read button: TextButton,
	read popupParent: GuiObject | LayerCollector,
	read tweenService: TweenService,
	read formatNumber: (value: number) -> string,
	read playAudio: (cue: "PressContact" | "PressConfirmed") -> (),
	read getReducedMotion: () -> boolean,
}

local PressPresenter = {}

-- A 150ms fixed window groups adjacent confirmed presses at the approved input
-- rate while showing the first reward immediately and keeping feedback responsive.
local AGGREGATION_SECONDS = 0.15
local CONTACT_SECONDS = 0.1
local CONTACT_SCALE = 0.95
local POPUP_FADE_IN_SECONDS = 0.1
local POPUP_MOVE_SECONDS = 0.8
local POPUP_CLEANUP_MARGIN_SECONDS = 0.1

local dependencies: Dependencies? = nil
local originalButtonSize: UDim2? = nil
local contactGeneration = 0
local contactTween: Tween? = nil
local restoreTween: Tween? = nil
local popupGeneration = 0
local popup: TextLabel? = nil
local popupFadeInTween: Tween? = nil
local popupMoveTween: Tween? = nil
local sequenceOpen = false
local sequenceReward = 0

local function cancelTween(tween: Tween?)
	if tween ~= nil then
		tween:Cancel()
	end
end

local function cleanupPopup()
	popupGeneration += 1
	sequenceOpen = false
	sequenceReward = 0
	cancelTween(popupFadeInTween)
	cancelTween(popupMoveTween)
	popupFadeInTween = nil
	popupMoveTween = nil
	if popup ~= nil then
		popup:Destroy()
		popup = nil
	end
end

local function finitePositiveNumber(value: unknown): number?
	if type(value) ~= "number"
		or value ~= value
		or value == math.huge
		or value == -math.huge
		or value <= 0
	then
		return nil
	end
	return value
end

local function popupText(reward: number): string
	local configured = dependencies :: Dependencies
	return "+" .. configured.formatNumber(reward)
end

local function beginPopupMotion(generation: number)
	local activePopup = popup
	if generation ~= popupGeneration or activePopup == nil then
		return
	end
	sequenceOpen = false
	local configured = dependencies :: Dependencies
	cancelTween(popupFadeInTween)
	popupFadeInTween = nil
	local targetPosition = if configured.getReducedMotion() then activePopup.Position else UDim2.new(0.5, -200, 1, -260)
	local moveTween = configured.tweenService:Create(
		activePopup,
		TweenInfo.new(POPUP_MOVE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = targetPosition,
			TextTransparency = 1,
			BackgroundTransparency = 1,
		}
	)
	popupMoveTween = moveTween
	moveTween:Play()

	task.delay(POPUP_MOVE_SECONDS + POPUP_CLEANUP_MARGIN_SECONDS, function()
		if generation == popupGeneration then
			cleanupPopup()
		end
	end)
end

local function createPopup(reward: number, color: Color3)
	cleanupPopup()
	local configured = dependencies :: Dependencies
	sequenceReward = reward
	sequenceOpen = true
	popupGeneration += 1
	local generation = popupGeneration

	local createdPopup = Instance.new("TextLabel")
	createdPopup.Name = "PressRewardPopup"
	createdPopup.Text = popupText(sequenceReward)
	createdPopup.TextSize = 18
	createdPopup.Size = UDim2.new(0, 400, 0, 40)
	createdPopup.Position = UDim2.new(0.5, -200, 1, -180)
	createdPopup.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	createdPopup.BackgroundTransparency = 1
	createdPopup.TextColor3 = color
	createdPopup.Font = Enum.Font.GothamBlack
	createdPopup.TextXAlignment = Enum.TextXAlignment.Center
	createdPopup.TextYAlignment = Enum.TextYAlignment.Center
	createdPopup.TextTransparency = 0.5
	createdPopup.Parent = configured.popupParent
	popup = createdPopup

	local fadeInTween = configured.tweenService:Create(
		createdPopup,
		TweenInfo.new(POPUP_FADE_IN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	)
	popupFadeInTween = fadeInTween
	fadeInTween:Play()

	task.delay(AGGREGATION_SECONDS, function()
		beginPopupMotion(generation)
	end)
end

function PressPresenter.init(candidate: Dependencies)
	if not candidate.button:IsA("TextButton")
		or (not candidate.popupParent:IsA("GuiObject") and not candidate.popupParent:IsA("LayerCollector"))
		or not candidate.tweenService:IsA("TweenService")
		or type(candidate.formatNumber) ~= "function"
		or type(candidate.playAudio) ~= "function"
		or type(candidate.getReducedMotion) ~= "function"
	then
		error("PressPresenter.init received malformed dependencies", 2)
	end

	if dependencies ~= nil then
		if dependencies.button == candidate.button
			and dependencies.popupParent == candidate.popupParent
			and dependencies.tweenService == candidate.tweenService
			and dependencies.formatNumber == candidate.formatNumber
			and dependencies.playAudio == candidate.playAudio
			and dependencies.getReducedMotion == candidate.getReducedMotion
		then
			return
		end
		error("PressPresenter is already initialized with different dependencies", 2)
	end

	dependencies = table.freeze({
		button = candidate.button,
		popupParent = candidate.popupParent,
		tweenService = candidate.tweenService,
		formatNumber = candidate.formatNumber,
		playAudio = candidate.playAudio,
		getReducedMotion = candidate.getReducedMotion,
	})
	originalButtonSize = candidate.button.Size
end

function PressPresenter.playContact()
	local configured = dependencies
	local buttonSize = originalButtonSize
	if configured == nil or buttonSize == nil then
		return
	end

	contactGeneration += 1
	configured.playAudio("PressContact")
	local generation = contactGeneration
	local contactScale = if configured.getReducedMotion() then 0.98 else CONTACT_SCALE
	local compressedButtonSize = UDim2.new(
		buttonSize.X.Scale * contactScale,
		buttonSize.X.Offset * contactScale,
		buttonSize.Y.Scale * contactScale,
		buttonSize.Y.Offset * contactScale
	)
	cancelTween(contactTween)
	cancelTween(restoreTween)
	local compressionTween = configured.tweenService:Create(
		configured.button,
		TweenInfo.new(CONTACT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = compressedButtonSize }
	)
	contactTween = compressionTween
	compressionTween:Play()

	task.delay(CONTACT_SECONDS, function()
		if generation ~= contactGeneration or dependencies == nil then
			return
		end
		contactTween = nil
		local recoveryTween = configured.tweenService:Create(
			configured.button,
			TweenInfo.new(CONTACT_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = buttonSize }
		)
		restoreTween = recoveryTween
		recoveryTween:Play()
	end)
end

function PressPresenter.presentConfirmedReward(payload: unknown): boolean
	local configured = dependencies
	if configured == nil or type(payload) ~= "table" then
		return false
	end
	local reward = finitePositiveNumber(payload.reward)
	local color = payload.rarityColor
	if reward == nil or typeof(color) ~= "Color3" then
		return false
	end

	if sequenceOpen and popup ~= nil then
		sequenceReward += reward
		popup.Text = popupText(sequenceReward)
		configured.playAudio("PressConfirmed")
		return true
	end

	createPopup(reward, color)
	configured.playAudio("PressConfirmed")
	return true
end

function PressPresenter.destroy()
	contactGeneration += 1
	cancelTween(contactTween)
	cancelTween(restoreTween)
	contactTween = nil
	restoreTween = nil
	local buttonSize = originalButtonSize
	if dependencies ~= nil and buttonSize ~= nil then
		dependencies.button.Size = buttonSize
	end
	cleanupPopup()
	dependencies = nil
	originalButtonSize = nil
end

return table.freeze(PressPresenter)
