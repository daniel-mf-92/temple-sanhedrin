# Stuck pattern: modernization CQ-1202 repeated

- Trigger: modernization latest task `CQ-1202` repeated 4 consecutive iterations.
- Finding 1: Temporal recommends explicit Activity timeout layering (`Start-To-Close` and/or `Schedule-To-Close`) plus `Heartbeat Timeout` so stalled work fails fast instead of silently repeating.
- Finding 2: Temporal retries are policy-driven; cap retries (`maximum_attempts`) and tune backoff to prevent endless same-task churn.
- Finding 3: GitHub Actions `concurrency` with `cancel-in-progress: true` prevents obsolete overlapping runs from compounding repetition.
- Finding 4: Kubernetes-style retry control (`backoffLimit`, `activeDeadlineSeconds`) reinforces bounded retry windows and forced escalation when no forward progress.
- Recommended guardrail: add progress fingerprint (`task_id`, changed-file hash, validation hash) and auto-escalate when fingerprint unchanged for 3+ attempts.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/develop/python/activities/timeouts
- https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://kubernetes.io/docs/concepts/workloads/controllers/job/
