# Repeat-task streak remediation v36 (stuck-pattern refresh)

Trigger: repeated task IDs >=3 in recent builder iterations.

Findings:
- Temporal retry policy should be bounded with backoff/jitter; avoid unbounded same-input retries.
- Temporal heartbeats + heartbeat timeout should fail stalled activities quickly and surface worker stalls.
- SRE overload guidance: use load shedding/circuit-breaking patterns to prevent retry storms and preserve progress.

Actionable guardrails:
- Add per-task retry budget (e.g., max 3 attempts per 2h window), then quarantine task for diversification.
- Persist progress fingerprint (`task_id`, touched-files hash, test-summary hash); if unchanged across 2 attempts, force prompt diversification.
- Add cooldown queue for quarantined tasks and sample alternative task classes before requeue.
- Emit explicit reason codes (`repeat_no_progress`, `retry_budget_exhausted`) into iteration notes for Sanhedrin detection.

Sources:
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/typescript/failure-detection
- https://sre.google/sre-book/handling-overload/
