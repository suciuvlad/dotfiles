# Hotkeys

Every binding documented here is extracted from a config file in this repo. When in doubt, the config wins.

- **tmux prefix:** `Ctrl-a` (rebound from default `Ctrl-b`)
- **herdr prefix:** `Ctrl-a` (rebound from default `Ctrl-b`, same as tmux)
- **neovim leader:** `,` (both `mapleader` and `maplocalleader`)

---

## macOS keyboard

Source: [`launchagents/Library/LaunchAgents/com.vladsuciu.keyremap.plist`](../launchagents/Library/LaunchAgents/com.vladsuciu.keyremap.plist)

| Binding    | Action                                                                |
|------------|-----------------------------------------------------------------------|
| `CapsLock` | `Escape` — system-wide remap via `hidutil`, applies to every keyboard |

System-level: the keystroke is rewritten in IOKit before any app sees it, so it works in nvim, terminals, browsers, IDEs alike. Loaded by `make agents`; re-applied at every login by the LaunchAgent (`hidutil` mappings reset on logout/reboot, hence the agent).

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

## herdr

Source: [`herdr/.config/herdr/config.toml`](../herdr/.config/herdr/config.toml)

Agent-oriented multiplexer, keymap ported from `.tmux.conf`. Vocabulary maps 1:1 onto tmux:
**workspace** ≈ session, **tab** ≈ window, **pane** ≈ pane. Validate edits with `herdr config check`,
apply to a live server with `herdr server reload-config`.

### Quick start

```sh
h                           # from Ghostty: launches herdr, or attaches if already running
cd ~/code/foo && hdl c      # from inside a pane: nvim left, claude right, terminal bottom
```

`h` once per terminal, `hdl` once per project — `hdl` refuses to run outside a herdr pane
(it checks `$HERDR_ENV`). For a second project don't re-run `h`; open a tab (`prefix c`) or a
workspace (`prefix N`), `cd`, then `hdl` again.

Closing the terminal is safe — the server is headless and keeps running with its agents. Reopen and
type `h`. `prefix d` is the deliberate form of the same thing. After a *server* restart (reboot,
`herdr update`) the layout returns from `~/.config/herdr/session.json` and Claude panes reopen into
their original conversations via the persisted session refs — but pane processes do not survive, so a
dev server or long build is gone.

| Situation                        | What to type                                    |
|----------------------------------|-------------------------------------------------|
| Start of day                     | `h`                                             |
| Something pinged you             | `prefix o` — jumps to the agent that notified   |
| New project layout               | `prefix c`, `cd …`, `hdl c`                     |
| Several repos at once            | `hdlm c` from the parent directory              |
| Same task, N agents              | `hsl 4 cc`                                      |
| Changed `config.toml`            | `herdr config check` then `prefix R`            |

Not every tmux binding was worth porting. The prefix, the `|`/`_` splits and `prefix d` are tmux's;
the shift tier, pane cycling and resize are herdr's, because tmux's uppercase/lowercase pairing
(`c`/`C`, `k`/`K`) couldn't survive `prefix k` becoming pane-focus-up — and once that system breaks,
herdr's mnemonics (`N`=new, `D`=delete, `W`=workspace, `T`=tab, `X`=close tab) are the consistent ones.

### Workspaces (tmux sessions)

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `Alt-↑` / `Alt-↓`   | Previous / next workspace (no prefix, as in tmux)   |
| `prefix N`          | New workspace                                       |
| `prefix W`          | Rename current workspace                            |
| `prefix D`          | Close current workspace (with confirmation)         |
| `prefix w`          | Workspace picker — scales better than cycling past ~4 workspaces |

### Tabs (tmux windows)

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix c`          | New tab (no name prompt, matches tmux `bind c`)     |
| `prefix X`          | Close current tab — **not** `prefix k`, which is pane-focus-up here |
| `prefix p` / `n`    | Previous / next tab                                 |
| `prefix 1`–`9`      | Jump to tab N                                       |
| `prefix T`          | Rename tab                                          |

### Panes

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix \|`          | Split side-by-side (herdr calls this `split_vertical`) |
| `prefix _`          | Split stacked (`split_horizontal`)                  |
| `prefix Ctrl-T`     | Narrow 20% drawer on the right (shells out to `herdr pane split --ratio 0.8` — ratio is the *existing* pane's share) |
| `prefix h/j/k/l`    | Move between panes — **prefix-based**, unlike tmux  |
| `prefix Tab` / `Shift-Tab` | Cycle to next / previous pane                |
| `prefix z`          | Toggle pane zoom — `prefix Ctrl-A` is reserved (double-prefix sends a literal `Ctrl-a`) |
| `prefix r`          | Resize mode — enter once, then arrows/`hjkl` (tmux needed repeatable `prefix` + arrows) |
| `prefix x`          | Close pane                                          |
| `prefix ;`          | Jump to last pane                                   |
| `prefix [`          | Enter copy mode                                     |
| `prefix P`          | Rename pane                                         |

Pane focus stays behind the prefix on purpose: herdr has no `vim-tmux-navigator` passthrough, so
binding bare `Ctrl-h/j/k/l` would swallow the keys nvim uses for its own splits. The prefix-less
variant is commented in the config if that trade is ever worth making.

### Sidebar

Two halves: **spaces** on top, **agents** below. `prefix b` toggles the whole thing.

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix o`          | Jump to whatever just notified you — usually beats walking the list |
| `prefix g`          | Navigate mode: `↑`/`↓` walk spaces, `hjkl` walk panes |
| `prefix w`          | Space picker                                        |
| `prefix Shift-1`–`9`| Jump to space N (`prefix 1`–`9` is tabs)            |
| `prefix J` / `K`    | Next / previous agent — lowercase `hjkl` is panes, shift is the agent list |
| `prefix Alt-1`–`9`  | Focus agent N directly                              |

The agent half ships with **no** bindings at all (`next_agent`, `previous_agent` and `focus_agent` are
unbound, and navigate mode only covers spaces and panes), so the five above are additions rather than
ports. They matter because `agent_panel_sort = "priority"` turns that half into an attention queue.

### Misc

| Binding             | Action                                              |
|---------------------|-----------------------------------------------------|
| `prefix R`          | Reload `config.toml` — rare and deliberate, so `prefix r` goes to resize |
| `prefix d`          | Detach (tmux default, herdr ships `prefix q`)       |
| `prefix e`          | Edit scrollback in `$EDITOR`                        |
| `prefix G`          | New git worktree workspace                          |
| `prefix s` / `?`    | Settings / help                                     |

### Shell helpers (zsh functions)

Sourced from `herdr/.herdr-functions.zsh` — the tmux `tdl`/`tdlm`/`tsl` trio ported to the herdr CLI.
Both sets coexist; these only run inside a herdr pane (`$HERDR_ENV`).

| Command                       | Layout                                                       |
|-------------------------------|--------------------------------------------------------------|
| `hdl <ai> [<ai2>]`            | Dev layout: editor left, AI right (30%), terminal bottom (15%). Second AI splits the right column. |
| `hdlm <ai> [<ai2>]`           | Run `hdl` once per subdirectory, one tab each. Renames the workspace to the current dir. |
| `hsl <count> <command>`       | Swarm layout: tile `<count>` panes, run `<command>` in each. |

`herdr pane run` types into the pane's interactive login zsh, so aliases (`c`, `cc`, `k`, `kk`) expand
just like `tmux send-keys` did — and the installed agent integrations report real state regardless of
how the agent was launched.

Two herdr CLI behaviours these helpers work around, worth knowing if you script against it yourself:

- `--ratio` is the **existing** pane's share, the inverse of tmux's `-p N`. A 30% right-hand pane is `--ratio 0.7`.
- An empty or omitted pane target falls back to the **UI-focused** pane, which may not be yours. Every call passes an explicit id and bails instead of guessing.

### tmux settings with no herdr equivalent

`history-limit` (herdr caps scrollback in bytes via `[advanced] scrollback_limit_bytes`), copy-mode's
in-mode `v`/`y` (`prefix [` enters, but the keys inside aren't configurable), `bind -r` arrow resizing
(no `resize_pane_*` actions in 0.8.0 — `prefix r` resize mode covers it), `base-index`,
`renumber-windows`, `detach-on-destroy`, `escape-time`, `terminal-features`, and the TPM plugin list.
Catppuccin mocha carries over as `[theme] name = "catppuccin"`.

Two things the shipped `herdr --default-config` doesn't advertise, both verified against 0.8.0:
an action can take an **array** of bindings (`next_tab = ["prefix+n", "alt+right"]`), and
`herdr config check` reports unknown key names rather than ignoring them silently — so probing a
setting you saw in someone else's config with a deliberate bogus key alongside tells you whether your
build actually supports it.

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

### Move lines (Shift-Alt-j / Shift-Alt-k)

| Mode    | Binding                 | Action                        |
|---------|-------------------------|-------------------------------|
| Normal  | `S-Alt-j` / `S-Alt-k`   | Move current line down / up   |
| Insert  | `S-Alt-j` / `S-Alt-k`   | Same, stays in insert         |
| Visual  | `S-Alt-j` / `S-Alt-k`   | Move selection, re-select     |

Plain `Alt-j` / `Alt-k` are reserved for copilot accept-line / accept-word — see below.

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

Line-move uses `Shift-Alt-j` / `Shift-Alt-k` instead of plain Alt to avoid clashing with these.

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
| `c` / `cc`      | `claude` / `claude --permission-mode auto`        |
| `t`             | `tmux attach \|\| tmux new -s Work`               |
| `h`             | `herdr` — launches or attaches the persistent session |
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
