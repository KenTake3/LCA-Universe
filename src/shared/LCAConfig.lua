--!strict

return {
	-- 既存システムとの二重処理を避けるため、最初はfalse
	Enabled = false,
	DebugMode = true,

	Data = {
		DefaultEnergy = 0,
		DefaultLifetimeEnergy = 0,
		DefaultFactoryStage = 1,
		MaxEnergy = 1e18,
	},

	FactoryStages = {
		[1] = {
			Name = "CORE ONLINE",
			RequiredLifetimeEnergy = 0,
		},
		[2] = {
			Name = "BASIC GENERATOR",
			RequiredLifetimeEnergy = 500,
		},
		[3] = {
			Name = "CONVEYOR SYSTEM",
			RequiredLifetimeEnergy = 5_000,
		},
		[4] = {
			Name = "DRONE ASSEMBLY",
			RequiredLifetimeEnergy = 50_000,
		},
		[5] = {
			Name = "FUSION REACTOR",
			RequiredLifetimeEnergy = 500_000,
		},
		[6] = {
			Name = "QUANTUM FACTORY",
			RequiredLifetimeEnergy = 5_000_000,
		},
	},
}