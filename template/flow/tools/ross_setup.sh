#!/usr/bin/env bash
# Pin AMD Ross skills to this project: add the Ross repository as a git submodule at the
# version in project.toml and link its skills into .claude/skills/ (opencode reads it too).
# Ross skills must NOT also be installed globally (they would load twice).
#   flow/tools/ross_setup.sh            # first setup or re-link
#   flow/tools/ross_setup.sh <version>  # upgrade: change the pin, then run the full regression
set -eu
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
url="https://github.com/Xilinx/ross-ai-assistant.git"
target="third_party/ross-ai-assistant"
version="${1:-$(python3 flow/project_value.py tools.ross_version)}"

if [[ ! -e "$target/.git" ]]; then
    git submodule add "$url" "$target"
fi
git -C "$target" fetch --tags --quiet
git -C "$target" checkout --quiet "$version"
git add "$target"

mkdir -p .claude/skills
linked=0
for skill in "$target"/skills/*/; do
    name="$(basename "$skill")"
    link=".claude/skills/$name"
    [[ -e "$link" && ! -L "$link" && ! -f "$link/.ross-copy" ]] && { echo "skip $name (project skill with same name)"; continue; }
    rm -rf "$link"
    if ln -s "../../$target/skills/$name" "$link" 2>/dev/null; then :; else
        cp -r "$skill" "$link" && touch "$link/.ross-copy"   # fallback where symlinks fail (PILOT: Windows)
    fi
    linked=$((linked + 1))
done
if [[ "${1:-}" != "" ]]; then
    python3 - "$version" <<'PY'
import re, sys
path = "project.toml"
text = open(path).read()
open(path, "w").write(re.sub(r'ross_version = "[^"]*"', f'ross_version = "{sys.argv[1]}"', text))
PY
    echo "Ross pinned to $version. Next: make regress, then record the upgrade as a DR in decision_record.md."
fi
echo "ROSS_SETUP_RESULT: PASS version=$version skills=$linked"
