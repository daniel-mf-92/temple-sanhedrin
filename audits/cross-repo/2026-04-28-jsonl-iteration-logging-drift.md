# Cross-Repo Audit: JSONL Iteration Logging Drift

Generated: 2026-04-28T22:52:55+02:00
Scope: TempleOS `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`, holyc-inference `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`, and Sanhedrin policy surfaces in this repo.
Audit angle: Cross-repo invariant check

## Question

Do the Trinity repos now share one durable iteration-provenance contract after the 2026-04-27 reform that made `automation/logs/iterations.jsonl` the writable logging path and made direct `temple-central.db` writes a blocker pattern?

## Evidence

- TempleOS `MODERNIZATION/LOOP_PROMPT.md`, holyc-inference `LOOP_PROMPT.md`, and Sanhedrin `LOOP_PROMPT.md` all contain the reform override: the central SQLite DB is sandbox-readonly, builders should append one JSON line to `automation/logs/iterations.jsonl`, and repeated `readonly database` retries are a violation.
- The same prompt files still retain earlier direct `sqlite3 ~/Documents/local-codebases/temple-central.db "INSERT INTO iterations ..."` instructions above the override, so the durable contract depends on agents reading and correctly applying the later section.
- TempleOS currently has 55 lines in `automation/logs/iterations.jsonl`, zero missing required JSON fields among those lines, and no `automation/pending_temple_central_inserts.sql` file.
- holyc-inference currently has 17 lines in `automation/logs/iterations.jsonl`, zero missing required JSON fields among those lines, and 95 lines in `automation/pending_temple_central_inserts.sql`.
- The holyc-inference pending SQL backlog contains 95 `INSERT INTO iterations` statements, 52 mentions that the central DB was read-only, and 77 queue-floor/queue-replenishment references that are stale under the same 2026-04-27 reform.
- The Sanhedrin working tree has no `automation/logs/iterations.jsonl` file and has 277 lines in `automation/pending_temple_central_inserts.sql`, with 270 `INSERT INTO iterations` statements. `LOOP_PROMPT.md` still says to log audit results to DB and "only write a markdown audit file if there's a CRITICAL violation" before the later JSONL override.
- No QEMU or VM command was executed for this audit. TempleOS and holyc-inference repos were read-only.

## Findings

1. WARNING: The post-reform logging contract is not encoded as a single source of truth.
   All three prompts include the correct JSONL override, but they also preserve older SQLite INSERT instructions in earlier sections. This creates an avoidable historical-audit ambiguity: a future or resumed agent can quote the obsolete instruction path while still appearing to have read the prompt.

2. WARNING: holyc-inference still carries a large obsolete pending-SQL backlog after JSONL adoption.
   The repo has 17 valid JSONL rows but also 95 pending SQL rows. More than half of those pending rows explicitly mention read-only DB handling, and most still mention old queue-floor maintenance. That backlog can mislead retroactive auditors into treating staged SQL as canonical iteration telemetry even though the current contract is JSONL plus host ingestion.

3. WARNING: Sanhedrin policy remains more DB-centric than the builder policy.
   The Sanhedrin prompt still makes central DB reads and writes first-class execution steps, while the working tree has pending SQL rather than JSONL audit rows. That weakens cross-repo parity: the auditors are expected to police a JSONL migration, but their own policy surface still centers the stale SQLite write path.

4. INFO: TempleOS has converged furthest on the new logging path.
   The modernization repo has 55 JSONL rows, all with the required fields checked in this pass, and no pending SQL backlog. The latest entries carry task ID, files, status, and notes fields suitable for file-based retroactive audit.

5. WARNING: JSONL rows still under-specify exact validation output and commit linkage.
   The JSONL schema records `ts`, `agent`, `task_id`, `status`, `files`, and `notes`, but it does not structurally require `commit_sha`, `validation_cmd`, `validation_result`, `north_star_result`, or the exact RED output. This continues the provenance weakness previously observed in `temple-central.db`, now in the replacement log stream.

## LAWS.md Impact

- Law 5 is affected because north-star justification and RED/PASS evidence are not structurally captured in the replacement log.
- Law 6 is affected because stale pending SQL still contains queue-floor language after the append-only queue reform abolished that behavior.
- Law 7 is affected because repeated `readonly database` handling is preserved in staged SQL artifacts even though the current rule says to log once and move on.

## Recommended Remediation

- Collapse the logging instructions in all three prompts so only the JSONL path remains authoritative; keep direct SQLite reads as read-only historical analysis only.
- Move or mark `pending_temple_central_inserts.sql` as pre-reform legacy evidence in holyc-inference and Sanhedrin so it cannot be mistaken for current telemetry.
- Extend JSONL rows with structured `commit_sha`, `validation_cmd`, `validation_result`, `north_star_result`, and `north_star_notes` fields before treating JSONL as a complete replacement for commit-level audit provenance.
