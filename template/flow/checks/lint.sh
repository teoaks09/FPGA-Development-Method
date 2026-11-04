#!/usr/bin/env bash
# Lint one feature with Verilator and Vivado. Prints LINT_RESULT: PASS|FAIL.
# A tool that is not available counts as FAIL unless LINT_ALLOW_SKIP=1 (then reported as SKIP).
set -u
feature="$1"
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
pv() { python3 flow/project_value.py "$1"; }
prefix="$(pv project.prefix)"
top="${TOP:-${prefix}_${feature}}"
out="build/lint/$feature"
mkdir -p "$out"

lists=()
[[ -f hw/rtl/common/files.f ]] && lists+=(-f hw/rtl/common/files.f)
lists+=(-f "hw/rtl/$feature/files.f")
waiver=()
[[ -f "hw/rtl/$feature/verilator.vlt" ]] && waiver+=("hw/rtl/$feature/verilator.vlt")

# Xilinx XPM sources are given to Verilator as libraries when Vivado is installed (PILOT).
xpm=()
vivado_bin="$(command -v vivado || true)"
vivado_path="${vivado_bin:+$(dirname "$(dirname "$vivado_bin")")}"
for library in "$vivado_path"/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv \
               "$vivado_path"/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv \
               "$vivado_path"/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv; do
    [[ -f "$library" ]] && xpm+=(-v "$library")
done

status=PASS
skip_note=""
if command -v verilator >/dev/null; then
    if verilator --lint-only -Wall --timing --top-module "$top" "${waiver[@]}" "${lists[@]}" \
            "${xpm[@]}" >"$out/verilator.log" 2>&1; then
        echo "LINT_VERILATOR_RESULT: PASS feature=$feature"
    else
        echo "LINT_VERILATOR_RESULT: FAIL feature=$feature (see $out/verilator.log)"
        grep -E "^%(Error|Warning)" "$out/verilator.log" | head -10
        status=FAIL
    fi
else
    echo "LINT_VERILATOR_RESULT: SKIP verilator not found"; skip_note+=" verilator"
fi

if [[ "${LINT_VIVADO:-1}" == 1 && -x "$vivado_bin" ]]; then
    "$vivado_bin" -mode batch -nojournal -log "$out/vivado.log" -source flow/vivado/lint.tcl \
        -tclargs "$feature" "$(pv project.part)" "$top" >"$out/vivado.stdout" 2>&1
    grep -E "^LINT_VIVADO_RESULT" "$out/vivado.stdout" || echo "LINT_VIVADO_RESULT: FAIL no result line"
    grep -q "^LINT_VIVADO_RESULT: PASS" "$out/vivado.stdout" || status=FAIL
else
    echo "LINT_VIVADO_RESULT: SKIP vivado not available"; skip_note+=" vivado"
fi

if [[ -n "$skip_note" && "$status" == PASS ]]; then
    if [[ "${LINT_ALLOW_SKIP:-0}" == 1 ]]; then status="PASS(skipped:${skip_note# })"; else status=FAIL; fi
fi
echo "LINT_RESULT: $status feature=$feature"
[[ "$status" == PASS* ]]
