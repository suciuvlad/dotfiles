# Login shells only: ssh sessions, and new tabs in the macOS terminals (which
# start login shells; Linux desktop terminals usually don't). Read before
# .zshrc, and inherited by everything a session spawns — including the
# non-interactive shells agents run from it, which never read .zshrc. Not
# covered: one-shot `ssh host cmd`, which is neither login nor interactive
# and reads only ~/.zshenv.

# macOS: Homebrew's prefix, where mise and everything else lives, ahead of
# /usr/bin. (path_helper may have appended it already via /etc/paths.d —
# harmless; .zshrc's `typeset -U path` drops the duplicate.)
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

# mise, herdr, claude and the Debian bat/fd symlinks on Linux; the native
# installers on macOS. Must precede the mise line: on Linux that's where
# mise is.
export PATH="$HOME/.local/bin:$PATH"

# Shims: one static PATH entry that resolves every mise-managed tool, for the
# non-interactive shells that never read .zshrc's `mise activate zsh`.
# Interactive shells get the hook on top and it takes precedence.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh --shims)"
