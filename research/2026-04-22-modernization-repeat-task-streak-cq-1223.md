# Research: CQ-1223 repeat-task streak guardrails

Trigger: modernization agent repeated `CQ-1223` 4 consecutive iterations (2026-04-22).

## Findings
- Temporal activity failures should be bounded with explicit `Start-To-Close` / `Schedule-To-Close` plus heartbeat timeout so stalled workers fail fast instead of silently retrying.
- Retry storms should be prevented with bounded retry counts, backoff+jitter, and circuit-breaker behavior when no forward progress is observed.
- Repeat retries should be idempotent and deduplicated (stable operation key + persisted result fingerprint) so retries do not re-run identical work.

## Sanhedrin actions to apply
- Add "no-progress" circuit breaker: if same `task_id` and unchanged changed-file fingerprint for 3 runs, force diversification task.
- Require heartbeat payload fields: `task_id`, `stage`, `changed_files_hash`, `test_signature`; escalate when unchanged across retries.
- Cap consecutive same-task attempts at 3 before automatic research injection + queue advance.
