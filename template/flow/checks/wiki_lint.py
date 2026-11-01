#!/usr/bin/env python3
"""Mechanical wiki checks: frontmatter, index completeness, broken links, stale code references."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WIKI = ROOT / "llm/wiki"
SPECIAL = {"index.md", "log.md", "SCHEMA.md"}


def main() -> int:
    if not WIKI.exists():
        print("WIKI_RESULT: PASS (no wiki in this profile)")
        return 0
    problems, warnings = [], []
    index_text = (WIKI / "index.md").read_text() if (WIKI / "index.md").exists() else ""
    pages = [p for p in WIKI.rglob("*.md") if p.name not in SPECIAL]
    for page in pages:
        relative = page.relative_to(WIKI).as_posix()
        text = page.read_text()
        if not text.startswith("---"):
            problems.append(f"{relative}: missing frontmatter")
        elif "status:" not in text.split("---")[1]:
            problems.append(f"{relative}: frontmatter has no status")
        if f"({relative})" not in index_text:
            problems.append(f"{relative}: not listed in index.md")
        for link in re.findall(r"\]\(([^)#\s]+\.md)", text):
            if not (page.parent / link).resolve().exists():
                problems.append(f"{relative}: broken link {link}")
        for code_path in re.findall(r"`((?:hw|sw|flow)/[^`\s]+)`", text):
            if not (ROOT / code_path).exists() and "*" not in code_path and "<" not in code_path:
                warnings.append(f"{relative}: refers to missing {code_path}")
        if "status: unverified" in text:
            warnings.append(f"{relative}: unverified")
    for link in re.findall(r"\]\(([^)#\s]+\.md)\)", index_text):
        if not (WIKI / link).exists():
            problems.append(f"index.md: broken link {link}")
    for entry in warnings:
        print(f"[WARN] {entry}")
    for entry in problems:
        print(f"[FAIL] {entry}")
    status = "FAIL" if problems else "PASS"
    print(f"WIKI_RESULT: {status} pages={len(pages)} problems={len(problems)} warnings={len(warnings)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
