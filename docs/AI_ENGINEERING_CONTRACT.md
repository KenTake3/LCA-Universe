# Atlas 2.0 AI Engineering Contract

Status: Governing foundation
Applies to: AI-assisted analysis, documentation, implementation, review, and validation in this repository

## 1. Objective

AI collaborators help build LCA Universe safely, transparently, and in alignment with product intent. They are expected to make useful progress without inventing facts, widening scope silently, or damaging unrelated work.

This contract defines the default operating standard. The user’s current request and repository instructions take precedence when they are more specific.

## 2. Instruction and Evidence Order

Use the following order when deciding what to do:

1. The user’s explicit request and constraints.
2. The nearest applicable `AGENTS.md` instructions.
3. An accepted feature specification or work-package prompt.
4. Governing product and design documents.
5. Current code, tests, project mapping, and runtime evidence.
6. Historical or recovery documents.
7. Clearly labeled inference or proposal.

Instruction priority and factual evidence are different: a specification can define a desired change, but it cannot make an unobserved current behavior factual.

## 3. Truth Labels

Use these categories whenever certainty matters:

- **Confirmed:** Directly supported by current source, configuration, test output, runtime inspection, or an accepted specification.
- **Inferred:** Strongly suggested by evidence but not fully established.
- **Proposed:** A new recommendation awaiting acceptance or implementation.
- **Unknown:** Not recoverable from available evidence.

Never fabricate original balance, DataStore names, asset IDs, product IDs, remote payloads, analytics results, or legacy behavior. Recommended defaults must be named as defaults and chosen to fail safely.

## 4. Scope Control

Before editing, identify:

- The requested outcome.
- Files and systems likely in scope.
- Explicit prohibitions.
- Existing user changes that must be preserved.
- The minimum verification needed for the risk.

Do not turn a documentation request into a runtime refactor, a diagnosis into an unsolicited fix, or a scoped feature into a repository-wide cleanup. If completion requires a materially different change, request authorization.

## 5. Repository Safety

- Inspect the worktree before changing files.
- Treat all pre-existing modifications and untracked files as user work.
- Do not overwrite, revert, delete, rename, format, stage, or commit unrelated work.
- Prefer focused patches and review the resulting diff.
- Do not edit binary Roblox place files unless explicitly requested.
- Do not commit, push, publish, deploy, open a pull request, or modify external state without explicit authorization.
- Never expose credentials, secrets, private data, or sensitive command output.

## 6. Architecture Contract

### Server

The server is authoritative for accepted actions, validation, currencies, rewards, upgrade eligibility, Rebirth, Factory Stage, purchases, persistence, and anti-abuse controls.

### Client

The client may collect input, send requests, predict non-authoritative contact feedback, and present authoritative state. It must not grant rewards, claim success before confirmation, or become the sole owner of persisted truth.

### Shared

Shared code contains deterministic definitions, formats, types, and calculations required on both sides. Shared availability is not permission to trust client-supplied results.

### Recovery evidence

Files under `recovery/` inform reconstruction but do not automatically override production code under `src/`. Compatibility claims require evidence from actual call sites and mapped runtime structure.

## 7. Change Design Standard

For a behavior change, define or confirm:

- Player-visible intent and acceptance criteria.
- Owning module or service.
- Input and output contract.
- Authority boundary.
- State transition and persistence impact.
- Invalid, missing, duplicate, delayed, and rejected input behavior.
- Cleanup and bounded resource use.
- Backward compatibility and migration needs.
- Mobile, accessibility, and degraded-mode behavior when relevant.
- Verification and documentation impact.

Prefer the smallest coherent ownership boundary. Avoid generic managers that absorb feature-specific behavior without a proven shared contract.

## 8. Remote and Data Rules

- Reuse established remotes when their semantics and payloads match; do not create duplicates casually.
- Validate every client-controlled value on the server for type, range, finiteness, identity, eligibility, and rate as appropriate.
- Fail closed on malformed or unknown requests.
- Keep response and synchronization payloads explicit and versionable.
- Never infer success from a sent request.
- Data schema changes require defaults, migration behavior, compatibility analysis, and save/load validation.
- Persistence code must account for load failure, retry policy, shutdown, player removal, and partial or stale data.
- Economy calculations must be deterministic, finite, bounded, and server-owned.

## 9. Implementation Workflow

### Inspect

Read applicable instructions, specifications, current code, tests, and worktree status. Search for all producers and consumers of a contract before changing it.

### Plan

State assumptions and choose a narrow implementation path. Resolve risky ambiguity from repository evidence; ask only when a decision would materially change the requested outcome.

### Implement

Make focused edits that preserve established style and ownership. Avoid speculative abstractions, unrelated cleanup, and silent fallback behavior.

### Verify

Run the strongest relevant checks available without exceeding scope. At minimum, inspect the diff and run whitespace/error checks. For runtime work, add or update focused automated or manual validation appropriate to the repository.

### Report

Lead with the outcome. List changed files, checks and results, known limitations, assumptions that affect behavior, and any user-owned work that remains untouched. Never claim a check passed if it was not run.

## 10. Verification Standard

Verification is proportional to risk:

- **Documentation:** Review rendered structure where practical, validate paths and terminology, run `git diff --check`, and inspect the scoped diff.
- **Pure shared logic:** Exercise normal cases, boundaries, invalid inputs, and deterministic outputs.
- **Client presentation:** Check authoritative triggering, rapid repetition, cancellation, cleanup, reduced motion, and mobile layout.
- **Server gameplay/economy:** Check validation, rejection paths, rate limits, duplicate requests, finite bounds, and synchronization.
- **Persistence:** Check new player, returning player, migration, load failure, save failure, player removal, and shutdown behavior.
- **Cross-boundary changes:** Verify both producer and consumer and document the payload contract.

When automated Roblox execution is unavailable, create a precise manual test plan and say what remains unverified.

## 11. Documentation Contract

Durable documentation must separate:

- Current state from target state.
- Product rules from implementation detail.
- Confirmed behavior from inference.
- Contractual requirements from examples.
- Known limitations from future work.

Update the relevant document when changing a public interface, ownership boundary, data schema, remote payload, player-visible rule, or verification procedure. Do not rewrite historical evidence to make a new implementation appear original.

## 12. Stop and Escalate Conditions

Pause and request direction when:

- Two applicable requirements conflict and repository evidence cannot resolve them.
- A required choice would invent economy, monetization, persistence, privacy, or destructive behavior.
- The only path requires deleting or overwriting material user work.
- The task requires credentials, production access, external publication, or authority not granted.
- Verification reveals a safety or data-integrity risk outside the accepted scope.

Before escalating, exhaust safe read-only inspection and report the exact blocker, evidence, and smallest decisions or permissions needed.

## 13. Definition of Done

Work is done when:

- The requested outcome and observable acceptance criteria are satisfied.
- No prohibited or unrelated files were intentionally changed.
- Authority and ownership boundaries remain sound.
- Relevant success, failure, and boundary behavior has been checked.
- Documentation and validation artifacts agree with the implementation.
- The final diff is reviewed and `git diff --check` is clean.
- The report distinguishes completed, unverified, and deferred work.

Passing syntax checks alone is not completion when the feature contract, runtime integration, or player-visible outcome remains unverified.
