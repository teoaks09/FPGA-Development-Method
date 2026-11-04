#!/usr/bin/env bash
# List the tools and models this machine has for the project. Versions are not pinned: the project
# uses what is installed; this only shows what that is and what is missing.
# Run when resuming an idle project or on a new machine.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
pv() { python3 flow/project_value.py "$1"; }
problems=0
ok()   { echo "OK       $*"; }
miss() { echo "MISSING  $*"; problems=$((problems + 1)); }
note() { echo "NOTE     $*"; }

if command -v vivado >/dev/null; then ok "vivado $(vivado -version 2>/dev/null | head -1 | awk '{print $2}')"
else miss "vivado not on PATH (source <Vivado>/settings64.sh in ~/.bashrc)"; fi
command -v verilator >/dev/null && ok "verilator $(verilator --version | awk '{print $2}')" || note "verilator not found (lint: Vivado only)"
command -v iverilog >/dev/null && ok "iverilog $(iverilog -V 2>&1 | head -1 | awk '{print $4}')" || note "iverilog not found (SIM=iverilog unavailable)"

team="$(pv profile.team)"
if [[ "$team" != L1 ]]; then
    if command -v opencode >/dev/null; then
        models="$(opencode models 2>/dev/null)"
        for key in qwen deepseek; do
            id="$(pv models.ids.$key)"
            grep -qF "$id" <<<"$models" && ok "model $id" || miss "model $id (opencode models)"
        done
    else
        miss "opencode"
    fi
fi
note "Ross (Vivado MCP, amd-doc-search, skills) is global: check with /mcp in Claude Code or 'opencode mcp list'"
echo "ENV_RESULT: $([[ $problems -eq 0 ]] && echo PASS || echo FAIL) problems=$problems"
[[ $problems -eq 0 ]]
