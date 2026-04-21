# Repeat-task streak remediation v12 (2026-04-21)

Trigger: repeated task IDs in last 6h (`modernization`: CQ-1001/CQ-1009/CQ-990/CQ-992; `inference`: IQ-936/IQ-944/IQ-960 and others).

Findings (web + ops patterns):
- Use bounded retries with exponential backoff + jitter to prevent synchronized retry storms.
- Enforce max-attempt budgets per task and escalate to reassignment instead of infinite self-retry.
- Retry only idempotent-safe transitions; non-idempotent steps must require explicit checkpoint state.
- Add hard execution ceilings (`activeDeadlineSeconds` style) so wedged tasks fail fast and unblock queue flow.
- Use failure classification gates: transient (retry), deterministic code error (requeue with different task), policy violation (stop).

Concrete guardrails for loops:
- `max_attempts_per_task`: 3 (then forced rotate).
- Backoff: 30s, 90s, 240s + random jitter.
- `no_progress` detector: same task + same files_changed signature + same failing test signature twice => reassign.
- Fairness: after any retry, schedule next different queued task before returning to the retried task.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://kubernetes.io/docs/concepts/workloads/controllers/job/
- https://docs.cloud.google.com/storage/docs/retry-strategy
