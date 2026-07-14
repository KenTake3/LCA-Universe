# WP-02 NumberFormatter Manual Test

Test the ModuleScript mapped from `src/shared/NumberFormatter.lua` to `ReplicatedStorage/LCA_Shared/NumberFormatter` in both client and server contexts.

## API and invalid inputs

- [ ] `format` and `formatTime` exist and are functions.
- [ ] `format(nil) == "0"`.
- [ ] `format(true) == "0"` and `format(false) == "0"`.
- [ ] `format({}) == "0"`.
- [ ] `format("not a number") == "0"`.
- [ ] `format("1250") == "1.25K"`.
- [ ] `format(" 1500000 ") == "1.5M"`.
- [ ] `format(0 / 0) == "0"`.
- [ ] `format(math.huge) == "0"`.
- [ ] `format(-math.huge) == "0"`.
- [ ] No result contains `nan`, `inf`, or `1.#INF` in any letter case.

## Number formatting

- [ ] `format(0) == "0"`.
- [ ] `format(12) == "12"`.
- [ ] `format(12.5) == "12.5"`.
- [ ] `format(12.345) == "12.35"`.
- [ ] `format(999) == "999"`.
- [ ] `format(1000) == "1K"`.
- [ ] `format(1250) == "1.25K"`.
- [ ] `format(1500000) == "1.5M"`.
- [ ] `format(-1250) == "-1.25K"`.
- [ ] `format(-0.5) == "-0.5"`.
- [ ] `format(-0.001) == "-1e-3"` and does not collapse to `"-0"`.
- [ ] Finite negative values retain exactly one leading minus sign.
- [ ] Formatted decimals have no unnecessary trailing zeroes.

## Suffix boundaries

For each boundary, verify the value immediately below, exactly at, and immediately above it:

- [ ] K: `1,000`.
- [ ] M: `1,000,000`.
- [ ] B: `1,000,000,000`.
- [ ] T: `1,000,000,000,000`.
- [ ] Qa: `1,000,000,000,000,000`.
- [ ] Values that round into the next boundary are promoted, for example `format(999999) == "1M"`.
- [ ] Repeated calls with the same input produce identical output.

## Beyond Qa

- [ ] `format(1e18) == "1e18"`.
- [ ] `format(1.25e20) == "1.25e20"`.
- [ ] `format(-1.25e20) == "-1.25e20"`.
- [ ] Very large finite values remain concise and never contain invalid numeric text.

## Time formatting

- [ ] `formatTime(nil) == "0s"`.
- [ ] `formatTime(true) == "0s"`.
- [ ] `formatTime("invalid") == "0s"`.
- [ ] `formatTime(-1) == "0s"`.
- [ ] `formatTime(0 / 0) == "0s"`.
- [ ] `formatTime(math.huge) == "0s"` and `formatTime(-math.huge) == "0s"`.
- [ ] `formatTime(0) == "0s"`.
- [ ] `formatTime(45.9) == "45s"`.
- [ ] `formatTime("45.9") == "45s"`.
- [ ] `formatTime(59) == "59s"`.
- [ ] `formatTime(60) == "1m 00s"`.
- [ ] `formatTime(303) == "5m 03s"`.
- [ ] `formatTime(3599) == "59m 59s"`.
- [ ] `formatTime(3600) == "1h 00m"`.
- [ ] `formatTime(7500) == "2h 05m"`.
- [ ] `formatTime(86399) == "23h 59m"`.
- [ ] `formatTime(86400) == "1d 00h"`.
- [ ] `formatTime(93600) == "1d 02h"`.
- [ ] Durations over one day do not wrap their day count.
- [ ] Zero-value leading units are omitted.

## Mobile readability

- [ ] Energy, Gems, Rebirths, Luck, upgrade costs, rebirth costs, and reward labels fit their existing UI containers at common values.
- [ ] K/M/B/T/Qa and scientific outputs remain understandable at the existing text sizes.
- [ ] Playtime and daily countdown strings remain concise on a narrow mobile viewport.
- [ ] Negative diagnostic values do not disrupt label layout.

## Studio integration prerequisites

- [ ] Rojo maps the file to `ReplicatedStorage/LCA_Shared/NumberFormatter` without changing `default.project.json`.
- [ ] The recovered client’s `ReplicatedStorage.Shared.NumberFormatter` require path is bridged or updated in a separately authorized integration task.
- [ ] The module can be required from a LocalScript without yielding or throwing.
