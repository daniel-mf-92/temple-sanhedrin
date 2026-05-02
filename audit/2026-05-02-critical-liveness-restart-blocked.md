# CRITICAL — Builder loop liveness restart blocked

- Timestamp: 2026-05-02T07:22+0200
- TempleOS heartbeat age: >19h (`TempleOS/automation/logs/loop.heartbeat` updated 2026-05-01T11:29:33+0200)
- holyc-inference heartbeat age: >19h (`holyc-inference/automation/logs/loop.heartbeat` updated 2026-05-01T11:44:30+0200)
- sanhedrin heartbeat: healthy (<10s)
- Restart attempts made via required `ssh ... localhost` flow failed:
  - `Could not resolve hostname localhost`
  - `ssh 127.0.0.1 ...`: `Operation not permitted` (sandbox/network restriction)

Impact: both builder loops are currently non-live from Sanhedrin perspective and cannot be restarted from this runtime.
