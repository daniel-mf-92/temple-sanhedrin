# Cross-Repo Write-Fail Token Event Contract Drift Audit

Timestamp: 2026-04-29T06:09:49+02:00

Scope: TempleOS `abbc679bc7c4` and holyc-inference `ce09228422da`, read-only. This audit checks whether TempleOS' Book-of-Truth write-fail halt contract is represented in the holyc-inference per-token Book-of-Truth event ABI.

Laws reviewed: Law 2 air-gap sanctity, Law 3 Book of Truth immutability, Law 8 hardware proximity, Law 9 resource supremacy / crash on log failure, Law 11 local-only Book of Truth access.

## Summary

TempleOS now has an explicit write-fail halt path: append failure or serial timeout routes to `BookTruthWriteFailHlt`, records a `WRITE FAIL` status line, forces liveness halt flags on, and executes `SysHlt`. holyc-inference has recently implemented per-token Book-of-Truth event emission, but its ABI only carries `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}` plus `{blocked, emitted}` status. That means the worker-plane token event contract cannot currently distinguish "token not emitted because the Book of Truth is dead and the OS halted" from ordinary policy blocking or local buffer failure.

Findings: 4 warnings, 0 critical.

## Evidence

- TempleOS defines `BOT_WRITE_FAIL_REASON_APPEND=1` and `BOT_WRITE_FAIL_REASON_TIMEOUT=2`, increments `bot_write_fail_halts`, stores the last reason/payload, forces halt flags on, prints `BookTruth: WRITE FAIL -- ...`, then calls `SysHlt` in `TempleOS/Kernel/BookOfTruthSerialCore.HC:34-49`.
- TempleOS exposes `BookTruthFailStopStatus` with `write_fail_halts`, `write_fail_reason`, and `write_fail_payload` in `TempleOS/Kernel/BookOfTruthSerialCore.HC:84-91`.
- TempleOS calls `BookTruthWriteFailHlt(BOT_WRITE_FAIL_REASON_APPEND, ...)` when `BookTruthAppend` fails in `BookTruthSerialMirrorProbe` at `TempleOS/Kernel/BookOfTruthSerialCore.HC:1085-1088`.
- TempleOS calls `BookTruthWriteFailHlt(BOT_WRITE_FAIL_REASON_TIMEOUT, ...)` after serial liveness timeout after appending `BOT_EVENT_SERIAL_DEAD` at `TempleOS/Kernel/BookOfTruthSerialCore.HC:1378-1386`.
- TempleOS' write-fail smoke fixture requires `BookTruthSerialTimeoutSet`, `BookTruth: WRITE FAIL --`, and `BookTruthFailStopStatus` lines and validates reason, halt counter, halt flags, and nonzero payload in `TempleOS/automation/bookoftruth-write-fail-smoke.sh:46-99`.
- holyc-inference declares the token Book-of-Truth event tuple as 6 cells and status domain as only `blocked=0` and `emitted=1` in `holyc-inference/src/model/inference.HC:26-32`.
- holyc-inference's token emitter contract snapshots `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}`, requires secure-local digest match, and only publishes `event_status`, `event_count`, and `event_digest_q64` in `holyc-inference/src/model/inference.HC:3371-3516`.
- holyc-inference mission text still promises every token is logged to the Book of Truth and WS8-03 remains the Book-of-Truth integration hook workstream in `holyc-inference/MASTER_TASKS.md:9-24` and `:112-116`.
- Scoped search found no holyc-inference runtime or policy gate contract for TempleOS `WRITE FAIL`, `write_fail_reason`, `write_fail_halts`, `BookTruthFailStopStatus`, or UART halt state. Matches for "write failure" were unrelated attention harness test names.

## Findings

### WARNING 1 - Token emission status cannot represent TempleOS hard halt

TempleOS distinguishes hard log failure from normal log events: append failure and timeout both route through `BookTruthWriteFailHlt` and stop the system. holyc-inference only reports token event status as `blocked` or `emitted`.

Impact: A future cross-repo runner can see a missing token event after a TempleOS halt and has no ABI-level way to say "the Book of Truth died; Law 9 intentionally killed the machine." That weakens retroactive auditability because ordinary policy block, digest mismatch, buffer underflow, and serial-death halt collapse into adjacent host-side symptoms.

Recommended invariant: Extend the inference/Sanhedrin token event contract with a fail-stop outcome class, or define a separate required host-side serial record that maps TempleOS `WRITE FAIL` lines into inference session audit state.

### WARNING 2 - Reason and payload domains are not shared

TempleOS now has a concrete reason domain `{append=1, timeout=2}` and a payload field for write-fail halts. The inference token event digest excludes both fields and only hashes token/session/policy tuple fields.

Impact: If a token event stream stops during generation, inference artifacts cannot identify whether the upstream failure was append-path failure, TX timeout, policy mismatch, or local no-write validation. This is specifically a Law 9 evidence gap, not a runtime violation: the OS may halt correctly, but the worker-plane audit trail does not preserve the halt reason.

Recommended invariant: Add a cross-repo `bot_failstop_reason` vocabulary and require Sanhedrin to treat TempleOS `write_fail_reason` as authoritative when joining token events to serial evidence.

### WARNING 3 - The smoke fixture includes post-halt status that a live halt path cannot guarantee

The TempleOS write-fail smoke fixture includes a `BookTruthFailStopStatus` line after `BookTruth: WRITE FAIL -- ...`, but the live `BookTruthWriteFailHlt` implementation calls `SysHlt` immediately after printing the write-fail line.

Impact: Consumers that require post-halt status from a real guest may wait for evidence that cannot exist after an immediate halt. For fixture-mode validation that is fine, but cross-repo consumers need to mark post-halt status as synthetic or pre-halt-only.

Recommended invariant: Split the fixture grammar into "live minimum" (`WRITE FAIL` line before halt) and "synthetic diagnostic extension" (`BookTruthFailStopStatus` allowed only in fixture/replay mode).

### WARNING 4 - Trinity policy sync checks broad Book-of-Truth presence, not write-fail semantics

holyc-inference's `automation/check-trinity-policy-sync.sh` currently checks that dev-local guardrails mention air-gap and Book of Truth, but it does not check for write-fail/halt semantics, serial liveness state, or Law 9 fail-stop reason vocabulary.

Impact: The policy sync gate can pass while TempleOS and holyc-inference disagree about what happens when the Book of Truth cannot be written. That is a cross-repo drift risk because the exact Law 9 behavior is now more specific than the policy-sync regexes.

Recommended invariant: Add a non-source policy check that looks for `write_fail`, `halt_on_dead`, or an agreed fail-stop reason vocabulary in the docs/ABI surfaces consumed by both repos.

## Non-Findings

- No TempleOS networking or QEMU command was executed by this audit.
- The inspected TempleOS write-fail smoke script checks for explicit `-nic none` or `-net none` evidence before validating serial fixtures, consistent with Law 2.
- No Trinity source files were modified.
- holyc-inference runtime files inspected in `src/` remain HolyC.

## Follow-Up

Open one cross-repo issue for a Book-of-Truth fail-stop evidence ABI. Minimum acceptance criteria: a serial fixture with `BookTruth: WRITE FAIL -- reason=<1|2> payload=<nonzero>` must join to an inference session as `bot_failstop=true` without requiring any post-`SysHlt` status line.
