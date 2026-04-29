# temple-central.db Validation Outcome Semantics Drift

Audit timestamp: 2026-04-29T16:16:40+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for validation command/result semantics, especially rows where success status is carrying skipped or unavailable validation evidence and rows where failure status is not carrying a structured error. It did not inspect live processes, restart anything, run QEMU, or modify TempleOS / holyc-inference source code.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- TempleOS head observed read-only: `b91d88429b23f8099fb3be1ba7105f04792b7480`
- holyc-inference head observed read-only: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `9c861b6ac2c6fc1b2a3d01a26726cb151e8dcffe`
- Query pack: `audits/trends/2026-04-29-validation-outcome-semantics-drift.sql`
- LAWS.md focus: Law 7 evidence reliability, Law 2 air-gap auditability, and Law 5 meaningful-progress validation. This is not a current liveness audit.

## Findings

1. WARNING - Sanhedrin failure rows do not populate structured failure fields.
   - Evidence: 94 `sanhedrin` rows have `status='fail'` and 3 have `status='blocked'`; all 97 have empty `error_msg`, `validation_cmd`, and `validation_result`.
   - Impact: historical blocker escalation and Law 7 failure trend queries must parse free-form `notes`, so repeated blocker strings can be missed or double-counted.

2. WARNING - 109 modernization pass rows encode skipped or unavailable validation in `validation_result`.
   - Evidence: affected rows span ids `80..14007`; daily clusters include 12 rows on 2026-04-12, 19 on 2026-04-13, 20 on 2026-04-20, and 30 on 2026-04-21.
   - Impact: `status='pass'` currently conflates fully executed validation with partial validation where local QEMU or ISO-backed coverage was skipped.

3. WARNING - Modernization validation-result text has at least three incompatible skip shapes.
   - Evidence: 78 rows are `local_qemu_skip`, 22 are `iso_unavailable`, and 9 are `remote_or_ssh_backstop`.
   - Impact: reports that search one phrase, such as `ISO unavailable`, will undercount skipped validation and overstate full Law 2 / Law 5 coverage.

4. WARNING - Three modernization pass rows include failure wording even though the rows passed.
   - Evidence: ids `5674`, `6589`, and `7197` contain phrases such as `no compile errors`, which trip failure-keyword scans because `error` is present inside a successful result.
   - Impact: naive text classifiers can mark successful remote compile backstops as suspect failures unless validation outcome vocabulary is normalized.

5. INFO - Builder rows have complete validation fields, and the skip/pass conflation is concentrated in modernization.
   - Evidence: all 1,505 modernization pass rows and all 1,414 inference pass rows have non-empty `validation_cmd` and `validation_result`; inference has only 1 skipped/unavailable pass row versus modernization's 109.
   - Impact: the drift is semantic rather than missing builder evidence; a small taxonomy change can preserve existing rows while making future trend reports reliable.

## Supporting Extracts

Validation-field coverage:

| Agent | Status | Rows | Has validation cmd | Has validation result | Has error msg |
| --- | --- | ---: | ---: | ---: | ---: |
| `inference` | `pass` | 1,414 | 1,414 | 1,414 | 0 |
| `modernization` | `pass` | 1,505 | 1,505 | 1,505 | 0 |
| `sanhedrin` | `blocked` | 3 | 0 | 0 | 0 |
| `sanhedrin` | `fail` | 94 | 0 | 0 | 0 |
| `sanhedrin` | `pass` | 8,850 | 0 | 0 | 0 |
| `sanhedrin` | `skip` | 2,740 | 0 | 0 | 0 |

Skip/unavailable pass evidence:

| Agent | Rows | Pass skip/unavailable rows | Pass failure-word rows |
| --- | ---: | ---: | ---: |
| `inference` | 1,414 | 1 | 0 |
| `modernization` | 1,505 | 109 | 3 |
| `sanhedrin` | 11,687 | 0 | 0 |

Modernization skip evidence shapes:

| Evidence shape | Rows | First id | Last id |
| --- | ---: | ---: | ---: |
| `local_qemu_skip` | 78 | 80 | 14007 |
| `iso_unavailable` | 22 | 5000 | 13349 |
| `remote_or_ssh_backstop` | 9 | 5674 | 12927 |

Sanhedrin structured-error gaps:

| Task id | Status | Rows | First id | Last id |
| --- | --- | ---: | ---: | ---: |
| `CI-TEMPLEOS` | `fail` | 43 | 1376 | 1813 |
| `AUDIT` | `fail` | 31 | 494 | 14208 |
| `VM-COMPILE` | `fail` | 10 | 4471 | 8854 |
| `VM-CHECK` | `fail` | 5 | 1930 | 13089 |
| `LAW-CHECK` | `fail` | 3 | 2397 | 13283 |
| `VM-COMPILE` | `blocked` | 3 | 6883 | 8489 |
| `AUDIT-RECTIFY` | `fail` | 1 | 4648 | 4648 |
| `CI-24308638070` | `fail` | 1 | 604 | 604 |

## Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-validation-outcome-semantics-drift.sql
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
```

## Recommendations

- Add a structured validation outcome taxonomy for future rows, for example `executed`, `partial`, `skipped_prereq`, `remote_backstop`, and `failed`.
- Populate `error_msg` for every future `fail` and `blocked` row, even when `notes` retains the human-readable explanation.
- Treat `pass` plus skipped/unavailable validation text as partial evidence in historical trend reports instead of full validation proof.
- Normalize successful wording away from `no errors` toward positive tokens such as `compile_clean` to avoid false failure-keyword hits.
