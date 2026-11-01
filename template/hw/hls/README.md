# hw/hls

One folder per Vitis HLS kernel (copy `_kernel_template/`): `src/` synthesizable C++, `tb/` C
simulation testbench, `hls_config.cfg`. The exported IP is generated into build/hls/<kernel>/
(never committed) and added to the design by script. Use the Ross skills hls-run-flow,
hls-optimize and hls-architect.
