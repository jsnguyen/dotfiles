#!/bin/bash

tmux attach -t atmux 2>/dev/null || tmux new-session -s atmux
