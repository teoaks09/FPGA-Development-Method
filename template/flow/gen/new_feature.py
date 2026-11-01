#!/usr/bin/env python3
"""Create the canonical folders and files of a new feature.

  python3 flow/gen/new_feature.py <feature> [--difficulty simple|medium|hard] [--clock-mhz N]

Creates (never overwrites): hw/rtl/<f>/files.f, hw/tb/<f>/files.f, docs/output/specs/<f>.md,
hw/tb/acceptance/<f>/files.f (team L3), and a row in docs/output/architecture.md (if present).
RTL and testbench sources are written by their roles, not by this script.
"""
import argparse
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def create(path: Path, text: str, created: list) -> None:
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    created.append(path.relative_to(ROOT).as_posix())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("feature")
    parser.add_argument("--difficulty", default="medium", choices=["simple", "medium", "hard"])
    parser.add_argument("--clock-mhz", type=int)
    args = parser.parse_args()
    feature = args.feature
    if not re.fullmatch(r"[a-z][a-z0-9_]*", feature):
        sys.exit("feature names are lower_snake_case")
    config = tomllib.loads((ROOT / "project.toml").read_text())
    prefix = config["project"]["prefix"]
    clock = args.clock_mhz or config["project"]["default_clock_mhz"]
    created = []

    create(ROOT / f"hw/rtl/{feature}/files.f",
           f"# Design sources of feature '{feature}' (repository-relative, compile order).\n"
           f"hw/rtl/{feature}/{prefix}_{feature}.sv\n", created)
    create(ROOT / f"hw/tb/{feature}/files.f",
           f"# Testbench sources of feature '{feature}'. Top module: tb_{feature}\n"
           f"hw/tb/{feature}/tb_{feature}.sv\n", created)
    if config["profile"]["team"] == "L3":
        create(ROOT / f"hw/tb/acceptance/{feature}/files.f",
               f"# Acceptance testbench of '{feature}' (written by spec-writer, locked for free models).\n",
               created)
    template = ROOT / "docs/output/specs/_template.md"
    if template.exists():
        spec = template.read_text()
        spec = spec.replace("feature: <name>", f"feature: {feature}")
        spec = spec.replace("difficulty: simple | medium | hard", f"difficulty: {args.difficulty}")
        spec = spec.replace("clock_mhz: <target>", f"clock_mhz: {clock}")
        spec = spec.replace("# <Feature> specification", f"# {feature} specification")
        spec = spec.replace("[FEAT-001]", f"[{feature.upper().replace('_', '')[:8]}-001]")
        create(ROOT / f"docs/output/specs/{feature}.md", spec, created)
    architecture = ROOT / "docs/output/architecture.md"
    if architecture.exists() and f"| {feature} |" not in architecture.read_text():
        text = architecture.read_text().replace(
            "| Feature | Folder | Difficulty | Requirements | Notes |\n|---|---|---|---|---|\n",
            "| Feature | Folder | Difficulty | Requirements | Notes |\n|---|---|---|---|---|\n"
            f"| {feature} | hw/rtl/{feature}/ | {args.difficulty} | | |\n")
        architecture.write_text(text)
        created.append("docs/output/architecture.md (row added)")
    for entry in created:
        print(f"created {entry}")
    print(f"Top module name: {prefix}_{feature} · testbench top: tb_{feature}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
