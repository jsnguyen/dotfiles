#!/bin/bash

DISK_NAMES='QNDA QNDB'

for el in $DISK_NAMES;do
    DISK_PATH="/Volumes/${el}"
    mkdir -p "$DISK_PATH/filetree_snapshots"
    find $DISK_PATH -type f | sort > "${DISK_PATH}/filetree_snapshots/${el}_snapshot_$(date +%Y%m%d).txt" 
done

