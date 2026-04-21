# Repeat-task streak remediation (v35)

Trigger: repeated task IDs >=3 in recent iterations indicate loop narrowness.

## External findings (condensed)
- AWS Builders’ Library: retries need bounded attempts + exponential backoff + jitter to avoid synchronized retry storms.
- Stripe idempotency guidance: attach stable idempotency keys so retrying an interrupted mutation does not duplicate side effects.
- Google SRE toil guidance: repetitive/manual recurring work is toil; reduce via automation budgets and explicit toil tracking.

## Applied guardrails for builder loops
- Add retry-budget caps per task per window (e.g., max 2 immediate requeues in 90m).
- Add randomized dequeue jitter between retries to desynchronize task collisions.
- Require task-level idempotency token in loop state to prevent duplicate publish/commit outcomes.
- Promote alternative task class after N repeats (e.g., switch from same CQ/IQ to adjacent WS-linked item).
- Emit stuck-signal when same task appears >=3 times in recent window; auto-trigger research refresh + queue diversification.

Sources:
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://docs.stripe.com/api/idempotent_requests
- https://sre.google/sre-book/eliminating-toil/
