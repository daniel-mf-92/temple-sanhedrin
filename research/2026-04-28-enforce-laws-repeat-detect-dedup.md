# Enforce-laws repeated LAW-4 detect on already-clean SHA

Date: 2026-04-28
Trigger: repeated `LAW-4-compounding` detect+`ALREADY-CLEAN` on the same TempleOS commit (`6c0c561...`) across consecutive Sanhedrin iterations.

## Findings
- The current detector scans the last 5 commits each run and increments `violations_found` before checking whether any file was actually removed; this causes repeated warning noise when a violating commit remains in the recent window but offending files are already absent.
- Industry pattern: make repeated operations idempotent by storing a processed key and short-circuiting duplicate handling.
- CI/automation pattern: deduplicate repeated work at source using explicit concurrency/dedup keys per branch/ref.

## Recommended patch shape
- Add an `audits/enforced-shas.log` ledger keyed by `<repo>:<sha>:<law>:<action>`.
- On detection, skip counting/logging as a new violation if a prior `ALREADY-CLEAN` or `REVERT` marker exists for the same key.
- Increment `violations_found` only when a new enforcement action is taken (`RM`, `REVERT`, `REVERT-CONFLICT`) or first-time unresolved violation is seen.
- Keep one periodic reminder for unresolved items (e.g., every 12h), not every loop.

## References
- GitHub Docs: workflow/run semantics and per-ref execution model: https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows
- Idempotency design principle overview: https://hackernoon.com/how-to-fix-duplicate-api-requests-understanding-idempotency
