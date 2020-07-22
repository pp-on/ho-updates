#!/bin/env bash

verbose=0       #show files
dir=./
wp="wp"         #where is wp-cli 
cms="wp"        #specific for db dump
restore=0       #restoree site from file 
while [ $# -gt 0 ];do
    case $1 in
        -v)
            verbose=1
            ;;
        -d)
            shift
            dir=$1
            ;;
        -h)
            echo "wpbackup.sh [-b][-r][-d targetDIR][-w path/to/wp]"
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
for site in $(ls -d $dir*/); do
    if [ -d "$site/wp-content/" ]; then
        seite=${site##"$dir"}
        echo "Found $seite"
        echo "Should it be processed? [y/n] "
    cd $site  &>/dev/null
        read answer
        echo -e "\n--------------"
        if [ "$answer" = "y" ]; then
            sites+=("$site")
        fi
    fi
done

root="${dir}backups"
#backups folders for every site
function folders () {
    if [ ! -d "$1" ]; then
        mkdir $1
    fi
}

folders $root
datum=$(date)          
for site in "${sites[@]}"; do
    cd $site  &>/dev/null
    #only names
    site=${site##"$dir"}
    site=${site%/}
    echo -e "================================\n\t$site\n================================"
    # is wp-site working?
    error=$($wp core check-update ) #the result of command -> 0 ok, 1 error. string goes to variable
    #echo $?
    if [ ! -z "$error" ]; then
     #   echo "$error"
        echo "Everything OK"
    else
        echo "$error" 
        continue
   fi
   sleep 1
    echo -e "---------------\nDumping Database#\n---------------"
    $wp db export "${site}-${datum}.sql" --allow-root
    sleep 1
    echo -e "---------------\nBackingup files\n---------------"
    folders $root/$site
    if [ "$verbose" -eq 1 ]; then
        tar cvzf "$root/$site/${site}-${datum}.tar.gz" . 
    else
        tar czf "$root/$site/${site}-${datum}.tar.gz" . 
    fi
    rm "${site}-${datum}.sql"    #CLEAN UP
    cd -  &>/dev/null
done

