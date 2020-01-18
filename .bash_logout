# .bash_logout

Bash_Logout_Message="$(date) ${USER}@${HOSTNAME}"

# prep sshAgentInit to clean up when the last $USER is logging out
export Bash_Pids=($(pgrep -u ${USER} bash)) # this creates a subshell, so 2=1?
export Bash_Count=${#Bash_Pids[@]}
Bash_Logout_Message+=" Bash_Count=${Bash_Count}"

if [ ${Bash_Count} -le 2 ]; then
    Bash_Logout_Message+=" (last login?)"
    verbose_level=3
else
    verbose_level=1
fi

if [ "$(type -t verbose)" == "function" ]; then
    verbose "${Bash_Logout_Message}" $verbose_level
else
    printf "${Bash_Logout_Message}\n"
fi

if [ ${Bash_Count} -lt 2 ]; then
    # last login

    if [[ "${SSH_AGENT_PID}" =~ ^[0-9].+ ]]; then
        kill -9 "${SSH_AGENT_PID}" &> /dev/null
    fi

    if [ "$(type -t sshAgentInit)" == "function" ]; then
        sshAgentInit
    fi

    unset -v SSH_AGENT_PID SSH_AUTH_SOCK

fi

export Bash_Logout=0
