---
name: milestone-exit
description: Close a milestone - full regression, exit record, frozen paths, tag proposal. Use when the user says a milestone is done or asks for the exit review.
---

1. `make regress` (via vivado-runner; read only the summary lines).
2. `make trace`, `make doc-check`, `make wiki-lint`, `make check-locks`.
3. Copy tracking/_exit_record_template.md to tracking/<milestone>/exit_record.md and fill it with
   raw result lines and evidence per requirement. List frozen paths.
4. exit-reviewer reviews (derived requirements, problem reports, coverage, sampled code).
5. Update the scorecard summary. Recommend pass/fail; the user approves, merges and tags.
