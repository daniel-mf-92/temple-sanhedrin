# CRITICAL: Builder loop liveness

- Timestamp (local): 2026-05-02T01:33:25+0200
- `TempleOS` heartbeat stale: 2026-05-01T11:29:33+0200 (>10m)
- `holyc-inference` heartbeat stale: 2026-05-01T11:44:30+0200 (>10m)
- `temple-sanhedrin` heartbeat fresh
- Restart attempts blocked in this environment:
  - `ssh ... localhost`: `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1`: `connect to host 127.0.0.1 port 22: Operation not permitted`

Impact: both builder loops appear dead and could not be restarted from this sandbox.
