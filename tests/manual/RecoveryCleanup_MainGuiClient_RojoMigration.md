# Recovery Cleanup — MainGuiClient Rojo Migration Manual Verification

## Repository ownership

- [ ] `src/client/MainGuiClient.client.lua` is the only repository runtime source for MainGuiClient.
- [ ] `recovery/studio/MainGuiClient.client.lua` no longer exists.
- [ ] `default.project.json` does not map MainGuiClient into StarterPlayerScripts.
- [ ] A fresh Rojo build requires no manual Source copy from `recovery/studio`.
- [ ] The empty `ReplicatedStorage.Shared` folder remains untouched in the current Studio place.

## Generated hierarchy

- [ ] The build contains exactly `StarterGui/MainGui/MainGuiClient`.
- [ ] `MainGui` is a ScreenGui.
- [ ] `MainGuiClient` is a LocalScript.
- [ ] `MainGuiClient.Parent == MainGui`.
- [ ] No second MainGuiClient exists under StarterGui or StarterPlayerScripts.
- [ ] `MainGui.ResetOnSpawn == false`.
- [ ] `MainGui.IgnoreGuiInset == true`.
- [ ] `MainGui.DisplayOrder == 0`.
- [ ] `MainGui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling`.
- [ ] `MainGui.Enabled == true`.

## Studio cutover

- [ ] Back up the currently open place before connecting the new mapping.
- [ ] Stop the old Rojo session before changing ownership.
- [ ] Confirm the existing manual path is `StarterGui/MainGui/MainGuiClient`.
- [ ] Connect the repository using `rojo serve default.project.json`.
- [ ] Confirm Rojo reconciles the same-name LocalScript rather than creating a duplicate.
- [ ] If a duplicate appears, stop sync and remove only the stale manual copy after comparing Source.
- [ ] Confirm exactly one enabled MainGuiClient remains before Play.
- [ ] Confirm a repository comment edit reaches Studio, then revert the comment.

## Script Analysis and runtime

- [ ] Studio Script Analysis reports no MainGuiClient errors before Play.
- [ ] `script.Parent` is the cloned `PlayerGui.MainGui` ScreenGui at runtime.
- [ ] Main UI appears exactly once.
- [ ] Press sends one request and DataSync updates Energy.
- [ ] UPG shows ClickPower, AutoPower, CoreAmplifier, and Luck.
- [ ] BuyUpgrade remains server-authoritative and refreshes through DataSync.
- [ ] Auto Power updates Energy and LifetimeEnergy without incrementing TotalPresses or emitting PressFeedback.
- [ ] Respawn behavior matches `ResetOnSpawn = false` and does not duplicate the controller.
- [ ] Leaving and rejoining produces one UI/controller instance.
- [ ] Legacy FactoryEvolution remains disabled.
- [ ] Achievement and Collection rendering remains deferred.

## Regression and scope

- [ ] The five shared requires target `ReplicatedStorage.LCA_Shared`.
- [ ] No `updateAchievementPanel()` or `updateCollectionPanel()` call remains.
- [ ] No server, remote, shared API, or gameplay behavior changed as part of the mapping migration.
- [ ] No compatibility proxy was added beneath the empty `ReplicatedStorage.Shared` folder.
