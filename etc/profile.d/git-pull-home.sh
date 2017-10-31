#!/bin/bash

# keep home directory up to date
if [ -d ~/.git ]; then
    CWD=$(/usr/bin/pwd)
    cd ~
    git pull &> /dev/null
    cd "$CWD"
fi
