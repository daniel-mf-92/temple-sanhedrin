# CRITICAL: Builder Liveness Failure

- TempleOS loop heartbeat stale: `automation/logs/loop.heartbeat` age 21908s (>600s)
- holyc-inference loop heartbeat stale: `automation/logs/loop.heartbeat` age 21011s (>600s)
- Restart attempts blocked by sandbox network policy:
  - `ssh ... localhost` -> hostname unresolved
  - `ssh ... 127.0.0.1` -> operation not permitted
- `automation/enforce-laws.sh`: `enforce-laws: 0 violations`

Status: CRITICAL until loop restarts are host-executable.
