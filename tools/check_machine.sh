#!/usr/bin/env bash
# One-time machine check (SETUP.md). Reads paths and model ids from kit_config.toml.
# Prints OK / MISSING / NOTE per item and MACHINE_RESULT: PASS|FAIL (only required items count).
set -u
kit="$(cd "$(dirname "$0")/.." && pwd)"
cfg() { python3 - "$1" <<'PY'
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
data = tomllib.load(open(sys.argv[2] if len(sys.argv) > 2 else "KIT/kit_config.toml".replace("KIT", __import__("os").environ["KIT"]), "rb"))
value = data
for part in sys.argv[1].split("."):
    value = value.get(part, "") if isinstance(value, dict) else ""
print(value)
PY
}
export KIT="$kit"
fail=0
ok()   { echo "OK       $*"; }
miss() { echo "MISSING  $*"; fail=1; }
note() { echo "NOTE     $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null \
    && ok "python $(python3 -V 2>&1 | cut -d' ' -f2)" \
    || { python3 -c 'import tomli' 2>/dev/null && ok "python (tomli fallback)" || miss "python >= 3.11 or pip install tomli"; }
for tool in git make bash; do have "$tool" && ok "$tool" || miss "$tool"; done

vivado="$(cfg tools.vivado_path)"
[[ -x "$vivado/bin/vivado" ]] && ok "vivado $("$vivado/bin/vivado" -version 2>/dev/null | head -1)" || miss "vivado at $vivado (kit_config.toml tools.vivado_path)"
have xsim && ok "xsim on PATH" || note "xsim not on PATH: source $vivado/settings64.sh in ~/.bashrc"
vitis="$(cfg tools.vitis_path)"
[[ -n "$vitis" && -d "$vitis" ]] && ok "vitis at $vitis" || note "vitis not found (only needed for Zynq PS / HLS)"
petalinux="$(cfg tools.petalinux_path)"
[[ -n "$petalinux" && -d "$petalinux" ]] && ok "petalinux at $petalinux" || note "petalinux not set (only for Linux on Zynq)"

have verilator && ok "verilator $(verilator --version | awk '{print $2}')" || miss "verilator"
have iverilog && ok "iverilog $(iverilog -V 2>&1 | head -1 | awk '{print $4}')" || miss "iverilog"

have claude && ok "claude $(claude --version 2>/dev/null | head -1)" || note "claude CLI not found (desktop app may still work; projects can run without Claude)"
if have opencode; then
    ok "opencode"
    models="$(opencode models 2>/dev/null)"
    for key in qwen deepseek; do
        id="$(cfg models.$key)"
        grep -qF "$id" <<<"$models" && ok "model $key = $id" || miss "model $key = $id not in 'opencode models'"
    done
else
    miss "opencode"
fi

ross_root="$(cfg tools.ross_mcp_root)"; ross_root="${ross_root/#\~/$HOME}"
version="$(cfg tools.ross_version)"
binary="$ross_root/$version/$(cfg tools.ross_mcp_binary | sed "s/{version}/$version/")"
[[ -x "$binary" ]] && ok "ross mcp $binary" || miss "ross mcp server $binary"
[[ -d "$HOME/.claude/skills" ]] && ls "$HOME/.claude/skills" 2>/dev/null | grep -qE "^(vivado|hls|hw)-" \
    && echo "WARN     Ross skills installed globally in ~/.claude/skills - remove them (they load twice)" || ok "no global Ross skills"

if have gh && gh auth status >/dev/null 2>&1; then ok "github (gh)"
elif ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then ok "github (ssh)"
else note "github not authenticated (not needed in the internal network)"; fi
have code && ok "vs code" || note "vs code not installed (optional)"

echo "MACHINE_RESULT: $([[ $fail -eq 0 ]] && echo PASS || echo FAIL)"
exit $fail
