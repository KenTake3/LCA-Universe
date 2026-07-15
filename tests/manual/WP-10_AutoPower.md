# WP-10 — Auto Power Manual Tests

## Studio validation result

Validated successfully using the Rojo-managed MainGuiClient integration:

- [x] Recovery Cleanup completed successfully.
- [x] MainGuiClient runs from `StarterGui/MainGui/MainGuiClient` through Rojo.
- [x] No duplicate MainGuiClient instance exists.
- [x] The player spawns and the UI displays correctly without runtime errors.
- [x] AutoPower level 0 produces no passive Energy.
- [x] Purchasing AutoPower succeeds and starts passive production.
- [x] Energy increases automatically at approximately one-second intervals.
- [x] Auto Power continues after additional ClickPower purchases.
- [x] Factory stage display updates correctly.
- [x] DataSync-driven UI remains responsive.

## Scheduler contract

- [ ] Module require has no side effects.
- [ ] First valid init creates exactly one Heartbeat connection.
- [ ] Identical init is a no-op; conflicting init errors without another connection.
- [ ] One global accumulator produces one tick per completed one-second interval.
- [ ] At most five ticks execute in one Heartbeat callback.
- [ ] Excess whole intervals are discarded and only fractional remainder retained.
- [ ] Multiple players receive independent production through the one scheduler.
- [ ] No PlayerAdded, PlayerRemoving, BindToClose, per-player loop/task/coroutine, or client RemoteEvent exists.
- [ ] Scheduler never reads sessions, marks dirty, or sends DataSync.

## Production and canonical authority

- [x] AutoPower level 0 receives no passive Energy.
- [x] Purchasing AutoPower level 1 starts passive generation.
- [x] Energy increases at approximately one-second intervals by the configured derived production.
- [ ] LifetimeEnergy increases by the same applied amount where unsaturated.
- [ ] Rebirth multiplier is applied only through UpgradeDefinitions.
- [ ] Fractional derived output is floored and no remainder is persisted.
- [ ] Client cannot start, stop, accelerate, or provide production values/timing.
- [ ] Loading, Saving, failed, finalizing, released, absent, or malformed sessions fail closed without log spam.

## Transaction boundaries

- [ ] TotalPresses never changes from Auto Power.
- [ ] No PressFeedback or other gameplay-feedback event is emitted.
- [ ] A positive state-changing tick calls markDirty exactly once.
- [x] DataSync updates the UI responsively after passive production.
- [ ] Dirty failure restores Energy, LifetimeEnergy, FactoryStage, and HighestFactoryStage exactly and causes no sync.
- [ ] Sync failure does not roll back the authoritative dirty mutation.
- [ ] Result is fresh/frozen/scalar-only with reward, applied deltas, and sync status.

## Saturation and factory progression

- [ ] Saturated Energy still allows LifetimeEnergy progression where permitted.
- [ ] Complete Energy/LifetimeEnergy saturation with no stage change causes no dirty mark or sync.
- [x] Factory stage display updates during validated passive progression.
- [ ] Direct stage skipping follows FactoryDefinitions.
- [ ] FactoryStage and HighestFactoryStage never regress.
- [ ] No new highest stage leaves both factory fields unchanged.

## Lifecycle and regression

- [ ] Leaving creates no continuing player worker or visible error.
- [ ] Rejoining does not create duplicate production.
- [ ] Existing Players before lifecycle startup load normally and later produce once Loaded.
- [ ] Press reward, TotalPresses, COMMON PressFeedback, and rate limiting remain unchanged.
- [ ] BuyUpgrade behavior remains unchanged.
- [x] Legacy FactoryEvolution remains disabled and the canonical stage display updates correctly.
- [ ] No Auto Power RemoteEvent, QuestSync, offline progression, DataStore, autosave, retry, or lease work exists.

## Approved recovery constants

- [ ] One-second cadence is recorded as approved `RECOVERY_PROVISIONAL` behavior.
- [ ] `math.floor` integer award is recorded as approved Recovery Sprint behavior.
- [ ] Five-tick Heartbeat catch-up cap is recorded as approved `RECOVERY_PROVISIONAL` safety behavior.
