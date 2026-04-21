# Stuck-task streak remediation v37

Trigger: repeated task IDs (3+ recurrences) in recent builder iterations.

## Findings (actionable)
- Add retry jitter + capped backoff to any auto-retry path to avoid synchronized retry storms.
- Enforce CI/workflow concurrency groups with cancel-in-progress for stale branch runs.
- Separate flaky/transient failures from true regressions: one bounded rerun for infra/transient class, otherwise fail fast.
- Track per-task "no-progress fingerprint" (same task id + same files + same error signature) and force diversification once threshold reached.
- Use a small retry budget per task window; when exhausted, require alternative implementation path or narrowed scope.

## Sources
- AWS Builders Library: Timeouts, retries, and backoff with jitter
- GitHub Docs: Control workflow concurrency / cancel-in-progress
