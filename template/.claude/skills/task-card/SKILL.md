---
name: task-card
description: Hand a piece of work to a free model (opencode) with a task card, and process its result card. Use when dispatching RTL, testbench, review, documentation or wiki work in L2-L4.
---

Write
1. Next free ID in tracking/tasks/ (T001...). Copy `_template.md`; fill role, model (copy the
   `model:` line of the role's agent file), difficulty, branch.
2. Inputs: only what the role needs. Writable paths: as narrow as possible.
3. Dispatch per `profile.dispatch` in project.toml:
   manual - give the user exactly one line:
   `opencode run --auto -m <model> --agent <role> "Execute tracking/tasks/T012.md"`
   auto - run that command yourself.

Process
1. Read only the result card and `build/check/<feature>.txt`, then re-run `make check FEATURE=<f>`
   yourself - a free model's statement is not evidence.
2. Read every DERIVED-nnn: accept into the spec or send the task back.
3. After max_attempts: senior-engineer, then the main session.
4. Add a row (with start/end time) to tracking/model_scorecard.md.
