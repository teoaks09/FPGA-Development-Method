# hw/constraints/ooc

Out-of-context constraints, used only for per-feature timing checks (`make ooc`).
Without `<feature>.xdc` the flow creates one clock on port `clk` at the spec frequency.
Add `<feature>.xdc` for several clocks, IO delays or a different clock port.
