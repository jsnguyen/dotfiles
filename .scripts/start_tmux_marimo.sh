#!/bin/bash

function start_tmux_marimo {
    tmux new-session -d -s 'marimo'
}

echo 'Starting marimo notebook server...'
if start_tmux_marimo ; then
    tmux send-keys -t marimo:0 'cd' C-m
    tmux send-keys -t marimo:0 'marimo edit' C-m
    echo 'marimo started!'
else
    echo 'marimo already running!'
fi
