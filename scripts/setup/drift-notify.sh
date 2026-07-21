#!/usr/bin/env bash
# Run weekly by com.vladsuciu.dotfiles-drift.plist: execute the status probes
# (status.sh --check) and raise a macOS notification when anything drifted.
# Always exits 0 — a notification is the alert; launchd shouldn't see failure.
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"

if out=$(bash "$SETUP_DIR/status.sh" --check 2>&1); then
  echo "no drift ($(date))"
  exit 0
fi

echo "drift detected ($(date)):"
printf '%s\n' "$out"

count=$(printf '%s\n' "$out" | grep -c .)
first=$(printf '%s' "$out" | head -1)
body="$first"
[ "$count" -gt 1 ] && body="$body (+$((count - 1)) more)"
body="${body//\"/\\\"}"

osascript -e "display notification \"$body\" with title \"dotfiles drift\" subtitle \"run: make -C ~/dotfiles/scripts status\"" 2>/dev/null || true
exit 0
