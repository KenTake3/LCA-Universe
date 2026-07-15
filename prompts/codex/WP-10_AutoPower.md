# WP-10 — Server-Authoritative Auto Power

## Approved Recovery Contract

WP-10 implements Auto Power as a server-internal domain transaction driven by one centralized Heartbeat scheduler. It does not reuse PressCore, increment TotalPresses, emit PressFeedback, or expose a client remote.

Approved recovery behavior:

- `RECOVERY_PROVISIONAL` production cadence: one second.
- Derived production: `UpgradeDefinitions.calculateStats(...).AutoPower`.
- Integer award: `math.floor(derivedAutoPower)`.
- No persisted fractional remainder.
- `reward <= 0` is a successful no-op with no dirty mark or sync.
- Five Heartbeat ticks maximum per callback; discard excess whole intervals while preserving the fractional remainder.
- Positive production saturates Energy and LifetimeEnergy at Config.Security.MaxEnergy.
- Factory eligibility uses post-tick LifetimeEnergy and current Rebirths in the same transaction.
- Exactly one markDirty call and one DataSync attempt for each state-changing tick.
- Dirty failure rolls back Energy, LifetimeEnergy, FactoryStage, and HighestFactoryStage.
- Complete saturation with no stage change is a no-op.
- Saturated Energy does not block LifetimeEnergy progression.

## Scheduler Boundary

`AutoPowerScheduler` owns exactly one RunService.Heartbeat connection and one global accumulator. It enumerates Players once for every completed interval and calls `GameplayService.applyAutoPowerTick(player)`. It never reads sessions, mutates gameplay data, sends DataSync, discovers remotes, or owns Player lifecycle events.

Initialization validates exact dependencies, no-ops for identical reinitialization, and rejects conflicting reinitialization before another connection is created. There are no per-player workers, tasks, coroutines, loops, or connections.

## Gameplay Transaction

`GameplayService.applyAutoPowerTick(player)`:

1. Validates exact Player, canonical wrapper identity, revision metadata, and Loaded/non-busy state.
2. Validates Energy, LifetimeEnergy, Rebirths, AutoPower level, and factory fields.
3. Derives AutoPower through UpgradeDefinitions and floors it.
4. Returns a no-op for non-positive reward.
5. Saturates Energy and LifetimeEnergy safely.
6. Calculates factory eligibility from post-tick LifetimeEnergy and Rebirths.
7. Advances both factory fields only for a new highest stage.
8. Returns a no-op if no authoritative field changes.
9. Assigns the four transaction fields.
10. Calls markDirty exactly once.
11. Restores all four fields if dirty marking fails.
12. Calls DataSync exactly once after dirty success.

The fresh frozen result contains `reward`, `energyAdded`, `lifetimeEnergyAdded`, and `syncSucceeded`. No session or mutable data reference is returned.

## Explicit Exclusions

No offline progression, fractional persistence, client controls, Auto Power RemoteEvent, TotalPresses mutation, PressFeedback, QuestSync/progression, rebirth gameplay, visual FactoryEvolution, FactoryEvolutionSync, production DataStore, autosave, retry, or cross-server lease is included.

Legacy FactoryEvolution, EnergyService, and PlayerDataService remain disabled and unchanged.
