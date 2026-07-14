# MainGuiClient Shared-Path Compatibility Manual Tests

## Exact Replacements

- [ ] `ReplicatedStorage.Shared.Config` became `ReplicatedStorage.LCA_Shared.Config`.
- [ ] `ReplicatedStorage.Shared.NumberFormatter` became `ReplicatedStorage.LCA_Shared.NumberFormatter`.
- [ ] `ReplicatedStorage.Shared.UpgradeDefinitions` became `ReplicatedStorage.LCA_Shared.UpgradeDefinitions`.
- [ ] `ReplicatedStorage.Shared.FactoryDefinitions` became `ReplicatedStorage.LCA_Shared.FactoryDefinitions`.
- [ ] `ReplicatedStorage.Shared.QuestDefinitions` became `ReplicatedStorage.LCA_Shared.QuestDefinitions`.
- [ ] No `ReplicatedStorage.Shared` reference remains in `recovery/studio/MainGuiClient.client.lua`.
- [ ] No other MainGuiClient behavior changed.

## Rojo Hierarchy

- [ ] `ReplicatedStorage.LCA_Shared.Config` exists.
- [ ] `ReplicatedStorage.LCA_Shared.NumberFormatter` exists.
- [ ] `ReplicatedStorage.LCA_Shared.UpgradeDefinitions` exists.
- [ ] `ReplicatedStorage.LCA_Shared.FactoryDefinitions` exists.
- [ ] `ReplicatedStorage.LCA_Shared.QuestDefinitions` exists.
- [ ] No `ReplicatedStorage.Shared` compatibility bridge was added.
- [ ] `default.project.json` remains unchanged.

## Scope Boundaries

- [ ] FactoryEvolution remains intentionally unresolved and unmodified.
- [ ] Undefined MainGuiClient functions remain deferred.
- [ ] QuestSync handling remains deferred.
- [ ] Rebirth notification behavior remains unchanged.
- [ ] MainGuiClient remains under `recovery/studio` and was not moved into `src/client`.

## Studio Deployment and Retest

`recovery/studio/MainGuiClient.client.lua` is not Rojo-mapped. Apply the same five require-path replacements manually to the deployed Studio MainGuiClient before testing.

- [ ] Connect Rojo using `default.project.json`.
- [ ] Verify all five LCA_Shared modules in ReplicatedStorage.
- [ ] Update the deployed Studio copy with the exact five replacements.
- [ ] Start a fresh Play session to avoid cached ModuleScript results.
- [ ] Confirm the `Config is not a valid member of Folder "ReplicatedStorage.Shared"` error no longer appears.
- [ ] Confirm all five modules load before MainGuiClient constructs UI.
- [ ] Confirm the player reaches `DataLoaded=true` without `DataLoadFailed=true`.
- [ ] Confirm initial DataSync updates the client cache/UI.
- [ ] Confirm PressCore produces DataSync and explicit COMMON PressFeedback.
- [ ] Record unrelated undefined-function or QuestSync issues separately; do not treat them as path regressions.
- [ ] Keep FactoryEvolution disabled until its separate compatibility repair.

## Confirmed Studio Results

Validated in the deployed Studio MainGuiClient after applying the same five `LCA_Shared` path replacements:

- [x] The `ReplicatedStorage.Shared.Config` startup error is gone.
- [x] The main UI appears.
- [x] The press button appears.
- [x] Press requests work.
- [x] The initial press reward is `+1`.
- [x] Energy updates successfully.
