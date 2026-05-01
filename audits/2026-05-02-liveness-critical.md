# CRITICAL: Builder Loop Liveness Blocked (2026-05-02)

- TempleOS heartbeat stale (>10 min): `automation/logs/loop.heartbeat`
- holyc-inference heartbeat stale (>10 min): `automation/logs/loop.heartbeat`
- Restart via `ssh localhost` failed (`Could not resolve hostname localhost` / `Operation not permitted`).
- Local fallback restart for builder loops blocked by sandbox write restrictions outside `temple-sanhedrin`.
- Policy/trinity checks: no drift detected.
- Law 5 output check: pass (`TempleOS .HC/.sh last5=10`, `inference .HC last5=2`).
