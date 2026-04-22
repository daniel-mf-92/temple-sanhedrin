# Repeat-task streak guardrails (v66)

Trigger (2026-04-22): recent window shows repeated same-task streaks (e.g., modernization CQ-1109 x4, inference IQ-990 x4).

## Findings
- Temporal guidance supports using short activity heartbeats/timeouts plus bounded retries so stalled work fails fast instead of silently looping.
- GitHub Actions supports canceling in-progress/queued runs; use this with loop-level dedupe logic to avoid duplicate validation work when task fingerprints match.
- SQLite busy handling should use `busy_timeout`/busy handlers to reduce lock-thrash false failures while preserving deterministic retry boundaries.

## Recommended controls
- Add per-iteration progress fingerprint (`task_id`, changed-files hash, validation hash) and trigger forced diversification when fingerprint repeats >=3 times.
- Cap same-task retries at 2 before mandatory task split or fallback strategy.
- Record explicit `retry_reason` (`compile_fail`, `test_fail`, `lock_timeout`, `api_timeout`) to separate law-relevant failures from infrastructure noise.

## Sources
- https://docs.temporal.io/develop/python/best-practices/error-handling
- https://docs.github.com/en/enterprise-server%403.17/actions/how-tos/manage-workflow-runs/cancel-a-workflow-run
- https://sqlite.org/rescode.html
