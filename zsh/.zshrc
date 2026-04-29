# Path to oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

plugins=(
	git
	zsh-syntax-highlighting
	zsh-completions
	zsh-autosuggestions
	zsh-history-substring-search
)

source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR='nvim'

# Go
export GOPRIVATE=github.com/purposeinplay/*
export GOPATH="${GOPATH:-$HOME/go}"
export PATH=$PATH:$GOPATH/bin

alias la=tree
alias cat=bat

# Git
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gcad='git commit -a --amend'
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'
alias g='git'

# Tools
alias d='docker'
alias r='rails'
alias c='claude'
alias cc='claude --enable-auto-mode'
alias t='tmux attach || tmux new -s Work'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Tmux layout functions (tdl, tdlm, tsl)
source "$HOME/.tmux-functions.zsh"

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Eza
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# File system
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'
alias cl='clear'

# Google Cloud SDK
if [ -f '/Users/vladsuciu/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/vladsuciu/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/vladsuciu/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/vladsuciu/google-cloud-sdk/completion.zsh.inc'; fi

# Ruby (via mise — gem path resolved lazily)
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
fi

# Starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Mise (version manager for Node, Ruby, etc.)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# fzf
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

# Windsurf
export PATH="/Users/vladsuciu/.codeium/windsurf/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/vladsuciu/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export PATH="$HOME/.local/bin:$PATH"
export FPATH="$HOME/.config/eza/completions/zsh:$FPATH"

# bun
[ -s "/Users/vladsuciu/.bun/_bun" ] && source "/Users/vladsuciu/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/Users/vladsuciu/.opencode/bin:$PATH
alias lzd='lazydocker'
