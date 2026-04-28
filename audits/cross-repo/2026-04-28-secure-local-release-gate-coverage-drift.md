# Cross-Repo Invariant Audit: Secure-Local Release-Gate Coverage Drift

- Audit angle: cross-repo invariant checks
- Repos inspected: `TempleOS`, `holyc-inference`, `temple-sanhedrin`
- Audit time: `2026-04-28T04:02:11+02:00`
- Scope: read-only review of secure-local, GPU, attestation, policy-digest, and performance gate evidence surfaces. No TempleOS or holyc-inference files were modified.

## Summary

The trinity policy documents agree on the headline invariant: `secure-local` is default, `dev-local` remains air-gapped, model trust requires quarantine/hash/attestation/policy-digest gates, and GPU dispatch requires IOMMU plus Book-of-Truth hooks. The executable proof is weaker. The holyc-inference doc-sync gate passes, but the holyc-inference secure-local release gate currently fails 3 trust checks, TempleOS has no equivalent policy gate script, and one performance harness can emit synthetic "security enabled" rows when no real inference binary exists.

This is not a live liveness issue and not a source-code modification request. It is historical/cross-repo drift between policy text, release gates, and measurable secure-local evidence.

## Finding CRITICAL-001: Doc-level trinity policy sync passes while the secure-local release gate is red

Laws implicated:
- Law 5: North Star Discipline
- Law 8/9/11 by dependency, because secure-local claims require Book-of-Truth, fail-closed, and local-only proof boundaries

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:100-122` checks policy language in the three control docs with regular expressions.
- Running `bash automation/check-trinity-policy-sync.sh` in `holyc-inference` returned summary `status=pass`, `drift=false`, `passed=21`, `failed=0`.
- `holyc-inference/automation/inference-secure-gate.sh:59-67` is the executable secure-local release gate.
- Running `bash automation/inference-secure-gate.sh` returned `status=fail`, `passed=6`, `failed=3`.
- The failed checks were:
  - `WS16-03`: missing `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`
  - `WS16-04`: missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`
  - `WS16-05`: missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`

Impact:

Sanhedrin can see a clean trinity policy-sync result even while secure-local release prerequisites are not implemented. That creates a false sense that policy parity equals release readiness.

Recommendation:

Treat doc parity as necessary but insufficient. Add a Sanhedrin cross-repo check that runs or parses the secure-local release gate result and blocks any secure-local promotion/report when the executable gate is red.

## Finding WARNING-001: TempleOS has policy doctrine but no matching secure-local/trinity gate script

Laws implicated:
- Law 5: North Star Discipline
- Law 6: Queue Health, insofar as WS14 gate work remains unchecked

Evidence:
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:33-39` defines `secure-local` as default and requires air-gap, Book of Truth, quarantine/hash verification, and no guest networking.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:43-47` makes TempleOS the trust/control plane and requires attestation evidence plus policy digest match.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:259-280` leaves WS14-01 through WS14-22 unchecked, including profile state, quarantine flow, attestation verifier, policy-digest handshake, key-release gate, and secure-on performance matrix.
- `find automation -maxdepth 1 -type f \( -iname '*policy*' -o -iname '*secure*' -o -iname '*trinity*' -o -iname '*gpu*' -o -iname '*attest*' \)` in TempleOS returned no matching policy/security/trinity gate script.

Impact:

TempleOS is declared the trust/control plane, but the repository currently lacks an executable local gate equivalent to holyc-inference's `inference-secure-gate.sh`. That means the worker plane has more concrete release-gate automation than the sovereign control plane.

Recommendation:

Add a TempleOS host-side gate that checks WS14 producer readiness: boot-visible profile state, quarantine/hash verifier, policy-digest verifier, local approval/key-release path, Book-of-Truth event IDs for profile/model/gate failures, and GPU fail-closed state.

## Finding WARNING-002: GPU checks pass by symbol presence while TempleOS GPU producer tasks remain future work

Laws implicated:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `holyc-inference/automation/inference-secure-gate.sh:63-67` marks GPU/IOMMU/Book-of-Truth readiness by checking for static symbols in holyc-inference files.
- The secure gate run passed `WS9-02`, `WS9-08`, `WS9-17`, `WS9-18`, and `WS9-22`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:267-274` still lists GPU stage definition, IOMMU domain manager, BAR/MMIO allowlist, DMA lease model, reset/scrub, dispatch transcript capture, secure performance guardrails, and fail-closed CPU-only boot gate as unchecked WS14 tasks.

Impact:

The inference-side GPU gate can report its local symbols as present even though TempleOS has not implemented the control-plane producers needed to make those hooks Book-of-Truth-compliant. This is producer/consumer drift rather than a direct code violation.

Recommendation:

Require GPU release checks to include TempleOS-side producer readiness, not only holyc-inference symbol presence. A pass should require canonical TempleOS Book-of-Truth event/source IDs, IOMMU state evidence, fail-closed GPU boot state, and replay parser coverage.

## Finding WARNING-003: Synthetic performance rows can claim secure-local hardening without a real binary

Laws implicated:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/perf-matrix.sh:34-56` emits deterministic synthetic throughput rows when `build/host-holyc-infer` is missing.
- The synthetic path labels rows with `attestation=on,policy_digest=on,audit_hooks=on` at `perf-matrix.sh:48-52`.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:47` says performance wins only count when measured with IOMMU, Book-of-Truth, and policy gates enabled.
- `TempleOS/MODERNIZATION/LOOP_PROMPT.md:57` repeats that measurable performance outputs must be with security controls on, not only relaxed mode.

Impact:

A missing-binary fallback is useful for testing CSV plumbing, but it can produce artifacts that look like secure-local evidence. If copied into reports without a synthetic marker check, Sanhedrin may count a non-measurement as secure-on performance progress.

Recommendation:

Make synthetic rows non-promotable by adding an explicit `synthetic=true` column and requiring real-run evidence before any secure-local throughput claim is accepted.

## Finding WARNING-004: The current trinity sync gate checks policy text only, not executable parity

Laws implicated:
- Law 5: North Star Discipline

Evidence:
- `holyc-inference/automation/check-trinity-policy-sync.sh:10-12` points to three markdown/control documents.
- `check_pattern` at `check-trinity-policy-sync.sh:69-93` only searches those documents for regular-expression matches.
- The gate does not inspect TempleOS kernel sources, holyc-inference runtime gates, QEMU launchers, Book-of-Truth event/source constants, or performance artifact provenance.

Impact:

Policy text can remain synchronized while executable behavior drifts. This is exactly the condition observed in this audit: text parity is green, but the secure-local release gate is red and TempleOS producer automation is absent.

Recommendation:

Split the gate names explicitly:
- `trinity-policy-doc-sync`: current regex doc check.
- `trinity-executable-parity`: cross-repo source/tooling check that verifies TempleOS producers, holyc-inference consumers, Sanhedrin parsers, and non-synthetic secure-local measurements.

## Verification

Commands run read-only:

```bash
bash automation/check-trinity-policy-sync.sh
bash automation/inference-secure-gate.sh
find automation -maxdepth 1 -type f \( -iname '*policy*' -o -iname '*secure*' -o -iname '*trinity*' -o -iname '*gpu*' -o -iname '*attest*' \) -print | sort
nl -ba automation/inference-secure-gate.sh | sed -n '1,100p'
nl -ba automation/check-trinity-policy-sync.sh | sed -n '1,140p'
nl -ba automation/perf-matrix.sh | sed -n '1,140p'
nl -ba MODERNIZATION/MASTER_TASKS.md | sed -n '30,60p'
nl -ba MODERNIZATION/MASTER_TASKS.md | sed -n '255,282p'
nl -ba MODERNIZATION/LOOP_PROMPT.md | sed -n '35,70p'
```

Finding count: 5 total, 1 critical and 4 warnings.
