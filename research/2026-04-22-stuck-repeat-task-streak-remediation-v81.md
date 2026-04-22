# Stuck repeat-task streak remediation (v81)

- Trigger: modernization `CQ-1206` repeated 3 times; inference `IQ-1114` repeated 3 times at audit head.
- Temporal guidance: enforce explicit `heartbeat timeout` + `start-to-close`/`schedule-to-close` so stalled work fails fast instead of silent long retries.
- Temporal guidance: bound retries (`maximum_attempts`, backoff) and carry progress details in heartbeats/checkpoints to distinguish real progress from no-progress retries.
- GitHub Actions guidance: rerun failed jobs only (`gh run rerun --failed`) and keep failure triage tied to failed-step logs to avoid blind full reruns.
- Workflow guardrail: use matrix `fail-fast` intentionally; disable only when diagnostic parallelism is needed, then re-enable to reduce repeated noisy cycles.

## Sources
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
