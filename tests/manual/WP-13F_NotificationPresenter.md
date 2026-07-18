# WP-13F — NotificationPresenter

## Objective

Extract MainGuiClient's notification mechanics into one bounded presenter with explicit priority, duplicate suppression, replacement, animation, and deterministic cleanup.

## Authority Source

NotificationPresenter does not determine outcomes. MainGuiClient and feature presenters supply already classified text/color after their existing client-validation or authoritative-event boundaries.

## Ownership Boundary

NotificationPresenter owns notification TextLabels, corners, layout ordering, fade tweens, deduplication history, the maximum-visible policy, replacement, and cleanup. It does not own Press reward popups, RemoteEvents, gameplay validation, or outcome text generation.

## Files Changed

- `src/client/NotificationPresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `src/client/RebirthPresenter.lua`
- `default.project.json`
- `tests/manual/WP-13F_NotificationPresenter.md`
- `CHANGELOG.md`

The obsolete unused `Notification` Remote lookup was removed; no RemoteEvent Instance or server contract changed.

## Cancellation and Cleanup

Replacement cancels both owned tweens and destroys the label immediately. Natural expiry uses a three-second hold, explicit 0.5-second fade, and bounded delayed destruction rather than relying on Tween.Completed. `destroy()` removes every active notification and clears bounded deduplication history.

## Overlap and Priority

Maximum visible count: three.

- Routine can replace only the oldest routine; otherwise it is dropped.
- Failure replaces the oldest routine, then oldest failure; it does not displace major progression.
- Major progression replaces the oldest routine first, then failure, then the oldest major if necessary.
- Identical routine or failure messages are deduplicated for one second.
- Deduplication history is capped at eight entries.
- Visible LayoutOrder is recomputed as `1..#visible`; no monotonically growing counter exists.

## Reduced Motion

Notifications already use short opacity-only fades with no spatial travel. The same readable behavior is retained under reduced motion.

## Static Validation

- [x] Uses `--!strict`.
- [x] Maximum visible count is three.
- [x] Major progression cannot be displaced by routine.
- [x] Routine/failure deduplication window is bounded at one second.
- [x] Deduplication storage is capped.
- [x] LayoutOrder is bounded by visible count.
- [x] Cleanup does not rely solely on Tween.Completed.
- [x] Cancelled/replaced labels are destroyed.
- [x] Press reward popup ownership remains in PressPresenter.
- [x] No RemoteEvent was added.

## Studio Validation Checklist

- [ ] Confirm welcome, insufficient-Rebirth-Energy, rarity, broadcast, Rebirth, and Factory-era messages use the extracted presenter.
- [x] Exercise notification flow and confirm the bounded visible-notification behavior works.
- [ ] Fill slots with a major notification and confirm routine cannot displace it.
- [ ] Repeat identical routine/failure within one second and confirm deduplication.
- [ ] Repeat after one second and confirm it may display again.
- [ ] Replace active entries and confirm no stale labels or tweens remain.
- [x] Confirm notification overlays do not intercept input.
- [x] Respawn and confirm no duplicate notification ownership or behavior.
- [x] Confirm Output has no new relevant Script Analysis or runtime errors.

Architect-reported Studio validation confirmed bounded notifications, non-blocking interaction, clean respawn lifecycle behavior, and no new relevant Output errors. Exact deduplication-window and priority-replacement harness cases remain unchecked.

## Known Limitations

- Deduplication compares priority plus exact text, not semantic message IDs.
- Text wrapping and dynamic-height notifications are deferred.
- Existing colors and 300px container width are retained.
- There is no centralized cross-channel presentation scheduler.
- Navigation buttons below `QUEST` currently have no implemented destination or content. This is outside WP13 gameplay scope; a future design should implement them, disable them, or provide a clear `Coming Soon` response.

## Handoff Notes

Future callers must classify messages explicitly and must not use NotificationPresenter to infer success. Preserve the three-visible bound and keep Press popups separate.
