# temple-central.db Validation Result Specificity Drift

Audit timestamp: 2026-05-01T11:25:18+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for whether historical builder validation rows preserve specific outcome evidence or collapse to generic success strings. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-validation-result-specificity-drift.sql`

## Summary

`iterations.validation_cmd` is rich enough to show what was attempted, but `iterations.validation_result` often discards the test identity and outcome detail. Across 2,919 builder rows, 2,385 rows (`81.7%`) use the exact generic result strings `ok` for inference or `exit 0` for modernization. The pattern is strongest in modernization, where 1,391 of 1,505 rows (`92.4%`) are exactly `exit 0`, despite 1,153 rows carrying QEMU evidence and 811 rows touching multiple files. Inference improved late in the window, but still has 994 of 1,414 rows (`70.3%`) recorded as exactly `ok`.

Findings: 5 total.

## Findings

### WARNING-1: Builder validation results are mostly generic success markers

Evidence:
- Combined builder rows: 2,919.
- Exact generic result rows: 2,385 (`81.7%`).
- Inference exact `ok` rows: 994 of 1,414 (`70.3%`).
- Modernization exact `exit 0` rows: 1,391 of 1,505 (`92.4%`).

Impact: `status='pass'` plus `validation_result='ok'` or `exit 0` proves only that some command returned success. It does not preserve which assertion, fixture, QEMU phase, or Law-specific guard actually passed, weakening retroactive Law 5 and Law 7 replay.

### WARNING-2: Modernization QEMU-heavy validation is under-described

Evidence:
- Modernization rows with QEMU evidence in command or result text: 1,153.
- Modernization rows with skip/unavailable language: 109.
- All 109 skip/unavailable rows also overlap QEMU evidence.
- Modernization rows with any timeout result evidence: 1.

Impact: many rows probably rely on scripts to enforce air-gap and VM safety, but the DB result does not consistently say whether the QEMU phase ran, skipped due to ISO availability, timed out, or passed. Historical audit has to reopen source/scripts instead of trusting the row-level evidence contract.

### WARNING-3: Multi-file work often has single-token validation outcomes

Evidence:
- Inference multi-file rows: 626; generic result multi-file rows: 416.
- Modernization multi-file rows: 811; generic result multi-file rows: 735.
- Combined generic multi-file rows: 1,151.

Impact: the rows most likely to need traceable validation detail are also commonly reduced to `ok` or `exit 0`. That makes it harder to connect changed surfaces to specific checks during retroactive commit audits.

### WARNING-4: Result vocabulary is compressed relative to command diversity

Evidence:
- Inference has 1,189 distinct validation commands but only 227 distinct validation results, a `0.19` result-per-command ratio.
- Modernization has 1,227 distinct validation commands but only 91 distinct validation results, a `0.07` result-per-command ratio.
- The most common inference result is `ok` with 994 rows; the most common modernization result is `exit 0` with 1,391 rows.

Impact: the database keeps enough command diversity to show that work varied, but result diversity does not scale with it. Trend analysis can count activity volume, but cannot reliably score evidence quality by task family without parsing command strings.

### INFO-5: The drift improved for inference but persisted for modernization

Evidence:
- Inference generic coverage peaked at 98.0% on 2026-04-18, then dropped to 29.0% on 2026-04-22 and 8.2% on 2026-04-23.
- Modernization recorded 100.0% generic results on 2026-04-15, 2026-04-16, and 2026-04-17, then still recorded 93.5% generic results on 2026-04-22 and 97.1% on 2026-04-23.

Impact: inference moved toward more specific pytest and named-check evidence late in the window, while modernization stayed dominated by `exit 0`. Future historical audits should score generic results as low-specificity evidence rather than noncompliance by themselves.

## Key Aggregates

| Agent | Rows | Exact generic rows | Generic coverage | Result has digit | Named-check rows | Passed rows | QEMU rows | QEMU skip/unavailable rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 994 | 70.3% | 356 | 170 | 262 | 0 | 0 |
| modernization | 1,505 | 1,391 | 92.4% | 1,502 | 11 | 8 | 1,153 | 109 |

| Agent | Unique validation commands | Unique validation results | Result/command ratio |
| --- | ---: | ---: | ---: |
| inference | 1,189 | 227 | 0.19 |
| modernization | 1,227 | 91 | 0.07 |

| Agent | Day | Rows | Generic rows | Generic coverage |
| --- | --- | ---: | ---: | ---: |
| modernization | 2026-04-17 | 143 | 143 | 100.0% |
| modernization | 2026-04-16 | 68 | 68 | 100.0% |
| modernization | 2026-04-15 | 31 | 31 | 100.0% |
| modernization | 2026-04-18 | 146 | 145 | 99.3% |
| inference | 2026-04-18 | 152 | 149 | 98.0% |
| modernization | 2026-04-23 | 34 | 33 | 97.1% |
| inference | 2026-04-17 | 157 | 148 | 94.3% |
| modernization | 2026-04-22 | 246 | 230 | 93.5% |
| inference | 2026-04-20 | 202 | 186 | 92.1% |
| modernization | 2026-04-20 | 225 | 205 | 91.1% |

## Recommendations

- Add a structured `validation_result_detail` convention for builder inserts, such as `tests=<n>; assertions=<n>; qemu_phase=<passed|skipped|timeout>; law_checks=<ids>`.
- Treat exact `ok` and `exit 0` as low-specificity evidence in retroactive scoring unless paired with specific named checks in `notes` or artifacts.
- For modernization QEMU-related rows, record whether the QEMU stage ran and whether the command line included `-nic none` and readonly image evidence in the row-level result or notes.
- Preserve the database read-only; this audit is evidence-quality scoring, not a request to mutate historical rows.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-validation-result-specificity-drift.sql
```

Finding count: 5 total, 4 warnings and 1 info.
