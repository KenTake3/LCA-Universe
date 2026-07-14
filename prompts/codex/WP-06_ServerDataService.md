# WP-06 — Recover ServerDataService Contract

## Mission

Recover the authoritative server-side player-data orchestration contract around the salvaged in-memory `SessionManager`. This work package must separate persistence and synchronization from gameplay, preserve recovered data unless an explicit migration says otherwise, and fail closed when durable state cannot be loaded safely.

Phase A is investigation and design only. Do not implement persistence, alter runtime services, repair recovered callers, change project mapping, or enable production DataStores in this phase.

## Evidence Base

Inspected completely or at all relevant call sites:

- `recovery/studio/SessionManager.lua`
- `recovery/studio/FactoryEvolution.server.lua`
- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/SecurityService.lua`
- `docs/03_Architecture.md`
- `docs/04_Game_Economy.md`
- `docs/05_Roadmap.md`
- `docs/06_Current_System.md`
- `src/shared/Config.lua`
- `src/shared/UpgradeDefinitions.lua`
- `src/shared/FactoryDefinitions.lua`
- `src/shared/QuestDefinitions.lua`
- `src/shared/LCAConfig.lua`
- `src/server/Main.server.lua`
- `src/server/Services/PlayerDataService.lua`
- `src/server/Services/EnergyService.lua`
- `src/server/Services/FactoryService.lua`
- every current server file that reads or writes player data

The repository and available Git file history were searched for the requested persistence, lifecycle, session, migration, and schema terms. No implementation of `DataStoreService`, `GetDataStore`, `GetAsync`, `SetAsync`, `UpdateAsync`, autosave, `BindToClose`, persistence retries, or cross-server session locking was found.

## 1. Existing Data Services and Responsibilities

### Recovered `SessionManager`

An in-memory session repository keyed by `player.UserId`. It owns defaults, shallow migration, session states, dirty flags, data import/export, and main/quest sync-packet construction. It does not call DataStore APIs, connect player lifecycle events, autosave, retry, lock sessions, or fire remotes.

### Missing recovered `ServerDataService`

`FactoryEvolution.server.lua` requires `ServerStorage.ServerDataService` and calls `syncToClient(player)` after a stage change. The missing service is therefore at least the synchronization coordinator. The existing packet builders and lifecycle gaps strongly indicate that it also coordinated load/save/player lifecycle, but no implementation survives.

### Current `PlayerDataService`

A separate minimal in-memory repository keyed by `Player`. It creates only Energy, Lifetime Energy, and Factory Stage, publishes three attributes, returns raw data, and removes it on leave. It has no states, dirty tracking, migrations, persistence, sync packets, failure handling, or duplicate-user protection beyond returning an existing session for the same `Player` object.

### Current gameplay foundations

- `EnergyService` mutates current `Energy` and `LifetimeEnergy` through injected `PlayerDataService`.
- `FactoryService` reads current `LifetimeEnergy` and mutates `FactoryStage` through the same service.
- `Main.server.lua` injects `PlayerDataService` into both and calls `PlayerDataService.Init()`.

These current services are disabled through `LCAConfig.Enabled = false` for energy operations and are not a persistence implementation.

## 2. Recovered SessionManager Public API

All recovered methods take a `Player` unless stated otherwise:

| API | Behavior |
| --- | --- |
| `createSession(player)` | Unconditionally replaces `sessions[userId]` with a new `{data, state, player, dirty}` wrapper in `Loading`. |
| `getSession(player)` | Returns the wrapper keyed by `player.UserId`. |
| `getData(player)` | Returns the wrapper's live mutable `data` table or `nil`. |
| `removeSession(player)` | Deletes the wrapper immediately. |
| `getAllSessions()` | Returns the live mutable internal session map. |
| `setState(player, state)` | Writes arbitrary state; updates load attributes only for `Loaded` and `LoadFailed`. |
| `getState(player)` | Returns session state or `Loading` when absent. |
| `isLoaded(player)` | True only when a wrapper exists with state `Loaded`. |
| `isFailed(player)` | True only when state is `LoadFailed`. |
| `markDirty(player)` | Sets `dirty = true`. |
| `isDirty(player)` | Reads the dirty flag. |
| `clearDirty(player)` | Sets `dirty = false`. |
| `loadData(player, savedData)` | Migrates/adopts supplied data into an existing wrapper; does not change state. |
| `exportData(player)` | Returns the live mutable session data, not a snapshot. |
| `migrateData(data)` | Mutates and returns supplied data, or creates defaults for nil. |
| `getDefaultData()` | Returns a newly constructed recovered template. |
| `DataState()` | Returns the live local state-name table. |
| `buildSyncPacket(player)` | Builds the main client packet and calculated upgrade stats. |
| `buildQuestSyncPacket(player)` | Builds quest-domain data and achievement statistics. |

Canonical recovered wrapper keys are lowercase: `data`, `state`, `player`, and `dirty`. The map key is numeric user ID, while public lookup input is a `Player`.

## 3. Current PlayerDataService Public API

| API | Behavior |
| --- | --- |
| `CreateSession(player)` | Returns an existing raw data table for the same Player, otherwise creates the three-field template and attributes. |
| `GetSession(player)` | Returns the raw data table keyed by the Player object. |
| `RemoveSession(player)` | Deletes the raw table immediately without saving. |
| `Init()` | Creates sessions for current players and connects PlayerAdded/PlayerRemoving. |

The current service does not expose a wrapper, loaded state, user-ID key, dirty bit, migration, packet builders, export, save, or failure state. Its PascalCase method names also differ from recovered lower-camel names.

## 4. Every Current Caller and Expected Contract

| Caller | Call/data expectation | Compatibility finding |
| --- | --- | --- |
| Recovered `SecurityService` | `SessionManager.isLoaded(player)`, `isFailed(player)` and separately supplied full recovered `data` | Matches recovered player/lowercase API; cannot use current service's raw three-field data for upgrade/rebirth/reward validators. |
| Recovered `FactoryEvolution` | `getSession(player.UserId)`, wrapper `DataState`/`Data`, then `ServerDataService.syncToClient(player)` | Incompatible with recovered SessionManager input and lowercase wrapper. Its mutation also omits `markDirty`. Must not be repaired in WP-06. |
| Recovered `MainGuiClient` | Waits on `DataLoaded`; consumes flat `DataSync` matching `buildSyncPacket`; obtains but does not listen to `QuestSync` | ServerDataService must not treat the client cache as saved state. Initial sync must follow successful load. Client quest integration remains separately scoped. |
| Recovered `SessionManager.buildSyncPacket` | Calls `UpgradeDefinitions.calculateStats(UpgradeLevels, Rebirths)` | Requires the complete recovered nested schema before sync. Packet currently contains live nested table references prior to RemoteEvent serialization. |
| Current `Main.server.lua` | Injects current PlayerDataService into Energy/Factory and calls `Init()` | Has no ServerDataService wiring. Altering it is an integration change requiring explicit Phase B approval. |
| Current `EnergyService` | `GetSession(player)` returns raw data; mutates `Energy` and `LifetimeEnergy`; updates attributes | No loaded-state check or dirty marking. It cannot safely write a recovered session without an adapter or later refactor. |
| Current `FactoryService` | `GetSession(player)` returns raw data; reads LifetimeEnergy; mutates FactoryStage; updates attribute | No HighestFactoryStage, Rebirths, dirty marking, or recovered stage contract. |
| Current `PlayerDataService.Init` | Owns PlayerAdded and PlayerRemoving | Would race or duplicate a new lifecycle owner if both services are enabled. |

No other server player-data reader or writer exists in the current repository.

## 5. Complete Recovered Data Template

```lua
{
    Energy = 0,
    LifetimeEnergy = 0,
    Rebirths = 0,
    Gems = 0,

    UpgradeLevels = {
        ClickPower = 0,
        AutoPower = 0,
        CoreAmplifier = 0,
        Luck = 0,
    },

    DailyReward = { LastClaim = 0, Streak = 0 },
    PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 },
    PurchasedPerks = {},

    History = {},
    BestRarity = 0,
    BestRarityName = "None",

    FactoryStage = 1,
    HighestFactoryStage = 1,

    DailyQuests = { Date = "", Quests = {}, SessionStart = 0 },
    Achievements = { Unlocked = {}, Claimed = {} },
    Collection = { Cores = {}, Auras = {}, Titles = {}, Factories = {} },
    DailyLogin = { LastClaim = 0, CumulativeDays = 0, CurrentDay = 1 },

    TotalPresses = 0,
    TotalRarePulls = 0,
    TotalLegendaryPulls = 0,
    TotalMythicPulls = 0,
    TotalCosmicPulls = 0,
    TotalJackpotPulls = 0,
    RarityCount = { [1] = 0, [2] = 0, [3] = 0, [4] = 0,
        [5] = 0, [6] = 0, [7] = 0, [8] = 0 },

    FirstJoin = os.time(),
    DataVersion = Config.DataVersion,
}
```

`FirstJoin` must be generated only for genuinely new data and preserved thereafter. Current `Config.DataVersion = 4` is a recovery-provisional value, not proof of the production schema history.

## 6. Complete Current Data Template

```lua
{
    Energy = 0,
    LifetimeEnergy = 0,
    FactoryStage = 1,
}
```

The current `LCAConfig` supplies matching defaults and a separate `MaxEnergy = 1e18`. This template is an intentionally minimal foundation, not a superset or migration replacement for recovered player data.

## 7. Field-by-Field Schema Differences

| Field/group | Recovered | Current | Required disposition |
| --- | --- | --- | --- |
| `Energy` | Present, default 0 | Present, default 0 | Preserve; reconcile cap ownership later. |
| `LifetimeEnergy` | Present, default 0 | Present, default 0 | Preserve. |
| `FactoryStage` | Present, default 1 | Present, default 1 | Preserve numeric value. |
| `Rebirths` | Present, default 0 | Missing | Preserve/add through migration. |
| `Gems` | Present, default 0 | Missing | Preserve/add. |
| `UpgradeLevels` | Four nested IDs | Missing | Preserve/add independent nested map. |
| `DailyReward` | `LastClaim`, `Streak` | Missing | Preserve/add independent table. |
| `PlaytimeReward` | `LastClaim`, `TotalPlaytime`, `Index` | Missing | Preserve/add independent table. |
| `PurchasedPerks` | Empty map | Missing | Preserve unknown legacy entries; ownership semantics unresolved. |
| `History` | Empty array | Missing | Preserve; entry schema/limit unresolved. |
| `BestRarity` | 0 | Missing | Preserve/add. |
| `BestRarityName` | `None` | Missing | Preserve/add. |
| `HighestFactoryStage` | 1 | Missing | Preserve/add; relationship to FactoryStage unresolved. |
| `DailyQuests` | Date/Quests/SessionStart | Missing | Preserve/add independent nested tables. |
| `Achievements` | Unlocked/Claimed | Missing | Preserve/add independent maps. |
| `Collection` | Cores/Auras/Titles/Factories | Missing | Preserve/add independent maps. |
| `DailyLogin` | LastClaim/CumulativeDays/CurrentDay | Missing | Preserve/add. |
| `TotalPresses` | 0 | Missing | Preserve/add. |
| Five rarity pull totals | All default 0 | Missing | Preserve/add. |
| `RarityCount` | Slots 1..8 | Missing | Preserve/add independent array/map. |
| `FirstJoin` | New-data timestamp | Missing | Preserve valid legacy timestamp; create once for new data. |
| `DataVersion` | Config version | Missing | Preserve original during migration decisions, then advance only after successful versioned migration. |

All unknown legacy top-level and nested fields must survive round trips unless a reviewed migration explicitly removes or transforms them. The recovered removal of `UpgradeLevels.CriticalChance` and `CriticalMultiplier` is evidence of an old migration, but its version gate and safety are missing; Phase B must not repeat destructive deletion blindly.

## 8. Session Lifecycle

Recovered partial lifecycle:

1. An external owner must call `createSession(player)`.
2. Wrapper begins in `Loading` with fresh defaults.
3. External code must load persistence and call `loadData`.
4. External code must call `setState(Loaded)` or `setState(LoadFailed)`.
5. Gameplay reads/mutates live data and should mark dirty.
6. An external owner must save and remove the session.

No surviving code performs that orchestration.

Proposed canonical lifecycle:

1. One ServerDataService owns PlayerAdded, PlayerRemoving, autosave, and shutdown connections.
2. Reject a second active session for the same user in the same server before replacing anything.
3. Clear `DataLoaded` and `DataLoadFailed`; create exactly one `Loading` wrapper.
4. Acquire a cross-server session lease and load through the configured persistent adapter.
5. Deep-copy, validate, and migrate into session-owned data while retaining unknown fields.
6. Set `Loaded` and attributes only after the whole load succeeds; then send initial sync.
7. Serialize saves per user and track a mutation revision so mutations during an awaited save remain dirty.
8. On leave/shutdown, stop accepting gameplay mutations, save, release the lease, then remove the wrapper.

Additional states such as `Closing`/`Saving` may be internal to ServerDataService. Do not change the recovered public state enum without a separately reviewed SessionManager change.

## 9. Load Behavior

No authoritative original load behavior survives. Proposed safe behavior:

- ServerDataService is the only loader.
- Never accept saved state from a RemoteEvent or client argument.
- Use a configured DataStore and key builder; do not hardcode guessed production names/scopes/keys.
- Use `UpdateAsync` if acquiring a persistent session lease in the same record. The transform must reject a valid lease owned by another server and must not overwrite its data.
- Distinguish a genuinely absent record from read failure. Only absent data receives a fresh recovered template.
- Deep-copy the loaded value before migration so the session exclusively owns all nested tables.
- Validate serializability and known fields conservatively. Invalid known fields should use documented safe normalization or fail load; unknown fields should be preserved when serializable.
- Do not expose defaults as a loaded session after retries fail.
- On success: load data, record lease/version metadata outside gameplay data where possible, set state/attributes deterministically, then sync.
- On failure: set `LoadFailed`, keep `DataLoaded = false`, set `DataLoadFailed = true`, deny gameplay mutations and saving of fallback defaults, and expose a non-destructive retry/rejoin UX. Do not add generic kicking in WP-06.

The DataStore name, key format, lease duration, and retry policy require explicit approval before production enablement.

## 10. Save Behavior

No save implementation survives. Proposed safe behavior:

- Save only server-owned session data, never a client packet.
- Produce a deep snapshot and validate it before yielding to DataStore APIs.
- Prefer `UpdateAsync` for lock ownership checks and conflict-safe persisted mutation; do not use blind `SetAsync` for active player records.
- In the transform, verify the stored lease token belongs to this server/session before replacing data or releasing a lock.
- Preserve unknown legacy fields carried in the loaded snapshot. Do not rebuild persisted data from only the known template.
- Maintain per-user single-flight saving; overlapping saves must coalesce or queue.
- Capture a mutation revision with the snapshot. Clear dirty only if the saved revision still equals the current revision; otherwise leave dirty for the next save.
- Treat save success, conflict/lock loss, validation failure, throttling, and transient service failure as distinct results.
- Never clear dirty or remove the session merely because a save was attempted.
- Never grant rewards, calculate gameplay, process receipts, or mutate progress as part of saving.

Whether unchanged clean sessions need a final lease-release write is separate from whether their gameplay data is dirty.

## 11. Dirty Tracking

Recovered dirty tracking is a single boolean. It is usable for basic scheduling but unsafe across yielding saves:

1. Save snapshots data while dirty.
2. Gameplay mutates and marks dirty during `UpdateAsync`.
3. Old save succeeds and `clearDirty` erases the newer mutation signal.

Canonical orchestration needs a monotonically increasing per-session revision or generation. `markDirty` should advance it, a save captures it, and completion records only the captured revision. If current revision is newer, the session remains dirty.

Current EnergyService, FactoryService, and recovered FactoryEvolution mutate without marking dirty. WP-06 must document this incompatibility but must not repair those gameplay callers.

## 12. Autosave Behavior

No autosave loop or interval survives.

Proposed requirements:

- Use a reviewed configurable interval; no value is approved in Phase A.
- Save loaded dirty sessions only, while separately renewing leases as required.
- Stagger players to avoid request bursts.
- Respect DataStore request budgets and bounded retry/backoff.
- Never overlap saves for one user.
- Continue after individual failures and retain dirty state.
- Stop scheduling new autosaves during shutdown.
- Avoid a single unprotected infinite loop whose error permanently stops autosaving.

## 13. PlayerRemoving Behavior

Current PlayerDataService deletes data immediately and therefore cannot preserve progress. Recovered SessionManager has only `removeSession`; no caller combines it with saving.

Proposed sequence:

1. Mark the session closing so gameplay stops mutating it.
2. Run a bounded final save when loaded and changed.
3. Release the cross-server lease through a conditional `UpdateAsync`, including clean sessions if the lease is stored persistently.
4. Record/log failure without pretending success.
5. Remove in-memory state only after the bounded finalization attempt completes.

PlayerRemoving and shutdown may both run; finalization must be idempotent and single-flight.

## 14. BindToClose Behavior

No `BindToClose` handler survives.

Proposed behavior:

- Set a shutdown flag and disconnect/disable new lifecycle work.
- Snapshot loaded sessions and finalize them concurrently with a bounded worker count rather than fully sequentially.
- Reuse the same per-player single-flight save/finalize path as PlayerRemoving.
- Wait only within Roblox shutdown constraints; exact timeout/concurrency values remain unresolved.
- Do not clear sessions or dirty flags before confirmed results.
- Do not start new gameplay, reset data, or use client acknowledgements.

## 15. Migration Behavior

Recovered migration:

- returns defaults for nil;
- fills missing top-level keys;
- partially fills nested structures;
- removes `CriticalChance` and `CriticalMultiplier` without a version gate;
- overwrites `DataVersion` with current Config value regardless of source version;
- mutates the supplied table in place.

Problems:

- no ordered per-version migrations;
- no validation of source version or future-version data;
- incomplete nested repair;
- destructive legacy deletion without documented version context;
- unknown fields are retained incidentally, not by explicit policy;
- failures cannot roll back the mutated source.

Canonical migration must deep-copy first, preserve the original version for routing, run explicit idempotent steps, validate after each/at the end, retain unknown serializable fields, and advance `DataVersion` only after success. Future-version records must fail closed or enter a documented compatibility path, never be silently downgraded.

## 16. Retry and Failure Behavior

No retries or failure policy survives.

Proposed contract:

- Bounded attempts with reviewed exponential backoff and jitter for retryable DataStore failures.
- Do not retry deterministic schema/serialization errors as transient failures.
- Respect request budgets and cancellation caused by player removal/shutdown.
- Return structured internal results such as success, not-found, locked, transient-failure, invalid-data, lock-lost, and cancelled; exact representation is a Phase B design choice.
- Load exhaustion sets `LoadFailed` and never marks defaults loaded.
- Save exhaustion leaves the revision dirty and reports telemetry/logging; it does not claim durability.
- Lock conflict prevents gameplay in that server and must not steal an unexpired lease.
- Attribute state must be deterministic on every path.

Exact attempt counts, delays, lease timeouts, alerting, and player-facing failure UX are unresolved.

## 17. Nested-Table Aliasing Risks

`getDefaultData()` constructs fresh nested tables each call, so ordinary new sessions do not inherently share one static global template. However, ownership is still unsafe:

- `loadData` adopts and migrates the caller's table; the caller retains an alias to live session data.
- Passing the same saved table to two loads can alias sessions.
- `exportData`, `getData`, `getAllSessions`, and `DataState()` expose live mutable internal tables.
- Packet builders include live nested tables before remote serialization.
- `table.clone` is shallow and does not guarantee independent descendants for externally supplied or internally aliased structures.
- Migration mutates its input and can leave partial changes if later validation fails.

Phase B must use cycle-safe/depth-limited deep copies for defaults, load adoption, persistence snapshots, and packets where internal code could retain references. Reject cycles, Instances, functions, threads, userdata, non-finite numbers, and unsupported keys before DataStore writes. Every player must own independent nested tables.

## 18. Concurrency and Duplicate-Session Risks

- Recovered `createSession` silently overwrites an existing same-user wrapper, losing dirty data.
- Current sessions are keyed by Player objects, so a second Player object/user transition is not guarded by user ID.
- Current `CreateSession` only deduplicates the identical Player object.
- Two lifecycle owners could connect PlayerAdded/Removing and create/remove competing sessions.
- No cross-server lock prevents the same account loading in two servers.
- Autosave, manual save, PlayerRemoving, and BindToClose can race.
- Mutation during save can be cleared by boolean dirty tracking.
- A stale server can overwrite newer data without lease/token/revision checks.
- Immediate removal can race a pending save or sync.

Use one lifecycle owner, a user-ID registry, unique per-load lease tokens, conditional UpdateAsync transforms, per-user save mutexes, revisions, idempotent finalization, and lease expiry/renewal. Lease details remain subject to DataStore constraints and approval.

## 19. Security and Exploit Risks

- Accepting client-supplied saved tables, currencies, upgrades, quest state, timestamps, or versions.
- Marking fallback defaults loaded after a read failure, causing destructive overwrite.
- Duplicate sessions and last-writer-wins rollback/duplication.
- Blind `SetAsync` overwriting concurrent progress.
- Saving NaN/infinity, unsupported Roblox values, cycles, oversized history, or hostile legacy shapes.
- Table aliasing that permits unrelated code to mutate internal sessions.
- Missing integer/range validation for known persisted values.
- Failing to authenticate lease ownership in UpdateAsync transforms.
- Clearing dirty before confirmed durable success.
- Exposing full data or internal metadata to clients.
- Treating client sync packets as authority.
- Logging complete player records or sensitive identifiers unnecessarily.
- Allowing gameplay while load state is Loading/LoadFailed/Closing.
- Losing unknown legacy monetization/receipt metadata by rebuilding only known fields.

ServerDataService must not own reward formulas, purchases, quest completion, factory evolution, or receipt fulfillment.

## 20. Proposed Canonical ServerDataService API

The only directly recovered required method is `syncToClient(player)`. A complete orchestrator needs a small explicit API:

```lua
ServerDataService.init(dependencies?) -> ()
ServerDataService.loadPlayer(player) -> (boolean, resultCode?)
ServerDataService.savePlayer(player, reason?) -> (boolean, resultCode?)
ServerDataService.syncToClient(player) -> boolean
ServerDataService.syncQuestToClient(player) -> boolean
ServerDataService.finalizePlayer(player, reason?) -> (boolean, resultCode?)
ServerDataService.shutdown() -> ()
```

Design rules:

- `init` is idempotent and establishes exactly one lifecycle owner.
- `loadPlayer` is server-internal and never accepts client data.
- `savePlayer` serializes per user and saves snapshots only.
- `syncToClient` uses recovered `buildSyncPacket` and confirmed `DataSync`.
- `syncQuestToClient` uses `buildQuestSyncPacket` and confirmed `QuestSync`; the current client lacks a listener, so initial enabling may be deferred without changing packet shape.
- `finalizePlayer` unifies PlayerRemoving/shutdown behavior.
- `shutdown` is idempotent and invokes bounded finalization.
- Persistence adapter/store/key/retry policy should be injected or configured explicitly for tests; no guessed production identifier.
- Do not expose raw load/save transforms to remotes or clients.

Names beyond `syncToClient` are proposed, not recovered. Phase B must approve the exact public surface before implementation and avoid unnecessary generic repository abstractions.

## 21. Proposed Canonical Data Schema

Use the complete recovered template from section 5 as the canonical gameplay data schema. It is the only surviving superset and is required by recovered validators and packet builders.

Rules:

- Preserve exact PascalCase gameplay/save field names for compatibility.
- Keep session metadata (`state`, `dirty/revision`, `player`, lock token, save-in-flight, last-save result) outside persisted gameplay data unless a reviewed cross-server lease format requires reserved persisted metadata.
- Each player owns independent nested tables.
- Preserve unknown serializable legacy fields at every nesting level.
- Add missing known fields through explicit migration; do not replace a loaded record with defaults wholesale.
- Normalize known counters to finite, non-negative integers within reviewed caps where authoritative caps exist.
- Preserve `FirstJoin` and only create it for new records.
- Treat `DataVersion` as migration routing metadata; do not overwrite before successful migration.
- Keep calculated `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck` out of persisted data because `buildSyncPacket` derives them.
- Do not add gameplay fields from future roadmap currencies until their owning systems define them.

## 22. Compatibility Strategy

1. Treat recovered SessionManager's player-object/lowercase-wrapper contract as canonical recovery evidence.
2. Keep ServerDataService as orchestration around SessionManager, not a second mutable data store.
3. Do not run current PlayerDataService lifecycle alongside ServerDataService for the same players.
4. Adapt or retire current PlayerDataService only in a separately approved integration step. A temporary adapter may expose `GetSession(player)` as recovered `getData(player)`, but it must also route dirty marking and loaded-state checks; a raw alias alone is unsafe.
5. Preserve `buildSyncPacket` field names for MainGuiClient.
6. Preserve the recovered quest packet; repair client mapping later.
7. Do not repair FactoryEvolution's `player.UserId`, `DataState`, or `Data` mismatches in WP-06.
8. Do not resolve `Shared` versus `LCA_Shared` or change `default.project.json` in WP-06.
9. Avoid two signal owners. Main/server wiring changes require an explicit cutover plan and tests.
10. Keep current foundation disabled until it uses the authoritative session and persistence path safely.

## 23. Manual Test Plan

### Schema and ownership

- Verify every section 5 field/default and all required nested keys.
- Create two new players and prove every nested table is referentially independent.
- Load the same fixture twice and prove sessions cannot alias.
- Preserve unknown top-level and nested legacy fields across migration/save/reload.
- Preserve valid FirstJoin and route DataVersion through ordered migrations.
- Reject cycles, unsupported values, non-finite values, and future versions according to policy.

### Lifecycle and load

- Existing record, absent record, malformed record, future version, transient failure, retry exhaustion, and active foreign lock.
- Confirm defaults are used only for an absent record, never read failure.
- Confirm attributes for Loading, Loaded, and LoadFailed are deterministic and stale failure attributes clear on a fresh attempt.
- Confirm initial DataSync occurs only after successful load.
- Confirm gameplay cannot mutate Loading/LoadFailed sessions.
- Confirm duplicate same-user creation is rejected without overwriting the first session.

### Save and dirty revisions

- Clean session, dirty session, mutation during awaited save, concurrent save requests, serialization failure, transient failure, lock loss, and retry success.
- Confirm dirty clears only for the exact persisted revision.
- Confirm unknown fields remain intact.
- Confirm no `SetAsync` blind overwrite path exists.
- Confirm client packets and calculated stats are not persisted as authority.

### Autosave, leave, and shutdown

- Autosave only loaded dirty sessions; stagger/budget behavior; loop survives one-player failure.
- PlayerRemoving saves/releases before removal and is idempotent with shutdown.
- BindToClose finalizes multiple players concurrently within a bound.
- Failure remains observable and never reports false durability.
- No new lifecycle work starts after shutdown begins.

### Synchronization

- `syncToClient` fires only `DataSync` with exact recovered main packet.
- `syncQuestToClient` fires only `QuestSync` with exact recovered quest packet when enabled.
- Nested packet mutations in test code cannot mutate session data.
- No full session wrapper, lock metadata, dirty state, or unknown private fields reach clients.

### Security and separation

- Malformed RemoteEvent/client values cannot invoke load/save or replace state.
- No reward, purchase, quest, factory, or receipt gameplay is implemented.
- No FactoryEvolution/MainGuiClient/project-mapping change is included.
- Rojo build and allowlist checks pass.

DataStore tests must use an isolated approved test store or injected fake, never production data.

## 24. Exact Files Proposed for Phase B

Because persistence identifiers, retry/lease policy, and active SessionManager placement are unresolved, Phase B should be approved in two small gates rather than enabling guessed production persistence.

### Phase B1 — service contract and deterministic tests

Proposed allowlist:

- `src/server/Services/ServerDataService.lua`
- `tests/manual/WP-06_ServerDataService.md`
- `CHANGELOG.md`

B1 should implement the lifecycle/sync/persistence coordinator against injected dependencies or a fake adapter, with production persistence disabled until store/key/lease settings are approved. It must not change `Main.server.lua`, current PlayerDataService, recovered files, project mapping, or gameplay callers.

### Separately approved integration/cutover

Likely files, subject to a new exact allowlist after B1 review:

- an active source copy/repair of the recovered `SessionManager`
- `src/server/Main.server.lua`
- a narrow adapter or replacement for `src/server/Services/PlayerDataService.lua`
- integration tests and approved persistence configuration

Do not include EnergyService, FactoryService, FactoryEvolution, MainGuiClient, `default.project.json`, reward handlers, quest handlers, remotes, or receipt code in WP-06 B1. Caller dirty-marking and FactoryEvolution compatibility remain separate work packages.

## Phase B Approval Blockers and Unresolved Decisions

Before production persistence is enabled, approve:

- DataStore name, scope, and user key format;
- whether existing live data already uses another wrapper/envelope;
- real schema-version history and treatment of future versions;
- lease record format, duration, renewal, expiry, and lock-conflict UX;
- retry counts/backoff, autosave interval, budget thresholds, shutdown bounds;
- size/history limits and serialization policy;
- failure telemetry and player-facing behavior;
- whether `PurchasedPerks` or receipt metadata has an external authority;
- exact active location/API of SessionManager under the current Rojo layout;
- whether QuestSync should be sent before its client listener is repaired;
- final cutover/retirement strategy for current PlayerDataService.

No values for these items are `RECOVERY_PROVISIONAL` in Phase A because none has been approved even as a runtime placeholder.
