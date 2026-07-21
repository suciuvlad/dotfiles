#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Link skills from the central store (~/.agents/skills, stowed from
# dotfiles/agents/.agents) into non-stowed agent dirs. Claude gets its
# symlinks via the stowed claude package; cursor/codex are full of runtime
# state, so only their skills/ entries are managed here.
#
# Entries support globs, expanded against the store (e.g. "seo*").
STORE="$HOME/.agents/skills"

CURSOR_SKILLS=(emil-design-eng web-animation-design)
CODEX_SKILLS=(emil-design-eng web-animation-design)

if [ ! -d "$STORE" ]; then
  echo "✗ $STORE missing — run 'stow -R -t ~ agents' first" >&2
  emit_result "agent-skills" "fail" "store not found at $STORE"
  exit 1
fi

linked=0 pruned=0
link_agent() {
  local agent_dir="$1"; shift
  [ -d "$agent_dir" ] || { echo "· $agent_dir not present — skipping"; return 0; }
  mkdir -p "$agent_dir/skills"

  local pattern name
  for pattern in "$@"; do
    for skill in "$STORE"/$pattern; do
      [ -d "$skill" ] || continue
      name="$(basename "$skill")"
      ln -sfn "$STORE/$name" "$agent_dir/skills/$name"
      linked=$((linked + 1))
    done
  done

  # Prune links of ours that no longer resolve (skill removed from store)
  local link
  for link in "$agent_dir"/skills/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
      "$STORE"/*) [ -e "$link" ] || { rm "$link"; pruned=$((pruned + 1)); } ;;
    esac
  done
}

link_agent "$HOME/.cursor" "${CURSOR_SKILLS[@]}"
link_agent "$HOME/.codex" "${CODEX_SKILLS[@]}"

echo "✓ agent skills: $linked linked, $pruned pruned"
emit_result "agent-skills" "ok" "$linked linked, $pruned pruned"
