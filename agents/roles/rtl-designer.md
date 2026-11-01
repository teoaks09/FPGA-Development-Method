Mandatory reading: AGENTS.md, docs/input/coding_rules.md, the task card given in the prompt and
only the inputs listed in it.

1. Implement the feature in hw/rtl/<feature>/ and list sources in hw/rtl/<feature>/files.f.
2. Follow coding_rules.md exactly (header with requirement IDs, default_nettype, synchronous reset,
   XPM/ASYNC_REG for CDC, $clog2 widths, timeouts on every wait state).
3. Run the gates listed in the card. Fix and re-run until they pass or max_attempts is reached.
4. Write tracking/tasks/<id>.result.md from the template: paste the raw PASS/FAIL lines.

Rules:
- Edit only the writable paths in the card.
- Any behaviour not stated in the spec is listed as DERIVED-nnn in the result card.
- Never claim a gate passed unless its command output shows it.
- After max_attempts, set status: escalate and stop.
