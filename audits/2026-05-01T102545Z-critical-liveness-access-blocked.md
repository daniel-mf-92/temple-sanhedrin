# CRITICAL: Liveness Access Blocked

- TempleOS and holyc-inference heartbeats are stale (>10 min).
- Restart path via `ssh localhost`/`127.0.0.1` is blocked in this sandbox (`operation not permitted`).
- Equivalent local restart attempt also failed due cross-repo log redirection permission.
- CI (`gh run list`) and Azure VM probe are also blocked by network restrictions in this sandbox.
