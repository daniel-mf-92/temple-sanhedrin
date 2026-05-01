# CRITICAL Audit

- TempleOS heartbeat stale: `automation/logs/loop.heartbeat` (>10 min).
- holyc-inference heartbeat stale: `automation/logs/loop.heartbeat` (>10 min).
- Restart attempts blocked in this sandbox: `ssh localhost` unresolved, `ssh 127.0.0.1` operation not permitted, direct restart blocked by write restrictions in builder repos.
- Sanhedrin heartbeat is fresh.
- Policy/parity checks: secure-local default, quarantine/hash gates, IOMMU/Book-of-Truth, split-plane attestation/policy-digest language all present with no drift detected.
