# WP-09 — MainGuiClient Shop/Upgrade UI Investigation

## Mission and Root-Cause Decision

Investigate why the recovered client opens an empty panel labeled SHOP while authoritative upgrade purchasing is active.

**Root cause:** SHOP and UPGRADES are separate recovered panels. The SHOP panel renders `Config.GamePasses`; that table is intentionally empty because no monetization products survived recovery. The four canonical upgrades are already constructed under the separate `UpgradePanel` and opened by the `UPG` navigation button. This is not a missing upgrade renderer, missing template, wrong parent, or uncalled refresh.

The smallest safe recovery action is therefore validation, not immediate runtime modification: test the deployed `UPG` path and compare the Studio LocalScript with the repository copy. Do not duplicate upgrade rows into SHOP or repurpose monetization navigation without an explicit UX decision.

## Confirmed Studio Validation Outcome

Studio validation completed after this investigation and confirmed the diagnosis:

- SHOP and UPG are separate panels.
- SHOP is monetization-only and remains empty because Config.GamePasses is empty.
- UPG opens the canonical UpgradePanel.
- Exactly four rows are visible: AutoPower, ClickPower, CoreAmplifier, and Luck.
- Initial levels and Config-derived display costs appear.
- After sufficient Energy was earned, ClickPower purchase succeeded server-side.
- Energy was deducted, ClickPower advanced from level 0 to 1, and DataSync refreshed the UI.
- The subsequent Press reward increased from +1 to +2.
- No MainGuiClient runtime repair was required for this validation slice.
- Legacy FactoryEvolution remained disabled in Studio.

## 1. Current MainGuiClient Startup Flow

The recovered LocalScript:

1. Gets LocalPlayer and PlayerGui.
2. Requires Config, NumberFormatter, UpgradeDefinitions, FactoryDefinitions, and QuestDefinitions from `ReplicatedStorage.LCA_Shared`.
3. Waits for the confirmed RemoteEvents, including BuyUpgrade and DataSync.
4. Builds all top-level UI Instances dynamically beneath `script.Parent` (`MainGui` ScreenGui).
5. Creates navigation buttons, panels, upgrade rows, and game-pass rows synchronously.
6. Connects DataSync and other client events.
7. Defines `updateUI` and connects panel/button handlers.
8. Starts a one-second UI update task.
9. Waits up to 30 seconds for the DataLoaded attribute, then calls `updateUI` and displays the welcome message.

Current Studio evidence confirms this flow reaches usable UI and receives DataSync without red runtime errors.

## 2. Current DataSync Cache Shape

The local `clientData` cache has canonical upgrade-related fields:

```lua
Energy = 0
ClickPower = 1
AutoPower = 0
CoreAmplifier = 1
Luck = 0
UpgradeLevels = {
    ClickPower = 0,
    AutoPower = 0,
    CoreAmplifier = 0,
    Luck = 0,
}
```

The DataSync handler replaces these from the canonical main packet:

- Energy
- derived ClickPower, AutoPower, CoreAmplifier, Luck
- the complete four-key UpgradeLevels table

SessionRepository builds exactly these values from server-owned data and calculated stats. Client cache values are display-only and must not be returned as authority.

## 3. Confirmed SHOP Navigation Flow

The navigation bar creates two different buttons:

```lua
UpgradeNav, text "UPG", LayoutOrder 1
ShopNav, text "SHOP", LayoutOrder 3
```

Connections are distinct:

```lua
upgradeBtn.MouseButton1Click → togglePanel(upgradePanel)
shopNavBtn.MouseButton1Click → togglePanel(shopPanel)
```

The reported SHOP observation proves only the second path. It does not test the first path. A VIPZone proximity prompt also opens ShopPanel, while UpgradeZone opens UpgradePanel.

## 4. Confirmed SHOP Panel Instance Path

The UI is code-created under the ScreenGui:

```text
StarterGui/MainGui (deployed Studio hierarchy)
└─ ShopPanel
   └─ List
      └─ UIListLayout
```

At runtime it is available through the player's cloned GUI as:

```text
Players.LocalPlayer.PlayerGui.MainGui.ShopPanel.List
```

The exact MainGui name is an observed/recovered placement assumption; the script itself uses `script.Parent` and creates ShopPanel directly beneath it.

ShopPanel is a game-pass/monetization panel, not the upgrade parent.

## 5. Existing Upgrade Rendering Functions

There is no separately named `createUpgrade`, `renderUpgrade`, or `refreshUpgrade` function. Equivalent behavior exists inline in two places:

- construction loop: `for i, upgrade in ipairs(Config.Upgrades)` creates each row and stores references in `upgradeButtons[upgrade.id]`;
- refresh block inside `updateUI`: iterates Config.Upgrades, reads cached levels/Energy, calculates display cost, and updates labels/colors/max state.

The reusable generic helpers are `makeGui`, `makeText`, `makeButton`, `makePanel`, and `togglePanel`.

## 6. Missing or Incomplete Upgrade Rendering Functions

No upgrade rendering function is missing for the current four-row contract. All required construction, click wiring, and refresh code survives.

Structural weaknesses that may justify later refactoring, but do not explain empty SHOP:

- row construction and refresh are anonymous inline blocks;
- Config/client packet shapes are trusted without defensive client validation;
- max-state styling does not explicitly restore every property if a level later falls below max;
- button Active/AutoButtonColor are not explicitly disabled while maxed or unaffordable;
- no pending-request state exists;
- the fixed-height Frame is not scrollable, though four 75-pixel rows plus spacing fit the current 360-pixel list area.

Do not treat these as authority/security defects; the server rejects invalid purchases.

## 7. Exact Four Upgrade IDs Expected by the Client

Exactly:

1. `ClickPower`
2. `AutoPower`
3. `CoreAmplifier`
4. `Luck`

They are Config IDs, saved-data keys, DataSync UpgradeLevels keys, client row keys, and accepted BuyUpgrade payloads. Case variants, display names, legacy IDs, and speculative upgrades are unsupported.

## 8. Config.Upgrades Schema Compatibility

Current Config.Upgrades is an ordered array of exactly four records. Each supplies every field consumed during row construction and refresh:

- `id`
- `displayName`
- `description`
- `iconColor` (Color3)
- `maxLevel`
- internal cost fields consumed by Config.getUpgradeCost

The construction loop uses `ipairs`, preserving Config ordering. No missing Template is required. Display text/colors and balance remain recovery-provisional but are centralized in Config.

By contrast, Config.GamePasses is intentionally `{}`. Therefore `pairs(Config.GamePasses)` creates zero SHOP children. This is the direct cause of the observed empty SHOP.

## 9. UpgradeDefinitions Usage in the Client

The client uses:

```lua
UpgradeDefinitions.canLevelUp(upgrade.id, level)
```

only to color the display as affordable/eligible. It does not calculate mutation results or grant authority. The server independently validates the Config definition, effective limit, current level, Energy, and cost.

Client `calculateStats` is not used for purchasing; derived stats arrive through DataSync.

## 10. BuyUpgrade Remote Payload Compatibility

Each existing upgrade row connects:

```lua
buyUpgradeEvent:FireServer(upgrade.id)
```

This exactly matches WP-07B: one and only one supported string ID, with no level, cost, balance, max level, or quantity. GameplayRemoteController validates payload shape and rate-limits independently; GameplayService re-reads canonical session state and recalculates cost.

No client/server payload repair is required.

## 11. Upgrade Button Construction Strategy

Keep the existing deterministic code construction. There is no authoritative Template to clone.

For each Config.Upgrades record, the existing code creates:

- one TextButton row named by exact ID;
- a Color3 stripe from `iconColor`;
- display-name and description labels;
- level and cost labels;
- one entry in `upgradeButtons`;
- one MouseButton1Click listener sending the exact ID.

Do not create a second set under ShopPanel. Duplicate rows would create ambiguous navigation, duplicate listeners, and two display registries.

## 12. Level and Cost Text Strategy

Level source:

```lua
clientData.UpgradeLevels[upgrade.id]
```

Cost source for display only:

```lua
Config.getUpgradeCost(upgrade.id, level)
```

The existing labels display `Lv. <level>` and formatted cost. Preserve NumberFormatter and current typography. The server remains authoritative and may reject a click based on newer state even if the client display is stale.

## 13. Max-Level Display Behavior

Existing behavior:

- if `level >= upgrade.maxLevel`, cost text becomes `MAX`;
- level text becomes gold;
- canLevelUp contributes to red/non-affordable coloring before the MAX replacement.

For a future minimal hardening slice, use `UpgradeDefinitions.canLevelUp` as the display eligibility source rather than only comparing raw `upgrade.maxLevel`, because the server also applies Config.Security.MaxUpgradeLevel. At max, show `MAX` and make the row non-interactive locally, while retaining server enforcement.

No exact disabled opacity/color beyond existing COLORS is recovered; any new value must be marked `RECOVERY_PROVISIONAL`.

## 14. Insufficient-Energy Display Behavior

Existing behavior colors cost green only when cached Energy is at least the displayed cost and canLevelUp returns true; otherwise it uses danger/red.

This is adequate presentation. A future slice may set `Active`/`AutoButtonColor` for clarity, but must not claim the client prevents exploits. Cached Energy can be stale, and only the server decides affordability.

## 15. DataSync Refresh Behavior

Every DataSync updates the cache, then calls `updateUI`. The upgrade refresh block updates the four existing row references; it does not create rows. Therefore purchases reflected by DataSync update Energy, selected level, next cost, eligibility color, and derived-stat labels without duplication.

Rows are created once at startup before the DataSync connection is used. `upgradeButtons` is keyed by stable ID, so repeated DataSync events reuse the same Instances.

## 16. Panel-Open Refresh Behavior

`togglePanel` only changes visibility; it does not explicitly call updateUI. This does not cause the empty SHOP and does not stale upgrade rows because:

- DataSync calls updateUI;
- a one-second task also calls updateUI continuously;
- final startup calls updateUI.

If a reviewed Phase B refactor adds `refreshUpgradeRows()`, calling it when UpgradePanel opens is reasonable and deterministic. It must update existing references, not rebuild rows.

## 17. Existing Template or Dynamic-Construction Decision

Decision: retain dynamic construction.

No Template, Clone call, pre-authored upgrade row, ScrollingFrame template, or Rojo-mapped client UI asset survives. The current four rows already fit the fixed list. Introducing a Template would add hierarchy dependencies without recovery evidence.

## 18. Parent Hierarchy Assumptions

Upgrade hierarchy:

```text
MainGui (ScreenGui; script.Parent)
└─ UpgradePanel
   └─ List (Frame)
      ├─ UIListLayout
      ├─ ClickPower (TextButton)
      ├─ AutoPower (TextButton)
      ├─ CoreAmplifier (TextButton)
      └─ Luck (TextButton)
```

The rows are created directly by the LocalScript; they do not need pre-existing children. Required external hierarchy is only a running LocalScript parented beneath a suitable ScreenGui plus the confirmed ReplicatedStorage modules/remotes.

`default.project.json` does not map recovery/studio into StarterGui or src/client. The deployed Studio MainGuiClient must therefore still be updated manually for any future repository-side client change.

## 19. Undefined-Function Blockers

`updateAchievementPanel()` and `updateCollectionPanel()` are referenced by category-tab callbacks but have no definitions. Quest/Achievement/Collection/Login navigation buttons are created but not wired in the surviving panel-management connections. QuestSync is resolved but has no listener.

These defects do not execute during normal startup, SHOP navigation, UPG navigation, DataSync, press, or upgrade purchase in the confirmed Studio path. They remain latent blockers only when the corresponding incomplete UI paths become reachable.

Do not repair them in the upgrade slice.

## 20. Other Startup Blockers After the Shared-Path Fix

No current red runtime blocker is observed. Potential blocking waits remain if required Instances disappear:

- every `WaitForChild` RemoteEvent, including unused QuestAction/QuestSync and disabled FactoryEvolutionSync;
- required LCA_Shared modules;
- LocalPlayer/PlayerGui.

Current Studio evidence confirms these dependencies exist. FactoryEvolution server script can remain disabled while the client merely resolves/listens to its existing remote.

The one-second full updateUI loop is inefficient and rebuilds History entries, but current evidence shows no startup error; it is outside this slice.

## 21. Quest/Achievement/Collection Code That Must Remain Deferred

Defer:

- QuestSync cache mapping/listener;
- QuestAction payloads;
- quest navigation/actions/rendering;
- achievement records, targets, claim actions, and `updateAchievementPanel`;
- collection categories/ownership and `updateCollectionPanel`;
- DailyLogin mapping/navigation/claim behavior;
- all undefined helper repairs in those domains.

QuestDefinitions currently exposes only one immutable category and intentionally contains no invented records.

## 22. Security Boundary

The client may:

- display Config definitions and cached DataSync state;
- calculate an advisory display cost;
- show affordability/max presentation;
- send exactly one supported upgrade ID.

The client must never send or decide authoritative cost, level, Energy, max level, mutation, reward, or success. GameplayService revalidates the exact Loaded session, Config/effective limit, current Energy/level, and server-calculated cost, then marks dirty and syncs.

No optimistic cache mutation should occur. No purchase-success notification Remote is added.

## 23. Proposed Minimal Client API/Functions

### Immediate Phase B recommendation

Do not change runtime code until Studio verifies the `UPG` navigation path against the current deployed LocalScript. Existing code already provides the required four-row contract.

### Contingent refactor if validation finds deployed drift or maintainability is explicitly requested

Within MainGuiClient only:

```lua
local function createUpgradeRows()
local function refreshUpgradeRows()
```

- `createUpgradeRows` runs once, validates/iterates Config.Upgrades in order, constructs exactly four rows, and connects one listener per row.
- `refreshUpgradeRows` updates the existing registry from clientData and never creates/destroys rows.
- DataSync calls refresh through updateUI or directly.
- UpgradePanel open may call refresh.

This refactor must preserve exact visuals and payloads. It is unnecessary if UPG already works, and must not be used to populate ShopPanel.

## 24. Exact Phase B Allowlist

Recommended first Phase B is validation-only and creates no runtime diff:

- `tests/manual/WP-09_MainGuiClient_ShopRecovery.md`
- `CHANGELOG.md` only if recording verified Studio results is desired.

If Chief Architect explicitly authorizes a client refactor after UPG/deployed-copy validation:

- `recovery/studio/MainGuiClient.client.lua`
- `tests/manual/WP-09_MainGuiClient_ShopRecovery.md`
- `CHANGELOG.md`

Do not modify server modules, shared modules, project mapping, FactoryEvolution, remotes, or other recovered files. Because recovery/studio is not Rojo-mapped, the deployed Studio copy must again be updated manually and compared after any approved client change.

## 25. Manual Studio Test Plan

### Establish root cause

- Open SHOP and confirm runtime path `MainGui.ShopPanel.List` contains only UIListLayout when Config.GamePasses is empty.
- Confirm this is expected monetization-safe behavior, not an upgrade rendering failure.
- Click UPG and confirm `MainGui.UpgradePanel.List` contains exactly four TextButton rows in Config order.
- Confirm exact row names: ClickPower, AutoPower, CoreAmplifier, Luck.
- Compare deployed MainGuiClient construction/navigation sections with recovery/studio source.

### Rendering and refresh

- Each row shows Config displayName, description, iconColor stripe, level, and cost.
- Initial DataSync updates all four levels and current Energy.
- Repeated DataSync updates existing Instances without increasing row/listener count.
- Closing/reopening UPG preserves four rows and current labels.
- No Template or pre-existing row is required.

### Purchase integration

- Click each affordable row and verify exactly its ID is sent.
- Do not locally alter level/Energy on click.
- While awaiting DataSync, retain the last server-confirmed display; repeated clicks may occur but server rate/eligibility remains authoritative.
- On successful purchase, next DataSync updates Energy, level, next cost, color, and derived stats.
- Insufficient Energy and max-level rejection cause no optimistic change or false success notification.
- Max display follows effective eligibility; server remains authoritative.

### Regression and exclusions

- Press/DataSync/COMMON feedback remain working.
- SHOP stays empty when GamePasses is empty and does not invent products.
- Rebirth, Daily, Playtime, Quest, Achievement, Collection, Login, History, rarity, and monetization behavior is unchanged.
- Legacy FactoryEvolution remains disabled.
- No server/shared/project files change.
- Repository and deployed Studio copies are manually synchronized if a later client diff is approved.

## 26. Explicitly Deferred Client Systems

- Repurposing SHOP as UPGRADES or merging the two panels without an approved UX decision.
- Game-pass/developer-product UI and IDs.
- Rebirth immediate false-success repair and authoritative feedback.
- Daily and Playtime validation/feedback.
- Quest, Achievement, Collection, and DailyLogin mappings/functions/navigation.
- History performance/refactor and rarity behavior.
- FactoryEvolutionSync removal/repair and visual evolution.
- Notification Remote contract.
- defensive validation of every DataSync field.
- pending spinners, optimistic UI, bulk-buy, purchase sounds, animations, and telemetry.
- moving MainGuiClient into src/client or changing default.project.json.

## 27. Unresolved UI/UX Values

- Whether product language intends SHOP to mean upgrades, monetization, or both; recovered source clearly separates UPG and SHOP.
- Whether SHOP should show a non-purchasable “No products available” state when GamePasses is empty.
- Whether the UPG navigation label is sufficiently discoverable in Studio.
- Whether maxed/unaffordable rows should be disabled, dimmed, or remain clickable for server rejection.
- Whether a pending state should temporarily suppress repeat clicks before DataSync.
- Whether a server-confirmed purchase success effect is desired; no feedback protocol is approved.
- Whether fixed row/panel dimensions are adequate across phone/tablet safe areas. Any changed layout constants are `RECOVERY_PROVISIONAL` until approved.
