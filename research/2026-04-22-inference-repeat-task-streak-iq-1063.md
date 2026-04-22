# Research: IQ-1063 repeat-task streak remediation

Trigger: inference task `IQ-1063` appeared repeatedly in recent iterations (streak pattern risk).

## Findings (actionable)
- Add explicit per-attempt progress tokens in loop heartbeat (task_id, stage, file-hash, validation-hash).
- Trip a deterministic circuit breaker when the same task repeats >=3 with unchanged progress token.
- On breaker, force prompt diversification: alternate test vector set, different code path focus, or split subtask.
- Bound retry behavior (max attempts/backoff) and fail fast on stalled runs instead of silent long retries.
- Record stuck-event metadata in central DB for automated trend alerts.

## Practical policy for this project
- Keep single failures as INFO.
- Escalate only repeated no-progress retries.
- Treat API/timeouts as infra noise unless paired with no-progress streaks.

## References
- https://docs.temporal.io/develop/typescript/failure-detection#heartbeat-an-activity
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/how-tos/monitor-workflows/use-workflow-run-logs
- https://sre.google/workbook/alerting-on-slos/
