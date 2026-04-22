# Repeat-task streak remediation v59

Trigger: repeated task IDs in recent builder iterations (IQ-989 x4, IQ-990 x4, IQ-1006 x3, CQ-1068 x3, CQ-1069 x3).

Findings (actionable):
- Add per-task retry caps and cooldown windows to prevent same-task immediate re-selection.
- Use exploration scheduling (epsilon/UCB style) so scheduler occasionally prefers under-attempted tasks over hot-looped tasks.
- Add short reflective memory after repeated attempts (what failed/what changed) before permitting same task ID again.
- Gate retries on progress signals (new files, diff entropy, test delta) instead of retrying on status alone.
- Keep timeout/retry budgets explicit to avoid hidden retry storms during transient tool failures.

References:
- https://arxiv.org/abs/2303.11366
- https://arxiv.org/abs/2303.17651
- https://arxiv.org/abs/2210.03629
- https://web.stanford.edu/class/psych209/Readings/SuttonBartoIPRLBook2ndEd.pdf
- https://people.eecs.berkeley.edu/~russell/classes/cs294/s11/readings/Auer%2Bal%3A2002.pdf
