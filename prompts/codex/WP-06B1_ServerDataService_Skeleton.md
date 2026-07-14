# WP-06B1 — ServerDataService Skeleton

## Status

Implementation specification for architecture review. Do not implement until this document is explicitly approved.

WP-06B1 is a non-integrated, dependency-injected ServerDataService skeleton. It establishes deterministic session orchestration, synchronization boundaries, data isolation, and revision-based dirty tracking without accessing production persistence or owning Roblox player lifecycle signals.

## Mission

Create a testable ServerDataService skeleton that:

- uses the complete recovered player-data schema through an injected session repository;
- formally adopts monotonic revision-based dirty tracking;
- preserves mutations made while a save yields;
- deep-clones imported, exported, persisted, and synchronized data;
- fails closed on invalid load/save state;
- exposes the recovered `syncToClient(player)` compatibility function;
- remains inactive until later integration injects dependencies and calls its methods.

This task does not activate persistence or replace the current PlayerDataService.

## Inputs

Read completely before implementation:

- `AGENTS.md`
- `prompts/codex/WP-06_ServerDataService.md`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/FactoryEvolution.server.lua`
- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/SecurityService.lua`
- `src/shared/Config.lua`
- `src/shared/UpgradeDefinitions.lua`
- `src/shared/FactoryDefinitions.lua`
- `src/shared/QuestDefinitions.lua`
- `src/server/Services/PlayerDataService.lua`
- `src/server/Services/EnergyService.lua`
- `src/server/Services/FactoryService.lua`
- `default.project.json`

## Allowed Files for Implementation

Create or modify only:

- `src/server/Services/ServerDataService.lua`
- `tests/manual/WP-06B1_ServerDataService_Skeleton.md`
- `CHANGELOG.md`

Do not modify this approved prompt during implementation.

## Binding Exclusions

WP-06B1 must not:

- access `DataStoreService`;
- call `GetDataStore`, `GetAsync`, `SetAsync`, `UpdateAsync`, `RemoveAsync`, or DataStore budget APIs;
- connect or handle `Players.PlayerAdded`;
- connect or handle `Players.PlayerRemoving`;
- call or register `game:BindToClose`;
- modify `src/server/Main.server.lua`;
- modify or replace `PlayerDataService`;
- modify recovered files;
- implement autosave or retry timers;
- implement cross-server leases or claim cross-server duplicate-session protection;
- resolve `Shared` versus `LCA_Shared`;
- change `default.project.json`;
- discover RemoteEvents through `game`, `ReplicatedStorage`, or Workspace;
- implement gameplay, rewards, purchases, receipts, quests, factory evolution, or client behavior;
- create generic service locators or persistence frameworks.

No production DataStore access is permitted, including a disabled code path that still imports or references DataStoreService.

## Runtime Activation Model

The module must have no side effects when required.

- It must not call `game:GetService`.
- It must not connect signals.
- It must not spawn loops or delayed tasks.
- It becomes usable only after `init(dependencies)` succeeds.
- Tests and later integration supply all session, persistence, and remote dependencies explicitly.

## Public API

Use `--!strict` and export exactly these functions:

```lua
ServerDataService.init(dependencies: Dependencies): ()
ServerDataService.loadPlayer(player: Player): (boolean, ResultCode)
ServerDataService.markDirty(player: Player): (boolean, ResultCode)
ServerDataService.savePlayer(player: Player, reason: SaveReason?): (boolean, ResultCode)
ServerDataService.syncToClient(player: Player): boolean
ServerDataService.syncQuestToClient(player: Player): boolean
ServerDataService.finalizePlayer(player: Player, reason: FinalizeReason?): (boolean, ResultCode)
```

Do not export `shutdown` in B1 because BindToClose and lifecycle ownership are excluded. Do not export user-ID overloads, raw session access, raw data access, deep-clone helpers, validation helpers, or test-reset functions.

Every public player argument accepts a `Player` only. The service may derive `player.UserId` internally but no public method accepts a number.

## Result Types

```lua
export type ResultCode =
    "OK"
    | "INVALID_PLAYER"
    | "NOT_FOUND"
    | "NOT_INITIALIZED"
    | "ALREADY_ACTIVE"
    | "NOT_LOADED"
    | "LOAD_FAILED"
    | "SAVE_FAILED"
    | "INVALID_DATA"
    | "SAVE_IN_PROGRESS"
    | "FINALIZING"
    | "RELEASED"

export type SaveReason =
    "Manual"
    | "Autosave"
    | "PlayerRemoving"
    | "Shutdown"

export type FinalizeReason =
    "PlayerRemoving"
    | "Shutdown"
```

`Autosave`, `PlayerRemoving`, and `Shutdown` are accepted reason labels for future callers and tests only. B1 must not schedule or connect any of those behaviors.

Invalid or omitted save reasons normalize to `"Manual"`. Invalid or omitted finalize reasons normalize to `"PlayerRemoving"`. Reason strings are diagnostic inputs only and must not change saved gameplay data.

State/result rules are exact:

| Function/condition | Result |
| --- | --- |
| Any operation except `init` before initialization | `false, "NOT_INITIALIZED"` or `false` for sync methods |
| Invalid/non-Player argument | `false, "INVALID_PLAYER"` or `false` for sync methods |
| `loadPlayer` with an existing non-Released same-user session | `false, "ALREADY_ACTIVE"` |
| `markDirty`/`savePlayer` with no session | `false, "NOT_FOUND"` |
| `markDirty`/`savePlayer` in Loading | `false, "NOT_LOADED"` |
| `markDirty`/`savePlayer` in LoadFailed | `false, "LOAD_FAILED"` |
| `markDirty` after finalization requested | `false, "FINALIZING"` |
| `markDirty`/`savePlayer` in Released | `false, "RELEASED"` |
| `savePlayer` while a save is in flight | `false, "SAVE_IN_PROGRESS"` |
| Clean Loaded `savePlayer` | `true, "OK"`, without adapter write |
| `finalizePlayer` with absent or Released session | `true, "RELEASED"` |
| Adapter read exception/failure | `false, "LOAD_FAILED"` |
| Adapter write exception/failure | `false, "SAVE_FAILED"` |
| Clone/schema/migration contradiction | `false, "INVALID_DATA"` |

## Dependency Contract

`init` requires one table containing exactly these dependencies:

```lua
export type Dependencies = {
    sessions: SessionRepository,
    persistence: PersistenceAdapter,
    sendDataSync: (player: Player, packet: any) -> (),
    sendQuestSync: (player: Player, packet: any) -> (),
}
```

Rules:

- Every dependency is required and must have the expected type.
- Missing or malformed dependencies cause `init` to error before storing partial configuration.
- The first valid call freezes the dependency table after copying its four fields.
- Repeating `init` with the same dependency identities is a no-op.
- Repeating `init` with different dependency identities errors.
- Dependency callbacks may yield unless a method below states otherwise.
- The service must catch dependency errors at load, save, finalize, and sync boundaries and return the documented failure result.

## Session Repository Interface

```lua
export type SessionState =
    "Loading"
    | "Loaded"
    | "LoadFailed"
    | "Saving"
    | "Released"

export type Session = {
    -- Immutable after creation
    userId: number,
    player: Player,

    -- Private mutable data owned by this session
    data: { [any]: any },

    -- Mutable lifecycle/revision metadata
    state: SessionState,
    revision: number,
    savedRevision: number,
    dirty: boolean,
    saveInFlight: boolean,
    finalizeRequested: boolean,
    lastResult: ResultCode?,
}

export type SessionRepository = {
    createSession: (player: Player) -> Session?,
    getSession: (player: Player) -> Session?,
    removeSession: (player: Player) -> boolean,
    getDefaultData: () -> { [any]: any },
    migrateData: (data: { [any]: any }) -> ({ [any]: any }?, boolean, string?),
    buildSyncPacket: (player: Player) -> { [any]: any }?,
    buildQuestSyncPacket: (player: Player) -> { [any]: any }?,
}
```

The repository is injected because no active canonical SessionManager exists under `src` and that placement/cutover is outside B1.

Repository requirements:

- Sessions are internally keyed by numeric user ID.
- Public repository methods accept `Player` only.
- `createSession` returns nil instead of overwriting an existing active same-user session.
- A new session starts in `Loading` with revision fields set to zero and all flags false.
- `migrateData` must not be trusted to preserve input ownership; ServerDataService clones before and after calling it.
- `migrateData` returns `(migratedData, changed, errorMessage)`. `changed` is true when defaults, normalization, or a version step altered the candidate. On failure it returns nil, false, and a diagnostic string.
- Packet builders may use the session, but ServerDataService clones their results before invoking send callbacks.
- ServerDataService never exports the injected repository or a Session.

## Formal Revision-Based Dirty Contract

Revision-based dirty tracking is binding and replaces boolean-only dirty semantics for WP-06B1.

Invariants:

```lua
session.revision >= 0
session.savedRevision >= 0
session.savedRevision <= session.revision
session.dirty == (session.revision > session.savedRevision)
```

All revision values are finite non-negative integers.

### markDirty

For a `Loaded` or `Saving` session that is not finalizing and has not been released:

```lua
session.revision += 1
session.dirty = true
session.lastResult = "OK"
```

`markDirty` may run while `saveInFlight == true` and state is `Saving`. In that case it still increments revision and returns `true, "OK"`, unless finalization has begun.

It fails without mutation for absent, Loading, LoadFailed, finalizing, or Released sessions.

### Save capture

Immediately before the persistence callback may yield:

```lua
local capturedRevision = session.revision
local snapshot = deepClone(session.data)
session.saveInFlight = true
session.state = "Saving"
```

### Save completion

On successful persistence:

```lua
session.savedRevision = math.max(session.savedRevision, capturedRevision)
session.dirty = session.revision > session.savedRevision
session.saveInFlight = false
session.state = "Loaded"
session.lastResult = "OK"
```

If `markDirty` ran during the yield, `session.revision > capturedRevision`, so dirty remains true.

On failed persistence:

```lua
session.dirty = session.revision > session.savedRevision
session.saveInFlight = false
session.state = "Loaded"
session.lastResult = <failure code>
```

The captured revision is not recorded as saved on failure.

A session is clean only when `savedRevision == revision`. Never clear dirty solely because a save attempt returned.

## Persistence Adapter Interface

B1 uses only an injected fake/in-memory adapter:

```lua
export type ReadResult = {
    ok: boolean,
    code: "OK" | "NOT_FOUND" | "LOAD_FAILED" | "INVALID_DATA",
    data: { [any]: any }?,
}

export type WriteResult = {
    ok: boolean,
    code: "OK" | "SAVE_FAILED" | "INVALID_DATA",
}

export type PersistenceAdapter = {
    read: (userId: number) -> ReadResult,
    write: (
        userId: number,
        snapshot: { [any]: any },
        reason: SaveReason
    ) -> WriteResult,
}
```

Both methods may yield.

- Adapter exceptions are caught and normalized to `LOAD_FAILED` or `SAVE_FAILED`.
- `NOT_FOUND` is the only result that authorizes new default data.
- `OK` reads require a table payload.
- A contradictory result is `INVALID_DATA`.
- `write` receives a deep snapshot, never live session data.
- The adapter has no DataStore, lock, lease, UpdateAsync, retry, or release semantics in B1.

## Data Isolation and Validation

Implement a small private cycle-detecting deep-clone/validation helper inside ServerDataService. Do not export it or build a general serialization framework.

Allowed persisted/synchronized value types:

- nil where structurally permitted;
- boolean;
- string;
- finite number;
- tables with supported string or finite integer keys.

Reject:

- NaN and positive/negative infinity;
- functions, threads, userdata, Instances, and unsupported Roblox datatypes;
- cyclic tables;
- non-integer numeric keys;
- table keys of unsupported types.

Required clone boundaries:

1. Clone `getDefaultData()` output before session adoption.
2. Clone adapter read data before migration.
3. Clone migrated data again before assigning `session.data`.
4. Clone `session.data` for every write snapshot.
5. Clone main and quest packets before send callbacks.

Unknown legacy fields survive when their keys and values are supported. Do not rebuild records from a known-field allowlist and do not delete unknown fields.

## Function Behavior

### init(dependencies)

- Validates and stores dependencies only.
- Creates no sessions.
- Reads no persistence.
- Sends no remotes.
- Connects no signals.
- Returns no value.

### loadPlayer(player)

1. Require successful initialization and a valid Player-like argument with finite integer `UserId`.
2. Reject an existing non-Released same-user session with `ALREADY_ACTIVE`.
3. Call `sessions.createSession(player)` and verify a valid Loading session with matching player/user ID and revision invariants.
4. Set `DataLoaded=false` and `DataLoadFailed=false` on the Player.
5. Call `persistence.read(userId)`.
6. For `NOT_FOUND`, deep-clone repository defaults.
7. For `OK`, deep-clone the returned table.
8. Call migration on the cloned candidate, retain its `changed` result, then deep-clone/validate the result.
9. On success, assign owned data and initialize revision state as follows:
   - adapter `NOT_FOUND`: `revision=1`, `savedRevision=0`, `dirty=true`;
   - existing data changed by migration: `revision=1`, `savedRevision=0`, `dirty=true`;
   - existing data unchanged by migration: `revision=0`, `savedRevision=0`, `dirty=false`.
10. Set state `Loaded` and deterministic attributes.
11. Call `syncToClient(player)` only after state becomes Loaded.
12. Return `true, "OK"` even if the send callback fails; sync failure does not convert a successfully loaded session into load failure.

On read, clone, validation, or migration failure:

- keep the session for failure inspection;
- set state `LoadFailed`;
- set `DataLoaded=false`, `DataLoadFailed=true`;
- set the corresponding result;
- never substitute defaults unless the adapter returned `NOT_FOUND`;
- return `false, <result>`.

### markDirty(player)

Implements the formal revision contract above. It never inspects or changes gameplay fields.

### savePlayer(player, reason?)

- Requires a Loaded or Saving session.
- A clean Loaded session returns `true, "OK"` without calling the adapter.
- If `saveInFlight` is already true, return `false, "SAVE_IN_PROGRESS"`; do not start a second save.
- Capture revision and a deep snapshot before the adapter yields.
- Apply the formal completion rules above.
- Never remove the session.

### syncToClient(player)

- Return false unless initialized and session state is Loaded or Saving.
- Obtain `buildSyncPacket(player)` from the repository.
- Deep-clone and validate the packet.
- Invoke `sendDataSync(player, clonedPacket)` inside a protected call.
- Return true only when packet creation, cloning, and sending succeed.
- Do not send session metadata or unknown private persisted fields outside the recovered packet builder.

### syncQuestToClient(player)

Same rules as `syncToClient`, using `buildQuestSyncPacket` and `sendQuestSync`. B1 exposes the method for contract testing but calls it nowhere automatically.

### finalizePlayer(player, reason?)

- Requires initialization.
- Is idempotent for Released/absent sessions: return `true, "RELEASED"`.
- Set `finalizeRequested=true` before any yield.
- If a save is already in flight, return `false, "SAVE_IN_PROGRESS"`; the caller may retry. B1 must not poll, wait, or spawn tasks.
- If Loaded and dirty, perform one synchronous `savePlayer` call using the normalized finalization reason.
- After the bounded single attempt, set state `Released` and call `sessions.removeSession(player)`.
- Return the save result. If saving failed, removal still occurs because B1 has no lifecycle retry owner; the failure must remain observable to the caller.
- LoadFailed sessions are released without attempting to save fallback data.
- No adapter lease-release operation exists.

## State Transitions

```text
Absent --loadPlayer--> Loading

Loading --read/migrate succeeds--> Loaded
Loading --read/migrate fails--> LoadFailed

Loaded --dirty save begins--> Saving
Loaded --clean finalize--> Released
Loaded --dirty finalize/save succeeds--> Saving --> Released
Loaded --dirty finalize/save fails--> Saving --> Released

Saving --save succeeds and not finalizing--> Loaded
Saving --save fails and not finalizing--> Loaded

LoadFailed --finalizePlayer--> Released
Released --no transition--> Released
```

No direct Absent-to-Loaded transition is permitted. No defaults may be installed after a failed read.

## Player Attributes

`loadPlayer` owns only:

- `DataLoaded`
- `DataLoadFailed`

Deterministic values:

| State | DataLoaded | DataLoadFailed |
| --- | --- | --- |
| Loading | false | false |
| Loaded/Saving | true | false |
| LoadFailed | false | true |
| Released | false | preserve last failure only until removal |

B1 must not create LCA Energy, LifetimeEnergy, FactoryStage, or other gameplay attributes.

## Canonical Data Schema

The repository default/migration dependency must use the complete recovered schema documented in `WP-06_ServerDataService.md`, including:

- Energy, LifetimeEnergy, Rebirths, Gems;
- four UpgradeLevels;
- DailyReward, PlaytimeReward, PurchasedPerks;
- History, BestRarity, BestRarityName;
- FactoryStage and HighestFactoryStage;
- DailyQuests, Achievements, Collection, DailyLogin;
- all lifetime press/rarity counters and eight RarityCount slots;
- FirstJoin and DataVersion.

B1 ServerDataService must not duplicate this template internally. It obtains defaults and migration from the injected repository, then enforces cloning and ownership.

`FirstJoin` and `DataVersion` behavior remains the repository/migration contract:

- create FirstJoin only for genuinely absent data;
- preserve an existing valid FirstJoin;
- inspect source DataVersion before migration;
- advance DataVersion only after successful ordered migration;
- retain supported unknown legacy fields.

## Manual Test Document Requirements

Create `tests/manual/WP-06B1_ServerDataService_Skeleton.md` covering:

### Module isolation

- require has no side effects;
- no `game:GetService`, signals, tasks, timers, or DataStore references;
- invalid dependencies fail atomically;
- identical init is idempotent and conflicting init fails.

### Load

- uninitialized call;
- absent record/default success;
- existing record success;
- duplicate same-user rejection;
- adapter error/throw;
- malformed adapter results;
- invalid/cyclic/non-finite data;
- migration failure;
- deterministic attributes;
- initial DataSync ordering;
- sync failure does not corrupt successful load;
- no defaults after read failure.

### Revision/dirty behavior

- absent/default data starts at revision 1, savedRevision 0, and dirty;
- unchanged existing data starts at revision/savedRevision zero and clean;
- migration-changed existing data starts at revision 1, savedRevision 0, and dirty;
- repeated markDirty increments monotonically;
- markDirty rejection by state;
- clean save skips adapter;
- dirty save captures exact revision;
- mutation during yielding write remains dirty;
- successful unchanged save becomes clean;
- failed save stays dirty;
- concurrent save rejection;
- invariants hold after every transition.

### Data isolation

- independent defaults for two sessions;
- same loaded fixture cannot alias sessions;
- adapter cannot mutate live data after read;
- adapter write receives a detached snapshot;
- mutation of sync packet cannot mutate session data;
- unknown supported fields survive load/migrate/write;
- cycles and unsupported values fail closed.

### Sync

- exact main packet callback;
- exact quest packet callback;
- no automatic QuestSync;
- wrong state, nil packet, invalid packet, and callback error return false;
- no internal metadata leaks.

### Finalization

- clean Loaded release;
- dirty save then release;
- failed final save remains observable and still releases;
- LoadFailed release without write;
- existing in-flight save returns SAVE_IN_PROGRESS;
- absent/released idempotence;
- no signals, retries, task spawning, or lease release.

### Explicit exclusion checks

- no DataStoreService or DataStore method names in runtime source;
- no PlayerAdded, PlayerRemoving, or BindToClose references;
- `Main.server.lua` unchanged;
- PlayerDataService and all gameplay/recovered files unchanged;
- no project mapping change;
- Rojo build succeeds.

## Changelog

Add one Unreleased entry stating that a dependency-injected ServerDataService skeleton and revision-safe dirty-state contract were added, while production persistence and lifecycle integration remain disabled/deferred.

Do not claim that DataStore saving, autosave, shutdown saving, or cross-server locking is implemented.

## Validation Commands

Run:

- `git diff --check`
- `rojo build default.project.json --output /tmp/LCA-WP06B1.rbxlx`
- `git diff --stat`
- `git status --short`

Confirm that the only implementation changes are the three files in the allowlist. The already approved specification prompt is an input, not an implementation change.

Do not commit or push.

## Architecture Review Checklist

- [ ] Scope is a non-integrated skeleton, not production persistence.
- [ ] Revision-based dirty tracking is the formal source of truth.
- [ ] Mutations during yielding saves remain dirty.
- [ ] DataStore and cross-server leases are absent.
- [ ] PlayerAdded, PlayerRemoving, and BindToClose are absent.
- [ ] `Main.server.lua` is unchanged.
- [ ] No lifecycle signals or loops are registered.
- [ ] Session repository and persistence are injected.
- [ ] Public APIs accept Player only.
- [ ] No live session/data table is exported.
- [ ] All clone boundaries are explicit.
- [ ] Unknown supported legacy fields are preserved.
- [ ] Final-save failure remains observable.
- [ ] FactoryEvolution, MainGuiClient, project mapping, and gameplay are deferred.

## Deferred Work

After B1 review, separate authorization is required for:

- active canonical SessionManager placement/implementation;
- revision-aware mutation integration in gameplay services;
- DataStore adapter and production identifiers;
- UpdateAsync concurrency/lease design;
- retry, autosave, request-budget, PlayerRemoving, and BindToClose orchestration;
- `Main.server.lua` cutover and current PlayerDataService retirement;
- RemoteEvent discovery/wiring in the active Studio hierarchy;
- QuestSync client support;
- FactoryEvolution and MainGuiClient repairs;
- Shared/LCA_Shared path integration.
