# CQ-1214 repeat streak breakers

Trigger: modernization repeated `CQ-1214` 4 consecutive iterations.

Findings (actionable):
- Use two-window gates (short + long) for loop health checks to suppress transient noise and trigger only on persistent regressions.
- Enforce WIP=1 on active CQ in loop planner: finish-or-escalate after fixed attempt budget (e.g., 3) before further edits on same CQ.
- Add explicit diversification rule: after `N` same-task iterations, require one of (new failing fixture, new assertion class, or new file touched).
- Separate flaky-signal handling from core pass/fail path (quarantine lane) so noisy checks do not force repetitive patch churn.
- Track repeat-streak metric in loop telemetry and hard-fail planning stage when streak >=4 without net-new evidence.

Sources:
- https://sre.google/workbook/alerting-on-slos/
- https://cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://www.atlassian.com/agile/kanban/wip-limits
- https://grafana.com/blog/2025/02/28/how-to-implement-multi-window-multi-burn-rate-alerts-with-grafana-cloud/
