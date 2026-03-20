#!/bin/bash

function vnc_tunnel_decaf {
    tmux new-session -d -s 'vnctun'
}

echo 'Starting vnc ssh tunnel on localhost:59001 to localhost:5901 on decaf.ucsd.edu session...'
if vnc_tunnel_decaf; then
    tmux send-keys -t vnctun:0 'cd' C-m
    tmux send-keys -t vnctun:0 'ssh -L 59001:localhost:5901 -C -N jsn@decaf.ucsd.edu' C-m
    echo 'vnc ssh tunnel established!'
else
    echo 'error could not establish tunnel or tunnel already running'
fi
