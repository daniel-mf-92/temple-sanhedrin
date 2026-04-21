# Repeat-task loop guardrails v3 (2026-04-21)

Trigger: repeated task IDs still present (CQ-914 x6, CQ-877 x4, IQ-839/842/844/861 x3 in recent window).

## Findings
- Use WIP limits on active task IDs per agent lane; when a task hits repeat threshold, force rotation to a different task family.
- Track throughput + stability together (not only completions): task throughput plus recovery-from-failure time gives earlier stall detection.
- Enforce an error-budget style gate for retries: if repeat budget is exhausted, block further retries except unblock/fix tasks.
- Require explicit strategy delta on retries (new validation target, new file scope, or new test vector) before task can re-enter queue.
- Add stale-task timeout: any task reappearing N times without new code artifacts auto-demoted behind fresh tasks.

## Suggested Sanhedrin checks
- WARNING when same task_id appears >=3 times in last 50 iterations.
- CRITICAL when same task_id appears >=5 and codeish_rows delta is zero across those repeats.
- Auto-trigger research when repeat budget breached for either agent.

## Sources
- https://www.atlassian.com/agile/kanban/wip-limits
- https://dora.dev/guides/dora-metrics/
- https://sre.google/workbook/error-budget-policy/
