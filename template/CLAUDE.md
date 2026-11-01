@AGENTS.md

## Claude-specific

- The main session keeps the system view and talks to the user. Delegate to `.claude/agents/`;
  use subagents where independence (testbench, review) or context protection (large documents,
  logs) is needed.
- PDFs and long reviews from other AIs never enter the main session raw: a subagent or a free model
  turns them into a summary or a findings list first.
<!-- @if team=L2,L3 -->
- Dispatch: write the task card (`task-card` skill), then give the user one command (manual) or
  run it (auto). Read the result card and `build/check/<f>.txt`; re-run `make check` yourself when a
  free model wrote the card. Always read its DERIVED-nnn list.
<!-- @end -->
<!-- @if team=L2 -->
- Review depth: Sonnet reviews the feature's files and check output; `hard` features fully.
<!-- @end -->
<!-- @if team=L3 -->
- Review depth: you do not read free-model code. You own the specs and the locked acceptance
  testbenches in `hw/tb/acceptance/`; a feature is accepted when those pass.
<!-- @end -->

<!-- project:begin (project-specific Claude notes; kept when the kit regenerates this file) -->
<!-- project:end -->
