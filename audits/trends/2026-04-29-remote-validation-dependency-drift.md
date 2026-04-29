# Historical Remote Validation Dependency Drift Audit

Timestamp: 2026-04-29T15:11:58+02:00

Audit angle: historical drift trends. This pass queried `temple-central.db` read-only for host-side remote validation evidence in builder iteration rows, then spot-checked current TempleOS and holyc-inference policy text. No TempleOS or holyc-inference source file was modified. No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, or package-network action was executed.

Repositories/evidence reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `ada76461a008`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a2`
- Sanhedrin audit repo: `/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55` at `b6cf7f9757d9`
- DB: `/Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db`
- SQL: `audits/trends/2026-04-29-remote-validation-dependency-drift.sql`

## Source Counts

| Agent | Rows | SSH rows | Azure rows | SCP rows | HTTP/curl rows | Remote-blocked rows | SSH row share |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| inference | 1,414 | 0 | 0 | 0 | 0 | 0 | 0.00% |
| modernization | 1,505 | 194 | 183 | 8 | 0 | 0 | 12.89% |

Modernization daily remote-validation concentration:

| Day | Rows | SSH rows | Azure rows | SCP rows |
| --- | ---: | ---: | ---: | ---: |
| 2026-04-13 | 137 | 1 | 1 | 0 |
| 2026-04-15 | 31 | 1 | 1 | 0 |
| 2026-04-16 | 68 | 1 | 1 | 0 |
| 2026-04-19 | 142 | 32 | 27 | 5 |
| 2026-04-20 | 225 | 65 | 62 | 0 |
| 2026-04-21 | 248 | 31 | 30 | 1 |
| 2026-04-22 | 246 | 52 | 50 | 2 |
| 2026-04-23 | 34 | 11 | 11 | 0 |

## Findings

1. WARNING - Modernization DB evidence normalized remote Azure validation as ordinary pass evidence.
   - Evidence: 194 of 1,505 modernization rows contain `ssh`, 183 mention `azureuser@` or `52.157.*`, and 8 contain `scp`; all are recorded as successful pass rows rather than a separate host-remote validation class.
   - Impact: historical dashboards can overstate local physical validation. Law 2 air-gap is not automatically violated when the QEMU guest uses `-nic none`, but host-remote validation is a different trust boundary from local-console or local-host validation.

2. WARNING - The remote-validation trend is concentrated exactly in the Book-of-Truth implementation window.
   - Evidence: the first/last sample rows include Book-of-Truth work such as `CQ-216`, `CQ-133`, `CQ-147`, many `CQ-5xx` rows, and latest `CQ-1351/CQ-1352`; the daily concentration peaks at 65 SSH rows on 2026-04-20 and 52 SSH rows on 2026-04-22.
   - Impact: Law 11 local-access audits cannot treat all historical serial/Book-of-Truth validations as physically local unless the validation surface says so explicitly.

3. WARNING - Current policy text still advertises SSH test hosts while also requiring local-only Book-of-Truth access.
   - Evidence: TempleOS `MODERNIZATION/LOOP_PROMPT.md:81-98` says a real TempleOS instance runs on Azure, gives `ssh -o StrictHostKeyChecking=no azureuser@52.157.85.234`, shows QEMU serial capture to `/tmp/serial.log`, and tells builders to check serial output for Book-of-Truth entries. TempleOS `MODERNIZATION/MASTER_TASKS.md:222-230` says Book-of-Truth serial mirror output must be physically local and not remotely accessible.
   - Impact: this is a policy contradiction for future audits: remote compile-only validation may be acceptable, but remote inspection of serial output that can contain Book-of-Truth rows is not.

4. WARNING - holyc-inference advertises the same SSH compile host despite having zero DB rows that used it.
   - Evidence: holyc-inference `LOOP_PROMPT.md:83-92` gives the Azure IP, SSH command, and says serial output captures compilation results; the DB window has 0 inference SSH/Azure/SCP rows.
   - Impact: the absence of historical inference usage is good, but the prompt still invites a future worker to use a remote host for TempleOS serial capture without a structured distinction between compile output and Book-of-Truth-bearing output.

5. WARNING - The DB schema has no validation locality/provenance field.
   - Evidence: `iterations` stores free-text `validation_cmd`, `validation_result`, `error_msg`, and `notes`, but no `validation_location`, `host_transport`, `serial_access_mode`, or `book_of_truth_output_seen` field. The trend SQL had to infer SSH/Azure/SCP usage from prose.
   - Impact: retroactive Law 2 and Law 11 scoring remains brittle. A pass row with `-nic none` and `ssh azureuser@...` can be guest-air-gapped while still violating, or drifting toward violating, the physical-local Book-of-Truth observation model.

## Non-Findings

- The DB query found 0 inference rows with SSH/Azure/SCP validation in the 2026-04-12 through 2026-04-23 DB window.
- The DB query found 0 builder rows with `curl`, `wget`, or `http` in validation text. A current TempleOS source spot-check still found `automation/qemu-compile-test.sh:13` and `:23-29` contain an ISO download path; that is already a separate Law 2 source-surface issue.
- The historical rows sampled here usually referenced QEMU `-nic none`; this audit does not claim guest networking was enabled.

## Recommendations

- Add structured validation provenance fields: `validation_location`, `host_transport`, `qemu_network_mode`, `serial_access_mode`, `bot_output_seen`, and `remote_compile_only`.
- Update prompts so remote SSH hosts are allowed only for compile-only checks that suppress or redact Book-of-Truth serial contents.
- Treat any historical row that combines `ssh`/`scp` with Book-of-Truth serial inspection as ineligible for Law 11 local-access proof unless it carries explicit local physical-access evidence.
- Keep guest air-gap checks separate from host-observer checks: `-nic none` proves no guest NIC, not physical-local Book-of-Truth access.

## Read-Only Verification Commands

```bash
sqlite3 -header -csv /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db "..."
sqlite3 -header -column /Users/danielmatthews-ferrero/Documents/local-codebases/temple-central.db < audits/trends/2026-04-29-remote-validation-dependency-drift.sql
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/LOOP_PROMPT.md | sed -n '76,98p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '222,234p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/LOOP_PROMPT.md | sed -n '78,92p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/qemu-compile-test.sh | sed -n '1,80p'
```
