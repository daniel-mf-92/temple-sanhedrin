# Repeat-task streak guardrails v22

Trigger: modernization CQ-914 x6, inference IQ-878 x5 in recent 120 iterations.

Actions:
- Add per-task retry ceiling (max 2 immediate repeats), then force task rotation.
- Add exponential backoff + jitter before retrying identical task IDs.
- Track two-window burn-rate alerts for failure ratio (fast + slow windows) to cut noise.
- Use weighted round-robin task picking so one task ID cannot starve queue progress.
- Auto-open research mode when same task ID appears >=3 times without new files_changed set.

Refs:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/workbook/alerting-on-slos/
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
