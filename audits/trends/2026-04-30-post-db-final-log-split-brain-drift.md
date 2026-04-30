# Post-DB Final Log Split-Brain Drift

Audit timestamp: 2026-04-30T08:59:22+02:00

Audit angle: historical drift trends. This pass compared the read-only `temple-central.db` iteration ledger against persisted builder `automation/logs/*.final.txt` summaries in the TempleOS and holyc-inference sibling worktrees. It did not inspect live liveness, restart processes, run QEMU, or modify TempleOS / holyc-inference source code. The TempleOS guest air-gap was not touched.

## Scope

- Database: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- SQL evidence pack: `audits/trends/2026-04-30-post-db-final-log-split-brain-drift.sql`
- TempleOS final-summary directory: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/logs`
- holyc-inference final-summary directory: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/automation/logs`
- TempleOS head observed read-only: `2083dc34edecdaddace3be5b51a8c8f4e9d09e2e`
- holyc-inference head observed read-only: `a70776642a09de7ed01b75aaaebbdd3243f84c2`
- LAWS.md focus: Law 5 progress evidence, Law 6 queue/iteration traceability, and Law 7 historical blocker evidence. This is not a current-iteration liveness check.

## Findings

1. WARNING - `temple-central.db` stopped receiving builder iteration rows before the current final-summary era.
   - Evidence: `iterations` has 14,606 rows and the latest builder timestamps are `modernization=2026-04-23T12:01:29` and `inference=2026-04-23T12:06:44`.
   - Counter-evidence outside the DB: TempleOS has 244 `*.final.txt` summaries from `20260427-155036` through `20260430-082347`; holyc-inference has 341 from `20260427-155031` through `20260430-083730`.
   - Impact: historical reports that query only `temple-central.db` miss at least 585 later builder iterations.

2. WARNING - Post-DB final summaries are split across unstructured per-iteration text files.
   - Evidence: sampled TempleOS and holyc-inference final summaries contain prose sections such as `Changed:`, `Verified:`, and `Blocked:`, but no stable row schema equivalent to `iterations(agent, task_id, status, files_changed, validation_cmd, validation_result, error_msg, duration_sec)`.
   - Impact: Law 5 and Law 6 trend queries must either ignore post-2026-04-23 work or scrape free-form human summaries, which is weaker than the old normalized ledger.

3. WARNING - Blocker evidence is heavily present in final summaries but absent from the DB status stream.
   - Evidence: 297 final-summary files mention commit/sandbox blockers using patterns such as `Operation not permitted`, `git add is blocked`, `Not committed`, `Could not commit`, or `Blocked:`.
   - DB contrast: `iterations.status='blocked'` has only 3 rows, all for `sanhedrin`; no modernization or inference blocked rows exist after the final-summary period began.
   - Impact: Law 7 blocker escalation can undercount persistent builder blockers if it reads only `temple-central.db`.

4. WARNING - Builder final-summary counts are large enough to change trend conclusions after April 23.
   - Evidence by date: TempleOS final summaries are 47 on 2026-04-27, 88 on 2026-04-28, 81 on 2026-04-29, and 28 on 2026-04-30. holyc-inference final summaries are 42, 124, 116, and 59 for the same dates.
   - Impact: Any long-window rate, status, cadence, blocker, or evidence-quality trend that ends at the DB max timestamp is stale for the current audit branch by roughly a week of builder activity.

5. INFO - The final-summary files preserve useful evidence, but need ingestion before they can replace the DB.
   - Evidence: recent summaries include changed file lists, validation commands, no-HolyC/no-QEMU notes, and explicit sandbox-commit blocker text.
   - Recommendation: backfill a second normalized table such as `final_summaries(repo, run_id, ts, summary_path, status_guess, blocker_guess, changed_files_text, validation_text, raw_text_sha256)` and keep `iterations` read-only as the pre-switch ledger.

## Supporting Extracts

DB endpoint:

| Agent | DB rows | Latest DB timestamp |
| --- | ---: | --- |
| inference | 1,414 | 2026-04-23T12:06:44 |
| modernization | 1,505 | 2026-04-23T12:01:29 |
| sanhedrin | 11,687 | 2026-04-23T11:54:59 |

Final-summary counts:

| Repo | Final summaries | First final summary | Latest final summary |
| --- | ---: | --- | --- |
| TempleOS | 244 | 20260427-155036 | 20260430-082347 |
| holyc-inference | 341 | 20260427-155031 | 20260430-083730 |
| Combined | 585 | 20260427-155031 | 20260430-083730 |

Commit/sandbox blocker mentions:

| Repo | Final summaries with blocker text | Total final summaries |
| --- | ---: | ---: |
| TempleOS | 119 | 244 |
| holyc-inference | 178 | 341 |
| Combined | 297 | 585 |

Daily final-summary volume:

| Date | TempleOS | holyc-inference | Combined |
| --- | ---: | ---: | ---: |
| 2026-04-27 | 47 | 42 | 89 |
| 2026-04-28 | 88 | 124 | 212 |
| 2026-04-29 | 81 | 116 | 197 |
| 2026-04-30 | 28 | 59 | 87 |

## Commands

```bash
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-30-post-db-final-log-split-brain-drift.sql
find ../templeos-gpt55/automation/logs -maxdepth 1 -type f -name '*.final.txt'
find ../holyc-gpt55/automation/logs -maxdepth 1 -type f -name '*.final.txt'
rg -l "Could not commit|Not committed|git add is blocked|Operation not permitted|blocked by the sandbox|Blocked:" ../templeos-gpt55/automation/logs/*.final.txt ../holyc-gpt55/automation/logs/*.final.txt
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
```

Finding count: 5 total, 4 warnings and 1 info.
