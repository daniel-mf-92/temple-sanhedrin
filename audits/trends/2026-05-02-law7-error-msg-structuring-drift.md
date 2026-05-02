# Law 7 Structured Error Message Drift

Audit timestamp: 2026-05-02T05:12:47+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only to test whether Law 7 blocker escalation can use structured `iterations.error_msg` values for repeated-error detection. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-law7-error-msg-structuring-drift.sql`

## Summary

The central database contains 97 historical `fail` or `blocked` iteration rows, all from Sanhedrin, and every one has an empty structured `error_msg`. Law 7 explicitly depends on recognizing the same error string across consecutive iterations, but the only nonpass evidence is stored in prose `notes`. A structured-error implementation would find zero repeated-error windows even when notes contain repeated CI and VM blocker narratives.

Findings: 5 warnings.

## Findings

### WARNING-1: Every nonpass row lacks structured `error_msg`

Evidence:

- Nonpass rows: 97.
- Rows missing `error_msg`: 97.
- Missing structured-error rate: 100.00%.
- Rows missing `validation_result`: 97.
- Rows missing `notes`: 0.

Impact: the database has human-readable failure prose, but it does not have machine-stable error strings for Law 7 escalation. Any detector that reads only `error_msg` would conclude there are no repeatable errors to group.

### WARNING-2: The blind spot covers both `fail` and `blocked`

Evidence:

| Status | Rows | Missing `error_msg` | Missing rate |
| --- | ---: | ---: | ---: |
| `fail` | 94 | 94 | 100.00% |
| `blocked` | 3 | 3 | 100.00% |

Impact: blocked operational paths are affected as much as outright failures. This matters because Law 7 examples include repeated operational blockers such as "readonly database" and "command not found", not only failing tests.

### WARNING-3: Highest-volume nonpass task buckets collapse to a single blank error key

Evidence:

| Agent | Status | Task ID | Rows | Distinct `error_msg` | Distinct `notes` |
| --- | --- | --- | ---: | ---: | ---: |
| `sanhedrin` | `fail` | `CI-TEMPLEOS` | 43 | 1 | 31 |
| `sanhedrin` | `fail` | `AUDIT` | 31 | 1 | 31 |
| `sanhedrin` | `fail` | `VM-COMPILE` | 10 | 1 | 10 |
| `sanhedrin` | `fail` | `VM-CHECK` | 5 | 1 | 5 |
| `sanhedrin` | `blocked` | `VM-COMPILE` | 3 | 1 | 2 |

Impact: `COUNT(DISTINCT error_msg)` reports one value per bucket only because the value is blank. The meaningful variation is trapped in `notes`, so blocker recurrence cannot be normalized without brittle text parsing.

### WARNING-4: Structured repeat detection returns no Law 7 windows

Evidence:

- Querying three consecutive nonpass rows with the same non-empty `error_msg` returns no rows.
- Classifying blocker families from `notes` and other prose yields only 4 recognized rows: 2 `timeout` rows and 2 `blocked literal` rows; 93 rows remain unclassified by simple family rules.

Impact: a strict Law 7 detector using structured columns would miss every historical repetition. A fallback prose classifier helps only partially because old notes use free-form phrasing and many failure narratives do not include a reusable canonical error token.

### WARNING-5: Builder rows show no historical nonpass contrast, so Sanhedrin is the only evidence source

Evidence:

| Agent | All rows | Nonpass rows |
| --- | ---: | ---: |
| `modernization` | 1,505 | 0 |
| `inference` | 1,414 | 0 |
| `sanhedrin` | 11,687 | 97 |

Impact: the builder loops have no central nonpass rows to compensate for Sanhedrin's missing structured errors. Historical blocker analysis therefore depends entirely on Sanhedrin prose until future writers populate `error_msg` and `validation_result` consistently.

## Recommendation

For future central DB writes, preserve the prose `notes` field but also populate:

```text
error_msg = canonical shortest repeated blocker string
validation_result = concise pass/fail/blocked evidence summary
notes = human narrative and supporting context
```

For Law 7 specifically, canonicalize common blockers before insertion, for example `readonly database`, `command not found`, `operation not permitted`, `ssh timeout`, `github api unreachable`, and `missing credential`. Escalation should group on `agent`, `task_id`, and canonical `error_msg`, then fall back to prose parsing only for older rows.
