# Changelog

## Unreleased

- Recovered the missing Config contract required by the salvaged LCA client, security, session, and factory-evolution code.
- Added the four saved-data upgrade IDs and the confirmed eight-tier rarity names and multipliers.
- Kept unknown monetization IDs disabled and centralized all unknown balance values as `RECOVERY_PROVISIONAL` defaults pending review.
- Recovered the shared number and time formatter with compact suffixes, safe scientific fallback, and invalid-input handling.
- Recovered upgrade stat calculation and level eligibility with fail-closed Config/input normalization and provisional additive formulas.
- Recovered immutable six-stage factory definitions with safe input normalization, confirmed unlock thresholds, and provisional descriptions, colors, and progress behavior.
- Recovered the minimal immutable quest-definition contract with the confirmed `Press` achievement category and no invented gameplay records.
- Added a non-integrated WP-06B1 ServerDataService skeleton with revision-safe dirty tracking; production persistence and lifecycle wiring remain disabled.
- Added the WP-06B2 canonical in-memory SessionRepository with isolated defaults, fail-closed migration, and detached recovered sync packets; persistence and lifecycle integration remain deferred.
- Added WP-06B3 lifecycle integration with a single idempotent player-lifecycle owner, injected sync callbacks, and a non-production in-memory persistence adapter.
- Added the WP-07A authoritative press-only gameplay slice with Loaded-session enforcement, revision-aware mutation, server rate limiting, and explicit COMMON feedback.
- Added the WP-07B authoritative single-upgrade purchase flow with server-derived costs, fail-closed level validation, atomic rollback, independent rate limiting, and DataSync feedback.
- Added WP-08 press-triggered canonical Factory progression; visual and global factory evolution remain deferred.
- Validated the recovered UPG interface and authoritative upgrade purchase flow in Studio; the empty monetization-only SHOP requires no client repair while game passes remain disabled.
- Added and Studio-validated server-authoritative one-second Auto Power production with bounded Heartbeat catch-up, atomic factory progression, revision-aware rollback, and responsive DataSync UI updates.
- Moved and Studio-validated the recovered MainGuiClient under authoritative Rojo ownership at `StarterGui/MainGui/MainGuiClient`, preserving its confirmed ScreenGui properties and eliminating duplicate/manual source ownership.
- Updated the recovered MainGuiClient's five shared-module requires to the current `ReplicatedStorage.LCA_Shared` Rojo path; the deployed Studio copy still requires the same manual update.
