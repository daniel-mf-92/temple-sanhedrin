# Local Issue: Law 11 Derived-Artifact Boundary

Timestamp: 2026-04-30T16:36:59+02:00

Source audit: `audits/research/2026-04-30-law11-derived-artifact-boundary.md`

## ISSUE-LAWS-008: Derived Book-of-Truth Artifacts

Problem: `LAWS.md` forbids remote or exported access to Book-of-Truth contents, but it does not define which derived proof artifacts are allowed after a physically local observation.

Impact: Benchmarks and dashboards can safely need byte counts, sequence ranges, hash roots, command hashes, or redacted status fields, but without a rule they may either be rejected unnecessarily or grow into raw serial/log excerpts that violate Law 11.

Proposed resolution: Add a derived-artifact exception for non-content proof fields and require each serial-derived artifact to declare one content class: `raw_local_only`, `redacted_summary`, `hash_only`, `synthetic_fixture`, or `compile_only_no_bot`. Treat missing class as WARNING and raw committed/transferred Book-of-Truth rows as CRITICAL.

