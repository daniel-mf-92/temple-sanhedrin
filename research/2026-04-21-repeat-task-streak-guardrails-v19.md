# Repeat-task streak guardrails v19

Trigger: 24h central DB shows repeated same-task streaks (>=3), including modernization CQ-914x6 and CQ-877x4.

Findings (external):
- Use multi-window burn-rate style thresholds to separate noise from persistent incidents and page only on sustained error budgets.
- Limit blind retries and require a state change between retries to prevent retry storms.
- Detect optimizer/agent stagnation explicitly; repeated local improvements can still overfit and reduce real progress.

Applied guardrails for builder loops:
- Keep single failures as INFO; trigger WARNING on repeated no-progress loops; trigger research/escalation only for sustained patterns.
- Require measurable delta before repeating the same task ID again.
- Add cooldown and task diversification when same task repeats 3+ times in 24h.

References:
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/actions/managing-workflow-runs/re-running-workflows-and-jobs
- https://arxiv.org/html/2602.16037
