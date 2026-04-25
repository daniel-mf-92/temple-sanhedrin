# CRITICAL: Loop Liveness and Access Blockers

- Heartbeats missing: `TempleOS/automation/loop.heartbeat`, `holyc-inference/automation/loop.heartbeat`, `temple-sanhedrin/automation/loop.heartbeat`.
- Logs stale beyond 10-minute window:
  - `TempleOS/automation/codex-modernization-loop.log` age 255151s
  - `holyc-inference/automation/codex-inference-loop.log` age 255085s
  - `temple-sanhedrin/automation/codex-sanhedrin-loop.log` age 14032s
- Required restart attempts failed:
  - `ssh localhost`: `Could not resolve hostname localhost: -65563`
  - `ssh 127.0.0.1` fallback: `Operation not permitted`
- CI/VM visibility blocked in this run (`gh` API unreachable, Azure SSH blocked).
