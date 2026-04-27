# Compliance Backfill: Law 11 Local Access Only

Scope: retroactive / historical compliance backfill for Book-of-Truth local-access boundaries. No TempleOS or holyc-inference source was modified, and no VM/QEMU command was executed.

Repos inspected:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit`

Applicable rules:
- Law 11: Book of Truth can only be read with direct physical access; no remote viewing ever.
- Law 11 violations include log export commands, print-to-file exports, serial output forwarding/streaming/proxying to a remote host, or any path that makes log contents available outside the local console.
- Law 2 remains satisfied only when QEMU explicitly disables networking; this backfill did not execute QEMU.

## Backfill Window

Historical introduction points checked:
- TempleOS `automation/qemu-headless.sh`: introduced by `48608e22561985badab9a5b19c54d862b3658181` on 2026-04-12 with headless serial capture semantics still present in current HEAD.
- TempleOS `MODERNIZATION/LOOP_PROMPT.md`: Azure/SSH test-host guidance dates back through early prompt commits, with the current file still instructing remote SSH testing and `/tmp/serial.log` inspection.
- holyc-inference `LOOP_PROMPT.md`: Azure/SSH test-host guidance appears in `e8ce7a26732726f7caf79a35682ff61492a0ce6c` on 2026-04-12 and remains in current HEAD.
- holyc-inference `bench/qemu_prompt_bench.py`: introduced by `842e667a8fa4a152c96fd97d691dc49181609ca5` on 2026-04-27 and currently persists serial stdout/stderr tails into JSON benchmark reports.

Current search surface:
- TempleOS has 969 text files matching serial-log capture/replay/export markers across modernization docs and automation.
- holyc-inference has 3 matching files: `LOOP_PROMPT.md`, `bench/qemu_prompt_bench.py`, and `tests/test_qemu_prompt_bench.py`.

## Finding CRITICAL-001: Remote Azure SSH workflow can expose Book-of-Truth serial contents

Applicable law:
- Law 11: local access only, no remote viewing.

Evidence:
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:81-89` says a real TempleOS instance runs on Azure VM `52.157.85.234`, gives `ssh azureuser@52.157.85.234`, and shows QEMU with `-serial file:/tmp/serial.log`.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:95-98` tells builders to check serial output for compilation errors or Book-of-Truth log entries and says they can SSH in for manual tests.
- `holyc-inference/LOOP_PROMPT.md:83-92` similarly points builders at Azure VM `52.157.85.234`, tells them to SSH in, and states serial output captures compilation results.
- `TempleOS/MODERNIZATION/NORTH_STAR.md:26` makes a Book-of-Truth log line part of the serial end-to-end target.

Backfill assessment:
The guest QEMU command shown in the prompt includes `-nic none`, so this is not a guest-networking breach. The violation is the observer boundary: a remote SSH session to an Azure host plus serial capture to `/tmp/serial.log` gives non-local access to serial output that the same prompt explicitly says may contain Book-of-Truth rows.

Risk:
Builders can satisfy compile or North Star checks by reading Book-of-Truth-bearing serial data over SSH. That violates the "direct physical access only" model even while preserving guest air-gap flags.

Required remediation:
- Retire remote Azure serial-log inspection for any run that can emit Book-of-Truth rows.
- Split validation modes: remote compile-only mode must suppress or redact Book-of-Truth output; local physical-console mode may inspect full Book-of-Truth serial.
- Update prompts to say remote test hosts may verify compile success and non-sensitive status only, not Book-of-Truth contents.

## Finding CRITICAL-002: Canonical TempleOS headless runner writes raw serial output to host files

Applicable law:
- Law 11: no log export / print-to-file path for Book-of-Truth contents.

Evidence:
- `automation/qemu-headless.sh:43-45` documents serial capture to `SERIAL_LOG_FILE` via `-serial file:<SERIAL_LOG_FILE>`.
- `automation/qemu-headless.sh:67-73` builds QEMU with `-serial "file:$SERIAL_LOG_FILE"`.
- `automation/qemu-headless.sh:98-123` prints the serial log path and confirms serial output was captured there.
- `MODERNIZATION/NORTH_STAR.md:17-18` defines the target QEMU command as `-serial file:/tmp/north-star.log` and says a HolyC program prints Book-of-Truth-related lines over serial.

Backfill assessment:
The host-side file capture is useful for automation, and it is local to the machine running QEMU. Law 11 is stricter than "not networked": it forbids export/print-to-file paths for the Book of Truth. Current headless automation has no mode distinction between harmless compile/test serial and Book-of-Truth serial rows, so once Book-of-Truth output appears on serial, the same runner persists it outside the local console.

Risk:
`automation/logs/*.log` and `/tmp/north-star.log` become de facto Book-of-Truth export artifacts. They can later be copied, committed, uploaded, or read by non-local automation without violating any current script guard.

Required remediation:
- Add a Law 11-safe runner mode that refuses to capture raw serial to files when Book-of-Truth rows are expected.
- If automation needs assertions, emit a local-only pass/fail digest that proves expected rows existed without storing row contents.
- Add a static Sanhedrin check for QEMU `-serial file:` usage paired with Book-of-Truth emission claims.

## Finding WARNING-001: holyc-inference benchmark report stores serial tails

Applicable laws:
- Law 11, when benchmark serial includes Book-of-Truth token/inference rows.
- Cross-repo invariant: inference "Book-of-Truth" tuple work must not be treated as local TempleOS Book-of-Truth access.

Evidence:
- `bench/qemu_prompt_bench.py:4-6` says the runner launches QEMU, captures serial output, and writes normalized results.
- `bench/qemu_prompt_bench.py:146-158` builds QEMU with `-nic none`, `-serial stdio`, `-display none`, and a TempleOS image.
- `bench/qemu_prompt_bench.py:251-259` captures stdout and stderr from QEMU.
- `bench/qemu_prompt_bench.py:279-296` stores `stdout_tail` and `stderr_tail` in each benchmark record.
- `bench/qemu_prompt_bench.py:299-309` writes those records to `bench/results/qemu_prompt_bench_latest.json` and a timestamped JSON file.
- `bench/README.md:30-35` documents that the benchmark captures serial output and writes records to `bench/results/`.

Backfill assessment:
The benchmark is good on guest air-gap enforcement, but it persists serial tails in host-side JSON. Today the documented expected output is benchmark metrics, not raw TempleOS Book-of-Truth rows. The risk becomes active when inference token events or GPU/security hooks are routed through Book-of-Truth serial: the benchmark will preserve tail content without a Law 11 classification gate.

Risk:
Performance reports can accidentally become Book-of-Truth excerpts, especially as holyc-inference continues adding token, GPU, and policy-digest event hooks.

Required remediation:
- Redact `stdout_tail` / `stderr_tail` by default, or store only parsed metric fields.
- Add an explicit `--allow-serial-tail` debug flag with a Law 11 warning and local-only use restriction.
- Add a test fixture proving Book-of-Truth-like lines are not written into benchmark JSON outputs.

## Compliance Score

- Law 2 guest air-gap on inspected commands: pass for the cited current QEMU command builders (`-nic none` or equivalent explicit no-network flag present).
- Law 11 local-only access: fail for current TempleOS remote/serial-file workflows; warning for holyc-inference benchmark persistence because it becomes a violation when Book-of-Truth rows are present.
- Backfill result: 3 findings total, 2 critical and 1 warning.

## Non-Findings

- No guest TCP/IP, UDP, DNS, DHCP, HTTP, TLS, socket, NIC-driver, or WS8 networking execution path was identified in the inspected evidence.
- No QEMU or VM command was executed during this audit.
- The cited holyc-inference benchmark path rejects conflicting network arguments and injects `-nic none`; the issue is serial persistence, not guest networking.

## Commands Run

- `sed -n '1,240p' LAWS.md`
- `rg -n "SSH|azureuser|52\\.157\\.85\\.234|serial\\.log|Book of Truth log|Book-of-Truth|serial output|captures serial|stdout_tail|stderr_tail|write_text|qemu_prompt_bench" ...`
- `nl -ba .../automation/qemu-headless.sh`
- `nl -ba .../MODERNIZATION/NORTH_STAR.md`
- `nl -ba .../MODERNIZATION/LOOP_PROMPT.md`
- `nl -ba .../holyc-inference/LOOP_PROMPT.md`
- `nl -ba .../bench/qemu_prompt_bench.py`
- `nl -ba .../bench/README.md`
- `git log --follow --date=iso-strict --format=... -- automation/qemu-headless.sh`
- `git log --follow --date=iso-strict --format=... -- MODERNIZATION/LOOP_PROMPT.md`
- `git log --follow --date=iso-strict --format=... -- bench/qemu_prompt_bench.py`
- `git log --follow --date=iso-strict --format=... -- LOOP_PROMPT.md`
- Python marker scan over `.sh`, `.py`, `.md`, `.HC`, and `.HH` files for serial-log/export/remote markers.
