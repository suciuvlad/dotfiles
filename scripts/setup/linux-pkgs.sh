#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Linux counterpart to the strict Brewfile. Targets Debian/Ubuntu — the
# headless agent VMs first, a desktop too. There is no Homebrew here by
# design: a second package manager on a server buys nothing but a
# /home/linuxbrew prefix to be surprised by later.
#
# Five sections, in dependency order:
#   1. apt         base tools Debian/Ubuntu package at a usable version
#   2. installers  mise and herdr — the two that bootstrap the rest
#   3. mise        modern CLIs apt ships stale or not at all, mostly via
#                  mise's github backend (release binaries). Same convention
#                  as mise/.tool-versions owning npm CLIs: if a version
#                  manager can own it, it does.
#   4. zsh plugins cloned to ~/.local/share/zsh/plugins — what brew's zsh-*
#                  formulae provide on macOS
#   5. desktop     clipboard tools and a Nerd Font, only where a desktop
#                  session exists (best-effort)
#
# Deliberately NOT installed: mas, reattach-to-user-namespace (macOS only),
# postgresql (runs in Docker on these boxes, not on the host), docker itself
# (a machine-level service — the VM template/cloud-init owns it, dotfiles
# own the user environment), yarn and tmuxinator (per-project; the tmux
# helpers live in herdr now).
#
# The mise tools end up in mise's global config (~/.config/mise/config.toml),
# not in the stowed ~/.tool-versions: that file is shared with macOS, where
# brew already provides them. The arrays below are their source of truth.

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
  # herdr.sh's settings.json normaliser; cloud images have it, bare ones don't
  python3
  # mise's ruby core compiles with ruby-build; without these it fails late
  libssl-dev libyaml-dev libreadline-dev zlib1g-dev libffi-dev libgmp-dev
)

echo "→ apt: ${#APT_PKGS[@]} packages"
if ! "${SUDO[@]}" apt-get update -qq; then
  failed+=("apt-get update — failed")
else
  # env, not a prefix assignment: sudo resets the environment. noninteractive
  # + needrestart in automatic mode (restart affected services, don't ask)
  # keep Ubuntu cloud images from prompting.
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
# -T (GNU): never descend into an existing ~/.local/bin/bat directory.
for pair in "batcat bat" "fdfind fd"; do
  deb="${pair% *}"; want="${pair##* }"
  if [ -x "/usr/bin/$deb" ]; then
    ln -sfT "/usr/bin/$deb" "$HOME/.local/bin/$want" || failed+=("$want — symlink to $deb failed")
  fi
done

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
# github: pulls the matching release binary straight from GitHub, so these
# track upstream instead of whatever the distro froze two years ago. (It
# replaced mise's ubi backend, which goes away in mise 2027.1.)
# "<mise tool spec> <binary>" pairs — the binary name is what the present-check
# asks mise for, and it isn't always the tool name (neovim ships nvim).
# Each GitHub-backed lookup is an unauthenticated API call, 60/hour per IP.
# Rebuilding the template a few times in an hour exhausts that; exporting
# MISE_GITHUB_TOKEN before 'make linux' lifts it.
#
# Same two-tier policy as Brewfile vs Brewfile.optional (membership differs:
# on macOS all of these are strict). Essentials are what the stowed configs
# wire in or agents lean on (a missing eza breaks `ls`), and a failure there
# stops the chain. The rest is best-effort — reported, never fatal.
MISE_ESSENTIAL=(
  "neovim nvim"
  # apt's fzf (0.44 on 24.04) predates the `fzf --zsh` that .zshrc sources
  "github:junegunn/fzf[exe=fzf] fzf"
  "github:starship/starship[exe=starship] starship"
  "github:atuinsh/atuin[exe=atuin] atuin"
  "github:eza-community/eza[exe=eza] eza"
  "github:dandavison/delta[exe=delta] delta"
  "github:cli/cli[exe=gh] gh"
)
MISE_OPTIONAL=(
  "github:jesseduffield/lazygit[exe=lazygit] lazygit"
  "github:jesseduffield/lazydocker[exe=lazydocker] lazydocker"
  "github:sxyazi/yazi[exe=yazi] yazi"
  "github:bootandy/dust[exe=dust] dust"
  "github:charmbracelet/gum[exe=gum] gum"
  "github:anchore/grype[exe=grype] grype"
  # registry names (aqua backend); strict on macOS, best-effort here
  "pnpm pnpm"
  "tealdeer tldr"
)

# mise_tools <strict|optional> <entry>...
mise_tools() {
  local tier="$1"; shift
  local entry tool name err why
  for entry in "$@"; do
    tool="${entry% *}"; name="${entry##* }"
    if "$MISE_BIN" which "$name" >/dev/null 2>&1; then
      echo "· $name present"
      continue
    fi
    echo "→ mise use -g $tool"
    # Keep stderr: the first 'mise ERROR' line names the cause (404, 403 rate
    # limit, ...); the last line only says "run with --verbose".
    if err="$("$MISE_BIN" use -g "$tool" 2>&1 >/dev/null)"; then
      installed+=("$name")
      printf '%s\n' "$err" | grep '^mise WARN' | sed 's/^/  /' || true
    else
      why="$(printf '%s\n' "$err" | grep -m1 '^mise ERROR' | sed 's/^mise ERROR *//' || true)"
      [ -n "$why" ] || why="$(printf '%s\n' "$err" | tail -n 1)"
      if [ "$tier" = "strict" ]; then
        failed+=("$name — mise use failed: $why")
      else
        optional_failed+=("$name — mise use failed: $why")
      fi
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

# ── 5. desktop extras ───────────────────────────────────────────────────────
# Only where something renders them: a session type is set, or a desktop
# session file exists (Ubuntu Desktop; cloud images and containers have
# neither). LINUX_DESKTOP=1|0 overrides the guess. Everything here is
# best-effort — a headless box that guesses wrong loses nothing.
is_desktop() {
  case "${LINUX_DESKTOP:-}" in 1) return 0 ;; 0) return 1 ;; esac
  [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && return 0
  compgen -G "/usr/share/xsessions/*.desktop" >/dev/null \
    || compgen -G "/usr/share/wayland-sessions/*.desktop" >/dev/null
}

if is_desktop; then
  # nvim's unnamedplus and tmux-yank need a clipboard tool; xdg-open backs
  # nvim's vim.ui.open; fontconfig provides fc-cache below.
  DESKTOP_PKGS=(xclip wl-clipboard xdg-utils fontconfig)
  echo "→ desktop: apt ${DESKTOP_PKGS[*]}"
  if "${SUDO[@]}" env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
      apt-get install -y -qq "${DESKTOP_PKGS[@]}"; then
    installed+=("desktop-apt(${#DESKTOP_PKGS[@]})")
  else
    optional_failed+=("desktop packages — apt-get install failed")
  fi

  # The font ghostty, starship and `eza --icons` assume. Direct release URL:
  # a redirect, not an API call, so it doesn't count against the 60/hour.
  FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if compgen -G "$FONT_DIR/*.ttf" >/dev/null; then
    echo "· JetBrainsMono Nerd Font present"
  else
    echo "→ JetBrainsMono Nerd Font → $FONT_DIR"
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/font.zip" \
         https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip \
       && mkdir -p "$FONT_DIR" \
       && unzip -qo "$tmp/font.zip" '*.ttf' -d "$FONT_DIR" \
       && fc-cache -f "$HOME/.local/share/fonts" >/dev/null; then
      installed+=("nerd-font")
    else
      optional_failed+=("JetBrainsMono Nerd Font — download or install failed")
    fi
    rm -rf "$tmp"
  fi
else
  echo "· no desktop session — skipping clipboard tools and fonts (LINUX_DESKTOP=1 forces them)"
fi

# ── Result ──────────────────────────────────────────────────────────────────
[ ${#optional_failed[@]} -gt 0 ] && printf '⚠ %s\n' "${optional_failed[@]}" >&2

if [ ${#failed[@]} -gt 0 ]; then
  printf '✗ %s\n' "${failed[@]}" >&2
  echo "  re-run 'make linux' to retry; export MISE_GITHUB_TOKEN first if the cause is a GitHub rate limit (403)" >&2
  emit_result "linux-pkgs" "fail" "${#failed[@]} issue(s)" "${failed[@]}" "${optional_failed[@]}"
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
