#!/usr/bin/env python3
"""Requirement <-> test traceability.

Definitions : lines "- [ID] text {by: test|review|analysis}" in docs/input/system_requirements.md
              and docs/output/specs/*.md (templates starting with "_" are skipped).
              "{by: test}" is the default.
Tests       : "// REQ: ID, ID" annotations and tb_check(..., "ID") calls in hw/tb/**/*.sv.
Allocation  : a spec requirement may cite system requirements, e.g. "(SR-003)".
Fails when  : a test-verified requirement has no test, or a test cites an undefined ID.
Reports     : system requirements not cited by any spec (not allocated), as a warning.
Writes      : build/trace/matrix.md
"""
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFINITION = re.compile(r"^\s*-\s*\[([A-Z][A-Z0-9]*-\d{3,})\]\s*(.*)$", re.M)
METHOD = re.compile(r"\{by:\s*(test|review|analysis)\}")
CITATION = re.compile(r"\b([A-Z][A-Z0-9]*-\d{3,})\b")
REQ_COMMENT = re.compile(r"//\s*REQ:\s*([A-Z0-9,\s-]+)")
CHECK_CALL = re.compile(r"tb_check\s*\(.*?\"([A-Z][A-Z0-9]*-\d{3,})\"\s*\)", re.S)


def definitions() -> dict:
    found = {}
    sources = [ROOT / "docs/input/system_requirements.md"]
    sources += [p for p in sorted((ROOT / "docs/output/specs").glob("*.md")) if not p.name.startswith("_")]
    for source in sources:
        if not source.exists():
            continue
        for identifier, text in DEFINITION.findall(source.read_text()):
            method = METHOD.search(text)
            found[identifier] = {"file": source.relative_to(ROOT).as_posix(),
                                 "method": method.group(1) if method else "test",
                                 "cites": [c for c in CITATION.findall(text) if c != identifier]}
    return found


def tests() -> dict:
    found = defaultdict(set)
    for source in sorted((ROOT / "hw/tb").rglob("*.sv")):
        text = source.read_text(errors="ignore")
        location = source.relative_to(ROOT).as_posix()
        for group in REQ_COMMENT.findall(text):
            for identifier in CITATION.findall(group):
                found[identifier].add(location)
        for identifier in CHECK_CALL.findall(text):
            found[identifier].add(location)
    return found


def main() -> int:
    defined, tested = definitions(), tests()
    untested = sorted(i for i, d in defined.items() if d["method"] == "test" and i not in tested
                      and not i.startswith("SR-"))  # SR-* are verified through allocated feature reqs
    undefined = sorted(i for i in tested if i not in defined)
    cited = {c for d in defined.values() for c in d["cites"]}
    unallocated = sorted(i for i in defined if i.startswith("SR-") and i not in cited and i not in tested)

    out = ROOT / "build/trace"
    out.mkdir(parents=True, exist_ok=True)
    rows = ["| Requirement | Method | Defined in | Allocated to | Tests |", "|---|---|---|---|---|"]
    for identifier, data in sorted(defined.items()):
        allocated = sorted(i for i, d in defined.items() if identifier in d["cites"])
        rows.append(f"| {identifier} | {data['method']} | {data['file']} | {', '.join(allocated)} | "
                    f"{', '.join(sorted(tested.get(identifier, [])))} |")
    (out / "matrix.md").write_text("# Traceability matrix (generated)\n\n" + "\n".join(rows) + "\n")

    for identifier in unallocated:
        print(f"[WARN] {identifier} is not allocated to any feature requirement or test")
    for identifier in untested:
        print(f"[FAIL] {identifier} ({defined[identifier]['file']}) has no test")
    for identifier in undefined:
        print(f"[FAIL] {identifier} is used in {', '.join(sorted(tested[identifier]))} but not defined")
    status = "FAIL" if untested or undefined else "PASS"
    print(f"TRACE_RESULT: {status} defined={len(defined)} untested={len(untested)} "
          f"undefined={len(undefined)} unallocated={len(unallocated)}")
    return 1 if status == "FAIL" else 0


if __name__ == "__main__":
    sys.exit(main())
