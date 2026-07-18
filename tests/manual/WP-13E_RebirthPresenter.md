# WP-13E — RebirthPresenter

## Objective

Present only server-confirmed Rebirth completion, distinguish ordinary cycle progression from Rebirth-plus-Factory-era progression, and coordinate narrowly typed notification, audio, and camera requests without changing Rebirth gameplay.

## Authority Source

`PresentationCoordinator.RebirthCompleted`, emitted only when authoritative Rebirths increase between valid DataSync snapshots. Factory Stage before/after values in that same event classify major progression.

## Ownership Boundary

RebirthPresenter owns Rebirth/multiplier label emphasis, one coordinator subscription, one replaceable sequence, classification, and semantic requests. NotificationPresenter owns messages, AudioPresenter owns sound mechanics, CameraPresenter owns FOV, and FactoryVisualController remains the sole owner of stable Factory layer reconciliation.

## Files Changed

- `src/client/RebirthPresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-13E_RebirthPresenter.md`
- `CHANGELOG.md`

## Cancellation and Cleanup

At most one sequence is active. A new event cancels existing label tweens, restores captured colors, and advances a generation token before replacement. Cleanup uses bounded delays rather than Tween.Completed. `destroy()` disconnects and restores all owned properties.

## Overlap and Priority

- Rebirth without Factory Stage increase: routine confirmed-progression notification, label emphasis, `RebirthConfirmed` semantic audio/camera cue.
- Rebirth with Factory Stage increase: major progression notification using the authoritative stage's configured name/color, label emphasis, `FactoryEra` semantic cues.

No overlay is created, controls remain active, and no presentation queue exists.

## Reduced Motion

Reduced motion shortens the color emphasis. CameraPresenter independently suppresses all FOV output. Text and authoritative world reconciliation remain available.

## Static Validation

- [x] Uses `--!strict`.
- [x] Presents only `RebirthCompleted` events.
- [x] Initial/historical DataSync cannot generate celebration through the coordinator baseline contract.
- [x] Major classification requires Factory Stage increase in the same event.
- [x] Does not perform stable Factory reconciliation.
- [x] Does not calculate Rebirth cost, multiplier, eligibility, or reset state.
- [x] Creates no overlay and disables no controls.
- [x] Replaces overlap and restores owned properties deterministically.
- [x] Does not call `FireServer` or discover remotes.

## Studio Validation Checklist

- [ ] Join with existing Rebirth history and confirm no celebration on initial DataSync.
- [x] Complete Rebirth without stage increase and confirm concise cycle presentation after DataSync only.
- [x] Complete Rebirth with stage increase and confirm FactoryStage progression presentation.
- [ ] Confirm Factory layers still reconcile solely through FactoryVisualController.
- [x] Confirm Press, navigation, and upgrade controls remain usable during presentation.
- [ ] Trigger overlapping events in an isolated harness and confirm one sequence with exact color restoration.
- [ ] Enable reduced motion and confirm no camera FOV effect.
- [x] Respawn and confirm no duplicate subscription or presentation behavior.
- [x] Confirm Output has no new relevant Script Analysis or runtime errors.

Architect-reported Studio validation confirmed ordinary Rebirth presentation, FactoryStage progression presentation, usable controls, clean respawn lifecycle behavior, and no new relevant Output errors. Initial-history, overlap, and reduced-motion harness cases remain unchecked.

## Known Limitations

- Ordinary Rebirth requests a semantic camera pulse; reduced motion suppresses it.
- No full-screen overlay, particles, or Factory VFX are implemented.
- Audio cues no-op because no reviewed SoundIds exist.
- Snapshot coalescing may represent more than one Rebirth as one completion event.

## Handoff Notes

Do not move eligibility or reset logic into this presenter. Future major presentation must remain input-transparent and reconciliation-independent.
