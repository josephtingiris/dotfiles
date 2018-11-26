# .bash_logout

# this is logic in .bashrc
if [ "$(type -t sshAgentKill)" == "function" ]; then
    sshAgentKill
fi
