#!/bin/bash

UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
BASE=$(git merge-base @ "$UPSTREAM")

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
