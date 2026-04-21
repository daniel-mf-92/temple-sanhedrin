# Repeat-task streak remediation v30 (CQ-942 / IQ-878)

Trigger: 3x same-task streak detected (modernization: CQ-942, inference: IQ-878).

## Findings (online)
- Add hard loop bounds (`max_iterations` / `max_turns`) so retries cannot run indefinitely.
- Use explicit termination conditions (keyword/stop state + timeout/token/turn caps).
- Enforce bounded retry policy for transient failures only (`max_attempts`, backoff, jitter).
- On repeated same-task streak, force planner re-route: switch task class or inject fresh task candidates.
- Persist per-task outcome ledger and block re-selection after N identical pass/fail cycles without new code deltas.

## Sources
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://docs.langchain.com/oss/javascript/langgraph/thinking-in-langgraph
- https://microsoft.github.io/autogen/0.4.5//reference/python/autogen_agentchat.teams.html
- https://microsoft.github.io/autogen/0.2/docs/tutorial/chat-termination/
- https://addyosmani.com/blog/self-improving-agents/
