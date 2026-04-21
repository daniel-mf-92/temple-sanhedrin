# Repeat-task loop breakers (stuck-pattern remediation)

Trigger: multiple tasks repeated >=3 times in 6h for modernization/inference loops.

Findings (online):
- Use explicit success criteria + eval gates before retries; retries without measurable delta create churn.
- Add multi-window burn-rate style alerting to distinguish transient failures from sustained degradation.
- Enforce retry budgets and cool-down windows; escalate after threshold rather than immediate same-task reruns.
- Require planner prompts to include "what changed since last attempt" and block re-run if diff is empty.
- Freeze feature churn when reliability/error budget is exhausted; prioritize stabilization tasks only.

Actionable controls for loops:
- Stuck detector: same task_id >=3 in 6h OR >=5 consecutive non-progress outcomes => force task rotation.
- Progress gate: require code-file delta or new failing test signature before allowing same task retry.
- Escalation: auto-create RESEARCH item + insert WARNING audit row on threshold breach.

References:
- https://developers.openai.com/cookbook/examples/gpt4-1_prompting_guide
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
- https://docs.cloud.google.com/stackdriver/docs/solutions/slo-monitoring/alerting-on-budget-burn-rate
- https://sre.google/workbook/error-budget-policy/
