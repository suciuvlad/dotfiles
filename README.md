dotfiles
========

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each top-level directory is a Stow package whose contents mirror `$HOME`.

| Package    | What it provides                                        |
|------------|---------------------------------------------------------|
| `ghostty`  | `~/.config/ghostty/config`                              |
| `git`      | `~/.gitconfig`, `~/.gitignore`, `~/.gitmessage`         |
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
stow -t ~ ghostty git nvim scripts shell starship tmux zsh
```

(Optional, fresh Mac only: `./scripts/.bin/macoss` for macOS defaults.)

Common operations
-----------------

| Action                          | Command (run from `~/dotfiles`)         |
|---------------------------------|-----------------------------------------|
| Install everything              | `stow -t ~ <pkg1> <pkg2> ...`           |
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
* [Thoughtbot dotfiles](https://github.com/thoughtbot/dotfiles)
* [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
