# WP-13C — Presentation Bible

## Objective

Establish a canonical, project-wide presentation language for LCA Universe before expanding client presentation implementation. WP13-C defines shared principles, priorities, vocabulary, accessibility expectations, and ownership boundaries without adding or changing gameplay, UI behavior, VFX, SFX, camera behavior, animation, or server behavior.

WP13-C is documentation-only. It does not claim implementation or Studio validation of future presentation standards.

## Canonical Presentation-Design Source

`docs/PresentationBible.md` is the canonical presentation-design source for LCA Universe.

Future presentation designs and implementation work packages should cite it, identify the standards they apply, and document any deliberate exception during Architect review. Feature documentation may add implementation-specific contracts, but should not silently redefine the shared presentation language.

The Bible guides presentation behavior. It does not supersede authoritative gameplay, persistence, RemoteEvent, DataSync, or security contracts.

## File Created

- `docs/PresentationBible.md` — canonical presentation philosophy, standards, ownership boundaries, and emotional-flow guidance.
- `tests/manual/WP-13C_PresentationBible.md` — this documentation validation and handoff record.

No source-code or gameplay file is part of WP13-C.

## Sections Covered

The Presentation Bible covers:

1. Presentation philosophy: responsiveness, clarity, anticipation, celebration, readability, and accessibility.
2. Event priority from safety/state correction through ambient presentation.
3. Motion vocabulary for contact, charge, release, lock, reconcile, evolve, and settle behavior.
4. Timing standards for contact, aggregation, routine feedback, major sequences, and notifications.
5. Audio standards and confirmation boundaries.
6. Camera standards, restoration, and reduced-motion constraints.
7. Popup authority, aggregation, readability, and cleanup standards.
8. Factory reconciliation, cumulative layers, Workspace ownership, and celebration eligibility.
9. Notification priority, deduplication, clarity, and authority rules.
10. Reduced-motion policy.
11. Mobile readability and performance policy.
12. Future presenter ownership boundaries.
13. The player-facing emotion curve from Input through Mastery.
14. The “Never Fight Gameplay” rule.

This record intentionally summarizes coverage rather than duplicating the complete Bible.

## Architectural Rules Established

- Presentation follows authoritative gameplay state and never invents rewards, progression, success, or persisted values.
- Immediate local feedback may acknowledge input only when it cannot imply authoritative success.
- Persistent UI and world reconciliation take priority over transient celebration.
- Presentation must never block gameplay input or make effect completion a gameplay prerequisite.
- High-frequency feedback is bounded, aggregated, replaced, or cancelled rather than queued without limit.
- Temporary instances, tweens, connections, and delayed cleanup remain feature-owned and deterministic.
- A central coordinator may compare authoritative state and route typed events, but remains display-free.
- Feature presenters own their specific rendering and must not become general gameplay or animation services.
- Factory rendering remains isolated to its approved Workspace boundary and does not grant progression.
- Audio, camera, color, and motion supplement readable state; no single sensory channel carries required meaning alone.
- Reduced-motion and mobile policies preserve authoritative information while reducing decorative intensity and cost.
- When presentation overlaps or fails, input, authoritative state, reconciliation, and readability win.

## Relationship to WP13-A PresentationCoordinator

WP13-A created the display-free event-routing foundation documented in `tests/manual/WP-13A_PresentationCoordinator.md`.

The Presentation Bible confirms that PresentationCoordinator should:

- receive and compare authoritative DataSync state;
- emit typed presentation events;
- dispatch events without owning their visual treatment;
- remain free of UI, tweens, notifications, audio, camera, VFX, Workspace mutation, and gameplay authority.

Future presenters may subscribe to approved coordinator events, but the Bible does not authorize changes to the coordinator API or event set by itself. Each integration requires a reviewed implementation slice.

## Relationship to WP13-B PressPresenter

WP13-B established a feature-owned Press presentation boundary documented in `tests/manual/WP-13B_PressPresenter.md`.

Its current contract demonstrates several Bible rules:

- immediate contact motion acknowledges input without claiming server success;
- confirmed popup values come only from authoritative PressFeedback;
- rapid rewards aggregate within a fixed bounded window;
- one popup replaces another instead of forming an unlimited queue;
- feature-owned tweens and temporary instances are cancelled and cleaned deterministically;
- MainGuiClient retains the gameplay request, while PressPresenter never calls `FireServer`.

WP13-C does not alter or retroactively validate PressPresenter implementation. Future Press refinements should preserve its authority and ownership boundary while applying reviewed accessibility or mobile standards.

## Documentation Validation

- [x] `docs/PresentationBible.md` exists.
- [x] The Bible defines all fourteen documented presentation sections.
- [x] The document identifies server-authoritative gameplay as the source of outcomes.
- [x] The document keeps PresentationCoordinator display-free.
- [x] The document keeps feature presenters narrowly owned.
- [x] The document defines bounded high-frequency presentation and deterministic cleanup.
- [x] The document defines reduced-motion and mobile policies.
- [x] The document defines the emotion curve.
- [x] The document defines the “Never Fight Gameplay” rule.
- [x] This manual record references WP13-A, WP13-B, and the canonical Bible without copying the complete Bible.
- [x] WP13-C introduces no code or gameplay change.

These checks validate documentation structure and stated architecture only. They do not validate future implementation or Studio behavior.

## Review Checklist

- [ ] Architect confirms `docs/PresentationBible.md` as the canonical presentation-design source.
- [ ] Architect confirms the event-priority ordering.
- [ ] Architect confirms the motion vocabulary and timing ranges.
- [ ] Architect confirms the audio and camera constraints before either system is implemented.
- [ ] Architect confirms popup and notification channel separation.
- [ ] Architect confirms Factory presentation remains reconciliation-first and DataSync-authoritative.
- [ ] Architect confirms reduced-motion requirements for future presenter dependency contracts.
- [ ] Architect confirms mobile performance and readability requirements.
- [ ] Architect confirms future presenter ownership boundaries.
- [ ] Architect selects the next implementation slice and its exact allowlist.

Review items remain unchecked until explicitly approved. WP13-C has no implementation or Studio test completion to mark.

## Known Limitations

- The Bible defines standards but does not provide shared motion, audio, camera, notification, accessibility, or preference modules.
- Timing values are approved design ranges, not automatic enforcement.
- Reduced-motion preference storage and runtime propagation are not designed or implemented.
- Mobile viewport coverage, text scaling, device performance tiers, and effect budgets require feature-specific acceptance tests.
- Audio assets, mix levels, concurrency limits, and music ownership remain unresolved until an audio-focused design.
- Camera effects remain prohibited unless a future reviewed slice defines ownership and restoration precisely.
- Event priority is a policy; there is not yet a centralized scheduler enforcing it.
- Existing MainGuiClient notification and dormant rarity presentation have not been migrated into dedicated presenters.
- Documentation validation cannot prove runtime cleanup, accessibility, visual quality, or performance.

## Handoff to the Next WP13 Implementation Slice

The next slice should be narrow, authoritative-event-driven, and visibly testable without introducing a broad animation framework.

Before implementation, the package should:

1. name one feature presenter and its exact ownership boundary;
2. identify the authoritative confirmation event it consumes;
3. select the applicable Bible priority, motion, timing, accessibility, mobile, and cleanup rules;
4. define cancellation, overlap, stale-event, respawn, and deterministic teardown behavior;
5. preserve PresentationCoordinator as event routing only;
6. preserve gameplay and server authority;
7. add no RemoteEvent unless a separately reviewed gameplay contract requires one;
8. include static checks and an honest Studio validation checklist.

Candidate future slices include a narrowly scoped authoritative Upgrade presenter or Rebirth presenter. Notification, audio, camera, and major Factory celebration should remain separate until their priority and cross-feature ownership contracts are approved.

## References

- `docs/PresentationBible.md` — canonical presentation-design source.
- `tests/manual/WP-13A_PresentationCoordinator.md` — coordinator architecture and validation record.
- `tests/manual/WP-13B_PressPresenter.md` — Press presentation ownership, aggregation, and cleanup record.
