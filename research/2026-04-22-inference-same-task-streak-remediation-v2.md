# Research: inference same-task streak remediation (IQ-1055)

Trigger: consecutive same task streak reached 3 for `inference` agent with no failure streak.

Findings (online):
- Temporal guidance: set explicit activity `heartbeatTimeout` plus bounded `startToCloseTimeout` to fail stalled attempts quickly instead of silent long hangs.
- Temporal retry guidance: use capped retries and backoff, then surface terminal state for operator action instead of infinite same-task churn.
- Reliability pattern: include idempotency keys/checkpoints in each attempt so retries can detect no-progress loops and branch strategy.
- Queue fairness pattern: add per-task cooldown/jitter and alternate task selection after N repeats to prevent starvation.

Applied recommendation for Sanhedrin policy:
- Keep single failures informational; escalate only on repeat-pattern streaks.
- Treat same-task streak >=3 as WARNING and require diversification/requeue hints.
- Treat same-task streak >=5 with no artifact delta as STUCK and trigger deeper research + stronger circuit-breaker recommendation.

Sources:
- https://docs.temporal.io/develop/typescript/failure-detection
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/activity-definition
- https://sre.google/sre-book/addressing-cascading-failures/
