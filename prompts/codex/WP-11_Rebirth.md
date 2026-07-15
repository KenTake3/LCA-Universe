# WP-11 — Server-Authoritative Rebirth

## Approved contract

`RequestRebirth` accepts exactly zero arguments. The server re-reads canonical Energy and Rebirths and calculates the requirement with `Config.getRebirthCost(currentRebirths)`. Successful Rebirth requires Energy greater than or equal to that cost and Rebirths below `Config.Security.MaxRebirths`.

The atomic mutation is exactly:

- `Energy = 0`;
- `Rebirths = oldRebirths + 1`;
- all four canonical UpgradeLevels become `0`;
- LifetimeEnergy is preserved;
- Factory eligibility is recalculated from preserved LifetimeEnergy and new Rebirths;
- FactoryStage and HighestFactoryStage advance together only for a new highest eligible stage.

Gems, TotalPresses, reward/login state, quests, achievements, collections, rarity/history data, perks, FirstJoin, DataVersion, and unknown safe legacy fields are preserved.

## Authority and transaction boundary

`GameplayService.rebirth(player)` accepts no gameplay values. It requires the exact Loaded, non-busy canonical session and validates revision metadata, caps, all four upgrade levels, and Factory invariants. Invalid live data fails closed rather than being normalized.

After assigning the complete transaction it calls `ServerDataService.markDirty(player)` exactly once. Dirty failure restores Energy, Rebirths, all four upgrade levels, FactoryStage, and HighestFactoryStage. DataSync is attempted exactly once only after dirty success. Sync failure does not roll back. QuestSync and FactoryEvolutionSync are excluded.

## Transport and rate limiting

`GameplayRemoteController` owns exactly one RequestRebirth listener and an independent weak-key limiter. A valid zero-argument request may be admitted at most once per Player per second. Malformed payloads are rejected before admission. The controller does not inspect sessions, calculate cost, mutate data, or send feedback.

## Auto Power compatibility

AutoPowerScheduler is unchanged. Gameplay transactions do not yield before dirty marking, so Auto Power and Rebirth observe a complete before-or-after canonical state. Resetting AutoPower to zero makes subsequent scheduled ticks natural no-ops.

## Explicit exclusions

No client-authored values, Gems reward, QuestSync, quest/achievement behavior, daily/playtime/login behavior, offline progression, production persistence, autosave, retry, lease, visual FactoryEvolution, FactoryEvolutionSync, or new RemoteEvent is included. The client sends only the request and waits for DataSync-driven UI state; WP-11 adds no replacement notification.
