#!/bin/bash

PWD=$(PWD)

for FILENAME in *.dng *.DNG; do
    [ -e "${FILENAME}" ] || continue

    DIM=$(identify -format "%wx%h" ${FILENAME})
    XDIM=$(echo ${DIM} | cut -d'x' -f1)
    YDIM=$(echo ${DIM} | cut -d'x' -f2)

    echo ${XDIM} ${YDIM}

    if [ "$XDIM" -gt "$YDIM" ]; then
        SIZE='12499x6048'
        ROTATE=''
    else
        SIZE='6048x12499'
        ROTATE='-rotate 90'
    fi

    echo ${SIZE}

    NEWFILENAME="${FILENAME::${#FILENAME}-4}_a.jpg"
    echo "Stretching image... ${PWD}/${FILENAME} -> ${PWD}/${NEWFILENAME}"
    magick -quality 80 ${PWD}/${FILENAME} -resize ${SIZE}\! ${ROTATE} ${PWD}/${NEWFILENAME}
done
