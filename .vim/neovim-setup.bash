#!/bin/bash

# EPEL neovim 
# SCL python 3.6 & ruby 2.4 for neovim providers.
# xsel for clipboard (probably should use lemonade)

if [ ! -f /etc/centos-release ]; then
        exit
fi

Yum_Packages=(
centos-release-scl 
epel-release
neovim
rh-python36-python-pip
rh-ruby24-ruby-devel
python2-pip
tmux
xsel
)

for Yum_Package in ${Yum_Packages[@]}; do
        echo
        echo "Installing $Yum_Package ..."
        echo
        sudo yum -y install $Yum_Package
done

echo
echo "Re-source environment & run ..."
echo
echo "pip2 install --user --upgrade neovim"
echo "pip3 install --user --upgrade neovim"
echo "gem install neovim"
echo
