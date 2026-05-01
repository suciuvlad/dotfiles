# Hotkeys

Every binding documented here is extracted from a config file in this repo. When in doubt, the config wins.

- **tmux prefix:** `Ctrl-a` (rebound from default `Ctrl-b`)
- **neovim leader:** `,` (both `mapleader` and `maplocalleader`)

---

## tmux

Source: [`tmux/.tmux.conf`](../tmux/.tmux.conf), [`tmux/.tmux-functions.zsh`](../tmux/.tmux-functions.zsh)

### Sessions

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix C`          | New session, starting in current pane's directory   |
| `prefix R`          | Rename current session (prompt prefilled)           |
| `prefix K`          | Kill current session (with confirmation)           |
| `prefix P` / `N`    | Previous / next session                             |
| `Alt-Up` / `Alt-Down` | Previous / next session (no prefix)               |

`detach-on-destroy off` — killing the current session switches to another instead of detaching.

### Windows

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix c`          | New window in current pane's directory              |
| `prefix k`          | Kill current window (with confirmation)             |
| `prefix 1`–`9`      | Jump to window N (windows are 1-indexed)            |

`renumber-windows on` — windows renumber automatically when one is closed.

### Panes — splits

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix \|`          | Horizontal split (panes side-by-side)               |
| `prefix _`          | Vertical split (panes stacked)                      |
| `prefix Ctrl-T`     | Narrow 20%-wide drawer pane on the right            |

All splits start in the current pane's directory.

### Panes — navigation & sizing

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `Ctrl-h/j/k/l`      | Move between panes (works between tmux & nvim via `vim-tmux-navigator`) |
| `prefix Ctrl-W`     | Cycle to next pane                                  |
| `prefix Ctrl-A`     | Toggle pane zoom (full-screen current pane)         |
| `prefix → / ← / ↑ / ↓` | Resize current pane (repeatable — hold without re-pressing prefix) |

### Copy mode (vi-style)

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix [`          | Enter copy mode                                     |
| `v`                 | Begin selection                                     |
| `y`                 | Yank to clipboard and exit copy mode                |
| `q` / `Esc`         | Exit copy mode                                      |

`set-clipboard on` + `tmux-yank` plugin handle OSC 52 → host clipboard.

### Misc

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix r`          | Reload `~/.tmux.conf` (`display "Reloaded!"`)       |

### Plugins (TPM)

| Plugin                              | What it adds                                          |
|-------------------------------------|-------------------------------------------------------|
| `tmux-plugins/tpm`                  | The plugin manager itself                             |
| `tmux-plugins/tmux-sensible`        | Sane defaults (history-limit, terminal, etc.)         |
| `tmux-plugins/tmux-yank`            | OSC 52 clipboard, `prefix y` to copy commandline      |
| `christoomey/vim-tmux-navigator`    | Seamless `Ctrl-h/j/k/l` between tmux panes & nvim splits |
| `catppuccin/tmux`                   | Status-bar theme (mocha)                              |

Install/update plugins: `prefix I` (install), `prefix U` (update), `prefix alt-u` (uninstall removed).

### Shell helpers (zsh functions)

These are zsh functions sourced from `tmux/.tmux-functions.zsh` — they only work inside an active tmux session.

| Command                       | Layout                                                       |
|-------------------------------|--------------------------------------------------------------|
| `tdl <ai> [<ai2>]`            | Dev layout: nvim left, AI right (30%), terminal bottom (15%). Optional second AI splits the right column vertically. |
| `tdlm <ai> [<ai2>]`           | Run `tdl` once per subdirectory, one window each. Renames session to current dir. |
| `tsl <count> <command>`       | Swarm layout: tile `<count>` panes, run `<command>` in each. |

Example: `tdl claude` opens nvim + a Claude pane + a terminal pane in the current dir.

---

## neovim

Source: [`nvim/.config/nvim/lua/keymaps.lua`](../nvim/.config/nvim/lua/keymaps.lua) and per-plugin files in `nvim/.config/nvim/lua/plugins/`.

Leader is `,`. Press `<leader>?` to surface buffer-local maps via which-key.

### Core editing

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `<leader><leader>`  | Jump to alternate file (`<C-^>`)                    |
| `<leader>/`         | Clear search highlight                              |
| `<leader>Q`         | Close all buffers (`:bufdo bdelete`)                |
| `<leader>x`         | Open current file in default macOS app (`!open %`)  |
| `gf`                | Open file under cursor (creates if missing)         |
| `q:`                | Close instead of opening command-line history       |
| `j` / `k`           | Move by terminal rows when wrapped (no count); by lines otherwise |

### Visual mode polish

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `<` / `>`           | Indent and **keep** selection                       |
| `y` / `Y`           | Yank without jumping the cursor                     |
| `p`                 | Paste over selection without copying it             |

### Insert mode shortcuts

| Binding | Action                                |
|---------|---------------------------------------|
| `;;`    | Append `;` at end of line             |
| `,,`    | Append `,` at end of line             |

### Window resize

| Binding         | Action            |
|-----------------|-------------------|
| `Ctrl-↑` / `↓`  | Grow / shrink height |
| `Ctrl-←` / `→`  | Grow / shrink width  |

### Move lines (alt-j / alt-k)

| Mode    | Binding         | Action                          |
|---------|-----------------|---------------------------------|
| Normal  | `Alt-j` / `Alt-k` | Move current line down / up   |
| Insert  | `Alt-j` / `Alt-k` | Same, stays in insert         |
| Visual  | `Alt-j` / `Alt-k` | Move selection, re-select     |

### File picker — fzf-lua

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>f`     | Find files (fd, hidden, no `.git`/node_modules/vendor) |
| `<leader>F`     | Find **all** files (no ignore)                    |
| `<leader>lg`    | Live grep                                         |
| `<leader>lb`    | Buffers                                           |
| `<leader>h`     | Recent (oldfiles)                                 |
| `<leader>ld`    | Workspace diagnostics                             |
| `<leader>gd`    | LSP definitions                                   |

### LSP (active when an LSP attaches)

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `gd`            | Go to definition                                  |
| `gD`            | Go to declaration                                 |
| `gi`            | Go to implementation                              |
| `gr`            | References (via fzf-lua)                          |
| `K`             | Hover docs                                        |
| `<leader>k`     | Signature help                                    |
| `<leader>D`     | Type definition                                   |
| `<leader>rn`    | Rename symbol                                     |
| `<leader>ca`    | Code action                                       |
| `<leader>d`     | Open diagnostic float                             |
| `[d` / `]d`     | Previous / next diagnostic                        |
| `<leader>uh`    | Toggle inlay hints (when supported)               |

### Trouble (diagnostic list)

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>xx`    | Toggle Trouble                                    |
| `<leader>xw`    | Workspace diagnostics                             |
| `<leader>xd`    | Document diagnostics                              |
| `<leader>xl`    | Location list                                     |
| `<leader>xq`    | Quickfix list                                     |
| `<leader>gR`    | LSP references in Trouble                         |

### File tree — nvim-tree

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>n`     | Toggle file tree (focused on current file)        |

### Git — fugitive + gitsigns

| Binding         | Source     | Action                                    |
|-----------------|------------|-------------------------------------------|
| `<leader>gg`    | fugitive   | `:Git` (status buffer)                    |
| `<leader>gB`    | fugitive   | `:Git blame`                              |
| `<leader>gs`    | gitsigns   | Stage hunk                                |
| `<leader>gr`    | gitsigns   | Reset hunk                                |
| `<leader>gp`    | gitsigns   | Preview hunk                              |
| `<leader>gb`    | gitsigns   | Toggle current-line blame                 |
| `]h` / `[h`     | gitsigns   | Next / previous hunk                      |
| `<leader>gf`    | conform    | Format buffer                             |

### Tests — vim-test

(`<leader>t` group — uses `vimux` strategy when inside tmux, else `floaterm`.)

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>tn`    | Test nearest                                      |
| `<leader>tf`    | Test current file                                 |
| `<leader>ts`    | Test suite                                        |
| `<leader>tl`    | Test last                                         |
| `<leader>tv`    | Visit last test file                              |

### Debugger — nvim-dap

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>dt`    | Toggle breakpoint                                 |
| `<leader>dc`    | Continue                                          |
| `<leader>di`    | Step into                                         |
| `<leader>do`    | Step over                                         |
| `<leader>dO`    | Step out                                          |
| `<leader>dr`    | Open REPL                                         |
| `<leader>du`    | Toggle DAP UI                                     |

### Floating terminal — vim-floaterm

| Binding | Action                                            |
|---------|---------------------------------------------------|
| `F1`    | Toggle scratch floaterm (works from terminal mode) |

### Movement — flash.nvim

| Binding         | Mode    | Action                                        |
|-----------------|---------|-----------------------------------------------|
| `s`             | n/x/o   | Flash jump (label-jump anywhere visible)      |
| `S`             | n/x/o   | Flash treesitter (jump to AST nodes)          |
| `r`             | o       | Remote flash                                  |
| `R`             | o/x     | Treesitter search                             |
| `Ctrl-s`        | command | Toggle flash search                           |

### Surround — mini.surround

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `gsa`           | Add surround                                      |
| `gsd`           | Delete surround                                   |
| `gsr`           | Replace surround                                  |
| `gsf` / `gsF`   | Find right / left surround                        |
| `gsh`           | Highlight surround                                |
| `gsn`           | Update `n_lines`                                  |

### Text objects — mini.ai (additions on top of vim defaults)

| Object | What it selects (with `i`/`a`)                    |
|--------|---------------------------------------------------|
| `f`    | Function (treesitter)                             |
| `c`    | Class                                             |
| `a`    | Parameter / argument                              |
| `b`    | Block                                             |
| `o`    | Conditional (if/else)                             |
| `l`    | Loop                                              |

E.g. `vif` selects inner function, `daa` deletes around argument.

### Treesitter — incremental selection

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `gnn`           | Init selection                                    |
| `grn`           | Expand to next node                               |
| `grc`           | Expand to next scope                              |
| `grm`           | Shrink                                            |

### Completion — blink.cmp

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `Ctrl-Space`    | Show / show docs / hide docs                      |
| `Ctrl-e`        | Hide                                              |
| `Enter`         | Accept (fallback to default Enter)                |
| `Tab` / `S-Tab` | Next / previous, snippet jump                     |
| `Ctrl-b` / `Ctrl-f` | Scroll documentation                          |

### Copilot — copilot.lua

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `Alt-l`         | Accept suggestion                                 |
| `Alt-k`         | Accept word                                       |
| `Alt-j`         | Accept line                                       |
| `Alt-]` / `Alt-[` | Next / previous suggestion                      |
| `Ctrl-]`        | Dismiss                                           |
| `Alt-Enter`     | Open Copilot panel                                |

> Note: `Alt-j` / `Alt-k` collide with the line-move bindings in `keymaps.lua`. In insert mode, copilot wins when a suggestion is showing; otherwise lines move.

### Snacks — notifications + reference jumping

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `<leader>un`    | Dismiss notifications                             |
| `<leader>nh`    | Notification history                              |
| `]]` / `[[`     | Next / previous reference (word under cursor)     |

### Which-key groups

`<leader>` groups defined for which-key popups: `c` code · `d` debug/diagnostics · `g` git/goto · `l` list/lsp · `n` notifications · `t` test · `u` ui.

---

## zsh

Source: [`zsh/.zshrc`](../zsh/.zshrc)

### History search

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `↑` / `↓`       | `history-substring-search` up/down (matches what you've typed) |
| `Ctrl-r`        | atuin search popup                                |

`atuin` is initialized with `--disable-up-arrow` so the arrows keep using `zsh-history-substring-search`.

### fzf widgets (default fzf zsh integration)

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `Ctrl-t`        | Insert file path (fuzzy)                          |
| `Ctrl-r`        | (overridden by atuin — see above)                 |
| `Alt-c`         | `cd` into a fuzzy-picked directory                |
| `**<Tab>`       | Trigger fuzzy completion for a token              |

### Aliases

`g <alias>` runs gitconfig aliases (e.g. `g st`). The OMZ-style shorthands below mirror the verbose originals:

| Alias           | Expands to                                        |
|-----------------|---------------------------------------------------|
| `g`             | `git`                                             |
| `gst`           | `git status`                                      |
| `gco`           | `git checkout`                                    |
| `gp`            | `git push origin HEAD`                            |
| `gpu`           | `git pull origin`                                 |
| `gb` / `gba`    | `git branch` / `git branch -a`                    |
| `gc` / `gca`    | `git commit -m` / `git commit -a -m`              |
| `gcad`          | `git commit -a --amend`                           |
| `gcoall`        | `git checkout -- .`                               |
| `gadd` / `ga`   | `git add` / `git add -p`                          |
| `gdiff`         | `git diff`                                        |
| `gr` / `gre`    | `git remote` / `git reset`                        |
| `glog`          | Pretty graph log                                  |
| `la`            | `tree`                                            |
| `cat`           | `bat`                                             |
| `ls` / `lsa`    | `eza -lh --group-directories-first --icons` / `ls -a` |
| `lt` / `lta`    | `eza --tree --level=2 --long --icons --git` / `lt -a` |
| `..`/`...`/`....` | `cd ..` / `cd ../..` / `cd ../../..`            |
| `d`             | `docker`                                          |
| `r`             | `rails`                                           |
| `c` / `cc`      | `claude` / `claude --enable-auto-mode`            |
| `t`             | `tmux attach \|\| tmux new -s Work`               |
| `cl`            | `clear`                                           |
| `lzd`           | `lazydocker`                                      |
| `ff`            | `fzf --preview 'bat --style=numbers --color=always {}'` |
| `eff`           | `$EDITOR "$(ff)"` — edit fzf-picked file          |

### Functions

| Function        | Action                                            |
|-----------------|---------------------------------------------------|
| `n [path…]`     | `nvim .` if no args, else `nvim "$@"`             |
| `tdl` / `tdlm` / `tsl` | tmux layout helpers — see [tmux > Shell helpers](#shell-helpers-zsh-functions) |
| `z <pat>`       | `zoxide` jump to frecent dir                      |
| `zi`            | `zoxide` interactive (fzf picker)                 |

---

## ghostty

Source: [`ghostty/.config/ghostty/config`](../ghostty/.config/ghostty/config)

The config doesn't override Ghostty's keybindings — defaults apply. A few relevant ones:

| Binding         | Action                                            |
|-----------------|---------------------------------------------------|
| `Cmd-t`         | New tab                                           |
| `Cmd-w`         | Close tab/window                                  |
| `Cmd-d`         | Split right                                       |
| `Cmd-Shift-d`   | Split down                                        |
| `Cmd-[` / `]`   | Previous / next split                             |
| `Cmd-+` / `Cmd--` | Increase / decrease font size                   |
| `Cmd-Enter`     | Toggle fullscreen                                 |

Behavior tweaks worth knowing:

- Font: JetBrainsMono Nerd Font 12pt, P3 colorspace, Carbonfox theme
- `notify-on-command-finish = unfocused` — long-running commands ping when the window isn't focused
- `clipboard-paste-protection = on` — prompts before pasting unsafe content
- `mouse-hide-while-typing = on`
