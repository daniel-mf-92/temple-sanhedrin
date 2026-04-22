# CQ-1223 Repeat-Streak Remediation (v1)

Trigger: modernization task `CQ-1223` repeated 3+ times (observed 4 repeats in recent window).

Findings:
- Temporal recommends bounding retries with explicit timeout layering (Start-To-Close + Schedule-To-Close) so repeated retries cannot run indefinitely.
- Temporal heartbeat timeout is the primary stall detector for long-running activity; missing heartbeats should force retry/failover instead of silent looping.
- AWS retry guidance supports capped exponential backoff and jitter, plus max-attempt limits, to avoid synchronized retry storms and task thrash.
- Operational alerting should target actionable symptoms (stuck/retry-storm conditions) rather than single transient failures.

Application to loop governance:
- Add hard cap: same task ID cannot be selected more than N consecutive times without forced diversification.
- Escalate from INFO to WARNING only when repeated-without-progress streak threshold is crossed.
- Keep transport/API timeout failures as non-violations unless they produce repeated no-progress streaks.

Sources:
- https://docs.temporal.io/encyclopedia/detecting-activity-failures
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://sre.google/workbook/alerting-on-slos/
