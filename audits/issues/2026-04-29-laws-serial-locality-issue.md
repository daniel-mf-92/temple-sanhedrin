# Local Issue: Book-of-Truth Serial Locality Boundary

Timestamp: 2026-04-29T23:21:16+02:00

Source audit: `audits/research/2026-04-29-laws-serial-locality-ambiguity.md`

## ISSUE-LAWS-006: Serial Mirror Locality

Problem: `LAWS.md` requires serial Book-of-Truth emission but does not explicitly distinguish physically local serial capture from remote serial observation. The phrase "serial port exfiltration" in Law 3 can be misread as permission to export logs, while Law 11 forbids forwarding, streaming, proxying, or remote viewing.

Impact: A builder or auditor can treat `-nic none` as sufficient proof even when Book-of-Truth serial contents are inspected through SSH/cloud-hosted QEMU. That preserves guest air-gap but can violate the local-access doctrine.

Proposed resolution: Define COM1/QEMU serial capture as a local-only mirror. Require validation records to state observer locality whenever Book-of-Truth serial contents are used as evidence. Remote hosts may be compile-only only when Book-of-Truth contents are absent or redacted.

