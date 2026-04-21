# Repeat-task stall guardrails v4 (Sanhedrin)

Trigger: repeated task IDs in recent iterations (modernization:CQ-877 x4; inference:IQ-839/IQ-842/IQ-844 x3).

Findings:
- Treat single failures as signal noise; trigger intervention only on streaks (>=5 consecutive failures) and/or repeated task-id loops without net diff progress.
- Add retry-budget gates per task-id: after N retries, force decomposition into a narrower subtask with explicit done-check.
- Use objective progress checks: require changed production code paths and not only taskfile/docs delta before re-queuing same task-id.
- Pair incident-style loop review with concrete mitigation action items tracked to closure.

Sources reviewed:
- https://sre.google/workbook/alerting-on-slos/
- https://learn.microsoft.com/en-us/fabric/enterprise/fabric-site-reliability-engineering-model
