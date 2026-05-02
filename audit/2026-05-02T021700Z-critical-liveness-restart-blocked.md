# CRITICAL: Builder Loop Liveness Failure

- Timestamp (UTC): 2026-05-02T02:15:33Z
- TempleOS loop heartbeat age: 60436s (>600s threshold)
- holyc-inference loop heartbeat age: 59539s (>600s threshold)
- Restart attempts failed:
  - `ssh localhost`: `Could not resolve hostname localhost: -65563`
  - `ssh 127.0.0.1`: `connect to host 127.0.0.1 port 22: Operation not permitted`
- Effect: both builder loops are dead/stalled and cannot be revived from current sandbox.
