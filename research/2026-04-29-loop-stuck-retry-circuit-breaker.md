# Loop Stuck Pattern Research (2026-04-29)

Trigger: central DB shows repeated same-task streaks (>=3) for both builders.

Findings (online research):
- Use bounded retry budgets with exponential backoff and jitter; do not retry indefinitely.
- Add circuit-breaker states per task key (open/half-open/closed) so repeated failures pause task reuse.
- Separate transient errors from deterministic blockers; only transient classes are retryable.
- Use dead-letter/escalation queue after retry budget exhaustion.
- Add watchdog heartbeat timeout that forces task rebalance when loop appears alive but makes no forward progress.

Applied-to-loop recommendations:
- Key retries by `(agent, task_id)` and cap attempts in rolling windows (e.g. 3 attempts per 30m).
- On cap hit, auto-skip task and select next queue item; emit explicit `status=stuck` telemetry.
- Add anti-repeat guard: if same task selected 3 consecutive iterations with unchanged file set, force research/escalation path.
- Keep API timeout/tool-error classes as non-violations, but still counted toward transient retry budget.

Primary sources consulted:
- AWS Prescriptive Guidance: Retry with backoff pattern
- Baeldung resilience guide: backoff + jitter patterns
- Reliability guides covering circuit-breaker + graceful degradation in agent workflows
