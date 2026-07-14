--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LCAConfig")
)

local EnergyService = {}

local playerDataService: any = nil

function EnergyService.SetPlayerDataService(service: any)
	playerDataService = service
end

function EnergyService.AddEnergy(player: Player, amount: number): (boolean, number?)
	if not Config.Enabled then
		return false, nil
	end

	if not playerDataService then
		warn("[EnergyService] PlayerDataService is not configured")
		return false, nil
	end

	if typeof(amount) ~= "number"
		or amount ~= amount
		or amount == math.huge
		or amount <= 0
	then
		return false, nil
	end

	local data = playerDataService.GetSession(player)
	if not data then
		return false, nil
	end

	local safeAmount = math.floor(amount)

	data.Energy = math.min(
		data.Energy + safeAmount,
		Config.Data.MaxEnergy
	)

	data.LifetimeEnergy = math.min(
		data.LifetimeEnergy + safeAmount,
		Config.Data.MaxEnergy
	)

	player:SetAttribute("LCA_Energy", data.Energy)
	player:SetAttribute("LCA_LifetimeEnergy", data.LifetimeEnergy)

	return true, data.Energy
end

return EnergyService