# Law 9 Diagnostic Fail-Stop Boundary Research

Timestamp: 2026-04-30T09:53:27+02:00

Audit angle: deeper `LAWS.md` research.

Scope:
- Sanhedrin `LAWS.md` on `codex/sanhedrin-gpt55-audit`.
- TempleOS `Kernel/BookOfTruthSerialCore.HC` and `MODERNIZATION/MASTER_TASKS.md` inspected read-only.
- No TempleOS or holyc-inference source files were modified.
- No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed.

## Question

How should Law 9 score diagnostic or replay code that accepts a non-fatal parameter such as `halt_on_dead=FALSE` when the live path is supposed to clamp back to fail-stop?

`LAWS.md` says any config flag, boot parameter, or API that disables halt-on-failure behavior is a violation, and also says dead UART equals immediate `HLT`. TempleOS currently has diagnostic/replay surfaces that pass non-fatal arguments, while the serial core also contains strict clamping that forces the effective live setting back to halt.

The intended invariant should be:

> Live Book-of-Truth write, append, serial-liveness, tamper, and integrity failure paths must be fail-stop with no caller-visible bypass. Diagnostic/replay helpers may simulate or count failure without halting only if they are explicitly non-live, cannot alter live policy, and record that non-fatal mode was blocked or sandboxed from the live path.

## Evidence

1. `LAWS.md` lines 123-138 require the OS to die before the log dies, forbid any API that disables halt-on-failure, require unconditional `HLT` in the write path, and say dead UART means immediate `HLT`.

2. TempleOS `MODERNIZATION/MASTER_TASKS.md` lines 196-204 is stricter prose: no fallback, no skip, no delayed logging, no workaround, and no code path that allows continued execution if the log cannot be written.

3. Current TempleOS `BookTruthWriteFailHlt` records fail-stop metadata, forces serial timeout/liveness halt flags back on, prints a write-fail line, and calls `SysHlt` in `Kernel/BookOfTruthSerialCore.HC` lines 37-50.

4. Current TempleOS `BookTruthFailStopClamp` blocks non-fatal requests when strict policy is active, and `BookTruthFailStopSet(FALSE)` still leaves strict mode true while incrementing a blocked counter in lines 52-82.

5. Current TempleOS live setters/checks accept `halt_on_dead` arguments but then force `halt_eff=TRUE` before updating live policy in lines 1280-1324 and 1339-1364.

6. Diagnostic/replay surfaces still pass or expose non-fatal parameters: `BookTruthSerialLivenessFailStopAlertReplay` calls `BookTruthSerialLivenessCheck(..., FALSE, FALSE)` at lines 880-884, and `BookTruthSerialLivenessSweep` defaults `halt_on_dead=FALSE` at lines 1403-1427.

## Findings

1. **WARNING - Law 9 lacks a diagnostic/replay exception boundary.**  
   Evidence: the written law treats any disabling API as a violation, but current code contains replay/sweep helpers that accept or pass non-fatal failure arguments. Because the live check clamps to halt, the source may be safe, but auditors need a rule for when such arguments are harmless simulation versus prohibited live policy.

2. **WARNING - "Immediate HLT" needs a definition for sampled liveness checks.**  
   Evidence: Law 9 says dead UART means immediate `HLT`; current liveness code uses `bot_serial_timeout_limit` and a timeout streak before calling `BookTruthWriteFailHlt`. If `dead_limit` is always forced to 1 for live paths, this can satisfy the law; if diagnostic callers can raise it in live execution, it becomes a violation. The doctrine should state that live paths require first failed required write/liveness observation to halt, while replay windows may count failures without representing live behavior.

3. **WARNING - Audit reports need separate labels for `requested_halt` and `effective_halt`.**  
   Evidence: current status strings preserve both requested and effective values (`halt_req`, `halt_on_dead`), but retro audits often grep only for `halt_on_dead=FALSE` or for an exported parameter. A report can false-positive if it ignores clamping, or false-negative if it ignores a public bypass that actually changes effective live policy.

4. **INFO - The current code already suggests the safe doctrine.**  
   Evidence: strict clamping, blocked counters, and `BookTruthWriteFailHlt` provide a model: non-fatal requests may be accepted as inputs only when they are denied for live policy and are visible as blocked/diagnostic evidence. That should be promoted into `LAWS.md` so future builders preserve the boundary intentionally.

## Proposed LAWS.md Refinement

Add under Law 9:

```text
Diagnostic/replay boundary: helpers may simulate or summarize Book-of-Truth failure states without halting only when they do not perform a live required log write, do not change live fail-stop policy, and clearly report `diagnostic_only=1`. Any live path that observes a required append/write/serial-liveness failure must halt on the first required failure observation.

For any API accepting `halt_on_fail`, `halt_on_dead`, `strict`, `dead_limit`, or equivalent controls, auditors must distinguish requested policy from effective policy. A non-fatal request is allowed only if the effective live policy remains fail-stop and the rejected request is recorded as blocked. If the effective live policy can continue after a live Book-of-Truth failure, it is a Law 9 violation.
```

Add an audit rule:

```text
When reviewing fail-stop commits, record both `requested_halt` and `effective_halt`. A finding should cite the live call path that can continue after failure, not only the existence of a diagnostic parameter.
```

## Local Issue Opened

See `audits/issues/2026-04-30-law9-diagnostic-failstop-boundary-issue.md`.

