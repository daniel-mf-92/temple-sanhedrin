# Stuck Pattern Research — Repeat Task Streak Breakers (v69)

Trigger: inference same-task streak reached 4 on IQ-1063; modernization streak reached 3 on CQ-1152.

Findings (web):
- Apply a circuit-breaker after N repeated iterations on the same task to force a different path before continuing.
- Use bounded retries with exponential backoff + jitter to avoid rapid no-progress loops.
- Cap retries by time/attempt budget, then require a decomposition step (new subtask, new invariant, or new failing test) before continuing.

Recommended guardrails for builder loops:
- If same task appears 3x consecutively, require one of: new failing test, new code-path file touch, or queue advance to next dependency.
- If same task appears 5x consecutively, hard-stop task and enqueue blocker-resolution ticket with concrete unblock criterion.
- Track "progress token" (new symbol, new assertion, or new harness case) and reject iterations lacking one.

Sources:
- Google SRE Workbook: Eliminating Toil
- Microsoft Architecture Center: Circuit Breaker Pattern
- Microsoft Architecture Center: Retry Storm Antipattern
