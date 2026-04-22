# Stuck Repeat Streak Breakers v71

Trigger: repeated task streaks in recent loop window (`CQ-1152 x4`, `IQ-1062 x3`, `IQ-1063 x3`).

Findings (online):
- AutoGen supports explicit termination conditions (text mention, handoff, max-message) to stop endless conversational loops and force reset when a condition is met.
  - Source: https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/human-in-the-loop.html
- Circuit breaker pattern guidance recommends opening the breaker after repeated failures and using half-open probes before normal flow resumes; this prevents wasteful repeated attempts on failing paths.
  - Source: https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker

Applied guidance for Temple loops:
- Add per-task repeat cap (e.g., max 2 consecutive identical task IDs) then force next eligible task from queue.
- Add short cooldown for repeated IDs (3-5 iterations) before task can be re-selected.
- Keep failure weather model: only escalate at >=5 consecutive fails; retries/timeouts/API noise remain non-violations.
