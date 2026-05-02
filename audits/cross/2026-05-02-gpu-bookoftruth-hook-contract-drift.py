#!/usr/bin/env python3
"""Read-only cross-repo GPU Book-of-Truth hook contract audit."""

from pathlib import Path
import re

TEMPLE = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS")
INFER = Path("/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference")


def read(path: Path) -> str:
    return path.read_text(errors="replace")


def has(pattern: str, text: str) -> bool:
    return re.search(pattern, text, re.MULTILINE) is not None


def main() -> int:
    temple_bot = read(TEMPLE / "Kernel/BookOfTruth.HC")
    temple_iommu = read(TEMPLE / "Kernel/IOMMU.HC")
    inference_policy = read(INFER / "src/gpu/policy.HC")
    inference_bridge = read(INFER / "src/gpu/book_of_truth_bridge.HC")
    inference_digest = read(INFER / "src/runtime/policy_digest.HC")

    checks = {
        "temple_has_dma_payload": has(r"#define\s+BOT_DMA_PAYLOAD_MARKER\b", temple_bot),
        "temple_has_dma_record": has(r"public\s+Bool\s+BookTruthDMARecord\b", temple_bot),
        "temple_has_iommu_gpu": has(r"public\s+Bool\s+IOMMUGPUMap\b", temple_iommu),
        "temple_has_iommu_mmio": has(r"public\s+Bool\s+IOMMUGPUMMIOWrite\b", temple_iommu),
        "temple_has_gpu_dispatch_event": has(r"BOT_(?:EVENT|GPU).*DISPATCH", temple_bot),
        "temple_has_gpu_source": has(r"BOT_SOURCE_GPU|BOT_SOURCE_INFERENCE", temple_bot),
        "infer_policy_requires_three_bot_hooks": has(
            r"bot_dma_log_enabled[\s\S]*bot_mmio_log_enabled[\s\S]*bot_dispatch_log_enabled",
            inference_policy,
        ),
        "infer_bridge_has_dispatch": has(r"#define\s+BOT_GPU_EVENT_DISPATCH\b", inference_bridge),
        "infer_bridge_overwrites_oldest": "overwriting the oldest event when full" in inference_bridge,
        "infer_digest_defaults_hooks_on": has(
            r"g_policy_bot_dma_log_enabled\s*=\s*1[\s\S]*"
            r"g_policy_bot_mmio_log_enabled\s*=\s*1[\s\S]*"
            r"g_policy_bot_dispatch_log_enabled\s*=\s*1",
            inference_digest,
        ),
    }

    for name, value in checks.items():
        print(f"{name}: {int(value)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
