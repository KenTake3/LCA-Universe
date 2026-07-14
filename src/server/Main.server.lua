--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LCAConfig")
)

local ServicesFolder = script.Parent:WaitForChild("Services")

local PlayerDataService = require(
	ServicesFolder:WaitForChild("PlayerDataService")
)

local EnergyService = require(
	ServicesFolder:WaitForChild("EnergyService")
)

local FactoryService = require(
	ServicesFolder:WaitForChild("FactoryService")
)

EnergyService.SetPlayerDataService(PlayerDataService)
FactoryService.SetPlayerDataService(PlayerDataService)

PlayerDataService.Init()

if Config.DebugMode then
	print(
		"[LCA] Foundation services loaded",
		"Enabled =", Config.Enabled
	)
end