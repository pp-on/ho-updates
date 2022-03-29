
#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh

#!/bin/bash
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
total=0
dir=./
anzahl=0
hostname="localhost"     #host in DB
dbuser="web"
dbpw="1234"
dir=$(basename $PWD)
# replace "-" with "_" for database name 
dbname=${dir//[^a-zA-Z0-9]/_}
title="test${dir^^}"           #uppercase
url="localhost/arbeit/updates/repos/$dir"
wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
while [ $# -gt 0 ];do
    case $1 in
        -y)
            skip=1
            ;;
        -u)
            shift
            url="$1"
            ;;
        -v)
            verbose=1
            ;; -t) wp=${1}
            ;;
        -h)
            echo "wpsearchdir.sh [-w path/to/wpcli][-s][-p][-v][-t][-d TARGET DIR][-b (dir1,dir2,...)]"
            exit
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done


