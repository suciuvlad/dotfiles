#!/usr/bin/env bash
set -euo pipefail

EMAIL="${SSH_KEY_EMAIL:-$(git config --global user.email 2>/dev/null)}"
if [ -z "$EMAIL" ]; then
  echo "No email found. Set SSH_KEY_EMAIL or run 'git config --global user.email' first." >&2
  exit 1
fi
KEY="$HOME/.ssh/id_ed25519"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$KEY" ]; then
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
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

echo ""
echo "Public key (paste into https://github.com/settings/keys):"
echo ""
cat "$KEY.pub"
