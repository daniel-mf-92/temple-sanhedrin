# Law 9 Disk Reclaim Priority Boundary Research

Timestamp: 2026-05-01T12:27:58+02:00

Audit angle: deeper `LAWS.md` research.

Scope:
- Sanhedrin `LAWS.md` on `codex/sanhedrin-gpt55-audit`.
- TempleOS `MODERNIZATION/MASTER_TASKS.md` and recent Book-of-Truth disk-reclaim audit reports inspected read-only.
- TempleOS and holyc-inference source repos were not modified.
- No QEMU/VM command, SSH command, WS8 networking task, socket, TCP/IP, UDP, DNS, DHCP, HTTP, TLS, package-manager, or remote-runtime action was executed.

## Question

How should Law 9 define disk-reclaim ordering when "resource priority" and "delete non-log files" can be read in different directions?

Law 9 says the Book of Truth has absolute priority, lists the priority order as `Book of Truth > kernel core > process memory > file cache > user files > swap`, and says disk reclamation must not delete log files before all non-log files are exhausted. TempleOS task text for WS13-21 says disk reclaim should delete `user files > temp > swap` before touching the log allocation. Those statements agree that Book-of-Truth artifacts are last to be sacrificed, but they leave ambiguity about the order among non-log resources.

The intended invariant should be:

> Book-of-Truth disk writes must never be skipped. If reclaim is needed, the implementation must first protect the log allocation by explicit identity, then delete lower-priority non-log resources in a deterministic and documented order. If the order sacrifices user data before swap/temp, the doctrine must say so explicitly and justify why user files have lower reclaim priority than swap in that context.

## Evidence

1. `LAWS.md` Law 9 requires the Book of Truth to have absolute priority, forbids deleting log files before all non-log files are exhausted, and sets the priority order `Book of Truth > kernel core > process memory > file cache > user files > swap`.

2. `MODERNIZATION/MASTER_TASKS.md` repeats the same priority order, but the WS13 disk rule prose also says disk reclaim deletes `User files, temp files, swap` before log allocation.

3. The tracked retro audit for TempleOS commit `a070ae63a76a5ce30360be2a422718e574810e3f` flagged disk reclaim concerns around filename-based keep filtering, destructive delete evidence timing, and RED North Star closure.

4. Recent audits show this ambiguity is recurring: resource-supremacy reports review delete order, Book-of-Truth preservation, and fail-stop proof separately, but `LAWS.md` does not give a single scoring rule for the relative order of user files, temp files, and swap-like spill files.

5. A strict reading of a priority order means lower-priority resources should be reclaimed first. Under that reading, `swap` should be deleted before `user files`. A literal reading of the WS13-21 text reverses that order by naming user files first.

## Findings

1. **WARNING - Law 9 has an intra-law ordering ambiguity.**  
   The priority line places user files above swap, while the disk-reclaim task prose can be read as deleting user files before swap. Auditors can reasonably disagree on whether user-first deletion is compliance or drift.

2. **WARNING - "All non-log files" is too broad for immutable-image doctrine.**  
   Law 9 says non-log files are expendable before log allocation, but Law 10 says the OS image cannot be modified after install. `LAWS.md` should state that immutable OS files are not part of the disk-reclaim candidate set, even though they are non-log files.

3. **WARNING - Book-of-Truth preservation should be identity-based, not name-based.**  
   If a reclaim implementation keeps files only by substring, future log paths with different names can be misclassified as ordinary non-log files. Law 9 should require explicit ledger identity, allocation, mount, extent, or manifest protection.

4. **WARNING - Disk-pressure trigger evidence is separate from memory-ring pressure evidence.**  
   A reclaim cascade can be correct for in-memory ledger pressure and still fail disk-full cases if it never measures the disk target. Law 9 should require disk-reclaim audits to cite the disk pressure observation that triggered deletion.

5. **INFO - The safe audit rule is a three-part proof.**  
   A compliant disk-reclaim commit should prove: protected log identity, deterministic non-log deletion order, and fail-stop if the write still cannot complete after the ordered reclaim set is exhausted.

## Proposed LAWS.md Refinement

Add under Law 9:

```text
Disk reclaim ordering: before any Book-of-Truth disk write may fail for space, the system must identify the protected log allocation by explicit ledger identity, manifest, partition, extent, or sealed allocation handle. Filename substring matching is not sufficient proof.

The reclaim candidate set excludes immutable OS image files and kernel code/data covered by Law 10. Among writable non-log resources, deletion order must be deterministic and documented. Unless a more specific law or task explicitly overrides it, lower-priority resources are reclaimed first: swap/spill files, temporary files, user-cache files, then user data. Book-of-Truth log allocation is never reclaimed while any writable non-log candidate remains.

Disk-reclaim evidence must include the disk pressure observation for the persistence target. Memory-ring pressure alone is not proof that disk-space reclaim will trigger for disk-full failures.
```

Add an audit rule:

```text
When reviewing Law 9 disk reclaim, record three proof points: (1) protected log identity, (2) ordered non-log candidate set, and (3) fail-stop behavior after reclaim exhaustion. Score missing proof as WARNING unless the diff creates a live path that can delete log allocation or continue after a failed required log write, which is CRITICAL.
```

## Local Issue Opened

See `audits/issues/2026-05-01-law9-disk-reclaim-priority-boundary-issue.md`.
