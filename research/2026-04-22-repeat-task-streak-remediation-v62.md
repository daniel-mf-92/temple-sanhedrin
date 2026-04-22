# Repeat task streak remediation v62

- Date: 2026-04-22
- Trigger: inference same-task streak observed (`IQ-990` repeated 4 consecutive iterations)

## Findings (online)
- Temporal recommends explicit Activity timeout design (`Start-To-Close` and/or `Schedule-To-Close`) plus heartbeat timeout to fail stalled executions quickly instead of allowing long silent retries.
- Temporal heartbeat timeout should be paired with retry policy boundaries (max attempts/backoff) so worker stalls are detected and retried deterministically.
- GitHub Actions supports `concurrency` groups with `cancel-in-progress` to prevent stale in-flight runs and reduce repeated obsolete work.
- GitHub Actions has job execution limits (hosted jobs capped at 6h), so explicit shorter job `timeout-minutes` is advisable to fail fast and preserve throughput.
- Google SRE workbook recommends alerting on actionable SLO signals, supporting escalation only on sustained/repeated failure patterns to reduce noise and improve response quality.

## Source links
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/reference/limits
- https://sre.google/workbook/alerting-on-slos/
