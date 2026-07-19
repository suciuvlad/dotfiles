from __future__ import annotations

import importlib
import importlib.util
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent

COMMANDS = {
    "new": "scaffold_vault",
    "competitors": "find_competitors",
    "keywords": "pull_competitor_kw",
    "xlsx": "build_keyword_xlsx",
    "paa": "mine_paa_serps",
    "synthesize": "synthesize_beast_plan",
    "report": "render_beast_pdf",
    "next": "guide_next_action",
    "lint": "lint_vault",
    "demo": "build_demo_vault",
    "visuals": "generate_editorial_assets",
}


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if not args or args[0] in {"-h", "--help"}:
        print_help()
        return 0
    command = args.pop(0)
    module_name = COMMANDS.get(command)
    if not module_name:
        print(f"ERROR: unknown marketing-brain command: {command}", file=sys.stderr)
        print_help()
        return 2
    if command == "new" and args and not args[0].startswith("-"):
        args = ["--client", args[0], *args[1:]]
    scripts_dir = resolve_scripts_dir(module_name)
    sys.path.insert(0, str(scripts_dir))
    module = importlib.import_module(module_name)
    return int(module.main(args))


def resolve_scripts_dir(module_name: str) -> Path:
    checkout_scripts = REPO_ROOT / "scripts"
    if (checkout_scripts / f"{module_name}.py").exists():
        return checkout_scripts

    spec = importlib.util.find_spec("scripts")
    if spec and spec.submodule_search_locations:
        for location in spec.submodule_search_locations:
            candidate = Path(location)
            if (candidate / f"{module_name}.py").exists():
                return candidate

    raise ModuleNotFoundError(
        f"Cannot find Marketing Brain script module '{module_name}'. "
        "Run from the source checkout, the installed skill directory, or install the Python package."
    )


def print_help() -> None:
    print(
        """marketing-brain commands:
  marketing-brain new <client-slug> --site <url> --business-type <type> --owner <name> --niche <text>
  marketing-brain competitors --vault <path> --site <url> [--seed-keywords <csv> --dry-run]
  marketing-brain keywords --vault <path> [--dry-run]
  marketing-brain xlsx --vault <path>
  marketing-brain paa --vault <path> [--dry-run]
  marketing-brain synthesize --vault <path>
  marketing-brain report --vault <path> [--html-only]
  marketing-brain next --vault <path>
  marketing-brain lint --vault <path> [--template]
  marketing-brain demo
"""
    )


if __name__ == "__main__":
    raise SystemExit(main())
