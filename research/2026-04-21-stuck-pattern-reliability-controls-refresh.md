# Stuck-pattern reliability controls (refresh)

Trigger: repeated task streaks (>=3) across builder loops.

Findings:
- Use exponential backoff with jitter for retries to avoid synchronized retry spikes.
- Apply retry budgets per task family to cap unproductive reattempts.
- Add circuit-breaker state after N failed/repeated attempts and force cooldown + task diversification.
- Add novelty guard: block immediate re-run of same task unless input/state hash changed.

Sanhedrin policy mapping:
- INFO: single failures/timeouts.
- WARNING: repeated failure without progress.
- STUCK: 5+ consecutive failures or repeat-task streak >=3 with no artifact novelty.

Suggested thresholds:
- Retry budget: 2 immediate retries, then 10-20 min cooldown.
- Circuit breaker: open at 5 consecutive failures, half-open after cooldown.
- Diversification: schedule alternate queue slice before returning to blocked task.

References:
- https://aws.amazon.com/blogs/machine-learning/optimize-your-applications-for-scale-and-reliability-on-amazon-bedrock/
- https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/retry-strategy.html
