# WP14-B — World Awakening Presentation

Status: Design and implementation plan only — no runtime implementation authorized
Product basis: `docs/PRODUCT.md`
Presentation basis: `docs/PresentationBible.md`
Terminology basis: WP14-A

## 1. Problem Statement

The current client accurately presents input, confirmed rewards, upgrades, Rebirth, and cumulative world stages, but those channels mostly operate beside one another. A PRESS compresses a button and creates a reward popup; DataSync updates numbers and world layers; a qualifying Rebirth adds a notification, color emphasis, silent semantic audio request, and bounded FOV pulse. The player can see correct results without yet feeling a continuous causal chain from their hand, through the Core, into the world.

WP14-B must make the existing progression feel like a world awakening without changing what progresses, how quickly it progresses, or which state is authoritative. Presentation must connect input, confirmation, Core response, energy propagation, stable environment state, UI, audio, and camera while remaining calm, readable, interruptible, mobile-safe, and bounded.

## 2. Player Emotion Target

The target emotional sequence is:

1. **Agency:** “I touched the system.”
2. **Response:** “The Core answered me.”
3. **Connection:** “Energy moved from the Core into this place.”
4. **Growth:** “The world is getting closer to waking.”
5. **Wonder:** “A meaningful part of the world just came alive.”
6. **Continuity:** “The final world state remembers what happened after the effect settles.”

PRESS should feel compact and repeatable. Progress should feel quietly present. World Awakening should be the rare, strongest event, but it must never become louder than the information it communicates.

## 3. Current-System Findings

### Confirmed authority and routing

- `MainGuiClient` fires `PressCore`, but accepted manual PRESS rewards arrive only through authoritative `PressFeedback`.
- `DataSync` is the authoritative client snapshot for Energy, `FactoryStage`, Rebirths, upgrade levels, and the current HUD/world state.
- `PresentationCoordinator` validates and compares Energy, `FactoryStage`, Rebirths, and four upgrade levels. It emits semantic differences and owns no UI, Workspace, audio, camera, or effects.
- An `EnergyChanged` event cannot safely identify its cause. Positive deltas may include manual PRESS or Auto Power; negative deltas may reflect purchases or Rebirth. It must not be used to claim a manual or automatic action.
- The current DataSync handler calls `FactoryVisualController.reconcile()` before updating UI and before `PresentationCoordinator.processDataSync()`.
- Initial valid DataSync seeds the coordinator and produces no historical presentation events.

### Confirmed presenter boundaries

- `PressPresenter` owns button compression, one 150ms confirmed-reward aggregation sequence, one popup, replaceable tweens, deterministic cleanup, and semantic Press audio requests.
- `RebirthPresenter` owns ordinary Rebirth emphasis and currently also owns the major Rebirth-plus-stage notification/audio/camera branch.
- `NotificationPresenter` owns at most three visible notifications, priority replacement, one-second duplicate suppression, opacity tweens, and cleanup.
- `AudioPresenter` owns one routine and one major sound slot. All SoundIds are currently empty, so every cue safely no-ops.
- `CameraPresenter` owns one replaceable FOV pulse. It never changes CFrame or CameraType and cancels immediately for reduced motion.
- `PresentationPreferences` currently exposes one in-memory reduced-motion boolean; there is no persisted preference or low-end setting.
- `FactoryVisualController` caches authored stage descendants once, restores authored BasePart visibility/collision/query/touch and enabled-effect state for visible cumulative layers, and hides later layers. It owns stable reconciliation, not celebration.

### Confirmed gaps and constraints

- No reviewed Core, path, light, particle, or sound asset contract exists in source.
- The existing `Workspace.FactoryEvolution/Stage%d+` hierarchy is known, but exact authored Core and energy-path objects must be inspected in Studio before implementation.
- `FactoryVisualController` does not expose its cached descendants and should not become a general effect manager.
- Stage rendering correctness must not wait for a 1.5–3.0 second sequence. A presenter failure or skipped animation must still leave the latest authoritative layer state visible.
- Current rarity flashes in `MainGuiClient` are separate legacy presentation and can overlap. WP14-B should not expand that legacy ownership; a later bounded cleanup may be needed if Studio testing shows conflict.
- The existing once-per-second `updateUI()` loop is historical UI behavior. WP14-B adds no polling and must not use that loop to drive atmosphere.

## 4. Presentation Principles

1. **Correct state first.** Stable UI and world reconciliation apply immediately from DataSync. Celebration may frame the new state but never gate it.
2. **Input is not success.** Immediate button/Core contact may acknowledge touch only. Reward magnitude, reward color, propagation release, and progression celebration wait for authoritative evidence.
3. **One cause, one visual sentence.** Manual PRESS uses `PressFeedback`; Auto Power uses a quiet automation state; stage change uses `FactoryStageChanged`. Do not infer cause from Energy delta.
4. **Reuse before creation.** Cache optional presentation targets once, reuse a fixed pool, retarget active tweens, and aggregate rapid input.
5. **Authored state is sacred.** Temporary overrides capture exact values and restore them on completion, replacement, preference change, respawn, failure, and teardown.
6. **Hierarchy by scale.** PRESS is local, upgrades are card-level, ordinary Rebirth affects important HUD elements, and World Awakening coordinates world/UI/audio/camera.
7. **Silence and absence are valid degradation.** Missing optional assets reduce spectacle, never correctness or input.
8. **No future-feature implication.** Effects communicate existing power, progress, and visible world change only.

## 5. Exact Moment-to-Moment PRESS Sequence

Target length per accepted sequence: approximately 0.45–0.90 seconds, with rapid confirmations aggregated.

| Time | Step | Authority | Presentation |
| --- | --- | --- | --- |
| 0ms | Input | Local, non-authoritative | Existing button compression begins; optional Core contact halo may tighten or brighten without displaying value or success color. `PressContact` audio remains semantic and replaceable. |
| 80–200ms | Await confirmation | No outcome claim | Button settles. Contact halo fades if confirmation has not arrived. No propagation, reward amount, rarity color, world pulse, or progress claim occurs. |
| On valid `PressFeedback` | Core response | Authoritative accepted manual PRESS | Core pulse retargets to the confirmed rarity color; amplitude is clamped and does not scale without bound by reward. Existing reward popup appears immediately and aggregates for 150ms. |
| +0–180ms | Energy propagation | Authoritative | One pooled propagation sequence travels from the Core toward a small fixed set of approved path anchors. Repeated confirmations add intensity within a cap and restart/retarget one sequence rather than spawn one per PRESS. |
| +150–800ms | Reward feedback | Authoritative | Existing aggregated numeric popup remains the exact reward channel. Rare-tier notification behavior remains separate. Optional `PressConfirmed` audio uses the existing routine slot. |
| By 900ms | Settle | Presentation only | Core/path temporary properties restore to their current stable baselines. No delayed callback may restore stale values over a newer effect generation. |

### Immediate versus authoritative behavior

Allowed immediately:

- PRESS button compression/restoration.
- A small neutral contact response on a confirmed optional Core target.
- Replaceable `PressContact` audio if an approved asset later exists.

Must wait for valid `PressFeedback`:

- Rarity color.
- Reward amount and confirmed audio.
- Outward energy propagation.
- Any world response that communicates accepted power.

### Rapid manual input

- Preserve the existing fixed 150ms reward aggregation window.
- Keep at most one active Core pulse and one active propagation sequence.
- Accumulate a bounded intensity counter of `1..3`; further accepted PRESSes refresh duration and aggregate the popup without adding instances, lights, or paths.
- New rarity color may retarget the active pulse only when its rarity rank is equal or higher; lower-tier confirmation still adds to the exact popup but does not visually downgrade the current pulse mid-sequence.
- There is no queue. Latest valid state plus highest active emphasis wins.

### Auto Power distinction

- Do not trigger manual contact, reward popup, rarity burst, or outward PRESS propagation from `EnergyChanged`.
- When the authoritative AutoPower upgrade level is above zero, show only a low, steady automation signature on approved Core/path targets: slow intensity breathing or a persistent low-strength path accent.
- Update automation enabled/disabled state only from accepted DataSync/upgrade-level state, not a timer that guesses production ticks.
- Auto Power may share cached targets but not manual pulse generation. Manual confirmation temporarily layers above or replaces the automation accent, then restores it.

### Reduced motion and low-end PRESS

- Reduced motion: keep button color/stroke or 0.98 compression, exact popup fading in place, and a brief non-traveling Core brightness change; disable traveling propagation.
- Low-end: retain button response, exact popup, and one Core color/brightness pulse; disable path travel and particles.
- If no Core/path targets are approved, existing button and popup behavior remains the complete safe fallback.

## 6. Awakening-Progress Presentation

Progress is derived from the same authoritative snapshot fields already used by `FactoryDefinitions.getProgress(FactoryStage, LifetimeEnergy, Rebirths)`. It is presentation of an existing calculation, not a new saved resource. The client must never interpolate gameplay progress between DataSync packets or imply that a visual sub-step is separately persisted.

### Stable progress signals

- **UI:** Add one compact, non-interactive progress fill behind or immediately below the current Awakening label. Set its fill directly from the accepted computed ratio; a short replacement tween may visually reconcile from the last displayed ratio, but cancellation snaps/reconciles to the newest ratio.
- **Core:** Map authoritative ratio into three broad visual bands rather than continuous per-frame updates: dormant `0–32%`, gathering `33–65%`, near-awakening `66–99%`. At `100%`, stable state remains restrained until an authoritative stage change occurs.
- **Energy paths:** Enable zero, one, or two approved ambient accent groups by progress band. Never reveal a future stage layer or imply unlock.
- **Environment:** Optional existing lights/effects may receive a small additive presentation offset within reviewed limits. Do not modify materials or permanent colors for progress.
- **Audio:** If approved looping ambience exists later, use at most one ambient layer with three reviewed mix levels and crossfade only on band changes. No asset is currently approved; initial implementation stays silent.

### Event/update model

- `MainGuiClient` computes the ratio only after a valid authoritative DataSync using existing definitions and passes `{stage, ratio, color, autoEnabled}` to the progress owner.
- Update only when the accepted stage, ratio band, exact UI ratio, color, or automation state changes.
- No Heartbeat, RenderStepped, `while`, or periodic polling.
- Rejoin/high-stage initial sync applies the stable band directly with no buildup or celebration.
- A Rebirth reset may lower Energy but must not regress `HighestFactoryStage`; progress presentation simply reconciles to the latest authoritative ratio produced by the existing rules.

## 7. Exact World Awakening Transition Timeline

Target full-motion duration: 2.20 seconds. Acceptable tuned range: 1.50–3.00 seconds. Gameplay input remains enabled throughout.

Stable `FactoryVisualController.reconcile()` still applies the authoritative cumulative layer state immediately before celebration. The timeline’s “activation” is a perceptual highlight of the newly visible layer, not deferred gameplay/state visibility. This avoids a presenter failure leaving the world stale.

| Time | Phase | Behavior |
| --- | --- | --- |
| 0.00–0.25s | Anticipation | Cancel lower-priority manual propagation. Core gathers using a bounded scale-free brightness/color pulse. HUD Awakening label receives a brief emphasis. Do not hide the newly reconciled layer. |
| 0.25–0.60s | Core release | One major semantic audio cue is requested; the Core reaches stage color and releases one pooled radial/anchor-based propagation. Routine audio is interrupted by existing priority rules. |
| 0.45–1.05s | World propagation | Approved path groups illuminate in deterministic Core-to-world order using cached targets. At most one group transition is active per route; no descendant scan occurs. |
| 0.75–1.30s | Layer activation highlight | Only newly entered stage targets receive a temporary additive highlight or enable-only transient overlay. Their stable authored visibility was already reconciled. Earlier cumulative layers remain stable. |
| 0.90–1.30s | Camera response | Existing `FactoryEra` FOV pulse runs once. No CFrame, CameraType, shake, blur, or input lock. Reduced motion skips it. |
| 0.95–1.45s | Notification | Existing major-priority channel shows exactly `WORLD AWAKENED! Awakening {n}: {name}`. It may outlive the world pulse under its existing bounded lifetime. |
| 1.30–2.20s | Settle | Temporary Core, path, light, and stage highlights restore to stable authored/progress baselines. UI progress resets/reconciles to the next authoritative target. Camera restores independently. |

### Stage increase during Rebirth

- `RebirthCompleted` continues to communicate the confirmed reset cycle.
- If the same accepted state comparison also increases `FactoryStage`, `WorldAwakeningPresenter` owns the one major Awakening sequence and notification.
- `RebirthPresenter` must suppress its current major branch and own only ordinary Rebirth emphasis/notification when no stage increase occurs. It must not duplicate audio, camera, notification, or world effects.
- The existing semantic event names and payloads remain unchanged.

### Stage increase without Rebirth

- A positive `FactoryStageChanged` event triggers the same World Awakening sequence even when Rebirth did not increase. This corrects the current limitation where only Rebirth-plus-stage receives major presentation.
- A stage decrease is treated as state correction only: stable reconciliation, no celebration.

## 8. Presenter and Module Ownership

### Existing modules

| Module | WP14-B ownership | Must not own |
| --- | --- | --- |
| `PresentationCoordinator` | Continue validating snapshots and emitting existing semantic events only | Effect scheduling, Workspace, UI, audio, camera, progress calculation, asset discovery |
| `PresentationPreferences` | Reduced-motion source; may add an in-memory low-end presentation tier only if separately approved in B1 | Platform guessing, persistence, gameplay settings |
| `PressPresenter` | Button contact and exact confirmed popup aggregation | Workspace Core/path effects, Auto Power inference, stage transition |
| `RebirthPresenter` | Ordinary Rebirth-only HUD emphasis and routine notification | Major World Awakening orchestration after B2 |
| `NotificationPresenter` | Existing bounded text channel and priority policy | Timeline ownership or success inference |
| `AudioPresenter` | Existing semantic one-shot slots; optionally one separately reviewed ambient slot in B3 | Asset selection without approval, world timing authority |
| `CameraPresenter` | Existing replaceable major FOV pulse | PRESS camera, CFrame, CameraType, shake, timeline orchestration |
| `FactoryVisualController` | Immediate, stable cumulative authoritative reconciliation and authored visibility restoration | Temporary pulses, progress atmosphere, notification/audio/camera, orchestration |
| `MainGuiClient` | Composition, accepted payload routing, display references, and calculation/pass-through of existing progress ratio | Rendering feature effects or becoming a scheduler |

### New `EnergyPropagationPresenter` — justified

This module owns the reusable physical response vocabulary shared by confirmed manual PRESS, automation ambience, authoritative progress bands, and a major release request. That responsibility cannot cleanly belong to `PressPresenter` because it includes non-PRESS stable world atmosphere, and it cannot belong to `FactoryVisualController` because it is temporary presentation outside stable layer reconciliation.

It owns:

- One cached optional Core target set.
- A fixed ordered set of optional path/accent target groups.
- One replaceable manual pulse, one stable progress/automation baseline, and one replaceable major propagation.
- Exact property capture, layered baseline calculation, generation tokens, cancellation, and restoration.
- No event subscription; callers provide already classified semantic requests.

### New `WorldAwakeningPresenter` — justified

This module owns one rare-event timeline spanning existing presenters. No existing presenter can own it without crossing its established feature boundary. It coordinates but does not reimplement rendering systems.

It owns:

- Subscription to existing `FactoryStageChanged` events.
- Positive-increase classification, one active timeline, generation/cancellation, skipped-stage metadata, and presentation timing.
- Calls to `EnergyPropagationPresenter`, `NotificationPresenter`, `AudioPresenter`, and `CameraPresenter` through injected narrow callbacks.
- Optional newly entered stage highlight targets supplied by a reviewed presentation-target adapter/cache.
- No stable world reconciliation, gameplay mutation, remote, reward calculation, or universal scheduling.

Only World Awakening events are orchestrated here; upgrades, routine Rebirth, rarity, and PRESS remain feature-owned.

## 9. Authoritative Event and State Flow

```text
Local PRESS
  -> PressPresenter.playContact()                         [non-authoritative]
  -> existing PressCore request                          [unchanged]

Valid PressFeedback
  -> PressPresenter.presentConfirmedReward(payload)      [exact popup]
  -> EnergyPropagationPresenter.presentManual(payload)   [Core/path response]

Valid DataSync
  -> FactoryVisualController.reconcile(FactoryStage, Rebirths)
                                                        [stable state first]
  -> existing client cache and HUD update
  -> existing FactoryDefinitions.getProgress(...)
  -> EnergyPropagationPresenter.reconcileProgress(...)
                                                        [stable atmosphere]
  -> PresentationCoordinator.processDataSync(packet)
      -> UpgradeLevelsChanged -> UpgradePresenter
      -> RebirthCompleted -> RebirthPresenter             [ordinary only]
      -> FactoryStageChanged positive -> WorldAwakeningPresenter
          -> cancel lower response
          -> major propagation
          -> optional stage highlight
          -> existing audio/camera/notification callbacks
```

No new RemoteEvent is justified. DataSync, PressFeedback, and existing semantic events provide the required authority.

## 10. Interruption and Cancellation Behavior

- **New manual confirmation:** Retarget the one manual pulse/propagation and aggregate reward; no queue.
- **World Awakening begins:** Cancel manual travel and temporarily override the presentation baseline with major priority. Exact numeric popup may finish because it does not conflict with world state.
- **Newer stage increase:** Cancel/restore the active major timeline, reconcile latest stable state, then play one sequence for the newest stage. For skipped stages, display only the final authoritative Awakening number/name and use one combined propagation; do not queue historical celebrations.
- **Repeated same-stage DataSync:** Reconcile stable progress only; do not restart celebration.
- **Stage decrease/correction:** Cancel any active major sequence, restore owned properties, apply stable reconciliation, and show no success presentation.
- **Respawn/teardown:** Disconnect subscriptions, invalidate all generations, cancel tweens, stop owned sounds through existing presenter teardown, destroy pooled temporary UI/instances, and restore captured properties before releasing references.
- **Rejoin at higher stage:** Initial snapshot applies correct layers/progress directly; no celebration.
- **Missing assets:** Each channel independently no-ops. Notification and stable state still succeed.
- **Presenter failure:** Coordinator listener isolation already uses `pcall`; the failed effect must restore in its own protected cleanup path and cannot prevent other listeners or stable reconciliation.
- **Reduced motion toggled mid-effect:** Immediately cancel travel/camera, restore targets, then apply the static reduced-motion state for the latest authoritative progress.
- **Input during transition:** PRESS and all controls remain usable. New accepted rewards update exact UI, but world travel may be suppressed until the major timeline settles.

## 11. Reduced-Motion Behavior

- Keep immediate state reconciliation, exact rewards, Awakening label, stage notification, and stage color.
- PRESS uses existing 0.98 compression or a static color/stroke response; confirmed Core response is one short opacity/brightness change without spatial travel.
- Progress uses a static UI fill and discrete Core/path visibility bands with direct or short crossfade transitions.
- World Awakening sequence compresses to approximately 0.6–1.0 seconds: static Core emphasis, immediate stable layer state, notification, then settle.
- Disable traveling propagation, repeated oscillation, particle bursts, and CameraPresenter entirely.
- Audio may remain unless a future independent audio preference disables it; meaning never depends on audio.

## 12. Low-End-Device Behavior

Low-end mode is an explicit presentation quality choice, not automatic platform inference in this work package.

- Retain exact UI, button response, stable world layers, one Core pulse, notification, and authored stage color.
- Disable particles and traveling path groups; allow at most one static path accent.
- Do not add dynamic lights for PRESS. Major transition may use at most one cached light if approved.
- Skip ambient audio layering and use only approved one-shots.
- Keep the existing bounded camera pulse unless reduced motion is also enabled; product review may disable it in low-end mode.
- Apply quality changes only at semantic events or preference changes, never every frame.

If no low-end preference UI is approved, B1 ships one conservative mobile baseline rather than hidden device heuristics.

## 13. Authored-Property Preservation Rules

### Allowed temporary properties, subject to Studio asset audit

- `BasePart.Color` and `Material` are **not** modified in WP14-B.
- `BasePart.Transparency` may be changed only on explicitly approved presentation-only Core/path targets, never on cumulative stage geometry owned by `FactoryVisualController`.
- `Light.Brightness`, `Light.Color`, and optionally `Light.Range` may be changed on explicitly approved cached lights.
- `ParticleEmitter.Enabled` and a bounded one-shot `Emit(count)` may be used only on approved presentation emitters; authored continuous emitters are not disabled or repurposed.
- `Beam.Enabled`, `Beam.Transparency`, and `Beam.Color` may be changed only on explicitly approved presentation beams.
- UI progress fill size/transparency/color may be changed on presenter-owned UI only.
- Collision, touch, and query properties are never temporary presentation controls.

### Capture and restoration

- Cache targets once at initialization from an explicit allowlist or injected references; do not scan the whole Workspace.
- Capture every property before first ownership. Store a per-instance immutable authored baseline.
- Maintain separate stable progress/automation baseline and temporary effect layer. Settle restores the latest stable baseline, not an obsolete authored-only value.
- Use generation tokens so delayed cleanup cannot overwrite a newer effect.
- Restore synchronously on replacement, stage correction, reduced-motion change, destroy, and respawn.
- If an instance disappears or changes class, skip it safely and remove the stale cache entry; do not rediscover continuously.
- `FactoryVisualController` remains the sole writer of stage geometry Transparency, `CanCollide`, `CanTouch`, `CanQuery`, and authored effect Enabled state.

## 14. Performance Budgets

Budgets are per client and include all new WP14-B presentation work:

| Resource | Full mobile baseline | Reduced motion / low-end | Rule |
| --- | --- | --- | --- |
| Temporary instances | Maximum 4, pooled; target 0 per PRESS | Maximum 1 | No unbounded creation; destroy pool on teardown |
| Active new tweens | Maximum 8 total; max 3 for PRESS, 8 for Awakening | Maximum 3 | Replacement, never queue |
| Particle emission | Maximum 12 particles per confirmed aggregated PRESS sequence; 40 per Awakening | 0 | Only approved pooled emitters; exact counts reviewed in Studio |
| Concurrent presentation sounds | Existing 1 routine + 1 major; optional B3 ambient adds max 1 | Max 1 one-shot; no ambient | No per-PRESS Sound creation outside AudioPresenter |
| Camera effects | Maximum 1 existing replaceable FOV sequence | 0 reduced motion | No PRESS camera; no CFrame/CameraType |
| Temporarily controlled lights | Maximum 3 cached lights | Maximum 1 | No light creation per event |
| Path/accent groups | Maximum 3 ordered groups, 8 targets total | 1 static group | Explicit cache, no runtime descendant scan |
| Update frequency | Semantic events only | Semantic events only | No polling, Heartbeat, RenderStepped, or per-frame scripts |
| Cleanup deadline | PRESS ≤1.0s; Awakening ≤3.25s including margin | ≤1.25s | Cleanup cannot depend only on Tween.Completed |
| Discovery | One bounded initialization pass under approved roots | Same | No repeated or whole-Workspace scans |

These are ceilings, not targets. Initial implementation should use fewer effects until Studio profiling proves headroom.

## 15. Implementation Phases

### WP14-B1 — Responsive Core and Energy Propagation

- Complete Studio asset/anchor audit first.
- Add `EnergyPropagationPresenter` with explicit injected targets, authored-property capture, pooled/manual response, automation baseline, progress input contract, teardown, and reduced-motion fallback.
- Route valid `PressFeedback` to it only after existing validation.
- Keep one conservative Core response if path assets are not approved.
- Add focused manual tests and static budget checks.

### WP14-B2 — Awakening Transition Orchestration

- Add `WorldAwakeningPresenter` subscribing only to existing `FactoryStageChanged`.
- Move the major stage branch out of `RebirthPresenter`; preserve ordinary Rebirth.
- Coordinate major propagation, optional new-layer highlight, existing `FactoryEra` audio/camera cue, and major notification.
- Preserve immediate `FactoryVisualController` reconciliation and test all interruption cases.

### WP14-B3 — Progress Atmosphere and Polish

- Add the compact UI progress fill and route existing authoritative ratio.
- Enable discrete Core/path progress bands and distinct automation ambience.
- Add approved ambient or one-shot assets only if an asset review supplies IDs and ownership.
- Profile mobile, tune budgets downward, audit rarity-effect overlap, and validate all six authored stages.

### Safe batching recommendation

B1 should ship alone as the first batch because it establishes target discovery, property ownership, pooling, and cleanup used by later phases. After B1 is Studio-validated, B2 may be implemented as its own batch. B3 should remain separate because stable atmosphere, UI layout, audio assets, and device-quality tuning carry different risks.

B1 and B2 should not be combined initially: doing so would mix high-frequency effect ownership with rare-event orchestration before the property-restoration foundation is proven. B2 and the UI-only portion of B3 may be combined only after B1 if the diff remains focused and no ambient asset or world-property expansion is included.

## 16. Exact Files Likely to Change

### WP14-B1

- `src/client/EnergyPropagationPresenter.lua` — new, narrowly scoped.
- `src/client/PressPresenter.lua` — only if a narrow confirmed-response callback is preferred; otherwise unchanged.
- `src/client/MainGuiClient.client.lua` — target injection and authoritative routing/composition.
- `src/client/PresentationPreferences.lua` — only if an explicit reviewed quality tier is added.
- `default.project.json` — map the new presenter.
- `tests/manual/WP-14B1_CoreEnergyPropagation.md` — new validation contract.
- `CHANGELOG.md`.

### WP14-B2

- `src/client/WorldAwakeningPresenter.lua` — new event-specific orchestrator.
- `src/client/RebirthPresenter.lua` — remove only duplicate major-stage ownership; retain ordinary Rebirth.
- `src/client/MainGuiClient.client.lua` — dependency composition.
- `src/client/AudioPresenter.lua` — only if a reviewed cue contract needs a new semantic alias; prefer retaining `FactoryEra` internally.
- `src/client/CameraPresenter.lua` — expected unchanged; existing `FactoryEra` callback is sufficient.
- `src/client/FactoryVisualController.lua` — expected unchanged; any read-only target adapter must be separately justified and must not change reconciliation.
- `default.project.json`.
- `tests/manual/WP-14B2_WorldAwakeningTransition.md`.
- `CHANGELOG.md`.

### WP14-B3

- `src/client/EnergyPropagationPresenter.lua` — stable progress/automation bands.
- `src/client/MainGuiClient.client.lua` — presenter-owned progress UI creation/reference and authoritative ratio pass-through.
- `src/client/AudioPresenter.lua` — only after approved assets and ambient ownership contract.
- `src/client/PresentationPreferences.lua` — only for explicit quality controls.
- `tests/manual/WP-14B3_AwakeningProgressAtmosphere.md`.
- `CHANGELOG.md`.

`NotificationPresenter.lua`, `UpgradePresenter.lua`, `PresentationCoordinator.lua`, and `PressPresenter.lua` are expected to remain unchanged unless a phase demonstrates a concrete narrow contract need.

## 17. Files and Contracts Explicitly Prohibited From Change

The following are outside WP14-B implementation scope:

- All `src/server/` files and server services.
- Shared gameplay definitions and calculations under `src/shared/`, including thresholds, costs, rarity, upgrade effects, and `FactoryDefinitions` behavior.
- Persistence repositories, schemas, migration, save/load, and lifecycle code.
- RemoteEvent instances, names, payloads, and server/client authority.
- `FactoryStage`, `HighestFactoryStage`, `FactoryDefinitions`, `FactoryVisualController`, `FactoryEvolution`, `Stage1` through `Stage6`, DataSync fields, persistence fields, and semantic presentation event names.
- Workspace object renames, stage model replacement, gameplay collision design, and server-owned world mutation.
- Reward calculations, Rebirth eligibility/reset rules, Auto Power production, and progression thresholds.
- Sound IDs without explicit asset approval.
- Camera CFrame, CameraType, shake, animation timing outside the approved presentation phase, and input blocking.
- Historical WP12/WP13 records except new forward references where separately requested.

## 18. Risks and Mitigations

| Risk | Severity | Mitigation |
| --- | --- | --- |
| Presentation masks or delays authoritative stage state | Critical | Reconcile stable layers first; celebration only overlays perception |
| Temporary effects permanently drift authored properties | Critical | Explicit allowlist, immutable capture, layered baseline, generation tokens, synchronous restore |
| Manual/Auto Power attribution is false | High | Manual uses PressFeedback only; Auto is a stable enabled signature, never inferred from Energy delta |
| Rebirth and stage events duplicate major effects | High | Transfer major ownership to WorldAwakeningPresenter; RebirthPresenter handles ordinary path only |
| Skipped/rapid stages queue long celebrations | High | Latest stage wins; one combined sequence; no historical queue |
| Missing Studio assets makes B1 speculative | High | Mandatory target audit; Core-only fallback; no invented instance names |
| Mobile particle/light overdraw | High | Hard ceilings, low-end mode, profile each stage, start below budget |
| Existing rarity flashes compete with Awakening | Medium | Major priority suppresses new lower effects; Studio overlap audit; do not expand legacy flash behavior in B1/B2 |
| UI progress appears to be independently saved | Medium | Update only from DataSync-derived existing ratio; no interpolation or local accumulation |
| Coordinator becomes universal scheduler | High | No coordinator changes; new presenters subscribe narrowly or accept injected semantic calls |
| Failure leaves presenter state active | High | Protected cleanup, teardown tests, bounded deadlines, independent stable reconciliation |
| Progress targets conflict with FactoryVisualController | Critical | Never override stage geometry visibility/collision/effect ownership; use presentation-only allowlisted targets |
| Unapproved audio creates scope drift | Medium | Empty cues remain safe; asset review is a gate, not a placeholder-ID task |

## 19. Acceptance Criteria

- Every local PRESS immediately acknowledges contact without claiming reward.
- Every valid PressFeedback can produce one bounded Core-to-world response and the exact existing reward popup.
- Rapid PRESS never creates an unbounded queue, one object per event, or accumulating sound/camera effects.
- Auto Power has a quiet, clearly different stable signature and never triggers manual PRESS presentation.
- Progress UI and atmosphere derive only from accepted DataSync and existing progress calculation.
- A positive authoritative stage change produces one 1.5–3.0 second World Awakening sequence with the approved notification.
- Stable stage layers are correct even if celebration is skipped, interrupted, missing assets, or fails.
- Ordinary Rebirth remains important but does not duplicate a World Awakening sequence.
- Initial sync/rejoin produces no historical celebration; skipped stages produce one latest-state sequence; decreases produce none.
- Reduced motion and low-end modes preserve exact state and text while removing travel/particle/camera load as defined.
- All temporary properties restore exactly to the latest stable baseline after completion, cancellation, respawn, and repeated events.
- Performance remains within Section 14 budgets with no polling or unbounded scans.
- PRESS, upgrades, Auto Power, Rebirth, DataSync, persistence, remotes, and world-layer visibility remain behaviorally unchanged.
- Output contains no new relevant errors and respawn creates no duplicate subscriptions, pools, sounds, or effects.

## 20. Studio Validation Matrix

Studio-only checks remain unchecked until executed.

| Area | Desktop | Narrow mobile | Reduced motion | Low-end | Required cases |
| --- | --- | --- | --- | --- | --- |
| Local PRESS contact | [ ] | [ ] | [ ] | [ ] | No success claim before feedback; button restores |
| Confirmed PRESS chain | [ ] | [ ] | [ ] | [ ] | Core, propagation, exact popup, settle |
| Rapid PRESS | [ ] | [ ] | [ ] | [ ] | Max input rate, one pooled sequence, bounded instances/tweens/sounds |
| Rejected/malformed PRESS | [ ] | [ ] | [ ] | [ ] | No confirmed Core/path/reward response |
| Auto Power | [ ] | [ ] | [ ] | [ ] | Distinct steady signature; no manual popup or pulse |
| Progress bands | [ ] | [ ] | [ ] | [ ] | 0/32/33/65/66/99/100%, no threshold change or false unlock |
| Stage 1 initial/rejoin | [ ] | [ ] | [ ] | [ ] | Correct stable state, no celebration |
| Stages 2–6 | [ ] | [ ] | [ ] | [ ] | Correct layer, color, progress reset, one timeline |
| Ordinary Rebirth | [ ] | [ ] | [ ] | [ ] | Existing routine presentation only |
| Rebirth + stage | [ ] | [ ] | [ ] | [ ] | One World Awakening, no duplicate major branch |
| Stage increase without Rebirth | [ ] | [ ] | [ ] | [ ] | Same World Awakening sequence |
| Rapid/skipped DataSync | [ ] | [ ] | [ ] | [ ] | Latest wins; one sequence; no stale restoration |
| Stage correction/decrease | [ ] | [ ] | [ ] | [ ] | Stable correction, no success presentation |
| Missing Core/path/light/effect | [ ] | [ ] | [ ] | [ ] | Graceful channel no-op, correct UI/world |
| Presenter-injected failure | [ ] | [ ] | [ ] | [ ] | Other listeners/state continue; owned properties restore |
| Respawn during each phase | [ ] | [ ] | [ ] | [ ] | Cleanup, restore, no duplicates |
| Camera replacement | [ ] | N/A | [ ] | [ ] | Old FOV restored, no CFrame/CameraType writes |
| Notification overlap | [ ] | [ ] | [ ] | [ ] | Major remains readable; routine bounded |
| Rarity overlap | [ ] | [ ] | [ ] | [ ] | No unreadable flash/major collision |
| Authored properties | [ ] | [ ] | [ ] | [ ] | Exact before/after comparison across repeated transitions |
| Performance profile | [ ] | [ ] | [ ] | [ ] | Budgets, frame time, instance count, cleanup deadlines |
| Full regression | [ ] | [ ] | [ ] | [ ] | PRESS, upgrades, Auto Power, Rebirth, DataSync, layers, Output |

## Asset and Design Approval Gates

Before B1 implementation, approve:

- Exact existing Core instance(s) and whether they are safe presentation targets.
- Exact path/accent groups and ordering, or approval to ship Core-only.
- Which existing lights, beams, and emitters are presentation-only versus owned by stage reconciliation.
- Whether a dedicated low-end preference is exposed or the conservative baseline is universal.

Before B2 implementation, approve:

- Whether stage-layer activation highlight uses existing presentation-only descendants or Core/path light alone.
- Final full-motion timeline tuning within 1.5–3.0 seconds.
- Whether stage increase without Rebirth receives identical or slightly reduced intensity; this plan recommends identical World Awakening treatment.

Before B3 audio implementation, supply reviewed SoundIds and usage rights. Until then, all existing semantic audio cues remain intentional no-ops and no ambient layer is implemented.
