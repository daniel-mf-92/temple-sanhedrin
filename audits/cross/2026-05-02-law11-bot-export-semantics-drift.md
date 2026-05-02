# Cross-Repo Law 11 Book-of-Truth Export Semantics Drift

Audit timestamp: 2026-05-02T07:23:59+02:00

Audit angle: cross-repo invariant check. This pass compared current TempleOS `HEAD` (`9f3abbf263982bf9344f8973a52f845f1f48d109`) against current holyc-inference `HEAD` (`2799283c9554bea44c132137c590f02034c8f726`) for Law 11 local-only Book-of-Truth semantics. Both sibling repos were inspected read-only. No TempleOS or holyc-inference source was modified. No live liveness watching, process restart, QEMU/VM command, networking command, or WS8 networking task was executed. The TempleOS guest air-gap was not touched.

Analyzer: `audits/cross/2026-05-02-law11-bot-export-semantics-drift.py`

## Summary

TempleOS law says Book-of-Truth reads must stay local: no log export, no forwarding, no path that makes log contents available outside the local console. holyc-inference is mostly aligned on air-gap and no HTTP, but several current work products name Book-of-Truth evidence as "export", "offline replay", or an "attestation evidence bundle" without an explicit local-console-only sink. That is a semantics drift rather than a confirmed network breach.

Finding count: 5 warnings.

## Evidence Matrix

| Check | Result |
| --- | ---: |
| Law 11 forbids log export commands | 1 |
| Law 11 forbids making log contents available outside local console | 1 |
| TempleOS Book of Truth uses COM1/local serial basis | 1 |
| TempleOS BookOfTruth has no `Export`-named API | 1 |
| holyc-inference `PrefixCacheExportAuditRows*` API count | 5 |
| holyc-inference prefix cache names Book-of-Truth rows | 1 |
| holyc-inference dispatch transcript says Book-of-Truth export | 1 |
| holyc-inference task plan requests attestation evidence bundle | 1 |
| holyc-inference has attestation manifest emitter | 1 |
| holyc-inference docs keep local API serial/no HTTP | 1 |
| holyc-inference prompt preserves secure-local | 1 |

## Findings

### WARNING-001: `PrefixCacheExportAuditRows*` normalizes "export" as the Book-of-Truth audit path

Law: Law 11, Book of Truth Local Access Only.

Evidence: `holyc-inference/src/runtime/prefix_cache.HC:3954` defines `PrefixCacheExportAuditRowsChecked`, and lines `3975-3976` say export is all-or-nothing so "Book-of-Truth rows stay deterministic". Follow-on wrappers at lines `4039` and `4141` preserve the same export naming. Law 11 in `temple-sanhedrin/LAWS.md:155-159` explicitly lists log export commands and paths making log contents available outside the local console as violations.

Impact: the inference side may be using "export" as a local tuple-copy term, but the name conflicts with the Law 11 forbidden action. That ambiguity makes future builders likely to add file/USB/copy semantics under an apparently approved Book-of-Truth export API.

### WARNING-002: Dispatch transcript says it is designed for Book-of-Truth export and offline replay

Law: Law 11, Book of Truth Local Access Only; Law 8, immediacy.

Evidence: `holyc-inference/src/gpu/dispatch_transcript.HC:4-8` describes a chain-hashed dispatch transcript and says it is designed for "Book-of-Truth export and offline replay verification". TempleOS Law 11 requires direct physical access only, while Law 8 requires the log to be synchronous and close to hardware, not a later replay artefact.

Impact: offline replay can be useful for diagnostics, but it must be clearly separated from Book-of-Truth read/export semantics. As written, the wording invites a bridge where Book-of-Truth evidence leaves the guest or is validated later as a substitute for the synchronous local ledger.

### WARNING-003: Attestation evidence bundle has no explicit local-only sink

Law: Law 11, Book of Truth Local Access Only.

Evidence: `holyc-inference/MASTER_TASKS.md:218` requests an "attestation evidence bundle" for trusted runtime sessions. `holyc-inference/src/runtime/attestation_manifest.HC:17-30` stores manifest lines in memory, and lines `253-317` emit key/value rows including session id, policy digest, GPU state, and Book-of-Truth hook state. I found no adjacent statement that these rows are local-console-only, serial-local, or forbidden from file/removable-media export.

Impact: an attestation manifest is not necessarily a Book-of-Truth log read, but it carries policy and hook evidence derived from the trusted control plane. Without a local-only sink contract, future code can turn the manifest into a remote-readable surrogate for Book-of-Truth state while claiming it is only attestation metadata.

### WARNING-004: Inference is good on no-HTTP, but Law 11 is stricter than no networking

Law: Law 11, Book of Truth Local Access Only.

Evidence: `holyc-inference/MASTER_TASKS.md:202` correctly scopes the OpenAI-compatible local API as "CLI-based, serial-port accessible, no HTTP", and `LOOP_PROMPT.md:21-36` preserves secure-local policy discipline. Law 11, however, also forbids dump-to-file, copy-to-removable-media, serial forwarding/proxying, or any path that exposes log contents outside the local console.

Impact: current docs could pass an air-gap/no-HTTP review while still leaving file export, host-side capture, or serial proxy semantics undefined. This is a cross-repo policy gap because TempleOS treats local physical presence as the boundary, not merely absence of sockets.

### WARNING-005: TempleOS Book-of-Truth producer vocabulary does not include export, but inference consumer vocabulary does

Law: Law 11, Book of Truth Local Access Only; cross-repo invariant.

Evidence: TempleOS `Kernel/BookOfTruth.HC:151-163` defines COM1 constants and local UART basis, and the scanned BookOfTruth file has no `BookTruth*Export` API. holyc-inference has multiple `ExportAuditRows` APIs and a dispatch transcript explicitly designed for Book-of-Truth export. This creates a producer/consumer vocabulary mismatch: the producer is local append/read/status oriented; the consumer normalizes export-style evidence handoff.

Impact: future integration work can appear policy-compliant inside each repo while violating the cross-repo invariant at the handoff. The shared contract should reserve "export" for forbidden Law 11 actions and use names like local status rows, local console rows, or append payload staging for permitted evidence.

## Recommended Follow-Up

- Rename or document inference "export" APIs as local in-memory staging only, not Book-of-Truth log export.
- Add a shared Law 11 sink contract: local console/serial-local status is allowed; file, removable-media, host capture, serial proxy, and remote transport are forbidden.
- Require attestation evidence bundles to declare their sink and provenance, and forbid bundling raw Book-of-Truth rows outside local physical access.
- Add a static gate that flags `Book.*Truth.*Export`, `Export.*Book.*Truth`, dump/copy/proxy wording, and serial forwarding unless explicitly marked out-of-scope.

## Read-Only Verification

```bash
python3 audits/cross/2026-05-02-law11-bot-export-semantics-drift.py
```

No QEMU/VM command was executed. No networking was enabled or touched.
