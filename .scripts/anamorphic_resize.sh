#!/bin/bash

PWD=$(PWD)

for FILENAME in *.jpg *.JPG; do
    [ -e "${FILENAME}" ] || continue

    DIM=$(identify -format "%wx%h" ${FILENAME})
    XDIM=$(echo ${DIM} | cut -d'x' -f1)
    YDIM=$(echo ${DIM} | cut -d'x' -f2)

    if [ "$XDIM" -gt "$YDIM" ]; then
        SIZE='13107x5464'
    else
        SIZE='5464x13107'
    fi

    NEWFILENAME="${FILENAME::${#FILENAME}-4}_a.jpg"
    echo "Stretching image... ${PWD}/${FILENAME} -> ${PWD}/${NEWFILENAME}"
    magick ${PWD}/${FILENAME} -resize ${SIZE}\! ${PWD}/${NEWFILENAME}
done
