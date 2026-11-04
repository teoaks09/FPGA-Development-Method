#!/usr/bin/env bash
# Machine check (SETUP.md). Reads model ids and the Ross folder from kit_config.toml.
# Versions are not pinned; the check shows what is installed.
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
[[ -f "$kit/kit_config.toml" ]] || { echo "MISSING  kit_config.toml (cp kit_config.example.toml kit_config.toml)"; echo "MACHINE_RESULT: FAIL"; exit 1; }
fail=0
ok()   { echo "OK       $*"; }
miss() { echo "MISSING  $*"; fail=1; }
note() { echo "NOTE     $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null \
    && ok "python $(python3 -V 2>&1 | cut -d' ' -f2)" \
    || { python3 -c 'import tomli' 2>/dev/null && ok "python (tomli fallback)" || miss "python >= 3.11 or pip install tomli"; }
for tool in git make bash; do have "$tool" && ok "$tool" || miss "$tool"; done

have vivado && ok "vivado $(vivado -version 2>/dev/null | head -1 | awk '{print $2}') at $(dirname "$(dirname "$(command -v vivado)")")" \
    || miss "vivado not on PATH (source <Vivado>/settings64.sh in ~/.bashrc)"
have xsim && ok "xsim on PATH" || miss "xsim not on PATH"
have vitis || have v++ && ok "vitis" || note "vitis not on PATH (only needed for Zynq PS / HLS)"
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

ross="$(cfg tools.ross_dir)"; ross="${ross/#\~/$HOME}"
[[ -x "$ross/vivado-mcp-server" ]] && ok "ross mcp server $ross/vivado-mcp-server" || miss "ross mcp server at $ross/vivado-mcp-server"
[[ -d "$ross/ross-ai-assistant/.git" ]] && ok "ross skills $(git -C "$ross/ross-ai-assistant" log -1 --format=%cs)" || miss "ross skills clone at $ross/ross-ai-assistant"
n="$(find "$HOME/.config/opencode/skills" -maxdepth 1 -type l 2>/dev/null | wc -l)"
[[ "$n" -gt 0 ]] && ok "opencode ross skill links: $n" || note "no skills in ~/.config/opencode/skills (tools/update_ross.sh)"
grep -q '"vivado"' "$HOME/.config/opencode/opencode.json"* 2>/dev/null && ok "opencode mcp vivado configured" || note "opencode mcp vivado not in ~/.config/opencode/opencode.json(c)"

if have gh && gh auth status >/dev/null 2>&1; then ok "github (gh)"
elif ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com 2>&1 | grep -q "successfully authenticated"; then ok "github (ssh)"
else note "github not authenticated (not needed in the internal network)"; fi
have code && ok "vs code" || note "vs code not installed (optional)"

echo "MACHINE_RESULT: $([[ $fail -eq 0 ]] && echo PASS || echo FAIL)"
exit $fail
