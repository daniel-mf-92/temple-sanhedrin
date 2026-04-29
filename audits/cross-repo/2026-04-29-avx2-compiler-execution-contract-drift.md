# Cross-Repo Audit: AVX2 Compiler Execution Contract Drift

Timestamp: 2026-04-29T04:38:02+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `607f90d49daaab26467264d55ce880d169e8babb`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `432a5fcbf6ff2d4dec847b78421067f905901836`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 0 critical, 4 warnings, 1 info.

holyc-inference has made substantial progress on "AVX2" named kernels, but the current implementation is mostly AVX2-shaped scalar HolyC with optional future inline assembly. TempleOS' compiler tables currently expose only MM/XMM register names, mark XMM operand classes as not implemented, and contain no YMM/VEX/AVX2 opcode vocabulary beyond unrelated `VERR`/`VERW`. The repos therefore agree on integer-only HolyC math, but they do not yet share an executable AVX2 contract for code that must eventually run inside the TempleOS guest.

## Finding WARNING-001: holyc-inference marks AVX2 work complete while TempleOS cannot assemble AVX2 opcodes yet

Applicable laws:
- Law 1: HolyC Purity
- Law 4: Integer Purity
- Law 5: North Star Discipline

Evidence:
- holyc-inference north-star rules say AVX2 inline assembly should be used for quantized dot products, matmul kernels, and attention score computation: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:31`.
- holyc-inference marks multiple AVX2 helper/kernel tasks complete, including IQ-101 through IQ-117: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:338`.
- TempleOS' opcode/register table lists only `XMM0` through `XMM7`: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/OpCodes.DD:131`.
- TempleOS' compiler argument types explicitly mark `ARGT_MM`, `ARGT_XMM`, `ARGT_XMM32`, `ARGT_XMM64`, `ARGT_XMM128`, and `ARGT_XMM0` as not implemented: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KernelA.HH:1948`.
- A targeted TempleOS search found no YMM/VEX/AVX2 opcode vocabulary in `Compiler/OpCodes.DD`, `Compiler/CInit.HC`, or `Kernel/KernelA.HH`; the only `V...` opcode hits were unrelated `VERR` and `VERW`.

Assessment:

This is not a direct Law 1 violation because the runtime code is still HolyC. It is a cross-repo execution-contract drift: holyc-inference's completed AVX2 work cannot yet mean "guest-assembled AVX2 machine instructions" unless TempleOS gains a compatible assembler/codegen path or the AVX2 bodies remain scalar HolyC under a different label.

Recommended closure:

Split the contract into `avx2_shape_scalar_holyc` and `avx2_machine_codegen`. Only mark the latter complete after TempleOS can assemble the required YMM/VEX instructions or after holyc-inference declares a non-guest host-codegen boundary.

## Finding WARNING-002: current AVX2 code is scalar HolyC under AVX2 names, which can inflate performance readiness

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `src/quant/q8_0_avx2.HC` says hot loops can later replace the scalar widening body with AVX2 asm `vpmovsxbw`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:8`.
- `Q8_0Pack32ToI16LanesAVX2` loops over 32 lanes in scalar HolyC: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:163`.
- `Q8_0MulI16LanesToI32PairsAVX2` mirrors `vpmaddwd` behavior but computes pair products in a HolyC loop: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:196`.
- `src/quant/q4_0_avx2.HC` says later inline-asm AVX2 can drop in without changing math: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_avx2.HC:5`.
- `Q4_0DotI16LanesAVX2` directly loops over 32 lanes and sums products: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_avx2.HC:186`.

Assessment:

The scalar implementations are valuable because they lock down lane order, overflow checks, and integer equations. The drift is naming and readiness: downstream reports can mistake AVX2-shaped scalar parity for actual AVX2 throughput, especially because the north star includes a performance target.

Recommended closure:

Require benchmark and task labels to state `scalar-contract`, `shape-parity`, or `machine-avx2`. Sanhedrin should not count `AVX2` names alone as proof of vectorized execution.

## Finding WARNING-003: no shared CPU feature or fallback handshake exists for AVX2 dispatch

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS has a low-level `_CPUID` entrypoint: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KUtils.HC:318`.
- holyc-inference exposes AVX2-named checked entrypoints such as `Q8_0DotProductBlocksAVX2Checked`: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:376`.
- holyc-inference has a `Q4_0DotAVX2KernelEnabled` guarded path that always computes the scalar reference first and requires exact parity before publishing AVX2-shaped output: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot_avx2.HC:394`.
- The reviewed files do not define a cross-repo manifest or policy field that records `{cpu_vendor, avx2_supported, xsave_enabled, codegen_mode, fallback_mode}` for trusted inference runs.

Assessment:

The current fallback shape is conservative for correctness, but the control plane cannot distinguish "AVX2 disabled because the guest/compiler cannot execute it" from "AVX2 enabled and parity-checked." That matters for performance evidence, reproducibility, and future secure-local promotion gates.

Recommended closure:

Add an execution profile field to the inference attestation/policy digest: `isa_profile`, `codegen_mode`, `feature_probe`, and `fallback_mode`. TempleOS should produce or bless those fields from guest-local CPUID evidence before trusted dispatch.

## Finding WARNING-004: TempleOS register model is narrower than holyc-inference's AVX2 lane vocabulary

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- TempleOS loads `ST_XMM_REGS` as only `XMM0` through `XMM7`: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/CInit.HC:225`.
- TempleOS has no `ST_YMM_REGS` list in the reviewed compiler initializer.
- holyc-inference uses 32-lane AVX2 contracts for Q8_0 and Q4_0 blocks: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:11`; `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_avx2.HC:7`.
- holyc-inference's Q8_0 comments explicitly map the 32 lanes to two AVX2 16-lane halves: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC:175`.

Assessment:

This is not a math disagreement. It is an implementation boundary mismatch: the inference repo already talks in AVX2 lane geometry, while the compiler-side register/opcode vocabulary is still pre-AVX. Without an explicit boundary, future inline-asm work can land in holyc-inference before TempleOS can compile it inside the guest.

Recommended closure:

Create a small shared ISA readiness checklist before any actual AVX2 inline asm lands: YMM register symbols, VEX/AVX2 opcode encoding, CPUID/OSXSAVE gate, scalar fallback, parity gate, and secure-local benchmark labeling.

## Finding INFO-001: reviewed AVX2-shaped parity tests pass and preserve integer-only behavior

Applicable laws:
- Law 4: Integer Purity

Evidence:
- `PYTHONDONTWRITEBYTECODE=1 python3 tests/test_q8_0_avx2_dot_lanes.py` returned `q8_0_avx2_dot_lanes_reference_checks=ok`.
- `PYTHONDONTWRITEBYTECODE=1 python3 tests/test_q4_0_avx2_dot_q32.py` returned `q4_0_avx2_dot_q32_reference_checks=ok`.
- holyc-inference quantization docs state optional AVX2 asm may optimize loops, but must preserve the same integer equations: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md:123`.

Assessment:

The current concern is not incorrect arithmetic or floating-point drift. The tests support the scalar/shape contract. The missing piece is a cross-repo label and gate that separates "integer AVX2-shaped semantics" from "actual AVX2 machine execution inside TempleOS."

## Law Compliance Notes

- No trinity source code was modified.
- No VM, QEMU, or WS8 networking command was executed.
- Air-gap posture was preserved.
- Findings are warning-level cross-repo contract drift, not current critical Law 1 or Law 2 violations.

## Evidence Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '25,45p;334,356p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/QUANTIZATION.md | sed -n '118,126p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q8_0_avx2.HC | sed -n '1,220p;368,422p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_avx2.HC | sed -n '1,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/quant/q4_0_dot_avx2.HC | sed -n '379,425p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/OpCodes.DD | sed -n '122,139p;1265,1280p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KernelA.HH | sed -n '1948,1956p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/CInit.HC | sed -n '220,236p'
rg -n "^YMM|\\bYMM[0-9]|\\bV[A-Z0-9]+\\b|VEX|AVX" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/OpCodes.DD /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Compiler/CInit.HC /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/Kernel/KernelA.HH || true
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_q8_0_avx2_dot_lanes.py
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_q4_0_avx2_dot_q32.py
```
