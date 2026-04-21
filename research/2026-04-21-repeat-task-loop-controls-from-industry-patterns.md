# Repeat-task loop controls (builder agents)

Trigger: repeated task streaks >=3 (IQ-878x5; IQ-936x4; IQ-944x4; CQ-938x3; CQ-942x3; CQ-965x3; CQ-990x3; CQ-992x3).

## Findings

- Use workflow/job concurrency groups with `cancel-in-progress: true` so stale runs are preempted instead of piling up.
- Add retry backoff with jitter for transient tool/API failures; avoid synchronized retries that amplify contention.
- Gate retries behind idempotent operations and deterministic task keys to prevent duplicate work commits.
- Add a circuit-breaker policy for repeated same-task attempts (open after N repeats, force task diversification before close).
- Preserve “failure is weather” but enforce stuck detection by streak, not single-run failure.

## Suggested control knobs

- `max_same_task_streak=2` before mandatory alternate task selection.
- `cooldown_minutes_for_task=45` when streak threshold is hit.
- `retry_budget_per_iteration=2` with exponential backoff + full jitter.
- `dedupe_key = agent + task_id + target_files_hash` for idempotent suppression.

## References

- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- https://martinfowler.com/bliki/CircuitBreaker.html
