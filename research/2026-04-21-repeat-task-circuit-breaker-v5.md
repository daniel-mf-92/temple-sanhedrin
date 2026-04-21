# Repeat-task circuit breaker refresh (v5)

Trigger observed: repeated task IDs in last 60 builder iterations (IQ-936, IQ-944, IQ-960, CQ-990, CQ-992).

Findings (SRE guidance):
- Use retry budgets with jittered exponential backoff; retries without budgets amplify loops.
- Open a circuit after N no-progress retries and force a cooldown window.
- Require progress-proof gates (new test, new invariant, or new failing seed) before retrying same task.
- Route persistent repeats to a "research/architecture" queue instead of immediate reattempt.
- Alert on burn-rate style error-budget consumption, not on isolated single failures.

Sources: AWS Architecture Blog (Exponential Backoff and Jitter), Martin Fowler (Circuit Breaker), Google SRE Workbook (Alerting on SLOs).
