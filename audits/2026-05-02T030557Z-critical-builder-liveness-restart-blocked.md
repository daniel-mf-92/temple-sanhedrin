# Critical Audit
- ts: 2026-05-02T03:05:57Z
- issue: builder loop liveness critical
- details: TempleOS and holyc-inference heartbeats are stale (>10m), and restart attempt via ssh localhost failed (hostname resolution error).
- action: manual host SSH/local resolver fix required, then restart automation/codex-modernization-loop.sh and automation/codex-inference-loop.sh
