# Cross-Repo Invariant Audit: IRQ Book-of-Truth vs Token Evidence Contract

Audit timestamp: `2026-04-29T23:58:49+02:00`

Scope: Retroactive cross-repo invariant check between TempleOS `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `d84df3da3e8c241f43882f76493e1ae5a2f03b9e` and holyc-inference `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `485af0ea41a239c8393542d6e0e2fc5944f30f53`. Both target repos were read-only.

## Question

Does TempleOS' new all-PIC-IRQ Book-of-Truth coverage produce evidence that holyc-inference can consume without weakening the secure-local inference proof chain?

## Summary

TempleOS now routes PIC vectors `0x20..0x2F` through `INT_IRQ` and emits `BOT_EVENT_IRQ` / `BOT_EVENT_IRQ_ANOMALY` ledger entries. holyc-inference, however, models per-token Book-of-Truth evidence as a six-cell tuple `{session_id, step_index, token_id, logit_q16, policy_digest_q64, profile_mode}` plus status/count/digest, and its QEMU prompt benchmark extracts only `BENCH_RESULT` JSON or generic key/value metrics from serial output. The repos therefore agree that serial output is the local evidence channel, but they do not share an IRQ-aware evidence contract for correlating token output with interrupt interference, IRQ anomaly markers, or ledger sequence/hash continuity.

## Findings

### WARNING: IRQ ledger entries are not part of holyc-inference token evidence

Evidence:

- TempleOS defines `BOT_EVENT_IRQ` as event `4`, `BOT_EVENT_IRQ_ANOMALY` as event `13`, and `BOT_SOURCE_IRQ` as source `3` in `Kernel/BookOfTruth.HC:3-22` and `Kernel/BookOfTruth.HC:122-129`.
- TempleOS `BookTruthIRQRecord` appends `BOT_EVENT_IRQ/BOT_SOURCE_IRQ` with the IRQ number as payload, and may append `BOT_EVENT_IRQ_ANOMALY/BOT_SOURCE_IRQ` with the encoded anomaly payload in `Kernel/BookOfTruth.HC:15429-15454`.
- holyc-inference's canonical token evidence tuple has exactly six cells: session, step, token, logit, policy digest, and profile mode. It digests that tuple plus event status/count in `src/model/inference.HC:26-32` and `src/model/inference.HC:3445-3486`.
- The Python mirror test for IQ-1791 validates the same six-cell tuple and does not include TempleOS Book-of-Truth `seq`, `event_type`, `source`, `payload`, `prev_hash`, IRQ vector, or IRQ anomaly marker fields in `tests/test_iq1791_bot_emit.py:12-18` and `tests/test_iq1791_bot_emit.py:76-99`.

Impact:

- A secure-local inference transcript can say a token event was emitted under the expected policy digest, but cannot prove whether that token occurred under an interrupt storm, adjacent IRQ anomaly, or missing IRQ ledger continuity.
- This does not by itself violate Law 4 integer purity or Law 2 air-gap sanctity, but it is drift between the modernization repo's Book-of-Truth expansion and inference repo's token-level evidence model.

Required alignment:

- Add a shared contract, spec, or parser expectation that binds token events to a Book-of-Truth ledger range, at minimum `{first_seq, last_seq, last_hash_or_digest, irq_count, irq_anomaly_count}` for the token window.
- Keep the inference runtime HolyC-only; host-side tests/parsers may remain Python under the existing Law 1 exception.

### WARNING: QEMU prompt benchmark treats serial as benchmark output, not a mixed ledger stream

Evidence:

- holyc-inference documents `qemu_prompt_bench.py` as capturing serial output and extracting only `BENCH_RESULT` JSON or key/value metrics in `bench/README.md:28-35` and `bench/README.md:47-57`.
- The runner parses benchmark payloads by scanning serial text for a JSON payload or generic `key=value` pairs in `bench/qemu_prompt_bench.py:24-27` and `bench/qemu_prompt_bench.py:167-175`.
- The report stores raw `stdout_tail` and `stderr_tail`, but normalized `BenchRun` fields do not include Book-of-Truth ledger sequence/hash, IRQ event counts, anomaly marker counts, or chain verification status in `bench/qemu_prompt_bench.py:279-296`.
- TempleOS' new PIC IRQ path makes IRQ ledger chatter more important on the same serial channel: vectors `0x20..0x2F` are wired in `Kernel/KInts.HC:259-278`, while each non-timer PIC IRQ path calls `BookTruthIRQHook` from `INT_IRQ` in `Kernel/KInts.HC:5-20`.

Impact:

- Benchmark results can be marked structurally successful while silently ignoring adjacent `BOT` lines that would reveal interrupt noise, missing sequence continuity, or an IRQ anomaly during the same prompt run.
- Generic key/value parsing risks accepting unrelated status lines if they contain token-like keys before the intended `BENCH_RESULT`.

Required alignment:

- Make benchmark parsing ledger-aware: require either a bounded `BENCH_RESULT` prefix plus an accompanying Book-of-Truth summary, or reject runs where `BOT_EVENT_IRQ_ANOMALY` / `src=3` anomalies occur in the captured prompt window without being surfaced in the JSON result.
- Preserve air-gap by continuing to inject `-nic none`; this audit did not execute QEMU.

### CRITICAL: Shared evidence still inherits TempleOS' Law 8 IRQ proximity violation

Evidence:

- `INT_IRQ` calls `BookTruthIRQHook` before EOI, but that is still a helper call boundary rather than an inline serial emission sequence in `Kernel/KInts.HC:5-20`.
- `BookTruthIRQHook` wraps `BookTruthIRQRecord` in `Kernel/KInts.HC:285-287`, and `BookTruthIRQRecord` uses `BookTruthAppend` in `Kernel/BookOfTruth.HC:15429-15454`.
- LAWS.md Law 8 requires interrupt logging inside the IDT handler with zero software layers between the event and `out 0x3F8`.

Impact:

- Any holyc-inference evidence contract that consumes the current IRQ ledger as authoritative would inherit the known Law 8 violation already found in `audits/retro/d84df3da3e8c241f43882f76493e1ae5a2f03b9e.md`.
- The cross-repo invariant is therefore not merely missing fields; the producer evidence needs correction or an explicit policy amendment before inference can safely rely on it.

Required alignment:

- Treat IRQ-derived inference evidence as provisional until TempleOS emits the IRQ ledger record in the interrupt instruction path with no helper-layer dependency before the UART output.
- After that correction, update holyc-inference tests to verify token windows against the corrected ledger format.

## Non-Findings

- No networking stack, sockets, DHCP, DNS, HTTP, TLS, or WS8 execution was found in this audit path.
- holyc-inference's QEMU benchmark still injects `-nic none` and rejects common network arguments in `bench/qemu_prompt_bench.py:1-7` and `bench/qemu_prompt_bench.py:146-160`.
- No trinity source code was modified.

## Commands Run

- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD`
- `git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS show --format=fuller --patch --unified=80 d84df3da3e8c241f43882f76493e1ae5a2f03b9e`
- `rg -n "BOT_EVENT_IRQ|BOT_SOURCE_IRQ|BookTruthIRQ|IRQ|irq" Kernel MODERNIZATION automation`
- `rg -n "BookOfTruth|BookTruth|BOT_|bot_|token_event|serial|qemu|IRQ|irq" src bench tests docs MASTER_TASKS.md`
- `nl -ba Kernel/KInts.HC | sed -n '1,45p;240,305p'`
- `nl -ba Kernel/BookOfTruth.HC | sed -n '1,140p;15390,15470p;15510,15580p'`
- `nl -ba src/model/inference.HC | sed -n '1,45p;3380,3520p;3530,3660p'`
- `nl -ba tests/test_iq1791_bot_emit.py | sed -n '1,220p'`
- `nl -ba bench/qemu_prompt_bench.py | sed -n '1,80p;135,175p;260,340p'`
- `nl -ba bench/README.md | sed -n '1,90p'`

## Verdict

Cross-repo invariant is not yet satisfied. TempleOS has widened the Book-of-Truth IRQ evidence surface, but holyc-inference does not consume, verify, or bind that evidence to token-level secure-local outputs. Count: 3 findings (1 critical, 2 warnings).
