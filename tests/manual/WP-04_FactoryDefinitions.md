# WP-04 FactoryDefinitions Manual Tests

## Preconditions

- Build the project with `rojo build`.
- In Studio, require `FactoryDefinitions` from the location produced by the current Rojo mapping.
- Run assertions from a temporary Studio command-bar or test harness; do not add the harness to runtime source.
- For NaN and infinity cases, use `0 / 0`, `math.huge`, and `-math.huge`.

## Public Contract and Exact Schema

- [ ] The module exports exactly `Stages`, `getStage`, `getNextStage`, `calculateStage`, and `getProgress`.
- [ ] `#FactoryDefinitions.Stages == 6`.
- [ ] Every record contains `id`, `stage`, `name`, `description`, `coreColor`, `lifetimeEnergyRequired`, `rebirthsRequired`, and `unlockMode`.
- [ ] Every description is a string and every `coreColor` has `typeof(value) == "Color3"`.
- [ ] Confirm the exact ordered values:

| Stage | ID | Name | Lifetime Energy | Rebirths | Mode |
| ---: | --- | --- | ---: | ---: | --- |
| 1 | `core_online` | Core Online | 0 | 0 | `DEFAULT` |
| 2 | `power_generator` | Power Generator | 500 | 0 | `ENERGY` |
| 3 | `industrial_factory` | Industrial Factory | 5,000 | 0 | `ENERGY` |
| 4 | `advanced_reactor` | Advanced Reactor | 50,000 | 1 | `ENERGY_OR_REBIRTHS` |
| 5 | `mega_factory` | Mega Factory | 500,000 | 3 | `ENERGY_OR_REBIRTHS` |
| 6 | `quantum_factory` | Quantum Factory | 5,000,000 | 10 | `ENERGY_OR_REBIRTHS` |

## Immutability and Input Preservation

- [ ] `table.isfrozen(FactoryDefinitions)` is true.
- [ ] `table.isfrozen(FactoryDefinitions.Stages)` is true.
- [ ] `table.isfrozen(stage)` is true for all six records.
- [ ] Assigning to the module, stage array, or a stage record fails.
- [ ] No mutable internal lookup table is exported.
- [ ] Save input variables before every public call and confirm their values are unchanged afterward.
- [ ] Passing a table as any argument neither modifies that table nor any nested value.

## Stage Input Normalization

- [ ] `getStage(1)`, `getStage("1")`, and `getStage(1.9)` return stage 1.
- [ ] `getStage(6)`, `getStage("6")`, and `getStage(6.9)` return stage 6.
- [ ] Values below 1, including `0`, `-10`, and `"-2"`, clamp to stage 1.
- [ ] Values above 6, including `7`, `1e9`, and `"99"`, clamp to stage 6.
- [ ] `nil`, booleans, tables, invalid strings, NaN, and both infinities normalize to stage 1.
- [ ] Numeric strings with fractions are floored before clamping.

## Lifetime Energy and Rebirth Normalization

- [ ] Finite numbers and numeric strings produce identical results.
- [ ] Fractions are floored: compare `499.9` with `499`, and `"3.9"` with `3`.
- [ ] Negative values normalize to `0`.
- [ ] `nil`, booleans, tables, invalid strings, NaN, and both infinities normalize to `0`.
- [ ] Every result from `calculateStage` is an integer from 1 through 6.
- [ ] Every result from `getProgress` is finite and within `[0, 1]`.

## Energy Unlock Boundaries

For every row, hold rebirths at `0` and test the Lifetime Energy values immediately below, exactly at, and immediately above the threshold:

| Target stage | Inputs | Expected calculated stages |
| ---: | --- | --- |
| 2 | 499, 500, 501 | 1, 2, 2 |
| 3 | 4,999, 5,000, 5,001 | 2, 3, 3 |
| 4 | 49,999, 50,000, 50,001 | 3, 4, 4 |
| 5 | 499,999, 500,000, 500,001 | 4, 5, 5 |
| 6 | 4,999,999, 5,000,000, 5,000,001 | 5, 6, 6 |

Repeat every case with numeric strings.

## Rebirth Unlock Boundaries and OR Eligibility

Use Lifetime Energy `0` to isolate the rebirth path:

| Target stage | Rebirth inputs | Expected calculated stages |
| ---: | --- | --- |
| 4 | 0, 1, 2 | 1, 4, 4 |
| 5 | 2, 3, 4 | 4, 5, 5 |
| 6 | 9, 10, 11 | 5, 6, 6 |

- [ ] Repeat every case with numeric strings.
- [ ] For stages 4, 5, and 6, confirm the energy threshold unlocks with insufficient rebirths.
- [ ] For stages 4, 5, and 6, confirm the rebirth threshold unlocks with insufficient energy.
- [ ] Confirm satisfying either independent path is enough; both are not required.
- [ ] Confirm `calculateStage(5_000_000, 0) == 6` and `calculateStage(0, 10) == 6`, demonstrating direct stage skipping.

## getNextStage Boundaries

- [ ] Inputs `1` through `5` return stages `2` through `6`, respectively.
- [ ] Stage `6` returns `nil`.
- [ ] A value below range normalizes to stage 1 and returns stage 2.
- [ ] A value above range normalizes to stage 6 and returns `nil`.
- [ ] Invalid values normalize to stage 1 and return stage 2.
- [ ] Numeric strings and fractional values use the same normalization as `getStage`.

## Progress

### Energy-only progress

- [ ] `getProgress(1, 0, 0) == 0`.
- [ ] `getProgress(1, 250, 0) == 0.5`.
- [ ] `getProgress(1, 500, 0) == 1`.
- [ ] `getProgress(2, 2_500, 0) == 0.5`.
- [ ] Values beyond an energy threshold clamp to `1`.

### ENERGY_OR_REBIRTHS progress

- [ ] From stage 3, energy `25_000` and rebirths `0` returns `0.5`.
- [ ] From stage 3, energy `0` and rebirths below `1` returns `0` after integer normalization.
- [ ] From stage 4, energy `0` and rebirths `1` returns `1 / 3` toward stage 5.
- [ ] From stage 4, energy `250_000` and rebirths `0` returns `0.5`.
- [ ] When both paths have partial progress, the greater path is returned.
- [ ] Meeting either next-stage threshold returns `1`.
- [ ] Zero denominators are guarded and no call returns NaN or infinity.
- [ ] `getProgress(6, anyValue, anyValue) == 1`, including invalid values.

## Recovered Compatibility

- [ ] `#FactoryDefinitions.Stages` and numeric indexing support the recovered server loop.
- [ ] `getStage` results include `name`, `description`, and `coreColor` for `FactoryEvolution.server.lua`.
- [ ] `getStage` results include `name`, `coreColor`, and `rebirthsRequired` for `MainGuiClient.client.lua`.
- [ ] `getNextStage` and `getProgress` return the types assumed by the recovered client.
- [ ] No factory production, storage, offline income, ownership, upgrade, purchase, reward, persistence, session, remote, Workspace, or UI behavior exists in this module.
- [ ] Studio integration separately resolves the known `Shared` versus `LCA_Shared` require-path mismatch.
