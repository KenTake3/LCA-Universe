# WP-06B2 — Canonical SessionRepository Implementation Specification

## Mission and Scope

Implement the canonical, in-memory `SessionRepository` required by the approved WP-06B1 `ServerDataService` skeleton. The repository is the sole in-memory owner of player gameplay data. It does not load, save, schedule, grant rewards, or connect runtime lifecycle events.

This specification is based on the recovered `SessionManager`, the implemented B1 dependency contract, and the recovered client, security, and factory callers. It does not authorize runtime implementation during Phase A.

## 1. Exact Module Name and Proposed Source Path

- Module name: `SessionRepository`
- Proposed source: `src/server/Services/SessionRepository.lua`
- Expected Rojo location under the current project: `ServerScriptService/LCA_Server/Services/SessionRepository`
- The module uses `--!strict`.
- It may require only `Config` and `UpgradeDefinitions` from the currently mapped `ReplicatedStorage/LCA_Shared`. The proposed expressions are `require(game.ReplicatedStorage.LCA_Shared.Config)` and `require(game.ReplicatedStorage.LCA_Shared.UpgradeDefinitions)`; Phase B must verify them with `rojo build` and must not create a `Shared` compatibility bridge.
- Require-time work is limited to those deterministic shared-module requires, local constants, types, helpers, and the private empty session map. It must not connect signals, spawn tasks, discover remotes, or mutate Workspace.

## 2. Exact Public API

Export exactly these seven functions and no aliases, raw-data accessor, `getAllSessions`, state setter, dirty setter, exporter, or reset helper:

```lua
SessionRepository.createSession(player: Player): Session?
SessionRepository.getSession(player: Player): Session?
SessionRepository.removeSession(player: Player): boolean
SessionRepository.getDefaultData(): GameplayData
SessionRepository.migrateData(data: { [any]: any }): (GameplayData?, boolean, string?)
SessionRepository.buildSyncPacket(player: Player): MainSyncPacket?
SessionRepository.buildQuestSyncPacket(player: Player): QuestSyncPacket?
```

Exact returns:

- `createSession`: a newly owned live `Session`, or `nil` for invalid Player or any existing entry with the same numeric UserId. It never overwrites.
- `getSession`: the live `Session` for the exact Player/UserId pair, otherwise `nil`. Returning the live wrapper is required by B1; it is an internal dependency boundary, not a public gameplay API.
- `removeSession`: `true` only when the exact Player/UserId-owned entry existed and was removed; otherwise `false`.
- `getDefaultData`: a fresh, complete, independently owned `GameplayData` for genuinely new data.
- `migrateData`: `(ownedData, changed, nil)` on success; `(nil, false, diagnostic)` on failure. Diagnostics must not include the full record.
- packet builders: a fresh packet for a valid `Loaded` or `Saving` exact-player session, otherwise `nil`.

All Player-taking methods accept a real `Player` Instance only. Numeric UserIds are private map keys and are never accepted through the public API.

## 3. Exact Session Type

```lua
export type SessionState = "Loading" | "Loaded" | "LoadFailed" | "Saving" | "Released"

export type Session = {
    -- Identity: assigned once by createSession.
    userId: number,
    player: Player,

    -- Live repository-owned gameplay table. B1 replaces this after migration.
    data: { [any]: any },

    -- B1-owned mutable lifecycle/revision metadata.
    state: SessionState,
    revision: number,
    savedRevision: number,
    dirty: boolean,
    saveInFlight: boolean,
    finalizeRequested: boolean,
    lastResult: ResultCode?,
}
```

`userId` and `player` are immutable by contract after creation. `data` is mutable server-owned gameplay state. The repository owns storage and identity; B1 owns lifecycle/revision transitions after creation. The wrapper cannot be frozen because B1 must replace `data` and update metadata.

## 4. Exact Persisted Gameplay-Data Schema

Calculated `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck` are deliberately absent; they are derived for synchronization.

```lua
export type GameplayData = {
    Energy: number,                 -- default 0
    LifetimeEnergy: number,         -- default 0
    Rebirths: number,               -- default 0
    Gems: number,                   -- default 0

    UpgradeLevels: {
        ClickPower: number,         -- default 0
        AutoPower: number,          -- default 0
        CoreAmplifier: number,      -- default 0
        Luck: number,               -- default 0
        [any]: any,                 -- safe unknown legacy fields retained
    },

    DailyReward: { LastClaim: number, Streak: number, [any]: any },
    PlaytimeReward: { LastClaim: number, TotalPlaytime: number, Index: number, [any]: any },
    PurchasedPerks: { [any]: any },

    History: { [any]: any },
    BestRarity: number,             -- default 0
    BestRarityName: string,         -- default "None"

    FactoryStage: number,           -- default 1
    HighestFactoryStage: number,    -- default 1

    DailyQuests: { Date: string, Quests: { [any]: any }, SessionStart: number, [any]: any },
    Achievements: { Unlocked: { [any]: any }, Claimed: { [any]: any }, [any]: any },
    Collection: {
        Cores: { [any]: any },
        Auras: { [any]: any },
        Titles: { [any]: any },
        Factories: { [any]: any },
        [any]: any,
    },
    DailyLogin: { LastClaim: number, CumulativeDays: number, CurrentDay: number, [any]: any },

    TotalPresses: number,
    TotalRarePulls: number,
    TotalLegendaryPulls: number,
    TotalMythicPulls: number,
    TotalCosmicPulls: number,
    TotalJackpotPulls: number,
    RarityCount: { [number]: number, [any]: any }, -- defaults 1..8 = 0

    FirstJoin: number,
    DataVersion: number,
    [any]: any,                     -- safe unknown legacy fields retained
}
```

Default nested values are exactly:

```lua
DailyReward = { LastClaim = 0, Streak = 0 }
PlaytimeReward = { LastClaim = 0, TotalPlaytime = 0, Index = 1 }
DailyQuests = { Date = "", Quests = {}, SessionStart = 0 }
Achievements = { Unlocked = {}, Claimed = {} }
Collection = { Cores = {}, Auras = {}, Titles = {}, Factories = {} }
DailyLogin = { LastClaim = 0, CumulativeDays = 0, CurrentDay = 1 }
RarityCount = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 }
```

`History`, perk values, quest entries, achievement keys, collection entries, and unknown-field semantics remain opaque safe legacy data; WP-06B2 must not invent their gameplay schemas.

## 5. Session State Enum

The exact enum is `Loading`, `Loaded`, `LoadFailed`, `Saving`, and `Released`. `createSession` creates only `Loading`. The repository does not perform transitions. B1 validates and owns every subsequent transition.

## 6. revision / savedRevision Ownership

`createSession` initializes both to integer `0`. Thereafter only `ServerDataService` may update them. The repository must not infer a revision from data, migration, packet building, or removal and must never decrease either value.

## 7. dirty Compatibility Behavior

`dirty` exists only because B1 validates the compatibility field. It initializes false and must always mirror:

```lua
session.dirty == (session.revision > session.savedRevision)
```

It is not authoritative. The repository exposes no `markDirty`, `clearDirty`, or `isDirty` method. Packet builders do not write it.

## 8. createSession Behavior

1. Validate a real Player with a finite integer UserId.
2. Look up the private map by numeric UserId.
3. Return nil if any entry already exists, including Released, so only B1 decides when a Released entry may be removed and replaced.
4. Create an independently owned wrapper with `data = {}`, `state = "Loading"`, revisions zero, `dirty=false`, both flags false, and `lastResult=nil`.
5. Store and return that wrapper.

The empty initial data table is intentional. New versus existing persistence is unknown at creation time. Calling `getDefaultData` here would generate `FirstJoin` before B1 confirms `NOT_FOUND`.

## 9. Duplicate-Session Behavior

Sessions are keyed by `player.UserId`. A second Player object with the same UserId cannot overwrite the first. `createSession` returns nil. `getSession` and `removeSession` also require `session.player == player`, preventing a replacement Player object from observing or removing the first wrapper. Cross-server duplication is deferred to persistence leases.

## 10. getSession Behavior

For a valid Player, lookup by numeric UserId and return the live wrapper only if both stored `userId` and exact `player` identity match. Otherwise return nil. This live return is required because B1 directly assigns `session.data` and metadata; no other caller is authorized in WP-06B2.

## 11. removeSession Behavior

Validate the exact Player/UserId pair. Remove only that matching entry and return true. Missing, invalid, or identity-mismatched requests return false without mutation. The method does not save, release adapters, change Player attributes, or alter the wrapper before removal.

## 12. getDefaultData Behavior

Return a newly constructed complete schema every call, with no shared nested tables. Set `FirstJoin = os.time()` only here and `DataVersion = Config.DataVersion`. B1 calls this method only after an adapter `NOT_FOUND` result, making it the genuine-new-data creation boundary. Validate that current `Config.DataVersion` is a finite non-negative integer; invalid configuration is an implementation error and must fail rather than emit corrupt defaults.

## 13. migrateData Input/Output Contract

`migrateData(data)` accepts a candidate table already cloned by B1, but must still deep-clone it before any transformation. It never mutates caller input.

Success:

```lua
return migratedOwnedData, changed, nil
```

Failure:

```lua
return nil, false, "SHORT_DIAGNOSTIC_CODE"
```

Failure includes non-table input, unsupported/cyclic/deep data, invalid or future DataVersion, unrepairable known-field shapes, or invalid configuration. The function must not throw for record-content failures.

## 14. Migration Change Detection

Track a local `changed` flag while applying deterministic repairs. Set true when any known default is inserted, a known scalar is normalized, a known container is replaced/repaired, or `DataVersion` advances. Do not use table identity or serialization order. Unknown fields copied unchanged do not set changed. An already canonical current-version record returns `changed=false`.

No historical version-step formulas survived. WP-06B2 therefore performs an idempotent recovery normalization from supported source versions `0..Config.DataVersion`, where missing DataVersion routes as legacy version 0. This is a recovery migration, not evidence that original versions 0–3 had identical schemas.

## 15. Unknown Legacy-Field Preservation

Begin with a deep clone of the complete input and modify only known paths. Retain unknown safe fields at every nesting level. Do not repeat the recovered unconditional deletion of `CriticalChance` or `CriticalMultiplier`; their safe values survive until a versioned destructive migration is approved. Reject the whole candidate if an unknown key/value is unsupported, cyclic, non-finite, or exceeds the depth limit rather than silently dropping it.

## 16. Deep-Copy Ownership Boundaries

- Each `createSession` gets a unique wrapper and empty data table.
- Each `getDefaultData` call constructs a fully fresh nested graph.
- `migrateData` clones before modifying and returns its owned clone.
- Main and quest packet builders construct fresh outer and nested packet tables; they never return live session tables.
- B1 independently clones migration inputs/outputs, save snapshots, and callback packets. Repository cloning is defense-in-depth, not a replacement for B1 boundaries.

Use a private cycle-safe, depth-limited clone/validator compatible with B1's supported scalar/key rules. The proposed limit is exactly 32 to avoid accepting data the B1 boundary later rejects. Mark the limit `RECOVERY_PROVISIONAL`.

## 17. buildSyncPacket Contract

Return nil unless the exact Player session exists and state is `Loaded` or `Saving`. Calculate stats with:

```lua
UpgradeDefinitions.calculateStats(data.UpgradeLevels, data.Rebirths)
```

Return exactly this fresh shape:

```lua
{
    Energy = data.Energy,
    LifetimeEnergy = data.LifetimeEnergy,
    ClickPower = stats.ClickPower,
    AutoPower = stats.AutoPower,
    CoreAmplifier = stats.CoreAmplifier,
    Luck = stats.Luck,
    Rebirths = data.Rebirths,
    Gems = data.Gems,
    UpgradeLevels = deepClone(data.UpgradeLevels),
    DailyReward = deepClone(data.DailyReward),
    PlaytimeReward = deepClone(data.PlaytimeReward),
    PurchasedPerks = deepClone(data.PurchasedPerks),
    History = deepClone(data.History),
    BestRarity = data.BestRarity,
    BestRarityName = data.BestRarityName,
    FactoryStage = data.FactoryStage,
    HighestFactoryStage = data.HighestFactoryStage,
}
```

Return nil on invalid session data or cloning/stat-calculation failure. Do not expose FirstJoin, DataVersion, unknown fields, quest-domain fields, or session metadata.

## 18. buildQuestSyncPacket Contract

Return nil under the same session/state rules. Return exactly:

```lua
{
    DailyQuests = deepClone(data.DailyQuests),
    Achievements = deepClone(data.Achievements),
    Collection = deepClone(data.Collection),
    DailyLogin = deepClone(data.DailyLogin),
    Stats = {
        TotalPresses = data.TotalPresses,
        LifetimeEnergy = data.LifetimeEnergy,
        Rebirths = data.Rebirths,
        HighestFactoryStage = data.HighestFactoryStage,
        TotalRarePulls = data.TotalRarePulls,
        TotalLegendaryPulls = data.TotalLegendaryPulls,
        TotalMythicPulls = data.TotalMythicPulls,
        TotalCosmicPulls = data.TotalCosmicPulls,
        TotalJackpotPulls = data.TotalJackpotPulls,
        RarityCount = deepClone(data.RarityCount),
    },
}
```

The recovered MainGuiClient obtains `QuestSync` but has no listener, so this packet is compatibility preservation only in B2.

## 19. Packet Cloning Ownership

Every packet and descendant table is detached from session data. Mutation of a returned packet must not affect the session, a previously returned packet, or a later packet. B1 clones the returned packet again before invoking callbacks. Packet builders never mutate session data.

## 20. FirstJoin Behavior

- Genuine new record: `getDefaultData` creates one finite non-negative integer timestamp with `os.time()`.
- Existing valid record: migration preserves it exactly.
- Existing invalid FirstJoin: migration fails closed; it must not replace it with the current time.
- Existing record with no FirstJoin: preserve absence as legacy-unknown and mark no fabricated timestamp. Because the canonical type requires FirstJoin, return failure with `"MISSING_FIRST_JOIN"` until an approved provenance-aware migration exists.

This strict failure is preferable to falsely recording migration time as first join. The B1 interface does not pass an `isNew` flag to `migrateData`; new defaults already contain FirstJoin.

## 21. DataVersion Behavior

- Current target is `Config.DataVersion` (currently recovery-provisional 4).
- Require the configured target to be a finite non-negative integer.
- Missing source version is treated as legacy 0.
- Source version must otherwise be a finite non-negative integer.
- Source greater than current returns `(nil, false, "FUTURE_DATA_VERSION")`.
- Supported older/missing versions are normalized, then DataVersion is set to current only after every validation succeeds.
- Current canonical records preserve their version and can return unchanged.
- Never downgrade or overwrite the caller-owned source.

## 22. Known-Field Normalization

Normalization is deterministic and applies only to known fields:

- Missing known containers are added from fresh defaults, except FirstJoin as specified above.
- Wrong-type known containers fail closed rather than destroying potentially meaningful legacy data.
- Currency/stat counters are finite, non-negative integers. `Energy` and `LifetimeEnergy` cap at `Config.Security.MaxEnergy`; Gems at MaxGems; Rebirths at MaxRebirths; upgrade levels at the effective per-upgrade/global limits. Lifetime counters and timestamps cap at the maximum safe integer.
- Fractions floor; numeric strings are not accepted in persisted data and cause failure for known scalar fields. Booleans never coerce to numbers.
- FactoryStage and HighestFactoryStage normalize as integers clamped to `1..#FactoryDefinitions.Stages` only if FactoryDefinitions is approved as a dependency. To keep B2's dependency surface minimal, Phase B instead clamps both to recovered range `1..6`, documented as compatibility with the approved six-stage contract.
- BestRarity clamps to integer `0..#Config.LuckRarities`; BestRarityName must be a string.
- Index defaults are `PlaytimeReward.Index=1`, `DailyLogin.CurrentDay=1`; known timestamp/count fields use non-negative integers.
- RarityCount ensures indices 1..8 exist and are non-negative integers while preserving other safe unknown entries.
- Known string fields (`DailyQuests.Date`, BestRarityName) must be strings.
- Opaque History, perks, quest records, achievements, and collection entries are clone-validated but not gameplay-normalized.
- Do not enforce relationships such as HighestFactoryStage >= FactoryStage in B2; changing progression history without authoritative evidence is unsafe.

Any normalization changes set `changed=true`.

## 23. Unsupported-Value Handling

Allow nil where absence is permitted, booleans, strings, finite numbers, and tables keyed by strings or finite integers. Reject NaN, both infinities, functions, threads, userdata, Instances, Roblox datatypes, cycles, non-integer numeric keys, unsupported keys, and depth greater than 32. Fail the complete migration or packet build; never silently delete a value.

## 24. Future-Version Handling

Future DataVersion fails closed with `FUTURE_DATA_VERSION`. It is not downgraded, normalized, loaded, or replaced with defaults. ServerDataService will convert the migration failure to `INVALID_DATA` and leave the session LoadFailed. Player-facing compatibility UX and telemetry are deferred.

## 25. Compatibility with ServerDataService B1

The seven method names and return arities exactly match B1's injected `SessionRepository` type. Creation produces the exact Loading/zero-revision wrapper B1 validates. B1 remains responsible for adopting migrated data, revision initialization, state changes, dirty mirroring, saves, sync callback cloning, Player attributes, finalization, and removal.

B1 calls methods as plain functions (`repository.method(argument)`), so Phase B must not implement colon/self methods. B1 catches repository errors, but repository content errors should use the specified nil/diagnostic returns.

One approved post-review correction supersedes stale prose in the B1 prompt: a failed final save returns the session to Loaded, clears finalization, remains dirty, and does not call `removeSession`. SessionRepository requires no special behavior for that path.

## 26. Incompatibility with Recovered FactoryEvolution

Recovered FactoryEvolution is definitely incompatible:

- calls `getSession(player.UserId)` instead of `getSession(player)`;
- reads `session.DataState` instead of `session.state`;
- reads `session.Data` instead of `session.data`;
- mutates factory fields without revision-aware `ServerDataService.markDirty(player)`.

WP-06B2 must not add aliases or userId overloads to accommodate it. Repair remains WP-08.

## 27. Security Risks and Decisions

- Player validation and exact identity prevent same-user replacement objects from reading/removing sessions.
- Duplicate entries never overwrite unsaved data.
- No client data enters migration or session APIs.
- Unknown safe legacy data is retained, while unsupported structures fail closed.
- Future versions fail closed to prevent downgrade corruption.
- Packets use explicit allowlists and exclude metadata/unknown fields.
- Calculated stats are server-derived and never persisted.
- Live session access remains an internal architectural risk because B1 requires it. Only B1 and later authoritative gameplay services may receive the injected repository; integration must prohibit arbitrary consumers and require revision marking after mutations.
- No size limits exist for History or opaque legacy collections. Data-size policy remains unresolved and must be enforced before production persistence.
- Cross-server locks, durability, receipts, and monetization authority are outside this in-memory module.

## 28. Manual Test Plan

Create Phase B manual tests covering:

1. Require performs only the two specified `LCA_Shared` module requires and has no signals, tasks, DataStore, remotes, Workspace, or UI side effects.
2. Exactly seven exports; module table frozen if compatible with private mutable session storage.
3. Invalid Player and raw userId rejection for all Player methods.
4. Creation shape exactly matches B1; data table is empty and independently owned.
5. Duplicate exact Player and same-UserId/different-Player rejection without overwrite.
6. Exact-player get/remove behavior and removal idempotence.
7. Two default records share no nested tables and have complete exact fields.
8. FirstJoin created only by getDefaultData; preserved through migration; missing/invalid existing FirstJoin fails closed.
9. Current, missing, older, invalid, and future DataVersion behavior.
10. Migration does not mutate input and output cannot alias it.
11. Idempotence and exact changed flag for canonical, default-added, normalized, and version-advanced inputs.
12. Unknown safe fields survive at top-level and nested levels.
13. CriticalChance/CriticalMultiplier are not destructively removed.
14. Known scalar/container normalization and each Config cap.
15. NaN, infinities, unsupported values/keys, cycles, and depth 32/33 boundaries.
16. Main packet exact fields, calculated stats, state gating, no metadata, and no aliasing.
17. Quest packet exact fields/stats, state gating, and no aliasing.
18. Packet mutation does not affect sessions or other packets.
19. Calculated stats absent from defaults/migrated persisted data.
20. B1 integration fixture: load new, unchanged, changed, failed/future; main and quest sync; duplicate session; final-save retry preservation.
21. Static exclusions for DataStore, lifecycle events, `Main.server.lua`, PlayerDataService, remotes, Workspace, rewards, purchases, and gameplay mutations.
22. `git diff --check` and `rojo build` pass with only the Phase B allowlist changed.

## 29. Phase B Implementation Allowlist

Proposed exact allowlist:

- `src/server/Services/SessionRepository.lua`
- `tests/manual/WP-06B2_SessionRepository.md`
- `CHANGELOG.md`

The approved specification file may be committed later as project documentation but must not be edited during implementation unless separately authorized.

## 30. Explicitly Deferred Work

- DataStoreService, adapters, store names/keys, UpdateAsync, retries, budgets, and cross-server leases.
- PlayerAdded, PlayerRemoving, BindToClose, autosave, shutdown, and Main.server.lua wiring.
- PlayerDataService modification, migration, retirement, or coexistence.
- Gameplay mutation APIs, rewards, purchases, receipts, quests, factory production, and achievement logic.
- FactoryEvolution and MainGuiClient repairs.
- Shared versus LCA_Shared compatibility bridges or project mapping changes.
- RemoteEvent discovery or synchronization callback wiring.
- getAllSessions, raw userId overloads, raw data export, calculated-stat persistence, or generic repository APIs.
- Historical version-specific destructive migrations until real version history is recovered.
- Opaque History/quest/collection entry schemas, size limits, and production telemetry/UX.

## Phase B Review Decisions Required

Before implementation, approve the strict handling of existing records missing FirstJoin, the recovery normalization rules and caps, the provisional depth limit of 32, and the exact shared-module require path under the current Rojo tree. No runtime implementation should begin until those decisions are accepted.
