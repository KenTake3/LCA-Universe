# WP-02 — Recover NumberFormatter

## Mission

Implement the missing `NumberFormatter` ModuleScript required by the recovered LCA client.

This task must not alter game balance or gameplay behavior.

## Inputs

Read completely:

- `AGENTS.md`
- `docs/06_Current_System.md`
- `recovery/studio/MainGuiClient.client.lua`
- `prompts/codex/WP-02_NumberFormatter.md`

## Allowed Files

You may create or modify only:

- `src/shared/NumberFormatter.lua`
- `tests/manual/WP-02_NumberFormatter.md`
- `CHANGELOG.md`

Do not modify recovered files.
Do not modify Config.
Do not modify project mappings.

## Required Public API

Implement:

- `NumberFormatter.format(value)`
- `NumberFormatter.formatTime(seconds)`

## `format(value)` Requirements

The function must:

- Accept numbers and numeric strings.
- Return `"0"` for nil, unsupported types, NaN, and negative infinity.
- Handle positive infinity safely without returning invalid UI text.
- Preserve the negative sign for finite negative numbers.
- Use compact suffixes for large absolute values.
- Use stable deterministic formatting.
- Avoid unnecessary trailing zeroes.
- Never throw an error.

Use these suffixes initially:

- K = 1,000
- M = 1,000,000
- B = 1,000,000,000
- T = 1,000,000,000,000
- Qa = 1,000,000,000,000,000

For values beyond the supported suffix range, use a safe compact scientific representation.

Expected examples:

- `0` → `"0"`
- `12` → `"12"`
- `999` → `"999"`
- `1000` → `"1K"`
- `1250` → `"1.25K"`
- `1500000` → `"1.5M"`
- `-1250` → `"-1.25K"`

Do not display values such as:

- `nan`
- `inf`
- `1.#INF`

## `formatTime(seconds)` Requirements

The function must:

- Accept numbers and numeric strings.
- Clamp invalid or negative input to zero.
- Floor fractional seconds.
- Never throw an error.

Expected display:

- Under 60 seconds: `"45s"`
- Under 60 minutes: `"5m 03s"`
- Under 24 hours: `"2h 05m"`
- 24 hours or more: `"1d 02h"`

Do not include zero-value leading units.

## Compatibility

The recovered MainGuiClient uses this module for:

- Energy
- Gems
- Rebirths
- Luck
- Upgrade costs
- Rebirth costs
- Press rewards
- Playtime intervals
- Notification rewards

Keep output concise enough for mobile UI.

## Manual Test Document

Create `tests/manual/WP-02_NumberFormatter.md`.

Include tests for:

- nil
- booleans
- strings
- numeric strings
- negative values
- zero
- fractional values
- NaN
- positive infinity
- negative infinity
- every suffix boundary
- values beyond Qa
- every time-display boundary
- mobile readability

## Changelog

Add an Unreleased entry noting recovery of the shared number and time formatter.

## Completion Requirements

Before finishing:

1. Inspect the diff.
2. Run `rojo build`.
3. Confirm only allowed files changed.
4. Report edge-case decisions.
5. Do not commit or push.