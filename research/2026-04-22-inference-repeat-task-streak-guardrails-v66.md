# Inference same-task streak guardrails (v66)

Trigger: inference repeated `IQ-1055` for 3 consecutive iterations.

Findings:
- Temporal retries are default for Activities and can become effectively unbounded unless `maximumAttempts` and bounded timeouts are set.
- Use explicit Activity timeout layering (`Start-To-Close` and/or `Schedule-To-Close`) with retry policy to fail stalled work quickly.
- Add task-progress heartbeat payload (`task_id`, changed-files hash, test-result hash) and branch prompt strategy when the payload is unchanged for >=3 attempts.
- Keep retry backoff with jitter and capped attempts to avoid synchronized retry loops and no-progress churn.

Applied recommendation for Sanhedrin policy:
- Escalate to WARNING when same task streak >=3 with unchanged code fingerprint.
- Auto-trigger research + diversification hints when streak >=3 even if status is `pass`.

References:
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/activity-execution
- https://docs.temporal.io/encyclopedia/detecting-application-failures
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
