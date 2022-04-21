#!/bin/bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh

dir=./
wp="wp"         #where is wp-cli 
while [ $# -gt 0 ];do
#for arg in "$@"; do
#while getopts 'd:w:gh' arg; do
    #case $1 in
    case $1 in
        -g)
            git=1
            ;;
        -d)
            shift
            dir="$1"
            ;;
        -o)
            os_detection 1
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
        -h)
            echo "wpmod.sh [--print][-p][-c][-l][-o][-s SEL,DIRS,...][--copy_plugins FROM][-d targetDIR][-w path/to/wp][-g]"
            exit
            ;;
        *)
            echo "hhh"
            exit
    esac
    shift
done #only WP-Sites are to be processed
verbose=1
#searchwp
