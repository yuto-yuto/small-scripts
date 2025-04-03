#!/bin/bash

# This script renames all files in the current directory to last modified time in YYYYMMDD-HHMMSS format.
# Call this script with '-run' arg to apply rename.
# 
# * Dry Run
#   Execute this script without arg. It shows the source name and the destination name.

find . -maxdepth 1 -mindepth 1 -type f -not -name "rename-to-update-time.sh" -print0 |
 while IFS= read -r -d '' filename; do 
       # Get last modified time in YYYYMMDD-HHMMSS format.
       updateTime="$(date -r "$filename" "+%Y%m%d-%H%M%S")"
       # Get extension of the file.
       extension="${filename##*.}"

       echo "$filename ---> $updateTime.$extension"
       if [[ "$1" == "-run" ]]; then
              mv "$filename" "$updateTime.$extension"
       fi       
 done

read -p "Press [Enter] to finish"
