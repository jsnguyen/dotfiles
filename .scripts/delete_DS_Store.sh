#!/bin/bash

echo "Target directory: $(pwd)"
echo ""

DS_FILES=$(find . -name ".DS_Store" -type f)

if [ -z "$DS_FILES" ]; then
    echo "No .DS_Store files found."
    exit 0
fi

echo "Found the following .DS_Store files:"
echo "$DS_FILES"
echo ""
COUNT=$(echo "$DS_FILES" | wc -l | tr -d ' ')
echo "Total: $COUNT file(s)"
echo ""
read -p "Delete all $COUNT .DS_Store file(s)? [y/N] " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Deleting..."
echo "$DS_FILES" | while read -r FILE; do
    rm -v "$FILE" && echo "  ✓ Deleted: $FILE" || echo "  ✗ Failed:  $FILE"
done

echo ""
echo "Done."
