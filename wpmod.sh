#!/bin/bash

#search for wp-sites
source ~/git/ho-updates/wpsearchdir.sh

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
<<<<<<< HEAD
done 

process_dirs "aurahotel,beans-and-books"
=======
done
#only WP-Sites are to be processed
verbose=1
#searchwp
#print_sites
process_dirs "wp-starter,aurahotel,bbsb,eca"
>>>>>>> 939b3996dd120b0dc9e6adbf86ab4f16d3ed88a8
print_sites
list_wp_plugins
