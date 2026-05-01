# CRITICAL: Liveness regression

- `automation/enforce-laws.sh`: `0 violations`.
- Builder loop heartbeats stale (`TempleOS` and `holyc-inference` > 10 minutes).
- Required restart via `ssh localhost` failed (`Could not resolve hostname localhost`).
- Policy/parity checks pass (`secure-local`, quarantine/hash, IOMMU/Book of Truth, trinity parity, split-plane attestation/policy digest).
- CI/email/Azure checks blocked in this environment (network/API/auth/SSH restrictions).
