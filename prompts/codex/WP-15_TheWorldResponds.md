# WP15 — The World Responds

Status: WP15-A implemented; WP15-B remains design-only

## 1. Problem Statement

WP14-B established a truthful relationship between input and the Core: local PRESS contact is non-authoritative, accepted `PressFeedback` produces the confirmed Core pulse, and positive `FactoryStageChanged` produces one major World Awakening timeline after stable layer reconciliation. The response currently stops at the Core. The player sees light and UI feedback, but the world does not yet visibly answer.

WP15 extends the causal sentence from:

```text
Player → Core
```

to:

```text
Player → Core → World → Player
```

The extension is presentation only. It must not add progress, change thresholds, infer Auto Power, mutate stable stage geometry, or introduce persistent atmosphere. A player should understand through motion and timing—not instructions—that accepted energy leaves the Core, reaches the nearby environment, and receives a visible answer.

## 2. Player Emotion Target

The intended moment is “I powered this place,” not merely “my number increased.”

- **Contact:** My action touched the Core.
- **Trust:** The stronger response happened only because the action was accepted.
- **Connection:** I saw energy travel outward.
- **Response:** Something in the world answered.
- **Return:** The response settles back toward the Core/player-facing UI, closing the loop without adding another reward claim.
- **Scale:** Repeated PRESS feels local and fluent; World Awakening feels like the same language expanded across the world.

The response must remain calm enough to repeat at the maximum accepted PRESS rate.

## 3. Current Implementation Findings

### Confirmed PRESS path

- `MainGuiClient` calls `PressPresenter.playContact()` and `EnergyPropagationPresenter.playContact()` before firing the existing `PressCore` request.
- Valid `PressFeedback` must first pass the existing payload checks and `PressPresenter.presentConfirmedReward()` before it reaches `EnergyPropagationPresenter.presentManual()`.
- `EnergyPropagationPresenter` currently owns one optional presenter-created `PointLight`, one active Tween, generation-based cancellation, reduced-motion cancellation, and teardown destruction.
- The PointLight is created once under an optionally discovered Core BasePart; it is never created per PRESS.
- Manual Core response currently lasts approximately 0.40 seconds: 0.08 seconds in and 0.32 seconds out.
- Rapid PRESS replaces the active Core pulse; there is no Core effect queue.

### Confirmed World Awakening path

- `FactoryVisualController.reconcile()` runs before client cache/UI update and before `PresentationCoordinator.processDataSync()`.
- Stable cumulative stage visibility is therefore correct before `WorldAwakeningPresenter` receives a positive `FactoryStageChanged` event.
- `WorldAwakeningPresenter` owns the rare timeline and latest-generation cancellation. It requests Core release immediately, internal `FactoryEra` audio at 0.25 seconds, camera at 0.90 seconds, and the approved notification at 0.95 seconds.
- Stage decreases cancel presentation; initial sync creates no semantic change event; rapid later positive stages invalidate earlier delayed callbacks.
- `FactoryVisualController` owns stage-descendant BasePart Transparency/collision/touch/query and Light/ParticleEmitter/Trail/Beam Enabled restoration. WP15 must not compete with those properties.

### Confirmed architectural baseline

- WP15-A extends `EnergyPropagationPresenter` with the exact approved Stage1 `BaseRing`, one pooled Beam, and one pooled target light. Stage-directed routing remains unimplemented.
- `WorldAwakeningPresenter` can request one undirected `playPropagation(color)` callback, but cannot specify the authoritative destination stage.
- No target registry is required for WP15-A. The verified exact hierarchy is resolved once by `MainGuiClient` without scanning.
- No new server or RemoteEvent information is required: valid `PressFeedback` distinguishes accepted manual PRESS, and positive `FactoryStageChanged` identifies the stage destination.

## 4. Verified Studio Asset Audit and Remaining Uncertainty

### Verified hierarchy

`default.project.json` does not map Workspace content, but the following hierarchy and classes were verified directly in Studio:

| Candidate | Evidence | Classification | Permitted conclusion |
| --- | --- | --- | --- |
| `Workspace.Interactive.EnergyCore.CoreHighlight` | Verified `Highlight` with approved baseline | Authored and explicitly excluded | WP15-A never reads or writes its Enabled, DepthMode, colors, or transparencies |
| `Workspace.Interactive.EnergyCore.CoreBase` | Verified BasePart | Not a WP15-A target | No property or child ownership added |
| `Workspace.Interactive.EnergyCore.CoreInner` | Verified BasePart with click detector and particles | Approved Core host for presenter-owned children | Existing properties/children remain untouched |
| `Workspace.Interactive.EnergyCore.CoreOuter` | Verified BasePart | Existing Core fallback only | WP15-A exact transfer origin remains resolved CoreInner when present |
| `Workspace.FactoryEvolution.Stage1.BaseRing` | Verified BasePart | Approved WP15-A destination and `FactoryVisualController`-owned stable geometry | Presenter-owned Attachment/PointLight children only; no authored property writes |
| `Workspace.FactoryEvolution.Stage2.Connector0`–`Connector3` | Verified BaseParts | WP15-B candidates only | No WP15-A resolution, references, or effects |
| Stage3–Stage6 targets | Not supplied or verified | Unknown | Do not invent paths |

`BaseRing` is a world anchor, not a machine. It represents the smallest awakened world available at Stage1: accepted energy visibly leaves the Core and reaches the first stable world layer. This is more accurate than implying that an unverified generator or reactor is active.

### Remaining WP15-B audit procedure

Before WP15-B, perform this procedure in the authoritative test Place and save the results in its manual validation document:

1. Open Explorer and Properties; do not rename or edit any object.
2. Expand `Workspace.Interactive` recursively and record for every candidate Core, floor, path, beam, light, attachment, emitter, neon, and nearby equipment object:
   - full `GetFullName()` path;
   - ClassName;
   - parent ClassName;
   - whether it is visible/collidable/interactable during normal play;
   - current relevant properties;
   - scripts or constraints referencing it, found with Studio Find All.
3. Expand `Workspace.FactoryEvolution`, record every direct `Stage%d+` folder, and count BaseParts, Lights, ParticleEmitters, Trails, Beams, and Attachments under each.
4. For each stage candidate, identify whether `FactoryVisualController` already writes its type/property. Anything whose Transparency, collision flags, or Enabled state is owned by the controller cannot be a WP15 temporary-property target.
5. Temporarily select—but do not modify—the nearest visible environmental BasePart to the Core. Confirm it is not a trigger, purchase zone, spawn, gameplay platform, or moving/constraint-owned object.
6. Enter Play Solo and observe which candidates are present after initial reconciliation for Stage1 and after each available stage transition.
7. Record before/after property snapshots around PRESS, Rebirth, respawn, and stage transition to detect other writers.
8. Classify each exact path as:
   - safe presentation-only target;
   - owned by `FactoryVisualController`;
   - gameplay/collision object;
   - unknown; manual approval required;
   - unsuitable.
9. Architect/product approves exact Connector route order and exact stage destinations before WP15-B references are added.

### Capability decision from current evidence

| Capability | Safe now? | Decision |
| --- | --- | --- |
| Core only | Yes, as already implemented | Presenter-owned PointLight child only |
| Core plus Stage1 world anchor | Yes | Exact approved destination is `Workspace.FactoryEvolution.Stage1.BaseRing` |
| Core plus Connector route | Not for WP15-A | `Connector0`–`Connector3` are WP15-B candidates only |
| Stage-specific activation targets | No | Stage folders are controller-owned and exact presentation-safe descendants are unconfirmed |

WP15-A is approved as `CoreInner → BaseRing`. WP15-B remains gated on Connector ordering and stage-specific target approval.

## 5. World-Response Visual Language

WP15 uses a three-part visual sentence:

1. **Release:** Existing Core light reaches confirmed color and peak.
2. **Travel:** One thin, presenter-owned signal moves or reveals from Core toward an approved target.
3. **Answer:** One approved target receives a brief presenter-owned light response, then both travel and answer settle.

### Preferred conservative primitive

Use presenter-owned children rather than modifying authored objects:

- one Attachment under the approved Core BasePart;
- one Attachment under the exact approved `BaseRing`;
- one reusable Beam connecting the two Attachments;
- one PointLight under the exact approved `BaseRing`.

These four objects are created once at initialization and destroyed at teardown. No object is created per PRESS. The Beam and target PointLight begin disabled/zeroed and are entirely WP15-owned, so authored properties require no temporary override.

WP15-A never reparents these objects or modifies `BaseRing`, `CoreHighlight`, or any authored effect. WP15-B may later use approved Connector routes through the same ownership model.

### Scale hierarchy

- **PRESS:** one short Core-to-near-target route; narrow Beam; low target brightness; no camera; no notification beyond existing reward channels.
- **Upgrade:** existing card emphasis remains medium and unrelated to WP15 route.
- **Ordinary Rebirth:** existing HUD/audio/camera treatment remains important; no stage route without stage increase.
- **World Awakening:** same visual grammar, longer route/duration, stronger but capped brightness, authoritative destination stage, existing camera and notification.

## 6. Exact Confirmed-PRESS Sequence

Target full duration: 0.62 seconds; acceptable tuned range: 0.40–1.00 seconds.

| Time | Step | Authority | Behavior |
| --- | --- | --- | --- |
| Before feedback | Contact | Local only | Existing button/Core neutral contact remains unchanged. No Beam or world target response. |
| 0.00–0.08s after valid `PressFeedback` | Core response | Authoritative manual acceptance | Existing confirmed Core pulse begins with validated rarity color. Existing exact reward popup remains immediate. |
| 0.06–0.18s | Travel | Authoritative | One pooled Beam reveals from `CoreInner` to `BaseRing`. Beam color uses the same lifted confirmed color; width/intensity is capped and does not scale with reward magnitude. |
| 0.18–0.32s | World answer | Authoritative | The presenter-owned `BaseRing` PointLight rises briefly. No authored `BaseRing` property changes. |
| 0.30–0.70s | Return/settle | Presentation only | Beam width fades to zero and disables; target light settles to zero; existing Core pulse settles independently. |

The “return” is the target answer plus the already visible reward/UI response; no reverse Beam is required in the initial implementation. This avoids doubling motion on every PRESS.

If the exact BaseRing path is missing, mismatched, removed, or reparented, `presentManual()` permanently falls back to the current Core-only response for that presenter instance.

## 7. Exact World Awakening Sequence

Target world-response duration: 2.10 seconds; acceptable range: 1.50–3.00 seconds. Stable stage state remains correct before time zero.

| Time | Step | Behavior |
| --- | --- | --- |
| 0.00–0.25s | Gather | Existing Core major gather; cancel/suppress ordinary PRESS world travel while exact PRESS UI can continue. |
| 0.25–0.60s | Release | Existing Core release and existing internal audio request at 0.25s. Beam begins toward the approved near-world route anchor. |
| 0.50–1.05s | World route | Reuse one Beam and target response in ordered hops only if exact approved anchors exist. Maximum two intermediate hops; no route discovery at event time. |
| 0.85–1.35s | Stage-directed answer | Move the pooled target response to the approved target mapped to the final authoritative `factoryStage`. It receives the strongest target-light response. Do not alter stage geometry or authored effects. |
| 0.90s | Camera | Preserve existing `FactoryEra` FOV request. |
| 0.95s | Notification | Preserve existing `WORLD AWAKENED! Awakening {n}: {name}` timing and priority. |
| 1.35–2.10s | Settle | Beam disables; target light returns to zero; Core settles; pooled target references return to neutral. Stable Factory layer remains untouched. |

If an exact stage target is unavailable, route to the approved near-world target and retain existing Core/camera/notification. Do not guess a stage descendant. If stages are skipped, map only the latest authoritative stage and play one sequence.

## 8. Target Ownership and Module Boundaries

### `EnergyPropagationPresenter` — extend

It remains the correct owner because it already owns Core response primitives, cancellation generations, reduced-motion response, and teardown. Extend it to own:

- exact approved `BaseRing` reference supplied at initialization;
- presenter-owned Attachment/Beam/target-light pool;
- one near-world route;
- no stage mapping in WP15-A;
- manual `presentManual(payload)` world response;
- existing `playMajor(color)` remains Core-only and cancels manual world response;
- independent bounded Core and world Tween slots, with one Core Tween maximum preserved.

It must not discover semantic stage state, subscribe to coordinator events, select rewards, own stable atmosphere, or write authored target properties.

### `WorldAwakeningPresenter` — retain orchestration

WP15-A leaves its callback and timing unchanged. Its existing `cancelPropagation()` then `playPropagation()` sequence cancels and neutralizes manual Beam/BaseRing response before major Core presentation.

### Narrow `WorldResponseTargetRegistry` — justified after audit

A data-only provider becomes justified if WP15-B has one near target plus stage-specific targets. It prevents `MainGuiClient` and effect code from duplicating exact Workspace paths and safety checks.

Responsibilities:

- resolve only exact Studio-approved paths once during composition;
- validate expected ClassName and allowed ancestry;
- return an immutable record: `{core, nearTarget, routeTargets, stageTargets}`;
- exclude missing/mismatched targets without scanning alternatives;
- create no effects, own no state, subscribe to nothing, and mutate nothing.

For WP15-A with only one approved near target, direct injection from `MainGuiClient` is smaller and preferred. Add the registry in WP15-B only when the approved target count/paths justify it.

### Preserved owners

- `FactoryVisualController`: sole stable stage visibility and authored restoration owner.
- `PresentationCoordinator`: semantic comparison/delivery only; unchanged.
- `PressPresenter`: button and exact reward popup only; unchanged.
- `MainGuiClient`: composition and valid payload routing only.

## 9. Authoritative Event Flow

```text
Local PRESS
  -> PressPresenter.playContact()
  -> EnergyPropagationPresenter.playContact()       [Core only; no world claim]
  -> existing PressCore request

Valid PressFeedback
  -> PressPresenter.presentConfirmedReward(payload)
  -> EnergyPropagationPresenter.presentManual(payload)
       -> confirmed Core response
       -> pooled Beam to approved near target
       -> pooled target answer
       -> settle

Valid DataSync
  -> FactoryVisualController.reconcile(...)         [stable state first]
  -> client UI/cache reconciliation
  -> PresentationCoordinator.processDataSync(...)
       -> positive FactoryStageChanged
          -> WorldAwakeningPresenter
             -> EnergyPropagationPresenter.playMajor(color, finalStage)
             -> existing audio/camera/notification callbacks
```

No new RemoteEvent, server change, or Workspace server mutation is justified.

## 10. Rapid-Input Aggregation

- Keep the existing PressPresenter 150ms exact reward aggregation unchanged.
- Maintain no world-response queue.
- `EnergyPropagationPresenter` keeps one current manual generation. A later valid PressFeedback retargets the Beam/target response and invalidates older callbacks.
- Use one active Core Tween maximum plus at most one Beam Tween and one target-light Tween. Replacement cancels the relevant slot before starting another.
- During an active World Awakening, accepted PRESS rewards and popup remain exact, but manual Beam/target travel is suppressed. The existing local button contact may continue.
- Rarity color follows latest accepted feedback for PRESS. World Awakening color has major priority until it settles.
- Reward magnitude never increases target count, Beam count, particle count, or brightness beyond reviewed caps.

## 11. Cancellation and Lifecycle Behavior

- **New PRESS confirmation:** cancel/retarget only manual world response; no stale callback may disable a newer Beam/light.
- **World Awakening begins:** cancel manual Beam/target response, restore WP15-owned objects to neutral, then start the major generation.
- **Newer positive stage:** cancel the current major generation and play one route to the latest approved destination.
- **Stage decrease:** cancel all major world response and show no success; stable controller reconciliation remains authoritative.
- **Same-stage DataSync:** no restart.
- **Respawn/teardown:** invalidate generations, cancel all Tween slots, disable Beam, set presenter-owned lights to zero, destroy presenter-owned pool, disconnect preferences, and release target references.
- **Target disappears:** cancel the affected slot, set surviving owned objects neutral, remove only that target reference, and fall back to Core-only. Do not rediscover or scan.
- **Target reparented outside approved ancestry:** treat as missing on the next semantic call; do not follow it into an unknown hierarchy.
- **Delayed callbacks:** every callback captures channel generation and owned instance identity before writing.
- **Presenter failure:** stable world and exact UI remain correct because reconciliation/routing precedes optional world effects.

## 12. Authored-Property Preservation

### Proposed initial target/property contract

| Target | Authored properties changed | WP15-owned properties | Baseline |
| --- | --- | --- | --- |
| Approved Core BasePart | None | Child Attachment; existing WP14 child PointLight | Owned instances start neutral; destroyed on teardown |
| Approved near-world BasePart | None | Child/reparented Attachment and target PointLight | Beam disabled/transparent; Brightness 0 |
| Approved stage BasePart | None | Same pooled target Attachment/PointLight temporarily parented | Neutral before/after use |
| Presenter-owned Beam | N/A | Enabled, Transparency, Color, Width0/Width1, Attachment0/1 | Disabled and fully transparent |
| Presenter-owned target PointLight | N/A | Brightness, Color, Range; Shadows false | Brightness 0 |

WP15 does not change authored BasePart Transparency, Color, Material, Size, CFrame, collision, touch, query, or any authored Light/Beam/Emitter property in the initial implementation.

### Stable baseline versus temporary override

- Stable authored state remains entirely outside WP15.
- WP15’s stable baseline is only the neutral state of its own children.
- Temporary override is a nonzero value on presenter-owned Beam/light.
- Cancellation restores owned neutral values synchronously before reuse.
- If an approved target is destroyed, Roblox destroys/reparents its owned children as applicable; the presenter validates references before every semantic call and cleans remaining instances safely.

Only a later separately approved optimization may use an existing presentation-only Beam/Light. That change requires exact authored-property capture, immutable baseline storage, independent temporary layer, and before/after Studio proof.

## 13. Reduced-Motion Behavior

- Preserve exact popup, stable stage layers, notification, and readable state.
- Confirmed PRESS: no traveling Beam. Briefly fade a static low-width connection or skip it; target PointLight may use one short non-traveling pulse capped below full-motion brightness.
- World Awakening: Core emphasis plus immediate target-light answer on the approved final target; no intermediate hops and no camera.
- Disable any Beam width travel, particle emission, repeated oscillation, or reverse motion.
- Preference change during an effect cancels all world travel immediately and restores owned neutral state.

## 14. Low-End Behavior

Until an explicit quality preference exists, the initial WP15-A implementation uses the conservative mobile baseline for everyone:

- one near target;
- one pooled Beam;
- one pooled target PointLight;
- no particles;
- no intermediate route hops;
- no shadows;
- no dynamic authored light control;
- semantic-event updates only.

WP15-B may add up to two route hops on full quality only after mobile profiling. Low-end remains direct Core-to-final-target with one Beam and one target pulse. Do not infer low-end from device type inside a presenter.

## 15. Performance Budgets

Per-client WP15 ceilings, excluding existing WP14 Core light/UI presenters:

| Resource | WP15-A ceiling | WP15-B full ceiling | Reduced/low-end | Rule |
| --- | --- | --- | --- | --- |
| Cached authored targets | 2: Core + near | 10: Core + near + max 2 routes + 6 stages | 2–8 resolved refs | Exact allowlist only |
| Presenter-owned instances | 4: 2 Attachments + 1 Beam + 1 target PointLight | 4 preferred; hard max 8 if fixed endpoints are required | Max 4 | Created once, zero per PRESS |
| Active WP15 Tweens | 2 world + existing 1 Core = 3 total | 2 world + existing 1 Core = 3 total | Max 1 world + Core | Separate replaceable slots; no queue |
| Lights | Existing 1 Core + 1 WP15 target | Same | Target light only; no shadows | Never one per target unless separately approved within hard instance cap |
| Beams | 1 active/owned | 1 active/owned | 0 or 1 static | Reuse by retargeting approved attachments |
| Particles | 0 | 0 initial; hard future ceiling 12 per major only | 0 | Not part of initial WP15 |
| Update frequency | Valid PressFeedback/stage event only | Same | Same | No polling, Heartbeat, RenderStepped |
| PRESS cleanup | ≤0.75s | ≤0.75s | ≤0.35s | Includes 0.1s margin; not Tween.Completed-only |
| Awakening cleanup | N/A | ≤2.35s | ≤1.0s | Latest event replaces |
| Discovery | One exact-path composition pass | Same | Same | No GetDescendants or whole-Workspace scan at runtime |

## 16. Implementation Phases

### WP15-A — Core-to-near-world response

Approved target: `Workspace.FactoryEvolution.Stage1.BaseRing`.

1. Extend `EnergyPropagationPresenter` dependencies with exact `BaseRing` resolution.
2. Add the four-object owned pool and independent Beam/target Tween slots.
3. Extend confirmed manual response only; local contact remains Core-only.
4. Suppress manual world travel during major presentation.
5. Add missing-target, rapid input, reduced-motion, teardown, and property-integrity tests.
6. Profile on narrow mobile before enabling any stage routes.

### WP15-B — Stage-directed World Awakening propagation

Gate: approve the order/meaning of Stage2 `Connector0`–`Connector3` and exact stage-specific destinations. Do not invent Stage3–Stage6 paths.

1. Add a data-only target registry if multiple exact paths are approved.
2. Change the major callback to carry destination stage without renaming the semantic event.
3. Extend the existing major timeline with at most two route hops and the strongest response at the final approved stage target.
4. Preserve existing 0.25/0.90/0.95 audio/camera/notification coordination.
5. Validate skipped stages, rapid snapshots, rejoin, missing per-stage target, and every available stage.

### Batch recommendation

Implement separately based on current evidence. WP15-A establishes the reusable world-target pool and restoration behavior with one approved target and high-frequency load. WP15-B adds authoritative stage routing only after WP15-A passes mobile and lifecycle validation and Studio identifies safe stage targets.

WP15-A proceeds independently with BaseRing. Do not combine WP15-B until Connector order and later-stage targets are verified.

## 17. Exact Files Likely to Change

### WP15-A

- `src/client/EnergyPropagationPresenter.lua` — extend owned pool, manual world sequence, cancellation.
- `src/client/MainGuiClient.client.lua` — resolve/inject one exact approved target and preserve valid payload routing.
- `tests/manual/WP-15A_CoreToWorldResponse.md` — new.
- `CHANGELOG.md`.

Expected unchanged: `PressPresenter.lua`, `PresentationCoordinator.lua`, `WorldAwakeningPresenter.lua`, `FactoryVisualController.lua`, `default.project.json`.

### WP15-B

- `src/client/EnergyPropagationPresenter.lua` — stage-directed route API.
- `src/client/WorldAwakeningPresenter.lua` — pass final authoritative stage to propagation callback.
- `src/client/MainGuiClient.client.lua` — inject approved target record.
- `src/client/WorldResponseTargetRegistry.lua` — new only if the approved multi-target inventory justifies it.
- `default.project.json` — only if the registry is added as a ModuleScript.
- `tests/manual/WP-15B_StageDirectedWorldResponse.md` — new.
- `CHANGELOG.md`.

Expected unchanged: `FactoryVisualController.lua`, `PresentationCoordinator.lua`, `PressPresenter.lua`, server/shared files.

## 18. Prohibited Files and Contracts

- All `src/server/` code and server Workspace mutation.
- All shared gameplay/economy/progression definitions and thresholds.
- Data schema, persistence, migration, save/load, and lifecycle.
- Existing RemoteEvents, payloads, DataSync fields, and PressFeedback contract.
- `FactoryStage`, `HighestFactoryStage`, `FactoryDefinitions`, `FactoryEvolution`, `Stage1`–`Stage6`, server services, and semantic presentation event names.
- `FactoryVisualController` stable ownership, cumulative visibility, caching, and authored restoration behavior.
- Gameplay BasePart Transparency, Color, Material, Size, CFrame, collision, touch, and query.
- Authored Light/Beam/ParticleEmitter/Trail Enabled or visual properties without a separate exact approval.
- Camera timing/CFrame/CameraType, notification text/priority, reward math, Rebirth rules, Auto Power behavior, and input availability.
- WP14-B3 progress atmosphere, continuous Core breathing, Auto Power ambience, UI progress bars, ambient audio, sky/day-night systems, and large particles.
- New creation, customization, visiting, sharing, or gameplay systems.

## 19. Risks and Mitigations

| Risk | Severity | Mitigation |
| --- | --- | --- |
| Guessed target path controls gameplay object | Critical | Mandatory exact Studio audit; allowlist path/class/ancestry; no alternative search |
| Conflict with FactoryVisualController | Critical | Presenter-owned children only; never write controller-owned geometry/effect properties |
| World response claims rejected PRESS | Critical | Trigger Beam/target only after existing valid PressFeedback path |
| High-rate PRESS accumulates effects | High | One pool, replaceable slots, generation tokens, no queue/instance per event |
| Major and manual effects fight | High | Major priority suppresses manual world channel; exact popup remains independent |
| Target deletion causes errors/drift | High | Validate each call, cancel affected channel, Core-only fallback, no rediscovery |
| Beam reads as weapon/laser | Medium | Thin energy-transfer language, short duration, soft lifted stage/rarity color, no impact burst |
| PRESS becomes too similar to Awakening | High | One local target and ≤0.75s for PRESS; stage destination, stronger light, camera/notification only for Awakening |
| Mobile overdraw | High | One Beam, two total presentation lights including Core, no particles/shadows, hard budgets |
| Partial stage mapping misdirects response | High | Explicit near-target fallback; never choose arbitrary Stage descendant |
| Binary string evidence treated as hierarchy | High | Mark tokens as hints only; require Explorer path/Class/property proof |
| B3 scope leaks into WP15 | Medium | Semantic events only; no persistent/periodic state or ambience APIs |

## 20. Acceptance Criteria

- Local PRESS creates no world travel before authoritative acceptance.
- Every valid PressFeedback can produce one `CoreInner`-to-`BaseRing` response in approximately 0.55–0.75 seconds.
- BaseRing visibly answers through a presenter-owned child light without any authored property mutation.
- Rapid accepted PRESS retargets one pool, creates no queue, and stays within all budgets.
- Missing/removed targets fall back to the current Core-only response without gameplay/UI failure.
- Auto Power, EnergyChanged, purchase, and Rebirth do not trigger manual world response.
- Positive `FactoryStageChanged` can direct one major response to the latest approved stage target in 1.50–3.00 seconds.
- Stable cumulative layers are correct before, during, and after optional presentation.
- Skipped/rapid stages produce one latest-state response and no historical queue.
- Existing audio at 0.25s, camera at 0.90s, and notification at 0.95s remain coordinated.
- PRESS remains clearly smaller than upgrades, ordinary Rebirth, and World Awakening.
- Reduced motion removes travel while preserving exact state, reward, and a static/brief target answer.
- Respawn, teardown, target loss, and interruption leave no Beam, light, Attachment, Tween, or stale callback leak.
- No server/shared/persistence/remote/gameplay/Workspace-name contract changes.
- Output contains no new relevant warnings/errors, and mobile profiling remains within Section 15 budgets.

## 21. Studio Validation Matrix

Studio-only items remain unchecked until executed.

| Area | Desktop | Narrow mobile | Reduced motion | Missing target | Required evidence |
| --- | --- | --- | --- | --- | --- |
| Asset inventory | [ ] | N/A | N/A | N/A | Exact paths, classes, properties, references, classifications |
| Initial join | [ ] | [ ] | [ ] | [ ] | No Beam/target response or historical celebration |
| Local PRESS before feedback | [ ] | [ ] | [ ] | [ ] | Core/button contact only; no world claim |
| Confirmed single PRESS | [ ] | [ ] | [ ] | [ ] | Core → Beam → near target → settle, exact popup |
| Rejected/malformed PRESS | [ ] | [ ] | [ ] | [ ] | No Beam/target response |
| Rapid maximum PRESS | [ ] | [ ] | [ ] | [ ] | One pool, bounded Tweens, no queue, cleanup deadline |
| Rarity colors | [ ] | [ ] | [ ] | [ ] | Legible, lifted, not weapon-like, no brightness overflow |
| Auto Power/non-PRESS Energy | [ ] | [ ] | [ ] | [ ] | No manual route or target pulse |
| Ordinary upgrade/Rebirth | [ ] | [ ] | [ ] | [ ] | Existing hierarchy unchanged |
| Stage 1 initial/rejoin | [ ] | [ ] | [ ] | [ ] | Stable layer, no World Awakening |
| Stage 2–6 transitions | [ ] | [ ] | [ ] | [ ] | Latest approved destination; stable layer unaffected |
| Rebirth plus stage | [ ] | [ ] | [ ] | [ ] | One major route, audio/camera/notification coordinated |
| Stage increase without Rebirth | [ ] | [ ] | [ ] | [ ] | Same authoritative major route |
| Skipped/rapid stages | [ ] | [ ] | [ ] | [ ] | Latest wins; no queued historical response |
| Stage correction/decrease | [ ] | [ ] | [ ] | [ ] | Cancel/neutral, no success presentation |
| Target removed/reparented | [ ] | [ ] | [ ] | [ ] | Core-only fallback, no rediscovery/error |
| Respawn during each phase | [ ] | [ ] | [ ] | [ ] | Pool destroyed/recreated once, neutral state, no duplicates |
| Property integrity | [ ] | [ ] | [ ] | [ ] | Exact authored before/after snapshot unchanged |
| Instance/Tween budget | [ ] | [ ] | [ ] | [ ] | Counts remain within Section 15 |
| Timing capture | [ ] | [ ] | [ ] | [ ] | PRESS 0.40–1.00s; Awakening 1.50–3.00s |
| Output | [ ] | [ ] | [ ] | [ ] | No new relevant errors/warnings |
| Full regression | [ ] | [ ] | [ ] | [ ] | PRESS, rewards, upgrades, Auto Power, Rebirth, DataSync, layers unchanged |

## Implementation Gate

WP15-A target approval is satisfied by `Workspace.FactoryEvolution.Stage1.BaseRing`. Do not begin WP15-B until Connector route order and exact later-stage destinations are approved; Stage3–Stage6 paths remain intentionally unspecified.
