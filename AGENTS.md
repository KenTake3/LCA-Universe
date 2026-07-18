# Atlas 2.0 Repository Guide

This repository contains **LCA Universe / Lucky Core Factory**, a Roblox factory-progression game whose long-term destination is player creativity. This file is the entry point for humans and AI agents working under the Atlas 2.0 documentation system.

## Read Before Changing Anything

Read the documents relevant to the work in this order:

1. `docs/PRODUCT.md` — product intent, audience, experience, scope, and success criteria.
2. `docs/AtlasDesignConstitution.md` — durable product and design principles.
3. `docs/AI_ENGINEERING_CONTRACT.md` — engineering boundaries, evidence rules, workflow, and completion standard.
4. `docs/06_Current_System.md` — current implementation and recovery evidence.
5. `docs/PresentationBible.md` — presentation behavior and ownership when working on client presentation.
6. The remaining numbered documents in `docs/` for historical vision, universe, design, architecture, economy, and roadmap context.

Task-specific prompts and manual validation plans live in `prompts/codex/` and `tests/manual/`.

## Source-of-Truth Rules

- The current code and `docs/06_Current_System.md` describe what exists now.
- `docs/PRODUCT.md` describes what the product is trying to become.
- `docs/AtlasDesignConstitution.md` governs design decisions when requirements are incomplete.
- `docs/AI_ENGINEERING_CONTRACT.md` governs how changes are made and verified.
- A task-specific accepted specification may narrow these documents, but must not silently contradict them.
- When documents disagree with observable behavior, record the discrepancy; do not invent compatibility or rewrite history.

## Repository Boundaries

- `src/shared/` contains definitions and utilities shared across runtime boundaries.
- `src/server/` owns authority, validation, progression, persistence, and rewards.
- `src/client/` owns input, UI, effects, audio, camera, and presentation of authoritative state.
- `recovery/studio/` is recovery evidence, not the default production source tree.
- `docs/` contains durable product and engineering knowledge.
- `prompts/codex/` contains scoped work-package specifications.
- `tests/manual/` contains manual verification contracts.

Preserve unrelated work in a dirty worktree. Do not edit generated place files or recovered evidence unless the task explicitly requires it. Do not broaden a documentation task into gameplay or runtime changes.

## Default Working Agreement

- Inspect before editing; distinguish confirmed facts, inferences, proposals, and unknowns.
- Keep server authority intact. A client may request and present, but must not decide rewards or persisted progression.
- Prefer the smallest coherent change that satisfies the accepted scope.
- Do not introduce currencies, remotes, data fields, asset IDs, balance values, or monetization behavior without an approved source.
- Update documentation and validation artifacts when a contract or player-visible behavior changes.
- Run checks proportional to risk and report commands and outcomes honestly.
- Never commit, push, publish, or modify external systems unless the task explicitly authorizes it.
