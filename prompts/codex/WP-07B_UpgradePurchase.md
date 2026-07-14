# WP-07B — Authoritative Single-Upgrade Purchase Design

## Mission and Evidence Boundary

Design the smallest authoritative `BuyUpgrade` vertical slice on the approved WP-06 lifecycle and WP-07A gameplay server. The recovered client confirms a one-ID request, while the approved shared modules define supported IDs, costs, and level eligibility. No active or recovered authoritative purchase mutation survives.

WP-07B therefore extends the existing `GameplayService`, `GameplayRemoteController`, and `Main.server.lua`. It does not change shared definitions or add gameplay systems.

## 1. Exact BuyUpgrade Payload

The accepted call is exactly:

```lua
BuyUpgrade:FireServer(upgradeId)
```

The server receives exactly one argument after the implicit `Player`. It must verify `select("#", ...) == 1` before dispatch. That sole argument must be an exact supported string. No envelope or additional field is accepted.

The recovered client already uses this contract at `buyUpgradeEvent:FireServer(upgrade.id)`. Client-provided levels, prices, balances, max levels, quantities, timestamps, or request metadata are forbidden.

## 2. Supported Upgrade IDs

Accept exactly these case-sensitive saved-data IDs:

1. `ClickPower`
2. `AutoPower`
3. `CoreAmplifier`
4. `Luck`

Use a private allowlist in the server gameplay implementation. Do not derive request validity solely from arbitrary Config entries. This preserves the canonical four-key `UpgradeLevels` schema.

## 3. Session-State Requirements

Every purchase requires:

- a valid exact `Player` Instance;
- `SessionRepository.getSession(player)` returning that Player's live wrapper;
- `session.player == player` and `session.userId == player.UserId`;
- valid revision metadata and `dirty == (revision > savedRevision)`;
- `session.state == "Loaded"` exactly;
- `session.saveInFlight == false`;
- `session.finalizeRequested == false`;
- canonical tables and fields required by the purchase.

Absent, Loading, Saving, LoadFailed, Released, finalizing, busy, or malformed sessions fail without mutation. Although `ServerDataService.markDirty` supports Saving, WP-07 gameplay deliberately does not.

## 4. Current-Level Source

Read the current level only from:

```lua
session.data.UpgradeLevels[upgradeId]
```

It must be a finite non-negative integer. The handler must re-read it for every accepted remote request. It must never use the client cache, UI text, request payload, or an earlier request's result.

## 5. Cost Calculation Source

Calculate the price server-side for every request:

```lua
local cost = Config.getUpgradeCost(upgradeId, currentLevel)
```

The approved Config calculation is `floor(baseCost * costGrowth ^ currentLevel)`, capped by `Config.Security.MaxEnergy`. Its balance inputs are `RECOVERY_PROVISIONAL`; WP-07B must not copy or alter them.

For a supported, configured, eligible upgrade, the returned cost must be a finite integer in `1..Config.Security.MaxEnergy`. A zero, negative, fractional, NaN, infinite, or over-cap result is invalid configuration and fails closed. In particular, a zero result must never grant a free purchase.

## 6. Max-Level Eligibility

Use the approved shared contract:

```lua
UpgradeDefinitions.canLevelUp(upgradeId, currentLevel)
```

It applies the effective limit:

```text
min(upgrade.maxLevel, Config.Security.MaxUpgradeLevel)
```

Before classifying a false result from `canLevelUp`, server gameplay must validate that exactly one supported `Config.Upgrades` entry exists, that its `maxLevel` is a finite non-negative integer, and that `Config.Security.MaxUpgradeLevel` is a finite non-negative integer. Then calculate:

```lua
local effectiveLimit = math.min(upgrade.maxLevel, Config.Security.MaxUpgradeLevel)
```

Classify the result in this order:

- missing, duplicate, or malformed configuration: `INVALID_DATA`;
- `currentLevel >= effectiveLimit`: `MAX_LEVEL`;
- `currentLevel < effectiveLimit` while `canLevelUp` is false: `INVALID_DATA`;
- otherwise continue purchase validation.

This ensures a fail-closed helper result is not automatically mislabeled as a normal max-level condition. Server gameplay must also validate the live level as a canonical finite integer; it must not rely on the helper's normalization to repair corrupted session data.

## 7. Energy Validation

Read Energy only from `session.data.Energy`. It must be a finite non-negative integer no greater than the validated finite positive integer `Config.Security.MaxEnergy`.

After calculating a valid cost, require:

```lua
data.Energy >= cost
```

Insufficient Energy fails unchanged. Never accept a client balance or precomputed affordability flag.

## 8. Exact Mutation Fields

A successful purchase mutates exactly:

```lua
data.Energy = oldEnergy - cost
data.UpgradeLevels[upgradeId] = oldLevel + 1
```

No other persisted or session field is gameplay-authored. In particular, do not directly write `revision`, `savedRevision`, `dirty`, factory fields, stats, rewards, history, quests, or collection data.

## 9. Atomic Mutation Order

Within one non-yielding service call:

1. Validate the exact Player, session identity, Loaded state, metadata, Config caps, and required data shape.
2. Validate the exact supported ID.
3. Read the latest Energy and current level.
4. Validate the exact Config entry and calculate its effective limit.
5. Classify max-level versus malformed `canLevelUp` failure in the binding order above.
6. Calculate and validate the server cost.
7. Check Energy affordability.
8. Capture `oldEnergy` and `oldLevel`.
9. Calculate `newEnergy` and `newLevel` only from the validated values.
10. Assign Energy and the selected level.
11. Call `ServerDataService.markDirty(player)` exactly once.
12. On dirty success, call `ServerDataService.syncToClient(player)`.

No operation before the sync is expected to yield with the current memory-backed dependencies. Do not call external commerce, persistence, or lifecycle APIs.

## 10. markDirty Behavior

For each successful two-field mutation, call:

```lua
dataService.markDirty(player)
```

exactly once. `ServerDataService` alone increments `revision` and updates the compatibility `dirty` mirror. Gameplay code never writes revision metadata directly.

Validation failures and rejected remote requests call `markDirty` zero times.

## 11. Rollback Behavior

If `markDirty` returns failure, restore both captured fields:

```lua
data.Energy = oldEnergy
data.UpgradeLevels[upgradeId] = oldLevel
```

Return `DIRTY_FAILED`; do not sync. Rollback must restore the same selected entry without replacing `UpgradeLevels` or disturbing unknown nested fields.

If DataSync later fails, do not roll back a valid dirty purchase. The authoritative mutation is already committed in memory and a later sync can repair presentation.

## 12. DataSync Behavior

Call `ServerDataService.syncToClient(player)` only after `markDirty` succeeds. The existing SessionRepository builder recalculates stats and sends a fresh allowlisted main packet, including Energy, derived stats, and the four upgrade levels.

Exactly one sync attempt is made per successful purchase. Sync failure is retained only in the internal result's `syncSucceeded` value; it does not invalidate or roll back the purchase. Failed purchases produce no sync.

## 13. Purchase Feedback Decision

Do not add a feedback RemoteEvent in WP-07B. Success is reflected through `DataSync`, which already drives the recovered client's Energy, level, cost, and derived-stat display.

Failures are silent to the client: no Notification, PressFeedback reuse, DataSync echo, or client-authored error detail. The service may return deterministic server-internal result codes for testing and control flow, but the controller must not send those codes to the client.

## 14. Invalid ID Handling

Reject all values outside the exact four-ID allowlist, including:

- empty or whitespace strings;
- case variants such as `clickpower`;
- display names such as `Click Power`;
- legacy or guessed IDs;
- arbitrary Config IDs added in the future without a reviewed schema change.

Rejection is fail-closed and silent: no cost calculation, mutation, dirty mark, or sync.

## 15. Malformed Payload Handling

Reject:

- zero arguments;
- explicit `nil` as the one argument;
- more than one argument, including trailing `nil`;
- numbers, booleans, tables, functions, Instances, and userdata;
- empty strings and unsupported strings.

Payload shape and ID allowlist validation occur in the remote controller before rate-limit admission and service dispatch. GameplayService repeats supported-ID validation as a trusted-server API boundary.

Malformed requests produce no mutation, response, detailed log, or packet-content log.

## 16. Independent Rate Limit

`BuyUpgrade` receives a private one-second sliding-window limiter in `GameplayRemoteController`:

- a separate weak-key `{ [Player]: { number } }` timestamp map;
- no reads or writes to the existing press timestamps;
- server `os.clock()` timestamps only;
- prune entries older than one second;
- reject once the current window reaches its limit;
- record an accepted attempt before calling GameplayService.

No dedicated upgrade-request Config value exists. Phase B should use `Config.MaxPressesPerSecond` as the only currently approved finite positive request ceiling, while keeping a completely independent bucket. This reuse is a `RECOVERY_PROVISIONAL` transport limit, not a claim that press and purchase balance rates are identical. A later dedicated Config field requires separate review.

Invalid payloads do not consume the purchase bucket. Valid but unaffordable, maxed, busy, or otherwise rejected service attempts do consume it, limiting server work and probing.

## 17. Rapid Repeated Purchase Behavior

Every admitted request independently:

- retrieves the current live session;
- re-reads the selected level and Energy;
- reruns max-level eligibility;
- recalculates the new cost;
- rechecks affordability.

Do not cache level, cost, or Energy in the controller. Do not infer state from a prior DataSync. Current RemoteEvent service calls and the proposed mutation path do not yield, so each request observes the previous completed mutation. Requests stop succeeding as soon as Energy is insufficient or the effective max is reached.

No bulk-buy, queue, debounce-based coalescing, request ID, or client quantity is introduced.

## 18. Numeric and Cap Validation

Before mutation, require:

- `Config.Security.MaxEnergy`: finite positive integer within Luau's safe integer bound;
- current Energy: finite integer in `0..MaxEnergy`;
- current level: finite non-negative integer;
- exactly one matching Config entry with finite non-negative integer `maxLevel`;
- finite non-negative integer `Config.Security.MaxUpgradeLevel`;
- configured effective level limit: calculated explicitly and independently verified through `canLevelUp`;
- cost: finite integer in `1..MaxEnergy`;
- `oldLevel + 1`: within the effective configured/global limit;
- `oldEnergy - cost`: a finite non-negative integer.

Because subtraction occurs only after `Energy >= cost`, it cannot underflow. Because `canLevelUp` is true before adding one, level increment cannot exceed the effective cap. Numeric strings, fractions, NaN, and infinities in live data fail closed rather than being normalized by gameplay code.

## 19. Proposed GameplayService API Addition

Source: `src/server/Services/GameplayService.lua`.

Keep the existing API and add exactly:

```lua
GameplayService.buyUpgrade(
    player: Player,
    upgradeId: string
): (boolean, ResultCode, UpgradePurchaseResult?)
```

Add these service result codes:

```lua
"INVALID_UPGRADE"
"MAX_LEVEL"
"INVALID_COST"
"INSUFFICIENT_ENERGY"
```

Existing state/data/dirty result codes remain unchanged.

```lua
export type UpgradePurchaseResult = {
    upgradeId: string,
    cost: number,
    newLevel: number,
    syncSucceeded: boolean,
}
```

The result is a fresh frozen scalar-only table for trusted server control/tests. It exposes no session, data table, or revision metadata. The method accepts no level, cost, balance, quantity, or max-level argument.

## 20. Proposed GameplayRemoteController Addition

Source: `src/server/Services/GameplayRemoteController.lua`.

Extend its dependency contract with:

```lua
buyUpgrade: RemoteEvent
```

Extend its GameplayService dependency type with `buyUpgrade(player, upgradeId)`. `init` must validate `buyUpgrade` as an exact RemoteEvent and include it in identical/conflicting reinitialization checks.

Connect exactly one new listener:

```lua
buyUpgrade.OnServerEvent:Connect(onBuyUpgrade)
```

`onBuyUpgrade` owns exact argument-count/type/ID validation and the independent limiter, then invokes `GameplayService.buyUpgrade`. It does not access sessions, calculate prices, mutate data, sync remotes, or send a response. Preserve the existing PressCore listener and PressFeedback behavior unchanged.

## 21. Main.server Wiring

In `src/server/Main.server.lua`:

1. Resolve `ReplicatedStorage.Remotes.BuyUpgrade` with `FindFirstChild`.
2. Assert that it is a RemoteEvent before gameplay/lifecycle initialization.
3. Keep ServerDataService and GameplayService initialization unchanged.
4. Inject `buyUpgrade = buyUpgrade` into `GameplayRemoteController.init` with the existing PressCore, PressFeedback, and GameplayService dependencies.
5. Keep `DataLifecycleService.init` last so listeners are ready before existing-player loading.

Main must not create a RemoteEvent or discover any unrelated gameplay remote. The Studio `BuyUpgrade` Instance is confirmed to exist; payload and server listener are the WP-07B responsibility.

## 22. Exact Phase B Allowlist

Proposed WP-07B implementation allowlist:

- `src/server/Main.server.lua`
- `src/server/Services/GameplayService.lua`
- `src/server/Services/GameplayRemoteController.lua`
- `tests/manual/WP-07B_UpgradePurchase.md`
- `CHANGELOG.md`

The approved Phase A specification may be included in a later commit only when a final-validation instruction explicitly authorizes it. Do not modify Config, UpgradeDefinitions, SessionRepository, ServerDataService, lifecycle/persistence modules, recovered code, client code, project mapping, or Studio Instances in Phase B.

## 23. Manual Test Plan

### Contract and authority

- Modules load without new require-time side effects.
- Existing APIs remain; `buyUpgrade` is the only GameplayService addition.
- Exact four IDs succeed when eligible; every case variant, display name, legacy ID, empty/whitespace string, and unknown ID fails.
- Controller accepts exactly one string argument; zero, explicit nil, extra/trailing nil, and all non-string values fail.
- Client-supplied levels, costs, balances, max levels, and quantities cannot be supplied or used.

### Session and numeric validation

- Invalid Player, wrong Player object, absent session, Loading, Saving, LoadFailed, Released, finalizing, and save-in-flight sessions fail unchanged.
- Revision/dirty mismatch and malformed data tables fail closed.
- Energy and level reject negatives, fractions, numeric strings, NaN, and both infinities.
- Invalid/non-finite/fractional/zero Config cap or calculated cost fails closed.
- Cost is recalculated from the latest server level every attempt.
- Missing, duplicate, or malformed Config definitions return `INVALID_DATA`.
- A level at/above a valid effective limit returns `MAX_LEVEL`.
- A false `canLevelUp` below a valid effective limit returns `INVALID_DATA`.

### Mutation, dirty marking, and synchronization

- Exact cost is deducted and exactly the chosen level increments once.
- Other upgrade levels and all other persisted fields remain unchanged.
- `markDirty` is called exactly once after both assignments.
- Dirty failure restores Energy and the chosen level exactly and does not sync.
- Dirty success makes exactly one DataSync attempt.
- Sync failure does not roll back and is reported only in the internal result.
- Result is frozen/scalar-only and contains the exact ID, cost, new level, and sync status.
- GameplayService never writes revision, savedRevision, or dirty directly.

### Rate limit and rapid requests

- Upgrade and press timestamp buckets are independent per exact Player.
- Below-limit, at-limit, and one-second expiry boundaries behave deterministically.
- Malformed payloads do not consume the upgrade bucket.
- Valid but rejected service attempts consume it.
- Sequential rapid purchases re-read level/Energy and recalculate increasing costs.
- Purchases stop at insufficient Energy or max level with no over-deduction/over-level.
- No bulk-buy or coalescing occurs.

### Integration and exclusions

- Main validates and injects the confirmed BuyUpgrade RemoteEvent before lifecycle initialization.
- Exactly one BuyUpgrade listener and the existing one PressCore listener are connected.
- Success is visible through DataSync; no new feedback remote or failure packet exists.
- No DataStore, autosave, retry, rewards, rebirth, claim, factory, rarity, quest, notification, commerce, or client behavior is added.
- Rojo build, `git diff --check`, and allowlist-only status pass.

## 24. Deferred Behavior and Unresolved UX

Deferred:

- bulk/multi-buy and purchase queues;
- success animations, purchase sounds, or a dedicated feedback event;
- client-visible failure reasons for insufficient Energy, max level, malformed requests, or rate limiting;
- a dedicated upgrade-request rate Config field;
- telemetry and security counters;
- AutoPower runtime production and CoreAmplifier effects;
- rebirths, daily/playtime claims, factory progression, rarity, quests, rewards, notifications, monetization, and receipts;
- DataStore persistence, autosave, retries, and cross-server leases;
- FactoryEvolution, MainGuiClient behavior repairs, and Shared/LCA_Shared compatibility work.

Unresolved UX concerns:

- DataSync is the only success acknowledgement, so packet loss/callback failure leaves the client temporarily stale even though the authoritative purchase succeeded.
- Silent failure gives no direct reason and may make fast clicks appear unresponsive.
- Reusing `Config.MaxPressesPerSecond` supplies a safe approved ceiling but is semantically coupled to press tuning; a dedicated reviewed value may be preferable later.
- All upgrade prices, growth factors, and max levels remain `RECOVERY_PROVISIONAL`, not recovered original balance.
