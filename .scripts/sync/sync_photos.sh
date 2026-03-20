#!/bin/bash

if [ "${1}" = "qnap" ]; then
    rsync -avzh --progress ~/Google\ Drive/My\ Drive/photos/ /Volumes/QNDA/photos
    rsync -avzh --progress ~/Google\ Drive/My\ Drive/photos/ /Volumes/QNDB/photos
fi

if [ "${1}" = "SSXP" ]; then
    rsync -avzh --progress ~/Google\ Drive/My\ Drive/photos/ /Volumes/SSXP/photos
fi
