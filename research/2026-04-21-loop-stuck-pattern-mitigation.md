# Loop Stuck Pattern Mitigation (2026-04-21)

Trigger: repeated same-task IDs (CQ-914 x6, IQ-878 x5 in recent window).

Findings:
- Prefer simple composable agent loops over framework-heavy orchestration; add explicit phase boundaries (plan/execute/verify) and stop rules.
- Add eval gates tied to task IDs: require measurable delta before reusing the same task ID again.
- Add "no-progress" detector: if N consecutive runs touch same objective without new code-surface expansion, force task rotation.
- Use reliability-style burn-rate alerts for failure clusters, but ignore isolated transient/tool/API failures.
- Keep retry budget separate from law-violation budget to avoid false CRITICAL escalation.

Sources:
- https://www.anthropic.com/research/building-effective-agents
- https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- https://sre.google/workbook/alerting-on-slos/
- https://developers.openai.com/cookbook/examples/partners/eval_driven_system_design/receipt_inspection
