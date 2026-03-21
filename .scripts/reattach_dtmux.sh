#!/bin/bash

tmux attach -t dtmux 2>/dev/null || tmux new-session -s dtmux
