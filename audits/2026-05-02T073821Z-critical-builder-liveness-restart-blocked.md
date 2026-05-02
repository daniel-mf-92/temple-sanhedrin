# CRITICAL — builder liveness restart blocked

- TempleOS heartbeat stale >10m (`automation/logs/loop.heartbeat`, age ~79685s).
- holyc-inference heartbeat stale >10m (`automation/logs/loop.heartbeat`, age ~78788s).
- sanhedrin heartbeat fresh (~3s).
- Required localhost restart attempts failed: `ssh: Could not resolve hostname localhost: -65563`.

Secondary checks (non-blocking):
- `enforce-laws`: `0 violations`.
- Recent builder DB rows: both agents `pass`, with code-producing file changes.
- Law 1/2/4 checks: no non-HolyC core files, no network diff hits, float refs informational only.
- Policy parity/profile/GPU/attestation digest checks: no drift detected.
- CI + Azure VM checks blocked in sandbox/network context.
