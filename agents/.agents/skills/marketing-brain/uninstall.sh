#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./uninstall.sh --target codex|claude|agents|all [--dest DIR]
USAGE
}

target="codex"
dest_override=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      target="${2:-}"
      shift 2
      ;;
    --dest)
      dest_override="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

remove_one() {
  local name="$1"
  local root="$2"
  local dest="$root/marketing-brain"
  rm -rf "$dest"
  echo "Removed Marketing Brain for $name: $dest"
}

if [[ -n "$dest_override" ]]; then
  case "$target" in
    codex|claude|agents|all) remove_one "$target" "$dest_override" ;;
    *) echo "ERROR: invalid --target: $target" >&2; exit 2 ;;
  esac
  exit 0
fi

case "$target" in
  codex)
    remove_one "codex" "$HOME/.codex/skills"
    ;;
  claude)
    remove_one "claude" "$HOME/.claude/skills"
    ;;
  agents)
    remove_one "agents" "$HOME/.agents/skills"
    ;;
  all)
    remove_one "codex" "$HOME/.codex/skills"
    remove_one "claude" "$HOME/.claude/skills"
    remove_one "agents" "$HOME/.agents/skills"
    ;;
  *)
    echo "ERROR: invalid --target: $target" >&2
    usage >&2
    exit 2
    ;;
esac
