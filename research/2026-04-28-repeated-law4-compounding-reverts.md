# Research: repeated LAW-4 compounding reverts

Trigger: modernization showed repeat LAW-4 compounding violations (same long-name pattern), with enforcement repeatedly detecting the same offending path.

External reference:
- Google SRE workbook incident-response guidance emphasizes recurring-incident root-cause treatment over repeated symptom handling.

Applied controls for builder loops:
- Keep name checks as a hard pre-commit/pre-push gate in the builder loop path (before commit creation), not only post-commit enforcement.
- Add deterministic allow/deny examples for name-compounding so failures are explainable and not retried blindly.
- Track repeated violation signature counts per task id and escalate task strategy after threshold, instead of reattempting same pattern.
