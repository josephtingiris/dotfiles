# .bashrc

Bashrc_Version="20171031, joseph.tingiris@gmail.com"

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

alias cl='cd;clear'
alias cp='cp -i'
alias h='history'
alias hs='export HISTSIZE=0'
alias l='ls -lFhart'
alias ls='ls --color=tty'
alias mv='mv -i'
alias rm='rm -i'
alias s='source ~/.bashrc'
alias sd='screen -S $(basename $(pwd))'

# Uncomment the following line to disable systemctl auto-paging feature
# export SYSTEMD_PAGER=

export TZ='America/New_York'

if [ "$TERM" == "xterm" ] || [ "$TERM" == "ansi" ] || [[ "$TERM" == *"color" ]]; then
    #export PS1="\[$(tput setaf 0)\][\u@\h \w]$PS \[$(tput sgr0)\]" # black
    #export PS1="\[$(tput setaf 1)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark red
    #export PS1="\[$(tput setaf 2)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark green
    #export PS1="\[$(tput setaf 3)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark yellow(ish)
    #export PS1="\[$(tput setaf 4)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark blue
    #export PS1="\[$(tput setaf 5)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark purple
    #export PS1="\[$(tput setaf 6)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark cyan
    #export PS1="\[$(tput setaf 7)\][\u@\h \w]$PS \[$(tput sgr0)\]" # grey
    #export PS1="\[$(tput setaf 8)\][\u@\h \w]$PS \[$(tput sgr0)\]" # dark grey
    #export PS1="\[$(tput setaf 9)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright red
    #export PS1="\[$(tput setaf 10)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright green
    #export PS1="\[$(tput setaf 11)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright yellow
    #export PS1="\[$(tput setaf 12)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright blue
    #export PS1="\[$(tput setaf 13)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright purble
    #export PS1="\[$(tput setaf 14)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright cyan
    #export PS1="\[$(tput setaf 15)\][\u@\h \w]$PS \[$(tput sgr0)\]" # white
    #export PS1="\[$(tput setaf 17)\][\u@\h \w]$PS \[$(tput sgr0)\]" # really dark blue
    if [ "$USER" == "root" ]; then
        PS="#"
        export PS1="\[$(tput setaf 11)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright yellow
    else
        PS="$"
        export PS1="\[$(tput setaf 14)\][\u@\h \w]$PS \[$(tput sgr0)\]" # bright cyan
    fi
    unset PS
fi

if [ ! -f ~/.inputrc ]; then
    echo "set bell-style none" > ~/.inputrc
fi

if [ ! -d ~/.ssh ]; then
    Ssh_Keygen=/usr/bin/ssh-keygen
    if [ -x $Ssh_Keygen ]; then
        $Ssh_Keygen -t ed25519 -b 4096
    fi
    unset Ssh_Keygen
fi

if [ "${HOME}" != "" ] && [ -d "${HOME}/.ssh" ]; then

    # this works in conjunction with .bash_logout

    Ssh_Add=/usr/bin/ssh-add
    Ssh_Agent=/usr/bin/ssh-agent
    Ssh_Agent_Timeout=86400

    if [ -x $Ssh_Agent ] && [ -x $Ssh_Add ]; then

        $Ssh_Add -l &> /dev/null
        if [ $? -eq 2 ]; then

            if [ -r ${HOME}/.ssh-agent.$HOSTNAME ]; then
                eval "$(<${HOME}/.ssh-agent.$HOSTNAME)" &> /dev/null
            fi

            $Ssh_Add -l &> /dev/null
            if [ $? -eq 2 ]; then
                # TODO: see if another ssh-agent is running by this user & use it rather than start a new one every time
                (umask 066; $Ssh_Agent -t $Ssh_Agent_Timeout 1> ${HOME}/.ssh-agent.$HOSTNAME)
                eval "$(<${HOME}/.ssh-agent.$HOSTNAME)" &> /dev/null
            fi

        fi

        Ssh_Key_Files=()
        while read Ssh_Key_File; do
            Ssh_Key_Files+=($Ssh_Key_File)
        done <<< "$(find "${HOME}/.ssh/" -name "*id_dsa" -o -name "*id_rsa" -o -name "*ecdsa_key" -o -name "*id_ed25519" 2> /dev/null)"

        if [ -r "${HOME}/.ssh/config" ]; then
            while read Ssh_Key_File; do
                Ssh_Key_Files+=($Ssh_Key_File)
            done <<< "$(cat "${HOME}/.ssh/config" | grep IdentityFile | awk '{print $NF}' | sort -u)"
        fi

        if [ -r "${HOME}/.git/GIT_SSH.config" ]; then
            while read Ssh_Key_File; do
                Ssh_Key_Files+=($Ssh_Key_File)
            done <<< "$(cat "${HOME}/.git/GIT_SSH.config" | grep IdentityFile | awk '{print $NF}' | sort -u)"
        fi

        if [ -r "${HOME}/.subversion/SVN_SSH.config" ]; then
            while read Ssh_Key_File; do
                Ssh_Key_Files+=($Ssh_Key_File)
            done <<< "$(cat "${HOME}/.subversion/SVN_SSH.config" 2> /dev/null | grep IdentityFile 2> /dev/null | awk '{print $NF}' 2> /dev/null | sort -u 2> /dev/null)"
        fi

        eval Ssh_Key_Files=($(printf "%q\n" "${Ssh_Key_Files[@]}" | sort -u))

        for Ssh_Key_File in ${Ssh_Key_Files[@]}; do
            Ssh_Agent_Key=""
            Ssh_Key_File_Pub=""
            if [ -r "${Ssh_Key_File}.pub" ]; then
                Ssh_Key_File_Pub=$(cat "${Ssh_Key_File}.pub" 2> /dev/null | awk '{print $2}' 2> /dev/null)
                Ssh_Agent_Key=$($Ssh_Add -L  2> /dev/null | grep "$Ssh_Key_File_Pub" 2> /dev/null)
                if [ "$Ssh_Agent_Key" != "" ]; then
                    continue
                fi
            else
                continue
            fi
            if [ -r "$Ssh_Key_File" ]; then
                Ssh_Agent_Key=$($Ssh_Add -l 2> /dev/null | grep $Ssh_Key_File 2> /dev/null)
                if [ "$Ssh_Agent_Key" == "" ]; then
                    if [ "$PS1" != "" ]; then
                        $Ssh_Add $Ssh_Key_File
                    else
                        $Ssh_Add $Ssh_Key_File &> /dev/null
                    fi
                fi
                unset Ssh_Agent_Key
            fi
        done
        unset Ssh_Agent_Key Ssh_Key_File Ssh_Key_File_Pub Ssh_Key_Files

    fi

    unset Ssh_Add Ssh_Agent Ssh_Agent_Timeout

fi

if [ -x /usr/bin/gnome-keyring-daemon ] && [ -r /etc/pam.d/kdm ]; then
    # http://tuxrocket.com/2013/01/03/getting-gnome-keyring-to-work-under-kde-and-kdm/
    # /etc/pam.d/kdm
    # session include common-pamkeyring
    /usr/bin/gnome-keyring-daemon start 1> /dev/null
fi

# mimic /etc/profile.d in home etc/profile.d directory
if  [ "${HOME}" != "" ] && [ "${HOME}" != "/" ] && [ -d "${HOME}/etc/profile.d" ]; then
    SHELL=/bin/bash
    # Only display echos from profile.d scripts if this is not a login shell
    # or is an interactive shell - otherwise just process them to set envvars
    for Home_Etc_Profile_D in ${HOME}/etc/profile.d/*.sh; do
        if [ -r "$Home_Etc_Profile_D" ]; then
            if [ "$PS1" ]; then
                . "$Home_Etc_Profile_D"
            else
                . "$Home_Etc_Profile_D" >/dev/null
            fi
        fi
    done
    unset Home_Etc_Profile_D
fi


Auto_Path="./:"

Find_Paths=("$HOME" "/apex" "/base")

if [ -r ~/.Auto_Path ]; then
    while read Auto_Path_Line; do
        Find_Paths+=("$Auto_Path_Line")
    done <<< "$(cat ~/.Auto_Path | grep -v ^\#)"
fi

for Find_Path in ${Find_Paths[@]}; do
    if [ -d /${Find_Path} ] && [ -r /${Find_Path} ]; then
        Find_Bins=$(find ${Find_Path}/ -maxdepth 2 -type d -name bin -printf "%d %p\n" -o -name sbin -printf "%d %p\n" 2> /dev/null | sort -n | awk '{print $NF}')
        for Find_Bin in $Find_Bins; do
            Auto_Path+="$Find_Bin:"
        done
        unset Find_Bin Find_Bins
    fi
done
unset Find_Path Find_Paths

# rhscl; see https://wiki.centos.org/SpecialInterestGroup/SCLo/CollectionsList
# e.g. yum --enablerepo=extras install centos-release-scl && yum install rh-php56
if [ -d /opt/rh ]; then
    Rhscl_Roots=$(find /opt/rh/ -type f -name enable 2> /dev/null | sort -V)
    for Rhscl_Enable in $Rhscl_Roots; do
        if [ -r "$Rhscl_Enable" ]; then
            . "$Rhscl_Enable"
        else
            continue
        fi
        Rhscl_Root="$(dirname "$Rhscl_Enable")/root"
        Rhscl_Bins="usr/local/bin usr/local/sbin usr/bin usr/sbin bin sbin"
        for Rhscl_Bin in $Rhscl_Bins; do
            if [ -d "$Rhscl_Root/$Rhscl_Bin" ]; then
                Auto_Path+="$Rhscl_Root/$Rhscl_Bin:"
            fi
        done
        unset Rhscl_Bin Rhscl_Bins  Rhscl_Enable Rhscl_Root
    done
    unset Rhscl_Roots
fi

Auto_Path+="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

export PATH=$Auto_Path

unset Auto_Path

if [ "$USER" != "root" ]; then
    umask u+rw,g-rwx,o-rwx
fi

##
### everything past here depends on PATH
##

# who am i (really)
if [ $(which --skip-alias logname 2> /dev/null) ]; then
    export Whom=$(logname 2> /dev/null)
else
    if [ $(which --skip-alias who 2> /dev/null) ]; then
        export Whom=$(who -m 2> /dev/null)
    fi
fi
if [ "$Whom" != "" ]; then export Who="${Whom%% *}"; fi

if [ "$Who" == "" ] && [ "$USER" != "" ]; then export Who=$USER; fi
if [ "$Who" == "" ] && [ "$LOGNAME" != "" ]; then export Who=$LOGNAME; fi
if [ "$Who" == "" ]; then
    export Who=UNKNOWN
else
    if [ $(which --skip-alias getent 2> /dev/null) ]; then
        Who_Home=$(getent passwd $Who | awk -F: '{print $6}')
    fi
fi

##
### everything past here depends on PATH and/or Who_Home
##

# EDITOR
unset EDITOR
Editors=(nvim vim vi)
for Editor in ${Editors[@]}; do
    if [ $(which --skip-alias $Editor 2> /dev/null) ]; then
        export EDITOR="$(which --skip-alias $Editor 2> /dev/null)"
        alias vi="$EDITOR"
        break
    fi
done
unset Editor Editors

# git
if [ $(which --skip-alias git 2> /dev/null) ]; then
    export GIT_EDITOR=$EDITOR
    git config --global alias.st status
    git config --global alias.info 'remote -v'
    git config --global push.default simple
    git config --global user.email "joseph.tingiris@gmail.com" &> /dev/null
    git config --global user.name "$USER@$HOSTNAME" &> /dev/null
fi

# svn
if [ $(which --skip-alias svn 2> /dev/null) ]; then
    export SVN_EDITOR=$EDITOR
fi

# tmux
unset Tmux_Info
if [ $(which --skip-alias tmux 2> /dev/null) ]; then
    if [ -r "${Who_Home}/.tmux.conf" ]; then
        Tmux_Info+="[${Who_Home}/.tmux.conf]"
        alias tmux="tmux -f ${Who_Home}/.tmux.conf"
    fi
fi

if [ "$TMUX" != "" ]; then
    Tmux_Info="[$TMUX]"
fi

export Apex_User=${Who}@$HOSTNAME
export Base_User=$Apex_User

if [ "$PS1" != "" ]; then
    echo
    echo -n "~/.bashrc $Bashrc_Version"
    if [ "$Tmux_Info" ]; then
        echo -n " $Tmux_Info"
    fi
    echo
    echo
fi

