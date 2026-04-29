#!/usr/bin/env bash
set -euo pipefail

# Install Oh My Zsh without overwriting the stow-managed ~/.zshrc
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_absent() {
  local dest="$1" url="$2"
  [ -d "$dest" ] || git clone --depth=1 "$url" "$dest"
}

clone_if_absent "$ZSH_CUSTOM/plugins/zsh-completions"              https://github.com/zsh-users/zsh-completions
clone_if_absent "$ZSH_CUSTOM/plugins/zsh-autosuggestions"          https://github.com/zsh-users/zsh-autosuggestions
clone_if_absent "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"      https://github.com/zsh-users/zsh-syntax-highlighting
clone_if_absent "$ZSH_CUSTOM/plugins/zsh-history-substring-search" https://github.com/zsh-users/zsh-history-substring-search
clone_if_absent "$ZSH_CUSTOM/themes/powerlevel10k"                 https://github.com/romkatv/powerlevel10k
