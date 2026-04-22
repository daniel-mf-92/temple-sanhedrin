# Repeat-task streak breakers (v62)

Trigger: CQ-1098 x3 and IQ-1014 x3 in recent loop history.

Findings from quick web scan:
- AWS Builders’ Library recommends capped exponential backoff with jitter to avoid synchronized retry storms and repeated no-progress loops.
- For workflow systems, use automatic retry only for transient failures; force a different execution path after N repeated same-task passes/fails (task diversification gate).
- Apply WIP/task-slot caps so the loop cannot keep selecting the same task family when queue breadth is available.

Recommended safeguards for builder loops:
1. If same `task_id` appears 3 times in 60-min window, demote it for next 2 iterations.
2. Require “different subsystem” pick after 3-repeat streak (e.g., `Kernel/*` -> `automation/*` or vice versa).
3. Add streak counter to central DB scoring so scheduler prefers fresh task IDs.
4. Keep transient API/timeouts as non-violations; only trigger streak breaker on no-progress repeats.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://miro.com/kanban/wip-limits-kanban/
