#!/bin/bash

#for dirs
dirs=($(ls -lh -d */ | awk '{print $9}'))
#check for wpsites and add them to array
for site in "${dirs[@]}"; do
    if [ -d "$site/wp-content/" ]; then
        echo "Found $site"
        sites+=("$site")
        let i++
    fi
done
echo "$i"
