# Repeat-task streak guardrails (v14)

Trigger: repeated task IDs in recent window (modernization: CQ-906/CQ-908/CQ-911/CQ-914 each seen >=3x; inference: IQ-844/IQ-861 each seen >=3x).

Findings:
- Use bounded retries with exponential backoff + jitter to avoid hot retry loops and synchronized retry storms.
- Use multi-window burn-rate style alerting to separate one-off noise from sustained failure conditions.
- Enforce explicit WIP limits per lane to reduce multitasking and force completion before pulling more work.

Applied Sanhedrin action:
- Keep single failures as INFO.
- Escalate only on sustained failure streaks (>=5) or repeat-task patterns without progress.
- When repeat-task>=3 appears, require guardrail reminder and track in research DB.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://sre.google/workbook/alerting-on-slos/
- https://www.atlassian.com/agile/kanban/wip-limits
