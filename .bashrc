# .bashrc

Bashrc_Version="20181127, joseph.tingiris@gmail.com"

##
### returns to avoid interactive shell enhancements
##

case $- in
    *i*)
        # interactive shell (OK)
        ;;
    *)
        # non-interactive shell
        return
        ;;
esac

if [ ${#PS1} -le 0 ]; then
    # no prompt
    return
fi

if [ ${#SSH_CONNECTION} -gt 0 ] && [ ${#SSH_TTY} -eq 0 ]; then
    # ssh, no tty
    return
fi

# non-login shells will *not* execute .bash_logout, and I want to know ...
if ! shopt -q login_shell &> /dev/null; then
    printf "\nNOTICE: interactive, but not a login shell\n"
fi

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

if type -P logname &> /dev/null; then
    export User_Name=$(logname 2> /dev/null)
else
    if type -P who &> /dev/null; then
        export User_Name=$(who -m 2> /dev/null)
    fi
fi
if [ ${#User_Name} -eq 0 ] && [ ${#SUDO_USER} -ne 0 ]; then export User_Name=${SUDO_USER}; fi
if [ ${#User_Name} -eq 0 ]; then export User_Name=${USER}; fi
if [ ${#User_Name} -gt 0 ]; then export Who="${User_Name%% *}"; fi

if [ ${#Who} -eq 0 ] && [ ${#USER} -eq 0 ]; then export Who=${USER}; fi
if [ ${#Who} -eq 0 ] && [ ${#LOGNAME} -gt 0 ]; then export Who=${LOGNAME}; fi
if [ ${#Who} -eq 0 ]; then
    export Who=UNKNOWN
    export User_Dir="/tmp"
else
    if type -P getent &> /dev/null; then
        export User_Dir=$(getent passwd ${Who} 2> /dev/null | awk -F: '{print $6}')
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

export Apex_User=${Who}@${HOSTNAME}
export Base_User=${Apex_User}

##
### set PATH automatically
##

cd &> /dev/null

unset -v Auto_Path

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
        Find_Paths+=($(eval "echo ${Auto_Path_Line}"))
    done <<< "$(grep -v '^#' ~/.Auto_Path 2> /dev/null)"
fi

for Find_Path in ${Find_Paths[@]}; do
    if [ -d /${Find_Path} ] && [ -r /${Find_Path} ]; then
        Find_Bins=$(find ${Find_Path}/ -maxdepth 2 -type d -name bin -printf "%d %p\n" -o -name sbin -printf "%d %p\n" 2> /dev/null | sort -n | awk '{print $NF}')
        for Find_Bin in ${Find_Bins}; do
            Auto_Path+=":${Find_Bin}"
        done
        unset -v Find_Bin Find_Bins
    fi
done
unset -v Find_Path Find_Paths

# after .Auto_Path, put /opt/rh bin & sbin directories in the path too
# rhscl; see https://wiki.centos.org/SpecialInterestGroup/SCLo/CollectionsList
if [ -d /opt/rh ] && [ -r ~/.Auto_Scl ]; then
    Rhscl_Roots=$(find /opt/rh/ -type f -name enable 2> /dev/null | sort -Vr)
    for Rhscl_Root in ${Rhscl_Roots}; do
        if [ -r "${Rhscl_Root}" ] && [ "${Rhscl_Root}" != "" ]; then
            Unset_Variables=$(grep ^export "${Rhscl_Root}" 2> /dev/null | awk -F= '{print $1}' 2> /dev/null | awk '{print $2}' 2> /dev/null | grep -v ^PATH$ | sort -u)
            for Unset_Variable in ${Unset_Variables}; do
                eval "unset -v ${Unset_Variable}"
            done
        fi
    done
    for Rhscl_Root in ${Rhscl_Roots}; do
        if [ -r "${Rhscl_Root}" ] && [ "${Rhscl_Root}" != "" ]; then
            . "${Rhscl_Root}"
        else
            continue
        fi
        Rhscl_Root="$(dirname "${Rhscl_Root}")/root"
        Rhscl_Bins="usr/local/bin usr/local/sbin usr/bin usr/sbin bin sbin"
        for Rhscl_Bin in ${Rhscl_Bins}; do
            if [ -d "${Rhscl_Root}/${Rhscl_Bin}" ]; then
                Auto_Path+=":${Rhscl_Root}/${Rhscl_Bin}"
            fi
        done
        unset -v Rhscl_Bin Rhscl_Bins Rhscl_Root Rhscl_Root
    done
    unset -v Rhscl_Root Rhscl_Roots
fi

# finally, add these to the end of Auto_Path
Auto_Path+=":/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

export PATH=${Auto_Path}:${PATH}

unset -v Auto_Path

OIFS=${IFS}
IFS=':' read -ra Auto_Path <<< "${PATH}"
Uniq_Path="./"
for Dir_Path in "${Auto_Path[@]}"; do
    if ! [[ "${Uniq_Path}" =~ (^|:)${Dir_Path}($|:) ]]; then
        if [ -r "${Dir_Path}" ] && [ "${Dir_Path}" != "" ]; then
            Uniq_Path+=":${Dir_Path}"
        fi
    fi
done
unset -v Dir_Path
IFS=${OIFS}

export PATH="${Uniq_Path}"

unset -v Uniq_Path

Man_Paths=()
Man_Paths+=(/usr/local/share/man)
Man_Paths+=(/usr/share/man)
for Man_Path in ${Man_Paths[@]}; do
    if ! [[ "${MANPATH}" =~ (^|:)${Man_Path}($|:) ]]; then
        if [ -r "${Man_Path}" ]; then
            export MANPATH+=":${Man_Path}"
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
    git config --global user.name "${USER}@${HOSTNAME}" &> /dev/null

}

# keep my home directory dotfiles up to date
function githubDotfiles() {

    local cwd=$(/usr/bin/pwd 2> /dev/null)
    cd ~

    if [ -d ~/.git ]; then

        git fetch &> /dev/null

        local git_head_upstream=$(git rev-parse HEAD@{u} 2> /dev/null)
        local git_head_working=$(git rev-parse HEAD 2> /dev/null)

        if [ "${git_head_upstream}" != "${git_head_working}" ]; then
            # need to pull
            printf "git_head_upstream   = ${git_head_upstream}\n"
            printf "git_head_working    = ${git_head_working}\n\n"

            git pull
        fi

    else

        git init
        git remote add origin git@github.com:josephtingiris/dotfiles
        git fetch
        git checkout -t origin/master -f
        git reset --hard
        git checkout -- .

    fi

    cd "${cwd}"
}

# if necessary, start ssh-agent
function sshAgent() {
    if [ ${#Ssh_Agent_Home} -gt 0 ] && [ ! -r "${Ssh_Agent_Home}" ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        # there's no .ssh-agent file and ssh agent forwarding is apparently off
        return 1
    fi

    if [ -x ${Ssh_Agent} ] && [ -x ${Ssh_Add} ] && [ -x ${Ssh_Keygen} ]; then

        # if needed then generate an ssh key
        if [ ! -d "${HOME}/.ssh" ]; then
            ${Ssh_Keygen} -t ed25519 -b 4096
        fi

        # ensure ssh-agent works
        ${Ssh_Add} -l &> /dev/null
        if [ $? -eq 2 ]; then
            if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
                (umask 066; ${Ssh_Agent} -t ${Ssh_Agent_Timeout} 1> ${Ssh_Agent_Hostname})
                eval "$(<${Ssh_Agent_Hostname})" &> /dev/null
            fi
            ${Ssh_Add} -l &> /dev/null
            if [ $? -gt 1 ]; then
                # starting ssh-agent failed
                return 1
            fi
            #else
            #if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
            # ssh-agent works; ssh agent forwarding is on .. start another/local agent anyway?
            #if [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
            #printf "NOTICE: SSH_AUTH_SOCK=${SSH_AUTH_SOCK}\n"
            #fi
            #fi
        fi

        # enable agent forwarding
        if [ "${#SSH_AUTH_SOCK}" -gt 0 ]; then
            alias ssh='ssh -A'
        fi

        Ssh_Key_Files=()

        Ssh_Dirs=()
        Ssh_Dirs+=(${HOME})
        Ssh_Dirs+=(${User_Dir})

        for Ssh_Dir in ${Ssh_Dirs[@]}; do
            if [ -r "${Ssh_Dir}/.ssh" ] && [ -d "${Ssh_Dir}/.ssh" ]; then
                while read Ssh_Key_File; do
                    Ssh_Key_Files+=(${Ssh_Key_File})
                done <<< "$(find "${Ssh_Dir}/.ssh/" -name "*id_dsa" -o -name "*id_rsa" -o -name "*ecdsa_key" -o -name "*id_ed25519" 2> /dev/null)"
            fi
        done

        Ssh_Configs=()
        Ssh_Configs+=("${HOME}/.ssh/config")
        Ssh_Configs+=("${User_Dir}/.ssh/config")
        Ssh_Configs+=("${HOME}/.git/GIT_SSH.config")
        Ssh_Configs+=("${User_Dir}/.git/GIT_SSH.config")
        Ssh_Configs+=("${HOME}/.subversion/SVN_SSH.config")
        Ssh_Configs+=("${User_Dir}/.subversion/SVN_SSH.config")

        for Ssh_Config in ${Ssh_Configs[@]}; do
            if [ -r "${Ssh_Config}" ]; then
                while read Ssh_Key_File; do
                    Ssh_Key_Files+=(${Ssh_Key_File})
                done <<< "$(grep IdentityFile "${Ssh_Config}" 2> /dev/null | awk '{print $NF}' | sort -u)"
                unset -v Ssh_Key_File
            fi
        done
        unset -v Ssh_Config Ssh_Configs

        eval Ssh_Key_Files=($(printf "%q\n" "${Ssh_Key_Files[@]}" | sort -u))

        for Ssh_Key_File in ${Ssh_Key_Files[@]}; do
            Ssh_Agent_Key=""
            Ssh_Key_Public=""
            if [ -r "${Ssh_Key_File}.pub" ]; then
                Ssh_Key_Public=$(awk '{print $2}' "${Ssh_Key_File}.pub" 2> /dev/null)
                Ssh_Agent_Key=$(${Ssh_Add} -L  2> /dev/null | grep "${Ssh_Key_Public}" 2> /dev/null)
                if [ "${Ssh_Agent_Key}" != "" ]; then
                    # public key is already in the agent
                    continue
                fi
                ${Ssh_Keygen} -l -f "${Ssh_Key_File}.pub" &> /dev/null
                if [ $? -ne 0 ]; then
                    # unsupported key type
                    continue
                fi
            else
                continue
            fi
            if [ -r "${Ssh_Key_File}" ]; then
                Ssh_Key_Private=$(${Ssh_Keygen} -l -f "${Ssh_Key_File}.pub" 2> /dev/null | awk '{print $2}')
                Ssh_Agent_Key=$(${Ssh_Add} -l 2> /dev/null | grep ${Ssh_Key_Private} 2> /dev/null)
                if [ "${Ssh_Agent_Key}" == "" ]; then
                    ${Ssh_Add} ${Ssh_Key_File}
                fi
                unset -v Ssh_Agent_Key
            fi
        done
        unset -v Ssh_Agent_Key Ssh_Key_File Ssh_Key_Private Ssh_Key_Public Ssh_Key_Files

        # hmm .. https://serverfault.com/questions/401737/choose-identity-from-ssh-agent-by-file-name
        # this will convert the stored ssh-keys to public files that can be used with IdentitiesOnly
        Md5sum=$(type -P md5sum)
        if [ -x "${Md5sum}" ] && [ -w "${HOME}/.ssh" ] && [ "${USER}" != "root" ]; then
            Ssh_Identities_Dir="${HOME}/.ssh/identity"

            if [ ! -d "${Ssh_Identities_Dir}" ]; then
                mkdir -p "${Ssh_Identities_Dir}"
                if [ $? -ne 0 ]; then
                    return 1
                fi
            fi

            chmod 0700 "${Ssh_Identities_Dir}" &> /dev/null
            if [ $? -ne 0 ]; then
                return 1
            fi

            while read Ssh_Public_Key; do
                Ssh_Public_Key_Md5sum=$(echo "${Ssh_Public_Key}" | awk '{print $2}' | ${Md5sum} | awk '{print $1}')
                if [ "${Ssh_Public_Key_Md5sum}" != "" ]; then
                    if [ -f "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub" ]; then
                        continue
                    fi
                    echo "${Ssh_Public_Key}" > "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub"
                    chmod 0400 "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub" &> /dev/null
                    if [ $? -ne 0 ]; then
                        return 1
                    fi
                fi
                unset -v Ssh_Public_Key_Md5sum
            done <<< "$(${Ssh_Add} -L)"
            unset -v Ssh_Public_Key
        fi
        # else ssh tools are not executable
    fi

    # use the gnome keyring daemon (if it's available)

    if [ -x /usr/bin/gnome-keyring-daemon ] && [ -r /etc/pam.d/kdm ]; then
        # http://tuxrocket.com/2013/01/03/getting-gnome-keyring-to-work-under-kde-and-kdm/
        # /etc/pam.d/kdm
        # session include common-pamkeyring
        /usr/bin/gnome-keyring-daemon start &> /dev/null
    fi
}

# ssh-agent validation
function sshAgentValidate() {

    export Ssh_Add=$(type -P ssh-add)
    if [ ${#Ssh_Add} -eq 0 ]; then
        return 1
    fi

    export Ssh_Agent=$(type -P ssh-agent)
    if [ ${#Ssh_Agent} -eq 0 ]; then
        return 1
    fi

    export Ssh_Agent_Home="${HOME}/.ssh-agent"
    export Ssh_Agent_Hostname="${Ssh_Agent_Home}.${Who}@${HOSTNAME}"

    export Ssh_Agent_Timeout=86400

    export Ssh_Keygen=$(type -P ssh-keygen)

    #env | grep -i ssh | LC_COLLATE=C sort
    #printf "before\n"
    #pgrep -a -u "${USER}" -f ${Ssh_Agent}\ -t\ ${Ssh_Agent_Timeout}

    if [ ${#SSH_AUTH_SOCK} -gt 0 ] && [ ! -r "${SSH_AUTH_SOCK}" ]; then
        unset SSH_AUTH_SOCK SSH_AGENT_PID
    fi

    if [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        if [ ${#Ssh_Agent_Hostname} -gt 0 ] && [ -r "${Ssh_Agent_Hostname}" ]; then
            eval "$(<${Ssh_Agent_Hostname})" &> /dev/null
        fi
    fi

    local ssh_agent_clean=1

    if [ ${#SSH_AGENT_PID} -eq 0 ]; then
        # SSH_AGENT_PID is not set
        ssh_agent_clean=0
    else
        if [ -d /proc/${SSH_AGENT_PID} ]; then
            if [ ${#Ssh_Agent_Hostname} -gt 0 ]; then
                if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
                    if [ ${#SSH_AUTH_SOCK} -gt 0 ] && [ ${#SSH_AGENT_PID} -gt 0 ]; then
                        # if everything matches then leave it running (until it expires)
                        if ! grep -q "^SSH_AGENT_PID=${SSH_AGENT_PID};" "${Ssh_Agent_Hostname}" &> /dev/null; then
                            # if it's running but everything doesn't match then update Ssh_Agent_Hostname
                            printf "SSH_AUTH_SOCK=%s; export SSH_AUTH_SOCK;\n" "${SSH_AUTH_SOCK}" > "${Ssh_Agent_Hostname}"
                            printf "SSH_AGENT_PID=%s; export SSH_AGENT_PID;\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_Hostname}"
                            printf "echo Agent pid %s\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_Hostname}"
                        fi
                    else
                        ssh_agent_clean=0
                    fi
                else
                    # ssh-agent was started manually? should it be running?
                    ssh_agent_clean=0
                fi
            else
                # should it be running without an agent hostname file?
                ssh_agent_clean=0
            fi
        else
            # SSH_AGENT_PID is set but the process isn't running
            ssh_agent_clean=0
        fi
    fi

    if [ $ssh_agent_clean -eq 0 ]; then
        if [ ${#Ssh_Agent_Hostname} -gt 0 ] && [ -r "${Ssh_Agent_Hostname}" ]; then
            rm -f "${Ssh_Agent_Hostname}" &> /dev/null
        fi
    fi

    local pid
    for pid in $(pgrep -u "${USER}" -f ${Ssh_Agent}\ -t\ ${Ssh_Agent_Timeout} 2> /dev/null); do
        if [ ${#SSH_AGENT_PID} -gt 0 ]; then
            if [ "${SSH_AGENT_PID}" == "$pid" ]; then
                if [ $ssh_agent_clean -eq 1 ]; then
                    # don't kill a valid agent
                    continue
                fi
            fi
        fi
        kill -9 $pid &> /dev/null
    done
    unset -v pid

    #printf "after\n"
    #pgrep -a -u "${USER}" -f ${Ssh_Agent}\ -t\ ${Ssh_Agent_Timeout}
}

##
### set default timezone
##

export TZ='America/New_York'

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
alias suroot='sudo su -'
if [ ${BASH_VERSINFO[0]} -ge 4 ]; then
    if [ ${BASH_VERSINFO[0]} -eq 4 ] && [ ${BASH_VERSINFO[1]} -lt 2 ]; then
        alias root="sudo SSH_AGENT_PID=${SSH_AGENT_PID} SSH_AUTH_SOCK=${SSH_AUTH_SOCK} -u root /bin/bash --init-file ~${User_Name}/.bashrc # 4.0-4.1"
    else
        alias root="sudo SSH_AGENT_PID=${SSH_AGENT_PID} SSH_AUTH_SOCK=${SSH_AUTH_SOCK} -u root /bin/bash --login --init-file ~${User_Name}/.bashrc # 4.2+"
    fi
else
    alias root=suroot
fi
alias s='source ~/.bashrc'
alias sd='screen -S $(basename $(pwd))'
alias noname="find . -ls 2> /dev/null | awk '{print \$5}' | sort -u | grep ^[0-9]"

##
### global key bindings
##

set -o vi

# showkey -a
bind '"\x18\x40\x73\x6c":"'${User_Name}'"' # Super+l
bind '"\x18\x40\x73\x75":"'${USER}'"' # Super+u

##
### get tmux info
##

if [ ${#TMUX} -gt 0 ]; then
    # already in a tmux
    #export Tmux_Bin=$(ps -ho command -p $(env | grep ^TMUX= | head -1 | awk -F, '{print $2}') | awk '{print $1}')
    export Tmux_Bin=$(ps -ho cmd -p $(ps -ho ppid -p $$ 2> /dev/null) 2> /dev/null | awk '{print $1}')
else
    # not in in a tmux
    export Tmux_Bin=$(type -P tmux 2> /dev/null)
fi

if [ ${#Tmux_Bin} -gt 0 ] && [ -x ${Tmux_Bin} ]; then
    if [ -r "${User_Dir}/.tmux.conf" ]; then
        Tmux_Info="[${Tmux_Bin}] [${User_Dir}/.tmux.conf]"
        alias tmu=tmux
        alias tmus=tmux
        alias tmux="${Tmux_Bin} -l -f ${User_Dir}/.tmux.conf -u"
    fi
fi

##
### preserve TERM for screen & tmux; handle TERM before prompt
##

if [[ "${TERM}" != *"screen"* ]] && [[ "${TERM}" != *"tmux"* ]]; then
    if [ ${#KONSOLE_DBUS_WINDOW} -gt 0 ]; then
        export TERM=konsole-256color # if it's a konsole dbus window then konsole-25color
    fi
fi

##
### custom, color prompt
##

case "${TERM}" in
    ansi|*color|*xterm)
        export PROMPT_COMMAND='printf "\033]0;%s\007" "${USER}@${HOSTNAME}:${PWD} [bash]"'

        function bash_command_prompt_command() {
            case "${BASH_COMMAND}" in
                *\033]0*)
                    # nested escapes can confuse the terminal, don't output them.
                    ;;
                *)
                    printf "\033]0;%s\007" "${USER}@${HOSTNAME}:${PWD} [${BASH_COMMAND}]"
                    ;;
            esac
        }

        # trap function debug

        trap bash_command_prompt_command DEBUG

        #export PS1="\[$(tput setaf 0)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # black
        #export PS1="\[$(tput setaf 1)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark red
        #export PS1="\[$(tput setaf 2)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark green
        #export PS1="\[$(tput setaf 3)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark yellow(ish)
        #export PS1="\[$(tput setaf 4)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark blue
        #export PS1="\[$(tput setaf 5)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark purple
        #export PS1="\[$(tput setaf 6)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark cyan
        #export PS1="\[$(tput setaf 7)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # grey
        #export PS1="\[$(tput setaf 8)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # dark grey
        #export PS1="\[$(tput setaf 9)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright red
        #export PS1="\[$(tput setaf 10)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright green
        #export PS1="\[$(tput setaf 11)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright yellow
        #export PS1="\[$(tput setaf 12)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright blue
        #export PS1="\[$(tput setaf 13)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright purple
        #export PS1="\[$(tput setaf 14)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright cyan
        #export PS1="\[$(tput setaf 15)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # white
        #export PS1="\[$(tput setaf 17)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # really dark blue

        if [ "${USER}" == "root" ]; then
            PS="#"
            export PS1="\[$(tput setaf 11)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright yellow
        else
            PS="$"
            export PS1="\[$(tput setaf 14)\][\u@\h \w]${PS} \[$(tput sgr0)\]" # bright cyan
        fi
        unset -v PS

        ;;
    *)
        ;;
esac

##
### if needed then create .inputrc (with preferences)
##

if [ ! -f ~/.inputrc ]; then
    echo "set bell-style none" > ~/.inputrc
fi

##
### check ssh, ssh-agent, gnome-keyring-daemon & add all potential keys (if they're not already added)
##

sshAgentValidate

if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
    sshAgent
else
    if [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        if [ -d "${HOME}/.ssh" ]; then
            # remind me; these keys probably shouldn't be here
            for Ssh_Key in "${HOME}/.ssh/id"*; do
                if [ -r "${Ssh_Key}" ]; then
                    printf "NOTICE: no ${Ssh_Agent_Home}; found ssh key file on ${HOSTNAME} '${Ssh_Key}'\n"
                fi
            done
            unset -v Ssh_Key
        fi
    else
        if [ ${#SSH_AUTH_SOCK} -gt 0 ] && [ -r "${SSH_AUTH_SOCK}" ]; then
            #printf "NOTICE: no ${Ssh_Agent_Home}; found readable SSH_AUTH_SOCK='${SSH_AUTH_SOCK}'\n"
            # ssh agent forwarding is probably on; load local keys anyway?
            sshAgent
        fi
    fi
fi

##
### mimic /etc/profile.d in home etc/profile.d directory
##

if  [ ${#HOME} -gt 0 ] && [ "${HOME}" != "/" ] && [ -d "${HOME}/etc/profile.d" ]; then
    SHELL=/bin/bash
    # Only display output from profile.d scripts if this is not a login shell
    # or is an interactive shell - otherwise just process them to set envvars
    for Home_Etc_Profile_D in ${HOME}/etc/profile.d/*.sh; do
        if [ -r "${Home_Etc_Profile_D}" ]; then
            . "${Home_Etc_Profile_D}"
        fi
    done
    unset -v Home_Etc_Profile_D
fi

if [ "${USER}" != "root" ]; then
    umask u+rw,g-rwx,o-rwx
fi

##
### set ctags
##

if type -P ctags &> /dev/null; then
    alias ctags="ctags --fields=+l --c-kinds=+p --c++-kinds=+p -f .tags"
fi

##
### set EDITOR
##

unset -v EDITOR
Editors=(nvim vim vi)
for Editor in ${Editors[@]}; do
    if type -P ${Editor} &> /dev/null; then
        export EDITOR="$(type -P ${Editor} 2> /dev/null)"
        if [ -r "${User_Dir}/.vimrc" ]; then
            alias vi="HOME=\"${User_Dir}\" ${EDITOR} --cmd \"let User_Name='${User_Name}'\" --cmd \"let User_Dir='${User_Dir}'\""
        else
            alias vi="${EDITOR}"
        fi
        break
    fi
done
unset -v Editor Editors

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

if type -P git &> /dev/null; then
    export GIT_EDITOR=${EDITOR}
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

if type -P less &> /dev/null; then
    alias more='less -r -Ms -T.tags -U -x4'
fi

##
### set svn
##

if type -P svn &> /dev/null; then
    export SVN_EDITOR=${EDITOR}
fi

##
### display some useful information
##

printf "\n"

if [ -r /etc/redhat-release ]; then
    cat /etc/redhat-release
    printf "\n"
fi

printf "${User_Dir}/.bashrc ${Bashrc_Version}\n\n"
if [ "${TMUX}" ]; then
    printf "${Tmux_Info} [${TMUX}]\n\n"
fi
