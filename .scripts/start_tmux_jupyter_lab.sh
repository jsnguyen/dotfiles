#!/bin/bash

function start_tmux_jupyter_lab {
    tmux new-session -d -s 'jupyter'
}

echo 'Starting jupyter lab session...'
if start_tmux_jupyter_lab ; then
    tmux send-keys -t jupyter:0 'cd' C-m
    tmux send-keys -t jupyter:0 'pyenv activate notebooks' C-m
    tmux send-keys -t jupyter:0 'jupyter lab --ServerApp.allow_remote_access=True
 --ServerApp.allow_origin="*" --no-browser --ServerApp.token=""' C-m
    echo 'jupyter lab started!'
else
    echo 'jupyter lab already running!'
fi
