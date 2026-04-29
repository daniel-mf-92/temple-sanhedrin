# temple-central.db Files-Changed Delimiter Drift

Audit timestamp: 2026-04-29T09:21:40+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for `iterations.files_changed` serialization consistency across the modernization and inference builder rows. It did not inspect live liveness, run QEMU or VM commands, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Query pack: `audits/trends/2026-04-29-files-changed-delimiter-drift.sql`
- Builder window: 2026-04-12 through 2026-04-23
- LAWS.md focus: historical auditability for Law 1 source-surface scans, Law 5 work classification, Law 6 queue traceability, and Law 7 evidence reliability.

## Findings

1. WARNING - `files_changed` uses two incompatible list delimiters.
   - Evidence: inference has 626 comma-delimited rows and 724 semicolon-delimited rows; modernization has 811 comma-delimited rows and 476 semicolon-delimited rows.
   - Impact: any historical audit that splits only on comma treats 1,200 builder rows as single-file or under-split records, even when they include core source, tests, automation, and task-file changes.

2. WARNING - comma-only parsing undercounts 1,963 changed-file tokens.
   - Evidence: inference has 3,873 file tokens when comma and semicolon are both accepted, but only 2,574 tokens under comma-only parsing, a 1,299-token miss. Modernization has 3,430 dual-delimiter tokens versus 2,766 comma-only tokens, a 664-token miss.
   - Impact: Law 1/Law 5/Law 6 backfills can undercount core HolyC changes, test coverage, and task-file touches if they consume `files_changed` without delimiter normalization.

3. WARNING - semicolon-delimited rows carry high-value evidence, not fringe metadata.
   - Evidence: semicolon rows include 641 inference core-source rows, 676 inference test rows, 680 inference `MASTER_TASKS.md` rows, 157 modernization core-source rows, 424 modernization automation rows, and 432 modernization task-file rows.
   - Impact: a parser defect here changes the compliance classification of meaningful implementation and validation rows, not just display formatting.

4. WARNING - semicolon rows account for substantial churn.
   - Evidence: inference semicolon rows add 200,569 lines versus 188,451 comma-row additions. Modernization semicolon rows add 114,060 lines and remove 270 lines.
   - Impact: churn-based trend reports can misattribute large implementation periods to one-file changes unless they normalize separators before grouping by path type.

5. INFO - the delimiter drift is persistent across the full stored builder window.
   - Evidence: every active builder day from 2026-04-12 through 2026-04-23 contains semicolon rows for both agents. The peak day is 2026-04-21 with 120 inference semicolon rows and 88 modernization semicolon rows.
   - Impact: this is a systemic ingestion/serialization convention drift, not an isolated malformed record.

## Supporting Extracts

| Agent | Rows | First ts | Last ts | Comma rows | Semicolon rows | Single/unsplit rows | Unique strings |
| --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| inference | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | 626 | 724 | 64 | 1,134 |
| modernization | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | 811 | 476 | 218 | 951 |

| Agent | Comma-only tokens | Comma-or-semicolon tokens | Tokens missed by comma-only | Semicolon-only rows |
| --- | ---: | ---: | ---: | ---: |
| inference | 2,574 | 3,873 | 1,299 | 724 |
| modernization | 2,766 | 3,430 | 664 | 476 |

| Agent | Semicolon core rows | Semicolon test rows | Semicolon automation rows | Semicolon task rows |
| --- | ---: | ---: | ---: | ---: |
| inference | 641 | 676 | 0 | 680 |
| modernization | 157 | 0 | 424 | 432 |

| Agent | Delimiter class | Rows | Lines added | Lines removed | Avg added |
| --- | --- | ---: | ---: | ---: | ---: |
| inference | comma | 626 | 188,451 | 147 | 301.0 |
| inference | semicolon | 724 | 200,569 | 146 | 277.0 |
| inference | single/unsplit | 64 | 1,023 | 1 | 16.0 |
| modernization | comma | 811 | 170,380 | 100 | 210.1 |
| modernization | semicolon | 476 | 114,060 | 270 | 239.6 |
| modernization | single/unsplit | 218 | 38,120 | 3 | 174.9 |

## Recommendations

- Normalize `files_changed` at ingestion time as JSON array text or a child table, not a free-form delimiter string.
- Until ingestion changes, every trend/backfill query should split on both comma and semicolon, trim whitespace, and reject mixed delimiters if they appear later.
- Add a typed path-class projection for `core_holyc`, `test`, `automation`, `task_file`, `doc`, and `unknown` so Law 1/Law 5/Law 6 reports do not depend on ad hoc path parsing.
- Preserve the raw `files_changed` string for forensics, but make dashboards consume normalized path rows first.

## Read-Only Verification

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-files-changed-delimiter-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
