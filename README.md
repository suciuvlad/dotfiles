dotfiles
========

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

Setup
-----

Clone the repo:

    git clone git@github.com:suciuvlad/dotfiles.git ~/dotfiles

Install Stow:

    brew install stow

Optionally apply macOS defaults:

    ./scripts/.bin/macoss

Symlink everything from `~/dotfiles` into `$HOME`:

    cd ~/dotfiles
    stow -t ~ ghostty git nvim scripts shell starship tmux zsh

Each top-level directory is a Stow package whose contents mirror `$HOME`. To
install just one package: `stow -t ~ nvim`. To remove: `stow -D -t ~ nvim`.
After adding or removing files inside a package, run `stow -R -t ~ <package>`
(restow) to sync the symlinks.

Updating
--------

    git pull
    cd ~/dotfiles && stow -R -t ~ ghostty git nvim scripts shell starship tmux zsh

Inspiration
-----------
* [Thoughtbot](https://github.com/thoughtbot/dotfiles)
* [mathiasbynens](https://github.com/mathiasbynens/dotfiles)
