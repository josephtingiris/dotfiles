#!/bin/bash

# EPEL neovim & python 3.6
# SCL ruby 2.4 for neovim providers
# xsel for clipboard (probably should use lemonade)

if [ ! -f /etc/centos-release ]; then
        exit
fi

Yum_Packages=(
centos-release-scl
epel-release
cargo
ctags-etags
golang
mono-devel
neovim
nodejs
npm
python34-devel
rh-ruby24-ruby-devel
python2-pip
tmux
xsel
cargo
)

for Yum_Package in ${Yum_Packages[@]}; do
        echo
        echo "Installing $Yum_Package ..."
        echo
        sudo yum -y install $Yum_Package
        if [ $? -ne 0 ]; then
            exit 1
        fi
done

echo
echo "Re-source environment & run ..."
echo
pip2 install --user --upgrade neovim
pip3 install --user --upgrade neovim
gem install --user-install neovim
npm install -g typescript
echo
