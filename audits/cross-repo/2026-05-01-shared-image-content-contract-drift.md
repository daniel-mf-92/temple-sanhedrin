# Cross-Repo Audit: Shared-Image Content Contract Drift

Timestamp: 2026-05-01T04:21:19+02:00

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `2bac8a1a3102`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin branch: `codex/sanhedrin-gpt55-audit`
- Audit angle: cross-repo invariant check, historical/deep audit only

No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, or remote fetch command was executed.

## Summary

TempleOS commit `738206d0` removed the immediate missing-`shared.img` preflight blocker by adding `automation/mk-shared-img.sh` and enabling `automation/ns-preflight.sh` to auto-create a shared disk image. That is useful host automation, but it only proves that an image file exists.

holyc-inference's North Star requires a Q4_0 GPT-2 124M weight blob to live on `shared.img`, and its secure-local tasks require quarantine plus hash-manifest verification before trusted load. Current cross-repo evidence does not define or check the shared-image contents, file layout, manifest path, quarantine state, or reference-output binding. The two repos therefore agree on a filename but not on the artifact contract.

Findings: 5

## Findings

### 1. WARNING: TempleOS preflight treats shared-image existence as sufficient

Evidence:
- `TempleOS/automation/ns-preflight.sh:20-26` documents checks for QEMU, ISO, `shared.img` existence, North Star script existence, and `-nic none`.
- `TempleOS/automation/ns-preflight.sh:41-55` creates `shared.img` if missing when `AUTO_MK_SHARED=1`.
- `TempleOS/automation/ns-preflight.sh:62-67` only checks that the North Star script contains `-nic none` before printing PASS.

Impact: the preflight can pass with a newly-created empty data image. That fixes a host blocker, but it does not prove the holyc-inference North Star requirement that the image carries model weights, manifests, or trusted-load inputs.

Recommended issue: add a separate shared-image content preflight that verifies the expected model path, manifest file, size/hash tuple, and quarantine/trusted-state marker before any cross-repo inference run is considered on-path.

### 2. WARNING: `mk-shared-img.sh` can produce a raw unformatted image while still exiting success

Evidence:
- `TempleOS/automation/mk-shared-img.sh:38-47` attempts `newfs_msdos` or `mkfs.fat` and records `formatted=1` only on success.
- `TempleOS/automation/mk-shared-img.sh:49-54` always moves the temporary image into place and exits 0, even when it prints `raw, FAT format unavailable`.

Impact: a host without FAT tooling can create a zero-filled raw image that satisfies TempleOS preflight but may not be mountable or usable by the guest-side model handoff expected by holyc-inference. This is a Law 5/North Star evidence gap, not an air-gap breach.

Recommended issue: make unformatted image creation an explicit non-pass state for North Star preflight, or require callers to opt in with a clearly named fixture mode that cannot satisfy inference handoff gates.

### 3. WARNING: holyc-inference documents `shared.img` but its e2e script reads host-side weights

Evidence:
- `holyc-inference/NORTH_STAR.md:16-18` says the Q4_0 GPT-2 124M blob lives on `shared.img`, is loaded by a HolyC program inside the guest, and is compared bit-exactly against `tests/reference_q4_gpt2.py`.
- `holyc-inference/automation/north-star-e2e.sh:5-13` checks `models/gpt2-124m-q4_0.bin` in the host repo, not a file inside `shared.img`.
- `holyc-inference/automation/north-star-e2e.sh:28-35` delegates the guest execution to a missing `automation/run-holyc-forward.sh` and does not define the shared-image mount/copy contract.

Impact: TempleOS can now auto-create the file that holyc-inference names, while holyc-inference's own executable gate still does not consume that file. This allows false progress signals around the shared-image handoff.

Recommended issue: align the e2e runner with the documented contract: prepare or inspect `shared.img`, require the expected in-image path, and pass only when the HolyC guest runner consumes that artifact.

### 4. WARNING: Shared-image handoff is not bound to quarantine/hash-manifest promotion

Evidence:
- `holyc-inference/MASTER_TASKS.md:207-216` keeps WS16 secure-local tasks open for profile config, model quarantine layout, trusted manifest SHA256 verification, parser/deterministic gates, and release gating.
- `holyc-inference/MASTER_TASKS.md:1146-1147` records implementation work for a trust manifest parser and quarantine promotion helper, but the North Star script does not call or verify those artifacts.
- `TempleOS/automation/ns-preflight.sh:41-55` creates only the image container, with no manifest or quarantine state.

Impact: the shared image can become an untrusted data shuttle rather than the named boundary `external/out-of-band -> host-staged local file -> TempleOS quarantine -> manifest/hash verified -> trusted local load`.

Recommended issue: define a minimal shared-image layout such as `/quarantine/models/...`, `/manifests/models.sha256`, `/trusted/...`, and require both repos to verify the same tuple before secure-local promotion.

### 5. INFO: Air-gap minimum remains preserved in the audited surfaces

Evidence:
- `TempleOS/automation/north-star-e2e.sh:92-101` constructs QEMU args with `-nic none`, `-nographic`, serial pipe capture, monitor disabled, and no reboot.
- `TempleOS/automation/ns-preflight.sh:62-64` fails if the North Star script does not contain `-nic none`.
- The holyc-inference North Star docs describe disk-only model loading and no guest network dependency in the reviewed surfaces.

Impact: this audit found content-contract drift, not enabled networking. The corrective path should remain fully local and must not introduce fetchers, sockets, package-dependent online setup, or WS8 networking work.

## Evidence Commands

Read-only commands used:

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS log --format='%H %h %cI %s' -12
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference log --format='%H %h %cI %s' -8
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/mk-shared-img.sh | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/ns-preflight.sh | sed -n '1,110p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,180p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md | sed -n '1,70p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '204,216p'
```
