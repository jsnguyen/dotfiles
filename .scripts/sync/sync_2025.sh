#!/bin/bash

if [ "${1}" = "qnap" ]; then
    rsync -avzh --progress ~/landing/archived_pictures/2025/ /Volumes/QNDA/archived_pictures/2025
    rsync -avzh --progress ~/landing/archived_pictures/2025/ /Volumes/QNDB/archived_pictures/2025
fi

if [ "${1}" = "SSXP" ]; then
    rsync -avzh --progress ~/landing/archived_pictures/2025/ /Volumes/SSXP/archived_pictures/2025
fi
