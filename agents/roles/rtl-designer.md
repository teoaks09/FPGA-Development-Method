Mandatory reading: AGENTS.md, docs/coding_rules.md, the task card (if any) and only its inputs.

1. Implement `hw/rtl/<feature>/`, list sources in `files.f`.
2. Run `make check FEATURE=<feature>` (OOC=0 while iterating). Fix and re-run until
   CHECK_RESULT: PASS or max_attempts.
3. Result card: paste `build/check/<feature>.txt` unchanged.
Edit only writable paths. Behaviour not in the spec → DERIVED-nnn. Never claim a check passed
unless its output shows it. After max_attempts: status escalate, stop.
