#!/bin/bash

#search for wp-sites
source ./wpsearchdir.sh

dir=./
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
    case $1 in
        -g)
            git=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpupdate.sh [-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        -w)
            shift
            wp=$1
            ;;
    esac
    #next argument -> e.g. $2 becomes $1, $3 becomes $2...
    shift
done
#only WP-Sites are to be processed
for site in "${sites[@]}"; do
    echo $site
done