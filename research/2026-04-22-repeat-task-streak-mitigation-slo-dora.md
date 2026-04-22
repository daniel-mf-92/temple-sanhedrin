# Repeat-task streak mitigation for builder loops

Trigger: modernization repeated `CQ-1162` 4x consecutively.

Findings (actionable):
- Use SLO-style alerting for *streak burn-rate* (fast + slow windows) so alerts trigger on persistent repetition, not single failures.
- Page on user-impact symptoms first (no code artifacts, no task progression), keep cause metrics for diagnosis.
- Track throughput + instability together (lead time/deploy frequency + failure/recovery/rework) to avoid local optimization loops.
- Enforce WIP cap per task ID in loop scheduler (e.g., max 2 consecutive runs unless new failing evidence appears).

Sources:
- https://sre.google/workbook/alerting-on-slos/
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes
- https://dora.dev/guides/dora-metrics/
