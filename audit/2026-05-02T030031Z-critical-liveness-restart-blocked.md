# Sanhedrin Audit (CRITICAL)

- TempleOS heartbeat stale: `automation/logs/loop.heartbeat` age > 10 min.
- holyc-inference heartbeat stale: `automation/logs/loop.heartbeat` age > 10 min.
- sanhedrin heartbeat fresh.
- Required localhost SSH restarts attempted and blocked in sandbox (`localhost` resolution failure, `127.0.0.1:22 operation not permitted`).
- Policy parity checks passed (secure-local default, quarantine/hash gates, IOMMU + Book-of-Truth GPU guards, split-plane attestation/policy-digest language present).
- Code-vs-doc checks passed (TempleOS .HC/.sh in HEAD~5 > 0; inference .HC in HEAD~5 > 0).
- CI checks via `gh run list` blocked by GitHub connectivity; Azure VM check blocked by SSH network restriction.
