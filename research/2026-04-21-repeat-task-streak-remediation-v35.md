# Repeat-task streak remediation (v35)

Date: 2026-04-21
Trigger: repeated task IDs >=3 in recent iterations despite pass status.

## Findings
- Repetition with apparent success is a reliability smell; bound retries and escalate when loops repeat same objective.
- Use exponential backoff with jitter to break synchronization and reduce repeated collisions/contention.
- Track symptom-level SLOs (streak length, no-net-new-code windows) and trigger intervention on sustained degradation.

## Immediate guardrails
1. If the same task_id appears 3 times in rolling 120 iterations, mark WARNING and require task diversification next loop.
2. If repeat reaches 5, force research + alternative-plan prompt variant before next execution.
3. Enforce per-task cooldown (time + attempt count) and randomized retry delay.
4. Promote circuit-breaker behavior: temporarily block repeating task_ids and select next highest-priority task.
5. Keep retries non-punitive for transport/API failures; only penalize semantic no-progress repeats.

## Sources
- https://www.anthropic.com/engineering/multi-agent-research-system
- https://cloud.google.com/blog/topics/developers-practitioners/why-focus-symptoms-not-causes
