--[[
	FactoryEvolution Script (ServerScriptService)
	Lucky Core Factory - Factory Evolution Stage Manager

	Tracks each player's FactoryStage and HighestFactoryStage.
	The server-wide visual factory stage = max(HighestFactoryStage) across all players.

	Stage unlock conditions:
	  Stage 1: Default (Core Online)
	  Stage 2: 500 Lifetime Energy (Power Generator)
	  Stage 3: 5,000 Lifetime Energy (Industrial Factory)
	  Stage 4: 50,000 Lifetime Energy OR 1 Rebirth (Advanced Reactor)
	  Stage 5: 500,000 Lifetime Energy OR 3 Rebirths (Mega Factory)
	  Stage 6: 5,000,000 Lifetime Energy OR 10 Rebirths (Quantum Factory)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local FactoryDefinitions = require(ReplicatedStorage.Shared.FactoryDefinitions)
local SessionManager = require(ServerStorage.SessionManager)
local ServerDataService = require(ServerStorage.ServerDataService)

local DEBUG = Config.DEBUG_MODE or false

local function dprint(...)
	if DEBUG then
		print("[FactoryEvolution]", ...)
	end
end

-- ============================================================
-- Remote Setup
-- ============================================================

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local factoryEvolutionSync = remotes and remotes:FindFirstChild("FactoryEvolutionSync")
if not factoryEvolutionSync then
	warn("[FactoryEvolution] FactoryEvolutionSync RemoteEvent not found!")
end

-- ============================================================
-- Visual Stage Management
-- ============================================================

local factoryEvolutionFolder = Workspace:FindFirstChild("FactoryEvolution")
local stageFolders = {}

if factoryEvolutionFolder then
	for i = 1, #FactoryDefinitions.Stages do
		stageFolders[i] = factoryEvolutionFolder:FindFirstChild("Stage" .. i)
	end
end

local function setStageVisible(stageId, isVisible)
	local folder = stageFolders[stageId]
	if not folder then return end
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Transparency = isVisible and 0 or 1
		elseif child:IsA("Decal") or child:IsA("Texture") then
			child.Transparency = isVisible and 0 or 1
		end
	end
end

-- Update the visual factory to show all stages up to the server stage
local function updateVisualStage(serverStage)
	if not factoryEvolutionFolder then return end

	for i = 1, #FactoryDefinitions.Stages do
		setStageVisible(i, i <= serverStage)
	end

	factoryEvolutionFolder:SetAttribute("ServerStage", serverStage)

	-- Update EnergyCore color based on stage
	local energyCore = Workspace:FindFirstChild("Interactive")
	if energyCore then
		energyCore = energyCore:FindFirstChild("EnergyCore")
	end
	if energyCore then
		local coreInner = energyCore:FindFirstChild("CoreInner")
		if coreInner then
			local stageInfo = FactoryDefinitions.getStage(serverStage)
			coreInner.Color = stageInfo.coreColor
			-- Also update the outer ring if it exists
			local coreOuter = energyCore:FindFirstChild("CoreOuter")
			if coreOuter then
				coreOuter.Color = stageInfo.coreColor
			end
		end
	end

	-- Broadcast to all clients
	if factoryEvolutionSync then
		factoryEvolutionSync:FireAllClients({
			serverStage = serverStage,
			stageName = FactoryDefinitions.getStage(serverStage).name,
		})
	end

	dprint("Visual stage updated to", serverStage, "(" .. FactoryDefinitions.getStage(serverStage).name .. ")")
end

-- ============================================================
-- Player Stage Tracking
-- ============================================================

-- Check and update a player's FactoryStage based on their LifetimeEnergy and Rebirths
local function updatePlayerStage(player)
	local session = SessionManager.getSession(player.UserId)
	if not session or session.DataState ~= "Loaded" then return end

	local data = session.Data
	local newStage = FactoryDefinitions.calculateStage(data.LifetimeEnergy, data.Rebirths)

	-- Only update if the stage increased
	if newStage > (data.HighestFactoryStage or 1) then
		local oldStage = data.HighestFactoryStage or 1
		data.HighestFactoryStage = newStage
		data.FactoryStage = newStage

		local stageInfo = FactoryDefinitions.getStage(newStage)
		dprint(player.Name, "advanced to Factory Stage", newStage, "(" .. stageInfo.name .. ")")

		-- Notify the player
		if factoryEvolutionSync then
			factoryEvolutionSync:FireClient(player, {
				playerStage = newStage,
				stageName = stageInfo.name,
				stageDescription = stageInfo.description,
				isUpgrade = true,
			})
		end

		-- Sync data to client
		ServerDataService.syncToClient(player)

		return newStage
	end

	return nil
end

-- ============================================================
-- Server-Wide Stage Calculation
-- ============================================================

local currentServerStage = 1

local function recalculateServerStage()
	local maxStage = 1

	for _, player in ipairs(Players:GetPlayers()) do
		local session = SessionManager.getSession(player.UserId)
		if session and session.DataState == "Loaded" then
			local highest = session.Data.HighestFactoryStage or 1
			if highest > maxStage then
				maxStage = highest
			end
		end
	end

	if maxStage ~= currentServerStage then
		currentServerStage = maxStage
		updateVisualStage(currentServerStage)
	end
end

-- ============================================================
-- Stage Check Loop
-- ============================================================

-- Check player stages periodically (every 2 seconds)
task.spawn(function()
	while true do
		task.wait(2)
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayerStage(player)
		end
		recalculateServerStage()
	end
end)

-- ============================================================
-- Player Join Handler
-- ============================================================

Players.PlayerAdded:Connect(function(player)
	-- Check stage after data is loaded (delayed to allow DataService to finish)
	task.delay(3, function()
		if not player.Parent then return end
		updatePlayerStage(player)
		recalculateServerStage()
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Recalculate server stage after a player leaves
	task.delay(1, function()
		recalculateServerStage()
	end)
end)

-- ============================================================
-- Initialize
-- ============================================================

-- Set initial visual stage
updateVisualStage(1)

-- Check stages for any players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2)
		updatePlayerStage(player)
	end)
end

dprint("FactoryEvolution initialized successfully")
