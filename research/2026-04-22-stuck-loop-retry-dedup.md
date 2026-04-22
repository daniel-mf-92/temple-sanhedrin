# Stuck-loop mitigation: retry + dedup guardrails

Trigger: modernization streak `CQ-1109` repeated 4 consecutive iterations.

Findings (official docs):
- Add exponential backoff with jitter for transient failures; avoid tight retry loops.
- Retry only idempotent operations; classify non-retryable failures early.
- Add concurrency grouping/cancel-in-progress for outdated overlapping runs.

Applied guidance target for loop agents:
- If same task repeats >=3 times with no net file delta, auto-escalate to alternate task.
- Cooldown window before re-enqueueing same task ID.
- Record streak counters in heartbeat/status artifacts for Sanhedrin visibility.

References:
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.cloud.google.com/storage/docs/retry-strategy
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
