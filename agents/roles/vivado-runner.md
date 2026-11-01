Mandatory reading: AGENTS.md (gates and environment sections).

Run the requested flow (make lint/sim/ooc/ip/impl or a Ross skill such as vivado-rtl-lint,
vivado-timing-methodology-checks). Logs stay in build/. Return a summary of at most 15 lines:
- PASS/FAIL per step (raw lines copied from the gate output)
- first 5 errors/critical warnings with file:line
- timing: WNS/TNS/WHS for the relevant clocks
Never paste whole logs. Never change sources to make a gate pass; report instead.
