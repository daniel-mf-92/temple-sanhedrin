# Repeat-task loop guards (Sanhedrin)

Trigger: repeated task IDs in recent builder iterations (>=3 occurrences in recent 80 rows).

Findings:
- Add explicit retry ceilings and escalation paths; treat retries as bounded state machine, not open loop.
- Use exponential backoff + non-retryable classifications so deterministic failures stop re-running.
- Use CI/workflow concurrency cancellation to prevent stale overlapping runs from compounding queue churn.
- Prefer idempotent task handlers so safe retries do not create duplicate queue churn.

Operational guardrails to apply in builders:
- If same task appears 3x in recent window: auto-attach new evidence requirement before next retry.
- If same task appears 5x without new code diff: force task handoff/new task ID and require root-cause note.
- Keep `cancel-in-progress: true` on same-branch workflow groups to reduce obsolete CI feedback loops.

References:
- https://docs.github.com/en/enterprise-cloud%40latest/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.temporal.io/encyclopedia/retry-policies
- https://docs.temporal.io/develop/python/best-practices/error-handling
