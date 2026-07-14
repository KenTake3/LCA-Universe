# WP-06B1 ServerDataService Skeleton Manual Tests

## Preconditions

- Build with `rojo build default.project.json --output /tmp/LCA-WP06B1.rbxlx`.
- Use an isolated Studio test place with real test Players.
- Inject a purpose-built in-memory SessionRepository, persistence adapter, and sync callbacks.
- Do not connect the test harness to production DataStores or live gameplay remotes.
- Clone the ModuleScript per initialization-isolation test because Roblox caches `require` results.

## Module Isolation and Public Contract

- [ ] Requiring the module has no side effects.
- [ ] The module exports exactly `init`, `loadPlayer`, `markDirty`, `savePlayer`, `syncToClient`, `syncQuestToClient`, and `finalizePlayer`.
- [ ] Runtime source has no `game:GetService`, task spawning, timers, signal connections, or service discovery.
- [ ] Calls before initialization return `NOT_INITIALIZED`, or false for sync methods.
- [ ] Non-Player arguments return `INVALID_PLAYER`, or false for sync methods.
- [ ] Missing, malformed, or extra dependency keys make `init` fail before retaining partial state.
- [ ] Repeating `init` with identical dependency identities is a no-op.
- [ ] Repeating `init` with different dependencies fails.
- [ ] No repository, adapter, Session, raw data, or helper function is exported.

## New and Existing Loads

- [ ] Adapter `NOT_FOUND` installs cloned defaults as Loaded.
- [ ] New data starts with `revision=1`, `savedRevision=0`, and derived dirty true.
- [ ] Existing unchanged data starts with `revision=0`, `savedRevision=0`, and dirty false.
- [ ] Existing migration-changed data starts with `revision=1`, `savedRevision=0`, and dirty true.
- [ ] Successful load sets `DataLoaded=true` and `DataLoadFailed=false`.
- [ ] Initial DataSync occurs only after state becomes Loaded.
- [ ] Initial sync failure does not convert a successful load into LoadFailed.
- [ ] A second active session for the same UserId returns `ALREADY_ACTIVE` and leaves the first session unchanged.
- [ ] A released repository entry is removed before a replacement session is created.

## Fail-Closed Loading

- [ ] Adapter throw or explicit load failure returns `LOAD_FAILED`.
- [ ] Malformed or contradictory adapter results return `INVALID_DATA`.
- [ ] Adapter `OK` without table data returns `INVALID_DATA`.
- [ ] Migration failure, malformed changed flag, or invalid result returns `INVALID_DATA`.
- [ ] Failure leaves state LoadFailed, `DataLoaded=false`, and `DataLoadFailed=true`.
- [ ] A read failure never installs or marks fallback defaults Loaded.
- [ ] LoadFailed data cannot be saved, dirtied, or synchronized.

## Revision-Based Dirty Tracking

- [ ] Dirty always equals `revision > savedRevision`.
- [ ] Every successful `markDirty` increments revision by exactly one.
- [ ] Repeated `markDirty` calls are monotonic and never change savedRevision.
- [ ] `markDirty` works while a save is yielding unless finalization has begun.
- [ ] Loading, LoadFailed, finalizing, Released, absent, and invalid sessions reject `markDirty` deterministically.
- [ ] Revisions reject negative, fractional, non-finite, inconsistent, and unsafe-integer values.
- [ ] Revision and savedRevision never decrease.
- [ ] The compatibility `dirty` boolean is only a mirror of revision comparison.

## Save Success and Failure

- [ ] A clean Loaded save returns `OK` without calling adapter write.
- [ ] A dirty save captures the current revision and passes a detached snapshot to the adapter.
- [ ] Successful save advances savedRevision to the captured revision only.
- [ ] Successful save with no intervening mutation becomes clean.
- [ ] Adapter failure or throw never advances savedRevision and leaves the session dirty.
- [ ] Malformed write results return `INVALID_DATA` and preserve dirty state.
- [ ] Save never removes a session.
- [ ] Diagnostic reason defaults to `Manual`; invalid reasons normalize to `Manual`.

## Mutation During an Awaited Save

- [ ] Pause adapter write after it receives its snapshot.
- [ ] Call `markDirty` one or more times while state is Saving.
- [ ] Resume a successful write.
- [ ] savedRevision becomes only the pre-yield captured revision.
- [ ] revision retains every later increment and dirty remains true.
- [ ] The earlier captured snapshot remains unchanged after later session mutation.

## Save Concurrency

- [ ] While adapter write is paused, a second `savePlayer` returns `SAVE_IN_PROGRESS`.
- [ ] The second call does not invoke adapter write or alter captured metadata.
- [ ] Finalization during an in-flight save marks finalization requested and returns `SAVE_IN_PROGRESS` without polling or spawning work.
- [ ] Once finalization is requested, new dirty mutations are rejected with `FINALIZING`.

## Deep-Clone Load Isolation

- [ ] Mutating adapter-returned data after load cannot change session data.
- [ ] Migration receives a clone rather than the adapter-owned table.
- [ ] Migrated output is cloned again before session assignment.
- [ ] Loading the same nested fixture for two players creates no shared nested tables.
- [ ] Default data for two players has no shared nested tables.

## Deep-Clone Save Isolation

- [ ] Adapter write receives no live session table or nested table.
- [ ] Mutating the write snapshot cannot change session data.
- [ ] Mutating session data after capture cannot change the snapshot.
- [ ] Unknown safe legacy fields and nested fields survive load, migration, and save snapshots.

## Main and Quest Sync Isolation

- [ ] Main sync runs only for Loaded or Saving sessions.
- [ ] Quest sync runs only for Loaded or Saving sessions.
- [ ] Each callback receives a detached clone of its packet-builder output.
- [ ] Callback packet mutation cannot affect builder output or session data.
- [ ] Nil, invalid, cyclic, or non-finite packets return false.
- [ ] Builder or callback errors return false without changing session state.
- [ ] No QuestSync occurs automatically during load.
- [ ] Session state, revisions, flags, repository, and unknown private fields never leak into packets.

## Unsupported Values and Depth Safety

- [ ] Reject NaN and both infinities at every clone boundary.
- [ ] Reject functions, threads, userdata, Instances, and unsupported Roblox datatypes.
- [ ] Reject cycles and unsupported table keys.
- [ ] Reject non-integer numeric keys.
- [ ] Accept safe string and finite-integer keys.
- [ ] Reject structures deeper than the internal depth limit rather than overflowing.

## Finalization

- [ ] Clean Loaded finalization removes the session without adapter write.
- [ ] Dirty Loaded finalization makes one save attempt and then removes the session.
- [ ] Failed final save remains observable in the returned result and still removes the B1 session.
- [ ] LoadFailed finalization performs no write.
- [ ] Absent or already removed session returns `RELEASED` idempotently.
- [ ] No adapter lease-release, retry, polling, task spawning, or lifecycle signal is used.

## Explicit Exclusions and Allowlist

- [ ] Runtime source contains no `DataStoreService`, `GetDataStore`, `GetAsync`, `SetAsync`, `UpdateAsync`, `RemoveAsync`, or DataStore budget access.
- [ ] Runtime source connects or handles no PlayerAdded, PlayerRemoving, or BindToClose lifecycle signal; diagnostic reason labels are not signal wiring.
- [ ] Runtime source performs no RemoteEvent lookup or ReplicatedStorage discovery.
- [ ] Runtime source contains no gameplay, reward, purchase, receipt, quest, factory, or UI logic.
- [ ] `Main.server.lua`, PlayerDataService, gameplay services, recovered files, shared modules, and project mapping are unchanged.
- [ ] Only `ServerDataService.lua`, this manual test document, and `CHANGELOG.md` changed during implementation.
