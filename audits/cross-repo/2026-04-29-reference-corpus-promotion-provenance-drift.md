# Cross-Repo Audit: Reference Corpus Promotion Provenance Drift

Audit timestamp: 2026-04-29T20:56:36+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `fc7d7ca5e27eb55211639d6d6a0ac27a4db1b20b`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `6fb000b5c0ac9912c8c8ca055eed114612e8e20e`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU, VM, liveness watcher, process restart, deploy, or WS8 networking task was executed.

## Summary

Found 5 findings: 4 warnings and 1 info.

This pass compared TempleOS secure-local promotion doctrine against the newest holyc-inference reference-output corpus tooling. The repos agree that secure-local promotion requires model quarantine/hash checks, deterministic evaluation parity, parser hardening, and Book-of-Truth/policy evidence. The current reference generator is useful host-side tooling, but its fixture schema and capture path are not yet strong enough to serve as promotion evidence for that doctrine.

The drift is evidence provenance, not runtime language purity. The audited inference changes live under `tests/`, which LAWS.md explicitly permits for Python validation scripts. The problem is that the test fixture can become "blessed baseline" material without recording the same model, tokenizer, manifest, capture locality, and secure-local gate state that TempleOS requires before trusted execution.

## Finding WARNING-001: reference fixture schema omits TempleOS trusted-manifest fields

Applicable laws:
- Law 5: North Star Discipline
- TempleOS secure-local promotion invariant

Evidence:
- TempleOS requires `secure-local` to enforce model quarantine plus hash verification, and promotion requires deterministic eval parity, parser negative-corpus/fuzz pass, reproducible build hash parity, and no open critical Sanhedrin findings: `TempleOS/MODERNIZATION/MASTER_TASKS.md:33-39`.
- TempleOS marks trusted model manifest schema as `model_id`, `sha256`, quant type, tokenizer hash, and provenance: `TempleOS/MODERNIZATION/MASTER_TASKS.md:259-263`.
- holyc-inference `tests/reference_q4_gpt2.py` writes only `updated_at_utc`, `source`, `model_id`, `seed`, `prompt_token_ids`, and `next_token_id`, with optional `capture_cmd` and `capture_excerpt`: `holyc-inference/tests/reference_q4_gpt2.py:123-135`.

Assessment:

The fixture proves a token value for a model label, not a trusted-model identity. It does not bind the reference result to the model file SHA256, quantization type, tokenizer hash, tokenizer special-token policy, llama.cpp build hash, or local provenance required by the TempleOS control-plane contract.

Recommended closure:

Extend reference fixtures with at least `model_sha256`, `quant_type`, `tokenizer_hash`, `tokenizer_policy_digest`, `reference_runner`, `reference_runner_sha256`, `capture_host_class`, and `provenance`. Treat fixtures missing those fields as development-only baselines, not secure-local promotion evidence.

## Finding WARNING-002: `--capture-cmd` allows arbitrary shell capture without local-only or no-network gating

Applicable laws:
- Law 2: Air-Gap Sanctity
- Law 5: North Star Discipline

Evidence:
- `_capture_token` invokes `subprocess.run(capture_cmd, shell=True, ...)`: `holyc-inference/tests/reference_q4_gpt2.py:47-55`.
- `--capture-cmd` is exposed as a free-form string: `holyc-inference/tests/reference_q4_gpt2.py:85-88`.
- The only committed capture-path test uses `printf 'next_token_id=777\n'` and asserts only token extraction and `source == "capture-cmd"`: `holyc-inference/tests/test_reference_q4_gpt2.py:46-67`.

Assessment:

The audited commit did not execute a network command, and this audit did not execute one. The warning is that the capture surface can accept `ssh`, `curl`, `wget`, package-manager, HTTP API, or remote runtime commands and then persist the result as a local reference fixture. That is too weak for an artifact that may later feed deterministic eval parity or model promotion.

Recommended closure:

Replace shell-string capture with structured argv and local path evidence. Reject obvious remote/network tokens (`ssh`, `scp`, `curl`, `wget`, `http://`, `https://`, package managers, API clients), and require `runner_path`, `model_path`, `model_sha256`, `prompt_id`, `seed`, `exit_status`, and `stdout_hash`.

## Finding WARNING-003: inference secure-local release gate is already red on the deterministic promotion chain

Applicable laws:
- Law 5: North Star Discipline
- Cross-repo secure-local release invariant

Evidence:
- holyc-inference marks WS12-05 complete for reference output generation: `holyc-inference/MASTER_TASKS.md:181-188`.
- holyc-inference still lists WS16-03/04/05/08 as unchecked secure-local profile gates: `holyc-inference/MASTER_TASKS.md:207-215`.
- `automation/inference-secure-gate.sh` requires `ModelTrustManifestVerifySHA256Checked`, `ModelEvalPromotionGateChecked`, and `GGUFParserHardeningGateChecked`: `holyc-inference/automation/inference-secure-gate.sh:59-61`.
- Running `bash automation/inference-secure-gate.sh` returned `status:"fail"` with 6 passes and 3 failures: missing `ModelTrustManifestVerifySHA256Checked`, missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`, and missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`.

Assessment:

This is useful release-gate behavior: it is failing closed. The drift is that the new reference-output path can look complete at WS12 while the secure-local chain that would consume that evidence remains red. Promotion reports should explicitly say "reference-only, not secure-local promotion evidence" until the gate passes.

Recommended closure:

Make the reference generator emit `promotion_eligible=false` unless `automation/inference-secure-gate.sh` passes and the fixture includes manifest/parser/eval-gate proof fields.

## Finding WARNING-004: default fixture path is not committed but WS12-05 is marked complete

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- Default fixture path is `tests/fixtures/reference_q4_gpt2.json`: `holyc-inference/tests/reference_q4_gpt2.py:20-23`.
- If the default fixture does not exist, the script exits with `ERROR: fixture not found`: `holyc-inference/tests/reference_q4_gpt2.py:139-141`.
- WS12-05 is checked as complete: `holyc-inference/MASTER_TASKS.md:188`.

Assessment:

The generator exists, but the committed baseline corpus is absent at the default path. That weakens the historical audit trail because future readers cannot reproduce the checked WS12-05 outcome from repository contents alone.

Recommended closure:

Either commit a deterministic development fixture and clearly mark it non-promotion, or leave WS12-05 unchecked until the fixture exists with the provenance fields above.

## Finding INFO-001: HolyC runtime and air-gap posture were not directly breached in this pass

Applicable laws:
- Law 1: HolyC Purity
- Law 2: Air-Gap Sanctity
- Law 4: Integer Purity

Evidence:
- The reference generator and tests live under `tests/`, which LAWS.md permits for host-side validation scripts.
- No `src/` runtime implementation file was modified by the audited reference generator commit.
- No QEMU, VM, SSH, package-manager, HTTP, DNS, DHCP, TLS, TCP/IP, UDP, socket, or NIC command was executed during this audit.

Assessment:

This report should be treated as a warning-level cross-repo evidence-contract gap, not a direct HolyC runtime or air-gap violation.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/MASTER_TASKS.md | sed -n '30,50p;255,266p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '180,220p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/reference_q4_gpt2.py | sed -n '1,170p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/tests/test_reference_q4_gpt2.py | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '55,75p'
bash /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh
```

Finding count: 5
