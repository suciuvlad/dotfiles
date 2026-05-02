#!/usr/bin/env bash
# Best-effort installer for Brewfile.optional.
# Failures are collected and summarized at the end; this script always exits 0
# so an outer 'make brew' that already ran the strict Brewfile doesn't abort.
#
# Usage: brew-optional.sh <path-to-Brewfile.optional>
set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -r "$FILE" ]; then
  echo "brew-optional: cannot read '$FILE'" >&2
  exit 1
fi

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

LOG="${DOTFILES_BREW_LOG:-/tmp/dotfiles-brew-optional.log}"
: > "$LOG"

ok=0
total=0
failed=()

run() {  # run <label> <cmd...>
  local label="$1"; shift
  local out
  total=$((total + 1))
  if out=$("$@" </dev/null 2>&1); then
    ok=$((ok + 1))
    printf "  ✓ %s\n" "$label"
  else
    local err
    err=$(printf '%s\n' "$out" | grep -E '^(Error|error)' | head -1)
    [ -z "$err" ] && err=$(printf '%s\n' "$out" | head -1)
    failed+=("$label — $err")
    printf "  ✗ %s\n" "$label"
  fi
  {
    printf '\n=== %s ===\n' "$label"
    printf '%s\n' "$out"
  } >> "$LOG"
}

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"                               # strip trailing comment
  line="${line#"${line%%[![:space:]]*}"}"          # ltrim
  line="${line%"${line##*[![:space:]]}"}"          # rtrim
  [ -z "$line" ] && continue

  if [[ "$line" =~ ^tap[[:space:]]+\"([^\"]+)\" ]]; then
    name="${BASH_REMATCH[1]}"
    run "tap $name" brew tap "$name"
  elif [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
    name="${BASH_REMATCH[1]}"
    run "brew $name" brew install "$name"
  elif [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
    name="${BASH_REMATCH[1]}"
    run "cask $name" brew install --cask "$name"
  elif [[ "$line" =~ ^mas[[:space:]]+\"([^\"]+)\",[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
    name="${BASH_REMATCH[1]}"; appid="${BASH_REMATCH[2]}"
    if command -v mas >/dev/null 2>&1; then
      run "mas \"$name\" ($appid)" mas install "$appid"
    else
      total=$((total + 1)); failed+=("mas \"$name\" ($appid) — mas CLI not installed")
      printf "  ✗ mas %s (mas CLI missing)\n" "$name"
    fi
  fi
done < "$FILE"

echo ""
echo "── Brewfile.optional summary ──"
printf "  installed: %d / %d\n" "$ok" "$total"
if [ "${#failed[@]}" -gt 0 ]; then
  printf "  failed:    %d\n" "${#failed[@]}"
  for f in "${failed[@]}"; do
    printf "     - %s\n" "$f"
  done
  echo ""
  echo "Full output captured at: $LOG"
  emit_result "brew-optional" "warn" "$ok/$total (${#failed[@]} failed)" "${failed[@]}"
else
  emit_result "brew-optional" "ok" "$ok/$total installed"
fi

exit 0
