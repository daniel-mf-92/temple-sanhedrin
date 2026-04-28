# Cross-Repo Invariant Audit: I/O-Port vs GPU-MMIO Allowlist Semantics Drift

Timestamp: 2026-04-28T20:27:23+02:00

Audit owner: gpt-5.5 sibling, retroactive / historical scope only

Repos examined:
- TempleOS: `/Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS` at `1cc54d4593b798b6adbe93d2f7e43397a22eac5a`
- holyc-inference: `/Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference` at `ce09228422dae06e86feb84925d51df88d67821b`
- temple-sanhedrin audit branch: `codex/sanhedrin-gpt55-audit` at `a872bab80bef6ce493e3c6455229368deab7937a`

Audit angle: cross-repo invariant check. No TempleOS or holyc-inference source code was modified. No QEMU or VM command was executed.

## Summary

Found 5 findings: 1 critical, 3 warnings, 1 info.

TempleOS now exposes a Book-of-Truth I/O-port allowlist for legacy port I/O events, while holyc-inference exposes a GPU BAR/MMIO allowlist for security-gated writes. The two features use similar "allowlist" language, but they do not currently mean the same thing: TempleOS records an `allowed` bit after the I/O event path, while holyc-inference denies by default and returns reason codes before a write should be admitted. This creates a cross-repo invariant risk for any future shared policy, dashboard, or Sanhedrin parser that treats "allowlisted I/O" and "allowlisted MMIO" as equivalent.

## Finding CRITICAL-001: TempleOS allowlist records policy state but does not gate I/O like holyc-inference MMIO

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:1861-1884` defines `BookTruthIOPortAllowed` for COM1, PIC, PIT, keyboard, CMOS, and A20 ports.
- `TempleOS/Kernel/BookOfTruth.HC:1886-1899` computes `allowed` and appends a `BOT_EVENT_IO_PORT` payload, but returns `FALSE` if `bot_io_log_enabled` is off.
- `TempleOS/Kernel/BookOfTruth.HC:1902-1912` performs `InU8` or `OutU8`, calls `BookTruthIOPortRecord`, and does not branch on the returned append status.
- `holyc-inference/src/gpu/mmio_allowlist.HC:126-205` implements a deny-by-default checker where `out_allow` remains `0` unless BAR, register range, and width all match.

Assessment:
This is not a guest networking issue. The drift is that holyc-inference's allowlist is an enforcement predicate, while TempleOS's I/O-port allowlist is an audit annotation. If later tooling uses the TempleOS `allowed=1` / `blocked=1` counters as proof that blocked I/O was prevented, it will overstate the security property. For Book-of-Truth paths, the more serious local issue is that hardware I/O can continue even when the ledger append is skipped or fails, which conflicts with Laws 8 and 9.

Required remediation:
- Rename or document TempleOS status as `observed_allowed` / `observed_blocked` unless it actually gates I/O.
- If wrappers are meant to enforce policy, make the deny decision before the hardware access and fail-stop on ledger failure in the same path.
- Add a shared Sanhedrin invariant that distinguishes `audit_annotation` from `enforcement_gate`.

## Finding WARNING-001: No shared allowlist result vocabulary exists across port I/O and GPU MMIO

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:2017-2023` reports aggregate `allowed`, `blocked`, `in_ops`, `out_ops`, `last_port`, `last_val`, and `last_allowed`.
- `holyc-inference/src/gpu/mmio_allowlist.HC:15-21` defines reason codes including `DENY_DEFAULT`, `BAD_BAR`, `BAD_OFFSET`, `BAD_WIDTH`, `BAD_TABLE`, and `TABLE_OVERLAP`.
- `holyc-inference/tests/test_gpu_mmio_allowlist.py:169-206` asserts distinct unknown-BAR, out-of-range, width-mismatch, bad-table, and overlap outcomes.

Assessment:
TempleOS emits a binary allowed/blocked bit for observed legacy port I/O. holyc-inference carries reason-coded MMIO decisions. A cross-repo dashboard cannot currently answer whether a blocked TempleOS I/O event was denied by default, bad width, malformed table, or merely outside the allowlist after the fact.

Required remediation:
- Define a shared allowlist result schema: `subject`, `op`, `address_kind`, `address`, `width`, `decision`, `reason`, `enforced`.
- Preserve TempleOS's compact serial payload if needed, but publish a stable decoded status line with reason and enforcement mode.

## Finding WARNING-002: Address domains are not typed in shared policy language

Applicable laws:
- Law 5: North Star Discipline

Evidence:
- `TempleOS/Kernel/BookOfTruth.HC:1826-1830` packs marker, op, 16-bit port, 8-bit value, and allowed bit into one payload word.
- `holyc-inference/src/gpu/mmio_allowlist.HC:28-34` models GPU MMIO as BAR index plus register start/end plus width mask.
- `holyc-inference/src/gpu/book_of_truth_bridge.HC:9-12` says MMIO writes are a Book-of-Truth GPU event class, alongside DMA and dispatch events.

Assessment:
Both repos are discussing hardware access allowlists, but one address is an x86 I/O port and the other is a GPU BAR register offset. Without an explicit `address_kind`, policy consumers can accidentally compare `0x3F8` COM1 with a GPU register offset or treat both as the same hardware namespace.

Required remediation:
- Add an explicit domain marker to cross-repo audit docs and emitted reports: `x86_io_port`, `gpu_bar_mmio`, `dma_phys`, or `dispatch_queue`.
- Require invariant checks to reject cross-domain comparisons unless an adapter explicitly maps the domains.

## Finding WARNING-003: TempleOS smoke validates payload decoding but not fail-stop or enforcement semantics

Applicable laws:
- Law 8: Book of Truth Immediacy & Hardware Proximity
- Law 9: Resource Supremacy / Crash on Log Failure

Evidence:
- `TempleOS/automation/bookoftruth-ioport-allowlist-smoke.sh:10-15` uses a synthetic log fixture, not a live I/O wrapper execution.
- `TempleOS/automation/bookoftruth-ioport-allowlist-smoke.sh:73-82` checks total/decode/allow/block/op counts and allowed-bit consistency.
- `holyc-inference/tests/test_gpu_mmio_allowlist.py:160-224` checks allow, deny, error, overlap, and overhead behavior at the enforcement-helper level.

Assessment:
The TempleOS smoke is useful for decoder correctness, but it cannot prove that blocked I/O is prevented or that ledger failure halts execution. holyc-inference's test suite exercises policy gate outcomes directly. This difference matters because both features are now likely to be summarized as "allowlist coverage" in cross-repo reporting.

Required remediation:
- Add a TempleOS host-side replay classification that labels the result as decoder-only.
- Add a separate enforcement/fail-stop proof before reporting the I/O-port allowlist as a security gate.

## Finding INFO-001: Reviewed files preserve HolyC and air-gap boundaries

Applicable laws:
- Law 1: HolyC Purity
- Law 2: Air-Gap Sanctity

Evidence:
- TempleOS core changes reviewed are in `Kernel/BookOfTruth.HC` and `Kernel/KExts.HC`; the Python is confined to `automation/bookoftruth-ioport-allowlist-smoke.sh`.
- holyc-inference runtime changes reviewed are HolyC under `src/gpu/`; Python appears only in the allowed `tests/` directory.
- This audit did not execute QEMU, launch a VM, or run any WS8/networking task.

Assessment:
The finding set is semantic drift, not a HolyC purity or air-gap breach.

## Read-Only Verification Commands

```bash
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/TempleOS rev-parse HEAD
git -C /Users/danielmatthews-ferrero/Documents/local-codebases/holyc-inference rev-parse HEAD
git rev-parse HEAD
rg -n "IOPort|BookTruthInU8Log|BookTruthOutU8Log|BookTruthIOPortAllowed|BookTruthIOPortStatus" Kernel/BookOfTruth.HC Kernel/KExts.HC automation/bookoftruth-ioport-allowlist-smoke.sh
rg -n "GPUMMIO|MMIO|allowlist|BOT_GPU_EVENT_MMIO" src/gpu/mmio_allowlist.HC src/gpu/book_of_truth_bridge.HC tests/test_gpu_mmio_allowlist.py
bash automation/bookoftruth-ioport-allowlist-smoke.sh
PYTHONDONTWRITEBYTECODE=1 python3 tests/test_gpu_mmio_allowlist.py
```

Observed verification output:

```text
[bookoftruth-ioport-allowlist-smoke] pass: total=4 decode_ok=3 decode_fail=1 allowed=2 blocked=1 in=1 out=2 last_port=3F8 last_val=55
ok
```
