# Coding rules

## Naming
- Module and package names start with the project prefix (see project.toml).
- No abbreviations. Allowed: lsb, msb, tb, dut, clk, rst, axi, axis, axil, cdc, fifo, ram, rom,
  crc, id, ip, tx, rx, cfg, cnt (extend this list here, nowhere else).
- Active-low signals end in `_n`. Registered/next pairs: `<name>_reg` / `<name>_next`.
- Interfaces: AXI-Stream `s_axis_*` / `m_axis_*`, AXI4-Lite `s_axil_*`.

## File layout
- 4 spaces, no tabs. One module per file, file name = module name.
- First line `` `default_nettype none ``, last line `` `default_nettype wire ``.
- Mandatory header:
  ```
  // Module      : <name>
  // Description : <one line>
  // Requirements: <ID, ID, ...>
  // Xilinx IP   : <IP/XPM used and checked documents, or "none">
  ```

## Style
- Default: single `always_ff` block. Two-block style only with `_reg`/`_next`.
- Synchronous, active-high reset (Xilinx recommendation). Reset only control registers; the data
  path is not reset.
- CDC only through XPM (xpm_cdc_*) or a synchronizer with `(* ASYNC_REG = "TRUE" *)`; never use
  the first synchronizer flop's output.
- Counter widths from `$clog2(...)`; no oversized counters.
- Every state that waits for an external event has a timeout counter and an error/counter output.
- No latches, no initial blocks in RTL (except ROM init), no `#` delays in RTL.

## Testbench
- Top module `tb_<feature>` in hw/tb/<feature>/, sources in files.f.
- Use hw/tb/common: tb_pkg (tb_check, tb_finish), watchdog, AXI models.
- Each test is annotated `// REQ: ID, ID`; each check passes the requirement ID.
- The run ends with exactly one `TB_RESULT: PASS` or `TB_RESULT: FAIL` line.
