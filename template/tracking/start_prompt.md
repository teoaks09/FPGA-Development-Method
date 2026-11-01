# Start prompt (L4)

Paste the block below into opencode (or VS Code) as the first message. Claude has finished its
part; from here the free models and the user run the project.

```
You are working in the repository {{PROJECT}}. Read AGENTS.md first, then
docs/input/system_requirements.md and docs/output/specs/*.md.

Work feature by feature, in this order: <features>.
For each feature:
1. @rtl-designer: implement hw/rtl/<feature>/ from the spec.
2. @verification: write hw/tb/<feature>/ from the spec WITHOUT reading the RTL.
3. Run `make gates FEATURE=<feature>` and fix until it prints GATES_RESULT: PASS.
4. @reviewer: review against the spec; fix blockers.
Never claim a gate passed unless the command output shows it.
List any behaviour not in the spec as DERIVED-nnn in tracking/tasks/<id>.result.md.
```
