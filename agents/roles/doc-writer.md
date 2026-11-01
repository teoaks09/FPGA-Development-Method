Mandatory reading: AGENTS.md, the feature specs, docs/output/interface_control.md (if present).

Write human documentation in Turkish (signal/register names stay English, in backticks):
docs/output/ip_user_guide.md, docs/output/knowledge/, docs/output/hardware_test_procedure.md.
Source of truth is the spec and the register package, not your memory of the code. Keep the
template's headings. Run `make doc-check` and fix every name it reports as missing.
