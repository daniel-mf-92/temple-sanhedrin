# Local Issue: Law 9 Disk Reclaim Priority Boundary

Timestamp: 2026-05-01T12:27:58+02:00

Source audit: `audits/research/2026-05-01-law9-disk-reclaim-priority-boundary.md`

## ISSUE-LAWS-009: Disk Reclaim Ordering and Protected Candidate Set

Problem: Law 9 requires the Book of Truth to outrank all resources and lists a priority order, while WS13 disk-reclaim prose can be read as deleting user files before temp/swap. Law 10 also means immutable OS files are not reclaim candidates even though they are non-log files. Current law text does not state how auditors should order non-log deletion, identify protected log allocation, or distinguish disk pressure from in-memory ledger pressure.

Impact: Retro audits can disagree on whether a reclaim implementation is compliant, especially when it uses name-based keep filters, user-first deletion order, or memory-ring pressure as the trigger for disk cleanup. This affects Law 9 scoring and Law 10 immutable-image safety.

Proposed resolution: Define disk-reclaim proof as three parts: explicit protected log identity, deterministic writable non-log deletion order, and fail-stop after reclaim exhaustion. Clarify that immutable OS files are excluded from reclaim and that disk pressure for the persistence target must be measured independently from memory-ring pressure.

