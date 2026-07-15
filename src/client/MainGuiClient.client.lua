--[[
	MainGuiClient (StarterGui > MainGui)
	Lucky Core Factory - Client UI Controller
	
	Builds the entire UI programmatically and handles:
	- Data display (Energy, Gems, Rebirths)
	- Upgrade purchases
	- Rebirth requests
	- Daily/Playtime reward claims
	- Shop (gamepass/dev products with 0=disabled)
	- Press button (mobile-friendly)
	- Notifications
	- Press feedback effects
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Require shared modules
local Config = require(ReplicatedStorage.LCA_Shared.Config)
local NumberFormatter = require(ReplicatedStorage.LCA_Shared.NumberFormatter)
local UpgradeDefinitions = require(ReplicatedStorage.LCA_Shared.UpgradeDefinitions)
local FactoryDefinitions = require(ReplicatedStorage.LCA_Shared.FactoryDefinitions)
local QuestDefinitions = require(ReplicatedStorage.LCA_Shared.QuestDefinitions)

-- ============================================================
-- Remotes
-- ============================================================
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local pressCoreEvent = remotes:WaitForChild("PressCore")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgrade")
local claimDailyEvent = remotes:WaitForChild("ClaimDailyReward")
local claimPlaytimeEvent = remotes:WaitForChild("ClaimPlaytimeReward")
local requestRebirthEvent = remotes:WaitForChild("RequestRebirth")
local dataSyncEvent = remotes:WaitForChild("DataSync")
local pressFeedbackEvent = remotes:WaitForChild("PressFeedback")
local rarityBroadcastEvent = remotes:WaitForChild("RarityBroadcast")
local factoryEvolutionSync = remotes:WaitForChild("FactoryEvolutionSync")
local questActionEvent = remotes:WaitForChild("QuestAction")
local questSyncEvent = remotes:WaitForChild("QuestSync")
local notificationEvent = remotes:FindFirstChild("Notification")

-- ============================================================
-- Color Theme
-- ============================================================
local COLORS = {
	bg = Color3.fromRGB(20, 22, 30),
	panel = Color3.fromRGB(30, 33, 45),
	accent = Color3.fromRGB(0, 170, 255),
	accentDim = Color3.fromRGB(0, 100, 160),
	good = Color3.fromRGB(80, 200, 120),
	warn = Color3.fromRGB(255, 180, 60),
	danger = Color3.fromRGB(255, 80, 80),
	text = Color3.fromRGB(240, 240, 250),
	textDim = Color3.fromRGB(160, 160, 180),
	purple = Color3.fromRGB(140, 80, 220),
	gold = Color3.fromRGB(255, 200, 50),
}

-- ============================================================
-- UI Container (script.Parent is MainGui ScreenGui)
-- ============================================================
local screenGui = script.Parent

-- ============================================================
-- Helper: Create UI elements with defaults
-- ============================================================
local function makeGui(className, props, parent)
	local el = Instance.new(className)
	for key, value in pairs(props or {}) do
		el[key] = value
	end
	el.Parent = parent or screenGui
	return el
end

local function makeText(parent, text, size, position, color, font)
	local label = makeGui("TextLabel", {
		Text = text or "",
		TextSize = size or 14,
		Position = position or UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		TextColor3 = color or COLORS.text,
		Font = font or Enum.Font.GothamBold,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
	return label
end

local function makeButton(parent, text, size, position, bgColor, textColor)
	local btn = makeGui("TextButton", {
		Text = text or "",
		TextSize = size or 14,
		Size = size and UDim2.new(0, 200, 0, 40) or UDim2.new(0, 200, 0, 50),
		Position = position or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = bgColor or COLORS.accent,
		TextColor3 = textColor or COLORS.text,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent)
	
	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	return btn
end

local function makePanel(name, size, position)
	local panel = makeGui("Frame", {
		Name = name,
		Size = size,
		Position = position,
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		Visible = false,
	})
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	return panel
end

-- ============================================================
-- Current Data Cache (client copy)
-- ============================================================
local clientData = {
	Energy = 0,
	LifetimeEnergy = 0,
	ClickPower = 1,
	AutoPower = 0,
	CoreAmplifier = 1,
	Luck = 0,
	Rebirths = 0,
	Gems = 0,
	UpgradeLevels = { ClickPower = 0, AutoPower = 0, CoreAmplifier = 0, Luck = 0 },
	DailyReward = { LastClaim = 0, Streak = 0 },
	PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 },
	PurchasedPerks = {},
	History = {},
	BestRarity = 0,
	BestRarityName = "None",
	FactoryStage = 1,
	HighestFactoryStage = 1,
	-- Quest/Achievement/Collection/DailyLogin data
	QuestData = { quests = {} },
	AchievementData = { unlocked = {}, claimed = {} },
	CollectionData = { cores = {}, auras = {}, titles = {}, factories = {} },
	DailyLoginData = { Day = 0, LastClaim = 0 },
	QuestStats = {},
}

-- ============================================================
-- Build TopBar
-- ============================================================
local topBar = makeGui("Frame", {
	Name = "TopBar",
	Size = UDim2.new(1, 0, 0, 60),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = COLORS.bg,
	BorderSizePixel = 0,
})

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 0)
topBarCorner.Parent = topBar

-- Energy display (center)
local energyLabel = makeText(topBar, "0", 24, UDim2.new(0.5, -100, 0, 10), COLORS.accent, Enum.Font.GothamBlack)
energyLabel.Size = UDim2.new(0, 200, 0, 30)
energyLabel.TextXAlignment = Enum.TextXAlignment.Center

local energySubtitle = makeText(topBar, "ENERGY", 11, UDim2.new(0.5, -100, 0, 38), COLORS.textDim, Enum.Font.Gotham)
energySubtitle.Size = UDim2.new(0, 200, 0, 18)

-- Game title below TopBar
local titleLabel = makeGui("TextLabel", {
	Name = "GameTitle",
	Text = "LUCKY CORE FACTORY",
	TextSize = 14,
	Size = UDim2.new(0, 250, 0, 22),
	Position = UDim2.new(0.5, -125, 0, 62),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.3,
	TextColor3 = COLORS.gold,
	Font = Enum.Font.GothamBlack,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
})
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleLabel

-- Factory Evolution stage label (below title)
local factoryStageLabel = makeGui("TextLabel", {
	Name = "FactoryStageLabel",
	Text = "Stage 1: Core Online",
	TextSize = 12,
	Size = UDim2.new(0, 200, 0, 18),
	Position = UDim2.new(0.5, -100, 0, 86),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.3,
	TextColor3 = COLORS.accent,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
})
local fslCorner = Instance.new("UICorner")
fslCorner.CornerRadius = UDim.new(0, 6)
fslCorner.Parent = factoryStageLabel

-- Gems display (right)
local gemsLabel = makeText(topBar, "Gems: 0", 16, UDim2.new(1, -150, 0, 18), COLORS.gold, Enum.Font.GothamBold)
gemsLabel.Size = UDim2.new(0, 140, 0, 24)
gemsLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Rebirths display (left)
local rebirthsLabel = makeText(topBar, "Rebirths: 0", 16, UDim2.new(0, 10, 0, 18), COLORS.purple, Enum.Font.GothamBold)
rebirthsLabel.Size = UDim2.new(0, 140, 0, 24)
rebirthsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Luck display (left, below rebirths)
local luckLabel = makeText(topBar, "Luck: 0", 14, UDim2.new(0, 10, 0, 40), Color3.fromRGB(255, 100, 200), Enum.Font.GothamBold)
luckLabel.Size = UDim2.new(0, 140, 0, 18)
luckLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Core Amplifier display (right, below gems)
local coreAmpLabel = makeText(topBar, "Amp: x1.0", 14, UDim2.new(1, -150, 0, 40), Color3.fromRGB(255, 150, 0), Enum.Font.GothamBold)
coreAmpLabel.Size = UDim2.new(0, 140, 0, 18)
coreAmpLabel.TextXAlignment = Enum.TextXAlignment.Right

-- ============================================================
-- Build Press Button (bottom center)
-- ============================================================
local pressButton = makeGui("TextButton", {
	Name = "PressButton",
	Size = UDim2.new(0, 120, 0, 120),
	Position = UDim2.new(0.5, -60, 1, -160),
	BackgroundColor3 = COLORS.accent,
	TextColor3 = COLORS.text,
	Text = "PRESS",
	TextSize = 20,
	Font = Enum.Font.GothamBlack,
	AutoButtonColor = true,
})

local pressCorner = Instance.new("UICorner")
pressCorner.CornerRadius = UDim.new(1, 0) -- fully round
pressCorner.Parent = pressButton

-- Press button glow ring
local pressRing = makeGui("Frame", {
	Name = "Ring",
	Size = UDim2.new(1, 10, 1, 10),
	Position = UDim2.new(0, -5, 0, -5),
	BackgroundColor3 = COLORS.accent,
	BackgroundTransparency = 0.8,
	ZIndex = 0,
}, pressButton)
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = pressRing

-- ============================================================
-- Build Navigation Buttons (bottom-left)
-- ============================================================
local navContainer = makeGui("Frame", {
	Name = "NavButtons",
	Size = UDim2.new(0, 50, 0, 580),
	Position = UDim2.new(0, 10, 1, -590),
	BackgroundTransparency = 1,
	LayoutOrder = 0,
})

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 8)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navContainer

local function makeNavButton(name, text, order, icon)
	local btn = makeGui("TextButton", {
		Name = name,
		Size = UDim2.new(0, 50, 0, 50),
		BackgroundColor3 = COLORS.panel,
		TextColor3 = COLORS.text,
		Text = text,
		TextSize = 10,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
		LayoutOrder = order,
	}, navContainer)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	return btn
end

local upgradeBtn = makeNavButton("UpgradeNav", "UPG", 1)
local rebirthNavBtn = makeNavButton("RebirthNav", "REB", 2)
local shopNavBtn = makeNavButton("ShopNav", "SHOP", 3)
local dailyNavBtn = makeNavButton("DailyNav", "DAILY", 4)
local playtimeNavBtn = makeNavButton("PlaytimeNav", "TIME", 5)
local historyNavBtn = makeNavButton("HistoryNav", "HIST", 6)
local questNavBtn = makeNavButton("QuestNav", "QUEST", 7)
local achNavBtn = makeNavButton("AchNav", "ACHV", 8)
local collNavBtn = makeNavButton("CollNav", "COLL", 9)
local loginNavBtn = makeNavButton("LoginNav", "LOGIN", 10)

-- ============================================================
-- Build Upgrade Panel
-- ============================================================
local upgradePanel = makePanel("UpgradePanel", UDim2.new(0, 320, 0, 420), UDim2.new(0.5, -160, 0.5, -210))

local upgradeTitle = makeText(upgradePanel, "UPGRADES", 20, UDim2.new(0, 0, 0, 10), COLORS.text, Enum.Font.GothamBlack)

local upgradeClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, upgradePanel)
local ucCorner = Instance.new("UICorner")
ucCorner.CornerRadius = UDim.new(0, 6)
ucCorner.Parent = upgradeClose

local upgradeList = makeGui("Frame", {
	Name = "List",
	Size = UDim2.new(1, -20, 1, -60),
	Position = UDim2.new(0, 10, 0, 50),
	BackgroundTransparency = 1,
}, upgradePanel)

local upgradeListLayout = Instance.new("UIListLayout")
upgradeListLayout.Padding = UDim.new(0, 8)
upgradeListLayout.Parent = upgradeList

-- Create upgrade entry for each upgrade
local upgradeButtons = {}
for i, upgrade in ipairs(Config.Upgrades) do
	local entry = makeGui("TextButton", {
		Name = upgrade.id,
		Size = UDim2.new(1, 0, 0, 75),
		BackgroundColor3 = COLORS.bg,
		Text = "",
		AutoButtonColor = true,
		LayoutOrder = i,
	}, upgradeList)
	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry
	
	-- Color stripe
	local stripe = makeGui("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		BackgroundColor3 = upgrade.iconColor,
		BorderSizePixel = 0,
	}, entry)
	local stripeCorner = Instance.new("UICorner")
	stripeCorner.CornerRadius = UDim.new(0, 2)
	stripeCorner.Parent = stripe
	
	-- Name and description
	local nameLabel = makeText(entry, upgrade.displayName, 14, UDim2.new(0, 12, 0, 5), COLORS.text, Enum.Font.GothamBold)
	nameLabel.Size = UDim2.new(1, -100, 0, 20)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	local descLabel = makeText(entry, upgrade.description, 11, UDim2.new(0, 12, 0, 22), COLORS.textDim, Enum.Font.Gotham)
	descLabel.Size = UDim2.new(1, -100, 0, 16)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Level and cost on the right
	local levelLabel = makeText(entry, "Lv. 0", 12, UDim2.new(1, -90, 0, 5), COLORS.textDim, Enum.Font.GothamBold)
	levelLabel.Size = UDim2.new(0, 80, 0, 20)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right
	
	local costLabel = makeText(entry, "Cost: 0", 12, UDim2.new(1, -90, 0, 38), COLORS.gold, Enum.Font.GothamBold)
	costLabel.Size = UDim2.new(0, 80, 0, 20)
	costLabel.TextXAlignment = Enum.TextXAlignment.Right
	
	upgradeButtons[upgrade.id] = {
		button = entry,
		levelLabel = levelLabel,
		costLabel = costLabel,
		nameLabel = nameLabel,
	}
end

-- ============================================================
-- Build Rebirth Panel
-- ============================================================
local rebirthPanel = makePanel("RebirthPanel", UDim2.new(0, 280, 0, 280), UDim2.new(0.5, -140, 0.5, -140))

local rebirthTitle = makeText(rebirthPanel, "REBIRTH", 20, UDim2.new(0, 0, 0, 10), COLORS.purple, Enum.Font.GothamBlack)

local rebirthClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, rebirthPanel)
local rcCorner = Instance.new("UICorner")
rcCorner.CornerRadius = UDim.new(0, 6)
rcCorner.Parent = rebirthClose

local rebirthInfo = makeText(rebirthPanel, "Rebirth to reset upgrades and get permanent multipliers!", 12, UDim2.new(0, 15, 0, 45), COLORS.textDim, Enum.Font.Gotham)
rebirthInfo.Size = UDim2.new(1, -30, 0, 40)
rebirthInfo.TextWrapped = true

local rebirthCostLabel = makeText(rebirthPanel, "Cost: 0", 16, UDim2.new(0, 0, 0, 100), COLORS.gold, Enum.Font.GothamBold)
rebirthCostLabel.Size = UDim2.new(1, 0, 0, 25)

local rebirthMultLabel = makeText(rebirthPanel, "Multiplier: x1.0", 16, UDim2.new(0, 0, 0, 130), COLORS.good, Enum.Font.GothamBold)
rebirthMultLabel.Size = UDim2.new(1, 0, 0, 25)

local rebirthConfirmBtn = makeButton(rebirthPanel, "REBIRTH", 16, UDim2.new(0.5, -80, 1, -55), COLORS.purple, COLORS.text)
rebirthConfirmBtn.Size = UDim2.new(0, 160, 0, 40)

-- ============================================================
-- Build Shop Panel
-- ============================================================
local shopPanel = makePanel("ShopPanel", UDim2.new(0, 320, 0, 420), UDim2.new(0.5, -160, 0.5, -210))

local shopTitle = makeText(shopPanel, "SHOP", 20, UDim2.new(0, 0, 0, 10), COLORS.gold, Enum.Font.GothamBlack)

local shopClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, shopPanel)
local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 6)
scCorner.Parent = shopClose

local shopList = makeGui("Frame", {
	Name = "List",
	Size = UDim2.new(1, -20, 1, -60),
	Position = UDim2.new(0, 10, 0, 50),
	BackgroundTransparency = 1,
}, shopPanel)

local shopListLayout = Instance.new("UIListLayout")
shopListLayout.Padding = UDim.new(0, 8)
shopListLayout.Parent = shopList

-- Create shop entries for gamepasses
local shopButtons = {}
for perkId, passInfo in pairs(Config.GamePasses) do
	local entry = makeGui("Frame", {
		Name = perkId,
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = COLORS.bg,
	}, shopList)
	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry
	
	local nameLabel = makeText(entry, passInfo.name, 14, UDim2.new(0, 10, 0, 5), COLORS.text, Enum.Font.GothamBold)
	nameLabel.Size = UDim2.new(1, -20, 0, 20)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	local descLabel = makeText(entry, passInfo.description, 11, UDim2.new(0, 10, 0, 25), COLORS.textDim, Enum.Font.Gotham)
	descLabel.Size = UDim2.new(1, -20, 0, 20)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	local buyBtn = makeGui("TextButton", {
		Text = passInfo.id == 0 and "SOON" or "BUY",
		TextSize = 12,
		Size = UDim2.new(0, 70, 0, 30),
		Position = UDim2.new(1, -80, 1, -35),
		BackgroundColor3 = passInfo.id == 0 and COLORS.textDim or COLORS.gold,
		TextColor3 = COLORS.text,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = passInfo.id ~= 0,
	}, entry)
	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyBtn
	
	-- Disable button if ID is 0 (placeholder)
	if passInfo.id == 0 then
		buyBtn.Active = false
		buyBtn.BackgroundTransparency = 0.5
	end
	
	shopButtons[perkId] = { button = buyBtn, passInfo = passInfo, entry = entry }
end

-- ============================================================
-- Build Daily Reward Panel
-- ============================================================
local dailyPanel = makePanel("DailyRewardPanel", UDim2.new(0, 280, 0, 320), UDim2.new(0.5, -140, 0.5, -160))

local dailyTitle = makeText(dailyPanel, "DAILY REWARD", 18, UDim2.new(0, 0, 0, 10), COLORS.good, Enum.Font.GothamBlack)

local dailyClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, dailyPanel)
local dcCorner = Instance.new("UICorner")
dcCorner.CornerRadius = UDim.new(0, 6)
dcCorner.Parent = dailyClose

local dailyStreakLabel = makeText(dailyPanel, "Streak: Day 1", 16, UDim2.new(0, 0, 0, 50), COLORS.gold, Enum.Font.GothamBold)
dailyStreakLabel.Size = UDim2.new(1, 0, 0, 25)

local dailyTimerLabel = makeText(dailyPanel, "Ready to claim!", 14, UDim2.new(0, 0, 0, 80), COLORS.textDim, Enum.Font.Gotham)
dailyTimerLabel.Size = UDim2.new(1, 0, 0, 25)

-- Daily reward preview grid
local dailyGrid = makeGui("Frame", {
	Name = "Grid",
	Size = UDim2.new(1, -20, 0, 120),
	Position = UDim2.new(0, 10, 0, 110),
	BackgroundTransparency = 1,
}, dailyPanel)

local dailyGridLayout = Instance.new("UIGridLayout")
dailyGridLayout.CellSize = UDim2.new(0, 70, 0, 50)
dailyGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
dailyGridLayout.Parent = dailyGrid

for i = 1, 7 do
	local dayCell = makeGui("Frame", {
		Name = "Day" .. i,
		BackgroundColor3 = COLORS.bg,
	}, dailyGrid)
	local dc2 = Instance.new("UICorner")
	dc2.CornerRadius = UDim.new(0, 6)
	dc2.Parent = dayCell
	
	local dayLabel = makeText(dayCell, "Day " .. i, 10, UDim2.new(0, 0, 0, 2), COLORS.textDim, Enum.Font.Gotham)
	dayLabel.Size = UDim2.new(1, 0, 0, 14)
	
	local rewardLabel = makeText(dayCell, (Config.DailyReward.Gems[i] or 0) .. " gems", 10, UDim2.new(0, 0, 0, 18), COLORS.gold, Enum.Font.GothamBold)
	rewardLabel.Size = UDim2.new(1, 0, 0, 28)
end

local dailyClaimBtn = makeButton(dailyPanel, "CLAIM", 16, UDim2.new(0.5, -80, 1, -55), COLORS.good, COLORS.text)
dailyClaimBtn.Size = UDim2.new(0, 160, 0, 40)

-- ============================================================
-- Build Playtime Reward Panel
-- ============================================================
local playtimePanel = makePanel("PlaytimeRewardPanel", UDim2.new(0, 280, 0, 320), UDim2.new(0.5, -140, 0.5, -160))

local playtimeTitle = makeText(playtimePanel, "PLAYTIME REWARDS", 16, UDim2.new(0, 0, 0, 10), COLORS.accent, Enum.Font.GothamBlack)

local playtimeClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, playtimePanel)
local pcCorner = Instance.new("UICorner")
pcCorner.CornerRadius = UDim.new(0, 6)
pcCorner.Parent = playtimeClose

local playtimeProgressLabel = makeText(playtimePanel, "Progress", 14, UDim2.new(0, 0, 0, 50), COLORS.textDim, Enum.Font.Gotham)
playtimeProgressLabel.Size = UDim2.new(1, 0, 0, 25)

local playtimeList = makeGui("Frame", {
	Name = "List",
	Size = UDim2.new(1, -20, 0, 160),
	Position = UDim2.new(0, 10, 0, 80),
	BackgroundTransparency = 1,
}, playtimePanel)

local playtimeListLayout = Instance.new("UIListLayout")
playtimeListLayout.Padding = UDim.new(0, 6)
playtimeListLayout.Parent = playtimeList

for i, interval in ipairs(Config.PlaytimeReward.Intervals) do
	local entry = makeGui("Frame", {
		Name = "Reward" .. i,
		Size = UDim2.new(1, 0, 0, 45),
		BackgroundColor3 = COLORS.bg,
	}, playtimeList)
	local ec = Instance.new("UICorner")
	ec.CornerRadius = UDim.new(0, 6)
	ec.Parent = entry
	
	local descLabel = makeText(entry, NumberFormatter.formatTime(interval) .. " - " .. (Config.PlaytimeReward.Gems[i] or 0) .. " gems", 12, UDim2.new(0, 10, 0, 0), COLORS.text, Enum.Font.GothamBold)
	descLabel.Size = UDim2.new(1, -20, 1, 0)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
end

local playtimeClaimBtn = makeButton(playtimePanel, "CLAIM", 16, UDim2.new(0.5, -80, 1, -55), COLORS.accent, COLORS.text)
playtimeClaimBtn.Size = UDim2.new(0, 160, 0, 40)

-- ============================================================
-- Build History Panel
-- ============================================================
local historyPanel = makePanel("HistoryPanel", UDim2.new(0, 320, 0, 420), UDim2.new(0.5, -160, 0.5, -210))

local historyTitle = makeText(historyPanel, "LUCK HISTORY", 20, UDim2.new(0, 0, 0, 10), COLORS.gold, Enum.Font.GothamBlack)

local historyClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, historyPanel)
local hcCorner = Instance.new("UICorner")
hcCorner.CornerRadius = UDim.new(0, 6)
hcCorner.Parent = historyClose

-- Best Rarity record display
local bestRarityLabel = makeText(historyPanel, "Best: None yet", 16, UDim2.new(0, 10, 0, 45), COLORS.textDim, Enum.Font.GothamBold)
bestRarityLabel.Size = UDim2.new(1, -20, 0, 25)
bestRarityLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Rarity tier reference (all 8 tiers)
local tierList = makeGui("Frame", {
	Name = "TierList",
	Size = UDim2.new(1, -20, 0, 130),
	Position = UDim2.new(0, 10, 0, 75),
	BackgroundTransparency = 1,
}, historyPanel)

local tierListLayout = Instance.new("UIListLayout")
tierListLayout.Padding = UDim.new(0, 2)
tierListLayout.Parent = tierList

for i, rarity in ipairs(Config.LuckRarities) do
	local tierEntry = makeGui("Frame", {
		Name = rarity.name,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
	}, tierList)
	
	local tierNameLabel = makeText(tierEntry, rarity.name, 11, UDim2.new(0, 0, 0, 0), rarity.color, Enum.Font.GothamBold)
	tierNameLabel.Size = UDim2.new(0, 90, 1, 0)
	tierNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	local tierMultLabel = makeText(tierEntry, "x" .. NumberFormatter.format(rarity.multiplier), 11, UDim2.new(0, 90, 0, 0), COLORS.textDim, Enum.Font.Gotham)
	tierMultLabel.Size = UDim2.new(0, 80, 1, 0)
	tierMultLabel.TextXAlignment = Enum.TextXAlignment.Left
end

-- History entries (scrolling frame)
local historyScroll = makeGui("ScrollingFrame", {
	Name = "HistoryScroll",
	Size = UDim2.new(1, -20, 1, -220),
	Position = UDim2.new(0, 10, 0, 215),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, historyPanel)

local historyScrollLayout = Instance.new("UIListLayout")
historyScrollLayout.Padding = UDim.new(0, 4)
historyScrollLayout.Parent = historyScroll

-- ============================================================
-- Build Quest Panel
-- ============================================================
local questPanel = makePanel("QuestPanel", UDim2.new(0, 340, 0, 420), UDim2.new(0.5, -170, 0.5, -210))

local questTitle = makeText(questPanel, "DAILY QUESTS", 18, UDim2.new(0, 0, 0, 10), COLORS.accent, Enum.Font.GothamBlack)

local questClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, questPanel)
local qCloseCorner = Instance.new("UICorner")
qCloseCorner.CornerRadius = UDim.new(0, 6)
qCloseCorner.Parent = questClose

local questScroll = makeGui("ScrollingFrame", {
	Name = "QuestList",
	Size = UDim2.new(1, -20, 1, -60),
	Position = UDim2.new(0, 10, 0, 50),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, questPanel)
local questScrollLayout = Instance.new("UIListLayout")
questScrollLayout.Padding = UDim.new(0, 8)
questScrollLayout.Parent = questScroll

-- ============================================================
-- Build Achievement Panel
-- ============================================================
local achievementPanel = makePanel("AchievementPanel", UDim2.new(0, 360, 0, 450), UDim2.new(0.5, -180, 0.5, -225))

local achTitle = makeText(achievementPanel, "ACHIEVEMENTS", 18, UDim2.new(0, 0, 0, 10), COLORS.gold, Enum.Font.GothamBlack)

local achClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, achievementPanel)
local aCloseCorner = Instance.new("UICorner")
aCloseCorner.CornerRadius = UDim.new(0, 6)
aCloseCorner.Parent = achClose

-- Category tabs
local achTabsContainer = makeGui("Frame", {
	Name = "Tabs",
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.new(0, 10, 0, 45),
	BackgroundTransparency = 1,
}, achievementPanel)
local achTabsLayout = Instance.new("UIListLayout")
achTabsLayout.FillDirection = Enum.FillDirection.Horizontal
achTabsLayout.Padding = UDim.new(0, 4)
achTabsLayout.Parent = achTabsContainer

local achCategoryButtons = {}
local selectedAchCategory = "Press"

for _, cat in ipairs(QuestDefinitions.AchievementCategories) do
	local tabBtn = makeGui("TextButton", {
		Name = cat.id,
		Text = cat.name,
		TextSize = 10,
		Size = UDim2.new(0, 52, 0, 28),
		BackgroundColor3 = COLORS.bg,
		TextColor3 = cat.color,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
	}, achTabsContainer)
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tabBtn

	tabBtn.MouseButton1Click:Connect(function()
		selectedAchCategory = cat.id
	end)

	achCategoryButtons[cat.id] = tabBtn
end

local achScroll = makeGui("ScrollingFrame", {
	Name = "AchList",
	Size = UDim2.new(1, -20, 1, -95),
	Position = UDim2.new(0, 10, 0, 85),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, achievementPanel)
local achScrollLayout = Instance.new("UIListLayout")
achScrollLayout.Padding = UDim.new(0, 6)
achScrollLayout.Parent = achScroll

-- ============================================================
-- Build Collection Panel
-- ============================================================
local collectionPanel = makePanel("CollectionPanel", UDim2.new(0, 360, 0, 450), UDim2.new(0.5, -180, 0.5, -225))

local collTitle = makeText(collectionPanel, "COLLECTION", 18, UDim2.new(0, 0, 0, 10), Color3.fromRGB(0, 200, 120), Enum.Font.GothamBlack)

local collClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, collectionPanel)
local cCloseCorner = Instance.new("UICorner")
cCloseCorner.CornerRadius = UDim.new(0, 6)
cCloseCorner.Parent = collClose

-- Collection tabs
local collTabsContainer = makeGui("Frame", {
	Name = "Tabs",
	Size = UDim2.new(1, -20, 0, 30),
	Position = UDim2.new(0, 10, 0, 45),
	BackgroundTransparency = 1,
}, collectionPanel)
local collTabsLayout = Instance.new("UIListLayout")
collTabsLayout.FillDirection = Enum.FillDirection.Horizontal
collTabsLayout.Padding = UDim.new(0, 4)
collTabsLayout.Parent = collTabsContainer

local collCategoryButtons = {}
local selectedCollCategory = "Core"
local collCategories = {
	{ id = "Core", name = "CORE" },
	{ id = "Aura", name = "AURA" },
	{ id = "Title", name = "TITLE" },
	{ id = "Factory", name = "FACT" },
}

for _, cat in ipairs(collCategories) do
	local tabBtn = makeGui("TextButton", {
		Name = cat.id,
		Text = cat.name,
		TextSize = 10,
		Size = UDim2.new(0, 78, 0, 28),
		BackgroundColor3 = COLORS.bg,
		TextColor3 = COLORS.text,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = true,
	}, collTabsContainer)
	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tabBtn

	tabBtn.MouseButton1Click:Connect(function()
		selectedCollCategory = cat.id
	end)

	collCategoryButtons[cat.id] = tabBtn
end

local collScroll = makeGui("ScrollingFrame", {
	Name = "CollList",
	Size = UDim2.new(1, -20, 1, -95),
	Position = UDim2.new(0, 10, 0, 85),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, collectionPanel)
local collScrollLayout = Instance.new("UIListLayout")
collScrollLayout.Padding = UDim.new(0, 6)
collScrollLayout.Parent = collScroll

-- ============================================================
-- Build DailyLogin Panel
-- ============================================================
local dailyLoginPanel = makePanel("DailyLoginPanel", UDim2.new(0, 340, 0, 400), UDim2.new(0.5, -170, 0.5, -200))

local dlTitle = makeText(dailyLoginPanel, "DAILY LOGIN REWARDS", 16, UDim2.new(0, 0, 0, 10), COLORS.gold, Enum.Font.GothamBlack)

local dlClose = makeGui("TextButton", {
	Text = "X",
	TextSize = 16,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -35, 0, 5),
	BackgroundColor3 = COLORS.danger,
	TextColor3 = COLORS.text,
	Font = Enum.Font.GothamBold,
}, dailyLoginPanel)
local dlCloseCorner = Instance.new("UICorner")
dlCloseCorner.CornerRadius = UDim.new(0, 6)
dlCloseCorner.Parent = dlClose

local dlStreakLabel = makeText(dailyLoginPanel, "Day 0 / 30", 14, UDim2.new(0, 0, 0, 45), COLORS.textDim, Enum.Font.GothamBold)
dlStreakLabel.Size = UDim2.new(1, 0, 0, 25)

local dlTimerLabel = makeText(dailyLoginPanel, "Ready to claim!", 12, UDim2.new(0, 0, 0, 70), COLORS.good, Enum.Font.Gotham)
dlTimerLabel.Size = UDim2.new(1, 0, 0, 20)

-- 30-day reward grid
local dlGrid = makeGui("Frame", {
	Name = "Grid",
	Size = UDim2.new(1, -20, 0, 200),
	Position = UDim2.new(0, 10, 0, 95),
	BackgroundTransparency = 1,
}, dailyLoginPanel)
local dlGridLayout = Instance.new("UIGridLayout")
dlGridLayout.CellSize = UDim2.new(0, 50, 0, 38)
dlGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
dlGridLayout.Parent = dlGrid

for i = 1, 30 do
	local dayCell = makeGui("Frame", {
		Name = "Day" .. i,
		BackgroundColor3 = COLORS.bg,
	}, dlGrid)
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 4)
	dc.Parent = dayCell

	local dayLabel = makeText(dayCell, tostring(i), 9, UDim2.new(0, 0, 0, 0), COLORS.textDim, Enum.Font.Gotham)
	dayLabel.Size = UDim2.new(1, 0, 0, 12)

	local rewardLabel = makeText(dayCell, "?", 8, UDim2.new(0, 0, 0, 12), COLORS.gold, Enum.Font.GothamBold)
	rewardLabel.Size = UDim2.new(1, 0, 0, 24)
end

local dlClaimBtn = makeButton(dailyLoginPanel, "CLAIM", 16, UDim2.new(0.5, -80, 1, -50), COLORS.good, COLORS.text)
dlClaimBtn.Size = UDim2.new(0, 160, 0, 36)

-- ============================================================
-- Build Mission Tracker (always-visible overlay)
-- ============================================================
local missionTracker = makeGui("Frame", {
	Name = "MissionTracker",
	Size = UDim2.new(0, 220, 0, 120),
	Position = UDim2.new(1, -230, 0, 65),
	BackgroundColor3 = COLORS.panel,
	BackgroundTransparency = 0.1,
	Visible = true,
})
local mtCorner = Instance.new("UICorner")
mtCorner.CornerRadius = UDim.new(0, 8)
mtCorner.Parent = missionTracker

local mtTitle = makeText(missionTracker, "MISSIONS", 12, UDim2.new(0, 0, 0, 3), COLORS.textDim, Enum.Font.GothamBold)
mtTitle.Size = UDim2.new(1, 0, 0, 16)

local mtList = makeGui("Frame", {
	Name = "List",
	Size = UDim2.new(1, -10, 1, -22),
	Position = UDim2.new(0, 5, 0, 20),
	BackgroundTransparency = 1,
}, missionTracker)
local mtLayout = Instance.new("UIListLayout")
mtLayout.Padding = UDim.new(0, 2)
mtLayout.Parent = mtList

-- ============================================================
-- Build Notification Container
-- ============================================================
local notifContainer = makeGui("Frame", {
	Name = "NotificationContainer",
	Size = UDim2.new(0, 300, 0, 200),
	Position = UDim2.new(0.5, -150, 0, 70),
	BackgroundTransparency = 1,
})

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 5)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Parent = notifContainer

-- ============================================================
-- Notification System
-- ============================================================

local notifOrder = 0
local function showNotification(text, color)
	notifOrder = notifOrder + 1
	local notif = makeGui("TextLabel", {
		Text = text,
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundColor3 = color or COLORS.panel,
		TextColor3 = COLORS.text,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = notifOrder,
	}, notifContainer)
	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = notif
	
	-- Fade in then out
	notif.BackgroundTransparency = 1
	notif.TextTransparency = 1
	
	TweenService:Create(notif, TweenInfo.new(0.2), { BackgroundTransparency = 0.2, TextTransparency = 0 }):Play()
	
	task.delay(3, function()
		local fadeTween = TweenService:Create(notif, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 })
		fadeTween:Play()
		fadeTween.Completed:Connect(function()
			notif:Destroy()
		end)
	end)
end

-- ============================================================
-- Data Sync Handler
-- ============================================================

dataSyncEvent.OnClientEvent:Connect(function(data)
	if not data then return end
	
	-- Update client data cache
	clientData.Energy = data.Energy or clientData.Energy
	clientData.LifetimeEnergy = data.LifetimeEnergy or clientData.LifetimeEnergy
	clientData.ClickPower = data.ClickPower or clientData.ClickPower
	clientData.AutoPower = data.AutoPower or clientData.AutoPower
	clientData.CoreAmplifier = data.CoreAmplifier or clientData.CoreAmplifier
	clientData.Luck = data.Luck or clientData.Luck
	clientData.Rebirths = data.Rebirths or clientData.Rebirths
	clientData.Gems = data.Gems or clientData.Gems
	clientData.UpgradeLevels = data.UpgradeLevels or clientData.UpgradeLevels
	clientData.History = data.History or clientData.History
	clientData.BestRarity = data.BestRarity or clientData.BestRarity
	clientData.BestRarityName = data.BestRarityName or clientData.BestRarityName
	clientData.FactoryStage = data.FactoryStage or clientData.FactoryStage
	clientData.HighestFactoryStage = data.HighestFactoryStage or clientData.HighestFactoryStage
	clientData.DailyReward = data.DailyReward or clientData.DailyReward
	clientData.PlaytimeReward = data.PlaytimeReward or clientData.PlaytimeReward
	clientData.PurchasedPerks = data.PurchasedPerks or clientData.PurchasedPerks
	
	updateUI()
end)

-- ============================================================
-- UI Update Function
-- ============================================================

function updateUI()
	-- TopBar
	energyLabel.Text = NumberFormatter.format(clientData.Energy)
	
	-- Factory Evolution stage display
	local stage = clientData.HighestFactoryStage or 1
	local stageInfo = FactoryDefinitions.getStage(stage)
	factoryStageLabel.Text = "Stage " .. stage .. ": " .. stageInfo.name
	factoryStageLabel.TextColor3 = stageInfo.coreColor
	
	-- Show progress toward next stage
	local nextStage = FactoryDefinitions.getNextStage(stage)
	if nextStage then
		local progress = FactoryDefinitions.getProgress(stage, clientData.LifetimeEnergy or 0, clientData.Rebirths or 0)
		local pct = math.floor(progress * 100)
		local nextName = nextStage.name
		local reqText = nextStage.rebirthsRequired > 0 and clientData.Rebirths >= nextStage.rebirthsRequired
			and ("Unlocked via Rebirths!")
			or (pct .. "% to " .. nextName)
		factoryStageLabel.Text = factoryStageLabel.Text .. " (" .. reqText .. ")"
	end
	gemsLabel.Text = "Gems: " .. NumberFormatter.format(clientData.Gems)
	rebirthsLabel.Text = "Rebirths: " .. NumberFormatter.format(clientData.Rebirths)
	luckLabel.Text = "Luck: " .. NumberFormatter.format(clientData.Luck or 0)
	coreAmpLabel.Text = "Amp: x" .. string.format("%.1f", clientData.CoreAmplifier or 1)
	
	-- Best rarity record display
	local bestRarityIdx = clientData.BestRarity or 0
	if bestRarityIdx > 0 and Config.LuckRarities[bestRarityIdx] then
		local rarityInfo = Config.LuckRarities[bestRarityIdx]
		bestRarityLabel.Text = "Best: " .. rarityInfo.name .. " (x" .. NumberFormatter.format(rarityInfo.multiplier) .. ")"
		bestRarityLabel.TextColor3 = rarityInfo.color
	else
		bestRarityLabel.Text = "Best: None yet"
		bestRarityLabel.TextColor3 = COLORS.textDim
	end
	
	-- Update history panel entries
	for _, child in ipairs(historyScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local history = clientData.History or {}
	if #history == 0 then
		local emptyLabel = makeText(historyScroll, "No rare pulls yet — keep pressing!", 12, UDim2.new(0, 0, 0, 0), COLORS.textDim, Enum.Font.Gotham)
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
	else
		for _, entry in ipairs(history) do
			local rarityInfo = Config.LuckRarities[entry.rarityIndex] or { name = entry.rarityName or "?", color = COLORS.text }
			local row = makeGui("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = COLORS.bg,
				BorderSizePixel = 0,
			}, historyScroll)
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 4)
			rc.Parent = row
			
			local nameLabel = makeText(row, entry.rarityName or "?", 11, UDim2.new(0, 8, 0, 0), rarityInfo.color, Enum.Font.GothamBold)
			nameLabel.Size = UDim2.new(0, 100, 1, 0)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			
			local rewardLabel = makeText(row, "+" .. NumberFormatter.format(entry.reward or 0), 11, UDim2.new(0, 110, 0, 0), COLORS.gold, Enum.Font.GothamBold)
			rewardLabel.Size = UDim2.new(1, -118, 1, 0)
			rewardLabel.TextXAlignment = Enum.TextXAlignment.Right
		end
	end
	
	-- Upgrade buttons
	for _, upgrade in ipairs(Config.Upgrades) do
		local ui = upgradeButtons[upgrade.id]
		if ui then
			local level = clientData.UpgradeLevels[upgrade.id] or 0
			local cost = Config.getUpgradeCost(upgrade.id, level)
			ui.levelLabel.Text = "Lv. " .. level
			ui.costLabel.Text = NumberFormatter.format(cost)
			
			-- Color: red if can't afford, green if can
			if clientData.Energy >= cost and UpgradeDefinitions.canLevelUp(upgrade.id, level) then
				ui.costLabel.TextColor3 = COLORS.good
			else
				ui.costLabel.TextColor3 = COLORS.danger
			end
			
			-- Dim if maxed
			if level >= upgrade.maxLevel then
				ui.costLabel.Text = "MAX"
				ui.levelLabel.TextColor3 = COLORS.gold
			end
		end
	end
	
	-- Rebirth panel
	local rebirthCost = Config.getRebirthCost(clientData.Rebirths)
	local rebirthMult = Config.getRebirthMultiplier(clientData.Rebirths + 1)
	rebirthCostLabel.Text = "Cost: " .. NumberFormatter.format(rebirthCost) .. " Energy"
	rebirthMultLabel.Text = "New Multiplier: x" .. string.format("%.2f", rebirthMult)
	if clientData.Energy >= rebirthCost then
		rebirthCostLabel.TextColor3 = COLORS.good
	else
		rebirthCostLabel.TextColor3 = COLORS.danger
	end
	
	-- Daily reward
	local now = os.time()
	local cooldownSec = Config.DailyReward.CooldownHours * 3600
	local timeSince = now - (clientData.DailyReward.LastClaim or 0)
	if timeSince >= cooldownSec then
		dailyTimerLabel.Text = "Ready to claim!"
		dailyTimerLabel.TextColor3 = COLORS.good
		dailyClaimBtn.BackgroundColor3 = COLORS.good
	else
		local remaining = cooldownSec - timeSince
		dailyTimerLabel.Text = "Next: " .. NumberFormatter.formatTime(remaining)
		dailyTimerLabel.TextColor3 = COLORS.textDim
		dailyClaimBtn.BackgroundColor3 = COLORS.textDim
	end
	dailyStreakLabel.Text = "Streak: Day " .. ((clientData.DailyReward.Streak or 0) + 1)
	
	-- Playtime reward
	local ptIndex = clientData.PlaytimeReward.Index or 1
	if ptIndex > #Config.PlaytimeReward.Intervals then
		playtimeProgressLabel.Text = "All rewards claimed!"
		playtimeClaimBtn.BackgroundColor3 = COLORS.textDim
	else
		local required = Config.PlaytimeReward.Intervals[ptIndex]
		local current = clientData.PlaytimeReward.TotalPlaytime or 0
		playtimeProgressLabel.Text = string.format("%.0fs / %s", current, NumberFormatter.formatTime(required))
		if current >= required then
			playtimeClaimBtn.BackgroundColor3 = COLORS.accent
		else
			playtimeClaimBtn.BackgroundColor3 = COLORS.textDim
		end
	end
	
	-- Shop: update owned status
	for perkId, ui in pairs(shopButtons) do
		if clientData.PurchasedPerks and clientData.PurchasedPerks[perkId] then
			ui.button.Text = "OWNED"
			ui.button.BackgroundColor3 = COLORS.good
			ui.button.AutoButtonColor = false
			ui.button.Active = false
		end
	end
end

-- ============================================================
-- Panel Management
-- ============================================================

local activePanel = nil

local function togglePanel(panel)
	if activePanel == panel then
		panel.Visible = false
		activePanel = nil
	elseif activePanel then
		activePanel.Visible = false
		panel.Visible = true
		activePanel = panel
	else
		panel.Visible = true
		activePanel = panel
	end
end

-- Nav button connections
upgradeBtn.MouseButton1Click:Connect(function() togglePanel(upgradePanel) end)
rebirthNavBtn.MouseButton1Click:Connect(function() togglePanel(rebirthPanel) end)
shopNavBtn.MouseButton1Click:Connect(function() togglePanel(shopPanel) end)
dailyNavBtn.MouseButton1Click:Connect(function() togglePanel(dailyPanel) end)
playtimeNavBtn.MouseButton1Click:Connect(function() togglePanel(playtimePanel) end)
historyNavBtn.MouseButton1Click:Connect(function() togglePanel(historyPanel) end)

-- Close button connections
upgradeClose.MouseButton1Click:Connect(function() upgradePanel.Visible = false; activePanel = nil end)
rebirthClose.MouseButton1Click:Connect(function() rebirthPanel.Visible = false; activePanel = nil end)
shopClose.MouseButton1Click:Connect(function() shopPanel.Visible = false; activePanel = nil end)
dailyClose.MouseButton1Click:Connect(function() dailyPanel.Visible = false; activePanel = nil end)
playtimeClose.MouseButton1Click:Connect(function() playtimePanel.Visible = false; activePanel = nil end)
historyClose.MouseButton1Click:Connect(function() historyPanel.Visible = false; activePanel = nil end)

-- ============================================================
-- 3D Facility ProximityPrompt Connections
-- ============================================================
-- Each facility on the map has a ProximityPrompt. When the
-- player presses E (or taps the mobile button), the corresponding
-- GUI panel toggles open/closed — same as the left-side nav buttons.

local gameMap = workspace:FindFirstChild("GameMap")

local facilityLinks = {
	{zoneName = "UpgradeZone",  partName = "UpgradePlatform",  panel = upgradePanel},
	{zoneName = "RebirthZone",  partName = "RebirthPedestal",  panel = rebirthPanel},
	{zoneName = "VIPZone",      partName = "VIPPedestal",      panel = shopPanel},
	{zoneName = "DailyZone",    partName = "DailyPedestal",    panel = dailyPanel},
	{zoneName = "PlaytimeZone", partName = "PlaytimePedestal", panel = playtimePanel},
}

if gameMap then
	for _, link in ipairs(facilityLinks) do
		local zone = gameMap:FindFirstChild(link.zoneName)
		local part = zone and zone:FindFirstChild(link.partName)
		if part then
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function()
					togglePanel(link.panel)
				end)
			end
		end
	end
end

-- ============================================================
-- Button Action Connections
-- ============================================================

-- Press button (fires RemoteEvent)
pressButton.MouseButton1Click:Connect(function()
	pressCoreEvent:FireServer()
	
	-- Visual press effect
	local originalSize = pressButton.Size
	local tween = TweenService:Create(
		pressButton,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 100, 0, 100) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		local returnTween = TweenService:Create(
			pressButton,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = originalSize }
		)
		returnTween:Play()
	end)
end)

-- Upgrade button connections
for _, upgrade in ipairs(Config.Upgrades) do
	local ui = upgradeButtons[upgrade.id]
	if ui and ui.button then
		ui.button.MouseButton1Click:Connect(function()
			buyUpgradeEvent:FireServer(upgrade.id)
		end)
	end
end

-- Rebirth confirm
rebirthConfirmBtn.MouseButton1Click:Connect(function()
	requestRebirthEvent:FireServer()
end)

-- Daily claim
dailyClaimBtn.MouseButton1Click:Connect(function()
	claimDailyEvent:FireServer()
end)

-- Playtime claim
playtimeClaimBtn.MouseButton1Click:Connect(function()
	claimPlaytimeEvent:FireServer()
end)

-- Shop buy buttons
for perkId, ui in pairs(shopButtons) do
	ui.button.MouseButton1Click:Connect(function()
		if ui.passInfo.id == 0 then return end -- Disabled
		if clientData.PurchasedPerks and clientData.PurchasedPerks[perkId] then return end -- Already owned
		MarketplaceService:PromptGamePassPurchase(player, ui.passInfo.id)
	end)
end

-- ============================================================
-- Press Feedback Handler (visual effects)
-- ============================================================

pressFeedbackEvent.OnClientEvent:Connect(function(feedback)
	if not feedback then return end
	
	local reward = feedback.reward or 0
	local rarityName = feedback.rarityName or "COMMON"
	local rarityColor = feedback.rarityColor or Color3.fromRGB(200, 200, 200)
	local rarityIndex = feedback.rarityIndex or 1
	
	-- Determine display size and popup text based on 8-tier system
	local displayColor = rarityColor
	local displaySize = 18
	local popupText = "+" .. NumberFormatter.format(reward)
	
	if rarityIndex >= 8 then -- JACKPOT
		displaySize = 40
		popupText = "JACKPOT!!! +" .. NumberFormatter.format(reward) .. " ENERGY!!!"
	elseif rarityIndex >= 7 then -- COSMIC
		displaySize = 36
		popupText = rarityName .. "! +" .. NumberFormatter.format(reward)
	elseif rarityIndex >= 6 then -- MYTHIC
		displaySize = 32
		popupText = rarityName .. "! +" .. NumberFormatter.format(reward)
	elseif rarityIndex >= 5 then -- LEGENDARY
		displaySize = 30
		popupText = rarityName .. "! +" .. NumberFormatter.format(reward)
	elseif rarityIndex >= 4 then -- EPIC
		displaySize = 26
		popupText = rarityName .. "! +" .. NumberFormatter.format(reward)
	elseif rarityIndex >= 3 then -- RARE
		displaySize = 24
		popupText = rarityName .. "! +" .. NumberFormatter.format(reward)
	elseif rarityIndex >= 2 then -- UNCOMMON
		displaySize = 20
		popupText = rarityName .. " +" .. NumberFormatter.format(reward)
	end
	
	-- Show floating popup near the press button
	local popup = makeGui("TextLabel", {
		Text = popupText,
		TextSize = displaySize,
		Size = UDim2.new(0, 400, 0, 40),
		Position = UDim2.new(0.5, -200, 1, -180),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = displayColor,
		Font = Enum.Font.GothamBlack,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, screenGui)
	
	-- Animate popup upward and fade
	local moveTween = TweenService:Create(
		popup,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -200, 1, -260), TextTransparency = 1, BackgroundTransparency = 1 }
	)
	
	-- Fade in first
	popup.TextTransparency = 0.5
	TweenService:Create(popup, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
	
	task.wait(0.1)
	moveTween:Play()
	moveTween.Completed:Connect(function()
		popup:Destroy()
	end)
	
	-- RARE+ rarity notification
	if rarityIndex >= 3 then
		showNotification(rarityName .. "! +" .. NumberFormatter.format(reward) .. " Energy!", rarityColor)
	end

	-- JACKPOT special: full-screen overlay + big center text
	if rarityIndex >= 8 then
		-- Full screen gold flash
		local jackpotFlash = makeGui("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 215, 0),
			BackgroundTransparency = 0.4,
			ZIndex = 20,
		}, screenGui)
		local jTween = TweenService:Create(jackpotFlash, TweenInfo.new(1.5), { BackgroundTransparency = 1 })
		jTween:Play()
		jTween.Completed:Connect(function()
			jackpotFlash:Destroy()
		end)
		
		-- Big center text
		local jackpotText = makeGui("TextLabel", {
			Text = "JACKPOT!!!",
			TextSize = 48,
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 0.3, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 215, 0),
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 21,
		}, screenGui)
		jackpotText.TextTransparency = 1
		TweenService:Create(jackpotText, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
		task.delay(3, function()
			local jtOut = TweenService:Create(jackpotText, TweenInfo.new(0.5), { TextTransparency = 1 })
			jtOut:Play()
			jtOut.Completed:Connect(function()
				jackpotText:Destroy()
			end)
		end)
	
	-- COSMIC / MYTHIC: strong screen flash
	elseif rarityIndex >= 6 then
		local flash = makeGui("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = rarityColor,
			BackgroundTransparency = 0.5,
			ZIndex = 10,
		}, screenGui)
		local flashTween = TweenService:Create(flash, TweenInfo.new(1.0), { BackgroundTransparency = 1 })
		flashTween:Play()
		flashTween.Completed:Connect(function()
			flash:Destroy()
		end)
	
	-- LEGENDARY / EPIC: moderate screen flash
	elseif rarityIndex >= 4 then
		local flash = makeGui("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = rarityColor,
			BackgroundTransparency = 0.7,
			ZIndex = 10,
		}, screenGui)
		local flashDuration = rarityIndex >= 5 and 0.6 or 0.3
		local flashTween = TweenService:Create(flash, TweenInfo.new(flashDuration), { BackgroundTransparency = 1 })
		flashTween:Play()
		flashTween.Completed:Connect(function()
			flash:Destroy()
		end)
	end
end)

-- ============================================================
-- Rarity Broadcast Handler (server-to-client announcements)
-- ============================================================

rarityBroadcastEvent.OnClientEvent:Connect(function(broadcast)
	if not broadcast then return end
	
	local playerName = broadcast.playerName or "???"
	local rarityName = broadcast.rarityName or "?"
	local rarityColor = broadcast.rarityColor or COLORS.text
	local reward = broadcast.reward or 0
	
	-- Show broadcast notification to all players
	local notifText = playerName .. " rolled " .. rarityName .. "! (" .. NumberFormatter.format(reward) .. " Energy)"
	showNotification(notifText, rarityColor)
end)

-- ============================================================
-- Factory Evolution Sync Handler
-- ============================================================

factoryEvolutionSync.OnClientEvent:Connect(function(data)
	if not data then return end
	
	-- Server-wide stage update
	if data.serverStage then
		local stageInfo = FactoryDefinitions.getStage(data.serverStage)
		showNotification("Factory evolved to Stage " .. data.serverStage .. ": " .. (data.stageName or stageInfo.name), stageInfo.coreColor)
	end
	
	-- Player-specific stage upgrade
	if data.isUpgrade and data.playerStage then
		local stageInfo = FactoryDefinitions.getStage(data.playerStage)
		showNotification("FACTORY UPGRADE! Stage " .. data.playerStage .. ": " .. (data.stageName or stageInfo.name), stageInfo.coreColor)
		if data.stageDescription then
			showNotification(data.stageDescription, COLORS.text)
		end
	end
end)

-- ============================================================
-- Daily/Playtime Timer Update
-- ============================================================

task.spawn(function()
	while true do
		task.wait(1)
		updateUI()
	end
end)

-- ============================================================
-- Initialize
-- ============================================================

-- Wait for data to load
local attempts = 0
while not player:GetAttribute("DataLoaded") and attempts < 60 do
	task.wait(0.5)
	attempts = attempts + 1
end

updateUI()
showNotification("Welcome to Lucky Core Factory!", COLORS.accent)
