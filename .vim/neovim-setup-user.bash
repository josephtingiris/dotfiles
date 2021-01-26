#!/bin/bash

if [ ! -f /etc/os-release ]; then
    exit
fi

source /etc/os-release

# install/upgrade neovim user dependencies

chown -R $USER:"$(id -gn $USER)" ~/.config
if [ "${ID}" == "centos" ] || [[ "${ID}" == "fedora" && ${VERSION_ID} -lt 28 ]]; then
    pip2 uninstall neovim
    pip2 install --user --upgrade pynvim
fi

pip3 uninstall neovim &> /dev/null
pip3 install --user --upgrade pynvim
gem install --user-install neovim
grep .gem/ruby/bin ~/.Auto_Path || echo ~/.gem/ruby/bin >> ~/.Auto_Path
npm install -g bash-language-server
npm install -g typescript
npm install -g neovim
echo
