# Stuck task streak remediation v38

Trigger: repeated same-task streaks in recent window (`IQ-970` x3, `CQ-1014` x3, `CQ-1018` x3).

Findings (online):
- Temporal heartbeat timeout should be explicit so stalled long-running activity attempts fail fast and retry under policy.
- Temporal retry policy should be bounded (`maximumAttempts`) and paired with backoff to avoid no-progress retry loops.
- GitHub Actions should use `concurrency` groups and `cancel-in-progress` where appropriate to reduce duplicate stale runs.
- GitHub Actions jobs should set `timeout-minutes` to prevent hidden hangs.

Applied auditor guidance:
- Keep failure handling pattern-based: 5+ consecutive failures = stuck, single failures = info.
- Auto-escalate when same task repeats >=3 with no net progress, then diversify prompt scope.

References:
- https://docs.temporal.io/develop/typescript/failure-detection
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
