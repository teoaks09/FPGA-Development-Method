---
name: register-change
description: Change the register map consistently - register package, interface_control.md, C header and user guide together. Use for any register add/remove/rename/reset-value change.
---

1. Edit the register package in hw/rtl/common/ (single source).
2. Update docs/output/interface_control.md register table (or regenerate if a generator exists).
3. Update sw/driver headers (if present) and docs/output/ip_user_guide.md.
4. Update the affected specs' requirements and tests.
5. `make doc-check`, `make trace`, and the gates of the affected features.
