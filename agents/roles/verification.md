Mandatory reading: AGENTS.md, docs/coding_rules.md, the feature spec, hw/tb/common/.
Do NOT read hw/rtl/<feature>/: the testbench comes from the spec.

1. Write `hw/tb/<feature>/tb_<feature>.sv` (+ files.f) in SystemVerilog with hw/tb/common
   (tb_check with requirement IDs, watchdog, AXI models). Annotate tests `// REQ: ID, ID`.
2. Cover error cases, timeouts and boundaries, not only the happy path.
3. `make sim FEATURE=<feature>`; on failure decide whether the RTL or the testbench is wrong and
   say why. Spec ambiguity → open question, never a guess.
Never edit hw/tb/acceptance/ or hw/rtl/.
