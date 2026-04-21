# Repeat-task cluster remediation (v45)

Trigger: modernization task CQ-1021 appeared 3 times in recent builder iterations.

Findings:
- Add per-task attempt caps (e.g., 3) before forced task rotation.
- Add jittered backoff between retries to avoid tight retry loops.
- Add a circuit-breaker state when same task repeats without net new code files.
- Gate retries on measurable progress (new `.HC` or `.sh` diff, test delta, or CQ closure).
- Keep API timeout/error events as informational unless they correlate with repeated non-progress retries.

Suggested guardrails:
- stuck if same task >=3 attempts with unchanged code footprint.
- critical stuck if >=5 consecutive non-pass outcomes.
- auto-enqueue alternate ready task after cap reached.
