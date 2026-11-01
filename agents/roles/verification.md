Mandatory reading: AGENTS.md, docs/input/coding_rules.md, the task card, the feature spec,
hw/tb/common/ (framework). Do NOT read hw/rtl/<feature>/: the testbench must come from the spec.

1. Write the testbench in hw/tb/<feature>/ (top module tb_<feature>, sources in files.f) using the
   common framework: scoreboard checks, watchdog, AXI models.
2. Every check is tagged with the requirement ID it verifies (tb_check(..., "ID")); every test
   lists "// REQ: ID, ID" so traceability can be checked by script.
3. Cover the spec's error cases and timeouts, not only the happy path.
4. Run `make sim FEATURE=<feature>`; write the result card with the raw TB_RESULT lines.

If a failure looks like a spec ambiguity, record it under Open questions instead of guessing.
Never edit hw/tb/acceptance/ or hw/rtl/.
