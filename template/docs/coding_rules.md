# Coding rules

Short on purpose. Extend only with rules that fixed a real problem.

## RTL (SystemVerilog)
- Module names start with the project prefix; one module per file, file name = module name.
- No abbreviations except: lsb, msb, tb, dut, clk, rst, axi, axis, axil, cdc, fifo, ram, rom, crc,
  id, tx, rx, cfg, cnt. Interfaces: `s_axis_*`, `m_axis_*`, `s_axil_*`.
- `` `default_nettype none `` at the top, `` `default_nettype wire `` at the end; 4 spaces.
- Header: module, one-line description, requirement IDs, Xilinx IP used.
- Synchronous active-high reset, only on control registers.
- CDC only through XPM (`xpm_cdc_*`) or an `ASYNC_REG` synchronizer; never use the first flop.
- Counter widths from `$clog2`; a wait state that can hang the system has a timeout.
- Xilinx IP / XPM: see AGENTS.md (design principles).

## Testbench (SystemVerilog or Verilog, never cocotb)
- `hw/tb/<feature>/tb_<feature>.sv`, sources in `files.f`; use `hw/tb/common` (tb_pkg, watchdog,
  AXI models). The testbench is written from the spec, not from the RTL.
- Tag checks with requirement IDs: `tb_check(cond, "msg", "R-001")`, tests with `// REQ: R-001`.
- End with exactly one `TB_RESULT: PASS` or `TB_RESULT: FAIL` (tb_finish does this).
