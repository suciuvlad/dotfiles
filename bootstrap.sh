#!/usr/bin/env bash
# Fresh-Mac bootstrap.
# Run with:
#   curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/master/bootstrap.sh | bash
#
# Idempotent — safe to re-run.
set -euo pipefail

REPO_HTTPS="${DOTFILES_REPO_HTTPS:-https://github.com/suciuvlad/dotfiles.git}"
REPO_SSH="${DOTFILES_REPO_SSH:-git@github.com:suciuvlad/dotfiles.git}"
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
  # Prefer SSH if GitHub auth already works on this Mac. BatchMode=yes
  # disables passphrase/password prompts so a missing/locked key fails
  # fast and falls through to HTTPS. accept-new silently adds github.com
  # to known_hosts on first run.
  if ssh -o BatchMode=yes -o ConnectTimeout=5 \
         -o StrictHostKeyChecking=accept-new \
         -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "→ GitHub SSH already works — cloning via SSH"
    git clone "$REPO_SSH" "$DEST"
  else
    echo "→ Cloning via HTTPS (make ssh will switch to SSH after key registration)"
    git clone "$REPO_HTTPS" "$DEST"
  fi
else
  echo "✓ already cloned"
fi

say "Stow packages"
cd "$DEST"
PACKAGES=(claude ghostty git mise nvim scripts shell starship tmux zsh)

# Pre-flight: dry-run stow to detect real files that would block linking
# (e.g. a hand-written ~/.zshrc on a previously-used Mac).
stow_rc=0
stow_dryrun=$(stow -n -R -t "$HOME" "${PACKAGES[@]}" 2>&1) || stow_rc=$?

if [ "$stow_rc" -ne 0 ]; then
  conflicts=()
  while IFS= read -r line; do
    # Matches both "is neither a link nor a directory: <path>"
    # and "is not owned by stow: <path>".
    if [[ "$line" =~ existing\ target\ is\ [^:]*:\ (.+)$ ]]; then
      conflicts+=("${BASH_REMATCH[1]}")
    fi
  done <<< "$stow_dryrun"

  if [ ${#conflicts[@]} -eq 0 ]; then
    echo "✗ Stow dry-run failed but no parseable conflicts:" >&2
    while IFS= read -r ln; do echo "    $ln" >&2; done <<< "$stow_dryrun"
    exit 1
  fi

  backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  echo "→ Found ${#conflicts[@]} existing file(s) blocking stow:"
  printf '    %s\n' "${conflicts[@]}"
  echo "→ Backing up to $backup_dir"
  mkdir -p "$backup_dir"
  for rel in "${conflicts[@]}"; do
    target="$HOME/$rel"
    [ -e "$target" ] || continue
    bp="$backup_dir/$rel"
    mkdir -p "$(dirname "$bp")"
    mv "$target" "$bp"
  done
fi

# -R = restow (idempotent — re-link without erroring on existing links)
stow -R -t "$HOME" "${PACKAGES[@]}"

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
