#!/bin/bash

function start_tmux_claude_code {
    tmux new-session -d -s 'claude'
}

echo 'Starting claude code session...'
if start_tmux_claude_code ; then
    tmux send-keys -t claude:0 'cd ~/landing/cc_projects' Enter
    tmux send-keys -t claude "claude" Enter
    echo 'claude code started!'
else
    echo 'claude code already running!'
fi
