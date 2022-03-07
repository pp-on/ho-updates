#!/bin/bash

verbose=0
total=0
dir=./
anzahl=0

while [ $# -gt 0 ];do
    case $1 in
        -v)
            verbose=1
            ;;
        -t)
            total=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpsearchdir.sh [-v][-t][-d TARGET DIR]"
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#for dirs
#dirs=($(ls -lh -d */ | awk '{print $9}' | sed 's/\///g'))
dirs=$(find "$dir"*/ -maxdepth 1 -mindepth 1 -type d)
#check for wpsites and add them to array
#for site in "${dirs[@]}"; do
searchwp() {
    for site in $(ls -d $dir*/); do
        if [ -d "$site/wp-content/" ]; then
            site=${site##"$dir"}
            if [ "$verbose" = "1" ]; then
                sleep 1
                echo "Found $site"
            fi
            sites+=("$site")
            let anzahl++
        fi
    done

# w/o arguments
if [ "$verbose" = "0" ]; then
    #pass it
    echo "${sites[@]}" 
fi
# -t -> how many found 
if [ "$total" = "1" ]; then
    echo -e "\n=======\nTotal $anzahl WP-Sites"
fi
}
process_sites(){
    if [ -z "$sites" ]; then #if no folders aka Websites were pass as argument
        for site in $(ls -d $dir*/); do
            if [ -d "$site/wp-content/" ]; then
                seite=${site##"$dir"}
                echo "Found $seite"
                echo "Should it be processed? [y] "
                read answer
                echo -e "\n--------------"
                if [ "$answer" = "y" ]; then
                    #only names
                    site=${site#"$dir"}
                    site=${site%%/}
                    sites+=("$site")
                fi
            fi
        done

