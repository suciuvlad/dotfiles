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
# `g <alias>` uses the gitconfig aliases (e.g. `g st`).
# OMZ-style shell shorthands below mirror the originals (verbose `git status`, etc.).
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gp='git push origin HEAD'
alias gpu='git pull origin'
alias gb='git branch'
alias gba='git branch -a'
alias gc='git commit -m'
alias gca='git commit -a -m'
alias gcad='git commit -a --amend'
alias gcoall='git checkout -- .'
alias gadd='git add'
alias ga='git add -p'
alias gdiff='git diff'
alias gr='git remote'
alias gre='git reset'
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"

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

# direnv (per-project envs via .envrc; pairs with mise)
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# atuin (history search; --disable-up-arrow keeps history-substring-search bindings)
command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

## ── Per-machine overrides (untracked) ───────────────────────────
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
