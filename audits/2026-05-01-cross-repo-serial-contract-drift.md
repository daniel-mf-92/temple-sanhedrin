# Cross-Repo Serial Contract Drift Audit

- Audit angle: cross-repo invariant checks
- Timestamp: 2026-05-01T06:49:31+02:00
- Repos inspected: `TempleOS` and `holyc-inference`
- TempleOS HEAD: `c81806b97e2e698a1e18f695b2c43253c173b844`
- holyc-inference HEAD: `2799283c9554bea44c132137c590f02034c8f726`
- Scope note: read-only source/doc inspection only; no TempleOS guest, QEMU, VM, network, or builder-repo write operation was executed.

## Invariant Under Audit

TempleOS claims the serial path as the Book-of-Truth evidence path and the headless CLI control surface. `holyc-inference` assumes the same TempleOS guest can emit inference result tokens, stream user-visible output, and log every inference token/checkpoint to the Book of Truth. These contracts need a single shared serial framing policy before the repos can run one combined trusted E2E.

Relevant law anchors:
- `LAWS.md` Law 2 requires any guest run to remain air-gapped.
- `LAWS.md` Law 3 requires the Book of Truth to remain immutable and non-disableable.
- `LAWS.md` Law 8 requires Book-of-Truth logging to happen synchronously at hardware proximity.
- `LAWS.md` Law 11 forbids remote or exported Book-of-Truth viewing.

## Evidence

TempleOS:
- `TempleOS/MODERNIZATION/NORTH_STAR.md:17-22` defines a QEMU command that writes serial to `/tmp/north-star.log` and requires exactly three serial lines: `BoT: boot ok`, `BoT: keypress=q`, and `BoT: halt clean`.
- `TempleOS/MODERNIZATION/NORTH_STAR.md:26` says this exercises boot, HolyC compile, serial I/O, keyboard input, Book-of-Truth log line, and clean shutdown.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:23-28` requires serial-console headless operation and names `BookOfTruth;` and `Inference("prompt");` as CLI commands.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:161-166` says every Book-of-Truth entry exits instantly over raw serial and the host captures the serial copy.
- `TempleOS/MODERNIZATION/MASTER_TASKS.md:222-230` says the serial mirror must remain physically local and must not be forwarded, streamed, exported, or remotely accessed.

holyc-inference:
- `holyc-inference/NORTH_STAR.md:16-20` requires a Q4_0 GPT-2 model on `shared.img`, one HolyC forward pass, and next-token ID output over serial.
- `holyc-inference/MASTER_TASKS.md:9-10` targets `Inference("What is truth?");` in TempleOS with every token logged to the Book of Truth.
- `holyc-inference/MASTER_TASKS.md:23-24` says every inference call, every token, and tensor-op checkpoint must be loggable by the TempleOS Book-of-Truth ledger.
- `holyc-inference/MASTER_TASKS.md:112-116` includes an interactive streaming mode and Book-of-Truth hooks for model load, each token, and anomalies.
- `holyc-inference/MASTER_TASKS.md:197-204` includes a CLI-based, serial-port-accessible local API.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:1-12` names a GPU-to-Book-of-Truth event bridge for DMA, MMIO, and dispatch events.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:47-54` stores bridge events in an in-memory ring with `capacity`, `count`, `head`, and `next_seq_id`.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:154-161` explicitly advances the ring and overwrites the oldest event when full.
- `holyc-inference/docs/GGUF_FORMAT.md:198-202` keeps parser/runtime disk-only and requires QEMU runs to keep the NIC disabled.

## Findings

### 1. WARNING: The two north stars require incompatible serial success contracts

TempleOS currently treats success as exactly three `BoT:` lines on serial. Inference treats success as a model token ID emitted over serial from the same TempleOS guest. There is no shared framing rule that says whether inference token output is an extra serial stream, a Book-of-Truth event payload, or a replacement for the TempleOS three-line north-star fixture.

Impact:
- A combined E2E can fail spuriously because inference output violates TempleOS's exact-line serial expectation.
- A parser that accepts loose serial text can accidentally count user token output as Book-of-Truth evidence.

Recommendation:
- Define one serial frame grammar with explicit channels, for example `BOT ...` for immutable evidence, `OUT token_id=...` for user output, and `CTRL ...` for harness control.
- Update both north-star docs to reference the same grammar before merging the E2E surfaces.

### 2. WARNING: User-visible token streaming and Book-of-Truth serial evidence are not separated

TempleOS declares the serial mirror to be the canonical Book-of-Truth evidence path and local-only read surface. Inference declares token streaming, a serial-accessible local API, and per-token Book-of-Truth logging, but does not define how user output is kept distinct from sealed evidence bytes.

Impact:
- Book-of-Truth local-only rules can become ambiguous if the same captured serial file contains both audit records and ordinary inference output.
- The inference API could later normalize "read serial output" into "read Book-of-Truth content" unless the boundary is specified now.

Recommendation:
- Reserve a Book-of-Truth-only serial prefix or binary frame and require user output to use a separate prefix or console stream.
- Require Sanhedrin replay checks to reject unframed serial lines in trusted runs.

### 3. WARNING: Inference-side Book-of-Truth bridge semantics can drift from TempleOS immutability semantics

`holyc-inference/src/gpu/book_of_truth_bridge.HC` is useful as deterministic staging code, but it is named as a Book-of-Truth bridge while storing events in an overwriting in-memory ring. TempleOS's Book-of-Truth doctrine requires immediate serial exfiltration, no deferred queue, no skippable/overwritable log path, and fail-stop behavior on log failure.

Impact:
- If this bridge is later treated as the authoritative Book-of-Truth path, it conflicts with Law 3 and Law 8 expectations.
- If it remains a staging adapter, the contract needs to say which TempleOS routine performs the synchronous raw UART write and what happens when that write fails.

Recommendation:
- Document the bridge as non-authoritative staging only, or rename it away from Book-of-Truth semantics until it calls the TempleOS synchronous UART/log path.
- Add a cross-repo task requiring GPU/inference event IDs to be committed to TempleOS's Book-of-Truth schema before secure-local GPU enablement.

### 4. WARNING: Secure-local control-plane handoff lacks a shared failure record for inference output

TempleOS says trusted-load and key-release decisions belong to the TempleOS control plane with fail-closed behavior. Inference has attestation and policy-digest work, but the audited north-star output is still just a token ID over serial. There is no required serial record that binds the token ID to model hash, policy digest, profile, quarantine decision, and Book-of-Truth sequence number.

Impact:
- A correct token ID can be produced without proving it came from the trusted model/profile that TempleOS authorized.
- Later performance benchmarks may be hard to compare because the serial evidence does not bind result, policy, and Book-of-Truth sequence together.

Recommendation:
- Require the inference north-star serial output to include a local-only evidence tuple such as `model_hash`, `policy_digest`, `profile`, `bot_seq`, `prompt_hash`, and `token_id`.
- Treat a bare token ID as dev-local only, not secure-local release evidence.

## Summary

Findings: 4 total.

- Critical: 0
- Warning: 4

No current evidence shows the inference runtime adding networking, and this audit did not execute any VM or QEMU command. The drift is a contract gap: serial is simultaneously serving as Book-of-Truth evidence, CLI/user output, harness status, and proposed local API transport without a shared frame grammar or trust binding.
