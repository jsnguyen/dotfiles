#!/bin/bash

function start_tmux_jupyter_lab {
    tmux new-session -d -s 'pluto'
}

echo 'Starting Pluto.jl session...'
if start_tmux_jupyter_lab ; then
    tmux send-keys -t pluto:0 'cd' C-m
    tmux send-keys -t pluto:0 'julia -e "using Pluto; Pluto.run()"' C-m
    echo 'Pluto.jl started!'
else
    echo 'Pluto.jl already running!'
fi
