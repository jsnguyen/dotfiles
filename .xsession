#!/bin/bash

if [ -x /usr/bin/gnome-power-manager ]; then
    sleep 1
    gnome-power-manager &
fi

while true; do
    xsetroot -name "$(date + "%F %I:%M %p")"
    sleep 10
done &

export PATH="/snap/bin:$PATH"

~/.fehbg &
(conky | while read LINE; do xsetroot -name "$LINE"; done) &
exec dwm
