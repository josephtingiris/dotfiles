# .bash_logout

# this is logic in .bashrc
if [ "$(type -t sshAgentValidate)" == "function" ]; then
    sshAgentValidate
fi
