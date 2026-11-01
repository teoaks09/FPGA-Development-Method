#!/usr/bin/env python3
"""Print one value from project.toml, e.g. `project_value.py profile.team`."""
import sys
try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11: pip install tomli
    import tomli as tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load() -> dict:
    with open(ROOT / "project.toml", "rb") as handle:
        return tomllib.load(handle)


def get(dotted: str):
    value = load()
    for part in dotted.split("."):
        value = value[part]
    return value


def feature_clock(feature: str):
    """Target clock of a feature: spec frontmatter clock_mhz, else project default."""
    spec = ROOT / "docs/specs" / f"{feature}.md"
    if feature and spec.exists():
        for line in spec.read_text().splitlines()[:12]:
            if line.startswith("clock_mhz:") and line.split(":", 1)[1].strip().replace(".", "").isdigit():
                return line.split(":", 1)[1].strip()
    return get("project.default_clock_mhz")


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--feature-clock":
        print(feature_clock(sys.argv[2]))
        sys.exit(0)
    if len(sys.argv) != 2:
        sys.exit("usage: project_value.py <section.key> | --feature-clock <feature>")
    value = get(sys.argv[1])
    print(" ".join(value) if isinstance(value, list) else value)
