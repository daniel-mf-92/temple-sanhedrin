# temple-sanhedrin — NORTH STAR

This is the **single concrete deliverable** that defines "done" for the auditor loop.

## North Star

**Sanhedrin demonstrates teeth: detects and reverts violations, with audit trail.**

Concretely, the following must all be true:

1. `automation/enforce-laws.sh` runs every iteration
2. It detects:
   - **Identifier compounding** — new symbols / filenames longer than 40 chars OR with >5 hyphen-separated tokens
   - **Self-generated CQs** — a commit that adds new `CQ-` or `IQ-` lines to MASTER_TASKS.md (queue self-padding)
   - **Repeated blockers** — same error string recurring across >3 consecutive iteration logs
3. On detection, it `git revert --no-commit <sha>` on the offending repo + commits the revert with `revert: sanhedrin enforcement (LAW-X violation)` + force-push not allowed (regular push)
4. Each enforcement action appends one line to `audits/enforcement.log` with sha, repo, law, timestamp
5. `automation/north-star-e2e.sh` checks: at least 1 enforcement action in last 24h OR explicit "no violations detected — clean run" lines in the log

## Why this North Star

The previous mode was rubber-stamp observation. Real auditing means having and using authority to revert. This makes Sanhedrin a forcing function on the builders, not a passive logger.

## Status

RED until first enforcement action lands.
