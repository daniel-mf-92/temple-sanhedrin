# Historical Commit-Traceability Evidence Drift Audit

Timestamp: 2026-04-29T13:03:00+02:00

Scope: historical drift trends over `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`, with read-only spot checks against the current TempleOS and holyc-inference git logs. This audit does not inspect live liveness, run QEMU, run VM commands, or modify TempleOS/holyc-inference source code.

Audit angle: retroactive auditability of builder iterations. The question is whether historical `iterations` rows preserve enough commit identity to bind a pass/fail row to the exact diff later reviewed under LAWS.md.

Reproduction:

```sh
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-commit-traceability-evidence-drift.sql
python3 audits/trends/2026-04-29-commit-traceability-evidence-drift.py
```

## Findings

1. WARNING: `iterations` has no `commit_sha`, `commit_ref`, `repo`, or `parent_sha` column. The durable row schema records task, status, files, validation, and notes, but it cannot directly bind an iteration to a reviewed git object.

2. WARNING: The precise regex scan found zero exact 40-character commit SHAs across all 2919 builder rows: 1505 modernization rows and 1414 inference rows. Loose 7-12 hex tokens were also non-evidence in practice: examples were date stamps like `20260421` or identifiers embedded in words like `eadF64B`.

3. WARNING: Task IDs cannot safely substitute for commit identity. Modernization reused 334 of 1087 distinct task IDs (30.7%), inference reused 256 of 1109 (23.1%), and individual IDs appear up to 6 times for modernization and 5 times for inference.

4. WARNING: Modernization traceability is especially weak in the historical DB. The loose SQL scan found only 1 row with git-command/commit-word evidence and 13 weak trace rows out of 1505 (0.86%); the exact SHA checker still found 0 exact commit SHAs.

5. WARNING: The database is stale relative to the current repo histories used for retroactive auditing. The last builder rows are 2026-04-23T12:01:29 for modernization and 2026-04-23T12:06:44 for inference, while the current local git histories contain 631 TempleOS commits and 588 holyc-inference commits after those respective timestamps.

Finding count: 5

## Evidence Extracts

Iteration schema:

```text
cid  name               type     notnull  dflt_value                              pk
---  -----------------  -------  -------  --------------------------------------  --
0    id                 INTEGER  0                                                1
1    ts                 TEXT     0        strftime('%Y-%m-%dT%H:%M:%S','now')     0
2    agent              TEXT     1                                                0
3    task_id            TEXT     1                                                0
4    status             TEXT     1                                                0
5    files_changed      TEXT     0                                                0
6    lines_added        INTEGER  0        0                                       0
7    lines_removed      INTEGER  0        0                                       0
8    validation_cmd     TEXT     0                                                0
9    validation_result  TEXT     0                                                0
10   error_msg          TEXT     0                                                0
11   duration_sec       INTEGER  0                                                0
12   notes              TEXT     0                                                0
```

Loose traceability scan:

```text
agent          rows  first_ts             last_ts              weak_git_evidence_rows  weak_hexish_rows  weak_trace_rows  weak_trace_pct  compound_task_rows  multi_file_rows
-------------  ----  -------------------  -------------------  ----------------------  ----------------  ---------------  --------------  ------------------  ---------------
inference      1414  2026-04-12T13:53:13  2026-04-23T12:06:44  382                     2                 383              27.09           0                   1350
modernization  1505  2026-04-12T13:51:32  2026-04-23T12:01:29  1                       12                13               0.86            103                 1287
```

Exact SHA scan:

```text
agent rows exact_40_hex_sha loose_7_12_hex_token
inference 1414 0 2
modernization 1505 0 12
```

Task ID reuse:

```text
agent          distinct_task_ids  reused_task_ids  max_rows_for_one_task  reused_task_pct
-------------  -----------------  ---------------  ---------------------  ---------------
inference      1109               256              5                      23.1
modernization  1087               334              6                      30.7
```

Representative high-reuse task IDs:

```text
agent          task_id  rows  first_ts             last_ts
-------------  -------  ----  -------------------  -------------------
modernization  CQ-914   6     2026-04-21T04:03:30  2026-04-21T05:07:43
inference      IQ-878   5     2026-04-21T06:15:19  2026-04-21T06:55:00
modernization  CQ-1118  5     2026-04-22T02:37:12  2026-04-22T02:38:46
modernization  CQ-1191  5     2026-04-22T07:25:08  2026-04-22T08:20:52
modernization  CQ-1223  5     2026-04-22T10:59:18  2026-04-22T14:59:01
```

Current local heads:

```text
TempleOS:         63780d214b9bbb999ad271c83895a062c3485150 2026-04-29T11:59:17+02:00 feat(modernization): codex iteration 20260429-114910
holyc-inference: 485af0ea41a239c8393542d6e0e2fc5944f30f53 2026-04-29T06:51:01+02:00 feat(inference): codex iteration 20260429-064100
```

## Audit Judgment

No direct Law 1, Law 2, Law 3, Law 4, Law 8, Law 9, Law 10, or Law 11 violation is established by this trend audit. The compliance risk is evidentiary: retroactive LAWS.md review depends on exact commit-to-row provenance, but the historical database mostly records task-level summaries. Future historical rows should store `repo`, `commit_sha`, `parent_sha`, and the exact validation command/result for the checked commit.
