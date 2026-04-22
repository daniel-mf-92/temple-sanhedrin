# Stuck Pattern Research (v74)

Trigger: repeated task IDs in recent builder iterations (modernization `CQ-1152` x4; inference `IQ-1057`/`IQ-1062`/`IQ-1063` x3 each in recent window).

## Findings
- Add per-task circuit breaker: if same task appears 3 times in 6 attempts without net queue reduction, force task switch to next eligible CQ/IQ for one cycle.
- Add bounded retries with jittered backoff on identical task re-attempts to avoid immediate tight-loop reprocessing.
- Add toil guardrail metric: `% iterations on repeated task IDs`; warn at >30%, hard warning at >50%.
- Keep failure semantics unchanged: transport/API timeout failures remain INFO, not law violations.

## Sources
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://sre.google/sre-book/eliminating-toil/
