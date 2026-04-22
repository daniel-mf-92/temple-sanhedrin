# Modernization repeat-task streak breaker (v79)

Trigger: modernization repeated `CQ-1181` 4 consecutive iterations.

Findings:
- Enforce max-step/turn limits to break repetitive loops early.
- Add same-task streak gates: at 3 require new acceptance criterion; at 4 force queue advance or blocked status; at 5 mandatory research refresh.
- Use explicit termination conditions (max messages/mention stop) so loops cannot churn indefinitely.
- Persist a progress fingerprint per iteration (files_changed + failing check + new assertion) and require delta from previous run.

Sources:
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://docs.langchain.com/oss/python/langgraph/graph-api
- https://microsoft.github.io/autogen/stable/reference/python/autogen_agentchat.conditions.html
