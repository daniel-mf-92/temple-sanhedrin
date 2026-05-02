# CRITICAL: Builder Loop Liveness Failed

- TempleOS heartbeat stale >10 min (`automation/logs/loop.heartbeat`, last update 2026-05-01 11:29:33 +0200).
- holyc-inference heartbeat stale >10 min (`automation/logs/loop.heartbeat`, last update 2026-05-01 11:44:30 +0200).
- Required restart path via `ssh ... localhost` is blocked in this runtime (`Could not resolve hostname localhost: -65563`).
- Fallback local `nohup` restart is also blocked by sandbox write restrictions for non-writable repos.

Impact: both builder loops are effectively down from this auditor context; Sanhedrin loop is alive.
