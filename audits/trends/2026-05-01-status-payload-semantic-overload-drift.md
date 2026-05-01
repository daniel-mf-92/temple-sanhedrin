# temple-central.db Status/Payload Semantic Overload Drift

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for places where the normalized `status` field no longer carries enough meaning without brittle note parsing. It did not inspect live loop liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-status-payload-semantic-overload-drift.sql`

## Summary

The central DB's `iterations.status` column is too coarse for Sanhedrin and too lexical for trend mining. Builder rows are structurally simple: all 1,505 modernization rows and all 1,414 inference rows are `pass` with `validation_result` populated. Sanhedrin rows use all four statuses, but every non-pass Sanhedrin row has empty `validation_result` and empty `error_msg`, forcing cause recovery from free-text `notes`.

The main risk is not that these rows prove LAWS.md violations. The risk is that long-window dashboards cannot distinguish "feature named fail-stop", "observed fail_count=0", "CI failed", "blocked by sandbox", and "actual violation" without regexes that know each historical wording variant.

## Findings

1. **WARNING - Non-pass Sanhedrin rows have no structured cause fields.**
   - Evidence: 2,837 Sanhedrin non-pass rows have both `validation_result=''` and `error_msg=''`: 2,740 `skip`, 94 `fail`, and 3 `blocked`.
   - Why it matters: Law 7 blocker trend analysis should not have to parse arbitrary prose to identify whether a row represents unavailable email credentials, CI failure, SSH sandbox denial, or a real audit failure.

2. **WARNING - `EMAIL-CHECK` skip rows dominate non-pass history without machine-readable reason codes.**
   - Evidence: `EMAIL-CHECK` accounts for 2,088 skip rows, all with empty `validation_result` and `error_msg`; the sampled row says the GitHub failure email check was unavailable due missing Google MCP credentials.
   - Why it matters: this single external-tooling issue can swamp historical status distributions and make Sanhedrin appear unhealthy unless every query has a special-case email-credential classifier.

3. **WARNING - CI and VM task IDs reuse `skip`, `fail`, and `blocked` without a shared taxonomy.**
   - Evidence: examples include `CI-INFERENCE` 444 skips, `CI-TEMPLEOS` 43 fails plus 2 skips, `VM-COMPILE` 12 skips plus 10 fails plus 3 blocked, and `VM-CHECK` 12 skips plus 5 fails.
   - Why it matters: the same task family can move between statuses for operationally different reasons, but the DB has no `reason_code`, `external_dependency`, `policy_blocked`, or `law_violation` columns.

4. **INFO - Builder pass rows contain many failure words that are not row failures.**
   - Evidence: 82 modernization pass rows and 18 inference pass rows include `fail` in `validation_result` or `notes`. Buckets include `fail-stop` feature work, `verify-fail` event names, generic failure-path evidence, and other failure-token wording.
   - Why it matters: lexical "fail" searches over pass rows create false positives for Law 5 or Law 7 trend audits unless queries distinguish feature vocabulary from iteration outcome.

5. **WARNING - Sanhedrin pass rows are also overloaded with failure vocabulary.**
   - Evidence: 4,947 Sanhedrin pass rows include `fail`; the mutually exclusive buckets include 1,634 `fail_count=0`, 400 `no_critical_violations`, 827 generic failure-evidence rows, and 2,001 other failure-token rows.
   - Why it matters: a healthy audit conclusion can include failure evidence, zero-failure counters, and negative assertions in the same free-text field. The current schema cannot preserve that distinction for downstream dashboards.

## Counts

| Section | Agent | Status | Rows | Extra |
|---|---:|---:|---:|---|
| status total | inference | pass | 1,414 | |
| status total | modernization | pass | 1,505 | |
| status total | sanhedrin | blocked | 3 | |
| status total | sanhedrin | fail | 94 | |
| status total | sanhedrin | pass | 8,850 | |
| status total | sanhedrin | skip | 2,740 | |
| non-pass missing structured cause | sanhedrin | blocked | 3 | |
| non-pass missing structured cause | sanhedrin | fail | 94 | |
| non-pass missing structured cause | sanhedrin | skip | 2,740 | |
| pass payload has fail token | inference | pass | 18 | |
| pass payload has fail token | modernization | pass | 82 | |
| pass payload has fail token | sanhedrin | pass | 4,947 | |
| pass payload has blocked token | modernization | pass | 7 | |
| pass payload has blocked token | sanhedrin | pass | 200 | |

Top non-pass Sanhedrin cause gaps:

| Task ID | Status | Rows | First TS | Last TS |
|---|---:|---:|---:|---|
| EMAIL-CHECK | skip | 2,088 | 1776539926 | 2026-04-23T11:54:25 |
| CI-INFERENCE | skip | 444 | 2026-04-13T10:38:11 | 2026-04-18T09:28:19 |
| CI-24308638070 | skip | 156 | 2026-04-12T19:07:45 | 2026-04-16T17:45:53 |
| CI-TEMPLEOS | fail | 43 | 2026-04-16T18:00:14 | 2026-04-17T00:07:36 |
| AUDIT | fail | 31 | 2026-04-13T07:22:49 | 2026-04-22T23:55:13 |
| CI-24308309656 | skip | 15 | 2026-04-12T21:14:34 | 2026-04-15T16:28:51 |
| VM-CHECK | skip | 12 | 2026-04-17T01:15:11 | 2026-04-22T02:13:00 |
| VM-COMPILE | skip | 12 | 2026-04-17T03:57:08 | 2026-04-20T18:59:36 |
| VM-COMPILE | fail | 10 | 2026-04-18T15:46:45 | 2026-04-20T20:56:49 |

## Recommendation

Add structured fields before using `temple-central.db` status history as an enforcement signal:

- `outcome`: pass/fail/skip/blocked, preserving the current role.
- `reason_code`: stable enum such as `email_credentials_missing`, `ci_failed`, `ssh_sandbox_blocked`, `qemu_not_run_policy`, `audit_violation`, `audit_clean`.
- `law_id`: nullable FK for law-specific findings.
- `evidence_class`: `positive_evidence`, `negative_assertion`, `external_blocker`, `feature_failure_path`, `actual_failure`.
- `external_dependency`: nullable service/tool label for GitHub, email MCP, Azure VM, SSH, or SQLite.

Until those fields exist, historical trend audits should treat `status` as advisory and preserve the regex classifier used for each report.

## Reproduction

```sh
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-status-payload-semantic-overload-drift.sql
```
