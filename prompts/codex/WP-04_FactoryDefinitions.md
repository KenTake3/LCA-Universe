# WP-04 — Recover FactoryDefinitions Contract

## Mission

Implement the missing shared `FactoryDefinitions` contract required by the salvaged LCA factory-evolution code.

This is a recovery task, not a factory rebalance, production-system implementation, or Workspace/UI task. Phase B must preserve recovered behavior where the evidence is clear and must mark unresolved gameplay values as provisional rather than presenting them as authoritative.

## Phase A Evidence Base

This specification is based on complete or targeted inspection of:

- `recovery/studio/FactoryEvolution.server.lua`
- `recovery/studio/MainGuiClient.client.lua`
- `recovery/studio/SessionManager.lua`
- `recovery/studio/SecurityService.lua`
- `docs/01_Universe_Bible.md`
- `docs/03_Architecture.md`
- `docs/04_Game_Economy.md`
- `docs/05_Roadmap.md`
- `docs/06_Current_System.md`
- `src/shared/Config.lua`
- `src/shared/LCAConfig.lua`
- `src/shared/UpgradeDefinitions.lua`
- `src/server/Main.server.lua`
- `src/server/Services/EnergyService.lua`
- `src/server/Services/FactoryService.lua`
- `src/server/Services/PlayerDataService.lua`

The repository was also searched for `Factory`, `Factories`, `factoryId`, `Production`, `Storage`, `Capacity`, `Unlock`, `Evolution`, `Income`, `Energy`, `Core`, `Tier`, and `Level`.

## 1. Existing Factory IDs

The only factory identifiers confirmed in executable repository code are the numeric evolution stages `1` through `6`.

- `FactoryEvolution.server.lua` indexes stages numerically, iterates `1` through `#FactoryDefinitions.Stages`, stores a numeric `FactoryStage`, and addresses Workspace folders as `Stage1` through `Stage6`.
- `LCAConfig.FactoryStages` is also keyed by the numeric values `1` through `6`.
- No existing string `factoryId` values were found.
- `Collection.Factories` exists in saved data, but its key and value format is not implemented or documented.

Numeric stages must remain supported for recovered save-data and caller compatibility. The stable string IDs proposed in section 15 are new canonical identifiers, not recovered IDs.

## 2. Existing Factory Names

Two conflicting name sets exist. The recovered evolution server comments describe:

| Stage | Recovered evolution name | Current `LCAConfig` name |
| ---: | --- | --- |
| 1 | Core Online | CORE ONLINE |
| 2 | Power Generator | BASIC GENERATOR |
| 3 | Industrial Factory | CONVEYOR SYSTEM |
| 4 | Advanced Reactor | DRONE ASSEMBLY |
| 5 | Mega Factory | FUSION REACTOR |
| 6 | Quantum Factory | QUANTUM FACTORY |

Capitalization aside, only stages 1 and 6 agree semantically. Phase B should use the recovered evolution names because the missing module is required directly by the recovered evolution server and client. The conflicting current names must remain documented until an architect confirms whether they represent an older design, visual sub-stages, or a separate foundation prototype.

## 3. All Discovered Factory-Related Fields

### Definition fields required by recovered callers

- `name`: displayed by the server and client.
- `description`: sent in `FactoryEvolutionSync` and displayed in the evolution notification.
- `coreColor`: applied to `CoreInner`, optional `CoreOuter`, and client UI colors.
- `rebirthsRequired`: read by the client to explain an alternative unlock.
- An energy threshold is required by `calculateStage` and `getProgress`, but the recovered field name is not present because `FactoryDefinitions.lua` is missing.
- A numeric stage/index is implicit in `Stages`, `getStage`, Workspace folder names, and saved data.

### Current parallel-foundation definition fields

- `Name`
- `RequiredLifetimeEnergy`

These PascalCase fields belong to `LCAConfig.FactoryStages`; recovered callers expect a different shared module and lower-camel-case output fields.

### Mutable session and save-data fields

- `Energy`
- `LifetimeEnergy`
- `Rebirths`
- `FactoryStage`
- `HighestFactoryStage`
- `Collection.Factories`

`SessionManager` defaults `FactoryStage` and `HighestFactoryStage` to `1`, includes both in sync packets, and includes `HighestFactoryStage` in quest statistics. It also repairs a missing `Collection.Factories` table during migration. It does not define the contents of that collection.

### Current player attributes

- `LCA_Energy`
- `LCA_LifetimeEnergy`
- `LCA_FactoryStage`

These attributes are used by the separate current foundation services, not by the recovered evolution server.

### Remote payload fields

- Server-wide evolution sync: `serverStage`, `stageName`
- Per-player evolution sync: `playerStage`, `stageName`, `stageDescription`, `isUpgrade`

### Other adjacent fields

- `AutoPower` is an upgrade/stat described as automatic energy production.
- `CoreAmplifier` is an upgrade/stat described as increasing energy output.
- Neither field is currently connected to a recovered factory-stage production formula.

Immutable definition records must not contain mutable player progress such as owned state, current storage, accumulated income, or unlock state.

## 4. Production Formulas or Fixed Production Values

No authoritative factory-stage production formula or fixed production value was found.

The only adjacent formulas are the `RECOVERY_PROVISIONAL` upgrade-stat formulas in `UpgradeDefinitions`:

- `AutoPower = normalized AutoPower level * rebirth multiplier`
- `CoreAmplifier = 1 + normalized CoreAmplifier level * 0.05`

No service was found that converts these values, a factory stage, or elapsed time into authoritative energy production. No per-stage production multiplier, base output, tick interval, offline income, or reward formula is recoverable from the inspected repository. Phase B must not invent these values or imply that the upgrade formulas are factory production rules.

## 5. Storage or Capacity Formulas

No factory storage/capacity field or formula was found.

`Config.Security.MaxEnergy` is a provisional global security ceiling of `1e15`, while the separate `LCAConfig.Data.MaxEnergy` is `1e18`. Neither is identified as factory storage capacity. The discrepancy is a compatibility concern, not evidence for a stage capacity curve.

Phase B must not add per-stage storage, warehouse capacity, collection limits, or storage growth formulas without a separately approved design. If future definitions need these concepts, add explicit fields only after their units and authority are specified.

## 6. Unlock Requirements

The recovered evolution comments define these requirements:

| Stage | Lifetime Energy | Alternative Rebirths | Recovered condition |
| ---: | ---: | ---: | --- |
| 1 | 0 | 0 | Default/unlocked |
| 2 | 500 | 0 | Energy |
| 3 | 5,000 | 0 | Energy |
| 4 | 50,000 | 1 | Energy **or** rebirths |
| 5 | 500,000 | 3 | Energy **or** rebirths |
| 6 | 5,000,000 | 10 | Energy **or** rebirths |

`LCAConfig.FactoryStages` independently corroborates all six Lifetime Energy thresholds, but its current `FactoryService` evaluates energy only and has no rebirth alternatives. The OR semantics for stages 4 through 6 are also supported by recovered client UI behavior: it reports an unlock via rebirths when the next stage's rebirth requirement has been met.

## 7. Factory Progression or Evolution Rules

Recovered behavior is:

- Player progression begins at numeric stage `1`.
- `calculateStage(LifetimeEnergy, Rebirths)` determines the eligible stage.
- `FactoryEvolution.server.lua` only writes a new player stage when the calculated stage is greater than the current `FactoryStage`; it does not downgrade.
- On an upgrade, both `FactoryStage` and `HighestFactoryStage` are set to the new stage.
- The server visual stage is the maximum active players' `HighestFactoryStage`.
- The server scans active players approximately every two seconds and checks a joining player after a three-second delay.
- Workspace visual evolution activates folders from stage `1` through the selected server stage and hides later folders.
- The client displays `HighestFactoryStage` as its current factory stage, even though sync data also contains `FactoryStage`.

Unresolved progression details include whether `FactoryStage` may ever decrease independently, why both fields exist, how offline gains should trigger progression, and whether eligibility may skip directly across several stages. The recovered comparison allows a direct jump to the highest eligible stage.

## 8. Upgrade Relationships

No direct factory-stage-to-upgrade relationship is defined.

- `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck` exist as player upgrades.
- `AutoPower` and `CoreAmplifier` are conceptually related to production/output, but no recovered formula combines them with a factory stage.
- Factory unlock thresholds use only `LifetimeEnergy` and, for later stages, `Rebirths`.
- No upgrade level is a confirmed factory unlock requirement.
- Factory evolution must not modify upgrade definitions or calculate upgrade purchases.

## 9. Server-Side References

### Recovered server

`FactoryEvolution.server.lua` expects:

- `FactoryDefinitions.Stages`
- `FactoryDefinitions.getStage(stageId)`
- `FactoryDefinitions.calculateStage(lifetimeEnergy, rebirths)`
- Stage fields `name`, `description`, and `coreColor`

It also reads/writes `FactoryStage` and `HighestFactoryStage` and fires `FactoryEvolutionSync`. Its use of `SessionManager` is currently incompatible with the salvaged API: it calls `getSession(player.UserId)`, `session.DataState`, and `session.Data` instead of `getSession(player)`, `session.state`, and `session.data`.

### Current foundation server

`FactoryService.lua` uses `LCAConfig.FactoryStages`, calculates eligibility using Lifetime Energy only, increases `FactoryStage`, and publishes `LCA_FactoryStage`. It does not use the missing `FactoryDefinitions` module, `HighestFactoryStage`, rebirth requirements, persistence, or evolution remotes.

The current `Main.server.lua` initializes services, but no inspected call connects an energy award to `FactoryService.RefreshPlayerStage`. This current path is also disabled by `LCAConfig.Enabled = false`.

## 10. Client/UI References

`MainGuiClient.client.lua` expects:

- `FactoryDefinitions.getStage(stage)`
- `FactoryDefinitions.getNextStage(stage)`
- `FactoryDefinitions.getProgress(stage, LifetimeEnergy, Rebirths)`
- Stage fields `name`, `coreColor`, and `rebirthsRequired`

It uses `HighestFactoryStage` for the stage label and progress panel. If the next stage's rebirth condition is already satisfied, it displays `Unlocked via Rebirths!`; otherwise it displays a percentage toward the next stage. It also reacts to `FactoryEvolutionSync` and uses the received stage to recolor and animate UI.

The client is presentation-only. Its progress calculation and visible definitions must never be accepted as proof of unlock or as authority to issue production, purchases, or rewards.

## 11. Save-Data References

`SessionManager` currently stores numeric:

- `FactoryStage = 1`
- `HighestFactoryStage = 1`

It also stores `Collection.Factories = {}`. There is no recovered schema for owned factories, no saved stable string ID, and no migration from numeric stages to string IDs.

Phase B must preserve numeric compatibility. Adding a stable `id` to immutable definitions does not authorize changing saved-data fields. Any future save migration to string IDs requires a separate, versioned task with backward compatibility and collision handling.

## 12. Asset or Workspace References

Recovered code references:

- `Workspace.FactoryEvolution`
- Children named `Stage1` through `Stage6`
- A `ServerStage` attribute on the evolution container
- `Workspace.Interactive.EnergyCore.CoreInner`
- Optional `Workspace.Interactive.EnergyCore.CoreOuter`

The recovered server changes `BasePart.Transparency` for stage folders and applies the definition's `coreColor` to core parts. Repository source references do not prove that these Instances currently exist in Studio. Their exact contents, collision behavior, streaming behavior, and ownership are unresolved.

`FactoryDefinitions` must contain no Workspace lookups, Instance mutation, remotes, UI behavior, or asset loading.

## 13. Missing Code and Unresolved Uncertainties

- The original `FactoryDefinitions` module is missing.
- Original `description` strings are unknown.
- Original `coreColor` values are unknown.
- The original energy-threshold field name is unknown.
- The exact invalid-input behavior of the original API is unknown.
- The intended progress formula for energy-or-rebirth unlocks is unknown.
- Factory-stage production and production multipliers are unknown.
- Storage/capacity values and formulas are unknown.
- Offline income, automation tick, and collection behavior are unknown.
- `Collection.Factories` keys and value schema are unknown.
- The meaning of `FactoryStage` versus `HighestFactoryStage` beyond observed usage is unknown.
- Whether stage skipping is intended is not explicitly documented.
- Whether the current and recovered name sets describe competing versions or separate concepts is unknown.
- The current existence and shape of the referenced Workspace hierarchy is unconfirmed.
- The authoritative future location of the module is complicated by the require-path mismatch described in section 18.
- No original balance source was found beyond the confirmed unlock thresholds.

Phase B must label every chosen description, color, and unresolved progress behavior with `RECOVERY_PROVISIONAL` comments.

## 14. Conflicts Between Recovered Files

1. **Names:** recovered evolution names conflict with `LCAConfig` at stages 2 through 5.
2. **Unlock semantics:** recovered evidence uses energy-or-rebirth conditions for stages 4 through 6; current `FactoryService` is energy-only.
3. **Configuration source:** recovered code requires `FactoryDefinitions`; current code reads `LCAConfig.FactoryStages`.
4. **Data model:** recovered code uses both `FactoryStage` and `HighestFactoryStage`; current services use only `FactoryStage`.
5. **Session API:** recovered evolution server calls incompatible `SessionManager` APIs and field names.
6. **Energy ceilings:** `Config.Security.MaxEnergy` is provisionally `1e15`; `LCAConfig.Data.MaxEnergy` is `1e18`.
7. **Module path:** recovered scripts require `ReplicatedStorage.Shared`; the current Rojo project maps `src/shared` to `ReplicatedStorage.LCA_Shared`.
8. **Displayed stage:** the recovered client displays `HighestFactoryStage`, while the evolution server compares and updates `FactoryStage`.

These conflicts must not be silently reconciled inside a data-only shared module.

## 15. Proposed Canonical FactoryDefinitions Schema

Use an ordered, frozen array of six frozen immutable records. Preserve numeric stages and add stable, lower-snake-case string IDs:

| Stage | Proposed stable ID | Canonical recovery name |
| ---: | --- | --- |
| 1 | `core_online` | Core Online |
| 2 | `power_generator` | Power Generator |
| 3 | `industrial_factory` | Industrial Factory |
| 4 | `advanced_reactor` | Advanced Reactor |
| 5 | `mega_factory` | Mega Factory |
| 6 | `quantum_factory` | Quantum Factory |

The string IDs are proposed recovery identifiers. They must not replace numeric saved values in WP-04.

Each definition record should have this shape:

```lua
{
    id = "core_online",             -- stable immutable string ID
    stage = 1,                       -- legacy-compatible numeric stage
    name = "Core Online",           -- recovered name
    description = "...",            -- RECOVERY_PROVISIONAL until sourced
    coreColor = Color3.fromRGB(...), -- RECOVERY_PROVISIONAL until sourced
    lifetimeEnergyRequired = 0,
    rebirthsRequired = 0,
    unlockMode = "DEFAULT",          -- DEFAULT, ENERGY, or ENERGY_OR_REBIRTHS
}
```

Required exports for recovered compatibility:

- `Stages`: ordered frozen array, usable with `#Stages` and numeric indexing.
- `getStage(stage)`: return the normalized numeric stage record.
- `getNextStage(stage)`: return the next record or `nil` at the final stage.
- `calculateStage(lifetimeEnergy, rebirths)`: return the highest eligible numeric stage.
- `getProgress(stage, lifetimeEnergy, rebirths)`: return a finite number in `[0, 1]` toward the next stage.

Optionally expose `getStageById(id)` only if Phase B tests or future saved references justify it; do not add a general registry abstraction. Production and storage fields are intentionally excluded because their units and values are not recoverable.

For direct recovered compatibility, `coreColor` must be a `Color3`. This is deterministic but not DataStore-serializable; definitions must never be stored in player data or sent as a persistence payload. All other canonical fields are scalar and serializable.

Freeze nested records, `Stages`, any internal lookup tables that are exported, and the returned module table with `table.freeze` where supported. Callers must receive module-owned immutable records, not mutable configuration state.

## 16. Validation and Normalization Rules

Phase B should use small local helpers and deterministic behavior:

- A number is valid only when its type is `number`, it equals itself (not NaN), and it is neither positive nor negative infinity.
- Lifetime Energy and Rebirths normalize invalid or negative input to `0`; valid values normalize to non-negative integers with `math.floor`.
- Stage input normalizes to an integer and clamps to `1..#Stages` for `getStage`, preserving a usable record for recovered UI callers.
- `getNextStage` returns `nil` after stage 6.
- Definition validation must require unique non-empty IDs, contiguous stages `1..6`, ordered non-decreasing energy thresholds, valid non-negative integer requirements, supported unlock modes, a string name/description, and a `Color3` color.
- `calculateStage` starts at stage 1 and evaluates stages in ascending order. Stages 2 and 3 use energy; stages 4 through 6 use `LifetimeEnergy >= requirement OR Rebirths >= requirement`. It returns an integer in `1..6`.
- Public functions must not mutate input tables or module-owned tables.

The original OR-condition progress rule is unavailable. Use this explicitly provisional deterministic rule in Phase B:

- Final stage progress is `1`.
- If the next stage is already eligible, progress is `1`.
- Energy progress is `LifetimeEnergy / next lifetimeEnergyRequired`, clamped to `[0, 1]`.
- For `ENERGY_OR_REBIRTHS`, rebirth progress is `Rebirths / next rebirthsRequired`, clamped to `[0, 1]`, and displayed progress is the maximum of energy and rebirth progress.
- For `ENERGY`, displayed progress is energy progress.
- Every division must guard a zero denominator and every return must be finite and non-negative.

Mark the progress rule with `RECOVERY_PROVISIONAL`. Do not normalize client data by mutating it and do not put security caps or player-session access in this module.

## 17. Security Considerations

- Factory definitions are descriptive inputs, not authority.
- The server must independently calculate unlock eligibility from its own session values.
- Only the authoritative server may update factory progress, charge purchases, produce energy, or grant rewards.
- Never trust a client-provided stage, unlock flag, progress value, production value, or reward amount.
- Validate finite non-negative numbers before comparisons; reject or normalize NaN, infinity, negatives, and malformed types.
- Do not expose mutable definition tables that a client or another module can alter at runtime.
- Keep Workspace mutation, remotes, persistence, receipt processing, and UI effects outside the shared module.
- Do not infer production or storage rewards from display-only fields.
- Stage updates should be marked dirty and persisted by server orchestration once that implementation exists.
- Server handlers should rate-limit any future factory purchase or collection request and validate ownership, cost, capacity, and replay behavior.

## 18. Compatibility Risks

- Recovered code requires `ReplicatedStorage.Shared.FactoryDefinitions`, but current Rojo maps `src/shared` to `ReplicatedStorage.LCA_Shared`. WP-04 must not change project mapping; Studio integration must resolve or deliberately bridge this path.
- Using recovered names will disagree with `LCAConfig` stages 2 through 5.
- Current `FactoryService` ignores rebirth alternatives and does not consume the new module.
- String IDs are new; converting numeric saved stages would be a separate migration risk.
- `Color3` preserves recovered callers but must not be persisted as ordinary save data.
- `table.freeze` will expose previously unnoticed caller mutations if any exist.
- A clamped `getStage` is UI-compatible but can hide invalid saved values; authoritative server validation should log or reject corrupted state before display normalization.
- The provisional `getProgress` rule may not match the original UI intent.
- Missing descriptions and colors require provisional Phase B values.
- Factory evolution cannot work correctly until the incompatible `SessionManager` calls are repaired in their separately scoped work package.
- Maintaining both `LCAConfig.FactoryStages` and `FactoryDefinitions.Stages` risks future drift.
- Workspace folders and core parts may be absent or shaped differently in Studio.
- No authoritative production/storage implementation exists, so a definition module alone cannot complete factory gameplay.

## 19. Manual Test Plan

Create a manual test document that verifies:

### Interface and schema

- `Stages`, `getStage`, `getNextStage`, `calculateStage`, and `getProgress` exist.
- There are exactly six ordered records with contiguous numeric stages.
- Stable IDs are unique and exactly match the proposed IDs.
- Required names, fields, types, and confirmed thresholds match this specification.
- Stage records, exported arrays, and module-owned lookup tables cannot be mutated.

### Unlock boundaries

- Stage 1 at zero data.
- Each energy threshold immediately below, exactly at, and above its boundary.
- Stages 4 through 6 immediately below, exactly at, and above their rebirth boundaries.
- Either branch of an OR requirement independently unlocks the stage.
- A caller can jump directly to the highest eligible stage.
- Lower data never produces stage 0 or a stage above 6.

### Normalization and safety

- `nil`, booleans, strings, tables, negative values, fractions, NaN, and both infinities for every numeric public argument.
- Functions always return documented types and finite, non-negative numbers.
- Inputs and definitions remain unchanged after every call.

### Progress

- Energy-only progress at zero, midpoint, threshold, and over threshold.
- OR-condition energy and rebirth paths independently.
- Maximum-of-paths behavior.
- Final-stage progress equals `1`.
- Results remain within `[0, 1]` and never divide by zero.

### Compatibility and integration

- Numeric indexing and `#FactoryDefinitions.Stages` work for the recovered server loop.
- Every field read by `MainGuiClient` and `FactoryEvolution.server.lua` exists.
- Studio has or deliberately maps the expected require path.
- Studio has `Workspace.FactoryEvolution/Stage1..Stage6` and the referenced Energy Core parts before runtime integration testing.
- `FactoryEvolutionSync` remains server-originated.
- Rojo build succeeds without changing `default.project.json`.
- No production, storage, Workspace, UI, or remote behavior is implemented inside the shared module.

## 20. Exact Files Proposed for Phase B Implementation

Phase B should allow changes only to:

- `src/shared/FactoryDefinitions.lua`
- `tests/manual/WP-04_FactoryDefinitions.md`
- `CHANGELOG.md`

Do not modify recovered files, `Config.lua`, `LCAConfig.lua`, `UpgradeDefinitions.lua`, server/client runtime services, `default.project.json`, Workspace assets, or project settings in Phase B. Path integration, factory server authority, recovered-session compatibility, and production gameplay require separately approved tasks.

## Phase B Completion Requirements

1. Implement only the data contract and pure helper functions specified above.
2. Mark every provisional description, color, and progress rule with `RECOVERY_PROVISIONAL`.
3. Do not add production or storage values.
4. Inspect the diff and run `git diff --check`.
5. Run `rojo build` without changing project mapping.
6. Confirm no file outside the Phase B allowlist changed.
7. Report all provisional values and every unresolved compatibility concern.
8. Do not commit or push.
