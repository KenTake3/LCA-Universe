# WP-05 QuestDefinitions Manual Tests

## Preconditions

- Build the project with `rojo build default.project.json --output /tmp/LCA-WP05.rbxlx`.
- In Studio, require `QuestDefinitions` from the location produced by the current Rojo mapping.
- Run checks from a temporary command-bar or test harness; do not add the harness to runtime source.

## Load and Exact Public Contract

- [ ] Requiring `QuestDefinitions` succeeds without warnings or errors.
- [ ] The returned value is a table.
- [ ] The module has exactly one public key: `AchievementCategories`.
- [ ] `AchievementCategories` exists and is a dense ordered array.
- [ ] `#QuestDefinitions.AchievementCategories == 1`.
- [ ] The sole record has exactly the keys `id`, `name`, and `color`.
- [ ] No functions or helper APIs are exported.

Suggested public-key check:

```lua
local count = 0
for key in pairs(QuestDefinitions) do
	count += 1
	assert(key == "AchievementCategories")
end
assert(count == 1)
```

## Confirmed Category and Provisional Display Values

- [ ] The sole record's exact ID is `Press`.
- [ ] `id` is a non-empty string.
- [ ] Treat `Press` only as an achievement category ID, not an achievement record ID.
- [ ] `name` is the non-empty provisional string `PRESS`.
- [ ] `color` has `typeof(color) == "Color3"`.
- [ ] The provisional color is `Color3.fromRGB(0, 170, 255)`.
- [ ] Source comments mark both `name` and `color` with `RECOVERY_PROVISIONAL`.
- [ ] Neither provisional display value is presented as original or authoritative.

## Immutability

- [ ] `table.isfrozen(QuestDefinitions)` is true.
- [ ] `table.isfrozen(QuestDefinitions.AchievementCategories)` is true.
- [ ] `table.isfrozen(QuestDefinitions.AchievementCategories[1])` is true.
- [ ] Assigning a new module field fails.
- [ ] Replacing, adding, or removing an array entry fails.
- [ ] Changing `id`, `name`, or `color` on the record fails.
- [ ] Failed mutation attempts leave every exported value unchanged.
- [ ] No mutable lookup or nested table is exported.

Suggested mutation checks:

```lua
assert(not pcall(function()
	QuestDefinitions.Other = {}
end))

assert(not pcall(function()
	QuestDefinitions.AchievementCategories[1].name = "Changed"
end))

assert(not pcall(function()
	table.insert(QuestDefinitions.AchievementCategories, {})
end))
```

## Explicitly Absent Gameplay Definitions

- [ ] No quest records are exported.
- [ ] No daily quest records are exported.
- [ ] No achievement records are exported.
- [ ] No targets or progress-source mappings are present.
- [ ] No completion or claim fields are present.
- [ ] No reward types, amounts, or Config-derived reward values are present.
- [ ] No ordering, prerequisite, reset, date, or timezone values are present.
- [ ] No progress, completion, reward, claim, reset, or lookup helper exists.

## Data-Only and Runtime Isolation

- [ ] The module does not call `game:GetService`.
- [ ] The module does not require Config or another module.
- [ ] The module does not access sessions or DataStores.
- [ ] The module does not access or create RemoteEvents.
- [ ] The module does not access Workspace or UI Instances.
- [ ] The module does not read clocks, dates, locale, random state, or player state.
- [ ] Loading the module performs no mutation outside its local definition tables.
- [ ] The module remains immutable, deterministic, and data-only.

## Recovered Client Compatibility

- [ ] Iterating `AchievementCategories` with `ipairs` yields the `Press` category once.
- [ ] Each field read by `MainGuiClient` (`id`, `name`, and `color`) exists with the expected type.
- [ ] The client initial category selection `Press` corresponds to the exported category ID.
- [ ] Studio integration separately resolves the known `Shared` versus `LCA_Shared` require-path mismatch.
