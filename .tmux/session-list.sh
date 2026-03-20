#!/bin/bash
current="$1"
for s in $(tmux ls -F "#{session_name}"); do
    if [ "$s" = "$current" ]; then
        printf "#[bg=white,fg=black,bold] %s #[default]" "$s"
    else
        printf "#[fg=grey] %s " "$s"
    fi
done
