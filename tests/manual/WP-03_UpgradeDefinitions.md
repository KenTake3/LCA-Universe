# WP-03 UpgradeDefinitions Manual Test

Test `src/shared/UpgradeDefinitions.lua` as `ReplicatedStorage/LCA_Shared/UpgradeDefinitions` with the sibling recovered Config module.

## Public API and return contract

- [ ] `calculateStats` and `canLevelUp` exist and are functions.
- [ ] `calculateStats(nil, nil)` does not throw.
- [ ] The returned table contains `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck`.
- [ ] The returned table contains no additional gameplay values.
- [ ] Every returned value is finite, non-negative, and deterministic.

## Exact IDs

- [ ] `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck` are supported.
- [ ] Unknown strings, empty strings, differently cased IDs, nil, booleans, numbers, and tables return `false` from `canLevelUp`.
- [ ] No legacy `CriticalChance` or `CriticalMultiplier` ID is accepted.

## Normalization

For every upgrade level and for rebirths:

- [ ] Missing values normalize to `0` in `calculateStats`.
- [ ] Numeric strings such as `"3"` normalize to integer `3`.
- [ ] Negative values clamp to `0`.
- [ ] Fractional values floor after clamping, for example `3.9` becomes `3`.
- [ ] NaN and positive/negative infinity normalize to `0` in `calculateStats`.
- [ ] Unsupported types normalize to `0` in `calculateStats`.
- [ ] Upgrade levels cap at the smaller of the Config upgrade `maxLevel` and `Config.Security.MaxUpgradeLevel`.
- [ ] Rebirths cap at `Config.Security.MaxRebirths`.
- [ ] Input tables are not mutated.

## Config fail-closed behavior

Use isolated Config fixtures and require a fresh copy of UpgradeDefinitions for each case. Do not mutate the production Config ModuleScript during manual testing.

- [ ] Remove `ClickPower` from fixture `Config.Upgrades`; `calculateStats({ClickPower=50}, 0).ClickPower == 1`.
- [ ] With `ClickPower` missing from fixture `Config.Upgrades`, `canLevelUp("ClickPower", 0) == false`.
- [ ] Configure `ClickPower.maxLevel = 0`; it remains recognized as configured, its normalized level is `0`, and `canLevelUp("ClickPower", 0) == false`.
- [ ] Configure `ClickPower.maxLevel` as nil, a string, NaN, positive infinity, or negative infinity; each invalid value produces an effective limit of `0` and `canLevelUp("ClickPower", 0) == false`.
- [ ] Configure `ClickPower.maxLevel` above `Config.Security.MaxUpgradeLevel`; its effective limit equals `Config.Security.MaxUpgradeLevel`.
- [ ] Missing or invalid Config entries never fall back to `Config.Security.MaxUpgradeLevel`.
- [ ] Config, `Config.Upgrades`, and supplied upgrade-level tables remain unchanged after both public API calls.

## Provisional formulas

- [ ] At all zero levels and zero rebirths, stats are `{ClickPower=1, AutoPower=0, CoreAmplifier=1, Luck=0}`.
- [ ] ClickPower is `(1 + ClickPowerLevel) * Config.getRebirthMultiplier(rebirths)`.
- [ ] AutoPower is `AutoPowerLevel * Config.getRebirthMultiplier(rebirths)`.
- [ ] CoreAmplifier is `1 + CoreAmplifierLevel * 0.05`.
- [ ] Luck equals normalized Luck level.
- [ ] Rebirth multiplier affects ClickPower and AutoPower only.
- [ ] ClickPower and AutoPower do not exceed `Config.Security.MaxEnergy`.
- [ ] CoreAmplifier does not exceed `Config.Security.MaxCoreAmplifier`.
- [ ] Luck does not exceed `Config.Security.MaxLuck`.

## `canLevelUp`

- [ ] Level `0` returns `true` for all four IDs when their maximum is positive.
- [ ] Numeric string `"0"` returns `true` for all four IDs.
- [ ] Negative and fractional finite levels normalize consistently before comparison.
- [ ] Exactly the effective maximum returns `false`.
- [ ] Values above the effective maximum return `false`.
- [ ] nil, booleans, tables, invalid strings, NaN, and positive/negative infinity return `false`.
- [ ] The function never throws for malformed input.

## Compatibility and Studio integration

- [ ] Rojo maps the module to `ReplicatedStorage/LCA_Shared/UpgradeDefinitions` without project changes.
- [ ] `calculateStats(data.UpgradeLevels, data.Rebirths)` returns the four fields expected by SessionManager.
- [ ] MainGuiClient can call `canLevelUp(upgrade.id, level)` for every Config upgrade.
- [ ] The recovered `ReplicatedStorage.Shared` require paths are bridged or updated in a separately authorized integration task.
- [ ] Config remains unchanged during WP-03.
