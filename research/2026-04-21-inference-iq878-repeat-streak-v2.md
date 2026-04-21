# Stuck pattern: repeated IQ task selection (IQ-878 x5)

Trigger:
- Inference recent80 shows `IQ-878` selected 5 times; modernization has 3x repeats but below hard stuck threshold.

Web findings (applied to loop policy):
- Add idempotency key per `(task_id, patch_fingerprint)` so retries do not re-run identical no-op attempts.
- Use exponential backoff with jitter for retried task IDs and temporarily down-rank them after 2 consecutive no-progress attempts.
- Enforce fairness window: exclude any task picked in last `K=3` iterations unless queue depth < floor.
- Apply priority aging so untouched queued tasks gain score each iteration and beat repeated IDs.
- Promote a decomposition fallback: after 2 failures on same IQ, auto-split into narrower subtask with explicit changed-file target.

Expected outcome:
- Breaks same-task loops without violating queue depth or HolyC purity laws.
