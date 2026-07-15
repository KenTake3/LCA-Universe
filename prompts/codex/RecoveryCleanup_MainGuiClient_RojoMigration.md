# Recovery Cleanup — MainGuiClient Rojo Migration

## 1. Objective

Make the repository the sole source of truth for `MainGuiClient` and remove the current manual synchronization between:

- `recovery/studio/MainGuiClient.client.lua`; and
- the deployed Studio `StarterGui/MainGui/MainGuiClient` LocalScript.

The design was approved and implemented in the current uncommitted recovery-cleanup worktree. Commit and push remain separately controlled.

## Implementation Record

The approved migration uses:

```text
src/client/MainGuiClient.client.lua
→ StarterGui/MainGui/MainGuiClient
```

The source was moved from `recovery/studio/MainGuiClient.client.lua` with Git rename tracking. The project mapping now owns `MainGui` with the confirmed deployed properties:

- `ResetOnSpawn = false`
- `IgnoreGuiInset = true`
- `DisplayOrder = 0`
- `ZIndexBehavior = Sibling`
- `Enabled = true`

Studio confirmed that `MainGuiClient` was the only edit-time child, so the mapped `MainGui` does not preserve unknown descendants. The broader `StarterGui` service retains `$ignoreUnknownInstances: true` to keep unrelated GUI instances out of scope. The empty `ReplicatedStorage.Shared` folder is not mapped, modified, or deleted.

## 2. Pre-Migration State

Before this cleanup, `default.project.json` mapped:

- `src/shared` to `ReplicatedStorage/LCA_Shared`;
- `src/server` to `ServerScriptService/LCA_Server`; and
- `src/client` to `StarterPlayer/StarterPlayerScripts/LCA_Client`.

No repository path mapped `StarterGui/MainGui`. The recovered client assumes `script.Parent` is the `MainGui` ScreenGui and creates its entire runtime UI beneath that parent. Editing `recovery/studio/MainGuiClient.client.lua` therefore did not update Studio, and editing the deployed LocalScript did not update the repository.

The current recovered source already contains the reviewed `LCA_Shared` require paths and the pending strict-type cleanup that removes calls to the two unrecovered global update functions. The migration must transfer the reviewed current source exactly; it must not copy an older committed revision over those fixes.

## 3. Options Considered

### 3.1 Map the LocalScript through the existing `src/client` directory

Placing `MainGuiClient.client.lua` directly under the currently mapped `src/client` would create:

```text
StarterPlayer
└── StarterPlayerScripts
    └── LCA_Client
        └── MainGuiClient
```

This is incompatible without a runtime rewrite because `script.Parent` would be `LCA_Client`, not a ScreenGui. The script would parent UI objects into StarterPlayerScripts/PlayerScripts instead of `PlayerGui.MainGui`.

Decision: reject for the minimum cleanup slice.

### 3.2 Move to StarterPlayerScripts and create MainGui at runtime

The LocalScript could explicitly find or create `Players.LocalPlayer.PlayerGui.MainGui`. This would be a viable later architecture, but it changes startup, respawn, duplicate-GUI, and ScreenGui-property behavior. It is larger than required to end dual source ownership.

Decision: defer.

### 3.3 Explicitly map the existing StarterGui hierarchy

Map a repository-owned LocalScript to:

```text
StarterGui
└── MainGui (ScreenGui)
    └── MainGuiClient (LocalScript)
```

This preserves the recovered `script.Parent` contract and the observed deployed hierarchy.

Decision: approved design recommendation.

## 4. Proposed Repository Layout

Authoritative runtime source:

```text
src/client/MainGuiClient.client.lua
```

Rojo runtime path:

```text
src/client/MainGuiClient.client.lua
→ StarterGui/MainGui/MainGuiClient
```

After migration, remove:

```text
recovery/studio/MainGuiClient.client.lua
```

Do not retain a second editable mirror, generated copy, symlink, or compatibility script. Git history remains the recovery archive.

## 5. Proposed Rojo Mapping

Replace the current whole-directory `StarterPlayerScripts/LCA_Client -> src/client` mapping because the same source path must not be mapped into two DataModel locations. No active client files currently exist under `src/client`, so removal has no current runtime consumer.

Add an explicit mapping equivalent to:

```json
"StarterGui": {
  "$className": "StarterGui",
  "$ignoreUnknownInstances": true,

  "MainGui": {
    "$className": "ScreenGui",
    "$properties": {
      "ResetOnSpawn": false,
      "IgnoreGuiInset": true,
      "DisplayOrder": 0,
      "ZIndexBehavior": "Sibling",
      "Enabled": true
    },

    "MainGuiClient": {
      "$path": "src/client/MainGuiClient.client.lua"
    }
  }
}
```

The deployed `StarterGui.MainGui` properties were confirmed before implementation:

- `ResetOnSpawn = false`;
- `IgnoreGuiInset = true`;
- `DisplayOrder = 0`;
- `ZIndexBehavior = Sibling`;
- `Enabled = true`.

The mapping encodes only those confirmed values. The build must contain one ScreenGui named `MainGui` and one LocalScript named `MainGuiClient` at the exact path.

The `MainGui` mapping should be authoritative after cutover. Unknown edit-time children under that ScreenGui must be inventoried before choosing `$ignoreUnknownInstances`. If the deployed ScreenGui contains only the recovered LocalScript, prefer no ignore flag at the `MainGui` level so stale manual descendants cannot survive. Keep `$ignoreUnknownInstances: true` at the broader `StarterGui` service so unrelated GUIs remain out of scope.

## 6. Source Migration Rules

1. Keep the cleanup allowlist distinguishable from the already reviewed WP-10 and typecheck changes present in the worktree.
2. Compare the deployed Studio LocalScript source with the current repository recovery source.
3. Resolve any difference before moving files; do not silently select one copy.
4. Move the reviewed source with `git mv` semantics to preserve history:

   ```text
   recovery/studio/MainGuiClient.client.lua
   → src/client/MainGuiClient.client.lua
   ```

5. Update references in documentation and manual tests that incorrectly describe the recovery path as the active editable source.
6. Retain historical references where the document is explicitly describing the original recovery investigation; label them historical rather than rewriting evidence.
7. Do not change MainGuiClient gameplay, UI layout, remote payloads, cache shapes, or deferred systems in the migration commit.

## 7. Studio Cutover Procedure

The cutover must be performed once, in a controlled Studio session:

1. Save a local backup of the place before changing synchronization ownership.
2. Record the deployed `StarterGui.MainGui` properties and child inventory.
3. Compare deployed `MainGuiClient.Source` with the proposed repository source.
4. Stop any existing Rojo serve session.
5. Apply the Phase B repository move and project mapping.
6. Build an rbxlx and inspect the hierarchy before connecting live Rojo sync.
7. In Studio, remove or rename the manually maintained LocalScript only if Rojo does not reconcile it by the same name/path. Never leave two enabled LocalScripts.
8. Connect `rojo serve default.project.json` and confirm the repository-owned instance appears at `StarterGui.MainGui.MainGuiClient`.
9. Edit a harmless comment in the repository and verify Studio updates automatically; revert the comment afterward.
10. Do not edit the Studio Source as a normal workflow after cutover. Repository changes are authoritative.

The same-name existing Studio instance is expected to reconcile at the mapped path, but the operator must verify that Studio contains exactly one instance rather than assuming reconciliation.

## 8. Runtime Compatibility Requirements

The migration must preserve:

- `script.Parent == StarterGui.MainGui` in edit-time source and `PlayerGui.MainGui` at runtime;
- the five `ReplicatedStorage.LCA_Shared` requires;
- all confirmed RemoteEvent paths;
- dynamic UI creation beneath `MainGui`;
- the canonical UPG panel and server-authoritative BuyUpgrade behavior;
- Press/DataSync/Auto Power display behavior;
- the current absence of a client Auto Power RemoteEvent;
- all explicitly deferred Quest, Achievement, Collection, DailyLogin, Rebirth, monetization, and Factory visual work.

Do not reactivate legacy `FactoryEvolution` or map any other file from `recovery/studio`.

## 9. Duplicate-Execution Prevention

Acceptance requires exactly one enabled `MainGuiClient` LocalScript across:

- `StarterGui`;
- `StarterPlayerScripts`;
- `PlayerGui` during a single runtime clone; and
- all Rojo-mapped source paths.

The Phase B repository search must confirm there is exactly one runtime source file containing the MainGuiClient implementation. `recovery/studio` must no longer contain an editable duplicate.

Do not add runtime singleton guards merely to tolerate duplicate deployment. Fix the hierarchy instead.

## 10. Phase B Allowlist

Recommended exact allowlist:

- `default.project.json`
- `recovery/studio/MainGuiClient.client.lua` (delete/move only)
- `src/client/MainGuiClient.client.lua` (move destination)
- `tests/manual/RecoveryCleanup_MainGuiClient_RojoMigration.md`
- `CHANGELOG.md`
- `prompts/codex/RecoveryCleanup_MainGuiClient_RojoMigration.md` only if the reviewed design needs implementation-result annotations

No server module, shared module, RemoteEvent, legacy FactoryEvolution file, project setting outside the Rojo mapping, or unrelated Studio instance may change.

## 11. Validation Plan

### Repository and build

- `git diff --check`
- `rojo build default.project.json --output /tmp/LCA-RecoveryCleanup-MainGuiClient.rbxlx`
- Inspect the built hierarchy for exactly `StarterGui/MainGui/MainGuiClient`.
- Search for all `MainGuiClient` source copies and confirm only `src/client/MainGuiClient.client.lua` is runtime-authoritative.
- Confirm `recovery/studio/MainGuiClient.client.lua` is absent after the move.
- Confirm no source maps to both StarterGui and StarterPlayerScripts.

### Studio Script Analysis

- Open the built rbxlx before Play.
- Confirm zero MainGuiClient type errors.
- Confirm `script.Parent` is a ScreenGui.
- Confirm exactly one MainGuiClient LocalScript exists at the intended hierarchy.

### Studio runtime

- Main UI appears once with no duplicate panels.
- Press works and emits exactly one request per click.
- DataSync updates Energy once.
- UPG shows the four canonical upgrades.
- BuyUpgrade sends only the upgrade ID and refreshes through DataSync.
- Auto Power updates Energy without `TotalPresses` or PressFeedback changes.
- Respawn behavior matches the recorded pre-migration `ResetOnSpawn` contract.
- Leaving and rejoining creates one UI/controller instance.
- Legacy FactoryEvolution remains disabled.

### Rojo ownership

- A repository Source edit appears in Studio through Rojo.
- A Studio-only Source edit is treated as transient and is not copied back into `recovery/studio`.
- Rebuilding from a fresh checkout reproduces the same MainGui hierarchy without manual source pasting.

## 12. Rollback Plan

If the mapped hierarchy or runtime validation fails:

1. Stop Rojo synchronization.
2. Restore the backed-up place.
3. Revert only the migration commit/files.
4. Keep the reviewed source changes in Git history; do not establish a new permanent mirror.
5. Record the exact property or hierarchy incompatibility before revising this design.

Rollback must not introduce a `ReplicatedStorage.Shared` bridge or activate recovered server scripts.

## 13. Acceptance Criteria

The cleanup is complete only when:

- the repository contains exactly one editable MainGuiClient source;
- Rojo builds it at `StarterGui.MainGui.MainGuiClient`;
- Studio contains exactly one enabled deployed copy;
- `script.Parent` remains a ScreenGui without a client runtime rewrite;
- a fresh checkout/build requires no manual source copy;
- Script Analysis is clean for the client;
- Press, DataSync, UPG, BuyUpgrade, and Auto Power UI integration pass;
- deferred client systems remain deferred; and
- `recovery/studio` is no longer part of the MainGuiClient editing workflow.

## 14. Resolved Inputs and Remaining Studio Validation

- The deployed ScreenGui properties are confirmed and encoded in `default.project.json`.
- The deployed child inventory is confirmed as exactly one `MainGuiClient` LocalScript.
- The repository source includes the approved `LCA_Shared` paths and removal of the two calls to unrecovered update functions.
- The generated rbxlx contains exactly one `StarterGui/MainGui/MainGuiClient` hierarchy.
- Live Rojo reconciliation must still be verified on a backup of the currently open place to ensure the existing same-name LocalScript is updated rather than duplicated.
