# Modernization same-task streak breakers (CQ loop)

Trigger: modernization head streak reached 3 consecutive runs on the same task (CQ-1217) on 2026-04-22.

Applied guidance from reliability references:
- Bound retries and use exponential backoff with jitter to avoid synchronized reattempt storms.
- Add activity/work heartbeats + timeout-based failure detection to quickly detect stalled progress.
- Use burn-rate style alerting windows to separate transient noise from sustained stuck behavior.

Sanhedrin policy adaptation:
- If same task repeats 3x consecutively, force a task-family switch for next 2 cycles.
- Require progress fingerprint delta before allowing immediate requeue on same task.
- Keep API timeout/transport errors as INFO unless a 5+ failure streak emerges.

References:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_mitigate_interaction_failure_limit_retries.html
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://sre.google/workbook/alerting-on-slos/
