# temple-central.db Violation Recording Drift Audit

Timestamp: 2026-04-28T20:39:35+02:00

Scope: historical drift trends, read-only query of `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`.

SQL: `audits/trends/2026-04-28-temple-central-violation-recording-drift.sql`

## Summary

The structured `violations` table is not being used. The database contains 11,687 Sanhedrin iteration rows and 2,823 Sanhedrin `AUDIT` rows, including explicit `Severity=CRITICAL` and `Severity=WARNING` notes, but `violations` has 0 rows. This means long-window compliance trend reports cannot distinguish "no violations existed" from "violations were only written into free-text notes/Markdown."

Finding count: 5

## Findings

### WARNING-1: Structured violation table is empty despite active Sanhedrin audit history

Evidence:
- `iterations` has 11,687 Sanhedrin rows.
- Sanhedrin `AUDIT` rows total 2,823.
- `violations` rows total 0.

Impact: LAWS.md says violations are logged in `audits/`, but the central schema also has a purpose-built `violations` table. Because no Sanhedrin audit writes to it, DB-only historical reports undercount every violation and cannot compute resolution state.

### WARNING-2: Critical/warning severity is embedded in free text, not normalized

Evidence:
- 2,823 Sanhedrin `AUDIT` rows.
- 1,198 Sanhedrin `AUDIT` rows include `severity=` in notes.
- 157 `AUDIT` rows start with critical/warning/pass-with-warning severity.
- 0 corresponding `violations` rows exist.

Impact: Severity cannot be reliably joined to `laws`, `agent`, `resolved`, or machine-readable evidence. Every future trend query must re-parse text variants instead of querying the schema.

### WARNING-3: DB status does not preserve audit severity semantics

Evidence:
- Of the 157 critical/warning/pass-with-warning audit rows, 149 have `iterations.status='pass'` and only 8 have `status='fail'`.
- Sanhedrin has 94 total `fail` rows and 31 `AUDIT` fail rows, but no structured violation rows.

Impact: `iterations.status` is process outcome, not compliance severity. Treating `status='pass'` as "no law issue" hides warnings and pass-with-warning audits.

### WARNING-4: Date normalization drift damages daily aggregation

Evidence:
- 14 `iterations.ts` values are not ISO-like `YYYY-MM-DDTHH:MM:SS`.
- 3 rows use Unix-epoch-like `1776539926`; SQLite `date(ts)` returns NULL for them.
- Affected rows include one Sanhedrin `AUDIT` row.

Impact: daily groupings create a NULL day bucket and lose a Sanhedrin audit row from normal date windows.

### INFO-5: Law references are present enough to backfill structured rows

Evidence:
- 2,751 of 2,823 Sanhedrin `AUDIT` rows mention `law`.
- 1,198 include `severity=`.

Impact: A historical backfill is practical. A conservative parser can populate `violations` only for rows with explicit `Severity=CRITICAL`, `Severity=WARNING`, or `Severity=PASS_WITH_WARNING`, leaving ambiguous PASS rows untouched.

## Reproduction

```bash
sqlite3 /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-28-temple-central-violation-recording-drift.sql
```

## Recommendation

Add a Sanhedrin write path that records each CRITICAL/WARNING finding into `violations(law_id, agent, severity, evidence, resolved)` while preserving the existing Markdown report. For historical accuracy, backfill only explicit free-text severities first, then separately audit ambiguous notes.
