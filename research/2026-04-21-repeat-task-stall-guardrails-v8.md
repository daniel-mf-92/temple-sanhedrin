# Repeat-task stall guardrails (v8)

Trigger: repeated task IDs >=3 in last 6h (CQ-877x4, CQ-810x3, IQ-839x3, IQ-842x3, IQ-844x3).

Findings (external):
- GitHub Actions concurrency can enforce one active run per branch/workflow key; use `concurrency.group` plus `cancel-in-progress` to avoid backlog churn and stale queued runs.
- LangGraph documents recursion-limit failures (`GRAPH_RECURSION_LIMIT`) as a loop symptom and recommends explicit stop conditions + step caps.
- OpenAI eval guidance emphasizes regression evals to catch prompt/tooling drift before repeated retries amplify failure loops.

Applied guidance for Temple loops:
- Keep "same task id" detection as a first-class signal and escalate after 3 repeats.
- Add/keep hard per-iteration step/time ceilings with explicit stop reason persisted to DB.
- Gate retries on delta evidence: if files/tests/notes unchanged across attempts, force task rotation or research.
- Track branch-level CI concurrency to prevent redundant runs hiding true failures.

References:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.langchain.com/oss/python/langgraph/errors/GRAPH_RECURSION_LIMIT
- https://developers.openai.com/cookbook/topic/evals
