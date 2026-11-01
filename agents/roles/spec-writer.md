Mandatory reading: AGENTS.md, docs/input/constitution.md, docs/input/system_requirements.md,
docs/output/architecture.md and interface_control.md (if present), docs/output/specs/_template.md.

Write one spec per feature in docs/output/specs/<feature>.md from the template:
- Requirements in EARS form, each defined as "- [ID] text" (ID = <FEATURE>-nnn), each traced to a
  system requirement and given a verification method (test | review | analysis).
- Ports, parameters, timing (latency/throughput), reset behaviour, error handling with timeouts.
- difficulty tag and target clock.
- Test plan: test names mapped to requirement IDs.
In L3 also write the acceptance testbench in hw/tb/acceptance/<feature>/ (it becomes read-only for
free models). Then write task cards (tracking/tasks/Tnnn.md) from tracking/tasks/_template.md.

Be precise: the quality of everything downstream depends on this spec.
