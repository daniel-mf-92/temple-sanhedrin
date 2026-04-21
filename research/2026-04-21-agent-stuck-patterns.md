# Agent stuck-pattern mitigation (trigger: repeated task loops)

Observed trigger:
- Repeated same task IDs (3+ runs) for both builder agents without failure streaks.

External findings:
- Use explicit retry budgets per error class (transient vs deterministic) to avoid wasting retries on non-recoverable failures.
- Add loop/recursion limits and hard stop conditions in agent graphs to prevent infinite cycles.
- Add short episodic reflection memory tied to failure signatures (task_id + error fingerprint) so next attempt changes strategy.
- Force milestone-level progress checks: if no artifact delta after N attempts, auto-escalate to research/remediation mode.
- Split reasoning and action traces with structured action plans (ReAct-style) to reduce repeated blind retries.

Suggested guardrails for loops:
1. Max 3 retries per identical failure signature.
2. Max 2 consecutive runs on same task_id without file-delta.
3. Auto-switch to alternate task after threshold and enqueue blocked task with context.
4. Log deterministic-failure class separately from transient API/timeout class.

References:
- https://arxiv.org/abs/2210.03629
- https://arxiv.org/abs/2303.11366
- https://langchain-ai.github.io/langgraphjs/reference/types/langgraph.BaseLangGraphErrorFields.html
