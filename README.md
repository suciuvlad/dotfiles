dotfiles
========

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow package whose contents mirror `$HOME`.

**Manual:** see [`docs/`](docs/README.md) for hotkeys, shell tools, TUIs,
dev stacks, apps, and setup walkthroughs.

| Package    | What it provides                                        |
|------------|---------------------------------------------------------|
| `agents`   | `~/.agents/skills/` — central store for AI-agent skills (claude/cursor/codex symlink into it) |
| `claude`   | `~/.claude/CLAUDE.md`, `settings.json` (declares plugins + marketplaces — Claude Code reinstalls them on first launch), `skills/` (symlinks into `agents`) |
| `ghostty`  | `~/.config/ghostty/config`                              |
| `git`      | `~/.gitconfig`, `~/.gitignore`, `~/.gitmessage`         |
| `herdr`    | `~/.config/herdr/config.toml`, `~/.herdr-functions.zsh` (tmux keymap + layout helpers ported to herdr) |
| `launchagents` | `~/Library/LaunchAgents/*.plist` (CapsLock→Escape remap, weekly drift check) |
| `mise`     | `~/.tool-versions` (global node/go/python/ruby versions)|
| `nvim`     | `~/.config/nvim/` (init, options, keymaps, plugins)     |
| `scripts`  | `~/.bin/macoss`, `~/.bin/tmuxinator.zsh`                |
| `shell`    | `~/.agignore`, `~/.eslintrc`, `~/.xterm-256color.ti`    |
| `starship` | `~/.config/starship.toml`                               |
| `tmux`     | `~/.tmux.conf`, `~/.tmux-functions.zsh`                 |
| `zsh`      | `~/.zshrc`                                              |

Setup
-----

### Fresh Mac (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` installs Xcode CLT → Homebrew → git/stow, clones this repo
**via HTTPS** to `~/dotfiles`, stows everything, and runs `make all`. It is
idempotent — safe to re-run.

You'll be prompted to register the SSH key (printed by `make ssh`) on
GitHub. Once registered, re-run `make ssh` and it will verify GitHub access
and auto-switch the dotfiles remote from HTTPS to SSH.

### Already have brew + git

```sh
git clone git@github.com:suciuvlad/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -R -t ~ */
make -C scripts all
```

Per-step provisioning
---------------------

`make all` runs `brew → ssh → runtimes → defaults → iterm → agents → skills → ai-clis → herdr` through a
spinner-driven orchestrator (`scripts/install.sh`) that ends with a styled
summary box: per-step status icons, durations, and any per-package
failures (e.g., region-locked casks). Output is captured to
`~/.local/state/dotfiles/install.log`, and per-step results persist in
`~/.local/state/dotfiles/results.jsonl` — so if a run dies partway,
`make -C scripts status` shows what ran, what failed, what never started
(verified against the live machine), and the exact commands to resume.

`status` trusts probes over records: every step is verified live (defaults
are re-read via `defaults.sh --verify` — the same `dw` lines drive apply
*and* verify; `Brewfile.optional` is counted, not judged; the checkout
itself gets a cleanliness row). The ledger only supplies timestamps. A
weekly LaunchAgent (`com.vladsuciu.dotfiles-drift`, Mondays 10:00) runs
`status.sh --check` and posts a notification when the machine drifts.

Bypass the orchestrator for raw output: `VERBOSE=1 make all`. CI / `curl |
bash` flows fall through automatically when stdout isn't a TTY.

Each step is idempotent and re-runnable:

| Step                                       | Re-run with               |
|--------------------------------------------|---------------------------|
| Homebrew + Brewfiles                       | `~/.bin/macoss brew`      |
| Runtimes via mise (node, go, python, ruby) | `~/.bin/macoss runtimes`  |
| SSH key + allowed_signers (+ remote→SSH)   | `~/.bin/macoss ssh`       |
| macOS `defaults` settings                  | `~/.bin/macoss defaults`  |
| iTerm2 shell integration                   | `~/.bin/macoss iterm`     |
| LaunchAgents (keyremap, weekly drift check)| `~/.bin/macoss agents`    |
| AI-agent skills → cursor/codex symlinks    | `~/.bin/macoss skills`    |
| AI CLIs (claude native, kimi; codex via mise) | `~/.bin/macoss ai-clis` |
| herdr agent integrations (binary via Brewfile) | `~/.bin/macoss herdr`   |

Brewfiles
---------

The package list is split:

| File                       | Behavior                                                              |
|----------------------------|-----------------------------------------------------------------------|
| `scripts/Brewfile`         | **Strict.** Core CLI, zsh plugins. Failure aborts `make brew`.        |
| `scripts/Brewfile.optional`| **Best-effort.** Casks, dev tools, niche CLIs, MAS apps. Failures are summarised at the end of `make brew`; do not abort. |

Add new strictly-required tools to `Brewfile`. Add anything that might be
renamed/missing/region-locked (casks especially) to `Brewfile.optional`.

SSH key
-------

After `make ssh`, register the printed public key on GitHub **twice** —
once as an **Authentication Key** (push/pull) and once as a **Signing
Key** (so signed commits show "Verified"). Both at
<https://github.com/settings/keys>.

Maintenance
-----------

| Command                | What it does                                              |
|------------------------|-----------------------------------------------------------|
| `~/.bin/macoss status` | live-probe every install step + repo cleanliness, with resume commands (`status.sh --check` for the script-friendly version: drift lines on stdout, exit 1) |
| `~/.bin/macoss check`  | audit symlinks, required CLI tools, Brewfile, git identity, stow packages, cask trust, CVE scan |
| `~/.bin/macoss lint`   | shellcheck `scripts/setup/*.sh` and `macoss` itself       |
| `~/.bin/macoss test`   | probe + `defaults --verify` logic tests against fake `$HOME`s (also run in CI on every push) |

Run `make check` after pulling, after `stow -R`, or whenever something
feels off — it'll surface dangling symlinks and missing dependencies in
one shot.

The two security sections audit your existing install — they run as part
of `make check`, not during `make brew`:

- **Cask trust** — `spctl --assess` on every `.app` in `/Applications`;
  reports how many are signed + Apple-notarized and classifies any that
  aren't (ad-hoc signed, Developer ID without notarization, dev cert,
  unsigned). Gatekeeper's runtime check is launch-time only — this
  surfaces problems before you double-click.
- **CVE scan** — `grype` against `$(brew --prefix)/Cellar` *and*
  `/Applications`, grouped by severity (Critical → High → Medium → Low).
  Catches known vulnerabilities in CLI tools and bundled libraries
  inside Electron / Java apps. First run downloads ~500 MB of vuln DB;
  subsequent runs hit the local cache.

Common operations
-----------------

| Action                          | Command (run from `~/dotfiles`)         |
|---------------------------------|-----------------------------------------|
| Install everything              | `stow -t ~ */`                          |
| Install one package             | `stow -t ~ nvim`                        |
| Refresh after adding/removing   | `stow -R -t ~ nvim`                     |
| Refresh everything              | `stow -R -t ~ */`                       |
| Uninstall a package             | `stow -D -t ~ nvim`                     |

Always re-stow with `-R` after adding or deleting files inside a package
— that's how stow stays in sync and avoids dangling symlinks.

One folding exception: `~/Library/LaunchAgents` must stay a **real
directory** — launchd won't scan a symlinked one at login, so agents
silently stop surviving reboots. On fresh Macs (no such dir yet) stow
would fold it into exactly that; `bootstrap.sh` pre-creates the dir and
`make agents` heals an already-folded one.

Updating
--------

```sh
git pull
cd ~/dotfiles && stow -R -t ~ */
```

Inspiration
-----------
* [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles)
* [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
* [caarlos0/dotfiles](https://github.com/caarlos0/dotfiles)
* [paulirish/dotfiles](https://github.com/paulirish/dotfiles)
* [alrra/dotfiles](https://github.com/alrra/dotfiles)
