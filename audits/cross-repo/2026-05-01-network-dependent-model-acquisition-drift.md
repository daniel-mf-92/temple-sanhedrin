# Cross-Repo Audit: Network-Dependent Model Acquisition Drift

Timestamp: 2026-05-01T00:49:17Z

Scope:
- TempleOS repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `738206d0abfd`
- holyc-inference repo: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `2799283c9554`
- Sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `8cfc13aaf023`

Audit angle: cross-repo invariant check. This pass checked whether model preparation and compatibility tasks preserve the hard air-gap requirement and the new instruction to reject network-dependent package ecosystems or remote runtime services.

No TempleOS or holyc-inference source files were modified. No QEMU, VM, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package install, or remote fetch command was executed.

## Summary

TempleOS policy is strict and consistent: guest networking is forbidden, WS8 remains out of scope, CI must stay offline-safe, and remote package/fetch flows are rejected. holyc-inference also states the runtime is disk-only with no downloading, HTTP, or networking.

The drift is in holyc-inference task wording for host-side model acquisition. Several future work items still say "download from Hugging Face", "pull Ollama blob", parse model cards, and compare against external local LLM ecosystems. Those tasks may be intended as host-side offline preparation, but they do not yet state the required boundary: no guest network, no remote runtime service, no network-dependent package ecosystem, and only pre-fetched local artifacts may enter the quarantine/hash-manifest flow.

Findings: 4 warnings, 1 info.

## Findings

### 1. WARNING: WS12 model-preparation tasks still describe online acquisition verbs

Evidence:
- `holyc-inference/MASTER_TASKS.md:20` says models are loaded from disk only, with no downloading, HTTP, or networking.
- `holyc-inference/MASTER_TASKS.md:181-186` defines host-side preparation from Hugging Face/Ollama sources, including "download from Hugging Face" and "pull Ollama blob".
- `holyc-inference/docs/GGUF_FORMAT.md:198-202` says the GGUF parser and runtime are disk-only and have no sockets, HTTP, model downloaders, or VM guest networking.

Impact: A builder could interpret WS12 as permission to add online model-acquisition scripts or package-backed fetch tooling, then rely on "host-side" as the exception. Under the hard policy, host-side validation may use local tooling, but the project should not depend on network fetches to pass a core iteration or trusted-load workflow.

Recommended invariant: Rewrite WS12-02/WS12-03 acceptance language to "import pre-fetched local artifacts from a host staging directory; document external acquisition as out-of-band human preparation only." Any optional fetch example should be marked non-CI, non-runtime, and out-of-scope for air-gapped validation.

### 2. WARNING: Ecosystem compatibility tasks do not distinguish local artifact parsing from remote service interaction

Evidence:
- `holyc-inference/MASTER_TASKS.md:197-204` lists Ollama blob extraction, LM Studio layout compatibility, an OpenAI-compatible local API, Hugging Face model-card parsing, and benchmarks against llama.cpp/Ollama/LM Studio.
- `holyc-inference/MASTER_TASKS.md:202` correctly says the OpenAI-compatible local API is CLI-based and has no HTTP, but the neighboring ecosystem tasks do not explicitly forbid invoking those tools as networked services.
- `TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:10-15` forbids connectivity-dependent runtime features, remote package fetchers, telemetry uploaders, and dependency models that require network access.

Impact: Future compatibility work can drift into service orchestration or remote model registry access while still appearing to be "local LLM ecosystem" work. That would violate the air-gap and remote-service boundary even if the inference runtime remains HolyC.

Recommended invariant: For WS15, require "parse local directories/blobs/manifests only; never call Ollama, LM Studio, OpenAI-compatible HTTP servers, model registries, or remote APIs from guest/runtime/CI paths." Benchmarks may compare against external tools only when their model files and binaries already exist locally.

### 3. WARNING: TempleOS policy rejects online CI/package flows, but holyc-inference host-side preparation lacks the same offline-CI guard

Evidence:
- `TempleOS/MODERNIZATION/CI_NOTES.md:16-24` rejects guest networking stages and dynamic `shellcheck` installation with `apt`, `brew`, `curl`, or container pulls.
- `TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:14-15` forbids package managers or build flows that require internet access.
- `holyc-inference/MASTER_TASKS.md:181-188` allows host-side Python/C tools for model preparation and reference output generation, but does not state that those tools must be runnable offline from local inputs.

Impact: The two repos can diverge on CI and tool bootstrap semantics: TempleOS fails closed on network-dependent validation, while inference model-prep work could introduce a tool that only works after online package/model fetches. That would make cross-repo release gates non-reproducible in an air-gapped environment.

Recommended invariant: Add an inference-side offline tool rule matching TempleOS: host tools may be non-HolyC, but CI/core validation must not install packages, download models, contact registries, or require remote services.

### 4. WARNING: Quarantine/hash-manifest policy is not explicitly bound to imported local artifacts

Evidence:
- `holyc-inference/MASTER_TASKS.md:26-29` requires `secure-local`, quarantine plus hash-manifest verification, GPU guardrails, and TempleOS control-plane trust decisions.
- `holyc-inference/MASTER_TASKS.md:181-186` describes model preparation from standard external sources before the quarantine section.
- `TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md:17-22` makes `secure-local` default and requires Book of Truth, model quarantine, hash verification, no guest networking, and TempleOS sovereignty as the control plane.

Impact: The docs state the right security posture, but the handoff from "external model ecosystem" to "trusted local artifact" is still implicit. Without a mandatory local import boundary, a future task can skip directly from a downloaded model to a trusted runtime path in prose or tooling.

Recommended invariant: Define the import boundary as a named artifact state: `external/out-of-band` -> `host-staged local file` -> `TempleOS quarantine` -> `manifest/hash verified` -> `trusted local load`. Only the latter four states are in project automation scope.

### 5. INFO: Current runtime/parser docs are aligned with the air-gap doctrine

Evidence:
- `holyc-inference/MASTER_TASKS.md:20` and `holyc-inference/docs/GGUF_FORMAT.md:198-202` both forbid runtime downloading, HTTP, model downloaders, and guest networking.
- `TempleOS/MODERNIZATION/SMOKE_TEST_CRITERIA.md:14-36` requires QEMU smoke runs to use explicit no-network evidence, preferring `-nic none` and allowing `-net none` only as a legacy fallback.
- `TempleOS/MODERNIZATION/CI_NOTES.md:9-18` requires QEMU/VM commands to disable guest networking and rejects networking-oriented guest build/test stages.

Impact: This audit found wording drift in future acquisition/prep tasks, not a current evidence of enabled guest networking.

## Evidence Commands

```bash
rg -n "download|Hugging Face|Ollama|pull|HTTP|http|network|remote|package|pip|npm|curl|wget|TLS|DNS|DHCP|TCP/IP|socket" /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/NORTH_STAR.md /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/automation -g '!*.log' -g '!*.tmp.*'
rg -n "download|Hugging Face|Ollama|pull|HTTP|http|network|remote|package|pip|npm|curl|wget|TLS|DNS|DHCP|TCP/IP|socket|WS8" /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/README.md /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/automation -g '!*.log' -g '!*.tmp.*'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/MASTER_TASKS.md | sed -n '1,35p;176,206p;2048,2062p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference/docs/GGUF_FORMAT.md | sed -n '1,18p;196,204p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/CI_NOTES.md | sed -n '1,35p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/AGENT_HOLYC_MODERN_OS_GUIDE.md | sed -n '1,25p'
nl -ba /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS/MODERNIZATION/SMOKE_TEST_CRITERIA.md | sed -n '1,40p;68,74p'
```

