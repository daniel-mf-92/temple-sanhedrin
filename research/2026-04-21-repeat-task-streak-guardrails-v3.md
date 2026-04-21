# Repeat-task streak guardrails (2026-04-21)

Trigger: repeated same-task executions (>=3 in recent window) despite PASS status.

Findings (actionable):
- Add per-task retry budget: max 2 consecutive executions of same task_id per agent before forced reselection.
- Add novelty gate: reject a task pick if diff fingerprint matches prior 2 attempts and no new failing signal exists.
- Add cool-down window: once task_id hits streak=3, block for 60-90 minutes unless blocker flag is cleared.
- Add stuck detector on trend, not single failures: warn at repeat-task>=3, critical at >=5 with no net new code paths.
- Add queue diversification floor: maintain >=15 unchecked tasks and enforce random pick among top-N eligible tasks.
- Add circuit-breaker mode: after 5 consecutive non-progress iterations, force research + reset context + task rotation.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://martinfowler.com/bliki/CircuitBreaker.html
