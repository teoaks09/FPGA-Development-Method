#!/usr/bin/env bash
# Simulate one feature. Default simulator: xsim (Xilinx IP models).
# SIM=verilator or SIM=iverilog for fast runs of plain SV/Verilog testbenches (iverilog: limited SV).
# COVERAGE=1 collects xsim code coverage. TEST=<name> is passed as +TEST=<name>.
# Prints SIM_RESULT: PASS|FAIL (PASS requires exactly one "TB_RESULT: PASS" and no FAIL line).
set -u
feature="$1"
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
sim="${SIM:-xsim}"
top="tb_${feature}"
out="build/sim/$feature"
rm -rf "$out"; mkdir -p "$out"
plusargs=()
[[ -n "${TEST:-}" ]] && plusargs+=("+TEST=$TEST")

lists=(hw/tb/common/files.f)
[[ -f hw/rtl/common/files.f ]] && lists+=(hw/rtl/common/files.f)
lists+=("hw/rtl/$feature/files.f")
[[ -f "hw/tb/acceptance/$feature/files.f" ]] && lists+=("hw/tb/acceptance/$feature/files.f")
lists+=("hw/tb/$feature/files.f")

# Expand lists into absolute source paths (files.f paths are repository-relative).
sources=()
for list in "${lists[@]}"; do
    [[ -f "$list" ]] || { echo "SIM_RESULT: FAIL missing $list"; exit 1; }
    while read -r line; do
        line="${line%%#*}"; line="$(echo "$line" | xargs)"
        [[ -z "$line" || "$line" == +incdir+* ]] && continue
        sources+=("$root/$line")
    done <"$list"
done

case "$sim" in
xsim)
    (
        cd "$out"
        xvlog -sv "${sources[@]}" >compile.log 2>&1 || exit 10
        coverage=()
        [[ "${COVERAGE:-0}" == 1 ]] && coverage=(-cc_type sbct -cc_dir cov -cc_db "$top")
        xelab -debug typical -L xpm -L unisims_ver "${coverage[@]}" "$top" -s "$top" \
            >elaborate.log 2>&1 || exit 11
        xsim_args=(-R)
        [[ -n "${TEST:-}" ]] && xsim_args+=(--testplusarg "TEST=$TEST")
        xsim "$top" "${xsim_args[@]}" >sim.log 2>&1
        if [[ "${COVERAGE:-0}" == 1 ]]; then
            xcrg -cc_dir cov -cc_db "$top" -report_dir cov_report -report_format text \
                >coverage.log 2>&1
        fi
        exit 0
    )
    code=$?
    ;;
verilator)
    (
        cd "$out"
        verilator --binary --timing -Wno-fatal -Wno-lint -Wno-style --top-module "$top" \
            "${sources[@]}" -o "$top" >compile.log 2>&1 || exit 10
        "./obj_dir/$top" "${plusargs[@]}" >sim.log 2>&1
        exit 0
    )
    code=$?
    ;;
iverilog)
    (
        cd "$out"
        iverilog -g2012 -s "$top" -o "$top.vvp" "${sources[@]}" >compile.log 2>&1 || exit 10
        vvp -n "$top.vvp" "${plusargs[@]}" >sim.log 2>&1
        exit 0
    )
    code=$?
    ;;
*) echo "SIM_RESULT: FAIL unknown SIM=$sim"; exit 1 ;;
esac

if [[ $code -ne 0 ]]; then
    stage=$([[ $code -eq 10 ]] && echo compile || echo elaborate)
    echo "SIM_RESULT: FAIL feature=$feature sim=$sim ($stage error, see $out/)"
    grep -iE "error" "$out/compile.log" "$out/elaborate.log" 2>/dev/null | head -10
    exit 1
fi
grep -E "^\[FAIL\]" "$out/sim.log" | head -20
pass_count=$(grep -c "^TB_RESULT: PASS" "$out/sim.log")
fail_count=$(grep -c "^TB_RESULT: FAIL" "$out/sim.log")
grep -E "^TB_RESULT" "$out/sim.log" | tail -1
if [[ $pass_count -eq 1 && $fail_count -eq 0 ]]; then
    echo "SIM_RESULT: PASS feature=$feature sim=$sim"
else
    echo "SIM_RESULT: FAIL feature=$feature sim=$sim (pass=$pass_count fail=$fail_count lines)"
    exit 1
fi
