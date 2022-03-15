#!/bin/env bash

cdir=$(basedir $PWD)
new="http://localhost/arbeit/updates/${cdir}"
old=""
wp="wp"         #where is wp-cli 

while [ $# -gt 0 ];do
    case $1 in
        -s)
            shift
            old=$1
            ;;
        -n)
            shift
            new=$1
            ;;
        -h)
            echo "$0: -s Searchstring  [-n newString][-w PATH/TO/WP cli][-h usage]"
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

echo "Replacing all ocurrences of ${old} with ${new}"
echo "Proceed [y/n]"
read a
if [ $a = "y" ]; then
    wp search-replace --network --url=${old} ${old} ${new} --precise --dry-run
elif [ $a = "n" ]; then
    echo "Bye" 
fi
