---
name: new-feature
description: Start a new design feature - canonical folders, files.f lists and spec from the template. Use whenever a new RTL feature is added.
---

1. Pick a lower_snake_case name and a difficulty (simple | medium | hard).
2. `make feature NAME=<feature> DIFFICULTY=<d>`.
3. Fill `docs/specs/<feature>.md`: only what the implementer and the testbench writer need.
   Requirements as `- [FEAT-001] text (R-00x)`. Get the user's approval of the spec.
4. RTL: `hw/rtl/<feature>/<prefix>_<feature>.sv` (+ files listed in files.f). Testbench:
   `hw/tb/<feature>/tb_<feature>.sv`, written from the spec. Follow docs/coding_rules.md.
5. `make check FEATURE=<feature>`.
