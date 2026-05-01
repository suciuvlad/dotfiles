---
name: update-docs
description: Use this skill when editing files that affect the dotfiles documentation under docs/. Triggers include scripts/Brewfile or scripts/Brewfile.optional (tool installs), zsh/.zshrc (aliases, tool wirings), tmux/.tmux.conf or tmux/.tmux-functions.zsh (keybindings, layout helpers), nvim/.config/nvim/lua/keymaps.lua or any nvim/.config/nvim/lua/plugins/*.lua (keymaps, new plugins), mise/.tool-versions (runtimes), scripts/Makefile (provisioning targets), scripts/setup/defaults.sh (macOS defaults), or adding/removing/renaming a top-level stow package directory. Apply this skill alongside the change — edit the relevant docs/ chapter in the same turn so the manual never drifts from the configs.
---

# Updating the dotfiles manual

The `docs/` directory is the public manual for this repo. When you change a file listed in this skill's description, update the matching doc chapter in the **same turn** as the code change, not "later."

## Source → doc mapping

| When you edit                                          | Update                                                                                       |
|--------------------------------------------------------|----------------------------------------------------------------------------------------------|
| `scripts/Brewfile` (strict CLI)                        | `docs/03-shell-tools.md`, or `docs/04-tuis.md` for full-screen apps (lazygit, btop, yazi…)   |
| `scripts/Brewfile.optional` — casks                    | `docs/06-apps.md` (find the right category table)                                            |
| `scripts/Brewfile.optional` — MAS                      | `docs/06-apps.md` Mac App Store section                                                      |
| `scripts/Brewfile.optional` — language/dev CLIs        | `docs/05-dev-stacks.md` (e.g. `buf`/`delve` → Go; `uv` → Python)                             |
| `scripts/Brewfile.optional` — security/cloud/media     | `docs/07-other-packages.md`                                                                  |
| `zsh/.zshrc` aliases                                   | `docs/02-hotkeys.md` aliases table                                                           |
| `zsh/.zshrc` new tool init (`eval`/`source`)           | `docs/03-shell-tools.md` (entry's `Config:` line) + cross-ref in `02-hotkeys.md` if it binds keys |
| `tmux/.tmux.conf` keybindings                          | `docs/02-hotkeys.md` tmux section                                                            |
| `tmux/.tmux-functions.zsh` helpers                     | `docs/02-hotkeys.md` "Shell helpers" subsection                                              |
| `nvim/.config/nvim/lua/keymaps.lua`                    | `docs/02-hotkeys.md` neovim section                                                          |
| `nvim/.config/nvim/lua/plugins/*.lua` (new plugin)     | `docs/02-hotkeys.md` (subsection for the plugin) + `docs/04-tuis.md` if it adds a TUI        |
| `mise/.tool-versions`                                  | `docs/05-dev-stacks.md` (relevant language section)                                          |
| `scripts/Makefile` (new target)                        | `docs/01-setup.md` provisioning-chain table                                                  |
| `scripts/setup/defaults.sh` (new `defaults write`)     | `docs/01-setup.md` (note new behavior if user-visible)                                       |
| New top-level stow package directory                   | `README.md` package table + `docs/01-setup.md` file-layout block + the chapter that documents that package's tools |
| Removed top-level stow package directory               | Same as above — remove rows                                                                  |

## Per-tool entry template

When adding a CLI tool to `docs/03-shell-tools.md`, `docs/05-dev-stacks.md`, or `docs/07-other-packages.md`:

```
### `tool-name`
One-line summary. What it does or what it replaces.

**Killer commands**
- 3-5 invocations actually used day-to-day
- Skip the obvious ones (--help, --version)

**Config:** path/to/file:line   (only if there's a wiring point)
**Upstream:** https://…
```

For casks/MAS apps in `docs/06-apps.md`: just add a row to the right category table — `| name | one-line description |`. No prose entry.

## Coverage rules

- **Don't pad.** Spotify, VLC, Slack don't need prose. The one-line table row in `06-apps.md` is enough.
- **Why over what.** Upstream docs explain what a tool does. The manual's value is *why this is in the stack* and *which 3 commands matter*.
- **Anchor to the config.** When a tool is wired in a config file, cite the file:line so readers can find the wiring instantly.
- **Cross-reference instead of duplicating.** If a tool already has a section elsewhere (e.g. `tldr` in shell-tools), link to it from `07-other-packages.md` rather than duplicating.
- **Sort alphabetically within each section** — keep entries scannable.

## Stow-package additions

A new top-level directory is a bigger change. Update at minimum:

1. `README.md` — the "Package | What it provides" table.
2. `docs/01-setup.md` — the file-layout block at the bottom.
3. `bootstrap.sh` line 60 — the `stow -R -t "$HOME"` package list (this is code, not docs, but it's the reason the package gets symlinked).
4. The chapter that documents whatever the package contains (a new TUI? `04-tuis.md`. New keybindings? `02-hotkeys.md`).

## What NOT to update

- Internal-only refactors of existing configs (renaming a Lua variable, reformatting a Brewfile comment).
- `scripts/setup/brew-optional.sh` logic changes — these are infrastructure, not user-visible.
- `claude/.claude/CLAUDE.md` — that's user instructions, not part of the public manual.
- Comment-only changes anywhere.

## Quick check after editing

Before finishing the turn, verify:
- [ ] The doc entry uses the template format above.
- [ ] Internal links resolve (relative paths from `docs/` to repo root use `../`).
- [ ] If a section gained a new entry, the section's intro/TOC reference is still accurate.
- [ ] `make -C scripts check` still passes (no broken stow links).
