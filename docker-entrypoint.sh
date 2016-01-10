#!/bin/bash
set -e

if [[ "$1" == 'build-tmux' ]]
then
    echo 'INFO: Building tmux'
    /build-tmux.sh

    if mountpoint -q /target
    then
        echo "INFO: Installing tmux to /target"
        cp /tmp/tmux/tempinstall/bin/tmux /target
        echo "Installing docker-enter to /target"
        cp /docker-enter /target
        echo "Installing importenv to /target"
        cp /importenv /target
    else
        echo "/target is not a mountpoint."
        echo "You can either:"
        echo "- re-run this container with -v /opt/tmux/bin:/target"
        echo "- extract the tmux binary (located at /tmp/tmux/tempinstall/bin)"
    fi
fi

exec "$@"
