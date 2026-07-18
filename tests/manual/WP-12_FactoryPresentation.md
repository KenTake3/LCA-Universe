# WP-12 — Factory Presentation

## Objective

Render each player's authoritative FactoryStage as a cumulative local factory model without adding gameplay authority, server Workspace mutation, polling, or another synchronization RemoteEvent.

WP-12 uses the existing DataSync packet as the only factory-presentation source. The client never calculates eligibility or sends a visual stage to the server.

## Implementation summary

- Added the strict `FactoryVisualController` client module under the Rojo-managed `StarterGui/MainGui` hierarchy.
- MainGuiClient forwards authoritative `DataSync.FactoryStage` and `DataSync.Rebirths` to the controller.
- Removed MainGuiClient's obsolete `FactoryEvolutionSync` lookup and listener. WP-12 adds no RemoteEvent.
- The controller discovers direct Folder children of `Workspace.FactoryEvolution` whose names match `Stage%d+`, sorts them numerically, and caches their supported descendants once.
- Stage layers are cumulative: a rendered Stage 4 shows Stage1 through Stage4 and hides later discovered layers.
- Visible BaseParts restore their authored `Transparency`, `CanCollide`, `CanTouch`, and `CanQuery` values. Hidden BaseParts use Transparency 1 and disable those three physical/query properties.
- Existing Lights, ParticleEmitters, Trails, and Beams restore their authored Enabled value while visible and are disabled while hidden.
- The controller never modifies `Workspace.GameMap`, `Workspace.Interactive`, or `Workspace.SpawnLocation`.
- The first valid DataSync establishes the presentation baseline and renders without celebration.
- Model reconciliation occurs whenever the authoritative FactoryStage changes.
- The existing-style factory-upgrade notification appears only when both Rebirths and FactoryStage increase between consecutive authoritative DataSync packets.
- Rendering is protected with `pcall`. A raised render failure does not advance the controller's previous-stage/Rebirth comparison and a later DataSync can retry.
- Widened the centered factory-stage status background to keep the current progress text readable.
- Corrected the Rebirth title bounds and added local insufficient-Energy feedback without weakening the authoritative server Rebirth validation.

## WP-12 files

- `src/client/FactoryVisualController.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-12_FactoryPresentation.md`
- `CHANGELOG.md`

No GameplayService, SessionRepository, ServerDataService, scheduler, persistence, or other server behavior is part of WP-12.

## Static and build validation results

- [x] `git diff --check` passed after the final defensive and UI fixes.
- [x] `rojo build default.project.json --output /tmp/LCA-WP12-final-review.rbxlx` passed.
- [x] `rojo build default.project.json --output /tmp/LCA-WP12-ui-review.rbxlx` passed.
- [x] `rojo build default.project.json --output /tmp/LCA-WP12-rebirth-dialog-review.rbxlx` passed.
- [x] FactoryVisualController contains no RemoteEvent, polling loop, Heartbeat, RenderStepped, gameplay mutation, or server dependency.
- [x] MainGuiClient no longer references `FactoryEvolutionSync`.
- [x] Rojo maps exactly one FactoryVisualController beside MainGuiClient under MainGui.

## Studio validation checklist

### Hierarchy and ownership

- [ ] Sync the current Rojo project into the test place.
- [ ] Confirm `StarterGui.MainGui` contains one MainGuiClient and one FactoryVisualController.
- [ ] Confirm legacy FactoryEvolution remains disabled.
- [ ] Confirm no FactoryEvolutionSync client listener is active.
- [ ] Confirm Output contains no runtime or Script Analysis errors introduced by WP-12.

### Initial DataSync and cumulative layers

- [ ] Join with FactoryStage 1 and confirm Stage1 is visible while later discovered Stage folders are hidden.
- [ ] Confirm the initial snapshot produces no upgrade notification or celebration.
- [ ] For stages 2 through 6, confirm every layer at or below the stage is visible and every higher layer is hidden.
- [ ] Confirm visible parts restore their authored transparency and collision/touch/query values rather than receiving generic defaults.
- [ ] Confirm hidden parts are transparent and have CanCollide, CanTouch, and CanQuery disabled.
- [ ] Confirm supported lights and effects restore authored Enabled values only in visible layers.

### Authoritative reconciliation

- [ ] Advance FactoryStage through authoritative Press or Auto Power progression and confirm the model reconciles without a Rebirth celebration.
- [ ] Complete a Rebirth that does not advance FactoryStage and confirm there is no factory-upgrade notification.
- [ ] Complete a Rebirth where both Rebirths and FactoryStage increase and confirm exactly one factory-upgrade notification appears.
- [ ] Confirm a repeated DataSync with the same stage does not reapply or celebrate the stage.
- [ ] Confirm a later valid DataSync can retry after an injected render exception without a gameplay mutation or additional remote.

### Workspace isolation

- [ ] Snapshot properties under `Workspace.GameMap`, `Workspace.Interactive`, and `Workspace.SpawnLocation` before validation.
- [ ] Exercise all six stage reconciliations.
- [ ] Confirm no property under those three excluded roots changed due to FactoryVisualController.
- [ ] Confirm the controller does not create or delete FactoryEvolution descendants.

### UI regression

- [ ] Confirm the `LUCKY CORE FACTORY` title remains centered and unchanged.
- [ ] Confirm the widened factory status text remains inside its gray background for every stage/progress string.
- [ ] Confirm the purple Rebirth title stays at the top of its dialog and does not overlap the multiplier or confirm button.
- [ ] With insufficient Energy, confirm the Rebirth button shows one `Not enough Energy to Rebirth` notification and sends no request.
- [ ] With sufficient Energy, confirm the button sends one RequestRebirth request and the existing authoritative WP-11 flow still succeeds.

### Lifecycle

- [ ] Reconnect with a persisted later FactoryStage and confirm the initial DataSync renders it without historical celebration.
- [ ] Respawn and confirm MainGui/FactoryVisualController are not duplicated.
- [ ] Confirm Press, upgrades, Auto Power, Rebirth, DataSync UI, and server rate limits remain unchanged.

## Studio validation recorded during development

- [x] The Rojo-managed MainGuiClient continued to start and display its UI during WP-12 investigation.
- [x] The sidebar REB control opened the Rebirth dialog.
- [x] The Rebirth request path was verified unchanged from the approved WP-11 implementation.
- [x] The empty/silent insufficient-Energy case and Rebirth-title overlap were diagnosed in source and repaired.
- [ ] A complete six-stage visual pass after the final defensive and dialog fixes has not yet been recorded in this document.

## Known limitations

- Stage folders and descendants are cached only once. Descendants added later are intentionally not discovered.
- If `Workspace.FactoryEvolution` is absent during first cache construction, the current empty cache does not itself raise an error. Streaming/readiness behavior requires explicit Studio validation and may need a separately reviewed bounded readiness contract.
- WP-12 does not create stage models, lights, particles, trails, beams, sounds, animation, or camera effects; it only reconciles authored objects already present.
- Decals and Textures are not modified because they are outside the approved Workspace property contract.
- DataSync does not currently contain a monotonic packet sequence. WP-12 relies on the existing single server DataSync producer and Roblox event ordering.
- The controller's comparison state is client-local and resets on reconnect, so the first snapshot never celebrates historical progression.
- Press and Auto Power can advance the authoritative FactoryStage. Those changes reconcile the model but do not produce the Rebirth-plus-stage celebration.
- The existing factory celebration is a notification only; coordinated motion, audio, VFX, and presentation priority remain WP13 work.

## WP13 handoff

- Treat DataSync as state, not as a visual command.
- PresentationCoordinator should own comparisons and event routing; FactoryVisualController should continue to own only stable FactoryEvolution model reconciliation.
- Do not reintroduce FactoryEvolutionSync or another visual-only gameplay remote.
- Keep Rebirth-plus-stage celebration conditioned on both authoritative values increasing in the same snapshot comparison.
- Add no transient effect that permanently overwrites FactoryVisualController's cached BasePart or effect baselines.
- Address bounded asset readiness, stale DataSync sequencing, notification priority, reduced motion, and transient-instance cleanup as separate reviewed presentation contracts.
- Preserve Workspace isolation: GameMap, Interactive, and SpawnLocation remain outside FactoryVisualController ownership.
