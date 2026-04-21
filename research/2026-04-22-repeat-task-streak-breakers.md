# Repeat-task streak breakers (Sanhedrin)

Trigger: inference and modernization showed recent same-task run streaks (>=3), even with PASS.

## Practical controls for Codex loops
- Add exponential backoff with jitter after same-task retries to prevent synchronization and tight repeat loops.
- Add per-task retry budget (e.g., max 2 consecutive attempts) then force scheduler to pick different task class.
- Add circuit breaker on task-id streaks: if streak >=3, open breaker for that task for cooldown window.
- Add workflow concurrency guard (`concurrency + cancel-in-progress`) so stale duplicate loop runs do not pile up.
- Add queue fairness: weighted random/task-bucket rotation so "fresh" tasks get scheduled before repeating one ID.

## Suggested thresholds
- streak_warn: 3
- streak_block: 5
- cooldown_min: 15
- retry_jitter_ms: 200-3000

## References
- AWS Builders Library: Timeouts, retries, and backoff with jitter
- GitHub Actions docs: Control workflow concurrency
- Kubernetes Job docs: `.spec.backoffLimit`
