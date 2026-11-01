---
name: new-feature
description: Start a new design feature in this FPGA project - creates the canonical folders, files.f lists, spec from the template and the architecture row. Use whenever a new RTL feature/module group is added.
---

1. Ask (or take from the architecture) the feature name (lower_snake_case), difficulty and clock.
2. Run `python3 flow/gen/new_feature.py <feature> --difficulty <d> --clock-mhz <n>`.
3. The spec-writer fills `docs/output/specs/<feature>.md` (EARS requirements with IDs, interface,
   behaviour, errors/timeouts, test plan). Requirements cite the system requirements they refine.
4. RTL goes to `hw/rtl/<feature>/<prefix>_<feature>.sv` (+ more files listed in files.f), the
   testbench to `hw/tb/<feature>/tb_<feature>.sv`. Follow docs/input/coding_rules.md.
5. After the first RTL: `make codemap` and fill Purpose/Notes of the new cards.
Never place feature files outside these paths.
