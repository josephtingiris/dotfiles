#!/bin/bash

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @{0})
BASE=$(git merge-base @{0} "$UPSTREAM")

# keep home directory up to date
if [ -d ~/.git ]; then
    CWD=$(/usr/bin/pwd)

    cd ~

    if [ $LOCAL = $BASE ]; then
        # need to pull
        git pull &> /dev/null
    fi

    cd "$CWD"
fi
