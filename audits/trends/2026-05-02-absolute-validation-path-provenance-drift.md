# Host-Absolute Validation Path Provenance Drift

Audit timestamp: 2026-05-02T10:16:53+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only for builder validation evidence that depends on host-absolute paths such as `/tmp`, `/Users/danielmatthews-ferrero/...`, and `/home/azureuser/...`. It did not inspect live liveness, restart processes, run QEMU or VM commands, run SSH/SCP, execute WS8 networking tasks, modify TempleOS or holyc-inference source code, or write to the central database. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-02-absolute-validation-path-provenance-drift.sql`

## Summary

The historical builder ledger often records validation as machine-local path evidence rather than portable artifact provenance. Modernization is the affected side: 775 of 1,505 rows contain `/tmp`, `/Users/...`, or `/home/azureuser/...` evidence, including 354 Book-of-Truth rows with `/tmp` references and 173 rows mentioning the Azure home path. Inference has only one `/Users/...` row. This is not a guest-networking finding; it is a Law 5/Law 11 evidence-quality drift because future audits cannot replay or physically locate those artifacts from the DB row alone.

Findings: 5 warnings.

## Findings

### WARNING-1: Modernization validation evidence is dominated by host-absolute paths

Evidence:
- Modernization builder rows: 1,505.
- Modernization rows with `/tmp`, `/Users`, or `/home/azureuser`: 775 (`51.50%`).
- Inference builder rows: 1,414.
- Inference rows with those path forms: 1 (`0.07%`).

Impact: more than half of modernization's captured validation rows depend on machine-local locations. That weakens historical replay because the DB does not store artifact hashes, captured contents, or a durable artifact URI for those paths.

### WARNING-2: `/tmp` evidence overlaps Book-of-Truth validation

Evidence:
- Modernization rows mentioning `/tmp`: 354.
- Modernization rows mentioning both `/tmp` and Book-of-Truth wording: 354.
- None of those `/tmp` rows mention `mktemp` or `tmpdir` in the captured evidence text.

Impact: `/tmp` paths are ephemeral by design. When they are the only durable pointer to Book-of-Truth replay, serial, or fixture evidence, Law 11 local-access and Book-of-Truth provenance audits must fall back to prose instead of preserved local artifacts.

### WARNING-3: Remote Azure home paths became normal validation evidence

Evidence:
- Modernization rows mentioning `/home/azureuser`: 173.
- The classified path scan counted 170 rows where Azure home was the primary path class after excluding rows that also contained `/tmp`.
- The Azure-home window runs from `2026-04-15T19:02:04` through `2026-04-23T12:01:29`.

Impact: this is separate from whether QEMU used `-nic none`. A host-remote filesystem path is a different provenance class from local physical evidence, especially for Book-of-Truth workflows that must stay locally observable.

### WARNING-4: Replay, fixture, and digest evidence often carries absolute paths

Evidence:
- Modernization replay rows: 760; replay rows with absolute paths: 505.
- Modernization fixture rows: 472; fixture rows with absolute paths: 340.
- Modernization digest rows: 487; digest rows with absolute paths: 297.

Impact: the strongest validation words in the ledger still lack normalized artifact references. A future auditor can see that replay/fixture/digest checks happened, but cannot reconstruct which exact artifact was consumed or produced without the originating workstation layout.

### WARNING-5: Absolute-path usage intensified near the end of the DB window

Evidence:
- `2026-04-21`: 136 of 248 modernization rows have absolute-path evidence.
- `2026-04-22`: 199 of 246 modernization rows have absolute-path evidence.
- `2026-04-23`: 26 of 34 modernization rows have absolute-path evidence.

Impact: this was not just an early bootstrap artifact. It became more common during the later captured modernization window, when Book-of-Truth and scheduler replay evidence should have been moving toward stronger archival provenance.

## Key Aggregates

| Agent | Rows | Abs Path Rows | Abs Path % | `/tmp` Rows | `/Users` Rows | `/home/azureuser` Rows | `/tmp` + Book-of-Truth Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 1 | 0.07 | 0 | 1 | 0 | 0 |
| modernization | 1,505 | 775 | 51.50 | 354 | 302 | 173 | 354 |

| Agent | Replay Rows | Replay Abs Rows | Fixture Rows | Fixture Abs Rows | Digest Rows | Digest Abs Rows |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 0 | 0 | 6 | 0 | 1 | 0 |
| modernization | 760 | 505 | 472 | 340 | 487 | 297 |

| Primary Path Class | Agent | Rows | First Timestamp | Last Timestamp |
| --- | --- | ---: | --- | --- |
| `azure_home` | modernization | 170 | `2026-04-15T19:02:04` | `2026-04-23T12:01:29` |
| `tmp` | modernization | 354 | `2026-04-12T15:24:56` | `2026-04-23T05:47:39` |
| `users` | inference | 1 | `2026-04-18T20:30:58` | `2026-04-18T20:30:58` |
| `users` | modernization | 251 | `2026-04-21T04:39:03` | `2026-04-23T11:04:01` |

## Recommendations

- Store validation artifacts as normalized records with `artifact_kind`, `path_original`, `repo_relative_path` when applicable, `sha256`, `size_bytes`, and `local_only`/`remote_host` provenance.
- Treat `/tmp` and `/home/azureuser` evidence as low-provenance unless the DB also records the artifact digest and whether Book-of-Truth contents were viewed locally or remotely.
- Normalize `REPO_DIR="/Users/..."` and other workstation paths before DB insertion so historical reports remain machine-portable.
- Keep guest air-gap scoring separate from artifact locality scoring: an air-gapped QEMU command can still produce weak Law 11 evidence if the only recorded artifact pointer is remote or ephemeral.

## Read-Only Verification Command

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-02-absolute-validation-path-provenance-drift.sql
```

Finding count: 5 warning findings.
