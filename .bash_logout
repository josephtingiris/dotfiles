# ~/.bash_logout

if [ "$Ssh_Agent_Pid" != "" ] && [ -d /proc/$Ssh_Agent_Pid ]; then
    # this works in conjunction with /etc/profile.d/ssh-agent.sh
    if [ -f ~/.ssh-agent.$HOSTNAME ]; then
        # TODO: does the content of .ssh-agent.$HOSTNAME Ssh_Agent_Pid match the environment variable?
        Ssh_Agent_Pid_Check=$(cat ~/.ssh-agent.$HOSTNAME | grep "^Ssh_Agent_Pid=$Ssh_Agent_Pid;")
        if [ "$Ssh_Agent_Pid_Check" == "" ]; then
            kill -9 $Ssh_Agent_Pid &> /dev/null
        fi
    fi
fi
