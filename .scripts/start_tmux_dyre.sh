#!/bin/bash

function start_tmux_dyre {
    tmux new-session -d -s 'dyre'
}

echo 'Starting dyre notebook server...'
if start_tmux_dyre ; then
    tmux send-keys -t dyre:0 'cd' C-m
    tmux send-keys -t dyre:0 'dyre' C-m
    echo 'dyre started!'
else
    echo 'dyre already running!'
fi
