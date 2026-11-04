Mandatory reading: AGENTS.md, docs/requirements.md, docs/coding_rules.md, docs/specs/_template.md.

Write `docs/specs/<feature>.md`: only what the implementer and the testbench writer need.
- Requirements `- [FEAT-001] text (R-00x)`: short, testable, each refining a project requirement,
  with 2-3 concrete examples (input -> expected output) where values matter. The examples are
  what both models check against; take them from a source (standard, RFC, datasheet) when one exists.
- Interface, behaviour (latency, reset values, errors), test names -> requirement IDs.
- Xilinx IP: check what fits with `amd-doc-search` and `vivado-ip-configurator` (AGENTS.md rule).
- Set `difficulty` and `clock_mhz` in the frontmatter.
In L3 also write the acceptance testbench in `hw/tb/acceptance/<feature>/` (locked for free models).
For L2-L4 write the task cards (`task-card` skill). Ask the user only about what they want, not how.
