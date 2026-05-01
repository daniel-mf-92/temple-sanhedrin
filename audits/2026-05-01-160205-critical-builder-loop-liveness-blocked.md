# CRITICAL: builder loops stale and restart blocked

- Timestamp: 2026-05-01T14:02:11Z
- TempleOS heartbeat age: 16326s (>10m)
- holyc-inference heartbeat age: 15429s (>10m)
- temple-sanhedrin heartbeat age: 5s
- `ps` check blocked by sandbox (`operation not permitted`).
- Required restart channel blocked: `ssh localhost/127.0.0.1` not permitted.
- Direct restart fallback blocked by sandbox cross-repo log write permissions.

## Other checks
- Recent builder DB activity: latest entries are pass-only but stale (`2026-04-23`).
- Law 5 code output: TempleOS last5 `.HC|.sh`=10 (pass), inference last5 `.HC`=2 (pass).
- Law 1 non-HolyC core files: 0.
- Law 2 network diff hits (TempleOS HEAD~3): 0.
- Law 4 float markers in inference src: 111 (info-only lexical hits).
- Trinity secure-local/GPU/attestation policy language present in all control docs; no drift signal found.
- CI checks blocked (`gh` cannot reach api.github.com), email check blocked (`outlook` unauthenticated), VM compile check blocked (ssh operation not permitted).
