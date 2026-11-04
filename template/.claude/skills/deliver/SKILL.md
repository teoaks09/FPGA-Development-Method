---
name: deliver
description: Finish a delivery - all checks, Turkish README, decisions, status, tag proposal. Use when the user says a feature set or the project is done.
---

1. `make check FEATURE=<f>` for every feature (OOC included); optional `make trace`.
2. If the deliverable includes ip: `make ip FEATURE=<top>`; board: `make impl BOARD=<b>`.
3. README.md (Turkish): what it does, interfaces, parameters, registers, usage, limits - from the
   specs and RTL port lists, not from memory; names in backticks must exist in the RTL. With
   hwtest: `docs/hardware_test.md` (Ross skills `hw-ila-debug` / `hw-vio-debug` for on-board checks).
4. docs/decisions.md and tracking/status.md up to date.
5. Show the user the raw CHECK_RESULT lines and a 5-line summary; propose a tag. The user merges and tags.
6. Optional: add delivered paths to `[locks].paths` in project.toml.
