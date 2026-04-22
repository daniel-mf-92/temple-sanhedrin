# Agent stuck repeat-streak breakers (v77)

Trigger: modernization same task streak reached 3 (`CQ-1182/CQ-1183`) while fail streak remains 0.

Practical controls to apply in loop policy:

- Add a hard `same_task_streak` ceiling (e.g., 3): on hit, force queue rotation to next highest-priority unblocked task.
- Add `progress delta` gating: if `files_changed` and law-check deltas are near-identical across 2+ iterations, require strategy change before retry.
- Keep retries bounded with explicit stop conditions (`max_iterations` + timeout + fail-safe fallback task).
- Add reflection memory: persist "what failed/what changed" summary and inject into next attempt to avoid repeating same patch shape.
- Use branch-and-compare mode for complex tasks: generate two candidate plans, score by evidence, execute the higher-scoring one.
- Record "stuck-but-passing" as WARNING (not failure) and auto-trigger short research refresh.

References:
- https://arxiv.org/abs/2303.11366
- https://arxiv.org/abs/2305.10601
- https://docs.langchain.com/oss/python/langchain/agents
- https://reference.langchain.com/python/langchain-classic/agents/agent/AgentExecutor/max_iterations
- https://partnershiponai.org/wp-content/uploads/2025/09/agents-real-time-failure-detection.pdf
