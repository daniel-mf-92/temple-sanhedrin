# Research: agent-stuck-repeat-task-guards
Date: 2026-04-21
Trigger: inference repeated task `IQ-844` 3 times consecutively.

## Findings (web)
- Use bounded retries with exponential backoff + jitter to avoid retry storms and synchronized rework loops.
- Treat repeated task submissions as idempotent operations keyed by `(agent, task_id, patch_fingerprint)` so duplicate attempts return prior result instead of re-running.
- Add explicit retry ceilings and escalation thresholds (e.g., hard escalation after N repeated same-task runs without net file-delta growth).
- Use client-side throttling/load shedding when worker queue pressure rises so one stuck task cannot monopolize loop throughput.

## Concrete guardrails for temple loops
- Add duplicate-run suppression: skip execution when same `task_id` appears with same file delta hash in the last 2 successful iterations.
- Add progress gate: require monotonic change in either touched HolyC files or test surface; otherwise status=`warning` and force next task selection.
- Add circuit breaker for task repetition: 3 same-task hits in a row => cooldown + research hook + queue advance.
- Keep failures informational unless consecutive fail streak >=5; only then mark stuck/critical path.

## Sources consulted
- AWS Builders’ Library: Timeouts, retries and backoff with jitter.
- AWS Builders’ Library: Making retries safe with idempotent APIs.
- AWS Well-Architected REL05-BP03 (limit retries).
- Google SRE Book: Addressing Cascading Failures / Handling Overload.
- Stripe API docs: idempotent request semantics.
