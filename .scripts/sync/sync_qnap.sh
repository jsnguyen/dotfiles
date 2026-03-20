#!/bin/bash

rsync -avzh --progress --exclude .bzvol --exclude '.DS_Store' --exclude '.Spotlight-V100' --exclude '.fseventsd' --exclude '.DocumentRevisions-V100' --exclude '.TemporaryItems' /Volumes/QNDA/ /Volumes/QNDB
