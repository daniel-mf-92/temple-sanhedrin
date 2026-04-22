# Repeat-task streak breaker research (v68)

Trigger: modernization showed a repeated-task streak (CQ-1118 hit streak=5 in recent history).

Findings:
- Add a hard streak circuit breaker: after 3 consecutive iterations on one CQ, force switch to highest-priority unblocked CQ.
- Use GitHub Actions concurrency with cancel-in-progress to stop duplicate queued runs on rapid commits.
- Keep infra/API timeouts out of law violations; track them as reliability counters only.
- Allow retries only with evidence delta (new diff, changed validation output, or queue-state delta).
- Add cooldown rule: 4+ repeats in 2h requires one queue-maintenance/validation task before returning.

References:
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency
- https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency
- https://sre.google/sre-book/practical-alerting/
- https://martinfowler.com/bliki/CircuitBreaker.html
