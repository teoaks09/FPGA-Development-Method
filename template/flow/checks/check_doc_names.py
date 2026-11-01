#!/usr/bin/env python3
"""Every `identifier` in backticks in the human docs must exist in RTL or software sources.

Docs   : docs/output/ip_user_guide.md, docs/output/hardware_test_procedure.md, docs/output/knowledge/*.md
Names  : backticked words that look like identifiers (contain "_" or an upper-case letter or a digit).
Ignore : <!-- doc-check-ignore: word word --> anywhere in a doc.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IDENTIFIER = re.compile(r"`([A-Za-z_][A-Za-z0-9_]*)(?:\[[^`]*\])?`")


def known_names() -> set:
    names = set()
    for pattern in ("hw/rtl/**/*.sv", "hw/rtl/**/*.v", "sw/**/*.[ch]", "hw/boards/**/*.sv"):
        for source in ROOT.glob(pattern):
            names |= set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", source.read_text(errors="ignore")))
    return names


def main() -> int:
    docs = [ROOT / "docs/output/ip_user_guide.md", ROOT / "docs/output/hardware_test_procedure.md"]
    docs += sorted((ROOT / "docs/output/knowledge").glob("*.md"))
    names = known_names()
    missing = []
    for doc in docs:
        if not doc.exists():
            continue
        text = doc.read_text()
        ignored = set(" ".join(re.findall(r"doc-check-ignore:([^>]*)-->", text)).split())
        for name in sorted(set(IDENTIFIER.findall(text))):
            looks_like_signal = "_" in name or any(c.isupper() for c in name) or any(c.isdigit() for c in name)
            if looks_like_signal and name not in names and name not in ignored:
                missing.append(f"{doc.relative_to(ROOT).as_posix()}: `{name}`")
    for entry in missing:
        print(f"[FAIL] not found in sources: {entry}")
    status = "FAIL" if missing else "PASS"
    print(f"DOCNAMES_RESULT: {status} missing={len(missing)}")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
