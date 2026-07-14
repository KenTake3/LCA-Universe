# WP-01 — Recover Config Contract

## Mission

Implement the missing `Config` ModuleScript contract required by the salvaged LCA code.

This is a recovery task, not a rebalance or monetization task.

## Inputs

Read completely:

- `AGENTS.md`
- `docs/06_Current_System.md`
- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/SecurityService.lua`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/FactoryEvolution.server.lua`

## Allowed Files

You may create or modify only:

- `src/shared/Config.lua`
- `tests/manual/WP-01_Config.md`
- `CHANGELOG.md`

Do not modify recovered files.

## Required Config Interface

Implement every Config field or function referenced by the recovered code.

At minimum:

- `DataVersion`
- `DEBUG_MODE`
- `MaxPressesPerSecond`
- `Security`
  - `MaxEnergy`
  - `MaxGems`
  - `MaxRebirths`
  - `MaxUpgradeLevel`
  - `MaxLuck`
  - `MaxCoreAmplifier`
  - `MaxRewardPerPress`
- `Upgrades`
- `GamePasses`
- `DailyReward`
- `PlaytimeReward`
- `LuckRarities`
- `getUpgradeCost(upgradeId, currentLevel)`
- `getRebirthCost(currentRebirths)`
- `getRebirthMultiplier(rebirthCount)`

## Required Upgrade IDs

The existing saved-data schema requires these exact IDs:

- `ClickPower`
- `AutoPower`
- `CoreAmplifier`
- `Luck`

Each upgrade entry must include all fields used by MainGuiClient and SecurityService:

- `id`
- `displayName`
- `description`
- `iconColor`
- `maxLevel`

You may add internal fields required for cost calculation.

## Luck Rarities

Provide eight ordered rarity entries compatible with:

- index-based saved history
- `name`
- `color`
- `multiplier`

Use these known names and multipliers:

1. COMMON ×1
2. UNCOMMON ×2
3. RARE ×5
4. EPIC ×15
5. LEGENDARY ×50
6. MYTHIC ×250
7. COSMIC ×2,000
8. JACKPOT ×77,777

Do not implement rolling logic in this task.

## Monetization Safety

All unknown Game Pass IDs must remain `0`.

Do not invent production IDs.

Entries with ID `0` must remain visibly disabled by the existing client.

## Provisional Values

When original balance values are unknown:

- Use conservative, playable defaults.
- Mark them clearly with comments containing `RECOVERY_PROVISIONAL`.
- Centralize them so they can be rebalanced later.
- Avoid exponential values that immediately break early progression.

## Function Safety

All public functions must:

- tolerate invalid types
- return finite non-negative numbers
- avoid NaN and infinity
- use deterministic calculations
- cap results using Config.Security values where relevant

## Rojo Mapping

The file must be compatible with the current project mapping:

`src/shared/Config.lua`
→ `ReplicatedStorage/LCA_Shared/Config`

Do not change `default.project.json` during this task.

## Manual Test Document

Create `tests/manual/WP-01_Config.md` containing:

- Interface checklist
- Upgrade ID checklist
- Rarity checklist
- Invalid input tests
- Cost monotonicity tests
- Rebirth monotonicity tests
- Monetization ID safety check
- Studio integration prerequisites

## Changelog

Add an Unreleased entry describing the recovered Config contract and noting that unknown balance values are provisional.

## Completion Requirements

Before finishing:

1. Inspect the diff.
2. Confirm no other files changed.
3. Report every provisional value.
4. Report every unknown still unresolved.
5. Do not commit or push.