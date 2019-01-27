#!/bin/bash

# EPEL neovim & python 3.6
# SCL ruby 2.4 for neovim providers
# xsel for clipboard (probably should use lemonade)

if [ ! -f /etc/os-release ]; then
    exit
fi

source /etc/os-release

Yum_Packages=(
epel-release
cargo
ctags-etags
golang
mono-devel
neovim
nodejs
npm
python2-pip
tmux
xsel
)

if [ "${ID}" == "centos" ]; then
    if [ ${VERSION_ID} -le 7 ]; then
        Yum_Packages+=(centos-release-scl)
        Yum_Packages+=(python34-devel)
        Yum_Packages+=(rh-ruby24-ruby-devel)
    fi
else
    if [ "${ID}" == "fedora" ]; then
        if [ ${VERSION_ID} -ge 28 ]; then
            Yum_Packages+=(ruby-devel)
            Yum_Packages+=(python3-devel)
        fi
    fi
fi

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
grep /home/jtingiris/.gem/ruby/bin ~/.Auto_Path || echo /home/jtingiris/.gem/ruby/bin >> ~/.Auto_Path
npm install -g typescript
npm install -g neovim
echo
