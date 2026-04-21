# Stuck-pattern remediation (v32)

Trigger: repeated task IDs in recent 80 iterations (`IQ-920 x3`, `CQ-965 x3`).

Findings:
- Temporal recommends heartbeat + explicit activity timeouts to detect stalled workers quickly instead of silent long retries.
- GitHub Actions notifications can be configured to notify only on failed runs; keep `gh run list` + `gh run view --log-failed` as the terminal cross-check path.
- Add a local repetition circuit breaker in loop controllers: if same task repeats 3 times with no file-delta expansion, force one of: scope shrink, alternate subtask, or explicit research cooldown.

Concrete guardrails:
- Persist `task_id`, touched-file hash, and test-result hash in heartbeat metadata; if unchanged for 3 attempts, tag `stuck_pattern` and auto-diversify prompt.
- Enforce retry budget tiers: attempts 1-2 normal, attempt 3 mandatory strategy shift, attempt 4 escalate WARNING, 5+ CRITICAL stuck.
- Keep failure taxonomy strict: API timeout/network flake remains INFO unless coupled with zero-progress streak.

References:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs
- https://docs.github.com/en/subscriptions-and-notifications/how-tos/managing-github-actions-notifications
- https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html
