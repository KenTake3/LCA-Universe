# WP-08 — Press-Triggered Factory Progression Manual Tests

## Setup and scope

- [ ] Build and deploy the current Rojo project with canonical WP-06 and WP-07 services.
- [ ] Use isolated Loaded sessions with canonical Energy, LifetimeEnergy, Rebirths, TotalPresses, FactoryStage, and HighestFactoryStage values.
- [ ] Confirm GameplayService requires `ReplicatedStorage.LCA_Shared.FactoryDefinitions`.
- [ ] Confirm the module creates no require-time tasks, connections, remotes, lifecycle handlers, or Workspace access.
- [ ] Confirm the recovered FactoryEvolution script remains inactive.

## Stage-field validation

- [ ] FactoryStage and HighestFactoryStage accept finite integers from 1 through `#FactoryDefinitions.Stages`.
- [ ] Reject nil, booleans, tables, numeric strings, fractions, negative values, zero, NaN, and both infinities for either field.
- [ ] Reject stage values above the final stage.
- [ ] Reject HighestFactoryStage below FactoryStage.
- [ ] Rebirths continues to reject invalid values and values above `Config.Security.MaxRebirths` through the existing validation.
- [ ] Every malformed case returns `INVALID_DATA` without field mutation, dirty marking, sync, or feedback.

## LifetimeEnergy boundaries

For each threshold below, prepare the press so post-press LifetimeEnergy is one below, exactly equal to, and one above the boundary:

- [ ] Stage 2: 500.
- [ ] Stage 3: 5,000.
- [ ] Stage 4: 50,000.
- [ ] Stage 5: 500,000.
- [ ] Stage 6: 5,000,000.

For every boundary:

- [ ] One below does not advance through the Energy path.
- [ ] Exact threshold advances to the expected stage.
- [ ] One above advances to the expected stage.
- [ ] Final stage remains 6 and does not overflow.

## Eligibility and progression rules

- [ ] A prepared canonical session can skip directly to the highest eligible stage.
- [ ] Prepared Rebirths values 1, 3, and 10 exercise Stage 4, 5, and 6 OR eligibility during a press.
- [ ] No stage ever decreases.
- [ ] If eligibleStage is not above old HighestFactoryStage, both stage fields remain byte-for-byte unchanged.
- [ ] FactoryStage is not forced up to HighestFactoryStage when no new highest stage is reached.
- [ ] A non-crossing press changes exactly Energy, LifetimeEnergy, and TotalPresses.
- [ ] A crossing press changes those three fields plus FactoryStage and HighestFactoryStage only.

## Atomicity, dirty marking, and sync

- [ ] Post-press Energy, LifetimeEnergy, and TotalPresses are computed before assignment.
- [ ] Eligible stage is calculated from post-press LifetimeEnergy and current Rebirths.
- [ ] Eligible stage output must be a finite integer within the stage range.
- [ ] Successful crossing and non-crossing presses each call `markDirty(player)` exactly once.
- [ ] Dirty failure restores Energy, LifetimeEnergy, TotalPresses, FactoryStage, and HighestFactoryStage exactly.
- [ ] Dirty failure causes no DataSync or PressFeedback.
- [ ] Dirty success calls `syncToClient(player)` exactly once.
- [ ] DataSync contains consistent post-transaction LifetimeEnergy, FactoryStage, and HighestFactoryStage.
- [ ] Sync failure does not roll back the dirty five-field transaction.

## Regression and explicit exclusions

- [ ] PressResult remains exactly `{ reward, syncSucceeded }`.
- [ ] PressFeedback still contains exactly reward, COMMON rarity name/color, and rarity index 1.
- [ ] Existing reward calculation, saturating counters, rate limiting, and failure behavior remain unchanged.
- [ ] WP-07B buyUpgrade API, validation, two-field mutation, rollback, rate limiting, and sync behavior remain unchanged.
- [ ] No FactoryEvolutionService, polling loop, PlayerAdded/PlayerRemoving connection, or load reconciliation exists.
- [ ] No FactoryEvolutionSync, global server stage, Workspace access, visibility mutation, or core recoloring exists.
- [ ] No rebirth-triggered progression, production, storage, capacity, or offline income exists.
- [ ] Main.server.lua, FactoryDefinitions, SessionRepository, and ServerDataService remain unchanged.
- [ ] Only the approved WP-08 allowlist changed.
