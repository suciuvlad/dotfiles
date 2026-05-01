dotfiles
========

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow package whose contents mirror `$HOME`.

| Package    | What it provides                                        |
|------------|---------------------------------------------------------|
| `claude`   | `~/.claude/CLAUDE.md` (Claude Code behavior)            |
| `ghostty`  | `~/.config/ghostty/config`                              |
| `git`      | `~/.gitconfig`, `~/.gitignore`, `~/.gitmessage`         |
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
curl -fsSL https://raw.githubusercontent.com/suciuvlad/dotfiles/master/bootstrap.sh | bash
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

`make all` runs `brew → runtimes → ssh → defaults → iterm`. Each step is
idempotent and re-runnable:

| Step                                       | Re-run with               |
|--------------------------------------------|---------------------------|
| Homebrew + Brewfiles                       | `~/.bin/macoss brew`      |
| Runtimes via mise (node, go, python, ruby) | `~/.bin/macoss runtimes`  |
| SSH key + allowed_signers (+ remote→SSH)   | `~/.bin/macoss ssh`       |
| macOS `defaults` settings                  | `~/.bin/macoss defaults`  |
| iTerm2 shell integration                   | `~/.bin/macoss iterm`     |

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
| `~/.bin/macoss check`  | audit symlinks, required CLI tools, Brewfile, git identity, stow packages |
| `~/.bin/macoss lint`   | shellcheck `scripts/setup/*.sh` and `macoss` itself       |

Run `make check` after pulling, after `stow -R`, or whenever something
feels off — it'll surface dangling symlinks and missing dependencies in
one shot.

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
