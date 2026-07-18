# WP-14A — World Awakening Terminology Manual Tests

Status: Implementation complete; Studio validation pending

## Scope

WP14-A changes player-facing Factory-centered terminology to the approved World Awakening vocabulary. It does not rename internal Factory contracts or change gameplay, progression, persistence, remotes, Workspace objects, animation timing, sound, camera behavior, or world-layer reconciliation.

## Static Review

- [x] Product title source text is `LCA UNIVERSE`.
- [x] Welcome source text is `Welcome to LCA Universe. Awaken the Core.`
- [x] Persistent stage source format is `Awakening {n}: {name}`.
- [x] The six approved awakening names and descriptions are present in order in the client display mapping.
- [x] Major stage-advance source format is `WORLD AWAKENED! Awakening {n}: {name}`.
- [x] `PRESS` remains unchanged.
- [x] Core Amplifier display description is `Amplify the Core's energy output.`
- [x] Luck display description is `Improve the chance of higher rarity rewards.`
- [x] Internal Factory identifiers, event names, saved fields, remotes, and Workspace names remain unchanged.
- [x] No server file, shared gameplay definition, progression threshold, reward calculation, persistence code, remote, or `FactoryVisualController` behavior was changed by WP14-A.

## Studio Setup

1. Build or sync the WP14-A project into a test place containing the authored `Workspace.FactoryEvolution/Stage1` through `Stage6` hierarchy.
2. Start a local server with one player and keep the Output window visible.
3. Test at a representative desktop viewport and at least one narrow mobile viewport.
4. Use only existing authoritative gameplay paths or reviewed test data to reach each stage; do not edit production balance as part of this test.

## Initial Presentation

- [ ] On first join, confirm the centered title reads exactly `LCA UNIVERSE`.
- [ ] Confirm the welcome notification reads exactly `Welcome to LCA Universe. Awaken the Core.` once.
- [ ] Confirm the initial stage status reads `Awakening 1: Core Awakening`.
- [ ] Confirm the main action button still reads `PRESS`.

## Six Awakening Stages

For each authoritative stage, confirm the persistent status uses the exact number and approved name:

- [ ] Awakening 1: `Core Awakening`
- [ ] Awakening 2: `Energy Rising`
- [ ] Awakening 3: `World in Motion`
- [ ] Awakening 4: `Resonant World`
- [ ] Awakening 5: `Radiant Horizon`
- [ ] Awakening 6: `Quantum Awakening`

- [ ] Confirm each name matches the correct existing `Stage1` through `Stage6` visible layer state.
- [ ] Confirm Awakening 6 does not display a nonexistent next-awakening goal.

## Progress Text

- [ ] Before each Energy-driven threshold, confirm the status suffix is `{pct}% to {next awakening name}` with the correct approved next name.
- [ ] Confirm the percentage still follows the existing authoritative progression calculation.
- [ ] Where the current `ENERGY_OR_REBIRTHS` condition has already met its Rebirth branch before stage reconciliation, confirm the suffix reads `Next awakening available through Rebirth.`
- [ ] Confirm no status displays `Factory Stage`, `Factory Evolution`, `Industrial Factory`, `Power Generator`, `Advanced Reactor`, or `Mega Factory`.

## Rebirth Presentation

- [ ] Complete an ordinary Rebirth that does not advance the stage and confirm the existing `REBIRTH COMPLETE! Cycle {n}` presentation remains exactly once.
- [ ] Confirm ordinary Rebirth still updates the displayed Rebirth count and multiplier without a World Awakening notification.
- [ ] Complete a Rebirth that advances the authoritative stage and confirm exactly one major notification reads `WORLD AWAKENED! Awakening {n}: {name}`.
- [ ] Confirm the major notification uses the approved name for the resulting stage.
- [ ] Confirm initial sync, reconnect, repeated DataSync, and corrective reconciliation do not create a historical stage-advance notification.

## Notifications and Upgrade Copy

- [ ] Confirm the welcome and stage-advance notifications fit their containers and remain readable for their full lifetime.
- [ ] Confirm routine rarity, failure, reward, and Rebirth notifications retain their existing meanings and priority behavior.
- [ ] Open Upgrades and confirm Core Amplifier reads `Amplify the Core's energy output.`
- [ ] Confirm Luck reads `Improve the chance of higher rarity rewards.`
- [ ] Confirm Click Power and Auto Power names, descriptions, costs, levels, and effects remain unchanged.

## Mobile and Terminology Audit

- [ ] At a narrow mobile viewport, confirm the title, all six awakening labels, longest progress suffix, welcome notification, and major notification do not clip or overlap controls.
- [ ] Confirm the normal player path contains no mixed Factory/World Awakening terminology in title, welcome, stage status, progress status, stage milestone, or relevant upgrade descriptions.
- [ ] Confirm no copy claims customization, creation, visiting, sharing, or collaboration is currently available.
- [ ] Inspect Studio-authored signs, BillboardGuis, SurfaceGuis, prompts, and external place metadata; record any Factory-centered player-visible wording not owned by Rojo source as a separate follow-up.

## Behavioral Regression

- [ ] Confirm Press still sends the same request and confirmed rewards remain exact.
- [ ] Confirm upgrade purchases retain the same costs, eligibility, effects, and authoritative confirmation.
- [ ] Confirm Auto Power production and progression remain unchanged.
- [ ] Confirm Rebirth eligibility, reset behavior, cost, multiplier, and server confirmation remain unchanged.
- [ ] Confirm DataSync fields and processing remain unchanged.
- [ ] Confirm each authoritative stage still makes all existing world layers at or below it visible and later layers hidden.
- [ ] Respawn and confirm UI, subscriptions, notifications, world reconciliation, and presentation behavior are not duplicated.
- [ ] Rejoin with persisted progress and confirm the correct awakening name appears without a historical celebration.
- [ ] Confirm Output contains no new relevant warnings or errors during the full pass.

## Known Manual Boundary

Studio-authored text and external Roblox metadata are not fully represented by the Rojo source tree. Any mixed terminology found there must be inventoried and approved separately; WP14-A does not rename Workspace objects or mutate external product metadata.
