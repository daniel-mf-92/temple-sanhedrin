# CRITICAL: Loop Liveness and Restart Access Failure

- Date: 2026-04-25
- Violation: all loop heartbeat files missing (`TempleOS`, `holyc-inference`, `temple-sanhedrin`).
- Log staleness: TempleOS `automation/codex-modernization-loop.log` ~268k s, holyc-inference `automation/codex-inference-loop.log` ~268k s, sanhedrin `automation/codex-sanhedrin-loop.log` ~27k s.
- Required restart action attempted for all three loops via `ssh -i ~/.ssh/id_localhost ... localhost`.
- Restart result: failed for all (`ssh: Could not resolve hostname localhost: -65563`).
- Process-list check is sandbox-blocked (`ps` not permitted), so heartbeat/log evidence used for liveness judgment.
- Severity: CRITICAL.
