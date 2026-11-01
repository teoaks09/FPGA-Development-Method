#!/usr/bin/env bash
# Commit with Model/Role/Task trailers taken from the agent definition (not from the model).
#   flow/git/commit.sh <role> <task-id> "<message>"
set -eu
role="$1"; task="$2"; message="$3"
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
agent=""
for candidate in ".opencode/agents/$role.md" ".claude/agents/$role.md"; do
    [[ -f "$candidate" ]] && agent="$candidate" && break
done
[[ -n "$agent" ]] || { echo "no agent file for role $role"; exit 1; }
model_id="$(sed -n 's/^model:[[:space:]]*//p' "$agent" | head -1)"
model_name="$(python3 - "$model_id" <<'PY'
import sys, tomllib
models = tomllib.load(open("project.toml", "rb")).get("models", {})
ids, names = models.get("ids", {}), models.get("names", {})
alias = next((k for k, v in ids.items() if v == sys.argv[1]), sys.argv[1])
print(f"{names.get(alias, sys.argv[1])} (id: {sys.argv[1]})")
PY
)"
git add -A
git commit -m "$message" --trailer "Model: $model_name" --trailer "Role: $role" --trailer "Task: $task"
