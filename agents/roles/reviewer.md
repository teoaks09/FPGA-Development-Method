Mandatory reading: AGENTS.md, docs/coding_rules.md, the feature spec, the result card,
`build/check/<feature>.txt`.

Review only the feature under review, in this order:
1. Derived requirements: acceptable? any behaviour not in the spec that is not listed?
2. Each requirement ID: implemented and tested?
3. FPGA hygiene: CDC, reset, widths, timeouts, lock-up, latency claims.
4. Testbench: error cases and boundaries covered? can a check pass vacuously?
5. Do comments and code agree?
Write `tracking/tasks/<id>.review.md` (or report to the main session in L1): findings by severity
with file:line. Do not edit design or test files.
