# WP-11 — Rebirth Manual Tests

## Studio validation result

Validated successfully through the Rojo-managed client and canonical server services:

- [x] Rebirth UI opens correctly.
- [x] The server-authoritative Energy cost gate works.
- [x] Rebirth succeeds at the required Energy.
- [x] Successful Rebirth resets Energy exactly to 0.
- [x] The displayed cost updates for the next Rebirth through DataSync.
- [x] Factory progression updates correctly.
- [x] ClickPower, AutoPower, CoreAmplifier, and Luck levels all reset to 0.
- [x] Auto Power stops producing Energy after its level resets to 0.
- [x] No runtime errors were observed.

## Payload and authority

- [ ] RequestRebirth accepts exactly zero arguments.
- [ ] Explicit nil, extra arguments, tables, numbers, strings, and booleans are rejected.
- [ ] No client cost, reward, multiplier, balance, level, reset list, or stage is accepted.
- [ ] Exactly one RequestRebirth listener exists.
- [ ] No new RemoteEvent or feedback RemoteEvent exists.

## State and validation

- [ ] Invalid Player, missing session, Loading, Saving, LoadFailed, Released, finalizing, and malformed wrappers fail unchanged.
- [ ] Revision, savedRevision, dirty mirror, saveInFlight, and exact Player identity are validated.
- [ ] Energy, LifetimeEnergy, Rebirths, four upgrade levels, and both Factory fields require canonical finite integers within approved caps.
- [ ] HighestFactoryStage below FactoryStage is rejected.
- [ ] Invalid MaxEnergy or MaxRebirths fails closed.
- [ ] Invalid, zero, negative, fractional, NaN, infinite, or raised Rebirth cost fails closed.
- [ ] Rebirths at MaxRebirths returns MAX_REBIRTHS without mutation.
- [x] Energy below cost is rejected by the authoritative cost gate.
- [x] Energy at the required cost is eligible.

## Approved transaction

- [x] Successful Rebirth sets Energy exactly to 0 rather than subtracting cost.
- [x] Rebirths increments and the next Rebirth cost updates through DataSync.
- [x] ClickPower, AutoPower, CoreAmplifier, and Luck upgrade levels all reset to 0.
- [ ] LifetimeEnergy and TotalPresses are preserved exactly.
- [ ] Gems, reward state, login state, quests, achievements, collections, perks, history, rarity counters, FirstJoin, and DataVersion are preserved.
- [ ] Result is fresh, frozen, scalar-only, and contains cost, newRebirths, and syncSucceeded.

## Factory progression

- [x] Factory progression updates from the post-Rebirth authoritative state.
- [ ] Rebirth thresholds 1, 3, and 10 can advance to stages 4, 5, and 6 through the OR path.
- [ ] A new eligible highest stage assigns FactoryStage and HighestFactoryStage together.
- [ ] An equal or lower eligible stage preserves both fields exactly.
- [ ] FactoryStage and HighestFactoryStage never decrease.
- [ ] No FactoryEvolutionSync, Workspace access, recoloring, or visual evolution occurs.

## Dirty, rollback, and sync

- [ ] The complete transaction is assigned before markDirty.
- [ ] markDirty is called exactly once per successful transaction.
- [ ] Dirty failure restores Energy, Rebirths, four upgrade levels, FactoryStage, and HighestFactoryStage exactly.
- [ ] Dirty failure sends no DataSync.
- [ ] Dirty success attempts DataSync exactly once.
- [ ] DataSync failure does not roll back authoritative state.
- [ ] QuestSync is never called.

## Rate and concurrency

- [ ] Rebirth uses an independent weak-key limiter with one admitted request per Player per second.
- [ ] Malformed payloads do not consume admission; valid ineligible attempts do.
- [ ] Every admitted request re-reads current Energy/Rebirths and recalculates cost.
- [ ] Press and BuyUpgrade rate buckets remain independent and unchanged.
- [ ] AutoPowerScheduler remains unchanged.
- [x] After AutoPower resets to 0, future ticks produce no Energy.
- [ ] Auto Power and Rebirth observe complete before-or-after transactions without partial state.

## Regression and exclusions

- [ ] Press, BuyUpgrade, DataLifecycleService, and Main initialization order remain valid.
- [ ] The client sends RequestRebirth with zero arguments.
- [ ] The client does not display immediate success and adds no replacement notification.
- [ ] Legacy FactoryEvolution remains disabled.
- [ ] No offline progression, DataStore, autosave, retry, lease, rewards, quests, achievements, or login behavior was added.
- [ ] Rebirth UI state updates only from the subsequent authoritative DataSync packet.
