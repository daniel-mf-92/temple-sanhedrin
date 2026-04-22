# Repeat-task streak breakers (v72)

Trigger:
- Recent 20 iterations show repeat clusters without failure progress: `CQ-1152 x4`, `IQ-1057 x3`, `IQ-1062 x3`, `IQ-1063 x3`.

Online findings (applied to builder loops):
- Enforce a "start wide, then narrow" retry policy so retries must alter search breadth before reusing same task framing.
- Add harness-level diversity constraints: each repeated task attempt must include one new verification axis (new fixture, edge case, or alternate parity gate), otherwise auto-requeue a sibling task.
- Use explicit effort budgets + stop conditions for long-running loops; when task repeats hit threshold, require a different task family for 1 cycle before returning.

Actionable guardrails:
- `same_task_recent20 >= 3` -> inject one adjacent task from backlog before allowing same task again.
- `same_task_recent20 >= 4` -> require changed test oracle/input class; reject "same test, same shape" retries.
- Keep failures separate from law checks: API/timeouts remain operational info, not law violations.

References:
- https://www.anthropic.com/engineering/built-multi-agent-research-system
- https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
