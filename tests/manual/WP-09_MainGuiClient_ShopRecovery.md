# WP-09 — MainGuiClient Shop/Upgrade Studio Validation

## Validation status

Completed successfully in Studio on the `recovery/studio-salvage` recovery line.

No MainGuiClient runtime repair was required. This document records observed integration behavior rather than prescribing an untested implementation.

## Panel identity and navigation

- [x] SHOP and UPG are separate panels.
- [x] SHOP is the recovered monetization-only panel.
- [x] SHOP remains empty because `Config.GamePasses` is intentionally empty.
- [x] Empty SHOP is expected while no recovered game-pass IDs or definitions are enabled.
- [x] UPG opens the canonical `UpgradePanel` successfully.
- [x] Legacy FactoryEvolution remains disabled in Studio.

## Canonical upgrade rows

- [x] Exactly four upgrade rows are displayed.
- [x] `AutoPower` is present.
- [x] `ClickPower` is present.
- [x] `CoreAmplifier` is present.
- [x] `Luck` is present.
- [x] No unsupported, legacy, duplicated, or speculative row is present.
- [x] Initial levels are displayed.
- [x] Costs derived from `Config.getUpgradeCost` are displayed.

The visible ordering recorded during Studio validation was AutoPower, ClickPower, CoreAmplifier, and Luck. The recovered construction contract remains `Config.Upgrades` ordering; future ordering differences must be investigated as deployed-copy or Instance-layout differences rather than normalized silently.

## Authoritative purchase integration

- [x] Sufficient Energy was earned through PressCore before purchase.
- [x] Clicking the ClickPower row sent the exact `ClickPower` upgrade ID.
- [x] The authoritative server accepted the purchase.
- [x] Energy was deducted correctly by the server.
- [x] ClickPower level changed from 0 to 1.
- [x] DataSync updated the client cache and visible UI.
- [x] The next Press reward increased from +1 to +2.

The client uses Config cost and cached Energy/level only for presentation. GameplayService remains authoritative: it re-reads session state, recalculates cost, validates eligibility and Energy, performs mutation, marks dirty, and synchronizes the result.

## Runtime-change decision

- [x] No MainGuiClient runtime change was required.
- [x] No server or shared module was changed for this validation slice.
- [x] No SHOP-to-UPG routing or duplicated upgrade renderer was added.
- [x] No game-pass definition, ID, price, or purchase behavior was invented.
- [x] No purchase-success RemoteEvent or optimistic client mutation was added.
- [x] FactoryEvolution was not reactivated.

## Deferred systems

- [ ] SHOP empty-state presentation and future monetization UX.
- [ ] Rebirth confirmation repair.
- [ ] Daily and Playtime claim validation/feedback.
- [ ] Quest, Achievement, Collection, and DailyLogin behavior.
- [ ] History and rarity UI recovery.
- [ ] FactoryEvolution visual/global behavior.
- [ ] Moving MainGuiClient into the Rojo-mapped `src/client` hierarchy.
