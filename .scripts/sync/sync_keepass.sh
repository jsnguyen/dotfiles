#!/bin/bash

KEEPASS_FILE=/Users/jsn/landing/docs/jsn_db.kdbx

if [ "${1}" = "qnap" ]; then
    echo "Backing up to qnap..."
    rsync -avzh "$KEEPASS_FILE" /Volumes/QNDA
    rsync -avzh "$KEEPASS_FILE" /Volumes/QNDB
fi

if [ "${1}" = "SSXP" ]; then
    echo "Backing up to SSXP..."
    rsync -avzh "$KEEPASS_FILE" /Volumes/SSXP
fi
