# Sanhedrin Critical Audit

- Time (UTC): 2026-05-01T16:09:36Z
- CRITICAL: Builder loop liveness failure.
- Heartbeat ages: TempleOS=23937s, holyc-inference=23040s, sanhedrin=5s (threshold 600s).
- Restart attempts failed:
- `ssh ... localhost ...`: could not resolve hostname localhost.
- `ssh ... 127.0.0.1 ...`: operation not permitted.
- Enforcement: `bash automation/enforce-laws.sh` => `0 violations`.
- Law 5 code-vs-docs signal: modernization `.HC/.sh` last 5 commits = 10; inference `.HC` last 5 commits = 2.
- Policy/profile/parity/attestation scans: no drift detected in controlling docs.
- CI and Azure VM checks blocked by network restrictions in this environment.
