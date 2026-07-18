# WP15-A — Core-to-World Response Manual Tests

Status: Static implementation complete; Studio validation pending

## Scope

WP15-A extends valid manual PRESS presentation from the existing Core response to the exact approved destination `Workspace.FactoryEvolution.Stage1.BaseRing`. It creates one presenter-owned Core Attachment, one BaseRing Attachment, one Beam, and one BaseRing PointLight during initialization. It does not implement Connector routing, stage-directed propagation, WP15-B, or WP14-B3 atmosphere.

## Static Contract

- [x] Exact target resolution uses only `Workspace.FactoryEvolution.Stage1.BaseRing`.
- [x] FactoryEvolution and Stage1 must be Folder or Model; BaseRing must be BasePart.
- [x] There is no alternative target search, `GetDescendants`, whole-Workspace scan, polling, Heartbeat, or RenderStepped.
- [x] Local PRESS invokes only existing button and Core contact behavior.
- [x] Beam and BaseRing response require existing valid `PressFeedback` processing.
- [x] Four WP15 instances are created once and zero instances are created per PRESS.
- [x] One Core Tween, one Beam Tween, and one BaseRing-light Tween are the maximum active presentation slots.
- [x] World Awakening cancels manual world presentation through the existing propagation cancellation boundary.
- [x] `FactoryVisualController` remains unchanged and owns BaseRing stable visibility/restoration.
- [x] `CoreHighlight` is never resolved or modified.
- [x] No server, shared, gameplay, persistence, remote, reward, Rebirth, or progression contract changed.

## Studio Setup and Baseline Capture

1. Open the authoritative test Place with Explorer, Properties, Output, and Developer Console visible.
2. Confirm `Workspace.Interactive.EnergyCore.CoreInner` is a BasePart.
3. Confirm `Workspace.FactoryEvolution.Stage1.BaseRing` is a BasePart.
4. Record BaseRing Transparency, Color, Material, Size, CFrame, CanCollide, CanTouch, CanQuery, CastShadow, and all existing children.
5. Record CoreHighlight Enabled, DepthMode, FillColor, FillTransparency, OutlineColor, and OutlineTransparency.
6. Start a local server with one player and test desktop and a narrow mobile viewport.

## Initial and Local Contact

- [ ] Initial join creates the four WP15-owned instances once but the Beam is disabled, fully neutral, and invisible.
- [ ] Initial BaseRing response-light Brightness is zero.
- [ ] Local PRESS before authoritative feedback produces button/Core contact only.
- [ ] Local contact does not enable the Beam or raise BaseRing response-light Brightness.

## Valid and Invalid Feedback

- [ ] One accepted PRESS produces existing Core confirmation, then one visible CoreInner-to-BaseRing Beam and BaseRing light response.
- [ ] Beam reveal begins approximately 0.06 seconds after valid feedback.
- [ ] BaseRing light peaks approximately 0.18 seconds after valid feedback.
- [ ] Beam begins fading approximately 0.30 seconds after valid feedback.
- [ ] By approximately 0.70 seconds, Beam is disabled with zero width and target Brightness is zero.
- [ ] Existing exact reward popup content, aggregation, color, and cleanup remain unchanged.
- [ ] Malformed or rejected feedback creates no confirmed Core, Beam, or BaseRing response.
- [ ] Beam is narrow, soft, brief, and reads as energy transfer rather than a weapon or sustained laser.
- [ ] Reward magnitude does not change Beam width, target count, or instance count.

## Rapid PRESS and Priority

- [ ] PRESS at the maximum accepted rate and confirm one pooled Beam/light response is retargeted rather than queued.
- [ ] Confirm exactly one `WP15CoreTransferAttachment`, `WP15BaseRingResponseAttachment`, `WP15CoreToBaseRingBeam`, and `WP15BaseRingResponseLight` exists.
- [ ] Confirm stale delayed callbacks never disable a newer response early.
- [ ] Confirm at most one Core Tween, one Beam Tween, and one BaseRing-light Tween are active.
- [ ] Trigger an existing World Awakening during manual response and confirm Beam/BaseRing presentation immediately neutralizes.
- [ ] Confirm existing World Awakening Core, camera, notification, timing, and stable world layers remain unchanged.
- [ ] Confirm PRESS remains materially smaller and shorter than World Awakening.

## Non-PRESS Regression

- [ ] Auto Power Energy changes produce no Beam or BaseRing response.
- [ ] Upgrade purchase produces no Beam or BaseRing response.
- [ ] Ordinary Rebirth without stage increase produces no WP15-A response.
- [ ] Initial DataSync, repeated same-stage DataSync, and rejoin produce no WP15-A response.

## Reduced Motion

- [ ] With reduced motion enabled, Beam remains disabled and no traveling/reveal animation occurs.
- [ ] Confirm the optional BaseRing response is brief, low brightness, and settles within approximately 0.20 seconds.
- [ ] Enable reduced motion during an active response and confirm Beam disables and target Brightness returns to zero immediately.
- [ ] Exact reward popup and existing reduced-motion Core response remain readable and correct.

## Missing Target and Lifecycle

- [ ] In an isolated copy, remove or change the class of BaseRing before initialization and confirm silent Core-only fallback with no warning spam.
- [ ] Remove or reparent BaseRing after initialization and confirm active world response cancels, surviving owned instances clean up, and that presenter instance permanently remains Core-only.
- [ ] Confirm no alternative target is discovered.
- [ ] Respawn during Beam reveal, target peak, and fade; confirm neutral restoration and no duplicate instances or behavior.
- [ ] On teardown, confirm Beam is disabled/neutral, target Brightness is zero, all four WP15-owned instances are destroyed, and authored instances remain.
- [ ] Confirm no lingering Beam, PointLight, Attachment, Tween, or delayed presentation remains.

## Authored-Property Integrity

- [ ] Compare BaseRing before/after snapshots and confirm Transparency, Color, Material, Size, CFrame, CanCollide, CanTouch, CanQuery, and CastShadow are identical.
- [ ] Confirm all pre-existing BaseRing children and their properties are identical.
- [ ] Compare CoreHighlight before/after and confirm Enabled=true, DepthMode=AlwaysOnTop, FillColor=[0,170,255], FillTransparency=0.8, OutlineColor=[100,220,255], and OutlineTransparency=0.
- [ ] Confirm authored CoreParticles and CoreClickDetector remain unchanged.
- [ ] Confirm FactoryVisualController still controls BaseRing stable visibility and collision restoration exclusively.

## Mobile, Readability, and Output

- [ ] On desktop, confirm Core-to-BaseRing direction is legible without obscuring the world or UI.
- [ ] On a narrow mobile viewport, confirm the Beam/target response remains visible but restrained.
- [ ] Confirm no large flash, particle burst, impact effect, or weapon-like presentation appears.
- [ ] Confirm Output contains no new relevant warnings or errors during initial join, rapid PRESS, reduced motion, missing target, World Awakening overlap, and respawn.
