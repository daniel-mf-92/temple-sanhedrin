# Cross-Repo Serial Token Channel / Mirror Drift Audit

Timestamp: 2026-05-02T04:02:11+02:00

Scope: read-only cross-repo invariant check across `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` and `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`.

TempleOS head inspected: `9f3abbf263982bf9344f8973a52f845f1f48d109` (`codex/modernization-loop`)

holyc-inference head inspected: `2799283c9554bea44c132137c590f02034c8f726` (`main`)

No QEMU, VM, network, or live liveness command was executed. This was a source-only historical/deep cross-repo audit.

## Invariant Under Audit

holyc-inference's north star requires a pure HolyC forward pass inside the TempleOS guest that outputs the next token id over serial. TempleOS LAWS require the Book of Truth to keep serial exfiltration present, synchronous, fail-stop, and local-only. The cross-repo invariant is:

1. serial is the only accepted guest-to-host token/evidence channel for inference benchmarking;
2. Book-of-Truth serial mirroring cannot be disabled or restored to disabled by helper/probe paths;
3. benchmark serial capture must not become an alternate remote log-view/export channel.

## Findings

### WARNING 1. TempleOS exposes a public serial mirror setter that accepts `FALSE`

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1056` defines `BookTruthSerialMirrorSet(Bool on=TRUE)`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1058` assigns `bot_serial_mirror_enabled=on` with no strict clamp to `TRUE`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC:98` exports that setter.

Impact: this is drift against Law 3's "removal of serial port exfiltration logic" and "disable logging flag/API" boundary. It is also a cross-repo risk because holyc-inference depends on serial output for the token result and cannot distinguish "model produced no token" from "TempleOS mirror was disabled" without a mandatory mirror-on proof.

### WARNING 2. Serial mirror probe restores the mirror to disabled if it started disabled

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1081` captures `mirror_before=bot_serial_mirror_enabled`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1082` through `1085` force-enable the mirror only for the probe append.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruthSerialCore.HC:1091` through `1092` call `BookTruthSerialMirrorSet(FALSE)` when the mirror was previously off.

Impact: probe success can coexist with a post-probe disabled mirror. That weakens both TempleOS proof semantics and holyc-inference benchmark semantics because a serial health probe does not establish that subsequent token output remains mirrored.

### WARNING 3. A burst-status helper also restores the mirror to disabled after generating evidence

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:72089` records `mirror_enabled_before`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:72091` through `72093` force-enable serial mirroring for the helper when needed.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:72185` through `72186` call `BookTruthSerialMirrorSet(FALSE)` if the helper forced the mirror on.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:72188` through `72192` treat restoration to the prior disabled state as expected.

Impact: this preserves a disabled steady state as legitimate after an audit helper emits healthy-looking evidence. Under the cross-repo serial-token invariant, audit helpers should be able to force the mirror on, but should not normalize returning to off.

### WARNING 4. TempleOS secure-local policy can repair serial mirroring, but it is a check path rather than a write-path invariant

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13280` through `13284` classify disabled serial mirror as a secure-local policy violation.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:13288` through `13291` repair it only when the policy check runs with `enforce`.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC:2506` through `2509` allow reclaiming a sealed page only when serial mirror is enabled and serial is live, showing the core code recognizes mirror state as a safety precondition.

Impact: the safety property is checked and sometimes repaired, but it is not represented as an always-on invariant at the public setter/probe boundary. holyc-inference's serial token channel needs the stronger property: if serial is the contract, mirror-on should be fail-closed before token/evidence generation starts.

### WARNING 5. holyc-inference benchmark docs specify serial capture and air-gap, but not a Book-of-Truth mirror-on precondition

Evidence:

- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md:7` requires the guest to output a token id over serial.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md:30` through `32` describe serial capture as the benchmark observation channel.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md:34` through `35` document `-nic none`, but do not require a serial mirror status/probe line before accepting token output.
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py:150` through `157` hard-code `-nic none`, `-serial stdio`, and a TempleOS image drive, then parse serial text.

Impact: the inference side enforces guest air-gap at the QEMU argument layer, but the serial evidence contract is underspecified. A benchmark can pass or fail based on raw serial text without proving the TempleOS Book-of-Truth mirror was enabled and fail-stop for the same run.

## Healthy Observations

- holyc-inference's benchmark path uses serial capture rather than network transport.
- The QEMU benchmark builder rejects user-supplied network devices and injects `-nic none`.
- TempleOS has secure-local policy checks that identify disabled serial mirroring as a violation and can repair it when that check is invoked with enforcement.
- No WS8 networking execution or guest networking implementation was observed in this audit slice.

## Recommended Remediation

- Clamp `BookTruthSerialMirrorSet(FALSE)` requests to enabled under secure-local / installed-mode policy, and record a blocked-disable event instead of honoring the off state.
- Change probe and burst helpers so forced-on serial mirroring remains on after the helper, or at least fail closed when the pre-helper state was off.
- Add a mandatory serial preamble for inference benchmark runs: mirror status enabled, serial live, fail-stop strict, and no dead UART before accepting `BENCH_RESULT` token output.
- Keep benchmark capture local-only: serial-to-stdio/file for local host validation is acceptable, but do not introduce socket, HTTP, TCP, or remote log viewing around the captured stream.

Finding count: 5
