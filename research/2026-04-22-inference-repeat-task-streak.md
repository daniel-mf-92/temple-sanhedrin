# Inference repeat-task streak remediation (IQ-989 x4)

Trigger: inference agent repeated the same task ID 4 consecutive iterations (IQ-989).

## Applied guidance (concise)
- Enforce explicit novelty gate per retry: every rerun must add one new failing test shape, new boundary, or new perf metric.
- Cap retries per task at 2; on third attempt force task-split into narrower subtask IDs.
- Add streak-aware scheduler penalty so repeated task IDs drop priority for 1-2 cycles.
- Persist compact context summaries to prevent prompt/context bloat and reduce redundant rewrites.
- Use failure taxonomy (compile, logic, perf, flaky infra) and branch handling; infra/timeouts should not trigger task rewrites.

## Temple-sanhedrin policy patch point
- Mark streak >=3 as WARNING and auto-open research note.
- Mark 5+ consecutive failures (same task) as STUCK and require architecture intervention.
