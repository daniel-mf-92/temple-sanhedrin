# Stuck Repeat Streak Breakers (v73)

Trigger:
- modernization: CQ-1152 repeated 4 consecutive iterations
- inference: IQ-1062 repeated 3 consecutive iterations

Online findings (applied to loop policy):
- Use exponential backoff with jitter for transient failure retries; avoids synchronized thrash.
  - https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
  - https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- Add circuit-breaker state after consecutive failures/repeats; stop immediate re-attempts and force alternate path.
  - https://martinfowler.com/bliki/CircuitBreaker.html
- Add objective reliability gate: if error/repeat budget exceeded in rolling window, pause feature loop and run stabilization tranche.
  - https://sre.google/workbook/error-budget-policy/

Sanhedrin actions to enforce:
- If same task repeats >=3: force task diversification (pick different task family next run).
- If same task repeats >=5 OR fail streak >=5: mark stuck=CRITICAL, require research refresh + alternate implementation path.
- Retry policy: max retries per task family per hour; then cool-down window before same task family can re-enter.
