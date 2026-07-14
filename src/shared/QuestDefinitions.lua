--!strict

local pressCategory = table.freeze({
	id = "Press",
	-- RECOVERY_PROVISIONAL: the original category display name was not recovered.
	name = "PRESS",
	-- RECOVERY_PROVISIONAL: the original category color was not recovered.
	color = Color3.fromRGB(0, 170, 255),
})

local QuestDefinitions = {
	AchievementCategories = table.freeze({
		pressCategory,
	}),
}

return table.freeze(QuestDefinitions)
