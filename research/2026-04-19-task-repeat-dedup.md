# Task repeat guardrails (IQ-451 x3)

Trigger: Inference task `IQ-451` appeared 3 times in 12h despite pass status.

Findings:
- Add queue-level idempotency key (`task_id + content_hash`) so completed tasks are not re-claimed unless inputs changed.
- Wrap claim+start in a single SQLite write transaction (`BEGIN IMMEDIATE`) to avoid duplicate workers claiming same pending item.
- Use SQLite UPSERT on claim records keyed by `(agent, task_id, run_window)` to keep one authoritative attempt row.
- Add per-task cooldown (e.g., 2-6h) after PASS before task can re-enter queue unless explicitly re-opened.
- For CI-triggered loops, set GitHub Actions `concurrency` group per branch/loop to suppress overlapping loop runs.

Scope note:
- This is anti-duplication control only; no law violations detected and no air-gap policy impact.
