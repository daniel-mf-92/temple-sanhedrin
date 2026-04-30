# Cross-Repo Audit: Secure Throughput Timing Proof Drift

Timestamp: 2026-04-30T08:24:38+02:00

Audit angle: cross-repo invariant check for whether TempleOS Book-of-Truth timing/baseline evidence matches holyc-inference throughput benchmark assumptions.

Repos reviewed:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `2e3b9750875e609cbe8495e03fb26087e78ee5f1`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554bea44c132137c590f02034c8f726`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `110a6681f4d95edc7b43b4b6f3509a0e5032a11d`

No TempleOS or holyc-inference source file was modified. No QEMU, VM, WS8 networking, package-download, SSH, networking, or live liveness command was executed.

## Expected Cross-Repo Invariant

Secure throughput claims must be joinable to TempleOS control-plane evidence. A promotable `secure-local` performance row needs:
- worker benchmark geometry, model/profile/policy digest, and integer throughput counters;
- timing source identity and TSC/CPU-frequency calibration evidence;
- Book-of-Truth sequence/hash anchors covering the benchmark window;
- explicit classification of real measured counters vs deterministic modeled counters;
- fail-closed release behavior when either security gates or throughput floors fail.

Finding count: 5 warnings.

## Findings

### WARNING-001: Q4 benchmark rows use bare TSC windows without a Book-of-Truth timing anchor

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- holyc-inference `q4_0_dot_bench.HC` states that the benchmark uses "cycle accounting from TSC" and integer-only throughput derivation at `src/bench/q4_0_dot_bench.HC:4-8`.
- `Q4_0DotBenchRunShape(...)` reads `TSC` before and after three benchmark loops, then prints `elapsed_cycles`, `cycles_per_dot`, and `dots_per_sec` with no ledger sequence, entry hash, profile id, policy digest, or boot TSC reference field at `src/bench/q4_0_dot_bench.HC:119-239`.
- TempleOS records boot TSC reference payloads in the Book of Truth at `Kernel/BookOfTruth.HC:11278-11288`.

Assessment:
The worker-side Q4 rows can be locally useful, but they are not control-plane proof. Sanhedrin can read elapsed cycles, but cannot prove those cycles came from a benchmark window that TempleOS accepted under `secure-local`, with serial/ledger liveness intact, TSC-gap checks in range, and the same CPU-frequency baseline.

Required remediation:
- Add benchmark evidence fields such as `bot_start_seq`, `bot_end_seq`, `bot_start_hash`, `bot_end_hash`, `boot_tsc_ref`, `cpu_hz_source`, `profile_id`, and `policy_digest`.
- Treat bare `Q4_0_DOT_BENCH` lines as advisory until joined to TempleOS ledger evidence.

### WARNING-002: Q8 default suite is explicitly modeled, but the contract does not distinguish modeled throughput from measured throughput

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `Q8_0DotBenchRunDefaultSuite(...)` documents that it is "intentionally timer-free" and uses "a fixed cycle model from canonical suite geometry and fixed vectors" at `src/bench/q8_0_dot_bench.HC:1453-1457`.
- The same routine publishes `total_cycles`, `cycles_per_op`, and checksum outputs derived from modeled geometry at `src/bench/q8_0_dot_bench.HC:1458-1472`.
- holyc-inference requires throughput claims to include `secure-local` measurements with audit hooks enabled at `MASTER_TASKS.md:26-30`.

Assessment:
The Q8 modeled suite is valuable for deterministic math regression, but it is not a measured secure-local performance row. Without an explicit `timing_mode=modeled` or equivalent field, a downstream gate can accidentally compare modeled throughput against real measured TempleOS/GPU timing rows.

Required remediation:
- Add a required timing-mode field with values like `measured_tsc`, `modeled_cycles`, and `host_fixture`.
- Sanhedrin and release gates should reject modeled rows for throughput-floor promotion unless a policy explicitly allows synthetic regression evidence.

### WARNING-003: TempleOS has the timing/security acceptance doctrine, but the worker benchmark rows do not carry the control-plane tuple

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS policy says performance wins only count with IOMMU, Book-of-Truth, and policy gates enabled at `MODERNIZATION/MASTER_TASKS.md:43-48`.
- TempleOS still lists GPU performance guardrails, secure-on acceptance matrix, policy-digest handshake, and release blocker tasks as open at `MODERNIZATION/MASTER_TASKS.md:273-280`.
- holyc-inference likewise keeps secure-on throughput SLO and security-overhead benchmark work open at `MASTER_TASKS.md:145` and `MASTER_TASKS.md:163`.

Assessment:
Both repos agree on the goal, but the executable proof tuple is not yet shared. Current benchmark helpers can improve kernel math and reporting, while the cross-repo release invariant still lacks the fields needed to prove "security controls ON" and "throughput floor satisfied" in the same record.

Required remediation:
- Define one shared `secure_throughput_evidence` schema: `{profile_id, policy_digest, attestation_id, model_hash, quant, prompt_shape, timing_mode, cpu_hz, cycles, tok_per_sec_q16, p50_q16, p95_q16, bot_seq_start, bot_seq_end, bot_hash_end}`.
- Make promotion gates require this schema before counting performance wins.

### WARNING-004: CPU frequency is caller-provided in worker throughput math without a TempleOS provenance field

Applicable laws:
- Law 5: North Star Discipline
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- Q4 throughput computes `dots_per_sec = total_dots * cpu_hz / elapsed_cycles`, and only validates that `cpu_hz > 0` at `src/bench/q4_0_dot_bench.HC:101-116`.
- Q8 throughput helpers similarly accept `cpu_hz` as an input and validate it as positive at `src/bench/q8_0_dot_bench.HC:140-183` and `src/bench/q8_0_dot_bench.HC:227-284`.
- TempleOS has boot baseline and TSC reference surfaces, including `BookTruthBootBaselineWindowStatus(...)` and boot TSC reference entries at `Kernel/BookOfTruth.HC:11278-11288` and `Kernel/BookOfTruth.HC:11791-11860`.

Assessment:
A positive `cpu_hz` is a numeric precondition, not provenance. For secure-local benchmark accounting, the CPU frequency must be tied to TempleOS boot/runtime calibration or recorded as a trusted local constant under Book-of-Truth coverage.

Required remediation:
- Require `cpu_hz_source` and `cpu_hz_bot_seq` in worker benchmark output.
- Reject secure-local throughput rows whose frequency was caller-provided without a TempleOS ledger-backed source.

### WARNING-005: The newer TempleOS architecture seam exposes `ArchRdTSC`, but Book-of-Truth timing doctrine still requires direct hardware proximity

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity

Evidence:
- TempleOS doctrine says TSC reads use `rdtsc` directly, with no OS timer abstraction at `MODERNIZATION/MASTER_TASKS.md:175-186`.
- The current architecture interface exposes `ArchRdTSC()` as a wrapper returning `GetTSC` at `Kernel/KArchIface.HC:37-40`.
- The reviewed worker benchmarks use their own `TSC` surface rather than a shared TempleOS proof API.

Assessment:
`ArchRdTSC()` may be useful for non-Book-of-Truth architecture cleanup, but it should not become the evidence path for Book-of-Truth timing proofs. The cross-repo risk is that a future benchmark bridge uses a wrapper or worker-local timer and calls it "TempleOS TSC proof" without satisfying the direct-hardware proximity rule.

Required remediation:
- Keep `ArchRdTSC()` explicitly out of Book-of-Truth timing append paths, or document it as non-evidence utility only.
- For secure throughput evidence, have TempleOS emit the timing window proof directly in the append path rather than accepting a worker timer value as authoritative.

## Non-Findings

- No HolyC purity violation was found in the reviewed benchmark/runtime surfaces.
- No integer-purity violation was found; the reviewed benchmark math is integer-only.
- No air-gap or networking violation was found; this audit did not execute QEMU or networking commands.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/bench/q4_0_dot_bench.HC | sed -n '1,280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/bench/q8_0_dot_bench.HC | sed -n '1,460p;1440,1585p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/BookOfTruth.HC | sed -n '1,50p;11260,11310p;11780,11860p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KArchIface.HC | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '35,55p;175,186p;267,281p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '24,31p;141,164p;1088,1104p'
rg -n "Q4_0_DOT_BENCH|Q8_0.*BENCH|BENCH_RESULT|elapsed_cycles|cycles_per_token|tok_per_sec|p95|BookTruth|ledger|seq|hash" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/bench /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/bench /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests --glob '!*.pyc'
```
