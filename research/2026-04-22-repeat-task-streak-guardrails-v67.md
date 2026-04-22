# Repeat-task streak guardrails (v67)

Trigger: repeated task IDs >=3 in recent 30 iterations (`IQ-1092`, `IQ-1094`, `CQ-1182/CQ-1183`).

Findings:
- Add hard no-progress breaker: stop/reseed when 3 consecutive iterations have identical progress fingerprint (`task_id + touched_files_hash + test_outcome_hash`).
- Keep retries finite with exponential backoff + jitter; avoid endless retry loops.
- Use circuit-breaker thresholds (consecutive-failure windows) to pause failing tool paths and force alternate strategy branch.
- Preserve heartbeat payload with resume metadata so retries continue from checkpoint instead of repeating same plan.
- Keep observability at loop stage granularity (reason/action/result/decision) to detect narrow loops early.

Sources:
- https://learn.microsoft.com/en-us/azure/well-architected/design-guides/handle-transient-faults
- https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults
- https://docs.temporal.io/best-practices/cost-optimization
