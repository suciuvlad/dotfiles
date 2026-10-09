#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Linux counterpart to the strict Brewfile. Targets Debian/Ubuntu on the
# headless agent VMs (see the home-infra plan's agent01); there is no
# Homebrew here by design — a second package manager on a server buys
# nothing but a /home/linuxbrew prefix to be surprised by later.
#
# Three tiers, in dependency order:
#   1. apt       base tools Debian/Ubuntu package at a usable version
#   2. installers  mise and herdr — the two that bootstrap the rest
#   3. mise      modern CLIs apt ships stale or not at all, via mise's ubi
#                backend (GitHub releases). Same convention as
#                mise/.tool-versions owning npm CLIs: if a version manager
#                can own it, it does.
#
# Deliberately NOT installed: mas, reattach-to-user-namespace (macOS only),
# postgresql (runs in Docker on these boxes, not on the host), docker itself
# (a machine-level service — the VM template/cloud-init owns it, dotfiles
# own the user environment).
#
# The ubi tools end up in mise's global config (~/.config/mise/config.toml),
# not in the stowed ~/.tool-versions: that file is shared with macOS, where
# brew already provides them. The array below is their source of truth.

installed=()
failed=()
optional_failed=()

# Array, not a string: an empty string would expand to an empty argument
# under quoting, and an unquoted $SUDO is SC2086. Empty array disappears.
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  SUDO=()
fi

# ── 1. apt ──────────────────────────────────────────────────────────────────
APT_PKGS=(
  bat build-essential ca-certificates curl direnv fd-find git jq
  ripgrep shellcheck stow tmux tree unzip zoxide zsh btop
  # mise's ruby core compiles with ruby-build; without these it fails late
  libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev libgmp-dev
)

echo "→ apt: ${#APT_PKGS[@]} packages"
if ! "${SUDO[@]}" apt-get update -qq; then
  failed+=("apt-get update — failed")
else
  # env, not a prefix assignment: sudo resets the environment. noninteractive
  # + needrestart in list mode keep Ubuntu cloud images from prompting.
  if ! "${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
      apt-get install -y -qq "${APT_PKGS[@]}"; then
    failed+=("apt-get install — one or more packages failed")
  else
    installed+=("apt(${#APT_PKGS[@]})")
  fi
fi

# Debian renames two binaries to dodge existing packages. Symlink them to the
# names every config and muscle-memory expects, rather than aliasing in .zshrc
# where scripts and agents won't see them.
mkdir -p "$HOME/.local/bin"
[ -x /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat" || true
[ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd" || true

# ── 2. bootstrap installers ─────────────────────────────────────────────────
if command -v mise >/dev/null 2>&1; then
  echo "· mise already installed"
else
  echo "→ installing mise"
  if curl -fsSL https://mise.run | sh; then
    installed+=("mise")
  else
    failed+=("mise — installer failed")
  fi
fi

MISE_BIN="$HOME/.local/bin/mise"
[ -x "$MISE_BIN" ] || MISE_BIN="$(command -v mise 2>/dev/null || true)"

if command -v herdr >/dev/null 2>&1 || [ -x "$HOME/.local/bin/herdr" ]; then
  echo "· herdr already installed"
else
  echo "→ installing herdr"
  if curl -fsSL https://herdr.dev/install.sh | sh; then
    installed+=("herdr")
  else
    failed+=("herdr — installer failed")
  fi
fi

# ── 3. mise-managed CLIs ────────────────────────────────────────────────────
# ubi: pulls the matching release binary straight from GitHub, so these track
# upstream instead of whatever the distro froze two years ago.
# "<mise tool spec> <binary>" pairs — the binary name is what the present-check
# asks mise for, and it isn't always the tool name (neovim ships nvim).
# Each ubi lookup is an unauthenticated GitHub API call, 60/hour per IP.
# Rebuilding the template a few times in an hour exhausts that; exporting
# MISE_GITHUB_TOKEN before 'make linux' lifts it.
#
# Same split as Brewfile vs Brewfile.optional: essentials are what the stowed
# configs wire in or agents lean on (a missing eza breaks `ls`), and a failure
# there stops the chain. The rest is best-effort — reported, never fatal.
MISE_ESSENTIAL=(
  "neovim nvim"
  # apt's fzf (0.44 on 24.04) predates the `fzf --zsh` that .zshrc sources
  "ubi:junegunn/fzf[exe=fzf] fzf"
  "ubi:starship/starship[exe=starship] starship"
  "ubi:atuinsh/atuin[exe=atuin] atuin"
  "ubi:eza-community/eza[exe=eza] eza"
  "ubi:dandavison/delta[exe=delta] delta"
  "ubi:cli/cli[exe=gh] gh"
)
MISE_OPTIONAL=(
  "ubi:jesseduffield/lazygit[exe=lazygit] lazygit"
  "ubi:jesseduffield/lazydocker[exe=lazydocker] lazydocker"
  "ubi:sxyazi/yazi[exe=yazi] yazi"
  "ubi:bootandy/dust[exe=dust] dust"
  "ubi:charmbracelet/gum[exe=gum] gum"
  "ubi:anchore/grype[exe=grype] grype"
)

# mise_tools <strict|optional> <entry>...
mise_tools() {
  local tier="$1"; shift
  local entry tool name err
  for entry in "$@"; do
    tool="${entry% *}"; name="${entry##* }"
    if "$MISE_BIN" which "$name" >/dev/null 2>&1; then
      echo "· $name present"
      continue
    fi
    echo "→ mise use -g $tool"
    # Keep stderr: mise's last line names the cause (404, rate limit, ...).
    if err="$("$MISE_BIN" use -g "$tool" 2>&1 >/dev/null)"; then
      installed+=("$name")
    elif [ "$tier" = "strict" ]; then
      failed+=("$name — mise use failed: $(printf '%s\n' "$err" | tail -n 1)")
    else
      optional_failed+=("$name — mise use failed: $(printf '%s\n' "$err" | tail -n 1)")
    fi
  done
}

if [ -z "$MISE_BIN" ]; then
  failed+=("mise tools — mise not on PATH, skipped $(( ${#MISE_ESSENTIAL[@]} + ${#MISE_OPTIONAL[@]} )) tools")
else
  mise_tools strict "${MISE_ESSENTIAL[@]}"
  mise_tools optional "${MISE_OPTIONAL[@]}"
fi

# ── 4. zsh plugins ──────────────────────────────────────────────────────────
# One predictable prefix for all four, so .zshrc needs a single Linux branch
# rather than four distro-specific paths. Mirrors what brew gives on macOS.
ZSH_PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

ZSH_PLUGINS=(
  "zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting"
  "zsh-completions https://github.com/zsh-users/zsh-completions"
  "zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search"
)

for entry in "${ZSH_PLUGINS[@]}"; do
  name="${entry%% *}"; url="${entry##* }"
  dest="$ZSH_PLUGIN_DIR/$name"
  if [ -d "$dest/.git" ]; then
    echo "· $name present"
    continue
  fi
  echo "→ cloning $name"
  if git clone --depth 1 -q "$url" "$dest"; then
    installed+=("$name")
  else
    failed+=("$name — clone failed")
  fi
done

# ── Result ──────────────────────────────────────────────────────────────────
[ ${#optional_failed[@]} -gt 0 ] && printf '⚠ %s\n' "${optional_failed[@]}" >&2

if [ ${#failed[@]} -gt 0 ]; then
  printf '✗ %s\n' "${failed[@]}" >&2
  emit_result "linux-pkgs" "warn" "${#failed[@]} issue(s)" "${failed[@]}" "${optional_failed[@]}"
  exit 1
fi

[ ${#installed[@]} -gt 0 ] && echo "✓ installed: ${installed[*]}"
if [ ${#optional_failed[@]} -gt 0 ]; then
  echo "✓ Linux packages ready (${#optional_failed[@]} optional tool(s) missing — re-run to retry)"
  emit_result "linux-pkgs" "warn" "${#optional_failed[@]} optional tool(s) failed" "${optional_failed[@]}"
else
  echo "✓ Linux packages ready"
  emit_result "linux-pkgs" "ok" "${#installed[@]} groups installed"
fi
