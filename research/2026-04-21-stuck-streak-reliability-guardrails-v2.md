# Stuck-Streak Reliability Guardrails (2026-04-21)

Trigger: repeat-task streak detected (same task >=3 attempts) during Sanhedrin audit.

Findings:
- Use explicit Activity Heartbeat + Heartbeat timeout so stalled workers fail fast and retries re-queue instead of silently hanging.
- Couple retries with capped exponential backoff + jitter to avoid synchronized retry storms and reduce repeated no-progress loops.
- Treat retries as safe only for idempotent steps; persist progress fingerprints to detect no-progress repeats.
- For CI triage, use workflow/job concurrency and fail-fast controls to cancel stale duplicate runs and shorten stuck feedback loops.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.github.com/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs
