# Stuck-pattern breaker: modernization CQ-1162 streak

Trigger: modernization repeated `CQ-1162` for 4 consecutive iterations.

Actions:
- Add a hard no-progress breaker: if same `task_id` repeats >=3 with unchanged touched-file hash, force task diversification on next pick.
- Add explicit heartbeat timeout + bounded retries on the worker loop so stalled executions fail fast instead of silently repeating.
- Split large CQ into 2-3 sub-checkpoints with required artifact delta per checkpoint (code/test/log evidence).
- Add a mandatory alternate-surface rule after 3 repeats (e.g., move from harness to kernel path or vice versa).
- Gate completion with a strict "new artifact" check to block pass-without-delta cycles.

Sources:
- https://docs.temporal.io/cli/activity
- https://cookbook.openai.com/examples/how_to_handle_rate_limits
- https://sre.google/workbook/alerting-on-slos/
