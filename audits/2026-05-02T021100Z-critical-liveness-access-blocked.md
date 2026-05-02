# CRITICAL: builder liveness + access blockers

- TempleOS heartbeat stale (>10m): `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale (>10m): `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/logs/loop.heartbeat`.
- Process liveness check blocked by sandbox (`ps`/`pgrep` unavailable).
- Restart blocked: cannot SSH localhost in sandbox; cannot write builder logs outside writable roots.
- CI check blocked: `gh` cannot reach `api.github.com`.
- VM check blocked: SSH to `52.157.85.234` not permitted.
- Email check blocked: `outlook` not authenticated (`outlook-auth` required).
