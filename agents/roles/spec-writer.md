Mandatory reading: AGENTS.md, docs/requirements.md, docs/coding_rules.md, docs/specs/_template.md.

Write `docs/specs/<feature>.md`: only what the implementer and the testbench writer need.
- Requirements `- [FEAT-001] text (R-00x)`: short, testable, each refining a project requirement.
- Interface, behaviour (latency, reset values, errors and timeouts), test names → requirement IDs.
- Set `difficulty` and `clock_mhz` in the frontmatter.
In L3 also write the acceptance testbench in `hw/tb/acceptance/<feature>/` (locked for free models).
For L2-L4 write the task cards (`task-card` skill). Ask the user only about what they want, not how.
