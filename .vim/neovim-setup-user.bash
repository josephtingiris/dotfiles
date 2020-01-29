#!/bin/bash

# install/upgrade neovim user dependencies

sudo chown -R $USER:"$(id -gn $USER)" /home/jtingiris/.config
pip2 uninstall neovim
pip2 install --user --upgrade pynvim
pip3 uninstall neovim
pip3 install --user --upgrade pynvim
gem install --user-install neovim
grep /home/jtingiris/.gem/ruby/bin ~/.Auto_Path || echo /home/jtingiris/.gem/ruby/bin >> ~/.Auto_Path
npm install -g bash-language-server
npm install -g typescript
npm install -g neovim
echo
