# WP-03 — Recover UpgradeDefinitions

## Mission

Implement the missing `UpgradeDefinitions` ModuleScript required by the recovered LCA session and client code.

This is a compatibility recovery task.

Do not rebalance the whole game.
Do not implement purchases or RemoteEvent handlers.

## Inputs

Read completely:

- `AGENTS.md`
- `docs/06_Current_System.md`
- `src/shared/Config.lua`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/SecurityService.lua`
- `prompts/codex/WP-03_UpgradeDefinitions.md`

## Allowed Files

You may create or modify only:

- `src/shared/UpgradeDefinitions.lua`
- `tests/manual/WP-03_UpgradeDefinitions.md`
- `CHANGELOG.md`

Do not modify:

- Config
- recovered files
- Rojo project mappings
- any server handlers

## Required Public API

Implement:

- `UpgradeDefinitions.calculateStats(upgradeLevels, rebirths)`
- `UpgradeDefinitions.canLevelUp(upgradeId, currentLevel)`

You may add private helper functions.

## Exact Upgrade IDs

Support only:

- `ClickPower`
- `AutoPower`
- `CoreAmplifier`
- `Luck`

Unknown IDs must fail safely.

## `calculateStats` Return Contract

Return a table containing exactly these gameplay values:

- `ClickPower`
- `AutoPower`
- `CoreAmplifier`
- `Luck`

All values must be:

- finite
- non-negative
- deterministic
- safe for invalid or missing input
- capped using Config.Security where relevant

## Recovery-Provisional Stat Model

Use a simple additive model unless recovered code proves otherwise.

### ClickPower

- Base value: 1
- Each ClickPower level adds 1
- Apply rebirth multiplier using `Config.getRebirthMultiplier(rebirths)`

Provisional formula:

`(1 + ClickPowerLevel) * RebirthMultiplier`

### AutoPower

- Base value: 0
- Each AutoPower level adds 1 Energy per second
- Apply rebirth multiplier

Provisional formula:

`AutoPowerLevel * RebirthMultiplier`

### CoreAmplifier

This value is a multiplier.

- Base value: 1
- Each level adds 0.05
- Cap using `Config.Security.MaxCoreAmplifier`

Provisional formula:

`1 + CoreAmplifierLevel * 0.05`

Do not apply rebirth multiplier to CoreAmplifier.

### Luck

- Base value: 0
- Each Luck level adds 1
- Cap using `Config.Security.MaxLuck`

Do not apply rebirth multiplier to Luck.

Mark these formulas with `RECOVERY_PROVISIONAL`.

## Input Safety

`calculateStats` must tolerate:

- nil
- booleans
- strings
- missing upgrade keys
- numeric strings
- negative levels
- fractional levels
- NaN
- positive infinity
- negative infinity
- invalid rebirth values

Upgrade levels and rebirths must be normalized to:

- finite
- non-negative
- integer values
- capped at Config safety limits

## `canLevelUp` Requirements

Return `true` only when:

- upgradeId is one of the four exact IDs
- currentLevel is valid after normalization
- currentLevel is below that upgrade's Config maxLevel
- currentLevel is below Config.Security.MaxUpgradeLevel

Return `false` for unknown IDs or invalid values.

The function must never throw.

## Compatibility

The recovered SessionManager expects:

```lua
local stats = UpgradeDefinitions.calculateStats(
    data.UpgradeLevels,
    data.Rebirths
)
```
