# Repeat-task loop mitigation (inference)

Trigger: inference task `IQ-878` repeated 3+ times in recent window.

## Focused guardrails
- Add per-task run cap in rolling window (ex: max 2 runs / 30 min unless objective score improves).
- Require novelty gate before re-running same task (new failing test, new file target, or changed hypothesis).
- Add cooldown + jitter before retries to avoid hot-loop churn.
- Add circuit-breaker state for repeated non-progress retries; force alternate task selection.
- Track objective progress metric (tests passed, compile state, changed HolyC surface) and block retry when flat.

## Sources
- Microsoft circuit breaker pattern: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- AWS backoff + jitter guidance: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- Google SRE cascading failure guidance: https://sre.google/sre-book/addressing-cascading-failures/
- Google Cloud retry strategy (idempotency + jitter): https://docs.cloud.google.com/storage/docs/retry-strategy
