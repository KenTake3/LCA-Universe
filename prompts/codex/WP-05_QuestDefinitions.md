# WP-05 — Recover QuestDefinitions Contract

## Mission

Recover only the shared quest-definition contract supported by surviving evidence. This is a definition and compatibility task, not authorization to invent quest content, implement quest services, schedule daily resets, grant rewards, mutate sessions, or repair the recovered client.

Phase A found no recoverable quest records. Phase B must therefore implement the smallest evidenced interface unless an architect separately approves new, versioned quest content.

## Phase A Evidence Base

Inspected:

- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/FactoryEvolution.server.lua`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/SecurityService.lua`
- `docs/01_Universe_Bible.md`
- `docs/03_Architecture.md`
- `docs/04_Game_Economy.md`
- `docs/05_Roadmap.md`
- `docs/06_Current_System.md`
- `src/shared/Config.lua`
- `src/shared/UpgradeDefinitions.lua`
- `src/shared/FactoryDefinitions.lua`
- `src/shared/LCAConfig.lua`
- `src/server/Main.server.lua`
- every file under `src/server/Services`
- every current client script; no files currently exist under `src/client`

The entire repository and available Git file history were searched for `Quest`, `Quests`, `questId`, `Progress`, `Completed`, `Claimed`, `Reward`, `Objective`, `Daily`, `LifetimeEnergy`, `FactoryStage`, `HighestFactoryStage`, `Rebirths`, `Upgrades`, `Clicks`, and `AutoPower`.

## 1. Existing Quest IDs

No daily-quest, mission, or achievement record ID was discovered.

The only confirmed identifier in the missing module's domain is the achievement category ID `Press`:

- `MainGuiClient` initializes `selectedAchCategory = "Press"`.
- It iterates `QuestDefinitions.AchievementCategories`, using each record's `id` as the tab name/key.

`Press` is an achievement **category ID**, not evidence of a quest ID. No numeric legacy quest identifier, stable string `questId`, or saved quest key is recoverable. `DailyQuests.Quests`, `Achievements.Unlocked`, and `Achievements.Claimed` are empty maps/arrays by default, so their future keys cannot be inferred.

## 2. Existing Quest Names and Descriptions

No quest or achievement name or description was found.

The client contains UI headings `DAILY QUESTS`, `MISSIONS`, and `ACHIEVEMENTS`, but these are panel labels rather than definition records. `AchievementCategories` records require a display `name`, yet the original display name for the `Press` category is absent. A Phase B display name such as `PRESS` must be marked `RECOVERY_PROVISIONAL` and must not be described as original.

## 3. Quest Categories or Types

Confirmed or strongly evidenced domain groupings are:

- Daily quests: `DailyQuests` save/sync container and a `DAILY QUESTS` panel.
- Achievements: `Achievements.Unlocked`, `Achievements.Claimed`, category tabs, and lifetime statistic fields.
- Mission tracker: an empty always-visible `MISSIONS` panel; whether this mirrors daily quests is unknown.
- Collections and daily login are adjacent v4 domains included in the same quest sync packet, but they are not proven quest types.

Only the `Press` achievement category is confirmed. Categories for energy, rebirth, factory, rarity, upgrades, or automation may be plausible from available statistics, but none is authoritative and Phase B must not add them without approval.

## 4. Progress Source Fields

`SessionManager.buildQuestSyncPacket` exposes these `Stats` fields for achievement progress display:

- `TotalPresses`
- `LifetimeEnergy`
- `Rebirths`
- `HighestFactoryStage`
- `TotalRarePulls`
- `TotalLegendaryPulls`
- `TotalMythicPulls`
- `TotalCosmicPulls`
- `TotalJackpotPulls`
- `RarityCount`, with one-based slots `1..8`

The default save data also contains all of those fields. This proves that they are candidate progress sources, not which quests consume them or whether rarity counters are exact-tier or cumulative.

Notably:

- `Energy` and `FactoryStage` are absent from the quest `Stats` packet.
- `LifetimeEnergy` and `HighestFactoryStage` are present.
- `UpgradeLevels`, individual upgrade IDs, `AutoPower`, and total upgrade purchases are absent.
- `Clicks` is not a saved field; the recovered counter is `TotalPresses`.
- Mutable daily quest records might carry their own progress, but their record shape is unknown.

Phase B must not claim unsupported progress sources merely because the underlying gameplay field exists elsewhere.

## 5. Completion Conditions

No quest target, comparison operator, completion flag shape, or evaluation function survived.

The available lifetime counters suggest threshold-based achievements, but no thresholds are known. There is no evidence for equality versus greater-than-or-equal evaluation, compound objectives, incremental event progress, retroactive completion, prerequisite completion, or whether completion is stored or derived.

Definitions must not mark a quest complete. A future authoritative server service should derive eligibility from validated server-owned progress and approved definitions, then persist only the mutable state required by the approved contract.

## 6. Reward Fields and Values

No quest or achievement reward field, reward type, or reward amount was discovered.

Confirmed currencies elsewhere are Energy and Gems, while design documents also mention Research, Core Fragments, and Blueprint Tokens. Their existence does not prove that quests reward them. `Config.DailyReward` and `Config.PlaytimeReward` are separate reward systems and must not be reused as quest rewards by inference. `Security.MaxRewardPerPress` is a press-reward cap, not an established general quest-reward cap.

Phase B must define no quest rewards. Any future `rewardType` and `rewardAmount` values require explicit product approval and server-side caps.

## 7. Claim Behavior

No quest claim behavior survives.

- The client obtains `QuestAction` but never calls `FireServer` on it.
- No recovered server listener exists.
- `Achievements.Claimed` proves that achievement claim state was intended, but its keys and values are unknown.
- `DailyQuests.Quests` does not reveal whether daily quests are claimed individually, automatically rewarded, or claimed as a set.
- The daily-login claim button has no connection and belongs to a separate adjacent system.

Future claim handling must be atomic and server-authoritative: validate loaded state, definition, completion, unclaimed state, and reward bounds; grant once; record claim; mark dirty; then sync. None of that belongs in `QuestDefinitions`.

## 8. Repeatability or Reset Behavior

`DailyQuests = { Date = "", Quests = {}, SessionStart = 0 }` strongly indicates date-scoped daily quest state and session-relative tracking. It does not define:

- timezone or reset hour;
- date string format;
- whether quests rotate, reroll, or repeat;
- how many daily quests are selected;
- whether progress survives disconnects within the same date;
- what `SessionStart` measures or which objectives use it;
- missed-day behavior;
- whether achievements are one-time.

`Achievements.Unlocked` and `Achievements.Claimed` suggest persistent one-time state, but repeatability is not explicitly implemented. Phase B must not implement reset scheduling or selection logic.

## 9. Ordering and Unlock Dependencies

No quest ordering, tier, prerequisite, player-level gate, factory-stage gate, or category-unlock dependency was found.

Array order may eventually control presentation, while stable IDs should control saved references. These roles must remain separate. Do not derive unlock dependencies from the roadmap, factory stages, upgrade IDs, or the ordering of lifetime statistics.

## 10. Server-Side References

There is no current or recovered `QuestService` implementation. `docs/03_Architecture.md` lists `QuestService` as a planned core service, but listing a service does not specify its API.

`SessionManager`:

- creates and migrates quest-adjacent save containers;
- exposes `buildQuestSyncPacket(player)`;
- does not require `QuestDefinitions`;
- does not calculate progress, completion, or rewards;
- does not fire `QuestSync` itself.

`SecurityService` has no quest-specific validation. Current server services cover only in-memory player data, Energy, and factory stage foundations; none reference quests. `FactoryEvolution` changes `HighestFactoryStage`, which is a quest statistic candidate, but it does not update quests.

## 11. Client/UI References

The missing module has exactly one confirmed executable client contract:

```lua
for _, category in ipairs(QuestDefinitions.AchievementCategories) do
    -- reads category.id, category.name, and category.color
end
```

The initial selected category is `Press`, so a coherent `AchievementCategories` array needs a `Press` record.

The client creates panels for daily quests, achievements, collections, daily login, and a mission tracker, but the implementations are incomplete:

- quest and mission lists are never populated;
- no `QuestSync.OnClientEvent` listener exists;
- no `QuestAction:FireServer` call exists;
- quest/achievement/login navigation and close buttons are not wired;
- `updateAchievementPanel()` and `updateCollectionPanel()` are called but undefined;
- cached shapes use lower-camel names that do not match the SessionManager packet;
- no record fields beyond achievement category `id`, `name`, and `color` are read.

Client data is presentation-only and must never establish authoritative progress, completion, claims, or rewards.

## 12. Save-Data References

Recovered default/migration contract:

```lua
DailyQuests = {
    Date = "",
    Quests = {},
    SessionStart = 0,
}

Achievements = {
    Unlocked = {},
    Claimed = {},
}
```

Related persistent statistics:

```lua
TotalPresses = 0
LifetimeEnergy = 0
Rebirths = 0
HighestFactoryStage = 1
TotalRarePulls = 0
TotalLegendaryPulls = 0
TotalMythicPulls = 0
TotalCosmicPulls = 0
TotalJackpotPulls = 0
RarityCount = { [1] = 0, ..., [8] = 0 }
```

Related but separate sync/save domains are `Collection` and `DailyLogin`.

The internal shape of each `DailyQuests.Quests` entry and the key/value representation of `Unlocked` and `Claimed` are unknown. SessionManager migration also shallow-clones nested defaults, which can cause shared nested quest tables, and it performs no per-record quest validation. Phase B must not change or reinterpret saved data.

## 13. Remote-Event References

The `QuestAction` and `QuestSync` RemoteEvent Instances are confirmed present under `ReplicatedStorage.Remotes`.

- `QuestSync` is the implied transport for `buildQuestSyncPacket`, but no producer or client listener survives.
- `QuestAction` is obtained by the client, but no send, payload, action name, or server listener survives.
- No success, rejection, or notification payload is defined.

Instance existence is confirmed; payload contracts and listeners are not. Shared definitions must not create, find, fire, or listen to either remote.

## 14. Security and Exploit Risks

- Trusting client-provided progress, completion, reward amounts, reset dates, or claimed state.
- Accepting arbitrary or obsolete quest IDs.
- Double rewards from replayed or concurrent claim requests.
- Granting before atomically recording the claim, or recording without granting.
- Client/server definition-version drift and orphaned saved IDs.
- Counter overflow, NaN, infinity, negative, fractional, or wrong-type values.
- Using `MaxRewardPerPress` as an unjustified quest reward cap.
- Reset manipulation caused by client clocks, timezone ambiguity, or malformed saved `Date` values.
- Duplicate event counting after reconnect or handler retries.
- Treating rarity counters as cumulative when they are exact-tier, or vice versa.
- Shared nested default tables leaking progress between sessions due to shallow migration copies.
- Failing to mark quest mutations dirty or synchronize only after successful mutation.
- Leaking mutable definition tables that another script can alter at runtime.

The future server must use server clocks, server-owned counters, stable allowlisted IDs, finite integer normalization, idempotent claim handling, and transaction ordering appropriate to the persistence design.

## 15. Missing Code and Unresolved Values

- All quest and achievement record IDs.
- All quest/achievement names and descriptions.
- All targets, progress-source mappings, and completion operators.
- All reward types and values.
- Daily quest count, selection, rotation, and reset rules.
- Date format, timezone, and reset hour.
- `SessionStart` semantics.
- Daily quest mutable entry shape.
- `Unlocked` and `Claimed` map value semantics.
- Achievement categories beyond `Press`.
- Original `Press` category display name and color.
- Achievement ordering, tiers, prerequisites, and retroactive behavior.
- Exact versus cumulative rarity-counter semantics.
- QuestAction actions and payloads.
- QuestSync producer/listener behavior and payload versioning.
- Claim rejection/success protocol.
- Quest service, authoritative event hooks, and reward service integration.
- Definition version/migration behavior for retired or changed IDs.
- Whether collections and daily login belong in QuestDefinitions or separate modules.

No provisional quest ID, threshold, reward, or reset value is approved by this Phase A document.

## 16. Conflicts Between Recovered and Current Files

1. `SessionManager.buildQuestSyncPacket` sends PascalCase domains (`DailyQuests`, `Achievements`, `Collection`, `DailyLogin`, `Stats`), while the client cache expects `QuestData.quests`, `AchievementData.unlocked/claimed`, `CollectionData.cores/...`, `DailyLoginData.Day`, and `QuestStats`.
2. SessionManager supplies a quest packet, but the client has no `QuestSync` listener.
3. The client obtains `QuestAction`, but neither client actions nor a server handler survive.
4. The client assumes `AchievementCategories`, but no current module supplies it.
5. Architecture lists `QuestService`; no current service implements it.
6. Current `PlayerDataService` contains only `Energy`, `LifetimeEnergy`, and `FactoryStage`; it has no recovered v4 quest fields.
7. `HighestFactoryStage` is a quest statistic in recovered sessions, but current player data tracks only `FactoryStage`.
8. Recovered scripts require `ReplicatedStorage.Shared`, while current Rojo maps shared source to `ReplicatedStorage.LCA_Shared`.
9. The client uses lower-camel cache fields while recovered saved/sync fields use PascalCase.

These conflicts require later synchronization, client, persistence, and service work; a shared definition module must not conceal them.

## 17. Proposed Canonical QuestDefinitions Schema

### Approved minimal Phase B contract

Export exactly one immutable member:

```lua
QuestDefinitions.AchievementCategories = {
    {
        id = "Press",
        name = "PRESS", -- RECOVERY_PROVISIONAL
        color = Color3.fromRGB(...), -- RECOVERY_PROVISIONAL
    },
}
```

Requirements:

- `AchievementCategories` is a dense, ordered array.
- The sole Phase B category has stable ID `Press`.
- Freeze the record, array, and returned module table.
- Do not expose mutable lookup tables.
- Do not export daily quests, achievements, helpers, reward functions, progress calculators, reset logic, or `getById` APIs without an approved record set and consumer contract.

This minimal module restores the only executable require-time contract while avoiding invented gameplay content.

### Candidate future quest record schema — not approved for Phase B

If product design later supplies actual records, prefer flat deterministic scalar fields:

```lua
{
    id = "approved_stable_id",
    kind = "DAILY",               -- approved enum
    categoryId = "Press",         -- approved stable category ID
    name = "Approved name",
    description = "Approved description",
    progressSource = "TotalPresses", -- approved allowlist
    target = 100,                  -- approved positive integer
    rewardType = "Gems",          -- approved allowlist
    rewardAmount = 10,             -- approved non-negative integer
    order = 1,
}
```

This is a proposed shape only. The sample ID and numeric values are illustrative placeholders and must not enter runtime code or tests. Mutable values such as `progress`, `completed`, `claimed`, selected date, and session start belong in player data, never immutable definitions.

## 18. Validation and Normalization Rules

### Phase B category validation

- Use `--!strict`.
- Require exactly one category for the approved minimal contract.
- Require `id == "Press"`.
- Require a non-empty string `name`.
- Require `typeof(color) == "Color3"`.
- Reject duplicate or empty IDs.
- Freeze all exported data.
- Provide no public input-normalization function because the minimal contract accepts no input.

### Future record validation, pending approval

- IDs must be non-empty, unique, stable strings and must never be derived from display text.
- Enums must fail closed against explicit allowlists.
- Targets, rewards, order, and mutable progress must be finite non-negative integers; target should be positive when the approved objective requires progress.
- Unknown progress sources or reward types must fail closed.
- Definitions must be deterministic and must not depend on time, locale, sessions, DataStores, remotes, Workspace, UI, random selection, or client state.
- Saved unknown IDs must never be silently remapped to a different reward.
- Definition validation does not authorize reward granting or completion decisions.

## 19. Manual Test Plan

### Phase B interface

- Confirm the module exports exactly `AchievementCategories`.
- Confirm the array contains exactly one record.
- Confirm its ID is exactly `Press` and the client initial selection resolves to it.
- Confirm `id` and `name` are non-empty strings and `color` is a `Color3`.
- Confirm no quest IDs, targets, rewards, reset values, or helper APIs were invented.

### Immutability

- Confirm `table.isfrozen` for the category record, array, and module table.
- Confirm writes to each frozen table fail.
- Confirm no mutable lookup table is exported.

### Recovered compatibility

- Require the module in Studio and iterate `AchievementCategories` with `ipairs`.
- Confirm every field read by `MainGuiClient` exists.
- Confirm creating the category tabs does not fail because the `Press` selection is absent.
- Confirm the known `Shared` versus `LCA_Shared` path mismatch is handled only by the later integration task, not this module.

### Explicit exclusions

- Confirm the module does not access services, sessions, DataStores, remotes, Workspace, UI, clocks, or random APIs.
- Confirm it does not calculate progress/completion, grant rewards, update claims, or schedule resets.
- Confirm it has no definitions for collections or daily login.

### Build and repository checks

- Run `git diff --check`.
- Run `rojo build default.project.json` with an explicit temporary output path if required by the installed Rojo version.
- Confirm only the Phase B allowlist changed.

Future quest-record tests must be specified only after IDs, fields, targets, rewards, and reset semantics are approved.

## 20. Exact Files Proposed for Phase B Implementation

Phase B should allow changes only to:

- `src/shared/QuestDefinitions.lua`
- `tests/manual/WP-05_QuestDefinitions.md`
- `CHANGELOG.md`

Do not modify the recovered files, current server/client services, SessionManager, SecurityService, Config, other shared definitions, `default.project.json`, remotes, Studio Instances, or project settings.

## Recommended Phase B Plan

1. Implement the minimal frozen `AchievementCategories` contract with the single confirmed `Press` ID.
2. Select one conservative display name and color and mark both `RECOVERY_PROVISIONAL`.
3. Add focused manual tests for exact interface, category compatibility, and immutability.
4. Record in the changelog that no quest records, targets, rewards, or reset rules were recovered or added.
5. Run diff, build, and allowlist validation.
6. Defer actual quest records until product design approves stable IDs, progress mappings, thresholds, rewards, and reset semantics.
7. Defer quest sync, actions, authority, persistence repair, and client rendering to their separately reviewed work packages.
8. Do not commit or push during Phase B unless a later instruction explicitly authorizes it.
