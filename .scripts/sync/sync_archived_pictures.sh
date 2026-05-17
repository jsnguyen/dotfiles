#!/bin/bash

if [ "${1}" = "qnap" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress ~/landing/archived_pictures/ /Volumes/QNDB/archived_pictures
fi

if [ "${1}" = "SSXP" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress ~/landing/archived_pictures/ /Volumes/SSXP/archived_pictures
fi
