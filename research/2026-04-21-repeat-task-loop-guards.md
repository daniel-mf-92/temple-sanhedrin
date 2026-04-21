# Repeat-task loop guards (stuck-pattern response)

Trigger: repeated task IDs (>=3 repeats in last 120 builder iterations).

## Findings
- Use DB-level dedupe for active work: SQLite supports partial unique indexes, so only one active row per `(agent, task_id)` can exist while status is pending/running.
- Add retry control with jittered backoff for transient failures; jitter avoids synchronized retry storms and reduces repeat thrash.
- Use workflow concurrency groups (`cancel-in-progress: true`) in GitHub Actions to prevent stale duplicate runs from accumulating on the same branch.

## Suggested actions (host automation only)
- Add `CREATE UNIQUE INDEX ... WHERE status IN ('pending','running')` on central task queue tables.
- Add capped exponential backoff with jitter to loop retry paths and only reopen a task after backoff window.
- Add GitHub Actions `concurrency` key for loop branches (`codex/modernization-loop`, `main`) where duplicate pushes are common.

## Sources
- SQLite partial indexes: https://sqlite.org/partialindex.html
- AWS backoff + jitter: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- AWS Builders' Library retries/backoff: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- GitHub Actions concurrency: https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
