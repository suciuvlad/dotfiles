dotfiles
========

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow package whose contents mirror `$HOME`.

| Package    | What it provides                                        |
|------------|---------------------------------------------------------|
| `claude`   | `~/.claude/CLAUDE.md` (Claude Code behavior)            |
| `ghostty`  | `~/.config/ghostty/config`                              |
| `git`      | `~/.gitconfig`, `~/.gitignore`, `~/.gitmessage`         |
| `mise`     | `~/.tool-versions` (global node/go/runtime versions)    |
| `nvim`     | `~/.config/nvim/` (init, options, keymaps, plugins)     |
| `scripts`  | `~/.bin/macoss`, `~/.bin/tmuxinator.zsh`                |
| `shell`    | `~/.agignore`, `~/.eslintrc`, `~/.xterm-256color.ti`    |
| `starship` | `~/.config/starship.toml`                               |
| `tmux`     | `~/.tmux.conf`, `~/.tmux-functions.zsh`                 |
| `zsh`      | `~/.zshrc`                                              |

Setup
-----

```sh
brew install stow
git clone git@github.com:suciuvlad/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow -t ~ */
```

Fresh-Mac provisioning
----------------------

After cloning, run:

```sh
~/.bin/macoss        # everything (brew, node, ssh, macOS defaults, iterm)
~/.bin/macoss help   # list individual steps
```

Each step is idempotent and can be re-run on its own:

| Step                              | Re-run with             |
|-----------------------------------|-------------------------|
| Homebrew + `Brewfile`             | `~/.bin/macoss brew`    |
| Runtimes via mise (node, go, …)   | `~/.bin/macoss node`    |
| SSH key + allowed_signers         | `~/.bin/macoss ssh`     |
| macOS `defaults` settings         | `~/.bin/macoss defaults`|
| iTerm2 shell integration          | `~/.bin/macoss iterm`   |

The packages it installs live in `scripts/Brewfile`; edit there to add or
remove apps.

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
