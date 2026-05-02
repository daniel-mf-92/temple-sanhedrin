# CRITICAL: Builder liveness degraded

- Timestamp (UTC): 2026-05-02T06:42:00Z
- TempleOS heartbeat age: 76162s (>600s)
- holyc-inference heartbeat age: 75265s (>600s)
- Sanhedrin heartbeat age: 5s
- Required SSH restart path blocked in sandbox (`ssh localhost` not permitted), so restart could not be executed from this run.

Impact: both builder loops appear stale/dead from heartbeat telemetry, preventing fresh iterations.
