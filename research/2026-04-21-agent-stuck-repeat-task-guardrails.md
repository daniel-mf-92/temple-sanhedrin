# Stuck-pattern guardrails for repeat-task loops

Trigger: same task repeated 3+ times without forward movement (`modernization:CQ-942`).

Findings:
- Add explicit stop conditions in agent prompts: exit task after N failed/unchanged attempts and escalate.
- Persist execution checkpoints and retry metadata so resumed loops avoid redoing identical work.
- Use bounded retry policies with fallback routing instead of open-ended retries.
- Enforce GitHub Actions concurrency with `cancel-in-progress: true` for loop branches to avoid stale duplicate runs.

References:
- https://docs.langchain.com/oss/python/langgraph/durable-execution
- https://reference.langchain.com/python/langgraph/types/RetryPolicy
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://platform.openai.com/docs/guides/prompt-engineering
