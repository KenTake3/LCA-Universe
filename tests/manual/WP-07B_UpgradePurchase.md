# WP-07B — Upgrade Purchase Manual Tests

## Setup

- [ ] Build and deploy the current Rojo project with the confirmed `BuyUpgrade`, `DataSync`, `PressCore`, and `PressFeedback` RemoteEvents present.
- [ ] Confirm ServerDataService uses SessionRepository and MemoryPersistenceAdapter.
- [ ] Use isolated test sessions and record Energy, all four upgrade levels, revision, savedRevision, and dirty before each case.

## API and initialization

- [ ] GameplayService exports existing `init` and `press` plus `buyUpgrade(player, upgradeId)` only.
- [ ] The purchase result is a fresh frozen table containing only `upgradeId`, `cost`, `newLevel`, and `syncSucceeded`.
- [ ] Main validates BuyUpgrade as a RemoteEvent and injects it into GameplayRemoteController.
- [ ] DataLifecycleService initialization remains last.
- [ ] Controller connects one PressCore listener and one BuyUpgrade listener; WP-07A Press behavior and feedback remain unchanged.

## Payload and ID validation

- [ ] Each exact ID succeeds when its session is eligible: `ClickPower`, `AutoPower`, `CoreAmplifier`, `Luck`.
- [ ] Zero arguments, explicit nil, two arguments, and a trailing nil are rejected.
- [ ] Numbers, booleans, tables, functions, Instances, and userdata are rejected.
- [ ] Empty/whitespace strings, case variants, display names, legacy IDs, and unknown strings are rejected.
- [ ] Malformed payloads do not consume the upgrade rate bucket or call GameplayService.
- [ ] No client level, cost, Energy, max level, or quantity is accepted.

## Session and data validation

- [ ] Invalid Player, wrong exact Player object, and missing session fail unchanged.
- [ ] Loading, Saving, LoadFailed, Released, save-in-flight, and finalizing sessions fail unchanged.
- [ ] Only `state == "Loaded"` is accepted.
- [ ] Invalid revision metadata or dirty mirror mismatch returns `INVALID_DATA`.
- [ ] Missing data/UpgradeLevels tables return `INVALID_DATA`.
- [ ] Energy and selected level reject negatives, fractions, numeric strings, NaN, and both infinities.
- [ ] Energy above MaxEnergy returns `INVALID_DATA`.

## Config and effective-limit classification

- [ ] Missing matching Config.Upgrades entry returns `INVALID_DATA`.
- [ ] Duplicate matching Config.Upgrades entries return `INVALID_DATA`.
- [ ] Invalid/fractional/negative/NaN/infinite `upgrade.maxLevel` returns `INVALID_DATA`.
- [ ] Invalid/fractional/negative/NaN/infinite `Config.Security.MaxUpgradeLevel` returns `INVALID_DATA`.
- [ ] `effectiveLimit` is exactly `min(upgrade.maxLevel, Config.Security.MaxUpgradeLevel)`.
- [ ] `currentLevel >= effectiveLimit`, including a valid zero limit, returns `MAX_LEVEL`.
- [ ] A false `canLevelUp` below a valid effective limit returns `INVALID_DATA`.
- [ ] A true `canLevelUp` continues to cost validation.

## Cost and affordability

- [ ] Cost is recalculated with `Config.getUpgradeCost(upgradeId, currentLevel)` for every attempt.
- [ ] Zero, negative, fractional, NaN, infinite, or over-MaxEnergy cost returns `INVALID_COST`.
- [ ] A raised error from `Config.getUpgradeCost` returns `INVALID_COST` without mutation.
- [ ] Energy below valid cost returns `INSUFFICIENT_ENERGY` with no mutation.
- [ ] Energy equal to cost succeeds and leaves Energy at zero.
- [ ] No free purchase is possible.

## Mutation, dirty marking, and rollback

- [ ] Success changes exactly Energy by `-cost` and the selected level by `+1`.
- [ ] Other upgrade levels and every other persisted field remain unchanged.
- [ ] `markDirty(player)` is called exactly once after both assignments.
- [ ] GameplayService never directly writes revision, savedRevision, or dirty.
- [ ] Dirty failure restores the exact prior Energy and selected level, returns `DIRTY_FAILED`, and does not sync.
- [ ] Dirty success makes exactly one `syncToClient(player)` attempt.
- [ ] Sync failure does not roll back the authoritative mutation and returns success with `syncSucceeded = false`.

## Independent rate limiting and rapid requests

- [ ] BuyUpgrade and PressCore use separate weak-key timestamp maps.
- [ ] Upgrade requests from different Players have independent windows.
- [ ] Requests below the limit are admitted; the at-limit request is rejected; admission resumes after one second.
- [ ] Valid payloads consume the bucket even when GameplayService rejects the purchase.
- [ ] Every rapid request re-reads Energy and level and recalculates cost.
- [ ] Rapid purchases stop at insufficient Energy or max level without over-deduction or over-leveling.
- [ ] No bulk-buy, coalescing, or queue behavior exists.

## Feedback and exclusions

- [ ] Successful purchases are reflected only through DataSync.
- [ ] Failures produce no sync, feedback Remote, notification, or client-authored error detail.
- [ ] No reward, rebirth, claim, factory, rarity, quest, purchase-receipt, DataStore, autosave, or retry behavior was added.
- [ ] No file outside the WP-07B allowlist changed.
