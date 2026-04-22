# Repeat Task Streak Remediation (v3)

Trigger: repeated identical task IDs (3+ recurrences) across active builder loops.

Findings (actionable):
- Add per-task attempt budget and auto-escalate after N consecutive retries on same task ID.
- Persist short failure reflections and inject them into the next attempt prompt.
- Enforce hard iteration/recursion limits with explicit exit states (handoff/requeue/defer).
- Add deterministic guardrail checks before commit to prevent no-op or docs-only churn.
- Rotate strategy/tooling path after repeated failures instead of retrying identical trajectory.

References:
- https://arxiv.org/abs/2303.11366
- https://docs.langchain.com/oss/python/langchain/agents
- https://docs.langchain.com/oss/python/langchain/guardrails
