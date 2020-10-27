#!/bin/bash

# EPEL neovim & python 3.6
# SCL ruby 2.4 for neovim providers
# xsel for clipboard (probably should use lemonade)

if [ ! -f /etc/os-release ]; then
    exit
fi

source /etc/os-release

Packages=(
epel-release
cargo
golang
mono-devel
neovim
nodejs
npm
python2-pip
tmux
xsel
yamllint
)

if [ "${ID}" == "centos" ]; then
    if [ ${VERSION_ID} -le 7 ]; then
        Packages+=(centos-release-scl)
        Packages+=(python36-devel)
        Packages+=(python36-pip)
        Packages+=(rh-ruby24-ruby-devel)
        Packages+=(ctags-etags)
    else
        Packages+=(ctags)
        Packages+=(python3)
        Packages+=(python3-devel)
    fi
else
    if [ "${ID}" == "fedora" ]; then
        if [ ${VERSION_ID} -ge 28 ]; then
            Packages+=(ruby-devel)
            Packages+=(python3-devel)
        fi
    fi
fi

for Package in ${Packages[@]}; do
    echo
    echo "Installing $Package ..."
    echo
    sudo yum -y install $Package
    if [ $? -ne 0 ]; then
        exit 1
    fi
done

~/.vim/neovim-setup-user.bash
