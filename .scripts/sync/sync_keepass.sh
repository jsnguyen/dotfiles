#!/bin/bash

if [ "${1}" = "qnap" ]; then
    echo "Backing up to qnap..."
    rsync -avzh /Users/jsn/landing/docs/jsn_db.kdbx /Volumes/QNDA
    rsync -avzh /Users/jsn/landing/docs/jsn_db.kdbx /Volumes/QNDB
fi

if [ "${1}" = "SSXP" ]; then
    echo "Backing up to SSXP..."
    rsync -avzh /Users/jsn/landing/docs/jsn_db.kdbx /Volumes/SSXP
fi
