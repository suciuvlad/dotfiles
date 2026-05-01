# TUIs

Full-screen terminal applications. Each one has its own keymap — the entries below cover the most-used commands; press `?` inside any of them for the in-app help.

---

### `lazygit`
Git porcelain as a TUI. The single best way to stage hunks, write commits, browse history, and resolve conflicts.

**Workflow**
- Open at repo root; left panel lists status + branches + commits + stash + diff.
- `<space>` to stage/unstage a file (or hunk in the diff panel).
- `c` to commit (`C` to commit with the editor for long messages).
- `P` to push, `p` to pull, `f` to fetch.
- `R` to refresh.
- `h` / `l` to switch panels; `?` for full keymap.

**Killer commands**
- `lazygit` — open in cwd
- `lzg` — common alias if you set one (this repo doesn't, but `lzd` exists for lazydocker)

**Upstream:** <https://github.com/jesseduffield/lazygit>

---

### `lazydocker`
Same idea as lazygit, for Docker. Browse containers, images, volumes, networks; tail logs; exec into shells.

**Workflow**
- `[` / `]` to switch tabs (containers, images, volumes, networks)
- `d` to remove, `s` to stop, `r` to restart
- `Enter` on a container → logs tail
- `e` → exec a shell

**Killer commands**
- `lazydocker` — open
- `lzd` — alias defined at `zsh/.zshrc:77`

**Upstream:** <https://github.com/jesseduffield/lazydocker>

---

### `btop`
System monitor. Replaces `top` / `htop`.

**Workflow**
- `1`–`4` toggle CPU / memory / network / processes panels
- `f` filter processes
- `Enter` on a process → details
- `t` toggle tree view
- `q` quit

**Killer commands**
- `btop` — open
- `btop -p 0` — preset 0 (full layout)

**Upstream:** <https://github.com/aristocratos/btop>

---

### `yazi`
Blazing-fast file manager. vim-keys, image previews, async loading, plugin system.

**Workflow**
- `h/j/k/l` move; selection follows cursor
- `<space>` mark; `v` enter visual mode for range marking
- `o` / `Enter` open
- `y` yank, `x` cut, `p` paste, `d` delete
- `r` rename, `a` create file/dir
- `:` command line
- `q` quit, `Q` quit and `cd` to current dir (needs the shell shim)

**Shell shim** — to make `Q` actually `cd` your shell, add to `~/.zshrc.local` (the per-machine override file):
```sh
function yy() {
  local tmp; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then builtin cd -- "$cwd"; fi
  rm -f -- "$tmp"
}
```
Then run `yy` instead of `yazi`.

**Upstream:** <https://yazi-rs.github.io>

---

### `neovim`
The editor. Configured as a full IDE: LSP, treesitter, fzf-lua, copilot, dap, gitsigns, fugitive, vim-test, snacks dashboard, which-key.

**First time**
- `nvim` — opens the snacks dashboard (`f` find, `g` grep, `r` recent, `c` config, `l` lazy, `q` quit)
- `:Lazy` — plugin manager UI; `U` updates everything, `R` rolls back
- `:Mason` — LSP/formatter installer UI
- `:checkhealth` — diagnose problems (missing tree-sitter parsers, broken plugins, etc.)

**Daily drivers** — see [Hotkeys › neovim](02-hotkeys.md#neovim) for the full keymap. Highlights:
- `<leader>f` find files · `<leader>lg` live grep · `<leader>n` file tree
- `<leader>gg` lazygit-equivalent (`:Git` from fugitive — but for hunk-staging, prefer `<leader>gs` from gitsigns)
- `<leader>tn` test nearest · `<leader>tf` test file
- `s<2 chars>` flash-jump anywhere visible

**Plugins of note**
- `lazy.nvim` — plugin manager (declarative spec in `lua/plugins/*.lua`)
- `snacks.nvim` — dashboard, notifier, statuscolumn, scope, words
- `which-key.nvim` — popup that shows keybindings as you type the prefix
- `flash.nvim` — better-than-easymotion label-jumping
- `mini.ai` + `mini.surround` — text objects + surround ops
- `blink.cmp` — completion (replaces nvim-cmp)
- `conform.nvim` — formatter dispatcher (prettier, stylua, gofmt, …)
- `nvim-treesitter` — incremental parsing for highlighting + folding + text objects
- `nvim-dap` + `nvim-dap-go` + `nvim-dap-ui` — debugger
- `vim-test` — `:TestNearest` etc., with `vimux`/`floaterm` strategies
- `vim-fugitive` + `vim-rhubarb` — git porcelain inside nvim
- `gitsigns.nvim` — gutter signs, hunk staging, blame
- `nvim-tree.lua` — sidebar file tree
- `trouble.nvim` — diagnostic / quickfix panel
- `vim-tmux-navigator` — `Ctrl-h/j/k/l` between nvim splits and tmux panes
- `copilot.lua` — Copilot suggestions

**Config:** `nvim/.config/nvim/`
**Upstream:** <https://neovim.io>

---

### `tmux`
Terminal multiplexer + persistent session manager.

**Why it's in the stack**
- Detach a session, reconnect from anywhere with `tmux attach`. Pairs well with `t` alias (`tmux attach || tmux new -s Work`).
- Multi-pane layouts with the `tdl`/`tdlm`/`tsl` helpers (see [Hotkeys › tmux](02-hotkeys.md#tmux)).
- Survives terminal app crashes; works the same over SSH.

**Daily drivers** — full keymap in [Hotkeys › tmux](02-hotkeys.md#tmux). Highlights:
- `prefix \|` / `prefix _` — split horizontal / vertical
- `prefix Ctrl-A` — toggle pane zoom
- `Alt-↑` / `Alt-↓` — switch sessions without prefix
- `Ctrl-h/j/k/l` — move between panes (also navigates into nvim splits)
- `tdl claude` — full dev layout in current dir

**Plugins** — installed via TPM. After editing `~/.tmux.conf`, reload with `prefix r`. Manage plugins with `prefix I` (install), `prefix U` (update).

**Config:** `tmux/.tmux.conf`, `tmux/.tmux-functions.zsh`
**Upstream:** <https://github.com/tmux/tmux>
