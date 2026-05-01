# temple-central.db Files-Changed Current-Head Join Drift

Audit timestamp: 2026-05-01T03:51:19+02:00

Audit angle: historical drift trends. This pass queried `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db` read-only and compared recorded builder `files_changed` paths with the current local heads of TempleOS and holyc-inference. It did not inspect live liveness, restart processes, run QEMU or VM commands, execute WS8 networking tasks, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

SQL: `audits/trends/2026-05-01-files-changed-current-head-join-drift.sql`
Helper: `audits/trends/2026-05-01-files-changed-current-head-join-drift.py`

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder DB window with nonblank `files_changed`: 2026-04-12T13:51:32 through 2026-04-23T12:06:44
- TempleOS head checked for path existence: `2bac8a1a31022bda672b53a5d1a642efdf7cb5bd`
- holyc-inference head checked for path existence: `2799283c9554bea44c132137c590f02034c8f726`

## Summary

`files_changed` is useful evidence, but it is not a durable join key by itself. Across 2,919 builder rows, 278 recorded path tokens no longer exist at the current sibling heads, and 4 rows contain non-path placeholders instead of changed paths. This does not prove the historical commits were wrong; it proves that long-window audits cannot safely join old DB rows to current filesystem state without commit SHA, path action, and rename/delete metadata.

## Findings

### WARNING-1: Current-head path joins miss historical builder evidence

Evidence from the helper:

| Agent | Rows | Valid path tokens | Current-head missing paths | Rows with missing paths |
| --- | ---: | ---: | ---: | ---: |
| modernization | 1,505 | 3,429 | 115 | 112 |
| inference | 1,414 | 3,870 | 163 | 101 |

Impact: a trend report that resolves historical `files_changed` entries against only the current worktree will undercount historical work and may misclassify old implementation or validation rows as unverifiable.

### WARNING-2: Inference has runtime-path disappearance in the historical ledger

Evidence:

- 62 inference rows name at least one `src/` path that does not exist at current head.
- The most repeated missing runtime paths are `src/gguf/parser.HC` in 34 rows and `src/quant/q8_0_matmul.HC` in 28 rows.
- Current holyc-inference head contains nearby surfaces such as `src/gguf/reader.HC`, `src/gguf/tensor_info.HC`, and `src/quant/q8_0_dot.HC`, but the DB has no rename/action column to explain whether the historical paths were renamed, deleted, or never committed.

Impact: Law 1 and Law 5 backfills that classify runtime work from current paths will lose historical inference runtime evidence unless they replay the exact commit or ingest git path history.

### WARNING-3: Modernization missing paths concentrate in host automation smoke scripts

Evidence:

- 115 modernization path tokens are absent at current TempleOS head.
- The most repeated missing modernization paths are host-side smoke scripts, including `automation/bookoftruth-verify-fault-tail-status-smoke.sh` in 9 rows, `automation/bookoftruth-verify-fault-tail-status-delta-smoke.sh` in 5 rows, and several `automation/bookoftruth-*smoke.sh` paths in 2 to 4 rows each.
- No modernization `Kernel/`, `Adam/`, `Apps/`, `Compiler/`, or `0000Boot/` current-missing path was observed in this pass.

Impact: this is lower risk than missing core HolyC paths, but it still weakens validation-evidence replay because old smoke evidence cannot be joined to current script contents.

### WARNING-4: Four pass rows do not contain path tokens

Evidence:

| Row | Timestamp | Agent | Task | `files_changed` |
| ---: | --- | --- | --- | --- |
| 11907 | 2026-04-21T21:19:20 | modernization | CQ-1015 | `(superseded)` |
| 13038 | 2026-04-22T02:07:45 | inference | IQ-1038 | `1` |
| 13079 | 2026-04-22T02:13:06 | inference | IQ-1039 | `1` |
| 13097 | 2026-04-22T02:16:36 | inference | IQ-1037 | `1` |

Impact: these rows are recorded as `pass`, but `files_changed` cannot support Law 5 work-substance scoring or Law 1/Law 4 file-surface classification for those iterations.

### INFO-1: The DB is close enough to support a normalized path backfill

Evidence:

- 7,299 of 7,303 raw builder `files_changed` tokens parse as plausible path tokens.
- The drift is concentrated enough to backfill a child table without rewriting the original `iterations.files_changed` strings.

Recommended backfill shape: `iteration_files(iteration_id, agent, repo_head_at_insert, path, path_role, action, exists_at_current_head, parse_status)`. Keep the original free-text field for forensics, but make Law 1, Law 4, Law 5, and Law 6 trend reports consume normalized path rows.

## Checks Performed

```bash
sqlite3 -readonly -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-05-01-files-changed-current-head-join-drift.sql
python3 audits/trends/2026-05-01-files-changed-current-head-join-drift.py
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
```

No QEMU/VM command was run.

## Verdict

Record 4 warning findings and 1 informational finding. The central ledger is not wrong merely because a historical path is absent at current head, but it needs normalized path/action/provenance backfill before current-head joins are used for compliance scoring.
