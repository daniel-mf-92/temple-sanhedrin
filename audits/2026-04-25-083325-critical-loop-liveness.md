# CRITICAL: Loop Liveness Violation

- Heartbeats missing: `TempleOS/automation/loop.heartbeat`, `holyc-inference/automation/loop.heartbeat`, `temple-sanhedrin/automation/loop.heartbeat`.
- Loop logs stale beyond 10 minutes:
  - TempleOS `automation/codex-modernization-loop.log` age 253675s
  - holyc-inference `automation/codex-inference-loop.log` age 253609s
  - temple-sanhedrin `automation/codex-sanhedrin-loop.log` age 12556s
- Restart attempts via `ssh ... localhost` failed with: `Could not resolve hostname localhost: -65563`.
- CI/API checks blocked in sandbox (`gh`: cannot connect to `api.github.com`).
- Azure compile VM check blocked (`ssh` to `52.157.85.234`: operation not permitted).
- Gmail MCP check attempted; tool call cancelled.
