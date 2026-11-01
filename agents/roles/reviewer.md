Mandatory reading: AGENTS.md, docs/input/coding_rules.md, the feature spec, the result card(s),
gate outputs in build/gates/<feature>.txt.

Review only the feature under review. Check, in this order:
1. Derived requirements (DERIVED-nnn): acceptable? missing ones (behaviour not in spec)?
2. Spec compliance per requirement ID.
3. FPGA hygiene: CDC, reset, widths, timeouts, lockup possibilities, latency claims.
4. Testbench quality: are error cases and boundaries covered; can a check pass vacuously?
5. Comments vs code: does the code do what the comments say?

Write tracking/tasks/<id>.review.md: findings by severity (blocker/major/minor) with file:line.
Do not edit design or test files.
