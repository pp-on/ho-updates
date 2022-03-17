#!/bin/bash

#make functions available to be used
#in other scripts for maintaning more
#than one wordpress's sies in a web
#serv er or locally
#+----------------------------------+
#|      Functions                   |
#+----------------------------------+
#| searchwp()                       |
#| search for wp sites in $dir      |
#+----------------------------------+

# Reset
Color_Off="\e[0m"       # Text Reset

# Regular Colors
Black="\e[30m"        # Black
Red="\e[31m"          # Red
Green="\e[32m"        # Green
Yellow="\e[33m"       # Yellow
Blue="\e[34m"         # Blue
Purple="\e[35m"       # Purple
Cyan="\e[36m"         # Cyan
White="\e[37m"        # White

wp="wp"         #where is wp-cli 
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
        -v)
            verbose=1
            ;;
        -t)
            total=1
            ;;
        -w)
            shift
            wp=${1}
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpsearchdir.sh [-w path/to/wpcli][-s][-p][-v][-t][-d TARGET DIR][-b (dir1,dir2,...)]"
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
for site in $(ls -d "$dir"*/); do
    if [ -d "$site/wp-content/" ]; then
        site=${site##"$dir"}
        [ "$verbose" = "1" ] && sleep 1 && echo "Found $site"
        sites+=("$site"); (( anzahl++ ))
    fi
done
[ -n "$total" ] && echo -e "${Yellow}${anzahl}${Color_Off} WordPress Sites found"
