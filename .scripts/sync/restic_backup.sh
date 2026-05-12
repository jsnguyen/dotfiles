#!/bin/bash
restic -r /Volumes/QNDR/ backup /Volumes/QNDB --exclude-file exclude_list_restic.txt --verbose --insecure-no-password --one-file-system
