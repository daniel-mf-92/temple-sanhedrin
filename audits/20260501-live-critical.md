# CRITICAL: builder loop liveness blocked

- TempleOS loop non-live: missing `automation/.codex-loop.lock/pid`, heartbeat stale.
- holyc-inference loop non-live: missing `automation/.codex-loop.lock/pid`, heartbeat stale.
- Restart attempt blocked in sandbox: `ssh 127.0.0.1` -> `Operation not permitted`.
- CI/API and VM checks blocked by network policy in this runtime.

Required host action: run the documented localhost SSH restart commands outside sandbox, then re-verify heartbeats < 600s.
