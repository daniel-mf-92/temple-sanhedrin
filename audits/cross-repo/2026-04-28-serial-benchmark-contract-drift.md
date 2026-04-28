# Cross-Repo Serial Benchmark Contract Drift Audit

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no QEMU or VM command was executed.

Timestamp: 2026-04-28T03:52:22+02:00

## Scope

- TempleOS committed HEAD: `ffc8a1309fac5c9c6a5592823d609f46707f26f7`
- holyc-inference committed HEAD: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- Repos reviewed read-only:
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
  - `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`
- Primary invariant: serial evidence emitted by TempleOS should be consumable by holyc-inference benchmark and north-star tooling without weakening the air-gap, Book-of-Truth, or secure-local policies.

## Summary

The repos agree at the policy level that TempleOS is air-gapped and that security-on performance must include Book-of-Truth controls. They do not yet agree on a concrete serial benchmark record contract.

TempleOS currently defines a north-star serial demo around exact `BoT:` boot/keypress/halt markers and has scheduler-band smoke wrappers that emit human-readable `SchedBand...` status lines. holyc-inference defines its north star as a GPT-2 forward pass that outputs a token id over serial, and its QEMU benchmark parser expects either `BENCH_RESULT` JSON or key/value metrics containing token and timing fields. Those are all reasonable local contracts, but they are not the same contract. A cross-repo benchmark run cannot currently prove, from one serial stream, both "TempleOS Book-of-Truth boot path is alive" and "holyc-inference produced a measurable next-token result" in a normalized way.

## Findings

### Finding WARNING-001: North-star serial contracts are incompatible

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-22` requires QEMU with `-nic none` and exact serial lines: `BoT: boot ok`, `BoT: keypress=q`, and `BoT: halt clean`.
- `holyc-inference/NORTH_STAR.md:7-20` requires one pure-HolyC GPT-2 forward pass inside the TempleOS guest, outputting the next-token id over serial with wall-time and memory bounds.

Impact:

The control-plane north star proves boot, serial I/O, keyboard input, Book-of-Truth marker visibility, and clean halt. The inference north star proves model data flow and token generation. Neither document defines a shared record that lets one run satisfy both. This can cause false cross-repo confidence: TempleOS can be "north-star shaped" while producing no token benchmark record, and holyc-inference can parse token metrics while not proving the exact Book-of-Truth boot markers that TempleOS requires.

Recommendation:

Define a shared serial envelope that preserves the TempleOS lines and adds a normalized inference record, for example:

```text
BoT: boot ok
BENCH_RESULT: {"profile":"secure-local","tokens":1,"next_token_id":<id>,"elapsed_us":<n>,"bot_boot_ok":true,"bot_halt_clean":true}
BoT: halt clean
```

Keep the TempleOS exact-marker requirement; add the benchmark record as an additional line rather than replacing Book-of-Truth evidence.

### Finding WARNING-002: holyc-inference benchmark parser cannot consume current TempleOS scheduler-band evidence

Evidence:
- `holyc-inference/bench/README.md:30-32` says `qemu_prompt_bench.py` captures serial output and extracts `BENCH_RESULT` JSON or key/value metrics.
- `holyc-inference/bench/README.md:47-57` documents accepted output shapes with `tokens`, `elapsed_us`, and `tok_per_s` / `tok_per_s_milli`.
- `holyc-inference/bench/qemu_prompt_bench.py:207-235` extracts `tokens`, `elapsed_us`, and throughput from specific metric keys.
- `TempleOS/automation/sched-band-suite.sh:101-117` runs scheduler-band smoke scripts and emits only `PASS mode=... scripts=...` at the suite layer.
- `TempleOS/Kernel/Sched.HC:12521`, `12751`, `12940`, `13006`, and `13092` emit `SchedBand...` human-readable status lines with scheduler fields and digests, not `BENCH_RESULT` or token/timing keys.

Impact:

The scheduler-band evidence is useful for TempleOS modernization, but holyc-inference's benchmark tools will not normalize it into benchmark records. If future inference work attempts to use current TempleOS scheduler-band serial logs as benchmark evidence, the parser will either fall back to host elapsed time with missing token counts or produce records that do not answer the inference north-star question.

Recommendation:

Do not overload scheduler-band logs as inference benchmark evidence. Add a distinct inference serial record emitted by the guest and parsed by holyc-inference, while keeping scheduler-band status lines as TempleOS-only diagnostic evidence.

### Finding WARNING-003: secure-local hardening evidence is too coarse in host perf output

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-48` says TempleOS is the `secure-local` trust/control plane and that performance wins count only with IOMMU, Book-of-Truth, and policy gates enabled.
- `holyc-inference/src/gpu/security_perf_matrix.HC:4-7` documents fail-closed secure-local matrix execution requiring IOMMU and Book-of-Truth DMA/MMIO/dispatch hooks.
- `holyc-inference/src/gpu/security_perf_matrix.HC:60-80` exposes separate `bot_dma_log_enabled`, `bot_mmio_log_enabled`, and `bot_dispatch_log_enabled` gates.
- `holyc-inference/automation/perf-matrix.sh:48-52` records synthetic hardening as one string containing `audit_hooks=on`.
- `holyc-inference/automation/perf-matrix.sh:75-78` accepts `audit_hooks=on` as the only Book-of-Truth-related host perf proof.

Impact:

The HolyC GPU matrix has a stronger contract than the host perf artifact. The host perf CSV can say `audit_hooks=on` without proving which Book-of-Truth hooks were active. That is not a direct Law violation because this is host tooling, but it weakens Sanhedrin's ability to distinguish full `secure-local` coverage from a coarse or synthetic hardening marker.

Recommendation:

Extend host perf records with discrete fields such as `bot_dma_log=on`, `bot_mmio_log=on`, `bot_dispatch_log=on`, `iommu=on`, and `policy_digest=on`. Treat `audit_hooks=on` as a summary label only, not sufficient evidence for cross-repo secure-local performance claims.

### Finding INFO-001: Reviewed QEMU benchmark command construction preserves the air-gap minimum

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17` requires `-nic none` in the concrete QEMU north-star command.
- `holyc-inference/bench/qemu_prompt_bench.py:146-160` builds QEMU commands by rejecting network arguments and injecting `-nic none` before serial/display/drive arguments.
- `holyc-inference/bench/README.md:34-35` states the runner injects `-nic none` and rejects conflicting networking arguments.
- `TempleOS/automation/sched-band-live.sh:111-115` checks helper scripts for `-nic none` or `-net none` evidence before running fixture/replay/compile flows.

Impact:

This pass found serial-contract drift, not an air-gap breach. The reviewed benchmark and scheduler wrapper surfaces retain explicit no-network policy. No WS8 networking task was executed or recommended.

Recommendation:

Keep the air-gap checks mandatory when adding the shared serial benchmark envelope. Any QEMU/VM run must continue to include `-nic none` or, for legacy fallback only, `-net none`.

## Safety Notes

- No TempleOS guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or remote runtime service was added or enabled.
- No TempleOS or holyc-inference source file was modified.
- No QEMU or VM command was executed during this audit.
- The proposed shared serial envelope is an audit/reporting contract only; it does not require network access or non-HolyC core implementation.

## Commands Run

Read-only commands only:

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,140p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '35,55p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-band-live.sh | sed -n '1,180p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-band-suite.sh | sed -n '1,170p'`
- `rg -n "SchedBand|PASS mode|scripts=|serial=|book|truth|tok_per|elapsed|hardening|csv|json|metric" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-band-live.sh /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-band-suite.sh /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/sched-band-*.sh /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/Sched.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KExts.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,120p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/README.md | sed -n '1,90p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '1,80p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench/qemu_prompt_bench.py | sed -n '207,238p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/perf-matrix.sh | sed -n '1,175p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/gpu/security_perf_matrix.HC | sed -n '1,90p'`
