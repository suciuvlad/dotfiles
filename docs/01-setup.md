# Setup

This repo is a [GNU Stow](https://www.gnu.org/software/stow/) farm: every top-level directory is a "package" whose contents mirror `$HOME`. `stow -t ~ zsh` symlinks `zsh/.zshrc` to `~/.zshrc`. That's the entire trick.

Provisioning (Homebrew, runtimes, SSH key, macOS defaults, iTerm2) lives in `scripts/`. There is one entry script (`bootstrap.sh`) for first-time setup and a `Makefile` for re-running individual steps.

## Fresh Mac (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/master/bootstrap.sh | bash
```

What it does, in order:

1. **Xcode Command Line Tools** — installs if missing (system dialog appears).
2. **Homebrew** — installs if missing.
3. **`git` + `stow`** — installed via brew so we can clone and symlink.
4. **Clone** to `~/dotfiles`. Tries SSH first (in case GitHub is already authorized on this Mac); falls back to HTTPS.
5. **Stow** all 10 packages into `$HOME`. If any existing real files conflict (e.g. a hand-written `~/.zshrc` from a previous setup), they're moved to `~/.dotfiles-backup-<timestamp>/` first so stow can proceed cleanly.
6. **`make all`** — runs the full provisioning chain.

It is idempotent. Re-running it on a partially-set-up machine just fills in what's missing.

## `make all` — the provisioning chain

`make all` runs five steps. Each is independently re-runnable:

| Target              | Re-run with            | What it does                                                                        |
|---------------------|------------------------|-------------------------------------------------------------------------------------|
| `make brew`         | `~/.bin/macoss brew`   | Strict `Brewfile` (CLI core), then best-effort `Brewfile.optional` (casks, MAS).    |
| `make runtimes`     | `~/.bin/macoss runtimes` | `mise install` for `~/.tool-versions` (node, go, python, ruby).                  |
| `make ssh`          | `~/.bin/macoss ssh`    | Generates `~/.ssh/id_ed25519`, writes `~/.ssh/config`, prints public key for GitHub. Auto-switches dotfiles remote from HTTPS→SSH once registered. |
| `make defaults`     | `~/.bin/macoss defaults` | Applies `defaults write` settings (Finder, Dock, screenshots, keyboard repeat, …). Requires sudo. |
| `make iterm`        | `~/.bin/macoss iterm`  | Installs iTerm2 shell integration (appends a source line to `~/.zshrc`).            |

`~/.bin/macoss` is just a shim: `exec make -C ~/dotfiles/scripts "${@:-all}"`.

Run `make help` from `scripts/` for the full listing.

## After `make all` — the SSH dance

`make ssh` prints a public key and pauses. Register it on GitHub at <https://github.com/settings/keys> **twice**:

- once as an **Authentication Key** (push/pull),
- once as a **Signing Key** (so signed commits show "Verified").

Then press ENTER. The script verifies GitHub access via `ssh -T` and switches the dotfiles remote from HTTPS to SSH. If you skip the prompt, re-run `make ssh` later.

## Brewfiles

Two files, two policies:

| File                              | Behavior                                                                                              |
|-----------------------------------|-------------------------------------------------------------------------------------------------------|
| `scripts/Brewfile`                | **Strict.** Core CLI + zsh plugins. `brew bundle` runs it; failure aborts `make brew`.                |
| `scripts/Brewfile.optional`       | **Best-effort.** Casks, dev tools, niche CLIs, MAS apps. `brew-optional.sh` runs it; failures are summarized but don't abort. |

Add new strictly-required CLI to `Brewfile`. Add anything that might be renamed, region-locked, or non-essential (casks especially) to `Brewfile.optional`.

`zsh/.zshrc` exports `HOMEBREW_VERIFY_ATTESTATIONS=1`, so every bottle install/upgrade verifies a Sigstore attestation proving the binary was built by Homebrew's official CI. Tampered bottles in storage are rejected before install.

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
│   ├── Makefile                    # all/brew/runtimes/ssh/defaults/iterm/check/lint
│   ├── Brewfile                    # strict: core CLI + zsh plugins
│   ├── Brewfile.optional           # best-effort: casks, MAS, niche CLIs
│   ├── setup/                      # ssh.sh, defaults.sh, iterm.sh, brew-optional.sh
│   └── .bin/                       # macoss, tmuxinator.zsh — stowed to ~/.bin/
├── claude/    ghostty/    git/     mise/    nvim/
├── shell/     starship/   tmux/    zsh/
└── docs/                           # this manual
```
