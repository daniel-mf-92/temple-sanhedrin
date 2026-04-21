# Repeat-task stall mitigation refresh (2026-04-21)

Trigger: repeated task IDs in last 6h (`CQ-877` x4, `IQ-839` x3, `IQ-842` x3, `IQ-844` x3, `CQ-810` x3).

## Findings
- Use jittered exponential backoff with capped retries to avoid synchronized retry storms and infinite retry loops.
- Use durable idempotency keys per task-attempt and claim-write-before-execute semantics to prevent duplicate work replays.
- Use workflow/job concurrency guards to cancel stale in-progress runs and prioritize newest commits/tasks.
- Split long multi-step activities into smaller idempotent steps with explicit progress heartbeats/checkpoints.

## Source anchors
- AWS Architecture Blog: Exponential Backoff and Jitter
- Temporal docs/blog: activity idempotency + retry policy + heartbeats
- GitHub Actions docs: `concurrency` + `cancel-in-progress: true`

## Immediate application to temple loops
- Add per-task retry budget in loop wrappers (`max_attempts_per_task`) with escalation after budget exhausted.
- Add novelty gate: if same task_id repeats >=3 without new code-file delta, demote and pick next task.
- Add stale-run suppression in CI workflows via concurrency groups keyed by workflow+branch.
- Persist step-level checkpoints in central DB to prove forward progress across retries.
