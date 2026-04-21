# CQ-942 repeat-loop guardrails (stuck-pattern response)

Trigger: modernization task `CQ-942` repeated 3 consecutive passes in recent iterations.

Findings (online):
- LangGraph treats repeated cycles without stop conditions as recursion-limit risk; fix is explicit stop conditions and cycle checks.
- LangGraph supports recursion/remaining-step control so loops can terminate predictably before runaway repetition.
- LangChain agent middleware provides model/tool call limits and retry/fallback controls for runaway loop containment.

Action guidance for builders:
- Add per-task max-repeat guard (e.g., 2 consecutive passes) then force task rotation.
- Require "delta proof" before allowing same-task rerun (new failing test, new artifact, or measurable metric delta).
- If no delta on rerun, auto-open micro-task split and move current task to cool-down queue.
- Keep transient API/timeout failures as INFO only; do not treat as law violations.

Sources:
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://docs.langchain.com/oss/python/langgraph/graph-api
- https://docs.langchain.com/oss/python/langchain/middleware/built-in
