#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./install.sh --target codex|claude|agents|all [--dest DIR]

Installs Marketing Brain by copying this checkout into the selected local skill
directory. Use --dest to override the computed target root for tests.
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

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_one() {
  local name="$1"
  local root="$2"
  local dest="$root/marketing-brain"
  mkdir -p "$root"
  rm -rf "$dest"
  mkdir -p "$dest"
  tar \
    --exclude='.git' \
    --exclude='dist' \
    --exclude='__pycache__' \
    --exclude='.pytest_cache' \
    --exclude='.mypy_cache' \
    --exclude='.ruff_cache' \
    -C "$repo_dir" -cf - . | tar -C "$dest" -xf -
  echo "Installed Marketing Brain for $name: $dest"
}

if [[ -n "$dest_override" ]]; then
  case "$target" in
    codex|claude|agents|all) install_one "$target" "$dest_override" ;;
    *) echo "ERROR: invalid --target: $target" >&2; exit 2 ;;
  esac
  exit 0
fi

case "$target" in
  codex)
    install_one "codex" "$HOME/.codex/skills"
    ;;
  claude)
    install_one "claude" "$HOME/.claude/skills"
    ;;
  agents)
    install_one "agents" "$HOME/.agents/skills"
    ;;
  all)
    install_one "codex" "$HOME/.codex/skills"
    install_one "claude" "$HOME/.claude/skills"
    install_one "agents" "$HOME/.agents/skills"
    ;;
  *)
    echo "ERROR: invalid --target: $target" >&2
    usage >&2
    exit 2
    ;;
esac
