--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LCAConfig")
)

local FactoryService = {}

local playerDataService: any = nil

function FactoryService.SetPlayerDataService(service: any)
	playerDataService = service
end

function FactoryService.GetEligibleStage(lifetimeEnergy: number): number
	local eligibleStage = 1

	for stage, definition in Config.FactoryStages do
		if lifetimeEnergy >= definition.RequiredLifetimeEnergy then
			eligibleStage = math.max(eligibleStage, stage)
		end
	end

	return eligibleStage
end

function FactoryService.RefreshPlayerStage(player: Player): number?
	if not playerDataService then
		return nil
	end

	local data = playerDataService.GetSession(player)
	if not data then
		return nil
	end

	local eligibleStage = FactoryService.GetEligibleStage(
		data.LifetimeEnergy
	)

	if eligibleStage > data.FactoryStage then
		data.FactoryStage = eligibleStage
		player:SetAttribute("LCA_FactoryStage", eligibleStage)
	end

	return data.FactoryStage
end

return FactoryService