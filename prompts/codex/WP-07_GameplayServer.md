# WP-07 — Authoritative Gameplay Server Investigation and Design

## Mission and Evidence Boundary

Design the smallest authoritative gameplay mutation path on top of the approved WP-06 lifecycle, `ServerDataService`, and canonical `SessionRepository`. Repository-wide search found no active or recovered server-side `OnServerEvent` or `OnServerInvoke` gameplay handler. Client requests and validation fragments survive, but several mutation and reward formulas do not.

WP-07 Phase B should therefore begin with a press-only vertical slice. Upgrade purchases, rebirths, claims, factory progression, luck rolling, quests, and monetization remain separate reviewed subpackages.

## 1. Existing Gameplay Remotes

The following RemoteEvent Instances are confirmed under `ReplicatedStorage.Remotes`:

| RemoteEvent | Direction evidenced | Status |
| --- | --- | --- |
| `PressCore` | Client → server | Client fires with no arguments; no server listener survives. |
| `BuyUpgrade` | Client → server | Client sends one upgrade ID string; no listener survives. |
| `ClaimDailyReward` | Client → server | Client fires with no arguments; no listener survives. |
| `ClaimPlaytimeReward` | Client → server | Client fires with no arguments; no listener survives. |
| `RequestRebirth` | Client → server | Client fires with no arguments; no listener survives. |
| `QuestAction` | Intended client → server | Client obtains it but never fires it; action names/payload are unknown. |
| `DataSync` | Server → client | Active B1/B3 callback sends canonical main packet. |
| `QuestSync` | Server → client | Active callback is injected, but B1 does not automatically send and recovered client has no listener. |
| `PressFeedback` | Server → client | Client listener expects press presentation fields. No producer survives. |
| `RarityBroadcast` | Server → clients | Client listener exists; no producer survives. |
| `FactoryEvolutionSync` | Server → client(s) | Recovered FactoryEvolution produces two evidenced shapes but is inactive/incompatible. |
| `Notification` | Intended server → client | Client finds it optionally but has no listener/use. Payload unknown. |

No RemoteFunction reference exists. No `InvokeServer`, `OnServerInvoke`, or active server gameplay remote listener was found.

## 2. Existing Client-to-Server Action Names

There is no generic action envelope in surviving client code. Exact requests are:

```lua
PressCore:FireServer()
BuyUpgrade:FireServer(upgrade.id)
RequestRebirth:FireServer()
ClaimDailyReward:FireServer()
ClaimPlaytimeReward:FireServer()
```

`QuestAction` is only resolved; no action identifier or call survives. `UpgradeAction`, `RebirthAction`, and `DataAction` do not exist. Game-pass buttons call `MarketplaceService:PromptGamePassPurchase` locally rather than a gameplay remote.

## 3. Existing Server-to-Client Events

- `DataSync`: exact recovered allowlisted main packet, currently built by SessionRepository and sent by ServerDataService.
- `QuestSync`: exact recovered quest-domain packet, but no recovered client listener.
- `PressFeedback`: client reads optional lower-camel fields `reward`, `rarityName`, `rarityColor`, and `rarityIndex`. Defaults are 0, COMMON, gray, and 1.
- `RarityBroadcast`: client reads `playerName`, `rarityName`, `rarityColor`, and `reward`.
- `FactoryEvolutionSync`: recovered global `{serverStage, stageName}` and player `{playerStage, stageName, stageDescription, isUpgrade=true}`.
- `Notification`: no confirmed payload/listener.

Phase B press-only sends `DataSync` through ServerDataService after mutation and always sends the exact PressFeedback shape `{reward, rarityName, rarityColor, rarityIndex}`. The rarity fields use fixed COMMON values from the confirmed first Config rarity entry: name `"COMMON"`, its configured color, and index `1`. This is presentation-only and does not claim a rarity roll occurred.

## 4. Confirmed Press/Click Behavior

Confirmed:

- The UI press button fires `PressCore` with no payload.
- `ClickPower` is one of the four persisted upgrade IDs and its recovered display contract says it increases energy per press.
- Main sync exposes derived `ClickPower`.
- PressFeedback presents a server-provided reward.
- Recovered SecurityService maintains a one-second sliding press limit using `Config.MaxPressesPerSecond`.
- Persisted schema contains `Energy`, `LifetimeEnergy`, and `TotalPresses`.

Not confirmed:

- An original server press handler.
- Whether every press performs a luck roll.
- Whether CoreAmplifier applies to manual presses.
- Reward rounding order, history insertion, rarity counters, broadcast thresholds, achievement progress, or factory progression timing.

## 5. Confirmed Energy Calculation

The only approved shared derived formula is WP-03:

```lua
ClickPower = (1 + ClickPowerLevel) * getRebirthMultiplier(Rebirths)
getRebirthMultiplier(r) = 1 + r * 0.5
```

Both formulas are marked `RECOVERY_PROVISIONAL`; they are approved recovery contracts, not recovered original balance. `UpgradeDefinitions.calculateStats` caps ClickPower at `Config.Security.MaxEnergy`.

No surviving code explicitly states `pressReward = ClickPower`. The ClickPower name/description and client presentation make it the narrowest compatible inference. WP-07A must mark this mapping `RECOVERY_PROVISIONAL` and calculate:

```lua
rawReward = UpgradeDefinitions.calculateStats(data.UpgradeLevels, data.Rebirths).ClickPower
minimumReward = max(1, floor(rawReward))
reward = clamp(minimumReward, 0, Config.Security.MaxRewardPerPress)
newEnergy = clamp(data.Energy + reward, 0, Config.Security.MaxEnergy)
newLifetimeEnergy = clamp(data.LifetimeEnergy + reward, 0, Config.Security.MaxEnergy)
newTotalPresses = min(data.TotalPresses + 1, MAX_SAFE_INTEGER)
```

If ClickPower or the configured caps are invalid/non-finite, fail closed without mutation. The minimum of 1 is applied before every cap and mutation. Reward is computed by the server; the client supplies nothing.

## 6. Confirmed Upgrade Purchase Behavior

Confirmed evidence:

- Client sends exactly one `upgrade.id` through BuyUpgrade.
- Exact IDs are ClickPower, AutoPower, CoreAmplifier, and Luck.
- Client displays current level and `Config.getUpgradeCost(id, level)`.
- Recovered SecurityService rejects unknown IDs, configured/global max levels, and insufficient Energy.
- `UpgradeDefinitions.canLevelUp` is the approved fail-closed level eligibility contract.

No server mutation survives. Deducting cost and incrementing level are strongly implied but not executable recovered evidence. Atomic ordering, feedback/error protocol, and whether a purchase triggers other systems remain unconfirmed. Upgrade handling is deferred to WP-07B.

## 7. Upgrade Price Formulas

Approved recovery-provisional Config formula:

```lua
floor(baseCost * costGrowth ^ floor(currentLevel))
```

Values:

| ID | Base | Growth | Max |
| --- | ---: | ---: | ---: |
| ClickPower | 10 | 1.15 | 100 |
| AutoPower | 50 | 1.16 | 100 |
| CoreAmplifier | 250 | 1.17 | 100 |
| Luck | 500 | 1.18 | 100 |

All values are `RECOVERY_PROVISIONAL`. Costs cap at `Config.Security.MaxEnergy`. No original price table/formula survives.

## 8. Upgrade Max-Level Behavior

Eligibility requires a configured supported ID and:

```lua
currentLevel < min(upgrade.maxLevel, Config.Security.MaxUpgradeLevel)
```

Missing definitions, invalid maxLevel, and maxLevel 0 fail closed. Persisted levels are normalized to the same effective cap. Client display is advisory only. WP-07B must re-read the current server level on every request and never accept a client level/cost.

## 9. Confirmed Rebirth Behavior

Confirmed:

- Client sends RequestRebirth with no payload.
- Client displays Config rebirth cost and next multiplier.
- Recovered SecurityService checks Energy against cost and Rebirths against MaxRebirths.
- UpgradeDefinitions applies a rebirth multiplier to ClickPower and AutoPower.
- Client text says rebirth resets upgrades and grants permanent multipliers.

No authoritative mutation survives. Exact reset fields, retained currencies, reward Gems, factory effects, history effects, and feedback are unknown. The client incorrectly shows success immediately after sending. Rebirth is deferred to WP-07C.

## 10. Rebirth Requirements and Rewards

Approved recovery-provisional requirement:

```lua
cost = floor(10_000 * 1.75 ^ currentRebirths)
```

Cap: `Config.Security.MaxRebirths = 100`, also provisional.

Approved derived multiplier:

```lua
1 + rebirthCount * 0.5
```

Unknown and unresolved:

- Whether Energy becomes zero or cost is merely deducted.
- Which/all upgrade levels reset.
- Whether Gems or another currency is awarded.
- Whether LifetimeEnergy resets.
- Whether FactoryStage resets while HighestFactoryStage remains.
- Rebirth response/notification protocol.

No rebirth mutation may be implemented until these are approved.

## 11. Factory-Stage Mutation Behavior

Recovered FactoryEvolution calculates a stage using LifetimeEnergy/Rebirths, and on increase writes both `HighestFactoryStage` and `FactoryStage`. It never decreases either and broadcasts FactoryEvolutionSync. FactoryDefinitions now contains the approved six thresholds and OR rules.

The recovered script is unusable with canonical sessions because it passes userId, reads uppercase wrapper fields, and omits revision marking. The obsolete current FactoryService uses a different Config and ignores Rebirths/HighestFactoryStage.

WP-07A must not mutate factory fields even when a press crosses a threshold. Factory progression is deferred to WP-07E or WP-08 coordination so visual behavior, revision/sync ordering, and duplicate notifications can be reviewed together.

## 12. Reward and Claim Behavior

Confirmed validation fragments:

- Daily claim requires elapsed time at least `Config.DailyReward.CooldownHours * 3600` since LastClaim.
- Playtime claim requires `TotalPlaytime >= Config.PlaytimeReward.Intervals[Index]` and Index within the configured array.
- Client sends both claim remotes with no payload.
- Config contains provisional Gem arrays for seven daily and four playtime entries.

Unknown:

- Streak rollover/reset rules and timezone boundary.
- Which daily reward index derives from Streak.
- When/how TotalPlaytime increments and whether it is session/cumulative time.
- Claim timestamp/index mutation ordering.
- Duplicate request response and notification payloads.
- Whether Gems arrays are final.

Claims are deferred to WP-07D. DailyLogin is a separate unresolved system.

## 13. Current SecurityService API

Recovered API:

```text
isDataLoaded(player)
isDataFailed(player)
validateNumber(value, min, max)
validateEnergy(value)
validateGems(value)
validateRebirths(value)
validateUpgradeLevel(value)
validateLuck(value)
validateCoreAmplifier(value)
validateReward(value)
canPress(player)
clearPlayer(player)
canBuyUpgrade(upgradeId, currentLevel)
validateUpgrade(data, upgradeId)
validateRebirth(data)
validateDailyReward(data)
validatePlaytimeReward(data)
clampEnergy(energy)
clampGems(gems)
```

It is recovered Studio source only and is not active under `src`.

## 14. SecurityService Compatibility Gaps

- Requires obsolete `ReplicatedStorage.Shared.Config` and `ServerStorage.SessionManager` paths.
- Uses recovered SessionManager state API rather than canonical SessionRepository/B1 contract.
- Does not understand Saving/finalizing/released metadata or revision invariants.
- `validateNumber` accepts numeric strings, preserves fractions, and does not explicitly reject both infinities.
- Upgrade/reward validators assume nested tables are present and canonical.
- `canPress` uses UserId state but cleanup must be called externally; no lifecycle connection survives.
- It does not perform mutations, rollback, markDirty, or sync.
- It has no payload-shape validation or result-code contract.
- It is not dependency-injected and would create a second authority boundary if copied wholesale.

WP-07A should implement only a focused private press limiter/validation inside the remote controller. Do not reactivate or broadly port SecurityService.

## 15. Session Loaded-State Requirements

Every mutation requires:

- valid exact Player;
- `SessionRepository.getSession(player)` returns the exact live wrapper;
- `session.state == "Loaded"` only;
- `saveInFlight == false`;
- `finalizeRequested == false`;
- finite non-negative integer revisions with `savedRevision <= revision`;
- `dirty == (revision > savedRevision)`;
- canonical required data fields/types for the specific mutation.

Saving, Loading, LoadFailed, Released, finalizing, absent, or malformed sessions fail without mutation. B1 allows markDirty while Saving, but gameplay policy is intentionally stricter.

## 16. Canonical Mutation Flow

For WP-07A:

```text
PressCore.OnServerEvent(player, ...)
  → require zero payload arguments
  → server rate-limit exact Player
  → GameplayService.press(player)
      → validate exact Loaded canonical session
      → derive ClickPower from server-owned levels/rebirths
      → apply max(1, floor(ClickPower)), then cap reward
      → capture old Energy/LifetimeEnergy/TotalPresses
      → mutate those three fields synchronously
      → ServerDataService.markDirty(player)
      → if dirty marking fails: rollback all three fields and fail
      → ServerDataService.syncToClient(player)
      → return immutable/detached `{reward}` result
  → on success FireClient PressFeedback with `{reward, rarityName="COMMON", rarityColor=<Config COMMON color>, rarityIndex=1}`
```

Sync failure does not roll back a valid dirty mutation; the next sync can recover presentation. PressFeedback is sent only after mutation and dirty marking succeed.

## 17. Revision-Aware Dirty Marking

Every successful persisted mutation calls `ServerDataService.markDirty(player)` exactly once. GameplayService must never write revision, savedRevision, or dirty directly.

Because WP-07A has no yielding operation between session validation, mutation, and markDirty, lifecycle state cannot normally change mid-transaction. Nevertheless, the service records old field values and restores them if markDirty returns failure. A failed/no-op request does not increment revision or sync.

## 18. Client Synchronization Behavior

- Call `ServerDataService.syncToClient(player)` only after markDirty succeeds.
- B1/SessionRepository constructs and clones the allowlisted canonical DataSync packet.
- Do not expose session wrappers, revision metadata, FirstJoin, DataVersion, or unknown fields.
- The press request result remains successful if DataSync callback fails; return/report sync status only internally.
- PressFeedback always contains server-derived reward plus explicit fixed COMMON `rarityName`, `rarityColor`, and `rarityIndex`; it never relies on client defaults.
- Do not send QuestSync, RarityBroadcast, FactoryEvolutionSync, or Notification in WP-07A.

## 19. Rate-Limiting Requirements

Use a server-maintained sliding one-second window based on `os.clock()` and `Config.MaxPressesPerSecond`.

- State keyed by exact Player in a weak-key table, preventing long-lived Player retention without another lifecycle connection.
- Validate Config limit as a finite positive integer at initialization; invalid configuration disables/fails controller initialization rather than allowing unlimited requests.
- Prune timestamps older than one second before checking count.
- Reject when count is already at the limit.
- Record an accepted attempt before calling GameplayService to bound malformed gameplay-state spam after payload validation.
- Rate-limit rejection causes no mutation, dirty mark, sync, feedback, or detailed client error.
- No client timestamp, sequence, rate, or elapsed value is accepted.

The current `MaxPressesPerSecond = 12` is `RECOVERY_PROVISIONAL`.

## 20. Numeric Normalization and Caps

- Persisted numeric inputs must already be finite non-negative integers; malformed live data fails closed rather than being repaired by gameplay code.
- Derived ClickPower must be finite and non-negative; compute `max(1, floor(ClickPower))` before applying any cap.
- Per-press reward caps at `Config.Security.MaxRewardPerPress`.
- Energy and LifetimeEnergy cap independently at `Config.Security.MaxEnergy`.
- TotalPresses caps at Luau's safe integer `9_007_199_254_740_991`; this is a technical bound, not balance.
- Do not accept numeric strings, booleans, NaN, infinity, fractions, or client-authored numbers.
- Saturating fields still produce a successful press only if reward is valid; TotalPresses advances until its technical cap.

## 21. Replay and Duplicate-Request Risks

- Press requests are intentionally repeatable and have no request ID; rate limiting is the replay defense.
- RemoteEvent ordering is per-client but should not be treated as a transaction identifier.
- Multiple rapid upgrade requests must later recompute current level/cost each time; never trust displayed client state.
- Claims need server timestamps and atomic eligibility/mutation to stop duplicate rewards.
- Rebirth needs server state revalidation for every request.
- No handler may yield between validation and mutation under the memory-backed Phase B design.
- Cross-server replay/duplication remains a production persistence concern and is deferred.

## 22. Remote Payload Validation

| Remote | Accepted payload |
| --- | --- |
| PressCore | Exactly zero arguments. Any extra value, including nil explicitly present, fails. |
| BuyUpgrade (future) | Exactly one non-empty supported string ID; no level/cost. |
| RequestRebirth (future) | Exactly zero arguments. |
| ClaimDailyReward (future) | Exactly zero arguments. |
| ClaimPlaytimeReward (future) | Exactly zero arguments. |
| QuestAction | Unresolved; no handler until action names/schema are recovered or approved. |

Remote handlers never accept tables for WP-07A. Malformed payloads fail silently/minimally and do not log packet contents.

## 23. Exact Proposed GameplayService API

Source: `src/server/Services/GameplayService.lua`.

Export exactly:

```lua
GameplayService.init(dependencies: Dependencies): ()
GameplayService.press(player: Player): (boolean, ResultCode, PressResult?)
```

```lua
export type Dependencies = {
    sessions: SessionRepository,
    dataService: ServerDataService,
}

export type ResultCode =
    "OK"
    | "INVALID_PLAYER"
    | "NOT_FOUND"
    | "NOT_LOADED"
    | "BUSY"
    | "INVALID_DATA"
    | "INVALID_REWARD"
    | "DIRTY_FAILED"

export type PressResult = {
    reward: number,
    syncSucceeded: boolean,
}
```

Rules:

- init validates exactly two dependencies; identical re-init no-ops, conflicting re-init errors.
- Module directly requires current `LCA_Shared.Config` and `UpgradeDefinitions`; no bridge.
- press accepts Player only, never userId or reward.
- Returned result is fresh/frozen or scalar-only and exposes no data/session reference.
- No generic mutate/getData API is exported.

## 24. Exact Proposed Remote-Handler Module

Source: `src/server/Services/GameplayRemoteController.lua`.

Export exactly:

```lua
GameplayRemoteController.init(dependencies: Dependencies): ()
```

```lua
export type Dependencies = {
    pressCore: RemoteEvent,
    pressFeedback: RemoteEvent,
    gameplayService: GameplayService,
}
```

Responsibilities:

- Validate exact dependencies and idempotent initialization.
- Own only the PressCore OnServerEvent connection.
- Validate zero payload arguments.
- Apply the private server rate limiter.
- Call GameplayService.press.
- On success send exact `{reward=result.reward, rarityName="COMMON", rarityColor=Config.LuckRarities[1].color, rarityIndex=1}` through PressFeedback.
- Never access SessionRepository, Config balances, or gameplay data directly.
- Never discover remotes, connect lifecycle events, or expose callbacks/maps.

## 25. Dependency-Injection Design

```text
Main.server
  ├─ GameplayService.init({
  │      sessions = SessionRepository,
  │      dataService = ServerDataService,
  │  })
  └─ GameplayRemoteController.init({
         pressCore = confirmed RemoteEvent,
         pressFeedback = confirmed RemoteEvent,
         gameplayService = GameplayService,
     })
```

GameplayService owns authoritative rules/mutation. Controller owns transport/payload/rate validation. Main owns exact RemoteEvent discovery. SessionRepository remains the only data owner; ServerDataService remains the only revision/sync orchestrator.

## 26. Main.server Integration Strategy

Extend the existing WP-06B3 composition root:

1. Require GameplayService and GameplayRemoteController.
2. Validate exact `ReplicatedStorage.Remotes.PressCore` and `PressFeedback` as RemoteEvents alongside existing sync remotes.
3. Initialize ServerDataService as today.
4. Initialize GameplayService.
5. Initialize GameplayRemoteController.
6. Initialize DataLifecycleService last, so existing players load only after gameplay dependencies/listeners are ready.

Do not create remotes or touch other request events in WP-07A.

## 27. Compatibility with SessionRepository

- Uses only `getSession(player)` and the live wrapper required by B1.
- Requires lowercase `session.data`/`session.state` and exact Player identity.
- Mutates only Energy, LifetimeEnergy, and TotalPresses in WP-07A.
- Does not expose the wrapper or unknown legacy fields.
- Does not call create/remove/migrate/packet builders.
- SessionRepository remains the sole in-memory owner.

The live-wrapper boundary is trusted-server-only and remains an architectural risk; no remote controller receives it.

## 28. Compatibility with ServerDataService

- Calls only `markDirty(player)` and `syncToClient(player)`.
- Does not call load, save, finalize, init, or quest sync.
- Enforces Loaded-only gameplay even though B1 markDirty also supports Saving.
- Rolls back field mutations if markDirty fails.
- Does not alter revision metadata directly.
- Relies on B1 sync packet isolation and callbacks.

## 29. Explicitly Deferred Gameplay Systems

Split Phase B into:

- **WP-07A:** press-only vertical slice described here.
- **WP-07B:** upgrade purchase mutation and response protocol.
- **WP-07C:** rebirth after reset/reward semantics are approved.
- **WP-07D:** daily/playtime claims after time/streak ownership is approved.
- **WP-07E:** authoritative factory-stage progression, coordinated with WP-08 FactoryEvolution repair.

Also deferred: AutoPower ticking, CoreAmplifier production, luck/rarity rolling, History, RarityCount, rarity broadcasts, achievements, quests, collections, DailyLogin, monetization/receipts, game passes, notifications, DataStore/autosave/retries/leases, FactoryEvolution repair, MainGuiClient repair, and Shared compatibility work.

## 30. Phase B Implementation Allowlist

Proposed WP-07A allowlist:

- `src/server/Main.server.lua`
- `src/server/Services/GameplayService.lua`
- `src/server/Services/GameplayRemoteController.lua`
- `tests/manual/WP-07A_PressGameplay.md`
- `CHANGELOG.md`

Do not modify ServerDataService, SessionRepository, lifecycle/persistence modules, legacy services, shared modules, recovered code, client code, project mapping, or RemoteEvent Instances.

## 31. Manual Test Plan

### Service authority and state

- Module loads without connections or mutation.
- Exact API and dependency validation/idempotence.
- Invalid Player/userId, absent, Loading, Saving, LoadFailed, finalizing, Released, and malformed sessions fail unchanged.
- Loaded canonical session succeeds.
- No session/data/revision reference leaks.

### Press calculation and mutation

- Baseline level/rebirth produces the reviewed provisional reward.
- ClickPower levels and rebirths use UpgradeDefinitions exactly.
- CoreAmplifier/Luck/AutoPower do not affect WP-07A reward.
- Reward, Energy, LifetimeEnergy, and TotalPresses cap tests.
- Invalid/non-finite/fractional live fields fail closed.
- Successful press changes exactly three persisted fields.
- markDirty called exactly once and revision increments once.
- markDirty failure restores all three old fields.
- sync occurs only after dirty success; sync failure does not roll back.

### Remote and rate security

- Main validates exact PressCore/PressFeedback Instances before lifecycle starts.
- Controller registers one handler; identical init no-ops, conflicting init errors.
- Zero arguments accepted; every extra/malformed argument rejected.
- Sliding window below/at/after boundary.
- Per-Player isolation and weak-key ownership.
- Rejected/rate-limited requests do not mutate, dirty, sync, or feedback.
- Successful feedback always has exactly reward plus fixed COMMON name, configured color, and index 1.
- Client cannot supply reward, stats, balances, level, rarity, or timestamp.

### Integration/exclusions

- New player loads via B3, press mutates canonical data, DataSync updates client, memory finalization saves snapshot, same-server rejoin reads it.
- PlayerDataService/EnergyService/FactoryService remain inactive.
- Other gameplay remotes receive no listeners.
- No DataStore, autosave, retry, lease, factory/client repair, quest/reward/upgrade/rebirth logic, or full-data logging.
- `git diff --check` and Rojo build pass with only allowlisted changes.

## 32. Unresolved Gameplay and Balance Values

- Original press reward formula and whether ClickPower maps directly to reward.
- Whether CoreAmplifier applies to press, auto, factory, or all production.
- Luck odds/roll algorithm and whether every press rolls.
- Rarity history retention, counters, broadcasts, and reward multiplier order.
- Original upgrade costs/formulas and balance caps.
- Rebirth reset set, currency reward, retained fields, and factory effects.
- Daily streak/reset timezone and reward index.
- Playtime accumulation ownership/reset and claim sequence.
- Factory progression timing relative to press/rebirth and visual broadcasts.
- Error/notification protocol for rejected gameplay actions.
- Whether TotalPresses counts valid presses at saturated Energy and/or rate-limited attempts.
- Press-at-cap counting behavior remains recovery-provisional: a valid accepted press advances TotalPresses even when Energy and LifetimeEnergy are saturated.

Chief Architect approval fixes WP-07A reward normalization as `max(1, floor(ClickPower))` before caps and requires an explicit fixed-COMMON four-field PressFeedback packet.
