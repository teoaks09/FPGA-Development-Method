---
name: task-card
description: Write a task card for handing work to a role/model (free model or Claude subagent), and process its result card. Use when dispatching RTL, testbench, review, documentation or wiki work.
---

Write:
1. Next free ID in tracking/tasks/ (T001, T002...). Copy `tracking/tasks/_template.md`.
2. Fill role, model (copy the `model:` line of the role's agent file), difficulty, branch.
3. Inputs: only what the role needs (spec sections, requirement IDs). Small inputs = cheap runs.
4. Writable paths: the narrowest globs possible. Gates: `make gates FEATURE=<f>` (or the
   relevant subset).
5. Dispatch per project.toml `profile.dispatch`:
   - manual: give the user exactly one line, e.g.
     `opencode run -m <model> --agent <role> "Execute tracking/tasks/T012.md"`
   - auto: run that command yourself.

Process the result:
1. Read only the result card and build/gates/<feature>.txt - not the whole diff.
2. Verify the gate lines yourself: re-run `make gates FEATURE=<f>` if the card was written by a
   free model (its statement is not evidence).
3. Read every DERIVED-nnn; accept into the spec or reject (task goes back).
4. Escalate after max_attempts: free model -> Sonnet -> Opus.
5. Add a row to tracking/model_scorecard.md; add bugs to tracking/problem_reports.md.
