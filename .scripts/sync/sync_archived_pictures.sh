#!/bin/bash

ARCHIVED_PICTURES_FOLDER=~/landing/archived_pictures/

if [ "${1}" = "qnap" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress "$PHOTOS_FOLDER" /Volumes/QNDB/archived_pictures
fi

if [ "${1}" = "SSXP" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress "$PHOTOS_FOLDER" /Volumes/SSXP/archived_pictures
fi

if [ "${1}" = "synology" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress "$PHOTOS_FOLDER" jsn@skylab.local:/volume1/storage/archived_pictures
fi
