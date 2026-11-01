# hw/ip_package

Packaging the design as a Vivado custom IP. Only scripts are committed; the packaged IP is
generated into build/ip/<feature>/ by `make ip FEATURE=<feature>`.

- `package_ip.tcl` - generic packager (sources from files.f, AXI interfaces inferred from names,
  all bus interfaces associated with the clock port `clk`).
- `<feature>_customize.tcl` (optional) - sourced before saving: GUI pages, parameter ranges,
  extra interface associations.
After packaging, the IP is added to a block design in a throw-away project, validated and
synthesised out of context (`IP_RESULT: PASS`).
