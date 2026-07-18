# WP14-B1/B2 — World Awakening Presentation Manual Tests

Status: Static implementation complete; Studio validation pending

## Scope

This combined batch adds a bounded Core response for local and confirmed PRESS presentation and moves positive authoritative `FactoryStageChanged` presentation into `WorldAwakeningPresenter`. It does not implement WP14-B3 progress atmosphere, ambient audio, energy-path assets, particles, or UI progress polish.

## Static Contract

- [x] `EnergyPropagationPresenter` owns at most one reusable PointLight and one active tween.
- [x] No PointLight or other effect instance is created per PRESS.
- [x] Local PRESS produces only a neutral contact response before server confirmation.
- [x] Confirmed rarity color and stronger Core response require valid `PressFeedback`.
- [x] Missing `Workspace.Interactive.EnergyCore.CoreInner/CoreOuter` safely produces no Core effect.
- [x] No polling, Heartbeat, RenderStepped, or repeated descendant scan was added.
- [x] `FactoryVisualController.reconcile()` still runs before presentation event processing.
- [x] `WorldAwakeningPresenter` subscribes only to existing `FactoryStageChanged` events.
- [x] Initial DataSync and stage decreases produce no World Awakening celebration.
- [x] `RebirthPresenter` no longer duplicates stage-advance notification, audio, or camera presentation.
- [x] Ordinary Rebirth presentation remains owned by `RebirthPresenter`.
- [x] Existing internal Factory names, DataSync fields, remotes, persistence, server services, thresholds, rewards, and Rebirth rules remain unchanged.
- [x] B3 atmosphere and polish are absent.

## Studio Setup

1. Build or sync the project into the recovery test place.
2. Confirm whether `Workspace.Interactive.EnergyCore.CoreInner` or `CoreOuter` exists as a BasePart.
3. Start a local server with one player and keep Output and Developer Console visible.
4. Test desktop, a narrow mobile viewport, and reduced motion through an isolated preference harness.

## PRESS Chain

- [ ] Press once and confirm the button and optional Core respond immediately without showing reward value or rarity before `PressFeedback`.
- [ ] Confirm accepted PRESS shows the exact existing reward popup and a stronger Core pulse using authoritative rarity color.
- [ ] Confirm rejected or malformed feedback produces no confirmed Core pulse.
- [ ] Press at the allowed maximum rate and confirm only one `WorldAwakeningPresentationLight` exists and Core brightness settles to zero.
- [ ] Confirm the lifted rarity color remains recognizable while providing visible contrast against the Core and surrounding world.
- [ ] Confirm the wider light range and increased brightness improve visibility without washing out nearby UI/world details.
- [ ] Confirm rapid input does not accumulate tweens, instances, sounds, camera effects, or delayed stale restoration.
- [ ] Confirm rare notifications and existing reward aggregation remain unchanged.
- [ ] Remove or rename the optional Core part in an isolated copy and confirm PRESS/UI/gameplay continue without relevant errors or Core effects.

## Auto Power and Non-PRESS Energy

- [ ] Let Auto Power increase Energy and confirm it does not create manual contact, rarity-colored Core pulse, or reward popup.
- [ ] Purchase an upgrade and complete Rebirth; confirm Energy changes do not independently create manual PRESS presentation.
- [ ] Confirm no WP14-B3 ambient or progress-band effect is present.

## World Awakening

- [ ] Initial join at Stage 1 applies correct stable layers without celebration.
- [ ] Rejoin at a higher persisted stage applies correct stable layers without historical celebration.
- [ ] Increase `FactoryStage` without Rebirth and confirm exactly one World Awakening sequence and approved major notification.
- [ ] Complete a Rebirth that also increases `FactoryStage` and confirm exactly one World Awakening notification, one major audio request, and one major camera request.
- [ ] Confirm no ordinary Rebirth notification is duplicated during the stage-advance case.
- [ ] Complete an ordinary Rebirth without stage increase and confirm the existing routine cycle notification, emphasis, audio request, and camera request remain once.
- [ ] Confirm `FactoryVisualController` has already reconciled the new cumulative layer even if Core presentation is unavailable or interrupted.
- [ ] Confirm stage correction/decrease cancels Core presentation and creates no success notification.

## Interruption and Lifecycle

- [ ] Send rapid consecutive positive stage snapshots in an isolated harness and confirm the latest stage replaces the earlier timeline without queued historical notifications.
- [ ] Send repeated same-stage DataSync and confirm no presentation restart.
- [ ] Respawn during Core contact, confirmed pulse, major gather, release, and notification delay; confirm no duplicate subscriptions or lights.
- [ ] Rejoin during/after an interrupted sequence and confirm stable world state is correct.
- [ ] Remove the Core part during a sequence and confirm degradation is visual only with no gameplay failure.
- [ ] Inject a presenter-listener failure and confirm stable reconciliation and other coordinator listeners continue.

## Reduced Motion and Mobile

- [ ] Enable reduced motion before PRESS and confirm the Core pulse is shorter and restrained.
- [ ] Enable reduced motion during an active pulse and confirm immediate cancellation and Brightness restoration to zero.
- [ ] Trigger World Awakening with reduced motion and confirm no CameraPresenter FOV pulse, while stable layers and major notification remain.
- [ ] Confirm no overlays intercept touch input and all existing mobile controls remain usable.
- [ ] Profile rapid PRESS and World Awakening on a low-end mobile target; confirm one new light, one new tween maximum, and no sustained frame degradation.

## Regression and Output

- [ ] Confirm PRESS requests, rewards, rate limits, upgrades, Auto Power, Rebirth, DataSync, persistence, and world-layer visibility remain behaviorally unchanged.
- [ ] Confirm authored BasePart Transparency, Color, Material, collision, touch, and query properties are unchanged by the new presenters.
- [ ] Confirm existing authored Light, ParticleEmitter, Trail, Beam, and stage Enabled values are unchanged.
- [ ] Confirm CameraType and Camera CFrame remain untouched and FOV restores after the existing pulse.
- [ ] Confirm Output contains no new relevant warnings, errors, or leaked-instance reports.
