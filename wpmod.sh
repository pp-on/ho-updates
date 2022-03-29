#!/bin/bash

#search for wp-sites
source ~/git/ho-updates/wphelpfuntions.sh

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
ssh=0
assign_env "ssh" 1
#only WP-Sites are to be processed
verbose=1
#searchwp
#print_sites
os_detection
echo $cOS
process_dirs "wp-starter,aurahotel,bbsb,eca"
print_sites
list_wp_plugins
