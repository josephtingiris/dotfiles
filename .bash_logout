# .bash_logout

Bash_Logout_Message="$(date) ${USER}@${HOSTNAME}"

# prep sshAgentClean to clean up when the last $USER is logging out
export Bash_Pids=($(pgrep -u ${USER} bash)) # this creates a subshell, so 2=1
export Bash_Count=${#Bash_Pids[@]}
Bash_Logout_Message+=" Bash_Count=${Bash_Count}"
if [ ${Bash_Count} -le 2 ]; then
    Bash_Logout_Message+=" (last login)"
    unset -v SSH_AGENT_PID SSH_AUTH_SOCK
    if [ -f "${Ssh_Agent_State}" ]; then
        rm -f "${Ssh_Agent_State}" &> /dev/null
    fi
    bverbose_level=3
else
    bverbose_level=1
fi

if [ ${#Bash_Logout} -eq 0 ]; then
    if [ "$(type -t bverbose)" == "function" ]; then
        bverbose "${Bash_Logout_Message}" $bverbose_level
    else
        printf "${Bash_Logout_Message}\n"
    fi
fi

# this is logic in .bashrc
if [ "$(type -t sshAgentClean)" == "function" ]; then
    sshAgentClean
fi

export Bash_Logout=0

sleep 3
