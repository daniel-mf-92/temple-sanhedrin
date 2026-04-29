# CRITICAL: secure-local release gate regression (2026-04-29)

- `automation/inference-secure-gate.sh` failed (3 checks).
- Missing `src/model/trust_manifest.HC:ModelTrustManifestVerifySHA256Checked`.
- Missing `src/model/eval_gate.HC:ModelEvalPromotionGateChecked`.
- Missing `src/gguf/hardening_gate.HC:GGUFParserHardeningGateChecked`.
- Violates trusted-load guard expectations (quarantine/hash + promotion + parser hardening).
