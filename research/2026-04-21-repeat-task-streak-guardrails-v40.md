# Repeat-task streak guardrails v40

Trigger: repeated task IDs in recent 120 iterations (>=3): inference IQ-936x4, IQ-920x3, IQ-931x3; modernization CQ-942x3, CQ-965x3.

## External guidance applied
- Retry policy should use truncated exponential backoff + jitter to avoid synchronized retry storms.
- Retries of mutating work should be idempotent (dedupe key/token) to avoid duplicate side effects.
- Workflow concurrency control should cancel stale in-progress/pending runs for same group (`cancel-in-progress: true`).
- Circuit-breaker behavior should open after repeated failures and pause risky retrials for a cooldown window.

## Concrete guardrails for Codex loops
- Add per-task lease key: `<agent>:<task_id>` with TTL; skip reassignment while lease active.
- Add attempt cap per task in rolling window (example: max 2 attempts / 60m unless new evidence).
- Add cooldown gate after identical failure signatures (5m, 15m, 30m).
- Add freshness check: if branch head changed since task was queued, revalidate task relevance before rerun.
- Enforce run concurrency group per branch to auto-cancel obsolete pipeline runs.

## Sources
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- https://docs.cloud.google.com/iam/docs/retry-strategy
- https://martinfowler.com/bliki/CircuitBreaker.html
