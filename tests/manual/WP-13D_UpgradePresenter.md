# WP-13D — UpgradePresenter

## Objective

Present a bounded confirmation on only those upgrade cards whose levels increased in authoritative DataSync state, without changing purchase requests, costs, affordability, levels, or server authority.

## Authority Source

`PresentationCoordinator.UpgradeLevelsChanged` is the only success source. UpgradePresenter ignores all other events and ignores level decreases, including the four-level reset produced by Rebirth.

## Ownership Boundary

UpgradePresenter owns card and level-label color emphasis, its subscription, per-upgrade tween cancellation, authored-color restoration, and semantic `UpgradeConfirmed` audio requests. MainGuiClient owns card construction and `BuyUpgrade:FireServer`. AudioPresenter owns playback mechanics.

## Files Changed

- `src/client/UpgradePresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-13D_UpgradePresenter.md`
- `CHANGELOG.md`

## Cancellation and Cleanup

Each canonical upgrade ID has at most one active emphasis. A repeated increase cancels that card's owned tweens, restores its captured colors, and starts a replacement. Delayed callbacks use entry identity and generation checks. `destroy()` disconnects the coordinator subscription, cancels all tweens, and restores every active card.

## Overlap and Priority

One authoritative packet may emphasize each changed card once; work is bounded by the four canonical IDs. Different cards may animate together. Level decreases update through MainGuiClient but do not celebrate. Upgrade feedback is confirmed progression below Rebirth/Factory major progression.

## Reduced Motion

Reduced motion shortens the highlight phase and retains a restrained color-only emphasis. No scale, travel, camera, or overlay is used.

## Static Validation

- [x] Uses `--!strict`.
- [x] Subscribes to PresentationCoordinator and handles only `UpgradeLevelsChanged`.
- [x] Requires `level > previousLevel`.
- [x] Does not calculate cost, affordability, or level values.
- [x] Does not call `FireServer` or discover remotes.
- [x] Work is bounded by four canonical upgrade IDs.
- [x] Repeated same-card presentation cancels and restores deterministically.
- [x] Audio is requested semantically through an injected callback.

## Studio Validation Checklist

- [ ] Purchase each upgrade and confirm only its card and level area emphasize after DataSync.
- [ ] Confirm no emphasis begins on click before authoritative level change.
- [ ] Trigger a multi-upgrade authoritative packet in an isolated harness and confirm only changed cards animate.
- [ ] Rebirth and confirm all level resets display without purchase-success emphasis or audio.
- [ ] Purchase the same upgrade rapidly and confirm exact authored colors restore.
- [ ] Enable reduced motion through an isolated harness and confirm restrained color-only behavior.
- [x] Confirm an authoritative upgrade-level increase emphasizes its matching card after DataSync with no observed regression.
- [x] Respawn and confirm no duplicate coordinator subscription or presentation behavior.
- [x] Confirm Output has no new relevant Script Analysis or runtime errors.

Architect-reported Studio validation confirmed authoritative card emphasis, no observed regression, clean respawn lifecycle behavior, and no new relevant Output errors. More specific unchecked harness and per-upgrade cases remain unclaimed.

## Known Limitations

- This slice emphasizes existing card and level colors only.
- No purchase-specific notification is added.
- Audio is silent until reviewed SoundIds are configured.
- There is no user-facing reduced-motion settings UI.

## Handoff Notes

Keep card construction and purchase authority outside UpgradePresenter. Future card effects should preserve positive-authoritative-level gating, four-card bounds, and exact authored-state restoration.
