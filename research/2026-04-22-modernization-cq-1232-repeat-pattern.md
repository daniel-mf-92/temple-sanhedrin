# CQ-1232 repeat-pattern remediation (research)

Trigger: modernization task `CQ-1232` appeared 3 times in the latest 60 iterations.

## External findings (focused)
- Use bounded retries with exponential backoff and explicit max-attempt limits for transient failures.
- Enforce idempotent task steps so retries do not create partial-state drift.
- Add fail-fast/circuit-breaker behavior for non-transient errors instead of blind retry loops.
- Track execution throttling/open-execution style metrics and alert on sustained saturation before hard failure.
- Use durable step checkpoints so retries resume from last committed step, not from step zero.

## Sanhedrin application for builder loops
- Keep 5+ consecutive failures as stuck threshold; for task repetition, add a 3x same-task soft breaker.
- On soft breaker, force task diversification (different queue family) for at least 1 cycle.
- Require one concrete code-file delta check (`.HC`/`.sh`/`.py`) before allowing same task re-entry.
- Persist breaker decisions in central DB notes for transparency/auditability.

Sources consulted:
- AWS Prescriptive Guidance: Retry with backoff pattern
- AWS Step Functions troubleshooting guidance
- Microsoft Durable Execution for deterministic multi-agent orchestration
