#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Load every LaunchAgent the repo defines (stowed into ~/Library/LaunchAgents).
# The repo dir is the source of truth — same as the status.sh probe.
DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPO_AGENTS="$DOTFILES_DIR/launchagents/Library/LaunchAgents"

# launchd won't scan a symlinked ~/Library/LaunchAgents at login — stow folds
# the dir on fresh Macs where it doesn't pre-exist. Heal: swap the folded
# symlink for a real dir with per-file links.
if [ -L "$HOME/Library/LaunchAgents" ]; then
  echo "→ ~/Library/LaunchAgents is a stow-folded symlink (launchd skips it at login) — unfolding"
  unlink "$HOME/Library/LaunchAgents"
  mkdir "$HOME/Library/LaunchAgents"
  stow -R -t "$HOME" -d "$DOTFILES_DIR" launchagents
fi

loaded=0
missing=()
for src in "$REPO_AGENTS"/*.plist; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  label="${name%.plist}"
  plist="$HOME/Library/LaunchAgents/$name"

  if [ ! -L "$plist" ] && [ ! -f "$plist" ]; then
    missing+=("$name")
    continue
  fi

  # bootout fails ("not loaded") on first run; ignore. Then bootstrap fresh.
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist"
  loaded=$((loaded + 1))

  # keyremap must take effect immediately; calendar-based agents wait their turn.
  case "$label" in
    *keyremap*) launchctl kickstart -k "gui/$(id -u)/$label" ;;
  esac
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "✗ not stowed into ~/Library/LaunchAgents: ${missing[*]} — run 'stow -R -t ~ launchagents' first" >&2
  emit_result "agents" "fail" "${#missing[@]} plist(s) not stowed" "${missing[@]}"
  exit 1
fi

echo "✓ loaded $loaded LaunchAgent(s)"
emit_result "agents" "ok" "loaded $loaded plist(s)"
