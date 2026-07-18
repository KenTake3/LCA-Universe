# WP-13G — AudioPresenter

## Objective

Provide one typed, bounded owner for presentation one-shot audio while preserving silence when the repository has no reviewed SoundIds.

## Authority Source

Feature presenters select semantic meaning only after their approved boundaries: local Press contact, authoritative PressFeedback, positive authoritative upgrade increase, and authoritative Rebirth/Factory-era completion.

## Ownership Boundary

AudioPresenter exclusively owns creation, playback, interruption, lifetime, and destruction of presentation Sound instances. It does not own music, gameplay, event classification, UI, camera, or asset selection outside its reviewed allowlist.

## Files Changed

- `src/client/AudioPresenter.lua`
- `src/client/PressPresenter.lua`
- `src/client/UpgradePresenter.lua`
- `src/client/RebirthPresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-13G_AudioPresenter.md`
- `CHANGELOG.md`

## Cancellation and Cleanup

Routine cues share one replaceable slot; major cues share one replaceable slot and interrupt routine playback. Valid future sounds have a ten-second maximum lifetime and are explicitly stopped/destroyed on replacement or teardown. Current empty IDs create no Sound.

## Overlap and Priority

Semantic cues are `PressContact`, `PressConfirmed`, `UpgradeConfirmed`, `RebirthConfirmed`, and `FactoryEra`. Press/upgrade cues are routine. Rebirth/Factory cues are major and may interrupt routine audio. There is no queue.

## Reduced Motion

Reduced motion does not automatically mute audio. A future reviewed audio preference may be added separately. Missing audio never removes visual or textual confirmation.

## Static Validation

- [x] Uses `--!strict` and a closed semantic cue union.
- [x] No feature presenter creates or plays Sound directly.
- [x] Repository search found no approved SoundId.
- [x] All cue IDs are intentionally empty and safely no-op.
- [x] No placeholder or external SoundId was invented.
- [x] Routine and major concurrency are bounded to one slot each.
- [x] Volume configuration is bounded to `0..1`.
- [x] No music, RemoteEvent, server, or gameplay behavior exists.

## Studio Validation Checklist

- [x] Confirm the empty SoundId configuration safely no-ops with no relevant runtime errors.
- [x] Confirm no `PresentationCue` Sound is created while IDs remain empty.
- [x] Confirm Press, upgrades, Rebirth, and Factory presentation continue normally without audio.
- [ ] In a future asset-review harness, confirm routine replacement and major interruption remain bounded.
- [x] Respawn and confirm no leaked Sound or duplicate audio behavior.
- [x] Confirm Output has no new relevant Script Analysis or runtime errors.

Architect-reported Studio validation confirmed safe empty-ID no-op behavior, normal silent presentation, clean respawn lifecycle behavior, and no new relevant Output errors. Future configured-asset concurrency tests remain unchecked.

## Known Limitations

- All cues are intentionally silent pending reviewed asset IDs.
- No music, audio settings, mix bus, spatial audio, or per-cue rate tuning exists.
- Future configured sounds use a conservative ten-second cleanup ceiling.
- Audible `PressContact` feedback is still desired, but no SoundId is authorized until the follow-up asset audit identifies an already approved project asset.

## Handoff Notes

SoundIds require a separate asset review. Add only approved IDs to the closed cue table; do not let feature presenters bypass semantic playback ownership.
