# Board __BOARD__

- `{{PREFIX}}___BOARD___top.sv` (listed in `files.f`) - board top: pins, clocking, reset, instantiates the design top
- `__BOARD__.xdc` - pin assignments, IO standards, board clocks
- `bd/*.tcl` - block designs exported with `write_bd_tcl` (e.g. Zynq PS)
- `manifest.txt` - files the clean build must produce
