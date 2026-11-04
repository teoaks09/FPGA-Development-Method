Mandatory reading: AGENTS.md, docs/coding_rules.md, the feature spec, hw/tb/common/.
Do NOT read hw/rtl/<feature>/: the testbench comes from the spec.

1. Write `hw/tb/<feature>/tb_<feature>.sv` (+ files.f) in SystemVerilog with hw/tb/common. Follow
   the Ross skill `vivado-simulate-rtl` for a self-checking testbench; for AXI ports AMD AXI VIP
   may be used. Annotate tests `// REQ: ID, ID`.
2. Expected values come from the spec examples or an independent reference, never from DUT output.
   Cover boundaries, reset and backpressure; fixed seeds for random tests.
3. `make sim FEATURE=<feature>`. On a mismatch do not change expected values to match the RTL:
   write which side you think is wrong and why, and stop. Spec ambiguity -> open question.
Never edit hw/tb/acceptance/ or hw/rtl/. Commit with `flow/git/commit.sh`.
