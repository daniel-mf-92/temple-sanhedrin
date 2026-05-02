# temple-central.db Research Topic Normalization Churn

Audit timestamp: 2026-05-02T00:09:56Z

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for topic churn in the `research` table. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-research-topic-normalization-churn.sql`

## Summary

The research ledger is overwhelmingly concentrated in repeat-task, stuck-loop, loop, and streak topics: 426 of 444 rows, or 95.9%. The concentration itself is understandable because Sanhedrin was diagnosing builder loop pathologies, but the topic strings splinter into many near-duplicate families and version suffixes. This weakens Law 5 and Law 7 backfills because repeated research rows look like separate investigations instead of one normalized case thread with updates.

Findings: 5 warnings.

## Findings

### WARNING-1: Repeat/stuck-loop research dominates the table

Evidence:
- Total research rows: 444.
- Repeat/stuck-loop classified rows: 426, or 95.9%.
- Blank-reference rows inside that class: 74.
- Blank-reference rows outside that class: 2.

Impact: Research became heavily operational-loop focused. That is valid in context, but long-window reports should not treat row count as breadth of deep LAWS.md research; most rows belong to one broad loop-remediation theme.

### WARNING-2: Near-duplicate topic families split one remediation thread

Evidence:
- `repeat-task-streak-*`: 49 rows across 12 distinct topic strings and 36 distinct triggers.
- `repeat-task-streak-remediation-v*`: 43 rows across 29 distinct topic strings and 29 distinct triggers.
- `repeat-task-loop-*`: 31 rows across 22 distinct topic strings.
- `stuck-loop-*`: 24 rows across 21 distinct topic strings.

Impact: The table lacks a stable `case_id` or normalized topic key. A historical auditor must collapse spelling variants, hyphen/space variants, and semantic variants before deciding whether Sanhedrin produced new research or repeated the same research under a new title.

### WARNING-3: Version-suffixed research topics create artificial uniqueness

Evidence:
- Versioned topic rows matching `*-v[0-9]*`: 146.
- Distinct versioned topic strings: 121.
- Versioned rows span `2026-04-21T02:10:01` through `2026-04-22T10:27:35`.
- Examples include `repeat-task-streak-remediation-v33`, `repeat-task-streak-remediation-v34`, `repeat-task-streak-remediation-v35`, and `repeat-task-streak-breakers-v76`.

Impact: Version suffixes can be useful for artifacts, but as database topics they defeat grouping. They should be stored as a revision field on a stable topic/case, not embedded in the primary grouping string.

### WARNING-4: Research burst rate suggests repeated re-documentation

Evidence:
- 2026-04-21 records 273 research rows, 269 of them repeat/stuck-loop related, with 55 blank references.
- 2026-04-22 records 160 research rows, 151 of them repeat/stuck-loop related, with 20 blank references.
- The busiest hour, `2026-04-21T21:00:00`, has 27 research rows, all repeat/stuck-loop related, across 23 distinct topics and 18 distinct triggers.

Impact: High-volume research bursts may reflect active mitigation, but without normalized case linkage they resemble Law 5 busywork from the ledger alone. The table needs to distinguish new evidence from updates to an existing remediation case.

### WARNING-5: Same trigger tasks fan out into many research topic strings

Evidence:
- Trigger `AUDIT`: 40 repeat/stuck-loop rows across 36 distinct topics, 15 blank references.
- Trigger `CQ-1223`: 10 rows across 10 distinct topics.
- Trigger `IQ-990`: 9 rows across 8 distinct topics, 3 blank references.
- Adjacent rows reused the same `trigger_task` 104 times, but only 11 of those adjacent pairs reused the exact same topic.

Impact: `trigger_task` is not enough to reconstruct a remediation thread. The same trigger can emit many differently named rows, forcing later Law 7 analysis to infer dedupe state from prose rather than a structured case/update model.

## Key Aggregates

| Metric | Count |
| --- | ---: |
| Research rows | 444 |
| Repeat/stuck-loop rows | 426 |
| Repeat/stuck-loop rows with blank references | 74 |
| Versioned topic rows | 146 |
| Distinct versioned topics | 121 |
| Adjacent same-trigger rows | 104 |
| Adjacent same-trigger rows with exact same topic | 11 |

| Day | Research Rows | Repeat/Stuck-Loop Rows | Blank References |
| --- | ---: | ---: | ---: |
| 2026-04-15 | 1 | 0 | 0 |
| 2026-04-16 | 1 | 0 | 0 |
| 2026-04-17 | 1 | 1 | 1 |
| 2026-04-19 | 4 | 2 | 0 |
| 2026-04-20 | 3 | 2 | 0 |
| 2026-04-21 | 273 | 269 | 55 |
| 2026-04-22 | 160 | 151 | 20 |
| 2026-04-23 | 1 | 1 | 0 |

## Recommendations

- Add `research_case_id`, `normalized_topic`, and `revision` fields instead of encoding revisions in `topic`.
- Store repeat-task and stuck-loop mitigations as case updates until the trigger set, finding, or evidence source materially changes.
- Require a reference URL or committed artifact path for every research row that is not explicitly a short case update.
- For Law 5 scoring, count unique normalized cases and material updates separately from raw research row count.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-research-topic-normalization-churn.sql
```

Finding count: 5 warning findings.
