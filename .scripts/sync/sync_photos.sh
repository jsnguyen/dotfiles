#!/bin/bash

PHOTOS_FOLDER=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/storage/photos/

if [ "${1}" = "qnap" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress "$PHOTOS_FOLDER" /Volumes/QNDB/photos
fi

if [ "${1}" = "SSXP" ]; then
    rsync --exclude-from='exclude_list.txt' -avzh --progress "$PHOTOS_FOLDER" /Volumes/SSXP/photos
fi
