# FPGA Development Method (fpga-method)

Kit for developing AMD/Xilinx FPGA (and Zynq PS) designs with Claude Code and free LLMs (opencode).
Light rules, standard structure: every project gets the same folders, generated agents, skills,
`AGENTS.md`/`CLAUDE.md` and plain make/Tcl checks.

| File | |
|---|---|
| `METHODOLOGY.md` | The method (Turkish) - start here |
| `SETUP.md` | One-time Ubuntu machine setup (Vivado, Verilator, iverilog, Claude Code, opencode, AMD Ross, GitHub, internal network) |
| `manifest.toml`, `template/` | Canonical project tree and its templates |
| `agents/roles.toml`, `agents/roles/` | Roles, permissions, model and effort per team level |
| `tools/new_project.py` | Create a project / change its profile |
| `tools/check_machine.sh` | Machine check |
| `kit_config.example.toml` | Machine-specific settings (copy to `kit_config.toml`) |
| `BENCHMARK.md`, `REVIEW_PROMPT.md` | Pilot measurement, external review |

Start a project: open Claude Code in an empty folder and say
"Kit: ~/fpga-method. Read METHODOLOGY.md and start a new project: <what you want>".

Version: `VERSION`. Requirements: Ubuntu, Python 3.11+ (or `tomli`), git, make.
Machine settings: `cp kit_config.example.toml kit_config.toml` (git-ignored).
