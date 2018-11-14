# .bashrc

Bashrc_Version="20181114, joseph.tingiris@gmail.com"

##
### source global definitions
##

if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

##
### determine os variant
##

export Uname_R=$(uname -r 2> /dev/null | awk -F\. '{print $(NF-1)"."$NF}' 2> /dev/null)

##
### determine true username
##

if [ $(which --skip-alias logname 2> /dev/null) ]; then
    export User_Name=$(logname 2> /dev/null)
else
    if [ $(which --skip-alias who 2> /dev/null) ]; then
        export User_Name=$(who -m 2> /dev/null)
    fi
fi
if [ ${#User_Name} -eq 0 ] && [ ${#SUDO_USER} -ne 0 ]; then export User_Name=$SUDO_USER; fi
if [ ${#User_Name} -eq 0 ]; then export User_Name=$USER; fi
if [ ${#User_Name} -gt 0 ]; then export Who="${User_Name%% *}"; fi

if [ ${#Who} -eq 0 ] && [ ${#USER} -eq 0 ]; then export Who=$USER; fi
if [ ${#Who} -eq 0 ] && [ ${#LOGNAME} -gt 0 ]; then export Who=$LOGNAME; fi
if [ ${#Who} -eq 0 ]; then
    export Who=UNKNOWN
    export User_Dir="/tmp"
else
    if [ $(which --skip-alias getent 2> /dev/null) ]; then
        export User_Dir=$(getent passwd $Who 2> /dev/null | awk -F: '{print $6}')
    fi
fi

if [ ${#User_Dir} -eq 0 ]; then
    export User_Dir="~"
else
    if [ ${#User_Name} -gt 0 ]; then
        if [ -f "${User_Dir}/.bashrc" ]; then
            chown ${User_Name} "${User_Dir}/.bashrc" &> /dev/null
        fi
        if [ -f "${User_Dir}/.bashrc.share" ]; then
            chown ${User_Name} "${User_Dir}/.bashrc.share" &> /dev/null
        fi
    fi
fi

export Apex_User=${Who}@$HOSTNAME
export Base_User=$Apex_User

##
### set PATH automatically
##

cd &> /dev/null

unset Auto_Path

# bin & sbin from the directories, in the following array, are automatically added in the order given
Find_Paths=()
Find_Paths+=("${HOME}")
Find_Paths+=("${User_Dir}")
if [ -r "${User_Dir}/opt/${Uname_R}" ]; then
    Find_Paths+=("${User_Dir}/opt/${Uname_R}")
fi
Find_Paths+=("/apex")
Find_Paths+=("/base")

# add custom paths, in the order given in ~/.Auto_Path, before automatically finding bin paths
if [ -r ~/.Auto_Path ]; then
    while read Auto_Path_Line; do
        Find_Paths+=($(eval "echo $Auto_Path_Line"))
    done <<< "$(cat ~/.Auto_Path | grep -v '^#')"
fi

for Find_Path in ${Find_Paths[@]}; do
    if [ -d /${Find_Path} ] && [ -r /${Find_Path} ]; then
        Find_Bins=$(find ${Find_Path}/ -maxdepth 2 -type d -name bin -printf "%d %p\n" -o -name sbin -printf "%d %p\n" 2> /dev/null | sort -n | awk '{print $NF}')
        for Find_Bin in $Find_Bins; do
            Auto_Path+=":$Find_Bin"
        done
        unset Find_Bin Find_Bins
    fi
done
unset Find_Path Find_Paths

# after .Auto_Path, put /opt/rh bin & sbin directories in the path too
# rhscl; see https://wiki.centos.org/SpecialInterestGroup/SCLo/CollectionsList
if [ -d /opt/rh ] && [ -r ~/.Auto_Scl ]; then
    Rhscl_Roots=$(find /opt/rh/ -type f -name enable 2> /dev/null | sort -Vr)
    for Rhscl_Enable in $Rhscl_Roots; do
        if [ -r "$Rhscl_Enable" ] && [ "$Rhscl_Enable" != "" ]; then
            Unset_Variables=$(cat "$Rhscl_Enable" | grep ^export 2> /dev/null | awk -F= '{print $1}' 2> /dev/null | awk '{print $2}' 2> /dev/null | grep -v ^PATH$ | sort -u)
            for Unset_Variable in $Unset_Variables; do
                eval "unset $Unset_Variable"
            done
        fi
    done
    for Rhscl_Enable in $Rhscl_Roots; do
        if [ -r "$Rhscl_Enable" ] && [ "$Rhscl_Enable" != "" ]; then
            . "$Rhscl_Enable"
        else
            continue
        fi
        Rhscl_Root="$(dirname "$Rhscl_Enable")/root"
        Rhscl_Bins="usr/local/bin usr/local/sbin usr/bin usr/sbin bin sbin"
        for Rhscl_Bin in $Rhscl_Bins; do
            if [ -d "$Rhscl_Root/$Rhscl_Bin" ]; then
                Auto_Path+=":$Rhscl_Root/$Rhscl_Bin"
            fi
        done
        unset Rhscl_Bin Rhscl_Bins  Rhscl_Enable Rhscl_Root
    done
    unset Rhscl_Enable Rhscl_Roots
fi

# finally, add these to the end of Auto_Path
Auto_Path+=":/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

export PATH=$Auto_Path:${PATH}

unset Auto_Path

OIFS=$IFS
IFS=':' read -ra Auto_Path <<< "$PATH"
Uniq_Path="./"
for Dir_Path in "${Auto_Path[@]}"; do
    if ! [[ "${Uniq_Path}" =~ (^|:)${Dir_Path}($|:) ]]; then
        if [ -r "$Dir_Path" ] && [ "$Dir_Path" != "" ]; then
            Uniq_Path+=":$Dir_Path"
        fi
    fi
done
unset Dir_Path
IFS=$OIFS

export PATH="$Uniq_Path"

unset Uniq_Path

Man_Paths=()
Man_Paths+=(/usr/local/share/man)
Man_Paths+=(/usr/share/man)
for Man_Path in ${Man_Paths[@]}; do
    if ! [[ "${MANPATH}" =~ (^|:)${Man_Path}($|:) ]]; then
        if [ -r "$Man_Path" ]; then
            export MANPATH+=":$Man_Path"
        fi
    fi
done

##
### functions
##

# add stuff to my .gitconfig
function gitConfig() {

    if [ -f ~/.gitconfig.lock  ]; then
        rm -f ~/.gitconfig.local &> /dev/null
    fi

    git config --global alias.info 'remote -v' &> /dev/null
    git config --global alias.ls ls-files &> /dev/null
    git config --global alias.rev-prase rev-parse &> /dev/null
    git config --global alias.st status &> /dev/null
    git config --global alias.up pull &> /dev/null

    git config --global color.ui auto &> /dev/null
    git config --global color.branch auto &> /dev/null
    git config --global color.status auto &> /dev/null

    if [[ $(git --version 2> /dev/null | grep 'version 1.9.') ]]; then
        # only support this for git 1.9.x
        git config --global push.default simple &> /dev/null
    fi

    git config --global user.email "joseph.tingiris@gmail.com" &> /dev/null
    git config --global user.name "$USER@$HOSTNAME" &> /dev/null

}

# keep my home directory dotfiles up to date
function githubDotfiles() {

    local cwd=$(/usr/bin/pwd 2> /dev/null)
    cd ~

    if [ -d ~/.git ]; then

        git fetch &> /dev/null

        local git_head_upstream=$(git rev-parse HEAD@{u})
        local git_head_working=$(git rev-parse HEAD)

        if [ "$git_head_upstream" != "$git_head_working" ]; then
            # need to pull

            echo "git_head_upstream   = $git_head_upstream"
            echo "git_head_working    = $git_head_working"
            echo

            if [ ${#PS1} -gt 0 ]; then
                git pull
            else
                git pull &> /dev/null
            fi
        fi

    else

        git init
        git remote add origin git@github.com:josephtingiris/dotfiles
        git fetch
        git checkout -t origin/master -f
        git reset --hard
        git checkout -- .

    fi

    cd "$cwd"
}

##
### set default timezone
##

export TZ='America/New_York'

##
### returns to avoid interactive shell enhancements
##

if [[ "${SUDO_COMMAND}" == *"BECOME_SUCCESS"* ]]; then
    # ansible
    return
else
    if [ ${#SSH_CONNECTION} -gt 0 ] && [ ${#SSH_TTY} -eq 0 ]; then
        # ssh, no tty
        return
    fi
fi

##
### global alias definitions
##

alias cl='cd;clear'
alias cp='cp -i'
alias h='history'
alias hs='export HISTSIZE=0'
alias l='ls -lFhart'
alias ls='ls --color=tty'
alias mv='mv -i'
alias rm='rm -i'
alias root="sudo -u root /bin/bash --init-file ~${User_Name}/.bashrc"
alias suroot='sudo su -'
alias s='source ~/.bashrc'
alias sd='screen -S $(basename $(pwd))'
alias noname="find . -ls 2> /dev/null | awk '{print \$5}' | sort -u | grep ^[0-9]"

##
### global key bindings
##

set -o vi

# showkey -a
bind '"\x18\x40\x73\x6c":"'$User_Name'"' # Super+l
bind '"\x18\x40\x73\x75":"'$USER'"' # Super+u

##
### get tmux info
##

if [ ${#TMUX} -gt 0 ]; then
    export Tmux_Bin=$(ps -ho command -p $(env | grep ^TMUX= | head -1 | awk -F, '{print $2}') | awk '{print $1}')
else
    export Tmux_Bin=$(which --skip-alias tmux 2> /dev/null)
fi

if [ -x $Tmux_Bin ]; then
    if [ -r "${User_Dir}/.tmux.conf" ]; then
        Tmux_Info="[$Tmux_Bin] [${User_Dir}/.tmux.conf]"
        alias tmu=tmux
        alias tmus=tmux
        alias tmux="$Tmux_Bin -l -f ${User_Dir}/.tmux.conf -u"
    fi
fi

##
### preserve TERM for screen & tmux; handle TERM before prompt
##

if [[ "$TERM" != *"screen"* ]] && [[ "$TERM" != *"tmux"* ]]; then
    if [ ${#KONSOLE_DBUS_WINDOW} -gt 0 ]; then
        export TERM=konsole-256color # if it's a konsole dbus window then konsole-25color
    fi
fi

##
### custom, color prompt
##

if [ "$TERM" == "ansi" ] || [[ "$TERM" == *"color" ]] || [[ "$TERM" == *"xterm" ]]; then
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
    export PROMPT_COMMAND='printf "\033]0;%s\007" "$USER@$HOSTNAME:$PWD"'
fi

##
### if needed then create .inputrc (with preferences)
##

if [ ! -f ~/.inputrc ]; then
    echo "set bell-style none" > ~/.inputrc
fi

##
### check ssh, ssh-agent & add all potential keys (if they're not already added)
##

if [ ${#HOME} -gt 0 ] && [ -d "${HOME}" ]; then

    # if needed then generate an ssh key

    Ssh_Keygen=/usr/bin/ssh-keygen
    if [ ! -d "${HOME}/.ssh" ]; then
        if [ -x $Ssh_Keygen ]; then
            $Ssh_Keygen -t ed25519 -b 4096
        fi
        unset Ssh_Keygen
    fi

    # this works in conjunction with .bash_logout

    Ssh_Add=/usr/bin/ssh-add
    Ssh_Agent=/usr/bin/ssh-agent
    Ssh_Agent_File="${HOME}/.ssh-agent.${Who}@${HOSTNAME}"
    Ssh_Agent_Timeout=86400

    if [ -x $Ssh_Agent ] && [ -x $Ssh_Add ] && [ -x $Ssh_Keygen ]; then

        $Ssh_Add -l &> /dev/null
        if [ $? -eq 2 ]; then

            if [ -r "${Ssh_Agent_File}" ]; then
                eval "$(<${Ssh_Agent_File})" &> /dev/null
            fi

            $Ssh_Add -l &> /dev/null
            if [ $? -eq 2 ]; then
                # TODO: see if another ssh-agent is running by this user & use it rather than start a new one every time
                (umask 066; $Ssh_Agent -t $Ssh_Agent_Timeout 1> ${Ssh_Agent_File})
                eval "$(<${Ssh_Agent_File})" &> /dev/null
            fi

        fi

        Ssh_Dirs=()
        Ssh_Dirs+=(${HOME})
        Ssh_Dirs+=(${User_Dir})
        Ssh_Key_Files=()

        for Ssh_Dir in ${Ssh_Dirs[@]}; do
            if [ -r "${Ssh_Dir}/.ssh" ] && [ -d "${Ssh_Dir}/.ssh" ]; then
                while read Ssh_Key_File; do
                    Ssh_Key_Files+=($Ssh_Key_File)
                done <<< "$(find "${Ssh_Dir}/.ssh/" -name "*id_dsa" -o -name "*id_rsa" -o -name "*ecdsa_key" -o -name "*id_ed25519" 2> /dev/null)"
            fi
        done

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
                $Ssh_Keygen -l -f "${Ssh_Key_File}.pub" &> /dev/null
                if [ $? -ne 0 ]; then
                    # unsupported key type
                    continue
                fi
            else
                continue
            fi
            if [ -r "$Ssh_Key_File" ]; then
                Ssh_Agent_Key=$($Ssh_Add -l 2> /dev/null | grep $Ssh_Key_File 2> /dev/null)
                if [ "$Ssh_Agent_Key" == "" ]; then
                    if [ ${#PS1} -gt 0 ]; then
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

    unset Ssh_Add Ssh_Agent Ssh_Agent_File Ssh_Agent_Timeout

fi

##
### use the gnome keyring daemon (if it's available)
##

if [ -x /usr/bin/gnome-keyring-daemon ] && [ -r /etc/pam.d/kdm ]; then
    # http://tuxrocket.com/2013/01/03/getting-gnome-keyring-to-work-under-kde-and-kdm/
    # /etc/pam.d/kdm
    # session include common-pamkeyring
    /usr/bin/gnome-keyring-daemon start 1> /dev/null
fi

##
### mimic /etc/profile.d in home etc/profile.d directory
##

if  [ ${#HOME} -gt 0 ] && [ "${HOME}" != "/" ] && [ -d "${HOME}/etc/profile.d" ]; then
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

if [ "$USER" != "root" ]; then
    umask u+rw,g-rwx,o-rwx
fi

##
### set ctags
##

if [ $(which --skip-alias ctags 2> /dev/null) ]; then
    alias ctags="ctags --fields=+l --c-kinds=+p --c++-kinds=+p -f .tags"
fi

##
### set EDITOR
##

unset EDITOR
Editors=(nvim vim vi)
for Editor in ${Editors[@]}; do
    if [ $(which --skip-alias $Editor 2> /dev/null) ]; then
        export EDITOR="$(which --skip-alias $Editor 2> /dev/null)"
        if [ -r "${User_Dir}/.vimrc" ]; then
            alias vi="HOME=\"${User_Dir}\" $EDITOR --cmd \"let User_Name='$User_Name'\" --cmd \"let User_Dir='$User_Dir'\""
        else
            alias vi="$EDITOR"
        fi
        break
    fi
done
unset Editor Editors

##
### set LD_LIRBARY_PATH
##

if [ -r "${User_Dir}/opt/${Uname_R}/lib" ]; then
    if [ ${#LD_LIBRARY_PATH} -eq 0 ]; then
        export LD_LIBRARY_PATH="${User_Dir}/opt/${Uname_R}/lib"
    else
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${User_Dir}/opt/${Uname_R}/lib"
    fi
fi

##
### set git
##

if [ $(which --skip-alias git 2> /dev/null) ]; then
    export GIT_EDITOR=$EDITOR
    alias get=git
    alias gi=git
    alias giit=git
    alias git-config=gitConfig
    alias gc=gitConfig
    alias git-hub-dotfiles=githubDotfiles
    alias dotfiles=githubDotfiles
fi

##
### set more/less
##

if [ $(which --skip-alias less 2> /dev/null) ]; then
    alias more='less -r -Ms -T.tags -U -x4'
fi

##
### set svn
##

if [ $(which --skip-alias svn 2> /dev/null) ]; then
    export SVN_EDITOR=$EDITOR
fi

##
### display some useful information
##

if [ "$PS1" != "" ]; then
    echo

    if [ -r /etc/redhat-release ]; then
        cat /etc/redhat-release
        echo
    fi

    echo "${User_Dir}/.bashrc $Bashrc_Version"
    if [ "$TMUX" ]; then
        echo
        echo "$Tmux_Info [$TMUX]"
    fi
    echo
fi

