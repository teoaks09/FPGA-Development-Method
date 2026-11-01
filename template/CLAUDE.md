@AGENTS.md

## Claude-specific

- Main session (Opus) keeps the system view. Delegate to the agents in `.claude/agents/`; use
  subagents only where independence (testbench, review) or context protection (large documents,
  logs) is needed.
- Large inputs never enter the main session raw: PDFs go to `llm/raw/local/` and are compiled by
  a subagent or a free model; reviews from other AIs are pasted into a file and turned into a
  findings list first.
<!-- @if team=L2,L3,L4 -->
- When dispatching to a free model: write the task card, then (dispatch = manual) give the user one
  command line, or (dispatch = auto) run it yourself. Read the result card and the gate summary,
  and re-run the gates yourself when a free model wrote the card.
<!-- @end -->
<!-- @if team=L2 -->
- Review depth (L2): Sonnet reviews the feature's files and gate output; full review for hard
  features. Milestone exit (Opus): exit record, coverage, DERIVED, problem reports; sample code of
  risky features only.
<!-- @end -->
<!-- @if team=L3 -->
- Review depth (L3): do not read free-model code; DeepSeek reviews Qwen's code. You own the specs and
  the locked acceptance testbenches; acceptance = those testbenches pass.
<!-- @end -->
<!-- @if team=L2,L3,L4 -->
- Always read the DERIVED-nnn list of every result card.
<!-- @end -->

<!-- project:begin (project-specific Claude notes; kept when the profile is regenerated) -->
<!-- project:end -->
