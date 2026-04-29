# temple-central.db Research Trigger Traceability Drift

Timestamp: 2026-04-30T01:22:31+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether research rows can be traced back to the builder CQ/IQ iteration that triggered them. It did not inspect live liveness, run QEMU/VM commands, execute WS8 networking work, or modify TempleOS / holyc-inference source.

SQL: `audits/trends/2026-04-30-research-trigger-traceability-drift.sql`

## Summary

The `research` table preserves useful topics and findings, but its trigger linkage is not reliable enough for long-window Law 5 / Law 6 reconstruction. All 444 rows have a non-empty `trigger_task`, yet 296 rows use composite or non-queue trigger text instead of one normalized CQ/IQ id. The 148 strict single CQ/IQ triggers do join to prior builder rows; the drift is concentrated in the 213 mixed queue-text rows and 83 non-queue rows that require custom parsing before they can be audited.

Findings: 5 total.

## Findings

### WARNING-1: `trigger_task` is free-form instead of a durable foreign key

Evidence:
- Research rows: 444.
- Strict single queue-shaped triggers: 148 rows.
- Mixed queue text such as comma/slash groups or prose: 213 rows.
- Non-queue trigger text such as `AUDIT` or `repeat-task>=3`: 83 rows.

Impact: historical reports cannot join research rows to `iterations` without per-report parsing rules. This weakens Law 5 evidence because research can look justified in prose while lacking a machine-checkable iteration source.

### INFO-2: Strict single CQ/IQ triggers join cleanly

Evidence:
- Strict single queue-shaped research rows: 148.
- Rows with no exact `iterations.task_id = research.trigger_task` match: 0.
- Rows with no prior exact match at research time: 0.
- Rows that only match a future iteration: 0.

Impact: this is the positive control for the backfill. Rows whose `trigger_task` is exactly one CQ/IQ id are already traceable; the remediation can preserve this path and focus on composite trigger rows.

### WARNING-3: Composite trigger rows need tokenization before they are useful

Evidence:
- Splitting research trigger text on common comma/slash/semicolon separators yields 613 CQ/IQ token mentions across 313 research rows.
- Those tokens cover 109 distinct task ids.
- 46 token mentions have no exact builder iteration task match.

Impact: downstream audit code must duplicate fragile string tokenization to recover lineage. A normalized `research_triggers(research_id, task_id)` table would preserve many-to-many links without losing the original trigger text.

### WARNING-4: Research burst patterns show retry-loop saturation

Evidence:
- 104 of 443 research rows after the first reuse the immediately previous `trigger_task`.
- 99 of those immediate repeats occur within 10 minutes.
- High-repeat trigger examples include `AUDIT` with 41 rows, `CQ-1223` with 10 rows, `IQ-990` with 10 rows, `CQ-1118` with 9 rows, and `CQ-914/IQ-878` with 9 rows.

Impact: repeated research can be legitimate during blocker mitigation, but without a normalized trigger and outcome field, historical trend reports cannot distinguish new research from another note on the same stuck trigger.

### INFO-5: The burst is time-localized and backfillable

Evidence:
- 433 of 444 research rows occur on 2026-04-21 and 2026-04-22.
- Those two days also contain 75 of the 76 rows with blank `references_urls`.
- Every research row has non-empty `findings` and `trigger_task`.

Impact: a conservative backfill is feasible. Start with the 148 strict single queue-shaped rows, then split composite trigger text into a join table while keeping the raw `trigger_task` field for audit context.

## Source Counts

| Metric | Count |
| --- | ---: |
| Research rows | 444 |
| Rows with blank trigger | 0 |
| Rows with blank references | 76 |
| Strict single queue-shaped trigger rows | 148 |
| Mixed queue-text trigger rows | 213 |
| Non-queue trigger rows | 83 |
| Strict single queue rows with no exact iteration match | 0 |
| CQ/IQ token mentions after splitting trigger text | 613 |
| Distinct CQ/IQ tokens after splitting | 109 |
| Immediate same-trigger repeats | 104 |
| Immediate same-trigger repeats under 10 minutes | 99 |

## Recommendations

- Add `research_triggers(research_id, task_id, agent, source)` and populate it alongside the existing raw `trigger_task`.
- Preserve composite trigger rows by splitting into one row per CQ/IQ token, while retaining the original string for review.
- Add an `outcome` or `applied_to_iteration_id` field so repeated research can be classified as new finding, duplicate mitigation, escalation, or follow-up.
- Treat `research.trigger_task` as human-readable context only until the normalized join table exists.

## Read-Only Verification Commands

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db '.schema research'
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-research-trigger-traceability-drift.sql
```
