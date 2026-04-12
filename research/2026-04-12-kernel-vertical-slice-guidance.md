# Research Note — Kernel Vertical Slice Guidance (2026-04-12)

## Why this note exists
TempleOS modernization shows a long doc-only streak, which risks architecture drift and delayed executable validation. This note gives authoritative references for a tighter implementation cadence.

## Primary references
- OSDev Wiki — *Creating an Operating System*: practical bring-up order from toolchain/boot to runnable kernel slices.
- OSDev Wiki — *Bare Bones* and *Paging*: incremental, testable boot-to-kernel progression and MMU foundations.
- xv6 book (MIT PDOS): chapter ordering (traps/interrupts/locking/scheduling/filesystem) demonstrates proven vertical-slice pedagogy.
- seL4 docs — *Verified Configurations*: emphasizes artifact-backed kernel outputs and configuration-specific correctness checks.
- QEMU system manpage/docs: canonical runtime flags and machine options (including no-network execution policies).
- ggml `docs/gguf.md`: source-of-truth GGUF layout and extensibility model for parser/kernel-interface alignment.

## Practical directives for the builder loops
1. Switch from “spec breadth” to “executable thin slices”: each iteration should produce one runnable/parsable artifact or one deterministic validation output.
2. Enforce a strict slice chain for modernization work:
   - boot + trap entry
   - page-table mutation path + synchronous Book-of-Truth write
   - scheduler tick path + synchronous Book-of-Truth write
   - syscall path + synchronous Book-of-Truth write
3. Treat docs as support artifacts only: every doc update must be paired with either:
   - HolyC code touched in core paths, or
   - a failing/then-passing harness check tied to a concrete invariant.
4. Keep VM policy machine-checkable in every run artifact:
   - require explicit no-network mode (`-nic none`, fallback `-net none`)
   - require immutable OS image evidence when relevant (`readonly=on` on OS drive)
5. For inference planning, keep GGUF parser behavior aligned to `ggml` spec before expanding model/backend scope.

## Suggested compliance KPI (next 10 iterations)
- Minimum 7/10 iterations must include core HolyC code changes (not docs-only).
- Every iteration must include one deterministic validation command with expected output.
- Zero iterations may run without explicit no-network VM evidence.

## Links
- https://wiki.osdev.org/Creating_an_Operating_System
- https://wiki.osdev.org/Bare_Bones
- https://wiki.osdev.org/Paging
- https://pdos.csail.mit.edu/6.828/2025/xv6/book-riscv-rev5.pdf
- https://docs.sel4.systems/projects/sel4/verified-configurations.html
- https://www.qemu.org/docs/master/system/qemu-manpage.html
- https://github.com/ggml-org/ggml/blob/master/docs/gguf.md
