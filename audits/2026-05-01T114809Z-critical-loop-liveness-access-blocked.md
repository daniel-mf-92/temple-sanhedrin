# CRITICAL: Loop Liveness Access Blocked

- Timestamp (UTC): 2026-05-01T11:48:09Z
- TempleOS heartbeat: 2026-05-01 11:29:33 +0200 (stale >10m)
- holyc-inference heartbeat: 2026-05-01 11:44:30 +0200 (stale >10m)
- Restart attempts via `ssh localhost` and `ssh 127.0.0.1` failed (`operation not permitted`)
- Direct `nohup` restart fallback blocked by sandbox write restrictions on target logs
- Result: unable to restore builder loops from this sandbox; requires host-level restart access
