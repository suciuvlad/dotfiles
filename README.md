dotfiles
========

Clone repo
-------

Clone onto your laptop:

    git clone git://github.com/suciuvlad/dotfiles.git ~/dotfiles


### Install software & configure some sensible macOS defaults
When setting up a new Mac, you may want to set some sensible macOS defaults:

```bash
./bin/macos
```
 
### Install Thoughtbot's rcm
Install [rcm](https://github.com/thoughtbot/rcm):

    brew tap thoughtbot/formulae
    brew install rcm

Symlink the dotfiles:

    env RCRC=$HOME/dotfiles/rcrc rcup
 
After the initial installation, you can run `rcup` without the one-time variable
`RCRC` being set (`rcup` will symlink the repo's `rcrc` to `~/.rcrc` for future
runs of `rcup`).

Update
------

From time to time you should pull down any updates to these dotfiles, and run

    rcup

to link any new files and install new vim plugins. **Note** You _must_ run
`rcup` after pulling to ensure that all files in plugins are properly installed,
but you can safely run `rcup` multiple times so update early and update often!

Inspiration
-----------------
* [Thoughtbot](https://github.com/thoughtbot/dotfiles)
* [mathiasbynens](https://github.com/mathiasbynens/dotfiles)
