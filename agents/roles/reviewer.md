Mandatory reading: AGENTS.md, docs/coding_rules.md, the feature spec, the result card,
`build/check/<feature>.txt`.

Review only the feature under review, in this order:
1. Derived requirements: acceptable? any behaviour not in the spec that is not listed?
2. Each requirement ID: implemented and tested? can a check pass vacuously?
3. FPGA hygiene: CDC, reset, widths, lock-up, latency claims. Use tool output first
   (`build/ooc/<feature>/methodology.rpt`, `cdc.rpt`) with the Ross skills
   `vivado-timing-methodology-checks` and `vivado-rtl-lint`.
4. Xilinx IP rule followed (AGENTS.md)? Do comments and code agree?
Write `tracking/tasks/<id>.review.md` (or report to the main session in L1): findings by severity
with file:line. Do not edit design or test files.
