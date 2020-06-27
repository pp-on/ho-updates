#!/bin/bash

verbose=0
total=0
dir=./

while [ $# -gt 0 ];do
    case $1 in
        -v)
            verbose=1
            ;;
        -t)
            total=1
            ;;
        *)
            dir=$1
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#for dirs
dirs=($(ls -lh -d */ | awk '{print $9}' | sed 's/\///g'))
#check for wpsites and add them to array
for site in "${dirs[@]}"; do
    if [ -d "$site/wp-content/" ]; then
        if [ "$verbose" = "1" ]; then
            sleep 1
            echo "Found $site"
        fi
        sites+=("$site")
        let i++
    fi
done
# w/o arguments
if [ "$verbose" = "0" ]; then
    echo "${sites[@]}" 
fi
# -t -> how many found 
if [ "$total" = "1" ]; then
    echo -e "\n=======\nTotal $i WP-Sites"
fi
