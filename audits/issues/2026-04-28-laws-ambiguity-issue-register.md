# Local Issue Register: LAWS Ambiguity Research

Timestamp: 2026-04-27T23:04:40Z

Source audit: `audits/research/2026-04-28-laws-numbering-and-enforcement-ambiguities.md`

These are local issue records for follow-up by the Sanhedrin/human doctrine owner. No GitHub issue was created from this sandboxed audit iteration.

## ISSUE-LAWS-001: Stable law ids

Problem: `LAWS.md` reuses Law 4, Law 5, Law 6, and Law 7 for later appended rules.

Impact: Audit reports and enforcement logs that cite only a law number are ambiguous.

Proposed resolution: Add immutable ids such as `LAW-04-INTEGER-RUNTIME` and `LAW-12-NAME-COMPOUNDING`, with old number headings retained only as aliases.

## ISSUE-LAWS-002: Enforcement coverage declaration

Problem: `LAWS.md` describes revert enforcement, but `automation/enforce-laws.sh` only scans the last 5 commits on selected branches.

Impact: Builders and auditors can overstate what is automatically enforced.

Proposed resolution: Require every enforcement report to declare branch selection, commit window, and which law clauses are mechanically checked.

## ISSUE-LAWS-003: Suffix-chain measurement

Problem: The identifier compounding rule forbids "existing-name + suffix", but current builder checkers only enforce length, token count, and long function-like identifiers.

Impact: The most important anti-pattern remains judgment-only and can be scored differently by different auditors.

Proposed resolution: Define a parent-tree identifier comparison rule, allowed suffix table, and a maximum suffix stack depth.

## ISSUE-LAWS-004: Host automation scope matrix

Problem: Law 1 permits host-side automation languages, but Laws 2, 10, and 11 still constrain host scripts that launch QEMU or persist serial/Book-of-Truth evidence.

Impact: The host-tooling exception can be misread as a broad safety exception.

Proposed resolution: Add a per-law scope matrix for core code, host automation, tests, docs, and generated artifacts.

## ISSUE-LAWS-005: Retroactive liveness audit boundary

Problem: Law 7 process liveness is live-state oriented, while the gpt-5.5 sibling scope forbids live liveness watching.

Impact: Retroactive audit reports can appear incomplete unless they state the liveness evidence boundary.

Proposed resolution: Define that retroactive Law 7 audits use historical heartbeat/log/process snapshots only and do not perform current process watching.
