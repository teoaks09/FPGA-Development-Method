#!/usr/bin/env bash
# Update AMD Ross on this machine by hand, now and then (no per-project pinning).
#   1. git pull of the skills clone (<ross_dir>/ross-ai-assistant)
#   2. re-link every skill into ~/.config/opencode/skills (new skills added, removed ones dropped)
#   3. Claude Code plugin: refresh the marketplace and plugin (PILOT: check the commands)
# The Vivado MCP server binary and the local knowledge base are updated from the AMD download
# page by hand: replace <ross_dir>/vivado-mcp-server, then restart Claude Code / opencode.
set -u
kit="$(cd "$(dirname "$0")/.." && pwd)"
ross="$(python3 - "$kit/kit_config.toml" <<'PY'
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
print(tomllib.load(open(sys.argv[1], "rb"))["tools"]["ross_dir"])
PY
)" || exit 1
ross="${ross/#\~/$HOME}"
repo="$ross/ross-ai-assistant"
links="$HOME/.config/opencode/skills"

before="$(git -C "$repo" log -1 --format='%h %cs')"
git -C "$repo" pull --ff-only || { echo "ROSS_UPDATE_RESULT: FAIL git pull"; exit 1; }
after="$(git -C "$repo" log -1 --format='%h %cs')"

mkdir -p "$links"
for link in "$links"/*; do                      # drop links into the clone that no longer resolve
    [[ -L "$link" && ! -e "$link" && "$(readlink "$link")" == "$repo"* ]] && rm "$link"
done
count=0
while IFS= read -r skill; do
    dir="$(dirname "$skill")"; name="$(basename "$dir")"
    [[ -e "$links/$name" && ! -L "$links/$name" ]] && { echo "skip $name (not a link)"; continue; }
    ln -sfn "$dir" "$links/$name"; count=$((count + 1))
done < <(find "$repo" -name SKILL.md -not -path '*/.git/*')

if command -v claude >/dev/null; then
    claude plugin marketplace update >/dev/null 2>&1 && claude plugin update ross >/dev/null 2>&1 \
        && echo "claude plugin updated" \
        || echo "NOTE claude plugin: update it in Claude Code with /plugin (PILOT)"
fi
echo "Restart Claude Code and opencode to load the new skills."
echo "ROSS_UPDATE_RESULT: PASS skills $before -> $after links=$count"
