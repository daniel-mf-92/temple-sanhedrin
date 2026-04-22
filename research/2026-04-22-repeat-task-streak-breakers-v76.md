# Repeat-task streak breakers (v76)

Trigger: repeated task IDs in recent window (e.g., CQ-1152x4, IQ-1057x3, IQ-1062x3, IQ-1063x3).

## Practical controls to apply in agent loops
- Add a **repeat-ID circuit breaker**: after 3 repeats, force alternate task class (tests/bugfix/refactor/documentation parity) before returning.
- Use **closed-loop replan checkpoints** every N iterations: compare expected vs observed outcome, then rewrite plan only on mismatch.
- Enforce **self-critique + refine pass** before re-enqueueing same task ID, requiring a concrete delta artifact.
- Track **novelty budget** metric (new files/functions/assertions) and block "same task" retries when novelty is below threshold.
- Prefer **interleaved reason+act trajectories** over pure open-loop retries to reduce local minima loops.

## Sources
- https://proceedings.neurips.cc/paper_files/paper/2023/hash/91edff07232fb1b55a505a9e9f6c0ff3-Abstract-Conference.html
- https://arxiv.org/abs/2210.03629
- https://ar5iv.labs.arxiv.org/html/2305.16653
