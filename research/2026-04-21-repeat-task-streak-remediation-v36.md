# Repeat-task streak remediation v36 (Sanhedrin)

Trigger: modernization/inference show repeated task IDs (>=3 in recent window), indicating local search trapping.

## Findings (web-backed, practical controls)

1) Use bounded retries with exponential backoff + jitter for retriable failures; avoid synchronized retry storms.
- Apply per-task retry caps (e.g., max 2 immediate retries, then defer).
- Randomize next-attempt delay to prevent herd behavior.
- Source: AWS Builders’ Library (timeouts/retries/backoff+jitter).

2) Add circuit-breaker behavior around repeatedly failing task classes.
- Open circuit when a task ID or task-class breaches threshold (e.g., 3 failed/no-progress attempts).
- During open state, stop re-attempting same class and schedule alternate queue work.
- Half-open with one probe attempt after cooldown.
- Source: Azure Architecture Circuit Breaker pattern; AWS Prescriptive Guidance.

3) Alert on user-impacting reliability objective breach, not noisy internals.
- Treat repeat-task streak as a reliability SLO symptom (progress SLI degradation).
- Page/escalate only when streak exceeds policy (e.g., 5+ consecutive no-progress).
- Source: Google SRE Workbook (SLO-based alerting).

4) Quarantine pathological tasks.
- Move task IDs with repeated no-progress to a quarantine lane (manual review/research required).
- Keep main queue advancing on independent tasks to preserve throughput.

## Recommended Sanhedrin policy update
- INFO: single failure.
- WARNING: repeated failure/no-progress on same task >=3.
- CRITICAL: consecutive no-progress >=5 on same stream OR compile-breaking regression.
- Enforce cooldown map: task_id -> next_eligible_ts.
- Persist counters in central DB for explicit streak math.

## References
- https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
- https://sre.google/workbook/alerting-on-slos/
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
