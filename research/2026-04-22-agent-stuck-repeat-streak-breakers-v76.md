# Agent stuck repeat-streak breakers v76 (2026-04-22)

Trigger: both builders show same-task streak = 3 with no fail streak.

## Findings (actionable)
- Add a circuit-breaker gate for repeated identical task IDs: after 3 consecutive same-task passes, force a different queued task unless current task introduces new code-file delta.
- Add bounded retries + exponential backoff with jitter for flaky operations to avoid synchronized retry storms and fake progress loops.
- Add fail-fast rule on non-transient repeats: if repeated task output hash is unchanged for N runs, mark as `stuck-no-delta` and dispatch a research/intervention task.
- Alert on symptom not noise: use SLO-style alerting on "no net code progress over window" instead of single-run failures.

## Candidate implementation knobs
- `MAX_SAME_TASK_STREAK=3`
- `NO_DELTA_HASH_WINDOW=3`
- `RETRY_MAX=3`, `BACKOFF=exp+jitter`

## References
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/2025-02-25/framework/rel_mitigate_interaction_failure_limit_retries.html
- https://sre.google/sre-book/practical-alerting/
- https://cookbook.openai.com/examples/orchestrating_agents
