#!/usr/bin/env python3
"""Generate llm/wiki/codemap/<module>.md cards from RTL.

The "Interface" section between the generated markers is rewritten on every run (ports,
parameters, instantiated modules, requirement IDs from the file header). The "Purpose" and
"Notes" sections belong to the LLM/human and are preserved. Cards of deleted modules are
reported (not deleted). The codemap list in llm/wiki/index.md is regenerated.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CODEMAP = ROOT / "llm/wiki/codemap"
BEGIN, END = "<!-- generated:begin -->", "<!-- generated:end -->"
KEYWORDS = {"if", "else", "for", "while", "case", "begin", "end", "assign", "always", "always_ff",
            "always_comb", "always_latch", "module", "function", "task", "return", "initial",
            "generate", "endgenerate", "localparam", "parameter", "logic", "wire", "reg", "input",
            "output", "inout", "typedef", "struct", "enum", "int", "integer", "genvar", "unique",
            "priority", "assert", "property", "import", "foreach", "repeat", "forever", "default"}


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def balanced(text: str, start: int) -> tuple:
    """text[start] == '('; return (inner, index after closing paren)."""
    depth = 0
    for index in range(start, len(text)):
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return text[start + 1:index], index + 1
    return text[start + 1:], len(text)


def split_top(text: str) -> list:
    parts, depth, current = [], 0, []
    for char in text:
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        if char == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
    if "".join(current).strip():
        parts.append("".join(current))
    return [p.strip() for p in parts if p.strip()]


def parse_module(path: Path) -> list:
    raw = path.read_text(errors="ignore")
    header_requirements = re.search(r"//\s*Requirements\s*:\s*(.*)", raw)
    text = strip_comments(raw)
    modules = []
    for match in re.finditer(r"\bmodule\s+(\w+)", text):
        name, cursor = match.group(1), match.end()
        parameters, ports = [], []
        rest = text[cursor:]
        hash_match = re.match(r"\s*#\s*\(", rest)
        if hash_match:
            inner, consumed = balanced(rest, hash_match.end() - 1)
            for item in split_top(inner):
                item = re.sub(r"^\s*parameter\s+", "", item)
                item_match = re.match(r"(.*?)(\w+)\s*=\s*(.+)$", item, re.S)
                if item_match:
                    parameters.append((item_match.group(2), " ".join(item_match.group(3).split()),
                                       " ".join(item_match.group(1).split())))
            rest = rest[consumed:]
        paren = re.match(r"\s*\(", rest)
        body_start = 0
        if paren:
            inner, consumed = balanced(rest, paren.end() - 1)
            direction = ""
            for item in split_top(inner):
                item = " ".join(item.split())
                dir_match = re.match(r"(input|output|inout)\b\s*(.*)", item)
                if dir_match:
                    direction, item = dir_match.group(1), dir_match.group(2)
                port_match = re.match(r"(.*?)(\w+)\s*$", item)
                if port_match:
                    declaration = port_match.group(1).replace("wire logic", "logic").strip()
                    width = re.search(r"\[[^\]]+\]", declaration)
                    ports.append((port_match.group(2), direction, width.group(0) if width else "1"))
            body_start = consumed
        body_end = rest.find("endmodule", body_start)
        body = rest[body_start:body_end if body_end >= 0 else len(rest)]
        instances = sorted({m.group(1) for m in re.finditer(r"^\s*(\w+)\s*(?:#\s*\(|\s\w+\s*\()", body, re.M)
                            if m.group(1) not in KEYWORDS})
        modules.append({"name": name, "file": path.relative_to(ROOT).as_posix(), "parameters": parameters,
                        "ports": ports, "instances": instances,
                        "requirements": header_requirements.group(1).strip() if header_requirements else "-"})
    return modules


def generated_section(module: dict) -> str:
    lines = [BEGIN, "## Interface (generated - do not edit)", "",
             f"- File: `{module['file']}`", f"- Requirements: {module['requirements']}",
             f"- Instantiates: {', '.join(module['instances']) or '-'}", ""]
    if module["parameters"]:
        lines += ["| Parameter | Default | Type |", "|---|---|---|"]
        lines += [f"| `{n}` | `{d}` | {t or '-'} |" for n, d, t in module["parameters"]] + [""]
    if module["ports"]:
        lines += ["| Port | Dir | Width |", "|---|---|---|"]
        lines += [f"| `{n}` | {d} | `{w}` |" for n, d, w in module["ports"]] + [""]
    lines.append(END)
    return "\n".join(lines)


def write_card(module: dict) -> bool:
    card = CODEMAP / f"{module['name']}.md"
    section = generated_section(module)
    if card.exists():
        text = card.read_text()
        if BEGIN in text and END in text:
            new = text[:text.index(BEGIN)] + section + text[text.index(END) + len(END):]
        else:
            new = text.rstrip() + "\n\n" + section + "\n"
    else:
        new = (f"---\ntitle: {module['name']}\ntype: codemap\nstatus: generated\n---\n\n"
               f"# {module['name']}\n\n## Purpose\n<!-- one paragraph, written by the wiki maintainer -->\n\n"
               f"{section}\n\n## Notes\n<!-- pitfalls, design decisions (DR-nnn), related pages -->\n")
    if card.exists() and card.read_text() == new:
        return False
    card.write_text(new)
    return True


def update_index(names: list) -> None:
    index = ROOT / "llm/wiki/index.md"
    if not index.exists():
        return
    text = index.read_text()
    begin, end = "<!-- codemap:begin -->", "<!-- codemap:end -->"
    listing = "\n".join(f"- [{n}](codemap/{n}.md)" for n in names) or "- (none yet)"
    if begin in text and end in text:
        text = text[:text.index(begin) + len(begin)] + "\n" + listing + "\n" + text[text.index(end):]
        index.write_text(text)


def main() -> int:
    CODEMAP.mkdir(parents=True, exist_ok=True)
    modules = []
    for source in sorted((ROOT / "hw/rtl").rglob("*.sv")) + sorted((ROOT / "hw/rtl").rglob("*.v")):
        modules += parse_module(source)
    changed = [m["name"] for m in modules if write_card(m)]
    names = sorted(m["name"] for m in modules)
    stale = sorted(p.stem for p in CODEMAP.glob("*.md") if p.stem not in names)
    update_index(names)
    for name in stale:
        print(f"[WARN] codemap card without module: {name}.md")
    print(f"CODEMAP_RESULT: PASS modules={len(modules)} updated={len(changed)} stale={len(stale)}")
    if changed:
        print("Updated cards (fill Purpose/Notes if new): " + ", ".join(changed))
    return 0


if __name__ == "__main__":
    sys.exit(main())
