# Repeat-task streak guardrails v28

Trigger: inference `IQ-878` repeated 5x (recent60), `IQ-877` 3x; modernization `CQ-938` 3x.

Findings (online):
- Use capped retries + exponential backoff + jitter to prevent synchronized re-attempt storms.
- Keep strict retry budgets per task key (task_id + code fingerprint) to force escalation after N tries.
- Apply idempotency-aware retry policy: retry only transient failures; stop on deterministic test/code errors.
- Add reflection memory on failed attempts (error signature + diff summary + blocked invariant) before next attempt.

Actionable policy for builders:
- Hard cap: max 2 consecutive attempts on same task_id without net-new code path touched.
- On cap hit: auto-enqueue sibling task from same WS with different subsystem scope.
- Require one new failing test signature or changed touched-file set before retrying same task.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://arxiv.org/abs/2303.11366
