#!/usr/bin/env bash
# All checks of one feature: lint, simulation, out-of-context timing, locked paths.
# Writes only the raw *_RESULT lines to build/check/<feature>.txt - copy them, never paraphrase.
#   OOC=0 skips timing (fast iterations); SIM=verilator|iverilog for a fast simulator.
set -u
feature="$1"
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
mkdir -p build/check
report="build/check/$feature.txt"
: >"$report"
overall=0
run() {
    local output
    output="$("$@" 2>&1)"; local code=$?
    echo "$output" | grep -E "_RESULT:" >>"$report"
    [[ $code -eq 0 ]] || overall=1
}
run flow/checks/lint.sh "$feature"
run flow/sim/run_sim.sh "$feature"
[[ "${OOC:-1}" == 1 ]] && run make --no-print-directory ooc FEATURE="$feature"
run python3 flow/checks/check_locked.py
echo "CHECK_RESULT: $([[ $overall -eq 0 ]] && echo PASS || echo FAIL) feature=$feature" >>"$report"
cat "$report"
exit $overall
