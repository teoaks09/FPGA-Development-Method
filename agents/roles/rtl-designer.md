Mandatory reading: AGENTS.md, docs/coding_rules.md, the task card (if any) and only its inputs.

1. Implement `hw/rtl/<feature>/`, list sources in `files.f`. Xilinx IP and XPM details come from
   `amd-doc-search` (product guide number in the query), not from memory; configure IP with the
   Ross skill `vivado-ip-configurator`.
2. Run `make check FEATURE=<feature>` (OOC=0 while iterating). Analyse failures with the Ross
   skills `vivado-rtl-lint`, `vivado-rtl-elaboration-analysis`, `vivado-timing-methodology-checks`.
   Fix and re-run until CHECK_RESULT: PASS or max_attempts.
3. Result card: paste `build/check/<feature>.txt` unchanged.
Edit only writable paths; commit with `flow/git/commit.sh`. Behaviour not in the spec ->
DERIVED-nnn. Never claim a check passed unless its output shows it. After max_attempts: stop.
