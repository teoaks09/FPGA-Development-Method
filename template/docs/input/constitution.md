# Constitution

Non-negotiable principles of this project. Changes need the user's approval.

## 1. Vendor and languages
- AMD/Xilinx only. RTL and testbenches in SystemVerilog (no cocotb). UVM only with a written reason.
- Simulator: xsim is primary (Xilinx IP models). Verilator for lint and fast unit tests, version
  pinned in project.toml. Each test is assigned to exactly one simulator.

## 2. Reuse first
- Use Xilinx IP / XPM for MACs, FIFOs, CDC and similar. An own design where a suitable IP exists
  needs the user's approval and a decision record. RAM/ROM may be inferred from RTL.

## 3. Keep it simple, but complete
- A costly feature no scenario needs is left out as a documented constraint, and violating it is
  visible through a counter. A functionally required feature is never dropped for simplicity.

## 4. Robustness
- The design never locks up: every wait state has a timeout. Dropped data is counted by cause.

## 5. Single source
- Register map and defaults live in one SystemVerilog package; documents and C headers are
  generated from it or checked against it by script.

## 6. Repository first
- The Vivado project is a temporary output under build/. Committed Tcl creates it and references
  repository files in place (`add_files`, never `import_files`). IP is generated from committed
  IP Tcl; block designs are stored with `write_bd_tcl`. .xci, .runs, DCP and bitstreams are never
  committed. Any setting changed in the GUI is written back to Tcl/XDC before the work counts as
  done. Clean-build check: `git archive` → empty folder → project + synthesis → expected manifest.
- Scripts run with plain make/Tcl, without any AI tool or MCP server.

## 7. Constraints
- Board XDC (pins, IO, board clocks) in hw/boards/<board>/; constraints that travel with the
  design (CDC, clock groups, multicycle) as scoped XDC in hw/constraints/ip/ (UG903);
  out-of-context clock definitions in hw/constraints/ooc/.

## 8. AI-produced work
- LLM output is unqualified tool output. It is accepted only after an independent check: a script
  gate, a different model, or a review. A gate result is never taken from a model's statement.
- RTL and its testbench are written by different agents (different models from L2 on); the
  testbench comes from the spec, not from the RTL.
- Behaviour not in the spec is a derived requirement and must be listed and accepted.
