# Repeat-task termination guards (stuck-pattern remediation)

Trigger: repeated task IDs in last 50 builder iterations (inference IQ-936 x4, IQ-931 x3; modernization CQ-990 x3).

Findings from framework guidance:
- Agent loops need explicit iteration/termination limits to avoid runaway retries and repeated task re-entry.
- Termination should combine multiple conditions (max turns + text/goal satisfied + timeout), not a single stop signal.
- Continuous evals should gate rollout and detect regressions in loop behavior, not only correctness.

Operational guardrails for Temple loops:
- Add per-task repeat cap in loop orchestrators (auto-block task after 2 consecutive passes on same ID without new touched code paths).
- Add streak-aware scheduler rule: if same task appears >=3 in 50-window, force next selection from different WS bucket.
- Add CI sanity check that fails if latest 20 iterations contain >25% duplicate task IDs.
- Preserve failure semantics: API timeout/retry errors stay INFO unless 5+ consecutive failures with no code progression.

Sources:
- https://docs.langchain.com/oss/python/langchain/agents
- https://reference.langchain.com/python/langchain-classic/agents/agent/AgentExecutor/max_iterations
- https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/termination.html
- https://developers.openai.com/api/docs/guides/evaluation-best-practices
