# WP-13A — PresentationCoordinator Foundation

## Objective

Establish a strict, display-free client routing layer that receives authoritative `DataSync` snapshots, compares consecutive valid states, produces typed presentation events, and dispatches them to future feature presenters without changing gameplay or existing presentation.

WP13-A introduces event detection and subscription infrastructure only. It does not render UI, animate, play audio, move the camera, modify Workspace, display notifications, or create gameplay authority.

## Architecture

```text
ServerDataService
    ↓ existing DataSync RemoteEvent
MainGuiClient
    ↓ processDataSync(authoritative packet)
PresentationCoordinator
    ├─ validate and snapshot allowlisted state
    ├─ compare previous and current snapshots
    ├─ construct frozen typed events
    └─ dispatch events to subscribed feature presenters
```

The current implementation is `src/client/PresentationCoordinator.lua`. It is Rojo-mapped beside MainGuiClient under `StarterGui/MainGui` and is required with `script.Parent.PresentationCoordinator`.

The first valid DataSync establishes the comparison baseline and emits no events. Each later valid packet is compared with the immediately preceding valid snapshot.

## Ownership Boundary

PresentationCoordinator owns:

- validation of the authoritative fields needed for presentation comparisons;
- an independently constructed previous-state snapshot;
- comparison of valid consecutive snapshots;
- creation of immutable presentation-event payloads;
- listener registration, dispatch, and idempotent disconnection.

PresentationCoordinator does not own:

- RemoteEvent discovery or connections;
- gameplay requests, calculations, mutations, or authority;
- MainGuiClient's data cache;
- UI objects, tweens, notifications, popups, buttons, or factory rendering;
- audio, camera, VFX, Workspace, polling, Heartbeat, or RenderStepped behavior;
- presenter implementation or event-specific visual policy.

MainGuiClient continues to own the existing `DataSync.OnClientEvent` connection and all pre-existing UI processing. Feature presenters remain responsible for their own rendering and cleanup.

## Event Model

`PresentationCoordinator.init()` enables packet processing. Repeated initialization is harmless because it only sets the internal initialized state.

`PresentationCoordinator.processDataSync(packet)`:

1. rejects processing before initialization;
2. validates and snapshots `Energy`, `FactoryStage`, `Rebirths`, and all four canonical upgrade levels;
3. rejects malformed packets without replacing the previous valid snapshot;
4. records the first valid packet as the baseline without dispatching events;
5. replaces the baseline with each later valid snapshot;
6. compares the new snapshot with the previous one;
7. dispatches applicable events in this order:
   - `EnergyChanged`;
   - `UpgradeLevelsChanged`;
   - `RebirthCompleted`;
   - `FactoryStageChanged`.

The method returns `true` for an accepted valid packet and `false` for uninitialized or malformed input.

`PresentationCoordinator.subscribe(listener)` registers a listener and returns a frozen connection with an idempotent `Disconnect()` method. Listeners are stored by function identity, so registering the same function again does not duplicate that listener. Each listener call is isolated with `pcall`; one listener error does not stop dispatch to the remaining listeners.

Events and nested change records are frozen before dispatch. The coordinator does not expose or reuse packet-owned nested tables.

## Supported Presentation Events

### EnergyChanged

Emitted whenever accepted consecutive snapshots contain different Energy values.

```lua
{
    name = "EnergyChanged",
    previousEnergy = number,
    energy = number,
    delta = number,
}
```

`delta` may be positive or negative because authoritative Energy can increase or be spent/reset.

### UpgradeLevelsChanged

Emitted once per packet when one or more canonical upgrade levels changed. Changes follow canonical ordering: `ClickPower`, `AutoPower`, `CoreAmplifier`, then `Luck`.

```lua
{
    name = "UpgradeLevelsChanged",
    changes = {
        {
            upgradeId = "ClickPower" | "AutoPower" | "CoreAmplifier" | "Luck",
            previousLevel = number,
            level = number,
        },
    },
}
```

### RebirthCompleted

Emitted only when authoritative Rebirths increased. A decrease does not produce a completion event.

```lua
{
    name = "RebirthCompleted",
    previousRebirths = number,
    rebirths = number,
    previousFactoryStage = number,
    factoryStage = number,
}
```

The event carries the before/after Factory Stage values needed by a future presenter but does not perform Rebirth presentation.

### FactoryStageChanged

Emitted whenever accepted consecutive snapshots contain different Factory Stage values.

```lua
{
    name = "FactoryStageChanged",
    previousFactoryStage = number,
    factoryStage = number,
}
```

The coordinator reports the authoritative difference; it does not render or decide Factory layer visibility.

## MainGuiClient Integration

MainGuiClient:

1. requires `PresentationCoordinator` from its sibling ModuleScript;
2. calls `PresentationCoordinator.init()` during client startup;
3. forwards each non-nil DataSync packet to `PresentationCoordinator.processDataSync(data)` after its existing local cache and UI update path, so subscribers capture the latest authored UI state;
4. ignores the coordinator's boolean result so coordinator rejection cannot block the remaining legacy DataSync processing.

The existing DataSync connection, MainGuiClient cache updates, FactoryVisualController reconciliation, notifications, upgrades, Rebirth UI, and other UI refresh behavior remain independently owned and continue after coordinator processing.

WP13-A adds no subscriptions or visible presenters. Therefore event generation has no visual side effect in this foundation slice.

## Files Changed

- `src/client/PresentationCoordinator.lua` — strict coordinator implementation and public event contract.
- `src/client/MainGuiClient.client.lua` — coordinator require, initialization, and DataSync forwarding.
- `default.project.json` — maps one PresentationCoordinator beside MainGuiClient under `StarterGui/MainGui`.
- `tests/manual/WP-13A_PresentationCoordinator.md` — this retrospective implementation and validation record.

No server or shared gameplay file is part of WP13-A.

## Static Validation

- [x] PresentationCoordinator uses `--!strict`.
- [x] The module exports the four approved typed presentation-event variants.
- [x] The first valid packet establishes a baseline without dispatching an event.
- [x] Invalid packets fail closed and do not replace the previous valid snapshot.
- [x] Energy, Factory Stage, Rebirths, and four canonical upgrade levels require finite non-negative integers.
- [x] Factory Stage additionally requires a value of at least 1.
- [x] Event and nested upgrade-change records are frozen.
- [x] Subscriber disconnection is idempotent.
- [x] Listener failures are isolated during dispatch.
- [x] The coordinator contains no RemoteEvent lookup, UI, tween, notification, audio, camera, VFX, Workspace, polling, Heartbeat, or RenderStepped behavior.
- [x] MainGuiClient remains the sole DataSync connection owner.
- [x] MainGuiClient forwards DataSync without making coordinator success a condition of its existing UI processing.
- [x] Exactly one PresentationCoordinator is mapped beside MainGuiClient.
- [x] No gameplay or server behavior is implemented by the coordinator.

## Studio Validation Checklist

- [ ] Open the Rojo-built place and confirm `StarterGui.MainGui.PresentationCoordinator` exists exactly once.
- [ ] Start Play and confirm MainGuiClient requires and initializes the coordinator without Script Analysis or runtime errors.
- [ ] Confirm the first authoritative DataSync produces no presentation event.
- [ ] Subscribe with an isolated test listener and confirm an Energy increase emits one `EnergyChanged` event with the exact previous, current, and delta values.
- [ ] Spend or reset Energy and confirm `EnergyChanged.delta` is negative when appropriate.
- [ ] Purchase each upgrade and confirm `UpgradeLevelsChanged` reports only changed canonical IDs and exact authoritative levels.
- [ ] Complete Rebirth and confirm one `RebirthCompleted` event contains the exact authoritative Rebirth and Factory Stage values.
- [ ] Change Factory Stage and confirm one `FactoryStageChanged` event contains the exact previous and current stages.
- [ ] Confirm a packet changing several fields dispatches events in the documented order.
- [ ] Disconnect a listener twice and confirm it receives no later events and produces no error.
- [ ] Make one isolated listener raise an error and confirm another listener still receives the event.
- [ ] Supply malformed packet shapes from an isolated test harness and confirm `processDataSync` returns false without dispatching or corrupting the valid comparison baseline.
- [ ] Confirm normal HUD, Press, upgrades, Auto Power, Rebirth, Factory rendering, and notifications behave exactly as before.
- [ ] Respawn and confirm no duplicate MainGuiClient, coordinator module, DataSync connection, or event dispatch appears.

Studio-only checks remain unchecked because this document does not claim a dedicated WP13-A Studio harness run.

## Known Limitations

- WP13-A provides an in-memory client event router only; it has no reset or destroy API.
- MainGuiClient currently initializes one coordinator for the lifetime of its Rojo-managed ScreenGui. A future lifecycle change must review explicit reset semantics.
- Listener iteration order is not defined. Event-type order within one DataSync packet is defined, but ordering among listeners for the same event is not.
- Listener errors are intentionally isolated and currently produce no coordinator logging or diagnostics.
- The coordinator validates only the allowlisted comparison fields, not the complete DataSync packet.
- Factory Stage has no upper-bound validation in the coordinator; authoritative shared definitions and downstream reconciliation retain their own validation responsibilities.
- Rebirth completion is inferred from an increase between valid DataSync snapshots. Intermediate transitions may be coalesced if the client receives only a later authoritative snapshot.
- Events are synchronous within `processDataSync`; listeners must remain bounded and must not block UI processing.
- WP13-A includes no event replay for subscribers registered after a state change.
- No visible presenter subscribes as part of WP13-A.

## Handoff to WP13-B

WP13-B should preserve PresentationCoordinator as a display-free authoritative-state router. Press presentation is a separate feature boundary because:

- immediate Press contact is local input acknowledgement rather than a DataSync state transition;
- confirmed reward presentation arrives through the existing authoritative `PressFeedback` contract;
- MainGuiClient remains responsible for firing `PressCore`;
- a feature-owned PressPresenter should own only contact motion, authoritative reward popup aggregation, cancellation, and cleanup;
- PressPresenter must not subscribe to DataSync merely to infer rewards and must never call `FireServer`.

WP13-B must not turn PresentationCoordinator into a general animation service, duplicate DataSync ownership, or move gameplay authority into presentation code. See `src/client/PresentationCoordinator.lua` for the coordinator contract and `tests/manual/WP-13B_PressPresenter.md` for the subsequent PressPresenter boundary.
