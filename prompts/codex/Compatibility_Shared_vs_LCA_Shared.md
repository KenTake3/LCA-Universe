# Compatibility Investigation — `Shared` vs `LCA_Shared`

## Scope and Studio Evidence

Studio reports:

```text
Config is not a valid member of Folder "ReplicatedStorage.Shared"
```

The current Rojo mapping is authoritative:

```text
src/shared/* → ReplicatedStorage/LCA_Shared/*
```

`default.project.json` does not map or create `ReplicatedStorage.Shared`. Because `$ignoreUnknownInstances` is enabled, an unrelated Studio `Shared` Folder may remain present while lacking the recovered modules. Its presence does not make it a valid compatibility location.

## Search Coverage

Repository search covered:

- `ReplicatedStorage.Shared`
- `WaitForChild("Shared")`
- `FindFirstChild("Shared")`
- `script.Parent.Shared`
- `ServerStorage.SessionManager`
- `ServerStorage.ServerDataService`
- existing `LCA_Shared` references for comparison

No `FindFirstChild("Shared")` or `script.Parent.Shared` runtime reference exists. No RemoteFunction path is involved.

## 1. Runtime-Code References

### `recovery/studio/MainGuiClient.client.lua`

Repository status: recovered-only snapshot, not Rojo-mapped. Studio evidence confirms a deployed copy is active in the current place.

| Line | Current | Required replacement | Path-only sufficient? |
| ---: | --- | --- | --- |
| 25 | `ReplicatedStorage.Shared.Config` | `ReplicatedStorage.LCA_Shared.Config` | Yes, for this require. |
| 26 | `ReplicatedStorage.Shared.NumberFormatter` | `ReplicatedStorage.LCA_Shared.NumberFormatter` | Yes. |
| 27 | `ReplicatedStorage.Shared.UpgradeDefinitions` | `ReplicatedStorage.LCA_Shared.UpgradeDefinitions` | Yes. |
| 28 | `ReplicatedStorage.Shared.FactoryDefinitions` | `ReplicatedStorage.LCA_Shared.FactoryDefinitions` | Yes. |
| 29 | `ReplicatedStorage.Shared.QuestDefinitions` | `ReplicatedStorage.LCA_Shared.QuestDefinitions` | Yes. |

Changing all five paths is sufficient to clear the reported shared-module startup failure. It is not sufficient to validate the whole client; see MainGuiClient blockers below.

### `recovery/studio/SessionManager.lua`

Repository status: recovered-only and not Rojo-mapped. Superseded by the active `SessionRepository`/`ServerDataService` stack. It must not be activated as a second session owner.

| Line | Current | Required replacement if inspected in isolation | Path-only sufficient? |
| ---: | --- | --- | --- |
| 10 | `ReplicatedStorage.Shared.Config` | `ReplicatedStorage.LCA_Shared.Config` | Yes for loading Config, but activating this module is not approved. |
| 247 | `ReplicatedStorage.Shared.UpgradeDefinitions` | `ReplicatedStorage.LCA_Shared.UpgradeDefinitions` | Yes for this lazy require only. |

No production compatibility fix should revive this module. Its API, boolean dirty model, migration, and ownership differ from the canonical B1/B2 stack.

### `recovery/studio/SecurityService.lua`

Repository status: recovered-only and not Rojo-mapped; obsolete against the canonical session API.

| Line | Current | Required canonical path | Path-only sufficient? |
| ---: | --- | --- | --- |
| 11 | `ReplicatedStorage.Shared.Config` | `ReplicatedStorage.LCA_Shared.Config` | Yes for Config only. |
| 12 | `ServerStorage.SessionManager` | `ServerScriptService.LCA_Server.Services.SessionRepository` | No. |

Replacing SessionManager with SessionRepository is not sufficient: SecurityService calls `isLoaded`, `isFailed`, and other recovered APIs that SessionRepository intentionally does not export. It also lacks canonical lifecycle-state, revision, and mutation flow support. WP-07A implemented focused validation/rate limiting without reactivating it.

### `recovery/studio/FactoryEvolution.server.lua`

Repository status: recovered-only and not Rojo-mapped. Whether the deployed Studio copy is currently enabled must be confirmed separately.

| Line | Current | Required canonical path | Path-only sufficient? |
| ---: | --- | --- | --- |
| 22 | `ReplicatedStorage.Shared.Config` | `ReplicatedStorage.LCA_Shared.Config` | Yes for Config only. |
| 23 | `ReplicatedStorage.Shared.FactoryDefinitions` | `ReplicatedStorage.LCA_Shared.FactoryDefinitions` | Yes for FactoryDefinitions only. |
| 24 | `ServerStorage.SessionManager` | `ServerScriptService.LCA_Server.Services.SessionRepository` | No. |
| 25 | `ServerStorage.ServerDataService` | `ServerScriptService.LCA_Server.Services.ServerDataService` | The path and `syncToClient(player)` API are compatible, but the script as a whole remains blocked. |

SessionRepository replacement alone fails because the script calls `getSession(player.UserId)`, reads `session.DataState` and `session.Data`, and mutates without `ServerDataService.markDirty(player)`. It also independently owns Players lifecycle callbacks and a polling loop. This remains WP-08 work, not a path-only compatibility edit.

### `src/server/Services/EnergyService.lua`

Repository status: currently Rojo-mapped ModuleScript but intentionally inactive/obsolete; Main no longer requires it.

| Line | Current | Required path if retained | Path-only sufficient? |
| ---: | --- | --- | --- |
| 6 | `ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LCAConfig")` | `ReplicatedStorage:WaitForChild("LCA_Shared"):WaitForChild("LCAConfig")` | No for safe activation. |

The path change would make the require resolve but would not fix its obsolete raw PlayerDataService contract, legacy attributes, or missing revision-aware dirty/sync flow. It should remain inactive.

### `src/server/Services/FactoryService.lua`

Repository status: currently Rojo-mapped ModuleScript but intentionally inactive/obsolete; Main no longer requires it.

| Line | Current | Required path if retained | Path-only sufficient? |
| ---: | --- | --- | --- |
| 6 | `ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LCAConfig")` | `ReplicatedStorage:WaitForChild("LCA_Shared"):WaitForChild("LCAConfig")` | No for safe activation. |

It still expects obsolete raw player data, an old factory definition shape, Energy-only progression, and no revision marking.

## 2. Correct Current Runtime References

These Rojo-mapped files already use the authoritative path and require no compatibility change:

| File | Lines | Current correct paths |
| --- | --- | --- |
| `src/server/Services/SessionRepository.lua` | 3–4 | `LCA_Shared.Config`, `LCA_Shared.UpgradeDefinitions` |
| `src/server/Services/GameplayService.lua` | 3–4 | `LCA_Shared.Config`, `LCA_Shared.UpgradeDefinitions` |
| `src/server/Services/GameplayRemoteController.lua` | 3 | `LCA_Shared.Config` |
| `default.project.json` | 10–12 | maps `src/shared` as `ReplicatedStorage.LCA_Shared` |

`src/server/Main.server.lua` does not require shared modules directly and currently initializes the canonical services correctly.

## 3. Non-Runtime References

These files document the mismatch or historical Studio paths. They do not execute and do not cause the Studio failure.

### Documentation/current-system references

| File | Lines | Classification/action |
| --- | --- | --- |
| `docs/06_Current_System.md` | 16, 27, 38 | Historical recovered requirements; update only in a later documentation refresh. |
| `docs/06_Current_System.md` | 233, 241, 249, 257, 265, 273 | Historical work-package path language; not runtime. |

### Prompt/specification references

| File | Lines | Classification/action |
| --- | --- | --- |
| `prompts/codex/Recovery.md` | 22 | Recovery inventory heading for `ReplicatedStorage.Shared`. |
| `prompts/codex/WP-01_Config.md` | 129 | Correct LCA_Shared mapping. |
| `prompts/codex/WP-04_FactoryDefinitions.md` | 253, 340 | Explicitly records the mismatch. |
| `prompts/codex/WP-05_QuestDefinitions.md` | 271, 367 | Explicitly records/deferred the mismatch. |
| `prompts/codex/WP-06_ServerDataService.md` | 42, 452 | Records recovered ServerStorage path and deferral. |
| `prompts/codex/WP-06B1_ServerDataService_Skeleton.md` | 66, 626 | Explicit deferral. |
| `prompts/codex/WP-06B2_SessionRepository.md` | 15, 367, 407 | Correct current mapping and bridge exclusion. |
| `prompts/codex/WP-06B3_DataLifecycleIntegration.md` | 11, 17, 400 | Historical obsolete Main path, correct mapping, and exclusion. |
| `prompts/codex/WP-07_GameplayServer.md` | 235, 383 | Recovered Security mismatch and correct current path. |

### Manual-test references

| File | Lines | Classification/action |
| --- | --- | --- |
| `tests/manual/WP-01_Config.md` | 3, 75–76 | Correct mapping and deferred consumer integration. |
| `tests/manual/WP-02_NumberFormatter.md` | 3, 86–87 | Correct mapping and deferred integration. |
| `tests/manual/WP-03_UpgradeDefinitions.md` | 3, 69, 72 | Correct mapping and deferred integration. |
| `tests/manual/WP-04_FactoryDefinitions.md` | 122 | Deferred mismatch. |
| `tests/manual/WP-05_QuestDefinitions.md` | 95 | Deferred mismatch. |
| `tests/manual/WP-06B2_SessionRepository.md` | 87 | Bridge exclusion. |
| `tests/manual/WP-06B3_DataLifecycleIntegration.md` | 67 | Bridge exclusion. |

No non-runtime reference needs replacement to fix Studio execution. Historical claims should not be mechanically rewritten as though the recovered hierarchy never existed.

## 4. Required Replacement Paths

Canonical replacements are:

```text
ReplicatedStorage.Shared.Config
→ ReplicatedStorage.LCA_Shared.Config

ReplicatedStorage.Shared.NumberFormatter
→ ReplicatedStorage.LCA_Shared.NumberFormatter

ReplicatedStorage.Shared.UpgradeDefinitions
→ ReplicatedStorage.LCA_Shared.UpgradeDefinitions

ReplicatedStorage.Shared.FactoryDefinitions
→ ReplicatedStorage.LCA_Shared.FactoryDefinitions

ReplicatedStorage.Shared.QuestDefinitions
→ ReplicatedStorage.LCA_Shared.QuestDefinitions

ReplicatedStorage.Shared.LCAConfig
→ ReplicatedStorage.LCA_Shared.LCAConfig
```

Server-only canonical replacements are:

```text
ServerStorage.SessionManager
→ ServerScriptService.LCA_Server.Services.SessionRepository

ServerStorage.ServerDataService
→ ServerScriptService.LCA_Server.Services.ServerDataService
```

The two server replacements require API review; they are not drop-in aliases.

## 5. Is a Compatibility Bridge Necessary?

Architecturally, no. Every authoritative current module already uses `LCA_Shared`, and direct consumer updates avoid maintaining two public module roots.

Operational caveat: MainGuiClient is currently an unknown Studio Instance preserved by `$ignoreUnknownInstances`; it is not sourced from `src/client`. A repository edit to `recovery/studio/MainGuiClient.client.lua` does not automatically update the live Studio Instance through Rojo. Therefore one of these deployment actions is required:

1. **Recommended:** update the deployed MainGuiClient's five require paths and mirror the exact change in the recovered source under an explicitly authorized compatibility task.
2. Later move/replace the client with a reviewed Rojo-managed client layout during WP-09.
3. **Not recommended except as a temporary emergency:** add a `ReplicatedStorage.Shared` proxy bridge.

A bridge would mask stale consumers, preserve ambiguous dual roots, and could unintentionally advance obsolete SessionManager/Security/Factory scripts to their next failure. If temporarily used, it must contain only five frozen proxy ModuleScripts requiring `LCA_Shared` and have an explicit removal task. Mapping the same source directory twice or moving the authoritative folder is not recommended.

## 6. MainGuiClient Blockers

### Immediate startup blocker

- Lines 25–29 require five modules under the wrong folder. The first failure is Config, so later failures have not yet surfaced.

### Blockers after the path repair

- The active Studio copy must receive the change; recovery source is not Rojo-mapped.
- The script assumes `script.Parent` is the intended ScreenGui/container. Moving it blindly into `src/client` would change its parent to `StarterPlayerScripts/LCA_Client` and break UI construction.
- `updateAchievementPanel()` and `updateCollectionPanel()` are called but undefined.
- Four newer navigation/close-button groups and DailyLogin claim behavior are incomplete.
- QuestSync is resolved but has no listener; cache shapes do not match the server packet.
- RequestRebirth displays success before server confirmation.
- Notification is resolved but unused.

These are WP-09/client-validation issues. They do not justify a Shared bridge.

## 7. FactoryEvolution Blockers

Path blockers:

- Config and FactoryDefinitions use `Shared` instead of `LCA_Shared`.
- SessionManager and ServerDataService use obsolete ServerStorage locations.

Non-path blockers that remain after replacement:

- `getSession(player.UserId)` must use exact Player.
- `session.DataState` must become `session.state`.
- `session.Data` must become `session.data`.
- Stage mutation must call `ServerDataService.markDirty(player)` exactly once.
- Sync must occur only after dirty success, with rollback/fail-closed behavior reviewed.
- Its independent PlayerAdded/Removing ownership and polling loop must be reconciled with DataLifecycleService.
- Factory progression timing is deferred from WP-07A.

Changing only require paths is unsafe and insufficient. Keep the recovered/deployed FactoryEvolution disabled until WP-08.

## 8. Recommended Exact Allowlist for Compatibility Fix

### Recommended direct-consumer fix

For a narrowly scoped MainGuiClient startup repair:

- `recovery/studio/MainGuiClient.client.lua`
- `tests/manual/Compatibility_SharedPaths.md`
- `CHANGELOG.md`

No `default.project.json` change. No shared proxy modules. No FactoryEvolution, SessionManager, SecurityService, EnergyService, or FactoryService edits.

Because the recovery file is not Rojo-mapped, the implementation task must explicitly require applying/verifying the identical five-line change in the deployed Studio MainGuiClient. If repository-only reproducibility is required, stop and design WP-09's client mapping rather than silently adding a bridge.

### Separate WP-08 allowlist, not part of the path fix

FactoryEvolution requires a full compatibility task, proposed separately as:

- `recovery/studio/FactoryEvolution.server.lua`
- focused manual tests/documentation
- `CHANGELOG.md`

Its exact active Rojo placement must be approved before implementation.

## 9. Studio Retest Checklist

### Hierarchy and require validation

- [ ] Rojo is connected to `default.project.json`.
- [ ] `ReplicatedStorage.LCA_Shared` contains Config, NumberFormatter, UpgradeDefinitions, FactoryDefinitions, and QuestDefinitions.
- [ ] The deployed MainGuiClient lines corresponding to recovered 25–29 all use `LCA_Shared`.
- [ ] No MainGuiClient require targets `ReplicatedStorage.Shared`.
- [ ] Start a fresh Play session rather than relying on cached ModuleScript results.
- [ ] Confirm no `Config is not a valid member of Folder ReplicatedStorage.Shared` error.
- [ ] Confirm all five modules require successfully before UI construction.

### Current server/client integration

- [ ] Main.server validates DataSync, QuestSync, PressCore, and PressFeedback.
- [ ] Player reaches `DataLoaded=true` with no LoadFailed attribute.
- [ ] Initial DataSync populates Energy, levels, stats, rewards, and factory stage.
- [ ] One press produces DataSync and explicit four-field COMMON PressFeedback.
- [ ] Rate limiting rejects excess presses without server errors.

### Known post-path issues

- [ ] Record any undefined UI function errors separately as WP-09 blockers.
- [ ] Do not treat absent QuestSync UI updates as a path regression; the listener is still missing.
- [ ] Verify FactoryEvolution remains disabled/unmodified unless WP-08 has been completed.
- [ ] Confirm PlayerDataService, EnergyService, FactoryService, recovered SessionManager, and recovered SecurityService remain inactive.

## Recommendation

Update the five MainGuiClient require paths directly and avoid a permanent `Shared` bridge. Do not perform global search-and-replace across recovered/obsolete services: several of those files would load farther but remain architecturally incompatible and unsafe to activate.
