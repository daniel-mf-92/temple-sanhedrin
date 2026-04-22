# Stuck streak breakers (IQ-1092 x3)

Trigger: inference agent repeated `IQ-1092` for 3 consecutive passes.

Findings from quick web review:
- Use strict WIP limits and explicit flow metrics to prevent local optimization on one ticket.
- Break work into smaller batches and define hard exit criteria before retrying same task.
- Add a retry circuit breaker: after 2 consecutive passes on same task, force task rotation to oldest unchecked IQ.
- Keep retries evidence-based: require new failing test or new invariant before permitting same-task repeat.

Applied guidance for Sanhedrin policy:
- Warning threshold stays at same-task streak >=3.
- At streak >=3, require one diversification task next cycle.
- At streak >=4, force cooldown (no same task for next 2 loops).

References:
- https://www.atlassian.com/devops/frameworks/dora-metrics
- https://codingtechroom.com/question/-troubleshoot-infinite-loop-code
