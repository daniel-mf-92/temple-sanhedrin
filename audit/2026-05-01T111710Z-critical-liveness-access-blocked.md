# Sanhedrin Audit (CRITICAL)

- Date (UTC): 2026-05-01T11:16:59Z
- enforce-laws: `0 violations`
- Liveness: CRITICAL
  - TempleOS heartbeat stale `6385s` (`automation/logs/loop.heartbeat`)
  - holyc-inference heartbeat stale `5488s` (`automation/logs/loop.heartbeat`)
  - sanhedrin heartbeat fresh `1s`
- Restart attempts: blocked by sandbox (`ssh 127.0.0.1 port 22: Operation not permitted`)
- Code-vs-docs: pass (`TempleOS .HC/.sh last5=10`, `inference .HC last5=2`, `inference .HC/.sh/.py last5=7`)
- Trinity/policy/parity checks: pass (secure-local default, quarantine/hash, IOMMU+Book-of-Truth, attestation/policy-digest language present)
- CI status check: blocked (`gh` cannot reach `api.github.com`)
- GitHub email failure check: blocked (`outlook` not authenticated)
- Azure compile VM check: blocked (`ssh ...52.157.85.234: Operation not permitted`)
