# Identifier compounding risk (2026-04-27)

Trigger: repeated ultra-long chained function identifiers in `holyc-inference` recent commits (`HEAD~5..HEAD`) indicate architecture drift toward wrapper-on-wrapper naming.

Findings:
- Google style guidance emphasizes consistent naming for readability and maintainability, and avoiding redundant/overly cumbersome naming patterns.
- PEP 8 emphasizes readability-first naming conventions and consistent, simple function/module naming.
- Clean Code guidance (Fowler references) supports extracting intent clearly and avoiding names that obscure intent through accumulated suffix chains.

Why this matters here:
- Compounded names reduce reviewability, increase merge/conflict surface in generated queues, and weaken signal-to-noise in safety-critical audit code paths.
- The current chain pattern appears to encode workflow history in symbol names rather than in metadata/tests.

Recommended enforcement direction:
- Keep stable canonical symbol names and move variant metadata to structured tables/comments/tests.
- Cap new identifiers by length/token count (already law-bound), reject chained suffix growth at review/enforcement stage.
- Auto-fail iterations that add a new compounded variant when a canonical function already exists.

References:
- https://google.github.io/styleguide/cppguide.html
- https://google.github.io/styleguide/
- https://peps.python.org/pep-0008/
- https://martinfowler.com/bliki/FunctionLength.html
