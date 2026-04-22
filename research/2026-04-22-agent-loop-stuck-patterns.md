# Agent loop anti-stuck patterns (targeted)

Trigger: modernization max consecutive same task=4, inference=3 (latest 50 iterations), despite PASS outcomes.

Findings (actionable for loop owners):
- Add explicit step-budget guardrails per iteration and hard stop reasons; recursion/step caps are standard for preventing silent loops.
- Track progress deltas per run (task_id, touched code file count, test signal) and classify "same task + no delta" as warning after 3 repeats.
- Add trace-level evals on loop behavior (not just code/tests) so repeated-task patterns fail fast in CI.
- Keep per-agent "stuck heuristics" in telemetry: consecutive same task, consecutive non-code outputs, and repeated rollback/no-op commits.
- Escalation policy: at repeat>=3 trigger automatic research/strategy prompt; at repeat>=5 force task rotation.

References:
- https://developers.openai.com/api/docs/guides/agent-evals
- https://developers.openai.com/api/docs/guides/evaluation-best-practices
- https://developers.openai.com/blog/eval-skills
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://reference.langchain.com/python/langgraph/errors/GraphRecursionError
