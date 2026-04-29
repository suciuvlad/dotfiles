## ── Editor / dev env ────────────────────────────────────────────
export EDITOR='nvim'
export GOPRIVATE=github.com/purposeinplay/*
export GOPATH="${GOPATH:-$HOME/go}"

## ── PATH ────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"
typeset -U path  # de-dupe
path=(
  "$HOME/.local/bin"
  "$HOME/.codeium/windsurf/bin"
  "$HOME/.opencode/bin"
  "$BUN_INSTALL/bin"
  "$PNPM_HOME"
  "$GOPATH/bin"
  "/opt/homebrew/opt/ruby/bin"
  $path
)

export FPATH="$HOME/.config/eza/completions/zsh:$FPATH"

## ── History ─────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE

## ── Completion ──────────────────────────────────────────────────
# zsh-completions must be on fpath BEFORE compinit
[ -d /opt/homebrew/share/zsh-completions ] && \
  fpath=(/opt/homebrew/share/zsh-completions $fpath)
autoload -Uz compinit && compinit -i  # -i: silently skip insecure dirs instead of prompting

## ── Plugins (Homebrew) ──────────────────────────────────────────
HBSHARE="/opt/homebrew/share"
[ -f "$HBSHARE/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$HBSHARE/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$HBSHARE/zsh-history-substring-search/zsh-history-substring-search.zsh" ] && \
  source "$HBSHARE/zsh-history-substring-search/zsh-history-substring-search.zsh"
# syntax-highlighting MUST be sourced last
[ -f "$HBSHARE/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$HBSHARE/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Up/Down arrow → history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

## ── Aliases ─────────────────────────────────────────────────────
# Git aliases live in ~/.gitconfig — invoke as `g <alias>` (e.g. `g st`).
alias g='git'

alias la=tree
alias cat=bat
alias d='docker'
alias r='rails'
alias c='claude'
alias cc='claude --enable-auto-mode'
alias t='tmux attach || tmux new -s Work'
alias cl='clear'
alias lzd='lazydocker'

# Eza
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# fzf / file picking
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'

## ── Functions ───────────────────────────────────────────────────
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Tmux layout helpers (tdl, tdlm, tsl)
[ -f "$HOME/.tmux-functions.zsh" ] && source "$HOME/.tmux-functions.zsh"

## ── Tools ───────────────────────────────────────────────────────
# Google Cloud SDK
[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]       && source "$HOME/google-cloud-sdk/path.zsh.inc"
[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

# Bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Mise (version manager)
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# fzf
command -v fzf &>/dev/null && source <(fzf --zsh)

# zoxide (smarter cd: 'z <pat>' jumps to a frecent dir, 'zi' picks via fzf)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

## ── Per-machine overrides (untracked) ───────────────────────────
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
