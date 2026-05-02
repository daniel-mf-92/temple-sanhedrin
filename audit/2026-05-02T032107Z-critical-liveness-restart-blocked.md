# Sanhedrin Critical Audit

- CRITICAL: Builder liveness failed.
- TempleOS heartbeat age: 64201s (`automation/logs/loop.heartbeat`).
- holyc-inference heartbeat age: 63304s (`automation/logs/loop.heartbeat`).
- sanhedrin heartbeat age: 1s.
- Restart attempts failed in sandbox:
  - `ssh ... localhost`: hostname resolution failed.
  - `ssh ... 127.0.0.1`: port 22 operation not permitted.
- Policy parity/security checks: no drift detected.
- CI, email, VM checks blocked by environment restrictions.
