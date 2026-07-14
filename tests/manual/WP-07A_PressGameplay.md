# WP-07A Authoritative Press Gameplay Manual Tests

## Preconditions

- Build with `rojo build default.project.json --output /tmp/LCA-WP07A.rbxlx`.
- Use an isolated Studio place with confirmed PressCore, PressFeedback, DataSync, and QuestSync RemoteEvents.
- Use the WP-06 memory-backed lifecycle; do not connect production persistence.

## GameplayService Contract

- [ ] Module exports exactly `init` and `press` and has no require-time mutation or connection.
- [ ] Missing, malformed, and extra dependencies fail before initialization; identical init no-ops and conflicting init errors.
- [ ] press rejects invalid Player, raw userId, absent session, Loading, Saving, LoadFailed, finalizing, Released, and malformed metadata/data.
- [ ] Only an exact Loaded Player/session can mutate.
- [ ] No session wrapper, data table, revision metadata, or unknown field is returned.

## Reward Calculation

- [ ] Server derives ClickPower through UpgradeDefinitions from server-owned UpgradeLevels and Rebirths.
- [ ] Reward applies `max(1, floor(ClickPower))` before every cap and mutation.
- [ ] Reward caps at Config.Security.MaxRewardPerPress.
- [ ] Baseline ClickPower yields reward 1.
- [ ] Fractions floor before the minimum/cap; zero ClickPower still yields 1.
- [ ] NaN, infinities, negative ClickPower, invalid caps, or malformed live fields fail without mutation.
- [ ] Client cannot supply reward, ClickPower, levels, rebirths, rarity, balances, or caps.

## Mutation and Revision Flow

- [ ] Successful press mutates exactly Energy, LifetimeEnergy, and TotalPresses.
- [ ] Energy and LifetimeEnergy saturate independently at Config.Security.MaxEnergy.
- [ ] TotalPresses saturates at the technical safe-integer limit.
- [ ] A valid press at saturated Energy still advances TotalPresses until its cap.
- [ ] markDirty is called exactly once after mutation and revision increments exactly once.
- [ ] markDirty failure restores all three old values and returns DIRTY_FAILED.
- [ ] Failed requests never dirty, sync, or produce feedback.
- [ ] DataSync is requested only after dirty success.
- [ ] DataSync failure does not roll back a valid dirty mutation and is exposed only as syncSucceeded=false.

## Remote Controller and Rate Limit

- [ ] Controller exports only init and owns exactly one PressCore OnServerEvent connection.
- [ ] Main validates exact PressCore and PressFeedback RemoteEvents before lifecycle initialization.
- [ ] Zero payload arguments are accepted; every extra argument, including an explicit nil, is rejected.
- [ ] Sliding one-second limit uses server os.clock and Config.MaxPressesPerSecond.
- [ ] Requests below the limit pass, the request at the limit is rejected, and expired timestamps are pruned.
- [ ] Limits are isolated per exact Player and stored with weak Player keys.
- [ ] Rate rejection does not mutate, dirty, sync, or feedback.

## PressFeedback Contract

- [ ] Every successful press sends exactly four fields: reward, rarityName, rarityColor, rarityIndex.
- [ ] reward equals the authoritative GameplayService result.
- [ ] rarityName is always `COMMON`.
- [ ] rarityColor equals Config.LuckRarities[1].color.
- [ ] rarityIndex is always 1.
- [ ] No path relies on recovered client defaults.
- [ ] No luck roll, History, rarity counter, or RarityBroadcast occurs.

## Integration and Exclusions

- [ ] New player loads, presses, receives DataSync and PressFeedback, finalizes to memory, and same-server rejoin loads the snapshot.
- [ ] BuyUpgrade, RequestRebirth, claims, QuestAction, and other gameplay remotes have no WP-07A listeners.
- [ ] PlayerDataService, EnergyService, FactoryService, and recovered SecurityService remain inactive.
- [ ] ServerDataService, SessionRepository, lifecycle/persistence modules, shared modules, recovered files, client, and project mapping are unchanged.
- [ ] No DataStore, autosave, retry, lease, upgrade, rebirth, claim, factory, quest, luck, reward-roll, or monetization implementation exists.
- [ ] Only the WP-07A allowlist changed; `git diff --check` and Rojo build pass.
