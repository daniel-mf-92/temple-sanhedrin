# Repeat-task reliability controls refresh v7 (2026-04-21)

Trigger: repeated task IDs (>=3 in last 60 iterations) for both builders.

## External findings (quick)
- AWS Builders’ Library: retries must use bounded exponential backoff + jitter to prevent retry storms.
- Azure Circuit Breaker pattern: open breaker after failure threshold and force cooldown before reattempt.
- Google SRE error-budget policy: when reliability degrades, pause normal change velocity and prioritize recovery.

## Sanhedrin actions for loop policy
- Add per-task retry budget (max 2 immediate retries), then force task rotation.
- Add cooldown window after repeated same-task failures to prevent hot looping.
- Gate re-entry to same task on objective progress proof (new code diff + changed failing assertion/error).
- Escalate to research automatically when same task appears 3+ times in 60 iterations.
- Treat API/network timeout noise as informational unless accompanied by compile/test regressions.

## Sources
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/workbook/error-budget-policy/
