# Cross-Repo Invariant Audit: North-Star Handoff Contract Drift

Timestamp: 2026-04-27T22:56:59Z

Auditor: gpt-5.5 sibling, retroactive/deep audit scope

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified, and no VM/QEMU command was executed.

Repos examined:
- TempleOS committed HEAD: `06e0e74851510affb8c005f70aa3fbdc400ed79a`
- holyc-inference committed HEAD: `8079563a0d42d2094abf25e3407e9556dc7bff05`
- temple-sanhedrin committed baseline: `ed51bebf7f0ddf009f5ae0d2ddc8273e0434eb7a`
- temple-sanhedrin branch: `codex/sanhedrin-gpt55-audit`

Working tree note:
- Both builder worktrees had uncommitted concurrent-loop changes during this audit. They were treated as read-only snapshots; no builder file was edited.

## Executive Summary

Found 4 findings: 3 warnings, 1 info.

The inspected north-star surfaces agree on the high-level story: TempleOS must run headless and air-gapped, and holyc-inference must eventually run a pure-HolyC forward pass inside that guest. The drift is at the handoff contract. TempleOS documents a `shared.img` boot program and exact Book-of-Truth serial lines, but its actual north-star script launches only an ISO and does not attach `shared.img`. holyc-inference documents a GPT-2 Q4_0 blob on `shared.img`, but its script looks for a host-side `models/gpt2-124m-q4_0.bin` and a placeholder `automation/run-holyc-forward.sh`. Neither repo currently defines the shared disk layout, serial framing, or Book-of-Truth event schema that would let Sanhedrin decide when one repo's north-star evidence satisfies the other repo's assumptions.

## Finding WARNING-001: TempleOS north-star spec and script disagree on the shared disk handoff

Applicable laws:
- Law 5: North Star Discipline
- Law 10: Immutable OS Image, insofar as guest payloads must live outside the sealed OS image

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-18` defines the north-star boot as a QEMU command with `-drive file=shared.img,format=raw,if=ide`, then says a HolyC program on `shared.img` runs at boot.
- `TempleOS/automation/north-star-e2e.sh:21-26` launches QEMU with `-m 512M -cdrom "$ISO" -nic none -nographic -serial "file:$LOG" -monitor none -vga none -no-reboot`, with no `shared.img` drive.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:212-219` says user data, Book-of-Truth logs, and LLM models live on a separate writable partition, while the OS image should be read-only in QEMU.

Assessment:
The script preserves `-nic none`, so this is not an air-gap breach. The drift is that the executable north-star gate cannot currently prove the documented shared-disk payload path. If holyc-inference produces a correct HolyC forward-pass payload for `shared.img`, the TempleOS north-star script still has no contract for attaching or booting that payload.

Risk:
The TempleOS loop can keep improving serial/Book-of-Truth smoke evidence while remaining unable to consume the inference loop's expected guest payload location.

Required remediation:
- Define a shared-disk contract owned by Sanhedrin or TempleOS: image path/env var, mount/drive mode, expected HolyC autostart path, model directory, and whether the writable data image is separate from a readonly OS image.
- Update the TempleOS north-star script to either attach the documented shared image under `-nic none` or revise the North Star to match the actual ISO-only launch.
- Keep the OS image readonly in any future QEMU command that uses a mutable data/model image.

## Finding WARNING-002: holyc-inference north-star spec and script disagree on where the model artifact lives

Applicable laws:
- Law 5: North Star Discipline
- Law 2: Air-Gap Sanctity, because model loading must remain disk-only and offline

Evidence:
- `holyc-inference/NORTH_STAR.md:16-17` requires a Q4_0 GPT-2 124M weight blob on `shared.img` and a HolyC guest program that outputs the next-token id over serial.
- `holyc-inference/automation/north-star-e2e.sh:5-8` defaults to host paths under `$REPO_DIR`, including `models/gpt2-124m-q4_0.bin`, `tests/reference_q4_gpt2.py`, and `/tmp/holyc-forward.log`.
- `holyc-inference/automation/north-star-e2e.sh:28-35` delegates guest execution to `$REPO_DIR/automation/run-holyc-forward.sh` and parses the final stdout line for digits.
- Read-only existence check found `automation/run-holyc-forward.sh`, `models/gpt2-124m-q4_0.bin`, and `tests/reference_q4_gpt2.py` absent in the inspected worktree.

Assessment:
The holyc-inference north-star script is still a host-side placeholder. That is acceptable while RED, but it is not yet a faithful executable form of the documented `shared.img` guest handoff. The script also does not declare how the host model file becomes a guest-visible image without network/package steps.

Risk:
Future progress can satisfy host-side placeholder checks without proving the model was staged onto the same air-gapped guest data surface that TempleOS expects.

Required remediation:
- Add a manifest for model staging into the guest data image: source hash, target path, image path, readonly/writable role, and offline creation command.
- Make `automation/run-holyc-forward.sh` explicitly launch or delegate to a QEMU runner with `-nic none` and a clearly declared data image before it can count as north-star evidence.
- Ensure reference generation stays host-side validation only and is not mistaken for guest runtime proof.

## Finding WARNING-003: Serial output has no cross-repo framing contract for inference tokens versus Book-of-Truth lines

Applicable laws:
- Law 3: Book of Truth Immutability
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 11: Book of Truth Local Access Only
- Law 5: North Star Discipline

Evidence:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:18-21` requires exact serial lines: `BoT: boot ok`, `BoT: keypress=q`, and `BoT: halt clean`.
- `TempleOS/automation/north-star-e2e.sh:9-13` hard-codes the same three serial strings and fails if any are missing.
- `holyc-inference/NORTH_STAR.md:7` requires output of a token id over serial, but does not define the line prefix, event type, or whether the token must also appear as a Book-of-Truth entry.
- `holyc-inference/MASTER_TASKS.md:9-10` says every token is logged to the Book of Truth, and `MASTER_TASKS.md:23-24` says every inference call, token, and tensor-op checkpoint is loggable by the ledger.
- A read-only search for inference/token-specific Book-of-Truth event names in `TempleOS/Kernel/BookOfTruth.HC`, `Kernel/KExts.HC`, and `Kernel/KMain.HC` returned no matches for `BOT_EVENT_.*(INFER|TOKEN|MODEL|LLM)|INFER|Inference|TOKEN`.

Assessment:
The two repos both depend on serial evidence, but they do not share a typed serial schema. Sanhedrin can verify the TempleOS Book-of-Truth hello lines and can parse a bare final integer from holyc-inference, but it cannot yet prove that an inference token was synchronously logged by the Book of Truth rather than merely printed as ordinary guest output.

Risk:
A future inference run may appear green by printing the correct token id while bypassing the Book-of-Truth immediacy/immutability evidence that TempleOS treats as non-negotiable.

Required remediation:
- Define a shared serial framing contract, for example a stable `BOT_INFERENCE_TOKEN` or equivalent Book-of-Truth event line with token id, prompt hash, model hash, sequence number, and status.
- Add Sanhedrin parser rules that distinguish ordinary stdout token lines from Book-of-Truth ledger lines.
- Require the holyc-inference north-star runner to assert both: the expected next-token id was produced and the corresponding Book-of-Truth token event was present.

## Finding INFO-001: Reviewed launch surfaces did not execute QEMU and preserved air-gap intent where launch arguments are visible

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- `TempleOS/automation/north-star-e2e.sh:21-26` includes `-nic none`.
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17` includes `-nic none` in the documented launch command.
- `holyc-inference/automation/north-star-e2e.sh` does not itself launch QEMU; it delegates to a missing placeholder runner.
- No QEMU/VM command was executed during this audit.

Assessment:
No direct guest networking enablement was observed in the inspected north-star launch surfaces. The compliance issue is contract incompleteness, not a current Law 2 breach.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No WS8 networking task was executed.
- No QEMU or VM command was executed.
- The holyc-inference north-star being RED is not itself a violation; the warning is that its executable gate no longer encodes the same shared-image contract as its prose North Star.
- The TempleOS north-star script includes `-nic none`; this audit does not flag it as an air-gap violation.

## Read-Only Verification Commands

- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55 rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/worktrees/sanhedrin-gpt55 rev-parse HEAD`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/NORTH_STAR.md | sed -n '1,80p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/automation/north-star-e2e.sh | sed -n '1,120p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md | sed -n '18,34p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/templeos-gpt55/MODERNIZATION/MASTER_TASKS.md | sed -n '212,232p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/NORTH_STAR.md | sed -n '1,80p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/automation/north-star-e2e.sh | sed -n '1,120p'`
- `nl -ba /Users/danielmatthews-ferrero/Documents/worktrees/holyc-gpt55/MASTER_TASKS.md | sed -n '1,34p'`
- `ls -l tests/reference_q4_gpt2.py models/gpt2-124m-q4_0.bin automation/run-holyc-forward.sh 2>&1 || true`
- `rg -n "BOT_EVENT_.*(INFER|TOKEN|MODEL|LLM)|INFER|Inference|TOKEN" Kernel/BookOfTruth.HC Kernel/KExts.HC Kernel/KMain.HC -S -m 40`
