# Stuck-task loop breakers (Sanhedrin)

Trigger: repeated same task IDs (IQ-877 x3 consecutive; CQ-914 x3 in recent window).

Findings:
- Add a hard retry cap per task ID (max 2 retries), then force queue advance.
- Require per-iteration novelty check (new file diff or new failing test signature) before re-running same task.
- On repeat-3, auto-switch to "decompose" mode: split task into smaller subtask IDs with explicit acceptance checks.
- Track reason codes for retries (flake, dependency, review churn) to separate weather from true blockers.

Reference:
- https://www.thoughtworks.com/insights/articles/radar-hits-misses
