# Stuck loop mitigation: retry storms and duplicate work

Trigger: repeated consecutive task runs (>=3) in builder loops.

Findings:
- Use GitHub Actions `concurrency` groups with `cancel-in-progress: true` so stale queued/running iterations are superseded.
- Add exponential backoff with jitter to loop retries to prevent synchronized retry bursts.
- Retry only transient failure classes; avoid retrying deterministic logic failures without state change.
- Add a breaker rule: after N repeated task_ids, force task reselection from queue tail.
- Add progress gate: if task repeats and output diff hash is unchanged, mark as no-progress and rotate task.

Sources:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://sre.google/sre-book/addressing-cascading-failures/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
