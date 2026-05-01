# Manual

A reference for what's in this dotfiles repo: the tools, the keybindings, the configs, and the workflows they enable. Inspired by the [Omarchy manual](https://learn.omacom.io/2/the-omarchy-manual/).

## Table of contents

1. [Setup](01-setup.md) — bootstrap, `make` targets, stow workflow, troubleshooting
2. [Hotkeys](02-hotkeys.md) — tmux, neovim, zsh, ghostty
3. [Shell tools](03-shell-tools.md) — atuin, fzf, fd, ripgrep, bat, eza, zoxide, jq, gh, git-delta, …
4. [TUIs](04-tuis.md) — lazygit, lazydocker, btop, yazi, neovim, tmux
5. [Dev stacks](05-dev-stacks.md) — node, go, python, ruby, rust, postgres, supabase
6. [Apps](06-apps.md) — every cask in `Brewfile.optional`, grouped
7. [Other packages](07-other-packages.md) — security CLIs, cloud, media, niche

## How this manual is organized

Each chapter lists tools as small entries:

```
### `tool-name`
1-line summary of what it does.

**Killer commands**
- the 3-5 invocations actually used day-to-day

**Config:** path/to/file:line
**Upstream:** https://…
```

The goal isn't to replicate upstream documentation — it's to record *why this tool is in the stack* and *which 3 commands matter*. For deep dives, follow the upstream link.

## Source of truth

Tools are installed by [`scripts/Brewfile`](../scripts/Brewfile) (strict — must succeed) and [`scripts/Brewfile.optional`](../scripts/Brewfile.optional) (best-effort). Configuration lives in the stow packages at the repo root (`zsh/`, `nvim/`, `tmux/`, etc.). When a doc entry conflicts with the actual config, **the config wins** — please open a PR to fix the doc.
