# Shell tools

Single-purpose CLI utilities sourced from [`scripts/Brewfile`](../scripts/Brewfile). Most are `eval`-wired into [`zsh/.zshrc`](../zsh/.zshrc); the file:line of the wiring is noted under each entry.

---

### `atuin`
Searchable, syncable shell history. Replaces `Ctrl-r`.

**Killer commands**
- `Ctrl-r` — fuzzy search across all your history (and across machines if synced)
- `atuin import auto` — pull existing `.zsh_history`
- `atuin stats` — what you actually ran this month
- `atuin login` / `atuin sync` — opt-in cross-machine sync (E2E encrypted)

**Config:** `zsh/.zshrc:144` (`atuin init zsh --disable-up-arrow` — keeps `↑` for substring search)
**Upstream:** <https://atuin.sh>

---

### `bat`
`cat` with syntax highlighting, line numbers, and git-diff gutter. Aliased to `cat` in this repo.

**Killer commands**
- `bat <file>` — pretty print
- `bat --plain <file>` — no decorations (closer to real cat)
- `bat -p` — plain, no paging (good for piping)
- Used as fzf preview: `fzf --preview 'bat --style=numbers --color=always {}'` (see `ff` alias)

**Config:** `zsh/.zshrc:83` (`alias cat=bat`)
**Upstream:** <https://github.com/sharkdp/bat>

---

### `direnv`
Per-directory environment variables via `.envrc`. Pairs with `mise` for project-scoped tool versions.

**Killer commands**
- `direnv allow` — trust the current `.envrc`
- `direnv edit` — edit the current `.envrc` and auto-allow on save
- `direnv reload` — re-source after manual changes

**Config:** `zsh/.zshrc:141` (`eval "$(direnv hook zsh)"`)
**Upstream:** <https://direnv.net>

---

### `eza`
Modern `ls` with icons, git status, and tree mode. Aliased to `ls`/`lt` here.

**Killer commands**
- `ls` → `eza -lh --group-directories-first --icons=auto`
- `lsa` → `ls -a`
- `lt` → `eza --tree --level=2 --long --icons --git`
- `lta` → `lt -a`

**Config:** `zsh/.zshrc:97-100` (aliases); completions at `~/.config/eza/completions/zsh` (added to FPATH at `zsh/.zshrc:25`)
**Upstream:** <https://eza.rocks>

---

### `fd`
`find` replacement: regex by default, fast, gitignore-aware.

**Killer commands**
- `fd <pattern>` — recursive find from cwd
- `fd -e ts` — by extension
- `fd -H` — include hidden
- `fd -t d <pat>` — directories only

Used by fzf-lua in nvim with: `--type f --hidden --follow --exclude .git --exclude node_modules --exclude vendor`.

**Upstream:** <https://github.com/sharkdp/fd>

---

### `fzf`
General-purpose fuzzy finder. Powers `Ctrl-t`, `Alt-c`, `**<Tab>`, the `ff` alias, and many nvim integrations.

**Killer commands**
- `Ctrl-t` — insert path
- `Alt-c` — cd into fuzzy-picked dir
- `**<Tab>` — trigger fuzzy completion mid-token
- `ff` — pick file with bat preview
- `eff` — pick file and open in `$EDITOR`
- `command | fzf` — pipe anything in

**Config:** `zsh/.zshrc:135` (`source <(fzf --zsh)`)
**Upstream:** <https://github.com/junegunn/fzf>

---

### `gh`
GitHub CLI: PRs, issues, runs, releases, gists, repo creation, all without leaving the terminal.

**Killer commands**
- `gh pr create` / `gh pr view` / `gh pr checkout <num>`
- `gh pr list --author @me`
- `gh run watch` — live-tail the latest CI run
- `gh issue list --assignee @me`
- `gh repo clone <user/repo>`
- `gh auth login` — first-time setup

**Upstream:** <https://cli.github.com>

---

### `git-delta`
Side-by-side diff viewer with syntax highlighting. Wired into git as the pager.

**Where it shows up**
- `git diff`, `git log -p`, `git show` — automatic
- `git add -p` (and `ga` alias) — colored diffs

**Config:** `git/.gitconfig:36-44` (`pager = delta`, `interactive.diffFilter`, `[delta]` section with side-by-side + line numbers)
**Upstream:** <https://github.com/dandavison/delta>

---

### `gum`
`charm.sh`-flavored prompts and styled output for shell scripts.

**Killer commands**
- `gum confirm "do thing?" && do-thing`
- `gum choose option1 option2 option3`
- `gum input --placeholder "name"`
- `gum spin --title "loading…" -- sleep 3`
- `gum style --foreground 212 "fancy"`

**Upstream:** <https://github.com/charmbracelet/gum>

---

### `jq`
JSON processor.

**Killer commands**
- `jq .` — pretty-print
- `jq '.foo.bar'` — extract field
- `jq '.[] | .name'` — map over array
- `jq -r '.[].id'` — raw output (no quotes), one per line
- `gh pr list --json number,title | jq '.[] | "#\(.number) \(.title)"'`

**Upstream:** <https://jqlang.github.io/jq/>

---

### `mise`
Polyglot version manager (replacement for asdf, nvm, rbenv, pyenv, goenv). Reads `.tool-versions`.

**Killer commands**
- `mise install` — install everything in `~/.tool-versions`
- `mise use node@22` — pin a project to node 22 (writes `.tool-versions`)
- `mise use -g python@3.13` — set global default
- `mise current` — show active versions
- `mise upgrade` — bump all to latest

**Config:** `mise/.tool-versions` (`node lts`, `go latest`, `python 3.13`, `ruby latest`); activated at `zsh/.zshrc:132`
**Upstream:** <https://mise.jdx.dev>

---

### `ripgrep` (`rg`)
Fastest grep. Respects `.gitignore` by default.

**Killer commands**
- `rg pattern` — recursive grep from cwd
- `rg -t ts pattern` — limit to typescript files
- `rg -l pattern` — list matching files only
- `rg -i pattern` — case-insensitive
- `rg --hidden -g '!.git' pattern` — include hidden, exclude `.git`

Used by fzf-lua live-grep with: `--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g "!{.git,node_modules,vendor}/*"`.

**Upstream:** <https://github.com/BurntSushi/ripgrep>

---

### `shellcheck`
Static analysis for shell scripts. Wired into `make lint`.

**Killer commands**
- `shellcheck script.sh`
- `shellcheck -x script.sh` — follow `source` directives
- `make lint` (from `scripts/`) — runs over `setup/*.sh`, `macoss`, `bootstrap.sh`

**Config:** `scripts/Makefile:87-90`
**Upstream:** <https://www.shellcheck.net>

---

### `starship`
Cross-shell prompt. Configured to be minimal-left / right-aligned info.

**Layout**
- Left: `directory` + character (`➜` green/red, `[N] >>>` in vi-mode)
- Right: git branch + status + package version + cmd duration (≥2s) + hostname (when SSH)

**Config:** `starship/.config/starship.toml`; activated at `zsh/.zshrc:129`
**Upstream:** <https://starship.rs>

---

### `tldr`
Crowd-sourced cheatsheets. The "I forgot the syntax" tool.

**Killer commands**
- `tldr <command>` — show common usage examples
- `tldr -u` — update the cache

**Upstream:** <https://tldr.sh>

---

### `tree`
Directory tree printer. Aliased to `la`.

**Killer commands**
- `la` → `tree`
- `tree -L 2` — limit depth
- `tree -a` — include hidden
- `tree -I 'node_modules|.git'` — exclude patterns

**Config:** `zsh/.zshrc:82` (`alias la=tree`)
**Upstream:** <http://mama.indstate.edu/users/ice/tree/>

---

### `zoxide`
Smarter `cd`. Learns frequently-visited directories.

**Killer commands**
- `z <partial>` — jump to frecent match (`z dot` → `~/dotfiles`)
- `z foo bar` — multi-keyword match
- `zi` — interactive picker (fzf)

**Config:** `zsh/.zshrc:138` (`eval "$(zoxide init zsh)"`)
**Upstream:** <https://github.com/ajeetdsouza/zoxide>

---

### `dust`
`du` replacement: visual, sorted, fast.

**Killer commands**
- `dust` — current dir, biggest first
- `dust -d 2` — limit depth
- `dust -r` — reverse sort

**Upstream:** <https://github.com/bootandy/dust>

---

### Zsh plugins

Sourced in this order in `zsh/.zshrc:37-55`. The prefix is `/opt/homebrew/share`
on macOS and `~/.local/share/zsh/plugins` on the Linux agent VMs, where
`scripts/setup/linux-pkgs.sh` clones them (see [01-setup](01-setup.md#one-zshrc-two-plugin-prefixes)):

| Plugin                              | What it does                                          |
|-------------------------------------|-------------------------------------------------------|
| `zsh-completions`                   | Adds completions to fpath (must come before `compinit`) |
| `zsh-autosuggestions`               | Inline suggestion of past commands; accept with `→`   |
| `zsh-history-substring-search`      | `↑`/`↓` matches by substring of what you've typed     |
| `zsh-syntax-highlighting`           | Live coloring of commands as you type (sourced **last**) |

Order matters: syntax-highlighting must be last, completions must be on fpath before `compinit`.

---

### `tmuxinator`
YAML-defined tmux layouts. Currently mostly superseded by the `tdl`/`tdlm`/`tsl` shell functions, but kept for project-scoped layouts.

**Killer commands**
- `tmuxinator new <name>` — scaffold a project config
- `mux <name>` (alias) — start a project layout
- `tmuxinator edit <name>` — edit a config

**Config:** `scripts/.bin/tmuxinator.zsh` (stowed to `~/.bin/tmuxinator.zsh`)
**Upstream:** <https://github.com/tmuxinator/tmuxinator>

---

### `reattach-to-user-namespace`
macOS-specific shim that re-attaches tmux to the user namespace so `pbcopy`/`pbpaste` and notifications work from inside tmux. Used implicitly — you don't call it directly.

**Upstream:** <https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard>

---

### `mas`
Mac App Store CLI. Used by `Brewfile.optional` to install Magnet, Bear, Todoist.

**Killer commands**
- `mas list` — what's installed via MAS
- `mas search <name>` — find an app + ID
- `mas install <id>` — install by ID
- `mas upgrade` — upgrade all MAS apps

**Upstream:** <https://github.com/mas-cli/mas>

---

### `pnpm` / `yarn`
Alternate node package managers. `pnpm` for content-addressed dedup (saves disk on monorepos); `yarn` for projects that demand it.

**Killer commands**
- `pnpm install`, `pnpm add <pkg>`, `pnpm dlx <pkg>` (one-shot exec)
- `yarn install`, `yarn add <pkg>`

**Config:** `PNPM_HOME=~/Library/pnpm` and `BUN_INSTALL=~/.bun` exported at `zsh/.zshrc:12-13`, both on PATH.
**Upstream:** <https://pnpm.io> · <https://yarnpkg.com>

---

### `postgresql@17`
Full Postgres install (server + client tools). Started as a service when needed:

**Killer commands**
- `brew services start postgresql@17`
- `psql postgres` — connect to default DB
- `createdb <name>` / `dropdb <name>`
- `pg_dump <db> > backup.sql` / `psql <db> < backup.sql`

**Upstream:** <https://www.postgresql.org/docs/17/>
