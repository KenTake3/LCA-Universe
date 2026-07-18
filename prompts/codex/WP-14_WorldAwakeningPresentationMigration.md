# WP-14 — World Awakening Player-Facing Presentation Migration Plan

Status: Plan only — no implementation authorized
Scope: Factory-related player-facing UI, text, and presentation
Product basis: `docs/PRODUCT.md`
Presentation basis: `docs/PresentationBible.md`

## 1. Objective

Reframe the current Factory-centered player-facing experience as the first awakening of an evolving world.

WP14 changes the language through which players understand existing behavior. It does not change the behavior itself. The Core and machinery remain part of the first playable setting, but “factory” stops functioning as the identity of the whole product. The intended emotional progression becomes:

**awaken → respond → transform → attach → create → share**

Only the first three steps are currently represented by confirmed playable behavior. Creation and sharing are long-term product direction and must not be presented as available features.

## 2. Non-Negotiable Boundary: Internal Names Stay Unchanged

WP14 must not rename or migrate any internal contract, including:

- Modules and files: `FactoryDefinitions`, `FactoryVisualController`, `FactoryService`, and all existing source paths.
- Data fields and attributes: `FactoryStage`, `HighestFactoryStage`, `LCA_FactoryStage`, `LifetimeEnergy`, `Rebirths`, and related saved fields.
- Events and types: `FactoryStageChanged`, `RebirthCompleted`, `FactoryEra`, `UpgradeLevelsChanged`, and existing RemoteEvent names and payload keys.
- Dependency members: `getFactoryName`, `getFactoryColor`, `majorFactoryEra`, and other internal parameters.
- Workspace hierarchy: `FactoryEvolution`, `Stage1` through `Stage6`, and authored descendant names.
- Stable IDs: `core_online`, `power_generator`, `industrial_factory`, `advanced_reactor`, `mega_factory`, `quantum_factory`, `ClickPower`, `AutoPower`, `CoreAmplifier`, and `Luck`.
- Gameplay terms whose renaming would alter a current contract: `Energy`, `Rebirth`, upgrade IDs, rarity IDs, balance values, eligibility rules, and stage numbers.

These names may remain visible in source, logs, tests, and engineering documentation. The migration introduces or revises display-facing copy at the presentation boundary only. No save migration, data schema change, RemoteEvent change, model rename, or compatibility adapter is required.

## 3. Product Language Direction

### Player-facing concepts

| Current framing | WP14 display direction | Meaning preserved |
| --- | --- | --- |
| Lucky Core Factory as the whole identity | LCA Universe / world awakening | The current factory is the opening place, not the entire product |
| Factory Evolution / Factory Stage | World Awakening / Awakening Stage | The same six-stage progression |
| Factory upgrade | World awakened / Awakening advanced | The same confirmed stage increase |
| Factory era milestone | Awakening milestone | The same major Rebirth-plus-stage presentation tier |
| Factory output | Core energy flow / world energy flow | The same calculated output |
| Final factory stage | Current awakening peak | The current definition ceiling, not the end of the universe |

This is a display lexicon, not authorization to rename internal symbols.

### Copy principles

- Lead with what changed in the world, not with the system that incremented.
- Keep the Core and machinery concrete; do not replace every industrial word with abstract fantasy language.
- Use “World” only for the player’s current place. Do not imply explorable planets, shared worlds, visiting, or world-building tools.
- Use “Awakening Stage” consistently wherever the current `FactoryStage` is presented.
- Preserve exact numbers, costs, requirements, rarity results, and reward values.
- Do not claim player choice, creation, customization, or sharing until those capabilities exist.
- Keep messages short enough for the existing UI bounds; layout expansion requires separate review.

## 4. Confirmed Target Inventory

### A. Product identity and entry copy

| Source | Current player-facing expression | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `src/client/MainGuiClient.client.lua` — `GameTitle` | `LUCKY CORE FACTORY` | `LCA UNIVERSE` as the product title; the factory remains visible in the scene | P0 | Every session; primary identity cue |
| Same file — initialization notification | `Welcome to Lucky Core Factory!` | Welcome the player to LCA Universe and invite the first awakening without promising a new action | P0 | First impression and product framing |

Proposed review copy:

- Title: `LCA UNIVERSE`
- Welcome: `Welcome to LCA Universe. Awaken the Core.`

The welcome line is valid only if “Awaken the Core” is understood as flavor for the existing Press interaction, not a distinct objective or promised system.

### B. Stage status and progression

| Source | Current player-facing expression | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `MainGuiClient.client.lua` — initial `FactoryStageLabel` | `Stage 1: Core Online` | `Awakening 1: Core Online` or `Awakening Stage 1: Core Online` | P0 | Persistent HUD |
| Same file — `updateUI()` | `Stage {n}: {stage name}` | `Awakening {n}: {display name}` | P0 | Persistent HUD and progression comprehension |
| Same file — next-stage progress | `{pct}% to {next name}` | `{pct}% to {next awakening name}`; avoid implying a separate feature | P0 | Persistent progression goal |
| Same file — alternate requirement | `Unlocked via Rebirths!` | `Awakening ready through Rebirth!` or shorter reviewed equivalent | P1 | Requirement comprehension; text-width risk |
| `FactoryDefinitions.lua` — `name` | Six industrial stage display names | Revise display values only; retain IDs, order, rules, colors, and thresholds | P0 | HUD, notification, and Rebirth presentation share this source |
| Same file — `description` | Factory/output-centered descriptions | Describe the visible world response at the same stage; make no claim about unavailable interactions | P1 | Currently not confirmed visible, but public display data and future-facing copy |

Candidate stage display set for product review:

| Internal ID — unchanged | Current display name | Candidate display name | Candidate description direction |
| --- | --- | --- | --- |
| `core_online` | Core Online | Core Awakening | The Core stirs and energy begins to flow. |
| `power_generator` | Power Generator | Energy Rising | New machinery carries power into the surrounding world. |
| `industrial_factory` | Industrial Factory | World in Motion | The awakened systems begin moving as one living place. |
| `advanced_reactor` | Advanced Reactor | Resonant Core | The Core’s growing energy transforms the world around it. |
| `mega_factory` | Mega Factory | Radiant Horizon | Power and structure spread across the visible world. |
| `quantum_factory` | Quantum Factory | Quantum Awakening | The current world reaches its highest available awakening. |

These are candidate display strings, not approved final copy. They deliberately describe only the existing visual progression. “Highest available” replaces “final” so the current six-stage ceiling is not presented as the universe’s final identity.

### C. Upgrade panel language

| Source | Current player-facing expression | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `src/shared/Config.lua` — `ClickPower.description` | `Increase energy earned per press.` | Keep mechanically clear; optionally connect the Press to awakening without obscuring value | P2 | Purchase comprehension |
| Same file — `AutoPower.description` | `Increase automatic energy production.` | Keep mechanically clear; describe continuing energy flow | P2 | Purchase comprehension |
| Same file — `CoreAmplifier.description` | `Amplify factory energy output.` | Remove factory-as-product framing: `Amplify the Core's energy output.` | P0 | Direct Factory wording in a repeated decision surface |
| Same file — `Luck.description` | `Improve the chance of valuable cores.` | Review “cores” against actual rarity reward semantics; do not invent collectible Cores | P1 | Risk of implying an unavailable collection result |

Upgrade display names can remain `Click Power`, `Auto Power`, `Core Amplifier`, and `Luck`. Their stable IDs must remain unchanged. Mechanical clarity takes precedence over thematic renaming on a purchase surface.

### D. Rebirth and major progression presentation

| Source | Current player-facing expression or treatment | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `src/client/RebirthPresenter.lua` | `FACTORY UPGRADE! Stage {n}: {name}` | `WORLD AWAKENED! Awakening {n}: {display name}` or a shorter reviewed variant | P0 | Highest-intensity Factory identity statement |
| Same file | Factory-stage increase uses gold emphasis | Preserve significance; review color against Awakening stage color and existing hierarchy | P1 | HUD emphasis and semantic consistency |
| Same file | `REBIRTH COMPLETE! Cycle {n}` | Keep gameplay term and exact cycle; optionally change tone to `REBIRTH COMPLETE — Cycle {n}` | P2 | Routine confirmed milestone |
| `MainGuiClient.client.lua` — Rebirth panel | `Rebirth to reset upgrades and get permanent multipliers!` | Keep the mechanic explicit; avoid replacing it with lore that hides reset consequences | P2 | High trust and decision clarity |
| Same file — Rebirth progress text | `Rebirths:`, `New Multiplier:`, cost in Energy | Preserve exact mechanic labels unless separately product-tested | P2 | Economy and consent |

`Rebirth` is currently a player-facing mechanic, not merely a Factory label. WP14 must not rename it as “Awakening” because that would conflate a repeatable reset with `FactoryStage` progression and make consequences less clear.

### E. Press, rarity, and reward feedback

| Source | Current player-facing expression or treatment | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `MainGuiClient.client.lua` — `PressButton` | `PRESS` | Candidate `AWAKEN`; approve only after confirming it still reads as the repeatable Energy action | P1 | Primary input; high comprehension and regression risk |
| `PressPresenter.lua` | `+{value}` confirmed popup | Keep exact value; theme is supplied by surrounding context, not extra copy | P3 | High-frequency readability |
| `MainGuiClient.client.lua` — rarity notification | `{rarity}! +{reward} Energy!` | Keep result and Energy exact; no Factory term requires migration | P3 | Reward trust |
| Same file — broadcast | `{player} rolled {rarity}! ({reward} Energy)` | Keep unless a separate randomness-language review is approved | P3 | Social/system notification |
| Same file — history empty state | `No rare pulls yet — keep pressing!` | If the primary action becomes `AWAKEN`, use mechanically unambiguous supporting copy; do not imply new discovery content | P2 | Terminology consistency |
| Same file — `JACKPOT!!!` and rarity flashes | Rarity-tier celebration | Keep event semantics; review intensity separately for calm-wonder alignment | P2 | Strong visual interruption and accessibility |

Renaming `PRESS` is optional, not a prerequisite for WP14. A safer first release changes identity, stages, and major milestone copy while retaining `PRESS` until usability validation shows that `AWAKEN` communicates a repeatable action.

### F. World visuals and presentation semantics

| Source | Current behavior | Planned direction | Priority | Impact |
| --- | --- | --- | --- | --- |
| `src/client/FactoryVisualController.lua` | Cumulative `Stage1`…`Stage6` world layers | Preserve all rendering behavior; reinterpret each reveal as the world awakening | P0 concept / no code change | Largest durable visual evidence of progression |
| `src/client/RebirthPresenter.lua` | Major stage event coordinates notification, color emphasis, audio cue, and camera cue | Preserve trigger and priority; revise the player-facing event meaning from Factory upgrade to Awakening milestone | P0 | Cross-channel semantic alignment |
| `src/client/AudioPresenter.lua` | Internal `FactoryEra` cue; no reviewed SoundId currently configured | Keep internal cue name; future asset brief should use an awakening motif, not generic production noise | P2 | Currently silent; future asset risk |
| `src/client/CameraPresenter.lua` | `FactoryEra` uses a stronger bounded FOV pulse | Keep internal cue and bounded behavior; evaluate whether it communicates world response without excess | P2 | Major milestone; reduced-motion behavior already exists |
| `docs/PresentationBible.md` | Fantasy and standards repeatedly center factory expansion | Plan a separate documentation-alignment patch after display copy approval | P1 documentation | Future work may otherwise reintroduce Factory-centered language |

No new models, particles, sounds, lighting, animations, camera paths, or world interactions are authorized by WP14. Existing visuals can support the new framing because they already show the environment becoming active and structurally richer.

### G. Authored Studio content requiring manual inventory

The Rojo source proves the programmatic UI listed above, but the repository does not fully prove all player-visible text embedded in the Roblox place. Before implementation, inspect Studio for:

- `SurfaceGui`, `BillboardGui`, `TextLabel`, `TextButton`, `TextBox`, `ProximityPrompt`, and `ClickDetector` text under `Workspace`.
- Signs, labels, decals with embedded words, and named map areas visible to players.
- UI or scripts not mapped by `default.project.json`.
- Authored sounds or visual effects associated with `Workspace.FactoryEvolution`.
- Localization tables, badges, game title/description, thumbnails, icons, and store copy outside this repository.

Record these as confirmed targets before changing them. Instance names alone are not player-facing and must remain unchanged under WP14.

## 5. Priority and Release Sequence

### P0 — Establish the identity

1. Approve the World Awakening vocabulary and six display stage names.
2. Change product title, welcome copy, persistent Awakening Stage label, and next-stage copy.
3. Change the major `FACTORY UPGRADE!` notification to the approved Awakening milestone copy.
4. Change `Core Amplifier` description to remove “factory output.”
5. Verify that all internal identifiers and gameplay behavior are byte-for-byte or semantically unchanged as applicable.

P0 creates the minimum coherent migration. Shipping only some of these surfaces would make the title say “Universe” while the main progression still declares the factory to be the product.

### P1 — Align supporting language

1. Review stage descriptions and the Rebirth-unlock status line.
2. Decide through a small comprehension test whether `PRESS` remains or becomes `AWAKEN`.
3. Resolve `Luck` copy so “valuable cores” does not promise collectibles that the reward does not grant.
4. Inventory Studio-authored and external product copy.
5. Align `PresentationBible.md` terminology in a separate documentation scope without changing its authority and ownership rules.

### P2 — Tune the emotional layer

1. Review rarity flashes, gold milestone emphasis, audio direction, and camera pulse against calm wonder and reduced-motion expectations.
2. Align history and supporting Rebirth copy after primary terminology is stable.
3. Prepare localization-ready strings and verify existing layout bounds.

### P3 — Preserve unless evidence supports change

Keep compact numeric reward feedback, rarity names, costs, level labels, Energy, Gems, and mechanically necessary terms stable. These surfaces already communicate the result and do not center Factory identity.

## 6. Impact Scope

### Directly affected in a future implementation

- Programmatic HUD title and stage status.
- Welcome and milestone notifications.
- Factory stage display names and descriptions consumed from shared definitions.
- Selected upgrade descriptions.
- Potentially the primary action label and supporting history copy after review.
- Product/presentation documentation and manual UI validation plans.

### Indirectly affected

- Text widths in the title, stage bar, notifications, upgrade cards, and Rebirth panel.
- Localization keys and translation memory if localization is introduced.
- Screenshots, trailers, thumbnails, game listing copy, tutorials, and store metadata outside source control.
- Future sound and visual asset briefs that currently refer to `FactoryEra` internally.
- QA terminology: testers must distinguish display term “Awakening Stage” from internal `FactoryStage` evidence.

### Explicitly unaffected

- Progression thresholds, stage order, unlock rules, rewards, rarity odds, costs, and multipliers.
- Persistence, saved data, migration, server validation, RemoteEvents, DataSync, and presentation event payloads.
- Factory layer visibility, Workspace structure, collision, effects, and reconciliation behavior.
- Rebirth reset behavior and purchase eligibility.
- Module, function, variable, instance, and file names.

## 7. Risks and Mitigations

| Risk | Severity | Why it matters | Mitigation |
| --- | --- | --- | --- |
| Cosmetic rename leaks into internal contracts | Critical | Can break saves, payload consumers, Workspace discovery, or tests | Maintain the immutable-name list; diff specifically for renamed symbols and serialized keys |
| New copy promises creation or sharing | High | Those are product direction, not confirmed playable capabilities | Restrict current copy to awakening, response, and visible transformation |
| “Awakening” obscures mechanical meaning | High | Players may not understand Stage, Press, Rebirth, costs, or requirements | Pair theme with exact numbers and stable mechanic terms; comprehension-test `AWAKEN` before replacing `PRESS` |
| Stage names imply visual changes that are absent | High | Copy and world evidence would contradict each other | Review every candidate name in Studio against actual Stage1–Stage6 authored layers |
| Shared definition copy is treated as internal-only | High | `FactoryDefinitions.name` feeds both HUD and major notifications | Map every consumer before implementation; change display values only |
| Text overflow and mobile readability | High | World Awakening phrases are generally longer than Factory labels | Use short approved variants; validate narrow viewports and maximum progress strings |
| Mixed terminology ships | Medium | Factory and Awakening labels together weaken identity and comprehension | Treat P0 surfaces as one release unit; use a player-facing string audit |
| Rebirth and Awakening become conflated | High | One is a reset cycle; the other is world-stage progression | Preserve `Rebirth`; reserve `Awakening` for display of `FactoryStage` and its milestone |
| External Roblox metadata remains Factory-centered | Medium | Store page and in-game identity would disagree | Inventory separately; do not mutate external state without explicit authorization |
| Localization work is duplicated | Medium | Hardcoded strings and shared definitions have no proven localization layer | Approve final source language first, then scope localization rather than inventing infrastructure inside WP14 |
| Existing presentation documentation reintroduces old framing | Medium | Future work may follow `PresentationBible.md` literally | Schedule a documentation-only alignment after terminology approval |
| Visual/audio escalation exceeds current scope | Medium | “World Awakening” could be misread as authorization for new VFX/assets | State clearly that WP14 is a semantic migration; asset additions require their own work package |

## 8. Implementation Gate

No code implementation should begin until the following are approved:

1. Final product title and welcome copy.
2. The display term for `FactoryStage`.
3. All six player-facing stage names and descriptions after visual inspection.
4. Major Awakening milestone notification copy.
5. Decision to keep or test-replace `PRESS`.
6. Exact list of Studio-authored and external surfaces in scope.
7. Whether localization infrastructure is explicitly in or out of the implementation work package.

## 9. Future Implementation Acceptance Criteria

These criteria define a later code/content work package; WP14 itself makes no runtime changes.

- No player-facing surface presents the factory as the final identity of LCA Universe.
- The factory remains legible as the current place and first awakening context.
- The HUD consistently displays the approved Awakening term and correct current stage number.
- All six stages display approved names matching their authored visuals.
- Major stage progression uses approved World Awakening copy exactly once under the existing trigger.
- Rebirth, Energy, reward, cost, and requirement meanings remain clear and numerically unchanged.
- No copy claims creation, customization, visiting, sharing, collaboration, or other unavailable capability.
- No internal name listed in Section 2 changes.
- Saved data, remotes, progression, rendering, and presentation triggers behave as before.
- All affected strings fit supported mobile and desktop layouts.
- Reduced-motion behavior and presentation cleanup remain unchanged.
- Studio-authored and external copy gaps are documented even when excluded from the implementation scope.

## 10. WP14 Deliverable

WP14 delivers this evidence-based inventory and migration plan only. It authorizes no source, Studio, asset, localization, product-page, or external metadata change.
