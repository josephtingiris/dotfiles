# .bashrc

Bashrc_Version="20200507, joseph.tingiris@gmail.com"

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

Os_Id=""
Os_Version_Id=""
Os_Version_Major=""

if [ -r /etc/os-release ]; then
    if [ ${#Os_Id} -eq 0 ]; then
        Os_Id=$(sed -nEe 's#"##g;s#^ID=(.*)$#\1#p' /etc/os-release)
    fi
    if [ ${#Os_Version_Id} -eq 0 ]; then
        Os_Version_Id=$(sed -nEe 's#"##g;s#^VERSION_ID=(.*)$#\1#p' /etc/os-release)
    fi
fi

if [ ${#Os_Id} -eq 0 ]; then
    if [ -r /etc/redhat-release ]; then
        Os_Id=rhel
        Os_Version_Id=$(sed 's/[^.0-9][^.0-9]*//g' /etc/redhat-release)
    fi
fi

Os_Version_Major=${Os_Version_Id%.*}

export Os_Id Os_Version_Id Os_Version_Major

if [ ${#Os_Id} -gt 0 ]; then
    if [ ${#Os_Version_Major} -gt 0 ]; then
        export Os_Variant="${Os_Id}/${Os_Version_Major}"
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
    Rhscl_Roots=$(find /opt/rh/ -maxdepth 2 -type f -name enable 2> /dev/null | sort -Vr)
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
    local dmesg="$(type -P dmesg)"

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
            verbose "ALERT: failed to 'rm -f ~/.gitconfig.local', Rm_Rc=${Rm_Rc}"
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

    if [[ $(git --version 2> /dev/null | egrep -e 'version 1.9.|version 1.8.[3-9].') ]]; then
        # only support this for git 1.8.3-1.9.x
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

# colorize make output
if [ -x /usr/bin/make ]; then
    function make() {
        /usr/bin/make "$@" 2>&1 | sed --unbuffered -e "s/\(.*[Ee]rror.*\)/${TPUT_SETAF_1}\1${TPUT_SGR0}/" -e "s/\(.*[Ff]ail.*\)/${TPUT_SMSO}\1${TPUT_SGR0}/" -e "s/\(.*[Ww]arning.*\)/${TPUT_SETAF_3}\1${TPUT_SGR0}/"
        return ${PIPESTATUS[0]}
    }
export -f make
fi

# if necessary, start ssh-agent
function sshAgent() {

    if ! sshAgentInit; then
        verbose "ERROR: sshAgentInit failed"
        return 1
    fi

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
                # there's no .ssh-agent file and ssh agent forwarding is off
                verbose "NOTICE: no ${Ssh_Agent_Home}; ssh agent forwarding is off"
                return 0
            fi
        fi
    fi

    export Ssh_Agent="$(type -P ssh-agent)"
    if [ ${#Ssh_Agent} -eq 0 ] || [ ! -x ${Ssh_Agent} ]; then
        verbose "ERROR: ssh-agent not usable"
        return 1
    fi

    export Ssh_Keygen="$(type -P ssh-keygen)"
    if [ ${#Ssh_Keygen} -eq 0 ] || [ ! -x ${Ssh_Keygen} ]; then
        verbose "ERROR: ssh-keygen not usable"
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
    Ssh_Add_Out=$(${Ssh_Add} -l 2>&1)
    Ssh_Add_Rc=$?
    if [ ${Ssh_Add_Rc} -eq 0 ]; then
        if [ ${#SSH_AGENT_PID} -eq 0 ] && [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
            # ssh-add works; ssh agent forwarding is on .. start another/local agent anyway?
            local ssh_agent_home_message="ssh agent forwarding via SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
            if [ ${#Ssh_Agent_Home} -gt 0 ] && [ -r "${Ssh_Agent_Home}" ]; then
                ssh_agent_home_message+="; ignoring ${Ssh_Agent_Home}"
            fi
            verbose "NOTICE: ${ssh_agent_home_message}"
        fi
    else
        # starting ssh-add failed (the first time)
        # rc=1 means 'failure', it's unspecified and may just be that it has no identities
        if [[ "${Ssh_Add_Out}" != *"agent has no identities"* ]]; then
            verbose "ERROR: '${Ssh_Add}' failed with SSH_AGENT_PID=${SSH_AGENT_PID}, SSH_AUTH_SOCK=${SSH_AUTH_SOCK}, output='${Ssh_Add_Out}', Ssh_Add_Rc=${Ssh_Add_Rc}"
            unset -v SSH_AGENT_PID
            unset -v SSH_AUTH_SOCK
        fi
    fi
    unset -v Ssh_Add_Out Ssh_Add_Rc

    # always enable agent forwarding?
    if [ "${#SSH_AUTH_SOCK}" -gt 0 ]; then
        alias ssh='ssh -A'
    fi

    Ssh_Key_Files=()

    Ssh_Dirs=()
    Ssh_Dirs+=(${User_Dir})

    if [ "${User_Dir}" != "${HOME}" ]; then
        Ssh_Dirs+=(${HOME})
    fi

    verbose "DEBUG: Ssh_Dirs=${Ssh_Dirs[@]}" 22

    for Ssh_Dir in ${Ssh_Dirs[@]}; do
        if [ -r "${Ssh_Dir}/.ssh" ] && [ -d "${Ssh_Dir}/.ssh" ]; then
            while read Ssh_Key_File; do
                Ssh_Key_Files+=(${Ssh_Key_File})
            done <<< "$(find "${Ssh_Dir}/.ssh/" -user ${User_Name} -name "*id_dsa" -o -name "*id_rsa" -o -name "*ecdsa_key" -o -name "*id_ed25519" 2> /dev/null)"
        fi
    done
    unset -v Ssh_Add_Rc Ssh_Dir


    Ssh_Configs=()
    for Ssh_Dir in ${Ssh_Dirs[@]}; do
        Ssh_Configs+=("${Ssh_Dir}/.ssh/config")
        Ssh_Configs+=("${Ssh_Dir}/.git/GIT_SSH.config")
        Ssh_Configs+=("${Ssh_Dir}/.subversion/SVN_SSH.config")
    done
    unset -v Ssh_Dir

    verbose "DEBUG: Ssh_Configs=${Ssh_Configs[@]}" 22

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

    verbose "DEBUG: Ssh_Key_Files=${Ssh_Key_Files[@]}" 22

    local ssh_key_file_counter=0
    for Ssh_Key_File in ${Ssh_Key_Files[@]}; do
        Ssh_Agent_Key=""
        Ssh_Key_Public=""
        Ssh_Key_Private=""

        if [ -r "${Ssh_Key_File}.pub" ]; then
            Ssh_Key_Public=$(awk '{print $2}' "${Ssh_Key_File}.pub" 2> /dev/null)
            if [ ${#Ssh_Key_Public} -eq 0 ]; then
                # couldn't determine public key
                continue
            fi

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

        let ssh_key_file_counter=${ssh_key_file_counter}+1

        if [ -r "${Ssh_Key_File}" ]; then
            Ssh_Key_Private=$(${Ssh_Keygen} -l -f "${Ssh_Key_File}.pub" 2> /dev/null | awk '{print $2}')
            if  [ ${#Ssh_Key_Private} -gt 0 ]; then
                Ssh_Agent_Key=$(${Ssh_Add} -l 2> /dev/null | grep ${Ssh_Key_Private} 2> /dev/null)
                if [ "${Ssh_Agent_Key}" == "" ]; then

                # add the key to the agent
                ${Ssh_Add} ${Ssh_Key_File} &> /dev/null
                Ssh_Add_Rc=$?
                if [ ${Ssh_Add_Rc} -ne 0 ]; then
                    verbose "ERROR: '${Ssh_Add} ${Ssh_Key_File}' failed, Ssh_Add_Rc=${Ssh_Add_Rc}"
                fi
                unset -v Ssh_Add_Rc

                fi
                unset -v Ssh_Agent_Key
            fi
        fi
    done
    unset -v Ssh_Agent_Key Ssh_Key_File Ssh_Key_Private Ssh_Key_Public Ssh_Key_Files

    # hmm .. https://serverfault.com/questions/401737/choose-identity-from-ssh-agent-by-file-name
    # this will convert the stored ssh-keys to public files that can be used with IdentitiesOnly
    Md5sum="$(type -P md5sum)"
    if [ -x "${Md5sum}" ] && [ -w "${HOME}/.ssh" ] && [ "${USER}" != "root" ]; then
        Ssh_Identities_Dir="${HOME}/.ssh/md5sum"

        if [ ! -d "${Ssh_Identities_Dir}" ]; then
            mkdir -p "${Ssh_Identities_Dir}"
            Mkdir_Rc=$?
            if [ ${Mkdir_Rc} -ne 0 ]; then
                verbose "EMERGENCY: failed to 'mkdir -p ${Ssh_Identities_Dir}', Mkdir_Rc=${Mkdir_Rc}"
                return 1
            fi
            unset -v Mkdir_Rc
        fi

        chmod 0700 "${Ssh_Identities_Dir}" &> /dev/null
        Chmod_Rc=$?
        if [ ${Chmod_Rc} -ne 0 ]; then
            verbose "EMERGENCY: failed to 'chmod -700 ${Ssh_Identities_Dir}', Chmod_Rc=${Chmod_Rc}"
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
                    verbose "EMERGENCY: failed to 'chmod 0400 ${Ssh_Identities_Dir}/${Ssh_Public_Key_Md5sum}.pub', Chmod_Rc=${Chmod_Rc}"
                    return 1
                fi
                unset -v Chmod_Rc
            fi
            unset -v Ssh_Public_Key_Md5sum
        done <<< "$(${Ssh_Add} -L 2> /dev/null)"
        unset -v Ssh_Public_Key
    fi

}

function sshAgentInit() {

    if [[ ! ${Ssh_Agent_Clean_Counter} =~ ^[0-9]+$ ]]; then
        Ssh_Agent_Clean_Counter=0
    fi

    let Ssh_Agent_Clean_Counter=${Ssh_Agent_Clean_Counter}+1

    if [ ${Ssh_Agent_Clean_Counter} -gt 2 ]; then
        return 1 # prevent infinite, recursive loops
    fi

    export Ssh_Add="$(type -P ssh-add)"
    if [ ${#Ssh_Add} -eq 0 ] || [ ! -x ${Ssh_Add} ]; then
        pkill ssh-agent &> /dev/nulll
        verbose "EMERGENCY: ssh-add not usable"
        return 1
    fi

    export Ssh_Agent_Home="${User_Dir}/.ssh-agent"
    export Ssh_Agent_State="${Ssh_Agent_Home}.${Who}@${HOSTNAME}"
    export Ssh_Agent_Timeout=86400

    if [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        if [ -s "${Ssh_Agent_State}" ]; then
            # agent state file exists and it's not empty, try to use it
            eval "$(<${Ssh_Agent_State})" &> /dev/null
        fi
    fi

    local ssh_agent_socket_command

    if [ ${#SSH_AGENT_PID} -gt 0 ]; then
        ssh_agent_socket_command=$(ps -h -o comm -p ${SSH_AGENT_PID} 2> /dev/null)
        if [ ${#ssh_agent_socket_command} -gt 0 ] && [ "${ssh_agent_socket_command}" != "ssh-agent" ] && [ "${ssh_agent_socket_command}" != "sshd" ]; then
            verbose "ERROR: SSH_AGENT_PID=${SSH_AGENT_PID} process not valid; missing or defunct\n"
            kill -9 ${SSH_AGENT_PID} &> /dev/null
            unset -v SSH_AGENT_PID
        fi
    fi

    if [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
        if [ -S "${SSH_AUTH_SOCK}" ]; then
            if [ ! -w "${SSH_AUTH_SOCK}" ]; then
                verbose "ERROR: unset SSH_AUTH_SOCK=${SSH_AUTH_SOCK}, socket not found writable\n"
                unset -v SSH_AUTH_SOCK
                if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                    kill -9 ${SSH_AGENT_PID} &> /dev/null
                    unset -v SSH_AGENT_PID
                fi
            fi
        else
            # SSH_AUTH_SOCK is not a valid socket
            verbose "ERROR: unset SSH_AUTH_SOCK=${SSH_AUTH_SOCK}, socket not valid\n"
            unset -v SSH_AUTH_SOCK
            if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                kill ${SSH_AGENT_PID} &> /dev/null
                unset -v SSH_AGENT_PID
            fi
        fi
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

            # TODO: test with gnome
            local ssh_agent_socket_identifier
            if [[ "${ssh_agent_socket_command}" == *"kde"* ]] || [[ "${ssh_agent_socket_command}" == *"plasma"* ]] || [ "${ssh_agent_socket_command}" == "sshd" ]; then
                ssh_agent_socket_identifier=""
            else
                ((++ssh_agent_socket_pid))
                ssh_agent_socket_command=$(ps -h -o comm -p ${ssh_agent_socket_pid} 2> /dev/null)
                ssh_agent_socket_identifier=" [++]"
            fi
        fi

        # TODO: test with gnome
        if [[ "${ssh_agent_socket_command}" == *"kde"* ]] || [[ "${ssh_agent_socket_command}" == *"plasma"* ]] || [ "${ssh_agent_socket_command}" == "sshd" ] || [ "${ssh_agent_socket_command}" == "ssh-agent" ]; then
            # sometimes ssh-add fails to read the socket & takes 3+ minutes to timeout
            # if it takes longer than 5 seconds to read the socket then remove it (it's unusable)
            SSH_AUTH_SOCK=${ssh_agent_socket} timeout 5 ${Ssh_Add} -l ${ssh_agent_socket} &> /dev/null
            Ssh_Add_Rc=$?
            if [ ${Ssh_Add_Rc} -gt 1 ]; then
                # definite error
                verbose "ALERT: removing dead ssh_agent_socket ${ssh_agent_socket}, command=${ssh_agent_socket_command}, Ssh_Add_Rc=${Ssh_Add_Rc}"
                rm -f ${ssh_agent_socket} &> /dev/null
                Rm_Rc=$?
                if [ ${Rm_Rc} -ne 0 ]; then
                    verbose "ALERT: failed to 'rm -f ${ssh_agent_socket}', Rm_Rc=${Rm_Rc}"
                fi
                unset -v ssh_auth_sock
                unset -v Rm_Rc
            else
                # don't remove valid sockets; try to reuse them

                if [ ${#SSH_AGENT_PID} -eq 0 ] || [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
                    if [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
                        if [ ${#ssh_agent_socket_pid} -gt 0 ] && [ "${ssh_agent_socket_command}" == "ssh-agent" ]; then
                            export SSH_AGENT_PID=${ssh_agent_socket_pid}
                            verbose "DEBUG: reusing SSH_AGENT_PID=${SSH_AGENT_PID}"
                        fi

                        if [ ${#ssh_agent_socket} -gt 0 ]; then
                            export SSH_AUTH_SOCK=${ssh_agent_socket}
                            verbose "DEBUG: reusing SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
                        fi
                    fi
                else
                    verbose "DEBUG: ssh_agent_socket_command = ${ssh_agent_socket_command} (pid=${ssh_agent_socket_pid})${ssh_agent_socket_identifier} [OK]"
                fi

                continue
            fi
            unset -v Ssh_Add_Rc
        else
            verbose "ALERT: removing unusable ssh_agent_socket ${ssh_agent_socket}, pid=${ssh_agent_socket_pid}, command=${ssh_agent_socket_command}"
            rm -f ${ssh_agent_socket} &> /dev/null
            Rm_Rc=$?
            if [ ${Rm_Rc} -ne 0 ]; then
                verbose "ALERT: failed to 'rm -f ${ssh_agent_socket}', Rm_Rc=${Rm_Rc}"
            fi
            unset -v ssh_auth_sock
            unset -v Rm_Rc
        fi
        verbose "ALERT: ssh_agent_socket_command = ${ssh_agent_socket_command} (pid=${ssh_agent_socket_pid})${ssh_agent_socket_identifier} [OK?]" # should be dead code
    done <<<"$(find /tmp/ssh* -type s -user ${User_Name} -wholename "*/ssh*agent*" 2> /dev/null)"

    unset -v ssh_agent_socket ssh_agent_socket_pid ssh_agent_socket_command ssh_auth_sock

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
            else
                if [ ${#SSH_AGENT_PID} -gt 0 ]; then
                    if [ "${SSH_AGENT_PID}" == "${ssh_agent_pid}" ]; then
                        # don't kill the current agent
                        continue
                    fi
                fi
            fi

            verbose "ALERT: killing old ssh_agent_pid='${ssh_agent_pid}'"
            kill ${ssh_agent_pid} &> /dev/null
        done
        unset -v ssh_agent_pid ssh_agent_state_pid
    fi

    # it's possible this condition could happen (again) if a socket's removed
    if [ ${#SSH_AGENT_PID} -gt 0 ] && [ ${#SSH_AUTH_SOCK} -eq 0 ]; then
        unset -v SSH_AGENT_PID
    fi

    if [ "${USER}" == "${Who}" ]; then
        if [ ${#SSH_AGENT_PID} -gt 0 ] && [ ${#SSH_AUTH_SOCK} -gt 0 ]; then
            verbose "DEBUG: creating ${Ssh_Agent_State}" 15
            printf "SSH_AUTH_SOCK=%s; export SSH_AUTH_SOCK;\n" "${SSH_AUTH_SOCK}" > "${Ssh_Agent_State}"
            printf "SSH_AGENT_PID=%s; export SSH_AGENT_PID;\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_State}"
            printf "echo Agent pid %s\n" "${SSH_AGENT_PID}" >> "${Ssh_Agent_State}"
        else
            verbose "DEBUG: no SSH_AGENT_PID or SSH_AUTH_SOCK" 15
            if [ -f "${Ssh_Agent_State}" ]; then
                verbose "DEBUG: removing ${Ssh_Agent_State}"
                rm -f "${Ssh_Agent_State}" &> /dev/null
                Rm_Rc=$?
                if [ ${Rm_Rc} -ne 0 ]; then
                    verbose "ALERT: failed to 'rm -f ${Ssh_Agent_State}', Rm_Rc=${Rm_Rc}"
                fi
                unset -v Rm_Rc
            fi
        fi
    fi

    if [ -w "${Ssh_Agent_State}" ]; then
        chmod 0600 "${Ssh_Agent_State}" &> /dev/null
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
    if [[ ${Verbose} =~ ^[0-9]+$ ]]; then
        verbosity=${Verbose}
    else
        if [[ ${VERBOSE} =~ ^[0-9]+$ ]]; then
            verbosity=${VERBOSE}
        else
            verbosity=1
        fi
    fi

    if [ ${#2} -gt 0 ]; then
        verbose_message="${verbose_arguments[@]}" # preserve verbose_arguments
        verbose_level=${verbose_arguments[${#verbose_arguments[@]}-1]}
        if [[ ${verbose_level} =~ ^[0-9]+$ ]]; then
            # remove the last (integer) element (verbose_level)
            verbose_message="${verbose_message% *}"
        else
            verbose_level=""
        fi
    else
        verbose_message="${1}"
        verbose_level=""
    fi

    # 0 EMERGENCY (unusable), 1 ALERT, 2 CRIT(ICAL), 3 ERROR, 4 WARN(ING), 5 NOTICE, 6 INFO(RMATIONAL), 7 DEBUG

    local verbose_message_upper

    if [ ${BASH_VERSINFO} -ge 4 ]; then
        verbose_message_upper="${verbose_message^^}"
    else
        verbose_message_upper=$(echo "${verbose_message}" | tr '[:lower:]' '[:upper:]')
    fi

    # convert verbose_message to uppercase & check for presence of keywords
    if [[ "${verbose_message_upper}" == *"ALERT"* ]]; then
        if [ ${#verbose_level} -eq 0 ]; then
            verbose_level=1
        fi
    else
        if [[ "${verbose_message_upper}" == *"CRIT"* ]]; then
            if [ ${#verbose_level} -eq 0 ]; then
                verbose_level=1
            fi
        else
            if [[ "${verbose_message_upper}" == *"ERROR"* ]]; then
                if [ ${#verbose_level} -eq 0 ]; then
                    verbose_level=1
                fi
            else
                if [[ "${verbose_message_upper}" == *"WARN"* ]]; then
                    if [ ${#verbose_level} -eq 0 ]; then
                        verbose_level=3
                    fi
                else
                    if [[ "${verbose_message_upper}" == *"NOTICE"* ]]; then
                        if [ ${#verbose_level} -eq 0 ]; then
                            verbose_level=2
                        fi
                    else
                        if [[ "${verbose_message_upper}" == *"INFO"* ]]; then
                            if [ ${#verbose_level} -eq 0 ]; then
                                verbose_level=4
                            fi
                        else
                            if [[ "${verbose_message_upper}" == *"DEBUG"* ]]; then
                                if [ ${#verbose_level} -eq 0 ]; then
                                    verbose_level=8
                                fi
                            else
                                if [ ${#verbose_level} -eq 0 ]; then
                                    verbose_level=0
                                fi
                            fi
                        fi
                    fi
                fi
            fi
        fi
    fi

    if [ ${#verbose_level} -eq 0 ] || [ ${verbose_level} -eq 0 ]; then
        return # hide
    fi

    if [ ${verbose_level} -gt ${verbosity} ]; then
        return # hide
    fi

    local verbose_level_prefix

    if [[ "${Verbose_Level_Prefix}" =~ ^(0|on|true)$ ]]; then
        verbose_level_prefix=0
    else
        verbose_level_prefix=1
    fi

    if [ ${verbose_level} -eq 1 ]; then
        verbose_color=1
        if [ ${verbose_level_prefix} -eq 0 ] && [[ "${verbose_message_upper}" != *"ALERT"* ]]; then
            verbose_message="ALERT: ${verbose_message}"
        fi

        if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"CRIT"* ]]; then
            verbose_message="CRITICAL: ${verbose_message}"
        fi

        if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"ERROR"* ]]; then
            verbose_message="ERROR: ${verbose_message}"
        fi
    else
        if [ ${verbose_level} -eq 2 ]; then
            verbose_color=2
            if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"NOTICE"* ]]; then
                verbose_message="NOTICE: ${verbose_message}"
            fi
        else
            if [ ${verbose_level} -eq 3 ]; then
                verbose_color=3
                if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"WARN"* ]]; then
                    verbose_message="WARNING: ${verbose_message}"
                fi
            else
                if [ ${verbose_level} -eq 4 ]; then
                    verbose_color=4
                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"INFO"* ]]; then
                        verbose_message="INFO: ${verbose_message}"
                    fi
                else
                    if [ ${verbose_level} -eq 5 ]; then
                        verbose_color=5
                    else
                        if [ ${verbose_level} -eq 6 ]; then
                            verbose_color=6
                        else
                            if [ ${verbose_level} -eq 7 ]; then
                                verbose_color=7
                            else
                                if [ ${verbose_level} -eq 8 ]; then
                                    verbose_color=8
                                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"DEBUG"* ]]; then
                                        verbose_message="DEBUG: ${verbose_message}"
                                    fi
                                else
                                    verbose_color=9
                                    if [ ${verbose_level_prefix} -eq 0 ] &&  [[ "${verbose_message_upper}" != *"DEBUG"* ]]; then
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

    if [ ${verbosity} -ge ${verbose_level} ]; then

        if [ ${BASH_VERSINFO} -ge 4 ]; then
            verbose_message_upper="${verbose_message^^}"
        else
            verbose_message_upper=$(echo "${verbose_message}" | tr '[:lower:]' '[:upper:]')
        fi

        local -i verbose_pad_left verbose_pad_right

        if [[ ${Verbose_Pad_Left} =~ ^[0-9]+$ ]]; then
            verbose_pad_left=${Verbose_Pad_Left}
        fi

        if [[ ${Verbose_Pad_Right} =~ ^[0-9]+$ ]]; then
            verbose_pad_right=${Verbose_Pad_Right}
        fi

        local v1 v2

        if [[ "${verbose_message_upper}" == *":"* ]]; then
            v1="${verbose_message%%:*}"
            v1="${v1#"${v1%%[![:space:]]*}"}"
            v1="${v1%"${v1##*[![:space:]]}"}"
            v2="${verbose_message#*:}"
            v2="${v2#"${v2%%[![:space:]]*}"}"
            v2="${v2%"${v2##*[![:space:]]}"}"
            printf -v verbose_message "%-${verbose_pad_left}b : %b" "${v1}" "${v2}"
            unset v1 v2
        fi

        if [[ "${verbose_message_upper}" == *"="* ]]; then
            v1="${verbose_message%%=*}"
            v1="${v1#"${v1%%[![:space:]]*}"}"
            v1="${v1%"${v1##*[![:space:]]}"}"
            v2="${verbose_message#*=}"
            v2="${v2#"${v2%%[![:space:]]*}"}"
            v2="${v2%"${v2##*[![:space:]]}"}"
            printf -v verbose_message "%-${verbose_pad_right}b = %b" "${v1}" "${v2}"
            unset v1 v2
        fi

        if [ ${#TPUT_SGR0} -gt 0 ]; then
            if [ ${#verbose_color} -eq 0 ]; then
                verbose_color=${verbose_level}
            fi
            local tput_set_af_v="TPUT_SETAF_${verbose_color}"
            if [ ${verbose_level} -le 7 ] && [ ${#TPUT_BOLD} -gt 0 ]; then
                verbose_message="${TPUT_BOLD}${!tput_set_af_v}${verbose_message}${TPUT_SGR0}"
            else
                verbose_message="${!tput_set_af_v}${verbose_message}${TPUT_SGR0}"
            fi
            unset -v tput_set_af_v
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
            if type -P locate &> /dev/null; then
                while read vi_file; do
                    if [ -r "${vi_file}" ] && [ ! -d "${vi_file}" ]; then
                        vi_files+=($vi_file)
                    fi
                done <<< "$(locate -r "/${vi_locate}$" | sort)"
            else
                if type -P which &> /dev/null; then
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

##
### trap EXIT to ensure .bash_logout gets called, regardless of whether or not it's a login shell
##

if [ -r "${User_Dir}/.bash_logout" ]; then
    if [ ${#TMUX_PANE} -eq 0 ]; then
        trap "source ${User_Dir}/.bash_logout" EXIT
    else
        trap "source ${User_Dir}/.bash_logout;tmux kill-pane -t ${TMUX_PANE}" EXIT
    fi
else
    if [ -r "${User_Dir}/.bash_logout" ]; then
        if [ ${#TMUX_PANE} -eq 0 ]; then
            trap "source ${HOME}/.bash_logout" EXIT
        else
            trap "source ${User_Dir}/.bash_logout;tmux kill-pane -t ${TMUX_PANE}" EXIT
        fi
    fi
fi

##
### exported functions
##

export -f verbose

##
### set history control
##

export HISTCONTROL=ignoredups

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
    export Tmux_Bin="$(type -P tmux 2> /dev/null)"
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

if [ "${TERM}" != "linux" ] && [[ "${TERM}" != *"screen"* ]] && [[ "${TERM}" != *"tmux"* ]]; then
    if [ ${#KONSOLE_DBUS_WINDOW} -gt 0 ] && [ -r /usr/share/terminfo/k/konsole-256color ]; then
        export TERM=konsole-256color # if it's a konsole dbus window then use konsole-256color
    else
        export TERM=screen-256color
    fi
fi

if [[ "${TERM}" == *"screen"* ]]; then
    if [ -r /usr/share/terminfo/s/screen-256color ]; then
        export TERM=screen-256color
    else
        if [ -r /usr/share/terminfo/s/screen ]; then
            export TERM=screen
        else
            export TERM=ansi
        fi
    fi
fi

# this is mainly for performance; as long as TERM doesn't change then there's no need to run tput every time
if [ "${TERM}" != "${TPUT_TERM}" ] || [ ${#TPUT_TERM} -eq 0 ]; then
    if type -P tput &> /dev/null; then
        export TPUT_TERM=${TERM}
        export TPUT_BOLD="$(tput bold 2> /dev/null)"
        if [ $? -eq 0 ]; then
            export TPUT_SETAF_0="$(tput setaf 0 2> /dev/null)" # black
            export TPUT_SETAF_1="$(tput setaf 1 2> /dev/null)" # red
            export TPUT_SETAF_2="$(tput setaf 2 2> /dev/null)" # green
            export TPUT_SETAF_3="$(tput setaf 3 2> /dev/null)" # orange (yellow?)
            export TPUT_SETAF_4="$(tput setaf 4 2> /dev/null)" # blue
            export TPUT_SETAF_5="$(tput setaf 5 2> /dev/null)" # purple
            export TPUT_SETAF_6="$(tput setaf 6 2> /dev/null)" # cyan
            export TPUT_SETAF_7="$(tput setaf 7 2> /dev/null)" # white
            export TPUT_SETAF_8="$(tput setaf 8 2> /dev/null)" # grey
            export TPUT_SGR0="$(tput sgr0 2> /dev/null)" # reset
            export TPUT_SMSO="$(tput smso 2> /dev/null)" # standout
        fi
    fi
fi

##
### set Verbose variables
##

Verbose_Pad_Left=11
Verbose_Pad_Right=50

for verbose_file in "${User_Dir}/.verbose" "${User_Dir}/.bashrc.verbose"; do
    if [ -r "${verbose_file}" ]; then
        # get digits only from the first line; if they're not digits then set verbosity to one
        export Verbose=$(grep -m1 "^[0-9]*$" "${verbose_file}" 2> /dev/null)
        if [ ${#Verbose} -gt 0 ]; then
            break
        fi
    fi
done

verbose "NOTICE: verbose is on"

# non-login shells will *not* execute .bash_logout, and I want to know ...
if ! shopt -q login_shell &> /dev/null; then
    verbose "NOTICE: interactive, but not a login shell"
fi

##
### custom, color prompt
##

case "${TERM}" in
    ansi|*color|*xterm)

        # default PROMPT_COMMAND
        export PROMPT_COMMAND='printf "\033]2;%s\007" "[bash] ${USER}@${HOSTNAME}:${PWD}"'

        function bash_command_prompt_command() {
            case "${BASH_COMMAND}" in
                *\033]2*)
                    # nested escapes can confuse the terminal, don't output them.
                    ;;
                *)
                    printf "\033]0;%s\007" "${USER}@${HOSTNAME}:${PWD} [${BASH_COMMAND}]"
                    ;;
            esac
        }

        # trap DEBUG to update window titles

        #trap bash_command_prompt_command DEBUG

        ;;
    *)
        echo TERM=$TERM
        echo
        ;;
esac

PS="[\u@\H \w]"
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
Editors=(nvim vimx vim vi)
for Editor in ${Editors[@]}; do
    if type -P ${Editor} &> /dev/null; then
        export EDITOR="$(type -P ${Editor} 2> /dev/null)"
        if [[ "${EDITOR}" == *"vim"* ]] && [ -r "${User_Dir}/.vimrc" ]; then
            alias vim="HOME=\"${User_Dir}\" ${EDITOR} --cmd \"let User_Name='${User_Name}'\" --cmd \"let User_Dir='${User_Dir}'\""
        else
            alias vim="${EDITOR}"
        fi
        alias vi=vim
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
### set ip
##

if type -P ip &> /dev/null; then
    if ip -c link show lo &> /dev/null; then
        alias ip='ip -c'
    fi
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

if type -P colordiff &> /dev/null; then
    alias diff=colordiff
fi

if [ -r "${User_Dir}/.bashrc" ]; then
    alias s="source ${User_Dir}/.bashrc"
else
    alias s="source ${HOME}/.bashrc"
fi

alias authsock=sshAgentInit
alias scpo='scp -o IdentitiesOnly=yes'
alias ssho='ssh -o IdentitiesOnly=yes'

if [ -x /usr/bin/sudo ]; then
    Sudo=/usr/bin/sudo
else
    if [ -x /bin/sudo ]; then
        Sudo=/bin/sudo
    fi
fi

if [ ${#Sudo} -gt 0 ]; then
    alias root="${Sudo} SSH_AUTH_SOCK=${SSH_AUTH_SOCK} -u root /bin/bash --init-file ${User_Dir}/.bashrc"
    alias suroot="${Sudo} su -"
else
    alias root="su - root -c '/bin/bash --init-file /home/jtingiris/.bashrc'"
    alias suroot='su -'
fi

if type -P screen &> /dev/null; then
    alias sd='screen -S $(basename $(pwd))'
fi

##
### check ssh, ssh-agent, & add all potential keys (if they're not already added)
##

Ssh_Agent_Clean_Counter=0

# try twice
if ! sshAgent; then
    verbose "ALERT: sshAgent failed, retrying ...\n"
    sshAgent
fi

##
### if possible, as other users, xauth add ${User_Dir}/.Xuathority
##

if [ "${USER}" != "${Who}" ]; then
    if [ ${#DISPLAY} -gt 0 ]; then
        if type -P xauth &> /dev/null; then
            verbose "DEBUG: xauth DISPLAY=${DISPLAY}"

            if [ -r "${User_Dir}/.Xauthority" ]; then
                verbose "DEBUG: ${User_Dir}/.Xauthority file found readable" 22
                while read Xauth_Add; do
                    xauth -b add ${Xauth_Add} 2> /dev/null
                done <<< "$(xauth -b -f "${User_Dir}/.Xauthority" list)"
            else
                verbose "DEBUG: ${User_Dir}/.Xauthority file not found readable" 22
            fi
        fi
    fi
fi

##
### display some useful information
##

verbose "DEBUG: Who=${Who}" 18
verbose "DEBUG: User_Dir=${User_Dir}" 18
verbose "DEBUG: Ssh_Agent_Home=${Ssh_Agent_Home}" 18
verbose "DEBUG: Ssh_Agent_State=${Ssh_Agent_State}" 18

if [ -r /etc/redhat-release ]; then
    printf "\n"
    cat /etc/redhat-release
    printf "\n"
fi

printf "${User_Dir}/.bashrc ${Bashrc_Version}\n\n"

if [ "${TMUX}" ]; then
    verbose "${Tmux_Info} [${TMUX}]\n" 8
fi
