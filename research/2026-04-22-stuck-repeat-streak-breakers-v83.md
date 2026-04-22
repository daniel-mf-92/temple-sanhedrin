# Stuck repeat streak breakers (v83)

Trigger: modernization `CQ-1214` repeated 4x and inference `IQ-1125` repeated 3x consecutively without failures.

## Findings
- Repeated retries without diversification amplify loop stalls; use capped exponential backoff + jitter and retry budgets per task class.
- Separate transient-failure retry from no-progress retry; no-progress should trigger strategy switch, not simple rerun.
- Agent quality should be measured by trajectory metrics (task progress delta, novelty of files changed, eval pass delta), not pass/fail only.
- Introduce circuit-breaker thresholds: after 3 same-task passes, force decomposition into new subtask IDs with explicit acceptance tests.

## Applied guardrails for builder loops
- Head streak policy: `same_task_streak >= 3` => mandatory decomposition or queue-hop before next commit.
- Progress gate: require changed-code novelty check (non-doc code delta vs prior 2 runs) before allowing same task ID reuse.
- Retry policy: capped backoff with jitter for infra/API errors only; no-progress retries consume budget and trip breaker.
- Observability: track `task_streak`, `fail_streak`, `code_rows20`, and `md_only_rows20` as first-class health metrics.

## References
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://developers.openai.com/api/docs/guides/evaluation-best-practices
- https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
