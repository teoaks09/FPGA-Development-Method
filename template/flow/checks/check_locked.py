#!/usr/bin/env python3
"""Fail if locked paths changed on this branch compared with the base branch.

Locked paths: project.toml [locks].paths (add paths there to freeze delivered work) and
hw/tb/acceptance/** for team L3. On the base branch nothing is checked (the user merges
approved changes there).
"""
import fnmatch
import subprocess
import sys
try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11: pip install tomli
    import tomli as tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def git(*args: str) -> str:
    result = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else ""


def locked_patterns(config: dict) -> list:
    patterns = list(config.get("locks", {}).get("paths", []))
    if config["profile"]["team"] == "L3":
        patterns.append("hw/tb/acceptance/**")
    return patterns


def main() -> int:
    config = tomllib.loads((ROOT / "project.toml").read_text())
    base = config.get("locks", {}).get("base_ref", "main")
    branch = git("rev-parse", "--abbrev-ref", "HEAD").strip()
    if not branch:
        print("LOCKS_RESULT: PASS (not a git repository)")
        return 0
    if branch == base:
        print(f"LOCKS_RESULT: PASS (on {base}; nothing to compare)")
        return 0
    changed = set()
    if git("rev-parse", "--verify", "--quiet", base):
        changed |= set(git("diff", "--name-only", f"{base}...HEAD").split())
    changed |= {line[3:] for line in git("status", "--porcelain").splitlines() if line}
    patterns = locked_patterns(config)
    violations = sorted(path for path in changed
                        if any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(path, p.rstrip("*") + "*")
                               for p in patterns))
    if violations:
        print(f"LOCKS_RESULT: FAIL {len(violations)} locked file(s) changed: {' '.join(violations)}")
        return 1
    print(f"LOCKS_RESULT: PASS ({len(patterns)} locked patterns, {len(changed)} changed files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
