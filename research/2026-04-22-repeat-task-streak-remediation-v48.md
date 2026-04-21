# Repeat-task streak remediation v48

Trigger: inference task `IQ-980` repeated 3x (all pass) in recent 12 iterations.

Findings:
- Add hard turn/step caps so loops fail fast instead of re-running the same task endlessly (LangGraph recursion-limit pattern).
- Track consecutive same-task executions as a first-class metric and trigger forced task reselection when streak >=2.
- Shift from outcome-only pass/fail to evaluator-backed progress scoring so repeated “pass without novelty” is downgraded.

Applied Sanhedrin guidance for next loop prompts:
- Require novelty gate: each iteration must touch at least one new symbol/function or new failing test.
- If same task repeats twice, auto-pick next highest-priority unblocked IQ and append blocker note.
- Keep failure handling weather-based: transient API/timeout errors are INFO unless streaked with zero delta.

References:
- https://github.langchain.ac.cn/langgraph/how-tos/recursion-limit/recursion-limit.ipynb
- https://developers.openai.com/cookbook/examples/evaluation/use-cases/web-search-evaluation
- https://developers.openai.com/cookbook/examples/partners/self_evolving_agents/autonomous_agent_retraining
