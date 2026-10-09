#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Cloud images hand the default user bash, and nothing in zsh/ runs until the
# login shell is zsh. This is its own step, after stow-linux, on purpose:
# switching before ~/.zshrc is linked and then failing partway would leave the
# next login in zsh's new-user wizard with no ~/.local/bin on PATH.

me="$(id -un)"
login_shell="$(getent passwd "$me" | cut -d: -f7)"
zsh_bin="$(command -v zsh || true)"

if [ -z "$zsh_bin" ]; then
  echo "✗ zsh not installed — run 'make linux-pkgs' first" >&2
  emit_result "linux-shell" "fail" "zsh not installed"
  exit 1
fi

if [ "$(basename "$login_shell")" = "zsh" ]; then
  echo "· login shell for $me already zsh"
  emit_result "linux-shell" "ok" "already zsh"
  exit 0
fi

if [ ! -e "$HOME/.zshrc" ]; then
  echo "✗ ~/.zshrc not linked — run 'make stow-linux' first" >&2
  emit_result "linux-shell" "fail" ".zshrc not linked (run make stow-linux)"
  exit 1
fi

# Array, not a string: an empty string would expand to an empty argument
# under quoting, and an unquoted $SUDO is SC2086. Empty array disappears.
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  SUDO=()
fi

echo "→ login shell for $me: $login_shell → $zsh_bin"
if "${SUDO[@]}" chsh -s "$zsh_bin" "$me"; then
  echo "✓ login shell is zsh (from the next login)"
  emit_result "linux-shell" "ok" "chsh to $zsh_bin"
else
  echo "✗ chsh failed — run: sudo chsh -s $zsh_bin $me" >&2
  emit_result "linux-shell" "fail" "chsh failed for $me"
  exit 1
fi
