# Atlas 2.0 Design Constitution

Status: Governing foundation

## Purpose

This constitution defines the durable principles used to resolve incomplete or competing requirements for LCA Universe. It guides product, interaction, visual, economy, and technical design. Feature specifications may add constraints; exceptions to this constitution must be explicit, narrow, and documented with their tradeoff.

## Article I — Creation Is the Destination

The product begins with factory progression and grows toward player authorship. Features should move the player from operating a system to shaping a place and expressing an identity.

- Repetition may teach the loop, but must not be the permanent destination.
- Progress should unlock capability, choice, visible transformation, or expression.
- Creative systems must not be reserved exclusively for payment.

## Article II — The Player Must Understand Cause and Effect

Every important action needs a readable request, result, and next state.

- Immediate local feedback may acknowledge input but must not claim success.
- Rewards, purchases, progression, and saved outcomes are presented only after authoritative confirmation.
- Persistent state outranks transient celebration.
- Errors explain what happened and, when possible, what the player can do next.
- Color, sound, motion, text, and numbers must communicate the same meaning.

## Article III — Progress Must Become Visible

Numerical growth alone is insufficient. Milestones should change what the player can see, do, arrange, or share.

- Major progression has a durable representation after its celebration ends.
- Factory evolution should read through silhouette, structure, light, motion, and spatial organization.
- Visual spectacle must not obscure the actual state change.
- Screenshots of stable play should remain attractive and legible.

## Article IV — Calm Is a Feature

LCA is industrial, peaceful, beautiful, and readable.

- Hierarchy comes from spacing, scale, contrast, and timing before decoration.
- Celebration intensity follows significance, not frequency.
- High-frequency feedback aggregates, replaces, or reuses presentation rather than accumulating.
- Motion feels mechanical and deliberate: compress, charge, release, reconcile, evolve, settle.
- No design should depend on noise, urgency, or interruption to remain engaging.

## Article V — Respect Player Time and Trust

The game does not manufacture anxiety to compensate for shallow value.

- Goals, costs, cooldowns, odds, and requirements are communicated honestly.
- No deceptive UI, false success, hidden loss, or accidental-purchase pressure.
- Returning players receive continuity, not punishment designed solely to force attendance.
- Random outcomes have a clear purpose and do not replace all meaningful agency.
- Monetization may improve pace or convenience, never basic dignity or creative access.

## Article VI — Mobile Is the Baseline

The primary experience must work comfortably on touch devices; desktop enhancements must preserve the same product truth.

- Important controls are reachable, large enough, and unobstructed.
- Layouts survive narrow viewports, safe areas, localization growth, and dynamic values.
- Information density is reduced before legibility is sacrificed.
- Effects respect device performance and avoid unbounded instances, particles, tweens, or overdraw.
- Pointer hover and keyboard shortcuts may enhance interaction but cannot be the only path.

## Article VII — Accessibility Preserves Meaning

Every player must receive the information required to act and understand outcomes.

- Meaning is never conveyed by color, sound, or motion alone.
- Reduced motion removes nonessential travel, shake, flashes, oscillation, and camera effects while preserving state and hierarchy.
- Audio supplements visible information and has bounded playback and a mute path.
- Text favors contrast, plain language, adequate duration, and resilient containers.
- Accessibility settings must not change authoritative results.

## Article VIII — Systems Earn Their Complexity

Every mechanic, currency, upgrade, and screen must have a distinct player-facing job.

- Do not add a system solely to imitate genre convention.
- Avoid currencies or upgrade branches whose only purpose is to gate another meter.
- Prefer a small number of composable rules over many exceptions.
- Introduce complexity after the player has a reason to care about it.
- A feature owns its behavior and cleanup; shared layers coordinate contracts rather than becoming universal controllers.

## Article IX — Authority and Presentation Stay Separate

Technical ownership is part of product integrity.

- The server owns validation, rewards, economy, progression, purchases, and persisted data.
- The client owns input, rendering, interface, audio, camera, and effects.
- Shared modules define deterministic contracts and pure calculations that both boundaries require.
- Presentation observes authoritative state; it never grants progress or invents rewards.
- Failure, interruption, reconnection, or skipped animation must still converge to correct state.

## Article X — Build From Evidence

Recovery work and new design must distinguish fact from intention.

- Existing code and runtime evidence describe current behavior.
- Product documents describe desired behavior.
- Unknown balance, asset IDs, payloads, and legacy behavior remain unknown until verified.
- Inferences and recommended defaults must be labeled.
- Compatibility changes preserve proven contracts and fail safely when evidence is incomplete.

## Article XI — Every Feature Has a Complete State Model

A feature is not designed only for its happy path. Its specification must consider:

- Initial, loading, ready, locked, unavailable, and failure states.
- Accepted, rejected, repeated, delayed, and out-of-order actions.
- Rejoin, reconnect, resynchronization, and correction.
- Mobile layout, reduced motion, missing optional assets, and degraded performance.
- Ownership, cleanup, bounded resource use, and observability.

Not every feature needs custom behavior for every state, but the omission must be deliberate.

## Article XII — Quality Is Part of Scope

Work is complete when behavior, verification, and durable knowledge agree.

- Acceptance criteria must be observable.
- Validation should cover the highest-risk boundary and failure cases, not only the demonstration path.
- Documentation changes accompany changes to contracts, ownership, or player-visible rules.
- Known limitations are recorded plainly; they are not disguised as completed behavior.
- A smaller coherent feature is preferable to a larger feature with ambiguous authority or unreliable cleanup.

## Constitutional Review

Use this review for product and design decisions:

1. Does it increase capability, beauty, ownership, or sharing?
2. Is cause and effect honest and legible?
3. Does durable state remain clear after effects end?
4. Is the experience calm, accessible, and mobile-first?
5. Does the system justify its complexity and respect player time?
6. Are authority, ownership, failure behavior, and cleanup explicit?
7. Which claims are confirmed, inferred, proposed, or unknown?

If a proposal violates an article, document the exception, why no conforming alternative works, the affected scope, and how the exception will be reviewed or removed.
