# .bashrc

Bashrc_Version="20190415, joseph.tingiris@gmail.com"

##
### returns to avoid interactive shell enhancements
##

if [ "$BASH_SOURCE" == "$0" ]; then
    # not meant to be run, only sourced
    exit
fi

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

if [ ${#SSH_CONNECTION} -gt 0 ] && [ ${#SSH_TTY} -eq 0 ] && [ ${#TMUX} -eq 0 ]; then
    # ssh, no tty, no tmux
    return
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

if [ -r /etc/os-release ]; then
    export Os_Id=$(cat /etc/os-release | sed -nEe 's#"##g;s#^ID=(.*)$#\1#p')
    export Os_Version_Id=$(cat /etc/os-release | sed -nEe 's#"##g;s#^VERSION_ID=(.*)$#\1#p')
fi

if [ ${#Os_Id} -gt 0 ]; then
    if [ ${#Os_Version_Id} -gt 0 ]; then
        export Os_Variant="${Os_Id}/${Os_Version_Id}"
    else
        export Os_Variant="${Os_Id}"
    fi
fi

export Uname_I=$(uname -i 2> /dev/null)

##
### determine true username
##

if [ "$EUID" == "0" ]; then
    USER="root"
fi

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

if [ ${#OLDPWD} -eq 0 ]; then
    cd &> /dev/null
fi

unset -v Auto_Path

# bin & sbin from the directories, in the following array, are automatically added in the order given
Find_Paths=()
Find_Paths+=("${HOME}")
Find_Paths+=("${User_Dir}")
if [ -r "${User_Dir}/opt/static/${Uname_I}" ]; then
    Find_Paths+=("${User_Dir}/opt/static/${Uname_I}")
fi
if [ -r "${User_Dir}/opt/${Os_Variant}/${Uname_I}" ]; then
    Find_Paths+=("${User_Dir}/opt/${Os_Variant}/${Uname_I}")
fi
Find_Paths+=("/apex")
Find_Paths+=("/base")

# add custom paths, in the order given in ~/.Auto_Path, before automatically finding bin paths
if [ -r ~/.Auto_Path ]; then
    while read Auto_Path_Line; do
        Find_Paths+=($(eval "echo ${Auto_Path_Line}"))
    done <<< "$(grep -v '^#' ${User_Dir}/.Auto_Path 2> /dev/null)"
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
if [ -d /opt/rh ] && [ -r ${User_Dir}/.Auto_Scl ]; then
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

# override dmesg
function dmesg() {
    local dmesg=$(type -P dmesg)

    if [ -x ${dmesg} ]; then
        ${dmesg} -TL $@ 2> /dev/null || ${dmesg} $@
    fi
}

# add stuff to my .gitconfig
function gitConfig() {

    if [ -f ~/.gitconfig.lock  ]; then
        rm -f ~/.gitconfig.local &> /dev/null
        Rm_Rc=$?
        if [ ${Rm_Rc} -ne 0 ]; then
            verbose "ALERT: failed to 'rm -f ~/.gitconfig.local', rc=${Rm_Rc}"
        fi
        unset -v Rm_Rc
    fi

    local git_config_globals=()
    git_config_globals+=("alias.b branch")
    git_config_globals+=("alias.info 'remote -v'")
    git_config_globals+=("alias.ls ls-files")
    git_config_globals+=("alias.restore 'checkout --'")
    git_config_globals+=("alias.rev-prase rev-parse")
    git_config_globals+=("alias.st status")
    git_config_globals+=("alias.s status")
    git_config_globals+=("alias.unstage 'reset --'")
    git_config_globals+=("alias.up pull")

    git_config_globals+=("color.ui auto")
    git_config_globals+=("color.branch auto")
    git_config_globals+=("color.status auto")

    git_config_globals+=("core.filemode false")

    git_config_globals+=("user.email ${USER}@${HOSTNAME}")
    git_config_globals+=("user.name ${USER}@${HOSTNAME}")

    if [[ $(git --version 2> /dev/null | grep 'version 1.9.') ]]; then
        # only support this for git 1.9.x
        git_config_globals+=("push.default simple")
    fi

    # set if not set but don't overwrite
    local git_config_global git_config_global_key git_config_global_value
    for git_config_global in "${git_config_globals[@]}"; do
        git_config_global_key=${git_config_global%% *}
        git_config_global_value=${git_config_global#* }
        git_config_global_value=${git_config_global_value//\'/}
        if git_config_global=$(git config --get --global ${git_config_global_key}); then
            if [ "${git_config_global}" == "${git_config_global_value}" ]; then
                verbose "INFO: git_config_global: ${git_config_global_key} ${git_config_global_value}"
            else
                verbose "NOTICE: git_config_global: ${git_config_global_key} ${git_config_global_value} != ${git_config_global}"
            fi
        else
            verbose "ALERT: git_config_global: ${git_config_global_key} ${git_config_global_value}"
            git config --global ${git_config_global_key} "${git_config_global_value}"
        fi
    done

}

# keep my home directory dotfiles up to date
function githubDotfiles() {

    local cwd=$(/usr/bin/pwd 2> /dev/null)
    cd ${User_Dir}

    if [ -d ${User_Dir}/.git ]; then

        git fetch &> /dev/null

        local git_head_upstream=$(git rev-parse HEAD@{u} 2> /dev/null)
        local git_head_working=$(git rev-parse HEAD 2> /dev/null)

        if [ "${git_head_upstream}" != "${git_head_working}" ]; then
            # need to pull
            verbose "NOTICE: git_head_upstream = ${git_head_upstream}"
            verbose "NOTICE: git_head_working = ${git_head_working}\n"

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

    if ! sshAgentClean; then
        verbose "EMERGENCY: sshAgentClean failed"
        return 1
    fi

    verbose "DEBUG: ${FUNCNAME} start SSH_AGENT_PID=${SSH_AGENT_PID}"
    verbose "DEBUG: ${FUNCNAME} start SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"

    if [ ${#Ssh_Agent_Home} -gt 0 ]; then

        if [ ! -r "${Ssh_Agent_Home}" ]; then
            if [ -d "${HOME}/.ssh" ]; then
                # remind me; these keys probably shouldn't be here
                for Ssh_Key in "${HOME}/.ssh/id"*; do
                    if [ -r "${Ssh_Key}" ]; then
                        verbose "WARNING: no ${Ssh_Agent_Home}; found ssh key file on ${HOSTNAME} '${Ssh_Key}'"
                    fi
                done
                unset -v Ssh_Key
            fi
        fi

        if [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
            if [ ! -r "${Ssh_Agent_Home}" ]; then
                # there's no .ssh-agent file and ssh agent forwarding is apparently off
                verbose "ALERT: no ${Ssh_Agent_Home}; ssh agent forwarding is apparently off"
                return 0
            fi
        fi
    fi

    export Ssh_Agent=$(type -P ssh-agent)
    if [ ${#Ssh_Agent} -eq 0 ] || [ ! -x ${Ssh_Agent} ]; then
        verbose "EMERGENCY: ssh-agent not usable"
        return 1
    fi

    export Ssh_Keygen=$(type -P ssh-keygen)
    if [ ${#Ssh_Keygen} -eq 0 ] || [ ! -x ${Ssh_Keygen} ]; then
        verbose "EMERGENCY: ssh-keygen not usable"
        return 1
    fi

    # if needed then generate an ssh key
    if [ ! -d "${HOME}/.ssh" ]; then
        ${Ssh_Keygen} -t ed25519 -b 4096
    fi

    # (re)start ssh-agent if necessary
    if [ ${#SSH_AGENT_PID} -eq 0 ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
            (umask 066; ${Ssh_Agent} -t ${Ssh_Agent_Timeout} 1> ${Ssh_Agent_State})
            eval "$(<${Ssh_Agent_State})" &> /dev/null
        fi
    fi

    # ensure ssh-add works or output an error message & return
    Ssh_Add_Out=$(${Ssh_Add} -l 2> /dev/null)
    Ssh_Add_Rc=$?
    if [ ${Ssh_Add_Rc} -eq 0 ]; then
        if [ ${#SSH_AGENT_PID} -eq 0 ] && [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
            # ssh-add apparently works; ssh agent forwarding is apparently on .. start another/local agent anyway?
            if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
                verbose "ALERT: ignoring ${Ssh_Agent_Home}"
            fi
            verbose "ALERT: ssh agent forwarding via SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
        fi
    else
        # starting ssh-add failed (the first time)
        if [ ${#Ssh_Add_Rc} -eq 1 ]; then
            # rc=1 means 'failure', it's unspecified and may just be that it has no identities
            if [[ "${Ssh_Add_Out}" != *"agent has no identities"* ]]; then
                verbose "ALERT: '${Ssh_Add}' failed with SSH_AGENT_PID=${SSH_AGENT_PID}, SSH_AUTH_SOCK=${SSH_AUTH_SOCK}, output='${Ssh_Add_Out}', rc=${Ssh_Add_Rc}"
            fi
        else
            verbose "EMERGENCY: '${Ssh_Add}' failed with SSH_AGENT_PID=${SSH_AGENT_PID}, SSH_AUTH_SOCK=${SSH_AUTH_SOCK}, output='${Ssh_Add_Out}' rc=${Ssh_Add_Rc}"
            if [ ${#SSH_AGENT_PID} -gt 0 ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
                # it's a bad SSH_AGENT_PID
                unset -v SSH_AGENT_PID
            else
                if [ ${#SSH_AGENT_PID} -eq 0 ] && [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
                    # it's a bad SSH_AUTH_SOCK
                    unset -v SSH_AUTH_SOCK
                else
                    unset -v SSH_AGENT_PID
                    unset -v SSH_AUTH_SOCK
                fi
            fi
            return 1
        fi
    fi
    unset -v Ssh_Add_Out Ssh_Add_Rc

    # always enable agent forwarding?
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
    unset -v Ssh_Add_Rc

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
            done <<< "$(grep IdentityFile "${Ssh_Config}" 2> /dev/null | awk '{print $NF}' | grep -v \.pub$ | sort -u)"
            unset -v Ssh_Key_File
        fi
    done
    unset -v Ssh_Config Ssh_Configs

    eval Ssh_Key_Files=($(printf "%q\n" "${Ssh_Key_Files[@]}" | sort -u))

    for Ssh_Key_File in ${Ssh_Key_Files[@]}; do
        Ssh_Agent_Key=""
        Ssh_Key_Public=""
        Ssh_Key_Private=""

        if [ -r "${Ssh_Key_File}.pub" ]; then
            Ssh_Key_Public=$(awk '{print $2}' "${Ssh_Key_File}.pub" 2> /dev/null)
            Ssh_Agent_Key=$(${Ssh_Add} -L  2> /dev/null | grep "${Ssh_Key_Public}" 2> /dev/null)

            if [ "${Ssh_Agent_Key}" != "" ]; then
                # public key is already in the agent
                continue
            fi

            # ensure the agent supports this key type
            ${Ssh_Keygen} -l -f "${Ssh_Key_File}.pub" &> /dev/null
            Ssh_Keygen_Rc=$?
            if [ ${Ssh_Keygen_Rc} -ne 0 ]; then
                # unsupported key type
                verbose "WARNING: ${Ssh_Key_File}.pub is of an unsupported key type"
                continue
            fi
            unset -v Ssh_Keygen_Rc

        else
            # key file is not readable
            continue
        fi

        if [ -r "${Ssh_Key_File}" ]; then
            Ssh_Key_Private=$(${Ssh_Keygen} -l -f "${Ssh_Key_File}.pub" 2> /dev/null | awk '{print $2}')
            Ssh_Agent_Key=$(${Ssh_Add} -l 2> /dev/null | grep ${Ssh_Key_Private} 2> /dev/null)
            if [ "${Ssh_Agent_Key}" == "" ]; then

                # add the key to the agent
                printf "\n"
                ${Ssh_Add} ${Ssh_Key_File}
                Ssh_Add_Rc=$?
                if [ ${Ssh_Add_Rc} -ne 0 ]; then
                    verbose "ALERT: '${Ssh_Add} ${Ssh_Key_File}', rc=${Ssh_Add_Rc}"
                fi
                unset -v Ssh_Add_Rc

            fi
            unset -v Ssh_Agent_Key
        fi
    done
    unset -v Ssh_Agent_Key Ssh_Key_File Ssh_Key_Private Ssh_Key_Public Ssh_Key_Files

    # hmm .. https://serverfault.com/questions/401737/choose-identity-from-ssh-agent-by-file-name
    # this will convert the stored ssh-keys to public files that can be used with IdentitiesOnly
    Md5sum=$(type -P md5sum)
    if [ -x "${Md5sum}" ] && [ -w "${HOME}/.ssh" ] && [ "${USER}" != "root" ]; then
        Ssh_Identities_Dir="${HOME}/.ssh/md5sum"

        if [ ! -d "${Ssh_Identities_Dir}" ]; then
            mkdir -p "${Ssh_Identities_Dir}"
            Mkdir_Rc=$?
            if [ ${Mkdir_Rc} -ne 0 ]; then
                verbose "EMERGENCY: failed to 'mkdir -p ${Ssh_Identities_Dir}', rc=${Mkdir_Rc}"
                return 1
            fi
            unset -v Mkdir_Rc
        fi

        chmod 0700 "${Ssh_Identities_Dir}" &> /dev/null
        Chmod_Rc=$?
        if [ ${Chmod_Rc} -ne 0 ]; then
            verbose "EMERGENCY: failed to 'chmod -700 ${Ssh_Identities_Dir}', rc=${Chmod_Rc}"
            return 1
        fi
        unset -v Chmod_Rc

        while read Ssh_Public_Key; do
            Ssh_Public_Key_Md5sum=$(printf "${Ssh_Public_Key}" | awk '{print $2}' | ${Md5sum} | awk '{print $1}')
            if [ "${Ssh_Public_Key_Md5sum}" != "" ]; then
                if [ -f "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub" ]; then
                    continue
                fi
                printf "${Ssh_Public_Key}" > "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub"
                chmod 0400 "${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub" &> /dev/null
                Chmod_Rc=$?
                if [ ${Chmod_Rc} -ne 0 ]; then
                    verbose "EMERGENCY: failed to 'chmod 0400 ${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub', rc=${Chmod_Rc}"
                    return 1
                fi
                unset -v Chmod_Rc
            fi
            unset -v Ssh_Public_Key_Md5sum
        done <<< "$(${Ssh_Add} -L)"
        unset -v Ssh_Public_Key
    fi

}

function sshAgentClean() {

    export Ssh_Add=$(type -P ssh-add)
    if [ ${#Ssh_Add} -eq 0 ] || [ ! -x ${Ssh_Add} ]; then
        pkill ssh-agent &> /dev/nulll
        verbose "EMERGENCY: ssh-add not usable"
        return 1
    fi

    export Ssh_Agent_Home="${HOME}/.ssh-agent"
    export Ssh_Agent_State="${Ssh_Agent_Home}.${Who}@${HOSTNAME}"
    export Ssh_Agent_Timeout=86400

    if [ -s "${Ssh_Agent_State}" ]; then
        if [ ${#SSH_AGENT_PID} -gt 0 ] || [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
            # SSH_AUTH_SOCK may not yet be set
            eval "$(<${Ssh_Agent_State})" &> /dev/null
        else
            if [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
                if grep -q "^SSH_AUTH_SOCK=${SSH_AUTH_SOCK};" "${Ssh_Agent_State}"; then
                    # SSH_AGENT_PID got unset somehow
                    eval "$(<${Ssh_Agent_State})" &> /dev/null
                fi
            fi
        fi
    else
        if [ -f "${Ssh_Agent_State}" ]; then
            verbose "ALERT: removing empty ${Ssh_Agent_State}"
            rm -f "${Ssh_Agent_State}" &> /dev/null
            Rm_Rc=$?
            if [ ${Rm_Rc} -ne 0 ]; then
                verbose "ALERT: failed to 'rm -f ${Ssh_Agent_State}', rc=${Rm_Rc}"
            fi
            unset -v Rm_Rc
        else
            if [ ${#SSH_AGENT_PID} -gt 0 ] && [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
                # missing Ssh_Agent_State; create one
                printf "SSH_AUTH_SOCK=%s; export SSH_AUTH_SOCK;\n" "${SSH_AUTH_SOCK}" > "${Ssh_Agent_State}"
                printf "SSH_AGENT_PID=%s; export SSH_AGENT_PID;\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_State}"
                printf "echo Agent pid %s\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_State}"
            fi
        fi
    fi

    if [ -w "${Ssh_Agent_State}" ]; then
        chmod 0600 "${Ssh_Agent_State}" &> /dev/null
    fi

    local ssh_agent_socket_command
    if [ ${#SSH_AGENT_PID} -gt 0 ]; then
        ssh_agent_socket_command=$(ps -h -o comm -p ${SSH_AGENT_PID} 2> /dev/null)
        if [ "${ssh_agent_socket_command}" != "ssh-agent" ] && [ "${ssh_agent_socket_command}" != "sshd" ]; then
            verbose "WARNING: SSH_AGENT_PID=${SSH_AGENT_PID} process not found"
            unset -v SSH_AGENT_PID
        fi
    fi

    if [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
        if [ -S "${SSH_AUTH_SOCK}" ]; then
            if [ ! -w "${SSH_AUTH_SOCK}" ]; then
                verbose "WARNING: ${SSH_AUTH_SOCK} socket not found writable"
                unset -v SSH_AUTH_SOCK
                if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                    kill ${SSH_AGENT_PID} &> /dev/null
                    unset -v SSH_AGENT_PID
                fi
            fi
        else
            # SSH_AUTH_SOCK is not a socket
            verbose "WARNING: ${SSH_AUTH_SOCK} is not a socket"
            unset -v SSH_AUTH_SOCK
            if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                kill ${SSH_AGENT_PID} &> /dev/null
                unset -v SSH_AGENT_PID
            fi
        fi
    fi

    if [ ${#SSH_AGENT_PID} -eq 0 ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        if [ -s "${Ssh_Agent_State}" ]; then
            verbose "ALERT: removing invalid ${Ssh_Agent_State}"
            rm -f "${Ssh_Agent_State}" &> /dev/null
            Rm_Rc=$?
            if [ ${Rm_Rc} -ne 0 ]; then
                verbose "ALERT: failed to 'rm -f ${Ssh_Agent_State}', rc=${Rm_Rc}"
            fi
            unset -v Rm_Rc
        fi
    fi

    # remove old ssh_agent_pids as safely as possible
    local ssh_agent_pid ssh_agent_state_pid
    # don't kill the Ssh_Agent_State
    if [ -s "${Ssh_Agent_State}" ]; then
        ssh_agent_state_pid=$(grep "^SSH_AGENT_PID=" "${Ssh_Agent_State}" 2> /dev/null | awk -F\; '{print $1}' | awk -F= '{print $NF}')
    fi
    if [ ${#Ssh_Agent} -gt 0 ]; then
        for ssh_agent_pid in $(pgrep -u "${USER}" -f ${Ssh_Agent} -P 1 2> /dev/null); do
            if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                if [ "${ssh_agent_pid}" == "${SSH_AGENT_PID}" ]; then
                    # don't kill a running agent
                    continue
                fi
            fi
            if [ ${#ssh_agent_state_pid} -gt 0 ]; then
                if [ "${ssh_agent_pid}" == "${ssh_agent_state_pid}" ]; then
                    # don't kill a running agent
                    continue
                fi
            fi
            verbose "ALERT: killing old ssh_agent_pid='${ssh_agent_pid}'"
            kill ${ssh_agent_pid} &> /dev/null
        done
        unset -v ssh_agent_pid ssh_agent_state_pid
    fi

    # remove old ssh_agent_sockets as safely as possible
    local ssh_agent_socket ssh_agent_socket_pid ssh_auth_sock
    ssh_auth_sock=$SSH_AUTH_SOCK
    while read ssh_agent_socket; do
        ssh_agent_socket_pid=""
        ssh_agent_socket_command=""

        if [ "${ssh_agent_socket}" == "" ] || [ ! -w "${ssh_agent_socket}" ]; then
            continue
        fi

        ssh_agent_socket_pid=${ssh_agent_socket##*.}
        if [[ ${ssh_agent_socket_pid} =~ ^[0-9]+$ ]]; then

            ssh_agent_socket_command=$(ps -h -o comm -p ${ssh_agent_socket_pid} 2> /dev/null)

            if [ "${ssh_agent_socket_command}" != "startkde" ] && [ "${ssh_agent_socket_command}" != "sshd" ]; then
                ((++ssh_agent_socket_pid))
                ssh_agent_socket_command=$(ps -h -o comm -p ${ssh_agent_socket_pid} 2> /dev/null)
            fi
        fi

        if [ "${ssh_agent_socket_command}" == "startkde" ] || [ "${ssh_agent_socket_command}" == "sshd" ] || [ "${ssh_agent_socket_command}" == "ssh-agent" ]; then
            #echo "bug here? SSH_AUTH_SOCK=${ssh_agent_socket} ${Ssh_Add} -l ${ssh_agent_socket}"
            # sometimes ssh-add fails to read the socket & takes 3+ minutes to timeout; if it takes longer than 5 seconds
            # to read the socket then remove it (it's unusable)
            SSH_AUTH_SOCK=${ssh_agent_socket} timeout 5 ${Ssh_Add} -l ${ssh_agent_socket} &> /dev/null
            Ssh_Add_Rc=$?
            if [ ${Ssh_Add_Rc} -gt 1 ]; then
                # definite error
                verbose "ALERT: (1) removing unusable ssh_agent_socket ${ssh_agent_socket}, comm=${ssh_agent_socket_command}, pid=${ssh_agent_socket_pid}, ${Ssh_Add} rc=${Ssh_Add_Rc}"
                rm -f ${ssh_agent_socket} &> /dev/null
                Rm_Rc=$?
                if [ ${Rm_Rc} -ne 0 ]; then
                    verbose "ALERT: failed to 'rm -f ${ssh_agent_socket}', rc=${Rm_Rc}"
                fi
                unset -v ssh_auth_sock
                unset -v Rm_Rc
            else
                # don't remove sockets with running ssh processes
                continue
            fi
            unset -v Ssh_Add_Rc
        else
            verbose "ALERT: (2) removing dead ssh_agent_socket ${ssh_agent_socket}, comm=${ssh_agent_socket_command}, pid=${ssh_agent_socket_pid}, ${Ssh_Add} rc=${Ssh_Add_Rc}"
            rm -f ${ssh_agent_socket} &> /dev/null
            Rm_Rc=$?
            if [ ${Rm_Rc} -ne 0 ]; then
                verbose "ALERT: failed to 'rm -f ${ssh_agent_socket}', rc=${Rm_Rc}"
            fi
            unset -v ssh_auth_sock
            unset -v Rm_Rc
        fi
        # also find really old sockets & remove them regardless if they still work or not?
    done <<<"$(find /tmp -type s -name "agent\.*" 2> /dev/null)"

    if [ ${#ssh_auth_sock} -gt 0 ] && [ -S "${ssh_auth_sock}" ]; then
        SSH_AUTH_SOCK=$ssh_auth_sock
    fi

    unset -v ssh_agent_socket ssh_agent_socket_pid ssh_agent_socket_command ssh_auth_sock

    # it's possible this condition could happen (again) if a socket's removed
    if [ ${#SSH_AGENT_PID} -gt 0 ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        unset -v SSH_AGENT_PID
    fi
}

# output more verbose messages based on a verbosity level set in the environment or a specific file
function verbose() {
    # verbose level is usually the last argument
    local verbose_arguments=($@)

    local -i verbose_color
    local verbose_level verbose_message

    local -i verbosity

    # if these values are set with an integer that will be honored, otherwise a verbosity value of 1 will be set
    if [ ${#Verbose} -gt 0 ]; then
        # if it's an integer then use that value, otherwise set verbosity to one
        if [[ ${Verbose} =~ ^[0-9]+$ ]]; then
            verbosity=${Verbose}
        else
            verbosity=1
        fi
    else
        if [ ${#VERBOSE} -gt 0 ]; then
            # if it's an integer then use that value, otherwise set verbosity to one
            if [[ ${VERBOSE} =~ ^[0-9]+$ ]]; then
                verbosity=${VERBOSE}
            else
                verbosity=1
            fi
        else
            verbosity=1
        fi
    fi

    if [ ${#2} -gt 0 ]; then
        verbose_message=(${verbose_arguments[@]}) # preserve verbose_arguments
        verbose_level=${verbose_message[${#verbose_message[@]}-1]}
    else
        verbose_message="${1}"
        verbose_level=""
    fi

    # 0 EMERGENCY, 1 ALERT, 2 CRIT(ICAL), 3 ERROR, 4 WARN(ING), 5 NOTICE, 6 INFO(RMATIONAL), 7 DEBUG

    if [[ ${verbose_level} =~ ^[0-9]+$ ]]; then
        # given verbose_level is always used
        if [ ${#2} -gt 0 ]; then
            # remove the last (integer) element (verbose_level) from the array & convert verbose_message to a string
            unset 'verbose_message[${#verbose_message[@]}-1]'
        fi
        verbose_message="${verbose_message[@]}"
    else
        # don't change the array, convert it to a string, and explicitly set verbose_level so the message gets displayed
        verbose_message="${verbose_message[@]}"

        # convert verbose_message to uppercase & check for presence of keywords
        if [[ "${verbose_message^^}" == *"ALERT"* ]]; then
            verbose_level=1
        else
            if [[ "${verbose_message^^}" == *"CRIT"* ]]; then
                verbose_level=2
            else
                if [[ "${verbose_message^^}" == *"ERROR"* ]]; then
                    verbose_level=3
                else
                    if [[ "${verbose_message^^}" == *"WARN"* ]]; then
                        verbose_level=4
                    else
                        if [[ "${verbose_message^^}" == *"NOTICE"* ]]; then
                            verbose_level=5
                        else
                            if [[ "${verbose_message^^}" == *"INFO"* ]]; then
                                verbose_level=6
                            else
                                if [[ "${verbose_message^^}" == *"DEBUG"* ]]; then
                                    verbose_level=7
                                else
                                    # EMERGENCY (always gets displayed)
                                    verbose_level=0
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi

    fi

    local -l verbose_level_prefix

    if [[ "${Verbose_Level_Prefix}" =~ ^(0|on|true)$ ]]; then
        verbose_level_prefix=0
    else
        verbose_level_prefix=1
    fi

    if [ ${verbose_level} -eq 1 ]; then
        verbose_color=1
        if [ ${verbose_level_prefix} -eq 0 ] && [[ "${verbose_message^^}" != *"ALERT"* ]]; then
            verbose_message="ALERT: ${verbose_message}"
        fi
    else
        if [ ${verbose_level} -eq 2 ]; then
            verbose_color=3
            if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"CRIT"* ]]; then
                verbose_message="CRITICAL: ${verbose_message}"
            fi
        else
            if [ ${verbose_level} -eq 3 ]; then
                verbose_color=5
                if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"ERROR"* ]]; then
                    verbose_message="ERROR: ${verbose_message}"
                fi
            else
                if [ ${verbose_level} -eq 4 ]; then
                    verbose_color=2
                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"WARN"* ]]; then
                        verbose_message="WARNING: ${verbose_message}"
                    fi
                else
                    if [ ${verbose_level} -eq 5 ]; then
                        verbose_color=6
                        if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"NOTICE"* ]]; then
                            verbose_message="NOTICE: ${verbose_message}"
                        fi
                    else
                        if [ ${verbose_level} -eq 6 ]; then
                            verbose_color=4
                            if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"INFO"* ]]; then
                                verbose_message="INFO: ${verbose_message}"
                            fi
                        else
                            if [ ${verbose_level} -eq 7 ]; then
                                verbose_color=7
                                if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"DEBUG"* ]]; then
                                    verbose_message="DEBUG: ${verbose_message}"
                                fi
                            else
                                if [ ${verbose_level} -eq 0 ]; then
                                    verbose_color=0
                                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"EMERGENCY"* ]]; then
                                        verbose_message="EMERGENCY: ${verbose_message}"
                                    fi
                                else
                                    verbose_color=8
                                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message^^}" != *"DEBUG"* ]]; then
                                        verbose_message="XDEBUG: ${verbose_message}"
                                    fi
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi

    # be pendantic; ensure there are integer values to avoid any possibility of comparison errors

    if [ ${#verbosity} -eq 0 ] || [[ ! ${verbosity} =~ ^[0-9]+$ ]]; then
        verbosity=0
    fi

    if [ ${#verbose_level} -eq 0 ] || [[ ! ${verbose_level} =~ ^[0-9]+$ ]]; then
        verbose_level=0
    fi

    if [ ${verbosity} -ge ${verbose_level} ]; then

        local v1 v2

        if [[ "${verbose_message^^}" == *":"* ]]; then
            v1="${verbose_message%%:*}"
            v1="${v1#"${v1%%[![:space:]]*}"}"
            v1="${v1%"${v1##*[![:space:]]}"}"
            v2="${verbose_message#*:}"
            v2="${v2#"${v2%%[![:space:]]*}"}"
            v2="${v2%"${v2##*[![:space:]]}"}"
            printf -v verbose_message "%-11b : %b" "${v1}" "${v2}"
            unset v1 v2
        fi

        if [[ "${verbose_message^^}" == *"="* ]]; then
            v1="${verbose_message%%=*}"
            v1="${v1#"${v1%%[![:space:]]*}"}"
            v1="${v1%"${v1##*[![:space:]]}"}"
            v2="${verbose_message#*=}"
            v2="${v2#"${v2%%[![:space:]]*}"}"
            v2="${v2%"${v2##*[![:space:]]}"}"
            printf -v verbose_message "%-40b = %b" "${v1}" "${v2}"
            unset v1 v2
        fi

        if [ -x $(type -P tput) ]; then
            if [ ${verbose_level} -eq 0 ]; then
                # EMERGENCY (0), black is special; standout mode with white background color
                verbose_message="${TPUT_SMSO}${TPUT_SETAF_8}${verbose_message}${TPUT_SGR0}"
            else
                if [ ${#verbose_color} -eq 0 ]; then
                    verbose_color=${verbose_level}
                fi
                local tput_set_af_v="TPUT_SETAF_${verbose_color}"
                verbose_message="${TPUT_BOLD}${!tput_set_af_v}${verbose_message}${TPUT_SGR0}"
                unset -v tput_set_af_v
            fi
        fi
        (>&2 printf "%b\n" "${verbose_message}")
    fi

    unset -v verbose_level verbosity
}

# locate files & vi them
function viLocate() {
    local vi_locates=($@)
    verbose "ALERT: vi locates '${vi_locates[@]}'\n"
    local vi_file vi_files vi_locate

    vi_files=()

    for vi_locate in ${vi_locates[@]}; do
        if [ -r "${vi_locate}" ] && [ ! -d "${vi_locate}" ]; then
            vi_files+=(${vi_locate})
        else
            if [ -x $(type -P locate) ]; then
                while read vi_file; do
                    if [ -r "${vi_file}" ] && [ ! -d "${vi_file}" ]; then
                        vi_files+=($vi_file)
                    fi
                done <<< "$(locate -r "/${vi_locate}$" | sort)"
            else
                if [ -x $(type -P which) ]; then
                    while read vi_file; do
                        if [ -r "${vi_file}" ] && [ ! -d "${vi_file}" ]; then
                            vi_files+=($vi_file)
                        fi
                    done <<< "$(which  "${vi_locate}" | sort)"
                fi
            fi
        fi
    done

    if [ ${#vi_files} -eq 0 ]; then
        vi_files=(${vi_locates[@]})
    fi

    if [[ "${EDITOR}" == *"vim"* ]] && [ -r "${User_Dir}/.vimrc" ]; then
        HOME="${User_Dir}" ${EDITOR} --cmd "let User_Name='${User_Name}'" --cmd "let User_Dir='${User_Dir}'" $(printf "%b " "${vi_files[@]}")
    else
        ${EDITOR} $(printf "%b " "${vi_files[@]}")
    fi
}

##
### Main
##

# this is mainly for performance; as long as TERM doesn't change then there's no need to run tput every time
if [ "$TERM" != "$TPUT_TERM" ]; then
    if [ -x $(type -P tput) ]; then
        export TPUT_TERM=$TERM
        export TPUT_BOLD="$(tput bold)"
        export TPUT_SETAF_0="$(tput setaf 0)"
        export TPUT_SETAF_1="$(tput setaf 1)"
        export TPUT_SETAF_2="$(tput setaf 2)"
        export TPUT_SETAF_3="$(tput setaf 3)"
        export TPUT_SETAF_4="$(tput setaf 4)"
        export TPUT_SETAF_5="$(tput setaf 5)"
        export TPUT_SETAF_6="$(tput setaf 6)"
        export TPUT_SETAF_7="$(tput setaf 7)"
        export TPUT_SETAF_8="$(tput setaf 8)"
        export TPUT_SGR0="$(tput sgr0)"
        export TPUT_SMSO="$(tput smso)"
    fi
fi

##
### trap EXIT to ensure .bash_logout gets called, regardless of whether or not it's a login shell
##

# non-login shells will *not* execute .bash_logout, and I want to know ...
if ! shopt -q login_shell &> /dev/null; then
    verbose "INFO: interactive, but not a login shell\n"
fi

if [ -r "${User_Dir}/.bash_logout" ]; then
    if [ ${#TMUX_PANE} -eq 0 ]; then
        trap "source ${User_Dir}/.bash_logout" EXIT
    else
        trap "source ${User_Dir}/.bash_logout;tmux kill-pane -t ${TMUX_PANE}" EXIT
    fi
else
    if [ -r "${HOME}/.bash_logout" ]; then
        if [ ${#TMUX_PANE} -eq 0 ]; then
            trap "source ${HOME}/.bash_logout" EXIT
        else
            trap "source ${User_Dir}/.bash_logout;tmux kill-pane -t ${TMUX_PANE}" EXIT
        fi
    fi
fi

##
### set Verbose
##

for verbose_file in "${HOME}/.verbose" "${HOME}/.bashrc.verbose"; do
    if [ -r "${verbose_file}" ]; then
        # get digits only from the first line; if they're not digits then set verbosity to one
        export Verbose=$(grep -m1 "^[0-9]*$" "${verbose_file}" 2> /dev/null)
        if [ ${#Verbose} -gt 0 ]; then
            break
        fi
    fi
done

verbose "ALERT: verbose is on\n"

##
### exported functions
##

export -f verbose

##
### set default timezone
##

export TZ='America/New_York'

##
### static alias definitions
##

alias cl='cd;clear'
alias cp='cp -i'
alias duh='export HISTSIZE=0; unset HISTSIZE'
alias forget=duh
alias h='history'
alias hs='export HISTSIZE=0'
alias jc=journalctl
alias l='ls -lFhart'
alias ls='ls --color=tty'
alias mv='mv -i'
alias nouser="find . -nouser 2> /dev/null"
alias rm='rm -i'
alias sal='ps -ef | grep ssh-agent; echo && env | grep -i ssh | sort -V; echo; ssh-add -l'
alias sc=systemctl
alias vil=viLocate
alias viw=viLocate

##
### global key bindings
##

set -o vi

# showkey -a
bind '"\x18\x40\x73\x6c":"'${User_Name}'"' # Super+l
bind '"\x18\x40\x73\x75":"'${USER}'"' # Super+u

##
### tmux info
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
        alias tmux="${Tmux_Bin} -f ${User_Dir}/.tmux.conf -u"
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
    # linux term only supports 8 colors (and bold)
    #export PS1="\[${TPUT_SETAF_0}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # black
    #export PS1="\[${TPUT_SETAF_1}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # red
    #export PS1="\[${TPUT_SETAF_2}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # green
    #export PS1="\[${TPUT_SETAF_3}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # yellow(ish)
    #export PS1="\[${TPUT_SETAF_4}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # blue
    #export PS1="\[${TPUT_SETAF_5}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # purple
    #export PS1="\[${TPUT_SETAF_6}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # cyan
    #export PS1="\[${TPUT_SETAF_7}\][\u@\h \w]${PS} \[${TPUT_SGR0}\]" # grey

    ansi|*color|*xterm)

        # default PROMPT_COMMAND
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

        # trap DEBUG to update window titles

        trap bash_command_prompt_command DEBUG


        ;;
    *)
        echo TERM=$TERM
        ;;
esac

PS="[\u@\h \w]"
if [ "${USER}" == "root" ]; then
    PS+="# "
    PS1="\[${TPUT_BOLD}${TPUT_SETAF_3}\]${PS}\[${TPUT_SGR0}\]" # bold yellow
else
    PS+="$ "
    PS1="\[${TPUT_BOLD}${TPUT_SETAF_6}\]${PS}\[${TPUT_SGR0}\]" # bold cyan
fi
if [ ${#TPUT_BOLD} -eq 0 ]; then
    PS1=$PS
fi
unset -v PS

##
### if needed then create .inputrc (with preferences)
##

if [ ! -f ${HOME}/.inputrc ]; then
    printf "set bell-style none\n" > ${HOME}/.inputrc
fi

##
### check ssh, ssh-agent, & add all potential keys (if they're not already added)
##

# try twice
if ! sshAgent; then
    verbose "ALERT: sshAgent failed, retrying ..."
    sshAgent
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
        if [[ "${EDITOR}" == *"vim"* ]] && [ -r "${User_Dir}/.vimrc" ]; then
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

if [ -r "${User_Dir}/opt/static/${Uname_I}/lib" ]; then
    if [ ${#LD_LIBRARY_PATH} -eq 0 ]; then
        export LD_LIBRARY_PATH="${User_Dir}/opt/static/${Uname_I}/lib"
    else
        export LD_LIBRARY_PATH="${User_Dir}/opt/static/${Uname_I}/lib:${LD_LIBRARY_PATH}"
    fi
fi

if [ -r "${User_Dir}/opt/${Os_Variant}/${Uname_I}/lib" ]; then
    if [ ${#LD_LIBRARY_PATH} -eq 0 ]; then
        export LD_LIBRARY_PATH="${User_Dir}/opt/${Os_Variant}/${Uname_I}/lib"
    else
        export LD_LIBRARY_PATH="${User_Dir}/opt/${Os_Variant}/${Uname_I}/lib:${LD_LIBRARY_PATH}"
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
    alias got=git
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
### conditional alias definitions
##

if [ -r "${User_Dir}/.bashrc" ]; then
    alias s="source ${User_Dir}/.bashrc"
else
    alias s="source ${HOME}/.bashrc"
fi
if [ -x $(type -P sudo) ]; then
    alias root="sudo SSH_AUTH_SOCK=${SSH_AUTH_SOCK} -u root /bin/bash --init-file ${User_Dir}/.bashrc"
    alias suroot='sudo su -'
else
    alias root="su - root -c '/bin/bash --init-file /home/jtingiris/.bashrc'"
    alias suroot='su -'
fi
if [ -x $(type -P screen) ]; then
    alias sd='screen -S $(basename $(pwd))'
fi

##
### display some useful information
##

printf "\n"

if [ -r /etc/redhat-release ]; then
    cat /etc/redhat-release
    printf "\n"
fi

verbose "${User_Dir}/.bashrc ${Bashrc_Version}\n" 2
if [ "${TMUX}" ]; then
    verbose "${Tmux_Info} [${TMUX}]\n" 4
fi
