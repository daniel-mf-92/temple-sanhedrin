# Cross-Repo Audit: Promotion Gate Eval/Hardening Drift

Timestamp: 2026-04-28T07:16:45+02:00

TempleOS commit under audit: `b61659bc6fc50f625831376aaafaef7254e64fcc`

holyc-inference commit under audit: `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`

Scope: read-only cross-repo invariant audit of the `dev-local` -> `secure-local` promotion contract. No TempleOS or holyc-inference files were modified. No QEMU or VM command was executed.

## Summary

TempleOS policy defines promotion as more than hash verification: deterministic eval parity, parser negative-corpus/fuzz pass, reproducible build hash parity, and zero critical Sanhedrin findings are required before `dev-local` work becomes `secure-local`.

holyc-inference mirrors that doctrine in WS16, but its current executable promotion path is narrower. `ModelQuarantinePromoteChecked` only requires verified quarantine state, a safe trusted path, and the current profile being `secure-local`. The release gate does fail closed because the deterministic eval gate and parser hardening gate artifacts are absent, but that protection lives in host-side release gating rather than in the worker promotion primitive.

## Findings

### WARNING-001: Worker promotion primitive does not require deterministic eval parity

TempleOS requires deterministic eval parity for promotion. holyc-inference also lists WS16-04 as the deterministic evaluation gate for profile promotion. The current `ModelQuarantinePromoteChecked` implementation does not consume or verify any prompt, seed, logit-window, blessed-baseline digest, or eval gate status before setting `QUARANTINE_STAGE_PROMOTED`.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:37`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:263`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:211`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:429`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:446`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src/model/quarantine.HC:461`

Risk: a future integration could call the worker promotion primitive directly and treat `QUARANTINE_STAGE_PROMOTED` as secure-local eligibility even though the deterministic next-token/logit-window baseline was never proven.

### WARNING-002: Parser hardening is a policy requirement but not a promotion precondition

TempleOS requires a malformed GGUF/safetensors corpus plus fuzz regression runner before promotion. holyc-inference lists the same requirement as WS16-05. The current promotion implementation has no parser-hardening status input, and the expected `src/gguf/hardening_gate.HC` artifact is absent.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:37`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md:262`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md:212`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:61`
- Read-only search found no `src/gguf/hardening_gate.HC` and no `GGUFParserHardeningGateChecked` implementation outside gate/test expectations.

Risk: parser-level fuzz/parsing work can remain scattered across per-helper Python tests without producing the single promotion-grade hardening gate that TempleOS policy expects.

### WARNING-003: Release gate fails closed, but the missing gates are only host-side release evidence

Running the holyc-inference release gate produced `status=fail` with three missing WS16 checks: manifest verifier symbol, deterministic promotion parity gate, and parser hardening gate. That is good fail-closed behavior. The drift is that the only executable protection observed is the host-side gate; the HolyC promotion function itself still exposes a narrower promoted state.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:59`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:60`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh:61`
- Gate result: `WS16-03 status=fail`, `WS16-04 status=fail`, `WS16-05 status=fail`; summary `status=fail`, `passed=6`, `failed=3`.

Risk: Sanhedrin or TempleOS must treat `QUARANTINE_STAGE_PROMOTED` as worker-local state until it is bound to release-gate evidence or an equivalent HolyC policy snapshot.

### WARNING-004: Tests normalize hash/profile-only promotion success

The current quarantine promotion test constructs a three-field manifest, calls import -> verify -> promote under the default secure profile, and expects promotion success. It also checks that `dev-local` blocks promotion, which is useful, but it does not require deterministic eval parity, parser hardening evidence, reproducible build hash parity, or zero-critical Sanhedrin status.

Evidence:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:205`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:210`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:212`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:220`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_model_quarantine_promote.py:226`

Risk: future changes can keep tests green while preserving a promotion definition that is weaker than TempleOS's control-plane contract.

## LAWS.md Assessment

- Law 1 HolyC Purity: no non-HolyC runtime implementation was introduced by this audit; inspected runtime paths are HolyC.
- Law 2 Air-Gap Sanctity: no networking code or QEMU execution was observed or performed; no WS8 work was executed.
- Law 4 Integer Purity: no floating-point tensor runtime issue was found in this promotion-gate audit.
- Law 5 North Star / No Busywork: warning-level drift. The current promotion primitive can represent secure-local promotion without the deterministic correctness and parser-hardening evidence required by the north-star security profile.
- Laws 8-11 Book of Truth / immutable image / local access: no direct violation was observed in this audit; the gap is promotion precondition coverage.

## Recommendations

- Treat `ModelQuarantinePromoteChecked` as worker-local until it requires an eval-gate digest and parser-hardening digest, or rename its state to avoid implying secure-local eligibility.
- Add a shared promotion evidence tuple: `{manifest_digest, eval_baseline_digest, parser_hardening_digest, build_hash, sanhedrin_critical_count, policy_digest}`.
- Extend the quarantine promotion tests so success requires the deterministic eval and parser-hardening gates, with failure vectors for missing or stale gate evidence.
- Keep `automation/inference-secure-gate.sh` fail-closed and make Sanhedrin consume its machine-readable output before accepting any secure-local promotion claim.

## Commands Run

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '31,47p;255,282p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '24,31p;206,216p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '1,95p'`
- `find /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src -path '*eval_gate.HC' -o -path '*hardening_gate.HC' -o -path '*attestation*' -o -path '*policy*' -o -path '*quarantine*' -o -path '*trust_manifest*' | sort`
- `rg -n "ModelEvalPromotionGateChecked|GGUFParserHardeningGateChecked|deterministic evaluation|fixed prompt|logit-window|negative-corpus|fuzz|promot" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/src /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation -g '*.HC' -g '*.py' -g '*.sh'`
- `cd /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference && automation/inference-secure-gate.sh`
