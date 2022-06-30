#!/bin/bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh

dir=./
wp="wp"         #where is wp-cli 
wpuser="test"
wppw="secret"
wpemail="oswaldo.nickel@pfennigparade.de"
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
        -u|--update)
            shift
            wp_update "$1"
            ;;
        -r)
            shift
            remove_plugins "$1" "$2"
            shift
            ;;
        -wm|--wp-migrate-db-pro)
            wp_key_migrate
            ;;
        -cp|--copy-plugins)
            shift
            copy_plugins "$1"
            ;;
        -n)
            out "creating user ${wpuser} with password ${wppw}" 1
            wp_new_user $wpuser $wppw $wpemail
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
