<!-- Markdown link definitions -->
[init-base]: https://github.com/josephtingiris/dotfiles
[init-conduct]: dotfiles.CODE_OF_CONDUCT.md
[init-contributing]: dotfiles.CONTRIBUTING.md
[init-installation]: #Installation
[init-issue]: https://github.com/josephtingiris/dotfiles/issues/new
[init-license]: dotfiles.LICENSE.md
[init-support]: #Support
[init-usage]: #Usage
[init-wiki]: https://github.com/josephtingiris/dotfiles/wiki

# Description

@josephtingiris dotfiles

## Table of Contents

* [Installation][init-installation]
* [Usage][init-usage]
* [Support][init-support]
* [License][init-license]
* [Code of Conduct][init-conduct]
* [Contributing][init-contributing]

## Installation

Download to the project directory, add, and commit.  i.e.:

```sh
cd ~
if [ -d .git ]; then rm -rf .git; fi
git init
git remote add origin git@github.com:josephtingiris/dotfiles
git fetch
git checkout -t origin/master -f
git reset --hard
git checkout -- .
~
```

## Usage

1. .bash_profile

* nothing special, just included to make sure ~/.bashrc gets sourced & initial PATH is set

2. .bashrc

* source global definitions (/etc/bashrc)
* helpful single & double character aliases
* if /usr/bin/vim is found then alias vi & export EDITOR, GIT_EDITOR, & SVN_EDITOR
* export TZ='America/New_York'
* if a color TERM is set then tput a color prompt (PS1)
* if there's no .inputrc then create one to turn all bells off (set bell-style none)
* if there's no .ssh directory then generate a key
* ssh-agent logic; automatically start or reuse existing process
* ssh-agent logic; add identities from a variety of sources (e.g. authorized_keys, GIT_SSH.config, SVN_SSH.config, etc)
* start gnome-keyring-daemon if /etc/pam.d/kdm is readable
* Auto_Path logic; find all bin & sbin directories and add them to PATH
* Auto_Path logic; add contents of ~/.Auto_Path to PATH (except comments)
* Auto_Path logic; support for /opt/rh scl packages (add to automatic PATH & enable)
* sets umask
* adds WHO & WHOM globals
* addes Apex_User & Base_User globals (for revision control)

3. .bash_logout

* if it's running (and started by .bashrc) then kill ssh-agent pid

4. .gitignore

* ignore everything (except some stuff)

5. .vimrc (& .vim)

* colorscheme elflord
* spaces, not tabs
* tabstop & shiftwidth are 4
* preserve cursor position when Indent()'ing the entire buffer (e.g. gg=G)
* <F5> call Indent()
* <F7> set nopaste
* <F8> set paste
* <F12> syntax sync fromstart
* some custom filetypes
* custom .vim scripts
* etc

6. etc/profile.d

* files in this directory, with execute permissions, will automatically be sourced on login
* includes etc/profile.d/git-pull-dotfiles.sh to automatically pull updates from this repo (each login)

## Support

Please see the [Wiki][init-wiki] or [open an issue][init-issue] for support.
