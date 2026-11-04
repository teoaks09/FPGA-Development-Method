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
import sys
try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib
models = tomllib.load(open("project.toml", "rb")).get("models", {})
ids, names = models.get("ids", {}), models.get("names", {})
alias = next((k for k, v in ids.items() if v == sys.argv[1]), sys.argv[1])
print(f"{names.get(alias, sys.argv[1])} (id: {sys.argv[1]})")
PY
)"
git add -A
# Scope check: every changed file must be inside the role's writable paths (agent file section
# "Writable paths"). This is the hard boundary; prompt and tool permissions are not.
python3 - "$agent" <<'PY' || { git reset -q; exit 1; }
import fnmatch, re, subprocess, sys
text = open(sys.argv[1]).read().split("## Writable paths", 1)[-1].split("\n## ", 1)[0]
allow = re.findall(r"^- `([^`]+)`", text, re.M)
deny = re.findall(r"^- not `([^`]+)`", text, re.M)
files = subprocess.run(["git", "diff", "--cached", "--name-only"], capture_output=True, text=True).stdout.split()
bad = [f for f in files if not any(fnmatch.fnmatch(f, g) for g in allow) or any(fnmatch.fnmatch(f, g) for g in deny)]
if bad:
    print("SCOPE_RESULT: FAIL outside writable paths: " + " ".join(bad))
    sys.exit(1)
print(f"SCOPE_RESULT: PASS files={len(files)}")
PY
git commit -m "$message" --trailer "Model: $model_name" --trailer "Role: $role" --trailer "Task: $task"
