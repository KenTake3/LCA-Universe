# LCA Universe Presentation Bible

Status: WP13-C first draft

Scope: client presentation language and ownership; no gameplay contract changes

## 1. Presentation Philosophy

LCA Universe presents one continuous fantasy: the player directly powers a machine, expands a factory, and advances it into a new technological era. Presentation should make cause and effect legible before it makes the screen spectacular.

### Responsiveness

- Input acknowledgement should begin immediately when it does not imply server success, such as Press-button compression.
- Rewards, purchases, progression, and completion are presented only after authoritative confirmation.
- Frequent feedback should replace, retarget, or aggregate existing presentation instead of creating an unbounded queue.
- Presentation must never delay, block, or mutate gameplay transactions.

### Clarity

- Every effect must communicate one primary fact: input received, value changed, action rejected, feature locked, or milestone completed.
- Persistent UI reflects the latest authoritative state and takes precedence over transient effects.
- Color, motion, sound, and text must agree. A failure must not use success color or celebratory motion.
- Effects must not obscure controls, currency values, costs, or Factory Stage status.

### Anticipation

- Anticipation is reserved for actions whose outcome is already authoritative or whose local motion cannot imply success.
- Routine actions use little or no anticipation. Major progression may briefly gather visual and audio energy before release.
- Anticipation must be cancellable and must not leave UI or world objects in an intermediate state.

### Celebration

- Celebration intensity scales with significance, not input frequency.
- Press rewards are compact and repeatable; upgrades are discrete confirmations; Rebirth and Factory Stage advancement may coordinate several presentation channels.
- Celebration never invents state. DataSync and confirmed server feedback remain the source of truth.
- Reconciliation must still complete if a celebration is skipped, interrupted, or reduced.

### Readability

- Text remains readable against both UI and world backgrounds through sufficient contrast and bounded placement.
- Numeric feedback uses concise formatting without hiding the authoritative magnitude.
- Transient text must remain on screen long enough to scan, but must not accumulate over important HUD elements.
- Presentation is tested at supported mobile and desktop viewport sizes.

### Accessibility

- Meaning is never conveyed by color alone; pair color with text, shape, iconography, or motion.
- Rapid flashes, strong camera movement, repeated vibration-like motion, and dense particle fields are opt-in to the full presentation tier and constrained by safety limits.
- Reduced-motion behavior must preserve state changes, text, and hierarchy while removing nonessential travel, scale oscillation, and camera movement.
- Audio cues supplement visible information and are not required to understand an outcome.

## 2. Event Priority

When events overlap, higher-priority presentation may suppress or shorten lower-priority transient effects, but it must not suppress authoritative state reconciliation.

| Priority | Class | Examples | Policy |
| --- | --- | --- | --- |
| P0 | Safety and state correction | Reconcile Factory layers, restore owned UI state, remove stale temporary instances | Immediate and non-skippable |
| P1 | Major progression | Rebirth plus Factory Stage increase, future era milestone | May interrupt P3–P4; one major sequence at a time |
| P2 | Confirmed progression | Rebirth without stage increase, Factory Stage change, upgrade purchase | Queue at most one compatible follow-up or coalesce by feature |
| P3 | Confirmed routine feedback | Press reward, Energy change | Aggregate or replace; never form an unlimited queue |
| P4 | Local contact feedback | Button compression, hover/focus response | Immediate, short, cancellable, and non-authoritative |
| P5 | Ambient presentation | Idle light, background motion, music variation | Yield to all active feedback and accessibility settings |

Failure and locked-state feedback uses the priority of the action it answers, but remains concise and does not masquerade as success. Repeated identical failures should be deduplicated within a bounded interval.

## 3. Motion Vocabulary

Motion should feel mechanical, powered, and deliberate.

| Motion | Meaning | Preferred character |
| --- | --- | --- |
| Compression | Physical contact or actuation | Fast scale-down, immediate recovery; no success claim |
| Charge | Energy gathering before a confirmed major release | Controlled ease-in; used sparingly |
| Release | Confirmed power delivery or reward | Quick expansion or upward movement with ease-out |
| Lock | Unavailable or rejected action | Small, contained resistance; no celebratory overshoot |
| Reconcile | Persistent state becoming correct | Direct or short crossfade; correctness before flourish |
| Evolve | Confirmed technological-era advancement | Ordered reveal from stable layers toward the new layer |
| Settle | Return to stable authored state | Predictable ease-out with explicit final properties |

Rules:

- Every tween declares duration, easing style, and easing direction explicitly.
- Feature presenters own and cancel their tweens; shared routing does not animate.
- Replacement is preferred for high-frequency motion. Major sequences may use a bounded queue only when order carries meaning.
- Motion must end at authored or reconciled values, not at accumulated deltas.
- Continuous frame loops are not used for discrete presentation events.

## 4. Timing Standards

These ranges establish rhythm rather than mandate one global animation helper.

| Category | Duration | Use |
| --- | --- | --- |
| Contact | 80–120ms each direction | Button compression and restoration |
| Immediate UI response | 100–180ms | Small fade, highlight, or state transition |
| Aggregation window | 100–200ms | Rapid confirmed values; fixed and bounded |
| Routine confirmed feedback | 500–900ms | Reward popup movement and fade |
| Confirmed upgrade | 600–1,200ms | Card confirmation without blocking navigation |
| Major anticipation | 250–500ms | Confirmed Rebirth or evolution wind-up |
| Major celebration | 1,200–2,500ms | Coordinated milestone presentation |
| Notification hold | 1,500–3,000ms | Depends on text length and priority |

No transient sequence should hold gameplay input hostage. Fixed aggregation windows must not extend forever under continuous input. Cleanup deadlines include a small bounded margin and do not rely solely on tween completion signals.

## 5. Audio Standards

- Audio is client presentation triggered by authoritative events or non-authoritative contact, according to the meaning of the cue.
- Contact, routine confirmation, progression, and major celebration occupy distinct intensity tiers.
- Frequent Press sounds must be short, low-cost, and concurrency-limited; rapid input must replace, pool, or rate-limit playback.
- Upgrade and Rebirth confirmations must not play before authoritative state confirms the outcome.
- Factory evolution uses a recognizable mechanical progression motif rather than an unrelated generic reward sound.
- Music and ambient beds remain separate from one-shot feedback ownership.
- Audio assets require reviewed IDs, bounded volume, cleanup, and a mute/accessibility path.
- No gameplay result depends on audio completion or availability.

## 6. Camera Standards

- Camera presentation is client-only and never supplies gameplay authority.
- Routine Press and Energy events do not move the camera.
- Camera motion is reserved for major confirmed milestones and must be short, bounded, cancellable, and compatible with the player’s current camera mode.
- A presentation must restore only properties it owns and must not fight Roblox camera scripts.
- Reduced motion disables camera shake, displacement, and FOV pulses by default.
- Camera effects must not obstruct controls, induce repeated high-frequency motion, or prevent the player from orienting immediately after the sequence.
- No presenter uses a polling or per-frame loop unless a future reviewed camera feature proves it necessary and owns deterministic teardown.

## 7. Popup Standards

- Reward popups display only authoritative values. They never derive or default a reward.
- The first confirmed value appears promptly; rapid related values aggregate within a fixed bounded window.
- A high-frequency feature owns at most one active popup unless a reviewed design explicitly permits more.
- Popup totals equal the sum of accepted authoritative events in that aggregation sequence.
- Text remains inside its background or safe visual area with adequate padding and contrast.
- Movement is short, directional, and paired with a clean fade. Replacement cancels owned tweens and destroys the previous temporary instance.
- Malformed payloads create nothing and do not alter an active total.
- Popups do not become notifications merely because their value is large; escalation follows an explicit event classification.

The current Press standard is the WP13-B contract: a fixed 150ms aggregation window, immediate first display, one active popup, and deterministic cleanup.

## 8. Factory Presentation Standards

- `DataSync.FactoryStage` is the sole authoritative source for rendered Factory Stage.
- Persistent visual reconciliation happens whenever the authoritative stage changes and is independent from celebration.
- Factory layers are cumulative: the current stage and all earlier stages are visible.
- `FactoryVisualController` owns only `Workspace.FactoryEvolution` and never modifies `Workspace.GameMap`, `Workspace.Interactive`, or `Workspace.SpawnLocation`.
- Stage discovery uses authored `Stage%d+` folders. Feature code does not hardcode descendant object names.
- Stable reconciliation may update the approved BasePart and enabled-effect properties only.
- Evolution celebration is eligible only when both Rebirths and FactoryStage increased between consecutive authoritative DataSync snapshots.
- Initial sync, late join, reconnect, or corrective reconciliation does not imply celebration.
- Failure to render must not advance remembered presentation state; the next authoritative DataSync can retry.
- Visual layers never grant progression and never write player data.

## 9. Notification Standards

- Notifications communicate discrete outcomes that cannot be read clearly from the persistent UI alone.
- Success is shown only after authoritative confirmation. Client-side validation may explain why a request was not sent, but cannot claim server success.
- Notifications have explicit priority, bounded lifetime, and deterministic cleanup.
- Duplicate messages are coalesced or suppressed within a bounded interval.
- Major progression notifications may replace routine notifications; routine feedback must not cover critical progression text.
- Copy is brief, specific, and action-oriented. It states what happened or what is required.
- Color reinforces meaning but is never the only distinction.
- Reward popups, persistent HUD changes, and notifications are separate channels; do not repeat the same fact across all three without a milestone reason.

## 10. Reduced-Motion Policy

Reduced motion preserves information while minimizing spatial movement.

- Persistent state reconciliation always runs.
- Button contact may use a subtle color or stroke response instead of scale compression.
- Reward values may appear and fade in place without upward travel.
- Camera motion, shake, FOV pulses, rapid flashes, repeated oscillation, and nonessential particle bursts are disabled.
- Major progression retains readable text, stable factory reconciliation, and optional restrained audio.
- Durations may be shortened, but content must remain readable.
- Presenters receive a shared preference in the future; they do not independently infer platform or accessibility needs.
- The preference must be changeable without requiring rejoin and must not affect authoritative state.

## 11. Mobile Presentation Policy

- Design and validation begin with touch targets, safe areas, and narrow viewports rather than treating mobile as a scaled desktop layout.
- Primary controls remain unobstructed during transient presentation.
- Text containers accommodate the longest supported copy with padding, wrapping, or bounded truncation where appropriate.
- Effects avoid large transparent overdraw, dense particles, excessive simultaneous tweens, and repeated temporary-instance allocation.
- High-frequency presentation is aggregated, pooled, or replaced.
- Camera and vibration-like motion are conservative on touch devices.
- UI remains legible with Roblox inset behavior and common aspect ratios.
- Mobile performance degradation must reduce decorative density before removing authoritative feedback.

## 12. Future Presenter Ownership

Presentation remains split by feature ownership. A central coordinator routes authoritative changes but does not render them.

| Component | Owns | Must not own |
| --- | --- | --- |
| `PresentationCoordinator` | Comparing authoritative DataSync snapshots; emitting typed presentation events; subscription lifecycle | UI, tweens, audio, camera, Workspace, notifications, gameplay |
| `PressPresenter` | Press contact motion; authoritative confirmed Press reward popup; bounded aggregation and cleanup | FireServer, reward calculation, generic animation, notifications, Workspace |
| `FactoryVisualController` | Stable cumulative Factory layer reconciliation from DataSync | Gameplay progression, celebration authority, unrelated Workspace roots |
| Future `UpgradePresenter` | Upgrade-card confirmation derived from authoritative UpgradeLevels changes | Cost authority, purchase requests, session mutation |
| Future `RebirthPresenter` | Confirmed Rebirth presentation and coordination of eligible major celebration | Rebirth eligibility, reset rules, direct session access |
| Future `NotificationPresenter` | Priority, deduplication, layout, lifetime, and cleanup of notification messages | Inventing outcomes, gameplay validation, reward calculation |
| Future `AudioPresenter` | Bounded client audio playback by approved presentation event | Gameplay timing, authoritative state, music ownership unless explicitly expanded |
| Future `CameraPresenter` | Bounded major-event camera effects and restoration | Routine feedback, camera authority outside active effects, gameplay state |

MainGuiClient remains the composition and UI integration boundary until a reviewed migration assigns narrower ownership. Server systems remain authoritative for rewards, currencies, upgrades, Rebirth, Factory Stage, and all persisted state. No presenter discovers or creates gameplay remotes, polls authoritative state, or modifies server-owned data.

## 13. Emotion Curve

The LCA Universe experience follows a repeating emotional arc: the player acts, the machine answers, confirmed value arrives, the factory grows, and familiar interaction transforms into mastery. Each presentation layer supports that arc without inventing progress or obscuring the underlying game state.

### Input

The player initiates power through a deliberate action. Presentation acknowledges physical contact immediately with concise, non-authoritative feedback such as button compression. This makes the machine feel responsive without claiming that the server accepted or rewarded the action.

### Response

The system answers the action clearly. Contact motion restores promptly, the interface remains available, and authoritative feedback appears as soon as confirmation arrives. Response should feel mechanical and direct: an action enters the machine and produces a readable reaction.

### Reward

Confirmed Energy and other rewards become visible through authoritative values, persistent HUD reconciliation, and bounded transient feedback. Presentation emphasizes the amount actually granted, never a client estimate. Frequent rewards remain compact and aggregate cleanly so repetition strengthens the power fantasy instead of creating noise.

### Growth

Upgrades, rising production, and changing Factory Stage communicate that repeated actions have lasting consequences. Presentation connects increased output to the systems that caused it through clear card states, value changes, and stable world reconciliation. Growth should be legible before it becomes celebratory.

### Transformation

Rebirth and Factory evolution turn accumulated growth into a visible technological shift. Persistent factory layers reconcile first so the world is correct; eligible celebration then frames the change as a new era. Transformation is rarer and more coordinated than routine rewards, giving it emotional weight without moving authority to the client.

### Anticipation

The player learns to recognize approaching thresholds, affordable upgrades, and the next Factory era. UI hierarchy and restrained presentation make goals understandable without falsely predicting success. Any wind-up begins only when it cannot misrepresent an unconfirmed gameplay outcome, and it remains cancellable.

### Mastery

As the player understands the machine, presentation becomes a fluent language rather than an interruption. Consistent motion, color, sound, and priority let experienced players read outcomes quickly. High-frequency feedback stays bounded, major milestones remain distinctive, and accessibility options preserve information so mastery depends on decisions rather than tolerance for visual intensity.

The curve repeats at increasing scale. A mastered Press cycle feeds upgrade growth; mastered upgrades feed Rebirth; Rebirth enables transformation; each transformation creates new anticipation. Presentation should make those relationships feel continuous rather than like disconnected reward screens.

## 14. Never Fight Gameplay

Presentation follows gameplay; it never holds gameplay hostage. The player must be able to continue acting while the presentation layer reconciles, replaces, shortens, or skips transient effects.

- **Input always wins.** An active tween, popup, notification, sound, or celebration must not consume, defer, or block otherwise valid gameplay input. A new feature-owned interaction may cancel or retarget its previous presentation immediately.
- **Gameplay is authoritative.** Server-owned state determines rewards, currencies, upgrades, Rebirths, and Factory progression. Presentation observes confirmed outcomes and never changes eligibility, timing, values, or persisted data.
- **Presentation catches up.** If several authoritative updates arrive quickly, persistent UI and world state reconcile to the newest valid snapshot. Transient effects may aggregate, replace, or be omitted; they must never force gameplay to wait for every intermediate flourish.
- **Celebration does not prevent interaction.** Major Rebirth or Factory evolution presentation may receive visual priority, but controls remain usable unless gameplay itself imposes a reviewed restriction. Celebration layers must avoid intercepting input unintentionally.
- **Temporary effects never lock controls.** Popups, overlays, camera effects, audio, and VFX own no gameplay lock. Their creation, animation, failure, cancellation, or destruction cannot determine whether the player may Press, purchase, navigate, or request another action.
- **Delayed cleanup never delays gameplay.** Cleanup timers exist only to remove presentation-owned resources. Gameplay continues independently, and replacement presentation explicitly cancels or destroys stale resources without waiting for a delay or `Tween.Completed`.
- **Failure degrades visually, not functionally.** Missing assets, cancelled tweens, reduced-motion settings, or presenter errors may reduce spectacle, but authoritative state reconciliation and gameplay input remain available.
- **Presentation order cannot become gameplay order.** A popup finishing, a sound ending, or a camera returning must never be a prerequisite for the next server request or state mutation.

When performance or overlap forces a choice, preserve input, authoritative state, and readability first. Shorten or remove decoration before delaying gameplay.

## References

- `tests/manual/WP-12_FactoryPresentation.md` — current Factory reconciliation contract and handoff notes.
- `tests/manual/WP-13B_PressPresenter.md` — current Press contact, popup aggregation, validation, and cleanup contract.
- `src/client/PresentationCoordinator.lua` — authoritative DataSync comparison and presentation-event routing boundary.
- `src/client/FactoryVisualController.lua` — stable Factory layer reconciliation boundary.
- `src/client/PressPresenter.lua` — feature-owned Press presentation boundary.
