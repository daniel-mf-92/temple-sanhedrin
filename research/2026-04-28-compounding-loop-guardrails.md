# Compounding-name loop guardrails (2026-04-28)

## Trigger
`audits/enforcement.log` shows repeated LAW-4 detections for the same long compounded filename in TempleOS commits, including repeated `DETECT` after cleanup.

## Findings (external references)
- Add a pre-execution stop-rule that blocks any proposed identifier/file name crossing policy limits before code generation starts.
- Add repeat-attempt detection keyed by normalized violation signature (`repo + law + path + sha`); if seen 3+ times, force task handoff or alternate queue item instead of retrying same shape.
- Add circuit-breaker behavior for repeated tool/action retries: bounded attempts, cooldown window, escalation payload.
- Keep append-only persistent guardrails loaded each iteration so prior violations become hard constraints, not soft reminders.
- Track loop metrics explicitly: same-task streak, same-violation streak, and “no-net-progress” count; route to research path when thresholds hit.

## Concrete controls to apply in loops
1. Preflight check in both builder loops:
   - Run `bash automation/check-no-compound-names.sh HEAD` before commit and also against staged paths before test/commit.
2. Violation signature memory:
   - Persist latest 20 violation signatures in loop-local state file under `automation/logs/`.
3. Retry gate:
   - If same signature appears 3 times in last 5 iterations, mark iteration `warning`, skip current queue item, and write research trigger note.
4. Queue pivot rule:
   - For naming-policy failures, do not regenerate same target name with suffixes; require rename from canonical short token map.
5. Observability:
   - Include `same_violation_streak` in audit JSONL notes so Sanhedrin can detect systemic looping early.

## Expected effect
These controls reduce repeated LAW-4 detections and stop the loop from reattempting identical invalid naming shapes.
