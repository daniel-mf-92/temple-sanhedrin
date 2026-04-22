# Repeat-task streak guardrails (v76)

- Trigger: repeated task IDs observed (>=3 attempts) for both builders despite pass-heavy status.
- Pattern: no failure streak, but retry selection shows low diversification and repeated IDs.
- Guardrail: enforce no-progress detector using `(task_id, changed_files_hash, test_hash)` over last 3 attempts.
- Guardrail: when unchanged across 3 attempts, auto-switch prompt strategy and skip task for one cycle.
- Guardrail: keep heartbeat timeout short and bounded retries so stalls fail fast, then branch.
- CI hygiene: preserve flaky/infra classification separate from code regressions; only escalate compile blockers.

Sources:
- https://docs.temporal.io/
- https://docs.github.com/en/actions
