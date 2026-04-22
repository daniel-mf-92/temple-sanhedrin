# Repeat-task streak controls (v66)

Trigger observed: same task IDs repeated 3+ times in recent builder windows (CQ-1130, CQ-1109, IQ-1039/IQ-1014/IQ-1024).

## Findings
- Use bounded retries per task ID (max 2 immediate retries), then force task switch to a different subsystem.
- Add a cooldown window for recently-attempted task IDs so scheduler cannot re-pick them in the next 5 selections.
- Require a measurable delta before allowing same-task retry (new failing test line, new file touched, or changed hypothesis tag).
- If no delta after retry budget, auto-emit `stuck` and enqueue a narrow research/unblock task instead of re-running.
- Keep transport/API timeout errors non-fatal and excluded from retry-streak law accounting.

## Sanhedrin application
- Classification remains `INFO` for isolated fails and `WARNING` for repeat-without-delta.
- Escalate to `CRITICAL` only for compile-blocking failures or 5+ consecutive true failures.
