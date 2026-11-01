# fpga-method

Kit for developing AMD/Xilinx FPGA (and Zynq PS) designs with Claude and free LLMs.

- `METHODOLOGY.md` - the method (Turkish). Give it, with this folder, to a Claude session.
- `manifest.toml` - canonical project tree and which profile creates which path.
- `template/` - files of the canonical tree.
- `agents/roles.toml`, `agents/roles/*.md` - roles: task, writable paths, model and effort per team level.
- `tools/new_project.py` - creates or grows a project from a profile.
- `kit_config.toml` - per machine: model ids, Vivado/Ross versions and paths. Edit once.

Quick start
```
python3 tools/new_project.py --name uart_lite --dest ~/work/uart_lite --weight light --team L1 \
    --deliver ip --prefix ul --part xc7a35ticsg324-1L --clock-mhz 100 --features uart:simple --git
cd ~/work/uart_lite && flow/tools/ross_setup.sh && make env-check
```
Requirements: Python 3.11+, git, bash, make; Vivado and Verilator on the work machine; opencode for L2-L4.

Maintenance: monthly Ross release check, model table updates from project scorecards (METHODOLOGY §14).
Version: see `VERSION`.
