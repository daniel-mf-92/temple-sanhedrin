#!/usr/bin/env python3
"""Read-only Law 11 Book-of-Truth export/local-only semantics audit."""

from pathlib import Path
import re

ROOT = Path("/Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55")
TEMPLE = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS")
INFER = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference")


def read(path: Path) -> str:
    return path.read_text(errors="replace")


def count(pattern: str, text: str) -> int:
    return len(re.findall(pattern, text, re.IGNORECASE | re.MULTILINE))


def has(pattern: str, text: str) -> bool:
    return re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is not None


def main() -> int:
    laws = read(ROOT / "LAWS.md")
    temple_bot = read(TEMPLE / "Kernel/BookOfTruth.HC")
    infer_master = read(INFER / "MASTER_TASKS.md")
    infer_prompt = read(INFER / "LOOP_PROMPT.md")
    infer_prefix = read(INFER / "src/runtime/prefix_cache.HC")
    infer_attest = read(INFER / "src/runtime/attestation_manifest.HC")
    infer_dispatch = read(INFER / "src/gpu/dispatch_transcript.HC")

    checks = {
        "law11_forbids_log_export": has(r"Log export commands", laws),
        "law11_forbids_outside_local_console": has(r"outside the local console", laws),
        "temple_schema_has_serial_local_console_basis": has(r"BOT_COM1_BASE\s+0x3F8", temple_bot),
        "temple_has_no_export_named_api": not has(r"BookTruth.*Export|Export.*BookTruth", temple_bot),
        "infer_prefix_export_api_count": count(r"PrefixCacheExportAuditRows", infer_prefix),
        "infer_prefix_book_rows_phrase": has(r"Book-of-Truth rows", infer_prefix),
        "infer_dispatch_export_phrase": has(r"Book-of-Truth export", infer_dispatch),
        "infer_attestation_emits_bundle_task": has(r"attestation evidence bundle", infer_master),
        "infer_attestation_manifest_lines": has(r"class\s+InferenceAttestationManifest", infer_attest),
        "infer_docs_no_http_local_api": has(r"serial-port accessible, no HTTP", infer_master),
        "infer_prompt_secure_local": has(r"secure-local", infer_prompt),
    }

    for name, value in checks.items():
        if isinstance(value, bool):
            value = int(value)
        print(f"{name}: {value}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
