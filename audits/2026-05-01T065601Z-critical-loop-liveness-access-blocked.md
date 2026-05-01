# CRITICAL: loop liveness failure

- Date (UTC): 2026-05-01
- Evidence:
  - `TempleOS/automation/loop.heartbeat` missing
  - `holyc-inference/automation/loop.heartbeat` missing
  - `temple-sanhedrin/automation/loop.heartbeat` missing
  - Loop log staleness: TempleOS=773385s, holyc-inference=773319s, sanhedrin=70385s
- Restart attempts:
  - `ssh localhost` restart attempted for all three loops; each failed with `Could not resolve hostname localhost: -65563`.
- Impact:
  - Law 7 liveness cannot be satisfied in current sandbox/session.
