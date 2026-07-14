# WP-06B3 — Data Lifecycle Integration Specification

## Mission

Integrate the approved non-production data stack into the active Rojo server entry point with exactly one player-lifecycle owner. WP-06B3 wires `ServerDataService`, `SessionRepository`, a server-local `MemoryPersistenceAdapter`, and the confirmed `DataSync`/`QuestSync` RemoteEvents. It owns PlayerAdded, startup loading of existing players, PlayerRemoving, and BindToClose.

This remains a recovery integration. It does not authorize production persistence, autosave, retries, cross-server leases, gameplay handlers, or recovered client/factory repairs.

## Evidence and Current Conflicts

- `src/server/Main.server.lua` currently requires the obsolete `ReplicatedStorage.Shared.LCAConfig`, initializes `PlayerDataService`, and injects that three-field store into `EnergyService` and `FactoryService`.
- `PlayerDataService.Init()` loads existing players and connects PlayerAdded/PlayerRemoving. Enabling it beside B3 would create two incompatible in-memory session owners.
- `EnergyService` and `FactoryService` expect `PlayerDataService.GetSession(player)` to return a raw `{Energy, LifetimeEnergy, FactoryStage}` table. `SessionRepository.getSession(player)` instead returns the canonical wrapper whose gameplay data is in `session.data`, and mutations require `ServerDataService.markDirty(player)`.
- `ServerDataService` B1 is dependency-injected and deliberately owns no lifecycle signals or RemoteEvent discovery.
- `SessionRepository` B2 satisfies B1's exact repository contract and owns canonical in-memory gameplay data.
- `DataSync` and `QuestSync` RemoteEvent instances are confirmed under `ReplicatedStorage.Remotes`. Their existence is not provisional; callback payload ownership remains server-side.
- `default.project.json` maps server source to `ServerScriptService/LCA_Server` and shared source to `ReplicatedStorage/LCA_Shared`.

## 1. Proposed Integration Graph

```text
ServerScriptService/LCA_Server/Main.server
    ├─ validates ReplicatedStorage.Remotes.DataSync
    ├─ validates ReplicatedStorage.Remotes.QuestSync
    ├─ ServerDataService.init({
    │      sessions = SessionRepository,
    │      persistence = MemoryPersistenceAdapter,
    │      sendDataSync = DataSync:FireClient callback,
    │      sendQuestSync = QuestSync:FireClient callback,
    │  })
    └─ DataLifecycleService.init({
           players = Players,
           dataService = ServerDataService,
       })

DataLifecycleService (sole lifecycle owner)
    ├─ PlayerAdded ───────────────> ServerDataService.loadPlayer
    ├─ existing Players startup ─> ServerDataService.loadPlayer
    ├─ PlayerRemoving ───────────> ServerDataService.finalizePlayer("PlayerRemoving")
    └─ BindToClose ──────────────> ServerDataService.finalizePlayer("Shutdown")

ServerDataService
    ├─ SessionRepository
    ├─ MemoryPersistenceAdapter
    ├─ DataSync callback
    └─ QuestSync callback
```

Neither lifecycle code nor Main accesses live session data directly.

## 2. Exact Source Paths

Existing runtime inputs, unchanged:

- `src/server/Services/ServerDataService.lua`
- `src/server/Services/SessionRepository.lua`

Phase B runtime additions/changes:

- `src/server/Main.server.lua` — composition root; replace obsolete foundation initialization.
- `src/server/Services/DataLifecycleService.lua` — sole lifecycle owner.
- `src/server/Services/MemoryPersistenceAdapter.lua` — non-production, server-local snapshot adapter.

Documentation/test files:

- `tests/manual/WP-06B3_DataLifecycleIntegration.md`
- `CHANGELOG.md`

Expected runtime locations:

```text
ServerScriptService/LCA_Server/Main
ServerScriptService/LCA_Server/Services/DataLifecycleService
ServerScriptService/LCA_Server/Services/MemoryPersistenceAdapter
ServerScriptService/LCA_Server/Services/ServerDataService
ServerScriptService/LCA_Server/Services/SessionRepository
```

No project mapping change is needed.

## 3. Exact Lifecycle Owner

`DataLifecycleService` is the only active owner of:

- `Players.PlayerAdded`
- startup enumeration through `Players:GetPlayers()`
- `Players.PlayerRemoving`
- `game:BindToClose`

`Main.server` composes dependencies and calls `DataLifecycleService.init` exactly once. `ServerDataService`, `SessionRepository`, and `MemoryPersistenceAdapter` remain free of lifecycle connections. `PlayerDataService.Init()` must not be called.

### DataLifecycleService public API

Export exactly:

```lua
DataLifecycleService.init(dependencies: Dependencies): ()
```

```lua
export type Dependencies = {
    players: Players,
    dataService: {
        loadPlayer: (player: Player) -> (boolean, string),
        finalizePlayer: (player: Player, reason: "PlayerRemoving" | "Shutdown") -> (boolean, string),
    },
}
```

The dependency table must contain exactly those two entries. Missing, malformed, or extra dependencies error before connections are registered.

## 4. Idempotent Lifecycle Initialization

`DataLifecycleService` keeps private initialization state.

1. Validate and copy dependencies before changing state.
2. First valid call stores dependency identities and marks initialization in progress before registering callbacks.
3. Register each signal/binding once.
4. Enumerate existing players only once.
5. A later call using the identical `players` and `dataService` identities is a no-op.
6. A later call with different identities errors and creates no additional connections.
7. The module exports no reset or disconnect API in production.

Per-player private sets prevent the PlayerAdded callback and startup enumeration from loading the same exact Player twice. Another Player object with the same UserId is ultimately rejected by SessionRepository/B1 duplicate protection.

## 5. MemoryPersistenceAdapter API

Source: `src/server/Services/MemoryPersistenceAdapter.lua`.

Export exactly the B1 persistence interface:

```lua
MemoryPersistenceAdapter.read(userId: number): ReadResult
MemoryPersistenceAdapter.write(userId: number, snapshot: { [any]: any }, reason: SaveReason): WriteResult
```

```lua
export type ReadResult = {
    ok: boolean,
    code: "OK" | "NOT_FOUND" | "LOAD_FAILED" | "INVALID_DATA",
    data: { [any]: any}?,
}

export type WriteResult = {
    ok: boolean,
    code: "OK" | "SAVE_FAILED" | "INVALID_DATA",
}
```

Behavior:

- Private snapshots are keyed by finite integer numeric UserId.
- `read` of a missing key returns `{ok=true, code="NOT_FOUND", data=nil}`.
- `read` of a present key returns `{ok=true, code="OK", data=<detached deep clone>}`.
- `write` validates and deep-clones the snapshot before replacing the private entry, then returns `{ok=true, code="OK"}`.
- Invalid UserId, reason, snapshot, unsupported value/key, non-finite number, cycle, or excessive depth returns `{ok=false, code="INVALID_DATA"}`.
- The exact accepted reasons are `Manual`, `Autosave`, `PlayerRemoving`, and `Shutdown`; B3 itself uses only the two finalization labels.
- The adapter is synchronous and non-yielding. It implements no failure injection, retry, delay, DataStore, lease, serialization envelope, external mutation API, list API, clear/reset API, or raw map export.
- It uses a private cycle-safe depth-limited clone matching B1/B2 supported values. The depth 32 limit is marked `RECOVERY_PROVISIONAL`.
- The returned module table may be frozen; the private snapshot map remains mutable.
- Data persists only for the lifetime of one server process. It is lost on shutdown and is not production persistence.

## 6. Main.server Composition Flow

`Main.server.lua` must:

1. Obtain `Players` and `ReplicatedStorage`.
2. Require `ServerDataService`, `SessionRepository`, `MemoryPersistenceAdapter`, and `DataLifecycleService` from `script.Parent.Services`.
3. Find `ReplicatedStorage.Remotes`; fail immediately with a clear configuration error if absent.
4. Obtain `DataSync` and `QuestSync`; validate that both are `RemoteEvent` instances. Do not create, rename, or search elsewhere for them.
5. Create two local callback functions:

```lua
local function sendDataSync(player: Player, packet: any)
    dataSync:FireClient(player, packet)
end

local function sendQuestSync(player: Player, packet: any)
    questSync:FireClient(player, packet)
end
```

6. Call `ServerDataService.init` with exactly the four required dependencies.
7. Call `DataLifecycleService.init` with the Players service and ServerDataService.

Dependency and RemoteEvent validation must complete before lifecycle initialization so no Player is partially managed after a composition failure.

## 7. PlayerAdded Flow

The lifecycle owner uses one private `managedPlayers` set keyed by exact Player objects.

```text
PlayerAdded(player)
    → if closing: ignore
    → if exact Player already managed: ignore
    → mark managed before calling dependency
    → ServerDataService.loadPlayer(player)
    → on success: initial DataSync is already sent by B1
    → on failure: retain managed marker; log result code; do not retry or install fallback data
```

Rules:

- No client data participates in loading.
- LoadFailed sessions remain available for `finalizePlayer` cleanup.
- `ALREADY_ACTIVE` is logged as a lifecycle conflict, not treated as success.
- B3 does not kick players or define player-facing failure UX.
- Because the memory adapter is synchronous/non-yielding, B3 does not introduce load/removal yield races. Production yielding persistence requires a later lifecycle review.

## 8. Existing-Player Startup Loading

To close the connection/enumeration race:

1. Register PlayerAdded and PlayerRemoving callbacks.
2. Register BindToClose.
3. Iterate `players:GetPlayers()` and pass every result through the same guarded PlayerAdded helper.

The managed-player guard makes a player observed by both the signal and enumeration load exactly once. Initialization itself enumerates only once.

## 9. PlayerRemoving Flow

Use a private `finalizationStarted` set keyed by exact Player.

```text
PlayerRemoving(player)
    → if finalization already started: return
    → mark finalization started before calling dependency
    → ServerDataService.finalizePlayer(player, "PlayerRemoving")
    → success: B1 removes the session
    → failure: log exact result; do not force-remove and do not retry
```

Required behavior:

- One bounded synchronous finalization attempt.
- A failed final save keeps the B1 session Loaded, dirty, and retryable by a future authorized owner, but B3 performs no automatic retry.
- LoadFailed sessions are removed by B1 without saving fallback data.
- Absent/already released sessions are idempotent success through B1's `RELEASED` result.
- The lifecycle module never calls SessionRepository directly.

## 10. BindToClose Flow

The registered callback:

1. Sets private `closing=true` before any finalization.
2. Prevents new PlayerAdded loads.
3. Iterates the private managed-player set, not only `Players:GetPlayers()`, so ownership is explicit.
4. For each Player without `finalizationStarted`, marks it and calls `ServerDataService.finalizePlayer(player, "Shutdown")`.
5. Logs failures by result code without retrying, polling, spawning tasks, or force-removing sessions.
6. Returns after the finite sequential pass.

PlayerRemoving and BindToClose may both observe a Player, but `finalizationStarted` guarantees at most one finalization attempt. Memory writes are synchronous, so no parallel save fan-out is required. Shutdown ordering across players is unspecified and must not affect correctness.

No claim of durable shutdown persistence is allowed: the memory adapter is process-local, and all snapshots disappear when the server terminates. The flow validates lifecycle behavior only.

## 11. RemoteEvent Injection Strategy

- Main is the only B3 component that resolves RemoteEvent Instances.
- Resolve exact confirmed paths `ReplicatedStorage.Remotes.DataSync` and `ReplicatedStorage.Remotes.QuestSync`.
- Validate `RemoteEvent` class before calling either init method.
- Inject closures into ServerDataService; do not inject RemoteEvent Instances themselves.
- ServerDataService remains unaware of ReplicatedStorage and remotes.
- SessionRepository remains responsible only for allowlisted packet construction.
- B1 sends initial `DataSync` after successful load. It does not automatically send QuestSync; B3 must not add an extra quest send or modify B1.
- The recovered MainGuiClient lacks a QuestSync listener, but injecting the callback is required to satisfy B1 configuration and future explicit server sync calls.
- Do not create remotes or add compatibility paths.

## 12. PlayerDataService Disposition

`src/server/Services/PlayerDataService.lua` remains physically present and unchanged but inactive.

- Remove its require and `Init()` call from Main.
- Do not adapt it, wrap it, delete it, or let it connect lifecycle signals.
- It must not coexist as an active session owner with SessionRepository.
- Retirement/deletion may occur only in a later reviewed cleanup after no callers remain.

This cutover makes SessionRepository the sole active in-memory gameplay-data owner.

## 13. EnergyService Disposition

`src/server/Services/EnergyService.lua` remains unchanged and inactive in B3.

- Main no longer requires it or calls `SetPlayerDataService`.
- Do not inject SessionRepository directly: EnergyService expects raw data, uses the obsolete Shared/LCAConfig path, updates legacy attributes, and does not call revision-aware `markDirty`.
- Its authoritative replacement/adaptation belongs to WP-07 gameplay handlers after a mutation contract is approved.

## 14. FactoryService Disposition

`src/server/Services/FactoryService.lua` remains unchanged and inactive in B3.

- Main no longer requires it or calls `SetPlayerDataService`.
- Do not inject SessionRepository directly: it expects raw data, uses an incompatible Config/stage schema, omits Rebirths/HighestFactoryStage, and does not mark revisions dirty.
- Factory gameplay integration and recovered FactoryEvolution compatibility remain separately scoped.

## 15. Initialization and Failure Policy

- Main validates every static dependency before starting lifecycle ownership.
- `ServerDataService.init` identical reinitialization is already idempotent; conflicting dependencies error.
- `DataLifecycleService.init` follows the identical/no-op and conflicting/error rule.
- Remote configuration errors stop startup before player load connections.
- Individual player load/finalize failures are logged using result code only; do not log full gameplay data.
- No fallback defaults after load failure except B1's explicit adapter `NOT_FOUND` flow.
- No kick, retry, polling, delay, task spawning, or silent force-removal policy is introduced.

## 16. Security and Ownership Decisions

- The server remains authoritative; only lifecycle callbacks call load/finalize.
- Client remotes cannot request load, save, finalize, or supply snapshots.
- Main injects server-to-client callbacks only; it adds no OnServerEvent listeners.
- Memory snapshots and session maps remain private.
- Remote packets are already detached and allowlisted by SessionRepository and cloned again by B1.
- Exact Player identity and numeric UserId duplicate protection remain enforced by SessionRepository.
- Lifecycle state sets use exact Player identity and are not exposed.
- No gameplay values, rewards, purchases, quests, or factory stages are changed by lifecycle integration.

## 17. Manual Test Plan

Create `tests/manual/WP-06B3_DataLifecycleIntegration.md` covering:

### Composition

- Exact Main requires and dependency graph.
- Missing/wrong Remotes folder, DataSync, or QuestSync fails before lifecycle initialization.
- Exactly four ServerDataService dependencies and two DataLifecycleService dependencies.
- DataSync/QuestSync callbacks call `FireClient` with the exact Player and packet.
- No RemoteEvent is created or searched outside the confirmed path.

### Idempotent lifecycle

- First init registers one PlayerAdded, one PlayerRemoving, and one BindToClose callback.
- Identical second init adds nothing and does not re-enumerate players.
- Conflicting second init errors without changing active connections.
- Signal/enumeration overlap loads an exact Player once.

### Loading

- Existing players load at startup.
- Later PlayerAdded loads once.
- Successful new memory load reaches Loaded and sends initial DataSync.
- Load failure remains fail-closed and is not retried.
- Duplicate same-user conflict is observable and does not overwrite the first session.
- Closing state prevents new loads.

### Removal and shutdown

- PlayerRemoving calls finalization exactly once with `PlayerRemoving`.
- BindToClose calls each not-yet-finalized managed Player exactly once with `Shutdown`.
- Signal/shutdown overlap does not double-finalize.
- Clean, dirty-success, LoadFailed, absent, and final-save-failure paths preserve B1 behavior.
- Failure is logged but not retried or force-removed.
- BindToClose performs no task spawn, polling, or unbounded wait.

### Memory adapter

- Missing read returns exact NOT_FOUND result.
- Write/read round trip uses detached clones.
- Caller mutations cannot change stored snapshots; returned-data mutations cannot change storage.
- Invalid IDs, reasons, roots, cycles, depth, keys, types, NaN, and infinities return INVALID_DATA.
- No raw map/reset/list API is exported.
- Server restart loses all memory data by design.

### Cutover and exclusions

- PlayerDataService.Init is not called and owns no active connections.
- EnergyService and FactoryService are not required or initialized.
- ServerDataService and SessionRepository remain unchanged.
- No DataStore API, autosave, retry, lease, gameplay handler, recovered-script repair, or compatibility bridge.
- Rojo build and `git diff --check` pass with only allowlisted files changed.

## 18. Phase B Implementation Allowlist

Modify or create only:

- `src/server/Main.server.lua`
- `src/server/Services/DataLifecycleService.lua`
- `src/server/Services/MemoryPersistenceAdapter.lua`
- `tests/manual/WP-06B3_DataLifecycleIntegration.md`
- `CHANGELOG.md`

Do not modify:

- `src/server/Services/ServerDataService.lua`
- `src/server/Services/SessionRepository.lua`
- `src/server/Services/PlayerDataService.lua`
- `src/server/Services/EnergyService.lua`
- `src/server/Services/FactoryService.lua`
- shared modules, recovered Studio files, client files, project mapping, or remotes.

The Phase A specification may be included in a later approved commit as project documentation but is not part of the Phase B runtime allowlist unless explicitly listed by the implementation request.

## 19. Explicit Exclusions

- DataStoreService and every production persistence identifier/API.
- Autosave, retry/backoff, budgets, cancellation, and cross-server leases.
- Production durability claims for PlayerRemoving or BindToClose.
- Gameplay mutation APIs and authoritative press/upgrade/rebirth/reward/quest handlers.
- Receipt and monetization processing.
- FactoryEvolution repair.
- MainGuiClient repair.
- Shared/LCA_Shared compatibility repair or default.project.json changes.
- Remote creation, discovery outside the exact confirmed paths, and OnServerEvent listeners.
- PlayerDataService, EnergyService, or FactoryService adaptation/deletion.

## 20. Unresolved Integration Concerns

- Production persistence may yield, introducing load/removal and shutdown timing races that the synchronous memory adapter cannot exercise.
- A failed final save intentionally leaves a session resident; without retries or a later owner, B3 only logs the failure.
- The process-local memory adapter makes shutdown writes non-durable and exists solely to validate orchestration.
- There is no approved player-facing LoadFailed UX.
- QuestSync is injectable but has no recovered client listener and is not automatically sent on load.
- EnergyService and FactoryService become inactive, so no current gameplay mutation path is enabled by B3.
- Exact logging facility/format is not established; use concise `warn` messages without record contents.
