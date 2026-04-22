# Sanhedrin Audit — 2026-04-22

Status: CRITICAL

- Law 5 violation (modernization): `git diff --stat HEAD~5 | grep -E '\.HC|\.sh' | wc -l` = 0.
- Law 5 warning (inference): `git diff --stat HEAD~5 | grep -E '\.HC' | wc -l` = 0.
- Loops alive with fresh heartbeats (<10 min).
- CI latest 3 runs: all success in both repos.
- Azure VM compile tests latest 5: all pass.
- Gmail failure-email query unavailable (missing MARTA_GOOGLE_CLIENT_ID/SECRET).
