#!/usr/bin/env bash

a="$1"
b="$2"

RSYNC_OPTS="-avzhi --no-perms --omit-dir-times --exclude-from=exclude_list.txt"

# Default to dry run
if [[ "$3" != "--run" ]]; then
    RSYNC_OPTS="$RSYNC_OPTS -n"
    echo "*** DRY RUN ***"
fi

echo "=== $a -> $b ==="
rsync $RSYNC_OPTS "$a/" "$b/"

echo
echo "=== $b -> $a ==="
rsync $RSYNC_OPTS "$b/" "$a/"
