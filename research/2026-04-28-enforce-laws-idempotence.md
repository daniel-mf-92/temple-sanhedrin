# Enforce-laws idempotence: repeated LAW-4 detections

Trigger: `enforce-laws.sh` repeatedly reports the same TempleOS commit (`848ec83...`) as LAW-4 compounding even after Sanhedrin already removed the file.

Findings:
- Git hooks/policy checks should reject violations at commit/push time to avoid repeated post-hoc scans of old commits.
- GitHub rulesets can enforce push policies (including path/filename constraints) at repository/organization boundary.
- Current scanner increments violations on `ALREADY-CLEAN` history, which creates recurring false-positive noise.

Practical fix path:
- Treat `ALREADY-CLEAN` as non-violation (do not increment counter).
- Persist a resolved-commit ledger (or skip commits with matching resolved SHA in enforcement log) so remediated commits are not re-counted.
- Add a push-time guard (hook or ruleset) so compounding names are blocked before landing.

Sources:
- https://git-scm.com/docs/githooks
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
