#!/bin/bash

rsync -avzh --progress /Volumes/QNDA/ /Volumes/QNDB --exclude-from=exclude_list.txt
rsync -avzh --progress /Volumes/QNDB/ /Volumes/QNDA --exclude-from=exclude_list.txt
