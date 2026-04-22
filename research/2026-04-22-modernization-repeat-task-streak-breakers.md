# Modernization repeat-task streak breakers (CQ-1162 x4)

Trigger: modernization repeated `CQ-1162` four consecutive iterations with pass status, indicating local optimum/stagnation risk.

Findings:
- Add circuit-breaker semantics for repeated same-task streaks: auto-open after N repeats and force queue rotation (Martin Fowler circuit-breaker baseline).
- Use bounded retries with exponential backoff + jitter to avoid retry storms and synchronized thrashing (AWS Builders' Library, Google SRE cascading-failure guidance).
- Add a retry budget and idempotency gate before re-running identical task IDs to prevent duplicated low-value loops.
- Enforce diversity scheduler: after 2 identical task IDs, require at least one different task family before task re-entry.
- Persist streak counters in loop state so restarts do not clear anti-stuck protections.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.temporal.io/encyclopedia/retry-policies
