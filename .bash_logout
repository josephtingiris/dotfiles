# .bash_logout

# prep sshAgentClean to clean up when the last $USER is logging out
Bash_Count=$(pgrep -u $USER bash | wc -l) # this creates a subshell, so 2=1
if [ $Bash_Count -le 2 ]; then
    echo "$(date) ${USER}@${HOSTNAME} Bash_Count=$Bash_Count (last login)"
    unset -v SSH_AGENT_PID SSH_AUTH_SOCK
    if [ -f "${Ssh_Agent_Hostname}" ]; then
        rm -f "${Ssh_Agent_Hostname}" &> /dev/null
    fi
else
    echo "$(date) ${USER}@${HOSTNAME} Bash_Count=$Bash_Count"
fi


# this is logic in .bashrc
if [ "$(type -t sshAgentClean)" == "function" ]; then
    sshAgentClean
fi
