#!/usr/bin/env python3
"""Compare xsim code coverage (xcrg text report) with the target in the feature spec.

Spec line format: "Coverage target: line >= 95 %, branch >= 90 %" (≥ also accepted).
PILOT: the xcrg text report format is parsed heuristically; verify on the first project.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def targets(feature: str) -> dict:
    spec = ROOT / "docs/output/specs" / f"{feature}.md"
    found = {"line": 95.0, "branch": 90.0}
    if spec.exists():
        match = re.search(r"Coverage target:(.*)", spec.read_text())
        if match:
            for kind, value in re.findall(r"(line|branch|statement|condition|toggle)\s*(?:>=|≥)\s*([\d.]+)",
                                          match.group(1)):
                found["line" if kind == "statement" else kind] = float(value)
    return found


def measured(feature: str) -> dict:
    report_dir = ROOT / "build/sim" / feature / "cov_report"
    text = "\n".join(p.read_text(errors="ignore") for p in report_dir.rglob("*.txt")) if report_dir.exists() else ""
    values = {}
    for kind, pattern in {"line": r"statement[^\n]*?([\d.]+)\s*%", "branch": r"branch[^\n]*?([\d.]+)\s*%",
                          "condition": r"condition[^\n]*?([\d.]+)\s*%", "toggle": r"toggle[^\n]*?([\d.]+)\s*%"}.items():
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            values[kind] = float(match.group(1))
    return values


def main() -> int:
    feature = sys.argv[1]
    goal, got = targets(feature), measured(feature)
    if not got:
        print(f"COVERAGE_RESULT: FAIL feature={feature} no coverage report (build/sim/{feature}/cov_report)")
        return 1
    failures = [f"{kind} {got.get(kind, 0):.1f}<{limit}" for kind, limit in goal.items()
                if got.get(kind, 0.0) < limit]
    summary = " ".join(f"{k}={v:.1f}%" for k, v in got.items())
    status = "FAIL" if failures else "PASS"
    print(f"COVERAGE_RESULT: {status} feature={feature} {summary}" + (f" ({', '.join(failures)})" if failures else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
