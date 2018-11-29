# .bash_logout

# prep sshAgentClean to clean up when the last $USER is logging out
if [ ${#SUDO_USER} -eq 0 ]; then
    Login_Count=$(w -h $USER 2> /dev/null | wc -l 2> /dev/null)
    if [ "$Login_Count" == "" ] || [ "$Login_Count" == "0" ] || [ "$Login_Count" == "1" ]; then
        unset -v SSH_AGENT_PID SSH_AUTH_SOCK
        if [ -f "${Ssh_Agent_Hostname}" ]; then
            rm -f "${Ssh_Agent_Hostname}" &> /dev/null
        fi
    fi
fi

# this is logic in .bashrc
if [ "$(type -t sshAgentClean)" == "function" ]; then
    sshAgentClean
fi
