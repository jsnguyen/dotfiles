#!/bin/bash

PHOTOS_FOLDER=~/Library/Mobile\ Documents/com\~apple\~CloudDocs/storage/photos/

if [ "${1}" = "qnap" ]; then
    rsync --exclude='.DS_Store' -avzh --progress "$PHOTOS_FOLDER" /Volumes/QNDA/photos
    rsync --exclude='.DS_Store' -avzh --progress "$PHOTOS_FOLDER" /Volumes/QNDB/photos
fi

if [ "${1}" = "SSXP" ]; then
    rsync --exclude='.DS_Store' -avzh --progress "$PHOTOS_FOLDER" /Volumes/SSXP/photos
fi
