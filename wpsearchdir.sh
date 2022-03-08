#!/bin/bash

verbose=0
total=0
dir=./
anzahl=0
print=0

while [ $# -gt 0 ];do
    case $1 in
        -p)
            print=1
            ;;
        -s)
            searchwp
            ;;
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
            echo "wpsearchdir.sh [-s][-p][-v][-t][-d TARGET DIR]"
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
            [ "$verbose" = "1" ] && sleep 1 && echo "Found $site"
            sites+=("$site"); let anzahl++
        fi
    done

}
print_sites(){
    for s in "${sites[@]}"; do
        echo $s
    done
}
# w/o arguments
[ "$print" = "1" ] && print_sites

# -t -> how many found 
[ "$total" = "1" ] && echo -e "\n=======\nTotal $anzahl WP-Sites"

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
    }
