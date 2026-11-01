# fpga-method kit

This repository is the kit, not a project. Do not create projects inside it.
- To start a project: read METHODOLOGY.md (§11 "Başlarken") and use tools/new_project.py with a
  destination outside this repository.
- To change the kit: keep rules short and principle-level; every template file must be covered by
  manifest.toml; roles live only in agents/roles.toml + agents/roles/*.md. After a change, generate
  a few profiles with tools/new_project.py --dry-run / into a scratch folder and run their checks.
- Talk to the user in Turkish, briefly. Kit files are English except METHODOLOGY.md, SETUP.md and
  BENCHMARK.md (Turkish).
