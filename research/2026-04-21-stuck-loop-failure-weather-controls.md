# Failure-weather controls for stuck task loops

Trigger: repeated task IDs in recent window (modernization: CQ-914 x6, inference: IQ-878 x5, IQ-944 x4, IQ-936 x4).

Findings:
- Treat single run failures as signal only; apply retry with exponential backoff + jitter to avoid synchronized repeat churn.
- Add circuit-breaker gate at repeat-3 for same task ID: pause direct retries and require alternate action (decompose, dependency check, or reviewer handoff).
- Enforce novelty guard: repeat of same task ID must include new diff surface or new failing signature before execution.
- Prefer rerun-scoped CI actions (failed jobs only) after flaky infrastructure failure; do not blindly rerun full pipelines.

References:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://martinfowler.com/articles/patterns-of-distributed-systems/index.html
- https://docs.github.com/en/actions/managing-workflow-runs/re-running-workflows-and-jobs
