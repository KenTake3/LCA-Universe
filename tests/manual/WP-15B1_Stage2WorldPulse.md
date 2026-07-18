# WP15-B1 — Stage2 World Pulse Manual Tests

Status: Static implementation complete; Studio validation pending

## Scope and Static Contract

WP15-B1 extends only a positive authoritative transition whose final `FactoryStage` is 2. Its exact route is `CoreInner → Connector0 → Connector1 → Connector2 → Connector3`; Connector3 is the final response target.

- [x] Composition resolves only the four named direct children of `Workspace.FactoryEvolution.Stage2`.
- [x] FactoryEvolution and Stage2 must be Folder or Model; all four Connectors must be BaseParts.
- [x] A partial or malformed route is rejected as a whole with no search or warning spam.
- [x] The semantic `FactoryStageChanged` event and authoritative DataSync comparison remain unchanged.
- [x] Stage3–Stage6 have no Connector route, alternative search, or BaseRing fallback.
- [x] FactoryVisualController, server/shared code, gameplay, persistence, remotes, and progression contracts are unchanged.
- [x] There is no polling, Heartbeat, RenderStepped, particle, or instance-per-event allocation.

## Setup and Authored Baseline

1. Open the authoritative test Place with Explorer, Properties, Output, and Developer Console visible.
2. Confirm `Workspace.Interactive.EnergyCore.CoreInner` is a BasePart.
3. Confirm `Workspace.FactoryEvolution.Stage2` is a Folder or Model.
4. Confirm Connector0, Connector1, Connector2, and Connector3 are direct BasePart children of Stage2.
5. Record each Connector's Transparency, Color, Material, Size, CFrame, CanCollide, CanTouch, CanQuery, CastShadow, and authored children/properties.
6. Test with one local player on desktop and a narrow mobile viewport.

## Trigger and Route Order

- [ ] Initial join at Stage1 or Stage2 produces no World Pulse route or historical celebration.
- [ ] Stage1 accepted PRESS retains only the WP15-A Core-to-BaseRing response.
- [ ] A positive authoritative Stage1-to-Stage2 transition travels CoreInner → Connector0 → Connector1 → Connector2 → Connector3 in that order.
- [ ] Connector pulses are sequential rather than four simultaneous flashes.
- [ ] Connector0 responds at approximately 0.28s, Connector1 at 0.48s, Connector2 at 0.68s, and Connector3 at 0.88s.
- [ ] Connector3 receives the strongest response from approximately 0.88–1.30s.
- [ ] All WP15-B route effects are neutral by 2.10s and no later than 2.30s.
- [ ] The route reads as world energy transfer rather than a weapon or sustained laser.

## Existing World Awakening Coordination

- [ ] Existing Core gather begins at 0.00s and release/audio request remains at 0.25s.
- [ ] Existing camera request remains at approximately 0.90s.
- [ ] Existing WORLD AWAKENED notification remains at approximately 0.95s with exact approved text.
- [ ] Stable Stage2 visibility is already reconciled correctly before and throughout the optional route.
- [ ] PRESS remains much smaller than the Stage2 World Awakening presentation.

## Negative and Unverified Triggers

- [ ] Local PRESS and valid PressFeedback never start the Connector route.
- [ ] Auto Power, upgrade purchase, and ordinary Rebirth without a stage increase never start the route.
- [ ] Initial sync, repeated Stage2 sync, and stage decrease never start the route.
- [ ] Stage3, Stage4, Stage5, and Stage6 transitions retain Core, camera, and notification presentation but show no Connector or BaseRing route.
- [ ] No alternative target is searched or selected for any unverified stage.

## Priority, Replacement, and Lifecycle

- [ ] An active WP15-A manual Beam/BaseRing response neutralizes before Stage2 World Pulse begins.
- [ ] Rapid positive stage snapshots cancel stale delayed callbacks; only the latest authoritative stage remains eligible.
- [ ] A skipped transition whose latest final stage is 3–6 cancels any Stage2 route and plays no replacement world route.
- [ ] A stage decrease cancels the active route and returns owned Beam/light properties to neutral.
- [ ] Respawn during each route segment and Connector3 response destroys owned instances and leaves no delayed presentation.
- [ ] No lingering enabled Beam or nonzero WP15 route light remains after cancellation, replacement, or teardown.

## Reduced Motion and Missing Route

- [ ] Reduced motion shows no traveling Beam and no intermediate Connector response.
- [ ] Reduced motion may briefly pulse Connector3 with a low-brightness owned light, then settles within approximately 0.45s.
- [ ] Existing reduced-motion camera suppression and readable notification remain unchanged.
- [ ] In an isolated copy, remove or change the class of any one Connector before initialization; Stage2 falls back silently to Core/camera/notification only.
- [ ] Remove or reparent a Connector during a route; the route cancels, cleans up, and is not rediscovered.

## Ownership, Budgets, and Property Integrity

- [ ] Exactly four WP15-B Connector Attachments and one WP15-B route PointLight are created once.
- [ ] The existing WP15 Beam is reused; no Beam or light is created per World Awakening.
- [ ] At most one Beam and one route/destination PointLight are active for WP15-B.
- [ ] At most one Beam Tween and one world-light Tween are active in addition to the existing Core Tween.
- [ ] Particles remain zero and there are no per-frame presentation updates.
- [ ] Compare all Connector snapshots before/after and confirm no authored property or authored child property changed.
- [ ] Confirm FactoryVisualController remains the sole owner of stable Stage visibility and restoration.

## Device and Output Validation

- [ ] Desktop route direction and Connector order are clear without obscuring controls or state.
- [ ] Narrow mobile route remains visible, calm, and readable without excessive overdraw.
- [ ] Test initial join, transition, rapid snapshots, reduced motion, missing Connector, cancellation, and respawn with no new relevant Output errors or warnings.
