# {{PROJECT}}

<!-- project:begin (project-specific text; kept when the profile is regenerated) -->
{{SUMMARY}}

Deviations from the kit: none
<!-- project:end -->

## Profile

`{{PROFILE_LINE}}`

- Weight: {{WEIGHT}} · Team: {{TEAM}} · Deliverables: {{DELIVERABLES}}
- Kit: fpga-method {{KIT_VERSION}} · Generated: {{DATE}} (do not hand-edit generated sections;
  re-run the kit's new_project.py --existing after a profile change)
<!-- @if team=L2,L3 -->
- Dispatch: {{DISPATCH}} (manual: Claude gives the user one command line; auto: Claude runs `opencode run`)
<!-- @end -->
<!-- @if team=L4 -->
- Claude set up this project and withdrew. The user runs the free models (opencode or VS Code);
  the start prompt is in `tracking/start_prompt.md`.
<!-- @end -->

Machine-readable settings: `project.toml`.

## Where is what

{{WHERE_TABLE}}

Paths are canonical across all projects: a file is either at its canonical path or absent.
New files go to the extension points only (new feature folders, new docs under docs/output/).

## Working rules

- Talk to the user in Turkish, briefly. All project files are English, except human docs
  (`docs/output/ip_user_guide.md`, `docs/output/knowledge/`, `docs/output/hardware_test_procedure.md`)
  which are Turkish; signal and register names stay English.
- `docs/input/**` changes only with the user's approval.
<!-- @if weight=standard,comprehensive -->
- Files of an approved milestone (frozen paths in its exit record) change only with approval.
<!-- @end -->
- Never merge to `main`, never install system packages without being asked.
- LLM output is unqualified tool output: a gate is passed only when its script says so.
  Copy raw PASS/FAIL lines; never summarise a gate result from memory.
- Behaviour not in the spec is a derived requirement: list it as DERIVED-nnn in the result card.
- Do not paste large logs or PDFs into the conversation. Logs stay in `build/`; sources are read
  section by section{{WIKI_HINT}}.
- Coding rules: `docs/input/coding_rules.md` (read the sections relevant to your task).
  Design principles: `docs/input/constitution.md`.

## Gates

| Command | What |
|---|---|
| `make lint FEATURE=<f>` | Verilator + Vivado lint |
| `make sim FEATURE=<f>` | xsim testbench, `TB_RESULT: PASS` required |
| `make ooc FEATURE=<f>` | Out-of-context synthesis + timing at the spec clock |
| `make gates FEATURE=<f>` | All feature gates; summary in `build/gates/<f>.txt` |
<!-- @if weight=standard,comprehensive -->
| `make trace` | Requirement ↔ test traceability |
| `make doc-check` | Names in human docs exist in RTL |
| `make codemap` | Regenerate `llm/wiki/codemap/` interface sections |
| `make regress` | All features, all gates |
<!-- @end -->
<!-- @if deliverable=ip -->
| `make ip` | Package the design as a Vivado custom IP and integration-test it |
<!-- @end -->
<!-- @if deliverable=board -->
| `make impl BOARD=<b>` | Board implementation, timing closure, bitstream |
<!-- @end -->
| `make check-locks` | Locked paths unchanged |
| `make env-check` | Installed Vivado/Ross/model versions vs project.toml (tools change only between milestones) |

## Roles

{{ROLE_TABLE}}

<!-- @if team=L2,L3,L4 -->
## Handoff (Claude ↔ free models)

- Work is handed over only through files: task card `tracking/tasks/Tnnn.md`, result card
  `Tnnn.result.md`, review `Tnnn.review.md`. Templates are in `tracking/tasks/`.
- Free models run as primary agents with the model stated explicitly:
  `opencode run -m <model> --agent <role> "Execute tracking/tasks/Tnnn.md"`.
- Each task runs on its own branch. Commit with `flow/git/commit.sh <role> <task> "<message>"`
  (adds Model/Role/Task trailers).
<!-- @if team=L2,L3 -->
- After {{MAX_ATTEMPTS}} failed attempts on a gate the card is escalated: free model → senior-engineer
  (Sonnet) → main session (Opus).
<!-- @end -->
<!-- @if team=L4 -->
- After {{MAX_ATTEMPTS}} failed attempts on a gate, stop and report to the user.
<!-- @end -->
- Results go to `tracking/model_scorecard.md`.
<!-- @end -->

## Environment

- Vivado {{VIVADO_VERSION}} at `{{VIVADO_PATH}}` (do not search the file system for Vivado)
- Part: `{{PART}}` · Module prefix: `{{PREFIX}}_`
- AMD Ross {{ROSS_VERSION}}, pinned per project: skills from the submodule
  `third_party/ross-ai-assistant` linked into `.claude/skills/` (`flow/tools/ross_setup.sh`);
  Vivado MCP server binary of the same version (path in `.mcp.json` / `opencode.json`).
  Never install Ross skills globally (they would load twice).
  Use `amd-doc-search` for AMD documents (put the document number in the query, e.g. "PG203 ...").
  Do not use `vivado-revision-control` as the build method; use it only to export GUI changes and
  to verify that a rebuilt project matches.
- Scripts run with plain `make`/Tcl, without Claude, opencode or MCP.
