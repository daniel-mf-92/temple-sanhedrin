# Builder Stall Guardrails (Sanhedrin)

## Trigger
Repeated task IDs detected in recent builder iterations:
- modernization: CQ-877 repeated 4x
- inference: IQ-839 / IQ-842 / IQ-844 repeated 3x each

## External guidance synthesized
- Apply strict WIP caps to force completion before pulling new work.
- Add a circuit-breaker: after N repeated failures/no-progress cycles, pause retries and require alternative path selection.
- Separate transient failures from persistent failures (timeouts/API errors are transient noise; repeated no-progress is persistent).
- Use short+long windows for alerts to reduce noisy paging and catch true stalls quickly.

## Concrete guardrails for loops
- Novelty gate: block commits that touch only task metadata after 2 consecutive iterations on same task.
- Retry budget: max 3 consecutive same-task attempts unless files_changed includes core code paths.
- Escalation state machine: INFO (1 fail), WARNING (2-4 no-progress), STUCK (>=5 no-progress) -> mandatory research + task swap.
- Throughput floor: enforce minimum code artifact delta over rolling 5 commits.

## Sources
- Atlassian Kanban WIP limits
- Microsoft Azure Architecture: Circuit Breaker pattern
- AWS Prescriptive Guidance: Circuit Breaker pattern
- Google SRE Workbook: Alerting on SLOs (multi-window burn-rate)
