# Setup

This repo is a [GNU Stow](https://www.gnu.org/software/stow/) farm: every top-level directory is a "package" whose contents mirror `$HOME`. `stow -t ~ zsh` symlinks `zsh/.zshrc` to `~/.zshrc`. That's the entire trick.

Provisioning (Homebrew, runtimes, SSH key, macOS defaults, iTerm2) lives in `scripts/`. There is one entry script (`bootstrap.sh`) for first-time setup and a `Makefile` for re-running individual steps.

## Fresh Mac (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/main/bootstrap.sh | bash
```

What it does, in order:

1. **Xcode Command Line Tools** — installs if missing (system dialog appears).
2. **Homebrew** — installs if missing.
3. **`git` + `stow`** — installed via brew so we can clone and symlink.
4. **Clone** to `~/dotfiles`. Tries SSH first (in case GitHub is already authorized on this Mac); falls back to HTTPS.
5. **Stow** all 13 packages into `$HOME`. If any existing real files conflict (e.g. a hand-written `~/.zshrc` from a previous setup), they're moved to `~/.dotfiles-backup-<timestamp>/` first so stow can proceed cleanly.
6. **`make all`** — runs the full provisioning chain.

It is idempotent. Re-running it on a partially-set-up machine just fills in what's missing.

## `make all` — the provisioning chain

`make all` runs nine steps. Each is independently re-runnable:

| Target              | Re-run with            | What it does                                                                        |
|---------------------|------------------------|-------------------------------------------------------------------------------------|
| `make brew`         | `~/.bin/macoss brew`   | Strict `Brewfile` (CLI core), then best-effort `Brewfile.optional` (casks, MAS).    |
| `make ssh`          | `~/.bin/macoss ssh`    | Generates `~/.ssh/id_ed25519`, writes `~/.ssh/config`, prints public key for GitHub. Auto-switches dotfiles remote from HTTPS→SSH once registered. Runs before `runtimes` so the key exists before anything clones from GitHub. |
| `make runtimes`     | `~/.bin/macoss runtimes` | `mise install` for `~/.tool-versions` (node, go, python, ruby).                  |
| `make defaults`     | `~/.bin/macoss defaults` | Applies `defaults write` settings (Finder, Dock, screenshots, keyboard repeat, …). Requires sudo. Sandboxed domains (Mail, App Store) are skipped with a warning unless the terminal has Full Disk Access — grant it and re-run to apply those. |
| `make iterm`        | `~/.bin/macoss iterm`  | Installs iTerm2 shell integration (appends a source line to `~/.zshrc`).            |
| `make agents`       | `~/.bin/macoss agents` | Loads `~/Library/LaunchAgents/*.plist` via `launchctl bootstrap` (e.g. CapsLock→Escape via `hidutil`). |
| `make skills`       | `~/.bin/macoss skills` | Symlinks AI-agent skills from the stowed `~/.agents/skills` store into `~/.cursor/skills` and `~/.codex/skills` (see [AI-agent skills](#ai-agent-skills)). |
| `make ai-clis`      | `~/.bin/macoss ai-clis` | Installs the AI CLIs that aren't brew or mise packages — `claude` (native installer) and `kimi`; verifies mise-managed `codex`. |
| `make herdr`        | `~/.bin/macoss herdr`  | Installs herdr's per-agent state integrations (the hooks that report `idle`/`working`/`blocked`/`done` to its sidebar), and keeps `~/.config/herdr` a real directory so stow can't fold herdr's runtime state into the repo. The binary itself comes from the strict `Brewfile` (`linux-pkgs` on Linux). Agents that aren't installed are skipped; an installed CLI that has never run gets its config dir created so the hook can land. |

Each step appends its result to `~/.local/state/dotfiles/results.jsonl` (the
full log goes to `~/.local/state/dotfiles/install.log`). If a run dies partway,
`make status` reads that state, cross-checks each step against the live machine
(brew bundle satisfied? SSH key accepted by GitHub? runtimes present?), and
prints what ran, what didn't, and the exact commands to resume — including a
ready-made `brew install --cask --adopt …` line for casks that failed because
the app was already in `/Applications`.

### Full Disk Access (for the Mail / App Store defaults)

macOS sandboxes some preference domains under `~/Library/Containers`; `defaults
write` can only touch them if the terminal has Full Disk Access. `make defaults`
skips those with a warning rather than failing. To apply them:

1. Open the pane: `open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"`
   (or System Settings → Privacy & Security → Full Disk Access).
2. Toggle your terminal (Ghostty / iTerm2 / Terminal) on — use **+** to add it
   from `/Applications` if it isn't listed.
3. Quit the terminal fully (⌘Q) and reopen — the grant only applies at launch.
4. Re-run `make -C ~/dotfiles/scripts defaults`.
5. Optionally toggle the access back off afterwards; applied settings persist.

`~/.bin/macoss` is just a shim: `exec make -C ~/dotfiles/scripts "${@:-all}"`.

Run `make help` from `scripts/` for the full listing.

## After `make all` — the SSH dance

`make ssh` prints a public key and pauses. Register it on GitHub at <https://github.com/settings/keys> **twice**:

- once as an **Authentication Key** (push/pull),
- once as a **Signing Key** (so signed commits show "Verified").

Then press ENTER. The script verifies GitHub access via `ssh -T` and switches the dotfiles remote from HTTPS to SSH. If you skip the prompt, re-run `make ssh` later.

## Linux (headless agent VMs)

The agent VMs in the home-infra build run these configs without Homebrew,
launchd, or any macOS step. `make linux` is a **parallel chain** — deliberately
not a step inside `install.sh`, and `make status` stays macOS-only.

```sh
git clone https://github.com/suciuvlad/dotfiles ~/dotfiles
cd ~/dotfiles/scripts && make linux
```

| Target            | What it does                                                                                           |
|-------------------|--------------------------------------------------------------------------------------------------------|
| `make linux`      | Full chain: `linux-pkgs` → `stow-linux` → `linux-shell` → `runtimes` → `ai-clis` → `herdr` → `skills`. |
| `make stow-linux` | Stows `LINUX_PACKAGES` — everything except `ghostty` (macOS terminal) and `launchagents` (launchd).    |
| `make linux-pkgs` | The `Brewfile` equivalent: apt base, `mise` + `herdr` installers, modern CLIs through mise's `ubi:` backend, zsh plugins cloned to `~/.local/share/zsh/plugins`. |
| `make linux-shell`| `chsh` to zsh for the current user. Runs after `stow-linux` so the shell it switches to has a `.zshrc`. |

Order: `linux-pkgs` first because it installs `stow`; `skills` last because
`herdr` creates `~/.codex`, which `agent-skills.sh` links into. Off macOS the
Makefile also prepends `~/.local/bin` to `PATH` for every recipe: the
installers put mise, herdr and claude there mid-run, and `make` captured `PATH`
before they existed.

`linux-pkgs` splits its mise tools the way the Brewfiles split: essentials
(nvim, fzf, starship, atuin, eza, delta, gh) fail the step; the rest (lazygit,
lazydocker, yazi, dust, gum, grype) are reported and skipped. Re-run to retry.
They land in mise's global config (`~/.config/mise/config.toml`), not in the
stowed `~/.tool-versions`, which macOS shares and where brew already provides
them. The arrays in `linux-pkgs.sh` are the source of truth.

**Skipped on Linux, deliberately:**

- `brew` — no second package manager on a server. apt plus mise covers the list.
- `defaults`, `iterm`, `agents` — macOS and launchd only.
- `docker` — a machine-level service. The VM template (cloud-init) owns it;
  dotfiles own the user environment.
- `ssh` — keys are per-machine. Generating one inside a VM **template** hands
  every clone the same private key. Run `make ssh` on the clone, never on the
  template — and before any agent commits there: `git/.gitconfig` signs every
  commit with `~/.ssh/id_ed25519.pub`, so until the key exists `git commit`
  fails with "Couldn't load public key". `ssh.sh` itself is portable; its
  keychain lines are macOS-only and guarded.

**Debian binary names.** `bat` and `fd` install as `batcat` and `fdfind`.
`linux-pkgs.sh` symlinks both into `~/.local/bin` rather than aliasing them in
the shell, so scripts and agents resolve them too.

**GitHub API limit.** Every `ubi:` tool is an unauthenticated GitHub API
lookup, and the limit is 60 per hour per IP. Rebuilding the template a few
times inside an hour exhausts it and `linux-pkgs` reports
`mise use failed: … rate limit`. `export MISE_GITHUB_TOKEN=…` before
`make linux` lifts it.

**Login shell.** Cloud images hand the default user `bash`, and nothing in
`zsh/` runs until that changes. `make linux-shell` runs `chsh -s zsh` for the
current user, after `stow-linux`, so the first zsh login already has its
`.zshrc` instead of the new-user wizard.

### One `.zshrc`, two plugin prefixes

`zsh/.zshrc:37-43` picks the plugin prefix by `$OSTYPE`: Homebrew's
`/opt/homebrew/share` on macOS, `~/.local/share/zsh/plugins` elsewhere — the
one directory `linux-pkgs.sh` clones all four plugins into, so the branch is a
single variable rather than four distro-specific paths. Only `zsh-completions`
differs in layout (brew flattens `src/` into the share dir), which is why the
completions dir is its own variable. Every `source` line is still guarded by
`[ -f ]`, so a missing plugin degrades silently; the other macOS-only lines
(`DYLD_FALLBACK_LIBRARY_PATH`, the iTerm2 integration) are guarded the same
way.

`~/.local/bin` is on `PATH` from both `.zprofile` and `.zshrc` — mise, herdr,
claude and the Debian symlinks all land there.

### mise: shims in `.zprofile`, hook in `.zshrc`

`mise activate` is a prompt hook, so it only fires in **interactive** shells.
Agents spawn plenty that aren't, and those would get the system `node`.
`zsh/.zprofile` puts mise's shims on `PATH` for login shells, and everything
they spawn inherits it. `.zshrc` layers the hook on top for interactive use,
where it takes precedence — its per-directory tool paths sort before the shims.
One-shot `ssh agent01 cmd` is neither login nor interactive and reads only
`~/.zshenv`, so it sees neither; move both lines there if that matters.

Note `mise reshim` is needed after anything installs executables outside
mise's knowledge (`npm i -g`), or the new CLI appears not to exist.

A Mac that already has a hand-written `~/.zprofile` (the Codex installer
writes one) blocks `stow -R -t ~ zsh` until the file is moved aside. Its usual
content — `~/.local/bin` on `PATH` — is already covered by the stowed one.

## Brewfiles

Two files, two policies:

| File                              | Behavior                                                                                              |
|-----------------------------------|-------------------------------------------------------------------------------------------------------|
| `scripts/Brewfile`                | **Strict.** Core CLI + zsh plugins. `brew bundle` runs it; failure aborts `make brew`.                |
| `scripts/Brewfile.optional`       | **Best-effort.** Casks, dev tools, niche CLIs, MAS apps. `brew-optional.sh` runs it; failures are summarized but don't abort. |

Add new strictly-required CLI to `Brewfile`. Add anything that might be renamed, region-locked, or non-essential (casks especially) to `Brewfile.optional`.

`zsh/.zshrc` exports `HOMEBREW_VERIFY_ATTESTATIONS=1`, so every bottle install/upgrade verifies a Sigstore attestation proving the binary was built by Homebrew's official CI. Tampered bottles in storage are rejected before install.

## AI-agent skills

All agent skills (Claude Code, Cursor, Codex) live in **one git-tracked store**: `agents/.agents/skills/`, stowed to `~/.agents/skills`. Agent directories never hold real skill content, only symlinks:

- `~/.claude/skills/<name>` → `../../../../.agents/skills/<name>` — these relative symlinks live *inside the repo* (`claude/.claude/skills/`) and are themselves git-tracked, so Claude's skill selection survives a fresh clone with zero extra steps.
- `~/.cursor/skills` and `~/.codex/skills` are runtime dirs (not stowed), so `make skills` (`scripts/setup/agent-skills.sh`) recreates their symlinks. Per-agent skill lists live at the top of that script; edit them to change which skills an agent sees.

Installing a new skill from [skills.sh](https://www.skills.sh/):

```sh
npx skills add <owner/repo> -g        # writes into ~/.agents/skills + symlinks ~/.claude/skills
cd ~/dotfiles && git add agents claude/.claude/skills && git commit
```

Because `~/.agents` is a stow symlink into the repo, the CLI's output lands directly in git's working tree — `git status` shows the new skill ready to commit. Skills not from skills.sh follow the same pattern: drop the folder in `agents/.agents/skills/` and symlink it where needed.

## Stow workflow

| Action                          | Command (run from `~/dotfiles`)         |
|---------------------------------|-----------------------------------------|
| Install everything              | `stow -t ~ */`                          |
| Install one package             | `stow -t ~ nvim`                        |
| Refresh after adding/removing files | `stow -R -t ~ nvim`                 |
| Refresh everything              | `stow -R -t ~ */`                       |
| Uninstall a package             | `stow -D -t ~ nvim`                     |

**Always re-stow with `-R` after adding or deleting files inside a package** — that's how stow stays in sync and avoids dangling symlinks.

## Maintenance

| Command                | What it does                                                                                          |
|------------------------|-------------------------------------------------------------------------------------------------------|
| `make check`           | Audits broken symlinks, required CLI tools, Brewfile satisfaction, git identity, stow packages.      |
| `make lint`            | Runs `shellcheck` on `scripts/setup/*.sh`, `scripts/.bin/macoss`, and `bootstrap.sh`.                 |

Run `make check` after pulling, after `stow -R`, or whenever something feels off.

## Updating

```sh
cd ~/dotfiles && git pull && stow -R -t ~ */
```

If the Brewfile changed, also run `make brew` to install new packages.

## Troubleshooting

### `Brewfile.optional` shows zero installs

Symptom: `brew bundle check --file=Brewfile.optional` lists every cask as missing even after `make all` ran successfully.

Cause: the optional installer (`scripts/setup/brew-optional.sh`) catches failures silently — if something killed the run early (network blip, sudo timeout, the very first cask hanging on a permission prompt), the rest never happen.

Fix: re-run it. It's idempotent.

```sh
make -C ~/dotfiles/scripts brew
```

Watch the live output — failures are logged as `✗ cask <name>` and summarized at the end. Anything that legitimately fails (sudo-prompted casks like `nordvpn`, region-locked MAS apps) you can install manually.

### iTerm2 line modifying `zsh/.zshrc`

`make iterm` runs the upstream iTerm2 shell-integration installer, which appends a `source ~/.iterm2_shell_integration.zsh` line to `~/.zshrc`. Since `~/.zshrc` is a stow symlink to `zsh/.zshrc`, the appended line ends up in the **repo file** and shows in `git status`. Either commit it or revert — it's harmless either way.

### `make ssh` non-interactive

If `make ssh` runs without a TTY (e.g., piped from `bootstrap.sh`), it skips the verification prompt and prints the manual command to switch the remote later. Re-run `make ssh` from a real terminal once the key is registered.

### Broken symlinks after deleting a stow file

If you `rm` a file from a stow package directly, stow's symlink to that file is now dangling. Run `stow -R -t ~ <package>` to clean it up. `make check` flags broken symlinks pointing into `~/dotfiles`.

## File layout

```
dotfiles/
├── bootstrap.sh                    # one-shot fresh-Mac entry point
├── scripts/                        # provisioning (not stowed into $HOME the same way as configs)
│   ├── Makefile                    # all/brew/ssh/runtimes/defaults/iterm/status/check/lint + linux chain
│   ├── Brewfile                    # strict: core CLI + zsh plugins
│   ├── Brewfile.optional           # best-effort: casks, MAS, niche CLIs
│   ├── setup/                      # ssh.sh, defaults.sh, iterm.sh, agents.sh, agent-skills.sh, brew-optional.sh, linux-pkgs.sh
│   └── .bin/                       # macoss, tmuxinator.zsh — the only part stowed (~/.bin/); .stow-local-ignore keeps Makefile/Brewfile/setup out of ~
├── agents/                         # ~/.agents/skills — central AI-agent skill store
├── claude/    ghostty/    git/     herdr/   launchagents/  mise/
├── nvim/      shell/      starship/   tmux/    zsh/
└── docs/                           # this manual
```
