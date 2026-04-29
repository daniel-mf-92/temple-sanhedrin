# temple-central.db Research Reference Quality Drift Audit

Timestamp: 2026-04-29T06:39:15+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only and did not inspect live liveness, start or restart processes, execute QEMU/VM commands, or modify TempleOS/holyc-inference source.

SQL: `audits/trends/2026-04-29-research-reference-quality-drift.sql`

## Summary

The `research` table contains 444 historical rows from 2026-04-15 through 2026-04-23. It is useful for proving that Sanhedrin reacted to repeat-task and stuck-loop patterns, but it is weak as a durable research ledger: 76 rows have no reference URL/path, only 1 row references a local artifact path, and 145 rows claim that a research artifact was added or created without storing a local artifact reference in `references_urls`.

Finding count: 5

## Findings

### WARNING-1: Research rows are often uncited

Evidence:
- `research` has 444 rows.
- 76 rows, or 17.1%, have blank `references_urls`.
- All rows have non-empty `trigger_task` and `findings`, so the missing data is specifically reference/provenance coverage.

Impact: deeper LAWS research and blocker-remediation guidance cannot always be traced to a source, local note, or committed artifact. This weakens retroactive confidence when research rows are used to justify Law 5 and Law 7 decisions.

### WARNING-2: Reference coverage degraded during the dense repeat-task period

Evidence:
- 2026-04-21 contains 273 research rows and 55 missing-reference rows.
- 2026-04-22 contains 160 research rows and 20 missing-reference rows.
- Those two days account for 433 of 444 research rows and 75 of 76 missing-reference rows.

Impact: the highest-volume research period is also where reference hygiene is weakest. Any trend conclusion about repeat-task-loop remediation from those days needs source-quality caveats.

### WARNING-3: Artifact claims are not linked to local artifact paths

Evidence:
- 145 rows contain `added` or `created` in `findings`.
- Only 1 research row has a `/Users/...` local path in `references_urls`.
- 145 artifact-claim rows lack a local artifact reference in `references_urls`.

Impact: a row can say a research note was created while the structured reference field does not identify the file. File-backed audits must search free text or repository history instead of joining through `research.references_urls`.

### WARNING-4: Repeat-task research is fragmented across near-duplicate topic spellings

Evidence:
- Normalized `repeat task streak remediation` appears 24 times across 3 topic variants, 16 trigger-task forms, and 4 missing-reference rows.
- `repeat task streak mitigation` appears 9 times across 3 variants.
- `repeat task streak breakers` appears 7 times across 2 variants.
- Multiple versioned variants, such as `repeat task streak remediation v33`, split related evidence into separate buckets.

Impact: topic-level aggregation overcounts novelty and undercounts repeated remediation loops unless every report performs custom normalization. That is Law 5-relevant because research meant to break busywork loops can itself become repeated bookkeeping.

### INFO-5: Most rows still have web references and actionable findings

Evidence:
- 360 rows include `http://` or `https://` references.
- 81 rows contain explicit `recommend` language.
- 8 non-empty reference fields are opaque rather than URL/local-path shaped.

Impact: the table is not unusable. It needs insertion-time normalization: required source/artifact references, topic canonicalization, and a separate `artifact_path` field for local research notes.

## Supporting Extracts

| Metric | Value |
| --- | ---: |
| Research rows | 444 |
| Missing references | 76 |
| URL-shaped references | 360 |
| Local artifact references | 1 |
| Opaque non-empty references | 8 |
| Artifact-claim rows | 145 |
| Artifact claims without local reference | 145 |

| Day | Rows | Topics | Missing refs |
| --- | ---: | ---: | ---: |
| 2026-04-21 | 273 | 220 | 55 |
| 2026-04-22 | 160 | 142 | 20 |
| 2026-04-23 | 1 | 1 | 0 |

## Recommendations

- Require `references_urls` to contain either at least one URL or a committed local artifact path for every new research row.
- Add `artifact_path`, `topic_canonical`, and `source_class` columns before using the table for long-window research-quality scoring.
- Normalize repeat-task/stuck-loop topics at insert time so remediation research can be counted by root cause instead of spelling/version variants.
- Backfill the 76 missing-reference rows only from committed research files or explicit source URLs, not from inference.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote service was added or enabled.
- No WS8 networking task was executed.
- No QEMU or VM command was run.
- No TempleOS or holyc-inference source code was modified.

## Read-Only Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema research'
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-research-reference-quality-drift.sql
```
