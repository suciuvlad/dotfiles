#!/usr/bin/env bash
# Interactive picker for Brewfile.optional.
# Falls back to "install everything" when not in a TTY or when gum is missing,
# so curl|bash bootstrap and CI keep working.
#
# Selection is persisted to ~/.config/dotfiles/brew-optional.selected and
# pre-checked on subsequent runs.
#
# Env:
#   DRY_RUN=1   parse + prompt only; print the generated Brewfile and exit
set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
SETUP_DIR="$SCRIPTS_DIR/setup"
SOURCE="$SCRIPTS_DIR/Brewfile.optional"
STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
STATE="$STATE_DIR/brew-optional.selected"

[ -r "$SOURCE" ] || { echo "pick-optional: cannot read $SOURCE" >&2; exit 1; }

# Non-interactive or no gum → legacy behavior (install everything).
if [ ! -t 0 ] || [ ! -t 1 ] || ! command -v gum >/dev/null 2>&1; then
  exec bash "$SETUP_DIR/brew-optional.sh" "$SOURCE"
fi

PARSED="$(mktemp -t brewfile-parsed.XXXXXX)"
TMP_BREWFILE="$(mktemp -t Brewfile.picked.XXXXXX)"
PREV_STATE="$(mktemp -t brew-optional-prev.XXXXXX)"
trap 'rm -f "$PARSED" "$TMP_BREWFILE" "$PREV_STATE"' EXIT

if [ -f "$STATE" ]; then
  cp "$STATE" "$PREV_STATE"
fi
prev_count=$(wc -l < "$PREV_STATE" 2>/dev/null | tr -d ' ' || echo 0)
[ -z "$prev_count" ] && prev_count=0

# Parse Brewfile.optional → "section|key|label|raw" lines.
#   section: most recent "# ..." comment header
#   key:     unique id like brew:fzf, cask:spotify, mas:Magnet:441258766
#   label:   human form shown in the picker
#   raw:     the original brewfile line, used to rebuild a temp Brewfile
parse_optional() {
  local file="$1"
  local section="(uncategorized)"
  local line trim no_comment header
  while IFS= read -r line || [ -n "$line" ]; do
    trim="${line#"${line%%[![:space:]]*}"}"
    trim="${trim%"${trim##*[![:space:]]}"}"
    [ -z "$trim" ] && continue
    if [[ "$trim" == \#* ]]; then
      header="${trim#\#}"
      header="${header#"${header%%[![:space:]]*}"}"
      header="${header%"${header##*[![:space:]]}"}"
      [ -n "$header" ] && section="$header"
      continue
    fi
    no_comment="${trim%%#*}"
    no_comment="${no_comment%"${no_comment##*[![:space:]]}"}"
    [ -z "$no_comment" ] && continue
    if   [[ "$no_comment" =~ ^tap[[:space:]]+\"([^\"]+)\" ]]; then
      printf '%s|tap:%s|tap %s|%s\n'  "$section" "${BASH_REMATCH[1]}" "${BASH_REMATCH[1]}" "$no_comment"
    elif [[ "$no_comment" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
      printf '%s|brew:%s|brew %s|%s\n' "$section" "${BASH_REMATCH[1]}" "${BASH_REMATCH[1]}" "$no_comment"
    elif [[ "$no_comment" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
      printf '%s|cask:%s|cask %s|%s\n' "$section" "${BASH_REMATCH[1]}" "${BASH_REMATCH[1]}" "$no_comment"
    elif [[ "$no_comment" =~ ^mas[[:space:]]+\"([^\"]+)\",[[:space:]]*id:[[:space:]]*([0-9]+) ]]; then
      printf '%s|mas:%s:%s|mas %s|%s\n' "$section" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[1]}" "$no_comment"
    fi
  done < "$file"
}

parse_optional "$SOURCE" > "$PARSED"
total=$(wc -l < "$PARSED" | tr -d ' ')

# ── Top menu ───────────────────────────────────────────────────────────────
opts=()
[ "$prev_count" -gt 0 ] && opts+=("Use saved ($prev_count items)")
opts+=("Pick per category")
opts+=("Everything ($total items)")
opts+=("Skip")

mode=$(gum choose --header "Brewfile.optional — what to install?" "${opts[@]}") || mode="Skip"

case "$mode" in
  Skip|"")
    echo "Skipped optional brew install."
    exit 0
    ;;
  "Use saved"*)
    : # use $STATE as-is (already populated)
    ;;
  Everything*)
    mkdir -p "$STATE_DIR"
    awk -F'|' '{print $2}' "$PARSED" > "$STATE"
    ;;
  "Pick per category")
    mkdir -p "$STATE_DIR"
    : > "$STATE"

    sections=$(awk -F'|' '!seen[$1]++ {print $1}' "$PARSED")

    while IFS= read -r section; do
      [ -z "$section" ] && continue

      items=$(awk -F'|' -v s="$section" '$1==s {print $3}' "$PARSED")
      [ -z "$items" ] && continue

      # Pre-select: previously chosen items in this section (carry forward),
      # or — on first run with no history — everything in the section.
      if [ "$prev_count" -gt 0 ]; then
        preselect_labels=$(awk -F'|' \
          'NR==FNR{keep[$0]=1; next} $1==s && ($2 in keep){print $3}' \
          s="$section" "$PREV_STATE" "$PARSED" | paste -sd, -)
      else
        preselect_labels=$(printf '%s' "$items" | paste -sd, -)
      fi

      selected=$(printf '%s\n' "$items" | gum choose --no-limit \
        --header "$section" --selected="$preselect_labels") || selected=""

      [ -z "$selected" ] && continue
      while IFS= read -r label; do
        [ -z "$label" ] && continue
        awk -F'|' -v s="$section" -v l="$label" \
          '$1==s && $3==l {print $2; exit}' "$PARSED" >> "$STATE"
      done <<< "$selected"
    done <<< "$sections"
    ;;
esac

selected_count=$(wc -l < "$STATE" 2>/dev/null | tr -d ' ' || echo 0)
[ -z "$selected_count" ] && selected_count=0
if [ "$selected_count" -eq 0 ]; then
  echo "No items selected — skipping."
  exit 0
fi

# Build temp Brewfile from picks (taps first so dependent casks resolve).
{
  awk -F'|' 'NR==FNR{keep[$0]=1; next} ($2 in keep) && $4 ~ /^tap /  {print $4}' "$STATE" "$PARSED"
  awk -F'|' 'NR==FNR{keep[$0]=1; next} ($2 in keep) && $4 !~ /^tap / {print $4}' "$STATE" "$PARSED"
} > "$TMP_BREWFILE"

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "── Picked ($selected_count items) ──"
  cat "$TMP_BREWFILE"
  echo ""
  echo "(DRY_RUN=1, not installing. State saved at $STATE.)"
  exit 0
fi

echo ""
echo "── Installing $selected_count optional items ──"
exec bash "$SETUP_DIR/brew-optional.sh" "$TMP_BREWFILE"
