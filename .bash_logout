# ~/.bash_logout

# this works in conjunction with logic in ~/.bashrc

if [ ${#Who} -eq 0 ]; then
    Who=${USER}
fi

Ssh_Agent_File="${HOME}/.ssh-agent.${Who}@${HOSTNAME}"

if [ ${#SSH_AGENT_PID} -eq 0 ] && [ -r "${Ssh_Agent_File}" ]; then
    eval "$(<${Ssh_Agent_File})" &> /dev/null
fi

if [ ${#SSH_AGENT_PID} -gt 0 ]; then
    if [ -d /proc/${SSH_AGENT_PID} ]; then
        if [ -r "${Ssh_Agent_File}" ]; then
            if [ -r "${HOME}/.ssh-keys" ]; then
                # if everything matches then leave it running (until it expires)
                if ! grep "^SSH_AGENT_PID=${SSH_AGENT_PID}" "${Ssh_Agent_File}" &> /dev/null; then
                    rm -f "${Ssh_Agent_File}" &> /dev/null
                    pkill -9 -u "${USER}" -f $(type -P ssh-agent) &> /dev/null
                fi
            else
                # ssh-agent was started manually? should it be running?
                rm -f "${Ssh_Agent_File}" &> /dev/null
                pkill -9 -u "${USER}" -f $(type -P ssh-agent) &> /dev/null
            fi
        else
            # should it be running without an agent file?
            pkill -9 -u "${USER}" -f $(type -P ssh-agent) &> /dev/null
        fi
    fi
else
    if [ -f "${Ssh_Agent_File}" ]; then
        # it's not running but the agent file exists; remove it
        rm -f "${Ssh_Agent_File}" &> /dev/null
    fi
fi

unset -v Ssh_Agent_File
