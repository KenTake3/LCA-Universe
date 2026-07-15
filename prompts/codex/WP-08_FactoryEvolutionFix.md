# WP-08 — FactoryEvolution Integration Refresh

## Mission and Recommended Slice

Refresh the recovered FactoryEvolution plan against the completed WP-04, WP-06, WP-07A, and WP-07B architecture. The recovered script is valuable evidence but must not be activated as-is.

The smallest safe Phase B slice is **press-triggered canonical data progression only**:

- extend the existing non-yielding `GameplayService.press` transaction;
- calculate the eligible stage from the post-press LifetimeEnergy and current Rebirths;
- when eligibility exceeds HighestFactoryStage, set both FactoryStage and HighestFactoryStage to that stage;
- include both fields in the existing rollback;
- retain exactly one `markDirty` call and one DataSync attempt for the whole press transaction.

Do not port the recovered polling loop, lifecycle handlers, Workspace mutations, global server stage, or FactoryEvolutionSync in this slice. WP-07C is deferred, so rebirth-triggered progression is also deferred.

## 1. Current Incompatibilities Between Recovered FactoryEvolution and Canonical Services

### Module and location incompatibilities

- Recovered source requires `ReplicatedStorage.Shared.Config` and `.FactoryDefinitions`; current Rojo modules are under `ReplicatedStorage.LCA_Shared`.
- It requires `ServerStorage.SessionManager` and `ServerStorage.ServerDataService`; canonical modules are Rojo-mapped under `ServerScriptService` services and composed by `Main.server.lua`.
- `recovery/studio/FactoryEvolution.server.lua` is a reference artifact, not active Rojo runtime source.

### Session contract incompatibilities

- Calls `SessionManager.getSession(player.UserId)` instead of `SessionRepository.getSession(player)`.
- Reads `session.DataState` instead of `session.state`.
- Reads/writes `session.Data` instead of `session.data`.
- Does not enforce exact Player-object ownership, userId match, save/finalize flags, or revision metadata invariants.
- Iterates active players and performs userId-based session lookup, which canonical public APIs intentionally reject.

### Mutation and synchronization incompatibilities

- Writes FactoryStage and HighestFactoryStage without calling `ServerDataService.markDirty`.
- Calls sync after mutation even though the mutation is not revision-owned; a save may omit it.
- Has no rollback if dirty marking or synchronization fails.
- Periodic checks can repeatedly inspect malformed/live state without deterministic result codes.
- Stage mutation is separate from the press mutation that changed LifetimeEnergy, creating avoidable transaction and sync races.

### Lifecycle and ownership incompatibilities

- Connects PlayerAdded and PlayerRemoving despite DataLifecycleService being the sole canonical lifecycle owner.
- Starts require-time tasks, delays, connections, Workspace mutation, and initial broadcasts, violating current side-effect/injection conventions.
- Uses fixed delays as a proxy for load completion instead of explicit Loaded session state.
- Its infinite two-second loop duplicates event-driven trigger opportunities.

### Visual and global-stage incompatibilities

- Assumes Workspace.FactoryEvolution.Stage1..Stage6 and Interactive.EnergyCore hierarchy without current validation.
- Overwrites authored BasePart/Decal/Texture transparency rather than preserving original values.
- Applies shared Workspace visuals from the maximum active players' HighestFactoryStage; the intended multiplayer semantics remain unapproved.
- Fires FactoryEvolutionSync directly and owns two payload shapes without injection or active-client contract validation.
- Resets the visual server stage to 1 at startup before loaded sessions are reconciled.

## 2. Exact API Replacements Required

If any recovered logic is translated, replace contracts as follows:

```text
ReplicatedStorage.Shared.FactoryDefinitions
  → ReplicatedStorage.LCA_Shared.FactoryDefinitions

SessionManager.getSession(player.UserId)
  → SessionRepository.getSession(player)

session.DataState
  → session.state

session.Data
  → session.data

direct untracked mutation
  → mutation inside an approved transaction followed by
    ServerDataService.markDirty(player)

direct ServerStorage require/discovery
  → composition-root injection, or direct shared definition require where
    no runtime dependency is needed
```

For the recommended minimum slice, do not create a translated standalone FactoryEvolution script. Add:

```lua
local FactoryDefinitions = require(game.ReplicatedStorage.LCA_Shared.FactoryDefinitions)
```

to GameplayService and use its existing injected SessionRepository/ServerDataService transaction boundary. Main.server requires no change for this slice.

## 3. Session API Migration Table

| Recovered access | Canonical replacement | Required validation/behavior |
| --- | --- | --- |
| `getSession(player.UserId)` | `sessions.getSession(player)` | Player only; exact object identity enforced by repository. |
| `session.DataState` | `session.state` | Must equal `Loaded`; Saving/finalizing/load failure/released fail closed. |
| `session.Data` | `session.data` | Trusted server wrapper only; never expose to client. |
| `data.LifetimeEnergy` | `session.data.LifetimeEnergy` | Finite canonical non-negative integer within MaxEnergy. |
| `data.Rebirths` | `session.data.Rebirths` | Finite canonical non-negative integer within MaxRebirths. |
| `data.FactoryStage` | `session.data.FactoryStage` | Finite integer in `1..#FactoryDefinitions.Stages`. |
| `data.HighestFactoryStage` | `session.data.HighestFactoryStage` | Finite integer in range and never lower than FactoryStage. |
| direct field assignment only | capture → assign → `markDirty(player)` | Roll back all fields if dirty marking fails. |
| direct `syncToClient(player)` | existing post-dirty GameplayService sync | Exactly one sync attempt for a successful press transaction. |
| `Players:GetPlayers()` + session lookup | no scan in minimum slice | Load/rebirth/global reconciliation deferred. |

The repository must remain the sole in-memory session owner. Do not add raw userId public methods or expose its sessions map.

## 4. Dirty/Revision Mutation Requirements

Stage progression is persisted gameplay state. Every actual stage increase must be covered by revision-aware dirty marking.

For the minimum press slice:

1. Capture old Energy, LifetimeEnergy, TotalPresses, FactoryStage, and HighestFactoryStage.
2. Compute all post-press values before final assignment where practical.
3. Assign the three existing press fields.
4. If the calculated eligible stage is greater than old HighestFactoryStage, assign both stage fields.
5. Call `ServerDataService.markDirty(player)` exactly once for the combined transaction.
6. If dirty marking fails, restore all five captured fields exactly, whether or not a stage threshold was crossed.
7. Never write revision, savedRevision, or dirty directly.

This deliberately revises the WP-07A “exactly three persisted fields mutate” assertion only for threshold-crossing presses. Non-crossing presses still mutate exactly the original three. The Phase B review must explicitly approve and test this scoped extension.

Do not mark dirty when calculated stage is unchanged and no other gameplay mutation succeeded. Do not create a second revision for the stage change.

## 5. Factory Progression Trigger Points

### Implement in minimum slice

- **Successful PressCore transaction:** LifetimeEnergy is changed here. Calculate eligibility from the newly computed LifetimeEnergy plus current Rebirths before the existing markDirty call.

This supports direct stage skipping because FactoryDefinitions.calculateStage returns the highest eligible stage.

### Deferred trigger points

- **Initial load/rejoin reconciliation:** ServerDataService currently performs its own initial DataSync and exposes no post-load gameplay hook. Legacy/high-LifetimeEnergy data with stale stages remains unresolved until a reviewed lifecycle hook exists.
- **Rebirth success:** WP-07C mutation is intentionally deferred. Do not add a RequestRebirth listener or infer stage change.
- **Offline income/AutoPower/rewards/admin grants:** no authoritative mutation paths exist.
- **Periodic polling:** unnecessary for known event-driven mutations and intentionally excluded.
- **Upgrade purchase:** changes Energy and UpgradeLevels only; it cannot increase LifetimeEnergy or Rebirths, so it is not a progression trigger.

Future mutation services that increase LifetimeEnergy or Rebirths must invoke the same reviewed progression calculation inside their own atomic transaction.

## 6. HighestFactoryStage Behavior

HighestFactoryStage is the monotonic progression authority evidenced by recovered server/client behavior and current migration rules.

- Calculate `eligibleStage = FactoryDefinitions.calculateStage(newLifetimeEnergy, currentRebirths)`.
- Advance only when `eligibleStage > oldHighestFactoryStage`.
- On advance, set both FactoryStage and HighestFactoryStage to eligibleStage.
- Permit direct skipping to the highest eligible stage.
- Never decrease either field in the minimum slice.
- Require existing canonical invariant `HighestFactoryStage >= FactoryStage` before gameplay mutation; malformed live data fails closed rather than being repaired by GameplayService.
- If eligibleStage is below/equal to HighestFactoryStage, preserve both current fields exactly. Do not force FactoryStage up to HighestFactoryStage because selectable/current-stage semantics remain unresolved.

The client currently displays HighestFactoryStage. FactoryStage remains persisted and synchronized for recovered compatibility.

## 7. DataSync Timing

Use the existing WP-07A order:

```text
validate
→ compute press and eligible stage
→ assign combined transaction
→ markDirty exactly once
→ rollback everything on dirty failure
→ syncToClient exactly once on dirty success
→ PressFeedback
```

The single DataSync packet then contains post-press Energy/LifetimeEnergy and post-evolution FactoryStage/HighestFactoryStage together. This avoids an intermediate client packet, duplicate sync, and a second revision.

DataSync failure does not roll back an already dirty authoritative transaction. FactoryEvolutionSync is not sent in the minimum slice, so no stage-up notification is guaranteed beyond the normal UI update from DataSync.

## 8. Runtime Dependencies

Minimum slice dependencies:

- existing `GameplayService` injected SessionRepository (`getSession(player)`);
- existing injected ServerDataService (`markDirty`, `syncToClient`);
- shared immutable `ReplicatedStorage.LCA_Shared.FactoryDefinitions`;
- current canonical session fields LifetimeEnergy, Rebirths, FactoryStage, HighestFactoryStage;
- existing DataSync packet construction.

No new remote, service dependency, Main.server injection, lifecycle connection, task, Workspace lookup, or DataStore access is required.

UpgradeDefinitions is unrelated to stage eligibility, except that GameplayService already requires it for press stats. Do not combine upgrade levels with factory stage calculations.

## 9. Phase B Minimum Allowlist

Recommended Phase B allowlist:

- `prompts/codex/WP-08_FactoryEvolutionFix.md` only for approved clarification;
- `src/server/Services/GameplayService.lua`;
- `tests/manual/WP-08_FactoryEvolutionFix.md`;
- `CHANGELOG.md`.

Do not modify:

- `recovery/studio/FactoryEvolution.server.lua`;
- Main.server.lua for the minimum slice;
- ServerDataService or SessionRepository;
- FactoryDefinitions or UpgradeDefinitions;
- DataLifecycleService, persistence adapters, or legacy PlayerData/Factory services;
- client scripts, RemoteEvents, Workspace, or project mapping.

If later visual/global/load integration is authorized, it requires a separate allowlist and design review.

## 10. Manual Studio Verification Plan

### Contract and regression

- Build succeeds and modules load with no new require-time side effects.
- WP-07A press reward, three base field mutations, one dirty mark, one DataSync, and COMMON PressFeedback remain unchanged below thresholds.
- WP-07B BuyUpgrade behavior and independent rate limiter remain unchanged.
- No recovered FactoryEvolution script is enabled and no extra lifecycle/remote listener exists.

### Stage boundaries

- For each LifetimeEnergy boundary 500, 5,000, 50,000, 500,000, and 5,000,000, press from one point below and verify exact advancement at/above the boundary.
- Verify no advancement below every boundary.
- Verify direct skip to the highest eligible stage when test data starts below its eligible stage.
- With approved test fixtures for Rebirths 1/3/10, verify OR eligibility during a press without implementing rebirth mutation.
- Verify final stage remains 6 and does not overflow.

### Data invariants and atomicity

- Validate finite integer ranges for LifetimeEnergy, Rebirths, FactoryStage, and HighestFactoryStage.
- Invalid types, numeric strings, fractions, negatives, NaN, infinities, out-of-range stages, and HighestFactoryStage below FactoryStage fail closed without mutation.
- Non-crossing press leaves both stage fields unchanged.
- Crossing press sets both fields to the same eligible stage and changes no other new fields.
- Dirty marking is called exactly once on crossing and non-crossing successful presses.
- Dirty failure restores all five captured fields exactly and causes no DataSync/PressFeedback.
- DataSync failure preserves the dirty combined mutation.
- Successful crossing sends one DataSync containing consistent post-transaction values.

### Studio presentation

- Main UI stage label updates from DataSync after crossing.
- Record that no FactoryEvolutionSync notification, Workspace stage visibility, ServerStage attribute, or core recolor is expected in this slice.
- Confirm absent FactoryEvolution Workspace assets do not affect authoritative data progression.

## 11. Deferred Behavior

- Porting or enabling the recovered FactoryEvolution server script.
- FactoryEvolutionSync per-player and server-wide payloads/notifications.
- Workspace.FactoryEvolution Stage1..Stage6 visibility.
- EnergyCore CoreInner/CoreOuter recoloring.
- Global server stage and maximum-active-player semantics.
- PlayerAdded/PlayerRemoving ownership and initial loaded-session reconciliation.
- Periodic two-second scans and delay-based loading.
- Rebirth-triggered evolution while WP-07C is deferred.
- AutoPower, offline income, rewards, admin grants, or other future LifetimeEnergy triggers.
- FactoryStage selection/downgrade behavior.
- Production, storage, capacity, collection ownership, purchases, and rewards.
- DataStore, autosave, retries, and cross-server leases.
- MainGuiClient/FactoryEvolution compatibility repair beyond DataSync-visible stage fields.

## 12. Remaining Unknowns

- Whether FactoryStage is a selectable/current visual stage distinct from monotonic HighestFactoryStage.
- Whether FactoryStage should always be raised to HighestFactoryStage during reconciliation.
- Whether loaded legacy data should be automatically repaired from LifetimeEnergy/Rebirths and when that transaction should be marked dirty/synced.
- Whether server-wide visuals should use maximum active HighestFactoryStage, a fixed world state, or per-player visuals.
- Whether authored transparency/collision properties must be saved and restored rather than overwritten.
- Whether FactoryEvolutionSync payloads are still required once DataSync updates the UI.
- Whether stage-up notification should precede or follow DataSync.
- Whether stage names/thresholds, descriptions, colors, and OR progress remain final; several values are recovery/provisional contracts.
- How rebirth-triggered eligibility should be composed once WP-07C receives an authoritative mutation contract.
- How future offline/automatic energy changes trigger progression without duplicate revisions or syncs.
