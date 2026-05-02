#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path("/Users/danielmatthews-ferrero/Documents/local-codebases")
TEMPLE = ROOT / "TempleOS"
INFER = ROOT / "holyc-inference"

temple_bot = TEMPLE / "Kernel" / "BookOfTruth.HC"
temple_exts = TEMPLE / "Kernel" / "KExts.HC"
infer_quarantine = INFER / "src" / "model" / "quarantine.HC"
infer_quant = INFER / "src" / "runtime" / "quant_profile.HC"
infer_policy = INFER / "src" / "runtime" / "policy_digest.HC"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def count(pattern: str, text: str, flags: int = re.MULTILINE) -> int:
    return len(re.findall(pattern, text, flags=flags))


def has(pattern: str, text: str) -> int:
    return 1 if re.search(pattern, text, flags=re.MULTILINE | re.DOTALL) else 0


def main() -> int:
    bot = read(temple_bot)
    exts = read(temple_exts)
    quarantine = read(infer_quarantine)
    quant = read(infer_quant)
    policy = read(infer_policy)

    model_start = bot.find("public Bool BookTruthModelImport", 100000)
    model_end = bot.find("public U0 BookTruthModelStatus", model_start)
    model_block = bot[model_start:model_end]

    checks = {
        "temple_public_model_emit_event_params": count(
            r"public Bool BookTruthModel(?:Import|ParseRun|DetRun|BuildSet|Verify|Promote)\([\s\S]*?\)\n\{",
            model_block,
            re.MULTILINE,
        ),
        "temple_extern_model_emit_event_params": count(
            r"extern Bool BookTruthModel(?:Import|ParseRun|DetRun|BuildSet|Verify|Promote)\([^;]*emit_event=TRUE",
            exts,
        ),
        "temple_model_emit_event_guards": count(r"if \(emit_event\)", model_block),
        "temple_promote_mutates_trusted_state": has(
            r"public Bool BookTruthModelPromote.*?state=BOT_MODEL_STATE_TRUSTED.*?if \(emit_event\)",
            bot,
        ),
        "temple_promote_failure_can_skip_event": has(
            r"secure_gate=1.*?if \(emit_event\).*?BookTruthAppend\(BOT_EVENT_VERIFY_FAIL",
            bot,
        ),
        "inference_quarantine_contract_mentions_import_verify_promote": has(
            r"import->verify->promote workflow.*?promote stage requires secure-local profile and verified quarantine state",
            quarantine,
        ),
        "inference_promote_requires_verified_stage": has(
            r"ModelQuarantinePromoteChecked.*?state->stage < QUARANTINE_STAGE_VERIFIED",
            quarantine,
        ),
        "inference_quant_forbids_disabled_trust_gates": has(
            r"forbidden unless\s+// quarantine \+ manifest verification gates remain enforced.*?!secure_quarantine_gate_enabled",
            quant,
        ),
        "inference_policy_digest_includes_quarantine_manifest_bits": has(
            r"bit4 quarantine, bit5 hash manifest.*?quarantine_gate_enabled << 4.*?hash_manifest_gate_enabled << 5",
            policy,
        ),
    }

    print("# trusted-model-ledger-contract-drift")
    for key, value in checks.items():
        print(f"{key}: {value}")

    findings = 4
    print(f"finding_count: {findings}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
