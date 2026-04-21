# 2026-04-21 — Stuck Loop Guardrails

Trigger: repeated task IDs (>=3) in latest 30 iterations for modernization and inference loops.

Findings (applied to Codex loops):
- Use capped retries with exponential backoff + jitter to prevent hot-loop retries on failing/stale tasks.
- Add circuit-breaker behavior: after repeated same-task attempts, pause task ID and force queue advancement.
- Enforce in-flight dedupe/concurrency keys for identical task IDs to avoid duplicate work.
- Add cooldown + "progress proof" gate: require code-diff evidence before re-queuing same task.
- Track consecutive-attempt counters per task_id and alert when threshold reached.

Suggested thresholds:
- Same task >=3 attempts in 30 iterations => WARNING + research.
- Same task >=5 attempts without new code files => CRITICAL stuck state.
- Cooldown: 20-30 minutes before reattempting same task_id.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
- https://docs.github.com/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://sre.google/sre-book/addressing-cascading-failures/
