# .bash_logout

Bash_Logout_Message="$(date) ${USER}@${HOSTNAME}"

# prep sshAgentClean to clean up when the last $USER is logging out
export Bash_Count=$(pgrep -u ${USER} bash | wc -l) # this creates a subshell, so 2=1
Bash_Logout_Message+=" Bash_Count=$Bash_Count"
if [ ${Bash_Count} -le 2 ]; then
    Bash_Logout_Message+=" (last login)"
    unset -v SSH_AGENT_PID SSH_AUTH_SOCK
    if [ -f "${Ssh_Agent_Hostname}" ]; then
        rm -f "${Ssh_Agent_Hostname}" &> /dev/null
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

