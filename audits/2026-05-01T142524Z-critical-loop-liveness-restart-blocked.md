# CRITICAL audit

- TempleOS and holyc-inference loop heartbeats are stale (>10 minutes).
- Sanhedrin heartbeat is fresh.
- Required localhost SSH restart path failed (`localhost` unresolved, `127.0.0.1:22` operation not permitted).
- Direct restart fallback also blocked by sandbox write restrictions on target repo logs.

