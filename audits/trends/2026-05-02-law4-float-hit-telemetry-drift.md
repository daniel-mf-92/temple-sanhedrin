# Law 4 Float-Hit Telemetry Drift

Audit timestamp: 2026-05-02T08:24:52+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for Sanhedrin `AUDIT` rows that mention Law 4 float-hit scans. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-law4-float-hit-telemetry-drift.sql`

## Summary

Sanhedrin recorded Law 4 float-hit evidence in 773 historical `AUDIT` rows from 2026-04-12 through 2026-04-23, but the signal is not a stable structured metric. Some rows use prose such as `Law4 float hits=66`, some use `law4_float_hits=<number>`, and later rows sometimes replace the count with text such as `info-present`. This does not prove an inference integer-purity violation; it is a telemetry drift finding that can make historical Law 4 dashboards drop evidence, misparse an informational scanner count, or treat parser artifacts as real violations.

## Findings

### WARNING-1: Law 4 float-hit evidence has two incompatible shapes

- Evidence: 773 Sanhedrin `AUDIT` rows mention Law 4 float-hit evidence.
- Direct `law4_float_hits=` key/value rows: 406.
- Other prose shapes: 367.
- First observed Law 4 float row: `2026-04-12T14:30:07`.
- Latest observed Law 4 float row: `2026-04-23T11:54:25`.

Impact: a trend query that expects `law4_float_hits=` silently excludes 367 rows, while a prose scan cannot safely extract numeric counts.

### WARNING-2: The migration to key/value form was partial, not clean

- On 2026-04-21, the DB has 192 prose rows and 2 key/value rows.
- On 2026-04-22, it has 115 prose rows and 301 key/value rows.
- On 2026-04-23, it still has 1 prose row and 100 key/value rows.

Impact: date-bucketed Law 4 trend lines can show an apparent drop or jump because the telemetry format changed, not because the underlying inference source surface changed.

### WARNING-3: Some key/value rows are not numeric

- Among 406 `law4_float_hits=` rows, 382 start with a numeric value and 24 start with text.
- Representative textual values include `info_present`, `present(info)`, `info-present`, `info(existing metadata readers)`, and `present(info-existing)`.

Impact: scripts that cast `law4_float_hits` directly to an integer will convert text-headed evidence to `0` in SQLite-style parsing, creating false "no float hits" buckets.

### WARNING-4: One key/value row has a parser-hostile numeric outlier

- Row `11590` at `2026-04-21T19:24:20` records `Law4_float_hits=1222`.
- Nearby historical counts are in the range 95, 98, 101, 105, 108, 109, and 110.
- The outlier appears inside a compact packed note with adjacent Law 2 and Law 6 metrics, so it should be treated as delimiter/recording drift unless a raw source scan proves 1,222 actual hits.

Impact: long-window dashboards that alert on high float-hit count could report a spurious Law 4 spike.

### WARNING-5: Law 4 scanner counts are informational but not classified as such structurally

- Many snippets mark the float-hit count as `info`, `scan-only`, `info-existing`, or `existing metadata readers`.
- The DB has no structured fields for `law_id`, `metric_name`, `metric_value`, `metric_kind`, or `severity`.

Impact: integer-purity compliance scoring cannot distinguish a known informational GGUF metadata/type-name surface from a runtime tensor float violation without reparsing prose and re-scanning current or historical source.

## Evidence Tables

| Metric | Value |
|---|---:|
| Law 4 float evidence rows | 773 |
| Key/value rows | 406 |
| Prose/other rows | 367 |
| Numeric-headed key/value rows | 382 |
| Text-headed key/value rows | 24 |
| Parsed numeric values observed | 20, 57, 95, 98, 101, 105, 107, 108, 109, 110, 1222 |

| Parsed value | Rows | First timestamp | Last timestamp |
|---:|---:|---|---|
| 20 | 5 | 2026-04-22T06:33:51 | 2026-04-23T02:43:55 |
| 57 | 1 | 2026-04-17T19:59:54 | 2026-04-17T19:59:54 |
| 95 | 2 | 2026-04-18T06:16:52 | 2026-04-19T21:24:38 |
| 98 | 1 | 2026-04-21T16:38:35 | 2026-04-21T16:38:35 |
| 101 | 81 | 2026-04-22T05:24:20 | 2026-04-22T08:09:17 |
| 105 | 100 | 2026-04-22T08:16:37 | 2026-04-22T11:42:57 |
| 108 | 104 | 2026-04-22T08:11:06 | 2026-04-23T01:03:15 |
| 109 | 83 | 2026-04-23T01:08:39 | 2026-04-23T11:26:52 |
| 110 | 3 | 2026-04-23T11:35:30 | 2026-04-23T11:54:25 |
| 1222 | 1 | 2026-04-21T19:24:20 | 2026-04-21T19:24:20 |

## Recommendations

- Store Law 4 float scan output as structured audit metrics: `law_id`, `scanner`, `hit_count`, `scope`, `classification`, and `severity`.
- Split `metadata/type-name float references` from `runtime tensor float operations`; only the latter should score as Law 4 violation candidates.
- Reject nonnumeric `law4_float_hits` at insertion time, and put explanatory labels in a separate field such as `classification=info_existing_metadata`.
- Treat row `11590` as telemetry-quality warning until a source scan confirms or disproves the 1,222-hit value.
