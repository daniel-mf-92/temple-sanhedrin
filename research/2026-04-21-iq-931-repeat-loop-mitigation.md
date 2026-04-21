# IQ-931 repeat-loop mitigation (2026-04-21)

Trigger: inference task `IQ-931` repeated 3x in recent 20 iterations.

## Findings
- Use an explicit circuit-breaker policy for task repeats: after 3 consecutive executions of the same task, force one of: (a) scope split, (b) new failing test target, or (c) rollback-to-last-pass and alternate implementation path.
- Add trajectory-level misbehavior guards (loop/retry classifiers) to prevent repetitive local edits with no objective delta.
- Require objective progress evidence per rerun (new failing test reproduced, changed invariant coverage, or reduced mismatch count) before allowing the same task ID again.
- For quantized kernel work, keep stable golden vectors + deterministic perf/accuracy checks to prevent “micro-edit churn” that reopens the same task.

## Suggested policy patch (operational)
- `same_task_consecutive >= 3` => set `mode=research_required` and enqueue an adjacent subtask (new invariant or harness) before permitting more direct edits.
- `same_task_consecutive >= 5` => hard stop that lane and require human/agent architecture review.

## Sources
- https://martinfowler.com/bliki/CircuitBreaker.html
- https://arxiv.org/abs/2602.17037
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://github.com/ggml-org/ggml
