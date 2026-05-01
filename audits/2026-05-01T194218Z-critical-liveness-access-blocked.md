# CRITICAL: Builder loop liveness blocked

- TempleOS heartbeat stale (>10 min): `automation/logs/loop.heartbeat`.
- holyc-inference heartbeat stale (>10 min): `automation/logs/loop.heartbeat`.
- sanhedrin heartbeat fresh.
- `ps` liveness check blocked in sandbox (`operation not permitted`).
- Required restart path via `ssh localhost` blocked (`Could not resolve hostname localhost: -65563`; `127.0.0.1:22 operation not permitted`).
- Equivalent local `nohup` restart blocked by write restrictions on target repo logs.
- Policy parity checks: PASS (secure-local default, quarantine/hash gates, IOMMU + Book-of-Truth GPU hooks, split-plane trust + attestation/policy-digest language present).
- CI checks blocked (no network to `api.github.com`); email check blocked (Outlook CLI unauthenticated); Azure VM compile check blocked (SSH egress not permitted).
