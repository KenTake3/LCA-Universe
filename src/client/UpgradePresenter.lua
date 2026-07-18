--!strict

local PresentationCoordinator = require(script.Parent.PresentationCoordinator)

export type UpgradeId = "ClickPower" | "AutoPower" | "CoreAmplifier" | "Luck"

export type Card = {
	read button: GuiButton,
	read levelLabel: TextLabel,
}

export type Dependencies = {
	read getCard: (upgradeId: UpgradeId) -> Card?,
	read tweenService: TweenService,
	read playAudio: () -> (),
	read getReducedMotion: () -> boolean,
}

type Active = {
	generation: number,
	card: Card,
	buttonColor: Color3,
	labelColor: Color3,
	highlightTween: Tween?,
	highlightLabelTween: Tween?,
	restoreTween: Tween?,
	restoreLabelTween: Tween?,
}

local UpgradePresenter = {}
local HIGHLIGHT_SECONDS = 0.12
local RESTORE_SECONDS = 0.28
local HIGHLIGHT_COLOR = Color3.fromRGB(80, 200, 120)
local UPGRADE_IDS: { UpgradeId } = { "ClickPower", "AutoPower", "CoreAmplifier", "Luck" }

local dependencies: Dependencies? = nil
local connection: PresentationCoordinator.Connection? = nil
local activeById: { [UpgradeId]: Active } = {}

local function restore(upgradeId: UpgradeId)
	local active = activeById[upgradeId]
	if active == nil then
		return
	end
	active.generation += 1
	if active.highlightTween ~= nil then
		active.highlightTween:Cancel()
	end
	if active.restoreTween ~= nil then
		active.restoreTween:Cancel()
	end
	if active.highlightLabelTween ~= nil then
		active.highlightLabelTween:Cancel()
	end
	if active.restoreLabelTween ~= nil then
		active.restoreLabelTween:Cancel()
	end
	active.card.button.BackgroundColor3 = active.buttonColor
	active.card.levelLabel.TextColor3 = active.labelColor
	activeById[upgradeId] = nil
end

local function emphasize(upgradeId: UpgradeId)
	local configured = dependencies
	if configured == nil then
		return
	end
	restore(upgradeId)
	local card = configured.getCard(upgradeId)
	if card == nil or not card.button:IsA("GuiButton") or not card.levelLabel:IsA("TextLabel") then
		return
	end

	local active: Active = {
		generation = 1,
		card = card,
		buttonColor = card.button.BackgroundColor3,
		labelColor = card.levelLabel.TextColor3,
		highlightTween = nil,
		highlightLabelTween = nil,
		restoreTween = nil,
		restoreLabelTween = nil,
	}
	activeById[upgradeId] = active
	configured.playAudio()

	local highlightDuration = if configured.getReducedMotion() then 0.08 else HIGHLIGHT_SECONDS
	local highlightTween = configured.tweenService:Create(
		card.button,
		TweenInfo.new(highlightDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundColor3 = HIGHLIGHT_COLOR }
	)
	local labelTween = configured.tweenService:Create(
		card.levelLabel,
		TweenInfo.new(highlightDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextColor3 = Color3.fromRGB(255, 255, 255) }
	)
	active.highlightTween = highlightTween
	active.highlightLabelTween = labelTween
	highlightTween:Play()
	labelTween:Play()

	local generation = active.generation
	task.delay(highlightDuration, function()
		if activeById[upgradeId] ~= active or generation ~= active.generation then
			labelTween:Cancel()
			return
		end
		labelTween:Cancel()
		active.highlightTween = nil
		active.highlightLabelTween = nil
		local restoreTween = configured.tweenService:Create(
			card.button,
			TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = active.buttonColor }
		)
		local labelRestoreTween = configured.tweenService:Create(
			card.levelLabel,
			TweenInfo.new(RESTORE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TextColor3 = active.labelColor }
		)
		active.restoreTween = restoreTween
		active.restoreLabelTween = labelRestoreTween
		restoreTween:Play()
		labelRestoreTween:Play()
		task.delay(RESTORE_SECONDS, function()
			labelRestoreTween:Cancel()
			if activeById[upgradeId] == active and generation == active.generation then
				restore(upgradeId)
			end
		end)
	end)
end

local function onEvent(event: PresentationCoordinator.PresentationEvent)
	if event.name ~= "UpgradeLevelsChanged" then
		return
	end
	for _, change in event.changes do
		if change.level > change.previousLevel then
			emphasize(change.upgradeId)
		end
	end
end

function UpgradePresenter.init(candidate: Dependencies)
	if type(candidate.getCard) ~= "function"
		or not candidate.tweenService:IsA("TweenService")
		or type(candidate.playAudio) ~= "function"
		or type(candidate.getReducedMotion) ~= "function"
	then
		error("UpgradePresenter.init received malformed dependencies", 2)
	end
	if dependencies ~= nil then
		if dependencies.getCard == candidate.getCard
			and dependencies.tweenService == candidate.tweenService
			and dependencies.playAudio == candidate.playAudio
			and dependencies.getReducedMotion == candidate.getReducedMotion
		then
			return
		end
		error("UpgradePresenter is already initialized with different dependencies", 2)
	end
	dependencies = table.freeze({
		getCard = candidate.getCard,
		tweenService = candidate.tweenService,
		playAudio = candidate.playAudio,
		getReducedMotion = candidate.getReducedMotion,
	})
	connection = PresentationCoordinator.subscribe(onEvent)
end

function UpgradePresenter.destroy()
	if connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
	for _, upgradeId in UPGRADE_IDS do
		restore(upgradeId)
	end
	dependencies = nil
end

return table.freeze(UpgradePresenter)
