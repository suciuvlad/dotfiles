# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/share/npm/bin:$PATH

function _prompt_char() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    echo "%{%F{blue}%}±%{%f%k%b%}"
  else
    echo ' '
  fi
}

project_pwd() {
  echo $PWD | sed -e "s/\/Users\/$USER/~/"
}

ruby_version() {
  echo " $(ruby -v | awk '{print $2}')"
}

in_git_repo() {
 [ $PWD != "/Users/$HOME" ] && [ -d '.git' ]
}

git_parse_branch() {
  sed -e 's/^.*refs\/heads\///' '.git/HEAD'
}

git_head_commit_id() {
  cut -c 1-7 ".git/refs/heads/`git_parse_branch`"
}

git_cwd_dirty() {
  [[ `git ls-files -m` == '' ]] || echo ' +'
}


git_cwd_info() {
  if in_git_repo; then
    echo -n " %{\e[1;35m%}`git_parse_branch`%{\e[0;35m%}@%{\e[1;35m%}`git_head_commit_id``git_cwd_dirty`%{\e[1;35m%}"
  fi
}

export PROMPT=$'%{\e[1;34m%}%n@\e[1;34m%M%{\e[0m%}
%{\e[0;%(?.32.31)m%}>%{\e[0m%} '

export RPROMPT=$'%{\e[1;31m%}$(project_pwd)%{\e[0;34m%}$(ruby_version)$(git_cwd_info)%{\e[0m%}'
eval "$(rbenv init -)"

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

export DISABLE_AUTO_TITLE=true
