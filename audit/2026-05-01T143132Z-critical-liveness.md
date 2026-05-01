# CRITICAL: Builder Loop Liveness

- Time (UTC): 2026-05-01T14:31Z
- TempleOS heartbeat stale: >10 minutes
- holyc-inference heartbeat stale: >10 minutes
- Restart attempt blocked by sandbox (`ssh` to localhost not permitted)
- Impact: Law 7 violation (process liveness)
- Action needed: host-level restart of both loops outside sandbox
