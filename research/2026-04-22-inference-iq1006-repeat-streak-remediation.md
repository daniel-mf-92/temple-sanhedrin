# Inference IQ-1006 repeat-task streak remediation (3x)

Trigger: inference task `IQ-1006` repeated 3 consecutive times in recent audit window.

## Findings
- Temporal: treat repeats as stalled-activity risk; enforce explicit `HeartbeatTimeout` plus bounded `Start-To-Close` / `Schedule-To-Close` so retries fail fast instead of silently looping.
- Temporal: retries should be bounded and tuned with retry policy, not unbounded defaults; use retry simulator to validate timeout/retry envelopes before rollout.
- GitHub Actions: use `concurrency` groups with `cancel-in-progress: true` for branch workflows so stale queued/running runs do not amplify repeat-task churn.
- Reliability pattern: apply circuit-breaker style guardrails after repeated no-progress attempts to force fallback path (smaller scope/reseeded task) instead of infinite retry churn.

## Practical guardrails for loops
- Persist per-attempt progress fingerprint (`task_id`, touched-file hash, test signature) and auto-escalate when unchanged for 3 attempts.
- On 3-attempt no-progress streak, trigger prompt diversification + narrower objective slice before next retry.
- Gate retries on at least one progress delta (file diff, test delta, or failing assertion delta); otherwise short-circuit and escalate.

## References
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/activity-retry-simulator
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://martinfowler.com/bliki/CircuitBreaker.html
