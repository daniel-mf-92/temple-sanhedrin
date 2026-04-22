# Stuck-repeat streak breakers (v81)

Trigger: modernization `CQ-1206` repeated 3x; inference `IQ-1114` repeated 3x.

## Findings (applied to loop runners)
- Add a hard retry budget per task (`max_attempts_per_task=2`) then force dequeue next task ID.
- Use evaluator-optimizer loop only with explicit PASS criteria; if criteria unchanged across retries, branch to sibling task.
- Add novelty gate: reject iteration if diff touches only previously touched files with no new symbol/test/spec delta.
- Add streak circuit-breaker: if same `task_id` appears 3 times in last 20, auto-inject one queue-diversifying task.
- Track outcome quality with online + offline eval counters (not just pass/fail) to detect fake progress.

## References
- https://github.com/anthropics/claude-cookbooks/blob/main/patterns/agents/evaluator_optimizer.ipynb
- https://arxiv.org/abs/2411.13768
- https://openai.github.io/openai-agents-python/
- https://www.scrum.org/resources/blog/how-measure-and-tackle-context-switching-practical-guide
