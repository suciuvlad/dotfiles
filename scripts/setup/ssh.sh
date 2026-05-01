#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

EMAIL="${SSH_KEY_EMAIL:-$(git config --global user.email 2>/dev/null)}"
if [ -z "$EMAIL" ]; then
  echo "No email found. Set SSH_KEY_EMAIL or run 'git config --global user.email' first." >&2
  emit_result "ssh" "fail" "no git user.email configured"
  exit 1
fi
KEY="$HOME/.ssh/id_ed25519"
KEY_GENERATED=0

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$KEY" ]; then
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
  KEY_GENERATED=1
fi

if ! grep -q "^Host \*" "$HOME/.ssh/config" 2>/dev/null; then
  cat >> "$HOME/.ssh/config" <<'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
fi

ssh-add --apple-use-keychain "$KEY" 2>/dev/null || true

# Allowed signers file for git ssh commit-signing verification
ALLOWED="$HOME/.ssh/allowed_signers"
PUBKEY_LINE="$EMAIL namespaces=\"git\" $(cat "$KEY.pub")"
if [ ! -f "$ALLOWED" ] || ! grep -qF "$(cat "$KEY.pub")" "$ALLOWED"; then
  echo "$PUBKEY_LINE" >> "$ALLOWED"
  chmod 600 "$ALLOWED"
fi

echo ""
echo "Public key (paste into https://github.com/settings/keys):"
echo ""
cat "$KEY.pub"
echo ""

# ── If the dotfiles remote is HTTPS, offer to auto-switch to SSH ────────────
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
if [ -d "$DOTFILES_DIR/.git" ]; then
  CURRENT=$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)
  if [[ "$CURRENT" == https://github.com/* ]]; then
    SSH_URL="${CURRENT/https:\/\/github.com\//git@github.com:}"
    SSH_URL="${SSH_URL%.git}.git"

    if [ -e /dev/tty ]; then
      printf "Press ENTER once you've added the key on GitHub (auth + signing), or 's' to skip: "
      read -r reply < /dev/tty
    else
      echo "Non-interactive shell — skipping SSH auth verification."
      echo "After registering the key, switch the remote with:"
      echo "  git -C \"$DOTFILES_DIR\" remote set-url origin \"$SSH_URL\""
      [ "$KEY_GENERATED" -eq 1 ] && detail="ed25519 generated, auth verification skipped" \
                                || detail="key exists, auth verification skipped"
      emit_result "ssh" "ok" "$detail"
      exit 0
    fi

    if [[ "${reply:-}" == "s" || "${reply:-}" == "S" ]]; then
      echo "Skipped. Switch later with:"
      echo "  git -C \"$DOTFILES_DIR\" remote set-url origin \"$SSH_URL\""
      [ "$KEY_GENERATED" -eq 1 ] && detail="ed25519 generated, GitHub registration deferred" \
                                || detail="key exists, GitHub registration deferred"
      emit_result "ssh" "ok" "$detail"
      exit 0
    fi

    # ssh -T returns exit 1 on success (GitHub closes the connection),
    # so we match the success message in stderr.
    if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 \
         | grep -q "successfully authenticated"; then
      git -C "$DOTFILES_DIR" remote set-url origin "$SSH_URL"
      echo "✓ Dotfiles remote switched to SSH: $SSH_URL"
      emit_result "ssh" "ok" "remote switched to SSH"
      exit 0
    else
      echo "✗ GitHub SSH auth failed — key probably not registered yet."
      echo "  Add it at https://github.com/settings/keys, then re-run 'make ssh'."
      emit_result "ssh" "warn" "key ready, GitHub auth not yet working"
      exit 0
    fi
  fi
fi

# Reached when the dotfiles remote is already SSH (or this isn't the dotfiles repo).
[ "$KEY_GENERATED" -eq 1 ] && detail="ed25519 generated" || detail="key already configured"
emit_result "ssh" "ok" "$detail"
