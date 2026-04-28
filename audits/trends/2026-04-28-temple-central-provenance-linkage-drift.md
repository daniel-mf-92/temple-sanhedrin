# temple-central.db Provenance Linkage Drift

Audit timestamp: 2026-04-28T19:19:30+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only and compared the database's builder provenance coverage with current local git history in `TempleOS` and `holyc-inference`. No Trinity source code was modified, no VM or QEMU command was executed, and the TempleOS guest air-gap was not touched.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- Builder repos checked read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Query pack: `audits/trends/2026-04-28-temple-central-provenance-linkage-drift.sql`
- LAWS.md focus: retroactive audit reliability for Law 5 north-star discipline, Law 6 queue traceability, Law 7 blocker escalation, and Sanhedrin evidence quality.

## Findings

1. WARNING - `iterations` has no structured commit SHA field for builder rows.
   - Evidence: the table schema includes `ts`, `agent`, `task_id`, `status`, `files_changed`, churn, validation, error, duration, and notes fields, but no `commit_sha`, parent SHA, branch, or remote ref.
   - Impact: retroactive commit audits cannot join database rows to exact builder commits without parsing git history and free-form text. This weakens historical Law 5 and Law 7 reconstruction when multiple commits share a task ID or timestamp window.

2. WARNING - north-star provenance is not structured in `temple-central.db`.
   - Evidence: the schema has no `north_star_delta`, `north_star_result`, or north-star explanation column. Current LAWS.md requires each iteration to justify how its commit advances `NORTH_STAR.md`.
   - Impact: compliance backfills for the newer Law 5 wording must infer north-star relevance from `notes`, validation text, or commit diffs instead of querying a durable field.

3. WARNING - commit mentions in builder notes are uneven across agents.
   - Evidence: all builder rows have non-empty notes, but only 46 of 1,505 modernization rows mention `commit` or `sha`, versus 414 of 1,414 inference rows.
   - Impact: inference history is materially easier to correlate with commits than modernization history. Modernization retro audits need more git-side heuristics and are more exposed to false joins.

4. WARNING - task IDs are sometimes reused enough to blur one-task-one-iteration provenance.
   - Evidence: modernization has 1,087 distinct task IDs across 1,505 rows; inference has 1,109 across 1,414 rows. Five task IDs appear at least 5 times: `CQ-914` appears 6 times; `CQ-1118`, `CQ-1191`, `CQ-1223`, and `IQ-878` appear 5 times each.
   - Impact: a task ID alone is not a stable commit key. Reused CQ/IQ IDs need timestamp and file evidence before they can support Law 6 queue traceability or Law 7 blocker-repeat conclusions.

5. WARNING - the most provenance-sensitive period coincides with falling task uniqueness.
   - Evidence: modernization task uniqueness fell to 65.3% on 2026-04-21 and 63.4% on 2026-04-22; inference fell to 64.8% on 2026-04-21 and 72.3% on 2026-04-22. Those days also contain dense iteration volume: 248 and 246 modernization rows, and 219 and 224 inference rows.
   - Impact: high-volume days with many repeated task IDs are precisely where retroactive audit linkage needs structured commit fields most. Without them, long-window trend conclusions can over-count or under-count repeated work.

6. INFO - basic builder evidence fields are complete through the database's active window.
   - Evidence: across 1,505 modernization and 1,414 inference rows, `task_id`, `files_changed`, `notes`, `validation_cmd`, and `validation_result` are all populated; every builder row has `status='pass'` and no `error_msg`.
   - Impact: the DB is still useful for coarse productivity and validation-evidence trends through 2026-04-23, but not for precise commit-level provenance.

7. WARNING - post-DB git activity is outside this structured provenance store.
   - Evidence: the last builder DB timestamps are `2026-04-23T12:01:29` for modernization and `2026-04-23T12:06:44` for inference. Local git history after `2026-04-23T12:06:44+02:00` contains 678 TempleOS commits and 587 holyc-inference commits.
   - Impact: current retroactive audits must continue writing file-based reports unless ingestion resumes with commit SHA, north-star, branch, and audit-result fields.

## Supporting Extracts

| Agent | Rows | First timestamp | Last timestamp | Distinct tasks | Missing task/files/notes | Notes mentioning commit/sha |
| --- | ---: | --- | --- | ---: | ---: | ---: |
| inference | 1,414 | 2026-04-12T13:53:13 | 2026-04-23T12:06:44 | 1,109 | 0 / 0 / 0 | 414 |
| modernization | 1,505 | 2026-04-12T13:51:32 | 2026-04-23T12:01:29 | 1,087 | 0 / 0 / 0 | 46 |

| Agent | Tasks | Once | Twice | 3-4 rows | 5+ rows | Max rows per task |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,109 | 853 | 215 | 40 | 1 | 5 |
| modernization | 1,087 | 753 | 267 | 63 | 4 | 6 |

| Agent | Lowest uniqueness day | Rows | Task uniqueness | Average churn per row |
| --- | --- | ---: | ---: | ---: |
| inference | 2026-04-21 | 219 | 64.8% | 273.5 |
| modernization | 2026-04-22 | 246 | 63.4% | 229.1 |

## Recommendation

- Add structured provenance fields before relying on `temple-central.db` for commit-level audit history: `commit_sha`, `parent_sha`, `branch`, `remote_ref`, `north_star_result`, and `north_star_explanation`.
- Backfill existing rows from git/audit reports only after defining deterministic join rules for timestamp windows and repeated CQ/IQ task IDs.
- Keep current retroactive audit artifacts in `audits/retro/` and `audits/trends/` as the source of truth for post-2026-04-23 activity until database ingestion catches up.
