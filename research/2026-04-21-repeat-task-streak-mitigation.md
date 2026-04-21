# Repeat-task streak mitigation (2026-04-21)

Trigger: repeated task IDs (3+ consecutive) in builder loops.

Findings:
- Add novelty gate: block re-issuing same task_id after 2 consecutive passes unless new failing evidence appears.
- Add retry budget per task_id (max 3 attempts / 6h), then force dequeue and pick highest-impact sibling task.
- Require delta-proof in loop prompt: each retry must cite new file, new test assertion, or new failing signal.
- Add cooldown window (30-60m) before task_id can re-enter active slot.
- Promote "stuck" class alerts to WARNING when streak>=3; CRITICAL only when compile/regression is blocked.

Operational policy for Sanhedrin:
- Keep single failures as INFO.
- Treat repeated failures without progress as WARNING.
- Treat 5+ consecutive failures with no artifact delta as stuck and require research refresh.
