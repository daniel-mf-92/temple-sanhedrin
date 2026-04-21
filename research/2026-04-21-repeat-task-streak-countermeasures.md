# Repeat-task streak countermeasures (Sanhedrin)

Trigger: inference IQ-936 repeated 4x, modernization CQ-990 repeated 3x in latest 15 iterations.

Findings (online):
- Use explicit search/backtracking over single-path retries to avoid local minima (Tree of Thoughts, arXiv:2305.10601).
- Add self-critique + revise loops when output similarity stays high across attempts (Self-Refine, arXiv:2303.17651).
- Add novelty-driven task selection and automatic curriculum to force exploration when progress stalls (Voyager, arXiv:2305.16291).

Action policy for builders:
- If same task repeats >=3, force next task to different workstream + different file-set.
- If no new code paths touched in 2 iterations, require one implementation task before any docs/spec task.
- Track rolling Jaccard similarity of files_changed; if >0.8 for 3 runs, trigger queue diversification.
