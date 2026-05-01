# Cross-Repo Audit: Shared Image Staging Atomicity Drift

Audit timestamp: 2026-05-01T22:03:31+02:00
Audit angle: cross-repo invariant checks

Repos audited read-only:
- `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS`
- `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference`

No trinity source code was modified. No QEMU or VM command was executed. No live liveness watching was performed. The TempleOS guest air-gap was not touched.

## Summary

TempleOS commit `738206d0` added `automation/mk-shared-img.sh` and made `automation/ns-preflight.sh` auto-create `automation/shared.img` when missing. That removes one North Star preflight blocker, but the cross-repo shared-image contract is still not stable enough for holyc-inference to rely on it. Current evidence proves an image file can exist; it does not prove atomic cleanup, ignored temp artifacts, in-image payload layout, or that the inference runner consumes the same guest-visible artifact promised by its North Star.

## Findings

### WARNING-001: Shared-image auto-creation leaves unignored temp residue on failed/interrupted runs

Evidence:
- `TempleOS/automation/mk-shared-img.sh:33-36` writes to `shared.img.tmp.$$` before formatting.
- `TempleOS/automation/mk-shared-img.sh:49` moves the temp file into place only after the format attempt.
- The current TempleOS worktree contains `automation/shared.img.tmp.36266`, size 27,262,976 bytes, modified `2026-05-01T11:29:09+0200`.
- `TempleOS/.gitignore:6-10` ignores `*.img` but does not ignore `*.img.tmp.*`; `git check-ignore -v automation/shared.img.tmp.36266` returned no match.

Law impact:
- Law 5 / North Star Discipline drift. Temp-image residue is not source, spec, or validation evidence, and can pollute worktree/accounting surfaces.
- Law 10 is not directly violated because this is a host-side data image, not an installed OS image. The risk is artifact hygiene and ambiguity around which image was used.

Recommended remediation:
- Add a trap in `mk-shared-img.sh` to remove `"$tmp_img"` on exit before the final `mv`.
- Ignore `*.img.tmp.*` or write temp files under `/tmp` and move atomically into `automation/shared.img`.

### WARNING-002: Auto-created `shared.img` proves existence, not payload content or provenance

Evidence:
- `TempleOS/automation/ns-preflight.sh:41-50` auto-creates `shared.img` when missing and then proceeds.
- `TempleOS/automation/mk-shared-img.sh:36-54` creates a zero-filled FAT16/raw image but does not stage a HolyC program, model blob, manifest, or content hash.
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-18` says a HolyC program on `shared.img` runs at boot and emits the Book-of-Truth serial lines.

Law impact:
- Law 5 / North Star Discipline drift. A preflight PASS can now mean only "blank data disk exists," while the documented North Star requires guest-visible executable content.

Recommended remediation:
- Split preflight into image existence and image-content checks.
- Require a manifest with expected guest paths, SHA-256s, and the HolyC entrypoint before treating `shared.img` as North Star-ready.

### WARNING-003: TempleOS copies `shared.img` into a transient QEMU drive without preserving the content identity in evidence

Evidence:
- `TempleOS/automation/north-star-e2e.sh:104-110` copies `"$SHARED_IMG"` to `/tmp/north-star-shared-$$.img` and attaches the copy with `-drive "file=$TMP_SHARED_IMG,format=raw,if=ide"`.
- `TempleOS/automation/north-star-e2e.sh:91-118` records the QEMU launch path but does not record the source image hash, temp image hash, or final drive identity in the serial/result evidence.

Law impact:
- Law 5 evidence drift. A future green run would not prove which shared-image bytes were consumed by the guest.
- Law 2 is not violated: the launch path still includes `-nic none`.

Recommended remediation:
- Record source and temp image SHA-256 before QEMU launch.
- Include those hashes in the North Star result log so Sanhedrin can bind serial output to a specific staged artifact.

### WARNING-004: holyc-inference still documents `shared.img` but checks a host-side weight path

Evidence:
- `holyc-inference/NORTH_STAR.md:16-18` requires a Q4_0 GPT-2 124M blob on `shared.img`, loaded by a HolyC guest program.
- `holyc-inference/automation/north-star-e2e.sh:5-13` checks `models/gpt2-124m-q4_0.bin` on the host filesystem.
- `holyc-inference/automation/north-star-e2e.sh:28-35` delegates to a missing `automation/run-holyc-forward.sh` without defining how host weights are staged into the TempleOS shared image.

Law impact:
- Cross-repo North Star drift under Law 5. TempleOS is now making an image file available, while inference still cannot prove its runtime consumes that guest-visible image.

Recommended remediation:
- Define one shared-image layout contract used by both repos, for example `/MODEL/GPT2_Q4_0.BIN`, `/BENCH/PROMPT.TXT`, and `/MANIFEST.JSON`.
- Make the inference e2e runner inspect or build `shared.img` locally, then run only through the TempleOS guest path.

## Non-Findings

- No guest networking, WS8 networking task, NIC driver, socket, TCP/IP, UDP, DHCP, DNS, HTTP, TLS, or remote runtime service was found in the inspected shared-image path.
- The audited QEMU launch code retains explicit `-nic none` in `TempleOS/automation/north-star-e2e.sh`.
- The inspected changes are host-side Bash automation and do not add non-HolyC implementation code to TempleOS core subsystems or the holyc-inference runtime.

## Validation Performed

```sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS status --short --branch
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference status --short --branch
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/mk-shared-img.sh
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/ns-preflight.sh
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/.gitignore
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/NORTH_STAR.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS ls-files --others --exclude-standard
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS check-ignore -v automation/shared.img.tmp.36266
stat -f '%N %z bytes %Sm' -t '%Y-%m-%dT%H:%M:%S%z' /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/shared.img.tmp.36266
find /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation -maxdepth 1 -name 'shared.img*' -ls
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show --stat --oneline --decorate 738206d0
```

## Verdict

Record 4 warning findings. The shared-image work improves North Star preflight reliability, but the artifact boundary remains under-specified across TempleOS and holyc-inference: existence is now automated, while content, cleanup, provenance, and guest-consumption evidence are still not enforced.
