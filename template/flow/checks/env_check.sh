#!/usr/bin/env bash
# Compare the tools on this machine with the versions pinned in project.toml.
# Run when starting a session on a project that was idle, or on a new machine.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
pv() { python3 flow/project_value.py "$1"; }
problems=0
report() { echo "$1"; [[ "$1" == MISMATCH* || "$1" == MISSING* ]] && problems=$((problems + 1)); }

want="$(pv tools.vivado_version)"; path="$(pv tools.vivado_path)"
if [[ -x "$path/bin/vivado" ]]; then
    have="$("$path/bin/vivado" -version 2>/dev/null | head -1 | grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' | tr -d v)"
    [[ "$have" == "$want"* ]] && report "OK       vivado $have" || report "MISMATCH vivado want $want have ${have:-?}"
else
    report "MISSING  vivado $want at $path"
fi

want="$(pv tools.verilator_version)"
have="$(verilator --version 2>/dev/null | awk '{print $2}')"
if [[ -z "$have" ]]; then report "MISSING  verilator"
elif [[ "$want" == *x* || "$have" == "$want"* ]]; then report "OK       verilator $have (pinned: $want)"
else report "MISMATCH verilator want $want have $have"; fi

want="$(pv tools.ross_version)"
if [[ -d third_party/ross-ai-assistant/.git || -f third_party/ross-ai-assistant/.git ]]; then
    have="$(git -C third_party/ross-ai-assistant describe --tags --exact-match 2>/dev/null || echo untagged)"
    [[ "$have" == "$want" ]] && report "OK       ross skills $have" || report "MISMATCH ross skills want $want have $have"
else
    report "MISSING  ross skills (run flow/tools/ross_setup.sh)"
fi
if [[ -f .mcp.json ]]; then
    for binary in $(python3 -c "import json;[print(s['command']) for s in json.load(open('.mcp.json'))['mcpServers'].values() if 'command' in s]"); do
        [[ -x "$binary" ]] && report "OK       mcp $binary" || report "MISSING  mcp server $binary"
    done
fi

team="$(pv profile.team)"
if [[ "$team" != L1 ]]; then
    if command -v opencode >/dev/null; then
        models="$(opencode models 2>/dev/null)"
        for key in qwen deepseek; do
            id="$(pv models.$key)"
            grep -q "$id" <<<"$models" && report "OK       model $id" || report "MISSING  model $id (opencode models)"
        done
        report "NOTE     model versions behind aliases: check [models.names] against the platform"
    else
        report "MISSING  opencode"
    fi
fi
echo "ENV_RESULT: $([[ $problems -eq 0 ]] && echo PASS || echo FAIL) problems=$problems"
[[ $problems -eq 0 ]]
