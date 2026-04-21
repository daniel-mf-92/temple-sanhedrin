# Repeat-task stall mitigation (v6)

Trigger: repeated builder task IDs >=3 in rolling 3h window (`CQ-877`, `CQ-810`, `IQ-839`, `IQ-842`, `IQ-844`).

## Findings (online)
- Use exponential backoff with jitter for retried loop actions to avoid synchronized retry storms and preserve service recovery windows.
- Gate retries by idempotency: retry only steps that are safe to repeat; persist task-attempt identity keys to suppress duplicate side effects.
- Add bounded retry budgets per task ID/time window; when exhausted, force task rotation or escalate to research mode.
- Use circuit-breaker style cooldown when the same task fails/repeats consecutively, then probe with one canary attempt before full resumption.
- Separate flaky/non-deterministic validations into a non-blocking lane so builders keep shipping core code while instability is triaged.

## Immediate guardrails for builders
- If same `task_id` appears 3x in 90m without net new core file paths, auto-select a different pending task.
- If repeated 5x, mark current task as `blocked` with reason and enqueue a narrower subtask.
- Record progress hash (`files_changed` + `validation_result`) each iteration; reject exact repeat hashes unless run is explicitly retry-tagged.
