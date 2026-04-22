# Stuck-loop guardrails (v66)

Trigger: repeated task streaks detected in recent builder iterations (>=3 repeats).

Findings (online):
- Use exponential backoff with jitter between retries to avoid synchronized retry storms and reduce contention.
- Add a circuit breaker so repeated failures temporarily stop calls/work and force cooldown before retry.
- Track toil/repetition as a first-class metric and route repeated manual loops into automation tasks.

Applied to Temple loops:
- Keep transient single failures as INFO.
- On repeat streak threshold, increase retry spacing and rotate task scope before next attempt.
- If threshold persists, force research note + alternative strategy selection.

Sources:
- https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/workbook/eliminating-toil/
