#!/bin/bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh

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
        -o)
            os_detection
            ;;
        -p)
            process_sites
            ;;
        --print)
            print_sites
            ;;
        -c)
            colors
            ;;
        -l)
            list_wp_plugins
            ;;
        -h)
            echo "wpmod.sh [--print][-p][-c][-l][-o][-s SEL,DIRS,...][--copy_plugins FROM][-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        -s)
            shift
            process_dirs "$1"
            ;;
        --copy-plugins)
            shift
            copy_plugins "$1"
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
