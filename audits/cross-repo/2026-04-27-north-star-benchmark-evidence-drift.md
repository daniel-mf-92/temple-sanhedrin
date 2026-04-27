# Cross-Repo Invariant Audit: North-Star Benchmark Evidence Drift

Timestamp: 2026-04-27T19:43:25Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified.

Repos examined:
- TempleOS: `9e1b0735a6d25b256778d8d6b1048deb9c8eb172`
- holyc-inference: `afe75745cb2e09088fffa7b6b7160144275e8648`
- temple-sanhedrin: branch `codex/sanhedrin-gpt55-audit`

## Executive Summary

Found 3 findings: 1 critical, 2 warnings.

The current holyc-inference benchmark reports are useful host-side smoke artifacts, but they are not valid north-star evidence for either trinity member. The committed `qemu_prompt_bench` and benchmark-matrix reports use `bench/fixtures/qemu_synthetic_bench.py`, a deterministic Python fixture that explicitly says it is not an emulator, while both north-star contracts require actual TempleOS guest execution over serial.

## Finding CRITICAL-001: Synthetic benchmark passes can be mistaken for secure-local TempleOS inference progress

Applicable laws:
- Law 5: North Star discipline
- Law 8: Book of Truth immediacy and hardware proximity, insofar as secure-local performance claims require Book-of-Truth controls enabled

Evidence:
- `holyc-inference/NORTH_STAR.md:7-20` requires one pure-HolyC GPT-2 forward pass inside the TempleOS guest, a serial token id, bit-exact reference parity, wall time under 30s, and memory peak under 256 MB.
- `holyc-inference/NORTH_STAR.md:24` says optimizations are evaluated against reference accuracy and wall time, not synthetic micro-benchmarks.
- `holyc-inference/bench/fixtures/qemu_synthetic_bench.py:2-7` says the fixture is not an emulator and only emits deterministic `BENCH_RESULT` telemetry without booting a guest.
- `holyc-inference/bench/fixtures/qemu_synthetic_bench.py:16-30` derives token counts from prompt IDs and computes elapsed time as `tokens * 6250`; it does not load a Q4_0 GPT-2 blob, run HolyC, or compare a reference token.
- `holyc-inference/bench/results/qemu_prompt_bench_latest.md:3-12` reports `Status: pass`, 6/6 OK runs, 240 total tokens, and 160 tok/s.
- `holyc-inference/bench/results/bench_matrix_latest.md:3-13` reports a passing matrix for `ci-airgap-smoke` / `synthetic-smoke` / `Q4_0` and `Q8_0`.

Assessment:
The benchmark harness itself is appropriate host tooling, and it preserves the air-gap flag in the recorded command. The drift is semantic: a green benchmark report with token/sec and memory numbers is currently disconnected from the north-star proof. It proves report generation and parser plumbing, not TempleOS guest inference.

Risk:
Builder or Sanhedrin summaries can over-count synthetic 160 tok/s rows as secure-local throughput progress. That would make Law 5 north-star accounting weaker by treating fixture telemetry as a substitute for the end-to-end TempleOS forward-pass proof.

Required remediation:
- Label synthetic benchmark artifacts as `fixture_only=true` or equivalent in JSON/CSV/Markdown summaries.
- Add a Sanhedrin rule that excludes `model=synthetic-smoke`, `profile=synthetic-airgap-smoke`, and `qemu_bin=bench/fixtures/qemu_synthetic_bench.py` from north-star and secure-local throughput evidence.
- Require any north-star evidence row to include the actual `automation/north-star-e2e.sh` result, reference token parity, TempleOS guest command, and serial transcript provenance.

## Finding WARNING-001: The benchmark command shape is not linked to the holyc-inference north-star runner

Applicable laws:
- Law 5: North Star discipline
- Law 2: Air-gap sanctity

Evidence:
- `holyc-inference/automation/north-star-e2e.sh:28-35` still delegates the guest forward pass to `automation/run-holyc-forward.sh`.
- `holyc-inference/automation/north-star-e2e.sh:30-32` explicitly reports RED if that runner is missing.
- `holyc-inference/bench/README.md:148-159` documents refreshing the committed smoke report without booting a guest by using `/tmp/TempleOS.synthetic.img` and `bench/fixtures/qemu_synthetic_bench.py`.
- `holyc-inference/bench/results/bench_matrix_latest.csv:2-3` records commands using `bench/fixtures/qemu_synthetic_bench.py`, `-nic none`, and `file=/tmp/TempleOS.synthetic.img,format=raw,if=ide`.

Assessment:
The north-star script and the benchmark dashboard are two separate evidence tracks. That is fine for development, but the current artifacts do not encode that separation strongly enough. The benchmark reports say "pass" while the north-star contract remains RED until the real forward-pass runner exists and matches reference output.

Risk:
Historical trend reports can accidentally join benchmark pass rows to north-star state and show progress that the north-star script would reject.

Required remediation:
- Add a `north_star_eligible` field to benchmark outputs, defaulting false unless the run used the real north-star runner or a real TempleOS image plus reference-parity metadata.
- Keep fixture reports committed only under a clearly named smoke/fixture section of dashboards.

## Finding WARNING-002: TempleOS control-plane requirements are absent from inference benchmark provenance

Applicable laws:
- Law 3: Book of Truth immutability
- Law 8: Book of Truth immediacy and hardware proximity
- Law 11: local-only Book-of-Truth access
- Law 5: North Star discipline

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:31-47` requires `secure-local` performance to be measured with Book-of-Truth, IOMMU, and policy gates enabled.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:41-47` defines TempleOS as the trust/control plane and the inference runtime as an untrusted worker plane.
- `holyc-inference/MASTER_TASKS.md:26-30` mirrors that secure-local/default, quarantine, split-plane, and security-on performance policy.
- `holyc-inference/bench/results/bench_matrix_latest.csv:2-3` records profile, model, quantization, command, tok/s, and memory, but no TempleOS Book-of-Truth row identity, policy digest, attestation digest, IOMMU state, or secure-local gate proof.

Assessment:
The benchmark schema is useful for raw throughput, but it cannot yet satisfy the cross-repo secure-local invariant. Performance claims only count when the TempleOS control plane and Book-of-Truth hooks are part of the measured run.

Risk:
The inference loop can accumulate benchmark history that looks production-relevant but lacks the TempleOS-originated trust proofs required for secure-local promotion.

Required remediation:
- Extend benchmark provenance for north-star-eligible runs with policy digest, attestation digest, Book-of-Truth event sequence range, IOMMU/gate state, and TempleOS image identity.
- Treat rows without those fields as development telemetry only.

## Non-Findings

- The inspected benchmark commands include `-nic none`; this audit did not find a guest networking enablement in the reviewed benchmark artifacts.
- No QEMU or VM command was executed during this audit.
- No TempleOS or holyc-inference source files were edited.

## Read-Only Verification Commands

- `nl -ba holyc-inference/NORTH_STAR.md | sed -n '1,40p'`
- `nl -ba holyc-inference/MASTER_TASKS.md | sed -n '1,50p'`
- `nl -ba holyc-inference/bench/README.md | sed -n '97,170p'`
- `nl -ba holyc-inference/bench/fixtures/qemu_synthetic_bench.py | sed -n '1,220p'`
- `nl -ba holyc-inference/bench/fixtures/bench_matrix_smoke.json | sed -n '1,180p'`
- `nl -ba holyc-inference/bench/results/bench_matrix_latest.md | sed -n '1,120p'`
- `nl -ba holyc-inference/bench/results/bench_matrix_latest.csv | sed -n '1,20p'`
- `nl -ba holyc-inference/bench/results/qemu_prompt_bench_latest.md | sed -n '1,120p'`
- `nl -ba holyc-inference/automation/north-star-e2e.sh | sed -n '1,80p'`
- `nl -ba TempleOS/MODERNIZATION/NORTH_STAR.md | sed -n '1,45p'`
- `nl -ba TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,62p'`
