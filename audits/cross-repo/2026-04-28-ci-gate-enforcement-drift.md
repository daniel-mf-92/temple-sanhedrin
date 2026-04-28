# Cross-Repo Invariant Audit: CI Gate Enforcement Drift

Timestamp: 2026-04-28T06:36:33+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical / cross-repo scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `3812751ba2db8eb3239520c93f16aa55fc176bb9`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `b8a4fc8b7dd7cb2175ff3e4e8f051a7d4b19ca7d`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `d2299cfe8ca805879380241aee38b8ff1e626975`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No live liveness watching was performed. No QEMU or VM command was executed.

## Summary

Found 5 findings: 4 warnings, 1 info.

The builder repos contain useful local gates for north-star evidence, identifier compounding, secure-local release readiness, and Trinity policy sync. CI does not enforce those gates symmetrically. TempleOS has a workflow, but it is explicitly a skeleton that only syntax-checks `automation/qemu-smoke.sh` and prints an air-gap reminder. holyc-inference has no workflow for its local gates; the only committed workflow is secret scanning. The result is CI drift: a push can pass GitHub Actions while bypassing the same checks the builders are told to run before commit.

## Finding WARNING-001: TempleOS CI does not run the north-star or Law 4 gates

Applicable laws:
- Law 4: Identifier Compounding Ban
- Law 5: North Star Discipline
- Law 2: Air-Gap Sanctity, by dependency on QEMU launch evidence

Evidence:
- `TempleOS/.github/workflows/modernization-smoke.yml:1` names the workflow `Modernization Smoke (Skeleton)`.
- `TempleOS/.github/workflows/modernization-smoke.yml:29-35` only runs `bash -n automation/qemu-smoke.sh` when that script exists.
- `TempleOS/.github/workflows/modernization-smoke.yml:37-48` makes ShellCheck non-blocking and avoids installing anything.
- `TempleOS/.github/workflows/modernization-smoke.yml:50-53` prints an air-gap reminder, but does not execute an air-gap audit.
- `TempleOS/automation/north-star-e2e.sh:21-26` is the committed north-star QEMU gate and includes `-nic none`.
- `TempleOS/automation/check-no-compound-names.sh:8-10` defines the committed identifier-compounding gate.

Assessment:
The TempleOS workflow can pass without running `automation/north-star-e2e.sh`, without running `automation/check-no-compound-names.sh HEAD`, and without executing any QEMU smoke under `-nic none`. This is a CI coverage gap, not a guest networking breach.

Required remediation:
- Add blocking CI steps for `bash automation/check-no-compound-names.sh HEAD` and a north-star gate mode that is safe for GitHub runners.
- If the full QEMU north-star run cannot execute in CI, add a blocking offline wrapper check that validates every QEMU launch path includes `-nic none` or `-net none` and marks the full guest run as externally required.

## Finding WARNING-002: holyc-inference CI does not run any inference gates

Applicable laws:
- Law 1: HolyC Purity
- Law 4: Integer Purity
- Law 5: North Star Discipline
- Secure-local / Trinity policy doctrine in Sanhedrin control docs

Evidence:
- `holyc-inference/.github/workflows/secret-scan.yml:1-18` is the only inspected committed workflow and only runs gitleaks.
- `holyc-inference/automation/check-trinity-policy-sync.sh:8-12` defines a machine-readable Trinity policy sync gate.
- `holyc-inference/automation/inference-secure-gate.sh:8` defines the secure-local release gate.
- `holyc-inference/automation/north-star-e2e.sh:1-47` defines the forward-pass north-star gate.
- `holyc-inference/automation/check-no-compound-names.sh` exists but is not referenced by a committed workflow.

Assessment:
holyc-inference has more local policy-gate automation than CI exercises. A commit can pass the current GitHub workflow while never proving Trinity policy sync, secure-local release readiness, identifier naming compliance, or the RED/green north-star status.

Required remediation:
- Add a CI workflow that runs, at minimum, `bash automation/check-no-compound-names.sh HEAD`, `bash automation/check-trinity-policy-sync.sh`, `bash automation/inference-secure-gate.sh`, and `bash automation/north-star-e2e.sh` or an explicit RED-but-recorded variant.
- Keep any host-side Python tests in `tests/` only; do not introduce non-HolyC runtime implementation code.

## Finding WARNING-003: Sanhedrin push-monitoring policy assumes useful CI signal that the builder workflows do not yet provide

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- The repository-level agent instructions require push-to-GitHub workflows to be monitored with `gh run list --repo <repo> --limit 1`.
- `TempleOS/.github/workflows/modernization-smoke.yml:29-53` currently produces only skeleton smoke syntax, optional ShellCheck, and a policy reminder.
- `holyc-inference/.github/workflows/secret-scan.yml:15-18` runs only gitleaks.

Assessment:
Monitoring CI after push is useful only if CI encodes the gates that matter. At present, a green CI run mostly proves secret scanning and a narrow TempleOS shell syntax check. It does not prove LAWS.md compliance, north-star progress, or secure-local readiness.

Required remediation:
- Treat current CI green as a weak signal in Sanhedrin reports until builder workflows run the local gates.
- Add a CI capability matrix to Sanhedrin audits: `secret_scan`, `syntax`, `law_gate`, `north_star`, `secure_local`, `trinity_policy`, and `guest_airgap`.

## Finding WARNING-004: Existing local gates are asymmetric across the trinity repos

Applicable laws:
- Law 5: North Star Discipline
- Sanhedrin Trinity policy parity rule

Evidence:
- TempleOS has `automation/north-star-e2e.sh` and `automation/check-no-compound-names.sh`, but no matching committed `check-trinity-policy-sync.sh` or secure-local release gate.
- holyc-inference has `automation/check-trinity-policy-sync.sh`, `automation/inference-secure-gate.sh`, `automation/north-star-e2e.sh`, and `automation/check-no-compound-names.sh`.
- The TempleOS workflow exists but is skeletal; holyc-inference has no non-secret-scan workflow.

Assessment:
The local-gate inventory is uneven. holyc-inference owns the cross-repo policy checker even though TempleOS is documented as the secure-local control plane. TempleOS owns a workflow, but it does not call the available hard gates. This makes enforcement dependent on which loop remembers to run which local script.

Required remediation:
- Move shared Trinity policy checks into Sanhedrin or mirror the same checker in both builder repos.
- Make each builder repo's CI call its local gates with the same pass/fail semantics that the loop prompt requires before commit.

## Finding INFO-001: No VM or network-enabling command was executed during this audit

Applicable laws:
- Law 2: Air-Gap Sanctity

Evidence:
- This audit read workflow, shell, and markdown files only.
- No QEMU/VM command was run.
- The inspected TempleOS north-star QEMU command includes `-nic none` at `TempleOS/automation/north-star-e2e.sh:21-26`.

Assessment:
The findings concern enforcement coverage, not a direct air-gap violation.

## Non-Findings

- No TempleOS or holyc-inference source file was edited.
- No WS8 networking task was executed.
- No QEMU or VM command was executed.
- No guest networking stack, NIC driver, socket, TCP/IP, UDP, TLS, DHCP, DNS, HTTP, or network-dependent package/runtime service was added or enabled.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/.github/workflows/modernization-smoke.yml | sed -n '1,90p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/.github/workflows/secret-scan.yml | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/north-star-e2e.sh | sed -n '1,80p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation/check-no-compound-names.sh | sed -n '1,100p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/check-trinity-policy-sync.sh | sed -n '1,150p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/inference-secure-gate.sh | sed -n '1,110p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation/north-star-e2e.sh | sed -n '1,80p'
find /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference -path '*/.github/*' -o -path '*/automation/*'
```
