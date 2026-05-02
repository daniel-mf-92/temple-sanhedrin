# CRITICAL: Builder liveness restart blocked

- Evidence: builder loop locks/logs stale >10m (TempleOS, holyc-inference).
- Restart attempt via required SSH path failed (`localhost` unresolved; `127.0.0.1` SSH op not permitted in sandbox).
- Enforcement: `bash automation/enforce-laws.sh` => `enforce-laws: 0 violations`.
- Policy checks: secure-local/quarantine/IOMMU/Book-of-Truth and Trinity parity terms present; no drift signal found.
- CI/VM/email checks blocked by environment (`api.github.com` unreachable, external SSH blocked, Outlook not authenticated).
