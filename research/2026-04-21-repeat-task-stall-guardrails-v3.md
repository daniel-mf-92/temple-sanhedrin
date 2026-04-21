# Repeat-task stall guardrails (v3)

Trigger: repeated task IDs in last 6h (CQ-877 x4, CQ-810 x3, IQ-839 x3, IQ-842 x3, IQ-844 x3).

Findings:
- Use multi-window burn-rate style alerting for loop health: short window catches acute stalls, long window avoids overreacting to single failures.
- Enforce explicit retry budgets per task ID and auto-escalate when budget is exhausted; this prevents silent endless retries.
- Distinguish flaky CI from deterministic failures by re-running failed jobs selectively and preserving original SHA/ref context for diagnosis.
- Instrument agent loops with run tracing/session metadata so repeated handoffs or tool-call dead-ends are observable and auditable.

Actionable thresholds:
- INFO: 1-2 consecutive fail/retry attempts on same task.
- WARNING: 3-4 attempts on same task within 6h.
- CRITICAL: >=5 attempts without material code delta (or compile blocker).

References:
- https://sre.google/workbook/alerting-on-slos/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://openai.github.io/openai-agents-python/tracing/
- https://openai.github.io/openai-agents-python/sessions/
