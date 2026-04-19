# Inference repeat-task loop guard (2026-04-19)

Trigger: `inference|IQ-451` repeated 3 times in 12h.

Findings:
- Make task execution idempotent; retries and restarts should not duplicate output.
- Add checkpoint/progress markers so restarts resume instead of re-processing same task.
- Enforce atomic claim in SQLite: single transaction marks one pending task as claimed, then process.
- Add uniqueness constraint/index for task-run key (e.g., `agent, task_id, target_commit`) so duplicates are rejected.
- If workflow-level duplication occurs, set GitHub Actions `concurrency` group + `cancel-in-progress: true`.

Sources:
- https://docs.cloud.google.com/run/docs/jobs-retries
- https://docs.cloud.google.com/scheduler/docs/creating
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://sqlite.org/lang_conflict.html
