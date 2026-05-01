# Sanhedrin Audit — CRITICAL

- Enforcement: `automation/enforce-laws.sh` => `enforce-laws: 0 violations`.
- Liveness CRITICAL: builder heartbeats stale >10m.
  - `TempleOS/automation/logs/loop.heartbeat`: stale (~47000s)
  - `holyc-inference/automation/logs/loop.heartbeat`: stale (~46000s)
  - `temple-sanhedrin/automation/logs/loop.heartbeat`: fresh (~2s)
- Restart attempt blocked by sandbox policy:
  - `ssh ... localhost` => hostname resolve failure
  - `ssh ... 127.0.0.1` => `Operation not permitted`
- CI/email/VM checks access-blocked in sandbox:
  - `gh run list` cannot reach api.github.com
  - GitHub MCP calls returned cancelled
  - `outlook search` not authenticated (`outlook-auth` required)
  - Azure VM SSH (`52.157.85.234`) operation not permitted
- Policy parity/trust model checks: no drift detected in Trinity control docs.
