#!/bin/bash

#search for wp-sites
##source ~/git/ho-updates/wphelpfuntions.sh

#dir=./
wp="wp"         #where is wp-cli 
echo "before: ${dir}"
while [ $# -gt 0 ];do
#for arg in "$@"; do
#while getopts 'd:w:gh' arg; do
    #case $1 in
    case $arg in
        -g)
            git=1
            ;;
        -d)
            shift
            dir="$1"
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
    shift
done #only WP-Sites are to be processed
verbose=1
#searchwp
#print_sites
os_detection
echo $cOS
process_dirs "wp-starter,aurahotel,bbsb,eca"
print_sites
list_wp_plugins
