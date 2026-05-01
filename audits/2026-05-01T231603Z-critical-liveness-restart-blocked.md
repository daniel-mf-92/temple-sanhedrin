# CRITICAL Audit
- Modernization loop heartbeat stale (>10m): `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/logs/loop.heartbeat`.
- Inference loop heartbeat stale (>10m): `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/logs/loop.heartbeat`.
- Required restart attempts failed in this environment: `ssh ... localhost` -> `Could not resolve hostname localhost: -65563`.
- `ps` liveness checks are sandbox-blocked (`operation not permitted`), so heartbeat is authoritative.
- Severity: CRITICAL until host-executable restart path succeeds.
