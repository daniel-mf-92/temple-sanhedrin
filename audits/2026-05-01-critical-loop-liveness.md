# CRITICAL: Builder loop liveness failure (2026-05-01)

- `codex-modernization-loop` and `codex-inference-loop` heartbeats stale (>10 min).
- Lockfile PIDs from loop logs are dead (`83376`, `83424`).
- Restart path via `ssh localhost` blocked in this environment (`Operation not permitted`).
- Direct loop relaunch is blocked by stale lock guard in each builder repo.

Impact: builders are not progressing; Sanhedrin marked this iteration `critical` and logged JSONL.
