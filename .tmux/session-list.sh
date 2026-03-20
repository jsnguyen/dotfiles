#!/bin/bash
current="$1"
for s in $(tmux ls -F "#{session_name}"); do
    if [ "$s" = "$current" ]; then
        printf "#[bg=white,fg=black,bold] %s #[bg=#1e1e2e,fg=default,nobold]" "$s"
    else
        printf "#[bg=#1e1e2e,fg=grey] %s " "$s"
    fi
done
