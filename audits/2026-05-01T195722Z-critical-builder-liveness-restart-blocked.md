# CRITICAL: builder loop liveness
- TempleOS heartbeat stale >10m: `automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale >10m: `automation/logs/loop.heartbeat`.
- Required restart attempt failed: `ssh ... localhost` returned `Could not resolve hostname localhost: -65563`.
- Process-list checks unavailable in sandbox (`ps`/`pgrep` blocked).
