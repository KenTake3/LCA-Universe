# WP-01 Config Manual Test

Test the ModuleScript mapped from `src/shared/Config.lua` to `ReplicatedStorage/LCA_Shared/Config`. These checks validate the recovered contract; they do not approve the provisional balance for release.

## Interface checklist

- [ ] `DataVersion` is a finite non-negative number.
- [ ] `DEBUG_MODE` is `false`.
- [ ] `MaxPressesPerSecond` is a finite positive number.
- [ ] `Security` contains `MaxEnergy`, `MaxGems`, `MaxRebirths`, `MaxUpgradeLevel`, `MaxLuck`, `MaxCoreAmplifier`, and `MaxRewardPerPress` as finite non-negative numbers.
- [ ] `Upgrades`, `GamePasses`, `DailyReward`, `PlaytimeReward`, and `LuckRarities` are tables.
- [ ] `getUpgradeCost`, `getRebirthCost`, and `getRebirthMultiplier` are functions.
- [ ] `DailyReward.Gems` has seven entries.
- [ ] `PlaytimeReward.Intervals` and `PlaytimeReward.Gems` have matching lengths and ascending intervals.

## Upgrade ID checklist

- [ ] Exactly one `ClickPower` entry exists.
- [ ] Exactly one `AutoPower` entry exists.
- [ ] Exactly one `CoreAmplifier` entry exists.
- [ ] Exactly one `Luck` entry exists.
- [ ] Every entry has `id`, `displayName`, `description`, `iconColor`, and `maxLevel`.
- [ ] Every `maxLevel` is positive and does not exceed `Security.MaxUpgradeLevel`.

## Rarity checklist

- [ ] There are exactly eight ordered entries.
- [ ] Names in order are COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC, COSMIC, JACKPOT.
- [ ] Multipliers in order are 1, 2, 5, 15, 50, 250, 2,000, 77,777.
- [ ] Every entry contains a Color3 `color`.

## Invalid input tests

Run each call in Studio and confirm it does not throw and returns a finite non-negative number:

- [ ] `getUpgradeCost(nil, nil) == 0`
- [ ] `getUpgradeCost({}, {}) == 0`
- [ ] `getUpgradeCost("Unknown", 0) == 0`
- [ ] `getUpgradeCost("ClickPower", -10) == getUpgradeCost("ClickPower", 0)`
- [ ] `getUpgradeCost("ClickPower", 0 / 0) == getUpgradeCost("ClickPower", 0)`
- [ ] `getUpgradeCost("ClickPower", math.huge) == getUpgradeCost("ClickPower", 0)`
- [ ] `getRebirthCost(nil) == getRebirthCost(0)`
- [ ] `getRebirthCost(-1) == getRebirthCost(0)`
- [ ] `getRebirthCost(0 / 0) == getRebirthCost(0)`
- [ ] `getRebirthCost(math.huge) == getRebirthCost(0)`
- [ ] `getRebirthMultiplier(nil) == 1`
- [ ] `getRebirthMultiplier(-1) == 1`
- [ ] `getRebirthMultiplier(0 / 0) == 1`
- [ ] `getRebirthMultiplier(math.huge) == 1`

## Cost monotonicity tests

For each required upgrade ID:

- [ ] Iterate levels `0..maxLevel`; every cost is finite, non-negative, integral, and `<= Security.MaxEnergy`.
- [ ] Each cost is greater than or equal to the previous level's cost.
- [ ] Repeated calls with the same ID and level return the same value.
- [ ] Levels above `maxLevel` return the same capped-level cost.

## Rebirth monotonicity tests

- [ ] Iterate `0..Security.MaxRebirths`; every cost is finite, non-negative, integral, and `<= Security.MaxEnergy`.
- [ ] Rebirth cost never decreases.
- [ ] Rebirth multiplier never decreases and remains `<= Security.MaxCoreAmplifier`.
- [ ] Inputs above `Security.MaxRebirths` return the same values as the capped count.

## Monetization ID safety check

- [ ] `GamePasses` contains no nonzero ID.
- [ ] No production Game Pass or developer product ID appears in `Config.lua`.
- [ ] If a future disabled entry is added, its `id` remains `0` so MainGuiClient renders it as `SOON` and inactive.

## Studio integration prerequisites

- [ ] Rojo maps `src/shared/Config.lua` to `ReplicatedStorage/LCA_Shared/Config` without changing `default.project.json`.
- [ ] Consumers are updated or bridged separately if they still require `ReplicatedStorage.Shared.Config`; WP-01 does not change recovered consumers or the project mapping.
- [ ] `Color3` and `table.clone` are available in the Studio runtime.
- [ ] The Config ModuleScript can be required from both client and server contexts.
- [ ] Before gameplay integration, WP-03 confirms upgrade definitions use the same four IDs and caps.
- [ ] Before release, a human reviews every `RECOVERY_PROVISIONAL` value.
