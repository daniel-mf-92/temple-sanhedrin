# IQ-1135 repeat-task loop guardrails

Trigger: inference task `IQ-1135` repeated 3 times in last 10 iterations.

## Findings (actionable)
- Add a **task-streak circuit breaker**: if same task appears 3 times, force alternate queue pick for next run.
- Add **bounded retries with jitter** for transient tooling/API failures; avoid synchronized retry storms.
- Add **idempotency key per iteration attempt** so retried writes do not duplicate side effects.
- Split retry policy by error class: transient errors retry; deterministic/test failures escalate immediately.
- Add **cooldown window** after repeated same-task passes to require a distinct task before returning.

## References
- AWS Builders Library — Timeouts, retries and backoff with jitter
- Azure Architecture Center — Retry Storm antipattern + Circuit Breaker pattern
- Stripe API docs — Idempotent requests behavior
