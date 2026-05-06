#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

PLIST="$HOME/Library/LaunchAgents/com.vladsuciu.keyremap.plist"
LABEL="com.vladsuciu.keyremap"

if [ ! -L "$PLIST" ] && [ ! -f "$PLIST" ]; then
  echo "✗ $PLIST missing — run 'stow -R -t ~ launchagents' first" >&2
  emit_result "agents" "fail" "plist not found at $PLIST"
  exit 1
fi

# bootout fails ("not loaded") on first run; ignore. Then bootstrap fresh.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

emit_result "agents" "ok" "loaded $LABEL"
