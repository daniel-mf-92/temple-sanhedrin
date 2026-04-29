# Law 8 Backfill: UART Append Proximity and Producer Continuity

Timestamp: 2026-04-29T08:23:24+02:00

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Scope: historical compliance backfill for LAWS.md Law 8's UART emission clause, focused on the TempleOS Book-of-Truth append path and serial mirror producer continuity. TempleOS and holyc-inference source trees were read-only. No VM, QEMU, networking, or WS8 networking command was executed.

Repos examined:
- TempleOS: `75727979e5cba07e7959d4770c9abffe85be78e1`
- holyc-inference: `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin: branch `codex/sanhedrin-gpt55-audit`

## Rule Under Audit

Law 8 requires each Book-of-Truth act to be recorded synchronously and as close to hardware as possible:

- hardware event occurs
- entry is composed in the same instruction sequence
- `out 0x3F8` emits bytes to serial in that same instruction sequence
- entry is written to the in-memory ring buffer in that same instruction sequence
- no callback, deferred write, queue, buffer flush, driver abstraction layer, or bypassable software layer sits between event and record

Backfill compliance score for this UART append surface: **0/4 compliant**.

## Finding CRITICAL-001: Current HEAD has no `BookTruthAppend` implementation, only a declaration

Evidence:
- Current HEAD of `Kernel/BookOfTruth.HC` declares `public Bool BookTruthAppend(I64 event_type,I64 source=BOT_SOURCE_KERNEL,I64 payload=0);` at line 669.
- A current `git grep` for `public Bool BookTruthAppend|Bool BookTruthAppend` across TempleOS HEAD finds no implementation body outside that declaration.
- Current HEAD still has many call sites: the audited Book-of-Truth files contain 43 `BookTruthAppend(` references across `Kernel/BookOfTruth.HC` and `Kernel/BookOfTruthSerialCore.HC`.
- The only current `OutU8(BOT_COM1_BASE+BOT_COM1_TX,...)` hit in `Kernel/BookOfTruth.HC` is UART divisor initialization, not per-entry ledger emission.

Historical introduction:
- Commit `5f64ffc89375d92fcc78eaf1505ee2325af2705d` on 2026-04-21 deleted 21,559 lines from `Kernel/BookOfTruth.HC`.
- Before that deletion, commits such as `945d23e872141c2019de4734ea0d211646082bad` still had the append body and ended append with `BookTruthSerialMirror(e);`.
- From `5f64ffc89375d92fcc78eaf1505ee2325af2705d` through current HEAD there are 1,012 TempleOS commits in the range, all inheriting the missing append producer unless independently restored. The current tree shows it was not restored.

Assessment:
This is a direct Law 8 failure and also undermines Laws 3 and 9. A Book-of-Truth path with only call sites and no append implementation cannot prove synchronous UART emission, immediate ring-buffer recording, hash-chain update, or halt-on-write-failure behavior.

Required remediation:
- Restore a real `BookTruthAppend` body in the core Book-of-Truth source.
- Add a static Sanhedrin check that rejects any TempleOS commit where `BookTruthAppend(` call sites exist but no implementation body exists.
- Require that the implementation includes per-entry UART data-register emission, not only UART initialization.

## Finding CRITICAL-002: The original append implementation routed UART emission through helper layers, not inline `out 0x3F8`

Historical evidence:
- Commit `427bdc245605ec9e93b1d0d2a97b9dce85bf6323` introduced `BookTruthAppend` and serial mirroring.
- That implementation composed and stored the ring entry, unlocked the Book-of-Truth lock, then called `BookTruthSerialMirror(e)`.
- `BookTruthSerialMirror` formatted a string, called `BookTruthSerialPutStr`, which looped into `BookTruthSerialPutChar`, which finally executed `OutU8(BOT_COM1_BASE+BOT_COM1_TX,ch)`.
- Commit `945d23e872141c2019de4734ea0d211646082bad` retained that helper-chain shape while adding serial-dead precheck logic.

Assessment:
The helper chain eventually touches COM1, but Law 8 is stricter than "some serial output happens." It requires the serial `out 0x3F8` to be part of the same operation being logged, with zero bypassable software layers. `BookTruthAppend -> BookTruthSerialMirror -> BookTruthSerialPutStr -> BookTruthSerialPutChar -> OutU8` is a multi-function emission layer, and the ring entry is updated before the serial write completes.

Required remediation:
- Inline the UART byte emission path inside the append path, or use a tightly scoped non-overridable macro that expands directly to `OUT`/`OutU8` in the append sequence.
- Keep format construction, display helpers, and CLI summaries outside the mandatory per-entry hardware emission path.

## Finding WARNING-001: Later serial-liveness work added consumer/status surfaces around a missing append producer

Evidence:
- Commit `aacf08adc8b2d9cc53a6abd6d3090b36c9ed1f2d` added 544 lines to `Kernel/BookOfTruth.HC`, 4 lines to `Kernel/BookOfTruthSerialCore.HC`, and 15 externs to `Kernel/KExts.HC` after the append body had already been removed.
- At `aacf08adc8b2d9cc53a6abd6d3090b36c9ed1f2d`, the audited files had 13 `BookTruthAppend(` references, but the only `public Bool BookTruthAppend` match was still a declaration.
- Current HEAD expands this pattern to 43 audited `BookTruthAppend(` references and a large set of serial-dead, watchdog, liveness, risk-band, digest, and reset-proof commands.
- Current `automation/holyc-book-truth-headless-check.sh` only requires the fixed string `public Bool BookTruthAppend`, so a declaration-only source still passes that marker check.

Assessment:
The later liveness/status work may be useful as analysis code, but it cannot establish Law 8 compliance while the append producer is absent. It risks reporting health about an event stream that the current source cannot actually append or serial-mirror.

Required remediation:
- Gate serial-liveness and watchdog evidence on a source-level producer-continuity check.
- Treat reports that parse historical or fixture entries as non-compliance evidence unless the current append producer also exists and passes proximity checks.

## Finding WARNING-002: The task ledger overstates serial mirror completion without a direct UART-proximity proof

Evidence:
- `MODERNIZATION/MASTER_TASKS.md` marks WS13-03 as complete: "Add serial port mirror -- log exits the machine to host via QEMU `-serial file:`".
- The same file states the strict hardware-proximity rule: logging uses raw `out` instructions to the UART data register, no driver abstraction, no callback, no deferred write, no queue, and one act equals one entry equals one serial write.
- Current HEAD does not contain a per-entry `OutU8(BOT_COM1_BASE+BOT_COM1_TX,...)` append path. It only retains UART setup writes and downstream status/analysis code.

Assessment:
The task ledger is stale relative to the actual source. Completion evidence for WS13-03 should not count unless the append path still contains a direct UART emission sequence.

Required remediation:
- Reclassify WS13-03 as needing Law 8 proximity backfill until a restored append path proves direct UART emission.
- Add a source smoke that checks both producer continuity and direct COM1 transmit use in the append path.

## Non-Findings

- No networking code or QEMU networking command was added or executed.
- holyc-inference was not flagged by this backfill because Law 8's UART append producer is TempleOS Book-of-Truth-specific.
- This audit did not perform live liveness watching; it only examined historical commits and current source state.

## Read-Only Verification Commands

- `git -C TempleOS grep -n "public Bool BookTruthAppend\\|Bool BookTruthAppend" HEAD -- .`
- `git -C TempleOS grep -n -E "public Bool BookTruthAppend|OutU8\\(BOT_COM1_BASE\\+BOT_COM1_TX|BookTruthSerialMirror\\(|BookTruthSerialPutChar" HEAD -- Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC`
- `git -C TempleOS log --reverse --format='%H%x09%ai%x09%s' -S'public Bool BookTruthAppend' -- Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC`
- `git -C TempleOS log --reverse --format='%H%x09%ai%x09%s' -S'OutU8(BOT_COM1_BASE+BOT_COM1_TX' -- Kernel/BookOfTruth.HC Kernel/BookOfTruthSerialCore.HC`
- `git -C TempleOS show --patch --unified=80 945d23e872141c2019de4734ea0d211646082bad -- Kernel/BookOfTruth.HC`
- `git -C TempleOS show --stat --oneline --find-renames 5f64ffc89375d92fcc78eaf1505ee2325af2705d -- Kernel/BookOfTruth.HC`
- `sed -n '1,80p' TempleOS/automation/holyc-book-truth-headless-check.sh`
