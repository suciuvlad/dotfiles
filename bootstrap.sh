#!/usr/bin/env bash
# Fresh-Mac bootstrap.
# Run with:
#   curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/master/bootstrap.sh | bash
#
# Idempotent — safe to re-run.
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/suciuvlad/dotfiles.git}"
DEST="${DOTFILES_DIR:-$HOME/dotfiles}"

say() { printf "\n── %s ──\n" "$*"; }

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only" >&2; exit 1; }

say "Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  echo "→ Installing (a system dialog will appear)…"
  xcode-select --install || true
  echo "Wait for the install to finish, then re-run this script."
  exit 0
fi
echo "✓ already installed"

say "Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# shellcheck disable=SC1091
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
echo "✓ $(brew --version | head -1)"

say "git + stow (needed to clone & link)"
brew install git stow

say "Clone dotfiles → $DEST"
if [ ! -d "$DEST/.git" ]; then
  git clone "$REPO" "$DEST"
else
  echo "✓ already cloned"
fi

say "Stow packages"
cd "$DEST"
# -R = restow (idempotent — re-link without erroring on existing links)
stow -R -t "$HOME" claude ghostty git mise nvim scripts shell starship tmux zsh

say "Run provisioning (make all)"
make -C "$DEST/scripts" all

cat <<'EOF'

── Done ──

If make ssh just printed a public key, register it on GitHub at
  https://github.com/settings/keys
as BOTH an Authentication Key and a Signing Key.

Once registered, re-run:
  cd ~/dotfiles && make ssh

It will verify GitHub access and auto-switch the dotfiles remote
from HTTPS to SSH.
EOF
