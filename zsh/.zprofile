# Login shells only (ssh sessions, new terminal tabs), read before .zshrc, and
# inherited by everything a session spawns — including the non-interactive
# shells agents run from it, which never read .zshrc. Not covered: one-shot
# `ssh host cmd`, which is neither login nor interactive and reads only
# ~/.zshenv.

# mise, herdr, claude and the Debian bat/fd symlinks on the agent VMs; the
# native installers on macOS. Must precede the mise line: that's where mise is.
export PATH="$HOME/.local/bin:$PATH"

# Shims: one static PATH entry that resolves every mise-managed tool, for the
# shells where .zshrc's `mise activate zsh` hook never fires. Interactive
# shells get the hook on top and it takes precedence.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh --shims)"
