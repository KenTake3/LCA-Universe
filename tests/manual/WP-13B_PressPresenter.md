# WP-13B — PressPresenter Foundation

## Objective

Extract the active Press contact and confirmed COMMON reward-popup presentation from MainGuiClient into one strict, feature-owned client module without changing Press gameplay, server authority, reward values, RemoteEvents, or unrelated presentation.

## Ownership boundary

PressPresenter owns only:

- immediate local compression and restoration of the injected Press TextButton;
- validation and display of reward values received through the existing authoritative PressFeedback path;
- one bounded reward aggregation sequence and at most one active reward popup;
- its own contact/popup tweens, delayed callbacks, temporary TextLabel, cancellation, and cleanup.

PressPresenter does not:

- connect button or RemoteEvent signals;
- call FireServer or FireClient;
- calculate rewards, rarity, Energy, stats, or gameplay state;
- subscribe to DataSync or PresentationCoordinator;
- create notifications, sounds, camera effects, VFX, Workspace effects, polling, Heartbeat, or RenderStepped work;
- own dormant rarity notifications or screen-flash branches.

MainGuiClient remains responsible for firing exactly one PressCore request from its existing button handler and forwarding validated PressFeedback payloads.

## Files changed

- `src/client/PressPresenter.lua`
- `src/client/MainGuiClient.client.lua`
- `default.project.json`
- `tests/manual/WP-13B_PressPresenter.md`

No server or shared gameplay module is in scope.

## Aggregation contract

The fixed aggregation window is 150 milliseconds.

The first accepted authoritative reward:

1. creates the sole `PressRewardPopup` immediately;
2. displays its confirmed reward total immediately;
3. fades in with explicit Quad/Out easing;
4. keeps the 150ms sequence open.

Each accepted reward inside that same fixed window is added to the displayed total. The aggregation deadline is not extended, so continuous input cannot keep one sequence open without bound.

At the end of the window, the popup moves upward and fades over 0.8 seconds with explicit Quad/Out easing. A later sequence cancels and destroys the old popup before creating its replacement. PressPresenter therefore owns no queue and never owns more than one reward popup.

The 150ms window is long enough to combine adjacent confirmations at the approved rapid Press rate while remaining shorter than a typical consciously perceived UI response delay.

## Payload validation

- Payload must be a table.
- Reward must be a finite positive number.
- Missing, zero, negative, non-number, NaN, and positive/negative infinity rewards are rejected.
- The popup uses the authoritative payload reward and validated Color3 supplied through PressFeedback.
- A missing reward is never defaulted to 1 or another value.
- MainGuiClient validates the remaining rarity presentation fields before forwarding the payload or entering dormant rarity branches.
- Rejected payloads create no popup and do not alter an active aggregation total.

## Contact motion

- Compression duration: 0.1 seconds, Quad/Out.
- Restoration duration: 0.1 seconds, Quad/Out.
- A new contact cancels both owned contact tweens and replaces the sequence.
- The original injected button size is retained and restored.
- Immediate contact feedback does not claim server success and does not supply a reward.

## Cleanup

- Popup fade and movement tweens are cancelled before replacement.
- The previous popup is explicitly destroyed before a new sequence starts.
- Final popup destruction uses a bounded delayed cleanup after the movement duration and does not depend on Tween.Completed.
- Generation tokens make superseded delayed callbacks no-ops.
- `destroy()` cancels contact and popup tweens, restores the original button size, destroys the popup, and clears dependencies.
- The module does not create signal connections, so it cannot duplicate button or remote ownership after respawn.

## Static validation

- [x] `--!strict` is present.
- [x] Exactly one PressPresenter is mapped beside MainGuiClient under `StarterGui/MainGui`.
- [x] PressPresenter contains no RemoteEvent lookup or FireServer/FireClient call.
- [x] PressPresenter contains no Workspace, camera, audio, VFX, notification, polling, Heartbeat, or RenderStepped behavior.
- [x] MainGuiClient retains the sole PressCore button request call.
- [x] MainGuiClient forwards accepted authoritative PressFeedback to PressPresenter.
- [x] The extracted MainGuiClient popup and Press-button tween implementation is removed.
- [x] PresentationCoordinator and FactoryVisualController are unchanged by WP-13B.
- [x] `git diff --check` passes.
- [x] Rojo build succeeds.

## Studio validation checklist

- [ ] Join and confirm exactly one MainGuiClient and one PressPresenter module exist under MainGui.
- [x] Click Press once and confirm the button compresses immediately, then returns to its original size.
- [ ] Confirm exactly one PressCore request is sent for one accepted button activation.
- [ ] Confirm no reward popup appears before authoritative PressFeedback.
- [x] Confirm one valid COMMON PressFeedback displays the authoritative reward popup and Energy updates from server processing.
- [ ] Send missing, nil, zero, negative, string, boolean, table, NaN, and both infinite rewards from an isolated test harness; confirm no popup appears.
- [x] Press at the approved rapid rate and confirm adjacent rewards aggregate into one readable total.
- [ ] Confirm the displayed total equals the sum of every accepted reward in that 150ms sequence.
- [ ] Confirm no more than one `PressRewardPopup` exists at any time.
- [ ] Confirm a later sequence replaces and destroys the prior popup cleanly.
- [ ] Confirm no popup remains after its bounded lifetime.
- [x] Confirm rapid contact input does not leave the Press button compressed.
- [ ] Confirm Energy, TotalPresses, Factory progression, DataSync, upgrades, Auto Power, and Rebirth remain unchanged.
- [ ] Confirm existing rarity notifications/flashes remain dormant under the current COMMON-only server contract.
- [x] Confirm Output has no new relevant runtime or Script Analysis errors.
- [x] Respawn and confirm no duplicate input or PressFeedback handling appears.

Architect-reported Studio validation confirmed contact motion, authoritative Energy/popup feedback, rapid popup aggregation, clean button restoration, respawn lifecycle behavior, and no new relevant Output errors. Malformed-payload harness cases and other unchecked items were not claimed.

## Known limitations

- WP-13B intentionally preserves the existing fixed 400px popup width; mobile layout redesign is deferred.
- The aggregation window groups only confirmations received during the first fixed 150ms and does not extend with later rewards.
- A new sequence replaces an older popup that may still be moving; this is intentional to maintain the one-popup bound.
- Dormant non-COMMON rarity notifications and screen flashes remain in MainGuiClient and are not centralized in this slice.
- Immediate contact feedback acknowledges input only; authoritative server rejection produces no confirmed popup.
- The existing whole-UI timer loop remains unchanged and outside WP-13B.

## Handoff notes

- Keep PressPresenter feature-owned; do not turn it into a general tween or presentation service.
- Future motion tokens may replace its local constants only after another approved feature shares the same vocabulary.
- Future PresentationCoordinator subscribers should not duplicate PressFeedback reward presentation.
- Notification, audio, camera, machine VFX, reduced motion, and popup responsive-layout work require separate reviewed slices.
- Preserve the one-popup invariant and authoritative reward-only boundary in later work.
