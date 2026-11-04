#!/usr/bin/env python3
"""Create or extend an FPGA project from the fpga-method kit.

A project = the canonical tree (manifest.toml) filtered by its profile:
  team          L1 | L2 | L3 | L4          who does the work (cost level)
  deliverables  code (always) + ip, board, hwtest, sw
  options       wiki, xilinx_ip, hls

Examples
  new_project.py --name uart_lite --dest ~/work/uart_lite --team L1 --deliver ip \
      --prefix ul --part xc7a35ticsg324-1L --clock-mhz 100 --features uart:simple --git
  new_project.py --name eth --dest ~/work/eth --team L2 --deliver ip,board,hwtest,sw \
      --with wiki,xilinx_ip --board zcu102 --prefix es --part xczu9eg-ffvb1156-2-e --clock-mhz 322 \
      --features arp,udp,tcp:hard --git
  new_project.py --existing --dest ~/work/uart_lite --team L2 --with wiki ...   (change/grow a profile)

--existing never overwrites project content. It regenerates the kit-owned files (AGENTS.md,
CLAUDE.md, Makefile - keeping their project:begin/end block) and all agent files, removes agent
files of roles that moved to the other tool, and adds missing paths.
"""
import argparse
import datetime
import os
import re
import subprocess
import sys
try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11: pip install tomli
    import tomli as tomllib
from pathlib import Path

KIT = Path(__file__).resolve().parents[1]
TEMPLATE = KIT / "template"
TEAMS = ["L1", "L2", "L3", "L4"]
DELIVERABLES = ["code", "ip", "board", "hwtest", "sw"]
OPTIONS = ["wiki", "xilinx_ip", "hls"]
CLAUDE_MODELS = {"opus", "sonnet", "haiku"}
REGENERATED = {"AGENTS.md", "CLAUDE.md", "Makefile"}
MARKER = re.compile(r"^\s*(?:<!--|#)\s*@(if|end)\b\s*(.*?)\s*(?:-->)?\s*$")
PLACEHOLDER = re.compile(r"\{\{([A-Z_]+)\}\}")
PROJECT_BLOCK = re.compile(r"^[^\n]*project:begin[^\n]*\n.*?^[^\n]*project:end[^\n]*$", re.M | re.S)


def condition_holds(clause: str, ctx: dict) -> bool:
    for alternative in clause.split("|"):
        key, _, values = alternative.partition("=")
        wanted = {v.strip() for v in values.split(",")}
        have = ctx[key.strip()]
        if (wanted & have) if isinstance(have, set) else (have in wanted):
            return True
    return False


def selected(entry: dict, ctx: dict) -> bool:
    return all(condition_holds(clause, ctx) for clause in entry.get("when", []))


def render(text: str, ctx: dict, values: dict, source: str) -> str:
    output, stack = [], []
    for number, line in enumerate(text.splitlines(keepends=True), 1):
        marker = MARKER.match(line)
        if marker and marker.group(1) == "if":
            stack.append(condition_holds(marker.group(2), ctx))
        elif marker:
            if not stack:
                sys.exit(f"{source}:{number}: @end without @if")
            stack.pop()
        elif all(stack):
            output.append(line)
    if stack:
        sys.exit(f"{source}: unterminated @if")
    text = "".join(output)
    missing = sorted({m for m in PLACEHOLDER.findall(text) if m not in values})
    if missing:
        sys.exit(f"{source}: no value for {', '.join(missing)}")
    return PLACEHOLDER.sub(lambda m: str(values[m.group(1)]), text)


def load_manifest() -> list:
    entries = tomllib.loads((KIT / "manifest.toml").read_text())["path"]
    covered = set()
    for entry in entries:
        source = TEMPLATE / entry["path"]
        if not source.exists():
            sys.exit(f"manifest entry without template: {entry['path']}")
        covered |= {p for p in source.rglob("*") if p.is_file()} if source.is_dir() else {source}
    uncovered = sorted(p.relative_to(TEMPLATE).as_posix() for p in TEMPLATE.rglob("*")
                       if p.is_file() and p not in covered)
    if uncovered:
        sys.exit("template files not covered by manifest.toml:\n  " + "\n  ".join(uncovered))
    return entries


def target_name(relative: str, values: dict) -> str:
    return relative.replace("__BOARD__", values["BOARD"]).replace("{{PREFIX}}", values["PREFIX"])


def copy_entry(entry: dict, ctx: dict, values: dict, dest: Path, existing: bool, log: list) -> None:
    source = TEMPLATE / entry["path"]
    if source.is_dir():
        for folder in [source] + [d for d in source.rglob("*") if d.is_dir()]:
            if not any(p.is_file() for p in folder.iterdir()) and not any(p.is_dir() for p in folder.iterdir()):
                keep = dest / target_name(folder.relative_to(TEMPLATE).as_posix(), values) / ".gitkeep"
                keep.parent.mkdir(parents=True, exist_ok=True)
                keep.touch()
        files = [p for p in source.rglob("*") if p.is_file()]
    else:
        files = [source]
    for file in files:
        relative = file.relative_to(TEMPLATE).as_posix()
        target = dest / target_name(relative, values)
        text = render(file.read_text(), ctx, values, relative)
        if target.exists() and existing:
            if relative not in REGENERATED:
                log.append(f"kept     {target.relative_to(dest)}")
                continue
            old = PROJECT_BLOCK.search(target.read_text())
            if old:
                text = PROJECT_BLOCK.sub(lambda _: old.group(0), text, count=1)
            log.append(f"updated  {target.relative_to(dest)} (project block kept)")
        else:
            log.append(f"created  {target.relative_to(dest)}")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
        if os.access(file, os.X_OK):
            target.chmod(0o755)


def opencode_frontmatter(spec: dict, model_id: str, role: str) -> list:
    lines = ["---", f"description: {spec['description']}", "mode: primary", f"model: {model_id}",
             f"steps: {80 if role in ('rtl-designer', 'verification') else 40}"]
    lines += ["permission:", "  edit:", '    "*": deny']
    lines += [f'    "{p}": allow' for p in spec["writable"] if not p.startswith("!")]
    lines += [f'    "{p[1:]}": deny' for p in spec["writable"] if p.startswith("!")]
    lines += ['    "docs/requirements.md": deny', '    "docs/coding_rules.md": deny']
    lines += ["  bash:", '    "*": ask', '    "make *": allow', '    "python3 flow/*": allow',
              '    "flow/*": allow', '    "git status*": allow', '    "git diff*": allow',
              '    "git add*": allow', '    "git commit*": deny', '    "git checkout*": allow',
              '    "git switch*": allow', '    "git push*": deny', "  webfetch: deny", "---", ""]
    return lines


def run_model(model_id: str, model_key: str, effort: str, variants: dict) -> str:
    """opencode -m value: provider/model#variant (variant from kit_config [models.variants])."""
    variant = variants.get(model_key, {}).get(effort, "")
    return f"{model_id}#{variant}" if variant else model_id


def render_agents(ctx: dict, models: dict, names: dict, variants: dict, dest: Path, log: list) -> list:
    roles = tomllib.loads((KIT / "agents/roles.toml").read_text())
    team, rows, wanted = ctx["team"], [], set()
    for role, spec in roles.items():
        if spec.get("option") and spec["option"] not in ctx["option"]:
            continue
        model_key, effort = spec["model"][team], spec["effort"][team]
        if model_key == "none":
            continue
        body = (KIT / "agents/roles" / f"{role}.md").read_text().rstrip() + "\n"
        body += "\n## Writable paths\n" + "\n".join(
            f"- not `{p[1:]}`" if p.startswith("!") else f"- `{p}`" for p in spec["writable"]) + "\n"
        if spec.get("cannot_read"):
            body += "\n## Do not read\n" + "\n".join(f"- `{p}`" for p in spec["cannot_read"]) + "\n"
        if model_key in CLAUDE_MODELS:
            path, tool = dest / ".claude/agents" / f"{role}.md", "Claude Code"
            front = ["---", f"name: {role}", f"description: {spec['description']}", f"model: {models[model_key]}"]
            front += [f"effort: {effort}"] if effort != "default" else []
            text = "\n".join(front + ["---", ""]) + body + (
                "\nStay inside the writable paths (not enforced for Claude subagents; "
                "`make check-locks` and the reviewer check).\n")
        else:
            path, tool = dest / ".opencode/agents" / f"{role}.md", "opencode"
            text = "\n".join(opencode_frontmatter(spec, models[model_key], role)) + body
            effort = f"`-m {run_model(models[model_key], model_key, effort, variants)}`"
        state = "updated " if path.exists() else "created "
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        log.append(f"{state} {path.relative_to(dest)}")
        wanted.add(path)
        rows.append((role, tool, names.get(model_key, model_key), effort, spec["description"]))
    for folder in (dest / ".claude/agents", dest / ".opencode/agents"):
        for stale in sorted(folder.glob("*.md")) if folder.exists() else []:
            if stale not in wanted:
                stale.unlink()
                log.append(f"removed  {stale.relative_to(dest)} (role not on this tool for {team})")
    if team != "L4":
        rows.insert(0, ("(main session)", "Claude Code", names["opus"], "high",
                        "Talks to the user, architecture, dispatch, accepts derived requirements"))
    return rows


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--name", required=True)
    parser.add_argument("--dest", type=Path)
    parser.add_argument("--summary", default="<one paragraph: what this project builds>")
    parser.add_argument("--team", choices=TEAMS, required=True)
    parser.add_argument("--deliver", default="", help="comma list: ip,board,hwtest,sw (code is implied)")
    parser.add_argument("--with", dest="options", default="", help="comma list: wiki,xilinx_ip,hls")
    parser.add_argument("--prefix", required=True)
    parser.add_argument("--part", required=True)
    parser.add_argument("--clock-mhz", type=int, default=100)
    parser.add_argument("--board", default="")
    parser.add_argument("--features", default="", help="comma list name[:simple|medium|hard]")
    parser.add_argument("--dispatch", choices=["manual", "auto"])
    parser.add_argument("--kit-config", type=Path, default=KIT / "kit_config.toml",
                        help="machine settings (copy of kit_config.example.toml)")
    parser.add_argument("--existing", action="store_true")
    parser.add_argument("--git", action="store_true", help="git init + first commit (new project)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    args.dest = (args.dest or Path.cwd() / args.name).expanduser().resolve()
    return args


def main() -> int:
    args = parse_args()
    if not args.kit_config.exists():
        sys.exit(f"{args.kit_config} missing: cp {KIT / 'kit_config.example.toml'} {args.kit_config} and edit it")
    kit = tomllib.loads(args.kit_config.read_text())
    deliverables = {"code"} | {d.strip() for d in args.deliver.split(",") if d.strip()}
    options = {o.strip() for o in args.options.split(",") if o.strip()}
    for item, allowed in ((deliverables, DELIVERABLES), (options, OPTIONS)):
        if item - set(allowed):
            sys.exit(f"unknown: {', '.join(sorted(item - set(allowed)))}")
    if "board" in deliverables and not args.board:
        sys.exit("--board is required for deliverable board")
    ctx = {"team": args.team, "deliverable": deliverables, "option": options}

    models_cfg = kit["models"]
    models = {k: v for k, v in models_cfg.items() if isinstance(v, str)}
    names, variants = models_cfg["names"], models_cfg.get("variants", {})
    ordered = [d for d in DELIVERABLES if d in deliverables]
    profile = f"{args.team} × {{{', '.join(ordered)}}}" + (f" + {', '.join(sorted(options))}" if options else "")
    version = (KIT / "VERSION").read_text().strip()
    values = {
        "PROJECT": args.name, "SUMMARY": args.summary, "PROFILE_LINE": profile, "TEAM": args.team,
        "DELIVERABLES_TOML": ", ".join(f'"{d}"' for d in ordered),
        "OPTIONS_TOML": ", ".join(f'"{o}"' for o in sorted(options)),
        "KIT_VERSION": version, "DATE": datetime.date.today().isoformat(),
        "DISPATCH": args.dispatch or kit["defaults"]["dispatch"], "MAX_ATTEMPTS": kit["defaults"]["max_attempts"],
        "WIKI_HINT": "; compiled knowledge is in llm/wiki/ (index.md first)" if "wiki" in options else "",
        "PART": args.part, "PREFIX": args.prefix, "CLOCK_MHZ": args.clock_mhz, "BOARD": args.board or "board",
        "IP_VENDOR": kit["organisation"]["ip_vendor"],
        "MODELS_TOML": "[models.ids]\n" + "\n".join(f'{k} = "{v}"' for k, v in models.items())
                       + "\n\n[models.names]\n" + "\n".join(f'{k} = "{v}"' for k, v in names.items()),
        "LOCKS_TOML": '"docs/requirements.md", "docs/coding_rules.md"',
        "WHERE_TABLE": "{{WHERE_TABLE}}", "ROLE_TABLE": "{{ROLE_TABLE}}",
    }
    entries = load_manifest()
    chosen = [e for e in entries if selected(e, ctx)]
    if args.dry_run:
        print(f"profile: {profile}")
        print("\n".join("  " + target_name(e["path"], values) for e in chosen))
        return 0
    if args.dest.exists() and any(args.dest.iterdir()) and not args.existing:
        sys.exit(f"{args.dest} is not empty (use --existing)")
    args.dest.mkdir(parents=True, exist_ok=True)

    log = []
    for entry in chosen:
        copy_entry(entry, ctx, values, args.dest, args.existing, log)
    rows = render_agents(ctx, models, names, variants, args.dest, log)

    where = ["| Path | Content |", "|---|---|"] + [
        f"| `{e.get('show', e['path']).replace('__BOARD__', '<board>')}` | {e['where']} |"
        for e in entries if "where" in e and selected(e, ctx)]
    role_table = ["| Role | Tool | Model | Effort / opencode -m | Task |", "|---|---|---|---|---|"] + [
        f"| {r} | {t} | {m} | {e} | {d} |" for r, t, m, e, d in rows]
    agents = args.dest / "AGENTS.md"
    agents.write_text(agents.read_text().replace("{{WHERE_TABLE}}", "\n".join(where))
                      .replace("{{ROLE_TABLE}}", "\n".join(role_table)))
    if args.existing:
        project = args.dest / "project.toml"
        text = project.read_text()
        text = re.sub(r'^team = "[^"]*"', f'team = "{args.team}"', text, flags=re.M)
        text = re.sub(r"^deliverables = \[.*\]", f"deliverables = [{values['DELIVERABLES_TOML']}]", text, flags=re.M)
        text = re.sub(r"^options = \[.*\]", f"options = [{values['OPTIONS_TOML']}]", text, flags=re.M)
        project.write_text(text)

    for feature in [f.strip() for f in args.features.split(",") if f.strip()]:
        name, _, difficulty = feature.partition(":")
        result = subprocess.run([sys.executable, "flow/gen/new_feature.py", name, "--difficulty",
                                 difficulty or "medium"], cwd=args.dest, capture_output=True, text=True)
        if result.returncode:
            sys.exit(result.stderr)
        log += [f"feature  {line}" for line in result.stdout.splitlines()]

    leftovers = [p.relative_to(args.dest).as_posix() for p in args.dest.rglob("*")
                 if p.is_file() and ".git" not in p.parts and PLACEHOLDER.search(p.read_text(errors="ignore"))]
    if leftovers:
        print("WARNING: unresolved placeholders in " + ", ".join(leftovers))
    if args.git and not (args.dest / ".git").exists():
        subprocess.run(["git", "init", "-q", "-b", "main"], cwd=args.dest, check=True)
        subprocess.run(["git", "add", "-A"], cwd=args.dest, check=True)
        subprocess.run(["git", "commit", "-q", "-m", f"Project setup from fpga-method {version}",
                        "-m", f"Profile: {profile}"], cwd=args.dest, check=True)

    for line in log:
        if not line.startswith("created"):
            print(line)
    created = sum(line.startswith("created") for line in log)
    print(f"profile: {profile}")
    print(f"NEW_PROJECT_RESULT: PASS dest={args.dest} created={created}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
