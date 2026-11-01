#!/usr/bin/env bash
# Run all gates of one feature (or --all features) and write build/gates/<feature>.txt.
# The file holds only raw result lines: copy them into result cards, never paraphrase.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
pv() { python3 flow/project_value.py "$1"; }
weight="$(pv profile.weight)"

if [[ "${1:-}" == "--all" ]]; then
    overall=0
    for dir in hw/rtl/*/; do
        feature="$(basename "$dir")"
        [[ "$feature" == common || ! -f "$dir/files.f" || ! -f "hw/tb/$feature/files.f" ]] && continue
        "$0" "$feature" || overall=1
    done
    if [[ "$weight" != light ]]; then
        python3 flow/checks/check_trace.py || overall=1
        python3 flow/checks/check_doc_names.py || overall=1
    fi
    python3 flow/checks/check_locked.py || overall=1
    exit $overall
fi

feature="$1"
mkdir -p build/gates
report="build/gates/$feature.txt"
: >"$report"
overall=0
run() {  # run a gate, keep only its *_RESULT lines in the report
    local output
    output="$("$@" 2>&1)"; local code=$?
    echo "$output" | grep -E "_RESULT:" >>"$report"
    [[ $code -eq 0 ]] || overall=1
}

run flow/checks/lint.sh "$feature"
if [[ "$weight" == light ]]; then
    run flow/sim/run_xsim.sh "$feature"
else
    run env COVERAGE=1 flow/sim/run_xsim.sh "$feature"
    run python3 flow/checks/check_coverage.py "$feature"
fi
if [[ "${OOC:-1}" == 1 ]]; then
    run make --no-print-directory ooc FEATURE="$feature"
fi
run python3 flow/checks/check_locked.py

echo "GATES_RESULT: $([[ $overall -eq 0 ]] && echo PASS || echo FAIL) feature=$feature" >>"$report"
cat "$report"
exit $overall
