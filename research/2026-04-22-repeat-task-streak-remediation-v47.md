# Repeat-task streak remediation v47 (2026-04-22)

Trigger: same-task repeat clusters >=3 in last 30 iterations (modernization: CQ-1009/CQ-1013/CQ-1014/CQ-1018; inference: IQ-970/IQ-980).

Findings:
- Temporal: explicit Start-To-Close/Schedule-To-Close plus heartbeat timeout shortens detection of stalled workers and prevents silent long retries.
- Temporal: keep retry policy bounded (max attempts/backoff) rather than relying on broad defaults when tasks can loop.
- GitHub Actions: use workflow/job concurrency groups with `cancel-in-progress: true` to stop stale duplicate runs.
- AWS reliability guidance: retries should use exponential backoff + jitter with max-attempt caps to prevent synchronized retry storms.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
