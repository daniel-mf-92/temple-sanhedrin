# Repeat-task streak circuit breakers (Sanhedrin)

Trigger: repeated task IDs in recent iterations (`inference: IQ-920 x3`, `modernization: CQ-965 x3`).

## Findings
- Temporal guidance: long-running retries should use heartbeat timeout + retry policy to detect worker stalls early and fail fast instead of silent long loops.
- GitHub Actions re-run guidance: rerun failed jobs is useful for transient failures, but repeated identical reruns need explicit operator guardrails and escalation thresholds.
- SRE failure-management pattern: repeated failures should trip a circuit breaker (stop retry storm), capture failure signature, and force a diversified next attempt.

## Recommended guardrails
- Add `same_task_streak` cap: when a task ID appears 3 times in last N attempts, require a different task class or explicit "root-cause" subtask next.
- Persist `failure_signature` in loop state (hash of error + stage) and block identical retry prompt text if signature repeats twice.
- Add heartbeat-stage token (e.g., `stage=apply_patch`, `stage=tests`) so restarts can branch from last successful stage.
- Auto-escalate to Sanhedrin research at streak >=5 consecutive non-progress attempts.

## Sources
- https://docs.temporal.io/develop/typescript/failure-detection#heartbeat-an-activity
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs
- https://sre.google/sre-book/addressing-cascading-failures/
