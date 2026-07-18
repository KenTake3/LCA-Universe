# WP-13H — CameraPresenter

## Objective

Own short, bounded FOV pulses for confirmed major presentation without changing CameraType, CFrame, gameplay input, or default Roblox camera ownership.

## Authority Source

RebirthPresenter invokes `RebirthConfirmed` or `FactoryEra` only after a `PresentationCoordinator.RebirthCompleted` event. Routine Press, Energy, and upgrade events have no CameraPresenter path.

## Ownership Boundary

CameraPresenter owns only the active camera's captured FieldOfView, one replaceable tween sequence, restoration, and reduced-motion cancellation. It does not own CameraType, CFrame, shake, Lighting, gameplay, or event classification.

## Files Changed

- `src/client/CameraPresenter.lua`
- `src/client/PresentationPreferences.lua`
- `src/client/RebirthPresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-13H_CameraPresenter.md`
- `CHANGELOG.md`

## Cancellation and Cleanup

At most one effect exists. A new cue first cancels the active tween and restores the captured FOV. Generation tokens invalidate delayed callbacks. The pulse uses explicit Quad/Out tweens: 0.12 seconds outward and 0.28 seconds back. Final restoration uses a bounded delay, not Tween.Completed. `destroy()` disconnects preference observation and restores FOV.

If `CurrentCamera` is missing, the cue no-ops. If it changes during the effect, the old owned camera property is restored and the sequence stops safely.

## Overlap and Priority

`FactoryEra` uses a small +5-degree pulse; `RebirthConfirmed` uses +3 degrees. FOV is capped at 100. New major cues replace old cues. There is no queue and no per-frame loop.

## Reduced Motion

PresentationPreferences stores one in-memory boolean. When reduced motion is enabled, new camera cues no-op and an active pulse is cancelled/restored immediately. No settings UI, persistence, RemoteEvent, or platform inference is included.

## Static Validation

- [x] Uses `--!strict` and accepts only two major semantic cues.
- [x] Routine Press, Energy, and upgrades cannot invoke CameraPresenter.
- [x] Uses TweenService and no Heartbeat, RenderStepped, or polling loop.
- [x] Does not write CameraType or CFrame.
- [x] Does not create shake or Lighting effects.
- [x] At most one effect is active.
- [x] Captured FOV is restored on replacement, completion, camera change, reduced motion, and teardown.
- [x] Creates no UI overlay and blocks no input.

## Studio Validation Checklist

- [ ] Press and purchase upgrades; confirm FOV does not move.
- [x] Complete ordinary Rebirth and confirm one restrained FOV pulse after authoritative DataSync.
- [x] Complete Rebirth with Factory Stage increase and confirm one FactoryEra pulse with final FOV restoration.
- [ ] Trigger overlapping major cues in an isolated harness and confirm replacement/restoration.
- [ ] Replace CurrentCamera during a pulse and confirm safe restoration with no runtime error.
- [ ] Enable reduced motion before a cue and confirm no FOV change.
- [ ] Enable reduced motion during a cue and confirm immediate restoration.
- [ ] Confirm CameraType and CFrame remain default-script-owned.
- [x] Respawn and confirm no duplicate effect owner or camera behavior.
- [x] Confirm Output has no new relevant Script Analysis or runtime errors.

Architect-reported Studio validation confirmed major-event FOV behavior, deterministic restoration, clean respawn lifecycle behavior, and no new relevant Output errors. Overlap, camera-replacement, and reduced-motion harness cases remain unchecked.

## Known Limitations

- PresentationPreferences is in-memory only and defaults reduced motion to false.
- No settings UI exposes reduced motion yet.
- No shake, blur, bloom, depth of field, camera CFrame movement, or device-specific tuning exists.

## Handoff Notes

Keep camera use major-event-only. Future camera work must preserve exact property ownership, immediate reduced-motion cancellation, and deterministic restoration.
