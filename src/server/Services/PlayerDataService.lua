--!strict

local Players = game:GetService("Players")

local PlayerDataService = {}

export type PlayerData = {
	Energy: number,
	LifetimeEnergy: number,
	FactoryStage: number,
}

local sessions: {[Player]: PlayerData} = {}

function PlayerDataService.CreateSession(player: Player): PlayerData
	local existing = sessions[player]
	if existing then
		return existing
	end

	local data: PlayerData = {
		Energy = 0,
		LifetimeEnergy = 0,
		FactoryStage = 1,
	}

	sessions[player] = data

	player:SetAttribute("LCA_Energy", data.Energy)
	player:SetAttribute("LCA_LifetimeEnergy", data.LifetimeEnergy)
	player:SetAttribute("LCA_FactoryStage", data.FactoryStage)

	return data
end

function PlayerDataService.GetSession(player: Player): PlayerData?
	return sessions[player]
end

function PlayerDataService.RemoveSession(player: Player)
	sessions[player] = nil
end

function PlayerDataService.Init()
	for _, player in Players:GetPlayers() do
		PlayerDataService.CreateSession(player)
	end

	Players.PlayerAdded:Connect(PlayerDataService.CreateSession)
	Players.PlayerRemoving:Connect(PlayerDataService.RemoveSession)
end

return PlayerDataService