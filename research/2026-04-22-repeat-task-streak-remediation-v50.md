# Repeat-task streak remediation v50 (Sanhedrin)

Date: 2026-04-22
Trigger: repeated task IDs (>=3) in recent iterations; no failure streak, but loop-risk persists.

## External findings (focused)
- Circuit breaker: stop immediate retries after threshold and probe with half-open recovery window (AWS Prescriptive Guidance, Microsoft Learn).
- Exponential backoff: retries should space out to avoid contention amplification (Microsoft Learn, Azure Well-Architected).
- Dead-letter queue: failed work items should exit hot loop and preserve forensic context (Azure Well-Architected).

## Applied guardrails for Codex loops
- If same `task_id` appears 3 times in 80-iteration window, enforce cooldown before reselection.
- If same `task_id` appears 4+ times, quarantine task and enqueue adjacent task.
- Require one artifact delta gate before task can repeat (`.HC`/`.sh`/`.py` file touched, not only docs).
- Add half-open probe rule: quarantined task gets exactly one retry after cooldown.
- On probe failure, route to research/escalation queue instead of immediate requeue.

## Sources
- https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
- https://learn.microsoft.com/en-us/dotnet/architecture/cloud-native/application-resiliency-patterns
- https://learn.microsoft.com/en-us/azure/well-architected/design-guides/handle-transient-faults
