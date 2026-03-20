#!/bin/bash

if [ "${1}" = "qnap" ]; then
    rsync -avzh --progress ~/landing/archived_pictures/2024/ /Volumes/QNDA/archived_pictures/2024
    rsync -avzh --progress ~/landing/archived_pictures/2024/ /Volumes/QNDB/archived_pictures/2024
fi

if [ "${1}" = "SSXP" ]; then
    rsync -avzh --progress ~/landing/archived_pictures/2024/ /Volumes/SSXP/archived_pictures/2024
fi
