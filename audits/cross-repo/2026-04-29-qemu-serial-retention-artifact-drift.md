# Cross-Repo QEMU Serial Retention Artifact Drift Audit

Timestamp: 2026-04-29T19:28:49Z

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55` at `3eef3eb7525ee256a060a96fe5af6ce6ef400465`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55` at `d3daa15c824cf48a1b839ad192062b55a00510bc`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `fb4f6aad1a648b08ae8fb2c7acd93b44fb90f3d9`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 4 findings: 3 warnings and 1 info.

TempleOS is growing a QEMU serial transcript retention report that scans `*.log` and `*.txt` files under `automation/qemu-serial-logs`, extracts QEMU/no-network/outcome/Book-of-Truth signal, and emits a retention gate. holyc-inference's benchmark path records serial evidence inside benchmark JSON fields (`stdout_tail`, `stderr_tail`, `serial_output_bytes`, `serial_output_lines`) under `bench/results`.

Those two artifact contracts do not meet. The TempleOS retention scanner cannot see holyc-inference JSON serial tails, and holyc-inference does not emit standalone transcript files or a compatible serial-retention manifest. The drift is evidence-plane compatibility, not a guest networking breach.

## Finding WARNING-001: Retention scanner only discovers log/text transcripts, while inference serial evidence is JSON-embedded

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 3: Book of Truth Immutability
- Law 11: Book of Truth Local Access Only

Evidence:
- `templeos-gpt55/automation/qemu-serial-retention-report.py:117-126` discovers only `*.log` and `*.txt` candidates in one logs directory.
- `templeos-gpt55/automation/qemu-serial-retention-report.py:225-233` defaults that directory to `automation/qemu-serial-logs` and creates transcript records only from discovered files.
- `holyc-gpt55/bench/qemu_prompt_bench.py:998-1062` stores captured serial output as `BenchRun.stdout_tail`, `BenchRun.stderr_tail`, `serial_output_bytes`, and `serial_output_lines`.
- `holyc-gpt55/bench/qemu_prompt_bench.py:2397-2460` embeds warmup and measured runs into a JSON report.
- `holyc-gpt55/bench/qemu_prompt_bench.py:2462-2478` writes `qemu_prompt_bench_latest.json` and timestamped JSON reports, not standalone `*.log` or `*.txt` serial transcripts.

Assessment:
TempleOS has a retention gate for filesystem transcript files, while holyc-inference treats benchmark JSON as the durable evidence artifact. If inference QEMU runs become the cross-repo proof source for the north-star forward pass, Sanhedrin/TempleOS retention checks can report healthy coverage while missing every inference-run serial tail.

Required remediation:
- Define a shared serial-retention artifact schema accepted by both repos.
- Either make holyc-inference emit local-only transcript files/sidecar manifests, or make the TempleOS scanner ingest benchmark JSON serial-tail fields explicitly.
- Require provenance fields that identify source repo, command hash, launch index, serial evidence class, and whether the raw serial body was retained or redacted.

## Finding WARNING-002: Book-of-Truth signal is detected but not counted or separated as retention-critical evidence

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only

Evidence:
- `templeos-gpt55/automation/qemu-serial-retention-report.py:20` defines `BOT_RE` for `BOT seq=` and `BookTruth...:` lines.
- `templeos-gpt55/automation/qemu-serial-retention-report.py:171-172` increments only generic `signal_lines` for Book-of-Truth matches.
- `templeos-gpt55/automation/qemu-serial-retention-report.py:196-210` returns no `book_of_truth_lines`, `book_of_truth_status`, or local-only classification field.
- `templeos-gpt55/automation/qemu-serial-retention-report.py:277-310` summarizes QEMU/outcome/air-gap/fail/stale counts but not Book-of-Truth-bearing transcript counts.

Assessment:
The scanner knows how to recognize Book-of-Truth-looking lines, but collapses them into generic signal. That prevents downstream policy from distinguishing ordinary benchmark output from retention-critical local ledger material. Cross-repo consumers cannot tell whether a retained serial transcript is safe to summarize, must remain local raw evidence, or must never be committed.

Required remediation:
- Add explicit `book_of_truth_line_count` and `contains_book_of_truth` fields to transcript records and summaries.
- Treat Book-of-Truth-bearing serial as a separate evidence class from PASS/FAIL or benchmark metrics.
- Make strict mode fail if Book-of-Truth-bearing serial lacks a local-only retention path or redaction decision.

## Finding WARNING-003: Inference benchmark serial limits gate size, not retention semantics

Applicable laws:
- Law 5: North Star Discipline
- Law 11: Book of Truth Local Access Only

Evidence:
- `holyc-gpt55/bench/qemu_prompt_bench.py:1512-1529` can flag runs when serial output exceeds byte or line limits.
- `holyc-gpt55/bench/qemu_prompt_bench.py:2390-2391` passes `max_serial_output_bytes` and `max_serial_output_lines` into telemetry findings.
- `holyc-gpt55/bench/qemu_prompt_bench.py:2422` and `:2460` persist complete dataclass dictionaries for warmups and measured runs, including `stdout_tail` and `stderr_tail`.
- `holyc-gpt55/bench/results/qemu_prompt_bench_latest.json:54-59` shows a current artifact with serial byte/line telemetry and raw `stdout_tail` content.

Assessment:
The benchmark can prove serial output was small, but not whether it was metrics-only, redacted, Book-of-Truth-bearing, or locally retained. Size gates are useful for benchmark hygiene, but they do not satisfy the serial-evidence retention contract implied by TempleOS's new retention report and the local-only law.

Required remediation:
- Add `serial_evidence_class` to benchmark run records, with at least `metrics_only`, `redacted_serial`, and `book_of_truth_local_raw`.
- Add a Book-of-Truth prefix detector before JSON persistence.
- Omit raw tails from committed JSON by default once real guest output can include ledger material; keep parsed metrics and local-only transcript references instead.

## Finding INFO-001: Reviewed benchmark artifacts preserve explicit air-gap command evidence

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `holyc-gpt55/bench/qemu_prompt_bench.py:470-515` rejects missing `-nic none` and conflicting network flags in command metadata.
- `holyc-gpt55/bench/results/qemu_prompt_bench_latest.json:5-21` records `-nic none`, `-serial stdio`, `-display none`, and `command_airgap_ok: true`.
- `templeos-gpt55/automation/qemu-serial-retention-report.py:245-250` flags QEMU transcript lines that lack no-network evidence or contain forbidden network markers.

Assessment:
This audit found artifact-retention incompatibility, not a network enablement issue. No WS8 networking task was executed, no network stack/NIC/socket/TCP/IP/UDP/TLS/DHCP/DNS/HTTP feature was added or enabled, and no VM was launched.

## Non-Findings

- No TempleOS or holyc-inference files were edited.
- No QEMU, VM, package manager, remote runtime, or network-dependent validation command was executed.
- No live liveness watching, current-iteration LAWS.md compliance check, process restart, or real-time Sanhedrin audit was performed.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/qemu-serial-retention-report.py | sed -n '1,430p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '940,1065p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/qemu_prompt_bench.py | sed -n '2380,2490p'
nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/bench/results/qemu_prompt_bench_latest.json | sed -n '1,220p'
```
