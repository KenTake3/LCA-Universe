# WP-06B3 Data Lifecycle Integration Manual Tests

## Preconditions

- Build with `rojo build default.project.json --output /tmp/LCA-WP06B3.rbxlx`.
- Use an isolated Studio place containing the confirmed `ReplicatedStorage.Remotes.DataSync` and `QuestSync` RemoteEvents.
- Do not connect the test place to production DataStores or monetization systems.

## Composition and Remote Injection

- [ ] Main requires exactly ServerDataService, SessionRepository, MemoryPersistenceAdapter, and DataLifecycleService.
- [ ] Main no longer requires or initializes PlayerDataService, EnergyService, FactoryService, Shared/LCAConfig, or recovered scripts.
- [ ] Missing Remotes, DataSync, or QuestSync fails before DataLifecycleService initialization.
- [ ] Wrong-class DataSync or QuestSync fails before lifecycle initialization.
- [ ] Main creates no RemoteEvents and searches no alternative hierarchy.
- [ ] ServerDataService receives exactly sessions, persistence, sendDataSync, and sendQuestSync.
- [ ] DataLifecycleService receives exactly players and dataService.
- [ ] Each injected callback fires the exact RemoteEvent to the exact Player with the unchanged packet.

## Lifecycle Initialization

- [ ] Requiring DataLifecycleService has no connections or other lifecycle effects.
- [ ] First valid init registers one PlayerAdded, one PlayerRemoving, and one BindToClose callback.
- [ ] Identical repeated init is a no-op and does not enumerate existing players again.
- [ ] Conflicting repeated init errors without adding connections.
- [ ] Missing, malformed, and extra dependency fields fail before connections.
- [ ] The module exports only init and exposes no lifecycle state or reset API.

## Player Loading

- [ ] Players already present during initialization are loaded through the common guarded helper.
- [ ] A later PlayerAdded is loaded exactly once.
- [ ] Signal/enumeration overlap cannot load the same exact Player twice.
- [ ] Closing state prevents new PlayerAdded loads.
- [ ] Successful NOT_FOUND load creates canonical defaults and sends initial DataSync.
- [ ] Load failure remains fail-closed, logs only the UserId/result, and is not retried.
- [ ] Duplicate same-user load cannot overwrite the existing SessionRepository entry.

## PlayerRemoving and BindToClose

- [ ] PlayerRemoving calls finalizePlayer once with `PlayerRemoving`.
- [ ] BindToClose sets closing before finalization and calls each managed, not-yet-finalized Player with `Shutdown`.
- [ ] PlayerRemoving/BindToClose overlap never finalizes one Player twice.
- [ ] Clean, dirty-success, LoadFailed, absent, and Released B1 outcomes remain unchanged.
- [ ] Final-save failure is logged, not retried or force-removed, and leaves the B1 session Loaded and dirty.
- [ ] Shutdown uses one finite sequential pass with no polling, task spawning, delay, or unbounded wait.

## MemoryPersistenceAdapter

- [ ] Requiring the adapter creates no external effects and exports exactly read and write.
- [ ] Missing finite-integer UserId returns exact successful NOT_FOUND result.
- [ ] Successful write/read round trip returns a detached equivalent snapshot.
- [ ] Mutating the write input after write cannot alter storage.
- [ ] Mutating read output cannot alter storage or later reads.
- [ ] Invalid UserId, reason, root, cycle, depth, key, type, NaN, and both infinities return INVALID_DATA.
- [ ] Depth 32/33 boundary matches the provisional clone contract.
- [ ] No raw map, list, clear, reset, delay, failure injection, DataStore, retry, or lease API exists.
- [ ] Stored snapshots disappear on server restart by design.

## B1/B2 Integration and Exclusions

- [ ] ServerDataService loads, saves, synchronizes, and finalizes using the injected B2 repository and memory adapter.
- [ ] DataSync and QuestSync packet ownership remains detached across callbacks.
- [ ] ServerDataService.lua and SessionRepository.lua are unchanged.
- [ ] PlayerDataService owns no active session or lifecycle path.
- [ ] EnergyService and FactoryService remain inactive and unchanged.
- [ ] No DataStoreService, production persistence, autosave, retry, lease, gameplay handler, FactoryEvolution repair, MainGuiClient repair, or Shared/LCA_Shared bridge exists.
- [ ] Only the WP-06B3 Phase B allowlist changed.
- [ ] `git diff --check` and Rojo build succeed.
