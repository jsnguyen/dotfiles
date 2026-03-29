#!/bin/bash

echo 'Syncing archived pictures...'
./sync_archived_pictures.sh qnap

echo 'Sync photos...'
./sync_photos.sh qnap

echo 'Sync keepass...'
./sync_keepass.sh qnap

echo 'Syncing qnap...'
./sync_qnap.sh
