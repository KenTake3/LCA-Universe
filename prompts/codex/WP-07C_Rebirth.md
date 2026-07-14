# WP-07C — Authoritative Rebirth Investigation and Design

## Mission and Decision

Investigate the smallest safe authoritative `RequestRebirth` contract on the canonical WP-06/WP-07 services. The repository confirms the request shape, eligibility inputs, provisional cost/multiplier contracts, and that rebirth count affects derived stats and factory eligibility. It does not preserve an authoritative rebirth mutation.

**Decision: defer WP-07C runtime implementation.** Energy disposition and the exact upgrade reset set are fundamental transaction semantics and remain unconfirmed. Implementing only a counter increment, guessing cost deduction versus zeroing, or interpreting client copy as an exact reset schema would create irreversible saved-data behavior without sufficient evidence.

This Phase A package is design-only; no runtime implementation was performed.

## 1. Exact RequestRebirth Payload

The recovered client calls:

```lua
RequestRebirth:FireServer()
```

The eventual controller must accept exactly zero arguments after the implicit Player. `select("#", ...)` must equal zero. An explicit nil or any additional value is malformed.

Never accept client-provided cost, reward, multiplier, level, reset list, Energy, Rebirths, currency, timestamp, or factory stage.

## 2. Current Rebirths Source

The sole authoritative source is:

```lua
session.data.Rebirths
```

SessionRepository defaults it to `0`, normalizes it to a finite non-negative integer capped by `Config.Security.MaxRebirths`, and includes it in main and quest sync packets. Every eventual request must re-read the live Loaded session value; clientData is presentation-only.

## 3. Rebirth Cost Source and Formula

The server-side source is:

```lua
Config.getRebirthCost(currentRebirths)
```

Current approved recovery formula:

```text
floor(10,000 * 1.75 ^ floor(currentRebirths))
```

The result is capped at `Config.Security.MaxEnergy`. Base `10,000`, growth `1.75`, and the cap are `RECOVERY_PROVISIONAL`; they are not recovered original balance.

Recovered SecurityService also calls this function with `data.Rebirths`, then checks `data.Energy < cost`. The recovered client displays the same calculated cost but is not authoritative.

## 4. MaxRebirths Source

Use only `Config.Security.MaxRebirths`. The current value is `100` and is `RECOVERY_PROVISIONAL`.

An eventual service must require MaxRebirths to be a finite non-negative integer within Luau's safe integer bound. Missing, malformed, negative, fractional, NaN, or infinite configuration fails closed. `currentRebirths >= MaxRebirths` is a normal maxed condition; malformed live Rebirths is invalid data.

## 5. Energy Requirement

Confirmed eligibility is:

```lua
data.Energy >= Config.getRebirthCost(data.Rebirths)
```

Recovered SecurityService enforces it, and the client colors affordability from it. Energy must come from `session.data.Energy` and be a finite non-negative integer no greater than a valid `Config.Security.MaxEnergy`.

The cost must be recalculated server-side and validated as a finite positive integer in `1..MaxEnergy`. A zero or invalid cost must not permit a free rebirth.

## 6. Exact Confirmed Reset Fields

No exact reset field is confirmed by surviving authoritative mutation code.

The client sentence “Rebirth to reset upgrades and get permanent multipliers!” confirms only a high-level product intent that some upgrades reset. It does not define exact saved keys, reset values, exceptions, ordering, or whether all four current IDs were present when the text was authored.

Therefore the confirmed reset-field set is empty.

## 7. Exact Unresolved Reset Fields

Unresolved candidates include:

- `Energy`;
- `UpgradeLevels.ClickPower`;
- `UpgradeLevels.AutoPower`;
- `UpgradeLevels.CoreAmplifier`;
- `UpgradeLevels.Luck`;
- `FactoryStage`;
- possibly other progression state not named by surviving code.

There is no evidence that `LifetimeEnergy`, Gems, History, rarity records/counters, reward state, quests, achievements, collections, DailyLogin, TotalPresses, PurchasedPerks, or HighestFactoryStage reset. They must not be reset by inference.

## 8. Upgrade Reset Decision

Do not implement the reset yet.

Evidence for resetting upgrades is limited to client display copy. No server handler, Config reset list, SessionManager method, migration, or SecurityService mutation specifies which keys reset. The canonical schema now has exactly four IDs, but that fact does not prove the original rebirth reset included all four.

Before Phase B, product/Chief Architect approval must explicitly state whether all four reset to zero and whether any future/perk-owned upgrade fields are excluded. Until then, even a Rebirths-only transaction is not an acceptable substitute.

## 9. Energy Reset-versus-Deduction Decision

Unresolved; defer implementation.

The term “Cost” and the affordability validator support either:

- subtracting `cost` from Energy; or
- using `cost` as a threshold and resetting Energy to zero.

No surviving mutation chooses between them. Recovered WP-07 analysis already records this ambiguity. Neither behavior may be selected as a recovery default.

## 10. LifetimeEnergy Decision

Preserve `LifetimeEnergy` unchanged in any future contract unless new explicit evidence authorizes otherwise.

It is a lifetime counter, drives factory unlocks, and recovered FactoryEvolution uses it together with Rebirths. No source resets it. Resetting it would contradict its name and could alter progression, but this is a preservation decision rather than proof of original behavior.

## 11. Gems Reward Evidence

No Gems reward or other currency reward is evidenced for rebirth.

Config has no rebirth reward field. The client shows only cost and the next multiplier. SecurityService returns only eligibility and cost. Do not invent or grant Gems.

## 12. FactoryStage Behavior

Do not mutate `FactoryStage` in WP-07C.

Recovered FactoryEvolution only increases FactoryStage when recalculating from LifetimeEnergy/Rebirths; it does not define rebirth reset behavior. That script is inactive and incompatible with canonical sessions. FactoryDefinitions may make a higher stage eligible after Rebirths increments, but applying that progression belongs to the separately reviewed factory package.

## 13. HighestFactoryStage Behavior

Preserve `HighestFactoryStage` unchanged.

Recovered FactoryEvolution treats it as a monotonic maximum and only writes a higher value. Session migration enforces `HighestFactoryStage >= FactoryStage`. No evidence supports reducing it during rebirth. Automatic advancement caused by a new rebirth remains deferred with factory progression.

## 14. Exact Mutation Fields

No Phase B mutation field set is approved because the transaction is deferred.

The minimum fields that require an explicit product decision are:

- `Rebirths = oldRebirths + 1`;
- the chosen Energy result: `0` or `oldEnergy - cost`;
- an exact approved subset of the four UpgradeLevels, normally with an explicit reset value.

Do not add Gems, LifetimeEnergy, FactoryStage, HighestFactoryStage, or other fields to that future transaction without separate evidence and approval.

## 15. Atomic Mutation Order

Once the missing semantics are approved, the future non-yielding service flow should be:

1. Validate exact Player, session identity, Loaded state, revision metadata, and required data tables.
2. Re-read Energy and Rebirths.
3. Validate MaxEnergy and MaxRebirths configuration.
4. Reject a maxed Rebirths count.
5. Calculate and validate cost server-side.
6. Recheck affordability.
7. Validate every field in the approved reset set.
8. Capture every value that will mutate.
9. Calculate all new values without assigning them.
10. Assign the complete approved transaction.
11. Call `ServerDataService.markDirty(player)` exactly once.
12. Roll back every captured value if dirty marking fails.
13. Call `ServerDataService.syncToClient(player)` once after dirty success.

Do not partially implement this sequence before the mutation set is approved.

## 16. markDirty and Rollback

Every future successful rebirth must call `markDirty(player)` exactly once. Gameplay code must not write revision, savedRevision, or dirty directly.

On dirty failure, restore Rebirths, Energy, and every reset upgrade/field to its exact captured value. No sync follows rollback. DataSync failure after dirty success must not roll back an authoritative dirty transaction.

Because the exact rollback set depends on the unresolved mutation set, this requirement cannot yet be implemented safely.

## 17. DataSync Behavior

Use `ServerDataService.syncToClient(player)` exactly once after dirty success. The current main packet contains Energy, Rebirths, all four UpgradeLevels, and recalculated ClickPower/AutoPower, so it is sufficient for authoritative presentation of the eventual base transaction.

Failed eligibility, malformed requests, rate rejection, invalid data/config, and dirty rollback produce no DataSync. Sync failure does not invalidate a completed dirty mutation.

Do not send QuestSync or FactoryEvolutionSync as part of the deferred base rebirth transaction.

## 18. Client Feedback Behavior

The recovered client immediately displays “Rebirth successful!” after firing the request, without server confirmation. This is incorrect for any authoritative handler because rejected requests appear successful.

No server response payload or dedicated rebirth feedback RemoteEvent survives. The smallest future server behavior should use DataSync as success reflection and send no failure detail, matching WP-07B, but the client-side false-success message remains an unresolved WP-09 repair. Do not add Notification or reuse PressFeedback in WP-07C.

## 19. Rate-limit Requirements

The eventual controller should own a third independent weak-key timestamp table for RequestRebirth, separate from press and upgrade buckets.

- use server `os.clock()`;
- use a one-second sliding window;
- key by exact Player with weak keys;
- validate zero arguments before consuming the bucket;
- record an admitted attempt before calling GameplayService;
- valid but ineligible attempts consume the bucket;
- rejection causes no mutation, sync, or feedback.

No dedicated rebirth request limit exists. Reusing `Config.MaxPressesPerSecond` would provide the only approved ceiling but is semantically inappropriate for a rare transaction. Phase B should require an explicitly approved limit or Config field rather than silently treating twelve rebirth attempts per second as product intent.

## 20. Session-state Requirements

Match WP-07A/B policy:

- valid exact Player Instance;
- canonical SessionRepository wrapper for the exact Player;
- `session.player` and `session.userId` identity match;
- valid finite revision/savedRevision metadata;
- `dirty == (revision > savedRevision)`;
- `state == "Loaded"` exactly;
- `saveInFlight == false`;
- `finalizeRequested == false`;
- required data tables and fields are canonical.

Loading, Saving, LoadFailed, Released, finalizing, busy, absent, and malformed sessions fail unchanged.

## 21. Numeric and Cap Validation

Future implementation must require:

- MaxEnergy: finite positive safe integer;
- MaxRebirths: finite non-negative safe integer;
- Energy: finite integer in `0..MaxEnergy`;
- Rebirths: finite integer in `0..MaxRebirths`;
- cost: finite integer in `1..MaxEnergy`;
- `Rebirths + 1 <= MaxRebirths` without unsafe addition;
- every approved reset field: canonical finite integer within its Config/definition cap.

Numeric strings, fractions, booleans, NaN, and infinities fail closed. Gameplay code must not normalize corrupted live state. `Config.getRebirthCost` should be protected and any raised/invalid result classified deterministically as invalid cost/configuration.

## 22. Replay and Rapid-request Behavior

RequestRebirth has no request ID and is not idempotent. Every admitted request must re-fetch the live session and re-read Rebirths and Energy, then recalculate cost and eligibility. Never cache the client-displayed cost or prior server result.

The future mutation path must not yield before markDirty. Sequential requests then observe the prior completed transaction and stop at insufficient Energy or MaxRebirths. The independent limiter bounds replay/spam; cross-server replay protection remains a persistence/lease concern and is deferred.

## 23. Proposed GameplayService API Addition

No API should be implemented until the mutation contract is approved. Reserved future shape:

```lua
GameplayService.rebirth(player: Player): (boolean, ResultCode, RebirthResult?)
```

Proposed scalar result after approval:

```lua
export type RebirthResult = {
    cost: number,
    newRebirths: number,
    syncSucceeded: boolean,
}
```

Likely new internal result codes are `MAX_REBIRTHS`, `INVALID_COST`, and `INSUFFICIENT_ENERGY`; existing Player/session/data/dirty codes should be reused. The API accepts no client-authored values and exposes no session reference.

This signature is a design reservation, not Phase B authorization.

## 24. Proposed GameplayRemoteController Addition

After approval, extend controller dependencies with:

```lua
requestRebirth: RemoteEvent
```

Add `rebirth(player)` to its GameplayService dependency and connect exactly one RequestRebirth listener. The listener validates exactly zero arguments, applies the independent limiter, and invokes the service. It must not calculate cost, access sessions, mutate data, or send success/failure payloads.

Do not add this listener while the service mutation is deferred; consuming the request and returning no authoritative result would preserve the client's misleading success behavior without implementing the feature.

## 25. Main.server Wiring

After Phase B authorization:

1. Resolve `ReplicatedStorage.Remotes.RequestRebirth`.
2. Assert it is a RemoteEvent with the existing gameplay remotes.
3. Inject it into GameplayRemoteController.
4. Keep ServerDataService and GameplayService initialization order unchanged.
5. Keep DataLifecycleService initialization last.

Do not create the Instance or discover unrelated remotes. No Main change is recommended in the current deferred state.

## 26. Phase B Allowlist

No Phase B implementation should begin until the blocking decisions in sections 8, 9, and 19 are explicitly approved.

Once approved, proposed allowlist:

- `prompts/codex/WP-07C_Rebirth.md` only if clarification is required;
- `src/server/Main.server.lua`;
- `src/server/Services/GameplayService.lua`;
- `src/server/Services/GameplayRemoteController.lua`;
- `tests/manual/WP-07C_Rebirth.md`;
- `CHANGELOG.md`.

Do not modify Config unless a separately approved dedicated rate/balance task authorizes it. Do not modify shared definitions, SessionRepository, ServerDataService, lifecycle/persistence services, recovered code, client code, FactoryEvolution, project mapping, or Studio Instances.

## 27. Manual Test Plan

### Payload, authority, and state

- Exactly zero payload arguments accepted; explicit nil and every extra value rejected.
- No client cost, reward, multiplier, reset list, level, balance, or currency is accepted.
- Invalid/wrong Player and all non-Loaded/busy/finalizing states fail unchanged.
- Revision/dirty mismatch and malformed data fail closed.

### Configuration and eligibility

- Invalid MaxEnergy/MaxRebirths and invalid/raised cost calculation fail closed.
- Rebirths below/at MaxRebirths boundaries.
- Energy below/at/above each calculated cost.
- Numeric strings, fractions, NaN, and both infinities rejected.
- Every rapid request re-reads Energy/Rebirths and recalculates cost.

### Approved transaction (blocked pending decision)

- Assert exact mutation field set and exact Energy disposition.
- Assert exact four-upgrade reset policy after it is approved.
- Gems, LifetimeEnergy, FactoryStage, and HighestFactoryStage remain unchanged.
- Exactly one markDirty call follows the complete mutation.
- Dirty failure restores every field exactly and causes no sync.
- Dirty success causes exactly one DataSync; sync failure does not roll back.
- Fresh frozen scalar-only result and no session metadata leakage.

### Transport and regression

- Independent weak-key rebirth, upgrade, and press buckets.
- Malformed payload does not consume the rebirth bucket; admitted failures do.
- Exactly one RequestRebirth listener after authorization.
- WP-07A Press and WP-07B BuyUpgrade behavior unchanged.
- DataLifecycleService remains last.
- No claims, factory mutation, quest, rarity, reward, DataStore, autosave, or retry behavior.
- Rojo build, diff check, and allowlist status pass.

## 28. Explicitly Deferred Behavior

- RequestRebirth runtime listener and mutation until reset/Energy/rate decisions are approved;
- Gems or any rebirth currency reward;
- factory-stage recalculation, mutation, and FactoryEvolutionSync;
- LifetimeEnergy reset;
- success/failure notification protocol and client false-success repair;
- multiplier rebalance or alternative stat application;
- reward claims, quests, rarity/history, achievements, collections, DailyLogin, monetization, and receipts;
- DataStore, autosave, retries, cross-server locks/leases, and replay ledger;
- FactoryEvolution and MainGuiClient repairs;
- Shared/LCA_Shared compatibility bridges.

## 29. Unresolved Balance and UX Questions

Blocking questions:

1. Does successful rebirth set Energy to zero or subtract the calculated cost?
2. Do all four canonical UpgradeLevels reset to zero? If not, which exact IDs and values?
3. What independent rebirth request rate is approved?

Non-blocking but unresolved:

- Are provisional base cost `10,000`, growth `1.75`, MaxRebirths `100`, and multiplier increment `0.5` acceptable balance?
- Should a successful rebirth immediately advance an eligible factory stage in a later factory transaction?
- Should DataSync alone acknowledge success, and how should the client display rejection?
- Should the recovered client’s immediate success notification be removed or replaced with server-confirmed feedback in WP-09?
- Is a request ID/receipt-like deduplication mechanism needed once durable persistence exists?
