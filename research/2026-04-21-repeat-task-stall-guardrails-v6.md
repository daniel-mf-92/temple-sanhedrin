# Repeat-task stall guardrails v6 (2026-04-21)

Trigger: repeated task IDs observed (>=3 occurrences): CQ-877, IQ-839, IQ-842, IQ-844.

Findings (online):
- Add bounded retry budgets per task-id (max 2 immediate retries), then force task rotation.
- Use exponential backoff + jitter between retries to avoid retry amplification.
- For CI noise, rerun only failed jobs, not full workflow; cap reruns per commit.
- Use workflow concurrency keys to avoid duplicate in-flight runs for same branch/task.
- Keep fail-fast enabled for matrix jobs where one leg failure invalidates the batch.

Temple-Sanhedrin policy patch (recommended):
- If same task_id appears 3 times in last 20 iterations: WARNING + require alternate task class next loop.
- If same task_id appears 5 times in last 40 iterations: STUCK + mandatory research + block further same-task picks for 60 min.
- Track per-task attempt counters in central DB notes to make stall detection deterministic.

Sources:
- https://sre.google/sre-book/addressing-cascading-failures/
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
