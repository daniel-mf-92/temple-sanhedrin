# Repeat-task streak guardrails (v8)

- Trigger: repeated task streaks detected (same task >=3 recent runs) despite healthy pass rates.
- Add per-attempt progress fingerprints (`task_id`, touched files hash, test hash) and auto-escalate when unchanged for 3 attempts.
- Enforce bounded retries with capped exponential backoff + jitter; avoid synchronized retry storms.
- Use heartbeat timeout + explicit stage heartbeats to fail stalled work quickly and re-queue diversified prompts.
- Alert on symptoms (no-progress retries, stale heartbeat, repeat-task streak) instead of raw error count.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://sre.google/sre-book/practical-alerting/
