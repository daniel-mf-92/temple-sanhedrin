# Historical Identifier-Compounding Files-Changed Drift

Audit angle: historical drift trends. This is a read-only query of `temple-central.db` iteration history, focused on whether recorded `files_changed` paths show sustained Law 4 identifier-compounding pressure.

Scope:
- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Table: `iterations`
- Window present in DB rows with `files_changed`: 2026-04-12 through 2026-04-23
- Laws considered: appended Law 4 Identifier Compounding Ban, appended Law 5 North Star Discipline, appended Law 7 Blocker Escalation
- No TempleOS or holyc-inference source files were modified.
- No QEMU or VM command was executed.

## Summary

The central DB shows 2,993 iteration rows with non-empty `files_changed`. Of those, 1,975 rows record at least one changed path whose basename exceeds 40 characters or more than 5 hyphen/underscore-separated tokens. Every builder row flagged by this trend was still recorded as `pass`, so the central ledger currently normalizes many measurable Law 4 over-limit changes as successful iterations.

| Agent | Rows with files | Changed paths | Compound rows | Compound paths | Compound row rate | Max basename length | Max separator tokens |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 3,873 | 1,087 | 1,128 | 76.9% | 242 | 34 |
| modernization | 1,505 | 3,430 | 814 | 852 | 54.1% | 169 | 25 |
| sanhedrin | 74 | 74 | 74 | 74 | 100.0% | 61 | 10 |

## Findings

### WARNING-001: Builder pass rows frequently contain measurable Law 4 filename violations

Evidence:
- `inference`: 1,087 of 1,414 rows with file lists contain at least one over-limit changed basename; all 1,087 are recorded with `status='pass'`.
- `modernization`: 814 of 1,505 rows with file lists contain at least one over-limit changed basename; all 814 are recorded with `status='pass'`.
- The worst inference row in the DB is `IQ-740` at `2026-04-20T16:26:59`, with a 242-character test filename and 33 separator tokens before the `.py` extension; the reusable SQL query counts the extension-bearing basename at 34 separator tokens.
- The worst modernization rows are generated smoke scripts in the scheduler/Book-of-Truth families, with basenames up to 169 characters and 25 separator tokens.

Impact: reports that rely on `status='pass'` alone will miss large volumes of measurable identifier-compounding drift. This is not a new source-code audit of current heads; it is a central-ledger trend showing that the historical pass/fail field is not sufficient for Law 4 compliance.

### WARNING-002: The drift is sustained, not a one-day spike

Daily builder rows with compound paths:

| Day | Modernization compound rows | Inference compound rows |
| --- | ---: | ---: |
| 2026-04-17 | 48 | 131 |
| 2026-04-18 | 79 | 144 |
| 2026-04-19 | 98 | 143 |
| 2026-04-20 | 135 | 178 |
| 2026-04-21 | 157 | 181 |
| 2026-04-22 | 183 | 194 |
| 2026-04-23 | 24 | 48 |

Impact: Law 4 identifier-compounding pressure increased across the same historical window rather than being isolated to a small batch of commits. This should be treated as trend debt and not only retroactive per-commit debt.

### WARNING-003: Repeated suffix vocabulary shows chained-helper growth

Evidence from over-limit paths:
- Inference over-limit paths heavily repeat `checked` (1,035 paths), `nopartial` (450), `commit_only` (417), `preflight_only` (408), and `parity` (271).
- Modernization over-limit paths heavily repeat `smoke` (677 paths) and `digest` (249).

Impact: this matches the Law 4 "existing-name + suffix" anti-pattern even when individual commits look like small additions. The DB trend shows chained suffixes became a naming strategy, not an occasional exception.

### WARNING-004: Sanhedrin artifact names also exceed the appended Law 4 measurement

Evidence:
- 74 Sanhedrin rows with `files_changed` are present; all 74 include compound paths by the same measurement.
- One Sanhedrin row is `fail`, but 73 are `pass`.

Impact: audit artifacts are not builder source code, but Sanhedrin's own path vocabulary can make Law 4 reporting noisy and normalize the naming pattern it is supposed to detect. If audit artifacts are intended to be exempt, `LAWS.md` should say so explicitly; otherwise central reports should distinguish "audit artifact path debt" from builder violation debt.

### INFO-001: The central DB has enough structure for automated Law 4 trend checks

The `files_changed` field is free text but mostly parseable with comma, semicolon, and newline delimiters. A recurring Sanhedrin query can compute `compound_rows`, `compound_paths`, maximum basename length, and maximum separator-token count per agent/day without touching builder repos.

Recommended next steps:
- Add a derived central metric such as `law4_compound_path_count` per iteration.
- Treat `status='pass'` plus `law4_compound_path_count > 0` as "pass with Law 4 debt", not clean pass.
- Add a baseline/debt distinction so legacy long names do not block all progress, while new suffix-chain expansions still surface as regressions.
- Clarify whether Sanhedrin audit artifact filenames are exempt from the appended Law 4 naming limits.

## Reproduction

Reusable query:

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-identifier-compounding-files-changed-drift.sql
```

Additional read-only analysis command used for phrase counts:

```bash
python3 - <<'PY'
import sqlite3, re, collections
DB='/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db'
conn=sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
rows=conn.execute("select id, ts, agent, task_id, status, files_changed from iterations where files_changed is not null and trim(files_changed)<>''").fetchall()
def files(s): return [p.strip() for p in re.split(r'[,;\n]+', s or '') if p.strip()]
def bad(path):
    base=path.rsplit('/',1)[-1]
    toks=[t for t in re.split(r'[-_]+', base) if t]
    return len(base)>40 or len(toks)>5, base
counts=collections.Counter()
for _,_,agent,_,_,fc in rows:
    for path in files(fc):
        is_bad, base = bad(path)
        if is_bad:
            low=base.lower().replace('-', '_')
            for phrase in ('checked','nopartial','commit_only','preflight_only','parity','smoke','digest'):
                if phrase in low:
                    counts[(agent, phrase)] += 1
print(counts)
PY
```
