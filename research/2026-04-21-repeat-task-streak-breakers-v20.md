# Repeat-task streak breakers (v20)

Trigger: modernization max consecutive task streak=3 (CQ-914, recent window), inference max consecutive task streak=3 (IQ-878, recent window).

Findings (actionable):
- Add a circuit-breaker gate for identical task IDs: after 3 consecutive attempts, force task decomposition into a narrower sub-task before next retry.
- Apply exponential backoff + jitter on repeated task retries to avoid synchronized retry storms and unproductive rapid loops.
- Require idempotent retry boundaries: retries should only re-run side-effect-safe validation paths unless a new patch delta exists.
- Add “observation budget” in loop prompts: each repeat must include at least one new failing assertion, changed file target, or test vector; otherwise auto-skip to backlog rotation.

Why this fits Temple loops:
- Reduces churn while preserving autonomous progress.
- Converts repeated retries into structured exploration instead of blind repetition.

References:
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
