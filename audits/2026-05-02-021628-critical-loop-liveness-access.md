# CRITICAL: Loop liveness + access blockers

- TempleOS heartbeat stale: `2026-05-01 11:29:33` (`automation/logs/loop.heartbeat`)
- holyc-inference heartbeat stale: `2026-05-01 11:44:30` (`automation/logs/loop.heartbeat`)
- Restart via required `ssh localhost` failed: `Could not resolve hostname localhost`.
- Local fallback restart failed due sandbox write restrictions in target repos.
- CI status and Azure VM checks blocked by network restrictions in this sandbox.
