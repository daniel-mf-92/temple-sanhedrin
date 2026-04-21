# Repeat-task progress gates v6 (Sanhedrin)

Trigger: repeated tasks (>=3) in last 120 iterations: inference IQ-936/944/960 (x4), IQ-920/931/946/951 (x3), modernization CQ-990/992 (x3).

Applied reliability controls (from circuit-breaker/retry-pattern practice):
- Retry budget per task: max 2 immediate retries; on 3rd miss force task switch.
- Circuit breaker: open task after 3 no-delta passes; cool-down 30 min before reopen.
- Progress proof gate: PASS must include one measurable code delta (`.HC/.sh/.py`) or test delta.
- Diversity gate: disallow same task id in >2 of last 5 cycles for each agent.
- Escalation gate: if same task appears 3+ times with low delta, auto-spawn research note + replacement task pair.

Implementation note for loop prompts:
- Require a "delta token" in notes: `files_changed`, test name, and invariant checked.
- If delta token repeats unchanged across 2 passes, status should degrade to WARNING (not PASS).
